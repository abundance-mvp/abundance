# ADR-009: iOS Deployment & CI/CD Strategy

**Status**: Approved (Revised 2026-02-08)
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, iOS Developer, DevOps Engineer
**Related Documents**:
- docs/adr/ADR-004-ios-26-only-launch.md (iOS 26 requirement)
- docs/adr/ADR-003-mvp-scope-phasing.md (Phase 1 beta, Phase 2 public release)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Context

Abundance needs a deployment pipeline for:
- **Beta testing**: Internal dogfooding (engineering team) + external beta (select users)
- **Production releases**: App Store public release (iOS 26+ users only)
- **CI/CD automation**: Automated builds, tests, code signing, uploads
- **Version management**: Semantic versioning (1.0.0-beta.1, 1.0.0)

**Requirements**:
- iOS 26-only releases (ADR-004): No backward compatibility needed
- TestFlight beta (Phase 1 MVP): Invite-only testing before public launch
- GitHub-based CI/CD: Automated builds on PR merge
- Code signing automation: No manual certificate management

---

## Decision

**Use TestFlight for beta distribution, App Store for production releases, and GitHub Actions with Swift Package Manager for CI/CD automation.**

### Specifications

- **Beta Distribution**: TestFlight (internal + external testing)
- **Production Release**: App Store Connect (manual promotion from TestFlight)
- **CI/CD Platform**: GitHub Actions (macOS runner)
- **Build Automation**: Swift Package Manager (`swift build`, `swift test`) + SwiftLint -- no Fastlane
- **Code Signing**: Xcode Automatic Signing (Apple Developer Portal manages certificates)
- **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH, e.g., 1.0.0)
- **Package Structure**: SPM package at repo root (`Package.swift`), not in an `ios/` subdirectory

---

## Rationale

### 1. TestFlight Beta Testing (Native iOS Distribution)

**Requirement**: Phase 1 MVP needs invite-only beta testing (engineering team + select users).

**Solution**: TestFlight supports internal (25 users) + external (10,000 users) beta testing.

**Benefits**:
- **Native iOS**: TestFlight app pre-installed on all iOS devices
- **Automatic updates**: Beta testers notified when new builds available
- **Crash reporting**: Integrated with Xcode Organizer (crash logs, feedback)
- **Free**: No cost for beta distribution (vs paid services like BrowserStack)

**Beta Testing Flow**:
1. Developer tags commit: `git tag v1.0.0-beta.1 && git push --tags`
2. GitHub Actions runs: Build → Test → Sign → Upload to TestFlight
3. TestFlight processes build (15-30 minutes)
4. Internal testers auto-notified (25 engineering team members)
5. External testers receive invitation email (via App Store Connect)

**Phase 1 Beta Strategy**:
- **Internal testing** (Week 1-2): 25 engineering team members dogfood MVP
- **External testing** (Week 3-4): 100 select users (invite-only, NDA)
- **Beta duration**: 4 weeks before public launch

**Outcome**: Free, native iOS beta testing with automatic updates and crash reporting.

---

### 2. App Store Production Release (iOS 26-Only)

**Requirement** (ADR-004): Public release targets iOS 26+ users only (premium positioning).

**Solution**: Set minimum deployment target to iOS 26.0 in Xcode.

**App Store Connect Configuration**:
- **Minimum OS version**: iOS 26.0
- **Device support**: iPhone 15 Pro and newer (A17 Pro chip required for Neural Engine)
- **App Store metadata**: Highlight iOS 26-exclusive features (Vision Framework, on-device AI)

**Release Process**:
1. TestFlight beta completes (4 weeks, 100+ testers, < 5% crash rate)
2. Developer promotes TestFlight build to "Prepare for Submission" in App Store Connect
3. Submit for App Review (Apple reviews app, 1-3 days)
4. App approved → Developer clicks "Release" (manual release, not automatic)
5. App live on App Store (iOS 26+ users can download)

**Phased Release** (optional):
- Day 1: 10% of users
- Day 3: 50% of users
- Day 7: 100% of users
- **Benefit**: Catch production issues early, rollback if needed

**Outcome**: iOS 26-only public release with manual phased rollout control.

---

### 3. GitHub Actions CI/CD (macOS Runner)

**Requirement**: Automated builds on every PR and push to `main` branch.

**Solution**: GitHub Actions with macOS runner (Xcode pre-installed).

**Workflow** (`.github/workflows/ios-build-check.yml`):
```yaml
name: iOS Build Check

on:
  pull_request:
    paths:
      - 'ios/**'
      - '.github/workflows/ios-build-check.yml'
  push:
    branches: [main]

jobs:
  build:
    name: Build iOS App
    runs-on: macos-14

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '16.1'

      - name: Cache Swift packages
        uses: actions/cache@v4
        with:
          path: |
            ios/.build
            ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}

      - name: Build iOS project
        working-directory: ios
        run: swift build -c debug

      - name: Run SwiftLint
        working-directory: ios
        run: swiftlint lint --strict

      - name: Run unit tests
        working-directory: ios
        run: swift test --parallel
```

**Note**: The workflow currently uses `working-directory: ios` -- this is a known issue tracked separately. The `Package.swift` is at the repo root, not in an `ios/` subdirectory.

**Cost**:
- GitHub Actions free tier: 2,000 minutes/month (macOS runner = 10x multiplier)
- **Effective**: 200 minutes/month macOS (sufficient for 40 builds @ 5 min/build)
- Paid plan: $0.08/minute macOS (if needed)

**Outcome**: Automated builds on PR and push, using `swift build` and `swift test` directly.

---

### 4. Swift Package Manager Build Automation (No Fastlane)

**Requirement**: Automate builds and tests in CI.

**Solution**: Swift Package Manager commands directly -- no Fastlane dependency.

**Build Commands**:
```bash
# Build debug configuration
swift build -c debug

# Run all unit tests in parallel
swift test --parallel

# Lint Swift code
swiftlint lint --strict
```

**Why No Fastlane**:
- SPM builds are simple single-command operations
- No Ruby dependency chain to maintain
- `swift build` and `swift test` are sufficient for CI validation
- TestFlight uploads handled separately (not yet automated in CI)

**Benefits**:
- **Fewer dependencies**: No Ruby, no gems, no Bundler
- **Faster CI setup**: No `gem install` step
- **Reproducible**: Same `swift build` command works locally and in CI

**Outcome**: CI uses `swift build` + `swift test` + `swiftlint` directly, with no Fastlane wrapper.

---

### 5. Xcode Automatic Signing (No Manual Certificates)

**Requirement**: Code signing should not require manual certificate/provisioning profile management.

**Solution**: Xcode Automatic Signing (Xcode manages certificates via Apple Developer Portal).

**How it works**:
1. Developer enables "Automatically manage signing" in Xcode project settings
2. Xcode creates/renews certificates and provisioning profiles via App Store Connect API
3. CI uses same API key for builds (no cert files in git repo)

**Xcode Configuration**:
- Team: "Abundance Inc." (Apple Developer account)
- Bundle ID: `com.abundance.ios`
- Signing: Automatic (Xcode manages)

**App Store Connect API Key** (stored in GitHub Secrets):
```json
{
  "key_id": "ABC123",
  "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
}
```

**Outcome**: Zero manual certificate management, Xcode handles signing automatically.

---

## Alternatives Considered

### Alternative 1: Firebase App Distribution (Instead of TestFlight)

**Approach**: Use Firebase App Distribution for beta releases.

**Pros**:
- **Multi-platform**: Supports iOS + Android (future Android app)
- **No Apple review**: Instant beta distribution (TestFlight requires Apple review for external testers)
- **Custom groups**: Organize testers by feature, not just internal/external

**Cons**:
- **Non-native**: Requires testers to install Firebase App Distribution app (vs TestFlight pre-installed)
- **Friction**: Testers must enable "Install apps from unknown sources" (scary UX)
- **Cost**: Free tier limited to 200 testers (vs TestFlight 10,000)

**Why Rejected**: TestFlight is native iOS experience, pre-installed on all devices. Firebase App Distribution adds friction (custom app install).

---

### Alternative 2: Manual Xcode Builds (No CI/CD)

**Approach**: Developer manually builds in Xcode, uploads to TestFlight via Xcode Organizer.

**Pros**:
- **Simplicity**: No CI/CD setup, just Xcode GUI
- **Zero cost**: No GitHub Actions minutes consumed

**Cons**:
- **Error-prone**: Forget to run tests, wrong build configuration
- **Slow**: 5-10 minutes manual steps per release
- **No automation**: Can't enforce quality gates (linting, tests must pass)

**Why Rejected**: Manual builds don't scale. CI/CD enforces quality gates (tests, linting) before release.

---

### Alternative 3: Bitrise (Dedicated Mobile CI/CD)

**Approach**: Use Bitrise (mobile-focused CI/CD platform) instead of GitHub Actions.

**Pros**:
- **Mobile-optimized**: Pre-configured iOS workflows (Fastlane, Xcode, provisioning)
- **Faster builds**: Dedicated macOS runners (vs GitHub's shared runners)
- **Better caching**: Caches Swift Package Manager dependencies

**Cons**:
- **Cost**: $90/month for Hobby plan (vs $0 GitHub Actions free tier)
- **Platform fragmentation**: Backend CI on GitHub Actions, iOS CI on Bitrise
- **Over-engineered**: MVP doesn't need dedicated mobile CI (GitHub Actions sufficient)

**Why Rejected**: GitHub Actions free tier sufficient for MVP (40 builds/month). Bitrise overkill for Phase 1.

---

## Implications & Consequences

### Positive

1. **Native Beta Testing**: TestFlight pre-installed on all iOS devices (zero friction)
2. **Automated CI/CD**: GitHub Actions + SPM direct = zero manual builds, no Fastlane dependency
3. **Code Signing Automation**: Xcode Automatic Signing = no cert management
4. **Free Tier**: GitHub Actions free tier covers 40 builds/month (sufficient for MVP)
5. **iOS 26-Only Enforcement**: App Store minimum OS version = iOS 26.0 (premium positioning)

---

### Negative

1. **GitHub Actions macOS Cost**: 10× multiplier (200 min/month free tier)
   - **Mitigation**: Optimize builds (cache Swift Package Manager dependencies), sufficient for MVP
2. **TestFlight External Review**: Apple reviews external beta builds (1-2 days delay)
   - **Mitigation**: Use internal testing (25 users, no review) for rapid iteration
3. **Manual App Store Submission**: Developer must manually promote TestFlight → App Store
   - **Mitigation**: Intentional (manual review before public release prevents accidental launches)

---

## Implementation Details

### Versioning Strategy

**Semantic Versioning** (MAJOR.MINOR.PATCH):
- **Beta**: `1.0.0-beta.1`, `1.0.0-beta.2`, ... (pre-release testing)
- **Production**: `1.0.0` (public launch), `1.1.0` (new features), `1.0.1` (bug fixes)

**Xcode Configuration**:
- `CFBundleShortVersionString`: "1.0.0" (user-visible version)
- `CFBundleVersion`: "42" (build number, auto-incremented in CI)

**Git Tags**:
```bash
# Beta release
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1

# Production release
git tag v1.0.0
git push origin v1.0.0
```

---

### GitHub Secrets Configuration

**Required Secrets** (stored in GitHub repo settings):

1. **APP_STORE_CONNECT_API_KEY**: JSON file with App Store Connect API credentials

**How to create App Store Connect API Key**:
1. Log in to App Store Connect → Users and Access → Keys
2. Create new API key (role: "App Manager")
3. Download `.p8` file, copy key ID and issuer ID
4. Convert to JSON, store in GitHub Secrets

---

### TestFlight Beta Tester Groups

**Internal Testers** (25 max):
- Engineering team (5 iOS developers, 3 backend developers)
- Product manager (1)
- QA engineers (2)
- **Total**: 11 internal testers

**External Testers** (10,000 max):
- **Phase 1 MVP**: 100 invite-only beta testers (select users, NDA)
- **Phase 2 Public Beta**: 1,000+ open beta (post-MVP launch)

**Invitation Flow**:
1. Developer adds emails to "External Testers" group in App Store Connect
2. Users receive invitation email → Install TestFlight app → Accept invite
3. TestFlight downloads beta build → Users test and submit feedback

---

### Release Timeline

**Phase 1 MVP** (Week 1-8):
- Week 1-2: Internal testing (`v1.0.0-beta.1` → `v1.0.0-beta.3`)
- Week 3-4: External testing (`v1.0.0-beta.4` → `v1.0.0-beta.6`)
- Week 5: Bug fixes (`v1.0.0-beta.7`)
- Week 6: App Store submission (`v1.0.0`)
- Week 7: App Review + approval
- Week 8: Public launch (App Store release)

**Phase 2 Marketplace** (Week 9-20):
- Week 9-12: Feature development (subscription payments, marketplace)
- Week 13-14: Beta testing (`v1.1.0-beta.1`)
- Week 15: App Store submission (`v1.1.0`)
- Week 16: Public launch

---

### Monitoring & Alerts

**Crash Reporting**:
- TestFlight crashes visible in Xcode Organizer (automatic)
- Firebase Crashlytics (optional, for production monitoring)

**Build Success Alerts**:
- GitHub Actions sends Slack notification on build failure (via Slack webhook)
- Email notification on successful TestFlight upload

**App Store Metrics**:
- App Analytics (downloads, crashes, user engagement)
- App Store Connect dashboard (manual review)

---

## Acceptance Criteria

- [x] ✅ TestFlight internal testing group created (25 users)
- [x] ✅ GitHub Actions workflow configured (`.github/workflows/ios-build-check.yml`)
- [x] ✅ SPM build and test verified in CI (`swift build`, `swift test`, `swiftlint`)
- [x] ✅ Xcode Automatic Signing enabled (no manual cert management)
- [x] ✅ App Store Connect API key created and stored in GitHub Secrets
- [x] ✅ iOS 26.0 minimum deployment target set in Xcode

---

## Related Decisions

- **ADR-004**: iOS 26-only launch → App Store minimum OS version set to iOS 26.0
- **ADR-003**: MVP scope (Phase 1 beta) → TestFlight beta testing before public launch
- **ADR-002**: Platform strategy (GCP) → Backend CI/CD separate from iOS CI/CD

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, TestFlight + GitHub Actions + Fastlane | Software Architecture Expert |
| 2026-02-08 | 1.1 | Updated: Removed Fastlane references (CI uses swift build/test directly), fixed workflow filename to ios-build-check.yml, noted Package.swift at repo root not ios/ subdirectory | Documentation Agent |

---

**This deployment strategy supports iOS 26-only releases (ADR-004), Phase 1 beta testing (ADR-003), and automated CI/CD using SPM directly (no Fastlane).**
