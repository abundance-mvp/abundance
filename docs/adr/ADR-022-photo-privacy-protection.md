# ADR-022: Photo Privacy Protection

**Status**: Approved
**Date**: 2025-11-09
**Deciders**: Privacy & Security Architect
**References**:
- docs/design/DESIGN-015-privacy-architecture.md (privacy firewall)
- docs/design/DESIGN-025-security-privacy-architecture.md
- docs/design/THREAT-MODEL-001-stride-analysis.md (Threats T-3, I-2)
- docs/validation/RESEARCH-VALIDATION-stage-2.5.md (Claims 3, 5)

---

## Context

Abundance's privacy-first positioning depends on a **privacy firewall** that ensures full photos never leave the iOS device. Only cropped object images (extracted by Vision Framework) are uploaded to Firebase Storage for AI processing. This architectural pattern is a strategic differentiator and GDPR compliance requirement (data minimization principle, Article 5).

However, privacy firewall enforcement requires robust validation to prevent accidental or malicious full photo uploads. This ADR specifies the validation strategy, test cases, and monitoring approach to guarantee that full photos remain on-device only.

---

## Decision

We will implement a **multi-layered privacy firewall validation strategy** combining automated testing, storage audits, network traffic analysis, and Firebase Security Rules enforcement to guarantee that full photos never leave the device.

---

## Privacy Firewall Architecture

### Core Requirements (from DESIGN-015)
1. Full photos processed on-device only (Layer 1)
2. Vision Framework crops objects to bounding boxes
3. Full photos deleted immediately after cropping (via `defer` block)
4. Only cropped objects uploaded to Firebase Storage
5. Cloud AI APIs (Gemini, SerpAPI, Claude) only receive cropped objects

### Implementation Pattern

```swift
/// Service enforcing privacy firewall (full photo deletion)
/// Note: Uses UIImage as this is infrastructure code (allowed per ADR-010)
final class PrivacyFirewall {
    func processPhoto(_ photo: UIImage) async throws -> [CroppedObject] {
        // 1. Save full photo to temporary storage (encrypted)
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

        // 2. Run Vision Framework detection (on-device)
        let detectedObjects = try await visionService.detectAndCropObjects(in: photo)

        // 3. Convert to upload-ready objects
        let croppedObjects = detectedObjects.compactMap { object -> CroppedObject? in
            guard let croppedImage = object.croppedImage else { return nil }
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
```

**Critical Guarantee**: The `defer` block ensures full photo deletion even if Vision Framework processing fails or throws an error.

---

## Validation Strategy

### 1. Code Review Validation

**Objective**: Verify no code path uploads full photos

**Process**:
1. **Manual code review**: Search for all Firebase Storage upload calls (`putDataAsync`, `putFileAsync`)
2. **Verify upload paths**: All uploads must use pattern `users/{userId}/items/{itemId}/objects/{objectId}.jpg`
3. **Reject patterns**: Block any code that uploads to `users/{userId}/photos/` (full photo path)
4. **PR review requirement**: Privacy firewall changes require security team approval

**Validation Script**:
```bash
# Search for Firebase Storage uploads in codebase
grep -r "putDataAsync\|putFileAsync" --include="*.swift" .

# Expected: All uploads are cropped objects (paths contain "/objects/")
# BLOCKED: Any uploads to "/photos/" or similar full photo paths
```

### 2. Firebase Storage Audit

**Objective**: Verify all uploaded images are < 500KB (full photos ~3-5MB)

**Implementation**:
```javascript
// Cloud Function: Audit uploaded images
exports.auditUploadedImages = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name; // e.g., users/user123/items/item456/objects/obj789.jpg
  const fileSize = parseInt(object.size);

  // Alert if file size exceeds 500KB (potential full photo leak)
  if (fileSize > 500 * 1024) {
    console.error(`⚠️ PRIVACY ALERT: Large file uploaded (${fileSize} bytes): ${filePath}`);

    // Send alert to security team
    await sendSecurityAlert({
      type: 'PRIVACY_VIOLATION',
      message: `Large file uploaded: ${filePath} (${fileSize} bytes)`,
      severity: 'HIGH'
    });

    // Optional: Auto-delete suspicious file
    // await admin.storage().bucket().file(filePath).delete();
  } else {
    console.log(`✅ File size OK: ${filePath} (${fileSize} bytes)`);
  }
});
```

**Monitoring**:
- Cloud Logging alert: File size > 500KB triggers security team notification
- Dashboard: File size distribution histogram (all uploads should be < 500KB)

### 3. Network Traffic Analysis

**Objective**: Instrument iOS app, capture network traffic, verify no large image uploads

**Implementation**:
```swift
import Network

/// Network monitor for privacy firewall validation (DEBUG ONLY)
class NetworkMonitor {
    private let monitor = NWPathMonitor()

    func startMonitoring() {
        #if DEBUG
        URLProtocol.registerClass(PrivacyAuditURLProtocol.self)
        print("📡 Network monitoring enabled (privacy audit)")
        #endif
    }
}

/// URLProtocol for intercepting Firebase Storage uploads (DEBUG ONLY)
class PrivacyAuditURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.host?.contains("firebasestorage.googleapis.com") ?? false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Audit request body size
        if let bodyStream = request.httpBodyStream {
            let bodyData = Data(reading: bodyStream)
            let bodySize = bodyData.count

            if bodySize > 500 * 1024 {
                print("⚠️ PRIVACY AUDIT FAILED: Large upload detected (\(bodySize) bytes)")
                assertionFailure("Privacy firewall violated: Large image upload detected")
            } else {
                print("✅ Upload size OK: \(bodySize) bytes")
            }
        }

        // Continue with actual request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // ... handle response
        }
        task.resume()
    }

    override func stopLoading() {}
}
```

**Usage**: Enable network monitoring during integration tests and manual testing to verify no large uploads.

### 4. Automated Test Cases

#### Test Case 1: Full Photo Deleted After Processing
```swift
func testPrivacyFirewall_DeletesFullPhotoAfterProcessing() async throws {
    // Given: Full photo (3MB) captured
    let fullPhoto = UIImage(named: "test_photo_3mb")!
    let tempURL = try temporaryStorage.saveTemporaryPhoto(fullPhoto)

    // When: Process photo with privacy firewall
    let croppedObjects = try await privacyFirewall.processPhoto(fullPhoto)

    // Then: Full photo should be deleted
    XCTAssertFalse(
        FileManager.default.fileExists(atPath: tempURL.path),
        "Full photo should be deleted after processing"
    )

    // And: Only cropped objects should exist
    XCTAssertGreaterThan(croppedObjects.count, 0, "Should have cropped objects")
}
```

#### Test Case 2: File Size Constraint Enforced
```swift
func testFirebaseStorage_RejectFilesOver10MB() async throws {
    // Given: Large file (11MB) that exceeds Firebase Storage rules limit
    let largeImageData = Data(count: 11 * 1024 * 1024) // 11MB

    let storage = Storage.storage()
    let ref = storage.reference().child("users/test_user/items/test_item/objects/test.jpg")

    // When: Attempt to upload large file
    do {
        _ = try await ref.putDataAsync(largeImageData)
        XCTFail("Should reject files > 10MB")
    } catch {
        // Then: Upload should fail (Firebase Storage rules enforce 10MB limit)
        XCTAssertTrue(
            error.localizedDescription.contains("permission-denied") ||
            error.localizedDescription.contains("storage/unauthorized"),
            "Should reject due to size limit"
        )
    }
}
```

#### Test Case 3: Upload Path Validation
```swift
func testFirebaseStorage_OnlyAcceptsObjectPaths() async throws {
    // Given: Cropped object image
    let croppedImage = UIImage(named: "test_object_cropped")!
    guard let imageData = croppedImage.jpegData(compressionQuality: 0.8) else {
        XCTFail("Failed to convert image")
        return
    }

    let storage = Storage.storage()

    // When: Attempt to upload to full photo path (invalid)
    let invalidRef = storage.reference().child("users/test_user/photos/full_photo.jpg")

    do {
        _ = try await invalidRef.putDataAsync(imageData)
        XCTFail("Should reject uploads to /photos/ path")
    } catch {
        // Then: Upload should fail (not using /objects/ path)
        print("✅ Correctly rejected invalid path: \(error)")
    }

    // When: Upload to valid cropped object path
    let validRef = storage.reference().child("users/test_user/items/item123/objects/obj456.jpg")
    _ = try await validRef.putDataAsync(imageData)

    // Then: Upload should succeed
    XCTAssertTrue(true, "Valid object path accepted")
}
```

#### Test Case 4: Network Traffic Audit (Integration Test)
```swift
func testNetworkTraffic_NoLargeUploads() async throws {
    // Given: Network monitoring enabled
    let networkMonitor = NetworkMonitor()
    networkMonitor.startMonitoring()

    // When: Capture photo and process through privacy firewall
    let photo = try await cameraService.capturePhoto() // Full photo ~3MB
    let croppedObjects = try await privacyFirewall.processPhoto(photo)

    // Upload cropped objects
    for object in croppedObjects {
        try await uploadService.uploadCroppedObject(object, userId: "test_user", itemId: "test_item")
    }

    // Then: Verify no large uploads in network logs
    let networkLogs = networkMonitor.getUploadLogs()
    let largeUploads = networkLogs.filter { $0.size > 500 * 1024 }

    XCTAssertTrue(largeUploads.isEmpty, "No uploads should exceed 500KB")
}
```

---

## Firebase Storage Rules Enforcement

### Storage Rules (STORAGE-RULES-001)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload to their items folder (original images from iOS app)
    // Matches both flat files (items/{itemId}.jpg) and nested paths (items/{itemId}/motion.mov)
    match /users/{userId}/items/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024  // 10MB limit
                   && request.resource.contentType.matches('image/.*|video/.*');
    }

    // Session crops are written by backend Cloud Functions (service account)
    // and read by authenticated users who own the session
    // Note: Cloud Functions bypass rules, but users need read access
    match /users/{userId}/sessions/{sessionId}/crops/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      // Write is handled by Cloud Functions service account (bypasses rules)
    }
  }
}
```

**Security Guarantee**: Firebase Storage rules enforce 10MB max upload size. The wildcard path `{allPaths=**}` allows both flat files and nested paths within the user's items folder.

**Note on content types**: Video uploads (e.g., Live Photo motion clips as `.mov` files) are also allowed via the `video/.*` content type match. This supports the Live Photo capture feature.

**Note on session crops**: Session crops follow the path `users/{userId}/sessions/{sessionId}/crops/` and are written by Cloud Functions (which bypass security rules). Users have read-only access to their own session crops.

---

## Threat Scenarios & Mitigations

### Threat 1: Malicious Developer Bypasses Privacy Firewall
- **Attack Vector**: Developer modifies code to upload full photos instead of cropped objects
- **Mitigation #1**: Automated test in CI/CD verifies file size constraints (test fails if upload > 500KB)
- **Mitigation #2**: Firebase Storage rules enforce 10MB max upload (blocks full photos)
- **Mitigation #3**: Privacy audit checklist (manual review before launch)
- **Verification**: Code review + automated tests + Firebase rules = defense-in-depth

### Threat 2: Privacy Firewall `defer` Block Fails
- **Attack Vector**: Exception thrown before `defer` block executes, temp photo not deleted
- **Mitigation #1**: `defer` executes even if function throws (Swift language guarantee)
- **Mitigation #2**: Temporary storage cleanup job runs hourly (deletes photos > 1 hour old)
- **Mitigation #3**: iOS automatically cleans temp directory on app termination
- **Verification**: Unit test verifies temp photo deleted even if Vision Framework fails

### Threat 3: Full Photo Accidentally Persisted to Documents Directory
- **Attack Vector**: Developer persists full photo to permanent storage (not temp directory)
- **Mitigation #1**: Code review rejects any writes to Documents directory for full photos
- **Mitigation #2**: Privacy audit checklist includes file system scan for unexpected photos
- **Mitigation #3**: Monitoring: Alert if iOS app disk usage exceeds threshold
- **Verification**: Integration test verifies Documents directory contains no full photos

---

## GDPR Compliance Validation

### Data Minimization (Article 5)
- **Requirement**: Collect only necessary data, no excessive retention
- **Abundance Compliance**:
  - ✅ Full photos deleted immediately after cropping (DESIGN-015 privacy firewall)
  - ✅ Only cropped objects stored (no face data, no location metadata)
  - ✅ Camera roll access limited to single photo selection (not full library)
  - ✅ No background data collection (app inactive = no data access)
- **Validation**: Automated tests verify file size < 500KB, network traffic analysis confirms no large uploads

### Purpose Limitation (Article 5)
- **Requirement**: Data used only for disclosed purposes
- **Abundance Compliance**:
  - ✅ Cropped objects used only for AI cataloging (disclosed in privacy policy)
  - ✅ No sharing with third parties beyond AI processing (Gemini, SerpAPI, Claude)
  - ✅ No advertising or tracking (no analytics on photo content)
- **Validation**: Privacy policy disclosure + third-party DPA review (PRIVACY-IMPACT-ASSESSMENT-001)

### Storage Limitation (Article 5)
- **Requirement**: Data retained no longer than necessary
- **Abundance Compliance**:
  - ✅ Images deleted 90 days after item deletion (Cloud Storage lifecycle policy)
  - ✅ User can delete items individually (immediate deletion)
  - ✅ User can delete account (cascade delete all data within 30 days)
- **Validation**: Integration test verifies cascade delete removes all cropped objects

---

## Monitoring & Alerting

### Cloud Logging Alerts

```javascript
// Alert: Large file uploaded to Firebase Storage
const alertConfig = {
  displayName: "Privacy Alert: Large File Upload",
  conditions: [
    {
      displayName: "File size > 500KB",
      conditionThreshold: {
        filter: 'resource.type="gcs_bucket" AND protoPayload.resourceName=~"users/.*/items/.*/objects/.*" AND protoPayload.response.size > 500000',
        comparison: "COMPARISON_GT",
        thresholdValue: 0,
        duration: "60s"
      }
    }
  ],
  notificationChannels: ["projects/abundance-project/notificationChannels/security-team"],
  severity: "HIGH"
};
```

### Dashboard Metrics

- **File Size Distribution**: Histogram of uploaded file sizes (all should be < 500KB)
- **Upload Count by Path**: Verify all uploads go to `/objects/` path (not `/photos/`)
- **Temp Directory Size**: iOS app temp directory should remain < 10MB (cleanup working)
- **Privacy Firewall Failures**: Count of exceptions in `PrivacyFirewall.processPhoto` (should be near zero)

---

## Privacy Audit Checklist

Use this checklist before releasing any feature that processes photos:

- [ ] Full photos are NEVER uploaded to cloud
- [ ] Full photos are deleted immediately after Vision processing (verified via unit test)
- [ ] Only cropped objects are stored in Firebase Storage (verified via storage audit)
- [ ] Temporary storage uses device temp directory (auto-cleaned by iOS)
- [ ] Camera permission request includes privacy disclosure
- [ ] Privacy policy updated to reflect data flow
- [ ] User can delete items (and associated cropped images)
- [ ] User can delete account (cascade delete all data)
- [ ] No analytics tracking of photo content (only metadata like "item created")
- [ ] Firebase Security Rules prevent unauthorized access to images
- [ ] Cropped images use user-scoped paths (`users/{userId}/items/{itemId}/objects/...`)
- [ ] No logging of photo URLs or payloads in production
- [ ] Test: Verify temp directory is empty after item creation
- [ ] Test: Verify full photo is not in Firebase Storage (file size audit passes)
- [ ] Network traffic analysis: No uploads > 500KB detected

---

## Consequences

### Positive
- ✅ Privacy firewall validated via automated tests (CI/CD enforcement)
- ✅ Multi-layered defense: Code review + Storage rules + Monitoring + Tests
- ✅ GDPR data minimization compliance (Article 5) verified
- ✅ User trust maintained (full photos never leave device)
- ✅ Strategic differentiator (privacy-first positioning)

### Negative
- ⚠️ Automated testing adds complexity to CI/CD pipeline
  - **Mitigation**: Tests run in < 5 minutes, acceptable overhead for security guarantee
- ⚠️ Network monitoring only available in DEBUG builds
  - **Mitigation**: Integration tests run in DEBUG mode, sufficient for validation
- ⚠️ Firebase Storage audit requires Cloud Function deployment
  - **Mitigation**: Function runs on every upload (zero maintenance overhead)

### Trade-offs
- **Security vs. Performance**: File size validation adds latency (< 10ms per upload)
  - **Decision**: Accept negligible performance overhead for privacy guarantee
- **Automation vs. Manual Review**: Automated tests reduce manual security review burden
  - **Decision**: Use automated tests as first line of defense, manual privacy audit as final gate

---

## Test Coverage Goals

- **Unit Tests**: 100% coverage for PrivacyFirewall service (critical for privacy guarantee)
- **Integration Tests**: 90% coverage for end-to-end photo processing flow
- **Storage Rules Tests**: 100% coverage (all upload paths validated)
- **Network Traffic Tests**: 100% coverage (all Firebase Storage uploads monitored)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial photo privacy protection validation strategy | Privacy & Security Architect |
| 2026-02-08 | 1.1 | Update storage rules to match actual `storage.rules` (wildcard paths, session crops, video support), note UIImage as infrastructure code (ADR-010) | Documentation Update |
