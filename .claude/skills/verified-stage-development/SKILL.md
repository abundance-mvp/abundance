---
name: verified-stage-development
aliases: [stage-orchestrator]
description: Orchestrates deterministic stage development with research verification, planning, execution, and approval gates
---

# Verified Stage Development (Phase 1)

Orchestrates stage development with research verification and quality gates.

**Design:** Embedded in this skill file (Phase 1 implementation)

**Invocation:** `/verified-stage-development stage-X.X`

**Example:** `/verified-stage-development stage-2.2`

---

## Phase 1 Scope

This is Phase 1 implementation:

- ✅ Context Collection
- ✅ Research Verification Hook
- ✅ Planning Integration (write-plan)
- ✅ Two-Gate Approval Flow
- ✅ Checkpoint Generation
- ✅ Master Document Drift Detection (manual)
- ❌ NO verification hook (Phase 2)

---

## Parameters

- `stage-number` (required): Stage identifier (e.g., `stage-2.2`, `stage-3.1`)

---

## Process

### Phase 1: Context Collection

**Purpose:** Load all relevant documents with deterministic file list.

**Steps:**

1. **Parse stage number from invocation**

   - Extract from command: `/verified-stage-development stage-2.2` → `2.2`
   - Validate format: `stage-X.X` where X is digit

2. **Read context-map.json**

   - File: `docs/context-map.json`
   - Look up key: `stage-X.X` (e.g., `stage-2.2`)
   - Extract: `required_inputs`, `status`, `apple_docs` flag
   - This provides deterministic list of files to load

3. **Check prerequisites**

   **If iOS stage:**

   - Check: `docs/apple/` directory exists
   - If missing: ERROR and stop

     ```
     ERROR: Apple documentation not found.

     iOS stages (2.2, 3.1, 4.1) require Apple developer documentation for accurate verification.

     Run this command first:
     /apple-docs-fetcher

     Then retry: /verified-stage-development stage-X.X
     ```

   **If not first stage (X.X > 1.1):**

   - Check: `docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md` exists
   - Calculate previous stage number (e.g., 2.2 → 2.1)
   - If missing: ERROR and stop

     ```
     ERROR: Previous stage not complete.

     Cannot find: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md

     Complete Stage [X.Y-1] first before running Stage X.X.
     ```

4. **Build explicit file list from context-map.json**

   Using data from context-map.json for current stage:

   a. Load common files (always required):

   ```
   - docs/abundance-analysis-pipeline-design.md
   ```

   b. Load stage-specific required inputs:

   - `required_inputs.common`: Common docs
   - `required_inputs.from_stage_X.Y`: Previous stage outputs
   - `required_inputs.from_phase_N`: Phase-level dependencies
   - `required_inputs.all_adrs`: All ADRs (if specified)
   - `required_inputs.all_designs`: All designs (if specified)
   - `required_inputs.all_specs`: All specs (if specified)
   - `required_inputs.all_tech_stack`: All tech stack docs (if specified)
   - `required_inputs.apple_docs`: Path to Apple docs (if iOS stage)

   c. Expand glob patterns if present:

   - `docs/adr/*.md` → Read all ADR files
   - `docs/design/*.md` → Read all design files
   - `docs/specs/*.md` → Read all spec files
   - `docs/tech-stack/*.md` → Read all tech stack files

5. **Load all files**

   - Use Read tool for each file in the explicit list
   - Store in context for next phases
   - If any REQUIRED file missing → ERROR with specific filename
   - Track which files were loaded for verification

6. **Display context loaded summary**

   ```
   Phase 1: Context Collection
   ✅ Read: docs/context-map.json (stage-X.X context map)
   ✅ Read: docs/abundance-analysis-pipeline-design.md
   ✅ Read: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md
   ✅ Read: [N] files from required_inputs
      - [N] ADRs from docs/adr/
      - [N] designs from docs/design/
      - [N] specs from docs/specs/
      - [N] tech stack docs from docs/tech-stack/
   ✅ Verified: docs/apple/ exists (iOS stage)

   Total files loaded: [N]
   Context loaded. Proceeding to Phase 2...
   ```

---

### Phase 2: Research Verification Hook

**Purpose:** Verify technical claims against official documentation.

**Implementation:** Dispatch sub-agent via Task tool.

**Steps:**

1. **Build sub-agent prompt**

   ```markdown
   You are a research verification agent for Stage X.X of the Abundance Analysis Pipeline.

   ## CONTEXT

   [Include all files loaded in Phase 1]

   Master Pipeline Design: docs/abundance-analysis-pipeline-design.md
   Previous Stage: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md (if exists)
   All ADRs: [list]
   All Designs: [list]
   All Specs: [list]
   Tech Stack: [list]
   [If iOS] Apple Docs: docs/apple/ (search using Grep tool)

   ## YOUR TASK

   ### 1. Identify Technical Claims

   Read Stage X.X section from abundance-analysis-pipeline-design.md.
   Extract ALL technical claims requiring verification:

   - Pricing (cost per request, monthly fees, storage costs)
   - Performance (latency, throughput, response times)
   - Capabilities (supported features, API availability, version requirements)
   - Limitations (rate limits, quotas, restrictions)

   ### 2. Verify iOS/Apple Claims

   For claims involving Apple technologies:

   - Use Grep tool to search docs/apple/{technology}/\*.md
   - Example: `Grep pattern:"VNRecognizeObjects" path:"docs/apple/vision/"`
   - Extract accurate information from local markdown
   - Note: These docs pre-fetched from developer.apple.com via sosumi.ai

   ### 3. Verify GCP/Firebase/Other Claims

   For non-Apple claims:

   - Use WebSearch to find official documentation
   - Use WebFetch to extract specific information
   - Prioritize official sources: cloud.google.com, firebase.google.com

   ### 4. Resolve Contradictions

   If conflicting information found:

   - Fetch latest documentation from official source
   - Document which source is authoritative and why
   - Update verification with resolved information
   - Do NOT block or require human input - resolve automatically

   ### 5. Build Curated Source List

   For this stage's technologies, compile official documentation URLs.

   ## OUTPUT FORMAT

   Create: docs/validation/RESEARCH-VALIDATION-stage-X.X.md

   ## Structure:

   # Research Validation Report: Stage X.X

   **Created**: [date]
   **Stage**: [stage number and name]
   **Technologies Verified**: [list]

   ## Executive Summary

   [2-3 sentences: what was verified, sources used, any issues resolved]

   ## Verified Technical Claims

   ### Claim 1: [Statement from requirements]

   - **Verification Status**: ✅ VERIFIED / ⚠️ PARTIALLY VERIFIED / ❌ NOT FOUND
   - **Actual Value**: [from official source]
   - **Source**: [URL]
   - **Notes**: [any important context]

   ### Claim 2: [Statement]

   ...

   ## Contradictions Resolved

   [Only if contradictions found]

   ### Issue 1: [Description]

   - **Original Claim**: [what was stated or assumed]
   - **Conflict**: [why it was wrong/outdated]
   - **Resolution**: [accurate information]
   - **Source**: [authoritative URL]

   ## Curated Sources for This Stage

   ### Apple/iOS Sources

   - [Technology]: [sosumi.ai URL] (local: docs/apple/[path])
   - ...

   ### GCP/Firebase Sources

   - [Service]: [official URL]
   - ...

   ## Warnings

   [Any warnings about stale data, deprecated APIs, or uncertainty]

   ## Verification Summary

   - Total claims identified: X
   - Verified as accurate: X
   - Updated/corrected: X
   - Unable to verify: X

   ---
   ```

2. **Dispatch sub-agent**

   ```
   Tool: Task
   Parameters:
     subagent_type: general-purpose
     description: Research verification for stage X.X
     prompt: [prompt from step 1]
   ```

3. **Wait for sub-agent completion**

   Sub-agent will create: `docs/validation/RESEARCH-VALIDATION-stage-X.X.md`

4. **Validate output**

   - Check file exists: `docs/validation/RESEARCH-VALIDATION-stage-X.X.md`
   - If missing: Error and offer retry

5. **Display summary**

   ```
   Phase 2: Research Verification Hook
   Launching research sub-agent...

   Verifying technical claims for Stage X.X...
   - Searching docs/apple/swift/ for Swift 6 features
   - Searching docs/apple/swiftui/ for architecture patterns
   - WebSearch: Firebase iOS SDK pricing
   - Resolved contradiction: Firebase Auth pricing updated to $0.XXXX/MAU

   ✅ Created: docs/validation/RESEARCH-VALIDATION-stage-X.X.md
      - [X] claims verified
      - [Y] contradictions resolved
      - [Z] sources documented

   Proceeding to Phase 3...
   ```

---

### Apple Documentation Verification (iOS stages only)

**IMPORTANT:** Use apple-docs-fetcher pattern to avoid token limit failures.

When stage requires iOS/Swift implementation:

1. Read TECH-STACK-MAP to identify specific APIs to verify (not broad frameworks)
2. Identify 3-5 focused APIs for verification (e.g., VNCoreMLRequest, VNDetectBarcodesRequest)
3. Pass focused API list to research verification agent with token budget
4. Research agent uses apple-docs-fetcher pattern:
   - Search first: mcp**sosumi**searchAppleDocumentation
   - Extract key info from search results
   - Fetch selectively: Only if search insufficient
   - Immediately extract and discard full docs
   - Create concise verification summary
   - Token budget: 8,000 per API, 25,000 total max
5. Research agent returns summary (not full docs)
6. Proceed with planning using verification summary

**Do NOT:**

- ❌ Fetch broad documentation paths (e.g., "/documentation/vision")
- ❌ Accumulate multiple fetched docs in context
- ❌ Use the full apple-docs-fetcher skill (causes token overflow)

---

### Phase 3: Planning Integration (write-plan)

**Purpose:** Create implementation plan with verified context via plugin (superpowers:write-plan).

**Implementation:** Invoke superpowers:write-plan via SlashCommand tool.

**Steps:**

1. **Build enhanced instructions for write-plan**

   ```markdown
   You are creating an implementation plan for Stage X.X of the Abundance Analysis Pipeline.

   ## CONTEXT PROVIDED

   All context from Phase 1 (master design, previous stage, ADRs, designs, specs)
   Research Validation Report from Phase 2: docs/validation/RESEARCH-VALIDATION-stage-X.X.md

   ## MANDATORY REQUIREMENTS

   ### 1. Verified Claims Only

   All pricing, performance, and capability claims MUST reference the research validation report.

   Format: "Firebase Storage costs $0.026/GB/month (ref: RESEARCH-VALIDATION-stage-X.X.md, Claim 3)"

   ### 2. Apple Documentation (iOS stages)

   For iOS-related APIs, you have access to docs/apple/ with pre-fetched documentation.
   Use Grep to search these files for accurate API usage.

   Example: `Grep pattern:"VNRecognizeObjects" path:"docs/apple/vision/"`

   ### 3. Real Libraries Only

   All code examples MUST use libraries specified in TECH-STACK-MAP-001.
   Verify imports and package names are real and available.

   ### 4. Test-Driven Development

   For each implementation task, include:

   - Given/When/Then acceptance criteria
   - Example test case structure
   - Reference TEST-STRATEGY-001 for test pyramid guidance

   ### 5. Previous Stage Context

   This plan builds on previous stages. Reference and maintain consistency with:

   - Previous stage: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md
   - Relevant ADRs: [list]
   - Relevant designs: [list]

   ### 6. Master Pipeline Alignment

   Your plan must accomplish objectives defined in:
   docs/abundance-analysis-pipeline-design.md (Stage X.X section)

   ## OUTPUT STRUCTURE

   Create TWO files:

   ### File 1: docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md

   Detailed implementation plan:

   - Background & Context (links to previous artifacts)
   - Objectives (from master pipeline design)
   - Verified Technical Constraints (from research report)
   - Implementation Tasks (detailed, with test examples)
   - Acceptance Criteria (traceable to master design)
   - Dependencies & Risks

   ### File 2: docs/plans/PLAN-SUMMARY-stage-X.X.md

   Concise summary (500-1000 words):

   - What this stage accomplishes
   - Key decisions made
   - Outputs created
   - Next stage preview

   This becomes the master reference for Stage X.X.
   ```

2. **Invoke write-plan**

   ```
   Tool: SlashCommand
   Command: /superpowers:write-plan

   Pass context:
   - All Phase 1 files
   - Research validation report
   - Enhanced instructions from step 1
   ```

3. **Wait for write-plan completion**

   write-plan will create:

   - `docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md`
   - `docs/plans/PLAN-SUMMARY-stage-X.X.md`

4. **Validate outputs**

   - Check both files exist
   - Verify PLAN-SUMMARY is concise (500-1000 words)
   - Verify detailed plan references research validation report

5. **Display summary**

   ```
   Phase 3: Planning
   Invoking superpowers:write-plan...

   Creating implementation plan with verified context...

   ✅ Created: docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md
   ✅ Created: docs/plans/PLAN-SUMMARY-stage-X.X.md

   Plan includes:
   - [N] implementation tasks
   - [N] ADRs to create
   - [N] design documents to create
   - [N] test plans

   Proceeding to Gate 1 (Human Approval)...
   ```

---

### GATE 1: Human Approval (Post-Planning)

**Purpose:** Human reviews research and plan before execution.

**Phase 1 Note:** No verification sub-agent in Phase 1. Gate 1 reviews research + plan only.

**Steps:**

1. **Display gate header**

   ```
   ═══════════════════════════════════════════════════════════
   STAGE X.X VERIFICATION COMPLETE
   ═══════════════════════════════════════════════════════════
   ```

2. **Display research validation summary**

   ```
   Research Validation:
   ✅ docs/validation/RESEARCH-VALIDATION-stage-X.X.md
      - [X] claims verified
      - [Y] contradictions resolved
      - [Z] sources documented
   ```

3. **Display plan creation summary**

   ```
   Plan Created:
   ✅ docs/plans/PLAN-SUMMARY-stage-X.X.md
   ✅ docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md
   ```

4. **Display gate instructions**

   ```
   ═══════════════════════════════════════════════════════════
   NEXT: Execute plan to create stage artifacts

   Please review:
   1. Research validation report (are claims verified?)
   2. Plan summary (does it align with stage objectives?)

   Type 'proceed to execute' to continue
   Type 'abort' to stop
   ═══════════════════════════════════════════════════════════
   ```

5. **Wait for human response**

   - Listen for: "proceed to execute", "proceed", "execute", "continue", "yes"
   - If user says "abort", "stop", "cancel": Exit skill gracefully
   - If ambiguous: Ask for clarification

6. **On approval, display transition**

   ```
   ✅ Approval received. Proceeding to Phase 4...
   ```

---

### Phase 4: Execution (execute-plan)

**Purpose:** Create all stage artifacts per verified plan.

**Implementation:** Invoke plugin superpowers:execute-plan via SlashCommand tool.

**Steps:**

1. **Build enhanced instructions for execute-plan**

   ```markdown
   You are executing the implementation plan for Stage X.X.

   ## CONTEXT PROVIDED

   Plan: docs/plans/[YYYY-MM-DD]-stage-X.X-[topic].md
   Plan Summary: docs/plans/PLAN-SUMMARY-stage-X.X.md
   All Phase 1 context (master design, ADRs, designs, specs)
   Research validation report: docs/validation/RESEARCH-VALIDATION-stage-X.X.md

   ## EXECUTION REQUIREMENTS

   ### 1. Follow Plan Exactly

   Implement all tasks as specified in the plan.

   ### 2. Create Artifacts in Correct Locations

   - Specs: docs/specs/
   - Designs: docs/design/
   - ADRs: docs/adr/
   - Tech stack: docs/tech-stack/
   - Test plans: docs/test/

   ### 3. Include Document Metadata Headers

   Every document MUST start with:
   ```

   # [Document Title]

   **Created**: [YYYY-MM-DD]
   **Stage**: [X.X - Stage Name]
   **References**: [list of related docs]
   **Status**: Draft

   ```

   ### 4. Cross-Reference Related Artifacts

   In document body, reference related documents:
   - "See ADR-XXX for rationale"
   - "Implements DESIGN-XXX architecture"
   - "Tested per TEST-XXX strategy"

   ### 5. Follow TDD Pattern for Test Examples

   All test examples should follow:
   - Given: Setup/preconditions
   - When: Action under test
   - Then: Expected outcome

   ### 6. Batch Execution with Review Checkpoints

   Follow execute-plan skill's batch execution pattern.
   Present work for review between logical groups.
   ```

2. **Invoke execute-plan**

   ```
   Tool: SlashCommand
   Command: /superpowers:execute-plan

   Pass context:
   - All Phase 1 files
   - Research validation report
   - Plans from Phase 3
   - Enhanced instructions from step 1
   ```

3. **Monitor execution**

   execute-plan will create artifacts as specified in plan.
   Track which artifacts are created for Phase 5.

4. **On completion, display summary**

   ```
   Phase 4: Execution
   Invoking superpowers:execute-plan...

   Executing plan tasks...

   ✅ Created: docs/design/DESIGN-XXX-[name].md
   ✅ Created: docs/adr/ADR-XXX-[name].md
   ✅ Created: docs/adr/ADR-XXX-[name].md
   ✅ Created: docs/adr/ADR-XXX-[name].md
   ✅ Created: docs/design/[name].md
   ✅ Created: docs/design/[name].md

   Artifacts created: [N] total
   - [X] Specifications
   - [Y] Design Documents
   - [Z] ADRs
   - [W] Test Plans

   Proceeding to Phase 5 (Checkpoint)...
   ```

---

### Phase 5: Checkpoint & Master Document Drift Detection

**Purpose:** Generate checkpoint document, detect drift, update PROJECT-STATUS.md.

**Steps:**

1. **Collect execution results**

   From Phase 4, we have:

   - List of all artifacts created
   - Any execution errors (if any)
   - Key decisions made (from plan and ADRs)

2. **Detect master document drift**

   a. Read Stage X.X section from: `docs/abundance-analysis-pipeline-design.md`

   b. Compare stage definition with actual execution:

   - Were objectives achieved as defined?
   - Were outputs different than specified?
   - Did scope expand or contract?
   - Did architecture decisions deviate?

   c. If deviations detected:

   - Identify specific text to change in master document
   - Create before/after diff
   - Document rationale for change

   Example deviations:

   - Stage said "TBD by expert" → Now we have specific decision in ADR
   - Stage listed 3 outputs → We created 5 outputs
   - Stage suggested approach A → We chose approach B with justification

3. **Generate checkpoint document**

   Create: `docs/checkpoints/CHECKPOINT-stage-X.X-[name].md`

   Template:

   ```markdown
   # CHECKPOINT: Stage X.X - [Stage Name]

   **Date**: [YYYY-MM-DD]
   **Status**: Awaiting Approval
   **Plan**: docs/plans/PLAN-SUMMARY-stage-X.X.md

   ---

   ## Executive Summary

   [3-5 sentences: what was accomplished, key findings, recommendation]

   ---

   ## Work Completed

   - ✅ Research validation completed ([X] claims verified)
   - ✅ Implementation plan created and approved
   - ✅ [Major deliverable 1]
   - ✅ [Major deliverable 2]
   - ✅ [Major deliverable 3]

   ---

   ## Key Decisions Made

   ### Decision 1: [Decision Name]

   **Rationale**: [2-3 sentences explaining why]
   **Impact**: [What this enables or constrains]
   **Documented in**: [ADR-XXX link]

   ### Decision 2: [Decision Name]

   **Rationale**: [...]
   **Impact**: [...]
   **Documented in**: [...]

   ---

   ## Artifacts Generated

   **Specifications:**

   - 📄 [docs/specs/XXX.md](../specs/XXX.md) - [Description]

   **Design Documents:**

   - 📄 [docs/design/DESIGN-XXX.md](../design/DESIGN-XXX.md) - [Description]

   **Architecture Decision Records:**

   - 📄 [docs/adr/ADR-XXX.md](../adr/ADR-XXX.md) - [Description]

   **Validation Reports:**

   - 📄 [docs/validation/RESEARCH-VALIDATION-stage-X.X.md](../validation/...) - Research verification

   **Plans:**

   - 📄 [docs/plans/PLAN-SUMMARY-stage-X.X.md](../plans/...) - Master stage reference

   ---

   ## Master Pipeline Document Drift

   [If no deviations:]
   ✅ **No drift detected** - Stage execution aligned perfectly with master pipeline design.

   [If deviations detected:]
   ⚠️ **Deviations from master design detected**

   The following aspects of stage execution differed from the original design in `docs/abundance-analysis-pipeline-design.md`:

   ### Deviation 1: [Description]

   **Original Design Said:**
   ```

   [Quote from master document, including line numbers if possible]

   ```

   **Actual Execution:**
   ```

   [What actually happened]

   ````

   **Rationale for Change:**
   [Why this deviation occurred - reference ADRs if applicable]

   **Proposed Master Document Update:**
   ```diff
   - [Original text]
   + [Proposed updated text]
   ````

   ### Deviation 2: [...]

   **Recommendation**: Review proposed changes above. If approved, manually update `docs/abundance-analysis-pipeline-design.md` with the proposed text.

   ***

   ## Risks & Concerns Identified

   [If any risks found during execution]

   ⚠️ **[Risk 1: Risk Name]**

   - **Description**: [What could go wrong]
   - **Impact**: High/Medium/Low
   - **Probability**: High/Medium/Low
   - **Mitigation**: [Proposed approach]

   ***

   ## Dependencies for Next Stage

   The next stage ([X.Y+1 - Stage Name]) requires:

   - ✅ [PLAN-SUMMARY-stage-X.X.md - Complete]
   - ✅ [ADR-XXX - Complete]
   - ✅ [DESIGN-XXX - Complete]
   - ⏳ [Item waiting on external factor]

   ***

   ## Next Stage Preview

   **Stage [X.Y+1]**: [Stage Name]

   - **Expert Agent**: [Name and domain]
   - **Will accomplish**: [1-2 sentences]
   - **Will produce**: [Key outputs]
   - **Prerequisites**: [This checkpoint approval + any other items]

   ***

   ## Required Human Action

   Please review this checkpoint and:

   - [ ] Review all artifacts generated (links above)
   - [ ] Review key decisions made
   - [ ] Review and acknowledge risks
   - [ ] If drift detected: Review proposed master document changes
   - [ ] **Provide approval to proceed**

   ### How to Respond

   - **"Approved - proceed to Stage X.Y+1"** - Mark stage complete, ready for next stage
   - **"Approved with changes: [details]"** - Make changes, regenerate checkpoint
   - **"Request revision: [what needs to change]"** - Fix issues, re-run

   ### If Master Document Changes Proposed

   After approval, manually update `docs/abundance-analysis-pipeline-design.md`:

   1. Open the master document
   2. Find the Stage X.X section
   3. Apply the proposed changes shown in "Master Pipeline Document Drift" section above
   4. Commit changes with message: "docs: Update Stage X.X definition based on execution (CHECKPOINT-stage-X.X)"

   ***

   **Generated by**: verified-stage-development orchestrator (Phase 1)
   **Verification Status**: Research Verified

   ```

   ```

4. **Update PROJECT-STATUS.md**

   a. Read current PROJECT-STATUS.md

   b. Update stage status:

   - Find Stage X.X in progress tracker table
   - Change status from "⏳ Prompt Needed" to "✅ Complete - [YYYY-MM-DD]"
   - Update outputs column with artifact links

   c. Update "Next Steps" section:

   - Point to Stage X.Y+1 as next action

   d. Save updated PROJECT-STATUS.md

5. **Display checkpoint summary**

   ```
   Phase 5: Checkpoint & Drift Detection

   Generating checkpoint...

   Execution summary:
   - [N] artifacts created
   - [M] key decisions documented

   Detecting drift from master design...
   [If drift found:]
   ⚠️ Drift detected: [brief description]
   [If no drift:]
   ✅ No drift - execution aligned with master design

   ✅ Created: docs/checkpoints/CHECKPOINT-stage-X.X-[name].md
   ✅ Updated: PROJECT-STATUS.md

   Proceeding to Gate 2 (Final Approval)...
   ```

---

### GATE 2: Human Approval (Post-Checkpoint)

**Purpose:** Human reviews checkpoint and approves stage completion.

**Steps:**

1. **Display gate header**

   ```
   ═══════════════════════════════════════════════════════════
   STAGE X.X EXECUTION COMPLETE
   ═══════════════════════════════════════════════════════════
   ```

2. **Display checkpoint summary**

   ```
   Checkpoint Generated:
   📋 docs/checkpoints/CHECKPOINT-stage-X.X-[name].md

   Artifacts Created: [N] total
   ✅ [X] Specifications
   ✅ [Y] Design Documents
   ✅ [Z] ADRs
   ✅ [W] Validation Reports
   ```

3. **Display drift status**

   [If drift detected:]

   ```
   ⚠️  MASTER DOCUMENT DRIFT DETECTED

       [Brief summary of changes]

       Review checkpoint for:
       - Detailed diff of proposed changes
       - Rationale for each deviation
       - Instructions for manual update

       After approval, you will need to manually update:
       docs/abundance-analysis-pipeline-design.md
   ```

   [If no drift:]

   ```
   ✅ No drift detected - execution aligned with master design
   ```

4. **Display PROJECT-STATUS update**

   ```
   PROJECT-STATUS.md Updated:
   ✅ Stage X.X marked complete
   ✅ Progress tracker updated
   ✅ Next steps updated
   ```

5. **Display gate instructions**

   ```
   ═══════════════════════════════════════════════════════════
   NEXT: Review checkpoint and approve to continue

   Please review:
   1. Checkpoint document (see all artifacts and decisions)
   2. Master document drift (if any)
   3. Risks and concerns

   Type 'approved - proceed to Stage X.Y+1' to complete
   Type 'approved with changes: [details]' to revise
   Type 'request revision: [what needs to change]' to fix issues
   ═══════════════════════════════════════════════════════════
   ```

6. **Wait for human response**

   - Listen for: "approved", "approved - proceed to stage X.Y+1"
   - If "approved with changes": Note changes, offer to revise
   - If "request revision": Note issues, offer to re-run phases

7. **On approval with drift detected**

   ```
   ✅ Approval received.

   ⚠️ Master document changes proposed.

   Please manually update docs/abundance-analysis-pipeline-design.md:

   1. Open: docs/abundance-analysis-pipeline-design.md
   2. Find: Stage X.X section (search for "Stage X.X")
   3. Apply: Proposed changes from checkpoint
   4. Commit: "docs: Update Stage X.X definition based on execution"

   Have you updated the master document?
   Type 'yes' to confirm and complete stage.
   Type 'skip' to complete without updating (not recommended).
   ```

8. **Wait for drift update confirmation**

   - Listen for: "yes", "done", "updated", "complete"
   - If "skip": Warn but proceed

9. **Final stage completion**

   a. Update PROJECT-STATUS.md final timestamp

   b. Display completion message:

   ```
   ═══════════════════════════════════════════════════════════
   ✅ STAGE X.X COMPLETE
   ═══════════════════════════════════════════════════════════

   Summary:
   - Research: [X] claims verified
   - Planning: Complete
   - Execution: [N] artifacts created
   - Checkpoint: Approved
   - Master doc: [Updated / No changes needed]

   Next Stage: X.Y+1 - [Stage Name]

   Ready to run: /verified-stage-development stage-X.Y+1

   ═══════════════════════════════════════════════════════════
   ```

---

## Error Handling

### Prerequisite Errors

**Apple docs missing (iOS stage):**

```
ERROR: Apple documentation not found.

iOS stages (2.2, 3.1, 4.1) require Apple developer documentation.

Run: /apple-docs-fetcher

Then retry: /verified-stage-development stage-X.X
```

**Previous stage missing:**

```
ERROR: Previous stage not complete.

Cannot find: docs/plans/PLAN-SUMMARY-stage-[X.Y-1].md

Complete Stage [X.Y-1] first.
```

**Master design missing:**

```
ERROR: Master pipeline design not found.

Required file: docs/abundance-analysis-pipeline-design.md

This file must exist to run stage orchestration.
```

### Research Hook Errors

**Sub-agent timeout:**

```
ERROR: Research verification sub-agent timed out.

Options:
1. Type 'retry' to run research verification again
2. Type 'abort' to stop
```

**Research output file missing:**

```
ERROR: Research sub-agent completed but did not create output file.

Expected: docs/validation/RESEARCH-VALIDATION-stage-X.X.md

Options:
1. Type 'retry' to run research verification again
2. Type 'abort' to stop
```

### Planning Errors

**write-plan fails:**

```
ERROR: Planning failed.

[Error details from write-plan]

Options:
1. Type 'retry' to run planning again
2. Type 'abort' to stop
```

### Execution Errors

**execute-plan fails:**

```
ERROR: Execution failed.

[Error details from execute-plan]

Progress: [N] artifacts created before failure
Saved: Partial progress in docs/

Options:
1. Type 'resume' to continue from last successful task
2. Type 'abort' to stop
```

### File Permission Errors

**Cannot write file:**

```
ERROR: Permission denied writing to: [path]

Check directory permissions and retry.
```

---

## Stale Documentation Warnings

**Apple docs >30 days old:**

During context collection, check manifest dates.

If any manifest shows fetch_date > 30 days ago:

```
⚠️ Warning: Apple documentation is [X] days old (fetched: YYYY-MM-DD)

Recommendation: Refresh docs after this stage completes
Command: /apple-docs-fetcher --refresh

Continuing with existing documentation...
```

This is a warning only, not blocking.

---

## Notes

- This is Phase 1 implementation
- Phase 2 will add: verification hook (code validation, TDD enforcement)
- Phase 3 will add: dry-run mode, structured JSON output, advanced recovery
- Design: Embedded in this skill file (see header)

---
