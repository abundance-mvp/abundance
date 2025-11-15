# ADR-003: MVP Scope and Phasing Decision

**Status:** Proposed
**Date:** 2025-10-24
**Decision Makers:** Product Leadership, Engineering Leadership
**Related Documents:** PRD-001, FEATURES-001, METRICS-001, business-strategy-validated.md, ADR-001, ADR-002

---

## Context

Abundance aims to build an AI-powered inventory app with a passive marketplace for peer-to-peer transactions. The product vision includes:

1. **Inventory App (Single-Player Utility):** "Know what you own" via AI cataloging and search
2. **Passive Marketplace (Network Effect):** Buyers discover all cataloged items (not just active listings), sellers receive offers

**Core Strategic Question:**

Should we:

- **Option A:** Launch both inventory + marketplace simultaneously (Day 1 network effects)
- **Option B:** Launch inventory app first, add marketplace 6-9 months later (phased approach)
- **Option C:** Launch marketplace first, use inventory cataloging as seller onboarding (marketplace-led)

This ADR documents the decision to pursue **Option B (Inventory-First, Marketplace Phase 2)** and the rationale behind phasing.

---

## Decision

**We will launch in two distinct phases:**

### Phase 1 (Months 0-6): Inventory App MVP

**Scope:**
- AI cataloging (single-item + multi-item capture)
- Inventory browsing & search
- Basic organization (categories, tags, locations)
- Freemium tier structure (90-day trial, $8/month premium)
- User authentication, profile, export (PDF/CSV)
- **NO marketplace features**

**Success Criteria (Month 6 Checkpoint):**
- 5,000 active users (target metro: Austin)
- 250,000 cataloged items (50 items/user median)
- 25% Month 6 retention
- 15% premium conversion

### Phase 2 (Months 6-12): Passive Marketplace Launch

**Scope (Additive to Phase 1):**
- Passive marketplace discovery (buyers search all cataloged inventory)
- Offer & acceptance flow
- Escrow & payment processing (Stripe)
- In-app messaging
- Reputation system (ratings, badges)
- Trust & safety (Tier 1 verification: phone/email)

**Prerequisites:**
- Phase 1 success criteria met
- Minimum inventory density: 500+ items per ZIP code
- Trust & safety infrastructure validated

**Success Criteria (Month 12 Checkpoint):**
- $50K+ GMV/month (gross merchandise value)
- 85% transaction completion rate
- 10% seller activation (Organizers who accept 1+ offer)
- LTV:CAC > 2:1

---

## Rationale

### Why Inventory-First (Not Simultaneous Launch)

**1. Critical Mass Problem (Marketplace Chicken-and-Egg)**

**Problem:**
- Marketplaces require liquidity on both sides: Buyers need inventory, Sellers need buyers
- Launching marketplace on Day 1 with < 100 users = 0 transactions (no liquidity)
- Even with 1,000 users, if catalog depth is shallow (10 items/user), buyers search and find nothing → churn

**Data:**
- Competitive analysis (Facebook Marketplace, OfferUp): 40-60% of searches yield no results due to sparse inventory
- Abundance passive marketplace requires 10-100× more cataloged items than active listings (every item = potential sale)
- Minimum viable liquidity: 500+ items per ZIP code (10-20 sellers × 25-50 items each)

**Solution (Inventory-First):**
- Phase 1: Focus 100% on building cataloged inventory depth (250K items target)
- Organizers catalog for personal utility ("Know what I own"), NOT to sell → stronger retention
- By Month 6: 100+ users per ZIP, 1,000-2,000 items per ZIP → marketplace has baseline liquidity

**Outcome:**
- Marketplace launches with pre-built supply (250K items discoverable Day 1)
- Buyers immediately find items → positive first experience → retention

---

**2. Product-Market Fit Validation (Single-Player First)**

**Problem:**
- Untested assumption: Do users ACTUALLY value "effortless inventory cataloging"?
- If single-player utility is weak, users won't catalog enough items → marketplace has no supply
- Launching marketplace first masks inventory app PMF issues (users catalog to sell, not for personal value)

**Strategic Risk:**
- Marketplace fees subsidize weak inventory app → false signal
- If marketplace fails, inventory app hasn't been validated → entire product collapses

**Solution (Inventory-First):**
- Phase 1: Validate single-player utility FIRST (users pay $8/month for cataloging, not marketplace)
- Key metrics:
  - 50+ items/user (catalog depth proves utility)
  - 25% Month 6 retention (users return even without marketplace)
  - 15% premium conversion (willingness to pay for inventory features alone)

**Outcome:**
- If Phase 1 succeeds → strong foundation (users catalog for personal value, marketplace is upside)
- If Phase 1 fails → pivot or kill before investing in marketplace infrastructure

---

**3. Technical Complexity & Focus**

**Problem:**
- Marketplace requires complex infrastructure:
  - Payment processing (Stripe Connect, escrow)
  - Trust & safety (verification, reputation, disputes)
  - Messaging (real-time chat)
  - Fraud detection (velocity limits, pattern analysis)
- Estimated effort: 18 weeks for marketplace features vs. 8 weeks for inventory core
- Attempting both simultaneously = 26-week timeline (9+ months) OR quality compromises

**Solution (Inventory-First):**
- Phase 1: Ship inventory MVP in 5-6 months (MUST + SHOULD features)
- Faster time-to-market → earlier user feedback → iterate before marketplace build
- Engineering team stays focused (2 iOS engineers can deliver inventory; marketplace requires +1 backend engineer + support hire)

**Outcome:**
- Higher quality MVP (polish onboarding, AI accuracy, search speed)
- Marketplace built with real user data (search patterns, inventory distribution, demand signals)

---

**4. Unit Economics & Burn Rate**

**Problem:**
- Simultaneous launch requires:
  - Full engineering team (4-5 engineers) for 9 months before revenue
  - Higher CAC (market both inventory + marketplace value props)
  - Longer burn before marketplace revenue materializes (3-6 months to liquidity)

**Financial Model (Simultaneous Launch):**
- Month 0-9: $450K burn (5 engineers × $150K/year × 0.75 years)
- Month 9: First revenue ($5K MRR = 500 users × $8 + $150 marketplace fees)
- Cash needed: $600K (9 months + 3-month buffer)

**Financial Model (Phased Launch):**
- Month 0-6 (Phase 1): $225K burn (3 engineers × 6 months)
- Month 6: First revenue ($5K MRR from premium subscriptions)
- Month 6-12 (Phase 2): $300K burn (4 engineers + support) - $30K revenue = $270K net burn
- Cash needed: $495K (21 months total + buffer) OR $350K if revenue reinvested

**Outcome:**
- $100-150K less funding required (phased approach)
- Revenue starts 3 months earlier (premium subscriptions in Month 3 vs. marketplace in Month 9)
- Investors see traction (5K users, 15% conversion) before funding Phase 2

---

**5. User Psychology: Organizers ≠ Sellers (Persona Mismatch)**

**Problem (Validated in Stage 1.1 Analysis):**
- Target persona (Organizers) cataloged items for personal use → uncomfortable with active selling
- Traditional marketplaces require seller intent ("I want to sell this") → listing friction
- If marketplace launches Day 1, users may catalog with selling in mind → false retention signal (they'd churn when items don't sell)

**Solution (Inventory-First + Passive Marketplace):**
- Phase 1: Organizers catalog for intrinsic value ("know what I own, find it quickly")
- Retention driven by search utility, NOT marketplace potential
- Phase 2: Marketplace is passive (users receive offers, don't have to list) → no persona transition required

**Outcome:**
- Phase 1 retention is genuine (users value inventory app itself)
- Marketplace leverages existing behavior (users already cataloged 150-200 items for personal use)
- 10% seller activation = 500 passive sellers (vs. 50 active sellers if marketplace-first)

---

### Why NOT Marketplace-First (Option C)

**Considered Approach:**
- Launch marketplace Day 1, use inventory cataloging as seller onboarding ("catalog your items to list them for sale")

**Why Rejected:**

1. **Weak Single-Player Utility:**
   - Users catalog ONLY to sell → if items don't sell, they churn (no intrinsic value)
   - Retention is marketplace-dependent (vulnerable to liquidity issues)

2. **Persona Mismatch:**
   - Attracts Active Sellers (resellers, flippers) → NOT our target persona (Organizers)
   - Wrong user base for Phase 2 thesis (passive marketplace, neighborhood sharing)

3. **Competitive Positioning Failure:**
   - eBay, Facebook Marketplace, OfferUp already serve Active Sellers well
   - Abundance differentiation is "effortless cataloging + passive discovery," NOT "better listing tools"

**Decision:**
- Marketplace-first contradicts strategic positioning (ADR-001: iOS-first, privacy-first, **utility-first**)

---

## Alternatives Considered

### Alternative 1: Simultaneous Launch (Inventory + Marketplace Day 1)

**Pros:**
- Network effects start immediately (buyers + sellers grow together)
- Single launch event (marketing efficiency)
- No perceived "pivot" (users see full vision from start)

**Cons:**
- High technical complexity → longer time-to-market (9+ months)
- Chicken-and-egg problem (0 liquidity at launch)
- False PMF signals (can't isolate inventory vs. marketplace value)
- Higher burn rate ($600K vs. $495K)

**Why Rejected:**
- Risks outweigh benefits; phased approach reduces execution risk

---

### Alternative 2: Marketplace Beta (Month 3-6, Soft Launch)

**Approach:**
- Launch inventory app Month 0
- Add marketplace features incrementally (Month 3: search, Month 4: offers, Month 6: payments)
- Gradual rollout to 10% of users (beta)

**Pros:**
- Earlier marketplace validation (3 months sooner)
- Lower risk than full simultaneous launch

**Cons:**
- Still requires marketplace infrastructure in parallel with inventory iteration
- Splits engineering focus during critical PMF validation period (Month 0-6)
- Beta marketplace with thin liquidity = poor experience → false negative signal

**Why Rejected:**
- Month 6 is optimal timing (inventory depth + user base sufficient for real liquidity)
- Incremental rollout still divides focus during crucial Phase 1

---

### Alternative 3: B2B Inventory First (Rental Companies, Small Business)

**Approach:**
- Target rental companies, equipment businesses (commercial inventory management)
- Monetize via B2B SaaS pricing ($50-200/month)
- Consumer marketplace as Phase 2

**Pros:**
- Higher ACV (average contract value) → faster revenue
- Easier sales (fewer customers, higher LTV)
- Built-in inventory depth (rental companies have 500-5,000 items)

**Cons:**
- Different product requirements (multi-user accounts, invoicing, integrations)
- Longer sales cycles (3-6 months B2B vs. instant consumer)
- Strategic misalignment: Consumer network effects (neighborhood liquidity) don't apply to B2B

**Why Rejected:**
- Consumer-first aligns with passive marketplace vision (neighbors sharing/selling)
- B2B is better as Phase 3 expansion (after consumer PMF validated)

---

## Implications & Consequences

### Positive Consequences

**1. Reduced Execution Risk**
- Smaller MVP → faster iteration → earlier user feedback
- Focus 100% on nailing single-player utility (AI accuracy, search speed, onboarding)

**2. Financial Efficiency**
- Lower burn in first 6 months ($225K vs. $450K)
- Revenue starts earlier (Month 3 premium vs. Month 9 marketplace)
- Can bootstrap Phase 2 with Phase 1 revenue OR raise smaller seed round

**3. Stronger Product Foundation**
- Phase 1 retention validates genuine utility (users stay without marketplace)
- Phase 2 inherits proven cataloging UX and 250K items (instant marketplace supply)

**4. Clearer Metrics & Decision-Making**
- Month 6 checkpoint: Proceed/Pivot/Kill based on inventory PMF alone
- Avoids false signals (marketplace subsidizing weak inventory app)

---

### Negative Consequences (Risks)

**1. Delayed Network Effects**
- 6-month delay before marketplace launches → competitors could launch similar product
- Mitigation: iOS 26 Visual Intelligence (multi-item capture) is 6-12 month moat; patents on passive discovery

**2. User Expectation Management**
- Early adopters may ask "When is marketplace coming?" → need clear roadmap communication
- Mitigation: Publicly announce Phase 1 (inventory) + Phase 2 (marketplace) timeline upfront

**3. Potential Churn at Month 6**
- Some users may have been waiting for marketplace → churn if not ready
- Mitigation: Enable sharing circles (Month 6) as bridge feature (lending → marketplace)

**4. Inventory Depth Risk**
- If Phase 1 fails to reach 250K items, Phase 2 delayed further
- Mitigation: Target 50 items/user (median) × 5,000 users = 250K; adjust user acquisition if needed

---

## Validation Criteria (Month 6 Checkpoint)

### Proceed to Phase 2 (GREEN)

Must hit **ALL** of the following:

1. ✅ 5,000+ MAU (target metro)
2. ✅ 250,000+ cataloged items (50 items/user median)
3. ✅ 25%+ Month 6 retention (users stay without marketplace)
4. ✅ 15%+ premium conversion (willingness to pay for inventory alone)
5. ✅ 500+ items per ZIP code (minimum liquidity for marketplace)

**Action:** Proceed to Phase 2 marketplace build (Month 6-9)

---

### Delay Phase 2 (YELLOW)

Hit **3 of 5** criteria, but below targets:

- 3,000-4,999 MAU (close to goal)
- 150K-249K items (supply exists but thin)
- 20-24% retention (good but not great)
- 10-14% conversion (revenue exists but below target)
- 300-499 items per ZIP (sparse liquidity)

**Action:**
- Delay marketplace 3 months (Month 9 launch)
- Focus on growth: Increase CAC spend, referral programs, sharing circles
- Optimize retention: Improve search, onboarding, re-engagement

---

### Pivot or Kill (RED)

Hit **< 3 of 5** criteria, declining trends:

- < 3,000 MAU + declining growth
- < 150K items (< 30 items/user)
- < 20% retention (users don't return)
- < 10% conversion (willingness to pay is weak)

**Action:**
- **Pivot:** Explore B2B (rental companies), AI-powered insurance app, or other verticals
- **Kill:** If no viable pivot, shut down gracefully, refund users, open-source code

---

## Open Questions for Resolution

1. **Month 6 Feature Scope:**
   - Should we ship sharing circles in Month 6 (marketplace prep) or defer to Month 9?
   - Recommendation: Ship Month 6 as "soft marketplace test" (lending enables buyer discovery without payments)

2. **Geographic Expansion Timing:**
   - Should we launch 2nd metro (Portland) in Month 9 (Phase 2 start) or wait until Month 12 (Phase 2 validation)?
   - Recommendation: Month 12 (focus on single-metro liquidity first)

3. **Premium Trial Duration:**
   - A/B test 60 vs. 90 vs. 120 days, or commit to 90 days based on industry benchmarks?
   - Recommendation: A/B test (300 users per variant, Month 1-4), select winner for Month 5+ cohorts

4. **Free Tier Permanence:**
   - If user downgrades from premium to free, do they lose access to multi-item capture forever, or get 1 free multi-item/month?
   - Recommendation: 1 free multi-item/month (goodwill, reduces churn, enables occasional re-engagement)

---

## Related Decisions

**ADR-001 (Strategic Positioning):**
- iOS-first, privacy-first, metro-by-metro → aligns with inventory-first (deep, dense supply in one metro before expanding)

**ADR-002 (Platform Strategy):**
- "Come for tool, stay for network" → inventory utility must exist FIRST (Phase 1), then network (Phase 2)

**PRD-001 (MVP Scope):**
- Implements this ADR (Phase 1 features defined as MUST HAVE, Phase 2 as WON'T HAVE initially)

**FEATURES-001 (Prioritization Matrix):**
- MoSCoW categorization maps directly to Phase 1 MUST/SHOULD/COULD vs. Phase 2 scope

---

## Stakeholder Sign-Off

**Required Approvals:**

- [ ] **CEO / Product Leadership:** Approve phasing strategy, Month 6 checkpoint criteria
- [ ] **Engineering Leadership:** Confirm Phase 1 timeline (5-6 months) is achievable with 3 engineers
- [ ] **Finance / Fundraising:** Validate $350-495K funding requirement, revenue projections
- [ ] **Design Leadership:** Confirm UX flows for Phase 1 can be extended to Phase 2 without redesign

**Timeline:**
- ADR review: Week of 2025-10-28
- Final decision: 2025-10-31
- Kick-off Phase 1 build: 2025-11-04

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial draft, rationale for inventory-first phasing | Product Strategy (Stage 1.2) |

---

## Conclusion

**Decision: Launch Abundance in two phases (Inventory-First, Marketplace Phase 2)**

This phasing strategy:
- ✅ Reduces execution risk (smaller MVP, faster iteration)
- ✅ Validates single-player utility before network effects (genuine PMF)
- ✅ Builds marketplace supply BEFORE demand (250K items ready for buyers)
- ✅ Lowers burn rate ($100-150K savings)
- ✅ Aligns with strategic positioning (ADR-001, ADR-002)

**Next Steps:**
1. Engineering: Finalize Phase 1 sprint plan (22-week roadmap)
2. Design: Complete UX flows, wireframes for Phase 1 features
3. Marketing: Draft launch messaging ("Know what you own" positioning)
4. Finance: Model cash flow (Phase 1 revenue offsets Phase 2 burn)
5. Month 6 Checkpoint: Review metrics, make Phase 2 go/no-go decision

---

**This ADR will be revisited at Month 6 based on validation criteria outcomes.**
