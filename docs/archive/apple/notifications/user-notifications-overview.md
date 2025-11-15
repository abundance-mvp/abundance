# User Notifications Framework Overview

**Source**: https://sosumi.ai/documentation/usernotifications
**Fetched**: 2025-11-02

## Overview

The UserNotifications framework enables iOS, macOS, and watchOS apps to schedule and manage local notifications, as well as receive and handle remote (push) notifications delivered via Apple Push Notification service (APNs).

## Core Components

### Notification Center Management

The `UNUserNotificationCenter` class serves as the central hub for notification operations:

- **Current instance access**: `UNUserNotificationCenter.current()` retrieves the shared notification center
- **Authorization requests**: Apps must request user permission via `requestAuthorization(options:completionHandler:)`
- **Settings queries**: `getNotificationSettings(completionHandler:)` checks current authorization status
- **Badge management**: `setBadgeCount(_:withCompletionHandler:)` updates app badge numbers

### Authorization Options

Apps can request permission for specific notification features:

- `.badge` - App icon badge numbers
- `.sound` - Audio alerts
- `.alert` - Visual notifications (banners/alerts)
- `.carPlay` - CarPlay display
- `.criticalAlert` - Bypass Do Not Disturb
- `.provisional` - Tentative authorization
- `.providesAppNotificationSettings` - Custom settings UI

## Notification Content

### Creating Notifications

`UNMutableNotificationContent` defines notification properties:

**Primary content**:
- `title` - Short headline
- `subtitle` - Secondary text
- `body` - Main message content

**Supplementary content**:
- `attachments` - Images, audio, video files
- `userInfo` - Custom dictionary data
- `launchImageName` - Custom launch screen

**System integration**:
- `sound` - Audio alert (default or custom)
- `interruptionLevel` - Urgency: `.passive`, `.active`, `.timeSensitive`, `.critical`
- `badge` - Numeric badge value
- `threadIdentifier` - Conversation grouping
- `categoryIdentifier` - Links to notification actions

## Scheduling Notifications

### Local Notification Requests

Create `UNNotificationRequest` with content and trigger:

```
UNNotificationRequest(identifier:, content:, trigger:)
```

### Trigger Types

**Calendar trigger** - Specific dates/times using `DateComponents`:
- "nextTriggerDate()" calculates next fire time
- `repeats` parameter enables recurring notifications

**Time interval trigger** - Delays measured in seconds:
- Minimum 60 seconds for most notifications
- Critical alerts can use shorter intervals

**Location trigger** - Region-based delivery:
- Fires when device enters/exits `CLRegion`
- Requires location permissions

**Push trigger** - Remote delivery via APNs

### Managing Scheduled Notifications

- `add(_:withCompletionHandler:)` - Schedule a request
- `getPendingNotificationRequests(completionHandler:)` - List scheduled items
- `removePendingNotificationRequests(withIdentifiers:)` - Cancel specific notifications
- `removeAllPendingNotificationRequests()` - Cancel all pending

## Handling Notifications

### Delegate Protocol

Implement `UNUserNotificationCenterDelegate` to process notifications:

**Receiving foreground notifications**:
```
userNotificationCenter(_:willPresent:withCompletionHandler:)
```
Customizes display via `UNNotificationPresentationOptions`: `.banner`, `.list`, `.sound`, `.badge`, `.alert`

**Processing user actions**:
```
userNotificationCenter(_:didReceive:withCompletionHandler:)
```
Responds when user taps notification or custom action

**Settings access**:
```
userNotificationCenter(_:openSettingsFor:)
```
Opens notification settings when user taps settings option

### Notification Delivery Status

- `getDeliveredNotifications(completionHandler:)` - Active notifications
- `removeDeliveredNotifications(withIdentifiers:)` - Clear specific notifications
- `removeAllDeliveredNotifications()` - Clear all

## Notification Categories & Actions

### Custom Actions

Define actionable notification types with `UNNotificationCategory`:

- Link actions to notifications via `categoryIdentifier`
- Specify action buttons with `UNNotificationAction`
- Support text input via `UNTextInputNotificationAction`

### Action Options

- `.authenticationRequired` - Unlock device first
- `.destructive` - Red styling for delete/remove
- `.foreground` - Launch app when activated

### Category Options

- `.customDismissAction` - Handle swipe-to-dismiss
- `.allowInCarPlay` - Enable CarPlay display
- `.hiddenPreviewsShowTitle` - Display title when locked
- `.hiddenPreviewsShowSubtitle` - Display subtitle when locked

## Remote Notifications (Push)

### Server Setup

Apps receiving remote notifications require:

1. **APNs registration** - Register certificate or token
2. **Device token** - Retrieved by app, sent to backend
3. **Payload delivery** - Server sends JSON via APNs
4. **Sandbox/production** - Separate environments for testing

### APNs Security

- **Token-based** - JSON Web Token with signing key (recommended)
- **Certificate-based** - SSL/TLS certificate authentication

### Content Modification

`UNNotificationServiceExtension` allows processing before delivery:

```
didReceive(_:withContentHandler:)
```
Modify content, download attachments, decrypt payloads within 30-second window

## Authorization Status

`UNAuthorizationStatus` indicates permission state:

- `.notDetermined` - User hasn't decided
- `.denied` - User declined
- `.authorized` - Fully granted
- `.provisional` - Tentative permission
- `.ephemeral` - Temporary access

## Device-Specific Settings

Query per-feature enablement:

- `notificationCenterSetting` - Notification Center display
- `lockScreenSetting` - Lock screen visibility
- `alertSetting` - Alert/banner display
- `soundSetting` - Audio enabled
- `badgeSetting` - Badge numbers
- `criticalAlertSetting` - Do Not Disturb bypass

Each returns `.notSupported`, `.disabled`, or `.enabled`

## Error Handling

`UNError` defines notification-specific failures:

- `notificationsNotAllowed` - Authorization denied
- `notificationInvalidNoDate` - Missing trigger date
- `notificationInvalidNoContent` - Empty content
- `attachmentInvalidURL` - Bad attachment path
- `attachmentInvalidFileSize` - Oversized attachment

## Key Considerations

- Requests require completion handlers for proper cleanup
- Notification sound must be under 30 seconds
- Attachments limited to 100MB (compressed)
- Time interval triggers need 60+ second delays
- Authorization prompt appears once per app

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
