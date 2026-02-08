---
name: device-tester
description: >
  Use when testing on physical device w-16e or simulator, debugging device-specific
  crashes, capturing device logs, inspecting UI state, or iterating on build-deploy-verify cycles.
user-invocable: true
---

# Device Testing Workflow

Iterative testing on physical devices and simulators using XcodeBuildMCP (primary) and AXe for UI inspection.

## When NOT to Use

- **Automated AXe test suite** → Use `sim-test` skill instead
- **Build failure only (no device)** → Use `build-fixer` agent or `/axiom:fix-build` directly
- **Pure performance profiling** → Use `performance-profiler` agent directly

## Device & Project Constants

| Key | Value |
|-----|-------|
| Physical Device | `w-16e` |
| Bundle ID | `com.abundance.mvp` |
| Device Identifier | `6C65EE17-7E22-59FA-B47B-29AE0D69973D` |
| Scheme | `Abundance` |
| UI Test Scheme | `AbundanceUITests` |
| Derived Data | `/tmp/device-build` |

All commands below use these constants. Update this table if they change.

## Issue Routing

When an issue surfaces during testing, route to the right agent:

| Symptom | Route To |
|---------|----------|
| App crashed / .ips log found | `crash-analyzer` agent — check `~/Library/Logs/CrashReporter/MobileDevice/w-16e/` |
| XCUITest failures | `test-debugger` agent |
| Slow / stuttering / battery drain | `performance-profiler` agent |
| Build failed / code signing / linker | `build-fixer` agent → if persistent, `axiom-ios-build` skill |
| API / network errors | Check Cloud Functions logs via `mcp__plugin_firebase_firebase__functions_get_logs` |
| Visual bug / layout wrong | AXe `describe-ui` (simulator) or `./screenshots/` (device) |

## Iterative Loop

1. **Build & Deploy** — XcodeBuildMCP: `build_device` or `build_sim`. If fails → route to build-fixer.
2. **Launch & Capture Logs** — `launch_app_device`/`launch_app_sim` + `start_device_log_cap` (device only).
3. **Inspect UI** — Simulator: `axe describe-ui` or `snapshot_ui`. Device: check `./screenshots/`.
4. **Triage issues** — Use routing table above.
5. **Fix → Repeat** from step 1 until resolved.

## Build & Deploy: Physical Device

**XcodeBuildMCP (primary):** `build_device` → `install_app_device` → `launch_app_device` → `start_device_log_cap`

**Fallback raw commands:**

```bash
# Build
xcodebuild -scheme Abundance -destination "platform=iOS,name=w-16e" \
  -derivedDataPath /tmp/device-build -configuration Debug build 2>&1 | tee /tmp/build.log

# Install
xcrun devicectl device install app --device w-16e \
  /tmp/device-build/Build/Products/Debug-iphoneos/Abundance.app

# Launch with console
xcrun devicectl device process launch --device w-16e \
  --console --terminate-existing com.abundance.mvp

# Launch with deep link
xcrun devicectl device process launch --device w-16e \
  --payload-url "abundance://capture" com.abundance.mvp
```

## Build & Deploy: Simulator

**XcodeBuildMCP (primary):** `list_sims` → `boot_sim` → `build_sim` → `launch_app_sim`

**Fallback raw commands:**

```bash
xcrun simctl list devices available | grep iPhone
xcrun simctl boot <UDID>
xcodebuild -scheme Abundance -destination "platform=iOS Simulator,name=iPhone 16 Pro" build
xcrun simctl launch --console-pty <UDID> com.abundance.mvp
```

## UI Inspection

### Simulator: AXe (Preferred)

```bash
UDID=$(xcrun simctl list devices -j | jq -r '.devices | to_entries[] | .value[] | select(.state == "Booted") | .udid' | head -1)

axe describe-ui --udid $UDID                          # Full tree — run BEFORE interactions
axe describe-ui --point 200,400 --udid $UDID           # Element at coordinates
axe screenshot --output /tmp/sim-screenshot.png --udid $UDID
```

**Interact by accessibility identifier (stable), not coordinates (fragile):**

```bash
axe tap --id "captureButton" --udid $UDID
axe tap --label "Capture" --udid $UDID
axe type "kitchen items" --udid $UDID                  # Focus field first
axe gesture scroll-down --udid $UDID
```

**Alternative:** XcodeBuildMCP `snapshot_ui` MCP tool for view hierarchy with coordinates.

### Physical Device: Screenshots

```bash
ls -lt screenshots/ | head -5    # Check for iCloud-synced screenshots
```

Workflow: User screenshots on device → syncs to `./screenshots/` → Claude reads image → suggest fixes → repeat.

### SwiftUI Preview Rendering (mcpbridge)

When Xcode is open and mcpbridge is available, render SwiftUI previews directly:

```
mcp__xcode__RenderPreview(file: "Sources/InventoryFeature/ItemCard.swift")
```

Returns a snapshot image of the SwiftUI preview. Use this to:
- Verify UI changes without deploying to device
- Check layout in preview before building
- Compare before/after for visual regressions

**When to use RenderPreview vs device screenshots:**
| Scenario | Use |
|----------|-----|
| Quick layout check during iteration | `RenderPreview` |
| Testing with real data / auth state | Device screenshot |
| Verifying animations or gestures | Device (previews are static) |
| Checking dark mode / accessibility sizes | `RenderPreview` (configure preview) |

### Swift REPL (mcpbridge)

Execute Swift snippets in the context of the project (when mcpbridge available):

```
mcp__xcode__ExecuteSnippet(code: "print(Bundle.main.bundleIdentifier ?? \"unknown\")")
```

Useful for quick validation of:
- Computed property logic
- Date formatting
- Codable round-trips
- Expression evaluation during debugging

## Testing

**XcodeBuildMCP:** `test_device` or `test_sim` (scheme: `AbundanceUITests`)

**Fallback:**
```bash
xcodebuild test -scheme AbundanceUITests \
  -destination "platform=iOS,name=w-16e" \
  -resultBundlePath /tmp/test-results.xcresult
```

## Device Utilities

```bash
# Process control
xcrun devicectl device process terminate --device w-16e com.abundance.mvp
xcrun devicectl device info processes --device w-16e | grep -i abundance

# App data
xcrun devicectl device info files --device w-16e \
  --domain-type appDataContainer --domain-identifier com.abundance.mvp
xcrun devicectl device copy from --device w-16e \
  --source appDataContainer:com.abundance.mvp/Documents/ --destination /tmp/device-data/
```

## Issue Filing

When a bug is found, gather context then invoke file-issue:

1. Console logs (last 50 lines), device info, UI state (`axe describe-ui` or screenshot), test scenario
2. `Skill(skill="file-issue", args="--source device-tester --context <gathered>")`
3. Ask user: **"Continue testing?"** (resume loop) or **"Stop to investigate?"** (`ios-superpowers debug`)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| AXe can't find TabView tab buttons | SwiftUI TabView tabs are NOT in the AX tree. Use coordinate tapping: Catalog(100,850), Camera(200,850), Profile(300,850) |
| AXe can't find toolbar Cancel/Save | SwiftUI toolbar buttons often missing from AX tree. Use label text search or swipe to dismiss |
| `.accessibilityIdentifier()` on Label inside `.tabItem {}` | Doesn't work — put identifier on the content view instead |
| `LazyVGrid` with `.accessibilityIdentifier()` | Doesn't create distinct AX element — grid items appear as direct app children |
| Screenshots not appearing in `./screenshots/` | iCloud sync delay — wait 5-10 seconds, then re-check |
| Device not found by `xcrun devicectl` | Reconnect USB cable, trust device: Settings > General > Device Management > Trust |
| Console shows nothing | App may not use stdout. Add `os_log`: `Logger(subsystem: "com.abundance.mvp", category: "debug")` then filter in Console.app |
| AXe returns empty tree | UI may still be loading. Add `--pre-delay 0.5` flag |

## Troubleshooting

### Device Not Found
```bash
xcrun devicectl list devices
# If not listed: reconnect USB, trust on device (Settings > General > Device Management)
```

### App Won't Launch
```bash
xcrun devicectl device info apps --device w-16e | grep -i abundance
# If missing: rebuild + reinstall via build_device → install_app_device
# Or: xcrun devicectl device uninstall app --device w-16e com.abundance.mvp
```
