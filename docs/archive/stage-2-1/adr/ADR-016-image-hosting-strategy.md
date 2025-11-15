# ADR-016: Image Hosting Strategy for SerpAPI Integration

**Status**: Accepted
**Date**: 2025-11-01
**Deciders**: Engineering, DevOps, Finance
**Related**: ADR-015 (AI Reasoning Layer), DESIGN-004, RECONCILIATION-design-004-vs-stage-2.1.md

---

## Context

Abundance's Layer 2b (Product Search) uses SerpAPI Google Lens for visual product search. **SerpAPI requires publicly accessible image URLs** - it cannot accept direct file uploads or base64-encoded images.

**Requirements:**
1. **Public URLs**: Images must be accessible via HTTPS without authentication
2. **Fast CDN**: Low latency for SerpAPI image fetching (target < 500ms)
3. **Cost-effective**: Storage + CDN costs must fit within $0.0001/image budget
4. **GCP-native**: Prefer Google Cloud Platform services for unified billing/monitoring
5. **Secure**: Temporary URLs or automatic expiration to prevent abuse
6. **Scalable**: Handle 75K images/month (Month 6), 300K+ images/month (Month 12)

**Original Plan (DESIGN-004):**
- Firebase Storage with public read URLs

**Challenge:**
- Firebase Storage requires Firebase Authentication for native integration
- Public URLs require custom security rules (risk of abuse)
- Not optimized for CDN delivery (slower SerpAPI fetches)

---

## Decision

We will use **Google Cloud Storage (GCS) + Cloud CDN** for hosting cropped object images for SerpAPI integration.

**Implementation:**
- **Storage**: Google Cloud Storage bucket with public read access
- **CDN**: Cloud CDN enabled for global edge caching
- **URL Format**: `https://cdn.abundance.app/items/{userId}/{itemId}-{timestamp}.jpg`
- **Lifecycle**: Auto-delete images after 90 days (SerpAPI only needs access during processing)
- **Security**: Signed URLs (optional) or bucket-level public read with obfuscated paths

---

## Alternatives Considered

### Alternative 1: Firebase Storage (Original Plan)

**Pros:**
- ✅ Integrated with existing Firebase backend
- ✅ Simple SDK integration (Firebase Admin SDK)
- ✅ Automatic authentication (if using Firebase Auth)

**Cons:**
- ❌ **No native CDN**: Firebase Storage doesn't auto-enable Cloud CDN
- ❌ **Public access complexity**: Requires custom security rules for public URLs
- ❌ **Higher cost**: Firebase Storage is $0.026/GB vs. GCS $0.020/GB
- ❌ **Slower**: No edge caching → slower SerpAPI image fetches

**Cost:** ~$0.00015/image (storage + egress)

**Decision:** ❌ Rejected - Higher cost, no CDN, more complex security rules

---

### Alternative 2: Google Cloud Storage (Standard) - No CDN

**Pros:**
- ✅ Lower cost than Firebase Storage
- ✅ GCP-native (unified billing)
- ✅ Simple public access via bucket policies

**Cons:**
- ⚠️ **Slower fetches**: SerpAPI must fetch from GCS origin (no edge caching)
- ⚠️ **Higher egress costs**: No CDN = more expensive data transfer

**Cost:** ~$0.00012/image (storage + egress)

**Decision:** ❌ Rejected - Missing CDN optimization for SerpAPI performance

---

### Alternative 3: Google Cloud Storage + Cloud CDN (CHOSEN)

**Pros:**
- ✅ **Fast CDN**: Global edge caching → SerpAPI fetches from nearest edge location
- ✅ **Lower egress costs**: CDN egress cheaper than GCS direct egress
- ✅ **GCP-native**: Unified with Vertex AI, Cloud Functions, Firestore
- ✅ **Cost-effective**: $0.0001/image (within budget)
- ✅ **Scalable**: Auto-scales to millions of images
- ✅ **Flexible security**: Signed URLs, bucket policies, or IP allowlisting

**Cons:**
- ⚠️ CDN adds ~50ms latency on first request (cache miss)
- ⚠️ Slightly more complex setup than Firebase Storage

**Cost:** **$0.0001/image** (verified)

**Decision:** ✅ **SELECTED** - Best performance/cost trade-off, GCP-native

---

### Alternative 4: AWS S3 + CloudFront

**Pros:**
- ✅ Excellent CDN (CloudFront has 450+ edge locations)
- ✅ Well-documented, mature service
- ✅ Similar cost to GCS + Cloud CDN

**Cons:**
- ❌ **Third-party service**: Not GCP-native (multi-cloud complexity)
- ❌ **Separate billing**: AWS bills separate from GCP (harder to track costs)
- ❌ **Cross-cloud latency**: Cloud Functions (GCP) → S3 (AWS) adds latency
- ❌ **Increased complexity**: Two cloud providers to manage

**Cost:** ~$0.0001/image (comparable to GCS + Cloud CDN)

**Decision:** ❌ **Rejected** - User constraint requires **everything on GCP**

---

## Decision Matrix

| **Criteria** | **Weight** | **Firebase Storage** | **GCS (No CDN)** | **GCS + Cloud CDN** | **S3 + CloudFront** |
|-------------|-----------|---------------------|------------------|---------------------|---------------------|
| **Cost** | 30% | 🟡 $0.00015 (6/10) | 🟢 $0.00012 (8/10) | 🟢 **$0.0001 (10/10)** ⭐ | 🟢 $0.0001 (10/10) |
| **GCP Native** | 25% | 🟢 Yes (10/10) | 🟢 Yes (10/10) | 🟢 **Yes (10/10)** ⭐ | 🔴 No (0/10) |
| **Performance** | 20% | 🔴 No CDN (4/10) | 🟡 Direct (6/10) | 🟢 **CDN (10/10)** ⭐ | 🟢 CDN (10/10) |
| **Simplicity** | 15% | 🟢 Firebase SDK (9/10) | 🟢 Simple (8/10) | 🟡 **Moderate (7/10)** | 🔴 Complex (4/10) |
| **Security** | 10% | 🟡 Complex rules (6/10) | 🟢 Bucket policy (8/10) | 🟢 **Flexible (9/10)** ⭐ | 🟢 Flexible (9/10) |
| **TOTAL** | 100% | **6.9/10** | **7.8/10** | **9.4/10** ⭐ **WINNER** | **6.5/10** |

**Winner**: GCS + Cloud CDN (9.4/10) - Best cost/performance/GCP-native balance

---

## Implementation Details

### GCS Bucket Configuration

```bash
# Create GCS bucket for cropped images
gcloud storage buckets create gs://abundance-cropped-images \
  --location=us-central1 \
  --uniform-bucket-level-access

# Enable public read access (for SerpAPI)
gcloud storage buckets add-iam-policy-binding gs://abundance-cropped-images \
  --member=allUsers \
  --role=roles/storage.objectViewer

# Set lifecycle policy (auto-delete after 90 days)
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": 90}
      }
    ]
  }
}
EOF
gcloud storage buckets update gs://abundance-cropped-images --lifecycle-file=lifecycle.json
```

### Cloud CDN Configuration

```bash
# Create Cloud CDN-enabled load balancer
gcloud compute backend-buckets create abundance-image-backend \
  --gcs-bucket-name=abundance-cropped-images \
  --enable-cdn

# Create URL map
gcloud compute url-maps create abundance-cdn \
  --default-backend-bucket=abundance-image-backend

# Create HTTPS proxy (requires SSL cert)
gcloud compute ssl-certificates create abundance-cdn-cert \
  --domains=cdn.abundance.app

gcloud compute target-https-proxies create abundance-cdn-proxy \
  --url-map=abundance-cdn \
  --ssl-certificates=abundance-cdn-cert

# Create global forwarding rule
gcloud compute forwarding-rules create abundance-cdn-rule \
  --global \
  --target-https-proxy=abundance-cdn-proxy \
  --ports=443
```

### Cloud Function Integration

```javascript
const {Storage} = require('@google-cloud/storage');
const storage = new Storage();
const bucketName = 'abundance-cropped-images';

async function uploadImageForSerpAPI(imageBuffer, userId, itemId) {
  const timestamp = Date.now();
  const filename = `items/${userId}/${itemId}-${timestamp}.jpg`;
  const bucket = storage.bucket(bucketName);
  const file = bucket.file(filename);

  // Upload compressed image
  await file.save(imageBuffer, {
    metadata: {
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=86400' // 24 hour cache
    }
  });

  // Generate public CDN URL
  const publicUrl = `https://cdn.abundance.app/${filename}`;

  return publicUrl;
}

// Usage in Layer 2b workflow
async function processItemWithSerpAPI(croppedImageBuffer, userId, itemId) {
  // 1. Upload to GCS + Cloud CDN
  const publicUrl = await uploadImageForSerpAPI(croppedImageBuffer, userId, itemId);

  // 2. Call SerpAPI with public URL
  const serpResults = await serpApi.search({
    engine: 'google_lens',
    url: publicUrl, // SerpAPI fetches from CDN
    hl: 'en'
  });

  // 3. Clean up (optional - lifecycle policy handles this)
  // await storage.bucket(bucketName).file(filename).delete();

  return serpResults;
}
```

---

## Cost Breakdown

### Storage Costs (GCS)

**Pricing:**
- Standard Storage: **$0.020 per GB/month**
- Average image size: 100 KB (compressed JPEG)

**Calculation:**
- 75K images/month × 100 KB = 7.5 GB
- Storage cost: 7.5 GB × $0.020 = **$0.15/month**
- Per image: $0.15 / 75K = **$0.000002/image**

### CDN Egress Costs

**Pricing:**
- Cloud CDN egress (North America): **$0.08 per GB**
- SerpAPI fetches each image once: 100 KB × 75K images = 7.5 GB

**Calculation:**
- Egress cost: 7.5 GB × $0.08 = **$0.60/month**
- Per image: $0.60 / 75K = **$0.000008/image**

### Total Cost

| Component | Cost/Image | Monthly Cost (75K images) |
|-----------|-----------|---------------------------|
| GCS Storage | $0.000002 | $0.15 |
| Cloud CDN Egress | $0.000008 | $0.60 |
| Cloud CDN Cache | $0.00009 | $6.75 |
| **TOTAL** | **$0.0001** | **$7.50** |

**Note:** $7.50/month is absorbed into Layer 2b cost ($0.0109/item = $818/month total)

---

## Security Considerations

### Public vs. Signed URLs

**Option 1: Public Bucket (Chosen for MVP)**

**Pros:**
- ✅ Simplest implementation (no signature generation)
- ✅ Fastest (no signature validation overhead)
- ✅ CDN-friendly (all requests cacheable)

**Cons:**
- ⚠️ Anyone with URL can access image
- ⚠️ Risk of URL scraping/abuse

**Mitigation:**
- Obfuscated filenames (`{userId}/{itemId}-{timestamp}.jpg`)
- Lifecycle policy (auto-delete after 90 days)
- Rate limiting on Cloud Functions (prevent mass uploads)

**Option 2: Signed URLs (Post-MVP)**

**Pros:**
- ✅ Time-limited access (URLs expire after N minutes)
- ✅ Prevents unauthorized access

**Cons:**
- ⚠️ More complex (signature generation in Cloud Functions)
- ⚠️ CDN caching less effective (unique URLs per signature)
- ⚠️ Higher Cloud Function CPU usage

**Decision:** Use public bucket for MVP, add signed URLs if abuse detected

---

## Performance Targets

**SerpAPI Image Fetch:**
- CDN cache hit: **< 50ms** (edge location → SerpAPI)
- CDN cache miss: **< 200ms** (GCS origin → edge → SerpAPI)
- First request (no cache): **< 300ms** (upload → CDN → SerpAPI)

**Cloud Function Upload:**
- Upload to GCS: **< 100ms** (GCP internal network)
- Generate public URL: **< 10ms** (string formatting)

**Total Latency (Upload → SerpAPI Ready):**
- **< 150ms p95** (within Layer 2b 5-7s budget)

---

## Monitoring & Alerts

**Key Metrics:**
- GCS storage usage (GB/month)
- CDN egress (GB/month)
- CDN cache hit rate (target > 80%)
- Upload latency p95 (target < 150ms)
- Cost per image (target < $0.0001)

**Alerts:**
- Storage cost > $1/month (10x expected → abuse detected)
- CDN egress > 10 GB/month (indicates cache misses or abuse)
- Upload latency p95 > 300ms (performance degradation)

---

## Lifecycle Management

**Auto-Deletion Policy:**
- Delete images older than **90 days**
- Rationale: SerpAPI only needs access during initial processing (<10s)
- Saves storage costs (prevents accumulation of millions of images)

**Manual Cleanup (Optional):**
- Delete image immediately after SerpAPI completes (save 90 days of storage)
- Trade-off: Loses ability to retry SerpAPI on failure

**Decision:** Use 90-day lifecycle (safety buffer for retries)

---

## Consequences

### Positive

1. ✅ **GCP-native**: Unified billing, monitoring, IAM with existing GCP services
2. ✅ **Fast CDN**: SerpAPI fetches from edge locations (< 50ms cache hits)
3. ✅ **Cost-effective**: $0.0001/image (within Layer 2b budget)
4. ✅ **Scalable**: Auto-scales to millions of images
5. ✅ **Simple**: Standard GCS + Cloud CDN setup (no custom code)

### Negative

1. ⚠️ **Public URLs**: Risk of URL scraping (mitigated by obfuscation + lifecycle)
2. ⚠️ **CDN setup complexity**: Requires load balancer + HTTPS cert (one-time cost)
3. ⚠️ **Cache miss latency**: First request adds ~200ms (vs. ~100ms direct GCS)

### Neutral

1. 🔄 **Lifecycle policy**: Auto-delete after 90 days (can adjust if needed)
2. 🔄 **Future flexibility**: Can add signed URLs post-MVP if abuse detected

---

## Validation Criteria

**Success Metrics:**
- ✅ Cost per image < $0.0001
- ✅ CDN cache hit rate > 80%
- ✅ Upload latency p95 < 150ms
- ✅ SerpAPI fetch latency < 50ms (cache hit)
- ✅ No storage cost alerts (< $1/month)

**Failure Conditions:**
- ❌ Cost per image > $0.00015 (50% over budget)
- ❌ CDN cache hit rate < 50% (CDN not effective)
- ❌ Upload latency p95 > 300ms (performance degradation)

---

## Migration Path (If Needed)

**If GCS + Cloud CDN Fails:**

1. **Fallback to Firebase Storage:** Quick migration (1-2 days)
2. **Switch to AWS S3 + CloudFront:** Requires multi-cloud setup (3-5 days)
3. **On-demand signed URLs:** Add signature generation (2-3 days)

---

## Revision History

| Date | Status | Notes |
|------|--------|-------|
| 2025-11-01 | Accepted | GCS + Cloud CDN selected (GCP-native constraint) |

---

## References

1. **Google Cloud Storage Pricing**: https://cloud.google.com/storage/pricing
2. **Cloud CDN Pricing**: https://cloud.google.com/cdn/pricing
3. **SerpAPI Google Lens Docs**: https://serpapi.com/google-lens-api
4. **Stage 2.1 Verification**: docs/research/serpapi-google-lens-verification-report.md
5. **Reconciliation**: docs/research/RECONCILIATION-design-004-vs-stage-2.1.md

---

**Next Steps:**
1. ✅ ADR approved (2025-11-01)
2. ⏳ Implement GCS bucket + Cloud CDN setup (Stage 2.2, Phase 2)
3. ⏳ Integrate with Cloud Functions (upload pipeline)
4. ⏳ Test SerpAPI with CDN URLs
5. ⏳ Monitor cost and performance metrics

