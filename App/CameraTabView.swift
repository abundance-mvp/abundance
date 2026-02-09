import SwiftUI
import CameraFeature

struct CameraTabView: View {
    let onNavigateToCollection: () -> Void

    // Persist CameraService across tab switches using @StateObject
    @StateObject private var cameraService = CameraService()

    var body: some View {
        CaptureView(cameraService: cameraService, onDone: onNavigateToCollection)
    }
}
