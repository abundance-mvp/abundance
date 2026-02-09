# ADR-001: Strategic Positioning - iOS-First, Privacy-First, Metro-by-Metro Launch

**Status**: Approved
**Date**: 2025-10-23
**Decision Makers**: Executive Team / Product Owner
**Consulted**: Business Strategy Analyst (Stage 1.1)
**Informed**: Engineering, Design, Marketing teams

---

## Context

Abundance must make fundamental strategic choices that determine product architecture, go-to-market approach, and competitive positioning. Three interrelated decisions require resolution before engineering begins:

1. **Platform Strategy**: iOS-first vs. cross-platform from day one
2. **Privacy Architecture**: Privacy-first (on-device processing) vs. cloud-first (full image upload)
3. **Geographic Strategy**: National launch vs. metro-by-metro expansion

These decisions are deeply interconnected: iOS-first enables privacy-first architecture through Apple's Vision framework; privacy-first affects competitive positioning; geographic strategy determines network effects timeline.

### Background

**Market Context**:
- $350B+ U.S. secondhand goods market growing 16% annually
- Established marketplaces (Facebook Marketplace: 1B users, eBay: 18M sellers) dominate with massive network effects
- Inventory management apps (Sortly, Encircle) exist but failed to achieve mainstream adoption (<100K users after 8+ years)
- AI capabilities (GPT-4V, Gemini, Apple Vision framework) make comprehensive photo-based cataloging feasible for first time

**Strategic Tension**:
- **Technical Excellence vs. Market Reach**: iOS-first enables superior UX through platform integration but limits addressable market (30-40% U.S. share)
- **Privacy vs. AI Accuracy**: On-device processing preserves privacy but limits AI capabilities vs. cloud-based analysis
- **Speed vs. Network Effects**: National launch enables fastest user acquisition but prevents local density for sharing/marketplace

### Why This Decision Is Needed Now

Architecture decisions made in MVP phase lock in technical direction for 12-24 months. Platform choice (iOS vs. cross-platform) determines:
- Engineering hiring (Swift/SwiftUI vs. React Native/Flutter expertise)
- AI pipeline design (can use Vision framework or must use cloud-only)
- Privacy architecture (hybrid vs. full-cloud)
- MVP timeline (single platform faster than cross-platform)

Delaying this decision delays engineering start.

---

## Decision

Abundance will pursue a **three-part strategic positioning**:

### 1. iOS-First Platform Strategy (with rapid Android follow-on)

**Initial Launch** (Months 0-6):
- iOS-only using Swift/SwiftUI, Vision framework, and Apple Intelligence APIs
- Full access to on-device Neural Engine, VNRecognizeObjectsRequest, and latest iOS 26 capabilities
- Target iOS 26 launch window for App Store featuring opportunity

**Android Follow-On** (Months 6-9):
- Android version begins parallel development at Month 3 (not post-iOS launch)
- Committed launch timeline: 6-9 months after iOS (not 18-24 months)
- Platform-agnostic backend architecture to support both platforms
- Android version uses cloud-based AI (Google Gemini, GPT-4V) since Visual Intelligence is iOS-exclusive

**Rationale for iOS-First**:
1. **Technical Differentiation**: Apple's Vision framework + on-device Neural Engine enable privacy-preserving hybrid architecture (on-device segmentation, cloud analysis) that competitors cannot easily replicate
2. **Demographic Alignment**: iOS users have higher household income ($85K vs. $61K median), more likely to own homes with substantial possessions worth cataloging
3. **App Store Featuring**: iOS 26 launch window creates editorial placement opportunity worth $500K-2M in effective marketing spend
4. **Development Speed**: Single-platform MVP ships 2-3 months faster than cross-platform, enabling rapid behavioral validation

**Rationale for Rapid Android Follow-On**:
1. **Network Effects Requirement**: Sharing circles and marketplace require local density. iOS-only limits density by 60-70% in any geography. Android essential for network activation.
2. **Platform Dependency Mitigation**: Reduces risk of Apple API changes, feature Sherlocking, or App Store policy shifts
3. **Market Expansion**: Unlocks college student demographic (higher Android penetration), international markets
4. **Competitive Response**: If incumbents (Facebook, eBay) add AI cataloging, cross-platform reach becomes critical survival factor

### 2. Privacy-First Architecture

**Hybrid On-Device/Cloud Design**:
- **Phase 1 (On-Device)**: Original wide-angle photos of possessions never leave device
- **Phase 2 (On-Device)**: Apple Vision framework segments individual objects locally using Neural Engine
- **Phase 3 (Cloud)**: Only cropped, de-contextualized object images transmitted to cloud AI (GPT-4V, Gemini) for identification and metadata generation
- **Phase 4 (Integration)**: Structured data returned to device and synced to backend

**Privacy Advantages**:
1. **Competitive Differentiation**: Contrast with Facebook (data harvesting) and Google (cloud-first)
2. **User Trust**: Sensitive possessions (medications, financial documents, valuables) processed privately
3. **Regulatory Compliance**: GDPR, CCPA friendly; minimal PII transmission
4. **Brand Positioning**: Aligns with Apple's privacy messaging; strengthens App Store featuring pitch

**Trade-Offs Accepted**:
1. **AI Accuracy**: On-device segmentation less accurate than cloud-based vision models. Accept 5-10% accuracy reduction for privacy gain.
2. **Platform Dependency**: Hybrid architecture tightly coupled to Apple Vision framework. Mitigated by Android cloud-only fallback.
3. **Development Complexity**: Hybrid pipeline more complex than full-cloud. Accept 3-4 week longer MVP timeline.

### 3. Metro-by-Metro Geographic Expansion (NOT National Launch)

**Phase 1: Single Metro Validation** (Months 0-6)
- Launch in San Francisco or Seattle (tech early adopters, high iOS penetration, walkable urban density)
- Goal: 5,000 activated users (50+ items cataloged, monthly active)
- Enable ALL features immediately: inventory, sharing circles, marketplace (not phased rollout)
- Validate: Retention (>25% Month 6), engagement (>3 sessions/week), sharing circle formation (>30% join circles)

**Phase 2: Metro Expansion** (Months 6-12)
- If Phase 1 retention >25%: Expand to 5-10 additional metros (NYC, LA, Boston, Portland, Austin, Denver, Chicago, Seattle/SF alternate)
- If Phase 1 retention <25%: Pivot or kill (behavior problem confirmed)
- Marketplace enabled in original metro if 2,500+ active listings achieved
- Sharing circles enabled in new metros immediately (geo-fence to prevent low-density disappointment elsewhere)

**Phase 3: National Expansion** (Months 12-18)
- Expand to top 50 metros
- Android launch to accelerate density everywhere
- Marketplace activated metro-by-metro based on inventory density thresholds
- National "dark launch": Users outside target metros can catalog but sharing/marketplace features remain locked until local density achieved

**Rationale for Metro-by-Metro**:
1. **Network Effects Requirement**: Sharing circles require ~100 active users per ZIP code; marketplace requires ~1,000-5,000 listings per metro. National launch spreads users too thin to achieve density anywhere.
2. **Better Unit Economics**: Concentrated marketing in single metro more efficient than diffuse national spend. CAC estimated 30-40% lower with geographic targeting.
3. **Quality Control**: Prove sharing and marketplace work excellently in one place before scaling to avoid "ghost town" user experience (few listings, no borrowing opportunities).
4. **Capital Efficiency**: Achieve product-market fit with 5K users before scaling to 250K. Fail fast if behavioral assumptions invalid.

**Trade-Offs Accepted**:
1. **Slower Overall Growth**: Metro-by-metro expansion grows slower than viral national launch (if viral mechanics exist, which is unproven)
2. **Press/PR Challenges**: "Only available in SF" creates FOMO but also frustration. Must manage national press carefully.
3. **Competitive Intelligence**: Focused launch telegraphs strategy to incumbents. Accept that Facebook/eBay will see what Abundance is doing and may respond. But better to be excellent in one metro than mediocre everywhere.

---

## Consequences

### Benefits

**iOS-First**:
✅ Superior product quality through platform-specific integration
✅ Privacy-preserving architecture differentiates from Facebook/Google
✅ App Store featuring opportunity (worth $500K-2M marketing equivalent)
✅ Faster MVP timeline (2-3 months faster than cross-platform)
✅ Wealthier demographic (higher LTV potential)

**Privacy-First**:
✅ Competitive differentiation vs. data-harvesting incumbents
✅ User trust for cataloging sensitive possessions
✅ Regulatory compliance (GDPR, CCPA)
✅ Brand alignment with Apple privacy messaging
✅ Potential future integration with Apple Health, Home, other privacy-focused features

**Metro-by-Metro**:
✅ Achieves network effects with fewer users (5K in one metro > 50K nationally for sharing/marketplace)
✅ Better unit economics (lower CAC through geographic targeting)
✅ Quality control (prove sharing/marketplace work before scaling)
✅ Faster iteration (concentrated user feedback)
✅ Capital efficiency (validate PMF before major scaling investment)

### Risks and Mitigation

**Risk 1: Platform Dependency (Apple)**
- **Risk**: Apple changes Vision API, adds competing feature, or modifies App Store policies
- **Impact**: High (could break core functionality or business model)
- **Probability**: Medium (40% of significant change in 3 years)
- **Mitigation**:
  - Android version at Month 6-9 (reduces dependency)
  - Cloud-based AI fallback if Vision API restricted
  - Platform-agnostic backend architecture
  - Modular design allows API swapping
- **Residual Risk**: Medium

**Risk 2: Network Effects Delayed**
- **Risk**: iOS-only limits density; metro-by-metro delays national reach
- **Impact**: High (sharing/marketplace value delayed 12-18 months)
- **Probability**: Certainty (by design)
- **Mitigation**:
  - Strong single-player utility (inventory management) must carry retention during Phase 1
  - Android at Month 6-9 accelerates density
  - Friend/family circles (not geography-based) enable sharing earlier
- **Residual Risk**: High if single-player utility insufficient

**Risk 3: Incumbent Response Window**
- **Risk**: Focused launch telegraphs strategy; Facebook/eBay have 12-18 months to respond
- **Impact**: Critical (if incumbents add AI cataloging, differentiation evaporates)
- **Probability**: High (60-70% if Abundance shows traction)
- **Mitigation**:
  - Move extremely fast (achieve 250K users before Month 18)
  - Build moat through data (cataloging depth) and network (sharing circles), not just AI feature
  - Pivot messaging if incumbents respond (emphasize integration, sharing, privacy vs. pure AI)
- **Residual Risk**: High (existential threat)

**Risk 4: Metro Selection Wrong**
- **Risk**: SF/Seattle don't represent broader market; success there doesn't predict national success
- **Impact**: Medium (delayed learning, capital waste)
- **Probability**: Medium (30-40%)
- **Mitigation**:
  - Choose SF or Seattle based on data (iOS penetration, sustainability mindset, tech adoption), not just proximity
  - Rapid expansion to diverse metros in Phase 2 (LA, Austin, Boston) to validate across demographics
  - Cohort analysis: Track which personas/behaviors predict success
- **Residual Risk**: Low-Medium

**Risk 5: AI Accuracy Trade-Off**
- **Risk**: On-device segmentation less accurate than cloud-based vision; user frustration
- **Impact**: Medium (affects "magic" perception)
- **Probability**: Medium (40%)
- **Mitigation**:
  - A/B test hybrid vs. full-cloud pipelines to quantify accuracy trade-off
  - User education: Position privacy as feature, not constraint
  - Easy correction UI; confidence scores (only show high-confidence IDs)
  - Continuous improvement through user feedback loop
- **Residual Risk**: Low-Medium

### Long-Term Implications

**Positive**:
- Strong privacy brand positioning creates differentiation for 3-5 years (hard for competitors to match without similar architecture)
- Metro-by-metro expansion creates replicable playbook: achieve density, activate network effects, expand
- iOS-first → Android → Web progression mirrors Instagram, Pinterest, successful consumer apps
- Platform-agnostic backend supports future expansion (web, smart home integrations, B2B white-label)

**Negative**:
- iOS-first positioning may create "premium/exclusive" brand perception (good for revenue, bad for mass market reach)
- Privacy-first architecture limits future monetization options (can't harvest data for ads like Facebook)
- Metro-by-metro delays revenue generation (marketplace fees kick in slower)
- Platform dependency on Apple creates ongoing negotiation/compliance burden

---

## Alternatives Considered

### Alternative 1: Cross-Platform from Day One (React Native / Flutter)

**Description**: Launch iOS and Android simultaneously using cross-platform framework

**Pros**:
✅ Maximum addressable market from Day 1 (70%+ smartphone owners)
✅ Faster network effects (larger user base achieves density quicker)
✅ Reduced platform dependency risk (not locked to Apple)
✅ Single codebase easier to maintain than two native apps

**Cons**:
❌ Cannot use Apple Vision framework (iOS-exclusive) → full-cloud AI only → no privacy differentiation
❌ Lower product quality (React Native/Flutter UX inferior to native Swift/SwiftUI)
❌ 2-3 month longer MVP timeline (cross-platform complexity)
❌ No App Store featuring opportunity (not showcasing latest iOS capabilities)
❌ More fragmentation (Android device variety), higher QA burden

**Why Rejected**:
Trade-off is wrong. Sacrifices technical differentiation (privacy-preserving architecture) and App Store featuring ($500K-2M value) for faster network effects. But network effects only matter if product is good enough to retain users. Better to have excellent product on one platform than mediocre product on two platforms.

**Reconsideration Trigger**: If Apple announces competing feature or restricts Vision API, immediately shift to cross-platform.

---

### Alternative 2: Cloud-First Architecture (Full Image Upload)

**Description**: Upload full wide-angle photos to cloud, process entirely server-side with state-of-the-art vision models

**Pros**:
✅ Best AI accuracy (GPT-4V, Google Gemini Multimodal at full resolution)
✅ Platform-agnostic (works equally well iOS/Android/Web)
✅ Simpler architecture (no hybrid on-device/cloud coordination)
✅ Easier to iterate (change models without app updates)

**Cons**:
❌ Privacy concerns (full photos of personal spaces uploaded to cloud)
❌ No differentiation from Facebook/Google (they already do this)
❌ Larger data transmission (costs, latency, requires good connectivity)
❌ GDPR/CCPA compliance more complex (storing sensitive photos)
❌ User trust barrier (cataloging medications, valuables, financial docs)

**Why Rejected**:
Privacy is core brand differentiation vs. Facebook/Google. Cloud-first architecture eliminates this advantage and increases user trust barrier for cataloging sensitive possessions. Hybrid approach trades 5-10% accuracy for meaningful privacy gain and competitive positioning.

**Reconsideration Trigger**: If user research shows privacy concerns are minimal and users prefer maximum accuracy, revisit cloud-first.

---

### Alternative 3: National Launch with Feature Gating

**Description**: Launch nationally but "dark launch" sharing/marketplace until local density achieved

**Pros**:
✅ Maximum user acquisition (all geographies accessible)
✅ Viral mechanics can work nationally (if they exist)
✅ No "FOMO frustration" from metro-only availability
✅ Broad data on which geographies organically gain traction

**Cons**:
❌ 95% of users experience inventory-only (weakest value prop)
❌ Network effects never activate (users spread too thin)
❌ Higher CAC (national marketing less efficient than geo-targeted)
❌ "Ghost town" marketplace (few listings per metro)
❌ Support burden higher (users asking why sharing/marketplace dark)

**Why Rejected**:
Historical evidence shows geographic network effects (sharing, local marketplace) require concentrated density. Nextdoor, Uber, Lyft all succeeded through metro-by-metro. Facebook Marketplace succeeded because Facebook already had 1B+ users everywhere. Abundance starts with zero users and must build density deliberately.

Diffuse national launch creates "ghost town" experience: users see 5 listings in their city, conclude marketplace doesn't work, churn. Better to have 5,000 listings in one city and delight users there than 5 listings in 1,000 cities and disappoint everyone.

**Reconsideration Trigger**: If Phase 1 proves single-player utility (inventory) is strong enough to drive retention without network features, then national launch becomes viable.

---

### Alternative 4: Android-First (Larger Market)

**Description**: Launch on Android first to access larger market (70%+ global, 60%+ U.S.)

**Pros**:
✅ Larger addressable market (4-5x more potential users)
✅ Emerging markets access (Android dominates globally)
✅ Faster network effects (more users)

**Cons**:
❌ Lower revenue potential (Android users have 40% lower household income median)
❌ No Vision framework equivalent (Google's on-device ML less mature)
❌ Device fragmentation (testing/QA nightmare)
❌ Less alignment with "premium organization app" positioning
❌ No App Store featuring opportunity

**Why Rejected**:
iOS users are better fit for Abundance's value proposition: higher income, more possessions, more willing to pay for productivity/organization apps. Android-first optimizes for user count over user value. Better to have 50K high-LTV users than 200K low-LTV users.

Additionally, Android fragmentation increases development complexity without strategic benefit. iOS-first with rapid Android follow-on captures 80% of the benefit with 20% of the downside.

**Reconsideration Trigger**: If iOS market proves too small or unwilling to pay, pivot to Android-primary.

---

## Validation Criteria (6-Month Checkpoint)

This decision will be re-evaluated at Month 6 based on the following metrics:

### Success Criteria (Proceed with Strategy)

**User Adoption**:
- ✅ 5,000+ activated users in origin metro (50+ items cataloged, monthly active)
- ✅ 30%+ new users catalog 50+ items in first 30 days
- ✅ 25%+ Month 6 retention

**Engagement**:
- ✅ 3+ sessions per week average
- ✅ 10+ searches per month (inventory genuinely used, not just cataloged and forgotten)
- ✅ 30%+ users join sharing circles

**Network Effects**:
- ✅ 20+ active sharing circles with 5+ members each
- ✅ 500+ marketplace listings (if marketplace enabled)
- ✅ 20+ transactions per week (if marketplace enabled)

**Strategic**:
- ✅ App Store featuring achieved (or strong positive signals from Apple)
- ✅ No incumbent response yet (Facebook/eBay haven't launched competing feature)
- ✅ User feedback validates privacy-first architecture ("I trust Abundance with cataloging my possessions")

### Pivot Triggers (Revise Strategy)

**Low Adoption**:
- ❌ <3,000 activated users after 6 months → Geographic strategy wrong or product-market fit absent
- ❌ <20% catalog 50+ items → Behavioral assumption invalid (people don't want to catalog)
- ❌ <15% Month 6 retention → Single-player utility insufficient

**Network Failure**:
- ❌ <10% join sharing circles → Community features not resonating
- ❌ <200 marketplace listings → Insufficient inventory for marketplace
- ❌ <5 transactions per week → Marketplace liquidity too low

**Competitive**:
- ❌ Facebook/eBay/Google ships competing feature → Differentiation evaporated, must pivot to integration messaging or niche
- ❌ Apple restricts Vision API or announces competing feature → Platform dependency materialized, accelerate Android

**Monetization**:
- ❌ <3% willing to pay for premium → Subscription model invalid
- ❌ <5% list items for sale → Marketplace monetization invalid

### Kill Triggers (Consider Shutdown or Major Pivot)

- ❌ <2,000 activated users AND <15% retention → No product-market fit
- ❌ Apple launches competing feature (inventory in Photos app) → Existential threat
- ❌ Facebook launches AI cataloging + zero-fee marketplace → Cannot compete
- ❌ Behavioral study shows <10% willing to invest time cataloging → Market doesn't exist

---

## Implementation Plan

### Month 0-1: Architecture & Foundation
- Finalize iOS tech stack (Swift, SwiftUI, Vision framework)
- Design platform-agnostic backend API (to support future Android)
- Implement hybrid AI pipeline (on-device segmentation → cloud analysis → data integration)
- Set up infrastructure (AWS/GCP, database, observability)

### Month 1-3: iOS MVP Development
- Core cataloging (camera, multi-item capture, AI identification)
- Inventory management (search, organization, categories)
- User accounts, authentication
- Basic sharing circles (create, invite, browse)
- Marketplace v1 (list, search, offers)

### Month 3: Android Planning Begins
- Architecture design for Android version
- Identify React Native vs. native Android vs. Flutter
- Spec cloud-based AI pipeline (no Vision framework)
- Hire Android engineer (if native) or cross-platform expert (if RN/Flutter)

### Month 4-6: iOS Launch & Validation
- Beta testing (500-1,000 users in SF/Seattle)
- App Store submission
- PR/marketing campaign (geo-targeted to origin metro)
- Monitoring: Retention, engagement, sharing/marketplace metrics
- **Month 6 Checkpoint**: Evaluate success criteria, decide proceed/pivot/kill

### Month 6-9: Android Development (Parallel with iOS Growth)
- Android version build
- Cloud-based AI pipeline implementation
- Cross-platform testing
- Prepare for simultaneous metro expansion + Android launch

### Month 9-12: Android Launch + Metro Expansion
- Android ships in top 10 metros
- iOS expands to new metros
- Marketplace enabled where density achieved
- Scale infrastructure, customer support, trust & safety

---

## Stakeholder Communication

### Engineering Team
**Impact**: iOS-first determines hiring (Swift/SwiftUI), architecture (hybrid AI pipeline), and timeline (faster MVP)
**Action Required**:
- Hire iOS engineers (2-3) immediately
- Begin Android planning at Month 3 (hire Android engineer or evaluate cross-platform)
- Design backend with platform-agnostic APIs

### Marketing Team
**Impact**: Metro-by-metro determines marketing strategy (geo-targeted, not national)
**Action Required**:
- Focus all Month 0-6 efforts on SF or Seattle
- Build metro launch playbook (repeatable for expansion)
- Prepare App Store featuring pitch (tie to iOS 26 launch)

### Design Team
**Impact**: iOS-first enables full use of Apple design guidelines, Liquid Glass design language
**Action Required**:
- Design with iOS HIG (Human Interface Guidelines) as primary
- Plan Android Material Design adaptation for Month 6-9
- Ensure privacy-first architecture is visible in UX (educate users on how their data is protected)

### Executive Team / Investors
**Impact**: Slower revenue ramp (marketplace fees delayed 12-18 months), higher quality product, better retention potential
**Action Required**:
- Funding runway must support 12-18 months to revenue (not 6-9 months)
- Understand trade-off: quality + retention over speed + scale
- Support pivot at Month 6 if validation criteria not met

---

## Success Metrics

**Month 6** (End of Phase 1):
- 5,000 activated users in origin metro
- 25% Month 6 retention
- 30% joining sharing circles
- App Store featuring (achieved or strong signals)

**Month 12** (End of Phase 2):
- 50,000 activated users across 10 metros
- 500+ active sharing circles
- 5,000+ marketplace listings
- Android version launched
- Revenue: $50K-100K (early monetization testing)

**Month 18** (End of Phase 3):
- 250,000 activated users nationally
- 20-30 metros with full network effects (sharing + marketplace)
- Revenue: $500K-1M annually
- LTV:CAC > 1:1 (breakeven unit economics)

**Month 24** (Sustainable Growth):
- 1M users
- 50+ metros with network effects
- Revenue: $5-7M annually
- LTV:CAC > 1.5:1 (healthy economics)

---

## Related Decisions

**ADR-002: Platform Strategy (Come for Tool, Stay for Network)** - Defines user acquisition sequencing and value prop evolution
**ADR-003: MVP Scope and Phasing** - Defines phasing strategy for inventory-first, marketplace Phase 2
**ADR-004: iOS 26 Only Launch** (Archived: `docs/archive/adr/ADR-004-ios-26-only-launch.md`) - iOS 26 platform requirement

---

## Appendix: Historical Precedents

### Successful iOS-First Companies

**Instagram** (2010):
- iOS-only for 18 months
- Achieved 10M users before Android launch
- Android shipped April 2012; acquired by Facebook days later for $1B
- **Lesson**: iOS-first works if single-player utility strong (photo filters) and network effects portable (follow anyone globally, not local-only)

**Uber** (2010):
- iOS-first in SF
- Metro-by-metro expansion (NYC, Seattle, Boston, etc.)
- Android followed 6-9 months per metro
- **Lesson**: Geographic network effects require metro-by-metro launch. National diffusion doesn't work for local marketplaces.

**Clubhouse** (2020):
- iOS-only for 12 months
- Achieved 10M users through FOMO/exclusivity
- Android launched too late (May 2021); momentum lost
- **Lesson**: Network-only apps (no single-player utility) must scale fast. Android delay was fatal.

### Failed iOS-Only Companies

**Google+** (2011):
- Network-dependent from Day 1
- No single-player utility
- Failed to achieve critical mass despite Google's resources
- **Lesson**: "Come for tool" must genuinely work standalone. "Come for network" requires massive scale.

**Nextdoor** (2011):
- iOS-first, struggled for 3-4 years
- Only achieved scale after Android launch enabled neighborhood density
- **Lesson**: Local network effects require cross-platform. iOS-only prevented density.

### Implication for Abundance

Abundance combines elements of Instagram (iOS-first, privacy-preserving, photo-based) and Uber (metro-by-metro, local density). Key difference: **Instagram's network effects were global (follow anyone); Abundance's are local (share/buy from neighbors)**.

This makes Android follow-on CRITICAL within 6-9 months. Delaying to 18-24 months (like original plan) would repeat Nextdoor's mistake.

---

**Status**: Approved
**Next Review**: Month 6 checkpoint (2026-04-23)
**Owner**: CEO / Product Owner
**Prepared By**: Business Strategy Analyst (Stage 1.1)
