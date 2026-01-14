Orchestrate iOS sprint development with superpowers integration, Apple docs fetching, and quality gates.

Invoke the Skill tool with skill="ios-sprint-executor" to dispatch a specialized iOS development agent that will:

1. Load sprint plan and context from docs/roadmap/SPRINT-PLAN-{N}.md
2. Detect iOS frameworks and fetch Apple documentation via apple-docs-fetcher
3. **Create implementation plan** via `/ios-superpowers plan` (ensures Apple docs grounding)
4. Get your approval before proceeding (Gate 1)
5. **Execute plan** via `/ios-superpowers execute` with quality checkpoints
6. **Run code review** via `/ios-superpowers review`
7. Create pull request with comprehensive documentation cross-references

**Note:** This skill uses ios-superpowers orchestrator for all superpowers interactions, ensuring Apple documentation is verified at every step.

Sprint: $ARGUMENTS

If no arguments provided, show available sprints from docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md.

Examples:

- `/ios-sprint-executor sprint-1` - Execute Sprint 1 (iOS Project Setup & Authentication)
- `/ios-sprint-executor sprint-2` - Execute Sprint 2 (Camera Capture & Vision Layer 1)
- `/ios-sprint-executor sprint-3` - Execute Sprint 3 (Backend AI Pipeline)
