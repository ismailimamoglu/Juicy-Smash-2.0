import Foundation
import Observation

@Observable
final class ProgressionManager {
    static let shared = ProgressionManager()

    // MARK: - Booster Prices
    static let hammerPrice    = 50
    static let shufflePrice   = 70
    static let megaBlastPrice = 100

    // MARK: - UserDefaults Keys
    private let coinsKey            = "JuicySmash_Coins"
    private let maxLevelKey         = "JuicySmash_MaxLevel"
    private let highScoreKey        = "JuicySmash_HighScore"
    private let previousMaxLevelKey = "JuicySmash_PrevMaxLevel"

    // MARK: - Persisted Properties
    var coins: Int {
        didSet { UserDefaults.standard.set(coins, forKey: coinsKey) }
    }

    var maxUnlockedLevel: Int {
        didSet { UserDefaults.standard.set(maxUnlockedLevel, forKey: maxLevelKey) }
    }

    var highScore: Int {
        didSet { UserDefaults.standard.set(highScore, forKey: highScoreKey) }
    }

    var previousMaxLevel: Int {
        didSet { UserDefaults.standard.set(previousMaxLevel, forKey: previousMaxLevelKey) }
    }

    // MARK: - Init
    private init() {
        let defaults = UserDefaults.standard
        // New players start with 10 coins
        if defaults.object(forKey: coinsKey) == nil { defaults.set(10, forKey: coinsKey) }
        if defaults.object(forKey: maxLevelKey) == nil { defaults.set(1, forKey: maxLevelKey) }
        self.coins            = defaults.integer(forKey: coinsKey)
        self.maxUnlockedLevel = defaults.integer(forKey: maxLevelKey)
        self.highScore        = defaults.integer(forKey: highScoreKey)
        self.previousMaxLevel = defaults.integer(forKey: previousMaxLevelKey)
        if self.previousMaxLevel == 0 { self.previousMaxLevel = self.maxUnlockedLevel }
    }

    // MARK: - Economy
    func addCoins(_ amount: Int) { coins += amount }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }

    // MARK: - Level Reward (Efficiency Bonus)
    /// Reward = 20 + (remainingMoves × 2)
    func coinRewardForLevel(remainingMoves: Int) -> Int {
        return 20 + (remainingMoves * 2)
    }

    // MARK: - Progression
    func unlockNextLevel(completedLevel: Int) {
        if completedLevel >= maxUnlockedLevel {
            maxUnlockedLevel = completedLevel + 1
        }
    }

    func syncPreviousMaxLevel() {
        previousMaxLevel = maxUnlockedLevel
    }

    func updateHighScore(newScore: Int) {
        if newScore > highScore { highScore = newScore }
    }

    // MARK: - Star Calculation (visual only)
    func calculateStars(level: Int, score: Int, targetScore: Int) -> Int {
        let ratio = Double(score) / Double(targetScore)
        if level <= 10 {
            if ratio >= 1.6 { return 3 }
            if ratio >= 1.3 { return 2 }
            if ratio >= 1.0 { return 1 }
        } else {
            if ratio >= 2.0 { return 3 }
            if ratio >= 1.5 { return 2 }
            if ratio >= 1.0 { return 1 }
        }
        return 0
    }
}
