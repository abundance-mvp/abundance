# Xcode 26.3 Native MCP Bridge Integration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Apple's native `xcrun mcpbridge` as a second MCP server alongside XcodeBuildMCP, then update all existing skills, permissions, and documentation to leverage the 20 native Xcode tools where they're superior.

**Architecture:** Run both MCP servers simultaneously — mcpbridge for project-aware file ops, builds, diagnostics, SwiftUI previews, Apple doc search, and Swift REPL; XcodeBuildMCP for simulator management, device deployment, UI automation, and debugging. Skills select the right server per operation. No tools are removed — only new routing added.

**Tech Stack:** MCP protocol (stdio transport), Claude Code MCP configuration, project skill markdown files

---

## Scope and Constraints

**In scope:**
- MCP server setup (mcpbridge alongside XcodeBuildMCP)
- Permission whitelist updates
- Skill file modifications (7 skills + CLAUDE.md + README)
- Verification that both servers coexist

**Out of scope:**
- Removing XcodeBuildMCP (complementary, not replaced)
- Changing CI/CD (mcpbridge requires Xcode GUI, not usable in CI)
- New skills or commands (only modifying existing ones)

**Prerequisites:**
- macOS 26 (Tahoe) installed
- Xcode 26.3 RC or later installed
- Xcode running with the Abundance project open when using mcpbridge tools

---

## Task 1: Register the Native MCP Bridge Server

**Files:**
- Modify: `.claude/settings.local.json`

**Step 1: Add the mcpbridge MCP server**

Run:
```bash
claude mcp add --transport stdio xcode -- xcrun mcpbridge
```

This registers `xcode` as an MCP server name. The tools will appear as `mcp__xcode__*` (e.g., `mcp__xcode__BuildProject`, `mcp__xcode__XcodeRead`).

**Step 2: Verify the server appears**

Run:
```bash
claude mcp list
```

Expected: Both `xcode` and `XcodeBuildMCP` appear in the list.

**Step 3: Test basic connectivity**

With Xcode open and the Abundance project loaded, invoke a simple tool to confirm the bridge works:

```
ToolSearch: "+xcode"
```

Then call `mcp__xcode__XcodeListWindows` to verify Xcode responds.

Expected: Returns the Abundance workspace/project window info.

**Step 4: Commit**

```bash
git add .claude/settings.local.json
git commit -m "chore: register Xcode 26.3 native MCP bridge server

Adds xcrun mcpbridge as stdio MCP server alongside XcodeBuildMCP.
Both servers run simultaneously — mcpbridge for builds, previews,
diagnostics, and Apple docs; XcodeBuildMCP for device/sim/UI automation."
```

---

## Task 2: Update Permission Whitelist for mcpbridge Tools

**Files:**
- Modify: `.claude/settings.local.json`

**Step 1: Add mcpbridge tools to the allow list**

Edit `.claude/settings.local.json` to add the 20 mcpbridge tools that skills will use. Group them by category:

```json
{
  "permissions": {
    "allow": [
      // --- Existing permissions (keep all) ---
      "Bash(gh repo create:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git remote set-url:*)",
      "Bash(git push:*)",
      "Skill(apple-docs-fetcher)",
      "mcp__XcodeBuildMCP__get_device_app_path",
      "mcp__XcodeBuildMCP__install_app_device",
      "mcp__XcodeBuildMCP__launch_app_device",
      "mcp__XcodeBuildMCP__start_device_log_cap",
      "mcp__plugin_firebase_firebase__functions_list_functions",
      "mcp__plugin_firebase_firebase__functions_get_logs",
      "Bash(python3:*)",
      "mcp__XcodeBuildMCP__stop_device_log_cap",
      "Bash(claude plugins add:*)",

      // --- Xcode Native MCP Bridge: File Operations ---
      "mcp__xcode__XcodeRead",
      "mcp__xcode__XcodeWrite",
      "mcp__xcode__XcodeUpdate",
      "mcp__xcode__XcodeLS",
      "mcp__xcode__XcodeGlob",
      "mcp__xcode__XcodeGrep",
      "mcp__xcode__XcodeMakeDir",
      "mcp__xcode__XcodeRM",
      "mcp__xcode__XcodeMV",

      // --- Xcode Native MCP Bridge: Build & Testing ---
      "mcp__xcode__BuildProject",
      "mcp__xcode__GetBuildLog",
      "mcp__xcode__RunAllTests",
      "mcp__xcode__RunSomeTests",
      "mcp__xcode__GetTestList",

      // --- Xcode Native MCP Bridge: Diagnostics ---
      "mcp__xcode__XcodeListNavigatorIssues",
      "mcp__xcode__XcodeRefreshCodeIssuesInFile",

      // --- Xcode Native MCP Bridge: Preview & Snippets ---
      "mcp__xcode__RenderPreview",
      "mcp__xcode__ExecuteSnippet",

      // --- Xcode Native MCP Bridge: Documentation & Discovery ---
      "mcp__xcode__DocumentationSearch",
      "mcp__xcode__XcodeListWindows"
    ],
    "deny": [],
    "ask": []
  }
}
```

**Step 2: Verify permissions load**

Start a new Claude Code session and confirm the tools are accessible:
```
ToolSearch: "+xcode Build"
```

Expected: `mcp__xcode__BuildProject` and `mcp__xcode__GetBuildLog` appear.

**Step 3: Commit**

```bash
git add .claude/settings.local.json
git commit -m "chore: whitelist all 20 Xcode native MCP bridge tools

Adds file ops, build, testing, diagnostics, preview, snippets,
documentation search, and discovery tools to permission allow list."
```

---

## Task 3: Update `ios-superpowers` Skill — Apple Docs and Build Verification

**Files:**
- Modify: `.claude/skills/ios-superpowers/SKILL.md`

This is the highest-impact change. Two key improvements:

1. **Apple docs grounding**: Replace `axiom-apple-docs-research` references with `DocumentationSearch` as the primary source, keeping axiom as fallback.
2. **Build verification**: Replace `swift build` / `swift test` with `BuildProject` / `RunAllTests` for richer structured output.

**Step 1: Add mcpbridge section to the skill**

After the existing `## 1. Domain Detection` section header (before the domain table), insert a new section:

At the very top of the file, after the YAML frontmatter and before `## 1. Domain Detection`, add:

```markdown
## 0. MCP Server Availability

Two MCP servers provide build and documentation tools. Check availability at session start.

| Server | Tool Prefix | Requires | Use For |
|--------|-------------|----------|---------|
| **Xcode Native Bridge** (`xcode`) | `mcp__xcode__*` | Xcode running with project open, macOS 26 | Builds, previews, diagnostics, Apple docs, project-aware file ops |
| **XcodeBuildMCP** (`XcodeBuildMCP`) | `mcp__XcodeBuildMCP__*` | None (headless) | Simulators, devices, UI automation, debugging |

**Availability check:** At session start, try `mcp__xcode__XcodeListWindows`. If it fails, mcpbridge is unavailable — fall back to `swift build` and `axiom-apple-docs-research` for all operations. Log: "mcpbridge unavailable — using CLI fallback."

---
```

**Step 2: Update the plan action routing for Apple docs**

In section `## 2. Routing Matrix`, under `### plan Action`, update the `*` wildcard row:

Change:
```markdown
| * | - | `axiom-apple-docs-research` | `writing-plans` |
```

To:
```markdown
| * | - | `axiom-apple-docs-research` | `writing-plans` |
```

No change to the routing table itself — but update the `### plan Execution` sequence in section 3:

Change:
```
1. domain = DETECT(context)
2. route = ROUTING_MATRIX[plan][domain]
3. IF route.axiom_agent:
   Task(subagent_type=route.axiom_agent, prompt=context)
4. Skill(skill=route.axiom_skill OR "axiom-apple-docs-research")
5. Skill(skill="superpowers:writing-plans")
6. VERIFY()
```

To:
```
1. domain = DETECT(context)
2. route = ROUTING_MATRIX[plan][domain]
3. IF route.axiom_agent:
   Task(subagent_type=route.axiom_agent, prompt=context)
4. APPLE_DOCS(context):
   IF mcpbridge available:
     mcp__xcode__DocumentationSearch(query=context)
   ELSE:
     Skill(skill=route.axiom_skill OR "axiom-apple-docs-research")
5. Skill(skill="superpowers:writing-plans")
6. VERIFY()
```

**Step 3: Update the brainstorm execution for Apple docs**

Change:
```
1. domain = DETECT(context)
2. IF domain starts with "ui-":
   Skill(skill="axiom-hig")
   Skill(skill="axiom-swiftui-architecture")
3. ELSE:
   Skill(skill="axiom-apple-docs-research", args=context)
4. Skill(skill="superpowers:brainstorming")
```

To:
```
1. domain = DETECT(context)
2. IF domain starts with "ui-":
   Skill(skill="axiom-hig")
   Skill(skill="axiom-swiftui-architecture")
3. ELSE:
   APPLE_DOCS(context):
     IF mcpbridge available:
       mcp__xcode__DocumentationSearch(query=context)
     ELSE:
       Skill(skill="axiom-apple-docs-research", args=context)
4. Skill(skill="superpowers:brainstorming")
```

**Step 4: Update verification checklist**

Change section `## 4. Verification Checklist`:

```markdown
After every execution, verify:

- [ ] No deprecated APIs introduced (check via `axiom-apple-docs-research`)
- [ ] Swift 6 concurrency satisfied (actor isolation, Sendable)
- [ ] API signatures match Apple documentation
- [ ] Tests pass (if applicable): `swift test`
- [ ] If backend changes deployed: verify via `backend-superpowers`
```

To:
```markdown
After every execution, verify:

- [ ] No deprecated APIs introduced (check via `mcp__xcode__DocumentationSearch` or `axiom-apple-docs-research`)
- [ ] Swift 6 concurrency satisfied (actor isolation, Sendable)
- [ ] API signatures match Apple documentation
- [ ] Build passes: `mcp__xcode__BuildProject` (preferred) or `swift build` (fallback)
- [ ] Tests pass (if applicable): `mcp__xcode__RunAllTests` (preferred) or `swift test` (fallback)
- [ ] If backend changes deployed: verify via `backend-superpowers`
```

**Step 5: Commit**

```bash
git add .claude/skills/ios-superpowers/SKILL.md
git commit -m "feat: integrate mcpbridge into ios-superpowers routing

- Add MCP server availability check (Section 0)
- Route Apple docs through DocumentationSearch when available
- Route builds through BuildProject/RunAllTests when available
- Keep axiom-apple-docs-research and swift build as fallbacks"
```

---

## Task 4: Update `troubleshoot` Skill — Diagnostics and Build Verification

**Files:**
- Modify: `.claude/skills/troubleshoot/SKILL.md`

**Step 1: Update Phase 2 iOS context gathering**

Change the iOS Context section (lines ~55-67):

```markdown
### iOS Context

\`\`\`bash
# Build output (always)
swift build 2>&1 | tail -50

# Latest screenshots (if UI issue)
ls -lt screenshots/ | head -5

# Recent device/sim logs (if runtime issue)
XcodeBuildMCP: start_sim_log_cap or start_device_log_cap

# Build settings (if build issue)
XcodeBuildMCP: show_build_settings
\`\`\`
```

To:
```markdown
### iOS Context

\`\`\`
# Build diagnostics (prefer mcpbridge when Xcode is open)
IF mcpbridge available:
  mcp__xcode__XcodeListNavigatorIssues          # All current issues from Issue Navigator
  mcp__xcode__XcodeRefreshCodeIssuesInFile      # Live diagnostics for specific file
  mcp__xcode__GetBuildLog(severity: "error")    # Filtered build log
ELSE:
  swift build 2>&1 | tail -50

# Latest screenshots (if UI issue)
ls -lt screenshots/ | head -5

# Recent device/sim logs (if runtime issue)
XcodeBuildMCP: start_sim_log_cap or start_device_log_cap

# Build settings (if build issue)
XcodeBuildMCP: show_build_settings
\`\`\`
```

**Step 2: Update Phase 4 verification commands**

Change the verification table (line ~150-154):

```markdown
| Domain | Verify Build | Verify Tests | Verify Runtime |
|--------|-------------|-------------|----------------|
| iOS | `swift build` | `swift test` | Optional: `Skill(skill="sim-test")` or `Skill(skill="device-tester")` |
```

To:
```markdown
| Domain | Verify Build | Verify Tests | Verify Runtime |
|--------|-------------|-------------|----------------|
| iOS | `mcp__xcode__BuildProject` or `swift build` | `mcp__xcode__RunAllTests` or `swift test` | Optional: `Skill(skill="sim-test")` or `Skill(skill="device-tester")` |
```

**Step 3: Update the red flags table**

Change:
```markdown
| "Fix looks good, skip verification" | The verify loop is the whole point. `swift build && swift test` minimum. |
```

To:
```markdown
| "Fix looks good, skip verification" | The verify loop is the whole point. `BuildProject` + `RunAllTests` (or `swift build && swift test`) minimum. |
```

**Step 4: Commit**

```bash
git add .claude/skills/troubleshoot/SKILL.md
git commit -m "feat: integrate mcpbridge diagnostics into troubleshoot pipeline

- Phase 2 uses XcodeListNavigatorIssues + GetBuildLog for richer context
- Phase 4 prefers BuildProject/RunAllTests over raw CLI
- Fallback to swift build/test when mcpbridge unavailable"
```

---

## Task 5: Update `polish` Skill — Build Verification via mcpbridge

**Files:**
- Modify: `.claude/skills/polish/SKILL.md`

**Step 1: Update Step 6 build verify**

Change (lines ~130-136):
```markdown
### Step 6: Build Verify

\`\`\`bash
swift build
\`\`\`

- **Success:** proceed to report
- **Failure:** revert last batch of fixes, identify which fix broke the build, re-apply others, rebuild (max 2 retries)
- **Still failing after 2 retries:** report build errors as part of output
```

To:
```markdown
### Step 6: Build Verify

\`\`\`
IF mcpbridge available:
  mcp__xcode__BuildProject
  IF failure:
    mcp__xcode__GetBuildLog(severity: "error")    # Structured error details
ELSE:
  swift build
\`\`\`

- **Success:** proceed to report
- **Failure:** revert last batch of fixes, identify which fix broke the build, re-apply others, rebuild (max 2 retries)
- **Still failing after 2 retries:** report build errors as part of output
```

**Step 2: Commit**

```bash
git add .claude/skills/polish/SKILL.md
git commit -m "feat: polish skill uses BuildProject for build verification

Prefers mcpbridge BuildProject + GetBuildLog for structured error
output. Falls back to swift build when Xcode is not running."
```

---

## Task 6: Update `device-tester` Skill — Add Preview Rendering

**Files:**
- Modify: `.claude/skills/device-tester/SKILL.md`

The key addition here is `RenderPreview` — Claude can now see SwiftUI previews without needing a device screenshot.

**Step 1: Add RenderPreview to the UI Inspection section**

After the existing `### Physical Device: Screenshots` section (after line ~119), add a new subsection:

```markdown
### SwiftUI Preview Rendering (mcpbridge)

When Xcode is open and mcpbridge is available, render SwiftUI previews directly:

\`\`\`
mcp__xcode__RenderPreview(file: "Sources/InventoryFeature/ItemCard.swift")
\`\`\`

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
```

**Step 2: Add ExecuteSnippet for quick validation**

After the RenderPreview section, add:

```markdown
### Swift REPL (mcpbridge)

Execute Swift snippets in the context of the project (when mcpbridge available):

\`\`\`
mcp__xcode__ExecuteSnippet(code: "print(Bundle.main.bundleIdentifier ?? \"unknown\")")
\`\`\`

Useful for quick validation of:
- Computed property logic
- Date formatting
- Codable round-trips
- Expression evaluation during debugging
```

**Step 3: Commit**

```bash
git add .claude/skills/device-tester/SKILL.md
git commit -m "feat: device-tester adds RenderPreview and ExecuteSnippet

SwiftUI preview rendering via mcpbridge for visual feedback without
deploying. Swift REPL for quick expression validation during debugging."
```

---

## Task 7: Update `sim-test` Skill — mcpbridge Build Alternative

**Files:**
- Modify: `.claude/skills/sim-test/SKILL.md`

The sim-test pipeline stays XcodeBuildMCP-primary for simulator interaction, but the build step can leverage mcpbridge for better error diagnostics.

**Step 1: Update Step 2 build step**

Change (lines ~38-44):
```markdown
### Step 2: Build & Launch

1. `build_sim` — build for iOS Simulator
2. `boot_sim` — ensure simulator is booted
3. `build_run_sim` — install and launch the app

If build fails, stop and report the build error. Do not proceed to scenarios.
```

To:
```markdown
### Step 2: Build & Launch

1. `build_sim` — build for iOS Simulator (XcodeBuildMCP)
2. `boot_sim` — ensure simulator is booted (XcodeBuildMCP)
3. `build_run_sim` — install and launch the app (XcodeBuildMCP)

If build fails:
- IF mcpbridge available: `mcp__xcode__GetBuildLog(severity: "error")` for detailed diagnostics
- Report the build error with full context. Do not proceed to scenarios.
```

**Step 2: Commit**

```bash
git add .claude/skills/sim-test/SKILL.md
git commit -m "feat: sim-test uses mcpbridge GetBuildLog for build failure diagnostics

Build step remains XcodeBuildMCP (headless capable). On failure,
mcpbridge provides structured error details if Xcode is running."
```

---

## Task 8: Update `fresh-deploy` Skill — mcpbridge Build Option

**Files:**
- Modify: `.claude/skills/fresh-deploy/SKILL.md`

**Step 1: Update Phase 4 build step**

After the existing Phase 4.3 `build_device` section (line ~174), add a diagnostic fallback:

Change:
```markdown
### 4.3 Build for Device

\`\`\`
mcp__XcodeBuildMCP__build_device
\`\`\`

If build fails, route to `build-fixer` agent and **STOP**.
```

To:
```markdown
### 4.3 Build for Device

\`\`\`
mcp__XcodeBuildMCP__build_device
\`\`\`

If build fails:
1. IF mcpbridge available: `mcp__xcode__GetBuildLog(severity: "error")` for structured diagnostics
2. Route to `build-fixer` agent with the diagnostic output and **STOP**.
```

**Step 2: Commit**

```bash
git add .claude/skills/fresh-deploy/SKILL.md
git commit -m "feat: fresh-deploy uses mcpbridge for build failure diagnostics

On device build failure, fetch structured build log from mcpbridge
before routing to build-fixer agent."
```

---

## Task 9: Update `CLAUDE.md` — Document Both MCP Servers

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add mcpbridge to the Quick Commands section**

In the `## Quick Commands` section, under `# iOS Development`, add:

```markdown
# Xcode MCP Bridge (requires Xcode running + macOS 26)
mcp__xcode__BuildProject                     # Build via Xcode (structured errors)
mcp__xcode__RenderPreview                    # Render SwiftUI preview snapshot
mcp__xcode__DocumentationSearch              # Search Apple docs + WWDC transcripts
mcp__xcode__XcodeListNavigatorIssues         # Mirror Xcode Issue Navigator
mcp__xcode__ExecuteSnippet                   # Swift REPL in project context
```

**Step 2: Add to the MCP section**

After the existing MCP integration note at the bottom (or create a new section after `## CI/CD`), add:

```markdown
## MCP Servers

| Server | Transport | Tools | Requires | Purpose |
|--------|-----------|-------|----------|---------|
| `xcode` (mcpbridge) | stdio | 20 | Xcode running, macOS 26 | Builds, previews, diagnostics, Apple docs, project-aware file ops |
| `XcodeBuildMCP` | stdio | 60+ | None (headless) | Simulators, devices, UI automation, debugging |
| Firebase | plugin | 29 | Firebase project | Firestore, Functions, Auth, FCM, etc. |
| Observability | plugin | 13 | GCP project | Logging, metrics, tracing |

**Both Xcode servers run simultaneously.** Skills route to the right server:
- Builds/diagnostics/previews/docs → mcpbridge (when available)
- Simulator/device/UI automation → XcodeBuildMCP (always)
```

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: document Xcode native MCP bridge in CLAUDE.md

Adds quick commands for mcpbridge tools and MCP server comparison
table showing when each Xcode server is used."
```

---

## Task 10: Update `.claude/README.md` — MCP Server Table

**Files:**
- Modify: `.claude/README.md`

**Step 1: Update the MCP Integration table**

Change the existing table (lines ~74-84):

```markdown
## MCP Integration

This project uses official MCP servers for backend operations:

| MCP Server | Tools | Purpose |
|------------|-------|---------|
| Firebase | 29 | Firestore, Functions, Auth, FCM, RemoteConfig, RTDB |
| Observability | 13 | Logging, Metrics, Tracing, Alerts, Errors |
| Storage | 17 | GCS buckets, objects, IAM |
| GCloud | 1 | General gcloud CLI |
| Sosumi | 2 | Apple Developer documentation |
```

To:
```markdown
## MCP Integration

This project uses MCP servers for iOS development and backend operations:

| MCP Server | Tools | Requires | Purpose |
|------------|-------|----------|---------|
| **Xcode Native Bridge** (`xcode`) | 20 | Xcode running, macOS 26 | Builds, SwiftUI previews, diagnostics, Apple docs, project-aware file ops |
| **XcodeBuildMCP** | 60+ | None (headless) | Simulators, devices, UI automation, debugging, project scaffolding |
| Firebase | 29 | Firebase project | Firestore, Functions, Auth, FCM, RemoteConfig, RTDB |
| Observability | 13 | GCP project | Logging, Metrics, Tracing, Alerts, Errors |
| Storage | 17 | GCS project | GCS buckets, objects, IAM |
| GCloud | 1 | GCP project | General gcloud CLI |
| Sosumi | 2 | None | Apple Developer documentation |

**Xcode Native Bridge vs XcodeBuildMCP:** Both run simultaneously. mcpbridge requires Xcode GUI open (not usable in CI). XcodeBuildMCP works headless. Skills automatically route to the appropriate server.
```

**Step 2: Commit**

```bash
git add .claude/README.md
git commit -m "docs: add Xcode native MCP bridge to README MCP table

Shows both Xcode MCP servers with requirements and purpose.
Explains they're complementary, not replacements."
```

---

## Task 11: Update `axiom-integration.md` Reference

**Files:**
- Modify: `.claude/skills/ios-superpowers/references/axiom-integration.md`

**Step 1: Add a new section at the end of the file**

After the existing `## Skill Invocation Examples` section, add:

```markdown
---

## Xcode Native MCP Bridge Tools

When Xcode is open (macOS 26+), these tools augment Axiom skills:

| mcpbridge Tool | Augments | How |
|----------------|----------|-----|
| `mcp__xcode__DocumentationSearch` | `axiom-apple-docs-research` | Semantic search across Apple docs + WWDC transcripts (on-device) |
| `mcp__xcode__BuildProject` | `swift build` | Triggers Xcode build with structured success/failure |
| `mcp__xcode__GetBuildLog` | `swift build 2>&1` | Filtered build log (errors, warnings, notes) with file paths |
| `mcp__xcode__RunAllTests` | `swift test` | Runs tests from active test plan with structured results |
| `mcp__xcode__RunSomeTests` | `swift test --filter` | Run specific test targets or methods |
| `mcp__xcode__RenderPreview` | Device screenshots | Renders SwiftUI Preview as snapshot image |
| `mcp__xcode__ExecuteSnippet` | Swift playground | REPL-like execution in file context |
| `mcp__xcode__XcodeListNavigatorIssues` | `axiom:build-fixer` | Mirrors Issue Navigator for all current warnings/errors |
| `mcp__xcode__XcodeRefreshCodeIssuesInFile` | Manual inspection | Live compiler diagnostics for a specific file |

**Fallback rule:** If mcpbridge is unavailable (Xcode closed, not macOS 26), all operations fall back to existing Axiom skills and CLI commands. No skill breaks without mcpbridge.
```

**Step 2: Commit**

```bash
git add .claude/skills/ios-superpowers/references/axiom-integration.md
git commit -m "docs: document mcpbridge tool-to-axiom mapping

Maps each mcpbridge tool to the Axiom skill it augments.
Establishes fallback rule: nothing breaks without mcpbridge."
```

---

## Task 12: Verify Both MCP Servers Work Together

**Files:**
- None (verification only)

**Step 1: Boot simulator and open Xcode**

Ensure:
- Xcode 26.3 is open with `Abundance.xcodeproj`
- iOS Simulator is booted (for XcodeBuildMCP tests)

**Step 2: Test mcpbridge tools**

```
mcp__xcode__XcodeListWindows                                      # Discovery
mcp__xcode__XcodeLS(path: "Sources/")                             # File listing
mcp__xcode__BuildProject                                          # Build
mcp__xcode__GetBuildLog(severity: "error")                        # Build log
mcp__xcode__DocumentationSearch(query: "AVCaptureSession")        # Apple docs
mcp__xcode__RenderPreview(file: "Sources/InventoryFeature/ItemCard.swift")  # Preview
mcp__xcode__GetTestList                                           # Test discovery
mcp__xcode__XcodeListNavigatorIssues                              # Diagnostics
```

Expected: All return valid results without errors.

**Step 3: Test XcodeBuildMCP tools still work**

```
mcp__XcodeBuildMCP__list_sims                     # Simulator listing
mcp__XcodeBuildMCP__snapshot_ui                    # UI hierarchy
mcp__XcodeBuildMCP__screenshot                     # Screenshot
mcp__XcodeBuildMCP__list_devices                   # Device listing
```

Expected: All return valid results — no conflicts between the two MCP servers.

**Step 4: Test the fallback path**

Quit Xcode, then try:
```
mcp__xcode__BuildProject
```

Expected: Fails gracefully. Then verify:
```bash
swift build
```

Expected: Succeeds (CLI fallback works).

**Step 5: Document results**

If all tests pass, no commit needed. If issues found, file them.

---

## Task 13: Update Memory File

**Files:**
- Modify: `/Users/w/.claude/projects/-Users-w-code-abundance-mvp/memory/MEMORY.md`

**Step 1: Add mcpbridge section**

Add a new section to MEMORY.md:

```markdown
## Xcode Native MCP Bridge (Feb 2026)
- Registered as `xcode` MCP server: `xcrun mcpbridge` (stdio transport)
- Requires Xcode running + macOS 26 — NOT usable in CI
- 20 tools: file ops (9), build/test (5), diagnostics (2), preview/snippets (2), docs/discovery (2)
- Tool prefix: `mcp__xcode__*` (e.g., `mcp__xcode__BuildProject`)
- Complementary with XcodeBuildMCP — both run simultaneously
- mcpbridge: builds, previews, diagnostics, Apple docs, project-aware file ops
- XcodeBuildMCP: simulators, devices, UI automation, debugging
- Fallback: all skills work without mcpbridge (CLI + Axiom skills)
- `DocumentationSearch` augments `axiom-apple-docs-research` (semantic search + WWDC transcripts)
- `RenderPreview` renders SwiftUI previews as snapshot images (unique capability)
```

**Step 2: Commit**

Not needed (memory files are not committed to git).

---

## Summary: Tool Routing After Integration

| Operation | Primary (mcpbridge available) | Fallback (mcpbridge unavailable) |
|-----------|-------------------------------|----------------------------------|
| Apple docs lookup | `mcp__xcode__DocumentationSearch` | `axiom-apple-docs-research` skill |
| Build project | `mcp__xcode__BuildProject` | `swift build` |
| Build errors | `mcp__xcode__GetBuildLog` | `swift build 2>&1 \| tail -50` |
| Run all tests | `mcp__xcode__RunAllTests` | `swift test` |
| Run specific tests | `mcp__xcode__RunSomeTests` | `swift test --filter` |
| Live diagnostics | `mcp__xcode__XcodeListNavigatorIssues` | `axiom:build-fixer` agent |
| File diagnostics | `mcp__xcode__XcodeRefreshCodeIssuesInFile` | Manual code inspection |
| SwiftUI preview | `mcp__xcode__RenderPreview` | Device screenshot (`./screenshots/`) |
| Swift REPL | `mcp__xcode__ExecuteSnippet` | None (new capability) |
| Project-aware file ops | `mcp__xcode__XcodeWrite` etc. | Standard `Write`/`Edit` tools |
| Simulator management | XcodeBuildMCP (always) | XcodeBuildMCP (always) |
| Device deployment | XcodeBuildMCP (always) | XcodeBuildMCP (always) |
| UI automation | XcodeBuildMCP (always) | XcodeBuildMCP (always) |
| Debugging | XcodeBuildMCP (always) | XcodeBuildMCP (always) |

## Files Modified

| File | Change |
|------|--------|
| `.claude/settings.local.json` | MCP server registration + permission whitelist |
| `.claude/skills/ios-superpowers/SKILL.md` | Section 0 (availability), doc routing, build/test verification |
| `.claude/skills/troubleshoot/SKILL.md` | Phase 2 diagnostics, Phase 4 build verification |
| `.claude/skills/polish/SKILL.md` | Step 6 build verification |
| `.claude/skills/device-tester/SKILL.md` | RenderPreview + ExecuteSnippet sections |
| `.claude/skills/sim-test/SKILL.md` | Build failure diagnostics |
| `.claude/skills/fresh-deploy/SKILL.md` | Build failure diagnostics |
| `CLAUDE.md` | Quick commands + MCP server table |
| `.claude/README.md` | MCP Integration table update |
| `.claude/skills/ios-superpowers/references/axiom-integration.md` | mcpbridge-to-axiom mapping |
| Memory file | mcpbridge learnings |
