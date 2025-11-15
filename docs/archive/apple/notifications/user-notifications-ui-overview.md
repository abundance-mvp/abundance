# User Notifications UI Framework Overview

**Source**: https://sosumi.ai/documentation/usernotificationsui
**Fetched**: 2025-11-02

## Overview
The User Notifications UI framework enables developers to customize notification appearance and behavior through content extensions.

## Core Components

### Notification Content Extension
The `UNNotificationContentExtension` protocol serves as the primary interface for building custom notification UIs. It allows apps to "Customizing the Appearance of Notifications" through custom view controllers.

### Processing Notifications
Implement `didReceive(UNNotification)` to handle incoming notifications and update your custom interface accordingly.

### Custom Action Handling
The `didReceive(_:completionHandler:)` method processes user interactions with custom notification actions, requiring a response option to indicate the desired behavior.

**Response Options:**
- `doNotDismiss` — Keep the notification visible after action
- `dismiss` — Close the notification normally
- `dismissAndForwardAction` — Close and pass action to the main app

### Media Playback Support
Extensions can provide media controls through these properties and methods:

- `mediaPlayPauseButtonType` — Configure button appearance (none, default, or overlay)
- `mediaPlayPauseButtonFrame` — Define button positioning
- `mediaPlayPauseButtonTintColor` — Customize button coloring
- `mediaPlay()` and `mediaPause()` — Control playback programmatically

This framework enables rich, interactive notification experiences beyond standard alert styles.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
