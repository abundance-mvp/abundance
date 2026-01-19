# SPEC-UI-002: Catalog Inventory Flow

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## 1. Overview

The Catalog Inventory Flow provides users with a comprehensive interface to browse, view, and edit their cataloged household items. This feature is the primary destination for users after capturing items through the camera, displaying all processed items with their AI-extracted metadata.

### 1.1 Key Capabilities

- **Grid-based inventory browsing** with responsive 2-column layout
- **Search and filtering** across all item attributes
- **Multi-select mode** for bulk operations (delete)
- **Detailed item view** with parallax hero image and metadata display
- **Rescan-driven edit flow** for data correction
- **Real-time updates** via Firestore listeners

### 1.2 Module Location

```
Sources/InventoryFeature/
  InventoryFeature.swift       # Module declaration
  InventoryView.swift          # Main list view
  InventoryViewModel.swift     # List view state management
  ItemCard.swift               # Grid item component
  ItemDetailView.swift         # Full item detail view
  EmptyStateCard.swift         # Empty inventory state
  Components/
    SearchBar.swift            # Search input component
    FloatingTabBar.swift       # Tab navigation component
  EditFlow/
    EditItemViewModel.swift    # Edit flow state machine
    EditItemSheet.swift        # Manual field editor
    RescanPromptSheet.swift    # Rescan prompt bottom sheet
    RescanCameraView.swift     # Full-screen camera for rescan
    RescanComparisonSheet.swift # Before/after comparison
```

---

## 2. View Hierarchy

```
InventoryView (NavigationStack)
  |
  +-- SearchBar (when items exist)
  |
  +-- Content Area:
  |     +-- ProgressView (loading state)
  |     +-- ErrorView (error state)
  |     +-- EmptyInventoryView (empty state)
  |     +-- ContentUnavailableView (no search results)
  |     +-- ItemGridView (main content)
  |           +-- LazyVGrid (2 columns)
  |                 +-- ItemCard[] -> NavigationLink -> ItemDetailView
  |
  +-- Selection Toolbar (when in multi-select mode)
```

### 2.1 State Flow

```
         [Loading]
             |
    +--------+--------+
    |        |        |
[Error]  [Empty]  [Loaded]
    |        |        |
    +--------+--------+
             |
    [Displaying Items]
             |
    +--------+--------+
    |                 |
[Search]      [Selection Mode]
    |                 |
[Filtered]     [Bulk Actions]
```

---

## 3. Item Card Component

**File:** `Sources/InventoryFeature/ItemCard.swift`

The ItemCard is a reusable component that displays item thumbnails in the inventory grid.

### 3.1 Component Structure

```
+----------------------------------+
|  +----------------------------+  |
|  |                            |  |  <- Thumbnail Image (AsyncImage)
|  |     [Item Photo]           |  |     Height: 160px (120px at xxxLarge)
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  Item Name                       |  <- Primary text (semibold)
|  Brand - Color                   |  <- Secondary text
|                                  |
|  [Condition] ______ [Status]     |  <- Badges row
|                                  |
+----------------------------------+
```

### 3.2 Displayed Data

| Field | Source | Fallback |
|-------|--------|----------|
| Image | `item.imageUrl` | Placeholder with photo icon |
| Name | `item.name` | `item.category` or "Unknown Item" |
| Brand | `item.brand` | (hidden if nil) |
| Color | `item.color` | (hidden if nil) |
| Condition | `item.condition` | (hidden if nil) |
| Status | `item.status` | Always shown |

### 3.3 Status Badge

The StatusBadge component displays the processing state of each item:

| Status | Display Text | Color |
|--------|--------------|-------|
| `pending` | "Processing" | Blue |
| `layer2aComplete` | "Analyzed" | Green |
| `complete` | "Complete" | Green |
| `failed` / `failedLayer2a` / `failedLayer2b` | "Failed" | Red |
| Other | Raw value | Gray |

### 3.4 Condition Badge

The ConditionBadge shows the physical condition assessment:

| Condition | Display | Color |
|-----------|---------|-------|
| `new` | "New" | Green |
| `likeNew` | "Like New" | Green |
| `good` | "Good" | Blue |
| `fair` | "Fair" | Orange |
| `poor` | "Poor" | Red |

### 3.5 Selection Mode

In multi-select mode, cards display a selection indicator:
- Unselected: White circle with 80% opacity
- Selected: Accent color circle with white checkmark
- Selected cards have an accent-colored border stroke

### 3.6 Interactions

- **Tap (normal mode):** Navigate to ItemDetailView
- **Tap (selection mode):** Toggle selection state
- **Long press / Context menu:** Edit or Delete actions
- **Press animation:** 0.98 scale effect (respects Reduce Motion)

---

## 4. Item Detail View

**File:** `Sources/InventoryFeature/ItemDetailView.swift`

Full-screen detail view with hero image and expanded metadata.

### 4.1 Layout Structure

```
+----------------------------------+
|                                  |
|         [Hero Image]             |  <- 50% of screen height
|         (Parallax scroll)        |     Parallax effect on scroll
|                                  |
+----------------------------------+
     |
     | -60pt overlap
     v
+----------------------------------+
|  Item Name              [Edit]   |  <- Header with edit button
|  Brand Model                     |
|                                  |
|  [Category] [Sub-category]       |  <- Category badges
|                                  |
|  --------------------------------|
|                                  |
|  Est. Value:           $XX.XX    |  <- If available
|                                  |
|  +----------+ +----------+       |
|  | Color    | | Material |       |  <- Metadata grid (2 columns)
|  +----------+ +----------+       |
|  | Condition| | Dimensions|      |
|  +----------+ +----------+       |
|  | Quantity |            |       |
|  +----------+            |       |
|                                  |
|  --------------------------------|
|                                  |
|  [icon] AI Confidence    High    |  <- Confidence row
|                                  |
|  AI Notes                        |  <- If processingNotes exists
|  Processing notes text...        |
|                                  |
+----------------------------------+
```

### 4.2 Catalog Fields Displayed

| Field | Type | Display |
|-------|------|---------|
| `name` | String? | Title (fallback: "Unnamed Item") |
| `brand` | String? | Subheadline |
| `model` | String? | Tertiary text |
| `category` | String? | Orange capsule badge |
| `subCategory` | String? | Blue capsule badge |
| `color` | String? | Metadata grid cell |
| `material` | String? | Metadata grid cell |
| `condition` | ItemCondition? | Metadata grid cell (display name) |
| `dimensions` | String? | Metadata grid cell |
| `quantity` | Int? | Metadata grid cell |
| `estimatedValue` | Double? | Currency format ($XX.XX) |
| `confidence` | ItemConfidence? | Row with icon + color |
| `processingNotes` | String? | AI notes section |

### 4.3 Confidence Indicator

| Level | Icon | Color |
|-------|------|-------|
| `high` | checkmark.circle.fill | Green |
| `medium` | exclamationmark.triangle.fill | Orange |
| `low` | questionmark.circle.fill | Red |

### 4.4 Visual Effects

- **Parallax scrolling:** Hero image offset = scrollOffset * 0.5 (respects Reduce Motion)
- **Liquid Glass:** Metadata card uses `adaptiveGlass` modifier
- **Card overlap:** -60pt offset to overlap hero image
- **Shadow:** Black 15% opacity, 16pt radius, -8pt y-offset

---

## 5. Edit Flow

The edit flow is designed around a "rescan-first" approach where users must capture a new photo before making manual edits. This ensures AI can attempt to correct the data before falling back to manual entry.

### 5.1 State Machine

**File:** `Sources/InventoryFeature/EditFlow/EditItemViewModel.swift`

```swift
public enum EditFlowState: Equatable {
    case idle              // No edit in progress
    case promptingRescan   // Showing rescan prompt sheet
    case capturing         // Camera view active
    case processing        // Analyzing captured image
    case comparing(newItem: Item)  // Showing before/after comparison
    case editing           // Manual edit form open
    case saving            // Saving changes
    case error(String)     // Error state with message
}
```

### 5.2 Flow Diagram

```
[Detail View]
     |
     | tap Edit button
     v
+------------------+
| Rescan Prompt    |  <- "Edit Requires New Photo"
| Sheet            |     Take Photo / Cancel
+------------------+
     |
     | Take Photo
     v
+------------------+
| Rescan Camera    |  <- Full-screen camera
| View             |     Capture button
+------------------+
     |
     | Capture
     v
+------------------+
| Processing       |  <- "Analyzing your photo..."
| Overlay          |     Progress indicator
+------------------+
     |
     | AI complete
     v
+------------------+
| Comparison       |  <- Before/After cards
| Sheet            |     "Looks Good" / "Still Incorrect?"
+------------------+
     |
     +--- Accept --> [Save & Close]
     |
     | Still Incorrect?
     v
+------------------+
| Edit Item        |  <- Full edit form
| Sheet            |     All editable fields
+------------------+
     |
     | Save
     v
[Detail View]
```

### 5.3 Rescan Prompt Sheet

**File:** `Sources/InventoryFeature/EditFlow/RescanPromptSheet.swift`

- **Presentation:** `.medium` detent
- **Content:** Camera viewfinder icon, explanation text
- **Actions:** "Take New Photo" (primary), "Cancel" (plain)

### 5.4 Rescan Camera View

**File:** `Sources/InventoryFeature/EditFlow/RescanCameraView.swift`

- **Presentation:** Full screen cover (iOS)
- **Features:**
  - Camera preview using AVCaptureSession
  - "Position the item in frame" instruction
  - Capture button (72pt white circle)
  - Processing overlay with progress
- **Photo handling:** Uploads to Firebase Storage, triggers Cloud Function rescan

### 5.5 Comparison Sheet

**File:** `Sources/InventoryFeature/EditFlow/RescanComparisonSheet.swift`

- **Presentation:** `.large` detent
- **Layout:** Side-by-side "Before" and "After" cards
- **Content:**
  - Thumbnail images
  - Key fields (Name, Category, Brand, Value)
  - Changes summary with strikethrough/green highlight
- **Actions:** "Looks Good" (accept), "Still Incorrect?" (unlock manual edit)

### 5.6 Edit Item Sheet

**File:** `Sources/InventoryFeature/EditFlow/EditItemSheet.swift`

- **Presentation:** `.large` detent
- **Form sections:**
  - Basic Information: Name, Brand, Model
  - Categorization: Category, Sub-Category
  - Physical Properties: Color, Material, Dimensions, Condition (picker)
  - Value: Quantity (stepper), Estimated Value (currency input)
  - AI Metadata: Confidence, Processing Notes (read-only)
- **Validation:**
  - Name: max 100 characters
  - Estimated Value: >= 0, warning if > 1,000,000
  - Quantity: >= 1, warning if > 1000
- **Field tracking:** `EditedFieldTracker` records which fields user modified (for AI training)

---

## 6. Status Indicators

### 6.1 ItemStatus Enum

**File:** `Sources/Persistence/Models/Item.swift`

```swift
public enum ItemStatus: String, Codable, Sendable {
    case pending = "pending"           // Waiting for Layer 2a
    case layer2aComplete = "layer2a_complete"  // Layer 2a done
    case layer2bScheduled = "layer2b_scheduled" // Scheduled for Layer 2b
    case layer2bComplete = "layer2b_complete"   // Layer 2b done
    case complete = "complete"         // Fully cataloged
    case failed = "failed"             // General failure
    case failedLayer2a = "failed_layer2a"  // Layer 2a failure
    case failedLayer2b = "failed_layer2b"  // Layer 2b failure
}
```

### 6.2 Status Lifecycle

```
[New Item Created]
      |
      v
  pending -----> layer2a_complete -----> complete
      |               |
      v               v
 failed_layer2a   failed_layer2b
```

### 6.3 UI Display Mapping

| Status | Badge Text | Color | User Meaning |
|--------|------------|-------|--------------|
| pending | "Processing" | Blue | AI analyzing |
| layer2aComplete | "Analyzed" | Green | Initial analysis done |
| layer2bComplete | "Analyzed" | Green | Full analysis done |
| complete | "Complete" | Green | Ready for use |
| failed* | "Failed" | Red | Requires manual review |

---

## 7. Navigation Flow

### 7.1 Primary Navigation

```
InventoryView
     |
     | tap ItemCard (normal mode)
     v
ItemDetailView
     |
     | tap Edit button
     v
[Edit Flow Sheets]
```

### 7.2 Back Navigation

- ItemDetailView: System back button in navigation bar
- Edit sheets: "Cancel" button dismisses sheet
- Edit flow: `viewModel.cancelFlow()` resets all state

### 7.3 Selection Mode Navigation

```
InventoryView
     |
     | tap "Select" button
     v
[Selection Mode]
     |
     +-- tap ItemCard --> toggle selection
     +-- tap "Delete (N)" --> confirmation dialog --> batch delete
     +-- tap "Deselect All" --> clear selections
     +-- tap "Done" --> exit selection mode
```

---

## 8. Data Binding

### 8.1 ViewModel Architecture

**File:** `Sources/InventoryFeature/InventoryViewModel.swift`

```swift
@MainActor
@Observable
public final class InventoryViewModel {
    public var items: [Item] = []
    public var isLoading: Bool = false
    public var error: String?
    public var deleteError: String?

    private let itemRepository: ItemRepository
    private var cancellables: Set<AnyCancellable> = Set()
}
```

### 8.2 Real-time Updates

**Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)

```swift
private func observeItems() {
    guard let userId = userId else { return }

    itemRepository.observeItems(userId: userId)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] items in
            self?.items = items
        }
        .store(in: &cancellables)
}
```

### 8.3 Repository Protocol

```swift
public protocol ItemRepository:
    ItemReadRepository,
    ItemWriteRepository,
    ItemObservableRepository {}

// Observable protocol
public protocol ItemObservableRepository: Sendable {
    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration
    func observeItems(userId: String) -> AnyPublisher<[Item], Never>
}
```

### 8.4 Optimistic Updates

Delete operations use optimistic updates with rollback:

```swift
public func deleteItem(_ item: Item) async {
    // Store for rollback
    let itemIndex = items.firstIndex(where: { $0.id == item.id })

    // Optimistic removal
    items.removeAll { $0.id == item.id }

    do {
        try await itemRepository.deleteItem(id: item.id)
    } catch {
        // Rollback on failure
        if let index = itemIndex, index < items.count {
            items.insert(item, at: index)
        } else {
            items.append(item)
        }
        deleteError = "Failed to delete item: \(error.localizedDescription)"
    }
}
```

---

## 9. Search Functionality

### 9.1 Search Bar Component

**File:** `Sources/InventoryFeature/Components/SearchBar.swift`

- Capsule-shaped input with magnifying glass icon
- Clear button appears when text is present
- Uses Liquid Glass styling (`adaptiveGlass`)

### 9.2 Search Algorithm

**File:** `Sources/Persistence/Models/Item+Search.swift` (inferred)

Searches across multiple fields with case-insensitive, locale-aware matching:
- category
- color
- material
- condition
- name
- subCategory
- brand
- model

```swift
private var filteredItems: [Item] {
    guard !searchText.isEmpty else {
        return viewModel.items
    }
    return viewModel.items.filter { item in
        item.matchesSearchQuery(searchText)
    }
}
```

---

## 10. Empty States

### 10.1 Empty Inventory

**Component:** `EmptyStateCard`

```
+----------------------------------+
|            [tray icon]           |
|                                  |
|         No Items Yet             |
|                                  |
|  Capture items with the camera   |
|       to get started             |
|                                  |
|        [Open Camera]             |
+----------------------------------+
```

### 10.2 No Search Results

Uses system `ContentUnavailableView.search(text:)` component.

### 10.3 Error State

```
+----------------------------------+
|     [warning triangle icon]      |
|                                  |
|     Error Loading Items          |
|                                  |
|     Error message text           |
|                                  |
|           [Retry]                |
+----------------------------------+
```

---

## 11. Accessibility

### 11.1 ItemCard Accessibility

- Combined accessibility element
- Label includes: name/category, brand, color, condition, status, selection state
- Button trait
- Context menu for edit/delete actions

### 11.2 Dynamic Type Support

- Image height adjusts: 160px normal, 120px at xxxLarge
- Text uses semantic font styles (.body, .footnote, .caption)

### 11.3 Motion Preferences

- Animations respect `accessibilityReduceMotion`
- Parallax effect disabled when reduce motion is on

### 11.4 Color Contrast

- Status badges use color + text for redundant indication
- Condition badges use semantic colors (green/blue/orange/red)

---

## 12. Design System Integration

### 12.1 Liquid Glass

All cards and sheets use `adaptiveGlass` modifier which:
- Uses `.glassEffect()` on iOS 26+ when reduce transparency is off
- Falls back to `.thickMaterial` on older systems
- Respects `accessibilityReduceTransparency`

### 12.2 Brand Animations

- `.brandSnappy` for press/selection animations
- `.brandDefault` for tab selection transitions

### 12.3 Brand Colors

- `Color.accentPrimary` for primary actions
- `Color.successColor` for save confirmation
- Semantic system colors for status indicators

---

## 13. Error Handling

### 13.1 Edit Flow Errors

```swift
public enum EditFlowError: LocalizedError {
    case missingUserId           // "User authentication required"
    case rescanProcessingFailed  // "Failed to analyze the new photo"
    case rescanTimeout           // "Photo analysis timed out"
    case validationFailed        // "Please fix validation errors"
}
```

### 13.2 Delete Errors

- Single item: Alert with error message
- Bulk delete: Alert with count and error message
- Both support rollback of optimistic updates

### 13.3 Load Errors

- Displayed in ErrorView with retry button
- Error message from `error.localizedDescription`

---

## 14. Not Implemented / Planned Features

The following features are referenced in code comments but not yet fully implemented:

| Feature | Status | Notes |
|---------|--------|-------|
| Edit from context menu | TODO | Comment: "Stage 3.3 - wire to rescan edit flow" |
| Layer 2b status display | Partial | Status exists but UI doesn't distinguish from Layer 2a |
| Batch edit | Not Implemented | Only batch delete is available |
| Sort options | Not Implemented | Items sorted by createdAt (descending) only |
| Filter by status | Not Implemented | Search doesn't filter by processing status |
| Category filter chips | Not Implemented | Only text search available |
| Image gallery | Not Implemented | Detail view shows single image only |
| Undo delete | Not Implemented | Confirmation dialog only, no post-delete undo |

---

## 15. Related Specifications

- **SPEC-ARCH-002:** Layer1-Layer2 Pipeline (status transitions)
- **SPEC-DATA-001:** Firestore Schema (Item document structure)
- **SPEC-DATA-002:** Storage Architecture (image URLs)
- **SPEC-PIPE-002:** Layer2 Cataloging (AI field extraction)
- **DESIGN-031:** SwiftUI Component Library (ItemCard, EmptyStateCard)
- **DESIGN-037:** Persistence Patterns (Repository Protocol, Real-Time Listeners)
