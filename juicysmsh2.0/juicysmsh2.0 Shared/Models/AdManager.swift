import Foundation
import GoogleMobileAds
import Combine
import UIKit

class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    @Published var isRewardedAdReady = false
    private let rewardedAdID = "ca-app-pub-3940256099942544/1712485313" // Google Test ID
    private var rewardedAd: RewardedAd? 
    
    override init() {
        super.init()
        // Ad loading is now triggered by ConsentManager after ATT + UMP consent flow completes.
        // Do NOT call loadRewardedAd() here.
    }
    
    func loadRewardedAd() {
        let request = Request()
        
        RewardedAd.load(with: rewardedAdID, request: request) { [weak self] ad, error in
            if let error = error {
                GameLogger.error("Reklam yüklenemedi: \(error.localizedDescription)", category: "AD")
                self?.isRewardedAdReady = false
                return
            }
            self?.rewardedAd = ad
            self?.isRewardedAdReady = true
            GameLogger.success("Ödüllü reklam hazır!", category: "AD")
        }
    }
    
    // DİKKAT: SwiftUI uyumluluğu için UIViewController opsiyonel (?) olmalıdır!
    func showRewardedAd(from root: UIViewController?, completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, let rootVC = root else {
            GameLogger.error("Reklam hazır değil veya gösterilecek geçerli bir ekran (root) bulunamadı!", category: "AD")
            completion(false)
            return
        }
        
        ad.present(from: rootVC) {
            let reward = ad.adReward
            GameLogger.success("Kullanıcı ödülü hak etti: \(reward.amount) \(reward.type)", category: "AD")
            completion(true)
            self.loadRewardedAd() // Sonraki izleme için yenisini yükle
        }
    }
}
