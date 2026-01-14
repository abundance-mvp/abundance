Orchestrate stage development with research verification, planning, execution, and approval gates.

Invoke the Skill tool with skill="verified-stage-development" to dispatch a stage orchestration agent that will:
1. Load required context from docs/context-map.json for the specified stage
2. Research & verify technical claims (creates RESEARCH-VALIDATION-stage-X.Y.md)
3. **For iOS stages**: Use `/ios-superpowers plan` for implementation planning
4. **For non-iOS stages**: Use `/superpowers:write-plan`
5. Gate 1: Get your approval before execution
6. **For iOS stages**: Use `/ios-superpowers execute` for plan execution
7. **For non-iOS stages**: Use `/superpowers:execute-plan` with batch review
8. Gate 2: Generate checkpoint and validate against master documents

**iOS stages** (require ios-superpowers): 2.2, 3.1, 4.1, and any stage touching Swift code

Stage: $ARGUMENTS

Examples:
- `/verified-stage-development stage-2.2` - Execute Stage 2.2 (iOS Client Architecture)
- `/verified-stage-development stage-3.1` - Execute Stage 3.1 (iOS Implementation Research)
- `/verified-stage-development stage-5.3` - Execute Stage 5.3 (CI/CD & Automation)

See docs/context-map.json for available stages and their status.
