import Foundation
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform
import Combine

/// ConsentManager handles the full App Store compliance flow:
///   1. ATT (App Tracking Transparency) — Apple requirement
///   2. UMP (User Messaging Platform) — GDPR / Google requirement
///   3. Google Mobile Ads SDK initialization — only after consent is collected
///
/// Call `startConsentFlow()` once at app launch, after a brief delay to let the UI settle.
@MainActor
class ConsentManager: ObservableObject {
    static let shared = ConsentManager()
    
    @Published var consentCompleted: Bool = false
    
    private var hasRun = false
    
    private init() {}
    
    /// Entry point: Call this from your launch screen after UI is ready.
    /// The flow is sequential: ATT → UMP → AdSDK Init → Load Ads.
    func startConsentFlow() {
        guard !hasRun else { return }
        hasRun = true
        
        Task { @MainActor in
            // Step 1: Small delay to ensure the app UI is fully presented
            // Apple rejects ATT prompts that appear before the first frame is rendered.
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Request ATT authorization
            let status = await ATTrackingManager.requestTrackingAuthorization()
            
            switch status {
            case .authorized:
                GameLogger.success("ATT: User authorized tracking.", category: "CONSENT")
            case .denied:
                GameLogger.debug("ATT: User denied tracking.", category: "CONSENT")
            case .restricted:
                GameLogger.debug("ATT: Tracking restricted.", category: "CONSENT")
            case .notDetermined:
                GameLogger.debug("ATT: Status not determined.", category: "CONSENT")
            @unknown default:
                break
            }
            
            // Step 2: After ATT, proceed to UMP consent flow
            await requestUMPConsent()
        }
    }
    
    /// Step 2: Google UMP consent form flow.
    private func requestUMPConsent() async {
        // Configure UMP parameters
        let parameters = RequestParameters()
        
        // For testing GDPR in non-EEA regions, uncomment debug settings:
        // let debugSettings = DebugSettings()
        // debugSettings.geography = .EEA
        // debugSettings.testDeviceIdentifiers = ["YOUR_TEST_DEVICE_HASH"]
        // parameters.debugSettings = debugSettings
        
        // Request the latest consent information
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            GameLogger.success("UMP consent info updated successfully.", category: "CONSENT")
        } catch {
            GameLogger.error("UMP consent info update failed: \(error.localizedDescription)", category: "CONSENT")
            // Even if UMP fails, we should still init ads (non-personalized)
            initializeAdsSDK()
            return
        }
        
        // Load and present the form if required by the user's region
        await loadAndShowFormIfRequired()
    }
    
    /// Loads and presents the UMP consent form if required by the user's region.
    private func loadAndShowFormIfRequired() async {
        guard ConsentInformation.shared.formStatus == .available else {
            GameLogger.debug("UMP: No consent form available (likely not in EEA).", category: "CONSENT")
            initializeAdsSDK()
            return
        }
        
        do {
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
            GameLogger.success("UMP consent form presented and handled.", category: "CONSENT")
        } catch {
            GameLogger.error("UMP form error: \(error.localizedDescription)", category: "CONSENT")
        }
        
        // Step 3: Initialize Google Mobile Ads SDK after consent
        initializeAdsSDK()
    }
    
    /// Step 3: Initialize Google Mobile Ads SDK and load the first rewarded ad.
    private func initializeAdsSDK() {
        // Check if we can request ads based on consent
        if ConsentInformation.shared.canRequestAds {
            MobileAds.shared.start(completionHandler: nil)
            GameLogger.success("Google Mobile Ads SDK initialized.", category: "AD")
            
            // Now load the first rewarded ad
            AdManager.shared.loadRewardedAd()
            GameLogger.success("Ad loading started after consent flow.", category: "AD")
        } else {
            GameLogger.debug("Cannot request ads — user did not consent.", category: "AD")
        }
        
        // Mark consent flow as complete regardless
        consentCompleted = true
    }
}
