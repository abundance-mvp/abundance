#if DEBUG
import SwiftUI
import InventoryFeature
import ProfileFeature
import Persistence

/// Debug-only MainTabView that bypasses Firebase Auth and uses in-memory data.
/// Used when running on simulator to enable AXe test scenarios.
struct DebugMainTabView: View {
    @State private var selectedTab: Tab = .catalog
    @State private var inventoryViewModel: InventoryViewModel
    @State private var profileViewModel: ProfileViewModel

    enum Tab {
        case catalog
        case camera
        case profile
    }

    init() {
        let repo = SimulatorItemRepository()
        _inventoryViewModel = State(initialValue: InventoryViewModel(
            userId: SimulatorItemFactory.userId,
            itemRepository: repo,
            requiresAuthentication: false
        ))
        _profileViewModel = State(initialValue: ProfileViewModel(
            userId: SimulatorItemFactory.userId,
            displayName: "Debug User",
            email: "debug@simulator.local",
            itemRepository: repo,
            requiresAuthentication: false
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            InventoryView(
                viewModel: inventoryViewModel,
                onOpenCamera: { selectedTab = .camera }
            )
            .tabItem {
                Label("Catalog", systemImage: "square.grid.2x2.fill")
                    .accessibilityIdentifier("tab.catalog")
            }
            .tag(Tab.catalog)

            cameraPlaceholder
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                        .accessibilityIdentifier("tab.camera")
                }
                .tag(Tab.camera)

            ProfileView(viewModel: profileViewModel)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
                    .accessibilityIdentifier("tab.profile")
            }
            .tag(Tab.profile)
        }
    }

    @ScaledMetric(relativeTo: .largeTitle) private var cameraIconSize: CGFloat = 60

    /// Placeholder for camera tab on simulator (no hardware camera available).
    private var cameraPlaceholder: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: cameraIconSize))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Camera unavailable")
                Text("Camera Unavailable")
                    .font(.title2)
                Text("Camera is not available on the simulator.\nUse a physical device to capture items.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Camera")
            .accessibilityIdentifier("camera.simulatorPlaceholder")
        }
    }
}
#endif
