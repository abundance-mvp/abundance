# Trust & Safety Framework: Abundance Marketplace

**Document ID:** TRUST-001
**Version:** 1.0
**Date:** 2025-10-24
**Status:** Draft for Review
**Phase:** Phase 2 (Marketplace Launch, Month 6+)
**Related Documents:** PRD-001, PERSONA-001, JOURNEY-001, business-strategy-validated.md

---

## Overview

This document defines the trust and safety architecture for Abundance's passive marketplace (Phase 2). The framework addresses identity verification, reputation systems, transaction security, dispute resolution, and privacy controls required to enable safe peer-to-peer transactions.

**Critical Context:** Abundance's passive marketplace is fundamentally different from traditional marketplaces (eBay, Facebook Marketplace):

- **Traditional:** Sellers actively list items for sale
- **Abundance:** ALL cataloged items are passively discoverable; sellers receive offers and decide whether to accept

This creates unique trust & safety challenges:
1. Sellers didn't intend to sell, may not take transaction seriously
2. Buyers discover items sellers forgot they owned (communication gap)
3. Privacy-first design: Buyer/seller identities hidden until transaction accepted

---

## Design Principles

### 1. Privacy-Preserving by Default

**Principle:** Minimize data exposure until transaction is mutually accepted.

**Implementation:**
- Anonymous hashing: Marketplace knows "Item X exists in ZIP 78701" but not "Sarah owns Item X"
- Identity reveal only after both parties consent (buyer sends offer → seller accepts → identities revealed)
- Photos/metadata visible, but owner identity hidden

**Rationale:** Organizers cataloged items for personal use, not public sale. Exposing "Sarah owns a $2,000 camera" creates security risk.

### 2. Friction-Optimized for Good Actors

**Principle:** Make transactions seamless for trustworthy users, add friction only for risk signals.

**Implementation:**
- **Low friction:** Verified users, high reputation, local transactions
- **High friction:** New users, low reputation, high-value items, cross-ZIP transactions

**Example:**
- Sarah (verified, 15 completed transactions, 5-star rating) sends offer for $30 camping stove 2 miles away → Marcus (seller) sees "Trusted Buyer" badge, accepts in 1 click
- Anonymous user (new account, no verification) sends offer for $1,500 camera → Marcus sees "New User - Verify Identity Before Meeting" warning

### 3. Escrow-First for Financial Safety

**Principle:** Money held in escrow until both parties confirm transaction complete.

**Implementation:**
- Buyer pays upfront → funds held in escrow
- Buyer/seller meet, exchange item
- Both parties confirm exchange in app → funds released to seller

**Rationale:** Prevents scams (buyer pays, seller ghosts) and disputes (item not as described).

### 4. Community-Driven Moderation

**Principle:** Trust emerges from repeated local interactions, not centralized oversight.

**Implementation:**
- Reputation scores based on completed transactions, ratings, dispute history
- Community reporting (flag suspicious users, scams)
- Automated risk detection (unusual patterns, high-value items from new users)

**Rationale:** Hyperlocal marketplace → same users transact repeatedly → reputation matters more than centralized moderation.

---

## Identity Verification

### Tier 1: Basic Verification (Required for Marketplace Access)

**Requirement:** Link one verified credential

**Options:**
1. **Phone Number (SMS Verification):**
   - User enters phone → receives 6-digit code → confirms
   - **Purpose:** Prevent multi-account abuse (1 account per phone number)
   - **Privacy:** Phone number NOT shared with other users

2. **Email Verification:**
   - User confirms email address via link
   - **Purpose:** Account recovery, communication
   - **Privacy:** Email NOT shared unless user opts in

**Gating:**
- To send offers (buyer): Phone OR email verification required
- To accept offers (seller): Phone OR email required

**Completion Time:** < 2 minutes

**User Experience:**
- Prompt appears when user first attempts to send/accept offer
- "To protect our community, verify your phone number to continue"

---

### Tier 2: Enhanced Verification (Recommended for High-Value Transactions)

**Requirement:** Link government ID or trusted third-party verification

**Options:**

1. **Government ID Verification (Stripe Identity or similar):**
   - User uploads driver's license or passport
   - AI verifies ID is valid, matches selfie
   - **Data Retention:** Stripe stores ID, Abundance receives "verified" token only
   - **Privacy:** ID details NOT shared with other users

2. **Social Verification (Future):**
   - Link Facebook, LinkedIn, or other social account
   - **Purpose:** Confirm real person with established social presence
   - **Privacy:** Only name + profile photo shared with transaction partners

3. **Payment Method Verification:**
   - Link credit card or bank account (Stripe)
   - **Purpose:** Financial accountability (harder to scam with traceable payment method)
   - **Privacy:** Card details NOT shared

**Gating:**
- **Buyers:** Recommended for transactions > $200
- **Sellers:** Recommended for accepting offers > $500

**Benefits:**
- "Verified" badge on profile
- Higher trust score → better offer acceptance rates
- Unlock higher transaction limits

**Completion Time:** 5-10 minutes

---

### Tier 3: Trusted Seller Status (Earned)

**Requirement:** Complete 10+ successful transactions with 4.5+ star rating

**Benefits:**
- "Trusted Seller" badge
- Offers auto-accepted (buyer pays → seller notified, no manual accept needed)
- Priority placement in search results
- Higher transaction limits ($5,000+)

**Revocation:**
- Automatic if rating drops below 4.0 or dispute filed

---

## Reputation System

### Reputation Score Components

**1. Transaction Completion Rate (40% weight):**
- **Formula:** (Completed transactions) / (Accepted offers)
- **Example:** Sarah accepted 20 offers, completed 18 → 90% completion rate
- **Penalty:** Accepting offers then ghosting damages reputation

**2. User Ratings (30% weight):**
- After each transaction, both parties rate each other (1-5 stars)
- **Categories:** Communication, item accuracy, timeliness, overall experience
- **Example:** Marcus buys camping stove from Sarah → rates 5 stars ("Item exactly as described, easy pickup")

**3. Dispute History (20% weight):**
- Disputes filed against user (penalty)
- Disputes filed by user (minor penalty if excessive, neutral if justified)
- **Example:** Sarah has 0 disputes in 15 transactions → high trust score

**4. Tenure & Activity (10% weight):**
- Account age (older = more trustworthy)
- Transaction volume (more transactions = more data points)
- **Example:** New user with 1 transaction = lower trust than veteran with 50 transactions

**Overall Score:** 0-100 (displayed as 1-5 stars for simplicity)

---

### Reputation Display

**Buyer View (Before Sending Offer):**

**Seller Profile (Anonymous Until Offer Accepted):**
- Star rating: ⭐⭐⭐⭐⭐ (4.8 stars, 23 transactions)
- Badges: "Verified" (Tier 2), "Trusted Seller" (Tier 3)
- Response time: "Usually responds in < 1 hour"
- Transaction completion: "98% of offers completed"

**Seller View (When Receiving Offer):**

**Buyer Profile:**
- Star rating: ⭐⭐⭐⭐ (4.2 stars, 7 transactions)
- Badges: "Verified" (Tier 1 only)
- Offer history: "Completed 6 of 7 transactions"
- Warning flags: "New user - account created 15 days ago"

---

### Reputation Abuse Prevention

**Sybil Attack (Multi-Account Abuse):**
- **Threat:** User creates fake accounts to boost own rating
- **Mitigation:** 1 phone number per account, device fingerprinting, graph analysis (detect coordinated accounts)

**Review Bombing:**
- **Threat:** Competitor creates accounts to leave negative reviews
- **Mitigation:** Only verified transactions can leave reviews; reviews from flagged accounts hidden

**Rating Manipulation:**
- **Threat:** Buyer/seller collude to inflate ratings (fake transactions)
- **Mitigation:** Escrow requirement (real money must be exchanged); pattern detection (same 2 users transact repeatedly)

---

## Transaction Security: Escrow System

### Escrow Flow

**Step 1: Buyer Sends Offer**

**UI (Buyer):**
- Search results show item: "Coleman Camping Stove - $30 - 2.3 miles away"
- Buyer taps item → detail view (seller anonymous)
- Buyer taps "Make Offer" → enters amount ($30 or custom)
- Buyer confirms payment method (Stripe)

**Backend:**
- Buyer's card authorized for $30 (NOT charged yet)
- Offer sent to seller with 48-hour expiration

**Step 2: Seller Receives Offer**

**UI (Seller - Push Notification):**
- "You have an offer! Someone wants to buy your Coleman Camping Stove for $30."

**UI (Seller - App):**
- Offer detail view:
  - Item: Coleman Camping Stove
  - Offer: $30
  - Buyer: ⭐⭐⭐⭐ (4.2 stars, 7 transactions, "Verified")
  - Actions: Accept / Decline / Counter-offer

**Seller taps "Accept"**

**Backend:**
- Buyer's card charged $30 → funds held in Stripe escrow
- Identities revealed (buyer/seller can now message)

**Step 3: Arrange Pickup**

**UI (Both Parties):**
- In-app messaging unlocked
- Suggested message: "Great! I'm available to meet this Saturday at 2pm at Central Market. Does that work?"
- Location suggestions: Public places (coffee shops, grocery store parking lots)

**Safety Prompts:**
- "Meet in a public place during daylight hours"
- "Bring a friend if possible"
- "Inspect item before confirming transaction"

**Step 4: Exchange Item**

**In-Person:**
- Buyer/seller meet at agreed location
- Buyer inspects item (confirms it's as described)
- Seller hands over item

**Step 5: Confirm Transaction**

**UI (Both Parties):**
- "Did the transaction complete successfully?"
- Buyer taps "Confirm Receipt"
- Seller taps "Confirm Handoff"

**Backend (Once BOTH Confirm):**
- Funds released from escrow to seller (minus 3% marketplace fee)
- Item marked as sold (removed from seller's inventory + marketplace listings)
- Both parties prompted to rate each other

**Escrow Hold Period:**
- Funds released immediately if both confirm
- If only 1 confirms within 24 hours → reminder sent to other party
- If neither confirms within 72 hours → auto-release with prompt to rate transaction

---

### Dispute Scenarios

**Scenario 1: Item Not as Described**

**Context:** Buyer meets seller, item has damage not mentioned in listing

**Buyer Action:**
1. Does NOT tap "Confirm Receipt"
2. Takes photo of damage in app
3. Taps "Report Issue" → selects "Item not as described"
4. Describes issue: "Listing said 'like new' but stove has large dent and rust"

**Seller Notification:**
- "Buyer reported an issue. You can offer a partial refund or cancel the transaction."

**Resolution Options:**

1. **Partial Refund (Seller Offers):**
   - Seller: "I'll refund $10 for the damage" → Buyer accepts → Escrow releases $20 to seller, $10 refunded to buyer

2. **Full Refund (Transaction Canceled):**
   - Buyer: "I don't want the item" → Seller agrees → Escrow refunds $30 to buyer, item not exchanged

3. **Escalation (Mediation Required):**
   - Parties can't agree → Abundance support reviews evidence (photos, messages) → makes final decision
   - **Timeline:** 48-72 hour resolution

**Reputation Impact:**
- If seller misrepresented item → negative rating, potential "item accuracy" warning on profile
- If buyer made false claim → negative rating, potential "abuse" flag

---

**Scenario 2: Seller Ghosts After Offer Accepted**

**Context:** Sarah accepts offer for $30 stove, funds escrowed, but never responds to messages

**Buyer Action (After 48 Hours of No Response):**
1. Taps "Report Issue" → "Seller not responding"
2. System auto-sends reminder to seller

**Seller Notification:**
- "You accepted an offer 2 days ago but haven't arranged pickup. Respond within 24 hours or the transaction will be auto-canceled."

**Auto-Resolution (After 72 Hours Total):**
- Transaction auto-canceled
- Full refund to buyer
- Seller's reputation penalized (completion rate drops)
- Seller temp-banned from accepting new offers (7 days)

---

**Scenario 3: Buyer Claims Item Never Received (Fraud Attempt)**

**Context:** Transaction completed, both parties confirmed, buyer later claims fraud

**Buyer Action:**
- Contacts Abundance support: "I never received the item, this is a scam"

**Investigation:**
1. Review transaction log:
   - Buyer confirmed receipt in app (timestamp, GPS location)
   - Seller confirmed handoff
   - Both parties rated each other 5 stars
2. Review chat history (no mention of issues)
3. **Decision:** Likely buyer's remorse or fraud attempt

**Resolution:**
- Support denies refund request
- Buyer flagged for potential abuse (if pattern emerges, account banned)

---

## Privacy & Data Protection

### Anonymity Until Transaction

**Marketplace Catalog Architecture:**

**What's Visible (Before Offer Accepted):**
- Item photo (from seller's inventory catalog)
- Item details (name, category, estimated value, condition)
- Location (ZIP code only, not exact address)
- Seller reputation (star rating, transaction count, badges)

**What's Hidden:**
- Seller's name, profile photo, contact info
- Exact address (only approximate distance: "2.3 miles away")
- Seller's other cataloged items (privacy: can't browse all of Sarah's stuff)

**Technical Implementation:**

**Database Schema (Simplified):**
```
marketplace_listings:
  - item_id: "abc123" (hash)
  - item_metadata: {...}
  - location_hash: "ZIP_78701" (anonymized)
  - seller_id_hash: "def456" (hashed until offer accepted)
  - visibility: "public" | "private"
```

**Search Query:**
- Buyer searches "camping stove" in ZIP 78701
- Backend returns items with location_hash matching ZIP, seller_id_hash hidden
- Only when offer is accepted → seller_id_hash revealed, messaging unlocked

---

### Data Minimization

**What Abundance Stores:**

**User Data:**
- Phone number (hashed, for verification only)
- Email (for communication)
- Payment method (tokenized via Stripe, Abundance never sees card numbers)
- Cataloged items (photos, metadata)
- Transaction history (buyer/seller pairs, amounts, ratings)

**What Abundance Does NOT Store:**
- Government ID images (Stripe Identity stores these, Abundance receives "verified" token only)
- Exact GPS coordinates (ZIP code level only for marketplace)
- Full message history (deleted after 90 days post-transaction)

**Data Retention:**
- Active user data: Retained indefinitely (while account active)
- Transaction history: 3 years (for dispute resolution, fraud detection)
- Deleted account data: 30-day grace period, then permanent deletion

---

### GDPR & Privacy Compliance

**User Rights:**

1. **Right to Access:** User can export all their data (cataloged items, transactions, ratings) via in-app "Download My Data"

2. **Right to Deletion:** User can delete account → all personal data erased within 30 days (except transaction history required for legal/fraud purposes, anonymized)

3. **Right to Portability:** Export format: JSON (machine-readable for import to other services)

4. **Right to Rectification:** User can edit item details, update profile info, dispute incorrect ratings

**Consent:**
- Marketplace opt-in: "Enable marketplace to allow others to find and buy your cataloged items" (OFF by default)
- Data sharing: Explicit consent before revealing identity to transaction partner
- Marketing: Opt-in only (unchecked by default)

---

## Fraud Detection & Prevention

### Automated Risk Signals

**High-Risk Transaction Flags:**

1. **New Account Activity:**
   - Account < 7 days old + high-value transaction (> $500) → manual review

2. **Velocity Limits:**
   - More than 5 offers sent in 1 hour → rate limit (prevents spam)
   - More than 3 high-value items (> $500) listed in 1 day → fraud review (could be stolen goods)

3. **Geographic Anomalies:**
   - User's cataloged items are in Austin, TX but suddenly accepting offers in Seattle, WA → suspicious (account takeover?)

4. **Payment Failures:**
   - Buyer's card declined 3+ times → temp ban from sending offers (likely stolen card)

5. **Reputation Manipulation:**
   - Same 2 users complete 10+ transactions in short period → graph analysis (collusion?)

**Mitigation:**
- Auto-flag for manual review
- Require enhanced verification (Tier 2)
- Temporary transaction limits (new users: max $200 per transaction until 5 completed transactions)

---

### Scam Prevention Playbook

**Common Scam: Fake Listings**

**Threat:** Scammer catalogs high-demand items they don't own, accepts offers, takes money, ghosts

**Mitigation:**
1. **Escrow:** Buyer protected (full refund if item not received)
2. **Reputation:** Scammer's completion rate tanks after first ghost → future offers rejected
3. **Pattern Detection:** Account flagged after 2 ghosted transactions → banned

**Cost to Abundance:** Stripe fees on refunded transactions (3% of $X)

---

**Common Scam: Item Swapping**

**Threat:** Seller shows genuine item in catalog photo, brings damaged/fake item to exchange

**Mitigation:**
1. **Buyer Inspection:** Buyer encouraged to inspect before confirming receipt
2. **Dispute Process:** Buyer can reject item, upload proof, get refund
3. **Reputation:** Seller's "item accuracy" score penalized if pattern emerges

---

**Common Scam: Chargeback Fraud**

**Threat:** Buyer completes transaction, receives item, then files chargeback with credit card company ("I never got it")

**Mitigation:**
1. **Confirmation Requirement:** Both parties confirm in app (evidence for chargeback dispute)
2. **GPS Verification (Future):** App logs GPS at confirmation (proves in-person meeting)
3. **Stripe Chargeback Protection:** Seller protected if evidence shows transaction confirmed

---

## Content Moderation

### Prohibited Items

**Not Allowed on Marketplace:**

1. **Illegal Items:**
   - Weapons (guns, knives), drugs, stolen goods, counterfeit items

2. **Regulated Items:**
   - Alcohol, tobacco, prescription medications (require licensing)

3. **Dangerous Items:**
   - Fireworks, hazardous chemicals, recalled products

4. **High-Fraud Items (Initially):**
   - Electronics > $1,000 (high scam risk, add in Phase 3 with enhanced protections)
   - Luxury goods (designer bags, watches) → high counterfeit risk

**Detection:**
1. **AI Moderation:** Catalog images scanned for prohibited items (gun detection, drug paraphernalia)
2. **Keyword Filtering:** Item names flagged for prohibited terms
3. **Community Reporting:** Users can flag suspicious listings

**Enforcement:**
- First offense: Item delisted, user warned
- Repeat offense: Account banned, transactions refunded

---

### Abusive Behavior

**Harassment, Hate Speech, Threats:**

**Reporting:**
- User can report messages, profiles, transactions
- "Report" button in chat, on profiles

**Review Process:**
1. Automated filter: Hate speech keywords auto-flagged
2. Human review: Support team reviews within 24 hours
3. Decision: Warning, temp ban, permanent ban

**Appeals:**
- User can appeal ban within 30 days
- Support reviews appeal, final decision within 7 days

---

## Safety Best Practices (User Education)

### In-App Safety Tips

**Displayed at Key Moments:**

1. **First Offer Sent (Buyer):**
   - "Safety tip: Meet in a public place like a coffee shop or grocery store parking lot during daylight hours."

2. **First Offer Accepted (Seller):**
   - "Safety tip: Never give out your home address. Suggest a public meeting spot."

3. **Before Meeting:**
   - "Reminder: Inspect the item before confirming receipt. If something feels wrong, trust your instincts."

---

### Recommended Meeting Locations

**In-App Suggestions (Based on ZIP Code):**

- Central Market (Austin): "Popular meetup spot, well-lit parking lot, security cameras"
- Starbucks (Main St): "Public, busy during daytime"
- Police Station Parking Lot: "Safest option for high-value items"

**Integration:**
- When arranging pickup, app suggests nearby public places
- Tap to send suggested location in chat

---

## Trust & Safety Roadmap

### Phase 2A (Marketplace MVP, Month 6-9)

**Launch Features:**
- Tier 1 verification (phone/email)
- Basic reputation system (ratings, completion rate)
- Escrow via Stripe
- In-app messaging
- Dispute process (manual support review)

**Launch Restrictions:**
- Max transaction value: $200 (reduce fraud risk during validation)
- Buyers/sellers must be in same metro (no shipping)
- Single metro launch (Austin)

---

### Phase 2B (Scale, Month 9-12)

**Enhancements:**
- Tier 2 verification (government ID via Stripe Identity)
- Trusted Seller badges
- Increase transaction limit: $500
- Automated fraud detection (velocity, pattern analysis)
- Community reporting tools

**Expansion:**
- Launch in 2nd metro (Portland)
- Cross-metro transactions (if buyer willing to travel)

---

### Phase 3 (Maturity, Year 2)

**Advanced Features:**
- GPS verification at transaction (prove in-person meeting)
- Shipping integration (USPS, UPS) for non-local transactions
- Luxury goods protection (authentication partners)
- Insurance partnership (high-value item coverage)
- Reputation gamification (badges, leaderboards)

**Platform Maturity:**
- National rollout (50+ metros)
- Transaction limit: $5,000+
- 10,000+ transactions per month (target)

---

## Success Metrics (Phase 2)

### North Star Metric: Transaction Completion Rate

**Definition:** (Completed transactions) / (Accepted offers)

**Target:** 85%+ (Month 12)

**Why This Matters:** High completion rate = trust is working; low rate = fraud, ghosting, disputes

---

### Supporting Metrics

**User Trust:**
- % Users with Tier 1 verification: 80%+ (Month 9)
- % Users with Tier 2 verification: 30%+ (Month 12)
- Average seller rating: 4.5+ stars
- Average buyer rating: 4.3+ stars

**Transaction Safety:**
- Dispute rate: < 5% of transactions
- Chargeback rate: < 1% of transactions
- Fraud rate: < 0.5% of transaction volume

**Escrow Performance:**
- Average escrow hold time: 24-48 hours
- % Transactions auto-released (both parties confirmed): 80%+
- % Requiring manual dispute resolution: < 3%

**Marketplace Health:**
- Repeat transaction rate: 40%+ of buyers complete 2+ transactions
- Seller activation: 10% of Organizers accept 1+ offer (Month 12)
- Buyer satisfaction (NPS): 50+ (Month 12)

---

## Open Questions for Human Review

1. **Transaction Limits:** Is $200 max too conservative for Phase 2A? Should we allow $500 with enhanced verification?

2. **Escrow Fees:** Should Abundance absorb Stripe fees (3% + 30¢) or pass to buyer/seller?
   - Option A: Marketplace takes 3% fee, absorbs Stripe fees (simpler)
   - Option B: Marketplace takes 1%, buyer pays Stripe fees (transparent but complex)

3. **Identity Verification Timing:** Require Tier 1 verification upfront (before marketplace access) or just-in-time (when first offer sent)?
   - Upfront: Cleaner, safer, but adds friction to onboarding
   - Just-in-time: Faster activation, but higher fraud risk

4. **Dispute Mediation:** Hire in-house support team or outsource to third-party (Stripe Disputes, PayPal Resolution)?
   - In-house: Better control, higher cost ($50K+ per support hire)
   - Outsource: Cheaper initially, less control

---

## Conclusion

This trust & safety framework balances **privacy** (anonymous until transaction), **safety** (escrow, verification, reputation), and **user experience** (low friction for trusted users).

**Critical Success Factors:**
1. Escrow must work flawlessly (any bugs = lost funds = brand death)
2. Dispute resolution must be fast (< 48 hours) and fair
3. Fraud detection must catch scams without false positives (banning good users)

**Next Steps:**
- Validate escrow flow with beta users (Month 6)
- A/B test transaction limits ($200 vs $500)
- Build fraud detection ruleset (Month 7-8)
- Hire first support/trust & safety lead (Month 8)

---

**Next Document:** Feature Prioritization Matrix (FEATURES-001) will categorize all features by phase (MVP Phase 1 vs Marketplace Phase 2).
