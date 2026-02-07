---
name: sim-test
description: Build on simulator and run AXe test scenarios from AXE-TEST-SCENARIOS.md
---

# Sim-Test

Build the app on an iOS Simulator, launch it, and run interactive AXe test scenarios defined in `docs/testing/AXE-TEST-SCENARIOS.md`.

## When to Use

- When `/sim-test` is invoked
- When user says "run test scenarios", "run AXe tests", "test on simulator"
- After UI changes to verify accessibility identifiers and interaction flows

## Pipeline

```
setup → build → launch → run scenarios → report
```

### Step 1: Setup

Load XcodeBuildMCP tools and set session defaults.

**Tools required:** `session-set-defaults`, `build_sim`, `boot_sim`, `build_run_sim`, `launch_app_sim`, `snapshot_ui`, `screenshot`, `tap`, `swipe`, `long_press`, `type_text`

**Session defaults:**
- Project: `Abundance.xcodeproj`
- Scheme: `Abundance`
- Simulator: iPhone 16 Pro, latest OS
- Bundle ID: `com.abundance.mvp`

```
session-set-defaults(project: "Abundance.xcodeproj", scheme: "Abundance")
```

### Step 2: Build & Launch

1. `build_sim` — build for iOS Simulator
2. `boot_sim` — ensure simulator is booted
3. `build_run_sim` — install and launch the app

If build fails, stop and report the build error. Do not proceed to scenarios.

### Step 3: Load Scenarios

1. Read `docs/testing/AXE-TEST-SCENARIOS.md`
2. Parse the `$ARGUMENTS` to determine which scenarios to run:
   - No argument → run all scenarios (1-11)
   - Single number (e.g. `6`) → run only that scenario
   - Range (e.g. `1-5`) → run scenarios 1 through 5
3. Build the execution list from the scenario doc

**CRITICAL:** Scenario definitions live in `docs/testing/AXE-TEST-SCENARIOS.md`, NOT in this skill. Read the doc every time — scenarios may have changed since the last run.

### Step 4: Execute Scenarios

Run each scenario sequentially from the loaded doc.

**For each scenario:**

1. **Check skip conditions** — read the scenario's "Skip if" section and check current app state
2. **Execute steps** — follow the scenario's "Steps" section using XcodeBuildMCP tools
3. **Assert** — verify the scenario's "Assertions" using `snapshot_ui` output
4. **Screenshot** — capture `screenshot` at key assertion points
5. **Record result** — PASS / FAIL / SKIP with details
6. **Continue** — if a scenario fails, capture failure details and move to the next scenario (do NOT stop)

**Navigation between scenarios:** Return to a known state (Catalog tab) before starting each scenario unless the scenario specifies a different starting point.

### Step 5: Report

Print a summary table at the end:

```markdown
## Sim-Test Report

| # | Scenario | Result | Notes |
|---|----------|--------|-------|
| 1 | Tab Navigation | PASS | |
| 2 | Empty Inventory State | SKIP | Items present |
| ... | ... | ... | ... |

**Summary:** X passed, Y failed, Z skipped
```

Include screenshot paths for key moments and any failure details.

## Platform Workarounds

These are verified workarounds for SwiftUI + AXe limitations. **Follow them exactly** — they prevent wasted retries.

### Tab bar navigation

Tab bar buttons (`tab.catalog`, `tab.camera`, `tab.profile`) are **NOT** in the AX tree. Use coordinate taps:

| Tab | Coordinates |
|-----|------------|
| Catalog | `tap(x: 100, y: 850)` |
| Camera | `tap(x: 200, y: 850)` |
| Profile | `tap(x: 300, y: 850)` |

If a tap doesn't switch tabs, the scrollable content may be intercepting it — take a `screenshot` to visually confirm the tab bar position, then adjust y coordinate (try 840-860 range).

### Search field activation

The SwiftUI `.searchable` field requires **two steps**:

1. `tap(id: "inventory.searchField")` — focus it (cursor appears). MUST use `id`, not coordinates.
2. `snapshot_ui` — confirm focus (AXValue changes from placeholder)
3. `type_text(text: "...")` — type the search term

A single coordinate `tap` followed by `type_text` may silently fail.

### Edit form dismissal

Toolbar buttons (Cancel/Save) are **NOT** in the AX tree. To dismiss the edit form:

- **Swipe down** from y=100 to y=800 (duration 0.3s)
- The `edit.cancelButton` on the **rescan prompt sheet** IS accessible — only the NavigationBar toolbar buttons are hidden

### Edit flow is two-step

Tapping `detail.editButton` opens a **rescan prompt sheet** first (not the edit form directly):

1. `tap(id: "detail.editButton")` → rescan prompt sheet appears
2. Verify: `edit.takeNewPhotoButton`, `edit.skipRescanButton`, `edit.cancelButton`
3. `tap(id: "edit.skipRescanButton")` → actual edit form appears

### Long press

`long_press` requires explicit x/y coordinates — it does **NOT** accept an `id` parameter.

1. Get the target element's frame from `snapshot_ui` AXFrame
2. Calculate center: `x + width/2`, `y + height/2`
3. `long_press(x: <center_x>, y: <center_y>, duration: 1500)`

### Grid container not in AX tree

`inventory.grid` on `LazyVGrid` is not exposed as a separate AX element. Grid items appear as direct children of the Application. Verify grid by checking for multiple `inventory.item.*` identifiers.

## Error Handling

| Condition | Action |
|-----------|--------|
| Build fails | Stop, report build error, do not run scenarios |
| Simulator won't boot | Stop, report simulator error |
| App crashes during scenario | Capture crash info, relaunch app, continue to next scenario |
| `snapshot_ui` returns empty tree | Take `screenshot` for visual fallback, retry once, then FAIL the scenario |
| Scenario step fails | Record failure details, continue to next scenario |
| All scenarios skip | Report "all skipped" with reasons |

## Red Flags — STOP and Re-read This Skill

| Thought | Reality |
|---------|---------|
| "I know the scenarios, skip reading the doc" | Scenarios change. Read `AXE-TEST-SCENARIOS.md` every time. |
| "Tab bar should be tappable by ID" | It's not. Use coordinates. See Platform Workarounds. |
| "I'll tap the search field by coordinates" | Use `tap(id:)` for search. Coordinates silently fail. |
| "Cancel button should dismiss the edit form" | It's not in the AX tree. Swipe down instead. |
| "Long press accepts an element ID" | It doesn't. Calculate coordinates from AXFrame. |
| "One scenario failed, stop everything" | Capture failure, continue to next scenario. Always finish all. |
| "I'll hardcode scenario steps in my response" | Read them from `AXE-TEST-SCENARIOS.md`. That's the source of truth. |

## What This Skill Does NOT Do

- Modify app source code or fix failing assertions
- Run on physical devices (use `/device-tester` for that)
- Test network-dependent features (Cloud Functions, Firestore sync)
- Replace XCUITest suites (this is interactive AXe testing, not automated test scripts)
- Define scenarios (those live in `docs/testing/AXE-TEST-SCENARIOS.md`)
