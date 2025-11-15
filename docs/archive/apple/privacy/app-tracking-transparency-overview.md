# App Tracking Transparency Overview
**Source**: https://sosumi.ai/documentation/apptrackingtransparency
**Fetched**: 2025-11-02
## Overview
Apple's App Tracking Transparency (ATT) framework enables apps to request user permission before tracking their activity across other apps and websites.
## Key Components
Apps must include `NSUserTrackingUsageDescription` key in Info.plist. The `ATTrackingManager` class manages all tracking authorization functionality.
## Authorization Status States
- **authorized**: User granted tracking permission
- **denied**: User explicitly rejected tracking
- **notDetermined**: User hasn't yet responded
- **restricted**: Device-level restrictions prevent tracking
---
*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
