import AVFoundation
import Combine

/// Actor-isolated camera session manager for thread-safe AVFoundation operations
/// Ensures all camera operations are properly synchronized in Swift 6
actor CameraSessionActor {
    // MARK: - Properties

    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()

    /// Camera configuration settings
    let configuration: CameraConfiguration

    private var videoInput: AVCaptureDeviceInput?

    // MARK: - Initialization

    /// Creates a session actor with the specified configuration
    /// - Parameter configuration: Camera configuration settings
    init(configuration: CameraConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Session Configuration

    /// Configure the capture session with proper isolation.
    /// Idempotent: safe to call multiple times (skips inputs/outputs already added).
    func configure() async throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Set session preset from configuration
        captureSession.sessionPreset = configuration.sessionPreset

        // Only add video input if not already present
        if captureSession.inputs.isEmpty {
            guard let camera = AVCaptureDevice.default(
                configuration.preferredDeviceType,
                for: .video,
                position: configuration.preferredCameraPosition
            ) else {
                throw CameraError.deviceNotAvailable
            }

            let input = try AVCaptureDeviceInput(device: camera)

            guard captureSession.canAddInput(input) else {
                throw CameraError.cannotAddInput
            }

            captureSession.addInput(input)
            videoInput = input
        }

        // Only add photo output if not already present
        if !captureSession.outputs.contains(where: { $0 is AVCapturePhotoOutput }) {
            guard captureSession.canAddOutput(photoOutput) else {
                throw CameraError.cannotAddOutput
            }

            captureSession.addOutput(photoOutput)
        }

        // Configure photo quality (always apply in case settings changed)
        photoOutput.maxPhotoQualityPrioritization = configuration.photoQualityPrioritization

        // Only add video output if not already present
        if !captureSession.outputs.contains(where: { $0 is AVCaptureVideoDataOutput }) {
            guard captureSession.canAddOutput(videoOutput) else {
                throw CameraError.cannotAddOutput
            }

            captureSession.addOutput(videoOutput)
        }

        // Configure video output (always apply in case settings changed)
        videoOutput.alwaysDiscardsLateVideoFrames = configuration.alwaysDiscardsLateVideoFrames
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(configuration.pixelFormat)
        ]

        // Set photo output connection to portrait orientation so captured photos
        // match the preview layer's display (fixes photo shifting right of center)
        configurePhotoOutputRotation()
    }

    // MARK: - Session Control

    /// Start the capture session
    func startRunning() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    /// Stop the capture session
    func stopRunning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    /// Check if session is running
    func isRunning() -> Bool {
        captureSession.isRunning
    }

    // MARK: - Focus Control

    /// Set focus point with proper device locking
    func setFocusPoint(_ point: CGPoint) async throws {
        guard let device = videoInput?.device else { return }

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }

            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
        } catch {
            throw CameraError.configurationFailed(error)
        }
    }

    // MARK: - Video Delegate Setup

    /// Set the sample buffer delegate with proper queue isolation
    func setSampleBufferDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate?, queue: DispatchQueue?) {
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)
    }

    // MARK: - Photo Capture Settings

    /// Ensure the photo output connection rotation matches portrait orientation.
    /// Without this, the captured photo uses the sensor's native landscape orientation,
    /// causing a mismatch with the preview layer which auto-rotates to portrait.
    func configurePhotoOutputRotation() {
        guard let connection = photoOutput.connection(with: .video) else { return }
        // 90° = portrait orientation on iOS (sensor is natively landscape-right)
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    /// Create photo settings for capture
    func createPhotoSettings() -> AVCapturePhotoSettings {
        var settings = AVCapturePhotoSettings()

        // Use HEIF format when available for better compression
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }

        // Enable flash if available and appropriate
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }

        // Enable high-resolution capture
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        settings.photoQualityPrioritization = configuration.photoQualityPrioritization

        return settings
    }
}
