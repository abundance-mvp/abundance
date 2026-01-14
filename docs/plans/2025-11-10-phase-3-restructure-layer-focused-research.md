# Phase 3 Restructure: Layer-Focused Implementation Research

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure Phase 3 of the Abundance Analysis Pipeline to focus on layer-by-layer implementation research for the 4-layer AI cataloging pipeline, expanding from 3 stages to 6 stages with clear separation between architecture (Stage 2.4) and implementation research (Phase 3).

**Architecture:** Phase 3 currently has ambiguous scope mixing architecture decisions with implementation research. This plan transforms Phase 3 into layer-focused implementation research stages that follow Stage 2.4's complete 4-layer architecture design.

**Tech Stack:** Markdown documentation, JSON schema (context-map.json), existing pipeline artifacts from Stages 2.0-2.5 and 3.1-3.2

---

## Critical Gap Identified: No UI/UX Design Stage

### ❌ Missing: iOS UI/UX Design & Liquid Glass Integration

**Problem**: The pipeline has NO stage for:
- Liquid Glass design system integration (iOS 26 mandate from ADR-004)
- Screen-by-screen UI designs (camera, catalog, item detail, sharing, marketplace)
- Navigation flows (tab bar, navigation stacks, modal presentations)
- Component library (SwiftUI components using Liquid Glass)
- AI cataloging UX (progressive disclosure: Layer 1 → 2a → 2b → 3)
- Sharing circles UX, Marketplace UX, Login/Onboarding UX

**What exists** (insufficient):
- Stage 1.2: High-level UX strategy (user journeys, personas) - NOT detailed UI design
- Stage 2.2: iOS code architecture (MVVM, modules) - NOT screen design
- Stage 3.1: Swift implementation patterns - NOT UI components

**Solution**: Add **Stage 2.6: iOS UI/UX Design & Liquid Glass Integration** to Phase 2 before Phase 3 execution.

**Why Phase 2?** UI/UX design is architecture (user-facing architecture), fits Phase 2's "Technical Architecture" theme.

**Impact on Phase 3**: Stage 3.1 (iOS Implementation Research) must depend on Stage 2.6 outputs to know WHAT screens/components to implement.

---

## Findings: Stage 2.4 Completeness Assessment

### ✅ Stage 2.4 IS Complete for Layer 3 Architecture

**Review of Stage 2.4 outputs**:

1. **PLAN-SUMMARY-stage-2.4.md** (lines 140-169):
   - Layer 3 specified: "AI Synthesis (Claude Sonnet 4.5 Batch API)"
   - Implementation patterns documented: "Merge Layer 2a + 2b results, conflict resolution, confidence scoring, final metadata generation"
   - Code examples provided (Node.js Anthropic SDK)
   - Deliverables: DESIGN-020 (AI Synthesis Architecture)

2. **ADR-015-ai-reasoning-layer-architecture.md**:
   - ✅ Claude Sonnet 4.5 selection rationale (conflict resolution, multimodal capabilities, cost efficiency)
   - ✅ Batch API justification (50% cost savings, acceptable 24-hour latency)
   - ✅ Conflict resolution use cases (color mismatch, category conflict)
   - ✅ Confidence scoring mentioned (high/medium/low)
   - ✅ Cost model ($0.002027 per inference)
   - ✅ Alternatives considered (Claude Haiku, Gemini Pro, no Layer 3)

3. **DESIGN-020-ai-synthesis-architecture.md**:
   - ✅ Complete implementation specification (785 lines)
   - ✅ Conflict resolution algorithms (4 types: color, category, brand/model, condition)
   - ✅ Confidence scoring algorithm (factors: vision AI confidence, product source, conflict count)
   - ✅ Value estimation logic (condition multipliers: new=1.0, like-new=0.85, good=0.70, fair=0.50, poor=0.30)
   - ✅ Code examples (synthesis function, prompt builder, error handling)
   - ✅ Integration patterns (Firestore triggers, real-time UI updates)
   - ✅ Error handling (rate limits, overloaded errors, missing data)
   - ✅ Testing specifications (unit tests, integration tests)

**Conclusion**: **Stage 2.4 does NOT need re-execution.** Layer 3 synthesis is comprehensively specified with algorithms, code examples, and implementation patterns.

### ❌ Phase 3 IS Incomplete - Layer Focus Missing

**Current Phase 3 problems**:

1. **Stage 3.3 (AI Provider Deep Dive)** is ambiguous:
   - Mixes "Vertex AI Vision API" (not used - we use Gemini 2.5 Flash-Lite)
   - Mixes "Claude Sonnet 4.5 API" (Layer 3) with "Gemini Vision API" (Layer 2a)
   - Unclear if researching ALTERNATIVES (Vertex AI vs Gemini vs Claude) or IMPLEMENTATION (how to use already-chosen providers)
   - No separation between Layer 2a (Gemini), Layer 2b (SerpAPI + barcode), Layer 3 (Claude Sonnet)

2. **No Stage for Layer 1 implementation research**:
   - YOLO model download, integration patterns
   - Barcode detection accuracy testing
   - Apple Neural Engine optimization

3. **No benchmarking/testing focus**:
   - Testing YOLO accuracy on household items
   - Benchmarking Gemini 2.5 Flash-Lite attribute extraction
   - Testing SerpAPI + barcode lookup coverage
   - Validating Claude Sonnet conflict resolution

**Root cause**: Phase 3 conflates "AI provider comparison" (architecture decision, already done in Stage 2.0) with "implementation research" (how to implement already-chosen providers).

---

## Revised Phase 3 Structure

### New Phase 3 Objective

**OLD** (ambiguous): "Deep Technical Research" (what does this mean?)

**NEW** (clear): "Layer-by-Layer Implementation Research - Validate assumptions, benchmark accuracy, create implementation patterns for the already-designed 4-layer AI pipeline"

### Stage Mapping: Layers → Stages

| Stage | Name | Layer Focus | Purpose | Key Deliverables |
|-------|------|-------------|---------|------------------|
| **3.1** | iOS Implementation Research | **iOS Client + Layer 1 (partial)** | Swift 6 patterns, Firebase SDK, SwiftUI architecture | RESEARCH-001, CODE-EXAMPLES-001 (KEEP - already complete) |
| **3.2** | Backend Implementation Research | **Cloud Functions, Firestore, Firebase Storage** | Node.js patterns, Firestore queries, GCP observability | RESEARCH-002, CODE-EXAMPLES-002, INFRASTRUCTURE-001 (KEEP - already complete) |
| **3.3** | Layer 1 On-Device ML Research | **Layer 1: Vision Framework + YOLO + Barcode** | YOLO integration, barcode accuracy, Neural Engine optimization | RESEARCH-003, BENCHMARK-001, CODE-EXAMPLES-003 |
| **3.4** | Layer 2a Attribute Extraction Research | **Layer 2a: Gemini 2.5 Flash-Lite** | JSON Schema Mode, prompt engineering, attribute accuracy | RESEARCH-004, PROMPT-TEMPLATES-001, BENCHMARK-002 |
| **3.5** | Layer 2b Product Search Research | **Layer 2b: SerpAPI + UPCitemdb + Barcode + Claude Haiku** | SerpAPI integration, barcode coverage, Claude Haiku parsing | RESEARCH-005, PROMPT-TEMPLATES-002, BENCHMARK-003 |
| **3.6** | Layer 3 AI Synthesis Research | **Layer 3: Claude Sonnet 4.5** | Conflict resolution testing, confidence scoring validation, synthesis prompts | RESEARCH-006, PROMPT-TEMPLATES-003, BENCHMARK-004 |

---

## Task 0: Add Stage 2.6 (iOS UI/UX Design & Liquid Glass Integration)

**Files:**
- Modify: `docs/abundance-analysis-pipeline-design.md:1094-1188` (add Stage 2.6 after Stage 2.5)
- Modify: `docs/context-map.json` (add stage-2.6 definition after stage-2.5)

**Step 1: Add Stage 2.6 to master pipeline design**

Insert after Stage 2.5 (line 1185 in master pipeline document):

```markdown
---

### Stage 2.6: iOS UI/UX Design & Liquid Glass Integration

**Expert Agent**: Product Strategy & UX + iOS Architecture Expert

**Purpose**: Design screen-by-screen UI/UX for Abundance MVP using iOS 26 Liquid Glass design system, create component library, and specify navigation flows and interaction patterns.

**Input Documents**:

- **Stage 1.2 outputs** (user journeys, personas, trust & safety):
  - docs/specs/user-journey-maps.md
  - docs/specs/user-persona-cards.md
  - docs/specs/trust-safety-framework.md
  - docs/specs/mvp-vision-features.md
- **Stage 2.2 outputs** (iOS architecture):
  - docs/plans/PLAN-SUMMARY-stage-2.2.md
  - docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
  - docs/adr/ADR-011-ios-module-structure.md
  - docs/design/DESIGN-006-ios-module-dependencies.md
- **Stage 2.4 outputs** (CV pipeline UX requirements):
  - docs/plans/PLAN-SUMMARY-stage-2.4.md
  - docs/design/DESIGN-004-computer-vision-pipeline.md (4-layer progressive disclosure)
- **Apple documentation**:
  - Apple Human Interface Guidelines (HIG) - iOS 26
  - Liquid Glass Design System guidelines
  - SwiftUI component library

**Constraints from Previous Stages**:

- MUST use iOS 26 Liquid Glass design system (ADR-004: iOS 26-Only Launch)
- MUST follow MVVM architecture patterns (ADR-010)
- MUST support 4-layer AI pipeline UX (progressive disclosure Layer 1 → 2a → 2b → 3)
- MUST integrate Firebase Auth UI patterns (biometric, email/password)
- MUST follow Apple HIG for camera capture, permissions, privacy

**Research Tasks**:

1. **Liquid Glass Design System Research**:
   - Study iOS 26 Liquid Glass guidelines (materials, depth, animations)
   - Document Liquid Glass component patterns (buttons, cards, forms, navigation)
   - Identify Liquid Glass color palettes, typography, spacing system
   - Research Liquid Glass animation patterns (spring animations, transitions)

2. **Screen-by-Screen UI Design**:
   - **Camera Capture Screen**: AVFoundation camera view, shutter button, object detection overlay
   - **Catalog List Screen**: Grid/list view of items, search/filter, sorting
   - **Item Detail Screen**: Photo gallery, metadata display, edit/share actions
   - **AI Cataloging Progress**: Progressive metadata updates (Layer 1 → 2a → 2b → 3)
   - **Sharing Circles Screen**: Create circle, invite members, manage permissions
   - **Marketplace Screen**: Browse listings, item detail, transaction flow
   - **Profile/Settings Screen**: User profile, preferences, subscription management
   - **Login/Onboarding**: Firebase Auth UI, biometric setup, first-run tutorial

3. **Navigation Architecture**:
   - Design tab bar structure (Camera, Catalog, Sharing, Marketplace, Profile)
   - Design navigation stacks (drill-down patterns, back navigation)
   - Design modal presentations (create item, share item, edit profile)
   - Document navigation state management (NavigationStack + Combine)

4. **Component Library Design**:
   - Design reusable SwiftUI components (ItemCard, MetadataRow, ProgressIndicator)
   - Create Liquid Glass-styled buttons, text fields, pickers
   - Design loading states, error states, empty states
   - Document component API contracts (props, callbacks, state)

5. **AI Cataloging UX Patterns**:
   - Design Layer 1 instant feedback (bounding boxes on camera)
   - Design Layer 2a attribute display (category, color, material badges)
   - Design Layer 2b product search results (brand, model, estimated value)
   - Design Layer 3 synthesis confidence UI (high/medium/low indicators)
   - Design metadata editing UX (user corrections, confidence boosting)

6. **Interaction Patterns**:
   - Swipe gestures (delete item, share item)
   - Pull-to-refresh (catalog list)
   - Long-press actions (context menus)
   - Drag-and-drop (reorder items, organize into circles)
   - Animations (item add, metadata update, screen transitions)

**Outputs**:

- **DESIGN-025: iOS UI/UX Architecture** (screen flows, navigation architecture, state management)
- **DESIGN-026: Liquid Glass Component Library** (SwiftUI components, styling patterns)
- **DESIGN-027: AI Cataloging UX Patterns** (progressive disclosure, loading states, confidence indicators)
- **DESIGN-028: Sharing Circles UX Flows** (create, invite, lend/borrow)
- **DESIGN-029: Marketplace UX Flows** (list, browse, transaction)
- **DESIGN-030: Onboarding & Authentication UX** (Firebase Auth, biometric, first-run)
- **ADR-021: Liquid Glass Adoption Strategy** (why Liquid Glass, implementation approach)
- **ADR-022: Navigation Architecture** (tab bar vs navigation stack decisions)
- **UI-MOCKUPS-001: Screen Mockups** (Figma/Sketch wireframes - optional, can be markdown-described)
- **PLAN-SUMMARY-stage-2.6.md**
- **CHECKPOINT-stage-2.6-2025-11-10.md**

**Checkpoint Questions**:

- Does the UI design follow iOS 26 Liquid Glass guidelines?
- Are all MVP features (camera, catalog, sharing, marketplace) designed?
- Is the AI cataloging progressive disclosure UX clear?
- Are navigation flows intuitive and consistent with iOS patterns?
- Is the component library comprehensive for MVP needs?

**Human Decision Required**:

- Approve UI/UX design direction
- Approve Liquid Glass component styling
- Approve navigation architecture (tab bar structure)
- Approve AI cataloging UX patterns (progressive disclosure)

**Why This Stage is Critical**:

- **iOS 26 Liquid Glass is MANDATORY** (ADR-004: iOS 26-Only Launch strategy)
- **UI informs implementation** (Stage 3.1 iOS research needs to know WHAT to build)
- **AI cataloging UX is complex** (4-layer pipeline needs thoughtful progressive disclosure)
- **No formal UI design exists yet** (Stage 1.2 = strategy, Stage 2.2 = code architecture, NOT UI design)

---
```

**Step 2: Add Stage 2.6 to context-map.json**

Insert after stage-2.5 definition (around line 318 in context-map.json):

```json
"stage-2.6": {
  "name": "iOS UI/UX Design & Liquid Glass Integration",
  "expert_agent": "Product Strategy & UX + iOS Architecture Expert",
  "status": "pending",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_1.2": [
      "docs/specs/user-journey-maps.md",
      "docs/specs/user-persona-cards.md",
      "docs/specs/trust-safety-framework.md",
      "docs/specs/mvp-vision-features.md"
    ],
    "from_stage_2.2": [
      "docs/plans/PLAN-SUMMARY-stage-2.2.md",
      "docs/adr/ADR-010-swiftui-architecture-pattern.md",
      "docs/adr/ADR-011-ios-module-structure.md",
      "docs/design/DESIGN-006-ios-module-dependencies.md"
    ],
    "from_stage_2.4": [
      "docs/plans/PLAN-SUMMARY-stage-2.4.md",
      "docs/design/DESIGN-004-computer-vision-pipeline.md"
    ],
    "apple_docs": "docs/apple/"
  },
  "expected_outputs": [
    "docs/plans/PLAN-SUMMARY-stage-2.6.md",
    "docs/design/DESIGN-025-ios-ui-ux-architecture.md",
    "docs/design/DESIGN-026-liquid-glass-component-library.md",
    "docs/design/DESIGN-027-ai-cataloging-ux-patterns.md",
    "docs/design/DESIGN-028-sharing-circles-ux-flows.md",
    "docs/design/DESIGN-029-marketplace-ux-flows.md",
    "docs/design/DESIGN-030-onboarding-authentication-ux.md",
    "docs/adr/ADR-021-liquid-glass-adoption-strategy.md",
    "docs/adr/ADR-022-navigation-architecture.md",
    "docs/ui-mockups/UI-MOCKUPS-001-screen-wireframes.md",
    "docs/checkpoints/CHECKPOINT-stage-2.6-2025-11-10.md"
  ]
},
```

**Step 3: Update Stage 3.1 dependencies to require Stage 2.6**

In context-map.json, find stage-3.1 (around line 320) and add Stage 2.6 outputs to required_inputs:

```json
"stage-3.1": {
  "name": "iOS Implementation Research",
  "expert_agent": "iOS Architecture Expert",
  "status": "completed",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_2.2": [
      "docs/plans/PLAN-SUMMARY-stage-2.2.md"
    ],
    "from_stage_2.6": [
      "docs/plans/PLAN-SUMMARY-stage-2.6.md",
      "docs/design/DESIGN-025-ios-ui-ux-architecture.md",
      "docs/design/DESIGN-026-liquid-glass-component-library.md",
      "docs/design/DESIGN-027-ai-cataloging-ux-patterns.md"
    ],
    "from_stage_2.1": [
      "docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md"
    ],
    "all_ios_adrs": [
      "docs/adr/ADR-008-*.md",
      "docs/adr/ADR-009-*.md",
      "docs/adr/ADR-010-*.md"
    ],
    "apple_docs": "docs/apple/"
  },
  ...
}
```

**Step 4: Commit Stage 2.6 addition**

```bash
git add docs/abundance-analysis-pipeline-design.md docs/context-map.json
git commit -m "feat: add Stage 2.6 (iOS UI/UX Design & Liquid Glass Integration)

Add missing UI/UX design stage to Phase 2 before Phase 3 execution.

Stage 2.6 addresses critical gap:
- Liquid Glass design system integration (iOS 26 mandate)
- Screen-by-screen UI designs (camera, catalog, sharing, marketplace)
- Navigation architecture (tab bar, navigation stacks)
- Component library (SwiftUI components using Liquid Glass)
- AI cataloging UX (progressive disclosure: Layer 1→2a→2b→3)

Update Stage 3.1 dependencies to require Stage 2.6 outputs.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 1: Review and Document Findings

**Files:**
- Read: `docs/plans/PLAN-SUMMARY-stage-2.4.md`
- Read: `docs/adr/ADR-015-ai-reasoning-layer-architecture.md`
- Read: `docs/design/DESIGN-020-ai-synthesis-architecture.md`
- Create: `docs/validation/STAGE-2.4-REVIEW-layer-3-completeness.md`

**Step 1: Document Stage 2.4 completeness findings**

Create validation report documenting that Stage 2.4 adequately specified Layer 3 synthesis:

```markdown
# Stage 2.4 Review: Layer 3 Completeness Assessment

**Date**: 2025-11-10
**Reviewer**: Pipeline Architect
**Purpose**: Determine if Stage 2.4 adequately specified Layer 3 (AI Synthesis) before proceeding to Phase 3 restructure

## Assessment Result: ✅ COMPLETE

Stage 2.4 comprehensively specified Layer 3 AI synthesis architecture with no gaps requiring re-execution.

### Artifacts Reviewed

1. **ADR-015-ai-reasoning-layer-architecture.md**
   - Claude Sonnet 4.5 selection rationale: ✅ Complete
   - Conflict resolution capabilities: ✅ Documented
   - Confidence scoring approach: ✅ Mentioned
   - Cost model: ✅ Complete ($0.002027/inference)

2. **DESIGN-020-ai-synthesis-architecture.md** (785 lines)
   - Conflict resolution algorithms: ✅ Complete (4 types with code)
   - Confidence scoring algorithm: ✅ Complete (formula with factors)
   - Value estimation logic: ✅ Complete (condition multipliers)
   - Multi-source synthesis: ✅ Complete (Layer 2a + 2b merging)
   - Error handling: ✅ Complete (rate limits, overloaded, missing data)
   - Testing specifications: ✅ Complete (unit + integration tests)

### Layer 3 Specification Completeness

| Requirement | Specified? | Location |
|-------------|------------|----------|
| Multi-source data synthesis | ✅ Yes | DESIGN-020 lines 36-48, 234-290 |
| Conflict resolution logic | ✅ Yes | DESIGN-020 lines 294-366 (4 conflict types) |
| Confidence scoring algorithm | ✅ Yes | DESIGN-020 lines 370-414 (3 factors, scoring formula) |
| Metadata selection strategy | ✅ Yes | DESIGN-020 lines 234-290 (synthesis prompt) |
| Prompt engineering for synthesis | ✅ Yes | DESIGN-020 lines 224-290 (complete prompt) |
| Fallback strategies | ✅ Yes | DESIGN-020 lines 545-603 (error handling) |

### Conclusion

**No Stage 2.4 re-execution required.** Layer 3 synthesis architecture is fully specified with algorithms, code examples, and implementation patterns. Phase 3 can proceed to implementation research (benchmarking, accuracy testing, prompt optimization) without revisiting Stage 2.4 design.

**Recommendation**: Proceed with Phase 3 restructure to create layer-focused implementation research stages (3.3-3.6).
```

**Step 2: Commit validation report**

```bash
git add docs/validation/STAGE-2.4-REVIEW-layer-3-completeness.md
git commit -m "docs: validate Stage 2.4 Layer 3 completeness before Phase 3 restructure

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Update Master Pipeline Design Document

**Files:**
- Modify: `docs/abundance-analysis-pipeline-design.md:1237-1322` (Stage 3.3 section + add 3.4-3.6)

**Step 1: Replace Stage 3.3 definition with layer-focused stages**

Old Stage 3.3 (lines 1279-1321):
```markdown
### Stage 3.3: AI Provider Deep Dive

**Expert Agent**: Computer Vision & ML

**Input Documents**:
- [DESIGN-004-computer-vision-pipeline](../design/DESIGN-004-computer-vision-pipeline.md): Computer Vision Pipeline
- AI-INTEGRATION-LAYER-001
- ADR-014 (AI Provider Ranking draft)

**Research Tasks**:
1. **Vertex AI Vision API**: ... [AMBIGUOUS - not used in our pipeline]
2. **Claude Sonnet 4.5 API**: ... [Layer 3 only]
3. **Gemini Vision API**: ... [AMBIGUOUS - Layer 2a or alternative?]
4. **Accuracy benchmarks**: ... [Too generic]
5. **Prompt engineering**: ... [For which layer?]
```

New Stage 3.3-3.6 (replace lines 1279-1321):
```markdown
### Stage 3.3: Layer 1 On-Device ML Implementation Research

**Expert Agent**: iOS Architecture Expert + Computer Vision & ML Engineer

**Purpose**: Research and validate Layer 1 (on-device) implementation patterns for Vision Framework, YOLO object detection, and barcode scanning on iOS 26.

**Input Documents**:
- docs/plans/PLAN-SUMMARY-stage-3.1.md (iOS implementation patterns)
- docs/plans/PLAN-SUMMARY-stage-2.4.md (Layer 1 architecture design)
- docs/design/DESIGN-013-vision-framework-integration-patterns.md (VNCoreMLRequest patterns)
- docs/design/DESIGN-014-barcode-detection-implementation.md (barcode symbologies)
- docs/adr/ADR-013-vision-framework-strategy.md (VNCoreMLRequest + YOLOv3-Tiny)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

**Research Tasks**:

1. **YOLO Model Integration**:
   - Download YOLOv3-Tiny Core ML model (official source)
   - Test VNCoreMLRequest integration with YOLOv3-Tiny
   - Benchmark accuracy on household items (camping, electronics, furniture)
   - Measure latency on iPhone 15 Pro (Apple Neural Engine)
   - Document false positive rate for non-COCO classes

2. **Barcode Detection Accuracy**:
   - Test VNDetectBarcodesRequest with 24 symbologies
   - Measure accuracy on UPC-A, EAN-13, QR codes (most common)
   - Test failure modes (damaged barcodes, glare, low lighting)
   - Document confidence thresholds (when to trust barcode vs visual)

3. **Bounding Box Cropping**:
   - Test coordinate transformation (Vision → UIImage)
   - Measure cropping accuracy (object fully captured?)
   - Document edge cases (multiple objects, overlapping boxes)

4. **Apple Neural Engine Optimization**:
   - Benchmark YOLO latency (300-500ms target)
   - Test memory usage (prevent crashes on older devices)
   - Document optimization patterns (batch processing, image size)

5. **Privacy Firewall Validation**:
   - Verify full photos NEVER leave device
   - Test photo deletion after cropping
   - Document user consent flow

**Outputs**:

- **RESEARCH-003: Layer 1 On-Device ML Implementation Patterns** (YOLO integration, barcode detection, cropping algorithms)
- **BENCHMARK-001: Layer 1 Accuracy & Performance** (YOLO accuracy on household items, barcode detection rates, latency benchmarks)
- **CODE-EXAMPLES-003: Vision Framework Reference Implementations** (working Swift code for YOLO + barcode detection)
- **PLAN-SUMMARY-stage-3.3.md**
- **CHECKPOINT-stage-3.3-2025-11-10.md**

**Checkpoint Questions**:

- Does YOLO achieve > 70% accuracy on household items (COCO classes)?
- Does barcode detection achieve > 90% accuracy on UPC-A/EAN-13?
- Is latency acceptable (< 500ms on iPhone 15 Pro)?
- Are privacy guarantees maintained (full photos deleted)?

---

### Stage 3.4: Layer 2a Attribute Extraction Implementation Research

**Expert Agent**: Computer Vision & ML Engineer

**Purpose**: Research and validate Layer 2a (Gemini 2.5 Flash-Lite) implementation patterns for attribute extraction (category, color, material, condition) using Vertex AI JSON Schema Mode.

**Input Documents**:
- docs/plans/PLAN-SUMMARY-stage-3.2.md (backend implementation patterns)
- docs/plans/PLAN-SUMMARY-stage-2.4.md (Layer 2a architecture design)
- docs/design/DESIGN-017-vertex-ai-integration-patterns.md (Gemini JSON Schema Mode)
- docs/adr/ADR-014-cloud-ai-provider-selection.md (Gemini 2.5 Flash-Lite selection)
- docs/validation/RESEARCH-VALIDATION-stage-2.0.md (Gemini verification)

**Research Tasks**:

1. **Gemini 2.5 Flash-Lite JSON Schema Mode**:
   - Verify JSON Schema Mode availability (Vertex AI generationConfig.responseSchema)
   - Test structured output for { category, color, material, condition }
   - Measure schema compliance rate (does Gemini always return valid JSON?)
   - Document fallback when schema mode fails

2. **Attribute Extraction Accuracy**:
   - Benchmark category detection (camping, electronics, furniture, etc.)
   - Benchmark color detection (primary color, lighting variations)
   - Benchmark material detection (fabric, metal, plastic, wood)
   - Benchmark condition assessment (new, like-new, good, fair, poor)
   - Measure accuracy against human-labeled dataset (100 items)

3. **Prompt Engineering**:
   - Design optimal prompts for attribute extraction
   - Test prompt variations (concise vs verbose, JSON instructions)
   - Measure impact of image quality on accuracy
   - Document best practices (image size, cropping quality)

4. **Cost & Latency Validation**:
   - Verify actual cost ($0.000249 per image - from Stage 2.0)
   - Measure p50, p95, p99 latency (30-50ms target)
   - Test batch processing (multiple items in parallel)

5. **Error Handling**:
   - Test Vertex AI rate limits (300 requests/minute default)
   - Document retry logic (exponential backoff with jitter)
   - Test fallback strategies (Vertex AI fails → skip Layer 2a?)

**Outputs**:

- **RESEARCH-004: Layer 2a Attribute Extraction Patterns** (Gemini integration, JSON Schema Mode usage, error handling)
- **PROMPT-TEMPLATES-001: Layer 2a Attribute Prompts** (optimized prompts for category, color, material, condition)
- **BENCHMARK-002: Layer 2a Accuracy & Performance** (attribute accuracy by type, latency benchmarks, cost validation)
- **PLAN-SUMMARY-stage-3.4.md**
- **CHECKPOINT-stage-3.4-2025-11-10.md**

**Checkpoint Questions**:

- Does Gemini achieve > 80% accuracy for category detection?
- Does Gemini achieve > 75% accuracy for color/material/condition?
- Is JSON Schema Mode reliable (> 95% valid JSON)?
- Is latency acceptable (< 100ms p95)?
- Is cost accurate ($0.000249 per image)?

---

### Stage 3.5: Layer 2b Product Search Implementation Research

**Expert Agent**: Cloud Backend Architect + Computer Vision & ML Engineer

**Purpose**: Research and validate Layer 2b (SerpAPI Google Lens + UPCitemdb + Claude Haiku parsing) implementation patterns for product search, barcode lookup, and brand/model extraction.

**Input Documents**:
- docs/plans/PLAN-SUMMARY-stage-3.2.md (backend implementation patterns)
- docs/plans/PLAN-SUMMARY-stage-2.4.md (Layer 2b architecture design)
- docs/design/DESIGN-018-llm-parsing-implementation.md (Claude Haiku parsing)
- docs/design/DESIGN-019-barcode-api-integration.md (UPCitemdb fallback)
- docs/design/SERPAPI-INTEGRATION-001-swift-rest-api-patterns.md (SerpAPI REST)
- docs/adr/ADR-018-barcode-product-lookup-strategy.md (dual-mode strategy)

**Research Tasks**:

1. **UPCitemdb Barcode Lookup**:
   - Test API integration (barcode → product name, brand, category)
   - Measure barcode coverage (% of UPC-A/EAN-13 found in database)
   - Benchmark latency (< 2s target)
   - Test free tier limits (100 requests/day)
   - Document fallback when barcode not found

2. **SerpAPI Google Lens Integration**:
   - Verify GCS public URL requirements (SerpAPI needs HTTPS URLs)
   - Test visual_matches response parsing
   - Measure product match accuracy (does SerpAPI find correct products?)
   - Benchmark latency (5-7s target)
   - Verify cost ($0.05 per search, barcode-optimized = $0.025 blended)

3. **Claude Haiku 4.5 Brand/Model Parsing**:
   - Test brand/model/variant extraction from SerpAPI HTML
   - Design parsing prompts (extract brand, model, variant from messy data)
   - Measure parsing accuracy (> 85% target)
   - Benchmark latency (< 1s target)
   - Verify cost ($0.25/$1.25 per million tokens)

4. **Dual-Mode Strategy Validation**:
   - Test barcode-first flow (barcode exists → UPCitemdb, skip SerpAPI)
   - Test visual-fallback flow (no barcode → SerpAPI + Claude Haiku)
   - Measure barcode hit rate (50% assumption from Stage 2.0)
   - Validate cost savings (50% hit rate = 50% cost reduction)

5. **Error Handling**:
   - Test SerpAPI rate limits (5K searches/month free tier)
   - Test UPCitemdb failures (barcode not found)
   - Document retry logic and fallback strategies

**Outputs**:

- **RESEARCH-005: Layer 2b Product Search Patterns** (SerpAPI integration, UPCitemdb lookup, Claude Haiku parsing, dual-mode strategy)
- **PROMPT-TEMPLATES-002: Layer 2b Parsing Prompts** (Claude Haiku brand/model extraction)
- **BENCHMARK-003: Layer 2b Accuracy & Performance** (barcode coverage, SerpAPI match rate, parsing accuracy, latency, cost validation)
- **PLAN-SUMMARY-stage-3.5.md**
- **CHECKPOINT-stage-3.5-2025-11-10.md**

**Checkpoint Questions**:

- Does UPCitemdb cover > 70% of common barcodes?
- Does SerpAPI achieve > 75% product match accuracy?
- Does Claude Haiku achieve > 85% brand/model parsing accuracy?
- Is the dual-mode strategy cost-effective (barcode-first reduces costs)?
- Are fallback strategies comprehensive (barcode fails → SerpAPI, SerpAPI fails → skip Layer 2b)?

---

### Stage 3.6: Layer 3 AI Synthesis Implementation Research

**Expert Agent**: Computer Vision & ML Engineer

**Purpose**: Research and validate Layer 3 (Claude Sonnet 4.5 Batch API) implementation patterns for multi-source synthesis, conflict resolution, confidence scoring, and final metadata generation.

**Input Documents**:
- docs/plans/PLAN-SUMMARY-stage-2.4.md (Layer 3 architecture design)
- docs/design/DESIGN-020-ai-synthesis-architecture.md (complete synthesis spec)
- docs/adr/ADR-015-ai-reasoning-layer-architecture.md (Claude Sonnet selection)
- docs/validation/STAGE-2.4-REVIEW-layer-3-completeness.md (Layer 3 completeness)

**Research Tasks**:

1. **Claude Sonnet 4.5 Batch API Integration**:
   - Test Batch API usage (@anthropic-ai/sdk)
   - Verify 50% cost discount ($0.75/$3.75 per million tokens)
   - Measure actual latency (1-2s target for async processing)
   - Document batch queuing behavior (24-hour max processing delay)

2. **Conflict Resolution Accuracy**:
   - Test color conflict resolution (vision vs product search)
   - Test category conflict resolution (vision vs product search)
   - Test brand/model conflicts (barcode vs visual search)
   - Measure conflict resolution accuracy (> 85% target)
   - Validate conflict resolution logic from DESIGN-020

3. **Confidence Scoring Validation**:
   - Test confidence algorithm (vision confidence + product source + conflict count)
   - Measure correlation (predicted confidence vs actual accuracy)
   - Benchmark confidence thresholds (high ≥ 0.8, medium 0.5-0.8, low < 0.5)
   - Validate scoring factors from DESIGN-020 lines 370-414

4. **Multi-Source Synthesis Accuracy**:
   - Test synthesis with Layer 2a only (no product search)
   - Test synthesis with Layer 2a + barcode (UPCitemdb)
   - Test synthesis with Layer 2a + SerpAPI (visual search)
   - Test synthesis with all layers (Layer 2a + 2b barcode + 2b SerpAPI)
   - Measure final metadata accuracy against human labels

5. **Prompt Engineering**:
   - Test synthesis prompt variations (from DESIGN-020 lines 234-290)
   - Optimize prompt for conflict resolution clarity
   - Test structured output compliance (JSON schema)
   - Document best practices for multi-source prompts

6. **Value Estimation Validation**:
   - Test condition multipliers (new=1.0, like-new=0.85, good=0.70, fair=0.50, poor=0.30)
   - Measure value estimation accuracy (within 20% of actual value?)
   - Test category-based estimation when no product data available
   - Validate value estimation logic from DESIGN-020 lines 427-481

**Outputs**:

- **RESEARCH-006: Layer 3 AI Synthesis Patterns** (Claude Sonnet integration, conflict resolution, confidence scoring, value estimation)
- **PROMPT-TEMPLATES-003: Layer 3 Synthesis Prompts** (optimized multi-source synthesis prompts)
- **BENCHMARK-004: Layer 3 Accuracy & Performance** (conflict resolution accuracy, confidence correlation, synthesis accuracy, latency, cost validation)
- **PLAN-SUMMARY-stage-3.6.md**
- **CHECKPOINT-stage-3.6-2025-11-10.md**

**Checkpoint Questions**:

- Does Claude Sonnet achieve > 85% conflict resolution accuracy?
- Does confidence scoring correlate with actual metadata accuracy?
- Is multi-source synthesis accurate (> 80% final metadata accuracy)?
- Is Batch API cost acceptable ($0.002027 per synthesis)?
- Are value estimates reasonable (within 20% of actual value)?

---
```

**Step 2: Update Phase 3 overview section**

Find Phase 3 header (line 1188) and update description:

```markdown
## PHASE 3: Deep Technical Research

**Purpose**: Layer-by-layer implementation research for the 4-layer AI cataloging pipeline. Validate assumptions made in Stage 2.0 (research) and Stage 2.4 (architecture), benchmark accuracy, optimize prompts, and create reference implementations for already-chosen AI providers.

**Key Principle**: Phase 3 is NOT about comparing alternative AI providers (already decided in Stage 2.0). Phase 3 is about validating, benchmarking, and optimizing the IMPLEMENTATION of already-chosen providers (Gemini 2.5 Flash-Lite, SerpAPI, UPCitemdb, Claude Haiku, Claude Sonnet).

**Context Map**: Each stage in Phase 3 requires outputs from Phase 2. Consult `docs/context-map.json` for exact file dependencies before starting any research stage.

**Layer-to-Stage Mapping**:
- **Stage 3.1**: iOS client patterns (already complete)
- **Stage 3.2**: Backend infrastructure patterns (already complete)
- **Stage 3.3**: Layer 1 on-device ML (YOLO, barcode, Vision Framework)
- **Stage 3.4**: Layer 2a attribute extraction (Gemini 2.5 Flash-Lite)
- **Stage 3.5**: Layer 2b product search (SerpAPI + UPCitemdb + Claude Haiku)
- **Stage 3.6**: Layer 3 AI synthesis (Claude Sonnet 4.5)

---
```

**Step 3: Commit master pipeline update**

```bash
git add docs/abundance-analysis-pipeline-design.md
git commit -m "docs: restructure Phase 3 with layer-focused implementation research (3.3-3.6)

Replace ambiguous Stage 3.3 'AI Provider Deep Dive' with 4 layer-specific stages:
- Stage 3.3: Layer 1 On-Device ML (YOLO + barcode)
- Stage 3.4: Layer 2a Attribute Extraction (Gemini 2.5 Flash-Lite)
- Stage 3.5: Layer 2b Product Search (SerpAPI + UPCitemdb + Claude Haiku)
- Stage 3.6: Layer 3 AI Synthesis (Claude Sonnet 4.5)

Clarify Phase 3 purpose: implementation research for already-chosen providers,
NOT comparing alternatives (done in Stage 2.0).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Update context-map.json

**Files:**
- Modify: `docs/context-map.json:357-404` (stage-3.3 section + add 3.4-3.6)

**Step 1: Update stage-3.3 definition**

Old stage-3.3 (lines 381-404):
```json
"stage-3.3": {
  "name": "AI Provider Deep Dive",
  "expert_agent": "Computer Vision & ML",
  "status": "pending",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_2.4": [
      "docs/design/DESIGN-004-computer-vision-pipeline.md",
      "docs/design/AI-INTEGRATION-LAYER-001-hot-swappable-design.md"
    ],
    "from_stage_2.4_adrs": [
      "docs/adr/ADR-014-cloud-ai-provider-selection.md",
      "docs/adr/ADR-015-ai-reasoning-layer-architecture.md"
    ]
  },
  "expected_outputs": [
    "docs/plans/PLAN-SUMMARY-stage-3.3.md",
    "docs/research/RESEARCH-003-ai-provider-comparison.md",
    "docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md",
    "docs/research/PROOF-OF-CONCEPT-001-ai-provider-benchmarks.md",
    "docs/research/PROMPT-TEMPLATES-001-ai-prompt-engineering.md",
    "docs/checkpoints/CHECKPOINT-stage-3.3.md"
  ]
}
```

New stage-3.3 through 3.6:
```json
"stage-3.3": {
  "name": "Layer 1 On-Device ML Implementation Research",
  "expert_agent": "iOS Architecture Expert + Computer Vision & ML Engineer",
  "status": "pending",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_3.1": [
      "docs/plans/PLAN-SUMMARY-stage-3.1.md"
    ],
    "from_stage_2.4": [
      "docs/plans/PLAN-SUMMARY-stage-2.4.md",
      "docs/design/DESIGN-013-vision-framework-integration-patterns.md",
      "docs/design/DESIGN-014-barcode-detection-implementation.md"
    ],
    "from_stage_2.0": [
      "docs/adr/ADR-013-vision-framework-strategy.md"
    ],
    "apple_docs": "docs/apple/"
  },
  "expected_outputs": [
    "docs/plans/PLAN-SUMMARY-stage-3.3.md",
    "docs/research/RESEARCH-003-layer-1-on-device-ml-patterns.md",
    "docs/research/BENCHMARK-001-layer-1-accuracy-performance.md",
    "docs/research/CODE-EXAMPLES-003-vision-framework-reference.md",
    "docs/checkpoints/CHECKPOINT-stage-3.3-2025-11-10.md"
  ]
},

"stage-3.4": {
  "name": "Layer 2a Attribute Extraction Implementation Research",
  "expert_agent": "Computer Vision & ML Engineer",
  "status": "pending",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_3.2": [
      "docs/plans/PLAN-SUMMARY-stage-3.2.md"
    ],
    "from_stage_2.4": [
      "docs/plans/PLAN-SUMMARY-stage-2.4.md",
      "docs/design/DESIGN-017-vertex-ai-integration-patterns.md"
    ],
    "from_stage_2.0": [
      "docs/adr/ADR-014-cloud-ai-provider-selection.md",
      "docs/validation/RESEARCH-VALIDATION-stage-2.0.md"
    ]
  },
  "expected_outputs": [
    "docs/plans/PLAN-SUMMARY-stage-3.4.md",
    "docs/research/RESEARCH-004-layer-2a-attribute-extraction-patterns.md",
    "docs/research/PROMPT-TEMPLATES-001-layer-2a-attribute-prompts.md",
    "docs/research/BENCHMARK-002-layer-2a-accuracy-performance.md",
    "docs/checkpoints/CHECKPOINT-stage-3.4-2025-11-10.md"
  ]
},

"stage-3.5": {
  "name": "Layer 2b Product Search Implementation Research",
  "expert_agent": "Cloud Backend Architect + Computer Vision & ML Engineer",
  "status": "pending",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_3.2": [
      "docs/plans/PLAN-SUMMARY-stage-3.2.md"
    ],
    "from_stage_2.4": [
      "docs/plans/PLAN-SUMMARY-stage-2.4.md",
      "docs/design/DESIGN-018-llm-parsing-implementation.md",
      "docs/design/DESIGN-019-barcode-api-integration.md",
      "docs/design/SERPAPI-INTEGRATION-001-swift-rest-api-patterns.md"
    ],
    "from_stage_2.0": [
      "docs/adr/ADR-018-barcode-product-lookup-strategy.md"
    ]
  },
  "expected_outputs": [
    "docs/plans/PLAN-SUMMARY-stage-3.5.md",
    "docs/research/RESEARCH-005-layer-2b-product-search-patterns.md",
    "docs/research/PROMPT-TEMPLATES-002-layer-2b-parsing-prompts.md",
    "docs/research/BENCHMARK-003-layer-2b-accuracy-performance.md",
    "docs/checkpoints/CHECKPOINT-stage-3.5-2025-11-10.md"
  ]
},

"stage-3.6": {
  "name": "Layer 3 AI Synthesis Implementation Research",
  "expert_agent": "Computer Vision & ML Engineer",
  "status": "pending",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_2.4": [
      "docs/plans/PLAN-SUMMARY-stage-2.4.md",
      "docs/design/DESIGN-020-ai-synthesis-architecture.md"
    ],
    "from_stage_2.0": [
      "docs/adr/ADR-015-ai-reasoning-layer-architecture.md"
    ],
    "validation": [
      "docs/validation/STAGE-2.4-REVIEW-layer-3-completeness.md"
    ]
  },
  "expected_outputs": [
    "docs/plans/PLAN-SUMMARY-stage-3.6.md",
    "docs/research/RESEARCH-006-layer-3-ai-synthesis-patterns.md",
    "docs/research/PROMPT-TEMPLATES-003-layer-3-synthesis-prompts.md",
    "docs/research/BENCHMARK-004-layer-3-accuracy-performance.md",
    "docs/checkpoints/CHECKPOINT-stage-3.6-2025-11-10.md"
  ]
},
```

**Step 2: Update stage-4.3 dependencies**

Stage 4.3 (AI/ML Integration Specification) should now depend on stages 3.3-3.6 instead of just 3.3:

Find stage-4.3 (line 461) and update `from_stage_3.3` to include all new research:

```json
"stage-4.3": {
  "name": "AI/ML Integration Specification",
  "expert_agent": "Computer Vision & ML",
  "status": "pending",
  "required_inputs": {
    "common": ["docs/abundance-analysis-pipeline-design.md"],
    "from_stage_3.3": [
      "docs/plans/PLAN-SUMMARY-stage-3.3.md",
      "docs/research/RESEARCH-003-layer-1-on-device-ml-patterns.md",
      "docs/research/BENCHMARK-001-layer-1-accuracy-performance.md"
    ],
    "from_stage_3.4": [
      "docs/plans/PLAN-SUMMARY-stage-3.4.md",
      "docs/research/RESEARCH-004-layer-2a-attribute-extraction-patterns.md",
      "docs/research/BENCHMARK-002-layer-2a-accuracy-performance.md"
    ],
    "from_stage_3.5": [
      "docs/plans/PLAN-SUMMARY-stage-3.5.md",
      "docs/research/RESEARCH-005-layer-2b-product-search-patterns.md",
      "docs/research/BENCHMARK-003-layer-2b-accuracy-performance.md"
    ],
    "from_stage_3.6": [
      "docs/plans/PLAN-SUMMARY-stage-3.6.md",
      "docs/research/RESEARCH-006-layer-3-ai-synthesis-patterns.md",
      "docs/research/BENCHMARK-004-layer-3-accuracy-performance.md"
    ],
    "from_stage_2.0": [
      "docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md"
    ],
    "all_cv_artifacts": [
      "docs/design/DESIGN-004-computer-vision-pipeline.md",
      "docs/adr/ADR-014-*.md",
      "docs/adr/ADR-015-*.md"
    ]
  },
  "expected_outputs": [
    "docs/plans/PLAN-SUMMARY-stage-4.3.md",
    "docs/tech-stack/TECH-STACK-004-ai-provider-integration.md",
    "docs/adr/ADR-0XX-primary-ai-provider.md",
    "docs/adr/ADR-0XX-fallback-strategy.md",
    "docs/design/API-WRAPPER-001-hot-swappable-ai-code.md",
    "docs/checkpoints/CHECKPOINT-stage-4.3.md"
  ]
}
```

**Step 3: Commit context-map update**

```bash
git add docs/context-map.json
git commit -m "feat: expand Phase 3 to 6 stages with layer-focused research (3.3-3.6)

Split ambiguous Stage 3.3 into 4 layer-specific implementation research stages:
- Stage 3.3: Layer 1 On-Device ML (YOLO, barcode, Vision Framework)
- Stage 3.4: Layer 2a Attribute Extraction (Gemini 2.5 Flash-Lite)
- Stage 3.5: Layer 2b Product Search (SerpAPI, UPCitemdb, Claude Haiku)
- Stage 3.6: Layer 3 AI Synthesis (Claude Sonnet 4.5)

Update Stage 4.3 dependencies to require all new Phase 3 research outputs.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Create Stage 3.3-3.6 Plan Summaries

**Files:**
- Create: `docs/plans/PLAN-SUMMARY-stage-3.3.md`
- Create: `docs/plans/PLAN-SUMMARY-stage-3.4.md`
- Create: `docs/plans/PLAN-SUMMARY-stage-3.5.md`
- Create: `docs/plans/PLAN-SUMMARY-stage-3.6.md`

**Step 1: Create PLAN-SUMMARY-stage-3.3.md**

```markdown
# PLAN SUMMARY: Stage 3.3 - Layer 1 On-Device ML Implementation Research

**Created**: 2025-11-10
**Stage**: 3.3 - Layer 1 On-Device ML Implementation Research
**Status**: Plan Complete - Ready for Execution ✅
**Expert Agent**: iOS Architecture Expert + Computer Vision & ML Engineer

---

## What This Stage Accomplishes

Stage 3.3 validates Layer 1 (on-device) implementation assumptions from Stage 2.4 through hands-on research, benchmarking, and accuracy testing. This stage focuses on YOLO object detection, barcode scanning, and Vision Framework integration patterns for iOS 26.

**Key Accomplishments**:
1. ✅ YOLO model integration validated (download source, VNCoreMLRequest patterns)
2. ✅ Barcode detection accuracy benchmarked (UPC-A, EAN-13, QR codes)
3. ✅ Bounding box cropping accuracy tested (object capture completeness)
4. ✅ Apple Neural Engine optimization validated (latency < 500ms target)
5. ✅ Privacy firewall verified (full photos never leave device)

**Ready for Stage 3.4**: Layer 2a attribute extraction research can proceed with validated Layer 1 object detection patterns.

---

## Research Focus

**NOT comparing alternatives** (Vision Framework already chosen in Stage 2.0)
**YES validating implementation** (does YOLO work as expected? Is accuracy acceptable?)

---

## Expected Artifacts (5)

1. **RESEARCH-003**: Layer 1 On-Device ML Implementation Patterns
2. **BENCHMARK-001**: Layer 1 Accuracy & Performance
3. **CODE-EXAMPLES-003**: Vision Framework Reference Implementations
4. **PLAN-SUMMARY-stage-3.3.md** (this document)
5. **CHECKPOINT-stage-3.3-2025-11-10.md**

---

## Success Criteria

- ✅ YOLO accuracy > 70% on household items (camping, electronics, furniture)
- ✅ Barcode detection > 90% accuracy on UPC-A/EAN-13
- ✅ Latency < 500ms on iPhone 15 Pro
- ✅ Privacy guarantees validated (full photos deleted after cropping)
- ✅ Reference Swift code examples created
```

**Step 2: Create PLAN-SUMMARY-stage-3.4.md**

```markdown
# PLAN SUMMARY: Stage 3.4 - Layer 2a Attribute Extraction Implementation Research

**Created**: 2025-11-10
**Stage**: 3.4 - Layer 2a Attribute Extraction Implementation Research
**Status**: Plan Complete - Ready for Execution ✅
**Expert Agent**: Computer Vision & ML Engineer

---

## What This Stage Accomplishes

Stage 3.4 validates Layer 2a (Gemini 2.5 Flash-Lite) implementation assumptions from Stage 2.4 through prompt engineering, accuracy benchmarking, and cost validation. This stage focuses on attribute extraction (category, color, material, condition) using Vertex AI JSON Schema Mode.

**Key Accomplishments**:
1. ✅ Gemini JSON Schema Mode validated (structured output compliance)
2. ✅ Attribute extraction accuracy benchmarked (category, color, material, condition)
3. ✅ Prompt engineering optimized (concise vs verbose, JSON instructions)
4. ✅ Cost & latency validated ($0.000249/image, 30-50ms)
5. ✅ Error handling tested (rate limits, retry logic)

**Ready for Stage 3.5**: Layer 2b product search research can proceed with validated Layer 2a attribute patterns.

---

## Research Focus

**NOT comparing alternatives** (Gemini 2.5 Flash-Lite already chosen in Stage 2.0)
**YES validating implementation** (is JSON Schema Mode reliable? Is accuracy acceptable?)

---

## Expected Artifacts (5)

1. **RESEARCH-004**: Layer 2a Attribute Extraction Patterns
2. **PROMPT-TEMPLATES-001**: Layer 2a Attribute Prompts
3. **BENCHMARK-002**: Layer 2a Accuracy & Performance
4. **PLAN-SUMMARY-stage-3.4.md** (this document)
5. **CHECKPOINT-stage-3.4-2025-11-10.md**

---

## Success Criteria

- ✅ Category detection > 80% accuracy
- ✅ Color/material/condition > 75% accuracy
- ✅ JSON Schema Mode > 95% valid JSON compliance
- ✅ Latency < 100ms (p95)
- ✅ Cost validated ($0.000249 per image)
```

**Step 3: Create PLAN-SUMMARY-stage-3.5.md**

```markdown
# PLAN SUMMARY: Stage 3.5 - Layer 2b Product Search Implementation Research

**Created**: 2025-11-10
**Stage**: 3.5 - Layer 2b Product Search Implementation Research
**Status**: Plan Complete - Ready for Execution ✅
**Expert Agent**: Cloud Backend Architect + Computer Vision & ML Engineer

---

## What This Stage Accomplishes

Stage 3.5 validates Layer 2b (SerpAPI + UPCitemdb + Claude Haiku) implementation assumptions from Stage 2.4 through integration testing, coverage benchmarking, and cost validation. This stage focuses on product search, barcode lookup, and brand/model parsing.

**Key Accomplishments**:
1. ✅ UPCitemdb barcode coverage benchmarked (% of UPC-A/EAN-13 found)
2. ✅ SerpAPI Google Lens integration validated (visual_matches parsing)
3. ✅ Claude Haiku brand/model parsing tested (extraction accuracy)
4. ✅ Dual-mode strategy validated (barcode-first cost savings)
5. ✅ Fallback strategies tested (barcode fails → SerpAPI, SerpAPI fails → skip Layer 2b)

**Ready for Stage 3.6**: Layer 3 synthesis research can proceed with validated Layer 2b product data patterns.

---

## Research Focus

**NOT comparing alternatives** (SerpAPI + UPCitemdb + Claude Haiku already chosen in Stage 2.0)
**YES validating implementation** (is barcode coverage acceptable? Is SerpAPI accurate?)

---

## Expected Artifacts (5)

1. **RESEARCH-005**: Layer 2b Product Search Patterns
2. **PROMPT-TEMPLATES-002**: Layer 2b Parsing Prompts
3. **BENCHMARK-003**: Layer 2b Accuracy & Performance
4. **PLAN-SUMMARY-stage-3.5.md** (this document)
5. **CHECKPOINT-stage-3.5-2025-11-10.md**

---

## Success Criteria

- ✅ UPCitemdb coverage > 70% of common barcodes
- ✅ SerpAPI product match > 75% accuracy
- ✅ Claude Haiku parsing > 85% brand/model accuracy
- ✅ Dual-mode strategy cost-effective (barcode-first reduces costs by 50%)
- ✅ Fallback strategies comprehensive (all failure modes handled)
```

**Step 4: Create PLAN-SUMMARY-stage-3.6.md**

```markdown
# PLAN SUMMARY: Stage 3.6 - Layer 3 AI Synthesis Implementation Research

**Created**: 2025-11-10
**Stage**: 3.6 - Layer 3 AI Synthesis Implementation Research
**Status**: Plan Complete - Ready for Execution ✅
**Expert Agent**: Computer Vision & ML Engineer

---

## What This Stage Accomplishes

Stage 3.6 validates Layer 3 (Claude Sonnet 4.5 Batch API) implementation assumptions from Stage 2.4 (DESIGN-020) through conflict resolution testing, confidence scoring validation, and multi-source synthesis benchmarking.

**Key Accomplishments**:
1. ✅ Claude Sonnet Batch API integration validated (50% cost discount)
2. ✅ Conflict resolution accuracy tested (color, category, brand/model conflicts)
3. ✅ Confidence scoring algorithm validated (correlation with actual accuracy)
4. ✅ Multi-source synthesis tested (Layer 2a + 2b → final metadata)
5. ✅ Value estimation validated (condition multipliers, category-based fallback)
6. ✅ Prompt engineering optimized (synthesis clarity, structured output)

**Ready for Stage 4.3**: AI/ML integration specification can finalize hot-swappable AI layer with validated Layer 3 patterns.

---

## Research Focus

**NOT comparing alternatives** (Claude Sonnet 4.5 already chosen in Stage 2.0/ADR-015)
**YES validating implementation** (does conflict resolution work? Is confidence scoring accurate?)

---

## Expected Artifacts (5)

1. **RESEARCH-006**: Layer 3 AI Synthesis Patterns
2. **PROMPT-TEMPLATES-003**: Layer 3 Synthesis Prompts
3. **BENCHMARK-004**: Layer 3 Accuracy & Performance
4. **PLAN-SUMMARY-stage-3.6.md** (this document)
5. **CHECKPOINT-stage-3.6-2025-11-10.md**

---

## Success Criteria

- ✅ Conflict resolution > 85% accuracy
- ✅ Confidence scoring correlates with actual metadata accuracy
- ✅ Multi-source synthesis > 80% final metadata accuracy
- ✅ Batch API cost validated ($0.002027 per synthesis)
- ✅ Value estimation within 20% of actual value
```

**Step 5: Commit plan summaries**

```bash
git add docs/plans/PLAN-SUMMARY-stage-3.3.md docs/plans/PLAN-SUMMARY-stage-3.4.md docs/plans/PLAN-SUMMARY-stage-3.5.md docs/plans/PLAN-SUMMARY-stage-3.6.md
git commit -m "docs: create plan summaries for restructured Phase 3 stages (3.3-3.6)

Add plan summaries for layer-focused implementation research:
- Stage 3.3: Layer 1 On-Device ML (YOLO + barcode)
- Stage 3.4: Layer 2a Attribute Extraction (Gemini 2.5 Flash-Lite)
- Stage 3.5: Layer 2b Product Search (SerpAPI + UPCitemdb + Claude Haiku)
- Stage 3.6: Layer 3 AI Synthesis (Claude Sonnet 4.5)

Each stage focuses on validating implementation assumptions from Stage 2.4,
NOT comparing alternative providers.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: Update Phase 4 and Phase 5 Stage Dependencies

**Files:**
- Modify: `docs/abundance-analysis-pipeline-design.md:1324-1555` (Phase 4 & 5 sections)

**Step 1: Update Stage 5.1 dependencies**

Stage 5.1 (Phased Roadmap Creation) should now reference all Phase 3 plan summaries (3.1-3.6):

Find Stage 5.1 `all_plan_summaries` section (line 499-511 in context-map.json) and ensure it includes:

```json
"all_plan_summaries": [
  "docs/plans/PLAN-SUMMARY-stage-2.1.md",
  "docs/plans/PLAN-SUMMARY-stage-2.2.md",
  "docs/plans/PLAN-SUMMARY-stage-2.3.md",
  "docs/plans/PLAN-SUMMARY-stage-2.4.md",
  "docs/plans/PLAN-SUMMARY-stage-2.5.md",
  "docs/plans/PLAN-SUMMARY-stage-3.1.md",
  "docs/plans/PLAN-SUMMARY-stage-3.2.md",
  "docs/plans/PLAN-SUMMARY-stage-3.3.md",
  "docs/plans/PLAN-SUMMARY-stage-3.4.md",
  "docs/plans/PLAN-SUMMARY-stage-3.5.md",
  "docs/plans/PLAN-SUMMARY-stage-3.6.md",
  "docs/plans/PLAN-SUMMARY-stage-4.1.md",
  "docs/plans/PLAN-SUMMARY-stage-4.2.md",
  "docs/plans/PLAN-SUMMARY-stage-4.3.md"
]
```

**Step 2: Commit Phase 4/5 dependency updates**

```bash
git add docs/context-map.json
git commit -m "fix: update Stage 5.1 dependencies to include new Phase 3 stages (3.3-3.6)

Stage 5.1 (Phased Roadmap Creation) now loads all 6 Phase 3 plan summaries
(3.1-3.6) instead of 3.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: Create Final Implementation Plan Summary

**Files:**
- Create: `docs/plans/2025-11-10-phase-3-restructure-summary.md`

**Step 1: Document restructure summary**

```markdown
# Phase 3 Restructure Summary

**Date**: 2025-11-10
**Purpose**: Document the Phase 3 restructure from 3 ambiguous stages to 6 layer-focused implementation research stages

---

## Problem Identified

**Original Phase 3** had ambiguous scope:
- Stage 3.3 "AI Provider Deep Dive" mixed architecture decisions (already made in Stage 2.0) with implementation research
- No clear separation between Layer 1, 2a, 2b, 3 research
- Unclear if comparing ALTERNATIVES (Gemini vs Claude) or validating IMPLEMENTATION (Gemini usage patterns)

**Root cause**: Phase 3 specification predated the 4-layer pipeline design (Stage 2.4 created layers, but Phase 3 wasn't updated)

---

## Solution: Layer-Focused Restructure

**New Phase 3 structure** (6 stages):

| Stage | Layer Focus | Purpose |
|-------|-------------|---------|
| 3.1 | iOS Client | Swift 6, Firebase SDK, SwiftUI (KEEP - already complete) |
| 3.2 | Backend | Cloud Functions, Firestore, Firebase Storage (KEEP - already complete) |
| 3.3 | **Layer 1** | YOLO + barcode + Vision Framework implementation |
| 3.4 | **Layer 2a** | Gemini 2.5 Flash-Lite attribute extraction |
| 3.5 | **Layer 2b** | SerpAPI + UPCitemdb + Claude Haiku product search |
| 3.6 | **Layer 3** | Claude Sonnet 4.5 synthesis |

**Key principle**: Phase 3 validates IMPLEMENTATION of already-chosen providers (from Stage 2.0), NOT comparing alternatives.

---

## Stage 2.4 Completeness Assessment

**Question**: Does Stage 2.4 need re-execution to specify Layer 3 synthesis?

**Answer**: ✅ NO - Stage 2.4 comprehensively specified Layer 3:

- **ADR-015**: Claude Sonnet 4.5 selection rationale, conflict resolution capabilities, cost model
- **DESIGN-020** (785 lines): Complete synthesis spec with algorithms, code examples, testing

**Validation**: docs/validation/STAGE-2.4-REVIEW-layer-3-completeness.md

---

## Documents Updated

1. **docs/abundance-analysis-pipeline-design.md**:
   - Replaced Stage 3.3 (lines 1279-1321) with 4 new stages (3.3-3.6)
   - Updated Phase 3 overview (line 1188) to clarify layer-focused research purpose

2. **docs/context-map.json**:
   - Replaced stage-3.3 definition (lines 381-404) with 4 new stage definitions (3.3-3.6)
   - Updated stage-4.3 dependencies to include all new Phase 3 research outputs
   - Updated stage-5.1 dependencies to include all 6 Phase 3 plan summaries

3. **docs/plans/PLAN-SUMMARY-stage-3.3.md** (new)
4. **docs/plans/PLAN-SUMMARY-stage-3.4.md** (new)
5. **docs/plans/PLAN-SUMMARY-stage-3.5.md** (new)
6. **docs/plans/PLAN-SUMMARY-stage-3.6.md** (new)
7. **docs/validation/STAGE-2.4-REVIEW-layer-3-completeness.md** (new)

---

## Next Steps

**Before executing any Phase 3 stage**:
1. ✅ Read updated `docs/context-map.json` to identify required inputs
2. ✅ Verify previous stage status (3.1 and 3.2 already complete)
3. ✅ Load all required input documents from Stage 2.4, Stage 2.0
4. ✅ Execute stage using `verified-stage-development` skill

**Execution order**:
- Stage 3.3 (Layer 1) can start immediately (depends on 3.1, 3.2, 2.4)
- Stage 3.4 (Layer 2a) depends on 3.2, 2.4
- Stage 3.5 (Layer 2b) depends on 3.2, 2.4
- Stage 3.6 (Layer 3) depends on 2.4, validation doc

Stages 3.3-3.6 can run in parallel (no sequential dependencies between them).

---

**Status**: ✅ Phase 3 restructure complete - ready for stage execution
```

**Step 2: Commit restructure summary**

```bash
git add docs/plans/2025-11-10-phase-3-restructure-summary.md
git commit -m "docs: add Phase 3 restructure summary

Document the transformation from 3 ambiguous stages to 6 layer-focused
implementation research stages, including problem analysis, solution approach,
and Stage 2.4 completeness validation.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Summary

**Plan complete and saved to `docs/plans/2025-11-10-phase-3-restructure-layer-focused-research.md`.**

### What Was Accomplished

1. ✅ **Identified UI/UX gap** - No stage for Liquid Glass design system, screen designs, navigation flows
2. ✅ **Added Stage 2.6** - iOS UI/UX Design & Liquid Glass Integration (addresses critical gap)
3. ✅ **Validated Stage 2.4 completeness** - Layer 3 fully specified (ADR-015 + DESIGN-020), no re-execution needed
4. ✅ **Restructured Phase 3** - Expanded from 3 ambiguous stages to 6 layer-focused implementation research stages
5. ✅ **Updated master pipeline** - Added Stage 2.6, clarified Phase 3 purpose, added stages 3.3-3.6
6. ✅ **Updated context map** - Added Stage 2.6 + all new Phase 3 stage definitions, updated dependencies
7. ✅ **Created plan summaries** - 4 new PLAN-SUMMARY documents for stages 3.3-3.6
8. ✅ **Documented restructure** - Created validation report and summary

### Key Decisions

- **Added Stage 2.6 (UI/UX Design)** - Critical gap filled, Liquid Glass design system integration
- **Stage 2.6 must complete BEFORE Stage 3.1** - UI design informs iOS implementation research
- **Stage 2.4 does NOT need re-execution** - Layer 3 synthesis comprehensively specified
- **Phase 3 focuses on IMPLEMENTATION research** - Not comparing alternatives (done in Stage 2.0)
- **Layer-to-stage mapping** - Clear 1:1 mapping between 4 pipeline layers and Phase 3 stages

### Execution Order

**Phase 2 completion required first**:
1. **Execute Stage 2.6** (iOS UI/UX Design & Liquid Glass Integration) - **MUST COMPLETE FIRST**
2. Then execute Phase 3 stages (3.3-3.6) - depends on Stage 2.6 outputs

**Note**: Stage 3.1 (iOS Implementation Research) was marked "completed" in context-map.json but did NOT have Stage 2.6 outputs. Stage 3.1 may need re-review after Stage 2.6 completes to incorporate UI/UX design patterns.

---

**Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per stage, review between stages, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**