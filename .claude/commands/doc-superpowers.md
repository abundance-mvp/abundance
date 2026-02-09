---
name: doc-superpowers
description: Documentation freshness orchestrator — audit stale docs, review PR impact, update specs, regenerate diagrams, sync CLAUDE.md
---

# doc-superpowers

**This command invokes the `doc-superpowers` skill.** Read and follow `.claude/skills/doc-superpowers/SKILL.md`.

## Quick Reference

```
hash check → scope detection → dispatch agents (parallel) → merge → report
```

**Arguments:**
- `/doc-superpowers audit [scope]` — Full documentation health check
- `/doc-superpowers audit all --plan` — Audit + write update plan to docs/plans/
- `/doc-superpowers review-pr [scope]` — PR-scoped doc review (changed files only)
- `/doc-superpowers update` — Execute updates from prior audit
- `/doc-superpowers diagram` — Regenerate architecture diagrams
- `/doc-superpowers sync` — Sync doc-index with filesystem + freshness report

**Scopes:** `all` | `ios` | `backend` | `architecture` | `adr` | `brand` | `specs` | `testing` | `view-specs` | `claude-md`

**Skill location:** `.claude/skills/doc-superpowers/SKILL.md`
