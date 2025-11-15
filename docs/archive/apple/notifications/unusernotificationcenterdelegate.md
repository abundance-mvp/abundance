# UNUserNotificationCenterDelegate API Documentation

**Source**: https://sosumi.ai/documentation/usernotifications/unusernotificationcenterdelegate
**Fetched**: 2025-11-02

## Overview

The `UNUserNotificationCenterDelegate` protocol provides an interface for handling incoming notifications and responding to user interactions with notification actions. It enables apps to manage foreground notification presentation and process custom notification actions.

## Availability

- iOS 10.0+
- iPadOS 10.0+
- Mac Catalyst 13.1+
- macOS 10.14+
- tvOS 10.0+
- visionOS 1.0+
- watchOS 3.0+

## Protocol Declaration

```swift
protocol UNUserNotificationCenterDelegate : NSObjectProtocol
```

## Purpose

As stated in the documentation: "An interface for processing incoming notifications and responding to notification actions."

## Key Usage Patterns

**Critical Setup Requirement**: You must assign your delegate object to the `UNUserNotificationCenter` shared instance before app launch completion. In iOS apps, implement this in `application(_:willFinishLaunchingWithOptions:)` or `application(_:didFinishLaunchingWithOptions:)` methods. Missing this timing may cause notification delivery failures.

## Required Delegate Methods

### 1. Handle Foreground Notification Presentation

```swift
userNotificationCenter(_:willPresent:withCompletionHandler:)
```

Called when a notification arrives while your app runs in the foreground. The method receives the notification object and requires a completion handler invocation with `UNNotificationPresentationOptions` to determine display behavior.

### 2. Process User Actions

```swift
userNotificationCenter(_:didReceive:withCompletionHandler:)
```

Invoked when the user selects a notification or interacts with custom notification actions. Requires completion handler execution upon action processing completion.

### 3. Display In-App Settings

```swift
userNotificationCenter(_:openSettingsFor:)
```

Called when users request notification settings display through the system notification interface.

## Related Types

- **UNNotificationPresentationOptions**: Constants controlling notification presentation in foreground scenarios
- **UNUserNotificationCenter**: Shared manager for notification configuration and handling
- **UNNotificationSettings**: Container for current notification authorization state

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
