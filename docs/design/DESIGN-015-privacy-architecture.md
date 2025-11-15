# DESIGN-015: Privacy Architecture

**Created**: 2025-11-09
**Stage**: 2.4 - Computer Vision Pipeline Architecture
**Status**: Draft
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.4.md
- docs/adr/ADR-001-strategic-positioning.md (privacy-first positioning)
- docs/adr/ADR-013-vision-framework-strategy.md (on-device processing)
- docs/design/DESIGN-012-camera-capture-implementation.md (camera)
- docs/design/DESIGN-013-vision-framework-integration-patterns.md (Vision)

---

## Overview

This document specifies the privacy architecture for Abundance's computer vision pipeline, ensuring that full photos never leave the device and only cropped object images are uploaded to the cloud. This privacy-first approach is a core differentiator and strategic positioning element.

**Key Requirements**:
- Privacy firewall: Full photos processed on-device only (Layer 1)
- Only cropped objects uploaded to cloud (Layer 2-3)
- Temporary photo deletion after Vision processing
- User consent for camera and photo library access
- Compliance with privacy regulations (GDPR, CCPA)
- Transparent privacy disclosure to users

---

## Privacy Firewall Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS Device (Secure)                       │
│                                                                   │
│  User Takes Photo                                                 │
│         │                                                         │
│         ▼                                                         │
│  ┌─────────────────┐                                            │
│  │ Temp Directory  │ (Full Photo)                                │
│  └────────┬────────┘                                            │
│           │                                                       │
│           ▼                                                       │
│  ┌─────────────────┐                                            │
│  │ Vision Framework │ (On-Device Processing)                     │
│  └────────┬────────┘                                            │
│           │                                                       │
│           ▼                                                       │
│  Detected Objects (Bounding Boxes)                               │
│           │                                                       │
│           ▼                                                       │
│  ┌─────────────────┐                                            │
│  │ Crop Objects    │ (Extract bounding box regions)              │
│  └────────┬────────┘                                            │
│           │                                                       │
│           ▼                                                       │
│  ┌─────────────────┐                                            │
│  │ DELETE Full Photo│ ◄── PRIVACY FIREWALL ENFORCED             │
│  └─────────────────┘                                            │
│           │                                                       │
└───────────┼───────────────────────────────────────────────────┘
            │
            ▼ (Only cropped objects leave device)
┌───────────────────────────────────────────────────────────────┐
│                      Cloud (Firebase)                          │
│                                                                 │
│  ┌─────────────────┐                                          │
│  │ Firebase Storage │ (Cropped Objects Only)                   │
│  └────────┬────────┘                                          │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                          │
│  │ Layer 2a: Gemini │ (Analyze cropped objects)                │
│  └────────┬────────┘                                          │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                          │
│  │ Layer 2b: SerpAPI│ (Product search)                         │
│  └────────┬────────┘                                          │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                          │
│  │ Layer 3: Claude  │ (Synthesis)                              │
│  └─────────────────┘                                          │
│                                                                 │
└───────────────────────────────────────────────────────────────┘
```

**Critical Principle**: Full photos NEVER cross the device boundary. Only cropped object regions are uploaded.

---

## Implementation

### PrivacyFirewall Service

```swift
import Foundation
import UIKit

/// Service enforcing privacy firewall (full photo deletion)
final class PrivacyFirewall {

    private let fileManager = FileManager.default
    private let temporaryStorage: TemporaryPhotoStorage

    init(temporaryStorage: TemporaryPhotoStorage) {
        self.temporaryStorage = temporaryStorage
    }

    /// Process photo with privacy firewall enforcement
    /// - Parameter photo: Full photo from camera
    /// - Returns: Array of cropped objects (full photo deleted)
    /// - Throws: PrivacyFirewallError if processing fails
    func processPhoto(_ photo: UIImage) async throws -> [CroppedObject] {
        // 1. Save full photo to temporary storage
        let tempURL = try temporaryStorage.saveTemporaryPhoto(photo)

        // Ensure full photo is deleted even if processing fails
        defer {
            do {
                try temporaryStorage.deleteTemporaryPhoto(at: tempURL)
                print("✅ Privacy firewall: Full photo deleted from \(tempURL.path)")
            } catch {
                print("⚠️ Privacy firewall: Failed to delete temp photo: \(error)")
            }
        }

        // 2. Run Vision Framework detection
        let visionService = try VisionService()
        let detectedObjects = try await visionService.detectAndCropObjects(in: photo)

        // 3. Convert to upload-ready objects
        let croppedObjects = detectedObjects.compactMap { object -> CroppedObject? in
            guard let croppedImage = object.croppedImage else {
                return nil
            }

            return CroppedObject(
                id: object.id,
                label: object.label,
                confidence: object.confidence,
                image: croppedImage
            )
        }

        // 4. Full photo automatically deleted by defer block

        return croppedObjects
    }
}

/// Object ready for cloud upload (privacy-safe)
struct CroppedObject: Identifiable {
    let id: UUID
    let label: String
    let confidence: Float
    let image: UIImage

    /// Convert to JPEG data for upload
    func toUploadData() -> Data? {
        return image.jpegData(compressionQuality: 0.8)
    }
}

enum PrivacyFirewallError: Error, LocalizedError {
    case tempStorageFailed
    case visionProcessingFailed
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .tempStorageFailed:
            return "Failed to save photo to temporary storage."
        case .visionProcessingFailed:
            return "Vision processing failed. Photo deleted for privacy."
        case .deletionFailed:
            return "Failed to delete temporary photo (privacy risk)."
        }
    }
}
```

---

### Temporary Photo Storage

```swift
import Foundation
import UIKit

/// Service for managing temporary photo storage (pre-deletion)
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

        print("📸 Temporary photo saved: \(fileURL.path)")

        return fileURL
    }

    /// Delete temporary photo (enforced by privacy firewall)
    func deleteTemporaryPhoto(at url: URL) throws {
        guard url.path.hasPrefix(fileManager.temporaryDirectory.path) else {
            throw StorageError.invalidPath
        }

        guard fileManager.fileExists(atPath: url.path) else {
            // Already deleted - this is fine
            return
        }

        try fileManager.removeItem(at: url)

        print("🗑️ Temporary photo deleted: \(url.path)")
    }

    /// Clean up all temporary photos older than 1 hour (safety measure)
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
            print("🧹 Cleaned up old temp photo: \(url.lastPathComponent)")
        }
    }
}

enum StorageError: Error {
    case invalidImageData
    case invalidPath
}
```

---

## User Consent Patterns

### Camera Permission

```swift
import AVFoundation
import UIKit

/// Manager for camera permission requests
final class CameraPermissionManager {

    /// Request camera permission with privacy-focused messaging
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return true

        case .notDetermined:
            // Request permission with privacy context
            return await AVCaptureDevice.requestAccess(for: .video)

        case .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }

    /// Show privacy-focused permission prompt
    func showPermissionRationale() -> String {
        return """
        Abundance needs camera access to catalog your items.

        Privacy Promise:
        • Photos are processed entirely on your device
        • Only small cropped images are uploaded
        • Full photos are NEVER uploaded to the cloud
        • You can delete your data anytime
        """
    }
}
```

### Permission Request UI

```swift
import SwiftUI

/// View for requesting camera permission with privacy disclosure
struct CameraPermissionView: View {

    @StateObject private var permissionManager = CameraPermissionManager()
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("Camera Access Required")
                .font(.title)
                .fontWeight(.bold)

            Text(permissionManager.showPermissionRationale())
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    let granted = await permissionManager.requestCameraPermission()
                    if !granted {
                        showingSettings = true
                    }
                }
            } label: {
                Text("Allow Camera Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Button {
                showingSettings = true
            } label: {
                Text("Learn More About Privacy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .alert("Camera Access Denied", isPresented: $showingSettings) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to use this feature.")
        }
    }
}
```

---

## Privacy-Preserving Design Patterns

### Pattern 1: Immediate Deletion

```swift
/// Ensure full photo is deleted immediately after processing
func captureAndCatalog() async throws {
    let photo = try await cameraService.capturePhoto()

    // Process with automatic deletion
    let croppedObjects = try await privacyFirewall.processPhoto(photo)

    // At this point, full photo is already deleted
    // Only cropped objects exist in memory

    // Upload cropped objects to cloud
    for object in croppedObjects {
        try await uploadCroppedObject(object)
    }
}
```

### Pattern 2: No Permanent Storage

```swift
/// Never persist full photos to permanent storage
class InvalidPattern_DoNotUse {
    func badExample(_ photo: UIImage) {
        // ❌ NEVER DO THIS - persisting full photo
        let documentsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let photoURL = documentsDir.appendingPathComponent("full_photo.jpg")
        try? photo.jpegData(compressionQuality: 1.0)?.write(to: photoURL)

        // This violates privacy firewall!
    }
}

class CorrectPattern {
    func goodExample(_ photo: UIImage) async throws {
        // ✅ CORRECT - only temporary storage, deleted after processing
        let tempURL = try temporaryStorage.saveTemporaryPhoto(photo)
        defer {
            try? temporaryStorage.deleteTemporaryPhoto(at: tempURL)
        }

        // Process and extract cropped objects
        let croppedObjects = try await processPhoto(photo)

        // Upload only cropped objects
        try await uploadObjects(croppedObjects)

        // Full photo deleted by defer block
    }
}
```

### Pattern 3: Upload Only Cropped Objects

```swift
import FirebaseStorage

/// Upload only cropped objects to Firebase Storage
func uploadCroppedObject(_ object: CroppedObject, userId: String, itemId: String) async throws -> URL {
    guard let imageData = object.toUploadData() else {
        throw UploadError.invalidImageData
    }

    let storage = Storage.storage()
    let ref = storage.reference()
        .child("users/\(userId)/items/\(itemId)/objects/\(object.id.uuidString).jpg")

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    // Upload cropped object (NOT full photo)
    _ = try await ref.putDataAsync(imageData, metadata: metadata)

    let downloadURL = try await ref.downloadURL()

    print("☁️ Uploaded cropped object: \(downloadURL)")

    return downloadURL
}

enum UploadError: Error {
    case invalidImageData
}
```

---

## Compliance Considerations

### GDPR Compliance

**Data Minimization** (Article 5):
- Only cropped objects uploaded (not full photos)
- Minimal data collection (user ID, item metadata)
- No unnecessary data retention

**Transparency** (Article 12):
- Clear privacy disclosure before camera permission
- In-app privacy policy explaining data flow
- User can view what data is stored

**Right to Erasure** (Article 17):
- User can delete account → all items and photos deleted
- Cropped objects deleted from Firebase Storage
- Firestore documents deleted (cascade)

### CCPA Compliance

**Notice at Collection**:
- Privacy disclosure shown before first camera use
- Explains what data is collected (cropped images, metadata)
- Links to full privacy policy

**Right to Delete**:
- User can delete items individually
- User can delete entire account
- Deletion removes all cloud storage (Firebase Storage + Firestore)

**Do Not Sell**:
- Abundance never sells user data
- No third-party data sharing (except AI APIs for processing)

---

## Privacy Audit Checklist

Use this checklist before releasing any feature that processes photos:

- [ ] Full photos are NEVER uploaded to cloud
- [ ] Full photos are deleted immediately after Vision processing
- [ ] Only cropped objects are stored in Firebase Storage
- [ ] Temporary storage uses device temp directory (auto-cleaned by iOS)
- [ ] Camera permission request includes privacy disclosure
- [ ] Privacy policy updated to reflect data flow
- [ ] User can delete items (and associated cropped images)
- [ ] User can delete account (cascade delete all data)
- [ ] No analytics tracking of photo content (only metadata like "item created")
- [ ] Firebase Security Rules prevent unauthorized access to images
- [ ] Cropped images use user-scoped paths (`users/{userId}/items/{itemId}/...`)
- [ ] No logging of photo URLs or payloads in production
- [ ] Test: Verify temp directory is empty after item creation
- [ ] Test: Verify full photo is not in Firebase Storage

---

## Privacy Disclosure (In-App)

### Privacy Policy Section

```
# How Abundance Protects Your Privacy

## Photos Stay on Your Device
When you take a photo to catalog an item:
1. The photo is analyzed entirely on your iPhone
2. Only small cropped images of detected items are uploaded
3. The full photo is immediately deleted from your device
4. We NEVER upload or store your full photos

## What We Store
- Small cropped images of individual items (e.g., a backpack, not your entire room)
- Item metadata (name, category, estimated value)
- Your user ID and email (if you sign in with Apple)

## What We Don't Store
- Full photos of your home
- Location data
- Contact lists
- Browsing history

## Your Data Rights
- You can delete any item (and its cropped images) anytime
- You can delete your account and all associated data
- You can export your catalog data
- You can contact us to request data deletion

## Third-Party Services
We use AI services to analyze your items:
- Google Vertex AI (Gemini): Analyzes cropped objects for attributes
- Anthropic Claude: Synthesizes product information
- SerpAPI: Searches for product matches

These services only receive cropped images, never full photos.

For questions: privacy@abundance.app
```

---

## Testing

### Unit Tests

```swift
import XCTest
@testable import AbundanceCore

class PrivacyFirewallTests: XCTestCase {

    var sut: PrivacyFirewall!
    var temporaryStorage: TemporaryPhotoStorage!
    var testImage: UIImage!

    override func setUp() {
        super.setUp()
        temporaryStorage = TemporaryPhotoStorage()
        sut = PrivacyFirewall(temporaryStorage: temporaryStorage)
        testImage = UIImage(named: "test_photo", in: Bundle(for: Self.self), with: nil)!
    }

    override func tearDown() {
        sut = nil
        temporaryStorage = nil
        testImage = nil
        super.tearDown()
    }

    func testProcessPhoto_DeletesFullPhotoAfterProcessing() async throws {
        // Given: Photo saved to temp storage
        let tempURL = try temporaryStorage.saveTemporaryPhoto(testImage)

        // When: Process photo with privacy firewall
        _ = try await sut.processPhoto(testImage)

        // Then: Full photo should be deleted
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: tempURL.path),
            "Full photo should be deleted after processing"
        )
    }

    func testProcessPhoto_DeletesPhotoEvenIfVisionFails() async {
        // Given: Invalid image that will cause Vision to fail
        let invalidImage = UIImage()

        // When: Process photo (will fail)
        do {
            _ = try await sut.processPhoto(invalidImage)
        } catch {
            // Expected to fail
        }

        // Then: Temp directory should be clean
        let tempFiles = try? FileManager.default.contentsOfDirectory(
            at: FileManager.default.temporaryDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("capture_") }

        XCTAssertTrue(tempFiles?.isEmpty ?? true, "Temp directory should be clean even after failure")
    }

    func testCleanupOldTemporaryPhotos_RemovesOldFiles() throws {
        // Given: Old temp file (simulated)
        let tempURL = try temporaryStorage.saveTemporaryPhoto(testImage)

        // Simulate old file (modify creation date)
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        try FileManager.default.setAttributes(
            [.creationDate: twoHoursAgo],
            ofItemAtPath: tempURL.path
        )

        // When: Run cleanup
        try temporaryStorage.cleanupOldTemporaryPhotos()

        // Then: Old file should be deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))
    }
}
```

### Integration Tests

```swift
func testEndToEnd_PrivacyFirewall() async throws {
    // Given
    let cameraService = MockCameraService()
    let privacyFirewall = PrivacyFirewall(temporaryStorage: TemporaryPhotoStorage())
    let uploadService = MockUploadService()

    // When: Capture photo
    let photo = try await cameraService.capturePhoto()

    // Process with privacy firewall
    let croppedObjects = try await privacyFirewall.processPhoto(photo)

    // Upload cropped objects
    for object in croppedObjects {
        try await uploadService.uploadCroppedObject(object, userId: "test_user", itemId: "test_item")
    }

    // Then: Verify no full photos in Firebase Storage
    let uploadedPaths = uploadService.uploadedPaths
    XCTAssertTrue(
        uploadedPaths.allSatisfy { $0.contains("/objects/") },
        "All uploads should be cropped objects, not full photos"
    )

    // Verify temp directory is clean
    let tempFiles = try FileManager.default.contentsOfDirectory(
        at: FileManager.default.temporaryDirectory,
        includingPropertiesForKeys: nil
    ).filter { $0.lastPathComponent.hasPrefix("capture_") }

    XCTAssertTrue(tempFiles.isEmpty, "Temp directory should be clean after processing")
}
```

---

## Acceptance Criteria

- [x] Privacy firewall enforces full photo deletion after Vision processing
- [x] Only cropped objects uploaded to Firebase Storage
- [x] Temporary storage uses device temp directory (auto-cleaned by iOS)
- [x] Camera permission request includes privacy disclosure
- [x] User can delete items and associated cropped images
- [x] User can delete account (cascade delete all data)
- [x] Firebase Security Rules prevent unauthorized access to user images
- [x] Privacy policy section explains data flow in plain language
- [x] Unit tests verify full photo deletion
- [x] Integration tests verify no full photos in cloud storage
- [x] Privacy audit checklist completed before release

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial privacy architecture spec | Computer Vision & ML Engineer |

---

**This privacy architecture ensures Abundance maintains its privacy-first positioning while enabling powerful AI cataloging features.**
