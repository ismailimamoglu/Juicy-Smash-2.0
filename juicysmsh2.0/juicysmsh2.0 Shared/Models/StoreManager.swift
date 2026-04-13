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
        "com.juicysmash.coins100": ProductMetadata(title: "Handful of Coins", subtitle: "+100 Coins", iconName: "circle.grid.hex.fill", coinAmount: 100),
        "com.juicysmash.coins500": ProductMetadata(title: "Bag of Coins", subtitle: "+500 Coins", iconName: "bitcoinsign.circle.fill", coinAmount: 500),
        "com.juicysmash.coins1200": ProductMetadata(title: "Treasure Chest", subtitle: "+1200 Coins", iconName: "archivebox.fill", coinAmount: 1200)
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
            // Fiyata göre küçükten büyüğe sırala
            self.products = storeProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("Ürünler çekilemedi: \(error)")
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
                    // Oyuncuya altını ver
                    if let meta = productDict[product.id] {
                        ProgressionManager.shared.coins += meta.coinAmount
                    }
                    // Apple'a işlemin bittiğini haber ver
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
        // AppStore.sync() triggers the system to verify all past store transactions and push them to the app. 
        // Our existing transaction listener (which should ideally be running continuously) or a standard check handles them.
        try await AppStore.sync()
    }
}
