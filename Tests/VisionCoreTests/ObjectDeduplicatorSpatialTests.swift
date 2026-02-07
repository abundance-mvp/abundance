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

    @Test("Empty cache returns false")
    func emptyCacheNotDuplicate() async {
        let dedup = ObjectDeduplicator()
        let pos = SIMD3<Float>(1.0, 0.5, -2.0)

        let isDup = await dedup.isSpatialDuplicate(position: pos, threshold: 0.15)
        #expect(!isDup)
    }

    @Test("Multiple entries tracked")
    func multipleEntries() async {
        let dedup = ObjectDeduplicator()
        let pos1 = SIMD3<Float>(1.0, 0.0, 0.0)
        let pos2 = SIMD3<Float>(2.0, 0.0, 0.0)
        let queryNearPos2 = SIMD3<Float>(2.05, 0.0, 0.0) // 5cm from pos2

        await dedup.addSpatialEntry(position: pos1, identifier: "obj-1")
        await dedup.addSpatialEntry(position: pos2, identifier: "obj-2")

        let isDup = await dedup.isSpatialDuplicate(position: queryNearPos2, threshold: 0.15)
        #expect(isDup)
    }

    @Test("Clear spatial cache removes all entries")
    func clearSpatialCache() async {
        let dedup = ObjectDeduplicator()
        let pos1 = SIMD3<Float>(1.0, 0.5, -2.0)

        await dedup.addSpatialEntry(position: pos1, identifier: "obj-1")
        await dedup.clearSpatialCache()

        let isDup = await dedup.isSpatialDuplicate(position: pos1, threshold: 0.15)
        #expect(!isDup)
    }

    @Test("Exact same position is duplicate")
    func exactSamePositionDuplicate() async {
        let dedup = ObjectDeduplicator()
        let pos = SIMD3<Float>(1.0, 0.5, -2.0)

        await dedup.addSpatialEntry(position: pos, identifier: "obj-1")
        let isDup = await dedup.isSpatialDuplicate(position: pos, threshold: 0.15)
        #expect(isDup)
    }
}
