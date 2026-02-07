import SwiftUI
import Core
import InventoryFeature
import ProfileFeature

public struct MainTabView: View {
    @State private var selectedTab: Tab = .catalog

    enum Tab {
        case catalog
        case camera
        case profile
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            InventoryView(onOpenCamera: {
                selectedTab = .camera
            })
                .accessibilityIdentifier("tab.catalog")
                .tabItem {
                    Label("Catalog", systemImage: "square.grid.2x2.fill")
                }
                .tag(Tab.catalog)

            CameraTabView(onNavigateToCatalog: {
                selectedTab = .catalog
            })
                .accessibilityIdentifier("tab.camera")
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(Tab.camera)

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
