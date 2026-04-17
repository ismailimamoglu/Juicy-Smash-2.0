import SwiftUI
import StoreKit

/// MainApp.swift: The root router of JUICY SMASH 2.0.
/// Consolidates views to ensure target compatibility and implements performance-optimized Sulu design.
struct MainApp: View {
    @State private var orchestrator = OrchardOrchestrator()
    @StateObject private var storeManager = StoreManager.shared
    
    // Animation & State
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
                MainMenuView(
                    onPlay: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { currentScreen = .map }
                    },
                    onOpenInfo: {
                        withAnimation { showInfo = true }
                    },
                    onOpenSettings: {
                        withAnimation { showSettings = true }
                    }
                )
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
    
}



// MARK: - App Structure Definitions
@main struct JuicySmashApp: App { var body: some Scene { WindowGroup { MainApp() } } }
enum AppScreen { case main, map, play }

