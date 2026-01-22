# Abundance iOS - Developer Setup Guide

**Created**: 2025-11-11
**Stage**: 4.1 - iOS Project Scaffolding
**Target**: New developers joining the Abundance iOS project
**Goal**: Get app building and running within 10 minutes

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

| Tool | Version | Installation | Verification |
|------|---------|--------------|--------------|
| **macOS** | 15.0+ (Sequoia) | [Apple](https://www.apple.com/macos/) | `sw_vers` |
| **Xcode** | 16.2+ | [App Store](https://apps.apple.com/us/app/xcode/id497799835) | `xcodebuild -version` |
| **Homebrew** | Latest | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` | `brew --version` |
| **SwiftLint** | 0.62.2+ | `brew install swiftlint` | `swiftlint version` |
| **Sourcery** | 2.3.0+ | `brew install sourcery` | `sourcery --version` |
| **Firebase CLI** | 13.0+ | `npm install -g firebase-tools` | `firebase --version` |

### Minimum Device Requirements

- **iPhone**: iPhone 15 Pro or later (iOS 26.0+)
- **iPad**: iPad Pro 2024 or later (iOS 26.0+)
- **Simulator**: iPhone 16 Pro simulator (included with Xcode 16.2+)

### Firebase Account

- Access to the Abundance Firebase project (request from team lead)
- Ability to download `GoogleService-Info.plist` from Firebase Console

---

## Quick Start (10 Minutes)

### Step 1: Clone Repository (1 min)

```bash
# Clone the repository
git clone <REPOSITORY_URL>
cd Abundance

# Verify you're on the main branch
git status
```

### Step 2: Install Tools (2 min)

```bash
# Install SwiftLint
brew install swiftlint

# Install Sourcery
brew install sourcery

# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Verify installations
swiftlint version   # Should show 0.62.2 or higher
sourcery --version  # Should show 2.3.0 or higher
firebase --version  # Should show 13.0 or higher
```

### Step 3: Configure Firebase (3 min)

#### Download GoogleService-Info.plist

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select **Abundance-Dev** project (for development)
3. Go to **Project Settings** → **General** → **Your apps**
4. Download `GoogleService-Info.plist` (iOS app configuration)

#### Add to Xcode Project

```bash
# Copy GoogleService-Info.plist to App/ directory
cp ~/Downloads/GoogleService-Info.plist App/GoogleService-Info.plist

# Verify file exists
ls -la App/GoogleService-Info.plist
```

**IMPORTANT**: Never commit `GoogleService-Info.plist` to Git. It's already in `.gitignore`.

### Step 4: Generate Code (1 min)

```bash
# Generate mocks with Sourcery
sourcery --config Sourcery.yml

# Run SwiftLint to verify code quality
swiftlint
```

**Expected Output**:
```
Sourcery: Generated MockCatalogRepository.swift
SwiftLint: Done linting! Found 0 violations in X files.
```

### Step 5: Open Project in Xcode (1 min)

```bash
# Open Xcode project
open Abundance.xcodeproj
```

**In Xcode**:
1. Wait for Swift Package Manager to resolve dependencies (~30 seconds)
2. Select **iPhone 16 Pro** simulator (Product → Destination → iPhone 16 Pro)
3. Select **Abundance** scheme (top bar, left of device selector)

### Step 6: Build and Run (2 min)

```bash
# Option 1: Build from command line
xcodebuild -scheme Abundance -destination 'platform=iOS Simulator,name=iPhone 16 Pro' clean build

# Option 2: Build in Xcode (recommended)
# Press Cmd+R or click the Play button
```

**Expected Result**:
- Build succeeds without errors
- Simulator launches with Abundance app
- App shows onboarding screen (or sign-in screen if onboarding not implemented yet)

**If Build Fails**: See [Troubleshooting](#troubleshooting) section below.

---

## Project Structure Overview

```
Abundance/
├── Abundance.xcodeproj/    # Xcode project
├── App/                    # Main app target
│   ├── AbundanceApp.swift  # Entry point
│   ├── ContentView.swift   # Root view (tab bar)
│   ├── GoogleService-Info.plist  # Firebase config (NOT in Git)
│   └── Info.plist          # App permissions, capabilities
├── Packages/               # Local Swift packages
│   ├── Features/           # UI features (Catalog, Camera, Profile)
│   ├── Core/               # Services (Firebase, Networking, Vision)
│   └── Shared/             # Utilities (Components, Extensions)
├── Tests/                  # Integration and UI tests
├── .swiftlint.yml          # Linting rules
├── Sourcery.yml            # Code generation config
└── Generated/              # Auto-generated mocks
```

**Key Files**:
- `Package.swift` (root): Swift Package Manager manifest
- `.swiftlint.yml`: Code quality rules (120 char line length, Swift 6 strict)
- `Sourcery.yml`: Mock generation config (AutoMockable protocol)

---

## Development Workflow

### Daily Development

```bash
# 1. Pull latest changes
git pull origin main

# 2. Resolve Swift package dependencies (if needed)
swift package resolve

# 3. Generate mocks (if protocols changed)
sourcery --config Sourcery.yml

# 4. Run linter
swiftlint

# 5. Build and test
xcodebuild -scheme Abundance -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

### Creating a New Feature

See [Module-Scaffold-Structure.md](./Module-Scaffold-Structure.md) for templates.

**Quick Steps**:
1. Create new directory in `Packages/Features/{FeatureName}/`
2. Add `Package.swift` (use Feature template from Module-Scaffold-Structure.md)
3. Add to root `Package.swift` products and targets
4. Run `swift package resolve`
5. Implement feature (Views + ViewModels + tests)

### Running Tests

```bash
# Run all tests
xcodebuild -scheme Abundance -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test

# Run specific test target
xcodebuild -scheme AbundanceTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test

# Run tests in Xcode
# Cmd+U or Product → Test
```

### Code Generation

```bash
# Generate mocks from protocols annotated with `// sourcery: AutoMockable`
sourcery --config Sourcery.yml

# Watch mode (auto-regenerate on file changes)
sourcery --config Sourcery.yml --watch
```

---

## Environment Configurations

The project supports three environments:

| Environment | Firebase Project | Use Case |
|-------------|------------------|----------|
| **Debug** | abundance-dev | Local development, debugging |
| **Staging** | abundance-staging | TestFlight beta testing |
| **Release** | abundance-prod | App Store production |

### Switching Environments

**In Xcode**:
1. Product → Scheme → Edit Scheme...
2. Run → Build Configuration → Select **Debug**, **Staging**, or **Release**
3. Build and run (Firebase project ID will change automatically)

**GoogleService-Info.plist Files**:
- `GoogleService-Info-Dev.plist` → Debug
- `GoogleService-Info-Staging.plist` → Staging
- `GoogleService-Info-Prod.plist` → Release

See [iOS-Environment-Configs.md](./iOS-Environment-Configs.md) for `.xcconfig` setup.

---

## Troubleshooting

### Issue 1: "Cannot find 'FirebaseApp' in scope"

**Cause**: `GoogleService-Info.plist` not added to Xcode project.

**Solution**:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Drag file into `App/` folder in Xcode (left sidebar)
3. Ensure "Copy items if needed" is checked
4. Ensure "Abundance" target is selected
5. Clean build folder (Cmd+Shift+K) and rebuild (Cmd+B)

### Issue 2: Swift 6 Concurrency Warnings

**Cause**: Code not using correct `.enableUpcomingFeature("StrictConcurrency")` syntax.

**Solution**:
- All `Package.swift` files should use `.enableUpcomingFeature("StrictConcurrency")`
- **NOT** `.enableExperimentalFeature("StrictConcurrency")` (Swift 5.x syntax, deprecated)
- See `docs/validation/RESEARCH-VALIDATION-stage-4.1.md` for details

### Issue 3: "Sourcery not found"

**Cause**: Sourcery not installed or not in PATH.

**Solution**:
```bash
# Install Sourcery via Homebrew
brew install sourcery

# Verify installation
sourcery --version

# If still not found, add to PATH
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Issue 4: SwiftLint Warnings Overload

**Cause**: SwiftLint rules too strict or code not formatted.

**Solution**:
```bash
# Auto-fix violations
swiftlint --fix

# Check configuration
cat .swiftlint.yml

# Disable specific rules in .swiftlint.yml if needed
# (Edit disabled_rules section)
```

### Issue 5: Firebase `@preconcurrency` Warnings

**Cause**: Firebase iOS SDK 11.x has partial Swift 6 support.

**Expected Behavior**: Warnings (not errors), app still compiles.

**Workaround** (already applied):
```swift
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseStorage
```

**Timeline**: Full Swift 6 support in Firebase SDK 12.x (expected Q1 2026).

### Issue 6: "No such module 'CatalogFeature'"

**Cause**: Swift Package Manager didn't resolve dependencies.

**Solution**:
```bash
# Resolve dependencies manually
swift package resolve

# Clean and rebuild
rm -rf .build/
swift build

# In Xcode: File → Packages → Reset Package Caches
```

### Issue 7: Simulator Not Launching

**Cause**: iOS 26 simulator not installed.

**Solution**:
1. Xcode → Settings → Platforms
2. Download **iOS 26.0 Simulator**
3. Select **iPhone 16 Pro (iOS 26.0)** as destination
4. Build and run

### Issue 8: "Building for iOS, but the linked framework was built for iOS Simulator"

**Cause**: Running on physical device with simulator builds.

**Solution**:
1. Clean build folder (Cmd+Shift+K)
2. Select physical device as destination (not simulator)
3. Rebuild (Cmd+B)

---

## Xcode Build Schemes

### Abundance (Debug)
- **Configuration**: Debug
- **Firebase**: abundance-dev
- **Logging**: Verbose (os_log enabled)
- **Optimizations**: None (fast compile, slow runtime)
- **Use For**: Local development, debugging

### Abundance (Staging)
- **Configuration**: Staging
- **Firebase**: abundance-staging
- **Logging**: Normal
- **Optimizations**: Size (-Osize)
- **Use For**: TestFlight beta builds

### Abundance (Release)
- **Configuration**: Release
- **Firebase**: abundance-prod
- **Logging**: Minimal (errors only)
- **Optimizations**: Speed (-O)
- **Use For**: App Store production builds

---

## Additional Resources

### Documentation
- [Project Structure](./AbundanceApp-Project-Structure.md)
- [Module Scaffold Templates](./Module-Scaffold-Structure.md)
- [Environment Configs](./iOS-Environment-Configs.md)
- [Research Validation](../validation/RESEARCH-VALIDATION-stage-4.1.md)

### Architecture Decision Records
- [ADR-010: MVVM Architecture](../adr/ADR-010-swiftui-architecture-pattern.md)
- [ADR-011: Modular Packages](../adr/ADR-011-ios-module-structure.md)
- [ADR-012: State Management](../adr/ADR-012-state-management-strategy.md)
- [ADR-013: Dependency Injection](../adr/ADR-013-dependency-injection-strategy.md)

### Code Examples
- [Swift 6 Concurrency Patterns](../design/CODE-EXAMPLE-001-swift6-concurrency-patterns.md)
- [Catalog MVVM Implementation](../design/CODE-EXAMPLE-002-catalog-mvvm-implementation.md)
- [Firebase iOS Integration](../design/CODE-EXAMPLE-003-firebase-ios-integration.md)

### External Links
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift 6 Migration Guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)

---

## Getting Help

### Team Communication
- **Slack**: #abundance-ios (technical questions)
- **GitHub Issues**: Bug reports, feature requests
- **Code Reviews**: Pull request reviews (mandatory before merge)

### Escalation Path
1. Check documentation (this README, ADRs, CODE-EXAMPLES)
2. Search GitHub issues (existing/closed)
3. Ask in #abundance-ios Slack channel
4. Create GitHub issue if problem persists

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial iOS setup guide | iOS Architecture Expert |

---

**Status**: ✅ **Production-Ready**

Complete developer onboarding guide for Abundance iOS project. Follow steps to get building within 10 minutes.
