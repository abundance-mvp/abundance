import AVFoundation
import Combine

/// Actor-isolated camera session manager for thread-safe AVFoundation operations
/// Ensures all camera operations are properly synchronized in Swift 6
actor CameraSessionActor {
    // MARK: - Properties
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    
    private var videoInput: AVCaptureDeviceInput?
    
    // MARK: - Session Configuration
    
    /// Configure the capture session with proper isolation
    func configure() async throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Set session preset for high-quality photos
        captureSession.sessionPreset = .photo
        
        // Add video input (camera)
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraError.deviceNotAvailable
        }
        
        let input = try AVCaptureDeviceInput(device: camera)
        
        guard captureSession.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        
        captureSession.addInput(input)
        videoInput = input
        
        // Configure photo output
        guard captureSession.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        
        captureSession.addOutput(photoOutput)
        
        // Configure for high quality photos
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        // Configure video output for live preview
        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        
        captureSession.addOutput(videoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
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
    
    /// Create photo settings for capture
    func createPhotoSettings() -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        
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
        settings.photoQualityPrioritization = .quality
        
        return settings
    }
}