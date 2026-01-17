# Plan: Restore Claude Plugins and Commands
**Date:** 2026-01-17
**Author:** Claude
**Priority:** P0 - Critical (breaks entire workflow)

## Problem Statement

All Claude plugins and commands have changed or disappeared:
- Axiom plugin is gone
- Firebase plugin is gone  
- All skills are now prefixed with `/project:` instead of normal names
- This breaks critical workflows like `ios-superpowers` which depends on these plugins

## Investigation Results

### Current State
1. **Directory Structure** - VERIFIED:
   - `.claude/` directory exists with proper structure
   - Commands exist in `.claude/commands/` including `ios-superpowers.md`
   - Skills exist in `.claude/skills/` including required dependencies
   - Plugins directory exists but is empty except for README

2. **Settings Configuration** - VERIFIED:
   - `.claude/settings.json` has plugins enabled:
     - `superpowers@superpowers-marketplace`: true
     - `axiom@axiom-marketplace`: true
   - Extra marketplace configured for superpowers

3. **Claude Code Version**: 1.0.3

### Root Cause Analysis

The issue appears to be that Claude Code is not loading the marketplace plugins properly. The `/project:` prefix suggests Claude is only recognizing local project commands/skills and not loading the marketplace plugins.

## Solution Plan

### Phase 1: Immediate Recovery (15 minutes)

1. **Reinstall Marketplace Plugins**
   ```bash
   # Remove and reinstall superpowers plugin
   rm -rf ~/.config/claude/plugins/superpowers@superpowers-marketplace
   claude plugin install superpowers@superpowers-marketplace
   
   # Remove and reinstall axiom plugin  
   rm -rf ~/.config/claude/plugins/axiom@axiom-marketplace
   claude plugin install axiom@axiom-marketplace
   ```

2. **Restart Claude Code**
   ```bash
   # Kill any running Claude processes
   pkill -f claude
   
   # Start fresh session
   claude
   ```

3. **Verify Plugin Loading**
   ```bash
   # List available plugins
   claude plugin list
   
   # List available commands
   claude command list
   ```

### Phase 2: Local Workaround (30 minutes)

If Phase 1 fails, implement local plugin copies:

1. **Create Local Plugin Definitions**
   ```bash
   # Create local axiom plugin
   mkdir -p .claude/plugins/axiom
   cat > .claude/plugins/axiom/plugin.json << 'EOF'
   {
     "name": "axiom",
     "version": "1.0.0",
     "description": "Local copy of Axiom plugin",
     "skills": [
       "systematic-debugging",
       "test-driven-development",
       "requesting-code-review"
     ]
   }
   EOF
   ```

2. **Copy Skill Definitions**
   - Download skill definitions from marketplace repos
   - Place in `.claude/skills/` with proper structure
   - Update references in commands

3. **Update Settings**
   ```json
   {
     "enabledPlugins": {
       "axiom": true,
       "superpowers": true
     }
   }
   ```

### Phase 3: Permanent Fix (45 minutes)

1. **Create Plugin Bootstrap Script**
   ```bash
   #!/bin/bash
   # .claude/scripts/bootstrap-plugins.sh
   
   # Install required plugins
   claude plugin install superpowers@superpowers-marketplace
   claude plugin install axiom@axiom-marketplace
   
   # Verify installation
   claude plugin list | grep -E "(superpowers|axiom)"
   
   # Test critical commands
   claude /ios-superpowers --help
   ```

2. **Add to Repository Setup**
   - Update `scripts/bootstrap-repository.sh` to include plugin setup
   - Document in `CLAUDE.md`
   - Add to `.claude/README.md`

3. **Create Fallback Mechanism**
   - Implement local skill definitions that mirror marketplace skills
   - Add detection logic in commands to use local or marketplace skills
   - Ensure graceful degradation

## Implementation Steps

### Step 1: Diagnose Current State
```bash
# Check Claude's view of plugins
ls ~/.config/claude/plugins/

# Check if marketplace connection works
curl -s https://api.marketplace.claude.ai/status

# Look for error logs
tail -n 100 ~/.config/claude/logs/claude.log | grep -i "plugin\|error"
```

### Step 2: Apply Immediate Fix
1. Run Phase 1 recovery steps
2. Test critical commands:
   ```bash
   /ios-superpowers brainstorm test
   /axiom debug test
   /firebase-superpowers deploy test
   ```

### Step 3: Implement Workaround if Needed
1. If plugins still not loading, implement Phase 2 local workaround
2. Test all critical workflows
3. Document temporary solution

### Step 4: Create Permanent Solution
1. Implement Phase 3 permanent fix
2. Test on fresh environment
3. Update documentation

## Success Criteria

- [ ] `axiom` plugin commands work without `/project:` prefix
- [ ] `superpowers` plugin commands work without `/project:` prefix  
- [ ] `ios-superpowers` command executes successfully
- [ ] All workflows from CLAUDE.md function correctly
- [ ] Solution survives Claude Code restart
- [ ] Solution documented for team

## Risk Mitigation

1. **Backup Current State**
   ```bash
   tar -czf claude-backup-$(date +%Y%m%d-%H%M%S).tar.gz .claude/
   ```

2. **Test in Isolation**
   - Test fixes in separate directory first
   - Verify no breaking changes to existing workflows

3. **Rollback Plan**
   - Keep backup of working configuration
   - Document steps to restore from backup

## Timeline

- **0-15 min**: Diagnose and attempt Phase 1 fix
- **15-45 min**: Implement Phase 2 workaround if needed
- **45-90 min**: Implement Phase 3 permanent solution
- **90-120 min**: Documentation and testing

## Next Actions

1. Start with diagnostic commands in Step 1
2. Report findings before proceeding with fixes
3. Implement solutions incrementally with testing between each phase