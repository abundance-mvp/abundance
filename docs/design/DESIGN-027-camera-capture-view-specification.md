# DESIGN-027: Camera Capture View Specification

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md
- docs/design/DESIGN-004-computer-vision-pipeline.md
- docs/design/DESIGN-013-vision-framework-integration-patterns.md
- docs/adr/ADR-010-swiftui-architecture-pattern.md
- shared/abundance-brand/abundance-brand-bible.md

---

## Overview

This document specifies the Camera Capture View for the Abundance iOS app, which enables users to scan household items using the device camera with real-time object detection and barcode scanning. The view integrates AVFoundation for camera preview, Vision Framework for on-device object detection (Layer 1 from Stage 2.4), and displays visual feedback using the Liquid Glass design language.

**User Journey**: Catalog View → Tap Camera Tab → Camera Opens → Detect Objects → Tap Capture → Cropped Objects Uploaded → AI Processing → Return to Catalog

**Success Criteria**:
- Camera preview loads in < 500ms
- Real-time object detection displays bounding boxes at 30 FPS
- Barcode detection triggers Mint Green glow indicator within 200ms
- Capture button provides immediate haptic + visual feedback
- User returns to Catalog view with loading states for AI processing

---

## Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  [Cancel - .secondary]                                          │
│                                                                   │
│                                                                   │
│                    CAMERA PREVIEW (Fullscreen)                   │
│                       AVCaptureVideoPreviewLayer                 │
│                                                                   │
│   ┌─────────────────────────────────────────────────────┐       │
│   │                                                       │       │
│   │         [Glass Overlay Frame - ConcentricRectangle]  │       │
│   │         .thin material, 2pt stroke, .primary vibrancy│       │
│   │                                                       │       │
│   │                                                       │       │
│   │         [Object Bounding Box - Bright Blue]          │       │
│   │         2pt stroke, soft glow, label overlay         │       │
│   │                                                       │       │
│   │         [Barcode Indicator - Mint Green Glow]        │       │
│   │         Pulsing animation when barcode detected      │       │
│   │                                                       │       │
│   └─────────────────────────────────────────────────────┘       │
│                                                                   │
│                                                                   │
│                                                                   │
│                                                                   │
│                      [Capture Button]                            │
│                   Capsule, 80x80pt, .thick material              │
│                   Camera icon, Bright Blue glow                  │
│                                                                   │
│                                                                   │
│   "Align item within frame • Tap to capture"                    │
│   15pt, SF Pro Rounded Regular, .secondary vibrancy             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components

### Camera Preview Layer

**Implementation**: AVCaptureVideoPreviewLayer wrapped in UIViewRepresentable

**Specifications**:
- **Video Gravity**: `.resizeAspectFill` (fullscreen, no letterboxing)
- **Position**: Edge-to-edge, extends under safe area
- **Orientation**: Follows device orientation (portrait, landscape)
- **Frame Rate**: 30 FPS (balance between performance and battery)
- **Resolution**: 1920x1080 (Full HD) for optimal object detection

**AVFoundation Setup**:
```swift
let captureSession = AVCaptureSession()
captureSession.sessionPreset = .hd1920x1080

guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
    throw CameraError.noCameraAvailable
}

let input = try AVCaptureDeviceInput(device: camera)
captureSession.addInput(input)

let output = AVCapturePhotoOutput()
captureSession.addOutput(output)
```

**Privacy**: Camera permission must be granted (from Onboarding Permissions screen). If denied, show alert with "Open Settings" button.

---

### Glass Overlay Frame

**Purpose**: Visual guide to help users frame objects within the detection area

**Specifications**:
- **Shape**: ConcentricRectangle(cornerRadius: 24, inset: 0) [iOS 26+]
- **Fallback**: RoundedRectangle(cornerRadius: 24) [iOS 25]
- **Material**: .thin (translucent, subtle blur)
- **Stroke**: 2pt, .primary vibrancy
- **Position**: Centered, 80% of screen width, 60% of screen height
- **Padding**: 40pt from edges (safe for all device sizes)
- **Animation**: Gentle fade-in on camera open (.brandGentle spring, 0.3s delay)

**Visual Effect**:
- Soft shadow: `radius: 8, color: .black.opacity(0.2), x: 0, y: 4`
- Inner glow when object detected: Bright Blue shadow, radius 12, opacity 0.3

**SwiftUI Implementation**:
```swift
struct GlassOverlayFrame: View {
    @Binding var hasDetectedObject: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if #available(iOS 26, *) {
            ConcentricRectangle(cornerRadius: 24, inset: 0)
                .strokeBorder(style: StrokeStyle(lineWidth: 2))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
                .background {
                    if !reduceTransparency {
                        if #available(iOS 26, *) {
                            ConcentricRectangle(cornerRadius: 24, inset: 0)
                                .fill(.thinMaterial)
                        } else {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.thinMaterial)
                        }
                    }
                }
                .shadow(
                    color: hasDetectedObject ? Color.brandBrightBlue.opacity(0.3) : .black.opacity(0.2),
                    radius: hasDetectedObject ? 12 : 8,
                    x: 0,
                    y: 4
                )
                .animation(.brandGentle, value: hasDetectedObject)
        } else {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(style: StrokeStyle(lineWidth: 2))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
                .background {
                    if !reduceTransparency {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.thinMaterial)
                    }
                }
                .shadow(
                    color: hasDetectedObject ? Color.brandBrightBlue.opacity(0.3) : .black.opacity(0.2),
                    radius: hasDetectedObject ? 12 : 8,
                    x: 0,
                    y: 4
                )
                .animation(.brandGentle, value: hasDetectedObject)
        }
    }
}
```

**Accessibility**:
- Hidden from VoiceOver (decorative element)
- Reduce Transparency: Remove material, use opaque `backgroundDefault` color

---

### Object Bounding Boxes

**Purpose**: Display real-time object detection results from Vision Framework (VNCoreMLRequest with YOLOv3-Tiny)

**Specifications**:
- **Shape**: Rectangle (Vision Framework bounding box coordinates)
- **Stroke**: 2pt, Bright Blue (#4381DF)
- **Glow**: Soft shadow, radius 8, Bright Blue at 40% opacity
- **Label**: Object class name (e.g., "backpack", "tent", "drill")
  - **Position**: Top-left of bounding box, 4pt padding
  - **Background**: .ultraThickMaterial (pill shape, Capsule)
  - **Text**: 12pt SF Pro Rounded Semibold, .primary vibrancy
  - **Min Confidence**: Only show labels for objects with >60% confidence

**Coordinate Transformation**:
- Vision Framework uses normalized coordinates (0-1, bottom-left origin)
- Transform to UIKit coordinates (pixels, top-left origin) using CoordinateTransformer (DESIGN-013)

**Animation**:
- Bounding boxes appear with brandSnappy spring (0.3s response, 0.6 damping)
- Glow pulses gently when object confidence > 80% (brandGentle spring, repeat forever)

**SwiftUI Implementation**:
```swift
struct ObjectBoundingBox: View {
    let object: DetectedObject
    let imageSize: CGSize

    var body: some View {
        let pixelRect = CoordinateTransformer.visionToUIKit(
            object.boundingBox,
            imageSize: imageSize
        )

        Rectangle()
            .strokeBorder(Color.brandBrightBlue, lineWidth: 2)
            .frame(width: pixelRect.width, height: pixelRect.height)
            .position(x: pixelRect.midX, y: pixelRect.midY)
            .shadow(color: Color.brandBrightBlue.opacity(0.4), radius: 8, x: 0, y: 0)
            .overlay(alignment: .topLeading) {
                if object.confidence >= 0.6 {
                    Text(object.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThickMaterial, in: Capsule())
                        .offset(x: pixelRect.minX + 4, y: pixelRect.minY + 4)
                }
            }
            .animation(.brandSnappy, value: object.boundingBox)
    }
}
```

**Performance**: Limit to 5 bounding boxes max (display top 5 by confidence to avoid UI clutter)

---

### Barcode Detection Indicator

**Purpose**: Provide visual feedback when barcode is detected (VNDetectBarcodesRequest from Vision Framework)

**Specifications**:
- **Shape**: Circle, 60pt diameter
- **Position**: Top-right corner of overlay frame, 12pt from edge
- **Icon**: SF Symbol "barcode.viewfinder", 24pt
- **Color**: Mint Green (#B3FFE1) when detected, .secondary when not detected
- **Glow**: Mint Green shadow, radius 16, opacity 0.6 (pulsing animation)
- **Animation**: Pulsing scale effect (1.0 → 1.1 → 1.0) with brandBouncy spring

**Trigger**: VNDetectBarcodesRequest returns successful result with recognized barcode value

**SwiftUI Implementation**:
```swift
struct BarcodeIndicator: View {
    @Binding var barcodeDetected: Bool
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(.ultraThickMaterial)
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 24))
                    .foregroundStyle(barcodeDetected ? Color.brandMintGreen : .secondary)
            }
            .shadow(
                color: barcodeDetected ? Color.brandMintGreen.opacity(0.6) : .clear,
                radius: barcodeDetected ? 16 : 0,
                x: 0,
                y: 0
            )
            .scaleEffect(isPulsing && barcodeDetected ? 1.1 : 1.0)
            .animation(.brandBouncy.repeatForever(autoreverses: true), value: isPulsing)
            .onChange(of: barcodeDetected) { _, newValue in
                isPulsing = newValue
            }
            .accessibilityLabel(barcodeDetected ? "Barcode detected" : "No barcode detected")
    }
}
```

**Haptic Feedback**: `.success` haptic when barcode first detected

---

### Capture Button

**Purpose**: Primary action button to capture photo and trigger object cropping + AI analysis

**Specifications**:
- **Shape**: Circle, 80x80pt (large tap target)
- **Material**: .thickMaterial
- **Icon**: SF Symbol "camera.fill", 36pt, .primary vibrancy
- **Border**: 3pt stroke, Bright Blue (#4381DF)
- **Glow**: Bright Blue shadow, radius 12, opacity 0.5
- **Position**: Bottom center, 32pt above safe area
- **States**:
  - **Default**: Bright Blue glow, solid border
  - **Pressed**: Scale to 0.9, glow radius 16, border 4pt
  - **Disabled**: .secondary color, no glow, reduced opacity 0.5
  - **Capturing**: Spinning activity indicator, glow pulsing

**Action**:
1. Tap → Haptic feedback (`.impact(weight: .medium)`)
2. Scale animation (brandSnappy spring)
3. Capture photo via AVCapturePhotoOutput
4. Show loading overlay while processing
5. Navigate back to Catalog with AI processing state

**SwiftUI Implementation**:
```swift
struct CaptureButton: View {
    let action: () -> Void
    @Binding var isCapturing: Bool
    @Binding var isEnabled: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) label: {
            ZStack {
                Circle()
                    .fill(.thickMaterial)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.brandBrightBlue, lineWidth: isPressed ? 4 : 3)
                    }
                    .shadow(
                        color: Color.brandBrightBlue.opacity(0.5),
                        radius: isPressed ? 16 : 12,
                        x: 0,
                        y: 4
                    )

                if isCapturing {
                    ProgressView()
                        .tint(.primary)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.primary)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.brandSnappy, value: isPressed)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
        .accessibilityLabel("Capture photo")
        .accessibilityHint("Captures photo of items in frame for AI cataloging")
    }
}
```

---

### Cancel Button

**Purpose**: Exit camera view without capturing, return to Catalog

**Specifications**:
- **Type**: Text button, "Cancel"
- **Font**: 17pt SF Pro Rounded Regular
- **Color**: .secondary vibrancy
- **Position**: Top-left, 16pt from safe area edges
- **Tap Target**: 44x44pt minimum (iOS HIG)

**SwiftUI Implementation**:
```swift
Button("Cancel") {
    dismiss()
}
.font(.system(.body, design: .rounded))
.foregroundStyle(.secondary)
.padding(16)
.accessibilityLabel("Cancel")
.accessibilityHint("Close camera without capturing")
```

---

### Instruction Label

**Purpose**: Guide user to align items within overlay frame

**Specifications**:
- **Text**: "Align item within frame • Tap to capture"
- **Font**: 15pt SF Pro Rounded Regular (Dynamic Type Callout)
- **Color**: .secondary vibrancy
- **Position**: Below capture button, 16pt spacing
- **Alignment**: Center
- **Background**: .ultraThickMaterial (pill shape, Capsule)
- **Padding**: 12pt horizontal, 8pt vertical

**States**:
- **No objects detected**: Default instruction
- **Object detected**: "Object detected • Ready to capture"
- **Barcode detected**: "Barcode detected • Scan complete"

**SwiftUI Implementation**:
```swift
struct InstructionLabel: View {
    let detectionState: DetectionState

    enum DetectionState {
        case noDetection
        case objectDetected
        case barcodeDetected

        var text: String {
            switch self {
            case .noDetection: return "Align item within frame • Tap to capture"
            case .objectDetected: return "Object detected • Ready to capture"
            case .barcodeDetected: return "Barcode detected • Scan complete"
            }
        }
    }

    var body: some View {
        Text(detectionState.text)
            .font(.system(.callout, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThickMaterial, in: Capsule())
            .animation(.brandGentle, value: detectionState)
    }
}
```

---

## State Management

### CameraViewModel

**MVVM Pattern** (ADR-010):

```swift
import SwiftUI
import AVFoundation
import Vision
import Combine

@MainActor
class CameraViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var detectedObjects: [DetectedObject] = []
    @Published var barcodeValue: String?
    @Published var isCapturing: Bool = false
    @Published var error: CameraError?
    @Published var hasDetectedObject: Bool = false

    // MARK: - Dependencies

    private let visionService: VisionServiceProtocol
    private let captureService: CaptureServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var detectionState: InstructionLabel.DetectionState {
        if barcodeValue != nil {
            return .barcodeDetected
        } else if hasDetectedObject {
            return .objectDetected
        } else {
            return .noDetection
        }
    }

    var canCapture: Bool {
        !isCapturing && hasDetectedObject
    }

    // MARK: - Initialization

    init(
        visionService: VisionServiceProtocol,
        captureService: CaptureServiceProtocol
    ) {
        self.visionService = visionService
        self.captureService = captureService
        observeCameraFrames()
    }

    // MARK: - Real-Time Detection

    func observeCameraFrames() {
        captureService.framePublisher
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] sampleBuffer in
                guard let self = self else { return }
                Task {
                    await self.processFrame(sampleBuffer)
                }
            }
            .store(in: &cancellables)
    }

    func processFrame(_ sampleBuffer: CMSampleBuffer) async {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        do {
            // Run Vision Framework detection
            let objects = try await visionService.detectObjectsInFrame(pixelBuffer)
            detectedObjects = objects.filter { $0.confidence >= 0.6 }
            hasDetectedObject = !detectedObjects.isEmpty

            // Detect barcodes
            let barcode = try await visionService.detectBarcode(in: pixelBuffer)
            barcodeValue = barcode

        } catch {
            // Silent failure for real-time detection (don't show errors for every frame)
        }
    }

    // MARK: - Capture Photo

    func capturePhoto() async {
        guard canCapture else { return }

        isCapturing = true
        defer { isCapturing = false }

        do {
            // Capture high-res photo
            let photo = try await captureService.capturePhoto()

            // Detect and crop objects
            let croppedObjects = try await visionService.detectAndCropObjects(in: photo)

            // Upload cropped objects to Firebase Storage (Layer 1 privacy firewall)
            // Trigger Layer 2 AI processing
            // Navigate back to Catalog with loading state

        } catch let error as CameraError {
            self.error = error
        } catch {
            self.error = .captureFailed(error)
        }
    }
}

enum CameraError: Error, LocalizedError {
    case noCameraAvailable
    case permissionDenied
    case captureFailed(Error)
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "Camera not available on this device."
        case .permissionDenied:
            return "Camera permission denied. Enable in Settings."
        case .captureFailed(let error):
            return "Failed to capture photo: \(error.localizedDescription)"
        case .processingFailed:
            return "Failed to process photo. Please try again."
        }
    }
}
```

---

## SwiftUI Implementation Pattern

### CameraView (Main View)

```swift
import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        visionService: VisionServiceProtocol = VisionService(),
        captureService: CaptureServiceProtocol = AVCaptureService()
    ) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(
            visionService: visionService,
            captureService: captureService
        ))
    }

    var body: some View {
        ZStack {
            // Camera Preview (fullscreen)
            CameraPreviewView(captureService: viewModel.captureService)
                .ignoresSafeArea()

            // Glass Overlay Frame
            GlassOverlayFrame(hasDetectedObject: $viewModel.hasDetectedObject)

            // Object Bounding Boxes
            ForEach(viewModel.detectedObjects) { object in
                ObjectBoundingBox(object: object, imageSize: UIScreen.main.bounds.size)
            }

            // Barcode Indicator
            VStack {
                HStack {
                    Spacer()
                    BarcodeIndicator(barcodeDetected: .constant(viewModel.barcodeValue != nil))
                        .padding(.trailing, 52)
                }
                Spacer()
            }

            // Controls Overlay
            VStack {
                // Top Bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(16)

                    Spacer()
                }

                Spacer()

                // Bottom Controls
                VStack(spacing: 16) {
                    InstructionLabel(detectionState: viewModel.detectionState)

                    CaptureButton(
                        action: {
                            Task {
                                await viewModel.capturePhoto()
                            }
                        },
                        isCapturing: $viewModel.isCapturing,
                        isEnabled: .constant(viewModel.canCapture)
                    )
                }
                .padding(.bottom, 32)
            }
        }
        .alert(error: $viewModel.error)
    }
}
```

---

## Animations

### Camera Open Animation

- Camera preview fades in with brandDefault spring (0.4s response)
- Glass overlay frame fades in with brandGentle spring (0.3s delay)
- Instruction label slides up with brandBouncy spring (0.5s delay)

### Object Detection Animation

- Bounding boxes appear with brandSnappy spring (immediate response)
- Glow pulses with brandGentle spring (repeat forever, 1.5s cycle)
- Label fades in with brandDefault spring (0.2s delay)

### Barcode Detection Animation

- Indicator scales from 0.8 → 1.0 with brandBouncy spring
- Glow pulses with brandGentle spring (repeat forever, 1.0s cycle)
- Haptic feedback: `.success` on first detection

### Capture Animation

- Button scales to 0.9 with brandSnappy spring (0.1s)
- Camera shutter flash effect (white overlay, opacity 0 → 1 → 0, 0.2s)
- Screen freezes current frame for 0.3s before dismissing

---

## Accessibility

### VoiceOver

- **Camera preview**: "Camera preview. Point camera at household items to scan."
- **Glass overlay frame**: Hidden (decorative)
- **Object bounding boxes**: Announced as detected: "Backpack detected with 85% confidence."
- **Barcode indicator**: "Barcode detected" or "No barcode detected"
- **Capture button**: "Capture photo. Button. Captures photo of items in frame for AI cataloging."
- **Cancel button**: "Cancel. Button. Close camera without capturing."
- **Instruction label**: Announced dynamically based on detection state

### Dynamic Type

- All text scales from `.xSmall` to `.xxxLarge`
- Instruction label wraps to multiple lines if needed
- Bounding box labels remain legible at all sizes

### Reduce Transparency

- Glass overlay frame: Replace .thinMaterial with opaque `backgroundDefault` (#FCFCFF)
- Capture button: Replace .thickMaterial with opaque `backgroundDefault` with 10% black tint
- Instruction label: Replace .ultraThickMaterial with opaque `backgroundDefault`

### Reduce Motion

- Disable all spring animations, use `.linear(duration: 0.2)` fades instead
- Disable pulsing glow on barcode indicator
- Disable bounding box glow animation
- Keep capture button scale animation (essential feedback)

---

## Testing Checklist

### Functional Tests

- [ ] Camera preview displays at 30 FPS with < 500ms startup
- [ ] Glass overlay frame centered correctly on all device sizes (SE, Pro, Pro Max, iPad)
- [ ] Object bounding boxes match Vision Framework coordinates (pixel-perfect)
- [ ] Barcode indicator glows Mint Green when VNDetectBarcodesRequest succeeds
- [ ] Capture button triggers photo capture and calls `detectAndCropObjects`
- [ ] Cancel button dismisses camera view and returns to Catalog
- [ ] Instruction label updates based on detection state (no objects, object, barcode)
- [ ] Real-time detection processes frames at 10 FPS (throttled to 100ms intervals)
- [ ] Capture action uploads cropped objects to Firebase Storage
- [ ] Loading state displays while AI processes objects

### Accessibility Tests

- [ ] VoiceOver announces all interactive elements with descriptive labels
- [ ] VoiceOver reads detection state changes ("Object detected", "Barcode detected")
- [ ] All text scales correctly with Dynamic Type (XS to XXXL)
- [ ] Reduce Transparency replaces all materials with opaque backgrounds
- [ ] Reduce Motion disables decorative animations, keeps essential feedback
- [ ] Capture button has 80x80pt tap target (exceeds 44x44pt minimum)
- [ ] Cancel button has 44x44pt tap target

### Brand Compliance

- [ ] Glass overlay frame uses ConcentricRectangle on iOS 26, RoundedRectangle on iOS 25
- [ ] Capture button glow uses Bright Blue (#4381DF) with 12pt radius, 0.5 opacity
- [ ] Barcode indicator glow uses Mint Green (#B3FFE1) with 16pt radius, 0.6 opacity
- [ ] Object bounding boxes use Bright Blue (#4381DF) 2pt stroke
- [ ] All animations use brand spring presets (brandSnappy, brandBouncy, brandGentle)
- [ ] Typography uses SF Pro Rounded at specified weights
- [ ] Instruction label uses .secondary vibrancy on .ultraThickMaterial

### Performance Tests

- [ ] Camera preview maintains 30 FPS with real-time detection
- [ ] Frame processing throttled to 100ms intervals (10 FPS detection rate)
- [ ] Capture → cropped objects flow completes in < 2 seconds
- [ ] Memory usage remains below 200 MB during camera session
- [ ] No memory leaks when opening/closing camera repeatedly (Instruments Leaks tool)

---

## References

- **Architecture**: docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
- **Vision Framework**: docs/design/DESIGN-013-vision-framework-integration-patterns.md
- **Computer Vision Pipeline**: docs/design/DESIGN-004-computer-vision-pipeline.md
- **Component Library**: docs/design/DESIGN-031-swiftui-component-library.md (PrimaryButton, GlassOverlay)
- **Color System**: docs/design/DESIGN-032-color-system-design-tokens.md
- **Animation Presets**: docs/design/DESIGN-034-animation-motion-specifications.md
- **Onboarding Flow**: docs/design/DESIGN-026-onboarding-flow-ui-specification.md (Permissions)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial camera capture view specification | iOS UI/UX Designer |

---

**Status**: ✅ **APPROVED**

**Implementation Ready**: Camera view specified with AVFoundation integration, Vision Framework real-time detection, SwiftUI Liquid Glass UI, and complete accessibility support.
