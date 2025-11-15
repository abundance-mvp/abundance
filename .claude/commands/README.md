# Claude Code Commands

Custom slash commands for the Abundance MVP project.

## Available Commands

### iOS Development Commands

#### `/ios-sprint-executor {sprint-number}`

Orchestrate iOS sprint development with superpowers integration.

**Example**: `/ios-sprint-executor sprint-1`

**Invokes**: `ios-sprint-executor` skill

**See**: `.claude/skills/ios-sprint-executor/SKILL.md`

---

#### `/verified-stage-development stage-X.Y`

Orchestrate stage development with research verification and approval gates.

**Example**: `/verified-stage-development stage-6.2`

**Invokes**: `verified-stage-development` skill

**See**: `.claude/skills/verified-stage-development/SKILL.md`

---

#### `/apple-docs-fetcher {query}`

Fetch Apple Developer documentation via MCP.

**Example**: `/apple-docs-fetcher SwiftUI.View`

**Invokes**: `apple-docs-fetcher` skill

**See**: `.claude/skills/apple-docs-fetcher/SKILL.md`

---

### Project Management Commands

#### `/validate-docs`

Run documentation validator to check for broken links and stale content.

**Example**: `/validate-docs`

**Uses**: `.claude/agents/doc-reviewer.md` agent specification

**Output**: File:line locations of issues with fix suggestions

---

#### `/check-drift`

Check for architecture drift from ADRs with severity-based reporting (P0/P1/P2).

**Example**: `/check-drift`

**Uses**: `.claude/agents/drift-detector.md` agent specification

**Output**: Violations categorized by severity

---

#### `/show-sprint-status`

Display current sprint progress from git branch and sprint plan.

**Example**: `/show-sprint-status`

**Uses**: Git status + docs/roadmap/SPRINT-PLAN-{N}.md

**Output**: Task completion percentage with next steps

---

## Command Architecture

Commands in this project follow two patterns:

### Skill-Based Commands

Commands that invoke project-specific skills:
- Command file (`.claude/commands/feature.md`) invokes skill via Skill tool
- Skill file (`.claude/skills/feature-name/SKILL.md`) contains full implementation
- Integrates with superpowers plugin workflows

### Standalone Commands

Commands that use agent specifications:
- Commands invoke Claude Code's conversational interface directly
- Agent specifications (`.claude/agents/*.md`) guide Claude's behavior
- No external skill dependencies (portable to any repo)

## Integration with CI/CD

Some commands are also invoked by GitHub Actions:

- `/validate-docs` → Runs in `docs-auto-update.yml` workflow
- `/check-drift` → Runs in `security-pr-review.yml` workflow

See `.github/workflows/` for automation configurations.

## Integration with Superpowers

Many skills integrate with the superpowers plugin via SlashCommand tool:
- `/superpowers:write-plan` - Create implementation plans
- `/superpowers:execute-plan` - Execute plans with batch review

See individual skill documentation for integration details.

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Skill Documentation**: `.claude/skills/*/SKILL.md`
- **Agent Specifications**: `.claude/agents/*.md`
- **CI/CD Architecture**: `docs/tech-stack/GITHUB-ACTIONS-ARCHITECTURE-001.md`
- **Context Map**: `docs/context-map.json`
