# DataScannerViewController API Documentation

**Source**: https://sosumi.ai/documentation/visionkit/datascannerviewcontroller
**Fetched**: 2025-11-02

## Overview

`DataScannerViewController` extracts data from live camera video, including "text, data in text, and machine-readable codes."

**Availability**: iOS 16.0+, iPadOS 16.0+, visionOS 1.0+

## Initialization

```swift
init(recognizedDataTypes:qualityLevel:recognizesMultipleItems:isHighFrameRateTrackingEnabled:isPinchToZoomEnabled:isGuidanceEnabled:isHighlightingEnabled:)
```

## Configuration Properties

- **delegate**: Handles user interactions with recognized items
- **qualityLevel**: Resolution used for data detection (QualityLevel enum)
- **recognizesMultipleItems**: Boolean controlling single vs. multiple item detection
- **isHighFrameRateTrackingEnabled**: Frequency of geometry updates for recognized items
- **isPinchToZoomEnabled**: Enables two-finger pinch-to-zoom functionality
- **isGuidanceEnabled**: Provides assistance when selecting items
- **isHighlightingEnabled**: Displays highlights around detected items

## Recognized Data Types

Supported data types specified via `recognizedDataTypes` property and `RecognizedDataType` enum. Framework recognizes text content across languages listed in `supportedTextRecognitionLanguages`.

## Scanning Lifecycle

**Starting and stopping:**
- `startScanning()` initiates video analysis
- `stopScanning()` halts the process
- `isScanning` property indicates active state

**Availability checks:**
- `isSupported`: Device capability check
- `isAvailable`: Permission and restriction verification
- `ScanningUnavailable` enum lists unavailability reasons

## Key Methods

**Recognition:**
- `recognizedItems`: Asynchronous array of currently detected items

**Zooming:**
- `zoomFactor`, `minZoomFactor`, `maxZoomFactor` manage camera magnification

**Customization:**
- `overlayContainerView`: Custom overlay layer
- `regionOfInterest`: Defines searchable video area
- `capturePhoto()`: Captures high-resolution images

## Requirements

- Add `NSCameraUsageDescription` to Info.plist
- User grants camera permission
- Check availability using provided properties
- Implement `DataScannerViewControllerDelegate` protocol

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
