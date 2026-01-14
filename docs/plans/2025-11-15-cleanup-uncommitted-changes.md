# Cleanup Uncommitted Changes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Organize and commit all uncommitted changes to appropriate branches and locations

**Architecture:** Multi-track cleanup - Claude automation to feature branch, Sprint 3 stragglers to main, test resources to docs, Python tooling setup with uv

**Tech Stack:** Git, Python 3.9+, uv (Python package manager), Shell scripts

---

## Task 1: Claude Automation Files to Feature Branch

**Files:**
- Create: Feature branch `feature/claude-automation-improvements`
- Stage: `.claude/commands/apple-docs-fetcher.md`
- Stage: `.claude/commands/super-code-review.md`
- Stage: `.claude/settings.local.json`

### Step 1: Create feature branch

```bash
git checkout -b feature/claude-automation-improvements
```

Expected: `Switched to a new branch 'feature/claude-automation-improvements'`

### Step 2: Stage Claude automation files

```bash
git add .claude/commands/apple-docs-fetcher.md
git add .claude/commands/super-code-review.md
git add .claude/settings.local.json
```

Expected: Files staged for commit

### Step 3: Verify staged files

```bash
git status
```

Expected: Shows 3 files staged, no other changes

### Step 4: Commit with descriptive message

```bash
git commit -m "$(cat <<'EOF'
feat(claude): add automation slash commands and permissions

Add two new slash commands for development workflow:
- apple-docs-fetcher: Lightweight Apple docs fetcher with token limit protection
- super-code-review: Invoke superpowers code-reviewer for PR reviews

Update settings.local.json to allow Skill(apple-docs-fetcher) without prompt.

These commands streamline iOS development by providing instant access to Apple
documentation and automated code review capabilities.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Expected: Commit created successfully

### Step 5: Push feature branch to remote

```bash
git push -u origin feature/claude-automation-improvements
```

Expected: Branch pushed to remote

### Step 6: Create pull request

```bash
gh pr create --title "feat(claude): add automation slash commands and permissions" --body "$(cat <<'EOF'
## Summary

- Add `apple-docs-fetcher` slash command for lightweight Apple documentation fetching
- Add `super-code-review` slash command to invoke superpowers code-reviewer
- Update `.claude/settings.local.json` to allow `Skill(apple-docs-fetcher)` without user prompt

## Test plan

- [ ] Verify `/apple-docs-fetcher SwiftUI.View` fetches documentation
- [ ] Verify `/super-code-review` invokes code-reviewer subagent
- [ ] Verify `Skill(apple-docs-fetcher)` runs without prompting

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR created, URL returned

### Step 7: Return to main branch

```bash
git checkout main
```

Expected: `Switched to branch 'main'`

---

## Task 2: Review and Commit Sprint 3 Test Changes

**Files:**
- Modified: `Sources/VisionCore/Services/HouseholdItemDetector.swift`
- Modified: `Tests/PersistenceTests/StorageServiceTests.swift`
- Modified: `Tests/VisionCoreTests/Services/HouseholdItemDetectorTests.swift`

### Step 1: Verify test changes are Sprint 3 related

Read the git diff output (already captured):
- `HouseholdItemDetector.swift`: Added `detectInStream()` for real-time detection
- `StorageServiceTests.swift`: Added iOS compatibility for Process API
- `HouseholdItemDetectorTests.swift`: Added stream detection tests

**Decision:** Keep all changes - these are Sprint 3 real-time detection features

### Step 2: Stage test files

```bash
git add Sources/VisionCore/Services/HouseholdItemDetector.swift
git add Tests/PersistenceTests/StorageServiceTests.swift
git add Tests/VisionCoreTests/Services/HouseholdItemDetectorTests.swift
```

Expected: Files staged

### Step 3: Verify deleted files are intentional

```bash
git status
```

Expected: Shows `Tests/manual-test-sprint-3.log` as deleted (intentional)
Expected: Shows `Tests/VisionCoreTests/Resources/test-household-item.jpg` as deleted (intentional)

### Step 4: Stage deletions

```bash
git add Tests/manual-test-sprint-3.log
git add Tests/VisionCoreTests/Resources/test-household-item.jpg
```

Expected: Deletions staged

### Step 5: Commit Sprint 3 stragglers

```bash
git commit -m "$(cat <<'EOF'
feat(vision): add real-time stream detection for Sprint 3

Add detectInStream() method to HouseholdItemDetector for processing live camera
frames with CVPixelBuffer. Uses lower confidence threshold (0.40 vs 0.60) for
real-time pipeline, with quality filtering happening downstream.

Changes:
- Add detectInStream(pixelBuffer:) method with alternative label support
- Add iOS compatibility guard for Process API in StorageServiceTests
- Add comprehensive stream detection tests with performance benchmarks
- Remove manual test log and unused test image

Tests verify <30ms detection latency and proper handling of low-confidence
results for real-time UX.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Expected: Commit created

### Step 6: Push to main

```bash
git push origin main
```

Expected: Pushed successfully

---

## Task 3: Move Example Catalog Pipeline to Docs

**Files:**
- Create: `docs/design/examples/real-time-detection-ux/`
- Move: `Tests/VisionCoreTests/Resources/example-catalog-pipeline/*`
- Update: README.md with cleaned explanation

### Step 1: Create examples directory

```bash
mkdir -p docs/design/examples/real-time-detection-ux
```

Expected: Directory created

### Step 2: Move files to docs

```bash
mv Tests/VisionCoreTests/Resources/example-catalog-pipeline/* docs/design/examples/real-time-detection-ux/
```

Expected: Files moved

### Step 3: Remove empty directory

```bash
rmdir Tests/VisionCoreTests/Resources/example-catalog-pipeline
```

Expected: Directory removed

### Step 4: Update README with cleaned explanation

Edit `docs/design/examples/real-time-detection-ux/README.md`:

```markdown
# Real-time Object Detection UX Flow

**Purpose:** Visual reference for Sprint 3 Layer 1 real-time detection user experience

**Context:** These mockups guided the architectural pivot from single-photo capture to continuous real-time detection with visual feedback.

---

## User Experience Flow

### Current Architecture
```
Preview → [Capture Button] → Single Photo → Detect Objects
```

### Target Architecture (Sprint 3)
```
Preview → [Continuous Frames] → Real-time Detection → Draw Bounding Border + Classification
```

---

## Experience Phases

The user walks around cataloging items in a frictionless experience. The app provides real-time visual feedback when objects are detected.

### Phase 1: Continuous Object Detection

**File:** `test-01-p1.jpg`

Camera continuously scans for objects as the user moves around. No visual feedback yet - passive detection mode.

### Phase 2: Object Detected - Grey Glowing Border

**File:** `test-01-p2.jpg`

When an object is detected, a glowing grey border appears (similar to iOS Photos app selection). This signals the app is analyzing the object.

**Behavior:**
- Grey border pulses with subtle glow animation
- Indicates "object detected, classification in progress"
- User can continue moving or hold position for better classification

### Phase 3: Successfully Classified - Mint Green Border

**File:** `test-01-p3-success.png`

When classification confidence exceeds threshold, border transitions to bright mint green (`#B3FFE1`).

**Behavior:**
- Green border confirms "successfully cataloged"
- Same logic applies to barcode detection
- User can move on to next object

**Confidence Threshold Logic:**
- Object detected but low confidence → grey border (or no border if very low)
- Confidence exceeds threshold → mint green border
- Timeout after ~5 seconds → mint green even if classification below threshold
- Cropped image passes to Layer 2 regardless (with or without ideal classification)

### Phase 4: Background Pipeline Processing

**Files:** `test-01-p4_obj-1.png`, `test-01-p4_obj-2.png`

Behind the scenes, Layer 1 completes:
1. Crop detected objects into separate images
2. Extract classification metadata
3. Pass cropped images + metadata to Layer 2

**Example:** `test-01_boxes.jpeg` shows multiple objects detected simultaneously, each cropped separately.

---

## Technical Implementation

**Detection API:** Apple Vision framework with YOLOv11n CoreML model
**Confidence Threshold:** Real-time uses 0.40 (vs 0.60 for single-photo)
**Performance Target:** <30ms per frame for smooth UX
**Border Animation:** SwiftUI overlay with glow effect

**Related Code:**
- `Sources/VisionCore/Services/HouseholdItemDetector.swift:detectInStream()`
- Sprint 3 ViewModels for real-time state management

---

## Test Assets

- `test-household-item.jpg` - Original test image for single-photo detection
- `test-desk-items.jpg` - Multi-object desk scene
- `test-detection.swift` - Swift code snippet for detection logic
- `test-yolo11n.py` - Python script for YOLO model testing
- `yolo11n.pt` - YOLOv11n model weights for testing

---

**Created:** 2025-11-15
**Sprint:** Sprint 3 - Real-time Detection Layer 1
**Status:** Reference documentation for implemented feature
```

### Step 5: Stage moved files

```bash
git add docs/design/examples/real-time-detection-ux/
git add Tests/VisionCoreTests/Resources/example-catalog-pipeline/
```

Expected: New files staged, deleted files staged

### Step 6: Commit documentation move

```bash
git commit -m "$(cat <<'EOF'
docs: move real-time detection UX mockups to design examples

Move example-catalog-pipeline test resources to docs/design/examples/ for
better discoverability and context. These mockups guided Sprint 3's
architectural pivot from single-photo to real-time continuous detection.

Updated README explains the 4-phase user experience:
- Phase 1: Continuous detection (passive scanning)
- Phase 2: Grey border (object detected, analyzing)
- Phase 3: Mint green border (successfully classified)
- Phase 4: Background cropping and Layer 2 handoff

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Expected: Commit created

### Step 7: Push to main

```bash
git push origin main
```

Expected: Pushed successfully

---

## Task 4: Setup Python Scripts with uv

**Files:**
- Create: `pyproject.toml` (uv project configuration)
- Create: `.python-version` (Python version specification)
- Update: `scripts/README.md` (add uv instructions)
- Modify: Python scripts to use `#!/usr/bin/env python3` shebang

### Step 1: Check if uv is installed

```bash
which uv
```

Expected: `/usr/local/bin/uv` or similar (if installed)

If not installed, proceed to Step 2. If installed, skip to Step 3.

### Step 2: Install uv (if needed)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Expected: `uv` installed successfully

### Step 3: Verify uv installation

```bash
uv --version
```

Expected: Version number displayed (e.g., `uv 0.4.0`)

### Step 4: Create Python version file

```bash
echo "3.11" > .python-version
```

Expected: File created

### Step 5: Initialize uv project

```bash
uv init --no-readme --lib
```

Expected: `pyproject.toml` created

### Step 6: Update pyproject.toml with project details

Edit `pyproject.toml`:

```toml
[project]
name = "abundance-mvp"
version = "0.1.0"
description = "Abundance MVP - iOS app for household item cataloging"
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
]

[tool.pytest.ini_options]
testpaths = ["scripts"]
python_files = "test_*.py"
python_classes = "Test*"
python_functions = "test_*"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Step 7: Verify Python scripts have correct shebang

Check `scripts/fix_doc_references.py`:

```bash
head -1 scripts/fix_doc_references.py
```

Expected: `#!/usr/bin/env python3`

Check `scripts/validate_doc_references.py`:

```bash
head -1 scripts/validate_doc_references.py
```

Expected: `#!/usr/bin/env python3`

Both already have correct shebang ✅

### Step 8: Verify scripts are executable

```bash
ls -l scripts/*.py
```

Expected: All show `-rwxr-xr-x` permissions

If not executable:

```bash
chmod +x scripts/fix_doc_references.py
chmod +x scripts/validate_doc_references.py
chmod +x scripts/map_documents.py
```

### Step 9: Test running script with uv

```bash
uv run scripts/validate_doc_references.py
```

Expected: Script runs and validates docs (may show errors if docs have issues)

---

## Task 5: Integrate Scripts into Development Workflow

**Files:**
- Create: `.claude/hooks/pre-commit` (Claude Code hook)
- Update: `scripts/README.md` (document workflow integration)

### Step 1: Determine best integration point

**Analysis:**
- Git pre-commit hook: Runs before every commit (might be too aggressive)
- Claude Code hook: Runs when Claude creates commits (balanced approach)
- CI/CD workflow: Already exists for validation (good backup)

**Decision:** Use Claude Code pre-commit hook for automatic validation when Claude commits

### Step 2: Create Claude pre-commit hook

Create `.claude/hooks/pre-commit`:

```bash
#!/bin/bash
# Claude Code pre-commit hook
# Validates document references before committing docs changes

set -e

# Check if any docs/ files are staged
if git diff --cached --name-only | grep -q "^docs/"; then
    echo "📚 Docs changes detected - validating references..."

    # Run validation with uv
    if uv run scripts/validate_doc_references.py; then
        echo "✅ Document references validated"
    else
        echo "❌ Document reference validation failed"
        echo "Run 'uv run scripts/fix_doc_references.py --apply' to fix"
        exit 1
    fi
fi

exit 0
```

### Step 3: Make hook executable

```bash
chmod +x .claude/hooks/pre-commit
```

Expected: Hook is executable

### Step 4: Test hook (dry run)

```bash
# Stage a docs file to test
git add docs/roadmap/SPRINT-PLAN-006.md
.claude/hooks/pre-commit
```

Expected: Validation runs, exits 0 if docs are valid

### Step 5: Unstage test file

```bash
git restore --staged docs/roadmap/SPRINT-PLAN-006.md
```

Expected: File unstaged

### Step 6: Update scripts/README.md with workflow section

Update the "Development Workflow" section in `scripts/README.md`:

Replace lines 175-216 with:

```markdown
## Development Workflow

### Setup (One-time)

Install uv (Python package manager):

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

The project uses Python 3.11+ (specified in `.python-version`).

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
```

### Step 7: Stage workflow changes

```bash
git add pyproject.toml
git add .python-version
git add .claude/hooks/pre-commit
git add scripts/README.md
```

Expected: Files staged

### Step 8: Commit Python tooling setup

```bash
git commit -m "$(cat <<'EOF'
build: setup Python scripts with uv package manager

Add uv-based Python tooling for documentation scripts:
- Create pyproject.toml with pytest configuration
- Add .python-version (Python 3.11)
- Add .claude/hooks/pre-commit for automatic doc validation
- Update scripts/README.md with uv workflow

Claude Code hook validates docs/ changes before committing, ensuring reference
integrity. Developers can run 'uv run scripts/validate_doc_references.py' to
check manually.

Scripts are executable with shebang (#!/usr/bin/env python3) and can be run
directly with 'uv run scripts/<script>.py'.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Expected: Commit created

### Step 9: Push to main

```bash
git push origin main
```

Expected: Pushed successfully

---

## Task 6: Verification and Cleanup

### Step 1: Verify git status is clean

```bash
git status
```

Expected: `nothing to commit, working tree clean`

### Step 2: Verify feature branch PR exists

```bash
gh pr list
```

Expected: Shows PR for `feature/claude-automation-improvements`

### Step 3: Verify recent commits on main

```bash
git log --oneline -5
```

Expected: Shows 3 new commits (Sprint 3 stragglers, docs move, Python setup)

### Step 4: Test uv workflow end-to-end

```bash
uv run scripts/validate_doc_references.py
```

Expected: Validation passes

### Step 5: Verify Claude hook works

```bash
# Make a test edit to docs
echo "" >> docs/roadmap/SPRINT-PLAN-006.md
git add docs/roadmap/SPRINT-PLAN-006.md
.claude/hooks/pre-commit
```

Expected: Hook runs validation successfully

### Step 6: Restore test edit

```bash
git restore --staged docs/roadmap/SPRINT-PLAN-006.md
git restore docs/roadmap/SPRINT-PLAN-006.md
```

Expected: Test changes discarded

---

## Summary

**Commits created:**
1. `feat(claude): add automation slash commands and permissions` (feature branch)
2. `feat(vision): add real-time stream detection for Sprint 3` (main)
3. `docs: move real-time detection UX mockups to design examples` (main)
4. `build: setup Python scripts with uv package manager` (main)

**Pull requests:**
1. `feature/claude-automation-improvements` → `main`

**Workflow improvements:**
- Automatic doc validation via Claude Code hook
- uv-based Python script execution
- Executable scripts with proper shebangs
- Comprehensive README documentation

**Files organized:**
- Claude automation files → feature branch (pending PR)
- Sprint 3 stragglers → committed to main
- UX mockups → `docs/design/examples/real-time-detection-ux/`
- Python tooling → configured and documented
