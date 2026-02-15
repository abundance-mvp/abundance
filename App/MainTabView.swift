import SwiftUI
import Core
import CollectionFeature
import ProfileFeature

public struct MainTabView: View {
    @State private var selectedTab: Tab = .collection

    enum Tab {
        case collection
        case scan
        case profile
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView(onOpenCamera: {
                selectedTab = .scan
            })
                .accessibilityIdentifier("tab.collection")
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }
                .tag(Tab.collection)

            CameraTabView(onNavigateToCollection: {
                selectedTab = .collection
            })
                .accessibilityIdentifier("tab.scan")
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(Tab.scan)

            ProfileView()
                .accessibilityIdentifier("tab.profile")
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(Color.salmon)
    }
}

#Preview {
    MainTabView()
}
