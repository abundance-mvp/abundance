---
name: sim-test
description: Build on simulator and run all 11 AXe test scenarios from AXE-TEST-SCENARIOS.md
---

# Simulator AXe Test Runner

Builds the app on an iOS Simulator, launches it, and runs all 11 interactive AXe test scenarios defined in `docs/testing/AXE-TEST-SCENARIOS.md`.

## Usage

```
/sim-test              # Run all 11 scenarios
/sim-test 1-5          # Run scenarios 1 through 5 only
/sim-test 6            # Run a single scenario
```

## Workflow

1. **Setup:** Load XcodeBuildMCP tools (`snapshot_ui`, `screenshot`, `tap`, `swipe`, `long_press`, `type_text`), set session defaults (project: `Abundance.xcodeproj`, scheme: `Abundance`, bundle ID: `com.abundance.mvp`)
2. **Build:** `build_sim` for iOS Simulator (iPhone 16 Pro, latest OS)
3. **Boot & Launch:** `boot_sim`, then `build_run_sim` or `launch_app_sim`
4. **Run Scenarios:** Read `docs/testing/AXE-TEST-SCENARIOS.md` and execute each scenario sequentially using XcodeBuildMCP `snapshot_ui` for accessibility tree inspection
5. **Report:** Summary table with PASS / FAIL / SKIP per scenario, plus screenshots at key points

## Scenario Reference

| # | Name | What It Tests |
|---|------|---------------|
| 1 | Tab Navigation | All 3 tabs reachable, correct content |
| 2 | Empty Inventory State | Empty state renders correctly |
| 3 | Item Grid & Scroll | 2-column grid, scrolling |
| 4 | Search & Filter | Search filters, clear restores, no-match state |
| 5 | Item Detail View | Tap item -> detail with metadata |
| 6 | Edit Item Flow | Edit sheet, form fields, cancel discards |
| 7 | Multi-Select & Bulk Delete | Selection mode, bulk delete confirmation |
| 8 | Context Menu (Long Press) | Long-press context menu with Edit/Delete |
| 9 | Profile View | User info, settings, export, sign out |
| 10 | Layout Correctness | No zero-sized or off-screen interactive elements |
| 11 | Accessibility ID Audit | All expected identifiers present |

## Gotchas — Read Before Running

These are verified workarounds for iOS 26 Liquid Glass + AXe limitations. Following them avoids wasted retries.

### Tab bar navigation
Tab bar buttons (`tab.catalog`, `tab.camera`, `tab.profile`) are **NOT** in the AX tree. Use coordinate taps: **Catalog(100,850), Camera(200,850), Profile(300,850)**. If a tap doesn't switch tabs, the scrollable content may be intercepting it — take a `screenshot` to visually confirm the tab bar position, then adjust y coordinate (try 840-860 range).

### Search field activation
The SwiftUI `.searchable` field requires **two steps**: first `tap(id: "inventory.searchField")` to focus it (cursor appears), THEN `type_text`. A single `tap(x, y)` followed by `type_text` may silently fail — always tap by ID, confirm focus with `snapshot_ui` (AXValue changes from placeholder), then type.

### Edit form dismissal
Toolbar buttons (Cancel/Save) are **NOT** in the AX tree. To dismiss the edit form, **swipe down** from y=100 to y=800 (duration 0.3s). The `edit.cancelButton` on the rescan prompt sheet IS accessible — only the NavigationBar toolbar buttons are hidden.

### Edit flow is two-step
Tapping `detail.editButton` opens a **rescan prompt sheet** first (not the edit form directly). Tap `edit.skipRescanButton` ("Edit Without Rescan") to reach the actual edit form. `edit.takeNewPhotoButton` and `edit.cancelButton` are also on this prompt.

### Long press
Use `long_press(x, y, duration: 1500)` with coordinates from the item card's frame center. The `long_press` tool requires explicit x/y — it does not accept an `id` parameter.

## Execution Rules

- Read the full test scenario doc FIRST: `docs/testing/AXE-TEST-SCENARIOS.md`
- Check skip conditions before each scenario (adapt to current app state)
- Use `snapshot_ui` (XcodeBuildMCP) for accessibility tree inspection
- Use `screenshot` at key assertion points
- If a scenario fails, capture the failure details and continue to the next scenario
- At the end, print a summary table: `Scenario | Result | Notes`

## Tools Required

- **XcodeBuildMCP:** `session-set-defaults`, `build_sim`, `boot_sim`, `build_run_sim`, `launch_app_sim`, `snapshot_ui`, `screenshot`, `tap`, `swipe`, `long_press`, `type_text`
- Scenario doc: `docs/testing/AXE-TEST-SCENARIOS.md`

## Arguments

$ARGUMENTS
