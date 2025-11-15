# Plan Summary: Claude Commands & Skills Audit and Refactor

**Created**: 2025-11-14
**Plan**: docs/plans/2025-11-14-audit-refactor-claude-commands-skills.md

---

## Overview

This plan audits and refactors all Claude Code commands and skills to follow official Anthropic best practices, ensuring consistent patterns and proper integration with the Skill tool and superpowers plugin.

---

## Problem Statement

Current commands don't follow the recommended pattern:
- Commands describe behavior but don't invoke the Skill tool correctly
- Inconsistent patterns between spec-kit (project commands) and abundance-scaffold (template commands)
- Missing documentation for command/skill architecture
- No CI verification to prevent regression

**Impact**: Commands may not work as intended, confusing for developers, harder to maintain.

---

## Solution Architecture

**Two-Tier Pattern**:

1. **Spec-kit Commands** (project-specific):
   - Commands invoke skills via `Skill tool with skill="name"`
   - Skills contain full implementation logic
   - Integrate with superpowers plugin via SlashCommand tool

2. **Abundance-scaffold Commands** (portable templates):
   - Commands are standalone (no skill dependencies)
   - Use agent specifications from `.claude/agents/*.md`
   - Can be copied to any project without external dependencies

**Best Practice Reference**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands

---

## Key Components

### Commands to Refactor (Spec-kit)

1. **ios-sprint-executor** - Orchestrates iOS sprint development
   - Fix: Add Skill tool invocation with sprint number parameter
   - Update: Add examples and default behavior

2. **verified-stage-development** - Orchestrates stage development
   - Fix: Add Skill tool invocation with stage parameter
   - Update: Reference context-map.json for available stages

3. **apple-docs-fetcher** - Fetches Apple documentation
   - Fix: Add Skill tool invocation with query parameter
   - Update: Document MCP integration pattern

### Commands to Refactor (Abundance-scaffold)

1. **validate-docs** - Documentation validator
   - Fix: Remove "invokes agent" claim, add full implementation instructions
   - Update: Explain how Claude uses doc-reviewer agent specification

2. **check-drift** - ADR compliance checker
   - Fix: Add severity levels (P0/P1/P2) explanation
   - Update: Reference CI integration workflow

3. **show-sprint-status** - Sprint progress tracker
   - Fix: Add full implementation (currently just describes output)
   - Update: Explain task completion detection logic

---

## Implementation Approach

### Pattern: Command → Skill (spec-kit)

**Command file**:
```markdown
Invoke the Skill tool with skill="feature" to dispatch agent that will:
1. Load context
2. Execute workflow
3. Generate outputs

Examples:
- `/feature arg1` - Description
```

**Skill file**:
```yaml
---
name: feature
description: One-line
---

# Feature

## Process
## Error Handling
```

### Pattern: Standalone Command (scaffold)

**Command file**:
```markdown
Usage: /command

When this runs, Claude will:
1. Read agent spec from .claude/agents/
2. Analyze data
3. Report results

Expected output: [examples]
```

---

## Deliverables

### Files Modified (8)

**Spec-kit**:
- `.claude/commands/ios-sprint-executor.md`
- `.claude/commands/verified-stage-development.md`
- `.claude/commands/apple-docs-fetcher.md`
- `.claude/skills/*/SKILL.md` (verify frontmatter)

**Abundance-scaffold**:
- `abundance-scaffold/.claude/commands/validate-docs.md`
- `abundance-scaffold/.claude/commands/check-drift.md`
- `abundance-scaffold/.claude/commands/show-sprint-status.md`

### Files Created (5)

- `.claude/commands/README.md` - Spec-kit commands documentation
- `abundance-scaffold/.claude/commands/README.md` - Scaffold commands documentation
- `scripts/verify-commands.sh` - Verification script for CI
- `.github/workflows/verify-commands.yml` - CI workflow
- Updated: `abundance-scaffold/docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md` (best practices section)
- Updated: `abundance-scaffold/README.md` (commands section)

---

## Success Criteria

1. **All spec-kit commands**: Invoke Skill tool with correct parameters
2. **All scaffold commands**: Standalone with clear usage instructions
3. **All skills**: Have YAML frontmatter and comprehensive documentation
4. **Verification script**: Passes for all commands
5. **CI integration**: Runs on command/skill changes

---

## Benefits

### Developer Experience
- Clear command usage with examples
- Consistent patterns across all commands
- Discoverability via README files

### Maintainability
- CI verification prevents regression
- Documentation explains architecture
- Patterns easy to replicate for new commands

### Integration
- Proper superpowers plugin integration
- SlashCommand tool usage documented
- Agent specifications guide Claude behavior

---

## Rollout

**Phase 1** (Tasks 1-3): Refactor spec-kit commands - 45 minutes
**Phase 2** (Tasks 4-6): Refactor scaffold commands - 45 minutes
**Phase 3** (Tasks 7-8): Documentation updates - 30 minutes
**Phase 4** (Tasks 9-10): CI integration - 30 minutes

**Total**: 2.5 hours

---

## Testing Plan

### Manual Tests

Each command tested with:
```
/command-name arg1
```

Verify:
- Skill tool invoked (spec-kit) OR
- Agent spec loaded (scaffold)
- Expected output produced
- Error handling works

### Automated Tests

Verification script checks:
- [ ] Commands invoke Skill tool (spec-kit)
- [ ] Matching skill directories exist
- [ ] YAML frontmatter present in skills
- [ ] Scaffold commands are standalone (no Skill tool)
- [ ] Agent specifications referenced

### CI Integration

- Runs on PR affecting `.claude/commands/**` or `.claude/skills/**`
- Fails if verification script finds errors
- Prevents merging non-compliant commands

---

## References

- **Best Practices**: https://code.claude.com/docs/en/common-workflows#create-custom-slash-commands
- **Frontend Example**: Provided in task description (command + skill pattern)
- **Architecture Doc**: `abundance-scaffold/docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md`
- **Superpowers Plugin**: Uses SlashCommand tool for `/superpowers:write-plan` and `/superpowers:execute-plan`

---

## Next Epic Preview

After this refactor:
- New commands can follow established patterns
- CI ensures compliance
- Documentation makes architecture clear
- Developers can create commands confidently

Future enhancements:
- More agent specifications (e.g., test-runner, performance-analyzer)
- Additional superpowers integrations
- Command composition patterns

---

**Status**: Ready for execution
**Executor**: Use `/superpowers:execute-plan` or execute manually task-by-task
**Estimated Duration**: 2.5 hours
