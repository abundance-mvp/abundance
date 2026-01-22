---
date: 2026-01-20
status: Fixed
priority: P1
type: bug
component: ios
source: manual
related-files:
  - Sources/InventoryFeature/ItemDetailView.swift
  - Sources/InventoryFeature/ItemCard.swift
  - Sources/Persistence/Models/Item.swift
  - functions/src/ai-pipeline/layer1/layer1-service.ts
screenshots:
  - Screenshot 2026-01-20 at 7.24.50 PM.png
axiom-agent: general-purpose
branch: fix/missing-item-images
design-doc: null
implementation-plan: null
fix-commit: 66810cf
---

## Summary

Item images fail to load for some inventory items, showing placeholder icon instead of actual photo.

## Description

In the ItemDetailView (and potentially ItemCard grid), some items display a placeholder image icon instead of the actual captured photo. The issue affects the hero image area in the detail view. All other metadata (name, brand, category, value, color, condition, AI confidence, etc.) loads and displays correctly.

The affected item in the screenshot is "Osprey Transporter Series Backpack" which shows:
- Placeholder icon (mountain/photo symbol) in the hero image area
- Complete metadata below including $75.00 estimated value
- High AI confidence rating

This suggests the image URL exists in the Item record but either:
1. The URL is invalid/expired
2. The image was not uploaded to storage
3. AsyncImage is failing to fetch from the URL
4. Storage permissions or CORS issue

## Expected Behavior

Item detail view should display the captured photo of the item in the hero image area at the top of the screen.

## Actual Behavior

Hero image area shows a gray placeholder with a photo icon. The image fails to load silently without error indication to the user.

## Technical Context

- Device: w-16e (iPhone)
- iOS: 18.0+
- Source: manual observation
- Views affected: ItemDetailView (confirmed), ItemCard (possibly)

## Investigation Steps

1. Check if `item.imageUrl` contains a valid URL
2. Verify the image exists in Firebase Storage at that path
3. Check if Storage security rules allow read access
4. Test AsyncImage with the URL directly
5. Check for items where imageUrl is empty vs invalid

## Proposed Solution

1. Add logging to track AsyncImage load failures
2. Verify storage upload completes before creating Item record
3. Consider adding retry logic or error state to AsyncImage
4. May need to check storage bucket permissions

## Root Cause Analysis

The Layer 1 detection service (`functions/src/ai-pipeline/layer1/layer1-service.ts`) was generating
GCS signed URLs with a 24-hour expiration for cropped object images:

```typescript
const [signedUrl] = await file.getSignedUrl({
  action: 'read',
  expires: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
  version: 'v4'
});
```

After 24 hours, these URLs became invalid, causing AsyncImage to fail silently.

Evidence:
- Firestore item had imageUrl with token: `85d8b7af-759b-4120-a388-c8bd3c282790`
- Current Storage file token: `941c1e31-be34-413e-8421-672bb5bdaf9b`
- The mismatch confirms the stored URL had expired

## Resolution

**Backend fix (functions/src/ai-pipeline/layer1/layer1-service.ts):**
- Replaced `getSignedUrl()` with Firebase Storage download URLs using permanent tokens
- Added `firebaseStorageDownloadTokens` metadata when uploading cropped images
- Created `generateFirebaseDownloadUrl()` helper for consistent URL generation
- New URLs use format: `firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={uuid}`

**iOS improvements:**
- Added `imageLoadFailed` LogEvent to AppLogger for tracking failures
- Added error logging to ItemDetailView and ItemCard AsyncImage failure handlers
- Created reusable `ItemImage` component with built-in error logging

**Note:** Existing items with expired URLs will need manual refresh or re-processing.
New items captured after this fix will have permanent URLs.
