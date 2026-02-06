import SwiftUI
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
                .tabItem {
                    Label("Catalog", systemImage: "square.grid.2x2.fill")
                }
                .accessibilityIdentifier("tab.catalog")
                .tag(Tab.catalog)

            CameraTabView(onNavigateToCatalog: {
                selectedTab = .catalog
            })
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .accessibilityIdentifier("tab.camera")
                .tag(Tab.camera)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .accessibilityIdentifier("tab.profile")
                .tag(Tab.profile)
        }
    }
}

#Preview {
    MainTabView()
}
