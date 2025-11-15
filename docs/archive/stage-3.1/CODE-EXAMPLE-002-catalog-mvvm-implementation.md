# CODE-EXAMPLE-002: Catalog Feature MVVM Implementation

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Complete MVVM reference implementation for Catalog feature

---

## Overview

This document provides a complete MVVM implementation for the Abundance Catalog feature, following ADR-010 (SwiftUI Architecture Pattern) and ADR-013 (Dependency Injection Strategy).

**Architecture**: Model-View-ViewModel (MVVM)
**Pattern**: Repository pattern for data access
**Testing**: Constructor injection with mock repositories

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      CatalogView (SwiftUI)                   │
│  @StateObject var viewModel: CatalogViewModel                │
│  - Displays catalog items in List                            │
│  - Handles user actions (delete, refresh)                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ observes @Published
                       │ calls async methods
                       ▼
┌─────────────────────────────────────────────────────────────┐
│            CatalogViewModel (@MainActor, ObservableObject)   │
│  @Published var items: [CatalogItem]                         │
│  @Published var isLoading: Bool                              │
│  @Published var error: Error?                                │
│  - async func fetchItems()                                   │
│  - async func deleteItem(id:)                                │
│  - func observeItems() (Combine)                             │
└──────────────────────┬──────────────────────────────────────┘
                       │ uses
                       │ (constructor injection)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              CatalogRepository (protocol)                     │
│  - func fetchItems() async throws -> [CatalogItem]           │
│  - func observeItems() -> AnyPublisher<[CatalogItem], Never> │
│  - func createItem(_ item: CatalogItem) async throws         │
│  - func updateItem(_ item: CatalogItem) async throws         │
│  - func deleteItem(id: String) async throws                  │
└─────────────┬───────────────────────────────────────────────┘
              │
     ┌────────┴──────────┐
     │                   │
     ▼                   ▼
┌─────────────┐   ┌──────────────────┐
│  Firestore  │   │  MockRepository  │
│ Repository  │   │  (for tests)     │
│ (production)│   └──────────────────┘
└─────────────┘
```

---

## Model Layer

### CatalogItem (Codable, Sendable)

```swift
import Foundation

/// Catalog item representing a user's possession
struct CatalogItem: Codable, Identifiable, Sendable {
    // MARK: - Properties

    let id: String
    var name: String
    var category: String
    var location: String?
    var estimatedValue: Double?
    var imageURL: URL?
    var barcodeValue: String?
    var aiAnalysis: AIAnalysis?
    let createdAt: Date
    var updatedAt: Date
    let userId: String

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String,
        location: String? = nil,
        estimatedValue: Double? = nil,
        imageURL: URL? = nil,
        barcodeValue: String? = nil,
        aiAnalysis: AIAnalysis? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        userId: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.location = location
        self.estimatedValue = estimatedValue
        self.imageURL = imageURL
        self.barcodeValue = barcode Value
        self.aiAnalysis = aiAnalysis
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.userId = userId
    }
}

// MARK: - Hashable Conformance

extension CatalogItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CatalogItem, rhs: CatalogItem) -> Bool {
        lhs.id == rhs.id
    }
}
```

### AIAnalysis

```swift
/// AI analysis results from 4-layer pipeline
struct AIAnalysis: Codable, Sendable {
    var layer1: Layer1Result?  // On-device Vision
    var layer2a: Layer2aResult? // Gemini attributes
    var layer2b: Layer2bResult? // Product ID
    var layer3: Layer3Result?   // Claude synthesis
}

struct Layer1Result: Codable, Sendable {
    let detectedObjects: [DetectedObject]
    let barcodes: [String]
    let processedAt: Date
}

struct DetectedObject: Codable, Sendable {
    let label: String
    let confidence: Double
    let boundingBox: CGRect
}

struct Layer2aResult: Codable, Sendable {
    let color: String?
    let material: String?
    let condition: String?
    let category: String?
}

struct Layer2bResult: Codable, Sendable {
    let productName: String?
    let brand: String?
    let model: String?
    let upc: String?
}

struct Layer3Result: Codable, Sendable {
    let synthesizedName: String
    let estimatedValue: Double?
    let confidence: Double
}
```

---

## Repository Layer

### CatalogRepository Protocol

```swift
import Combine

/// Protocol for catalog data access
protocol CatalogRepository {
    /// Fetch all catalog items for current user
    /// - Returns: Array of CatalogItem
    /// - Throws: CatalogError if fetch fails
    func fetchItems() async throws -> [CatalogItem]

    /// Observe real-time updates to catalog items
    /// - Returns: Publisher that emits catalog item arrays
    func observeItems() -> AnyPublisher<[CatalogItem], Never>

    /// Create new catalog item
    /// - Parameter item: CatalogItem to create
    /// - Throws: CatalogError if creation fails
    func createItem(_ item: CatalogItem) async throws

    /// Update existing catalog item
    /// - Parameter item: CatalogItem with updated fields
    /// - Throws: CatalogError if update fails
    func updateItem(_ item: CatalogItem) async throws

    /// Delete catalog item
    /// - Parameter id: Item ID to delete
    /// - Throws: CatalogError if deletion fails
    func deleteItem(id: String) async throws
}

/// Catalog-specific errors
enum CatalogError: Error, LocalizedError {
    case notFound
    case unauthorized
    case networkFailure
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Item not found"
        case .unauthorized:
            return "You don't have permission to access this item"
        case .networkFailure:
            return "Network connection failed"
        case .decodingError:
            return "Failed to parse server response"
        }
    }
}
```

### FirestoreCatalogRepository (Production)

```swift
import FirebaseFirestore
import Combine

/// Firestore implementation of CatalogRepository
class FirestoreCatalogRepository: CatalogRepository {
    // MARK: - Properties

    private let db = Firestore.firestore()
    private let itemsSubject = PassthroughSubject<[CatalogItem], Never>()
    private var listener: ListenerRegistration?

    // MARK: - CatalogRepository Conformance

    func fetchItems() async throws -> [CatalogItem] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CatalogError.unauthorized
        }

        let snapshot = try await db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: CatalogItem.self)
        }
    }

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Just([]).eraseToAnyPublisher()
        }

        // Set up Firestore real-time listener
        listener = db.collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }

                let items = documents.compactMap { doc -> CatalogItem? in
                    try? doc.data(as: CatalogItem.self)
                }

                self?.itemsSubject.send(items)
            }

        return itemsSubject.eraseToAnyPublisher()
    }

    func createItem(_ item: CatalogItem) async throws {
        try db.collection("items").document(item.id).setData(from: item)
    }

    func updateItem(_ item: CatalogItem) async throws {
        var updatedItem = item
        updatedItem.updatedAt = Date()
        try db.collection("items").document(item.id).setData(from: updatedItem)
    }

    func deleteItem(id: String) async throws {
        try await db.collection("items").document(id).delete()
    }

    // MARK: - Deinitialization

    deinit {
        listener?.remove()
    }
}
```

---

## ViewModel Layer

### CatalogViewModel

```swift
import SwiftUI
import Combine

/// ViewModel for Catalog list screen
@MainActor
class CatalogViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let repository: CatalogRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize with repository (constructor injection)
    /// - Parameter repository: CatalogRepository implementation
    init(repository: CatalogRepository) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Fetch catalog items asynchronously
    func fetchItems() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = error
        }
    }

    /// Start observing real-time updates
    func observeItems() {
        repository.observeItems()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }

    /// Delete item
    /// - Parameter id: Item ID to delete
    func deleteItem(id: String) async {
        do {
            try await repository.deleteItem(id: id)
            items.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    /// Refresh items (pull-to-refresh)
    func refresh() async {
        await fetchItems()
    }
}
```

---

## View Layer

### CatalogView (SwiftUI)

```swift
import SwiftUI

/// Catalog list view
struct CatalogView: View {
    // MARK: - ViewModel

    @StateObject private var viewModel: CatalogViewModel

    // MARK: - Initialization

    init(repository: CatalogRepository = FirestoreCatalogRepository()) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(repository: repository))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.items.isEmpty {
                    emptyView
                } else {
                    catalogList
                }
            }
            .navigationTitle("Catalog")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Navigate to camera
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .task {
                await viewModel.fetchItems()
                viewModel.observeItems() // Start real-time sync
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert(error: $viewModel.error)
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading items...")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Tap + to add your first item")
        )
    }

    private var catalogList: some View {
        List {
            ForEach(viewModel.items) { item in
                NavigationLink(value: item) {
                    CatalogItemRow(item: item)
                }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.deleteItem(id: viewModel.items[index].id)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
```

### CatalogItemRow (Reusable Component)

```swift
import SwiftUI

/// Row view for catalog item
struct CatalogItemRow: View {
    let item: CatalogItem

    var body: some View {
        HStack(spacing: 12) {
            // Image
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Color.gray.opacity(0.2)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    ProgressView()
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                Text(item.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let value = item.estimatedValue {
                    Text("$\(value, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
```

---

## Mock Repository (for Testing)

```swift
import Combine

/// Mock implementation of CatalogRepository for testing
class MockCatalogRepository: CatalogRepository {
    // MARK: - Test Configuration

    var stubbedItems: [CatalogItem] = []
    var shouldFail: Bool = false
    var didCallFetchItems: Bool = false
    var didCallDeleteItem: Bool = false

    private let itemsSubject = PassthroughSubject<[CatalogItem], Never>()

    // MARK: - CatalogRepository Conformance

    func fetchItems() async throws -> [CatalogItem] {
        didCallFetchItems = true

        if shouldFail {
            throw CatalogError.networkFailure
        }

        return stubbedItems
    }

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        return itemsSubject.eraseToAnyPublisher()
    }

    func createItem(_ item: CatalogItem) async throws {
        if shouldFail {
            throw CatalogError.networkFailure
        }

        stubbedItems.append(item)
        itemsSubject.send(stubbedItems)
    }

    func updateItem(_ item: CatalogItem) async throws {
        if shouldFail {
            throw CatalogError.networkFailure
        }

        if let index = stubbedItems.firstIndex(where: { $0.id == item.id }) {
            stubbedItems[index] = item
            itemsSubject.send(stubbedItems)
        } else {
            throw CatalogError.notFound
        }
    }

    func deleteItem(id: String) async throws {
        didCallDeleteItem = true

        if shouldFail {
            throw CatalogError.networkFailure
        }

        stubbedItems.removeAll { $0.id == id }
        itemsSubject.send(stubbedItems)
    }

    // MARK: - Test Helpers

    /// Send items to observers (simulates Firestore snapshot)
    func sendItems(_ items: [CatalogItem]) {
        itemsSubject.send(items)
    }
}
```

---

## References

- **ADR-010**: SwiftUI Architecture Pattern (MVVM)
- **ADR-012**: State Management Strategy (Combine + async/await)
- **ADR-013**: Dependency Injection Strategy (constructor injection)
- **CODE-EXAMPLE-001**: Swift 6 Concurrency Patterns (@MainActor ViewModels)

---

## Verification

✅ Repository protocol defined with async/await methods
✅ FirestoreCatalogRepository implements real-time sync with Combine
✅ CatalogViewModel uses @MainActor + @Published
✅ CatalogView uses @StateObject + .task modifier
✅ MockCatalogRepository enables unit testing
✅ Constructor injection used throughout (ADR-013)
✅ Follows MVVM pattern (ADR-010)

---

**Status**: ✅ Complete

**Next**: TEST-EXAMPLE-001 (ViewModel Unit Tests)
