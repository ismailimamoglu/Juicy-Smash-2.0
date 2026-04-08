import SwiftUI

struct HarvestGridView: View {
    @Bindable var orchestrator: OrchardOrchestrator
    @State private var activeDragId: String? = nil
    @State private var dragOffsets: [String: CGSize] = [:]
    
    var onBackToMenu: (() -> Void)? = nil
    var onOpenShop: (() -> Void)? = nil
    private let spacing: CGFloat = 6
    
    var body: some View {
        ZStack {
            // MARK: - Daytime Orchard Background
            backgroundLayer
            
            VStack(spacing: 0) {
                // MARK: - HUD Panel
                hudPanel
                    .padding(.bottom, 6)
                
                // TARGETING TEXT
                if orchestrator.activeBooster != nil {
                    Text("Select a fruit")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                        .padding(.bottom, 8)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // MARK: - Game Board
                gameBoardSection
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                
                // MARK: - Booster Bar
                if orchestrator.currentLevel >= 3 {
                    boosterBar
                        .padding(.bottom, 20)
                }
            }
            // Shake effect tied to heavy explosions
            .modifier(Shake(amount: 8, shakesPerUnit: 3, animatableData: CGFloat(orchestrator.shakeTrigger)))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: orchestrator.comboMultiplier)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: orchestrator.gamePhase)
            .animation(.easeInOut(duration: 0.3), value: orchestrator.scoreProgress)
            
            // MARK: - Overlays
            if orchestrator.gamePhase == .levelComplete {
                dimBackground
                victoryOverlay
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            
            if orchestrator.gamePhase == .levelFailed {
                dimBackground
                failedOverlay
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            
            if orchestrator.showInsufficientFunds {
                insufficientFundsOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Replaced Top Controls with the improved integrated HUD.
        }
    }
    
    // MARK: - Background Layer
    
    private var backgroundLayer: some View {
        ZStack {
            // Sunny Sky
            LinearGradient(
                colors: [
                    Color(hex: "#4FB8FF"), // Bright blue sky top
                    Color(hex: "#A8E1FF"), // Lighter horizon
                    Color(hex: "#8FE86C"), // Bright grass
                    Color(hex: "#66C931")  // Darker grass
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Subtle sun glow
            RadialGradient(
                colors: [Color.white.opacity(0.4), .clear],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Stylized soft trees (abstract background shapes)
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "#72D637").opacity(0.8))
                    .frame(width: 200, height: 200)
                    .position(x: -20, y: geo.size.height * 0.4)
                
                Circle()
                    .fill(Color(hex: "#72D637").opacity(0.8))
                    .frame(width: 250, height: 250)
                    .position(x: geo.size.width + 40, y: geo.size.height * 0.5)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - HUD Panel
    
    private var hudPanel: some View {
        VStack(spacing: 16) {
            // First Row: Back Button and Gold Bar
            HStack(alignment: .center) {
                // Left: Back Button
                Button {
                    onBackToMenu?()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                .padding(.top, 8)
                .padding(.leading, 12)
                
                Spacer()
                
                // Right: Gold Bar
                Button {
                    onOpenShop?()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.circle.fill")
                            .foregroundColor(Color(hex: "#FFD700"))
                            .font(.system(size: 20))
                        Text("\(ProgressionManager.shared.coins)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                            .animation(.spring(), value: ProgressionManager.shared.coins)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color(hex: "#34C759")))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.4))
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    )
                }
            }
            .padding(.horizontal, 16)
            
            // Second Row: Dedicated Level Title (Centered)
            Text("LEVEL \(orchestrator.currentLevel)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 2)
            
            // Third Row: Target and Moves (+ Score progress)
            // Using a clean pill for the stats so they are visible over the background
            HStack(spacing: 16) {
                // Target & Progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        // Current Score
                        HStack(spacing: 4) {
                            Text("SCORE:")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(orchestrator.score)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#FFD700"))
                                .contentTransition(.numericText())
                        }
                        
                        // Target Score
                        HStack(spacing: 4) {
                            Text("TARGET:")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(orchestrator.levelConfig.targetScore)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.3)).frame(height: 8)
                            Capsule().fill(LinearGradient(colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9500")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * orchestrator.scoreProgress), height: 8)
                                .shadow(color: Color.orange.opacity(0.6), radius: 4)
                            ForEach([0.33, 0.66, 1.0], id: \.self) { ratio in
                                Image(systemName: "star.fill").font(.system(size: 10, weight: .bold))
                                    .foregroundColor(orchestrator.scoreProgress >= ratio ? Color(hex: "#FFD700") : .white.opacity(0.5))
                                    .position(x: min(geo.size.width * ratio, geo.size.width - 5), y: 4)
                            }
                        }
                    }
                    .frame(height: 8)
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: 30)
                
                // Moves
                VStack(alignment: .center, spacing: 2) {
                    Text("MOVES")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 5) {
                        Image(systemName: "hand.tap.fill").font(.system(size: 12)).foregroundColor(.white)
                        Text("\(orchestrator.movesRemaining)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundColor(orchestrator.movesRemaining <= 3 ? Color(hex: "#FF6347") : .white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            )
            .padding(.horizontal, 24)
        }
        .padding(.top, 18) // Extra safe area padding
    }
    
    // MARK: - Game Board
    
    private var gameBoardSection: some View {
        GeometryReader { geo in
            let boardSize = min(geo.size.width, geo.size.height) - 16
            let tileSize = (boardSize - CGFloat(orchestrator.cols + 1) * spacing) / CGFloat(orchestrator.cols)
            
            ZStack(alignment: .topLeading) {
                // Slot grid background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#A8E1FF").opacity(0.5)) // Light blue semi-transparent board base
                
                // Slots (White boxes)
                VStack(spacing: spacing) {
                    ForEach(0..<orchestrator.rows, id: \.self) { _ in
                        HStack(spacing: spacing) {
                            ForEach(0..<orchestrator.cols, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white) // Solid white tile slot
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.05), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 2)
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }
                .padding(spacing)
                
                // Active tiles
                let allTiles = orchestrator.nectarGrid.flatMap { $0 }.compactMap { $0 }
                ForEach(allTiles, id: \.id) { tile in
                    let xPos = spacing + CGFloat(tile.col) * (tileSize + spacing) + (tileSize / 2)
                    let yPos = spacing + CGFloat(tile.row) * (tileSize + spacing) + (tileSize / 2)
                    
                    TileView(tile: tile, size: tileSize)
                        .position(x: xPos, y: yPos)
                        .offset(dragOffsets[tile.id] ?? .zero)
                        .shadow(color: orchestrator.activeBooster != nil ? Color.white : .clear, radius: orchestrator.activeBooster != nil ? 8 : 0)
                        .zIndex(dragOffsets[tile.id] != nil && dragOffsets[tile.id] != .zero ? 100 : 0)
                        .simultaneousGesture(
                            orchestrator.activeBooster != nil ? TapGesture().onEnded {
                                orchestrator.applyBooster(at: tile.row, col: tile.col)
                            } : nil
                        )
                        .simultaneousGesture(
                            orchestrator.activeBooster == nil ? DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    guard activeDragId != tile.id, !tile.isFrozen else { return }
                                    let trans = value.translation
                                    if abs(trans.width) > 18 || abs(trans.height) > 18 {
                                        activeDragId = tile.id
                                        handleSwipe(on: tile, translation: trans)
                                        // Delay offset reset safely
                                        DispatchQueue.main.async { dragOffsets[tile.id] = .zero }
                                    } else {
                                        dragOffsets[tile.id] = trans
                                    }
                                }
                                .onEnded { _ in
                                    activeDragId = nil
                                    withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                                        dragOffsets[tile.id] = .zero
                                    }
                                } : nil
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.0))
            )
            .frame(width: boardSize, height: boardSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                GeometryReader { _ in
                    // Render Particle effects
                    ForEach(orchestrator.activeParticles) { p in
                        let xOff = spacing + CGFloat(p.col) * (tileSize + spacing) + (tileSize / 2)
                        let yOff = spacing + CGFloat(p.row) * (tileSize + spacing) + (tileSize / 2)
                        ParticleBurstView(particle: p)
                            .position(x: xOff, y: yOff)
                    }
                    
                    // Render Floating Scores
                    ForEach(orchestrator.floatingScores) { fs in
                        let xOff = spacing + CGFloat(fs.col) * (tileSize + spacing) + (tileSize / 2)
                        let yOff = spacing + CGFloat(fs.row) * (tileSize + spacing) + (tileSize / 2)
                        FloatingScoreView(score: fs)
                            .position(x: xOff, y: yOff)
                    }
                }
            )
            .opacity(orchestrator.gamePhase == .playing ? 1.0 : 0.4)
            .blur(radius: orchestrator.gamePhase == .playing ? 0 : 2)
        }
    }
    
    // MARK: - Dim Background
    
    private var dimBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.6).ignoresSafeArea()
        }
        .transition(.opacity)
    }
    
    // MARK: - Victory Overlay
    
    private var victoryOverlay: some View {
        let stars = orchestrator.levelConfig.starsEarned(score: orchestrator.score)
        
        return VStack(spacing: 20) {
            Text("Amazing! 🎉")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
            
            Text("Level \(orchestrator.currentLevel) Complete!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 16) {
                ForEach(1...3, id: \.self) { i in
                    StarView(filled: i <= stars, index: i)
                }
            }
            .padding(.vertical, 8)
            
            Text("\(orchestrator.score) Points")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "#FFD700"))
                .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
            
            // REWARD DISPLAY
            HStack(spacing: 8) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#FFD700"))
                Text("+\(orchestrator.coinsEarned)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.2)))
            .padding(.top, -10)
            
            VStack(spacing: 14) {
                Button {
                    HighScoreManager.shared.updateIfNeeded(score: orchestrator.score)
                    orchestrator.advanceToNextLevel()
                } label: {
                    HStack(spacing: 8) {
                        Text("Next Level")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: "#FF9500"), Color(hex: "#FF5E3A")],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color(hex: "#FF5E3A").opacity(0.5), radius: 10, y: 4)
                    )
                }
                
                Button {
                    HighScoreManager.shared.updateIfNeeded(score: orchestrator.score)
                    onBackToMenu?()
                } label: {
                    Text("Level Map")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.top, 10)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(hex: "#4FB8FF").opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Failed Overlay
    
    private var failedOverlay: some View {
        VStack(spacing: 20) {
            Text("Oh No! 😢")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
            
            Text("Out of Moves!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Level \(orchestrator.currentLevel)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 4) {
                Text("\(orchestrator.score)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#FFD700"))
                Text("/")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                Text("\(orchestrator.levelConfig.targetScore)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Button {
                    orchestrator.buyExtraMoves()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Get More Moves")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                        Spacer()
                        HStack(spacing: 4) {
                            Text("50")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                            Image(systemName: "circle.circle.fill")
                                .foregroundColor(Color(hex: "#FFD700"))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#28A745")], startPoint: .top, endPoint: .bottom))
                            .shadow(color: Color(hex: "#28A745").opacity(0.5), radius: 8, y: 3)
                    )
                }
                
                Button {
                    // TODO: [INTEGRATION] Show Rewarded Video Ad SDK here to grant 5 extra moves.
                    orchestrator.watchAdForMoves()
                } label: {
                    HStack {
                        Image(systemName: "play.tv.fill")
                        Text("Watch Ad for +5 Moves")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.black.opacity(0.3)))
                }
                
                Button {
                    orchestrator.retryCurrentLevel()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .black))
                        Text("Retry")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "#00E5FF"), Color(hex: "#00B4D8")], startPoint: .top, endPoint: .bottom))
                            .shadow(color: Color(hex: "#00B4D8").opacity(0.5), radius: 6, y: 3)
                    )
                }
                
                Button {
                    onBackToMenu?()
                } label: {
                        Text("Level Map")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 4)
            }
            .padding(.top, 4)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(hex: "#FF5E3A").opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helpers
    
    private func handleSwipe(on tile: HarvestTile, translation: CGSize) {
        guard !orchestrator.isProcessing, orchestrator.gamePhase == .playing else { return }
        
        var targetRow = tile.row
        var targetCol = tile.col
        
        if abs(translation.width) > abs(translation.height) {
            targetCol += translation.width > 0 ? 1 : -1
        } else {
            targetRow += translation.height > 0 ? 1 : -1
        }
        
        guard targetRow >= 0, targetRow < orchestrator.rows,
              targetCol >= 0, targetCol < orchestrator.cols,
              let targetTile = orchestrator.nectarGrid[targetRow][targetCol] else { return }
        
        orchestrator.attemptSwap(tile1: tile, tile2: targetTile)
    }
    
    // MARK: - Booster UI Components
    
    private var boosterBar: some View {
        HStack(spacing: 20) {
            ForEach(BoosterType.allCases) { booster in
                Button {
                    if orchestrator.activeBooster == booster {
                        orchestrator.activeBooster = nil
                    } else {
                        orchestrator.activateBooster(booster)
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: booster.colorHex), Color(hex: booster.colorHex).opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 60, height: 60)
                                .shadow(color: Color(hex: booster.colorHex).opacity(0.5), radius: orchestrator.activeBooster == booster ? 10 : 4, y: orchestrator.activeBooster == booster ? 0 : 4)
                                // Pulsing border if active
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: orchestrator.activeBooster == booster ? 4 : 2)
                                )
                            
                            Image(systemName: booster.icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(orchestrator.activeBooster == booster ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5).repeatForever(autoreverses: true), value: orchestrator.activeBooster == booster)
                        }
                        
                        // Cost or Free badge
                        HStack(spacing: 2) {
                            if ProgressionManager.shared.hasFreeBooster(type: booster) {
                                Text("FREE")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: "#34C759")))
                            } else {
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "#FFD700"))
                                Text("\(booster.cost)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#2B4055"))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
    
    private var insufficientFundsOverlay: some View {
        VStack(spacing: 12) {
            Text("Insufficient Balance!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if onOpenShop != nil {
                Button {
                    orchestrator.showInsufficientFunds = false
                    onOpenShop?()
                } label: {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Get Coins")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: "#FFD700")))
                    .foregroundColor(Color(hex: "#2B4055"))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color.black.opacity(0.85)))
        .shadow(radius: 10)
        .padding(.top, 100)
    }
}

// MARK: - Particle Burst View

struct ParticleBurstView: View {
    let particle: ParticleEffect
    @State private var burstData: [(id: Int, x: CGFloat, y: CGFloat, scale: CGFloat)] = []
    
    var body: some View {
        ZStack {
            ForEach(burstData, id: \.id) { data in
                Circle()
                    .fill(Color(hex: particle.colorHex))
                    .frame(width: 12, height: 12)
                    .scaleEffect(data.scale)
                    .offset(x: data.x, y: data.y)
                    .opacity(data.scale > 0 ? 0.9 : 0)
            }
        }
        .onAppear {
            let count = particle.scatterCount
            for i in 0..<count { burstData.append((i, 0, 0, 1.0)) }
            withAnimation(.easeOut(duration: 0.5)) {
                for i in 0..<count {
                    let angle = Double(i) * (360.0 / Double(count))
                    let radius: CGFloat = CGFloat.random(in: 30...60)
                    burstData[i].x = cos(angle * .pi / 180) * radius
                    burstData[i].y = sin(angle * .pi / 180) * radius
                    burstData[i].scale = 0.0
                }
            }
        }
    }
}

// MARK: - Star View

struct StarView: View {
    let filled: Bool
    let index: Int
    @State private var animatedScale: CGFloat = 0.3
    @State private var animatedRotation: Double = -30
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: index == 2 ? 60 : 50, weight: .black))
            .foregroundStyle(
                filled ?
                LinearGradient(colors: [Color(hex: "#FFD700"), Color(hex: "#FF8C00")],
                               startPoint: .top, endPoint: .bottom) :
                LinearGradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.1)],
                               startPoint: .top, endPoint: .bottom)
            )
            .shadow(color: filled ? Color(hex: "#FFD700").opacity(0.6) : .clear, radius: 8)
            .overlay(
                Image(systemName: "star")
                    .font(.system(size: index == 2 ? 60 : 50, weight: .black))
                    .foregroundColor(filled ? .white.opacity(0.5) : .white.opacity(0.2))
            )
            .offset(y: index == 2 ? -10 : 0)
            .scaleEffect(animatedScale)
            .rotationEffect(.degrees(animatedRotation))
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(Double(index) * 0.15)) {
                    animatedScale = 1.0
                    animatedRotation = 0
                }
            }
    }
}

// MARK: - Tile View

struct TileView: View {
    let tile: HarvestTile
    let size: CGFloat
    
    var body: some View {
        ZStack {
            TileInnerCore(tile: tile, size: size)
            
            // Ice Overlay
            if tile.isFrozen {
                iceOverlay
            }
        }
        .frame(width: size, height: size)
    }
    
    private var iceOverlay: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(hex: "#C6F8FF").opacity(0.4))
            .background(.thinMaterial.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white, lineWidth: 3)
            )
            .overlay(
                // Thick Toon-style ice specular highlight
                Path { path in
                    path.move(to: CGPoint(x: size * 0.15, y: size * 0.2))
                    path.addLine(to: CGPoint(x: size * 0.45, y: size * 0.1))
                }.stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            )
            .shadow(color: Color(hex: "#00E5FF").opacity(0.4), radius: 6)
    }
}

private struct TileInnerCore: View {
    let tile: HarvestTile
    let size: CGFloat
    @State private var pulsePhase: Bool = false
    @State private var bombFlip: Bool = false
    @State private var rainbowRotation: Double = 0
    
    var body: some View {
        ZStack {
            switch tile.state {
            case .fresh:     fruitBody
            case .rowClearer: fruitBody; stripedOverlay(horizontal: true)
            case .colClearer: fruitBody; stripedOverlay(horizontal: false)
            case .bomb:      bombBody
            case .rainbow:   rainbowBody
            }
        }
    }
    
    private var fruitBody: some View {
        Image("\(tile.variety.rawValue)_tile")
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.85, height: size * 0.85) // Make asset fill the slot well
            .shadow(color: .black.opacity(0.25), radius: 2, y: 3) // Toon drop shadow
            .opacity(tile.isFrozen ? 0.7 : 1.0)
    }
    
    private func stripedOverlay(horizontal: Bool) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(0.8), .clear],
                                     center: .center, startRadius: 0, endRadius: size * 0.5))
                .frame(width: size, height: size)
            
            ForEach(0..<3, id: \.self) { i in
                let offset = CGFloat(i - 1) * size * 0.2
                Capsule()
                    .fill(Color.white)
                    .frame(width: horizontal ? size * 0.9 : 4, height: horizontal ? 4 : size * 0.9)
                    .offset(x: horizontal ? 0 : offset, y: horizontal ? offset : 0)
                    .opacity(pulsePhase ? 1.0 : 0.5)
                    .shadow(color: .black.opacity(0.2), radius: 1)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulsePhase = true } }
    }
    
    // Toon Bomb
    private var bombBody: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.8, height: size * 0.8)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 4)
            
            // Gloss highlight
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: -size * 0.15, y: -size * 0.15)
            
            Text("🧨")
                .font(.system(size: size * 0.45))
                .scaleEffect(bombFlip ? 1.2 : 1.0)
        }
        .onAppear { withAnimation(.spring(response: 0.3, dampingFraction: 0.5).repeatForever(autoreverses: true)) { bombFlip = true } }
    }
    
    // Toon Rainbow/Disco
    private var rainbowBody: some View {
        ZStack {
            Circle()
                .fill(AngularGradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                                      center: .center, startAngle: .degrees(rainbowRotation), endAngle: .degrees(rainbowRotation + 360)))
                .frame(width: size * 0.85, height: size * 0.85)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
            
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.4, weight: .black))
                .foregroundColor(.white)
        }
        .onAppear { withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) { rainbowRotation = 360 } }
    }
}

// MARK: - Floating Score

struct FloatingScoreView: View {
    let score: FloatingScore
    @State private var offset: CGFloat = 5
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Text(score.text)
            .font(.system(size: 26, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            // Thick stroke effect for Toon Score
            .shadow(color: Color(hex: score.color), radius: 1)
            .shadow(color: Color(hex: score.color), radius: 1)
            .shadow(color: Color(hex: score.color), radius: 1)
            .shadow(color: .black.opacity(0.5), radius: 2, y: 2)
            .offset(y: offset).opacity(opacity).scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { scale = 1.2 }
                withAnimation(.easeOut(duration: 0.8)) { offset = -50; opacity = 0 }
            }
    }
}

// MARK: - Hex Color Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    HarvestGridView(orchestrator: OrchardOrchestrator())
}
