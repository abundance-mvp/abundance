---
date: 2026-01-18
status: open
priority: P0
type: bug
component: backend
source: manual
related-files:
  - functions/src/triggers/onSessionCreated.ts
  - functions/src/ai-pipeline/layer1/layer1-service.ts
  - Sources/CameraFeature/Services/StorageService.swift
screenshots:
  - Screenshot 2026-01-18 at 7.13.50 PM.png
axiom-agent: null
branch: null
design-doc: null
implementation-plan: null
---

## Summary

Detection fails with "Unauthorized storage bucket" error preventing all object cataloging

## Description

When attempting to capture and detect objects, the app shows an "Analysis Failed" error with the message:

> Detection failed: Unauthorized storage bucket

This is a P0 blocking issue as it completely prevents the core functionality of the app - users cannot catalog any objects.

The error indicates that either:
1. The Cloud Function lacks permissions to access the GCS bucket
2. The iOS client is uploading to an unauthorized bucket
3. The service account doesn't have the required IAM roles
4. The bucket doesn't exist or has incorrect CORS/permissions

## Expected Behavior

1. User captures photo
2. Photo uploads to GCS temp bucket successfully
3. Cloud Function reads images from bucket
4. Gemini 3 Flash processes images
5. Detected objects returned to client

## Actual Behavior

1. User captures photo
2. Upload may succeed (unclear from error)
3. Detection fails with "Unauthorized storage bucket"
4. Error shown to user, no objects detected

## Technical Context

- Device: iPhone 16e (w-16e)
- iOS: 26
- Source: manual
- Error message: "Detection failed: Unauthorized storage bucket"

### GCS Bucket Configuration (from plan)

```
gs://abundance-temp/     # Auto-delete after 24h - for original uploads
gs://abundance-items/    # Permanent storage - for cropped objects
```

### Required IAM Permissions

Cloud Function service account needs:
- `roles/storage.objectViewer` on abundance-temp bucket
- `roles/storage.objectCreator` on abundance-items bucket

### Debugging Steps

1. Check Cloud Function logs for detailed error
2. Verify bucket exists: `gsutil ls gs://abundance-temp/`
3. Check service account: `gcloud functions describe onSessionCreated`
4. Verify IAM bindings on buckets
5. Check if CORS is blocking client uploads
6. Verify Firebase Storage rules if using Firebase Storage

## Proposed Solution

1. **Immediate**: Check Cloud Logging for the actual error details
2. **Verify buckets exist**:
   ```bash
   gsutil ls gs://abundance-temp/
   gsutil ls gs://abundance-items/
   ```
3. **Check/fix IAM permissions**:
   ```bash
   gsutil iam get gs://abundance-temp/
   gsutil iam ch serviceAccount:PROJECT_ID@appspot.gserviceaccount.com:objectViewer gs://abundance-temp/
   ```
4. **If using Firebase Storage**: Check security rules allow authenticated writes
5. **Verify Cloud Function deployment**: Ensure latest code is deployed with correct environment variables
