---
name: sim-test
description: Build on simulator and run all 12 AXe test scenarios from AXE-TEST-SCENARIOS.md
---

# Simulator AXe Test Runner

Builds the app on an iOS Simulator, launches it, and runs all 12 interactive AXe test scenarios defined in `docs/testing/AXE-TEST-SCENARIOS.md`.

## Usage

```
/sim-test              # Run all 12 scenarios
/sim-test 1-5          # Run scenarios 1 through 5 only
/sim-test 6            # Run a single scenario
```

## Workflow

1. **Setup:** Load XcodeBuildMCP tools, set session defaults (project: `Abundance.xcodeproj`, scheme: `Abundance`, bundle ID: `com.abundance.mvp`)
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
| 12 | Catalog Processing States | Items show progressive AI status |

## Execution Rules

- Read the full test scenario doc FIRST: `docs/testing/AXE-TEST-SCENARIOS.md`
- Check skip conditions before each scenario (adapt to current app state)
- Use `snapshot_ui` (XcodeBuildMCP) for accessibility tree inspection
- Use `screenshot` at key assertion points
- If a scenario fails, capture the failure details and continue to the next scenario
- At the end, print a summary table: `Scenario | Result | Notes`

## Tools Required

- **XcodeBuildMCP:** `session-set-defaults`, `build_sim`, `boot_sim`, `build_run_sim`, `launch_app_sim`, `snapshot_ui`, `screenshot`
- Scenario doc: `docs/testing/AXE-TEST-SCENARIOS.md`

## Arguments

$ARGUMENTS
