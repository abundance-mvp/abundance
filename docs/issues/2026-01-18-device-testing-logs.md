# Device Testing Logs - 2026-01-18

Session: w-16e (iPhone 16e) iterative testing
Date: 2026-01-18 06:00-06:15 UTC

## Summary of Issues Found & Fixed

| Issue | Priority | Status | Fix |
|-------|----------|--------|-----|
| Storage bucket authorization failure | P0 | Fixed | Deployed existing fix for URL parsing with `:443` port |
| Camera preview black screen | P1 | Fixed | Custom `PreviewView` UIView with `layoutSubviews()` |
| IAM signBlob permission denied | P0 | Fixed | Switched to Firebase download URLs with tokens |

## Successful Detection (Post-Fix)

```
Timestamp: 2026-01-18T06:10:48.855Z
Session: UcqMkcqHBVv64fJheZ6u
Result: 3 objects detected
Status: detected
```

---

## Raw Cloud Function Logs

### Deployment Log (06:08:47Z)

```json
{
  "timestamp": "2026-01-18T06:08:47.693839Z",
  "severity": "INFO",
  "textPayload": "firebase-functions-hash=556c3276bdccc7a0b7cd3d77368a8b2596ec472c"
}
```

### Detection Success Logs (06:10:48Z)

```json
{
  "timestamp": "2026-01-18T06:10:48.855Z",
  "severity": "INFO",
  "message": "Session detection completed",
  "sessionId": "UcqMkcqHBVv64fJheZ6u",
  "objectCount": 3
}
```

```json
{
  "timestamp": "2026-01-18T06:10:47.546Z",
  "severity": "INFO",
  "message": "Processing session",
  "sessionId": "UcqMkcqHBVv64fJheZ6u",
  "captureMode": "single",
  "imageCount": 1
}
```

### Earlier Errors (Pre-Fix) - signBlob Permission

```json
{
  "timestamp": "2026-01-18T06:04:52.633Z",
  "severity": "ERROR",
  "message": "Failed to crop object",
  "label": "Laptop Computer",
  "groupId": "laptop_macbook_001",
  "error": "firebase-app@0.1.3 requires permission 'iam.serviceAccounts.signBlob' to sign"
}
```

```json
{
  "timestamp": "2026-01-18T06:04:52.634Z",
  "severity": "ERROR",
  "message": "Failed to crop object",
  "label": "Coffee Mug",
  "groupId": "mug_coffee_001",
  "error": "firebase-app@0.1.3 requires permission 'iam.serviceAccounts.signBlob' to sign"
}
```

```json
{
  "timestamp": "2026-01-18T06:04:52.634Z",
  "severity": "ERROR",
  "message": "Failed to crop object",
  "label": "Wireless Mouse",
  "groupId": "mouse_wireless_001",
  "error": "firebase-app@0.1.3 requires permission 'iam.serviceAccounts.signBlob' to sign"
}
```

### Earlier Errors (Pre-Fix) - Unauthorized Bucket

```json
{
  "timestamp": "2026-01-18T05:58:XX.XXXZ",
  "severity": "ERROR",
  "message": "Session validation failed",
  "reason": "Unauthorized bucket",
  "url": "https://firebasestorage.googleapis.com:443/v0/b/abundance-mvp.firebasestorage.app/o/...",
  "bucketName": null
}
```

---

## Files Modified During Session

### iOS (Camera Preview Fix)

1. **`Sources/CameraFeature/Views/CameraPreviewView.swift`**
   - Created custom `PreviewView` UIView subclass
   - Uses `layoutSubviews()` for proper preview layer frame updates
   - Disables animations during frame updates to prevent glitches

2. **`Sources/CameraFeature/Services/CameraService.swift`**
   - Added diagnostic logging for session startup

3. **`Sources/CameraFeature/Services/CameraSessionActor.swift`**
   - Added diagnostic logging for configure/startRunning

### Backend (Firebase Download URLs Fix)

1. **`functions/src/ai-pipeline/layer1/layer1-service.ts`**
   - Changed from `getSignedUrl()` to Firebase Storage download URLs
   - Added `randomUUID` for download token generation
   - Avoids `iam.serviceAccounts.signBlob` permission requirement

---

## Additional Issues to File

Based on this testing session, consider filing:

1. **Background Processing UX** - User can't see detection progress while cataloging
2. **Camera Preview Offset** - Preview may still have edge cases with overlay transitions
3. **Error Recovery UX** - Need better user feedback when detection fails

---

## Git Status After Fixes

```
Branch: main (fixes committed)
Commits:
- fix(backend): resolve storage bucket authorization for detection
- fix(camera): synchronous preview layer frame updates
```
