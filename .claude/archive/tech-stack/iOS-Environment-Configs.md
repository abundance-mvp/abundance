# iOS Environment Configurations (.xcconfig)

**Created**: 2025-11-11
**Stage**: 4.1 - iOS Project Scaffolding
**References**:
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Firebase projects)
- docs/validation/RESEARCH-VALIDATION-stage-4.1.md (.xcconfig format verified)
**Status**: Production-Ready

---

## Overview

This document specifies `.xcconfig` files for managing build configurations across Debug, Staging, and Release environments. Each environment connects to a different Firebase project and has different optimization settings.

**Purpose**:
- Separate Firebase projects (Dev/Staging/Prod) without code changes
- Environment-specific build settings (logging, optimizations)
- Secure API key management (never commit secrets to Git)

---

## Environment Summary

| Environment | Firebase Project | Use Case | Optimizations |
|-------------|------------------|----------|---------------|
| **Debug** | `abundance-dev` | Local development, debugging | None (`-Onone`) |
| **Staging** | `abundance-staging` | TestFlight beta testing | Size (`-Osize`) |
| **Release** | `abundance-prod` | App Store production | Speed (`-O`) |

---

## Debug.xcconfig

**Location**: `Configurations/Debug.xcconfig`

**Purpose**: Development environment with verbose logging and no optimizations for fast iteration.

```xcconfig
// Debug.xcconfig
// Abundance iOS App - Debug Configuration
// Created: 2025-11-11
// Firebase Project: abundance-dev

// MARK: - Build Settings

// Swift Compilation Mode (no optimizations for faster builds)
SWIFT_OPTIMIZATION_LEVEL = -Onone

// Swift Compilation Conditions (DEBUG flag for conditional compilation)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) DEBUG

// Swift Strict Concurrency Checking
SWIFT_STRICT_CONCURRENCY = complete

// MARK: - Firebase Configuration

// Firebase Project ID (Dev)
FIREBASE_PROJECT_ID = abundance-dev

// Firebase App ID (replace with actual from GoogleService-Info-Dev.plist)
FIREBASE_APP_ID = 1:123456789:ios:abcdef123456

// Firebase API Key (replace with actual from GoogleService-Info-Dev.plist)
FIREBASE_API_KEY = AIzaSyC-REPLACE-WITH-ACTUAL-KEY

// MARK: - App Identification

// Bundle Identifier (Dev)
PRODUCT_BUNDLE_IDENTIFIER = com.abundance.app.dev

// App Name (shows in Xcode and device home screen)
PRODUCT_NAME = Abundance Dev

// Marketing Version (display version)
MARKETING_VERSION = 1.0.0

// Build Number (increment for each build)
CURRENT_PROJECT_VERSION = 1

// MARK: - Code Signing

// Code Signing Style (Automatic for development)
CODE_SIGN_STYLE = Automatic

// Development Team (replace with your Apple Developer Team ID)
DEVELOPMENT_TEAM = YOUR_TEAM_ID

// Provisioning Profile (Automatic for Debug)
PROVISIONING_PROFILE_SPECIFIER =

// MARK: - Build Options

// Enable Testability (allows unit tests to access internal types)
ENABLE_TESTABILITY = YES

// Debug Information Format
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym

// Deployment Target
IPHONEOS_DEPLOYMENT_TARGET = 26.0

// Supported Platforms
SUPPORTED_PLATFORMS = iphoneos iphonesimulator

// MARK: - Logging & Debugging

// Enable OS Activity Mode (verbose logging)
OS_ACTIVITY_MODE = enable

// Enable Address Sanitizer (detect memory issues)
ENABLE_ADDRESS_SANITIZER = NO

// Enable Thread Sanitizer (detect threading issues)
ENABLE_THREAD_SANITIZER = NO

// Enable Undefined Behavior Sanitizer
ENABLE_UNDEFINED_BEHAVIOR_SANITIZER = NO
```

**Usage**:
```bash
# Build with Debug configuration
xcodebuild -scheme Abundance -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

---

## Staging.xcconfig

**Location**: `Configurations/Staging.xcconfig`

**Purpose**: TestFlight beta testing with size optimizations and normal logging.

```xcconfig
// Staging.xcconfig
// Abundance iOS App - Staging Configuration
// Created: 2025-11-11
// Firebase Project: abundance-staging

// MARK: - Build Settings

// Swift Compilation Mode (optimize for size)
SWIFT_OPTIMIZATION_LEVEL = -Osize

// Swift Compilation Conditions (STAGING flag)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) STAGING

// Swift Strict Concurrency Checking
SWIFT_STRICT_CONCURRENCY = complete

// MARK: - Firebase Configuration

// Firebase Project ID (Staging)
FIREBASE_PROJECT_ID = abundance-staging

// Firebase App ID (replace with actual from GoogleService-Info-Staging.plist)
FIREBASE_APP_ID = 1:987654321:ios:fedcba654321

// Firebase API Key (replace with actual from GoogleService-Info-Staging.plist)
FIREBASE_API_KEY = AIzaSyC-REPLACE-WITH-ACTUAL-STAGING-KEY

// MARK: - App Identification

// Bundle Identifier (Staging)
PRODUCT_BUNDLE_IDENTIFIER = com.abundance.app.staging

// App Name (shows as "Abundance β" on device)
PRODUCT_NAME = Abundance β

// Marketing Version
MARKETING_VERSION = 1.0.0

// Build Number (auto-increment for TestFlight)
CURRENT_PROJECT_VERSION = 1

// MARK: - Code Signing

// Code Signing Style (Automatic or Manual for distribution)
CODE_SIGN_STYLE = Automatic

// Development Team
DEVELOPMENT_TEAM = YOUR_TEAM_ID

// Provisioning Profile (TestFlight/Ad Hoc)
PROVISIONING_PROFILE_SPECIFIER =

// MARK: - Build Options

// Disable Testability (production-like build)
ENABLE_TESTABILITY = NO

// Debug Information Format (for crash symbolication)
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym

// Deployment Target
IPHONEOS_DEPLOYMENT_TARGET = 26.0

// Supported Platforms
SUPPORTED_PLATFORMS = iphoneos

// MARK: - Logging & Debugging

// Normal logging (not verbose)
OS_ACTIVITY_MODE = default

// Disable sanitizers (performance impact)
ENABLE_ADDRESS_SANITIZER = NO
ENABLE_THREAD_SANITIZER = NO
ENABLE_UNDEFINED_BEHAVIOR_SANITIZER = NO

// MARK: - Distribution

// Strip debug symbols (reduce app size)
STRIP_INSTALLED_PRODUCT = YES

// Dead code stripping
DEAD_CODE_STRIPPING = YES
```

**Usage**:
```bash
# Archive for TestFlight
xcodebuild -scheme Abundance -configuration Staging -archivePath Abundance.xcarchive archive
```

---

## Release.xcconfig

**Location**: `Configurations/Release.xcconfig`

**Purpose**: App Store production with speed optimizations and minimal logging.

```xcconfig
// Release.xcconfig
// Abundance iOS App - Release Configuration
// Created: 2025-11-11
// Firebase Project: abundance-prod

// MARK: - Build Settings

// Swift Compilation Mode (optimize for speed)
SWIFT_OPTIMIZATION_LEVEL = -O

// Swift Compilation Conditions (RELEASE flag)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) RELEASE

// Swift Strict Concurrency Checking
SWIFT_STRICT_CONCURRENCY = complete

// MARK: - Firebase Configuration

// Firebase Project ID (Production)
FIREBASE_PROJECT_ID = abundance-prod

// Firebase App ID (replace with actual from GoogleService-Info-Prod.plist)
FIREBASE_APP_ID = 1:111222333:ios:aabbccdd1122

// Firebase API Key (replace with actual from GoogleService-Info-Prod.plist)
FIREBASE_API_KEY = AIzaSyC-REPLACE-WITH-ACTUAL-PROD-KEY

// MARK: - App Identification

// Bundle Identifier (Production)
PRODUCT_BUNDLE_IDENTIFIER = com.abundance.app

// App Name (shows as "Abundance" on device)
PRODUCT_NAME = Abundance

// Marketing Version (user-facing version)
MARKETING_VERSION = 1.0.0

// Build Number (App Store Connect version)
CURRENT_PROJECT_VERSION = 1

// MARK: - Code Signing

// Code Signing Style (Automatic or Manual for App Store)
CODE_SIGN_STYLE = Automatic

// Development Team
DEVELOPMENT_TEAM = YOUR_TEAM_ID

// Provisioning Profile (App Store)
PROVISIONING_PROFILE_SPECIFIER =

// MARK: - Build Options

// Disable Testability (security)
ENABLE_TESTABILITY = NO

// Debug Information Format
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym

// Deployment Target
IPHONEOS_DEPLOYMENT_TARGET = 26.0

// Supported Platforms (iOS devices only, no simulator)
SUPPORTED_PLATFORMS = iphoneos

// MARK: - Logging & Debugging

// Minimal logging (errors only)
OS_ACTIVITY_MODE = disable

// Disable all sanitizers (performance)
ENABLE_ADDRESS_SANITIZER = NO
ENABLE_THREAD_SANITIZER = NO
ENABLE_UNDEFINED_BEHAVIOR_SANITIZER = NO

// MARK: - Distribution

// Strip debug symbols
STRIP_INSTALLED_PRODUCT = YES

// Dead code stripping
DEAD_CODE_STRIPPING = YES

// Bitcode (deprecated in Xcode 14+, but kept for reference)
ENABLE_BITCODE = NO

// App Thinning (automatic for App Store)
ENABLE_APP_SLICING = YES
```

**Usage**:
```bash
# Archive for App Store
xcodebuild -scheme Abundance -configuration Release -archivePath Abundance.xcarchive archive
```

---

## Setup Instructions

### Step 1: Create Configurations Directory

```bash
mkdir -p Configurations
```

### Step 2: Create .xcconfig Files

Create three files in `Configurations/`:
- `Debug.xcconfig`
- `Staging.xcconfig`
- `Release.xcconfig`

Copy the contents from the templates above.

### Step 3: Replace Placeholders

**In each .xcconfig file**, replace:
- `YOUR_TEAM_ID` → Your Apple Developer Team ID (found in Apple Developer Account)
- `FIREBASE_APP_ID` → Actual app ID from `GoogleService-Info.plist`
- `FIREBASE_API_KEY` → Actual API key from `GoogleService-Info.plist`

**IMPORTANT**: Never commit real API keys to Git. Use environment variables or Xcode User-Defined Settings.

### Step 4: Add to Xcode Project

1. Open `Abundance.xcodeproj` in Xcode
2. Select project in left sidebar
3. Select `Abundance` target
4. Go to **Info** tab
5. Under **Configurations**, set:
   - **Debug** → `Debug.xcconfig`
   - **Staging** → `Staging.xcconfig`
   - **Release** → `Release.xcconfig`

### Step 5: Add GoogleService-Info.plist Files

Create three versions of `GoogleService-Info.plist`:
- `App/GoogleService-Info-Dev.plist` (from Firebase abundance-dev)
- `App/GoogleService-Info-Staging.plist` (from Firebase abundance-staging)
- `App/GoogleService-Info-Prod.plist` (from Firebase abundance-prod)

**Add Run Script Phase** (in Xcode Build Phases):
```bash
# Copy correct GoogleService-Info.plist based on configuration
if [ "${CONFIGURATION}" == "Debug" ]; then
    cp "${PROJECT_DIR}/App/GoogleService-Info-Dev.plist" "${PROJECT_DIR}/App/GoogleService-Info.plist"
elif [ "${CONFIGURATION}" == "Staging" ]; then
    cp "${PROJECT_DIR}/App/GoogleService-Info-Staging.plist" "${PROJECT_DIR}/App/GoogleService-Info.plist"
elif [ "${CONFIGURATION}" == "Release" ]; then
    cp "${PROJECT_DIR}/App/GoogleService-Info-Prod.plist" "${PROJECT_DIR}/App/GoogleService-Info.plist"
fi
```

### Step 6: Update .gitignore

```gitignore
# Firebase configuration files (contains secrets)
App/GoogleService-Info.plist
App/GoogleService-Info-*.plist

# .xcconfig files (contains API keys)
Configurations/*.xcconfig

# Keep template files
!Configurations/*.xcconfig.template
```

---

## Switching Environments in Xcode

### Method 1: Edit Scheme (Recommended)

1. Product → Scheme → Edit Scheme... (Cmd+<)
2. Run (left sidebar)
3. Build Configuration dropdown
4. Select **Debug**, **Staging**, or **Release**
5. Close
6. Build and run (Cmd+R)

### Method 2: Duplicate Schemes

Create separate schemes for each environment:

1. Product → Scheme → Manage Schemes...
2. Duplicate "Abundance" scheme
3. Rename to "Abundance Debug", "Abundance Staging", "Abundance Release"
4. Set default configuration for each scheme
5. Select scheme from dropdown in Xcode toolbar

---

## Conditional Compilation

Use `#if` directives to execute different code per environment:

```swift
import Foundation

func getAPIBaseURL() -> String {
    #if DEBUG
    return "https://api-dev.abundance.com"
    #elseif STAGING
    return "https://api-staging.abundance.com"
    #else
    return "https://api.abundance.com"
    #endif
}

func logLevel() -> LogLevel {
    #if DEBUG
    return .verbose
    #elseif STAGING
    return .normal
    #else
    return .minimal
    #endif
}
```

**Accessing Build Configuration at Runtime**:
```swift
#if DEBUG
let isDebug = true
#else
let isDebug = false
#endif

print("Running in \(isDebug ? "Debug" : "Production") mode")
```

---

## Security Best Practices

### Never Commit Secrets to Git

❌ **DON'T**:
- Commit real API keys in `.xcconfig` files
- Commit `GoogleService-Info.plist` with real Firebase config
- Hard-code secrets in source code

✅ **DO**:
- Use `.xcconfig.template` files with placeholders
- Store real `.xcconfig` files locally only
- Use Xcode User-Defined Settings for CI/CD
- Store secrets in Keychain or environment variables

### CI/CD Secret Management

For GitHub Actions or other CI/CD:
```yaml
# .github/workflows/build.yml
- name: Create Firebase Config
  env:
    FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
  run: |
    echo "FIREBASE_API_KEY=${FIREBASE_API_KEY}" > Configurations/Release.xcconfig
```

---

## Troubleshooting

### Issue: "FIREBASE_PROJECT_ID not found"

**Cause**: `.xcconfig` file not linked to Xcode project.

**Solution**:
1. Xcode → Project Settings → Configurations
2. Set configuration file for each build configuration
3. Clean build folder (Cmd+Shift+K)
4. Rebuild

### Issue: Wrong Firebase Project Connected

**Cause**: Incorrect `GoogleService-Info.plist` file used.

**Solution**:
1. Check Run Script Phase is copying correct file
2. Verify `FIREBASE_PROJECT_ID` in `.xcconfig` matches Firebase Console
3. Delete app from simulator/device and reinstall

### Issue: "Code signing failed"

**Cause**: `DEVELOPMENT_TEAM` not set or incorrect.

**Solution**:
1. Open `.xcconfig` file
2. Replace `YOUR_TEAM_ID` with actual Team ID from Apple Developer Account
3. Or set in Xcode: Project Settings → Signing & Capabilities → Team

---

## References

### Technology Stack
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md (Firebase projects)

### Validation
- docs/validation/RESEARCH-VALIDATION-stage-4.1.md (.xcconfig format verified for Xcode 16)

### Related Documents
- docs/tech-stack/README-iOS-Setup.md (Developer setup)
- docs/tech-stack/AbundanceApp-Project-Structure.md (Project structure)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial .xcconfig specification for Debug/Staging/Release | iOS Architecture Expert |

---

**Status**: ✅ **Production-Ready**

Complete .xcconfig templates for managing Debug, Staging, and Release environments with Firebase project separation and build optimization.
