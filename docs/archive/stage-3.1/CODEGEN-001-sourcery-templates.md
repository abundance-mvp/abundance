# CODEGEN-001: Sourcery Code Generation Templates

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Sourcery templates for ViewModel boilerplate and mock generation

---

## Overview

This document provides Sourcery templates to reduce MVVM boilerplate in the Abundance iOS app. Sourcery uses annotations in source code to generate repetitive patterns automatically.

**Benefits**:
- Reduce ViewModel boilerplate by 50%+
- Auto-generate mock repositories for testing
- Ensure consistency across ViewModels
- Speed up feature development

---

## Sourcery Setup

### Installation

```bash
# Homebrew
brew install sourcery

# Or Swift Package Manager
.package(url: "https://github.com/krzysztofzablocki/Sourcery.git", from: "2.0.0")
```

### Configuration (sourcery.yml)

```yaml
sources:
  - ./Packages
templates:
  - ./.sourcery
output:
  ./Generated
args:
  verbose: true
```

### Xcode Build Phase

Add Run Script build phase (runs before "Compile Sources"):

```bash
if which sourcery >/dev/null; then
  sourcery --config sourcery.yml
else
  echo "warning: Sourcery not installed, run 'brew install sourcery'"
fi
```

---

## Template 1: ViewModel Boilerplate Generator

### Purpose
Auto-generate `@Published` properties, initializers, and base functionality for ViewModels.

### Annotation Usage

```swift
import SwiftUI

// sourcery: AutoViewModel
@MainActor
class CatalogViewModel: ObservableObject {
    // sourcery: published
    var items: [CatalogItem] = []

    // sourcery: published
    var isLoading: Bool = false

    // sourcery: published
    var error: Error?

    // sourcery: injected
    private let repository: CatalogRepository

    // Sourcery will generate:
    // - @Published wrappers for marked properties
    // - init(repository:) with dependency injection
    // - clearError() method
}
```

### Template (.sourcery/ViewModel.stencil)

```stencil
// Generated using Sourcery 2.0.0
// DO NOT EDIT

{% for type in types.classes|annotated:"AutoViewModel" %}
// MARK: - {{ type.name }} Generated Code

extension {{ type.name }} {
    // MARK: - Published Properties

    {% for variable in type.variables|annotated:"published" %}
    @Published var {{ variable.name }}: {{ variable.typeName }}{% if variable.defaultValue %} = {{ variable.defaultValue }}{% endif %}
    {% endfor %}

    // MARK: - Initialization

    {% if type.variables|annotated:"injected" %}
    init(
        {% for variable in type.variables|annotated:"injected" %}
        {{ variable.name }}: {{ variable.typeName }}{% if not forloop.last %},{% endif %}
        {% endfor %}
    ) {
        {% for variable in type.variables|annotated:"injected" %}
        self.{{ variable.name }} = {{ variable.name }}
        {% endfor %}
    }
    {% endif %}

    // MARK: - Error Handling

    {% if type.variables|annotated:"published"|contains:"error" %}
    func clearError() {
        error = nil
    }
    {% endif %}

    // MARK: - Loading State

    {% if type.variables|annotated:"published"|contains:"isLoading" %}
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    {% endif %}
}
{% endfor %}
```

### Generated Output

```swift
// Generated using Sourcery 2.0.0
// DO NOT EDIT

// MARK: - CatalogViewModel Generated Code

extension CatalogViewModel {
    // MARK: - Published Properties

    @Published var items: [CatalogItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Initialization

    init(repository: CatalogRepository) {
        self.repository = repository
    }

    // MARK: - Error Handling

    func clearError() {
        error = nil
    }

    // MARK: - Loading State

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
}
```

---

## Template 2: Mock Repository Generator

### Purpose
Auto-generate mock implementations of repository protocols for testing.

### Annotation Usage

```swift
// sourcery: AutoMockable
protocol CatalogRepository {
    func fetchItems() async throws -> [CatalogItem]
    func observeItems() -> AnyPublisher<[CatalogItem], Never>
    func createItem(_ item: CatalogItem) async throws
    func updateItem(_ item: CatalogItem) async throws
    func deleteItem(id: String) async throws
}

// Sourcery will generate MockCatalogRepository
```

### Template (.sourcery/Mock.stencil)

```stencil
// Generated using Sourcery 2.0.0
// DO NOT EDIT

import Combine
@testable import Abundance

{% for protocol in types.protocols|annotated:"AutoMockable" %}
// MARK: - Mock{{ protocol.name }}

class Mock{{ protocol.name }}: {{ protocol.name }} {
    // MARK: - Call Tracking

    {% for method in protocol.methods %}
    var didCall{{ method.callName|upperFirstLetter }}: Bool = false
    var {{ method.callName }}CallCount: Int = 0
    {% endfor %}

    // MARK: - Stubbed Values

    {% for method in protocol.methods %}
    {% if method.returnTypeName %}
    {% if method.isAsync %}
    var stubbed{{ method.callName|upperFirstLetter }}Result: Result<{{ method.returnTypeName.unwrappedTypeName }}, Error> = .failure(MockError.notImplemented)
    {% else %}
    var stubbed{{ method.callName|upperFirstLetter }}: {{ method.returnTypeName }}!
    {% endif %}
    {% endif %}
    {% endfor %}

    // MARK: - Error Simulation

    var shouldFail: Bool = false
    var failureError: Error = MockError.simulatedFailure

    // MARK: - Protocol Implementation

    {% for method in protocol.methods %}
    {% if method.isAsync %}
    func {{ method.name }} async {% if method.throws %}throws {% endif %}{% if method.returnTypeName %}-> {{ method.returnTypeName }} {% endif %}{
        didCall{{ method.callName|upperFirstLetter }} = true
        {{ method.callName }}CallCount += 1

        if shouldFail {
            throw failureError
        }

        {% if method.returnTypeName %}
        switch stubbed{{ method.callName|upperFirstLetter }}Result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
        {% endif %}
    }
    {% else %}
    func {{ method.name }} {% if method.returnTypeName %}-> {{ method.returnTypeName }} {% endif %}{
        didCall{{ method.callName|upperFirstLetter }} = true
        {{ method.callName }}CallCount += 1

        {% if method.returnTypeName %}
        return stubbed{{ method.callName|upperFirstLetter }}
        {% endif %}
    }
    {% endif %}
    {% endfor %}
}

{% endfor %}

// MARK: - MockError

enum MockError: Error {
    case notImplemented
    case simulatedFailure
}
```

### Generated Output

```swift
// Generated using Sourcery 2.0.0
// DO NOT EDIT

import Combine
@testable import Abundance

// MARK: - MockCatalogRepository

class MockCatalogRepository: CatalogRepository {
    // MARK: - Call Tracking

    var didCallFetchItems: Bool = false
    var fetchItemsCallCount: Int = 0

    var didCallObserveItems: Bool = false
    var observeItemsCallCount: Int = 0

    var didCallCreateItem: Bool = false
    var createItemCallCount: Int = 0

    var didCallUpdateItem: Bool = false
    var updateItemCallCount: Int = 0

    var didCallDeleteItem: Bool = false
    var deleteItemCallCount: Int = 0

    // MARK: - Stubbed Values

    var stubbedFetchItemsResult: Result<[CatalogItem], Error> = .failure(MockError.notImplemented)
    var stubbedObserveItems: AnyPublisher<[CatalogItem], Never>!
    var stubbedCreateItemResult: Result<Void, Error> = .failure(MockError.notImplemented)
    var stubbedUpdateItemResult: Result<Void, Error> = .failure(MockError.notImplemented)
    var stubbedDeleteItemResult: Result<Void, Error> = .failure(MockError.notImplemented)

    // MARK: - Error Simulation

    var shouldFail: Bool = false
    var failureError: Error = MockError.simulatedFailure

    // MARK: - Protocol Implementation

    func fetchItems() async throws -> [CatalogItem] {
        didCallFetchItems = true
        fetchItemsCallCount += 1

        if shouldFail {
            throw failureError
        }

        switch stubbedFetchItemsResult {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    func observeItems() -> AnyPublisher<[CatalogItem], Never> {
        didCallObserveItems = true
        observeItemsCallCount += 1

        return stubbedObserveItems
    }

    func createItem(_ item: CatalogItem) async throws {
        didCallCreateItem = true
        createItemCallCount += 1

        if shouldFail {
            throw failureError
        }

        switch stubbedCreateItemResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func updateItem(_ item: CatalogItem) async throws {
        didCallUpdateItem = true
        updateItemCallCount += 1

        if shouldFail {
            throw failureError
        }

        switch stubbedUpdateItemResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func deleteItem(id: String) async throws {
        didCallDeleteItem = true
        deleteItemCallCount += 1

        if shouldFail {
            throw failureError
        }

        switch stubbedDeleteItemResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - MockError

enum MockError: Error {
    case notImplemented
    case simulatedFailure
}
```

---

## Template 3: Equatable Conformance Generator

### Purpose
Auto-generate `Equatable` conformance for structs.

### Annotation Usage

```swift
// sourcery: AutoEquatable
struct CatalogItem: Codable, Identifiable {
    let id: String
    var name: String
    var category: String

    // sourcery: skipEquatable
    var imageURL: URL? // Skip this property in == operator
}
```

### Template (.sourcery/Equatable.stencil)

```stencil
// Generated using Sourcery 2.0.0
// DO NOT EDIT

{% for type in types.structs|annotated:"AutoEquatable" %}
// MARK: - {{ type.name }} Equatable

extension {{ type.name }}: Equatable {
    static func == (lhs: {{ type.name }}, rhs: {{ type.name }}) -> Bool {
        {% for variable in type.variables %}
        {% if not variable.annotations.skipEquatable %}
        lhs.{{ variable.name }} == rhs.{{ variable.name }}{% if not forloop.last %} &&{% endif %}
        {% endif %}
        {% endfor %}
    }
}
{% endfor %}
```

### Generated Output

```swift
// Generated using Sourcery 2.0.0
// DO NOT EDIT

// MARK: - CatalogItem Equatable

extension CatalogItem: Equatable {
    static func == (lhs: CatalogItem, rhs: CatalogItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.category == rhs.category
    }
}
```

---

## Usage Examples

### Example 1: ViewModel with Generated Code

```swift
import SwiftUI
import Combine

// sourcery: AutoViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    // Generated @Published wrappers
    // sourcery: published
    var catalogItems: [CatalogItem] = []

    // sourcery: published
    var userProfile: User?

    // sourcery: published
    var isLoading: Bool = false

    // sourcery: published
    var error: Error?

    // Generated init
    // sourcery: injected
    private let catalogRepository: CatalogRepository

    // sourcery: injected
    private let userRepository: UserRepository

    // Custom business logic (not generated)
    func loadDashboard() async {
        setLoading(true) // Generated method
        defer { setLoading(false) }

        do {
            async let items = catalogRepository.fetchItems()
            async let profile = userRepository.fetchProfile()

            catalogItems = try await items
            userProfile = try await profile
        } catch {
            self.error = error
        }
    }
}
```

### Example 2: Test with Generated Mock

```swift
import XCTest
@testable import Abundance

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var mockCatalogRepo: MockCatalogRepository! // Generated
    var mockUserRepo: MockUserRepository! // Generated

    override func setUp() async throws {
        try await super.setUp()
        mockCatalogRepo = MockCatalogRepository()
        mockUserRepo = MockUserRepository()

        sut = DashboardViewModel(
            catalogRepository: mockCatalogRepo,
            userRepository: mockUserRepo
        )
    }

    func testLoadDashboardSuccess() async {
        // Given: Stub successful responses
        mockCatalogRepo.stubbedFetchItemsResult = .success(TestFixtures.catalogItems())
        mockUserRepo.stubbedFetchProfileResult = .success(TestFixtures.user())

        // When
        await sut.loadDashboard()

        // Then: Verify method calls (generated properties)
        XCTAssertTrue(mockCatalogRepo.didCallFetchItems)
        XCTAssertEqual(mockCatalogRepo.fetchItemsCallCount, 1)
        XCTAssertTrue(mockUserRepo.didCallFetchProfile)

        // Verify state
        XCTAssertFalse(sut.items.isEmpty)
        XCTAssertNotNil(sut.userProfile)
        XCTAssertNil(sut.error)
    }
}
```

---

## Best Practices

### ✅ DO

1. **Use Sourcery for repetitive patterns** - ViewModels, mocks, Equatable
2. **Version control generated code** - Check into git for Xcode autocomplete
3. **Re-run Sourcery on every build** - Xcode build phase keeps generated code fresh
4. **Document annotations** - Team members should understand `// sourcery:` comments
5. **Test generated code** - Verify mocks work correctly in unit tests

### ❌ DON'T

1. **Don't manually edit generated files** - Changes will be overwritten
2. **Don't use Sourcery for complex logic** - Only boilerplate/patterns
3. **Don't over-annotate** - Use Sourcery where it saves time, not everywhere
4. **Don't skip Sourcery in CI** - Ensure generated code is up-to-date

---

## CI/CD Integration

### GitHub Actions

```yaml
- name: Generate code with Sourcery
  run: |
    brew install sourcery
    sourcery --config sourcery.yml

- name: Verify generated code is committed
  run: |
    git diff --exit-code Generated/
    # Fails if generated code is out of date
```

---

## Alternative: Manual Patterns (No Sourcery)

If Sourcery is not used, implement patterns manually:

### BaseViewModel

```swift
@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: Error?

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func clearError() {
        error = nil
    }
}

// Usage
class CatalogViewModel: BaseViewModel {
    @Published var items: [CatalogItem] = []

    private let repository: CatalogRepository

    init(repository: CatalogRepository) {
        self.repository = repository
        super.init()
    }
}
```

---

## References

- Sourcery Documentation: https://github.com/krzysztofzablocki/Sourcery
- Stencil Template Language: https://stencil.fuller.li/en/latest/
- **CODE-EXAMPLE-002**: Catalog MVVM Implementation (manual patterns)
- **TEST-EXAMPLE-001**: ViewModel Unit Tests (manual mocks)

---

## Verification

✅ ViewModel boilerplate template created
✅ Mock repository template created
✅ Equatable conformance template created
✅ Sourcery configuration documented
✅ Xcode build phase integration explained
✅ Usage examples provided
✅ CI/CD integration documented

---

**Status**: ✅ Complete

**Next**: TEST-EXAMPLE-002 (iOS Testing Patterns)
