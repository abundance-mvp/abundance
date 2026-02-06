import SwiftUI
import Core
import Persistence

/// Bottom sheet prompting user to take a new photo before editing
/// Design: "To edit, take a new photo" with Take Photo / Cancel buttons
public struct RescanPromptSheet: View {
    @Bindable var viewModel: EditItemViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: EditItemViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "camera.viewfinder")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.secondary)
                .padding(.top, 32)

            // Title
            Text("Edit Requires New Photo")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            // Description
            Text("To ensure accuracy, we'll re-analyze your item with a new photo. This helps maintain data quality.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    viewModel.beginRescan()
                } label: {
                    Label("Take New Photo", systemImage: "camera.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    viewModel.state = .editing
                } label: {
                    Text("Edit Without Rescan")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("edit.skipRescanButton")

                Button {
                    viewModel.cancelFlow()
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .adaptiveGlass(cornerRadius: 32)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.state == .processing)
    }
}

#if DEBUG
#Preview("Rescan Prompt Sheet") {
    // @Observable manages its own state - no @State wrapper needed
    let viewModel = EditItemViewModel(
        item: Item(
            id: "preview-1",
            userId: "user-1",
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            name: "Test Item"
        ),
        itemRepository: PreviewItemRepository(),
        storageService: PreviewStorageService()
    )

    return RescanPromptSheet(viewModel: viewModel)
}

// Preview helpers
// swiftlint:disable line_length
private final class PreviewItemRepository: ItemRepository, @unchecked Sendable {
    func createItem(userId: String, imageUrl: String) async throws -> String { "id" }
    func createItemWithLayer1Metadata(itemId: String, userId: String, imageUrl: String, layer1Metadata: Layer1Metadata) async throws {}
    func createItemWithPhotoMetadata(itemId: String, userId: String, imageUrl: String, layer1Metadata: Layer1Metadata, photoMetadata: PhotoMetadata) async throws {}
    func getItem(id: String) async throws -> Item? { nil }
    func getItems(userId: String) async throws -> [Item] { [] }
    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> FirebaseFirestore.ListenerRegistration { fatalError() }
    func observeItems(userId: String) -> AnyPublisher<[Item], Never> { Just([]).eraseToAnyPublisher() }
    func deleteItem(id: String) async throws {}
    func deleteItems(ids: Set<String>) async throws {}
    func updateItem(_ item: Item, userEditedFields: [String]?) async throws {}
    func rescanItem(_ item: Item) async throws {}
}
// swiftlint:enable line_length

private final class PreviewStorageService: StorageServiceProtocol, @unchecked Sendable {
    func uploadCroppedObject(_ image: PlatformImage, itemId: String, userId: String) async throws -> URL {
        URL(string: "https://example.com/image.jpg")!
    }
    func uploadLivePhotoMotion(_ motionData: Data, itemId: String, userId: String) async throws -> URL {
        URL(string: "https://example.com/motion.mov")!
    }
}
#endif

import Combine
import FirebaseFirestore
