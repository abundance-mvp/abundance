# RED Phase: Baseline Findings

## Test Scenario

User asks Claude to help capture a bug found during testing.

## Baseline Behavior (Without Skill)

### Current Approach
1. Claude runs `./scripts/capture-issue.sh`
2. Script prompts user interactively for details
3. Script creates raw issue markdown
4. Script spawns `claude enrich-issue` as subprocess
5. **FAILURE**: Subprocess cannot get file write approval (parent Claude owns terminal)
6. Warning shown, no enriched JSON created

### Evidence
- BUG-004 documents this failure pattern
- `.debug/enrichment.log` shows analysis completes but file write blocks

### Problems Without Skill

1. **Nested invocation failure**: Subprocess Claude can't get approval
2. **Context loss**: Script prompts are disconnected from Claude conversation
3. **No enrichment**: Enrichment requires manual follow-up command
4. **Poor UX**: User switches between Claude and bash prompts

## Desired Behavior

Single Claude skill that:
1. Gathers issue details conversationally
2. Creates raw issue file (in-session, has approval)
3. Immediately enriches (in-session, has approval)
4. Writes enriched JSON (in-session, has approval)
5. Reports summary to user

## Conclusion

Technique skill needed to replace bash script + subprocess pattern with unified in-session workflow.
