import SwiftUI

struct LevelPreviewPopup: View {
    let level: Int
    let stars: Int
    let onPlay: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Text("LEVEL \(level)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.black.opacity(0.2))
                }
            }
            
            Text("Goal: Reach Score")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(i <= stars ? Color(hex: "#FFD700") : .black.opacity(0.1))
                }
            }
            .padding(.vertical, 10)
            
            Button(action: onPlay) {
                Text("PLAY")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#28A745")], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: Color(hex: "#34C759").opacity(0.4), radius: 8, y: 4)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
        .padding(.horizontal, 40)
    }
}
