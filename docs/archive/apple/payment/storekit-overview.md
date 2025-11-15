# StoreKit Documentation

**Source**: https://sosumi.ai/documentation/storekit
**Fetched**: 2025-11-02

StoreKit is Apple's framework for managing in-app purchases and subscriptions within iOS applications.

## Core Components

### In-App Purchase System

The framework enables developers to implement "in-app purchase functionality" through the `Product` class, which represents purchasable items in the App Store.

### Key Capabilities

**Product Management:**
- Request products from App Store using `Product.products(for:)`
- Display product information including name, description, and pricing
- Access subscription details and renewal information

**Purchase Handling:**
- Execute purchases with `purchase(options:)` method
- Support for promotional and introductory offers
- Handle purchase results with success, cancellation, or pending states

**Subscription Features:**
- Monitor subscription status through `Product.SubscriptionInfo`
- Track renewal states (subscribed, expired, billing retry, grace period)
- Access introductory and promotional offer details
- Manage subscription periods (daily, weekly, monthly, yearly)

### UI Components

**Store Views:**
- `ProductView`: Display individual products
- `StoreView`: Showcase multiple products
- `SubscriptionStoreView`: Present subscription options with styling
- `SubscriptionOfferView`: Show specific subscription offers

**Styling Options:**
- Multiple product view styles (automatic, compact, regular, large)
- Subscription control styles (buttons, pickers, paged layouts)
- Customizable backgrounds and appearance

### Transaction Management

The framework tracks purchase history through:
- Current entitlements verification
- Latest transaction access
- Transaction verification for security
- Refund request handling

### Configuration Options

Developers can customize behavior through environment-specific settings, purchase options for testing, and subscription offer parameters to tailor the purchase experience.
