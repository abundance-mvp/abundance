---
name: device-tester
description: |
  Iterative testing and troubleshooting workflow for physical iOS devices and simulators.
  Use when deploying to device, capturing logs, analyzing crashes, inspecting UI, and iterating on fixes.

  Example triggers:
  - "Test on my device"
  - "Debug on w-16e"
  - "Iterate on device testing"
  - "Capture device logs"
  - "Inspect the UI"
  - "Run on simulator"
user-invocable: true
---

# Device Testing Workflow

Iterative testing on physical devices and simulators using XcodeBuildMCP (primary) and AXe for UI inspection.

## Tools

| Tool | Purpose | Install |
|------|---------|---------|
| **XcodeBuildMCP** | Build, deploy, test, inspect via MCP tools | `claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@beta mcp` |
| **AXe** | Accessibility tree inspection + UI automation (simulator) | `brew install cameroncooke/axe/axe` |

## Routing Logic

Based on the issue encountered, invoke the appropriate Axiom skill or agent:

### App Crashed → **crash-analyzer** (Agent)

**Triggers:**
- App terminated unexpectedly
- Crash log in `~/Library/Logs/CrashReporter/MobileDevice/`
- User says "app crashed"

**Invoke:** Launch `crash-analyzer` agent with the crash file path

```bash
# Find recent crash logs
ls -lt ~/Library/Logs/CrashReporter/MobileDevice/w-16e/*.ips | head -5
```

---

### Tests Failing → **test-debugger** (Agent)

**Triggers:**
- XCUITest failures on device
- User wants to run tests on device
- Test debugging loop needed

**Invoke:** Launch `test-debugger` agent

---

### Performance Issues → **performance-profiler** (Agent)

**Triggers:**
- App is slow
- UI stuttering on device
- Battery drain
- Memory growth

**Invoke:** Launch `performance-profiler` agent

---

### Build Failed → **build-fixer** (Agent)

**Triggers:**
- xcodebuild failed
- Device build errors
- Code signing issues
- "No such module" errors
- Linker errors

**Invoke:** Launch `build-fixer` agent or run `/axiom:fix-build`

```bash
# Build log is at /tmp/build.log after failed build
# Provide this to the agent for analysis
```

**Alternative:** If build issues persist, invoke `axiom-ios-build` skill which routes to:
- `axiom-xcode-debugging` for environment issues
- `spm-conflict-resolver` agent for dependency conflicts

---

### Backend Issues → Check Cloud Functions Logs

**Triggers:**
- API calls failing
- Network errors in app
- Backend-related crashes
- "Unable to connect" errors

**Check Cloud Functions Logs:**
```
Use mcp__plugin_firebase_firebase__functions_get_logs with:
- function_names: ["ai-pipeline-orchestrator", "gemini-service"]
- min_severity: "WARNING"
- order: "desc"
- page_size: 20
```

**Check Error Reporting:**
```
Use mcp__observability__list_group_stats with:
- projectName: "projects/abundance-mvp"
- timeRangePeriod: "PERIOD_1_HOUR"
- order: "COUNT_DESC"
```

---

### UI Issue → **UI Inspection** (see below)

**Triggers:**
- User reports visual bug
- Layout looks wrong
- Element not responding to taps
- Need to verify UI state after code change

**Action:** Use AXe `describe-ui` (simulator) or check `./screenshots/` (device)

---

### General Device Testing → Use workflows below

**Triggers:**
- Deploy and test manually
- Capture logs
- Iterate on fixes

## Device Info

- **Physical Device:** `w-16e`
- **Bundle ID:** `com.abundance.mvp`
- **Identifier:** `6C65EE17-7E22-59FA-B47B-29AE0D69973D`

## Build & Deploy: Physical Device (w-16e)

### Using XcodeBuildMCP (Primary)

Use XcodeBuildMCP MCP tools for structured build/deploy. These are MCP tools invoked directly, not bash commands.

```
1. build_device        → Build for physical device (scheme: Abundance, device: w-16e)
2. install_app_device  → Install .app to device
3. launch_app_device   → Launch app on device
4. start_device_log_cap → Start capturing device logs
5. stop_device_log_cap  → Stop app and return captured logs
```

### Fallback: Raw Commands

If XcodeBuildMCP is unavailable, use these commands:

```bash
# 1. Verify device is connected
xcrun devicectl list devices

# 2. Build for device (clean build)
xcodebuild \
  -scheme Abundance \
  -destination "platform=iOS,name=w-16e" \
  -derivedDataPath /tmp/device-build \
  -configuration Debug \
  clean build \
  2>&1 | tee /tmp/build.log

# If build fails, invoke build-fixer agent with /tmp/build.log

# 3. Install to device
xcrun devicectl device install app \
  --device w-16e \
  /tmp/device-build/Build/Products/Debug-iphoneos/Abundance.app

# 4. Quick rebuild (incremental, faster)
xcodebuild \
  -scheme Abundance \
  -destination "platform=iOS,name=w-16e" \
  -derivedDataPath /tmp/device-build \
  build
```

### Launch & Monitor

```bash
# Launch with console output (see stdout/stderr)
xcrun devicectl device process launch \
  --device w-16e \
  --console \
  --terminate-existing \
  com.abundance.mvp

# Launch with deep link
xcrun devicectl device process launch \
  --device w-16e \
  --payload-url "abundance://capture" \
  com.abundance.mvp
```

## Build & Deploy: Simulator

### Using XcodeBuildMCP (Primary)

```
1. list_sims           → List available simulators
2. boot_sim            → Boot target simulator
3. build_sim           → Build for simulator (scheme: Abundance)
4. launch_app_sim      → Launch app on simulator
5. snapshot_ui         → Get view hierarchy with coordinates
6. screenshot          → Capture screenshot
```

### Fallback: Raw Commands

```bash
# List simulators
xcrun simctl list devices available | grep iPhone

# Boot simulator
xcrun simctl boot <UDID>

# Build for simulator
xcodebuild \
  -scheme Abundance \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -configuration Debug \
  build

# Launch
xcrun simctl launch --console-pty <UDID> com.abundance.mvp
```

## UI Inspection

### Simulator: AXe Accessibility Tree (Preferred for Agents)

**The accessibility tree gives structured data (element types, identifiers, labels, frames) which is more useful for iteration than screenshots alone.**

```bash
# Get the booted simulator UDID
UDID=$(xcrun simctl list devices -j | jq -r '.devices | to_entries[] | .value[] | select(.state == "Booted") | .udid' | head -1)

# Full accessibility tree - ALWAYS run this before UI interactions
axe describe-ui --udid $UDID

# Element at specific coordinates
axe describe-ui --point 200,400 --udid $UDID

# Screenshot (instant, no iCloud delay)
axe screenshot --output /tmp/sim-screenshot.png --udid $UDID
```

**Example tree output:**
```json
{
  "type": "Button",
  "identifier": "captureButton",
  "label": "Capture",
  "frame": {"x": 150, "y": 700, "width": 100, "height": 44},
  "enabled": true
}
```

**When to use `describe-ui`:**
- Debugging UI layout issues (get exact frames)
- Verifying accessibility identifiers are set correctly
- Finding why an element isn't tappable (check `enabled` state)
- Before automated interaction (tap/type/swipe)

### Simulator: AXe UI Automation

After inspecting the tree, interact by accessibility identifier (stable) not coordinates (fragile):

```bash
# Tap by accessibility identifier (preferred)
axe tap --id "captureButton" --udid $UDID

# Tap by label
axe tap --label "Capture" --udid $UDID

# Type text (focus field first)
axe tap --id "searchField" --udid $UDID
axe type "kitchen items" --udid $UDID

# Gestures
axe gesture scroll-down --udid $UDID
axe gesture swipe-from-left-edge --udid $UDID  # Back navigation
```

### Simulator: XcodeBuildMCP snapshot_ui

Alternative to AXe - use XcodeBuildMCP's `snapshot_ui` MCP tool for view hierarchy with precise coordinates. This is an MCP tool call, not a bash command.

### Physical Device: Screenshots

Physical device UI inspection still uses iCloud-synced screenshots:

```bash
# ALWAYS run this first when debugging device UI issues
ls -lt screenshots/ | head -5

# Then read the most recent screenshot
# Claude is multimodal and can analyze the image
```

**Device screenshot workflow:**
1. User takes screenshot on device (w-16e)
2. Screenshot syncs via iCloud to `./screenshots/`
3. **Claude reads and analyzes the screenshot** to understand UI state
4. Suggest fixes based on what you see
5. User redeploys -> takes new screenshot -> repeat

**When to check screenshots:**
- User mentions "look at this" or "here's a screenshot"
- User reports a UI bug or visual issue
- Debugging any display/layout problem
- Verifying a fix worked

## Iterative Workflow

```
┌─────────────────────────────────────────────────────────┐
│  1. BUILD & DEPLOY                                      │
│     → XcodeBuildMCP: build_device / build_sim           │
│     → If fails: Invoke build-fixer agent                │
└─────────────────────────────────────────────────────────┘
                          |
┌─────────────────────────────────────────────────────────┐
│  2. LAUNCH & CAPTURE LOGS                               │
│     → XcodeBuildMCP: launch_app_device / launch_app_sim │
│     → XcodeBuildMCP: start_device_log_cap (device)      │
└─────────────────────────────────────────────────────────┘
                          |
┌─────────────────────────────────────────────────────────┐
│  3. INSPECT UI                                          │
│     → Simulator: axe describe-ui (accessibility tree)   │
│     → Simulator: snapshot_ui (view hierarchy)           │
│     → Device: Check ./screenshots/ (iCloud sync)        │
└─────────────────────────────────────────────────────────┘
                          |
┌─────────────────────────────────────────────────────────┐
│  4. IF ISSUE FOUND                                      │
│     ├─ Crash? → Invoke crash-analyzer agent             │
│     ├─ Slow? → Invoke performance-profiler agent        │
│     ├─ Test fail? → Invoke test-debugger agent          │
│     ├─ UI bug? → axe describe-ui + screenshot           │
│     ├─ Bug? → Offer to file issue, then fix or continue │
│     └─ Feature idea? → File as enhancement              │
└─────────────────────────────────────────────────────────┘
                          |
┌─────────────────────────────────────────────────────────┐
│  5. REPEAT until fixed                                  │
└─────────────────────────────────────────────────────────┘
```

## Testing

### Run Tests via XcodeBuildMCP (Primary)

```
test_device   → Run tests on physical device (scheme: AbundanceUITests)
test_sim      → Run tests on simulator
```

### Fallback: Raw Commands

```bash
# Run all UI tests on device
xcodebuild test \
  -scheme AbundanceUITests \
  -destination "platform=iOS,name=w-16e" \
  -resultBundlePath /tmp/test-results.xcresult

# Run specific test
xcodebuild test \
  -scheme AbundanceUITests \
  -destination "platform=iOS,name=w-16e" \
  -only-testing:AbundanceUITests/CaptureTests/testCameraCapture \
  -resultBundlePath /tmp/test-results.xcresult
```

## Capture Evidence

### Check Running Processes
```bash
xcrun devicectl device info processes --device w-16e | grep -i abundance
```

### Crash Logs
```bash
# After crash, find logs
ls -lt ~/Library/Logs/CrashReporter/MobileDevice/w-16e/*.ips | head -5

# Then invoke crash-analyzer agent
```

### App Data
```bash
# List files in app container
xcrun devicectl device info files --device w-16e \
  --domain-type appDataContainer \
  --domain-identifier com.abundance.mvp

# Copy files for inspection
xcrun devicectl device copy from --device w-16e \
  --source appDataContainer:com.abundance.mvp/Documents/ \
  --destination /tmp/device-data/
```

## Process Control

```bash
# Terminate app
xcrun devicectl device process terminate --device w-16e com.abundance.mvp

# Send memory warning
xcrun devicectl device process sendMemoryWarning --device w-16e --pid <PID>

# Suspend/Resume
xcrun devicectl device process suspend --device w-16e --pid <PID>
xcrun devicectl device process resume --device w-16e --pid <PID>
```

## Issue Filing Integration

When an issue is discovered during device testing, use the file-issue skill to create a standardized issue.

### Automatic Context Gathering

Before invoking file-issue, gather:

1. **Console logs** (last 50 relevant lines from launch output)
2. **Device info**: w-16e, iOS version
3. **UI state**: `axe describe-ui` output (simulator) or recent screenshots (device)
4. **Current test scenario** (what was being tested)

### Invoke File-Issue

```
Skill(skill="file-issue", args="--source device-tester --context <gathered>")
```

Context JSON structure:
```json
{
  "source": "device-tester",
  "device": "w-16e",
  "ios_version": "18.x",
  "console_logs": "[last 50 lines]",
  "screenshots": ["IMG_1234.png"],
  "ui_tree": "[axe describe-ui output if simulator]",
  "test_scenario": "Testing camera capture flow"
}
```

### After Issue Filed

Ask user:
- **"Continue testing?"** -> Resume testing loop at step 1
- **"Stop to investigate?"** -> Offer to start debugging with `ios-superpowers debug`

### Quick Filing

For obvious bugs during testing:

```
"I noticed [issue]. Should I file this as an issue?"
- Yes -> Invoke file-issue with gathered context
- No -> Continue testing
```

## Quick Commands Reference

| Task | XcodeBuildMCP Tool | Fallback Command |
|------|--------------------|------------------|
| List devices | `list_devices` | `xcrun devicectl list devices` |
| Build for device | `build_device` | `xcodebuild -scheme Abundance -destination "platform=iOS,name=w-16e" build` |
| Install to device | `install_app_device` | `xcrun devicectl device install app --device w-16e /path/to/App.app` |
| Launch on device | `launch_app_device` | `xcrun devicectl device process launch --device w-16e com.abundance.mvp` |
| Capture device logs | `start_device_log_cap` | `xcrun devicectl device process launch --device w-16e --console com.abundance.mvp` |
| Build for simulator | `build_sim` | `xcodebuild -scheme Abundance -sdk iphonesimulator build` |
| Launch on simulator | `launch_app_sim` | `xcrun simctl launch <UDID> com.abundance.mvp` |
| Inspect UI (sim) | `snapshot_ui` | `axe describe-ui --udid $UDID` |
| Screenshot (sim) | `screenshot` | `axe screenshot --output /tmp/screenshot.png --udid $UDID` |
| Test on device | `test_device` | `xcodebuild test -scheme AbundanceUITests -destination "platform=iOS,name=w-16e"` |
| Test on simulator | `test_sim` | `xcodebuild test -scheme AbundanceUITests -destination "platform=iOS Simulator,name=iPhone 16 Pro"` |
| Terminate app | `stop_app_device` | `xcrun devicectl device process terminate --device w-16e com.abundance.mvp` |
| List processes | - | `xcrun devicectl device info processes --device w-16e` |
| List installed apps | - | `xcrun devicectl device info apps --device w-16e` |
| Copy from device | - | `xcrun devicectl device copy from --device w-16e --source appDataContainer:com.abundance.mvp/path --destination /local/path` |
| Send memory warning | - | `xcrun devicectl device process sendMemoryWarning --device w-16e --pid <PID>` |
| Reboot device | - | `xcrun devicectl device reboot --device w-16e` |

## Troubleshooting

### Device Not Found
```bash
# Check connection
xcrun devicectl list devices

# If not listed, reconnect USB and trust on device
# Settings > General > Device Management > Trust
```

### App Won't Launch
```bash
# Check if installed
xcrun devicectl device info apps --device w-16e | grep -i abundance

# Reinstall via XcodeBuildMCP: build_device then install_app_device
# Or fallback:
xcrun devicectl device uninstall app --device w-16e com.abundance.mvp
# Then rebuild and install using the commands above
```

### Console Shows Nothing
The app may not print to stdout/stderr. Use `os_log` in code:
```swift
import os
let logger = Logger(subsystem: "com.abundance.mvp", category: "debug")
logger.info("This will appear in Console.app")
```

Then view in **Console.app** -> select your device -> filter by subsystem.

### AXe Not Finding Elements
1. Run `axe describe-ui` to see available elements
2. Check element has `accessibilityIdentifier` set in code
3. Ensure element is visible (not off-screen)
4. Try adding `--pre-delay 0.5` for slow-loading UI
