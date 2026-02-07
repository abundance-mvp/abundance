import SwiftUI

/// A reusable image component for displaying item photos with retry and error handling
///
/// Firebase Storage download URLs can occasionally fail on first load due to eventual
/// consistency or network hiccups. This component automatically retries failed loads
/// before showing a placeholder.
///
/// Features:
/// - Automatic retry on failure (configurable, default 2 retries with 1s delay)
/// - Graceful error handling with placeholder
/// - Automatic logging of image load failures (after all retries exhausted)
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
    var maxRetries: Int = 2

    @State private var retryCount = 0
    @State private var loadId = UUID()
    @State private var hasLoggedError = false

    public init(
        url: String,
        itemId: String? = nil,
        context: String,
        placeholderIcon: String = "photo",
        contentMode: ContentMode = .fill,
        maxRetries: Int = 2
    ) {
        self.url = url
        self.itemId = itemId
        self.context = context
        self.placeholderIcon = placeholderIcon
        self.contentMode = contentMode
        self.maxRetries = maxRetries
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
                if retryCount < maxRetries {
                    // Show loading state while waiting to retry
                    loadingPlaceholder
                        .onAppear {
                            scheduleRetry()
                        }
                } else {
                    errorPlaceholder
                        .onAppear {
                            logErrorIfNeeded()
                        }
                }
            @unknown default:
                errorPlaceholder
            }
        }
        .id(loadId)
    }

    // MARK: - Placeholders

    private var loadingPlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            ProgressView()
        }
    }

    private var errorPlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.2)
            Image(systemName: placeholderIcon)
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Retry Logic

    private func scheduleRetry() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            retryCount += 1
            loadId = UUID()
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
            context: "\(context) (after \(maxRetries) retries)"
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

    /// Sets the maximum number of retries before showing error placeholder
    func retries(_ count: Int) -> ItemImage {
        var view = self
        view.maxRetries = count
        return view
    }
}
