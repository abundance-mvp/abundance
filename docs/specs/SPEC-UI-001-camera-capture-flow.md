# SPEC-UI-001: Camera Capture Flow

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## 1. Overview

The Camera Capture Flow is the primary entry point for adding items to the user's Collection. It provides a streamlined SwiftUI-based interface for capturing photos of household objects, which are then uploaded to Google Cloud Storage and analyzed server-side using Gemini 3 Flash for object detection.

### Key Features

- **Double-tap single capture**: Quick single photo capture for simple scenes
- **Long-press burst capture**: Multi-photo burst mode for complex scenes or multiple angles
- **Triple-tap sweep mode**: On-device EdgeTAM segmentation for camera sweep capture (device-eligible only)
- **Server-side detection**: All object detection runs on Firebase Cloud Functions using Gemini 3 Flash
- **Real-time feedback**: Visual overlays showing capture progress, upload status, and analysis state
- **Error recovery**: Comprehensive error handling with user-friendly recovery options

### Architecture Compliance

- **ADR-010 Compliant**: Pure SwiftUI implementation (no UIKit in Views/ViewModels)
- **MVVM Pattern**: CaptureSessionViewModel manages all capture state and business logic
- **Swift 6 Concurrency**: Task-based async/await with proper actor isolation

---

## 2. Capture Modes

The capture flow supports three modes, defined by the `CaptureMode` enum:

```swift
public enum CaptureMode: String, Sendable, Codable {
    case single  // Single photo from double-tap
    case burst   // Multiple photos from long-press burst
    case sweep   // Camera sweep with EdgeTAM on-device segmentation
}
```

### 2.1 Single Capture (Double-Tap)

Single capture mode is triggered by a double-tap gesture anywhere on the camera preview.

**Flow:**
1. User double-taps the camera preview
2. Network connectivity is verified (offline = error)
3. Photo is captured via `CameraService.capturePhoto()`
4. Preview freezes on captured frame
5. Haptic feedback (medium impact)
6. Photo uploaded to GCS
7. Server detection triggered
8. Results displayed or error shown

**Implementation:**

```swift
private var doubleTapGesture: some Gesture {
    TapGesture(count: 2)
        .onEnded {
            guard case .idle = viewModel.uiState else { return }
            captureAndProcess()
        }
}
```

### 2.2 Burst Capture (Long-Press Hold)

Burst capture mode is triggered by pressing and holding on the camera preview for 0.3 seconds.

**Flow:**
1. User presses and holds (minimum 0.3s to trigger)
2. Network connectivity is verified
3. Burst capture loop starts immediately
4. Photos captured at 0.5s intervals with haptic pulse
5. User releases to end capture
6. If 0 photos captured, shows `burstCaptureTooShort` error
7. If 1+ photos captured (even short holds), photos are uploaded and processed

**Implementation:**

```swift
private var longPressGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.3)
        .onEnded { _ in
            guard case .idle = viewModel.uiState else { return }
            startBurstCapture()
        }
        .simultaneously(with: DragGesture(minimumDistance: 0)
            .onEnded { _ in
                if longPressActive {
                    endBurstCapture()
                }
            }
        )
}
```

### 2.3 Sweep Capture (Triple-Tap)

Sweep capture mode is activated by triple-tapping the camera preview (when device-eligible) or via the `SweepModeToggle` pill at the bottom of the capture view.

**Prerequisites:**
- Device must pass `DeviceEligibility.isSweepModeAvailable` check
- Must be in `.idle` state and not in sweep mode already

**Flow:**
1. User triple-taps or selects "Sweep" from the mode toggle
2. `captureMode` switches from `.single` to `.sweep`
3. `SweepCaptureView` overlay appears on top of the camera preview
4. User sweeps camera; on-device EdgeTAM segmentation detects objects
5. User confirms or cancels (returning to `.single` mode)

**Implementation:**

```swift
private var tripleTapGesture: some Gesture {
    TapGesture(count: 3)
        .onEnded {
            guard case .idle = viewModel.uiState else { return }
            captureMode = .sweep
        }
}
```

**Components:**
- `SweepCaptureView` (Views/SweepCaptureView.swift) - Full overlay for sweep interaction
- `SweepModeToggle` (Views/SweepModeToggle.swift) - Pill selector at bottom of capture view
- `SweepCaptureViewModel` (ViewModels/SweepCaptureViewModel.swift) - State management for sweep

**Note:** Sweep mode is currently Phase 4 (crop/upload/pipeline integration is TODO).

---

## 3. Burst Parameters

The following constants define burst capture behavior in `CaptureSessionViewModel`:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `burstInterval` | 0.5 seconds | Time between consecutive captures |
| `minBurstDuration` | 1.0 seconds | Minimum hold time for valid burst |
| `maxBurstDuration` | 4.0 seconds | Auto-stop after this duration |
| **Max Photos** | 8 | Hard limit on photos per burst |
| `detectionTimeout` | 45.0 seconds | Server detection timeout |

**Auto-termination Conditions:**
- Maximum duration reached (4.0s)
- Maximum photo count reached (8 photos)
- 3 consecutive capture failures (error accumulation threshold)
- User releases (ends gesture)

**Burst Loop Implementation:**

```swift
burstTask = Task { @MainActor [weak self] in
    guard let self else { return }

    // Capture first photo immediately
    await self.captureBurstPhoto(capturePhoto: capturePhoto)

    // Continue at intervals until limit
    while !Task.isCancelled && self.isCapturing && self.capturedPhotos.count < 8 {
        try await Task.sleep(for: .milliseconds(500))
        if Task.isCancelled || !self.isCapturing { break }
        await self.captureBurstPhoto(capturePhoto: capturePhoto)
    }

    // Auto-end if max photos reached
    if self.capturedPhotos.count >= 8 && self.isCapturing {
        await self.endBurstCapture()
    }
}
```

---

## 4. UI States (CaptureUIState Enum)

The capture flow is driven by a finite state machine defined by `CaptureUIState`:

```swift
public enum CaptureUIState: Equatable, Sendable {
    /// Idle camera preview, ready for capture
    case idle

    /// Capturing photo(s) - count shows burst progress
    case capturing(count: Int)

    /// Uploading photos to GCS - progress is 0.0-1.0
    case uploading(progress: Double)

    /// Server analyzing images with Gemini 3 Flash
    case analyzing

    /// Detection results ready
    case results

    /// Error state with specific error type
    case error(CaptureError)
}
```

### State Descriptions

| State | Description | Visual Indicator |
|-------|-------------|------------------|
| `idle` | Camera preview active, gestures enabled | "Ready" (or "Sweep") badge, instruction label: "Double-tap to scan - Hold for burst" |
| `capturing(count)` | Photo(s) being captured | Photo count overlay (burst only) |
| `uploading(progress)` | Uploading to Cloud Storage | Circular progress indicator + percentage |
| `analyzing` | Server-side Gemini detection | Animated scan lines + "Analyzing..." |
| `results` | Detection complete | DetectionResultsView with bounding boxes |
| `error(CaptureError)` | Error occurred | ErrorOverlay with retry/dismiss |

---

## 5. State Machine Diagram

```
                                    ┌─────────────────────────────────────┐
                                    │                                     │
                                    ▼                                     │
┌─────────┐    double-tap     ┌──────────────────┐                       │
│         │─────────────────▶│  capturing(1)    │                       │
│  idle   │                   └────────┬─────────┘                       │
│         │◀────────────────────┐      │                                 │
└────┬────┘    retake/dismiss   │      │ single photo captured           │
     │                          │      │                                 │
     │ long-press              │      ▼                                 │
     │                          │ ┌──────────────────┐                   │
     ▼                          │ │ uploading(0.0)   │                   │
┌──────────────────┐            │ │     ...          │                   │
│  capturing(0)    │            │ │ uploading(1.0)   │                   │
│  capturing(1)    │ burst      │ └────────┬─────────┘                   │
│  capturing(2)    │ photos     │          │                             │
│      ...         │───────────▶│          │ all photos uploaded         │
│  capturing(8)    │            │          │                             │
└────────┬─────────┘            │          ▼                             │
         │                      │ ┌──────────────────┐                   │
         │ release gesture      │ │    analyzing     │                   │
         │ (0 photos captured)  │ └────────┬─────────┘                   │
         │                      │          │                             │
         ▼                      │          │ detection complete          │
┌──────────────────┐            │          │                             │
│      error       │────────────┘          ▼                             │
│(burstTooShort)   │            │ ┌──────────────────┐     ┌───────────┐ │
└──────────────────┘            │ │     results      │────▶│   done    │ │
         ▲                      │ └────────┬─────────┘     └───────────┘ │
         │                      │          │                             │
         │ any error            │          │ retake                      │
         │                      │          │                             │
         └──────────────────────┴──────────┴─────────────────────────────┘


Legend:
─────▶  State transition
◀─────  Return to previous state
```

### Transition Table

| From State | Trigger | To State | Condition |
|------------|---------|----------|-----------|
| `idle` | double-tap | `capturing(1)` | Network connected, not capturing |
| `idle` | long-press start | `capturing(0)` | Network connected, not capturing |
| `capturing(n)` | photo captured | `capturing(n+1)` | n < 8 |
| `capturing(n)` | release (burst) | `uploading(0)` | count >= 1 |
| `capturing(0)` | release (burst) | `error(burstTooShort)` | 0 photos captured |
| `capturing(n)` | 3 errors | `endBurstCapture()` | Error accumulation threshold |
| `uploading(p)` | upload progress | `uploading(p')` | p' > p |
| `uploading(1.0)` | all uploaded | `analyzing` | Ready for detection |
| `analyzing` | detection done | `results` | detectedObjects received |
| `analyzing` | timeout | `error(detectionTimeout)` | > 45 seconds |
| `results` | retake | `idle` | User action |
| `results` | done | dismiss view | User action |
| `error(*)` | dismiss/retry | `idle` | User action |

---

## 6. Key ViewModels

### 6.1 CaptureSessionViewModel

**File:** `/Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`

The main ViewModel managing all capture state, business logic, and service coordination.

#### Observable Properties

The ViewModel uses `@Observable` (iOS 17+ Observation framework), not `ObservableObject`/`@Published`:

```swift
@MainActor
@Observable
public final class CaptureSessionViewModel {
    public var uiState: CaptureUIState = .idle
    public var currentSession: CaptureSession?
    public var detectedObjects: [ServerDetectedObject] = []
    public var burstCount: Int = 0
    public var isCapturing: Bool = false
    public var lastCapturedPhoto: Data?
    public var burstErrors: [CaptureError] = []
    public var catalogingObjectIds: Set<String> = []
    public var catalogedObjectIds: Set<String> = []
}
```

#### Key Methods

| Method | Purpose |
|--------|---------|
| `handleDoubleTap(photoData:)` | Process single photo capture |
| `startBurstCapture(capturePhoto:)` | Begin burst capture loop |
| `endBurstCapture()` | End burst and process photos |
| `cancelBurstCapture()` | Cancel without processing |
| `retake()` | Reset to idle for new capture |
| `dismissError()` | Clear error and return to idle |
| `catalogObject(_:)` | Catalog single detected object |
| `catalogAllObjects()` | Catalog all detected objects |
| `catalogSelectedObjects(_:)` | Catalog only selected detected objects |

#### Private Methods

| Method | Purpose |
|--------|---------|
| `captureBurstPhoto(capturePhoto:)` | Capture single photo in burst loop |
| `processCapture(userId:captureMode:)` | Upload photos and trigger detection |
| `observeSession(sessionId:)` | Listen for session status changes |
| `handleSessionUpdate(_:)` | Process Firestore session updates |
| `waitForDetection(sessionId:)` | Poll for detection completion |
| `triggerHapticPulse()` | Fire haptic feedback (iOS only) |
| `cleanupCapture()` | Reset all capture state |

---

## 7. Error Handling

### 7.1 CaptureError Types

**File:** `/Sources/CameraFeature/Models/CaptureError.swift`

```swift
public enum CaptureError: Error, LocalizedError, Sendable, Equatable {
    // Authentication Errors
    case notAuthenticated        // User not signed in
    case authenticationExpired   // Session expired

    // Capture Errors
    case captureFailure          // Camera capture failed
    case invalidImageData        // Photo data corrupt
    case burstCaptureTooShort    // Hold < 1.0s or < 2 photos

    // Upload Errors
    case uploadFailed(underlying: Error?)  // GCS upload failed
    case networkTimeout          // Network unreachable/timeout
    case quotaExceeded           // Storage quota exceeded

    // Detection Errors
    case detectionTimeout        // Server detection > 45s
    case detectionFailed(reason: String)  // Server error
    case invalidResponse         // Malformed server response

    // General Errors
    case sessionNotFound         // Firestore session missing
    case unknownError(underlying: Error?)  // Catch-all
}
```

### 7.2 Error Properties

Each error provides:

| Property | Type | Description |
|----------|------|-------------|
| `errorDescription` | String? | User-facing error message |
| `recoverySuggestion` | String? | Actionable recovery hint |
| `isRetryable` | Bool | Whether retry makes sense |
| `errorCode` | String | Analytics/logging code |

### 7.3 Burst Error Accumulation

During burst capture, individual photo capture failures are accumulated rather than immediately stopping the burst:

```swift
do {
    let photoData = try await capturePhoto()
    capturedPhotos.append(photoData)
    // ... success handling
} catch {
    // Accumulate errors and stop after 3 failures
    let captureError = (error as? CaptureError) ?? .unknownError(underlying: error)
    burstErrors.append(captureError)
    logger.error("Failed to capture burst photo: \(error.localizedDescription)")
    if burstErrors.count >= 3 {
        logger.error("Too many burst capture failures, stopping burst")
        await endBurstCapture()
    }
}
```

**Threshold:** 3 consecutive failures triggers automatic burst termination.

### 7.4 Error Recovery UI

**File:** `/Sources/CameraFeature/Views/ErrorRecoveryView.swift`

The `ErrorRecoveryView` provides contextual error recovery:

- **Error categorization**: Camera, Network, Authentication, Server, Unknown
- **Category-specific icons and colors**
- **Retry button**: For retryable errors
- **Open Settings**: For camera permission denied
- **Dismiss button**: For non-retryable errors
- **Liquid Glass styling**: iOS 26+ with material fallbacks

**Error Categories:**

| Category | Icon | Color | Example Errors |
|----------|------|-------|----------------|
| Camera | camera.fill | Yellow | captureFailure, invalidImageData |
| Network | wifi.exclamationmark | Orange | networkTimeout, uploadFailed |
| Authentication | person.crop.circle.badge.exclamationmark | Blue | notAuthenticated |
| Server | server.rack | Red | detectionTimeout, detectionFailed |
| Unknown | exclamationmark.triangle.fill | Yellow | unknownError |

---

## 8. Haptic Feedback

### Burst Photo Capture Pulse

Each photo captured during burst mode triggers haptic feedback:

```swift
private func triggerHapticPulse() async {
    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    #endif
}
```

### Single Capture Feedback

Single capture also provides haptic feedback in the View layer:

```swift
// In CaptureView.captureAndProcess()
#if os(iOS)
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
```

**Feedback Type:** Medium impact (`UIImpactFeedbackGenerator.FeedbackStyle.medium`)

**Purpose:** Provides tactile confirmation that photos are being captured, especially important during burst mode when the user cannot see the count change.

---

## 9. Integration Points

### 9.1 SessionService (Firestore)

**File:** `/Sources/CameraFeature/Services/SessionService.swift`

**Protocol:** `SessionServiceProtocol`

Manages capture session documents in Firestore.

| Method | Purpose |
|--------|---------|
| `createSession(userId:captureMode:expectedImageCount:)` | Create new session document |
| `addUploadedImage(sessionId:imageUrl:)` | Record uploaded image URL |
| `markReadyForDetection(sessionId:)` | Set status to `detecting` |
| `observeSession(sessionId:)` | Real-time session updates (Combine) |
| `getSession(sessionId:)` | Fetch session by ID |
| `deleteSession(sessionId:)` | Remove session document |

**Firestore Collection:** `sessions`

**Session Status Flow:**
```
uploading → detecting → detected/failed
```

### 9.2 StorageService (GCS Upload)

**File:** `/Sources/Persistence/Firebase/StorageService.swift`

**Protocol:** `StorageServiceProtocol`

Handles image upload to Google Cloud Storage.

| Method | Purpose |
|--------|---------|
| `uploadCroppedObject(_:itemId:userId:)` | Upload JPEG to GCS |
| `uploadLivePhotoMotion(_:itemId:userId:)` | Upload Live Photo MOV |

**Storage Path:** `users/{userId}/items/{itemId}.jpg`

**Upload Configuration:**
- JPEG compression: 80% quality
- Upload timeout: 60 seconds
- Cache control: 1 hour public cache
- Custom metadata: processingStatus, uploadSource, timestamps

### 9.3 CatalogService (Item Creation)

**File:** `/Sources/CameraFeature/Services/CatalogService.swift`

**Protocol:** `CatalogServiceProtocol`

Creates collection items from detected objects.

| Method | Purpose |
|--------|---------|
| `catalogDetectedObject(userId:sessionId:object:)` | Create item document |
| `observeItem(itemId:)` | Track cataloging status (Combine) |

**Firestore Collection:** `items`

**Item Status Flow:**
```
pending → processing → complete/failed
```

---

## 10. View Components

### 10.1 Main Views

| View | File | Purpose |
|------|------|---------|
| `CaptureView` | Views/CaptureView.swift | Main capture interface |
| `CameraPreviewView` | Views/CameraPreviewView.swift | AVCaptureSession preview |
| `DetectionResultsView` | Views/DetectionResultsView.swift | Results with object selection |
| `ErrorRecoveryView` | Views/ErrorRecoveryView.swift | Error recovery modal |

### 10.2 Overlay Views

| View | File | Purpose |
|------|------|---------|
| `CaptureOverlay` | Views/CaptureOverlays.swift | Photo count during capture |
| `UploadingOverlay` | Views/CaptureOverlays.swift | Upload progress indicator |
| `AnalyzingOverlay` | Views/CaptureOverlays.swift | Analysis animation |
| `ErrorOverlay` | Views/CaptureOverlays.swift | Inline error display |

### 10.3 Sweep Mode Views

| View | File | Purpose |
|------|------|---------|
| `SweepCaptureView` | Views/SweepCaptureView.swift | Sweep mode overlay on camera |
| `SweepModeToggle` | Views/SweepModeToggle.swift | Single/Sweep mode pill selector |

### 10.4 Supporting Views

| View | File | Purpose |
|------|------|---------|
| `NoObjectsDetectedView` | Views/DetectionResultsView.swift | Empty results with reasoning |
| `OfflineModeIndicator` | Views/ErrorRecoveryView.swift | Network status badge |

---

## 11. Accessibility

### VoiceOver Support

- All interactive elements have `accessibilityLabel` and `accessibilityHint`
- Photo count changes announced during burst capture
- Error states clearly labeled with recovery instructions
- Mode indicator updates marked with `.updatesFrequently` trait

### Reduce Motion Support

- `AnalyzingOverlay` respects `@Environment(\.accessibilityReduceMotion)`
- Animated scan lines replaced with static progress indicator

### Reduce Transparency Support

- Glass effects fall back to solid backgrounds
- Material backgrounds replaced with opaque colors

---

## 12. Related Specifications

- **SPEC-ARCH-001**: System Overview
- **SPEC-PIPE-001**: Layer 1 Detection Pipeline
- **SPEC-PIPE-003**: Session Persistence
- **SPEC-DATA-001**: Firestore Schema
- **SPEC-DATA-002**: Storage Architecture
- **ADR-010**: SwiftUI-Only Architecture Decision
