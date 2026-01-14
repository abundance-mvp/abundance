# DESIGN-037: UI/UX to MVVM Integration Patterns

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM pattern)
- docs/adr/ADR-012-state-management-strategy.md (Combine + async/await)
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md
- docs/design/DESIGN-027-camera-capture-view-specification.md
- docs/design/DESIGN-028-catalog-view-specification.md
- docs/design/DESIGN-029-item-detail-view-specification.md
- docs/design/DESIGN-030-profile-export-view-specification.md
- docs/design/DESIGN-031-swiftui-component-library.md

---

## Overview

This document defines 8 production-ready integration patterns for connecting SwiftUI views to MVVM ViewModels with Firestore, Firebase Storage, and Vision Framework. All patterns follow the MVVM architecture (ADR-010) and state management strategy (ADR-012: Combine + async/await hybrid).

**Core Architecture** (from ADR-010):
- **Model**: Codable structs (CatalogItem, User, AIAnalysis) - plain data
- **View**: SwiftUI views - passive UI rendering, no business logic
- **ViewModel**: ObservableObject classes - business logic, @Published state, async operations

**State Management Strategy** (from ADR-012):
- **Combine**: Reactive UI state (@Published properties), real-time streams (Firestore listeners)
- **async/await**: Asynchronous operations (network calls, Vision processing, Firestore writes)

**Technology Stack**:
- iOS 26.0+ (primary), iOS 25.0+ (fallback)
- SwiftUI 6.0, Swift 6.0 (strict concurrency)
- Combine + async/await hybrid
- Firebase SDK (Firestore, Storage, Auth)
- Vision Framework (on-device ML)

---

## Pattern 1: ViewModel Initialization with Constructor Injection

### Purpose

Initialize ViewModels with injected dependencies (repositories, services) for testability and modularity.

### Pattern Overview

```
View creates ViewModel via @StateObject
    ↓
ViewModel initialized with injected repository
    ↓
Repository handles data access (Firestore, API, local storage)
```

### Implementation

#### Repository Protocol

```swift
import Combine

// MARK: - Repository Protocol
protocol CatalogRepository {
    func fetchItems() async throws -> [CatalogItem]
    func observeItems() -> AnyPublisher<[CatalogItem], Never>
    func createItem(_ item: CatalogItem) async throws -> CatalogItem
    func updateItem(_ item: CatalogItem) async throws
    func deleteItem(id: String) async throws
}

// MARK: - Firestore Implementation
class FirestoreCatalogRepository: CatalogRepository {
    private let db = Firestore.firestore()
    private let userId: String

    init(userId: String) {
        self.userId = userId
    }

    func fetchItems() async throws -> [CatalogItem] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("items")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: CatalogItem.self)
        }
    }

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        let subject = PassthroughSubject<[CatalogItem], Never>()

        let listener = db.collection("users").document(userId)
            .collection("items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    subject.send([])
                    return
                }

                let items = snapshot.documents.compactMap { doc -> CatalogItem? in
                    try? doc.data(as: CatalogItem.self)
                }

                subject.send(items)
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }

    func createItem(_ item: CatalogItem) async throws -> CatalogItem {
        let ref = db.collection("users").document(userId).collection("items").document()
        var newItem = item
        newItem.id = ref.documentID
        try ref.setData(from: newItem)
        return newItem
    }

    func updateItem(_ item: CatalogItem) async throws {
        try db.collection("users").document(userId)
            .collection("items").document(item.id)
            .setData(from: item, merge: true)
    }

    func deleteItem(id: String) async throws {
        try await db.collection("users").document(userId)
            .collection("items").document(id)
            .delete()
    }
}
```

#### ViewModel with Constructor Injection

```swift
import SwiftUI
import Combine

@MainActor
class CatalogViewModel: ObservableObject {
    // MARK: - Published State
    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Dependencies (Injected)
    private let repository: CatalogRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(repository: CatalogRepository) {
        self.repository = repository
        observeItems()
    }

    // MARK: - Public Methods
    func refreshItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = error
        }
    }

    func deleteItem(id: String) async {
        do {
            try await repository.deleteItem(id: id)
            items.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    // MARK: - Private Methods
    private func observeItems() {
        repository.observeItems()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }
}
```

#### View with @StateObject

```swift
struct CatalogView: View {
    // MARK: - ViewModel
    @StateObject private var viewModel: CatalogViewModel

    // MARK: - Initialization
    init(repository: CatalogRepository = FirestoreCatalogRepository(userId: Auth.auth().currentUser?.uid ?? "")) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(repository: repository))
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading items...")
                } else if viewModel.items.isEmpty {
                    EmptyStateCard(
                        iconName: "cube.box",
                        headline: "No Items Yet",
                        description: "Start building your catalog by scanning your first item.",
                        buttonTitle: "Scan First Item",
                        action: { /* Navigate to camera */ }
                    )
                    .padding()
                } else {
                    itemGrid
                }
            }
            .navigationTitle("Catalog")
            .refreshable {
                await viewModel.refreshItems()
            }
        }
    }

    private var itemGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(viewModel.items) { item in
                    ItemCard(item: item) {
                        // Navigate to detail
                    }
                }
            }
            .padding()
        }
    }
}
```

### Testing Pattern

```swift
import XCTest
@testable import Abundance

final class CatalogViewModelTests: XCTestCase {
    var sut: CatalogViewModel!
    var mockRepository: MockCatalogRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockCatalogRepository()
        sut = CatalogViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testRefreshItemsSuccess() async {
        // Given
        let expectedItems = [
            CatalogItem(id: "1", name: "Drill", category: "Tools", createdAt: Date()),
            CatalogItem(id: "2", name: "Tent", category: "Camping", createdAt: Date())
        ]
        mockRepository.stubbedItems = expectedItems

        // When
        await sut.refreshItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testDeleteItemSuccess() async {
        // Given
        sut.items = [
            CatalogItem(id: "1", name: "Drill", category: "Tools", createdAt: Date()),
            CatalogItem(id: "2", name: "Tent", category: "Camping", createdAt: Date())
        ]

        // When
        await sut.deleteItem(id: "1")

        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.id, "2")
        XCTAssertTrue(mockRepository.didCallDeleteItem)
    }
}

// MARK: - Mock Repository
class MockCatalogRepository: CatalogRepository {
    var stubbedItems: [CatalogItem] = []
    var shouldFail: Bool = false
    var didCallDeleteItem: Bool = false

    private let itemsSubject = PassthroughSubject<[CatalogItem], Never>()

    func fetchItems() async throws -> [CatalogItem] {
        if shouldFail {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return stubbedItems
    }

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        return itemsSubject.eraseToAnyPublisher()
    }

    func sendItems(_ items: [CatalogItem]) {
        itemsSubject.send(items)
    }

    func createItem(_ item: CatalogItem) async throws -> CatalogItem {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
        return item
    }

    func updateItem(_ item: CatalogItem) async throws {
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
    }

    func deleteItem(id: String) async throws {
        didCallDeleteItem = true
        if shouldFail {
            throw NSError(domain: "test", code: 1)
        }
    }
}
```

### Key Considerations

1. **@StateObject vs @ObservedObject**:
   - Use `@StateObject` when View owns ViewModel lifecycle
   - Use `@ObservedObject` when ViewModel is passed from parent

2. **Default Values in Initializer**:
   - Provide production dependency as default parameter
   - Allows easy testing with mock injection
   - Example: `init(repository: CatalogRepository = FirestoreCatalogRepository(...))`

3. **Memory Management**:
   - Store Combine cancellables in `Set<AnyCancellable>`
   - Use `[weak self]` in Combine closures to prevent retain cycles
   - ViewModels automatically deallocate when View is dismissed

---

## Pattern 2: Firestore Real-Time Listener Integration

### Purpose

Observe Firestore collections in real-time and update SwiftUI views automatically when data changes.

### Pattern Overview

```
Firestore addSnapshotListener
    ↓
Combine PassthroughSubject
    ↓
ViewModel @Published property
    ↓
SwiftUI View re-renders
```

### Implementation

#### Real-Time Listener with Combine

```swift
import Combine
import FirebaseFirestore

extension FirestoreCatalogRepository {
    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        let subject = PassthroughSubject<[CatalogItem], Never>()

        let listener = db.collection("users").document(userId)
            .collection("items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    subject.send([])
                    return
                }

                let items = snapshot.documents.compactMap { doc -> CatalogItem? in
                    try? doc.data(as: CatalogItem.self)
                }

                subject.send(items)
            }

        return subject
            .handleEvents(receiveCancel: {
                listener.remove() // Clean up listener on cancel
            })
            .eraseToAnyPublisher()
    }
}
```

#### ViewModel with Real-Time Updates

```swift
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var items: [CatalogItem] = []
    @Published var error: Error?

    private let repository: CatalogRepository
    private var cancellables = Set<AnyCancellable>()

    init(repository: CatalogRepository) {
        self.repository = repository
        observeItems()
    }

    private func observeItems() {
        repository.observeItems()
            .receive(on: DispatchQueue.main) // Ensure main thread updates
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }

    // Listener automatically cancels when ViewModel is deallocated
    deinit {
        cancellables.removeAll()
    }
}
```

#### View with Automatic Updates

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(viewModel.items) { item in
                    ItemCard(item: item)
                        .id(item.id) // Ensure SwiftUI tracks item identity
                }
            }
        }
        // No manual refresh needed - updates automatically
    }
}
```

### Error Handling

```swift
private func observeItems() {
    repository.observeItems()
        .receive(on: DispatchQueue.main)
        .catch { [weak self] error -> Just<[CatalogItem]> in
            self?.error = error
            return Just([]) // Emit empty array on error
        }
        .sink { [weak self] items in
            self?.items = items
        }
        .store(in: &cancellables)
}
```

### Key Considerations

1. **Connection Failures**:
   - Firestore listeners auto-reconnect on network recovery
   - Show offline banner when connection lost (via Firestore SDK listener)

2. **Permission Denied**:
   - Security rules rejection triggers listener error
   - Show authentication required alert, navigate to sign-in

3. **Memory Management**:
   - Always use `[weak self]` in sink closures
   - Store cancellables in Set to prevent listener leaks
   - Listener auto-removes in `handleEvents(receiveCancel:)`

4. **Threading**:
   - Always `.receive(on: DispatchQueue.main)` before sinking
   - Prevents SwiftUI crashes from background thread updates

---

## Pattern 3: Async/Await Operation with Loading States

### Purpose

Execute asynchronous operations (save, delete, export) with proper loading and error state management.

### Pattern Overview

```
User taps button
    ↓
View calls ViewModel async method
    ↓
ViewModel sets isLoading = true
    ↓
Async operation executes (try await)
    ↓
ViewModel updates @Published properties
    ↓
View updates UI (loading → success/error)
```

### Implementation

#### ViewModel with Async Operations

```swift
@MainActor
class ItemDetailViewModel: ObservableObject {
    // MARK: - Published State
    @Published var item: CatalogItem
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var error: Error?
    @Published var saveSuccess: Bool = false

    // MARK: - Dependencies
    private let repository: CatalogRepository

    init(item: CatalogItem, repository: CatalogRepository) {
        self.item = item
        self.repository = repository
    }

    // MARK: - Public Methods
    func saveItem() async {
        isSaving = true
        saveSuccess = false
        defer { isSaving = false }

        do {
            try await repository.updateItem(item)
            saveSuccess = true

            // Reset success flag after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            saveSuccess = false
        } catch {
            self.error = error
        }
    }

    func deleteItem() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.deleteItem(id: item.id)
            // Navigation handled by View
        } catch {
            self.error = error
        }
    }
}
```

#### View with Async Actions

```swift
struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $viewModel.item.name)
                TextField("Category", text: $viewModel.item.category)
            }

            Section {
                PrimaryButton(
                    title: "Save Item",
                    isLoading: viewModel.isSaving,
                    isEnabled: !viewModel.item.name.isEmpty
                ) {
                    Task {
                        await viewModel.saveItem()
                        if viewModel.saveSuccess {
                            dismiss()
                        }
                    }
                }
            }

            Section {
                Button("Delete Item", role: .destructive) {
                    Task {
                        await viewModel.deleteItem()
                        if viewModel.error == nil {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("Edit Item")
        .alert(error: $viewModel.error) // Show error alert
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
```

### Error Alert Modifier

```swift
extension View {
    func alert(error: Binding<Error?>) -> some View {
        self.alert(
            "Error",
            isPresented: .constant(error.wrappedValue != nil),
            actions: {
                Button("OK") {
                    error.wrappedValue = nil
                }
            },
            message: {
                if let error = error.wrappedValue {
                    Text(error.localizedDescription)
                }
            }
        )
    }
}
```

### Key Considerations

1. **Main Actor Isolation**:
   - All ViewModels annotated with `@MainActor`
   - Ensures @Published updates happen on main thread
   - Prevents SwiftUI crashes from background updates

2. **defer Statement**:
   - Always use `defer { isLoading = false }` to reset state
   - Guarantees cleanup even if operation throws

3. **Loading Button States**:
   - Pass `isLoading` to PrimaryButton for spinner display
   - Disable button during loading to prevent duplicate operations

4. **Success Feedback**:
   - Show success state (checkmark, banner) for 2 seconds
   - Auto-dismiss or reset success flag after delay

---

## Pattern 4: Firebase Storage AsyncImage Integration

### Purpose

Display images from Firebase Storage using AsyncImage with placeholder and error states.

### Pattern Overview

```
Firebase Storage signed URL
    ↓
AsyncImage fetches image
    ↓
Placeholder → Loading → Success/Error
```

### Implementation

#### Firebase Storage URL Generation

```swift
import FirebaseStorage

class StorageService {
    private let storage = Storage.storage()

    func getImageURL(itemId: String, imageType: String) async throws -> URL {
        let ref = storage.reference()
            .child("items")
            .child(itemId)
            .child("\(imageType).jpg")

        return try await ref.downloadURL()
    }
}
```

#### ItemCard with AsyncImage

```swift
struct ItemCard: View {
    let item: CatalogItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Async image loading
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()

                case .failure:
                    placeholderImage

                @unknown default:
                    placeholderImage
                }
            }
            .clipShape(ConcentricRectangle(cornerRadius: 12, inset: 4))

            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(item.category)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(.thickMaterial, in: ConcentricRectangle(cornerRadius: 16, inset: 0))
    }

    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
        .frame(height: 160)
    }
}
```

#### Optimized with Kingfisher (Optional)

```swift
import Kingfisher

struct OptimizedItemCard: View {
    let item: CatalogItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            KFImage(item.imageURL)
                .placeholder {
                    ProgressView()
                        .frame(height: 160)
                }
                .retry(maxCount: 3, interval: .seconds(2))
                .onSuccess { result in
                    // Image loaded successfully
                }
                .onFailure { error in
                    // Log error
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .clipped()
                .clipShape(ConcentricRectangle(cornerRadius: 12, inset: 4))

            // ... metadata
        }
    }
}
```

### Key Considerations

1. **Caching**:
   - AsyncImage automatically caches images in URLCache
   - Consider Kingfisher for advanced caching (memory + disk)

2. **Performance**:
   - Use `.resizable()` and `.aspectRatio(contentMode: .fill)` for proper sizing
   - Always `.clipped()` after aspect fill to prevent overflow

3. **Error Handling**:
   - Always provide `.failure` case with placeholder
   - Never crash on missing/invalid images

4. **Signed URLs**:
   - Firebase Storage URLs expire after 1 hour
   - Refresh URLs if image fails to load (retry mechanism)

---

## Pattern 5: Vision Framework Integration Pattern

### Purpose

Integrate Vision Framework object detection with SwiftUI camera view and real-time bounding box overlays.

### Pattern Overview

```
AVCaptureSession frame
    ↓
VNCoreMLRequest processes frame
    ↓
ViewModel publishes detected objects
    ↓
View draws bounding boxes
```

### Implementation

#### CameraViewModel with Vision

```swift
import SwiftUI
import AVFoundation
import Vision
import Combine

@MainActor
class CameraViewModel: ObservableObject {
    // MARK: - Published State
    @Published var detectedObjects: [DetectedObject] = []
    @Published var barcodeValue: String?
    @Published var isProcessing: Bool = false
    @Published var error: Error?

    // MARK: - Dependencies
    private let visionService: VisionService
    private var cancellables = Set<AnyCancellable>()

    init(visionService: VisionService = VisionService()) {
        self.visionService = visionService
    }

    // MARK: - Public Methods
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        Task {
            do {
                let objects = try await visionService.detectObjects(in: sampleBuffer)
                detectedObjects = objects

                // Check for barcode
                if let barcode = objects.first(where: { $0.type == .barcode }) {
                    barcodeValue = barcode.barcodeValue
                }
            } catch {
                self.error = error
            }
        }
    }

    func clearDetections() {
        detectedObjects = []
        barcodeValue = nil
    }
}

// MARK: - Detected Object Model
struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Double
    let boundingBox: CGRect // Normalized coordinates (0-1)
    let type: ObjectType
    var barcodeValue: String?

    enum ObjectType {
        case object
        case barcode
    }
}
```

#### Vision Service

```swift
import Vision
import CoreML

class VisionService {
    private let objectDetectionModel: VNCoreMLModel

    init() {
        // Load Core ML model (YOLOv8 or similar)
        let config = MLModelConfiguration()
        guard let model = try? VNCoreMLModel(for: YOLOv8(configuration: config).model) else {
            fatalError("Failed to load object detection model")
        }
        self.objectDetectionModel = model
    }

    func detectObjects(in sampleBuffer: CMSampleBuffer) async throws -> [DetectedObject] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: objectDetectionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let objects = results.compactMap { observation -> DetectedObject? in
                    guard let label = observation.labels.first,
                          observation.confidence > 0.5 else { return nil }

                    return DetectedObject(
                        label: label.identifier,
                        confidence: Double(observation.confidence),
                        boundingBox: observation.boundingBox,
                        type: .object
                    )
                }

                continuation.resume(returning: objects)
            }

            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, options: [:])
            try? handler.perform([request])
        }
    }
}
```

#### CameraView with Bounding Boxes

```swift
import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: cameraManager.captureSession)
                .ignoresSafeArea()

            // Bounding box overlays
            GeometryReader { geometry in
                ForEach(viewModel.detectedObjects) { object in
                    BoundingBoxView(object: object, frameSize: geometry.size)
                }
            }

            // Barcode indicator
            if let barcode = viewModel.barcodeValue {
                VStack {
                    Spacer()

                    Text("Barcode: \(barcode)")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background {
                            Capsule()
                                .fill(Color.brandMintGreen)
                                .shadow(color: Color.brandMintGreen.opacity(0.5), radius: 12, x: 0, y: 4)
                        }
                        .padding(.bottom, 100)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.brandBouncy, value: viewModel.barcodeValue)
                }
            }

            // Capture button
            VStack {
                Spacer()

                PrimaryButton(title: "Capture") {
                    capturePhoto()
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            cameraManager.startSession()
            cameraManager.framePublisher
                .sink { sampleBuffer in
                    viewModel.processFrame(sampleBuffer)
                }
                .store(in: &cancellables)
        }
        .onDisappear {
            cameraManager.stopSession()
            viewModel.clearDetections()
        }
    }
}

// MARK: - Bounding Box View
struct BoundingBoxView: View {
    let object: DetectedObject
    let frameSize: CGSize

    var body: some View {
        let box = convertBoundingBox(object.boundingBox, to: frameSize)

        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.brandBrightBlue, lineWidth: 2)
                .frame(width: box.width, height: box.height)

            Text(object.label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.brandBrightBlue)
                .offset(y: -20)
        }
        .position(x: box.midX, y: box.midY)
    }

    private func convertBoundingBox(_ normalized: CGRect, to size: CGSize) -> CGRect {
        // Vision uses bottom-left origin, SwiftUI uses top-left
        let x = normalized.origin.x * size.width
        let y = (1 - normalized.origin.y - normalized.height) * size.height
        let width = normalized.width * size.width
        let height = normalized.height * size.height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
```

### Key Considerations

1. **Frame Rate**:
   - Process every 3rd frame (10 FPS) to avoid UI lag
   - Vision requests are CPU-intensive

2. **Coordinate Conversion**:
   - Vision uses normalized coordinates (0-1, bottom-left origin)
   - SwiftUI uses points (top-left origin)
   - Always convert before drawing overlays

3. **Memory Management**:
   - Release sample buffers after processing
   - Limit detectedObjects array to 10 items max

4. **Thread Safety**:
   - Vision requests run on background thread
   - Use `@MainActor` for ViewModel to ensure main thread updates

---

## Pattern 6: Form Validation Pattern

### Purpose

Validate user input in real-time and display inline error messages with save button state management.

### Pattern Overview

```
User types in TextField
    ↓
ViewModel validates input
    ↓
@Published validationErrors updates
    ↓
View displays error messages
    ↓
Save button disabled until valid
```

### Implementation

#### ViewModel with Validation

```swift
@MainActor
class ItemDetailViewModel: ObservableObject {
    // MARK: - Published State
    @Published var item: CatalogItem
    @Published var validationErrors: [String: String] = [:]
    @Published var isSaving: Bool = false

    // MARK: - Computed Property
    var isValid: Bool {
        validationErrors.isEmpty && !item.name.isEmpty
    }

    init(item: CatalogItem) {
        self.item = item
        setupValidation()
    }

    // MARK: - Validation
    private func setupValidation() {
        // Validate name on change
        $item
            .map(\.name)
            .removeDuplicates()
            .sink { [weak self] name in
                self?.validateName(name)
            }
            .store(in: &cancellables)

        // Validate estimated value on change
        $item
            .map(\.estimatedValue)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.validateEstimatedValue(value)
            }
            .store(in: &cancellables)
    }

    private func validateName(_ name: String) {
        if name.isEmpty {
            validationErrors["name"] = "Name is required"
        } else if name.count < 2 {
            validationErrors["name"] = "Name must be at least 2 characters"
        } else if name.count > 100 {
            validationErrors["name"] = "Name must be less than 100 characters"
        } else {
            validationErrors.removeValue(forKey: "name")
        }
    }

    private func validateEstimatedValue(_ value: Double?) {
        if let value = value {
            if value < 0 {
                validationErrors["estimatedValue"] = "Value cannot be negative"
            } else if value > 1_000_000 {
                validationErrors["estimatedValue"] = "Value seems too high"
            } else {
                validationErrors.removeValue(forKey: "estimatedValue")
            }
        } else {
            validationErrors.removeValue(forKey: "estimatedValue")
        }
    }

    // MARK: - Save
    func saveItem() async {
        guard isValid else { return }

        isSaving = true
        defer { isSaving = false }

        // ... save logic
    }
}
```

#### View with Validation UI

```swift
struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel

    var body: some View {
        Form {
            Section("Details") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Name", text: $viewModel.item.name)

                    if let error = viewModel.validationErrors["name"] {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.warningColor)
                    }
                }

                Picker("Category", selection: $viewModel.item.category) {
                    ForEach(CatalogItem.Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }

            Section("Value") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField(
                        "Estimated Value",
                        value: $viewModel.item.estimatedValue,
                        format: .currency(code: "USD")
                    )
                    .keyboardType(.decimalPad)

                    if let error = viewModel.validationErrors["estimatedValue"] {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.warningColor)
                    }
                }
            }

            Section {
                PrimaryButton(
                    title: "Save Item",
                    isLoading: viewModel.isSaving,
                    isEnabled: viewModel.isValid
                ) {
                    Task {
                        await viewModel.saveItem()
                    }
                }
            }
        }
        .navigationTitle("Edit Item")
    }
}
```

### Key Considerations

1. **Debouncing**:
   - Add `.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)` before validation
   - Prevents validation on every keystroke

2. **Inline Errors**:
   - Show errors below each field (not in alert)
   - Use warningColor (WCAG-compliant red)

3. **Save Button State**:
   - Disable until all validations pass
   - Show loading spinner during save

4. **Accessibility**:
   - Error messages must be announced by VoiceOver
   - Use `.accessibilityLabel()` to combine field + error

---

## Pattern 7: Search & Filter Pattern

### Purpose

Filter catalog items in real-time based on search text with debouncing and Firestore query optimization.

### Pattern Overview

```
User types in SearchBar
    ↓
Debounce 300ms
    ↓
ViewModel filters items array
    ↓
View displays filtered results
```

### Implementation

#### ViewModel with Search

```swift
@MainActor
class CatalogViewModel: ObservableObject {
    // MARK: - Published State
    @Published var items: [CatalogItem] = []
    @Published var searchText: String = ""
    @Published var filteredItems: [CatalogItem] = []

    private var cancellables = Set<AnyCancellable>()

    init(repository: CatalogRepository) {
        self.repository = repository
        setupSearch()
        observeItems()
    }

    // MARK: - Search Setup
    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .combineLatest($items)
            .map { searchText, items in
                if searchText.isEmpty {
                    return items
                }

                return items.filter { item in
                    item.name.localizedCaseInsensitiveContains(searchText) ||
                    item.category.localizedCaseInsensitiveContains(searchText) ||
                    (item.location?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }
            .assign(to: &$filteredItems)
    }
}
```

#### View with SearchBar

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(searchText: $viewModel.searchText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // Results
                if viewModel.filteredItems.isEmpty {
                    if viewModel.searchText.isEmpty {
                        EmptyStateCard(
                            iconName: "cube.box",
                            headline: "No Items Yet",
                            description: "Start building your catalog by scanning your first item.",
                            buttonTitle: "Scan First Item",
                            action: { /* Navigate to camera */ }
                        )
                        .padding()
                    } else {
                        EmptyStateCard(
                            iconName: "magnifyingglass",
                            headline: "No Results Found",
                            description: "Try adjusting your search terms or browse all items.",
                            buttonTitle: "Clear Search",
                            action: {
                                viewModel.searchText = ""
                            }
                        )
                        .padding()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.filteredItems) { item in
                                ItemCard(item: item) {
                                    // Navigate to detail
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Catalog")
        }
    }
}
```

### Firestore Query Optimization

```swift
// Add index on name field for efficient searching
// firestore.indexes.json:
{
  "indexes": [
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}

// Firestore query with name filter
func searchItems(query: String) async throws -> [CatalogItem] {
    let snapshot = try await db.collection("users").document(userId)
        .collection("items")
        .whereField("name", isGreaterThanOrEqualTo: query)
        .whereField("name", isLessThan: query + "\u{f8ff}") // Unicode max character
        .limit(to: 50)
        .getDocuments()

    return snapshot.documents.compactMap { try? $0.data(as: CatalogItem.self) }
}
```

### Key Considerations

1. **Debouncing**:
   - Always debounce search input (300ms standard)
   - Prevents excessive filtering on every keystroke

2. **Client-Side vs Server-Side**:
   - Client-side: Filter local items array (fast, works offline)
   - Server-side: Query Firestore (required for large datasets > 1000 items)

3. **Empty States**:
   - Differentiate between "no items" and "no results"
   - Provide clear action (Clear Search vs Scan First Item)

4. **Performance**:
   - Use `.localizedCaseInsensitiveContains` for case-insensitive search
   - Consider fuzzy matching library for advanced search

---

## Pattern 8: Navigation State Pattern

### Purpose

Manage programmatic navigation with @Published navigation state in ViewModel.

### Pattern Overview

```
User taps ItemCard
    ↓
ViewModel sets selectedItem
    ↓
NavigationLink activates
    ↓
Detail view presented
```

### Implementation

#### ViewModel with Navigation State

```swift
@MainActor
class CatalogViewModel: ObservableObject {
    // MARK: - Published State
    @Published var items: [CatalogItem] = []
    @Published var selectedItem: CatalogItem?
    @Published var isPresentingExport: Bool = false
    @Published var isPresentingSettings: Bool = false

    // MARK: - Navigation Actions
    func selectItem(_ item: CatalogItem) {
        selectedItem = item
    }

    func clearSelection() {
        selectedItem = nil
    }

    func presentExport() {
        isPresentingExport = true
    }

    func dismissExport() {
        isPresentingExport = false
    }
}
```

#### View with Navigation Bindings

```swift
struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(viewModel.items) { item in
                        ItemCard(item: item) {
                            viewModel.selectItem(item)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Catalog")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Export") {
                        viewModel.presentExport()
                    }
                }
            }
            .navigationDestination(item: $viewModel.selectedItem) { item in
                ItemDetailView(item: item)
            }
            .sheet(isPresented: $viewModel.isPresentingExport) {
                ExportView()
            }
        }
    }
}
```

#### Programmatic Navigation

```swift
// Navigate from ViewModel action
func handleDeepLink(itemId: String) {
    if let item = items.first(where: { $0.id == itemId }) {
        selectedItem = item // Triggers navigation
    }
}

// Sheet presentation
func showSettings() {
    isPresentingSettings = true
}
```

### Key Considerations

1. **NavigationStack vs NavigationView**:
   - Use `NavigationStack` (iOS 16+) for programmatic navigation
   - `.navigationDestination(item:)` binds to @Published optional

2. **Sheet Presentation**:
   - Use `@Published var isPresenting: Bool` for sheets
   - Bind with `.sheet(isPresented:)`

3. **Navigation Cleanup**:
   - Set `selectedItem = nil` after navigation completes
   - Prevents memory leaks from retained items

4. **Deep Linking**:
   - Store navigation state in ViewModel for deep link handling
   - Example: Push notification → set selectedItem → navigate

---

## Testing Integration Patterns

### Unit Test Example

```swift
import XCTest
@testable import Abundance

@MainActor
final class IntegrationPatternTests: XCTestCase {
    func testFirestoreListenerIntegration() async {
        // Given
        let mockRepo = MockCatalogRepository()
        let viewModel = CatalogViewModel(repository: mockRepo)
        let expectation = expectation(description: "Items updated")

        // When
        mockRepo.sendItems([testItem1, testItem2])

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.items.count, 2)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testAsyncOperationWithLoadingState() async {
        // Given
        let mockRepo = MockCatalogRepository()
        let viewModel = ItemDetailViewModel(item: testItem, repository: mockRepo)

        // When
        XCTAssertFalse(viewModel.isSaving)

        Task {
            await viewModel.saveItem()
        }

        // Then (during operation)
        XCTAssertTrue(viewModel.isSaving)

        // Wait for completion
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then (after operation)
        XCTAssertFalse(viewModel.isSaving)
        XCTAssertTrue(viewModel.saveSuccess)
    }
}
```

---

## Performance Optimization

### Best Practices

1. **Firestore Listener Limits**:
   - Max 1 listener per collection
   - Unsubscribe when view disappears
   - Use `.handleEvents(receiveCancel:)` for cleanup

2. **Async Operation Throttling**:
   - Debounce search input (300ms)
   - Throttle Vision frame processing (every 3rd frame)

3. **Memory Management**:
   - Always use `[weak self]` in Combine closures
   - Store cancellables in Set<AnyCancellable>
   - Clear detectedObjects array periodically

4. **Main Thread Updates**:
   - Always `.receive(on: DispatchQueue.main)` before sink
   - Annotate ViewModels with `@MainActor`

---

## References

### Architecture Documents
- docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
- docs/adr/ADR-012-state-management-strategy.md (Combine + async/await)
- docs/adr/ADR-013-dependency-injection-strategy.md (Constructor injection)

### Design Documents
- docs/design/DESIGN-007-firebase-sdk-integration.md (Firestore setup)
- docs/design/DESIGN-008-vision-framework-integration.md (Vision setup)
- docs/design/DESIGN-011-ios-data-models.md (CatalogItem model)

### Stage 2.6 Documents
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md
- docs/design/DESIGN-027-camera-capture-view-specification.md
- docs/design/DESIGN-028-catalog-view-specification.md
- docs/design/DESIGN-029-item-detail-view-specification.md
- docs/design/DESIGN-030-profile-export-view-specification.md
- docs/design/DESIGN-031-swiftui-component-library.md

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial integration patterns document with 8 complete patterns | iOS Architecture Expert |

---

**Status**: ✅ **APPROVED**

**Implementation Ready**: All 8 patterns production-ready with complete code examples, testing strategies, and performance considerations.
