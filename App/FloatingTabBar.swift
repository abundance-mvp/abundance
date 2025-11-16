import SwiftUI

struct FloatingTabBar: View {
    enum Tab: String, CaseIterable, Identifiable {
        case catalog = "Catalog"
        case camera = "Camera"
        case profile = "Profile"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .catalog: return "square.grid.2x2"
            case .camera: return "camera"
            case .profile: return "person"
            }
        }
    }

    @Binding var selectedTab: Tab
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 24) {
            ForEach(Tab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(backgroundMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 40)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func tabButton(for tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .symbolVariant(selectedTab == tab ? .fill : .none)

                Text(tab.rawValue)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? .primary : .tertiary)
            }
            .frame(minWidth: 60, minHeight: 44)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTab == tab)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(selectedTab == tab ? [.isButton, .isSelected] : .isButton)
    }

    private var backgroundMaterial: AnyShapeStyle {
        reduceTransparency ? AnyShapeStyle(Color.backgroundDefault) : AnyShapeStyle(.regularMaterial)
    }
}
