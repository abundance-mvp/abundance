# ADR-014: Payment Strategy (Stripe vs Apple IAP)

**Status:** Proposed (Pending Decision)
**Date:** 2025-10-24
**Decision Makers:** Product Leadership, Finance, Engineering Leadership
**Related Documents:**
- PRD-001 (Pricing: $4.99-8/month premium)
- ADR-003 (MVP Scope Phasing)
- TECH-STACK-001

---

## Context

Subscription payment processing for Abundance MVP premium tier ($4.99-8/month). Need to decide between:
- **Apple In-App Purchase (IAP):** Native iOS integration, 30% App Store fee
- **Stripe:** Credit card processing, 3% fee, web sign-up flow

This ADR presents both options with recommendation for **phased approach** (start with Apple IAP, add Stripe later).

---

## Decision

**PENDING USER INPUT - Two viable options presented below:**

### Option A: Apple In-App Purchase (IAP) - Recommended for Launch

**Implementation:** StoreKit 2 (iOS 15+)
**Fee:** 30% App Store fee (15% after year 1, or if revenue < $1M/year)
**Timeline:** Launch Month 0

### Option B: Stripe + Web Sign-Up

**Implementation:** Stripe iOS SDK + Safari web sign-up
**Fee:** 2.9% + $0.30 per transaction
**Timeline:** Month 4+ (after Apple IAP validated)

### Recommended: Hybrid Approach (Phased)

1. **Phase 1 (Month 0-3):** Apple IAP only (faster to market)
2. **Phase 2 (Month 4-6):** Add Stripe web sign-up (users can choose)
3. **Phase 3 (Month 6+):** Grandfather Apple IAP users, default new users to Stripe

---

## Option A: Apple In-App Purchase (IAP)

### Implementation

**StoreKit 2 (Native iOS):**
```swift
import StoreKit

// 1. Fetch products
let products = try await Product.products(for: ["premium_monthly"])

// 2. Purchase
let result = try await products[0].purchase()

// 3. Verify receipt (Apple server)
if case .success(let verification) = result {
    // Grant premium access
}
```

**Subscription Management:**
- Renewals: Automatic (Apple handles)
- Cancellations: User manages in iOS Settings → Subscriptions
- Refunds: Apple handles (7-day no-questions-asked)

---

### Pros

1. **Native iOS UX:**
   - Users trust Apple (familiar payment flow)
   - Touch ID / Face ID authentication
   - No credit card entry (Apple Pay)

2. **App Store Approval:**
   - Easier approval (Apple prefers IAP for subscriptions)
   - No web sign-up friction (stays in-app)

3. **User Management:**
   - Apple handles renewals, cancellations, receipts
   - Less backend code (StoreKit validates receipts)

4. **Tax Compliance:**
   - Apple handles sales tax, VAT (all countries)
   - No need for tax calculation logic

---

### Cons

1. **30% Fee (15% after Year 1):**
   - User pays $8/month → Apple takes $2.40 → Abundance receives $5.60
   - After year 1 OR if revenue < $1M: 15% fee → $6.80 net revenue

2. **Complex Subscription Logic:**
   - Receipt validation (Apple server API)
   - Renewal status checks (is subscription active?)
   - Grace period handling (payment failed, retry)

3. **Limited Analytics:**
   - Apple provides basic metrics (App Store Connect)
   - Can't A/B test pricing easily

4. **App Store Lock-In:**
   - Can't offer lower price on web (App Store policy)
   - Must offer IAP if subscriptions exist

---

### Unit Economics (Apple IAP)

**Revenue (Month 6, 1,500 premium users):**
- Gross: 1,500 × $8/month = $12,000
- Apple fee (30%): -$3,600
- **Net revenue: $8,400/month**

**After Year 1 (15% fee):**
- Gross: 1,500 × $8/month = $12,000
- Apple fee (15%): -$1,800
- **Net revenue: $10,200/month**

---

## Option B: Stripe + Web Sign-Up

### Implementation

**Web Sign-Up Flow:**
1. iOS app: "Upgrade to Premium" button → Opens Safari
2. Web page (abundance.app/subscribe): Stripe Checkout
3. User enters credit card → Stripe processes payment
4. Webhook → Backend updates Firestore (`subscriptionTier: "premium"`)
5. iOS app: Firestore listener detects change → Unlocks premium features

**Stripe iOS SDK:**
```swift
import Stripe

// Option 1: Web sign-up (recommended)
UIApplication.shared.open(URL(string: "https://abundance.app/subscribe")!)

// Option 2: In-app Stripe (violates App Store policy if IAP exists)
// Cannot use if IAP is available (Apple rejects apps with dual payment)
```

---

### Pros

1. **Lower Fee (2.9% + $0.30):**
   - User pays $8/month → Stripe fee $0.53 → Abundance receives $7.47
   - **2.7× more net revenue than Apple IAP** ($7.47 vs. $5.60)

2. **Full Control:**
   - A/B test pricing ($4.99 vs. $6.99 vs. $8)
   - Custom subscription logic (pause, annual plans, lifetime)
   - Direct customer relationship (email, billing history)

3. **Better Analytics:**
   - Stripe Dashboard (churn rate, LTV, MRR)
   - Webhooks for custom logic (send email after signup)

4. **Flexible Pricing:**
   - Can offer discounts (referral codes, promotions)
   - Regional pricing (adjust for purchasing power)

---

### Cons

1. **Web Sign-Up Friction:**
   - User leaves app → Opens Safari → Re-authenticates → Enters credit card
   - Estimated conversion drop: 20-30% (vs. in-app IAP)

2. **App Store Policy Risk:**
   - Apple policy: "Apps offering subscriptions MUST offer IAP"
   - If Stripe-only: App Store rejection risk
   - Workaround: Offer both (Apple IAP + Stripe web), but can't link to Stripe in-app

3. **Tax Compliance:**
   - Must calculate sales tax, VAT (Stripe Tax add-on: +0.5% fee)
   - More backend complexity

4. **Payment Failures:**
   - Must handle declined cards, expired cards
   - Retry logic, grace period, dunning emails

---

### Unit Economics (Stripe)

**Revenue (Month 6, 1,500 premium users):**
- Gross: 1,500 × $8/month = $12,000
- Stripe fee (2.9% + $0.30): -$720
- **Net revenue: $11,280/month**

**Savings vs. Apple IAP:** $2,880/month = **$34,560/year**

---

## Hybrid Approach (Recommended)

### Phase 1 (Month 0-3): Apple IAP Only

**Rationale:**
- **Faster to market:** StoreKit 2 is simpler than Stripe web sign-up
- **App Store approval:** Easier (no web payment links)
- **User trust:** Apple payment flow is familiar

**Cost:**
- Month 1-3: 500 premium users × $5.60 net = **$2,800/month** (lower margin, but acceptable for launch)

---

### Phase 2 (Month 4-6): Add Stripe Web Sign-Up

**Implementation:**
- Add "Subscribe on Web" button (links to abundance.app/subscribe)
- Keep Apple IAP for existing users (grandfathered)
- New users can choose: Apple IAP (in-app) OR Stripe (web)

**App Store Policy Compliance:**
- Can link to web sign-up IF both options are available
- Must not say "Stripe is cheaper" (Apple prohibits price comparison)
- Neutral language: "Subscribe via web for more payment options"

**Expected Split (Month 4-6):**
- 30% new users choose Apple IAP (convenience)
- 70% new users choose Stripe (lower price OR credit card preference)

**Revenue (Month 6, 1,500 premium users):**
- Apple IAP (500 users): 500 × $5.60 = $2,800
- Stripe (1,000 users): 1,000 × $7.47 = $7,470
- **Total net revenue: $10,270/month** (vs. $8,400 Apple-only OR $11,280 Stripe-only)

---

### Phase 3 (Month 6+): Default to Stripe

**Strategy:**
- Grandfather existing Apple IAP users (no forced migration)
- New users: Default to Stripe (web sign-up)
- Apple IAP still available (for users who prefer in-app)

**Long-Term Goal:**
- 80% Stripe, 20% Apple IAP
- Net revenue converges to ~$10,500/month (1,500 users)

---

## Implementation Complexity

### Apple IAP Implementation

**Estimated Effort:** 2 weeks (iOS engineer)

**Tasks:**
1. Create subscription product in App Store Connect
2. Implement StoreKit 2 purchase flow (1 day)
3. Receipt validation (Apple server API) (2 days)
4. Subscription status checks (is user premium?) (2 days)
5. Restore purchases (user re-installs app) (1 day)
6. Testing (sandbox, production) (1 week)

---

### Stripe Implementation

**Estimated Effort:** 3 weeks (backend + iOS engineer)

**Tasks:**
1. Create Stripe account, configure products (1 day)
2. Build web sign-up page (abundance.app/subscribe) (3 days)
3. Implement Stripe Checkout (2 days)
4. Webhook handler (subscription created, cancelled, failed) (3 days)
5. iOS app: Open Safari for web sign-up (1 day)
6. Firestore subscription sync (2 days)
7. Testing (Stripe test mode, webhooks) (1 week)

---

## Alternatives Considered

### Alternative 1: RevenueCat (Subscription Management Abstraction)

**Approach:**
- RevenueCat wraps Apple IAP + Stripe
- Single SDK for both payment methods

**Pros:**
- Easier to implement (abstracts IAP + Stripe)
- Better analytics (unified dashboard)

**Cons:**
- **Cost:** 1% of revenue (on top of Apple/Stripe fees)
  - 1,500 users × $8 × 1% = $120/month extra
- **Vendor lock-in:** RevenueCat-specific API
- **Unnecessary for MVP:** Simple subscription model doesn't need abstraction

**Why Rejected:** 1% fee adds up ($1,440/year), can implement native IAP + Stripe directly

---

### Alternative 2: Paddle (Merchant of Record)

**Approach:**
- Paddle acts as reseller (handles tax, VAT, receipts)
- 5% + $0.50 per transaction

**Pros:**
- Handles all tax compliance (EU VAT, US sales tax)
- Merchant of record (Paddle, not Abundance)

**Cons:**
- **Cost:** 5% fee (vs. 2.9% Stripe)
  - 1,500 users × $8 × 5% = $600/month (vs. $360 Stripe)
- **Not available in App Store:** Paddle is web-only (no in-app option)

**Why Rejected:** Higher fees than Stripe, no App Store support

---

## Open Questions

### Question 1: Pricing ($4.99 vs. $6.99 vs. $8)

**Question:** What should premium tier cost?

**Options:**
- **$4.99/month:** Lower price, higher conversion (estimated 35%)
- **$6.99/month:** Balanced (estimated 30%)
- **$8/month:** Higher revenue per user, lower conversion (estimated 25%)

**Recommendation:** Start with $6.99 (balanced), A/B test $4.99 vs. $8 after Month 3

---

### Question 2: Annual Plan Discount

**Question:** Should we offer annual plan ($59.99/year, ~$5/month)?

**Options:**
- **Yes:** Lower churn (committed for 1 year), upfront revenue
- **No:** Simpler (monthly-only), easier to test pricing

**Recommendation:** Add annual plan in Month 6 (after monthly plan validated)

---

### Question 3: Free Trial Duration

**Question:** How long should free trial be?

**Options:**
- **90 days:** Longer trial (PRD-001 recommends 90 days)
- **30 days:** Industry standard
- **14 days:** Shorter, faster conversion

**Recommendation:** Start with 90 days (per PRD-001), A/B test 30 days after Month 3

---

## Validation Criteria (Month 6 Checkpoint)

### Apple IAP Metrics (Month 0-6)

| Metric | Target | Actual (TBD) |
|--------|--------|--------------|
| Premium conversion rate | 30% | ? |
| Monthly churn rate | <5% | ? |
| Average subscription duration | >6 months | ? |
| Net revenue per user (after Apple fee) | $5.60 | ? |

### Stripe Metrics (Month 4-6, if added)

| Metric | Target | Actual (TBD) |
|--------|--------|--------------|
| Web sign-up conversion (vs. IAP) | 70% choose Stripe | ? |
| Churn rate (Stripe vs. IAP) | <5% (same as IAP) | ? |
| Net revenue per user | $7.47 | ? |

---

## Related Decisions

**ADR-003 (MVP Scope Phasing):**
- Phase 1: Freemium pricing ($8/month premium, 90-day trial)
- Payment strategy must support freemium model

**PRD-001 (Product Requirements):**
- Premium tier: $4.99-8/month (TBD)
- Free tier: 90-day trial (all features), then limited to on-device features

---

## Stakeholder Sign-Off

**Required Approvals:**

- [ ] **Product Leadership:** Approve payment strategy (Apple IAP vs. Stripe vs. Hybrid)
- [ ] **Finance:** Approve unit economics (30% Apple fee acceptable? Or require Stripe?)
- [ ] **Engineering Leadership:** Confirm implementation timeline (2 weeks IAP, 3 weeks Stripe)
- [ ] **Legal:** Approve tax compliance strategy (Stripe Tax vs. manual)

**Timeline:**
- ADR review: Week of 2025-10-28
- **DECISION REQUIRED:** 2025-10-31
- Implementation: Month 0 (if Apple IAP) OR Month 4 (if adding Stripe)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-24 | 1.0 | Initial payment strategy options | Stage 2.1 Execution |

---

## Conclusion

**Recommendation: Start with Apple IAP (Month 0), add Stripe web sign-up (Month 4).**

This hybrid approach:
- ✅ Faster to market (Apple IAP is simpler, 2 weeks vs. 5 weeks)
- ✅ App Store compliant (offers IAP, can add web later)
- ✅ Better long-term economics (70% Stripe = higher margins)
- ✅ User choice (convenience vs. lower price)
- ⚠️ Requires 2 implementations (Apple IAP + Stripe)
- ⚠️ Complex subscription management (sync IAP + Stripe status)

**Alternative (Stripe-Only from Day 1):**
- ❌ App Store rejection risk (no IAP offered)
- ✅ Better margins from Day 1 ($7.47 vs. $5.60)
- ⚠️ 20-30% conversion drop (web sign-up friction)

**Decision Point:** Product Leadership must approve hybrid vs. Stripe-only by 2025-10-31.

---

**This ADR requires explicit approval before implementation can begin.**
