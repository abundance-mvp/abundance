# .debug/ Directory - Abundance Development Debugging

This directory contains development-time debugging artifacts and is **git-ignored**.

## Structure

```
.debug/
├── logs/                    # Simulator session logs
│   └── session-*.jsonl      # JSON Lines format, one event per line
├── issues/                  # Bug/issue tracking
│   ├── raw/                 # Unprocessed issues (captured during testing)
│   ├── enriched/            # Auto-enriched issue JSON
│   ├── triaged/             # Agent-processed, ready for dispatch
│   └── in-progress/         # Currently being worked on
├── completed/               # Resolved artifacts
│   ├── issues/              # Resolved issue files
│   └── logs/                # Completed enrichment logs
├── crashes/                 # Crash reports
│   └── crash-*.txt          # Crash logs from simulator
└── health/                  # Dependency health checks
    └── health-*.json        # Firebase, AI provider status
```

## Usage

### Capturing Logs

Logs are automatically captured when you run:
```bash
./scripts/sim.sh
```

Logs are written to `.debug/logs/session-<timestamp>.jsonl` in JSON Lines format.

### Capturing Issues

While testing the app, if you find a bug, tell Claude:
- "capture this issue"
- "file a bug"
- "log this problem"

Claude uses the `capture-issue` skill which:
1. Gathers issue details conversationally
2. Creates raw issue in `.debug/issues/raw/`
3. Auto-enriches to `.debug/issues/enriched/`

> **Note**: The old `capture-issue.sh` script is deprecated. Use the skill for unified in-session capture + enrichment.

### Triaging Issues

When you're ready to process captured issues:
```bash
claude triage-issues
```

This command:
1. Reads all raw issues
2. Analyzes attached logs
3. Classifies issues (bug/ux/spec-drift/performance)
4. **For iOS issues:** Invokes `apple-docs-fetcher` to verify API usage (MANDATORY)
5. Creates spec documents in `docs/bugs/` or `docs/refinements/`
6. Moves triaged issues to `.debug/issues/triaged/`

### iOS Issues - Apple Docs Verification

For all iOS-related issues (Swift files, iOS framework errors):

- **Triage** (`claude triage-issues`): Fetches Apple docs for APIs in the issue
- **Troubleshoot** (`claude troubleshoot`): Fetches Apple docs before and after fix
- **Code Review** (`/super-code-review`): Fetches Apple docs for changed iOS code

This ensures all iOS fixes use the latest Apple API patterns.

### Dispatching Agents

To work on multiple issues in parallel:
```bash
claude dispatch --parallel
```

This creates git worktrees and launches specialized agents for each issue.

## Log Format

Logs use structured JSON format (one JSON object per line):

```json
{"severity":"INFO","message":"Button tapped: Catalog Item on HomeView","category":"ui","metadata":{"timestamp":"2025-11-16T10:30:00Z","button":"Catalog Item","screen":"HomeView"}}
{"severity":"ERROR","message":"Data load failed: CatalogItem - Network error","category":"data","metadata":{"timestamp":"2025-11-16T10:30:05Z","error":"URLError"}}
```

## Severity Levels

- **INFO**: Normal operations, button taps, data loads
- **WARNING**: Retries, slow operations, quota warnings
- **ERROR**: Failures (network errors, Firestore denials)
- **CRITICAL**: System-level failures (out of memory, auth failures)

## Issue Types

- **bug**: Something is broken (crash, error, wrong behavior)
- **ux-issue**: Works but feels wrong (poor UX, confusing flow)
- **spec-drift**: Implementation doesn't match spec docs
- **silent-failure**: No error but doesn't work (button unresponsive)
- **performance**: Too slow (violates performance specs)

## Workflow Example

1. **Development session**:
   ```bash
   ./scripts/sim.sh
   ```

2. **Find bug while testing**:
   Tell Claude: "capture this issue"
   (Claude gathers details and auto-enriches)

3. **Continue testing, find more issues...**

4. **End of day - triage**:
   ```bash
   claude triage-issues
   ```

5. **Dispatch agents to fix**:
   ```bash
   claude dispatch --parallel
   ```

6. **Agents report back with PRs ready for review**

7. **Resolved issues move to** `.debug/completed/issues/`

## Related Documentation

- `docs/design/MONITORING-001.md` - Backend logging strategy
- `docs/adr/ADR-013-observability-stack.md` - Observability decisions
- `docs/test/TEST-STRATEGY-001.md` - Testing approach

## Notes

- All files in `.debug/` are git-ignored
- Logs rotate automatically (kept for 7 days)
- Issue documents are markdown for easy reading/editing
- Claude agents can read and analyze these files directly
