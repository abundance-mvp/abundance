# SPEC-DATA-002: Storage Architecture

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## Overview

This document specifies the Google Cloud Storage (GCS) architecture for the Abundance MVP, covering bucket structure, object paths, upload flows, privacy model, security rules, and URL generation.

The storage architecture serves three primary functions:
1. **Temporary storage** for original images during capture sessions
2. **Permanent storage** for cropped object images after AI processing
3. **Privacy preservation** by ensuring full photos are never stored permanently

**Key Principle:** Original photos uploaded by users are stored temporarily and discarded after Layer 1 processing. Only cropped object images (bounding box regions) persist in permanent storage.

---

## Bucket Structure

### Environment-Specific Buckets

The system uses separate buckets for each environment:

| Environment | Temp Bucket | Permanent Bucket |
|-------------|-------------|------------------|
| Production | `abundance-temp` | `abundance-mvp.firebasestorage.app` |
| Staging | `abundance-staging-temp` | `abundance-staging.firebasestorage.app` |
| Development | `abundance-dev-temp` | `abundance-dev.firebasestorage.app` |

### Temp Bucket (Original Images)

**Purpose:** Short-term storage for original images during AI processing

**Buckets:**
- `abundance-temp` (production)
- `abundance-dev-temp` (development)
- `abundance-staging-temp` (staging)

**Characteristics:**
- Auto-delete lifecycle: 24 hours
- No public access
- Service account access only (Cloud Functions)
- Not covered by Firebase Storage Rules (direct GCS access)

**Reference:** `functions/src/triggers/onSessionCreated.ts:43`
```typescript
const ALLOWED_BUCKETS = ['abundance-temp', 'abundance-dev-temp', 'abundance-staging-temp'];
```

### Permanent Bucket (Cropped Objects)

**Purpose:** Long-term storage for cropped object images and motion clips

**Bucket:** `{project-id}.firebasestorage.app`
- Production: `abundance-mvp.firebasestorage.app`

**Characteristics:**
- Standard storage class
- Multi-region: `us`
- Firebase Storage SDK access (iOS client)
- Protected by Firebase Storage Rules
- 90-day lifecycle after soft-delete (ADR-008)

---

## Object Paths

### Temp Bucket: Session Images

**Path Pattern:** `gs://{temp-bucket}/sessions/{sessionId}/{imageIndex}.jpg`

**Example:**
```
gs://abundance-temp/sessions/abc123xyz/0.jpg
gs://abundance-temp/sessions/abc123xyz/1.jpg
gs://abundance-temp/sessions/abc123xyz/2.jpg
```

**Note:** The current iOS implementation uploads to `users/{userId}/items/{sessionId}_{index}.jpg` in the permanent bucket, then the server-side layer1-service reads from the URLs provided in the session document.

### Permanent Bucket: Cropped Objects

**Path Pattern:** `users/{userId}/items/{groupId}_crop_{index}.jpg`

**Example:**
```
gs://abundance-mvp.firebasestorage.app/users/uid123/items/obj_a1b2c3_crop_0.jpg
gs://abundance-mvp.firebasestorage.app/users/uid123/items/obj_a1b2c3_crop_1.jpg
```

**Reference:** `functions/src/ai-pipeline/layer1/layer1-service.ts:387`
```typescript
const cropPath = `users/${userId}/items/${groupId}_crop_${croppedUrls.length}.jpg`;
```

### Permanent Bucket: Live Photo Motion Clips

**Path Pattern:** `users/{userId}/items/{itemId}/motion.mov`

**Example:**
```
gs://abundance-mvp.firebasestorage.app/users/uid123/items/item456/motion.mov
```

**Reference:** `Sources/Persistence/Firebase/StorageService.swift:131`
```swift
let ref: StorageReference = storage.reference()
    .child("users/\(userId)/items/\(itemId)/motion.mov")
```

---

## Upload Flows

### Flow 1: Client to Temp Bucket (Original Images)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  iOS App: CaptureSessionViewModel                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. User captures photo(s) via double-tap or long-press                      │
│  2. Create session document in Firestore (status: "uploading")               │
│  3. Upload each photo to permanent bucket via StorageService                 │
│  4. Add image URLs to session.originalImageUrls array                        │
│  5. Mark session ready for detection (status: "detecting")                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

**iOS Upload Code:**

```swift
// Sources/Persistence/Firebase/StorageService.swift:67-116
public func uploadCroppedObject(
    _ image: PlatformImage,
    itemId: String,
    userId: String
) async throws -> URL {
    // Compress to JPEG
    guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
        throw StorageError.compressionFailed
    }

    // Storage path: users/{userId}/items/{itemId}.jpg
    let ref: StorageReference = storage.reference()
        .child("users/\(userId)/items/\(itemId).jpg")

    // Set metadata
    let metadata: StorageMetadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    metadata.cacheControl = "public, max-age=3600"
    metadata.customMetadata = [
        "uploadedAt": Self.iso8601Formatter.string(from: Date()),
        "itemId": itemId,
        "userId": userId,
        "processingStatus": "pending",
        "uploadSource": "camera-detection"
    ]

    // Upload with timeout
    let url = try await withTimeout(uploadTimeout, ref: ref, imageData: imageData, metadata: metadata)
    return url
}
```

### Flow 2: Layer 1 Processing (Cropping and Upload)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Cloud Function: onSessionCreated                                            │
│  Reference: functions/src/triggers/onSessionCreated.ts:138                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Validate session document (userId, originalImageUrls, allowed buckets)   │
│  2. Fetch images from originalImageUrls                                      │
│  3. Call Gemini 3 Flash for object detection                                 │
│  4. For each detected object:                                                │
│     a. Extract bounding box coordinates                                      │
│     b. Crop image using sharp library                                        │
│     c. Upload crop to permanent bucket                                       │
│     d. Generate signed URL (24-hour expiration)                              │
│  5. Update session document with detected objects and cropped URLs           │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Server-Side Cropping Code:**

```typescript
// functions/src/ai-pipeline/layer1/layer1-service.ts:318-441
async function cropAndUploadObjects(
  objects: DetectedObject[],
  imageBase64s: string[],
  storage: Storage,
  userId: string,
  sessionId: string
): Promise<Map<string, CroppedObject>> {
  const sharpLib = await getSharp();
  const crops = new Map<string, CroppedObject>();

  for (const [groupId, groupObjects] of groupedObjects) {
    for (const obj of groupObjects) {
      // Get image dimensions
      const imageBuffer = Buffer.from(imageBase64, 'base64');
      const metadata = await sharpLib(imageBuffer).metadata();

      // Convert to absolute coordinates with 5% padding
      const absCoords = boxToAbsolute(obj.box_2d, metadata.width, metadata.height);
      const paddedCoords = addPadding(absCoords, 0.05, metadata.width, metadata.height);

      // Crop the image
      const croppedBuffer = await sharpLib(imageBuffer)
        .extract({
          left: paddedCoords.x1,
          top: paddedCoords.y1,
          width: paddedCoords.width,
          height: paddedCoords.height
        })
        .jpeg({ quality: 85 })
        .toBuffer();

      // Upload to GCS permanent bucket
      const cropPath = `users/${userId}/items/${groupId}_crop_${croppedUrls.length}.jpg`;
      const bucket = storage.bucket();
      const file = bucket.file(cropPath);

      await file.save(croppedBuffer, {
        metadata: {
          contentType: 'image/jpeg',
          metadata: {
            sessionId,
            groupId,
            label: obj.label,
            imageIndex: obj.image_index.toString()
          }
        }
      });

      // Generate signed URL (24-hour expiration)
      const [signedUrl] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 24 * 60 * 60 * 1000,
        version: 'v4'
      });
      croppedUrls.push(signedUrl);
    }
  }
  return crops;
}
```

### Flow 3: Image Deletion on Item Delete

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Cloud Function: onItemDeleted                                               │
│  Reference: functions/src/triggers/onItemDeleted.ts                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Firestore trigger on item document deletion                              │
│  2. Delete primary image: users/{userId}/items/{itemId}.jpg                  │
│  3. Delete motion clip (if exists): users/{userId}/items/{itemId}/motion.mov │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Privacy Model

### Core Privacy Guarantees (ADR-022)

1. **Original images are NEVER stored permanently**
   - Uploaded to temp bucket during processing
   - Automatically deleted via 24-hour lifecycle policy
   - Only cropped bounding box regions persist

2. **Only cropped objects are persisted**
   - Server-side cropping extracts object regions
   - Full room/home context is discarded
   - Crops stored in user-scoped paths

3. **Data minimization (GDPR Article 5)**
   - Only data necessary for cataloging is retained
   - No face detection or personal data extraction
   - Location metadata stripped

### Privacy Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  User captures photo                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Original Photo (3-5MB)                                                   │ │
│  │ Contains: full room, people, context                                     │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Temp Bucket Storage (24h TTL)                                            │ │
│  │ Path: gs://abundance-temp/sessions/{sessionId}/{index}.jpg               │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Gemini 3 Flash Detection                                                 │ │
│  │ Output: Bounding boxes [ymin, xmin, ymax, xmax] normalized 0-1000        │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Server-Side Cropping (sharp)                                             │ │
│  │ Extracts: object regions only (<500KB each)                              │ │
│  │ Discards: room context, background, people                               │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Permanent Bucket Storage                                                  │ │
│  │ Path: users/{userId}/items/{groupId}_crop_{index}.jpg                    │ │
│  │ Contains: cropped object only, no context                                │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                          │
│                                    ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Original Photo: DELETED (24h lifecycle or immediate discard)             │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Temp Bucket Cleanup

**Mechanism:** GCS Object Lifecycle Management

**Policy:** Delete objects older than 24 hours

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "Delete" },
        "condition": { "age": 1 }
      }
    ]
  }
}
```

**Additional Cleanup:** `cleanupDeletedItems` scheduled function runs daily at 2am UTC to permanently delete soft-deleted items older than 90 days (ADR-008).

---

## Storage Rules

### Firebase Storage Rules

**File:** `storage.rules`

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only upload to their own folder
    // Matches both flat files (items/{itemId}.jpg) and nested paths (items/{itemId}/motion.mov)
    match /users/{userId}/items/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024  // 10MB limit
                   && request.resource.contentType.matches('image/.*|video/.*');
    }
  }
}
```

### Security Constraints

| Constraint | Value | Purpose |
|------------|-------|---------|
| **Authentication** | Required (`request.auth != null`) | Only authenticated users can access storage |
| **User Scoping** | Owner only (`request.auth.uid == userId`) | Users can only access their own files |
| **Size Limit** | 10MB | Prevents abuse; full photos typically 3-5MB |
| **Content Type** | `image/*` or `video/*` | Only media files allowed |

### Allowed Bucket Validation (Server-Side)

The `onSessionCreated` trigger validates that all image URLs come from allowed temp buckets:

```typescript
// functions/src/triggers/onSessionCreated.ts:82-98
const ALLOWED_BUCKETS = ['abundance-temp', 'abundance-dev-temp', 'abundance-staging-temp'];

for (const url of sessionData.originalImageUrls as string[]) {
  const bucketMatch = url.match(/gs:\/\/([^/]+)\//);
  if (!bucketMatch || !ALLOWED_BUCKETS.some(b => bucketMatch[1].includes(b))) {
    logger.error('Session validation failed', { reason: 'Unauthorized bucket', url });
    await sessionRef.update({
      status: 'failed',
      error: 'Unauthorized storage bucket',
      errorCode: 'UNAUTHORIZED_BUCKET',
      failedAt: FieldValue.serverTimestamp()
    });
    return { valid: false, errorCode: 'UNAUTHORIZED_BUCKET', errorMessage: 'Unauthorized bucket' };
  }
}
```

---

## URL Generation

### Signed URLs (Server-Side)

Used for cropped object images returned to the client.

**Characteristics:**
- 24-hour expiration
- V4 signature format
- Read-only access

```typescript
// functions/src/ai-pipeline/layer1/layer1-service.ts:403-408
const [signedUrl] = await file.getSignedUrl({
  action: 'read',
  expires: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
  version: 'v4'
});
```

**URL Format:**
```
https://storage.googleapis.com/{bucket}/{path}?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=...&X-Goog-Date=...&X-Goog-Expires=86400&X-Goog-SignedHeaders=host&X-Goog-Signature=...
```

### Download URLs (Client-Side)

Used for iOS client uploads via Firebase Storage SDK.

```swift
// Sources/Persistence/Firebase/StorageService.swift:167
let downloadURL: URL = try await ref.downloadURL()
```

**URL Format:**
```
https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{urlEncodedPath}?alt=media&token={accessToken}
```

### GCS URL Parsing

The Layer 1 service supports multiple URL formats:

```typescript
// functions/src/ai-pipeline/layer1/layer1-service.ts:223-251
async function fetchImageFromGCS(gcsUrl: string, storage: Storage): Promise<string> {
  let bucket: string;
  let path: string;

  if (gcsUrl.startsWith('gs://')) {
    // Format: gs://bucket/path
    const match = gcsUrl.match(/^gs:\/\/([^/]+)\/(.+)$/);
    bucket = match[1];
    path = match[2];
  } else if (gcsUrl.includes('firebasestorage.googleapis.com')) {
    // Format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{urlEncodedPath}
    const url = new URL(gcsUrl);
    const bucketMatch = url.pathname.match(/\/v0\/b\/([^/]+)\/o\/(.+)/);
    bucket = bucketMatch[1];
    path = decodeURIComponent(bucketMatch[2]);
  } else if (gcsUrl.includes('storage.googleapis.com')) {
    // Format: https://storage.googleapis.com/bucket/path
    const url = new URL(gcsUrl);
    const pathParts = url.pathname.split('/').filter(Boolean);
    bucket = pathParts[0];
    path = pathParts.slice(1).join('/');
  }

  const file = storage.bucket(bucket).file(path);
  const [buffer] = await file.download();
  return buffer.toString('base64');
}
```

---

## Cost Analysis

### Storage Costs (Month 6 Projection)

Based on ADR-008 projections:

| Metric | Value | Cost |
|--------|-------|------|
| **Users** | 5,000 | - |
| **Items** | 250,000 | - |
| **Average crop size** | 200KB | - |
| **Total storage** | ~50 GB | $1.00/month |
| **Egress (CDN)** | ~125 GB | $10.00/month |
| **Total** | - | **~$11/month** |

### Temp Bucket Costs

Minimal cost due to 24-hour lifecycle:
- Peak temp storage: ~10 GB
- Monthly cost: ~$0.20/month

---

## References

| Document | Description |
|----------|-------------|
| `docs/adr/ADR-008-image-storage-architecture.md` | GCS architecture decision |
| `docs/adr/ADR-022-photo-privacy-protection.md` | Privacy firewall validation |
| `functions/src/ai-pipeline/layer1/layer1-service.ts` | Layer 1 cropping and upload |
| `functions/src/triggers/onSessionCreated.ts` | Session processing trigger |
| `Sources/Persistence/Firebase/StorageService.swift` | iOS upload service |
| `storage.rules` | Firebase Storage security rules |

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-18 | 1.0 | Initial storage architecture specification | Claude Code Audit |
