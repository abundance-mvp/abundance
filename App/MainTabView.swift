import SwiftUI
import InventoryFeature

public struct MainTabView: View {
    @State private var selectedTab: FloatingTabBar.Tab = .catalog

    public init() {}

    public var body: some View {
        ZStack {
            // Tab content
            Group {
                switch selectedTab {
                case .catalog:
                    InventoryView()
                case .camera:
                    CameraPlaceholderView()
                case .profile:
                    ProfilePlaceholderView()
                }
            }

            // Floating tab bar overlay
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(edges: .bottom) // Tab bar extends under safe area
    }
}

// MARK: - Placeholder Views

private struct CatalogPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                Text("Catalog")
                    .font(.title)
                Text("Your cataloged items will appear here once you scan them with the camera.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Catalog")
        }
    }
}

private struct CameraPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                Text("Camera")
                    .font(.title)
                Text("Real-time object detection will appear here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Camera")
        }
    }
}

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
