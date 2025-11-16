import SwiftUI
@preconcurrency import FirebaseCore
import FirebaseAuth
import OnboardingFeature

@main
struct AbundanceApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
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
