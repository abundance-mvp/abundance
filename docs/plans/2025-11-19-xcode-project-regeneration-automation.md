# Xcode Project Regeneration Automation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create automated Xcode project regeneration from SPM that preserves all build settings, signing configuration, and Firebase integration without manual intervention.

**Architecture:** Build a declarative configuration system that captures all Xcode project settings in version-controlled files, then regenerate a clean Xcode project using XcodeGen tool while preserving team ID, bundle ID, entitlements, Info.plist, and Firebase configuration.

**Tech Stack:** XcodeGen, YAML configuration, Bash scripting, rsync

---

## Background

**Problem:** The current Xcode project at `/Users/w/code/abundance-mvp-xcode/Abundance/` has duplicate file references causing build failures. The `sim.sh` script syncs SPM sources but the Xcode project structure becomes corrupt over time.

**Root Cause:** Manual Xcode project management + rsync sync = file reference duplicates

**Solution:** Use XcodeGen to generate Xcode project from declarative YAML configuration, ensuring:
- Zero duplicate file references
- Preserved code signing (Team ID: NDAMNXP7RA)
- Preserved bundle ID (com.abundance.mvp)
- Preserved Info.plist and GoogleService-Info.plist
- Preserved entitlements file
- Automated regeneration on each deployment

---

## Task 1: Install XcodeGen Tool

**Files:**
- None (system installation)

**Step 1: Install XcodeGen via Homebrew**

Run:
```bash
brew install xcodegen
```

Expected output: "xcodegen X.X.X successfully installed"

**Step 2: Verify installation**

Run:
```bash
xcodegen --version
```

Expected output: Version number (e.g., "2.40.0")

**Step 3: Document installation in repository setup**

Modify: `/Users/w/code/abundance-mvp/scripts/README.md`

Add to prerequisites section:
```markdown
### XcodeGen

Required for Xcode project regeneration:
```bash
brew install xcodegen
```
```

**Step 4: Commit**

```bash
git add scripts/README.md
git commit -m "docs(scripts): add XcodeGen installation requirement"
```

---

## Task 2: Create XcodeGen Configuration File

**Files:**
- Create: `/Users/w/code/abundance-mvp/project.yml`

**Step 1: Create base project.yml configuration**

Create file at `/Users/w/code/abundance-mvp/project.yml`:

```yaml
name: Abundance
options:
  bundleIdPrefix: com.abundance
  deploymentTarget:
    iOS: "18.0"
  developmentLanguage: en
  xcodeVersion: "16.0"

settings:
  base:
    DEVELOPMENT_TEAM: NDAMNXP7RA
    CODE_SIGN_STYLE: Automatic
    CODE_SIGN_IDENTITY: Apple Development
    SWIFT_VERSION: "6.0"
    IPHONEOS_DEPLOYMENT_TARGET: "18.0"
    ENABLE_STRICT_CONCURRENCY_CHECKING: YES
    SWIFT_UPCOMING_FEATURE_FLAGS: StrictConcurrency

targets:
  Abundance:
    type: application
    platform: iOS
    deploymentTarget: "18.0"

    settings:
      base:
        PRODUCT_NAME: Abundance
        PRODUCT_BUNDLE_IDENTIFIER: com.abundance.mvp
        CODE_SIGN_ENTITLEMENTS: Abundance/Abundance.entitlements
        INFOPLIST_FILE: Abundance/Info.plist
        SWIFT_VERSION: "6.0"
        DEVELOPMENT_TEAM: NDAMNXP7RA
        CODE_SIGN_STYLE: Automatic
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        ENABLE_PREVIEWS: YES

    sources:
      - path: App
        name: App
        type: group
      - path: Sources
        name: Sources
        type: group
        excludes:
          - "**/.build"
          - "**/Tests"

    resources:
      - App/Assets.xcassets
      - App/GoogleService-Info.plist
      - Sources/VisionCore/Resources/yolo11n.mlmodelc

    entitlements:
      path: Abundance/Abundance.entitlements

    dependencies:
      - package: FirebaseAnalytics
        product: FirebaseAnalytics
      - package: FirebaseAuth
        product: FirebaseAuth
      - package: FirebaseFirestore
        product: FirebaseFirestore
      - package: FirebaseStorage
        product: FirebaseStorage

packages:
  FirebaseAnalytics:
    url: https://github.com/firebase/firebase-ios-sdk.git
    from: 11.11.0
```

**Step 2: Validate YAML syntax**

Run:
```bash
python3 -c "import yaml; yaml.safe_load(open('project.yml'))"
```

Expected: No output (valid YAML)

**Step 3: Commit configuration**

```bash
git add project.yml
git commit -m "feat(build): add XcodeGen project configuration

- Declarative Xcode project definition
- Preserves team ID NDAMNXP7RA
- Preserves bundle ID com.abundance.mvp
- Includes Firebase dependencies
- Refs: DEV-ITERATION-SYSTEM-001"
```

---

## Task 3: Copy Critical Files to Xcode Project Structure

**Files:**
- Create: `/Users/w/code/abundance-mvp-xcode/Abundance/Abundance/Info.plist`
- Create: `/Users/w/code/abundance-mvp-xcode/Abundance/Abundance/GoogleService-Info.plist`
- Create: `/Users/w/code/abundance-mvp-xcode/Abundance/Abundance/Abundance.entitlements` (already exists from earlier)

**Step 1: Create Abundance directory in Xcode project**

Run:
```bash
mkdir -p /Users/w/code/abundance-mvp-xcode/Abundance/Abundance
```

**Step 2: Copy Info.plist from SPM App directory**

Run:
```bash
cp /Users/w/code/abundance-mvp/App/Info.plist \
   /Users/w/code/abundance-mvp-xcode/Abundance/Abundance/Info.plist
```

**Step 3: Copy GoogleService-Info.plist**

Run:
```bash
cp /Users/w/code/abundance-mvp/App/GoogleService-Info.plist \
   /Users/w/code/abundance-mvp-xcode/Abundance/Abundance/GoogleService-Info.plist
```

**Step 4: Verify Abundance.entitlements exists**

Run:
```bash
ls -la /Users/w/code/abundance-mvp-xcode/Abundance/Abundance/Abundance.entitlements
```

Expected: File exists (created earlier)

If missing, copy from SPM or create:
```bash
cat > /Users/w/code/abundance-mvp-xcode/Abundance/Abundance/Abundance.entitlements <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.device.camera</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
	<key>keychain-access-groups</key>
	<array>
		<string>$(AppIdentifierPrefix)com.abundance.mvp</string>
	</array>
</dict>
</plist>
EOF
```

**Step 5: No commit** (Xcode project is ephemeral, not version controlled)

---

## Task 4: Create Xcode Project Regeneration Script

**Files:**
- Create: `/Users/w/code/abundance-mvp/scripts/regenerate-xcode-project.sh`

**Step 1: Create regeneration script**

Create file at `/Users/w/code/abundance-mvp/scripts/regenerate-xcode-project.sh`:

```bash
#!/bin/bash
# regenerate-xcode-project.sh - Clean Xcode Project Regeneration
#
# This script:
# 1. Backs up critical files (Info.plist, GoogleService-Info.plist, entitlements)
# 2. Deletes the old Xcode project
# 3. Regenerates clean project using XcodeGen
# 4. Syncs SPM Sources → Xcode
# 5. Restores critical files
#
# Usage: ./scripts/regenerate-xcode-project.sh
#
# Created: 2025-11-19
# References: DEV-ITERATION-SYSTEM-001, XcodeGen automation

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCODE_ROOT="$HOME/code/abundance-mvp-xcode/Abundance"
BACKUP_DIR="$PROJECT_ROOT/.xcode-backup"

echo "🔨 Regenerating Xcode Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Check XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "❌ XcodeGen not found. Install with: brew install xcodegen"
    exit 1
fi

# Step 2: Backup critical files
echo ""
echo "📦 Backing up critical files..."
mkdir -p "$BACKUP_DIR"

if [ -f "$XCODE_ROOT/Abundance/Info.plist" ]; then
    cp "$XCODE_ROOT/Abundance/Info.plist" "$BACKUP_DIR/Info.plist"
    echo "   ✅ Info.plist backed up"
fi

if [ -f "$XCODE_ROOT/Abundance/GoogleService-Info.plist" ]; then
    cp "$XCODE_ROOT/Abundance/GoogleService-Info.plist" "$BACKUP_DIR/GoogleService-Info.plist"
    echo "   ✅ GoogleService-Info.plist backed up"
fi

if [ -f "$XCODE_ROOT/Abundance/Abundance.entitlements" ]; then
    cp "$XCODE_ROOT/Abundance/Abundance.entitlements" "$BACKUP_DIR/Abundance.entitlements"
    echo "   ✅ Abundance.entitlements backed up"
fi

# Step 3: Delete old Xcode project
echo ""
echo "🗑️  Removing old Xcode project..."
rm -rf "$XCODE_ROOT"
echo "   ✅ Old project removed"

# Step 4: Create Xcode root directory
mkdir -p "$XCODE_ROOT"
echo "   ✅ Created $XCODE_ROOT"

# Step 5: Run XcodeGen
echo ""
echo "🔧 Generating new Xcode project..."
cd "$PROJECT_ROOT"

xcodegen generate \
    --spec project.yml \
    --project "$XCODE_ROOT/Abundance.xcodeproj" \
    --use-cache

if [ $? -eq 0 ]; then
    echo "   ✅ Xcode project generated"
else
    echo "   ❌ XcodeGen failed"
    exit 1
fi

# Step 6: Create Abundance directory structure
mkdir -p "$XCODE_ROOT/Abundance"
echo "   ✅ Created Abundance directory"

# Step 7: Sync SPM Sources → Xcode
echo ""
echo "🔄 Syncing SPM sources to Xcode..."
rsync -av --delete \
    --exclude '.build' \
    --exclude '.debug' \
    --exclude '.git' \
    --exclude 'Tests' \
    "$PROJECT_ROOT/Sources/" \
    "$XCODE_ROOT/Abundance/Sources/" \
    2>&1 | grep -v "building file list" | grep -v "sent.*bytes.*received.*bytes" || true

rsync -av --delete \
    --exclude '.DS_Store' \
    "$PROJECT_ROOT/App/" \
    "$XCODE_ROOT/Abundance/App/" \
    2>&1 | grep -v "building file list" | grep -v "sent.*bytes.*received.*bytes" || true

echo "   ✅ Sources synced"

# Step 8: Restore critical files
echo ""
echo "📥 Restoring critical files..."

if [ -f "$BACKUP_DIR/Info.plist" ]; then
    cp "$BACKUP_DIR/Info.plist" "$XCODE_ROOT/Abundance/Info.plist"
    echo "   ✅ Info.plist restored"
else
    # Fallback: copy from SPM
    cp "$PROJECT_ROOT/App/Info.plist" "$XCODE_ROOT/Abundance/Info.plist"
    echo "   ⚠️  Info.plist copied from SPM (no backup found)"
fi

if [ -f "$BACKUP_DIR/GoogleService-Info.plist" ]; then
    cp "$BACKUP_DIR/GoogleService-Info.plist" "$XCODE_ROOT/Abundance/GoogleService-Info.plist"
    echo "   ✅ GoogleService-Info.plist restored"
else
    # Fallback: copy from SPM
    cp "$PROJECT_ROOT/App/GoogleService-Info.plist" "$XCODE_ROOT/Abundance/GoogleService-Info.plist"
    echo "   ⚠️  GoogleService-Info.plist copied from SPM (no backup found)"
fi

if [ -f "$BACKUP_DIR/Abundance.entitlements" ]; then
    cp "$BACKUP_DIR/Abundance.entitlements" "$XCODE_ROOT/Abundance/Abundance.entitlements"
    echo "   ✅ Abundance.entitlements restored"
else
    echo "   ⚠️  Abundance.entitlements not found in backup, will be created by XcodeGen"
fi

# Step 9: Copy Assets
echo ""
echo "📦 Copying assets..."
cp -R "$PROJECT_ROOT/App/Assets.xcassets" "$XCODE_ROOT/Abundance/App/Assets.xcassets"
echo "   ✅ Assets copied"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Xcode project regenerated successfully!"
echo ""
echo "📁 Location: $XCODE_ROOT/Abundance.xcodeproj"
echo ""
echo "Next steps:"
echo "  1. Open in Xcode: open $XCODE_ROOT/Abundance.xcodeproj"
echo "  2. Select your device and build (Cmd+R)"
echo "  3. Or use: ./scripts/sim.sh --device w-16e"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Step 2: Make script executable**

Run:
```bash
chmod +x /Users/w/code/abundance-mvp/scripts/regenerate-xcode-project.sh
```

**Step 3: Test script execution (dry run)**

Run:
```bash
./scripts/regenerate-xcode-project.sh
```

Expected output:
- ✅ Backup created
- ✅ Old project removed
- ✅ New project generated
- ✅ Sources synced
- ✅ Critical files restored

**Step 4: Commit script**

```bash
git add scripts/regenerate-xcode-project.sh
git commit -m "feat(build): add Xcode project regeneration script

- Automated clean project generation using XcodeGen
- Preserves Info.plist, GoogleService-Info.plist, entitlements
- Syncs SPM sources to Xcode structure
- Prevents duplicate file reference issues

Refs: DEV-ITERATION-SYSTEM-001"
```

---

## Task 5: Update sim.sh to Use Regeneration Script

**Files:**
- Modify: `/Users/w/code/abundance-mvp/scripts/sim.sh:59-75`

**Step 1: Add regeneration check to sim.sh**

In `sim.sh`, replace lines 59-75 (the sync section):

```bash
# Step 1: Check if Xcode project needs regeneration
echo "🔄 Checking Xcode project..."
if [ ! -d "$XCODE_ROOT/Abundance.xcodeproj" ]; then
    echo "⚠️  Xcode project not found. Regenerating..."
    "$PROJECT_ROOT/scripts/regenerate-xcode-project.sh"
elif [ "$FORCE_REGENERATE" = true ]; then
    echo "🔨 Force regenerating Xcode project..."
    "$PROJECT_ROOT/scripts/regenerate-xcode-project.sh"
else
    echo "✅ Xcode project exists"

    # Quick sync of sources only
    echo "🔄 Syncing SPM sources..."
    rsync -av --delete \
        --exclude '.build' \
        --exclude '.debug' \
        --exclude '.git' \
        --exclude 'Tests' \
        "$PROJECT_ROOT/Sources/" \
        "$XCODE_ROOT/Abundance/Sources/" \
        2>&1 | grep -v "building file list" | grep -v "sent.*bytes.*received.*bytes" || true

    rsync -av --delete \
        --exclude '.DS_Store' \
        "$PROJECT_ROOT/App/" \
        "$XCODE_ROOT/Abundance/App/" \
        2>&1 | grep -v "building file list" | grep -v "sent.*bytes.*received.*bytes" || true

    echo "✅ Sync complete"
fi
```

**Step 2: Add --regenerate flag to sim.sh argument parsing**

In `sim.sh`, modify lines 26-43 (argument parsing):

```bash
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
```

**Step 3: Update sim.sh usage documentation**

In `sim.sh`, modify lines 2-7 (usage comment):

```bash
# Usage: ./scripts/sim.sh [options] [device-name]
#
# Options:
#   --device      Build and deploy to physical device (default: w-16e)
#   --sim         Build and run on simulator (default: 16PRO-IOS26)
#   --regenerate  Force regenerate Xcode project from scratch
```

**Step 4: Test modified sim.sh**

Run:
```bash
./scripts/sim.sh --regenerate --device w-16e
```

Expected:
- Xcode project regenerated
- App built successfully
- App deployed to device

**Step 5: Commit changes**

```bash
git add scripts/sim.sh
git commit -m "feat(build): integrate Xcode regeneration into sim.sh

- Auto-detects missing Xcode project
- Adds --regenerate flag for manual regeneration
- Falls back to quick sync when project exists
- Ensures zero duplicate file references

Refs: DEV-ITERATION-SYSTEM-001"
```

---

## Task 6: Update Documentation

**Files:**
- Modify: `/Users/w/code/abundance-mvp/docs/dev-workflow/DEV-ITERATION-SYSTEM-001.md`
- Modify: `/Users/w/code/abundance-mvp/docs/dev-workflow/QUICK-REFERENCE.md`
- Modify: `/Users/w/code/abundance-mvp/CLAUDE.md`

**Step 1: Update DEV-ITERATION-SYSTEM-001.md**

In `DEV-ITERATION-SYSTEM-001.md`, add new section after line 305:

```markdown
### Xcode Project Regeneration

The Xcode project is **ephemeral** and regenerated from the SPM project using XcodeGen.

**When to regenerate**:
- First time setup
- Build failures with duplicate file references
- After adding new source files or resources
- Manually: `./scripts/regenerate-xcode-project.sh`

**Automatic regeneration**:
- `./scripts/sim.sh` auto-detects missing project
- Add `--regenerate` flag to force regeneration

**Configuration**:
- `project.yml` - Declarative Xcode project definition
- Preserves: Team ID, Bundle ID, Info.plist, Firebase config, entitlements

**Critical files** (version controlled in SPM, copied to Xcode):
- `App/Info.plist`
- `App/GoogleService-Info.plist`
- `Abundance/Abundance.entitlements` (generated from project.yml)
```

**Step 2: Update QUICK-REFERENCE.md**

In `QUICK-REFERENCE.md`, add new section after line 78:

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

**Step 3: Update CLAUDE.md**

In `CLAUDE.md`, modify the "Workflow" section (around line 230):

```markdown
### Before Starting
```bash
git checkout main && git pull
git checkout -b feature/your-feature
./scripts/validate-environment.sh

# Regenerate Xcode project if needed
./scripts/regenerate-xcode-project.sh
```

### During Development
- Follow MVVM pattern (ViewModels in `Sources/`)
- TDD: Write failing test → implement → verify → commit
- SwiftUI only, no UIKit for UI
- Deploy: `./scripts/sim.sh --device w-16e`

### If Build Fails
```bash
# Regenerate clean Xcode project
./scripts/sim.sh --regenerate --device w-16e
```
```

**Step 4: Commit documentation updates**

```bash
git add docs/dev-workflow/DEV-ITERATION-SYSTEM-001.md \
        docs/dev-workflow/QUICK-REFERENCE.md \
        CLAUDE.md
git commit -m "docs(workflow): document Xcode project regeneration

- Explain ephemeral Xcode project architecture
- Add regeneration commands to quick reference
- Update workflow with regeneration step

Refs: DEV-ITERATION-SYSTEM-001"
```

---

## Task 7: Create .gitignore Entry for Xcode Project

**Files:**
- Modify: `/Users/w/code/abundance-mvp/.gitignore`

**Step 1: Add Xcode backup directory to .gitignore**

Append to `.gitignore`:

```
# Xcode project backups (ephemeral)
.xcode-backup/
```

**Step 2: Commit .gitignore update**

```bash
git add .gitignore
git commit -m "chore(git): ignore Xcode project backups

- .xcode-backup/ is ephemeral, regenerated on each build

Refs: DEV-ITERATION-SYSTEM-001"
```

---

## Task 8: Test End-to-End Workflow

**Files:**
- None (testing only)

**Step 1: Clean test - delete Xcode project**

Run:
```bash
rm -rf /Users/w/code/abundance-mvp-xcode/Abundance
```

**Step 2: Test automatic regeneration via sim.sh**

Run:
```bash
./scripts/sim.sh --device w-16e
```

Expected output:
- ⚠️ Xcode project not found. Regenerating...
- ✅ Xcode project generated
- ✅ Sources synced
- ✅ Build succeeded
- ✅ App deployed to device

**Step 3: Verify app runs on device**

Expected: App launches successfully on w-16e device

**Step 4: Test forced regeneration**

Run:
```bash
./scripts/sim.sh --regenerate --device w-16e
```

Expected output:
- 🔨 Force regenerating Xcode project...
- ✅ Xcode project generated
- ✅ Build succeeded
- ✅ App deployed

**Step 5: Verify zero duplicate file warnings**

Run:
```bash
tail -100 /Users/w/code/abundance-mvp/.debug/logs/session-latest.log | /usr/bin/grep "duplicate"
```

Expected: No "duplicate" warnings in build log

**Step 6: No commit** (testing only)

---

## Task 9: Create Troubleshooting Guide

**Files:**
- Create: `/Users/w/code/abundance-mvp/docs/dev-workflow/XCODE-REGENERATION-TROUBLESHOOTING.md`

**Step 1: Create troubleshooting document**

Create file:

```markdown
# Xcode Project Regeneration Troubleshooting

## Common Issues

### Issue: "XcodeGen not found"

**Error:**
```
❌ XcodeGen not found. Install with: brew install xcodegen
```

**Solution:**
```bash
brew install xcodegen
xcodegen --version  # Verify installation
```

---

### Issue: "Build fails with duplicate file references"

**Error:**
```
error: Multiple commands produce '.../Animation+Extensions.stringsdata'
```

**Solution:**
```bash
# Force regenerate Xcode project
./scripts/regenerate-xcode-project.sh

# Or via sim.sh
./scripts/sim.sh --regenerate --device w-16e
```

---

### Issue: "Info.plist not found"

**Error:**
```
error: The file "Info.plist" could not be opened.
```

**Solution:**
```bash
# Verify Info.plist exists in SPM
ls -la App/Info.plist

# Regenerate project
./scripts/regenerate-xcode-project.sh
```

---

### Issue: "GoogleService-Info.plist missing"

**Error:**
```
FirebaseApp configuration error
```

**Solution:**
```bash
# Verify Firebase config exists
ls -la App/GoogleService-Info.plist

# Download from Firebase Console if missing
# Then regenerate
./scripts/regenerate-xcode-project.sh
```

---

### Issue: "Code signing error"

**Error:**
```
error: No signing certificate "Apple Development" found
```

**Solution:**
1. Open Xcode manually:
   ```bash
   open /Users/w/code/abundance-mvp-xcode/Abundance/Abundance.xcodeproj
   ```
2. Go to Signing & Capabilities
3. Enable "Automatically manage signing"
4. Select your team (NDAMNXP7RA)
5. Close Xcode
6. Run: `./scripts/sim.sh --device w-16e`

**Note:** Signing settings should persist in project.yml

---

### Issue: "YOLO model not found"

**Error:**
```
error: yolo11n.mlmodelc not found
```

**Solution:**
```bash
# Verify model exists
ls -la Sources/VisionCore/Resources/yolo11n.mlmodelc

# If missing, regenerate or re-download model
./scripts/regenerate-xcode-project.sh
```

---

## Force Clean Rebuild

If all else fails:

```bash
# 1. Delete everything
rm -rf /Users/w/code/abundance-mvp-xcode/Abundance
rm -rf .xcode-backup
rm -rf ~/Library/Developer/Xcode/DerivedData

# 2. Regenerate from scratch
./scripts/regenerate-xcode-project.sh

# 3. Build
./scripts/sim.sh --device w-16e
```

---

## Verification Checklist

After regeneration, verify:

- [ ] Xcode project opens without errors
- [ ] Team ID is NDAMNXP7RA
- [ ] Bundle ID is com.abundance.mvp
- [ ] Info.plist exists
- [ ] GoogleService-Info.plist exists
- [ ] Abundance.entitlements exists
- [ ] Zero duplicate file warnings
- [ ] Build succeeds
- [ ] App deploys to device
- [ ] App launches successfully

---

## Getting Help

If issues persist:

1. Check logs: `tail -100 .debug/logs/session-latest.log`
2. Run health check: `./scripts/check-health.sh`
3. Use troubleshoot command: `claude troubleshoot`
4. Review XcodeGen docs: https://github.com/yonaskolb/XcodeGen

---

**Last Updated:** 2025-11-19
```

**Step 2: Commit troubleshooting guide**

```bash
git add docs/dev-workflow/XCODE-REGENERATION-TROUBLESHOOTING.md
git commit -m "docs(workflow): add Xcode regeneration troubleshooting guide

- Common error solutions
- Force clean rebuild steps
- Verification checklist

Refs: DEV-ITERATION-SYSTEM-001"
```

---

## Verification & Testing

### Success Criteria

- [ ] XcodeGen installed and working
- [ ] project.yml generates valid Xcode project
- [ ] regenerate-xcode-project.sh executes without errors
- [ ] sim.sh auto-detects missing Xcode project
- [ ] sim.sh --regenerate forces clean regeneration
- [ ] Zero duplicate file warnings in build
- [ ] App builds successfully
- [ ] App deploys to physical device (w-16e)
- [ ] All documentation updated
- [ ] Troubleshooting guide created

### Integration Points

**DEV-ITERATION-SYSTEM-001 Integration:**
- `sim.sh` calls `regenerate-xcode-project.sh` automatically
- Health check could verify Xcode project integrity
- Issue capture workflow includes regeneration steps

**CLAUDE.md Integration:**
- Daily workflow includes regeneration step
- Quick commands section lists regeneration
- Troubleshooting references regeneration script

### Future Enhancements

**Phase 2:**
- Automatic regeneration on git pull if project.yml changed
- Health check validates project.yml against Xcode project
- CI/CD validation of XcodeGen configuration

**Phase 3:**
- Multiple schemes (Debug, Release, TestFlight)
- Environment-specific configurations
- Automated signing certificate management

---

## Commit Message Template

```
feat(build): automated Xcode project regeneration system

Implements XcodeGen-based automation for clean Xcode project generation:
- Declarative project.yml configuration
- Preserves team ID, bundle ID, Firebase config
- Zero duplicate file references
- Automated via sim.sh workflow
- Comprehensive documentation and troubleshooting

Tasks completed:
- Install XcodeGen tool
- Create project.yml configuration
- Copy critical files structure
- Build regeneration script
- Update sim.sh integration
- Update all documentation
- Create troubleshooting guide
- End-to-end testing

Refs: DEV-ITERATION-SYSTEM-001, BUG-002 (duplicate files)
Breaking: Xcode project now ephemeral, regenerated on demand
```

---

## Plan Complete

**Saved to:** `docs/plans/2025-11-19-xcode-project-regeneration-automation.md`

**Estimated time:** 45-60 minutes (all 9 tasks)

**Dependencies:** Homebrew, XcodeGen, existing SPM project structure

**Testing:** End-to-end deployment to w-16e device with zero duplicate file warnings
