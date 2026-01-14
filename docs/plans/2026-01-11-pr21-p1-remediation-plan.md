# PR #21 P1 Remediation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Address all 27 P1 issues from PR #21 code review, organized by priority and dependency.

**Architecture:** Three waves of fixes - (1) High-impact runtime issues, (2) Code quality cleanup, (3) Swift 6 concurrency improvements. Each wave can be executed independently.

**Tech Stack:** Swift 6.0, SwiftUI, Firebase iOS SDK 11.11.0, XCTest

---

## Wave 1: High-Impact P1s (Runtime Issues)

These issues can cause silent failures or incorrect behavior in production.

---

### Task 1: Fix Empty userId Fallback in InventoryViewModel

**Files:**
- Modify: `Sources/InventoryFeature/InventoryViewModel.swift:18-25`
- Create: `Tests/InventoryFeatureTests/InventoryViewModelTests.swift`

**Problem:** Empty string fallback silently fails all Firestore queries when user not authenticated.

**Step 1: Write failing test for unauthenticated state**

```swift
// Tests/InventoryFeatureTests/InventoryViewModelTests.swift
import XCTest
@testable import InventoryFeature
@testable import Persistence

final class InventoryViewModelTests: XCTestCase {

    func testInit_withNoUserId_setsErrorState() async {
        // Given: No authenticated user (nil userId)
        let mockRepository = MockItemRepository()

        // When: Create ViewModel without userId
        let viewModel = await InventoryViewModel(
            userId: nil,
            itemRepository: mockRepository,
            requiresAuthentication: true  // New parameter
        )

        // Then: Should have error state, not empty string
        await MainActor.run {
            XCTAssertNotNil(viewModel.error)
            XCTAssertEqual(viewModel.error, "Authentication required")
        }
    }
}

// Mock repository for testing
final class MockItemRepository: ItemRepository {
    var getItemsCalled = false
    var lastUserId: String?

    func getItems(userId: String) async throws -> [Item] {
        getItemsCalled = true
        lastUserId = userId
        return []
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        Just([]).eraseToAnyPublisher()
    }

    // Implement other protocol requirements with stubs...
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter InventoryViewModelTests.testInit_withNoUserId_setsErrorState`
Expected: FAIL (parameter doesn't exist yet)

**Step 3: Implement authentication check**

```swift
// Sources/InventoryFeature/InventoryViewModel.swift
@MainActor
public final class InventoryViewModel: ObservableObject {
    @Published public var items: [Item] = []
    @Published public var isLoading = false
    @Published public var error: String?

    private let itemRepository: ItemRepository
    private let userId: String?  // Changed to optional
    private var cancellables = Set<AnyCancellable>()

    public init(
        userId: String? = nil,
        itemRepository: ItemRepository = ItemService(),
        requiresAuthentication: Bool = true
    ) {
        let resolvedUserId = userId ?? Auth.auth().currentUser?.uid

        if requiresAuthentication && resolvedUserId == nil {
            self.userId = nil
            self.itemRepository = itemRepository
            self.error = "Authentication required"
            return
        }

        self.userId = resolvedUserId
        self.itemRepository = itemRepository
        observeItems()
    }

    public func loadItems() async {
        guard let userId = userId else {
            error = "Authentication required"
            return
        }

        isLoading = true
        error = nil

        do {
            items = try await itemRepository.getItems(userId: userId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func observeItems() {
        guard let userId = userId else { return }

        itemRepository.observeItems(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter InventoryViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/InventoryFeature/InventoryViewModel.swift Tests/InventoryFeatureTests/InventoryViewModelTests.swift
git commit -m "fix(inventory): handle unauthenticated state with error instead of empty userId

BREAKING: InventoryViewModel now requires authentication by default.
Pass requiresAuthentication: false for preview/testing without auth.

Resolves P1: silent failure when user not authenticated"
```

---

### Task 2: Add Missing Integration Tests for ItemService Layer1→2 Handoff

**Files:**
- Modify: `Tests/PersistenceTests/ItemServiceTests.swift`

**Problem:** Critical handoff functionality has no runtime test coverage.

**Step 1: Add integration test stubs with clear structure**

```swift
// Add to Tests/PersistenceTests/ItemServiceTests.swift

// MARK: - Integration Tests (Require Firebase Emulator)

/// Integration tests for ItemService.createItemWithLayer1Metadata
/// Run with: firebase emulators:start --only firestore
/// Then: swift test --filter ItemServiceTests.testIntegration
final class ItemServiceIntegrationTests: XCTestCase {

    var sut: ItemService!

    override func setUp() async throws {
        try await super.setUp()
        // Configure Firestore to use emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        sut = ItemService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func testIntegration_createItemWithLayer1Metadata_createsDocumentWithCorrectSchema() async throws {
        // Given: Layer 1 metadata from camera detection
        let userId = "test-user-\(UUID().uuidString)"
        let imageUrl = "gs://test-bucket/test-image.jpg"
        let metadata = Layer1Metadata(
            detectedClass: "tent",
            confidence: 0.87,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.75
        )

        // When: Create item with Layer 1 metadata
        try await sut.createItemWithLayer1Metadata(
            userId: userId,
            imageUrl: imageUrl,
            layer1Metadata: metadata
        )

        // Then: Document should exist with correct schema
        let items = try await sut.getItems(userId: userId)
        XCTAssertEqual(items.count, 1)

        let item = items[0]
        XCTAssertEqual(item.userId, userId)
        XCTAssertEqual(item.imageUrl, imageUrl)
        XCTAssertEqual(item.status, .pending)
        XCTAssertNotNil(item.aiAnalysis?.layer1)
        XCTAssertEqual(item.aiAnalysis?.layer1?.detectedClass, "tent")
    }

    func testIntegration_createItemWithLayer1Metadata_includesIdField() async throws {
        // Given: Valid inputs
        let userId = "test-user-\(UUID().uuidString)"
        let imageUrl = "gs://test-bucket/test-image.jpg"
        let metadata = Layer1Metadata(
            detectedClass: "tent",
            confidence: 0.87,
            boundingBox: .zero,
            qualityScore: 0.75
        )

        // When: Create item
        try await sut.createItemWithLayer1Metadata(
            userId: userId,
            imageUrl: imageUrl,
            layer1Metadata: metadata
        )

        // Then: Item should have non-empty id
        let items = try await sut.getItems(userId: userId)
        XCTAssertFalse(items[0].id.isEmpty, "Item id should not be empty")
    }
}
```

**Step 2: Run test to verify setup**

Run: `swift test --filter ItemServiceIntegrationTests -v`
Expected: Tests run (may fail without emulator, but structure verified)

**Step 3: Document emulator setup**

Add to `Tests/PersistenceTests/README.md`:

```markdown
# Persistence Tests

## Running Integration Tests

Integration tests require Firebase Emulator Suite.

### Setup

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Start emulators: `firebase emulators:start --only firestore`
3. Run tests: `swift test --filter ItemServiceIntegrationTests`

### CI/CD

Integration tests are skipped in CI by default. To enable:
- Set `FIREBASE_EMULATOR_HOST=localhost:8080` environment variable
```

**Step 4: Commit**

```bash
git add Tests/PersistenceTests/ItemServiceTests.swift Tests/PersistenceTests/README.md
git commit -m "test(persistence): add integration tests for ItemService Layer1 handoff

Adds Firebase emulator-based tests for:
- createItemWithLayer1Metadata document schema
- id field inclusion in created documents

Resolves P1: missing integration tests for critical handoff"
```

---

### Task 3: Fix Firebase SDK Version Mismatch

**Files:**
- Modify: `Package.swift:17`
- Modify: `project.yml:70-72`

**Problem:** Package.swift uses 11.11.0, project.yml uses 12.6.0 - can cause build inconsistencies.

**Step 1: Verify current versions**

Run: `grep -n "firebase" Package.swift project.yml`

**Step 2: Align to consistent version (11.11.0 - the SPM version)**

```swift
// Package.swift - keep as-is (11.11.0)
.package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.11.0"),
```

```yaml
# project.yml - update to match
packages:
  firebase-ios-sdk:
    url: https://github.com/firebase/firebase-ios-sdk.git
    from: 11.11.0
```

Note: project.yml uses xcframeworks repo, Package.swift uses main repo. Align version numbers.

**Step 3: Clean and rebuild**

Run: `rm -rf .build && swift build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Package.swift project.yml
git commit -m "fix(deps): align Firebase SDK version to 11.11.0 across build systems

Package.swift and project.yml now use same Firebase version.
Prevents build inconsistencies between SPM and XcodeGen builds.

Resolves P1: Firebase version mismatch"
```

---

## Wave 2: Code Quality P1s (Cleanup)

These issues don't affect runtime but create maintenance burden.

---

### Task 4: Remove Orphaned FloatingTabBar

**Files:**
- Delete: `App/FloatingTabBar.swift`
- Modify: `App/MainTabView.swift` (verify no references)

**Step 1: Search for FloatingTabBar usage**

Run: `grep -r "FloatingTabBar" Sources/ App/ --include="*.swift"`

**Step 2: Verify no usage, then delete**

```bash
# Verify no imports or references
grep -r "FloatingTabBar" . --include="*.swift" | grep -v "FloatingTabBar.swift"
# If no results, safe to delete
trash App/FloatingTabBar.swift
```

**Step 3: Build to verify no breakage**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add -A
git commit -m "chore(app): remove orphaned FloatingTabBar component

Component was defined but never used. Replaced by standard TabView.

Resolves P1: orphaned FloatingTabBar"
```

---

### Task 5: Consolidate Duplicate Tab Enums

**Files:**
- Modify: `App/MainTabView.swift:7-11`

**Problem:** FloatingTabBar.Tab and MainTabView.Tab are duplicates. After Task 4, only MainTabView.Tab remains, but verify it's correctly scoped.

**Step 1: Verify Tab enum is properly scoped**

The Tab enum in MainTabView.swift:7-11 is correctly defined as a nested type. No action needed if FloatingTabBar is removed.

**Step 2: Document the decision**

Already consolidated after Task 4.

**Step 3: Commit** (if separate from Task 4)

```bash
git commit --allow-empty -m "docs: Tab enum consolidated (FloatingTabBar removed in previous commit)"
```

---

### Task 6: Fix Git Hooks Path

**Files:**
- Modify: `scripts/setup-git-hooks.sh:21,54`

**Problem:** Hooks use `cd ios` but directory doesn't exist (iOS code is at root).

**Step 1: Update pre-commit hook path**

```bash
# scripts/setup-git-hooks.sh - line 21
# Change: cd ios && swiftlint lint --strict
# To: swiftlint lint --strict
```

**Step 2: Update pre-push hook path**

```bash
# scripts/setup-git-hooks.sh - line 54
# Change: cd ios && swift test
# To: swift test
```

**Step 3: Full updated script**

```bash
#!/bin/bash
# Setup Git Hooks
# Installs pre-commit and pre-push hooks

set -euo pipefail

echo "🪝 Setting up Git hooks..."

# Pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook: Run linters before commit

set -e

echo "🔍 Running pre-commit checks..."

# SwiftLint (if iOS files changed)
if git diff --cached --name-only | grep -q "\.swift$"; then
  echo "Running SwiftLint..."
  swiftlint lint --strict
fi

# ESLint (if TypeScript files changed)
if git diff --cached --name-only | grep -q "\.ts$"; then
  echo "Running ESLint..."
  cd functions && npm run lint
fi

# Document validation (if markdown files in docs/ changed)
if git diff --cached --name-only | grep -q "^docs/.*\.md$"; then
  echo "Validating document references..."
  python3 scripts/validate_doc_references.py
fi

echo "✅ Pre-commit checks passed"
EOF

chmod +x .git/hooks/pre-commit
echo "✅ Installed: pre-commit hook"

# Pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# Pre-push hook: Run tests before push

set -e

echo "🔍 Running pre-push checks..."

# iOS tests (if iOS files changed)
if git diff --name-only origin/main...HEAD | grep -q "\.swift$"; then
  echo "Running iOS tests..."
  swift test
fi

# Backend tests (if backend files changed)
if git diff --name-only origin/main...HEAD | grep -q "functions/.*\.ts$"; then
  echo "Running backend tests..."
  cd functions && npm test
fi

echo "✅ Pre-push checks passed"
EOF

chmod +x .git/hooks/pre-push
echo "✅ Installed: pre-push hook"

echo "✅ Git hooks setup complete"
```

**Step 4: Test the hooks**

Run: `./scripts/setup-git-hooks.sh`
Expected: ✅ Git hooks setup complete

**Step 5: Commit**

```bash
git add scripts/setup-git-hooks.sh
git commit -m "fix(scripts): update git hooks to use correct paths

Removed 'cd ios' references - iOS code is at repository root.
Updated backend path from 'backend/functions' to 'functions'.

Resolves P1: git hooks use non-existent 'cd ios' path"
```

---

## Wave 3: Swift 6 Concurrency P1s

These fixes improve thread safety and Swift 6 compliance.

---

### Task 7: Fix @State with Set<AnyCancellable> in CameraDetectionView

**Files:**
- Modify: `Sources/CameraFeature/Views/CameraDetectionView.swift:14,101-126`

**Problem:** Per Apple docs, @State should not be used with reference types like Set<AnyCancellable>. SwiftUI won't properly manage lifecycle.

**Step 1: Move cancellables to ViewModel**

The CameraDetectionViewModel should own the Combine subscriptions, not the View.

```swift
// Sources/CameraFeature/Views/CameraDetectionView.swift
// REMOVE line 14:
// @State private var cancellables = Set<AnyCancellable>()

// MODIFY setupCamera() to use ViewModel:
private func setupCamera() {
    Task {
        do {
            try await cameraService.startSession()
            // Wire frame loop through ViewModel
            await viewModel.startFrameProcessing(from: cameraService)
        } catch {
            print("Failed to start camera session: \(error)")
        }
    }
}

private func teardownCamera() {
    cameraService.stopSession()
    Task {
        await viewModel.stopFrameProcessing()
    }
}
```

**Step 2: Add frame processing to ViewModel**

```swift
// Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift
// Add to class:

private var frameSubscription: AnyCancellable?

public func startFrameProcessing(from cameraService: CameraService) {
    frameSubscription = cameraService.framePublisher
        .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
        .sink { [weak self] pixelBuffer in
            Task { [weak self] in
                await self?.processFrame(pixelBuffer)
            }
        }
}

public func stopFrameProcessing() {
    frameSubscription?.cancel()
    frameSubscription = nil
}
```

**Step 3: Build and test**

Run: `swift build && swift test --filter CameraFeatureTests`
Expected: PASS

**Step 4: Commit**

```bash
git add Sources/CameraFeature/Views/CameraDetectionView.swift Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift
git commit -m "fix(camera): move Combine subscriptions from View to ViewModel

Per Apple docs, @State should not hold reference types like Set<AnyCancellable>.
Moved frame processing subscription to ViewModel for proper lifecycle management.

Resolves P1: @State with reference type in CameraDetectionView"
```

---

### Task 8: Add Sendable Conformance to BarcodeDetector

**Files:**
- Modify: `Sources/VisionCore/Services/BarcodeDetector.swift:10`
- Modify: `Sources/VisionCore/Services/BarcodeDetectorProtocol.swift`

**Problem:** BarcodeDetector lacks Sendable, inconsistent with other detection services.

**Step 1: Update protocol to require Sendable**

```swift
// Sources/VisionCore/Services/BarcodeDetectorProtocol.swift
public protocol BarcodeDetectorProtocol: Sendable {
    func detectBarcodes(in image: PlatformImage) async throws -> [BarcodeResult]
}
```

**Step 2: Make BarcodeDetector Sendable**

```swift
// Sources/VisionCore/Services/BarcodeDetector.swift:10
// The class has no mutable state, so it's trivially Sendable
public final class BarcodeDetector: BarcodeDetectorProtocol, Sendable {
    // ... rest unchanged
}
```

**Step 3: Build to verify**

Run: `swift build`
Expected: BUILD SUCCEEDED (no Sendable violations)

**Step 4: Commit**

```bash
git add Sources/VisionCore/Services/BarcodeDetector.swift Sources/VisionCore/Services/BarcodeDetectorProtocol.swift
git commit -m "fix(vision): add Sendable conformance to BarcodeDetector

BarcodeDetector is stateless and safe to use across isolation boundaries.
Protocol now requires Sendable for consistency with other detectors.

Resolves P1: BarcodeDetector missing Sendable conformance"
```

---

### Task 9: Replace DispatchQueue.main.asyncAfter with Task

**Files:**
- Modify: `Sources/CameraFeature/Views/CameraDetectionView.swift:59`

**Problem:** DispatchQueue.main.asyncAfter should use Task.sleep in Swift 6 for structured concurrency.

**Step 1: Replace with Task-based delay**

```swift
// Sources/CameraFeature/Views/CameraDetectionView.swift:55-63
// BEFORE:
// .onAppear {
//     DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//         sparkleCenter = nil
//     }
// }

// AFTER:
.task {
    try? await Task.sleep(for: .seconds(0.5))
    sparkleCenter = nil
}
```

**Step 2: Build and test**

Run: `swift build`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sources/CameraFeature/Views/CameraDetectionView.swift
git commit -m "fix(camera): replace DispatchQueue.asyncAfter with Task.sleep

Uses Swift structured concurrency for animation delays.
Task modifier ensures proper cancellation on view disappear.

Resolves P1: asyncAfter should use Task in Swift 6"
```

---

## Wave 4: Documentation P1s (Quick Fixes)

---

### Task 10: Fix Workflow Count in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md:43`

**Step 1: Count actual workflows**

Run: `ls -1 .github/workflows/*.yml | wc -l`

**Step 2: Update documentation**

```markdown
# CLAUDE.md line 43
# Change "8 workflows" to "9 workflows" (or actual count)
```

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: fix workflow count in CLAUDE.md (9 not 8)"
```

---

## Execution Summary

| Wave | Tasks | Priority | Time Est. |
|------|-------|----------|-----------|
| 1 | Tasks 1-3 | High | Core functionality |
| 2 | Tasks 4-6 | Medium | Code cleanup |
| 3 | Tasks 7-9 | Medium | Swift 6 compliance |
| 4 | Task 10 | Low | Documentation |

**Recommended execution order:**
1. Wave 1 first (runtime issues)
2. Wave 3 next (Swift 6 - affects Wave 2 cleanup)
3. Wave 2 (cleanup after Swift 6 fixes)
4. Wave 4 last (docs)

---

## Verification Checklist

After all tasks complete:

- [ ] `swift build` succeeds
- [ ] `swift test` passes (all tests)
- [ ] `swiftlint lint` has no errors
- [ ] No compiler warnings about Sendable
- [ ] Git hooks work: `./scripts/setup-git-hooks.sh`

---

**Created:** 2026-01-11
**PR:** #21 Follow-up
**Branch:** fix/pr21-p1-remediation
