# ADR-010: Hybrid Storage Strategy (Local-First + Cloud Enrichment)

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Engineering Leadership, iOS Lead
**Related Documents:** TECH-STACK-001, ADR-004

---

## Context

Photo storage strategy for Abundance: Where to store original photos and cropped images?

---

## Decision

**We will use a hybrid storage strategy: iOS local storage for free tier, Firebase Storage for premium tier enrichment.**

### Storage Strategy by Tier

| Tier | Original Photo | Cropped Objects | Metadata |
|------|----------------|-----------------|----------|
| **Free** | iOS Photo Library (user choice) OR App Sandbox | App Sandbox (local) | Firestore (text only) |
| **Premium** | Same as free | Firebase Storage (temporary, 30-day lifecycle) | Firestore (enriched) |

---

## Rationale

### 1. Free Tier = Zero Cloud Storage Costs

**Problem:** Storing photos in cloud for free users = negative unit economics

**Solution:**
- Free tier: All photos stored locally on device
- No upload to Firebase Storage
- **Cost:** $0

**Alternative (Cloud Storage for All):**
- 3,500 free users × 50 items × 150 KB = 26 GB
- Firebase Storage: 26 GB × $0.026/GB = **$0.68/month**
- Small cost, but adds up at scale (10K users = $2/month → 100K users = $20/month)

---

### 2. Premium Tier = Cloud AI Requires Cloud Storage

**Requirement:** Google Shopping Graph API needs image URL (can't access iOS local storage)

**Workflow:**
1. iOS app detects objects (on-device Vision Framework)
2. Crops images around detected objects
3. Uploads cropped images to Firebase Storage (`gs://abundance-prod/users/{userId}/temp/object_1.jpg`)
4. Cloud Function calls Shopping Graph with `gs://` URL
5. Shopping Graph returns product metadata
6. (Optional) Delete cropped images after 30 days (user preference)

**Cost (Month 6, 1,500 premium users):**
- 1,500 users × 50 items × 150 KB = 11.25 GB
- Firebase Storage: 11.25 GB × $0.026/GB = **$0.29/month** (negligible)

---

### 3. Original Photos Stay on Device (Privacy)

**User Control:**
- Users choose whether to save photo to iOS Photo Library
- Original photos NEVER uploaded to cloud (even for premium users)
- Only cropped objects (detected items) are uploaded

**Privacy Marketing:**
- "Your original photos never leave your device"
- "We only upload cropped images of detected items (e.g., just the scissors, not the full room)"

---

## Storage Paths

### Free Tier (Local Only)

```
iOS App Sandbox:
/Users/{userId}/Documents/items/
├── item_abc123/
│   ├── original.jpg (optional, if user doesn't save to Photo Library)
│   ├── cropped_object_1.jpg (scissors)
│   └── cropped_object_2.jpg (headphones)

Firestore (Metadata Only):
users/{userId}/items/item_abc123
{
  "name": "scissors, headphones",
  "photoUrl": "local://item_abc123/original.jpg",  // Local reference
  "tier": "free"
}
```

---

### Premium Tier (Hybrid)

```
iOS App Sandbox (Local):
/Users/{userId}/Documents/items/item_abc123/
├── original.jpg (stays local)
├── cropped_object_1.jpg (uploaded to Firebase Storage)

Firebase Storage (Cloud):
users/{userId}/enrichment-queue/item_abc123/
├── cropped_object_1.jpg (uploaded for Shopping Graph)
└── metadata.json (timestamp, basicLabel)

Firestore (Enriched Metadata):
users/{userId}/items/item_abc123
{
  "name": "Scott Fabric Scissors 8-inch",
  "photoUrl": "local://item_abc123/original.jpg",  // Original stays local
  "croppedImageUrl": "gs://abundance-prod/users/{userId}/enrichment-queue/item_abc123/cropped_object_1.jpg",
  "tier": "premium",
  "enrichedAt": timestamp
}
```

---

## Lifecycle Management

### Cropped Images (Premium Tier)

**Retention Policy:**
- **Default:** Delete after 30 days (reduce storage costs)
- **User preference:** Keep indefinitely (for re-running enrichment if unsatisfied)

**Firebase Storage Lifecycle Rule:**
```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "matchesPrefix": ["users/*/enrichment-queue/"]
        }
      }
    ]
  }
}
```

**Cost Savings:**
- After 30 days: 11.25 GB → 0.5 GB (recent uploads only)
- Storage cost: $0.29/month → $0.01/month

---

## Alternatives Considered

### Alternative 1: Cloud Storage for All Tiers

**Approach:**
- Upload all photos to Firebase Storage (free + premium)
- Unified storage strategy

**Pros:**
- Simpler architecture (no hybrid logic)
- User can access photos from web (future feature)

**Cons:**
- **Cost:** $0.68/month for free tier (vs. $0 local storage)
- **Privacy:** Users don't want photos uploaded (free tier is privacy-focused)
- **Upload time:** Slows down cataloging (must wait for upload)

**Why Rejected:** Free tier with cloud storage has negative unit economics at scale

---

### Alternative 2: iOS Photo Library Only (No App Sandbox)

**Approach:**
- All photos stored in iOS Photo Library (no app-specific storage)
- App reads from Photo Library using `PHAsset`

**Pros:**
- Simpler (no app sandbox management)
- Users manage storage (iOS Settings → Photos)

**Cons:**
- **Permission friction:** Requires "All Photos" access (users hesitant)
- **No cropped images:** Can't store cropped objects in Photo Library (not user-facing photos)
- **Privacy:** App has access to ALL user photos (creepy)

**Why Rejected:** Privacy concern (requesting "All Photos" access is invasive)

---

## Implications

### Positive

1. **Zero storage cost (free tier):** Sustainable freemium economics
2. **Privacy-first:** Original photos never uploaded
3. **User control:** User decides if photo goes to Photo Library

### Negative (Risks)

1. **Device storage:** Users with 500+ items may run out of device storage
   - **Mitigation:** Warn user if device storage < 1 GB
2. **No web access:** Free tier users can't access photos from web (future feature)
   - **Mitigation:** Phase 3 (web app) requires premium (cloud backup)
3. **Complex logic:** Hybrid storage requires careful state management (local vs. cloud)
   - **Mitigation:** Clear separation (tier = "free" → local only, tier = "premium" → hybrid)

---

## Open Questions

### Question 1: Cropped Image Retention

**Question:** Should we keep cropped images indefinitely, or delete after 30 days?

**Options:**
- **Delete after 30 days:** Lower costs ($0.01/month vs. $0.29/month)
- **Keep indefinitely:** User can re-run enrichment if unsatisfied

**Recommendation:** Default to 30-day deletion, add "Keep forever" toggle in settings

---

### Question 2: Web Access (Phase 3)

**Question:** If we add web app (Phase 3), how do free tier users access photos?

**Options:**
- **Require premium:** Web access = cloud backup = premium feature
- **On-demand upload:** Free tier users can manually upload photos to view on web

**Recommendation:** Require premium (web access is premium value-add)

---

## Stakeholder Sign-Off

- [ ] **Engineering Leadership**
- [ ] **iOS Lead** (confirm local storage strategy)
- [ ] **Finance** (approve storage cost model)

**Timeline:** Finalized by 2025-10-31

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial hybrid storage strategy | Stage 2.1 Execution |
