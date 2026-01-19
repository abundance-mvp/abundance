import SwiftUI
import CameraFeature

struct CameraTabView: View {
    let onNavigateToCatalog: () -> Void

    var body: some View {
        CaptureView(onDone: onNavigateToCatalog)
    }
}
