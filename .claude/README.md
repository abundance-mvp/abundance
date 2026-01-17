# Claude Project Configuration

This repo is **Claude Code–ready** with a complete skill and command system.

## Directory Structure

```
.claude/
├── skills/                    # Auto-loaded context skills
│   ├── ios-superpowers/       # iOS development orchestrator
│   ├── backend-superpowers/   # Firebase + GCP unified skill (NEW)
│   ├── device-tester.md       # Physical device testing
│   ├── gemini-integration/    # AI pipeline patterns
│   ├── firebase-superpowers/  # DEPRECATED → use backend-superpowers
│   └── gcp-superpowers/       # DEPRECATED → use backend-superpowers
├── commands/                  # User-invoked via /project:command-name
│   ├── ios-superpowers.md     # /project:ios-superpowers
│   ├── ios-debug.md           # /project:ios-debug
│   ├── device-tester.md       # /project:device-tester
│   ├── gcp-deploy.md          # /project:gcp-deploy
│   └── dispatch.md            # /project:dispatch
├── hooks/                     # Automatic triggers
└── settings.json              # Plugin configuration
```

## Skills Overview

### Primary Skills

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `ios-superpowers` | iOS development orchestrator | ALL iOS/Swift work |
| `backend-superpowers` | Firebase + GCP + Gemini operations | ALL backend work (auto-routes to gemini-integration) |
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

/project:ios-debug <issue>
  Quick debug shortcut

/project:device-tester
  Physical device testing workflow
```

### Backend Operations

```bash
/project:gcp-deploy <function> [flags]
  Flags: --staging | --production | --verify | --notify
```

### Multi-Agent

```bash
/project:dispatch
  Dispatch agents to work on triaged issues
```

## MCP Integration

This project uses official MCP servers for backend operations:

| MCP Server | Tools | Purpose |
|------------|-------|---------|
| Firebase | 29 | Firestore, Functions, Auth, FCM, RemoteConfig, RTDB |
| Observability | 13 | Logging, Metrics, Tracing, Alerts, Errors |
| Storage | 17 | GCS buckets, objects, IAM |
| GCloud | 1 | General gcloud CLI |
| Sosumi | 2 | Apple Developer documentation |

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
