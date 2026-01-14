# iOS Pre-Superpowers Archive

**Archived**: 2026-01-14
**Reason**: Created without ios-superpowers skill (Apple docs + Axiom grounding)

## What Was Archived

iOS specification documents created before the ios-superpowers skill was
integrated into the verified-stage-development workflow. These documents
lack:

1. **Apple Documentation Grounding** - No verification against official
   Apple Developer documentation via sosumi.ai MCP
2. **Axiom Skill Patterns** - No integration with Axiom iOS skills:
   - axiom-swiftui-26-ref (iOS 26 SwiftUI patterns)
   - axiom-liquid-glass (Liquid Glass styling)
   - axiom-swift-concurrency (async/await, actors)
   - axiom-xcode-debugging (build issues)
   - axiom-memory-debugging (leaks, profiling)
   - axiom-ui-testing (XCTest, XCUITest)

## Contents

### ADRs (4 files)
- ADR-010: SwiftUI Architecture Pattern
- ADR-011: iOS Module Structure
- ADR-012: State Management Strategy
- ADR-013: Dependency Injection Strategy

### Design Docs (25 files)
- DESIGN-006 through DESIGN-014: iOS Architecture
- DESIGN-026 through DESIGN-040: iOS UI/UX Specifications

### Code Examples (5 files)
- CODE-EXAMPLE-001: Swift 6 Concurrency Patterns
- CODE-EXAMPLE-002: Catalog MVVM Implementation
- CODE-EXAMPLE-003: Firebase iOS Integration
- CODE-EXAMPLE-004: Vision Framework Patterns
- CODE-EXAMPLE-009: Household Item Detector

### Test Examples (3 files)
- TEST-EXAMPLE-001: ViewModel Unit Tests
- TEST-EXAMPLE-002: iOS Testing Patterns
- TEST-EXAMPLE-004: ML/CV Testing Patterns

## Regeneration Plan

These documents will be regenerated using:
1. `/verified-stage-development stage-2.2` - iOS Client Architecture
2. `/verified-stage-development stage-2.6` - iOS UI/UX Design
3. `/verified-stage-development stage-3.1` - iOS Implementation Research
4. `/verified-stage-development stage-3.3` - Layer 1 On-Device ML

Each stage will use ios-superpowers which automatically:
- Fetches Apple documentation via sosumi.ai MCP
- Routes to appropriate Axiom skills based on task type
- Grounds all specifications in official Apple patterns
