import Foundation
import AVFoundation

/// Low-latency sound management system for Juicy Smash 2.0
final class SoundManager {
    static let shared = SoundManager()
    
    // Players pool for low-latency (pre-loaded)
    private var players: [String: [AVAudioPlayer]] = [:]
    private let poolSize = 3 // Number of simultaneous instances per sound
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            #if os(iOS)
            // .playback ensures sound is heard even if the device is in silent mode
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            GameLogger.debug("Audio Session setup as .playback", category: "AUDIO", emoji: "🔊")
            #endif
        } catch {
            GameLogger.error("Failed to setup audio session: \(error)", category: "AUDIO")
        }
    }
    
    private func preloadSounds() {
        let soundFiles = [
            "pop", "match", "swap", "explosion", 
            "explosion_huge", "ice_break", "victory", "failed"
        ]
        
        for sound in soundFiles {
            players[sound] = []
            // Look for wav first (user preferred), then mp3 (fallback)
            var url = Bundle.main.url(forResource: sound, withExtension: "wav") ?? 
                      Bundle.main.url(forResource: sound, withExtension: "mp3")
            
            // Special fallback for explosion_huge
            if url == nil && sound == "explosion_huge" {
                url = Bundle.main.url(forResource: "explosion", withExtension: "wav") ?? 
                      Bundle.main.url(forResource: "explosion", withExtension: "mp3")
            }

            guard let finalUrl = url else {
                GameLogger.warning("Could not find sound file for: \(sound)", category: "AUDIO")
                continue
            }
            
            for _ in 0..<poolSize {
                do {
                    let player = try AVAudioPlayer(contentsOf: finalUrl)
                    player.prepareToPlay()
                    players[sound]?.append(player)
                    GameLogger.success("Preloaded: \(sound)", category: "AUDIO")
                } catch {
                    GameLogger.error("Failed to preload sound: \(sound) - \(error)", category: "AUDIO")
                }
            }
        }
    }
    
    private func play(named name: String) {
        // Respect settings from ProgressionManager
        guard ProgressionManager.shared.sfxEnabled else { 
            GameLogger.debug("SFX is disabled in settings", category: "AUDIO", emoji: "🔇")
            return 
        }
        
        guard let soundPool = players[name], !soundPool.isEmpty else { 
            GameLogger.warning("No sound pool for: \(name)", category: "AUDIO")
            return 
        }
        
        // Find a player that is not currently playing, or use the first one
        let player = soundPool.first(where: { !$0.isPlaying }) ?? soundPool[0]
        
        GameLogger.debug("Playing: \(name)", category: "AUDIO", emoji: "▶️")
        
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        
        player.play()
    }
    
    // MARK: - Dedicated Sound Triggers
    
    func playPopSound() {
        play(named: "pop")
    }
    
    func playMatchSound() {
        play(named: "match")
    }
    
    func playSwap() {
        play(named: "swap")
    }
    
    func playExplosion(isHuge: Bool) {
        play(named: isHuge ? "explosion_huge" : "explosion")
    }
    
    func playIceBreak() {
        play(named: "ice_break")
    }
    
    func playVictory() {
        play(named: "victory")
    }
    
    func playFailed() {
        play(named: "failed")
    }
    
    func playCombo(multiplier: Int) {
        // Fallback or specific combo sounds if available
        play(named: "match") 
    }
}
