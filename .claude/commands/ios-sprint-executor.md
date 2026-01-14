Orchestrate iOS sprint development with superpowers integration, Apple docs fetching, and quality gates.

Invoke the Skill tool with skill="ios-sprint-executor" to dispatch a specialized iOS development agent that will:

1. Load sprint plan and context from docs/roadmap/SPRINT-PLAN-{N}.md
2. Fetch relevant Apple documentation via apple-docs-fetcher skill (if iOS work detected)
3. Create implementation plan via `/superpowers:write-plan`
4. Get your approval before proceeding (Gate 1)
5. Execute plan via `/superpowers:execute-plan` with quality checkpoints
6. Run code review via superpowers:requesting-code-review
7. Create pull request with comprehensive documentation cross-references

Sprint: $ARGUMENTS

If no arguments provided, show available sprints from docs/roadmap/ROADMAP-001-mvp-implementation-timeline.md.

Examples:

- `/ios-sprint-executor sprint-1` - Execute Sprint 1 (iOS Project Setup & Authentication)
- `/ios-sprint-executor sprint-2` - Execute Sprint 2 (Camera Capture & Vision Layer 1)
- `/ios-sprint-executor sprint-3` - Execute Sprint 3 (Backend AI Pipeline)
