# Claude Code Commands

Custom slash commands for the Abundance MVP project. All project-level commands use the `project:` namespace.

## Available Commands

### iOS Development (REQUIRED: ios-superpowers)

**CRITICAL:** For ALL iOS/Swift work, use `/project:ios-superpowers` instead of raw superpowers skills.

#### `/project:ios-superpowers <action> <context>`

iOS-aware orchestrator that ensures Apple documentation is fetched via `/axiom:apple-docs-research` before any superpowers workflow.

**Actions:**
| Action | Example | Replaces |
|--------|---------|----------|
| `brainstorm <topic>` | `/project:ios-superpowers brainstorm biometric auth` | `superpowers:brainstorming` |
| `plan <feature>` | `/project:ios-superpowers plan camera capture` | `superpowers:writing-plans` |
| `execute <plan-path>` | `/project:ios-superpowers execute docs/plans/xxx.md` | `superpowers:executing-plans` |
| `review` | `/project:ios-superpowers review` | `superpowers:requesting-code-review` |
| `debug <issue>` | `/project:ios-superpowers debug CI failure` | `superpowers:systematic-debugging` |
| `tdd <feature>` | `/project:ios-superpowers tdd HouseholdItemDetector` | `superpowers:test-driven-development` |
| `parallel <tasks>` | `/project:ios-superpowers parallel "task1, task2"` | `superpowers:dispatching-parallel-agents` |

**See**: `.claude/commands/ios-superpowers.md`

---

#### `/project:device-tester`

Iterative testing on physical device with crash analysis and screenshot debugging.

**Example**: `/project:device-tester`

**See**: `.claude/commands/device-tester.md`

---

### Troubleshooting

#### `/project:troubleshoot <issue-description>`

End-to-end troubleshooting pipeline: triage, debug via superpowers skills, verify fix, write regression test, code review, and report.

**Examples:**
- `/project:troubleshoot "camera crash on tab switch"` — iOS domain, routes to `ios-superpowers debug`
- `/project:troubleshoot "Cloud Function 403"` — Backend domain, routes to `backend-superpowers`
- `/project:troubleshoot "upload 403 + function never fires"` — Multi-domain, parallel agents

**See:** `.claude/skills/troubleshoot/SKILL.md`

---

### Infrastructure Commands

#### `/project:gcp-deploy <function>`

Deploy Cloud Functions with verification.

**Example**: `/project:gcp-deploy catalogItem`

**See**: `.claude/commands/gcp-deploy.md`

---

### Apple Documentation

For Apple Developer documentation, use the Axiom skill directly:

```bash
/axiom:apple-docs-research SwiftUI.View
```

This is automatically invoked by `/project:ios-superpowers` workflows.

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

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Skill Documentation**: `.claude/skills/*/SKILL.md`
- **Agent Specifications**: `.claude/agents/*.md`
- **Context Map**: `docs/context-map.json`
