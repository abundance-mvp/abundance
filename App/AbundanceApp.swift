import SwiftUI
@preconcurrency import FirebaseCore
import FirebaseAuth
import OnboardingFeature

@main
struct AbundanceApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Configure Firebase with SPM resource bundle
        if let resourceBundleURL = Bundle.main.url(forResource: "Abundance_AbundanceApp", withExtension: "bundle"),
           let resourceBundle = Bundle(url: resourceBundleURL),
           let plistPath = resourceBundle.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: plistPath) {
            FirebaseApp.configure(options: options)
        } else {
            // Fallback to default configuration (works when bundle structure is standard)
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView(viewModel: authViewModel)
                }
            }
        }
    }
}
