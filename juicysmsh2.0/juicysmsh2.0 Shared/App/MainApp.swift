import SwiftUI

/// MainApp.swift contains the new Toon-themed main menu and tab structural foundation.
struct MainApp: View {
    @State private var orchestrator = OrchardOrchestrator()

    
    // Animation states
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var buttonOffsetY: CGFloat = 100
    @State private var buttonOpacity: Double = 0.0
    @State private var currentScreen: AppScreen = .main
    
    // Auxiliary views flags
    @State private var showShop: Bool = false
    @State private var showSettings: Bool = false
    @State private var isStarting: Bool = true
    
    private let floatingFruits: [FloatingFruit] = {
        let names = ["apple_tile", "orange_tile", "grapes_tile", "pear_tile", "banana_tile", "watermelon_tile"]
        let allNames = names + names + names
        return allNames.enumerated().map { i, name in
            FloatingFruit(
                imageName: name,
                size: CGFloat.random(in: 30...65),
                startX: CGFloat.random(in: 20...380),
                duration: Double.random(in: 8...15),
                delay: Double.random(in: 0...5),
                spinRate: Double.random(in: 30...120) * (i % 2 == 0 ? 1 : -1)
            )
        }
    }()
    
    var body: some View {
        ZStack {
            // MARK: - Toon Purple/Blue Bright Background
            LinearGradient(
                colors: [Color(hex: "#A8E1FF"), Color(hex: "#C6F8FF"), Color(hex: "#E5DAFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Background clouds/shapes
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 250, height: 250)
                    .position(x: 40, y: geo.size.height * 0.2)
                
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .position(x: geo.size.width - 20, y: geo.size.height * 0.8)
                
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.1)
            }
            .ignoresSafeArea()
            
            // Active floating objects
            ForEach(floatingFruits) { fruit in
                FloatingFruitView(fruit: fruit)
            }
            
            // MARK: - Main Content Switch
            switch currentScreen {
            case .main:
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo Section
                    VStack(spacing: 8) {
                        // Display some actual fruit assets in the logo
                        HStack(spacing: -10) {
                            Image("apple_tile").resizable().scaledToFit().frame(width: 70)
                                .rotationEffect(.degrees(-15))
                            Image("orange_tile").resizable().scaledToFit().frame(width: 80)
                                .offset(y: -10)
                            Image("grapes_tile").resizable().scaledToFit().frame(width: 70)
                                .rotationEffect(.degrees(15))
                        }
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 5)
                        
                        Text("JUICY")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color(hex: "#FF5E3A"), radius: 1)
                            .shadow(color: Color(hex: "#FF5E3A"), radius: 1)
                            .shadow(color: Color(hex: "#FF5E3A"), radius: 1)
                            .shadow(color: Color(hex: "#FF5E3A"), radius: 1)
                            .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                        
                        Text("SMASH")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color(hex: "#00B4D8"), radius: 1)
                            .shadow(color: Color(hex: "#00B4D8"), radius: 1)
                            .shadow(color: Color(hex: "#00B4D8"), radius: 1)
                            .shadow(color: Color(hex: "#00B4D8"), radius: 1)
                            .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                            .offset(y: -12)

                        Text("2.0")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#FFD700"))
                            .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                            .offset(y: -20)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    Spacer().frame(height: 50)
                    
                    // Buttons
                    VStack(spacing: 20) {
                        // Play Button
                        Button {
                            // Haptic
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentScreen = .map
                            }
                        } label: {
                            Text("PLAY")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#004D40"))
                                .frame(width: 250, height: 80)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9500")],
                                            startPoint: .top, endPoint: .bottom
                                        ))
                                        .overlay(Capsule().stroke(Color.white, lineWidth: 4))
                                )
                                .shadow(color: Color(hex: "#FF9500").opacity(0.5), radius: 10, y: 8)
                        }
                        
                        // High Score
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#FFD700"))
                            Text("High Score: \(HighScoreManager.shared.highScore)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2B4055"))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .overlay(Capsule().stroke(Color(hex: "#FFD700").opacity(0.5), lineWidth: 2))
                                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
                        )
                    }
                    .offset(y: buttonOffsetY)
                    .opacity(buttonOpacity)
                    
                    Spacer()
                }
                .onAppear {
                    // Staggered entry
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                        buttonOffsetY = 0
                        buttonOpacity = 1.0
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
                
            case .map:
                LevelMapView(
                    onStartLevel: { level in
                        if !(orchestrator.currentLevel == level && orchestrator.gamePhase == .playing) {
                            orchestrator.startLevel(level)
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentScreen = .play
                        }
                    },
                    onBackToMenu: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentScreen = .main
                        }
                    },
                    onOpenShop: {
                        withAnimation { showShop = true }
                    },
                    showSettings: $showSettings
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .play:
                HarvestGridView(
                    orchestrator: orchestrator,
                    onBackToMenu: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentScreen = .map
                        }
                    },
                    onOpenShop: {
                        withAnimation { showShop = true }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                ))
            }
            
            // MARK: - Overlays
            if showShop {
                ShopView(onClose: {
                    withAnimation { showShop = false }
                })
                .zIndex(100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showSettings {
                SettingsView(onClose: {
                    withAnimation { showSettings = false }
                })
                .zIndex(100)
                .transition(.scale.combined(with: .opacity))
            }
            
            if isStarting {
                LaunchView()
                    .zIndex(200)
                    .transition(AnyTransition.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.8)) {
                                isStarting = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Launch Screen
struct LaunchView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotation: Double = -10
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#A8E1FF"), Color(hex: "#C6F8FF"), Color(hex: "#E5DAFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Fruit Icons
                HStack(spacing: -10) {
                    Image("apple_tile").resizable().scaledToFit().frame(width: 70)
                        .rotationEffect(.degrees(-15))
                    Image("orange_tile").resizable().scaledToFit().frame(width: 80)
                        .offset(y: -10)
                    Image("grapes_tile").resizable().scaledToFit().frame(width: 70)
                        .rotationEffect(.degrees(15))
                }
                .shadow(color: .black.opacity(0.2), radius: 5, y: 5)
                
                // JUICY SMASH 2.0
                VStack(spacing: 0) {
                    Text("JUICY")
                        .font(.system(size: 65, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color(hex: "#FF5E3A"), radius: 1)
                        .shadow(color: Color(hex: "#FF5E3A"), radius: 1)
                        .shadow(color: Color(hex: "#FF5E3A"), radius: 1)
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                    
                    Text("SMASH")
                        .font(.system(size: 65, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color(hex: "#00B4D8"), radius: 1)
                        .shadow(color: Color(hex: "#00B4D8"), radius: 1)
                        .shadow(color: Color(hex: "#00B4D8"), radius: 1)
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                        .offset(y: -12)
                    
                    Text("2.0")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#FFD700"))
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                        .offset(y: -20)
                }
                
                Text("Match & Smash!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2B4055").opacity(0.8))
                    .offset(y: -10)
            }
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
                rotation = 0
            }
        }
    }
}

// MARK: - Floating Fruit Model
private struct FloatingFruit: Identifiable {
    let id = UUID()
    let imageName: String
    let size: CGFloat
    let startX: CGFloat
    let duration: Double
    let delay: Double
    let spinRate: Double
}

struct FloatingFruitView: View {
    fileprivate let fruit: FloatingFruit
    @State private var yOffset: CGFloat = 1000
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(fruit.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: fruit.size, height: fruit.size)
            .shadow(color: .black.opacity(0.15), radius: 3)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .position(x: fruit.startX, y: yOffset)
            .onAppear {
                yOffset = 1000
                withAnimation(.linear(duration: fruit.duration).delay(fruit.delay).repeatForever(autoreverses: false)) {
                    yOffset = -150
                    rotation = fruit.spinRate
                }
                withAnimation(.easeIn(duration: 1.0).delay(fruit.delay)) {
                    opacity = 1.0
                }
            }
    }
}

enum AppScreen {
    case main
    case map
    case play
}



#Preview {
    MainApp()
}

// MARK: - App Screen Definitions

struct LevelMapView: View {
    let onStartLevel: (Int) -> Void
    let onBackToMenu: () -> Void
    let onOpenShop: () -> Void
    @Binding var showSettings: Bool
    
    @ObservedObject private var progression = ProgressionManager.shared
    @State private var selectedLevel: Int? = nil
    @State private var avatarBounce: Bool = false
    @State private var avatarAppear: Bool = false
    
    private let totalLevels = 50
    private let waveAmplitude: CGFloat = 30 // Reduced for a straighter path
    private let waveFrequency: CGFloat = 0.15
    
    // MARK: - Simplified Theme
    private var worldColors: [Color] {
        return [Color(hex: "#EEFBF3"), Color(hex: "#C8F7DC"), Color(hex: "#A8E6CF")]
    }
    
    private var worldDecorations: [String] {
        return ["☁️", "☁️", "☁️", "☁️"] // Simplified to just clouds
    }
    
    var body: some View {
        ZStack {
            // Dynamic World Background
            LinearGradient(
                colors: worldColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: progression.maxUnlockedLevel)
            
            GeometryReader { geo in
                // Simplified static clouds
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "cloud.fill")
                        .font(.system(size: CGFloat.random(in: 60...100)))
                        .foregroundColor(.white.opacity(0.6))
                        .position(
                            x: i % 2 == 0 ? 60 : geo.size.width - 60,
                            y: CGFloat(i) * (geo.size.height / 3) + 100
                        )
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach((1...totalLevels).reversed(), id: \.self) { level in
                                node(for: level)
                                    .id(level)
                                    .padding(.vertical, 30)
                            }
                        }
                        .padding(.vertical, 80)
                    }
                    .onAppear {
                        avatarAppear = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                proxy.scrollTo(progression.maxUnlockedLevel, anchor: .center)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                avatarAppear = true
                            }
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                avatarBounce = true
                            }
                        }
                        // Sync previous level for next navigation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            progression.syncPreviousMaxLevel()
                        }
                    }
                }
            }
            
            // Simplified Header shadow/separator
            VStack {
                Color.black.opacity(0.05).frame(height: 1)
                Spacer()
            }
            
            if let level = selectedLevel {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                    Color.black.opacity(0.6).ignoresSafeArea()
                }
                .onTapGesture { withAnimation { selectedLevel = nil } }
                
                LevelPreviewPopup(
                    level: level,
                    stars: progression.levelStars[level] ?? 0,
                    onPlay: {
                        withAnimation { selectedLevel = nil }
                        onStartLevel(level)
                    },
                    onClose: { withAnimation { selectedLevel = nil } }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: onBackToMenu) {
                Image(systemName: "house.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
            Spacer()
            Button(action: onOpenShop) {
                HStack(spacing: 6) {
                    Image(systemName: "circle.circle.fill")
                        .foregroundColor(Color(hex: "#FFD700"))
                        .font(.system(size: 20))
                    Text("\(progression.coins)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color(hex: "#34C759")))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.4)))
            }
            Spacer()
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10).padding(.bottom, 10)
        .background(Color.white.opacity(0.1))
    }
    
    private func node(for level: Int) -> some View {
        let isUnlocked = level <= progression.maxUnlockedLevel
        let isCurrent = level == progression.maxUnlockedLevel
        let stars = progression.levelStars[level] ?? 0
        let offset = sin(CGFloat(level) * waveFrequency * .pi) * waveAmplitude
        
        return HStack {
            if offset > 0 { Spacer().frame(width: offset * 2) }
            ZStack {
                // Connecting lines
                if level < totalLevels {
                    let nextOffset = sin(CGFloat(level + 1) * waveFrequency * .pi) * waveAmplitude
                    Path { path in
                        path.move(to: CGPoint(x: 40, y: 0))
                        path.addLine(to: CGPoint(x: 40 + (nextOffset - offset), y: -70))
                    }
                    .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1, 10]))
                    .offset(y: -40)
                }
                
                Button {
                    if isUnlocked {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedLevel = level }
                    }
                } label: {
                    ZStack {
                        if isUnlocked {
                            Circle().fill(Color.white.opacity(0.5)).frame(width: 90, height: 90).blur(radius: 5)
                        }
                        Circle()
                            .fill(isUnlocked 
                                  ? LinearGradient(colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF8E8E")], startPoint: .top, endPoint: .bottom) 
                                  : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                            .frame(width: isCurrent ? 85 : 75, height: isCurrent ? 85 : 75)
                            .overlay(Circle().stroke(Color.white, lineWidth: isCurrent ? 5 : 3))
                            .shadow(color: isUnlocked ? Color.red.opacity(0.2) : .clear, radius: 10, y: 5)
                        
                        if isUnlocked {
                            Text("\(level)").font(.system(size: isCurrent ? 34 : 28, weight: .black, design: .rounded)).foregroundColor(.white)
                        } else {
                            Image(systemName: "lock.fill").foregroundColor(.white.opacity(0.6)).font(.system(size: 24))
                        }
                        
                        if isUnlocked && stars > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...3, id: \.self) { i in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(i <= stars ? Color(hex: "#FFD700") : .white.opacity(0.3))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.2)))
                            .offset(y: 45)
                        }
                        
                        // MARK: - Avatar on current level
                        if isCurrent {
                            VStack(spacing: 0) {
                                Image("apple_tile")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .shadow(color: .white.opacity(0.8), radius: 10)
                                    .scaleEffect(avatarAppear ? 1.0 : 0.01)
                                    .offset(y: avatarBounce ? -8 : 0)
                            }
                            .offset(y: -65)
                        }
                    }
                    .scaleEffect(isCurrent ? 1.05 : 1.0)
                }.buttonStyle(PlainButtonStyle())
            }
            .frame(width: 80)
            if offset < 0 { Spacer().frame(width: abs(offset) * 2) }
        }
    }
}

struct LevelPreviewPopup: View {
    let level: Int; let stars: Int; let onPlay: () -> Void; let onClose: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Text("LEVEL \(level)").font(.system(size: 32, weight: .black, design: .rounded))
                Spacer()
                Button(action: onClose) { Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.black.opacity(0.2)) }
            }
            Text("Goal: Reach Score").font(.system(size: 18, weight: .bold)).foregroundColor(.gray)
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: "star.fill").font(.system(size: 40)).foregroundColor(i <= stars ? Color(hex: "#FFD700") : .black.opacity(0.1))
                }
            }
            Button(action: onPlay) {
                Text("PLAY").font(.system(size: 28, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Capsule().fill(LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#28A745")], startPoint: .top, endPoint: .bottom)))
            }
        }
        .padding(30).background(RoundedRectangle(cornerRadius: 30).fill(Color.white).shadow(radius: 20)).padding(.horizontal, 40)
    }
}

struct ShopView: View {
    let onClose: () -> Void
    @ObservedObject private var progression = ProgressionManager.shared
    @AppStorage("JuicySmashAdsWatchedToday") private var adsWatchedToday: Int = 0
    @AppStorage("JuicySmashLastAdDate") private var lastAdDate: Double = 0
    let maxAdsPerDay = 10
    
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture(perform: onClose)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("SHOP").font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(Color(hex: "#FFD700"))
                    Spacer()
                    Button(action: onClose) { Image(systemName: "xmark").font(.system(size: 24, weight: .bold)).foregroundColor(.white.opacity(0.7)).padding(12).background(Circle().fill(Color.white.opacity(0.1))) }.padding(.trailing, 20)
                }.padding(.top, 20).padding(.bottom, 30)
                HStack(spacing: 8) {
                    Image(systemName: "circle.circle.fill").font(.system(size: 28)).foregroundColor(Color(hex: "#FFD700"))
                    Text("\(progression.coins)").font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(.white)
                }.padding(.bottom, 40)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        adOfferCard(); Divider().background(Color.white.opacity(0.2))
                        iapCard(amount: 100, price: "$0.99", icon: "centsign.circle.fill", popular: false)
                        iapCard(amount: 500, price: "$3.99", icon: "dollarsign.circle.fill", popular: true)
                        iapCard(amount: 1200, price: "$7.99", icon: "banknote.fill", popular: false)
                    }.padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
        }.onAppear { checkAndResetAds() }
    }
    
    private func checkAndResetAds() {
        let lastDate = Date(timeIntervalSince1970: lastAdDate)
        if !Calendar.current.isDateInToday(lastDate) { adsWatchedToday = 0; lastAdDate = Date().timeIntervalSince1970 }
    }
    
    private func adOfferCard() -> some View {
        let canWatch = adsWatchedToday < maxAdsPerDay
        return Button {
            if canWatch {
                // TODO: [INTEGRATION] Initialize and show AdMob/AppLovin Rewarded Video SDK here.
                // NOTE: Move the logic below inside the reward callback function provided by the SDK.
                adsWatchedToday += 1
                lastAdDate = Date().timeIntervalSince1970
                progression.addCoins(amount: 100)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "play.tv.fill").font(.system(size: 40)).foregroundColor(.white)
                VStack(alignment: .leading, spacing: 4) {
                    Text("FREE COINS").font(.system(size: 22, weight: .black)).foregroundColor(.white)
                    Text("Watch short ad for 100 Coins").font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                VStack {
                    Text("\(maxAdsPerDay - adsWatchedToday)/\(maxAdsPerDay)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(canWatch ? Color(hex: "#FFD700") : .red)
                    Text("left").font(.system(size: 10)).foregroundColor(.white.opacity(0.7))
                }
            }.padding().background(RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: [Color(hex: "#8A2BE2"), Color(hex: "#9370DB")], startPoint: .leading, endPoint: .trailing))).opacity(canWatch ? 1.0 : 0.5)
        }.disabled(!canWatch)
    }
    
    private func iapCard(amount: Int, price: String, icon: String, popular: Bool) -> some View {
        Button {
            // TODO: [INTEGRATION] Call StoreKit SDK (e.g. RevenueCat) to initiate purchase for \(price).
            // NOTE: Move the logic below inside the successful purchase completion handler.
            progression.addCoins(amount: amount)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 60, height: 60)
                    Image(systemName: icon).font(.system(size: 30)).foregroundColor(Color(hex: "#FFD700"))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(amount) Coins").font(.system(size: 24, weight: .black)).foregroundColor(.white)
                    if popular {
                        Text("MOST POPULAR").font(.system(size: 10, weight: .black)).foregroundColor(.white).padding(4).background(Color.red)
                    }
                }
                Spacer()
                Text(price).font(.system(size: 18, weight: .bold)).foregroundColor(.black).padding(.horizontal, 16).padding(.vertical, 10).background(Capsule().fill(Color(hex: "#FFD700")))
            }.padding().background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
        }
    }
}

struct SettingsView: View {
    let onClose: () -> Void; @ObservedObject private var progression = ProgressionManager.shared
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture(perform: onClose)
            VStack(spacing: 24) {
                HStack { Text("SETTINGS").font(.system(size: 28, weight: .black)).foregroundColor(Color(hex: "#2B4055")); Spacer(); Button(action: onClose) { Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.black.opacity(0.2)) } }
                VStack(spacing: 16) {
                    Toggle(isOn: Binding(get: { progression.musicEnabled }, set: { _ in progression.toggleMusic() })) { HStack { Image(systemName: "music.note").foregroundColor(Color(hex: "#FF1493")).frame(width: 30); Text("Music").font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "#2B4055")) } }
                    Divider()
                    Toggle(isOn: Binding(get: { progression.sfxEnabled }, set: { _ in progression.toggleSfx() })) { HStack { Image(systemName: "speaker.wave.2.fill").foregroundColor(Color(hex: "#00E5FF")).frame(width: 30); Text("Sound Effects").font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "#2B4055")) } }
                }.padding(20).background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
                Text("Juicy Smash 2.0").font(.system(size: 14)).foregroundColor(.gray)
            }.padding(30).background(RoundedRectangle(cornerRadius: 30).fill(Color.white).shadow(radius: 20)).padding(.horizontal, 30)
        }
    }
}


@main
struct JuicySmashApp: App {
    var body: some Scene {
        WindowGroup {
            MainApp()
        }
    }
}
