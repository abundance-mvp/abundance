# DEVELOPMENT-WORKFLOW-001: Git Branching Strategy

## Branch Structure

```
main (protected)
├── feature/sprint-1-project-setup
├── feature/sprint-2-camera-layer-1
├── feature/sprint-3-backend-ai-triggers
├── feature/sprint-4-ai-layer-2a
├── feature/sprint-5-ai-layers-2b-3
├── feature/sprint-6-catalog-view
├── feature/sprint-7-item-detail-onboarding
└── feature/sprint-8-testing-testflight
```

## Workflow

### 1. Create Feature Branch
```bash
git checkout -b feature/sprint-X-description
```

### 2. Or Use Worktree (Recommended)
```bash
git worktree add ../abundance-sprint-X -b feature/sprint-X-description
cd ../abundance-sprint-X
```

**Why worktrees?**
- Isolates each sprint in separate workspace
- No context switching overhead (`git checkout` switches entire directory)
- Parallel sprint work possible (work on Sprint 2 while Sprint 1 PR is in review)
- Clean separation of concerns

### 3. Implement Sprint Tasks
Follow TDD workflow via Superpowers:
- Test first, watch fail, implement, watch pass
- Commit frequently with proper messages

### 4. Create Pull Request
```bash
gh pr create --title "Sprint X: Description" --body "$(cat .github/PULL_REQUEST_TEMPLATE/sprint.md)"
```

### 5. Merge via GitHub
- Use "Squash and merge" strategy
- Delete branch after merge

### 6. Cleanup Worktree
```bash
cd /path/to/main/repo
git worktree remove ../abundance-sprint-X
git branch -d feature/sprint-X-description
```

---

## Commit Message Format

```
<type>(scope): <description>

[optional body]

[optional footer]
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **refactor**: Code restructuring without behavior change
- **test**: Adding or updating tests
- **docs**: Documentation only changes
- **chore**: Build process, tooling, dependencies

### Scopes
- **ios**: iOS application code
- **backend**: Backend/Cloud Functions code
- **ai-pipeline**: AI pipeline implementation
- **auth**: Authentication features
- **camera**: Camera capture features
- **catalog**: Catalog browsing features
- **vision**: Vision Framework integration
- **workflow**: Development workflow documentation

### Description Rules
- Use imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at end
- Maximum 50 characters

### Examples

```bash
# Good
feat(auth): implement Apple Sign-In with Firebase integration
fix(camera): resolve AVCaptureSession memory leak
test(catalog): add CatalogViewModelTests for search functionality
refactor(vision): extract barcode detection into separate service
docs(workflow): add git branching strategy guide

# Bad
feat: Added authentication ❌ (vague scope, wrong tense, capitalized)
Fixed bug ❌ (no scope, vague description)
camera stuff ❌ (no type, vague)
```

---

## Branch Protection Rules (main)

Configure on GitHub repository settings:

- [x] Require pull request before merging
  - Require approvals: 1+ (for human review)
  - Dismiss stale reviews when new commits pushed
- [x] Require status checks to pass before merging
  - iOS build check
  - Backend build check
  - SwiftLint validation
  - Spec validation
- [x] Require branches to be up to date before merging
- [x] No force pushes allowed
- [x] No branch deletions allowed
- [ ] Require signed commits (optional, for enterprise)

---

## Sprint Branch Lifecycle

### Duration
1 sprint (delete immediately after merge)

### Naming Convention
`feature/sprint-<number>-<short-description>`

Examples:
- `feature/sprint-1-project-setup`
- `feature/sprint-2-camera-layer-1`
- `feature/sprint-3-backend-ai-triggers`

### Isolation Strategy
**Prefer git worktrees over `git checkout`**

**Anti-pattern** (context switching):
```bash
git checkout feature/sprint-2  # Entire directory changes
# All files switch, IDE reindexes, loss of context
```

**Recommended** (parallel workspaces):
```bash
git worktree add ../abundance-sprint-2 -b feature/sprint-2-camera-layer-1
cd ../abundance-sprint-2
# Original workspace untouched, work in parallel
```

---

## Example: Parallel Sprint Work

**Scenario**: Sprint 1 PR is under review, start Sprint 2 in parallel

```bash
# Sprint 1 worktree (under review)
cd /Users/w/code/abundance-sprint-1
ls  # Sprint 1 work, PR created, waiting for approval

# Return to main repo
cd /Users/w/code/spec-kit

# Start Sprint 2 in parallel
git worktree add ../abundance-sprint-2 -b feature/sprint-2-camera-layer-1
cd ../abundance-sprint-2

# Now have 2 isolated workspaces:
# 1. abundance-sprint-1 (frozen, under review)
# 2. abundance-sprint-2 (active development)

# After Sprint 1 PR merged
cd /Users/w/code/spec-kit
git worktree remove ../abundance-sprint-1
git branch -d feature/sprint-1-project-setup
git pull origin main  # Get Sprint 1 changes
```

**Benefits**:
- No waiting for PR approval to start next sprint
- No risk of mixing Sprint 1 and Sprint 2 code
- Clean context for each sprint
- Easy to switch between sprints if needed

---

## Git Worktree Commands Reference

### Create worktree
```bash
git worktree add <path> -b <branch-name>
```

### List all worktrees
```bash
git worktree list
```

### Remove worktree
```bash
git worktree remove <path>
```

### Prune stale worktrees
```bash
git worktree prune
```

---

## Troubleshooting

### "Branch already exists"
```bash
# If branch exists but no worktree:
git worktree add ../abundance-sprint-X feature/sprint-X-existing-branch

# If you want to create new branch with different name:
git worktree add ../abundance-sprint-X -b feature/sprint-X-new-name
```

### "Worktree path already exists"
```bash
# Remove old worktree first:
rm -rf ../abundance-sprint-X
git worktree prune

# Then create new one:
git worktree add ../abundance-sprint-X -b feature/sprint-X-branch
```

### "Cannot create worktree from dirty working tree"
```bash
# Commit or stash changes first:
git add .
git commit -m "wip: save current work"
# OR
git stash

# Then create worktree
```

---

## References

- ios-sprint-executor skill (Phase 1, Step 6-7)
- Superpowers: using-git-worktrees skill
- Git Worktrees documentation: https://git-scm.com/docs/git-worktree
