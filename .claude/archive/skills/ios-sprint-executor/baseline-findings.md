# iOS Sprint Executor - Baseline Findings (RED Phase)

## Test Results Summary

| Scenario | Agent Behavior | Skill Gap | Severity |
|----------|----------------|-----------|----------|
| 1. Code Review | Doesn't fetch Apple docs during review | Phase 4 missing docs fetching | **CRITICAL** |
| 2. Device Build | Can't build/deploy to device via CLI | No device build phase | **CRITICAL** |
| 3. UI/UX Brainstorm | Identifies gaps but doesn't brainstorm | No brainstorming integration | **HIGH** |
| 4. Spec Drift | Detects drift but doesn't sync specs | No spec sync phase | **HIGH** |
| 5. Q&A Grounding | Uses docs (good) but no Q&A mode | No guidance mode | **MEDIUM** |

---

## Detailed Findings

### Scenario 1: Code Review Without Apple Docs Fetching

**What happened:**
- ios-sprint-executor only fetches Apple docs in Phase 1 (Pre-Sprint Setup)
- Phase 4 (Code Review) doesn't fetch docs to verify latest APIs
- Uses deprecated `apple-docs-fetcher` instead of `apple-docs-fetcher`

**User complaint confirmed:**
> "skill doesn't seem to use apple-docs-fetcher very often when performing code review. this is important since my ios app is using the latest apple APIs and swiftui frameworks."

**Root cause:**
- Lines 89-137: Apple docs fetched only once at sprint start
- Lines 451-499: Phase 4 (Code Review) has no docs fetching
- Line 91: References deprecated `apple-docs-fetcher`

**Impact:** Code using Swift 6.0/latest SwiftUI features doesn't get verified against latest Apple docs.

---

### Scenario 2: Building iOS App on Device

**What happened:**
- Skill has no phase for building/deploying to physical devices
- Agent tried `xcodebuild` but lacked best practices knowledge
- No automatic troubleshooting of build system issues
- No guidance on Swift 6.0/iOS 18 build settings

**User complaint confirmed:**
> "I want the skill to be better at building (and troubleshooting) the iOS app that is installed on the device. I don't want to have to work through the xcode-beta GUI. It should know the best settings and apply them to xcode."

**Root cause:**
- No "Phase 7: Device Build & Deploy" in skill
- No Xcode build settings reference
- No troubleshooting playbook

**Impact:** Users must manually build via Xcode GUI or figure out xcodebuild themselves.

---

### Scenario 3: Missing UI/UX - No Brainstorming

**What happened:**
- Agent identified missing UI/UX features (✅ good)
- Agent did NOT invoke `superpowers:brainstorm` skill
- Skill doesn't instruct brainstorming for UI/UX refinement

**Agent rationalizations (verbatim):**
- "This is just analysis, not design"
- "The user wants a quick answer"
- "There's no code to write yet"
- "It's just a comparison task"

**User complaint confirmed:**
> "It should be able to determine what ui/ux features are missing and work with me in a socratic method (superpowers:brainstorm) to iteratively make changes to the app as things evolve."

**Root cause:**
- No "Phase 1.5: UI/UX Review & Brainstorming" in skill
- No instruction to invoke brainstorming when gaps identified
- Sprint execution is too linear (plan → execute → review → PR)

**Impact:** UI/UX improvements require manual user intervention instead of proactive Socratic refinement.

---

### Scenario 4: Spec Drift - No Verification

**What happened:**
- Agent detected spec drift (✅ good)
- Agent did NOT invoke `verified-stage-development` skill
- Skill has no phase for spec drift checking/prevention

**User complaint confirmed:**
> "When changes are agreed upon and requirements and planning is nailed down the skill should invoke a version of the verified-stage-development skill and update/create/delete spec documents in docs/ to ensure there is no drift between the spec's and the implementation."

**Root cause:**
- No "Phase 6.5: Spec Sync & Verification" in skill
- No instruction to invoke verified-stage-development before PR
- Assumes specs stay in sync (they don't)

**Impact:** Implementation diverges from specs, documentation becomes stale.

---

### Scenario 5: Q&A Without Grounding

**What happened:**
- Agent DID use apple-docs-fetcher liberally (✅ good)
- ios-sprint-executor has no Q&A/guidance mode

**User complaint confirmed:**
> "I want to use the skill for general guidance and question and answering about apple APIs, swift, viability of implementation of ideas or features I have in mind and liberally invoke the apple-docs-fetcher to ground their responses."

**Root cause:**
- Skill is purely sprint execution focused (6 phases)
- No "Mode 2: Q&A & Guidance" in skill structure
- No instruction to ground all iOS/Swift answers in fetched docs

**Impact:** Skill is single-purpose (sprint execution only), not useful for general iOS development guidance.

---

## Pattern Analysis

### Missing Phases

Current skill phases:
1. Pre-Sprint Setup
2. Planning
3. Gate 1 (Approval)
4. Execution
5. Code Review
6. PR Creation
7. Completion

**Missing phases:**
- **Phase 1.5**: UI/UX Review & Brainstorming
- **Phase 4.5**: Code Review with Apple Docs Verification
- **Phase 5.5**: Spec Drift Detection & Sync
- **Phase 6.5**: Device Build & Deploy

### Missing Modes

Current: Single mode (sprint execution)

**Missing modes:**
- **Mode 1**: Sprint Execution (current)
- **Mode 2**: Q&A & Guidance (new)
- **Mode 3**: Exploratory UI/UX Iteration (new)

### Deprecated References

- Line 91: `apple-docs-fetcher` → Should be `apple-docs-fetcher`
- Phase 1 (lines 89-137): Lite version → Full version

### Missing Integrations

- ❌ `superpowers:brainstorm` for UI/UX refinement
- ❌ `verified-stage-development` for spec sync
- ❌ `apple-docs-fetcher` during code review
- ❌ Xcode build settings reference

### Missing Knowledge Bases

- Swift 6.0 strict concurrency settings
- iOS 18 deployment best practices
- xcodebuild device deployment commands
- Code signing troubleshooting playbook

---

## GREEN Phase Requirements

Minimal changes to address failures:

1. **Replace apple-docs-fetcher with apple-docs-fetcher** (all references)
2. **Add Phase 4.5: Code Review with Apple Docs** (fetch docs for code being reviewed)
3. **Add Phase 1.5: UI/UX Brainstorming** (invoke superpowers:brainstorm when gaps identified)
4. **Add Phase 5.5: Spec Drift Sync** (invoke verified-stage-development before PR)
5. **Add Phase 6.5: Device Build & Deploy** (xcodebuild with best settings)
6. **Add Mode 2: Q&A & Guidance** (ground all iOS/Swift answers in apple-docs-fetcher)

---

## Next: GREEN Phase

Write minimal skill changes addressing these 6 requirements.
