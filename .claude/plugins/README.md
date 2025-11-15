# Claude Code Plugins

This directory contains symlinks to Claude Code plugins.

## Setup

Run the installation script:
```bash
./scripts/install-claude-plugins.sh
```

This will create symlinks to:
- `code-review/` → `$HOME/.claude/plugins/cache/code-review`
- `feature-dev/` → `$HOME/.claude/plugins/cache/feature-dev`
- `research-agent/` → `$HOME/.claude/plugins/cache/research-agent` (optional)

## Required Plugins

Install these plugins via Claude Code marketplace before running the script:
1. **code-review**: 4 parallel agents, confidence scoring ≥80%
2. **feature-dev**: 7-phase workflow, architecture design, quality review

## Verification

After installation:
```bash
ls -la .claude/plugins/
```

You should see symlinks pointing to the Claude cache directory.

## References

- Research Validation: docs/validation/RESEARCH-VALIDATION-stage-5.3.md
- Plugin Architecture: docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md
