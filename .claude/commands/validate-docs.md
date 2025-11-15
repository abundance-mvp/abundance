Run documentation validator to check for broken links, stale content, and missing sections.

This command uses Claude Code's conversational interface to analyze documentation:

1. Reviews all Markdown files in docs/
2. Checks for broken internal links
3. Identifies stale documents (>90 days since last update)
4. Validates required sections in ADRs, PRDs, design docs
5. Reports file:line locations with recommended fixes

Usage:
```
/validate-docs
```

When this command runs, Claude will:
- Load the doc-reviewer agent specification from `.claude/agents/doc-reviewer.md`
- Scan the entire docs/ directory
- Generate a validation report

Expected output:
```
❌ docs/adr/ADR-010.md:15 → Broken link: ../design/AUTH-001.md
⚠️  docs/design/DESIGN-003.md → Stale (last updated 120 days ago)
✅ docs/specs/PRD-001.md → All checks passed
```

To fix issues:
1. Review the validation report
2. Update broken links to point to existing files
3. Refresh stale documents with current information
4. Re-run `/validate-docs` to verify fixes

Agent Specification: `.claude/agents/doc-reviewer.md`
