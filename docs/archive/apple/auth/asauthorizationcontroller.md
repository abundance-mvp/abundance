# ASAuthorizationController API Documentation

**Source**: https://sosumi.ai/documentation/authenticationservices/asauthorizationcontroller
**Fetched**: 2025-11-02

## Overview

`ASAuthorizationController` is a foundational class that coordinates credential authorization flows across multiple authentication providers. The framework enables apps to request user credentials through structured, provider-specific authorization requests.

## Availability

- iOS 13.0+
- iPadOS 13.0+
- Mac Catalyst 13.1+
- macOS 10.15+
- tvOS 13.0+
- visionOS 1.0+
- watchOS 6.0+

## Purpose

As stated in Apple's documentation: *"A controller that manages authorization requests that a provider creates."* It handles the presentation and lifecycle of credential authorization flows, including Sign in with Apple, password-based authentication, and custom authentication methods.

## Class Hierarchy

- **Inherits from:** NSObject
- **Conforms to:** CVarArg, CustomDebugStringConvertible, CustomStringConvertible, Equatable, Hashable, NSObjectProtocol

## Initialization

### init(authorizationRequests:)
Creates a controller instance from an array of authorization request objects. Supply request objects for supported credential types like `ASAuthorizationAppleIDRequest` or `ASAuthorizationPasswordRequest`.

## Core Properties

### delegate
Type: `ASAuthorizationControllerDelegate`

An object that receives notifications when authorization attempts succeed or fail. Must implement delegate protocol methods to handle completion events.

### presentationContextProvider
Type: `ASAuthorizationControllerPresentationContextProviding`

A provider object that supplies the UI window context where authorization interfaces appear. Required for modal presentation workflows.

### authorizationRequests
Type: `[ASAuthorizationRequest]`

Read-only collection of authorization request objects managed by the controller.

### customAuthorizationMethods
Type: `[ASAuthorizationCustomMethod]`

An array containing custom authentication methods users may select during authorization flows.

## Request Execution Methods

### performRequests()
Initiates authorization flows defined during controller initialization using modal presentation.

### performRequests(options:)
Initiates authorization flows with configurable options via `ASAuthorizationController.RequestOptions` parameter.

### performAutoFillAssistedRequests()
Launches authorization flows optimized for inline AutoFill UI presentation, reducing friction during credential entry.

### cancel()
Terminates any active authorization requests and dismisses presented UI.

## Delegate Protocol: ASAuthorizationControllerDelegate

Implementers must handle authorization outcomes:

- `authorizationController(_:didCompleteWithAuthorization:)` — Invoked upon successful authorization
- `authorizationController(_:didCompleteWithError:)` — Invoked when authorization fails
- `authorizationController(_:didCompleteWithCustomMethod:)` — Called when user selects custom authentication

## AutoFill Integration

Configure text field content types to enable AutoFill suggestions:
- Use `UITextContentType.username` for user identification fields
- Use `UITextContentType.password` for credential fields

This enables the controller to intelligently offer saved credentials via system AutoFill.

## Related Types

- `ASAuthorizationRequest` — Base class for credential request types
- `ASAuthorizationResult` — Encapsulates successful authorization outcomes
- `ASAuthorizationController.RequestOptions` — Configuration flags for request execution
