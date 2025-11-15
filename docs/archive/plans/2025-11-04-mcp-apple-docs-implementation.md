# MCP Apple Documentation System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement MCP-based just-in-time Apple documentation fetching with context map guidance and verified-stage-development integration.

**Architecture:** Three-tier system: apple-docs-fetcher skill wraps MCP tools, reads context map for known paths, falls back to search for discovery. Integrated into verified-stage-development for automatic pre-fetching during iOS stages.

**Tech Stack:** MCP (sosumi.ai), JSON (context map), Markdown (skill documentation)

---

## Task 1: Create Apple Context Map

**Files:**
- Create: `docs/apple-context-map.json`

**Step 1: Create context map v1.0**

```bash
cat > docs/apple-context-map.json << 'EOF'
{
  "version": "1.0",
  "last_updated": "2025-11-04",
  "tech_stack_source": "docs/tech-stack/TECH-STACK-MAP-001.md",
  "feature_mappings": {
    "technology_overviews": {
      "all": {
        "primary_api": "/documentation/technologyoverviews",
        "description": "High-level technology overviews and adoption guides"
      },
      "liquid_glass": {
        "primary_api": "/documentation/technologyoverviews/liquid-glass",
        "description": "iOS 26 Liquid Glass design system"
      }
    },
    "ui_design": {
      "hig_foundations": {
        "primary_api": "/design/human-interface-guidelines/foundations",
        "description": "HIG core design principles"
      }
    },
    "swift_language": {
      "basics": {
        "primary_api": "/documentation/swift",
        "description": "Swift language fundamentals"
      },
      "concurrency": {
        "primary_api": "/documentation/swift/swift_standard_library/concurrency",
        "description": "Swift async/await and structured concurrency"
      }
    },
    "swiftui": {
      "app_structure": {
        "primary_api": "/documentation/swiftui/app-structure-and-behavior",
        "description": "SwiftUI app lifecycle and structure"
      },
      "state_management": {
        "primary_api": "/documentation/swiftui/state-and-data-flow",
        "description": "SwiftUI state management"
      }
    },
    "auth": {
      "biometric": {
        "primary_api": "/documentation/localauthentication/lacontext",
        "description": "Face ID, Touch ID authentication"
      }
    },
    "camera": {
      "capture": {
        "primary_api": "/documentation/avfoundation/avcapturesession",
        "description": "Camera capture pipeline"
      }
    }
  },
  "search_hints": {
    "ui": ["SwiftUI", "UIKit", "HIG", "Liquid Glass"],
    "swift": ["Swift", "async", "await", "concurrency"],
    "swiftui": ["View", "State", "Binding", "NavigationStack"],
    "auth": ["LAContext", "Face ID", "Touch ID"],
    "camera": ["AVCaptureSession", "AVCaptureDevice"]
  }
}
EOF
```

**Step 2: Commit context map**

```bash
git add docs/apple-context-map.json
git commit -m "feat: add Apple documentation context map v1.0"
```

---

## Task 2: Create apple-docs-fetcher Skill

**Files:**
- Create: `.claude/skills/apple-docs-fetcher/SKILL.md`

**Step 1: Create skill directory**

```bash
mkdir -p .claude/skills/apple-docs-fetcher
```

**Step 2: Write skill documentation**

```bash
cat > .claude/skills/apple-docs-fetcher/SKILL.md << 'EOF'
---
name: apple-docs-fetcher
description: Fetch Apple Developer documentation using MCP server with context map guidance
---

## When to Use

- During iOS stage development research (automatic via verified-stage-development)
- When implementing iOS features and need API documentation
- When verifying Apple API capabilities

## Usage

Call with feature path, API name, or concept:
- `apple-docs-fetcher swift_language.basics`
- `apple-docs-fetcher AVCaptureSession`
- `apple-docs-fetcher "Face ID authentication"`

## Lookup Strategy

1. **Context Map Lookup:** Read `docs/apple-context-map.json` and check for feature path match
2. **Search Fallback:** Call `mcp__sosumi__searchAppleDocumentation` if not in context map
3. **Fetch:** Call `mcp__sosumi__fetchAppleDocumentation` with resolved path

## Implementation

**Step 1: Parse input**
- If input matches pattern `category.feature` → Context map lookup
- Otherwise → Search fallback

**Step 2: Context map lookup**
```
Read docs/apple-context-map.json
Parse input as category.feature (e.g., "swift_language.basics")
If found, extract primary_api path
Return path for fetching
```

**Step 3: Search fallback**
```
Call mcp__sosumi__searchAppleDocumentation(query=input)
If 0 results: Report "No documentation found"
If 1 result: Use it
If 2+ results: Present top 3 to user for selection
```

**Step 4: Fetch documentation**
```
Call mcp__sosumi__fetchAppleDocumentation(path=resolved_path)
Return markdown content to agent
Content stays in session memory only
```

## Error Handling

- Context map missing/malformed: Log warning, proceed to search
- MCP timeout: Report error with connection check suggestion
- No search results: Report "No documentation found for [query]"
- Ambiguous results: Present options to user

## Example Flows

**Context map hit:**
```
Input: "swift_language.concurrency"
→ Read context map
→ Find /documentation/swift/swift_standard_library/concurrency
→ Fetch directly
→ Return docs
```

**Search fallback:**
```
Input: "URLSession"
→ Read context map (no match)
→ Search MCP
→ Single result found
→ Fetch /documentation/foundation/urlsession
→ Return docs
```
EOF
```

**Step 3: Commit skill**

```bash
git add .claude/skills/apple-docs-fetcher/
git commit -m "feat: add apple-docs-fetcher skill with MCP integration"
```

---

## Task 3: Update verified-stage-development Integration

**Files:**
- Modify: `.claude/skills/verified-stage-development/SKILL.md` (add pre-fetch phase)

**Step 1: Document the pre-fetch phase**

Add after existing research verification phase:

```markdown
### Pre-fetch Apple Documentation (iOS stages only)

When stage requires iOS/Swift implementation:

1. Read TECH-STACK-MAP to identify required frameworks
2. Read docs/apple-context-map.json for relevant features
3. Invoke apple-docs-fetcher for foundational docs:
   - swift_language.basics
   - swift_language.concurrency
   - swiftui.app_structure
   - swiftui.state_management
   - technology_overviews.liquid_glass
4. Invoke apple-docs-fetcher for feature-specific docs based on stage requirements
5. Store all fetched docs in research agent session memory
6. Proceed with research verification using fetched docs
```

**Step 2: Commit integration**

```bash
git add .claude/skills/verified-stage-development/
git commit -m "feat: integrate apple-docs-fetcher into verified-stage-development"
```

---

## Task 4: Update CLAUDE.md Documentation

**Files:**
- Modify: `CLAUDE.md` (add MCP documentation section)

**Step 1: Add MCP documentation section**

Add to CLAUDE.md after "Using Superpowers" section:

```markdown
## Apple Documentation (MCP)

**System:** Just-in-time MCP-based documentation fetching

**How it works:**
- MCP server (sosumi.ai) provides live Apple documentation
- Context map (`docs/apple-context-map.json`) maps features to documentation paths
- `apple-docs-fetcher` skill wraps MCP complexity
- Automatic pre-fetching during iOS stage development

**Manual usage:**
```
Use apple-docs-fetcher skill:
- "apple-docs-fetcher swift_language.basics" → Swift docs
- "apple-docs-fetcher auth.biometric" → LAContext docs
- "apple-docs-fetcher AVCaptureSession" → Searches and fetches
```

**Troubleshooting:**
- Check MCP connection: `claude mcp list`
- Verify sosumi server: Should show "✓ Connected"
- If timeout: Check network/proxy settings

**Context map maintenance:**
- File: `docs/apple-context-map.json`
- Update when adding new tech stack features
- Format: `"category": { "feature": { "primary_api": "/path" } }`
```

**Step 2: Commit documentation**

```bash
git add CLAUDE.md
git commit -m "docs: add MCP Apple documentation workflow to CLAUDE.md"
```

---

## Task 5: Final Verification and Merge

**Files:**
- Read: All created files
- Test: MCP tools

**Step 1: Verify MCP connection**

```bash
claude mcp list
```
Expected: sosumi server shows "✓ Connected"

**Step 2: Test context map JSON validity**

```bash
cat docs/apple-context-map.json | python3 -m json.tool > /dev/null && echo "✓ Valid JSON"
```
Expected: "✓ Valid JSON"

**Step 3: Verify skill file structure**

```bash
ls -la .claude/skills/apple-docs-fetcher/SKILL.md
```
Expected: File exists

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete MCP-based Apple documentation system

- Context map with foundational iOS mappings
- apple-docs-fetcher skill with search-first hybrid
- Integration with verified-stage-development
- Updated CLAUDE.md with usage instructions

Closes migration from static docs to dynamic MCP fetching."
```

**Step 5: Switch to main and merge**

```bash
# Switch back to main
cd /Users/w/code/spec-kit
git checkout main

# Merge feature branch
git merge feature/mcp-apple-docs-implementation

# Clean up worktree
git worktree remove .worktrees/mcp-apple-docs
```

---

## Execution Notes

**Total Time:** ~30 minutes
**Dependencies:** MCP server already installed and connected
**Testing:** Manual verification (no automated tests for skill/docs)
**Risk:** Low - additive changes, no breaking modifications
