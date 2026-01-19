# Claude Workflow Restructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure Claude Code skills and commands to implement the ios-superpowers-architecture.md proposal with cleaner separation between commands (user-invoked) and skills (auto-activated).

**Architecture:** Replace overlapping skills with clear hierarchy: 3 user commands (`/ios-sprint`, `/ios-debug`, `/gcp-deploy`) backed by 6 domain skills (`verified-stage-development`, `firebase-superpowers`, `ios-superpowers`, `gcp-superpowers`, `apple-docs-fetcher`, `gemini-integration`). Commands invoke skills; skills route to MCP servers.

**Tech Stack:** Claude Code skills/commands (Markdown), MCP servers (sosumi, firebase, gcloud, observability)

---

## Background & Context

The current `.claude/` directory has accumulated overlapping skills:
- `ios-sprint-executor` (1200+ lines) overlaps with `verified-stage-development`
- `ios-superpowers` command duplicates some skill functionality
- No Firebase-specific skill despite Firebase MCP being primary backend
- No dedicated debugging command despite complex debugging workflows

The proposed architecture from `docs/dev-workflow/files (3)/ios-superpowers-architecture.md` provides a cleaner structure with explicit command/skill separation and agent dispatch matrix.

### Key Decisions

1. **Consolidate sprint execution** into single `verified-stage-development` skill (lead orchestrator)
2. **Create Firebase skill** as primary backend skill (Firestore, Functions, Auth, Storage, Rules)
3. **Add debugging command** (`/ios-debug`) for systematic iOS debugging
4. **Add deployment command** (`/gcp-deploy`) for Cloud Functions deployment
5. **Deprecate** `ios-sprint-executor` (merge into `verified-stage-development`)

---

## Task 1: Create `/ios-sprint` Command

**Files:**
- Create: `.claude/commands/ios-sprint.md`
- Archive: `.claude/commands/ios-sprint-executor.md` → `.claude/archive/ios-sprint-executor.md`

**Step 1: Read existing ios-sprint-executor command**

Review current implementation to preserve useful patterns.

**Step 2: Create new ios-sprint command**

```markdown
---
name: ios-sprint
description: Start a new iOS development sprint from spec documents
---

# iOS Sprint Command

Start spec-driven iOS development sprint using verified-stage-development orchestration.

## Usage

\`\`\`
/ios-sprint [spec-document-path]
\`\`\`

## Examples

\`\`\`
/ios-sprint docs/specs/DESIGN-042-ai-pipeline-v2.md
/ios-sprint docs/specs/DESIGN-043-catalog-ui.md
\`\`\`

## What This Does

1. **Load Spec Document**
   - Read the specified DESIGN-*, ADR-*, or SPEC-* document
   - Extract requirements, architecture, schemas

2. **Validate Completeness**
   - Check for required sections (architecture, schemas, testing)
   - If incomplete: use brainstorming to fill gaps

3. **Create Implementation Plan**
   - Use superpowers:writing-plans
   - Break into bite-sized tasks (5-10 min each)
   - Assign agents and MCP servers per task
   - Save to `docs/plans/YYYY-MM-DD-<feature>.md`

4. **Execute Sprint**
   - Use superpowers:subagent-driven-development
   - Dispatch specialized subagents:
     - ios-superpowers (with Axiom) for iOS code
     - firebase-superpowers for Firebase operations
     - gcp-superpowers for non-Firebase GCP
     - gemini-integration for AI pipeline
   - Code review between tasks

5. **Verify and Complete**
   - Run all tests
   - Verify against spec requirements
   - Use finishing-a-development-branch

## Agent Routing

| Task Type | Skill | MCP Servers |
|-----------|-------|-------------|
| iOS UI/Logic | ios-superpowers | sosumi |
| Firestore/Auth | firebase-superpowers | firebase |
| Cloud Functions | firebase-superpowers | firebase |
| Non-Firebase GCP | gcp-superpowers | gcloud |
| AI/Gemini | gemini-integration | gcloud |

## Prerequisites

- Spec document exists and is readable
- MCP servers configured (sosumi, firebase, gcloud, observability)
- Axiom plugin installed
- obra/superpowers installed

## Output

- Implementation plan in `docs/plans/`
- Implemented code in appropriate directories
- All tests passing
- Ready for merge or PR
```

**Step 3: Create archive directory and move old command**

Run: `mkdir -p .claude/archive && mv .claude/commands/ios-sprint-executor.md .claude/archive/`

**Step 4: Verify command exists**

Run: `cat .claude/commands/ios-sprint.md | head -20`
Expected: First 20 lines of new command

**Step 5: Commit**

```bash
git add .claude/commands/ios-sprint.md .claude/archive/
git commit -m "feat(claude): add /ios-sprint command, archive ios-sprint-executor

- New streamlined command for spec-driven sprints
- Routes to appropriate skill based on task domain
- Archives previous 1200-line implementation"
```

---

## Task 2: Create `/ios-debug` Command

**Files:**
- Create: `.claude/commands/ios-debug.md`

**Step 1: Create ios-debug command**

```markdown
---
name: ios-debug
description: Debug iOS issues using Axiom skills and Apple documentation
---

# iOS Debug Command

Systematic iOS debugging using Axiom skills and sosumi.ai documentation.

## Usage

\`\`\`
/ios-debug [issue-description]
/ios-debug [error-message]
\`\`\`

## Examples

\`\`\`
/ios-debug "BUILD FAILED - module 'AVFoundation' not found"
/ios-debug "App crashes on launch with EXC_BAD_ACCESS"
/ios-debug "Swift 6 actor isolation error in ViewModel"
/ios-debug "Memory leak in image processing"
\`\`\`

## What This Does

1. **Identify Issue Type**
   - Build/Compile → axiom-xcode-debugging
   - Memory → axiom-memory-debugging
   - Concurrency → axiom-swift-concurrency
   - UI → axiom-swiftui-* or axiom-liquid-glass
   - Database → axiom-swiftdata or axiom-database-migration
   - Testing → axiom-ui-testing
   - Energy → axiom-energy

2. **Activate Axiom Skill**
   - Systematic diagnosis workflow
   - Environment-first diagnostics
   - Common issue checklist

3. **Fetch Apple Documentation**
   - Use sosumi.ai MCP to look up APIs
   - Search for error messages
   - Get official fix patterns

4. **Apply Fix**
   - Follow documented patterns
   - Write test to verify fix
   - Commit with explanation

## Issue Routing

| Symptoms | Axiom Skill | First Action |
|----------|-------------|--------------|
| BUILD FAILED | axiom-xcode-debugging | Check build settings |
| module not found | axiom-xcode-debugging | Check target membership |
| EXC_BAD_ACCESS | axiom-memory-debugging | Check zombies |
| Memory leak | axiom-memory-debugging | Run Instruments |
| Actor isolated | axiom-swift-concurrency | Check actor boundaries |
| Data race | axiom-swift-concurrency | Add Sendable |
| SwiftUI crash | axiom-swiftui-* | Check state updates |
| Migration error | axiom-database-migration | Check schema version |
| Test flaky | axiom-ui-testing | Check async waits |
| Battery drain | axiom-energy | Run Power Profiler |

## Workflow

\`\`\`
1. Parse error/issue description
2. Route to Axiom skill
3. Run diagnostic workflow
4. Search sosumi.ai for API info
5. Apply fix pattern
6. Write test
7. Verify fix
8. Document solution
\`\`\`

## Integration with superpowers:systematic-debugging

This command wraps superpowers:systematic-debugging with iOS-specific enhancements:
- Automatic Axiom skill selection
- Apple docs grounding via sosumi.ai MCP
- iOS-specific diagnostic patterns

## Output

- Root cause identified
- Fix applied with test
- Documentation reference
- Commit with explanation
```

**Step 2: Verify command**

Run: `ls -la .claude/commands/ios-debug.md`
Expected: File exists with reasonable size

**Step 3: Commit**

```bash
git add .claude/commands/ios-debug.md
git commit -m "feat(claude): add /ios-debug command for iOS debugging

- Routes issues to appropriate Axiom skill
- Integrates sosumi.ai MCP for Apple docs lookup
- Wraps superpowers:systematic-debugging"
```

---

## Task 3: Create `/gcp-deploy` Command

**Files:**
- Create: `.claude/commands/gcp-deploy.md`

**Step 1: Create gcp-deploy command**

```markdown
---
name: gcp-deploy
description: Deploy Cloud Functions with verification
---

# GCP Deploy Command

Deploy Cloud Functions to staging or production with verification.

## Usage

\`\`\`
/gcp-deploy [function-name]
/gcp-deploy [function-name] --staging
/gcp-deploy [function-name] --production --verify
\`\`\`

## Examples

\`\`\`
/gcp-deploy ai-pipeline-orchestrator --staging
/gcp-deploy ai-pipeline-orchestrator --production --verify
/gcp-deploy gemini-service --staging
\`\`\`

## What This Does

1. **Pre-Deploy Checks**
   - Run local tests (`npm test`)
   - Verify TypeScript compiles
   - Check environment variables
   - Validate secrets exist

2. **Deploy to Staging** (default)
   \`\`\`bash
   firebase deploy --only functions:[name] --project abundance-mvp-staging
   \`\`\`

3. **Test Staging**
   - Send test request
   - Verify response structure
   - Check logs for errors

4. **Deploy to Production** (with --production)
   \`\`\`bash
   firebase deploy --only functions:[name] --project abundance-mvp
   \`\`\`

5. **Verify Production** (with --verify)
   - Check function status
   - Send smoke test request
   - Monitor logs
   - Verify observability alerts

## Flags

| Flag | Description |
|------|-------------|
| `--staging` | Deploy to staging only (default) |
| `--production` | Deploy to production |
| `--verify` | Run verification after deploy |
| `--dry-run` | Show commands without executing |

## MCP Servers Used

- **firebase** - Deploy commands, function management (primary)
- **gcloud** - Non-Firebase GCP resources if needed
- **observability** - Log monitoring, alert verification

## Prerequisites

- Firebase CLI authenticated (`firebase login`)
- Project configured in firebase.json
- Secrets in Secret Manager
- Tests passing locally

## Output

- Function deployed
- Verification results
- Log monitoring link
- Rollback command if needed
```

**Step 2: Verify command**

Run: `ls -la .claude/commands/gcp-deploy.md`
Expected: File exists

**Step 3: Commit**

```bash
git add .claude/commands/gcp-deploy.md
git commit -m "feat(claude): add /gcp-deploy command for Cloud Functions deployment

- Supports staging and production deployments
- Pre-deploy checks and post-deploy verification
- Uses Firebase MCP as primary deploy tool"
```

---

## Task 4: Create `firebase-superpowers` Skill

**Files:**
- Create: `.claude/skills/firebase-superpowers/SKILL.md`

**Step 1: Create skill directory**

Run: `mkdir -p .claude/skills/firebase-superpowers`

**Step 2: Create SKILL.md**

```markdown
---
name: firebase-superpowers
description: Firebase operations skill using official Firebase MCP server. Use for Firestore, Cloud Functions, Authentication, Storage, and Security Rules.
---

# Firebase Superpowers

Primary backend skill for all Firebase operations using the official Firebase MCP server.

## When This Skill Activates

- Firestore database operations (read, write, query)
- Cloud Functions deployment and management
- Firebase Authentication operations
- Firebase Storage operations
- Security Rules validation and deployment

## MCP Server

**Primary:** `firebase` (official Firebase MCP)

```json
{
  "firebase": {
    "command": "npx",
    "args": ["-y", "firebase-tools@latest", "mcp"]
  }
}
```

## Available Operations

### Firestore

| Operation | MCP Tool |
|-----------|----------|
| Get documents | `mcp__plugin_firebase_firebase__firestore_get_documents` |
| Query collection | `mcp__plugin_firebase_firebase__firestore_query_collection` |
| List collections | `mcp__plugin_firebase_firebase__firestore_list_collections` |
| Delete document | `mcp__plugin_firebase_firebase__firestore_delete_document` |

### Cloud Functions

| Operation | MCP Tool |
|-----------|----------|
| List functions | `mcp__plugin_firebase_firebase__functions_list_functions` |
| Get logs | `mcp__plugin_firebase_firebase__functions_get_logs` |

### Authentication

| Operation | MCP Tool |
|-----------|----------|
| Get users | `mcp__plugin_firebase_firebase__auth_get_users` |
| Update user | `mcp__plugin_firebase_firebase__auth_update_user` |
| Set SMS policy | `mcp__plugin_firebase_firebase__auth_set_sms_region_policy` |

### Storage

| Operation | MCP Tool |
|-----------|----------|
| Get download URL | `mcp__plugin_firebase_firebase__storage_get_object_download_url` |

### Security Rules

| Operation | MCP Tool |
|-----------|----------|
| Validate rules | `mcp__plugin_firebase_firebase__firebase_validate_security_rules` |
| Get rules | `mcp__plugin_firebase_firebase__firebase_get_security_rules` |

### Project Management

| Operation | MCP Tool |
|-----------|----------|
| Get project | `mcp__plugin_firebase_firebase__firebase_get_project` |
| List apps | `mcp__plugin_firebase_firebase__firebase_list_apps` |
| Get environment | `mcp__plugin_firebase_firebase__firebase_get_environment` |
| Initialize | `mcp__plugin_firebase_firebase__firebase_init` |

## Usage Patterns

### Querying Firestore

```
1. Use firestore_list_collections to discover available collections
2. Use firestore_query_collection with filters to find documents
3. Use firestore_get_documents for specific document retrieval
```

### Deploying Functions

```
1. Run local tests: npm test
2. Use functions_list_functions to verify current state
3. Deploy via firebase CLI: firebase deploy --only functions
4. Use functions_get_logs to verify deployment
```

### Managing Security Rules

```
1. Use firebase_get_security_rules to review current rules
2. Modify rules locally
3. Use firebase_validate_security_rules before deploy
4. Deploy: firebase deploy --only firestore:rules
```

## When NOT to Use This Skill

- Non-Firebase GCP resources → use `gcp-superpowers`
- iOS/Swift development → use `ios-superpowers`
- AI pipeline logic → use `gemini-integration`

## Error Handling

### Not logged in
→ Run: `firebase login`

### Wrong project
→ Run: `firebase use <project-id>`

### Rules validation failed
→ Review error message, fix rules syntax
```

**Step 3: Verify skill**

Run: `cat .claude/skills/firebase-superpowers/SKILL.md | head -30`
Expected: YAML frontmatter and skill header

**Step 4: Commit**

```bash
git add .claude/skills/firebase-superpowers/
git commit -m "feat(claude): add firebase-superpowers skill

- Primary skill for all Firebase operations
- Documents all Firebase MCP tools
- Covers Firestore, Functions, Auth, Storage, Rules"
```

---

## Task 5: Create `gcp-superpowers` Skill

**Files:**
- Create: `.claude/skills/gcp-superpowers/SKILL.md`

**Step 1: Create skill directory**

Run: `mkdir -p .claude/skills/gcp-superpowers`

**Step 2: Create SKILL.md**

```markdown
---
name: gcp-superpowers
description: Non-Firebase GCP operations using gcloud MCP server. Use for Cloud Storage, Monitoring, Logging, and other GCP services not covered by Firebase.
---

# GCP Superpowers

Skill for GCP operations that are NOT covered by Firebase MCP server.

## When This Skill Activates

- Cloud Storage bucket operations (outside Firebase Storage)
- Cloud Monitoring and alerting
- Cloud Logging queries
- Other GCP services (Vertex AI, BigQuery, etc.)

## MCP Servers

**Primary:** `gcloud` - General GCP CLI operations
**Secondary:** `observability` - Monitoring and logging
**Secondary:** `storage` - GCS bucket operations

## Available Operations

### Cloud Storage (via storage MCP)

| Operation | MCP Tool |
|-----------|----------|
| List buckets | `mcp__storage__list_buckets` |
| List objects | `mcp__storage__list_objects` |
| Read object | `mcp__storage__read_object_content` |
| Upload object | `mcp__storage__upload_object_safe` |
| Download object | `mcp__storage__download_object` |
| Delete object | `mcp__storage__delete_object` |

### Monitoring (via observability MCP)

| Operation | MCP Tool |
|-----------|----------|
| List metrics | `mcp__observability__list_metric_descriptors` |
| Get time series | `mcp__observability__list_time_series` |
| List alerts | `mcp__observability__list_alerts` |
| List alert policies | `mcp__observability__list_alert_policies` |

### Logging (via observability MCP)

| Operation | MCP Tool |
|-----------|----------|
| List logs | `mcp__observability__list_log_entries` |
| List log names | `mcp__observability__list_log_names` |
| List buckets | `mcp__observability__list_buckets` |
| List sinks | `mcp__observability__list_sinks` |

### Tracing (via observability MCP)

| Operation | MCP Tool |
|-----------|----------|
| List traces | `mcp__observability__list_traces` |
| Get trace | `mcp__observability__get_trace` |

### General GCP (via gcloud MCP)

| Operation | MCP Tool |
|-----------|----------|
| Run command | `mcp__gcloud__run_gcloud_command` |

## Usage Patterns

### Querying Logs

```
1. Use list_log_names to discover available logs
2. Build filter: severity="ERROR" AND timestamp > "2026-01-14T00:00:00Z"
3. Use list_log_entries with filter
4. Analyze results
```

### Checking Metrics

```
1. Use list_metric_descriptors to find relevant metrics
2. Define time interval (startTime, endTime)
3. Use list_time_series with filter and aggregation
4. Analyze time series data
```

### Managing Storage

```
1. Use list_buckets to see available buckets
2. Use list_objects with prefix filter
3. Use read_object_content for text files
4. Use download_object for binary files
```

## When NOT to Use This Skill

- Firestore operations → use `firebase-superpowers`
- Cloud Functions → use `firebase-superpowers`
- Firebase Auth → use `firebase-superpowers`
- iOS development → use `ios-superpowers`

## Common Commands via gcloud MCP

```bash
# List compute instances
mcp__gcloud__run_gcloud_command(args: ["compute", "instances", "list"])

# Get project info
mcp__gcloud__run_gcloud_command(args: ["projects", "describe", "PROJECT_ID"])

# List Cloud Run services
mcp__gcloud__run_gcloud_command(args: ["run", "services", "list"])
```
```

**Step 3: Verify skill**

Run: `cat .claude/skills/gcp-superpowers/SKILL.md | head -30`
Expected: YAML frontmatter and skill header

**Step 4: Commit**

```bash
git add .claude/skills/gcp-superpowers/
git commit -m "feat(claude): add gcp-superpowers skill

- Handles non-Firebase GCP operations
- Documents storage, observability, gcloud MCP tools
- Complements firebase-superpowers"
```

---

## Task 6: Create `gemini-integration` Skill

**Files:**
- Create: `.claude/skills/gemini-integration/SKILL.md`

**Step 1: Create skill directory**

Run: `mkdir -p .claude/skills/gemini-integration`

**Step 2: Create SKILL.md**

```markdown
---
name: gemini-integration
description: Skill for integrating Gemini 3 Pro with tool calling for the abundance cataloging pipeline. Covers prompt engineering, tool definitions, and response handling patterns.
---

# Gemini Integration

Skill for implementing Gemini 3 Pro integration with tool calling in the abundance cataloging pipeline.

## When This Skill Activates

- Implementing AI pipeline orchestration
- Creating Gemini tool definitions
- Handling tool calls and responses
- Prompt engineering for cataloging
- Confidence scoring and error handling

## Reference Implementation

See `functions/src/ai-pipeline/gemini/` for current implementation:
- `gemini-service.ts` - Core Gemini client
- Tool definitions in prompts files
- Test files for patterns

## Tool Calling Pattern

### Define Tools

```typescript
const tools: Tool[] = [{
  functionDeclarations: [{
    name: "tool_name",
    description: "Clear, concise description of what this tool does",
    parameters: {
      type: SchemaType.OBJECT,
      properties: {
        param1: {
          type: SchemaType.STRING,
          description: "Parameter description"
        }
      },
      required: ["param1"]
    }
  }]
}];
```

### Handle Tool Calls

```typescript
const response = await model.generateContent({
  contents: [{ role: "user", parts: [{ text: prompt }] }],
  tools: tools
});

// Check for tool calls
const candidate = response.response.candidates?.[0];
const functionCall = candidate?.content?.parts?.find(
  part => part.functionCall
)?.functionCall;

if (functionCall) {
  const result = await executeToolCall(functionCall);
  // Continue conversation with tool result
}
```

## Available Tools for Cataloging

### barcode_lookup

Look up product by UPC/EAN barcode.

```typescript
{
  name: "barcode_lookup",
  description: "Look up product information by barcode",
  parameters: {
    type: "object",
    properties: {
      barcode: { type: "string" },
      format: { type: "string", enum: ["UPC-A", "EAN-13", "CODE-128"] }
    },
    required: ["barcode"]
  }
}
```

### web_search

Search web for product information using Google Search grounding.

```typescript
{
  name: "web_search",
  description: "Search for product information",
  parameters: {
    type: "object",
    properties: {
      query: { type: "string" }
    },
    required: ["query"]
  }
}
```

### image_search

Visual search using Google Lens integration.

```typescript
{
  name: "image_search",
  description: "Search by product image",
  parameters: {
    type: "object",
    properties: {
      image_url: { type: "string" }
    },
    required: ["image_url"]
  }
}
```

## System Prompt Best Practices

1. **Clear role definition**: "You are a product cataloging assistant..."
2. **Workflow steps**: Numbered steps for decision process
3. **Confidence scoring**: "Rate confidence 0-100 based on..."
4. **Error handling**: "If uncertain, return needs_review: true"
5. **Output format**: JSON schema for structured responses

## Response Handling

```typescript
interface CatalogResult {
  item: {
    name: string;
    description: string;
    category: string;
    estimatedValue?: number;
  };
  confidence: number;
  sources: string[];
  needsReview: boolean;
}
```

## Error Handling

### Tool call failures
→ Retry with exponential backoff
→ Fall back to alternative tool
→ Return needs_review: true

### Low confidence
→ Try additional tools (web_search after barcode_lookup)
→ Aggregate confidence from multiple sources
→ Flag for human review if still low

### Rate limiting
→ Implement request queuing
→ Use appropriate quotas
→ Log and alert on limits

## Testing Patterns

See `functions/src/ai-pipeline/gemini/__tests__/` for test patterns:
- Mock Gemini responses
- Test tool call routing
- Test error handling
- Integration tests with real API
```

**Step 3: Verify skill**

Run: `cat .claude/skills/gemini-integration/SKILL.md | head -30`
Expected: YAML frontmatter and skill header

**Step 4: Commit**

```bash
git add .claude/skills/gemini-integration/
git commit -m "feat(claude): add gemini-integration skill

- Documents Gemini 3 Pro tool calling patterns
- Covers cataloging pipeline tools
- Includes response handling and error patterns"
```

---

## Task 7: Update `verified-stage-development` Skill

**Files:**
- Modify: `.claude/skills/verified-stage-development/SKILL.md`

**Step 1: Read current skill to understand structure**

Review existing implementation (already done in analysis phase).

**Step 2: Update skill with clearer orchestration**

Replace content with updated version that:
- Uses the new agent dispatch matrix
- References new skills (firebase-superpowers, gcp-superpowers, gemini-integration)
- Simplifies phases while maintaining quality gates

**Step 3: Verify changes**

Run: `head -50 .claude/skills/verified-stage-development/SKILL.md`
Expected: Updated content with new agent matrix

**Step 4: Commit**

```bash
git add .claude/skills/verified-stage-development/SKILL.md
git commit -m "refactor(claude): update verified-stage-development with new agent matrix

- Reference firebase-superpowers for Firebase operations
- Route non-Firebase GCP to gcp-superpowers
- Add gemini-integration for AI pipeline tasks"
```

---

## Task 8: Archive Deprecated Skills

**Files:**
- Move: `.claude/skills/ios-sprint-executor/` → `.claude/archive/skills/ios-sprint-executor/`

**Step 1: Create archive directory**

Run: `mkdir -p .claude/archive/skills`

**Step 2: Move deprecated skill**

Run: `mv .claude/skills/ios-sprint-executor .claude/archive/skills/`

**Step 3: Update README**

Add note to `.claude/README.md` about archived skills.

**Step 4: Verify**

Run: `ls -la .claude/archive/skills/`
Expected: ios-sprint-executor directory

**Step 5: Commit**

```bash
git add .claude/archive/ .claude/README.md
git commit -m "chore(claude): archive ios-sprint-executor skill

- Functionality merged into verified-stage-development
- Preserved for reference in .claude/archive/"
```

---

## Task 9: Update CLAUDE.md Quick Commands

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Read current CLAUDE.md**

Review existing quick commands section.

**Step 2: Update with new commands**

Add to Quick Commands section:
```markdown
## Quick Commands

```bash
/ios-sprint <spec>      # Start iOS sprint from spec
/ios-debug <issue>      # Debug iOS issue
/gcp-deploy <fn>        # Deploy Cloud Function
/validate-docs          # Check docs for broken links
/check-drift            # Verify ADR compliance
```
```

**Step 3: Verify changes**

Run: `grep -A 10 "Quick Commands" CLAUDE.md`
Expected: Updated commands section

**Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with new quick commands

- Add /ios-sprint, /ios-debug, /gcp-deploy
- Maintain existing validation commands"
```

---

## Task 10: Clean Up Temporary Files

**Files:**
- Delete: `docs/dev-workflow/SKILL*.md` (duplicate files)
- Delete: `docs/dev-workflow/files (3)/` (temporary directory)

**Step 1: List files to clean**

Run: `ls -la "docs/dev-workflow/"`
Expected: List of SKILL files and temporary directories

**Step 2: Remove temporary files**

Run: `trash "docs/dev-workflow/SKILL"*.md "docs/dev-workflow/SKILL (1).md" "docs/dev-workflow/SKILL (2).md" "docs/dev-workflow/SKILL (3).md" "docs/dev-workflow/SKILL (4).md" "docs/dev-workflow/SKILL (5).md"`

**Step 3: Keep useful reference files**

Keep: `ios-sprint.md`, `ios-debug.md`, `gcp-deploy.md` as they were used as templates.
Move architecture doc: `mv "docs/dev-workflow/files (3)/ios-superpowers-architecture.md" docs/dev-workflow/`

**Step 4: Remove empty directories**

Run: `trash "docs/dev-workflow/files (3)"`

**Step 5: Verify cleanup**

Run: `ls -la docs/dev-workflow/`
Expected: Only useful files remain

**Step 6: Commit**

```bash
git add docs/dev-workflow/
git commit -m "chore: clean up temporary workflow design files

- Remove duplicate SKILL*.md files
- Keep reference command templates
- Preserve architecture document"
```

---

## Verification Checklist

After completing all tasks, verify:

- [ ] `/ios-sprint` command exists and loads correctly
- [ ] `/ios-debug` command exists and loads correctly
- [ ] `/gcp-deploy` command exists and loads correctly
- [ ] `firebase-superpowers` skill exists
- [ ] `gcp-superpowers` skill exists
- [ ] `gemini-integration` skill exists
- [ ] `verified-stage-development` updated with new agent matrix
- [ ] `ios-sprint-executor` archived
- [ ] CLAUDE.md updated with new commands
- [ ] No temporary files remain in docs/dev-workflow/

---

## Rollback Plan

If issues arise, revert commits:

```bash
git log --oneline -10  # Find commits
git revert <commit-hash>  # Revert specific commit
```

Or restore archived files:

```bash
mv .claude/archive/skills/ios-sprint-executor .claude/skills/
```

---

**Generated by:** superpowers:writing-plans
**Date:** 2026-01-14
