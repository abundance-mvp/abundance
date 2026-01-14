#!/usr/bin/env python3
"""Validate document references in markdown files.

Usage:
    python scripts/validate_doc_references.py
"""

import re
from pathlib import Path
from typing import List, Dict

def validate_references(docs_root: Path) -> List[Dict[str, str]]:
    """Validate all document references are not broken.

    Args:
        docs_root: Root documentation directory

    Returns:
        List of issues found (empty if all valid)
    """
    issues = []

    # Pattern to match markdown links
    link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

    # Find all markdown files (excluding plans/ which may reference future files)
    for md_file in docs_root.rglob('*.md'):
        # Skip plans directory - contains future-looking documents
        if 'plans' in md_file.parts:
            continue
        content = md_file.read_text()

        # Extract all links
        for match in link_pattern.finditer(content):
            link_text = match.group(1)
            link_path = match.group(2)

            # Skip external links
            if link_path.startswith('http'):
                continue

            # Skip anchor links (internal page references)
            if link_path.startswith('#'):
                continue

            # Skip placeholder links (example code/documentation)
            if 'XXX' in link_path or '...' in link_path:
                continue

            # Skip code syntax (e.g., Swift parameter labels)
            if ':' in link_path and not link_path.startswith('http'):
                continue

            # Skip template variables
            if '{' in link_path or '}' in link_path:
                continue

            # Skip placeholder paths (00X, wildcard patterns, "nonexistent", etc.)
            if ('00X' in link_path or
                'nonexistent' in link_path.lower() or
                'MISSING' in link_path or
                link_path == 'path' or
                link_path.endswith('.*')):
                continue

            # Resolve relative path (all paths are relative to current file)
            full_path = (md_file.parent / link_path).resolve()

            # Check if target exists
            if not full_path.exists():
                issues.append({
                    'file': str(md_file.relative_to(docs_root.parent)),
                    'link_text': link_text,
                    'link_path': link_path,
                    'message': f"Broken link: {link_path} does not exist"
                })

    return issues

def main():
    """Run validation and report issues."""
    docs_root = Path('docs')

    print(f"🔍 Validating document references in {docs_root}...")

    issues = validate_references(docs_root)

    if not issues:
        print("✓ All document references are valid!")
        return 0

    print(f"\n❌ Found {len(issues)} broken reference(s):\n")

    for issue in issues:
        print(f"  {issue['file']}")
        print(f"    → {issue['message']}")

    return 1

if __name__ == '__main__':
    exit(main())
