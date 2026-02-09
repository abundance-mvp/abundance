import Testing
@testable import EdgeTAMFeature

@Suite("MotionKeyframeDetector")
struct MotionKeyframeDetectorTests {

    @Test("Starts inactive")
    func startsInactive() async {
        let detector = MotionKeyframeDetector()
        let active = await detector.isActive
        #expect(!active)
    }

    @Test("checkStabilized returns false when not monitoring")
    func checkStabilizedWhenNotMonitoring() async {
        let detector = MotionKeyframeDetector()
        let result = await detector.checkStabilized()
        #expect(!result)
    }

    @Test("Custom threshold is accepted")
    func customThreshold() async {
        // Just verify it initializes without error
        let detector = MotionKeyframeDetector(stabilizationThreshold: 0.05)
        let active = await detector.isActive
        #expect(!active)
    }

    @Test("Stop monitoring when not started is safe")
    func stopWhenNotStarted() async {
        let detector = MotionKeyframeDetector()
        await detector.stopMonitoring()
        let active = await detector.isActive
        #expect(!active)
    }
}
