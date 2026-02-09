# SPEC-UI-002: Collection Flow

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## 1. Overview

The Collection Flow provides users with a comprehensive interface to browse, view, and edit their cataloged household items. This feature is the primary destination for users after capturing items through the camera, displaying all processed items with their AI-extracted metadata.

### 1.1 Key Capabilities

- **Grid-based collection browsing** with responsive 2-column layout
- **Search and filtering** across all item attributes
- **Multi-select mode** for bulk operations (delete)
- **Detailed item view** with parallax hero image and metadata display
- **Rescan-driven edit flow** for data correction
- **Real-time updates** via Firestore listeners

### 1.2 Module Location

```
Sources/CollectionFeature/
  CollectionFeature.swift       # Module declaration
  CollectionView.swift          # Main list view
  CollectionViewModel.swift     # List view state management
  ItemCard.swift               # Grid item component
  ItemDetailView.swift         # Full item detail view
  EmptyStateCard.swift         # Empty collection state
  Components/
    SearchBar.swift            # Search input component
    FloatingTabBar.swift       # Tab navigation component
    PhotoCarouselView.swift    # Multi-photo horizontal carousel
  EditFlow/
    EditItemViewModel.swift    # Edit flow state machine
    EditItemSheet.swift        # Manual field editor
    RescanPromptSheet.swift    # Rescan prompt bottom sheet
    RescanCameraView.swift     # Full-screen camera for rescan
    RescanComparisonSheet.swift # Before/after comparison
    AddPhotoCameraView.swift   # Camera for adding additional photos
```

---

## 2. View Hierarchy

```
CollectionView (NavigationStack)
  |
  +-- SearchBar (when items exist)
  |
  +-- Content Area:
  |     +-- ProgressView (loading state)
  |     +-- ErrorView (error state)
  |     +-- EmptyCollectionView (empty state)
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

**File:** `Sources/CollectionFeature/ItemCard.swift`

The ItemCard is a reusable component that displays item thumbnails in the collection grid.

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

The StatusBadge component displays the processing state of each item using brand colors:

| Status | Display Text | Badge Color |
|--------|--------------|-------------|
| `processing` | "Processing" | Peach (`.peach`) |
| `complete` | "Complete" | MutedSage (`.mutedSage`) |
| `failed` | "Failed" | Salmon (`.salmon`) |

### 3.4 Condition Badge

The ConditionBadge shows the physical condition assessment using brand colors:

| Condition | Display | Badge Color |
|-----------|---------|-------------|
| `new` | "New" | MutedSage (`.mutedSage`) |
| `likeNew` | "Like New" | MutedSage (`.mutedSage`) |
| `good` | "Good" | SoftTeal (`.softTeal`) |
| `fair` | "Fair" | Peach (`.peach`) |
| `poor` | "Poor" | Salmon (`.salmon`) |

### 3.5 Selection Mode

In multi-select mode, cards display a selection indicator:
- Unselected: Cream circle with 80% opacity (`.cream.opacity(0.8)`)
- Selected: Accent primary circle (`.accentPrimary`) with warmWhite checkmark
- Selected cards have an accent-colored border stroke (3pt `Color.accentPrimary`)

### 3.6 Interactions

- **Tap (normal mode):** Navigate to ItemDetailView
- **Tap (selection mode):** Toggle selection state
- **Long press / Context menu:** Edit or Delete actions
- **Press animation:** 0.98 scale effect (respects Reduce Motion)

---

## 4. Item Detail View

**File:** `Sources/CollectionFeature/ItemDetailView.swift`

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
| `category` | String? | Peach capsule badge (`.peach`) |
| `subCategory` | String? | SoftTeal capsule badge (`.softTeal`) |
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
| `high` | checkmark.circle.fill | MutedSage (`.mutedSage`) |
| `medium` | exclamationmark.triangle.fill | Peach (`.peach`) |
| `low` | questionmark.circle.fill | Salmon (`.salmon`) |

### 4.4 Visual Effects

- **Parallax scrolling:** Hero image offset = scrollOffset * 0.5 (respects Reduce Motion)
- **Photo carousel:** Multi-photo items use `PhotoCarouselView` instead of single parallax hero
- **Card styling:** Metadata card uses `.abundanceCardStyle(cornerRadius: 24)` (cream background, peach border)
- **Card overlap:** -60pt offset to overlap hero image
- **Shadow:** Black 15% opacity, 16pt radius, -8pt y-offset
- **Refresh button:** Arrow icon with processing state (ProgressView when refreshing)
- **Estimated value:** Displayed in MutedSage (`.mutedSage`) color

---

## 5. Edit Flow

The edit flow is designed around a "rescan-first" approach where users must capture a new photo before making manual edits. This ensures AI can attempt to correct the data before falling back to manual entry.

### 5.1 State Machine

**File:** `Sources/CollectionFeature/EditFlow/EditItemViewModel.swift`

```swift
public enum EditFlowState: Equatable {
    case idle              // No edit in progress
    case promptingRescan   // Showing rescan prompt sheet
    case capturing         // Camera view active
    case processing        // Analyzing captured image
    case comparing(newItem: Item)  // Showing before/after comparison
    case editing           // Manual edit form open
    case saving            // Saving changes
    case addingPhoto       // Add-photo camera active
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

**File:** `Sources/CollectionFeature/EditFlow/RescanPromptSheet.swift`

- **Presentation:** `.medium` detent
- **Content:** Camera viewfinder icon, explanation text
- **Actions:** "Take New Photo" (primary), "Cancel" (plain)

### 5.4 Rescan Camera View

**File:** `Sources/CollectionFeature/EditFlow/RescanCameraView.swift`

- **Presentation:** Full screen cover (iOS)
- **Features:**
  - Camera preview using AVCaptureSession
  - "Position the item in frame" instruction
  - Capture button (72pt white circle)
  - Processing overlay with progress
- **Photo handling:** Uploads to Firebase Storage, triggers Cloud Function rescan

### 5.5 Comparison Sheet

**File:** `Sources/CollectionFeature/EditFlow/RescanComparisonSheet.swift`

- **Presentation:** `.large` detent
- **Layout:** Side-by-side "Before" and "After" cards
- **Content:**
  - Thumbnail images
  - Key fields (Name, Category, Brand, Value)
  - Changes summary with strikethrough/green highlight
- **Actions:** "Looks Good" (accept), "Still Incorrect?" (unlock manual edit)

### 5.6 Edit Item Sheet

**File:** `Sources/CollectionFeature/EditFlow/EditItemSheet.swift`

- **Presentation:** `.large` detent
- **Form sections:**
  - Basic Information: Name, Brand, Model
  - Categorization: Category, Sub-Category
  - Physical Properties: Color, Material, Dimensions, Condition (picker)
  - Value: Quantity (stepper), Estimated Value (currency input)
  - Photos: Horizontal scroll of thumbnails with add/delete (primary photo protected)
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

The status enum has been simplified to 3 states. Legacy Firestore values are mapped on decode:

```swift
public enum ItemStatus: String, Codable, Sendable {
    case processing = "processing"  // AI analyzing (maps from: pending, layer2a_complete, layer2b_scheduled, layer2b_complete)
    case complete = "complete"      // Fully cataloged
    case failed = "failed"          // Failure (maps from: failed, failed_layer2a, failed_layer2b)
}
```

### 6.2 Status Lifecycle

```
[New Item Created]
      |
      v
  processing -----> complete
      |
      v
    failed
```

### 6.3 UI Display Mapping

| Status | Badge Text | Badge Color | User Meaning |
|--------|------------|-------------|--------------|
| processing | "Processing" | Peach (`.peach`) | AI analyzing |
| complete | "Complete" | MutedSage (`.mutedSage`) | Ready for use |
| failed | "Failed" | Salmon (`.salmon`) | Requires manual review |

---

## 7. Navigation Flow

### 7.1 Primary Navigation

```
CollectionView
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
CollectionView
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

**File:** `Sources/CollectionFeature/CollectionViewModel.swift`

```swift
@MainActor
@Observable
public final class CollectionViewModel {
    public var items: [Item] = []
    public var isLoading: Bool = false
    public var error: String?
    public var deleteError: String?
    public var refreshError: String?
    public var searchText: String = ""

    public var filteredItems: [Item] { /* search filter */ }

    private let itemRepository: ItemRepository
    private let userId: String?
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
}
```

### 8.2 Real-time Updates

**Pattern:** DESIGN-037 Pattern 2 (Firestore Real-Time Listener Integration)

```swift
private func observeItems() {
    guard let userId = userId else { return }

    itemRepository.observeItems(userId: userId)
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
    let itemIndex: Int? = items.firstIndex(where: { $0.id == item.id })

    // Optimistic removal
    items.removeAll { $0.id == item.id }
    deleteError = nil

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

**Additional Methods:**

| Method | Purpose |
|--------|---------|
| `deleteItems(ids:)` | Bulk delete with optimistic update and full rollback |
| `refreshItem(_:)` | Re-run AI analysis on existing images |
| `deletePhoto(from:at:)` | Delete additional photo from item (primary photo protected) |

---

## 9. Search Functionality

### 9.1 Search Bar Component

**File:** `Sources/CollectionFeature/Components/SearchBar.swift`

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

### 10.1 Empty Collection

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

### 12.1 Card Styling

Content-layer components use opaque brand fills via `.abundanceCardStyle()` modifier (cream background, peach border), not glass effects. Glass effects (`adaptiveGlass`) are reserved for navigation-layer elements only (search bar, floating tab bar).

The `AbundanceCard` and `AbundanceCardModifier` provide:
- Background: `Color.cream` in `RoundedRectangle(cornerRadius: 16, style: .continuous)`
- Border: `Color.peach` 1px stroke (2px when `colorSchemeContrast == .increased`)

### 12.2 Brand Animations

- `.brandPress` for press/selection animations (0.3s response, 0.6 damping)
- `.brandDefault` for standard transitions (0.5s response, 0.6 damping)
- `.brandReducedMotion` for accessibility fallback (0.2s easeInOut)

### 12.3 Brand Colors

- `Color.accentPrimary` (`.salmon`) for primary actions and selection borders
- `Color.successColor` (`.mutedSage`) for save confirmation button tint
- `Color.errorColor` (`.salmon`) for error text and delete photo buttons
- `Color.deepPlum` for badge text and category badges
- `Color.cream` for card backgrounds
- `Color.peach` for card borders and category badge backgrounds

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
| Batch edit | Not Implemented | Only batch delete is available |
| Sort options | Not Implemented | Items sorted by createdAt (descending) only |
| Filter by status | Not Implemented | Search doesn't filter by processing status |
| Category filter chips | Not Implemented | Only text search available |
| Undo delete | Not Implemented | Confirmation dialog only, no post-delete undo |

---

## 15. Related Specifications

- **SPEC-ARCH-002:** Layer1-Layer2 Pipeline (status transitions)
- **SPEC-DATA-001:** Firestore Schema (Item document structure)
- **SPEC-DATA-002:** Storage Architecture (image URLs)
- **SPEC-PIPE-002:** Layer2 Cataloging (AI field extraction)
- **DESIGN-031:** SwiftUI Component Library (ItemCard, EmptyStateCard)
- **DESIGN-037:** Persistence Patterns (Repository Protocol, Real-Time Listeners)
