# DESIGN-004 vs Stage 2.1 Research Reconciliation

**Date:** 2025-11-01
**Purpose:** Reconcile existing DESIGN-004 architecture with Stage 2.1 verification findings

---

## Executive Summary

DESIGN-004 provides solid **architectural patterns and implementation code** but uses **outdated/unverified technologies**. Stage 2.1 research verified specific technologies and discovered **architectural gaps** (no product search layer). This document reconciles both to create an **accurate, implementable specification**.

**Verdict:** ✅ **Keep DESIGN-004 patterns, update technologies to Stage 2.1 verified stack**

---

## Technology Comparison

### Layer 1: Object Detection

| Aspect | DESIGN-004 | Stage 2.1 Research | Reconciliation |
|--------|------------|-------------------|----------------|
| **Model** | YOLOv8n (6MB) | YOLOv3-Tiny (35MB) | ✅ **Use YOLOv3-Tiny** (Apple-provided) |
| **Source** | Ultralytics (convert to Core ML) | Apple ML Models | ✅ **Use Apple's pre-trained** |
| **Framework** | VNCoreMLRequest | VNCoreMLRequest | ✅ **Same** |
| **Barcode** | VNDetectBarcodesRequest | Not mentioned | ✅ **Add barcode detection** |
| **Privacy** | Only crops uploaded | Only crops uploaded | ✅ **Same** |
| **Cost** | $0 | $0 | ✅ **Same** |

**Decision:** Keep DESIGN-004 implementation patterns, but use Apple's YOLOv3-Tiny instead of converting YOLOv8.

---

### Layer 2a: Attribute Extraction

| Aspect | DESIGN-004 | Stage 2.1 Research | Reconciliation |
|--------|------------|-------------------|----------------|
| **Model** | Gemini 1.5 Pro Vision | Gemini 2.5 Flash-Lite | ✅ **Use Flash-Lite** (cheaper, faster) |
| **API** | Vertex AI | Vertex AI | ✅ **Same** |
| **Cost** | $0.015-0.020 | $0.000249 | ✅ **60x cheaper with Flash-Lite!** |
| **Latency** | 1-3s | 30-50ms | ✅ **60x faster!** |
| **Output** | JSON parsing | JSON mode + schema | ✅ **Use JSON mode** |

**Decision:** Replace Gemini 1.5 Pro with Gemini 2.5 Flash-Lite (massive cost/speed improvement).

---

### Layer 2b: Product Search

| Aspect | DESIGN-004 | Stage 2.1 Research | Reconciliation |
|--------|------------|-------------------|----------------|
| **Existence** | ❌ Not mentioned | ✅ SerpAPI Google Lens | ✅ **ADD NEW LAYER** |
| **Cost** | - | $0.010/search | New cost component |
| **Image Hosting** | Firebase Storage | S3 + CloudFront | ✅ **Use S3** (SerpAPI needs public URLs) |
| **Parsing** | - | Claude Haiku ($0.0008) | ✅ **Add LLM parsing** |
| **Queue** | - | Redis queue | ✅ **Add queue system** |

**Decision:** Add entire Layer 2b (product search) as new component not in DESIGN-004.

---

### Layer 3: AI Reasoning

| Aspect | DESIGN-004 | Stage 2.1 Research | Reconciliation |
|--------|------------|-------------------|----------------|
| **Model** | Implicit (Gemini does all) | Claude Sonnet 4.5 | ✅ **Add dedicated synthesis layer** |
| **Cost** | - | $0.0092 (batch) | New cost component |
| **Purpose** | - | Merge Layer 2a + 2b | ✅ **Explicit synthesis step** |

**Decision:** Add Layer 3 as distinct synthesis step (not in DESIGN-004).

---

### Backend Infrastructure

| Aspect | DESIGN-004 | Stage 2.1 Research | Reconciliation |
|--------|------------|-------------------|----------------|
| **Storage** | Firebase Storage | S3 + CloudFront | ✅ **Use S3** (public URL requirement) |
| **Database** | Cloud Firestore | Not specified | ✅ **Keep Firestore** |
| **Functions** | Firebase Cloud Functions | Not specified | ✅ **Keep Cloud Functions** |
| **Queue** | Not mentioned | Redis | ✅ **Add Redis** |
| **Hosting** | Not mentioned | CloudFront CDN | ✅ **Add CDN** |

**Decision:** Keep Firestore + Cloud Functions from DESIGN-004, add S3/CloudFront/Redis from Stage 2.1.

---

## Cost Reconciliation

### DESIGN-004 Cost Breakdown

| Component | Cost |
|-----------|------|
| Firebase Storage | $0.001 |
| Cloud Function | $0.0001 |
| Gemini 1.5 Pro Vision | $0.015-0.020 |
| Barcode API | $0.005 |
| Firestore write | $0.0001 |
| **Total** | **$0.02-0.03** |

### Stage 2.1 Cost Breakdown

| Component | Cost |
|-----------|------|
| Layer 1 (iOS Vision) | $0.000 |
| Layer 2a (Gemini Flash-Lite) | $0.000249 |
| Layer 2b (SerpAPI + S3 + Parsing) | $0.0109 |
| Layer 3 (Claude Sonnet 4.5) | $0.0092 |
| **Total** | **$0.019449** |

**Difference:** Stage 2.1 is **35% cheaper** despite adding product search layer!

**Why?** Gemini 2.5 Flash-Lite is 60x cheaper than Gemini 1.5 Pro.

---

## Accurate Elements to Keep from DESIGN-004

### ✅ iOS Implementation Patterns

**Keep these code patterns:**

1. **Camera Capture (Phase 1):**
   - `AVCaptureSession` setup
   - `AVCapturePhotoOutput` delegate
   - SwiftUI integration
   - **Use verbatim** from DESIGN-004:178-153

2. **Object Detection Structure:**
   - `DetectedObject` struct
   - `VNCoreMLRequest` wrapper
   - Async/await patterns
   - Bounding box coordinate conversion
   - **Adapt** from DESIGN-004:209-309

3. **Barcode Detection:**
   - `VNDetectBarcodesRequest`
   - Parallel detection (objects + barcodes)
   - **Keep** from DESIGN-004:274-289

4. **Privacy Firewall:**
   - Only upload cropped images
   - Never upload full photos
   - **Keep principle** from DESIGN-004:311-326

5. **SwiftUI UI Patterns:**
   - `ItemReviewView` structure
   - Form-based editing
   - Confidence badges
   - **Adapt** from DESIGN-004:641-729

6. **Firestore Integration:**
   - Real-time listeners
   - `InventoryViewModel` pattern
   - Document structure
   - **Keep** from DESIGN-004:563-636

---

## Inaccurate Elements to Update from DESIGN-004

### ❌ Replace These Technologies

1. **Gemini 1.5 Pro Vision → Gemini 2.5 Flash-Lite**
   - Location: DESIGN-004:428-458
   - Reason: 60x cheaper, 60x faster

2. **Firebase Storage → S3 + CloudFront**
   - Location: DESIGN-004:372-401
   - Reason: SerpAPI requires public URLs

3. **Simple JSON parsing → JSON schema mode**
   - Location: DESIGN-004:461-475
   - Reason: Gemini 2.5 supports native JSON mode

4. **YOLOv8n (convert) → YOLOv3-Tiny (Apple)**
   - Location: DESIGN-004:193-206
   - Reason: Apple provides pre-trained model

---

## Missing Components to Add

### 🆕 Add These Layers (Not in DESIGN-004)

1. **Layer 2b: Product Search**
   - SerpAPI Google Lens integration
   - Image hosting service (S3 + CloudFront)
   - Request queue (Redis)
   - LLM parsing (Claude Haiku)
   - **New:** 11-16 days effort

2. **Layer 3: AI Synthesis**
   - Claude Sonnet 4.5 batch API
   - Merge Layer 2a + 2b results
   - Structured catalog output
   - **New:** 3-5 days effort

3. **Infrastructure:**
   - CloudFormation templates
   - Redis deployment
   - Rate limiting
   - Queue management
   - **New:** 5-7 days effort

---

## Updated Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                 ABUNDANCE VISION PIPELINE v2.0               │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Layer 1: On-Device Detection (iOS)                   │  │
│  │                                                        │  │
│  │  AVFoundation Camera → Vision Framework:              │  │
│  │  - VNCoreMLRequest (YOLOv3-Tiny 35MB)                │  │
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
│  │  1. Upload to S3 + CloudFront (public URL)            │  │
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

## Reconciled Implementation Plan

### Phase 1: iOS Camera + Detection (Use DESIGN-004 code)

**From DESIGN-004:**
- ✅ Camera setup (AVCaptureSession)
- ✅ Photo capture (AVCapturePhotoOutput)
- ✅ Barcode detection (VNDetectBarcodesRequest)

**Update:**
- Replace YOLOv8n with YOLOv3-Tiny from Apple

---

### Phase 2: Cloud Infrastructure (Update DESIGN-004)

**From DESIGN-004:**
- ✅ Cloud Functions trigger pattern
- ✅ Firestore integration

**Add (Stage 2.1):**
- S3 + CloudFront (replace Firebase Storage)
- Redis queue system
- Rate limiting

---

### Phase 3: AI Layers (Update + Add)

**From DESIGN-004:**
- ✅ Vision API call pattern
- ✅ JSON parsing logic

**Update:**
- Replace Gemini 1.5 Pro with 2.5 Flash-Lite

**Add (Stage 2.1):**
- Layer 2b: SerpAPI + LLM parsing
- Layer 3: Claude Sonnet synthesis

---

### Phase 4: iOS UI (Use DESIGN-004 code)

**From DESIGN-004:**
- ✅ ItemReviewView structure
- ✅ Firestore real-time listeners
- ✅ InventoryViewModel pattern
- ✅ Confidence badges

**No changes needed** - UI patterns are solid

---

## Final Recommendations

### ✅ Use from DESIGN-004

1. **All iOS code patterns** (camera, detection, UI)
2. **Firestore integration** (real-time listeners, data model)
3. **Privacy firewall** (crop-only upload)
4. **UX flow** (capture → review → confirm)
5. **Cloud Functions trigger** pattern

### ❌ Replace from DESIGN-004

1. Gemini 1.5 Pro → Gemini 2.5 Flash-Lite
2. Firebase Storage → S3 + CloudFront
3. YOLOv8n (convert) → YOLOv3-Tiny (Apple)

### 🆕 Add (Not in DESIGN-004)

1. Layer 2b: Product Search (SerpAPI)
2. Layer 3: AI Synthesis (Claude Sonnet)
3. Redis queue + rate limiting
4. LLM parsing service
5. Image hosting service

---

## Updated Cost & Performance

| Metric | DESIGN-004 | Stage 2.1 | Improvement |
|--------|------------|-----------|-------------|
| **Cost/item** | $0.02-0.03 | $0.019449 | **35% cheaper** |
| **Layer 1 latency** | <300ms | 50-150ms | **2x faster** |
| **Vision API latency** | 1-3s | <50ms | **60x faster** |
| **Total latency** | <6s | 7-10s | +1-4s (added product search) |
| **Accuracy** | >80% | >80% (same target) | Same |
| **Margin** | Not specified | 83.8% | ✅ Strong |

**Trade-off:** Slightly higher latency (+1-4s) for **product search capability** (brand/model/price data).

---

## Action Items

### Update Documents

- [ ] Update DESIGN-004 with Stage 2.1 technologies
- [ ] Create ADR-015: Claude Sonnet 4.5 selection
- [ ] Create ADR-016: S3 vs Firebase Storage decision
- [ ] Create ADR-017: LLM parsing architecture
- [ ] Update implementation plan with DESIGN-004 code patterns

### Implementation

- [ ] Use DESIGN-004 iOS code as starting point
- [ ] Swap out YOLOv8n for YOLOv3-Tiny
- [ ] Update Gemini 1.5 Pro → 2.5 Flash-Lite
- [ ] Add Layer 2b (SerpAPI)
- [ ] Add Layer 3 (Claude Sonnet)
- [ ] Update Cloud Functions for new infrastructure

---

**Status:** ✅ RECONCILIATION COMPLETE
**Next:** Update implementation plan with DESIGN-004 code patterns
**Estimated Effort:** Keep iOS/UI code (saves ~10 days), add new layers (+11-16 days)

