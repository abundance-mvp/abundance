# CODE-EXAMPLE-004: Vision Framework Implementation Patterns

**Created**: 2025-11-10
**Stage**: 3.1 - iOS Implementation Research
**Purpose**: Vision Framework + Core ML integration patterns for object detection and barcode scanning

---

## Overview

This document provides Vision Framework integration patterns for the Abundance app, following ADR-013 (Vision Framework Strategy) and ADR-018 (Barcode Strategy) from Stage 2.0.

**Vision Framework APIs**:
- VNCoreMLRequest (object detection with YOLOv3-Tiny)
- VNDetectBarcodesRequest (barcode scanning)
- AVCaptureSession (camera integration)

---

## Pattern 1: VNCoreMLRequest with YOLOv3-Tiny

### Purpose
Detect objects in photos using on-device Core ML model (YOLOv3-Tiny, 34 MB).

### Implementation

```swift
import Vision
import CoreML
import UIKit

// MARK: - Vision Service for Object Detection

actor VisionService {
    // MARK: - Object Detection

    /// Detect objects in image using Core ML model
    /// - Parameter image: UIImage to analyze
    /// - Returns: Array of detected objects
    func detectObjects(in image: UIImage) async throws -> [DetectedObject] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        // Load Core ML model
        let model = try VNCoreMLModel(for: YOLOv3Tiny(configuration: MLModelConfiguration()).model)

        // Create Vision request
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Parse results
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return []
        }

        return results.compactMap { observation in
            DetectedObject(from: observation, imageSize: image.size)
        }
    }

    /// Detect objects with confidence threshold
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - confidenceThreshold: Minimum confidence (0.0-1.0)
    /// - Returns: Filtered array of detected objects
    func detectObjects(in image: UIImage, confidenceThreshold: Float = 0.5) async throws -> [DetectedObject] {
        let allObjects = try await detectObjects(in: image)
        return allObjects.filter { $0.confidence >= confidenceThreshold }
    }
}

// MARK: - DetectedObject Model

struct DetectedObject: Sendable {
    let label: String
    let confidence: Float
    let boundingBox: CGRect // Normalized coordinates (0.0-1.0)

    init(from observation: VNRecognizedObjectObservation, imageSize: CGSize) {
        self.label = observation.labels.first?.identifier ?? "Unknown"
        self.confidence = observation.confidence

        // Convert Vision coordinates to UIKit coordinates
        // Vision: origin bottom-left, Y-axis up
        // UIKit: origin top-left, Y-axis down
        let visionRect = observation.boundingBox
        self.boundingBox = CGRect(
            x: visionRect.origin.x,
            y: 1.0 - visionRect.origin.y - visionRect.height,
            width: visionRect.width,
            height: visionRect.height
        )
    }

    /// Convert normalized bounding box to pixel coordinates
    /// - Parameter imageSize: Original image size
    /// - Returns: Bounding box in pixels
    func pixelBoundingBox(for imageSize: CGSize) -> CGRect {
        return CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: boundingBox.origin.y * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }

    /// Crop image to bounding box
    /// - Parameter image: Original UIImage
    /// - Returns: Cropped UIImage
    func cropImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let pixelBox = pixelBoundingBox(for: image.size)
        guard let croppedCGImage = cgImage.cropping(to: pixelBox) else { return nil }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

enum VisionError: Error, LocalizedError {
    case invalidImage
    case modelLoadFailed
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .modelLoadFailed:
            return "Failed to load Core ML model"
        case .requestFailed:
            return "Vision request failed"
        }
    }
}
```

### Usage in ViewModel

```swift
@MainActor
class CameraViewModel: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isAnalyzing: Bool = false

    private let visionService: VisionService

    init(visionService: VisionService = VisionService()) {
        self.visionService = visionService
    }

    func analyzePhoto(_ image: UIImage) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            // Detect objects with 50% confidence threshold
            detectedObjects = try await visionService.detectObjects(
                in: image,
                confidenceThreshold: 0.5
            )
        } catch {
            // Handle error
            print("Vision analysis failed: \(error)")
        }
    }

    func cropAndUploadObject(at index: Int, from image: UIImage) async {
        guard index < detectedObjects.count else { return }

        let object = detectedObjects[index]

        // Crop image to bounding box
        guard let croppedImage = object.cropImage(image) else { return }

        // Upload cropped image (from CODE-EXAMPLE-003)
        // await storageService.uploadImage(croppedImage, userId: ..., itemId: ...)
    }
}
```

---

## Pattern 2: VNDetectBarcodesRequest for Barcode Scanning

### Purpose
Scan barcodes from camera or photo library (24 symbologies: UPC-A, EAN-13, QR Code, etc.).

### Implementation

```swift
import Vision
import UIKit

// MARK: - Barcode Scanning

extension VisionService {
    /// Detect barcodes in image
    /// - Parameter image: UIImage to scan
    /// - Returns: Array of detected barcodes
    func detectBarcodes(in image: UIImage) async throws -> [Barcode] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        // Create barcode detection request
        let request = VNDetectBarcodesRequest()

        // Specify symbologies (default: all 24 supported)
        // Optionally filter to specific types:
        // request.symbologies = [.ean13, .upce, .qr, .code128]

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Parse results
        guard let results = request.results as? [VNBarcodeObservation] else {
            return []
        }

        return results.compactMap { observation in
            Barcode(from: observation)
        }
    }

    /// Detect barcodes of specific symbologies
    /// - Parameters:
    ///   - image: UIImage to scan
    ///   - symbologies: Array of VNBarcodeSymbology to detect
    /// - Returns: Array of detected barcodes
    func detectBarcodes(
        in image: UIImage,
        symbologies: [VNBarcodeSymbology]
    ) async throws -> [Barcode] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = symbologies

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNBarcodeObservation] else {
            return []
        }

        return results.compactMap { observation in
            Barcode(from: observation)
        }
    }
}

// MARK: - Barcode Model

struct Barcode: Sendable {
    let value: String
    let symbology: VNBarcodeSymbology
    let boundingBox: CGRect // Normalized coordinates

    init?(from observation: VNBarcodeObservation) {
        guard let payloadString = observation.payloadStringValue else {
            return nil
        }

        self.value = payloadString
        self.symbology = observation.symbology

        // Convert Vision coordinates to UIKit coordinates
        let visionRect = observation.boundingBox
        self.boundingBox = CGRect(
            x: visionRect.origin.x,
            y: 1.0 - visionRect.origin.y - visionRect.height,
            width: visionRect.width,
            height: visionRect.height
        )
    }

    var symbologyDisplayName: String {
        switch symbology {
        case .upce: return "UPC-E"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .qr: return "QR Code"
        case .code128: return "Code 128"
        case .code39: return "Code 39"
        case .code93: return "Code 93"
        case .i2of5: return "Interleaved 2 of 5"
        case .itf14: return "ITF-14"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        case .dataMatrix: return "Data Matrix"
        default: return "Unknown"
        }
    }
}
```

### Usage in ViewModel

```swift
@MainActor
class BarcodeScannerViewModel: ObservableObject {
    @Published var detectedBarcodes: [Barcode] = []
    @Published var isScanning: Bool = false

    private let visionService: VisionService

    init(visionService: VisionService = VisionService()) {
        self.visionService = visionService
    }

    func scanBarcodes(in image: UIImage) async {
        isScanning = true
        defer { isScanning = false }

        do {
            // Scan for common retail barcodes
            detectedBarcodes = try await visionService.detectBarcodes(
                in: image,
                symbologies: [.upce, .ean13, .ean8, .qr, .code128]
            )
        } catch {
            print("Barcode scan failed: \(error)")
        }
    }

    func lookupProduct(barcode: Barcode) async {
        // Call UPCitemdb API or SerpAPI for product lookup
        // (from ADR-017, ADR-018)
    }
}
```

---

## Pattern 3: AVCaptureSession Camera Setup

### Purpose
Configure camera for photo capture, integrate with Vision Framework for real-time analysis.

### Implementation

```swift
import AVFoundation
import UIKit

// MARK: - Camera Service

@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isAuthorized: Bool = false

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoCaptureDevice: AVCaptureDevice?

    // MARK: - Setup

    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }

    func setupCamera() throws {
        guard isAuthorized else {
            throw CameraError.notAuthorized
        }

        // Configure session
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Add camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCameraAvailable
        }

        videoCaptureDevice = device

        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        captureSession.addInput(input)

        // Add photo output
        guard captureSession.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(photoOutput)

        captureSession.commitConfiguration()
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Preview Layer

    func previewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
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
            print("Photo capture error: \(error)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to convert photo to UIImage")
            return
        }

        capturedImage = image
    }
}

enum CameraError: Error, LocalizedError {
    case notAuthorized
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized"
        case .noCameraAvailable:
            return "No camera available on this device"
        case .cannotAddInput:
            return "Cannot add camera input to capture session"
        case .cannotAddOutput:
            return "Cannot add photo output to capture session"
        }
    }
}
```

### SwiftUI Camera View

```swift
import SwiftUI

struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var visionService = VisionService()
    @State private var detectedObjects: [DetectedObject] = []

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(previewLayer: cameraService.previewLayer())
                .ignoresSafeArea()

            // Camera controls
            VStack {
                Spacer()

                Button {
                    cameraService.capturePhoto()
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 70, height: 70)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        }
                }
                .padding(.bottom, 40)
            }
        }
        .task {
            await cameraService.checkAuthorization()

            if cameraService.isAuthorized {
                try? cameraService.setupCamera()
                cameraService.startSession()
            }
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .onChange(of: cameraService.capturedImage) { _, newImage in
            guard let image = newImage else { return }

            // Analyze captured photo with Vision
            Task {
                detectedObjects = try await visionService.detectObjects(in: image)
            }
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}
```

---

## Pattern 4: Complete Image Processing Pipeline

### Purpose
End-to-end flow: Camera → Capture → Vision analysis → Crop → Upload.

### Implementation

```swift
@MainActor
class ItemCaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var detectedObjects: [DetectedObject] = []
    @Published var selectedObjectIndex: Int?
    @Published var croppedImage: UIImage?
    @Published var isProcessing: Bool = false
    @Published var uploadProgress: Double = 0.0

    private let visionService: VisionService
    private let storageService: ImageStorageService

    init(
        visionService: VisionService = VisionService(),
        storageService: ImageStorageService = ImageStorageService()
    ) {
        self.visionService = visionService
        self.storageService = storageService
    }

    // MARK: - Pipeline Steps

    /// Step 1: Analyze captured photo with Vision
    func analyzePhoto(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }

        capturedImage = image

        do {
            detectedObjects = try await visionService.detectObjects(
                in: image,
                confidenceThreshold: 0.5
            )
        } catch {
            print("Vision analysis failed: \(error)")
        }
    }

    /// Step 2: User selects detected object
    func selectObject(at index: Int) {
        guard index < detectedObjects.count,
              let image = capturedImage else { return }

        selectedObjectIndex = index

        // Crop image to selected object
        let object = detectedObjects[index]
        croppedImage = object.cropImage(image)
    }

    /// Step 3: Upload cropped image to Firebase Storage
    func uploadCroppedImage(userId: String, itemId: String) async -> URL? {
        guard let cropped = croppedImage else { return nil }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let url = try await storageService.uploadImageWithProgress(
                cropped,
                userId: userId,
                itemId: itemId
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.uploadProgress = progress
                }
            }

            return url
        } catch {
            print("Upload failed: \(error)")
            return nil
        }
    }

    /// Step 4: Create catalog item with uploaded image URL
    func createCatalogItem(imageURL: URL, userId: String) async -> CatalogItem? {
        guard let object = selectedObjectIndex.map({ detectedObjects[$0] }) else {
            return nil
        }

        let item = CatalogItem(
            name: object.label.capitalized,
            category: "Uncategorized",
            imageURL: imageURL,
            userId: userId
        )

        // Save to Firestore (from CODE-EXAMPLE-002)
        // try await catalogRepository.createItem(item)

        return item
    }
}
```

### Usage Flow

```swift
// 1. Capture photo
cameraService.capturePhoto()

// 2. Analyze with Vision
await itemCaptureViewModel.analyzePhoto(capturedImage)

// 3. User selects detected object
itemCaptureViewModel.selectObject(at: 0)

// 4. Upload cropped image
if let url = await itemCaptureViewModel.uploadCroppedImage(
    userId: currentUser.id,
    itemId: UUID().uuidString
) {
    // 5. Create catalog item
    await itemCaptureViewModel.createCatalogItem(
        imageURL: url,
        userId: currentUser.id
    )
}
```

---

## YOLOv3-Tiny Model Info

### Model Specifications
- **Size**: 34 MB
- **Input**: 416×416 RGB image
- **Output**: 80 object classes (COCO dataset)
- **Performance**: 300-500ms on A17 Pro Neural Engine
- **Accuracy**: ~33% mAP (mean Average Precision)

### Supported Object Classes (Sample)
- Tools: screwdriver, hammer, knife, scissors
- Electronics: laptop, keyboard, mouse, cell phone, tv, remote
- Kitchen: bottle, cup, fork, spoon, bowl, microwave, oven, toaster
- Furniture: chair, couch, bed, dining table
- Sports: sports ball, baseball bat, skateboard, surfboard, tennis racket
- Outdoor: backpack, umbrella, handbag, suitcase, frisbee, kite

### Model Download
- Include YOLOv3-Tiny.mlmodel in Xcode project
- Xcode automatically generates Swift interface
- Model loads on-demand (first Vision request)

---

## References

### Apple Documentation
- Vision Framework: https://developer.apple.com/documentation/vision/
- VNCoreMLRequest: https://developer.apple.com/documentation/vision/vncoremlrequest/
- VNDetectBarcodesRequest: https://developer.apple.com/documentation/vision/vndetectbarcodesrequest/
- AVCaptureSession: https://developer.apple.com/documentation/avfoundation/avcapturesession/

### Related ADRs
- ADR-013: Vision Framework Strategy (Stage 2.0)
- ADR-018: Barcode Strategy (Stage 2.0)
- ADR-008: Image Storage Architecture (cropped objects)

---

## Verification

✅ VNCoreMLRequest implementation with YOLOv3-Tiny
✅ VNDetectBarcodesRequest implementation (24 symbologies)
✅ AVCaptureSession camera setup
✅ Complete image processing pipeline (Camera → Vision → Crop → Upload)
✅ Coordinate conversion (Vision → UIKit)
✅ Error handling for all Vision operations
✅ SwiftUI camera view with preview

---

**Status**: ✅ Complete

**Next**: DESIGN-012 (Xcode Project Structure)
