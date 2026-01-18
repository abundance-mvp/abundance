# TEST-005: Cross-Platform Testing Strategy

**Extends**: TEST-STRATEGY-001
**Sprint**: 8 (Testing, Polish & TestFlight Launch)
**Scope**: iOS 26+ devices
**Last Updated**: 2025-11-12

---

## Purpose

Validate Abundance MVP across target iOS devices and screen sizes per ADR-004 (iOS 26+ only launch strategy). Ensures consistent UX before TestFlight distribution.

**Referenced by**: ios-sprint-executor (Sprint 8 acceptance criteria)

---

## Target Devices (iOS 26+)

Per ADR-004, MVP launches iOS 26+ only. Testing focuses on latest generation devices:

| Device | Screen Size | Test Priority |
|--------|-------------|---------------|
| iPhone 26 Pro Max | 6.9" | P0 (flagship) |
| iPhone 26 Pro | 6.3" | P0 (flagship) |
| iPhone 26 | 6.1" | P1 (base model) |
| iPad Pro 13" (M5) | 13" | P2 (tablet) |
| iPad Air 11" (M3) | 11" | P2 (tablet) |

**Rationale**: ADR-004 limits to latest OS for Apple Intelligence features (on-device LLM, enhanced Vision APIs).

**No backward compatibility testing required** (iOS 25, iOS 24, etc.)

---

## Device-Specific Test Matrix

### P0 Tests (Run on all devices)

**UI Layout Tests**:
- [ ] Onboarding flow renders correctly
- [ ] Camera view fills screen (AVCaptureVideoPreviewLayer)
- [ ] Catalog grid adapts to screen width
- [ ] Item detail view scrollable on all sizes
- [ ] Navigation bar heights correct (safe area insets)

**Functional Tests**:
- [ ] Apple Sign-In works on all devices
- [ ] Camera capture succeeds (test via Xcode device simulator)
- [ ] AI processing completes (< 10s target)
- [ ] Catalog search filters results
- [ ] Item editing saves changes

**Performance Tests**:
- [ ] App launch time < 2s cold start
- [ ] SwiftUI view rendering < 16ms (60fps)
- [ ] Image loading < 500ms (via Kingfisher cache)

---

### P1 Tests (iPhone 26 Pro Max only)

**Advanced Features**:
- [ ] Dynamic Island integration (Live Activities for AI processing)
- [ ] ProMotion 120Hz scrolling (catalog grid)
- [ ] Camera Control button (hardware shutter on iPhone 26 Pro)

---

### P2 Tests (iPad Pro 13" only)

**Tablet-Specific**:
- [ ] Multi-column catalog layout (3 columns on 13")
- [ ] Split-view support (catalog + item detail side-by-side)
- [ ] Keyboard shortcuts (Cmd+F for search)

---

## Simulator Testing (Local)

### Test Suite Execution

```bash
# iPhone 26 (base model, most common)
xcodebuild test \
  -workspace ios/Abundance.xcworkspace \
  -scheme AbundanceApp \
  -destination 'platform=iOS Simulator,name=iPhone 26,OS=26.0'

# iPhone 26 Pro Max (flagship)
xcodebuild test \
  -workspace ios/Abundance.xcworkspace \
  -scheme AbundanceApp \
  -destination 'platform=iOS Simulator,name=iPhone 26 Pro Max,OS=26.0'

# iPad Pro 13" (tablet)
xcodebuild test \
  -workspace ios/Abundance.xcworkspace \
  -scheme AbundanceApp \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.0'
```

**Expected Runtime**: 5-10 minutes per device (unit + UI tests)

---

## Real Device Testing (TestFlight Beta)

**Requirement**: Sprint 8 acceptance criteria includes real device validation before public TestFlight.

### Beta Testing Cohort (Internal)

| Device | OS | Tester Role |
|--------|----|----|
| iPhone 26 Pro | iOS 26.0 | Dev team lead |
| iPhone 26 | iOS 26.1 | QA engineer |
| iPad Pro 13" | iPadOS 26.0 | Product manager |

**Test Protocol**:
1. Install from TestFlight link
2. Execute manual test cases (see below)
3. Report issues via TestFlight feedback or GitHub Issues
4. Complete within 48 hours of TestFlight upload

---

## Manual Test Cases (Real Devices)

### TC-001: Full User Journey (E2E)

**Steps**:
1. Launch app (first time)
2. Complete onboarding (read welcome screen)
3. Tap "Sign in with Apple"
4. Complete Face ID/Touch ID authentication
5. View empty catalog
6. Tap camera button
7. Grant camera permission (iOS prompt)
8. Capture photo of banana
9. Wait for AI processing (observe progress indicator)
10. Verify item appears in catalog (name: "Bananas", expiry: "5 days")
11. Tap item → view detail screen
12. Tap edit button → change expiry date
13. Save changes → verify update
14. Navigate back to catalog
15. Use search bar → type "Banana"
16. Verify filtered results

**Expected Duration**: 3-5 minutes
**Pass Criteria**: All steps complete without crashes or UI glitches

---

### TC-002: Camera Functionality

**Steps**:
1. Open camera view
2. Point at various food items (5 different items)
3. Capture each item
4. Verify AI processing completes for all
5. Check catalog for all 5 items

**Pass Criteria**:
- Camera preview clear (no black screen)
- Capture button responsive
- All 5 items processed successfully
- No duplicate items created

---

### TC-003: Offline Mode

**Steps**:
1. Enable Airplane Mode
2. Launch app
3. Navigate to catalog (previously synced items)
4. View item detail
5. Attempt to capture new item
6. Disable Airplane Mode
7. Wait for sync

**Pass Criteria**:
- Cached catalog items viewable offline
- Offline indicator shown when capturing (no crash)
- New item syncs after network restored

---

## CI Integration (GitHub Actions)

**File**: `.github/workflows/cross-platform-tests.yml`

```yaml
name: Cross-Platform Tests

on:
  pull_request:
    branches: [main]

jobs:
  ios-simulator-tests:
    runs-on: macos-14
    strategy:
      matrix:
        device:
          - 'iPhone 26'
          - 'iPhone 26 Pro Max'
          - 'iPad Pro 13-inch (M5)'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '16.0'

      - name: Run Tests on ${{ matrix.device }}
        run: |
          cd ios
          xcodebuild test \
            -workspace Abundance.xcworkspace \
            -scheme AbundanceApp \
            -destination 'platform=iOS Simulator,name=${{ matrix.device }},OS=26.0' \
            -resultBundlePath TestResults-${{ matrix.device }}

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.device }}
          path: ios/TestResults-${{ matrix.device }}
```

**Runtime**: 15-30 minutes (3 devices in parallel)

---

## Screen Size Testing (SwiftUI Previews)

**Tool**: Xcode Canvas Previews

**Example** (`CatalogView.swift`):
```swift
#Preview("iPhone 26") {
    CatalogView()
        .previewDevice(PreviewDevice(rawValue: "iPhone 26"))
}

#Preview("iPhone 26 Pro Max") {
    CatalogView()
        .previewDevice(PreviewDevice(rawValue: "iPhone 26 Pro Max"))
}

#Preview("iPad Pro 13-inch") {
    CatalogView()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M5)"))
}
```

**Usage**: Visual inspection during development (Sprint 6-7 UI work)

---

## Accessibility Testing

**Requirement**: VoiceOver support per Apple Human Interface Guidelines

### VoiceOver Tests (Real Device)

1. Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. Navigate through onboarding flow (swipe gestures)
3. Verify all buttons announced correctly
4. Test catalog item navigation
5. Test camera capture with VoiceOver active

**Pass Criteria**:
- All UI elements have accessibility labels
- Navigation order logical
- Actions announced ("Capture button, double-tap to activate")

---

## Performance Benchmarks

**Requirement**: Sprint 8 acceptance criteria includes performance targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold start time | < 2s | Xcode Instruments (Time Profiler) |
| Catalog scroll FPS | 60fps | Xcode Instruments (Core Animation) |
| Image load time | < 500ms | Kingfisher metrics |
| AI processing | < 10s | Cloud Functions logs |
| Memory usage | < 150MB | Xcode Memory Graph |

**Test on**: iPhone 26 (base model, lowest spec)

---

## Success Metrics

Sprint 8 acceptance criteria:
- [ ] P0 tests pass on all 3 priority devices (iPhone 26, 26 Pro, 26 Pro Max)
- [ ] P1 tests pass on iPhone 26 Pro Max
- [ ] P2 tests pass on iPad Pro 13"
- [ ] Manual test cases completed by 3 internal beta testers
- [ ] Zero crashes reported in TestFlight beta (48-hour soak test)
- [ ] VoiceOver navigation functional
- [ ] Performance benchmarks met on base model (iPhone 26)

---

## Known Limitations

**iOS 26+ Only**:
- No backward compatibility testing (ADR-004)
- Users on iOS 25 or older cannot install (App Store requirement enforced)

**Simulator Limitations**:
- Camera capture mocked (real device needed for true camera testing)
- Face ID simulation (not identical to real biometric auth)
- Performance metrics approximate (real device more accurate)

---

## References

- **ADR-004**: iOS 26+ Only Launch (no backward compatibility)
- **TEST-STRATEGY-001**: Overall test strategy (80%+ coverage)
- **SPRINT-PLAN-008**: Sprint 8 deliverables (TestFlight launch)
- **Apple Human Interface Guidelines**: iOS 26 design patterns

---

**Last Updated**: 2025-11-12
**Validated**: Sprint 8 acceptance criteria
**Test Scope**: iOS 26+ only (3 iPhone models, 2 iPad models)
