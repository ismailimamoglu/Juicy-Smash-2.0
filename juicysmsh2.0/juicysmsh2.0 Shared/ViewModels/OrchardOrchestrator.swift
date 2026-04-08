import Foundation
import SwiftUI
import Observation

@Observable
final class OrchardOrchestrator {
    let rows = 8
    let cols = 8
    
    // Game state
    var nectarGrid: [[HarvestTile?]] = []
    var score: Int = 0
    var comboMultiplier: Int = 1
    
    // Level system
    var currentLevel: Int = 1
    var levelConfig: LevelConfig = LevelConfig.forLevel(1)
    var movesRemaining: Int = 0
    var gamePhase: GamePhase = .playing
    
    // Effects tracking
    var floatingScores: [FloatingScore] = []
    var activeParticles: [ParticleEffect] = []
    var shakeTrigger: Int = 0
    
    var lastSwappedTiles: (HarvestTile, HarvestTile)? = nil
    var isProcessing: Bool = false
    
    // Booster & UI State
    var activeBooster: BoosterType? = nil
    var showInsufficientFunds: Bool = false
    var coinsEarned: Int = 0
    
    /// Progress towards the target score (0.0 to 1.0+)
    var scoreProgress: Double {
        guard levelConfig.targetScore > 0 else { return 0 }
        return min(Double(score) / Double(levelConfig.targetScore), 1.0)
    }
    
    init() { startLevel(1) }
    
    // MARK: - Level Management
    
    func startLevel(_ level: Int) {
        currentLevel = level
        levelConfig = LevelConfig.forLevel(level)
        movesRemaining = levelConfig.maxMoves
        score = 0
        comboMultiplier = 1
        gamePhase = .playing
        floatingScores = []
        activeParticles = []
        lastSwappedTiles = nil
        isProcessing = false
        activeBooster = nil
        showInsufficientFunds = false
        coinsEarned = 0
        seedInitialOrchard()
    }
    
    @MainActor
    func advanceToNextLevel() { startLevel(currentLevel + 1) }
    
    @MainActor
    func retryCurrentLevel() { startLevel(currentLevel) }
    
    @MainActor
    private func checkLevelEnd() {
        if score >= levelConfig.targetScore && gamePhase == .playing {
            gamePhase = .levelComplete
            let stars = levelConfig.starsEarned(score: score)
            
            // Calculate rewards: Base 20 + 5 per remaining move
            let reward = ProgressionManager.shared.coinRewardForLevel(remainingMoves: movesRemaining)
            self.coinsEarned = reward
            ProgressionManager.shared.addCoins(amount: reward)
            
            ProgressionManager.shared.completeLevel(level: currentLevel, stars: stars)
            AudioManager.shared.playVictory()
            triggerHapticHaptics(style: .heavy)
        } else if movesRemaining <= 0 && score < levelConfig.targetScore && gamePhase == .playing {
            gamePhase = .levelFailed
            AudioManager.shared.playFailed()
        }
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
                
                // Ice blocks only from level 3+
                let isIce = Double.random(in: 0...1) < levelConfig.iceProbability
                nectarGrid[row][col] = HarvestTile(variety: variety, row: row, col: col, isFrozen: isIce)
            }
        }
    }
    
    private func createsMatchAtStart(row: Int, col: Int, variety: FruitVariety) -> Bool {
        if col >= 2, let l1 = nectarGrid[row][col-1], l1.variety == variety, let l2 = nectarGrid[row][col-2], l2.variety == variety { return true }
        if row >= 2, let u1 = nectarGrid[row-1][col], u1.variety == variety, let u2 = nectarGrid[row-2][col], u2.variety == variety { return true }
        return false
    }
    
    // MARK: - Boosters & Extra Moves
    
    @MainActor
    func activateBooster(_ type: BoosterType) {
        guard gamePhase == .playing, !isProcessing else { return }
        
        // Use free booster if available
        if ProgressionManager.shared.hasFreeBooster(type: type) {
            _ = ProgressionManager.shared.consumeFreeBooster(type: type)
            handleBoosterActivation(type)
        } else if ProgressionManager.shared.consumeCoins(amount: type.cost) {
            handleBoosterActivation(type)
        } else {
            showInsufficientFunds = true
            triggerHapticHaptics(style: .medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showInsufficientFunds = false
            }
        }
    }
    
    @MainActor
    private func handleBoosterActivation(_ type: BoosterType) {
        triggerHapticHaptics(style: .light)
        if type == .shuffle {
            applyShuffle()
        } else {
            activeBooster = type
        }
    }
    
    @MainActor
    func applyBooster(at row: Int, col: Int) {
        guard let booster = activeBooster, gamePhase == .playing, !isProcessing else { return }
        guard let _ = nectarGrid[row][col] else { return }
        
        activeBooster = nil
        isProcessing = true
        
        AudioManager.shared.playExplosion(isHuge: booster == .megaBlast)
        shakeTrigger += (booster == .megaBlast ? 2 : 1)
        triggerHapticHaptics(style: .heavy) // Impact feel
        
        Task { [weak self] in
            guard let self = self else { return }
            var destroyed = Set<HarvestTile>()
            if booster == .hammer {
                if let t = self.nectarGrid[row][col] { destroyed.insert(t) }
            } else if booster == .megaBlast {
                for r in max(0, row-1)...min(self.rows-1, row+1) {
                    for c in max(0, col-1)...min(self.cols-1, col+1) {
                        if let t = self.nectarGrid[r][c] { destroyed.insert(t) }
                    }
                }
            }
            
            self.awardPointsAndEmitParticles(for: destroyed, isRainbow: false)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                for tile in destroyed { self.nectarGrid[tile.row][tile.col] = nil }
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.applyOrganicGravity() }
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.refillOrchard() }
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            self.comboMultiplier = 1
            await self.processMatchesAndRefill()
        }
    }
    
    @MainActor
    private func applyShuffle() {
        isProcessing = true
        AudioManager.shared.playSwap()
        triggerHapticHaptics(style: .medium)
        
        var allTiles: [HarvestTile] = []
        for r in 0..<rows {
            for c in 0..<cols {
                if let t = nectarGrid[r][c] { allTiles.append(t) }
            }
        }
        
        allTiles.shuffle()
        
        var index = 0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            for r in 0..<rows {
                for c in 0..<cols {
                    if index < allTiles.count {
                        var t = allTiles[index]
                        t.row = r
                        t.col = c
                        nectarGrid[r][c] = t
                        index += 1
                    }
                }
            }
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                self.comboMultiplier = 1
            }
            await self.processMatchesAndRefill()
        }
    }
    
    @MainActor
    func buyExtraMoves() {
        if ProgressionManager.shared.consumeCoins(amount: 50) {
            movesRemaining += 5
            gamePhase = .playing
            triggerHapticHaptics(style: .heavy)
        } else {
            showInsufficientFunds = true
            triggerHapticHaptics(style: .medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showInsufficientFunds = false
            }
        }
    }
    
    @MainActor
    func watchAdForMoves() {
        movesRemaining += 5
        gamePhase = .playing
        triggerHapticHaptics(style: .heavy)
    }
    
    // MARK: - Interactions
    
    @MainActor
    func attemptSwap(tile1: HarvestTile, tile2: HarvestTile) {
        guard !isProcessing, gamePhase == .playing, movesRemaining > 0, activeBooster == nil else { return }
        
        // Block swaps of frozen tiles
        if tile1.isFrozen || tile2.isFrozen { return }
        
        let rowDiff = abs(tile1.row - tile2.row)
        let colDiff = abs(tile1.col - tile2.col)
        guard (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1) else { return }
        
        AudioManager.shared.playSwap()
        triggerHapticHaptics(style: .light)
        lastSwappedTiles = (tile1, tile2)
        isProcessing = true
        movesRemaining -= 1
        
        let rainbowSwap = tile1.state == .rainbow || tile2.state == .rainbow
        
        Task { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.swapInGrid(row1: tile1.row, col1: tile1.col, row2: tile2.row, col2: tile2.col)
                }
            }
            
            if rainbowSwap {
                let targetVariety = tile1.state == .rainbow ? tile2.variety : tile1.variety
                try? await Task.sleep(nanoseconds: 200_000_000)
                await MainActor.run {
                    AudioManager.shared.playExplosion(isHuge: true)
                    self.shakeTrigger += 1
                    self.triggerHapticHaptics(style: .heavy)
                    
                    var tilesToDestroy = Set<HarvestTile>()
                    for r in 0..<self.rows {
                        for c in 0..<self.cols {
                            if let t = self.nectarGrid[r][c], (t.variety == targetVariety || t.state == .rainbow) {
                                tilesToDestroy.insert(t)
                            }
                        }
                    }
                    
                    self.awardPointsAndEmitParticles(for: tilesToDestroy, isRainbow: true)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        for t in tilesToDestroy { self.nectarGrid[t.row][t.col] = nil }
                    }
                }
                
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.applyOrganicGravity() }
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.refillOrchard() }
                }
                try? await Task.sleep(nanoseconds: 400_000_000)
                
                self.comboMultiplier = 2
                await self.processMatchesAndRefill()
            } else {
                let matches = await MainActor.run { return self.findMatches() }
                let s1 = await MainActor.run { return self.nectarGrid[tile1.row][tile1.col] }
                let s2 = await MainActor.run { return self.nectarGrid[tile2.row][tile2.col] }
                let hasSpecial = (s1?.state != .fresh && s1 != nil) || (s2?.state != .fresh && s2 != nil)
                
                if matches.isEmpty && !hasSpecial {
                    await MainActor.run {
                        self.movesRemaining += 1
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.swapInGrid(row1: tile1.row, col1: tile1.col, row2: tile2.row, col2: tile2.col)
                        }
                        self.isProcessing = false
                    }
                } else if matches.isEmpty && hasSpecial {
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    
                    await MainActor.run {
                        var specialTargets = Set<HarvestTile>()
                        if let ts1 = s1, ts1.state != .fresh { specialTargets.insert(ts1) }
                        if let ts2 = s2, ts2.state != .fresh { specialTargets.insert(ts2) }
                        
                        AudioManager.shared.playExplosion(isHuge: true)
                        self.shakeTrigger += 1
                        self.triggerHapticHaptics(style: .heavy)
                        
                        let destroyedTiles = self.resolveExplosions(initialTargets: specialTargets)
                        self.awardPointsAndEmitParticles(for: destroyedTiles, isRainbow: false)
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            for t in destroyedTiles { self.nectarGrid[t.row][t.col] = nil }
                        }
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.applyOrganicGravity() }
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.refillOrchard() }
                    }
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    
                    self.comboMultiplier = 1
                    await self.processMatchesAndRefill()
                } else {
                    self.comboMultiplier = 1
                    await self.processMatchesAndRefill()
                }
            }
        }
    }
    
    private func swapInGrid(row1: Int, col1: Int, row2: Int, col2: Int) {
        let t = nectarGrid[row1][col1]
        nectarGrid[row1][col1] = nectarGrid[row2][col2]
        nectarGrid[row2][col2] = t
        nectarGrid[row1][col1]?.row = row1
        nectarGrid[row1][col1]?.col = col1
        nectarGrid[row2][col2]?.row = row2
        nectarGrid[row2][col2]?.col = col2
    }
    
    // MARK: - Matching Logic
    
    private func findMatches() -> Set<HarvestTile> {
        var matchedTiles = Set<HarvestTile>()
        for row in 0..<rows {
            var col = 0
            while col < cols - 2 {
                guard let current = nectarGrid[row][col] else { col += 1; continue }
                var m = 1
                while col + m < cols, let next = nectarGrid[row][col + m], next.variety == current.variety { m += 1 }
                if m >= 3 {
                    for i in 0..<m { if let t = nectarGrid[row][col + i] { matchedTiles.insert(t) } }
                }
                col += m
            }
        }
        for col in 0..<cols {
            var row = 0
            while row < rows - 2 {
                guard let current = nectarGrid[row][col] else { row += 1; continue }
                var m = 1
                while row + m < rows, let next = nectarGrid[row + m][col], next.variety == current.variety { m += 1 }
                if m >= 3 {
                    for i in 0..<m { if let t = nectarGrid[row + i][col] { matchedTiles.insert(t) } }
                }
                row += m
            }
        }
        return matchedTiles
    }
    
    @MainActor
    private func processMatchesAndRefill() async {
        var matches = findMatches()
        
        while !matches.isEmpty {
            let (toRemove, specialSpawns) = determineOutcomes(matches: matches)
            try? await Task.sleep(nanoseconds: 150_000_000)
            
            let destroyed = resolveExplosions(initialTargets: toRemove)
            let hasHeavy = destroyed.contains(where: { $0.state == .bomb || $0.state == .rainbow })
            let hasMedium = destroyed.contains(where: { $0.state == .rowClearer || $0.state == .colClearer })
            
            // Execute MainActor specific animation / interactions
            await MainActor.run {
                if hasHeavy {
                    AudioManager.shared.playExplosion(isHuge: true)
                    self.shakeTrigger += 1
                } else {
                    AudioManager.shared.playCombo(multiplier: self.comboMultiplier)
                }
                
                self.triggerHapticHaptics(style: hasHeavy ? .heavy : (hasMedium ? .medium : .light))
                self.awardPointsAndEmitParticles(for: destroyed, isRainbow: false)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    for tile in destroyed { self.nectarGrid[tile.row][tile.col] = nil }
                    for special in specialSpawns { self.nectarGrid[special.row][special.col] = special }
                }
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.applyOrganicGravity() }
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { self.refillOrchard() }
            }
            
            await MainActor.run {
                self.comboMultiplier += 1
            }
            
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            let matchCheckResolved = await MainActor.run {
                if self.score >= self.levelConfig.targetScore && self.gamePhase == .playing {
                    self.gamePhase = .levelComplete
                    let stars = self.levelConfig.starsEarned(score: self.score)
                    
                    let reward = ProgressionManager.shared.coinRewardForLevel(remainingMoves: self.movesRemaining)
                    self.coinsEarned = reward
                    ProgressionManager.shared.addCoins(amount: reward)
                    
                    ProgressionManager.shared.completeLevel(level: self.currentLevel, stars: stars)
                    AudioManager.shared.playVictory()
                    self.triggerHapticHaptics(style: .heavy)
                    self.isProcessing = false
                    return true
                }
                return false
            }
            if matchCheckResolved { return }
            
            matches = await MainActor.run { return self.findMatches() }
        }
        await MainActor.run {
            self.isProcessing = false
            self.checkLevelEnd()
        }
    }
    
    // Updates HUD and triggers particles for the destroyed tiles
    private func awardPointsAndEmitParticles(for tiles: Set<HarvestTile>, isRainbow: Bool) {
        let baseScore = isRainbow ? 30 : 10
        score += (tiles.count * baseScore * comboMultiplier)
        
        var newFloating = [FloatingScore]()
        var newParticles = [ParticleEffect]()
        var iceBroken = false
        
        for t in tiles {
            if t.isFrozen { iceBroken = true } // if any tile had ice
            newFloating.append(FloatingScore(text: "+\(baseScore * comboMultiplier)", color: t.variety.primaryColorHexString, row: t.row, col: t.col))
            newParticles.append(ParticleEffect(row: t.row, col: t.col, colorHex: t.variety.primaryColorHexString))
        }
        
        if iceBroken { AudioManager.shared.playIceBreak() }
        
        floatingScores.append(contentsOf: newFloating)
        activeParticles.append(contentsOf: newParticles)
        
        Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            let idsToRemove = Set(newFloating.map { $0.id })
            let pIdsToRemove = Set(newParticles.map { $0.id })
            await MainActor.run {
                self.floatingScores.removeAll { idsToRemove.contains($0.id) }
            }
            await MainActor.run {
                self.activeParticles.removeAll { pIdsToRemove.contains($0.id) }
            }
        }
    }
    
    private func resolveExplosions(initialTargets: Set<HarvestTile>) -> Set<HarvestTile> {
        var toProcess = Array(initialTargets)
        var destroyed = Set<HarvestTile>()
        
        while !toProcess.isEmpty {
            let current = toProcess.removeFirst()
            if destroyed.contains(current) { continue }
            guard let gridTile = nectarGrid[current.row][current.col] else { continue }
            destroyed.insert(current)
            
            switch gridTile.state {
            case .rowClearer:
                for c in 0..<cols { if let t = nectarGrid[current.row][c], !destroyed.contains(t) { toProcess.append(t) } }
            case .colClearer:
                for r in 0..<rows { if let t = nectarGrid[r][current.col], !destroyed.contains(t) { toProcess.append(t) } }
            case .bomb:
                for r in max(0, current.row-1)...min(rows-1, current.row+1) {
                    for c in max(0, current.col-1)...min(cols-1, current.col+1) {
                        if let t = nectarGrid[r][c], !destroyed.contains(t) { toProcess.append(t) }
                    }
                }
            case .rainbow:
                var vCount: [FruitVariety: Int] = [:]
                for r in 0..<rows { for c in 0..<cols {
                    if let t = nectarGrid[r][c], !destroyed.contains(t), t.state == .fresh { vCount[t.variety, default:0] += 1 }
                } }
                if let targetVariety = vCount.max(by: { $0.value < $1.value })?.key {
                    for r in 0..<rows { for c in 0..<cols {
                        if let t = nectarGrid[r][c], t.variety == targetVariety, !destroyed.contains(t) { toProcess.append(t) }
                    } }
                }
            case .fresh: break
            }
        }
        return destroyed
    }
    
    private func getConnectedComponents(from tiles: Set<HarvestTile>) -> [Set<HarvestTile>] {
        var unvisited = tiles
        var components: [Set<HarvestTile>] = []
        while let startNode = unvisited.first {
            var comp = Set<HarvestTile>()
            var queue = [startNode]
            unvisited.remove(startNode); comp.insert(startNode)
            while !queue.isEmpty {
                let n = queue.removeFirst()
                let adj = unvisited.filter { (abs($0.row - n.row) == 1 && $0.col == n.col) || (abs($0.col - n.col) == 1 && $0.row == n.row) }
                for a in adj { unvisited.remove(a); comp.insert(a); queue.append(a) }
            }
            components.append(comp)
        }
        return components
    }
    
    private func determineOutcomes(matches: Set<HarvestTile>) -> (Set<HarvestTile>, [HarvestTile]) {
        var toRemove = matches
        var spawns: [HarvestTile] = []
        
        let dictionary = Dictionary(grouping: matches, by: { $0.variety })
        for (variety, varietyTiles) in dictionary {
            for component in getConnectedComponents(from: Set(varietyTiles)) {
                let count = component.count
                if count >= 4 {
                    let rows = Set(component.map { $0.row }), cols = Set(component.map { $0.col })
                    let pivot = component.first(where: {
                        $0.row == lastSwappedTiles?.0.row && $0.col == lastSwappedTiles?.0.col ||
                        $0.row == lastSwappedTiles?.1.row && $0.col == lastSwappedTiles?.1.col
                    }) ?? component.first!
                    
                    var state: RipenessState? = nil
                    if count >= 5 {
                        state = (rows.count == 1 || cols.count == 1) ? .rainbow : .bomb
                    } else if count == 4 {
                        state = rows.count == 1 ? .rowClearer : .colClearer
                    }
                    if let state = state {
                        spawns.append(HarvestTile(variety: variety, state: state, row: pivot.row, col: pivot.col))
                        toRemove.remove(pivot)
                    }
                }
            }
        }
        return (toRemove, spawns)
    }
    
    private func applyOrganicGravity() {
        for col in 0..<cols {
            var emptyRowIndex = rows - 1
            for row in (0..<rows).reversed() {
                if let tile = nectarGrid[row][col] {
                    // Static obstacle behavior: frozen tiles do NOT fall
                    if tile.isFrozen {
                        emptyRowIndex = row - 1
                    } else {
                        if emptyRowIndex != row {
                            var movingTile = tile
                            movingTile.row = emptyRowIndex
                            nectarGrid[emptyRowIndex][col] = movingTile
                            nectarGrid[row][col] = nil
                        }
                        emptyRowIndex -= 1
                    }
                }
            }
        }
    }
    
    private func refillOrchard() {
        for col in 0..<cols {
            for row in 0..<rows {
                if nectarGrid[row][col] == nil {
                    // New falling tiles are never initially frozen.
                    let variety = FruitVariety.allCases.randomElement()!
                    nectarGrid[row][col] = HarvestTile(variety: variety, row: row, col: col, isFrozen: false)
                }
            }
        }
    }
    
    private func triggerHapticHaptics(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
        if style == .heavy {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        #endif
    }
}
