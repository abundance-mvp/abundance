---
date: 2026-02-09
status: Fixed
priority: P1
type: bug
component: ios
source: device-tester
related-files:
  - scripts/device-monitor.sh
screenshots: []
axiom-agent: null
branch: claude/pedantic-bhabha
design-doc: null
---

## Summary

`device-monitor.sh` crashes on every run due to 4 bash scripting bugs interacting with `set -euo pipefail`.

## Description

The device monitor script (`scripts/device-monitor.sh`) fails within seconds of starting. Four independent bugs compound to make the script unusable:

1. **`grep -c` multi-line output** — `grep -c "SCREENSHOT_MARKER"` can return multi-line output, breaking the arithmetic comparison `[[ "$local_marker_count" -gt "$LAST_MARKER_COUNT" ]]` with `syntax error in expression`.

2. **`local` outside function scope** — Lines 226, 231, 242, 243 used `local` keyword in the top-level `while true` loop. `local` is only valid inside a function, causing `local: can only be used in a function`.

3. **Stale marker reprocessing** — `LAST_MARKER_COUNT=0` on startup causes markers from previous sessions to be reprocessed. This triggers a 60-second screenshot polling loop (`find ... -newer`) waiting for an iCloud screenshot that will never arrive, then exits.

4. **`((attempts++))` falsy zero** — When `attempts=0`, the post-increment `((attempts++))` evaluates the pre-increment value `0`, which is falsy in bash arithmetic, returning exit code 1. With `set -e`, this kills the script. Additionally, `find ... | head -1` triggers SIGPIPE (exit 141) under `pipefail` when `find` has more output after `head` closes.

## Expected Behavior

`device-monitor.sh` runs continuously, polling device logs every 5s and correlating new screenshot markers with iCloud-synced screenshots.

## Actual Behavior

Script crashes within 5-10 seconds of starting on every invocation. Error messages include:
- `line 224: [[: 0\n0: syntax error in expression`
- `line 226: local: can only be used in a function`

## Technical Context

- Device: w-16e (iPhone 16e)
- Script uses `set -euo pipefail` (strict mode)
- On-device JSONL logs at `Documents/.debug/logs/session-*.jsonl`
- Screenshot markers written by `ScreenshotMonitor` in DEBUG builds

## Fix Applied

All 4 bugs fixed in this session:

1. `grep -c ... || true` instead of `grep -c ... | tail -1`
2. Removed `local` from top-level loop variables
3. `LAST_MARKER_COUNT=-1` with first-iteration seed to current count (skips stale markers)
4. `attempts=$((attempts + 1))` instead of `((attempts++))`, and `find -print -quit` instead of `find | head -1`
