Display current sprint progress and remaining tasks.

This command analyzes sprint plan and git branch status to show completion:

1. Detects current sprint from active git branch (e.g., `feature/sprint-2-camera-layer-1`)
2. Loads sprint plan from docs/roadmap/SPRINT-PLAN-{N}.md
3. Checks git commit history for completed tasks
4. Displays progress with task status

Usage:
```
/show-sprint-status
```

When this command runs, Claude will:
- Run: `git branch --show-current` to detect active sprint
- Load: `docs/roadmap/SPRINT-PLAN-{N}.md` (parsed from branch name)
- Check: `git log --oneline` for task completion markers
- Display: Formatted progress report

Expected output:
```
Sprint 2: Camera Capture & Vision Layer 1
Progress: 75% (6/8 tasks complete)

✅ Task 1: CameraView UI (commit: a3b2c1d)
✅ Task 2: CameraViewModel (commit: b4c3d2e)
✅ Task 3: VisionService (commit: c5d4e3f)
✅ Task 4: Barcode detection (commit: d6e5f4g)
⏳ Task 5: Unit tests (in progress, branch: feature/sprint-2-tests)
⏳ Task 6: Integration tests (pending)
⏳ Task 7: SwiftLint fixes (pending)
⏳ Task 8: PR creation (pending)

Current branch: feature/sprint-2-camera-layer-1
Commits this sprint: 12
Files changed: 18

Next steps:
1. Complete Task 5 (unit tests)
2. Run Task 6 (integration tests)
3. Fix any SwiftLint warnings (Task 7)
4. Create PR for review (Task 8)
```

Task Completion Detection:
Claude looks for commit messages matching patterns:
- `feat(task-1): ...` or `Task 1: ...` → Task 1 complete
- `test(task-5): ...` → Task 5 complete

Sprint Plan Format:
Sprint plans should list tasks as:
```markdown
### Task 1: Component Name
**Status**: Pending | In Progress | Complete
```

If no active sprint branch detected:
```
No active sprint detected.

Available sprints:
1. Sprint 1: Project Scaffolding
2. Sprint 2: Camera Capture & Vision Layer 1
3. Sprint 3: AI Pipeline Integration

To start a sprint:
1. Create branch: git checkout -b feature/sprint-N-name
2. Load sprint plan: docs/roadmap/SPRINT-PLAN-N.md
3. Begin tasks following DEVELOPMENT-WORKFLOW-003.md
```
