# MCP-Based Apple Documentation System Design

**Created:** 2025-11-04
**Status:** Approved for Implementation
**Related:** Apple Documentation Verification Report, Tech Stack Map

---

## Executive Summary

Migrate from static pre-fetched Apple documentation to a dynamic MCP-based system that fetches documentation just-in-time during iOS stage development. Uses search-first hybrid approach with context map guidance for deterministic lookups.

**Key Benefits:**
- Always current documentation from sosumi.ai
- No local documentation maintenance overhead
- Automatic integration with verified-stage-development
- Deterministic lookups via context map for known APIs
- Search fallback for discovery of new/unknown APIs

---

## Architecture Overview

### Three-Tier Architecture

```
┌─────────────────────────────────────────┐
│   Agent (verified-stage-development)    │
│   "I need biometric auth documentation" │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│     apple-docs-fetcher Skill Layer      │
│  1. Check context map for known path    │
│  2. Fallback to MCP search if unknown   │
│  3. Fetch documentation via MCP         │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│        MCP Integration Layer            │
│  - searchAppleDocumentation (discovery) │
│  - fetchAppleDocumentation (retrieval)  │
│  - Session memory only (no disk cache)  │
└─────────────────────────────────────────┘
```

### Data Flow

1. **Context Map Lookup (Fast Path)**
   - Agent needs: "auth.biometric"
   - Skill reads: `docs/apple-context-map.json`
   - Finds: `/documentation/localauthentication/lacontext`
   - Fetches: Direct MCP call
   - Returns: Markdown documentation

2. **Search Fallback (Discovery)**
   - Agent needs: "AVCaptureSession"
   - Context map: No exact match
   - MCP search: "AVCaptureSession"
   - Results: Single clear match
   - Fetches: Documentation via path
   - Returns: Markdown documentation

3. **Ambiguous Search Handling**
   - Agent needs: "payment processing"
   - MCP search: Multiple results (Apple Pay, StoreKit, etc.)
   - Present: Top 3 options to user
   - User selects: Apple Pay
   - Fetches: Selected documentation

---

## Component Design

### 1. Context Map (`docs/apple-context-map.json`)

**Purpose:** Maps project features to Apple framework documentation paths for deterministic lookups.

**Schema:**

```json
{
  "version": "1.0",
  "last_updated": "2025-11-04",
  "tech_stack_source": "docs/tech-stack/TECH-STACK-MAP-001.md",
  "feature_mappings": {
    "<feature_category>": {
      "<feature_name>": {
        "primary_api": "/documentation/<framework>/<class>",
        "related_apis": [
          "/documentation/<framework>/<related_class>"
        ],
        "description": "Human-readable description"
      }
    }
  },
  "search_hints": {
    "<keyword>": ["API class names", "framework names", "concepts"]
  }
}
```

**Example Mappings:**

```json
{
  "technology_overviews": {
    "all": {
      "primary_api": "/documentation/technologyoverviews",
      "related_apis": [],
      "description": "High-level technology overviews and adoption guides"
    },
    "liquid_glass": {
      "primary_api": "/documentation/technologyoverviews/liquid-glass",
      "related_apis": [
        "/design/human-interface-guidelines/foundations/materials",
        "/design/human-interface-guidelines/components"
      ],
      "description": "iOS 26 Liquid Glass design system - dynamic materials, depth, vibrancy"
    }
  },
  "ui_design": {
    "hig_foundations": {
      "primary_api": "/design/human-interface-guidelines/foundations",
      "related_apis": [
        "/design/human-interface-guidelines/foundations/color",
        "/design/human-interface-guidelines/foundations/typography",
        "/design/human-interface-guidelines/foundations/layout"
      ],
      "description": "Human Interface Guidelines - core design principles"
    },
    "hig_components": {
      "primary_api": "/design/human-interface-guidelines/components",
      "related_apis": [
        "/design/human-interface-guidelines/patterns",
        "/design/human-interface-guidelines/inputs"
      ],
      "description": "HIG UI components and interaction patterns"
    }
  },
  "swift_language": {
    "basics": {
      "primary_api": "/documentation/swift",
      "related_apis": [
        "/documentation/swift/string",
        "/documentation/swift/array",
        "/documentation/swift/dictionary"
      ],
      "description": "Swift language fundamentals and standard library"
    },
    "concurrency": {
      "primary_api": "/documentation/swift/swift_standard_library/concurrency",
      "related_apis": [
        "/documentation/swift/task",
        "/documentation/swift/asyncsequence"
      ],
      "description": "Swift async/await and structured concurrency"
    },
    "swift6": {
      "primary_api": "/documentation/swift",
      "related_apis": [
        "/documentation/swift/adopting-swift-6"
      ],
      "description": "Swift 6 features, data race safety, and migration"
    }
  },
  "swiftui": {
    "app_structure": {
      "primary_api": "/documentation/swiftui/app-structure-and-behavior",
      "related_apis": [
        "/documentation/swiftui/app",
        "/documentation/swiftui/scene",
        "/documentation/swiftui/view"
      ],
      "description": "SwiftUI app lifecycle and structure"
    },
    "views_controls": {
      "primary_api": "/documentation/swiftui/views-and-controls",
      "related_apis": [
        "/documentation/swiftui/text",
        "/documentation/swiftui/button",
        "/documentation/swiftui/list",
        "/documentation/swiftui/form"
      ],
      "description": "SwiftUI declarative UI components"
    },
    "state_management": {
      "primary_api": "/documentation/swiftui/state-and-data-flow",
      "related_apis": [
        "/documentation/swiftui/state",
        "/documentation/swiftui/binding",
        "/documentation/swiftui/observedobject",
        "/documentation/swiftui/environmentobject"
      ],
      "description": "SwiftUI state management and data flow"
    },
    "navigation": {
      "primary_api": "/documentation/swiftui/navigation-and-routing",
      "related_apis": [
        "/documentation/swiftui/navigationstack",
        "/documentation/swiftui/navigationlink"
      ],
      "description": "SwiftUI navigation patterns and routing"
    },
    "layout": {
      "primary_api": "/documentation/swiftui/layout-fundamentals",
      "related_apis": [
        "/documentation/swiftui/vstack",
        "/documentation/swiftui/hstack",
        "/documentation/swiftui/zstack",
        "/documentation/swiftui/grid"
      ],
      "description": "SwiftUI layout system and containers"
    }
  },
  "auth": {
    "biometric": {
      "primary_api": "/documentation/localauthentication/lacontext",
      "related_apis": [
        "/documentation/localauthentication/laright",
        "/documentation/localauthentication/laerror"
      ],
      "description": "Face ID, Touch ID authentication"
    },
    "sign_in_with_apple": {
      "primary_api": "/documentation/authenticationservices/asauthorizationcontroller",
      "related_apis": [
        "/documentation/authenticationservices/aswebauthenticationsession"
      ],
      "description": "Apple ID authentication flow"
    }
  },
  "camera": {
    "capture": {
      "primary_api": "/documentation/avfoundation/avcapturesession",
      "related_apis": [
        "/documentation/avfoundation/avcapturedevice",
        "/documentation/avfoundation/avcapturephotooutput"
      ],
      "description": "Camera capture pipeline"
    }
  },
  "storage": {
    "core_data": {
      "primary_api": "/documentation/coredata/nsmanagedobjectcontext",
      "related_apis": [
        "/documentation/coredata/nspersistentcontainer"
      ],
      "description": "Local data persistence"
    }
  }
}
```

**Search Hints (for fallback discovery):**

```json
{
  "search_hints": {
    "ui": ["SwiftUI", "UIKit", "View", "HIG", "Human Interface Guidelines", "Liquid Glass"],
    "design": ["Liquid Glass", "materials", "vibrancy", "HIG", "typography", "color", "layout"],
    "swift": ["Swift", "String", "Array", "async", "await", "Task", "concurrency", "Swift 6"],
    "swiftui": ["View", "State", "Binding", "NavigationStack", "List", "Form", "Button", "Text"],
    "layout": ["VStack", "HStack", "ZStack", "Grid", "GeometryReader", "spacing", "padding"],
    "state": ["@State", "@Binding", "@ObservedObject", "@EnvironmentObject", "data flow"],
    "navigation": ["NavigationStack", "NavigationLink", "routing", "deep linking"],
    "biometric": ["LAContext", "Local Authentication", "Face ID", "Touch ID", "biometry"],
    "payment": ["PKPaymentAuthorizationController", "Apple Pay", "StoreKit", "Product", "Transaction"],
    "camera": ["AVCaptureSession", "AVCaptureDevice", "AVFoundation", "camera", "photo", "video"],
    "vision": ["VNImageRequestHandler", "Vision", "Core ML", "object detection", "image analysis"],
    "storage": ["Core Data", "NSManagedObjectContext", "FileManager", "CloudKit", "persistence"],
    "network": ["URLSession", "NWConnection", "Network framework", "HTTP", "REST"],
    "testing": ["XCTest", "XCTestCase", "@Test", "Swift Testing", "unit test", "UI test"],
    "ml": ["Core ML", "MLModel", "Vision", "VNRequest", "machine learning"],
    "metal": ["MTLDevice", "Metal", "GPU", "rendering", "compute shader"],
    "concurrency": ["async", "await", "Task", "Actor", "MainActor", "structured concurrency"]
  }
}
```

**Maintenance:**
- Update when new features added to tech stack
- Seed from verification report priority matrix
- Add search hints based on common queries that require fallback
- Version tracking for schema evolution

---

### 2. apple-docs-fetcher Skill

**File:** `.claude/skills/apple-docs-fetcher/SKILL.md`

**Purpose:** Wraps MCP documentation tools with search-first hybrid logic.

**Skill Interface:**

```markdown
---
name: apple-docs-fetcher
description: Fetch Apple Developer documentation using MCP server with context map guidance
---

## When to Use

- During iOS stage development research (automatic via verified-stage-development)
- When implementing iOS features and need API documentation
- When agent needs to verify Apple API capabilities or signatures

## Usage Pattern

Call with feature path, API name, or concept:

**Foundational Areas:**
- `apple-docs-fetcher technology_overviews.all` → Returns all technology overviews
- `apple-docs-fetcher technology_overviews.liquid_glass` → Returns Liquid Glass design system
- `apple-docs-fetcher ui_design.hig_foundations` → Returns HIG foundations
- `apple-docs-fetcher swift_language.basics` → Returns Swift language documentation
- `apple-docs-fetcher swiftui.app_structure` → Returns SwiftUI app structure docs
- `apple-docs-fetcher swiftui.state_management` → Returns SwiftUI state management

**Specific APIs:**
- `apple-docs-fetcher auth.biometric` → Returns LAContext documentation
- `apple-docs-fetcher AVCaptureSession` → Searches and returns documentation
- `apple-docs-fetcher NavigationStack` → Searches and returns SwiftUI navigation docs

**Natural Language:**
- `apple-docs-fetcher "Face ID authentication"` → Searches by natural language
- `apple-docs-fetcher "async await Swift"` → Finds Swift concurrency docs
- `apple-docs-fetcher "Liquid Glass materials"` → Finds design system docs

## Lookup Strategy (Search-First Hybrid)

1. **Context Map Lookup:**
   - Read docs/apple-context-map.json
   - Parse input as feature path (e.g., "auth.biometric")
   - If found, use primary_api path directly
   - Skip search, go directly to fetch

2. **Search Fallback:**
   - If not in context map, call mcp__sosumi__searchAppleDocumentation
   - Use input as search query
   - Parse results:
     - Single clear match: Auto-fetch
     - Multiple matches: Present top 3 to user for selection
     - No matches: Report "No documentation found"

3. **Fetch Documentation:**
   - Call mcp__sosumi__fetchAppleDocumentation(path)
   - Return markdown content to agent
   - Content stays in session memory (not saved to disk)

## Error Handling

- Context map missing: Log warning, proceed to search fallback
- Context map malformed: Log error, proceed to search fallback
- Search returns no results: Report "No documentation found for [query]"
- MCP server timeout: Report error, suggest checking `claude mcp list`
- Ambiguous search: Present options with descriptions for user selection

## Related APIs

When fetching primary_api, optionally fetch related_apis for comprehensive context:
- Use `--include-related` flag to fetch all related APIs in one call
- Returns combined markdown with section headers
```

**Implementation Logic:**

```python
def fetch_apple_docs(query: str) -> str:
    # Step 1: Try context map
    context_map = read_json("docs/apple-context-map.json")

    if is_feature_path(query):  # e.g., "auth.biometric"
        mapping = lookup_feature_path(context_map, query)
        if mapping:
            return mcp_fetch(mapping["primary_api"])

    # Step 2: Search fallback
    search_results = mcp_search(query)

    if len(search_results) == 0:
        return f"No documentation found for '{query}'"

    if len(search_results) == 1:
        return mcp_fetch(search_results[0].path)

    # Step 3: Disambiguate
    selected = present_options_to_user(search_results[:3])
    return mcp_fetch(selected.path)

def mcp_search(query: str) -> list:
    return mcp__sosumi__searchAppleDocumentation(query=query)

def mcp_fetch(path: str) -> str:
    return mcp__sosumi__fetchAppleDocumentation(path=path)
```

---

### 3. MCP Server Integration

**Installation:**

```bash
claude mcp add --transport http sosumi https://sosumi.ai/mcp
```

**Available MCP Tools:**

1. **mcp__sosumi__searchAppleDocumentation**
   - Parameters: `query` (string)
   - Returns: Array of results with `title`, `url`, `description`, `breadcrumbs`, `tags`
   - Use for: Discovery of unknown APIs

2. **mcp__sosumi__fetchAppleDocumentation**
   - Parameters: `path` (string) - Documentation path like '/documentation/swift/array'
   - Returns: Markdown content
   - Use for: Retrieving actual documentation

**Session Caching Strategy:**
- Documentation lives in agent session memory only
- No disk writes to `docs/apple/`
- Refetch on each new session (acceptable cost for always-current docs)
- If agent needs same doc twice in session, reuse from memory

**Error Handling:**
- Network timeout: Report error, suggest checking MCP connection
- Invalid path: MCP returns error, skill reports to agent
- Rate limiting: MCP handles, skill waits and retries

---

### 4. verified-stage-development Integration

**Modification to Research Verification Phase:**

```markdown
## Research Verification Agent (for iOS stages)

When stage requires iOS/Swift implementation:

1. **Pre-fetch documentation phase:**
   - Read TECH-STACK-MAP to identify required frameworks
   - Read docs/apple-context-map.json for relevant features
   - Identify primary APIs needed for stage
   - Invoke apple-docs-fetcher for each primary API
   - Store documentation in research agent session memory

2. **Verification phase:**
   - Research agent has API documentation in context
   - Verifies technical claims against actual Apple API docs
   - Checks API availability for target iOS version
   - Validates architecture feasibility with real API signatures

3. **Report phase:**
   - Include references to Apple documentation used
   - Flag any missing documentation gaps
   - Recommend updates to context map if needed
```

**Example for Stage 2.2:**

```
Stage: 2.2 (iOS Camera Implementation)
Tech Stack: SwiftUI, AVFoundation, Vision

Research Agent Pre-fetch (Foundational + Feature-Specific):

Foundational Documentation:
1. apple-docs-fetcher swift_language.basics → Swift language docs
2. apple-docs-fetcher swift_language.concurrency → async/await, Task
3. apple-docs-fetcher swiftui.app_structure → SwiftUI App, Scene, View
4. apple-docs-fetcher swiftui.state_management → @State, @Binding, etc.
5. apple-docs-fetcher technology_overviews.liquid_glass → Liquid Glass design system
6. apple-docs-fetcher ui_design.hig_components → HIG UI components

Feature-Specific Documentation:
7. apple-docs-fetcher camera.capture → AVCaptureSession docs
8. apple-docs-fetcher camera.capture --include-related → AVCaptureDevice, AVCapturePhotoOutput
9. apple-docs-fetcher vision.image_analysis → VNImageRequestHandler

Research Verification:
- Verify Swift 6 compatibility and concurrency patterns
- Validate SwiftUI app structure and state management approach
- Check UI design against Liquid Glass and HIG guidelines
- Verify camera permissions approach against AVCaptureDevice.requestAccess
- Validate capture pipeline design against AVCaptureSession lifecycle
- Check image analysis integration with Vision framework
```

---

## Implementation Plan Overview

### Phase 1: Cleanup (Delete Bad Docs)

1. Delete AI-summarized docs from 6 recent commits
2. Revert manifest.json files to pre-fetch state
3. Update verification report to reflect deletions
4. Commit: "refactor: remove AI-summarized docs, migrate to MCP approach"

### Phase 2: MCP Setup

1. Install MCP server: `claude mcp add --transport http sosumi https://sosumi.ai/mcp`
2. Test MCP tools manually to verify connectivity
3. Document MCP setup in CLAUDE.md

### Phase 3: Build Context Map

1. Create `docs/apple-context-map.json` v1.0
2. Seed from verification report priority matrix
3. Map TECH-STACK-MAP features to Apple framework paths
4. Add search hints from common terminology
5. Commit: "docs: add Apple documentation context map v1.0"

### Phase 4: Create apple-docs-fetcher Skill

1. Create `.claude/skills/apple-docs-fetcher/SKILL.md`
2. Implement search-first hybrid logic
3. Add error handling and disambiguation
4. Test with known queries (auth.biometric, AVCaptureSession)
5. Commit: "feat: add apple-docs-fetcher skill with MCP integration"

### Phase 5: Integrate with verified-stage-development

1. Update verified-stage-development skill
2. Add pre-fetch phase for iOS stages
3. Update research agent context loading
4. Test with mock Stage 2.2 scenario
5. Commit: "feat: integrate apple-docs-fetcher with verified-stage-development"

### Phase 6: Documentation

1. Update CLAUDE.md with MCP documentation workflow
2. Add troubleshooting guide for MCP connection issues
3. Document context map maintenance procedures
4. Commit: "docs: document MCP-based Apple documentation system"

---

## Success Criteria

### Functional Requirements

- ✅ Agents can fetch Apple documentation during iOS stages
- ✅ Known APIs resolve via context map (deterministic)
- ✅ Unknown APIs discoverable via search (flexible)
- ✅ Documentation always current from sosumi.ai
- ✅ No local documentation maintenance required
- ✅ Session-only caching (no disk pollution)

### Performance Requirements

- ✅ Context map lookup: <100ms
- ✅ MCP search + fetch: <3 seconds
- ✅ Acceptable latency during research phase
- ✅ No repeated fetches within same session

### Usability Requirements

- ✅ Automatic during verified-stage-development
- ✅ Manual invocation available when needed
- ✅ Clear error messages for connection issues
- ✅ Disambiguation UI for ambiguous searches
- ✅ Documentation references in research reports

---

## Migration Impact

### What Changes

- **Removed:** Static `docs/apple/` API documentation files
- **Removed:** Manifest.json API tracking (keep overviews only)
- **Added:** `docs/apple-context-map.json` feature mappings
- **Added:** `.claude/skills/apple-docs-fetcher/` skill
- **Modified:** `verified-stage-development` skill (pre-fetch phase)
- **Modified:** CLAUDE.md (MCP documentation workflow)

### What Stays the Same

- Overview documentation in `docs/apple/` (valuable summaries)
- Verification report and priority matrix (historical analysis)
- Tech stack map structure (source of truth for features)
- Stage development workflow (transparent enhancement)

### Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| MCP server downtime | Graceful degradation: warn user, continue without docs |
| Network latency | Acceptable during research phase (not runtime) |
| Search ambiguity | Present top 3 results for user selection |
| Context map drift | Version tracking, update process documented |
| Missing mappings | Search fallback ensures all APIs discoverable |

---

## Future Enhancements

### v1.1 - Smart Caching

- Optional local cache with 7-day expiry
- Faster access for frequently used APIs
- Background refresh for stale docs

### v1.2 - Context Map Auto-Update

- Skill learns new mappings from successful searches
- Proposes context map updates via PR
- Reduces manual maintenance

### v1.3 - Multi-Framework Queries

- Fetch related documentation across frameworks
- Example: "camera + ML" → AVFoundation + Vision + CoreML
- Build comprehensive context for complex features

### v2.0 - Offline Mode

- Download essential docs for offline development
- Selective caching based on current stage requirements
- Sync on network reconnect

---

## Appendix: Context Map Schema Evolution

### Version 1.0 (Initial)

```json
{
  "version": "1.0",
  "feature_mappings": { "...": "..." },
  "search_hints": { "...": "..." }
}
```

### Version 1.1 (Planned)

```json
{
  "version": "1.1",
  "feature_mappings": { "...": "..." },
  "search_hints": { "...": "..." },
  "usage_stats": {
    "auth.biometric": {"fetch_count": 15, "last_fetched": "2025-11-04"}
  }
}
```

### Version 2.0 (Future)

```json
{
  "version": "2.0",
  "feature_mappings": { "...": "..." },
  "search_hints": { "...": "..." },
  "cache_policy": {
    "auth.biometric": {"strategy": "local", "ttl_days": 7}
  }
}
```

---

## References

- Apple Documentation Verification Report: `docs/apple-docs-verification-report.md`
- Tech Stack Map: `docs/tech-stack/TECH-STACK-MAP-001.md`
- MCP Documentation: https://docs.claude.com/en/docs/claude-code/mcp
- Sosumi.ai MCP Server: https://sosumi.ai/mcp
