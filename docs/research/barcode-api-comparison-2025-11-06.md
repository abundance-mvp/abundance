# Barcode Lookup API Comparison & Recommendation

**Research Date**: 2025-11-06
**Researcher**: Claude (via verified-stage-development skill)
**Purpose**: Select optimal barcode product lookup API for barcode scanning feature (FEATURE-BARCODE-001)
**Related Documents**: ADR-018, PLAN-SUMMARY-barcode-scanning-feature.md

---

## Executive Summary

**Recommendation**: **UPCitemdb.com PRO plan** ($699/month)

**Rationale**:
- Best cost per lookup: **$0.0047** (at expected 150K lookups/month)
- High daily limit: 150K requests/day = 4.5M/month capacity
- Covers expected growth through Month 12
- JSON API with product details (name, brand, images, specs)
- Established service with good reliability

**Runner-up**: OpenFoodFacts (free) for food items only, with UPCitemdb as paid fallback for non-food items

---

## Research Methodology

### Expected Usage Projections

Based on PLAN-SUMMARY-barcode-scanning-feature.md:

| Metric | Month 6 | Month 12 | Year 1 Total |
|--------|---------|----------|--------------|
| Total items cataloged | 75,000 | 150,000 | ~900,000 |
| Items with barcodes (50%) | 37,500 | 75,000 | ~450,000 |
| Barcode API lookups needed | 37,500 | 75,000 | ~450,000 |

**Average monthly lookups**: ~37.5K (Month 6), ~75K (Month 12), ~37.5K blended (Year 1)

### Cost Calculation Formula

```
Cost per lookup = Monthly plan cost / Expected monthly lookups
```

For Month 6: `Cost per lookup = Plan cost / 37,500`
For Month 12: `Cost per lookup = Plan cost / 75,000`

---

## API Comparison Table

| API Provider | Plan | Monthly Cost | Request Limit | Cost per Lookup (Month 6) | Cost per Lookup (Month 12) | Database Size | Coverage |
|--------------|------|--------------|---------------|---------------------------|----------------------------|---------------|----------|
| **UPCitemdb** | Free | $0 | 100/day = 3K/month | $0 | $0 | Not disclosed | Global UPC/EAN |
| **UPCitemdb** | DEV | $99 | 20K/day = 600K/month | **$0.0026** | **$0.0013** | Not disclosed | Global UPC/EAN |
| **UPCitemdb** | PRO | $699 | 150K/day = 4.5M/month | **$0.0186** | **$0.0093** | Not disclosed | Global UPC/EAN |
| **Go-UPC** | Developer | $74.95 | 5K/month | $0.0150 (OVER LIMIT) | $0.0010 (OVER LIMIT) | 500M+ records | Global UPC/EAN/ISBN |
| **Go-UPC** | Startup | $245 | 45K/month | **$0.0065** | $0.0033 (OVER LIMIT) | 500M+ records | Global UPC/EAN/ISBN |
| **Go-UPC** | Enterprise | $795 | 450K/month | **$0.0212** | **$0.0106** | 500M+ records | Global UPC/EAN/ISBN |
| **Barcode Lookup** | Basic | ~$99 | Unknown | Unknown | Unknown | Unknown | Global UPC/EAN |
| **Barcode Spider** | Unknown | Unknown | Unknown | Unknown | Unknown | 500M-1.5B records | Asia/Europe/Americas |
| **OpenFoodFacts** | Free | $0 | Unlimited (fair use) | **$0** | **$0** | 3M+ food products | Global food only |

**OVER LIMIT** = Expected usage exceeds plan's monthly request limit

---

## Detailed API Analysis

### 1. UPCitemdb.com

**Website**: https://www.upcitemdb.com/

#### Pricing Tiers
1. **Free Tier**
   - Cost: $0/month
   - Limit: 100 requests/day (3,000/month)
   - **Assessment**: INSUFFICIENT for production (need 37.5K/month minimum)

2. **DEV Tier** ⭐ **BEST VALUE FOR MONTH 6**
   - Cost: $99/month
   - Limit: 20,000 requests/day (600,000/month)
   - Cost per lookup (Month 6): **$0.0026**
   - Cost per lookup (Month 12): **$0.0013**
   - **Assessment**: Perfect fit for Month 6-12, excellent value

3. **PRO Tier**
   - Cost: $699/month
   - Limit: 150,000 requests/day (4.5M/month)
   - Cost per lookup (Month 6): **$0.0186**
   - Cost per lookup (Month 12): **$0.0093**
   - **Assessment**: Overkill for current needs, room for growth

#### Features
- JSON API responses
- Product name, brand, manufacturer, images
- UPC-A, UPC-E, EAN-13, EAN-8 support
- Response time: Typically <200ms
- 99.9% uptime SLA (paid plans)

#### Database Coverage
- Size: Not publicly disclosed
- Geographic: Global coverage
- Categories: General retail, electronics, books, groceries

#### Pros
- ✅ Clear pricing structure
- ✅ High daily limits prevent overages
- ✅ Excellent value at DEV tier ($0.0026/lookup)
- ✅ JSON API with comprehensive data
- ✅ Good documentation

#### Cons
- ❌ Database size not disclosed
- ❌ Match rate unknown (need testing)
- ❌ Large price jump between tiers ($99 → $699)

---

### 2. Go-UPC

**Website**: https://go-upc.com/

#### Pricing Tiers
1. **Developer**
   - Cost: $74.95/month
   - Limit: 5,000 requests/month
   - **Assessment**: INSUFFICIENT (37.5K needed)

2. **Startup**
   - Cost: $245/month
   - Limit: 45,000 requests/month
   - Cost per lookup (Month 6): **$0.0065**
   - **Assessment**: Covers Month 6 (37.5K), but INSUFFICIENT for Month 12 (75K)

3. **Enterprise**
   - Cost: $795/month
   - Limit: 450,000 requests/month
   - Cost per lookup (Month 6): **$0.0212**
   - Cost per lookup (Month 12): **$0.0106**
   - **Assessment**: Expensive for current needs, good for Year 2+

#### Features
- RESTful JSON API
- Product details: name, brand, category, description, images
- UPC, EAN, ISBN support
- Bulk lookup capability
- Webhook notifications

#### Database Coverage
- Size: 500M+ records
- Geographic: Global
- Categories: Comprehensive retail coverage

#### Pros
- ✅ Large database (500M+ records)
- ✅ Bulk lookup support
- ✅ Webhook notifications (useful for async processing)
- ✅ Comprehensive product data

#### Cons
- ❌ Higher cost per lookup ($0.0065-$0.0212)
- ❌ Startup plan too small for Month 12
- ❌ Enterprise plan expensive for current scale
- ❌ No middle tier between $245 and $795

---

### 3. Barcode Lookup

**Website**: https://www.barcodelookup.com/

#### Pricing Tiers
- **Research Limited**: Website blocked pricing page (403 Forbidden)
- **Known Information**: ~$99/month mentioned in search results
- **Request Limits**: Unknown
- **Database Size**: Unknown

#### Assessment
❌ **NOT RECOMMENDED**: Cannot verify pricing, limits, or reliability

---

### 4. Barcode Spider

**Website**: https://www.barcodespider.com/

#### Pricing Tiers
- **Research Limited**: Pricing not disclosed on public pages
- **Free Trial**: 7-day trial available
- **Scalable Packages**: Mentioned but no specifics

#### Database Coverage
- Size: 500M to 1.5B records (claimed)
- Geographic: Asia, Europe, Americas
- Daily updates from manufacturers and retailers

#### Features
- JSON and CSV outputs
- Millisecond response times
- Bulk processing (thousands at once)
- Product name, image, description, specs, category, rating, prices

#### Assessment
⚠️ **CANNOT EVALUATE**: Pricing not publicly disclosed, requires contact for quote

---

### 5. OpenFoodFacts (Free Alternative)

**Website**: https://world.openfoodfacts.org/

#### Pricing
- **Cost**: $0 (free, forever)
- **Limit**: Unlimited (fair use policy: 1 API call = 1 real user scan)
- **Cost per lookup**: $0

#### Features
- RESTful JSON API
- Product name, brand, ingredients, nutrition, images
- EAN-13, UPC-A, UPC-E support
- Response time: <300ms typically
- Open Database License

#### Database Coverage
- Size: 3M+ food products
- Geographic: Global, 150+ countries
- Categories: **Food and beverage ONLY** (groceries, drinks, snacks)

#### Pros
- ✅ Completely free
- ✅ No rate limits (fair use)
- ✅ 3M+ food products
- ✅ High-quality nutrition data
- ✅ Open data, community-driven
- ✅ Fast response times

#### Cons
- ❌ **Food items only** (no electronics, household, etc.)
- ❌ Coverage gaps for niche/regional products
- ❌ Community-driven = inconsistent data quality
- ❌ No SLA or reliability guarantee
- ❌ Fair use policy may limit production usage

---

## Cost-Benefit Analysis

### Scenario 1: UPCitemdb DEV ($99/month)

| Month | Items | Barcode Lookups | Plan Cost | Cost per Lookup | Fallback to SerpAPI (20%)* | Total Monthly Cost |
|-------|-------|-----------------|-----------|-----------------|---------------------------|-------------------|
| 6 | 75,000 | 37,500 | $99 | $0.0026 | $75 (7,500 × $0.01) | **$174** |
| 12 | 150,000 | 75,000 | $99 | $0.0013 | $150 (15,000 × $0.01) | **$249** |

*Assumes 80% barcode match rate, 20% fallback to SerpAPI

**Annual Cost (Year 1)**: $99 × 12 = **$1,188** + SerpAPI fallback (~$1,350) = **$2,538 total**

**Savings vs. SerpAPI-only**:
- SerpAPI-only: 450K × $0.01 = $4,500
- Barcode hybrid: $2,538
- **Annual savings**: $1,962 (44% reduction)

---

### Scenario 2: OpenFoodFacts (Free) + UPCitemdb DEV for Non-Food

Assumes 40% of household items are food/beverage (reasonable household estimate):

| Month | Food Barcodes (40%, free) | Non-Food Barcodes (60%, paid) | UPCitemdb Cost | Cost per Lookup (blended) |
|-------|---------------------------|-------------------------------|----------------|---------------------------|
| 6 | 15,000 (free) | 22,500 ($99) | $99 | **$0.0044** |
| 12 | 30,000 (free) | 45,000 ($99) | $99 | **$0.0022** |

**Annual Cost (Year 1)**: $99 × 12 = **$1,188** + SerpAPI fallback (~$810) = **$1,998 total**

**Savings vs. SerpAPI-only**: **$2,502 (56% reduction)**

**Pros**:
- ✅ Lower cost ($1,998 vs. $2,538)
- ✅ Leverages free OpenFoodFacts for groceries
- ✅ Higher accuracy for food items (nutrition data bonus)

**Cons**:
- ❌ More complex implementation (2 APIs)
- ❌ Need category detection logic (food vs. non-food)
- ❌ OpenFoodFacts coverage gaps for obscure brands

---

### Scenario 3: Go-UPC Startup ($245/month)

| Month | Items | Barcode Lookups | Plan Cost | Cost per Lookup | Fallback to SerpAPI (20%) | Total Monthly Cost |
|-------|-------|-----------------|-----------|-----------------|---------------------------|-------------------|
| 6 | 75,000 | 37,500 | $245 | $0.0065 | $75 | **$320** |
| 12 | 150,000 | 75,000 | **OVER LIMIT** (45K max) | N/A | N/A | N/A |

**Assessment**: ❌ Startup plan insufficient for Month 12 (75K > 45K limit)

Would need Enterprise plan ($795/month) for Month 12:

| Month | Items | Barcode Lookups | Plan Cost | Cost per Lookup | Total Monthly Cost |
|-------|-------|-----------------|-----------|-----------------|-------------------|
| 12 | 150,000 | 75,000 | $795 | $0.0106 | **$945** |

**Annual Cost (blended)**: ~$6,000 (too expensive)

---

## Final Recommendation

### **Primary Recommendation: UPCitemdb DEV ($99/month)**

**Justification**:
1. **Best value**: $0.0026/lookup at Month 6, $0.0013/lookup at Month 12
2. **Sufficient capacity**: 600K requests/month covers projected growth through Year 2
3. **Clear pricing**: No surprises, predictable costs
4. **Proven service**: Established provider with JSON API
5. **Cost savings**: 44% reduction vs. SerpAPI-only approach ($1,962/year saved)

**Implementation**:
- Sign up for UPCitemdb DEV plan immediately
- API endpoint: `https://api.upcitemdb.com/prod/trial/lookup?upc={barcode}`
- Store API key in environment variables: `UPC_DATABASE_API_KEY`
- Set timeout: 2 seconds
- Fallback to SerpAPI on 404 or timeout

---

### **Alternative Recommendation: Hybrid Approach**

**Strategy**: OpenFoodFacts (free) for food + UPCitemdb DEV for non-food

**Justification**:
1. **Lower cost**: $1,998/year vs. $2,538 (21% cheaper)
2. **Better food data**: Nutrition, ingredients, allergens
3. **Zero cost for 40% of items** (food/beverage)
4. **Still predictable**: UPCitemdb handles non-food overflow

**Implementation Complexity**:
- Add category detection logic (food vs. non-food)
- Two API integrations instead of one
- Fallback chain: OpenFoodFacts → UPCitemdb → SerpAPI

**Recommendation**: Use hybrid approach IF:
- Team has capacity for dual API integration
- Food items are >35% of catalog
- Nutrition data adds significant user value

Otherwise, stick with UPCitemdb-only for simplicity.

---

## Testing Plan

Before finalizing API selection, conduct a **48-hour pilot test**:

### Test Dataset
- **100 real household product barcodes**:
  - 40 food/beverage (groceries, snacks, drinks)
  - 30 electronics (cables, batteries, devices)
  - 20 household (cleaning, toiletries, tools)
  - 10 books/media (ISBN barcodes)

### Metrics to Measure
1. **Match rate**: % of barcodes successfully resolved
2. **Data quality**: Completeness of name, brand, image, category
3. **Response time**: p50, p95, p99 latency
4. **Error rate**: 404s, timeouts, malformed responses

### Success Criteria
- Match rate: >80%
- Data quality: >90% have name + brand + image
- Response time: p95 <500ms
- Error rate: <5%

### APIs to Test
1. UPCitemdb (free tier, 100 requests)
2. OpenFoodFacts (free, unlimited)
3. Go-UPC (request trial API key)

**Decision Rule**: Choose API with highest match rate × data quality score

---

## Risk Assessment

### Risk 1: UPCitemdb Match Rate <80%

**Likelihood**: Medium
**Impact**: Medium (more SerpAPI fallbacks = higher cost)

**Mitigation**:
- Test with 100 real barcodes before committing
- If match rate <75%, switch to Go-UPC or hybrid approach
- Monitor match rate in production; reevaluate quarterly

**Trigger**: If match rate <70% after 1,000 lookups → Switch APIs

---

### Risk 2: UPCitemdb Service Reliability

**Likelihood**: Low
**Impact**: High (pipeline blocked if API down)

**Mitigation**:
- Implement 2-second timeout with automatic SerpAPI fallback
- Monitor uptime via health check endpoint
- Store API keys for 2 backup providers (Go-UPC, Barcode Lookup)
- Cache common products (top 1,000 barcodes) locally

**Trigger**: If uptime <99% for 7 days → Activate backup API

---

### Risk 3: Cost Overrun (Usage Exceeds Projections)

**Likelihood**: Low
**Impact**: Medium (unexpected costs)

**Mitigation**:
- Set CloudWatch alert at 500K requests/month (83% of limit)
- DEV plan has 600K/month capacity (16× current needs)
- Hot-swappable API architecture (can switch providers in <1 day)

**Trigger**: If usage >400K/month → Evaluate PRO plan upgrade or hybrid approach

---

## Implementation Checklist

- [ ] Sign up for UPCitemdb DEV plan ($99/month)
- [ ] Generate API key and test with 10 sample UPCs
- [ ] Store API key in Cloud Functions environment variables
- [ ] Implement `lookupBarcode()` function with 2s timeout
- [ ] Add fallback logic: UPCitemdb → SerpAPI
- [ ] Test with 100-barcode pilot dataset
- [ ] Measure match rate, latency, data quality
- [ ] Deploy to staging environment
- [ ] Monitor for 7 days
- [ ] Deploy to production (canary rollout)
- [ ] Set up CloudWatch alerts (uptime, usage, cost)

---

## Monitoring & Alerts

### Metrics to Track

| Metric | Target | Alert Threshold |
|--------|--------|----------------|
| Barcode match rate | >80% | <75% |
| API response time (p95) | <500ms | >1000ms |
| API error rate | <5% | >10% |
| Monthly API usage | <400K | >500K |
| Monthly API cost | ~$99 | >$150 |
| Fallback rate (SerpAPI) | <25% | >40% |

### CloudWatch Dashboards
1. **Barcode API Health**: Uptime, error rate, latency
2. **Cost Tracking**: Daily/monthly usage, projected costs
3. **Data Quality**: Match rate, data completeness

---

## Quarterly Review Criteria

**Review every 3 months**:

1. **Match Rate**: Is UPCitemdb resolving >80% of barcodes?
2. **Cost**: Is blended cost still <$0.018/item?
3. **Latency**: Is p95 latency <500ms?
4. **Scale**: Will DEV plan (600K/month) suffice for next quarter?
5. **Alternatives**: Have competitors launched better pricing?

**Action Items**:
- If match rate drops: Test Go-UPC or hybrid approach
- If usage approaches 500K/month: Upgrade to PRO plan or negotiate custom pricing
- If new API launches with better pricing: Run pilot test

---

## Appendix A: API Endpoint Examples

### UPCitemdb
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     "https://api.upcitemdb.com/prod/trial/lookup?upc=012345678905"
```

Response:
```json
{
  "code": "OK",
  "total": 1,
  "items": [{
    "ean": "0012345678905",
    "title": "Example Product",
    "brand": "Example Brand",
    "category": "Electronics",
    "images": ["https://..."],
    "description": "..."
  }]
}
```

### OpenFoodFacts
```bash
curl "https://world.openfoodfacts.net/api/v2/product/012345678905"
```

Response:
```json
{
  "code": "012345678905",
  "product": {
    "product_name": "Example Food",
    "brands": "Example Brand",
    "image_url": "https://...",
    "categories": "Snacks",
    "nutriments": { "energy": 500, ... }
  }
}
```

---

## Appendix B: Cost Model Spreadsheet

| Month | Items Cataloged | Barcoded Items (50%) | UPCitemdb DEV Cost | Match Rate | SerpAPI Fallback (20%) | Fallback Cost | Total Cost | Cost per Item |
|-------|-----------------|---------------------|-------------------|------------|------------------------|---------------|------------|---------------|
| 1 | 5,000 | 2,500 | $99 | 80% | 500 | $5 | $104 | $0.021 |
| 2 | 10,000 | 5,000 | $99 | 80% | 1,000 | $10 | $109 | $0.011 |
| 3 | 20,000 | 10,000 | $99 | 80% | 2,000 | $20 | $119 | $0.006 |
| 6 | 75,000 | 37,500 | $99 | 80% | 7,500 | $75 | $174 | $0.0046 |
| 12 | 150,000 | 75,000 | $99 | 80% | 15,000 | $150 | $249 | $0.0033 |

**Blended Cost Calculation**:
- Barcoded items: $99/month + fallback cost
- Non-barcoded items (50%): SerpAPI at $0.01/item
- **Month 6 total**: $174 (barcode) + $375 (non-barcode) = **$549/month** for 75K items
- **Month 6 per-item cost**: $549 / 75,000 = **$0.0073**

**Comparison to SerpAPI-only**:
- SerpAPI-only (Month 6): 75,000 × $0.01 = $750
- Barcode hybrid (Month 6): $549
- **Savings**: $201/month = **$2,412/year**

---

**Document ID**: RESEARCH-BARCODE-API-2025-11-06
**Status**: Complete
**Next Steps**: Update ADR-018 with UPCitemdb selection, begin implementation

