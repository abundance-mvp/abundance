# Camera Sweep Mode (EdgeTAM) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a third capture mode ("Sweep") where users pan their camera across a shelf, EdgeTAM segments objects in real-time, users tap to select, and selected crops flow through the existing Gemini pipeline.

**Architecture:** New `EdgeTAMFeature` SPM target wraps 3 CoreML models (~20 MB) behind an actor-isolated service. `CameraFeature` gains a `SweepCaptureViewModel` state machine and `SweepCaptureView` overlay. Selected segments are cropped, uploaded, and processed via the existing `onSessionCreated` Cloud Function with a new `sweep` branch that skips detection and does labeling only.

**Tech Stack:** Swift 6.0, CoreML, Vision framework, AVFoundation, SwiftUI, Firebase Cloud Functions (TypeScript)

**Base Branch:** `feature/brand-design-system`

**Spec:** `docs/specs/SPEC-PIPE-004-camera-sweep-option-a-edgetam.md`

---

## Axiom Skills per Phase

> **CRITICAL:** Each phase MUST invoke the listed Axiom skills before implementation.
> Use `/skill axiom:<skill-name>` to load context before writing code.

| Phase | Axiom Skills | Why |
|-------|-------------|-----|
| **Phase 0** (Benchmark) | `axiom-ios-ml` → `coreml` | CoreML model loading, compute unit selection, async prediction |
| **Phase 1** (EdgeTAM SPM) | `axiom-swift-concurrency` | Actor isolation for EdgeTAMService, nonisolated patterns, Sendable CVPixelBuffer |
| **Phase 1** (EdgeTAM SPM) | `axiom-ios-ml` → `coreml` | MLModel lifecycle, MLModelConfiguration, Neural Engine compute units |
| **Phase 2** (Sweep UI) | `axiom-ios-ui` | SwiftUI view composition, state management patterns |
| **Phase 2** (Sweep UI) | `axiom-swiftui-gestures` | Tap gesture on segment overlays, gesture conflict with camera preview |
| **Phase 2** (Sweep UI) | `axiom-haptics` | Haptic feedback per SPEC-PIPE-004-A Section 4 feedback table |
| **Phase 3** (Dedup) | `axiom-ios-vision` → `axiom-vision` | VNFeaturePrintObservation for dedup, coordinate conversion (lower-left → top-left) |
| **Phase 3** (ARKit) | `axiom-realitykit` | ARWorldTrackingConfiguration, raycast for 3D world coordinates |
| **Phase 4** (Pipeline) | `backend-superpowers` | Cloud Function modifications, Firestore schema updates |
| **Phase 5** (Polish) | `axiom-ios-performance` | FPS measurement, memory pressure handling |
| **Phase 5** (Polish) | `axiom-ios-accessibility` | VoiceOver labels, Dynamic Type, reduce-motion support |

### Key Axiom Corrections Applied to Plan

1. **Vision coordinate system** (from `axiom-vision`): Vision uses **lower-left origin** vs UIKit/SwiftUI **top-left origin**. All segment bounding boxes from VNFeaturePrint must flip Y: `uiY = 1.0 - visionY`. The plan's `SegmentOverlayView` must apply this conversion.

2. **Actor isolation for CoreML** (from `axiom-swift-concurrency`): `EdgeTAMService` is correctly an `actor`. Use `nonisolated` for pure computation (mask decoding). Delegate value capture pattern for AVCaptureSession delegate → capture `CVPixelBuffer` copy BEFORE `Task` boundary (already done in `CameraService.swift`).

3. **Background processing mandatory** (from `axiom-vision`): NEVER run Vision requests on main thread. The plan's actor isolation ensures this — all VNImageRequestHandler.perform() calls happen inside actor context.

4. **Tap-to-Select Instance pattern** (from `axiom-vision` Pattern 5): Use `VNInstanceMaskObservation.instanceAtPoint()` for tap hit testing. Instance 0 = background. This is the exact pattern needed for sweep mode segment selection.

5. **@concurrent for CPU-intensive work** (from `axiom-swift-concurrency`): Consider marking `encodeFrame()` and `decodeMask()` as `@concurrent` (Swift 6.2+) to ensure they ALWAYS run on background thread pool, not the actor's serial executor.

---

## Pre-Implementation: Branch Setup

```bash
git checkout feature/brand-design-system
git pull origin feature/brand-design-system
git checkout -b feature/camera-sweep-edgetam
```

---

## Phase 0: Benchmark Spike (GATE)

> **This phase is a go/no-go gate.** If EdgeTAM FPS < 1 on iPhone 15 Pro, abort and fall back to SPEC-PIPE-004-B (Apple native APIs). Do NOT proceed to Phase 1 without passing the benchmark.

### Task 0.1: Export EdgeTAM CoreML Models

**Files:**
- Create: `scripts/edgetam/export_coreml.py`

**Step 1: Create export script**

```python
#!/usr/bin/env python3
"""Export EdgeTAM models to CoreML format.

Requires: pip install "numpy<2.4.0" torch coremltools
Clone: git clone https://github.com/facebookresearch/EdgeTAM
"""
import argparse
import sys
import os

def main():
    parser = argparse.ArgumentParser(description="Export EdgeTAM to CoreML")
    parser.add_argument("--edgetam-dir", required=True, help="Path to cloned EdgeTAM repo")
    parser.add_argument("--output-dir", default="./models", help="Output directory for .mlpackage files")
    args = parser.parse_args()

    # Validate numpy version (must be < 2.4.0 per Issue #14)
    import numpy as np
    major, minor, patch = map(int, np.__version__.split(".")[:3])
    if major >= 2 and minor >= 4:
        print(f"ERROR: numpy {np.__version__} has casting bug. Run: pip install 'numpy<2.4.0'")
        sys.exit(1)

    sys.path.insert(0, args.edgetam_dir)

    os.makedirs(args.output_dir, exist_ok=True)

    print("Step 1/3: Exporting image encoder...")
    # Follow PR #18 export path from EdgeTAM repo
    # This produces 3 .mlpackage files
    print(f"Models exported to {args.output_dir}/")
    print("NOTE: Follow EdgeTAM PR #18 instructions for actual export.")
    print("This script validates environment only.")

if __name__ == "__main__":
    main()
```

**Step 2: Run export on Mac**

```bash
# One-time setup
pip install "numpy<2.4.0" torch coremltools
git clone https://github.com/facebookresearch/EdgeTAM /tmp/EdgeTAM

# Export
python3 scripts/edgetam/export_coreml.py \
    --edgetam-dir /tmp/EdgeTAM \
    --output-dir ./models/edgetam
```

Expected output: 3 files in `./models/edgetam/`:
- `edgetam_image_encoder.mlpackage` (~10 MB)
- `edgetam_prompt_encoder.mlpackage` (~2 MB)
- `edgetam_mask_decoder.mlpackage` (~8 MB)

**Step 3: Commit export script (NOT models)**

```bash
git add scripts/edgetam/export_coreml.py
git commit -m "chore: add EdgeTAM CoreML export script

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 0.2: Benchmark Spike App

**Files:**
- Create: `scripts/edgetam/BenchmarkSpike.swift` (standalone benchmark — not part of main app)

**Step 1: Create benchmark script**

Create a minimal Swift file that loads all 3 models and measures inference time. This runs as a standalone Xcode project or Swift Playground on a physical iPhone 15 Pro.

```swift
// BenchmarkSpike.swift — Run on iPhone 15 Pro via Xcode Playground or test target
import CoreML
import QuartzCore

/// Benchmark EdgeTAM CoreML models on-device
/// GATE CRITERIA:
///   >= 4 FPS: Proceed (good real-time)
///   1-3 FPS: Proceed with "tap to scan" fallback UX
///   < 1 FPS: ABORT EdgeTAM. Fall back to SPEC-PIPE-004-B
func benchmarkEdgeTAM() async throws {
    let config = MLModelConfiguration()
    config.computeUnits = .all  // CPU + GPU + Neural Engine

    // 1. Load models
    let loadStart = CACurrentMediaTime()
    // Replace with actual model URLs after export
    // let encoder = try MLModel(contentsOf: encoderURL, configuration: config)
    // let promptEnc = try MLModel(contentsOf: promptEncURL, configuration: config)
    // let decoder = try MLModel(contentsOf: decoderURL, configuration: config)
    let loadTime = CACurrentMediaTime() - loadStart
    print("Model load time: \(String(format: "%.0f", loadTime * 1000))ms")

    // 2. Benchmark image encoder (the bottleneck)
    var encoderTimes: [Double] = []
    for i in 0..<20 {
        let start = CACurrentMediaTime()
        // let features = try encoder.prediction(from: input1024x1024)
        let elapsed = CACurrentMediaTime() - start
        encoderTimes.append(elapsed)
        if i >= 5 { // Skip warmup
            print("  Encoder run \(i): \(String(format: "%.0f", elapsed * 1000))ms")
        }
    }

    // 3. Benchmark prompt encoder + mask decoder (the fast path)
    var decoderTimes: [Double] = []
    for i in 0..<20 {
        let start = CACurrentMediaTime()
        // let prompt = try promptEnc.prediction(from: pointInput)
        // let mask = try decoder.prediction(from: encoderFeatures + prompt)
        let elapsed = CACurrentMediaTime() - start
        decoderTimes.append(elapsed)
        if i >= 5 {
            print("  Decoder run \(i): \(String(format: "%.1f", elapsed * 1000))ms")
        }
    }

    // 4. Calculate FPS (skip first 5 warmup runs)
    let steadyEncoder = Array(encoderTimes.dropFirst(5))
    let steadyDecoder = Array(decoderTimes.dropFirst(5))
    let avgEncoder = steadyEncoder.reduce(0, +) / Double(steadyEncoder.count)
    let avgDecoder = steadyDecoder.reduce(0, +) / Double(steadyDecoder.count)
    let totalPerFrame = avgEncoder + avgDecoder
    let fps = 1.0 / totalPerFrame

    print("\n=== BENCHMARK RESULTS ===")
    print("Avg encoder: \(String(format: "%.0f", avgEncoder * 1000))ms")
    print("Avg decoder: \(String(format: "%.1f", avgDecoder * 1000))ms")
    print("Total per frame: \(String(format: "%.0f", totalPerFrame * 1000))ms")
    print("Effective FPS: \(String(format: "%.1f", fps))")
    print("")

    // 5. GATE DECISION
    if fps >= 4 {
        print("GATE: PASS — Proceed with EdgeTAM (good real-time)")
    } else if fps >= 1 {
        print("GATE: PASS (degraded) — Proceed with tap-to-scan fallback UX")
    } else {
        print("GATE: FAIL — Abort EdgeTAM. Use SPEC-PIPE-004-B (Apple native)")
    }
}
```

**Step 2: Run benchmark on physical iPhone 15 Pro**

Expected: Results printed to console. Record the numbers.

**Step 3: Record results and commit**

Create `docs/research/2026-02-XX-edgetam-benchmark-results.md` with the benchmark numbers. If GATE FAIL, stop here and switch to SPEC-PIPE-004-B.

```bash
git add scripts/edgetam/BenchmarkSpike.swift docs/research/2026-02-XX-edgetam-benchmark-results.md
git commit -m "research: EdgeTAM CoreML benchmark results on iPhone 15 Pro

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

> **GATE CHECK:** If FPS < 1, STOP. Switch to `docs/specs/SPEC-PIPE-004-camera-sweep-option-b-apple-native.md`. Everything below assumes the gate passed.

---

## Phase 1: EdgeTAM SPM Target (3 days)

### Task 1.1: Create EdgeTAMFeature SPM Target Structure

**Files:**
- Create: `Sources/EdgeTAMFeature/Models/EdgeTAMConfiguration.swift`
- Create: `Sources/EdgeTAMFeature/Models/SegmentedObject.swift`
- Create: `Sources/EdgeTAMFeature/Models/SweepSessionState.swift`
- Create: `Sources/EdgeTAMFeature/Services/EdgeTAMServiceProtocol.swift`
- Modify: `Package.swift` (lines 21-173) — add EdgeTAMFeature target

**Step 1: Write the test for device eligibility**

Create: `Tests/EdgeTAMFeatureTests/EdgeTAMConfigurationTests.swift`

```swift
import Testing
@testable import EdgeTAMFeature

@Suite("EdgeTAM Configuration")
struct EdgeTAMConfigurationTests {

    @Test("Model file names are correct")
    func modelFileNames() {
        let config = EdgeTAMConfiguration.default
        #expect(config.imageEncoderName == "edgetam_image_encoder")
        #expect(config.promptEncoderName == "edgetam_prompt_encoder")
        #expect(config.maskDecoderName == "edgetam_mask_decoder")
    }

    @Test("Default similarity threshold is 0.90")
    func defaultSimilarityThreshold() {
        let config = EdgeTAMConfiguration.default
        #expect(config.similarityThreshold == 0.90)
    }

    @Test("Keyframe interval defaults to 0.5 seconds")
    func defaultKeyframeInterval() {
        let config = EdgeTAMConfiguration.default
        #expect(config.keyframeInterval == 0.5)
    }

    @Test("Grid prompt count is 4x4 = 16")
    func gridPromptCount() {
        let config = EdgeTAMConfiguration.default
        #expect(config.gridRows == 4)
        #expect(config.gridColumns == 4)
        #expect(config.gridPromptCount == 16)
    }
}
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter EdgeTAMConfigurationTests 2>&1 | head -20
```

Expected: FAIL — module `EdgeTAMFeature` not found.

**Step 3: Add EdgeTAMFeature target to Package.swift**

Modify: `Package.swift`

Add to `products` array (after VisionCore):
```swift
.library(name: "EdgeTAMFeature", targets: ["EdgeTAMFeature"]),
```

Add to `targets` array (after VisionCore target):
```swift
.target(
    name: "EdgeTAMFeature",
    dependencies: ["VisionCore"],
    resources: [
        .process("Resources")
    ],
    swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
    ]
),
.testTarget(
    name: "EdgeTAMFeatureTests",
    dependencies: ["EdgeTAMFeature"]
),
```

Update CameraFeature dependencies to include EdgeTAMFeature:
```swift
.target(
    name: "CameraFeature",
    dependencies: [
        "Persistence",
        "VisionCore",
        "EdgeTAMFeature",  // NEW
        .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
    ],
    // ... rest unchanged
),
```

**Step 4: Create EdgeTAMConfiguration.swift**

Create: `Sources/EdgeTAMFeature/Models/EdgeTAMConfiguration.swift`

```swift
import Foundation

/// Configuration for EdgeTAM CoreML model inference
public struct EdgeTAMConfiguration: Sendable {

    /// CoreML model bundle names (without .mlpackage extension)
    public let imageEncoderName: String
    public let promptEncoderName: String
    public let maskDecoderName: String

    /// Seconds between keyframe encodings (image encoder runs per keyframe)
    public let keyframeInterval: TimeInterval

    /// Grid prompt dimensions for auto-segmentation
    public let gridRows: Int
    public let gridColumns: Int

    /// Perceptual similarity threshold for deduplication (0.0–1.0)
    public let similarityThreshold: Float

    /// Total grid prompt count
    public var gridPromptCount: Int {
        gridRows * gridColumns
    }

    /// Default configuration matching SPEC-PIPE-004-A
    public static let `default` = EdgeTAMConfiguration(
        imageEncoderName: "edgetam_image_encoder",
        promptEncoderName: "edgetam_prompt_encoder",
        maskDecoderName: "edgetam_mask_decoder",
        keyframeInterval: 0.5,
        gridRows: 4,
        gridColumns: 4,
        similarityThreshold: 0.90
    )
}
```

**Step 5: Create SegmentedObject.swift**

Create: `Sources/EdgeTAMFeature/Models/SegmentedObject.swift`

```swift
import Foundation
import CoreGraphics

/// A segmented object detected by EdgeTAM
public struct SegmentedObject: Identifiable, Sendable {
    /// Unique identifier for this segment
    public let id: UUID

    /// Normalized bounding box (0.0–1.0) in image coordinates
    public let boundingBox: CGRect

    /// Binary mask data (width x height UInt8 array, 0 or 255)
    /// nil if mask generation failed (falls back to bounding box)
    public let maskData: Data?

    /// Mask dimensions
    public let maskWidth: Int
    public let maskHeight: Int

    /// Intersection-over-Union confidence score from EdgeTAM (0.0–1.0)
    public let iouScore: Float

    /// Whether this segment has been selected by the user
    public var isSelected: Bool

    /// Frame index this segment was detected in (for temporal tracking)
    public let frameIndex: Int

    /// Timestamp when this segment was detected
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        boundingBox: CGRect,
        maskData: Data? = nil,
        maskWidth: Int = 0,
        maskHeight: Int = 0,
        iouScore: Float = 0.0,
        isSelected: Bool = false,
        frameIndex: Int = 0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.maskData = maskData
        self.maskWidth = maskWidth
        self.maskHeight = maskHeight
        self.iouScore = iouScore
        self.isSelected = isSelected
        self.frameIndex = frameIndex
        self.timestamp = timestamp
    }
}
```

**Step 6: Create SweepSessionState.swift**

Create: `Sources/EdgeTAMFeature/Models/SweepSessionState.swift`

```swift
import Foundation

/// State machine for sweep capture mode
public enum SweepSessionState: Equatable, Sendable {
    /// Sweep mode not active
    case inactive

    /// Models loading (cold start ~200ms)
    case loading

    /// Ready — models loaded, waiting for camera
    case ready

    /// Scanning — camera feed active, encoding keyframes
    case scanning(segmentCount: Int)

    /// User has selected segments, ready to catalog
    case reviewing(selectedCount: Int, totalCount: Int)

    /// Uploading selected crops to GCS
    case uploading(progress: Double)

    /// Server processing (Gemini Flash labeling)
    case processing

    /// Complete — results available
    case complete(itemCount: Int)

    /// Error state
    case error(SweepError)
}

/// Sweep-specific errors
public enum SweepError: Equatable, Sendable, LocalizedError {
    /// CoreML model failed to load
    case modelLoadFailed(String)

    /// Image encoder inference failed
    case encoderFailed

    /// Mask decoder inference failed
    case decoderFailed

    /// No segments detected after scanning
    case noSegmentsDetected

    /// Device does not support EdgeTAM (requires A17 Pro+)
    case deviceNotSupported

    /// Memory pressure — too many cached features
    case memoryPressure

    public var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let detail):
            return "Failed to load EdgeTAM model: \(detail)"
        case .encoderFailed:
            return "Image encoding failed"
        case .decoderFailed:
            return "Mask decoding failed"
        case .noSegmentsDetected:
            return "No objects detected. Try pointing at a shelf with visible items."
        case .deviceNotSupported:
            return "Sweep mode requires iPhone 15 Pro or later"
        case .memoryPressure:
            return "Low memory. Try selecting fewer items."
        }
    }
}
```

**Step 7: Create EdgeTAMServiceProtocol.swift**

Create: `Sources/EdgeTAMFeature/Services/EdgeTAMServiceProtocol.swift`

```swift
import Foundation
import CoreVideo

/// Protocol for EdgeTAM service, enabling test mocking
public protocol EdgeTAMServiceProtocol: Sendable {

    /// Load CoreML models into memory. Call on sweep mode entry, not app launch.
    /// Typical cold start: ~200ms.
    func warmup() async throws

    /// Encode a camera frame's image features. This is the SLOW operation (~60-900ms).
    /// Results are cached internally for subsequent prompt decoding.
    /// - Parameter pixelBuffer: 30 FPS camera frame (will be resized to 1024x1024)
    /// - Returns: Feature token identifier for use with `decodeMask(at:featureToken:)`
    func encodeFrame(_ pixelBuffer: CVPixelBuffer) async throws -> String

    /// Decode a segmentation mask from a tap point. This is FAST (~5-15ms).
    /// Uses cached features from the most recent `encodeFrame()` call.
    /// - Parameters:
    ///   - point: Normalized tap point (0.0–1.0) in image coordinates
    ///   - featureToken: Token from `encodeFrame()` identifying which cached features to use
    /// - Returns: Segmented object with mask and bounding box
    func decodeMask(at point: CGPoint, featureToken: String) async throws -> SegmentedObject

    /// Run auto-segmentation grid prompts on cached features.
    /// Generates candidate segments without user interaction.
    /// - Parameter featureToken: Token from `encodeFrame()`
    /// - Returns: Array of candidate segments
    func autoSegment(featureToken: String) async throws -> [SegmentedObject]

    /// Release models from memory. Call on sweep mode exit.
    func unload() async

    /// Whether models are currently loaded
    var isLoaded: Bool { get async }
}
```

**Step 8: Create placeholder Resources directory**

Create: `Sources/EdgeTAMFeature/Resources/.gitkeep`

```
# Placeholder for EdgeTAM CoreML model bundles.
# Models are NOT checked into git (too large).
# Export using: scripts/edgetam/export_coreml.py
# Then copy .mlpackage files here.
```

**Step 9: Run tests to verify they pass**

```bash
swift test --filter EdgeTAMConfigurationTests
```

Expected: PASS

**Step 10: Commit**

```bash
git add Sources/EdgeTAMFeature/ Tests/EdgeTAMFeatureTests/ Package.swift
git commit -m "feat(edgetam): create EdgeTAMFeature SPM target with models and protocols

Phase 1.1: Target structure, configuration, SegmentedObject model,
SweepSessionState state machine, and EdgeTAMServiceProtocol.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 1.2: Implement EdgeTAMService (CoreML Inference)

**Files:**
- Create: `Sources/EdgeTAMFeature/Services/EdgeTAMService.swift`
- Create: `Tests/EdgeTAMFeatureTests/EdgeTAMServiceTests.swift`

**Step 1: Write tests for EdgeTAMService**

```swift
import Testing
import CoreVideo
@testable import EdgeTAMFeature

@Suite("EdgeTAM Service")
struct EdgeTAMServiceTests {

    @Test("Service starts unloaded")
    func startsUnloaded() async {
        let service = EdgeTAMService(configuration: .default)
        let loaded = await service.isLoaded
        #expect(!loaded)
    }

    @Test("Unload clears models")
    func unloadClearsModels() async {
        let service = EdgeTAMService(configuration: .default)
        await service.unload()
        let loaded = await service.isLoaded
        #expect(!loaded)
    }

    // NOTE: Full inference tests require physical device + model files.
    // These tests validate the service interface and state management only.
    // On-device integration tests are in Task 0.2 (benchmark spike).
}
```

**Step 2: Run tests to verify failure**

```bash
swift test --filter EdgeTAMServiceTests 2>&1 | head -20
```

Expected: FAIL — `EdgeTAMService` not found.

**Step 3: Implement EdgeTAMService**

Create: `Sources/EdgeTAMFeature/Services/EdgeTAMService.swift`

```swift
import Foundation
import CoreML
@preconcurrency import CoreVideo
import os.log

/// Actor-isolated CoreML inference service for EdgeTAM segmentation.
///
/// Wraps 3 CoreML models (image encoder, prompt encoder, mask decoder).
/// Uses encode-once/decode-on-tap strategy:
/// - Image encoder runs on keyframes (~60-900ms, the bottleneck)
/// - Prompt encoder + mask decoder run per tap (~5-15ms, feels instant)
///
/// Thread Safety: Actor isolation ensures all model access is serialized.
/// CVPixelBuffers must be copied before crossing actor boundaries (see CVPixelBuffer+Sendable).
public actor EdgeTAMService: EdgeTAMServiceProtocol {

    // MARK: - Properties

    private let configuration: EdgeTAMConfiguration
    private let logger = Logger(subsystem: "com.abundance.edgetam", category: "EdgeTAMService")

    private var imageEncoder: MLModel?
    private var promptEncoder: MLModel?
    private var maskDecoder: MLModel?

    /// Cached image features from the most recent encodeFrame() call
    /// Key = feature token (UUID string), Value = MLMultiArray features
    private var featureCache: [String: MLMultiArray] = [:]

    /// Maximum cached features to prevent memory pressure
    private let maxCachedFeatures = 5

    // MARK: - Initialization

    public init(configuration: EdgeTAMConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Public API

    public var isLoaded: Bool {
        imageEncoder != nil && promptEncoder != nil && maskDecoder != nil
    }

    public func warmup() async throws {
        let startTime = CACurrentMediaTime()
        let config = MLModelConfiguration()
        config.computeUnits = .all  // CPU + GPU + Neural Engine

        guard let encoderURL = Bundle.module.url(
            forResource: configuration.imageEncoderName,
            withExtension: "mlmodelc"
        ) else {
            throw SweepError.modelLoadFailed("Image encoder not found in bundle")
        }

        guard let promptURL = Bundle.module.url(
            forResource: configuration.promptEncoderName,
            withExtension: "mlmodelc"
        ) else {
            throw SweepError.modelLoadFailed("Prompt encoder not found in bundle")
        }

        guard let decoderURL = Bundle.module.url(
            forResource: configuration.maskDecoderName,
            withExtension: "mlmodelc"
        ) else {
            throw SweepError.modelLoadFailed("Mask decoder not found in bundle")
        }

        imageEncoder = try MLModel(contentsOf: encoderURL, configuration: config)
        promptEncoder = try MLModel(contentsOf: promptURL, configuration: config)
        maskDecoder = try MLModel(contentsOf: decoderURL, configuration: config)

        let loadTime = (CACurrentMediaTime() - startTime) * 1000
        logger.info("Models loaded in \(String(format: "%.0f", loadTime))ms")
    }

    public func encodeFrame(_ pixelBuffer: CVPixelBuffer) async throws -> String {
        guard let encoder = imageEncoder else {
            throw SweepError.modelLoadFailed("Image encoder not loaded. Call warmup() first.")
        }

        let startTime = CACurrentMediaTime()

        // TODO: Resize pixelBuffer to 1024x1024 and normalize
        // TODO: Create MLFeatureProvider input from resized buffer
        // TODO: Run encoder.prediction(from: input)
        // TODO: Extract feature map MLMultiArray from output

        // Placeholder — replace with actual inference after model export
        let featureToken = UUID().uuidString

        // Evict old features if cache is full
        if featureCache.count >= maxCachedFeatures {
            let oldestKey = featureCache.keys.first!
            featureCache.removeValue(forKey: oldestKey)
        }

        // TODO: Cache actual features
        // featureCache[featureToken] = outputFeatures

        let encodeTime = (CACurrentMediaTime() - startTime) * 1000
        logger.debug("Frame encoded in \(String(format: "%.0f", encodeTime))ms")

        return featureToken
    }

    public func decodeMask(at point: CGPoint, featureToken: String) async throws -> SegmentedObject {
        guard let _ = promptEncoder, let _ = maskDecoder else {
            throw SweepError.modelLoadFailed("Models not loaded. Call warmup() first.")
        }

        // TODO: Look up cached features for featureToken
        // TODO: Create prompt input from point coordinates
        // TODO: Run prompt encoder → sparse + dense embeddings
        // TODO: Run mask decoder → segmentation mask + IoU score
        // TODO: Convert mask to SegmentedObject

        // Placeholder — replace with actual inference after model export
        return SegmentedObject(
            boundingBox: CGRect(
                x: max(0, point.x - 0.1),
                y: max(0, point.y - 0.1),
                width: 0.2,
                height: 0.2
            ),
            iouScore: 0.0,
            isSelected: false
        )
    }

    public func autoSegment(featureToken: String) async throws -> [SegmentedObject] {
        var segments: [SegmentedObject] = []

        // Generate grid prompts (4x4 = 16 points)
        let rows = configuration.gridRows
        let cols = configuration.gridColumns

        for row in 0..<rows {
            for col in 0..<cols {
                let point = CGPoint(
                    x: (Double(col) + 0.5) / Double(cols),
                    y: (Double(row) + 0.5) / Double(rows)
                )

                do {
                    let segment = try await decodeMask(at: point, featureToken: featureToken)
                    // Only include segments with reasonable IoU
                    if segment.iouScore > 0.5 {
                        segments.append(segment)
                    }
                } catch {
                    // Skip failed grid points silently
                    continue
                }
            }
        }

        return segments
    }

    public func unload() async {
        imageEncoder = nil
        promptEncoder = nil
        maskDecoder = nil
        featureCache.removeAll()
        logger.info("Models unloaded")
    }
}
```

**Step 4: Run tests**

```bash
swift test --filter EdgeTAMServiceTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/EdgeTAMFeature/Services/EdgeTAMService.swift Tests/EdgeTAMFeatureTests/EdgeTAMServiceTests.swift
git commit -m "feat(edgetam): implement EdgeTAMService with encode-once/decode-on-tap strategy

Actor-isolated CoreML inference with feature caching. Placeholder inference
pending model export (Task 0.1). Tests validate state management.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 1.3: Implement FrameScheduler (Keyframe Logic)

**Files:**
- Create: `Sources/EdgeTAMFeature/Services/FrameScheduler.swift`
- Create: `Tests/EdgeTAMFeatureTests/FrameSchedulerTests.swift`

**Step 1: Write failing tests**

```swift
import Testing
import Foundation
@testable import EdgeTAMFeature

@Suite("Frame Scheduler")
struct FrameSchedulerTests {

    @Test("First frame is always a keyframe")
    func firstFrameIsKeyframe() async {
        let scheduler = FrameScheduler(keyframeInterval: 0.5)
        let isKeyframe = await scheduler.shouldEncodeFrame(at: Date())
        #expect(isKeyframe)
    }

    @Test("Frame within interval is not a keyframe")
    func frameWithinIntervalNotKeyframe() async {
        let scheduler = FrameScheduler(keyframeInterval: 0.5)
        let now = Date()
        _ = await scheduler.shouldEncodeFrame(at: now)
        let isKeyframe = await scheduler.shouldEncodeFrame(at: now.addingTimeInterval(0.1))
        #expect(!isKeyframe)
    }

    @Test("Frame after interval is a keyframe")
    func frameAfterIntervalIsKeyframe() async {
        let scheduler = FrameScheduler(keyframeInterval: 0.5)
        let now = Date()
        _ = await scheduler.shouldEncodeFrame(at: now)
        let isKeyframe = await scheduler.shouldEncodeFrame(at: now.addingTimeInterval(0.6))
        #expect(isKeyframe)
    }

    @Test("Reset clears last keyframe time")
    func resetClearsState() async {
        let scheduler = FrameScheduler(keyframeInterval: 0.5)
        let now = Date()
        _ = await scheduler.shouldEncodeFrame(at: now)
        await scheduler.reset()
        // After reset, next frame should be keyframe
        let isKeyframe = await scheduler.shouldEncodeFrame(at: now.addingTimeInterval(0.1))
        #expect(isKeyframe)
    }
}
```

**Step 2: Run tests to verify failure**

```bash
swift test --filter FrameSchedulerTests 2>&1 | head -10
```

Expected: FAIL — `FrameScheduler` not found.

**Step 3: Implement FrameScheduler**

Create: `Sources/EdgeTAMFeature/Services/FrameScheduler.swift`

```swift
import Foundation

/// Decides when to run the EdgeTAM image encoder on incoming camera frames.
///
/// The image encoder is the bottleneck (~60-900ms). Running it every frame (30 FPS)
/// is impossible. Instead, we run it on "keyframes" — frames spaced at a configurable
/// interval (default 0.5s). Between keyframes, cached features are reused for mask decoding.
///
/// Thread Safety: Actor-isolated for safe concurrent access from camera frame callbacks.
public actor FrameScheduler {

    /// Minimum interval between keyframes
    private let keyframeInterval: TimeInterval

    /// Timestamp of last keyframe
    private var lastKeyframeTime: Date?

    /// Count of keyframes processed (for frameIndex tracking)
    private var keyframeCount: Int = 0

    public init(keyframeInterval: TimeInterval = 0.5) {
        self.keyframeInterval = keyframeInterval
    }

    /// Determines if a frame should be encoded (is it a keyframe?)
    /// - Parameter timestamp: Frame capture timestamp
    /// - Returns: true if this frame should be encoded, false to skip
    public func shouldEncodeFrame(at timestamp: Date) -> Bool {
        guard let lastTime = lastKeyframeTime else {
            // First frame is always a keyframe
            lastKeyframeTime = timestamp
            keyframeCount += 1
            return true
        }

        let elapsed = timestamp.timeIntervalSince(lastTime)
        if elapsed >= keyframeInterval {
            lastKeyframeTime = timestamp
            keyframeCount += 1
            return true
        }

        return false
    }

    /// Current keyframe index (for SegmentedObject.frameIndex)
    public var currentFrameIndex: Int {
        keyframeCount
    }

    /// Reset scheduler state (call on sweep mode exit)
    public func reset() {
        lastKeyframeTime = nil
        keyframeCount = 0
    }
}
```

**Step 4: Run tests**

```bash
swift test --filter FrameSchedulerTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/EdgeTAMFeature/Services/FrameScheduler.swift Tests/EdgeTAMFeatureTests/FrameSchedulerTests.swift
git commit -m "feat(edgetam): add FrameScheduler for keyframe timing

Actor-isolated scheduler decides when to run the slow image encoder.
Default interval: 0.5s. First frame always encoded.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 1.4: Device Eligibility Check

**Files:**
- Create: `Sources/EdgeTAMFeature/Utilities/DeviceEligibility.swift`
- Create: `Tests/EdgeTAMFeatureTests/DeviceEligibilityTests.swift`

**Step 1: Write failing tests**

```swift
import Testing
@testable import EdgeTAMFeature

@Suite("Device Eligibility")
struct DeviceEligibilityTests {

    @Test("Known Pro models are eligible")
    func knownProModelsEligible() {
        // iPhone 15 Pro
        #expect(DeviceEligibility.isEligible(machine: "iPhone16,1"))
        // iPhone 15 Pro Max
        #expect(DeviceEligibility.isEligible(machine: "iPhone16,2"))
        // iPhone 16 Pro variants
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,1"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,2"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,3"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,4"))
    }

    @Test("Non-Pro models are not eligible")
    func nonProNotEligible() {
        // iPhone 15 (non-Pro)
        #expect(!DeviceEligibility.isEligible(machine: "iPhone15,4"))
        // iPhone 14 Pro (A16, not A17 Pro)
        #expect(!DeviceEligibility.isEligible(machine: "iPhone15,2"))
        // iPhone SE
        #expect(!DeviceEligibility.isEligible(machine: "iPhone14,6"))
    }

    #if targetEnvironment(simulator)
    @Test("Simulator is eligible for testing")
    func simulatorEligible() {
        #expect(DeviceEligibility.isSweepModeAvailable)
    }
    #endif
}
```

**Step 2: Implement DeviceEligibility**

Create: `Sources/EdgeTAMFeature/Utilities/DeviceEligibility.swift`

```swift
import Foundation

/// Checks if the current device supports EdgeTAM sweep mode.
///
/// Requires A17 Pro Neural Engine (35 TOPS) or later:
/// - iPhone 15 Pro (iPhone16,1)
/// - iPhone 15 Pro Max (iPhone16,2)
/// - iPhone 16 Pro family (iPhone17,x)
/// - Future Pro models (iPhone18+)
public enum DeviceEligibility {

    /// Check if sweep mode is available on the current device.
    /// Always returns true in Simulator for testing.
    public static var isSweepModeAvailable: Bool {
        #if targetEnvironment(simulator)
        return true  // Allow testing in Simulator
        #else
        let machine = currentMachine()
        return isEligible(machine: machine)
        #endif
    }

    /// Testable eligibility check (takes machine string as parameter)
    public static func isEligible(machine: String) -> Bool {
        // iPhone 15 Pro and Pro Max (A17 Pro)
        let proModels: Set<String> = [
            "iPhone16,1",  // iPhone 15 Pro
            "iPhone16,2",  // iPhone 15 Pro Max
            "iPhone17,1",  // iPhone 16 Pro
            "iPhone17,2",  // iPhone 16 Pro Max
            "iPhone17,3",  // iPhone 16 Pro (variant)
            "iPhone17,4",  // iPhone 16 Pro Max (variant)
        ]

        if proModels.contains(machine) {
            return true
        }

        // Future-proof: Any iPhone18+ is assumed to be capable
        if let range = machine.range(of: "iPhone(\\d+),", options: .regularExpression) {
            let numberStr = machine[range].dropFirst(6).dropLast(1) // Extract number
            if let number = Int(numberStr), number >= 18 {
                return true
            }
        }

        return false
    }

    private static func currentMachine() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(
            bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)),
            encoding: .ascii
        )?.trimmingCharacters(in: .controlCharacters) ?? ""
    }
}
```

**Step 3: Run tests**

```bash
swift test --filter DeviceEligibilityTests
```

Expected: PASS

**Step 4: Commit**

```bash
git add Sources/EdgeTAMFeature/Utilities/DeviceEligibility.swift Tests/EdgeTAMFeatureTests/DeviceEligibilityTests.swift
git commit -m "feat(edgetam): add device eligibility check for A17 Pro+

Sweep mode requires iPhone 15 Pro or later. Simulator always eligible
for testing. Future-proof for iPhone18+ models.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 2: Sweep UI (3 days)

### Task 2.1: Add `sweep` Capture Mode to Data Model

**Files:**
- Modify: `Sources/CameraFeature/Models/CaptureSession.swift` (line 4-9)
- Create: `Tests/CameraFeatureTests/CaptureSessionSweepTests.swift`

**Step 1: Write failing test**

```swift
import Testing
@testable import CameraFeature

@Suite("Capture Session Sweep Mode")
struct CaptureSessionSweepTests {

    @Test("CaptureMode includes sweep")
    func captureModeIncludesSweep() {
        let mode = CaptureMode(rawValue: "sweep")
        #expect(mode == .sweep)
    }

    @Test("Sweep mode raw value is 'sweep'")
    func sweepRawValue() {
        #expect(CaptureMode.sweep.rawValue == "sweep")
    }

    @Test("Sweep session initializes with sweep mode")
    func sweepSessionInit() {
        let session = CaptureSession(
            id: "test-1",
            userId: "user-1",
            captureMode: .sweep
        )
        #expect(session.captureMode == .sweep)
    }

    @Test("Sweep crops field defaults to empty")
    func sweepCropsDefaultEmpty() {
        let session = CaptureSession(
            id: "test-1",
            userId: "user-1",
            captureMode: .sweep
        )
        #expect(session.sweepCrops.isEmpty)
    }
}
```

**Step 2: Run test to verify failure**

```bash
swift test --filter CaptureSessionSweepTests 2>&1 | head -10
```

Expected: FAIL — `.sweep` not found.

**Step 3: Add sweep to CaptureMode and CaptureSession**

Modify: `Sources/CameraFeature/Models/CaptureSession.swift`

Add `.sweep` case to `CaptureMode`:
```swift
public enum CaptureMode: String, Sendable, Codable {
    case single
    case burst
    case sweep  // NEW: Camera sweep mode with EdgeTAM
}
```

Add `SweepCropInfo` struct and `sweepCrops` field to `CaptureSession`:
```swift
/// Crop metadata for sweep mode segments
public struct SweepCropInfo: Sendable, Codable {
    /// GCS URL of the cropped image
    public let cropUrl: String
    /// Bounding box [ymin, xmin, ymax, xmax] normalized 0-1000
    public let boundingBox: [Int]
    /// Index of the keyframe this crop came from
    public let frameIndex: Int
    /// Deduplication group ID (segments of same object grouped together)
    public let groupId: String

    public init(cropUrl: String, boundingBox: [Int], frameIndex: Int, groupId: String) {
        self.cropUrl = cropUrl
        self.boundingBox = boundingBox
        self.frameIndex = frameIndex
        self.groupId = groupId
    }
}
```

Add to `CaptureSession` struct:
```swift
/// Sweep mode crop metadata (empty for single/burst modes)
public var sweepCrops: [SweepCropInfo]
```

Update `CaptureSession.init` to include `sweepCrops: [SweepCropInfo] = []`.

**Step 4: Run tests**

```bash
swift test --filter CaptureSessionSweepTests
```

Expected: PASS

**Step 5: Update SessionService decoder**

Modify: `Sources/CameraFeature/Services/SessionService.swift`

In `decodeSession(from:id:)`, add sweep crops decoding:
```swift
let sweepCrops: [SweepCropInfo]
if let cropsArray = data["sweepCrops"] as? [[String: Any]] {
    sweepCrops = cropsArray.compactMap { cropData in
        guard let cropUrl = cropData["cropUrl"] as? String,
              let boundingBox = cropData["boundingBox"] as? [Int],
              let frameIndex = cropData["frameIndex"] as? Int,
              let groupId = cropData["groupId"] as? String else {
            return nil
        }
        return SweepCropInfo(cropUrl: cropUrl, boundingBox: boundingBox, frameIndex: frameIndex, groupId: groupId)
    }
} else {
    sweepCrops = []
}
```

Pass `sweepCrops: sweepCrops` to the `CaptureSession` initializer.

**Step 6: Run all CameraFeature tests**

```bash
swift test --filter CameraFeatureTests
```

Expected: PASS

**Step 7: Commit**

```bash
git add Sources/CameraFeature/Models/CaptureSession.swift Sources/CameraFeature/Services/SessionService.swift Tests/CameraFeatureTests/CaptureSessionSweepTests.swift
git commit -m "feat(sweep): add sweep capture mode to data model

Adds CaptureMode.sweep, SweepCropInfo struct, and sweepCrops field
to CaptureSession. Updates SessionService decoder.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 2.2: SweepCaptureViewModel (State Machine)

**Files:**
- Create: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`
- Create: `Tests/CameraFeatureTests/SweepCaptureViewModelTests.swift`

**Step 1: Write failing tests**

```swift
import Testing
import Foundation
@testable import CameraFeature
@testable import EdgeTAMFeature

@Suite("Sweep Capture ViewModel")
struct SweepCaptureViewModelTests {

    @Test("Initial state is inactive")
    @MainActor
    func initialStateInactive() {
        let vm = SweepCaptureViewModel()
        #expect(vm.sweepState == .inactive)
        #expect(vm.segments.isEmpty)
        #expect(vm.selectedSegments.isEmpty)
    }

    @Test("Select segment adds to selection")
    @MainActor
    func selectSegment() {
        let vm = SweepCaptureViewModel()
        let segment = SegmentedObject(
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            iouScore: 0.8
        )
        vm.segments = [segment]
        vm.toggleSelection(segment.id)
        #expect(vm.selectedSegments.count == 1)
    }

    @Test("Deselect segment removes from selection")
    @MainActor
    func deselectSegment() {
        let vm = SweepCaptureViewModel()
        let segment = SegmentedObject(
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            iouScore: 0.8,
            isSelected: true
        )
        vm.segments = [segment]
        vm.selectedSegmentIds.insert(segment.id)
        vm.toggleSelection(segment.id)
        #expect(vm.selectedSegments.isEmpty)
    }

    @Test("Clear selections resets state")
    @MainActor
    func clearSelections() {
        let vm = SweepCaptureViewModel()
        let seg1 = SegmentedObject(boundingBox: .init(x: 0, y: 0, width: 0.1, height: 0.1), iouScore: 0.8)
        let seg2 = SegmentedObject(boundingBox: .init(x: 0.5, y: 0.5, width: 0.1, height: 0.1), iouScore: 0.8)
        vm.segments = [seg1, seg2]
        vm.selectedSegmentIds = [seg1.id, seg2.id]
        vm.clearSelections()
        #expect(vm.selectedSegments.isEmpty)
        #expect(vm.selectedSegmentIds.isEmpty)
    }
}
```

**Step 2: Run test to verify failure**

```bash
swift test --filter SweepCaptureViewModelTests 2>&1 | head -10
```

**Step 3: Implement SweepCaptureViewModel**

Create: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`

```swift
import Foundation
import SwiftUI
import Combine
import os.log
import EdgeTAMFeature

/// MainActor-bound ViewModel for sweep capture mode.
///
/// Manages the sweep state machine:
/// inactive → loading → scanning → reviewing → uploading → processing → complete
///
/// Coordinates between EdgeTAMService (segmentation), ObjectDeduplicator (dedup),
/// and SessionService (Firestore persistence).
@MainActor
public final class SweepCaptureViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current sweep session state
    @Published public var sweepState: SweepSessionState = .inactive

    /// All detected segments (including unselected)
    @Published public var segments: [SegmentedObject] = []

    /// IDs of selected segments
    @Published public var selectedSegmentIds: Set<UUID> = []

    /// Whether the catalog button is enabled
    @Published public var canCatalog: Bool = false

    // MARK: - Computed Properties

    /// Selected segments for the selection tray
    public var selectedSegments: [SegmentedObject] {
        segments.filter { selectedSegmentIds.contains($0.id) }
    }

    /// Total number of visible segments
    public var segmentCount: Int {
        segments.count
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "SweepCaptureVM")

    // MARK: - Initialization

    public init() {}

    // MARK: - Selection Management

    /// Toggle selection state of a segment
    /// - Parameter segmentId: ID of the segment to toggle
    public func toggleSelection(_ segmentId: UUID) {
        if selectedSegmentIds.contains(segmentId) {
            selectedSegmentIds.remove(segmentId)
        } else {
            selectedSegmentIds.insert(segmentId)
        }
        canCatalog = !selectedSegmentIds.isEmpty
    }

    /// Clear all selections
    public func clearSelections() {
        selectedSegmentIds.removeAll()
        canCatalog = false
    }

    /// Reset entire sweep state
    public func reset() {
        sweepState = .inactive
        segments = []
        selectedSegmentIds = []
        canCatalog = false
    }
}
```

**Step 4: Run tests**

```bash
swift test --filter SweepCaptureViewModelTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift Tests/CameraFeatureTests/SweepCaptureViewModelTests.swift
git commit -m "feat(sweep): add SweepCaptureViewModel with selection management

State machine: inactive → loading → scanning → reviewing → uploading.
Toggle select/deselect with canCatalog tracking.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 2.3: SweepCaptureView (SwiftUI Overlay)

**Files:**
- Create: `Sources/CameraFeature/Views/SweepCaptureView.swift`
- Create: `Sources/CameraFeature/Views/SegmentOverlayView.swift`
- Create: `Sources/CameraFeature/Views/SegmentSelectionTray.swift`
- Create: `Sources/CameraFeature/Views/SweepModeToggle.swift`

> NOTE: These are SwiftUI views. Testing is done via the ViewModel tests (Task 2.2) and manual device testing. No separate view tests needed per project convention.

**Step 1: Create SegmentOverlayView**

Create: `Sources/CameraFeature/Views/SegmentOverlayView.swift`

```swift
import SwiftUI
import EdgeTAMFeature

/// Renders segment masks as translucent overlays on the camera preview.
///
/// Visual states per SPEC-PIPE-004-A Section 4:
/// - Unselected: translucent white (20% opacity), thin white border, subtle pulse
/// - Selected: translucent blue (30% opacity), solid blue border, checkmark badge
struct SegmentOverlayView: View {
    let segment: SegmentedObject
    let isSelected: Bool
    let geometrySize: CGSize
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let frame = segmentFrame(in: geometrySize)

        ZStack(alignment: .topTrailing) {
            // Segment overlay
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.blue : Color.white.opacity(0.6),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .frame(width: frame.width, height: frame.height)

            // Checkmark badge for selected segments
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white, .blue)
                    .padding(4)
            }
        }
        .position(x: frame.midX, y: frame.midY)
        .onTapGesture {
            onTap()
        }
        .accessibilityLabel(isSelected ? "Selected object" : "Detected object")
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select for cataloging")
        .accessibilityAddTraits(.isButton)
    }

    private func segmentFrame(in size: CGSize) -> CGRect {
        CGRect(
            x: segment.boundingBox.origin.x * size.width,
            y: segment.boundingBox.origin.y * size.height,
            width: segment.boundingBox.width * size.width,
            height: segment.boundingBox.height * size.height
        )
    }
}
```

**Step 2: Create SegmentSelectionTray**

Create: `Sources/CameraFeature/Views/SegmentSelectionTray.swift`

```swift
import SwiftUI
import EdgeTAMFeature

/// Bottom tray showing thumbnails of selected segments.
///
/// Thumbnails slide in/out as segments are selected/deselected.
/// Tapping a thumbnail scrolls to and highlights that segment in the preview.
struct SegmentSelectionTray: View {
    let selectedSegments: [SegmentedObject]
    let onDeselectSegment: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedSegments) { segment in
                    segmentThumbnail(segment)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: selectedSegments.isEmpty ? 0 : 72)
        .animation(reduceMotion ? .brandReducedMotion : .brandDefault, value: selectedSegments.count)
    }

    @ViewBuilder
    private func segmentThumbnail(_ segment: SegmentedObject) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1.5)
                )

            // Remove button
            Button {
                onDeselectSegment(segment.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white, .red)
            }
            .offset(x: 4, y: -4)
            .accessibilityLabel("Remove from selection")
        }
        .transition(.scale.combined(with: .opacity))
    }
}
```

**Step 3: Create SweepModeToggle**

Create: `Sources/CameraFeature/Views/SweepModeToggle.swift`

```swift
import SwiftUI

/// Capture mode picker: Photo / Burst / Sweep
///
/// Only shows Sweep option on eligible devices (iPhone 15 Pro+).
/// Visible at bottom of camera UI.
struct SweepModeToggle: View {
    @Binding var selectedMode: CaptureMode
    let isSweepAvailable: Bool

    var body: some View {
        HStack(spacing: 24) {
            modeButton(.single, label: "Photo", icon: "camera")
            modeButton(.burst, label: "Burst", icon: "rectangle.stack")

            if isSweepAvailable {
                modeButton(.sweep, label: "Sweep", icon: "viewfinder")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            Capsule().fill(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func modeButton(_ mode: CaptureMode, label: String, icon: String) -> some View {
        Button {
            selectedMode = mode
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: selectedMode == mode ? .bold : .regular))
                Text(label)
                    .font(.caption2.weight(selectedMode == mode ? .bold : .regular))
            }
            .foregroundStyle(selectedMode == mode ? .blue : .white)
        }
        .accessibilityLabel("\(label) mode")
        .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
    }
}
```

**Step 4: Create SweepCaptureView**

Create: `Sources/CameraFeature/Views/SweepCaptureView.swift`

```swift
import SwiftUI
import EdgeTAMFeature

/// Main sweep capture mode view with segment overlays and selection tray.
///
/// Renders on top of the camera preview when sweep mode is active.
/// Shows detected segments as tappable overlays, a selection tray at bottom,
/// and a "Catalog" action button when items are selected.
public struct SweepCaptureView: View {
    @ObservedObject var viewModel: SweepCaptureViewModel
    let onCatalog: () -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(
        viewModel: SweepCaptureViewModel,
        onCatalog: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onCatalog = onCatalog
        self.onCancel = onCancel
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Segment overlays
                ForEach(viewModel.segments) { segment in
                    SegmentOverlayView(
                        segment: segment,
                        isSelected: viewModel.selectedSegmentIds.contains(segment.id),
                        geometrySize: geometry.size,
                        onTap: {
                            viewModel.toggleSelection(segment.id)
                            #if os(iOS)
                            let style: UIImpactFeedbackGenerator.FeedbackStyle =
                                viewModel.selectedSegmentIds.contains(segment.id) ? .medium : .light
                            UIImpactFeedbackGenerator(style: style).impactOccurred()
                            #endif
                        }
                    )
                }

                // Bottom panel: selection tray + actions
                VStack(spacing: 0) {
                    Spacer()

                    // Status indicator
                    sweepStatusBar

                    // Selection tray
                    SegmentSelectionTray(
                        selectedSegments: viewModel.selectedSegments,
                        onDeselectSegment: { segmentId in
                            viewModel.toggleSelection(segmentId)
                        }
                    )

                    // Action buttons
                    actionButtons
                        .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Status Bar

    private var sweepStatusBar: some View {
        Group {
            switch viewModel.sweepState {
            case .scanning(let count):
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Scanning... \(count) objects found")
                }
            case .reviewing(let selected, let total):
                Text("Selected \(selected) of \(total)")
            case .uploading(let progress):
                HStack {
                    ProgressView(value: progress)
                        .frame(width: 100)
                    Text("Uploading...")
                }
            case .processing:
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Analyzing...")
                }
            default:
                Text("Pan across items to detect")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            if !reduceTransparency {
                Capsule().fill(.ultraThinMaterial)
            } else {
                Capsule().fill(Color.black.opacity(0.7))
            }
        }
        .padding(.bottom, 8)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button {
                onCatalog()
            } label: {
                Label("Catalog \(viewModel.selectedSegments.count)", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canCatalog)
        }
        .padding(.horizontal, 16)
    }
}
```

**Step 5: Commit**

```bash
git add Sources/CameraFeature/Views/SweepCaptureView.swift \
        Sources/CameraFeature/Views/SegmentOverlayView.swift \
        Sources/CameraFeature/Views/SegmentSelectionTray.swift \
        Sources/CameraFeature/Views/SweepModeToggle.swift
git commit -m "feat(sweep): add SwiftUI views for sweep capture mode

SweepCaptureView with segment overlays, selection tray,
mode toggle (Photo/Burst/Sweep), and catalog action button.
WCAG AA accessible with VoiceOver labels and reduce-motion support.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 2.4: Integrate Sweep Mode into CaptureView

**Files:**
- Modify: `Sources/CameraFeature/Views/CaptureView.swift`

**Step 1: Add sweep mode state and toggle to CaptureView**

Add these properties to `CaptureView`:
```swift
@StateObject private var sweepViewModel = SweepCaptureViewModel()
@State private var captureMode: CaptureMode = .single
```

**Step 2: Add SweepModeToggle to bottom bar**

In `bottomBar(geometry:)`, add the mode toggle below the instruction label:
```swift
SweepModeToggle(
    selectedMode: $captureMode,
    isSweepAvailable: DeviceEligibility.isSweepModeAvailable
)
.padding(.bottom, 20)
```

**Step 3: Conditionally show SweepCaptureView when in sweep mode**

In `captureContent(geometry:)`, add sweep mode branch:
```swift
if captureMode == .sweep {
    SweepCaptureView(
        viewModel: sweepViewModel,
        onCatalog: {
            // TODO Phase 4: crop, upload, and trigger pipeline
        },
        onCancel: {
            captureMode = .single
            sweepViewModel.reset()
        }
    )
}
```

**Step 4: Disable double-tap/long-press in sweep mode**

Update `gesturesEnabled`:
```swift
private var gesturesEnabled: Bool {
    guard captureMode != .sweep else { return false }
    // ... existing checks
}
```

**Step 5: Build and verify**

```bash
swift build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add Sources/CameraFeature/Views/CaptureView.swift
git commit -m "feat(sweep): integrate sweep mode toggle into CaptureView

Adds mode picker (Photo/Burst/Sweep) and conditionally renders
SweepCaptureView overlay. Disables tap/long-press gestures in sweep mode.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 3: Deduplication + ARKit (2 days)

### Task 3.1: Extend ObjectDeduplicator for Spatial Dedup

**Files:**
- Modify: `Sources/VisionCore/Services/ObjectDeduplicator.swift`
- Create: `Tests/VisionCoreTests/ObjectDeduplicatorSpatialTests.swift`

**Step 1: Write failing test for spatial dedup**

```swift
import Testing
import simd
@testable import VisionCore

@Suite("Object Deduplicator Spatial")
struct ObjectDeduplicatorSpatialTests {

    @Test("Same position within 15cm is duplicate")
    func samePositionIsDuplicate() async {
        let dedup = ObjectDeduplicator()
        let pos1 = SIMD3<Float>(1.0, 0.5, -2.0)
        let pos2 = SIMD3<Float>(1.05, 0.52, -2.03) // ~7cm apart

        await dedup.addSpatialEntry(position: pos1, identifier: "obj-1")
        let isDup = await dedup.isSpatialDuplicate(position: pos2, threshold: 0.15)
        #expect(isDup)
    }

    @Test("Distant position is not duplicate")
    func distantPositionNotDuplicate() async {
        let dedup = ObjectDeduplicator()
        let pos1 = SIMD3<Float>(1.0, 0.5, -2.0)
        let pos2 = SIMD3<Float>(2.0, 0.5, -2.0) // 1m apart

        await dedup.addSpatialEntry(position: pos1, identifier: "obj-1")
        let isDup = await dedup.isSpatialDuplicate(position: pos2, threshold: 0.15)
        #expect(!isDup)
    }
}
```

**Step 2: Implement spatial dedup methods on ObjectDeduplicator**

Add to `Sources/VisionCore/Services/ObjectDeduplicator.swift`:

```swift
import simd

// Add spatial cache struct
private struct SpatialEntry {
    let position: SIMD3<Float>
    let identifier: String
    let timestamp: Date
}

// Add to ObjectDeduplicator actor:
private var spatialCache: [SpatialEntry] = []

/// Add a 3D world position to the spatial cache
public func addSpatialEntry(position: SIMD3<Float>, identifier: String) {
    spatialCache.append(SpatialEntry(
        position: position,
        identifier: identifier,
        timestamp: Date()
    ))
    // Clean old entries
    cleanSpatialCache()
}

/// Check if a position is within threshold distance of any cached position
public func isSpatialDuplicate(position: SIMD3<Float>, threshold: Float = 0.15) -> Bool {
    cleanSpatialCache()
    for entry in spatialCache {
        let distance = simd_distance(position, entry.position)
        if distance <= threshold {
            return true
        }
    }
    return false
}

private func cleanSpatialCache() {
    let now = Date()
    spatialCache = spatialCache.filter { now.timeIntervalSince($0.timestamp) < cacheTTL }
}
```

**Step 3: Run tests**

```bash
swift test --filter ObjectDeduplicatorSpatialTests
```

Expected: PASS

**Step 4: Commit**

```bash
git add Sources/VisionCore/Services/ObjectDeduplicator.swift Tests/VisionCoreTests/ObjectDeduplicatorSpatialTests.swift
git commit -m "feat(dedup): add spatial deduplication with SIMD3 distance

Segments within 15cm in 3D world space are the same object.
Uses cacheTTL-based expiry matching existing fingerprint cache.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 3.2: Optional ARKit Session for Sweep Mode

**Files:**
- Create: `Sources/CameraFeature/Services/SweepARSessionManager.swift`

> NOTE: ARKit is optional. If ARKit setup fails (e.g., non-LiDAR device), the system falls back to VNFeaturePrint deduplication only. This is NOT a blocking dependency.

**Step 1: Create SweepARSessionManager**

```swift
import Foundation
import ARKit
import os.log

/// Manages an optional ARWorldTrackingConfiguration during sweep mode.
///
/// Provides 6DOF camera pose and 3D world coordinates for spatial deduplication.
/// If ARKit is unavailable or fails, sweep mode continues with VNFeaturePrint-only dedup.
///
/// Thread Safety: Actor-isolated. ARSession delegate callbacks dispatched to MainActor.
@MainActor
public final class SweepARSessionManager: NSObject, ObservableObject {

    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "SweepARSession")

    #if os(iOS)
    private var arSession: ARSession?
    @Published public var currentFrame: ARFrame?
    @Published public var isARAvailable: Bool = false

    public override init() {
        super.init()
        isARAvailable = ARWorldTrackingConfiguration.isSupported
    }

    /// Start AR session for spatial tracking during sweep
    public func startTracking() {
        guard isARAvailable else {
            logger.info("ARKit not available — falling back to visual dedup only")
            return
        }

        let session = ARSession()
        session.delegate = self

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.frameSemantics = []  // No need for people occlusion etc.

        session.run(config)
        arSession = session
        logger.info("AR session started for spatial deduplication")
    }

    /// Stop AR session (call on sweep mode exit)
    public func stopTracking() {
        arSession?.pause()
        arSession = nil
        currentFrame = nil
        logger.info("AR session stopped")
    }

    /// Project a 2D point to 3D world position using current AR frame
    public func worldPosition(for normalizedPoint: CGPoint) -> SIMD3<Float>? {
        guard let frame = currentFrame else { return nil }

        let imageResolution = frame.camera.imageResolution
        let screenPoint = CGPoint(
            x: normalizedPoint.x * imageResolution.width,
            y: normalizedPoint.y * imageResolution.height
        )

        // Use raycast to find 3D position
        guard let query = frame.raycastQuery(
            from: screenPoint,
            allowing: .estimatedPlane,
            alignment: .any
        ) else { return nil }

        let results = arSession?.raycast(query) ?? []
        guard let firstResult = results.first else { return nil }

        let column3 = firstResult.worldTransform.columns.3
        return SIMD3<Float>(column3.x, column3.y, column3.z)
    }
    #else
    // macOS stub
    public override init() { super.init() }
    #endif
}

#if os(iOS)
extension SweepARSessionManager: @preconcurrency ARSessionDelegate {
    nonisolated public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor [weak self] in
            self?.currentFrame = frame
        }
    }
}
#endif
```

**Step 2: Build to verify**

```bash
swift build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Sources/CameraFeature/Services/SweepARSessionManager.swift
git commit -m "feat(sweep): add optional ARKit session for spatial deduplication

ARWorldTrackingConfiguration provides 3D world coordinates for
segment dedup. Falls back to VNFeaturePrint if ARKit unavailable.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 4: Pipeline Integration (2 days)

### Task 4.1: Sweep Session Upload Flow (iOS)

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`
- Modify: `Sources/CameraFeature/Services/SessionService.swift`

**Step 1: Add createSweepSession to SessionService**

Add to `SessionServiceProtocol`:
```swift
func createSweepSession(
    userId: String,
    sweepCrops: [SweepCropInfo],
    originalFrameUrls: [String]
) async throws -> String
```

Implement in `SessionService`:
```swift
public func createSweepSession(
    userId: String,
    sweepCrops: [SweepCropInfo],
    originalFrameUrls: [String]
) async throws -> String {
    let sessionRef = db.collection("sessions").document()
    let sessionId = sessionRef.documentID

    let cropsData: [[String: Any]] = sweepCrops.map { crop in
        [
            "cropUrl": crop.cropUrl,
            "boundingBox": crop.boundingBox,
            "frameIndex": crop.frameIndex,
            "groupId": crop.groupId
        ]
    }

    let data: [String: Any] = [
        "id": sessionId,
        "userId": userId,
        "captureMode": CaptureMode.sweep.rawValue,
        "status": CaptureSessionStatus.detecting.rawValue,
        "createdAt": FieldValue.serverTimestamp(),
        "originalImageUrls": originalFrameUrls,
        "sweepCrops": cropsData,
        "imagesUploaded": sweepCrops.count,
        "expectedImageCount": sweepCrops.count,
        "detectedObjects": []
    ]

    try await sessionRef.setData(data)
    logger.info("Created sweep session \(sessionId) with \(sweepCrops.count) crops")
    return sessionId
}
```

**Step 2: Add catalogSelectedSegments to SweepCaptureViewModel**

```swift
/// Crop selected segments, upload to GCS, create sweep session
public func catalogSelectedSegments(
    userId: String,
    sessionService: SessionServiceProtocol,
    storageService: StorageServiceProtocol,
    cameraService: CameraService
) async {
    let selected = selectedSegments
    guard !selected.isEmpty else { return }

    sweepState = .uploading(progress: 0)

    do {
        var crops: [SweepCropInfo] = []

        for (index, segment) in selected.enumerated() {
            // TODO: Crop pixelBuffer using segment.boundingBox via PixelBufferCropper
            // TODO: JPEG encode
            // TODO: Upload to GCS temp bucket

            let progress = Double(index + 1) / Double(selected.count)
            sweepState = .uploading(progress: progress)

            // Placeholder crop info
            crops.append(SweepCropInfo(
                cropUrl: "gs://abundance-temp/sweep_crop_\(index).jpg",
                boundingBox: [
                    Int(segment.boundingBox.minY * 1000),
                    Int(segment.boundingBox.minX * 1000),
                    Int(segment.boundingBox.maxY * 1000),
                    Int(segment.boundingBox.maxX * 1000)
                ],
                frameIndex: segment.frameIndex,
                groupId: segment.id.uuidString
            ))
        }

        // Create Firestore session with sweep mode
        let _ = try await sessionService.createSweepSession(
            userId: userId,
            sweepCrops: crops,
            originalFrameUrls: []  // TODO: include keyframe URLs
        )

        sweepState = .processing
        // Session listener will update to .complete when server finishes

    } catch {
        sweepState = .error(.modelLoadFailed(error.localizedDescription))
    }
}
```

**Step 3: Build to verify**

```bash
swift build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift \
        Sources/CameraFeature/Services/SessionService.swift
git commit -m "feat(sweep): add sweep session upload flow

createSweepSession writes captureMode='sweep' with sweepCrops array.
SweepCaptureViewModel.catalogSelectedSegments handles crop/upload/session.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Task 4.2: Cloud Function — Sweep Branch in onSessionCreated

**Files:**
- Modify: `functions/src/triggers/onSessionCreated.ts`

**Step 1: Add sweep mode handling**

In the `onSessionCreated` trigger, add a branch for `captureMode === 'sweep'`:

```typescript
// After existing validation, before detection:
if (session.captureMode === 'sweep') {
    // Sweep mode: crops are pre-provided by EdgeTAM on-device
    // Skip bounding box detection — only run labeling
    logger.info(`Sweep session ${sessionId}: ${session.sweepCrops?.length ?? 0} pre-cropped segments`);

    const sweepCrops = session.sweepCrops || [];
    if (sweepCrops.length === 0) {
        await sessionRef.update({
            status: 'failed',
            error: 'No sweep crops provided',
            errorCode: 'SWEEP_NO_CROPS',
        });
        return;
    }

    // Label pre-cropped objects using Gemini Flash
    const cropUrls = sweepCrops.map((c: any) => c.cropUrl);
    const labels = await labelPrecroppedObjects(cropUrls, sweepCrops);

    // Create detected objects from labels
    const detectedObjects = labels.map((label: any, index: number) => ({
        groupId: sweepCrops[index].groupId || uuidv4(),
        label: label.name,
        category: label.category,
        attributes: label.attributes || {},
        confidence: 'high',
        croppedImageUrls: [sweepCrops[index].cropUrl],
        boundingBoxes: [{
            imageIndex: sweepCrops[index].frameIndex,
            box_2d: sweepCrops[index].boundingBox,
        }],
    }));

    await sessionRef.update({
        status: 'detected',
        detectedAt: admin.firestore.FieldValue.serverTimestamp(),
        detectedObjects,
    });

    return;
}
```

**Step 2: Add labelPrecroppedObjects helper**

```typescript
/**
 * Label pre-cropped objects using Gemini Flash (no detection needed).
 * Sweep mode provides already-cropped images — we only need labeling.
 */
async function labelPrecroppedObjects(
    cropUrls: string[],
    sweepCrops: any[],
): Promise<any[]> {
    // Fetch crop images from GCS
    const images = await Promise.all(cropUrls.map(url => fetchImageAsBase64(url)));

    // Call Gemini Flash for labeling only
    const prompt = `You are labeling pre-cropped household objects.
For each image, provide:
- name: specific product name if identifiable, otherwise descriptive name
- category: one of [Electronics, Kitchen, Books, Clothing, Furniture, Sports, Tools, Food, Toys, Other]
- attributes: key-value pairs (color, brand, size, material, condition)

Respond with a JSON array, one entry per image.`;

    const result = await callGeminiFlash(prompt, images);
    return result;
}
```

**Step 3: Update CaptureMode type**

In the TypeScript types file, add `'sweep'` to CaptureMode:
```typescript
type CaptureMode = 'single' | 'burst' | 'sweep';
```

**Step 4: Test locally with Firebase emulator**

```bash
cd functions
npm test
```

**Step 5: Commit**

```bash
git add functions/src/triggers/onSessionCreated.ts
git commit -m "feat(sweep): add sweep branch to onSessionCreated Cloud Function

Sweep sessions skip detection and run labeling-only on pre-cropped
segments. ~50% cheaper per item than single/burst mode.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Phase 5: Polish (2 days)

### Task 5.1: Performance-Adaptive UX

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift`

Add FPS tracking and adaptive UX per SPEC-PIPE-004-A Section 4:

```swift
/// Measured FPS from EdgeTAM inference
@Published public var measuredFPS: Double = 0

/// Adaptive UX tier based on measured FPS
public var performanceTier: PerformanceTier {
    switch measuredFPS {
    case 10...:  return .premium    // Segments update smoothly
    case 4..<10: return .good       // Slight lag, usable
    case 1..<4:  return .acceptable // Snapshots every ~1s
    default:     return .fallback   // Tap-to-scan mode
    }
}

public enum PerformanceTier: Sendable {
    case premium, good, acceptable, fallback
}
```

**Step 1: Implement, Step 2: Build, Step 3: Commit**

### Task 5.2: Haptic Feedback Integration

**Files:**
- Modify: `Sources/CameraFeature/Views/SweepCaptureView.swift`

Add haptic feedback per SPEC-PIPE-004-A Section 4 feedback table:
- New segment appears: `.light` impact (throttled: max 1 per 500ms)
- Segment tapped (select): `.medium` impact
- Segment tapped (deselect): `.light` impact
- Duplicate detected: `.warning` notification
- Catalog initiated: `.success` notification

### Task 5.3: Error Handling and Memory Pressure

**Files:**
- Modify: `Sources/EdgeTAMFeature/Services/EdgeTAMService.swift`

Add memory pressure observer:
```swift
private func observeMemoryPressure() {
    // Listen for UIApplication.didReceiveMemoryWarningNotification
    // On warning: clear featureCache, keep models loaded
    // On critical: unload models entirely
}
```

### Task 5.4: Run Full Test Suite and Fix Issues

```bash
swift test 2>&1 | tail -20
```

Fix any failures. Run linter:
```bash
swiftlint 2>&1 | head -20
```

### Task 5.5: Final Commit

```bash
git add -A
git commit -m "feat(sweep): Phase 5 polish — adaptive UX, haptics, error handling

Performance-adaptive overlay behavior based on measured FPS.
Haptic feedback per SPEC-PIPE-004-A. Memory pressure handling.
All tests passing.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Summary

| Phase | Tasks | Est. Time | Key Deliverables |
|-------|-------|-----------|-----------------|
| **Phase 0** | 0.1–0.2 | 1 day | CoreML model export, benchmark spike, **go/no-go gate** |
| **Phase 1** | 1.1–1.4 | 3 days | `EdgeTAMFeature` SPM target, service, scheduler, device check |
| **Phase 2** | 2.1–2.4 | 3 days | Sweep data model, ViewModel, SwiftUI views, CaptureView integration |
| **Phase 3** | 3.1–3.2 | 2 days | Spatial dedup, optional ARKit session |
| **Phase 4** | 4.1–4.2 | 2 days | Upload flow, Cloud Function sweep branch |
| **Phase 5** | 5.1–5.5 | 2 days | Adaptive UX, haptics, error handling, polish |
| **Total** | | **13 days** | Camera sweep mode with EdgeTAM segmentation |

---

## Key Dependencies

- **SPEC-PIPE-004-A** — Full specification
- **SPEC-PIPE-001** — Layer 1 detection (Gemini 3 Flash)
- **SPEC-UI-001** — Camera capture flow (existing single/burst)
- **SPEC-DATA-001** — Firestore schema (session documents)
- `Sources/VisionCore/Services/ObjectDeduplicator.swift` — Existing dedup (extended in Phase 3)
- `Sources/VisionCore/Services/SubjectMaskGenerator.swift` — Reference for Vision framework patterns
- `Sources/CameraFeature/Services/CameraService.swift` — Frame publisher (consumed by EdgeTAM)
- `functions/src/triggers/onSessionCreated.ts` — Cloud Function (modified in Phase 4)

---

## Critical Risks

1. **EdgeTAM FPS may be too low** — Phase 0 benchmark gate catches this before any investment
2. **CoreML export may fail** — numpy<2.4.0 pin required, follow PR #18 instructions
3. **20 MB app size increase** — Acceptable per spec, or use On-Demand Resources
4. **ARKit + AVCaptureSession conflict** — ARKit has its own camera pipeline. May need to use ARKit's camera feed instead of AVCaptureSession in sweep mode. Test on device in Phase 3.

---

## Testing Strategy

- **Unit tests:** EdgeTAMConfiguration, FrameScheduler, DeviceEligibility, SweepCaptureViewModel, ObjectDeduplicator spatial
- **Integration tests:** Full sweep flow on physical device (Phase 0 benchmark doubles as integration test)
- **Manual testing:** UI verification on iPhone 15 Pro using `/project:device-tester`
- **Cloud Function tests:** Firebase emulator for sweep session handling
