import SwiftUI
import InventoryFeature

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
                .tag(Tab.catalog)

            CameraTabView(onNavigateToCatalog: {
                selectedTab = .catalog
            })
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(Tab.camera)

            ProfilePlaceholderView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
    }
}

// MARK: - Placeholder Views

private struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                Text("Profile")
                    .font(.title)
                Text("User profile and settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView()
}
