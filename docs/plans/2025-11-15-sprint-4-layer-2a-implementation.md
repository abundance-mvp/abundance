# Sprint 4: Layer 2a Attribute Extraction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement Gemini 2.5 Flash-Lite attribute extraction (Layer 2a) with JSON Schema Mode, cost tracking, and error handling using @google/genai SDK.

**Architecture:** GeminiProvider adapter class handles all Gemini API interactions with retry logic and base64 image conversion. Layer 2a Cloud Function triggers on item creation, calls GeminiProvider, stores attributes in Firestore, and logs costs.

**Tech Stack:** TypeScript, Firebase Cloud Functions (Node.js 20), @google/genai SDK v1.29.0+, Firestore, node-fetch, Jest

---

## Prerequisites

- Sprint 3 complete (onItemCreated trigger skeleton exists)
- SDK migration docs complete (CODE-EXAMPLE-010, CODE-EXAMPLE-011)
- @google/genai patterns documented (GOOGLE-GENAI-SDK-USAGE.md)
- JSON Schema documented (DESIGN-041-layer-2a-json-schema.md)

---

## Task 1: Install @google/genai SDK and Dependencies

**Files:**

- Modify: `functions/package.json`

**Step 1: Add @google/genai dependency**

Navigate to functions directory and add dependency:

```bash
cd functions
npm install @google/genai@^1.29.0
npm install node-fetch@^3.3.0
npm install --save-dev @types/node-fetch@^2.6.0
```

**Step 2: Verify package.json dependencies**

Expected dependencies in `functions/package.json`:

```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "@google/genai": "^1.29.0",
    "node-fetch": "^3.3.0"
  },
  "devDependencies": {
    "@types/jest": "^30.0.0",
    "@types/node": "^20.0.0",
    "@types/node-fetch": "^2.6.0",
    "jest": "^30.2.0",
    "ts-jest": "^29.4.5",
    "typescript": "^5.3.0"
  }
}
```

**Step 3: Verify installation**

Run: `npm list @google/genai`
Expected: `@google/genai@1.29.0` or higher

**Step 4: Commit**

```bash
git add functions/package.json functions/package-lock.json
git commit -m "feat: add @google/genai SDK for Layer 2a attribute extraction"
```

---

## Task 2: Create GeminiProvider Class (Test-First)

**Files:**

- Create: `functions/src/ai-pipeline/providers/GeminiProvider.ts`
- Create: `functions/src/ai-pipeline/providers/__tests__/GeminiProvider.test.ts`

### Step 1: Write the failing test

Create test file at `functions/src/ai-pipeline/providers/__tests__/GeminiProvider.test.ts`:

```typescript
import { GeminiProvider } from "../GeminiProvider";

describe("GeminiProvider", () => {
  describe("extractAttributes", () => {
    it("should extract attributes from image URL", async () => {
      // Mock environment variable
      process.env.GOOGLE_API_KEY = "test_api_key";

      // Mock node-fetch
      const mockFetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest
          .fn()
          .mockResolvedValue(Buffer.from("fake-image-data").buffer),
      });
      global.fetch = mockFetch as any;

      const provider = new GeminiProvider();

      // Mock the SDK's generateContent method
      const mockGenerateContent = jest.fn().mockResolvedValue({
        response: {
          text: () =>
            JSON.stringify({
              category: "camping",
              color: "green",
              material: "fabric",
              condition: "good",
              confidence: 0.87,
            }),
          usageMetadata: {
            promptTokenCount: 258,
            candidatesTokenCount: 100,
            totalTokenCount: 358,
          },
        },
      });

      // Inject mock
      (provider as any).model = {
        generateContent: mockGenerateContent,
      };

      const result = await provider.extractAttributes(
        "https://storage.googleapis.com/test/image.jpg",
        "user123",
        "item456"
      );

      expect(result).toEqual({
        category: "camping",
        color: "green",
        material: "fabric",
        condition: "good",
        confidence: 0.87,
      });
      expect(mockFetch).toHaveBeenCalledWith(
        "https://storage.googleapis.com/test/image.jpg"
      );
      expect(mockGenerateContent).toHaveBeenCalled();
    });

    it("should return usage metadata", async () => {
      process.env.GOOGLE_API_KEY = "test_api_key";

      const mockFetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest
          .fn()
          .mockResolvedValue(Buffer.from("fake-image-data").buffer),
      });
      global.fetch = mockFetch as any;

      const provider = new GeminiProvider();

      const mockGenerateContent = jest.fn().mockResolvedValue({
        response: {
          text: () =>
            JSON.stringify({
              category: "camping",
              color: "green",
              condition: "good",
            }),
          usageMetadata: {
            promptTokenCount: 258,
            candidatesTokenCount: 100,
            totalTokenCount: 358,
          },
        },
      });

      (provider as any).model = {
        generateContent: mockGenerateContent,
      };

      const result = await provider.extractAttributes(
        "https://storage.googleapis.com/test/image.jpg",
        "user123",
        "item456"
      );

      const usage = (result as any).usage;
      expect(usage).toBeDefined();
      expect(usage.totalTokens).toBe(358);
      expect(usage.inputTokens).toBe(258);
      expect(usage.outputTokens).toBe(100);
    });

    it("should throw error if API key is missing", async () => {
      delete process.env.GOOGLE_API_KEY;

      await expect(async () => {
        const provider = new GeminiProvider();
        await provider.extractAttributes(
          "https://storage.googleapis.com/test/image.jpg",
          "user123",
          "item456"
        );
      }).rejects.toThrow();
    });
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- GeminiProvider.test.ts`
Expected: FAIL with "Cannot find module '../GeminiProvider'"

**Step 3: Write minimal implementation**

Create `functions/src/ai-pipeline/providers/GeminiProvider.ts`:

```typescript
import { GoogleGenAI } from "@google/genai";
import fetch from "node-fetch";

/**
 * Gemini AI provider for attribute extraction (Layer 2a)
 * Uses @google/genai SDK with JSON Schema Mode
 */
export class GeminiProvider {
  private genAI: GoogleGenAI;
  private model: any;

  constructor() {
    // Require API key
    const apiKey = process.env.GOOGLE_API_KEY;
    if (!apiKey) {
      throw new Error("GOOGLE_API_KEY environment variable is required");
    }

    this.genAI = new GoogleGenAI(apiKey);

    // Configure model with JSON Schema Mode
    this.model = this.genAI.getGenerativeModel({
      model: "gemini-2.5-flash-lite",
      generationConfig: {
        temperature: 0.2,
        topP: 0.8,
        topK: 40,
        maxOutputTokens: 256,
        responseMimeType: "application/json",
        responseSchema: this.getAttributeSchema(),
      },
    });
  }

  /**
   * Extract attributes from product image
   */
  async extractAttributes(
    imageUrl: string,
    userId: string,
    itemId: string
  ): Promise<any> {
    // Fetch image from Cloud Storage
    const imageResponse = await fetch(imageUrl);
    const arrayBuffer = await imageResponse.arrayBuffer();
    const base64Image = Buffer.from(arrayBuffer).toString("base64");

    // Generate content with image
    const result = await this.model.generateContent([
      this.getPrompt(),
      {
        inlineData: {
          mimeType: "image/jpeg",
          data: base64Image,
        },
      },
    ]);

    const response = result.response;
    const text = response.text();
    const attributes = JSON.parse(text);

    // Attach usage metadata
    const usage = response.usageMetadata;
    (attributes as any).usage = {
      inputTokens: usage.promptTokenCount,
      outputTokens: usage.candidatesTokenCount,
      totalTokens: usage.totalTokenCount,
    };

    return attributes;
  }

  /**
   * Get JSON Schema for attribute extraction
   */
  private getAttributeSchema() {
    return {
      type: "object",
      properties: {
        category: {
          type: "string",
          description: "Primary household item category",
          enum: [
            "camping",
            "electronics",
            "furniture",
            "clothing",
            "kitchenware",
            "books",
            "toys",
            "sports",
            "tools",
            "other",
          ],
        },
        color: {
          type: "string",
          description: "Primary visible color",
        },
        material: {
          type: "string",
          description: "Primary material",
        },
        condition: {
          type: "string",
          description: "Visual condition assessment",
          enum: ["new", "like-new", "good", "fair", "poor"],
        },
        confidence: {
          type: "number",
          description: "Overall confidence (0.0-1.0)",
          minimum: 0,
          maximum: 1,
        },
      },
      required: ["category", "color", "condition"],
    };
  }

  /**
   * Get extraction prompt
   */
  private getPrompt(): string {
    return `Analyze this product photo and extract the following attributes:

- category: Primary household item category (camping, electronics, furniture, clothing, kitchenware, books, toys, sports, tools, other)
- color: Primary visible color (e.g., red, blue, green, black, white)
- material: Primary material (e.g., metal, plastic, fabric, wood, glass)
- condition: Visual condition (new, like-new, good, fair, poor)
- confidence: Overall confidence in extraction (0.0-1.0)

Return structured JSON matching the schema. Required fields: category, color, condition.`;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- GeminiProvider.test.ts`
Expected: PASS (all 3 tests)

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/providers/GeminiProvider.ts functions/src/ai-pipeline/providers/__tests__/GeminiProvider.test.ts
git commit -m "feat: implement GeminiProvider with JSON Schema Mode"
```

---

## Task 3: Add Retry Logic to GeminiProvider

**Files:**

- Modify: `functions/src/ai-pipeline/providers/GeminiProvider.ts`
- Modify: `functions/src/ai-pipeline/providers/__tests__/GeminiProvider.test.ts`

**Step 1: Write the failing test**

Add test to `GeminiProvider.test.ts`:

```typescript
it("should retry on transient errors", async () => {
  process.env.GOOGLE_API_KEY = "test_api_key";

  const mockFetch = jest.fn().mockResolvedValue({
    arrayBuffer: jest
      .fn()
      .mockResolvedValue(Buffer.from("fake-image-data").buffer),
  });
  global.fetch = mockFetch as any;

  const provider = new GeminiProvider();

  // First call fails with transient error, second succeeds
  const mockGenerateContent = jest
    .fn()
    .mockRejectedValueOnce(new Error("quota exceeded"))
    .mockResolvedValueOnce({
      response: {
        text: () =>
          JSON.stringify({
            category: "camping",
            color: "green",
            condition: "good",
          }),
        usageMetadata: {
          promptTokenCount: 258,
          candidatesTokenCount: 100,
          totalTokenCount: 358,
        },
      },
    });

  (provider as any).model = {
    generateContent: mockGenerateContent,
  };

  const result = await provider.extractAttributes(
    "https://storage.googleapis.com/test/image.jpg",
    "user123",
    "item456"
  );

  expect(result.category).toBe("camping");
  expect(mockGenerateContent).toHaveBeenCalledTimes(2);
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- GeminiProvider.test.ts`
Expected: FAIL (no retry logic yet)

**Step 3: Implement retry logic**

Modify `extractAttributes` method in `GeminiProvider.ts`:

```typescript
async extractAttributes(
  imageUrl: string,
  userId: string,
  itemId: string
): Promise<any> {
  // Fetch image from Cloud Storage
  const imageResponse = await fetch(imageUrl);
  const arrayBuffer = await imageResponse.arrayBuffer();
  const base64Image = Buffer.from(arrayBuffer).toString('base64');

  // Retry logic with exponential backoff
  const maxRetries = 3;
  const baseDelay = 1000; // 1 second
  let lastError: Error | null = null;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      // Generate content with image
      const result = await this.model.generateContent([
        this.getPrompt(),
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: base64Image
          }
        }
      ]);

      const response = result.response;
      const text = response.text();
      const attributes = JSON.parse(text);

      // Attach usage metadata
      const usage = response.usageMetadata;
      (attributes as any).usage = {
        inputTokens: usage.promptTokenCount,
        outputTokens: usage.candidatesTokenCount,
        totalTokens: usage.totalTokenCount
      };

      return attributes;
    } catch (error: any) {
      lastError = error;

      // Don't retry on permanent errors
      if (
        error.message.includes('400') ||
        error.message.includes('API key')
      ) {
        throw error;
      }

      // Calculate backoff delay
      if (attempt < maxRetries - 1) {
        const delay = Math.min(
          Math.pow(2, attempt) * baseDelay,
          60000 // Max 60 seconds
        );
        console.log(`Attempt ${attempt + 1} failed, retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  throw new Error(`Max retries (${maxRetries}) exceeded: ${lastError?.message}`);
}
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- GeminiProvider.test.ts`
Expected: PASS (all 4 tests)

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/providers/GeminiProvider.ts functions/src/ai-pipeline/providers/__tests__/GeminiProvider.test.ts
git commit -m "feat: add exponential backoff retry logic to GeminiProvider"
```

---

## Task 4: Create CostLogger Class (Test-First)

**Files:**

- Create: `functions/src/ai-pipeline/cost-tracking/CostLogger.ts`
- Create: `functions/src/ai-pipeline/cost-tracking/__tests__/CostLogger.test.ts`

**Step 1: Write the failing test**

Create test file at `functions/src/ai-pipeline/cost-tracking/__tests__/CostLogger.test.ts`:

```typescript
import { CostLogger } from "../CostLogger";
import * as admin from "firebase-admin";

// Mock Firestore
jest.mock("firebase-admin", () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      add: jest.fn().mockResolvedValue({ id: "log123" }),
    })),
  })),
}));

describe("CostLogger", () => {
  it("should log API call cost to Firestore", async () => {
    const logger = new CostLogger();

    await logger.logCost({
      userId: "user123",
      itemId: "item456",
      provider: "gemini",
      model: "gemini-2.5-flash-lite",
      operation: "layer2a_extraction",
      inputTokens: 258,
      outputTokens: 100,
      totalTokens: 358,
      cost: 0.00006,
      timestamp: new Date(),
    });

    const mockAdd = (admin.firestore as any)().collection().add;
    expect(mockAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: "user123",
        itemId: "item456",
        provider: "gemini",
        model: "gemini-2.5-flash-lite",
        operation: "layer2a_extraction",
        inputTokens: 258,
        outputTokens: 100,
        totalTokens: 358,
        cost: 0.00006,
      })
    );
  });

  it("should calculate cost correctly", () => {
    const logger = new CostLogger();

    const cost = logger.calculateCost(
      "gemini-2.5-flash-lite",
      258, // input tokens
      100 // output tokens
    );

    // Gemini 2.5 Flash-Lite: $0.10/1M input, $0.40/1M output
    // Input: 258 × 0.10/1M = 0.0000258
    // Output: 100 × 0.40/1M = 0.0000400
    // Total: 0.0000658
    expect(cost).toBeCloseTo(0.0000658, 7);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- CostLogger.test.ts`
Expected: FAIL with "Cannot find module '../CostLogger'"

**Step 3: Write minimal implementation**

Create `functions/src/ai-pipeline/cost-tracking/CostLogger.ts`:

```typescript
import * as admin from "firebase-admin";

interface CostLogEntry {
  userId: string;
  itemId: string;
  provider: string;
  model: string;
  operation: string;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  cost: number;
  timestamp: Date;
}

/**
 * Cost logging for AI API calls
 * Logs all API usage to Firestore costLogs collection
 */
export class CostLogger {
  /**
   * Log API call cost to Firestore
   */
  async logCost(entry: CostLogEntry): Promise<void> {
    const db = admin.firestore();
    await db.collection("costLogs").add({
      ...entry,
      timestamp: admin.firestore.Timestamp.fromDate(entry.timestamp),
    });
  }

  /**
   * Calculate cost per API call
   *
   * Pricing (as of 2025-11-15):
   * - Gemini 2.5 Flash-Lite: $0.10/1M input, $0.40/1M output
   */
  calculateCost(
    model: string,
    inputTokens: number,
    outputTokens: number
  ): number {
    const pricing: Record<string, { input: number; output: number }> = {
      "gemini-2.5-flash-lite": {
        input: 0.1 / 1_000_000, // $0.10 per 1M tokens
        output: 0.4 / 1_000_000, // $0.40 per 1M tokens
      },
    };

    const modelPricing = pricing[model];
    if (!modelPricing) {
      throw new Error(`Unknown model: ${model}`);
    }

    const inputCost = inputTokens * modelPricing.input;
    const outputCost = outputTokens * modelPricing.output;

    return inputCost + outputCost;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- CostLogger.test.ts`
Expected: PASS (all 2 tests)

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/cost-tracking/CostLogger.ts functions/src/ai-pipeline/cost-tracking/__tests__/CostLogger.test.ts
git commit -m "feat: implement CostLogger for AI API cost tracking"
```

---

## Task 5: Implement Layer 2a Extraction Logic

**Files:**

- Create: `functions/src/ai-pipeline/layer2a/extractAttributes.ts`
- Create: `functions/src/ai-pipeline/layer2a/__tests__/extractAttributes.test.ts`

**Step 1: Write the failing test**

Create test file at `functions/src/ai-pipeline/layer2a/__tests__/extractAttributes.test.ts`:

```typescript
import { extractAttributesLayer2a } from "../extractAttributes";
import { GeminiProvider } from "../../providers/GeminiProvider";
import { CostLogger } from "../../cost-tracking/CostLogger";

jest.mock("../../providers/GeminiProvider");
jest.mock("../../cost-tracking/CostLogger");

describe("extractAttributesLayer2a", () => {
  it("should extract attributes and log cost", async () => {
    const mockExtract = jest.fn().mockResolvedValue({
      category: "camping",
      color: "green",
      material: "fabric",
      condition: "good",
      confidence: 0.87,
      usage: {
        inputTokens: 258,
        outputTokens: 100,
        totalTokens: 358,
      },
    });

    const mockCalculateCost = jest.fn().mockReturnValue(0.00006);
    const mockLogCost = jest.fn().mockResolvedValue(undefined);

    (GeminiProvider as jest.Mock).mockImplementation(() => ({
      extractAttributes: mockExtract,
    }));

    (CostLogger as jest.Mock).mockImplementation(() => ({
      calculateCost: mockCalculateCost,
      logCost: mockLogCost,
    }));

    const result = await extractAttributesLayer2a(
      "user123",
      "item456",
      "https://storage.googleapis.com/test/image.jpg"
    );

    expect(result).toEqual({
      category: "camping",
      color: "green",
      material: "fabric",
      condition: "good",
      confidence: 0.87,
    });

    expect(mockExtract).toHaveBeenCalledWith(
      "https://storage.googleapis.com/test/image.jpg",
      "user123",
      "item456"
    );

    expect(mockCalculateCost).toHaveBeenCalledWith(
      "gemini-2.5-flash-lite",
      258,
      100
    );

    expect(mockLogCost).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: "user123",
        itemId: "item456",
        provider: "gemini",
        model: "gemini-2.5-flash-lite",
        operation: "layer2a_extraction",
        inputTokens: 258,
        outputTokens: 100,
        totalTokens: 358,
        cost: 0.00006,
      })
    );
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- extractAttributes.test.ts`
Expected: FAIL with "Cannot find module '../extractAttributes'"

**Step 3: Write minimal implementation**

Create `functions/src/ai-pipeline/layer2a/extractAttributes.ts`:

```typescript
import { GeminiProvider } from "../providers/GeminiProvider";
import { CostLogger } from "../cost-tracking/CostLogger";

/**
 * Extract attributes from product image (Layer 2a)
 *
 * @param userId - User ID who owns the item
 * @param itemId - Item ID being processed
 * @param imageUrl - Cloud Storage URL of product image
 * @returns Extracted attributes
 */
export async function extractAttributesLayer2a(
  userId: string,
  itemId: string,
  imageUrl: string
): Promise<any> {
  const provider = new GeminiProvider();
  const logger = new CostLogger();

  const startTime = Date.now();

  // Extract attributes using Gemini
  const result = await provider.extractAttributes(imageUrl, userId, itemId);

  const latency = Date.now() - startTime;

  // Extract usage metadata
  const usage = result.usage;
  delete result.usage; // Remove from result

  // Calculate cost
  const cost = logger.calculateCost(
    "gemini-2.5-flash-lite",
    usage.inputTokens,
    usage.outputTokens
  );

  // Log cost to Firestore
  await logger.logCost({
    userId,
    itemId,
    provider: "gemini",
    model: "gemini-2.5-flash-lite",
    operation: "layer2a_extraction",
    inputTokens: usage.inputTokens,
    outputTokens: usage.outputTokens,
    totalTokens: usage.totalTokens,
    cost,
    timestamp: new Date(),
  });

  console.log(
    `Layer 2a complete for item ${itemId}: cost=$${cost.toFixed(
      6
    )}, latency=${latency}ms`
  );

  return result;
}
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- extractAttributes.test.ts`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/layer2a/extractAttributes.ts functions/src/ai-pipeline/layer2a/__tests__/extractAttributes.test.ts
git commit -m "feat: implement Layer 2a attribute extraction with cost logging"
```

---

## Task 6: Integrate Layer 2a into onItemCreated Trigger

**Files:**

- Modify: `functions/src/triggers/onItemCreated.ts`
- Modify: `functions/src/__tests__/triggers.test.ts`

**Step 1: Write the failing test**

Add test to `functions/src/__tests__/triggers.test.ts`:

```typescript
import { extractAttributesLayer2a } from "../ai-pipeline/layer2a/extractAttributes";

jest.mock("../ai-pipeline/layer2a/extractAttributes");

describe("onItemCreated", () => {
  it("should call Layer 2a extraction and store attributes", async () => {
    const mockExtract = jest.fn().mockResolvedValue({
      category: "camping",
      color: "green",
      material: "fabric",
      condition: "good",
      confidence: 0.87,
    });

    (extractAttributesLayer2a as jest.Mock).mockImplementation(mockExtract);

    const mockUpdate = jest.fn().mockResolvedValue(undefined);
    const mockData = {
      userId: "user123",
      imageUrl: "https://storage.googleapis.com/test/image.jpg",
      status: "pending",
      createdAt: new Date(),
    };

    const event = {
      params: { itemId: "item456" },
      data: {
        data: () => mockData,
        ref: {
          update: mockUpdate,
        },
      },
    };

    // Call trigger (implementation TBD)
    // await onItemCreated(event);

    expect(mockExtract).toHaveBeenCalledWith(
      "user123",
      "item456",
      "https://storage.googleapis.com/test/image.jpg"
    );

    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        status: "layer2a_complete",
        "layer2a.category": "camping",
        "layer2a.color": "green",
        "layer2a.material": "fabric",
        "layer2a.condition": "good",
        "layer2a.confidence": 0.87,
      })
    );
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- triggers.test.ts`
Expected: FAIL (trigger doesn't call Layer 2a yet)

**Step 3: Implement Layer 2a integration**

Modify `functions/src/triggers/onItemCreated.ts`:

```typescript
import * as functions from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { extractAttributesLayer2a } from "../ai-pipeline/layer2a/extractAttributes";

/**
 * Trigger: onItemCreated (Layer 1 → Layer 2a transition)
 * Fires when item document is created with status="pending"
 * Calls Gemini to extract attributes
 */
export const onItemCreated = functions.onDocumentCreated(
  "items/{itemId}",
  async (event) => {
    const itemId = event.params.itemId;
    const item = event.data?.data();

    if (!item) {
      console.error(`onItemCreated: No data for item ${itemId}`);
      return;
    }

    // Validate state
    if (item.status !== "pending") {
      console.log(
        `onItemCreated: Skipping item ${itemId} (status: ${item.status})`
      );
      return;
    }

    // Validate required fields
    if (!item.imageUrl) {
      console.error(`onItemCreated: Missing imageUrl for item ${itemId}`);
      await event.data?.ref.update({
        status: "failed_layer2a",
        error: {
          message: "Missing imageUrl",
          timestamp: admin.firestore.Timestamp.now(),
        },
        updatedAt: admin.firestore.Timestamp.now(),
      });
      return;
    }

    console.log(`[Layer 2a] Processing item ${itemId}`);

    try {
      // Extract attributes using Gemini
      const attributes = await extractAttributesLayer2a(
        item.userId,
        itemId,
        item.imageUrl
      );

      // Store attributes in Firestore
      await event.data?.ref.update({
        status: "layer2a_complete",
        "layer2a.category": attributes.category,
        "layer2a.color": attributes.color,
        "layer2a.material": attributes.material || null,
        "layer2a.condition": attributes.condition,
        "layer2a.confidence": attributes.confidence || null,
        "layer2a.model": "gemini-2.5-flash-lite",
        layer2aCompletedAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      console.log(`[Layer 2a] Complete for item ${itemId}`);
    } catch (error: any) {
      console.error(`[Layer 2a] Failed for item ${itemId}:`, error);

      await event.data?.ref.update({
        status: "failed_layer2a",
        error: {
          message: error.message,
          timestamp: admin.firestore.Timestamp.now(),
        },
        updatedAt: admin.firestore.Timestamp.now(),
      });
    }
  }
);
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- triggers.test.ts`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/triggers/onItemCreated.ts functions/src/__tests__/triggers.test.ts
git commit -m "feat: integrate Layer 2a attribute extraction into onItemCreated trigger"
```

---

## Task 7: Build and Deploy

**Step 1: Build TypeScript**

Run: `cd functions && npm run build`
Expected: No compilation errors

**Step 2: Run all tests**

Run: `cd functions && npm test`
Expected: All tests pass

**Step 3: Check for lint errors**

Run: `cd functions && npx tsc --noEmit`
Expected: No type errors

**Step 4: Verify deployment readiness**

Run: `firebase deploy --only functions --dry-run`
Expected: Preview of functions to deploy

**Step 5: Commit**

```bash
git add -A
git commit -m "build: compile Layer 2a implementation"
```

---

## Task 8: Create Environment Variables Documentation

**Files:**

- Create: `functions/.env.example`
- Modify: `functions/README.md`

**Step 1: Create .env.example**

Create `functions/.env.example`:

```bash
# Google Generative AI SDK (for local development)
# Get API key: https://aistudio.google.com/app/apikey
GOOGLE_API_KEY=your_api_key_here

# Firebase configuration (automatic in Cloud Functions)
# Only needed for local testing
# GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account-key.json
```

**Step 2: Document setup in README**

Create or modify `functions/README.md`:

````markdown
# Abundance Backend (Firebase Cloud Functions)

## Setup

### 1. Install Dependencies

```bash
npm install
```
````

### 2. Configure Environment Variables

**Local Development:**

```bash
cp .env.example .env
# Edit .env and add your GOOGLE_API_KEY
```

Get API key: https://aistudio.google.com/app/apikey

**Cloud Functions (Production):**

```bash
firebase functions:config:set gemini.api_key="YOUR_API_KEY"
```

### 3. Run Tests

```bash
npm test
```

### 4. Build

```bash
npm run build
```

### 5. Deploy

```bash
firebase deploy --only functions
```

## Architecture

- **Layer 2a**: Gemini attribute extraction (category, color, material, condition)
- **Cost Tracking**: All API calls logged to Firestore `costLogs` collection
- **Retry Logic**: Exponential backoff for transient errors

````

**Step 3: Commit**

```bash
git add functions/.env.example functions/README.md
git commit -m "docs: add environment variables and setup instructions"
````

---

## Task 9: Create Integration Test

**Files:**

- Create: `functions/src/__tests__/integration.test.ts`

**Step 1: Write integration test**

Create `functions/src/__tests__/integration.test.ts`:

```typescript
import { GeminiProvider } from "../ai-pipeline/providers/GeminiProvider";
import { extractAttributesLayer2a } from "../ai-pipeline/layer2a/extractAttributes";

describe("Integration: Layer 2a End-to-End", () => {
  it("should extract attributes from real image URL (skip if no API key)", async () => {
    if (!process.env.GOOGLE_API_KEY) {
      console.log("Skipping integration test: GOOGLE_API_KEY not set");
      return;
    }

    // Use a publicly accessible test image
    const testImageUrl =
      "https://storage.googleapis.com/abundance-test/backpack.jpg";

    const result = await extractAttributesLayer2a(
      "test_user",
      "test_item",
      testImageUrl
    );

    expect(result).toHaveProperty("category");
    expect(result).toHaveProperty("color");
    expect(result).toHaveProperty("condition");

    // Validate category is from enum
    const validCategories = [
      "camping",
      "electronics",
      "furniture",
      "clothing",
      "kitchenware",
      "books",
      "toys",
      "sports",
      "tools",
      "other",
    ];
    expect(validCategories).toContain(result.category);

    // Validate condition is from enum
    const validConditions = ["new", "like-new", "good", "fair", "poor"];
    expect(validConditions).toContain(result.condition);

    console.log("Integration test result:", result);
  }, 30000); // 30 second timeout
});
```

**Step 2: Run integration test**

Run: `cd functions && GOOGLE_API_KEY=your_key npm test -- integration.test.ts`
Expected: PASS (if API key is valid)

**Step 3: Commit**

```bash
git add functions/src/__tests__/integration.test.ts
git commit -m "test: add Layer 2a end-to-end integration test"
```

---

## Verification Checklist

After completing all tasks, verify:

- [ ] `npm install` succeeds in functions/
- [ ] `npm test` passes all tests (GeminiProvider, CostLogger, extractAttributes, triggers)
- [ ] `npm run build` compiles without errors
- [ ] Zero references to @google-cloud/vertexai in code
- [ ] All imports use @google/genai
- [ ] Environment variables documented in .env.example
- [ ] Integration test runs successfully with API key
- [ ] Cost logging writes to Firestore costLogs collection
- [ ] Retry logic handles transient errors
- [ ] JSON Schema Mode enforces structured output
- [ ] All commits follow Conventional Commits format

---

## Deployment Steps (Post-Implementation)

**1. Deploy to Firebase:**

```bash
firebase deploy --only functions:onItemCreated
```

**2. Test in production:**

- Create test item via iOS app or HTTP endpoint
- Verify Layer 2a completes successfully
- Check Firestore for `layer2a` attributes
- Verify cost log entry in `costLogs` collection

**3. Monitor logs:**

```bash
firebase functions:log --only onItemCreated
```

---

## Success Metrics

- ✅ All unit tests pass (GeminiProvider, CostLogger, extractAttributes)
- ✅ Integration test passes with real API call
- ✅ Zero @google-cloud/vertexai references in codebase
- ✅ Cost tracking logs all API calls to Firestore
- ✅ Retry logic handles rate limits and transient errors
- ✅ JSON Schema Mode returns valid enum values (category, condition)
- ✅ Deployment succeeds to Firebase Cloud Functions

---

**References:**

- [CODE-EXAMPLE-010-vertex-ai-attribute-extraction](../design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md): Gemini attribute extraction patterns
- [CODE-EXAMPLE-011-layer-2a-cloud-function](../design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Layer 2a Cloud Function patterns
- [DESIGN-041-layer-2a-json-schema](../design/DESIGN-041-layer-2a-json-schema.md): Layer 2a JSON Schema specification
- GOOGLE-GENAI-SDK-USAGE: SDK implementation guide
- @superpowers:test-driven-development: TDD workflow
- @superpowers:verification-before-completion: Verification requirements
