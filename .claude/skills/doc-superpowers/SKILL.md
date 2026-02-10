---
name: doc-superpowers
description: Use when auditing documentation freshness, reviewing docs for a PR, updating stale specs/ADRs/architecture, regenerating diagrams, or syncing CLAUDE.md with project reality
---

# doc-superpowers

Documentation orchestrator that detects stale docs, dispatches domain-specific review agents, and produces actionable update plans.

## Usage

```
/doc-superpowers <action> [scope]

Actions: audit | review-pr | update | diagram | sync
Scopes: all | ios | backend | architecture | adr | brand | specs | testing | view-specs | claude-md
```

## 0. Prerequisites

Before ANY action, run both checks to get a deterministic baseline:

```bash
# 1. Hash-based staleness (code_refs changed)
uv run scripts/check_doc_freshness.py --format json

# 2. Status drift (frontmatter/index mismatches, merged branches with stale status)
uv run scripts/check_doc_status_drift.py --format json
```

Parse both JSON outputs. The freshness check gives you docs where `code_refs` have changed. The status drift check gives you docs where frontmatter disagrees with the index, or where a branch merged but the status wasn't updated. Use both to prioritize agent work.

---

## 1. Scope Detection

Match scope argument against these categories. If scope is `all`, run ALL categories in parallel.

| Scope | Doc Paths | Code Paths | Agent Focus |
|-------|-----------|------------|-------------|
| `ios` | `docs/specs/SPEC-UI-*`, `docs/view-specs/*`, `docs/testing/*` | `Sources/`, `App/`, `Tests/` | SwiftUI views, camera, inventory, profiles, view specs |
| `backend` | `docs/specs/SPEC-API-*`, `docs/specs/SPEC-DATA-*`, `docs/specs/SPEC-PIPE-*` | `functions/src/` | Cloud Functions, Firestore schema, AI pipeline, storage |
| `architecture` | `docs/architecture/*`, `docs/specs/SPEC-ARCH-*` | `Sources/`, `functions/`, `Package.swift` | System diagrams, layer architecture, module boundaries |
| `adr` | `docs/adr/*` | (cross-reference all) | ADR accuracy, status, cross-references, numbering gaps |
| `brand` | `docs/brand/*` | `Sources/Core/DesignSystem/` | Brand bible vs design system code alignment |
| `specs` | `docs/specs/*` (all) | (per code_refs) | All spec freshness, completeness, accuracy |
| `testing` | `docs/testing/*` | `Tests/`, `scripts/sim-interact.sh` | Test guides, simulator interaction docs, AXe scenarios |
| `view-specs` | `docs/view-specs/*` | `Sources/*/Views/` | View spec vs actual view implementation alignment |
| `claude-md` | `CLAUDE.md` | `.claude/`, `docs/specs/`, `scripts/`, `.github/` | Commands, MCP servers, specs table, constraints accuracy |

---

## 2. Action Routing

### `audit` — Full Documentation Health Check

1. Run `check_doc_freshness.py --format json` to get hash-based staleness list.
2. Load `docs/.doc-index.json` for metadata (statuses, last_verified dates).
3. For each scope in the request, dispatch a domain doc agent (Task tool, `general-purpose`) in parallel.
4. Each agent receives:
   - The list of docs in its scope (from doc-index)
   - Which docs are hash-stale (from freshness check)
   - Instructions to read each doc + its code_refs and report: `{accurate, stale, missing, conflicting}`
5. Merge agent results into a unified report sorted by severity:
   - **P0 Critical**: Doc describes behavior that code no longer implements
   - **P1 Stale**: Code has changed, doc probably needs updating
   - **P2 Incomplete**: Doc is missing sections for new functionality
   - **P3 Style**: Formatting, broken links, outdated terminology
6. Output the report. If `--plan` flag: also write a plan doc to `docs/plans/` with update tasks.

### `review-pr` — PR-Scoped Documentation Review

1. Run `git diff --name-only main...HEAD` to get changed files.
2. Map changed files to docs via `code_refs` in doc-index.
3. Also check: if any doc files changed, verify they're consistent with their code_refs.
4. Dispatch agents only for affected scopes (not all).
5. Output: list of docs that need updating for this PR, with specific guidance.

### `update` — Execute Documentation Updates

1. Requires a prior `audit` or `review-pr` report (or pass `--from-freshness` to use hash check).
2. For each stale doc, dispatch an agent to:
   - Read the current doc
   - Read all code_refs
   - Write an updated version of the doc
   - Update `code_ref_hashes` and `last_verified` in doc-index via `check_doc_freshness.py --update`
3. Human reviews diffs before committing.

### `diagram` — Regenerate Architecture Diagrams

1. Read `docs/architecture/catalog-pipeline.md` for existing Mermaid source.
2. Read current code to verify diagram accuracy.
3. Use `mcp-mermaid` MCP server (if available) to regenerate PNG diagrams.
4. If mermaid MCP unavailable, output updated Mermaid source for manual rendering.
5. Flag diagrams where the code has diverged from the diagram.

### `sync` — Sync Doc Index with Filesystem

1. Run `uv run scripts/update_doc_index.py sync` to add untracked files / remove deleted entries.
2. Run `uv run scripts/check_doc_status_drift.py --fix` to sync index statuses from frontmatter.
3. Run `uv run scripts/check_doc_freshness.py` to report freshness status.
4. Output summary of changes made.

---

## 3. Domain Agent Prompts

Each agent is dispatched via `Task(subagent_type="general-purpose")`. Give each agent a focused prompt:

### iOS Docs Agent

```
Review iOS documentation for accuracy against current code.

Docs to review:
{list of docs in ios scope, flagging which are hash-stale}

For each doc:
1. Read the doc completely
2. Read the code_refs directories/files
3. Report:
   - Accurate sections (no changes needed)
   - Stale sections (describe what changed in code vs what doc says)
   - Missing sections (new code not covered by doc)
   - Conflicting info (doc contradicts other docs or code)

Focus on: SwiftUI view structure, state management, navigation patterns,
accessibility, camera capture flow, inventory display, profile features.

Output format:
## {doc filename}
### Status: FRESH | STALE | MISSING_COVERAGE
### Findings:
- [P0/P1/P2/P3] Description of issue
  - Doc says: "..."
  - Code shows: "..."
  - Suggested fix: "..."
```

### Backend Docs Agent

```
Review backend documentation for accuracy against current code.

Docs to review:
{list of docs in backend scope, flagging which are hash-stale}

For each doc:
1. Read the doc completely
2. Read the code_refs (functions/src/)
3. Report accuracy of: Cloud Function signatures, Firestore schemas,
   security rules, AI pipeline prompts, storage paths, trigger configurations.

Focus on: Function names matching deployed functions, Firestore field names
matching TypeScript interfaces, prompt text matching actual prompt files,
storage bucket paths matching configuration.
```

### Architecture Docs Agent

```
Review architecture documentation and diagrams for accuracy.

Docs to review:
{list of docs in architecture scope}

For each doc:
1. Read the doc and any referenced diagrams
2. Cross-reference against current module structure (Package.swift),
   deployment config (firebase.json), and system boundaries
3. Report: module boundaries accurate? Data flow diagrams match code?
   Component interactions still valid?

For diagrams in docs/architecture/diagrams/:
1. Read the master doc (catalog-pipeline.md) for Mermaid source
2. Verify each diagram's content against current code
3. Flag diagrams that need regeneration
```

### ADR Docs Agent

```
Review Architecture Decision Records for accuracy and completeness.

Docs to review: docs/adr/*.md

For each ADR:
1. Check status field (Proposed/Approved/Deprecated) — is it accurate?
2. Check cross-references to other ADRs — do referenced ADRs exist?
3. Check if the decision is still implemented as described
4. Flag ADRs that may need updating based on recent changes
5. Check for numbering gaps (missing ADR numbers)
```

### Brand Docs Agent

```
Review brand documentation against design system implementation.

Docs to review:
{brand docs}

Compare:
1. Color tokens in brand bible vs Sources/Core/DesignSystem/Color+Brand.swift
2. Typography specs vs actual font usage in views
3. Animation specs vs Animation+Brand.swift
4. Component specs vs actual SwiftUI component implementations
```

### CLAUDE.md Agent

```
Verify CLAUDE.md accurately reflects the current project state.

Check each section:
1. Quick Commands — do all listed commands exist in .claude/commands/?
2. Repository Structure — does it match actual directory layout?
3. Critical Constraints — are all ADRs referenced still active?
4. MCP Servers table — do listed servers match .claude/settings.json?
5. Specification Reference table — does it match docs/.doc-index.json specs?
6. Documentation commands — do scripts exist and work as described?
7. CI/CD section — do workflows match .github/workflows/?

Report any discrepancies with exact line references.
```

---

## 4. Verification (`superpowers:verification-before-completion`)

**REQUIRED:** After the `update` action writes changes, verify before claiming docs are updated.

### Gate Function

```
1. IDENTIFY: What proves the doc update is correct?
2. RUN:
   - `uv run scripts/check_doc_freshness.py --format json` (confirm doc is now fresh)
   - `git diff` on updated doc (confirm changes are coherent)
   - Read updated doc + its code_refs (confirm alignment)
3. READ: Full output — hash status, diff content
4. VERIFY: Does output confirm the claim?
   - If NO: State what's still stale or misaligned
   - If YES: State claim WITH evidence (N docs updated, freshness check passing)
5. ONLY THEN: Claim docs are updated

Skip any step = unverified claim.
```

### Dispatched Agent Verification

When dispatching domain doc agents via Task, include this instruction in every agent prompt:

```
VERIFICATION REQUIRED: After reviewing docs, you MUST verify your findings by
reading both the doc AND its code_refs. Report findings WITH evidence (exact
quotes from doc vs code). No 'looks stale' without specific discrepancies.
```

Agent reports without specific evidence (exact doc text vs exact code text) are unverified.

---

## 5. Integration with Other Skills

### Called BY other skills (callback pattern):

When `ios-superpowers review` or `backend-superpowers` complete a code review, they should check if doc updates are needed:

```
After code review completes, check:
  1. Run: uv run scripts/check_doc_freshness.py --quiet
  2. If exit code 1 (stale docs detected):
     - Print: "Documentation may need updating. Run /doc-superpowers review-pr <scope>"
     - Include the list of stale docs in the review output
```

### Called BY `review-commit`:

Add documentation review as a phase in review-commit. After Step 4 (code review agents return), add:

```
Step 4.5: Documentation Review
  1. From the changed files, determine which doc scopes are affected
  2. Run: check_doc_freshness.py --format json
  3. If stale docs found, append to review summary:
     "### Documentation ({N} stale docs)"
     List each stale doc with its changed code_refs
```

### Called BY pre-push hook:

Already integrated in Task 3. The hook runs the hash check and warns about stale docs.

---

## 6. Output Formats

### Audit Report (terminal)

```
## Documentation Freshness Audit — 2026-02-08

### Summary
- Scanned: 23 specs, 20 ADRs, 8 view-specs, 2 brand docs, 1 CLAUDE.md
- Fresh: 18 | Stale: 7 | Missing coverage: 2

### P0 Critical
1. docs/specs/SPEC-UI-001-camera-capture-flow.md
   - Section "State Machine" describes 4 states, code has 6
   - CaptureSessionViewModel.swift added sweepMode and arSession states

### P1 Stale
2. docs/specs/SPEC-ARCH-002-layer1-layer2-pipeline.md
   - functions/src/ai-pipeline/ has new files not covered

(... etc)

### Actions
- Run /doc-superpowers update to generate fixes
- Run uv run scripts/check_doc_freshness.py --update <doc> after manual review
```

---

## 7. Error Handling

- **No code_refs on doc**: Skip hash check, agent does full-text comparison only
- **Missing code_ref path**: Flag as P0 ("referenced code deleted")
- **Agent timeout**: Report partial results, continue with other agents
- **Mermaid MCP unavailable**: Output Mermaid source text instead of PNG
- **No stale docs**: Report "All documentation is fresh" and exit

## 8. Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running audit without `--init` first | Run `check_doc_freshness.py --init` to establish baselines |
| Updating doc but not hashes | Always run `--update <doc>` after verifying a doc |
| Trusting hash-fresh = content-accurate | Hashes only detect file changes; semantic drift needs agent review |
| Auditing `all` on every PR | Use `review-pr` for PRs — it only checks affected scopes |
