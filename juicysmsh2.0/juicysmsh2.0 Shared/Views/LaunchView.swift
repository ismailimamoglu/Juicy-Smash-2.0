import SwiftUI

struct LaunchView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotation: Double = -10
    
    var body: some View {
        ZStack {
            // Background matching the MainMenu theme
            LinearGradient(
                colors: [Color(hex: "#A8E1FF"), Color(hex: "#C6F8FF"), Color(hex: "#E5DAFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // We'll assume LaunchLogo is integrated into xcassets or provide a fallback
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                
                Text("Match & Smash!")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#2B4055"))
                    .opacity(opacity)
                    .padding(.top, 20)
            }
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

#Preview {
    LaunchView()
}
