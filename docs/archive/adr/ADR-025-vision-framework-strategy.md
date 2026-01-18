# ADR-025: Vision Framework Strategy

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, Computer Vision & ML Engineer
**Related Documents**:
- docs/validation/RESEARCH-VALIDATION-stage-2.0.md
- docs/design/DESIGN-004-computer-vision-pipeline.md
- docs/adr/ADR-004-ios-26-only-launch.md

---

## Context

Abundance needs on-device object detection for Layer 1 of the AI cataloging pipeline. Requirements:
- Privacy-first (full photos never leave device)
- $0 cost (sustainable free tier)
- < 500ms latency on iPhone 15 Pro
- iOS 26-only launch strategy (ADR-004)

## Decision

**Use VNCoreMLRequest + YOLOv3-Tiny for on-device object detection, and VNDetectBarcodesRequest for barcode scanning.**

### Technologies

1. **VNCoreMLRequest** (iOS 11.0+, available in iOS 26)
   - Integrates Core ML models with Vision framework
   - YOLOv3-Tiny model (34 MB, 80 COCO object classes)
   - Apple Neural Engine optimization (A17 Pro chip)

2. **VNDetectBarcodesRequest** (iOS 11.0+, available in iOS 26)
   - Detects 24 barcode symbologies (UPC, EAN, QR, Aztec, etc.)
   - High accuracy (> 95% in ideal conditions)

3. **Core ML YOLOv3-Tiny**
   - Model size: 34 MB
   - Accuracy: 33.1% mAP on COCO dataset
   - Supported classes: 80 (person, backpack, handbag, suitcase, bottle, cup, fork, knife, spoon, bowl, camping equipment, sports equipment, furniture, electronics, etc.)

## Rationale

### 1. Privacy-First Architecture

**Requirement** (ADR-001, ADR-004): Full photos must never leave device.

**Solution**: VNCoreMLRequest processes images entirely on-device. Only cropped objects (bounding box regions) are uploaded to cloud for Layer 2/3 processing.

**Outcome**: Privacy firewall maintained. Users can catalog items without uploading full home photos.

### 2. Free Tier Sustainability

**Requirement** (ADR-003): Free tier must have $0 marginal cost.

**Solution**: On-device processing costs $0 (no cloud API calls). Users get functional cataloging (coarse accuracy) without subscription.

**Outcome**: 85% of users (free tier) cost $0. Premium tier (15%) covers all cloud AI costs.

### 3. Cost Comparison

| Option | Cost per Item | Latency | Privacy |
|--------|---------------|---------|---------|
| **VNCoreMLRequest (on-device)** | **$0** | **300-500ms** | **100%** |
| Cloud AI only (Gemini) | $0.000249 | 50-100ms | 0% |
| Cloud AI only (GPT-4V) | $0.00765 | 200-500ms | 0% |

**Savings**: On-device free tier saves $0.000249-0.00765 per item × 85% of users × 50 items/user = significant cost reduction.

### 4. Accuracy Trade-Off Acceptable

**Challenge**: YOLOv3-Tiny has lower accuracy (33.1% mAP) compared to cloud AI (80-90% accuracy).

**Mitigation**:
- Layer 1 provides coarse detection (e.g., "backpack")
- Layer 2/3 cloud AI refines results (e.g., "Coleman Evanston 8-Person Tent")
- Free tier users get functional utility (search by category works)
- Premium tier users get granular accuracy

**Outcome**: 75%+ overall accuracy (end-to-end) even with 33% Layer 1 accuracy.

## Alternatives Considered

### Alternative 1: YOLOv8n (Higher Accuracy)

**Approach**: Use YOLOv8n model instead of YOLOv3-Tiny

**Pros**:
- Higher accuracy (37.3% mAP vs 33.1%)
- Smaller model size (6.2 MB vs 34 MB)

**Cons**:
- No official CoreML export (requires custom conversion)
- Less documentation/examples for iOS integration
- Higher risk of integration issues

**Why Rejected**: YOLOv3-Tiny has proven CoreML support with official Apple examples. 4% accuracy gain not worth integration risk.

### Alternative 2: Cloud-Only AI (No On-Device Detection)

**Approach**: Upload full photos to cloud, use Gemini/GPT-4V for all processing

**Pros**:
- Higher accuracy (80-90%)
- Simpler iOS implementation (no Core ML)

**Cons**:
- **Privacy violation**: Full photos uploaded
- **Cost unsustainable**: $0.020 per item × 85% free tier users = negative margin
- **Contradicts strategic positioning** (ADR-001: privacy-first)

**Why Rejected**: Violates core product values and business model.

### Alternative 3: No Object Detection (Catalog Full Photo)

**Approach**: Skip object detection, catalog entire photo as single item

**Pros**:
- Simplest implementation
- No ML model required

**Cons**:
- Lower accuracy (full photo contains background noise)
- Higher cloud AI costs (larger images to process)
- Poor UX (can't detect multiple items in one photo)

**Why Rejected**: Doesn't meet "10× better than spreadsheet" value proposition.

## Implications & Consequences

### Positive

1. **$0 Free Tier Cost**: Sustainable freemium economics (64-91% margin)
2. **Privacy Maintained**: Full photos never leave device
3. **Fast Performance**: < 500ms on A17 Pro chip
4. **iOS 26 Alignment**: Leverages latest Vision framework capabilities

### Negative

1. **Lower Layer 1 Accuracy**: 33.1% mAP (mitigated by Layer 2/3 cloud AI)
2. **iOS 26-Only Constraint**: Limits addressable market to 15% (accepted in ADR-004)
3. **Model Size**: 34 MB app size increase (acceptable for modern iPhones)

## Acceptance Criteria

- [x] ✅ VNCoreMLRequest integrates YOLOv3-Tiny successfully
- [x] ✅ Object detection latency < 500ms on iPhone 15 Pro
- [x] ✅ Cropped objects uploaded to GCS (not full photos)
- [x] ✅ VNDetectBarcodesRequest detects 24 symbologies
- [x] ✅ Free tier users can catalog items with $0 cost

## Related Decisions

- **ADR-001**: Strategic positioning (privacy-first) → Requires on-device processing
- **ADR-004**: iOS 26-only launch → Enables Vision Framework usage
- **ADR-014**: Cloud AI provider selection → Layer 2/3 refines Layer 1 results

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, VNCoreMLRequest + YOLOv3-Tiny | Computer Vision & ML Engineer |
