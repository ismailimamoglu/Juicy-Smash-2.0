import Foundation
import Combine

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
    private let kPreviousMaxLevel = "JuicySmashPreviousMaxLevel"
    
    @Published var highScore: Int = 0
    @Published var maxUnlockedLevel: Int = 1
    @Published var coins: Int = 0
    @Published var levelStars: [Int: Int] = [:] // Level -> Stars
    @Published var freeBoosters: [String: Int] = [:] // BoosterType.rawValue -> Count
    @Published var previousMaxLevel: Int = 1
    
    @Published var musicEnabled: Bool = true
    @Published var sfxEnabled: Bool = true
    
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

    /// Efficiency bonus: Reward = 100 + (remainingMoves × 2)
    func coinRewardForLevel(remainingMoves: Int) -> Int {
        return 100 + (remainingMoves * 2)
    }

    func syncPreviousMaxLevel() {
        previousMaxLevel = maxUnlockedLevel
        defaults.set(previousMaxLevel, forKey: kPreviousMaxLevel)
    }
    
    func addCoins(amount: Int) {
        coins += amount
        defaults.set(coins, forKey: kCoins)
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
}
