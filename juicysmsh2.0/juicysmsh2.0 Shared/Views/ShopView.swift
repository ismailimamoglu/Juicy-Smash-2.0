import SwiftUI
import StoreKit

struct ShopView: View {
    @ObservedObject var storeManager = StoreManager.shared
    var themeColors: [Color]
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // Soft, fixed background — warm cream to dusty rose
            LinearGradient(
                colors: [Color(hex: "#FFF5E6"), Color(hex: "#F0D5C8"), Color(hex: "#D4BCC8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                Text("SHOP")
                    .font(.system(size: 45, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#E8915A"))
                    .shadow(color: Color(hex: "#C47A4A").opacity(0.4), radius: 6)
                
                // Current Coins
                HStack {
                    Image(systemName: "circle.circle.fill")
                        .foregroundColor(Color(hex: "#F4A261"))
                        .font(.title)
                    Text("\(ProgressionManager.shared.coins)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#4A3728"))
                        .shadow(color: .black.opacity(0.1), radius: 1)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.6))
                        .shadow(color: Color.black.opacity(0.08), radius: 8)
                )
                .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                
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
                    .background(LinearGradient(colors: [Color(hex: "#D4956A"), Color(hex: "#C47A4A")], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20)
                    .shadow(color: Color(hex: "#C47A4A").opacity(0.3), radius: 6)
                }
                .padding(.horizontal, 40)
                
                Divider()
                    .background(Color(hex: "#C4A89A").opacity(0.5))
                    .padding(.horizontal, 60)
                    .padding(.vertical, 5)
                
                // Apple StoreKit Packages
                ScrollView {
                    VStack(spacing: 12) {
                        if storeManager.products.isEmpty {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#D4956A")))
                                    .scaleEffect(1.5)
                                Text("Connecting to Store...")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#8A7060"))
                                    .opacity(0.8)
                            }
                            .padding(.top, 60)
                            .transition(.opacity)
                        } else {
                            ForEach(storeManager.products.sorted(by: { 
                                (storeManager.metadata(for: $0.id)?.coinAmount ?? 0) < (storeManager.metadata(for: $1.id)?.coinAmount ?? 0)
                            }), id: \.id) { product in
                                ShopProductRow(product: product)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        Task { try? await storeManager.restorePurchases() }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#8A7060").opacity(0.8))
                            .underline()
                    }
                    
                    Button(action: onClose) {
                        Text("DONE")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#5A4030"))
                            .padding(.vertical, 14)
                            .padding(.horizontal, 60)
                            .background(Capsule().fill(Color.white.opacity(0.5)))
                            .overlay(Capsule().stroke(Color(hex: "#C4A89A").opacity(0.5), lineWidth: 1))
                    }
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
                        .fill(LinearGradient(colors: [Color(hex: "#F4A261"), Color(hex: "#E76F51")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .shadow(color: Color(hex: "#E76F51").opacity(0.3), radius: 4)
                    
                    Image(systemName: meta?.iconName ?? "circle.grid.hex.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(meta?.title ?? product.displayName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#3D2B1F"))
                    
                    Text(meta?.subtitle ?? "+ \(product.id.split(separator: ".").last ?? "Coins")")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#8A7060"))
                }
                
                Spacer()
                
                // Premium Price Button
                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "#D4956A"), Color(hex: "#C47A4A")], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: Color(hex: "#C47A4A").opacity(0.3), radius: 3, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
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
