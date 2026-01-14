# Abundance App Analysis Pipeline: Complete Design Specification

**Created**: 2025-10-22
**Last Updated**: 2025-11-15 (Layer 1 Real-Time Detection Architecture Refactor)
**Status**: Active - Phases 1-3 as designed, Phases 4-6 refactored (see below)
**Purpose**: Transform Abundance vision document into implementation-ready spec-kit through multi-stage expert analysis

> **IMPORTANT**: Phases 4-6 have been refactored on 2025-11-11 to eliminate redundancy discovered after completing Stages 1.1-3.4. Original tech stack decisions were made in Stage 2.1, making original Stages 4.1-4.3 redundant. See `docs/PIPELINE-REFACTOR-2025-11-11.md` for detailed analysis of changes.

---

## Table of Contents

1. [Overview](#overview)
2. [Expert Agent Specifications](#expert-agent-specifications)
3. [Complete Pipeline Architecture](#complete-pipeline-architecture)
4. [Context Map Usage](#context-map-usage)
5. [Phase 1: Vision & Strategy Validation](#phase-1-vision--strategy-validation)
6. [Phase 2: Technical Architecture](#phase-2-technical-architecture)
7. [Phase 3: Deep Technical Research](#phase-3-deep-technical-research)
8. [Phase 4: Technology Stack Finalization](#phase-4-technology-stack-finalization)
9. [Phase 5: Implementation Planning](#phase-5-implementation-planning)
10. [Phase 6: Validation & Finalization](#phase-6-validation--finalization)
11. [Checkpoint Format](#checkpoint-format)
12. [Artifact Naming Conventions](#artifact-naming-conventions)
13. [Next Steps](#next-steps)

---

## Overview

### Purpose

This pipeline transforms the high-level Abundance App Interpretation Report into a comprehensive, implementation-ready specification kit through sequential expert analysis. Each stage builds upon validated outputs from previous stages, with human checkpoints ensuring strategic alignment.

### Context Map (Critical)

**File**: `docs/context-map.json`

The context map is the **canonical source of truth** for stage dependencies, required inputs, and expected outputs. Before executing any stage, agents MUST read this file to:

- Identify which documents are required as inputs for the current stage
- Verify that all prerequisite stages are complete
- Understand what artifacts should be produced
- Determine if Apple documentation (docs/apple/) is required

**Why this matters**: The context map ensures deterministic, consistent stage execution by eliminating ambiguity about which documents to load. All agents and sub-agents must use this file to determine context requirements.

**Location**: All stage input/output mappings are maintained in `docs/context-map.json`. See the Context Map Usage section below for details.

### Design Principles

1. **Sequential over Parallel**: Each stage completes before the next begins to ensure complete context
2. **Tech Stack Foundation First**: Stage 2.1 locks all technology choices before domain experts begin detailed design
3. **Expert Agent Specialization**: Each stage is executed by specialized expert agents with defined knowledge domains
4. **Research-Driven**: Agents research authoritative sources (Apple docs, GCP docs, frameworks) to ground decisions
5. **Human-in-the-Loop**: Critical decisions require human approval before proceeding
6. **Spec-Driven Output**: Generate formal artifacts (PRD, DESIGN, ADR, TEST) not just analysis
7. **Living Documentation**: Specs evolve based on agent findings and iterative refinement
8. **Context Map Driven**: All stage dependencies and artifacts tracked in context-map.json for deterministic execution

### End State Artifacts

After completing all 6 phases, you will have:

- ✅ **Validated/Corrected Abundance Document**
- ✅ **Complete Spec-Kit** (PRD, DESIGN, ADR, TEST documents)
- ✅ **Phased Implementation Plan** with agent-ready prompts
- ✅ **Technology Stack Fully Specified** (versions, configurations, dependencies)
- ✅ **60+ Formal Artifacts** ready for agentic development

---

## Expert Agent Specifications

### Detailed Specifications by Domain

#### 1. Business Strategy Analyst

**Expertise**:

- Business model analysis (advertising, subscription, aggregation)
- Competitive dynamics and strategic positioning
- Platform economics and network effects
- Disruption theory (Christensen framework)
- Value chain analysis

**Frameworks Applied**:

- Aggregation Theory (original framework)
- Christensen disruption patterns
- Porter's Five Forces
- Value chain control
- Incentive analysis

**Analyzes Abundance Sections**: §1, §3, §6, §8, §9, §10

---

#### 2. Product Strategy & UX

**Expertise**:

- Product-market fit validation
- User persona development
- UX flow design and optimization
- Trust & safety frameworks
- Marketplace dynamics
- Community platform design

**Frameworks Applied**:

- Purpose, People, Process (management framework)
- Jobs to Be Done
- User journey mapping
- MVP prioritization

**Grounding Sources**:

- Nielsen Norman Group UX principles
- Marketplace design patterns
- Community platform research

**Analyzes Abundance Sections**: §2, §4, §7 (user experience aspects)

---

#### 3. iOS Architecture Expert

**Expertise**:

- SwiftUI architecture patterns (MVVM, TCA, MV) (Latest Swift Version)
- iOS application design and best practices (iOS 26)
- Code organization and modularity
- State management approaches
- Testing strategies for iOS

**Frameworks Applied**:

- SwiftUI architecture patterns
- Dependency injection strategies
- Clean architecture principles adapted for iOS

**Grounding Sources**:

- Apple Human Interface Guidelines (HIG)
- iOS Liquid Glass Guidelines
- Swift Evolution proposals
- WWDC session notes (2024, 2025)
- SwiftUI documentation
- Firebase iOS SDK documentation
- <https://docs.swift.org/swift-book/documentation/the-swift-programming-language/aboutswift/>
- <https://developer.apple.com/documentation/>

**Analyzes Abundance Sections**: §5 (client architecture), implementation approach

---

#### 4. Computer Vision & ML

**Expertise**:

- Apple Vision Framework
- Core ML integration
- On-device machine learning
- Object detection and segmentation
- Computer vision pipeline design

**Frameworks Applied**:

- On-device ML best practices
- Vision framework patterns
- Model optimization techniques

**Grounding Sources**:

- Apple Vision Framework documentation: developer.apple.com/documentation/vision
- <https://developer.apple.com/documentation/VisualIntelligence>
- WWDC 2024/2025 Vision sessions
- Core ML documentation
- VNRecognizeObjectsRequest API
- On-device ML performance optimization guides

**Analyzes Abundance Sections**: §2 (technical magic), §5 (4-phase pipeline)

---

#### 5. Cloud Backend Architect

**Expertise**:

- GCP architecture and services
- Firebase integration patterns
- Kubernetes and container orchestration
- API design and scalability
- Data modeling for cloud databases
- Observability and monitoring

**Frameworks Applied**:

- Cloud-native architecture patterns
- Microservices vs monolith-first
- API design best practices
- Database design for scale

**Grounding Sources**:

- GCP documentation (Firestore, Cloud Functions, Vertex AI, Cloud Storage)
- Firebase documentation (Auth, Firestore, Storage, Cloud Functions)
- Google Cloud Architecture Framework
- API design best practices (Google Cloud APIs, REST/gRPC)
- Firebase Extensions marketplace

**Analyzes Abundance Sections**: §5 (backend architecture), §8 (scalability metrics)

---

#### 6. Privacy & Security Architect

**Expertise**:

- Privacy-first architectural design
- Encryption and cryptography
- Data minimization strategies
- Threat modeling (STRIDE)
- Mobile security best practices
- Regulatory compliance (GDPR, CCPA)

**Frameworks Applied**:

- Privacy by Design principles
- STRIDE threat modeling
- Defense in depth
- Zero trust architecture

**Grounding Sources**:

- Apple iOS Security Guide (latest version)
- OWASP Mobile Application Security Testing Guide (MASTG)
- iOS data protection APIs
- Secure Enclave documentation
- GDPR/CCPA compliance frameworks

**Analyzes Abundance Sections**: §5 (privacy architecture), §7 (trust & safety)

---

#### 7. Software Architecture Expert

**Expertise**:

- System design and architecture patterns
- API contract design
- Modularity and separation of concerns
- Testing strategies (test pyramid)
- Technical debt management
- Monolith-first vs microservices

**Frameworks Applied**:

- Monolith-first approach
- Domain-driven design
- API design principles
- Test pyramid and coverage strategies
- Evolutionary architecture

**Grounding Sources**:

- REST API design principles
- Domain-driven design patterns
- Testing strategies (unit, integration, e2e)
- Microservices patterns
- Refactoring catalogs

**Analyzes Abundance Sections**: §5 (overall architecture), technical feasibility across all sections

---

## Complete Pipeline Architecture

### Pipeline Flow Diagram

```
PHASE 1: Vision & Strategy Validation
├─ 1.1: Business Strategy → Business Model + Competitive Analysis
└─ 1.2: Product Strategy → PRD-001 + User Journeys
    │
    ├─ [CHECKPOINT: Approve strategic direction & MVP scope]
    │
PHASE 2: Technical Architecture (FULLY SEQUENTIAL)
├─ 2.1: Tech Stack Mapping → TECH-STACK-MAP-001 🔒
    │   └─ [CHECKPOINT: Approve COMPLETE tech stack - locks all technology choices]
    │
├─ 2.2: iOS Architecture
    │   Input: TECH-STACK-MAP-001
    │   Output: DESIGN-002 (iOS architecture WITHIN tech stack)
    │   └─ [CHECKPOINT: Approve iOS architecture]
    │
├─ 2.3: Backend Architecture
    │   Input: TECH-STACK-MAP-001 + DESIGN-002
    │   Output: DESIGN-003 (Backend architecture WITHIN tech stack)
    │   └─ [CHECKPOINT: Approve backend architecture]
    │
├─ 2.4: Computer Vision Pipeline
    │   Input: TECH-STACK-MAP-001 + DESIGN-002 + DESIGN-003
    │   Output: DESIGN-004 (CV pipeline WITHIN tech stack)
    │   └─ [CHECKPOINT: Approve CV pipeline]
    │
└─ 2.5: Security & Privacy
    Input: TECH-STACK-MAP-001 + DESIGN-002 + DESIGN-003 + DESIGN-004
    Output: DESIGN-005 (Security across ENTIRE stack)
    └─ [CHECKPOINT: Approve security architecture]
    │
PHASE 3: Deep Technical Research
├─ 3.1: iOS Implementation Research
├─ 3.2: Backend Implementation Research
└─ 3.3: AI Provider Research
    │
PHASE 4: Technology Stack Finalization
├─ 4.1: iOS Tech Stack Specification
├─ 4.2: Backend Tech Stack Specification
└─ 4.3: AI/ML Integration Specification
    │
PHASE 5: Implementation Planning (REFACTORED 2025-11-12)
├─ 5.1: Document Orchestration Roadmap (sprint → document → scaffolding mapping)
└─ 5.2: Pre-Development Readiness Validation (artifact validation, developer onboarding)
    │
PHASE 6: Validation & Finalization
├─ 6.1: Technical Validation (All technical agent personas)
└─ 6.2: Business-Technical Alignment
```

### Abundance Document Section Mapping

| **Abundance Section**            | **Primary Expert Agent**                                               | **Secondary Expert Agents**                                |
| -------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------- |
| §1: What Is Abundance?           | Business Strategy Analyst                                              | Product Strategy & UX                                      |
| §2: How Abundance Works          | Computer Vision & ML                                                   | iOS Architecture Expert                                    |
| §3: Strategic Roadmap & Vision   | Business Strategy Analyst                                              | Product Strategy & UX                                      |
| §4: Key Features & Functionality | Product Strategy & UX                                                  | iOS Architecture Expert, Cloud Backend Architect           |
| §5: Technical Architecture       | iOS Architecture Expert, Cloud Backend Architect, Computer Vision & ML | Privacy & Security Architect, Software Architecture Expert |
| §6: Business Model & Growth      | Business Strategy Analyst                                              | Product Strategy & UX                                      |
| §7: Challenges & Risk Mitigation | Business Strategy Analyst, Product Strategy & UX                       | Privacy & Security Architect                               |
| §8: Success Metrics & Milestones | Business Strategy Analyst                                              | Product Strategy & UX, Cloud Backend Architect             |
| §9: Long-Term Vision             | Business Strategy Analyst                                              | All (validation check)                                     |
| §10: Conclusion                  | Business Strategy Analyst                                              | Product Strategy & UX                                      |

---

## Context Map Usage

### How to Use the Context Map

**File**: `docs/context-map.json`

Before starting any stage execution, follow this workflow:

1. **Read the context map**:

   ```
   Read docs/context-map.json
   ```

2. **Look up the current stage** (e.g., `stage-2.3`):

   ```json
   {
     "stage-2.3": {
       "name": "Backend Cloud Architecture",
       "expert_agent": "Cloud Backend Architect",
       "status": "pending",
       "required_inputs": {
         "common": ["docs/abundance-analysis-pipeline-design.md"],
         "from_stage_2.1": ["docs/tech-stack/TECH-STACK-MAP-001.md", ...],
         "from_stage_2.2": ["docs/design/DESIGN-002-ios-architecture.md", ...]
       }
     }
   }
   ```

3. **Load all required input files**:

   - Start with `common` files (always required)
   - Load files from previous stages (`from_stage_X.Y`)
   - If `apple_docs` is specified, load from `docs/apple/`

4. **Verify prerequisites**:

   - Check that all previous stages have `status: "completed"`
   - Ensure all required input files exist

5. **Execute the stage** using the loaded context

6. **Update the context map** after completion:
   - Change `status` from `pending` to `completed`
   - Update `outputs_created` with actual files generated
   - Add `completed_date` timestamp

### Context Map Structure

Each stage entry contains:

- **name**: Human-readable stage name
- **expert_agent**: Which agent specification to use
- **status**: `pending`, `in_progress`, or `completed`
- **required_inputs**: Nested object with file dependencies
  - `common`: Always required base files
  - `from_stage_X.Y`: Outputs from specific previous stages
  - `from_phase_N`: Outputs from entire phases
  - `apple_docs`: Path to Apple documentation (iOS stages only)
- **outputs_created**: List of artifacts generated (updated after completion)
- **completed_date**: ISO timestamp when stage finished

### Why This Matters

**Without context-map.json**: Agents might guess which files to load, leading to:

- Missing critical context from previous stages
- Inconsistent decisions due to incomplete information
- Duplicate work when re-creating existing artifacts
- Breaking changes when assumptions differ between stages

**With context-map.json**: Every stage execution is deterministic:

- Explicit file lists eliminate guesswork
- All dependencies clearly documented
- Status tracking prevents premature execution
- Outputs tracked for traceability

### Updating the Context Map

After completing a stage, update the context map:

```json
{
  "stage-2.3": {
    "status": "completed",
    "outputs_created": [
      "docs/design/DESIGN-003-backend-architecture.md",
      "docs/adr/ADR-011-firestore-data-model.md",
      "docs/tech-stack/DATA-MODEL-001-firestore-schema.md"
    ],
    "completed_date": "2025-11-02T14:30:00Z"
  }
}
```

This ensures downstream stages know exactly what's available and where to find it.

---

## PHASE 1: Vision & Strategy Validation

### Stage 1.1: Business Strategy Deep Dive

**Expert Agent**: Business Strategy Analyst

**Input Documents**:

- `shared/Abundance_App_Interpretation_Report.md` (§1, §3, §6, §8, §9, §10)

**Tasks**:

1. Stress-test business assumptions using:
   - Aggregation Theory
   - Network effects analysis
   - Competitive dynamics framework
   - Value chain analysis
2. Analyze market positioning vs. competitors:
   - Inventory apps (Sortly, Encircle, MyStuff)
   - P2P marketplaces (eBay, Facebook Marketplace, OfferUp, Mercari)
   - Sharing platforms (Nextdoor, Buy Nothing, Freecycle)
3. Validate "come for tool, stay for network" strategy
4. Assess iOS 26 integration strategy and App Store featuring viability
5. Critique monetization pathways and unit economics
6. Evaluate defensible moats and competitive advantages

**Outputs**:

- **Validated Business Strategy Document** (markdown, corrected/expanded from original)
- **Business Model Canvas** (structured document)
- **Competitive Analysis Matrix** (with moat assessment)
- **ADR-001: Strategic Positioning** (Why iOS-first? Why privacy-first?)
- **ADR-002: Platform Strategy** (Come for tool, stay for network validation)

**Checkpoint Questions**:

- Is the business model defensible against incumbent marketplaces?
- Are the network effects strong enough to justify the strategy?
- Is the iOS-first approach the right strategic choice?
- Are monetization assumptions realistic?

**Human Decision Required**:

- Approve strategic direction OR request revisions
- Select between alternative positioning strategies if presented
- Make go/no-go decision on overall business viability

---

### Stage 1.2: Product Strategy & UX Analysis

**Expert Agent**: Product Strategy & UX

**Input Documents**:

- `shared/Abundance_App_Interpretation_Report.md` (§2, §4, §7)
- Validated Business Strategy Document (from Stage 1.1)
- ADR-001, ADR-002

**Tasks**:

1. Validate user personas (Organizer, Sharer, Seller):
   - Are these distinct enough?
   - Do they represent real user segments?
   - Are there missing personas?
2. Analyze user flows for:
   - AI cataloging (snap → identify → catalog)
   - Community sharing (create circle → lend/borrow)
   - Marketplace transactions (list → sell → transact)
3. Assess trust & safety requirements:
   - User verification
   - Dispute resolution
   - Community moderation
   - Reputation systems
4. Evaluate friction points and "magical" moments
5. Propose MVP feature prioritization:
   - Phase 1 (single-player utility)
   - Phase 2 (community sharing)
   - Phase 3 (marketplace)

**Outputs**:

- **PRD-001: Abundance MVP Product Requirements** (formal spec with acceptance criteria)
- **User Journey Maps** (for Organizer, Sharer, Seller personas)
- **Trust & Safety Framework** (verification, disputes, community guidelines)
- **ADR-003: MVP Scope Decision** (what's in v1.0, what's deferred to v2/v3)
- **Feature Prioritization Matrix** (MoSCoW: Must/Should/Could/Won't)

**Checkpoint Questions**:

- Are the user personas validated and actionable?
- Is the MVP scope appropriate for achieving product-market fit?
- Are trust & safety measures adequate for launch?
- Is the phasing strategy (single-player → sharing → marketplace) correct?

**Human Decision Required**:

- Approve PRD-001 and MVP scope
- Make prioritization decisions if trade-offs exist
- Approve trust & safety framework

---

## PHASE 2: Technical Architecture

**Critical Note**: Phase 2 is **fully sequential**. Stage 2.0 performs foundational research that validates ALL technical capabilities. Stage 2.1 uses that research to create the technology map. No stage proceeds until the prior stage is complete and approved.

**Context Map**: Before executing any stage in Phase 2, read `docs/context-map.json` to determine required input documents. Each stage's entry specifies exactly which files from previous stages must be loaded for context. See [Context Map Usage](#context-map-usage) for details.

---

### Stage 2.0: Computer Vision & AI Research 🔬

**Expert Agent**: Computer Vision & ML Engineer

**Purpose**: Research and verify ALL technical capabilities for AI cataloging pipeline BEFORE making technology decisions in Stage 2.1.

**Input Documents**:

- PRD-001: Abundance MVP Product Requirements
- [ADR-003-mvp-scope-phasing](adr/ADR-003-mvp-scope-phasing.md): MVP Scope and Phasing
- [ADR-004-ios-26-only-launch](adr/ADR-004-ios-26-only-launch.md): iOS 26-Only Launch Strategy
- Feature Prioritization Matrix (barcode scanning requirements)
- MVP Vision Features (simplifications from Google Lens)

**Critical Research Areas**:

1. **iOS 26 Vision Framework**

   - Verify actual API names (use Apple MCP with token-safe pattern)
   - Object detection capabilities (VNCoreMLRequest + Core ML models)
   - Barcode scanning (VNDetectBarcodesRequest, supported symbologies)
   - Performance characteristics (latency, accuracy, device requirements)
   - Cost: $0 (on-device)

2. **Core ML Object Detection Models**

   - Available pre-trained models (YOLOv3-Tiny, others)
   - Download sources (Apple Developer, official repos)
   - Model size, accuracy, supported classes
   - Integration pattern with Vision Framework

3. **Barcode Product Lookup APIs**

   - UPCitemdb, Go-UPC, Barcode Lookup, OpenFoodFacts
   - Pricing tiers, request limits, database coverage
   - API capabilities (product names, images, specs)
   - Response times, reliability

4. **Cloud AI Providers for Attribute Extraction**

   - Gemini 2.5 Flash-Lite (verify model exists, pricing, capabilities)
   - GPT-4V alternatives
   - Structured output support (JSON mode)
   - Vision capabilities (color, material, condition detection)

5. **Visual Product Search**

   - SerpAPI Google Lens (verify API, pricing, requirements)
   - Response format, confidence scores, image URL requirements
   - Alternative providers (if any)

6. **AI Reasoning/Synthesis Layer**
   - Claude Sonnet 4.5 Batch API (verify pricing, capabilities)
   - LLM parsing for brand/model extraction
   - Conflict resolution capabilities

**Research Methodology**:

- **Apple APIs**: Use apple-docs-fetcher pattern (search-first, selective fetch, token budget: 25K max)
- **Cloud APIs**: Use WebSearch + WebFetch for official documentation
- **Pricing**: Verify current pricing (2025 rates), calculate blended costs
- **Capabilities**: Test APIs if possible, otherwise verify via official docs
- **Performance**: Document latency, throughput, accuracy from official benchmarks

**Outputs**:

- **RESEARCH-VALIDATION-stage-2.0.md**: Complete verification report

  - iOS 26 Vision Framework (verified API names, capabilities)
  - VNCoreMLRequest + YOLOv3-Tiny (integration pattern, performance)
  - VNDetectBarcodesRequest (symbologies, accuracy)
  - Barcode API comparison (UPCitemdb selection, pricing)
  - Gemini 2.5 Flash-Lite verification (model exists, pricing, JSON mode)
  - SerpAPI Google Lens verification (pricing, requirements, response format)
  - Claude Sonnet 4.5 verification (batch API pricing, capabilities)
  - Blended cost model (free tier: $0, premium tier: calculated)

- **DESIGN-004: 4-Layer AI Pipeline Architecture** (conceptual)

  - Layer 1: On-device Vision + barcode (iOS 26)
  - Layer 2a: Attribute extraction (Gemini 2.5 Flash-Lite)
  - Layer 2b: Product search (SerpAPI + UPCitemdb dual-mode)
  - Layer 3: AI synthesis (Claude Sonnet 4.5)
  - Cost breakdown per layer
  - Latency budget per layer
  - Fallback strategies

- **ADR-013: Vision Framework Strategy**

  - VNCoreMLRequest + YOLOv3-Tiny justification
  - On-device processing rationale
  - Barcode scanning integration

- **ADR-014: Cloud AI Provider Selection**

  - Gemini 2.5 Flash-Lite for Layer 2a (why)
  - SerpAPI Google Lens for Layer 2b visual search (why)
  - UPCitemdb for Layer 2b barcode lookup (why)
  - Claude Sonnet 4.5 for Layer 3 synthesis (why)

- **ADR-018: Barcode Product Lookup Strategy**

  - UPCitemdb selection rationale
  - Dual-mode strategy (barcode-first, visual fallback)
  - Cost optimization (50% barcode rate = 37% cost reduction)

- **COST-MODEL-001: AI Cataloging Cost Per Item**
  - Free tier: $0 (Layer 1 only)
  - Premium tier: Blended cost with barcode optimization
  - Margin calculations (revenue per item vs. cost)
  - Break-even analysis

**Checkpoint Questions**:

- Are all iOS 26 Vision APIs verified with actual names?
- Do barcode scanning APIs meet coverage and cost requirements?
- Is the 4-layer AI pipeline technically feasible?
- Are cost projections accurate and sustainable?
- Are there any unverified claims or assumptions?

**Human Decision Required**:

- Approve AI pipeline architecture (4 layers)
- Approve selected AI providers (Gemini, SerpAPI, UPCitemdb, Claude)
- Approve cost model and margin targets
- Decide: Proceed to Stage 2.1 tech stack mapping

**Success Criteria**:

- ✅ All iOS 26 Vision APIs verified via Apple MCP (actual names, not assumptions)
- ✅ All cloud AI providers verified (models exist, pricing current)
- ✅ Barcode API selected with verified pricing/limits
- ✅ Complete 4-layer pipeline designed with costs
- ✅ No unverified technical claims
- ✅ Token usage < 25,000 (apple-docs-fetcher pattern successful)

---

### Stage 2.1: High-Level Tech Stack Mapping 🔒

**Expert Agent**: Software Architecture Expert

**Input Documents**:

- PRD-001: Abundance MVP Product Requirements
- Validated Business Strategy Document
- All ADRs from Phase 1 (ADR-001 through ADR-004)
- **RESEARCH-VALIDATION-stage-2.0.md** (verified AI capabilities, costs)
- **DESIGN-004: 4-Layer AI Pipeline** (from Stage 2.0)
- **ADR-013, ADR-014, ADR-018** (Vision Framework, AI providers, barcode strategy from Stage 2.0)
- **COST-MODEL-001** (verified AI costs from Stage 2.0)

**Critical Decisions to Lock In**:
This stage makes ALL foundational technology decisions:

1. **Client Platform**: iOS (Swift 6.0, SwiftUI)
2. **Backend Platform**: GCP vs AWS vs Azure
3. **Backend Architecture**: Monolith-first vs microservices
4. **API Style**: REST vs GraphQL vs gRPC
5. **Database**: Firestore vs Cloud SQL vs hybrid
6. **Authentication**: Firebase Auth vs custom solution
7. **File Storage**: Firebase Storage vs Cloud Storage
8. **Compute**: Cloud Functions vs App Engine vs Cloud Run
9. **AI/ML Platform**: Vertex AI vs third-party APIs
10. **Observability**: Logging, monitoring, analytics services

**Tasks**:

1. For each technology decision above:
   - Research options
   - Evaluate against MVP requirements
   - Justify recommendation using Fowler's frameworks
2. Create complete tech stack map showing all layers
3. Define API contracts and interfaces between layers
4. Establish testing strategy across the stack (test pyramid)
5. Document decision rationale in ADRs

**Outputs**:

- **TECH-STACK-MAP-001: Complete Technology Stack** 🔑

  ```
  CLIENT LAYER:
  - Platform: iOS 17+
  - Language: Swift 6.0
  - UI Framework: SwiftUI
  - Architecture Pattern: [TBD by iOS expert in 2.2]

  API LAYER:
  - Protocol: REST over HTTPS
  - Format: JSON
  - Authentication: Firebase Auth tokens (JWT)
  - Base URL: [TBD]

  BACKEND LAYER:
  - Platform: Google Cloud Platform (GCP)
  - Compute: Cloud Functions (Node.js/Python - TBD in 2.3)
  - Database: Cloud Firestore
  - Storage: Firebase Storage
  - Auth: Firebase Authentication

  AI/ML LAYER:
  - On-Device: Apple Vision Framework + Core ML
  - Cloud: Vertex AI / OpenAI / Gemini (Primary/fallback TBD in 2.4)

  OBSERVABILITY LAYER:
  - Logging: Cloud Logging
  - Monitoring: Cloud Monitoring
  - Analytics: Firebase Analytics
  - Error Tracking: [TBD]
  ```

- **API-CONTRACTS-001: Service Interface Definitions**

  - REST endpoint structure
  - Request/response schemas (JSON)
  - Authentication flow
  - Error handling conventions

- **ADR-004: GCP Platform Choice** (why GCP over AWS/Azure)
- **ADR-005: Monolith-First Backend** (Fowler's monolith-first rationale applied to Abundance)
- **ADR-006: REST API Design** (why REST over GraphQL for MVP)
- **ADR-007: Firebase Services Integration** (which Firebase services, why hybrid GCP/Firebase)
- **TEST-STRATEGY-001: Test Pyramid & Coverage Goals**
  - Unit tests: 70%+ coverage
  - Integration tests: Critical paths
  - E2E tests: Key user flows

**Checkpoint Questions**:

- Is GCP the right cloud platform choice?
- Should we use Firebase services or pure GCP services?
- Is REST the right API style for the MVP?
- Is the monolith-first approach appropriate?
- Are there any technology choices that create unacceptable vendor lock-in?

**Human Decision Required**:

- **CRITICAL APPROVAL**: This checkpoint locks in ALL technology boundaries
- Review and approve the complete tech stack map
- Approve/reject specific technology choices
- Any changes here cascade to all downstream stages

---

### Stage 2.2: iOS Client Architecture

**Expert Agent**: iOS Architecture Expert

**Input Documents**:

- **TECH-STACK-MAP-001** (knows: Swift 6, SwiftUI, Firebase SDK, REST API, Vision framework)
- **API-CONTRACTS-001** (knows exact endpoints to call)
- **PRD-001** (knows features to build)

**Constraints from 2.1**:

- MUST use Swift 6.0 and SwiftUI
- MUST integrate Firebase iOS SDK
- MUST call REST API endpoints defined in API-CONTRACTS-001
- MUST use Vision framework for on-device processing

**Tasks**:

1. **Choose SwiftUI architecture pattern** (MVVM vs TCA vs MV):
   - Evaluate each pattern for Abundance's specific needs
   - Consider: complexity, testability, team size, maintenance
   - Justify choice with code examples
2. **Design module structure**:
   - Networking layer (API client)
   - Vision layer (Camera + Vision framework)
   - UI layer (Views, ViewModels)
   - Data layer (Firebase SDK, local persistence)
   - Domain layer (Business logic)
3. **Plan dependency injection approach**
4. **Design state management** (Combine vs async/await vs @Observable)
5. **Plan on-device data persistence**:
   - UserDefaults for simple settings
   - Core Data vs Firestore local cache for inventory
6. **Design Firebase SDK integration**:
   - Auth (login, token management)
   - Firestore (real-time listeners, offline support)
   - Storage (photo uploads)
   - Analytics (event tracking)

**Research Focus**:

- Swift 6 concurrency patterns (async/await)
- SwiftUI + chosen architecture best practices
- Firebase iOS SDK documentation
- Vision framework integration examples

**Outputs**:

- **DESIGN-006: iOS Module Dependencies** (module dependency diagram with Features/Core/Shared layers)
- **ADR-010: SwiftUI Architecture Pattern Choice** (MVVM selected - testable, SwiftUI-native)
- **ADR-011: iOS Module Structure** (SPM local packages, dependency rules)
- **ADR-012: State Management Approach** (Combine + async/await hybrid)
- **ADR-013: Dependency Injection Strategy** (Constructor injection for testability)
- **DESIGN-007: Firebase SDK Integration** (Auth, Firestore, Storage, Analytics patterns)
- **DESIGN-008: Vision Framework Integration** (VNCoreMLRequest, barcode scanning)
- **DESIGN-009: iOS Networking Layer** (REST API client, error handling)
- **DESIGN-010: iOS Data Persistence** (UserDefaults, Keychain, Firestore cache)
- **DESIGN-011: iOS Data Models** (Codable structs for API/Firestore)
- **TEST-002: iOS Unit Test Strategy** (80/15/5 pyramid, mocking patterns)

**Checkpoint Questions**:

- Is the chosen architecture pattern appropriate for the team and project?
- Is the module structure clear and maintainable?
- Are Firebase integrations properly designed?
- Is state management approach consistent and scalable?

**Human Decision Required**:

- Approve iOS architecture choices
- Select between architecture pattern options if trade-offs exist

---

### Stage 2.3: Backend Cloud Architecture

**Expert Agent**: Cloud Backend Architect

**Input Documents**:

- **TECH-STACK-MAP-001** (knows: GCP, Cloud Functions, Firestore, Firebase Storage, REST API)
- **API-CONTRACTS-001** (knows exact endpoints to implement)
- **DESIGN-002** (knows what iOS client expects from backend)
- **PRD-001** (knows features and scalability requirements)

**Constraints from 2.1 & 2.2**:

- MUST use GCP/Firebase services
- MUST implement REST endpoints defined in API-CONTRACTS-001
- MUST support iOS client's Firebase SDK integration
- MUST use Cloud Firestore and Firebase Storage

**Tasks**:

1. **Design Firestore data model**:
   - Collections structure (users, items, sharingCircles, marketplaceListings)
   - Document schemas (fields, types, indexes)
   - Relationships and denormalization strategy
   - Query patterns for common operations
2. **Design Cloud Functions structure**:
   - One monolithic function vs multiple functions
   - Function triggers (HTTP, Firestore, Storage)
   - Background processing (image AI analysis)
3. **Plan Firebase Storage organization**:
   - Folder structure (userPhotos/{uid}/original/, cropped/, processed/)
   - Access control and signed URLs
   - Lifecycle policies (archival, deletion)
4. **Design authentication & authorization**:
   - Firebase Auth integration
   - Custom claims for roles (user, moderator, admin)
   - Firestore security rules (RLS - row-level security)
5. **Design scalability approach**:
   - Firestore indexing strategy
   - Cloud Functions concurrency limits
   - Rate limiting and quota management
6. **Design hot-swappable AI integration layer**:
   - Abstract interface for AI providers
   - Configuration-driven provider selection (env variables)
   - Fallback strategy (primary → secondary → tertiary)

**Research Focus**:

- Firestore data modeling best practices
- Cloud Functions patterns for image processing
- Firebase Storage security rules
- Vertex AI integration from Cloud Functions

**Outputs**:

- **DESIGN-003: Backend Architecture** (GCP/Firebase component diagram)
- **DATA-MODEL-001: Firestore Schema** (collections, document structure, indexes)

  ```
  Collection: users/{userId}
    - email: string
    - displayName: string
    - createdAt: timestamp
    - photoURL: string

  Collection: items/{itemId}
    - ownerId: string (ref to users/{userId})
    - name: string
    - category: string
    - estimatedValue: number
    - photoUrls: array<string>
    - aiMetadata: object
    - visibility: enum (private, showcase, shared, marketplace)
    - createdAt: timestamp

  Collection: sharingCircles/{circleId}
    - name: string
    - members: array<string> (userIds)
    - createdBy: string
    - createdAt: timestamp

  [... etc]
  ```

- **CLOUD-FUNCTIONS-001: Function Structure** (which functions, triggers, responsibilities)
- **SECURITY-RULES-001: Firestore Security Rules** (access control logic)
- **STORAGE-RULES-001: Firebase Storage Rules** (file access control)
- **ADR-011: Firestore Data Model Rationale** (why this schema, denormalization decisions)
- **ADR-012: Cloud Functions Organization** (monolith vs multi-function)
- **AI-INTEGRATION-LAYER-001: Hot-Swappable AI Design** (abstraction layer specification)

**Checkpoint Questions**:

- Is the Firestore data model optimized for common queries?
- Are security rules comprehensive and secure?
- Is the Cloud Functions structure maintainable?
- Is the AI integration layer truly hot-swappable?

**Human Decision Required**:

- Approve backend architecture
- Approve data model design
- Approve security rules approach

---

### Stage 2.4: Computer Vision Pipeline Architecture

**Expert Agent**: Computer Vision & ML

**Input Documents**:

- **TECH-STACK-MAP-001** (knows: Vision framework on-device, Gemini/SerpAPI/Claude cloud)
- **DESIGN-002** (knows iOS architecture, where Vision code lives)
- **DESIGN-003** (knows backend, how to send images to cloud AI)
- **AI-INTEGRATION-LAYER-001** (knows the abstraction for AI providers)
- **PRD-001** (knows the 4-layer pipeline requirements)

**Constraints from 2.1, 2.2, 2.3**:

- MUST use Apple Vision framework with Core ML (VNCoreMLRequest + YOLOv3-Tiny)
- MUST upload cropped images to **Google Cloud Storage + Cloud CDN** (GCP-native)
- MUST call Cloud Functions for AI processing (multi-layer pipeline)
- MUST support Layer 2a (Gemini Flash-Lite) + Layer 2b (SerpAPI Google Lens)
- MUST use hot-swappable AI integration layer

**Tasks**:

1. **Design Layer 1: Real-Time On-Device Object Detection (iOS) - REFACTORED 2025-11-15**:

   - AVFoundation 2 FPS continuous frame streaming (CVPixelBuffer)
   - **Core ML VNCoreMLRequest with YOLOv11n** (80 COCO object classes, 10x faster)
   - **VNGenerateForegroundInstanceMaskRequest** (organic subject masks)
   - **VNImageFingerprint** (visual deduplication, 5-min cache, 0.90 similarity)
   - **VNCalculateImageAestheticsScoresRequest** (quality assessment)
   - Parallel multi-object detection (5 objects simultaneously in ~120ms)
   - Three-tier confidence system: automatic (conf>0.70 && qual>0.65), manual (conf 0.40-0.69), ignore (<0.40)
   - Organic glowing borders (mint green for auto, grey for manual)
   - Automatic cataloging on high-confidence + high-quality detections
   - Double-tap gesture for manual cataloging
   - Apple Neural Engine optimization
   - Privacy firewall: full frames NEVER leave device, only cropped objects after quality filter

   **Architecture Change**: Button-triggered single-photo → continuous 2 FPS real-time detection

2. **Design Layer 2a: Attribute Extraction (Gemini 2.5 Flash-Lite)**:

   - iOS → GCS + Cloud CDN (upload cropped images, get public URL)
   - Cloud Function → Vertex AI (Gemini 2.5 Flash-Lite)
   - JSON schema mode for structured output (condition, color, material, category)
   - Cost: $0.000249 per image, Latency: 30-50ms

3. **Design Layer 2b: Product Search (SerpAPI Google Lens)**:

   - **CRITICAL**: Use GCS + Cloud CDN public URLs (SerpAPI requires publicly accessible HTTPS URLs)
   - **Swift REST API integration** (no native SDK, use URLSession)
   - Cloud Function → SerpAPI Google Lens API with public image URL
   - Parse visual_matches response for brand/model/price
   - Claude Haiku 4.5 parsing for structured brand/model/variant extraction
   - Cost: $0.0109 per item, Latency: 5-7s
   - **NOTE**: AWS S3 has known issues with SerpAPI; GCS recommended

4. **Design Layer 3: AI Synthesis (Claude Sonnet 4.5)**:

   - Merge Layer 2a + Layer 2b results
   - Conflict resolution (vision vs product search mismatches)
   - Final metadata generation with confidence scoring
   - Cost: $0.0092 per inference, Latency: 1-2s

5. **Design Data Integration & UX**:
   - Cloud Function → Firestore (write enriched metadata)
   - iOS → Firestore listener (real-time UI updates)
   - Error handling and retry logic for each layer
   - Fallback strategies (Layer 2b fails → use Layer 2a only)

**Research Focus**:

- Apple Vision framework documentation (VNCoreMLRequest, VNDetectBarcodesRequest)
- Apple ML Models: YOLOv3-Tiny pre-trained Core ML model
- WWDC 2024/2025 Vision sessions
- Core ML integration and Apple Neural Engine optimization
- **Google Cloud Storage + Cloud CDN**: Public URL generation for SerpAPI
- **Gemini 2.5 Flash-Lite** (Vertex AI): JSON schema mode, attribute extraction
- **SerpAPI Google Lens API**: REST integration, visual_matches parsing, public URL requirements
- **Swift URLSession patterns**: Direct REST API calls (no native SerpAPI SDK)
- **Claude Haiku 4.5 API** (Anthropic): Brand/model/variant parsing from SerpAPI results
- **Claude Sonnet 4.5 Batch API** (Anthropic): AI synthesis and conflict resolution

**Outputs**:

- **DESIGN-004: Computer Vision Pipeline** (detailed 4-layer architecture with sequence diagrams)
- **DESIGN-005: Layer 2b Product Search Architecture** (SerpAPI + Claude Haiku parsing)
- **ADR-013: Vision Framework Strategy** (VNCoreMLRequest + YOLOv3-Tiny)
- **ADR-014: Cloud AI Provider Selection** (Gemini 2.5 Flash-Lite for Layer 2a)
- **ADR-015: AI Reasoning Layer Architecture** (Claude Sonnet 4.5 for synthesis)
- **ADR-016: Image Hosting Strategy** (GCS + Cloud CDN for SerpAPI public URLs)
- **ADR-017: LLM Parsing Architecture** (Claude Haiku for brand/model extraction)
- **VISION-INTEGRATION-001: iOS Vision Framework Implementation** (Swift/Core ML code design)
- **SERPAPI-INTEGRATION-001: Swift REST API Integration** (URLSession patterns, no native SDK)
- **CLOUD-AI-INTEGRATION-001: Multi-Layer AI Processing** (Layer 2a + 2b + 3 orchestration)

**Checkpoint Questions**:

- Is the 4-layer pipeline architecturally sound (Layer 1 → 2a+2b → 3)?
- Are privacy guarantees maintained (only cropped objects uploaded, not full photos)?
- Is GCS + Cloud CDN the correct choice for SerpAPI public URL requirements?
- Is the Vision framework integration optimized (YOLOv3-Tiny, Neural Engine)?
- Are Layer 2b costs acceptable ($0.0109 per item for product search)?
- Is Swift REST API integration (no SDK) the right approach for SerpAPI?
- Is the Claude Haiku parsing layer necessary for brand/model extraction?
- Are fallback strategies comprehensive (Layer 2b failure → Layer 2a only)?

**Human Decision Required**:

- Approve 4-layer Computer Vision pipeline architecture
- Approve SerpAPI Google Lens integration (Layer 2b)
- Approve GCS + Cloud CDN for public image hosting
- Approve Swift REST API approach (no native SDK)
- Approve AI provider selections (Gemini, SerpAPI, Claude Haiku, Claude Sonnet)
- Approve cost model ($0.019449 per item total)

---

### Stage 2.5: Privacy & Security Architecture

**Expert Agent**: Privacy & Security Architect

**Input Documents**:

- **TECH-STACK-MAP-001** (knows all technology choices)
- **DESIGN-002** (iOS architecture)
- **DESIGN-003** (Backend architecture)
- **DESIGN-004** (Computer Vision pipeline)
- **DATA-MODEL-001** (what data is stored where)
- **SECURITY-RULES-001, STORAGE-RULES-001** (current security approach)
- **PRD-001** (privacy-first requirements)

**Constraints from All Prior Stages**:

- MUST validate security across the ENTIRE tech stack
- MUST ensure privacy-first architecture is maintained
- MUST identify and mitigate security risks

**Tasks**:

1. **Validate privacy-first architecture**:
   - Verify on-device processing minimizes data transmission
   - Confirm only cropped objects leave device (not full photos)
   - Review data retention policies
   - Validate GDPR right to be forgotten
2. **Review encryption at all layers**:
   - Data in transit (HTTPS/TLS)
   - Data at rest (Firestore, Firebase Storage)
   - Data in use (on-device processing)
   - Key management (Firebase Auth, API keys)
3. **Review authentication & authorization**:
   - Firebase Auth security
   - Firestore security rules comprehensiveness
   - Storage security rules
   - API authentication (JWT tokens)
   - Session management
4. **Perform threat modeling** (STRIDE):
   - **S**poofing: User impersonation
   - **T**ampering: Data modification
   - **R**epudiation: Action denial
   - **I**nformation Disclosure: Photo leakage, metadata exposure
   - **D**enial of Service: Rate limiting, quota exhaustion
   - **E**levation of Privilege: Admin access compromise
5. **Identify attack surfaces**:
   - API endpoints
   - Storage buckets
   - Photo uploads
   - AI provider integration
6. **Design mitigation strategies** for each threat
7. **Plan compliance** (GDPR, CCPA):
   - User consent mechanisms
   - Data export functionality
   - Data deletion workflows
   - Privacy policy requirements

**Research Focus**:

- Apple iOS Security Guide (latest)
- OWASP MASTG (Mobile Application Security Testing Guide)
- iOS Keychain and Secure Enclave
- Firebase Security Rules best practices
- GCP security hardening guides

**Outputs**:

- **DESIGN-005: Security & Privacy Architecture** (comprehensive security design across all layers)
- **THREAT-MODEL-001: STRIDE Analysis** (threats, attack vectors, mitigations)
- **ADR-015: Authentication Strategy** (Firebase Auth + biometric)
- **ADR-016: Data Encryption Approach** (at rest, in transit, in use)
- **ADR-017: Photo Privacy Protection** (why cropped-only transmission is secure)
- **PRIVACY-IMPACT-ASSESSMENT-001** (GDPR/CCPA compliance analysis)
- **TEST-002: Security Test Plan** (penetration testing, privacy audits)
- **SECURITY-HARDENING-CHECKLIST-001** (deployment checklist)

**Checkpoint Questions**:

- Are there any privacy vulnerabilities in the current design?
- Are security rules comprehensive and correct?
- Are all attack surfaces identified and mitigated?
- Is the system compliant with GDPR and CCPA?

**Human Decision Required**:

- Approve security architecture
- Approve threat mitigations
- Approve compliance approach
- Decide on any security vs. usability trade-offs

---

## PHASE 3: Deep Technical Research

**Purpose**: Research specific implementation details, documentation, and code patterns within the approved tech stack.

**Context Map**: Each stage in Phase 3 requires outputs from Phase 2. Consult `docs/context-map.json` for exact file dependencies before starting any research stage.

---

### Stage 3.1: iOS Implementation Research

**Expert Agent**: iOS Architecture Expert

**Input Documents**:

- PLAN-SUMMARY-stage-2.2.md (iOS Architecture)
- PLAN-SUMMARY-stage-2.6.md (UI/UX Design)
- TECH-STACK-MAP-001
- All iOS-related ADRs

**Research Tasks**:

1. **Swift 6.0 concurrency patterns**:
   - async/await best practices
   - Task groups for parallel operations
   - Actors for state isolation
   - @MainActor implicit isolation for ViewModels
   - Task.detached for background ML processing (Vision Framework)
2. **SwiftUI + chosen architecture** (MVVM/TCA/MV):
   - Code examples and templates
   - State management patterns
   - Navigation patterns
   - @Observable vs @Published migration (performance comparison)
3. **Firebase iOS SDK**:
   - Auth integration patterns
   - Firestore real-time listeners
   - Storage upload/download patterns
   - Analytics event tracking
   - Swift 6 strict concurrency workarounds (@preconcurrency import)
   - Firebase Emulator integration test patterns
4. **Vision framework implementation**:
   - VNCoreMLRequest examples
   - VNDetectBarcodesRequest for product scanning
   - Camera integration with AVFoundation
   - Image processing on Apple Neural Engine
   - Thread safety patterns (Task.detached for non-blocking execution)
5. **WWDC 2024/2025 sessions**:
   - Relevant sessions on SwiftUI, Vision, ML
   - Extract implementation insights
   - WWDC 2025 Session 266 (Swift Concurrency)
   - WWDC 2025 Session 102 (SwiftUI @Observable)
   - WWDC 2024 Session 10163 (Vision Framework concurrency)
   - WWDC 2025 Session 205 (Liquid Glass accessibility)
6. **Code Generation & Testing**:
   - Sourcery templates for MVVM boilerplate
   - AutoMockable protocol generation
   - Swift Testing framework patterns (Given/When/Then)
   - Test pyramid implementation (80/15/5 unit/integration/UI)

**Outputs**:

- **CODE-EXAMPLE-001**: Swift 6 Concurrency Patterns (@MainActor, async/await, Task.detached)
- **CODE-EXAMPLE-002**: Catalog MVVM Implementation (ViewModel + View + Repository)
- **CODE-EXAMPLE-003**: Firebase iOS Integration (Auth, Firestore, Storage async/await)
- **CODE-EXAMPLE-004**: Vision Framework Patterns (VNCoreMLRequest, VNDetectBarcodesRequest)
- **DESIGN-012**: Xcode Project Structure (Package.swift, build configurations)
- **CODEGEN-001**: Sourcery Templates (AutoMockable, boilerplate reduction)
- **TEST-EXAMPLE-001**: ViewModel Unit Tests (Given/When/Then, Swift Testing)
- **TEST-EXAMPLE-002**: iOS Testing Patterns (Firebase Emulator, XCUITest)
- **RESEARCH-002**: WWDC Insights iOS 26 (5+ session summaries, actionable patterns)

---

### Stage 3.2: Backend Implementation Research

**Expert Agent**: Cloud Backend Architect

**Input Documents**:

- DESIGN-003: Backend Architecture
- TECH-STACK-MAP-001
- All backend-related ADRs

**Research Tasks**:

1. **Cloud Functions best practices**:
   - Node.js vs Python (recommend one)
   - Function structure and organization
   - Cold start optimization
2. **Firestore**:
   - Data modeling patterns
   - Query optimization
   - Index creation
   - Batch writes and transactions
3. **Firebase Storage**:
   - Upload patterns from Cloud Functions
   - Signed URL generation
   - Lifecycle policies
4. **Vertex AI integration**:
   - Calling Vertex AI Vision API from Cloud Functions
   - Authentication and API keys
   - Rate limiting and quotas
5. **GCP observability**:
   - Cloud Logging setup
   - Cloud Monitoring dashboards
   - Error tracking

**Outputs**:

- **RESEARCH-002: Backend Implementation Patterns** (Cloud Functions patterns, Firestore queries)
- **CODE-EXAMPLES-002: Cloud Functions Reference Implementations** (working function code)
- **INFRASTRUCTURE-001: GCP Resource Configuration** (Terraform or Firebase CLI scripts)

---

### Stage 3.3: AI Provider Deep Dive

**Expert Agent**: Computer Vision & ML

**Input Documents**:

- [DESIGN-004-computer-vision-pipeline](design/DESIGN-004-computer-vision-pipeline.md): Computer Vision Pipeline
- AI-INTEGRATION-LAYER-001
- ADR-014 (AI Provider Ranking draft)

**Research Tasks**:

1. **Vertex AI Vision API**:
   - Capabilities (object detection, labeling, OCR)
   - Pricing (per request)
   - Latency benchmarks
   - API examples
2. **Claude Sonnet 4.5 API**:
   - Capabilities (detailed object analysis, metadata extraction)
   - Pricing
   - Latency
   - API examples
3. **Gemini Vision API**:
   - Capabilities
   - Pricing
   - Latency
   - API examples
4. **Accuracy benchmarks**:
   - Test each provider with sample Abundance images
   - Compare accuracy of object identification
   - Compare quality of metadata extraction
5. **Prompt engineering**:
   - Design optimal prompts for metadata extraction
   - Test prompt variations
   - Document best prompts

**Outputs**:

- **RESEARCH-003: AI Provider Comparison** (detailed comparison matrix)
- **COST-MODEL-001: AI Cataloging Cost per Item** (pricing estimates for each provider)
- **PROOF-OF-CONCEPT-001: AI Provider Benchmark Results** (accuracy test results)
- **PROMPT-TEMPLATES-001: AI Prompt Engineering** (optimal prompts for each provider)

---

## PHASE 4: Project Scaffolding & Runnable Files (REFACTORED)

**Purpose**: Generate actual runnable project files and directory structures (not more decision documents).

**Why Refactored**: Original Stages 4.1-4.3 were designed to "specify tech stack," but TECH-STACK-MAP-001 already locked all technology choices in Stage 2.1. What's actually needed are runnable files (`Package.swift`, `firestore.rules`, etc.) and project scaffolds.

**Context Map**: Use `docs/context-map.json` to identify all Phase 2-3 outputs required for scaffolding.

---

### Stage 4.1: iOS Project Scaffolding

**Expert Agent**: iOS Architecture Expert

**Purpose**: Generate actual runnable iOS project files and directory structure

**Input Documents**:

- All Stage 2.2 outputs (iOS architecture)
- All Stage 3.1 outputs (iOS implementation research)
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`
- `docs/design/DESIGN-012-xcode-project-structure.md`
- `docs/design/CODEGEN-001-sourcery-templates.md`
- All iOS ADRs (ADR-010 to ADR-013)

**Tasks**:

1. Create runnable `Package.swift` with exact dependencies (Firebase iOS SDK version, SPM packages)
2. Generate Xcode project structure specification:
   - `AbundanceApp/` (main app target)
   - `Core/` (networking, persistence, domain models)
   - `Features/` (Camera, Catalog, ItemDetail, Profile)
   - `Shared/` (utilities, extensions, design system components)
3. Create `.swiftlint.yml` configuration (linting rules)
4. Create `Sourcery.yml` codegen configuration (AutoMockable protocol generation)
5. Create `FirebaseApp/Info.plist` template (Firebase configuration)
6. Create `README-iOS-Setup.md` (developer onboarding: clone, install, run)
7. Create `.xcconfig` files for different environments (Debug, Release, Staging)
8. Create module scaffold structure (SPM local packages)

**Outputs**:

- `docs/tech-stack/Package.swift` (runnable Swift package manifest)
- `docs/tech-stack/AbundanceApp-Project-Structure.md` (detailed Xcode project specification)
- `docs/tech-stack/.swiftlint.yml` (linting configuration)
- `docs/tech-stack/Sourcery.yml` (codegen configuration)
- `docs/tech-stack/Info.plist.template` (Firebase config template)
- `docs/tech-stack/Module-Scaffold-Structure.md` (SPM package layout)
- `docs/tech-stack/README-iOS-Setup.md` (developer onboarding)
- `docs/tech-stack/iOS-Environment-Configs.md` (.xcconfig files for Debug/Release/Staging)
- `docs/checkpoints/CHECKPOINT-stage-4.1.md`

---

### Stage 4.2: Backend Project Scaffolding

**Expert Agent**: Cloud Backend Architect

**Purpose**: Generate actual runnable backend project files and deployment scripts

**Input Documents**:

- All Stage 2.3 outputs (backend architecture)
- All Stage 3.2 outputs (backend implementation research)
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`
- `docs/tech-stack/DATA-MODEL-001-firestore-schema.md`
- `docs/design/SECURITY-RULES-001-firestore-rules.md`
- `docs/design/STORAGE-RULES-001-firebase-storage-rules.md`
- `docs/tech-stack/INFRASTRUCTURE-001-gcp-deployment-automation.md`
- All backend ADRs (ADR-005 to ADR-009, ADR-019 to ADR-020)

**Tasks**:

1. Create runnable `firestore.rules` file (translate SECURITY-RULES-001 to actual syntax)
2. Create runnable `storage.rules` file (translate STORAGE-RULES-001 to actual syntax)
3. Create `firestore.indexes.json` (index definitions from DATA-MODEL-001)
4. Create `functions/package.json` (Cloud Functions dependencies, Node.js version)
5. Create `functions/src/index.ts` scaffold (entry point with function exports)
6. Create `firebase.json` configuration (hosting, functions, Firestore, storage)
7. Create `.env.template` (environment variables: API keys, project ID, region)
8. Expand INFRASTRUCTURE-001 into runnable deployment scripts
9. Create `README-Backend-Setup.md` (developer onboarding: Firebase CLI, deploy, test)
10. Create deployment scripts (`deploy.sh`, `deploy-dev.sh`, `deploy-prod.sh`)

**Outputs**:

- `docs/tech-stack/firestore.rules` (runnable security rules)
- `docs/tech-stack/storage.rules` (runnable storage rules)
- `docs/tech-stack/firestore.indexes.json` (Firestore indexes)
- `docs/tech-stack/functions-package.json` (Cloud Functions dependencies)
- `docs/tech-stack/functions-index-scaffold.ts` (Cloud Functions entry point)
- `docs/tech-stack/firebase.json` (Firebase project configuration)
- `docs/tech-stack/.env.template` (environment variables template)
- `docs/tech-stack/deployment-scripts.md` (deploy.sh specifications)
- `docs/tech-stack/README-Backend-Setup.md` (developer onboarding)
- `docs/checkpoints/CHECKPOINT-stage-4.2.md`

---

### Stage 4.3: AI Pipeline Integration Scaffolding

**Expert Agent**: Computer Vision & ML Engineer

**Purpose**: Generate AI pipeline project structure and provider adapter interfaces

**Input Documents**:

- All Stage 3.3-3.6 outputs (Layer 1-3 research)
- `docs/design/DESIGN-004-computer-vision-pipeline.md`
- `docs/design/AI-INTEGRATION-LAYER-001-cloud-ai-orchestration.md`
- `docs/adr/ADR-014-cloud-ai-provider-selection.md`
- `docs/adr/ADR-015-ai-reasoning-layer-architecture.md`
- `docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md`
- `docs/validation/RESEARCH-VALIDATION-stage-4.3.md` (SDK deprecation identified, migration required)

**Critical Note**: Stage 4.3 includes migration from deprecated `@google-cloud/vertexai` SDK (June 2026 sunset) to current `@google/genai` SDK (v1.29.0+). All code examples and scaffolding use current SDK.

**Tasks**:

1. Create `ai-pipeline/` project structure specification
2. Design AI provider adapter interfaces (hot-swappable design):
   - `IAttributeExtractor` (Gemini 2.5 Flash-Lite)
   - `IProductSearcher` (SerpAPI Google Lens + UPCitemdb)
   - `ILLMParser` (Claude Haiku 4.5)
   - `IAISynthesizer` (Claude Sonnet 4.5)
3. Create configuration files:
   - Vertex AI configuration (project ID, region, model versions)
   - Anthropic API configuration (API keys, model names, batch settings)
   - SerpAPI configuration (API key, timeout, retry policy)
   - UPCitemdb configuration (API key, rate limits)
4. Create cost tracking and monitoring setup (per-request cost logging)
5. Create integration test harness (test each layer independently)
6. Create `README-AI-Pipeline-Setup.md` (setup instructions, API key management)

**Outputs**:

- `docs/tech-stack/ai-pipeline-project-structure.md` (directory layout)
- `docs/tech-stack/ai-provider-adapters.md` (interface specifications)
- `docs/tech-stack/ai-functions-package.json` (Node.js 20 dependencies with @google/genai SDK)
- `docs/tech-stack/tsconfig.ai-pipeline.json` (TypeScript strict mode configuration)
- `docs/tech-stack/.env.ai-pipeline.template` (environment variables for all providers)
- `docs/tech-stack/ai-cost-tracking-setup.md` (monitoring and logging)
- `docs/tech-stack/ai-integration-test-harness.md` (testing approach)
- `docs/tech-stack/GOOGLE-GENAI-SDK-USAGE.md` (current SDK migration from deprecated @google-cloud/vertexai)
- `docs/tech-stack/ai-error-handling-patterns.md` (error taxonomy, dead letter queue)
- `docs/tech-stack/ai-retry-logic-templates.md` (exponential backoff, circuit breaker)
- `docs/tech-stack/ai-batch-processing-setup.md` (Claude Sonnet Batch API for 50% savings)
- `docs/tech-stack/README-AI-Pipeline-Setup.md` (developer onboarding)
- `docs/checkpoints/CHECKPOINT-stage-4.3.md`

---

## PHASE 5: Implementation Planning (REFACTORED 2025-11-12)

**Purpose**: Create document orchestration guide and validate readiness for development.

**Why Refactored**:
- **Original Design**: Generic sprint plans + feature PRDs + agent prompts
- **Problem Identified**: Stage 5.1 refactor makes Stage 5.2 (feature PRDs, agent prompts) redundant
- **New Design**:
  - **Stage 5.1**: Document Orchestration Roadmap (sprint → document → scaffolding mapping)
  - **Stage 5.2**: Pre-Development Readiness Validation (artifact validation, developer onboarding)

**Key Changes**:
1. **Stage 5.1 Refactor** (2025-11-12):
   - Changed from generic task lists to "pull schedule" with explicit mappings
   - Each task now shows: Use (scaffolding) → Read (docs) → Implement (patterns) → Test
   - Eliminates need for separate agent prompts (guidance embedded in sprint plans)

2. **Stage 5.2 Refactor** (2025-11-12):
   - **Dropped**: Feature PRDs (PRD-002 to PRD-010) - redundant with DESIGN-026 to DESIGN-038
   - **Restored with Enhancement**: Agent Prompts (AGENT-PROMPT-001 to 008) - Now include superpowers patterns
     - `/superpowers:write-plan` → `/superpowers:execute-plan` workflow
     - Specialized agent dispatch (general-purpose, code-reviewer, parallel agents)
     - Token management strategies (batch sizing, context loading budgets)
   - **Added**: Pre-development validation (artifact completeness, scaffolding validation, developer onboarding)

**Context Map**: Requires comprehensive context from all Phases 1-4. Use `docs/context-map.json` to load all artifacts.

---

### Stage 5.1: Document Orchestration Roadmap (REFACTORED 2025-11-12)

**Expert Agents**: Software Architecture Expert + Product Strategy & UX

**Purpose**: Create "pull schedule" that maps sprint tasks to existing documents and scaffolding files from Stages 2-4

**Key Transformation** (Why Refactored):
- **Before**: Generic task lists ("Build camera UI", "Implement AI pipeline")
- **After**: Document orchestration guide with explicit mappings:
  - **Use**: Which Stage 4 scaffolding files (Package.swift, firestore.rules, etc.)
  - **Read**: Which ADRs, DESIGN docs, CODE-EXAMPLEs
  - **Implement**: Specific components following patterns
  - **Test**: Following TEST-EXAMPLE patterns

**Input Documents**:

- All Phase 1-4 artifacts (all PLAN-SUMMARY docs, ADRs, DESIGN docs, CODE-EXAMPLES)
- `docs/adr/ADR-003-mvp-scope-phasing.md` (MVP phasing strategy)
- `docs/specs/feature-prioritization-matrix.md`
- `docs/specs/mvp-vision-features.md`
- All Stage 4 scaffolding (Package.swift, firestore.rules, ai-provider-adapters.md, etc.)
- All technical architecture documents

**Tasks**:

1. **Create Feature-to-Document Mapping Matrix**:
   - Map each MVP feature to specific documents from Stages 2-4
   - Show which Stage 4 scaffolding files to use/extend
   - Identify ADRs, DESIGN docs, CODE-EXAMPLEs for each feature
   - Document "use existing" vs "write new code" separation

2. **Create 8-Sprint Roadmap with Document References**:
   - **Sprint 1**: Project Foundation & Authentication (Weeks 1-2)
     - Scaffolding: Package.swift, firebase.json, firestore.rules
     - Documents: ADR-005, ADR-010, CODE-EXAMPLE-003
   - **Sprint 2**: Camera Capture & Vision Layer 1 (Weeks 3-4)
     - Scaffolding: Vision module structure (Stage 4.1)
     - Documents: DESIGN-027, CODE-EXAMPLE-004
   - **Sprint 3**: Backend AI Pipeline (Layers 2a, 2b, 3) (Weeks 5-6)
     - Scaffolding: ai-provider-adapters.md (Stage 4.3)
     - Documents: CODE-EXAMPLEs 007, 010, 013, 016
   - **Sprint 4**: Catalog View & Firestore (Weeks 7-8)
     - Scaffolding: All Stage 4 artifacts
     - Documents: DESIGN-028, CODE-EXAMPLE-002
   - **Sprint 5**: Item Detail & Editing (Weeks 9-10)
   - **Sprint 6**: Profile & Export (Weeks 11-12)
   - **Sprint 7**: UI Polish & Accessibility (Weeks 13-14)
   - **Sprint 8**: Testing & App Store Prep (Weeks 15-16)

3. **Create Sprint Plans with Use → Read → Implement → Test Format**:
   - Each task shows:
     - **Use**: Stage 4 scaffolding files to extend
     - **Read**: Specific documents to study (in priority order)
     - **Implement**: Components per patterns (not generic descriptions)
     - **Test**: Following TEST-EXAMPLE patterns
     - **Validation**: Acceptance criteria from specs
   - Example:
     ```markdown
     Task 3.1: Implement Layer 2a (Attribute Extraction)
     - Use: ai-provider-adapters.md → VertexAIProvider interface
     - Read: CODE-EXAMPLE-010, DESIGN-041 (JSON schema)
     - Implement: attributeExtractor.ts per CODE-EXAMPLE-010
     - Test: Per TEST-EXAMPLE-003 (mock providers)
     - Validation: Cost logged per ai-cost-tracking-setup.md
     ```

4. **Create Dependency Graph**:
   - Critical path (Sprint 1 → 2 → 3 → 4 → 8)
   - Document dependencies (e.g., all iOS tasks need ADR-010 first)
   - Parallel work opportunities (Sprint 5 + 6 can run concurrently)

5. **Create Effort Estimates per Task**:
   - T-shirt sizing (XS: 1-2h, S: 2-4h, M: 4-8h, L: 8-16h, XL: 16-24h)
   - Sprint totals (20-30 hours per 2-week sprint)
   - Buffer time for debugging (20% overhead)

6. **Create Risk Register per Sprint**:
   - Technical risks with mitigation documents (CODE-EXAMPLEs, DESIGN docs)
   - Contingencies with fallback plans

**Outputs**:

- `docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md` (16-week timeline with document orchestration table)
- `docs/roadmap/EPIC-BREAKDOWN-001-features-to-documents.md` (feature → document mapping matrix)
- `docs/roadmap/SPRINT-PLAN-001.md` through `SPRINT-PLAN-008.md` (detailed plans with Use → Read → Implement → Test)
- `docs/roadmap/DEPENDENCY-GRAPH-001.md` (task + document dependencies, critical path)
- `docs/roadmap/EFFORT-ESTIMATES-001.md` (T-shirt sizing per task with sprint totals)
- `docs/roadmap/RISK-REGISTER-001.md` (risks per sprint with mitigation docs)
- `docs/checkpoints/CHECKPOINT-stage-5.1.md`

**Success Criteria**:
- ✅ Every task references specific Stage 4 scaffolding files
- ✅ Every implementation references ADRs, DESIGN docs, CODE-EXAMPLEs
- ✅ No generic tasks ("Build camera") - all show patterns to follow
- ✅ Developers with zero context can start Sprint 1 immediately
- ✅ Clear separation: "use existing scaffolding" vs "write new code"

---

### Stage 5.2: Agent Prompts & Pre-Development Validation (REFACTORED 2025-11-12)

**Expert Agents**: Software Architecture Expert + All Technical Experts (validation + prompt engineering roles)

**Purpose**: Generate superpowers-integrated agent prompts and validate readiness for development

**Why Refactored**:
- **Original Stage 5.2**: Generate feature PRDs (PRD-002 to PRD-010) and basic agent prompts
- **Problems**:
  - Feature PRDs redundant with DESIGN-026 to DESIGN-038
  - Original agent prompts didn't leverage superpowers plugin patterns
  - No token management strategy for large context windows
  - No validation of artifact completeness before development
- **New Purpose**:
  1. Generate superpowers-integrated agent prompts (`/superpowers:write-plan` → `/superpowers:execute-plan`)
  2. Include specialized agent dispatch patterns
  3. Manage token window limits with batching strategies
  4. Validate pre-development readiness

**Input Documents**:

- All Phase 1-4 artifacts (complete spec-kit)
- `docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md` (from Stage 5.1)
- `docs/roadmap/SPRINT-PLAN-001.md` through `SPRINT-PLAN-008.md` (from Stage 5.1)
- All Stage 4 scaffolding files (Package.swift, firestore.rules, ai-provider-adapters.md, etc.)

**Tasks**:

### **Part A: Generate Superpowers-Integrated Agent Prompts**

1. **Generate Agent Prompts with Superpowers Patterns** (8 prompts):

   Each agent prompt follows this structure:

   **AGENT-PROMPT-001: iOS Project Setup & Authentication**
   ```markdown
   # Agent Prompt: iOS Project Setup & Authentication (Sprint 1)

   ## Superpowers Workflow
   1. Run `/superpowers:write-plan` to create detailed implementation plan
   2. Present plan to human for review and approval
   3. Run `/superpowers:execute-plan` to execute in batches with review checkpoints

   ## Context Loading (Token Budget: ~18K)
   Load these documents BEFORE running /superpowers:write-plan:
   - docs/roadmap/SPRINT-PLAN-001.md (Sprint 1 tasks)
   - docs/tech-stack/Package.swift (iOS dependencies)
   - docs/tech-stack/firebase.json (backend configuration)
   - docs/adr/ADR-005-authentication-strategy.md
   - docs/adr/ADR-010-swiftui-architecture-pattern.md
   - docs/design/DESIGN-007-firebase-sdk-integration.md
   - docs/tech-stack/CODE-EXAMPLE-003-firebase-ios-integration.md
   - docs/test/TEST-EXAMPLE-001-viewmodel-unit-tests.md

   ## Specialized Agent Dispatch
   - **General-purpose agent**: iOS project setup, Package.swift integration
   - **General-purpose agent**: Firebase Auth implementation (AuthService, AuthViewModel)
   - **Code-reviewer agent** (after each batch): Review against ADR-010 (MVVM patterns)

   ## Token Management Strategy
   - **Batch 1** (8K tokens): iOS project setup, Package.swift, Xcode workspace
   - **Batch 2** (10K tokens): Firebase Auth implementation (AuthService, AuthViewModel)
   - **Batch 3** (5K tokens): Unit tests per TEST-EXAMPLE-001
   - Between batches: Human review checkpoint via /superpowers:execute-plan

   ## Success Criteria
   - ✅ iOS app compiles without errors (`swift build`)
   - ✅ Firebase Auth integrated (user can sign in with Apple)
   - ✅ Unit tests pass (80%+ coverage on AuthViewModel)
   ```

   **AGENT-PROMPT-002: Camera Capture & Vision Layer 1**
   ```markdown
   # Agent Prompt: Camera Capture & Vision Layer 1 (Sprint 2)

   ## Superpowers Workflow
   1. Run `/superpowers:write-plan` with context below
   2. Execute plan in batches with `/superpowers:execute-plan`
   3. Dispatch specialized agents for Vision Framework complexity

   ## Context Loading (Token Budget: ~22K)
   - docs/roadmap/SPRINT-PLAN-002.md
   - docs/design/DESIGN-027-camera-capture-view-specification.md
   - docs/design/DESIGN-013-vision-framework-integration-patterns.md
   - docs/tech-stack/CODE-EXAMPLE-004-vision-framework-patterns.md
   - docs/tech-stack/CODE-EXAMPLE-009-household-item-detector.md
   - docs/test/TEST-EXAMPLE-004-ml-cv-testing-patterns.md
   - docs/design/DESIGN-039-layer-1-performance-optimization.md

   ## Specialized Agent Dispatch
   - **General-purpose agent**: CameraView UI implementation (SwiftUI + AVFoundation)
   - **General-purpose agent**: VisionService implementation (VNCoreMLRequest + YOLOv3-Tiny)
   - **General-purpose agent**: Barcode detection (VNDetectBarcodesRequest)
   - **Code-reviewer agent**: Review Vision Framework concurrency patterns (@MainActor, Task.detached)

   ## Token Management Strategy
   - **Batch 1** (10K tokens): CameraView UI (AVFoundation preview, capture button)
   - **Batch 2** (12K tokens): VisionService (object detection, bounding boxes, cropping)
   - **Batch 3** (8K tokens): Barcode detection integration
   - **Batch 4** (6K tokens): Unit tests (Vision Framework mocks)

   ## Success Criteria
   - ✅ Camera captures photos (full image + cropped objects)
   - ✅ Vision Framework detects objects with bounding boxes
   - ✅ Barcode scanning works (UPC, EAN-13, QR codes)
   - ✅ Performance: < 500ms detection latency on iPhone 14+
   ```

   **AGENT-PROMPT-003: Backend AI Pipeline (Layers 2a, 2b, 3)**
   ```markdown
   # Agent Prompt: Backend AI Pipeline Implementation (Sprint 3)

   ## Superpowers Workflow
   1. Run `/superpowers:write-plan` with AI pipeline context
   2. Execute in batches via `/superpowers:execute-plan`
   3. Use **superpowers:dispatching-parallel-agents** for independent layers

   ## Context Loading (Token Budget: ~25K)
   - docs/roadmap/SPRINT-PLAN-003.md
   - docs/design/DESIGN-004-computer-vision-pipeline.md
   - docs/tech-stack/ai-provider-adapters.md (interface specifications)
   - docs/tech-stack/CODE-EXAMPLE-007-ai-pipeline-orchestration.md
   - docs/tech-stack/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md
   - docs/tech-stack/CODE-EXAMPLE-013-serpapi-google-lens.md
   - docs/tech-stack/CODE-EXAMPLE-016-claude-sonnet-synthesis.md
   - docs/design/DESIGN-041-layer-2a-json-schema.md
   - docs/test/TEST-EXAMPLE-003-cloud-functions-testing.md

   ## Specialized Agent Dispatch (PARALLEL)
   Since Layers 2a, 2b, 3 can be implemented independently:
   - Use `/superpowers:dispatching-parallel-agents` to dispatch 3 agents:
     - **Agent A**: Layer 2a (Vertex AI attribute extraction)
     - **Agent B**: Layer 2b (SerpAPI + UPCitemdb product search)
     - **Agent C**: Layer 3 (Claude Sonnet synthesis)
   - After parallel work completes: 1 agent for orchestration (Layer 1 → 2a+2b → 3)

   ## Token Management Strategy
   - **Parallel Batch 1** (3 agents, 8K tokens each):
     - Agent A: Layer 2a implementation
     - Agent B: Layer 2b implementation
     - Agent C: Layer 3 implementation
   - **Sequential Batch 2** (10K tokens): Pipeline orchestration (onItemCreated trigger)
   - **Sequential Batch 3** (8K tokens): Integration tests (Firebase Emulator)

   ## Success Criteria
   - ✅ Layer 2a: Attribute extraction works (category 87%, color 83%, material 80%)
   - ✅ Layer 2b: Barcode-first reduces costs by 22.6%
   - ✅ Layer 3: Conflict resolution works (vision vs product search mismatches)
   - ✅ End-to-end: Full pipeline completes in < 6 seconds
   ```

   **AGENT-PROMPT-004 through 008**: Similar structure for remaining sprints
   - **004**: Catalog View & Firestore Integration (Sprint 4)
   - **005**: Item Detail View & Editing (Sprint 5)
   - **006**: Profile & Export Functionality (Sprint 6)
   - **007**: UI Polish & Accessibility (Sprint 7)
   - **008**: Testing & App Store Prep (Sprint 8)

2. **Define Token Budget Strategy**:
   - Calculate total token requirements per sprint (context loading + execution)
   - Sprint 1-2: ~20K tokens (iOS-heavy, CODE-EXAMPLEs)
   - Sprint 3: ~25K tokens (AI pipeline, multiple CODE-EXAMPLEs)
   - Sprint 4-6: ~18K tokens (UI implementation)
   - Sprint 7-8: ~15K tokens (testing, polish)

3. **Define Specialized Agent Dispatch Patterns**:
   - **General-purpose agent**: Default for most implementation tasks
   - **Code-reviewer agent**: After each batch completion (review against ADRs, DESIGN docs)
   - **Parallel agent dispatch**: Sprint 3 (independent AI layers), Sprint 4 (iOS + Backend work)
   - **Systematic-debugging agent**: If tests fail or errors occur

### **Part B: Pre-Development Readiness Validation**

4. **Validate Artifact Completeness**:
   - Cross-check all Phase 1-4 outputs vs expected outputs in context-map.json
   - Verify all ADRs (ADR-001 to ADR-023) are consistent
   - Confirm all DESIGN docs (DESIGN-004 to DESIGN-043) cross-reference correctly
   - Validate all CODE-EXAMPLEs (001 to 018) and TEST-EXAMPLEs (001 to 007) exist

5. **Validate Scaffolding Files Compile/Deploy**:
   - **iOS**: Validate Package.swift resolves dependencies (`swift package resolve`)
   - **iOS**: Validate SwiftLint configuration passes (`swiftlint lint --config docs/tech-stack/.swiftlint.yml`)
   - **Backend**: Validate Firestore rules syntax (`firebase deploy --only firestore:rules --dry-run`)
   - **Backend**: Validate Storage rules syntax (`firebase deploy --only storage --dry-run`)
   - **Backend**: Validate functions package.json dependencies (`npm install` in functions/)
   - **AI Pipeline**: Validate TypeScript configuration (`tsc --noEmit` with tsconfig.ai-pipeline.json)

6. **Validate Roadmap Completeness**:
   - Verify all Sprint 1-8 plans reference existing documents (no broken links)
   - Confirm all tasks have Use → Read → Implement → Test guidance
   - Validate dependency graph is acyclic (no circular dependencies)
   - Check effort estimates sum to reasonable totals (120-150 hours developer time)

7. **Generate Development Readiness Checklist**:
   - Document prerequisites (Xcode 16.2+, Node.js 20+, Firebase CLI 13.0+)
   - Superpowers plugin installation (`claude mcp list` to verify)
   - API key requirements (Firebase project, Vertex AI, Anthropic, SerpAPI, UPCitemdb)
   - Environment setup steps (Apple Developer account, GCP project, Firebase project)
   - Pre-development verification commands

8. **Generate Quick Start Guide**:
   - "Day 1" setup instructions for new developers
   - Clone → Install → Configure → Build → Deploy (dev environment)
   - First task walkthrough using AGENT-PROMPT-001 (Sprint 1, iOS Setup)
   - Superpowers workflow demonstration (`/superpowers:write-plan` → `/superpowers:execute-plan`)
   - Troubleshooting common issues (Swift 6 concurrency, Firebase @preconcurrency)

9. **Generate E2E Integration Test Plan**:
   - **TEST-003**: E2E User Flows (onboarding → capture → catalog → export)
   - **TEST-004**: AI Pipeline Integration Testing (Layer 1 → 2a+2b → 3 → Firestore)
   - **TEST-005**: Cross-Platform Testing (iOS device matrix, OS versions)
   - **TEST-006**: Performance & Load Testing (concurrent users, AI latency, Firestore throughput)

10. **Document Git Workflow & PR Automation**:
   - **Git Branching Strategy**: Feature branch per sprint task (`feature/sprint-X-task-Y-description`)
   - **Branch Creation Timing**: Create branch BEFORE running `/superpowers:write-plan`
   - **PR Creation Timing**: Create PR AFTER `/superpowers:execute-plan` completes and code-reviewer approves
   - **PR Template**: Include links to sprint plan, ADRs, DESIGN docs, success criteria checklist
   - **Code Review Integration**: How `superpowers:requesting-code-review` triggers PR-based review
   - **Merge Strategy**: Squash merge with conventional commit messages

11. **Document Sprint Execution Workflow**:
   - **Pre-Sprint Setup**: Git worktree creation, branch initialization, context loading
   - **Sprint Execution Loop**:
     1. Load sprint plan + referenced documents
     2. Run `/superpowers:write-plan` to generate implementation plan
     3. Human review and approval
     4. Run `/superpowers:execute-plan` in batches with checkpoints
     5. Run `superpowers:requesting-code-review` after completion
     6. Address review feedback
     7. Create PR with links to artifacts
     8. Merge on approval
   - **Post-Sprint Cleanup**: Git worktree cleanup, branch deletion, checkpoint documentation

12. **Document Apple-Docs-Fetcher Integration** (iOS Sprints Only):
   - **Pre-Sprint Detection**: Read sprint plan, identify iOS work (Vision Framework, SwiftUI, AVFoundation)
   - **Apple Docs Validation**: Check if `docs/apple/` exists and is fresh (< 30 days)
   - **Automatic Fetching**: If iOS work detected and docs missing/stale → run `apple-docs-fetcher`
   - **Focused API List**: Extract 3-5 specific APIs from sprint plan (not broad frameworks)
   - **Token Budget Enforcement**: 8K tokens per API, 25K max for apple-docs-fetcher
   - **Context Loading**: Add fetched docs to context before `/superpowers:write-plan`
   - **Fallback Handling**: If fetch fails → error with clear instructions to run manually

**Outputs**:

### **Part A: Superpowers-Integrated Agent Prompts**
- `docs/agent-prompts/AGENT-PROMPT-001-ios-project-setup-authentication.md` (Sprint 1: iOS + Firebase Auth)
- `docs/agent-prompts/AGENT-PROMPT-002-camera-capture-vision-layer-1.md` (Sprint 2: Camera + Vision Framework)
- `docs/agent-prompts/AGENT-PROMPT-003-backend-ai-pipeline.md` (Sprint 3: Layers 2a, 2b, 3 with parallel dispatch)
- `docs/agent-prompts/AGENT-PROMPT-004-catalog-view-firestore.md` (Sprint 4: Catalog UI + Firestore integration)
- `docs/agent-prompts/AGENT-PROMPT-005-item-detail-editing.md` (Sprint 5: Item detail + manual editing)
- `docs/agent-prompts/AGENT-PROMPT-006-profile-export.md` (Sprint 6: Profile + CSV/JSON export)
- `docs/agent-prompts/AGENT-PROMPT-007-ui-polish-accessibility.md` (Sprint 7: UI polish + WCAG compliance)
- `docs/agent-prompts/AGENT-PROMPT-008-testing-app-store-prep.md` (Sprint 8: E2E tests + App Store submission)
- `docs/agent-prompts/SUPERPOWERS-PATTERNS-GUIDE.md` (Best practices: write-plan → execute-plan, parallel dispatch)
- `docs/agent-prompts/TOKEN-BUDGET-STRATEGY.md` (Token management across all 8 sprints)

### **Part B: Pre-Development Validation**
- `docs/validation/READINESS-VALIDATION-REPORT-001.md` (artifact completeness check, issues found)
- `docs/validation/SCAFFOLDING-VALIDATION-REPORT-001.md` (compile/deploy test results)
- `docs/validation/DEVELOPMENT-READINESS-CHECKLIST-001.md` (prerequisites, setup steps, superpowers verification)
- `docs/validation/QUICK-START-GUIDE-001.md` (Day 1 developer onboarding with superpowers workflow demo)
- `docs/validation/DEVELOPMENT-WORKFLOW-001-git-branching-strategy.md` (feature branch per task, naming conventions, merge strategy)
- `docs/validation/DEVELOPMENT-WORKFLOW-002-pr-creation-automation.md` (PR templates, code review integration, approval gates)
- `docs/validation/DEVELOPMENT-WORKFLOW-003-sprint-execution-guide.md` (end-to-end workflow from sprint start to PR merge)
- `docs/validation/IOS-DEVELOPMENT-WORKFLOW-001-apple-docs-integration.md` (automatic apple-docs-fetcher triggering for iOS sprints)
- `docs/test/TEST-003-e2e-user-flows.md` (E2E integration test plan)
- `docs/test/TEST-004-ai-pipeline-integration-testing.md` (AI pipeline test plan)
- `docs/test/TEST-005-cross-platform-testing.md` (iOS device matrix testing)
- `docs/test/TEST-006-performance-load-testing.md` (performance benchmarks)
- `docs/checkpoints/CHECKPOINT-stage-5.2.md`

**Success Criteria**:
- ✅ All 8 agent prompts follow superpowers best practices (`/superpowers:write-plan` → `/superpowers:execute-plan`)
- ✅ Token budgets calculated per sprint (18K-25K tokens, within limits)
- ✅ Specialized agent dispatch patterns documented (general-purpose, code-reviewer, parallel agents)
- ✅ Parallel dispatch identified for Sprint 3 (AI layers) and Sprint 4 (iOS + Backend)
- ✅ All Phase 1-4 artifacts accounted for (zero missing documents)
- ✅ All scaffolding files validate without errors (Package.swift resolves, firestore.rules deploy)
- ✅ All sprint plans reference existing documents (no broken links)
- ✅ Development prerequisites documented with superpowers plugin verification
- ✅ Quick Start Guide tested with fresh developer (< 2 hours to first build, superpowers workflow demo)
- ✅ Git workflow documented (feature branch per task, PR creation timing, merge strategy)
- ✅ Sprint execution workflow documented (pre-sprint setup → execution loop → post-sprint cleanup)
- ✅ Apple-docs-fetcher integration documented for iOS sprints (automatic detection, fetching, context loading)
- ✅ PR templates include links to sprint plan, ADRs, DESIGN docs, and success criteria

**Restored from Original Stage 5.2** (Why):
- ✅ **Agent Prompts (AGENT-PROMPT-001 to 008)**: RESTORED with superpowers integration
  - **Reason**: Stage 5.1 sprint plans provide "what to do", agent prompts provide "how to execute with superpowers"
  - **Enhancement**: Now include `/superpowers:write-plan` → `/superpowers:execute-plan` workflow
  - **Enhancement**: Include specialized agent dispatch patterns (general-purpose, code-reviewer, parallel)
  - **Enhancement**: Include token management strategies (batch sizing, context loading)

**Dropped from Original Stage 5.2** (Why):
- ❌ **Feature PRDs (PRD-002 to PRD-010)**: Redundant with DESIGN-026 to DESIGN-038
- ❌ **Acceptance Criteria Checklist**: Embedded in sprint plans and DESIGN docs

---

### Stage 5.3: Project Initialization & CI/CD Pipeline (NEW 2025-11-12)

**Expert Agents**: DevOps Engineer + Software Architecture Expert

**Purpose**: Set up repository infrastructure, CI/CD automation, and development tooling for deterministic agentic development

**Why Added**:
- **Original Design**: No stage for repository setup and CI/CD automation
- **User Request**: GitHub Actions automation similar to mids-hero-web (documentation generation, spec validation)
- **Benefit**: Enables automated validation of agent-generated code, documentation generation on PR merge, and continuous deployment

**Input Documents**:

- Stage 5.2 outputs (all workflow documentation)
- Stage 4 scaffolding files (Package.swift, firebase.json, firestore.rules, etc.)
- All ADRs (especially ADR-009-ios-deployment-cicd.md if exists)
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`

**Tasks**:

1. **Define GitHub Actions Workflow Architecture**:
   - **Workflow 1: Spec Validation** (runs on PR to `docs/**`)
     - Validates markdown syntax
     - Checks cross-references (ADR-XXX, DESIGN-XXX links exist)
     - Runs spec-lint validation
     - Verifies ADR numbering sequence
   - **Workflow 2: iOS Build Validation** (runs on PR to `ios/**` or `Package.swift`)
     - `swift package resolve` (dependency resolution)
     - `swift build` (compilation check)
     - `swiftlint` validation
     - `swift test` (unit tests)
   - **Workflow 3: Backend Validation** (runs on PR to `functions/**`)
     - `npm install` in functions directory
     - `firebase deploy --only firestore:rules --dry-run`
     - `firebase deploy --only storage --dry-run`
     - TypeScript compilation (`tsc --noEmit`)
     - Firebase emulator tests
   - **Workflow 4: AI Pipeline Validation** (runs on PR to AI pipeline code)
     - TypeScript compilation with `tsconfig.ai-pipeline.json`
     - Integration tests with mocked AI providers
     - Cost estimation validation (token counts within budget)
   - **Workflow 5: Documentation Generation** (runs on merge to `main`)
     - Auto-generate API documentation from code comments
     - Update CHANGELOG.md from conventional commits
     - Generate dependency graphs from CODE-EXAMPLEs
     - Deploy docs to GitHub Pages (optional)

2. **Create GitHub Actions Workflow Files**:
   - `.github/workflows/spec-validation.yml`
   - `.github/workflows/ios-build-check.yml`
   - `.github/workflows/backend-validation.yml`
   - `.github/workflows/ai-pipeline-validation.yml`
   - `.github/workflows/docs-generation.yml`

3. **Define PR Templates**:
   - **Feature PR Template** (`.github/PULL_REQUEST_TEMPLATE/feature.md`):
     - Sprint task reference (Sprint X, Task Y)
     - Links to sprint plan, ADRs, DESIGN docs
     - Success criteria checklist from sprint plan
     - Testing evidence (screenshots, test results)
     - Agent execution summary (superpowers:execute-plan output)
   - **Documentation PR Template** (`.github/PULL_REQUEST_TEMPLATE/documentation.md`):
     - Stage reference (Stage X.X)
     - Checkpoint reference
     - Artifact list with cross-references validated
   - **Hotfix PR Template** (`.github/PULL_REQUEST_TEMPLATE/hotfix.md`):
     - Issue reference
     - Root cause analysis
     - Testing validation

4. **Define Issue Templates**:
   - `.github/ISSUE_TEMPLATE/bug_report.yml` (structured bug reports)
   - `.github/ISSUE_TEMPLATE/feature_request.yml` (feature proposals)
   - `.github/ISSUE_TEMPLATE/sprint_task.yml` (sprint task tracking)

5. **Create Branch Protection Rules Documentation**:
   - **Main Branch**:
     - Require PR approval (1+ reviewers)
     - Require status checks (all CI workflows pass)
     - Require conversation resolution
     - No force push
     - No deletion
   - **Development Branch** (if using):
     - Require PR approval
     - Status checks optional (for experimentation)

6. **Create Dependabot Configuration**:
   - `.github/dependabot.yml`:
     - Swift Package Manager updates (weekly)
     - npm updates for Cloud Functions (weekly)
     - GitHub Actions updates (monthly)
     - Auto-merge minor/patch updates after CI passes

7. **Create Repository Initialization Checklist**:
   - GitHub repository setup (visibility, description, topics)
   - Branch protection rules applied
   - GitHub Actions secrets configured (Firebase, Anthropic, SerpAPI keys)
   - Dependabot enabled
   - GitHub Pages enabled (for documentation)
   - Repository settings (merge strategies, auto-delete head branches)

8. **Document Local Development Setup**:
   - Pre-commit hooks (run spec-lint, swiftlint before commit)
   - Git hooks installation script
   - Environment validation script (check Xcode, Node.js, Firebase CLI versions)
   - Developer machine setup guide (from scratch to first PR)

9. **Create Cost Monitoring Automation** (Optional but Recommended):
   - GitHub Action to track AI API usage per PR
   - Alert if PR exceeds budget (based on COST-MODEL-001)
   - Monthly cost reporting (aggregate across all PRs)

**Outputs**:

- `.github/workflows/spec-validation.yml` (spec-lint, cross-reference validation)
- `.github/workflows/ios-build-check.yml` (swift build, swiftlint, swift test)
- `.github/workflows/backend-validation.yml` (Firebase rules validation, emulator tests)
- `.github/workflows/ai-pipeline-validation.yml` (TypeScript compilation, integration tests)
- `.github/workflows/docs-generation.yml` (auto-generate docs on merge)
- `.github/PULL_REQUEST_TEMPLATE/feature.md` (feature PR template with sprint references)
- `.github/PULL_REQUEST_TEMPLATE/documentation.md` (documentation PR template)
- `.github/PULL_REQUEST_TEMPLATE/hotfix.md` (hotfix PR template)
- `.github/ISSUE_TEMPLATE/bug_report.yml` (structured bug reports)
- `.github/ISSUE_TEMPLATE/feature_request.yml` (feature proposals)
- `.github/ISSUE_TEMPLATE/sprint_task.yml` (sprint task tracking)
- `.github/dependabot.yml` (automated dependency updates)
- `.claude/docs/GITHUB-ACTIONS-ARCHITECTURE-001.md` (workflow architecture overview)
- `.claude/docs/BRANCH-PROTECTION-RULES-001.md` (branch protection configuration)
- `.claude/docs/REPOSITORY-SETUP-CHECKLIST-001.md` (GitHub repo initialization steps)
- `.claude/docs/LOCAL-DEV-SETUP-001.md` (pre-commit hooks, git hooks, environment validation)
- `.claude/docs/COST-MONITORING-AUTOMATION-001.md` (AI cost tracking per PR)
- `scripts/setup-git-hooks.sh` (install pre-commit hooks)
- `scripts/validate-environment.sh` (check developer machine prerequisites)
- `docs/checkpoints/CHECKPOINT-stage-5.3.md`

**Success Criteria**:
- ✅ All 5 GitHub Actions workflows defined and tested (spec, iOS, backend, AI pipeline, docs)
- ✅ PR templates include sprint references, ADR links, success criteria checklists
- ✅ Branch protection rules documented (main branch requires approval + CI passing)
- ✅ Dependabot configured for Swift, npm, and GitHub Actions updates
- ✅ Pre-commit hooks catch spec-lint and swiftlint errors before push
- ✅ Environment validation script checks all prerequisites (Xcode 16.2+, Node.js 20+, Firebase CLI 13.0+)
- ✅ Cost monitoring tracks AI usage per PR and alerts on budget overruns
- ✅ Repository initialization checklist tested with fresh GitHub repo (< 1 hour setup)

**Relationship to Sprint Execution**:
- **Stage 5.3 can run in parallel with Sprint 1-2** (non-blocking)
- **Recommended timing**: Execute Stage 5.3 during Sprint 1 (iOS setup) so CI/CD is ready for Sprint 2
- **Dependencies**: Stage 5.3 requires Stage 5.2 workflow documentation to design PR templates correctly

**Inspiration from mids-hero-web**:
- Documentation auto-generation on PR merge (similar to mids-hero-web docs workflow)
- Spec validation on PR (ensures agent-generated docs follow conventions)
- ADR validation (ensures numbering sequence and cross-references)
- Cost tracking (extends mids-hero-web approach with AI-specific cost monitoring)

---

## PHASE 6: Technology Validation (Catalog Pipeline)

**Purpose**: Test and validate actual technology capabilities before/during sprint implementation. Ensures technology assumptions are verified through functional tests, performance benchmarks, integration validation, and capability discovery before committing to implementation.

**Structure**: Sub-stages per catalog pipeline layer (Layer 1, 2a, 2b, 3)

**Timing**: Parallel to sprint implementation (Workflow B: Plan sprint → Validate tech → Review report → Implement or pivot)

**Context Map**: Each validation stage requires specific artifacts from Phases 2-4. Use `docs/context-map.json` to load required documents before validation execution.

---

### Stage 6.0: Master Validation Document

**Expert Agent**: Software Architecture Expert

**Purpose**: Create high-level validation strategy and tracking document for all layer validations

**Input Documents**:

- All Phase 2-4 artifacts (tech stack, architecture, implementation research)
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`
- `docs/design/DESIGN-004-computer-vision-pipeline.md`
- `docs/roadmap/SPRINT-PLAN-002.md` through `SPRINT-PLAN-004.md` (AI pipeline sprints)

**Tasks**:

1. Define validation strategy across all 4 layers (1, 2a, 2b, 3)
2. Create dependency graph (Layer 2 requires Layer 1 output for integration tests)
3. Document test categories per layer (functional, performance, integration, capability discovery)
4. Establish success criteria baselines (what makes a test "pass"?)
5. Define validation workflow integration with sprint execution

**Outputs**:

- `docs/validation/VALIDATION-MASTER-001.md` (master index with high-level strategy)
- `docs/checkpoints/CHECKPOINT-stage-6.0.md`

**Master Document Structure**:

```markdown
# Technology Validation Master Index

## Overview
High-level explanation of validation strategy, workflow integration, success criteria.

## Validation Stages

### Stage 6.1: Layer 1 (iOS On-Device)
- **Tests**: Multi-object detection, barcode detection, bounding boxes, streaming
- **Benchmarks**: Detection accuracy, latency, memory usage
- **Status**: [Not Started | In Progress | Complete | Blocked]
- **Documents**: TEST-LAYER1-001, BENCHMARK-LAYER1-001, VALIDATION-LAYER1-001

### Stage 6.2: Layer 2a (Backend Cloud Processing)
- **Tests**: Image preprocessing, storage, queue management
- **Benchmarks**: API latency, throughput, cost per request
- **Status**: [Not Started | In Progress | Complete | Blocked]
- **Documents**: TEST-LAYER2A-001, BENCHMARK-LAYER2A-001, VALIDATION-LAYER2A-001

### Stage 6.3: Layer 2b (Product Search)
- **Tests**: Barcode lookup, visual search, LLM parsing
- **Benchmarks**: Accuracy, API costs, latency
- **Status**: [Not Started | In Progress | Complete | Blocked]
- **Documents**: TEST-LAYER2B-001, BENCHMARK-LAYER2B-001, VALIDATION-LAYER2B-001

### Stage 6.4: Layer 3 (AI Synthesis)
- **Tests**: Conflict resolution, confidence scoring, Firestore integration
- **Benchmarks**: Synthesis accuracy, batch latency, cost per item
- **Status**: [Not Started | In Progress | Complete | Blocked]
- **Documents**: TEST-LAYER3-001, BENCHMARK-LAYER3-001, VALIDATION-LAYER3-001

## Dependency Graph
- Layer 2a integration tests depend on Layer 1 output
- Layer 2b integration tests depend on Layer 2a output
- Layer 3 integration tests depend on Layer 2b output

## Cross-Layer Findings
[Constraints or capabilities that affect multiple layers]
```

---

### Stage 6.1: Layer 1 Validation (iOS On-Device)

**Expert Agent**: iOS Architecture Expert + Computer Vision & ML Engineer

**Purpose**: Validate Layer 1 (on-device Vision + YOLO + barcode) capabilities before Sprint 2 implementation

**Input Documents**:

- `docs/design/DESIGN-004-computer-vision-pipeline.md` (Layer 1 architecture)
- `docs/design/CODE-EXAMPLE-009-household-item-detector.md` (Layer 1 implementation patterns)
- `docs/design/DESIGN-039-layer-1-performance-optimization.md`
- `docs/adr/ADR-013-vision-framework-strategy.md`
- `docs/roadmap/SPRINT-PLAN-002.md` (Camera + Vision Layer 1)

**Tasks**:

1. **Create Test Specifications** (TEST-LAYER1-001):
   - Functional: Multi-object detection (1, 3, 5, 10, 15+ objects)
   - Functional: Barcode detection (UPC, EAN-13, QR codes, various angles)
   - Functional: Bounding box accuracy (overlap, cropping precision)
   - Integration: Layer 1 output matches Layer 2a input schema (DESIGN-041)
   - Capability Discovery: Streaming vs batch mode (AVCaptureSession real-time vs photo capture)
   - Capability Discovery: YOLO-v3 tiny object recognition baseline (18 household classes)

2. **Create Benchmark Definitions** (BENCHMARK-LAYER1-001):
   - Detection accuracy (% objects detected correctly per photo)
   - Detection latency (ms from capture to results)
   - Memory usage (MB peak during processing)
   - Battery impact (mAh per detection)
   - Upper/lower bounds (max objects, min lighting conditions)

3. **Implement Tests** (iOS XCTest suite):
   - Unit tests: VisionService methods (object detection, bounding boxes)
   - Integration tests: Camera → Vision → JSON output
   - Performance tests: XCTest measure blocks (latency, memory)
   - Test fixtures: Curated image sets (varied objects, lighting, angles)

4. **Run Validation & Generate Report** (VALIDATION-LAYER1-001):
   - Execute tests with test fixtures
   - Collect benchmark data
   - Identify edge cases (failures, accuracy drops)
   - Recommend actions (ADR updates, design changes, blockers, limitations)

**Outputs**:

- `docs/validation/layer1/TEST-LAYER1-001.md` (test specifications)
- `docs/validation/layer1/BENCHMARK-LAYER1-001.md` (benchmark definitions)
- `ios/AbundanceTests/Layer1ValidationTests/` (XCTest suite + fixtures)
- `docs/validation/layer1/VALIDATION-LAYER1-001.md` (validation report with pass/fail, benchmarks, recommended actions)
- `docs/checkpoints/CHECKPOINT-stage-6.1.md`

**Test Specification Format** (Given/When/Then + Contract Validation + Exploratory):

| ID | Test Case | Given | When | Then | Priority |
|----|-----------|-------|------|------|----------|
| FT-L1-001 | Multi-object detection | Photo with 3 distinct objects | Process with Vision API | Detects all 3 objects | P0 |
| IT-L1-001 | Layer 1→2a interface | Raw image | Process and output JSON | JSON matches DESIGN-041 schema | P0 |
| CD-L1-001 | Streaming vs batch? | Test AVCaptureSession real-time | Measure latency | Document if < 200ms | P1 |

**Validation Report Structure**:

```markdown
# VALIDATION-LAYER1-001: Layer 1 On-Device Processing Validation Report

## Executive Summary
[Pass/fail status, key findings, go/no-go recommendation]

## Functional Test Results
- ✅ Multi-object detection: Pass (5 objects detected reliably, 10+ degrades to 60%)
- ✅ Barcode detection: Pass (UPC/EAN-13 90%+, angled barcodes 70%)
- ⚠️ Streaming mode: Degraded (3x slower than batch, acceptable for MVP)

## Benchmark Results
- Detection accuracy: 85% (target: 80%+) ✅
- Detection latency: 450ms (target: < 500ms) ✅
- Memory usage: 120MB peak (target: < 150MB) ✅
- Max objects per photo: 5 reliably, 10 degrades ⚠️

## Discovered Constraints
- **Constraint**: Max 5 objects detected reliably per photo
- **Impact**: Update DESIGN-004 with limit; consider multi-shot feature (PRD-012)

## Recommended Actions
### Critical Issues (Blockers)
- None

### Design Updates
- Update DESIGN-004: Document 5-object limit
- Add PRD-012: Multi-shot capture mode (future enhancement)

### Performance Gaps
- Streaming mode 3x slower (600ms vs 200ms) - acceptable for MVP

### Architecture Changes
- None required

## Go/No-Go Recommendation
**GO** - Layer 1 meets functional and performance requirements for MVP. 5-object limit acceptable with multi-shot enhancement in roadmap.
```

---

### Stage 6.2: Layer 2a Validation (Attribute Extraction)

**Expert Agent**: Computer Vision & ML Engineer

**Purpose**: Validate Layer 2a (Gemini 2.5 Flash-Lite attribute extraction) before Sprint 3 implementation

**Input Documents**:

- `docs/design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md`
- `docs/design/DESIGN-041-layer-2a-json-schema.md`
- `docs/research/BENCHMARK-002-layer-2a-accuracy-methodology.md`
- `docs/adr/ADR-014-cloud-ai-provider-selection.md`

**Tasks**:

1. Create test specifications (functional, performance, integration)
2. Create benchmark definitions (accuracy thresholds, cost per request, latency)
3. Implement tests (Jupyter notebooks with mock data + real Vertex AI calls)
4. Generate validation report (pass/fail, benchmarks, recommended actions)

**Outputs**:

- `docs/validation/layer2a/TEST-LAYER2A-001.md`
- `docs/validation/layer2a/BENCHMARK-LAYER2A-001.md`
- `notebooks/validation/layer2a/layer2a_validation.ipynb` (Jupyter notebook)
- `docs/validation/layer2a/VALIDATION-LAYER2A-001.md`
- `docs/checkpoints/CHECKPOINT-stage-6.2.md`

---

### Stage 6.3: Layer 2b Validation (Product Search)

**Expert Agent**: Cloud Backend Architect + Computer Vision & ML Engineer

**Purpose**: Validate Layer 2b (SerpAPI + UPCitemdb + Claude Haiku parsing) before Sprint 3 implementation

**Input Documents**:

- `docs/design/CODE-EXAMPLE-013-serpapi-google-lens.md`
- `docs/design/CODE-EXAMPLE-014-claude-haiku-parsing.md`
- `docs/adr/ADR-018-barcode-product-lookup-strategy.md`

**Tasks**:

1. Create test specifications (barcode-first dual-mode strategy)
2. Create benchmark definitions (accuracy, cost per lookup, latency)
3. Implement tests (Jupyter notebooks with real API calls)
4. Generate validation report (barcode cost savings, accuracy)

**Outputs**:

- `docs/validation/layer2b/TEST-LAYER2B-001.md`
- `docs/validation/layer2b/BENCHMARK-LAYER2B-001.md`
- `notebooks/validation/layer2b/layer2b_validation.ipynb`
- `docs/validation/layer2b/VALIDATION-LAYER2B-001.md`
- `docs/checkpoints/CHECKPOINT-stage-6.3.md`

---

### Stage 6.4: Layer 3 Validation (AI Synthesis)

**Expert Agent**: Computer Vision & ML Engineer

**Purpose**: Validate Layer 3 (Claude Sonnet 4.5 synthesis + conflict resolution) before Sprint 3 implementation

**Input Documents**:

- `docs/design/CODE-EXAMPLE-016-claude-sonnet-synthesis.md`
- `docs/design/CODE-EXAMPLE-017-conflict-resolution-patterns.md`
- `docs/adr/ADR-015-ai-reasoning-layer-architecture.md`

**Tasks**:

1. Create test specifications (conflict resolution, confidence scoring)
2. Create benchmark definitions (synthesis accuracy, batch latency, cost per item)
3. Implement tests (Jupyter notebooks with real Claude Sonnet API calls)
4. Generate validation report (end-to-end pipeline validation)

**Outputs**:

- `docs/validation/layer3/TEST-LAYER3-001.md`
- `docs/validation/layer3/BENCHMARK-LAYER3-001.md`
- `notebooks/validation/layer3/layer3_validation.ipynb`
- `docs/validation/layer3/VALIDATION-LAYER3-001.md`
- `docs/checkpoints/CHECKPOINT-stage-6.4.md`

---

## Sprint Integration (Workflow B: Plan → Validate → Implement)

**Validation workflow per sprint**:

1. **Plan Sprint Features**: Use Phase 5 roadmap (SPRINT-PLAN-00X)
2. **Execute Validation Stage**: Run Stage 6.X for relevant layer
   - Task 1: Run functional tests (TEST-LAYERX-001)
   - Task 2: Run benchmarks (if functional tests pass)
   - Task 3: Generate validation report (VALIDATION-LAYERX-001)
3. **Review Validation Report**: Assess results
   - **GO**: Functional tests pass, benchmarks meet targets → Proceed to implementation
   - **PIVOT**: Functional tests pass, benchmarks reveal constraints → Update ADRs/designs, adjust sprint plan
   - **NO-GO**: Functional tests fail → Halt sprint, escalate to architecture review, identify alternatives
4. **Implement Sprint**: Execute implementation with validated constraints and capabilities

**Validation Report Decision Matrix**:

| Validation Result | Action | Example |
|-------------------|--------|---------|
| ✅ All tests pass, benchmarks meet targets | **GO**: Proceed to implementation | Layer 1: 85% accuracy (target 80%+), proceed to Sprint 2 |
| ⚠️ Tests pass, benchmarks reveal constraints | **PIVOT**: Update designs, document limitations | Layer 1: Max 5 objects detected → Update DESIGN-004, add multi-shot feature to roadmap |
| ❌ Critical tests fail | **NO-GO**: Halt sprint, find alternatives | Object detection completely fails in low-light → Evaluate alternative models (ADR-025) |

**Discovery Feedback Loop**:

When validation discovers constraints or failures:

**Section: Recommended Actions** (in VALIDATION-LAYERX-001)

```markdown
## Recommended Actions

### Critical Issues (Blockers)
- **Issue**: Object detection fails entirely in low-light conditions
- **Action**: ADR-025 needed - Evaluate alternative models or add flash requirement
- **Impact**: Blocks Layer 1 sprint

### Discovered Constraints
- **Constraint**: Max 5 objects detected reliably per photo
- **Action**: Update DESIGN-003 with limit; consider multi-shot feature
- **Impact**: Update Layer 1 spec, add PRD-012 for multi-shot capture

### Performance Gaps
- **Gap**: Streaming mode 3x slower than batch (600ms vs 200ms)
- **Action**: Document as known limitation; acceptable for MVP
- **Impact**: Update TECH-STACK with performance characteristics

### Architecture Changes
- **Finding**: YOLO-v3 tiny insufficient for scissor detection (40% accuracy)
- **Action**: ADR-026 - Evaluate YOLOv8 or Vision API native object detection
- **Impact**: Re-validate after model change
```

**Layer Dependency Handling (Hybrid)**:

- **Parallel** (can run simultaneously):
  - Functional tests (each layer tests its own capabilities)
  - Performance benchmarks (measure layer in isolation)
  - Capability discovery (exploratory tests)

- **Sequential** (must run in order):
  - Integration tests (require actual output from previous layer)
  - End-to-end validation (Layer 1 → 2a → 2b → 3)

- **Robust Testing** (edge cases):
  - Layer 1: Different object counts (1, 3, 5, 10, 15+), lighting, angles, barcode types
  - Layer 2a: Different image sizes, formats, network conditions
  - Layer 2b: Different scene complexities, object types
  - Layer 3: Different catalog sizes, query types

---

## Checkpoint Format

**Standard format for all stage checkpoints**:

```markdown
# CHECKPOINT: [Stage X.Y - Stage Name]

## Executive Summary

[3-5 sentences: what was analyzed, key findings, recommendation]

## Work Completed

- [Major deliverable 1]
- [Major deliverable 2]
- [Major deliverable 3]

## Key Decisions Made

### Decision 1: [Decision Name]

**Rationale**: [2-3 sentences explaining why this decision was made]
**Impact**: [What this enables or constrains]

### Decision 2: [Decision Name]

**Rationale**: [...]
**Impact**: [...]

## Artifacts Generated

- 📄 **[ADR-XXX: Name]** - [One-line description]
- 📄 **[DESIGN-XXX: Name]** - [One-line description]
- 📄 **[TECH-STACK-XXX: Name]** - [One-line description]

## Open Questions Requiring Human Decision

### Question 1: [Clear, specific question]

**Context**: [Why this decision matters and what it impacts]

**Option A**: [Description]

- ✅ Pros: [List of advantages]
- ❌ Cons: [List of disadvantages]
- 💰 Cost: [If applicable]
- ⏱️ Time: [If applicable]

**Option B**: [Description]

- ✅ Pros: [...]
- ❌ Cons: [...]

**Option C** (if applicable): [...]

**Agent Recommendation**: Option [A/B/C] because [clear justification based on analysis]

### Question 2: [...]

## Risks & Concerns Identified

⚠️ **[Risk 1: Risk Name]**

- **Description**: [What could go wrong]
- **Impact**: High/Medium/Low
- **Probability**: High/Medium/Low
- **Mitigation**: [Proposed approach to reduce/eliminate risk]

⚠️ **[Risk 2: Risk Name]**

- [...]

## Dependencies for Next Stage

The next stage ([X.Y+1 - Stage Name]) requires:

- ✅ [Item 1 - Ready]
- ✅ [Item 2 - Ready]
- ⏳ [Item 3 - Waiting on human decision on Question 1]
- ❌ [Item 4 - Blocked by external factor]

## Next Stage Preview

**Stage [X.Y+1]**: [Stage Name]

- **Persona**: [Expert name and domain]
- **Will accomplish**: [1-2 sentences describing goals]
- **Will produce**: [Key output artifacts]
- **Estimated duration**: [If applicable]

## Required Human Action

Please review the checkpoint above and:

- [ ] Review all artifacts generated (links above)
- [ ] Approve decisions made OR provide corrections
- [ ] Make selections on open questions (1, 2, ...)
- [ ] Review and acknowledge risks
- [ ] **Authorize proceeding to Stage [X.Y+1]** OR request revisions

**How to respond**:

- "Approved - proceed to Stage [X.Y+1]"
- "Approved with changes: [specify changes]"
- "Question on [topic]: [your question]"
- "Request revision: [what needs to change]"
```

---

## Artifact Naming Conventions

### Document Types

| Prefix             | Type                          | Purpose                   | Example                             |
| ------------------ | ----------------------------- | ------------------------- | ----------------------------------- |
| **PRD-**           | Product Requirements Document | Feature specifications    | PRD-001: Abundance MVP              |
| **DESIGN-**        | Design Specification          | Technical designs         | DESIGN-002: iOS Client Architecture |
| **ADR-**           | Architecture Decision Record  | Decision rationale        | ADR-004: GCP Platform Choice        |
| **TEST-**          | Test Plan                     | Testing strategy          | TEST-001: Test Pyramid              |
| **TECH-STACK-**    | Technology Stack              | Tech specifications       | TECH-STACK-MAP-001                  |
| **RESEARCH-**      | Research Report               | Investigation findings    | RESEARCH-001: iOS Patterns          |
| **CODE-EXAMPLES-** | Code Examples                 | Reference implementations | CODE-EXAMPLES-001: Swift            |
| **ROADMAP-**       | Implementation Roadmap        | Phasing and timeline      | ROADMAP-001: Phased Plan            |
| **VALIDATION-**    | Validation Report             | Consistency checks        | VALIDATION-001: Tech Check          |

### Numbering System

- **Sequential numbering**: 001, 002, 003, ...
- **Special markers**:
  - 🔒 = Foundation document (e.g., TECH-STACK-MAP-001)
  - 🔑 = Critical dependency for multiple stages

### File Locations

Suggested directory structure:

```
docs/
├── specs/
│   ├── PRD-001-abundance-mvp.md
│   ├── PRD-002-ai-cataloging.md
│   └── ...
├── design/
│   ├── DESIGN-001-system-architecture.md
│   ├── DESIGN-002-ios-architecture.md
│   └── ...
├── adr/
│   ├── ADR-001-strategic-positioning.md
│   ├── ADR-004-gcp-platform-choice.md
│   └── ...
├── test/
│   ├── TEST-001-test-strategy.md
│   └── ...
├── tech-stack/
│   ├── TECH-STACK-MAP-001.md (🔒 Foundation)
│   ├── TECH-STACK-002-ios-dependencies.md
│   └── ...
├── research/
│   ├── RESEARCH-001-ios-patterns.md
│   └── ...
└── roadmap/
    └── ROADMAP-001-phased-plan.md
```

---

## Next Steps

### Immediate Actions

1. **Review Expert Agent Specifications** (Defined in this document):

   - Business Strategy Analyst
   - Product Strategy & UX
   - iOS Architecture Expert
   - Computer Vision & ML
   - Cloud Backend Architect
   - Privacy & Security Architect
   - Software Architecture Expert

2. **Create Grounding Documents** (Accelerates research):

   - `grounding/swift-swiftui-refs.md` (Apple docs, WWDC sessions)
   - `grounding/firebase-gcp-refs.md` (GCP/Firebase service docs)
   - `grounding/vision-coreml-refs.md` (Vision framework, Core ML docs)
   - `grounding/ios-security-refs.md` (iOS Security Guide, OWASP MASTG)

3. **Test the Pipeline**:

   - Start with Stage 1.1 (Business Strategy with Business Strategy Analyst)
   - Validate checkpoint format works
   - Refine based on learnings

4. **Iterate**:
   - Adjust pipeline based on what you learn
   - Refine expert agent specifications if needed
   - Update this document with lessons learned

### Pipeline Execution

To execute the pipeline:

```bash
# Start the pipeline
/superpowers:execute-plan

# Provide orchestrator prompt for Stage 1.1
[See detailed stage specification in Phase 1 section above]
```

### Success Criteria

Pipeline is successful when:

- ✅ All 6 phases complete
- ✅ All checkpoints passed with human approval
- ✅ 60+ formal artifacts generated
- ✅ Complete spec-kit ready for implementation
- ✅ Agent-ready prompts created for development
- ✅ No outstanding technical or business questions

---

## Revision History

| Date       | Version | Changes                                                  | Author                              |
| ---------- | ------- | -------------------------------------------------------- | ----------------------------------- |
| 2025-10-22 | 1.0     | Initial design - complete 6-phase pipeline specification | Claude Code (Brainstorming Session) |
| 2025-11-11 | 2.0     | Refactored Phases 4-6 to eliminate redundancy and focus on project scaffolding, roadmaps, and agent prompts (see PIPELINE-REFACTOR-2025-11-11.md) | Claude Code (Analysis Session) |
| 2025-11-12 | 2.1     | Refactored Phase 5: Stage 5.1 → Document Orchestration Roadmap (Use → Read → Implement → Test format), Stage 5.2 → Agent Prompts with Superpowers Integration + Pre-Development Validation. Dropped feature PRDs (redundant). Restored agent prompts with superpowers patterns (`/superpowers:write-plan` → `/superpowers:execute-plan`, specialized agent dispatch, token management). | Claude Code (Planning Session) |

---

## Appendix: Expert Agent Knowledge Domains & Research Sources

### Business Strategy Analyst

- **Key Frameworks**: Aggregation Theory, disruption patterns, platform dynamics, Porter's Five Forces
- **Focus**: Business model analysis, competitive dynamics, platform economics, network effects

### Product Strategy & UX

- **Key Frameworks**: Jobs to Be Done, User journey mapping, MVP prioritization
- **Focus**: Product-market fit, user personas, UX flows, trust & safety, marketplace dynamics

### iOS Architecture Expert

- **Key Frameworks**: SwiftUI architecture patterns, dependency injection, clean architecture for iOS
- **Focus**: SwiftUI, iOS 26, Swift 6, state management, testing strategies
- **Grounding Sources**: Apple HIG, Swift documentation, WWDC sessions, Firebase iOS SDK

### Computer Vision & ML

- **Key Frameworks**: On-device ML best practices, Vision framework patterns, model optimization
- **Focus**: Apple Vision Framework, Core ML, object detection, on-device machine learning
- **Grounding Sources**: Apple Vision docs, Visual Intelligence, WWDC Vision sessions

### Cloud Backend Architect

- **Key Frameworks**: Cloud-native architecture, microservices vs monolith-first, API design
- **Focus**: GCP architecture, Firebase integration, Kubernetes, API design, data modeling
- **Grounding Sources**: GCP/Firebase docs, Google Cloud Architecture Framework, API design guides

### Privacy & Security Architect

- **Key Frameworks**: Privacy by Design, STRIDE threat modeling, defense in depth, zero trust
- **Focus**: Privacy-first design, encryption, data minimization, mobile security, compliance
- **Grounding Sources**: Apple iOS Security Guide, OWASP MASTG, GDPR/CCPA frameworks

### Software Architecture Expert

- **Key Frameworks**: Monolith-first, domain-driven design, test pyramid, evolutionary architecture
- **Focus**: System design, API contracts, modularity, testing strategies, technical debt
- **Grounding Sources**: REST API principles, DDD patterns, microservices patterns, refactoring catalogs

### Common Grounding Documentation

- Apple Developer Documentation (Vision, Core ML, SwiftUI, Swift)
- WWDC 2024/2025 sessions
- GCP/Firebase documentation
- OWASP MASTG
- iOS Security Guide
- REST API design best practices

---

**End of Pipeline Design Specification**
