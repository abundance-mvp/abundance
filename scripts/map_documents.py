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
