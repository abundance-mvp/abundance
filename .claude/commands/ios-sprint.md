---
name: ios-sprint
description: Start a new iOS development sprint from spec documents
---

# iOS Sprint Command

Start spec-driven iOS development sprint using verified-stage-development orchestration.

## Usage

```
/ios-sprint [spec-document-path]
```

## Examples

```
/ios-sprint docs/specs/DESIGN-042-ai-pipeline-v2.md
/ios-sprint docs/specs/DESIGN-043-catalog-ui.md
```

## What This Does

1. **Load Spec Document**
   - Read the specified DESIGN-*, ADR-*, or SPEC-* document
   - Extract requirements, architecture, schemas

2. **Validate Completeness**
   - Check for required sections (architecture, schemas, testing)
   - If incomplete: use brainstorming to fill gaps

3. **Create Implementation Plan**
   - Use superpowers:writing-plans
   - Break into bite-sized tasks (5-10 min each)
   - Assign agents and MCP servers per task
   - Save to `docs/plans/YYYY-MM-DD-<feature>.md`

4. **Execute Sprint**
   - Use superpowers:subagent-driven-development
   - Dispatch specialized subagents:
     - ios-superpowers (with Axiom) for iOS code
     - firebase-superpowers for Firebase operations
     - gcp-superpowers for non-Firebase GCP
     - gemini-integration for AI pipeline
   - Code review between tasks

5. **Verify and Complete**
   - Run all tests
   - Verify against spec requirements
   - Use finishing-a-development-branch

## Agent Routing

| Task Type | Skill | MCP Servers |
|-----------|-------|-------------|
| iOS UI/Logic | ios-superpowers | sosumi |
| Firestore/Auth | firebase-superpowers | firebase |
| Cloud Functions | firebase-superpowers | firebase |
| Non-Firebase GCP | gcp-superpowers | gcloud |
| AI/Gemini | gemini-integration | gcloud |

## Prerequisites

- Spec document exists and is readable
- MCP servers configured (sosumi, firebase, gcloud, observability)
- Axiom plugin installed
- obra/superpowers installed

## Output

- Implementation plan in `docs/plans/`
- Implemented code in appropriate directories
- All tests passing
- Ready for merge or PR
