#!/usr/bin/env python3
"""Fix broken document references in markdown files.

Usage:
    python scripts/fix_doc_references.py              # Dry run
    python scripts/fix_doc_references.py --apply      # Apply changes
    python scripts/fix_doc_references.py --dir docs/roadmap  # Specific directory
"""

import argparse
from pathlib import Path
from typing import Dict
from map_documents import DocumentMapper, DocumentFixer

def main(docs_root: Path = Path('docs'), dry_run: bool = True, target_dir: str | None = None) -> Dict[str, int]:
    """Fix document references across all markdown files.

    Args:
        docs_root: Root documentation directory
        dry_run: If True, only report changes without applying
        target_dir: Optional specific subdirectory to process

    Returns:
        Stats dict with files_processed, files_modified, total_changes
    """
    # Build document index
    print(f"📚 Scanning {docs_root} for documents...")
    mapper = DocumentMapper(str(docs_root))
    mapper.discover_documents()
    mapper.build_prefix_index()
    print(f"✓ Found {len(mapper.documents)} documents")
    print(f"✓ Indexed {len(mapper.prefix_index)} document prefixes")

    # Determine which files to process
    if target_dir:
        target_path = docs_root / target_dir
        files_to_process = list(target_path.rglob('*.md'))
    else:
        files_to_process = mapper.documents

    print(f"\n🔍 Processing {len(files_to_process)} files...")

    # Fix references in each file
    fixer = DocumentFixer(mapper)
    stats = {
        'files_processed': 0,
        'files_modified': 0,
        'total_changes': 0
    }

    for file_path in files_to_process:
        content = file_path.read_text()
        fixed_content, changes = fixer.fix(content)

        stats['files_processed'] += 1

        if changes > 0:
            stats['files_modified'] += 1
            stats['total_changes'] += changes

            print(f"\n📝 {file_path.relative_to(docs_root)}")
            print(f"   → {changes} reference(s) fixed")

            if not dry_run:
                file_path.write_text(fixed_content)
                print(f"   ✓ Changes applied")

    # Print summary
    print(f"\n{'='*60}")
    print(f"📊 Summary:")
    print(f"   Files processed: {stats['files_processed']}")
    print(f"   Files modified: {stats['files_modified']}")
    print(f"   Total changes: {stats['total_changes']}")

    if dry_run and stats['total_changes'] > 0:
        print(f"\n⚠️  DRY RUN - No changes applied")
        print(f"   Run with --apply to apply changes")

    return stats

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Fix broken document references')
    parser.add_argument('--apply', action='store_true', help='Apply changes (default: dry run)')
    parser.add_argument('--dir', type=str, help='Specific subdirectory to process (e.g., roadmap)')

    args = parser.parse_args()

    main(
        docs_root=Path('docs'),
        dry_run=not args.apply,
        target_dir=args.dir
    )
