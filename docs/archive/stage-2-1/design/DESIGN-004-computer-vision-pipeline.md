# DESIGN-004: Computer Vision Pipeline Architecture

**Status**: Accepted (Updated 2025-11-01)
**Date**: 2025-10-23 (Original), 2025-11-01 (Stage 2.1 Update)
**Author**: Computer Vision & ML Engineer (Matthijs Hollemans persona)
**Stakeholders**: Product, Engineering, ML/AI
**Related Docs**:
- Google Lens Architecture Analysis (docs/research/)
- iOS/GCP Technology Mapping (docs/research/)
- ADR-013: Vision Framework Strategy
- ADR-014: Cloud AI Provider Selection
- ADR-015: Claude Sonnet 4.5 for AI Synthesis
- ADR-016: S3 + CloudFront vs Firebase Storage
- ADR-017: LLM Parsing Architecture
- RECONCILIATION-design-004-vs-stage-2.1.md

---

## Overview

This document specifies the complete **4-phase computer vision pipeline** for Abundance's home inventory cataloging feature. The pipeline processes user-captured photos to extract structured metadata (name, category, brand, value) using a hybrid on-device + cloud architecture.

**Design Goals**:
1. **Privacy-first**: Full photos never leave device; only cropped objects uploaded to cloud
2. **Fast**: Target < 5 seconds total processing time per item
3. **Accurate**: > 80% correct identification on first try for common household items
4. **Cost-effective**: < $0.03 per item processed at scale
5. **Offline-capable**: Barcode scanning works offline; cloud needed for full metadata

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 ABUNDANCE VISION PIPELINE v2.0               │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Layer 1: On-Device Detection (iOS)                   │  │
│  │                                                        │  │
│  │  AVFoundation Camera → Vision Framework:              │  │
│  │  - VNCoreMLRequest (YOLOv3-Tiny Apple pre-trained)   │  │
│  │  - VNDetectBarcodesRequest                            │  │
│  │  - Crop objects using bounding boxes                  │  │
│  │                                                        │  │
│  │  Cost: $0.00 | Latency: 50-150ms                     │  │
│  └───────────────────────────────────────────────────────┘  │
│                           ↓                                  │
│                 (Upload cropped images)                      │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Layer 2a: Attribute Extraction (GCP)                 │  │
│  │                                                        │  │
│  │  Gemini 2.5 Flash-Lite (Vertex AI):                  │  │
│  │  - Condition, color, material, category               │  │
│  │  - JSON mode with schema validation                   │  │
│  │                                                        │  │
│  │  Cost: $0.000249 | Latency: <50ms                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Layer 2b: Product Search (SerpAPI)            [NEW]  │  │
│  │                                                        │  │
│  │  1. Upload to Google Cloud Storage + Cloud CDN       │  │
│  │  2. SerpAPI Google Lens visual search                 │  │
│  │  3. Claude Haiku parsing (brand/model)                │  │
│  │  4. Redis queue + rate limiting                       │  │
│  │                                                        │  │
│  │  Cost: $0.0109 | Latency: 5-7s                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Layer 3: AI Synthesis (Anthropic)             [NEW]  │  │
│  │                                                        │  │
│  │  Claude Sonnet 4.5 (batch API):                       │  │
│  │  - Merge Layer 2a + 2b results                        │  │
│  │  - Resolve conflicts                                  │  │
│  │  - Final catalog metadata                             │  │
│  │                                                        │  │
│  │  Cost: $0.0092 | Latency: 1-2s                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Layer 4: Data Integration (Firebase + iOS)           │  │
│  │                                                        │  │
│  │  Cloud Firestore ← Write catalog entry                │  │
│  │          ↓                                             │  │
│  │  iOS: Real-time Firestore listener                    │  │
│  │          ↓                                             │  │
│  │  SwiftUI: Display + Edit UI                           │  │
│  │          ↓                                             │  │
│  │  User confirms → Save to inventory                    │  │
│  │                                                        │  │
│  │  Cost: $0.0001 | Latency: <500ms                     │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  Total Cost: $0.019449 | Total Latency: ~7-10s             │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: On-Device Capture

### 1.1 Objective

Capture high-quality photo of item using device camera with minimal friction.

### 1.2 Technology

- **Framework**: AVFoundation
- **Components**:
  - `AVCaptureSession` for camera control
  - `AVCapturePhotoOutput` for still image capture
  - SwiftUI camera preview

### 1.3 Implementation Spec

```swift
import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    func setupCamera() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)

            Task {
                captureSession.startRunning()
            }
        } catch {
            print("Camera setup failed: \\(error)")
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        Task { @MainActor in
            self.capturedImage = image
            // Proceed to Phase 2: Object Segmentation
            processImage(image)
        }
    }
}
```

### 1.4 UX Flow

1. User taps "Add Item" button
2. Camera UI opens (full-screen viewfinder)
3. User points camera at item
4. User taps capture button
5. Photo is saved to temporary storage (`FileManager.default.temporaryDirectory`)
6. Proceed to Phase 2

### 1.5 Requirements

- **Photo quality**: High resolution (1920x1080 minimum) for accurate AI analysis
- **Permissions**: Request camera permission in `Info.plist`
- **Temp storage**: Clean up after processing to avoid disk bloat
- **Error handling**: Handle camera unavailable, permissions denied

### 1.6 Performance Targets

- Time to camera ready: < 500ms
- Capture latency: < 200ms

---

## Phase 2: On-Device Object Segmentation

### 2.1 Objective

Detect object in photo, extract bounding box, crop object, and scan for barcodes.

### 2.2 Technology

- **Framework**: Vision framework
- **Requests**:
  - `VNCoreMLRequest` (object detection with YOLOv8 Core ML model)
  - `VNDetectBarcodesRequest` (barcode scanning)

### 2.3 Object Detection Model

**Recommended Model**: **YOLOv3-Tiny (Apple pre-trained)**

**Source**: Apple ML Models (developer.apple.com/machine-learning/models)

**Specifications**:
- Input: 416x416 RGB image
- Output: Bounding boxes + class labels + confidence scores
- Model size: ~35.4 MB
- Inference time: 50-100ms on iPhone 12+

**Classes**: COCO dataset (80 classes including common household items: chair, couch, laptop, cup, bottle, etc.)

**Rationale**: Apple provides a pre-trained, optimized Core ML model that works out-of-the-box, eliminating the need for manual conversion and ensuring iOS compatibility.

### 2.4 Implementation Spec

```swift
import Vision
import CoreML

struct DetectedObject {
    let boundingBox: CGRect
    let label: String
    let confidence: Float
    let croppedImage: UIImage
    var associatedBarcodes: [DetectedBarcode] = []
}

func processImage(_ image: UIImage) {
    guard let cgImage = image.cgImage else { return }

    // Run object detection and barcode scanning in parallel
    Task {
        async let objects = detectObjects(in: cgImage)
        async let barcodes = detectBarcodes(in: cgImage)

        let (detectedObjects, detectedBarcodes) = await (objects, barcodes)

        // Associate barcodes with objects based on bounding box overlap
        let enrichedObjects = associateBarcodesWithObjects(detectedObjects, detectedBarcodes)

        // Proceed to Phase 3: Upload to cloud
        if let primaryObject = enrichedObjects.first {
            uploadToCloud(object: primaryObject)
        }
    }
}

// Associate barcodes with detected objects using bounding box intersection
func associateBarcodesWithObjects(
    _ objects: [DetectedObject],
    _ barcodes: [DetectedBarcode]
) -> [DetectedObject] {
    return objects.map { object in
        // Find barcodes whose bounding box overlaps with object
        let associatedBarcodes = barcodes.filter { barcode in
            // Calculate intersection area
            let intersection = object.boundingBox.intersection(barcode.boundingBox)
            let intersectionArea = intersection.width * intersection.height
            let barcodeArea = barcode.boundingBox.width * barcode.boundingBox.height

            // Require >30% overlap to associate
            let overlapRatio = intersectionArea / barcodeArea
            return overlapRatio > 0.3
        }

        var enrichedObject = object
        enrichedObject.associatedBarcodes = associatedBarcodes
        return enrichedObject
    }
}

func detectObjects(in cgImage: CGImage) async -> [DetectedObject] {
    return await withCheckedContinuation { continuation in
        guard let model = try? VNCoreMLModel(for: YOLOv3Tiny().model) else {
            continuation.resume(returning: [])
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                continuation.resume(returning: [])
                return
            }

            let objects = results.compactMap { observation -> DetectedObject? in
                guard observation.confidence > 0.5 else { return nil }

                // Crop image using bounding box
                let croppedImage = cropImage(cgImage, to: observation.boundingBox)

                return DetectedObject(
                    boundingBox: observation.boundingBox,
                    label: observation.labels.first?.identifier ?? "Unknown",
                    confidence: observation.confidence,
                    croppedImage: croppedImage
                )
            }

            continuation.resume(returning: objects)
        }

        request.imageCropAndScaleOption = .scaleFit

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

struct DetectedBarcode {
    let type: VNBarcodeSymbology
    let value: String
    let confidence: Float
    let boundingBox: CGRect
}

func detectBarcodes(in cgImage: CGImage) async -> [DetectedBarcode] {
    return await withCheckedContinuation { continuation in
        let request = VNDetectBarcodesRequest { request, error in
            guard let results = request.results as? [VNBarcodeObservation] else {
                continuation.resume(returning: [])
                return
            }

            let barcodes = results.compactMap { observation -> DetectedBarcode? in
                guard let payloadString = observation.payloadStringValue,
                      observation.confidence > 0.8 else {
                    return nil
                }

                return DetectedBarcode(
                    type: observation.symbology,
                    value: payloadString,
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox
                )
            }

            continuation.resume(returning: barcodes)
        }

        // Specify supported barcode types (excludes QR codes per user requirement)
        request.symbologies = [
            .upce,      // UPC-E (retail products)
            .ean13,     // EAN-13 (international products)
            .ean8,      // EAN-8 (small products)
            .code128    // Code 128 (logistics/industrial)
        ]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

func cropImage(_ cgImage: CGImage, to normalizedBoundingBox: CGRect) -> UIImage {
    let width = cgImage.width
    let height = cgImage.height

    // Convert normalized coordinates to pixel coordinates
    let x = normalizedBoundingBox.origin.x * CGFloat(width)
    let y = (1 - normalizedBoundingBox.origin.y - normalizedBoundingBox.height) * CGFloat(height)
    let w = normalizedBoundingBox.width * CGFloat(width)
    let h = normalizedBoundingBox.height * CGFloat(height)

    let cropRect = CGRect(x: x, y: y, width: w, height: h)

    guard let cropped = cgImage.cropping(to: cropRect) else {
        return UIImage(cgImage: cgImage)
    }

    return UIImage(cgImage: cropped)
}
```

### 2.5 Barcode Scanning Details (Enhanced - ADR-018)

**Technology**: `VNDetectBarcodesRequest` from Vision Framework

**Supported Symbologies**:
- ✅ UPC-E: Universal Product Code (6-digit, retail products)
- ✅ EAN-13: European Article Number (13-digit, international products)
- ✅ EAN-8: European Article Number (8-digit, small products)
- ✅ Code 128: High-density barcode (logistics, industrial)
- ❌ QR codes: **EXCLUDED** (user concern about data manipulation/verification)

**Performance**:
- Latency: 50-100ms (runs in parallel with object detection)
- Confidence threshold: >0.8 (high accuracy required)
- Multiple barcode support: YES (can detect multiple barcodes per image)

**Barcode-to-Object Association Algorithm**:

```swift
// Step 1: Calculate bounding box intersection
let intersection = objectBbox.intersection(barcodeBbox)
let intersectionArea = intersection.width * intersection.height
let barcodeArea = barcodeBbox.width * barcodeBbox.height

// Step 2: Calculate overlap ratio
let overlapRatio = intersectionArea / barcodeArea

// Step 3: Associate if >30% overlap
if overlapRatio > 0.3 {
    object.associatedBarcodes.append(barcode)
}
```

**Edge Cases**:

1. **Multiple Objects, One Barcode**:
   - Associate barcode with object having highest bbox overlap
   - Claude Sonnet (Layer 3) validates if single barcode makes sense for detected object
   - Example: Barcode on box, multiple items visible → flag for user review

2. **One Object, Multiple Barcodes**:
   - Rare scenario (e.g., product with both UPC and ISBN)
   - Associate all barcodes with confidence >0.8
   - Layer 3 synthesis chooses primary barcode for product lookup

3. **No Barcode Detected**:
   - Fallback to SerpAPI Google Lens (existing Layer 2b workflow)
   - No additional latency impact (SerpAPI runs regardless)

4. **Barcode Detected, No Object**:
   - Barcode visible but YOLOv3-Tiny missed object
   - Use barcode bounding box as pseudo-object bbox
   - Crop image around barcode, proceed to Layer 2b barcode lookup

**Privacy Preservation**:
- ✅ Barcode scanning happens on-device (zero cost, no data leaves phone)
- ✅ Only barcode digits uploaded to cloud (not barcode image)
- ✅ Barcode type stored as metadata (UPC-E, EAN-13, etc.)

**Cost Optimization**:
- Barcode detection: $0.00 (on-device)
- Barcode product lookup (Layer 2b): $0.005/item (vs $0.010 for SerpAPI)
- Net savings: 46% reduction in Layer 2b costs for barcoded items

### 2.6 Privacy Firewall

**Critical Design Decision**: Original wide-angle photo **NEVER** leaves device.

**What gets uploaded to cloud**:
- ✅ Cropped object image (isolated from background context)
- ✅ Barcode string (if detected)
- ❌ Original full photo
- ❌ Location data
- ❌ User identifying information

**Privacy Benefits**:
- User's home layout not exposed
- Personal belongings in background not visible
- Complies with privacy-first architecture principle

### 2.6 Performance Targets

- Object detection: < 150ms
- Barcode detection: < 100ms
- Image cropping: < 50ms
- **Total Phase 2 time**: < 300ms

---

## Phase 3: Cloud-Based AI Analysis

### 3.1 Objective

Analyze cropped object image using AI to extract structured metadata (name, category, brand, value).

### 3.2 Technology

- **Cloud Storage**: Google Cloud Storage + Cloud CDN
- **Compute**: Firebase Cloud Functions (Node.js or Python)
- **AI Provider**: Gemini 2.5 Flash-Lite via Vertex AI
- **Product Search**: SerpAPI Google Lens
- **AI Synthesis**: Claude Sonnet 4.5 (Batch API)
- **Parsing**: Claude Haiku
- **Queue**: Redis
- **Optional**: UPC Database API for barcode lookup

### 3.3 Data Flow

```
iOS: Upload cropped image to Google Cloud Storage
  ↓
Cloud Function: Triggered on upload (onFinalize)
  ↓
Download image from Storage
  ↓
LAYER 2a: Call Gemini 2.5 Flash-Lite (Vertex AI) with JSON schema
  ↓
LAYER 2b: Upload to CDN → SerpAPI Google Lens → Claude Haiku parsing
  ↓
LAYER 3: Claude Sonnet 4.5 synthesis (merge Layer 2a + 2b)
  ↓
If barcode detected: Call UPC Database API
  ↓
Write final metadata to Firestore (items collection)
  ↓
iOS: Firestore real-time listener receives update
```

### 3.4 iOS Upload Code

```swift
import GoogleCloudStorage

func uploadToCloud(object: DetectedObject) {
    guard let imageData = object.croppedImage.jpegData(compressionQuality: 0.8) else {
        return
    }

    let gcsClient = GCSClient(projectId: "your-gcp-project-id")
    let bucketName = "abundance-vision-uploads"
    let objectName = "temp/\\(UUID().uuidString).jpg"

    // Serialize barcode data (if present)
    var barcodeMetadata: [String: Any] = [:]
    if let primaryBarcode = object.associatedBarcodes.first {
        barcodeMetadata = [
            "barcodeType": primaryBarcode.type.rawValue,
            "barcodeValue": primaryBarcode.value,
            "barcodeConfidence": primaryBarcode.confidence
        ]
    }

    // Add metadata
    let metadata: [String: String] = [
        "userId": Auth.auth().currentUser?.uid ?? "",
        "detectedLabel": object.label,
        "confidence": "\\(object.confidence)",
        "barcodeData": barcodeMetadata.isEmpty ? "" : String(data: try! JSONEncoder().encode(barcodeMetadata), encoding: .utf8)!
    ]

    Task {
        do {
            try await gcsClient.upload(
                data: imageData,
                to: bucketName,
                objectName: objectName,
                metadata: metadata
            )
            print("Upload successful, Cloud Function will process")
            // Show loading state to user
        } catch {
            print("Upload failed: \\(error)")
            // Handle error (retry, show user message)
        }
    }
}
```

### 3.5 Cloud Function (Node.js)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {VertexAI} = require('@google-cloud/vertexai');

admin.initializeApp();

exports.processUploadedImage = functions.storage.object().onFinalize(async (object) => {
    const filePath = object.name; // e.g., "temp/abc123.jpg"

    // Only process temp images
    if (!filePath.startsWith('temp/')) {
        return null;
    }

    const userId = object.metadata?.userId;
    const barcodeData = object.metadata?.barcodeData ? JSON.parse(object.metadata.barcodeData) : null;

    // Download image from Storage
    const bucket = admin.storage().bucket();
    const file = bucket.file(filePath);
    const [imageBuffer] = await file.download();

    // Call Gemini Vision API
    const vertexAI = new VertexAI({
        project: 'your-gcp-project-id',
        location: 'us-central1'
    });

    // LAYER 2a: Gemini 2.5 Flash-Lite with JSON schema mode
    const model = vertexAI.preview.getGenerativeModel({
        model: 'gemini-2.5-flash-lite',
        generationConfig: {
            responseMimeType: 'application/json',
            responseSchema: {
                type: 'object',
                properties: {
                    name: { type: 'string' },
                    category: { type: 'string', enum: ['Electronics', 'Furniture', 'Kitchenware', 'Clothing', 'Tools', 'Books', 'Toys', 'Sports', 'Other'] },
                    brand: { type: ['string', 'null'] },
                    color: { type: 'string' },
                    material: { type: ['string', 'null'], enum: ['plastic', 'metal', 'wood', 'fabric', 'glass', 'ceramic', null] },
                    estimatedValue: { type: 'number' },
                    condition: { type: ['string', 'null'], enum: ['new', 'good', 'fair', 'poor', null] },
                    confidence: { type: 'string', enum: ['high', 'medium', 'low'] }
                },
                required: ['name', 'category', 'color', 'confidence']
            }
        }
    });

    const prompt = `Analyze this image of a household item and extract visual attributes (color, material, category, condition). Focus on what you can see, not product identification.`;

    const result = await model.generateContent([
        prompt,
        {
            inlineData: {
                mimeType: 'image/jpeg',
                data: imageBuffer.toString('base64')
            }
        }
    ]);

    // JSON schema mode guarantees valid JSON
    const layer2aData = JSON.parse(result.response.text());

    // LAYER 2b: Product Search (Barcode-first strategy per ADR-018)
    let layer2bData = null;
    try {
        // If barcode detected, try barcode lookup first
        if (barcodeData && barcodeData.barcodeValue) {
            try {
                const barcodeResult = await lookupBarcode(barcodeData.barcodeValue);
                if (barcodeResult && barcodeResult.found) {
                    layer2bData = {
                        source: 'barcode_api',
                        product: barcodeResult,
                        barcodeType: barcodeData.barcodeType,
                        barcodeConfidence: barcodeData.barcodeConfidence
                    };
                }
            } catch (error) {
                console.error('Barcode lookup failed, falling back to SerpAPI:', error);
            }
        }

        // Fallback to SerpAPI if no barcode or barcode lookup failed
        if (!layer2bData) {
            // Upload to Cloud CDN for public URL
            const cdnUrl = await uploadToCDN(imageBuffer, objectName);

            // Queue SerpAPI request (rate-limited via Redis)
            const searchResults = await queueSerpAPISearch(cdnUrl);

            // Parse results with Claude Haiku
            const parsedData = await parseWithClaude(searchResults, 'haiku');
            layer2bData = {
                source: 'serpapi',
                product: parsedData,
                fallbackReason: barcodeData ? 'barcode_not_found' : null
            };
        }
    } catch (error) {
        console.error('Layer 2b failed:', error);
        // Continue without product search data
    }

    // LAYER 3: AI Synthesis with Claude Sonnet 4.5
    const finalMetadata = await synthesizeWithClaude({
        layer2a: layer2aData,
        layer2b: layer2bData,
        barcodeData: barcodeData
    });

    // Get signed URL for image
    const [url] = await file.getSignedUrl({
        action: 'read',
        expires: '03-01-2500'
    });

    // Write to Firestore
    await admin.firestore().collection('items').add({
        userId: userId,
        ...finalMetadata,
        imageUrl: url,
        barcode: barcode || null,
        layer2a: layer2aData,
        layer2b: layer2bData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending_user_review' // User must confirm/edit
    });

    // Delete temp image (optional: keep for debugging)
    // await file.delete();

    console.log('Item processed successfully:', finalMetadata.name);
    return null;
});

async function uploadToCDN(imageBuffer, objectName) {
    // Upload to GCS bucket with CDN enabled
    const bucket = admin.storage().bucket('abundance-cdn-uploads');
    const file = bucket.file(objectName);
    await file.save(imageBuffer, { contentType: 'image/jpeg', public: true });
    return `https://cdn.abundance.app/${objectName}`;
}

async function queueSerpAPISearch(imageUrl) {
    // Queue request via Redis (rate limiting: 100/month on free tier)
    const redis = getRedisClient();
    const jobId = uuidv4();

    await redis.lpush('serpapi-queue', JSON.stringify({
        jobId,
        imageUrl,
        timestamp: Date.now()
    }));

    // Wait for worker to process (or use pub/sub)
    const result = await waitForJobResult(jobId);
    return result;
}

async function parseWithClaude(searchResults, model = 'haiku') {
    const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

    const response = await anthropic.messages.create({
        model: `claude-3-${model}-20240307`,
        max_tokens: 1024,
        messages: [{
            role: 'user',
            content: `Extract brand, model, and price from these Google Lens search results: ${JSON.stringify(searchResults)}`
        }]
    });

    return JSON.parse(response.content[0].text);
}

async function synthesizeWithClaude(data) {
    const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

    const response = await anthropic.messages.create({
        model: 'claude-sonnet-4.5-20250929',
        max_tokens: 2048,
        messages: [{
            role: 'user',
            content: `Merge these data sources into final catalog metadata:
Layer 2a (visual attributes): ${JSON.stringify(data.layer2a)}
Layer 2b (product search): ${JSON.stringify(data.layer2b)}
Barcode: ${data.barcode}

Return JSON with: name, brand, category, color, material, estimatedValue, condition, confidence`
        }]
    });

    return JSON.parse(response.content[0].text);
}

async function lookupBarcode(barcode) {
    // UPC Database API example
    const response = await fetch(
        `https://api.upcdatabase.org/product/${barcode}`,
        {
            headers: {
                'Authorization': 'Bearer YOUR_API_KEY'
            }
        }
    );

    if (!response.ok) {
        return null;
    }

    const data = await response.json();
    return {
        name: data.title,
        brand: data.brand,
        category: data.category
    };
}
```

**Barcode Lookup API Function** (UPC Database API per ADR-018):

```javascript
async function lookupBarcode(barcodeValue) {
    const response = await fetch(
        `https://api.upcdatabase.org/product/${barcodeValue}`,
        {
            headers: {
                'Authorization': `Bearer ${process.env.UPC_DATABASE_API_KEY}`,
                'Accept': 'application/json'
            },
            timeout: 2000 // 2 second timeout
        }
    );

    if (!response.ok) {
        if (response.status === 404) {
            return { found: false, barcodeValue };
        }
        throw new Error(`UPC Database API error: ${response.status}`);
    }

    const data = await response.json();
    return {
        found: true,
        barcodeValue,
        name: data.title,
        brand: data.brand,
        manufacturer: data.manufacturer,
        category: data.category,
        description: data.description,
        images: data.images || [],
        size: data.size,
        weight: data.weight,
        upc: data.upc,
        ean: data.ean
    };
}
```

### 3.6 Performance Targets

**With Barcode (50% of items)**:
- Upload to GCS: < 1 second (depends on network)
- Cloud Function execution: 2-4 seconds
  - Layer 2a (Gemini Flash-Lite): 30-50ms
  - **Layer 2b (Barcode API)**: 100-200ms ⚡ **(5x faster than SerpAPI)**
  - Layer 3 (Claude Sonnet synthesis): 1-2 seconds
  - Firestore write: < 100ms
- **Total Phase 3 time**: **3-5 seconds** (50% faster than visual-only)

**Without Barcode (50% of items)**:
- Upload to GCS: < 1 second (depends on network)
- Cloud Function execution: 6-9 seconds
  - Layer 2a (Gemini Flash-Lite): 30-50ms
  - Layer 2b (SerpAPI + CDN + Haiku): 5-7 seconds
  - Layer 3 (Claude Sonnet synthesis): 1-2 seconds
  - Firestore write: < 100ms
- **Total Phase 3 time**: 7-10 seconds (same as before)

**Blended Average** (50% barcode, 50% visual-only):
- **Total Phase 3 time**: **5-7.5 seconds** (25% faster)

---

## Phase 4: Data Integration & Presentation

### 4.1 Objective

Display AI-generated metadata to user, allow editing, and save to inventory.

### 4.2 Technology

- **Database**: Cloud Firestore
- **Real-time sync**: Firestore real-time listeners
- **UI**: SwiftUI

### 4.3 iOS Firestore Integration

```swift
import FirebaseFirestore
import FirebaseAuth

class InventoryViewModel: ObservableObject {
    @Published var items: [InventoryItem] = []
    @Published var processingItems: [ProcessingItem] = []

    private var listener: ListenerRegistration?

    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Listen for pending items (waiting for user review)
        listener = Firestore.firestore()
            .collection("items")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending_user_review")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                self.processingItems = documents.compactMap { doc in
                    try? doc.data(as: ProcessingItem.self)
                }
            }
    }

    func confirmItem(_ item: ProcessingItem) async {
        // User confirmed AI-generated metadata (or edited it)
        let db = Firestore.firestore()

        try? await db.collection("items").document(item.id).updateData([
            "status": "confirmed",
            "confirmedAt": FieldValue.serverTimestamp()
        ])

        // Move to main inventory collection
        try? await db.collection("inventory").document(item.id).setData([
            "userId": item.userId,
            "name": item.name,
            "category": item.category,
            "brand": item.brand,
            "color": item.color,
            "material": item.material,
            "estimatedValue": item.estimatedValue,
            "imageUrl": item.imageUrl,
            "barcode": item.barcode,
            "tags": [],
            "location": "Unassigned",
            "createdAt": item.createdAt,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}

struct ProcessingItem: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let category: String
    let brand: String?
    let color: String?
    let material: String?
    let estimatedValue: Double?
    let condition: String?
    let confidence: String
    let imageUrl: String
    let barcode: String?
    let createdAt: Date
    let status: String
}
```

### 4.4 SwiftUI Review Screen

```swift
struct ItemReviewView: View {
    @StateObject var item: ProcessingItem
    @State private var editedName: String
    @State private var editedCategory: String
    @State private var editedValue: Double?

    init(item: ProcessingItem) {
        _item = StateObject(wrappedValue: item)
        _editedName = State(initialValue: item.name)
        _editedCategory = State(initialValue: item.category)
        _editedValue = State(initialValue: item.estimatedValue)
    }

    var body: some View {
        Form {
            Section("Item Photo") {
                AsyncImage(url: URL(string: item.imageUrl)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 200)
            }

            Section("AI Detected Information") {
                HStack {
                    Text("Confidence")
                    Spacer()
                    confidenceBadge(item.confidence)
                }

                TextField("Item Name", text: $editedName)

                Picker("Category", selection: $editedCategory) {
                    ForEach(categories, id: \\.self) { category in
                        Text(category).tag(category)
                    }
                }

                if let brand = item.brand {
                    Text("Brand: \\(brand)")
                }

                if let value = editedValue {
                    TextField("Estimated Value", value: $editedValue, format: .currency(code: "USD"))
                }
            }

            Section {
                Button("Save to Inventory") {
                    Task {
                        await confirmItem()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Retake Photo", role: .destructive) {
                    // Delete and retake
                }
            }
        }
        .navigationTitle("Review Item")
    }

    func confidenceBadge(_ confidence: String) -> some View {
        Text(confidence.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor(confidence))
            .foregroundColor(.white)
            .cornerRadius(8)
    }

    func confidenceColor(_ confidence: String) -> Color {
        switch confidence.lowercased() {
        case "high": return .green
        case "medium": return .orange
        case "low": return .red
        default: return .gray
        }
    }
}

let categories = [
    "Electronics", "Furniture", "Kitchenware", "Clothing",
    "Tools", "Books", "Toys", "Sports", "Other"
]
```

### 4.5 Performance Targets

- Firestore real-time update latency: < 500ms
- UI update: < 100ms
- **Total user wait time (Phase 1-4)**: 7-10 seconds

---

## Fallback Strategy for Older Devices

### iOS Version Support

**Minimum Target**: iOS 15.0

**Graceful Degradation**:

| **Feature** | **iOS 15+** | **iOS 13-14** | **< iOS 13** |
|-------------|------------|--------------|--------------|
| Vision framework | ✅ Full support | ⚠️ Limited (no Swift Concurrency) | ❌ Not supported |
| Barcode detection | ✅ | ✅ | ⚠️ Fallback to ML Kit |
| Text recognition | ✅ | ✅ | ❌ |
| Core ML models | ✅ | ✅ | ⚠️ Slower |
| Real-time camera | ✅ | ✅ | ✅ |

**Recommendation**: Set minimum deployment target to **iOS 15.0** to leverage Swift Concurrency and modern Vision APIs.

---

## Performance Summary

| **Phase** | **Target Time** | **User Perception** |
|-----------|----------------|---------------------|
| Phase 1: Capture | < 1 second | Instant |
| Phase 2: Segmentation | < 150ms | Instant |
| Phase 3: Cloud AI | 7-10 seconds | Loading... |
| Phase 4: Display | < 500ms | Instant |
| **Total** | **7-10 seconds** | Acceptable for cataloging |

**Performance Breakdown (Phase 3)**:
- Layer 2a (Gemini Flash-Lite): 30-50ms
- Layer 2b (Product Search): 5-7s
- Layer 3 (AI Synthesis): 1-2s

---

## Cost Analysis (Per Item)

| **Component** | **Cost** | **Notes** |
|--------------|----------|-----------|
| On-device processing (Layer 1) | $0.000 | Free (runs on user's device) |
| Layer 2a: Gemini 2.5 Flash-Lite | $0.000249 | Image analysis (416x416 pixels) |
| Layer 2b: Product Search | $0.0109 | SerpAPI ($0.01) + S3/CDN ($0.0001) + Claude Haiku parsing ($0.0008) |
| Layer 3: Claude Sonnet 4.5 | $0.0092 | AI synthesis (batch API, 50% discount) |
| Cloud Function execution | ~$0.0001 | Compute time |
| Firestore write | ~$0.0001 | Document write |
| Barcode API (optional) | ~$0.005 | Only for items with barcodes (~50%) |
| **Total per item** | **~$0.019449** | **35% cheaper than original design** |

**Cost Breakdown by Layer**:
- Layer 1 (iOS): $0.000
- Layer 2a (Attributes): $0.000249
- Layer 2b (Product Search): $0.0109
- Layer 3 (Synthesis): $0.0092
- Infrastructure: $0.0002

**Profit Margin** (at $0.12/item revenue):
- Cost: $0.019449
- Revenue: $0.120
- Margin: $0.100551 (83.8%)

**Cost Optimization Opportunities**:
1. Cache common items (e.g., "Coca-Cola can") to avoid re-processing
2. Skip Layer 2b for generic items (save $0.0109)
3. Batch processing for multiple items (future feature)
4. Use Claude Sonnet batch API for 50% discount (already implemented)

---

## Validation & Testing Plan

### 5.1 Test Dataset

**Create test dataset** of 100 household items:
- 40% packaged goods with barcodes
- 30% common household items (furniture, tools, dishes)
- 20% electronics
- 10% edge cases (handmade, obscure items)

### 5.2 Success Metrics

| **Metric** | **Target** | **Measurement** |
|------------|-----------|----------------|
| Accuracy (correct name/category) | > 80% | Manual validation |
| Processing time | < 6 seconds | Automated timing |
| Cost per item | < $0.03 | API cost tracking |
| User edit rate | < 40% | Analytics |

### 5.3 Device Testing

**Test on**:
- iPhone 12 (minimum recommended)
- iPhone 13 Pro
- iPhone 14
- iPhone 15

**Performance degradation acceptable on**:
- iPhone 11 (slower Core ML inference)
- iPhone SE (2nd gen)

---

## Document Status

**Status**: ✅ Accepted (Updated with Stage 2.1 verified technologies)
**Next Steps**:
1. Implementation planning
2. Proof-of-concept implementation
3. MVP development (Stage 3.X)

**Related Decisions**:
- See ADR-013: Vision Framework Strategy
- See ADR-014: Cloud AI Provider Selection
- See ADR-015: Claude Sonnet 4.5 for AI Synthesis
- See ADR-016: S3 + CloudFront vs Firebase Storage
- See ADR-017: LLM Parsing Architecture

---

## Revision History

### Version 2.0 - 2025-11-01 (Stage 2.1 Update)

**Major Technology Updates**:
1. **Layer 1: Object Detection**
   - Changed: YOLOv8n (6MB) → YOLOv3-Tiny (35.4MB)
   - Source: Ultralytics → Apple ML Models (pre-trained)
   - Rationale: Apple-provided model, no conversion needed

2. **Layer 2a: Attribute Extraction**
   - Changed: Gemini 1.5 Pro Vision → Gemini 2.5 Flash-Lite
   - Cost improvement: $0.015-0.020 → $0.000249 (60x cheaper)
   - Latency improvement: 1-3s → 30-50ms (60x faster)
   - Added: JSON schema mode (native structured output)

3. **Layer 2b: Product Search** (NEW)
   - Added: SerpAPI Google Lens integration
   - Added: Google Cloud Storage + Cloud CDN
   - Added: Claude Haiku for parsing
   - Added: Redis queue for rate limiting
   - Cost: $0.0109/item
   - Latency: 5-7s

4. **Layer 3: AI Synthesis** (NEW)
   - Added: Claude Sonnet 4.5 for merging Layer 2a + 2b
   - Cost: $0.0092/item (batch API with 50% discount)
   - Latency: 1-2s

5. **Infrastructure Updates**
   - Changed: Firebase Storage → Google Cloud Storage + Cloud CDN
   - Added: Redis queue system
   - Added: Rate limiting
   - Kept: Firestore, Cloud Functions (working well)

**Performance Impact**:
- Total latency: <6s → 7-10s (+1-4s for product search)
- Layer 1 latency: Improved 50-100ms → 50-150ms
- Layer 2a latency: Improved 1-3s → 30-50ms

**Cost Impact**:
- Total cost: $0.02-0.03 → $0.019449 (35% cheaper!)
- Despite adding two new layers (2b, 3), overall cost decreased
- Profit margin: 83.8% at $0.12/item revenue

**What Stayed the Same** (already correct):
- iOS implementation patterns (AVFoundation, Vision framework)
- SwiftUI UI components
- Firestore integration patterns
- Privacy firewall (crop-only uploads)
- Barcode detection approach

### Version 1.0 - 2025-10-23 (Original)

Initial architecture design with 4-phase pipeline.

---

**End of DESIGN-004**
