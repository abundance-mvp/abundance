---
date: 2026-01-18
status: fixed
priority: P2
type: bug
component: ios
source: manual
fixed: 2026-01-18
related-files:
  - App/Assets.xcassets/AppIcon.appiconset/Contents.json
  - App/Assets.xcassets/AppIcon.appiconset/abundance-app-icon-20260118.png
screenshots:
  - Screenshot 2026-01-18 at 6.53.23 PM.png
axiom-agent: null
branch: null
design-doc: null
implementation-plan: null
---

## Summary

App icon displays with white border/padding instead of filling the full icon area on iOS home screen.

## Description

The Abundance app icon shows with a visible white border around all edges when displayed on the iOS home screen. The gradient background (peach to teal) with the 3D "A" logo doesn't extend to the full icon bounds where iOS applies its rounded rect mask.

## Expected Behavior

The app icon should fill the entire icon area with the gradient background extending to all edges. iOS should apply its rounded corner mask directly to the gradient, with no visible white border.

## Actual Behavior

A white border/padding is visible around the icon because the source image already contains:
1. Pre-baked rounded corners
2. White/transparent background outside the rounded rect area

When iOS applies its own rounded rect mask on top of this, the white padding becomes visible.

## Technical Context

- Device: w-16e (iPhone 16e)
- Source: manual
- Root cause analysis:
  - Source image: `App/Assets.xcassets/AppIcon.appiconset/abundance-app-icon-20260118.png`
  - The 1024x1024 source PNG has rounded corners already baked into the image
  - iOS requires a **full square** source image and applies its own rounded corner mask
  - Having pre-rounded corners in the source causes double-masking, revealing the background

## Proposed Solution

1. **Replace the source icon** with a full-bleed 1024x1024 square version:
   - Gradient should extend edge-to-edge (no padding)
   - No pre-rounded corners in the source image
   - iOS will automatically apply the rounded rect mask

2. The "A" logo positioning and 3D effect can remain the same—only the background needs to extend to all edges.

## References

- Apple HIG: App icons must be provided as square images; the system applies the rounded corner mask

## Resolution

### Fix Applied

Used ImageMagick to extend the gradient background to fill the full 1024x1024 canvas:

1. Sampled edge colors from the existing gradient (peach top, teal bottom)
2. Created a matching vertical gradient background (1024x1024)
3. Composited the original icon (with 3D "A" logo) over the gradient
4. Optimized to 8-bit PNG for iOS compatibility

### Result

The app icon source image now has:
- Full-bleed gradient extending to all edges
- No transparent/white padding
- iOS will apply its rounded corner mask cleanly to the gradient

### Verification

Rebuild and redeploy to device to confirm no white border on home screen.
