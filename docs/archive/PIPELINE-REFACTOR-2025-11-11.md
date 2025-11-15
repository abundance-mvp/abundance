# Pipeline Refactor: Stages 4-6 Redesign

**Date**: 2025-11-11
**Status**: Active - Supersedes original Stages 4-6 from `abundance-analysis-pipeline-design.md`
**Reason**: Original Stages 4-6 design became redundant after comprehensive work in Stages 1-3
**Decision**: Refactor Stages 4-6 to eliminate redundancy and focus on actual implementation gaps

---

## Executive Summary

After completing Stages 1.1 through 3.4 (with 3.5-3.6 pending), an analysis revealed that the **original Stages 4-6 design is largely redundant**. The extensive research and architecture work in Phases 2-3 already accomplished what Stages 4.1-4.3 were meant to do (tech stack specification).

This document proposes a **refactored Stages 4-6** that:
- Eliminates redundant "tech stack specification" stages (4.1-4.3)
- Replaces them with **project scaffolding generation** (actual runnable files)
- Refines Stage 5.1-5.2 to produce **concrete roadmaps and agent prompts**
- Keeps Stage 6.1-6.2 validation as originally designed

**Result**: A clearer path from design to implementation with no wasted effort.

---

## What Stages 1-3 Actually Accomplished

### Phase 1: Vision & Strategy (Complete) ✅

| Stage | Artifacts Created | Status |
|-------|-------------------|--------|
| **1.1: Business Strategy** | Business model canvas, competitive analysis, ADR-001, ADR-002, revenue projections | ✅ Complete |
| **1.2: Product Strategy** | User personas, journey maps, trust & safety framework, ADR-003 (MVP scope), ADR-004 (iOS 26-only), feature prioritization | ✅ Complete |

**Key Outputs**:
- Clear business strategy with validated network effects
- MVP scope locked (single-player utility → sharing → marketplace)
- iOS 26-only launch strategy approved

---

### Phase 2: Technical Architecture (Complete) ✅

| Stage | Artifacts Created | Status |
|-------|-------------------|--------|
| **2.0: Computer Vision Research** | Research validation, 4-layer AI pipeline design, 6 ADRs (Vision, AI providers, barcode, reasoning, image hosting, LLM parsing), COST-MODEL-001 | ✅ Complete |
| **2.1: Tech Stack Mapping** | **TECH-STACK-MAP-001** (complete tech stack), API-CONTRACTS-001 (REST endpoints), 5 ADRs (auth, database, API, storage, CI/CD), TEST-STRATEGY-001 | ✅ Complete |
| **2.2: iOS Architecture** | PLAN-SUMMARY, 4 ADRs (MVVM, modules, state, DI), 6 DESIGN docs (modules, Firebase, Vision, networking, persistence, data models), TEST-002 | ✅ Complete |
| **2.3: Backend Architecture** | PLAN-SUMMARY, DATA-MODEL-001 (Firestore schema), CLOUD-FUNCTIONS-001, SECURITY-RULES-001, STORAGE-RULES-001, AI-INTEGRATION-LAYER-001, DEPLOYMENT-001, 2 ADRs, Research validation | ✅ Complete |
| **2.4: CV Pipeline Architecture** | Multiple DESIGN docs (DESIGN-004, DESIGN-005, SERPAPI-INTEGRATION-001), SCHEMA-001, barcode scanning plan, research reports, 6 ADRs | ✅ Complete |
| **2.5: Security Architecture** | PLAN-SUMMARY, security validation | ✅ Complete |
| **2.6: UI/UX Design** | PLAN-SUMMARY, 13 DESIGN docs (onboarding, camera, catalog, item detail, profile, component library, color system, typography, animations, accessibility, WCAG compliance, MVVM integration, iOS 25 compatibility) | ✅ Complete |

**Key Outputs**:
- **Complete technology stack locked** (Swift 6, SwiftUI, GCP, Firestore, Cloud Functions, Firebase Auth, Firebase Storage)
- **iOS architecture 100% specified** (MVVM, modular packages, Combine+async/await, constructor injection)
- **Backend architecture 100% specified** (Firestore schema, Cloud Functions, security rules, AI orchestration)
- **UI/UX 100% designed** (13 design docs, Liquid Glass integration, WCAG 2.2 Level AA)
- **20 ADRs created** (all major architectural decisions documented)

---

### Phase 3: Deep Technical Research (Partially Complete) ⏳

| Stage | Artifacts Created | Status |
|-------|-------------------|--------|
| **3.1: iOS Implementation Research** | PLAN-SUMMARY, Research validation, CODE-EXAMPLE-001 to 004 (Swift 6 concurrency, MVVM, Firebase, Vision), DESIGN-012 (Xcode structure), CODEGEN-001 (Sourcery), TEST-EXAMPLE-001 to 002, RESEARCH-002 (WWDC insights) | ✅ Complete |
| **3.2: Backend Implementation Research** | PLAN-SUMMARY, Research validation, CODE-EXAMPLE-005 to 008 (Cloud Functions, Firestore queries, AI orchestration, Firebase Admin), TEST-EXAMPLE-003, INFRASTRUCTURE-001 (deployment), MONITORING-001 | ✅ Complete |
| **3.3: Layer 1 On-Device ML Research** | PLAN-SUMMARY, RESEARCH-003 (household item detection), CODE-EXAMPLE-009 (detector implementation), DESIGN-039 (performance), DESIGN-040 (edge cases), BENCHMARK-001 (accuracy methodology), TEST-EXAMPLE-004 | ✅ Complete |
| **3.4: Layer 2a Attribute Extraction Research** | PLAN-SUMMARY, Research validation, CODE-EXAMPLE-010 to 011 (Vertex AI, Cloud Function), RESEARCH-004 (prompt optimization), DESIGN-041 (JSON schema), DESIGN-042 (error handling), BENCHMARK-002, TEST-EXAMPLE-005 | ✅ Complete |
| **3.5: Layer 2b Product Search Research** | CODE-EXAMPLE-012 to 014 (SerpAPI, UPCitemdb, Claude Haiku), DESIGN-043 (error handling), TEST-EXAMPLE-006, Research validation | ⏳ **Pending** |
| **3.6: Layer 3 AI Synthesis Research** | CODE-EXAMPLE-015 to 017 (Claude Sonnet synthesis, conflict resolution, confidence scoring), DESIGN-044 (error handling), TEST-EXAMPLE-007, Research validation | ⏳ **Pending** |

**Key Outputs**:
- **11 CODE-EXAMPLE documents** with production-ready patterns
- **Implementation research for iOS, Backend, Layer 1, Layer 2a** complete
- **INFRASTRUCTURE-001** (GCP deployment automation) created
- **DESIGN-012** (Xcode project structure) created
- **CODEGEN-001** (Sourcery templates) created

---

## The Problem: Original Stages 4-6 Are Redundant

### Original Stage 4.1: iOS Tech Stack Specification ❌ REDUNDANT

**Original Goal**:
- Specify exact Swift package dependencies
- Decide URLSession vs Alamofire
- Decide image caching (Nuke vs Kingfisher)
- Create runnable `Package.swift`

**Why Redundant**:
- ✅ **TECH-STACK-MAP-001** already locked all technology choices (Swift 6, SwiftUI, Firebase SDK)
- ✅ **DESIGN-012** (Xcode project structure) already specifies project organization
- ✅ **CODE-EXAMPLE-001 to 004** already show all dependencies (Firebase iOS SDK, Vision framework, Combine, async/await)
- ✅ **ADR-010 to ADR-013** already locked iOS architectural patterns

**What's Actually Missing**: A runnable `Package.swift` file (not another decision document)

---

### Original Stage 4.2: Backend Tech Stack Specification ❌ REDUNDANT

**Original Goal**:
- Choose Cloud Functions runtime (Node.js vs Python)
- Specify service configurations (Firestore indexes, deployment config)
- Decide search solution (Firestore vs Algolia)
- Create infrastructure-as-code templates

**Why Redundant**:
- ✅ **TECH-STACK-MAP-001** already locked backend choices (GCP, Cloud Functions, Firestore, Firebase Storage)
- ✅ **CODE-EXAMPLE-005 to 008** already show Node.js patterns (runtime implicitly chosen)
- ✅ **DATA-MODEL-001** already specifies Firestore schema and indexes
- ✅ **INFRASTRUCTURE-001** already exists (deployment automation)
- ✅ **SECURITY-RULES-001** and **STORAGE-RULES-001** already drafted

**What's Actually Missing**: Actual runnable files (`firestore.rules`, `storage.rules`, `firestore.indexes.json`, `package.json`)

---

### Original Stage 4.3: AI/ML Integration Specification ❌ REDUNDANT

**Original Goal**:
- Finalize AI provider ranking (primary, secondary, tertiary)
- Design hot-swappable integration code
- Create cost projections for scale

**Why Redundant**:
- ✅ **ADR-014** (Cloud AI Provider Selection) already locked providers (Gemini 2.5 Flash-Lite for Layer 2a, SerpAPI for Layer 2b visual search, UPCitemdb for barcode, Claude Sonnet 4.5 for Layer 3)
- ✅ **ADR-015** (AI Reasoning Layer Architecture) already designed Layer 3
- ✅ **AI-INTEGRATION-LAYER-001** already exists (hot-swappable design)
- ✅ **COST-MODEL-001** already exists (cost per item calculated)
- ✅ **CODE-EXAMPLE-007** (AI pipeline orchestration) already shows integration pattern

**What's Actually Missing**: Actual AI provider adapter interfaces and configuration files

---

### Original Stage 5.1: Phased Roadmap Creation ❓ PARTIALLY USEFUL

**Original Goal**:
- Break implementation into phases (MVP → Sharing → Marketplace)
- Create epics and stories
- Define task dependencies
- Estimate effort (T-shirt sizing)

**Status**: **Partially useful** but underspecified
- ✅ MVP phasing already defined in ADR-003 (Phase 1: single-player, Phase 2: sharing, Phase 3: marketplace)
- ❌ **Missing**: Sprint-by-sprint breakdown, epic decomposition, dependency graph, effort estimates

**What's Needed**: Concrete sprint plans with task-level breakdown

---

### Original Stage 5.2: Detailed Spec-Kit Generation ❓ PARTIALLY USEFUL

**Original Goal**:
- Generate PRD-002 through PRD-010 (feature PRDs)
- Generate DESIGN-006 through DESIGN-020 (component designs)
- Generate TEST-003 through TEST-015 (feature test plans)
- Create agent-ready implementation prompts

**Status**: **Partially useful** but design docs already exceed this scope
- ✅ **38 DESIGN documents** already created (far exceeds DESIGN-006 to DESIGN-020)
- ✅ **11 CODE-EXAMPLE documents** created
- ✅ **7 TEST-EXAMPLE documents** created
- ❌ **Missing**: Feature-by-feature PRDs (PRD-002, PRD-003, etc.)
- ❌ **Missing**: Agent-ready implementation prompts (executable prompts for `/superpowers:execute-plan`)

**What's Needed**: Per-feature PRDs and agent prompts (not more design docs)

---

### Original Stage 6.1: Technical Validation ✅ USEFUL AS DESIGNED

**Original Goal**:
- Cross-validate all technical decisions for consistency
- Identify integration points between components
- Verify all APIs are correctly specified
- Ensure test coverage is comprehensive
- Check for conflicting assumptions
- Validate security across all components

**Status**: **Keep as designed** - This is genuinely valuable validation work

---

### Original Stage 6.2: Business-Technical Alignment ✅ USEFUL AS DESIGNED

**Original Goal**:
- Verify technical plan delivers on business strategy
- Validate MVP can achieve product-market fit
- Check cost assumptions are realistic
- Ensure success metrics are measurable
- Confirm phasing aligns with business goals

**Status**: **Keep as designed** - This is genuinely valuable final sign-off

---

## Refactored Stages 4-6: New Design

### Phase 3 (Complete First): Finish Deep Technical Research

**Stage 3.5: Layer 2b Product Search Implementation Research** ⚠️ MUST COMPLETE

- **Expert**: Cloud Backend Architect + Computer Vision & ML Engineer
- **Purpose**: Research SerpAPI Google Lens integration, UPCitemdb barcode lookup, Claude Haiku parsing
- **Inputs**:
  - `docs/plans/PLAN-SUMMARY-stage-3.2.md` (backend research)
  - `docs/plans/PLAN-SUMMARY-stage-2.4.md` (CV pipeline architecture)
  - `docs/design/DESIGN-018-llm-parsing-implementation.md`
  - `docs/design/DESIGN-019-barcode-api-integration.md`
  - `docs/design/SERPAPI-INTEGRATION-001-swift-rest-api-patterns.md`
  - `docs/adr/ADR-018-barcode-product-lookup-strategy.md`
- **Research Areas**:
  1. SerpAPI Google Lens API integration (REST patterns, visual_matches parsing, public URL requirements)
  2. UPCitemdb barcode lookup API (pricing, limits, database coverage, product data quality)
  3. Claude Haiku 4.5 parsing (brand/model/variant extraction from SerpAPI results)
  4. Dual-mode strategy (barcode-first, visual fallback)
  5. Error handling and fallback logic
  6. Cost optimization (barcode reduces Layer 2b calls by 50%)
- **Outputs**:
  - `docs/plans/PLAN-SUMMARY-stage-3.5.md`
  - `docs/plans/2025-11-11-stage-3.5-layer-2b-implementation-research.md`
  - `docs/validation/RESEARCH-VALIDATION-stage-3.5.md`
  - `docs/design/CODE-EXAMPLE-012-serpapi-integration.md`
  - `docs/design/CODE-EXAMPLE-013-upcitemdb-integration.md`
  - `docs/design/CODE-EXAMPLE-014-claude-haiku-parsing.md`
  - `docs/design/DESIGN-043-layer-2b-error-handling.md`
  - `docs/test/TEST-EXAMPLE-006-layer-2b-testing-patterns.md`
  - `docs/checkpoints/CHECKPOINT-stage-3.5.md`

---

**Stage 3.6: Layer 3 AI Synthesis Implementation Research** ⚠️ MUST COMPLETE

- **Expert**: Computer Vision & ML Engineer
- **Purpose**: Research Claude Sonnet 4.5 Batch API for AI synthesis and conflict resolution
- **Inputs**:
  - `docs/plans/PLAN-SUMMARY-stage-2.4.md` (CV pipeline architecture)
  - `docs/design/DESIGN-020-ai-synthesis-architecture.md`
  - `docs/adr/ADR-015-ai-reasoning-layer-architecture.md`
  - Stage 3.4 outputs (Layer 2a research)
  - Stage 3.5 outputs (Layer 2b research)
- **Research Areas**:
  1. Claude Sonnet 4.5 Batch API (pricing, latency, capabilities, JSON mode)
  2. Merging Layer 2a + Layer 2b results (attribute extraction + product search)
  3. Conflict resolution patterns (mismatches between vision and product search)
  4. Confidence scoring algorithms (high/medium/low confidence per field)
  5. Final metadata generation (enriched item metadata schema)
  6. Error handling and retry logic
  7. Cost optimization (batch processing reduces cost)
- **Outputs**:
  - `docs/plans/PLAN-SUMMARY-stage-3.6.md`
  - `docs/plans/2025-11-11-stage-3.6-layer-3-ai-synthesis-implementation-research.md`
  - `docs/validation/RESEARCH-VALIDATION-stage-3.6.md`
  - `docs/design/CODE-EXAMPLE-015-claude-sonnet-synthesis.md`
  - `docs/design/CODE-EXAMPLE-016-conflict-resolution-patterns.md`
  - `docs/design/CODE-EXAMPLE-017-confidence-scoring.md`
  - `docs/design/DESIGN-044-layer-3-error-handling.md`
  - `docs/test/TEST-EXAMPLE-007-layer-3-testing-patterns.md`
  - `docs/checkpoints/CHECKPOINT-stage-3.6.md`

---

### Phase 4 (Refactored): Project Scaffolding & Runnable Files

**Purpose**: Generate actual runnable project files (not more decision documents)

---

**Stage 4.1: iOS Project Scaffolding**

- **Expert**: iOS Architecture Expert
- **Purpose**: Generate actual runnable iOS project files and directory structure
- **Inputs**:
  - All Stage 2.2 outputs (iOS architecture)
  - All Stage 3.1 outputs (iOS implementation research)
  - `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`
  - `docs/design/DESIGN-012-xcode-project-structure.md`
  - `docs/design/CODEGEN-001-sourcery-templates.md`
  - All iOS ADRs (ADR-010 to ADR-013)
- **Tasks**:
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
- **Outputs**:
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

**Stage 4.2: Backend Project Scaffolding**

- **Expert**: Cloud Backend Architect
- **Purpose**: Generate actual runnable backend project files and deployment scripts
- **Inputs**:
  - All Stage 2.3 outputs (backend architecture)
  - All Stage 3.2 outputs (backend implementation research)
  - `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`
  - `docs/tech-stack/DATA-MODEL-001-firestore-schema.md`
  - `docs/design/SECURITY-RULES-001-firestore-rules.md`
  - `docs/design/STORAGE-RULES-001-firebase-storage-rules.md`
  - `docs/tech-stack/INFRASTRUCTURE-001-gcp-deployment-automation.md`
  - All backend ADRs (ADR-005 to ADR-009, ADR-019 to ADR-020)
- **Tasks**:
  1. Create runnable `firestore.rules` file (translate SECURITY-RULES-001 to actual syntax)
  2. Create runnable `storage.rules` file (translate STORAGE-RULES-001 to actual syntax)
  3. Create `firestore.indexes.json` (index definitions from DATA-MODEL-001)
  4. Create `functions/package.json` (Cloud Functions dependencies, Node.js version)
  5. Create `functions/src/index.ts` scaffold (entry point with function exports)
  6. Create `firebase.json` configuration (hosting, functions, Firestore, storage)
  7. Create `.env.template` (environment variables: API keys, project ID, region)
  8. Expand INFRASTRUCTURE-001 into runnable Terraform scripts (if using IaC)
  9. Create `README-Backend-Setup.md` (developer onboarding: Firebase CLI, deploy, test)
  10. Create deployment scripts (`deploy.sh`, `deploy-dev.sh`, `deploy-prod.sh`)
- **Outputs**:
  - `docs/tech-stack/firestore.rules` (runnable security rules)
  - `docs/tech-stack/storage.rules` (runnable storage rules)
  - `docs/tech-stack/firestore.indexes.json` (Firestore indexes)
  - `docs/tech-stack/functions-package.json` (Cloud Functions dependencies)
  - `docs/tech-stack/functions-index-scaffold.ts` (Cloud Functions entry point)
  - `docs/tech-stack/firebase.json` (Firebase project configuration)
  - `docs/tech-stack/.env.template` (environment variables template)
  - `docs/tech-stack/terraform/` (GCP infrastructure-as-code scripts, if applicable)
  - `docs/tech-stack/README-Backend-Setup.md` (developer onboarding)
  - `docs/tech-stack/deployment-scripts.md` (deploy.sh specifications)
  - `docs/checkpoints/CHECKPOINT-stage-4.2.md`

---

**Stage 4.3: AI Pipeline Integration Scaffolding**

- **Expert**: Computer Vision & ML Engineer
- **Purpose**: Generate AI pipeline project structure and provider adapter interfaces
- **Inputs**:
  - All Stage 3.3-3.6 outputs (Layer 1-3 research)
  - `docs/design/DESIGN-004-computer-vision-pipeline.md`
  - `docs/design/AI-INTEGRATION-LAYER-001-cloud-ai-orchestration.md`
  - `docs/adr/ADR-014-cloud-ai-provider-selection.md`
  - `docs/adr/ADR-015-ai-reasoning-layer-architecture.md`
  - `docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md`
- **Tasks**:
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
- **Outputs**:
  - `docs/tech-stack/ai-pipeline-project-structure.md` (directory layout)
  - `docs/tech-stack/ai-provider-adapters.md` (interface specifications)
  - `docs/tech-stack/ai-configuration-files.md` (Vertex AI, Anthropic, SerpAPI, UPCitemdb configs)
  - `docs/tech-stack/ai-cost-tracking-setup.md` (monitoring and logging)
  - `docs/tech-stack/ai-integration-test-harness.md` (testing approach)
  - `docs/tech-stack/README-AI-Pipeline-Setup.md` (developer onboarding)
  - `docs/checkpoints/CHECKPOINT-stage-4.3.md`

---

### Phase 5 (Refactored): Implementation Roadmap & Agent Prompts

**Purpose**: Create sprint-by-sprint implementation plan and agent-ready execution prompts

---

**Stage 5.1: Phased Implementation Roadmap**

- **Experts**: Software Architecture Expert + Product Strategy & UX
- **Purpose**: Create concrete sprint-by-sprint breakdown with dependencies and estimates
- **Inputs**:
  - All Phase 1-4 artifacts (all PLAN-SUMMARY docs, ADRs, DESIGN docs, CODE-EXAMPLES)
  - `docs/adr/ADR-003-mvp-scope-phasing.md` (MVP phasing strategy)
  - `docs/specs/feature-prioritization-matrix.md`
  - `docs/specs/mvp-vision-features.md`
  - All technical architecture documents
- **Tasks**:
  1. Break MVP into 12-16 week sprint plan (2-week sprints)
  2. Create epic breakdown:
     - **Epic 1**: iOS Project Setup & CI/CD
     - **Epic 2**: User Authentication & Onboarding
     - **Epic 3**: Camera Capture Module
     - **Epic 4**: Layer 1 On-Device ML (Vision Framework)
     - **Epic 5**: Backend AI Pipeline (Layer 2a, 2b, 3)
     - **Epic 6**: Catalog View & Item Management
     - **Epic 7**: Item Detail View & Editing
     - **Epic 8**: Export Functionality
     - **Epic 9**: Profile & Settings
     - **Epic 10**: Integration Testing & Bug Fixes
     - **Epic 11**: Performance Optimization & Polish
     - **Epic 12**: App Store Submission Prep
  3. For each epic, decompose into stories (user-facing features)
  4. For each story, decompose into tasks (developer-facing work)
  5. Create dependency graph (which tasks must complete before others)
  6. Assign effort estimates (S: 1-2 days, M: 3-5 days, L: 1-2 weeks, XL: 2-4 weeks)
  7. Identify technical risks per sprint (risk register)
  8. Create sprint-by-sprint detailed plans (Sprint 1 through Sprint 8)
- **Outputs**:
  - `docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md` (12-16 week sprint plan with milestones)
  - `docs/roadmap/EPIC-BREAKDOWN-001-features-to-tasks.md` (hierarchical epic → story → task breakdown)
  - `docs/roadmap/SPRINT-PLAN-001-through-008.md` (detailed sprint plans: goals, stories, tasks, DoD)
  - `docs/roadmap/DEPENDENCY-GRAPH-001.md` (task dependencies visualization, critical path)
  - `docs/roadmap/RISK-REGISTER-001.md` (technical risks per sprint with mitigations)
  - `docs/roadmap/EFFORT-ESTIMATES-001.md` (T-shirt sizing: S/M/L/XL per task)
  - `docs/checkpoints/CHECKPOINT-stage-5.1.md`

---

**Stage 5.2: Feature-Specific Spec-Kit & Agent Prompts**

- **Experts**: All domain experts (orchestrated)
- **Purpose**: Generate per-feature PRDs and agent-ready implementation prompts
- **Inputs**:
  - `docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md` (from Stage 5.1)
  - `docs/roadmap/EPIC-BREAKDOWN-001-features-to-tasks.md` (from Stage 5.1)
  - All technical artifacts from Phases 1-4 (ADRs, DESIGN docs, CODE-EXAMPLES)
- **Tasks**:
  1. **Generate Feature PRDs** (one per major feature):
     - **PRD-002**: Camera Capture Feature
     - **PRD-003**: AI Cataloging Feature (4-layer pipeline)
     - **PRD-004**: Inventory Management Feature (catalog view, filtering, sorting)
     - **PRD-005**: User Authentication Feature (Firebase Auth, biometric, onboarding)
     - **PRD-006**: Item Detail View Feature (editing, photos, metadata)
     - **PRD-007**: Export Functionality Feature (CSV, PDF, insurance reports)
     - **PRD-008**: Profile & Settings Feature (account management, preferences)
     - **PRD-009**: Barcode Scanning Feature (Layer 2b barcode-first mode)
     - **PRD-010**: Sharing Circles Feature (Phase 2 - deferred to post-MVP)
     - Each PRD includes: user stories, acceptance criteria, edge cases, mockups, API contracts
  2. **Generate Agent-Ready Implementation Prompts** (executable with `/superpowers:execute-plan`):
     - **AGENT-PROMPT-001**: iOS Camera Module Implementation
     - **AGENT-PROMPT-002**: Vision Framework Processing Implementation
     - **AGENT-PROMPT-003**: Backend AI Pipeline Implementation (Layer 2a, 2b, 3)
     - **AGENT-PROMPT-004**: Firestore Data Layer Implementation
     - **AGENT-PROMPT-005**: iOS Catalog View Implementation
     - **AGENT-PROMPT-006**: iOS Item Detail View Implementation
     - **AGENT-PROMPT-007**: Firebase Authentication Implementation
     - **AGENT-PROMPT-008**: Export Functionality Implementation
     - Each prompt includes: context files to load, exact tasks, code examples to follow, test requirements
  3. **Generate E2E Test Plans** (integration and user flow testing):
     - **TEST-003**: E2E User Flows (onboarding → capture → catalog → export)
     - **TEST-004**: AI Pipeline Integration Testing (Layer 1 → 2a+2b → 3 → Firestore)
     - **TEST-005**: Cross-Platform Testing (iOS device matrix, OS versions)
     - **TEST-006**: Performance & Load Testing (concurrent users, AI latency, Firestore throughput)
  4. **Generate Acceptance Criteria Checklist**:
     - Definition of Done (DoD) for each feature
     - QA checklist for manual testing
     - Automated test coverage requirements (unit: 70%, integration: critical paths)
- **Outputs**:
  - `docs/specs/PRD-002-camera-capture.md` (feature PRD)
  - `docs/specs/PRD-003-ai-cataloging.md` (feature PRD)
  - `docs/specs/PRD-004-inventory-management.md` (feature PRD)
  - `docs/specs/PRD-005-user-authentication.md` (feature PRD)
  - `docs/specs/PRD-006-item-detail-view.md` (feature PRD)
  - `docs/specs/PRD-007-export-functionality.md` (feature PRD)
  - `docs/specs/PRD-008-profile-settings.md` (feature PRD)
  - `docs/specs/PRD-009-barcode-scanning.md` (feature PRD)
  - `docs/specs/PRD-010-sharing-circles.md` (feature PRD - Phase 2)
  - `docs/agent-prompts/AGENT-PROMPT-001-ios-camera-module.md` (executable prompt)
  - `docs/agent-prompts/AGENT-PROMPT-002-vision-processing.md` (executable prompt)
  - `docs/agent-prompts/AGENT-PROMPT-003-backend-ai-pipeline.md` (executable prompt)
  - `docs/agent-prompts/AGENT-PROMPT-004-firestore-data-layer.md` (executable prompt)
  - `docs/agent-prompts/AGENT-PROMPT-005-ios-catalog-view.md` (executable prompt)
  - `docs/agent-prompts/AGENT-PROMPT-006-ios-item-detail-view.md` (executable prompt)
  - `docs/agent-prompts/AGENT-PROMPT-007-firebase-authentication.md` (executable prompt)
  - `docs/agent-prompts/AGENT-PROMPT-008-export-functionality.md` (executable prompt)
  - `docs/test/TEST-003-e2e-user-flows.md` (integration test plan)
  - `docs/test/TEST-004-ai-pipeline-integration.md` (integration test plan)
  - `docs/test/TEST-005-cross-platform-testing.md` (device matrix testing)
  - `docs/test/TEST-006-performance-load-testing.md` (performance benchmarks)
  - `docs/specs/ACCEPTANCE-CRITERIA-CHECKLIST-001.md` (DoD for all features)
  - `docs/checkpoints/CHECKPOINT-stage-5.2.md`

---

### Phase 6 (Keep as Designed): Validation & Sign-Off

**Purpose**: Cross-validate all technical decisions and get final business approval

---

**Stage 6.1: Technical Consistency Validation**

- **Experts**: All technical experts (iOS Architecture Expert, Cloud Backend Architect, Computer Vision & ML, Privacy & Security Architect, Software Architecture Expert)
- **Purpose**: Cross-validate all technical decisions for consistency and correctness
- **Inputs**:
  - All Phase 1-5 artifacts (complete spec-kit: 20 ADRs, 38 DESIGN docs, 11 CODE-EXAMPLEs, 7 TEST-EXAMPLEs, 10 PRDs, 8 agent prompts, roadmap)
- **Tasks**:
  1. **ADR Consistency Check**: Verify no conflicting decisions across 20 ADRs
  2. **API Contract Validation**: Check iOS → Backend API contracts match (API-CONTRACTS-001 vs iOS networking layer vs Cloud Functions endpoints)
  3. **Firestore Schema Validation**: Verify DATA-MODEL-001 supports all features in PRDs (no missing collections/fields)
  4. **AI Pipeline Integration Validation**: Check Layer 1 → 2a+2b → 3 → Firestore flow is correct (DESIGN-004 vs CODE-EXAMPLEs)
  5. **Cost Model Validation**: Verify COST-MODEL-001 is accurate given Stage 3.4 research (Gemini pricing corrections)
  6. **Test Coverage Validation**: Ensure TEST-001, TEST-002, TEST-003 to TEST-006 provide comprehensive coverage (unit 70%, integration critical paths, E2E user flows)
  7. **Security Validation**: Cross-check SECURITY-RULES-001, STORAGE-RULES-001, STRIDE analysis (Stage 2.5) against all features
  8. **Dependency Validation**: Verify all CODE-EXAMPLEs use correct dependency versions (Firebase iOS SDK, Cloud Functions libraries)
  9. **Integration Point Validation**: Check all cross-component integration points are specified (iOS ↔ Firebase, Cloud Functions ↔ Vertex AI, Cloud Functions ↔ Anthropic)
- **Outputs**:
  - `docs/validation/VALIDATION-REPORT-001-technical-consistency.md` (issues found and resolutions)
  - `docs/test/INTEGRATION-TEST-PLAN-001-cross-component.md` (integration testing strategy)
  - `docs/validation/OUTSTANDING-QUESTIONS-001.md` (unresolved issues requiring human decision)
  - `docs/validation/CORRECTIONS-LOG-001.md` (fixes applied during validation)
  - `docs/checkpoints/CHECKPOINT-stage-6.1.md`

---

**Stage 6.2: Business-Technical Alignment & Go/No-Go**

- **Experts**: Business Strategy Analyst + Product Strategy & UX
- **Purpose**: Final business validation before implementation (final sign-off)
- **Inputs**:
  - Complete spec-kit (all artifacts from Phases 1-6)
  - `docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md`
  - `docs/specs/revenue-projections.md`
  - `docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md`
  - `docs/validation/VALIDATION-REPORT-001-technical-consistency.md` (Stage 6.1 output)
- **Tasks**:
  1. **Business Strategy Alignment**: Verify technical plan delivers on ADR-001 (strategic positioning) and ADR-002 (platform strategy)
  2. **MVP Product-Market Fit**: Validate PRD-002 to PRD-009 achieve product-market fit (ADR-003 MVP scope)
  3. **Cost Assumptions**: Check COST-MODEL-001 is realistic (AI costs, GCP costs, Firebase costs) vs revenue projections
  4. **Success Metrics**: Ensure success-metrics.md are measurable and trackable (user retention, catalog completion rate, sharing activity)
  5. **Phasing Alignment**: Confirm ROADMAP-001 aligns with business goals (12-16 week MVP, then Phase 2 sharing, then Phase 3 marketplace)
  6. **Go-to-Market Readiness**: Validate App Store submission readiness (privacy policy, terms of service, GDPR compliance)
  7. **Risk Assessment**: Review RISK-REGISTER-001 and assess business risks (technical debt, scalability, AI cost overruns)
- **Outputs**:
  - `docs/validation/VALIDATION-REPORT-002-business-technical-alignment.md` (confirmation or issues)
  - `docs/specs/SUCCESS-METRICS-FINAL.md` (updated with measurement plan and tracking tools)
  - `docs/tech-stack/COST-PROJECTION-FINAL.md` (12-month P&L projection with runway analysis)
  - `docs/validation/GO-NO-GO-RECOMMENDATION.md` (final recommendation: GO or NO-GO with detailed justification)
  - `docs/checkpoints/CHECKPOINT-stage-6.2.md` (final checkpoint)

---

## Summary of Changes

| Original Design | Refactored Design | Reason for Change |
|----------------|-------------------|-------------------|
| **Stage 4.1**: iOS Tech Stack Specification | **New 4.1**: iOS Project Scaffolding | Tech stack already locked in Stage 2.1. Need runnable `Package.swift`, not more decisions. |
| **Stage 4.2**: Backend Tech Stack Specification | **New 4.2**: Backend Project Scaffolding | Tech stack already locked in Stage 2.1. Need runnable `firestore.rules`, `storage.rules`, not more decisions. |
| **Stage 4.3**: AI/ML Integration Specification | **New 4.3**: AI Pipeline Integration Scaffolding | AI providers already locked in Stage 2.0. Need adapter interfaces and config files, not more decisions. |
| **Stage 5.1**: Generic roadmap | **New 5.1**: Sprint-by-sprint breakdown | Need concrete sprint plans with dependencies, not vague phasing. |
| **Stage 5.2**: Vague "spec-kit generation" | **New 5.2**: Feature PRDs + Agent Prompts | Need feature-specific PRDs and executable prompts for agents, not more design docs (already have 38). |
| **Stage 6.1**: Technical Validation | **Keep 6.1** (unchanged) | Genuinely valuable validation stage. |
| **Stage 6.2**: Business-Technical Alignment | **Keep 6.2** (unchanged) | Genuinely valuable final sign-off stage. |

---

## Critical Path to Implementation

### Immediate Next Steps:

1. ✅ **Complete Stage 3.5** (Layer 2b Product Search Implementation Research)
   - Estimated effort: 4-6 hours
   - Critical: Completes AI pipeline research

2. ✅ **Complete Stage 3.6** (Layer 3 AI Synthesis Implementation Research)
   - Estimated effort: 4-6 hours
   - Critical: Completes AI pipeline research

3. **Run Stage 4.1** (iOS Project Scaffolding)
   - Estimated effort: 6-8 hours
   - Output: Runnable `Package.swift`, Xcode project structure, config files

4. **Run Stage 4.2** (Backend Project Scaffolding)
   - Estimated effort: 6-8 hours
   - Output: Runnable `firestore.rules`, `storage.rules`, Cloud Functions scaffold

5. **Run Stage 4.3** (AI Pipeline Integration Scaffolding)
   - Estimated effort: 4-6 hours
   - Output: AI provider adapters, config files, test harness

6. **Run Stage 5.1** (Phased Implementation Roadmap)
   - Estimated effort: 6-8 hours
   - Output: Sprint-by-sprint plan, epic breakdown, dependency graph

7. **Run Stage 5.2** (Feature-Specific Spec-Kit & Agent Prompts)
   - Estimated effort: 8-10 hours
   - Output: PRD-002 to PRD-010, AGENT-PROMPT-001 to AGENT-PROMPT-008

8. **Run Stage 6.1** (Technical Consistency Validation)
   - Estimated effort: 4-6 hours
   - Output: Validation report, integration test plan

9. **Run Stage 6.2** (Business-Technical Alignment & Go/No-Go)
   - Estimated effort: 2-4 hours
   - Output: Final sign-off, go/no-go recommendation

**Total Estimated Effort**: 44-62 hours (~1-1.5 weeks of pipeline work)

**After Completion**: Ready for implementation with:
- ✅ Complete spec-kit (60+ artifacts)
- ✅ Runnable project files (iOS, Backend, AI Pipeline)
- ✅ Sprint-by-sprint roadmap (12-16 weeks)
- ✅ Agent-ready implementation prompts
- ✅ Technical validation passed
- ✅ Final business sign-off

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial refactor document - redesigned Stages 4-6 to eliminate redundancy | Claude Code (Analysis Session) |

---

## Next Actions

1. **Human Review**: Review this refactor design and approve/reject/request changes
2. **Update Context Map**: Update `docs/context-map.json` to reflect refactored Stages 4-6
3. **Execute Stage 3.5**: Start with Layer 2b research (next immediate step)
4. **Execute Stage 3.6**: Complete Layer 3 research
5. **Proceed to Phase 4**: Generate runnable project files

---

**END OF REFACTOR DOCUMENT**
