# Layer 1 Code Review Remediation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Address all critical and important issues identified in the iOS and Backend code reviews for the Gemini Layer 1 Capture Redesign.

**Architecture:** Parallel remediation across iOS (Swift 6) and Backend (TypeScript Cloud Functions) with domain-specific agents. iOS fixes focus on Swift Concurrency and accessibility; Backend fixes focus on security and reliability.

**Tech Stack:** Swift 6 / SwiftUI (iOS), TypeScript / Firebase Functions (Backend), Gemini 3 Flash API

---

## Parallel Execution Strategy

### Agent Deployment Matrix

| Track | Agent/Skill | Tasks | Can Run In Parallel |
|-------|-------------|-------|---------------------|
| **iOS-Critical** | `ios-superpowers` + `axiom:concurrency-auditor` | Task 1 | Yes (with Backend-Critical) |
| **Backend-Critical** | `backend-superpowers` | Tasks 2-4 | Yes (with iOS-Critical) |
| **iOS-Important** | `ios-superpowers` + `axiom:accessibility-auditor` | Tasks 5-7 | Yes (with Backend-Important) |
| **Backend-Important** | `backend-superpowers` + `gemini-integration` | Tasks 8-10 | Yes (with iOS-Important) |
| **Testing** | `axiom:test-runner` + `backend-superpowers` | Tasks 11-12 | Sequential (after fixes) |

### Execution Phases

```
Phase 1 (Parallel):
├── iOS-Critical (Task 1)
└── Backend-Critical (Tasks 2, 3, 4)

Phase 2 (Parallel):
├── iOS-Important (Tasks 5, 6, 7)
└── Backend-Important (Tasks 8, 9, 10)

Phase 3 (Sequential):
├── iOS Tests (Task 11)
└── Backend Tests (Task 12)
```

---

## Phase 1: Critical Fixes (Parallel Deployment)

---

### Task 1: Replace Timer with Task-based Burst Capture Loop (iOS-Critical)

**Agent:** `ios-superpowers debug "Swift concurrency Timer replacement"`
**Skills:** `axiom-swift-concurrency`

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift:134-160`
- Test: `Tests/CameraFeatureTests/CaptureSessionViewModelTests.swift` (create if missing)

**Step 1: Write the failing test**

```swift
// Tests/CameraFeatureTests/CaptureSessionViewModelTests.swift
import XCTest
@testable import CameraFeature

@MainActor
final class CaptureSessionViewModelTests: XCTestCase {

    func testBurstCaptureUsesStructuredConcurrency() async throws {
        let viewModel = CaptureSessionViewModel()
        var captureCount = 0

        let capturePhoto: @Sendable () async throws -> Data = {
            captureCount += 1
            return Data([0x00, 0x01, 0x02])
        }

        // Start burst
        viewModel.startBurstCapture(capturePhoto: capturePhoto)

        // Wait for 3 captures (0.5s interval × 3 = 1.5s + buffer)
        try await Task.sleep(for: .milliseconds(1700))

        // End burst
        viewModel.endBurstCapture()

        // Should have captured 3-4 photos
        XCTAssertGreaterThanOrEqual(captureCount, 3)
        XCTAssertLessThanOrEqual(captureCount, 4)

        // Verify no Timer leaks - burstTask should be nil after end
        XCTAssertNil(viewModel.burstTask)
    }

    func testBurstCaptureCancellation() async throws {
        let viewModel = CaptureSessionViewModel()
        var captureCount = 0

        let capturePhoto: @Sendable () async throws -> Data = {
            captureCount += 1
            try await Task.sleep(for: .milliseconds(100))
            return Data([0x00])
        }

        viewModel.startBurstCapture(capturePhoto: capturePhoto)

        // Cancel immediately
        try await Task.sleep(for: .milliseconds(200))
        viewModel.cancelBurstCapture()

        let countAfterCancel = captureCount

        // Wait to ensure no more captures happen
        try await Task.sleep(for: .milliseconds(600))

        XCTAssertEqual(captureCount, countAfterCancel, "Captures should stop after cancellation")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CaptureSessionViewModelTests`
Expected: FAIL - `burstTask` property doesn't exist

**Step 3: Replace Timer with Task-based loop**

```swift
// Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift

// Replace these properties (around line 55-58):
// OLD:
// private var burstTimer: Timer?

// NEW:
/// Task handle for burst capture loop - uses structured concurrency
public private(set) var burstTask: Task<Void, Never>?

// Replace startBurstCapture method (around line 134-160):
public func startBurstCapture(capturePhoto: @escaping @Sendable () async throws -> Data) {
    guard uiState == .idle else { return }

    isCapturing = true
    burstStartTime = Date()
    capturedPhotos = []
    burstCount = 0
    uiState = .capturing

    // Use Task-based loop instead of Timer for Swift Concurrency compliance
    burstTask = Task { @MainActor [weak self] in
        guard let self = self else { return }

        while !Task.isCancelled && self.isCapturing && self.capturedPhotos.count < 8 {
            await self.captureBurstPhoto(capturePhoto: capturePhoto)

            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                // Task was cancelled
                break
            }
        }

        // Auto-end if max photos reached
        if self.capturedPhotos.count >= 8 && self.isCapturing {
            self.endBurstCapture()
        }
    }
}

// Update cancelBurstCapture (around line 225-235):
public func cancelBurstCapture() {
    burstTask?.cancel()
    burstTask = nil
    cleanupCapture()
    uiState = .idle
}

// Update endBurstCapture to cancel task (around line 170-195):
public func endBurstCapture() {
    burstTask?.cancel()
    burstTask = nil

    guard isCapturing else { return }
    isCapturing = false

    // ... rest of existing endBurstCapture logic
}

// Update cleanupCapture (around line 346-353):
private func cleanupCapture() {
    capturedPhotos = []
    burstCount = 0
    burstStartTime = nil
    burstTask?.cancel()
    burstTask = nil
    lastCapturedPhoto = nil
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter CaptureSessionViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift Tests/CameraFeatureTests/CaptureSessionViewModelTests.swift
git commit -m "fix(ios): replace Timer with Task-based burst capture loop

Addresses Swift 6 concurrency compliance by using structured
concurrency (Task) instead of Timer for burst capture intervals.
This eliminates potential race conditions and ensures proper
cancellation propagation.

Fixes: Critical issue from code review"
```

---

### Task 2: Add userId Validation in Firestore Trigger (Backend-Critical)

**Agent:** `backend-superpowers`
**Skills:** Firebase MCP tools for verification

**Files:**
- Modify: `functions/src/triggers/onSessionCreated.ts:80-120`
- Test: `functions/src/triggers/__tests__/onSessionCreated.test.ts` (create)

**Step 1: Write the failing test**

```typescript
// functions/src/triggers/__tests__/onSessionCreated.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock firebase-admin
vi.mock('firebase-admin', () => ({
  initializeApp: vi.fn(),
  firestore: vi.fn(() => ({
    collection: vi.fn(() => ({
      doc: vi.fn(() => ({
        get: vi.fn(),
        update: vi.fn()
      }))
    }))
  })),
  storage: vi.fn(() => ({
    bucket: vi.fn()
  }))
}));

describe('onSessionCreated trigger', () => {
  describe('userId validation', () => {
    it('should reject session with missing userId', async () => {
      const mockSessionRef = {
        update: vi.fn().mockResolvedValue(undefined)
      };

      const afterData = {
        status: 'uploading',
        originalImageUrls: ['gs://bucket/image.jpg'],
        // userId intentionally missing
      };

      // Import after mocks are set up
      const { validateSessionDocument } = await import('../onSessionCreated');

      const result = await validateSessionDocument(afterData, mockSessionRef);

      expect(result.valid).toBe(false);
      expect(result.errorCode).toBe('INVALID_DOCUMENT');
      expect(mockSessionRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed',
          errorCode: 'INVALID_DOCUMENT'
        })
      );
    });

    it('should reject session with empty userId', async () => {
      const mockSessionRef = {
        update: vi.fn().mockResolvedValue(undefined)
      };

      const afterData = {
        status: 'uploading',
        originalImageUrls: ['gs://bucket/image.jpg'],
        userId: ''
      };

      const { validateSessionDocument } = await import('../onSessionCreated');

      const result = await validateSessionDocument(afterData, mockSessionRef);

      expect(result.valid).toBe(false);
      expect(result.errorCode).toBe('INVALID_DOCUMENT');
    });

    it('should accept session with valid userId', async () => {
      const afterData = {
        status: 'uploading',
        originalImageUrls: ['gs://bucket/image.jpg'],
        userId: 'user123'
      };

      const { validateSessionDocument } = await import('../onSessionCreated');

      const result = await validateSessionDocument(afterData, {} as any);

      expect(result.valid).toBe(true);
    });
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --grep "userId validation"`
Expected: FAIL - `validateSessionDocument` not exported

**Step 3: Add validation function**

```typescript
// functions/src/triggers/onSessionCreated.ts

// Add after imports (around line 10):
export interface ValidationResult {
  valid: boolean;
  errorCode?: string;
  errorMessage?: string;
}

// Add validation function (around line 75, before the main trigger):
export async function validateSessionDocument(
  sessionData: Record<string, unknown>,
  sessionRef: FirebaseFirestore.DocumentReference
): Promise<ValidationResult> {
  // Validate userId exists and is a non-empty string
  if (!sessionData.userId || typeof sessionData.userId !== 'string' || sessionData.userId.trim() === '') {
    console.error('Session validation failed: Invalid or missing userId');
    await sessionRef.update({
      status: 'failed',
      error: 'Invalid session document: missing userId',
      errorCode: 'INVALID_DOCUMENT',
      failedAt: FieldValue.serverTimestamp()
    });
    return { valid: false, errorCode: 'INVALID_DOCUMENT', errorMessage: 'Missing userId' };
  }

  // Validate originalImageUrls exists and is non-empty array
  if (!Array.isArray(sessionData.originalImageUrls) || sessionData.originalImageUrls.length === 0) {
    console.error('Session validation failed: No images provided');
    await sessionRef.update({
      status: 'failed',
      error: 'No images provided',
      errorCode: 'NO_IMAGES',
      failedAt: FieldValue.serverTimestamp()
    });
    return { valid: false, errorCode: 'NO_IMAGES', errorMessage: 'No images provided' };
  }

  // Validate all URLs are from allowed buckets
  const allowedBuckets = ['abundance-temp', 'abundance-dev-temp', 'abundance-staging-temp'];
  for (const url of sessionData.originalImageUrls as string[]) {
    const bucketMatch = url.match(/gs:\/\/([^/]+)\//);
    if (!bucketMatch || !allowedBuckets.some(b => bucketMatch[1].includes(b))) {
      console.error(`Session validation failed: Unauthorized bucket in URL: ${url}`);
      await sessionRef.update({
        status: 'failed',
        error: 'Unauthorized storage bucket',
        errorCode: 'UNAUTHORIZED_BUCKET',
        failedAt: FieldValue.serverTimestamp()
      });
      return { valid: false, errorCode: 'UNAUTHORIZED_BUCKET', errorMessage: 'Unauthorized bucket' };
    }
  }

  return { valid: true };
}

// Update the main trigger to use validation (around line 100-115):
// Add after the status check:
const validationResult = await validateSessionDocument(afterData, sessionRef);
if (!validationResult.valid) {
  console.error(`Session ${sessionId}: Validation failed - ${validationResult.errorCode}`);
  return;
}
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- --grep "userId validation"`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/triggers/onSessionCreated.ts functions/src/triggers/__tests__/onSessionCreated.test.ts
git commit -m "fix(backend): add userId and bucket validation to session trigger

Validates session documents before processing:
- userId must be non-empty string
- originalImageUrls must be non-empty array
- All URLs must reference allowed storage buckets

Fixes: Critical security issue from code review"
```

---

### Task 3: Replace makePublic with Signed URLs (Backend-Critical)

**Agent:** `backend-superpowers`
**Skills:** GCS MCP tools

**Files:**
- Modify: `functions/src/ai-pipeline/layer1/layer1-service.ts:290-310`

**Step 1: Write the failing test**

```typescript
// functions/src/ai-pipeline/layer1/__tests__/layer1-service.test.ts
import { describe, it, expect, vi } from 'vitest';

describe('cropAndSaveObjects', () => {
  it('should generate signed URLs instead of public URLs', async () => {
    const mockFile = {
      save: vi.fn().mockResolvedValue(undefined),
      getSignedUrl: vi.fn().mockResolvedValue(['https://storage.googleapis.com/signed-url']),
      makePublic: vi.fn() // Should NOT be called
    };

    const mockBucket = {
      file: vi.fn().mockReturnValue(mockFile)
    };

    // Test that makePublic is not called and getSignedUrl is used
    // Implementation in Step 3
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --grep "signed URLs"`
Expected: FAIL

**Step 3: Replace makePublic with getSignedUrl**

```typescript
// functions/src/ai-pipeline/layer1/layer1-service.ts

// Update the crop save section (around line 290-310):
// OLD:
// await file.makePublic();
// const publicUrl = `https://storage.googleapis.com/${bucket.name}/${cropPath}`;
// croppedUrls.push(publicUrl);

// NEW:
// Generate signed URL with 24-hour expiration (matches temp bucket lifecycle)
const [signedUrl] = await file.getSignedUrl({
  action: 'read',
  expires: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
  version: 'v4'
});
croppedUrls.push(signedUrl);

console.log(`Saved crop with signed URL: ${cropPath}`);
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- --grep "signed URLs"`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/layer1/layer1-service.ts functions/src/ai-pipeline/layer1/__tests__/layer1-service.test.ts
git commit -m "fix(backend): use signed URLs instead of makePublic for crops

Replace file.makePublic() with getSignedUrl() to prevent
unauthorized access to user inventory images. URLs expire
after 24 hours, matching temp bucket lifecycle.

Fixes: Important security issue from code review"
```

---

### Task 4: Implement Retry Logic for Gemini API (Backend-Critical)

**Agent:** `backend-superpowers`
**Skills:** `gemini-integration`

**Files:**
- Modify: `functions/src/ai-pipeline/layer1/layer1-service.ts:168-211`
- Reference: `docs/skills/gemini-integration.md` for retry patterns

**Step 1: Write the failing test**

```typescript
// functions/src/ai-pipeline/layer1/__tests__/layer1-service.test.ts

describe('callGeminiFlashWithRetry', () => {
  it('should retry on transient failure', async () => {
    let attempts = 0;
    const mockGenerate = vi.fn().mockImplementation(async () => {
      attempts++;
      if (attempts < 2) {
        throw new Error('UNAVAILABLE: Service temporarily unavailable');
      }
      return { text: '{"objects": []}' };
    });

    // Mock the Gemini client
    vi.mock('@google/genai', () => ({
      GoogleGenAI: vi.fn(() => ({
        getGenerativeModel: vi.fn(() => ({
          generateContent: mockGenerate
        }))
      }))
    }));

    const { callGeminiFlashWithRetry } = await import('../layer1-service');

    const result = await callGeminiFlashWithRetry(['base64image']);

    expect(attempts).toBe(2);
    expect(result.objects).toEqual([]);
  });

  it('should fail after max retries exceeded', async () => {
    const mockGenerate = vi.fn().mockRejectedValue(new Error('UNAVAILABLE'));

    vi.mock('@google/genai', () => ({
      GoogleGenAI: vi.fn(() => ({
        getGenerativeModel: vi.fn(() => ({
          generateContent: mockGenerate
        }))
      }))
    }));

    const { callGeminiFlashWithRetry } = await import('../layer1-service');

    await expect(callGeminiFlashWithRetry(['base64image'])).rejects.toThrow('UNAVAILABLE');
    expect(mockGenerate).toHaveBeenCalledTimes(3); // Initial + 2 retries
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --grep "callGeminiFlashWithRetry"`
Expected: FAIL - function doesn't exist

**Step 3: Implement retry wrapper**

```typescript
// functions/src/ai-pipeline/layer1/layer1-service.ts

// Add after imports (around line 15):
const RETRYABLE_ERROR_CODES = [
  'UNAVAILABLE',
  'DEADLINE_EXCEEDED',
  'RESOURCE_EXHAUSTED',
  'INTERNAL',
  'UNKNOWN'
];

function isRetryableError(error: Error): boolean {
  return RETRYABLE_ERROR_CODES.some(code => error.message.includes(code));
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Add retry wrapper (around line 165):
export async function callGeminiFlashWithRetry(
  imageBase64s: string[],
  maxRetries: number = LAYER1_TIMEOUTS.GEMINI_FLASH_MAX_RETRIES
): Promise<Layer1DetectionResponse> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await callGeminiFlash(imageBase64s);
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      // Don't retry non-retryable errors
      if (!isRetryableError(lastError)) {
        console.error(`Gemini Flash non-retryable error: ${lastError.message}`);
        throw lastError;
      }

      console.warn(`Gemini Flash attempt ${attempt + 1}/${maxRetries + 1} failed: ${lastError.message}`);

      if (attempt < maxRetries) {
        // Exponential backoff: 1s, 2s, 4s
        const backoffMs = 1000 * Math.pow(2, attempt);
        console.log(`Retrying in ${backoffMs}ms...`);
        await sleep(backoffMs);
      }
    }
  }

  throw lastError ?? new Error('Gemini Flash failed with unknown error');
}

// Update detectObjectsInImages to use retry wrapper (around line 90):
// OLD: const detectionResult = await callGeminiFlash(imageBase64s);
// NEW:
const detectionResult = await callGeminiFlashWithRetry(imageBase64s);
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- --grep "callGeminiFlashWithRetry"`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/layer1/layer1-service.ts functions/src/ai-pipeline/layer1/__tests__/layer1-service.test.ts
git commit -m "fix(backend): add retry logic for Gemini Flash API calls

Implements exponential backoff retry for transient errors:
- UNAVAILABLE, DEADLINE_EXCEEDED, RESOURCE_EXHAUSTED, INTERNAL, UNKNOWN
- Max 2 retries with 1s, 2s, 4s backoff
- Non-retryable errors fail immediately

Fixes: Important reliability issue from code review"
```

---

## Phase 2: Important Fixes (Parallel Deployment)

---

### Task 5: Add Accessibility Announcements for Burst Count (iOS-Important)

**Agent:** `ios-superpowers debug "accessibility VoiceOver announcements"`
**Skills:** `axiom:accessibility-auditor`, `axiom-accessibility-diag`

**Files:**
- Modify: `Sources/CameraFeature/Views/CaptureOverlays.swift:11-24`

**Step 1: Write the failing test**

```swift
// Tests/CameraFeatureTests/CaptureOverlaysAccessibilityTests.swift
import XCTest
import SwiftUI
@testable import CameraFeature

final class CaptureOverlaysAccessibilityTests: XCTestCase {

    func testCaptureOverlayHasAccessibilityLabel() throws {
        let overlay = CaptureOverlay(photoCount: 3)

        // Use ViewInspector or manual inspection
        // The view should have an accessibility label
        XCTAssertNotNil(overlay.body)
    }
}
```

**Step 2: Run test to verify baseline**

Run: `swift test --filter CaptureOverlaysAccessibilityTests`

**Step 3: Add accessibility announcements**

```swift
// Sources/CameraFeature/Views/CaptureOverlays.swift

// Update CaptureOverlay struct (around line 11-24):
struct CaptureOverlay: View {
    let photoCount: Int
    @State private var previousCount: Int = 0

    var body: some View {
        VStack {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)

            Text("\(photoCount) photos")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Burst capture: \(photoCount) photos")
        .accessibilityAddTraits(.updatesFrequently)
        .onChange(of: photoCount) { oldValue, newValue in
            // Announce count changes for VoiceOver users
            if newValue > oldValue {
                let announcement = newValue == 1
                    ? "1 photo captured"
                    : "\(newValue) photos captured"
                AccessibilityNotification.Announcement(announcement).post()
            }
        }
        .onAppear {
            previousCount = photoCount
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter CaptureOverlaysAccessibilityTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CameraFeature/Views/CaptureOverlays.swift Tests/CameraFeatureTests/CaptureOverlaysAccessibilityTests.swift
git commit -m "fix(ios): add VoiceOver announcements for burst photo count

Posts AccessibilityNotification.Announcement when photo count
increases during burst capture, allowing VoiceOver users to
track capture progress.

Fixes: Important accessibility issue from code review"
```

---

### Task 6: Document nonisolated(unsafe) Usage (iOS-Important)

**Agent:** `ios-superpowers debug "Swift concurrency nonisolated unsafe"`
**Skills:** `axiom-swift-concurrency`

**Files:**
- Modify: `Sources/CameraFeature/Services/SessionService.swift:36`
- Modify: `Sources/CameraFeature/Services/CatalogService.swift:30`

**Step 1: Add documentation comments**

```swift
// Sources/CameraFeature/Services/SessionService.swift (around line 34-40):

/// Firestore database reference.
///
/// SAFETY: Marked `nonisolated(unsafe)` because:
/// 1. Firestore is documented as thread-safe (https://firebase.google.com/docs/firestore/manage-data/enable-offline#configure_offline_persistence)
/// 2. All Firestore operations are internally synchronized
/// 3. We only perform read/write operations, never mutate the reference itself
/// 4. This pattern is recommended by Firebase for Swift 6 compatibility
///
/// If Firebase SDK changes threading guarantees in future versions,
/// this should be wrapped in an actor.
nonisolated(unsafe) private let db: Firestore
```

```swift
// Sources/CameraFeature/Services/CatalogService.swift (around line 28-35):

/// Firestore database reference.
///
/// SAFETY: Marked `nonisolated(unsafe)` because Firestore is thread-safe.
/// See SessionService.swift for detailed rationale.
nonisolated(unsafe) private let db: Firestore
```

**Step 2: Commit**

```bash
git add Sources/CameraFeature/Services/SessionService.swift Sources/CameraFeature/Services/CatalogService.swift
git commit -m "docs(ios): document nonisolated(unsafe) Firestore usage

Adds safety documentation explaining why nonisolated(unsafe)
is acceptable for Firestore references (thread-safe SDK).

Fixes: Important documentation issue from code review"
```

---

### Task 7: Improve Burst Error Handling (iOS-Important)

**Agent:** `ios-superpowers debug "error handling burst capture"`
**Skills:** `axiom-swiftui-architecture`

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift:212-223`

**Step 1: Write the failing test**

```swift
// Tests/CameraFeatureTests/CaptureSessionViewModelTests.swift

func testBurstCaptureAccumulatesErrors() async throws {
    let viewModel = CaptureSessionViewModel()
    var callCount = 0

    let capturePhoto: @Sendable () async throws -> Data = {
        callCount += 1
        if callCount == 2 {
            throw CaptureError.captureFailed(underlying: NSError(domain: "test", code: 1))
        }
        return Data([0x00, 0x01])
    }

    viewModel.startBurstCapture(capturePhoto: capturePhoto)

    try await Task.sleep(for: .milliseconds(1700))

    viewModel.endBurstCapture()

    // Should have captured photos despite one failure
    XCTAssertEqual(viewModel.capturedPhotos.count, 2) // 3 attempts, 1 failed
    XCTAssertEqual(viewModel.burstErrors.count, 1)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter testBurstCaptureAccumulatesErrors`
Expected: FAIL - `burstErrors` doesn't exist

**Step 3: Add error accumulation**

```swift
// Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift

// Add property (around line 48):
@Published public var burstErrors: [CaptureError] = []

// Update captureBurstPhoto (around line 212-223):
private func captureBurstPhoto(capturePhoto: @escaping @Sendable () async throws -> Data) async {
    do {
        let photoData = try await capturePhoto()
        capturedPhotos.append(photoData)
        burstCount = capturedPhotos.count
        lastCapturedPhoto = photoData
        logger.debug("Burst photo captured: \(self.burstCount)")
    } catch {
        let captureError: CaptureError
        if let ce = error as? CaptureError {
            captureError = ce
        } else {
            captureError = .captureFailed(underlying: error)
        }

        burstErrors.append(captureError)
        logger.error("Failed to capture burst photo: \(error.localizedDescription)")

        // Stop burst if we hit 3 consecutive errors
        if burstErrors.count >= 3 {
            logger.error("Too many burst capture failures, stopping burst")
            endBurstCapture()
        }
    }
}

// Update cleanupCapture (around line 346-353):
private func cleanupCapture() {
    capturedPhotos = []
    burstCount = 0
    burstStartTime = nil
    burstTask?.cancel()
    burstTask = nil
    lastCapturedPhoto = nil
    burstErrors = [] // Clear errors on cleanup
}

// Update endBurstCapture to report accumulated errors (around line 185):
public func endBurstCapture() {
    burstTask?.cancel()
    burstTask = nil

    guard isCapturing else { return }
    isCapturing = false

    // Log accumulated errors if any
    if !burstErrors.isEmpty {
        logger.warning("Burst completed with \(self.burstErrors.count) capture errors")
    }

    // ... rest of existing logic
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter testBurstCaptureAccumulatesErrors`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift Tests/CameraFeatureTests/CaptureSessionViewModelTests.swift
git commit -m "fix(ios): accumulate and handle burst capture errors

- Track individual capture failures in burstErrors array
- Stop burst after 3 consecutive failures
- Log warnings when burst completes with errors
- Clear errors on cleanup

Fixes: Important error handling issue from code review"
```

---

### Task 8: Verify Gemini Thinking Config Casing (Backend-Important)

**Agent:** `backend-superpowers`
**Skills:** `gemini-integration`

**Files:**
- Verify: `functions/src/ai-pipeline/layer1/prompts.ts:52-61`
- Reference: `@google/genai` SDK documentation

**Step 1: Check SDK documentation**

```bash
# Check the @google/genai types
cd functions && grep -r "thinkingConfig\|thinking_config" node_modules/@google/genai/
```

**Step 2: Verify or update casing**

```typescript
// functions/src/ai-pipeline/layer1/prompts.ts

// The @google/genai SDK uses camelCase for JavaScript/TypeScript
// Verify this matches the SDK's GenerationConfig type

// If SDK uses snake_case, update to:
export const LAYER1_GENERATION_CONFIG = {
  responseMimeType: 'application/json',
  responseSchema: LAYER1_RESPONSE_SCHEMA,
  // Verify with SDK types - use correct casing
  thinkingConfig: {  // or thinking_config based on SDK
    thinkingLevel: ThinkingLevel.LOW  // or thinking_level
  }
};
```

**Step 3: Add type import for verification**

```typescript
// Add explicit type import to catch mismatches at compile time
import { GenerationConfig } from '@google/genai';

export const LAYER1_GENERATION_CONFIG: GenerationConfig = {
  // TypeScript will error if properties don't match SDK types
};
```

**Step 4: Commit**

```bash
git add functions/src/ai-pipeline/layer1/prompts.ts
git commit -m "fix(backend): verify thinking config property casing with SDK types

Adds explicit GenerationConfig type import to ensure compile-time
verification of property names against @google/genai SDK.

Fixes: Important configuration issue from code review"
```

---

### Task 9: Add Structured Logging (Backend-Important)

**Agent:** `backend-superpowers`

**Files:**
- Modify: `functions/src/triggers/onSessionCreated.ts`
- Modify: `functions/src/ai-pipeline/layer1/layer1-service.ts`

**Step 1: Update imports and logging**

```typescript
// functions/src/triggers/onSessionCreated.ts

// Replace console.log/error with structured logging
import * as logger from 'firebase-functions/logger';

// Replace throughout the file:
// OLD: console.log(`Processing session ${sessionId}`);
// NEW:
logger.info('Processing session', {
  sessionId,
  captureMode: afterData.captureMode,
  imageCount: afterData.originalImageUrls.length
});

// OLD: console.error(`Session ${sessionId} failed:`, error);
// NEW:
logger.error('Session processing failed', {
  sessionId,
  error: error instanceof Error ? error.message : String(error),
  errorCode: 'PROCESSING_FAILED'
});
```

```typescript
// functions/src/ai-pipeline/layer1/layer1-service.ts

import * as logger from 'firebase-functions/logger';

// Replace console.log/error throughout
```

**Step 2: Commit**

```bash
git add functions/src/triggers/onSessionCreated.ts functions/src/ai-pipeline/layer1/layer1-service.ts
git commit -m "refactor(backend): use structured logging for Cloud Functions

Replace console.log/error with firebase-functions/logger for
better observability in Cloud Logging with structured data.

Fixes: Suggestion from code review"
```

---

### Task 10: Add Timeout Enforcement for Image Fetching (Backend-Important)

**Agent:** `backend-superpowers`

**Files:**
- Modify: `functions/src/ai-pipeline/layer1/layer1-service.ts:131-163`

**Step 1: Add timeout wrapper**

```typescript
// functions/src/ai-pipeline/layer1/layer1-service.ts

// Add timeout utility (around line 25):
function withTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number,
  errorMessage: string
): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) => {
      setTimeout(() => reject(new Error(errorMessage)), timeoutMs);
    })
  ]);
}

// Update fetchImageFromGCS (around line 131-163):
async function fetchImageFromGCS(gcsUrl: string, storage: Storage): Promise<string> {
  const fetchPromise = (async () => {
    // ... existing fetch logic
  })();

  return withTimeout(
    fetchPromise,
    LAYER1_TIMEOUTS.IMAGE_FETCH_TIMEOUT_MS,
    `Image fetch timeout: ${gcsUrl}`
  );
}
```

**Step 2: Commit**

```bash
git add functions/src/ai-pipeline/layer1/layer1-service.ts
git commit -m "fix(backend): enforce timeout on GCS image fetching

Adds withTimeout wrapper to fetchImageFromGCS to prevent
hanging on slow network or large images.

Fixes: Suggestion from code review"
```

---

## Phase 3: Testing (Sequential)

---

### Task 11: Run iOS Test Suite

**Agent:** `axiom:test-runner`

**Step 1: Run all CameraFeature tests**

Run: `swift test --filter CameraFeature`
Expected: All PASS

**Step 2: Run accessibility audit**

```bash
/axiom:audit accessibility
```

**Step 3: Run concurrency audit**

```bash
/axiom:audit concurrency
```

**Step 4: Commit test results**

If tests pass, no commit needed. If fixes required, address them first.

---

### Task 12: Run Backend Test Suite and Deploy

**Agent:** `backend-superpowers`

**Step 1: Run all function tests**

Run: `cd functions && npm test`
Expected: All PASS

**Step 2: Type check**

Run: `cd functions && npm run build`
Expected: No errors

**Step 3: Deploy to staging**

```bash
firebase deploy --only functions --project abundance-staging
```

**Step 4: Verify deployment**

```bash
# Check function logs
firebase functions:log --project abundance-staging

# Use MCP to verify
mcp__plugin_firebase_firebase__functions_get_logs
```

**Step 5: Final commit**

```bash
git add .
git commit -m "chore: layer1 code review remediation complete

All critical and important issues from iOS and Backend
code reviews have been addressed:

iOS:
- Task-based burst capture (Swift Concurrency)
- Accessibility announcements
- Error accumulation
- Documentation

Backend:
- UserId validation
- Signed URLs
- Retry logic
- Structured logging
- Timeout enforcement

Tested and deployed to staging."
```

---

## Verification Checklist

After all tasks complete:

- [ ] `swift test` passes
- [ ] `cd functions && npm test` passes
- [ ] `cd functions && npm run build` succeeds
- [ ] No `@MainActor` warnings in Xcode
- [ ] VoiceOver announces burst count changes
- [ ] Crop URLs are signed (not public)
- [ ] Retry logic fires on Gemini errors
- [ ] Structured logs appear in Cloud Logging

---

## References

- Original Plan: `docs/plans/2026-01-16-gemini-layer1-capture-redesign.md`
- iOS Code Review: Agent a4a15ec
- Backend Code Review: Agent a003465
- Gemini Integration Skill: `gemini-integration`
