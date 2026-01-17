---
name: device-tester
description: Iterative testing on physical device w-16e with crash analysis, performance profiling, and screenshot debugging
---

# Device Tester Command

Iterative testing and troubleshooting workflow for physical iOS device (w-16e).

## Usage

```
/device-tester                  # Start device testing session
/device-tester build            # Build and deploy to device
/device-tester crash            # Analyze recent crash
/device-tester logs             # View console output
/device-tester screenshot       # Check latest screenshot
```

## What This Does

Invokes the `device-tester` skill which provides:

1. **Build & Deploy** to physical device w-16e
2. **Launch with Console** for stdout/stderr monitoring
3. **Crash Analysis** via `axiom:crash-analyzer` agent
4. **Performance Profiling** via `axiom:performance-profiler` agent
5. **Screenshot Debugging** from iCloud-synced `./screenshots/`

## Issue Routing

| Issue | Routed To |
|-------|-----------|
| App crashed | `axiom:crash-analyzer` agent |
| Tests failing | `axiom:test-debugger` agent |
| Performance issues | `axiom:performance-profiler` agent |
| Build failed | `axiom:build-fixer` agent |
| UI bug (with screenshot) | Read from `./screenshots/` |

## Device Details

- **Device:** w-16e
- **Bundle ID:** com.abundance.mvp
- **Identifier:** 6C65EE17-7E22-59FA-B47B-29AE0D69973D

## Screenshot Workflow

Screenshots sync via iCloud to `./screenshots/`. When debugging UI issues:

```bash
# Check for latest screenshots
ls -lt screenshots/ | head -5

# Claude reads the screenshot (multimodal) to analyze UI state
```

## Quick Commands

| Action | Command |
|--------|---------|
| Build for device | `xcodebuild -scheme Abundance -destination "platform=iOS,name=w-16e" build` |
| Launch with console | `xcrun devicectl device process launch --device w-16e --console com.abundance.mvp` |
| Find crash logs | `ls -lt ~/Library/Logs/CrashReporter/MobileDevice/w-16e/*.ips \| head -5` |
| List processes | `xcrun devicectl device info processes --device w-16e` |
| Check screenshots | `ls -lt screenshots/ \| head -5` |
