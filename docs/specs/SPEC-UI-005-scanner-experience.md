# SPEC-UI-005: Scanner Experience

**Document ID:** SPEC-UI-005
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Section 3.3 (The Intelligent Scanner)
- DESIGN-004 (Computer Vision Pipeline)
- ADR-013 (Vision Framework Strategy)

---

## Executive Summary

This specification defines the **scanning UX** for Abundance, including viewfinder design, recognition feedback, and success/error states optimized for Liquid Glass.

---

## 1. Viewfinder Design

### 1.1 Overlay Elements

Per Brand Bible 3.3 (soft glowing glass elements, not chrome brackets):

```swift
struct ScannerOverlay: View {
    @Binding var isScanning: Bool

    var body: some View {
        ZStack {
            // Scanning guide corners (soft glass, not hard chrome)
            ScannerCorners()

            // Active scanning indicator
            if isScanning {
                ScanningPulse()
            }

            // Bottom action area
            VStack {
                Spacer()
                ScannerControls()
            }
            .safeAreaPadding(.bottom, AbundanceSpacing.lg)
        }
    }
}

struct ScannerCorners: View {
    var body: some View {
        GeometryReader { geo in
            let cornerLength: CGFloat = 40
            let padding: CGFloat = 40

            // Top-left
            CornerShape(corner: .topLeading)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: padding + cornerLength/2, y: padding + cornerLength/2)

            // Top-right
            CornerShape(corner: .topTrailing)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: geo.size.width - padding - cornerLength/2, y: padding + cornerLength/2)

            // Bottom-left
            CornerShape(corner: .bottomLeading)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: padding + cornerLength/2, y: geo.size.height - padding - cornerLength/2)

            // Bottom-right
            CornerShape(corner: .bottomTrailing)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: geo.size.width - padding - cornerLength/2, y: geo.size.height - padding - cornerLength/2)
        }
    }
}
```

### 1.2 Active Scanning Indicator

```swift
struct ScanningPulse: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .stroke(Color.abundance.blue.opacity(0.3), lineWidth: 2)
            .frame(width: 200, height: 200)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            }
    }
}
```

---

## 2. Object Detection Feedback

### 2.1 Detected Object Highlight

Per Brand Bible 3.3 ("refractive glass frame"):

```swift
struct DetectedObjectOverlay: View {
    let boundingBox: CGRect
    let confidence: Float

    var body: some View {
        RoundedRectangle(cornerRadius: AbundanceRadius.medium)
            .stroke(
                Color.abundance.blue,
                lineWidth: confidence > 0.8 ? 3 : 2
            )
            .frame(width: boundingBox.width, height: boundingBox.height)
            .position(
                x: boundingBox.midX,
                y: boundingBox.midY
            )
            // Subtle glass effect on border
            .shadow(color: .abundance.blue.opacity(0.5), radius: 8)
    }
}
```

### 2.2 Confidence Indicator

```swift
struct ConfidenceIndicator: View {
    let confidence: Float

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
            Text("\(Int(confidence * 100))%")
                .font(.caption.bold())
        }
        .foregroundStyle(confidenceColor)
        .padding(.horizontal, AbundanceSpacing.sm)
        .padding(.vertical, AbundanceSpacing.xxs)
        .background(
            .thinMaterial,
            in: Capsule()
        )
    }

    private var confidenceIcon: String {
        confidence > 0.8 ? "checkmark.circle.fill" :
        confidence > 0.5 ? "circle.dashed" : "questionmark.circle"
    }

    private var confidenceColor: Color {
        confidence > 0.8 ? .abundance.mint :
        confidence > 0.5 ? .abundance.cream : .abundance.coral
    }
}
```

---

## 3. Success State

### 3.1 Recognition Success Animation

Per Brand Bible 3.3 ("glassy confetti-like particles"):

```swift
struct ScanSuccessView: View {
    let recognizedItem: RecognizedItem
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Glass frame around item
            RoundedRectangle(cornerRadius: AbundanceRadius.large)
                .stroke(Color.abundance.mint, lineWidth: 4)
                .frame(width: 200, height: 200)
                .shadow(color: .abundance.mint.opacity(0.5), radius: 12)

            // Confetti particles
            if showConfetti {
                ConfettiView(colors: [
                    .abundance.blue,
                    .abundance.coral,
                    .abundance.mint
                ])
            }

            // Success checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.abundance.mint)
                .offset(y: -120)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showConfetti = true
            }
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}
```

---

## 4. Error States

### 4.1 No Object Detected

```swift
struct NoObjectDetectedView: View {
    var body: some View {
        VStack(spacing: AbundanceSpacing.md) {
            Image(systemName: "viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)

            Text("No object detected")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Position an item within the frame")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(AbundanceSpacing.xl)
        .background(
            .thickMaterial,
            in: RoundedRectangle(cornerRadius: AbundanceRadius.large)
        )
    }
}
```

### 4.2 Camera Permission Denied

```swift
struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: AbundanceSpacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text("Camera Access Required")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("Abundance needs camera access to scan your items")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            AbundancePrimaryButton(title: "Open Settings", icon: "gear") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding(AbundanceSpacing.xxl)
    }
}
```

### 4.3 Lens Smudge Warning (iOS 26)

Per Brand Bible 3.3 (DetectLensSmudgeRequest):

```swift
struct LensSmudgeWarning: View {
    var body: some View {
        HStack(spacing: AbundanceSpacing.sm) {
            Image(systemName: "camera.aperture")
                .foregroundStyle(.abundance.coral)

            Text("Clean camera lens for better results")
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(AbundanceSpacing.sm)
        .background(
            .thinMaterial,
            in: Capsule()
        )
    }
}
```

---

## 5. Vision Framework Integration Points

### 5.1 Detection Request Types

| Request | Purpose | Brand Bible Reference |
|---------|---------|----------------------|
| `VNRecognizeTextRequest` | Read text on objects | Section 3.3 |
| `VNDetectBarcodesRequest` | Scan QR/barcodes | Section 3.3 |
| `VNCoreMLRequest` | Object classification | Section 3.3 |
| `DetectLensSmudgeRequest` | Camera quality check | Section 3.3 (iOS 26) |
| `DetectDocumentSegmentationRequest` | Document isolation | Section 3.3 (iOS 26) |

---

## 6. Acceptance Criteria

- [ ] Viewfinder uses soft glowing corners (not hard chrome brackets)
- [ ] Active scanning shows pulsing indicator
- [ ] Detected objects highlighted with glass frame effect
- [ ] Success state shows confetti animation with haptic
- [ ] Error states show pulsating icons (not static)
- [ ] Lens smudge detection implemented (iOS 26)
- [ ] All states accessible with VoiceOver

---

## 7. Test Plan

```swift
func testScannerAccessibility() {
    let app = XCUIApplication()
    app.launch()
    app.tabBars.buttons["Scan"].tap()

    // Verify scanner controls are accessible
    XCTAssertTrue(app.buttons["Capture"].exists)
    XCTAssertTrue(app.buttons["Capture"].isHittable)
}
```
