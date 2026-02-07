---
name: review-commit
description: Route code review agents to the correct skill (ios-superpowers, backend-superpowers, gemini-integration) based on changed files in the current commit or working tree.
---

# Review Commit Command

Automatically classifies changed files by domain, then dispatches parallel code review agents routed to the appropriate skill.

## Usage

```
/review-commit                    # Review uncommitted changes (git diff HEAD)
/review-commit <commit-sha>       # Review a specific commit
/review-commit <branch>           # Review all changes on a branch vs main
```

## How It Works

### Step 1: Collect Changed Files

```bash
# Uncommitted changes
git diff --name-only HEAD

# Specific commit
git diff --name-only <sha>^..<sha>

# Branch vs main
git diff --name-only main...<branch>
```

### Step 2: Classify Files by Domain

Apply these rules in order. Each file goes into exactly ONE domain bucket:

| Domain | File Pattern | Skill | Review Focus |
|--------|-------------|-------|-------------|
| **ios** | `Sources/**/*.swift`, `App/**/*.swift`, `Tests/**/*.swift`, `Package.swift` | `ios-superpowers` | Swift 6 concurrency, ADR-010 (no UIKit in views), @Observable patterns, accessibility |
| **gemini** | `functions/src/ai-pipeline/**/*.ts` | `gemini-integration` | Thought signatures, tool calling, JSON parsing, token limits, prompt safety |
| **backend** | `functions/src/**/*.ts` (NOT ai-pipeline), `functions/package.json`, `functions/tsconfig.json`, `firestore.rules`, `storage.rules`, `firebase.json` | `backend-superpowers` | Firestore transactions, security rules, error handling, idempotency |
| **infra** | `.github/**`, `scripts/**`, `.claude/**`, `docs/**` | (no skill needed) | Standard review, no specialized agent |

**Priority rule:** `gemini` is a subset of `functions/src/` — files under `functions/src/ai-pipeline/` go to `gemini`, all other `functions/src/` files go to `backend`.

### Step 3: Load Skills for Context

For each non-empty domain bucket, load the corresponding skill:

```
# iOS domain detected
Skill(skill="ios-superpowers", args="review")

# Backend domain detected
Skill(skill="backend-superpowers")

# Gemini domain detected
Skill(skill="gemini-integration")
```

### Step 4: Dispatch Parallel Review Agents

Launch one `superpowers:code-reviewer` Task agent per domain, **all in parallel**:

```
Task(
  description: "<Domain> code review",
  subagent_type: "superpowers:code-reviewer",
  prompt: """
  Review the <domain> changes in this commit.

  ## Context
  <summary of what changed and why>

  ## Files to Review (<domain> only)
  <list of files in this domain bucket>

  ## Architecture Constraints
  <domain-specific constraints from skill>

  ## Review Checklist
  <domain-specific checklist>

  Read the git diff for these files and provide a thorough code review.
  """
)
```

### Step 5: Synthesize Results

After all agents return, produce a unified summary:

```markdown
## Code Review Summary

### iOS (N files) — via ios-superpowers
- Critical: ...
- Important: ...
- Suggestions: ...

### Backend (N files) — via backend-superpowers
- Critical: ...
- Important: ...
- Suggestions: ...

### Gemini Pipeline (N files) — via gemini-integration
- Critical: ...
- Important: ...
- Suggestions: ...

### Overall Verdict
[PASS / PASS WITH NOTES / NEEDS FIXES]
```

---

## Domain-Specific Review Checklists

### iOS Checklist
1. Swift 6 strict concurrency — no data races, proper actor isolation
2. ADR-010 — no `import UIKit` in Views/ViewModels (Services OK)
3. @Observable patterns — not ObservableObject (iOS 17+)
4. Accessibility — labels, traits, 44pt touch targets, Dynamic Type
5. Memory — no retain cycles in closures, proper `[weak self]`
6. SwiftUI performance — no expensive work in view bodies

### Backend Checklist
1. Firestore transactions — atomic reads+writes, no race conditions
2. Security — no user input in queries without validation, proper auth checks
3. Error handling — all async paths have catch blocks, proper error propagation
4. Idempotency — triggers safe to fire multiple times
5. FieldValue.serverTimestamp() — used for all timestamp fields
6. Test coverage — new logic paths have unit tests

### Gemini Checklist
1. Thought signatures — preserved in multi-turn tool calling
2. JSON parsing — handles truncated/malformed Gemini output
3. Token limits — maxOutputTokens appropriate for response size
4. Rate limiting — backoff with jitter for 429 errors
5. Cost — model selection (Flash vs Pro) appropriate for task
6. Tool definitions — schema matches expected response format

---

## Examples

### Review current uncommitted work
```
/review-commit
```
Output: Classifies 15 changed files into 3 domains, dispatches 3 parallel review agents.

### Review a specific commit
```
/review-commit 5bdedef
```

### Review a feature branch
```
/review-commit feature/camera-fix
```

---

## Error Handling

- **No changed files** — Report "nothing to review" and exit
- **Single domain** — Only dispatch one agent (skip parallel)
- **Infra-only changes** — Standard review without specialized skill, no agent dispatch
- **Agent failure** — Report which domain failed, continue with others
