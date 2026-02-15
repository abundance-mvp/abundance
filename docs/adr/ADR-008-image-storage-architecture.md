# ADR-008: Image Storage Architecture

**Status**: Approved (Revised 2026-02-08)
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, Backend Developer, iOS Developer
**Related Documents**:
- docs/adr/ADR-002-platform-strategy.md (GCP platform)
- docs/adr/ADR-016-image-hosting-strategy.md (Stage 2.0 research)
- docs/design/DESIGN-004-computer-vision-pipeline.md (privacy firewall)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Context

Abundance needs image storage for:
- **Cropped objects**: Bounding box regions extracted by iOS app (Layer 1 output)
- **SerpAPI visual search**: Requires public HTTPS URLs (ADR-016 finding)
- **Catalog display**: iOS app downloads images to show user's catalog
- **Privacy firewall**: Full photos never leave device (only cropped objects uploaded)

**Requirements**:
- GCP platform (ADR-002): Native Firebase/GCP integration
- Public HTTPS URLs (SerpAPI requirement from Stage 2.0 research)
- Global CDN (low-latency image delivery worldwide)
- Cost-efficient (free tier for MVP, low storage cost at scale)
- Lifecycle management (auto-delete old images to save storage)

---

## Decision

**Use Google Cloud Storage (GCS) with Cloud CDN for all image storage.**

### Specifications

- **Storage Service**: Google Cloud Storage (Standard class)
- **CDN**: Cloud CDN (global edge caching)
- **Bucket**: `abundance-prod-images` (multi-region: `us`)
- **Access Control**: Signed URLs (temporary public access, 1-hour expiration)
- **Lifecycle Policy**: Auto-delete images 90 days after item deletion
- **Pricing**: $0.020/GB storage + $0.08/GB egress (Cloud CDN)

---

## Rationale

### 1. SerpAPI Requires Public HTTPS URLs (Critical Requirement)

**Finding from ADR-016** (Stage 2.0 research): SerpAPI Google Lens API requires images to be accessible via public HTTPS URLs.

**SerpAPI API Contract**:
```bash
curl -X POST "https://serpapi.com/search.json" \
  -d "engine=google_lens" \
  -d "url=https://storage.googleapis.com/abundance-prod/items/item_123.jpg" \
  -d "api_key=..."
```

**Solution**: GCS buckets can serve images via public URLs with Cloud CDN.

**Security**: Firebase Storage security rules control access (from `storage.rules`):

```
// Users can upload to their items folder
match /users/{userId}/items/{allPaths=**} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null
               && request.auth.uid == userId
               && request.resource.size < 10 * 1024 * 1024  // 10MB limit
               && request.resource.contentType.matches('image/.*|video/.*');
}

// Session crops: written by Cloud Functions, read by owner
match /users/{userId}/sessions/{sessionId}/crops/{allPaths=**} {
  allow read: if request.auth != null && request.auth.uid == userId;
  // Write handled by Cloud Functions service account (bypasses rules)
}
```

**Content types**: Both `image/*` and `video/*` are allowed (supports Live Photo motion clips as `.mov` files).

**Cloud Functions access**: Backend functions use the Admin SDK which bypasses security rules entirely. For SerpAPI tool calls, the Gemini service fetches images via the Admin SDK and converts to base64, or uses signed URLs (15-minute expiration) when needed.

**Outcome**: User data is isolated by `userId` path segment, with 10MB upload limit and content type restrictions.

---

### 2. GCP-Native Service (No Cross-Cloud Latency)

**Requirement** (ADR-002): GCP platform for backend infrastructure.

**Solution**: GCS is a native GCP service, seamlessly integrated with Cloud Functions and Firestore.

**Integration Benefits**:
- **Cloud Functions**: Upload images directly from Cloud Functions (no external API)
- **Firebase SDK**: iOS app uploads via Firebase Storage SDK (wrapper around GCS)
- **Firestore**: Store image URLs in Firestore documents, images in GCS
- **Cloud CDN**: Automatic caching at Google's global edge network (no separate CDN setup)

**Example** (iOS upload):
```swift
import FirebaseStorage

let storage = Storage.storage()
let storageRef = storage.reference()
let imageRef = storageRef.child("users/\(userId)/items/\(itemId).jpg")

imageRef.putData(imageData, metadata: nil) { metadata, error in
    guard let metadata = metadata else { return }
    imageRef.downloadURL { url, error in
        // url = "https://firebasestorage.googleapis.com/v0/b/{bucket}/o/..."
        // Save URL to Firestore item document
    }
}
```

**Outcome**: Zero cross-cloud latency (iOS → GCS within GCP network).

---

### 3. Cloud CDN (Global Low-Latency Delivery)

**Requirement**: Catalog images should load fast for users worldwide.

**Solution**: Cloud CDN caches images at Google's 100+ edge locations globally.

**How it works**:
1. User in Tokyo requests `https://storage.googleapis.com/.../item_123.jpg`
2. Cloud CDN serves from Tokyo edge cache (if cached) → 20-50ms latency
3. If not cached, Cloud CDN fetches from GCS us-central1 → caches for future requests

**Performance**:
- **Cache hit**: 20-50ms (edge location)
- **Cache miss**: 200-300ms (origin fetch + cache population)
- **Cache TTL**: 1 hour (configurable via `Cache-Control` headers)

**Cost**:
- Cache egress: $0.08/GB (vs $0.12/GB direct GCS egress)
- Cache operations: Free

**Outcome**: Global users get fast image loads (20-50ms for cached images).

---

### 4. Cost Efficiency (Free Tier + Low Storage Cost)

**Requirement**: Free tier should support 85% of users (4,250 users @ Month 6).

**Cost Analysis** (Month 6: 5,000 users, 250K items):

**GCS Free Tier**:
- Storage: 5 GB/month (free)
- Egress: 1 GB/month to Americas (free)

**Projected Usage**:
- Images: 250K items × 500 KB/image = **125 GB storage**
- Storage cost: 125 GB × $0.020/GB = **$2.50/month**
- Egress: 5K users × 50 images viewed/month × 500 KB = **125 GB egress**
- Cloud CDN egress: 125 GB × $0.08/GB = **$10.00/month**
- **Total**: **$12.50/month**

**Month 12** (10K users, 750K items):
- Storage: 750K items × 500 KB = **375 GB** → 375 × $0.020 = **$7.50/month**
- Egress: 10K users × 75 images/month × 500 KB = **375 GB** → 375 × $0.08 = **$30.00/month**
- **Total**: **$37.50/month**

**Outcome**: Image storage cost is low ($12.50/month Month 6) compared to AI API costs ($367-$1,466/month).

---

### 5. Lifecycle Management (Auto-Delete Old Images)

**Requirement**: Minimize storage costs by deleting images when items are removed from catalog.

**Solution**: GCS Lifecycle Management rules auto-delete images after user deletes catalog item.

**Lifecycle Rule**:
```json
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "Delete" },
        "condition": { "daysSinceCustomTime": 90 }
      }
    ]
  }
}
```

**How it works**:
1. User deletes item from catalog → Cloud Function sets `customTime` metadata on GCS object
2. GCS Lifecycle Management checks daily → deletes images 90 days after `customTime`
3. Storage cost reduced automatically (no manual cleanup needed)

**Alternative**: Immediate deletion when user deletes item (Cloud Function deletes GCS object synchronously)
- **Trade-off**: User might restore deleted item within 90 days (grace period)
- **Decision**: Use 90-day grace period (better UX, small storage cost)

**Outcome**: Storage cost scales with active catalog size (not total items ever uploaded).

---

## Alternatives Considered

### Alternative 1: Firebase Storage (GCS Wrapper)

**Approach**: Use Firebase Storage SDK instead of raw GCS.

**Pros**:
- **Simpler iOS integration**: Firebase Storage SDK handles authentication automatically
- **Security Rules**: Firestore-like rules for access control
- **Same underlying storage**: Firebase Storage is a wrapper around GCS

**Cons**:
- **No functional difference**: Firebase Storage = GCS with SDK wrapper
- **Vendor lock-in**: Firebase SDK proprietary (vs standard GCS client libraries)

**Decision**: Use Firebase Storage SDK for iOS uploads (simpler), but treat as GCS underneath (architecture docs reference GCS).

**Why Not Rejected**: Firebase Storage is the recommended way to use GCS from iOS (per Google best practices).

---

### Alternative 2: AWS S3 + CloudFront

**Approach**: Use AWS S3 for storage + CloudFront for CDN.

**Pros**:
- **Mature ecosystem**: S3 is industry-standard object storage
- **Global CDN**: CloudFront has 400+ edge locations (vs 100+ Cloud CDN)

**Cons**:
- **Cross-cloud latency**: Backend on GCP (Cloud Functions), storage on AWS (S3)
- **Increased complexity**: Manage AWS credentials, cross-cloud networking
- **Cost**: S3 $0.023/GB (vs GCS $0.020/GB), CloudFront $0.085/GB (vs Cloud CDN $0.08/GB)
- **Platform fragmentation**: Violates GCP platform decision (ADR-002)

**Why Rejected**: Cross-cloud architecture adds latency and complexity. GCS/Cloud CDN sufficient for global delivery.

---

### Alternative 3: Cloudflare R2 (S3-Compatible, Zero Egress Fees)

**Approach**: Use Cloudflare R2 for storage (S3-compatible API, $0/GB egress).

**Pros**:
- **Zero egress fees**: $0.015/GB storage, $0/GB egress (vs GCS $0.08/GB egress)
- **Cost savings**: Month 6 egress = 125 GB × $0 = $0 (vs $10 Cloud CDN)

**Cons**:
- **Cross-platform**: Not GCP-native (violates ADR-002)
- **Separate credentials**: Manage Cloudflare API keys separate from GCP
- **No Firebase SDK support**: iOS app would need custom S3-compatible client
- **Ecosystem fragmentation**: Backend on GCP, storage on Cloudflare

**Why Rejected**: Platform fragmentation outweighs egress cost savings ($10/month negligible for MVP).

---

## Implications & Consequences

### Positive

1. **SerpAPI Compatible**: Public HTTPS URLs satisfy SerpAPI requirement (ADR-016)
2. **GCP-Native**: Zero cross-cloud latency, seamless Cloud Functions integration
3. **Global CDN**: Cloud CDN caches images at 100+ edge locations (20-50ms latency)
4. **Low Cost**: $12.50/month Month 6 (vs $367 AI costs), storage cost scales with catalog size
5. **Privacy Firewall**: Only cropped objects uploaded (full photos stay on-device per DESIGN-004)

---

### Negative

1. **Public URL Security Risk**: Signed URLs expire after 1 hour, but theoretically could be intercepted
   - **Mitigation**: Cropped objects are not sensitive (no full home photos), 1-hour expiration limits exposure
2. **Egress Cost Scales with Usage**: Heavy image viewing (e.g., marketplace browsing) increases egress cost
   - **Mitigation**: Cloud CDN caching reduces egress (cache hit = no origin fetch), acceptable for MVP
3. **No Multi-Cloud Redundancy**: Single GCS bucket (no AWS S3 backup)
   - **Mitigation**: GCS multi-region (`us`) provides 99.95% availability SLA, acceptable for MVP

---

## Implementation Details

### GCS Bucket Configuration

**Bucket Name**: `abundance-prod-images`

**Region**: `us` (multi-region, covers us-east1, us-central1, us-west1)

**Storage Class**: Standard (optimized for frequent access)

**Access Control**: Uniform (bucket-level IAM, no legacy ACLs)

**CORS Configuration** (for iOS uploads):
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

**Lifecycle Rule**:
```json
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "Delete" },
        "condition": { "daysSinceCustomTime": 90 }
      }
    ]
  }
}
```

---

### Directory Structure

**Storage Paths** (from `storage.rules`):

The storage bucket uses a user-scoped path structure:

```
{bucket}/
├── users/
│   ├── {userId}/
│   │   ├── items/
│   │   │   ├── {itemId}.jpg                    (primary image from iOS)
│   │   │   ├── {itemId}_crop_0.jpg             (cropped object from Layer 1)
│   │   │   ├── {itemId}_crop_1.jpg             (additional crop)
│   │   │   ├── {itemId}_photo_0.jpg            (additional photo)
│   │   │   ├── {itemId}/motion.mov             (Live Photo motion clip)
│   │   │   └── ...
│   │   └── sessions/
│   │       └── {sessionId}/
│   │           └── crops/
│   │               └── {allPaths=**}           (session crop images)
```

**Naming Convention**: `users/{userId}/items/{itemId}.jpg` (primary), `users/{userId}/items/{itemId}_crop_{index}.jpg` (crops)

**Session Crops**: `users/{userId}/sessions/{sessionId}/crops/{allPaths=**}` (written by Cloud Functions service account, read by authenticated owner)

---

### iOS Upload Flow

1. iOS app captures image (single, burst, or sweep mode)
2. iOS app uploads image to Firebase Storage at `users/{userId}/items/{itemId}.jpg`
3. Firebase Storage returns download URL
4. iOS app creates Firestore item document with `imageUrl` field
5. Firestore trigger (`onItemCreatedGemini3`) fires and fetches image via Admin SDK (bypasses security rules)
6. Image sent to Gemini 3 Pro for cataloging; Gemini may invoke Google Lens tool with the image URL

---

### Cloud Function Image Deletion

**Trigger**: Firestore `items/{itemId}` document deleted (implemented in `functions/src/triggers/onItemDeleted.ts`)

The `onItemDeleted` trigger cleans up all associated storage files when an item is deleted:

1. Primary image: `users/{userId}/items/{itemId}.jpg`
2. Cropped images: `users/{userId}/items/{itemId}_crop_*.jpg` (listed by prefix)
3. Additional photos: `users/{userId}/items/{itemId}_photo_*.jpg` (listed by prefix)
4. Live Photo motion clip: `users/{userId}/items/{itemId}/motion.mov`

Files are deleted immediately (not deferred with lifecycle rules). The trigger handles missing files gracefully (404 errors are logged but not thrown).

---

### Monitoring & Alerts

**GCS Metrics** (Cloud Monitoring):
- Storage usage (alert if > 500 GB)
- Egress bandwidth (alert if > 200 GB/month)
- Request rate (alert if > 10K requests/minute)

**Budget Alert**: Email notification if storage cost > $50/month

---

## Acceptance Criteria

- [x] ✅ GCS bucket created (`abundance-prod-images`, multi-region `us`)
- [x] ✅ Cloud CDN enabled (global edge caching)
- [x] ✅ Signed URLs tested (1-hour expiration, SerpAPI-compatible)
- [x] ✅ iOS Firebase Storage SDK integration tested (upload + download)
- [x] ✅ Lifecycle policy configured (90-day deletion after item removal)
- [x] ✅ CORS configured (iOS app can upload directly to GCS)

---

## Related Decisions

- **ADR-002**: Platform strategy (GCP) → GCS is native GCP service
- **ADR-016**: Image hosting strategy (Stage 2.0) → SerpAPI requires public HTTPS URLs
- **DESIGN-004**: AI pipeline (privacy firewall) → Only cropped objects uploaded, not full photos
- **ADR-006**: Database (Firestore) → Image URLs stored in Firestore documents

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, GCS + Cloud CDN for image storage | Software Architecture Expert |
| 2026-02-08 | 1.1 | Updated storage paths to match actual storage.rules (users/{userId}/items/{allPaths=**}), added session crop path, updated content type rules (image+video), updated deletion flow to match onItemDeleted trigger | Documentation Agent |

---

**This image storage architecture supports SerpAPI integration (ADR-016), GCP platform (ADR-002), privacy firewall (DESIGN-004), and global low-latency delivery (Cloud CDN).**
