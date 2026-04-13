import SwiftUI

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Premium Gold Gradient
extension LinearGradient {
    static var gold: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#FFD700"), // Gold
                Color(hex: "#FFFACD"), // Lemon Chiffon (Highlight)
                Color(hex: "#FFD700"), // Gold
                Color(hex: "#DAA520"), // Goldenrod (Shadow)
                Color(hex: "#FFD700")  // Gold
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shimmer Effect
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Color.white.opacity(0.3)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.7), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.5)
                                .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                        )
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(Shimmer())
    }
}

// MARK: - Sulu Alpha Transition
extension AnyTransition {
    /// "Sulu Alpha Transition": removal scales up + fades out, insertion scales from small + fades in
    static var juicyAlpha: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.85).combined(with: .opacity)
                .animation(.spring(response: 0.5, dampingFraction: 0.75)),
            removal: .scale(scale: 1.15).combined(with: .opacity)
                .animation(.easeOut(duration: 0.35))
        )
    }
}

// MARK: - Watercolor Background with Parallax Particles
struct WatercolorBackground: View {
    let tilt: CGSize
    var colors: [Color]? = nil
    
    private var baseColors: [Color] {
        colors ?? [Color(hex: "#FF007F"), Color(hex: "#7A00E6"), Color(hex: "#00F0FF")]
    }
    
    var body: some View {
        ZStack {
            // Base thematic gradient
            LinearGradient(
                colors: baseColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Watercolor texture blobs — soft, organic shapes
            GeometryReader { geo in
                ForEach(0..<8, id: \.self) { i in
                    let sizes: [CGFloat] = [200, 160, 250, 120, 180, 220, 140, 190]
                    let xPositions: [CGFloat] = [0.15, 0.8, 0.5, 0.2, 0.75, 0.4, 0.9, 0.1]
                    let yPositions: [CGFloat] = [0.1, 0.25, 0.5, 0.7, 0.85, 0.15, 0.6, 0.9]
                    
                    // Blobs use variations of the base colors
                    let blobColor = (colors?.first ?? Color.white).opacity(0.12)
                    
                    Circle()
                        .fill(i % 2 == 0 ? blobColor : Color.white.opacity(0.06))
                        .frame(width: sizes[i], height: sizes[i])
                        .position(
                            x: geo.size.width * xPositions[i] + tilt.width * CGFloat(i % 2 == 0 ? 1.5 : -1.0),
                            y: geo.size.height * yPositions[i] + tilt.height * CGFloat(i % 2 == 0 ? -1.0 : 1.5)
                        )
                        .blur(radius: CGFloat([40, 30, 50, 25, 35, 45, 30, 40][i]))
                }
                
                // Light particles — tiny bright dots that react to tilt
                ForEach(0..<15, id: \.self) { i in
                    let particleSizes: [CGFloat] = [4, 6, 3, 5, 7, 4, 3, 6, 5, 4, 7, 3, 5, 6, 4]
                    let px: [CGFloat] = [0.1, 0.3, 0.5, 0.7, 0.9, 0.2, 0.4, 0.6, 0.8, 0.15, 0.35, 0.55, 0.75, 0.85, 0.45]
                    let py: [CGFloat] = [0.15, 0.35, 0.55, 0.25, 0.75, 0.45, 0.65, 0.85, 0.05, 0.95, 0.1, 0.7, 0.4, 0.6, 0.3]
                    
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.7)))
                        .frame(width: particleSizes[i], height: particleSizes[i])
                        .position(
                            x: geo.size.width * px[i] + tilt.width * CGFloat(2.0 + Double(i) * 0.3),
                            y: geo.size.height * py[i] + tilt.height * CGFloat(2.0 + Double(i) * 0.3)
                        )
                        .blur(radius: 1)
                        .shadow(color: .white, radius: 3)
                }
                
                // Water droplet shapes — larger, semi-transparent, react to tilt
                ForEach(0..<6, id: \.self) { i in
                    let dropSizes: [CGFloat] = [20, 16, 24, 14, 18, 22]
                    let dx: [CGFloat] = [0.25, 0.65, 0.45, 0.85, 0.15, 0.55]
                    let dy: [CGFloat] = [0.2, 0.5, 0.8, 0.35, 0.65, 0.9]
                    
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: dropSizes[i], height: dropSizes[i] * 1.4)
                        .rotationEffect(.degrees(Double(i * 30 - 45)))
                        .position(
                            x: geo.size.width * dx[i] + tilt.width * CGFloat(3.0),
                            y: geo.size.height * dy[i] + tilt.height * CGFloat(3.0)
                        )
                        .blur(radius: 2)
                        .shadow(color: .white.opacity(0.3), radius: 5)
                }
            }
        }
    }
}

// MARK: - Floating Assets Logic
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
    
    var body: some View {
        Image(fruit.imageName)
            .resizable()
            .frame(width: fruit.size, height: fruit.size)
            .position(x: fruit.startX, y: yOffset)
            .opacity(0.6)
            .blur(radius: 0.5)
            .onAppear {
                withAnimation(.linear(duration: fruit.duration).repeatForever( autoreverses: false)) {
                    yOffset = -100
                }
            }
    }
}
