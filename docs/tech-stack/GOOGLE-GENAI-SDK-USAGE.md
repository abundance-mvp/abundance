# Google Generative AI SDK Usage Guide

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/plans/PLAN-SUMMARY-stage-3.4.md (Layer 2a code examples)
**Status**: Draft

## Overview

This guide documents how to use the Google Generative AI SDK (`@google/genai`) for the Abundance AI pipeline. This is the current, officially supported SDK for Gemini models.

**IMPORTANT**: This project uses `@google/genai` (v1.29.0+), NOT the deprecated `@google-cloud/vertexai` package. All code examples and documentation have been migrated to the current SDK.

## Migration from Deprecated SDK

### Old (Deprecated): @google-cloud/vertexai

```typescript
// ❌ DO NOT USE - Deprecated as of 2024
import { VertexAI } from '@google-cloud/vertexai';

const vertex_ai = new VertexAI({
  project: 'your-project-id',
  location: 'us-central1'
});

const model = vertex_ai.getGenerativeModel({
  model: 'gemini-2.5-flash-lite'
});
```

### New (Current): @google/genai

```typescript
// ✅ USE THIS - Current SDK
const { GoogleGenerativeAI } = require('@google/genai');

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

const model = genAI.getGenerativeModel({
  model: 'gemini-2.5-flash-lite'
});
```

## Installation

```bash
npm install @google/genai
```

**Version**: `^1.29.0` or higher

## Authentication

### Option 1: API Key (Recommended for Development)

```typescript
const { GoogleGenerativeAI } = require('@google/genai');

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
```

Get API key: [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)

### Option 2: Application Default Credentials (Recommended for Production)

```typescript
const { GoogleGenerativeAI } = require('@google/genai');

// SDK automatically uses ADC if no API key provided
const genAI = new GoogleGenerativeAI();
```

Set up ADC:

```bash
# For local development
gcloud auth application-default login

# For Cloud Functions (automatic)
# Service account automatically configured by Firebase
```

### Option 3: Service Account Key File

```typescript
const { GoogleGenerativeAI } = require('@google/genai');

const genAI = new GoogleGenerativeAI({
  credentials: require('./service-account-key.json')
});
```

**WARNING**: Never commit service account keys to version control!

## Basic Usage

### Text Generation

```typescript
const { GoogleGenerativeAI } = require('@google/genai');

async function generateText() {
  const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

  const prompt = 'Explain how AI works in simple terms.';
  const result = await model.generateContent(prompt);

  const response = result.response;
  const text = response.text();

  console.log(text);
}
```

### Image Analysis (Vision)

```typescript
const { GoogleGenerativeAI } = require('@google/genai');
const fs = require('fs');

async function analyzeImage() {
  const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

  // Read image from file
  const imageData = fs.readFileSync('photo.jpg');
  const base64Image = imageData.toString('base64');

  const prompt = 'Describe what you see in this image.';
  const result = await model.generateContent([
    prompt,
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: base64Image
      }
    }
  ]);

  const response = result.response;
  const text = response.text();

  console.log(text);
}
```

### Image from URL

```typescript
const { GoogleGenerativeAI } = require('@google/genai');
const fetch = require('node-fetch');

async function analyzeImageFromUrl(imageUrl) {
  const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

  // Fetch image from URL
  const response = await fetch(imageUrl);
  const arrayBuffer = await response.arrayBuffer();
  const base64Image = Buffer.from(arrayBuffer).toString('base64');

  const prompt = 'Extract all visible text from this image.';
  const result = await model.generateContent([
    prompt,
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: base64Image
      }
    }
  ]);

  const text = result.response.text();
  return text;
}
```

## Abundance AI Pipeline Usage

### Layer 2a: Attribute Extraction

```typescript
const { GoogleGenerativeAI } = require('@google/genai');

/**
 * Extract structured attributes from product photo
 */
async function extractAttributes(photoUrl, userId, itemId) {
  const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

  // Fetch image from Cloud Storage
  const fetch = (await import('node-fetch')).default;
  const imageResponse = await fetch(photoUrl);
  const arrayBuffer = await imageResponse.arrayBuffer();
  const base64Image = Buffer.from(arrayBuffer).toString('base64');

  // Structured prompt with JSON schema
  const prompt = `Analyze this product photo and extract the following attributes in JSON format:

{
  "item_type": "food|household|personal_care|other",
  "brand": "brand name if visible, null otherwise",
  "size": "size/quantity (e.g., '16 oz', '500 ml')",
  "color": "primary color",
  "material": "primary material (plastic, glass, metal, cardboard)",
  "condition": "new|used|opened",
  "packaging_type": "bottle|box|bag|can|jar|tube|other",
  "text_visible": ["array", "of", "visible", "text"],
  "barcode_detected": true|false,
  "expiry_visible": true|false,
  "confidence_scores": {
    "item_type": 0.0-1.0,
    "brand": 0.0-1.0
  }
}

Return ONLY valid JSON, no markdown formatting.`;

  const result = await model.generateContent([
    prompt,
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: base64Image
      }
    }
  ]);

  const response = result.response;
  const text = response.text();

  // Parse JSON response
  const attributes = JSON.parse(text);

  // Get usage metadata for cost tracking
  const usage = response.usageMetadata;

  return {
    attributes,
    usage: {
      input_tokens: usage.promptTokenCount,
      output_tokens: usage.candidatesTokenCount,
      total_tokens: usage.totalTokenCount
    }
  };
}
```

## Response Parsing

### Extracting Text

```typescript
const result = await model.generateContent(prompt);

// Simple text extraction
const text = result.response.text();

// Accessing full response object
const response = result.response;
console.log(response.candidates); // Array of candidate responses
console.log(response.usageMetadata); // Token usage
```

### Parsing JSON Responses

```typescript
const result = await model.generateContent(jsonPrompt);
const text = result.response.text();

// Remove markdown formatting if present
const cleanText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '');

// Parse JSON
const data = JSON.parse(cleanText);
```

### Handling Multiple Candidates

```typescript
const result = await model.generateContent(prompt);
const response = result.response;

// Get all candidates (usually just one)
const candidates = response.candidates;

candidates.forEach((candidate, index) => {
  console.log(`Candidate ${index + 1}:`, candidate.content.parts[0].text);
});
```

## Error Handling

### Common Error Types

```typescript
const { GoogleGenerativeAI } = require('@google/genai');

async function generateWithErrorHandling(prompt) {
  try {
    const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

    const result = await model.generateContent(prompt);
    return result.response.text();
  } catch (error) {
    if (error.message.includes('API key')) {
      console.error('Invalid or missing API key');
      throw new Error('Authentication failed');
    } else if (error.message.includes('quota')) {
      console.error('Quota exceeded');
      throw new Error('Rate limit exceeded - retry later');
    } else if (error.message.includes('400')) {
      console.error('Bad request - check prompt/image format');
      throw new Error('Invalid request');
    } else if (error.message.includes('500')) {
      console.error('Server error - transient, retry');
      throw new Error('API temporarily unavailable');
    } else {
      console.error('Unknown error:', error);
      throw error;
    }
  }
}
```

### Exponential Backoff Pattern

```typescript
async function generateWithRetry(
  model,
  prompt,
  maxRetries = 3,
  baseDelay = 1000
) {
  let lastError;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const result = await model.generateContent(prompt);
      return result.response.text();
    } catch (error) {
      lastError = error;

      // Don't retry on permanent errors
      if (
        error.message.includes('400') ||
        error.message.includes('API key')
      ) {
        throw error;
      }

      // Calculate backoff delay: 2^attempt * baseDelay
      const delay = Math.min(
        Math.pow(2, attempt) * baseDelay,
        60000 // Max 60 seconds
      );

      console.log(`Attempt ${attempt + 1} failed, retrying in ${delay}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error(`Max retries (${maxRetries}) exceeded: ${lastError.message}`);
}
```

## Usage Metadata & Cost Tracking

```typescript
const result = await model.generateContent(prompt);
const usage = result.response.usageMetadata;

console.log('Input tokens:', usage.promptTokenCount);
console.log('Output tokens:', usage.candidatesTokenCount);
console.log('Total tokens:', usage.totalTokenCount);

// Calculate cost (Gemini 2.5 Flash-Lite pricing as of 2025-11-11)
const inputCost = (usage.promptTokenCount / 1_000_000) * 0.01; // $0.01 per 1M tokens
const outputCost = (usage.candidatesTokenCount / 1_000_000) * 0.04; // $0.04 per 1M tokens
const totalCost = inputCost + outputCost;

console.log(`Total cost: $${totalCost.toFixed(6)}`);
```

## Model Configuration

### Available Models

```typescript
// Gemini 2.5 Flash-Lite (fastest, cheapest)
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

// Gemini 2.5 Flash (balanced)
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

// Gemini 2.5 Pro (most capable)
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
```

### Generation Config

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-2.5-flash-lite',
  generationConfig: {
    temperature: 0.7,        // 0.0-1.0 (lower = more deterministic)
    topP: 0.9,               // Nucleus sampling
    topK: 40,                // Top-k sampling
    maxOutputTokens: 1024,   // Max response length
    candidateCount: 1        // Number of response candidates
  }
});
```

### Safety Settings

```typescript
const { GoogleGenerativeAI, HarmCategory, HarmBlockThreshold } = require('@google/genai');

const model = genAI.getGenerativeModel({
  model: 'gemini-2.5-flash-lite',
  safetySettings: [
    {
      category: HarmCategory.HARM_CATEGORY_HARASSMENT,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE
    },
    {
      category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
      threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE
    }
  ]
});
```

## TypeScript Support

```typescript
import { GoogleGenerativeAI, GenerateContentResult } from '@google/genai';

async function generateTyped(prompt: string): Promise<string> {
  const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

  const result: GenerateContentResult = await model.generateContent(prompt);
  return result.response.text();
}
```

## Testing with Mocks

```typescript
// Mock for testing (no real API calls)
class MockGoogleGenerativeAI {
  getGenerativeModel(options) {
    return {
      generateContent: jest.fn().mockResolvedValue({
        response: {
          text: () => '{"item_type": "food", "brand": "Test Brand"}',
          usageMetadata: {
            promptTokenCount: 258,
            candidatesTokenCount: 100,
            totalTokenCount: 358
          }
        }
      })
    };
  }
}

// In tests
const genAI = new MockGoogleGenerativeAI();
```

## Troubleshooting

### Error: "API key not valid"

**Solution**:
1. Verify API key at [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Check `.env` file: `GOOGLE_API_KEY=your_key_here`
3. Ensure API key has no extra spaces or quotes

### Error: "Model not found: gemini-2.5-flash-lite"

**Solution**:
1. Check model name spelling (case-sensitive)
2. Verify model is available in your region
3. Update SDK: `npm install @google/genai@latest`

### Error: "Image too large"

**Solution**:
1. Image must be < 4MB
2. Compress image: `quality=0.8` for JPEG
3. Resize image: max 1024x1024 pixels

### Error: "Invalid MIME type"

**Solution**:
1. Supported: `image/jpeg`, `image/png`, `image/webp`
2. Check base64 encoding is correct
3. Verify `inlineData.mimeType` matches actual file type

## Best Practices

1. **Use API Key for Development**: Easier to debug
2. **Use ADC for Production**: More secure, no key rotation needed
3. **Always Track Usage**: Log tokens and costs to Firestore
4. **Implement Retry Logic**: Handle transient errors gracefully
5. **Parse JSON Carefully**: Gemini may wrap JSON in markdown
6. **Set Max Tokens**: Prevent runaway costs
7. **Use Structured Prompts**: Include JSON schema in prompt for consistent output

## Additional Resources

- **Official Docs**: [ai.google.dev/gemini-api/docs/quickstart?lang=node](https://ai.google.dev/gemini-api/docs/quickstart?lang=node)
- **SDK Reference**: [googleapis.github.io/genai-js](https://googleapis.github.io/genai-js)
- **Pricing**: [ai.google.dev/pricing](https://ai.google.dev/pricing)
- **API Playground**: [aistudio.google.com](https://aistudio.google.com)

---

**Last Updated**: 2025-11-11
