import SwiftUI
import Core

/// Floating tab bar with Liquid Glass and morphing effects
/// Uses material effects with smooth morphing animations
public struct FloatingTabBar: View {
    @Binding var selection: Int
    let items: [TabItem]

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Namespace private var tabNamespace

    public struct TabItem: Identifiable {
        public let id: UUID = UUID()
        public let icon: String
        public let title: String

        public init(icon: String, title: String) {
            self.icon = icon
            self.title = title
        }
    }

    public init(selection: Binding<Int>, items: [TabItem]) {
        self._selection = selection
        self.items = items
    }

    public var body: some View {
        tabContent
            .background {
                if reduceTransparency {
                    Capsule()
                        .fill(Color.backgroundDefault)
                } else {
                    Capsule()
                        .fill(.ultraThickMaterial)
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var tabContent: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                tabButton(for: item, at: index)
            }
        }
        .padding(6)
    }

    @ViewBuilder
    private func tabButton(for item: TabItem, at index: Int) -> some View {
        let isSelected: Bool = selection == index

        Button {
            withAnimation(.brandDefault) {
                selection = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))

                Text(item.title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(minWidth: 64, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule()
                    .fill(.thickMaterial)
                    .matchedGeometryEffect(id: "selectedTab", in: tabNamespace)
            }
        }
        .accessibilityLabel("\(item.title), tab \(index + 1) of \(items.count)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    @Previewable @State var selection = 0

    VStack {
        Spacer()
        FloatingTabBar(selection: $selection, items: [
            .init(icon: "house.fill", title: "Home"),
            .init(icon: "camera.fill", title: "Capture"),
            .init(icon: "person.fill", title: "Profile")
        ])
    }
    .padding()
}
