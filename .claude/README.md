# Claude Project Configuration

This repo is **Claude Code–ready** with a complete skill and command system.

## Directory Structure

```
.claude/
├── skills/                    # Auto-loaded context skills
│   ├── ios-superpowers/       # iOS development orchestrator
│   ├── backend-superpowers/   # Firebase + GCP unified skill (NEW)
│   ├── troubleshoot/          # End-to-end troubleshooting pipeline
│   ├── device-tester/         # Physical device testing
│   ├── gemini-integration/    # AI pipeline patterns
│   ├── firebase-superpowers/  # DEPRECATED → use backend-superpowers
│   └── gcp-superpowers/       # DEPRECATED → use backend-superpowers
├── commands/                  # User-invoked via /project:command-name
│   ├── ios-superpowers.md     # /project:ios-superpowers
│   ├── device-tester.md       # /project:device-tester
│   └── gcp-deploy.md          # /project:gcp-deploy
├── hooks/                     # Automatic triggers
└── settings.json              # Plugin configuration
```

## Skills Overview

### Primary Skills

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `ios-superpowers` | iOS development orchestrator | ALL iOS/Swift work |
| `backend-superpowers` | Firebase + GCP + Gemini operations | ALL backend work (auto-routes to gemini-integration) |
| `troubleshoot` | End-to-end troubleshooting pipeline | Build failures, runtime crashes, test failures, production errors |
| `device-tester` | Physical device testing | Device debugging |

### Sub-Skills (Auto-Routed)

| Skill | Routed From | Purpose |
|-------|-------------|---------|
| `gemini-integration` | `backend-superpowers` | Gemini 3 tool calling, thought signatures, AI pipeline code |

### Deprecated Skills

| Skill | Replacement | Status |
|-------|-------------|--------|
| `firebase-superpowers` | `backend-superpowers` | Remove after 2026-02-17 |
| `gcp-superpowers` | `backend-superpowers` | Remove after 2026-02-17 |

## Commands Reference

### iOS Development

```bash
/project:ios-superpowers <action> <context>
  Actions: debug | tdd | review | plan | execute | brainstorm | parallel

/project:device-tester
  Physical device testing workflow

/project:troubleshoot <issue-description>
  End-to-end troubleshooting: triage → debug → verify → test → review → report
```

### Backend Operations

```bash
/project:gcp-deploy <function> [flags]
  Flags: --staging | --production | --verify | --notify
```


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

See `backend-superpowers` skill for complete MCP tool inventory.

## Quick Start

### iOS Development

```bash
# Debug an issue
/project:ios-superpowers debug "@MainActor warning in CameraViewModel"

# Plan a feature
/project:ios-superpowers plan "real-time object detection"

# Code review
/project:ios-superpowers review
```

### Backend Operations

```bash
# Deploy function with verification
/project:gcp-deploy ai-pipeline-orchestrator --production --verify

# Query function logs (direct MCP)
mcp__plugin_firebase_firebase__functions_get_logs
  function_names: ["ai-pipeline-orchestrator"]
  min_severity: "WARNING"
```

## Related Documentation

- **Quick Reference:** `docs/dev-workflow/QUICK-REFERENCE.md`
- **MCP Consolidation Plan:** `docs/plans/2026-01-17-mcp-skill-consolidation-plan.md`
- **Project Root:** `CLAUDE.md`

## Trust & Setup

When prompted by Claude Code, trust this folder to enable:
- Auto-install of marketplace plugins
- Repo-scoped skill/command loading
- Hook execution
