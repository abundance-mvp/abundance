---
name: fresh-deploy
description: Wipe user's Firebase data, deploy Cloud Functions, build & install app on device w-16e
---

# Fresh Deploy Command

**This command invokes the `fresh-deploy` skill.** Read and follow `.claude/skills/fresh-deploy/SKILL.md`.

## Quick Reference

```
wipe data → deploy functions → build → install → launch
```

**Arguments:**
- `/fresh-deploy` — Full pipeline: wipe + deploy + build device
- `/fresh-deploy wipe` — Wipe Firebase data only (no deploy or build)
- `/fresh-deploy deploy` — Deploy Cloud Functions only
- `/fresh-deploy build` — Build & install on device only
- `/fresh-deploy --uid <userId>` — Use specific Firebase UID (default: current auth user)
- `/fresh-deploy --skip-deploy` — Wipe data + build device, skip function deploy

**Skill location:** `.claude/skills/fresh-deploy/SKILL.md`

$ARGUMENTS
