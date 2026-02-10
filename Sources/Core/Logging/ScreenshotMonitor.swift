#if canImport(UIKit)
import UIKit

/// Listens for device screenshots and writes a timestamped marker to AppLogger.
/// The marker includes the exact device-side timestamp so the monitoring script
/// can correlate logs with screenshots regardless of iCloud sync delay.
///
/// Usage: Call `ScreenshotMonitor.shared.startMonitoring()` at app launch.
/// Debug builds only — the marker is only useful during development.
@MainActor
public final class ScreenshotMonitor {
    public static let shared = ScreenshotMonitor()

    private var isMonitoring = false

    private init() {}

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }

    @objc private func handleScreenshot() {
        let screen = topViewControllerName()
        AppLogger.log(.screenshotTaken(screen: screen))
    }

    private func topViewControllerName() -> String {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
            let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return "unknown"
        }

        var current = rootVC
        while let presented = current.presentedViewController {
            current = presented
        }

        // For UIHostingController, extract the SwiftUI view type name
        let typeName = String(describing: type(of: current))
        if typeName.contains("UIHostingController") {
            if let start = typeName.firstIndex(of: "<"),
               let end = typeName.lastIndex(of: ">") {
                let viewType = typeName[typeName.index(after: start)..<end]
                return String(viewType)
            }
        }

        return typeName
    }
}
#endif
