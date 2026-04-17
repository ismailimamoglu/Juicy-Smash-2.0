import Foundation
import SwiftUI
import Observation

enum BoosterType: String {
    case none
    case hammer
    case megaBlast
}

@Observable
final class OrchardOrchestrator {
    // MARK: - Grid Configuration
    let rows = 8
    let cols = 8

    // MARK: - Game State
    var nectarGrid: [[HarvestTile?]] = []
    var score: Int = 0
    var comboMultiplier: Int = 1
    var floatingScores: [FloatingScore] = []
    var lastSwappedTiles: (HarvestTile, HarvestTile)? = nil
    var isProcessing: Bool = false

    // MARK: - Level State
    var level: Int
    var movesLeft: Int
    var targetScore: Int

    var isGameOver: Bool = false
    var isLevelClear: Bool = false

    // MARK: - Booster State
    var activeBooster: BoosterType = .none
    var showInsufficientBalance: Bool = false

    // MARK: - Init
    init(level: Int = 1) {
        self.level = level
        self.movesLeft = max(15, 25 - level)
        self.targetScore = 1000 + (level * 500)
        seedInitialOrchard()
    }

    // MARK: - Setup

    private func seedInitialOrchard() {
        nectarGrid = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        for row in 0..<rows {
            for col in 0..<cols {
                var variety: FruitVariety
                repeat {
                    variety = FruitVariety.allCases.randomElement()!
                } while createsMatchAtStart(row: row, col: col, variety: variety)
                nectarGrid[row][col] = HarvestTile(variety: variety, row: row, col: col)
            }
        }
    }

    private func createsMatchAtStart(row: Int, col: Int, variety: FruitVariety) -> Bool {
        if col >= 2,
           let l1 = nectarGrid[row][col-1], l1.variety == variety,
           let l2 = nectarGrid[row][col-2], l2.variety == variety { return true }
        if row >= 2,
           let u1 = nectarGrid[row-1][col], u1.variety == variety,
           let u2 = nectarGrid[row-2][col], u2.variety == variety { return true }
        return false
    }

    // MARK: - Extra Moves (IAP / Ad mock)

    @MainActor
    func buyExtraMoves() -> Bool {
        let progression = ProgressionManager.shared
        guard progression.spendCoins(50) else {
            showInsufficientBalance = true
            return false
        }
        movesLeft += 5
        isGameOver = false
        return true
    }

    @MainActor
    func watchAdForMoves() {
        movesLeft += 5
        isGameOver = false
    }

    // MARK: - Booster Actions

    @MainActor
    func activateHammer() -> Bool {
        guard ProgressionManager.shared.spendCoins(ProgressionManager.hammerPrice) else {
            showInsufficientBalance = true
            return false
        }
        SoundManager.shared.playBooster()
        activeBooster = .hammer
        return true
    }

    @MainActor
    func activateShuffle() -> Bool {
        guard !isProcessing else { return false }
        guard ProgressionManager.shared.spendCoins(ProgressionManager.shufflePrice) else {
            showInsufficientBalance = true
            return false
        }
        SoundManager.shared.playBooster()
        shuffleBoard()
        return true
    }

    @MainActor
    func activateMegaBlast() -> Bool {
        guard ProgressionManager.shared.spendCoins(ProgressionManager.megaBlastPrice) else {
            showInsufficientBalance = true
            return false
        }
        SoundManager.shared.playBooster()
        activeBooster = .megaBlast
        return true
    }

    @MainActor
    func useBoosterOnTile(row: Int, col: Int) {
        guard !isProcessing, activeBooster != .none else { return }
        isProcessing = true
        let booster = activeBooster
        activeBooster = .none

        Task {
            switch booster {
            case .hammer:
                guard nectarGrid[row][col] != nil else { isProcessing = false; return }
                triggerHaptics(style: .medium)
                score += 10
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    nectarGrid[row][col] = nil
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { applyOrganicGravity() }
                try? await Task.sleep(nanoseconds: 200_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { refillOrchard() }
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !findMatches().isEmpty {
                    comboMultiplier = 1
                    await processMatchesAndRefill()
                } else {
                    isProcessing = false
                    checkGameEnd()
                }

            case .megaBlast:
                var tilesToDestroy = Set<HarvestTile>()
                for r in max(0, row-1)...min(rows-1, row+1) {
                    for c in max(0, col-1)...min(cols-1, col+1) {
                        if let tile = nectarGrid[r][c] { tilesToDestroy.insert(tile) }
                    }
                }
                triggerHaptics(style: .heavy)
                score += tilesToDestroy.count * 15
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    for t in tilesToDestroy { nectarGrid[t.row][t.col] = nil }
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { applyOrganicGravity() }
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { refillOrchard() }
                try? await Task.sleep(nanoseconds: 400_000_000)
                if !findMatches().isEmpty {
                    comboMultiplier = 1
                    await processMatchesAndRefill()
                } else {
                    isProcessing = false
                    checkGameEnd()
                }

            case .none:
                isProcessing = false
            }
        }
    }

    private func shuffleBoard() {
        var allVarieties: [FruitVariety] = []
        for row in 0..<rows {
            for col in 0..<cols {
                if let tile = nectarGrid[row][col] {
                    allVarieties.append(tile.variety)
                }
            }
        }
        allVarieties.shuffle()

        var idx = 0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            for row in 0..<rows {
                for col in 0..<cols {
                    if nectarGrid[row][col] != nil && idx < allVarieties.count {
                        nectarGrid[row][col] = HarvestTile(variety: allVarieties[idx], row: row, col: col)
                        idx += 1
                    }
                }
            }
        }
    }

    // MARK: - Swap Interaction

    @MainActor
    func attemptSwap(tile1: HarvestTile, tile2: HarvestTile) {
        guard !isProcessing else { return }
        guard activeBooster == .none else { return }

        let rowDiff = abs(tile1.row - tile2.row)
        let colDiff = abs(tile1.col - tile2.col)
        let isAdjacent = (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)

        guard isAdjacent else { return }
        guard movesLeft > 0 && !isGameOver && !isLevelClear else { return }

        movesLeft -= 1
        SoundManager.shared.playSwipe()
        triggerHaptics(style: .light)
        lastSwappedTiles = (tile1, tile2)
        isProcessing = true

        let rainbowSwap = tile1.state == .rainbow || tile2.state == .rainbow

        Task {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                swapInGrid(row1: tile1.row, col1: tile1.col, row2: tile2.row, col2: tile2.col)
            }

            if rainbowSwap {
                let targetVariety = tile1.state == .rainbow ? tile2.variety : tile1.variety
                let rainbowTile   = tile1.state == .rainbow ? tile1 : tile2

                try? await Task.sleep(nanoseconds: 200_000_000)
                triggerHaptics(style: .heavy)
                SoundManager.shared.playCombo()

                var tilesToDestroy = Set<HarvestTile>()
                for r in 0..<rows {
                    for c in 0..<cols {
                        if let t = nectarGrid[r][c], t.variety == targetVariety {
                            tilesToDestroy.insert(t)
                        }
                    }
                }
                let rRow = (rainbowTile.state == .rainbow ? tile2.row : tile1.row)
                let rCol = (rainbowTile.state == .rainbow ? tile2.col : tile1.col)
                let rRow2 = (rainbowTile.state == .rainbow ? tile1.row : tile2.row)
                let rCol2 = (rainbowTile.state == .rainbow ? tile1.col : tile2.col)
                if let rt = nectarGrid[rRow][rCol]  { tilesToDestroy.insert(rt) }
                if let rt = nectarGrid[rRow2][rCol2] { tilesToDestroy.insert(rt) }

                let gained = tilesToDestroy.count * 30
                score += gained

                let floats = tilesToDestroy.map {
                    FloatingScore(text: "+30", color: $0.variety.primaryColorHexString, row: $0.row, col: $0.col)
                }
                floatingScores.append(contentsOf: floats)
                Task { try? await Task.sleep(nanoseconds: 1_000_000_000)
                    let ids = Set(floats.map { $0.id })
                    self.floatingScores.removeAll { ids.contains($0.id) }
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    for t in tilesToDestroy { nectarGrid[t.row][t.col] = nil }
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { applyOrganicGravity() }
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { refillOrchard() }
                try? await Task.sleep(nanoseconds: 400_000_000)

                comboMultiplier = 2
                if !findMatches().isEmpty {
                    await processMatchesAndRefill()
                } else {
                    isProcessing = false
                    checkGameEnd()
                }
            } else {
                let matches = findMatches()
                if matches.isEmpty {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swapInGrid(row1: tile1.row, col1: tile1.col, row2: tile2.row, col2: tile2.col)
                    }
                    movesLeft += 1
                    isProcessing = false
                } else {
                    SoundManager.shared.playMatch()
                    comboMultiplier = 1
                    await processMatchesAndRefill()
                }
            }
        }
    }

    // MARK: - Core Engine

    private func swapInGrid(row1: Int, col1: Int, row2: Int, col2: Int) {
        let temp = nectarGrid[row1][col1]
        nectarGrid[row1][col1] = nectarGrid[row2][col2]
        nectarGrid[row2][col2] = temp
        nectarGrid[row1][col1]?.row = row1; nectarGrid[row1][col1]?.col = col1
        nectarGrid[row2][col2]?.row = row2; nectarGrid[row2][col2]?.col = col2
    }

    private func findMatches() -> Set<HarvestTile> {
        var matched = Set<HarvestTile>()
        for row in 0..<rows {
            var col = 0
            while col < cols - 2 {
                guard let cur = nectarGrid[row][col] else { col += 1; continue }
                var len = 1
                while col + len < cols, let nxt = nectarGrid[row][col+len], nxt.variety == cur.variety { len += 1 }
                if len >= 3 { for i in 0..<len { if let t = nectarGrid[row][col+i] { matched.insert(t) } } }
                col += len
            }
        }
        for col in 0..<cols {
            var row = 0
            while row < rows - 2 {
                guard let cur = nectarGrid[row][col] else { row += 1; continue }
                var len = 1
                while row + len < rows, let nxt = nectarGrid[row+len][col], nxt.variety == cur.variety { len += 1 }
                if len >= 3 { for i in 0..<len { if let t = nectarGrid[row+i][col] { matched.insert(t) } } }
                row += len
            }
        }
        return matched
    }

    @MainActor
    private func processMatchesAndRefill() async {
        var matches = findMatches()
        while !matches.isEmpty {
            let (toRemove, specials) = determineRipenessOutcomes(matches: matches)
            try? await Task.sleep(nanoseconds: 150_000_000)

            let destroyed = resolveExplosions(initialTargets: toRemove)
            let hasHeavy  = destroyed.contains { $0.state == .bomb || $0.state == .rainbow }
            let hasMed    = destroyed.contains { $0.state == .rowClearer || $0.state == .colClearer }
            triggerHaptics(style: hasHeavy ? .heavy : (hasMed ? .medium : .light))

            if comboMultiplier > 1 { SoundManager.shared.playCombo() }
            else { SoundManager.shared.playMatch() }

            let gained = destroyed.count * 10 * comboMultiplier
            score += gained

            let floats = destroyed.map {
                FloatingScore(text: "+\(10 * comboMultiplier)", color: $0.variety.primaryColorHexString, row: $0.row, col: $0.col)
            }
            floatingScores.append(contentsOf: floats)
            Task { try? await Task.sleep(nanoseconds: 1_000_000_000)
                let ids = Set(floats.map { $0.id })
                self.floatingScores.removeAll { ids.contains($0.id) }
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                for t in destroyed { nectarGrid[t.row][t.col] = nil }
                for s in specials  { nectarGrid[s.row][s.col] = s }
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { applyOrganicGravity() }
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { refillOrchard() }
            comboMultiplier += 1
            try? await Task.sleep(nanoseconds: 400_000_000)
            matches = findMatches()
        }
        isProcessing = false
        checkGameEnd()
    }

    // MARK: - Game End

    private func checkGameEnd() {
        if score >= targetScore {
            SoundManager.shared.playLevelClear()
            isLevelClear = true
        } else if movesLeft <= 0 {
            SoundManager.shared.playGameOver()
            isGameOver = true
        }
    }

    // MARK: - Explosion Resolution

    private func resolveExplosions(initialTargets: Set<HarvestTile>) -> Set<HarvestTile> {
        var toProcess = Array(initialTargets)
        var destroyed = Set<HarvestTile>()

        while !toProcess.isEmpty {
            let cur = toProcess.removeFirst()
            guard !destroyed.contains(cur), nectarGrid[cur.row][cur.col] != nil else { continue }
            destroyed.insert(cur)

            switch cur.state {
            case .rowClearer:
                for c in 0..<cols { if let t = nectarGrid[cur.row][c], !destroyed.contains(t) { toProcess.append(t) } }
            case .colClearer:
                for r in 0..<rows { if let t = nectarGrid[r][cur.col], !destroyed.contains(t) { toProcess.append(t) } }
            case .bomb:
                for t in getRadius(row: cur.row, col: cur.col, radius: 1) where !destroyed.contains(t) { toProcess.append(t) }
            case .rainbow:
                let varieties = Set((0..<rows).flatMap { r in (0..<cols).compactMap { c in nectarGrid[r][c]?.variety } })
                if let v = varieties.randomElement() {
                    for r in 0..<rows { for c in 0..<cols {
                        if let t = nectarGrid[r][c], t.variety == v, !destroyed.contains(t) { toProcess.append(t) }
                    }}
                }
            case .fresh: break
            }
        }
        return destroyed
    }

    private func getRadius(row: Int, col: Int, radius: Int) -> [HarvestTile] {
        var results: [HarvestTile] = []
        for r in (row-radius)...(row+radius) {
            for c in (col-radius)...(col+radius) {
                if r >= 0, r < rows, c >= 0, c < cols, let t = nectarGrid[r][c] { results.append(t) }
            }
        }
        return results
    }

    private func getConnectedComponents(from tiles: Set<HarvestTile>) -> [Set<HarvestTile>] {
        var unvisited = tiles
        var components: [Set<HarvestTile>] = []
        while let start = unvisited.first {
            var component = Set<HarvestTile>()
            var queue = [start]
            unvisited.remove(start); component.insert(start)
            while !queue.isEmpty {
                let node = queue.removeFirst()
                let adjs = unvisited.filter {
                    (abs($0.row - node.row) == 1 && $0.col == node.col) ||
                    (abs($0.col - node.col) == 1 && $0.row == node.row)
                }
                for a in adjs { unvisited.remove(a); component.insert(a); queue.append(a) }
            }
            components.append(component)
        }
        return components
    }

    private func determineRipenessOutcomes(matches: Set<HarvestTile>) -> (Set<HarvestTile>, [HarvestTile]) {
        var toRemove = matches
        var spawns: [HarvestTile] = []

        let grouped = Dictionary(grouping: matches, by: { $0.variety })
        for (variety, tiles) in grouped {
            for component in getConnectedComponents(from: Set(tiles)) {
                let count = component.count
                guard count >= 4 else { continue }
                let rs = Set(component.map { $0.row })
                let cs = Set(component.map { $0.col })
                let spawnPt = component.first(where: {
                    $0.row == lastSwappedTiles?.0.row && $0.col == lastSwappedTiles?.0.col ||
                    $0.row == lastSwappedTiles?.1.row && $0.col == lastSwappedTiles?.1.col
                }) ?? component.first!

                var state: RipenessState?
                if count >= 5 { state = (rs.count == 1 || cs.count == 1) ? .rainbow : .bomb }
                else if count == 4 { state = rs.count == 1 ? .rowClearer : .colClearer }

                if let s = state {
                    spawns.append(HarvestTile(variety: variety, state: s, row: spawnPt.row, col: spawnPt.col))
                    toRemove.remove(spawnPt)
                }
            }
        }
        return (toRemove, spawns)
    }

    // MARK: - Gravity & Refill

    private func applyOrganicGravity() {
        for col in 0..<cols {
            var empty = rows - 1
            for row in (0..<rows).reversed() {
                if let tile = nectarGrid[row][col] {
                    if empty != row {
                        var t = tile; t.row = empty
                        nectarGrid[empty][col] = t
                        nectarGrid[row][col] = nil
                    }
                    empty -= 1
                }
            }
        }
    }

    private func refillOrchard() {
        for col in 0..<cols {
            for row in 0..<rows {
                if nectarGrid[row][col] == nil {
                    let v = FruitVariety.allCases.randomElement()!
                    nectarGrid[row][col] = HarvestTile(variety: v, row: row, col: col)
                }
            }
        }
    }

    // MARK: - Haptics

    private func triggerHaptics(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.impactOccurred()
        if style == .heavy {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        #endif
    }
}
