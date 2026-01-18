# Success Metrics & KPIs: Abundance

**Document ID:** METRICS-001
**Version:** 1.0
**Date:** 2025-10-24
**Status:** Draft for Review
**Related Documents:** PRD-001, business-strategy-validated.md, revenue-projections.md

---

## Overview

This document defines the metrics framework for Abundance across three phases:

- **Phase 1 (MVP, Months 0-6):** Inventory app validation
- **Phase 2 (Marketplace, Months 6-12):** Marketplace activation
- **Phase 3 (Scale, Year 2+):** National expansion

**Metrics Philosophy:**
- **One North Star Metric per phase** (primary success indicator)
- **3-5 Supporting KPIs** (operational health)
- **Leading vs. Lagging indicators** (predict vs. measure)
- **Cohort-based analysis** (Month 0 cohort retention vs. Month 3, etc.)

---

## Phase 1: Inventory App MVP (Months 0-6)

**Goal:** Validate single-player utility, build cataloged supply for marketplace

---

### North Star Metric: Items Cataloged Per Active User Per Month

**Definition:** (Total items cataloged) / (Monthly Active Users)

**Why This Metric:**
- Directly measures core value prop ("Know what you own")
- Predicts marketplace liquidity (more items cataloged = more marketplace supply)
- Indicates habit formation (users who catalog 100+ items have strong retention)

**Target:**
- Month 1: 30 items/user (initial cataloging binge)
- Month 3: 50 items/user (sustained engagement)
- Month 6: 75 items/user (power users emerge)

**Measurement:**
- Firestore: Count items WHERE `created_at` IN last 30 days, GROUP BY user
- Track p50, p75, p95 (distribution matters: 10 power users cataloging 500 items each ≠ 100 users cataloging 50 items)

**Success Criteria:**
- **Proceed to Phase 2:** 50+ items/user (Month 6 median)
- **Pivot:** < 30 items/user (low engagement, product not sticky)
- **Kill:** < 20 items/user + declining trend (no product-market fit)

---

### Supporting KPIs (Phase 1)

#### 1. Monthly Active Users (MAU)

**Definition:** Unique users who open app in last 30 days

**Target:**
- Month 1: 1,000 users (initial launch, single metro)
- Month 3: 3,000 users (organic growth + word-of-mouth)
- Month 6: 5,000 users (checkpoint for marketplace launch)

**Growth Rate:**
- Target: 30% month-over-month (compounding)
- Failure signal: < 10% MoM growth after Month 2

**Segmentation:**
- New users (first 30 days): High activity (cataloging binge)
- Retained users (30-90 days): Moderate activity (search-driven)
- Power users (90+ days): Low frequency but high value (refer friends)

---

#### 2. Week 1 Retention

**Definition:** % of new users who return to app within 7 days of install

**Target:**
- Week 1: 60% (strong onboarding, "aha" moment delivered)
- Benchmark: 40-50% is typical for productivity apps

**Why Week 1 Matters:**
- Users who don't catalog 10+ items in Week 1 rarely return
- Retention at Week 1 predicts Month 1, Month 3 retention (leading indicator)

**Measurement:**
- Cohort analysis: Install date → % who open app Day 2-7
- Firebase Analytics: `retention_7day`

**Failure Signal:**
- < 40% Week 1 retention → onboarding broken (AI accuracy, UX friction)

---

#### 3. Premium Conversion Rate

**Definition:** % of free trial users who convert to $8/month subscription after 90 days

**Target:**
- Cohort Month 0 (trial ends Month 3): 15% conversion (conservative)
- Cohort Month 3 (trial ends Month 6): 25% conversion (optimistic, product matured)

**Segmentation:**
- Power users (100+ items): 40% conversion expected
- Active searchers (10+ searches): 30% conversion
- Casual users (20-50 items): 5% conversion

**Measurement:**
- Stripe: Subscription created events
- Firestore: User tier changes (free_trial → premium_paid)

**Failure Signal:**
- < 10% conversion → premium value prop weak (multi-item capture not compelling, or trial too short)

---

#### 4. Search Frequency (Active Users)

**Definition:** Avg. searches per active user per week

**Target:**
- Month 1: 1-2 searches/week (learning to use search)
- Month 3: 2-3 searches/week (habit formed)
- Month 6: 3-4 searches/week (core retention driver)

**Why This Matters:**
- Search is the retention loop (need item → search → find → feel competent → catalog more)
- Users who search 3+ times/week have 3× higher retention than those who don't

**Measurement:**
- Firebase Analytics: `search_performed` event count / WAU

**Failure Signal:**
- < 1 search/week → users aren't finding value in search (accuracy, speed, or catalog depth issue)

---

#### 5. AI Accuracy Score

**Definition:** % of cataloged items where user does NOT edit the AI-generated name

**Target:**
- 80%+ accuracy (user trusts AI, minimal manual correction)

**Why This Matters:**
- If users have to edit 50% of items, AI feels broken → abandonment
- High accuracy = "magical" experience → word-of-mouth growth

**Measurement:**
- Firestore: Track `item.name_edited` boolean
- Calculate: (Items NOT edited) / (Total items)

**Segmentation:**
- Free tier (on-device Vision): 70-75% accuracy expected
- Premium tier (cloud AI + Shopping Graph): 85-90% accuracy expected

**Failure Signal:**
- < 70% accuracy → AI model needs improvement or user expectations misaligned

---

### Health Metrics (Phase 1)

#### Activation Rate

**Definition:** % of new users who catalog 10+ items within Week 1

**Target:** 60% (strong onboarding)

**Why:** Users who catalog 10+ items are 5× more likely to be retained at Month 1

---

#### Session Duration

**Definition:** Avg. time spent in app per session (minutes)

**Target:**
- Cataloging session: 5-10 minutes (catalog 20-30 items)
- Search session: 1-2 minutes (find item quickly)

**Why:** Long cataloging sessions = engagement; long search sessions = poor UX (should be fast)

---

#### Viral Coefficient (k)

**Definition:** Avg. number of new users each user brings via referrals/word-of-mouth

**Target:**
- Month 1-3: k = 0.2 (early adopters share with 1-2 friends)
- Month 6: k = 0.4 (sharing feature enabled, marketplace coming)

**Calculation:**
- Track referral source (attributed installs)
- Organic installs after user shares inventory (viral loop)

**Why:** k > 1 = exponential growth (viral), k < 1 = paid acquisition required

---

### Anti-Metrics (What NOT to Optimize For)

#### Total Downloads

**Why NOT:** Vanity metric, doesn't measure engagement or retention

**Better:** Monthly Active Users (MAU) = sustained usage

---

#### Total Items Cataloged (Absolute)

**Why NOT:** Can be gamed by few power users cataloging thousands of items

**Better:** Items/user (distribution matters, median > total)

---

#### Social Shares (Generic)

**Why NOT:** Shares don't equal installs or engagement

**Better:** Attributed installs from shares (actual conversions)

---

## Phase 2: Marketplace Launch (Months 6-12)

**Goal:** Activate buyer/seller personas, validate transaction economics

---

### North Star Metric: Gross Merchandise Value (GMV) Per Month

**Definition:** Total transaction value (all completed transactions) in last 30 days

**Why This Metric:**
- Directly measures marketplace economic activity
- Predicts revenue (GMV × 3% take rate = marketplace revenue)
- Indicates liquidity (high GMV = healthy two-sided market)

**Target:**
- Month 6 (marketplace soft launch): $5K GMV (100 transactions × $50 avg)
- Month 9: $25K GMV (500 transactions × $50 avg)
- Month 12: $75K GMV (1,500 transactions × $50 avg)

**Calculation:**
- SUM(transaction_amount) WHERE status = 'completed' AND completed_at IN last 30 days

**Success Criteria:**
- **Proceed to Phase 3 (Scale):** $50K+ GMV/month by Month 12, growing 20%+ MoM
- **Pivot:** < $15K GMV/month (low liquidity, need to improve trust/discovery)
- **Kill:** Declining GMV after Month 9 (marketplace not solving pain point)

---

### Supporting KPIs (Phase 2)

#### 1. Transaction Completion Rate

**Definition:** (Completed transactions) / (Accepted offers) × 100%

**Target:** 85%+ (high trust, low ghosting/disputes)

**Why This Matters:**
- Low completion rate = trust/safety issues (ghosting, scams, disputes)
- Below 70% = marketplace feels unreliable → buyer churn

**Measurement:**
- Firestore: Track offer status (sent → accepted → completed OR canceled/disputed)

**Failure Signal:**
- < 70% completion → Trust & safety interventions needed (stricter verification, escrow issues)

---

#### 2. Seller Activation Rate

**Definition:** % of Organizers (Phase 1 users) who accept 1+ offer

**Target:**
- Month 6: 5% (early marketplace, limited buyer demand)
- Month 12: 10% (marketplace matured, liquidity improved)

**Why This Matters:**
- Validates passive marketplace thesis (Organizers DO sell without active listing)
- Low activation = need to improve buyer discovery or offer flow

**Segmentation:**
- Users with 100+ items cataloged: 15% activation expected
- Users with < 50 items: 3% activation

---

#### 3. Buyer Repeat Rate

**Definition:** % of buyers who complete 2+ transactions

**Target:**
- Month 9: 30% (buyers find value, return for second purchase)
- Month 12: 40% (habit formed, prefer Abundance over Facebook Marketplace)

**Why This Matters:**
- Repeat buyers = sticky demand side (reduces CAC for future transactions)
- Low repeat rate = one-time curiosity, not sustainable

**Measurement:**
- Cohort analysis: Buyers who completed 1st transaction in Month X → % who complete 2nd in Month X+1 to X+3

---

#### 4. Average Transaction Value (ATV)

**Definition:** Median completed transaction amount

**Target:**
- Month 6-9: $30-50 (low-value items, testing marketplace)
- Month 12: $50-75 (trust increases, higher-value items traded)

**Why This Matters:**
- Higher ATV = more revenue per transaction (3% take rate scales)
- Too low (< $20) = marketplace is garage sale, not sustainable
- Too high (> $200) = fraud risk increases, need Tier 2 verification

**Segmentation:**
- Category: Electronics (high ATV), Clothing (low ATV), Tools (medium ATV)

---

#### 5. Dispute Rate

**Definition:** (Disputed transactions) / (Accepted offers) × 100%

**Target:** < 5% (low friction, high trust)

**Why This Matters:**
- High dispute rate = trust issues, poor item descriptions, scams
- Above 10% = marketplace feels unsafe → user churn

**Resolution Time:** < 48 hours (target for support response)

**Failure Signal:**
- > 10% dispute rate → Need better AI (item accuracy), seller verification, or buyer education

---

### Health Metrics (Phase 2)

#### Search-to-Offer Conversion

**Definition:** % of marketplace searches that result in offer sent

**Target:** 15-20% (buyers find what they want and act on it)

**Why:** Low conversion = poor search relevance, low inventory depth, or price mismatch

---

#### Offer Acceptance Rate

**Definition:** (Accepted offers) / (Sent offers) × 100%

**Target:** 60-70% (sellers are responsive, prices are fair)

**Why:** Low acceptance = sellers ghosting, offers too low, or notification issues

---

#### Time to Transaction Complete

**Definition:** Avg. hours from offer accepted → both parties confirm

**Target:** 24-48 hours (fast coordination, local pickup)

**Why:** Long time = friction in coordination (messaging, scheduling) or lack of urgency

---

#### Geographic Density

**Definition:** Avg. cataloged items per ZIP code (target metro)

**Target:**
- Month 6: 500+ items per ZIP (minimum for marketplace liquidity)
- Month 12: 2,000+ items per ZIP (healthy liquidity)

**Why:** Sparse inventory = buyers can't find items nearby → search failure

---

### Revenue Metrics (Phase 2)

#### Monthly Recurring Revenue (MRR)

**Sources:**
1. Premium subscriptions: $8/month × active premium users
2. Marketplace fees: 3% × GMV

**Target (Month 12):**
- Premium MRR: $10K (1,250 premium users × $8)
- Marketplace MRR: $2.25K (3% × $75K GMV)
- **Total MRR:** $12.25K

**Growth Rate:** 20-30% MoM (compounding)

---

#### Customer Acquisition Cost (CAC)

**Definition:** (Marketing spend + sales spend) / (New users acquired)

**Target:**
- Phase 1: $3-5 per user (paid ads, iOS, target metro)
- Phase 2: $2-3 per user (word-of-mouth, organic, referrals)

**Channels:**
- Paid ads (Instagram, TikTok): $4-6 CAC
- Organic (word-of-mouth, SEO): $0-1 CAC
- Referrals (friend shares inventory): $1-2 CAC

---

#### Lifetime Value (LTV)

**Definition:** Total revenue from user over their lifetime

**Calculation:**
- **Organizer (Premium):** $8/month × 18 months avg. retention = $144 LTV
- **Buyer (Marketplace):** $50 avg. transaction × 3 transactions × 3% fee = $4.50 LTV
- **Blended LTV:** $72 per user (50% premium conversion, 30% buyer activation)

**Target LTV:CAC Ratio:**
- Month 6: 1:1 (breakeven, acceptable for growth phase)
- Month 12: 2:1 (healthy, sustainable)
- Year 2: 3:1 (mature, profitable)

---

## Phase 3: Platform Maturity (Year 2+)

**Goal:** National scale, profitability, platform ecosystem

---

### North Star Metric: Net Revenue Retention (NRR)

**Definition:** (Revenue from retained cohort + expansions - churn) / (Starting cohort revenue) × 100%

**Why This Metric:**
- Measures sustainable growth (retained revenue > new revenue)
- NRR > 100% = revenue grows even if no new users acquired (gold standard)

**Target:**
- Year 2: 110% NRR (expansions from free → premium, premium → marketplace power sellers)
- Year 3: 120% NRR (ecosystem effects, B2B add-ons)

**Calculation:**
- Cohort analysis: Month 0 users → Month 12 revenue vs. Month 0 revenue
- Include: Subscription upgrades, increased marketplace activity
- Exclude: New user revenue

---

### Supporting KPIs (Phase 3)

#### National MAU

**Target:**
- Year 2: 50,000 MAU (10 metros)
- Year 3: 200,000 MAU (50 metros)

---

#### GMV Per Metro

**Target:**
- Tier 1 metros (Austin, Portland): $150K GMV/month
- Tier 2 metros (Boise, Asheville): $50K GMV/month

---

#### Multi-Metro Buyer Rate

**Definition:** % of buyers who complete transactions across multiple metros (travel, shipping enabled)

**Target:** 10% (expands addressable market)

---

## Metrics Dashboard & Reporting

### Daily Dashboard (Product Team)

**Real-Time Metrics:**
1. MAU (trailing 30 days)
2. Items cataloged today
3. Searches performed today
4. Transactions completed today (Phase 2+)
5. AI accuracy score (trailing 7 days)

**Tools:** Firebase Analytics, Mixpanel, or custom dashboard (React + Firestore)

---

### Weekly Review (Leadership)

**Key Metrics:**
1. North Star Metric (Items/user in Phase 1, GMV in Phase 2)
2. Week 1 Retention (cohort analysis)
3. Premium conversion rate (latest cohort)
4. Transaction completion rate (Phase 2+)
5. CAC and LTV (marketing efficiency)

**Format:** Google Sheets, Looker, or Mode Analytics

---

### Monthly Board Report (Investors)

**Executive Summary:**
1. North Star Metric (trend + target)
2. MAU growth (MoM %)
3. Revenue (MRR, ARR)
4. Unit economics (LTV:CAC)
5. Burn rate & runway

**Format:** 1-page slide deck

---

## Experiment Framework (A/B Testing)

### Onboarding Experiments (Phase 1)

**Experiment 1: Free Trial Duration**

**Hypothesis:** 90-day trial → higher conversion than 60-day (more sunk cost, habit formation)

**Variants:**
- A: 60-day trial
- B: 90-day trial (control)
- C: 120-day trial

**Primary Metric:** Premium conversion rate
**Secondary Metrics:** Items cataloged, retention

**Expected Result:** 90-day trial = 25% conversion, 60-day = 15%, 120-day = 28% (diminishing returns)

**Sample Size:** 300 users per variant (900 total)
**Duration:** 4 months (to observe conversions)

---

**Experiment 2: Multi-Item Capture Defaults**

**Hypothesis:** Default to multi-item → higher activation (more items cataloged in Week 1)

**Variants:**
- A: Default single-item (user must toggle to multi)
- B: Default multi-item (control)

**Primary Metric:** Items cataloged in Week 1
**Secondary Metrics:** AI accuracy, user-reported satisfaction

**Expected Result:** Multi-item default = 50 items/user Week 1, Single-item = 30 items

**Sample Size:** 200 users per variant
**Duration:** 2 weeks

---

### Marketplace Experiments (Phase 2)

**Experiment 3: Offer Expiration Time**

**Hypothesis:** 48-hour expiration → higher acceptance rate (urgency) vs. 7-day (no pressure → ghosting)

**Variants:**
- A: 24-hour expiration
- B: 48-hour expiration (control)
- C: 7-day expiration

**Primary Metric:** Offer acceptance rate
**Secondary Metrics:** Transaction completion rate, seller satisfaction

**Expected Result:** 48-hour = 65% acceptance, 7-day = 50% (sellers forget)

**Sample Size:** 150 offers per variant
**Duration:** 4 weeks

---

## Success Milestones & Go/No-Go Decisions

### Month 3 Checkpoint (Phase 1)

**Go/No-Go Decision:** Proceed to Month 6 launch OR pivot

**Go Criteria (Must Hit 3 of 4):**
1. ✅ 2,000+ MAU (target metro)
2. ✅ 40+ items/user (median)
3. ✅ 50%+ Week 1 retention
4. ✅ 75%+ AI accuracy

**Pivot Signals:**
- < 1,000 MAU + declining growth → acquisition problem (marketing, value prop)
- < 30 items/user → engagement problem (onboarding, AI accuracy, UX friction)

**Kill Signals:**
- < 500 MAU + < 20 items/user + < 30% Week 1 retention → no product-market fit

---

### Month 6 Checkpoint (Phase 1 → Phase 2 Transition)

**Go/No-Go Decision:** Launch marketplace OR delay 3 months

**Go Criteria (Must Hit ALL):**
1. ✅ 5,000+ MAU
2. ✅ 250,000+ cataloged items (50 items/user median)
3. ✅ 25%+ Month 3 retention
4. ✅ 15%+ premium conversion

**Delay Signals:**
- Inventory depth too low (< 200K items) → need more supply before marketplace

**Kill Marketplace (Keep Inventory App):**
- < 3,000 MAU → not enough users for liquidity

---

### Month 12 Checkpoint (Phase 2 → Phase 3 Transition)

**Go/No-Go Decision:** Expand to 2nd metro OR optimize current metro

**Go Criteria (Must Hit 3 of 4):**
1. ✅ $50K+ GMV/month (Austin)
2. ✅ 85%+ transaction completion rate
3. ✅ 10%+ seller activation
4. ✅ LTV:CAC > 2:1

**Optimize (Not Ready to Scale):**
- GMV < $30K → liquidity issues, improve discovery or trust
- Completion rate < 75% → trust issues, improve escrow or verification

**Kill Marketplace (Pivot to B2B or Other):**
- GMV declining after Month 9 → marketplace not solving pain point

---

## Instrumentation & Data Pipeline

### Event Tracking (Firebase Analytics)

**User Events:**
- `user_signed_up` (method: apple, email)
- `user_verified` (tier: 1, 2, 3)
- `premium_subscribed` (plan: monthly, annual)
- `premium_churned` (reason: too_expensive, not_using, other)

**Cataloging Events:**
- `catalog_started` (mode: single, multi)
- `catalog_completed` (items_count, ai_model: on_device, cloud)
- `catalog_failed` (error_type)
- `item_edited` (field: name, category, value)

**Search Events:**
- `search_performed` (query, results_count)
- `search_result_tapped` (query, result_position)
- `search_failed` (query, results_count: 0)

**Marketplace Events (Phase 2):**
- `marketplace_search` (query, results_count)
- `offer_sent` (item_id, offer_amount)
- `offer_accepted` (item_id, seller_id_hash)
- `transaction_completed` (item_id, amount, escrow_hold_hours)
- `dispute_filed` (issue_type)
- `transaction_rated` (rating: 1-5)

---

### Data Warehouse (BigQuery or Snowflake)

**Tables:**
- `users` (id, created_at, tier, verification_level)
- `items` (id, user_id, name, category, value, ai_accuracy_score)
- `searches` (id, user_id, query, results_count, timestamp)
- `transactions` (id, buyer_id, seller_id, item_id, amount, status, completed_at)
- `events` (user_id, event_name, properties_json, timestamp)

**ETL Pipeline:**
- Firebase → BigQuery (daily sync)
- Stripe → BigQuery (transaction data)
- Firestore → BigQuery (user/item snapshots)

---

## Conclusion

This metrics framework ensures:
- **Clarity:** One North Star Metric per phase (focus)
- **Actionability:** Leading indicators predict problems before they become crises
- **Accountability:** Go/No-Go criteria prevent premature scaling

**Next Steps:**
1. Implement event tracking (Firebase Analytics SDK)
2. Build daily dashboard (React + Firestore)
3. Set up cohort analysis (Mixpanel or custom)
4. Schedule weekly metrics review (product team)

---

**Next Document:** ADR-003 (MVP Scope and Phasing Decision) will formalize the rationale for Phase 1 → Phase 2 sequencing.
