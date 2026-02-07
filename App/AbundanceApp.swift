import SwiftUI
@preconcurrency import FirebaseCore
import FirebaseAuth
import OnboardingFeature

@main
struct AbundanceApp: App {
    @State private var authViewModel = AuthViewModel()

    init() {
        // Configure Firebase with SPM resource bundle
        #if DEBUG
        print("DEBUG: Looking for Firebase config...")
        print("DEBUG: Main bundle path: \(Bundle.main.bundlePath)")
        #endif

        if let resourceBundleURL = Bundle.main.url(forResource: "Abundance_AbundanceApp", withExtension: "bundle") {
            #if DEBUG
            print("DEBUG: Found resource bundle at \(resourceBundleURL)")
            #endif

            if let resourceBundle = Bundle(url: resourceBundleURL),
               let plistPath = resourceBundle.path(forResource: "GoogleService-Info", ofType: "plist") {
                #if DEBUG
                print("DEBUG: Found GoogleService-Info.plist at \(plistPath)")
                #endif

                if let options = FirebaseOptions(contentsOfFile: plistPath) {
                    #if DEBUG
                    print("DEBUG: Configuring Firebase with custom options")
                    #endif
                    FirebaseApp.configure(options: options)
                    return
                } else {
                    #if DEBUG
                    print("DEBUG: Failed to load FirebaseOptions from plist")
                    #endif
                }
            } else {
                #if DEBUG
                print("DEBUG: GoogleService-Info.plist not found in bundle")
                #endif
            }
        } else {
            #if DEBUG
            print("DEBUG: Resource bundle not found")
            #endif
        }

        // Fallback: Try default configuration
        #if DEBUG
        print("DEBUG: Attempting default Firebase configuration")
        #endif
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--e2e-test-mode") {
                    E2ETestMainTabView()
                } else if isSimulator {
                    DebugMainTabView()
                } else {
                    authContent
                }
                #else
                authContent
                #endif
            }
        }
    }

    @ViewBuilder
    private var authContent: some View {
        if authViewModel.isAuthenticated {
            MainTabView()
        } else {
            SignInView(viewModel: authViewModel)
        }
    }

    /// Check if running on simulator at runtime
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
