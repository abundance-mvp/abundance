# BUG-001: Camera Photo Upload Fails with Hardcoded User ID

**Status**: Triaged
**Severity**: Critical
**Type**: Bug (Authentication + Storage Error)
**Created**: 2025-11-17
**Issue Reference**: .debug/issues/triaged/issue-001.md

---

## Description

When a user attempts to capture a photo in the camera view, the upload to Firebase Storage fails with the error:

```
Failed to capture photo: Object users/current_user_id/items/E536DF7B-BCD6-44CB-BC3D-A617DCB2938A/cropped.jpg does not exist.
```

This prevents any photo cataloging from working in the app.

---

## Expected Behavior

When the capture button is tapped:

1. Photo should be captured from camera
2. Photo should be converted to UIImage
3. Photo should be uploaded to Firebase Storage at path: `users/{ACTUAL_USER_ID}/items/{ITEM_ID}/cropped.jpg`
4. Upload should succeed and return a download URL
5. User should see success feedback

---

## Actual Behavior

When the capture button is tapped:

1. Photo is captured successfully
2. Photo is converted to UIImage successfully
3. Upload attempts to use path: `users/current_user_id/items/{ITEM_ID}/cropped.jpg`
4. Firebase Storage rejects the upload because `current_user_id` is not a valid user
5. Error message is shown to user
6. Camera view becomes unresponsive (black screen) until app restart

---

## Root Cause

**File**: `Sources/CameraFeature/ViewModels/CameraViewModel.swift`
**Lines**: 100-102

```swift
// Upload to Firebase Storage
let itemId: String = UUID().uuidString
let userId: String = "current_user_id" // TODO: Get from Auth service
```

The code uses a hardcoded placeholder string `"current_user_id"` instead of retrieving the actual authenticated user's ID from the auth service.

**Analysis**:
- The TODO comment indicates this was known technical debt
- The StorageService.uploadCroppedObject() method receives this invalid user ID
- Firebase Storage security rules likely reject the path because it doesn't match the authenticated user
- No error handling recovers the camera view, causing it to become unresponsive

---

## Affected Files

- `Sources/CameraFeature/ViewModels/CameraViewModel.swift` (lines 100-102) - Hardcoded user ID
- `Sources/Persistence/StorageService.swift` - Receives invalid user ID, should validate
- `Sources/CameraFeature/Views/CameraView.swift` - No error recovery, camera becomes unresponsive

---

## Suggested Fix

### 1. Add Auth Service Dependency

Add AuthService to CameraViewModel initialization:

```swift
public init(
    cameraService: CameraServiceProtocol,
    storageService: StorageServiceProtocol = StorageService(),
    authService: AuthServiceProtocol = AuthService() // ADD THIS
) {
    self.cameraService = cameraService
    self.storageService = storageService
    self.authService = authService
}
```

### 2. Get Real User ID

Replace hardcoded string with actual user ID retrieval:

```swift
// Upload to Firebase Storage
let itemId: String = UUID().uuidString

// Get authenticated user ID
guard let userId = authService.getCurrentUserId() else {
    errorMessage = "User not authenticated. Please sign in again."
    return
}

uploadProgress = 0.5
```

### 3. Add Error Recovery

In `CameraView.swift`, add error state recovery:

```swift
.onChange(of: viewModel.errorMessage) { _, newError in
    if newError != nil {
        // Reset camera state after showing error
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await viewModel.checkCameraPermission() // Restart camera
        }
    }
}
```

### 4. Add Validation

Add user ID validation before upload attempt:

```swift
// Validate user ID before upload
guard !userId.isEmpty, userId != "current_user_id" else {
    errorMessage = "Invalid user session. Please sign in again."
    return
}
```

---

## Test Plan

### Unit Tests

- [ ] Test `CameraViewModel.capturePhoto()` with valid user ID
- [ ] Test `CameraViewModel.capturePhoto()` with nil user ID (should show error)
- [ ] Test `CameraViewModel.capturePhoto()` with empty user ID (should show error)
- [ ] Test `StorageService.uploadCroppedObject()` validates user ID format
- [ ] Test error recovery resets camera state correctly

### Integration Tests

- [ ] Test authenticated user can capture and upload photo
- [ ] Test upload path uses actual user ID from auth service
- [ ] Test upload succeeds and returns valid download URL
- [ ] Test error message is shown when user not authenticated
- [ ] Test camera recovers after error (not black screen)

### Manual Tests

- [ ] Sign in with valid user account
- [ ] Open camera view
- [ ] Capture photo
- [ ] Verify upload succeeds
- [ ] Check Firebase Storage console shows file at: `users/{REAL_USER_ID}/items/{ITEM_ID}/cropped.jpg`
- [ ] Force auth error (sign out in background)
- [ ] Capture photo
- [ ] Verify error message is shown
- [ ] Verify camera remains usable (not black screen)

---

## References

- **Spec**: docs/design/DESIGN-027-camera-capture-view-specification.md (photo capture flow)
- **Original Issue**: .debug/issues/triaged/issue-001.md
- **Log File**: .debug/logs/session-20251117-060008.log
- **Architecture**: ADR-010 (MVVM pattern with dependency injection)

---

## Priority Justification

**Critical** - This bug prevents the core cataloging feature from working at all. No user can catalog items until this is fixed.

---

## Estimated Effort

**Small** (1-2 hours)
- Add AuthService dependency
- Replace hardcoded user ID with auth service call
- Add validation and error handling
- Write unit tests

---

## Acceptance Criteria

- [ ] Camera captures photo successfully
- [ ] Photo uploads to Firebase Storage with real user ID in path
- [ ] Upload succeeds and returns download URL
- [ ] Error messages are clear when auth fails
- [ ] Camera remains usable after errors (no black screen)
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Code review approved
