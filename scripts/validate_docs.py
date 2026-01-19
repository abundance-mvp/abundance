#!/usr/bin/env python3
"""
Documentation validation script for the abundance-mvp project.

Validates:
1. All files in index exist on disk
2. All files in scoped directories are tracked in index
3. All markdown links resolve
4. Plans with status=Active don't have merged branches
5. Specs with code_refs have existing paths
6. Docs with archival-ready status require archiving

Exit codes:
- 0: All checks pass
- 1: Validation failures
- 2: Archive required (docs need archiving)
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import NamedTuple


class ValidationError(NamedTuple):
    """A validation error."""
    category: str
    path: str
    message: str


class ValidationResult:
    """Collects validation errors and warnings."""

    def __init__(self):
        self.errors: list[ValidationError] = []
        self.warnings: list[ValidationError] = []
        self.archive_required: list[str] = []

    def add_error(self, category: str, path: str, message: str):
        self.errors.append(ValidationError(category, path, message))

    def add_warning(self, category: str, path: str, message: str):
        self.warnings.append(ValidationError(category, path, message))

    def add_archive_required(self, path: str):
        self.archive_required.append(path)

    def has_failures(self) -> bool:
        return len(self.errors) > 0

    def has_archive_required(self) -> bool:
        return len(self.archive_required) > 0


def load_index(project_root: Path) -> dict | None:
    """Load the doc index file."""
    index_path = project_root / "docs" / ".doc-index.json"
    if not index_path.exists():
        return None

    with open(index_path) as f:
        return json.load(f)


def get_merged_branches() -> set[str]:
    """Get list of branches merged to main."""
    try:
        result = subprocess.run(
            ["git", "branch", "--merged", "main"],
            capture_output=True,
            text=True,
            check=True
        )
        branches = set()
        for line in result.stdout.strip().split("\n"):
            branch = line.strip().lstrip("* ")
            if branch and branch != "main":
                branches.add(branch)
        return branches
    except subprocess.CalledProcessError:
        return set()


def validate_files_exist(index: dict, project_root: Path, result: ValidationResult):
    """Check that all files in the index exist on disk."""
    for dir_info in index.get("directories", {}).values():
        dir_path = dir_info.get("path", "")
        for filename in dir_info.get("docs", {}).keys():
            full_path = project_root / dir_path / filename
            if not full_path.exists():
                result.add_error(
                    "missing_file",
                    f"{dir_path}{filename}",
                    "File in index does not exist on disk"
                )


def validate_files_tracked(index: dict, project_root: Path, result: ValidationResult):
    """Check that all files in scoped directories are tracked in index."""
    for dir_info in index.get("directories", {}).values():
        dir_path = project_root / dir_info.get("path", "")
        if not dir_path.exists():
            continue

        tracked_files = set(dir_info.get("docs", {}).keys())

        for file_path in dir_path.glob("*.md"):
            filename = file_path.name
            if filename not in tracked_files:
                result.add_warning(
                    "untracked_file",
                    str(file_path.relative_to(project_root)),
                    "File not tracked in .doc-index.json"
                )


def validate_markdown_links(index: dict, project_root: Path, result: ValidationResult):
    """Check that all markdown links resolve."""
    link_pattern = re.compile(r'\[[^\]]+\]\(([^)]+)\)')

    for dir_info in index.get("directories", {}).values():
        dir_path = project_root / dir_info.get("path", "")

        for filename in dir_info.get("docs", {}).keys():
            file_path = dir_path / filename
            if not file_path.exists():
                continue

            try:
                content = file_path.read_text()
            except Exception:
                continue

            for match in link_pattern.finditer(content):
                link_target = match.group(1)

                # Skip external links, anchors, and special protocols
                if link_target.startswith(('http://', 'https://', '#', 'mailto:')):
                    continue

                # Handle anchor links in same file
                if link_target.startswith('#'):
                    continue

                # Remove anchor from link
                link_path = link_target.split('#')[0]
                if not link_path:
                    continue

                # Resolve relative path
                if link_path.startswith('/'):
                    target_path = project_root / link_path.lstrip('/')
                else:
                    target_path = file_path.parent / link_path

                target_path = target_path.resolve()

                if not target_path.exists():
                    result.add_error(
                        "broken_link",
                        str(file_path.relative_to(project_root)),
                        f"Broken link to '{link_target}'"
                    )


def validate_plan_status(index: dict, result: ValidationResult):
    """Check that active plans don't have merged branches."""
    merged_branches = get_merged_branches()

    plans = index.get("directories", {}).get("plans", {}).get("docs", {})

    for filename, doc_info in plans.items():
        status = doc_info.get("status", "")
        related_branch = doc_info.get("related_branch")

        if status == "Active" and related_branch and related_branch in merged_branches:
            result.add_warning(
                "status_drift",
                f"docs/plans/{filename}",
                f"Plan is Active but branch '{related_branch}' is merged"
            )


def validate_code_refs(index: dict, project_root: Path, result: ValidationResult):
    """Check that code_refs in specs point to existing paths."""
    specs = index.get("directories", {}).get("specs", {}).get("docs", {})

    for filename, doc_info in specs.items():
        code_refs = doc_info.get("code_refs", [])

        for ref in code_refs:
            ref_path = project_root / ref
            if not ref_path.exists():
                result.add_warning(
                    "code_drift",
                    f"docs/specs/{filename}",
                    f"Code reference '{ref}' does not exist"
                )


def validate_archival(index: dict, result: ValidationResult):
    """Check that docs with archival-ready status are flagged for archiving."""
    for dir_info in index.get("directories", {}).values():
        archive_on = set(dir_info.get("archive_on", []))
        dir_path = dir_info.get("path", "")

        for filename, doc_info in dir_info.get("docs", {}).items():
            status = doc_info.get("status", "")

            if status in archive_on:
                result.add_archive_required(f"{dir_path}{filename}")


def print_results(result: ValidationResult, verbose: bool = False):
    """Print validation results."""
    if result.errors:
        print("\n❌ ERRORS:")
        for err in result.errors:
            print(f"  [{err.category}] {err.path}: {err.message}")

    if result.warnings and verbose:
        print("\n⚠️  WARNINGS:")
        for warn in result.warnings:
            print(f"  [{warn.category}] {warn.path}: {warn.message}")

    if result.archive_required:
        print("\n📦 ARCHIVE REQUIRED:")
        for path in result.archive_required:
            print(f"  {path}")
        print("\nRun: ./scripts/archive_doc.py --all")

    if not result.errors and not result.archive_required:
        print("✅ All documentation checks passed")
        if result.warnings:
            print(f"   ({len(result.warnings)} warnings)")


def main():
    parser = argparse.ArgumentParser(
        description="Validate documentation health"
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Quick mode: only check links (for pre-commit)"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show warnings in addition to errors"
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=None,
        help="Project root directory (defaults to git root)"
    )

    args = parser.parse_args()

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

    # Load index
    index = load_index(project_root)
    if index is None:
        print("Error: docs/.doc-index.json not found")
        sys.exit(1)

    result = ValidationResult()

    # Run validations
    validate_files_exist(index, project_root, result)
    validate_files_tracked(index, project_root, result)
    validate_markdown_links(index, project_root, result)

    if not args.quick:
        validate_plan_status(index, result)
        validate_code_refs(index, project_root, result)
        validate_archival(index, result)

    print_results(result, args.verbose)

    # Determine exit code
    if result.has_failures():
        sys.exit(1)
    elif result.has_archive_required():
        sys.exit(2)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
