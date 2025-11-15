# DESIGN-012: Camera Capture Implementation

**Created**: 2025-11-08
**Stage**: 2.4 - Computer Vision Pipeline Architecture
**Status**: Draft
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.4.md
- docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
- docs/adr/ADR-011-ios-module-structure.md (CameraFeature module)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (AVFoundation)

---

## Overview

This document specifies the iOS camera capture implementation for Layer 1 of the computer vision pipeline. The camera service handles photo capture, temporary storage, and provides the raw image to Vision Framework for object detection.

**Key Requirements**:
- Use AVFoundation for camera access and photo capture
- Support high-quality still image capture (not video)
- Manage temporary storage for photos before processing
- Handle camera permissions and errors
- Integrate with MVVM architecture (CameraViewModel → CameraService)

---

## Architecture

### Module Location

**Package**: `Packages/Features/CameraFeature`
**Files**:
- `CameraService.swift` - AVFoundation camera logic
- `CameraViewModel.swift` - MVVM ViewModel
- `CameraView.swift` - SwiftUI camera UI
- `CameraPermissionManager.swift` - Camera permission handling

**Dependencies**:
- `AVFoundation` (system framework)
- `Combine` (for reactive updates)
- `SwiftUI` (for UI)

---

## CameraService Implementation

### Service Protocol

```swift
import AVFoundation
import UIKit
import Combine

/// Service protocol for camera capture operations
protocol CameraServiceProtocol {
    /// Current camera session state
    var sessionState: AnyPublisher<CameraSessionState, Never> { get }

    /// Configure and start camera session
    func startSession() async throws

    /// Stop camera session
    func stopSession()

    /// Capture photo
    func capturePhoto() async throws -> UIImage

    /// Check camera authorization status
    func checkAuthorization() async -> CameraAuthorizationStatus
}

enum CameraSessionState {
    case notStarted
    case configuring
    case running
    case stopped
    case failed(Error)
}

enum CameraAuthorizationStatus {
    case authorized
    case denied
    case notDetermined
}

enum CameraError: Error {
    case deviceNotAvailable
    case cannotAddInput
    case cannotAddOutput
    case authorizationDenied
    case captureFailure
    case invalidImageData
}
```

---

### CameraService Class

```swift
import AVFoundation
import UIKit
import Combine

/// Concrete implementation of camera service using AVFoundation
final class CameraService: NSObject, CameraServiceProtocol {

    // MARK: - Properties

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.abundance.camera.session")

    private let sessionStateSubject = CurrentValueSubject<CameraSessionState, Never>(.notStarted)
    var sessionState: AnyPublisher<CameraSessionState, Never> {
        sessionStateSubject.eraseToAnyPublisher()
    }

    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Session Management

    func startSession() async throws {
        sessionStateSubject.send(.configuring)

        try await sessionQueue.sync {
            try configureSession()
        }

        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            self?.sessionStateSubject.send(.running)
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.sessionStateSubject.send(.stopped)
        }
    }

    private func configureSession() throws {
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

        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard captureSession.canAddInput(videoInput) else {
            throw CameraError.cannotAddInput
        }
        captureSession.addInput(videoInput)

        // Add photo output
        guard captureSession.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(photoOutput)

        // Configure photo output settings
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality
    }

    // MARK: - Photo Capture

    func capturePhoto() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality

            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.captureFailure)
                    return
                }

                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Authorization

    func checkAuthorization() async -> CameraAuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        @unknown default:
            return .denied
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoContinuation?.resume(throwing: CameraError.invalidImageData)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
```

---

## CameraViewModel Implementation

### ViewModel Class

```swift
import SwiftUI
import Combine

/// ViewModel for camera capture feature
@MainActor
final class CameraViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var sessionState: CameraSessionState = .notStarted
    @Published var capturedImage: UIImage?
    @Published var isCapturing: Bool = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: CameraAuthorizationStatus = .notDetermined

    // MARK: - Dependencies

    private let cameraService: CameraServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(cameraService: CameraServiceProtocol) {
        self.cameraService = cameraService

        // Observe session state changes
        cameraService.sessionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessionState)
    }

    // MARK: - Public Methods

    func checkCameraPermission() async {
        authorizationStatus = await cameraService.checkAuthorization()

        if authorizationStatus == .authorized {
            await startCamera()
        } else {
            errorMessage = "Camera access denied. Please enable in Settings."
        }
    }

    func startCamera() async {
        do {
            try await cameraService.startSession()
        } catch {
            errorMessage = "Failed to start camera: \(error.localizedDescription)"
            sessionState = .failed(error)
        }
    }

    func stopCamera() {
        cameraService.stopSession()
    }

    func capturePhoto() async {
        guard sessionState == .running else { return }

        isCapturing = true
        defer { isCapturing = false }

        do {
            let image = try await cameraService.capturePhoto()
            capturedImage = image
        } catch {
            errorMessage = "Failed to capture photo: \(error.localizedDescription)"
        }
    }
}
```

---

## CameraView Implementation

### SwiftUI View

```swift
import SwiftUI
import AVFoundation

/// SwiftUI view for camera capture
struct CameraView: View {

    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    init(cameraService: CameraServiceProtocol) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(cameraService: cameraService))
    }

    var body: some View {
        ZStack {
            // Camera preview
            if viewModel.sessionState == .running {
                CameraPreviewView(session: (viewModel.cameraService as? CameraService)?.captureSession)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }

            // Capture button overlay
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        Task {
                            await viewModel.capturePhoto()
                        }
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 80, height: 80)
                            }
                    }
                    .disabled(viewModel.isCapturing || viewModel.sessionState != .running)
                    .opacity(viewModel.isCapturing ? 0.5 : 1.0)

                    Spacer()
                }
                .padding(.bottom, 40)
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                    Spacer()
                }
            }

            // Loading indicator
            if viewModel.isCapturing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            }
        }
        .task {
            await viewModel.checkCameraPermission()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onChange(of: viewModel.capturedImage) { image in
            if image != nil {
                dismiss()
            }
        }
    }
}

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        guard let session = session else { return view }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
```

---

## Temporary Storage

### Temporary File Management

```swift
import Foundation
import UIKit

/// Service for managing temporary photo storage
final class TemporaryPhotoStorage {

    private let fileManager = FileManager.default

    /// Save photo to temporary directory
    func saveTemporaryPhoto(_ image: UIImage) throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw StorageError.invalidImageData
        }

        let tempDir = fileManager.temporaryDirectory
        let filename = "capture_\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(filename)

        try imageData.write(to: fileURL)

        return fileURL
    }

    /// Delete temporary photo
    func deleteTemporaryPhoto(at url: URL) throws {
        guard url.path.hasPrefix(fileManager.temporaryDirectory.path) else {
            throw StorageError.invalidPath
        }

        try fileManager.removeItem(at: url)
    }

    /// Clean up all temporary photos older than 1 hour
    func cleanupOldTemporaryPhotos() throws {
        let tempDir = fileManager.temporaryDirectory
        let contents = try fileManager.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )

        let oneHourAgo = Date().addingTimeInterval(-3600)

        for url in contents where url.lastPathComponent.hasPrefix("capture_") {
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  creationDate < oneHourAgo else {
                continue
            }

            try? fileManager.removeItem(at: url)
        }
    }
}

enum StorageError: Error {
    case invalidImageData
    case invalidPath
}
```

---

## Memory Management

### Best Practices

1. **Release camera session when not in use**:
   ```swift
   .onDisappear {
       viewModel.stopCamera()
   }
   ```

2. **Use weak self in closures**:
   ```swift
   sessionQueue.async { [weak self] in
       self?.captureSession.startRunning()
   }
   ```

3. **Clean up temporary files**:
   ```swift
   // After Vision processing completes
   try temporaryStorage.deleteTemporaryPhoto(at: tempURL)
   ```

4. **Limit photo resolution if needed**:
   ```swift
   // For memory-constrained devices
   captureSession.sessionPreset = .high // Instead of .photo
   ```

---

## Error Handling

### Common Errors

| Error | Cause | Mitigation |
|-------|-------|-----------|
| `deviceNotAvailable` | No camera hardware | Show error, suggest using photo library |
| `cannotAddInput` | Camera already in use | Stop other sessions first |
| `authorizationDenied` | User denied camera access | Show settings prompt |
| `captureFailure` | Photo capture failed | Retry with user prompt |
| `invalidImageData` | Photo data corrupt | Retry capture |

### Error UI

```swift
// In CameraView
if let errorMessage = viewModel.errorMessage {
    VStack {
        Text(errorMessage)
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(10)

        if viewModel.authorizationStatus == .denied {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(.white)
        }
    }
    .padding()
}
```

---

## Testing

### Unit Tests

```swift
import XCTest
@testable import CameraFeature

class CameraServiceTests: XCTestCase {

    var sut: CameraService!

    override func setUp() {
        super.setUp()
        sut = CameraService()
    }

    override func tearDown() {
        sut.stopSession()
        sut = nil
        super.tearDown()
    }

    func testStartSession_ConfiguresSessionCorrectly() async throws {
        // When
        try await sut.startSession()

        // Then
        let state = await sut.sessionState.first()
        XCTAssertEqual(state, .running)
    }

    func testCapturePhoto_WithoutSession_ThrowsError() async {
        // Given: session not started

        // When/Then
        do {
            _ = try await sut.capturePhoto()
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
```

### Integration Tests

```swift
func testCameraCapture_EndToEnd() async throws {
    // Given
    let cameraService = CameraService()
    let viewModel = CameraViewModel(cameraService: cameraService)

    // When
    await viewModel.checkCameraPermission()
    await Task.sleep(for: .seconds(1)) // Wait for session to start
    await viewModel.capturePhoto()

    // Then
    XCTAssertNotNil(viewModel.capturedImage)
}
```

---

## Performance Considerations

### Optimization Strategies

1. **Use background queue for session configuration**:
   ```swift
   sessionQueue.async {
       // Heavy AVFoundation work
   }
   ```

2. **Lazy session initialization**:
   - Don't start camera until user taps "Capture Item"
   - Stop camera when navigating away

3. **JPEG compression quality**:
   ```swift
   image.jpegData(compressionQuality: 0.9) // Good balance (0.8-0.9)
   ```

4. **Photo resolution**:
   - Use `.photo` preset for best quality (Vision Framework needs detail)
   - Don't downsample before Vision processing

---

## Privacy Considerations

**See**: DESIGN-015 (Privacy Architecture) for complete privacy implementation

### Key Privacy Requirements

1. **Camera permission prompt**: Show clear explanation before requesting access
2. **Temporary storage only**: Never persist full photos to permanent storage
3. **Auto-deletion**: Clean up temp files after Vision processing
4. **No cloud upload of full photos**: Only cropped objects leave device

---

## Integration with Vision Framework

### Handoff Pattern

```swift
// In CatalogViewModel (orchestrates camera → vision)
@MainActor
class CatalogViewModel: ObservableObject {

    private let cameraService: CameraServiceProtocol
    private let visionService: VisionServiceProtocol
    private let temporaryStorage: TemporaryPhotoStorage

    func captureAndAnalyzeItem() async {
        do {
            // 1. Capture photo
            let photo = try await cameraService.capturePhoto()

            // 2. Save to temp storage
            let tempURL = try temporaryStorage.saveTemporaryPhoto(photo)

            // 3. Pass to Vision Framework
            let detectedObjects = try await visionService.detectObjects(in: photo)

            // 4. Delete temp photo (privacy firewall)
            try temporaryStorage.deleteTemporaryPhoto(at: tempURL)

            // 5. Continue to Layer 2 (cloud AI)
            // ...

        } catch {
            // Handle error
        }
    }
}
```

---

## Acceptance Criteria

- [x] ✅ AVCaptureSession configured for high-quality photo capture
- [x] ✅ Camera permission handling (authorized/denied/not determined)
- [x] ✅ Photo capture with async/await pattern
- [x] ✅ Temporary storage for photos before Vision processing
- [x] ✅ Memory management (weak self, session cleanup)
- [x] ✅ Error handling for all camera failures
- [x] ✅ SwiftUI camera view with preview and capture button
- [x] ✅ MVVM architecture (CameraViewModel → CameraService)
- [x] ✅ Integration with Vision Framework (handoff pattern)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial camera capture implementation spec | Computer Vision & ML Engineer |

---

**Next Document**: DESIGN-013 (Vision Framework Integration Patterns)
