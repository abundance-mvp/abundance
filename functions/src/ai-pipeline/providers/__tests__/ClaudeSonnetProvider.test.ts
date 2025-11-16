import { ClaudeSonnetProvider } from '../ClaudeSonnetProvider';

// Mock the Anthropic SDK
jest.mock('@anthropic-ai/sdk', () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => ({
      messages: {
        create: jest.fn().mockResolvedValue({
          content: [{
            type: 'text',
            text: JSON.stringify({
              name: 'Coleman Triton 2-Burner Camping Stove',
              category: 'camping',
              brand: 'Coleman',
              model: 'Triton',
              variant: '2-Burner',
              color: 'green',
              material: 'metal',
              condition: 'good',
              estimatedValue: 31.49,
              confidence: 'high',
              conflictsResolved: [],
              reasoning: 'Barcode data provides authoritative product identity. Vision AI color and condition trusted.',
            }),
          }],
          usage: {
            input_tokens: 800,
            output_tokens: 200,
          },
        }),
      },
    })),
  };
});

describe('ClaudeSonnetProvider', () => {
  let provider: ClaudeSonnetProvider;

  beforeEach(() => {
    process.env.ANTHROPIC_API_KEY = 'test-anthropic-key';
    provider = new ClaudeSonnetProvider();
  });

  test('synthesizes Layer 2a + 2b into final metadata', async () => {
    const layer2a = {
      category: 'camping',
      color: 'green',
      material: 'metal',
      condition: 'good',
      confidence: 0.87,
    };

    const layer2b = {
      source: 'barcode' as const,
      product: {
        brand: 'Coleman',
        name: 'Triton',
        category: 'camping',
      },
    };

    const detectedLabel = 'stove';

    const result = await provider.synthesize(layer2a, layer2b, detectedLabel, 'test_item_123');

    expect(result.name).toContain('Coleman');
    expect(result.brand).toBe('Coleman');
    expect(result.color).toBe('green');
    expect(result.condition).toBe('good');
    expect(result.estimatedValue).toBeGreaterThan(0);
    expect(result.confidence).toMatch(/high|medium|low/);
    expect(result.tokensUsed.total).toBeGreaterThan(0);
  });
});
