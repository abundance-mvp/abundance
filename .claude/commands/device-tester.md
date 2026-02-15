---
name: device-tester
description: Iterative testing on device w-16e and simulators with XcodeBuildMCP, AXe UI inspection, crash analysis, and performance profiling
---

# Device Tester Command

**This command invokes the `device-tester` skill.** Read and follow `.claude/skills/device-tester/SKILL.md`.

## Quick Reference

```
build → deploy → launch → inspect → triage → fix → repeat
```

**Arguments:**
- `/device-tester` — Start interactive device testing session
- `/device-tester build` — Build and deploy to device
- `/device-tester sim` — Build and run on simulator
- `/device-tester crash` — Analyze recent crash
- `/device-tester logs` — View console output
- `/device-tester screenshot` — Check latest screenshot
- `/device-tester inspect` — Inspect UI via accessibility tree (simulator)

**Skill location:** `.claude/skills/device-tester/SKILL.md`

$ARGUMENTS
