import AVFoundation

/// Configuration for camera capture session settings
/// Provides injectable configuration for testing and device-specific customization
public struct CameraConfiguration: Sendable {
    // MARK: - Session Settings

    /// Quality preset for the capture session
    public let sessionPreset: AVCaptureSession.Preset

    /// Target frame rate for video capture
    public let frameRate: Int32

    /// Photo quality prioritization setting
    public let photoQualityPrioritization: AVCapturePhotoOutput.QualityPrioritization

    // MARK: - Queue Configuration

    /// Dispatch queue label for session operations
    public let sessionQueueLabel: String

    /// Dispatch queue label for video frame processing
    public let videoQueueLabel: String

    /// Quality of service for video queue
    public let videoQueueQoS: DispatchQoS

    // MARK: - Video Output Settings

    /// Pixel format for video output
    public let pixelFormat: OSType

    /// Whether to discard late video frames
    public let alwaysDiscardsLateVideoFrames: Bool

    // MARK: - Camera Settings

    /// Preferred camera position
    public let preferredCameraPosition: AVCaptureDevice.Position

    /// Preferred camera device type
    public let preferredDeviceType: AVCaptureDevice.DeviceType

    // MARK: - Initialization

    /// Creates a camera configuration with custom settings
    /// - Parameters:
    ///   - sessionPreset: Quality preset for capture session
    ///   - frameRate: Target frame rate for video capture
    ///   - photoQualityPrioritization: Quality prioritization for photos
    ///   - sessionQueueLabel: Label for session dispatch queue
    ///   - videoQueueLabel: Label for video dispatch queue
    ///   - videoQueueQoS: Quality of service for video queue
    ///   - pixelFormat: Pixel format for video output
    ///   - alwaysDiscardsLateVideoFrames: Whether to discard late frames
    ///   - preferredCameraPosition: Preferred camera position
    ///   - preferredDeviceType: Preferred camera device type
    public init(
        sessionPreset: AVCaptureSession.Preset = .photo,
        frameRate: Int32 = 30,
        photoQualityPrioritization: AVCapturePhotoOutput.QualityPrioritization = .balanced,
        sessionQueueLabel: String = "com.abundance.camera.session",
        videoQueueLabel: String = "com.abundance.camera.video",
        videoQueueQoS: DispatchQoS = .userInitiated,
        pixelFormat: OSType = kCVPixelFormatType_32BGRA,
        alwaysDiscardsLateVideoFrames: Bool = true,
        preferredCameraPosition: AVCaptureDevice.Position = .back,
        preferredDeviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
    ) {
        self.sessionPreset = sessionPreset
        self.frameRate = frameRate
        self.photoQualityPrioritization = photoQualityPrioritization
        self.sessionQueueLabel = sessionQueueLabel
        self.videoQueueLabel = videoQueueLabel
        self.videoQueueQoS = videoQueueQoS
        self.pixelFormat = pixelFormat
        self.alwaysDiscardsLateVideoFrames = alwaysDiscardsLateVideoFrames
        self.preferredCameraPosition = preferredCameraPosition
        self.preferredDeviceType = preferredDeviceType
    }

    // MARK: - Default Configurations

    /// Default configuration optimized for high-quality photo capture
    public static let `default` = CameraConfiguration()

    /// Configuration optimized for fast capture with reduced quality
    /// Suitable for rapid cataloging scenarios
    public static let fastCapture = CameraConfiguration(
        sessionPreset: .high,
        frameRate: 30,
        photoQualityPrioritization: .speed,
        videoQueueQoS: .userInteractive,
        alwaysDiscardsLateVideoFrames: true
    )

    /// Configuration optimized for maximum photo quality
    /// May result in slower capture times
    public static let highQuality = CameraConfiguration(
        sessionPreset: .photo,
        frameRate: 24,
        photoQualityPrioritization: .quality,
        videoQueueQoS: .userInitiated,
        alwaysDiscardsLateVideoFrames: true
    )

    /// Configuration for video-focused capture
    /// Balanced between video quality and photo capability
    public static let videoOptimized = CameraConfiguration(
        sessionPreset: .hd1920x1080,
        frameRate: 30,
        photoQualityPrioritization: .balanced,
        videoQueueQoS: .userInitiated,
        alwaysDiscardsLateVideoFrames: false
    )

    // MARK: - Device-Specific Configuration

    /// Creates a configuration optimized for the current device capabilities
    /// - Returns: Configuration tuned for device hardware
    public static func forCurrentDevice() -> CameraConfiguration {
        // Check device capabilities and return appropriate configuration
        let hasHighPerformance = ProcessInfo.processInfo.processorCount >= 6

        if hasHighPerformance {
            return .highQuality
        } else {
            return .fastCapture
        }
    }
}

// MARK: - Equatable

extension CameraConfiguration: Equatable {
    public static func == (lhs: CameraConfiguration, rhs: CameraConfiguration) -> Bool {
        lhs.sessionPreset == rhs.sessionPreset &&
        lhs.frameRate == rhs.frameRate &&
        lhs.photoQualityPrioritization == rhs.photoQualityPrioritization &&
        lhs.sessionQueueLabel == rhs.sessionQueueLabel &&
        lhs.videoQueueLabel == rhs.videoQueueLabel &&
        lhs.videoQueueQoS == rhs.videoQueueQoS &&
        lhs.pixelFormat == rhs.pixelFormat &&
        lhs.alwaysDiscardsLateVideoFrames == rhs.alwaysDiscardsLateVideoFrames &&
        lhs.preferredCameraPosition == rhs.preferredCameraPosition &&
        lhs.preferredDeviceType == rhs.preferredDeviceType
    }
}

// MARK: - CustomStringConvertible

extension CameraConfiguration: CustomStringConvertible {
    public var description: String {
        """
        CameraConfiguration(
            sessionPreset: \(sessionPreset.rawValue),
            frameRate: \(frameRate),
            photoQualityPrioritization: \(photoQualityPrioritization.rawValue),
            sessionQueueLabel: \(sessionQueueLabel),
            videoQueueLabel: \(videoQueueLabel)
        )
        """
    }
}
