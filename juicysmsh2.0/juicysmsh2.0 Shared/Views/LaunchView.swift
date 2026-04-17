import SwiftUI

struct LaunchView: View {
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Match the Main Menu background for a seamless transition
            LinearGradient(
                colors: [
                    Color(hex: "#071A0F"),
                    Color(hex: "#0D4F2B")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("JUICY SMASH")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(8)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}
