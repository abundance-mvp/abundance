import SwiftUI

/// A reusable image component for displaying item photos with error handling and logging
///
/// Features:
/// - Graceful error handling with placeholder
/// - Automatic logging of image load failures
/// - Configurable placeholder icon and background
///
/// Usage:
/// ```swift
/// ItemImage(
///     url: item.imageUrl,
///     itemId: item.id,
///     context: "ItemDetailView"
/// )
/// ```
public struct ItemImage: View {
    let url: String
    let itemId: String?
    let context: String
    var placeholderIcon: String = "photo"
    var contentMode: ContentMode = .fill

    @State private var hasLoggedError = false

    public init(
        url: String,
        itemId: String? = nil,
        context: String,
        placeholderIcon: String = "photo",
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.itemId = itemId
        self.context = context
        self.placeholderIcon = placeholderIcon
        self.contentMode = contentMode
    }

    public var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                loadingPlaceholder
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                errorPlaceholder
                    .onAppear {
                        logErrorIfNeeded()
                    }
            @unknown default:
                errorPlaceholder
            }
        }
    }

    // MARK: - Placeholders

    private var loadingPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.1)
            ProgressView()
        }
    }

    private var errorPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: placeholderIcon)
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error Logging

    private func logErrorIfNeeded() {
        // Only log once per view instance to avoid spam
        guard !hasLoggedError else { return }
        hasLoggedError = true

        AppLogger.log(.imageLoadFailed(
            url: url,
            itemId: itemId,
            context: context
        ))
    }
}

// MARK: - Convenience Modifiers

public extension ItemImage {
    /// Sets the placeholder icon shown on error
    func placeholder(_ icon: String) -> ItemImage {
        var view = self
        view.placeholderIcon = icon
        return view
    }

    /// Sets the content mode for the image
    func aspectRatio(_ mode: ContentMode) -> ItemImage {
        var view = self
        view.contentMode = mode
        return view
    }
}
