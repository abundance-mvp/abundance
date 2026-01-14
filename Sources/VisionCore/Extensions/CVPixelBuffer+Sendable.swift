import Foundation
import CoreVideo

// MARK: - CVPixelBuffer Sendable Conformance

/// CVPixelBuffer Sendable conformance for Swift 6 concurrency.
///
/// # Safety Requirements (MUST be maintained)
///
/// This conformance is safe ONLY if:
/// 1. All VisionCore operations use `CVPixelBufferLockBaseAddress` with `.readOnly` flag
/// 2. No code retains references to the pixel buffer's base address across await points
/// 3. The buffer is not modified after being passed across isolation boundaries
///
/// # Verification Checklist
///
/// Before adding new CVPixelBuffer operations, verify:
/// - [ ] Uses `.readOnly` lock flag when calling `CVPixelBufferLockBaseAddress`
/// - [ ] Does not store base address pointer beyond the lock/unlock scope
/// - [ ] Completes all pixel access before returning/awaiting
/// - [ ] Does not mutate pixel data when buffer may be shared across actors
///
/// # Why @unchecked?
///
/// CVPixelBuffer is a Core Foundation type (Core Video) without Sendable conformance.
/// The Swift compiler cannot verify thread safety for CF types. However, CVPixelBuffer
/// is designed to be thread-safe when used correctly:
///
/// - The buffer's pixel data is immutable after creation for read-only operations
/// - `CVPixelBufferLockBaseAddress(_:_:)` with `.readOnly` flag provides safe concurrent access
/// - Vision Framework operations are read-only by design (VNImageRequestHandler, etc.)
/// - IOSurface-backed buffers (common for camera frames) have kernel-level thread safety
///
/// Apple's Core Video documentation states that CVPixelBuffer operations are thread-safe
/// when proper locking is used. Vision Framework internally handles this correctly.
///
/// # @retroactive Attribute
///
/// The `@retroactive` attribute indicates this is a retroactive conformance to a protocol
/// from another module (Swift standard library's Sendable) for a type from another module
/// (CoreVideo's CVPixelBuffer). This may conflict if Apple adds Sendable conformance to
/// CVPixelBuffer in a future CoreVideo release. If that occurs, this extension should be
/// removed and the code should use Apple's official conformance.
///
/// - Warning: Violations of these invariants will cause data races.
///   Any code that writes to CVPixelBuffer MUST NOT pass it across isolation boundaries.
///   If you need to modify pixel data, create a copy first or ensure exclusive access.
///
/// - SeeAlso:
///   - `CVPixelBufferLockBaseAddress(_:_:)` - Lock the buffer before accessing pixel data
///   - `CVPixelBufferUnlockBaseAddress(_:_:)` - Unlock after access is complete
///   - `CVPixelBufferLockFlags.readOnly` - Use this flag for read-only concurrent access
///   - Apple's "Adopting strict concurrency in Swift 6 apps" documentation
extension CVPixelBuffer: @retroactive @unchecked Sendable {}
