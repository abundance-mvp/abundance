import SwiftUI
@preconcurrency import FirebaseCore
import OnboardingFeature

@main
struct AbundanceApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            SignInView()
        }
    }
}
