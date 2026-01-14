import SwiftUI
import AVFoundation
import VisionCore

/// Main camera view with real-time object detection and organic border overlays
/// Replaces deprecated CameraView with continuous 2 FPS detection experience
public struct CameraDetectionView: View {

    @StateObject private var viewModel: CameraDetectionViewModel
    private let cameraService: CameraService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var sparkleCenter: CGPoint?

    /// Initialize with detection view model and optional camera service
    public init(
        viewModel: CameraDetectionViewModel,
        cameraService: CameraService = CameraService()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.cameraService = cameraService
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview background
                Color.black
                    .ignoresSafeArea()

                // Camera preview layer
                if let captureSession = cameraService.getCaptureSession() {
                    CameraPreviewView(captureSession: captureSession)
                        .ignoresSafeArea()
                }

                // Detected object borders
                ForEach(viewModel.detectedObjects) { object in
                    OrganicBorderOverlay(object: object)
                        .frame(
                            width: geometry.size.width * object.boundingBox.width,
                            height: geometry.size.height * object.boundingBox.height
                        )
                        .position(
                            x: geometry.size.width * object.boundingBox.midX,
                            y: geometry.size.height * (1 - object.boundingBox.midY)
                        )
                        .onTapGesture(count: 2) {
                            handleDoubleTap(on: object, in: geometry.size)
                        }
                }

                // Sparkle animation on automatic catalog
                if let center = sparkleCenter {
                    SparkleAnimation(center: center)
                        .task {
                            // Clear sparkle after animation completes
                            try? await Task.sleep(for: .seconds(0.5))
                            sparkleCenter = nil
                        }
                }

                // Top bar
                VStack {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(16)

                        Spacer()

                        modeIndicator
                            .padding(16)
                    }

                    Spacer()

                    // Bottom instruction
                    instructionLabel
                        .padding(.bottom, 40)
                }
            }
            .onChange(of: viewModel.detectedObjects) { oldObjects, newObjects in
                checkForAutomaticCatalog(oldObjects: oldObjects, newObjects: newObjects, in: geometry.size)
            }
            .onAppear {
                setupCamera()
            }
            .onDisappear {
                teardownCamera()
            }
        }
    }

    /// Setup camera and wire frame processing loop
    private func setupCamera() {
        // Start camera session
        Task {
            do {
                try await cameraService.startSession()
            } catch {
                print("Failed to start camera session: \(error)")
            }
        }

        // Delegate frame processing to ViewModel (Swift 6 compliant)
        viewModel.startFrameProcessing(from: cameraService.framePublisher)
    }

    /// Cleanup camera resources
    private func teardownCamera() {
        cameraService.stopSession()
        viewModel.stopFrameProcessing()
    }

    /// Mode indicator (Auto/Manual) with Liquid Glass styling
    /// Uses glassEffect() for iOS 26+, .ultraThickMaterial fallback for iOS 25-
    /// Respects @Environment(\.accessibilityReduceTransparency)
    private var modeIndicator: some View {
        Text("Mode: Auto")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                if #available(iOS 26.0, macOS 26.0, *) {
                    if !reduceTransparency {
                        Color.clear
                            .glassEffect(in: Capsule())
                    } else {
                        Color.black.opacity(0.6)
                            .clipShape(Capsule())
                    }
                } else {
                    Capsule()
                        .fill(.ultraThickMaterial)
                }
            }
    }

    /// Instruction label at bottom with Liquid Glass styling
    /// Uses glassEffect() for iOS 26+, .ultraThickMaterial fallback for iOS 25-
    /// Respects @Environment(\.accessibilityReduceTransparency)
    private var instructionLabel: some View {
        Text("Double-tap grey objects to catalog manually")
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if #available(iOS 26.0, macOS 26.0, *) {
                    if !reduceTransparency {
                        Color.clear
                            .glassEffect(in: Capsule())
                    } else {
                        Color.black.opacity(0.6)
                            .clipShape(Capsule())
                    }
                } else {
                    Capsule()
                        .fill(.ultraThickMaterial)
                }
            }
    }

    /// Handle double-tap gesture on object
    private func handleDoubleTap(on object: DetectedObject, in size: CGSize) {
        Task {
            let location = CGPoint(
                x: object.boundingBox.midX,
                y: 1 - object.boundingBox.midY
            )
            await viewModel.handleDoubleTap(at: location)

            // TODO: Trigger upload to Firebase Storage
            print("Manual catalog triggered for: \(object.label)")
        }
    }

    /// Check for new automatic catalog objects and trigger sparkle
    private func checkForAutomaticCatalog(oldObjects: [DetectedObject], newObjects: [DetectedObject], in size: CGSize) {
        let newAutomaticObjects = newObjects.filter { newObject in
            newObject.catalogMode == .automatic &&
            !oldObjects.contains(where: { $0.id == newObject.id })
        }

        for object in newAutomaticObjects {
            // Trigger sparkle animation at object center
            sparkleCenter = CGPoint(
                x: size.width * object.boundingBox.midX,
                y: size.height * (1 - object.boundingBox.midY)
            )

            // TODO: Trigger upload to Firebase Storage
            print("Automatic catalog triggered for: \(object.label)")

            // TODO: Add haptic feedback using HapticFeedbackService abstraction
            // to maintain ADR-010 compliance (SwiftUI-only)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    @Previewable @StateObject var previewViewModel = {
        let mockYOLO = PreviewMockHouseholdItemDetector()
        let mockQuality = PreviewMockImageQualityAssessor()
        let mockDeduplicator = PreviewMockObjectDeduplicator()
        let mockMaskGenerator = PreviewMockSubjectMaskGenerator()

        return CameraDetectionViewModel(
            yoloDetector: mockYOLO,
            qualityAssessor: mockQuality,
            deduplicator: mockDeduplicator,
            maskGenerator: mockMaskGenerator,
            storageService: nil,  // Skip Firebase in preview
            itemService: nil      // Skip Firebase in preview
        )
    }()

    return CameraDetectionView(viewModel: previewViewModel)
}

// MARK: - Mock Dependencies for Preview

@preconcurrency import Vision

final class PreviewMockHouseholdItemDetector: HouseholdItemDetectorProtocol, @unchecked Sendable {
    func detectHouseholdItems(in image: PlatformImage) async throws -> [HouseholdItem] { [] }
    func detectInStream(pixelBuffer: CVPixelBuffer) async throws -> [YOLOResult] { [] }
}

actor PreviewMockImageQualityAssessor: ImageQualityAssessorProtocol {
    func assess(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> Double { 0.8 }
}

actor PreviewMockObjectDeduplicator: ObjectDeduplicatorProtocol {
    nonisolated func isSimilarToRecent(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> Bool { false }
    nonisolated func generateFingerprint(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> String? { "mock" }
    func addToCache(_ fingerprint: String) async { }
    func isDuplicate(_ fingerprint: String) async -> Bool { false }
    func cacheFingerprint(_ fingerprint: VNFeaturePrintObservation) async { }
}

actor PreviewMockSubjectMaskGenerator: SubjectMaskGeneratorProtocol {
    nonisolated func generateMask(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> VNInstanceMaskObservation? { nil }
}

#endif
