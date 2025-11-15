# Claude Code Commands (Abundance Scaffold)

Custom slash commands for the Abundance MVP project (template from scaffold).

## Available Commands

### `/validate-docs`

Run documentation validator to check for broken links and stale content.

**Example**: `/validate-docs`

**Uses**: `.claude/agents/doc-reviewer.md` agent specification

**Output**: File:line locations of issues with fix suggestions

---

### `/check-drift`

Check for architecture drift from ADRs with severity-based reporting (P0/P1/P2).

**Example**: `/check-drift`

**Uses**: `.claude/agents/drift-detector.md` agent specification

**Output**: Violations categorized by severity

---

### `/show-sprint-status`

Display current sprint progress from git branch and sprint plan.

**Example**: `/show-sprint-status`

**Uses**: Git status + docs/roadmap/SPRINT-PLAN-{N}.md

**Output**: Task completion percentage with next steps

---

## Command Architecture

These commands are **standalone** and do not depend on skills from spec-kit:

- Commands invoke Claude Code's conversational interface
- Agent specifications (`.claude/agents/*.md`) guide Claude's behavior
- No external skill dependencies (portable to any repo)

## Integration with CI/CD

Some commands are also invoked by GitHub Actions:

- `/validate-docs` → Runs in `docs-auto-update.yml` workflow
- `/check-drift` → Runs in `security-pr-review.yml` workflow

See `.github/workflows/` for automation configurations.

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Agent Specifications**: `.claude/agents/*.md`
- **CI/CD Architecture**: `docs/tech-stack/GITHUB-ACTIONS-ARCHITECTURE-001.md`
