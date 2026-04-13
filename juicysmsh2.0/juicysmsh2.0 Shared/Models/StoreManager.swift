import Foundation
import StoreKit
import Combine 

class StoreManager: ObservableObject {
    // İşte eksik olan 'shared' objesi burası!
    static let shared = StoreManager()
    
    @Published var products: [Product] = []
    
    // Antigravity'ye verdiğin ID'ler ve karşılığı olan altınlar
    struct ProductMetadata {
        let title: String
        let subtitle: String
        let iconName: String
        let coinAmount: Int
    }
    
    private let productDict: [String: ProductMetadata] = [
        "com.ismailimamoglu.juicysmash6100.coins100": ProductMetadata(title: "Handful of Coins", subtitle: "+100 Coins", iconName: "circle.grid.hex.fill", coinAmount: 100),
        "com.ismailimamoglu.juicysmash6100.coins500": ProductMetadata(title: "Bag of Coins", subtitle: "+500 Coins", iconName: "bitcoinsign.circle.fill", coinAmount: 500),
        "com.ismailimamoglu.juicysmash6100.chest1200": ProductMetadata(title: "Treasure Chest", subtitle: "+1200 Coins", iconName: "archivebox.fill", coinAmount: 1200),
        "com.ismailimamoglu.juicysmash6100.removeads": ProductMetadata(title: "Remove Ads", subtitle: "Ad-Free Experience", iconName: "nosign", coinAmount: 0)
    ]
    
    var productIDList: [String] { Array(productDict.keys) }
    
    func metadata(for id: String) -> ProductMetadata? {
        productDict[id]
    }
    
    private init() { }
    
    @MainActor
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDList)
            // Sort by coin amount (0 for Remove Ads means it'll be first, then 100, 500, 1200)
            self.products = storeProducts.sorted(by: { 
                (productDict[$0.id]?.coinAmount ?? .max) < (productDict[$1.id]?.coinAmount ?? .max) 
            })
            print("✅ [StoreKit] Successfully fetched \(storeProducts.count) products.")
        } catch {
            print("❌ [StoreKit] Failed to fetch products: \(error)")
        }
    }
    
    @MainActor
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("✅ [StoreKit] Purchase successful for \(product.id)")
                    // Grant product entitlements
                    if product.id == "com.ismailimamoglu.juicysmash6100.removeads" {
                        ProgressionManager.shared.removeAds()
                    } else if let meta = productDict[product.id] {
                        ProgressionManager.shared.addCoins(amount: meta.coinAmount)
                    }
                    // Inform Apple that transaction is finished
                    await transaction.finish()
                case .unverified:
                    print("İşlem doğrulanamadı.")
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Satın alma hatası: \(error)")
        }
    }
    
    @MainActor
    func restorePurchases() async throws {
        print("🔄 [StoreKit] Starting purchase restoration...")
        do {
            try await AppStore.sync()
            
            // Also iterate through current entitlements in case `sync()` alone isn't enough to trigger state update
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == "com.ismailimamoglu.juicysmash6100.removeads" {
                    ProgressionManager.shared.removeAds()
                    print("✅ [StoreKit] Restored Remove Ads entitlement.")
                }
            }
            print("✅ [StoreKit] Purchases restored successfully.")
        } catch {
            print("❌ [StoreKit] Restore purchases failed: \(error)")
            throw error
        }
    }
}
