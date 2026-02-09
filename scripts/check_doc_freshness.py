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
            continue  # No baseline yet -- skip (use --init)

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
