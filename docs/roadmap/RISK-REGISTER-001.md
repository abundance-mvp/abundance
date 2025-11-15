# RISK-REGISTER-001: Technical Risks & Mitigations

**Created**: 2025-11-12
**Risk Prioritization**: P0 (BLOCKING), P1 (High Impact), P2 (Medium Impact)

---

## P0 Risks (BLOCKING - Could Stop Development)

### P0-1: iOS 26 Adoption Rate Too Low

**Impact**: BLOCKING (market too small, < 1% iPhone users)

**Mitigation:**
- Track iOS 26 adoption via Mixpanel, App Annie (monitor monthly)
- If adoption remains low: Consider fallback to iOS 25 (ConcentricRectangle polyfill)
- ADR-004 documents iOS 26 decision with fallback strategy

**Contingency:**
- Backport to iOS 25 (remove ConcentricRectangle, use standard shapes)

---

### P0-2: Firebase Quota Exceeded (Free Tier)

**Impact**: BLOCKING (app stops working for all users)

**Mitigation:**
- Implement daily usage monitoring (Cloud Logging + BigQuery)
- Budget alert at 80% of free tier (40K reads/day)
- Optimize Firestore queries (cache aggressively, denormalize data)
- Upgrade to Blaze plan if needed (~$50/month for 100K reads/day)

**Contingency:**
- Emergency upgrade to Blaze plan (can activate in < 5 minutes)

---

## P1 Risks (High Impact - Could Delay Sprints)

### P1-1: AI Pipeline Accuracy Below Targets

**Impact**: High (poor user experience, high churn)

**Target Accuracy:**
- Layer 1: > 60% (coarse detection)
- Layer 2a: > 80% (attributes)
- Layer 2b: > 75% (product ID)
- Layer 3: > 75% (synthesis)

**Mitigation:**
- Golden dataset validation (100 items, diverse categories)
- Tune prompts during Sprint 5 (iterate on Layer 2a/2b/3 prompts)
- If Layer 2b < 75%: Increase SerpAPI usage (reduce barcode-first optimization)
- If Layer 3 < 75%: Add Claude prompt engineering iteration

**Contingency:**
- Manual review queue (10% of items flagged for human validation)
- Users can always override AI suggestions (acceptance criteria already includes edit UI)

---

### P1-2: Cloud Functions Cold Start Latency

**Impact**: High (poor UX, > 3s first request after idle)

**Mitigation:**
- Use Cloud Functions 2nd gen (faster cold starts, < 1s vs 3s)
- Implement minimum instances for critical endpoints (health, create item)
- Optimize function bundle size (tree-shake dependencies)
- Pre-warm functions during TestFlight launches (automated curl script)

**Contingency:**
- Upgrade to Cloud Run (faster cold starts, higher cost) if latency unacceptable

---

### P1-3: GitHub Actions macOS Runner Cost

**Impact**: Medium (budget overrun, $0.08/min macOS builds)

**Mitigation:**
- Optimize caching (SPM dependencies, DerivedData)
- Reduce build frequency (only on PR merge, not every commit)
- Monitor usage dashboard (GitHub Actions → Usage)
- 200 min/month = 40 builds @ 5 min/build (sufficient for 2 builds/week)

**Contingency:**
- Self-hosted macOS runner (Mac Mini, one-time cost $599 vs monthly overage)

---

## P2 Risks (Medium Impact - Manageable)

### P2-1: SwiftLint/Sourcery Tool Version Conflicts

**Impact**: Low (build warnings, manual fixes)

**Mitigation:**
- Lock tool versions in Homebrew (swiftlint@0.62.2, sourcery@2.3.0)
- Document installation in README-iOS-Setup.md
- Troubleshooting section covers version mismatches

---

### P2-2: Firebase Emulator Java Dependency

**Impact**: Low (local development blocked)

**Mitigation:**
- README-Backend-Setup.md documents Java installation
- Homebrew install command: `brew install openjdk@11`
- Alternative: Use cloud dev environment (Firestore Dev project instead of emulator)

---

## Risk Review Cadence

- **Sprint Start**: Review P0/P1 risks
- **Continuous**: Monitor P0 risks for blockers
- **Sprint End**: Add new risks identified during sprint
- **Periodic**: Update risk register with actual outcomes (did risks materialize?)

---
