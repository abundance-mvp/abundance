import SwiftUI
import Core

/// Swipeable photo carousel for items with multiple photos
struct PhotoCarouselView: View {
    let imageUrls: [String]
    var onDeletePhoto: ((Int) -> Void)?

    @State private var selectedIndex: Int = 0
    @State private var showDeleteConfirmation = false
    @State private var deleteIndex: Int?

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, urlString in
                    ZStack(alignment: .topTrailing) {
                        ItemImage(
                            url: urlString,
                            context: "PhotoCarousel.photo[\(index)]"
                        )
                        .clipped()

                        // Delete button for non-primary photos
                        if index > 0, onDeletePhoto != nil {
                            Button {
                                deleteIndex = index
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.deepPlum.opacity(0.8))
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .padding(8)
                            .accessibilityLabel("Delete photo \(index + 1)")
                        }
                    }
                    .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif

            // Custom page indicator
            if imageUrls.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<imageUrls.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 12)
            }
        }
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let index = deleteIndex {
                    onDeletePhoto?(index)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This photo will be permanently removed from this item.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Photo \(selectedIndex + 1) of \(imageUrls.count)")
    }
}

#if DEBUG
#Preview("Single Photo") {
    PhotoCarouselView(imageUrls: ["https://picsum.photos/seed/1/400/400"])
        .frame(height: 300)
}

#Preview("Multiple Photos") {
    PhotoCarouselView(
        imageUrls: [
            "https://picsum.photos/seed/1/400/400",
            "https://picsum.photos/seed/2/400/400",
            "https://picsum.photos/seed/3/400/400"
        ],
        onDeletePhoto: { index in print("Delete \(index)") }
    )
    .frame(height: 300)
}
#endif
