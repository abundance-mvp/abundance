# Claude Code Automation Architecture

**ID**: CLAUDE-CODE-AUTOMATION-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: Claude Code automation infrastructure for Abundance MVP

## Overview

Claude Code automation provides developer productivity through hooks, agents, commands, plugins, and MCP integrations. This document specifies the architecture and implementation patterns.

## Architecture

### 5 Plugin Types

1. **Commands** (`.claude/commands/`): Slash commands for quick actions
   - Example: `/validate-docs` → invoke doc-reviewer agent
   - Format: Markdown files with prompt content
   - Discovery: Auto-loaded from directory

2. **Agents** (`.claude/agents/`): Autonomous task executors
   - Example: `@drift-detector` → scan for ADR violations
   - Format: Markdown with role, behavior, output specs
   - Invocation: Via commands or @mention

3. **Skills** (`.claude/skills/`): Reusable workflows
   - Example: `ios-sprint-executor` → orchestrate sprint tasks
   - Format: Markdown with step-by-step instructions
   - Auto-loaded: Available to all Claude instances

4. **Hooks** (`.claude/hooks/`): Event-triggered scripts
   - Example: `bash_command_validator.py` → block dangerous commands
   - Events: SessionStart, Bash, FileEdit, etc.
   - Format: Executable scripts (Bash, Python)

5. **MCP (Model Context Protocol)**: External data sources
   - Example: sosumi.ai → Apple Developer documentation
   - Format: JSON-RPC server integration
   - Config: `.claude/settings.json`

## Command/Skill Best Practices

**Pattern**: Commands invoke skills via Skill tool. Skills contain implementation.

### Command Structure

**Location**: `.claude/commands/feature-name.md`

**Format**:
```markdown
Orchestrate [feature] with [capabilities].

Invoke the Skill tool with skill="feature-name" to dispatch a specialized agent that will:
1. [Step 1]
2. [Step 2]
3. [Step 3]

Task: $ARGUMENTS

If no arguments provided, [default behavior].

Examples:
- `/feature-name arg1` - [Description]
- `/feature-name arg2` - [Description]
```

### Skill Structure

**Location**: `.claude/skills/feature-name/SKILL.md`

**Format**:
```yaml
---
name: feature-name
aliases: [alt-name-1, alt-name-2]
description: One-line description
---

# Feature Name

Comprehensive documentation...

## Parameters

[Parameter documentation]

## Process

### Phase 1: Context Collection
[Steps...]

### Phase 2: Planning
[Steps...]

## Error Handling

[Error scenarios and recovery]

## References

[Links to related docs]
```

### Integration with Superpowers

Skills that orchestrate multi-step workflows should integrate with superpowers plugin:

**Invoke /superpowers:write-plan**:
```
Tool: SlashCommand
Parameters:
  command: "/superpowers:write-plan"
```

**Invoke /superpowers:execute-plan**:
```
Tool: SlashCommand
Parameters:
  command: "/superpowers:execute-plan"
```

**Pattern**: Skill coordinates workflow, superpowers handles plan creation/execution.

### Standalone Commands (Scaffold)

Commands in `abundance-scaffold/.claude/commands/` are **standalone**:
- No skill dependencies (portable)
- Use agent specifications (`.claude/agents/*.md`)
- Can be copied to any project

**Example**: `/validate-docs`
- Reads: `.claude/agents/doc-reviewer.md`
- Analyzes: `docs/` directory
- Reports: File:line issues

**Example**: `/check-drift`
- Reads: `.claude/agents/drift-detector.md`
- Scans: Codebase for ADR violations
- Reports: P0/P1/P2 severity violations

### Testing Commands

**Manual test**:
```
/command-name arg1
```

**Verify**:
- Command invokes Skill tool (or agent for standalone)
- Arguments passed correctly
- Expected output produced

**CI test** (if applicable):
- Command runs in GitHub Actions workflow
- Exit codes correct (0 = success, 1 = failure)
- Output captured in logs

## Implementation Patterns

### Hook Development

**Lifecycle**:
```
Event trigger → Hook execution → Output to Claude → Decision
```

**Example**: Bash command validator
```python
# .claude/hooks/bash_command_validator.py
import sys, re

DANGEROUS_PATTERNS = [
    r"rm\s+-rf\s+/",
    r":\(\)\{\s*:\|:&\s*\};:",  # Fork bomb
    r"curl.*\|\s*bash",
]

command = sys.argv[1]
for pattern in DANGEROUS_PATTERNS:
    if re.search(pattern, command):
        print(f"❌ BLOCKED: Dangerous command pattern: {pattern}")
        sys.exit(1)

print(f"✅ Command allowed: {command}")
sys.exit(0)
```

**Hooks in this project**:
- `pre-sprint.sh`: Validate environment before sprint
- `bash_command_validator.py`: Block dangerous commands
- `pr_create_hook.sh`: Enforce PR template compliance
- `file_edit_hook.sh`: Check for sensitive data in commits

### Agent Development

**Persona structure**:
```markdown
**Agent Name**: drift-detector
**Role**: ADR compliance enforcer
**Inputs**: File paths, ADR references
**Outputs**: Severity-tagged violations (P0/P1/P2)
**Behavior**:
  1. Load ADR-XXX constraints
  2. Scan codebase for violations
  3. Report file:line locations
**Success Criteria**: Zero P0 violations in protected branches
```

**Agents in this project**:
- `doc-reviewer`: Link validation, staleness detection
- `drift-detector`: ADR compliance with severity levels
- `cost-watchdog`: Budget monitoring (GCP/Firebase)

### Command Development

**Pattern**: Commands invoke agents or run checks
```markdown
---
description: Check documentation for broken links
---

@doc-reviewer scan all documentation in docs/ and report:
- Broken internal links
- Stale references (>90 days)
- Missing required sections

Output format: File:line with recommended fix.
```

**Commands in this project**:
- `/validate-docs`: Invoke doc-reviewer
- `/check-drift`: Invoke drift-detector
- `/show-sprint-status`: Parse sprint plan, show progress

## Integration with CI/CD

### GitHub Actions Integration

Claude Code agents can be invoked from workflows:

```yaml
- name: Run drift detection
  run: |
    claude agent run drift-detector \
      --severity P0,P1 \
      --output violations.json

- name: Comment on PR
  if: failure()
  uses: actions/github-script@v7
  with:
    script: |
      const violations = require('./violations.json')
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        body: violations.summary
      })
```

**Workflows using Claude Code**:
- `security-pr-review.yml`: Auto-review for OWASP Top 10
- `claude-code-action-ci-fix.yml`: Respond to @claude mentions in PR comments

## MCP Integration

### Apple Documentation Fetcher

**Setup**: MCP server provides live Apple docs without bloating context.

**Usage pattern**:
```
1. Claude needs SwiftUI View documentation
2. Calls mcp__sosumi__fetchAppleDocumentation("/documentation/swiftui/view")
3. Receives markdown-formatted API reference
4. Uses in response without manual context loading
```

**Context map** (`docs/apple-context-map.json`):
```json
{
  "auth": {
    "biometric": {
      "primary_api": "/documentation/localauthentication/lacontext"
    }
  }
}
```

**Benefits**:
- Just-in-time documentation loading
- No manual context management
- Always up-to-date API references

## Setup and Installation

### 1. Install Required Plugins

```bash
# Via Claude Code marketplace
claude plugin install superpowers
claude plugin install document-skills

# Verify installation
claude plugin list
```

### 2. Enable Project Hooks

```bash
cd abundance-scaffold
./scripts/setup-claude-hooks.sh
```

### 3. Configure MCP

Ensure `.claude/settings.json` includes sosumi:
```json
{
  "mcpServers": {
    "sosumi": {
      "command": "npx",
      "args": ["-y", "@sosumi/mcp-server"]
    }
  }
}
```

### 4. Validate Setup

```bash
./scripts/validate-environment.sh
```

Expected output:
```
✅ Claude Code: Hooks enabled
✅ Plugins: superpowers, document-skills
✅ MCP: sosumi connected
```

## Cost Considerations

**Token usage optimization**:
- Hooks: Minimal cost (pre-execution checks)
- Agents: Moderate cost (1-5 tasks per sprint)
- MCP: Low cost (fetches only requested docs)

**Budget allocation** (from COST-MODEL-001):
- Hooks: <$1/month (blocking checks)
- Agents: ~$20/month (5 reviews/sprint × 4 sprints)
- MCP: ~$5/month (documentation lookups)

Total: ~$26/month for automation (4.7% of $554 total budget)

## References

- **ADR-025**: Claude Code integration strategy
- **DEVELOPMENT-WORKFLOW-003**: Sprint execution guide
- **AI-AGENT-BEHAVIORS-001**: Agent persona specifications
- **COST-MODEL-001**: Budget breakdown

## Maintenance

**Monthly review**:
- Check hook execution logs for false positives
- Update agent personas based on team feedback
- Refresh MCP context map with new tech stack features

**Quarterly review**:
- Evaluate new Claude Code marketplace plugins
- Measure cost vs. productivity gains
- Update documentation with new patterns
