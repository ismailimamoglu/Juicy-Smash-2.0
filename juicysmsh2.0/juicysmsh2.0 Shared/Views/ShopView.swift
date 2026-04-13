import SwiftUI
import StoreKit

struct ShopView: View {
    @ObservedObject var storeManager = StoreManager.shared
    var themeColors: [Color]
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // Dynamic Theme Background with Glassmorphism
            LinearGradient(
                colors: themeColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                Text("SHOP")
                    .font(.system(size: 45, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .purple, radius: 10)
                
                // Current Coins
                HStack {
                    Image(systemName: "circle.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title)
                        .shadow(color: .orange, radius: 5)
                    Text("\(ProgressionManager.shared.coins)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color(hex: "#00F0FF").opacity(0.3), radius: 10)
                )
                .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                
                // Ad Button
                Button(action: {
                    let rootVC = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .compactMap { $0 as? UIWindowScene }
                        .first?.windows
                        .filter { $0.isKeyWindow }.first?.rootViewController
                    
                    if !AdManager.shared.isRewardedAdReady {
                        print("Ad not ready")
                    }
                    
                    AdManager.shared.showRewardedAd(from: rootVC) { success in
                        if success {
                            ProgressionManager.shared.coins += 100
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.tv.fill")
                        Text("WATCH AD (+100)")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [themeColors.count > 2 ? themeColors[2] : .purple, themeColors.last ?? .blue], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20)
                    .shadow(color: (themeColors.last ?? .purple).opacity(0.3), radius: 10)
                }
                .padding(.horizontal, 40)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.horizontal, 60)
                    .padding(.vertical, 5)
                
                // Apple StoreKit Packages
                ScrollView {
                    VStack(spacing: 12) {
                        if storeManager.products.isEmpty {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                    .scaleEffect(1.5)
                                Text("Connecting to Store...")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .opacity(0.6)
                            }
                            .padding(.top, 60)
                            .transition(.opacity)
                        } else {
                            ForEach(storeManager.products.sorted(by: { $0.price < $1.price }), id: \.id) { product in
                                ShopProductRow(product: product)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                
                // Close Button
                Button(action: onClose) {
                    Text("DONE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 60)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                .padding(.bottom, 30)
            }
            .padding(.top, 40)
        }
        .task {
            await storeManager.requestProducts()
        }
    }
}

private struct ShopProductRow: View {
    let product: Product
    @ObservedObject var storeManager = StoreManager.shared
    
    var body: some View {
        let meta = storeManager.metadata(for: product.id)
        
        Button(action: {
            Task { await storeManager.purchase(product) }
        }) {
            HStack(spacing: 16) {
                // Large Premium Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .shadow(color: .orange.opacity(0.5), radius: 5)
                    
                    Image(systemName: meta?.iconName ?? "circle.grid.hex.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(meta?.title ?? product.displayName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(meta?.subtitle ?? "+ \(product.id.split(separator: ".").last ?? "Coins")")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Premium Price Button
                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#2B4055")) // Deep readable blue/black
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 4, y: 3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}
