# LAContext API Documentation

**Source**: https://sosumi.ai/documentation/localauthentication/lacontext
**Fetched**: 2025-11-02

## Overview

LAContext is Apple's primary mechanism for handling local device authentication. As stated in the documentation, it provides "a mechanism for evaluating authentication policies and access controls."

The framework enables developers to authenticate users through biometric methods (Touch ID, Face ID) or device passcode, handling all user interactions and communication with the Secure Enclave—the hardware component managing biometric data.

## Availability

LAContext is available across Apple's ecosystem:
- iOS 8.0+
- iPadOS 8.0+
- macOS 10.10+
- Mac Catalyst 13.1+
- watchOS 3.0+
- visionOS 1.0+

## Critical Setup Requirement

**Important:** Applications must include the appropriate `Info.plist` key to enable biometric authentication. Failure to do so may result in authorization request failures.

## Core Capabilities

### Authentication Evaluation

The framework provides two primary evaluation methods:

1. **Policy Evaluation** - Assess and execute predefined authentication policies through `evaluatePolicy(_:localizedReason:reply:)`
2. **Access Control Evaluation** - Evaluate access controls for specific operations via `evaluateAccessControl(_:operation:localizedReason:reply:)`

### Availability Checking

Before attempting authentication, verify capability using:
- `canEvaluatePolicy(_:error:)` - Determines if a policy can be evaluated
- `biometryType` property - Returns the device's supported biometric method

## Key Properties

| Property | Purpose |
|----------|---------|
| `evaluatedPolicyDomainState` | Tracks current policy domain state |
| `maxBiometryFailures` | Defines failure threshold before fallback mechanism |
| `interactionNotAllowed` | Controls whether authentication UI can be presented |
| `domainState` | Contains authentication domain state information |

## Customization Options

Developers can localize the authentication experience:
- `localizedReason` - Explanation text shown in authentication dialog
- `localizedFallbackTitle` - Fallback button text
- `localizedCancelTitle` - Cancel button text

## Credential Management

LAContext supports credential handling through:
- `setCredential(_:type:)` - Sets application-provided credentials
- `isCredentialSet(_:)` - Checks credential status

## Lifecycle Management

- `invalidate()` - Invalidates the context when complete

## Authentication Flow Pattern

The framework operates asynchronously, returning results via callback that indicates success/failure and provides error information explaining any failures.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
