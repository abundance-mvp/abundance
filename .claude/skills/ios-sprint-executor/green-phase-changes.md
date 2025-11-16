# iOS Sprint Executor - GREEN Phase Changes

## Summary

Made 6 minimal changes to address all baseline failures identified in RED phase.

---

## Changes Made

### 1. Updated YAML Frontmatter & Description

**Before:**
```yaml
description: Executes sprint tasks with superpowers integration and automatic apple-docs-fetcher for iOS work
```

**After:**
```yaml
description: Use when executing iOS sprints, reviewing iOS code with latest APIs, building apps on device, identifying UI/UX gaps with brainstorming, preventing spec drift, or answering iOS/Swift questions - orchestrates superpowers workflow with apple-docs-fetcher grounding for all iOS work
```

**Impact:** CSO (Claude Search Optimization) improved - description now includes triggering conditions for all use cases.

---

### 2. Replaced apple-docs-fetcher-lite with apple-docs-fetcher

**Before (Line 91):**
```markdown
Use apple-docs-fetcher-lite pattern (NOT full apple-docs-fetcher)
```

**After (Line 103):**
```markdown
Use apple-docs-fetcher skill (Skill tool with skill: "apple-docs-fetcher")
```

**Impact:** Uses non-deprecated skill, benefits from latest documentation fetching capabilities.

---

### 3. Added Phase 1.5: UI/UX Review & Brainstorming

**Location:** Lines 189-260 (after Phase 1, before Phase 2)

**Purpose:** Identify UI/UX gaps and refine through Socratic brainstorming before planning

**Key steps:**
1. Review sprint plan for UI/UX requirements
2. Compare with existing implementation
3. Identify gaps (loading states, error states, animations, accessibility, etc.)
4. **Invoke superpowers:brainstorm if gaps identified**
5. Update sprint plan with agreed changes

**Addresses baseline failure:** Scenario 3 - agents now proactively brainstorm UI/UX improvements instead of just listing gaps.

---

### 4. Added Phase 4.5: Apple Docs Verification for Code Review

**Location:** Lines 584-661 (after Phase 4, before Phase 5)

**Purpose:** Verify iOS code uses latest Apple APIs correctly by fetching current documentation

**Key steps:**
1. Detect iOS framework usage (SwiftUI, Vision, AVFoundation, etc.)
2. Extract APIs used (@Observable, .containerRelativeFrame(), etc.)
3. **Invoke apple-docs-fetcher for each API**
4. Compare code against fetched docs
5. Report findings (correct usage, deprecations, best practices)
6. Fix issues if found

**Addresses baseline failure:** Scenario 1 - code review now fetches Apple docs to verify latest APIs instead of assuming correctness.

---

### 5. Added Phase 5: Spec Drift Detection & Sync

**Location:** Lines 664-725 (renumbered from old Phase 5, added drift detection)

**Purpose:** Detect and prevent spec drift by syncing implementation with design docs

**Key steps:**
1. Compare implementation with DESIGN docs
2. Identify drift (naming, architecture, missing features)
3. **Invoke verified-stage-development if drift detected**
4. Verify no drift remains
5. Display summary

**Addresses baseline failure:** Scenario 4 - spec drift is now automatically detected and synced before PR creation.

---

### 6. Added Phase 6.5: Device Build & Deploy

**Location:** Lines 890-1056 (after Phase 6, before Mode 2)

**Purpose:** Build and install iOS app on physical device via CLI with best settings

**Key steps:**
1. Detect connected iOS devices
2. Verify device info
3. **Apply best Xcode build settings for Swift 6.0/iOS 18**
4. Build for device with xcodebuild
5. Create archive
6. Export .ipa
7. Install on device
8. **Troubleshoot common issues** (code signing, provisioning, etc.)

**Addresses baseline failure:** Scenario 2 - agents can now build and deploy to devices via CLI with comprehensive troubleshooting.

---

### 7. Added Mode 2: Q&A & Guidance

**Location:** Lines 1060-1126 (before Error Handling section)

**Purpose:** Answer iOS/Swift questions with Apple documentation grounding

**Key steps:**
1. Detect iOS/Swift question
2. **Invoke apple-docs-fetcher for grounding**
3. Answer with grounded response (code examples, API signatures, availability)
4. **Never answer from training data alone**

**Red flags section:** Explicit warnings about rationalizations:
- "I know this from training data"
- "This is straightforward"
- "Fetching docs takes time"

**Addresses baseline failure:** Scenario 5 - skill now has dedicated Q&A mode that mandates documentation grounding.

---

## Updated Phase Flow

### Mode 1: Sprint Execution

1. Phase 1: Pre-Sprint Setup
2. **Phase 1.5: UI/UX Review & Brainstorming** ← NEW
3. Phase 2: Planning with Superpowers
4. GATE 1: Human Approval
5. Phase 3: Execution with Superpowers
6. Phase 4: Code Review
7. **Phase 4.5: Apple Docs Verification** ← NEW
8. **Phase 5: Spec Drift Detection & Sync** ← NEW (renamed from PR Creation)
9. Phase 5.5: PR Creation (renumbered)
10. Phase 6: Completion & Cleanup
11. **Phase 6.5: Device Build & Deploy** ← NEW (optional)

### Mode 2: Q&A & Guidance ← NEW

- Triggered by iOS/Swift questions
- Mandatory apple-docs-fetcher grounding
- Red flags for rationalization prevention

---

## Next: GREEN Phase Verification

Run all 5 baseline scenarios WITH the improved skill to verify:

1. ✅ Scenario 1: Code review fetches Apple docs
2. ✅ Scenario 2: Device build uses CLI with best settings
3. ✅ Scenario 3: UI/UX gaps trigger brainstorming
4. ✅ Scenario 4: Spec drift triggers verified-stage-development
5. ✅ Scenario 5: Q&A mode uses apple-docs-fetcher grounding

Expected: All scenarios PASS (agents comply with new phases).
