# iOS Superpowers Workflow Architecture

**Created**: 2026-01-14  
**Status**: Design Document  
**For**: Abundance MVP iOS App Development

---

## Executive Summary

This document defines a multi-agent workflow system for iOS development that combines:
- **obra/superpowers** skill patterns for planning and execution
- **MCP servers** for GCP and Apple documentation access
- **Axiom** iOS development skills for debugging and best practices
- **Spec-driven development** using the established abundance MVP documentation structure

The architecture uses a **lead agent** (`verified-stage-development`) that orchestrates subagents based on what spec documents define for each sprint.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        LEAD AGENT: verified-stage-development               │
│                                                                             │
│  • Reads spec documents (DESIGN-*, ADR-*, SPEC-*)                          │
│  • Creates implementation plans using superpowers:writing-plans             │
│  • Dispatches specialized subagents based on task type                      │
│  • Coordinates verification and review between stages                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                ┌───────────────────┼───────────────────┐
                ▼                   ▼                   ▼
┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│    iOS SUBAGENT      │ │   GCP SUBAGENT       │ │  INTEGRATION AGENT   │
│                      │ │                      │ │                      │
│ Skills:              │ │ Skills:              │ │ Skills:              │
│ • axiom-*            │ │ • gcp-functions      │ │ • gemini-integration │
│ • apple-docs-fetcher │ │ • gcp-storage        │ │ • api-design         │
│ • ios-sprint-exec    │ │ • gcp-observability  │ │ • e2e-testing        │
│                      │ │                      │ │                      │
│ MCP Servers:         │ │ MCP Servers:         │ │ MCP Servers:         │
│ • sosumi.ai          │ │ • gcloud             │ │ • gcloud             │
│                      │ │ • storage            │ │ • sosumi.ai          │
│                      │ │ • observability      │ │                      │
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘
```

---

## Skill Hierarchy

### Level 1: Lead Orchestrator

```
.claude/skills/
└── verified-stage-development/
    ├── SKILL.md                 # Main orchestrator skill
    └── references/
        ├── spec-document-guide.md   # How to read/interpret specs
        └── agent-dispatch-matrix.md # Which agent for which task
```

### Level 2: Domain-Specific Skills

```
.claude/skills/
├── firebase-superpowers/        # PRIMARY: Firebase operations (official MCP)
│   ├── SKILL.md
│   └── references/
│       └── firebase-patterns.md
│
├── ios-superpowers/             # iOS development wrapper
│   ├── SKILL.md
│   └── references/
│       └── axiom-integration.md
│
├── gcp-superpowers/             # Non-Firebase GCP operations only
│   ├── SKILL.md
│   └── references/
│       └── gcp-patterns.md
│
├── apple-docs-fetcher/          # sosumi.ai MCP wrapper
│   ├── SKILL.md
│   └── references/
│       └── common-lookups.md
│
└── gemini-integration/          # Gemini 3 Pro patterns
    ├── SKILL.md
    └── references/
        └── tool-calling-patterns.md
```

### Level 3: Execution Skills (from superpowers)

```
Uses obra/superpowers:
├── brainstorming               # Design phase
├── writing-plans               # Plan creation
├── executing-plans             # Batch execution
├── subagent-driven-development # Fast iteration
├── test-driven-development     # TDD enforcement
├── verification-before-completion
└── finishing-a-development-branch
```

---

## Workflow Stages

### Stage 0: Spec Validation

```
┌─────────────────────────────────────────────────┐
│ verified-stage-development activates            │
│                                                 │
│ 1. Load spec documents:                         │
│    • docs/specs/DESIGN-*.md                     │
│    • docs/specs/ADR-*.md                        │
│    • docs/plans/*.md                            │
│                                                 │
│ 2. Validate spec completeness:                  │
│    • Architecture defined?                      │
│    • Data schemas specified?                    │
│    • Error handling documented?                 │
│    • Testing strategy defined?                  │
│                                                 │
│ 3. If incomplete → Use brainstorming skill      │
│    If complete → Proceed to Stage 1             │
└─────────────────────────────────────────────────┘
```

### Stage 1: Planning

```
┌─────────────────────────────────────────────────┐
│ writing-plans skill creates implementation plan │
│                                                 │
│ Plan stored at:                                 │
│   docs/plans/YYYY-MM-DD-<sprint-name>.md        │
│                                                 │
│ Plan includes:                                  │
│   • Task breakdown (5-10 min each)              │
│   • Agent assignments per task                  │
│   • Required MCP servers per task               │
│   • Verification criteria                       │
└─────────────────────────────────────────────────┘
```

### Stage 2: Execution

```
┌─────────────────────────────────────────────────┐
│ subagent-driven-development dispatches agents   │
│                                                 │
│ For each task:                                  │
│                                                 │
│ 1. Identify task domain:                        │
│    • iOS UI → ios-superpowers + axiom           │
│    • Cloud Functions → gcp-superpowers          │
│    • API Integration → gemini-integration       │
│                                                 │
│ 2. Dispatch subagent with:                      │
│    • Task from plan                             │
│    • Relevant skill(s)                          │
│    • MCP server access                          │
│                                                 │
│ 3. Code review after each task                  │
│                                                 │
│ 4. Fix issues before next task                  │
└─────────────────────────────────────────────────┘
```

### Stage 3: Verification

```
┌─────────────────────────────────────────────────┐
│ verification-before-completion skill runs       │
│                                                 │
│ 1. Run all tests (unit, integration)            │
│ 2. Verify against spec requirements             │
│ 3. Check GCP deployments                        │
│ 4. Validate iOS build succeeds                  │
│                                                 │
│ finishing-a-development-branch completes:       │
│ • Present options (merge, PR, cleanup)          │
│ • Execute chosen workflow                       │
└─────────────────────────────────────────────────┘
```

---

## MCP Server Configuration

### Required MCP Servers

```json
{
  "mcpServers": {
    "firebase": {
      "command": "npx",
      "args": ["-y", "firebase-tools@latest", "mcp"],
      "description": "PRIMARY: Official Firebase MCP - Firestore, Functions, Auth, Storage, Rules"
    },
    "sosumi": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://sosumi.ai/mcp"],
      "description": "Apple Developer documentation"
    },
    "gcloud": {
      "command": "npx",
      "args": ["-y", "@google-cloud/gcloud-mcp"],
      "description": "Non-Firebase GCP resources only"
    },
    "observability": {
      "command": "npx",
      "args": ["-y", "@google-cloud/observability-mcp"],
      "description": "Cloud Monitoring and Logging beyond Firebase"
    }
  }
}
```

### Claude Code Firebase Plugin (Recommended)
```bash
# Install official Firebase plugin
claude plugin marketplace add firebase/firebase-tools
claude plugin install firebase@firebase

# Verify
claude mcp list
# Should show: firebase: npx -y firebase-tools@latest mcp - ✓ Connected
```

### Firebase MCP with Project Directory
```json
{
  "firebase": {
    "command": "npx",
    "args": [
      "-y", "firebase-tools@latest", "mcp",
      "--dir", "/Users/w/code/abundance-mvp",
      "--only", "auth,firestore,storage,functions"
    ]
  }
}
```

---

## Skill Definitions

### 1. verified-stage-development (Lead Orchestrator)

```yaml
---
name: verified-stage-development
description: |
  Lead orchestrator for spec-driven iOS development. Use when starting a new 
  sprint or implementing features from spec documents. Reads DESIGN-*, ADR-*, 
  and SPEC-* documents, creates implementation plans, dispatches specialized 
  subagents (iOS, GCP, Integration), and coordinates verification between stages.
  
  Triggers: "implement from spec", "start sprint", "build feature from design"
---
```

**Core Responsibilities:**

1. **Spec Document Loading**
   - Read and parse spec documents from `docs/specs/`
   - Extract requirements, architecture, schemas
   - Identify dependencies and order of operations

2. **Agent Dispatch Matrix**
   
   | Task Type | Primary Skill | MCP Server | Axiom Skills |
   |-----------|---------------|------------|--------------|
   | iOS UI | ios-superpowers | sosumi | axiom-swiftui-*, axiom-liquid-glass |
   | iOS Logic | ios-superpowers | sosumi | axiom-swift-concurrency |
   | iOS Debugging | ios-superpowers | sosumi | axiom-xcode-debugging, axiom-memory-debugging |
   | **Firestore** | **firebase-superpowers** | **firebase** | - |
   | **Cloud Functions** | **firebase-superpowers** | **firebase** | - |
   | **Firebase Auth** | **firebase-superpowers** | **firebase** | - |
   | **Firebase Storage** | **firebase-superpowers** | **firebase** | - |
   | **Security Rules** | **firebase-superpowers** | **firebase** | - |
   | Non-Firebase GCP | gcp-superpowers | gcloud | - |
   | Gemini Integration | gemini-integration | firebase, gcloud | - |

3. **Quality Gates**
   - No task proceeds without passing previous task's review
   - Critical issues block progression
   - All tasks must have verification steps

### 2. ios-superpowers (iOS Domain Skill)

```yaml
---
name: ios-superpowers
description: |
  iOS development skill that wraps Axiom skills and sosumi.ai MCP server.
  Use for any iOS/Swift/SwiftUI development, debugging, or optimization.
  Automatically selects appropriate Axiom sub-skill based on task type.
  
  Triggers: "iOS code", "Swift", "SwiftUI", "Xcode", "simulator", "iOS build"
---
```

**Sub-Skill Routing:**

```markdown
## Automatic Sub-Skill Selection

When task involves:

**Build/Compile Issues:**
→ Use axiom-xcode-debugging
→ MCP: sosumi (for API lookup)

**Concurrency/Async:**
→ Use axiom-swift-concurrency
→ MCP: sosumi (Swift Concurrency docs)

**UI Development:**
→ Use axiom-liquid-glass (iOS 26+) or axiom-swiftui-*
→ MCP: sosumi (SwiftUI docs, HIG)

**Memory Issues:**
→ Use axiom-memory-debugging
→ MCP: sosumi (Instruments docs)

**Database/Persistence:**
→ Use axiom-swiftdata or axiom-database-migration
→ MCP: sosumi (Core Data/SwiftData docs)

**Testing:**
→ Use axiom-ui-testing
→ MCP: sosumi (XCTest docs)
```

### 3. apple-docs-fetcher (MCP Wrapper Skill)

```yaml
---
name: apple-docs-fetcher
description: |
  Wrapper for sosumi.ai MCP server. Use to fetch Apple Developer documentation
  and Human Interface Guidelines in AI-readable Markdown format.
  
  Triggers: "Apple docs", "look up Swift API", "HIG guidelines", "check Apple documentation"
---
```

**Usage Patterns:**

```markdown
## Common Lookups

### Swift/SwiftUI APIs
- Search: searchAppleDocumentation("SwiftUI NavigationStack")
- Fetch: fetchAppleDocumentation("/documentation/swiftui/navigationstack")

### Human Interface Guidelines
- Fetch: fetchAppleDocumentation("/design/human-interface-guidelines/foundations/color")

### Framework Documentation
- Fetch: fetchAppleDocumentation("/documentation/vision")
- Fetch: fetchAppleDocumentation("/documentation/coreml")

## Best Practices
1. Always search before fetching (get exact path)
2. Cache common lookups in context
3. Reference doc URLs in code comments
```

### 4. gcp-superpowers (GCP Domain Skill)

```yaml
---
name: gcp-superpowers
description: |
  GCP operations skill for Cloud Functions, Storage, and Firestore.
  Use for deploying, debugging, and managing GCP resources for the abundance app.
  
  Triggers: "Cloud Function", "Firebase", "Firestore", "GCS", "deploy to GCP"
---
```

**Operations:**

```markdown
## Cloud Functions

### Deploy
gcloud functions deploy <function-name> \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=./functions \
  --trigger-http

### Logs
gcloud functions logs read <function-name> --gen2

### Test locally
firebase emulators:start --only functions

## Storage

### Upload
gcloud storage cp local-file gs://bucket/path

### List
gcloud storage ls gs://bucket/

## Observability

### View logs
gcloud logging read "resource.type=cloud_function"

### Create alert
gcloud monitoring policies create --config-from-file=alert.yaml
```

### 5. gemini-integration (Gemini 3 Pro Skill)

```yaml
---
name: gemini-integration
description: |
  Skill for integrating Gemini 3 Pro with tool calling for the abundance 
  cataloging pipeline. Covers prompt engineering, tool definitions, and
  response handling patterns.
  
  Triggers: "Gemini 3 Pro", "AI pipeline", "tool calling", "cataloging"
---
```

**Core Patterns:**

```markdown
## Tool Calling Pattern

### Define Tools
```typescript
const tools = [{
  name: "tool_name",
  description: "Clear, concise description",
  parameters: {
    type: "object",
    properties: { ... },
    required: [...]
  }
}];
```

### Handle Tool Calls
```typescript
const response = await model.generateContent({
  contents: [{ role: "user", parts: [{ text: prompt }] }],
  tools: tools
});

// Check for tool calls
if (response.candidates[0].content.parts[0].functionCall) {
  const toolCall = response.candidates[0].content.parts[0].functionCall;
  const result = await executeToolCall(toolCall);
  // Continue conversation with tool result
}
```

### System Prompt Best Practices
1. Clear workflow definition
2. Confidence scoring criteria
3. Error handling instructions
4. Output format specification
```

---

## Command Definitions

### /ios-sprint (Main Entry Point)

```yaml
---
name: ios-sprint
description: Start a new iOS sprint from spec documents
---
```

```markdown
# iOS Sprint Command

## Usage
/ios-sprint [spec-document-path]

## Process
1. Load spec document
2. Validate completeness
3. Create implementation plan (writing-plans)
4. Dispatch subagents (subagent-driven-development)
5. Verify and complete (finishing-a-development-branch)

## Example
/ios-sprint docs/specs/DESIGN-042-ai-pipeline-v2.md
```

### /ios-debug (Debugging Entry Point)

```yaml
---
name: ios-debug
description: Debug iOS issues using Axiom skills
---
```

```markdown
# iOS Debug Command

## Usage
/ios-debug [issue-description]

## Process
1. Identify issue type (build, memory, concurrency, etc.)
2. Activate appropriate Axiom skill
3. Fetch relevant Apple docs via sosumi.ai
4. Systematic debugging workflow
5. Document solution

## Example
/ios-debug "BUILD FAILED - module 'AVFoundation' not found"
```

### /gcp-deploy (GCP Deployment)

```yaml
---
name: gcp-deploy
description: Deploy Cloud Functions and verify
---
```

```markdown
# GCP Deploy Command

## Usage
/gcp-deploy [function-name] [--verify]

## Process
1. Validate function code
2. Run local tests
3. Deploy to staging
4. Verify with test requests
5. Deploy to production (with --verify)

## Example
/gcp-deploy ai-pipeline --verify
```

---

## Agent Dispatch Examples

### Example 1: iOS UI Task

```
Lead Agent (verified-stage-development):
  "Implement Task 3: Create CatalogItemView"

Dispatch:
  Agent: ios-superpowers
  Skills: axiom-swiftui-26-ref, axiom-liquid-glass
  MCP: sosumi.ai
  
  Prompt: |
    Implement Task 3 from docs/plans/2026-01-14-ai-pipeline.md
    
    You are implementing the CatalogItemView SwiftUI component.
    
    Use:
    - axiom-swiftui-26-ref for iOS 26 SwiftUI patterns
    - sosumi.ai MCP to fetch SwiftUI documentation
    - axiom-liquid-glass for Liquid Glass styling
    
    Follow TDD: Write tests first, then implement.
    
    Report: What you implemented, tests, files changed.
```

### Example 2: Cloud Function Task

```
Lead Agent (verified-stage-development):
  "Implement Task 5: Deploy orchestrator Cloud Function"

Dispatch:
  Agent: gcp-superpowers
  Skills: test-driven-development
  MCP: gcloud, observability
  
  Prompt: |
    Implement Task 5 from docs/plans/2026-01-14-ai-pipeline.md
    
    You are implementing the orchestrator Cloud Function.
    
    Use:
    - gcloud MCP for deployment
    - observability MCP for logging setup
    
    Follow TDD: Write tests first, then implement.
    
    Report: What you implemented, deployment status, tests.
```

### Example 3: Gemini Integration Task

```
Lead Agent (verified-stage-development):
  "Implement Task 7: Integrate Gemini 3 Pro with tools"

Dispatch:
  Agent: gemini-integration
  Skills: test-driven-development
  MCP: gcloud
  
  Prompt: |
    Implement Task 7 from docs/plans/2026-01-14-ai-pipeline.md
    
    You are implementing Gemini 3 Pro integration with tool calling.
    
    Reference: docs/specs/DESIGN-042-ai-pipeline-v2.md
    
    Use:
    - Tool definitions from spec
    - System prompt from spec
    - Generation config from spec
    
    Follow TDD: Write tests first, then implement.
    
    Report: What you implemented, tool tests, integration tests.
```

---

## Best Practices

### 1. Spec Document Structure

```markdown
# DESIGN-XXX: Feature Name

## Overview
Brief description of what this builds

## Architecture
System diagram and component breakdown

## Data Schema
TypeScript interfaces or JSON schemas

## Tool Definitions (if AI-related)
Complete tool definitions with parameters

## System Prompt (if AI-related)
Full prompt text

## Implementation Steps
Ordered list of implementation tasks

## Verification Criteria
How to know it's done correctly
```

### 2. Plan Document Structure

```markdown
# Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans

**Goal:** One sentence

**Architecture:** 2-3 sentences

**Tech Stack:** Key technologies

---

### Task N: Component Name

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts:123-145`
- Test: `tests/exact/path/to/test.ts`

**Agent:** ios-superpowers | gcp-superpowers | gemini-integration

**MCP Servers:** sosumi | gcloud | storage | observability

**Axiom Skills:** (if iOS) axiom-xcode-debugging, etc.

**Step 1: Write failing test**
[complete code]

**Step 2: Run test**
[exact command + expected output]

**Step 3: Implement**
[complete code]

**Step 4: Verify**
[exact command + expected output]

**Step 5: Commit**
[commit message]
```

### 3. Subagent Prompt Structure

```markdown
You are implementing Task N from [plan-file].

**Context:**
- Spec document: [spec-path]
- This task builds: [component description]

**Your Skills:**
- [list of activated skills]

**MCP Servers Available:**
- [list of MCP servers and when to use each]

**Your Job:**
1. Read task steps carefully
2. Follow TDD (test first)
3. Use MCP servers for lookups
4. Verify implementation works
5. Commit your work
6. Report back

**Report Format:**
- What you implemented
- What you tested
- Test results
- Files changed
- Any issues or blockers
```

---

## Integration Checklist

### MCP Server Setup
- [ ] sosumi.ai configured and tested
- [ ] gcloud MCP configured and authenticated
- [ ] storage MCP configured
- [ ] observability MCP configured

### Skills Installation
- [ ] obra/superpowers installed
- [ ] Axiom plugin installed
- [ ] Custom skills created and validated

### Commands Created
- [ ] /ios-sprint command
- [ ] /ios-debug command
- [ ] /gcp-deploy command

### Documentation
- [ ] Spec document templates created
- [ ] Plan document templates created
- [ ] Agent dispatch matrix documented

---

## Next Steps

1. **Create verified-stage-development SKILL.md**
   - Full orchestrator implementation
   - Spec document parsing
   - Agent dispatch logic

2. **Create ios-superpowers SKILL.md**
   - Axiom skill routing
   - sosumi.ai integration
   - Common patterns

3. **Create gcp-superpowers SKILL.md**
   - Cloud Functions patterns
   - Storage operations
   - Observability setup

4. **Create gemini-integration SKILL.md**
   - Tool calling patterns
   - System prompt best practices
   - Error handling

5. **Create commands**
   - /ios-sprint
   - /ios-debug
   - /gcp-deploy

6. **Test end-to-end**
   - Use DESIGN-042 (AI Pipeline v2) as first sprint
   - Validate all agents work together
   - Refine based on results
