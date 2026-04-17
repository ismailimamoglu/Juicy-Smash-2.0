import SwiftUI

struct SettingsView: View {
    let onClose: () -> Void
    @ObservedObject private var progression = ProgressionManager.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture(perform: onClose)
            VStack(spacing: 24) {
                HStack {
                    Text("SETTINGS")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#2B4055"))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black.opacity(0.2))
                    }
                }
                
                VStack(spacing: 16) {
                    Toggle(isOn: Binding(get: { progression.musicEnabled }, set: { _ in progression.toggleMusic() })) {
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(Color(hex: "#FF1493"))
                                .frame(width: 30)
                            Text("Music")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2B4055"))
                        }
                    }
                    Divider()
                    Toggle(isOn: Binding(get: { progression.sfxEnabled }, set: { _ in progression.toggleSfx() })) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(Color(hex: "#00E5FF"))
                                .frame(width: 30)
                            Text("Sound Effects")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2B4055"))
                        }
                    }
                    Divider()
                    Toggle(isOn: Binding(get: { progression.hapticsEnabled }, set: { _ in progression.toggleHaptics() })) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(Color(hex: "#34C759"))
                                .frame(width: 30)
                            Text("Haptics")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#2B4055"))
                        }
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
                
                Button(action: onClose) {
                    Text("DONE")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(Capsule().fill(Color(hex: "#2B4055")))
                }
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white).shadow(radius: 20))
            .padding(.horizontal, 30)
        }
    }
}
