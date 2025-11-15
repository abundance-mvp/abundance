# SKProduct API Documentation

**Source**: https://sosumi.ai/documentation/storekit/skproduct
**Fetched**: 2025-11-02

## Overview

The `SKProduct` class provides "information about a registered product in App Store Connect." These objects are returned as part of an `SKProductsResponse` when querying the App Store for product details.

## Availability

- iOS 3.0+
- iPadOS 3.0+
- Mac Catalyst 13.1+
- macOS 10.7+
- tvOS (unspecified version)+
- visionOS 1.0+
- watchOS 6.2+

## Inheritance

Extends `NSObject` and conforms to multiple protocols including `Equatable`, `Hashable`, `Sendable`, and `CustomStringConvertible`.

## Core Properties

### Product Identification
- **productIdentifier**: "The string that identifies the product to the Apple App Store"

### Product Attributes
- **localizedTitle**: "The name of the product"
- **localizedDescription**: "A description of the product"
- **contentVersion**: Identifies the version of product content
- **isFamilyShareable**: Boolean indicating Family Sharing eligibility
- **contentLengths**: Total content size in bytes

## Pricing Information

- **price**: "The cost of the product in the local currency"
- **priceLocale**: "The locale used to format the price of the product"
- **introductoryPrice**: Contains introductory pricing details for qualified products
- **discounts**: Array of available subscription promotional offers

## Subscription Details

- **subscriptionGroupIdentifier**: Identifies the subscription group membership
- **subscriptionPeriod**: "The period details for products that are subscriptions"
- **SKProductSubscriptionPeriod**: Helper class containing subscription duration information
- **SKProduct.PeriodUnit**: Enumeration for interval durations (day through year)

## Downloadable Content

- **isDownloadable**: Boolean for App Store hosted content availability
- **downloadContentLengths**: File sizes for downloadable assets
- **downloadContentVersion**: Version identifier for downloadable content

## Related Resources

Developers should reference StoreKit's product loading guides and `SKProductsRequest` for querying product data from the App Store.

---

*Note: This content is sourced from Apple's official developer documentation and was extracted via sosumi.ai. Apple Inc. retains all documentation rights.*
