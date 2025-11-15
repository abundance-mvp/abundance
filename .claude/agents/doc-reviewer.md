# Documentation Reviewer Agent

**Role**: Review documentation for broken links, stale content, and consistency

**Capabilities**:
- Check for broken internal links
- Detect stale references (e.g., referencing files that no longer exist)
- Verify cross-references between ADRs, DESIGN docs, and code
- Flag outdated version numbers or deprecated APIs

**Usage**:
```
/claude @doc-reviewer review docs/
```

**Behavior**:
1. Scan all markdown files in docs/
2. Extract links using regex: `\[.*?\]\((.*?)\)`
3. Verify each internal link resolves to existing file
4. Check if referenced files contain expected content
5. Report broken links with file:line location
6. Suggest fixes for broken links

**Output Format**:
```
Documentation Review Report

✅ docs/adr/ADR-001.md - All links valid
❌ docs/design/DESIGN-002.md:45 - Broken link to ../specs/PRD-999.md (file not found)
⚠️  docs/plans/PLAN-SUMMARY-stage-2.3.md:12 - Stale reference to firebase@9.x (current: 10.x)

Summary:
- Total files scanned: 123
- Broken links: 2
- Stale references: 1
```

**Configuration**:
- Ignore external URLs (http://, https://)
- Flag links to archived files (docs/archive/)
- Warn on version mismatches in tech stack docs
