import SwiftUI

struct HarvestGridView: View {
    @Bindable var orchestrator: OrchardOrchestrator
    @State private var activeDragId: String? = nil
    @State private var dragOffsets: [String: CGSize] = [:]
    
    // Kinetic Storm States
    @State private var armedStorm: StormType? = nil
    @State private var stormTimerRemaining: Int = 8
    @State private var stormTimer: Timer? = nil
    @State private var showInsufficientCoinsForStorm = false
    @State private var showStormOverlay = false
    @StateObject private var motionManager = MotionManager.shared
    
    var onGoHome: (() -> Void)? = nil
    var onGoToMap: (() -> Void)? = nil
    var onOpenShop: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil
    private let spacing: CGFloat = 2.0
    
    var body: some View {
        GeometryReader { geo in
            let sc = min(geo.size.width, geo.size.height) / 100
            
            ZStack {
                // MARK: - Daytime Orchard Background
                backgroundLayer
                
                VStack(spacing: 0) {
                    Spacer().frame(height: geo.safeAreaInsets.top > 0 ? 8 : sc * 4)
                    
                    // MARK: - HUD Panel
                    hudPanel(sc: sc, width: geo.size.width)
                    
                    if let _ = orchestrator.activeBooster {
                        Text("Select a fruit")
                            .font(.system(size: sc * 4, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, sc * 1.5)
                            .padding(.horizontal, sc * 3)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .padding(.vertical, sc)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer(minLength: sc * 2)
                    
                    // MARK: - Game Board
                    gameBoardSection(sc: sc, size: geo.size)
                        .padding(.horizontal, sc * 2)
                    
                    Spacer(minLength: sc * 2)
                    
                    // MARK: - Booster Bar
                    if orchestrator.currentLevel >= 1 {
                        boosterBar(sc: sc, width: geo.size.width)
                            .padding(.bottom, sc * 2)
                            
                        kineticStormBar(sc: sc)
                            .padding(.horizontal, sc * 2)
                            .padding(.bottom, max(12, geo.safeAreaInsets.bottom))
                    }
                }
                .modifier(Shake(amount: 8, shakesPerUnit: 3, animatableData: CGFloat(orchestrator.shakeTrigger)))
                
                // MARK: - Overlays
                if orchestrator.gamePhase == .levelComplete {
                    dimBackground
                    victoryOverlay(sc: sc)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                
                if orchestrator.gamePhase == .levelFailed {
                    dimBackground
                    failedOverlay(sc: sc)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                
                if orchestrator.showInsufficientFunds {
                    insufficientFundsOverlay(sc: sc)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if showStormOverlay {
                    JuiceSplashOverlay()
                }
                
                if showInsufficientCoinsForStorm {
                    VStack {
                        Spacer()
                        Text("Insufficient Coins\n250 Coins required")
                            .multilineTextAlignment(.center)
                            .font(.system(size: geo.size.width * 0.04, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.8)))
                            .padding(.bottom, geo.size.height * 0.15)
                    }
                    .transition(.opacity)
                }
            }
            .onAppear { motionManager.startMonitoring() }
            .onDisappear { motionManager.stopMonitoring(); disarmStorm() }
            .onReceive(motionManager.$shakeDetected) { type in
                guard let type = type else { return }
                handleShake(type)
            }
        }
    }
    
    // MARK: - Background Layer
    
    private var backgroundLayer: some View {
        let themeColors = ProgressionManager.shared.dynamicTheme(for: orchestrator.currentLevel)
        
        return ZStack {
            // MARK: - Dynamic Theme Gradient Background (Semi-transparent)
            LinearGradient(
                colors: themeColors.map { $0.opacity(0.6) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Watercolor texture blobs using theme colors
            GeometryReader { geo in
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(themeColors[i % themeColors.count].opacity(0.08))
                        .frame(width: CGFloat([80, 120, 60, 100, 90][i]))
                        .position(
                            x: geo.size.width * CGFloat([0.15, 0.85, 0.3, 0.7, 0.5][i]),
                            y: geo.size.height * CGFloat([0.15, 0.3, 0.6, 0.8, 0.45][i])
                        )
                        .blur(radius: 35)
                }
            }
            .ignoresSafeArea()
            
            // MARK: - Dark Vignette + Radial Spotlight (Semi-transparent overlay)
            // Reduced opacity to allow global floating fruits to peek through
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            // Radial light — bright center that fades to dark edges (spotlight)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.04),
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - HUD Panel
    
    private func hudPanel(sc: CGFloat, width: CGFloat) -> some View {
        VStack(spacing: sc * 3) {
            HStack(alignment: .center) {
                HStack(spacing: sc * 2) {
                    Button(action: { 
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onGoHome?() 
                    }) {
                        Image(systemName: "house.fill").font(.system(size: sc * 4.5)).foregroundColor(.white).padding(sc * 2).background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    Button(action: { 
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onGoToMap?() 
                    }) {
                        Image(systemName: "map.fill").font(.system(size: sc * 4.5)).foregroundColor(.white).padding(sc * 2).background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    Button(action: { 
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onOpenSettings?() 
                    }) {
                        Image(systemName: "gearshape.fill").font(.system(size: sc * 4.5)).foregroundColor(.white).padding(sc * 2).background(Circle().fill(Color.black.opacity(0.3)))
                    }
                }
                Spacer()
                Button(action: { onOpenShop?() }) {
                    HStack(spacing: sc * 1.5) {
                        Image(systemName: "circle.circle.fill").foregroundColor(Color(hex: "#FFD700")).font(.system(size: sc * 4.5))
                        Text("\(ProgressionManager.shared.coins)").font(.system(size: sc * 4.5, weight: .black, design: .rounded)).foregroundColor(.white).contentTransition(.numericText())
                        Image(systemName: "plus").font(.system(size: sc * 3, weight: .bold)).foregroundColor(.white).padding(sc * 0.8).background(Circle().fill(Color(hex: "#34C759")))
                    }
                    .padding(.horizontal, sc * 3.5).padding(.vertical, sc * 2).background(Capsule().fill(Color.black.opacity(0.4)).overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)))
                }
            }
            .padding(.horizontal, sc * 4)
            
            Text("LEVEL \(orchestrator.currentLevel)").font(.system(size: sc * 6.5, weight: .black, design: .rounded)).foregroundColor(.white).shadow(color: .black.opacity(0.4), radius: 2, y: 2)
                .lineLimit(1).minimumScaleFactor(0.5)
            
            HStack(spacing: sc * 2) {
                VStack(alignment: .leading, spacing: sc * 1.5) {
                    HStack {
                        HStack(spacing: sc * 0.5) {
                            Text("SCORE:").font(.system(size: sc * 1.8, weight: .black)).foregroundColor(.white.opacity(0.6))
                                .lineLimit(1).minimumScaleFactor(0.5)
                            Text("\(abbreviateNumber(orchestrator.score))").font(.system(size: sc * 3.2, weight: .black)).foregroundColor(Color(hex: "#FFD700"))
                                .lineLimit(1).minimumScaleFactor(0.5)
                        }
                        
                        Spacer(minLength: sc)
                        
                        HStack(spacing: sc * 0.5) {
                            Text("TARGET:").font(.system(size: sc * 1.8, weight: .black)).foregroundColor(.white.opacity(0.6))
                                .lineLimit(1).minimumScaleFactor(0.5)
                            Text("\(abbreviateNumber(orchestrator.levelConfig.targetScore))").font(.system(size: sc * 3.2, weight: .black)).foregroundColor(.white)
                                .lineLimit(1).minimumScaleFactor(0.5)
                        }
                    }
                    .frame(width: width * 0.55)
                    
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.3)).frame(height: sc * 1.5)
                        Capsule().fill(LinearGradient(colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9500")], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, (width * 0.55) * orchestrator.scoreProgress), height: sc * 1.5)
                        ForEach([0.33, 0.66, 1.0], id: \.self) { ratio in
                            Image(systemName: "star.fill").font(.system(size: sc * 2.5))
                                .foregroundColor(orchestrator.scoreProgress >= ratio ? Color(hex: "#FFD700") : .white.opacity(0.5))
                                .position(x: (width * 0.55) * CGFloat(ratio), y: sc * 0.75)
                        }
                    }.frame(width: width * 0.55, height: sc * 1.5)
                }
                
                Rectangle().fill(Color.white.opacity(0.3)).frame(width: 2, height: sc * 6)
                
                VStack(alignment: .center, spacing: sc * 0.4) {
                    Text("MOVES").font(.system(size: sc * 2.2, weight: .black)).foregroundColor(.white.opacity(0.8))
                        .lineLimit(1).minimumScaleFactor(0.5)
                    HStack(spacing: sc) {
                        Image(systemName: "hand.tap.fill").font(.system(size: sc * 2.5)).foregroundColor(.white)
                        Text("\(orchestrator.movesRemaining)").font(.system(size: sc * 5, weight: .black)).foregroundColor(orchestrator.movesRemaining <= 3 ? Color(hex: "#FF6347") : .white)
                            .lineLimit(1).minimumScaleFactor(0.5)
                    }
                }
            }
            .padding(.horizontal, sc * 4).padding(.vertical, sc * 2.5).background(Capsule().fill(Color.black.opacity(0.2)).overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))).padding(.horizontal, sc * 5)
        }
    }
    
    // MARK: - Game Board
    
    private func gameBoardSection(sc: CGFloat, size: CGSize) -> some View {
        let cols = CGFloat(orchestrator.cols)
        let rows = CGFloat(orchestrator.rows)
        
        let availableW = size.width - (sc * 8)
        let availableH = size.height * 0.55
        
        let tileSizeW = (availableW - (cols + 1) * spacing) / cols
        let tileSizeH = (availableH - (rows + 1) * spacing) / rows
        let tileSize = min(tileSizeW, tileSizeH)
        
        let finalBW = cols * tileSize + (cols + 1) * spacing
        let finalBH = rows * tileSize + (rows + 1) * spacing
        
        return ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: sc * 4).fill(Color(hex: "#A8E1FF").opacity(0.5)).frame(width: finalBW, height: finalBH)
            
            // Slots
            VStack(spacing: spacing) {
                ForEach(0..<orchestrator.rows, id: \.self) { _ in
                    HStack(spacing: spacing) {
                        ForEach(0..<orchestrator.cols, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: sc * 2.5).fill(Color.white).frame(width: tileSize, height: tileSize)
                        }
                    }
                }
            }
            .frame(width: finalBW, height: finalBH)
            
            // Tiles
            ZStack(alignment: .topLeading) {
                let allTiles = orchestrator.nectarGrid.flatMap { $0 }.compactMap { $0 }
                ForEach(allTiles, id: \.id) { tile in
                    let xPos = spacing + CGFloat(tile.col) * (tileSize + spacing) + (tileSize / 2)
                    let yPos = spacing + CGFloat(tile.row) * (tileSize + spacing) + (tileSize / 2)
                    
                    tileView(for: tile, size: tileSize)
                        .position(x: xPos, y: yPos)
                        .offset(dragOffsets[tile.id] ?? .zero)
                        .zIndex(activeDragId == tile.id ? 100 : 0)
                        .simultaneousGesture(
                            orchestrator.activeBooster != nil ? TapGesture().onEnded { orchestrator.applyBooster(at: tile.row, col: tile.col) } : nil
                        )
                        .simultaneousGesture(
                            orchestrator.activeBooster == nil ? DragGesture(minimumDistance: 10)
                                .onChanged { v in
                                    guard activeDragId == nil || activeDragId == tile.id, !tile.isFrozen else { return }
                                    let trans = v.translation
                                    if abs(trans.width) > 15 || abs(trans.height) > 15 {
                                        if activeDragId == nil {
                                            activeDragId = tile.id
                                            handleSwipe(on: tile, translation: trans)
                                        }
                                        dragOffsets[tile.id] = .zero
                                    } else { dragOffsets[tile.id] = trans }
                                }
                                .onEnded { _ in 
                                    activeDragId = nil
                                    withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) { dragOffsets[tile.id] = .zero }
                                } : nil
                        )
                }
                
                // Overlay Effects (Particles, Scores)
                ForEach(orchestrator.activeParticles) { p in
                    let xOff = spacing + CGFloat(p.col) * (tileSize + spacing) + (tileSize / 2)
                    let yOff = spacing + CGFloat(p.row) * (tileSize + spacing) + (tileSize / 2)
                    ParticleBurstView(particle: p).position(x: xOff, y: yOff)
                }
                ForEach(orchestrator.floatingScores) { fs in
                    let xOff = spacing + CGFloat(fs.col) * (tileSize + spacing) + (tileSize / 2)
                    let yOff = spacing + CGFloat(fs.row) * (tileSize + spacing) + (tileSize / 2)
                    FloatingScoreView(score: fs).position(x: xOff, y: yOff)
                }
            }
            .frame(width: finalBW, height: finalBH)
        }
        .opacity(orchestrator.gamePhase == .playing ? 1.0 : 0.4)
        .blur(radius: orchestrator.gamePhase == .playing ? 0 : 2)
    }
    
    // MARK: - Tile View Component
    
    private func tileView(for tile: HarvestTile, size: CGFloat) -> some View {
        let isHinted = orchestrator.hintedTiles.contains(tile.id)
        
        return ZStack {
            // Main Fruit Image
            Image("\(tile.variety.rawValue)_tile")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.85, height: size * 0.85)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
            
            // Ripeness State Overlays
            if tile.state == .bomb {
                Circle().fill(Color.orange.opacity(0.3)).frame(width: size * 0.4).overlay(Image(systemName: "flame.fill").font(.system(size: size * 0.4)).foregroundColor(.white))
            } else if tile.state == .rowClearer || tile.state == .colClearer {
                Image(systemName: tile.state == .rowClearer ? "arrow.left.and.right.circle.fill" : "arrow.up.and.down.circle.fill")
                    .resizable().scaledToFit().frame(width: size * 0.4).foregroundColor(.white.opacity(0.8))
            } else if tile.state == .rainbow {
                Circle().strokeBorder(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple], center: .center), lineWidth: size * 0.1)
            }
            
            // Ice Overlay
            if tile.isFrozen {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(Color(hex: "#A8E1FF").opacity(0.6))
                    .overlay(RoundedRectangle(cornerRadius: size * 0.2).stroke(Color.white, lineWidth: 1))
                    .frame(width: size, height: size)
            }
            
            // Hint Highlight
            if isHinted {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .stroke(Color.white, lineWidth: 3)
                    .shadow(color: .white, radius: 4)
                    .scaleEffect(1.1)
            }
            
            // Active Booster Highlight
            if orchestrator.activeBooster != nil {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .stroke(Color.white, lineWidth: 2)
                    .shadow(color: .white, radius: 5)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isHinted ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isHinted)
    }
    
    // MARK: - Booster Bar
    
    private func boosterBar(sc: CGFloat, width: CGFloat) -> some View {
        let visibleBoosters: [BoosterType] = BoosterType.allCases
        let cSize = min(width * 0.15, sc * 15)
        
        return HStack(spacing: sc * 2) {
            ForEach(visibleBoosters) { booster in
                Button(action: { 
                    if orchestrator.activeBooster == booster { orchestrator.activeBooster = nil }
                    else { orchestrator.activateBooster(booster) }
                }) {
                    VStack(spacing: sc * 0.5) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [Color(hex: booster.colorHex), Color(hex: booster.colorHex).opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                .frame(width: cSize, height: cSize)
                                .shadow(color: Color(hex: booster.colorHex).opacity(0.5), radius: orchestrator.activeBooster == booster ? 10 : 4)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            Image(systemName: booster.icon).font(.system(size: cSize * 0.45, weight: .bold)).foregroundColor(.white)
                        }
                        
                        let free = orchestrator.remainingFreeForType(booster)
                        let persistent = ProgressionManager.shared.hasFreeBooster(type: booster)
                        
                        if free > 0 {
                            Text("\(free) FREE").font(.system(size: sc * 1.8, weight: .black)).foregroundColor(.white).padding(.horizontal, sc * 1.2).padding(.vertical, 2).background(Capsule().fill(Color.green))
                        } else if persistent {
                            Text("INV").font(.system(size: sc * 1.8, weight: .black)).foregroundColor(.white).padding(.horizontal, sc * 1.2).padding(.vertical, 2).background(Capsule().fill(Color.purple))
                        } else {
                            HStack(spacing: sc * 0.5) {
                                Image(systemName: "circle.circle.fill").font(.system(size: sc * 1.8)).foregroundColor(.yellow)
                                Text("\(booster == .hint ? 10 : booster.cost)").font(.system(size: sc * 2.2, weight: .black)).foregroundColor(Color(hex: "#2B4055"))
                            }
                        }
                    }
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, sc * 4).padding(.vertical, sc * 2).background(Capsule().fill(Color.white.opacity(0.9)).shadow(color: .black.opacity(0.1), radius: 8, y: 4))
    }
    
    // MARK: - Overlays (Victory, Failed, Balances)
    
    private func victoryOverlay(sc: CGFloat) -> some View {
        VStack(spacing: sc * 4) {
            Text("Amazing! 🎉").font(.system(size: sc * 8, weight: .black, design: .rounded)).foregroundColor(.white).shadow(radius: 5)
            let stars = orchestrator.levelConfig.starsEarned(score: orchestrator.score)
            HStack(spacing: sc * 3) {
                ForEach(1...3, id: \.self) { i in StarView(filled: i <= stars, index: i, sc: sc) }
            }
            
            VStack(spacing: sc) {
                Text("\(orchestrator.score) Points").font(.system(size: sc * 6, weight: .black)).foregroundColor(.yellow).shadow(radius: 2)
                HStack(spacing: sc) {
                    Image(systemName: "circle.circle.fill").foregroundColor(.yellow).font(.system(size: sc * 4))
                    Text("+\(orchestrator.coinsEarned)").font(.system(size: sc * 5, weight: .black)).foregroundColor(.white)
                }
                .padding(.horizontal, sc * 4).padding(.vertical, sc * 2).background(Capsule().fill(Color.white.opacity(0.2)))
            }
            
            VStack(spacing: sc * 2.5) {
                if orchestrator.currentLevel >= 99 {
                    Text("YOU COMPLETED THE GAME!")
                        .font(.system(size: sc * 3.5, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 5)
                        .padding(.vertical, sc)
                        
                    Button(action: { onGoToMap?() }) {
                        Text("Return to Map")
                            .font(.system(size: sc * 5, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, sc * 3)
                            .background(Capsule().fill(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)).shadow(radius: 5))
                            .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 2))
                    }
                } else {
                    Button(action: { orchestrator.advanceToNextLevel() }) {
                        Text("Next Level").font(.system(size: sc * 5, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, sc * 3).background(Capsule().fill(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)).shadow(radius: 5)).overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 2))
                    }
                    Button(action: { onGoToMap?() }) {
                        Text("Level Map").font(.system(size: sc * 3.5, weight: .bold)).foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(sc * 6).background(RoundedRectangle(cornerRadius: sc * 8).fill(Color(hex: "#4FB8FF").opacity(0.95)).overlay(RoundedRectangle(cornerRadius: sc * 8).stroke(Color.white, lineWidth: 4)).shadow(radius: 20))
        .padding(.horizontal, sc * 6)
    }
    
    private func failedOverlay(sc: CGFloat) -> some View {
        VStack(spacing: sc * 4) {
            Text("Oh No! 😢").font(.system(size: sc * 8, weight: .black)).foregroundColor(.white).shadow(radius: 5)
            Text("Out of Moves!").font(.system(size: sc * 5, weight: .bold)).foregroundColor(.white)
            
            VStack(spacing: sc * 2) {
                Button(action: { orchestrator.buyExtraMoves() }) {
                    HStack {
                        Text("Get +5 Moves").font(.system(size: sc * 4, weight: .black))
                        Spacer()
                        Text("50").font(.system(size: sc * 4, weight: .black))
                        Image(systemName: "circle.circle.fill").foregroundColor(.yellow)
                    }.foregroundColor(.white).padding(.horizontal, sc * 4).padding(.vertical, sc * 3).background(Capsule().fill(Color.green).shadow(radius: 5))
                }
                
                Button(action: { orchestrator.retryCurrentLevel() }) {
                    Text("Retry").font(.system(size: sc * 4, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, sc * 2.5).background(Capsule().fill(Color.blue.opacity(0.8)))
                }
                
                Button(action: { onGoToMap?() }) {
                    Text("Level Map").font(.system(size: sc * 3.5, weight: .bold)).foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(sc * 6).background(RoundedRectangle(cornerRadius: sc * 8).fill(Color(hex: "#FF5E3A").opacity(0.95)).overlay(RoundedRectangle(cornerRadius: sc * 8).stroke(Color.white, lineWidth: 4)).shadow(radius: 20))
        .padding(.horizontal, sc * 6)
    }
    
    private func insufficientFundsOverlay(sc: CGFloat) -> some View {
        VStack(spacing: sc * 2) {
            Text("Insufficient Balance!").font(.system(size: sc * 4, weight: .bold)).foregroundColor(.white)
            Button(action: { orchestrator.showInsufficientFunds = false; onOpenShop?() }) {
                Text("Get Coins").font(.system(size: sc * 3.5, weight: .bold)).padding(.horizontal, sc * 4).padding(.vertical, sc * 2).background(Capsule().fill(Color.yellow)).foregroundColor(.black)
            }
        }
        .padding(sc * 4).background(Capsule().fill(Color.black.opacity(0.85))).shadow(radius: 10).padding(.top, sc * 50)
    }
    
    private var dimBackground: some View {
        ZStack { Rectangle().fill(.ultraThinMaterial); Color.black.opacity(0.6) }.ignoresSafeArea()
    }
    
    // MARK: - Kinetic Storm Logic
    
    private func kineticStormBar(sc: CGFloat) -> some View {
        HStack(spacing: sc * 2.5) {
            StormWeaponButton(type: .vertical, isArmed: armedStorm == .vertical, tilt: motionManager.tilt, sc: sc) {
                if armedStorm == .vertical {
                    handleShake(.vertical) // Debug tap
                } else {
                    armStorm(type: .vertical)
                }
            }
            
            VStack {
                Text("KINETIC STORM")
                    .font(.system(size: sc * 2.2, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("- 250 Coins")
                    .font(.system(size: sc * 1.8, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#FFD700"))
                
                if let armed = armedStorm {
                    Text("\(armed.rawValue) Ready (\(stormTimerRemaining)s)")
                        .font(.system(size: sc * 1.5, weight: .bold))
                        .foregroundColor(.orange)
                        .transition(.scale)
                }
            }
            .animation(.default, value: armedStorm)
            
            StormWeaponButton(type: .horizontal, isArmed: armedStorm == .horizontal, tilt: motionManager.tilt, sc: sc) {
                if armedStorm == .horizontal {
                    handleShake(.horizontal) // Debug tap
                } else {
                    armStorm(type: .horizontal)
                }
            }
        }
        .padding(sc * 1.5)
        .background(
            RoundedRectangle(cornerRadius: sc * 2.5)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: sc * 2.5).stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                .shadow(color: armedStorm != nil ? .orange.opacity(0.3) : .clear, radius: 10)
        )
    }
    
    private func armStorm(type: StormType) {
        if ProgressionManager.shared.coins < ProgressionManager.shared.kineticStormCost {
            showInsufficientCoinsForStorm = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showInsufficientCoinsForStorm = false }
            return
        }
        
        armedStorm = type
        stormTimerRemaining = 8
        motionManager.playFluidSlosh()
        
        stormTimer?.invalidate()
        stormTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if stormTimerRemaining > 1 {
                stormTimerRemaining -= 1
            } else {
                disarmStorm()
            }
        }
    }
    
    private func disarmStorm() {
        armedStorm = nil
        stormTimer?.invalidate()
        stormTimer = nil
    }
    
    private func handleShake(_ type: StormType) {
        guard armedStorm == type else { return }
        disarmStorm()
        
        if ProgressionManager.shared.consumeKineticStormCoins() {
            motionManager.playStormExplosion()
            orchestrator.executeKineticStorm(vertical: type == .vertical)
            
            withAnimation(.easeOut(duration: 0.2)) { showStormOverlay = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeIn(duration: 0.5)) { showStormOverlay = false }
            }
        } else {
            showInsufficientCoinsForStorm = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showInsufficientCoinsForStorm = false }
        }
    }
    
    private func handleSwipe(on tile: HarvestTile, translation: CGSize) {
        var trRow = tile.row; var trCol = tile.col
        if abs(translation.width) > abs(translation.height) { trCol += translation.width > 0 ? 1 : -1 }
        else { trRow += translation.height > 0 ? 1 : -1 }
        guard trRow >= 0, trRow < orchestrator.rows, trCol >= 0, trCol < orchestrator.cols, let target = orchestrator.nectarGrid[trRow][trCol] else { return }
        orchestrator.attemptSwap(tile1: tile, tile2: target)
    }

    private func abbreviateNumber(_ num: Int) -> String {
        let absNum = abs(num)
        if absNum >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000.0).replacingOccurrences(of: ".0", with: "")
        } else if absNum >= 10_000 {
            return String(format: "%.1fK", Double(num) / 1_000.0).replacingOccurrences(of: ".0", with: "")
        } else {
            return "\(num)"
        }
    }
}

// MARK: - Subviews

struct StarView: View {
    let filled: Bool
    let index: Int
    let sc: CGFloat
    
    @State private var appeared = false
    
    var body: some View {
        Image(systemName: filled ? "star.fill" : "star")
            .font(.system(size: sc * 12, weight: .black))
            .foregroundColor(filled ? .yellow : .white.opacity(0.3))
            .scaleEffect(appeared ? 1.0 : 0.0)
            .rotationEffect(.degrees(appeared ? 0 : -45))
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15 * Double(index))) { appeared = true }
            }
    }
}

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
                    let dist = CGFloat.random(in: 40...100)
                    burstData[i].x = cos(angle * .pi / 180) * dist
                    burstData[i].y = sin(angle * .pi / 180) * dist
                    burstData[i].scale = 0
                }
            }
        }
    }
}

struct FloatingScoreView: View {
    let score: FloatingScore
    @State private var opacity: Double = 1.0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Text("+\(score.text)")
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black, radius: 2)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    offset = -60
                    opacity = 0
                }
            }
    }
}

// MARK: - Kinetic Storm Helpers

struct StormWeaponButton: View {
    let type: StormType
    let isArmed: Bool
    let tilt: CGSize
    let sc: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background Circle (Similar to classic boosters but distinct purple/cyan vibe)
                Circle()
                    .fill(LinearGradient(
                        colors: isArmed ? [Color.orange, Color.red] : [Color(hex: "#7A00E6"), Color(hex: "#00F0FF")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: sc * 12, height: sc * 12)
                    .shadow(color: isArmed ? .orange.opacity(0.8) : Color(hex: "#00F0FF").opacity(0.5), radius: isArmed ? 15 : 6)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                
                // Liquid Parallax inner fill if armed
                if isArmed {
                    GeometryReader { geo in
                        Circle()
                            .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                            .offset(x: tilt.width * 1.5, y: tilt.height * 1.5 + (sc * 4))
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: tilt)
                            .blendMode(.screen)
                    }
                    .clipShape(Circle())
                    .frame(width: sc * 12, height: sc * 12)
                }
                
                VStack(spacing: sc * 0.5) {
                    Image(systemName: type == .vertical ? "arrow.up.and.down" : "arrow.left.and.right")
                        .font(.system(size: sc * 4.5, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                    
                    if isArmed {
                        Text("SHAKE!")
                            .font(.system(size: sc * 1.8, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
            }
            .scaleEffect(isArmed ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isArmed)
        }
    }
}

struct JuiceParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let finalX: CGFloat
    let finalY: CGFloat
    let rotation: Double
}

struct JuiceSplashOverlay: View {
    @State private var particles: [JuiceParticle] = []
    @State private var isScattered = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: 50)) // Meyve boyutuna sabitlendi
                    .offset(x: isScattered ? p.finalX : 0, y: isScattered ? p.finalY : 0)
                    .rotationEffect(.degrees(isScattered ? p.rotation : 0))
                    .shadow(color: .white.opacity(0.8), radius: 5)
            }
        }
        .onAppear {
            let emojis = ["💦", "💥", "⚡️"]
            var newParticles = [JuiceParticle]()
            for _ in 0..<45 {
                newParticles.append(JuiceParticle(
                    emoji: emojis.randomElement()!,
                    finalX: CGFloat.random(in: -300...300),
                    finalY: CGFloat.random(in: -500...500),
                    rotation: Double.random(in: 0...360)
                ))
            }
            particles = newParticles
            
            // Hızlıca merkezden dışa saçılma animasyonu
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.4)) {
                    isScattered = true
                }
            }
        }
    }
}
