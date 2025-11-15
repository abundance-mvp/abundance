# UX Flow Diagrams: Abundance

**Document ID:** UX-FLOWS-001
**Version:** 1.0
**Date:** 2025-10-24
**Status:** Draft for Review
**Related Documents:** PRD-001, PERSONA-001, JOURNEY-001, FEATURES-001

---

## Overview

This document provides detailed screen-by-screen user flows for Abundance's core features. Flows are presented in text-based format suitable for developer implementation and later conversion to visual diagrams (Figma, Miro, etc.).

**Flow Notation:**
- `→` = Next screen/state
- `[ACTION]` = User interaction (tap, type, swipe)
- `{CONDITION}` = Conditional logic
- `*` = Notes/edge cases

---

## Phase 1 Flows

### Flow 1: Onboarding & First Catalog

**Goal:** User goes from app install → first "aha" moment (10 items cataloged) in < 5 minutes

---

#### Screen 1.1: Welcome Screen

**Entry Point:** User opens app for first time

**UI Elements:**
- Hero illustration (camera pointing at shelf → items appearing)
- Headline: "Know what you own"
- Subheadline: "Point your camera at a shelf. We'll catalog everything on it."
- Primary CTA: "Start Cataloging" (button)
- Secondary link: "How it works" (modal with 3-step explainer)

**User Actions:**
- `[TAP "Start Cataloging"]` → Screen 1.2 (Permissions)
- `[TAP "How it works"]` → Modal overlay → `[TAP "Got it"]` → Back to Screen 1.1

**Analytics:**
- Track % users who tap "Start" vs "How it works"
- Target: 85%+ tap "Start" directly

---

#### Screen 1.2: Camera Permission

**Entry Point:** From Screen 1.1

**UI Elements:**
- iOS native permission prompt: "Abundance would like to access your camera"
- Custom messaging (appears before prompt): "Abundance uses your camera to catalog items. Photos stay on your device unless you choose cloud features."
- CTA: "Allow Camera Access" → triggers iOS permission prompt

**User Actions:**
- `[TAP "Allow Camera Access"]` → iOS prompt → User taps "Allow" → Screen 1.3 (Account Creation)
- `[TAP "Don't Allow"]` → Error state: "Camera access required to catalog items" → Retry CTA

**Edge Cases:**
- If user denies permission, show instructions to enable in Settings

**Analytics:**
- Track permission grant rate (target: 95%+)

---

#### Screen 1.3: Account Creation

**Entry Point:** From Screen 1.2 (after camera permission granted)

**UI Elements:**
- Headline: "Create your account"
- Subheadline: "Sync your inventory across devices"
- Primary CTA: "Sign in with Apple" (button with Apple logo)
- Secondary CTA: "Continue with Email" (text link)
- Skip link: "Skip for now" (catalog anonymously)

**User Actions:**
- `[TAP "Sign in with Apple"]` → Apple auth flow → Screen 1.4 (Camera View)
- `[TAP "Continue with Email"]` → Screen 1.3a (Email Input)
- `[TAP "Skip for now"]` → Anonymous mode → Screen 1.4 (Camera View)
  - *Note: After 10 items cataloged, prompt to create account ("Save your inventory—create account?")*

**Analytics:**
- Track: Apple Sign-In (target 70%), Email (25%), Skip (5%)
- Track: Anonymous users who later create account after 10 items

---

#### Screen 1.3a: Email Account Creation (Alternative Path)

**Entry Point:** From Screen 1.3

**UI Elements:**
- Email input field
- Password input field (masked)
- CTA: "Create Account"
- Back link: "Use Apple Sign-In instead"

**User Actions:**
- `[ENTER email + password]` → `[TAP "Create Account"]` → Firebase Auth → Screen 1.4 (Camera View)
- Email verification sent async (doesn't block app usage)

**Validation:**
- Email format validation
- Password min 8 characters
- Error states: "Email already in use," "Invalid email format"

---

#### Screen 1.4: Camera View (First Catalog)

**Entry Point:** From Screen 1.3 (account created or skipped)

**UI Elements:**
- Full-screen camera viewfinder
- Onboarding overlay (first use only):
  - "Point at a shelf or group of items"
  - "Tap the button to capture"
  - Dismiss: `[TAP anywhere]` or auto-dismiss after 3 seconds
- Bottom toolbar:
  - Capture button (center, large, circular)
  - Toggle: "Single-item" / "Multi-item" (default: Multi-item if iOS 26 + iPhone 15 Pro+)
  - Gallery icon (top-right): Import photo from library

**User Actions:**
- `[POINT camera at items]` → Live preview
- `[TAP Capture button]` → Screen 1.5 (Processing)
- `[TAP Toggle]` → Switch between single/multi-item mode
- `[TAP Gallery icon]` → Photo picker → Select photo → Screen 1.5 (Processing)

**Camera Guidance (Subtle, Non-Blocking):**
- If too close: "Move back for best results"
- If poor lighting: "Improve lighting for better accuracy"
- If no items detected: "Point at items to catalog"

**Analytics:**
- Track: Multi-item vs. Single-item usage
- Track: Photo import vs. camera capture ratio

---

#### Screen 1.5: Processing (AI Analysis)

**Entry Point:** From Screen 1.4 (after capture)

**UI Elements:**
- Blurred camera view or captured image thumbnail
- Loading indicator (spinner or progress bar)
- Text: "Analyzing items..." (2-4 seconds for cloud AI, < 2 seconds for on-device)
- {IF Premium/Trial}: "Using premium AI for granular details"
- {IF Free Tier}: "Using on-device AI"

**Backend Process:**
1. Upload photo (premium) or process on-device (free)
2. AI detects items, extracts metadata
3. Shopping Graph lookup (premium only)
4. Return results

**User Experience:**
- Should feel "instant" (target: < 3 seconds perceived wait)
- If processing > 5 seconds, show progress: "Detected 8 items... analyzing details..."

**Analytics:**
- Track: Processing time (p50, p95, p99)
- Track: AI accuracy (% items correctly named)

---

#### Screen 1.6: Results Review

**Entry Point:** From Screen 1.5 (processing complete)

**UI Elements:**
- Header: "Found 11 items" (count)
- Grid view of detected items (3 columns):
  - Each card shows: Item photo (cropped from capture), name, auto-suggested category, estimated value
- Example cards:
  - "Coleman Triton 2-Burner Camping Stove" | Camping | $89
  - "DeWalt 20V Cordless Drill" | Tools | $149
  - [9 more items...]
- Actions (bottom):
  - Primary CTA: "Save All" (saves all 11 items)
  - Secondary: "Review & Edit" (allows individual edits)

**User Actions:**
- `[TAP any item card]` → Screen 1.6a (Item Detail Edit)
- `[TAP "Save All"]` → Items saved to Firestore → Screen 1.7 (Success + Next Action)
- `[SWIPE to delete item]` → Remove from batch (if AI detected junk)

**Inline Editing (Optional):**
- User can tap item name to edit inline
- User can tap category to change from dropdown

**Analytics:**
- Track: % users who "Save All" vs "Review & Edit" (target: 80% Save All = high confidence in AI)
- Track: % items edited/deleted (target: < 20% = good AI accuracy)

---

#### Screen 1.6a: Item Detail Edit (Optional Deep-Dive)

**Entry Point:** From Screen 1.6 (tap on item card)

**UI Elements:**
- Large item photo
- Editable fields:
  - Name: [text input]
  - Category: [dropdown: Camping, Tools, Kitchen, Clothing, Electronics, Sports, Home, Holiday, Other]
  - Location: [text input with suggestions: "Garage," "Closet," "Basement"]
  - Value: [currency input] {IF Premium: auto-filled, IF Free: manual entry}
  - Condition: [dropdown: Like New, Good, Fair, Poor]
  - Notes: [text area, optional]
- Actions:
  - "Save" (returns to Screen 1.6 with edits applied)
  - "Delete Item" (removes from batch)

**User Actions:**
- `[EDIT any field]` → Update item metadata
- `[TAP "Save"]` → Back to Screen 1.6 (Results Review)
- `[TAP "Delete"]` → Confirm modal → Remove item → Back to Screen 1.6

**Analytics:**
- Track: Most edited fields (name, category, value)
- Track: Average edit time (target: < 20 seconds per item)

---

#### Screen 1.7: Success + Next Action

**Entry Point:** From Screen 1.6 (after "Save All")

**UI Elements:**
- Celebration moment:
  - Checkmark animation
  - Text: "11 items added to your inventory!"
- Quick stats: "Total: 11 items, $1,247 estimated value"
- Actions:
  - Primary CTA: "Catalog More Items" (returns to Screen 1.4 Camera View)
  - Secondary CTA: "View Inventory" (goes to Screen 2.1 Inventory Home)

**User Actions:**
- `[TAP "Catalog More"]` → Screen 1.4 (Camera View)
- `[TAP "View Inventory"]` → Screen 2.1 (Inventory Home)

**Engagement Hook:**
- If user taps "Catalog More," they're in the habit-forming loop (target: 60% continue cataloging immediately)

**Analytics:**
- Track: % users who catalog more vs. view inventory
- Track: Session duration (users who catalog more = longer sessions = higher activation)

---

### Flow 2: Inventory Browsing & Search

**Goal:** User searches for an item and finds it quickly (< 10 seconds)

---

#### Screen 2.1: Inventory Home

**Entry Point:** From app launch (returning user) or Screen 1.7

**UI Elements:**
- Header:
  - App logo (top-left)
  - Search bar (prominent, top-center)
  - Profile icon (top-right)
- Summary cards (horizontal scroll):
  - "Total Items: 47"
  - "Total Value: $12,847"
  - "Categories: 8"
- Category chips (horizontal scroll):
  - "All" (default), "Camping," "Tools," "Kitchen," "Electronics," etc.
- Item grid (3 columns, infinite scroll):
  - Each card: Photo, name, category tag, value
- Floating Action Button (bottom-right):
  - Camera icon: "Catalog More" → Screen 1.4 (Camera View)

**User Actions:**
- `[TAP Search bar]` → Screen 2.2 (Search)
- `[TAP Category chip]` → Filter grid to show only that category
- `[TAP Item card]` → Screen 2.3 (Item Detail View)
- `[TAP Camera FAB]` → Screen 1.4 (Camera View)
- `[SCROLL down]` → Lazy load more items (pagination)

**Empty State (No Items Yet):**
- Illustration: Empty box
- Text: "Start cataloging your items"
- CTA: "Take First Photo" → Screen 1.4

**Analytics:**
- Track: Search usage (% users who search vs. browse)
- Track: Category filter usage

---

#### Screen 2.2: Search

**Entry Point:** From Screen 2.1 (tap search bar)

**UI Elements:**
- Search bar (active, keyboard visible)
- Recent searches (if any): "camping stove," "drill," "tent"
- Search suggestions (as user types):
  - Autocomplete: "camp..." → "camping," "camping stove," "campfire"
  - Category suggestions: "All in Camping"
- Search results (instant, updates as user types):
  - Grid view (same as Screen 2.1)
  - Empty state: "No items found. Try a different search."

**User Actions:**
- `[TYPE query]` → Results update in real-time (debounced, 300ms)
- `[TAP recent search]` → Re-run search
- `[TAP search result]` → Screen 2.3 (Item Detail View)
- `[TAP back/cancel]` → Return to Screen 2.1

**Search Algorithm:**
- Fuzzy matching (typos tolerated: "colemen" → "Coleman")
- Semantic search (category-aware: "tent" → shows all camping shelter items)
- Location search: "garage" → shows items with location "Garage"

**Analytics:**
- Track: Search query terms (top 20 queries)
- Track: Search success rate (% searches that result in item tap)
- Track: Average time to result (target: < 500ms)

---

#### Screen 2.3: Item Detail View

**Entry Point:** From Screen 2.1 or 2.2 (tap item)

**UI Elements:**
- Large item photo (swipeable if multiple photos)
- Item metadata:
  - Name (editable)
  - Category tag
  - Location (editable)
  - Value (editable if premium)
  - Condition
  - Date added
  - Notes (if any)
- Actions (bottom toolbar):
  - "Edit" (icon) → Screen 2.3a (Edit Mode)
  - "Share" (icon) → Screen 6.1 (Sharing Flow, Phase 2)
  - "Delete" (icon) → Confirm modal → Delete item

**User Actions:**
- `[SWIPE photo]` → View additional photos (if any)
- `[TAP "Edit"]` → Screen 2.3a (Edit Mode)
- `[TAP "Share"]` → Share sheet (iOS native) or custom share flow
- `[TAP "Delete"]` → Confirm: "Are you sure? This cannot be undone." → Delete → Return to Screen 2.1

**Analytics:**
- Track: % items viewed after search (engagement metric)
- Track: % items edited after creation (indicates AI accuracy issues if high)

---

#### Screen 2.3a: Edit Mode (Item Detail)

**Entry Point:** From Screen 2.3 (tap "Edit")

**UI Elements:**
- Same as Screen 1.6a (Item Detail Edit)
- All fields editable
- Additional actions:
  - "Add Photo" → Camera or photo picker → Upload additional photo
  - "Remove Photo" → Delete photo (if multiple exist)

**User Actions:**
- `[EDIT fields]` → Update metadata
- `[TAP "Save"]` → Return to Screen 2.3 (Detail View) with updates
- `[TAP "Cancel"]` → Discard changes → Return to Screen 2.3

**Validation:**
- Prevent saving if required fields empty (name, category)

---

### Flow 3: Premium Conversion (Trial End)

**Goal:** Convert free trial users to $8/month premium subscribers

---

#### Screen 3.1: Trial Expiration Modal (In-App)

**Entry Point:** Day 87 (3 days before trial ends), triggered on app open

**UI Elements:**
- Modal overlay (blocks app usage, cannot dismiss without action)
- Headline: "Your premium trial ends in 3 days"
- Content:
  - "You've cataloged **178 items** using premium features"
  - "Multi-item capture saved you an estimated **4 hours**"
  - "You've avoided **2 repurchases** ($75 saved)"
- Comparison table:
  - Free tier: "Coarse descriptions (camping stove)"
  - Premium: "Granular details (Coleman Triton CT200, $89 MSRP, purchased 2022)"
- Pricing: "$8/month or $80/year (save $16)"
- Actions:
  - Primary CTA: "Continue Premium - $8/month"
  - Secondary CTA: "See Full Comparison"
  - Tertiary link: "No thanks, downgrade to Free"

**User Actions:**
- `[TAP "Continue Premium"]` → Screen 3.2 (Payment)
- `[TAP "See Full Comparison"]` → Screen 3.1a (Comparison Detail)
- `[TAP "No thanks"]` → Confirm modal: "Are you sure? You'll lose multi-item capture and granular details." → `[CONFIRM]` → Downgrade to free tier

**Analytics:**
- Track conversion rate at this prompt (target: 15-25%)
- Track: % users who view comparison before deciding

---

#### Screen 3.1a: Comparison Detail

**Entry Point:** From Screen 3.1 (tap "See Full Comparison")

**UI Elements:**
- Full-screen comparison table:

| Feature | Free | Premium (You) |
|---------|------|---------------|
| AI Accuracy | Coarse ("camping stove") | Granular ("Coleman Triton CT200") |
| Capture Speed | Single-item only | Multi-item (10× faster) |
| Value Tracking | Manual entry | Automatic depreciation |
| Export | No | PDF/CSV |
| Shopping Graph | No | Yes (exact make/model) |

- Your Usage Stats:
  - "178 items cataloged with premium"
  - "14 multi-item captures (vs. 178 single-item taps)"
  - "4 hours saved"
- CTA: "Subscribe for $8/month"

**User Actions:**
- `[TAP "Subscribe"]` → Screen 3.2 (Payment)
- `[TAP "Back"]` → Return to Screen 3.1

---

#### Screen 3.2: Payment & Subscription

**Entry Point:** From Screen 3.1 or 3.1a (tap subscribe)

**UI Elements:**
- Plan selection:
  - Monthly: $8/month (selected by default)
  - Annual: $80/year (badge: "Save $16")
- Payment method:
  - Apple Pay (default if available)
  - Credit card input (Stripe)
- Terms:
  - "Cancel anytime. Your existing items keep premium details even if you downgrade."
- CTA: "Subscribe Now"

**User Actions:**
- `[SELECT plan]` → Highlight selection
- `[TAP "Subscribe Now"]` → Stripe payment → Confirmation → Return to Screen 2.1 (Inventory Home)
  - Success toast: "Premium activated! Thanks for subscribing."

**Error Handling:**
- Payment declined: "Payment failed. Try another card or contact support."
- Retry button

**Analytics:**
- Track: Monthly vs. Annual selection (target: 70% monthly, 30% annual)
- Track: Payment success rate (target: 95%+)

---

### Flow 4: Export to PDF/CSV (Premium Feature)

**Goal:** User exports inventory for insurance or moving

---

#### Screen 4.1: Export Options

**Entry Point:** From Screen 2.1 (Inventory Home) → `[TAP Profile icon]` → `[TAP "Export Inventory"]`

**UI Elements:**
- Headline: "Export Your Inventory"
- Export format:
  - Radio button: "PDF (with photos)" (selected by default)
  - Radio button: "CSV (spreadsheet)"
- Filter options:
  - "Export all items" (default)
  - "Export category: [dropdown]"
  - "Export location: [dropdown]"
- Preview:
  - "178 items will be exported"
  - "Estimated file size: 12 MB"
- CTA: "Export"

**User Actions:**
- `[SELECT format]` → Update preview
- `[SELECT filters]` → Update item count
- `[TAP "Export"]` → {IF Premium: Screen 4.2, IF Free: Screen 4.1a Paywall}

**Analytics:**
- Track: PDF vs. CSV usage
- Track: Filter usage (do users export by category/location?)

---

#### Screen 4.1a: Export Paywall (Free Tier)

**Entry Point:** From Screen 4.1 (free user taps "Export")

**UI Elements:**
- Modal: "Export is a Premium Feature"
- Content:
  - "Upgrade to Premium to export your inventory to PDF or CSV"
  - "Great for insurance claims, moving checklists, or estate planning"
- CTA: "Upgrade to Premium - $8/month"
- Secondary: "Not now"

**User Actions:**
- `[TAP "Upgrade"]` → Screen 3.2 (Payment)
- `[TAP "Not now"]` → Return to Screen 4.1

---

#### Screen 4.2: Export Processing & Download

**Entry Point:** From Screen 4.1 (premium user taps "Export")

**UI Elements:**
- Processing indicator: "Generating PDF... (178 items)"
- Progress bar (if large export)
- Once complete:
  - Success message: "Export ready!"
  - Preview thumbnail (PDF first page or CSV icon)
  - Actions:
    - "Share" → iOS share sheet (email, AirDrop, save to Files)
    - "Download" → Save to Files app
    - "View" → Open in-app preview

**User Actions:**
- `[TAP "Share"]` → Share sheet → Send via email, AirDrop, etc.
- `[TAP "Download"]` → Save to Files → Confirmation toast
- `[TAP "View"]` → In-app PDF/CSV viewer → `[TAP "Done"]` → Return to Screen 4.1

**Analytics:**
- Track: Export share method (email, AirDrop, Files)
- Track: Export completion rate (target: 95%)

---

## Phase 2 Flows (Marketplace)

### Flow 5: Marketplace Search & Offer (Buyer Journey)

**Goal:** Buyer searches for item, finds it nearby, sends offer in < 2 minutes

---

#### Screen 5.1: Marketplace Home (New Tab)

**Entry Point:** From app launch (if marketplace enabled) → Bottom nav: "Marketplace" tab

**UI Elements:**
- Search bar: "Search for items nearby"
- Location badge: "Searching in: Austin, TX 78701" (editable)
- Featured categories (horizontal scroll):
  - "Camping," "Tools," "Electronics," "Furniture," etc.
- Recent listings (grid view):
  - Item photo, name, price (seller's ask or auto-estimated), distance ("2.3 miles away")
  - Seller info hidden (anonymous until offer accepted)

**User Actions:**
- `[TAP Search bar]` → Screen 5.2 (Marketplace Search)
- `[TAP Category]` → Filter to category → Show grid of items
- `[TAP Item card]` → Screen 5.3 (Marketplace Item Detail)
- `[TAP Location badge]` → Edit ZIP code → Re-run search

**Marketplace Opt-In (Seller Side):**
- If user hasn't enabled marketplace for their items, show banner:
  - "Let others discover your items. Enable marketplace?"
  - `[TAP "Enable"]` → Settings → Toggle "Make my items discoverable" → Confirmation

---

#### Screen 5.2: Marketplace Search

**Entry Point:** From Screen 5.1 (tap search bar)

**UI Elements:**
- Search bar (active)
- Filters (expandable):
  - Distance: "Within 5 miles" (slider: 1-50 miles)
  - Price range: "$0 - $200" (slider)
  - Condition: All, Like New, Good, Fair
- Search results:
  - Grid view (same as Screen 5.1)
  - Sort: "Distance (nearest first)," "Price (low to high)," "Recently added"

**User Actions:**
- `[TYPE query]` → Update results
- `[ADJUST filters]` → Re-run search
- `[TAP item]` → Screen 5.3 (Marketplace Item Detail)

**Analytics:**
- Track: Search terms (demand signals)
- Track: Filter usage (distance, price, condition)

---

#### Screen 5.3: Marketplace Item Detail (Pre-Offer)

**Entry Point:** From Screen 5.1 or 5.2 (tap item)

**UI Elements:**
- Item photo (large)
- Item details:
  - Name: "Coleman Triton 2-Burner Camping Stove"
  - Category: Camping
  - Condition: Good
  - Seller's asking price: $30 (or "Make an offer" if no price set)
  - Distance: "2.3 miles away"
- Seller info (anonymous until offer accepted):
  - Star rating: ⭐⭐⭐⭐⭐ (4.8 stars, 23 transactions)
  - Badges: "Verified," "Trusted Seller"
  - Response time: "Usually responds in < 1 hour"
- CTA: "Make Offer"

**User Actions:**
- `[TAP "Make Offer"]` → {IF Buyer Verified: Screen 5.4, ELSE: Screen 5.3a Verification Prompt}
- `[TAP Back]` → Return to Screen 5.1 or 5.2

---

#### Screen 5.3a: Buyer Verification Prompt

**Entry Point:** From Screen 5.3 (unverified buyer taps "Make Offer")

**UI Elements:**
- Modal: "Verify Your Account to Send Offers"
- Content:
  - "To protect our community, verify your phone number or email."
- CTA: "Verify Now"

**User Actions:**
- `[TAP "Verify Now"]` → Verification flow (SMS or email code) → Once verified → Screen 5.4

---

#### Screen 5.4: Send Offer

**Entry Point:** From Screen 5.3 (verified buyer taps "Make Offer")

**UI Elements:**
- Item summary (photo, name)
- Offer amount:
  - Pre-filled: $30 (seller's asking price)
  - Editable: User can change to custom amount
- Optional message: "Hi! Is this still available?"
- Payment method:
  - Default payment (if saved): "Visa ending in 1234"
  - `[TAP "Change"]` → Add/change payment method (Stripe)
- Fine print:
  - "Your card will be charged when the seller accepts. Funds held in escrow until transaction confirmed."
- CTA: "Send Offer ($30)"

**User Actions:**
- `[EDIT amount]` → Update offer
- `[TYPE message]` → Add personal note
- `[TAP "Send Offer"]` → Stripe authorizes payment → Screen 5.5 (Offer Sent Confirmation)

**Validation:**
- Offer must be > $0
- Payment method required

**Analytics:**
- Track: Offer amounts (vs. asking price)
- Track: % offers with messages (personalization)

---

#### Screen 5.5: Offer Sent (Buyer Wait State)

**Entry Point:** From Screen 5.4 (offer sent)

**UI Elements:**
- Confirmation: "Offer sent!"
- Status: "Waiting for seller to respond"
- Offer details:
  - Item: Coleman Camping Stove
  - Your offer: $30
  - Seller has 48 hours to respond
- Actions:
  - "Cancel Offer" (if seller hasn't responded yet)
  - "View My Offers" → Screen 5.6 (Offer History)

**Notifications:**
- Push: "Seller accepted your offer!" → Opens Screen 5.7
- Push: "Seller declined your offer" → Opens Screen 5.5 with "Declined" status

**User Actions:**
- `[TAP "Cancel Offer"]` → Confirm modal → Cancel → Refund authorization → Return to Screen 5.1
- `[TAP "View My Offers"]` → Screen 5.6

---

#### Screen 5.6: Offer History (Buyer Side)

**Entry Point:** From Screen 5.5 or Profile → "My Offers"

**UI Elements:**
- Tabs: "Pending," "Accepted," "Completed," "Declined"
- List view:
  - Item photo, name, your offer, status, timestamp
- Example:
  - Pending: "Coleman Camping Stove - $30 - Sent 2 hours ago"
  - Accepted: "DeWalt Drill - $120 - Accepted yesterday → `[TAP to message seller]`"

**User Actions:**
- `[TAP Pending offer]` → Screen 5.5 (status + cancel option)
- `[TAP Accepted offer]` → Screen 5.7 (Messaging & Coordination)
- `[TAP Completed offer]` → Screen 5.9 (Transaction Complete + Rating)

---

#### Screen 5.7: Offer Accepted - Messaging & Coordination

**Entry Point:** From Screen 5.6 (tap accepted offer) or push notification

**UI Elements:**
- Status banner: "Offer accepted! Funds held in escrow."
- Seller info (NOW revealed):
  - Name: "Sarah C."
  - Profile photo
  - Rating: ⭐⭐⭐⭐⭐ (4.8 stars)
- In-app messaging:
  - Chat thread (real-time)
  - Pre-filled suggestion: "Great! When can we meet?"
- Location suggestions:
  - "Suggested meeting spots near you:"
  - "Central Market (2.1 miles)"
  - "Starbucks, Main St (2.5 miles)"
  - `[TAP location]` → Insert into chat
- Safety tips (expandable):
  - "Meet in a public place during daylight"
  - "Inspect item before confirming receipt"

**User Actions:**
- `[TYPE message]` → Send to seller
- `[TAP location suggestion]` → Insert "Let's meet at Central Market?"
- `[ARRANGE pickup]` → Chat back and forth until agreed
- `[TAP "Mark as Complete" button]` → Screen 5.8 (only appears after in-person meeting)

**Push Notifications:**
- "Sarah replied to your message" → Opens Screen 5.7

---

#### Screen 5.8: Confirm Transaction (Buyer Side)

**Entry Point:** From Screen 5.7 (after in-person meeting, buyer confirms receipt)

**UI Elements:**
- Headline: "Did you receive the item?"
- Item summary: "Coleman Camping Stove - $30"
- Confirmation checkbox: "I received the item and it's as described"
- CTA: "Confirm Receipt"
- Alternative: "Report a Problem" → Screen 5.8a (Dispute Flow)

**User Actions:**
- `[TAP checkbox + "Confirm Receipt"]` → Funds released from escrow to seller → Screen 5.9 (Rating)
- `[TAP "Report a Problem"]` → Screen 5.8a

---

#### Screen 5.8a: Dispute Flow (Buyer Reports Issue)

**Entry Point:** From Screen 5.8 (tap "Report a Problem")

**UI Elements:**
- Issue type (radio buttons):
  - "Item not as described"
  - "Seller didn't show up"
  - "Item is damaged"
  - "Other"
- Description (text area): "Explain the issue"
- Photo upload (optional): "Add evidence"
- CTA: "Submit Report"

**User Actions:**
- `[SELECT issue type + describe]` → `[TAP "Submit"]` → Support notified → Screen 5.8b (Dispute Pending)

---

#### Screen 5.8b: Dispute Pending

**Entry Point:** From Screen 5.8a (dispute submitted)

**UI Elements:**
- Status: "Your report is under review"
- Content: "Support will respond within 48 hours. Funds are still held in escrow."
- Actions: "Cancel Report" (if resolved outside platform)

**Resolution:**
- Support reviews → Decides refund, partial refund, or deny
- Notify buyer + seller of decision

---

#### Screen 5.9: Rate Transaction (Buyer Side)

**Entry Point:** From Screen 5.8 (after confirming receipt)

**UI Elements:**
- Headline: "How was your experience?"
- Star rating (1-5 stars): Overall
- Sub-ratings:
  - Communication: 1-5 stars
  - Item accuracy: 1-5 stars
  - Timeliness: 1-5 stars
- Optional review (text area): "Leave a comment for Sarah"
- CTA: "Submit Rating"
- Skip: "Maybe Later"

**User Actions:**
- `[SELECT stars + submit]` → Rating saved → Return to Screen 5.1
- `[TAP "Maybe Later"]` → Defer rating (prompt again after 24 hours)

**Analytics:**
- Track: Rating distribution (target: 4.5+ average)
- Track: % users who skip vs. rate

---

### Flow 6: Receive Offer & Accept (Seller Journey)

**Goal:** Seller receives offer, accepts, coordinates pickup, gets paid

---

#### Screen 6.1: Offer Notification (Push)

**Entry Point:** Buyer sends offer (Screen 5.4)

**Push Notification:**
- "You have an offer! Someone wants to buy your Coleman Camping Stove for $30."

**User Actions:**
- `[TAP notification]` → Screen 6.2 (Offer Detail)

---

#### Screen 6.2: Offer Detail (Seller Side)

**Entry Point:** From push notification or Profile → "My Offers Received"

**UI Elements:**
- Offer summary:
  - Item: Coleman Camping Stove (your item)
  - Offer amount: $30
  - Buyer info:
    - Star rating: ⭐⭐⭐⭐ (4.2 stars, 7 transactions)
    - Badges: "Verified"
    - Completion rate: "Completed 6 of 7 transactions"
  - Buyer's message: "Hi! Is this still available?"
  - Expiration: "Expires in 46 hours"
- Actions:
  - Primary CTA: "Accept Offer ($30)"
  - Secondary: "Decline"
  - Tertiary: "Counter-Offer"

**User Actions:**
- `[TAP "Accept"]` → {IF Seller Verified: Escrow charges buyer → Screen 6.3, ELSE: Screen 6.2a Verification Prompt}
- `[TAP "Decline"]` → Confirm modal → Decline → Buyer notified
- `[TAP "Counter-Offer"]` → Screen 6.2b (Counter-Offer Input)

---

#### Screen 6.2a: Seller Verification Prompt

**Entry Point:** From Screen 6.2 (unverified seller taps "Accept")

**UI Elements:**
- Modal: "Verify Your Account to Accept Offers"
- Content: "To receive payments, verify your phone number or email."
- CTA: "Verify Now"

**User Actions:**
- `[TAP "Verify Now"]` → Verification flow → Once verified → Screen 6.3

---

#### Screen 6.2b: Counter-Offer (Seller Side)

**Entry Point:** From Screen 6.2 (tap "Counter-Offer")

**UI Elements:**
- Original offer: "$30"
- Counter-offer input: [editable, pre-filled with original asking price or custom]
- Message: "Optional message to buyer"
- CTA: "Send Counter-Offer"

**User Actions:**
- `[ENTER amount + message]` → `[TAP "Send"]` → Buyer notified → Screen 6.2c (Wait for Buyer Response)

---

#### Screen 6.2c: Counter-Offer Pending

**Entry Point:** From Screen 6.2b (counter-offer sent)

**UI Elements:**
- Status: "Counter-offer sent: $35"
- "Waiting for buyer to respond (24 hours)"

**Push Notifications:**
- If buyer accepts counter: "Buyer accepted your counter-offer!" → Screen 6.3
- If buyer declines: "Buyer declined your counter-offer"

---

#### Screen 6.3: Offer Accepted - Messaging & Coordination (Seller Side)

**Entry Point:** From Screen 6.2 (accepted offer) or push notification

**UI Elements:**
- Same as Screen 5.7 (Buyer Messaging), but from seller perspective
- Status: "Offer accepted! You'll receive $29.10 ($30 - 3% fee) after transaction completes."
- Buyer info revealed: "Marcus J." + profile photo + rating
- In-app messaging
- Location suggestions

**User Actions:**
- `[CHAT with buyer]` → Arrange pickup
- `[TAP "Mark as Complete"]` → Screen 6.4 (Confirm Handoff)

---

#### Screen 6.4: Confirm Handoff (Seller Side)

**Entry Point:** From Screen 6.3 (after meeting buyer in person)

**UI Elements:**
- Headline: "Did you hand off the item?"
- Checkbox: "I gave the item to Marcus"
- CTA: "Confirm Handoff"
- Alternative: "Report a Problem" (if buyer no-showed, etc.)

**User Actions:**
- `[TAP "Confirm Handoff"]` → Wait for buyer to also confirm → Once both confirm → Funds released → Screen 6.5 (Payment Received + Rating)

**Auto-Release:**
- If only seller confirms within 24 hours, reminder sent to buyer
- If neither confirms within 72 hours, auto-release funds

---

#### Screen 6.5: Payment Received & Rate Buyer

**Entry Point:** From Screen 6.4 (both parties confirmed)

**UI Elements:**
- Celebration: "Payment received!"
- Amount: "$29.10 deposited to your account"
- Rate the buyer:
  - Star rating (1-5 stars)
  - Sub-ratings: Communication, timeliness, respectful
  - Optional review
- CTA: "Submit Rating"

**User Actions:**
- `[RATE buyer]` → Submit → Return to Marketplace Home
- Item auto-removed from seller's inventory (marked as sold)

---

## Edge Cases & Error States

### Error 1: Network Offline (Any Screen)

**Trigger:** User loses internet connection

**UI:**
- Toast notification: "No internet connection. Some features unavailable."
- Catalog still works (on-device Vision, free tier)
- Search works (cached inventory)
- Marketplace unavailable

**Recovery:**
- Auto-retry when connection restored
- Sync pending changes (cataloged items upload when online)

---

### Error 2: AI Processing Failure

**Trigger:** Cloud AI timeout or error (Screen 1.5)

**UI:**
- Error message: "Processing failed. Please try again."
- Fallback: "Use on-device AI instead?" (downgrades to free tier for this capture)

**User Actions:**
- `[TAP "Retry"]` → Re-process with cloud AI
- `[TAP "Use on-device"]` → Process with free-tier Vision (lower accuracy but faster)

---

### Error 3: Payment Failure (Screen 3.2, 5.4)

**Trigger:** Stripe declines payment

**UI:**
- Error modal: "Payment failed. Please check your card details."
- CTA: "Try Another Card"

**User Actions:**
- `[TAP "Try Another Card"]` → Add new payment method → Retry

---

### Error 4: Seller Ghosts After Accepting Offer

**Trigger:** 48 hours after offer accepted, no seller response to messages

**Auto-Action:**
- Send push to seller: "Respond to Marcus within 24 hours or the transaction will be canceled."
- If 72 hours total no response → Auto-cancel, full refund to buyer, seller reputation penalized

---

### Error 5: Both Parties Don't Confirm Transaction

**Trigger:** 72 hours after in-person meeting, neither confirms

**Auto-Action:**
- Send push to both: "Did you complete the transaction? Tap to confirm."
- If 7 days no response → Auto-release funds (assume completed, both forgot to confirm)
- Prompt both to rate anyway

---

## Accessibility & Inclusive Design

**VoiceOver Support:**
- All buttons have descriptive labels
- Images have alt text (item names)
- Search results announce "X items found"

**Dynamic Type:**
- All text scales with iOS Dynamic Type settings

**Color Contrast:**
- WCAG AA compliance (4.5:1 contrast ratio minimum)

**Haptic Feedback:**
- Capture button: Haptic on tap (confirms action)
- Success states: Gentle haptic (item saved, payment received)

---

## Analytics Events (Instrumentation)

**Onboarding:**
- `onboarding_started` (Screen 1.1 viewed)
- `permissions_granted` (camera, photos)
- `account_created` (method: Apple, Email, Anonymous)
- `first_catalog_completed` (items_count, processing_time_ms)

**Cataloging:**
- `catalog_started` (mode: single, multi)
- `catalog_completed` (items_detected, ai_accuracy_score)
- `catalog_failed` (error_type)

**Search:**
- `search_performed` (query, results_count)
- `search_result_tapped` (query, result_position)

**Premium:**
- `trial_expiration_modal_viewed`
- `premium_subscribed` (plan: monthly, annual)
- `premium_churn` (reason)

**Marketplace:**
- `marketplace_search_performed`
- `offer_sent` (item_id, offer_amount, asking_price)
- `offer_accepted` (item_id, final_amount)
- `transaction_completed` (item_id, amount, escrow_hold_time_hours)
- `dispute_filed` (issue_type)

**Retention:**
- `daily_active_user`
- `weekly_active_user`
- `session_duration` (seconds)

---

## Conclusion

These UX flows provide implementation-ready guidance for developers and designers. All flows prioritize:
- **Speed:** < 5 min to first "aha" moment
- **Clarity:** Minimal cognitive load, clear CTAs
- **Trust:** Transparent pricing, escrow, reputation
- **Safety:** Public meeting prompts, dispute resolution

**Next Steps:**
- Convert text flows to visual wireframes (Figma)
- Validate flows with user testing (Beta, Month 0-1)
- Instrument analytics events (Firebase Analytics)

---

**Next Document:** Success Metrics (METRICS-001) will define North Star metric and KPIs for each phase.
