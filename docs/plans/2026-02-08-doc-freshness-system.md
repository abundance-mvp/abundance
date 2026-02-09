# Documentation Freshness System — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a three-layer documentation freshness system that detects stale docs via code-ref hashing, gates PRs with CI checks, and provides AI-powered auditing/updating via a `doc-superpowers` skill.

**Architecture:** Layer 1 is a deterministic Python script (`check_doc_freshness.py`) that hashes `code_refs` and compares against stored values. Layer 2 is a GitHub Actions workflow that posts PR comments listing stale docs. Layer 3 is a Claude Code skill (`doc-superpowers`) with domain-specific doc agents dispatched in parallel, integrating with existing `ios-superpowers`, `backend-superpowers`, and `review-commit`.

**Tech Stack:** Python 3 (scripts), GitHub Actions (CI), Claude Code skills/commands/hooks (automation), Mermaid via MCP (diagrams)

---

## Layer 0: Prerequisites

### Task 0: Register Untracked Directories in doc-index.json

**Files:**
- Modify: `docs/.doc-index.json`

**Context:** The doc-index currently only tracks 5 directories (`specs`, `plans`, `issues`, `brand`, `dev-workflow`). Four directories with critical documentation are completely untracked: `adr/` (21 ADRs), `architecture/` (master doc + 12 diagrams), `view-specs/` (9 component specs), and `testing/` (2 guides). Without tracking these, the hash engine (Task 2) can't detect staleness in them, and `validate_docs.py` can't check their links or archival readiness.

Two other directories exist but don't need tracking: `roadmap/` (empty), `design/` (reference images only, no markdown docs).

**Step 1: Add `adr` directory to doc-index.json**

Add the following to `directories` in `docs/.doc-index.json`. ADR statuses come from reading each file's `**Status**:` field. Code_refs are left empty for strategic/product ADRs, populated for implementation ADRs that reference specific paths.

```json
"adr": {
  "path": "docs/adr/",
  "archive_on": ["Deprecated", "Superseded"],
  "docs": {
    "ADR-001-strategic-positioning.md": {
      "status": "Proposed",
      "code_refs": [],
      "updated": "2026-01-14"
    },
    "ADR-002-platform-strategy.md": {
      "status": "Proposed",
      "code_refs": [],
      "updated": "2026-01-14"
    },
    "ADR-003-mvp-scope-phasing.md": {
      "status": "Proposed",
      "code_refs": [],
      "updated": "2026-01-14"
    },
    "ADR-005-authentication-strategy.md": {
      "status": "Approved",
      "code_refs": ["Sources/Core/Services/"],
      "updated": "2026-01-14"
    },
    "ADR-006-database-selection.md": {
      "status": "Approved",
      "code_refs": ["functions/src/"],
      "updated": "2026-01-14"
    },
    "ADR-007-api-architecture.md": {
      "status": "Approved",
      "code_refs": ["functions/src/"],
      "updated": "2026-01-14"
    },
    "ADR-008-image-storage-architecture.md": {
      "status": "Approved",
      "code_refs": ["functions/src/"],
      "updated": "2026-01-14"
    },
    "ADR-009-ios-deployment-cicd.md": {
      "status": "Approved",
      "code_refs": [".github/workflows/"],
      "updated": "2026-01-14"
    },
    "ADR-014-cloud-ai-provider-selection.md": {
      "status": "Superseded",
      "code_refs": ["functions/src/ai-pipeline/"],
      "updated": "2026-01-14"
    },
    "ADR-015-ai-reasoning-layer-architecture.md": {
      "status": "Superseded",
      "code_refs": ["functions/src/ai-pipeline/"],
      "updated": "2026-01-14"
    },
    "ADR-016-image-hosting-strategy.md": {
      "status": "Approved",
      "code_refs": ["functions/src/"],
      "updated": "2026-01-14"
    },
    "ADR-017-llm-parsing-architecture.md": {
      "status": "Superseded",
      "code_refs": ["functions/src/ai-pipeline/"],
      "updated": "2026-01-14"
    },
    "ADR-018-barcode-product-lookup-strategy.md": {
      "status": "Approved",
      "code_refs": ["Sources/CameraFeature/"],
      "updated": "2026-01-14"
    },
    "ADR-019-firestore-data-model-rationale.md": {
      "status": "Approved",
      "code_refs": ["functions/src/"],
      "updated": "2026-01-14"
    },
    "ADR-020-cloud-functions-organization.md": {
      "status": "Approved",
      "code_refs": ["functions/src/"],
      "updated": "2026-01-14"
    },
    "ADR-021-data-encryption-approach.md": {
      "status": "Approved",
      "code_refs": ["Sources/Core/"],
      "updated": "2026-01-14"
    },
    "ADR-022-photo-privacy-protection.md": {
      "status": "Approved",
      "code_refs": ["Sources/CameraFeature/"],
      "updated": "2026-01-14"
    },
    "ADR-023-authentication-authorization-strategy.md": {
      "status": "Approved",
      "code_refs": ["Sources/OnboardingFeature/"],
      "updated": "2026-01-14"
    },
    "ADR-024-observability-stack.md": {
      "status": "Approved",
      "code_refs": [],
      "updated": "2026-01-14"
    },
    "ADR-026-payment-strategy.md": {
      "status": "Proposed",
      "code_refs": [],
      "updated": "2026-01-14"
    }
  }
}
```

Note: ADR-004, ADR-010-013, ADR-025 don't exist on disk (numbering gaps). ADR-027 exists at the repo root as `docs/GLOSSARY.md` cross-reference, not in `docs/adr/` — skip if not present in that directory. Check with `ls docs/adr/ADR-027*` before adding.

**Step 2: Add `architecture` directory to doc-index.json**

```json
"architecture": {
  "path": "docs/architecture/",
  "archive_on": ["Deprecated"],
  "docs": {
    "catalog-pipeline.md": {
      "status": "Active",
      "code_refs": [
        "Sources/CameraFeature/",
        "functions/src/ai-pipeline/",
        "functions/src/"
      ],
      "updated": "2026-02-07"
    }
  }
}
```

Note: The 12 PNG diagrams in `docs/architecture/diagrams/` are outputs, not source docs — they don't get individual index entries. They're tracked indirectly through `catalog-pipeline.md` which is the master doc containing their Mermaid source.

**Step 3: Add `view-specs` directory to doc-index.json**

```json
"view-specs": {
  "path": "docs/view-specs/",
  "archive_on": ["Deprecated"],
  "docs": {
    "capture-view.md": {
      "status": "Active",
      "code_refs": ["Sources/CameraFeature/Views/"],
      "updated": "2026-01-18"
    },
    "detection-results-view.md": {
      "status": "Active",
      "code_refs": ["Sources/CameraFeature/Views/"],
      "updated": "2026-01-18"
    },
    "edit-item-sheet.md": {
      "status": "Active",
      "code_refs": ["Sources/CollectionFeature/Views/"],
      "updated": "2026-01-18"
    },
    "collection-view.md": {
      "status": "Active",
      "code_refs": ["Sources/CollectionFeature/"],
      "updated": "2026-01-18"
    },
    "item-card.md": {
      "status": "Active",
      "code_refs": ["Sources/CollectionFeature/Components/"],
      "updated": "2026-01-18"
    },
    "item-detail-view.md": {
      "status": "Active",
      "code_refs": ["Sources/CollectionFeature/Views/"],
      "updated": "2026-01-18"
    },
    "photo-carousel-view.md": {
      "status": "Active",
      "code_refs": ["Sources/CollectionFeature/Components/"],
      "updated": "2026-01-18"
    },
    "profile-view.md": {
      "status": "Active",
      "code_refs": ["Sources/ProfileFeature/"],
      "updated": "2026-01-18"
    },
    "sign-in-view.md": {
      "status": "Active",
      "code_refs": ["Sources/OnboardingFeature/"],
      "updated": "2026-01-18"
    }
  }
}
```

**Step 4: Add `testing` directory to doc-index.json**

```json
"testing": {
  "path": "docs/testing/",
  "archive_on": ["Deprecated"],
  "docs": {
    "SIMULATOR-INTERACTION.md": {
      "status": "Active",
      "code_refs": ["scripts/"],
      "updated": "2026-01-20"
    },
    "AXE-TEST-SCENARIOS.md": {
      "status": "Active",
      "code_refs": [
        "Sources/CollectionFeature/Views/",
        "Sources/ProfileFeature/",
        "Sources/CameraFeature/Views/"
      ],
      "updated": "2026-01-20"
    }
  }
}
```

**Step 5: Update `validate_docs.py` to handle new directory schemas**

The existing `validate_docs.py` already iterates over all directories in the index generically — no code changes needed. The `validate_code_refs` function currently only checks `specs` directory by name (line 188: `specs = index.get("directories", {}).get("specs", {}).get("docs", {})`). Fix this to check ALL directories with `code_refs`:

In `scripts/validate_docs.py`, replace the `validate_code_refs` function body to iterate all directories instead of just `specs`:

```python
def validate_code_refs(index: dict, project_root: Path, result: ValidationResult):
    """Check that code_refs in all docs point to existing paths."""
    for dir_name, dir_info in index.get("directories", {}).items():
        dir_path = dir_info.get("path", "")
        for filename, doc_info in dir_info.get("docs", {}).items():
            code_refs = doc_info.get("code_refs", [])
            for ref in code_refs:
                ref_path = project_root / ref
                if not ref_path.exists():
                    result.add_warning(
                        "code_drift",
                        f"{dir_path}{filename}",
                        f"Code reference '{ref}' does not exist"
                    )
```

**Step 6: Verify the index is valid JSON and passes validation**

Run: `python3 -c "import json; json.load(open('docs/.doc-index.json'))"`
Expected: No output (success)

Run: `uv run scripts/validate_docs.py --verbose`
Expected: All checks pass. May show warnings for superseded ADRs that match archival triggers.

**Step 7: Commit**

```bash
git add docs/.doc-index.json scripts/validate_docs.py
git commit -m "chore(docs): register adr, architecture, view-specs, testing in doc-index

Adds 4 previously untracked directories to .doc-index.json:
- adr/ (21 ADRs with statuses and code_refs)
- architecture/ (catalog-pipeline master doc)
- view-specs/ (9 component specs)
- testing/ (2 test guides)

Also fixes validate_docs.py to check code_refs across all
directories, not just specs/."
```

---

## Layer 1: Hash Engine

### Task 1: Extend doc-index.json Schema

**Files:**
- Modify: `docs/.doc-index.json`

**Step 1: Add `code_ref_hashes` and `last_verified` fields to every doc entry that has `code_refs`**

Task 0 registered `adr/`, `architecture/`, `view-specs/`, and `testing/` — so all directories now have entries. For each doc entry across ALL directories (`specs`, `brand`, `dev-workflow`, `adr`, `architecture`, `view-specs`, `testing`) that has non-empty `code_refs`, add two new fields. The `code_ref_hashes` field stores a mapping of each code_ref path to a content hash. The `last_verified` field stores the date a human or agent last confirmed the doc matches its code.

Compute initial hashes by running the script from Task 2 with `--init`. For now, just add the empty fields to establish the schema:

```json
{
  "SPEC-ARCH-001-system-overview.md": {
    "status": "Active",
    "code_refs": ["Sources/", "functions/"],
    "code_ref_hashes": {},
    "last_verified": null,
    "updated": "2026-01-18"
  }
}
```

Every doc entry with `code_refs` gets `code_ref_hashes: {}` and `last_verified: null`. Entries without `code_refs` (business strategy docs, cost model, ADR-001/002/003/024/026) are unchanged.

**Step 2: Verify the index is valid JSON**

Run: `python3 -c "import json; json.load(open('docs/.doc-index.json'))"`
Expected: No output (success)

**Step 3: Commit**

```bash
git add docs/.doc-index.json
git commit -m "chore(docs): extend doc-index schema with code_ref_hashes and last_verified"
```

---

### Task 2: Create `check_doc_freshness.py` Script

**Files:**
- Create: `scripts/check_doc_freshness.py`
- Reference: `scripts/validate_docs.py` (follow same patterns: argparse, `get_project_root()`, `load_index()`, `ValidationResult`)

**Step 1: Write the test — verify the script detects a stale doc**

Create a minimal integration test. The script should be testable by temporarily modifying a code_ref file after hashes are stored.

```bash
# Manual test procedure (run after Step 3):
# 1. Run --init to populate hashes
# 2. Touch a source file referenced by a spec
# 3. Run the script — should report that spec as stale
```

**Step 2: Write the script**

The script must:

1. **Load** `docs/.doc-index.json`
2. **Compute** a content hash for each `code_ref` path:
   - If path is a **directory** (e.g. `Sources/CameraFeature/`): hash = SHA256 of sorted concatenation of `(relative_path, file_size, mtime_ns)` for all files in the directory tree. This is fast (~5ms for 100 files) and detects any file add/remove/modify without reading file contents.
   - If path is a **file**: hash = SHA256 of file contents.
   - If path **doesn't exist**: hash = `"MISSING"` (and flag as warning).
3. **Compare** computed hashes against stored `code_ref_hashes`.
4. **Report** docs where any hash differs (= potentially stale).
5. **Modes:**
   - Default: Print stale docs to stdout, exit 0 if clean, exit 1 if stale.
   - `--init`: Compute and store all hashes, set `last_verified` to today. Write back to index.
   - `--update <doc-path>`: Update hashes for one specific doc after verification. Set `last_verified` to today.
   - `--format github-comment`: Output as markdown suitable for a PR comment body.
   - `--format json`: Output as JSON for programmatic consumption.
   - `--quiet`: Exit code only, no stdout (for hooks).

```python
#!/usr/bin/env python3
"""
Documentation freshness checker.

Computes content hashes of code_refs and compares against stored values
in docs/.doc-index.json to detect potentially stale documentation.

Exit codes:
- 0: All docs are fresh (hashes match)
- 1: Stale docs detected (hashes differ)
- 2: No hashes stored yet (run --init first)
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
from datetime import date
from pathlib import Path


def get_project_root() -> Path:
    """Get project root from git."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        print("Error: Not in a git repository", file=sys.stderr)
        sys.exit(1)


def load_index(project_root: Path) -> dict:
    """Load doc index."""
    index_path = project_root / "docs" / ".doc-index.json"
    if not index_path.exists():
        print("Error: docs/.doc-index.json not found", file=sys.stderr)
        sys.exit(1)
    with open(index_path) as f:
        return json.load(f)


def save_index(index: dict, project_root: Path):
    """Save doc index with updated timestamp."""
    index_path = project_root / "docs" / ".doc-index.json"
    index["generated"] = f"{date.today().isoformat()}T00:00:00Z"
    with open(index_path, "w") as f:
        json.dump(index, f, indent=2)
        f.write("\n")


def hash_path(path: Path) -> str:
    """Compute hash for a file or directory."""
    if not path.exists():
        return "MISSING"

    if path.is_file():
        return hashlib.sha256(path.read_bytes()).hexdigest()[:16]

    # Directory: hash metadata of all files (fast, no content reads)
    entries = []
    for root, _dirs, files in os.walk(path):
        for fname in sorted(files):
            fpath = Path(root) / fname
            try:
                stat = fpath.stat()
                rel = fpath.relative_to(path)
                entries.append(f"{rel}:{stat.st_size}:{stat.st_mtime_ns}")
            except OSError:
                continue

    content = "\n".join(sorted(entries))
    return hashlib.sha256(content.encode()).hexdigest()[:16]


def get_docs_with_refs(index: dict) -> list[tuple[str, str, dict]]:
    """Return (dir_name, filename, doc_info) for docs with code_refs."""
    results = []
    for dir_name, dir_info in index.get("directories", {}).items():
        for filename, doc_info in dir_info.get("docs", {}).items():
            if doc_info.get("code_refs"):
                results.append((dir_name, filename, doc_info))
    return results


def check_freshness(index: dict, project_root: Path) -> list[dict]:
    """Check all docs for staleness. Returns list of stale doc reports."""
    stale = []

    for dir_name, filename, doc_info in get_docs_with_refs(index):
        stored_hashes = doc_info.get("code_ref_hashes", {})
        if not stored_hashes:
            continue  # No baseline yet — skip (use --init)

        changed_refs = []
        missing_refs = []

        for ref in doc_info["code_refs"]:
            ref_path = project_root / ref
            current_hash = hash_path(ref_path)
            stored_hash = stored_hashes.get(ref, None)

            if current_hash == "MISSING":
                missing_refs.append(ref)
            elif stored_hash is None:
                changed_refs.append({"ref": ref, "reason": "new ref (not in stored hashes)"})
            elif current_hash != stored_hash:
                changed_refs.append({"ref": ref, "reason": "content changed"})

        if changed_refs or missing_refs:
            dir_path = index["directories"][dir_name]["path"]
            stale.append({
                "doc": f"{dir_path}{filename}",
                "dir": dir_name,
                "status": doc_info.get("status", "Unknown"),
                "last_verified": doc_info.get("last_verified"),
                "updated": doc_info.get("updated"),
                "changed_refs": changed_refs,
                "missing_refs": missing_refs,
            })

    return stale


def init_hashes(index: dict, project_root: Path):
    """Compute and store hashes for all docs with code_refs."""
    today = date.today().isoformat()
    count = 0

    for _dir_name, _filename, doc_info in get_docs_with_refs(index):
        hashes = {}
        for ref in doc_info["code_refs"]:
            ref_path = project_root / ref
            hashes[ref] = hash_path(ref_path)
        doc_info["code_ref_hashes"] = hashes
        doc_info["last_verified"] = today
        count += 1

    save_index(index, project_root)
    print(f"Initialized hashes for {count} docs")


def update_doc_hashes(index: dict, project_root: Path, doc_path: str):
    """Update hashes for a single doc after verification."""
    today = date.today().isoformat()

    for dir_name, dir_info in index.get("directories", {}).items():
        for filename, doc_info in dir_info.get("docs", {}).items():
            full_doc_path = f"{dir_info['path']}{filename}"
            if full_doc_path == doc_path or filename == doc_path:
                if not doc_info.get("code_refs"):
                    print(f"Doc {doc_path} has no code_refs")
                    return
                hashes = {}
                for ref in doc_info["code_refs"]:
                    ref_path = project_root / ref
                    hashes[ref] = hash_path(ref_path)
                doc_info["code_ref_hashes"] = hashes
                doc_info["last_verified"] = today
                save_index(index, project_root)
                print(f"Updated hashes for {doc_path}")
                return

    print(f"Doc not found in index: {doc_path}", file=sys.stderr)
    sys.exit(1)


def format_text(stale: list[dict]) -> str:
    """Format stale docs as plain text."""
    if not stale:
        return "All documentation is fresh."

    lines = [f"Found {len(stale)} potentially stale doc(s):\n"]
    for item in stale:
        lines.append(f"  {item['doc']}  (last verified: {item['last_verified'] or 'never'})")
        for ref in item["changed_refs"]:
            lines.append(f"    - {ref['ref']}: {ref['reason']}")
        for ref in item["missing_refs"]:
            lines.append(f"    - {ref}: MISSING (deleted or moved)")
    lines.append("")
    lines.append("To mark a doc as verified after review:")
    lines.append("  uv run scripts/check_doc_freshness.py --update <doc-path>")
    return "\n".join(lines)


def format_github_comment(stale: list[dict]) -> str:
    """Format stale docs as GitHub PR comment markdown."""
    if not stale:
        return ""

    lines = [
        "## Documentation Freshness Check",
        "",
        f"This PR touches code referenced by **{len(stale)} doc(s)** that may need updating:",
        "",
        "| Document | Last Verified | Changed References |",
        "|----------|---------------|-------------------|",
    ]

    for item in stale:
        refs = ", ".join(
            [f"`{r['ref']}`" for r in item["changed_refs"]]
            + [f"`{r}` (MISSING)" for r in item["missing_refs"]]
        )
        verified = item["last_verified"] or "never"
        lines.append(f"| `{item['doc']}` | {verified} | {refs} |")

    lines.append("")
    lines.append("*Run `uv run scripts/check_doc_freshness.py --update <doc>` after reviewing each doc.*")
    return "\n".join(lines)


def format_json(stale: list[dict]) -> str:
    """Format stale docs as JSON."""
    return json.dumps(stale, indent=2)


def main():
    parser = argparse.ArgumentParser(description="Check documentation freshness")
    parser.add_argument("--init", action="store_true",
                        help="Initialize hashes for all docs")
    parser.add_argument("--update", metavar="DOC",
                        help="Update hashes for a specific doc after review")
    parser.add_argument("--format", choices=["text", "github-comment", "json"],
                        default="text", help="Output format")
    parser.add_argument("--quiet", "-q", action="store_true",
                        help="Exit code only, no output")
    parser.add_argument("--project-root", type=Path, default=None)

    args = parser.parse_args()
    project_root = args.project_root or get_project_root()
    index = load_index(project_root)

    if args.init:
        init_hashes(index, project_root)
        return

    if args.update:
        update_doc_hashes(index, project_root, args.update)
        return

    # Check freshness
    stale = check_freshness(index, project_root)

    if not args.quiet:
        if args.format == "github-comment":
            output = format_github_comment(stale)
        elif args.format == "json":
            output = format_json(stale)
        else:
            output = format_text(stale)

        if output:
            print(output)

    sys.exit(1 if stale else 0)


if __name__ == "__main__":
    main()
```

**Step 3: Run `--init` to populate baseline hashes**

Run: `uv run scripts/check_doc_freshness.py --init`
Expected: `Initialized hashes for N docs` (where N = number of docs with code_refs)

**Step 4: Verify detection — touch a source file and check**

Run:
```bash
touch Sources/CameraFeature/Views/CaptureView.swift
uv run scripts/check_doc_freshness.py
```
Expected: Reports `docs/specs/SPEC-UI-001-camera-capture-flow.md` as stale (because `Sources/CameraFeature/` hash changed).

**Step 5: Verify `--update` clears the staleness**

Run:
```bash
uv run scripts/check_doc_freshness.py --update docs/specs/SPEC-UI-001-camera-capture-flow.md
uv run scripts/check_doc_freshness.py
```
Expected: First command prints `Updated hashes for ...`. Second command reports all docs fresh.

**Step 6: Commit**

```bash
git add scripts/check_doc_freshness.py docs/.doc-index.json
git commit -m "feat(docs): add check_doc_freshness.py with code-ref hash tracking"
```

---

### Task 3: Integrate Hash Check into Pre-Push Hook

**Files:**
- Modify: `.claude/hooks/pre-push` (lines 12-46)

**Step 1: Add freshness check as a warning step after existing validation**

Insert a new block between the existing validation and the final `exit 0`. This runs the freshness check as a **warning** (non-blocking) — it prints stale docs but doesn't prevent the push. The existing link/archival validation remains blocking.

```bash
# --- After the existing validation block (line 46), before `exit 0` ---

# Check documentation freshness (warning only, non-blocking)
echo ""
echo "Checking documentation freshness..."
freshness_result=0
uv run scripts/check_doc_freshness.py --quiet || freshness_result=$?

if [[ $freshness_result -eq 1 ]]; then
    echo ""
    echo "⚠️  Some documentation may be stale (code changed since last verification)."
    echo "  Run: uv run scripts/check_doc_freshness.py"
    echo "  To review and update: uv run scripts/check_doc_freshness.py --update <doc>"
    echo ""
    # Non-blocking — push continues
elif [[ $freshness_result -eq 2 ]]; then
    echo "  ℹ️  No freshness baselines stored. Run: uv run scripts/check_doc_freshness.py --init"
fi
```

**Step 2: Verify the hook runs both checks**

Run: `bash .claude/hooks/pre-push` (simulates a push to main — set BRANCH=main)
Expected: Prints both doc validation results AND freshness warning.

**Step 3: Commit**

```bash
git add .claude/hooks/pre-push
git commit -m "feat(hooks): add doc freshness warning to pre-push hook"
```

---

## Layer 2: CI Gate

### Task 4: Create `doc-freshness.yml` GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/doc-freshness.yml`

**Step 1: Write the workflow**

This workflow triggers on PRs to `main` and posts a comment listing potentially stale docs based on which files the PR changes.

```yaml
name: Documentation Freshness Check

on:
  pull_request:
    branches: [main]

jobs:
  doc-freshness:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Check doc freshness
        id: freshness
        run: |
          python3 scripts/check_doc_freshness.py --format github-comment > freshness.md 2>/dev/null || true
          if [ -s freshness.md ]; then
            echo "has_stale=true" >> "$GITHUB_OUTPUT"
          else
            echo "has_stale=false" >> "$GITHUB_OUTPUT"
          fi

      - name: Post or update PR comment
        if: steps.freshness.outputs.has_stale == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = fs.readFileSync('freshness.md', 'utf8');
            const marker = '<!-- doc-freshness-check -->';
            const fullBody = `${marker}\n${body}`;

            // Find existing comment
            const comments = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
            });
            const existing = comments.data.find(c => c.body.includes(marker));

            if (existing) {
              await github.rest.issues.updateComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: existing.id,
                body: fullBody,
              });
            } else {
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
                body: fullBody,
              });
            }
```

**Step 2: Verify YAML is valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/doc-freshness.yml'))"`
Expected: No output (success). If `yaml` not available: `python3 -c "import json; print('YAML syntax check requires PyYAML')"` — visual inspection is sufficient.

**Step 3: Commit**

```bash
git add .github/workflows/doc-freshness.yml
git commit -m "ci(docs): add doc-freshness PR comment workflow"
```

---

### Task 5: Add Freshness Check to Existing `spec-validation.yml`

**Files:**
- Modify: `.github/workflows/spec-validation.yml`

**Step 1: Read the existing workflow to understand its structure**

Read `.github/workflows/spec-validation.yml` to find where to add the freshness step.

**Step 2: Add a freshness step after existing checks**

Add as a new step in the existing job. Non-blocking (`continue-on-error: true`) — it's informational.

```yaml
      - name: Check doc freshness
        continue-on-error: true
        run: |
          python3 scripts/check_doc_freshness.py || echo "Stale docs detected (non-blocking)"
```

**Step 3: Commit**

```bash
git add .github/workflows/spec-validation.yml
git commit -m "ci(docs): add freshness check to spec-validation workflow"
```

---

## Layer 3: AI Orchestrator (`doc-superpowers` Skill)

### Task 6: Create the `doc-superpowers` Skill

**Files:**
- Create: `.claude/skills/doc-superpowers/SKILL.md`

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills to create this skill. Follow the TDD approach: baseline test (pressure scenario without skill) -> write skill -> verify compliance.

**Step 1: Baseline test — run a pressure scenario WITHOUT the skill**

Launch a subagent (Task tool, `general-purpose`) with this prompt and observe what it does:

```
You are reviewing documentation for the abundance-mvp project. The code in Sources/CameraFeature/
has changed significantly since the specs in docs/specs/SPEC-UI-001-camera-capture-flow.md were written.

Review the spec against the current code and tell me what's stale. Also check if
docs/architecture/catalog-pipeline.md needs updating, and whether CLAUDE.md accurately
reflects the current project structure.
```

Document the baseline behavior: Does it check all scopes? Does it miss cross-references? Does it update the doc-index? Does it verify diagrams?

**Step 2: Write the skill based on baseline gaps**

Create `.claude/skills/doc-superpowers/SKILL.md` with this content:

```markdown
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

Before ANY action, run the hash engine to get a deterministic staleness baseline:

```bash
uv run scripts/check_doc_freshness.py --format json
```

Parse the JSON output. This gives you the list of docs where `code_refs` have changed since last verification. Use this to prioritize agent work — don't waste agents on docs the hash engine already confirms are fresh.

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
2. Run `uv run scripts/check_doc_freshness.py` to report freshness status.
3. Output summary of changes made.

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

## 4. Integration with Other Skills

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

## 5. Output Formats

### Audit Report (terminal)

```
## Documentation Freshness Audit — 2026-02-08

### Summary
- Scanned: 23 specs, 20 ADRs, 8 view-specs, 2 brand docs, 1 CLAUDE.md
- Fresh: 18 | Stale: 7 | Missing coverage: 2

### P0 Critical
1. docs/specs/SPEC-UI-001-camera-capture-flow.md
   - Section "State Machine" describes 4 states, code has 6
   - CaptureSessionViewModel.swift added `sweepMode` and `arSession` states

### P1 Stale
2. docs/specs/SPEC-ARCH-002-layer1-layer2-pipeline.md
   - functions/src/ai-pipeline/ has new files not covered

(... etc)

### Actions
- Run `/doc-superpowers update` to generate fixes
- Run `uv run scripts/check_doc_freshness.py --update <doc>` after manual review
```

---

## 6. Error Handling

- **No code_refs on doc**: Skip hash check, agent does full-text comparison only
- **Missing code_ref path**: Flag as P0 ("referenced code deleted")
- **Agent timeout**: Report partial results, continue with other agents
- **Mermaid MCP unavailable**: Output Mermaid source text instead of PNG
- **No stale docs**: Report "All documentation is fresh" and exit

## 7. Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running audit without `--init` first | Run `check_doc_freshness.py --init` to establish baselines |
| Updating doc but not hashes | Always run `--update <doc>` after verifying a doc |
| Trusting hash-fresh = content-accurate | Hashes only detect file changes; semantic drift needs agent review |
| Auditing `all` on every PR | Use `review-pr` for PRs — it only checks affected scopes |
```

**Step 3: Re-run the baseline test WITH the skill loaded**

Launch the same subagent with the skill context injected and verify it now:
- Runs hash check first
- Dispatches scoped agents
- Produces prioritized report
- Suggests doc-index updates

**Step 4: Commit**

```bash
git add .claude/skills/doc-superpowers/SKILL.md
git commit -m "feat(skills): add doc-superpowers skill for documentation freshness orchestration"
```

---

### Task 7: Create the `doc-superpowers` Command

**Files:**
- Create: `.claude/commands/doc-superpowers.md`

**Step 1: Write the command file**

Follow the pattern from `polish.md` and `ios-superpowers.md` — thin command that points to the skill.

```markdown
---
name: doc-superpowers
description: Documentation freshness orchestrator — audit stale docs, review PR impact, update specs, regenerate diagrams, sync CLAUDE.md
---

# doc-superpowers

**This command invokes the `doc-superpowers` skill.** Read and follow `.claude/skills/doc-superpowers/SKILL.md`.

## Quick Reference

```
hash check → scope detection → dispatch agents (parallel) → merge → report
```

**Arguments:**
- `/doc-superpowers audit [scope]` — Full documentation health check
- `/doc-superpowers audit all --plan` — Audit + write update plan to docs/plans/
- `/doc-superpowers review-pr [scope]` — PR-scoped doc review (changed files only)
- `/doc-superpowers update` — Execute updates from prior audit
- `/doc-superpowers diagram` — Regenerate architecture diagrams
- `/doc-superpowers sync` — Sync doc-index with filesystem + freshness report

**Scopes:** `all` | `ios` | `backend` | `architecture` | `adr` | `brand` | `specs` | `testing` | `view-specs` | `claude-md`

**Skill location:** `.claude/skills/doc-superpowers/SKILL.md`
```

**Step 2: Commit**

```bash
git add .claude/commands/doc-superpowers.md
git commit -m "feat(commands): add /doc-superpowers command"
```

---

### Task 8: Integrate `doc-superpowers` into `review-commit`

**Files:**
- Modify: `.claude/commands/review-commit.md`

**Step 1: Add Step 4.5 — Documentation freshness check**

After the existing Step 4 (Dispatch Parallel Review Agents) and before Step 5 (Synthesize Results), add a new step:

```markdown
### Step 4.5: Documentation Freshness Check

After code review agents return, check if changed files affect documentation:

1. Run `uv run scripts/check_doc_freshness.py --format json` to get stale docs.
2. Map changed files to doc scopes using the same domain classification from Step 2.
3. If stale docs found, add to the synthesis in Step 5:

```markdown
### Documentation (N stale docs)
| Document | Changed Code Refs | Last Verified |
|----------|-------------------|---------------|
| `docs/specs/SPEC-UI-001...` | `Sources/CameraFeature/` | 2026-01-18 |

**Action:** Run `/doc-superpowers review-pr` for detailed analysis.
```

4. If no stale docs: add `### Documentation — All fresh` to synthesis.
```

**Step 2: Commit**

```bash
git add .claude/commands/review-commit.md
git commit -m "feat(review): add doc freshness check to review-commit pipeline"
```

---

### Task 9: Update CLAUDE.md with Doc Superpowers

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add doc-superpowers to the Quick Commands section**

Add after the Issue Tracking section:

```markdown
# Documentation Health
/project:doc-superpowers audit [scope]    # Audit docs for staleness across scopes
/project:doc-superpowers review-pr        # Check if PR makes docs stale
/project:doc-superpowers update           # Execute doc updates from audit
/project:doc-superpowers diagram          # Regenerate architecture diagrams
/project:doc-superpowers sync             # Sync doc-index + freshness check
```

**Step 2: Add freshness commands to the Documentation section**

In the existing "Documentation" section, add after the existing commands:

```markdown
### Freshness Checking

```bash
# Check which docs are stale (code changed since last verification)
uv run scripts/check_doc_freshness.py

# Initialize hash baselines (run once or after major refactor)
uv run scripts/check_doc_freshness.py --init

# Mark a doc as verified after review
uv run scripts/check_doc_freshness.py --update docs/specs/SPEC-UI-001-camera-capture-flow.md
```
```

**Step 3: Update MCP Servers table if mermaid MCP is configured**

Only add if the mermaid MCP server is actually configured. Check `.claude/settings.json` first.

**Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add doc-superpowers and freshness checking to CLAUDE.md"
```

---

### Task 10: Add Doc Scopes to `ios-superpowers` and `backend-superpowers` Review Callbacks

**Files:**
- Modify: `.claude/skills/ios-superpowers/SKILL.md`
- Modify: `.claude/skills/backend-superpowers/SKILL.md`

**Step 1: Add doc freshness callback to ios-superpowers review action**

At the end of the `review` action routing in the ios-superpowers skill, add:

```markdown
### Post-Review: Documentation Check

After code review completes for the `review` action:

1. Run: `uv run scripts/check_doc_freshness.py --quiet`
2. If exit code 1 (stale docs):
   - Print: "⚠️ Documentation may need updating. Stale docs detected for iOS scope."
   - Print: "Run `/doc-superpowers review-pr ios` for details."
3. If exit code 0: no action needed.
```

**Step 2: Add same callback to backend-superpowers**

Same pattern but scoped to `backend`:

```markdown
### Post-Review: Documentation Check

After backend operations that modify code:

1. Run: `uv run scripts/check_doc_freshness.py --quiet`
2. If exit code 1:
   - Print: "⚠️ Documentation may need updating. Run `/doc-superpowers review-pr backend`"
```

**Step 3: Commit**

```bash
git add .claude/skills/ios-superpowers/SKILL.md .claude/skills/backend-superpowers/SKILL.md
git commit -m "feat(skills): add doc freshness callbacks to ios/backend-superpowers review actions"
```

---

### Task 11: Register New Docs in Doc Index

**Files:**
- Modify: `docs/.doc-index.json`

**Step 1: Add this plan to the doc-index**

Run:
```bash
uv run scripts/update_doc_index.py add docs/plans/2026-02-08-doc-freshness-system.md --status Active --branch docs/doc-freshness-system
```

**Step 2: Run full validation**

Run: `uv run scripts/validate_docs.py --verbose`
Expected: All checks pass.

**Step 3: Run freshness init to include any new docs**

Run: `uv run scripts/check_doc_freshness.py --init`
Expected: Updated hash count.

**Step 4: Commit**

```bash
git add docs/.doc-index.json
git commit -m "chore(docs): register doc-freshness plan and refresh hashes"
```

---

## Post-Implementation Verification

### Verify Layer 1 (Hash Engine)

```bash
# Should report current state
uv run scripts/check_doc_freshness.py

# Should output valid JSON
uv run scripts/check_doc_freshness.py --format json | python3 -m json.tool

# Should output markdown table
uv run scripts/check_doc_freshness.py --format github-comment
```

### Verify Layer 2 (CI Gate)

```bash
# Validate workflow YAML
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/doc-freshness.yml'))" 2>/dev/null || echo "Check YAML manually"

# Verify it would trigger on PRs to main
grep "pull_request" .github/workflows/doc-freshness.yml
```

### Verify Layer 3 (AI Orchestrator)

```bash
# Verify skill exists and is loadable
cat .claude/skills/doc-superpowers/SKILL.md | head -5

# Verify command exists
cat .claude/commands/doc-superpowers.md | head -5

# Test the command
/doc-superpowers audit all
```

### End-to-End Test

```bash
# 1. Touch a source file to make a doc stale
touch Sources/CameraFeature/Views/CaptureView.swift

# 2. Hash engine should detect it
uv run scripts/check_doc_freshness.py

# 3. AI orchestrator should analyze it
/doc-superpowers audit ios

# 4. After review, mark as verified
uv run scripts/check_doc_freshness.py --update docs/specs/SPEC-UI-001-camera-capture-flow.md

# 5. Should now be clean
uv run scripts/check_doc_freshness.py
```
