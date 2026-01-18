# ROADMAP: Stage 2.2 Implementation Timeline

**Document ID:** ROADMAP-Stage-2.2
**Date:** 2025-11-01
**Status:** APPROVED
**Related Documents:**
- 2025-11-01-stage-2.2-ios-architecture-implementation.md (Detailed Plan)
- ADR-013, ADR-014, ADR-015, ADR-016, ADR-017
- DESIGN-004, DESIGN-005
- RECONCILIATION-design-004-vs-stage-2.1.md

---

## Executive Summary

This roadmap defines the **6-week implementation timeline** for Abundance's 4-layer computer vision pipeline, from iOS app to cloud AI services. The implementation follows a phased approach with testable milestones and validation gates.

**Key Deliverable:** Working proof-of-concept (POC) with all 4 layers integrated and tested.

**Timeline:** 6 weeks (Weeks 1-6)

**Success Criteria:**
- ✅ Layer 1: Detect objects in 75-80% of photos
- ✅ Layer 2a: Extract attributes with >95% valid JSON
- ✅ Layer 2b: Return product matches for common items
- ✅ Layer 3: Synthesize final metadata
- ✅ Cost: ≤ $0.020 per item
- ✅ Latency: ≤ 10 seconds p95
- ✅ All tests passing (unit + integration)

---

## Phase Breakdown

```
Week 1-2: Layer 1 (iOS Object Detection)
    ↓
Week 3: Infrastructure (GCS, CDN, Redis, Cloud Functions)
    ↓
Week 4: Layer 2b (SerpAPI + Claude Haiku Parsing)
    ↓
Week 5: Layer 2a (Gemini 2.5 Flash-Lite Attributes)
    ↓
Week 6: Integration & POC Validation
```

---

## Week 1-2: Layer 1 - iOS Object Detection

**Goal:** On-device object detection with YOLOv3-Tiny

### Week 1: Foundation
**Tasks:**
- Download YOLOv3-Tiny from Apple ML Models
- Integrate Core ML model into Xcode project
- Implement `ObjectDetectionService.swift` (VNCoreMLRequest wrapper)
- Implement image cropping logic (bounding boxes → cropped images)
- Write unit tests for detection service

**Deliverables:**
- YOLOv3-Tiny model integrated (35.4MB)
- Swift service that detects objects and returns bounding boxes
- Cropping logic that extracts objects from original image
- 20+ unit tests passing

**Validation:**
- Test with 10 household items: 70-80% detection rate
- Latency: <150ms p95 on iPhone 15 Pro

---

### Week 2: Camera Integration
**Tasks:**
- Implement AVFoundation camera capture
- Integrate ObjectDetectionService with camera preview
- Add barcode detection (VNDetectBarcodesRequest)
- Implement SwiftUI camera UI
- Write integration tests

**Deliverables:**
- Working camera capture → object detection flow
- Barcode scanning working in parallel
- SwiftUI camera preview with detection overlays
- 15+ integration tests passing

**Validation:**
- Capture photo → detect objects → crop → save to temp storage
- End-to-end latency: <500ms

---

## Week 3: Infrastructure Setup

**Goal:** Deploy cloud infrastructure for Layers 2a, 2b, 3

### Cloud Platform Setup
**Tasks:**
- Create GCS bucket for cropped images
- Configure Cloud CDN for public URLs
- Deploy Cloud Memorystore (Redis 7.0+)
- Set up Cloud Functions project (Node.js 20)
- Configure Cloud Scheduler for queue processing
- Set up Firestore collections

**Deliverables:**
- GCS bucket: `abundance-cropped-images` (public read)
- Cloud CDN: `cdn.abundance.app` HTTPS endpoint
- Redis instance: 1GB standard tier (~$25/month)
- Cloud Functions: `enrichItem`, `processSerpAPIQueue`
- Firestore: `users/{userId}/items/{itemId}` collections

**Validation:**
- Upload test image → GCS → verify CDN URL accessible
- Enqueue test job → Redis → verify dequeue after 1 second
- Trigger Cloud Function → verify Firestore write
- Cost: Infrastructure running at <$60/month

---

## Week 4: Layer 2b - Product Search

**Goal:** SerpAPI Google Lens integration + Claude Haiku parsing

### Tasks
**Days 1-2: Image Hosting Pipeline**
- Implement GCS upload function (Cloud Functions)
- Generate signed CDN URLs with 1-hour expiration
- Test upload latency (<100ms p95)

**Days 3-4: SerpAPI Integration**
- Implement Redis queue (enqueue, dequeue, rate limiting)
- Implement SerpAPI client (Node.js)
- Configure rate limiting (45 requests/minute)
- Write queue processing worker (Cloud Scheduler trigger)

**Days 5-6: Claude Haiku Parsing**
- Implement Anthropic API client (Claude Haiku 4.5)
- Define brand/model/variant parsing schema (JSON mode)
- Test parsing with SerpAPI responses
- Write unit tests for parsing logic

**Day 7: Integration Testing**
- End-to-end test: Upload → SerpAPI → Parse → Firestore
- Validate cost: $0.0109 per item
- Validate latency: 5-7s p95

**Deliverables:**
- Working SerpAPI integration with queueing
- Claude Haiku parsing service
- Redis queue with rate limiting (45/min)
- 30+ unit tests, 10+ integration tests

**Validation:**
- Test with 20 household items
- Success rate: >85% (product matches found)
- Parsing accuracy: >90% (brand/model correct)
- Cost: ≤$0.012 per item

---

## Week 5: Layer 2a - Attribute Extraction

**Goal:** Gemini 2.5 Flash-Lite attribute extraction

### Tasks
**Days 1-2: Vertex AI Setup**
- Configure Vertex AI API access
- Implement Gemini 2.5 Flash-Lite client (@google-cloud/vertexai)
- Define attribute schema (JSON mode with validation)

**Days 3-4: Attribute Extraction Logic**
- Implement attribute extraction function
- Test JSON schema mode (condition, color, material, category)
- Handle malformed responses (retry, fallback)
- Write unit tests

**Days 5: Integration with Layer 1**
- Integrate with iOS upload pipeline
- Parallel execution: Layer 2a + Layer 2b (Promise.all)
- Write integration tests

**Days 6-7: Layer 3 - AI Synthesis**
- Implement Claude Sonnet 4.5 Batch API client
- Define synthesis prompt (merge Layer 2a + 2b results)
- Implement conflict resolution logic
- Test final metadata generation

**Deliverables:**
- Gemini 2.5 Flash-Lite service ($0.000249/image)
- Claude Sonnet 4.5 synthesis service ($0.0092/inference)
- Parallel Layer 2a + 2b execution
- 25+ unit tests, 15+ integration tests

**Validation:**
- Test with 20 household items
- Layer 2a success rate: >95% (valid JSON)
- Layer 3 synthesis accuracy: >85%
- Cost: ≤$0.020 per item (full pipeline)

---

## Week 6: Integration & POC Validation

**Goal:** End-to-end pipeline testing and POC validation

### Tasks
**Days 1-2: iOS Integration**
- Integrate Layer 1 → Layer 2a+2b → Layer 3 → Firestore
- Implement real-time Firestore listeners (SwiftUI)
- Display enriched metadata in ItemReviewView
- Test user flow: Capture → Review → Confirm → Save

**Days 3-4: E2E Testing**
- Test full pipeline with 50 diverse household items
- Measure accuracy (name, category, brand, model, condition)
- Measure cost per item (actual vs. $0.019449 estimate)
- Measure latency (p50, p95, p99)

**Day 5: Performance Optimization**
- Profile slow queries (Firestore indexes)
- Optimize Redis queue processing
- Review Cloud Function cold starts
- Add Cloud Monitoring dashboards

**Days 6-7: Documentation & Handoff**
- Document API contracts (Cloud Functions)
- Write deployment guide (GCP setup)
- Create monitoring runbook (alerts, debugging)
- Generate POC validation report

**Deliverables:**
- Working end-to-end pipeline (iOS → Cloud → iOS)
- POC validation report with metrics
- Deployment documentation
- Monitoring dashboards

**Validation Criteria:**
- ✅ Accuracy: >80% correct metadata on first try
- ✅ Cost: ≤$0.020 per item (actual measured)
- ✅ Latency: ≤10s p95 (user-facing timeout)
- ✅ Detection rate: 75-80% (Layer 1 YOLOv3)
- ✅ Tests: 430+ tests passing (70% unit, 20% integration, 10% E2E)

---

## Milestones & Review Gates

| Week | Milestone | Review Gate | Success Criteria |
|------|-----------|-------------|------------------|
| **Week 2** | Layer 1 Complete | iOS Demo | Detect + crop 10 items, <500ms latency |
| **Week 3** | Infrastructure Deployed | Cloud Demo | GCS + Redis + Cloud Functions working |
| **Week 4** | Layer 2b Complete | SerpAPI Demo | 20 items searched, >85% success, <7s latency |
| **Week 5** | Layer 2a + 3 Complete | Full AI Demo | 20 items enriched, >80% accuracy, <$0.02 cost |
| **Week 6** | POC Validated | Final Review | 50 items, all criteria met, ready for beta |

**Review Format:**
- Demo: Live demonstration of functionality
- Metrics Review: Cost, latency, accuracy measurements
- Code Review: ADRs followed, tests passing, documentation complete
- Go/No-Go Decision: Proceed to beta or iterate

---

## Risk Mitigation

### High-Risk Items
1. **SerpAPI Rate Limits** (3,000/hour)
   - Mitigation: Redis queue with 45/min safety buffer
   - Contingency: Upgrade to Big Data plan (50,000/hour)

2. **Cost Overruns** (target: $0.020/item)
   - Mitigation: Track actual costs in Week 5-6
   - Contingency: Disable Layer 2b for common items (use Layer 2a only)

3. **Latency Exceeds 10s** (user timeout)
   - Mitigation: Parallel Layer 2a + 2b (Promise.all)
   - Contingency: Show Layer 2a results immediately, update with Layer 2b+3 later

4. **Accuracy Below 80%** (fails "like magic" requirement)
   - Mitigation: Test with diverse dataset in Week 6
   - Contingency: Upgrade to Claude Sonnet 4.5 extended thinking mode

---

## Resource Requirements

### Engineering Team
- **iOS Developer** (full-time, Weeks 1-6): Layer 1, camera, SwiftUI
- **Backend Developer** (full-time, Weeks 3-6): Cloud Functions, SerpAPI, Gemini, Claude
- **ML Engineer** (part-time, Weeks 1-2, 5-6): YOLOv3 integration, POC validation
- **DevOps Engineer** (part-time, Week 3): GCP infrastructure setup

### Cloud Platform Costs (Weeks 1-6)
- **Development/Testing:** ~$100/month
  - GCS: $1
  - Cloud CDN: $5
  - Redis: $25
  - Cloud Functions: $10
  - API costs (testing): $60 (300 test items × $0.02)

**Total Estimated Cost:** $600 for 6-week POC development

---

## Dependencies

### External APIs
- **Apple ML Models:** YOLOv3-Tiny download (no API key needed)
- **Google Vertex AI:** Gemini 2.5 Flash-Lite (requires GCP project)
- **SerpAPI:** Production plan subscription ($50/month, 3,000 searches/hour)
- **Anthropic:** Claude Haiku 4.5 + Sonnet 4.5 Batch API (requires API key)

### Internal Dependencies
- **Firebase Auth:** User authentication (existing)
- **Cloud Firestore:** Item metadata storage (existing)
- **iOS App:** Camera, photo library access (existing from free tier)

---

## Success Metrics

### Technical Metrics (Week 6 Validation)
- **Layer 1 Detection Rate:** 75-80% (YOLOv3-Tiny, 80 COCO classes)
- **Layer 2a JSON Success Rate:** >95% (Gemini 2.5 Flash-Lite)
- **Layer 2b Product Match Rate:** >85% (SerpAPI + Claude Haiku)
- **Layer 3 Synthesis Accuracy:** >85% (Claude Sonnet 4.5)
- **End-to-End Accuracy:** >80% (name + category correct)
- **Cost per Item:** ≤$0.020 (measured actual)
- **Latency p95:** ≤10 seconds (user-facing)
- **Test Coverage:** >90% (unit + integration)

### Business Metrics (Post-POC, Month 1 Beta)
- **Free → Premium Conversion:** >20% (users impressed by AI accuracy)
- **User Correction Rate:** <30% (metadata edited manually)
- **Daily Active Users (Premium):** 50+ beta users
- **Items Cataloged per User:** 10+ items/month average

---

## Next Steps After POC

### Week 7: Beta Deployment
- Deploy to TestFlight (100 beta users)
- Monitor actual usage patterns and costs
- Iterate on prompts based on user corrections

### Week 8-10: Beta Feedback & Iteration
- A/B test hybrid strategies (vision-only vs. full pipeline)
- Implement prompt caching (90% cost reduction for Layer 3)
- Optimize queue processing (reduce latency)

### Week 11-12: Production Readiness
- Scale testing (1,000 concurrent users)
- Security audit (signed URLs, rate limiting)
- Monitoring & alerting setup (Cloud Monitoring)
- Final cost validation (Month 6 projection: $1,459/month)

### Month 4: Public Launch
- App Store submission
- Marketing campaign (target: 5K users by Month 6)
- Monitor metrics: Cost, accuracy, conversion, retention

---

## Appendix: Detailed Implementation Plan

For bite-sized tasks (2-5 minutes each) with exact code and commands, see:

📄 **`docs/plans/2025-11-01-stage-2.2-ios-architecture-implementation.md`**

This roadmap provides the high-level timeline; the detailed plan provides step-by-step instructions for engineers.

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-01 | 1.0 | Initial roadmap for Stage 2.2 implementation (6-week POC) |

---

## Approval

**Status:** ✅ APPROVED (2025-11-01)

**Approved By:**
- Product Leadership: POC scope and timeline approved
- Engineering Leadership: Resource allocation and technical approach approved
- Finance: Budget approved ($600 POC development + $50/month SerpAPI)

**Next Action:** Begin Week 1 (Layer 1 iOS Object Detection)

**Questions/Concerns:** Contact project lead or reference detailed implementation plan

---

**End of Roadmap**

