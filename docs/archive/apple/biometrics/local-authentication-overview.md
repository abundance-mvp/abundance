# Local Authentication Framework Overview

**Source**: https://sosumi.ai/documentation/localauthentication
**Fetched**: 2025-11-02

## Core Functionality

Apple's Local Authentication framework enables biometric and device authentication through Face ID, Touch ID, and device passcode. The framework provides secure user verification directly on the device without transmitting biometric data to external servers.

## Essential Guides

Two primary use cases are documented:

1. **User Login**: "Logging a User into Your App with Face ID or Touch ID" covers authentication flows for app access
2. **Keychain Integration**: "Accessing Keychain Items with Face ID or Touch ID" demonstrates securing stored credentials

## Authentication Methods

### Biometric Types

The framework supports multiple biometric authentication mechanisms:
- **Face ID**: Facial recognition on compatible devices
- **Touch ID**: Fingerprint authentication
- **Optic ID**: Advanced biometric capability on newer devices

Applications can check available biometric capabilities using `LAContext.biometryType` to determine which authentication method is usable on the current device.

### Device Authentication Options

Beyond biometrics, the framework provides:
- Device passcode authentication
- Watch-based authentication for paired devices
- Companion device authentication (Mac, Vision, Watch)

## Core Classes

**LAContext** serves as the primary interface, offering methods to:
- Evaluate authentication policies
- Check biometric availability
- Manage authentication state and credentials
- Customize prompt messaging

**LARight** handles authorization for specific protected operations, supporting persistent storage through `LARightStore`.

## Cryptographic Integration

The framework includes key pair management with `LAPrivateKey` and `LAPublicKey` for:
- Data encryption/decryption
- Digital signature operations
- Key exchange protocols

These cryptographic operations require biometric or passcode authentication before executing.

## Error Handling

"LAError" provides comprehensive error codes including:
- Cancellation states (user, system, or app-initiated)
- Biometry failures (not enrolled, locked out, disconnected)
- Configuration errors (passcode not set, invalid context)

## SwiftUI Support

`LocalAuthenticationView` enables simple integration in SwiftUI applications with customizable authentication prompts and context handling.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
