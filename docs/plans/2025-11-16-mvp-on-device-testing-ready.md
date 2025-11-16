# MVP On-Device Testing Ready Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a semi-stable iOS app ready for on-device testing with auth flow, camera capture with Vision detection, catalog view with real-time Firestore sync, and tab bar navigation.

**Architecture:** SwiftUI-only MVVM (ADR-010), Firebase backend (Firestore + Storage), Vision Framework for on-device object detection, TabView navigation per Apple HIG.

**Tech Stack:** Swift 6.0, SwiftUI, Firebase iOS SDK 11.11.0, AVFoundation, Vision Framework, Combine + async/await.

---

## Task 1: Fix Critical Build Failures

**Goal:** Resolve missing FirebaseAuth dependency causing build errors.

**Files:**
- Modify: `Package.swift:58-64`

**Step 1: Add FirebaseAuth dependency to InventoryFeature**

```swift
.target(
    name: "InventoryFeature",
    dependencies: [
        "Persistence",
        .product(name: "FirebaseAuth", package: "firebase-ios-sdk")  // ← Add this
    ],
    swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
    ]
),
```

**Step 2: Verify build**

Run: `swift build`
Expected: Build succeeds without "missing required modules" errors

**Step 3: Run tests**

Run: `swift test`
Expected: Tests compile (may still have failures, but no compile errors)

**Step 4: Commit**

```bash
git add Package.swift
git commit -m "fix: add FirebaseAuth dependency to InventoryFeature

Resolves build failure from missing FirebaseAuthInternal module.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Implement Auth-to-Main Navigation Flow

**Goal:** Create root view that switches between SignInView (unauthenticated) and MainTabView (authenticated).

**Files:**
- Modify: `App/AbundanceApp.swift:1-17`
- Read: `Sources/OnboardingFeature/AuthViewModel.swift` (for understanding auth state)

**Step 1: Update AbundanceApp with auth state check**

```swift
import SwiftUI
@preconcurrency import FirebaseCore
import FirebaseAuth
import OnboardingFeature

@main
struct AbundanceApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView(viewModel: authViewModel)
                }
            }
            .onAppear {
                // Check if user is already signed in
                authViewModel.checkAuthStatus()
            }
        }
    }
}
```

**Step 2: Add checkAuthStatus() to AuthViewModel**

File: `Sources/OnboardingFeature/AuthViewModel.swift`

Add method to existing AuthViewModel:

```swift
func checkAuthStatus() {
    if Auth.auth().currentUser != nil {
        isAuthenticated = true
    }
}
```

**Step 3: Build and verify**

Run: `swift build`
Expected: Compiles successfully

**Step 4: Commit**

```bash
git add App/AbundanceApp.swift Sources/OnboardingFeature/AuthViewModel.swift
git commit -m "feat: implement auth-to-main navigation flow

- AbundanceApp now switches between SignInView and MainTabView based on auth state
- Added checkAuthStatus() to AuthViewModel to detect existing sessions

Follows DESIGN-026-onboarding-flow-ui-specification.md navigation pattern.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Implement MainTabView with Tab Navigation

**Goal:** Create tab bar navigation following Apple HIG and DESIGN-028 spec.

**Files:**
- Modify: `App/MainTabView.swift:1-96`
- Create: `App/CameraTabView.swift` (wrapper for CameraView)

**Step 1: Update MainTabView to use SwiftUI TabView**

```swift
import SwiftUI
import InventoryFeature
import CameraFeature
import OnboardingFeature

public struct MainTabView: View {
    @State private var selectedTab: Tab = .catalog

    enum Tab {
        case catalog
        case camera
        case profile
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Catalog", systemImage: "square.grid.2x2.fill", value: Tab.catalog) {
                InventoryView()
            }

            Tab("Camera", systemImage: "camera.fill", value: Tab.camera) {
                CameraTabView()
            }

            Tab("Profile", systemImage: "person.fill", value: Tab.profile) {
                ProfilePlaceholderView()
            }
        }
        .tabViewStyle(.automatic)
    }
}

// MARK: - Placeholder Views

private struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                Text("Profile")
                    .font(.title)
                Text("User profile and settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Profile")
        }
    }
}
```

**Step 2: Create CameraTabView wrapper**

File: `App/CameraTabView.swift`

```swift
import SwiftUI
import CameraFeature

struct CameraTabView: View {
    var body: some View {
        NavigationStack {
            CameraView(cameraService: CameraService())
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

**Step 3: Build and verify**

Run: `swift build`
Expected: TabView compiles with 3 tabs

**Step 4: Commit**

```bash
git add App/MainTabView.swift App/CameraTabView.swift
git commit -m "feat: implement TabView navigation per Apple HIG

- Replaced FloatingTabBar with native SwiftUI TabView
- Added CameraTabView wrapper for CameraView integration
- 3 tabs: Catalog, Camera, Profile

Follows https://developer.apple.com/design/human-interface-guidelines/tab-bars
and DESIGN-028-catalog-view-specification.md.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Verify Camera-to-Firestore Integration (Already Implemented)

**Goal:** Confirm existing Camera → Firebase Storage → Firestore flow works.

**Status:** ✅ **ALREADY IMPLEMENTED**

**Existing Implementation:**
- `CameraViewModel.capturePhoto()` uploads to Storage (line 107-111)
- Returns download URL for Firestore item creation
- **Note:** Code is deprecated in favor of `CameraDetectionViewModel` for real-time detection

**Verification Steps:**

**Step 1: Check CameraDetectionViewModel exists**

Run: `ls Sources/CameraFeature/ViewModels/`
Expected: See `CameraDetectionViewModel.swift` (real-time detection)

**Step 2: Verify it creates Firestore items**

Read: `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift`
Expected: Contains Firebase item creation logic

**Step 3: Skip to next task if verified**

If CameraDetectionViewModel exists and creates items → Skip this task ✅
If missing → Implement item creation in CameraDetectionViewModel

---

## Task 5: Fix Resource Handling for VisionCore Tests

**Goal:** Resolve "Found unhandled resource" error in VisionCoreTests.

**Files:**
- Modify: `Package.swift:94-100`

**Step 1: Update VisionCoreTests target resources**

```swift
.testTarget(
    name: "VisionCoreTests",
    dependencies: ["VisionCore"],
    resources: [
        .copy("Resources")  // ← Change from .process to .copy
    ]
),
```

**Step 2: Verify tests build**

Run: `swift test --filter VisionCoreTests`
Expected: No resource handling errors

**Step 3: Commit**

```bash
git add Package.swift
git commit -m "fix: change VisionCoreTests resources from process to copy

Resolves 'Found unhandled resource' error by using .copy instead of .process.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: Verify Real-Time Firestore Sync (Already Implemented)

**Goal:** Confirm InventoryViewModel has real-time Firestore listener.

**Status:** ✅ **ALREADY IMPLEMENTED**

**Existing Implementation:**
- `InventoryViewModel.observeItems()` (line 46-52) implements real-time listener
- Uses Combine to stream Firestore updates
- Follows DESIGN-037 Pattern 2 exactly

**Verification:**

**Step 1: Confirm implementation**

File: `Sources/InventoryFeature/InventoryViewModel.swift:46-52`

```swift
private func observeItems() {
    itemRepository.observeItems(userId: userId)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] items in
            self?.items = items
        }
        .store(in: &cancellables)
}
```

✅ Already implemented - **Skip this task**

---

## Task 7: Update DESIGN-029 Item Detail View with Image Example

**Goal:** Update item detail view spec to match provided example image for layout consistency.

**Files:**
- Modify: `docs/design/DESIGN-029-item-detail-view-specification.md:30-73`

**Note:** User provided image #2 showing updated item detail layout. Key changes from image analysis:

1. Hero image takes top 50% (not 40%)
2. Metadata card has rounded corners (24pt radius)
3. AI confidence badge positioned top-right of card (not below name)
4. Estimated value displayed prominently with currency symbol
5. Category shown as pill badge below name

**Step 1: Update Layout section**

Replace lines 30-73 with:

```markdown
## Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│                    [Hero Image - Parallax Scroll]                │
│                       Top 50% of screen                          │
│                    Cropped object photo                          │
│                    Aspect fill, no letterbox                     │
│                                                                   │
│   [< Back]                          [AI Confidence • Top Right]  │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                                                               │ │
│ │          [Glass Metadata Card - .ultraThickMaterial]         │ │
│ │                  Overlaps hero by 60pt                        │ │
│ │                                                               │ │
│ │  "Camping Tent"                          [Edit - Pencil]     │ │
│ │  28pt, SF Pro Rounded Bold                                    │ │
│ │                                                               │ │
│ │  [Camping Gear - Category Pill Badge]                        │ │
│ │  Coral Orange background, 12pt                                │ │
│ │                                                               │ │
│ │  ─────────────────────────────────────────────────────        │ │
│ │                                                               │ │
│ │  Est. Value:  $89                                             │ │
│ │  20pt, Mint Green, SF Pro Rounded Bold                        │ │
│ │                                                               │ │
│ │  Location:    Garage                                          │ │
│ │  Color:       Green                                           │ │
│ │  Material:    Nylon                                           │ │
│ │  Condition:   Good                                            │ │
│ │                                                               │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```
```

**Step 2: Commit**

```bash
git add docs/design/DESIGN-029-item-detail-view-specification.md
git commit -m "docs: update item detail view layout per example image

- Hero image now 50% of screen (was 40%)
- Metadata card overlap increased to 60pt (was 40pt)
- AI confidence badge moved to top-right of hero
- Estimated value prominently displayed with Mint Green
- Category shown as pill badge below name

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 8: Implement Item Detail View with Parallax Hero

**Goal:** Create item detail view following updated DESIGN-029 specification.

**Files:**
- Create: `Sources/InventoryFeature/ItemDetailView.swift`
- Modify: `Sources/InventoryFeature/InventoryView.swift:42-48` (add navigation)

**Step 1: Create ItemDetailView**

File: `Sources/InventoryFeature/ItemDetailView.swift`

```swift
import SwiftUI
import Persistence

public struct ItemDetailView: View {
    let item: Item
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var showEditSheet = false

    public init(item: Item) {
        self.item = item
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image with Parallax
                GeometryReader { geometry in
                    AsyncImage(url: URL(string: item.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.gray.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .offset(y: scrollOffset * 0.5) // Parallax effect
                        case .failure:
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.system(size: 80))
                                        .foregroundStyle(.tertiary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipped()
                }
                .frame(height: UIScreen.main.bounds.height * 0.5)

                // Metadata Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(item.category ?? "Uncategorized")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            showEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 20))
                                .foregroundStyle(.primary)
                        }
                    }

                    // Category Badge
                    Text(item.category ?? "Unknown")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(Color.orange.opacity(0.2))
                        }

                    Divider()

                    // Estimated Value
                    if let value = item.estimatedValue {
                        HStack {
                            Text("Est. Value:")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(value, specifier: "%.2f")")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                        }
                    }

                    // Metadata Rows
                    MetadataRow(label: "Color", value: item.color)
                    MetadataRow(label: "Material", value: item.material)
                    MetadataRow(label: "Condition", value: item.condition)
                }
                .padding(24)
                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: -8)
                .padding(.horizontal, 16)
                .offset(y: -60) // Overlap hero
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            Text("Edit sheet placeholder")
                .presentationDetents([.large])
        }
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String?

    var body: some View {
        if let value = value {
            HStack {
                Text(label)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
    }
}
```

**Step 2: Add navigation to InventoryView**

In `Sources/InventoryFeature/InventoryView.swift`, replace ItemGridView:

```swift
private struct ItemGridView: View {
    let items: [Item]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}
```

**Step 3: Build and verify**

Run: `swift build`
Expected: ItemDetailView compiles with parallax effect

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/ItemDetailView.swift Sources/InventoryFeature/InventoryView.swift
git commit -m "feat: implement item detail view with parallax hero image

- Parallax scrolling hero image (top 50% of screen)
- Glass metadata card with 60pt overlap
- Category badge, estimated value, and metadata rows
- Navigation from catalog grid view
- Edit button placeholder

Implements DESIGN-029-item-detail-view-specification.md.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 9: Verify End-to-End Flow

**Goal:** Test complete user journey from sign-in through capture to catalog sync.

**Manual Testing Steps:**

1. Clean build: `swift build && swift test`
2. Launch app on simulator or device
3. Verify:
   - [ ] App shows SignInView (unauthenticated state)
   - [ ] Sign in with Apple works (requires Apple ID in simulator)
   - [ ] MainTabView appears with 3 tabs
   - [ ] Camera tab opens CameraView
   - [ ] Capture photo triggers Vision detection
   - [ ] Catalog tab shows real-time updated items
   - [ ] Tap item card navigates to detail view
   - [ ] Detail view shows parallax hero image

**Expected Results:**
- All views render without crashes
- Tab navigation works smoothly
- Camera captures and uploads to Firebase
- Catalog updates in real-time
- Item detail view displays metadata correctly

---

## Task 10: Create Build & Deploy Documentation

**Goal:** Document how to build and deploy to iPhone for testing.

**Files:**
- Create: `docs/BUILDING-FOR-DEVICE.md`

**Step 1: Write build documentation**

File: `docs/BUILDING-FOR-DEVICE.md`

```markdown
# Building for iOS Device Testing

## Prerequisites

- Xcode 26.0+ (required for Swift 6.0)
- Apple Developer account (free tier sufficient for device testing)
- iPhone with iOS 18+ installed
- Firebase project configured (GoogleService-Info.plist in App/)

## Build Steps

### 1. Open Project in Xcode

```bash
open Package.swift
```

### 2. Select Device Target

- In Xcode toolbar, click target selector (next to Run button)
- Select your connected iPhone from device list
- If device not listed, connect via USB and trust computer

### 3. Configure Signing

- Select "AbundanceApp" target in project navigator
- Go to "Signing & Capabilities" tab
- Select your Team from dropdown
- Xcode will automatically create provisioning profile

### 4. Build and Run

Click Run button (⌘R) or:

```bash
xcodebuild -scheme AbundanceApp -destination 'platform=iOS,name=YOUR_DEVICE_NAME'
```

### 5. Trust Developer on Device

First time running:
- iPhone will show "Untrusted Developer" alert
- Go to Settings → General → VPN & Device Management
- Trust your Apple ID
- Return to app and launch

## Troubleshooting

### "No signing certificate found"
- Ensure Apple ID added in Xcode Preferences → Accounts
- Download manual provisioning profile from developer.apple.com

### "GoogleService-Info.plist not found"
- Ensure file exists at `App/GoogleService-Info.plist`
- Verify it's included in target membership

### "Camera permission denied"
- First launch requires camera permission
- If denied, go to Settings → Abundance → Camera → Allow

## Testing Checklist

- [ ] Sign in with Apple works
- [ ] Camera captures photos
- [ ] Vision detects objects
- [ ] Items appear in catalog
- [ ] Tab navigation works
- [ ] Item detail view displays

## Firebase Console Verification

Check Firestore for created items:
https://console.firebase.google.com/project/YOUR_PROJECT/firestore

Check Storage for uploaded images:
https://console.firebase.google.com/project/YOUR_PROJECT/storage
```

**Step 2: Commit**

```bash
git add docs/BUILDING-FOR-DEVICE.md
git commit -m "docs: add build and deploy guide for on-device testing

Step-by-step instructions for building to iPhone including:
- Xcode configuration
- Device signing
- Troubleshooting common issues
- Testing checklist

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 11: Final Integration Test & Verification

**Goal:** Run all tests and verify build is ready for on-device deployment.

**Step 1: Run full test suite**

```bash
swift test
```

Expected: All tests pass (or only known failures documented)

**Step 2: Build for device**

```bash
swift build -c release
```

Expected: Release build succeeds

**Step 3: Verify critical paths**

Manual checklist:
- [ ] Clean git status (all changes committed)
- [ ] Package.swift dependencies resolved
- [ ] Firebase configuration present
- [ ] Camera permissions in Info.plist
- [ ] All critical views compile
- [ ] Tab navigation implemented
- [ ] Firestore integration functional

**Step 4: Create final commit**

```bash
git status  # Verify clean working tree
git log --oneline -10  # Review recent commits
```

Expected: All 11 tasks committed, clean working directory

---

## Success Criteria

✅ **Build Status**: `swift build` succeeds without errors
✅ **Auth Flow**: Sign in navigates to MainTabView
✅ **Tab Navigation**: 3 tabs (Catalog, Camera, Profile) functional
✅ **Camera Integration**: Captures photos, detects objects, uploads to Storage
✅ **Firestore Sync**: Items created and synced in real-time to catalog
✅ **Detail View**: Parallax hero, metadata display, navigation working
✅ **On-Device Ready**: Can be deployed to iPhone via Xcode

---

## Known Limitations

This semi-stable build includes:
- ✅ Sprint 1: Auth flow (complete)
- ✅ Sprint 2: Camera capture UI (complete)
- ✅ Sprint 2: Layer 1 Vision detection (complete)
- ✅ Sprint 3: Firestore item creation (complete)
- ✅ Sprint 4: AI Pipeline Layer 2a (Gemini attribute extraction) - **IMPLEMENTED**
- ✅ Sprint 5: AI Pipeline Layer 2b (Barcode lookup + SerpAPI) - **IMPLEMENTED**
- ✅ Sprint 5: AI Pipeline Layer 3 (Claude synthesis) - **IMPLEMENTED**
- ✅ Sprint 6: Catalog view with real-time sync (complete)
- ⚠️ Sprint 7: Full item detail edit mode - **PLACEHOLDER** (view-only)
- ❌ Sprint 8: TestFlight deployment - **NOT CONFIGURED**

**Backend AI Pipeline Status:**
- ✅ `onItemCreated` trigger → Layer 2a (Gemini extraction)
- ✅ `onLayer2aComplete` trigger → Layer 2b (Barcode + SerpAPI)
- ✅ `onLayer2bComplete` trigger → Layer 3 (Claude synthesis)
- ✅ Cost tracking and monitoring
- ✅ Structured logging

**Next Steps After Testing:**
1. Complete item detail edit functionality (save to Firestore)
2. Configure TestFlight distribution
3. Add error handling UI for failed pipeline stages

---

## References

- DESIGN-026-onboarding-flow-ui-specification.md (Auth flow)
- DESIGN-027-camera-capture-view-specification.md (Camera UI/UX)
- DESIGN-028-catalog-view-specification.md (Catalog layout)
- DESIGN-029-item-detail-view-specification.md (Detail view)
- DESIGN-037-ui-mvvm-integration-patterns.md (Architecture patterns)
- Apple HIG: Tab Bars (https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- SwiftUI TabView Documentation (https://developer.apple.com/documentation/swiftui/tabview)

---

**Plan Status**: ✅ **READY FOR EXECUTION**

**Estimated Time**: 3-4 hours (11 tasks, includes testing and verification)
