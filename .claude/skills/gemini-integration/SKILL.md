---
name: gemini-integration
description: Skill for integrating Gemini 3 Pro with tool calling for the abundance cataloging pipeline. Covers prompt engineering, tool definitions, and response handling patterns.
---

# Gemini Integration

Skill for implementing Gemini 3 Pro integration with tool calling in the abundance cataloging pipeline.

## When This Skill Activates

- Implementing AI pipeline orchestration
- Creating Gemini tool definitions
- Handling tool calls and responses
- Prompt engineering for cataloging
- Confidence scoring and error handling

## Reference Implementation

See `functions/src/ai-pipeline/gemini/` for current implementation:
- `gemini-service.ts` - Core Gemini client
- Tool definitions in prompts files
- Test files for patterns

## Tool Calling Pattern

### Define Tools

```typescript
const tools: Tool[] = [{
  functionDeclarations: [{
    name: "tool_name",
    description: "Clear, concise description of what this tool does",
    parameters: {
      type: SchemaType.OBJECT,
      properties: {
        param1: {
          type: SchemaType.STRING,
          description: "Parameter description"
        }
      },
      required: ["param1"]
    }
  }]
}];
```

### Handle Tool Calls

```typescript
const response = await model.generateContent({
  contents: [{ role: "user", parts: [{ text: prompt }] }],
  tools: tools
});

// Check for tool calls
const candidate = response.response.candidates?.[0];
const functionCall = candidate?.content?.parts?.find(
  part => part.functionCall
)?.functionCall;

if (functionCall) {
  const result = await executeToolCall(functionCall);
  // Continue conversation with tool result
}
```

## Available Tools for Cataloging

### barcode_lookup

Look up product by UPC/EAN barcode.

```typescript
{
  name: "barcode_lookup",
  description: "Look up product information by barcode",
  parameters: {
    type: "object",
    properties: {
      barcode: { type: "string" },
      format: { type: "string", enum: ["UPC-A", "EAN-13", "CODE-128"] }
    },
    required: ["barcode"]
  }
}
```

### web_search

Search web for product information using Google Search grounding.

```typescript
{
  name: "web_search",
  description: "Search for product information",
  parameters: {
    type: "object",
    properties: {
      query: { type: "string" }
    },
    required: ["query"]
  }
}
```

### image_search

Visual search using Google Lens integration.

```typescript
{
  name: "image_search",
  description: "Search by product image",
  parameters: {
    type: "object",
    properties: {
      image_url: { type: "string" }
    },
    required: ["image_url"]
  }
}
```

## System Prompt Best Practices

1. **Clear role definition**: "You are a product cataloging assistant..."
2. **Workflow steps**: Numbered steps for decision process
3. **Confidence scoring**: "Rate confidence 0-100 based on..."
4. **Error handling**: "If uncertain, return needs_review: true"
5. **Output format**: JSON schema for structured responses

## Response Handling

```typescript
interface CatalogResult {
  item: {
    name: string;
    description: string;
    category: string;
    estimatedValue?: number;
  };
  confidence: number;
  sources: string[];
  needsReview: boolean;
}
```

## Error Handling

### Tool call failures
→ Retry with exponential backoff
→ Fall back to alternative tool
→ Return needs_review: true

### Low confidence
→ Try additional tools (web_search after barcode_lookup)
→ Aggregate confidence from multiple sources
→ Flag for human review if still low

### Rate limiting
→ Implement request queuing
→ Use appropriate quotas
→ Log and alert on limits

## Testing Patterns

See `functions/src/ai-pipeline/gemini/__tests__/` for test patterns:
- Mock Gemini responses
- Test tool call routing
- Test error handling
- Integration tests with real API
