# SKPaymentQueue API Documentation

**Source**: https://sosumi.ai/documentation/storekit/skpaymentqueue
**Fetched**: 2025-11-02

## Overview

`SKPaymentQueue` is a core StoreKit class that "communicates with the App Store and presents a user interface so that the user can authorize payment." The queue manages payment transactions persistently across app launches.

**Availability:** iOS 3.0+, iPadOS 3.0+, Mac Catalyst 13.1+, macOS 10.7+, tvOS 9.0+, visionOS 1.0+, watchOS 6.2+

## Purpose

This class enables in-app purchase functionality by handling the complete transaction lifecycle from payment initiation through fulfillment. "The contents of the queue are persistent between launches of your app."

## Singleton Pattern

```swift
SKPaymentQueue.default() // Returns the default payment queue instance
```

## Observer Pattern

Before processing payments, you must register transaction observers:

- **add(_:)** - Adds an observer conforming to `SKPaymentTransactionObserver`
- **transactionObservers** - Array of all currently active observers
- **remove(_:)** - Removes an observer from the queue

The observer receives callbacks when transaction states change.

## Payment Processing Flow

1. Add observer to queue
2. Create `SKPayment` object for the desired product
3. Add payment via **add(_:)** method
4. Queue creates `SKPaymentTransaction` and enqueues it
5. Observer receives updated transaction via callback
6. Observer processes transaction and calls **finishTransaction(_:)**

## Key Methods

**Managing Transactions:**
- **transactions** - Returns pending transaction array
- **finishTransaction(_:)** - Notifies App Store of completion
- **delegate** - Provides information needed for transaction completion

**Restoring Purchases:**
- **restoreCompletedTransactions()** - Restores previously purchased items
- **restoreCompletedTransactions(withApplicationUsername:)** - Restoration with user identifier

**Additional Features:**
- **canMakePayments()** - Checks if user can purchase
- **storefront** - Returns device's App Store storefront
- **showPriceConsentIfNeeded()** - Displays price increase consent sheet
- **presentCodeRedemptionSheet()** - Shows offer code redemption interface

## Content Delivery Patterns

Processed transactions enable three content approaches:

1. Enable built-in app features
2. Retrieve `SKDownload` objects for App Store-hosted content
3. Download from your own server via network connection

## Class Hierarchy

- Inherits from: `NSObject`
- Conforms to: `CVarArg`, `CustomDebugStringConvertible`, `Sendable`, and related protocols

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
