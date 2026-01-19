#!/usr/bin/env python3
"""
CLI tool to update the documentation index.

Usage:
    # Add a new document
    update_doc_index.py add docs/plans/my-plan.md --status Active

    # Update document status
    update_doc_index.py update docs/plans/my-plan.md --status Completed --merged 2026-01-19

    # Remove a document from tracking
    update_doc_index.py remove docs/plans/my-plan.md

    # Sync index with filesystem (add untracked, remove missing)
    update_doc_index.py sync
"""

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def load_index(project_root: Path) -> dict:
    """Load the doc index file."""
    index_path = project_root / "docs" / ".doc-index.json"
    if not index_path.exists():
        return {
            "version": "1.0",
            "generated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "directories": {
                "specs": {"path": "docs/specs/", "archive_on": ["Deprecated"], "docs": {}},
                "plans": {"path": "docs/plans/", "archive_on": ["Completed", "Abandoned"], "docs": {}},
                "issues": {"path": "docs/issues/", "archive_on": ["Closed", "Fixed", "Won't Fix"], "docs": {}},
                "dev-workflow": {"path": "docs/dev-workflow/", "archive_on": ["Deprecated"], "docs": {}},
            },
            "archived": {}
        }

    with open(index_path) as f:
        return json.load(f)


def save_index(project_root: Path, index: dict):
    """Save the doc index file."""
    index_path = project_root / "docs" / ".doc-index.json"
    index["generated"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with open(index_path, "w") as f:
        json.dump(index, f, indent=2)
        f.write("\n")


def parse_doc_path(doc_path: str) -> tuple[str, str] | None:
    """Parse doc path into (dir_name, filename).

    Returns None if path is not in a tracked directory.
    """
    doc_path = doc_path.removeprefix("docs/")
    parts = doc_path.split("/")

    if len(parts) < 2:
        return None

    dir_name = parts[0]
    filename = parts[-1]

    # Map directory names
    dir_map = {
        "specs": "specs",
        "plans": "plans",
        "issues": "issues",
        "dev-workflow": "dev-workflow",
    }

    if dir_name not in dir_map:
        return None

    return dir_map[dir_name], filename


def cmd_add(args, project_root: Path, index: dict) -> int:
    """Add a new document to the index."""
    parsed = parse_doc_path(args.path)
    if parsed is None:
        print(f"Error: Path '{args.path}' is not in a tracked directory")
        return 1

    dir_name, filename = parsed

    if dir_name not in index.get("directories", {}):
        print(f"Error: Directory '{dir_name}' not configured in index")
        return 1

    docs = index["directories"][dir_name]["docs"]

    if filename in docs:
        print(f"Error: '{filename}' already exists in index. Use 'update' instead.")
        return 1

    # Verify file exists
    dir_path = index["directories"][dir_name]["path"]
    full_path = project_root / dir_path / filename
    if not full_path.exists():
        print(f"Error: File does not exist: {full_path}")
        return 1

    # Create entry based on directory type
    if dir_name == "specs":
        docs[filename] = {
            "status": args.status or "Active",
            "code_refs": [],
            "updated": datetime.now(timezone.utc).strftime("%Y-%m-%d")
        }
    elif dir_name == "plans":
        docs[filename] = {
            "status": args.status or "Active",
            "related_branch": args.branch,
            "merged": args.merged
        }
    elif dir_name == "issues":
        docs[filename] = {
            "status": args.status or "Open",
            "related_branch": args.branch,
            "merged": args.merged
        }
    else:
        docs[filename] = {
            "status": args.status or "Active",
            "code_refs": [],
            "updated": datetime.now(timezone.utc).strftime("%Y-%m-%d")
        }

    save_index(project_root, index)
    print(f"Added: {dir_path}{filename}")
    return 0


def cmd_update(args, project_root: Path, index: dict) -> int:
    """Update an existing document in the index."""
    parsed = parse_doc_path(args.path)
    if parsed is None:
        print(f"Error: Path '{args.path}' is not in a tracked directory")
        return 1

    dir_name, filename = parsed

    if dir_name not in index.get("directories", {}):
        print(f"Error: Directory '{dir_name}' not configured in index")
        return 1

    docs = index["directories"][dir_name]["docs"]

    if filename not in docs:
        print(f"Error: '{filename}' not found in index. Use 'add' first.")
        return 1

    doc_info = docs[filename]

    # Update fields if provided
    if args.status:
        doc_info["status"] = args.status

    if args.branch is not None:
        doc_info["related_branch"] = args.branch if args.branch else None

    if args.merged is not None:
        doc_info["merged"] = args.merged if args.merged else None

    if args.superseded_by:
        doc_info["superseded_by"] = args.superseded_by

    if "updated" in doc_info:
        doc_info["updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    save_index(project_root, index)
    print(f"Updated: {index['directories'][dir_name]['path']}{filename}")
    return 0


def cmd_remove(args, project_root: Path, index: dict) -> int:
    """Remove a document from the index."""
    parsed = parse_doc_path(args.path)
    if parsed is None:
        print(f"Error: Path '{args.path}' is not in a tracked directory")
        return 1

    dir_name, filename = parsed

    if dir_name not in index.get("directories", {}):
        print(f"Error: Directory '{dir_name}' not configured in index")
        return 1

    docs = index["directories"][dir_name]["docs"]

    if filename not in docs:
        print(f"Error: '{filename}' not found in index")
        return 1

    del docs[filename]

    save_index(project_root, index)
    print(f"Removed: {index['directories'][dir_name]['path']}{filename}")
    return 0


def cmd_sync(_args, project_root: Path, index: dict) -> int:
    """Sync index with filesystem."""
    added = 0
    removed = 0

    for dir_name, dir_info in index.get("directories", {}).items():
        dir_path = project_root / dir_info.get("path", "")
        if not dir_path.exists():
            continue

        docs = dir_info["docs"]
        tracked_files = set(docs.keys())
        actual_files = {f.name for f in dir_path.glob("*.md")}

        # Add untracked files
        for filename in actual_files - tracked_files:
            if dir_name == "specs":
                docs[filename] = {
                    "status": "Active",
                    "code_refs": [],
                    "updated": datetime.now(timezone.utc).strftime("%Y-%m-%d")
                }
            elif dir_name == "plans":
                docs[filename] = {
                    "status": "Active",
                    "related_branch": None,
                    "merged": None
                }
            elif dir_name == "issues":
                docs[filename] = {
                    "status": "Open",
                    "related_branch": None,
                    "merged": None
                }
            else:
                docs[filename] = {
                    "status": "Active",
                    "code_refs": [],
                    "updated": datetime.now(timezone.utc).strftime("%Y-%m-%d")
                }
            print(f"  Added: {dir_info['path']}{filename}")
            added += 1

        # Remove missing files
        for filename in tracked_files - actual_files:
            del docs[filename]
            print(f"  Removed: {dir_info['path']}{filename}")
            removed += 1

    if added > 0 or removed > 0:
        save_index(project_root, index)
        print(f"\nSync complete: {added} added, {removed} removed")
    else:
        print("Index is already in sync with filesystem")

    return 0


def get_project_root() -> Path:
    """Get project root from git."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        return Path.cwd()


def main():
    parser = argparse.ArgumentParser(
        description="Update the documentation index"
    )
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Add command
    add_parser = subparsers.add_parser("add", help="Add a document to the index")
    add_parser.add_argument("path", help="Document path (e.g., docs/plans/my-plan.md)")
    add_parser.add_argument("--status", help="Document status")
    add_parser.add_argument("--branch", help="Related branch name")
    add_parser.add_argument("--merged", help="Merge date (YYYY-MM-DD)")

    # Update command
    update_parser = subparsers.add_parser("update", help="Update a document in the index")
    update_parser.add_argument("path", help="Document path")
    update_parser.add_argument("--status", help="New status")
    update_parser.add_argument("--branch", help="Related branch (use '' to clear)")
    update_parser.add_argument("--merged", help="Merge date (use '' to clear)")
    update_parser.add_argument("--superseded-by", dest="superseded_by", help="Superseding document")

    # Remove command
    remove_parser = subparsers.add_parser("remove", help="Remove a document from the index")
    remove_parser.add_argument("path", help="Document path")

    # Sync command
    subparsers.add_parser("sync", help="Sync index with filesystem")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    project_root = get_project_root()
    index = load_index(project_root)

    if args.command == "add":
        sys.exit(cmd_add(args, project_root, index))
    elif args.command == "update":
        sys.exit(cmd_update(args, project_root, index))
    elif args.command == "remove":
        sys.exit(cmd_remove(args, project_root, index))
    elif args.command == "sync":
        sys.exit(cmd_sync(args, project_root, index))


if __name__ == "__main__":
    main()
