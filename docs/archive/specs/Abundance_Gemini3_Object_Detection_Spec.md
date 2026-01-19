# Gemini 3 Multi-Object Detection Specification

*Technical Integration Guide for the Abundance App*

**Version 1.0 | January 2026**

---

## Executive Summary

This specification document outlines how to leverage Google's Gemini 3 model family for detecting and cataloging multiple objects across single or multiple images in the Abundance app. Based on comprehensive analysis of Google's developer documentation, **Gemini 3 Flash is recommended as the primary model** for high-throughput object detection workflows, with Gemini 3 Pro reserved for complex visual reasoning tasks.

---

## 1. Model Selection Recommendation

For the Abundance app's multi-object detection and cataloging use case, the following model hierarchy is recommended:

| Model | Best For | Pricing (per 1M tokens) | Key Advantage |
|-------|----------|-------------------------|---------------|
| **gemini-3-flash-preview** | High-throughput cataloging | $0.50 / $3 | 3x faster, free tier available |
| **gemini-3-pro-preview** | Complex reasoning | $2 / $12 (<200k) | Best visual reasoning |
| **gemini-2.5-flash** | Segmentation masks | Legacy pricing | Required if pixel masks needed |

> ⚠️ **Important:** Gemini 3 Pro and Flash do NOT support image segmentation (pixel-level masks). If your cataloging requires precise object boundaries, use Gemini 2.5 Flash with thinking disabled.

---

## 2. Technical Specifications

### 2.1 Context Window & Limits

- **Input Context:** 1,000,000 tokens
- **Output Limit:** 64,000 tokens
- **Maximum Images:** 3,600 images per request
- **Knowledge Cutoff:** January 2025

### 2.2 Bounding Box Output Format

Gemini returns bounding boxes as normalized coordinates scaled to [0, 1000]. The format is:

```
[ymin, xmin, ymax, xmax]
```

You must descale these coordinates based on your original image dimensions:

```python
abs_x = int(normalized_x / 1000 * image_width)
abs_y = int(normalized_y / 1000 * image_height)
```

### 2.3 Media Resolution Settings

Gemini 3 introduces per-part media resolution control. This is critical for optimizing cost when processing many images:

| Resolution Level | Tokens/Image | Use Case |
|------------------|--------------|----------|
| `media_resolution_low` | 280 | Simple scene recognition, bulk processing |
| `media_resolution_medium` | 560 | **Object detection, cataloging (recommended)** |
| `media_resolution_high` | 1,120 | Fine text, small object details |
| `media_resolution_ultra_high` | 2,240 | Per-part only; complex diagrams |

> 💰 **Cost Optimization Tip:** Using LOW instead of HIGH saves 75% of tokens per image. For a batch of 100 images, this means 84,000 tokens saved.

---

## 3. API Implementation

### 3.1 Multi-Object Detection Request

The following Python code demonstrates detecting all objects in an image with structured JSON output:

```python
from google import genai
from google.genai import types
from PIL import Image
import json

client = genai.Client()

prompt = '''Detect all objects in this image.
Return JSON array with:
- "label": descriptive object name
- "box_2d": [ymin, xmin, ymax, xmax] (0-1000)
- "confidence": detection confidence
- "category": object category'''

image = Image.open("/path/to/image.jpg")

config = types.GenerateContentConfig(
    response_mime_type="application/json",
    thinking_config=types.ThinkingConfig(
        thinking_level="low"  # Faster for detection
    )
)

response = client.models.generate_content(
    model="gemini-3-flash-preview",
    contents=[image, prompt],
    config=config
)

# Parse and convert bounding boxes
width, height = image.size
objects = json.loads(response.text)

for obj in objects:
    box = obj["box_2d"]
    abs_coords = {
        "x1": int(box[1] / 1000 * width),
        "y1": int(box[0] / 1000 * height),
        "x2": int(box[3] / 1000 * width),
        "y2": int(box[2] / 1000 * height)
    }
    print(f"{obj['label']}: {abs_coords}")
```

### 3.2 Batch Processing Multiple Images

For cataloging across multiple images, use per-part media resolution control:

```python
from google import genai
from google.genai import types
import base64

# Use v1alpha for per-part media resolution
client = genai.Client(
    http_options={'api_version': 'v1alpha'}
)

prompt = '''Detect and catalog all objects across these images.
Return JSON array with:
- "label": object name
- "box_2d": [ymin, xmin, ymax, xmax] (0-1000)
- "category": object category
- "image_index": which image (0-indexed)
- "attributes": {color, material, condition}'''

def load_image_part(image_path, resolution="media_resolution_medium"):
    with open(image_path, "rb") as f:
        image_bytes = f.read()
    
    return types.Part(
        inline_data=types.Blob(
            mime_type="image/jpeg",
            data=image_bytes
        ),
        media_resolution={"level": resolution}
    )

# Process multiple images with optimized resolution
contents = [
    types.Part(text=prompt),
    load_image_part("image1.jpg", "media_resolution_medium"),
    load_image_part("image2.jpg", "media_resolution_medium"),
    load_image_part("image3.jpg", "media_resolution_low"),  # Simpler image
]

config = types.GenerateContentConfig(
    response_mime_type="application/json",
    thinking_config=types.ThinkingConfig(thinking_level="low")
)

response = client.models.generate_content(
    model="gemini-3-flash-preview",
    contents=contents,
    config=config
)

catalog = json.loads(response.text)
```

### 3.3 Custom Object Detection Prompts

Gemini supports custom detection criteria and labels:

```python
# Detect specific categories
prompt = '''Detect only furniture items in this image.
Label each with its specific type (chair, table, sofa, etc.)
Return bounding boxes in [ymin, xmin, ymax, xmax] format.'''

# Detect with custom attributes
prompt = '''Detect all items and label them with:
- The allergens they may contain (for food items)
- The material type (for objects)
Return as JSON with box_2d and custom_label fields.'''

# Detect by color/property
prompt = '''Show bounding boxes for all green objects in this image.
Return JSON with label and box_2d fields.'''
```

---

## 4. Thinking Level Configuration

For object detection tasks, optimize thinking level based on complexity:

| Level | Use Case | Impact |
|-------|----------|--------|
| `minimal` | Basic object listing (Flash only) | Fastest, lowest cost |
| `low` | Standard object detection | **RECOMMENDED for cataloging** |
| `high` | Complex scene analysis | More accurate for ambiguous objects |

```python
# For simple detection (fastest)
config = types.GenerateContentConfig(
    thinking_config=types.ThinkingConfig(thinking_level="low")
)

# For complex scenes requiring reasoning
config = types.GenerateContentConfig(
    thinking_config=types.ThinkingConfig(thinking_level="high")
)

# Disable thinking entirely for maximum speed (best for basic detection)
config = types.GenerateContentConfig(
    thinking_config=types.ThinkingConfig(thinking_budget=0)
)
```

> 📝 **Note:** Setting `thinking_budget=0` is recommended when accuracy for simple spatial understanding tasks like object detection is sufficient with minimal reasoning.

---

## 5. Recommended JSON Schema for Cataloging

Define a structured output schema for consistent catalog entries:

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "label": {
        "type": "string",
        "description": "Descriptive name of the detected object"
      },
      "category": {
        "type": "string",
        "description": "High-level category (furniture, electronics, clothing, etc.)"
      },
      "box_2d": {
        "type": "array",
        "items": { "type": "integer" },
        "minItems": 4,
        "maxItems": 4,
        "description": "[ymin, xmin, ymax, xmax] normalized 0-1000"
      },
      "attributes": {
        "type": "object",
        "properties": {
          "color": { "type": "string" },
          "material": { "type": "string" },
          "condition": { "type": "string" },
          "brand": { "type": "string" },
          "estimated_value": { "type": "string" }
        }
      },
      "image_index": {
        "type": "integer",
        "description": "Index of source image (for multi-image requests)"
      }
    },
    "required": ["label", "box_2d", "category"]
  }
}
```

### Using with Pydantic (Python)

```python
from pydantic import BaseModel, Field
from typing import List, Optional

class ObjectAttributes(BaseModel):
    color: Optional[str] = None
    material: Optional[str] = None
    condition: Optional[str] = None
    brand: Optional[str] = None

class DetectedObject(BaseModel):
    label: str = Field(description="Descriptive name of the object")
    category: str = Field(description="High-level category")
    box_2d: List[int] = Field(description="[ymin, xmin, ymax, xmax] 0-1000")
    attributes: Optional[ObjectAttributes] = None
    image_index: Optional[int] = Field(default=0)

class CatalogResponse(BaseModel):
    objects: List[DetectedObject]

# Use with structured output
config = types.GenerateContentConfig(
    response_mime_type="application/json",
    response_json_schema=CatalogResponse.model_json_schema()
)
```

---

## 6. Cost Optimization Strategies

1. **Use Gemini 3 Flash:** 75% cheaper than Pro with comparable detection accuracy

2. **Set `media_resolution_medium`:** Optimal balance for object detection (560 tokens vs 1120 for high)

3. **Use `thinking_level="low"`:** Faster responses, lower compute for straightforward detection

4. **Batch process:** Send multiple images per request (up to 3,600) to reduce overhead

5. **Enable context caching:** 90% token cost reduction for repeated prompts with same context
   ```python
   response = client.models.generate_content(
       model="gemini-3-flash-preview",
       contents=prompt,
       config={"cached_content": "your-cache-id"}
   )
   ```

6. **Stay under 200K tokens:** 50% savings on input costs, 33% on output costs

### Cost Comparison Example

For processing 100 images at different settings:

| Configuration | Tokens | Cost (Flash) |
|--------------|--------|--------------|
| HIGH resolution | 112,000 | ~$0.056 |
| MEDIUM resolution | 56,000 | ~$0.028 |
| LOW resolution | 28,000 | ~$0.014 |

---

## 7. Known Limitations

- **No Segmentation in Gemini 3:** Pixel-level masks require Gemini 2.5 Flash with thinking disabled

- **Spatial Reasoning:** Models may return approximate counts; verify for precise counting

- **Low-Quality Images:** May hallucinate or miss objects; ensure proper lighting/resolution

- **Celebrity Recognition:** Designed for objects, not people identification

- **Temperature Setting:** Keep at default 1.0; lower values may cause looping

- **Tool Combination:** Cannot combine built-in tools (Search, Code Execution) with function calling in Gemini 3

---

## 8. Error Handling

```python
import json

def parse_detection_response(response_text):
    """Safely parse Gemini detection response."""
    # Handle markdown fencing if present
    text = response_text.strip()
    if text.startswith("```json"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")
        return []

def validate_bounding_box(box):
    """Validate bounding box format."""
    if not isinstance(box, list) or len(box) != 4:
        return False
    return all(0 <= coord <= 1000 for coord in box)
```

---

## 9. Complete Integration Example

```python
from google import genai
from google.genai import types
from PIL import Image
import json
from pathlib import Path

class AbundanceCatalogger:
    def __init__(self):
        self.client = genai.Client(
            http_options={'api_version': 'v1alpha'}
        )
        self.model = "gemini-3-flash-preview"
    
    def catalog_images(self, image_paths: list[str]) -> list[dict]:
        """Detect and catalog objects across multiple images."""
        
        prompt = '''Analyze these images and catalog all visible items.
        For each object, provide:
        - label: specific name (e.g., "leather armchair" not just "chair")
        - category: broad category
        - box_2d: [ymin, xmin, ymax, xmax] normalized 0-1000
        - attributes: color, material, condition, estimated_value
        - image_index: which image (0-indexed)
        
        Return as JSON array.'''
        
        contents = [types.Part(text=prompt)]
        
        # Add images with appropriate resolution
        for i, path in enumerate(image_paths):
            with open(path, "rb") as f:
                contents.append(types.Part(
                    inline_data=types.Blob(
                        mime_type="image/jpeg",
                        data=f.read()
                    ),
                    media_resolution={"level": "media_resolution_medium"}
                ))
        
        config = types.GenerateContentConfig(
            response_mime_type="application/json",
            thinking_config=types.ThinkingConfig(thinking_level="low")
        )
        
        response = self.client.models.generate_content(
            model=self.model,
            contents=contents,
            config=config
        )
        
        # Parse and enrich with absolute coordinates
        catalog = json.loads(response.text)
        
        for item in catalog:
            img_idx = item.get("image_index", 0)
            if img_idx < len(image_paths):
                img = Image.open(image_paths[img_idx])
                w, h = img.size
                box = item["box_2d"]
                item["absolute_coords"] = {
                    "x1": int(box[1] / 1000 * w),
                    "y1": int(box[0] / 1000 * h),
                    "x2": int(box[3] / 1000 * w),
                    "y2": int(box[2] / 1000 * h)
                }
        
        return catalog

# Usage
catalogger = AbundanceCatalogger()
results = catalogger.catalog_images([
    "room1.jpg",
    "room2.jpg",
    "garage.jpg"
])

for item in results:
    print(f"{item['label']} ({item['category']})")
    print(f"  Location: Image {item['image_index']}")
    print(f"  Coords: {item.get('absolute_coords')}")
    print(f"  Attributes: {item.get('attributes', {})}")
```

---

## 10. References

- **Gemini 3 Developer Guide:** https://ai.google.dev/gemini-api/docs/gemini-3
- **Image Understanding:** https://ai.google.dev/gemini-api/docs/image-understanding
- **Gemini 3 Pro Vision Blog:** https://blog.google/technology/developers/gemini-3-pro-vision
- **Spatial Understanding Notebook:** https://github.com/google-gemini/cookbook
- **Media Resolution Guide:** https://ai.google.dev/gemini-api/docs/media-resolution
- **Structured Outputs:** https://ai.google.dev/gemini-api/docs/structured-output

---

*Document generated January 2026 based on Google's official Gemini 3 documentation.*
