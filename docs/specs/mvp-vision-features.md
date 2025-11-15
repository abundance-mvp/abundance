# MVP Vision Features: Simplifications from Google Lens

**Document Type**: Feature Specification
**Status**: Draft
**Date**: 2025-10-23
**Related**: DESIGN-004, Google Lens Architecture Analysis

---

## Executive Summary

Abundance MVP will implement a **simplified subset** of Google Lens capabilities, focused exclusively on **home inventory cataloging**. This document defines what's in/out of MVP scope.

**TL;DR**:
- ✅ **MUST HAVE**: Single-object photo capture, barcode scanning, AI metadata extraction
- ⚠️ **COULD HAVE**: Multi-object detection, OCR for labels
- ❌ **WON'T HAVE**: Real-time AR, translation, landmark recognition, image search

---

## Feature Comparison Matrix

| **Google Lens Feature** | **Relevant to Abundance?** | **MVP Priority** | **Rationale** |
|-------------------------|----------------------------|------------------|---------------|
| **Object Detection** | ✅ Yes | **MUST HAVE** | Core functionality for cataloging |
| **Single-Object Mode** | ✅ Yes | **MUST HAVE** | Simpler UX, higher accuracy |
| **Multi-Object Detection** | ⚠️ Maybe | **DEFER to v2** | Nice-to-have (scan shelf), but increases complexity |
| **Barcode Scanning** | ✅ Yes | **MUST HAVE** | Essential for packaged goods (high success rate) |
| **Product Identification** | ✅ Yes | **MUST HAVE** | Name, category, brand needed for inventory |
| **Price Estimation** | ✅ Yes | **SHOULD HAVE** | Valuable for insurance, but can be inaccurate initially |
| **Product Information APIs** | ⚠️ Maybe | **COULD HAVE** | Improves accuracy for barcoded items, adds cost |
| **Real-time Camera Processing** | ❌ No | **WON'T HAVE** | Not needed for cataloging workflow |
| **Real-time AR Overlays** | ❌ No | **WON'T HAVE** | Adds complexity, not core value |
| **Text Recognition (OCR)** | ⚠️ Maybe | **COULD HAVE** | Useful for reading labels, but not essential |
| **Image Search / Visual Similarity** | ❌ No | **WON'T HAVE (Phase 3)** | Marketplace discovery feature, defer |
| **Translation** | ❌ No | **WON'T HAVE** | Not relevant to home inventory |
| **Landmark Recognition** | ❌ No | **WON'T HAVE** | Not relevant |
| **Plant/Animal ID** | ❌ No | **WON'T HAVE** | Not relevant |
| **Homework Help** | ❌ No | **WON'T HAVE** | Not relevant |

---

## MVP Feature Set (Minimum Viable Product)

### ✅ MUST HAVE (Core Functionality)

| **Feature** | **Description** | **User Benefit** |
|-------------|----------------|------------------|
| **Single-Object Photo Capture** | User takes one photo of one item | Simple, focused UX |
| **On-Device Object Detection** | Vision framework detects object, crops it | Privacy-preserving |
| **Barcode Scanning** | Automatically detect and scan barcodes | High accuracy for packaged goods |
| **Cloud AI Metadata Extraction** | Gemini Vision analyzes object → returns {name, category, brand, value} | Automated cataloging |
| **Manual Editing** | User can edit any AI-suggested field | Accuracy safety net |
| **Save to Firestore** | Store item in inventory database | Persistent inventory |
| **Display in Inventory UI** | List view of all cataloged items | View inventory |

**Expected User Flow**:
1. Tap "Add Item"
2. Take photo
3. Wait 3-5 seconds (AI processing)
4. Review AI-suggested metadata
5. Edit if needed
6. Tap "Save to Inventory"

---

### ⚠️ COULD HAVE (Nice-to-Have)

| **Feature** | **MVP Decision** | **Post-MVP Consideration** |
|-------------|------------------|----------------------------|
| **OCR for Labels** | **DEFER** | Useful for reading brand names on unlabeled items |
| **Barcode Lookup API** | **DEFER** | Improves accuracy but adds cost (~$0.005/item) |
| **Condition Assessment** | **DEFER** | AI estimates condition (new/used/worn) |
| **Multi-Category Detection** | **DEFER** | Detect multiple categories in one scan |

---

### ❌ WON'T HAVE (Out of Scope for MVP)

| **Feature** | **Why Not in MVP** | **Future Phase** |
|-------------|-------------------|------------------|
| **Multi-Object Capture** | Increases error rate, more complex UX | v2 (Q2 2026) |
| **Real-time Camera Processing** | Not needed for cataloging (async is fine) | Maybe v3 |
| **AR Overlays** | Adds complexity, no clear user value | Maybe v3 |
| **Image Search** | Complex, expensive, belongs in marketplace | Phase 3 (Marketplace) |
| **Translation** | Not relevant | Never |
| **Landmark Recognition** | Not relevant | Never |

---

## Architecture Simplifications

### Google Lens (Complex)
- Real-time on-device processing
- AR overlays with interactive elements
- Multiple ML models running simultaneously
- Knowledge Graph + Shopping Graph integration
- Image search backend
- Multi-modal AI (text + image + voice)

### Abundance MVP (Simplified)
- **Photo capture** (not real-time)
- **Standard UI** (not AR)
- **Single object detection** (not multi-object)
- **One AI API** (Gemini Vision)
- **Optional barcode API** (simple REST call)
- **Async processing** (3-5 second wait is acceptable)

**Estimated Complexity Reduction**: ~70% simpler than Google Lens

---

## Success Metrics for MVP

| **Metric** | **Target** | **Measurement Method** |
|------------|-----------|------------------------|
| **Accuracy (correct name/category)** | > 75% | Manual validation on 100-item test set |
| **Barcode Success Rate** | > 95% | Automated testing |
| **User Edit Rate** | < 50% | Analytics (% of items edited before saving) |
| **Processing Time** | < 6 seconds | Automated timing logs |
| **Cost per Item** | < $0.03 | Cloud cost tracking |
| **User Satisfaction** | > 4.0/5 | In-app rating after first 10 items cataloged |

---

## User Expectations Management

**Communication Strategy**:

**❌ Don't say**:
- "AI perfectly identifies your items"
- "Automated inventory management"

**✅ Do say**:
- "AI suggests item details - you confirm or edit"
- "Smart cataloging with AI assistance"
- "AI-powered suggestions to speed up cataloging"

**UI Patterns**:
- Show confidence level (High/Medium/Low)
- Make editing prominent and easy
- Default to "Review" screen (not auto-save)
- "AI Suggestion" label on metadata fields

---

## Roadmap: Post-MVP Features

### v2 (Q2 2026)
- ✅ Multi-object detection (scan entire shelf)
- ✅ Barcode lookup API integration
- ✅ OCR for labels and brand names
- ✅ Condition assessment (new/used/worn)
- ✅ Price data from eBay/Amazon APIs

### v3 (Q4 2026)
- ✅ Image search for marketplace (find similar items for sale)
- ✅ Batch import from photo library
- ✅ Custom categories and tags

### Phase 3: Marketplace (2027)
- ✅ Visual similarity matching (find your item in marketplace)
- ✅ Reverse image search for pricing

---

## Decision Log

| **Decision** | **Rationale** | **Date** |
|-------------|---------------|----------|
| Single-object only in MVP | Simpler UX, higher accuracy, faster to ship | 2025-10-23 |
| No real-time AR | Adds complexity without clear cataloging value | 2025-10-23 |
| Async processing acceptable | 3-5 second wait is fine for cataloging (vs. real-time search) | 2025-10-23 |
| Defer barcode API | Simplify MVP, add later for accuracy improvement | 2025-10-23 |
| Defer image search | Belongs in marketplace phase, not core inventory | 2025-10-23 |

---

**Document Status**: ✅ Complete
**Approval Needed**: Product, Engineering
