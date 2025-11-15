# DataScannerViewControllerDelegate API Documentation

**Source**: https://sosumi.ai/documentation/visionkit/datascannerviewcontrollerdelegate
**Fetched**: 2025-11-02

## Overview

`DataScannerViewControllerDelegate` is a protocol for handling user interactions with items recognized by the data scanner. As described in Apple's documentation, it enables developers to "respond when people interact with items that the data scanner recognizes."

## Availability

- iOS 16.0+
- iPadOS 16.0+
- visionOS 1.0+

## Protocol Declaration

```swift
@MainActor protocol DataScannerViewControllerDelegate : AnyObject
```

## Core Purpose

Implement this protocol to manage two primary responsibilities:
1. Respond when users tap recognized items
2. Optionally provide feedback when the scanner updates recognized items

## Delegate Methods

### Item Recognition Lifecycle

**didAdd** - Invoked when the scanner begins recognizing an item
```
dataScanner(_:didAdd:allItems:)
```

**didUpdate** - Called when the scanner updates geometry of a recognized item
```
dataScanner(_:didUpdate:allItems:)
```

**didRemove** - Triggered when the scanner stops recognizing an item
```
dataScanner(_:didRemove:allItems:)
```

### User Interaction

**didTapOn** - Responds to user tapping a recognized item
```
dataScanner(_:didTapOn:)
```

### Camera State

**didZoom** - Called when zoom factor changes (user or programmatic)
```
dataScannerDidZoom(_:)
```

**becameUnavailableWithError** - Handles scanner unavailability and cessation
```
dataScanner(_:becameUnavailableWithError:)
```

## Related Types

- `DataScannerViewController` - Main controller managing the scanning interface
- `RecognizedItem` - Represents detected items passed to delegate methods

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
