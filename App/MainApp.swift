import SwiftUI

@main
struct JuicySmashApp: App {
    var body: some Scene {
        WindowGroup {
            LevelMapView()
                .preferredColorScheme(.dark)
        }
    }
}
