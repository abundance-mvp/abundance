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
        let isKeyframe = await scheduler.shouldEncodeFrame(at: now.addingTimeInterval(0.1))
        #expect(isKeyframe)
    }

    @Test("Frame index increments on keyframes only")
    func frameIndexIncrementsOnKeyframes() async {
        let scheduler = FrameScheduler(keyframeInterval: 0.5)
        let now = Date()

        _ = await scheduler.shouldEncodeFrame(at: now) // keyframe 1
        let idx1 = await scheduler.currentFrameIndex
        #expect(idx1 == 1)

        _ = await scheduler.shouldEncodeFrame(at: now.addingTimeInterval(0.1)) // not keyframe
        let idx2 = await scheduler.currentFrameIndex
        #expect(idx2 == 1) // unchanged

        _ = await scheduler.shouldEncodeFrame(at: now.addingTimeInterval(0.6)) // keyframe 2
        let idx3 = await scheduler.currentFrameIndex
        #expect(idx3 == 2)
    }
}
