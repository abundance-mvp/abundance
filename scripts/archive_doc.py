#!/usr/bin/env python3
"""
Archive documentation that has reached terminal status.

Archives docs from:
- docs/specs/ -> docs/archive/specs/
- docs/plans/ -> docs/archive/plans/
- docs/issues/ -> docs/archive/issues/
- docs/dev-workflow/ -> docs/archive/dev-workflow/

Updates:
- docs/.doc-index.json (removes from active, adds to archived)
"""

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def load_index(project_root: Path) -> dict | None:
    """Load the doc index file."""
    index_path = project_root / "docs" / ".doc-index.json"
    if not index_path.exists():
        return None

    with open(index_path) as f:
        return json.load(f)


def save_index(project_root: Path, index: dict):
    """Save the doc index file."""
    index_path = project_root / "docs" / ".doc-index.json"
    index["generated"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    with open(index_path, "w") as f:
        json.dump(index, f, indent=2)
        f.write("\n")


def get_archive_ready_docs(index: dict) -> list[tuple[str, str, str]]:
    """Get list of docs that are ready for archiving.

    Returns list of (dir_name, filename, dir_path) tuples.
    """
    ready = []

    for dir_name, dir_info in index.get("directories", {}).items():
        archive_on = set(dir_info.get("archive_on", []))
        dir_path = dir_info.get("path", "")

        for filename, doc_info in dir_info.get("docs", {}).items():
            status = doc_info.get("status", "")

            if status in archive_on:
                ready.append((dir_name, filename, dir_path))

    return ready


def archive_doc(
    project_root: Path,
    index: dict,
    dir_name: str,
    filename: str,
    dir_path: str,
    dry_run: bool = False
) -> bool:
    """Archive a single document.

    Returns True if successful, False otherwise.
    """
    source_path = project_root / dir_path / filename
    archive_dir = project_root / "docs" / "archive" / dir_name
    dest_path = archive_dir / filename

    if not source_path.exists():
        print(f"  Error: Source file does not exist: {source_path}")
        return False

    if dest_path.exists():
        print(f"  Error: Destination already exists: {dest_path}")
        return False

    if dry_run:
        print(f"  Would archive: {dir_path}{filename}")
        return True

    # Create archive directory if needed
    archive_dir.mkdir(parents=True, exist_ok=True)

    # Move file
    shutil.move(str(source_path), str(dest_path))

    # Update index
    doc_info = index["directories"][dir_name]["docs"].pop(filename)
    doc_info["archived_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    if "archived" not in index:
        index["archived"] = {}

    if dir_name not in index["archived"]:
        index["archived"][dir_name] = {}

    index["archived"][dir_name][filename] = doc_info

    print(f"  Archived: {dir_path}{filename}")
    return True


def archive_single(project_root: Path, doc_path: str, dry_run: bool = False) -> int:
    """Archive a single document by path."""
    index = load_index(project_root)
    if index is None:
        print("Error: docs/.doc-index.json not found")
        return 1

    # Parse the path to find directory and filename
    doc_path = doc_path.removeprefix("docs/")
    parts = doc_path.split("/")

    if len(parts) < 2:
        print(f"Error: Invalid path format: {doc_path}")
        return 1

    dir_name = parts[0]
    filename = parts[-1]

    # Find the directory info
    if dir_name not in index.get("directories", {}):
        print(f"Error: Directory '{dir_name}' not tracked in index")
        return 1

    dir_info = index["directories"][dir_name]
    dir_path = dir_info.get("path", "")

    if filename not in dir_info.get("docs", {}):
        print(f"Error: File '{filename}' not tracked in index")
        return 1

    doc_info = dir_info["docs"][filename]
    status = doc_info.get("status", "")
    archive_on = set(dir_info.get("archive_on", []))

    if status not in archive_on:
        print(f"Error: Document status '{status}' is not archival-ready")
        print(f"  Archive triggers: {', '.join(archive_on)}")
        return 1

    success = archive_doc(project_root, index, dir_name, filename, dir_path, dry_run)

    if success and not dry_run:
        save_index(project_root, index)
        print("\nIndex updated.")

    return 0 if success else 1


def archive_all(project_root: Path, dry_run: bool = False) -> int:
    """Archive all documents that are ready."""
    index = load_index(project_root)
    if index is None:
        print("Error: docs/.doc-index.json not found")
        return 1

    ready = get_archive_ready_docs(index)

    if not ready:
        print("No documents ready for archiving.")
        return 0

    print(f"Found {len(ready)} documents ready for archiving:")

    success_count = 0
    for dir_name, filename, dir_path in ready:
        if archive_doc(project_root, index, dir_name, filename, dir_path, dry_run):
            success_count += 1

    if not dry_run and success_count > 0:
        save_index(project_root, index)
        print(f"\n{success_count} documents archived. Index updated.")

    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Archive documentation that has reached terminal status"
    )
    parser.add_argument(
        "path",
        nargs="?",
        help="Specific document path to archive (e.g., docs/plans/my-plan.md)"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Archive all documents that are ready"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be archived without making changes"
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=None,
        help="Project root directory (defaults to git root)"
    )

    args = parser.parse_args()

    # Validate arguments
    if not args.all and not args.path:
        parser.print_help()
        print("\nError: Specify a path or use --all")
        sys.exit(1)

    if args.all and args.path:
        print("Error: Cannot use both --all and a specific path")
        sys.exit(1)

    # Determine project root
    if args.project_root:
        project_root = args.project_root.resolve()
    else:
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=True
            )
            project_root = Path(result.stdout.strip())
        except subprocess.CalledProcessError:
            print("Error: Not in a git repository and --project-root not specified")
            sys.exit(1)

    if args.all:
        sys.exit(archive_all(project_root, args.dry_run))
    else:
        sys.exit(archive_single(project_root, args.path, args.dry_run))


if __name__ == "__main__":
    main()
