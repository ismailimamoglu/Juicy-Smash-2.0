import SwiftUI

struct InfoView: View {
    let onClose: () -> Void
    
    // Legal Links
    private let termsURL = "https://doc-hosting.flycricket.io/juicy-smash-2-0-terms-of-use/208c3d8c-e353-417e-bf68-6967492c1181/terms"
    private let privacyURL = "https://doc-hosting.flycricket.io/juicy-smash-2-0-privacy-policy/951a02ec-738a-44df-8239-38188a077bbd/privacy"
    
    // Tutorial State
    @State private var step = 1
    @State private var animationTask: Task<Void, Never>? = nil
    
    // Step 1 Animations (Match)
    @State private var s1ApplesOffset: [CGFloat] = [0, 0, 0]
    @State private var s1ApplesScale: [CGFloat] = [1, 1, 1]
    @State private var s1ApplesOpacity: Double = 1
    @State private var s1StarScale: CGFloat = 0
    
    // Step 2 Animations (Combo)
    @State private var s2GrapesOffset: [CGSize] = Array(repeating: .zero, count: 5)
    @State private var s2GrapesOpacity: Double = 1
    @State private var s2BombScale: CGFloat = 0
    private let grapePositions: [CGSize] = [
        CGSize(width: 0, height: -45),
        CGSize(width: -45, height: 0),
        CGSize(width: 0, height: 0),
        CGSize(width: 45, height: 0),
        CGSize(width: 0, height: 45)
    ]
    
    // Step 3 Animations (Explosion)
    @State private var s3BombScale: CGFloat = 1
    @State private var s3BombOpacity: Double = 1
    @State private var s3FruitsOpacity: Double = 1
    @State private var s3DiamondsScale: CGFloat = 0
    @State private var s3DiamondsOpacity: Double = 0
    private let s3FruitEmojis = ["🍎", "🍇", "🍌", "🍉", "🍊", "🍎", "🍇", "🍌"]
    
    // Shared Hand Cursor
    @State private var handOffset: CGSize = CGSize(width: 150, height: 150)
    @State private var handOpacity: Double = 0
    @State private var handScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture(perform: onClose)
            
            VStack(spacing: 0) {
                // Top header with Close Button
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.bottom, -15)
                .zIndex(2)
                
                VStack(spacing: 20) {
                    Text("HOW TO PLAY")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    
                    // Step Text Description
                    VStack(spacing: 6) {
                        Text("STEP \(step)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(stepDescription)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(height: 44)
                    }
                    
                    // Animation Canvas
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.35))
                            .frame(height: 180)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        
                        animationCanvas
                    }
                    .clipped()
                    
                    Spacer().frame(height: 5)
                    
                    // Action Button
                    Button(action: advanceStep) {
                        Text(step == 3 ? "REPLAY" : "NEXT STEP")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Capsule().fill(step == 3 ? Color.orange : Color.green))
                            .shadow(color: (step == 3 ? Color.orange : Color.green).opacity(0.5), radius: 6, y: 3)
                    }
                    
                    Spacer().frame(height: 8)
                    
                    // Legal links
                    HStack(spacing: 20) {
                        Link("Terms of Use", destination: URL(string: termsURL) ?? URL(string: "https://apple.com")!)
                        Link("Privacy Policy", destination: URL(string: privacyURL) ?? URL(string: "https://apple.com")!)
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan.opacity(0.8))
                }
            }
            .padding(25)
            .background(.ultraThinMaterial)
            .cornerRadius(30)
            .padding(35)
        }
        .onAppear {
            playCurrentStep()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private var stepDescription: String {
        switch step {
        case 1: return "Match 3+ fruits of the same kind."
        case 2: return "Match 5 to create a powerful Bomb."
        case 3: return "Swipe the bomb to explode nearby fruits!"
        default: return ""
        }
    }
    
    @ViewBuilder
    private var animationCanvas: some View {
        ZStack {
            if step == 1 {
                // Apples Match
                HStack(spacing: 12) {
                    Text("🍎").font(.system(size: 45)).offset(x: s1ApplesOffset[0]).scaleEffect(s1ApplesScale[0]).opacity(s1ApplesOpacity)
                    Text("🍎").font(.system(size: 45)).offset(x: s1ApplesOffset[1]).scaleEffect(s1ApplesScale[1]).opacity(s1ApplesOpacity)
                    Text("🍎").font(.system(size: 45)).offset(x: s1ApplesOffset[2]).scaleEffect(s1ApplesScale[2]).opacity(s1ApplesOpacity)
                }
                Text("⭐").font(.system(size: 65)).scaleEffect(s1StarScale)
                
            } else if step == 2 {
                // Grapes Combo
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        Text("🍇")
                            .font(.system(size: 38))
                            .offset(x: grapePositions[i].width + s2GrapesOffset[i].width, 
                                    y: grapePositions[i].height + s2GrapesOffset[i].height)
                    }
                    .opacity(s2GrapesOpacity)
                    
                    Text("💣").font(.system(size: 60)).scaleEffect(s2BombScale)
                }
            } else if step == 3 {
                // Bomb Explosion
                ZStack {
                    ForEach(0..<8, id: \.self) { i in
                        let angle = Double(i) * (.pi / 4.0)
                        let radius: CGFloat = 65
                        Text(s3FruitEmojis[i])
                            .font(.system(size: 32))
                            .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                            .opacity(s3FruitsOpacity)
                    }
                    
                    ForEach(0..<6, id: \.self) { i in
                        let angle = Double(i) * (2 * .pi / 6.0)
                        let radius: CGFloat = 85
                        Text("💎")
                            .font(.system(size: 35))
                            .offset(x: cos(angle) * radius * s3DiamondsScale, y: sin(angle) * radius * s3DiamondsScale)
                            .scaleEffect(max(0, s3DiamondsScale * 0.7))
                            .opacity(s3DiamondsOpacity)
                    }
                    
                    Text("💣").font(.system(size: 60))
                        .scaleEffect(s3BombScale)
                        .opacity(s3BombOpacity)
                }
            }
            
            // Hand Pointing Cursor
            Text("👆")
                .font(.system(size: 45))
                .offset(handOffset)
                .scaleEffect(handScale)
                .opacity(handOpacity)
                .alignmentGuide(HorizontalAlignment.center) { $0.width / 2 - 10 }
                .alignmentGuide(VerticalAlignment.center) { $0.height / 2 - 10 }
        }
    }
    
    private func advanceStep() {
        if step < 3 {
            step += 1
        } else {
            step = 1
        }
        playCurrentStep()
    }
    
    private func playCurrentStep() {
        animationTask?.cancel()
        resetAnimations()
        
        switch step {
        case 1: playStep1()
        case 2: playStep2()
        case 3: playStep3()
        default: break
        }
    }
    
    private func resetAnimations() {
        s1ApplesOffset = [0, 0, 0]
        s1ApplesScale = [1, 1, 1]
        s1ApplesOpacity = 1
        s1StarScale = 0
        
        s2GrapesOffset = Array(repeating: .zero, count: 5)
        s2GrapesOpacity = 1
        s2BombScale = 0
        
        s3BombScale = 1
        s3BombOpacity = 1
        s3FruitsOpacity = 1
        s3DiamondsScale = 0
        s3DiamondsOpacity = 0
        
        // Hand resets outside the canvas view frame
        handOffset = CGSize(width: 150, height: 150)
        handOpacity = 0
        handScale = 1.0
    }
    
    private func playStep1() {
        animationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            
            // Hand appears on left apple
            withAnimation(.easeOut(duration: 0.5)) {
                handOffset = CGSize(width: -60, height: 30)
                handOpacity = 1
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            
            // Hand presses down
            withAnimation(.spring()) { handScale = 0.85 }
            try? await Task.sleep(nanoseconds: 200_000_000)
            if Task.isCancelled { return }
            
            // Hand swipes right
            withAnimation(.easeInOut(duration: 0.4)) {
                handOffset = CGSize(width: -10, height: 30)
                s1ApplesOffset[0] = 55
                s1ApplesOffset[1] = -55
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            
            // Apples align back
            withAnimation(.snappy) {
                s1ApplesOffset = [0, 0, 0]
                handScale = 1.0
                handOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            if Task.isCancelled { return }
            
            // Pop out apples, animate star in
            withAnimation(.easeIn(duration: 0.2)) {
                s1ApplesScale = [0.2, 0.2, 0.2]
                s1ApplesOpacity = 0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) {
                s1StarScale = 1.0
            }
        }
    }
    
    private func playStep2() {
        animationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            
            // Hand appears near bottom grape
            withAnimation(.easeOut(duration: 0.5)) {
                handOffset = CGSize(width: 0, height: 60)
                handOpacity = 1
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            
            // Hand presses
            withAnimation(.spring()) { handScale = 0.85 }
            try? await Task.sleep(nanoseconds: 200_000_000)
            if Task.isCancelled { return }
            
            // Hand swipes up to center
            withAnimation(.easeInOut(duration: 0.4)) {
                handOffset = CGSize(width: 0, height: 10)
                s2GrapesOffset[4] = CGSize(width: 0, height: -45)
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            
            // All grapes collapse to center
            withAnimation(.easeInOut(duration: 0.3)) {
                s2GrapesOffset[0] = CGSize(width: 0, height: 45)
                s2GrapesOffset[1] = CGSize(width: 45, height: 0)
                s2GrapesOffset[2] = CGSize(width: 0, height: 0)
                s2GrapesOffset[3] = CGSize(width: -45, height: 0)
                
                handScale = 1.0
                handOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            
            // Grapes disappear, Bomb appears
            withAnimation(.easeIn(duration: 0.2)) {
                s2GrapesOpacity = 0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                s2BombScale = 1.0
            }
        }
    }
    
    private func playStep3() {
        animationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            
            // Hand appears over bomb
            withAnimation(.easeOut(duration: 0.5)) {
                handOffset = CGSize(width: 0, height: 20)
                handOpacity = 1
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            
            // Hand presses bomb
            withAnimation(.spring()) { handScale = 0.85 }
            try? await Task.sleep(nanoseconds: 200_000_000)
            if Task.isCancelled { return }
            
            // Hand drags bomb horizontally
            withAnimation(.easeInOut(duration: 0.3)) {
                handOffset = CGSize(width: 35, height: 20)
                s3BombScale = 1.2
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            
            // Huge Explosion and diamond spray
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                s3BombScale = 4.0
                s3BombOpacity = 0
                handOpacity = 0
                s3FruitsOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            if Task.isCancelled { return }
            
            // Diamonds burst out
            withAnimation(.easeOut(duration: 0.5)) {
                s3DiamondsScale = 1.3
                s3DiamondsOpacity = 1
            }
        }
    }
}

