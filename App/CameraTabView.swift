import SwiftUI
import CameraFeature

struct CameraTabView: View {
    var body: some View {
        CameraView(cameraService: CameraService())
    }
}
