# Iteration Workflow Modernization Design

**Created:** 2026-02-05
**Status:** Implemented
**Approach:** A - XcodeBuildMCP + AXe integration

---

## Problem Statement

The development iteration workflow has diverged from its documentation:

1. **`sim.sh` is unreliable and unused** - The 200-line simulator script (`scripts/sim.sh`) is no longer the primary build method, but references persist in 5+ active files.
2. **`ITERATION-SYSTEM-SUMMARY.md` is stale** - Written Nov 2025, describes a sim.sh-centric 4-layer system that doesn't match current practice.
3. **No accessibility tree inspection** - Claude can only analyze screenshots (pixel data). The HN-discussed approach of inspecting the view hierarchy programmatically (`describe_ui`) gives agents structured element data (types, identifiers, frames) which is more useful for iteration.
4. **Builds use raw shell commands** - `xcodebuild` and `xcrun devicectl` are invoked ad-hoc via Bash, not through structured MCP tools.

### Current Actual Workflow

```
Claude writes code
    -> xcodebuild -scheme Abundance -destination "platform=iOS,name=w-16e" build
    -> xcrun devicectl device install app --device w-16e /path/to/Abundance.app
    -> xcrun devicectl device process launch --device w-16e --console com.abundance.mvp
    -> User takes screenshot on device
    -> iCloud syncs screenshot to ./screenshots/
    -> Claude reads screenshot image (multimodal vision)
    -> Iterate
```

**Gaps:**
- No programmatic UI inspection (accessibility tree)
- No MCP-based build tools (fragile shell commands)
- No simulator UI automation (tap, type, swipe)

---

## Proposed Solution

### New Tools

#### XcodeBuildMCP (72 MCP tools)

**Source:** [github.com/cameroncooke/XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP)

MCP server providing structured Xcode build, deploy, test, and inspection tools. Replaces raw `xcodebuild`/`devicectl` shell commands with typed MCP tool calls.

**Key tools for our workflow:**

| Tool | Purpose | Replaces |
|------|---------|----------|
| `build_device` | Build for physical device | `xcodebuild ... -destination "platform=iOS,name=w-16e"` |
| `build_sim` | Build for simulator | `xcodebuild ... -sdk iphonesimulator` |
| `install_app_device` | Install on physical device | `xcrun devicectl device install app` |
| `launch_app_device` | Launch on device | `xcrun devicectl device process launch` |
| `launch_app_sim` | Launch on simulator | `xcrun simctl launch` |
| `snapshot_ui` | Print view hierarchy with coordinates | **NEW** - no equivalent exists |
| `screenshot` | Capture simulator screenshot | `xcrun simctl io screenshot` |
| `start_device_log_cap` | Capture device logs | `xcrun devicectl device process launch --console` |
| `stop_device_log_cap` | Stop + return logs | Manual Ctrl+C |
| `list_devices` | List connected devices | `xcrun devicectl list devices` |
| `test_device` | Run tests on device | `xcodebuild test ...` |
| `test_sim` | Run tests on simulator | `xcodebuild test ...` |
| `debug_attach_sim` | Attach LLDB to simulator app | **NEW** |
| `swift_package_test` | Run swift package tests | `swift test` |

**Additional capabilities not currently available:**
- LLDB debugging from MCP (breakpoints, variables, stack traces)
- Video recording (`record_sim_video`)
- Simulator management (boot, erase, location, status bar)
- Session defaults (persist build settings across tool calls)

**Installation:**
```bash
claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@beta mcp
```

#### AXe (Accessibility-Based UI Automation CLI)

**Source:** [github.com/cameroncooke/AXe](https://github.com/cameroncooke/AXe)

CLI tool for iOS Simulator UI automation using Apple's Accessibility APIs. Already documented in `axiom:axiom-axe-ref` skill but not installed.

**Key capabilities:**

| Command | Purpose | Current Alternative |
|---------|---------|-------------------|
| `axe describe-ui` | Full accessibility tree with element types, identifiers, labels, frames | None (screenshot only) |
| `axe describe-ui --point x,y` | Element info at specific coordinates | None |
| `axe tap --id "buttonID"` | Tap by accessibility identifier | None (manual testing only) |
| `axe tap --label "Button Text"` | Tap by accessibility label | None |
| `axe type "text"` | Type text into focused field | None |
| `axe gesture scroll-down` | Gesture presets | None |
| `axe screenshot` | Capture screenshot | iCloud sync (delayed) |

**Limitation:** Simulator-only. Physical device UI inspection still uses iCloud screenshots.

**Installation:**
```bash
brew install cameroncooke/axe/axe
```

---

## New Workflow

### Physical Device (w-16e)

```
Claude writes code
    -> XcodeBuildMCP: build_device (scheme: Abundance, device: w-16e)
    -> XcodeBuildMCP: install_app_device
    -> XcodeBuildMCP: launch_app_device + start_device_log_cap
    -> User takes screenshot on device
    -> iCloud syncs to ./screenshots/
    -> Claude reads screenshot + logs
    -> Iterate
```

**What changes:** Build/deploy/launch via MCP tools instead of raw shell. Log capture is structured. Everything else stays the same.

### Simulator

```
Claude writes code
    -> XcodeBuildMCP: build_sim
    -> XcodeBuildMCP: launch_app_sim
    -> AXe: describe-ui (get accessibility tree)
    -> XcodeBuildMCP: snapshot_ui (get view hierarchy with coordinates)
    -> XcodeBuildMCP: screenshot (visual capture)
    -> Claude reads tree + screenshot
    -> If interaction needed: AXe tap/type/swipe by accessibility ID
    -> Iterate
```

**What changes:** Claude gets structured UI data (element tree) in addition to screenshots. Can automate interactions (tap buttons, type text) without manual testing. No iCloud screenshot delay.

### Key Insight from HN Comment

> "For UI iteration, describe_ui returning the accessibility tree might actually be more useful to an agent than a preview screenshot."

This is accurate for several reasons:
1. **Structured data** - Element types, identifiers, labels, enabled state vs pixel inference
2. **Actionable** - If Claude sees `{"id": "loginButton", "label": "Login", "enabled": false}`, it knows exactly what to fix
3. **Faster** - No iCloud sync delay, no screenshot transfer
4. **Automatable** - Claude can tap elements by ID, not just describe what it sees

Screenshots remain valuable for visual layout verification, but the accessibility tree is the primary debugging signal.

---

## Changes Required

### 1. Install XcodeBuildMCP

```bash
claude mcp add XcodeBuildMCP -- npx -y xcodebuildmcp@beta mcp
```

Verify: Restart Claude Code, confirm XcodeBuildMCP tools appear in tool list.

### 2. Install AXe

```bash
brew install cameroncooke/axe/axe
axe --version  # Verify
```

### 3. Update device-tester skill

**File:** `.claude/skills/device-tester.md`

**Changes:**
- Add "MCP-Based Build & Deploy" section using XcodeBuildMCP tools
- Add "UI Inspection" section with AXe `describe-ui` and XcodeBuildMCP `snapshot_ui`
- Remove stale `sim.sh` reference at line 388
- Keep existing crash/perf/test routing logic (unchanged)
- Document fallback to raw commands if XcodeBuildMCP is unavailable

### 4. Delete ITERATION-SYSTEM-SUMMARY.md

The 4-layer iteration system doc from Nov 2025 is superseded by:
- device-tester skill (Layer 1: build/deploy/iterate)
- Axiom agents (Layer 2-4: crash analysis, perf profiling, issue routing)
- SPEC-OPS-002 (developer workflow spec)

### 5. Future cleanup (not in this pass)

Deferred to a follow-up:
- Remove `scripts/sim.sh`
- Clean sim.sh references from `SPEC-OPS-001`, `check-health.sh`, `regenerate-xcode-project.sh`
- Update SPEC-OPS-002 to reference XcodeBuildMCP
- Update CLAUDE.md quick commands

---

## What Still Requires Xcode

Even with XcodeBuildMCP + AXe, you still need to open Xcode for:

1. **Instruments profiling** - Deep performance analysis (Time Profiler, Allocations, etc.)
2. **Signing & provisioning** - Initial setup and troubleshooting
3. **Interface Builder / Storyboards** - Not applicable (SwiftUI-only per ADR-010)
4. **Debugging complex crashes** - When LLDB via MCP isn't sufficient
5. **Xcode Previews** - If used for rapid SwiftUI iteration

Everything else (build, deploy, test, inspect UI, capture logs, screenshots) can be done from the terminal.

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| XcodeBuildMCP is beta | Keep raw commands as documented fallback in device-tester skill |
| AXe requires simulator | Physical device retains iCloud screenshot workflow |
| New MCP dependency | Pin version, document in environment setup |
| Xcode 26.3+ requirement | Already on Xcode 16+ per SPEC-OPS-002 environment requirements |
| Tool conflicts with Axiom agents | XcodeBuildMCP handles build/deploy; Axiom agents handle diagnosis. No overlap. |

---

## Success Criteria

1. Claude can build + deploy to device w-16e via XcodeBuildMCP MCP tools (no raw shell)
2. Claude can inspect simulator accessibility tree via AXe `describe-ui`
3. Claude can tap/type in simulator via AXe (automated UI interaction)
4. Device-tester skill documents both MCP and fallback approaches
5. `ITERATION-SYSTEM-SUMMARY.md` deleted
6. No regression in existing crash/perf/test agent routing
