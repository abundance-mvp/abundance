# Apple Developer Documentation (Local Cache)

**Last Updated**: 2025-11-02
**Fetch Source**: [Sosumi.ai](https://sosumi.ai) - Clean markdown conversion of Apple Developer docs
**Purpose**: Fast, accurate local reference for iOS stage development

## Technology Coverage

### Core iOS Development
- ✅ Swift 6.x Language Documentation + Apple Intelligence + Foundation Models
- ✅ SwiftUI Framework + App Design + Interface Fundamentals
- ✅ Foundation (Core Data Types, Formatting)
- ✅ Combine (Reactive Programming)

### Vision & AI
- ✅ Vision Framework (Object Detection, Image Analysis)
- ✅ Visual Intelligence (iOS 26 AI Features)
- ✅ Core ML (Machine Learning Models)
- ✅ Metal (Neural Engine Optimization)
- ✅ Accelerate (Performance & BNNS)

### User Interface
- ✅ Liquid Glass Design System (iOS 26 UI/UX)
- ✅ UIKit (Legacy UI Components)
- ✅ VisionKit (Barcode/Document Scanning)
- ✅ Link Presentation (Rich Link Previews)

### Media & Camera
- ✅ AVFoundation (Camera APIs)
- ✅ PhotoKit (Photo Library Access)
- ✅ Image I/O (Advanced Image Processing)

### Authentication & Security
- ✅ Sign in with Apple / Keychain (Authentication)
- ✅ Local Authentication (Face ID / Touch ID)
- ✅ Security APIs (Secure Enclave, Data Protection)
- ✅ App Tracking Transparency (Privacy)

### Data & Storage
- ✅ Core Data / CloudKit / SwiftData (Storage + Data Management)
- ✅ Observation (Modern State Management)

### Networking
- ✅ Network Framework (Modern Networking APIs)
- ✅ Combine (Async Data Streams)

### Notifications & Engagement
- ✅ User Notifications (Local & Remote Push)
- ✅ User Notifications UI (Custom Notification UI)

### Commerce
- ✅ StoreKit / Apple Pay (Payment APIs)

### Content Safety
- ✅ Sensitive Content Analysis (Content Moderation)

### Location & Maps
- ✅ MapKit (Maps, Directions, Location)

### Testing
- ✅ XCTest (Unit & UI Testing)
- ✅ Swift Testing (Modern Testing Framework)

## Documentation Statistics

**Total Documents**: 44 across 23 technology areas

| Technology | Documents | Key Features |
|-----------|-----------|--------------|
| Swift (+ AI/ML + Core ML + Metal) | 5 | Language, ML Models, GPU |
| SwiftUI (+ Design + UIKit) | 5 | Declarative UI, Legacy UI |
| Vision | 1 | Object Detection, Image Analysis |
| Visual Intelligence | 1 | iOS 26 AI Features |
| Liquid Glass | 2 | iOS 26 Design System |
| Payment (StoreKit + Apple Pay) | 2 | In-App Purchases, Payments |
| Authentication | 2 | Sign in with Apple, Keychain |
| Storage (Core Data + CloudKit) | 6 | Data Persistence, Cloud Sync |
| Camera (AVFoundation + PhotoKit) | 2 | Media Capture, Photo Library |
| Security | 1 | Encryption, Data Protection |
| Notifications | 2 | Push Notifications, Custom UI |
| Testing | 2 | XCTest, Swift Testing |
| Scanning (VisionKit) | 1 | Barcode/Document Scanning |
| Content Safety | 1 | Sensitive Content Detection |
| Biometrics | 1 | Face ID, Touch ID |
| Networking | 2 | Network Framework, Combine |
| Foundation | 1 | Core Data Types |
| Maps | 1 | MapKit Mapping & Directions |
| Privacy | 1 | App Tracking Transparency |
| Observation | 1 | Modern State Management |
| Sharing | 1 | Link Presentation |
| Image Processing | 1 | Image I/O |
| Performance | 1 | Accelerate Framework |

## Refresh Documentation

### When to Refresh

Documentation is considered stale after **30 days**. The stage orchestrator will warn (but not block) if docs are older than 30 days.

### How to Refresh

**Option 1: Full Refresh (Recommended)**
```bash
/apple-docs-fetcher --refresh
```

**Option 2: Manual Refresh**
```bash
rm -rf docs/apple/
/apple-docs-fetcher
```

## Usage

These docs are automatically searched by the `verified-stage-development` skill when running iOS-related stages (2.2, 3.1, 4.1). The research verification agent uses `Grep` to search local markdown files instead of `WebFetch`, providing:

- ✅ Faster searches (local files vs. web requests)
- ✅ More accurate results (clean markdown vs. HTML parsing)
- ✅ Offline capability
- ✅ Cost savings (no repeated web fetches)

## Structure

Each technology has its own directory with:
- `manifest.json` - Metadata about fetched docs
- `*.md` - Markdown documentation files

The orchestrator skill knows to search these directories when verifying iOS/Swift technical claims.

## Available Technologies

### swift/
Swift 6.x standard library, language features, Core ML, Metal, and Apple Intelligence.

### swiftui/
Declarative UI framework for iOS with app design, interface fundamentals, and UIKit integration.

### foundation/
Core data types, decimal arithmetic, formatting, and fundamental utilities.

### vision/
Computer vision capabilities including image classification and object detection.

### visual-intelligence/
iOS 26 semantic content analysis and visual intelligence features.

### scanning/
VisionKit for barcode scanning, document scanning, and text recognition.

### payment/
In-app purchases (StoreKit) and payment processing (Apple Pay).

### auth/
Authentication services including Sign in with Apple, passkeys, and Keychain Services.

### biometrics/
Local Authentication framework for Face ID, Touch ID, and device passcode.

### storage/
Data persistence with Core Data (local) and CloudKit (cloud sync).

### camera/
AVFoundation and PhotoKit for media capture, processing, and photo library access.

### security/
Security framework for data protection, encryption, and secure storage.

### content-safety/
Sensitive Content Analysis for detecting and moderating sensitive media content.

### liquid-glass/
iOS 26 design system with dynamic materials, adoption guide, and implementation best practices.

### notifications/
User Notifications framework for local and remote push notifications with custom UI.

### networking/
Network framework for modern networking APIs and Combine for reactive data streams.

### maps/
MapKit for embedding maps, directions, location search, and street-level viewing.

### privacy/
App Tracking Transparency for user permission before cross-app tracking.

### observation/
Modern state management with @Observable macro and ObservationRegistrar.

### sharing/
Link Presentation framework for rich link previews with metadata.

### image-processing/
Image I/O framework for advanced image reading, writing, and metadata management.

### performance/
Accelerate framework with neural network capabilities and performance optimizations.

### testing/
XCTest for comprehensive testing and Swift Testing for modern test development.

## Notes

- Documentation fetched from sosumi.ai, which provides clean markdown conversions
- All rights belong to Apple Inc.
- This is unofficial documentation for development reference
- For official documentation, visit [developer.apple.com](https://developer.apple.com)
