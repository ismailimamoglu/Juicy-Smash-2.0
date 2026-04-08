import Foundation
import StoreKit
import Combine

/// Manages StoreKit 2 In-App Purchase lifecycle for Juicy Smash 2.0.
/// All three coin packs are **Consumable** products.
@MainActor
final class StoreManager: ObservableObject {
    
    // MARK: - Product Identifiers
    
    static let productIDs: Set<String> = [
        "com.ismail.juicysmash2.gold100",
        "com.ismail.juicysmash2.gold500",
        "com.ismail.juicysmash2.gold1000"
    ]
    
    /// Maps a product identifier → coin amount to deliver
    private static let coinMapping: [String: Int] = [
        "com.ismail.juicysmash2.gold100":  100,
        "com.ismail.juicysmash2.gold500":  500,
        "com.ismail.juicysmash2.gold1000": 1000
    ]
    
    // MARK: - Published State
    
    /// Fetched products from Apple, sorted by price ascending
    @Published private(set) var products: [Product] = []
    
    /// True while a purchase transaction is in progress
    @Published var isPurchasing: Bool = false
    
    /// Non-nil when we want to show an alert (success / failure)
    @Published var purchaseResultMessage: String?
    
    /// Set of product IDs that were recently purchased (for brief UI feedback)
    @Published var recentlyPurchased: Set<String> = []
    
    // MARK: - Transaction Listener
    
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Init / Deinit
    
    init() {
        // Start listening for transactions completed outside the app
        transactionListener = listenForTransactions()
        
        // Fetch products immediately
        Task { [weak self] in
            await self?.fetchProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: StoreManager.productIDs)
            // Sort by price so the cheapest pack appears first
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("[StoreManager] ❌ Failed to fetch products: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction using StoreKit 2's built-in verification
                let transaction = try checkVerified(verification)
                
                // Deliver the coins
                deliverCoins(for: transaction.productID)
                
                // Mark the consumable transaction as finished
                await transaction.finish()
                
                // Brief success feedback
                recentlyPurchased.insert(product.id)
                purchaseResultMessage = "✅ \(coinAmount(for: product.id)) Coins added!"
                
                // Remove the "recently purchased" state after 2 seconds
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self?.recentlyPurchased.remove(product.id)
                    self?.purchaseResultMessage = nil
                }
                
            case .userCancelled:
                // User dismissed the payment sheet — no action needed
                break
                
            case .pending:
                // Transaction requires approval (e.g., Ask to Buy)
                purchaseResultMessage = "⏳ Purchase pending approval."
                
            @unknown default:
                break
            }
        } catch {
            print("[StoreManager] ❌ Purchase error: \(error.localizedDescription)")
            purchaseResultMessage = "❌ Purchase failed. Please try again."
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.purchaseResultMessage = nil
            }
        }
    }
    
    // MARK: - Transaction Listener (Background)
    
    /// Listens for transactions that complete outside the current app session
    /// (e.g. pending Ask-to-Buy approvals, subscription renewals, refunds)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let transaction = transaction {
                        await MainActor.run {
                            self?.deliverCoins(for: transaction.productID)
                        }
                        await transaction.finish()
                    }
                } catch {
                    print("[StoreManager] ❌ Transaction listener error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Coin Delivery
    
    private func deliverCoins(for productID: String) {
        let amount = coinAmount(for: productID)
        guard amount > 0 else {
            print("[StoreManager] ⚠️ Unknown product: \(productID)")
            return
        }
        ProgressionManager.shared.addCoins(amount: amount)
        print("[StoreManager] 💰 Delivered \(amount) coins for \(productID). New balance: \(ProgressionManager.shared.coins)")
    }
    
    private func coinAmount(for productID: String) -> Int {
        return StoreManager.coinMapping[productID] ?? 0
    }
    
    // MARK: - Helpers
    
    /// Returns a user-facing coin label for a given product
    func displayName(for product: Product) -> String {
        let amount = coinAmount(for: product.id)
        return "\(amount) Coins"
    }
    
    /// Returns the icon name based on the tier
    func iconName(for product: Product) -> String {
        switch coinAmount(for: product.id) {
        case 100:  return "centsign.circle.fill"
        case 500:  return "dollarsign.circle.fill"
        case 1000: return "banknote.fill"
        default:   return "circle.circle.fill"
        }
    }
    
    /// True if this is the "popular" tier
    func isPopular(_ product: Product) -> Bool {
        return product.id == "com.ismail.juicysmash2.gold500"
    }
}
