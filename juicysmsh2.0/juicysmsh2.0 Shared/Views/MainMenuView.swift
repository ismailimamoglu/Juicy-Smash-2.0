import SwiftUI

// MARK: - Floating Fruit Model
private struct FloatingFruit: Identifiable {
    let id = UUID()
    let imageName: String
    let size: CGFloat
    let startX: CGFloat
    let duration: Double
    let delay: Double
}

// MARK: - Main Menu View

struct MainMenuView: View {
    let onPlay: () -> Void
    
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 60
    @State private var buttonOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerPhase: CGFloat = -1
    
    private let floatingFruits: [FloatingFruit] = {
        let assets = ["apple_tile", "orange_tile", "grapes_tile", "pear_tile", "banana_tile", "watermelon_tile"]
        var allAssets: [String] = []
        for _ in 0..<2 { allAssets.append(contentsOf: assets) }
        
        return allAssets.enumerated().map { i, name in
            FloatingFruit(
                imageName: name,
                size: CGFloat.random(in: 40...70),
                startX: CGFloat.random(in: 30...350),
                duration: Double.random(in: 8...15),
                delay: Double.random(in: 0...5)
            )
        }
    }()
    
    var body: some View {
        ZStack {
            // Deep premium background
            LinearGradient(
                colors: [
                    Color(hex: "#071A0F"),
                    Color(hex: "#0D4F2B"),
                    Color(hex: "#0A3D22"),
                    Color(hex: "#071A0F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Noise-like subtle radial glow
            RadialGradient(
                colors: [Color(hex: "#1A7A42").opacity(0.3), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Floating fruits background
            ForEach(floatingFruits) { fruit in
                FloatingFruitView(fruit: fruit)
            }
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                VStack(spacing: 8) {
                    HStack(spacing: 15) {
                        Image("apple_tile")
                            .resizable()
                            .frame(width: 60, height: 60)
                        Image("orange_tile")
                            .resizable()
                            .frame(width: 60, height: 60)
                        Image("grapes_tile")
                            .resizable()
                            .frame(width: 60, height: 60)
                    }
                    .padding(.bottom, 10)
                    
                    Text("JUICY")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#FFD700"), Color(hex: "#FF8C00"), Color(hex: "#FF6347")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("SMASH")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#FF6347"), Color(hex: "#FF1493"), Color(hex: "#FF69B4")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: -8)
                    
                    Text("2.0")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#00E5FF"))
                        .shadow(color: .black.opacity(0.3), radius: 5)
                        .offset(y: -10)
                }
                .shadow(color: Color(hex: "#FFD700").opacity(0.4), radius: 20)
                .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                Spacer().frame(height: 50)
                
                // Play Button
                Button(action: onPlay) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text("PLAY")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .tracking(4)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF6347"), Color(hex: "#FF1493")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(hex: "#FF6347").opacity(0.6), radius: 16, y: 6)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .scaleEffect(pulseScale)
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)
                
                Spacer().frame(height: 40)
                
                // High Score
                let highScore = HighScoreManager.shared.highScore
                if highScore > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Color(hex: "#FFD700"))
                            .font(.system(size: 16))
                        Text("High Score: \(highScore)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .offset(y: buttonOffset)
                    .opacity(buttonOpacity)
                }
                
                Spacer()
                
                // Footer
                HStack(spacing: 4) {
                    Text("Match & Smash")
                    Image("watermelon_tile")
                        .resizable()
                        .frame(width: 18, height: 18)
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
                buttonOffset = 0
                buttonOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1.0)) {
                pulseScale = 1.06
            }
        }
    }
}

// MARK: - Floating Fruit Animation

private struct FloatingFruitView: View {
    let fruit: FloatingFruit
    @State private var yOffset: CGFloat = 800
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(fruit.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: fruit.size, height: fruit.size)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .position(x: fruit.startX, y: yOffset)
            .onAppear {
                // Continuous floating loop
                startFloating()
            }
    }
    
    private func startFloating() {
        // Initial position below screen
        yOffset = 900
        opacity = 0
        rotation = Double.random(in: -30...30)
        
        withAnimation(
            .linear(duration: fruit.duration)
            .delay(fruit.delay)
            .repeatForever(autoreverses: false)
        ) {
            yOffset = -100
        }
        
        withAnimation(.easeIn(duration: 1.5).delay(fruit.delay)) {
            opacity = 0.25
        }
        
        withAnimation(
            .linear(duration: fruit.duration * 0.8)
            .delay(fruit.delay)
            .repeatForever(autoreverses: true)
        ) {
            rotation = Double.random(in: -180...180)
        }
    }
}
