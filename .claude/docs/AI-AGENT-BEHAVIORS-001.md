# AI Agent Behavioral Specifications

**ID**: AI-AGENT-BEHAVIORS-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: Persona and behavior specs for Claude Code agents

## Overview

This document defines the personas, behaviors, and success criteria for all AI agents used in the Abundance MVP development workflow.

## Agent Catalog

### 1. doc-reviewer

**Role**: Documentation quality enforcer

**Trigger**: `/validate-docs` command or PR creation

**Inputs**:
- Directory path (e.g., `docs/`)
- Optional: Specific file paths

**Behavior**:
1. Extract all internal links from Markdown files (`[text](path)`)
2. Verify each linked file exists
3. Check for stale references:
   - Find `**Last Updated**` timestamps
   - Flag files >90 days old
4. Verify required sections in ADRs, PRDs, Design Docs
5. Check cross-reference validity (e.g., `ADR-010` exists)

**Output Format**:
```
❌ docs/adr/ADR-010.md:15 → Broken link: ../design/AUTH-001.md
⚠️  docs/design/DESIGN-003.md → Stale (last updated 120 days ago)
✅ docs/specs/PRD-001.md → All checks passed
```

**Success Criteria**:
- Zero broken internal links
- No stale docs >90 days in active sprints
- 100% required sections present in ADRs

**Cost**: ~$2/run (10K tokens input, 2K output)

---

### 2. drift-detector

**Role**: ADR compliance enforcer with severity-based blocking

**Trigger**: `/check-drift` command, pre-push hook, PR reviews

**Inputs**:
- Changed files (from git diff)
- ADR catalog (all `docs/adr/ADR-*.md`)
- Severity threshold (P0, P1, P2)

**Behavior**:
1. Load all ADR constraints (e.g., ADR-010: SwiftUI only, no UIKit)
2. Scan changed files for violations:
   - Swift files: Check `import UIKit` → ADR-010 violation (P0)
   - Package.swift: Check unauthorized dependencies → P1
   - Firestore rules: Check insecure patterns → P0
3. Assign severity:
   - **P0**: Architectural violations (block PR)
   - **P1**: Best practice violations (require approval)
   - **P2**: Style/convention violations (warn only)
4. Generate actionable report with fix suggestions

**Output Format**:
```
🚫 P0 VIOLATION (BLOCKS PR):
  File: ios/Views/LoginView.swift:3
  Rule: ADR-010 (SwiftUI-only architecture)
  Found: import UIKit
  Fix: Replace UIKit components with SwiftUI equivalents

⚠️  P1 VIOLATION (REQUIRES REVIEW):
  File: Package.swift:12
  Rule: ADR-015 (Dependency approval process)
  Found: Unauthorized dependency 'Alamofire'
  Fix: Open ADR to justify or use URLSession per ADR-007

ℹ️  P2 WARNING:
  File: ios/Models/User.swift:25
  Rule: ADR-020 (Naming conventions)
  Found: Variable 'usr_id' violates snake_case rule
  Fix: Rename to 'userId'
```

**Severity Thresholds**:
- P0: CI fails, PR blocked
- P1: CI passes with warning, requires 1 approval
- P2: Informational only

**Success Criteria**:
- Zero P0 violations in `main` branch
- <5% P1 violation rate (tracked in sprint retros)
- P2 violations trending down over time

**Cost**: ~$5/run (20K tokens for ADR catalog + diffs, 3K output)

---

### 3. cost-watchdog

**Role**: Budget compliance monitor with proactive alerts

**Trigger**: Daily cron (GitHub Actions), `/check-costs` command

**Inputs**:
- Budget baseline: COST-MODEL-001 ($554/month)
- Actual costs: GCP Billing API, Firebase usage metrics
- Threshold config: 10% warn, 20% critical

**Behavior**:
1. Fetch current month's costs via `gcloud billing` API
2. Compare to pro-rated budget (e.g., Day 15 → $277 expected)
3. Calculate variance percentage
4. Check cost breakdown by service:
   - Firebase Functions: $25 → $30 (20% over, flag)
   - Firestore: $15 → $14 (within budget)
5. Generate alerts with actionable recommendations

**Output Format**:
```
🚨 CRITICAL ALERT: Budget exceeded by 22% ($676 actual vs $554 budgeted)

Cost Breakdown:
  ✅ Firestore: $14 (budget: $15, -7%)
  🚫 Cloud Functions: $30 (budget: $25, +20%) ← INVESTIGATE
  ⚠️  Cloud Storage: $18 (budget: $15, +20%)
  ✅ Authentication: $8 (budget: $10, -20%)

Top Recommendations:
  1. URGENT: Review Cloud Functions cold starts (ADR-008 optimization)
  2. Storage: Enable lifecycle policies per ADR-012
  3. Monitor: Set up budget alerts in GCP Console

Action Required: Open incident, notify team lead
```

**Alert Channels**:
- Slack: #abundance-alerts (via webhook)
- GitHub Issues: Auto-create with `cost-overrun` label
- Email: tech-lead@example.com (critical only)

**Success Criteria**:
- Alerts fired within 24 hours of 10% variance
- Zero months exceeding budget without prior approval
- Cost trends visible in sprint reviews

**Cost**: ~$1/day ($30/month for daily monitoring)

---

## Agent Orchestration Patterns

### Sequential Execution

**Use case**: PR review workflow

```
1. drift-detector (check ADR compliance)
   ↓ (if P0 violations)
   └─> BLOCK PR, notify author

2. doc-reviewer (validate documentation)
   ↓ (if broken links)
   └─> COMMENT on PR with fix suggestions

3. cost-watchdog (check budget impact)
   ↓ (if >10% increase)
   └─> WARN in PR comment

4. Manual review (human approval)
```

### Parallel Execution

**Use case**: Daily health checks

```
┌─> drift-detector (scan main branch)
├─> doc-reviewer (validate all docs)
└─> cost-watchdog (check daily burn rate)
     ↓
   Aggregate results → Slack summary
```

## Agent Development Guidelines

### 1. Persona Definition Template

```markdown
**Agent Name**: [kebab-case-name]
**Role**: [One-sentence purpose]
**Trigger**: [Commands, hooks, or events]
**Inputs**: [Required data with examples]
**Behavior**: [Numbered step-by-step process]
**Output Format**: [Example output with emoji severity]
**Success Criteria**: [Measurable outcomes]
**Cost**: [Estimated tokens per run]
```

### 2. Error Handling

All agents must handle:
- **Missing inputs**: Fail gracefully with clear error message
- **API failures**: Retry with exponential backoff (3 attempts)
- **Ambiguous results**: Request human clarification, don't guess

Example:
```python
try:
    violations = detect_drift(files, adrs)
except MissingADRError as e:
    print(f"❌ ERROR: Required ADR not found: {e.adr_id}")
    print(f"   Run: ls docs/adr/ to verify ADR catalog")
    sys.exit(1)
```

### 3. Testing Agents

**Unit tests** (`.claude/agents/tests/`):
- Mock inputs with known violations
- Assert expected output format
- Verify severity assignment

**Integration tests**:
- Run against real codebase snapshots
- Compare results to manual audits
- Measure false positive rate

Example:
```bash
# Test drift-detector with known UIKit violation
echo "import UIKit" > test_file.swift
./.claude/agents/drift-detector.md --files test_file.swift
# Expected: P0 violation for ADR-010
```

## Agent Performance Metrics

Track in monthly retros:

| Agent | Runs/Month | Avg Cost | False Positives | Value Rating (1-5) |
|-------|------------|----------|-----------------|---------------------|
| doc-reviewer | 40 | $80 | 2% | 4.5 |
| drift-detector | 120 | $600 | 5% | 5.0 |
| cost-watchdog | 30 | $30 | 0% | 4.8 |

**Action thresholds**:
- False positives >10% → Refine agent rules
- Value rating <3.0 → Deprecate or redesign
- Cost >$100/month per agent → Optimize prompts

## References

- **CLAUDE-CODE-AUTOMATION-001**: Architecture overview
- **ADR-025**: Claude Code integration strategy
- **DEVELOPMENT-WORKFLOW-003**: Sprint execution guide
- **COST-MODEL-001**: Budget allocation for agents

## Changelog

- **2025-11-14**: Initial version with 3 agents (doc-reviewer, drift-detector, cost-watchdog)
