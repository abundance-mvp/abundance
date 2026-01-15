# Catalog Sharing Feature Design

**Date:** 2026-01-14
**Status:** Approved
**Author:** Claude + W (brainstorming session)

## Overview

Enable users to share their household catalogs with family, friends, neighbors, and roommates. Supports the core Abundance goal: making it easy to find, share, or sell 2nd-hand goods by creating a more efficient discovery network.

## Features

### 1. Family & Friends Sharing (Core Feature)

Share catalog items with people you know based on relationship type:
- **Partner/Spouse:** Share entire household inventory
- **Family:** Apparel, electronics, books (hand-me-downs)
- **Roommate:** Kitchen, living room, bathroom (common areas)
- **Neighbor:** Home & garden, tools, outdoor (borrowing)
- **Friend:** Electronics, sports, entertainment
- **Coworker:** Books, electronics (professional items)

### 2. Insurance PDF Export (Separate Feature)

Export catalog to PDF for insurance claims:
- Table format with thumbnails
- Item details, dimensions, estimated values
- Share via iOS share sheet

---

## Design Decisions

| Topic | Decision |
|-------|----------|
| Mental model | Merged catalog with Mine/Shared/All toggle |
| Permissions | View-only (messaging post-MVP) |
| Data model | Reference-based with explicit `sharedItemIds` |
| New items | NOT auto-shared (manual opt-in) |
| Invitation | Phone/email invite |
| Privacy | Hide value, GPS, timestamps from shared view |
| UI | Liquid Glass segmented control |

---

## Data Model

### Firestore Collections

**`/shares/{shareId}`** - Sharing relationships

```typescript
interface Share {
  id: string;
  ownerId: string;
  sharedWithId: string;
  sharedWithEmail: string | null;
  relationship: ShareRelationship;
  sharedCategories: string[];    // For UI grouping
  sharedItemIds: string[];       // Explicit list of shared items
  status: "pending" | "active" | "revoked";
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

type ShareRelationship =
  | "partner"
  | "family"
  | "roommate"
  | "neighbor"
  | "friend"
  | "coworker";
```

**`/shareInvites/{inviteId}`** - Pending invitations

```typescript
interface ShareInvite {
  id: string;
  ownerId: string;
  recipientEmail?: string;
  recipientPhone?: string;
  relationship: ShareRelationship;
  sharedCategories: string[];
  sharedItemIds: string[];
  status: "pending" | "accepted" | "expired";
  expiresAt: Timestamp;
  createdAt: Timestamp;
}
```

### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /shares/{shareId} {
      // Both owner and recipient can read
      allow read: if request.auth.uid == resource.data.ownerId
                  || request.auth.uid == resource.data.sharedWithId;
      // Only owner can create/modify
      allow create: if request.auth.uid == request.resource.data.ownerId;
      allow update, delete: if request.auth.uid == resource.data.ownerId;
    }

    match /shareInvites/{inviteId} {
      allow read: if request.auth.uid == resource.data.ownerId;
      allow create: if request.auth.uid == request.resource.data.ownerId;
      allow update: if request.auth.uid == resource.data.ownerId;
    }

    // Items can be read by owner OR by users with active share
    match /items/{itemId} {
      allow read: if request.auth.uid == resource.data.userId
                  || itemIsSharedWithUser(resource.data.id, request.auth.uid);
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## iOS Models

### Share Model

```swift
// Sources/Persistence/Models/Share.swift

public struct Share: Identifiable, Codable, Sendable {
    public let id: String
    public let ownerId: String
    public let sharedWithId: String
    public let sharedWithEmail: String?
    public let relationship: ShareRelationship
    public var sharedCategories: [String]
    public var sharedItemIds: Set<String>
    public var status: ShareStatus
    public let createdAt: Date
    public var updatedAt: Date

    // Computed property for display
    public var recipientName: String?  // Populated from user lookup
}

public enum ShareRelationship: String, Codable, Sendable, CaseIterable {
    case partner
    case family
    case roommate
    case neighbor
    case friend
    case coworker

    public var displayName: String {
        switch self {
        case .partner: return "Partner/Spouse"
        case .family: return "Family Member"
        case .roommate: return "Roommate"
        case .neighbor: return "Neighbor"
        case .friend: return "Friend"
        case .coworker: return "Coworker"
        }
    }

    public var suggestedCategories: [String] {
        switch self {
        case .partner: return []  // All categories
        case .family: return ["Apparel", "Electronics", "Books"]
        case .roommate: return ["Kitchen", "Living Room", "Bathroom"]
        case .neighbor: return ["Home & Garden", "Tools", "Outdoor"]
        case .friend: return ["Electronics", "Sports", "Entertainment"]
        case .coworker: return ["Books", "Electronics"]
        }
    }

    public var suggestsAllCategories: Bool {
        self == .partner
    }
}

public enum ShareStatus: String, Codable, Sendable {
    case pending
    case active
    case revoked
}
```

### Privacy Extension

```swift
// Sources/Persistence/Models/Item+Privacy.swift

extension Item {
    /// Returns item with sensitive fields redacted for shared view
    public func redactedForSharing() -> Item {
        var redacted = self
        redacted.estimatedValue = nil
        redacted.photoMetadata = redacted.photoMetadata?.redactedForSharing()
        return redacted
    }
}

extension PhotoMetadata {
    public func redactedForSharing() -> PhotoMetadata {
        var redacted = self
        redacted.latitude = nil
        redacted.longitude = nil
        redacted.captureTimestamp = nil
        return redacted
    }
}
```

---

## User Flows

### Create Share Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SHARE WITH SOMEONE                           │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Enter email or phone number                              │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  sarah@email.com                              ✓     │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  How do you know Sarah?                                         │
│                                                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                        │
│  │ Partner  │ │  Family  │ │ Roommate │                        │
│  └──────────┘ └──────────┘ └──────────┘                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                        │
│  │ Neighbor │ │  Friend  │ │ Coworker │                        │
│  └──────────┘ └──────────┘ └──────────┘                        │
│                                                                 │
│                              [Next →]                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 SUGGESTED ITEMS TO SHARE                        │
│                                                                 │
│  Based on your relationship, we suggest sharing:                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ☑ Home & Garden                           47 items  ▼  │   │
│  │    ☑ Lawn Mower                                        │   │
│  │    ☑ Garden Hose                                       │   │
│  │    ☐ Outdoor Furniture Set    ← User deselected        │   │
│  │    ☑ Pressure Washer                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ☑ Tools                                   12 items  ▼  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│                     [Share with Sarah]                          │
└─────────────────────────────────────────────────────────────────┘
```

### Manage Share Flow

```
┌─────────────────────────────────────────────────────────────────┐
│              SHARING WITH SARAH (NEIGHBOR)                      │
│                                                                 │
│  Relationship: Neighbor                                         │
│  Sharing since: Jan 10, 2026                                    │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  SHARED ITEMS                                                   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Home & Garden                              52 items     │   │
│  │ ├─ ☑ Lawn Mower                                        │   │
│  │ ├─ ☐ Leaf Blower (new)              ← Not shared yet   │   │
│  │ ├─ ☑ Garden Hose                                       │   │
│  │ └─ ☑ Pressure Washer                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Tools                                      14 items     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  [Add Items]                 [Stop Sharing with Sarah]          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## UI Components

### Catalog Filter Control

```swift
// Sources/InventoryFeature/Components/CatalogFilterControl.swift

public enum CatalogFilter: String, CaseIterable {
    case mine = "Mine"
    case shared = "Shared"
    case all = "All"
}

struct CatalogFilterControl: View {
    @Binding var selection: CatalogFilter

    var body: some View {
        Picker("Filter", selection: $selection) {
            ForEach(CatalogFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .glassEffect()  // Liquid Glass styling
    }
}
```

### Shared Item Badge

```swift
// In ItemCard.swift

if let owner = sharedFrom {
    HStack {
        Image(systemName: "person.2.fill")
            .font(.caption2)
        Text("From \(owner)")
            .font(.caption2)
    }
    .foregroundStyle(.secondary)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(.ultraThinMaterial)
    .clipShape(Capsule())
}
```

---

## Service Layer

### ShareService

```swift
// Sources/Persistence/Firebase/ShareService.swift

public protocol ShareServiceProtocol: Sendable {
    func createShare(_ share: Share) async throws
    func getSharesOwned(by userId: String) async throws -> [Share]
    func getSharesSharedWith(userId: String) async throws -> [Share]
    func updateShare(_ share: Share) async throws
    func revokeShare(id: String) async throws
    func addItemsToShare(shareId: String, itemIds: [String]) async throws
    func removeItemsFromShare(shareId: String, itemIds: [String]) async throws
    func acceptInvite(inviteId: String, userId: String) async throws
    func observeShares(for userId: String) -> AnyPublisher<[Share], Never>
}

public final class ShareService: ShareServiceProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    public func getSharedItems(for userId: String) async throws -> [Item] {
        // 1. Get all active shares where user is recipient
        let shares = try await getSharesSharedWith(userId: userId)

        // 2. For each share, fetch explicitly shared items
        var sharedItems: [Item] = []

        for share in shares where share.status == .active {
            let items = try await fetchItemsForShare(share)
            let redactedItems = items.map { $0.redactedForSharing() }
            sharedItems.append(contentsOf: redactedItems)
        }

        return sharedItems
    }

    private func fetchItemsForShare(_ share: Share) async throws -> [Item] {
        guard !share.sharedItemIds.isEmpty else { return [] }

        // Firestore 'in' query limited to 30 items, chunk if needed
        let chunks = Array(share.sharedItemIds).chunked(into: 30)
        var items: [Item] = []

        for chunk in chunks {
            let snapshot = try await db.collection("items")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            items.append(contentsOf: snapshot.documents
                .compactMap { try? $0.data(as: Item.self) })
        }

        return items
    }
}
```

---

## Implementation Stages

### Stage 4.1: Data Model & Service Layer (~1.5 days)

**Tasks:**
- [ ] Create `Share.swift` model
- [ ] Create `ShareInvite.swift` model
- [ ] Create `ShareService.swift` with CRUD operations
- [ ] Add `Item+Privacy.swift` extension
- [ ] Update Firestore security rules
- [ ] Write unit tests

**Files:**
- `Sources/Persistence/Models/Share.swift` (new)
- `Sources/Persistence/Models/ShareInvite.swift` (new)
- `Sources/Persistence/Models/Item+Privacy.swift` (new)
- `Sources/Persistence/Firebase/ShareService.swift` (new)
- `firestore.rules`

### Stage 4.2: Invitation Flow (~1 day)

**Tasks:**
- [ ] Create `CreateShareView.swift`
- [ ] Create `SelectRelationshipView.swift`
- [ ] Create `SelectItemsToShareView.swift`
- [ ] Implement email/SMS invite
- [ ] Handle invite acceptance

**Files:**
- `Sources/SharingFeature/Views/CreateShareView.swift` (new)
- `Sources/SharingFeature/Views/SelectRelationshipView.swift` (new)
- `Sources/SharingFeature/Views/SelectItemsToShareView.swift` (new)
- `Sources/SharingFeature/ViewModels/CreateShareViewModel.swift` (new)

### Stage 4.3: Catalog UI Integration (~1.5 days)

**Tasks:**
- [ ] Create `CatalogFilterControl.swift`
- [ ] Update `InventoryViewModel` with sharing support
- [ ] Update `InventoryView` with filter toggle
- [ ] Update `ItemCard` with shared badge
- [ ] Update `ItemDetailView` with sharing section

**Files:**
- `Sources/InventoryFeature/Components/CatalogFilterControl.swift` (new)
- `Sources/InventoryFeature/InventoryViewModel.swift`
- `Sources/InventoryFeature/InventoryView.swift`
- `Sources/InventoryFeature/ItemCard.swift`
- `Sources/InventoryFeature/ItemDetailView.swift`

### Stage 4.4: Share Management (~1 day)

**Tasks:**
- [ ] Create `ManageSharesView.swift`
- [ ] Create `EditShareView.swift`
- [ ] Create `SharesViewModel.swift`
- [ ] Add "Share new item?" suggestion
- [ ] Add quick actions in ItemDetailView

**Files:**
- `Sources/SharingFeature/Views/ManageSharesView.swift` (new)
- `Sources/SharingFeature/Views/EditShareView.swift` (new)
- `Sources/SharingFeature/ViewModels/SharesViewModel.swift` (new)

### Stage 4.5: Insurance PDF Export (~0.5 day)

**Tasks:**
- [ ] Create `ExportService.swift`
- [ ] Create `ExportOptionsView.swift`
- [ ] Generate PDF with thumbnails and details
- [ ] Share via iOS share sheet

**Files:**
- `Sources/ExportFeature/Services/ExportService.swift` (new)
- `Sources/ExportFeature/Views/ExportOptionsView.swift` (new)

---

## Cost Impact

| Component | Additional Cost |
|-----------|-----------------|
| Firestore reads (shared items) | ~$5-10/month |
| SMS invites (Firebase Auth) | ~$5/month |
| PDF generation | Negligible (on-device) |
| **Total** | **~$10-15/month** |

---

## Out of Scope (Post-MVP)

- Messaging/request system for borrowing
- Tiered permissions (View+Edit)
- Nearby discovery (Bluetooth)
- Share links for strangers
- Borrow history tracking
- Contacts integration for finding friends

---

## Success Criteria

- [ ] User can invite someone via email/phone
- [ ] Relationship selection suggests appropriate categories
- [ ] Initial share populates with selected items
- [ ] New items are NOT auto-shared (manual opt-in)
- [ ] Shared items appear in recipient's catalog with "From [Owner]" badge
- [ ] Mine/Shared/All toggle filters correctly
- [ ] Sensitive fields (value, GPS) are hidden from shared view
- [ ] User can add/remove items from existing share
- [ ] User can revoke share entirely
- [ ] PDF export includes all item details with thumbnails

---

## References

- Stage 3.0 Design: `docs/plans/2026-01-14-stage-3.0-mvp-features-design.md`
- Apple CloudKit CKShare: Reference for sharing patterns
- Apple HIG: Collaboration and Sharing guidelines

---

**Approved:** 2026-01-14
