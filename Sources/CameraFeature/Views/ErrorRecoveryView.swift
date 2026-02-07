// swiftlint:disable file_length
// ErrorRecoveryView.swift
// Comprehensive error recovery UI for camera and network failures
//
// Created: 2026-01-18
// ADR-010 Compliant: SwiftUI-only (no UIKit imports for View layer)

import SwiftUI
import Core

// MARK: - Error Category

/// Categories of errors for UI presentation
public enum ErrorCategory: Sendable {
    case camera
    case network
    case authentication
    case server
    case unknown

    var iconName: String {
        switch self {
        case .camera:
            return "camera.fill"
        case .network:
            return "wifi.exclamationmark"
        case .authentication:
            return "person.crop.circle.badge.exclamationmark"
        case .server:
            return "server.rack"
        case .unknown:
            return "exclamationmark.triangle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .camera:
            return .cream
        case .network:
            return .accentSecondary
        case .authentication:
            return .accentPrimary
        case .server:
            return .errorColor
        case .unknown:
            return .cream
        }
    }
}

// MARK: - Error Recovery View

/// Reusable error recovery view with retry capability
/// Supports camera permission denied flow with Settings deep link
/// Uses Liquid Glass styling for iOS 26+ with fallbacks
public struct ErrorRecoveryView: View {
    let error: Error
    let category: ErrorCategory
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    let onOpenSettings: (() -> Void)?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 36
    @State private var isRetrying = false
    @State private var showingSettingsAlert = false

    /// Initialize with CameraError
    public init(
        cameraError: CameraError,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.error = cameraError
        self.category = Self.categorize(cameraError)
        self.onRetry = onRetry
        self.onDismiss = onDismiss
        self.onOpenSettings = onOpenSettings
    }

    /// Initialize with CaptureError
    public init(
        captureError: CaptureError,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.error = captureError
        self.category = Self.categorize(captureError)
        self.onRetry = onRetry
        self.onDismiss = onDismiss
        self.onOpenSettings = onOpenSettings
    }

    /// Initialize with any Error
    public init(
        error: Error,
        category: ErrorCategory = .unknown,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.error = error
        self.category = category
        self.onRetry = onRetry
        self.onDismiss = onDismiss
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Error icon
            errorIcon

            // Error message
            errorMessage

            // Recovery suggestion
            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // Action buttons
            actionButtons
        }
        .padding(32)
        .frame(maxWidth: 340)
        .background {
            glassBackground
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Subviews

    private var errorIcon: some View {
        ZStack {
            Circle()
                .fill(category.iconColor.opacity(0.2))
                .frame(width: 80, height: 80)

            Image(systemName: category.iconName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(category.iconColor)
        }
        .accessibilityHidden(true)
    }

    private var errorMessage: some View {
        VStack(spacing: 8) {
            Text(errorTitle)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(error.localizedDescription)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action (retry or open settings)
            if requiresSettingsNavigation {
                openSettingsButton
            } else if let onRetry = onRetry, isRetryable {
                retryButton(action: onRetry)
            }

            // Secondary action (dismiss)
            if let onDismiss = onDismiss {
                dismissButton(action: onDismiss)
            }
        }
        .padding(.top, 8)
    }

    private func retryButton(action: @escaping () -> Void) -> some View {
        Button {
            isRetrying = true
            action()
            // Reset after short delay
            // Note: [weak self] not needed for SwiftUI structs - @State handles lifecycle
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                isRetrying = false
            }
        } label: {
            HStack(spacing: 8) {
                if isRetrying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(isRetrying ? "Retrying..." : "Try Again")
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentPrimary, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isRetrying)
        .accessibilityHint("Double tap to retry the failed operation")
    }

    private var openSettingsButton: some View {
        Button {
            openSettings()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gear")
                Text("Open Settings")
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentPrimary, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityHint("Double tap to open Settings app to grant camera permission")
    }

    private func dismissButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text("Dismiss")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .accessibilityHint("Double tap to dismiss this error")
    }

    @ViewBuilder
    private var glassBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if !reduceTransparency {
                Color.clear
                    .glassEffect(in: RoundedRectangle(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.backgroundDefault)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            }
        } else {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }

    // MARK: - Computed Properties

    private var errorTitle: String {
        switch category {
        case .camera:
            return "Camera Issue"
        case .network:
            return "Connection Problem"
        case .authentication:
            return "Sign In Required"
        case .server:
            return "Service Unavailable"
        case .unknown:
            return "Something Went Wrong"
        }
    }

    private var recoverySuggestion: String? {
        if let captureError = error as? CaptureError {
            return captureError.recoverySuggestion
        } else if let cameraError = error as? CameraError {
            return cameraError.recoverySuggestion
        }
        return nil
    }

    private var isRetryable: Bool {
        if let captureError = error as? CaptureError {
            return captureError.isRetryable
        }
        // Camera errors are generally retryable except permission denied
        if let cameraError = error as? CameraError {
            switch cameraError {
            case .authorizationDenied:
                return false
            default:
                return true
            }
        }
        return true
    }

    private var requiresSettingsNavigation: Bool {
        if let cameraError = error as? CameraError {
            return cameraError == .authorizationDenied
        }
        return false
    }

    private var accessibilityDescription: String {
        "\(errorTitle). \(error.localizedDescription). \(recoverySuggestion ?? "")"
    }

    // MARK: - Actions

    private func openSettings() {
        if let customAction = onOpenSettings {
            customAction()
        } else {
            #if os(iOS)
            // Deep link to app settings - this is infrastructure, not UI (ADR-010 compliant)
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            #endif
        }
    }

    // MARK: - Error Categorization

    private static func categorize(_ error: CameraError) -> ErrorCategory {
        switch error {
        case .authorizationDenied:
            return .camera
        case .deviceNotAvailable, .cannotAddInput, .cannotAddOutput, .configurationFailed:
            return .camera
        case .captureFailure, .invalidImageData, .captureInProgress:
            return .camera
        case .sessionInterrupted, .sessionStartFailed:
            return .camera
        }
    }

    private static func categorize(_ error: CaptureError) -> ErrorCategory {
        switch error {
        case .notAuthenticated, .authenticationExpired:
            return .authentication
        case .captureFailure, .invalidImageData, .burstCaptureTooShort:
            return .camera
        case .uploadFailed, .networkTimeout:
            return .network
        case .quotaExceeded:
            return .server
        case .detectionTimeout, .detectionFailed, .invalidResponse:
            return .server
        case .sessionNotFound, .unknownError:
            return .unknown
        }
    }
}

// MARK: - CameraError Recovery Suggestion Extension

extension CameraError {
    /// User-friendly recovery suggestion
    public var recoverySuggestion: String? {
        switch self {
        case .authorizationDenied:
            return "Open Settings to allow camera access for Abundance."
        case .deviceNotAvailable:
            return "This device does not have a camera available."
        case .cannotAddInput, .cannotAddOutput, .configurationFailed:
            return "Try restarting the app."
        case .captureFailure:
            return "Try taking another photo."
        case .invalidImageData:
            return "The photo could not be processed. Try again."
        case .captureInProgress:
            return "Wait for the current capture to complete."
        case .sessionInterrupted:
            return "The camera was interrupted. Try again."
        case .sessionStartFailed:
            return "Unable to start the camera. Try restarting the app."
        }
    }
}

// MARK: - Offline Mode Indicator

/// Compact indicator showing offline status
public struct OfflineModeIndicator: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.system(.caption, weight: .medium))

            Text("Offline")
                .font(.system(.caption, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            if #available(iOS 26.0, macOS 26.0, *) {
                if !reduceTransparency {
                    Color.accentSecondary.opacity(0.8)
                        .glassEffect(in: Capsule())
                } else {
                    Capsule()
                        .fill(Color.accentSecondary)
                }
            } else {
                Capsule()
                    .fill(Color.accentSecondary)
            }
        }
        .accessibilityLabel("Offline mode active")
        .accessibilityHint("Some features may be limited without internet connection")
    }
}

// MARK: - Network Status Monitor

/// Observable object to monitor network connectivity
@MainActor
public final class NetworkMonitor: ObservableObject {
    @Published public var isConnected: Bool = true
    @Published public var connectionType: ConnectionType = .unknown

    public enum ConnectionType: Sendable {
        case wifi
        case cellular
        case unknown
    }

    public static let shared = NetworkMonitor()

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        // Use NWPathMonitor for network state monitoring
        // This is infrastructure code, not UI (ADR-010 compliant)
        #if os(iOS)
        Task {
            await setupPathMonitor()
        }
        #endif
    }

    #if os(iOS)
    private func setupPathMonitor() async {
        // Note: Full implementation would use NWPathMonitor from Network framework
        // For now, we assume connected and rely on actual network errors
        isConnected = true
    }
    #endif

    /// Manually trigger a connection check
    public func checkConnection() async -> Bool {
        // Attempt a lightweight network request to verify connectivity
        guard let url = URL(string: "https://www.googleapis.com/generate_204") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                isConnected = (200...299).contains(httpResponse.statusCode)
            }
        } catch {
            isConnected = false
        }

        return isConnected
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Camera Permission Denied") {
    ZStack {
        Color.black.ignoresSafeArea()

        ErrorRecoveryView(
            cameraError: .authorizationDenied,
            onRetry: { print("Retry tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
    }
}

#Preview("Network Error") {
    ZStack {
        Color.black.ignoresSafeArea()

        ErrorRecoveryView(
            captureError: .networkTimeout,
            onRetry: { print("Retry tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
    }
}

#Preview("Offline Indicator") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            OfflineModeIndicator()
            Spacer()
        }
        .padding()
    }
}
#endif

// swiftlint:enable file_length
