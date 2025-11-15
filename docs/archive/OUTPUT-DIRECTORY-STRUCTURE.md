# Output Directory Structure for Abundance Analysis Pipeline

**Created**: 2025-10-22
**Purpose**: Define standard locations for all artifacts generated during the pipeline execution

---

## Overview

All pipeline stages generate formal artifacts (PRDs, DESIGNs, ADRs, TEST plans, etc.) that must be saved in standardized locations. This document defines the complete directory structure and naming conventions.

---

## Directory Structure

```
spec-kit/
├── docs/
│   ├── specs/                          # Product Requirements Documents (PRDs) and Feature Specs
│   │   ├── PRD-001-abundance-mvp.md
│   │   ├── PRD-002-ai-cataloging.md
│   │   ├── business-strategy-validated.md
│   │   ├── business-model-canvas.md
│   │   ├── competitive-analysis-matrix.md
│   │   ├── revenue-projections.md
│   │   ├── user-persona-cards.md
│   │   ├── user-journey-maps.md
│   │   ├── trust-safety-framework.md
│   │   ├── feature-prioritization-matrix.md
│   │   ├── ux-flow-diagrams.md
│   │   ├── success-metrics.md
│   │   └── mvp-vision-features.md
│   │
│   ├── design/                         # Technical Design Documents
│   │   ├── DESIGN-001-system-architecture.md
│   │   ├── DESIGN-002-ios-client-architecture.md
│   │   ├── DESIGN-003-backend-architecture.md
│   │   ├── DESIGN-004-computer-vision-pipeline.md
│   │   ├── DESIGN-005-security-privacy-architecture.md
│   │   ├── MODULE-STRUCTURE-001-ios-module-breakdown.md
│   │   ├── DATA-MODEL-001-firestore-schema.md
│   │   ├── CLOUD-FUNCTIONS-001-function-structure.md
│   │   ├── SECURITY-RULES-001-firestore-security-rules.md
│   │   ├── STORAGE-RULES-001-firebase-storage-rules.md
│   │   ├── INTEGRATION-SPEC-001-firebase-sdk-integration.md
│   │   ├── VISION-INTEGRATION-001-ios-vision-framework.md
│   │   ├── CLOUD-AI-INTEGRATION-001-cloud-function-ai.md
│   │   ├── AI-INTEGRATION-LAYER-001-hot-swappable-ai.md
│   │   └── FALLBACK-STRATEGY-001-older-device-support.md
│   │
│   ├── adr/                            # Architecture Decision Records
│   │   ├── ADR-001-strategic-positioning.md
│   │   ├── ADR-002-platform-strategy.md
│   │   ├── ADR-003-mvp-scope-decision.md
│   │   ├── ADR-004-gcp-platform-choice.md
│   │   ├── ADR-005-monolith-first-backend.md
│   │   ├── ADR-006-rest-api-design.md
│   │   ├── ADR-007-firebase-services-integration.md
│   │   ├── ADR-008-swiftui-architecture-pattern.md
│   │   ├── ADR-009-state-management-approach.md
│   │   ├── ADR-010-dependency-injection-strategy.md
│   │   ├── ADR-011-firestore-data-model-rationale.md
│   │   ├── ADR-012-cloud-functions-organization.md
│   │   ├── ADR-013-vision-framework-strategy.md
│   │   ├── ADR-014-cloud-ai-provider-selection.md
│   │   ├── ADR-015-authentication-strategy.md
│   │   ├── ADR-016-data-encryption-approach.md
│   │   ├── ADR-017-photo-privacy-protection.md
│   │   ├── ADR-018-networking-layer.md
│   │   ├── ADR-019-image-caching-strategy.md
│   │   ├── ADR-020-dependency-management.md
│   │   ├── ADR-021-cloud-functions-runtime.md
│   │   ├── ADR-022-search-solution.md
│   │   ├── ADR-023-payment-integration.md
│   │   ├── ADR-024-primary-ai-provider.md
│   │   └── ADR-025-fallback-strategy.md
│   │
│   ├── test/                           # Test Plans and Strategies
│   │   ├── TEST-001-test-strategy.md
│   │   ├── TEST-002-security-test-plan.md
│   │   ├── TEST-003-ai-cataloging-tests.md
│   │   └── INTEGRATION-TEST-PLAN-001.md
│   │
│   ├── tech-stack/                     # Technology Stack Specifications
│   │   ├── TECH-STACK-MAP-001.md              # 🔒 FOUNDATION DOCUMENT
│   │   ├── API-CONTRACTS-001-service-interfaces.md
│   │   ├── TECH-STACK-002-ios-dependencies.md
│   │   ├── TECH-STACK-003-backend-services.md
│   │   ├── TECH-STACK-004-ai-provider-integration.md
│   │   ├── DEPENDENCIES-001-ios-dependency-list.md
│   │   └── INFRASTRUCTURE-AS-CODE-001.md
│   │
│   ├── research/                       # Research Reports and Analysis
│   │   ├── google-lens-architecture-analysis.md
│   │   ├── ios-gcp-technology-mapping.md
│   │   ├── vision-pipeline-cost-performance.md
│   │   ├── vision-poc-plan.md
│   │   ├── RESEARCH-001-ios-implementation-patterns.md
│   │   ├── RESEARCH-002-backend-implementation-patterns.md
│   │   ├── RESEARCH-003-ai-provider-comparison.md
│   │   ├── CODE-EXAMPLES-001-swift-swiftui.md
│   │   ├── CODE-EXAMPLES-002-cloud-functions.md
│   │   ├── COST-MODEL-001-ai-cataloging-cost.md
│   │   ├── PROOF-OF-CONCEPT-001-ai-benchmark.md
│   │   └── PROMPT-TEMPLATES-001-ai-prompts.md
│   │
│   ├── roadmap/                        # Implementation Roadmaps and Plans
│   │   ├── ROADMAP-001-phased-implementation-plan.md
│   │   ├── EPIC-BREAKDOWN-001-features-to-stories.md
│   │   ├── SPRINT-PLAN-TEMPLATE-001.md
│   │   └── RISK-REGISTER-001-technical-risks.md
│   │
│   ├── validation/                     # Validation and Review Reports
│   │   ├── VALIDATION-REPORT-001-technical-consistency.md
│   │   ├── VALIDATION-REPORT-002-business-technical-alignment.md
│   │   ├── THREAT-MODEL-001-stride-analysis.md
│   │   ├── PRIVACY-IMPACT-ASSESSMENT-001.md
│   │   ├── SECURITY-HARDENING-CHECKLIST-001.md
│   │   └── OUTSTANDING-QUESTIONS-001.md
│   │
│   ├── checkpoints/                    # Human Review Checkpoints
│   │   ├── CHECKPOINT-1.1-business-strategy.md
│   │   ├── CHECKPOINT-1.2-product-strategy.md
│   │   ├── CHECKPOINT-2.1-tech-stack-mapping.md
│   │   ├── CHECKPOINT-2.2-ios-architecture.md
│   │   ├── CHECKPOINT-2.3-backend-architecture.md
│   │   ├── CHECKPOINT-2.4-computer-vision.md
│   │   └── CHECKPOINT-2.5-security-privacy.md
│   │
│   └── agent-prompts/                  # Generated Agent Implementation Prompts
│       ├── AGENT-PROMPTS-001-epic-1-ai-cataloging.md
│       ├── AGENT-PROMPTS-002-epic-2-inventory-management.md
│       └── ...
│
├── prompts/                            # Input: Stage Prompts for Pipeline Execution
│   ├── stage-1.1-business-strategy/
│   ├── stage-1.2-product-strategy/
│   ├── stage-2.1-tech-stack-mapping/
│   └── ...
│
├── shared/                             # Input: Source Materials
│   ├── Abundance_App_Interpretation_Report.md
│   ├── cognitive_stylometry_stratechery_v1.0.json
│   ├── cognitive_stylometry_julie-zhuo_v1.0.json
│   └── ...
│
└── grounding/                          # Input: Reference Documentation (Optional)
    ├── swift-swiftui-refs.md
    ├── firebase-gcp-refs.md
    ├── vision-coreml-refs.md
    └── ios-security-refs.md
```

---

## Directory Purposes

### `/docs/specs/` - Product & Feature Specifications

**Purpose**: Product requirements, user research, feature specifications

**Contents**:
- PRD documents (PRD-001, PRD-002, etc.)
- Business strategy and competitive analysis
- User persona cards and journey maps
- Feature prioritization matrices
- UX flows and success metrics

**Naming Convention**: `PRD-XXX-feature-name.md`, `descriptive-name.md`

---

### `/docs/design/` - Technical Design Documents

**Purpose**: Technical architecture and design specifications

**Contents**:
- System architecture diagrams
- Component designs (iOS, backend, CV pipeline, security)
- Data models and schemas
- Integration specifications
- Module structures

**Naming Convention**: `DESIGN-XXX-component-name.md`, `COMPONENT-XXX-name.md`

---

### `/docs/adr/` - Architecture Decision Records

**Purpose**: Document architectural decisions with rationale

**Format**: Standard ADR format (Context, Decision, Consequences, Alternatives)

**Contents**:
- Strategic decisions (platform choice, architecture patterns)
- Technical decisions (libraries, frameworks, services)
- Trade-off analyses

**Naming Convention**: `ADR-XXX-decision-topic.md`

**Template**:
```markdown
# ADR-XXX: [Decision Title]

**Status**: Proposed | Accepted | Superseded
**Date**: YYYY-MM-DD
**Decision Makers**: [Persona/Human]

## Context
[Why is this decision needed? What's the background?]

## Decision
[What did we decide?]

## Rationale
[Why this decision? What factors influenced it?]

## Consequences
### Benefits
- [Positive outcome 1]
- [Positive outcome 2]

### Trade-offs
- [Negative outcome 1]
- [Mitigation strategy]

## Alternatives Considered
### Alternative 1: [Name]
- Pros: [...]
- Cons: [...]
- Why rejected: [...]

## References
- [Links to relevant docs, research, discussions]
```

---

### `/docs/test/` - Test Plans and Strategies

**Purpose**: Testing strategies, test plans, QA specifications

**Contents**:
- Overall test strategy (TEST-001)
- Feature-specific test plans
- Integration test plans
- Security test plans

**Naming Convention**: `TEST-XXX-test-name.md`, `INTEGRATION-TEST-PLAN-XXX.md`

---

### `/docs/tech-stack/` - Technology Stack Specifications

**Purpose**: Technology choices, dependencies, configurations

**Contents**:
- **TECH-STACK-MAP-001.md** (🔒 Foundation document - complete stack overview)
- API contracts and interfaces
- Platform-specific dependencies (iOS, backend, AI)
- Infrastructure-as-code templates

**Naming Convention**: `TECH-STACK-XXX-platform.md`, `API-CONTRACTS-XXX.md`

---

### `/docs/research/` - Research Reports and Analysis

**Purpose**: Research findings, technical analysis, proof-of-concepts

**Contents**:
- Google Lens architecture research
- Technology comparison matrices
- Cost models and performance analysis
- Code examples and reference implementations
- AI provider benchmarks

**Naming Convention**: `descriptive-name.md`, `RESEARCH-XXX-topic.md`

---

### `/docs/roadmap/` - Implementation Roadmaps

**Purpose**: Project planning, feature roadmaps, sprint plans

**Contents**:
- Phased implementation roadmap
- Epic and story breakdowns
- Sprint planning templates
- Risk registers

**Naming Convention**: `ROADMAP-XXX-name.md`, `EPIC-BREAKDOWN-XXX.md`

---

### `/docs/validation/` - Validation Reports

**Purpose**: Quality assurance, consistency checks, security reviews

**Contents**:
- Technical validation reports
- Business-technical alignment reviews
- Threat models (STRIDE analysis)
- Privacy impact assessments
- Security hardening checklists

**Naming Convention**: `VALIDATION-REPORT-XXX.md`, `THREAT-MODEL-XXX.md`

---

### `/docs/checkpoints/` - Human Review Checkpoints

**Purpose**: Stage completion reports for human review

**Contents**: Checkpoint report for each pipeline stage

**Naming Convention**: `CHECKPOINT-X.Y-stage-name.md`

**Format**: See checkpoint template in pipeline design doc

---

### `/docs/agent-prompts/` - Generated Implementation Prompts

**Purpose**: Agent-ready prompts for implementation tasks

**Contents**: Detailed prompts for each epic/story, ready to execute

**Naming Convention**: `AGENT-PROMPTS-XXX-epic-name.md`

---

## File Naming Conventions

### General Rules

1. **Use hyphens** for word separation: `business-model-canvas.md` (not underscores or camelCase)
2. **Use descriptive names**: `ios-client-architecture.md` (not `design2.md`)
3. **Include IDs for formal artifacts**: `PRD-001`, `ADR-015`, `DESIGN-004`
4. **Use .md extension** for all markdown files
5. **Use lowercase** unless ID prefix (PRD, ADR, DESIGN are uppercase)

### ID Prefixes

| Prefix | Type | Example |
|--------|------|---------|
| PRD-XXX | Product Requirements | PRD-001-abundance-mvp.md |
| DESIGN-XXX | Design Document | DESIGN-002-ios-architecture.md |
| ADR-XXX | Architecture Decision | ADR-013-vision-framework.md |
| TEST-XXX | Test Plan | TEST-001-test-strategy.md |
| TECH-STACK-XXX | Tech Stack | TECH-STACK-002-ios-deps.md |
| RESEARCH-XXX | Research Report | RESEARCH-001-ios-patterns.md |
| ROADMAP-XXX | Roadmap | ROADMAP-001-phased-plan.md |
| VALIDATION-XXX | Validation Report | VALIDATION-001-consistency.md |
| CHECKPOINT-X.Y | Checkpoint Report | CHECKPOINT-1.1-business.md |

---

## Special Files

### Foundation Documents (🔒)

These are **critical dependencies** that many stages rely on:

1. **TECH-STACK-MAP-001.md**
   - Location: `docs/tech-stack/`
   - Created by: Stage 2.1 (Tech Stack Mapping)
   - Used by: All Stage 2.2+ technical stages
   - Purpose: Locks in all technology choices (platform, services, APIs)

2. **PRD-001-abundance-mvp.md**
   - Location: `docs/specs/`
   - Created by: Stage 1.2 (Product Strategy)
   - Used by: All subsequent stages
   - Purpose: Defines MVP features and requirements

3. **API-CONTRACTS-001-service-interfaces.md**
   - Location: `docs/tech-stack/`
   - Created by: Stage 2.1 (Tech Stack Mapping)
   - Used by: iOS and Backend architecture stages
   - Purpose: Defines client-server API contracts

---

## Output Directory Setup

### Before Running Pipeline

Create all output directories:

```bash
# Navigate to spec-kit root
cd /Users/w/code/spec-kit

# Create all output directories
mkdir -p docs/{specs,design,adr,test,tech-stack,research,roadmap,validation,checkpoints,agent-prompts}

# Verify structure
tree docs -L 1
```

### Automated Setup Script

Create a setup script:

```bash
#!/bin/bash
# File: setup-output-dirs.sh

BASE_DIR="/Users/w/code/spec-kit/docs"

# Create all directories
mkdir -p "$BASE_DIR/specs"
mkdir -p "$BASE_DIR/design"
mkdir -p "$BASE_DIR/adr"
mkdir -p "$BASE_DIR/test"
mkdir -p "$BASE_DIR/tech-stack"
mkdir -p "$BASE_DIR/research"
mkdir -p "$BASE_DIR/roadmap"
mkdir -p "$BASE_DIR/validation"
mkdir -p "$BASE_DIR/checkpoints"
mkdir -p "$BASE_DIR/agent-prompts"

echo "✅ Output directory structure created successfully"
tree "$BASE_DIR" -L 1
```

**Usage**:
```bash
chmod +x setup-output-dirs.sh
./setup-output-dirs.sh
```

---

## Integration with Prompts

All stage prompts **must specify exact file paths** for outputs. Example:

```markdown
## Deliverables

### 1. Business Strategy Document
**File**: `docs/specs/business-strategy-validated.md`

### 2. ADR-001: Strategic Positioning
**File**: `docs/adr/ADR-001-strategic-positioning.md`
```

---

## .gitignore Considerations

**DO commit to git**:
- ✅ All `/prompts/` (input prompts)
- ✅ All `/shared/` (source materials, stylometry profiles)
- ✅ All `/docs/` (generated artifacts - these are deliverables)
- ✅ `/grounding/` (reference docs)

**DO NOT commit**:
- ❌ Temporary files (`.DS_Store`, etc.)
- ❌ Build artifacts (if any)
- ❌ Sensitive data (API keys, credentials)

**Suggested `.gitignore`**:
```
# macOS
.DS_Store

# Temporary files
*.tmp
*.temp
.cache/

# IDE
.vscode/
.idea/

# Secrets (if any)
.env
secrets/
*.key
```

---

## Verification Checklist

After each pipeline stage, verify outputs:

```bash
# Check that all expected files exist
ls -la docs/specs/PRD-001-abundance-mvp.md
ls -la docs/adr/ADR-001-strategic-positioning.md
ls -la docs/checkpoints/CHECKPOINT-1.1-business-strategy.md

# Count total artifacts generated
find docs -type f -name "*.md" | wc -l

# List all ADRs
ls -la docs/adr/
```

---

## Version Control Strategy

### Commit Strategy

**After each stage completes and is approved**:
```bash
# Stage 1.1 example
git add docs/specs/business-strategy-validated.md
git add docs/specs/business-model-canvas.md
git add docs/adr/ADR-001-strategic-positioning.md
git add docs/adr/ADR-002-platform-strategy.md
git add docs/checkpoints/CHECKPOINT-1.1-business-strategy.md

git commit -m "Stage 1.1: Business Strategy Analysis - APPROVED

Generated artifacts:
- Business strategy (validated)
- Business model canvas
- Competitive analysis matrix
- ADR-001: Strategic Positioning
- ADR-002: Platform Strategy
- Revenue projections

Checkpoint: Approved for Stage 1.2"

git push origin main
```

### Branch Strategy (Optional)

For larger pipelines, consider branches per phase:

```bash
# Create branch for Phase 1
git checkout -b phase-1-vision-strategy

# Work through Stage 1.1 and 1.2
# ... generate artifacts ...

# Merge when Phase 1 complete
git checkout main
git merge phase-1-vision-strategy
```

---

## Related Documentation

- **Pipeline Design**: `docs/abundance-analysis-pipeline-design.md`
- **Prompt README**: `prompts/README.md`
- **Stage Prompts**: `prompts/stage-X.Y-name/prompt.md`

---

**Last Updated**: 2025-10-22
**Next Review**: After Stage 1.1 completion (validate structure works in practice)
