# Code Review Remediation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use ios-superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all blocking and non-blocking issues identified in the 2026-01-18 code review before merging to main.

**Architecture:** Targeted fixes to existing files - no new modules. Focus on accessibility, memory safety, privacy compliance, and performance.

**Tech Stack:** Swift 6.0, SwiftUI, iOS 17+, Xcode Privacy Manifests

---

## Summary

| Priority | Count | Tasks |
|----------|-------|-------|
| P0 (Blocking) | 4 | Tasks 1-4 |
| P1 (High) | 5 | Tasks 5-9 |
| P2 (Medium) | 3 | Tasks 10-12 |
| **Total** | **12** | |

---

## P0: Blocking Issues (Must Fix Before Merge)

### Task 1: Fix Cancel Button Accessibility in CaptureView

**Files:**

- Modify: `Sources/CameraFeature/Views/CaptureView.swift:244-248`
- Test: Manual VoiceOver verification

**Step 1: Add accessibility label to Cancel button**

Open `Sources/CameraFeature/Views/CaptureView.swift` and modify lines 241-248:

```swift
Button {
    dismiss()
} label: {
    Text("Cancel")
        .font(.system(.body, design: .rounded))
        .foregroundStyle(.white)
        .padding(16)
}
.accessibilityLabel("Cancel capture")
.accessibilityHint("Dismisses the camera without saving")
```

**Step 2: Add accessibility to modeIndicator**

Modify lines 273-289, adding after line 288 (before the closing brace):

```swift
return Text(text)
    .font(.system(size: 12, weight: .semibold, design: .rounded))
    .foregroundStyle(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background {
        // ... existing background code ...
    }
    .accessibilityLabel("Capture status: \(text)")
    .accessibilityAddTraits(.updatesFrequently)
```

**Step 3: Verify with VoiceOver**

Run on device/simulator with VoiceOver enabled. Navigate to Cancel button - should announce "Cancel capture, Button".

**Step 4: Commit**

```bash
git add Sources/CameraFeature/Views/CaptureView.swift
git commit -m "fix(a11y): add accessibility labels to CaptureView controls"
```

---

### Task 2: Fix Object Card Accessibility in DetectionResultsView

**Files:**

- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift:71-82, 105-119`
- Test: Manual VoiceOver verification

**Step 1: Add accessibility to BoundingBoxOverlay tap gesture**

Modify lines 71-83 to add accessibility modifiers:

```swift
ForEach(detectedObjects) { object in
    BoundingBoxOverlay(
        object: object,
        isSelected: selectedObjectId == object.groupId,
        isCataloging: catalogingObjectIds.contains(object.groupId),
        isCataloged: catalogedObjectIds.contains(object.groupId)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Detected: \(object.label)")
    .accessibilityHint(selectedObjectId == object.groupId ? "Double tap to deselect" : "Double tap to select")
    .accessibilityAddTraits(.isButton)
    .onTapGesture {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedObjectId = selectedObjectId == object.groupId ? nil : object.groupId
        }
    }
}
```

**Step 2: Add accessibility to DetectedObjectCard tap gesture**

Modify lines 104-120:

```swift
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(detectedObjects) { object in
            DetectedObjectCard(
                object: object,
                isSelected: selectedObjectId == object.groupId,
                isCataloging: catalogingObjectIds.contains(object.groupId),
                isCataloged: catalogedObjectIds.contains(object.groupId),
                onCatalog: {
                    onCatalogObject(object)
                }
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(object.label), \(object.category)")
            .accessibilityHint("Double tap to select this object")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedObjectId = object.groupId
                }
            }
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
}
```

**Step 3: Verify with VoiceOver**

Run with VoiceOver. Cards should announce object name and category. Bounding boxes should be discoverable.

**Step 4: Commit**

```bash
git add Sources/CameraFeature/Views/DetectionResultsView.swift
git commit -m "fix(a11y): add VoiceOver support to detection result cards"
```

---

### Task 3: Create Privacy Manifest (PrivacyInfo.xcprivacy)

**Files:**

- Create: `App/PrivacyInfo.xcprivacy`
- Modify: Xcode project (add to target)

**Step 1: Create the Privacy Manifest file**

Create file at `App/PrivacyInfo.xcprivacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>35F9.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Step 2: Verify XML syntax**

```bash
plutil -lint App/PrivacyInfo.xcprivacy
```

Expected: `App/PrivacyInfo.xcprivacy: OK`

**Step 3: Add to Xcode project**

In Xcode:

1. Select the App target
2. Build Phases → Copy Bundle Resources
3. Add `PrivacyInfo.xcprivacy`

**Step 4: Commit**

```bash
git add App/PrivacyInfo.xcprivacy
git commit -m "feat(privacy): add PrivacyInfo.xcprivacy for App Store compliance"
```

---

### Task 4: Fix Task Retain Cycle in teardownCamera()

**Files:**

- Modify: `Sources/CameraFeature/Views/CaptureView.swift:416-420`
- Test: Memory graph verification

**Step 1: Fix the retain cycle**

Modify lines 416-420:

```swift
private func teardownCamera() {
    let service = cameraService  // Capture reference before Task
    Task {
        await service.stopSession()
    }
}
```

**Step 2: Verify no retain cycle**

1. Run app in Debug mode
2. Open CaptureView
3. Dismiss CaptureView
4. Xcode Debug Navigator → Memory Graph
5. Search for "CaptureView" - should show 0 instances

**Step 3: Commit**

```bash
git add Sources/CameraFeature/Views/CaptureView.swift
git commit -m "fix(memory): prevent retain cycle in CaptureView teardownCamera"
```

---

## P1: High Priority Issues (Fix This Sprint)

### Task 5: Fix Fixed Font Sizes in CaptureView

**Files:**

- Modify: `Sources/CameraFeature/Views/CaptureView.swift:274, 331`

**Step 1: Fix modeIndicator font (line 274)**

Change:

```swift
.font(.system(size: 12, weight: .semibold, design: .rounded))
```

To:

```swift
.font(.system(.caption, weight: .semibold, design: .rounded))
```

**Step 2: Fix instructionLabel font (line 331)**

Change:

```swift
.font(.system(size: 15, weight: .regular, design: .rounded))
```

To:

```swift
.font(.system(.subheadline, weight: .regular, design: .rounded))
```

**Step 3: Test Dynamic Type**

Settings → Accessibility → Display & Text Size → Larger Text → Maximum
Verify text scales appropriately.

**Step 4: Commit**

```bash
git add Sources/CameraFeature/Views/CaptureView.swift
git commit -m "fix(a11y): use semantic fonts for Dynamic Type in CaptureView"
```

---

### Task 6: Fix Fixed Font Sizes in DetectionResultsView

**Files:**

- Modify: `Sources/CameraFeature/Views/DetectionResultsView.swift` (multiple locations)

**Step 1: Fix objectListHeader font (line 161)**

Change:

```swift
.font(.system(size: 14, weight: .semibold, design: .rounded))
```

To:

```swift
.font(.system(.caption, weight: .semibold, design: .rounded))
```

**Step 2: Fix BoundingBoxOverlay labelBadge font (line 262)**

Change:

```swift
.font(.system(size: 11, weight: .semibold, design: .rounded))
```

To:

```swift
.font(.system(.caption2, weight: .semibold, design: .rounded))
```

**Step 3: Fix DetectedObjectCard fonts**

Line 341 - change:

```swift
.font(.system(size: 17, weight: .semibold, design: .rounded))
```

To:

```swift
.font(.system(.body, weight: .semibold, design: .rounded))
```

Line 344 - change:

```swift
.font(.system(size: 12, design: .rounded))
```

To:

```swift
.font(.system(.caption, design: .rounded))
```

Line 357 - change:

```swift
.font(.system(size: 10, design: .rounded))
```

To:

```swift
.font(.system(.caption2, design: .rounded))
```

Line 371 - change:

```swift
.font(.system(size: 24))
```

To:

```swift
.font(.title2)
```

Line 378 - change:

```swift
.font(.system(size: 14, weight: .semibold, design: .rounded))
```

To:

```swift
.font(.system(.caption, weight: .semibold, design: .rounded))
```

**Step 4: Fix NoObjectsDetectedView fonts**

Line 395 - change:

```swift
.font(.system(size: 64))
```

To:

```swift
.font(.system(size: 64, weight: .regular, design: .default).leading(.tight))
```

Line 399 - change:

```swift
.font(.system(size: 22, weight: .semibold, design: .rounded))
```

To:

```swift
.font(.system(.title2, weight: .semibold, design: .rounded))
```

Line 411 - change:

```swift
.font(.system(size: 14, weight: .semibold, design: .rounded))
```

To:

```swift
.font(.system(.caption, weight: .semibold, design: .rounded))
```

**Step 5: Test Dynamic Type**

Verify all text scales with accessibility text sizes.

**Step 6: Commit**

```bash
git add Sources/CameraFeature/Views/DetectionResultsView.swift
git commit -m "fix(a11y): use semantic fonts for Dynamic Type in DetectionResultsView"
```

---

### Task 7: Cache DateFormatter in AppLogger

**Files:**

- Modify: `Sources/Core/Logging/AppLogger.swift:179`

**Step 1: Add static cached formatter**

Add near the top of the LogEvent enum (around line 10):

```swift
public enum LogEvent {
    // Add static formatter
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
```

**Step 2: Use cached formatter in metadata**

Line 179 - change:

```swift
"timestamp": ISO8601DateFormatter().string(from: Date()),
```

To:

```swift
"timestamp": Self.isoFormatter.string(from: Date()),
```

**Step 3: Run tests**

```bash
swift test --filter AppLoggerTests
```

**Step 4: Commit**

```bash
git add Sources/Core/Logging/AppLogger.swift
git commit -m "perf: cache ISO8601DateFormatter in AppLogger"
```

---

### Task 8: Add Keychain Accessibility Attribute

**Files:**

- Modify: `Sources/Persistence/KeychainManager.swift:21-26`

**Step 1: Add accessibility attribute to save query**

Modify lines 21-26:

```swift
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: key,
    kSecValueData as String: data,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
```

**Step 2: Run tests**

```bash
swift test --filter KeychainTests
```

**Step 3: Test manually**

1. Sign in to app
2. Verify token retrieval works
3. Sign out and sign back in

**Step 4: Commit**

```bash
git add Sources/Persistence/KeychainManager.swift
git commit -m "security: add explicit accessibility attribute to Keychain"
```

---

### Task 9: Fix Fixed Font Sizes in SignInView

**Files:**

- Modify: `Sources/OnboardingFeature/SignInView.swift`

**Step 1: Fix offline warning font (line 56-57)**

Change:

```swift
.font(.system(size: 14, weight: .medium))
```

To:

```swift
.font(.system(.caption, weight: .medium))
```

**Step 2: Fix title font (line 116)**

Change:

```swift
.font(.system(size: 28, weight: .bold, design: .rounded).leading(.tight))
```

To:

```swift
.font(.system(.title, weight: .bold, design: .rounded).leading(.tight))
```

**Step 3: Fix check connection button fonts (lines 190-192)**

Change:

```swift
.font(.system(size: 12, weight: .medium))
```

To:

```swift
.font(.system(.caption, weight: .medium))
```

**Step 4: Test Dynamic Type**

Verify sign-in screen scales properly.

**Step 5: Commit**

```bash
git add Sources/OnboardingFeature/SignInView.swift
git commit -m "fix(a11y): use semantic fonts for Dynamic Type in SignInView"
```

---

## P2: Medium Priority Issues (Fix Next Sprint)

### Task 10: Add Reduce Motion Support to ItemDetailView

**Files:**

- Modify: `Sources/InventoryFeature/ItemDetailView.swift:36`

**Step 1: Add environment variable**

Near the top of ItemDetailView (around line 8), add:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

**Step 2: Conditionally disable parallax**

Line 36 - change:

```swift
.offset(y: scrollOffset * 0.5)
```

To:

```swift
.offset(y: reduceMotion ? 0 : scrollOffset * 0.5)
```

**Step 3: Test with Reduce Motion**

Settings → Accessibility → Motion → Reduce Motion → ON
Verify parallax effect is disabled.

**Step 4: Commit**

```bash
git add Sources/InventoryFeature/ItemDetailView.swift
git commit -m "fix(a11y): respect Reduce Motion preference in ItemDetailView"
```

---

### Task 11: Add Reduce Motion to RescanCameraView

**Files:**

- Modify: `Sources/InventoryFeature/EditFlow/RescanCameraView.swift:78-80`

**Step 1: Add environment variable**

Add to RescanCameraView:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

**Step 2: Conditionally animate overlay**

Change transition to respect reduce motion:

```swift
if viewModel.state == .processing {
    ProcessingOverlay()
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
}
```

**Step 3: Commit**

```bash
git add Sources/InventoryFeature/EditFlow/RescanCameraView.swift
git commit -m "fix(a11y): respect Reduce Motion in RescanCameraView"
```

---

### Task 12: Remove Redundant DispatchQueue.main in CaptureSessionViewModel

**Files:**

- Modify: `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift:294`

**Step 1: Remove redundant receive(on:)**

Line 294 - remove:

```swift
.receive(on: DispatchQueue.main)
```

The class is already @MainActor, so Combine will dispatch to main automatically when the sink closure captures self.

**Step 2: Run tests**

```bash
swift test --filter CaptureSessionViewModelTests
```

**Step 3: Commit**

```bash
git add Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
git commit -m "refactor: remove redundant DispatchQueue.main in @MainActor ViewModel"
```

---

## Verification Checklist

After completing all tasks:

- [ ] Run full test suite: `swift test`
- [ ] Run swiftlint: `swiftlint`
- [ ] Test VoiceOver on device with CaptureView and DetectionResultsView
- [ ] Test Dynamic Type at maximum size
- [ ] Test Reduce Motion preference
- [ ] Verify Privacy Manifest is bundled: Build → Show in Finder → Contents → PrivacyInfo.xcprivacy
- [ ] Memory graph debug: Verify no CaptureView leaks after dismiss

---

## Final Commit

After all tasks complete:

```bash
git add .
git commit -m "chore: complete code review remediation (12 fixes)

P0 (Blocking):
- fix(a11y): CaptureView Cancel button accessibility
- fix(a11y): DetectionResultsView card accessibility
- feat(privacy): add PrivacyInfo.xcprivacy
- fix(memory): CaptureView teardownCamera retain cycle

P1 (High):
- fix(a11y): Dynamic Type fonts in CaptureView
- fix(a11y): Dynamic Type fonts in DetectionResultsView
- perf: cache DateFormatter in AppLogger
- security: Keychain accessibility attribute
- fix(a11y): Dynamic Type fonts in SignInView

P2 (Medium):
- fix(a11y): Reduce Motion in ItemDetailView
- fix(a11y): Reduce Motion in RescanCameraView
- refactor: remove redundant DispatchQueue.main"
```

---

## Execution Estimate

| Priority | Tasks | Estimate |
|----------|-------|----------|
| P0 | 4 | 45 min |
| P1 | 5 | 60 min |
| P2 | 3 | 20 min |
| Verification | - | 15 min |
| **Total** | **12** | **~2.5 hours** |
