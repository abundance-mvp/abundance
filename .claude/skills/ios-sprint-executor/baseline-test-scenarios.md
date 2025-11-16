# iOS Sprint Executor - Baseline Test Scenarios

## Purpose
Test current skill behavior to identify failures before improvements.

## Scenario 1: Code Review Without Apple Docs Fetching

**Setup:**
- Sprint 6 implementation complete
- Code uses latest Swift 6.0 features (@Observable, @MainActor strict concurrency)
- Code uses latest SwiftUI features (new animation APIs, containerRelativeFrame)
- Current skill references apple-docs-fetcher-lite (deprecated)

**Pressure:**
- Time pressure: "Quick code review needed before PR"
- Authority: "The code works, just need to validate"
- Sunk cost: "Already spent 3 hours implementing"

**Test:**
Ask agent to perform code review using ios-sprint-executor skill.

**Expected FAILURE (baseline):**
- Agent doesn't fetch Apple docs during review
- Agent uses deprecated apple-docs-fetcher-lite
- Agent makes assumptions about Swift 6.0/SwiftUI APIs without verification
- Agent rationalizes: "Code compiles, so APIs must be correct"

---

## Scenario 2: Building iOS App on Device

**Setup:**
- iOS app needs to be built and installed on physical iPhone
- Agent has access to xcodebuild CLI
- Best practices: Code signing, provisioning profiles, build settings

**Pressure:**
- Complexity: "I don't want to use Xcode GUI"
- Authority: "You should know how to do this via CLI"
- Exhaustion: "I've been debugging this for hours"

**Test:**
Ask agent: "Build and install the iOS app on my iPhone using CLI only, no Xcode GUI"

**Expected FAILURE (baseline):**
- Agent suggests opening Xcode
- Agent doesn't know best xcodebuild settings
- Agent doesn't troubleshoot code signing automatically
- Agent rationalizes: "Xcode GUI is easier for device deployment"

---

## Scenario 3: Missing UI/UX Features - No Brainstorming

**Setup:**
- Sprint implementation complete
- UI works but lacks polish (animations, haptics, accessibility, error states)
- User hasn't explicitly requested improvements

**Pressure:**
- Time: "Sprint is done, let's move on"
- Sunk cost: "Already implemented what was planned"
- Authority: "Requirements were met"

**Test:**
Ask agent to review sprint completion and prepare for next sprint.

**Expected FAILURE (baseline):**
- Agent doesn't identify missing UI/UX features
- Agent doesn't proactively suggest brainstorming session
- Agent doesn't use superpowers:brainstorm skill
- Agent rationalizes: "Sprint requirements are complete, no need to brainstorm improvements"

---

## Scenario 4: Spec Drift - No Verification

**Setup:**
- Sprint implementation modified design during development
- Implementation diverged from original DESIGN docs
- verified-stage-development skill available for spec updates

**Pressure:**
- Time: "PR is ready, let's merge"
- Sunk cost: "Implementation works well"
- Authority: "Changes were necessary for technical reasons"

**Test:**
Ask agent to complete sprint and create PR.

**Expected FAILURE (baseline):**
- Agent doesn't invoke verified-stage-development
- Agent doesn't update DESIGN docs to match implementation
- Agent doesn't identify spec drift
- Agent rationalizes: "Implementation works, updating docs can happen later"

---

## Scenario 5: Q&A Without Grounding

**Setup:**
- User asks: "Can I use Swift's new typed throws feature with async sequences?"
- apple-docs-fetcher available with latest Swift docs
- User wants accurate, grounded answer

**Pressure:**
- Confidence: "I know this from training data"
- Efficiency: "Fetching docs takes time"
- Authority: "This is a simple question"

**Test:**
Ask: "Can I use Swift's new typed throws feature with async sequences? Show me examples."

**Expected FAILURE (baseline):**
- Agent answers from training data without fetching docs
- Agent doesn't use apple-docs-fetcher to verify
- Agent doesn't provide latest API examples from docs
- Agent rationalizes: "This is straightforward, no need to fetch docs"

---

## Baseline Test Instructions

For each scenario:

1. **Dispatch subagent** with CURRENT skill (no improvements)
2. **Apply all pressures** in scenario
3. **Document verbatim**:
   - What agent does
   - What agent says (exact quotes)
   - What rationalizations agent uses
   - What agent DOESN'T do (missing behaviors)
4. **Identify patterns** across scenarios

Expected outcome: Subagent fails all 5 scenarios in predictable ways.

---

## Success Criteria for Improved Skill

After improvements, agent should:

1. **Scenario 1**: Use apple-docs-fetcher (not lite) during code review, verify latest APIs
2. **Scenario 2**: Use xcodebuild CLI with best settings, troubleshoot automatically
3. **Scenario 3**: Identify UI/UX gaps, invoke superpowers:brainstorm proactively
4. **Scenario 4**: Invoke verified-stage-development to prevent spec drift
5. **Scenario 5**: Liberally use apple-docs-fetcher to ground all iOS/Swift Q&A
