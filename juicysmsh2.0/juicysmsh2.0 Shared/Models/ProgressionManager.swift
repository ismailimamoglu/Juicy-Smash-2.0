import Foundation
import Combine
import CoreMotion
import CoreHaptics
import SwiftUI

final class ProgressionManager: ObservableObject {
    static let shared = ProgressionManager()
    private let defaults = UserDefaults.standard
    
    // Keys
    private let kHighScore = "JuicySmashHighScore"
    private let kMaxUnlockedLevel = "JuicySmashMaxUnlockedLevel"
    private let kCoins = "JuicySmashCoins"
    private let kLevelStars = "JuicySmashLevelStars"
    private let kMusicEnabled = "JuicySmashMusicEnabled"
    private let kSfxEnabled = "JuicySmashSfxEnabled"
    private let kHapticsEnabled = "JuicySmashHapticsEnabled"
    private let kPreviousMaxLevel = "JuicySmashPreviousMaxLevel"
    
    @Published var highScore: Int = 0
    @Published var maxUnlockedLevel: Int = 1
    @Published var debugUnlockAll: Bool = true // Enable all levels for testing
    @Published var coins: Int = 0
    @Published var levelStars: [Int: Int] = [:] // Level -> Stars
    @Published var freeBoosters: [String: Int] = [:] // BoosterType.rawValue -> Count
    @Published var previousMaxLevel: Int = 1
    
    @Published var musicEnabled: Bool = true
    @Published var sfxEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        highScore = defaults.integer(forKey: kHighScore)
        
        let savedMax = defaults.integer(forKey: kMaxUnlockedLevel)
        maxUnlockedLevel = savedMax > 0 ? savedMax : 1
        
        let savedCoins = defaults.integer(forKey: kCoins)
        if savedCoins == 0 && !defaults.bool(forKey: "JuicySmashStartingCoinsGranted") {
            coins = 10 // New players start with 10 coins
            defaults.set(true, forKey: "JuicySmashStartingCoinsGranted")
            defaults.set(coins, forKey: kCoins)
        } else {
            coins = savedCoins
        }
        
        if let data = defaults.data(forKey: kLevelStars),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            levelStars = decoded
        }
        
        if let bData = defaults.data(forKey: "JuicySmashFreeBoosters"),
           let bDecoded = try? JSONDecoder().decode([String: Int].self, from: bData) {
            freeBoosters = bDecoded
        }
        
        if maxUnlockedLevel >= 3 && !defaults.bool(forKey: "JuicySmashWelcomeGiftGranted") {
            grantWelcomeGift()
        }
        
        // Defaults to true implicitly if not set previously (or we can just check if object is nil)
        if defaults.object(forKey: kMusicEnabled) != nil {
            musicEnabled = defaults.bool(forKey: kMusicEnabled)
        }
        if defaults.object(forKey: kSfxEnabled) != nil {
            sfxEnabled = defaults.bool(forKey: kSfxEnabled)
        }
        if defaults.object(forKey: kHapticsEnabled) != nil {
            hapticsEnabled = defaults.bool(forKey: kHapticsEnabled)
        }
        let savedPrev = defaults.integer(forKey: kPreviousMaxLevel)
        previousMaxLevel = savedPrev > 0 ? savedPrev : maxUnlockedLevel
        if previousMaxLevel == 0 {
            previousMaxLevel = maxUnlockedLevel
        }
    }
    
    // API
    func updateHighScore(score: Int) {
        if score > highScore {
            highScore = score
            defaults.set(score, forKey: kHighScore)
        }
    }
    
    func completeLevel(level: Int, stars: Int) {
        // Update stars if better
        let currentStars = levelStars[level] ?? 0
        if stars > currentStars {
            levelStars[level] = stars
            if let encoded = try? JSONEncoder().encode(levelStars) {
                defaults.set(encoded, forKey: kLevelStars)
            }
        }
        
        // Reward Coins (Now handled in OrchardOrchestrator with bonus moves)
        
        // Unlock next & Handle Welcome Gift
        if level >= maxUnlockedLevel {
            maxUnlockedLevel = level + 1
            defaults.set(maxUnlockedLevel, forKey: kMaxUnlockedLevel)
            
            // Welcome Gift for reaching Level 3
            if maxUnlockedLevel == 3 {
                grantWelcomeGift()
            }
        }
    }

    /// Tiered rewards: 1-5 (100), 6-15 (200), 16-50 (300), 51+ (400) + bonus for moves
    func coinRewardForLevel(level: Int, remainingMoves: Int) -> Int {
        let base: Int
        if level <= 5 {
            base = 100
        } else if level <= 15 {
            base = 200
        } else if level <= 50 {
            base = 300
        } else {
            base = 400
        }
        return base + (remainingMoves * 2)
    }

    func syncPreviousMaxLevel() {
        previousMaxLevel = maxUnlockedLevel
        defaults.set(previousMaxLevel, forKey: kPreviousMaxLevel)
    }
    
    func addCoins(amount: Int) {
        coins += amount
        defaults.set(coins, forKey: kCoins)
    }
    

    
    // MARK: - Kinetic Storm Economy
    
    let kineticStormCost = 250
    
    func consumeKineticStormCoins() -> Bool {
        if coins >= kineticStormCost {
            coins -= kineticStormCost
            defaults.set(coins, forKey: kCoins)
            return true
        }
        return false
    }
    
    func consumeCoins(amount: Int) -> Bool {
        if coins >= amount {
            coins -= amount
            defaults.set(coins, forKey: kCoins)
            return true
        }
        return false
    }
    
    // MARK: - Booster Inventory
    
    private func grantWelcomeGift() {
        for type in BoosterType.allCases {
            freeBoosters[type.rawValue] = (freeBoosters[type.rawValue] ?? 0) + 1
        }
        defaults.set(true, forKey: "JuicySmashWelcomeGiftGranted")
        saveBoosters()
    }
    
    func hasFreeBooster(type: BoosterType) -> Bool {
        return (freeBoosters[type.rawValue] ?? 0) > 0
    }
    
    func consumeFreeBooster(type: BoosterType) -> Bool {
        let count = freeBoosters[type.rawValue] ?? 0
        if count > 0 {
            freeBoosters[type.rawValue] = count - 1
            saveBoosters()
            return true
        }
        return false
    }
    
    private func saveBoosters() {
        if let encoded = try? JSONEncoder().encode(freeBoosters) {
            defaults.set(encoded, forKey: "JuicySmashFreeBoosters")
        }
    }
    
    func toggleMusic() {
        musicEnabled.toggle()
        defaults.set(musicEnabled, forKey: kMusicEnabled)
        // TODO: Tell AudioManager
    }
    
    func toggleSfx() {
        sfxEnabled.toggle()
        defaults.set(sfxEnabled, forKey: kSfxEnabled)
        // TODO: Tell AudioManager
    }
    
    func toggleHaptics() {
        hapticsEnabled.toggle()
        defaults.set(hapticsEnabled, forKey: kHapticsEnabled)
    }
    
    // MARK: - Dynamic Theme Engine
    func dynamicTheme(for level: Int) -> [Color] {
        switch level {
        case 1...5:
            // Village: Vibrant Pink to Orange Glow
            return [Color(hex: "#FF007F"), Color(hex: "#FF3366"), Color(hex: "#FF5500"), Color(hex: "#FF7A00"), Color(hex: "#FF9900")]
        case 6...15:
            // Forest: Neon Green to Cyan Glow
            return [Color(hex: "#059669"), Color(hex: "#10B981"), Color(hex: "#39FF14"), Color(hex: "#00E5FF"), Color(hex: "#00BFFF")]
        case 16...50:
            // City: Deep Purple to Magenta Pink Glow
            return [Color(hex: "#3B0764"), Color(hex: "#6B21A8"), Color(hex: "#9400D3"), Color(hex: "#C026D3"), Color(hex: "#FF1493")]
        default:
            // Space (51-99): Deep Space Blue to Cosmic Purple
            return [Color(hex: "#0F172A"), Color(hex: "#1E3A8A"), Color(hex: "#10002b"), Color(hex: "#5a189a"), Color(hex: "#7b2cbf")]
        }
    }
}

enum StormType: String {
    case vertical = "Vertical Storm"
    case horizontal = "Horizontal Storm"
}

final class MotionManager: ObservableObject {
    static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    private var hapticEngine: CHHapticEngine?
    
    @Published var tilt: CGSize = .zero
    @Published var shakeDetected: StormType? = nil
    
    private var isMonitoring = false
    private let updateInterval: TimeInterval = 0.05
    
    private init() {
        prepareHaptics()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = updateInterval
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let acceleration = data?.acceleration else { return }
                
                // Expose tilt (mapped for UI parallax offset, normally values are -1 to 1)
                self.tilt = CGSize(width: CGFloat(acceleration.x) * 25, height: CGFloat(acceleration.y) * 25)
                
                // Shake detection
                let threshold: Double = 1.9 // Force threshold (G)
                if abs(acceleration.x) > threshold {
                    self.triggerShake(.horizontal)
                } else if abs(acceleration.y) > threshold {
                    self.triggerShake(.vertical)
                }
            }
        }
    }
    
    func stopMonitoring() {
        if motionManager.isAccelerometerAvailable {
            motionManager.stopAccelerometerUpdates()
        }
        isMonitoring = false
        tilt = .zero
    }
    
    private func triggerShake(_ type: StormType) {
        // Prevent constant firing
        guard shakeDetected == nil else { return }
        shakeDetected = type
        
        // Auto-reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.shakeDetected = nil
        }
    }
    
    // MARK: - Core Haptics
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptics Error: \(error)")
        }
    }
    
    func playFluidSlosh() {
        guard let engine = hapticEngine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.2)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play fluid slosh: \(error.localizedDescription)")
        }
    }
    
    func playStormExplosion() {
        guard let engine = hapticEngine else {
            // Fallback for Simulator / Unsupported devices
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
            return
        }
        
        // Massive explosion pattern (Intense and sharp, fading out smoothly for a "liquid burst")
        var events = [CHHapticEvent]()
        
        for i in 0..<10 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(1.0 - (Double(i) * 0.08)))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(1.0 - (Double(i) * 0.08)))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: TimeInterval(i) * 0.06)
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play storm explosion: \(error.localizedDescription)")
        }
    }
}
