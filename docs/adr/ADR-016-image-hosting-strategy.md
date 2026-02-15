# ADR-016: Image Hosting Strategy

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, Cloud Backend Architect
**Related Documents**:
- docs/validation/RESEARCH-VALIDATION-stage-2.0.md
- docs/design/DESIGN-004-computer-vision-pipeline.md

---

## Context

Layer 2b (SerpAPI Google Lens) requires publicly accessible HTTPS image URLs. Requirements:
- Publicly accessible URLs (SerpAPI can fetch images)
- Fast global access (low latency for SerpAPI)
- Secure (time-limited URLs)
- Cost-effective storage
- GCP-native preferred (tech stack alignment)

## Decision

**Use Google Cloud Storage (GCS) + Cloud CDN for public image URLs.**

### Architecture

1. **Upload**: iOS → cropped objects → GCS bucket (`gs://abundance-app-uploads/cropped/{itemId}.jpg`)
2. **Access**: Cloud Function generates signed URLs (1-hour expiration)
3. **CDN**: Cloud CDN caches images globally (fast SerpAPI access)
4. **Lifecycle**: Images are deleted immediately when the associated item is deleted via the `onItemDeleted` Cloud Function trigger (see `functions/src/triggers/onItemDeleted.ts`)

## Rationale

### 1. SerpAPI Requirement (Public HTTPS URLs)

**Requirement**: SerpAPI Google Lens API requires publicly accessible HTTPS URLs (cannot accept base64 or private URLs).

**Solution**: GCS signed URLs provide temporary public access:
```
https://storage.googleapis.com/abundance-app-uploads/cropped/item123.jpg?
GoogleAccessId=...&Expires=1699564800&Signature=...
```

**Outcome**: SerpAPI can fetch images without authentication, URLs expire after 1 hour (security).

### 2. GCP-Native (Tech Stack Alignment)

**Context**: Abundance uses GCP/Firebase (Firestore, Cloud Functions, Firebase Auth).

**Benefit**: GCS + Cloud CDN stay within GCP ecosystem:
- No cross-cloud egress fees
- Unified IAM (same service account permissions)
- Integrated monitoring (Cloud Logging)

**Cost Comparison** (cross-cloud egress):
- GCS → SerpAPI (same region): $0.01/GB egress
- AWS S3 → GCS → SerpAPI: $0.09/GB egress (9× more expensive)

### 3. Cloud CDN (Low-Latency Global Access)

**Requirement**: SerpAPI endpoints are globally distributed. Images must be accessible with low latency.

**Solution**: Cloud CDN caches GCS objects at 100+ edge locations worldwide.

**Benefit**: SerpAPI requests hit nearest CDN node (50-100ms vs 200-500ms direct GCS access).

### 4. Lifecycle Management (Trigger-Based Cleanup)

**Privacy Concern**: Cropped objects should not persist after an item is deleted.

**Solution**: The `onItemDeleted` Cloud Function trigger (`functions/src/triggers/onItemDeleted.ts`) immediately deletes all associated storage files when an item document is deleted from Firestore. This includes the primary image, cropped objects, additional photos, and Live Photo motion clips.

**Note**: The original design proposed a 7-day GCS lifecycle policy, but the implemented approach uses immediate deletion via Firestore triggers, which provides stronger privacy guarantees. ADR-008 documents the full image storage lifecycle.

**Outcome**: Zero orphaned files, privacy-friendly (images deleted immediately with their item).

## Alternatives Considered

### Alternative 1: Firebase Storage (No CDN)

**Pros**:
- Firebase-native (simpler SDK integration)
- Signed URLs supported

**Cons**:
- **No Cloud CDN support** (slower SerpAPI access)
- Higher egress costs ($0.12/GB vs $0.08-0.12/GB with CDN)

**Why Rejected**: Cloud CDN is critical for low-latency SerpAPI access. GCS + Cloud CDN preferred.

### Alternative 2: AWS S3 + CloudFront

**Pros**:
- Similar features (CDN, lifecycle policies)
- Widely used, well-documented

**Cons**:
- **Cross-cloud complexity** (GCP → AWS)
- **SerpAPI compatibility issues** (documented in community forums)
- Higher egress fees (AWS → GCP → SerpAPI)

**Why Rejected**: GCP-native solution simpler, cheaper, no SerpAPI compatibility risks.

### Alternative 3: Direct Base64 Encoding (No Storage)

**Approach**: Send base64-encoded images directly to SerpAPI (no URL hosting)

**Pros**:
- Zero storage costs
- No lifecycle management needed

**Cons**:
- **SerpAPI doesn't support base64 images** (requires public URLs)

**Why Rejected**: Technical impossibility (SerpAPI API specification requires URLs).

## Implications & Consequences

### Positive

1. **GCP-Native**: No cross-cloud complexity, unified billing
2. **Cloud CDN**: 50-100ms global access (vs 200-500ms direct GCS)
3. **Lifecycle Management**: Immediate deletion via `onItemDeleted` trigger (privacy-friendly)
4. **Signed URLs**: 1-hour expiration (security)

### Negative

1. **Public URLs**: Images temporarily accessible via URL (mitigated by 1-hour expiration, no sensitive data in cropped objects)
2. **Cost**: GCS storage ($0.026/GB/month) + egress ($0.08-0.12/GB)

### Cost Analysis

**Scenario**: 125,000 premium items/month, 200 KB avg cropped object size

**Storage**:
- 125,000 × 200 KB = 25 GB total
- 25 GB × $0.026/GB/month = $0.65/month (negligible)

**Egress** (CDN):
- 125,000 × 200 KB = 25 GB
- 25 GB × $0.08/GB = $2.00/month (negligible)

**Total**: $2.65/month for 125K items (< $0.00002 per item)

## Acceptance Criteria

- [x] ✅ Signed URLs accessible via HTTPS
- [x] ✅ SerpAPI successfully fetches images from GCS + CDN
- [x] ✅ Images deleted immediately when item is deleted (via `onItemDeleted` trigger)
- [x] ✅ Cloud CDN caching reduces latency (< 150ms access time)

## Related Decisions

- **ADR-005**: Authentication strategy → GCS access controlled via Firebase Auth
- **DESIGN-004**: 4-layer pipeline → GCS hosts cropped objects for Layer 2b

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, GCS + Cloud CDN for image hosting | Cloud Backend Architect |
| 2026-02-08 | 1.1 | Fix lifecycle policy (immediate deletion via trigger, not 7-day policy), fix ADR-005 cross-reference | Documentation Update |
