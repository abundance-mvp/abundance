# AVCaptureDevice API Documentation

**Source**: https://sosumi.ai/documentation/avfoundation/avcapturedevice
**Fetched**: 2025-11-02

## Overview

AVCaptureDevice represents hardware or virtual capture devices (cameras, microphones) that supply media to capture sessions. Devices are retrieved via `DiscoverySession` or the `default(_:for:position:)` method—instances aren't created directly.

**Key principle:** Device configuration requires acquiring a lock via `lockForConfiguration()`, querying capabilities, applying changes, then calling `unlockForConfiguration()`.

## Availability

- iOS 4.0+
- iPadOS 4.0+
- macOS 10.7+
- Mac Catalyst 14.0+
- tvOS 17.0+
- visionOS 1.0+

## Class Declaration

```swift
class AVCaptureDevice : NSObject
```

### Conforms To
- `Equatable`, `Hashable`, `CustomStringConvertible`, `CustomDebugStringConvertible`

---

## Finding & Monitoring Devices

| Method/Property | Purpose |
|---|---|
| `DiscoverySession` | Locates devices matching specific search criteria |
| `default(_:for:position:)` | Returns default device for type, media type, and position |
| `default(for:)` | Returns default device for specified media type |
| `init(uniqueID:)` | Creates device reference from identifier |
| `devices()` | Returns all available capture devices |
| `devices(for:)` | Returns devices capturing specified media type |
| `wasConnectedNotification` | Posted when device becomes available |
| `wasDisconnectedNotification` | Posted when device becomes unavailable |

---

## Device Authorization

| Method/Property | Purpose |
|---|---|
| `requestAccess(for:completionHandler:)` | Requests user permission for media capture |
| `authorizationStatus(for:)` | Returns authorization status for media type |
| `AVAuthorizationStatus` | Constants indicating authorization state |

---

## Device Identification

| Property | Details |
|---|---|
| `uniqueID` | Unique device identifier |
| `modelID` | Model identifier string |
| `localizedName` | User-facing device name |
| `manufacturer` | Manufacturer name |
| `deviceType` | Device type (e.g., wide-angle camera, microphone) |
| `position` | Physical position (front/back) |

---

## Device State Properties

| Property | Type | Purpose |
|---|---|---|
| `isConnected` | Bool | Device currently available and connected |
| `isSuspended` | Bool | Device in suspended state |
| `isInUseByAnotherApplication` | Bool | Another app actively using device |

---

## Device Characteristics

| Method/Property | Purpose |
|---|---|
| `isVirtualDevice` | Indicates composite device (2+ physical devices) |
| `constituentDevices` | Array of physical devices in virtual device |
| `hasMediaType(_:)` | Checks if device captures specified media type |
| `transportType` | Device transport mechanism |
| `supportsSessionPreset(_:)` | Validates preset compatibility |

---

## Configuration Methods

```swift
lockForConfiguration()        // Acquire exclusive configuration access
unlockForConfiguration()      // Release configuration lock
```

**Warning:** Unnecessarily holding locks degrades capture quality in other apps.

---

## Camera Control Sections

### Focus Configuration
- Auto/manual focus behavior
- Lens position control

### Exposure Configuration
- Automatic/manual exposure modes
- Exposure settings control

### White Balance Configuration
- Automatic/manual white balance
- Color temperature adjustment

### Lighting
- Flash and torch configuration
- Low-light enhancement

### Color
- HDR settings
- Color space management

### Zoom
- Zoom behavior configuration
- Hardware capability inspection

### Formats
- Capture format configuration
- Frame rate control

---

## Cinematic Video Support

| Method | Purpose |
|---|---|
| `setCinematicVideoFixedFocus(at:focusMode:)` | Lock focus at distance |
| `setCinematicVideoTrackingFocus(at:focusMode:)` | Track and focus object at point |
| `setCinematicVideoTrackingFocus(detectedObjectID:focusMode:)` | Track detected object |
| `cinematicVideoCaptureSceneMonitoringStatuses` | Current scene conditions affecting capture |

---

## Smart Framing & Dynamic Aspect Ratio

| Property/Method | Purpose |
|---|---|
| `smartFramingMonitor` | Recommends optimal framing based on scene |
| `setDynamicAspectRatio(_:completionHandler:)` | Updates video aspect ratio |
| `dynamicAspectRatio` | Observable aspect ratio property |
| `dynamicDimensions` | Observable output dimensions property |

---

## Advanced Features

### Automatic Frame Rate
- `isAutoVideoFrameRateEnabled` – Device performs automatic rate adjustments

### Spatial Capture
- `spatialCaptureDiscomfortReasons` – Environmental suitability indicators

### Continuity Camera Support
- `systemPreferredCamera` – System-recommended camera
- `userPreferredCamera` – User-selected camera
- `isContinuityCamera` – Identifies Continuity Camera devices
- `companionDeskViewCamera` – Associated Desk View camera

### System Pressure Monitoring
- `systemPressureState` – OS and hardware status affecting performance

### Camera Switching (Virtual Devices)
- `setPrimaryConstituentDeviceSwitchingBehavior(_:restrictedSwitchingBehaviorConditions:)` – Control device switching
- `primaryConstituentDeviceSwitchingBehavior` – Current switching mode
- `activePrimaryConstituent` – Active primary device

---

## Lens & Optical Properties

| Property | Purpose |
|---|---|
| `nominalFocalLengthIn35mmFilm` | Focal length in 35mm equivalent |
| `extrinsicMatrix(from:to:)` | Relative positioning between devices |
| `AVCaptureDevice.LensStabilizationStatus` | OIS hardware status |

---

## Lens Smudge Detection

| Method/Property | Purpose |
|---|---|
| `isCameraLensSmudgeDetectionEnabled` | Enables/disables smudge detection |
| `setCameraLensSmudgeDetectionEnabled(_:detectionInterval:)` | Configure detection frequency |
| `cameraLensSmudgeDetectionStatus` | Current detection status |

---

## External Synchronization

| Property | Purpose |
|---|---|
| `isFollowingExternalSyncDevice` | Device following external sync source |
| `minSupportedExternalSyncFrameDuration` | Minimum frame duration for external sync |
| `isVideoFrameDurationLocked` | Frame rate lock status |
| `minSupportedLockedVideoFrameDuration` | Maximum achievable frame rate |

---

## Important Usage Notes

1. **Configuration Lock Required:** Always lock before modifying device properties; query capabilities first to ensure validity.

2. **Don't Hold Locks Unnecessarily:** Prolonged locks degrade other app performance—release when configuration completes.

3. **Discovery Pattern:** Use `DiscoverySession` with specific criteria or static `default()` methods rather than instantiating directly.

4. **Subject Area Monitoring:** Enable `isSubjectAreaChangeMonitoringEnabled` and observe `subjectAreaDidChangeNotification` for automatic refocus triggers.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
