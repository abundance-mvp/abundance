# View Spec: CaptureView

**Source:** `Sources/CameraFeature/Views/CaptureView.swift`
**Module:** CameraFeature
**Priority:** P0
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Camera background | `Color.black` | `#000000` | Full-screen camera bg |
| Error overlay bg | `black.opacity(0.6)` | — | Semi-transparent overlay |
| Cancel text | `.white` | — | Top bar text |
| Mode indicator text | `.white` | — | Status capsule text |
| Mode indicator bg | Glass / `black.opacity(0.6)` | — | iOS 26 glass, fallback opaque |
| Instruction text | `.secondary` | — | Bottom instruction label |
| Instruction bg | Glass / `.ultraThickMaterial` | — | iOS 26 glass, fallback material |
| Error overlay | (via `ErrorRecoveryView`) | — | Delegated to subview |
| Results view | (via `DetectionResultsView`) | — | Delegated to subview |

**Known violations:**
- None — camera views intentionally use black/white for viewfinder contrast

**Note:** Camera views are exempt from brand palette for the viewfinder layer. Overlays and chrome should use brand tokens where appropriate.

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Cancel button | "Cancel capture" | `.isButton` | 44×44pt (16pt padding) | Body |
| Cancel button hint | "Returns to catalog view" | — | — | — |
| Mode indicator | "Capture status: {text}" | `.updatesFrequently` | — | Caption semibold |
| Instruction label | (text content) | — | — | Subheadline |
| Double-tap gesture | — | — | Full screen | — |
| Long-press gesture | — | — | Full screen | — |
| Offline indicator | (via `OfflineModeIndicator`) | — | — | — |
| Error recovery | (via `ErrorRecoveryView`) | — | — | — |
| Retake button | "Retake" | `.isButton` | 44×44pt | Body |
| Done button | "Done" | `.isButton` | 44×44pt | Body |

**Concerns:**
- Double-tap and long-press gestures have no VoiceOver alternative — consider `.accessibilityAction` alternatives
- Instruction label "Double-tap to scan" may not be useful for VoiceOver users

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Mode indicator | `.glassEffect(in: Capsule())` | None | `Capsule().fill(.ultraThickMaterial)` |
| Instruction label | `.glassEffect(in: Capsule())` | None | `Capsule().fill(.ultraThickMaterial)` |
| Navigation bar | Hidden (`.navigationBarHidden(true)`) | — | — |

**Notes:**
- Both glass effects properly gated with `if #available(iOS 26.0, macOS 26.0, *)`
- Both respect `@Environment(\.accessibilityReduceTransparency)` — solid `black.opacity(0.6)` fallback
- Could use `adaptiveGlass(in: Capsule())` from `LiquidGlassHelpers.swift` instead of inline checks

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Camera preview | full screen | `.ignoresSafeArea()` |
| Frozen frame | full screen | `.ignoresSafeArea()` |
| Cancel button | padding | 16pt all sides |
| Mode indicator | padding | 16pt trailing |
| Offline indicator | top-right | trailing 16pt, top 60pt |
| Instruction label | bottom | 40pt from bottom |
| Results action buttons | spacing | 40pt between |
| Results action buttons | bottom | 40pt from bottom |
| Error overlay | centered | Scale + opacity transition |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Camera error show/hide | `.brandDefault` (reduce motion: `.brandReducedMotion`) | None | 500ms spring |
| Network status change | `.brandPress` (reduce motion: `.brandReducedMotion`) | None | 300ms spring |
| Error recovery overlay | `.scale + .opacity` | None | System |
| Single capture | — | `.impact(.medium)` | — |
| Burst end / Done | — | `.impact(.medium)` | — |

**Notes:**
- All animations respect `@Environment(\.accessibilityReduceMotion)` with `.brandReducedMotion` fallback
- Lines 193, 355: `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` — consider centralizing haptic calls in future

---

## State Machine

```
idle → capturing(count) → uploading(progress) → analyzing → results
                                                          → error
```

- `idle`: Live camera preview, gestures enabled
- `capturing(N)`: Burst mode counter visible
- `uploading(progress)`: Upload overlay
- `analyzing`: Analysis overlay
- `results`: Detection results or "no objects" view
- `error`: Error overlay with retry

## Subviews (referenced)

- `CameraPreviewView` — UIViewRepresentable for AVCaptureSession
- `DetectionResultsView` — Shows detected objects
- `NoObjectsDetectedView` — Empty results
- `ErrorRecoveryView` — Camera error recovery UI
- `CaptureOverlay` — Burst counter overlay
- `UploadingOverlay` — Upload progress
- `AnalyzingOverlay` — Analysis spinner
- `ErrorOverlay` — Inline error display
- `OfflineModeIndicator` — Network status chip
- `CaptureButtonStyle` — Primary/secondary button styling
