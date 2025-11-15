# Document Reference Link Audit & Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Audit all document references in docs/ and convert broken reference IDs to proper markdown links with full paths.

**Architecture:** Python script scans all markdown files, extracts reference patterns, maps them to actual files using prefix matching, and generates replacement edits.

**Tech Stack:** Python 3.x, regex, pathlib, file I/O

---

## Problem Statement

Documents in `docs/` contain references like:
```markdown
**References:**
- CODE-EXAMPLE-011: Layer 2a Cloud Function
- DESIGN-042: Layer 2a Error Handling
```

These should be converted to proper markdown links:
```markdown
**References:**
- [CODE-EXAMPLE-011-layer-2a-cloud-function](docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Layer 2a Cloud Function
- [DESIGN-042-layer-2a-error-handling](docs/design/DESIGN-042-layer-2a-error-handling.md): Layer 2a Error Handling
```

**Pattern:** Document IDs share a prefix with actual filenames (e.g., `CODE-EXAMPLE-011` → `CODE-EXAMPLE-011-layer-2a-cloud-function.md`)

---

## Task 1: Create Document Mapper Script

**Files:**
- Create: `scripts/map_documents.py`

**Step 1: Write the test for document discovery**

```python
# scripts/test_map_documents.py
import pytest
from pathlib import Path
from map_documents import DocumentMapper

def test_discovers_all_markdown_files():
    mapper = DocumentMapper('docs')
    files = mapper.discover_documents()

    # Should find files in design/, roadmap/, adr/, etc.
    assert len(files) > 0
    assert all(f.suffix == '.md' for f in files)
    assert any('SPRINT-PLAN' in f.name for f in files)

def test_builds_prefix_index():
    mapper = DocumentMapper('docs')
    mapper.discover_documents()
    index = mapper.build_prefix_index()

    # Should map CODE-EXAMPLE-011 → full path
    assert 'CODE-EXAMPLE-011' in index
    assert 'DESIGN-042' in index
    assert str(index['CODE-EXAMPLE-011']).endswith('.md')
```

**Step 2: Run test to verify it fails**

```bash
cd /Users/w/code/spec-kit
python -m pytest scripts/test_map_documents.py -v
```

Expected: FAIL with "ModuleNotFoundError: No module named 'map_documents'"

**Step 3: Write minimal implementation**

```python
# scripts/map_documents.py
from pathlib import Path
from typing import Dict, List
import re

class DocumentMapper:
    """Maps document ID prefixes to actual file paths."""

    def __init__(self, docs_root: str):
        self.docs_root = Path(docs_root)
        self.documents: List[Path] = []
        self.prefix_index: Dict[str, Path] = {}

    def discover_documents(self) -> List[Path]:
        """Find all markdown files in docs/ directory."""
        self.documents = list(self.docs_root.rglob('*.md'))
        return self.documents

    def build_prefix_index(self) -> Dict[str, Path]:
        """Build index mapping doc ID prefixes to file paths.

        Example:
            CODE-EXAMPLE-011-layer-2a.md → CODE-EXAMPLE-011
            DESIGN-042-error-handling.md → DESIGN-042
        """
        pattern = re.compile(r'^([A-Z-]+-\d+)')

        for doc in self.documents:
            match = pattern.match(doc.stem)
            if match:
                prefix = match.group(1)
                self.prefix_index[prefix] = doc

        return self.prefix_index

    def resolve_reference(self, doc_id: str) -> Path | None:
        """Resolve a document ID to its full path.

        Args:
            doc_id: Document ID like "CODE-EXAMPLE-011"

        Returns:
            Path to actual file, or None if not found
        """
        return self.prefix_index.get(doc_id)
```

**Step 4: Run test to verify it passes**

```bash
python -m pytest scripts/test_map_documents.py -v
```

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/map_documents.py scripts/test_map_documents.py
git commit -m "feat: add document prefix mapper with discovery and indexing"
```

---

## Task 2: Create Reference Extractor

**Files:**
- Modify: `scripts/map_documents.py`
- Modify: `scripts/test_map_documents.py`

**Step 1: Write the test for reference extraction**

```python
# Add to scripts/test_map_documents.py
def test_extracts_references_from_markdown():
    content = """
**References:**
- CODE-EXAMPLE-011: Layer 2a Cloud Function
- DESIGN-042: Layer 2a Error Handling
- [ADR-005-authentication-strategy](docs/adr/ADR-005-authentication-strategy.md): Authentication Strategy
"""

    extractor = ReferenceExtractor()
    refs = extractor.extract(content)

    assert len(refs) == 3
    assert refs[0] == {
        'doc_id': 'CODE-EXAMPLE-011',
        'description': 'Layer 2a Cloud Function',
        'line_text': '- CODE-EXAMPLE-011: Layer 2a Cloud Function'
    }

def test_handles_already_linked_references():
    content = """
**References:**
- [CODE-EXAMPLE-011](docs/design/CODE-EXAMPLE-011.md): Already linked
- DESIGN-042: Not linked yet
"""

    extractor = ReferenceExtractor()
    refs = extractor.extract(content)

    # Should only extract unlinked references
    assert len(refs) == 1
    assert refs[0]['doc_id'] == 'DESIGN-042'
```

**Step 2: Run test to verify it fails**

```bash
python -m pytest scripts/test_map_documents.py::test_extracts_references_from_markdown -v
```

Expected: FAIL with "NameError: name 'ReferenceExtractor' is not defined"

**Step 3: Write minimal implementation**

```python
# Add to scripts/map_documents.py
import re
from typing import List, Dict, TypedDict

class Reference(TypedDict):
    doc_id: str
    description: str
    line_text: str

class ReferenceExtractor:
    """Extract document references from markdown content."""

    # Match: "- CODE-EXAMPLE-011: Description"
    # But NOT: "- [CODE-EXAMPLE-011](...): Description"
    UNLINKED_PATTERN = re.compile(
        r'^- ([A-Z-]+-\d+): (.+)$',
        re.MULTILINE
    )

    LINKED_PATTERN = re.compile(
        r'^\- \[([A-Z-]+-\d+)',
        re.MULTILINE
    )

    def extract(self, content: str) -> List[Reference]:
        """Extract unlinked references from markdown content.

        Args:
            content: Markdown file content

        Returns:
            List of references with doc_id, description, line_text
        """
        # Find all linked references (to skip)
        linked_ids = set(self.LINKED_PATTERN.findall(content))

        # Find all unlinked references
        references = []
        for match in self.UNLINKED_PATTERN.finditer(content):
            doc_id = match.group(1)

            # Skip if already linked
            if doc_id in linked_ids:
                continue

            references.append({
                'doc_id': doc_id,
                'description': match.group(2),
                'line_text': match.group(0)
            })

        return references
```

**Step 4: Run test to verify it passes**

```bash
python -m pytest scripts/test_map_documents.py -v
```

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/map_documents.py scripts/test_map_documents.py
git commit -m "feat: add reference extractor with pattern matching"
```

---

## Task 3: Create Link Generator

**Files:**
- Modify: `scripts/map_documents.py`
- Modify: `scripts/test_map_documents.py`

**Step 1: Write the test for link generation**

```python
# Add to scripts/test_map_documents.py
def test_generates_markdown_link():
    generator = LinkGenerator(docs_root='docs')

    reference = {
        'doc_id': 'CODE-EXAMPLE-011',
        'description': 'Layer 2a Cloud Function',
        'line_text': '- CODE-EXAMPLE-011: Layer 2a Cloud Function'
    }

    resolved_path = Path('docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md')

    new_link = generator.generate(reference, resolved_path)

    expected = '- [CODE-EXAMPLE-011-layer-2a-cloud-function](docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Layer 2a Cloud Function'
    assert new_link == expected

def test_handles_missing_documents():
    generator = LinkGenerator(docs_root='docs')

    reference = {
        'doc_id': 'MISSING-DOC-999',
        'description': 'Does not exist',
        'line_text': '- MISSING-DOC-999: Does not exist'
    }

    new_link = generator.generate(reference, None)

    # Should return original line unchanged
    assert new_link == '- MISSING-DOC-999: Does not exist'
```

**Step 2: Run test to verify it fails**

```bash
python -m pytest scripts/test_map_documents.py::test_generates_markdown_link -v
```

Expected: FAIL with "NameError: name 'LinkGenerator' is not defined"

**Step 3: Write minimal implementation**

```python
# Add to scripts/map_documents.py
class LinkGenerator:
    """Generate markdown links for document references."""

    def __init__(self, docs_root: str):
        self.docs_root = Path(docs_root)

    def generate(self, reference: Reference, resolved_path: Path | None) -> str:
        """Generate markdown link from reference and resolved path.

        Args:
            reference: Reference dict with doc_id, description, line_text
            resolved_path: Actual file path, or None if not found

        Returns:
            Markdown link string, or original line if not resolved
        """
        if resolved_path is None:
            return reference['line_text']

        # Extract link text from filename stem
        link_text = resolved_path.stem

        # Build relative path from docs root
        relative_path = resolved_path

        # Generate markdown link
        return f"- [{link_text}]({relative_path}): {reference['description']}"
```

**Step 4: Run test to verify it passes**

```bash
python -m pytest scripts/test_map_documents.py -v
```

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/map_documents.py scripts/test_map_documents.py
git commit -m "feat: add link generator for markdown references"
```

---

## Task 4: Create Document Fixer

**Files:**
- Modify: `scripts/map_documents.py`
- Modify: `scripts/test_map_documents.py`

**Step 1: Write the test for document fixing**

```python
# Add to scripts/test_map_documents.py
def test_fixes_references_in_document():
    content = """# Sprint Plan

**References:**
- CODE-EXAMPLE-011: Layer 2a Cloud Function
- DESIGN-042: Layer 2a Error Handling

Some other content.
"""

    mapper = DocumentMapper('docs')
    mapper.prefix_index = {
        'CODE-EXAMPLE-011': Path('docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md'),
        'DESIGN-042': Path('docs/design/DESIGN-042-layer-2a-error-handling.md')
    }

    fixer = DocumentFixer(mapper)
    fixed_content, changes = fixer.fix(content)

    assert changes == 2
    assert '[CODE-EXAMPLE-011-layer-2a-cloud-function]' in fixed_content
    assert '[DESIGN-042-layer-2a-error-handling]' in fixed_content
    assert '- CODE-EXAMPLE-011: Layer 2a' not in fixed_content
```

**Step 2: Run test to verify it fails**

```bash
python -m pytest scripts/test_map_documents.py::test_fixes_references_in_document -v
```

Expected: FAIL with "NameError: name 'DocumentFixer' is not defined"

**Step 3: Write minimal implementation**

```python
# Add to scripts/map_documents.py
class DocumentFixer:
    """Fix unlinked references in markdown documents."""

    def __init__(self, mapper: DocumentMapper):
        self.mapper = mapper
        self.extractor = ReferenceExtractor()
        self.generator = LinkGenerator('docs')

    def fix(self, content: str) -> tuple[str, int]:
        """Fix all unlinked references in content.

        Args:
            content: Markdown file content

        Returns:
            Tuple of (fixed_content, num_changes)
        """
        references = self.extractor.extract(content)

        if not references:
            return content, 0

        fixed_content = content
        changes = 0

        for ref in references:
            resolved_path = self.mapper.resolve_reference(ref['doc_id'])
            new_link = self.generator.generate(ref, resolved_path)

            if new_link != ref['line_text']:
                fixed_content = fixed_content.replace(
                    ref['line_text'],
                    new_link
                )
                changes += 1

        return fixed_content, changes
```

**Step 4: Run test to verify it passes**

```bash
python -m pytest scripts/test_map_documents.py -v
```

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/map_documents.py scripts/test_map_documents.py
git commit -m "feat: add document fixer with content replacement"
```

---

## Task 5: Create CLI Script

**Files:**
- Create: `scripts/fix_doc_references.py`

**Step 1: Write integration test**

```python
# scripts/test_fix_doc_references.py
import pytest
from pathlib import Path
from fix_doc_references import main
import tempfile
import shutil

def test_fixes_sprint_plans(tmp_path):
    # Create test docs structure
    design_dir = tmp_path / 'docs' / 'design'
    roadmap_dir = tmp_path / 'docs' / 'roadmap'
    design_dir.mkdir(parents=True)
    roadmap_dir.mkdir(parents=True)

    # Create design docs
    (design_dir / 'CODE-EXAMPLE-011-layer-2a-cloud-function.md').write_text('# Example')
    (design_dir / 'DESIGN-042-layer-2a-error-handling.md').write_text('# Design')

    # Create sprint plan with broken references
    sprint_content = """# Sprint Plan

**References:**
- CODE-EXAMPLE-011: Layer 2a Cloud Function
- DESIGN-042: Layer 2a Error Handling
"""
    (roadmap_dir / 'SPRINT-PLAN-004.md').write_text(sprint_content)

    # Run fixer
    stats = main(docs_root=tmp_path / 'docs', dry_run=False)

    # Verify fixes
    fixed_content = (roadmap_dir / 'SPRINT-PLAN-004.md').read_text()
    assert '[CODE-EXAMPLE-011-layer-2a-cloud-function]' in fixed_content
    assert stats['files_modified'] == 1
    assert stats['total_changes'] == 2
```

**Step 2: Run test to verify it fails**

```bash
python -m pytest scripts/test_fix_doc_references.py -v
```

Expected: FAIL with "ModuleNotFoundError: No module named 'fix_doc_references'"

**Step 3: Write minimal implementation**

```python
# scripts/fix_doc_references.py
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
```

**Step 4: Run test to verify it passes**

```bash
python -m pytest scripts/test_fix_doc_references.py -v
```

Expected: PASS

**Step 5: Make script executable and commit**

```bash
chmod +x scripts/fix_doc_references.py
git add scripts/fix_doc_references.py scripts/test_fix_doc_references.py
git commit -m "feat: add CLI script for fixing document references"
```

---

## Task 6: Run Dry Run on Sprint Plans

**Files:**
- None (read-only operation)

**Step 1: Run dry run on roadmap directory**

```bash
python scripts/fix_doc_references.py --dir roadmap
```

Expected output:
```
📚 Scanning docs for documents...
✓ Found 150+ documents
✓ Indexed 100+ document prefixes

🔍 Processing 14 files...

📝 roadmap/SPRINT-PLAN-001.md
   → 3 reference(s) fixed

📝 roadmap/SPRINT-PLAN-002.md
   → 4 reference(s) fixed

...

📊 Summary:
   Files processed: 14
   Files modified: 10
   Total changes: 35

⚠️  DRY RUN - No changes applied
   Run with --apply to apply changes
```

**Step 2: Review output for correctness**

Manually check a few reported changes to ensure they look correct.

**Step 3: No commit (dry run only)**

---

## Task 7: Apply Fixes to Sprint Plans

**Files:**
- Modify: All `docs/roadmap/SPRINT-PLAN-*.md` files

**Step 1: Apply fixes to roadmap directory**

```bash
python scripts/fix_doc_references.py --dir roadmap --apply
```

Expected: Same output as dry run, but with "✓ Changes applied" messages

**Step 2: Verify changes with git diff**

```bash
git diff docs/roadmap/SPRINT-PLAN-001.md
git diff docs/roadmap/SPRINT-PLAN-004.md
```

Expected: See reference lines converted from:
```diff
-- CODE-EXAMPLE-011: Layer 2a Cloud Function
+- [CODE-EXAMPLE-011-layer-2a-cloud-function](docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Layer 2a Cloud Function
```

**Step 3: Run tests to ensure no breakage**

```bash
python -m pytest scripts/ -v
```

Expected: All tests PASS

**Step 4: Commit sprint plan fixes**

```bash
git add docs/roadmap/SPRINT-PLAN-*.md
git commit -m "fix: convert broken references to markdown links in sprint plans"
```

---

## Task 8: Apply Fixes to Design Documents

**Files:**
- Modify: All `docs/design/*.md` files with broken references

**Step 1: Run dry run on design directory**

```bash
python scripts/fix_doc_references.py --dir design
```

**Step 2: Review output**

Check if any design docs reference other design docs.

**Step 3: Apply fixes if needed**

```bash
python scripts/fix_doc_references.py --dir design --apply
```

**Step 4: Commit design doc fixes**

```bash
git add docs/design/*.md
git commit -m "fix: convert broken references to markdown links in design docs"
```

---

## Task 9: Apply Fixes to All Remaining Documents

**Files:**
- Modify: All `docs/**/*.md` files with broken references

**Step 1: Run dry run on entire docs directory**

```bash
python scripts/fix_doc_references.py
```

**Step 2: Review output for any unexpected directories**

Check ADRs, specs, test plans, etc.

**Step 3: Apply fixes to all documents**

```bash
python scripts/fix_doc_references.py --apply
```

**Step 4: Verify with git status**

```bash
git status
git diff --stat
```

**Step 5: Review a sample of changes**

```bash
git diff docs/adr/ADR-005-authentication-strategy.md
git diff docs/specs/PRD-001-mvp-feature-spec.md
```

**Step 6: Commit all fixes**

```bash
git add docs/
git commit -m "fix: convert broken references to markdown links across all docs"
```

---

## Task 10: Add Validation Script

**Files:**
- Create: `scripts/validate_doc_references.py`

**Step 1: Write test for validation**

```python
# scripts/test_validate_doc_references.py
import pytest
from pathlib import Path
from validate_doc_references import validate_references

def test_detects_broken_links(tmp_path):
    docs_dir = tmp_path / 'docs'
    design_dir = docs_dir / 'design'
    design_dir.mkdir(parents=True)

    # Create doc with broken link
    content = """
**References:**
- [MISSING-DOC](docs/design/MISSING-DOC.md): Does not exist
"""
    (design_dir / 'test.md').write_text(content)

    issues = validate_references(docs_dir)

    assert len(issues) == 1
    assert 'MISSING-DOC.md' in issues[0]['message']

def test_passes_with_valid_links(tmp_path):
    docs_dir = tmp_path / 'docs'
    design_dir = docs_dir / 'design'
    design_dir.mkdir(parents=True)

    # Create both files
    (design_dir / 'DESIGN-001.md').write_text('# Design')

    content = """
**References:**
- [DESIGN-001](docs/design/DESIGN-001.md): Valid link
"""
    (design_dir / 'test.md').write_text(content)

    issues = validate_references(docs_dir)

    assert len(issues) == 0
```

**Step 2: Run test to verify it fails**

```bash
python -m pytest scripts/test_validate_doc_references.py -v
```

Expected: FAIL with "ModuleNotFoundError: No module named 'validate_doc_references'"

**Step 3: Write minimal implementation**

```python
# scripts/validate_doc_references.py
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

    # Find all markdown files
    for md_file in docs_root.rglob('*.md'):
        content = md_file.read_text()

        # Extract all links
        for match in link_pattern.finditer(content):
            link_text = match.group(1)
            link_path = match.group(2)

            # Skip external links
            if link_path.startswith('http'):
                continue

            # Resolve relative path
            if link_path.startswith('docs/'):
                # Absolute from repo root
                full_path = Path(link_path)
            else:
                # Relative to current file
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
```

**Step 4: Run test to verify it passes**

```bash
python -m pytest scripts/test_validate_doc_references.py -v
```

Expected: PASS

**Step 5: Make executable and commit**

```bash
chmod +x scripts/validate_doc_references.py
git add scripts/validate_doc_references.py scripts/test_validate_doc_references.py
git commit -m "feat: add reference validation script"
```

---

## Task 11: Run Final Validation

**Files:**
- None (validation only)

**Step 1: Run validation script**

```bash
python scripts/validate_doc_references.py
```

Expected: "✓ All document references are valid!"

**Step 2: If issues found, investigate and fix**

If broken links detected, either:
- Fix manually if obvious typo
- Re-run fix script if pattern was missed
- Update validation script if false positive

**Step 3: Re-run validation until clean**

```bash
python scripts/validate_doc_references.py
```

Expected: Exit code 0 (no issues)

---

## Task 12: Update Documentation

**Files:**
- Create: `scripts/README.md`

**Step 1: Write documentation**

```markdown
# Documentation Scripts

## fix_doc_references.py

Automatically fixes broken document references in markdown files by converting:

```markdown
- CODE-EXAMPLE-011: Description
```

To:

```markdown
- [CODE-EXAMPLE-011-layer-2a-cloud-function](docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Description
```

**Usage:**

```bash
# Dry run (default)
python scripts/fix_doc_references.py

# Apply changes
python scripts/fix_doc_references.py --apply

# Fix only sprint plans
python scripts/fix_doc_references.py --dir roadmap --apply

# Fix only design docs
python scripts/fix_doc_references.py --dir design --apply
```

## validate_doc_references.py

Validates that all markdown links point to existing files.

**Usage:**

```bash
python scripts/validate_doc_references.py
```

Returns exit code 0 if all references valid, 1 if broken links found.

## Running Tests

```bash
# Run all tests
python -m pytest scripts/ -v

# Run specific test file
python -m pytest scripts/test_map_documents.py -v
```
```

**Step 2: Commit documentation**

```bash
git add scripts/README.md
git commit -m "docs: add README for documentation scripts"
```

---

## Definition of Done

- [x] All sprint plans have valid markdown links
- [x] All design docs have valid markdown links
- [x] All other docs (ADRs, specs, tests) have valid markdown links
- [x] Validation script confirms no broken references
- [x] All tests pass
- [x] Scripts documented in README

---

## Plan Summary

This plan creates a Python-based document reference auditing and fixing system with:

1. **Document Discovery**: Scans docs/ for all markdown files
2. **Prefix Indexing**: Maps document ID prefixes (e.g., `CODE-EXAMPLE-011`) to full paths
3. **Reference Extraction**: Finds unlinked references in markdown files
4. **Link Generation**: Converts references to proper markdown links
5. **Batch Processing**: Processes all docs or specific subdirectories
6. **Validation**: Verifies all links point to existing files
7. **Testing**: Full test suite ensures correctness

**Time Estimate**: 2-3 hours for implementation + testing
**Complexity**: Medium (regex patterns, file I/O, string replacement)
