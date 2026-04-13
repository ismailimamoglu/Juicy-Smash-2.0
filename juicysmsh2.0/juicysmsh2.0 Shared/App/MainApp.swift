import SwiftUI
import StoreKit

/// MainApp.swift: The root router of JUICY SMASH 2.0.
/// Consolidates views to ensure target compatibility and implements performance-optimized Sulu design.
struct MainApp: View {
    @State private var orchestrator = OrchardOrchestrator()
    @StateObject private var storeManager = StoreManager.shared
    
    // Animation & State
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var buttonOffsetY: CGFloat = 100
    @State private var buttonOpacity: Double = 0.0
    @State private var currentScreen: AppScreen = .main
    
    // UI Panels
    @State private var showShop: Bool = false
    @State private var showSettings: Bool = false
    @State private var showInfo: Bool = false
    @State private var isStarting: Bool = true
    
    // Sensor & Parallax
    @ObservedObject private var motion = MotionManager.shared
    @State private var currentMapColors: [Color]? = nil
    
    // PERFORMANCE OPTIMIZATION: Dynamic fruit count based on screen load
    private var activeFloatingFruits: [FloatingFruit] {
        let names = ["apple_tile", "orange_tile", "grapes_tile", "pear_tile", "banana_tile", "watermelon_tile"]
        // Reduce count in Map/Play to preserve FPS when ultraThinMaterial is active
        let count = (currentScreen == .main) ? 15 : 6
        return (0..<count).map { i in
            FloatingFruit(
                imageName: names[i % names.count],
                size: CGFloat.random(in: 35...65),
                startX: CGFloat.random(in: 20...380),
                duration: Double.random(in: 10...20),
                delay: Double.random(in: 0...5),
                spinRate: Double.random(in: 30...90)
            )
        }
    }
    
    var body: some View {
        ZStack {
            // MARK: - Global Sulu Background
            WatercolorBackground(tilt: motion.tilt, colors: currentMapColors)
                .ignoresSafeArea()
                .onAppear { motion.startMonitoring() }
                .drawingGroup() // Performance boost for static-ish layers
            
            // Performance Optimized Floating Assets
            ForEach(activeFloatingFruits) { fruit in
                FloatingFruitView(fruit: fruit)
            }
            
            // MARK: - Screen Router with Juicy Transitions
            switch currentScreen {
            case .main:
                mainMenuView
                    .transition(.juicyAlpha)
            case .map:
                LevelMapView(
                    onStartLevel: { level in
                        orchestrator.startLevel(level)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentScreen = .play }
                    },
                    onBackToMenu: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { 
                            currentScreen = .main 
                            currentMapColors = nil
                        }
                    },
                    onOpenShop: { withAnimation { showShop = true } },
                    showSettings: $showSettings,
                    onColorChange: { colors in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentMapColors = colors
                        }
                    }
                )
                .transition(.juicyAlpha)
            case .play:
                HarvestGridView(
                    orchestrator: orchestrator,
                    onGoHome: { withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentScreen = .main } },
                    onGoToMap: { withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentScreen = .map } },
                    onOpenShop: { withAnimation { showShop = true } },
                    onOpenSettings: { withAnimation { showSettings = true } }
                )
                .transition(.juicyAlpha)
            }
            
            // MARK: - Overlays
            if showShop {
                ShopView(
                    themeColors: ProgressionManager.shared.dynamicTheme(for: ProgressionManager.shared.maxUnlockedLevel),
                    onClose: { withAnimation { showShop = false } }
                )
                .zIndex(100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showSettings {
                SettingsView(onClose: { withAnimation { showSettings = false } })
                    .zIndex(100)
                    .transition(.scale.combined(with: .opacity))
            }
            
            if showInfo {
                InfoView(onClose: { withAnimation { showInfo = false } })
                    .zIndex(100)
                    .transition(.scale.combined(with: .opacity))
            }
            
            if isStarting {
                LaunchView()
                    .zIndex(200)
                    .transition(AnyTransition.opacity)
                    .onAppear {
                        ConsentManager.shared.startConsentFlow()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeOut(duration: 0.8)) { isStarting = false }
                        }
                    }
            }
        }
    }
    
    // MARK: - Main Menu Components
    private var mainMenuView: some View {
        GeometryReader { geo in
            let logoSize = min(geo.size.width * 0.8, 400)
            VStack(spacing: 0) {
                Spacer()
                
                // Animated Logo
                VStack(spacing: 8) {
                    HStack(spacing: -10) {
                        Image("apple_tile").resizable().scaledToFit().frame(width: logoSize * 0.18).rotationEffect(.degrees(-15))
                        Image("orange_tile").resizable().scaledToFit().frame(width: logoSize * 0.2).offset(y: -10)
                        Image("grapes_tile").resizable().scaledToFit().frame(width: logoSize * 0.18).rotationEffect(.degrees(15))
                    }
                    Text("JUICY").font(.system(size: logoSize * 0.18, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("SMASH").font(.system(size: logoSize * 0.18, weight: .black, design: .rounded)).foregroundColor(.white).offset(y: -5)
                    Text("2.0").font(.system(size: logoSize * 0.12, weight: .black, design: .rounded)).foregroundColor(.yellow).offset(y: -10)
                }
                .scaleEffect(logoScale).opacity(logoOpacity)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                
                Spacer().frame(height: 50)
                
                // Play Button
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentScreen = .map }
                } label: {
                    Text("PLAY")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#004B23"))
                        .frame(width: 260, height: 80)
                        .background(Capsule().fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)))
                        .overlay(Capsule().stroke(Color.white, lineWidth: 4))
                }
                .offset(y: buttonOffsetY).opacity(buttonOpacity)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            // Top Bar
            VStack {
                HStack {
                    Spacer()
                    Button(action: { withAnimation { showSettings = true } }) {
                        Image(systemName: "gearshape.fill").padding(12).background(.ultraThinMaterial).clipShape(Circle()).foregroundColor(.white)
                    }
                    Button(action: { withAnimation { showInfo = true } }) {
                        Image(systemName: "info.circle.fill").padding(12).background(.ultraThinMaterial).clipShape(Circle()).foregroundColor(.white)
                    }
                }
                .padding(.top, 50).padding(.horizontal, 25)
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8)) { logoScale = 1.0; logoOpacity = 1.0 }
            withAnimation(.spring(response: 0.7).delay(0.2)) { buttonOffsetY = 0; buttonOpacity = 1.0 }
        }
    }
}

// MARK: - Level Map View (Internal to project target)
struct LevelMapView: View {
    let onStartLevel: (Int) -> Void
    let onBackToMenu: () -> Void
    let onOpenShop: () -> Void
    @Binding var showSettings: Bool
    var onColorChange: ([Color]) -> Void
    
    @ObservedObject private var progression = ProgressionManager.shared
    @State private var selectedLevel: Int? = nil
    @State private var currentPage: Int = 0
    
    // Page groups with exact requested ranges and thematic colors
    struct WorldData { let name: String; let levels: [Int]; let colors: [Color]; let columns: Int }
    private let worlds: [WorldData] = [
        WorldData(name: "VILLAGE", levels: Array(1...5), colors: [Color(hex: "#FF80A8"), Color(hex: "#FFB347")], columns: 3),
        WorldData(name: "FOREST", levels: Array(6...15), colors: [Color(hex: "#7ED957"), Color(hex: "#48C9B0")], columns: 4),
        WorldData(name: "CITY", levels: Array(16...50), colors: [Color(hex: "#A569BD"), Color(hex: "#5DADE2")], columns: 6),
        WorldData(name: "SPACE", levels: Array(51...99), colors: [Color(hex: "#10002b"), Color(hex: "#7b2cbf")], columns: 6)
    ]
    
    var body: some View {
        ZStack {
            // MARK: - Sulu Map Depth
            ZStack {
                // Subtle tint gradient (Transparent to reveal background)
                LinearGradient(
                    colors: [worlds[currentPage].colors.first?.opacity(0.3) ?? .clear, .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                
                // Watercolor blobs for texture
                GeometryReader { geo in
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(worlds[currentPage].colors.first?.opacity(0.1) ?? .clear)
                            .frame(width: geo.size.width * 0.7).blur(radius: 60)
                            .offset(x: i % 2 == 0 ? -40 : 100, y: i == 0 ? -100 : 250)
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onBackToMenu) {
                        Image(systemName: "house.fill").padding(10).background(.ultraThinMaterial).clipShape(Circle()).foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("WORLD MAP").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                        Text(worlds[currentPage].name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.7))
                        
                        Button(action: onOpenShop) {
                            HStack(spacing: 4) {
                                Image(systemName: "cart.fill")
                                Text("\(progression.coins)").font(.system(size: 14, weight: .black, design: .rounded))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6).background(.ultraThinMaterial).cornerRadius(15).foregroundColor(.yellow)
                        }
                    }
                    Spacer()
                    // Settings button removed from Map, adding invisible spacer for header symmetry
                    Circle().fill(Color.clear).frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20).padding(.top, 10)
                
                TabView(selection: $currentPage) {
                    ForEach(0..<worlds.count, id: \.self) { index in
                        worldGrid(for: worlds[index]).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .onChange(of: currentPage) { newValue in
                    onColorChange(worlds[newValue].colors)
                }
            }
            .opacity(selectedLevel == nil ? 1.0 : 0.2)
            
            if let level = selectedLevel {
                Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { selectedLevel = nil }
                LevelPreviewPopup(
                    level: level, 
                    stars: progression.levelStars[level] ?? 0, 
                    onPlay: { selectedLevel = nil; onStartLevel(level) }, 
                    onClose: { selectedLevel = nil }
                )
            }
        }
        .onAppear { 
            scrollToCurrent() 
            onColorChange(worlds[currentPage].colors)
        }
    }
    
    private func scrollToCurrent() {
        let max = progression.maxUnlockedLevel
        if let idx = worlds.firstIndex(where: { $0.levels.contains(max) }) { currentPage = idx }
    }
    
    private func worldGrid(for world: WorldData) -> some View {
        ScrollView {
            VStack(spacing: 25) {
                let rows = chunked(world.levels, into: world.columns)
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 15) {
                        ForEach(rows[rowIndex], id: \.self) { level in
                            node(for: level)
                        }
                    }
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity)
        }
    }

    private func chunked<T>(_ array: [T], into size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0 ..< Swift.min($0 + size, array.count)])
        }
    }
    
    private func node(for level: Int) -> some View {
        let isUnlocked = level <= progression.maxUnlockedLevel || progression.debugUnlockAll
        let colors = progression.dynamicTheme(for: level)
        let isCurrent = level == (progression.levelStars.count + 1)
        
        return Button {
            if isUnlocked { 
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation { selectedLevel = level } 
            }
        } label: {
            VStack {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? colors.first!.opacity(0.7) : .gray.opacity(0.3))
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(.ultraThinMaterial))
                        .overlay(Circle().stroke(Color.white, lineWidth: isCurrent ? 3 : 1))
                    
                    if isUnlocked {
                        Text("\(level)").font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill").foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }
}

// MARK: - App Structure Definitions
@main struct JuicySmashApp: App { var body: some Scene { WindowGroup { MainApp() } } }
enum AppScreen { case main, map, play }

struct LevelPreviewPopup: View {
    let level: Int; let stars: Int; let onPlay: () -> Void; let onClose: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("LEVEL \(level)").font(.system(size: 30, weight: .black, design: .rounded))
            HStack(spacing: 10) { ForEach(1...3, id: \.self) { i in Image(systemName: "star.fill").font(.system(size: 35)).foregroundColor(i <= stars ? .yellow : .black.opacity(0.1)) } }
            Button(action: onPlay) {
                Text("PLAY").font(.system(size: 24, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Capsule().fill(Color.green))
            }
        }.padding(30).background(RoundedRectangle(cornerRadius: 25).fill(.white)).padding(40)
    }
}

struct SettingsView: View {
    let onClose: () -> Void; @ObservedObject private var prog = ProgressionManager.shared
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture(perform: onClose)
            VStack(spacing: 20) {
                Text("SETTINGS").font(.headline).foregroundColor(.white)
                Toggle("Sound", isOn: Binding(get: { prog.sfxEnabled }, set: { _ in prog.toggleSfx() })).tint(.purple)
                Toggle("Haptics", isOn: Binding(get: { prog.hapticsEnabled }, set: { _ in prog.toggleHaptics() })).tint(.purple)
                Button("CLOSE", action: onClose).padding().background(Capsule().fill(.purple)).foregroundColor(.white)
            }.padding(30).background(.ultraThinMaterial).cornerRadius(25).padding(40).foregroundColor(.white)
        }
    }
}

struct InfoView: View {
    let onClose: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture(perform: onClose)
            VStack(spacing: 15) {
                Text("GAME INFO").font(.headline).foregroundColor(.white)
                Text("Tap 3+ fruits to harvest!").font(.subheadline)
                Button("Terms of Use", action: { UIApplication.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) })
                Button("Privacy Policy", action: { UIApplication.shared.open(URL(string: "https://www.google.com")!) })
                Button("GOT IT", action: onClose).padding().background(Capsule().fill(.green)).foregroundColor(.white)
            }.padding(30).background(.ultraThinMaterial).cornerRadius(25).padding(40).foregroundColor(.white)
        }
    }
}

struct LaunchView: View {
    @State private var pulseScale: CGFloat = 0.8
    @State private var pulseOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#FF007F"), Color(hex: "#7A00E6"), Color(hex: "#00F0FF")],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 100...300))
                    .offset(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -300...300))
                    .blur(radius: 40)
            }
            
            Text("JUICY SMASH 2.0")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color(hex: "#FF007F"), radius: 15)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        pulseScale = 1.0
                        pulseOpacity = 1.0
                    }
                }
        }
    }
}
