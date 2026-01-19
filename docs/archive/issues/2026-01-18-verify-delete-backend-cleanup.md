---
date: 2026-01-18
status: fixed
priority: P2
type: test
component: backend
source: device-tester
related-files:
  - functions/src/catalog/delete-item.ts
  - Sources/CatalogFeature/ViewModels/CatalogViewModel.swift
  - functions/src/ai-pipeline/layer2/layer2-service.ts
screenshots:
  - Screenshot 2026-01-18 at 10.26.34 PM.png
axiom-agent: general-purpose
branch: test/verify-delete-cleanup
design-doc: null
implementation-plan: null
---

## Summary

Verify that delete function properly cleans up all backend data, especially for failed catalog items, to prevent orphaned data.

## Description

The delete function in the catalog view appears to work (item disappears from UI). However, verification is needed to ensure that:

1. Firestore document is deleted
2. Storage bucket images (original + crops) are deleted
3. Any processing queue entries are cleaned up
4. No orphaned data remains for failed items

This is particularly important for items that failed during Layer 2 cataloging, as they may have partial data in multiple locations.

## Expected Behavior

When an item is deleted:
1. Catalog item document removed from Firestore
2. Original image removed from Storage
3. Cropped images removed from Storage
4. Session data cleaned up if applicable
5. No orphaned references in other collections

## Actual Behavior

- UI shows item deleted (disappears from list)
- Backend cleanup status unknown
- Need to verify via Cloud Logging or Firestore console
- Concern about orphaned data from failed processing attempts

## Technical Context

- Device: w-16e (iPhone 16e)
- iOS: 18.x
- Source: device-tester session 2026-01-18
- Multiple failed items were created (screenshot shows 4 duplicates)
- All failed items were deleted via UI

### Data Locations to Verify

1. `users/{userId}/items/{itemId}` - Firestore document
2. `users/{userId}/sessions/{sessionId}` - Session document
3. `gs://abundance-mvp.firebasestorage.app/users/{userId}/captures/` - Original images
4. `gs://abundance-mvp.firebasestorage.app/users/{userId}/crops/` - Cropped images

## Verification Steps

1. Check Cloud Functions logs for delete operations
2. Query Firestore for any remaining documents
3. List Storage bucket contents for test user
4. Verify no orphaned crops exist without parent items

## Proposed Solution

1. Add comprehensive logging to delete function
2. Implement cascading delete for all related data
3. Add cleanup job for orphaned storage files
4. Write integration test for delete + cleanup verification
5. Consider soft-delete with scheduled hard-delete for recovery window
