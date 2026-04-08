import Foundation
import AVFoundation
import AudioToolbox
import Observation

@Observable
final class SoundManager {
    static let shared = SoundManager()

    var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "JuicySmash_SoundEnabled") }
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "JuicySmash_SoundEnabled") == nil {
            defaults.set(true, forKey: "JuicySmash_SoundEnabled")
        }
        isSoundEnabled = defaults.bool(forKey: "JuicySmash_SoundEnabled")
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    // MARK: - Sound Triggers
    func playSwipe()      { play(1104) }
    func playMatch()      { play(1057) }
    func playCombo()      { play(1025) }
    func playBooster()    { play(1335) }
    func playButtonTap()  { play(1104) }
    func playLevelClear() { play(1335) }
    func playGameOver()   { play(1073) }

    private func play(_ id: UInt32) {
        guard isSoundEnabled else { return }
        #if os(iOS)
        AudioServicesPlaySystemSound(SystemSoundID(id))
        #endif
    }

    /// Load and play a custom .mp3/.wav from the bundle
    func playCustom(named name: String, ext: String = "mp3") {
        guard isSoundEnabled else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        player.play()
    }
}
