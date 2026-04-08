import SwiftUI

// MARK: - Harvest Grid View (Main Gameplay Screen)

struct HarvestGridView: View {
    let level: Int
    @Binding var navigationPath: NavigationPath
    let onOpenShop: () -> Void

    @State private var orchestrator: OrchardOrchestrator
    @State private var activeDragId: String? = nil
    @State private var dragOffsets: [String: CGSize] = [:]

    private let spacing: CGFloat = 4
    private let progression = ProgressionManager.shared

    init(level: Int, navigationPath: Binding<NavigationPath>, onOpenShop: @escaping () -> Void) {
        self.level = level
        self._navigationPath = navigationPath
        self.onOpenShop = onOpenShop
        self._orchestrator = State(initialValue: OrchardOrchestrator(level: level))
    }

    var body: some View {
        ZStack {
            // Purple/Candy Gradient Background
            LinearGradient(
                colors: [
                    Color(hex: "#3B0764"),
                    Color(hex: "#6B21A8"),
                    Color(hex: "#C026D3"),
                    Color(hex: "#6B21A8"),
                    Color(hex: "#3B0764")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle floating blobs
            floatingBlobs

            VStack(spacing: 0) {
                topHeader
                    .padding(.top, 50)
                    .padding(.bottom, 8)

                progressBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                gameBoard
                    .padding(.horizontal, 12)
                    .padding(.bottom, 30)

                movesMeter
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: orchestrator.comboMultiplier)
        // Out of Moves Sheet
        .sheet(isPresented: $orchestrator.isGameOver) {
            OutOfMovesSheet(orchestrator: orchestrator, navigationPath: $navigationPath)
                .presentationDetents([.medium])
                .presentationCornerRadius(32)
        }
        // Level Clear Sheet
        .sheet(isPresented: $orchestrator.isLevelClear) {
            LevelClearSheet(
                level: level,
                score: orchestrator.score,
                targetScore: orchestrator.targetScore,
                navigationPath: $navigationPath
            )
            .presentationDetents([.medium])
            .presentationCornerRadius(32)
        }
    }

    // MARK: - Floating Background Blobs
    private var floatingBlobs: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill([Color(hex: "#EC4899"), Color(hex: "#A855F7"), Color(hex: "#7C3AED")][i % 3].opacity(0.12))
                    .frame(width: CGFloat([80, 120, 60, 100, 90][i]))
                    .offset(x: CGFloat([-120, 130, -80, 90, -60][i]), y: CGFloat([-200, -50, 100, 200, -150][i]))
                    .blur(radius: 30)
            }
        }
    }

    // MARK: - Top Header
    private var topHeader: some View {
        HStack(alignment: .center) {
            // Back / Menu button
            Button {
                navigationPath.removeLast()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("JUICY SMASH 2")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFE4E1"), Color(hex: "#FF69B4")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.8), radius: 4, y: 2)
                Text("LEVEL \(level)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(2)
            }

            Spacer()

            // Coin Indicator (Pill style with green plus button)
            Button(action: onOpenShop) {
                HStack(spacing: 6) {
                    Image(systemName: "circle.circle.fill")
                        .foregroundColor(Color(hex: "#FFD700"))
                        .font(.system(size: 16))
                    Text("\(progression.coins)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(Circle().fill(Color(hex: "#34C759")))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            
            Spacer()

            // Score badge
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        .font(.system(size: 14))
                    Text("\(orchestrator.score)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                )
                if orchestrator.comboMultiplier > 1 {
                    Text("x\(orchestrator.comboMultiplier) COMBO!")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange, .red], startPoint: .leading, endPoint: .trailing))
                        .shadow(color: .orange.opacity(0.8), radius: 3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Score Progress Bar
    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("TARGET")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
                Spacer()
                Text("\(orchestrator.score) / \(orchestrator.targetScore)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }

            GeometryReader { geo in
                let progress = min(1.0, CGFloat(orchestrator.score) / CGFloat(orchestrator.targetScore))
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.35))
                        .frame(height: 12)
                    // Fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F472B6"), Color(hex: "#A855F7")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 12)
                        .shadow(color: Color(hex: "#F472B6").opacity(0.6), radius: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: orchestrator.score)

                    // Star markers (1x, 1.3x/1.5x, 1.6x/2x threshold indicators)
                    let thresholds: [Double] = level <= 10 ? [1.0, 1.3, 1.6] : [1.0, 1.5, 2.0]
                    ForEach(thresholds.indices, id: \.self) { i in
                        let t = min(1.0, thresholds[i] / (level <= 10 ? 1.6 : 2.0))
                        Image(systemName: orchestrator.score >= Int(Double(orchestrator.targetScore) * thresholds[i])
                              ? "star.fill" : "star")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                            .offset(x: geo.size.width * CGFloat(t) - 5, y: -1)
                    }
                }
            }
            .frame(height: 20)
        }
    }

    // MARK: - Game Board
    private var gameBoard: some View {
        GeometryReader { geo in
            let boardSize = min(geo.size.width, geo.size.height) - 12
            let tileSize  = (boardSize - CGFloat(orchestrator.cols + 1) * spacing) / CGFloat(orchestrator.cols)

            ZStack(alignment: .topLeading) {
                // Slot Background Grid
                VStack(spacing: spacing) {
                    ForEach(0..<orchestrator.rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<orchestrator.cols, id: \.self) { col in
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }

                // Active Tiles
                let allTiles = orchestrator.nectarGrid.flatMap { $0 }.compactMap { $0 }
                ForEach(allTiles, id: \.id) { tile in
                    let xPos = CGFloat(tile.col) * (tileSize + spacing) + (tileSize / 2)
                    let yPos = CGFloat(tile.row) * (tileSize + spacing) + (tileSize / 2)

                    TileView(tile: tile, size: tileSize)
                        .position(x: xPos, y: yPos)
                        .offset(dragOffsets[tile.id] ?? .zero)
                        .zIndex(dragOffsets[tile.id] != nil && dragOffsets[tile.id] != .zero ? 100 : 0)
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    guard activeDragId != tile.id else { return }
                                    let trans = value.translation
                                    if abs(trans.width) > 18 || abs(trans.height) > 18 {
                                        activeDragId = tile.id
                                        handleSwipe(on: tile, translation: trans)
                                        withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                                            dragOffsets[tile.id] = .zero
                                        }
                                    } else {
                                        dragOffsets[tile.id] = trans
                                    }
                                }
                                .onEnded { _ in
                                    activeDragId = nil
                                    withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                                        dragOffsets[tile.id] = .zero
                                    }
                                }
                        )
                }

                // Floating Score Overlays
                GeometryReader { _ in
                    ForEach(orchestrator.floatingScores) { fs in
                        let xOff = spacing + CGFloat(fs.col) * (tileSize + spacing) + (tileSize / 2)
                        let yOff = spacing + CGFloat(fs.row) * (tileSize + spacing) + (tileSize / 2)
                        FloatingScoreView(score: fs)
                            .position(x: xOff, y: yOff)
                    }
                }
            }
            .padding(spacing)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.4), Color(hex: "#1E0B3A").opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#A855F7").opacity(0.4), Color(hex: "#EC4899").opacity(0.2)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color(hex: "#7C3AED").opacity(0.4), radius: 20, y: 8)
            .frame(width: boardSize, height: boardSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Moves Meter
    private var movesMeter: some View {
        HStack(spacing: 12) {
            ForEach(0..<max(0, min(20, orchestrator.movesLeft)), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#F472B6"), Color(hex: "#A855F7")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: 22)
                    .shadow(color: Color(hex: "#F472B6").opacity(0.5), radius: 3)
            }
            if orchestrator.movesLeft > 20 {
                Text("+\(orchestrator.movesLeft - 20)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(orchestrator.movesLeft)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(orchestrator.movesLeft <= 3 ? Color(hex: "#FF6B6B") : .white)
                    .contentTransition(.numericText())
                    .animation(.bouncy, value: orchestrator.movesLeft)
                Text("MOVES LEFT")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Swipe Handling
    private func handleSwipe(on tile: HarvestTile, translation: CGSize) {
        guard !orchestrator.isProcessing else { return }
        let absX = abs(translation.width), absY = abs(translation.height)
        var tr = tile.row, tc = tile.col
        if absX > absY { tc += translation.width > 0 ? 1 : -1 }
        else           { tr += translation.height > 0 ? 1 : -1 }
        guard tr >= 0, tr < orchestrator.rows, tc >= 0, tc < orchestrator.cols,
              let target = orchestrator.nectarGrid[tr][tc] else { return }
        orchestrator.attemptSwap(tile1: tile, tile2: target)
    }
}

// MARK: - Out of Moves Sheet

struct OutOfMovesSheet: View {
    @Bindable var orchestrator: OrchardOrchestrator
    @Binding var navigationPath: NavigationPath
    @State private var buyResult: BuyResult? = nil
    @State private var showBuyFeedback = false

    enum BuyResult { case success, notEnough }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#3B0764"), Color(hex: "#6B21A8")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#EC4899").opacity(0.2))
                        .frame(width: 90, height: 90)
                    Text("😵")
                        .font(.system(size: 52))
                }

                VStack(spacing: 6) {
                    Text("OUT OF MOVES!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#FFE4E1"), Color(hex: "#FF69B4")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    Text("Keep playing?")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Buy 5 Moves button
                JellyButton(
                    icon: "🍬",
                    label: "BUY 5 MOVES",
                    sublabel: "50 Coins",
                    gradient: [Color(hex: "#F472B6"), Color(hex: "#BE185D")]
                ) {
                    let ok = orchestrator.buyExtraMoves()
                    buyResult = ok ? .success : .notEnough
                    showBuyFeedback = true
                }

                // Watch Ad button (mock)
                JellyButton(
                    icon: "📺",
                    label: "WATCH AD",
                    sublabel: "Get 5 Moves Free",
                    gradient: [Color(hex: "#A855F7"), Color(hex: "#7C3AED")]
                ) {
                    orchestrator.watchAdForMoves()
                }

                // Give Up
                Button {
                    navigationPath.removeLast()
                } label: {
                    Text("Give Up")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .underline()
                }
            }
            .padding(32)
        }
        .alert(
            buyResult == .success ? "5 Moves Added! 🍬" : "Not Enough Coins 😔",
            isPresented: $showBuyFeedback
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(buyResult == .success ? "Keep smashing!" : "Watch an ad or give up.")
        }
    }
}

// MARK: - Level Clear Sheet

struct LevelClearSheet: View {
    let level: Int
    let score: Int
    let targetScore: Int
    @Binding var navigationPath: NavigationPath

    @State private var starsRevealed = 0
    @State private var coinsAwarded = false

    private var progression: ProgressionManager { ProgressionManager.shared }
    private var stars: Int { progression.calculateStars(level: level, score: score, targetScore: targetScore) }
    private var coinReward: Int { progression.coinsForStars(stars) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#3B0764"), Color(hex: "#6B21A8"), Color(hex: "#C026D3")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                // Celebration emoji
                Text("🎉")
                    .font(.system(size: 60))
                    .shadow(color: .yellow, radius: 12)

                Text("LEVEL CLEAR!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFE4E1"), Color(hex: "#FF69B4")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: .purple, radius: 6)

                // Stars row
                HStack(spacing: 16) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= starsRevealed ? "star.fill" : "star")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(
                                i <= starsRevealed
                                    ? LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: i <= starsRevealed ? .yellow.opacity(0.8) : .clear, radius: 8)
                            .scaleEffect(i <= starsRevealed ? 1.1 : 0.85)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(Double(i) * 0.25), value: starsRevealed)
                    }
                }

                // Score and coins info
                HStack(spacing: 20) {
                    VStack(spacing: 3) {
                        Text("\(score)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("SCORE")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .tracking(2)
                    }
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 36)
                    VStack(spacing: 3) {
                        HStack(spacing: 4) {
                            Text("💰")
                                .font(.system(size: 18))
                            Text("+\(coinReward)")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#FFD700"))
                        }
                        Text("COINS EARNED")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .tracking(2)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )

                // Continue button
                JellyButton(
                    icon: "▶️",
                    label: "CONTINUE",
                    sublabel: nil,
                    gradient: [Color(hex: "#F472B6"), Color(hex: "#9333EA")]
                ) {
                    navigationPath.removeLast()
                }
            }
            .padding(28)
        }
        .onAppear {
            // Unlock next level + award coins
            progression.unlockNextLevel(completedLevel: level)
            if !coinsAwarded {
                progression.addCoins(coinReward)
                progression.updateHighScore(newScore: score)
                coinsAwarded = true
            }
            // Animate stars one by one
            for i in 1...3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.35) {
                    if i <= stars { starsRevealed = i }
                }
            }
        }
    }
}

// MARK: - Jelly Button (Candy-themed reusable button)

struct JellyButton: View {
    let icon: String
    let label: String
    let sublabel: String?
    let gradient: [Color]
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3)) { pressed = false }
            }
            action()
        }) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    if let sub = sublabel {
                        Text(sub)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    // Jelly gloss top shine
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: gradient.last?.opacity(0.5) ?? .clear, radius: pressed ? 4 : 10, y: pressed ? 2 : 5)
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tile View

struct TileView: View {
    let tile: HarvestTile
    let size: CGFloat
    @State private var pulsePhase: Bool = false
    @State private var bombGlow: Bool = false
    @State private var rainbowRotation: Double = 0

    var body: some View {
        ZStack {
            if tile.state == .fresh           { fruitBody }
            if tile.state == .rowClearer      { fruitBody; stripedOverlay(horizontal: true) }
            if tile.state == .colClearer      { fruitBody; stripedOverlay(horizontal: false) }
            if tile.state == .bomb            { bombBody }
            if tile.state == .rainbow         { rainbowBody }
        }
        .frame(width: size, height: size)
    }

    private var fruitBody: some View {
        Text(tile.variety.emoji)
            .font(.system(size: size * 0.65))
            .shadow(color: Color(hex: tile.variety.primaryColorHexString).opacity(0.6), radius: 6)
            .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
    }

    private func stripedOverlay(horizontal: Bool) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: tile.variety.primaryColorHexString).opacity(0.5), .clear],
                    center: .center, startRadius: 0, endRadius: size * 0.5
                ))
                .frame(width: size, height: size).blur(radius: 3)

            ForEach(0..<3, id: \.self) { i in
                let offset = CGFloat(i - 1) * size * 0.18
                Capsule()
                    .fill(LinearGradient(
                        colors: [.clear, .white.opacity(0.9), .white, .white.opacity(0.9), .clear],
                        startPoint: horizontal ? .leading : .top,
                        endPoint: horizontal ? .trailing : .bottom
                    ))
                    .frame(width: horizontal ? size*0.85 : 2, height: horizontal ? 2 : size*0.85)
                    .offset(x: horizontal ? 0 : offset, y: horizontal ? offset : 0)
                    .opacity(pulsePhase ? 1.0 : 0.4)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulsePhase = true }
        }
    }

    private var bombBody: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "#4A4A4A"), Color(hex: "#1A1A1A"), .black],
                    center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.45
                ))
                .frame(width: size*0.72, height: size*0.72)
                .shadow(color: .red.opacity(bombGlow ? 0.8 : 0.2), radius: bombGlow ? 12 : 4)

            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .center))
                .frame(width: size*0.68, height: size*0.68)

            Path { p in
                let cx = size * 0.5
                p.move(to: CGPoint(x: cx, y: size * 0.16))
                p.addQuadCurve(to: CGPoint(x: cx + size*0.12, y: size*0.08),
                               control: CGPoint(x: cx + size*0.06, y: size*0.06))
            }
            .stroke(Color(hex: "#8B6914"), lineWidth: 2.5)

            Circle()
                .fill(bombGlow ? Color.orange : Color.yellow)
                .frame(width: bombGlow ? 8 : 5, height: bombGlow ? 8 : 5)
                .shadow(color: .orange, radius: bombGlow ? 6 : 2)
                .offset(x: size*0.12, y: -size*0.38)

            Text("💥").font(.system(size: size*0.28)).opacity(bombGlow ? 1 : 0.6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { bombGlow = true }
        }
    }

    private var rainbowBody: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
                Circle()
                    .fill(colors[i].opacity(0.4))
                    .frame(width: size*0.2, height: size*0.2)
                    .offset(y: -size*0.28)
                    .rotationEffect(.degrees(Double(i)*60 + rainbowRotation))
                    .blur(radius: 2)
            }
            Circle()
                .fill(AngularGradient(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                    center: .center,
                    startAngle: .degrees(rainbowRotation),
                    endAngle: .degrees(rainbowRotation + 360)
                ))
                .frame(width: size*0.65, height: size*0.65)
                .shadow(color: .purple.opacity(0.5), radius: 8)

            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.7), .clear],
                    center: .init(x: 0.3, y: 0.3), startRadius: 0, endRadius: size*0.3
                ))
                .frame(width: size*0.55, height: size*0.55)

            Image(systemName: "sparkle")
                .font(.system(size: size*0.22, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .white, radius: 4)
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { rainbowRotation = 360 }
        }
    }
}

// MARK: - Floating Score View

struct FloatingScoreView: View {
    let score: FloatingScore
    @State private var offset: CGFloat = 5
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text(score.text)
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: score.color), .white],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .shadow(color: .black, radius: 3, y: 1)
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { scale = 1.2 }
                withAnimation(.easeOut(duration: 1.0)) { offset = -60; opacity = 0 }
            }
    }
}
