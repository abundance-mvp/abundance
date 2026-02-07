---
name: polish
description: Run 4 parallel UI auditors (palette, accessibility, glass, HIG) against changed view files, auto-fix safe violations, build-verify, and report.
---

# Polish

**This command invokes the `polish` skill.** Read and follow `.claude/skills/polish/SKILL.md`.

## Quick Reference

```
diff → audit (4 parallel) → fix → build → report
```

**Arguments:**
- `/polish` — Full pipeline on changed view files
- `/polish --with-specs` — Include view spec cross-referencing

**Skill location:** `.claude/skills/polish/SKILL.md`
