# DEVELOPMENT-WORKFLOW-002: PR Creation & Automation

## PR Template Structure

Every sprint PR follows a standardized template to ensure consistency and completeness.

**Template location**: `.github/PULL_REQUEST_TEMPLATE/sprint.md`

**Usage**: When creating a PR for sprint work, GitHub automatically populates the PR description with the template.

---

## Template Sections

### 1. Sprint Reference
Links to the sprint plan that defines the work.

### 2. Documentation Cross-References
Links to all technical artifacts used during implementation:
- ADRs (architecture decisions)
- Design docs (technical specifications)
- Code examples (implementation patterns)
- Test examples (testing approaches)

**Purpose**: Traceability from code back to specs.

### 3. Success Criteria Checklist
Acceptance criteria from the sprint plan, formatted as checkboxes.

**Purpose**: Verify all sprint objectives met before merge.

### 4. Testing Evidence
Screenshots or output showing:
- Unit test results (coverage, passing tests)
- Build validation (iOS build, SwiftLint clean)

**Purpose**: Evidence before assertions (verification-before-completion).

### 5. Agent Execution Summary
Metrics from Superpowers workflow:
- Planning tokens (from /superpowers:write-plan)
- Execution batches (from /superpowers:execute-plan)
- Code review result (from superpowers:requesting-code-review)
- Apple docs fetched (from apple-docs-fetcher-lite)

**Purpose**: Track AI-assisted development metrics.

---

## GitHub CLI PR Creation

### Basic Command
```bash
gh pr create --title "Sprint X: Description"
```

### With Template
```bash
gh pr create \
  --title "Sprint 2: Camera Capture & Vision Layer 1" \
  --body "$(cat .github/PULL_REQUEST_TEMPLATE/sprint.md)"
```

### With Labels
```bash
gh pr create \
  --title "Sprint 2: Camera Capture & Vision Layer 1" \
  --body "$(cat .github/PULL_REQUEST_TEMPLATE/sprint.md)" \
  --label "sprint-2,enhancement,ios,backend"
```

### Auto-fill from Commit
```bash
# If single commit, use commit message as title
gh pr create --fill

# Specify base branch (if not main)
gh pr create --base develop --title "Sprint X: Description"
```

---

## Automated Checks (CI/CD)

**GitHub Actions workflows** (configured in Stage 5.3):

### Required Status Checks
All checks must pass before PR can be merged:

1. **iOS Build Check**
   - Command: `cd ios && swift build`
   - Validates: iOS project compiles successfully

2. **iOS Tests**
   - Command: `cd ios && swift test`
   - Validates: All unit tests pass

3. **SwiftLint Validation**
   - Command: `cd ios && swiftlint lint --strict`
   - Validates: Code meets style guidelines (0 warnings)

4. **Backend Build**
   - Command: `cd backend/functions && npm run build`
   - Validates: TypeScript compiles without errors

5. **Backend Tests**
   - Command: `cd backend/functions && npm test`
   - Validates: All Cloud Functions tests pass

6. **Spec Validation** (optional)
   - Command: `./scripts/validate-specs.sh`
   - Validates: Documentation links valid, no broken cross-references

---

## PR Review Process

### 1. Create PR
Use template above to create PR with complete context.

### 2. Automated Checks Run
GitHub Actions execute all required status checks (5-10 minutes).

### 3. Code Review (Optional for AI Agent)
**Superpowers Integration**:
- ios-sprint-executor already runs `superpowers:requesting-code-review` in Phase 4
- Code review report attached to PR as comment
- If issues found, fix and push new commit

### 4. Human Approval
- 1+ approvals required (configured in branch protection)
- Reviewer verifies:
  - Success criteria met
  - Tests cover functionality
  - Code follows ADR patterns
  - No security issues

### 5. Merge
- **Strategy**: Squash and merge (keeps main branch clean)
- **Auto-delete**: Branch deleted automatically after merge

---

## PR Naming Conventions

### Format
```
Sprint X: [Short Description]
```

### Examples

**Good**:
```
Sprint 1: iOS Project Setup & Authentication
Sprint 2: Camera Capture & Vision Layer 1
Sprint 3: Backend AI Pipeline Triggers
Sprint 4: AI Layer 2a Attribute Extraction
Sprint 5: AI Layers 2b + 3 Product Search & Synthesis
Sprint 6: Catalog View & Search
Sprint 7: Item Detail, Onboarding & Profile
Sprint 8: Testing & TestFlight Launch
```

**Bad**:
```
Fix stuff ❌ (vague)
WIP camera feature ❌ (work-in-progress, not ready)
Updates ❌ (too generic)
Sprint 2 ❌ (missing description)
```

---

## PR Labels

### Standard Labels
- **sprint-X**: Identifies which sprint (e.g., `sprint-2`)
- **enhancement**: New feature work
- **bug**: Bug fix work
- **ios**: iOS-specific changes
- **backend**: Backend-specific changes
- **ai-pipeline**: AI pipeline changes
- **docs**: Documentation changes

### Priority Labels
- **P0**: Critical, blocks launch
- **P1**: High priority
- **P2**: Medium priority
- **P3**: Nice to have

### Example Labeling
```bash
gh pr create \
  --title "Sprint 2: Camera Capture & Vision Layer 1" \
  --label "sprint-2,enhancement,ios,P0"
```

---

## PR Size Guidelines

### Ideal PR Size
**Lines changed**: 200-500 (sweet spot for reviewability)

### Maximum PR Size
**Lines changed**: 1000 (larger PRs harder to review)

### If PR Too Large
**Split into sub-PRs**:
- Sprint 2.1: Camera UI
- Sprint 2.2: Vision Framework Integration
- Sprint 2.3: Barcode Detection

**Tag with**: `sprint-2` label so they're grouped

---

## PR Description Best Practices

### DO
- ✅ Link to sprint plan
- ✅ List all documentation cross-references
- ✅ Include test evidence (screenshots/output)
- ✅ Mark all success criteria checkboxes
- ✅ Add agent execution summary (tokens, batches)
- ✅ Note any deferred work with reason

### DON'T
- ❌ Leave template placeholders (e.g., "X%" → fill in actual %)
- ❌ Omit testing evidence
- ❌ Skip documentation cross-references
- ❌ Mark success criteria complete without verification

---

## Example PR Description (Completed)

```markdown
# Sprint 2: Camera Capture & Vision Layer 1

## Sprint Reference
- Sprint: 2 ([SPRINT-PLAN-002.md](../roadmap/SPRINT-PLAN-002.md))

## Documentation Cross-References

### ADRs
- [ADR-010: SwiftUI Architecture Pattern](../adr/ADR-010-swiftui-architecture-pattern.md) - MVVM pattern for camera views
- [ADR-011: iOS Module Structure](../adr/ADR-011-ios-module-structure.md) - CameraFeature module organization
- [ADR-013: Vision Framework Strategy](../adr/ADR-013-vision-framework-strategy.md) - On-device object detection

### Design Docs
- [DESIGN-027: Camera Capture View Specification](../design/DESIGN-027-camera-capture-view-specification.md) - UI layout, controls
- [DESIGN-039: Layer 1 Performance Optimization](../design/DESIGN-039-layer-1-performance-optimization.md) - Vision pipeline optimization

### Code Examples & Tests
- [CODE-EXAMPLE-004: Vision Framework Patterns](../design/CODE-EXAMPLE-004-vision-framework-patterns.md) - VNCoreMLRequest setup
- [CODE-EXAMPLE-009: Household Item Detector](../design/CODE-EXAMPLE-009-household-item-detector.md) - YOLO integration
- [TEST-EXAMPLE-004: ML/CV Testing Patterns](../test/TEST-EXAMPLE-004-ml-cv-testing-patterns.md) - Vision service unit tests

## Success Criteria Checklist
- [x] Camera preview displays in CameraView
- [x] Capture button saves photo to Firebase Storage
- [x] Vision Framework detects household items (> 60% accuracy on golden dataset)
- [x] Barcode detection identifies 24 symbologies (> 95% success rate)
- [x] Backend CRUD endpoints functional (POST/GET /api/v1/items)
- [x] All unit tests pass (87% coverage, exceeds 80% target)

## Testing Evidence

### Unit Tests
- Test coverage: 87% (target: 80%+)
- Tests passing: 24/24
- Screenshot: [iOS test output showing 24 passing tests]

### Build Validation
- iOS build: ✅ PASSING (`swift build` success)
- SwiftLint: ✅ PASSING (0 warnings)
- Screenshot: [Xcode build success]

### Accuracy Validation
- Layer 1 (household items): 67% on golden dataset (exceeds 60% target)
- Barcode detection: 98% success rate (exceeds 95% target)

## Agent Execution Summary
- Planning: superpowers:write-plan (18K tokens, 12 tasks, 3 batches)
- Execution: superpowers:execute-plan (3 batches, 2.5 hours)
- Code Review: superpowers:requesting-code-review (passed, 0 issues)
- Apple Docs: apple-docs-fetcher-lite (7.6K tokens, 4 APIs: AVCaptureSession, VNCoreMLRequest, VNDetectBarcodesRequest, Task.detached)

## Notes
- Deferred Firebase Storage upload optimization to Sprint 3 (not blocking for Layer 1)
- Used Task.detached for Vision requests per CODE-EXAMPLE-004 (avoids main thread blocking)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Troubleshooting

### "gh command not found"
```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login
```

### "Template not found"
```bash
# Verify template exists
ls .github/PULL_REQUEST_TEMPLATE/sprint.md

# If missing, create from docs/validation/DEVELOPMENT-WORKFLOW-002.md
```

### "PR already exists for branch"
```bash
# View existing PR
gh pr view

# Edit PR description
gh pr edit --body "$(cat .github/PULL_REQUEST_TEMPLATE/sprint.md)"
```

### "Status checks failing"
```bash
# View check details
gh pr checks

# Re-run failed checks (if transient failure)
gh pr checks --watch

# Fix locally and push
git push origin feature/sprint-X-branch
```

---

## References

- ios-sprint-executor skill (Phase 5, Step 3)
- GitHub CLI documentation: https://cli.github.com/manual/gh_pr_create
- Template location: `.github/PULL_REQUEST_TEMPLATE/sprint.md`
