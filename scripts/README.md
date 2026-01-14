# Documentation Scripts

## fix_doc_references.py

Automatically fixes broken document references in markdown files by converting unlinked document IDs to proper markdown links.

**What it does:**

Converts this:
```markdown
- CODE-EXAMPLE-011: Layer 2a Cloud Function
```

To this:
```markdown
- [CODE-EXAMPLE-011-layer-2a-cloud-function](docs/design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Layer 2a Cloud Function
```

**How it works:**

1. Scans all markdown files in `docs/` directory
2. Builds a prefix index mapping document IDs (e.g., `CODE-EXAMPLE-011`) to full file paths
3. Extracts unlinked references using regex patterns
4. Resolves each reference to its actual file path
5. Generates proper markdown links with full paths
6. Replaces unlinked references with linked versions

**Usage:**

```bash
# Dry run (preview changes without applying)
python scripts/fix_doc_references.py

# Apply changes to all documents
python scripts/fix_doc_references.py --apply

# Fix only sprint plans in roadmap directory
python scripts/fix_doc_references.py --dir roadmap --apply

# Fix only design documents
python scripts/fix_doc_references.py --dir design --apply
```

**Options:**

- `--apply`: Apply changes to files (default is dry run)
- `--dir <subdirectory>`: Process only a specific subdirectory (e.g., `roadmap`, `design`, `adr`)

**Example output:**

```
📚 Scanning docs for documents...
✓ Found 152 documents
✓ Indexed 98 document prefixes

🔍 Processing 14 files...

📝 roadmap/SPRINT-PLAN-004.md
   → 3 reference(s) fixed
   ✓ Changes applied

============================================================
📊 Summary:
   Files processed: 14
   Files modified: 3
   Total changes: 8
```

---

## validate_doc_references.py

Validates that all markdown links in documentation point to existing files. Useful for detecting broken links after refactoring or moving files.

**What it validates:**

- All local markdown links (e.g., `[text](path/to/file.md)`)
- Skips external links (starting with `http`)
- Skips anchor links (starting with `#`)
- Skips placeholder/template links (containing `XXX`, `...`, `{}`)

**How it works:**

1. Scans all markdown files in `docs/` directory
2. Extracts all markdown links using regex
3. Resolves relative and absolute paths
4. Checks if target files exist
5. Reports any broken links with file location

**Usage:**

```bash
python scripts/validate_doc_references.py
```

**Exit codes:**

- `0`: All references valid
- `1`: Broken references found

**Example output (success):**

```
🔍 Validating document references in docs...
✓ All document references are valid!
```

**Example output (with issues):**

```
🔍 Validating document references in docs...

❌ Found 2 broken reference(s):

  docs/roadmap/SPRINT-PLAN-003.md
    → Broken link: docs/design/MISSING-DOC.md does not exist
  docs/design/DESIGN-042.md
    → Broken link: docs/adr/ADR-999.md does not exist
```

---

## map_documents.py

Core library used by `fix_doc_references.py`. Provides classes for document discovery, reference extraction, and link generation.

**Classes:**

- `DocumentMapper`: Maps document ID prefixes to actual file paths
- `ReferenceExtractor`: Extracts unlinked references from markdown content
- `LinkGenerator`: Generates markdown links for document references
- `DocumentFixer`: Orchestrates the fixing process

**Key features:**

- Excludes archived documents (paths containing `/archive/`)
- Handles both absolute (`docs/...`) and relative paths
- Pattern matching for document IDs: `[A-Z-]+-\d+` (e.g., `CODE-EXAMPLE-011`, `DESIGN-042`)
- Skips already-linked references to avoid duplication

---

## Running Tests

All scripts include comprehensive test coverage using pytest.

**Run all tests:**

```bash
python -m pytest scripts/ -v
```

**Run specific test file:**

```bash
python -m pytest scripts/test_map_documents.py -v
python -m pytest scripts/test_fix_doc_references.py -v
python -m pytest scripts/test_validate_doc_references.py -v
```

**Run with coverage:**

```bash
python -m pytest scripts/ --cov=scripts --cov-report=term-missing
```

**Test files:**

- `test_map_documents.py`: Tests for core mapping, extraction, and generation classes
- `test_fix_doc_references.py`: Integration tests for the fix script
- `test_validate_doc_references.py`: Tests for the validation script

---

## Development Workflow

### Setup (One-time)

Install uv (Python package manager):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

The project uses Python 3.11+ (specified in `.python-version`).

### XcodeGen

Required for Xcode project regeneration:

```bash
brew install xcodegen
```

Verify installation:

```bash
xcodegen --version
```

Expected output: Version number (e.g., "2.44.1")

### Running Scripts

Use `uv run` to execute scripts with automatic dependency management:

```bash
# Validate document references
uv run scripts/validate_doc_references.py

# Fix broken references (dry run)
uv run scripts/fix_doc_references.py

# Apply fixes
uv run scripts/fix_doc_references.py --apply
```

**Why uv?**
- Automatic Python version management (reads `.python-version`)
- Isolated virtual environments (no global `pip install` needed)
- Fast dependency resolution
- Consistent execution across environments

### Automated Workflow Integration

**Claude Code Hook (Automatic):**

When Claude commits changes to `docs/`, the `.claude/hooks/pre-commit` hook automatically runs validation:

```bash
📚 Docs changes detected - validating references...
✅ Document references validated
```

If validation fails, Claude will see the error and can run the fix script.

**CI/CD (GitHub Actions):**

The `validate-docs-spec` workflow runs on every PR to ensure docs integrity. See `.github/workflows/validate-docs-spec.yml`.

### Manual Workflow

**Before making changes:**

1. Validate current state:
   ```bash
   uv run scripts/validate_doc_references.py
   ```

**Making changes:**

1. Edit docs as needed

2. Preview fixes (dry run):
   ```bash
   uv run scripts/fix_doc_references.py
   ```

3. Review proposed changes

4. Apply fixes:
   ```bash
   uv run scripts/fix_doc_references.py --apply
   ```

5. Validate results:
   ```bash
   uv run scripts/validate_doc_references.py
   ```

6. Commit changes (validation runs automatically via Claude hook)

### Running Tests

Run Python script tests with pytest:

```bash
# Install dev dependencies
uv sync --dev

# Run all tests
uv run pytest scripts/ -v

# Run with coverage
uv run pytest scripts/ --cov=scripts --cov-report=term-missing
```

Test files:
- `test_map_documents.py` - Core mapping/extraction/generation
- `test_fix_doc_references.py` - Fix script integration tests
- `test_validate_doc_references.py` - Validation script tests

---

## Troubleshooting

**Issue: Script can't find a document that exists**

- Ensure the document follows the naming pattern: `DOC-ID-###-description.md`
- Check if the document is in the `archive/` directory (excluded by default)
- Verify the document ID matches the filename prefix exactly

**Issue: False positives in validation**

- Check if the link uses relative paths correctly
- Ensure the path starts with `docs/` for absolute references
- Verify the file actually exists at the specified path

**Issue: Tests failing**

- Ensure you're in the repo root: `cd /Users/w/code/spec-kit`
- Check Python version: requires Python 3.9+ for type hints
- Install pytest if missing: `pip install pytest`

---

## Architecture Notes

**Pattern matching:**

The scripts use this regex to identify document IDs:
```python
r'^([A-Z-]+-\d+)'
```

This matches patterns like:
- `CODE-EXAMPLE-011`
- `DESIGN-042`
- `ADR-005`
- `TEST-PLAN-001`

**Reference detection:**

Unlinked references must follow this format:
```markdown
- DOC-ID-###: Description text
```

Already-linked references are automatically skipped:
```markdown
- [DOC-ID-###-full-name](path/to/file.md): Description
```

**Path resolution:**

- Absolute paths: Start with `docs/` and are resolved from repo root
- Relative paths: Resolved relative to the current file's directory
- All generated links use absolute paths for consistency
