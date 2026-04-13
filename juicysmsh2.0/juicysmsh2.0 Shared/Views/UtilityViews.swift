import SwiftUI

struct SettingsView: View {
    let onClose: () -> Void
    @ObservedObject private var progression = ProgressionManager.shared
    
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture(perform: onClose)
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
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.1)))
                
                Text("Juicy Smash 2.0")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color.white).shadow(radius: 20))
            .padding(.horizontal, 30)
        }
    }
}

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
