# UNMutableNotificationContent API Documentation

**Source**: https://sosumi.ai/documentation/usernotifications/unmutablenotificationcontent
**Fetched**: 2025-11-02

## Overview

`UNMutableNotificationContent` is a class that defines the editable payload for local notifications in Apple platforms. It enables developers to configure notification appearance, behavior, and delivery characteristics.

## Availability

- iOS 10.0+
- iPadOS 10.0+
- Mac Catalyst 13.1+
- macOS 10.14+
- tvOS 10.0+
- visionOS 1.0+
- watchOS 3.0+

## Purpose

According to the documentation, this class is used to "specify the payload for a local notification," allowing configuration of alert titles and messages, audio playback, app badge values, and system handling details.

## Class Hierarchy

**Inherits From:**
- `UNNotificationContent`

**Conforms To:**
- `CVarArg`
- `CustomDebugStringConvertible`
- `CustomStringConvertible`
- `Equatable`
- `Hashable`
- `NSCoding`
- `NSCopying`
- `NSMutableCopying`
- `NSObjectProtocol`
- `NSSecureCoding`

## Key Properties

### Primary Content
| Property | Purpose |
|----------|---------|
| `title` | Localized text providing primary notification description |
| `subtitle` | Localized text providing secondary notification description |
| `body` | Localized text for main notification content |

### Supplementary Content
| Property | Purpose |
|----------|---------|
| `attachments` | Visual and audio content accompanying the notification |
| `userInfo` | Custom data associated with the notification |

### App Behavior Configuration
| Property | Purpose |
|----------|---------|
| `badge` | Number displayed on app icon |
| `launchImageName` | Image or storyboard to display when notification launches app |
| `targetContentIdentifier` | Scene identifier for handling the notification |

### System Integration
| Property | Purpose |
|----------|---------|
| `sound` | Audio played when notification is delivered |
| `interruptionLevel` | Notification importance and delivery timing |
| `relevanceScore` | Score determining if notification is featured in summary |
| `filterCriteria` | Criteria for Focus mode display evaluation |

### Notification Grouping
| Property | Purpose |
|----------|---------|
| `threadIdentifier` | Groups related notifications together |
| `categoryIdentifier` | Identifies the notification category |
| `summaryArgument` | Additional context text in notification summary |
| `summaryArgumentCount` | Count of items represented by notification |

## Usage Pattern

The typical workflow involves:

1. Create a `UNMutableNotificationContent` instance
2. Configure relevant properties (title, body, sound, etc.)
3. Assign content to a `UNNotificationRequest` object
4. Add a trigger condition specifying delivery timing
5. Schedule the notification

## Localization

The documentation recommends using `NSString.localizedUserNotificationString(forKey:arguments:)` for alert strings rather than `NSLocalizedString`. This approach delays string loading until delivery, ensuring notifications respect language changes made before delivery.

## Important Note

"Local notifications always result in user interactions, and the system ignores any interactions for which your app isn't authorized." Request appropriate notification permissions through the UserNotifications framework before scheduling.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
