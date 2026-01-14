# PR #1 vs Current Branch Comparison Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Systematically compare PR #1 from abundance-mvp/abundance-spec with the current verified-stage-development-2-5 branch to determine which approach is superior in completeness, quality, and alignment with project standards.

**Architecture:** Multi-phase analysis comparing documentation structure, content quality, spec compliance, and architectural decisions. Each phase produces specific artifacts that feed into a final comparative assessment.

**Tech Stack:** GitHub CLI (gh), git diff, markdown analysis, project spec-linting tools

---

## Task 1: Fetch and Catalog PR #1 Content

**Files:**
- Create: `docs/analysis/pr-1-inventory.md`
- Reference: GitHub PR #1 metadata

**Step 1: Fetch complete PR #1 file list**

Run: `gh pr view 1 --repo abundance-mvp/abundance-spec --json files,additions,deletions,headRefName`

Expected: JSON output with 13 files totaling ~10,052 additions

**Step 2: Fetch PR branch for local comparison**

```bash
git fetch https://github.com/abundance-mvp/abundance-spec.git claude/verified-stage-development-2-5-011CUxgzT5S9r2QMgki8BpQC:pr-1-comparison
```

Expected: New local branch `pr-1-comparison` created

**Step 3: Document PR #1 file inventory**

Create `docs/analysis/pr-1-inventory.md` with:
- List of all 13 files with line counts
- Organization by document type (ADR, DESIGN, TEST, CHECKPOINT, etc.)
- Identified stage focus (Stage 2.5)
- Document ID mapping

**Step 4: Commit inventory**

```bash
git add docs/analysis/pr-1-inventory.md
git commit -m "docs: add PR #1 file inventory for comparison"
```

---

## Task 2: Catalog Current Branch Content

**Files:**
- Create: `docs/analysis/current-branch-inventory.md`

**Step 1: List Stage 2.5 files on current branch**

```bash
git log fa56273 --name-only --pretty=format: | sort -u
```

Expected: List of files from Stage 2.5 commit

**Step 2: Verify current branch structure**

```bash
ls -la docs/adr/ docs/design/ docs/plans/ docs/test/ docs/validation/ docs/checkpoints/
```

Expected: Directory listings showing Stage 2.5 artifacts

**Step 3: Document current branch inventory**

Create `docs/analysis/current-branch-inventory.md` with:
- List of Stage 2.5 files with line counts
- Organization by document type
- Document ID mapping
- Commit hash reference (fa56273)

**Step 4: Commit inventory**

```bash
git add docs/analysis/current-branch-inventory.md
git commit -m "docs: add current branch inventory for comparison"
```

---

## Task 3: Side-by-Side File Comparison

**Files:**
- Create: `docs/analysis/file-by-file-diff.md`

**Step 1: Compare matching files**

For each file present in both branches:

```bash
git diff fa56273 pr-1-comparison -- docs/adr/ADR-021-authentication-hardening.md > /tmp/adr-021-diff.txt
git diff fa56273 pr-1-comparison -- docs/adr/ADR-022-data-encryption-approach.md > /tmp/adr-022-diff.txt
git diff fa56273 pr-1-comparison -- docs/adr/ADR-023-photo-privacy-protection.md > /tmp/adr-023-diff.txt
# ... repeat for all matching files
```

Expected: Diff files showing content differences

**Step 2: Identify unique files**

Files only in PR #1:
- (to be determined from inventories)

Files only in current branch:
- (to be determined from inventories)

**Step 3: Document comparison matrix**

Create `docs/analysis/file-by-file-diff.md` with table:

| File | PR #1 Size | Current Size | Diff Type | Notes |
|------|-----------|--------------|-----------|-------|
| ADR-021 | 755 | XXX | modified/new/missing | ... |

**Step 4: Commit comparison matrix**

```bash
git add docs/analysis/file-by-file-diff.md
git commit -m "docs: add file-by-file comparison matrix"
```

---

## Task 4: Spec Compliance Analysis

**Files:**
- Create: `docs/analysis/spec-compliance-pr-1.md`
- Create: `docs/analysis/spec-compliance-current.md`

**Step 1: Run spec-lint on PR #1 branch**

```bash
git checkout pr-1-comparison
# Run project spec linter if available
# Otherwise manual verification against CLAUDE.md requirements
```

Expected: List of compliance issues or confirmation

**Step 2: Document PR #1 compliance**

Create `docs/analysis/spec-compliance-pr-1.md` checking:
- Document ID format (ADR-XXX, DESIGN-XXX, TEST-XXX)
- Required sections per spec type
- Cross-references to other docs
- CLAUDE.md adherence
- Context map updates

**Step 3: Run spec-lint on current branch**

```bash
git checkout verified-stage-development-2-5
# Run same compliance checks
```

**Step 4: Document current branch compliance**

Create `docs/analysis/spec-compliance-current.md` with same checks

**Step 5: Commit compliance analysis**

```bash
git add docs/analysis/spec-compliance-*.md
git commit -m "docs: add spec compliance analysis for both branches"
```

---

## Task 5: Content Quality Assessment

**Files:**
- Create: `docs/analysis/quality-assessment.md`

**Step 1: Read and assess PR #1 ADRs**

Read all three ADRs from PR #1:
- ADR-021-authentication-hardening.md
- ADR-022-data-encryption-approach.md
- ADR-023-photo-privacy-protection.md

Assess for:
- Technical depth
- Tradeoff analysis
- Decision rationale
- Implementation guidance
- Risk assessment

**Step 2: Read and assess current branch ADRs**

Read corresponding ADRs from current branch (if they exist)

**Step 3: Read and assess design documents**

For both branches:
- DESIGN-025-security-privacy-architecture.md
- THREAT-MODEL-001-stride-analysis.md
- PRIVACY-IMPACT-ASSESSMENT-001.md
- SECURITY-HARDENING-CHECKLIST-001.md

**Step 4: Read and assess test plans**

Compare TEST-003-security-test-plan.md between branches

**Step 5: Document quality assessment**

Create `docs/analysis/quality-assessment.md` with scoring:

| Document | PR #1 Score | Current Score | Winner | Reasoning |
|----------|-------------|---------------|--------|-----------|
| ADR-021 | X/10 | X/10 | ... | ... |

Criteria:
- Completeness (0-10)
- Technical accuracy (0-10)
- Clarity (0-10)
- Actionability (0-10)

**Step 6: Commit quality assessment**

```bash
git add docs/analysis/quality-assessment.md
git commit -m "docs: add content quality assessment"
```

---

## Task 6: Architecture Comparison

**Files:**
- Create: `docs/analysis/architecture-comparison.md`

**Step 1: Extract architectural decisions from PR #1**

Key decisions from:
- [ADR-021-data-encryption-approach](../adr/ADR-021-data-encryption-approach.md): Authentication approach
- [ADR-022-photo-privacy-protection](../adr/ADR-022-photo-privacy-protection.md): Encryption strategy
- [ADR-023-authentication-authorization-strategy](../adr/ADR-023-authentication-authorization-strategy.md): Photo privacy model
- [DESIGN-025-security-privacy-architecture](../design/DESIGN-025-security-privacy-architecture.md): Overall architecture

**Step 2: Extract architectural decisions from current branch**

Same documents, extract key architectural choices

**Step 3: Compare approaches**

Create comparison table:

| Aspect | PR #1 Approach | Current Approach | Analysis |
|--------|----------------|------------------|----------|
| Auth | ... | ... | Which is better and why |
| Encryption | ... | ... | ... |

**Step 4: Assess consistency with earlier stages**

Check alignment with:
- Stage 2.2 (iOS Client) decisions
- Stage 2.3 (Backend) decisions
- Stage 2.4 (CV Pipeline) decisions

Reference: Read PLAN-SUMMARY files from stages 2.2-2.4

**Step 5: Document architecture comparison**

Complete `docs/analysis/architecture-comparison.md` with:
- Side-by-side decision comparison
- Consistency analysis
- Technical merit assessment
- Recommendation

**Step 6: Commit architecture comparison**

```bash
git add docs/analysis/architecture-comparison.md
git commit -m "docs: add architecture comparison analysis"
```

---

## Task 7: Completeness Check

**Files:**
- Create: `docs/analysis/completeness-check.md`

**Step 1: Verify required Stage 2.5 deliverables**

Per context-map.json, Stage 2.5 should produce:
- PLAN-SUMMARY-stage-2.5
- DESIGN-025
- ADR-021, ADR-022, ADR-023
- TEST-003
- Validation reports
- Checkpoint

**Step 2: Check PR #1 deliverables**

Map PR #1 files to required deliverables:
- ✓/✗ for each required item
- Note any extra deliverables

**Step 3: Check current branch deliverables**

Same mapping for current branch

**Step 4: Document completeness comparison**

Create `docs/analysis/completeness-check.md`:

| Required Deliverable | PR #1 | Current | Notes |
|---------------------|-------|---------|-------|
| PLAN-SUMMARY | ✓/✗ | ✓/✗ | ... |

**Step 5: Commit completeness check**

```bash
git add docs/analysis/completeness-check.md
git commit -m "docs: add completeness comparison"
```

---

## Task 8: Final Recommendation Report

**Files:**
- Create: `docs/analysis/COMPARISON-REPORT-pr1-vs-branch.md`

**Step 1: Read all previous analysis documents**

Read in order:
1. pr-1-inventory.md
2. current-branch-inventory.md
3. file-by-file-diff.md
4. spec-compliance-pr-1.md
5. spec-compliance-current.md
6. quality-assessment.md
7. architecture-comparison.md
8. completeness-check.md

**Step 2: Synthesize findings**

Aggregate scores and findings:
- Overall quality score (PR #1 vs Current)
- Spec compliance score
- Completeness score
- Architecture consistency score

**Step 3: Write executive summary**

Create clear recommendation:
- Which branch is superior
- By what margin (marginal vs clear winner)
- Key differentiators
- What needs to happen next

**Step 4: Write detailed findings**

Document section by section:
- File coverage comparison
- Quality comparison
- Compliance comparison
- Architecture comparison

**Step 5: Write recommendation section**

Clear action items:
- If PR #1 wins: "Merge PR #1 and archive current branch work"
- If Current wins: "Close PR #1, continue with current branch"
- If tie: "Cherry-pick best elements from both"

**Step 6: Save final report**

Write complete report to `docs/analysis/COMPARISON-REPORT-pr1-vs-branch.md`

**Step 7: Commit final report**

```bash
git add docs/analysis/COMPARISON-REPORT-pr1-vs-branch.md
git commit -m "docs: complete PR #1 vs current branch comparison analysis"
```

**Step 8: Output recommendation**

Print executive summary to console for user review

---

## Verification

After completing all tasks:

1. Verify all analysis files exist:
```bash
ls -la docs/analysis/
```

Expected 9 files:
- pr-1-inventory.md
- current-branch-inventory.md
- file-by-file-diff.md
- spec-compliance-pr-1.md
- spec-compliance-current.md
- quality-assessment.md
- architecture-comparison.md
- completeness-check.md
- COMPARISON-REPORT-pr1-vs-branch.md

2. Verify git history:
```bash
git log --oneline -9
```

Expected: 9 commits for this analysis work

3. Read final report and confirm recommendation is clear
