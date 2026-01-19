# Brainstorm: Burst Mode Evolution & Duplicate Detection

> **For Claude:** Use `superpowers:brainstorming` skill to explore these questions.

**Date:** 2026-01-18
**Context:** Session persistence (SPEC-PIPE-003) is now implemented. Questions arise about how it interacts with burst capture and whether we need object fingerprinting for duplicate detection.

---

## Background Context

### Current Implementation

| Component | Status | Spec Reference |
|-----------|--------|----------------|
| Burst Capture | **Implemented** | SPEC-UI-001 §2.2, §3 |
| Session Persistence | **Implemented** | SPEC-PIPE-003 |
| Context Caching | **Implemented** | SPEC-PIPE-003 §Component B |
| Object Fingerprinting | **Not Implemented** | SPEC-LAYER1-LAYER2-ARCHITECTURE (deprecated) mentions VNFeaturePrint |
| Duplicate Detection | **Not Implemented** | Not specified |

### Current Burst Mode Design (SPEC-UI-001)

- **Intent:** Capture same object from multiple angles
- **Parameters:** 8 photos max, 0.5s intervals, 4s max duration
- **Processing:** All photos sent as batch to Layer 1 (Gemini Flash)
- **Grouping:** Model assigns same `groupId` to same object across images

### Current Session Persistence Design (SPEC-PIPE-003)

- **Scope:** Per-item history at `items/{itemId}/catalogHistory/{entryId}`
- **Purpose:** Provide context for re-cataloging same item, reduce API costs
- **Trigger:** `processItemWithGeminiPersistent(imageUrl, itemId)`
- **Limitation:** Requires knowing `itemId` upfront—no cross-item deduplication

---

## Questions to Explore

### Theme 1: Burst Mode Use Cases

**Q1.1:** The current burst mode is designed for "same object, multiple angles" (SPEC-UI-001 §2.2). What changes are needed to support **"pan across bookshelf"** (multiple distinct objects in sequence)?

- Should this be a separate capture mode (e.g., `scan` vs `burst`)?
- How does Layer 1 groupId assignment change when detecting multiple distinct objects?
- What are the UX implications (different gesture? different feedback?)?

**Q1.2:** How should burst mode photos be associated with items?

- Current: All photos → single session → grouped by `groupId` → one item per group
- Bookshelf scan: All photos → single session → N distinct objects → N items
- Does the current architecture support this, or does it assume 1 primary object?

### Theme 2: Session Persistence × Burst Mode Interaction

**Q2.1:** How does `processItemWithGeminiPersistent()` behave when burst mode captures **multiple distinct objects**?

- Current implementation stores history per `itemId`
- If burst creates 5 items, each gets its own `catalogHistory` subcollection
- Is this the right behavior, or should there be session-level history?

**Q2.2:** How does context caching work with burst mode?

- The cached system prompt + tools are reused across all items in a session
- ✅ This seems correct—no changes needed
- Confirm: Is the cache shared across the batch, or recreated per item?

**Q2.3:** What happens when user adds a **new photo to existing item** (same object, better angle)?

- User catalogs item → moves it to better lighting → takes another photo
- How does the app know to associate new photo with existing item vs. create new item?
- Current flow: New photo → new session → new item (no association)

### Theme 3: Object Fingerprinting

**Q3.1:** What is object fingerprinting and is it implemented?

- **Deprecated spec reference:** SPEC-LAYER1-LAYER2-ARCHITECTURE mentions `fingerprints: [fp1, fp2, fp3]` using iOS `VNFeaturePrint` hashes
- **Current status:** Not implemented in active specs or codebase
- **Purpose:** Cross-session deduplication—identify if object was previously catalogued

**Q3.2:** How would fingerprinting work technically?

- iOS captures photo → generates `VNFeaturePrint` hash client-side
- Hash sent with image to Layer 1
- Layer 1 (or separate service) compares hash against existing items
- If similarity > threshold → potential duplicate

**Q3.3:** How would fingerprinting integrate with session persistence?

- Fingerprint lookup could happen before `processItemWithGeminiPersistent()`
- If match found: Pass existing `itemId` to get history context
- If no match: Create new item, no history context
- **Key insight:** Fingerprinting enables the "itemId lookup" that session persistence needs

### Theme 4: Duplicate Detection Scenarios

**Q4.1:** Scenario: User catalogs item, moves it, catalogs again (forgot it exists)

- Current behavior: Creates duplicate item with no warning
- Desired behavior: Detect potential duplicate, prompt user for review
- Implementation options:
  - Client-side: VNFeaturePrint comparison before upload
  - Server-side: Gemini-powered similarity check against user's inventory
  - Hybrid: Client filters obvious matches, server confirms

**Q4.2:** Scenario: Burst cuts off, user retakes with object repositioned

- User captures 3 photos, burst times out
- User moves object slightly, takes another photo
- Current behavior: Two separate sessions, potentially two items
- Desired behavior: Option to merge into single item

**Q4.3:** How should Gemini reason about duplicates?

- **Layer 1 approach:** After detection, query user's existing items by category/brand
- **Layer 2 approach:** During cataloging, search for similar items in user's inventory
- **Prompt injection:** "Before cataloging, check if this might match existing items: [list]"
- **Tool addition:** `check_existing_inventory(userId, category, brand?)` tool

### Theme 5: Update vs. Duplicate Disambiguation

**Q5.1:** How does the app distinguish intent?

| Scenario | User Intent | System Action |
|----------|-------------|---------------|
| Same object, new angle | Update existing | Add photo to item, re-catalog |
| Same object, forgot catalogued | Duplicate detected | Prompt: "Is this the same as [item]?" |
| Similar object, different instance | New item | Create new item |
| Exact same object class, different unit | New item | Create new item (e.g., 2 identical chairs) |

**Q5.2:** Does the distinction matter?

- **Argument for "doesn't matter":** Both cases prompt user review, user decides
- **Argument for "matters":** Different UI/UX, different default action
- **Proposed behavior:** Always prompt when potential match detected
  - "This looks similar to [existing item]. Is this:"
  - [ ] The same item (update existing)
  - [ ] A different item (create new)
  - [ ] Not sure (keep both, let me review later)

**Q5.3:** What metadata helps disambiguation?

- Location (if user grants permission)
- Time since last photo of similar item
- Exact fingerprint match vs. similar match
- User's historical behavior (do they often have multiples?)

### Theme 6: "Auto" Capture Mode (Smart Continuous Capture)

**Concept:** A new capture mode that automatically takes photos at regular intervals while the user pans across objects, but only captures when quality conditions are met.

#### Q6.1: Auto Mode Parameters

| Parameter | Proposed Value | Rationale |
|-----------|----------------|-----------|
| Capture interval | 1 second | Balance between coverage and processing |
| Max photos | 50-100 | Practical limit (Gemini 3 Flash supports 3,600) |
| Max duration | 60-120 seconds | Reasonable scan session |
| Quality gate | Must pass all checks | Only capture good frames |

**Gemini 3 Flash Limit:** 3,600 images per request (per spec), but practical/cost considerations suggest 50-100 max.

#### Q6.2: Quality Gates (iOS Sensor APIs)

**Gate 1: Motion Stability (CMMotionManager)**

```swift
// Detect if device is moving too fast
import CoreMotion

let motionManager = CMMotionManager()
motionManager.deviceMotionUpdateInterval = 0.1  // 10Hz sampling

// Check rotation rate and user acceleration
let isStable = abs(motion.rotationRate.x) < threshold &&
               abs(motion.rotationRate.y) < threshold &&
               abs(motion.userAcceleration.x) < threshold &&
               abs(motion.userAcceleration.y) < threshold
```

- **API:** `CMMotionManager.deviceMotion`
- **Metrics:** `rotationRate` (rad/s), `userAcceleration` (g)
- **Threshold:** TBD through testing (e.g., < 0.5 rad/s rotation)

**Gate 2: Blur Detection (Vision Framework)**

```swift
// Option A: VNDetectFaceLandmarksRequest has blur detection
// Option B: Use Laplacian variance on captured image
// Option C: AVCaptureDevice.isAdjustingFocus

import Vision

// Laplacian variance approach (higher = sharper)
func calculateBlurScore(image: CIImage) -> Double {
    let laplacianKernel = CIFilter(name: "CIConvolution3X3")
    // Apply kernel, calculate variance of result
    // Threshold: variance > 100 = acceptably sharp
}
```

- **Option A:** Check `AVCaptureDevice.isAdjustingFocus` — don't capture while focusing
- **Option B:** Laplacian variance on preview frame (compute-intensive)
- **Option C:** Use `AVCapturePhotoSettings.isAutoStillImageStabilizationEnabled`
- **Recommendation:** Start with Option A (simplest), add B if needed

**Gate 3: Light Level (AVCaptureDevice)**

```swift
import AVFoundation

let device = AVCaptureDevice.default(for: .video)

// Check current exposure/ISO
let iso = device?.iso ?? 0
let exposureDuration = device?.exposureDuration.seconds ?? 0
let isLowLight = iso > 800 || exposureDuration > 1/30

// Or use brightness from device
let brightness = device?.exposureTargetBias ?? 0  // EV adjustment
```

- **API:** `AVCaptureDevice` properties
- **Metrics:** ISO level, exposure duration, exposure bias
- **Threshold:** ISO > 800 or shutter > 1/30s = low light warning
- **Behavior:** Warn user, but allow capture (user decides)

#### Q6.3: Auto Mode State Machine

```
┌─────────┐  long-press 1s   ┌──────────────┐
│  idle   │─────────────────▶│ auto_standby │ (waiting for stability)
└─────────┘                   └──────┬───────┘
                                     │ stable + focused + adequate light
                                     ▼
                              ┌──────────────┐
                              │ auto_capture │◀─────┐
                              └──────┬───────┘      │ 1 second elapsed
                                     │              │ + quality gates pass
                                     │──────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
              user releases    max photos      quality gate fails
                    │          reached              │
                    ▼                │              ▼
             ┌───────────┐          │       ┌──────────────┐
             │ uploading │◀─────────┘       │ auto_paused  │
             └───────────┘                  └──────────────┘
                                                   │ quality restored
                                                   ▼
                                            (back to auto_capture)
```

#### Q6.4: UX Considerations

**Visual Feedback:**
- Photo count indicator (like burst mode)
- Quality status indicators:
  - 🟢 Green ring = capturing
  - 🟡 Yellow ring = paused (motion/blur/low light)
  - 🔴 Red pulse = quality gate failed
- "Slow down" haptic when moving too fast
- "Too dark" overlay when low light detected

**Audio Feedback:**
- Subtle shutter sound on each capture (can be disabled)
- Different tone when paused vs capturing

**Gesture Options:**
- **Option A:** Long-press 1s to start, release to stop (like burst but longer hold)
- **Option B:** Double-tap to toggle on/off (hands-free scanning)
- **Option C:** Dedicated "Scan" button in UI

#### Q6.5: Auto Mode vs. Burst Mode Comparison

| Aspect | Burst Mode | Auto Mode |
|--------|------------|-----------|
| **Intent** | Same object, multiple angles | Multiple objects, panning |
| **Trigger** | Long-press hold | Long-press 1s or toggle |
| **Interval** | 0.5 seconds | 1.0 second |
| **Max photos** | 8 | 50-100 |
| **Max duration** | 4 seconds | 60-120 seconds |
| **Quality gates** | None | Motion, blur, light |
| **User motion** | Stationary, rotating object | Walking/panning camera |
| **Primary use case** | Single item detail | Bookshelf, closet, garage |

#### Q6.6: Implementation Questions

1. **Should auto mode replace burst mode or coexist?**
   - Option A: Replace burst with auto (simpler, one mode)
   - Option B: Keep both (burst = quick, auto = thorough)
   - Recommendation: Keep both, different use cases

2. **How to handle quality gate failures mid-scan?**
   - Pause and resume automatically
   - Show "holding" indicator
   - Don't count against max photos

3. **What happens if user captures 100 photos with 50 distinct objects?**
   - Layer 1 processes all, creates 50 items
   - User reviews in batch
   - Consider: Batch review UI for auto mode results

4. **Should auto mode have a "preview" before upload?**
   - Show grid of captured photos
   - Let user deselect bad ones
   - Then upload only selected

5. **Cost implications of 50-100 images per session?**
   - Gemini 3 Flash: ~$0.002 per 50 images (very cheap)
   - Main cost is in Layer 2 cataloging per detected object
   - Gating: Limit number of objects detected, not photos

---

## Proposed Exploration Areas

1. **Burst mode evolution:** Define `scan` mode for multi-object capture vs. `burst` for multi-angle
2. **Auto mode MVP:** Implement quality-gated continuous capture with iOS sensor APIs
3. **Fingerprinting MVP:** iOS VNFeaturePrint → server comparison → duplicate prompt
4. **Gemini inventory lookup:** Tool or prompt injection for duplicate reasoning
5. **Session persistence enhancement:** Support item association from fingerprint match
6. **UX for duplicate review:** Design the "Is this the same item?" flow
7. **Batch review UI:** Design results screen for auto mode with 50+ detected objects

---

## Questions for Brainstorm Session

### Priority & Sequencing
1. What's the highest-impact feature to implement first?
2. Should auto mode be built before or after duplicate detection?
3. What's the simplest MVP that solves the "forgot I catalogued it" problem?

### Capture Modes
4. Should auto mode replace burst mode or coexist as separate modes?
5. What quality gate thresholds feel right for motion/blur/light?
6. Should auto mode require a dedicated UI button or reuse long-press gesture?

### Duplicate Detection
7. Should fingerprinting be client-side (VNFeaturePrint), server-side (Gemini), or hybrid?
8. How do we handle false positives in duplicate detection?
9. What's the right UX when a potential duplicate is detected?

### Architecture
10. How does auto mode interact with session persistence and context caching?
11. Should Layer 1 or Layer 2 handle duplicate checking?
12. What's the cost model for auto mode at scale (50-100 photos × many users)?
