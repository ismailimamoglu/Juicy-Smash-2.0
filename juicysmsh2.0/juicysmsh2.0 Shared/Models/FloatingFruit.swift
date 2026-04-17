import SwiftUI

struct FloatingFruit: Identifiable {
    let id = UUID()
    let imageName: String
    let size: CGFloat
    let startX: CGFloat
    let duration: Double
    let delay: Double
    let spinRate: Double
}

struct FloatingFruitView: View {
    let fruit: FloatingFruit
    @State private var yOffset: CGFloat = 1000
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(fruit.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: fruit.size, height: fruit.size)
            .opacity(0.3)
            .blur(radius: 0.5)
            .rotationEffect(.degrees(rotation))
            .position(x: fruit.startX, y: yOffset)
            .onAppear {
                // Rising animation
                withAnimation(.linear(duration: fruit.duration).repeatForever(autoreverses: false)) {
                    yOffset = -200
                }
                // Spinning animation
                withAnimation(.linear(duration: fruit.spinRate).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
