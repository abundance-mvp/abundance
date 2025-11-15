# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project scaffold with CI/CD and automation infrastructure
- GitHub Actions workflows (iOS, backend, AI pipeline, security, docs)
- Claude Code automation (hooks, agents, commands, plugins)
- PR and issue templates
- Setup scripts for developer onboarding
- Comprehensive documentation (tech-stack, development workflows)

## [0.1.0] - 2025-11-14

### Added
- **CI/CD Infrastructure**
  - iOS build check workflow with Swift 6.0, SwiftLint, parallel tests
  - Backend validation workflow with TypeScript, Firebase rules linting
  - AI pipeline validation with Python, Claude/Gemini API testing
  - Security PR review with OWASP scanning
  - Automated documentation updates
  - Claude Code CI debugging via @claude mentions

- **Claude Code Automation**
  - Bash command validator hook (blocks dangerous commands)
  - Pre-sprint validation hook
  - PR creation hook for template compliance
  - File edit hook for sensitive data detection
  - Doc-reviewer agent for link validation
  - Drift-detector agent for ADR compliance (P0/P1/P2 severity)
  - Cost-watchdog agent for budget monitoring
  - Slash commands: /validate-docs, /check-drift, /show-sprint-status

- **Developer Tooling**
  - Git hooks (pre-commit, pre-push) for linting and testing
  - Environment validation script
  - Claude Code hooks setup script
  - Plugin installation script (symlinks to marketplace plugins)

- **Documentation**
  - CLAUDE-CODE-AUTOMATION-001: Architecture overview
  - AI-AGENT-BEHAVIORS-001: Agent persona specifications
  - GITHUB-ACTIONS-ARCHITECTURE-001: CI/CD pipeline design
  - BRANCH-PROTECTION-RULES-001: GitHub protection config
  - REPOSITORY-SETUP-CHECKLIST-001: Step-by-step repo setup
  - LOCAL-DEV-SETUP-001: Developer onboarding guide
  - COST-MONITORING-AUTOMATION-001: Budget tracking setup
  - CHANGELOG-AUTOMATION-001: Automated changelog strategy

- **Templates**
  - PR templates: Feature, Documentation, Hotfix
  - Issue templates: Bug Report, Feature Request, Sprint Task
  - Dependabot configuration for automated updates

### Security
- Bash command validator blocks: `rm -rf /`, fork bombs, `curl|bash`, destructive operations
- Security PR review workflow with OWASP Top 10 scanning
- Secret scanning in CI pipeline

## References

- **Stage 5.3**: Project initialization, CI/CD, and Claude Code automation
- **ROADMAP-001**: MVP implementation timeline (8 sprints)
- **COST-MODEL-001**: Budget allocation ($554/month)

---

**Note**: This CHANGELOG will be automatically updated on each release using Conventional Commits. See CHANGELOG-AUTOMATION-001 for details.
