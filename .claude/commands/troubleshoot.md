---
name: troubleshoot
description: End-to-end troubleshooting pipeline — triage, debug, verify, test, review, report
---

# Troubleshoot

**This command invokes the `troubleshoot` skill.** Read and follow `.claude/skills/troubleshoot/SKILL.md`.

## Quick Reference

```
triage → context → debug → verify → test → review → report
                     ↑        │
                     └─ retry ─┘ (max 3)
```

**Arguments:**
- `/troubleshoot <issue-description>` — Full pipeline for the described issue
- `/troubleshoot <error-message>` — Classify and debug the error
- `/troubleshoot` — Interactive, asks for issue description

**Skill location:** `.claude/skills/troubleshoot/SKILL.md`

$ARGUMENTS
