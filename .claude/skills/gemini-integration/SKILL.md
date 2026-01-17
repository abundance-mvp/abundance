---
name: gemini-integration
description: Skill for integrating Gemini 3 Pro with tool calling for the abundance cataloging pipeline. Covers prompt engineering, tool definitions, thought signatures, and response handling patterns.
---

# Gemini Integration

Skill for implementing Gemini 3 Pro integration with tool calling in the abundance cataloging pipeline.

## When This Skill Activates

- Implementing AI pipeline orchestration
- Creating Gemini tool definitions
- Handling tool calls and responses
- Debugging thought signature errors
- Prompt engineering for cataloging
- Confidence scoring and error handling

## Reference Implementation

See `functions/src/ai-pipeline/gemini/` for current implementation:
- `gemini-service.ts` - Core Gemini client with thought signature handling
- `prompts.ts` - Tool declarations and system prompts
- `orchestrator.ts` - Firestore trigger integration
- Test files for patterns

---

## Gemini 3 Thought Signatures (CRITICAL)

Gemini 3 requires thought signatures for function calling. Without them, you get a 400 error.

### What Are Thought Signatures?

When Gemini 3 calls a tool, it pauses its reasoning. The `thoughtSignature` is a "save state" that lets the model resume its chain of thought when you return the function result.

### Handling Rules

| Scenario | Signature Location | Requirement |
|----------|-------------------|-------------|
| Single function call | On the `functionCall` part | **Must return** |
| Parallel function calls | Only on **first** `functionCall` | **Must return first part exactly** |
| Sequential (multi-step) | Each `functionCall` has its own | **Must return all signatures** |
| Text response | May include signature | Recommended but not enforced |

### SDK Automatic Handling

If using official Google Gen AI SDK with chat feature or appending full response to history, signatures are handled automatically. Our implementation manually preserves them:

```typescript
// From gemini-service.ts - preserving thought signatures
function getModelPartsWithThoughtSignature(response: GenerateContentResponse): Part[] {
  const candidate = response.candidates?.[0];
  if (!candidate?.content?.parts) return [];

  // Return parts that have function calls or thought-related content
  return candidate.content.parts.filter(part =>
    part.functionCall || part.thought || part.thoughtSignature
  );
}
```

### Error Pattern

```
400 Bad Request: Function call `barcode_lookup` in the `1.` content block
is missing a `thought_signature`
```

**Fix:** Ensure you pass the complete model response parts (not just function call names) back in conversation history.

---

## Tool Calling Pattern

### Define Tools

```typescript
import { Type } from '@google/genai';

const tools = [{
  functionDeclarations: [{
    name: "barcode_lookup",
    description: "Look up product information by barcode number",
    parameters: {
      type: Type.OBJECT,
      properties: {
        code: {
          type: Type.STRING,
          description: "The barcode number"
        },
        symbology: {
          type: Type.STRING,
          enum: ["upc_a", "ean_13", "qr", "code_128"],
          description: "The barcode format (optional)"
        }
      },
      required: ["code"]
    }
  }]
}];
```

### Handle Tool Calls (with Thought Signatures)

```typescript
const response = await ai.models.generateContent({
  model: "gemini-3-pro-preview",
  contents: [{ role: "user", parts: [{ text: prompt }] }],
  config: {
    tools: tools,
    systemInstruction: SYSTEM_PROMPT
  }
});

// Check for function calls
const functionCalls = response.functionCalls || [];

if (functionCalls.length > 0) {
  // Execute all function calls
  const toolResults = await Promise.all(
    functionCalls.map(async (call) => {
      const result = await executeToolCall(call.name, call.args);
      return {
        functionResponse: { name: call.name, response: result }
      };
    })
  );

  // CRITICAL: Preserve model parts with thought signatures
  const modelParts = getModelPartsWithThoughtSignature(response);
  const userParts = toolResults.map(r => ({ functionResponse: r.functionResponse }));

  // Continue conversation
  const nextResponse = await ai.models.generateContent({
    model: "gemini-3-pro-preview",
    contents: [
      ...previousContents,
      { role: "model", parts: modelParts },  // Includes thought signatures!
      { role: "user", parts: userParts }
    ],
    config: { tools, systemInstruction: SYSTEM_PROMPT }
  });
}
```

---

## Available Tools for Cataloging

### google_lens_search

Visual product matching using Google Lens API.

```typescript
{
  name: "google_lens_search",
  description: "Search for product information using visual matching",
  parameters: {
    type: "object",
    properties: {
      image_url: { type: "string", description: "Public URL of the product image" }
    },
    required: ["image_url"]
  }
}
```

### barcode_lookup

Look up product by UPC/EAN barcode.

```typescript
{
  name: "barcode_lookup",
  description: "Look up product information by barcode number",
  parameters: {
    type: "object",
    properties: {
      code: { type: "string", description: "The barcode number" },
      symbology: {
        type: "string",
        enum: ["upc_a", "upc_e", "ean_13", "ean_8", "qr", "code_128"],
        description: "The barcode format (optional)"
      }
    },
    required: ["code"]
  }
}
```

### web_search

Search for pricing using web grounding.

```typescript
{
  name: "web_search",
  description: "Search e-commerce sites for current pricing",
  parameters: {
    type: "object",
    properties: {
      query: { type: "string", description: "Search query" }
    },
    required: ["query"]
  }
}
```

---

## System Prompt Best Practices

1. **Clear role definition**: "You are a product cataloging assistant..."
2. **Workflow steps**: Numbered steps for decision process
3. **Tool selection guidance**: When to use each tool
4. **Confidence scoring**: "Rate confidence high/medium/low based on..."
5. **Error handling**: "If uncertain, set needsReview: true"
6. **Output format**: JSON schema for structured responses

See `prompts.ts` for full system prompt example.

---

## Generation Config

```typescript
export const GENERATION_CONFIG = {
  temperature: 0.1,          // Low for consistent cataloging
  topP: 0.95,
  maxOutputTokens: 8192,     // Enough for tool calling + JSON
  responseMimeType: 'application/json',
  responseSchema: CATALOG_ITEM_SCHEMA  // Structured output
};

export const GEMINI_MODEL_ID = 'gemini-3-pro-preview';
```

---

## Error Handling

### Thought Signature Errors (400)

```
Function call is missing a thought_signature
```

**Cause:** Not preserving model response parts in conversation history.
**Fix:** Use `getModelPartsWithThoughtSignature()` pattern above.

### Tool Call Failures

- Retry with exponential backoff
- Fall back to alternative tool (e.g., web_search if barcode_lookup fails)
- Return `needsReview: true` for human review

### Low Confidence

- Try additional tools (web_search after barcode_lookup)
- Aggregate confidence from multiple sources
- Flag for human review if still low

### Rate Limiting

- Implement request queuing
- Use appropriate Vertex AI quotas
- Log and alert on limits

---

## Vertex AI MCP Server (Optional)

For Claude Code integration with Gemini, you can use the community Vertex AI MCP server:

**GitHub:** https://github.com/shariqriazz/vertex-ai-mcp-server

**Install for Claude Desktop:**
```bash
bunx -y @smithery/cli install @shariqriazz/vertex-ai-mcp-server --client claude
```

**Claude Code:**
```bash
claude mcp add-json "vertex-ai-mcp-server" '{
  "command": "bunx",
  "args": ["-y", "vertex-ai-mcp-server"],
  "env": {
    "AI_PROVIDER": "vertex",
    "GOOGLE_CLOUD_PROJECT": "abundance-mvp"
  }
}'
```

**Provided Tools:**
- `answer_query_websearch` - Web-grounded responses
- `answer_query_direct` - Direct knowledge answers
- `code_analysis_with_docs` - Bug/security analysis
- `technical_comparison` - Framework comparisons

---

## Documentation Resources

When implementing Gemini integrations, consult:

| Topic | URL |
|-------|-----|
| Function Calling | https://ai.google.dev/gemini-api/docs/function-calling |
| Thought Signatures | https://ai.google.dev/gemini-api/docs/thought-signatures |
| Gemini 3 Guide | https://ai.google.dev/gemini-api/docs/gemini-3 |
| Vertex AI Docs | https://cloud.google.com/vertex-ai/generative-ai/docs |

---

## Testing Patterns

See `functions/src/ai-pipeline/gemini/__tests__/` for test patterns:
- Mock Gemini responses with thought signatures
- Test tool call routing
- Test error handling and retries
- Integration tests with real API

### Mock Example

```typescript
const mockResponse = {
  candidates: [{
    content: {
      parts: [{
        functionCall: { name: 'barcode_lookup', args: { code: '123' } },
        thoughtSignature: 'encrypted-signature-here'
      }]
    }
  }],
  functionCalls: [{ name: 'barcode_lookup', args: { code: '123' } }]
};
```

---

## When NOT to Use This Skill

- iOS/Swift development → use `ios-superpowers`
- Firebase operations (deploy, logs) → use `backend-superpowers`
- General GCP operations → use `backend-superpowers`

This skill is specifically for **Gemini API integration patterns** in the AI pipeline code.
