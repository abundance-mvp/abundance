# Single-Directory Xcode Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate the two-directory sync workflow by generating Xcode project in-place, removing ~80% of iteration system complexity.

**Architecture:** Generate `.xcodeproj` directly in `abundance-mvp/` alongside `Package.swift`. No separate Xcode directory, no rsync, no backup/restore dance. XcodeGen's `--use-cache` handles incremental regeneration.

**Tech Stack:** XcodeGen, xcodebuild, Bash

---

## Pre-flight Checklist

Before starting, ensure:
- [ ] Current branch is clean (`git status` shows no uncommitted changes)
- [ ] Create a feature branch: `git checkout -b refactor/single-directory-xcode`
- [ ] Backup exists: `cp -r ~/code/abundance-mvp-xcode ~/code/abundance-mvp-xcode-backup`

---

## Task 1: Update project.yml Paths

**Files:**
- Modify: `project.yml:29-30`

**Context:** The current `project.yml` assumes Info.plist is at the root level, but it actually lives in `App/Info.plist`. When generating in-place, we need correct relative paths.

**Step 1: Update INFOPLIST_FILE path**

Open `project.yml` and change line 30:

```yaml
# Before
INFOPLIST_FILE: Info.plist

# After
INFOPLIST_FILE: App/Info.plist
```

**Step 2: Verify project.yml is valid**

Run:
```bash
xcodegen generate --spec project.yml --use-cache
```

Expected: "Project generated" message, `Abundance.xcodeproj` created in project root.

**Step 3: Commit**

```bash
git add project.yml
git commit -m "fix(project): update INFOPLIST_FILE path for in-place generation"
```

---

## Task 2: Update .gitignore

**Files:**
- Modify: `.gitignore`

**Context:** The generated `.xcodeproj` should be git-ignored since it's regenerated from `project.yml`. The current `.gitignore` has partial xcodeproj rules that may not work correctly.

**Step 1: Update .gitignore**

Replace the Xcode section (lines 1-7) with:

```gitignore
# Xcode - generated project (regenerate with: xcodegen generate)
Abundance.xcodeproj/

# Xcode user data (always ignored)
*.xcworkspace/
xcuserdata/
*.xccheckout
*.moved-aside
*.xcuserstate
.swiftpm/
DerivedData/

# macOS
.DS_Store
```

**Step 2: Remove any existing tracked xcodeproj**

```bash
git rm -r --cached Abundance.xcodeproj 2>/dev/null || echo "Not tracked"
```

**Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore(git): update gitignore for in-place xcodeproj generation"
```

---

## Task 3: Rewrite scripts/sim.sh

**Files:**
- Modify: `scripts/sim.sh` (full rewrite, ~260 lines → ~150 lines)

**Context:** The current script has ~30 lines of rsync logic and references `$XCODE_ROOT` pointing to a separate directory. The new version generates in-place and builds from the current directory.

**Step 1: Replace scripts/sim.sh with simplified version**

```bash
#!/bin/bash
# sim.sh - Fast iOS Development Loop (Simulator or Physical Device)
# Usage: ./scripts/sim.sh [options] [device-name]
#
# Options:
#   --device      Build and deploy to physical device (default: w-16e)
#   --sim         Build and run on simulator (default: 16PRO-IOS26)
#   --regenerate  Force regenerate Xcode project from scratch
#
# This script:
# 1. Regenerates Xcode project if needed (xcodegen)
# 2. Builds the app with xcodebuild
# 3. Launches on simulator or deploys to device
# 4. Captures logs to .debug/logs/

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/.debug/logs"
SESSION_LOG="$LOG_DIR/session-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"

# Parse arguments
USE_DEVICE=false
DEVICE_NAME=""
FORCE_REGENERATE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --device)
            USE_DEVICE=true
            shift
            ;;
        --sim)
            USE_DEVICE=false
            shift
            ;;
        --regenerate)
            FORCE_REGENERATE=true
            shift
            ;;
        *)
            DEVICE_NAME="$1"
            shift
            ;;
    esac
done

# Set defaults based on mode
if [ "$USE_DEVICE" = true ]; then
    DEVICE_NAME="${DEVICE_NAME:-w-16e}"
    TARGET_TYPE="physical device"
else
    DEVICE_NAME="${DEVICE_NAME:-16PRO-IOS26}"
    TARGET_TYPE="simulator"
    SIMULATOR_ID_FALLBACK="2A6B63F1-9769-40AD-AFEB-227E3E755883"
fi

echo "🚀 Abundance Fast Iteration Loop"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Generate Xcode project if needed
cd "$PROJECT_ROOT"

if [ ! -d "Abundance.xcodeproj" ]; then
    echo "⚠️  Xcode project not found. Generating..."
    xcodegen generate --spec project.yml
elif [ "$FORCE_REGENERATE" = true ]; then
    echo "🔨 Force regenerating Xcode project..."
    trash Abundance.xcodeproj 2>/dev/null || rm -rf Abundance.xcodeproj
    xcodegen generate --spec project.yml
else
    echo "🔄 Checking Xcode project..."
    xcodegen generate --spec project.yml --use-cache
fi

echo "✅ Xcode project ready"

# Step 2: Build
echo ""
echo "🔨 Building for $TARGET_TYPE..."

if [ "$USE_DEVICE" = true ]; then
    # Build for physical device
    DEVICE_ID=$(xcrun xctrace list devices 2>&1 | grep "$DEVICE_NAME" | head -1 | grep -oE '\([A-Z0-9-]+\)' | tr -d '()')

    if [ -z "$DEVICE_ID" ]; then
        echo "❌ Physical device not found: $DEVICE_NAME"
        echo ""
        echo "Available devices:"
        xcrun xctrace list devices 2>&1 | grep -E "iPhone|iPad" | grep -v "Simulator"
        exit 1
    fi

    echo "   Using device: $DEVICE_NAME (ID: $DEVICE_ID)"

    xcodebuild \
        -project Abundance.xcodeproj \
        -scheme Abundance \
        -destination "id=$DEVICE_ID" \
        -sdk iphoneos \
        -configuration Debug \
        -allowProvisioningUpdates \
        build install 2>&1 | tee "$SESSION_LOG" | grep -E "error:|warning:|Abundance|Build succeeded|Build failed|Installing" || true

    DEVICE_INSTALL_HANDLED=true
else
    # Build for simulator
    SIMULATOR_ID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | head -1 | grep -oE '\([A-Z0-9-]+\)' | tr -d '()')

    if [ -z "$SIMULATOR_ID" ]; then
        echo "⚠️  Simulator name not found, using fallback ID: $SIMULATOR_ID_FALLBACK"
        SIMULATOR_ID="$SIMULATOR_ID_FALLBACK"

        if ! xcrun simctl list devices | grep -q "$SIMULATOR_ID"; then
            echo "❌ Simulator not found: $DEVICE_NAME (ID: $SIMULATOR_ID)"
            echo ""
            echo "Available simulators:"
            xcrun simctl list devices | grep -E "iPhone|iPad" | grep -v "unavailable"
            exit 1
        fi
    fi

    echo "   Using simulator: $DEVICE_NAME (ID: $SIMULATOR_ID)"

    xcodebuild \
        -project Abundance.xcodeproj \
        -scheme Abundance \
        -destination "id=$SIMULATOR_ID" \
        -sdk iphonesimulator \
        -configuration Debug \
        build 2>&1 | tee "$SESSION_LOG" | grep -E "error:|warning:|Abundance|Build succeeded|Build failed" || true

    BUILD_PRODUCT_PATH="Debug-iphonesimulator"
fi

# Check if build succeeded
if grep -q "Build failed" "$SESSION_LOG"; then
    echo ""
    echo "❌ Build failed. Check logs at: $SESSION_LOG"
    echo ""
    echo "Last 20 errors:"
    grep "error:" "$SESSION_LOG" | tail -20
    exit 1
fi

echo "✅ Build succeeded"

# Step 3: Deploy/Launch
echo ""
if [ "$USE_DEVICE" = true ]; then
    echo "✅ App installed to device via xcodebuild"
    echo ""
    echo "📱 Open the app on your device: $DEVICE_NAME"
    echo ""
    echo "To capture logs from device:"
    echo "  xcrun devicectl device monitor logs --device $DEVICE_ID"
else
    echo "🚀 Launching simulator..."

    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "   (Simulator already running)"

    APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData -path "*/$BUILD_PRODUCT_PATH/Abundance.app" -type d 2>/dev/null | head -1)"
    if [ -n "$APP_PATH" ]; then
        xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
        echo "✅ App installed"
    else
        echo "⚠️  Could not find Abundance.app in DerivedData"
    fi

    BUNDLE_ID="com.abundance.mvp"
    echo ""
    echo "📱 Launching app..."
    xcrun simctl launch --console-pty "$SIMULATOR_ID" "$BUNDLE_ID" 2>&1 | tee -a "$SESSION_LOG" &
    APP_PID=$!

    open -a Simulator
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$USE_DEVICE" = true ]; then
    echo "✅ Abundance deployed to $DEVICE_NAME!"
else
    echo "✅ Abundance is running on simulator!"
    echo ""
    echo "Press Ctrl+C to stop logging..."
fi
echo ""
echo "📋 Logs: $SESSION_LOG"
echo "🐛 Found a bug? Run: ./scripts/capture-issue.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wait for Ctrl+C (simulator only)
if [ "$USE_DEVICE" = false ] && [ -n "$APP_PID" ]; then
    wait $APP_PID
fi
```

**Step 2: Make executable and test**

```bash
chmod +x scripts/sim.sh
./scripts/sim.sh --sim
```

Expected: App builds and launches in simulator without rsync or separate directory references.

**Step 3: Commit**

```bash
git add scripts/sim.sh
git commit -m "refactor(scripts): simplify sim.sh for in-place xcode generation

- Remove rsync sync logic (~30 lines)
- Remove separate XCODE_ROOT directory references
- Use xcodegen --use-cache for incremental updates
- Build directly from project root"
```

---

## Task 4: Rewrite scripts/regenerate-xcode-project.sh

**Files:**
- Modify: `scripts/regenerate-xcode-project.sh` (full rewrite, ~198 lines → ~50 lines)

**Context:** The backup/restore dance is no longer needed. Just delete and regenerate.

**Step 1: Replace with simplified version**

```bash
#!/bin/bash
# regenerate-xcode-project.sh - Clean Xcode Project Regeneration
#
# This script:
# 1. Deletes the existing Xcode project
# 2. Regenerates clean project using XcodeGen
#
# Usage: ./scripts/regenerate-xcode-project.sh [--yes]

set -e

AUTO_YES=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--yes]"
            exit 1
            ;;
    esac
done

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔨 Regenerating Xcode Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "❌ XcodeGen not found. Install with: brew install xcodegen"
    exit 1
fi

# Confirmation prompt
if [ "$AUTO_YES" = false ]; then
    echo "⚠️  This will DELETE and regenerate Abundance.xcodeproj"
    read -p "Continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Delete and regenerate
echo ""
echo "🗑️  Removing old Xcode project..."
trash Abundance.xcodeproj 2>/dev/null || rm -rf Abundance.xcodeproj

echo "🔧 Generating new Xcode project..."
xcodegen generate --spec project.yml

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Xcode project regenerated!"
echo ""
echo "📁 Location: $PROJECT_ROOT/Abundance.xcodeproj"
echo ""
echo "Next steps:"
echo "  open Abundance.xcodeproj"
echo "  # or"
echo "  ./scripts/sim.sh --device w-16e"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Step 2: Test**

```bash
./scripts/regenerate-xcode-project.sh --yes
ls -la Abundance.xcodeproj
```

Expected: Project regenerated in ~2 seconds (vs ~10+ seconds before).

**Step 3: Commit**

```bash
git add scripts/regenerate-xcode-project.sh
git commit -m "refactor(scripts): simplify regenerate script for in-place generation

- Remove backup/restore logic (~100 lines)
- Remove rsync sync logic
- Single xcodegen command
- 198 lines → 50 lines"
```

---

## Task 5: Update scripts/check-health.sh

**Files:**
- Modify: `scripts/check-health.sh:94`

**Context:** One line references the old Xcode directory path.

**Step 1: Update the Xcode project check**

Change line 94 from:
```bash
if [ -d "$HOME/code/abundance-mvp-xcode/Abundance/Abundance.xcodeproj" ]; then
```

To:
```bash
if [ -d "$PROJECT_ROOT/Abundance.xcodeproj" ]; then
```

**Step 2: Commit**

```bash
git add scripts/check-health.sh
git commit -m "fix(scripts): update check-health.sh for in-place xcode project"
```

---

## Task 6: Clean Up Obsolete Files and Directories

**Files:**
- Delete: `.xcode-backup/` directory
- Delete: `Abundance/` directory (stale duplicate at project root)
- Archive: `~/code/abundance-mvp-xcode/` (external directory)

**Step 1: Remove .xcode-backup**

```bash
trash .xcode-backup 2>/dev/null || rm -rf .xcode-backup
```

**Step 2: Remove stale Abundance directory**

```bash
# Check what's in it first
ls -la Abundance/

# If it's stale/duplicate, remove it
trash Abundance 2>/dev/null || rm -rf Abundance
```

**Step 3: Update .gitignore to remove .xcode-backup reference**

Remove these lines from `.gitignore`:
```gitignore
# Xcode project backups (ephemeral)
.xcode-backup/
```

**Step 4: Archive external Xcode directory**

```bash
# Keep backup for safety, but mark as archived
mv ~/code/abundance-mvp-xcode ~/code/abundance-mvp-xcode-ARCHIVED-$(date +%Y%m%d)
```

**Step 5: Commit**

```bash
git add .gitignore
git commit -m "chore: remove obsolete xcode-backup directory and references"
```

---

## Task 7: Update Documentation - QUICK-REFERENCE.md

**Files:**
- Modify: `docs/dev-workflow/QUICK-REFERENCE.md`

**Step 1: Update the "What happens" section (lines 14-18)**

Change:
```markdown
**What happens**:
1. Syncs SPM → Xcode
2. Builds app
3. Launches simulator
4. Captures logs to `.debug/logs/`
```

To:
```markdown
**What happens**:
1. Regenerates Xcode project if needed (cached, instant)
2. Builds app
3. Launches simulator
4. Captures logs to `.debug/logs/`
```

**Step 2: Update "Regenerate Xcode Project" section (lines 80-93)**

Change:
```markdown
## 🔨 Regenerate Xcode Project

```bash
# If you get build errors with duplicate files
./scripts/regenerate-xcode-project.sh

# Or force regenerate during deployment
./scripts/sim.sh --regenerate --device w-16e
```

**When to use**:
- Duplicate file reference errors
- Missing Xcode project
- After major source structure changes
```

To:
```markdown
## 🔨 Regenerate Xcode Project

```bash
# Force clean regeneration
./scripts/regenerate-xcode-project.sh

# Or with sim.sh
./scripts/sim.sh --regenerate
```

**When to use**:
- Xcode project corruption
- After editing project.yml
- Build errors that don't make sense
```

**Step 3: Update "Key Directories" section - remove worktrees reference if not using**

Keep as-is unless you want to remove the worktrees line.

**Step 4: Commit**

```bash
git add docs/dev-workflow/QUICK-REFERENCE.md
git commit -m "docs: update QUICK-REFERENCE for simplified xcode workflow"
```

---

## Task 8: Update Documentation - ITERATION-SYSTEM-SUMMARY.md

**Files:**
- Modify: `ITERATION-SYSTEM-SUMMARY.md`

**Step 1: Update Layer 1 section (lines 17-22)**

Change:
```markdown
- **Fast simulator script** (`scripts/sim.sh`)
  - Syncs SPM → Xcode
  - Builds and runs on simulator
  - Captures logs automatically
```

To:
```markdown
- **Fast simulator script** (`scripts/sim.sh`)
  - Generates Xcode project in-place (cached)
  - Builds and runs on simulator
  - Captures logs automatically
```

**Step 2: Update workflow diagram (lines 111-139)**

Change line 117:
```
│  2. ./scripts/sim.sh                                    │
```

The diagram is still accurate - no change needed.

**Step 3: Commit**

```bash
git add ITERATION-SYSTEM-SUMMARY.md
git commit -m "docs: update ITERATION-SYSTEM-SUMMARY for in-place xcode generation"
```

---

## Task 9: Update Documentation - CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update "During Development" section**

Find the section that mentions `sim.sh` and ensure it doesn't reference the old workflow.

Current text is fine - no changes needed as it just says:
```markdown
- Deploy: `./scripts/sim.sh --device w-16e`
```

**Step 2: Update "If Build Fails" section**

Change:
```markdown
### If Build Fails
```bash
# Regenerate clean Xcode project
./scripts/sim.sh --regenerate --device w-16e
```
```

To:
```markdown
### If Build Fails
```bash
# Regenerate clean Xcode project
./scripts/regenerate-xcode-project.sh --yes
./scripts/sim.sh --device w-16e
```
```

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for simplified xcode workflow"
```

---

## Task 10: Simplify XCODE-REGENERATION-TROUBLESHOOTING.md

**Files:**
- Modify: `docs/dev-workflow/XCODE-REGENERATION-TROUBLESHOOTING.md`

**Context:** Most troubleshooting issues were caused by the two-directory sync. With in-place generation, this doc can be drastically simplified.

**Step 1: Read current content**

```bash
cat docs/dev-workflow/XCODE-REGENERATION-TROUBLESHOOTING.md
```

**Step 2: Replace with simplified version**

```markdown
# Xcode Project Troubleshooting

## Quick Fix

Most issues are solved by regenerating the project:

```bash
./scripts/regenerate-xcode-project.sh --yes
```

## Common Issues

### "No such module" errors

```bash
# Clean DerivedData and regenerate
rm -rf ~/Library/Developer/Xcode/DerivedData/Abundance-*
./scripts/regenerate-xcode-project.sh --yes
```

### Signing issues

1. Open `Abundance.xcodeproj` in Xcode
2. Select the Abundance target
3. Signing & Capabilities → Select your team
4. Build again

### XcodeGen not found

```bash
brew install xcodegen
```

## When to Regenerate

- After editing `project.yml`
- After adding/removing Swift files (usually auto-detected)
- When build errors don't match your code
- After pulling changes that modified project structure

## Architecture

The Xcode project is generated from `project.yml` using XcodeGen:

```
project.yml (source of truth)
    ↓ xcodegen generate
Abundance.xcodeproj (generated, git-ignored)
```

Never edit the `.xcodeproj` directly - changes will be lost on regeneration.
```

**Step 3: Commit**

```bash
git add docs/dev-workflow/XCODE-REGENERATION-TROUBLESHOOTING.md
git commit -m "docs: simplify XCODE-REGENERATION-TROUBLESHOOTING for new workflow"
```

---

## Task 11: Final Verification

**Step 1: Clean slate test**

```bash
# Remove generated project
trash Abundance.xcodeproj

# Full workflow test
./scripts/sim.sh --sim
```

Expected: Project generates, builds, and launches successfully.

**Step 2: Device test**

```bash
./scripts/sim.sh --device w-16e
```

Expected: App deploys to physical device.

**Step 3: Health check**

```bash
./scripts/check-health.sh
```

Expected: All checks pass, including Xcode project check.

**Step 4: Verify no references to old paths**

```bash
grep -r "abundance-mvp-xcode" . --include="*.sh" --include="*.md" --include="*.yml" 2>/dev/null
```

Expected: No matches (except possibly in archived/historical docs).

---

## Task 12: Final Commit and PR

**Step 1: Review all changes**

```bash
git log --oneline main..HEAD
git diff main --stat
```

**Step 2: Create PR**

```bash
gh pr create --title "refactor: single-directory Xcode workflow" --body "$(cat <<'EOF'
## Summary

Eliminates the two-directory sync workflow by generating Xcode project in-place.

### Changes
- **project.yml**: Updated INFOPLIST_FILE path
- **scripts/sim.sh**: Removed rsync, simplified to ~150 lines
- **scripts/regenerate-xcode-project.sh**: Simplified to ~50 lines
- **scripts/check-health.sh**: Updated path reference
- **.gitignore**: Updated for in-place generation
- **Documentation**: Updated 4 docs to reflect new workflow

### What's Removed
- rsync sync between directories
- Backup/restore dance for Info.plist, entitlements
- `.xcode-backup/` directory
- `~/code/abundance-mvp-xcode/` external directory

### New Workflow
```bash
./scripts/sim.sh          # Just works - no sync needed
./scripts/sim.sh --regenerate  # Force clean regeneration
```

## Test Plan
- [x] `./scripts/sim.sh --sim` - simulator build works
- [x] `./scripts/sim.sh --device w-16e` - device build works
- [x] `./scripts/regenerate-xcode-project.sh` - clean regen works
- [x] `./scripts/check-health.sh` - health check passes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Summary

| Metric | Before | After |
|--------|--------|-------|
| sim.sh lines | ~260 | ~150 |
| regenerate-xcode-project.sh lines | ~198 | ~50 |
| Directories to manage | 2 | 1 |
| rsync operations | 2 per build | 0 |
| Backup/restore steps | 6 | 0 |
| Time to understand workflow | High | Low |
