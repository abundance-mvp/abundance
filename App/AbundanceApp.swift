import SwiftUI
@preconcurrency import FirebaseCore

@main
struct AbundanceApp: App {
    init() {
        // Configure Firebase (requires GoogleService-Info.plist)
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Text("Abundance MVP")
                .font(.largeTitle)
        }
    }
}
