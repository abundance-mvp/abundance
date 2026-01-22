---
date: 2026-01-20
status: Fix-Deployed
priority: P1
type: bug
component: backend
source: device-tester
related-files:
  - functions/src/ai-pipeline/layer1/layer1-service.ts
  - functions/src/ai-pipeline/layer1/prompts.ts
screenshots:
  - Screenshot 2026-01-20 at 8.19.53 PM.png
axiom-agent: null
branch: null
resolved: pending-verification
---

## Summary

Layer 2 cataloging returns incorrect names and swapped cropped images for detected objects.

## Description

When two objects are detected (linen towel and Holimet PU leather placemat), the catalog results are incorrect:
1. The linen towel shows with the cropped image of the placemat and is named "Holimet PU Leather Placemat"
2. The actual Holimet placemat shows as "Unknown Item" with status "Failed"

This suggests either:
- Layer 1 crops are being associated with wrong groupIds
- Layer 2 is receiving mismatched image/label pairs
- The groupId mapping between detection and cataloging is broken

## Expected Behavior

- Linen towel should be identified as a towel/textile with its correct cropped image
- Holimet placemat should be identified correctly with its cropped image showing the green placemat

## Actual Behavior

- Linen towel card shows placemat crop and is named "Holimet PU Leather Placemat"
- Holimet placemat shows as "Unknown Item" with Failed status

## Technical Context

- Device: w-16e
- iOS: 26.0
- Source: device-tester
- The thumbnails ARE loading now (previous fix worked), but content is swapped
- One item succeeded with wrong data, other failed completely

## Root Cause Analysis

**Investigation completed 2026-01-20:**

The issue is NOT a code bug - it's a **Gemini 3 Flash model accuracy problem** in Layer 1 detection.

**Pipeline trace:**
1. Layer 1 (Gemini Flash) detects objects and returns: `{groupId, label, box_2d, image_index}`
2. Code crops images using `box_2d` coordinates and associates with `groupId`
3. iOS creates items with `imageUrl` = cropped image and `layer1Label`
4. Layer 2 (Gemini Pro) catalogs based on the cropped image

**What happened:**
- Gemini Flash returned detection with label "Linen Towel" but a `box_2d` that covers the PLACEMAT region
- The code correctly cropped the box_2d area → saved placemat image under "Linen Towel" groupId
- Layer 2 received the placemat crop, correctly identified it as "Holimet PU Leather Placemat"
- Result: Item labeled by Layer 2 has wrong image because Layer 1's bounding box didn't match its label

**Evidence:**
- The name "Holimet PU Leather Placemat" is from Layer 2 (Gemini Pro), not Layer 1
- Layer 2 correctly identified what it SAW (the placemat image), so Layer 2 is working
- The issue is Layer 1 returned mismatched label-bounding box pairs

## Proposed Solutions

**Option 1: Improve Layer 1 prompt (Quick fix)**
Add explicit instruction to the system prompt:
```
CRITICAL: Ensure each bounding box ONLY covers the object described by its label.
Double-check that the [ymin, xmin, ymax, xmax] values accurately frame the specific object.
```

**Option 2: Add validation in Layer 1 (Medium effort)**
- After cropping, use a quick vision check to verify the crop matches the label
- Flag detections where crop content doesn't match label for manual review

**Option 3: Lower temperature / use higher quality model (Configuration)**
- Current: `temperature: 0.1` in `LAYER1_GENERATION_CONFIG`
- Consider: `temperature: 0.0` for more deterministic bounding boxes
- Or: Use a higher capability model for detection if accuracy is critical

## Fix Applied

**2026-01-20:** Applied Option 1 + Option 3:

1. **Enhanced Layer 1 prompt** (`functions/src/ai-pipeline/layer1/prompts.ts`):
   Added "CRITICAL - BOUNDING BOX ACCURACY" section emphasizing:
   - Each bounding box must frame ONLY the labeled item
   - Do NOT include adjacent objects
   - Verify label matches what is INSIDE the bounding box

2. **Lowered temperature to 0** for deterministic bounding boxes

**Requires deployment:** `firebase deploy --only functions:onSessionCreated`

**Verification:** Delete test items, capture new session with multiple objects, verify correct crops.
