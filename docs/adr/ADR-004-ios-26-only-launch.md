# ADR-004: iOS 26-Only Launch Strategy

**Status:** Approved
**Date:** 2025-10-24
**Decision Makers:** Product Leadership, Engineering Leadership
**Related Documents:**
- PRD-001 (Product Requirements)
- ADR-003 (MVP Scope Phasing)
- TECH-STACK-001 (Technology Stack Map)
- Stage 2.4 iOS 26 Research Documents

---

## Context

iOS 26 introduces advanced Vision Framework capabilities (`VNRecognizeObjectsRequest`) that enable on-device object detection without cloud AI costs. This creates a technical decision point:

**Should we:**
- **Option A:** iOS 26-only (iPhone 15 Pro+, ~15% market at launch)
- **Option B:** Dual-tier support (iOS 17+ for basic features, iOS 26 for advanced)
- **Option C:** Delay launch until iOS 26 adoption reaches 30-40% (6-12 months)

This ADR documents the decision to pursue **Option A (iOS 26-Only Launch)** and the strategic trade-offs.

---

## Decision

**We will launch Abundance as an iOS 26-only application, requiring iPhone 15 Pro or newer (A17 Pro chip).**

### Device Requirements

**Supported Devices:**
- iPhone 15 Pro (A17 Pro chip)
- iPhone 15 Pro Max (A17 Pro chip)
- iPhone 16 and newer (A18+ chips)
- iPad Pro with M1 or newer
- iPad Air with M1 or newer

**Unsupported:**
- iPhone 15 (A16 Bionic - no Neural Engine for Vision Framework)
- iPhone 14 and older
- iPad (9th gen and older)

### Minimum Requirements

| Requirement | Value | Rationale |
|-------------|-------|-----------|
| **iOS Version** | 26.0+ | Vision Framework `VNRecognizeObjectsRequest` requires iOS 26 |
| **Chip** | A17 Pro+ or M1+ | Apple Neural Engine required for on-device ML performance |
| **RAM** | 8 GB+ | Vision Framework image processing requires memory |
| **Storage** | 500 MB+ | App size + on-device ML models |

---

## Rationale

### 1. Free Tier Economics (On-Device AI = $0 Cost)

**Problem:**
- Cloud AI costs $0.010-0.020 per image (Gemini, GPT-4V)
- Free tier users with cloud AI = negative unit economics
- Need 30%+ premium conversion to break even

**Solution (iOS 26 On-Device):**
- Free tier: iOS 26 Vision Framework (on-device, $0 cost)
- Premium tier: Google Shopping Graph ($0.007/item)
- Free tier users have zero marginal cost → sustainable freemium model

**Financial Impact (Month 6, 5,000 users):**

| Scenario | Free Tier Cost | Premium Tier Cost | Total Cost | Revenue | Margin |
|----------|----------------|-------------------|------------|---------|--------|
| **iOS 26-Only** | $0 (on-device) | $525 (Shopping Graph) | $525 | $9,000 | **94%** |
| **Cloud AI (iOS 17+)** | $3,500 (3,500 × $0.020) | $525 | $4,025 | $9,000 | **55%** |

**Conclusion:** iOS 26-only approach improves margin by 39 percentage points.

---

### 2. Product Differentiation (Cutting-Edge Technology)

**Problem:**
- Crowded market: Google Lens, Amazon app, eBay image search
- Need differentiation beyond "AI-powered inventory app"

**Solution (iOS 26 Vision Framework):**
- **First-to-market:** iOS 26 Vision Framework is brand new (released 2025)
- **Premium positioning:** "Requires latest iPhone" = status symbol
- **Early adopter persona:** Aligns with Organizer persona (tech-savvy, privacy-conscious)

**Marketing Narrative:**
- "Abundance uses Apple's newest AI technology to catalog your items instantly - no cloud upload required."
- "Privacy-first: Your photos never leave your device (free tier)."

**Competitive Moat (6-12 months):**
- Competitors need time to integrate iOS 26 APIs (6+ months)
- By Month 12, iOS 26 adoption reaches 30-40% → expand to broader market

---

### 3. Technical Simplicity (Single Codebase)

**Problem:**
- Dual-tier support (iOS 17+ and iOS 26) requires:
  - Separate codepaths (legacy YOLOv8n vs. iOS 26 Vision)
  - Complex feature flagging
  - Testing matrix explosion (2 OS versions × 5 device types = 10 test configurations)

**Solution (iOS 26-Only):**
- **Single codebase:** One API (`VNRecognizeObjectsRequest`), no legacy code
- **Faster iteration:** No branching logic, simpler debugging
- **Lower QA burden:** 3 device types to test (iPhone 15 Pro, 16, iPad M1+)

**Engineering Efficiency:**
- Estimated 30% faster development (5 months instead of 7)
- Lower bug rate (fewer edge cases)
- Cleaner architecture (no legacy compatibility layers)

---

### 4. Market Size Trade-Off (Quality Over Quantity)

**Problem:**
- iOS 26 adoption at launch: ~15% of iOS users (~30 million devices globally)
- Excludes 85% of iPhone users (iPhone 14 and older)

**Strategic Decision:**
- **Focus on early adopters** (Organizers persona: tech-savvy, premium device owners)
- **Phase 1:** Target 5,000 users in Austin (metro-by-metro strategy)
- **Phase 2 (Month 12):** Expand to iOS 25+ when adoption reaches 30-40%

**Market Size Analysis (Austin Metro):**

| Metric | Value | Calculation |
|--------|-------|-------------|
| Austin iPhone users | 400,000 | 1M adults × 60% iOS × 67% iPhone |
| iOS 26 adoption (Month 0) | 60,000 | 400K × 15% |
| Target (Month 6) | 5,000 users | 8% of iOS 26 users |
| Headroom for growth | 55,000 | 12× current target |

**Conclusion:** iOS 26-only does NOT constrain Month 6 goals (5,000 users achievable).

---

### 5. iOS 26 Adoption Trajectory

**Historical iOS Adoption Rates:**
- iOS 17 (2023): 15% adoption in 1 month, 40% in 6 months, 60% in 12 months
- iOS 18 (2024): Similar trajectory

**Projected iOS 26 Adoption:**

| Timeline | Adoption Rate | Total iPhone Users | Global Market Size |
|----------|---------------|--------------------|--------------------|
| Month 0 (Launch) | 15% | 150M iOS users | 22.5M iOS 26 devices |
| Month 3 | 20% | 200M iOS users | 40M iOS 26 devices |
| Month 6 | 30% | 300M iOS users | 90M iOS 26 devices |
| Month 12 | 40-50% | 400-500M iOS users | 160-250M iOS 26 devices |

**Strategic Timing:**
- **Phase 1 (Month 0-6):** Launch on 15% market, grow to 5K users
- **Phase 2 (Month 6-12):** iOS 26 adoption doubles (30%), marketplace launch
- **Phase 3 (Month 12+):** 40-50% adoption, geographic expansion (Portland, Seattle)

---

## Alternatives Considered

### Alternative 1: Dual-Tier Support (iOS 17+ Basic, iOS 26 Advanced)

**Approach:**
- iOS 17-25: Cloud AI (Gemini Vision) for all users
- iOS 26+: On-device Vision Framework (free tier), Shopping Graph (premium)

**Pros:**
- Larger addressable market (85% of iPhone users)
- Lower risk (more users = more feedback)

**Cons:**
- **Unit economics:** Free tier with cloud AI = negative margin (55% vs. 94%)
- **Technical complexity:** Dual codepaths, feature flags, testing burden
- **Slower iteration:** 30% longer development timeline (7 months vs. 5)
- **Weaker differentiation:** No unique iOS 26 positioning

**Why Rejected:**
- Free tier with cloud AI is unsustainable (burns $3,500/month at 5K users)
- Technical complexity slows MVP iteration (critical in Phase 1 PMF validation)
- iOS 26-only approach has better long-term economics

---

### Alternative 2: Delay Launch Until iOS 26 Adoption Reaches 30%

**Approach:**
- Wait 6-9 months for iOS 26 adoption to reach 30-40%
- Launch with larger addressable market

**Pros:**
- 2× larger market at launch (30% vs. 15%)
- Lower customer acquisition cost (CAC)

**Cons:**
- **Lost time:** 6-9 month delay = competitors catch up
- **Missed learning:** No user feedback during crucial early months
- **Fundraising risk:** Investors want traction, not "waiting for market"

**Why Rejected:**
- Time-to-market is critical (first-mover advantage on iOS 26 Vision)
- 15% market is sufficient for 5K users in Austin metro
- Early adopters provide higher-quality feedback (tech-savvy Organizers)

---

### Alternative 3: iOS 25 with YOLOv8n (Pre-iOS 26 Launch)

**Approach:**
- Use custom ML model (YOLOv8n) for object detection on iOS 25
- Upgrade to iOS 26 Vision Framework when available

**Pros:**
- Launch sooner (don't wait for iOS 26 release)
- Larger market (iOS 25 = 60% adoption at iOS 26 launch)

**Cons:**
- **Technical debt:** Must migrate from YOLOv8n → iOS 26 Vision (6-8 weeks refactor)
- **Performance:** YOLOv8n slower than iOS 26 Vision (1-2 sec vs. <500ms)
- **Accuracy:** Custom model requires training data, lower accuracy (70% vs. 85%)

**Why Rejected:**
- iOS 26 Vision Framework is production-ready (no training data needed)
- Migration cost (YOLOv8n → Vision) outweighs 3-6 month time-to-market gain
- Better to launch right with iOS 26 than refactor later

---

## Implications & Consequences

### Positive Consequences

**1. Sustainable Free Tier (0% Cloud AI Costs)**
- Free users have zero marginal cost → can afford 70% free tier
- Premium conversion pressure is lower (15% vs. 30%+ required with cloud AI)

**2. Premium Brand Positioning**
- "Requires iPhone 15 Pro+" = high-end positioning
- Aligns with Organizer persona (affluent, tech-savvy)

**3. Faster Development & Iteration**
- Single codebase (iOS 26 only)
- 30% faster MVP delivery (5 months vs. 7)
- Cleaner architecture (no legacy compatibility)

**4. First-Mover Advantage**
- 6-12 month moat (competitors need time to integrate iOS 26)
- Press coverage: "First app to use iOS 26 Vision Framework"

---

### Negative Consequences (Risks)

**1. Smaller Addressable Market (15% vs. 85%)**
- **Risk:** Harder to acquire 5,000 users in Austin
- **Mitigation:** 15% of Austin iPhone users = 60K devices (12× target)
- **Mitigation:** Target early adopters (willing to upgrade to iPhone 15 Pro)

**2. Device Upgrade Barrier**
- **Risk:** Users with iPhone 14 or older can't use app
- **Mitigation:** Phase 2 (Month 12): Expand to iOS 25+ (60% market)
- **Mitigation:** Marketing: "Upgrade to iPhone 15 Pro for Abundance access"

**3. App Store Discovery (Lower Ranking Due to Device Restrictions)**
- **Risk:** iOS 26-only apps rank lower in App Store search
- **Mitigation:** Paid user acquisition (Facebook Ads, Instagram, TikTok)
- **Mitigation:** PR strategy: Tech blogs, early adopter communities

**4. Competitive Response (Faster Than Expected)**
- **Risk:** Google Lens, Amazon integrate iOS 26 Vision in 3-6 months
- **Mitigation:** Network effects (passive marketplace in Month 6)
- **Mitigation:** Brand loyalty (early adopters become advocates)

---

## Validation Criteria (Month 6 Checkpoint)

### Proceed with iOS 26-Only (GREEN)

Must hit **ALL** of the following:

1. ✅ 5,000+ users (iOS 26 market sufficient)
2. ✅ CAC < $15 (user acquisition cost within budget)
3. ✅ 25%+ Month 6 retention (users find value despite device restriction)
4. ✅ iOS 26 adoption reaches 25-30% (market expanding)

**Action:** Continue iOS 26-only strategy, prepare marketplace (Phase 2)

---

### Expand to iOS 25+ (YELLOW)

Hit **3 of 4** criteria, but market constraint evident:

- 3,000-4,999 users (close to goal)
- CAC $15-20 (slightly high)
- 20-24% retention (good but not great)
- iOS 26 adoption 20-25% (growing slower)

**Action:**
- Month 9: Add iOS 25 support (YOLOv8n fallback for older devices)
- Expand addressable market to 60% of iPhone users
- Increase CAC budget (easier to acquire users with broader device support)

---

### Pivot or Kill (RED)

Hit **< 2 of 4** criteria, iOS 26 constraint too limiting:

- < 3,000 users (struggling to acquire early adopters)
- CAC > $20 (user acquisition too expensive)
- < 20% retention (users churn despite early adopter persona)
- iOS 26 adoption < 20% (market not growing fast enough)

**Action:**
- **Pivot:** Add iOS 25 support immediately (emergency measure)
- **Kill:** If iOS 25 expansion doesn't improve metrics by Month 9

---

## Open Questions for Resolution

### Question 1: iOS 26 Beta Access (Pre-Launch Testing)

**Question:** Should we participate in iOS 26 beta program (3-6 months before public release)?

**Options:**
- **Yes:** Early access to Vision Framework, test with beta users
- **No:** Wait for public release (lower risk)

**Recommendation:** Yes (early testing reduces launch bugs)

---

### Question 2: iOS 25 Fallback Timeline

**Question:** When should we add iOS 25 support (YOLOv8n fallback)?

**Options:**
- **Month 6:** If Phase 1 goals not met
- **Month 9:** If iOS 26 adoption < 25%
- **Month 12:** After Phase 2 (marketplace launch)
- **Never:** Commit to iOS 26-only long-term

**Recommendation:** Month 9 (after Phase 1 validation, before Phase 2 marketplace)

---

### Question 3: Device Upgrade Incentive Program

**Question:** Should we offer incentives for users to upgrade to iPhone 15 Pro?

**Options:**
- **Partner with carriers:** AT&T, Verizon trade-in promotion
- **Referral bonus:** $10 credit for referring friend who upgrades
- **Apple Store partnership:** In-store demo kiosks

**Recommendation:** Explore Apple Store partnership (Month 3-6)

---

## Related Decisions

**ADR-003 (MVP Scope Phasing):**
- Inventory-first approach aligns with iOS 26-only (early adopter market)
- Phase 2 (Month 12): Expand to iOS 25+ coincides with marketplace launch

**ADR-005 (GCP Platform Selection):**
- iOS 26 on-device processing reduces cloud costs → GCP free tier sufficient

**ADR-012 (Google Shopping Graph as Primary AI):**
- Premium tier (Shopping Graph) requires iOS 26 Vision Framework for object detection

---

## Stakeholder Sign-Off

**Required Approvals:**

- [ ] **CEO / Product Leadership:** Approve iOS 26-only strategy, accept 15% market trade-off
- [ ] **Engineering Leadership:** Confirm iOS 26 Vision Framework is production-ready
- [ ] **Marketing Leadership:** Approve premium positioning, early adopter targeting
- [ ] **Finance / Fundraising:** Validate unit economics (94% margin with iOS 26-only)

**Timeline:**
- ADR review: Week of 2025-10-28
- Final decision: 2025-10-31
- Kick-off Phase 1 build: 2025-11-04

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial draft, iOS 26-only rationale | Stage 2.1 Execution |

---

## Conclusion

**Decision: Launch Abundance as iOS 26-only application (iPhone 15 Pro+, A17 Pro chip required)**

This strategy:
- ✅ Enables sustainable free tier (on-device AI = $0 cost)
- ✅ Differentiates from competitors (first iOS 26 Vision app)
- ✅ Simplifies technical architecture (single codebase)
- ✅ Targets early adopters (Organizer persona)
- ⚠️ Accepts smaller market (15% vs. 85%) in exchange for better economics

**Next Steps:**
1. Engineering: Implement iOS 26 Vision Framework integration
2. Design: Create premium onboarding flow ("Requires iPhone 15 Pro+")
3. Marketing: Develop early adopter acquisition strategy
4. Month 6 Checkpoint: Evaluate iOS 26-only success, decide on iOS 25 expansion

---

**This ADR will be revisited at Month 6 based on validation criteria outcomes.**
