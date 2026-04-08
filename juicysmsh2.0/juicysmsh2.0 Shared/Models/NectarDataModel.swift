import Foundation
import CoreGraphics
import AVFoundation
import SwiftUI

// MARK: - Core Enums

enum FruitVariety: String, CaseIterable {
    case apple, orange, grapes, pear, banana, watermelon
    
    var primaryColorHexString: String {
        switch self {
        case .apple: return "#FF3B30"
        case .orange: return "#FF9500"
        case .grapes: return "#AF52DE"
        case .pear: return "#34C759"
        case .banana: return "#FFD60A"
        case .watermelon: return "#FF2D55"
        }
    }
    
    var emoji: String {
        switch self {
        case .apple: return "🍎"
        case .orange: return "🍊"
        case .grapes: return "🍇"
        case .pear: return "🍐"
        case .banana: return "🍌"
        case .watermelon: return "🍉"
        }
    }
}

enum RipenessState: String {
    case fresh, rowClearer, colClearer, bomb, rainbow
}

enum GamePhase: Equatable {
    case playing
    case levelComplete
    case levelFailed
}

/// App-level screen state


// MARK: - Booster Types

enum BoosterType: String, CaseIterable, Identifiable {
    case hammer
    case shuffle
    case megaBlast
    
    var id: String { self.rawValue }
    
    var cost: Int {
        switch self {
        case .hammer: return 50
        case .shuffle: return 70
        case .megaBlast: return 100
        }
    }
    
    var title: String {
        switch self {
        case .hammer: return "Hammer"
        case .shuffle: return "Shuffle"
        case .megaBlast: return "Blast"
        }
    }
    
    var icon: String {
        switch self {
        case .hammer: return "hammer.fill"
        case .shuffle: return "shuffle"
        case .megaBlast: return "flame.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .hammer: return "#FF3B30"
        case .shuffle: return "#AF52DE"
        case .megaBlast: return "#FF9500"
        }
    }
}

// MARK: - Level Configuration

struct LevelConfig {
    let level: Int
    let targetScore: Int
    let maxMoves: Int
    let iceProbability: Double // Probability of a tile starting frozen
    
    static func forLevel(_ level: Int) -> LevelConfig {
        let targetScore: Int
        let maxMoves: Int
        let iceProb: Double
        
        switch level {
        case 1:
            targetScore = 500;   maxMoves = 30; iceProb = 0.0
        case 2:
            targetScore = 800;   maxMoves = 28; iceProb = 0.0
        case 3:
            targetScore = 1000;  maxMoves = 26; iceProb = 0.0
        case 4:
            targetScore = 1200;  maxMoves = 25; iceProb = 0.0
        case 5:
            targetScore = 1400;  maxMoves = 24; iceProb = 0.03
        case 6:
            targetScore = 1600;  maxMoves = 23; iceProb = 0.05
        case 7:
            targetScore = 1800;  maxMoves = 22; iceProb = 0.06
        case 8:
            targetScore = 2000;  maxMoves = 22; iceProb = 0.07
        case 9:
            targetScore = 2200;  maxMoves = 21; iceProb = 0.08
        case 10:
            targetScore = 2400;  maxMoves = 20; iceProb = 0.09
        default:
            // Level 11+: Real challenge begins
            targetScore = 2400 + ((level - 10) * 300)
            maxMoves = max(12, 20 - (level - 10))
            iceProb = min(0.25, 0.10 + Double(level - 10) * 0.015)
        }
        
        return LevelConfig(level: level, targetScore: targetScore, maxMoves: maxMoves, iceProbability: iceProb)
    }
    
    func starsEarned(score: Int) -> Int {
        if level <= 10 {
            // Easier star thresholds for early levels
            if score >= Int(Double(targetScore) * 1.6) { return 3 }
            else if score >= Int(Double(targetScore) * 1.3) { return 2 }
            else if score >= targetScore { return 1 }
        } else {
            // Harder star thresholds for later levels
            if score >= Int(Double(targetScore) * 2.0) { return 3 }
            else if score >= Int(Double(targetScore) * 1.5) { return 2 }
            else if score >= targetScore { return 1 }
        }
        return 0
    }
}

// MARK: - Floating Effects

struct FloatingScore: Identifiable {
    let id = UUID()
    let text: String
    let color: String
    let row: Int
    let col: Int
}

struct ParticleEffect: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    let colorHex: String
    
    // Config
    let scatterCount = 6
}

// MARK: - Harvest Tile

struct HarvestTile: Identifiable, Hashable {
    let id: String
    var variety: FruitVariety
    var state: RipenessState
    var row: Int
    var col: Int
    var isFrozen: Bool = false
    
    private let footprintSalt: UUID
    
    init(variety: FruitVariety, state: RipenessState = .fresh, row: Int, col: Int, isFrozen: Bool = false) {
        let baseID = UUID()
        let salt = UUID()
        self.id = "\(baseID.uuidString)-\(salt.uuidString)"
        self.footprintSalt = salt
        self.variety = variety
        self.state = state
        self.row = row
        self.col = col
        self.isFrozen = isFrozen
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: HarvestTile, rhs: HarvestTile) -> Bool { lhs.id == rhs.id }
}

// MARK: - High Score Persistence

final class HighScoreManager {
    static let shared = HighScoreManager()
    private let key = "JuicySmash_HighScore"
    
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    
    func updateIfNeeded(score: Int) {
        if score > highScore { highScore = score }
    }
}

// MARK: - Audio Manager

final class AudioManager {
    static let shared = AudioManager()
    private var players: [String: AVAudioPlayer] = [:]
    
    private init() {
        // Pre-configure audio session to duck others and be ambient
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    /// Safely plays a sound fire-and-forget. The real audio files need to be bundled.
    private func playSound(name: String, loop: Bool = false) {
        // Respect the sound toggle
        guard ProgressionManager.shared.sfxEnabled else { return }
        
        // Find the URL. If the user hasn't added the sounds yet, gracefully return without crashing.
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") ??
                        Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }
        
        do {
            // Instantiate a new player for overlapping sounds if needed
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loop ? -1 : 0
            player.prepareToPlay()
            player.play()
            
            // Minimal caching for looping BGM, otherwise let it ARC release
            if loop { players[name] = player }
        } catch {
            print("Failed to play sound: \(name)")
        }
    }
    
    func playSwap() { playSound(name: "swap") }
    func playMatch() { playSound(name: "match") }
    func playCombo(multiplier: Int) { playSound(name: "combo\(min(multiplier, 3))") }
    func playExplosion(isHuge: Bool) { playSound(name: isHuge ? "explosion_huge" : "explosion") }
    func playIceBreak() { playSound(name: "ice_break") }
    func playVictory() { playSound(name: "victory") }
    func playFailed() { playSound(name: "failed") }
}

// MARK: - Shake Shake Shake
struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}
