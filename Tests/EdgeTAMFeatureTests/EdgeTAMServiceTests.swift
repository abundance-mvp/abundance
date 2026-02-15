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

    @Test("Encode frame throws when not loaded")
    func encodeFrameThrowsWhenNotLoaded() async {
        let service = EdgeTAMService(configuration: .default)

        // Create a minimal 1x1 pixel buffer for testing
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, 1, 1, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)

        guard let buffer = pixelBuffer else {
            Issue.record("Failed to create test pixel buffer")
            return
        }

        do {
            _ = try await service.encodeFrame(buffer)
            Issue.record("Expected encodeFrame to throw when models not loaded")
        } catch {
            // Expected: model not loaded error
            #expect(error is SweepError)
        }
    }

    @Test("Decode mask throws when not loaded")
    func decodeMaskThrowsWhenNotLoaded() async {
        let service = EdgeTAMService(configuration: .default)

        do {
            _ = try await service.decodeMask(at: CGPoint(x: 0.5, y: 0.5), featureToken: "fake-token")
            Issue.record("Expected decodeMask to throw when models not loaded")
        } catch {
            #expect(error is SweepError)
        }
    }
}
