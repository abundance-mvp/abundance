# Authentication Services Documentation

**Source**: https://sosumi.ai/documentation/authenticationservices
**Fetched**: 2025-11-02

## Overview

Apple's Authentication Services framework provides comprehensive tools for implementing secure user authentication across iOS, macOS, tvOS, and watchOS platforms.

## Major Sections

### Authorization Requests

The framework enables developers to create and manage authorization requests through `ASAuthorizationController`. Key capabilities include:

- Creating controllers with multiple authorization request types
- Inspecting request providers and custom authorization methods
- Managing presentation context for authorization flows
- Executing requests with options like preferring immediately available credentials
- Handling completion callbacks for successful authorizations or errors

### Sign In with Apple

This section covers Apple's native sign-in solution, featuring:

- **SignInWithAppleButton**: SwiftUI component with customizable labels ("Sign In," "Sign Up," "Continue") and styles (black, white, outlined)
- **ASAuthorizationAppleIDButton**: UIKit implementation with similar styling options
- Request creation through `ASAuthorizationAppleIDProvider`
- Credential state management (authorized, not found, revoked, transferred)
- User detection capabilities to identify likely authentic users
- Contact information retrieval including full name and email addresses

### Passwords

Password-based authentication support includes:

- Password AutoFill integration
- `ASPasswordCredential` for managing username/password pairs
- Password request creation and handling

### Passkeys

Modern passwordless authentication using public-private key pairs:

**Registration Flow:**
- `ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest` for device passkeys
- `ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest` for physical security keys
- Attestation preferences and resident key settings

**Authentication Flow:**
- Assertion requests for credential verification
- Support for large blob storage and PRF (Pseudo-Random Function) extensions
- Transports including USB, NFC, and Bluetooth for security keys

### Web Authentication Sessions

`ASWebAuthenticationSession` enables OAuth and OpenID Connect flows:

- Custom scheme and HTTPS-based callbacks
- Ephemeral session options for privacy
- Presentation context management
- Error handling for canceled or failed logins

### AutoFill Credentials

Credential provider extensions allow apps to participate in system-wide AutoFill:

- Password credential provision
- Passkey assertion and registration support
- One-time code delivery
- Credential identity management through `ASCredentialIdentityStore`
- Support for multiple credential types with ranking

## Key Data Types

**Credentials:**
- `ASPasswordCredential`: Username/password pairs
- `ASPasskeyAssertionCredential`: Passkey authentication data
- `ASPasskeyRegistrationCredential`: New passkey enrollment data
- `ASOneTimeCodeCredential`: Time-based codes for verification

**Results:**
- `ASAuthorizationResult`: Enum covering all credential types returned from authorization flows

**Preferences:**
- User verification (discouraged, preferred, required)
- Resident key storage (discouraged, preferred, required)
- Attestation types (none, direct, indirect, enterprise)

## Error Handling

Framework provides structured error handling through `ASAuthorizationError` with codes including:

- `canceled`: User initiated cancellation
- `failed`: Request processing failure
- `invalidResponse`: Malformed authentication response
- `notInteractive`: Non-interactive request rejected
- `credentialExport`/`credentialImport`: Credential transfer issues
- Device-specific: `deviceNotConfiguredForPasskeyCreation`

## Async/Await Support

Modern `AuthorizationController` offers async variants for streamlined concurrency:

```
performRequest(_:) async throws -> ASAuthorizationResult
performRequests(_:options:) async throws -> ASAuthorizationResult
```

This enables cleaner error handling and sequential authentication workflows without delegate callbacks.
