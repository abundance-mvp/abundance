#!/usr/bin/env python3
"""
Documentation status drift detector.

Detects two types of drift:
1. Branch State Drift (ERROR): Doc's related_branch is merged to main,
   but doc status is still Active/Open/In Progress.
2. Frontmatter/Index Mismatch (WARNING): YAML frontmatter status in .md file
   differs from status in docs/.doc-index.json.

Exit codes:
- 0: No drift detected
- 1: Drift detected
- 2: Configuration error (missing index, not in git repo)
"""

import argparse
import json
import re
import subprocess
import sys
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
        sys.exit(2)


def load_index(project_root: Path) -> dict:
    """Load doc index."""
    index_path = project_root / "docs" / ".doc-index.json"
    if not index_path.exists():
        print("Error: docs/.doc-index.json not found", file=sys.stderr)
        sys.exit(2)
    with open(index_path) as f:
        return json.load(f)


def save_index(index: dict, project_root: Path):
    """Save doc index with updated timestamp."""
    from datetime import date
    index_path = project_root / "docs" / ".doc-index.json"
    index["generated"] = f"{date.today().isoformat()}T00:00:00Z"
    with open(index_path, "w") as f:
        json.dump(index, f, indent=2)
        f.write("\n")


def get_merged_branches() -> set[str]:
    """Get branches merged to main."""
    try:
        result = subprocess.run(
            ["git", "branch", "--merged", "main"],
            capture_output=True, text=True, check=True
        )
        branches = set()
        for line in result.stdout.strip().split("\n"):
            branch = line.strip().lstrip("* ")
            if branch and branch != "main":
                branches.add(branch)
        return branches
    except subprocess.CalledProcessError:
        return set()


def parse_frontmatter_status(file_path: Path) -> str | None:
    """Parse status from a markdown file.

    Supports two formats:
    1. YAML frontmatter: ---\\nstatus: Value\\n---
    2. Header-style: **Status:** Value
    """
    if not file_path.exists():
        return None

    try:
        content = file_path.read_text()
    except Exception:
        return None

    # Try YAML frontmatter first
    if content.startswith("---"):
        end = content.find("---", 3)
        if end != -1:
            frontmatter = content[3:end]
            match = re.search(r'^status:\s*(.+)$', frontmatter, re.MULTILINE)
            if match:
                return match.group(1).strip()

    # Try header-style: **Status:** Value
    match = re.search(r'\*\*Status:\*\*\s*(.+?)$', content, re.MULTILINE)
    if match:
        return match.group(1).strip()

    return None


# Statuses that indicate a doc is still "in progress" (not terminal)
ACTIVE_STATUSES = {"Active", "Open", "In Progress"}

# Terminal statuses by doc type
TERMINAL_STATUS_PLANS = "Completed"
TERMINAL_STATUS_ISSUES = "Fixed"


def check_branch_drift(index: dict, merged_branches: set[str]) -> list[dict]:
    """Check for branch state drift: merged branch but non-terminal status."""
    items = []

    for dir_name in ("plans", "issues"):
        dir_info = index.get("directories", {}).get(dir_name, {})
        dir_path = dir_info.get("path", f"docs/{dir_name}/")

        for filename, doc_info in dir_info.get("docs", {}).items():
            related_branch = doc_info.get("related_branch")
            status = doc_info.get("status", "")

            if related_branch and related_branch in merged_branches and status in ACTIVE_STATUSES:
                suggested = TERMINAL_STATUS_PLANS if dir_name == "plans" else TERMINAL_STATUS_ISSUES
                items.append({
                    "type": "branch_merged",
                    "severity": "ERROR",
                    "doc": f"{dir_path}{filename}",
                    "dir": dir_name,
                    "filename": filename,
                    "index_status": status,
                    "related_branch": related_branch,
                    "suggested_status": suggested,
                    "message": f"Branch '{related_branch}' is merged to main but status is '{status}'"
                })

    return items


def check_frontmatter_drift(index: dict, project_root: Path) -> list[dict]:
    """Check for frontmatter/index status mismatches."""
    items = []

    for dir_name in ("plans", "issues"):
        dir_info = index.get("directories", {}).get(dir_name, {})
        dir_path = dir_info.get("path", f"docs/{dir_name}/")

        for filename, doc_info in dir_info.get("docs", {}).items():
            index_status = doc_info.get("status", "")
            file_path = project_root / dir_path / filename
            fm_status = parse_frontmatter_status(file_path)

            if fm_status is None:
                continue  # No frontmatter status found, skip

            if fm_status != index_status:
                items.append({
                    "type": "frontmatter_mismatch",
                    "severity": "WARNING",
                    "doc": f"{dir_path}{filename}",
                    "dir": dir_name,
                    "filename": filename,
                    "index_status": index_status,
                    "frontmatter_status": fm_status,
                    "message": f"Frontmatter says '{fm_status}' but index says '{index_status}'"
                })

    return items


def fix_frontmatter_drift(items: list[dict], index: dict, project_root: Path) -> int:
    """Fix index to match frontmatter (frontmatter = source of truth)."""
    fixed = 0

    for item in items:
        if item["type"] != "frontmatter_mismatch":
            continue

        dir_name = item["dir"]
        filename = item["filename"]
        fm_status = item["frontmatter_status"]

        docs = index.get("directories", {}).get(dir_name, {}).get("docs", {})
        if filename in docs:
            docs[filename]["status"] = fm_status
            print(f"  Fixed: {item['doc']} — index updated to '{fm_status}'")
            fixed += 1

    if fixed > 0:
        save_index(index, project_root)

    return fixed


def format_text(branch_items: list[dict], fm_items: list[dict]) -> str:
    """Format drift report as plain text."""
    if not branch_items and not fm_items:
        return "No documentation status drift detected."

    lines = []

    if branch_items:
        lines.append(f"ERRORS: {len(branch_items)} branch state drift(s)\n")
        for item in branch_items:
            lines.append(f"  {item['doc']}")
            lines.append(f"    Status: {item['index_status']} — Branch '{item['related_branch']}' is merged")
            lines.append(f"    Suggested: Update status to '{item['suggested_status']}'")
            lines.append("")

    if fm_items:
        lines.append(f"WARNINGS: {len(fm_items)} frontmatter/index mismatch(es)\n")
        for item in fm_items:
            lines.append(f"  {item['doc']}")
            lines.append(f"    Frontmatter: {item['frontmatter_status']}")
            lines.append(f"    Index:       {item['index_status']}")
            lines.append("")

    if fm_items:
        lines.append("To auto-fix index from frontmatter:")
        lines.append("  uv run scripts/check_doc_status_drift.py --fix")

    if branch_items:
        lines.append("")
        lines.append("To fix branch drift, update doc status and index:")
        lines.append("  uv run scripts/update_doc_index.py update <path> --status <status>")

    return "\n".join(lines)


def format_json(branch_items: list[dict], fm_items: list[dict]) -> str:
    """Format drift report as JSON."""
    return json.dumps({
        "branch_drift": branch_items,
        "frontmatter_mismatch": fm_items,
        "total_errors": len(branch_items),
        "total_warnings": len(fm_items),
    }, indent=2)


def format_github_comment(branch_items: list[dict], fm_items: list[dict]) -> str:
    """Format drift report as GitHub PR comment markdown."""
    if not branch_items and not fm_items:
        return ""

    lines = [
        "## Documentation Status Drift",
        "",
    ]

    if branch_items:
        lines.append(f"### Errors: {len(branch_items)} merged branch(es) with stale status")
        lines.append("")
        lines.append("| Document | Current Status | Branch | Suggested |")
        lines.append("|----------|---------------|--------|-----------|")
        for item in branch_items:
            lines.append(
                f"| `{item['doc']}` | {item['index_status']} | "
                f"`{item['related_branch']}` (merged) | {item['suggested_status']} |"
            )
        lines.append("")

    if fm_items:
        lines.append(f"### Warnings: {len(fm_items)} frontmatter/index mismatch(es)")
        lines.append("")
        lines.append("| Document | Frontmatter | Index |")
        lines.append("|----------|-------------|-------|")
        for item in fm_items:
            lines.append(
                f"| `{item['doc']}` | {item['frontmatter_status']} | {item['index_status']} |"
            )
        lines.append("")

    lines.append("*Run `uv run scripts/check_doc_status_drift.py --fix` to sync index from frontmatter.*")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Check documentation status drift")
    parser.add_argument("--format", choices=["text", "json", "github-comment"],
                        default="text", help="Output format")
    parser.add_argument("--fix", action="store_true",
                        help="Auto-fix index from frontmatter (frontmatter = source of truth)")
    parser.add_argument("--quiet", "-q", action="store_true",
                        help="Exit code only, no output")
    parser.add_argument("--project-root", type=Path, default=None)

    args = parser.parse_args()
    project_root = args.project_root or get_project_root()
    index = load_index(project_root)

    merged_branches = get_merged_branches()
    branch_items = check_branch_drift(index, merged_branches)
    fm_items = check_frontmatter_drift(index, project_root)

    if args.fix:
        fixed = fix_frontmatter_drift(fm_items, index, project_root)
        # Re-check after fix
        index = load_index(project_root)
        fm_items = check_frontmatter_drift(index, project_root)
        if not args.quiet:
            print(f"Fixed {fixed} frontmatter/index mismatch(es)")
            if branch_items:
                print(f"\n{len(branch_items)} branch drift error(s) remain (requires manual status update)")
        has_drift = bool(branch_items) or bool(fm_items)
        sys.exit(1 if has_drift else 0)

    if not args.quiet:
        if args.format == "json":
            output = format_json(branch_items, fm_items)
        elif args.format == "github-comment":
            output = format_github_comment(branch_items, fm_items)
        else:
            output = format_text(branch_items, fm_items)

        if output:
            print(output)

    has_drift = bool(branch_items) or bool(fm_items)
    sys.exit(1 if has_drift else 0)


if __name__ == "__main__":
    main()
