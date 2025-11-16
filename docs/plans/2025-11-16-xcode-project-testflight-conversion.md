# Xcode Project TestFlight Conversion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert Swift Package Manager project to Xcode project structure and configure for TestFlight distribution

**Architecture:** Migrate from SPM executable target to Xcode iOS App target with proper .app bundle, code signing, provisioning profiles, and App Store Connect integration

**Tech Stack:**
- Xcode 26.0 Beta
- Swift 6.0
- iOS 18.0+ deployment target
- Firebase iOS SDK (Auth, Firestore, Storage)
- Vision Framework + CoreML (YOLO11n)
- TestFlight / App Store Connect

**Current State:** SPM project with 6 modules (OnboardingFeature, CameraFeature, InventoryFeature, Persistence, VisionCore, AbundanceApp) that builds as executable, not .app bundle

**Target State:** Xcode project with proper iOS App target, framework dependencies, resources, entitlements, and distribution configuration

---

## Task 1: Create Xcode Project Structure

**Files:**
- Create: `Abundance.xcodeproj/project.pbxproj` (via Xcode)
- Create: `Abundance/Info.plist`
- Create: `Abundance/Abundance.entitlements`
- Backup: `Package.swift` → `Package.swift.backup`

**Step 1: Create new Xcode iOS App project**

```bash
# Create project via command line
mkdir -p /tmp/xcode-template
cd /tmp/xcode-template
cat > create_project.sh << 'EOF'
#!/bin/bash
/Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild \
  -project /dev/null \
  docbuild 2>&1 | head -1
EOF
chmod +x create_project.sh
```

Expected: Command exists (verifies Xcode CLI tools)

**Step 2: Open Xcode and create project manually**

Run: `open -a "Xcode-beta"`

Manual steps (cannot be automated):
1. File → New → Project
2. Select "iOS" → "App"
3. Product Name: "Abundance"
4. Team: "Woodrow Pearson (NDAMNXP7RA)"
5. Organization Identifier: "com.abundance"
6. Bundle Identifier: "com.abundance.mvp"
7. Interface: SwiftUI
8. Language: Swift
9. Location: `/Users/w/code/abundance-mvp-xcode` (NEW directory, not current)
10. Click "Create"

Expected: Abundance.xcodeproj created in `/Users/w/code/abundance-mvp-xcode/`

**Step 3: Verify project creation**

```bash
ls -la /Users/w/code/abundance-mvp-xcode/Abundance.xcodeproj/
```

Expected: project.pbxproj file exists

**Step 4: Backup original Package.swift**

```bash
cd /Users/w/code/abundance-mvp
cp Package.swift Package.swift.backup
git add Package.swift.backup
git commit -m "chore: backup Package.swift before Xcode conversion"
```

Expected: Commit created with Package.swift.backup

**Step 5: Create Info.plist for app**

File: `/Users/w/code/abundance-mvp-xcode/Abundance/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>Abundance</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<true/>
	</dict>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UILaunchScreen</key>
	<dict/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>NSCameraUsageDescription</key>
	<string>Abundance needs camera access to capture and identify items in your household inventory.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Abundance needs photo library access to save captured item images.</string>
</dict>
</plist>
```

**Step 6: Create entitlements file**

File: `/Users/w/code/abundance-mvp-xcode/Abundance/Abundance.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:abundance-mvp.web.app</string>
	</array>
	<key>keychain-access-groups</key>
	<array>
		<string>$(AppIdentifierPrefix)com.abundance.mvp</string>
	</array>
</dict>
</plist>
```

---

## Task 2: Migrate Source Files to Xcode Project

**Files:**
- Copy: All files from `/Users/w/code/abundance-mvp/Sources/` → `/Users/w/code/abundance-mvp-xcode/Abundance/Sources/`
- Copy: All files from `/Users/w/code/abundance-mvp/App/` → `/Users/w/code/abundance-mvp-xcode/Abundance/`
- Copy: `/Users/w/code/abundance-mvp/App/Assets.xcassets` → `/Users/w/code/abundance-mvp-xcode/Abundance/Assets.xcassets`
- Copy: `/Users/w/code/abundance-mvp/App/GoogleService-Info.plist` → `/Users/w/code/abundance-mvp-xcode/Abundance/GoogleService-Info.plist`

**Step 1: Create directory structure**

```bash
cd /Users/w/code/abundance-mvp-xcode/Abundance
mkdir -p Sources/OnboardingFeature
mkdir -p Sources/CameraFeature
mkdir -p Sources/InventoryFeature
mkdir -p Sources/Persistence
mkdir -p Sources/VisionCore
```

Expected: Directories created

**Step 2: Copy all source files**

```bash
# Copy feature modules
cp -R /Users/w/code/abundance-mvp/Sources/OnboardingFeature/* /Users/w/code/abundance-mvp-xcode/Abundance/Sources/OnboardingFeature/
cp -R /Users/w/code/abundance-mvp/Sources/CameraFeature/* /Users/w/code/abundance-mvp-xcode/Abundance/Sources/CameraFeature/
cp -R /Users/w/code/abundance-mvp/Sources/InventoryFeature/* /Users/w/code/abundance-mvp-xcode/Abundance/Sources/InventoryFeature/
cp -R /Users/w/code/abundance-mvp/Sources/Persistence/* /Users/w/code/abundance-mvp-xcode/Abundance/Sources/Persistence/
cp -R /Users/w/code/abundance-mvp/Sources/VisionCore/* /Users/w/code/abundance-mvp-xcode/Abundance/Sources/VisionCore/

# Copy app files
cp /Users/w/code/abundance-mvp/App/*.swift /Users/w/code/abundance-mvp-xcode/Abundance/
```

Expected: All .swift files copied

**Step 3: Copy resources**

```bash
# Copy asset catalog
cp -R /Users/w/code/abundance-mvp/App/Assets.xcassets /Users/w/code/abundance-mvp-xcode/Abundance/

# Copy Firebase config
cp /Users/w/code/abundance-mvp/App/GoogleService-Info.plist /Users/w/code/abundance-mvp-xcode/Abundance/

# Copy Vision ML model
cp -R /Users/w/code/abundance-mvp/Sources/VisionCore/Resources/yolo11n.mlmodelc /Users/w/code/abundance-mvp-xcode/Abundance/Resources/
```

Expected: Resources copied

**Step 4: Verify file structure**

```bash
find /Users/w/code/abundance-mvp-xcode/Abundance -name "*.swift" | wc -l
```

Expected: ~70+ Swift files

**Step 5: Add files to Xcode project**

Manual steps in Xcode:
1. Right-click "Abundance" folder in Project Navigator
2. Add Files to "Abundance"
3. Select `Sources/` directory
4. Check "Create groups"
5. Check "Copy items if needed" (unchecked, already copied)
6. Target: Abundance
7. Click "Add"
8. Repeat for all .swift files in root Abundance/ directory
9. Add Assets.xcassets
10. Add GoogleService-Info.plist
11. Add Resources/yolo11n.mlmodelc

Expected: All files visible in Project Navigator

---

## Task 3: Configure Firebase Dependencies via Swift Package Manager

**Files:**
- Modify: `Abundance.xcodeproj/project.pbxproj` (via Xcode UI)

**Step 1: Add Firebase package dependency**

Manual steps in Xcode:
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Dependency Rule: "Up to Next Major Version" 11.11.0
4. Click "Add Package"

Expected: Package resolution begins

**Step 2: Select Firebase products**

When package resolves, select:
- FirebaseAuth
- FirebaseCore
- FirebaseFirestore
- FirebaseStorage

Target: Abundance

Click "Add Package"

Expected: Firebase frameworks added to project

**Step 3: Add swift-protobuf dependency**

Manual steps:
1. File → Add Package Dependencies
2. Enter URL: `https://github.com/apple/swift-protobuf.git`
3. Exact version: 1.28.2
4. Click "Add Package"
5. Select: SwiftProtobuf
6. Target: Abundance
7. Click "Add Package"

Expected: SwiftProtobuf added

**Step 4: Verify dependencies in project**

Check Project Navigator → Package Dependencies shows:
- firebase-ios-sdk
- swift-protobuf

Expected: Both packages listed

**Step 5: Build to verify dependencies**

```bash
cd /Users/w/code/abundance-mvp-xcode
xcodebuild -project Abundance.xcodeproj -scheme Abundance -destination 'generic/platform=iOS' clean build
```

Expected: Build may fail with import errors (expected), but dependencies resolve

---

## Task 4: Configure Build Settings and Capabilities

**Files:**
- Modify: Build Settings in Abundance.xcodeproj
- Modify: Signing & Capabilities

**Step 1: Set deployment target**

Manual steps in Xcode:
1. Select project "Abundance" in navigator
2. Select target "Abundance"
3. General tab
4. Minimum Deployments: iOS 18.0

Expected: iOS 18.0 set

**Step 2: Configure code signing**

Manual steps:
1. Signing & Capabilities tab
2. Team: Woodrow Pearson (NDAMNXP7RA)
3. Bundle Identifier: com.abundance.mvp
4. Signing Certificate: Apple Development
5. Provisioning Profile: Automatic

Expected: "Xcode managed profile" shown

**Step 3: Add capabilities**

Manual steps:
1. Click "+ Capability"
2. Add "Associated Domains"
   - Domains: `applinks:abundance-mvp.web.app`
3. Add "Keychain Sharing"
   - Keychain Groups: `com.abundance.mvp`

Expected: Entitlements file updated automatically

**Step 4: Configure Swift settings**

Manual steps:
1. Build Settings tab
2. Search "Swift Language Version"
3. Set to: Swift 6
4. Search "Strict Concurrency Checking"
5. Set to: Complete

Expected: Swift 6 strict concurrency enabled

**Step 5: Set asset catalog compiler options**

Build Settings:
1. Search "Asset Catalog Compiler"
2. App Icon Set Name: AppIcon
3. Generate App Icons: Yes

Expected: App icon settings configured

**Step 6: Build to verify settings**

```bash
xcodebuild -project Abundance.xcodeproj -scheme Abundance -destination 'generic/platform=iOS' build
```

Expected: Build progresses (may still have import issues to fix next)

---

## Task 5: Fix Import Statements and Module Access

**Files:**
- Modify: All Swift files with incorrect import paths

**Step 1: Remove SPM-specific imports**

Find and remove any imports like:
```swift
import Persistence
import OnboardingFeature
import CameraFeature
import InventoryFeature
import VisionCore
```

These are now part of the same module (Abundance app target).

Expected: Inter-module imports removed

**Step 2: Ensure public/internal access is correct**

Files in `Sources/*/` that need to be accessible:
- All types should remain `public` for now (already set for SPM)
- SwiftUI views should be `public struct`
- ViewModels should be `public class`
- Services should have `public protocol` and `public class`

No changes needed - SPM already requires `public`.

Expected: Access levels already correct

**Step 3: Verify Firebase imports**

All files using Firebase should have:
```swift
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
```

Check these files:
- `Sources/OnboardingFeature/AuthViewModel.swift`
- `Sources/Persistence/Firebase/*.swift`
- `AbundanceApp.swift`

Expected: Firebase imports present

**Step 4: Build to check for import errors**

```bash
xcodebuild -project Abundance.xcodeproj -scheme Abundance -destination 'generic/platform=iOS' build 2>&1 | grep "error:"
```

Expected: No import errors

**Step 5: Fix any remaining import issues**

If errors found, update imports following pattern:
- Firebase modules: Keep as-is
- SwiftUI: Keep `import SwiftUI`
- Foundation: Keep `import Foundation`
- Remove cross-module imports (OnboardingFeature, etc.)

Expected: All imports resolved

---

## Task 6: Configure App Store Distribution

**Files:**
- Create: Archive scheme
- Modify: Build settings for Release configuration

**Step 1: Create Archive scheme**

Manual steps in Xcode:
1. Product → Scheme → Edit Scheme
2. Archive action
3. Build Configuration: Release
4. Reveal Archive in Organizer: Checked

Expected: Archive scheme configured

**Step 2: Configure Release build settings**

Build Settings → Release:
1. Optimization Level: Optimize for Speed [-O]
2. Swift Compilation Mode: Whole Module
3. Enable Bitcode: No (deprecated)
4. Strip Debug Symbols During Copy: Yes
5. Strip Swift Symbols: Yes

Expected: Release optimization set

**Step 3: Set version and build number**

General tab:
1. Version: 1.0
2. Build: 1

Expected: Version set to 1.0 (1)

**Step 4: Verify archive builds**

```bash
xcodebuild -project Abundance.xcodeproj \
  -scheme Abundance \
  -configuration Release \
  -archivePath /tmp/Abundance.xcarchive \
  archive
```

Expected: Archive created at /tmp/Abundance.xcarchive

**Step 5: Check archive contents**

```bash
ls -la /tmp/Abundance.xcarchive/Products/Applications/
file /tmp/Abundance.xcarchive/Products/Applications/Abundance.app/Abundance
```

Expected: Abundance.app exists, executable is ARM64 Mach-O

---

## Task 7: Register App in App Store Connect

**Prerequisites:** Apple Developer Program membership active

**Manual Steps (cannot be automated):**

**Step 1: Log into App Store Connect**

Visit: https://appstoreconnect.apple.com
Login with: w@woodrowpearson.com (or your Apple ID)

**Step 2: Create new app**

1. Click "My Apps"
2. Click "+" → "New App"
3. Platforms: iOS
4. Name: Abundance
5. Primary Language: English (U.S.)
6. Bundle ID: Select "com.abundance.mvp" (or register new)
7. SKU: abundance-mvp-001
8. User Access: Full Access

Expected: App created in App Store Connect

**Step 3: Fill required metadata**

App Information:
- Privacy Policy URL: (provide URL or mark as coming soon)
- Category: Primary: Lifestyle, Secondary: Productivity
- Content Rights: No, it does not contain third-party content

Expected: Basic metadata saved

**Step 4: Configure TestFlight**

1. Click "TestFlight" tab
2. Internal Testing → Click "+"
3. Group Name: "Internal Testers"
4. Add testers: Your email
5. Click "Create"

Expected: Internal testing group created

**Step 5: Save app record**

Click "Save" in top right

Expected: App ready to receive builds

---

## Task 8: Upload Build to TestFlight

**Files:**
- Create: Exportable IPA from archive

**Step 1: Create archive from Xcode**

Manual steps:
1. Connect iPhone to verify signing works
2. Select "Any iOS Device (arm64)" as destination
3. Product → Archive
4. Wait for archive to complete

Expected: Organizer opens with new archive

**Step 2: Distribute app**

In Organizer:
1. Select the archive
2. Click "Distribute App"
3. Method: App Store Connect
4. Destination: Upload
5. Distribution Options:
   - Upload symbols: Yes
   - Manage Version and Build Number: Yes
6. Re-sign: Automatically manage signing
7. Click "Upload"

Expected: Upload begins

**Step 3: Monitor upload progress**

Watch progress bar in Xcode

Expected: "Upload Successful" message

**Step 4: Verify build in App Store Connect**

1. Visit https://appstoreconnect.apple.com
2. My Apps → Abundance
3. TestFlight tab
4. Builds section (wait 5-15 minutes for processing)

Expected: Build 1.0 (1) appears with "Processing" status

**Step 5: Wait for build to process**

Check email for "Your build has been processed" message

Typical wait time: 10-30 minutes

Expected: Email received, build shows "Ready to Test"

---

## Task 9: Enable TestFlight Beta Testing

**Manual Steps in App Store Connect:**

**Step 1: Add build to test group**

1. TestFlight tab
2. Internal Testing → "Internal Testers" group
3. Builds section → Click "+"
4. Select build 1.0 (1)
5. Click "Add Build"

Expected: Build added to group

**Step 2: Configure test information**

1. Test Information section
2. What to Test: "Initial MVP build for on-device testing. Auth flow, camera capture, inventory catalog with Firebase sync."
3. Click "Save"

Expected: Test notes saved

**Step 3: Add testers**

If not already added:
1. Testers & Groups
2. Internal Testing → "Internal Testers"
3. Click "+" next to Testers
4. Enter email address
5. Click "Add"

Expected: Tester added, receives email invite

**Step 4: Enable testing**

1. Verify tester has email
2. Tester clicks "View in TestFlight" in email
3. Opens TestFlight app on iOS device
4. Accept invite

Expected: App appears in TestFlight

**Step 5: Install beta app**

In TestFlight app:
1. Tap "Abundance"
2. Tap "Install"
3. Accept permissions

Expected: App installs on device

---

## Task 10: Verify TestFlight Installation

**Manual Steps on iPhone:**

**Step 1: Launch app from TestFlight**

1. Open TestFlight app
2. Tap "Abundance"
3. Tap "OPEN"

Expected: App launches

**Step 2: Test authentication flow**

1. Should see SignInView
2. Tap "Sign In Anonymously"
3. Wait for Firebase auth

Expected: Navigates to MainTabView

**Step 3: Test camera capture**

1. Tap "Camera" tab
2. Grant camera permission
3. Point at object
4. Tap capture button

Expected: Image captured and uploaded

**Step 4: Test inventory catalog**

1. Tap "Catalog" tab
2. Verify captured item appears
3. Tap item card
4. Verify ItemDetailView shows

Expected: Full flow works

**Step 5: Report issues in TestFlight**

If issues found:
1. Shake device
2. TestFlight prompts for feedback
3. Add screenshot/comment
4. Tap "Send"

Expected: Feedback sent to developer

---

## Post-Conversion Cleanup

**Step 1: Update repository structure**

```bash
cd /Users/w/code
mv abundance-mvp abundance-mvp-spm-backup
mv abundance-mvp-xcode abundance-mvp
cd abundance-mvp
git init
git add .
git commit -m "feat: convert to Xcode project for TestFlight distribution"
```

**Step 2: Update CLAUDE.md**

Update tech stack section:
```markdown
**Tech Stack:** Swift 6.0 (Xcode iOS App Project), TypeScript (Firebase Functions), Python (AI Pipeline)
**Architecture:** SwiftUI-only (ADR-010), MVVM, Firebase Backend
```

**Step 3: Update build documentation**

Create `docs/BUILD-AND-DEPLOY.md` with:
- Xcode build instructions
- TestFlight upload steps
- Version bump process

**Step 4: Archive SPM artifacts**

```bash
mkdir -p archive/spm-original
cp /Users/w/code/abundance-mvp-spm-backup/Package.swift archive/spm-original/
cp -R /Users/w/code/abundance-mvp-spm-backup/Tests archive/spm-original/
```

**Step 5: Document known issues**

Create `docs/KNOWN-ISSUES.md`:
- List any features that broke during conversion
- Note test coverage that needs restoration
- Firebase configuration gotchas

---

## Verification Checklist

- [ ] Xcode project builds without errors
- [ ] All Swift 6 strict concurrency checks pass
- [ ] Firebase SDK integrated correctly
- [ ] App icon displays in build
- [ ] GoogleService-Info.plist included
- [ ] YOLO model included in bundle
- [ ] Code signing configured (automatic)
- [ ] Archive builds successfully
- [ ] Upload to App Store Connect succeeds
- [ ] Build processes in App Store Connect
- [ ] TestFlight install works on physical device
- [ ] Auth flow functional
- [ ] Camera capture works
- [ ] Firestore sync works
- [ ] Item detail view displays correctly
- [ ] No crashes during basic usage

---

## Rollback Plan

If conversion fails:

```bash
cd /Users/w/code
rm -rf abundance-mvp
mv abundance-mvp-spm-backup abundance-mvp
cd abundance-mvp
# Continue using SPM with manual Xcode deployment (⌘R)
```

---

## Estimated Time

- Task 1-2: 30 minutes (project creation, file migration)
- Task 3-5: 45 minutes (dependencies, build settings, imports)
- Task 6: 20 minutes (distribution configuration)
- Task 7: 15 minutes (App Store Connect setup)
- Task 8-9: 30 minutes (upload, enable TestFlight)
- Task 10: 15 minutes (verification testing)

**Total: ~2.5-3 hours** (reduced from initial estimate due to SPM's existing proper module structure)

---

## Notes for Engineer

**Why this is necessary:**
- SPM creates executables, not .app bundles
- iOS requires .app bundle with proper structure for installation
- TestFlight requires App Store Connect integration
- Only Xcode projects support full distribution signing flow

**Key differences from SPM:**
- No more `public` imports between modules (same target now)
- Resources embedded in .app bundle, not separate bundles
- Single module instead of 6 separate SPM targets
- Build settings managed in Xcode UI, not Package.swift

**Testing strategy:**
- Manual testing on TestFlight (no unit tests in this plan)
- Original SPM tests can be migrated later if needed
- Focus on smoke testing critical paths first

**Common pitfalls:**
- Forgetting to add files to Xcode target
- Wrong bundle identifier vs Firebase config
- Provisioning profile mismatches (use Automatic)
- Missing camera permissions in Info.plist
- YOLO model not included in Copy Bundle Resources
