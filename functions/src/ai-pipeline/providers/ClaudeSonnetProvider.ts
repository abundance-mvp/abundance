import Anthropic from '@anthropic-ai/sdk';

export interface Layer2aData {
  category: string;
  color: string;
  material?: string;
  condition: string;
  confidence: number;
}

export interface Layer2bData {
  source: 'barcode' | 'serpapi';
  product: {
    brand: string;
    name: string;
    model?: string;
    variant?: string;
    category?: string;
    estimatedValue?: number;
  };
}

export interface SynthesizedMetadata {
  name: string;
  category: string;
  brand: string;
  model?: string;
  variant?: string;
  color: string;
  material?: string;
  condition: 'new' | 'like-new' | 'good' | 'fair' | 'poor';
  estimatedValue: number;
  confidence: 'high' | 'medium' | 'low';
  conflictsResolved: string[];
  reasoning: string;
  model_used: string;
  latency: number;
  tokensUsed: {
    input: number;
    output: number;
    total: number;
  };
}

export class ClaudeSonnetProvider {
  private anthropic: Anthropic;

  constructor() {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set');
    }

    this.anthropic = new Anthropic({
      apiKey,
      defaultHeaders: {
        'anthropic-beta': 'pdfs-2024-09-25,prompt-caching-2024-07-31',
      },
    });
  }

  async synthesize(
    layer2a: Layer2aData,
    layer2b: Layer2bData,
    detectedLabel: string,
    itemId: string
  ): Promise<SynthesizedMetadata> {
    const prompt = this.buildSynthesisPrompt(layer2a, layer2b, detectedLabel);
    const startTime = Date.now();

    try {
      const message = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 1024,
        temperature: 0.3,
        messages: [{
          role: 'user',
          content: prompt,
        }],
      });

      const latency = Date.now() - startTime;

      // Extract and parse JSON response
      let synthesized: any;

      try {
        const responseText = message.content[0].type === 'text' ? message.content[0].text : '';

        // Try to parse the whole response as JSON first
        synthesized = JSON.parse(responseText);
        console.log(`[ClaudeSonnet] Structured output parsed successfully for ${itemId}`);
      } catch (parseError) {
        console.warn(`[ClaudeSonnet] Direct JSON parsing failed for item ${itemId}, falling back to regex extraction`);

        const responseText = message.content[0].type === 'text' ? message.content[0].text : '';
        const jsonMatch = responseText.match(/\{[\s\S]*\}/);

        if (!jsonMatch) {
          throw new Error('Failed to extract JSON from Claude response (both parsing and regex failed)');
        }

        synthesized = JSON.parse(jsonMatch[0]);
      }

      // Add metadata
      synthesized.model_used = 'claude-sonnet-4-5';
      synthesized.latency = latency;
      synthesized.tokensUsed = {
        input: message.usage.input_tokens,
        output: message.usage.output_tokens,
        total: message.usage.input_tokens + message.usage.output_tokens,
      };

      console.log(`[ClaudeSonnet] Synthesis complete for ${itemId} in ${latency}ms`);

      return synthesized;
    } catch (error: any) {
      console.error(`[ClaudeSonnet] Synthesis error for ${itemId}:`, error);
      throw error;
    }
  }

  private buildSynthesisPrompt(layer2a: Layer2aData, layer2b: Layer2bData, detectedLabel: string): string {
    return `You are analyzing a household item to create accurate catalog metadata. You have data from two AI systems:

**Vision AI (Layer 2a - Gemini Flash-Lite)**:
- Category: ${layer2a.category}
- Color: ${layer2a.color}
- Material: ${layer2a.material || 'unknown'}
- Condition: ${layer2a.condition}
- Confidence: ${layer2a.confidence}

**Product Search (Layer 2b)**:
${layer2b.source === 'barcode' ?
  `- Source: Barcode lookup
- Product Name: ${layer2b.product.name}
- Brand: ${layer2b.product.brand}
- Category: ${layer2b.product.category || 'unknown'}`
  :
  `- Source: Visual search (SerpAPI + Claude Haiku)
- Brand: ${layer2b.product.brand || 'unknown'}
- Model: ${layer2b.product.name || 'unknown'}
- Variant: ${layer2b.product.variant || 'none'}
- Estimated Value: $${layer2b.product.estimatedValue || 0}`
}

**iOS Detection**: ${detectedLabel}

**Your task**:
1. **Reconcile conflicts**: If Vision AI and Product Search disagree (e.g., color mismatch), use context to decide which is correct.
2. **Assign confidence**: Rate overall confidence (high/medium/low) based on data consistency.
3. **Estimate value**: Combine product search value with condition assessment (new = 100%, like-new = 85%, good = 70%, fair = 50%, poor = 30%).
4. **Generate final metadata**: Create a single, unified item description.

**Conflict resolution rules**:
- **Barcode data is authoritative** for product identity (name, brand)
- **Vision AI is authoritative** for physical attributes (color, condition)
- If color from Vision AI conflicts with product image, trust vision AI (user photographed actual item)
- If no price data, estimate based on category and condition

Return JSON with this structure:
{
  "name": "Final product name",
  "category": "Final category",
  "brand": "Brand name",
  "model": "Model name",
  "variant": "Variant (if applicable)",
  "color": "Primary color",
  "material": "Primary material",
  "condition": "new|like-new|good|fair|poor",
  "estimatedValue": number (USD),
  "confidence": "high|medium|low",
  "conflictsResolved": ["List of conflicts resolved"],
  "reasoning": "Brief explanation of synthesis logic"
}`;
  }
}
