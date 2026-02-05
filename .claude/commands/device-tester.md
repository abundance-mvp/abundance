---
name: device-tester
description: Iterative testing on device w-16e and simulators with XcodeBuildMCP, AXe UI inspection, crash analysis, and performance profiling
---

# Device Tester Command

Iterative testing and troubleshooting workflow for physical iOS device (w-16e) and simulators.

## Usage

```
/device-tester                  # Start device testing session
/device-tester build            # Build and deploy to device
/device-tester sim              # Build and run on simulator
/device-tester crash            # Analyze recent crash
/device-tester logs             # View console output
/device-tester screenshot       # Check latest screenshot
/device-tester inspect          # Inspect UI via accessibility tree (simulator)
```

## What This Does

Invokes the `device-tester` skill which provides:

1. **Build & Deploy** via XcodeBuildMCP MCP tools (with raw command fallback)
2. **UI Inspection** via AXe `describe-ui` (simulator accessibility tree) and iCloud screenshots (device)
3. **Log Capture** via XcodeBuildMCP `start_device_log_cap` or `--console` launch
4. **Crash Analysis** via `axiom:crash-analyzer` agent
5. **Performance Profiling** via `axiom:performance-profiler` agent

## Tools

| Tool | Purpose |
|------|---------|
| **XcodeBuildMCP** | 72 MCP tools for build, deploy, test, inspect |
| **AXe** | Accessibility tree inspection + UI automation (simulator) |

## Issue Routing

| Issue | Routed To |
|-------|-----------|
| App crashed | `axiom:crash-analyzer` agent |
| Tests failing | `axiom:test-debugger` agent |
| Performance issues | `axiom:performance-profiler` agent |
| Build failed | `axiom:build-fixer` agent |
| UI bug (simulator) | AXe `describe-ui` + XcodeBuildMCP `snapshot_ui` |
| UI bug (device) | Read from `./screenshots/` |

## Device Details

- **Device:** w-16e
- **Bundle ID:** com.abundance.mvp
- **Identifier:** 6C65EE17-7E22-59FA-B47B-29AE0D69973D

## Quick Reference

| Task | XcodeBuildMCP Tool | Fallback |
|------|--------------------|----------|
| Build for device | `build_device` | `xcodebuild -scheme Abundance -destination "platform=iOS,name=w-16e" build` |
| Launch on device | `launch_app_device` | `xcrun devicectl device process launch --device w-16e --console com.abundance.mvp` |
| Build for simulator | `build_sim` | `xcodebuild -scheme Abundance -sdk iphonesimulator build` |
| Inspect UI (sim) | `snapshot_ui` | `axe describe-ui --udid $UDID` |
| Screenshot (sim) | `screenshot` | `axe screenshot --output /tmp/screenshot.png --udid $UDID` |
| Find crash logs | - | `ls -lt ~/Library/Logs/CrashReporter/MobileDevice/w-16e/*.ips \| head -5` |
| Check device screenshots | - | `ls -lt screenshots/ \| head -5` |
