import SwiftUI
import CameraFeature
import VisionCore

struct CameraTabView: View {
    var body: some View {
        CameraDetectionView(
            viewModel: CameraDetectionViewModel(
                yoloDetector: HouseholdItemDetector(),
                qualityAssessor: ImageQualityAssessor(),
                deduplicator: ObjectDeduplicator(),
                maskGenerator: SubjectMaskGenerator()
            ),
            cameraService: CameraService()
        )
    }
}
