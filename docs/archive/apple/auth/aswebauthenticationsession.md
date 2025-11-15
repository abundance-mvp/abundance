# ASWebAuthenticationSession API Documentation

**Source**: https://sosumi.ai/documentation/authenticationservices/aswebauthenticationsession
**Fetched**: 2025-11-02

## Overview

`ASWebAuthenticationSession` is an iOS/macOS framework class that facilitates user authentication through web services. It provides a secure, controlled environment for OAuth and third-party authentication flows.

**Core Purpose:** "A session that an app uses to authenticate a user through a web service."

## Availability

- iOS 12.0+
- iPadOS 12.0+
- macOS 10.15+
- Mac Catalyst 12.0+
- tvOS 16.0+
- visionOS 1.0+
- watchOS 6.2+

## Class Definition

```swift
class ASWebAuthenticationSession
```

**Inheritance:** NSObject
**Protocols:** CVarArg, CustomDebugStringConvertible, CustomStringConvertible, Equatable, Hashable, NSObjectProtocol

## Initialization

### Primary Constructor
```swift
init(url: URL, callback: ASWebAuthenticationSession.Callback,
     completionHandler: @escaping CompletionHandler)
```
Creates a session instance with callback evaluation for redirection URLs.

### Deprecated Constructor
```swift
init(url: URL, callbackURLScheme: String,
     completionHandler: @escaping CompletionHandler)
```
Legacy initialization method (use callback-based approach instead).

## Key Configuration Properties

| Property | Type | Purpose |
|----------|------|---------|
| `prefersEphemeralWebBrowserSession` | Bool | Requests private/incognito browser session when available |
| `presentationContextProvider` | ASWebAuthenticationPresentationContextProviding | Delegate providing display context for session presentation |
| `additionalHeaderFields` | [String: String]? | Custom HTTP headers for initial URL request |

## Session Control Methods

| Method | Purpose |
|--------|---------|
| `start()` | Initiates the authentication session |
| `cancel()` | Terminates an active session |
| `canStart` (property) | Boolean indicating session readiness |

## Callback Handling

**ASWebAuthenticationSession.Callback:** Evaluates navigation events during authentication
**ASWebAuthenticationSession.CompletionHandler:** Processes completion with result or error

The framework ensures "only the calling app's session receives the authentication callback, even when more than one app registers the same callback URL scheme."

## Error Handling

**Error Types Available:**
- `ASWebAuthenticationSessionError` - Standard error class
- `ASWebAuthenticationSessionError.Code` - Specific error codes
- `ASWebAuthenticationSessionErrorDomain` - Error domain constant

## User Experience Flow

1. System displays modal showing authentication domain
2. User confirms proceeding
3. Browser loads (embedded WebView on iOS, default browser on macOS)
4. User authenticates with service
5. Service sends callback URL with authentication token
6. Session delivers result to app via completion handler

## Related Resources

- Authenticating a User Through a Web Service
- iCloud Keychain Verification Code Integration
- Single Sign-On Support for Web Browsers
