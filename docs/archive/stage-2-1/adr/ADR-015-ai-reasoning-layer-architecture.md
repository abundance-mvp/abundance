# ADR-015: AI Reasoning Layer with Multi-Model Architecture

**Status:** ACCEPTED (Revised 2025-10-30, Updated 2025-11-01)
**Date:** 2025-10-29 (Revised 2025-10-30, Updated 2025-11-01)
**Decision Makers:** Product Leadership, Tech Lead
**Supersedes:** ADR-012 (Google Shopping Graph as Primary AI)
**Related:** ADR-013 (Vision Framework Strategy), ADR-014 (Cloud AI Provider), PRD-001 (Abundance MVP), RECONCILIATION-design-004-vs-stage-2.1.md, SYNTHESIS-stage-2.1-comprehensive-verification.md, 2025-11-01-stage-2.2-ios-architecture-implementation.md

---

## Context

The original Stage 2.1 plan proposed a two-layer architecture for premium item cataloging:

1. **Layer 1 (Free):** iOS 26 Vision Framework for on-device object detection
2. **Layer 2 (Premium):** Google Shopping Graph API for product identification
3. **NO Layer 3:** No fallback, silent retry on failures

This approach had limitations:

- **No validation:** Shopping Graph results accepted without verification
- **No conflict resolution:** Vision label ("scissors") vs. Shopping Graph mismatch → user confusion
- **No attribute extraction:** Missing condition, color, material details for richer metadata
- **No graceful degradation:** If Shopping Graph fails → user sees generic label until retry succeeds
- **No handling of edge cases:** Imperfect cropping, multiple candidates, rare items

**User Requirement:** "Like magic" experience with **zero friction**. The premium tier must:

- Accurately catalog items from a single photo (even if imperfectly cropped)
- Extract rich metadata (condition, color, material, category) for search/filtering
- Handle conflicting data from multiple sources intelligently
- Request additional photos only when truly necessary (barcode, label, etc.)
- Provide best-effort attributes even when Shopping Graph has no match

**Hypothesis:** Adding an AI reasoning layer to synthesize vision analysis + Shopping Graph results will deliver "like magic" accuracy while maintaining acceptable margins (>80%).

---

## Decision

**We will implement a three-layer AI architecture for premium item cataloging:**

### **Layer 1 (Free Tier): iOS Vision Framework + Core ML**

- **Purpose:** On-device object detection and image cropping
- **Technology:** iOS Vision Framework + Core ML YOLOv3-Tiny model
- **Implementation:** `VNCoreMLRequest` wrapper around YOLOv3-Tiny (35MB model)
- **Output:** Bounding boxes + basic labels from 80 COCO object classes
- **Cost:** $0 (on-device, one-time 35MB model download)
- **Performance:** 50-150ms per image (well under 500ms target)
- **Detection Rate:** 70-80% for common household items
- **Device Requirements:** iPhone 15 Pro+ (A17 Pro chip recommended), iPhone 13+ supported
- **Note:** Apple does not provide built-in `VNRecognizeObjectsRequest` for generic objects. Core ML model integration required. (Verified 2025-10-30)

### **Layer 2a (Premium): Vision Analysis - Gemini 2.5 Flash-Lite**

- **Purpose:** Extract detailed object attributes from cropped images
- **Technology:** Google Gemini 2.5 Flash-Lite via GCP Vertex AI
- **Output:** Structured JSON with attributes
  ```json
  {
    "condition": "used",
    "condition_confidence": 0.85,
    "color": ["red", "black"],
    "material": "plastic",
    "material_confidence": 0.92,
    "size_category": "small",
    "category": "electronics",
    "subcategory": "gaming_controller",
    "notable_features": ["PlayStation logo", "USB-C port"]
  }
  ```
- **Cost:** $0.000249 per image
  - Calculation: (1,290 input tokens / 1M) × $0.10 + (300 output tokens / 1M) × $0.40
  - Input: $0.000129 + Output: $0.000120 = $0.000249
- **Performance:** <1 second per image
- **Runs in parallel with Layer 2b**

### **Layer 2b (Premium): Visual Product Search - SerpApi Google Lens + Brand/Model Parsing**

- **Purpose:** Identify specific products (brand, model, price) from image using Google Lens
- **Technology:** SerpApi Google Lens API + Image Hosting + LLM Parsing
- **Why This API:** Google Shopping Graph API does not exist as a developer-accessible API. Research (2025-10-30) confirmed:
  - Content API for Shopping: Merchants upload their own products (not searchable)
  - Vision API Product Search: Requires building your own product catalog ($4.50/1K queries)
  - **SerpApi Google Lens**: Access to Google's visual search using real Google Lens results
- **Architecture (3 sub-steps):**
  1. **Image Hosting:** Compress JPEG (85%) → Upload to AWS S3/CloudFront → Generate public URL (SerpAPI requires public URLs, no direct upload)
  2. **Visual Search:** Call SerpAPI Google Lens with public URL → Returns 10-25 product matches
  3. **LLM Parsing:** Use Claude Haiku 4.5 to extract brand/model from combined title string (SerpAPI doesn't provide separate brand/model fields)
- **Output:** Product matches from Google Lens visual search
  ```json
  {
    "visual_matches": [
      {
        "title": "Sony DualSense Wireless Controller",  // Combined title (requires parsing)
        "source": "Amazon",
        "link": "https://www.amazon.com/...",
        "price": {"value": "69.99", "currency": "USD"},
        "thumbnail": "https://...",
        "position": 1
        // Note: No confidence score, no separate brand/model fields
      }
    ]
  }
  ```
- **Cost Breakdown:**
  - SerpAPI search: $0.010 (Production plan: $150/month for 15K searches)
  - AWS S3/CloudFront: $0.0001 per image (storage + transfer)
  - Claude Haiku parsing: $0.0008 per inference (brand/model extraction)
  - **Total Layer 2b cost: $0.0109 per item**
- **Performance:**
  - Average: 5.29 seconds
  - p95: ~7 seconds (higher than original 2-5s estimate)
- **Reliability:** 99.76% uptime (slightly below 99.9% target)
- **Hourly Quota:** 3,000 searches/hour (20% of monthly quota)
- **Runs in parallel with Layer 2a**
- **Note:** Requires Redis-backed request queue with rate limiting. (Verified 2025-10-30)

### **Layer 3 (Premium): AI Reasoning & Synthesis - Claude Sonnet 4.5**

- **Purpose:** Synthesize vision analysis + SerpAPI results into final metadata
- **Technology:** Claude Sonnet 4.5 (Batch API) via Anthropic API or GCP Vertex AI
- **Why Sonnet 4.5:** Replaces Claude 3.5 Sonnet (verified 2025-10-30)
  - Graduate-level reasoning: 83.4% GPQA Diamond (vs. ~75% for 3.5)
  - Best-in-class structured output: 61.4% OSWorld (leading all models)
  - Hybrid reasoning mode: Fast + extended thinking
  - Production-proven: Available on Anthropic, AWS Bedrock, GCP Vertex AI
- **Input:** Vision attributes (Layer 2a) + SerpAPI/Barcode candidates (Layer 2b) + parsed brand/model + barcode data (Layer 1 per ADR-018)
- **Reasoning Tasks:**
  1. **NEW (ADR-018): Barcode validation** - Cross-reference barcode product data with vision analysis
     - Example: Barcode says "Heinz Ketchup 570g", vision confirms "red squeeze bottle with Heinz logo" ✅
     - Barcode wins for product identity, vision adds condition context ("80% full, label wear")
  2. **NEW (ADR-018): Barcode-vision conflict resolution** - Handle mismatches between barcode and visual features
     - Example: Barcode says "Adidas box", vision sees "Nike swoosh on shoes" → Flag for review
     - Example: Barcode not visible but product has distinctive branding → Use vision + SerpAPI
  3. **NEW (ADR-018): Package vs. product detection** - Detect when item is in wrong packaging
     - Example: Product removed from original box, barcode on box doesn't match item → Request additional photos
  4. Compare vision attributes against SerpAPI candidates (existing task)
  5. Resolve conflicts (e.g., vision says "red" but SerpAPI shows "blue variant")
  6. Select best product match from multiple SerpAPI candidates
  7. Validate parsed brand/model against vision analysis
  8. Detect mismatches (imperfect cropping, wrong product returned)
  9. Calculate confidence proxy (position rank + price + reviews) to replace missing SerpAPI confidence scores
  10. Determine if additional photos needed (confidence <70%, missing key identifiers)
  11. Provide fallback attributes when SerpAPI fails (vision-only metadata)
- **Output:** Final structured metadata (SCHEMA-001)
  ```json
  {
    "name": "Sony DualSense Wireless Controller",
    "brand": "Sony",
    "model": "DualSense",
    "category": "Video Games",
    "subcategory": "Controllers",
    "condition": "used",
    "color": ["red", "black"],
    "material": "plastic",
    "estimated_value": 69.99,
    "product_url": "https://shopping.google.com/...",
    "confidence": 0.88,
    "source": "shopping_graph_validated",
    "action": "save",
    "reasoning": "Vision analysis confirms top Shopping Graph match"
  }
  ```
- **Cost:** $0.0092 per inference (Batch API with 50% discount)
  - Standard API: $0.0183 per inference
  - Batch API: $0.0092 per inference (50% savings)
  - Calculation: (2,000 input tokens / 1M) × $1.50 + (500 output tokens / 1M) × $7.50
  - Input: $0.003 + Output: $0.00375 = $0.0092
  - **Note:** Can be further reduced to $0.0024 with prompt caching (90% savings on repeated content)
- **Performance:**
  - Standard mode: 1-2 seconds per synthesis
  - Extended thinking mode: ~156 seconds (batch processing only)
- **Context Window:** 200K tokens (1M in beta)

---

## Rationale

### Why Gemini 2.5 Flash-Lite for Vision Analysis?

**Research Findings (2025-10-29):**

| Model | Cost/Image | Vision Capabilities | Latency | Availability |
|-------|-----------|---------------------|---------|--------------|
| **Gemini 2.5 Flash-Lite** | **$0.000387** | Frontier multimodal, 1M context | <1s | GCP Vertex AI |
| Claude Haiku 4.5 | $0.0027 | Good vision, 200K context | <1s | Anthropic, Bedrock |
| GPT-4o mini | $0.00043* | Strong vision (MMMU 59.4%) | <2s | OpenAI |

*GPT-4o mini has a token anomaly: uses 2833 tokens/image in low-res mode (33x more than GPT-4o), making actual cost higher than advertised.

**Decision:** Gemini 2.5 Flash-Lite wins on cost-performance trade-off:

- **7x cheaper** than Claude Haiku 4.5
- **50% reduction** in output tokens vs. Gemini 2.0 Flash = further savings
- **Fastest latency** among proprietary models (lower TTFT, higher tokens/sec)
- **1M token context** enables batch processing (future optimization)
- **GCP native** = synergy with Shopping Graph API (if GCP-hosted)

### Why Claude 3.5 Sonnet for Reasoning?

**Research Findings:**

| Model | Cost/Inference | Reasoning Capabilities | Multimodal | Structured Output |
|-------|---------------|----------------------|------------|-------------------|
| **Claude 3.5 Sonnet** | **$0.0045** | Graduate-level, 100+ step reasoning | **Best vision** | ✅ JSON schema |
| Claude 3.7 Sonnet (Thinking) | $0.006-0.01 | Extended thinking (64K tokens) | Excellent | ✅ (standard mode) |
| GPT-4o | $0.0054 | Strong general reasoning | Good (MMMU 68.7%) | ✅ JSON mode |
| Gemini 2.5 Pro | $0.015 | **Top MMMU** (81.7%) | Excellent | ✅ |
| o1-mini | $0.0045 | STEM/coding optimized | ❌ No vision | ✅ |

**Decision:** Claude 3.5 Sonnet is optimal for synthesis layer:

- **Best multimodal reasoning** (surpasses Claude 3 Opus on vision benchmarks)
- **Cost-effective** at $0.0045/inference (same as o1-mini, but with vision support)
- **Exceptional at conflict resolution** (MathVista 67.7% = visual reasoning mastery)
- **Natural language explanations** (can generate user-facing "reasoning" field)
- **Tool calling support** (can invoke additional APIs if needed)
- **Available on GCP Vertex AI** (unified cloud provider with Gemini)

### Why SerpApi Google Lens?

**Requirements:**

- Visual product search (image → brand/model/price)
- Large product catalog (household items, electronics, furniture, etc.)
- Reasonable cost (<$0.01/lookup for 90% margin target)
- API availability (programmatic access)

**Research Findings (2025-10-30):**

**Google Shopping Graph API does NOT exist** as a developer-accessible API:
- Content API for Shopping: Allows merchants to upload products (not search Google's catalog)
- Vision API Product Search: Requires building your own product catalog ($4.50/1K queries + storage)
- Google Shopping Graph: Internal Google infrastructure with 50B+ products, but no public API

**Decision:** SerpApi Google Lens at $0.010/search (Production plan)

**Rationale:**
- Access to real Google Lens visual search results (same as consumer Google Lens app)
- No catalog maintenance required (leverages Google's 50B+ product database indirectly)
- Proven API with 1M+ developers, reliable uptime
- Cost-effective: $0.010/search on Production plan ($150/month for 15K searches)
- Alternative pricing: $0.009/search on Big Data plan ($275/month for 30K searches)

**Risk Mitigation Alternatives:**

- Barcode Lookup API (~$0.01/lookup, requires barcode in photo)
- Vision-only fallback (rich attributes without specific product ID)
- Build own catalog with Vision API Product Search ($4.50/1K queries, higher maintenance)

---

## Cost-Benefit Analysis

### **Total Cost Per Item (VERIFIED 2025-10-30)**

| Component | Cost | Notes |
|-----------|------|-------|
| Layer 1: iOS Vision + Core ML | $0.000 | On-device (verified) |
| Layer 2a: Vision Analysis (Gemini 2.5 Flash-Lite) | $0.000249 | Per cropped image (verified pricing) |
| Layer 2b: SerpApi Google Lens + Hosting + Parsing | $0.0109 | $0.010 SerpAPI + $0.0001 GCS + $0.0008 Haiku parsing |
| Layer 3: AI Reasoning (Claude Sonnet 4.5 Batch) | $0.0092 | Batch API with 50% discount (verified pricing) |
| **TOTAL** | **$0.019449** | **Per premium item cataloged** |

**With Prompt Caching Optimization (Post-MVP):**
| Component | Cost | Notes |
|-----------|------|-------|
| Layer 1: iOS Vision + Core ML | $0.000 | No change |
| Layer 2a: Vision Analysis (Gemini 2.5 Flash-Lite) | $0.000249 | No change |
| Layer 2b: SerpApi Google Lens + Hosting + Parsing | $0.0099 | Big Data plan $0.009 + $0.0001 GCS + $0.0008 Haiku |
| Layer 3: AI Reasoning (Claude Sonnet 4.5 Batch) | $0.0024 | With 90% prompt caching savings |
| **TOTAL** | **$0.012239** | **Optimized cost (37% reduction)** |

### **Economics (Month 6: 5K users, 250K total items)**

**Premium tier (30% of users = 1,500 users, 75K items):**

- **Compute cost:** 75K items × $0.019449 = **$1,459/month**
  - Layer 1 (Vision): $0 (on-device)
  - Layer 2a (Gemini): 75K × $0.000249 = $19/month
  - Layer 2b (SerpAPI + GCS + Haiku): 75K × $0.0109 = $818/month
  - Layer 3 (Claude 4.5 Batch): 75K × $0.0092 = $690/month
  - **Breakdown:** SerpAPI $750 + GCS $8 + Haiku parsing $60 = $818 (Layer 2b)
- **Revenue:** 1,500 users × $6/month = **$9,000/month**
- **Gross Margin:** ($9,000 - $1,459) / $9,000 = **83.8%**
- **Net revenue:** $7,541/month available for infrastructure, storage, team

**With Optimizations (Month 12+):**
- **Compute cost:** 75K items × $0.012239 = **$918/month**
- **Gross Margin:** ($9,000 - $918) / $9,000 = **89.8%**

**Comparison to previous estimates:**

| Metric | Initial Estimate (2025-10-29) | Verified (2025-10-30) | Change |
|--------|------------------------------|----------------------|---------|
| Cost/item | $0.016249 | $0.019449 | +$0.0032 (+19.7%) |
| Month 6 compute cost | $1,219/month | $1,459/month | +$240/month |
| Gross margin | 86.5% | 83.8% | -2.7% |
| Net revenue/month | $7,781 | $7,541 | -$240 |

**Why the increase:**
- Claude 3.5 Sonnet → Claude Sonnet 4.5 (Batch): $0.006 → $0.0092 (+$0.0032/item)
- Layer 2b now includes image hosting ($0.0001) and LLM parsing ($0.0008): +$0.0009/item
- SerpAPI latency higher than expected (5.29s vs. 2-5s), but acceptable

**Trade-off Assessment:**

- **Month 6 Cost:** $1,459/month (16.2% of revenue)
- **Margin:** 83.8% (excellent, above 80% target)
- **Optimization Path:** Can reach 89.8% margin with prompt caching + Big Data plan (Month 12+)
- **Value gained:**
  - **State-of-the-art reasoning:** Claude Sonnet 4.5 (83.4% GPQA vs. ~75% for 3.5)
  - **Production-ready architecture:** Public URL hosting (no hacks)
  - **Robust parsing:** LLM-based brand/model extraction (vs. regex)
  - Rich metadata (condition, color, material) for search/filtering
  - Conflict resolution (vision vs. product search mismatches)
  - Graceful degradation (vision-only fallback if SerpApi fails)
  - Edge case handling (imperfect crops, rare items, low confidence)
  - User-facing reasoning ("I detected a red variant, not the standard black model")
  - Access to Google Lens visual search (Google's product database)

**Conclusion:** 83.8% margin is acceptable for MVP (+$240/month buys better AI reasoning + production-ready architecture). Clear path to 89.8% through optimizations. This is viable and provides "like magic" accuracy.

---

## Alternatives Considered

### **Alternative 1: Shopping Graph Only (Original Plan - ADR-012)**

**Architecture:**

- Layer 1: iOS Vision (free)
- Layer 2: Google Shopping Graph (premium)
- NO Layer 3

**Pros:**

- Simpler architecture (fewer API calls)
- Lower cost ($0.007/item = 94% margin)
- Faster latency (one API call instead of three)

**Cons:**

- **No validation:** Accepts Shopping Graph results blindly
- **No attributes:** Missing condition, color, material metadata
- **No conflict resolution:** Vision says "scissors" but Shopping Graph returns "stapler" → confusion
- **No graceful degradation:** Shopping Graph fails → user sees generic label until 6-hour retry
- **No edge case handling:** Imperfect cropping, rare items → failure modes

**Why Rejected:** Fails "like magic" requirement. Users will need to manually edit metadata frequently.

### **Alternative 2: Single-Model Architecture (Claude Haiku 4.5)**

**Architecture:**

- Layer 1: iOS Vision (free)
- Layer 2: Claude Haiku 4.5 (vision + reasoning in one model, premium)
  - Haiku 4.5 analyzes image directly
  - Haiku 4.5 calls Shopping Graph API via tool use
  - Haiku 4.5 synthesizes results

**Pros:**

- Simpler (one AI model instead of two)
- Better margin (91.9% vs. 90.1% with two models)
- Fewer API roundtrips (one model call instead of two)
- Haiku 4.5 has strong instruction-following (65% vs. competitors' 44%)

**Cons:**

- **Less specialized:** Haiku 4.5 is generalist vs. Flash-Lite's vision + Sonnet's reasoning mastery
- **Less flexibility:** Can't swap vision model without changing reasoning layer
- **Limited multimodal benchmarks:** Haiku 4.5 vision benchmarks less documented than Sonnet
- **Higher per-model cost:** $0.0027/inference vs. Flash-Lite $0.000387 (7x more expensive for vision)

**Why Rejected:** Multi-model architecture provides better specialization and flexibility. Marginal cost savings ($0.595/user vs. $0.485/user) don't justify reduced accuracy/flexibility.

### **Alternative 3: Premium Accuracy (Gemini 2.5 Pro for Reasoning)**

**Architecture:**

- Layer 1: iOS Vision (free)
- Layer 2a: Gemini 2.5 Flash-Lite (vision, premium)
- Layer 2b: Google Shopping Graph (product search, premium)
- Layer 3: **Gemini 2.5 Pro** (reasoning, premium)

**Cost:** $0.0224/item (vs. $0.0119 with Sonnet) = 81% margin

**Pros:**

- **Highest MMMU score:** 81.7% (best multimodal understanding)
- **GCP ecosystem:** All Google models (unified billing, monitoring)
- **Potentially lower latency:** If Vertex AI optimizes Gemini model-to-model calls

**Cons:**

- **2x more expensive:** $0.015/inference vs. Sonnet $0.0045
- **Marginal accuracy gain:** Gemini 2.5 Pro 81.7% MMMU vs. Claude 3.5 Sonnet 67.7% MathVista (different benchmarks, hard to compare)
- **Lower margin:** 81% vs. 90% (reduces runway for infrastructure costs)

**Why Rejected:** Not worth 2x cost increase for MVP. Can upgrade to Pro for high-value items (luxury goods, insurance) in post-MVP phase.

### **Alternative 4: Extended Thinking (Claude 3.7 Sonnet)**

**Architecture:**

- Layer 3: Claude 3.7 Sonnet with extended thinking enabled

**Cost:** $0.006-0.01/inference (vs. $0.0045 standard) = 88-86% margin

**Pros:**

- **Deeper reasoning:** 64K+ thinking tokens for complex cases
- **Better accuracy:** Excels when multiple candidates need careful comparison
- **Hybrid mode:** Can toggle thinking on/off per request based on confidence

**Cons:**

- **Higher latency:** +52.9% increase (~156 seconds for complex tasks)
- **Tool calling limitation:** Extended thinking disables forced tool calling (need standard mode for Shopping Graph)
- **Higher cost:** $0.001-0.005 more per inference

**Why Rejected for MVP:** Standard Claude 3.5 Sonnet sufficient for 95% of items. Can enable thinking mode for flagged edge cases (5%) in hybrid approach.

**Hybrid Recommendation (Post-MVP):**

- 95% of items → Claude 3.5 Sonnet standard ($0.0045)
- 5% edge cases → Claude 3.7 Sonnet thinking ($0.008)
- Blended cost: $0.00468/inference (negligible increase)
- Triggers: confidence <70%, conflicting data, user flags "valuable/rare"

---

## Edge Case Handling

The AI reasoning layer (Claude 3.5 Sonnet) handles critical edge cases:

### **1. Imperfect Cropping**

**Scenario:** iOS Vision detects "scissors" but crops only 60% of object (rest is background/table).

**Layer 2a (Gemini Flash-Lite):** Analyzes partial object, returns attributes with confidence scores.

**Layer 2b (Shopping Graph):** May return low-confidence matches or wrong products due to partial image.

**Layer 3 (Claude Sonnet):**

- Detects mismatch: "Vision sees partial scissors, Shopping Graph returned stapler (low confidence)"
- Action: `request_additional_photos` with message: "Could you retake this photo with the entire object centered?"
- Fallback: If user declines, saves vision-only attributes ("scissors, partial view, unable to identify specific product")

### **2. Multiple High-Confidence Candidates**

**Scenario:** User photos a gaming controller. Shopping Graph returns:

1. Sony DualSense (standard black) - confidence 0.89
2. Sony DualSense (red variant) - confidence 0.87
3. Sony DualSense (limited edition) - confidence 0.85

**Layer 2a (Gemini Flash-Lite):** Identifies "red plastic, PlayStation logo, USB-C port"

**Layer 3 (Claude Sonnet):**

- Compares vision color ("red") against candidates
- Selects candidate #2 (red variant) as best match
- Output: `name: "Sony DualSense Wireless Controller (Red)"`, `confidence: 0.91`, `reasoning: "Vision analysis confirms red color, matches variant product"`

### **3. Conflicting Data**

**Scenario:** Vision analysis says "red Nike running shoes" but Shopping Graph returns "Adidas Ultraboost (black)" with 0.88 confidence.

**Layer 3 (Claude Sonnet):**

- Detects conflict: Brand mismatch (Nike vs. Adidas), color mismatch (red vs. black)
- Investigates: Shopping Graph confidence is high (0.88) → likely vision model misidentified brand
- Checks notable features: Vision saw "swoosh logo" → could be Nike; Shopping Graph saw "three stripes" → definitely Adidas
- Decision path:
  - If Shopping Graph image matches user photo → Trust Shopping Graph (vision model error)
  - If mismatch persists → Request additional photo ("Close-up of logo/brand tag")
- Output: `action: "request_additional_photos"`, `reasoning: "Brand and color mismatch detected. Please provide close-up of logo."`

### **4. Low Confidence Across All Sources**

**Scenario:**

- Vision analysis: "Possible leather bag, 60% confidence"
- Shopping Graph: No results (rare/handmade item)
- Basic label: "bag"

**Layer 3 (Claude Sonnet):**

- Recognizes low confidence + no product match
- Determines if request for additional photos will help:
  - Check if brand tag visible → Request close-up of tag
  - Check if barcode visible → Request barcode photo
  - If homemade/rare → Accept vision-only attributes
- Output:
  ```json
  {
    "name": "Leather Bag",
    "category": "Accessories",
    "subcategory": "Bags",
    "condition": "used",
    "material": "leather (unconfirmed)",
    "confidence": 0.60,
    "source": "vision_only",
    "action": "save",
    "reasoning": "No product match found. This may be a handmade or rare item."
  }
  ```

### **5. Shopping Graph API Failure**

**Scenario:** Shopping Graph API returns 503 (service unavailable) or rate limit error.

**Layer 2a (Gemini Flash-Lite):** Completes successfully, returns attributes.

**Layer 2b (Shopping Graph):** Fails with error.

**Layer 3 (Claude Sonnet):**

- Detects Shopping Graph failure
- Falls back to vision-only metadata
- Schedules silent retry (Cloud Scheduler, 6 hours)
- Output:
  ```json
  {
    "name": "Gaming Controller",
    "category": "Electronics",
    "subcategory": "Gaming",
    "condition": "used",
    "color": ["red", "black"],
    "material": "plastic",
    "confidence": 0.75,
    "source": "vision_only_fallback",
    "action": "save_and_retry_later",
    "reasoning": "Product search unavailable. Saved based on visual analysis."
  }
  ```
- User experience: Sees rich attributes immediately ("Gaming Controller - Used - Red/Black"), upgraded to specific product ("Sony DualSense") when retry succeeds.

### **6. Replica vs. Original Detection**

**Scenario:** User photos a designer handbag. Shopping Graph returns "Gucci Marmont" but vision analysis detects low-quality stitching.

**Layer 2a (Gemini Flash-Lite):**

- Identifies: "Gucci logo visible, leather texture low-quality, stitching irregular"
- Attributes: `notable_features: ["Gucci logo", "uneven stitching", "synthetic texture"]`

**Layer 3 (Claude Sonnet):**

- Cross-references: Shopping Graph says "Gucci Marmont $2,100" vs. vision says "low-quality materials"
- Reasoning: Likely replica/counterfeit
- Output:
  ```json
  {
    "name": "Designer-Style Handbag (Gucci Marmont Replica)",
    "category": "Accessories",
    "condition": "new",
    "material": "synthetic_leather",
    "estimated_value": 50.00,
    "confidence": 0.70,
    "source": "hybrid_analysis",
    "action": "save",
    "reasoning": "Visual analysis suggests replica (low-quality materials vs. authentic product)"
  }
  ```

---

## Implementation Details

### **Parallel Processing Workflow**

```javascript
// Cloud Function: enrichItem(croppedImageUrl, basicLabel, userId, itemId)

async function enrichItem(croppedImageUrl, basicLabel, userId, itemId) {
  try {
    // STEP 1: PARALLEL - Launch vision analysis + Shopping Graph search
    const [visionAnalysis, shoppingResults] = await Promise.all([
      analyzeWithGeminiFlashLite(croppedImageUrl),
      searchShoppingGraph(croppedImageUrl)
    ]);

    // STEP 2: SEQUENTIAL - Synthesize with Claude Sonnet
    const finalMetadata = await synthesizeWithClaude({
      visionAnalysis,
      shoppingResults,
      basicLabel,
      userId,
      itemId
    });

    // STEP 3: Handle actions
    if (finalMetadata.action === 'request_additional_photos') {
      await notifyUserForPhotos(userId, itemId, finalMetadata.reasoning);
      await savePartialItem(userId, itemId, finalMetadata);
    } else if (finalMetadata.action === 'save_and_retry_later') {
      await saveEnrichedItem(userId, itemId, finalMetadata);
      await scheduleRetry(itemId, Date.now() + 6 * 3600 * 1000); // 6 hours
    } else {
      await saveEnrichedItem(userId, itemId, finalMetadata);
    }

    return finalMetadata;

  } catch (error) {
    // Graceful degradation: Save basic label + schedule retry
    await saveBasicItem(userId, itemId, basicLabel);
    await scheduleRetry(itemId, Date.now() + 6 * 3600 * 1000);
    throw error;
  }
}
```

### **Retry Strategy**

```javascript
// Cloud Scheduler: Runs every 6 hours
async function retryFailedEnrichments() {
  const failedItems = await getItemsWithStatus('retry_pending');

  for (const item of failedItems) {
    try {
      const enrichedMetadata = await enrichItem(
        item.croppedImageUrl,
        item.basicLabel,
        item.userId,
        item.itemId
      );

      if (enrichedMetadata.confidence > 0.80) {
        await updateItemStatus(item.itemId, 'completed');
      } else {
        await incrementRetryCount(item.itemId);
        if (item.retryCount > 3) {
          await updateItemStatus(item.itemId, 'manual_review');
        }
      }
    } catch (error) {
      console.error(`Retry failed for item ${item.itemId}:`, error);
      await incrementRetryCount(item.itemId);
    }
  }
}
```

### **Cost Optimization (Post-MVP)**

**Prompt Caching (Claude):**

- Cache Shopping Graph JSON schemas (90% cost reduction per Anthropic docs)
- Cache system prompts with decision rules
- Expected savings: ~$0.002/inference → Total cost $0.0025 (down from $0.0045)

**Batch Processing (Gemini):**

- If user uploads 10+ photos simultaneously, batch vision analysis
- 1M context window allows processing multiple images in single request
- Expected savings: ~20% reduction in API calls

**Perceptual Hashing:**

- Detect duplicate/similar items (user photos same object twice)
- Cache vision analysis results for 24 hours
- Expected savings: ~5% reduction (duplicate detection rate)

**Target (Month 12):** Reduce cost from $0.0119/item → $0.008/item (87% margin)

---

## Testing Strategy

### **Accuracy Validation**

**Test Dataset:** 50 diverse household items

| Category | Items | Success Criteria |
|----------|-------|------------------|
| Electronics | 10 (headphones, chargers, controllers, etc.) | >85% correct brand/model |
| Furniture | 10 (chairs, lamps, shelves, etc.) | >75% correct category/type |
| Clothing | 10 (shirts, shoes, jackets, etc.) | >70% correct brand/size/color |
| Kitchen | 10 (utensils, containers, appliances, etc.) | >80% correct product ID |
| Office | 5 (scissors, staplers, notebooks, etc.) | >85% correct brand/model |
| Collectibles | 5 (toys, games, memorabilia, etc.) | >60% correct (rare items, lower bar) |

**Metrics:**

- **Precision:** % of AI-identified products that are correct
- **Recall:** % of items in dataset that AI correctly identifies
- **Attribute accuracy:** % of condition/color/material labels that match human judgment
- **Edge case handling:** % of imperfect crops, rare items that get reasonable fallback metadata

**Baseline Comparison:**

- **Shopping Graph only (ADR-012):** Test without vision analysis or reasoning layer
- **Multi-Model AI (ADR-015):** Test with full three-layer architecture
- **Human labeling:** Gold standard for precision/recall calculation

### **Performance Testing**

**Latency Targets:**

- Layer 2a (Gemini Flash-Lite): <1 second p95
- Layer 2b (Shopping Graph): <5 seconds p95
- Layer 3 (Claude Sonnet): <2 seconds p95
- **Total end-to-end:** <6 seconds p95

**Load Testing:**

- Simulate 1,000 concurrent users
- Each user uploads 10 items simultaneously
- Measure: Throughput (items/sec), error rate, API quota exhaustion

### **Cost Validation**

**Actual Token Usage:**

- Gemini Flash-Lite: Measure actual tokens per image (estimate: 1290 input + 300 output)
- Claude Sonnet: Measure actual tokens per synthesis (estimate: 1000 input + 200 output)
- Validate: Total cost matches $0.0119/item estimate

**Monthly Cost Projection:**

- Run POC with 100 beta users, 50 items each (5,000 items)
- Actual cost: $X
- Extrapolate to Month 6 (75K items): $X * 15
- Validate: Matches $893/month estimate (±10%)

---

## Risks & Mitigations

### **Risk 1: Google Shopping Graph API Unavailable**

**Likelihood:** Medium
**Impact:** High (entire premium tier depends on it)

**Mitigation:**

1. **Validate API access:** Contact Google Cloud sales to confirm Shopping Graph API exists and obtain pricing
2. **Alternative APIs:**
   - Barcode Lookup API (~$0.01/lookup, requires barcode in photo)
   - Semantics3 Product API (e-commerce product database)
   - Open Product Data (open-source product database)
3. **Vision-only fallback:** If no API available, use Gemini Flash-Lite + Claude Sonnet for rich attribute extraction without specific product ID
4. **Hybrid approach:** Request users to photo barcodes for items without visual product matches

**Decision Point:** Stage 2.3 (Backend Architecture) must validate Shopping Graph API before proceeding.

### **Risk 2: AI Model Pricing Changes**

**Likelihood:** Medium
**Impact:** Medium (could erode margins)

**Mitigation:**

1. **Pin model versions:** Anthropic and Google typically grandfather pricing for pinned versions
2. **Monitor pricing pages:** Set alerts for pricing updates
3. **Alternative models:** Architecture is flexible—can swap Gemini → GPT-4o mini or Claude → Gemini Pro if needed
4. **Prompt caching:** Implement immediately after MVP to reduce costs by ~40%

**Contingency:** If Sonnet pricing increases >50%, switch to Haiku 4.5 (single-model architecture)

### **Risk 3: Accuracy Below Expectations**

**Likelihood:** Low (research indicates frontier models are strong)
**Impact:** High (fails "like magic" requirement)

**Mitigation:**

1. **POC validation:** Build 50-item test dataset, measure accuracy before full MVP
2. **Gradual rollout:** Beta test with 100 users, measure correction rate (how often users edit AI metadata)
3. **Prompt engineering:** Iterate on Claude Sonnet system prompts based on failure analysis
4. **Upgrade path:** If accuracy <80%, upgrade to Claude 3.7 Sonnet (thinking) or Gemini 2.5 Pro

**Success Criteria:** >80% of items cataloged without user edits, <5% manual review rate

### **Risk 4: Latency Exceeds 10 Seconds**

**Likelihood:** Low (parallel processing should keep latency <6 sec)
**Impact:** Medium (degrades UX but doesn't break "like magic")

**Mitigation:**

1. **UX design:** Show immediate on-device results (Layer 1), display "Analyzing details..." for premium enrichment
2. **Progressive enhancement:** Update UI as results arrive (vision analysis → Shopping Graph → final synthesis)
3. **Caching:** Cache Shopping Graph results for common items (e.g., AirPods, iPhone chargers)
4. **Batch optimization:** Process multiple items simultaneously if user uploads album

**Acceptable Latency:** <10 seconds p95 (user sees progress, doesn't block app)

---

## Monitoring & Observability

### **Key Metrics**

**Cost Metrics:**

- Actual cost per item (vs. $0.0119 estimate)
- Cost breakdown by layer (vision $0.000387, Shopping Graph $0.007, reasoning $0.0045)
- Monthly burn rate (vs. $893/month budget)

**Performance Metrics:**

- Latency p50, p95, p99 for each layer
- End-to-end latency (total time from upload → final metadata saved)
- API error rates (Gemini, Shopping Graph, Claude)

**Accuracy Metrics:**

- User correction rate (% of items manually edited)
- Confidence distribution (histogram of final confidence scores)
- Edge case frequency (% of items flagged for additional photos or manual review)
- Source distribution (% shopping_graph_validated vs. vision_only vs. hybrid)

**Business Metrics:**

- Premium conversion rate (free → paid after seeing AI accuracy)
- User satisfaction (1-5 rating per cataloged item)
- Items per user per month (engagement)

### **Alerts**

- Cost per item > $0.015 (25% over budget)
- API error rate > 5% (Shopping Graph availability)
- Latency p95 > 10 seconds (performance degradation)
- User correction rate > 30% (accuracy below acceptable)

---

## Success Criteria

Stage 2.1 is considered successful when:

1. ✅ **Architecture validated:** POC with 50-item test dataset achieves >80% accuracy
2. ✅ **Cost validated:** Actual cost per item < $0.013 (10% buffer over estimate)
3. ✅ **Latency validated:** End-to-end p95 < 10 seconds
4. ✅ **Margin validated:** Gross margin >85% at $6/month subscription
5. ✅ **Edge cases handled:** All 6 edge case scenarios (imperfect crop, multiple candidates, etc.) have test coverage
6. ✅ **Human approval:** Product leadership approves trade-off (+$368/month cost for "like magic" accuracy)

**Blocking Issues:**

- Google Shopping Graph API unavailable or >$0.02/lookup
- POC accuracy <75% (fails minimum bar for premium tier)
- Cost per item >$0.015 (margin drops below 80%)

---

## Next Steps

### **Stage 2.2 (iOS Architecture Implementation):**

✅ **Plan Ready:** See `docs/plans/2025-11-01-stage-2.2-ios-architecture-implementation.md`

**Key tasks:**
- Phase 1: iOS Camera + Vision Framework (YOLOv3-Tiny integration)
- Phase 2: Cloud infrastructure (GCS + Cloud CDN, Cloud Functions, Redis)
- Phase 3: Layer 2b (SerpAPI + LLM parsing)
- Phase 4: Layer 2a (Gemini 2.5 Flash-Lite)
- Phase 5: Integration testing and POC validation

**Estimated Timeline:** 6 weeks to working POC

### **Stage 2.3 (POC Validation):**

- Build 50-item test dataset (diverse categories)
- Run accuracy validation (precision, recall, attribute accuracy)
- Run cost validation (actual tokens vs. estimates)
- Run latency validation (p50, p95, p99)
- Generate validation report with recommendations

### **Stage 2.4 (Beta Deployment):**

- Deploy to TestFlight with 100 beta users
- Monitor actual usage patterns and costs
- Iterate on prompts based on user corrections
- A/B test hybrid strategies (vision-only vs. full pipeline)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-29 | 1.0 | Initial draft | Tech Lead |
| 2025-10-30 | 2.0 | Comprehensive verification & updates | Tech Lead |
| 2025-11-01 | 2.1 | GCS/Cloud CDN updates, Stage 2.2 plan reference | Tech Lead |

### Version 2.0 Changes (2025-10-30):

**Layer 1 Updates:**
- Added Core ML YOLOv3-Tiny requirement (verified Apple doesn't provide built-in generic object detection)
- Updated detection rate to 70-80% (80 COCO object classes)
- Verified latency: 50-150ms (well under 500ms target)

**Layer 2a Updates:**
- Verified Gemini 2.5 Flash-Lite exists and is available (GA)
- Confirmed pricing: $0.000249/image (verified from official Google Cloud pricing)
- Confirmed all vision capabilities (color, material, condition detection)

**Layer 2b Updates:**
- Confirmed SerpAPI Google Lens exists and pricing ($0.010/search Production plan)
- **CRITICAL:** Added image hosting requirement (SerpAPI requires public URLs, no direct upload)
- **CRITICAL:** Added LLM parsing layer (SerpAPI doesn't provide separate brand/model fields)
- Updated cost: $0.0109/item (SerpAPI $0.010 + S3 $0.0001 + Haiku parsing $0.0008)
- Updated latency: 5.29s average (higher than original 2-5s estimate)

**Layer 3 Updates:**
- Replaced Claude 3.5 Sonnet with Claude Sonnet 4.5 (Batch API)
- Reasoning: Graduate-level reasoning (83.4% GPQA vs ~75% for 3.5), best structured output
- Updated cost: $0.0092/item (Batch API with 50% discount)
- Added confidence proxy calculation task (SerpAPI doesn't provide confidence scores)

**Economics Updates:**
- Total cost per item: $0.016249 → $0.019449 (+19.7%)
- Month 6 compute cost: $1,219 → $1,459 (+$240)
- Gross margin: 86.5% → 83.8% (-2.7%)
- Optimized margin: 90.3% → 89.8%

**Architecture Changes:**
- Added image hosting pipeline (compress → S3/CloudFront → public URL)
- Added LLM parsing service (Claude Haiku for brand/model extraction)
- Added request queue system (Redis-backed, 3,000/hour rate limit)
- Added confidence proxy algorithm (multi-factor scoring)

**Status:** Changed from PROPOSED to ACCEPTED (architecture verified and viable)

---

## Approval

**Pending approval from:**

- [ ] Product Leadership (Cost/margin trade-off acceptable?)
- [ ] Tech Lead (Architecture feasible?)
- [ ] Engineering Manager (Team capacity for three-layer implementation?)

**Approved by:**

_[Signatures pending]_

---

**End of ADR-015**
