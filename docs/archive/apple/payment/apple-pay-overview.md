# Apple Pay Documentation

**Source**: https://sosumi.ai/documentation/passkit/apple_pay
**Fetched**: 2025-11-02

## Overview
Apple Pay enables developers to request and process payments within applications across iPhone and Apple Watch platforms.

## Setup Requirements
Implementation requires fulfilling specific prerequisites to offer Apple Pay as a payment option. Developers must also review regional regulations that may apply to their Apple Pay implementations.

## Core Components

### Payment Authorization
The framework provides controllers for presenting payment authorization sheets:
- `PKPaymentAuthorizationController` and `PKPaymentAuthorizationViewController` present interfaces prompting user authorization

### Payment Buttons
Several button implementations are available:
- `PKPaymentButton` displays payment triggers or card setup prompts
- `PayWithApplePayButton` provides SwiftUI payment button functionality
- Customizable label and style options for button presentation

### Payment Requests
Multiple request types support different payment scenarios:
- Standard payments via `PKPaymentRequest`
- Recurring/subscription payments through `PKRecurringPaymentRequest`
- Automatic reload capabilities with `PKAutomaticReloadPaymentRequest`
- Deferred payments for bookings or pre-orders via `PKDeferredPaymentRequest`
- Multimerchant payments using `PKPaymentTokenContext`

### Disbursements
`PKDisbursementRequest` handles fund transfers from merchants to individuals.

## Payment Processing

### Sheet Updates
The framework manages dynamic updates after user interactions:
- Merchant validation updates
- Payment method changes
- Shipping information modifications
- Shipping method selections
- Coupon code applications

### Error Handling
Comprehensive error structures address payment and disbursement failures, with domain-specific error codes for debugging.

## Security & Validation
Payment tokens contain encrypted transaction data requiring verification. Developers should reference the payment token format documentation for validation procedures.
