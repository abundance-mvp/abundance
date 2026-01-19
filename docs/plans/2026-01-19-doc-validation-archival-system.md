# Documentation Validation & Archival System

**Created:** 2026-01-19
**Status:** Active
**Author:** Claude Code (Brainstorming Session)

---

## Overview

A comprehensive documentation health system that validates docs before pushing to `origin/main` and enforces aggressive archival of completed/obsolete documents.

### Scope

Validates these directories only:
- `docs/specs/`
- `docs/plans/`
- `docs/dev-workflow/`
- `docs/issues/`

### Goals

1. **No broken references** - All markdown links resolve
2. **No stale plans** - Plans marked "Active" shouldn't have merged branches
3. **No stale issues** - Issues marked "Open" shouldn't have fixes merged
4. **No code drift** - Specs reference code paths that exist
5. **Aggressive archival** - Completed/Closed/Deprecated docs move to archive immediately

---

## Architecture

### Index File: `docs/.doc-index.json`

Machine-readable registry of all tracked documentation:

```json
{
  "version": "1.0",
  "generated": "2026-01-19T10:00:00Z",
  "directories": {
    "specs": {
      "path": "docs/specs/",
      "archive_on": ["Deprecated"],
      "docs": {
        "SPEC-ARCH-001-system-overview.md": {
          "status": "Active",
          "code_refs": ["Sources/App/", "Sources/Core/"],
          "updated": "2026-01-18"
        }
      }
    },
    "plans": {
      "path": "docs/plans/",
      "archive_on": ["Completed", "Abandoned"],
      "docs": {
        "2026-01-18-code-review-remediation-plan.md": {
          "status": "Completed",
          "related_branch": "fix/code-review-p0",
          "merged": "2026-01-19"
        }
      }
    },
    "issues": {
      "path": "docs/issues/",
      "archive_on": ["Closed", "Fixed", "Won't Fix"],
      "docs": {}
    },
    "dev-workflow": {
      "path": "docs/dev-workflow/",
      "archive_on": ["Deprecated"],
      "docs": {}
    }
  },
  "archived": {}
}
```

### Validation Rules

#### Structural Checks (Fast)
- Every file in index exists on disk
- Every file in scoped directories is tracked in index
- All markdown links resolve
- No circular references

#### Status Checks
- Plans with status=Active → related_branch NOT merged to main
- Plans with status=Completed → related_branch IS merged
- Issues with status=Open → no commit contains "fixes #ISSUE-ID"
- Specs with status=Deprecated → superseded_by field exists

#### Code Drift Checks
- Each code_ref path in specs still exists

#### Archival Enforcement
- If doc.status in directory.archive_on → FAIL with "Archive required"

### Exit Codes

- `0` - All checks pass
- `1` - Validation failures (blocks push)
- `2` - Archive required (blocks push until archived)

---

## Archive Process

### Directory Structure

```
docs/archive/
├── specs/           # Archived specs
├── plans/           # Archived plans
├── issues/          # Archived issues
└── dev-workflow/    # Archived workflow docs
```

### Archive Operation

```bash
# Single file
./scripts/archive_doc.py docs/plans/2026-01-18-code-review-remediation-plan.md

# Bulk archive all ready docs
./scripts/archive_doc.py --all

# Dry-run
./scripts/archive_doc.py --all --dry-run
```

What it does:
1. Validates doc status is archival-ready
2. Moves file to `docs/archive/{type}/`
3. Updates `.doc-index.json` (removes from active, adds to archived)
4. Updates any README index tables

---

## Hook Configuration

### Pre-Push Hook: `.claude/hooks/pre-push`

```bash
#!/bin/bash
set -e

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$BRANCH" != "main" ]]; then
    exit 0
fi

echo "📚 Validating documentation health before push to main..."

if ! command -v uv &> /dev/null; then
    echo "⚠️  Warning: 'uv' not found. Skipping doc validation."
    exit 0
fi

if uv run scripts/validate_docs.py; then
    echo "✅ Documentation validated"
else
    echo ""
    echo "❌ Documentation validation failed"
    echo ""
    echo "To fix:"
    echo "  • Broken links: Update or remove the reference"
    echo "  • Archive required: ./scripts/archive_doc.py --all"
    echo "  • Status drift: Update doc status in .doc-index.json"
    echo ""
    exit 1
fi
```

### Pre-Commit Hook Update

Existing `.claude/hooks/pre-commit` updated to use:
```bash
uv run scripts/validate_docs.py --quick  # Links only
```

Full validation (`--full`) runs on pre-push only.

---

## Skill Integration

Skills auto-update the index:

### `file-issue` Skill
```python
# After creating issue
update_doc_index(
    path="docs/issues/YYYY-MM-DD-{slug}.md",
    status="Open",
    source="file-issue"
)
```

### `code-review` Skill
```python
# If review files issues
for issue in filed_issues:
    update_doc_index(path=issue.path, status="Open", source="code-review")
```

### `finishing-a-development-branch` Skill
```python
# On merge
related_docs = find_docs_by_branch(branch_name)
for doc in related_docs:
    if doc.type == "plan":
        update_doc_index(path=doc.path, status="Completed", merged=today)
    elif doc.type == "issue":
        update_doc_index(path=doc.path, status="Fixed", merged=today)
```

---

## Claude Integration

Add to `CLAUDE.md`:

```markdown
## Documentation Index

**Index File:** `docs/.doc-index.json` - Machine-readable doc registry

Before modifying documentation:
1. Check `docs/.doc-index.json` for doc status and relationships
2. When completing a plan: Update status to "Completed" and run `./scripts/archive_doc.py --all`
3. When closing an issue: Update status to "Closed" or "Fixed"
4. When deprecating a spec: Set status to "Deprecated" and add `superseded_by` field

**Validation:** `uv run scripts/validate_docs.py` - Run before pushing to main

**Archive:** `./scripts/archive_doc.py <path>` or `--all` for bulk

The pre-push hook will block if:
- Docs have archival-ready status but aren't archived
- Links are broken
- Plans marked Active have merged branches
- Code refs in specs point to deleted paths
```

---

## Implementation Checklist

### Files to Create

| File | Purpose |
|------|---------|
| `docs/.doc-index.json` | Machine-readable doc registry |
| `scripts/validate_docs.py` | Comprehensive doc validation (replace existing) |
| `scripts/archive_doc.py` | Archive docs to `docs/archive/` |
| `scripts/update_doc_index.py` | CLI to update index |
| `.claude/hooks/pre-push` | Pre-push validation hook |

### Files to Update

| File | Change |
|------|--------|
| `CLAUDE.md` | Add Documentation Index section |
| `.claude/hooks/pre-commit` | Call `validate_docs.py --quick` |
| `.claude/skills/file-issue/` | Auto-update index on issue creation |
| `scripts/setup-hooks.sh` | Add pre-push hook installation |

### Directories to Create

```
docs/archive/
├── specs/
├── plans/
├── issues/
└── dev-workflow/
```

### Implementation Order

1. Create `docs/.doc-index.json` with current doc inventory
2. Create `scripts/validate_docs.py` with all validation rules
3. Create `scripts/archive_doc.py` for archival
4. Create `scripts/update_doc_index.py` for index management
5. Create `docs/archive/` directory structure
6. Set up hooks (pre-push, update pre-commit)
7. Update `CLAUDE.md`
8. Update skills for auto-index updates

---

## Archival Policy Summary

| Directory | Archive When Status = |
|-----------|----------------------|
| `docs/specs/` | Deprecated |
| `docs/plans/` | Completed, Abandoned |
| `docs/issues/` | Closed, Fixed, Won't Fix |
| `docs/dev-workflow/` | Deprecated |

**Policy:** Aggressive - archive immediately when status changes to terminal state.

---

*Design validated through brainstorming session on 2026-01-19*
