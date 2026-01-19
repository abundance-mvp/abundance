---
name: device-tester
description: |
  Iterative testing and troubleshooting workflow for physical iOS devices.
  Use when deploying to device, capturing logs, analyzing crashes, and iterating on fixes.

  Example triggers:
  - "Test on my device"
  - "Debug on w-16e"
  - "Iterate on device testing"
  - "Capture device logs"
user-invocable: true
---

# Physical Device Testing Workflow

Iterative testing on physical iOS devices using `devicectl` and related tools.

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

### General Device Testing → Use commands below

**Triggers:**
- Deploy and test manually
- Capture logs
- Iterate on fixes

## Device Commands Reference

### Your Device
- **Name:** `w-16e`
- **Bundle ID:** `com.abundance.mvp`
- **Identifier:** `6C65EE17-7E22-59FA-B47B-29AE0D69973D`

### Screenshots Location

**IMPORTANT:** Always check for new screenshots when user reports UI issues or is iterating on device.

Device screenshots sync to: `./screenshots/` (symlinked to iCloud)

```bash
# ALWAYS run this first when debugging UI issues
ls -lt screenshots/ | head -5

# Then read the most recent screenshot
# Claude is multimodal and can analyze the image
```

**Workflow:**
1. User takes screenshot on device (w-16e)
2. Screenshot syncs via iCloud → appears in `./screenshots/`
3. **You read and analyze the screenshot** to understand UI state
4. Suggest fixes based on what you see
5. User redeploys → takes new screenshot → repeat

**When to check screenshots:**
- User mentions "look at this" or "here's a screenshot"
- User reports a UI bug or visual issue
- Debugging any display/layout problem
- Verifying a fix worked

### Setup & Deploy

**Build fails?** → Invoke `build-fixer` agent (or `/axiom:fix-build`)

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

# Launch with environment variables
xcrun devicectl device process launch \
  --device w-16e \
  --environment-variables '{"DEBUG_MODE": "1"}' \
  com.abundance.mvp
```

### Capture Evidence

#### Check Running Processes
```bash
xcrun devicectl device info processes --device w-16e | grep -i abundance
```

#### Crash Logs
```bash
# After crash, find logs
ls -lt ~/Library/Logs/CrashReporter/MobileDevice/w-16e/*.ips | head -5

# Then invoke crash-analyzer agent
```

#### App Data
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

### Process Control

```bash
# Terminate app
xcrun devicectl device process terminate --device w-16e com.abundance.mvp

# Send memory warning
xcrun devicectl device process sendMemoryWarning --device w-16e --pid <PID>

# Suspend/Resume
xcrun devicectl device process suspend --device w-16e --pid <PID>
xcrun devicectl device process resume --device w-16e --pid <PID>
```

### Run XCUITests on Device

```bash
# Run all UI tests
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

## Iterative Workflow

```
┌─────────────────────────────────────────────────────────┐
│  1. BUILD & DEPLOY                                      │
│     → Use xcodebuild (see below)                        │
│     → If fails: Invoke build-fixer agent                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  2. LAUNCH WITH CONSOLE                                 │
│     xcrun devicectl device process launch               │
│       --device w-16e --console --terminate-existing     │
│       com.abundance.mvp                                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  3. TEST & OBSERVE                                      │
│     - Watch console output                              │
│     - Interact with app                                 │
│     - Note issues                                       │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  4. IF ISSUE FOUND                                      │
│     ├─ Crash? → Invoke crash-analyzer agent             │
│     ├─ Slow? → Invoke performance-profiler agent        │
│     ├─ Test fail? → Invoke test-debugger agent          │
│     ├─ Bug? → Offer to file issue, then fix or continue │
│     └─ Feature idea? → File as enhancement              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  5. REPEAT until fixed                                  │
└─────────────────────────────────────────────────────────┘
```

---

## Issue Filing Integration

When an issue is discovered during device testing, use the file-issue skill to create a standardized issue.

### Automatic Context Gathering

Before invoking file-issue, gather:

1. **Console logs** (last 50 relevant lines from launch output)
2. **Device info**: w-16e, iOS version
3. **Recent screenshots**:
   ```bash
   ls -lt screenshots/ | head -5
   ```
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
  "test_scenario": "Testing camera capture flow"
}
```

### After Issue Filed

Ask user:
- **"Continue testing?"** → Resume testing loop at step 1
- **"Stop to investigate?"** → Offer to start debugging with `ios-superpowers debug`

### Quick Filing

For obvious bugs during testing:

```
"I noticed [issue]. Should I file this as an issue?"
- Yes → Invoke file-issue with gathered context
- No → Continue testing
```

## Quick Commands Reference

| Task | Command |
|------|---------|
| List devices | `xcrun devicectl list devices` |
| Launch app | `xcrun devicectl device process launch --device w-16e com.abundance.mvp` |
| Launch with console | `xcrun devicectl device process launch --device w-16e --console com.abundance.mvp` |
| Terminate app | `xcrun devicectl device process terminate --device w-16e com.abundance.mvp` |
| List processes | `xcrun devicectl device info processes --device w-16e` |
| List installed apps | `xcrun devicectl device info apps --device w-16e` |
| Install app | `xcrun devicectl device install app --device w-16e /path/to/App.app` |
| Copy from device | `xcrun devicectl device copy from --device w-16e --source appDataContainer:com.abundance.mvp/path --destination /local/path` |
| Send memory warning | `xcrun devicectl device process sendMemoryWarning --device w-16e --pid <PID>` |
| Reboot device | `xcrun devicectl device reboot --device w-16e` |

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

# Reinstall
xcrun devicectl device uninstall app --device w-16e com.abundance.mvp
./scripts/sim.sh --device w-16e
```

### Console Shows Nothing
The app may not print to stdout/stderr. Use `os_log` in code:
```swift
import os
let logger = Logger(subsystem: "com.abundance.mvp", category: "debug")
logger.info("This will appear in Console.app")
```

Then view in **Console.app** → select your device → filter by subsystem.
