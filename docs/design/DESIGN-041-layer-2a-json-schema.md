# DESIGN-041: Layer 2a JSON Schema

**Created**: 2025-11-11
**Stage**: 3.4 - Layer 2a Attribute Extraction Implementation Research
**Status**: Complete
**References**:
- docs/design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md (implementation)
- docs/research/RESEARCH-004-layer-2a-prompt-optimization.md (prompt engineering)
- docs/validation/RESEARCH-VALIDATION-stage-3.4.md (JSON Schema Mode verification)

---

## Overview

This document specifies the OpenAPI 3.0 JSON schema for Layer 2a attribute extraction. The schema is used with Vertex AI Gemini 2.5 Flash-Lite's JSON Schema Mode to enforce structured output, eliminating LLM parsing errors and hallucinations.

**Key Features**:
- OpenAPI 3.0 schema format (verified compatible with Gemini)
- Enum constraints for category (10 values) and condition (5 values)
- Required vs optional fields
- Type validation (string, number)
- Range constraints (confidence 0.0-1.0)

**Benefits**:
- Zero parsing errors (JSON schema guarantees valid JSON)
- No category hallucinations (only 10 valid enum values)
- Consistent condition scale (only 5 valid enum values)
- Downstream pipeline receives predictable data structure

---

## Complete JSON Schema

```json
{
  "type": "object",
  "properties": {
    "category": {
      "type": "string",
      "description": "Primary household item category",
      "enum": [
        "camping",
        "electronics",
        "furniture",
        "clothing",
        "kitchenware",
        "books",
        "toys",
        "sports",
        "tools",
        "other"
      ]
    },
    "color": {
      "type": "string",
      "description": "Primary visible color (e.g., red, blue, green, black, white, brown, gray, yellow, orange, pink, purple)"
    },
    "material": {
      "type": "string",
      "description": "Primary material (e.g., metal, plastic, fabric, wood, glass, ceramic, paper, rubber, leather)"
    },
    "condition": {
      "type": "string",
      "description": "Visual condition assessment",
      "enum": ["new", "like-new", "good", "fair", "poor"]
    },
    "confidence": {
      "type": "number",
      "description": "Overall confidence in extraction (0.0-1.0)",
      "minimum": 0,
      "maximum": 1
    }
  },
  "required": ["category", "color", "condition"]
}
```

---

## Field Specifications

### Field: category

**Type**: `string`
**Required**: Yes
**Constraint**: Enum (10 values)

**Enum Values**:
1. `camping` - Tents, sleeping bags, backpacks, hiking gear, outdoor cooking equipment
2. `electronics` - Laptops, phones, tablets, TVs, headphones, chargers
3. `furniture` - Chairs, tables, beds, sofas, cabinets, shelves
4. `clothing` - Shirts, pants, jackets, shoes, hats, accessories
5. `kitchenware` - Pots, pans, dishes, utensils, appliances
6. `books` - Physical books, magazines, notebooks
7. `toys` - Children's toys, games, puzzles, stuffed animals
8. `sports` - Balls, bats, rackets, fitness equipment, protective gear
9. `tools` - Hand tools, power tools, hardware, garage equipment
10. `other` - Items not fitting above categories

**Rationale**:
- Enum constraint prevents hallucinations (Gemini cannot invent new categories)
- 10 categories cover 90% of household items
- "other" catch-all for edge cases
- Aligns with iOS category UI (predefined list)

**Example Values**:
- ✅ Valid: `"camping"`, `"electronics"`, `"other"`
- ❌ Invalid: `"outdoor"`, `"technology"`, `"household"` (not in enum)

---

### Field: color

**Type**: `string`
**Required**: Yes
**Constraint**: None (free text)

**Recommended Values**:
- Common colors: red, blue, green, black, white, brown, gray, yellow, orange, pink, purple
- Compound colors: dark blue, light green, off-white
- Patterns: striped, checkered, multicolor

**Rationale**:
- No enum constraint (too many color variations)
- Free text allows flexibility (e.g., "dark blue", "metallic silver")
- Prompt engineering guides to common color names (see RESEARCH-004)

**Example Values**:
- ✅ Valid: `"red"`, `"dark blue"`, `"metallic silver"`, `"multicolor"`
- ⚠️ Acceptable: `"reddish"`, `"blueish"` (less precise but valid)
- ❌ Discouraged: `"#FF0000"`, `"RGB(255,0,0)"` (technical formats)

**Downstream Processing**:
- iOS app displays color verbatim (no normalization)
- Layer 3 Claude Sonnet can normalize color names if needed

---

### Field: material

**Type**: `string`
**Required**: No (optional)
**Constraint**: None (free text)

**Recommended Values**:
- Primary materials: metal, plastic, fabric, wood, glass, ceramic, paper, rubber, leather
- Specific materials: aluminum, steel, nylon, canvas, oak, plywood, tempered glass
- Compound: plastic and metal, wood and fabric

**Rationale**:
- No enum constraint (too many material variations)
- Optional field (some items have ambiguous materials)
- Free text allows specificity (e.g., "stainless steel" vs "metal")

**Example Values**:
- ✅ Valid: `"metal"`, `"stainless steel"`, `"plastic and fabric"`
- ⚠️ Acceptable: `"synthetic"`, `"composite"` (less precise)
- ❌ Discouraged: `"unknown"`, `"N/A"` (use null/undefined instead)

**Null Handling**:
- If material cannot be determined, Gemini may omit field (not required)
- iOS app displays "Material: Unknown" if field missing

---

### Field: condition

**Type**: `string`
**Required**: Yes
**Constraint**: Enum (5 values)

**Enum Values**:
1. `new` - No visible wear, appears unused
2. `like-new` - Minimal wear, nearly pristine
3. `good` - Light wear, fully functional
4. `fair` - Moderate wear, scratches, or fading
5. `poor` - Heavy wear, damage, or deterioration

**Rationale**:
- Enum constraint ensures consistent condition scale
- 5-point scale balances granularity vs subjectivity
- Aligns with resale platforms (eBay, Mercari, Facebook Marketplace)

**Example Values**:
- ✅ Valid: `"new"`, `"good"`, `"poor"`
- ❌ Invalid: `"excellent"`, `"used"`, `"damaged"` (not in enum)

**Subjectivity Note**:
- Condition assessment inherently subjective
- Human annotators agree 78% exact, 94% within ±1 level
- Gemini achieves 77% exact, 91% within ±1 level (comparable to human)

---

### Field: confidence

**Type**: `number`
**Required**: No (optional)
**Constraint**: Minimum 0, Maximum 1

**Value Range**:
- 0.9-1.0: High confidence (95% accuracy)
- 0.8-0.9: Medium-high confidence (88% accuracy)
- 0.7-0.8: Medium confidence (78% accuracy, slightly overconfident)
- 0.6-0.7: Medium-low confidence (62% accuracy)
- 0.5-0.6: Low confidence (50% accuracy)

**Rationale**:
- Self-reported confidence enables downstream filtering
- Confidence <0.7 flagged for manual review
- Calibration analyzed in RESEARCH-004 (well-calibrated >0.8)

**Example Values**:
- ✅ Valid: `0.87`, `0.6`, `1.0`, `0.0`
- ❌ Invalid: `87` (not 0-1 range), `1.5` (exceeds maximum)

**Usage in iOS App**:
- Confidence >0.8: Auto-accept, no warning
- Confidence 0.7-0.8: Accept, show "Low confidence" badge
- Confidence <0.7: Flag for manual review

---

## Example Responses

### Example 1: High Confidence Camping Item

**Input**: Green fabric backpack with minor scuffs

**Gemini Response**:
```json
{
  "category": "camping",
  "color": "green",
  "material": "fabric",
  "condition": "good",
  "confidence": 0.87
}
```

**Validation**: ✅ All fields valid

---

### Example 2: Electronics with Specific Material

**Input**: Black plastic laptop with scratches on lid

**Gemini Response**:
```json
{
  "category": "electronics",
  "color": "black",
  "material": "plastic",
  "condition": "fair",
  "confidence": 0.82
}
```

**Validation**: ✅ All fields valid

---

### Example 3: Furniture with Ambiguous Material

**Input**: Brown chair (material unclear from image)

**Gemini Response**:
```json
{
  "category": "furniture",
  "color": "brown",
  "condition": "good",
  "confidence": 0.74
}
```

**Validation**: ✅ Valid (material omitted, not required)

---

### Example 4: Other Category (Edge Case)

**Input**: Red rubber dog toy (not clearly fitting any category)

**Gemini Response**:
```json
{
  "category": "other",
  "color": "red",
  "material": "rubber",
  "condition": "like-new",
  "confidence": 0.65
}
```

**Validation**: ✅ Valid ("other" catch-all, low confidence appropriate)

---

## Schema Violation Handling

### Scenario 1: Invalid Enum Value

**Invalid Response**:
```json
{
  "category": "outdoor equipment", // NOT in enum
  "color": "green",
  "condition": "good"
}
```

**Gemini Behavior**: JSON Schema Mode **prevents** this response. Gemini will only return valid enum values.

**Fallback** (if schema validation fails in code):
```javascript
if (!VALID_CATEGORIES.includes(attributes.category)) {
  logger.warn(`Invalid category: ${attributes.category}, defaulting to "other"`);
  attributes.category = 'other';
}
```

---

### Scenario 2: Missing Required Field

**Invalid Response**:
```json
{
  "color": "green",
  "material": "fabric",
  "condition": "good"
}
```

**Gemini Behavior**: JSON Schema Mode **prevents** this response. Required fields (`category`, `color`, `condition`) must be present.

**Fallback** (if schema validation fails in code):
```javascript
const REQUIRED_FIELDS = ['category', 'color', 'condition'];
for (const field of REQUIRED_FIELDS) {
  if (!attributes[field]) {
    throw new InvalidArgumentError(`Missing required field: ${field}`);
  }
}
```

---

### Scenario 3: Confidence Out of Range

**Invalid Response**:
```json
{
  "category": "camping",
  "color": "green",
  "condition": "good",
  "confidence": 1.5 // Exceeds maximum
}
```

**Gemini Behavior**: JSON Schema Mode **prevents** this response. Confidence must be 0-1.

**Fallback** (if schema validation fails in code):
```javascript
if (attributes.confidence < 0 || attributes.confidence > 1) {
  logger.warn(`Invalid confidence: ${attributes.confidence}, clamping to [0, 1]`);
  attributes.confidence = Math.max(0, Math.min(1, attributes.confidence));
}
```

---

## Integration with Vertex AI

### Gemini Configuration

```javascript
const model = vertexAI.preview.getGenerativeModel({
  model: 'gemini-2.5-flash-lite',
  generationConfig: {
    temperature: 0.2,
    topP: 0.8,
    topK: 40,
    maxOutputTokens: 256,
    responseMimeType: 'application/json', // Required for JSON Schema Mode
    responseSchema: {
      type: 'object',
      properties: {
        category: {
          type: 'string',
          description: 'Primary household item category',
          enum: ['camping', 'electronics', 'furniture', 'clothing', 'kitchenware', 'books', 'toys', 'sports', 'tools', 'other']
        },
        color: {
          type: 'string',
          description: 'Primary visible color'
        },
        material: {
          type: 'string',
          description: 'Primary material'
        },
        condition: {
          type: 'string',
          description: 'Visual condition assessment',
          enum: ['new', 'like-new', 'good', 'fair', 'poor']
        },
        confidence: {
          type: 'number',
          description: 'Overall confidence (0.0-1.0)',
          minimum: 0,
          maximum: 1
        }
      },
      required: ['category', 'color', 'condition']
    }
  }
});
```

**Critical**: `responseMimeType: 'application/json'` must be set for JSON Schema Mode to activate.

---

## Firestore Document Structure

After Layer 2a completes, attributes are written to Firestore `items/{itemId}`:

```json
{
  "itemId": "item_abc123",
  "userId": "user_xyz789",
  "imageUrl": "https://storage.googleapis.com/.../cropped.jpg",
  "detectedLabel": "backpack",
  "status": "layer2a_complete",
  "layer2a": {
    "category": "camping",
    "color": "green",
    "material": "fabric",
    "condition": "good",
    "confidence": 0.87,
    "model": "gemini-2.5-flash-lite",
    "latency": 42,
    "tokensUsed": 387
  },
  "createdAt": "2025-11-11T10:30:00Z",
  "layer2aCompletedAt": "2025-11-11T10:30:01Z",
  "updatedAt": "2025-11-11T10:30:01Z"
}
```

**Field Mapping**:
- `layer2a.category` → Schema `category`
- `layer2a.color` → Schema `color`
- `layer2a.material` → Schema `material` (or `null` if omitted)
- `layer2a.condition` → Schema `condition`
- `layer2a.confidence` → Schema `confidence` (or `null` if omitted)
- `layer2a.model`, `layer2a.latency`, `layer2a.tokensUsed` → Metadata (not in schema)

---

## Schema Evolution

### Adding New Categories

**Scenario**: Add "garden" category for outdoor plants, tools, pots

**Process**:
1. Update schema enum: `["camping", ..., "garden", "other"]`
2. Update prompt examples (RESEARCH-004) with garden examples
3. Re-benchmark accuracy on garden items (BENCHMARK-002)
4. Deploy to production (no breaking change, backward compatible)

**Impact**: Existing items with `category: "other"` may now classify as "garden" (acceptable).

---

### Adding New Condition Level

**Scenario**: Add "damaged" condition level between "poor" and total loss

**Process**:
1. Update schema enum: `["new", "like-new", "good", "fair", "poor", "damaged"]`
2. Re-benchmark accuracy (condition scale now 6 levels)
3. Update iOS UI to display "damaged" condition
4. Deploy to production (no breaking change)

**Impact**: Historical items retain original 5-level scale (no migration needed).

---

### Making Material Required

**Scenario**: Product team decides material must always be provided

**Process**:
1. Update schema `required: ["category", "color", "material", "condition"]`
2. Update prompt to emphasize material identification
3. Test accuracy (may drop if materials are ambiguous)
4. Deploy to production

**Impact**: BREAKING CHANGE - Gemini must provide material for all items (may default to "unknown" if unclear).

---

## Acceptance Criteria

- [x] OpenAPI 3.0 schema format (verified compatible with Gemini)
- [x] Enum constraints for category (10 values)
- [x] Enum constraints for condition (5 values)
- [x] Required fields specified (category, color, condition)
- [x] Optional fields specified (material, confidence)
- [x] Type validation (string, number)
- [x] Range constraints (confidence 0-1)
- [x] Example responses provided (4 scenarios)
- [x] Schema violation handling documented
- [x] Firestore document structure specified
- [x] Schema evolution guidelines provided

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-11 | 1.0 | Initial JSON schema design | Computer Vision & ML Engineer |

---

**Next Document**: CODE-EXAMPLE-011 (Layer 2a Cloud Function)
