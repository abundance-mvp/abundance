import { synthesizeMetadata } from '../synthesize';

// Mock ClaudeSonnetProvider
jest.mock('../../providers/ClaudeSonnetProvider', () => ({
  ClaudeSonnetProvider: jest.fn().mockImplementation(() => ({
    synthesize: jest.fn().mockResolvedValue({
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
      reasoning: 'Barcode data provides authoritative product identity.',
      model_used: 'claude-sonnet-4-5',
      latency: 1200,
      tokensUsed: { input: 800, output: 200, total: 1000 },
    }),
  })),
}));

describe('synthesizeMetadata', () => {
  test('synthesizes Layer 2a + 2b into final metadata', async () => {
    const itemData = {
      detectedLabel: 'stove',
      layer2a: {
        category: 'camping',
        color: 'green',
        material: 'metal',
        condition: 'good',
        confidence: 0.87,
      },
      layer2b: {
        source: 'barcode' as const,
        product: {
          brand: 'Coleman',
          name: 'Triton',
          category: 'camping',
        },
      },
    };

    const result = await synthesizeMetadata(itemData, 'test_item_123');

    expect(result.name).toContain('Coleman');
    expect(result.brand).toBe('Coleman');
    expect(result.color).toBe('green');
    expect(result.condition).toBe('good');
    expect(result.confidence).toMatch(/high|medium|low/);
  });
});
