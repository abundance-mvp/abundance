import Testing
import CoreVideo
import CoreML
import QuartzCore
@testable import EdgeTAMFeature

/// On-device benchmark tests for EdgeTAM CoreML inference.
///
/// Gate criteria (SPEC-PIPE-004-A):
/// - >= 4 FPS: Proceed (good real-time experience)
/// - 1-3 FPS: Proceed with tap-to-scan fallback UX
/// - < 1 FPS: **Abort EdgeTAM.** Switch to Option B.
///
/// Run on physical device only (not simulator):
///   swift test --filter EdgeTAMBenchmarkTests
@Suite("EdgeTAM Benchmarks", .tags(.benchmark))
struct EdgeTAMBenchmarkTests {

    /// Skip benchmark if CoreML models are not bundled (export not yet run)
    private static func requireModels() throws {
        let config = EdgeTAMConfiguration.default
        let names = [config.imageEncoderName, config.promptEncoderName, config.maskDecoderName]
        let allPresent = names.allSatisfy { name in
            Bundle.module.url(forResource: name, withExtension: "mlmodelc") != nil
            || Bundle.module.url(forResource: name, withExtension: "mlpackage") != nil
        }
        try #require(allPresent, "Benchmark requires CoreML models. Run scripts/export_edgetam_coreml.py first.")
    }

    // MARK: - Cold Start

    @Test("Warmup (cold start) completes within 10 seconds")
    func benchmarkWarmup() async throws {
        try Self.requireModels()

        let service = EdgeTAMService(configuration: .default)

        let start = CACurrentMediaTime()
        try await service.warmup()
        let loadTimeMs = (CACurrentMediaTime() - start) * 1000

        #expect(await service.isLoaded, "Models should be loaded after warmup")

        print("""
        ========================================
        WARMUP BENCHMARK
        Cold start time: \(String(format: "%.0f", loadTimeMs)) ms
        ========================================
        """)

        #expect(loadTimeMs < 10000, "Warmup exceeded 10 second limit: \(loadTimeMs)ms")

        await service.unload()
    }

    // MARK: - Image Encoder (the bottleneck)

    @Test("Image encoder FPS meets gate criteria")
    func benchmarkEncodeFrame() async throws {
        try Self.requireModels()

        let service = EdgeTAMService(configuration: .default)
        try await service.warmup()

        let iterations = 10
        var totalTime: Double = 0

        for _ in 0..<iterations {
            let buffer = Self.makeTestBuffer()
            let start = CACurrentMediaTime()
            _ = try await service.encodeFrame(buffer)
            totalTime += (CACurrentMediaTime() - start) * 1000
        }

        let averageMs = totalTime / Double(iterations)
        let fps = 1000.0 / averageMs

        print("""
        ========================================
        IMAGE ENCODER BENCHMARK
        Iterations:   \(iterations)
        Average:      \(String(format: "%.1f", averageMs)) ms/frame
        Estimated:    \(String(format: "%.1f", fps)) FPS
        ========================================
        GATE DECISION:
        \(Self.gateDecision(fps: fps))
        ========================================
        """)

        // Gate: must be >= 1 FPS to proceed
        #expect(
            fps >= 1.0,
            """
            GATE FAILED: Image encoder at \(String(format: "%.1f", fps)) FPS (< 1 FPS).
            Abort EdgeTAM. Switch to Option B (Apple native APIs per SPEC-PIPE-004-B).
            """
        )

        await service.unload()
    }

    // MARK: - Mask Decoder (per-tap)

    @Test("Mask decoder latency is interactive (< 100ms)")
    func benchmarkDecodeMask() async throws {
        try Self.requireModels()

        let service = EdgeTAMService(configuration: .default)
        try await service.warmup()

        // Encode a frame first to get a feature token
        let buffer = Self.makeTestBuffer()
        let featureToken = try await service.encodeFrame(buffer)

        let iterations = 10
        let testPoint = CGPoint(x: 0.5, y: 0.5)
        var totalTime: Double = 0

        for _ in 0..<iterations {
            let start = CACurrentMediaTime()
            _ = try await service.decodeMask(at: testPoint, featureToken: featureToken)
            totalTime += (CACurrentMediaTime() - start) * 1000
        }

        let averageMs = totalTime / Double(iterations)

        print("""
        ========================================
        MASK DECODER BENCHMARK
        Iterations:   \(iterations)
        Average:      \(String(format: "%.1f", averageMs)) ms/point
        ========================================
        """)

        #expect(
            averageMs < 100,
            "Mask decoder too slow: \(String(format: "%.1f", averageMs))ms (target < 100ms)"
        )

        await service.unload()
    }

    // MARK: - Auto-Segment (full 4x4 grid)

    @Test("Auto-segment (4x4 grid) completes within 2 seconds")
    func benchmarkAutoSegment() async throws {
        try Self.requireModels()

        let service = EdgeTAMService(configuration: .default)
        try await service.warmup()

        let buffer = Self.makeTestBuffer()
        let featureToken = try await service.encodeFrame(buffer)

        let start = CACurrentMediaTime()
        let segments = try await service.autoSegment(featureToken: featureToken)
        let totalMs = (CACurrentMediaTime() - start) * 1000

        print("""
        ========================================
        AUTO-SEGMENT BENCHMARK (4x4 grid = 16 points)
        Total time:     \(String(format: "%.0f", totalMs)) ms
        Segments found: \(segments.count)
        Per-point avg:  \(String(format: "%.1f", totalMs / 16.0)) ms
        ========================================
        """)

        #expect(
            totalMs < 2000,
            "Auto-segment too slow: \(String(format: "%.0f", totalMs))ms (target < 2000ms)"
        )

        await service.unload()
    }

    // MARK: - Full Pipeline (encode + auto-segment)

    @Test("Full pipeline (encode + auto-segment) measures end-to-end FPS")
    func benchmarkFullPipeline() async throws {
        try Self.requireModels()

        let service = EdgeTAMService(configuration: .default)
        try await service.warmup()

        let iterations = 5
        var totalTime: Double = 0

        for _ in 0..<iterations {
            let buffer = Self.makeTestBuffer()
            let start = CACurrentMediaTime()
            let token = try await service.encodeFrame(buffer)
            _ = try await service.autoSegment(featureToken: token)
            totalTime += (CACurrentMediaTime() - start) * 1000
        }

        let averageMs = totalTime / Double(iterations)
        let fps = 1000.0 / averageMs

        print("""
        ========================================
        FULL PIPELINE BENCHMARK (encode + auto-segment)
        Iterations:     \(iterations)
        Average:        \(String(format: "%.0f", averageMs)) ms/frame
        End-to-end FPS: \(String(format: "%.1f", fps))
        ========================================
        GATE DECISION:
        \(Self.gateDecision(fps: fps))
        ========================================
        """)

        await service.unload()
    }

    // MARK: - Helpers

    /// Create a 1920x1080 test pixel buffer (simulating a camera frame)
    private static func makeTestBuffer() -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            1920, 1080,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        precondition(status == kCVReturnSuccess, "Failed to create pixel buffer")
        return pixelBuffer!
    }

    private static func gateDecision(fps: Double) -> String {
        switch fps {
        case 4...:
            return ">= 4 FPS: PROCEED (good real-time experience)"
        case 1..<4:
            return "1-3 FPS: PROCEED with tap-to-scan fallback UX"
        default:
            return "< 1 FPS: ABORT EdgeTAM. Switch to Option B."
        }
    }
}

// MARK: - Tags

extension Tag {
    @Tag static var benchmark: Self
}
