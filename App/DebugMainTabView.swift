#if DEBUG
import SwiftUI
import Core
import CollectionFeature
import ProfileFeature
import Persistence

/// Debug-only MainTabView that bypasses Firebase Auth and uses in-memory data.
/// Used when running on simulator to enable AXe test scenarios.
struct DebugMainTabView: View {
    @State private var selectedTab: Tab = .collection
    @State private var collectionViewModel: CollectionViewModel
    @State private var profileViewModel: ProfileViewModel

    enum Tab {
        case collection
        case scan
        case profile
    }

    init() {
        let repo = SimulatorItemRepository()
        _collectionViewModel = State(initialValue: CollectionViewModel(
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
            CollectionView(
                viewModel: collectionViewModel,
                onOpenCamera: { selectedTab = .scan }
            )
            .accessibilityIdentifier("tab.collection")
            .tabItem {
                Label("Collection", systemImage: "square.grid.2x2.fill")
            }
            .tag(Tab.collection)

            cameraPlaceholder
                .accessibilityIdentifier("tab.scan")
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(Tab.scan)

            ProfileView(viewModel: profileViewModel)
            .accessibilityIdentifier("tab.profile")
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
        .tint(Color.salmon)
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
            .navigationTitle("Scan")
            .accessibilityIdentifier("camera.simulatorPlaceholder")
        }
    }
}
#endif
