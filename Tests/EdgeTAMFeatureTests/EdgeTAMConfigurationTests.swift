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

@Suite("Sweep Session State")
struct SweepSessionStateTests {
    @Test("isError returns true for error states")
    func isErrorForErrorState() {
        let state = SweepSessionState.error(.deviceNotSupported)
        #expect(state.isError)
    }

    @Test("isError returns false for non-error states")
    func isErrorForNonErrorStates() {
        #expect(!SweepSessionState.inactive.isError)
        #expect(!SweepSessionState.loading.isError)
        #expect(!SweepSessionState.ready.isError)
        #expect(!SweepSessionState.scanning(segmentCount: 5).isError)
        #expect(!SweepSessionState.processing.isError)
        #expect(!SweepSessionState.complete(itemCount: 3).isError)
    }
}
