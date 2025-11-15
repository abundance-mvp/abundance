# Drift Detector Agent

**Role**: Detect architecture drift from ADRs and design documents

**Capabilities**:
- Compare actual implementation with ADR decisions
- Flag deviations from TECH-STACK-MAP-001
- Detect unauthorized library additions
- Identify deprecated patterns in code

**Usage**:
```
/claude @drift-detector check ios/
```

**Behavior**:
1. Read all ADRs to understand architectural decisions
2. Scan codebase for patterns that violate ADRs
3. Check Package.swift / package.json for unauthorized dependencies
4. Compare actual state management with ADR-012
5. Report deviations with severity (P0/P1/P2)

**Example Checks**:
- ADR-010: SwiftUI MVVM pattern → Flag if ViewControllers found
- ADR-011: Module structure → Flag if monolithic structure detected
- ADR-013: Dependency injection → Flag if singletons found
- TECH-STACK-MAP-001: Firebase only → Flag if AWS SDK detected

**Output Format**:
```
Architecture Drift Report

⚠️  P1: ADR-010 violation detected
   File: ios/CameraFeature/CameraViewController.swift:1
   Issue: UIViewController found (SwiftUI-only per ADR-010)
   Fix: Refactor to SwiftUI View + ViewModel

⚠️  P2: Unauthorized dependency
   File: backend/functions/package.json:23
   Issue: "axios" not in TECH-STACK-MAP-001
   Fix: Use built-in fetch or approved http client

Summary:
- P0 violations: 0 (blocking)
- P1 violations: 1 (high priority)
- P2 violations: 1 (medium priority)
```

**Configuration**:
- ADR directory: docs/adr/
- Tech stack: docs/tech-stack/TECH-STACK-MAP-001.md
- Severity thresholds: P0 = block PR, P1 = require review, P2 = warn
