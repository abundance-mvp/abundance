# ASPasswordCredential API Documentation

**Source**: https://sosumi.ai/documentation/authenticationservices/aspasswordcredential
**Fetched**: 2025-11-02

## Overview

`ASPasswordCredential` is a class that encapsulates password-based authentication credentials within Apple's Authentication Services framework.

## Availability

Supported across multiple Apple platforms:
- iOS 12.0+
- iPadOS 12.0+
- macOS 10.15+
- Mac Catalyst 13.1+
- tvOS 15.0+
- watchOS 6.0+
- visionOS 1.0+

## Purpose

This class represents "a password credential" and serves as the standard mechanism for handling username and password pairs during authentication workflows, particularly in conjunction with AutoFill features.

## Class Hierarchy

- **Inherits from:** `NSObject`
- **Implements:** `ASAuthorizationCredential` protocol along with standard Swift and Foundation protocols including `Codable`, `Hashable`, `Equatable`, and `Sendable`

## Initialization

### Creating Credentials

```swift
init(user: String, password: String)
```

Constructs a new password credential instance with the provided username and password values.

## Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `user` | String | The username associated with the credential |
| `password` | String | The password associated with the credential |

## Integration Points

ASPasswordCredential integrates with:
- **Password AutoFill** - Enables system-level credential autofill capabilities
- **ASAuthorizationPasswordProvider** - Manages password-based authorization flows
- **Web browser password handling** - Supports credential use across web contexts

## Conformance

The class adheres to secure coding standards through `NSSecureCoding` and `NSCoding` protocols, enabling safe serialization and persistence.
