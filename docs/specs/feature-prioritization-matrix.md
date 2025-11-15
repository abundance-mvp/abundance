# Feature Prioritization Matrix: Abundance

**Document ID:** FEATURES-001
**Version:** 1.0
**Date:** 2025-10-24
**Status:** Draft for Review
**Related Documents:** PRD-001, business-strategy-validated.md, ADR-001, ADR-002

---

## Overview

This document categorizes all Abundance features using the **MoSCoW method** (Must Have, Should Have, Could Have, Won't Have) across three phases:

- **Phase 1 (MVP):** Inventory app, single-player utility (Months 0-6)
- **Phase 2:** Passive marketplace launch (Months 6-12)
- **Phase 3:** Platform maturity, advanced features (Year 2+)

**Prioritization Framework:**

- **MUST HAVE:** Core value proposition, product fails without it
- **SHOULD HAVE:** Important for user experience, strong ROI, but not launch-blocking
- **COULD HAVE:** Nice-to-have, low effort, opportunistic if time permits
- **WON'T HAVE:** Out of scope for this phase, deferred or rejected

---

## Phase 1: Inventory App MVP (Months 0-6)

**Goal:** Validate single-player utility ("Know what you own") and build supply for marketplace

**Success Criteria:**
- 5,000 active users (target metro)
- 250,000 cataloged items (50 items/user average)
- 25% Month 6 retention
- 15% premium conversion

---

### MUST HAVE (Phase 1)

These features are **launch-blocking**—product cannot ship without them.

#### 1. AI-Powered Cataloging (Core Value Prop)

**Feature:** Point camera at items → auto-detect, name, categorize, estimate value

**Sub-Features:**
- **Single-Item Capture:** Tap photo → detect 1 item → catalog
- **Multi-Item Capture (Premium):** Tap photo → detect 5-15 items → catalog all at once
- **On-Device Vision (Free Tier):** iOS 26 Visual Intelligence, coarse descriptions
- **Cloud Vision (Premium):** GPT-4V/Gemini, granular descriptions + Shopping Graph integration

**Why MUST HAVE:**
- This is the "10× better than spreadsheet" promise
- Without AI, app is just another manual inventory tool (no differentiation)
- "Aha" moment depends on this working flawlessly

**Effort:** 8 weeks (highest priority)

**Technical Dependencies:**
- iOS 26 Vision framework (on-device)
- GPT-4V or Gemini API (cloud)
- Google Shopping Graph API
- Firebase Cloud Functions for backend processing

**Risks:**
- AI accuracy < 80% → user trust breaks, immediate churn
- Multi-item detection fails → premium tier value prop collapses

**Acceptance Criteria:**
- 80%+ correct item names (measured via beta testing)
- < 5 second processing for multi-item (cloud AI)
- < 2 second for single-item (on-device)
- Graceful degradation if cloud AI fails (fallback to on-device)

---

#### 2. Inventory Browsing & Search

**Feature:** View all cataloged items, search by name/category/location

**Sub-Features:**
- **Grid View:** All items with photos, names, categories
- **List View:** Compact view for power users
- **Search:** Instant search (< 500ms) with fuzzy matching, semantic search
- **Filters:** Category, location, value range, date added
- **Sort:** Alphabetical, by value, by date, by category

**Why MUST HAVE:**
- Search is the primary retention driver (habit loop: need item → search → find)
- Without search, app is just a photo gallery (no utility beyond cataloging)

**Effort:** 3 weeks

**Technical Dependencies:**
- Firestore queries (client-side cache for offline search)
- Search indexing (Algolia or native Firestore)

**Acceptance Criteria:**
- Search results < 500ms (perceived instant)
- 90%+ search relevance (user finds item they're looking for in top 3 results)
- Offline search works (local cache)

---

#### 3. Basic Organization (Categories, Tags, Locations)

**Feature:** Assign categories, add tags, specify locations for items

**Sub-Features:**
- **Auto-Categorization:** AI suggests category (Camping, Tools, Kitchen, etc.)
- **Manual Override:** User can change category
- **Tags:** User-defined tags (e.g., "winter gear," "lent to Katie")
- **Locations:** Auto-detect room from photo context (future) or manual entry (Garage, Closet, Basement)

**Why MUST HAVE:**
- Organization is the core job-to-be-done ("I want to ORGANIZE my stuff, not just photo it")
- Categories enable useful search ("show me all camping gear")
- Locations enable fast retrieval ("Garage, Red Shelf" → find in 30 seconds)

**Effort:** 2 weeks

**Acceptance Criteria:**
- 85%+ correct auto-categorization (measured via beta)
- User can override categories in < 10 seconds
- Locations persist across sessions

---

#### 4. User Authentication & Profile

**Feature:** Sign in, create account, manage profile

**Sub-Features:**
- **Sign in with Apple** (primary, 70% adoption expected)
- **Email + Password** (fallback, 30%)
- **Anonymous Mode → Persistent Account Upgrade** (catalog without account, prompt to save after 10 items)
- **Profile:** Name, photo, email, phone (for Phase 2 marketplace)

**Why MUST HAVE:**
- Data sync across devices requires account
- Marketplace (Phase 2) requires identity
- Premium subscriptions require account

**Effort:** 1 week

**Technical Dependencies:**
- Firebase Authentication (Apple Sign-In, Email/Password)

**Acceptance Criteria:**
- < 30 second account creation
- Anonymous mode allows cataloging 10 items before account prompt
- Data persists after account creation (no loss)

---

#### 5. Freemium Tier Structure

**Feature:** Free tier (on-device Vision, single-item) vs. Premium tier ($8/month, cloud AI, multi-item)

**Sub-Features:**
- **Free Tier:**
  - On-device Vision (coarse descriptions)
  - Single-item capture
  - Unlimited items cataloged
  - Basic search
  - Photos stay on device (privacy)

- **Premium Tier ($8/month):**
  - Cloud AI (granular descriptions, Shopping Graph)
  - Multi-item capture (5-15 items per photo)
  - Value tracking & depreciation
  - Export to PDF/CSV
  - Priority support

- **90-Day Free Trial:** All users get premium features free for 90 days (habit formation before conversion decision)

**Why MUST HAVE:**
- Revenue model depends on premium conversion
- Free tier must be genuinely useful (not crippled) to build network effects for Phase 2
- 90-day trial critical for sunk cost investment (100+ cataloged items → willingness to pay)

**Effort:** 2 weeks

**Technical Dependencies:**
- Stripe subscriptions
- Feature flagging (free vs. premium)

**Acceptance Criteria:**
- Free tier works 100% offline (no server dependency)
- Premium trial auto-expires after 90 days
- Downgrade graceful (existing items keep premium details, new items use free AI)

---

### SHOULD HAVE (Phase 1)

These features are **important but not launch-blocking**—ship in first 3 months if time permits.

#### 6. Value Tracking & Estimates

**Feature:** Auto-estimate item values, track total inventory value, depreciation over time

**Sub-Features:**
- **Initial Value Estimate:** Shopping Graph returns original MSRP
- **Current Value Estimate:** Apply depreciation based on age, condition
- **Total Portfolio Value:** Sum of all items ("You own $12,847 in stuff")
- **Insurance Export:** CSV/PDF with values for homeowner's policy

**Why SHOULD HAVE:**
- Strong secondary value prop ("Know what your stuff is worth")
- Insurance export creates "holy shit" moment (justifies premium subscription)
- Depreciation tracking differentiates from competitors

**Effort:** 3 weeks

**Acceptance Criteria:**
- 70%+ accurate initial value estimates (vs. actual MSRP)
- Depreciation formula validated (Year 1: 80% value, Year 2: 60%, etc.)

**Defer If:** AI cataloging accuracy issues consume time (prioritize core over secondary)

---

#### 7. Export to PDF/CSV

**Feature:** Export cataloged items to PDF (with photos) or CSV (spreadsheet)

**Sub-Features:**
- **PDF Export:** Professional format, photos + details, insurance-ready
- **CSV Export:** Spreadsheet format for further analysis

**Why SHOULD HAVE:**
- High-value use case: Insurance claims, moving checklists, estate planning
- Creates premium conversion moment ("I need this for insurance → subscribe")

**Effort:** 1 week

**Acceptance Criteria:**
- PDF includes photos, names, values, locations
- CSV includes all metadata fields
- Export completes in < 10 seconds for 200 items

**Defer If:** Subscription infrastructure delayed (export is premium-only feature)

---

#### 8. Sharing Circles (Enabled Month 6, Marketplace Prep)

**Feature:** Share cataloged items with friends/family (read-only access)

**Sub-Features:**
- **Share Category:** "Share my camping gear with Katie" → Katie sees Sarah's camping items in her app
- **Read-Only:** Katie can browse, search Sarah's shared items, but can't edit
- **Lending Tracking (Future):** "Mark item as lent to Katie" → reminder to get it back

**Why SHOULD HAVE:**
- Validates Phase 2 use case (lending/borrowing → marketplace)
- Viral growth driver (Katie sees Sarah's inventory → downloads app)
- Tests infrastructure for marketplace (discovery, permissions)

**Effort:** 2 weeks

**Acceptance Criteria:**
- Shared items visible in recipient's app
- Sharing permissions revocable (Sarah can unshare anytime)

**Launch Timing:** Month 6 (after inventory cataloging stabilizes)

---

### COULD HAVE (Phase 1)

These features are **nice-to-have but low priority**—ship only if time permits after MUST/SHOULD.

#### 9. Smart Notifications & Re-engagement

**Feature:** Push notifications to drive cataloging, search, retention

**Examples:**
- "You haven't cataloged anything in 7 days. Add 10 more items to unlock insights."
- "Before you shop this weekend, search Abundance—you might already own it."
- "Spring cleaning season! Catalog your winter gear before storing it."

**Why COULD HAVE:**
- Retention driver, but can launch without it (email works too)
- Risk of notification fatigue if done poorly

**Effort:** 1 week

**Defer If:** Core features delayed

---

#### 10. Barcode Scanning (Alternative Input Method)

**Feature:** Scan product barcodes to auto-populate item details

**Why COULD HAVE:**
- Useful for packaged goods (electronics, books, pantry items)
- Duplicates Shopping Graph functionality (AI already extracts product details)
- Lower accuracy than photo-based AI (generic UPCs vs. specific items)

**Effort:** 2 weeks

**Defer:** Phase 2 or 3 (not core to MVP value prop)

---

#### 11. Voice Search

**Feature:** "Hey Siri, find my camping stove in Abundance"

**Why COULD HAVE:**
- Premium UX, hands-free search
- Low adoption (most users will tap search bar)

**Effort:** 1 week

**Defer:** Phase 3

---

### WON'T HAVE (Phase 1)

These features are **explicitly out of scope** for Phase 1—deferred to Phase 2/3 or rejected.

#### 12. Passive Marketplace (Deferred to Phase 2)

**Feature:** Buyers search all cataloged inventory, sellers receive offers

**Why WON'T HAVE (Phase 1):**
- Marketplace requires critical mass (5,000+ users, 250K items) before launch
- Trust & safety infrastructure not built yet (escrow, verification, disputes)
- Phase 1 focus: Build supply (cataloged items) for Phase 2 demand

**Launch:** Month 6-9 (Phase 2)

---

#### 13. Active Listing & Selling (Rejected)

**Feature:** Sellers create listings, set prices, manage inventory like eBay

**Why WON'T HAVE:**
- Contradicts passive marketplace strategy (user clarification: Organizers won't become active Sellers)
- Creates listing friction (defeats "low-effort" value prop)

**Decision:** Permanently rejected (use passive discovery instead)

---

#### 14. Social Features (Feed, Comments, Likes) (Rejected)

**Feature:** Social feed showing friends' cataloged items, like/comment on items

**Why WON'T HAVE:**
- Out of scope for inventory utility
- Privacy concerns (users don't want public feed of their possessions)
- Network effects come from sharing/marketplace, not social feed

**Decision:** Rejected unless user research shows demand

---

#### 15. Payment Integration (Deferred to Phase 2)

**Feature:** In-app payments, escrow, transaction history

**Why WON'T HAVE (Phase 1):**
- Marketplace-only feature
- Requires trust & safety infrastructure

**Launch:** Month 6-9 (Phase 2)

---

#### 16. Shipping Integration (Deferred to Phase 3)

**Feature:** Print shipping labels, track packages, USPS/UPS integration

**Why WON'T HAVE (Phase 1-2):**
- Phase 2 marketplace is hyperlocal (in-person pickup only)
- Shipping adds complexity (returns, fraud, lost packages)

**Launch:** Phase 3 (Year 2+), if demand validates

---

## Phase 2: Marketplace Launch (Months 6-12)

**Goal:** Enable passive marketplace, activate buyer/seller personas, prove unit economics

**Success Criteria:**
- 10,000 active users
- 10% of Organizers accept 1+ offer (become passive Sellers)
- 5% of users complete 1+ purchase (Buyers)
- 500+ completed transactions
- 85% transaction completion rate

---

### MUST HAVE (Phase 2)

#### 17. Passive Marketplace Discovery

**Feature:** Buyers search all cataloged inventory (not just active listings), see items with anonymous sellers

**Sub-Features:**
- **Search:** "Coleman camping stove" → shows all cataloged stoves in target ZIP
- **Filters:** Distance, price range, condition
- **Anonymity:** Seller identity hidden until offer accepted

**Why MUST HAVE:**
- This is the core Phase 2 innovation (10-100× more liquidity than active listings)
- Without this, marketplace is just another Facebook Marketplace clone

**Effort:** 4 weeks

**Technical Dependencies:**
- Anonymous hashing (seller_id_hash revealed only after offer accepted)
- ZIP-level location indexing

---

#### 18. Offer & Acceptance Flow

**Feature:** Buyers send offers, sellers accept/decline/counter

**Sub-Features:**
- **Send Offer:** Buyer enters amount, adds optional message
- **Receive Offer:** Seller sees offer with buyer reputation, expiration (48 hours)
- **Accept:** Funds escrowed, identities revealed, messaging unlocked
- **Decline:** Offer rejected, no funds charged
- **Counter-offer:** Seller proposes different price

**Why MUST HAVE:**
- Core transaction flow, marketplace doesn't work without it

**Effort:** 3 weeks

**Technical Dependencies:**
- Stripe payment authorization (charge on accept)
- Push notifications (offer received/accepted)

---

#### 19. Escrow & Payment Processing

**Feature:** Stripe-powered escrow, funds held until both parties confirm transaction

**Sub-Features:**
- **Payment Authorization:** Buyer's card authorized on offer send (not charged)
- **Charge on Accept:** Funds charged to buyer when seller accepts offer
- **Escrow Hold:** Funds held in Stripe until both parties confirm receipt/handoff
- **Release:** Funds released to seller (minus 3% marketplace fee)
- **Refunds:** Full refund if transaction canceled or disputed

**Why MUST HAVE:**
- Financial safety, prevents scams, required for trust

**Effort:** 3 weeks

**Technical Dependencies:**
- Stripe Connect (marketplace payments)
- Stripe Escrow API

**Acceptance Criteria:**
- Zero data breaches (PCI compliance via Stripe)
- < 1% failed payments (card declines, insufficient funds)

---

#### 20. In-App Messaging

**Feature:** Buyer/seller chat to arrange pickup after offer accepted

**Sub-Features:**
- **Message Thread:** 1:1 chat per transaction
- **Location Suggestions:** App suggests public meeting spots (coffee shops, grocery stores)
- **Safety Tips:** "Meet in a public place during daylight hours"

**Why MUST HAVE:**
- Coordination required (arrange pickup time/location)
- Safety features reduce liability

**Effort:** 2 weeks

**Technical Dependencies:**
- Firebase Firestore (real-time messaging)
- Push notifications (new message)

---

#### 21. Reputation System

**Feature:** Ratings, reviews, trust scores for buyers/sellers

**Sub-Features:**
- **Post-Transaction Ratings:** 1-5 stars for communication, item accuracy, timeliness
- **Reputation Score:** Aggregated score (0-100 or 1-5 stars)
- **Badges:** "Verified," "Trusted Seller," "New User"
- **Transaction History:** "23 completed transactions, 4.8 star rating"

**Why MUST HAVE:**
- Trust mechanism, reduces fraud/ghosting
- Incentivizes good behavior

**Effort:** 2 weeks

---

#### 22. Trust & Safety: Tier 1 Verification

**Feature:** Phone/email verification required to send/accept offers

**Why MUST HAVE:**
- Prevents multi-account abuse, reduces fraud

**Effort:** 1 week

**Technical Dependencies:**
- Twilio (SMS verification)
- Firebase Auth email verification

---

### SHOULD HAVE (Phase 2)

#### 23. Dispute Resolution Process

**Feature:** Buyer/seller can report issues, escalate to support, request refunds

**Sub-Features:**
- **Report Issue:** "Item not as described," "Seller ghosted," "Buyer no-show"
- **Evidence Upload:** Photos, messages
- **Manual Review:** Support team mediates, makes final decision (48-72 hours)

**Why SHOULD HAVE:**
- Inevitable disputes will occur, need resolution process
- Can launch without it (handle via email initially), but UX is poor

**Effort:** 2 weeks

**Defer If:** Transaction volume low (< 50/month), manual email support sufficient

---

#### 24. Trust & Safety: Tier 2 Verification (Government ID)

**Feature:** Upload driver's license/passport via Stripe Identity for "Verified" badge

**Why SHOULD HAVE:**
- Increases trust for high-value transactions (> $200)
- Reduces fraud

**Effort:** 1 week

**Technical Dependencies:**
- Stripe Identity API

**Defer If:** Transaction volume doesn't justify cost (Stripe Identity charges per verification)

---

### COULD HAVE (Phase 2)

#### 25. Transaction Limits & Velocity Controls

**Feature:** New users limited to $200 per transaction, 5 offers per day

**Why COULD HAVE:**
- Fraud prevention, but can launch without (manual review of high-value)

**Effort:** 1 week

---

#### 26. Community Reporting (Flag Users/Items)

**Feature:** Users can flag suspicious listings, scams, harassment

**Why COULD HAVE:**
- Useful for content moderation, but low volume initially

**Effort:** 1 week

**Defer:** Until transaction volume > 500/month

---

### WON'T HAVE (Phase 2)

#### 27. Shipping Integration (Deferred to Phase 3)

**Rationale:** Hyperlocal in-person transactions only in Phase 2

---

#### 28. Advanced AI Features (Price Recommendations, Smart Matching)

**Feature:** AI suggests optimal price, matches buyers to sellers proactively

**Why WON'T HAVE:**
- Requires large dataset (thousands of transactions) to train models
- Passive discovery already handles matching

**Defer:** Phase 3 (Year 2+)

---

## Phase 3: Platform Maturity (Year 2+)

**Goal:** National scale, advanced features, platform ecosystem

---

### COULD HAVE (Phase 3)

#### 29. Shipping Integration

**Feature:** Print labels, track packages, USPS/UPS integration

**Why Phase 3:**
- Expands addressable market beyond hyperlocal
- Requires returns, fraud handling, lost package disputes

**Effort:** 8 weeks

---

#### 30. Insurance Partnership

**Feature:** Partner with insurance companies to offer coverage for high-value items

**Example:** User catalogs $50,000 in items → app suggests insurance policy

**Effort:** 4 weeks (partnership negotiation + integration)

---

#### 31. B2B Inventory (Small Business, Rental Companies)

**Feature:** Businesses catalog rental inventory, equipment, tools

**Why Phase 3:**
- Different use case (commercial vs. personal)
- Requires invoicing, multi-user accounts, bulk operations

**Effort:** 12 weeks

---

#### 32. API & Developer Platform

**Feature:** Public API for third-party developers to build on Abundance data

**Example:** Moving company integrates Abundance to auto-quote based on cataloged items

**Effort:** 8 weeks

---

### WON'T HAVE (Ever)

#### 33. Blockchain/NFT Integration

**Rationale:** No user demand, adds complexity, contradicts privacy-first design

---

#### 34. Cryptocurrency Payments

**Rationale:** Target persona (Organizers) not crypto-native, regulatory risk, UX friction

---

## Effort Estimates & Timeline

### Phase 1 (Months 0-6)

| Priority | Feature | Effort (Weeks) | Team |
|----------|---------|----------------|------|
| MUST | AI Cataloging (Single + Multi-item) | 8 | iOS + Backend |
| MUST | Inventory Browsing & Search | 3 | iOS |
| MUST | Basic Organization (Categories, Tags, Locations) | 2 | iOS |
| MUST | User Authentication & Profile | 1 | Backend |
| MUST | Freemium Tier Structure | 2 | Backend + iOS |
| SHOULD | Value Tracking & Estimates | 3 | Backend |
| SHOULD | Export to PDF/CSV | 1 | iOS |
| SHOULD | Sharing Circles | 2 | Backend + iOS |
| **Total** | | **22 weeks** | **5.5 months (buffer included)** |

**Team Size:** 2 iOS engineers, 1 backend engineer, 1 designer, 1 PM

---

### Phase 2 (Months 6-12)

| Priority | Feature | Effort (Weeks) | Team |
|----------|---------|----------------|------|
| MUST | Passive Marketplace Discovery | 4 | Backend + iOS |
| MUST | Offer & Acceptance Flow | 3 | iOS + Backend |
| MUST | Escrow & Payment Processing | 3 | Backend (Stripe) |
| MUST | In-App Messaging | 2 | Backend + iOS |
| MUST | Reputation System | 2 | Backend + iOS |
| MUST | Tier 1 Verification | 1 | Backend |
| SHOULD | Dispute Resolution Process | 2 | Backend + iOS |
| SHOULD | Tier 2 Verification | 1 | Backend (Stripe Identity) |
| **Total** | | **18 weeks** | **4.5 months (buffer included)** |

**Team Growth:** +1 backend engineer (payments/trust & safety), +1 support lead

---

## Feature Toggles & Rollout Strategy

**Gradual Rollout:**
1. **Alpha (Internal, 10 users):** All MUST features, test for 2 weeks
2. **Beta (Closed, 100 users):** MUST + SHOULD, collect feedback, 4 weeks
3. **Public Launch (5,000 users):** All Phase 1 features, monitor metrics
4. **Marketplace Beta (Month 6, 500 users):** Phase 2 MUST only, validate escrow/trust & safety
5. **Marketplace Public (Month 9):** All Phase 2 features

**Feature Flags (Firebase Remote Config):**
- `enable_multi_item_capture` (premium only)
- `enable_marketplace_discovery` (Phase 2 gated)
- `enable_sharing_circles` (launch Month 6)
- `max_transaction_value` (start $200, increase to $500 after validation)

---

## Open Questions for Human Review

1. **Phase 1 Timeline:** Is 6 months realistic for MUST + SHOULD features with 2 iOS engineers? Should we cut SHOULD features to ship faster (4 months)?

2. **Freemium Trial Duration:** A/B test 60 vs. 90 vs. 120 days, or commit to 90 days based on industry benchmarks?

3. **Export Feature Gating:** Should PDF/CSV export be premium-only or free (goodwill gesture for insurance use case)?

4. **Sharing Circles Launch:** Month 6 (same as marketplace) or earlier (Month 3-4) to test viral growth?

5. **Barcode Scanning Priority:** Worth adding to Phase 1 COULD HAVE, or defer indefinitely?

---

## Conclusion

This prioritization matrix aligns with:
- **Strategic positioning (ADR-001):** iOS-first, privacy-first, metro-by-metro
- **Business strategy:** Inventory-first to build supply, marketplace to drive revenue
- **User needs (PERSONA-001):** Organizers need effortless cataloging + fast search; Buyers need trust + liquidity

**Next Steps:**
- Validate effort estimates with engineering team
- Confirm Phase 1 timeline (target: Month 0 → Month 6 public launch)
- Finalize feature toggles & rollout plan

---

**Next Document:** UX Flow Diagrams (UX-FLOWS-001) will detail screen-by-screen flows for core features.
