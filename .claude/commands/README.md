# Claude Code Commands

Custom slash commands for the Abundance MVP project.

## Available Commands

### iOS Development (REQUIRED: ios-superpowers)

**CRITICAL:** For ALL iOS/Swift work, use `/ios-superpowers` instead of raw superpowers skills.

#### `/ios-superpowers <action> <context>`

iOS-aware orchestrator that ensures Apple documentation is fetched before any superpowers workflow.

**Actions:**
| Action | Example | Replaces |
|--------|---------|----------|
| `brainstorm <topic>` | `/ios-superpowers brainstorm biometric auth` | `superpowers:brainstorming` |
| `plan <feature>` | `/ios-superpowers plan camera capture` | `superpowers:writing-plans` |
| `execute <plan-path>` | `/ios-superpowers execute docs/plans/xxx.md` | `superpowers:executing-plans` |
| `review` | `/ios-superpowers review` | `superpowers:requesting-code-review` |
| `debug <issue>` | `/ios-superpowers debug CI failure` | `superpowers:systematic-debugging` |
| `tdd <feature>` | `/ios-superpowers tdd HouseholdItemDetector` | `superpowers:test-driven-development` |
| `parallel <tasks>` | `/ios-superpowers parallel "task1, task2"` | `superpowers:dispatching-parallel-agents` |

**See**: `.claude/commands/ios-superpowers.md`

---

#### `/ios-sprint-executor {sprint-number}`

Orchestrate iOS sprint development with ios-superpowers integration.

**Example**: `/ios-sprint-executor sprint-1`

**Note**: Uses ios-superpowers orchestrator internally for all superpowers interactions.

**See**: `.claude/skills/ios-sprint-executor/SKILL.md`

---

#### `/verified-stage-development stage-X.Y`

Orchestrate stage development with research verification and approval gates.

**Example**: `/verified-stage-development stage-6.2`

**Note**: iOS stages (2.2, 3.1, 4.1) use ios-superpowers; non-iOS stages use raw superpowers.

**See**: `.claude/skills/verified-stage-development/SKILL.md`

---

#### `/apple-docs-fetcher {query}`

Fetch Apple Developer documentation via MCP.

**Example**: `/apple-docs-fetcher SwiftUI.View`

**See**: `.claude/skills/apple-docs-fetcher/SKILL.md`

---

### Project Management Commands

#### `/validate-docs`

Run documentation validator to check for broken links and stale content.

**Example**: `/validate-docs`

**Uses**: `.claude/agents/doc-reviewer.md` agent specification

---

#### `/check-drift`

Check for architecture drift from ADRs with severity-based reporting (P0/P1/P2).

**Example**: `/check-drift`

**Uses**: `.claude/agents/drift-detector.md` agent specification

---

#### `/show-sprint-status`

Display current sprint progress from git branch and sprint plan.

**Example**: `/show-sprint-status`

---

### Issue Management Commands

#### `/capture-issue`

Capture bugs, UX issues, or spec drift during testing.

**Example**: `/capture-issue "Camera preview shows black screen on iOS 17"`

**See**: `.claude/skills/capture-issue/SKILL.md`

---

#### `/enrich-issue {issue-file}`

Post-capture issue enrichment with log analysis and Apple docs.

**Example**: `/enrich-issue .claude/.debug/issues/raw/2026-01-13-camera-black-screen.json`

**See**: `.claude/commands/enrich-issue.md`

---

#### `/triage-issues`

Triage and prioritize captured issues.

**Example**: `/triage-issues`

**See**: `.claude/commands/triage-issues.md`

---

#### `/dispatch`

Dispatch parallel agents for independent tasks (triaged issues).

**Example**: `/dispatch`

**Note**: Agents use ios-superpowers which auto-detects iOS context.

**See**: `.claude/commands/dispatch.md`

---

## Command Architecture

Commands in this project follow two patterns:

### Skill-Based Commands

Commands that invoke project-specific skills:
- Command file (`.claude/commands/feature.md`) invokes skill via Skill tool
- Skill file (`.claude/skills/feature-name/SKILL.md`) contains full implementation
- **iOS commands**: Use ios-superpowers orchestrator for Apple docs grounding

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

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Skill Documentation**: `.claude/skills/*/SKILL.md`
- **Agent Specifications**: `.claude/agents/*.md`
- **Context Map**: `docs/context-map.json`
