#!/usr/bin/env python3
# scripts/map_documents.py
from pathlib import Path
from typing import Dict, List, TypedDict
import re

class Reference(TypedDict):
    doc_id: str
    description: str
    line_text: str

class DocumentMapper:
    """Maps document ID prefixes to actual file paths."""

    def __init__(self, docs_root: str):
        self.docs_root = Path(docs_root)
        self.documents: List[Path] = []
        self.prefix_index: Dict[str, Path] = {}

    def discover_documents(self) -> List[Path]:
        """Find all markdown files in docs/ directory, excluding archive."""
        all_docs = self.docs_root.rglob('*.md')
        # Filter out any paths containing '/archive/' to exclude archived documents
        self.documents = [doc for doc in all_docs if '/archive/' not in str(doc)]
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

class LinkGenerator:
    """Generate markdown links for document references."""

    def __init__(self, docs_root: str):
        self.docs_root = Path(docs_root)

    def generate(self, reference: Reference, resolved_path: Path | None, source_file: Path | None = None) -> str:
        """Generate markdown link from reference and resolved path.

        Args:
            reference: Reference dict with doc_id, description, line_text
            resolved_path: Actual file path, or None if not found
            source_file: Source file where the link will be placed (for relative path calculation)

        Returns:
            Markdown link string, or original line if not resolved
        """
        if resolved_path is None:
            return reference['line_text']

        # Extract link text from filename stem
        link_text = resolved_path.stem

        # Build relative path from source file (if provided)
        if source_file is not None:
            # Calculate relative path from source file to target file
            # Convert both to absolute paths first
            source_abs = source_file.parent.resolve()
            target_abs = Path(resolved_path).resolve()
            docs_abs = self.docs_root.resolve()

            try:
                # Try simple relative path first
                relative_path = target_abs.relative_to(source_abs)
            except ValueError:
                # If files are in different directory trees, use .. navigation
                # Count how many levels up from source to docs root
                source_rel = source_abs.relative_to(docs_abs)
                levels_up = len(source_rel.parts)

                # Build relative path
                target_rel = target_abs.relative_to(docs_abs)
                relative_path = Path('../' * levels_up) / target_rel
        else:
            # Fallback to docs root relative path
            relative_path = resolved_path

        # Generate markdown link
        return f"- [{link_text}]({relative_path}): {reference['description']}"

class BrokenLinkFixer:
    """Fix broken markdown links by converting to proper relative paths."""

    def __init__(self, docs_root: Path):
        self.docs_root = docs_root
        # Pattern to match markdown links [text](path)
        self.link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

    def fix(self, content: str, source_file: Path) -> tuple[str, int]:
        """Fix broken markdown links in content.

        Args:
            content: Markdown file content
            source_file: Path to the source file

        Returns:
            Tuple of (fixed_content, num_changes)
        """
        fixed_content = content
        changes = 0

        for match in self.link_pattern.finditer(content):
            link_text = match.group(1)
            link_path = match.group(2)

            # Skip external URLs
            if link_path.startswith('http'):
                continue

            # Skip anchor links
            if link_path.startswith('#'):
                continue

            # Check if this is a broken link with docs/ prefix
            if link_path.startswith('docs/'):
                # Calculate what it currently resolves to (relative to source file)
                current_target = (source_file.parent / link_path).resolve()

                # Check if the file exists at the absolute docs/ path
                absolute_target = (self.docs_root.parent / link_path).resolve()

                if absolute_target.exists() and not current_target.exists():
                    # This is a broken link that should be a relative path
                    # Calculate the correct relative path
                    try:
                        relative_path = absolute_target.relative_to(source_file.parent.resolve())
                    except ValueError:
                        # Different directory trees, use .. navigation
                        source_abs = source_file.parent.resolve()
                        docs_abs = self.docs_root.resolve()

                        # Count how many levels up from source to docs root
                        try:
                            source_rel = source_abs.relative_to(docs_abs)
                            levels_up = len(source_rel.parts)
                        except ValueError:
                            # Source is not under docs root
                            continue

                        # Build relative path
                        target_rel = absolute_target.relative_to(docs_abs)
                        relative_path = Path('../' * levels_up) / target_rel

                    # Replace the broken link with the fixed one
                    old_link = f'[{link_text}]({link_path})'
                    new_link = f'[{link_text}]({relative_path})'

                    fixed_content = fixed_content.replace(old_link, new_link)
                    changes += 1

        return fixed_content, changes

class DocumentFixer:
    """Fix unlinked references in markdown documents."""

    def __init__(self, mapper: DocumentMapper):
        self.mapper = mapper
        self.extractor = ReferenceExtractor()
        self.generator = LinkGenerator('docs')

    def fix(self, content: str, source_file: Path | None = None) -> tuple[str, int]:
        """Fix all unlinked references in content.

        Args:
            content: Markdown file content
            source_file: Path to the source file (for relative path calculation)

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
            new_link = self.generator.generate(ref, resolved_path, source_file)

            if new_link != ref['line_text']:
                fixed_content = fixed_content.replace(
                    ref['line_text'],
                    new_link
                )
                changes += 1

        return fixed_content, changes
