import { synthesizeMetadata } from '../synthesize';
import { ClaudeSonnetProvider } from '../../providers/ClaudeSonnetProvider';

jest.mock('../../providers/ClaudeSonnetProvider');

describe('synthesizeMetadata - Edge Cases', () => {
  let mockProvider: jest.Mocked<ClaudeSonnetProvider>;

  beforeEach(() => {
    mockProvider = new ClaudeSonnetProvider() as jest.Mocked<ClaudeSonnetProvider>;
    (ClaudeSonnetProvider as jest.Mock).mockImplementation(() => mockProvider);
  });

  describe('Conflicting data resolution', () => {
    it('should resolve color conflict (vision AI wins)', async () => {
      const mockSynthesis = {
        name: 'Blue Widget',
        category: 'electronics',
        brand: 'BrandX',
        color: 'blue',  // Vision AI color
        condition: 'good' as const,
        estimatedValue: 50,
        confidence: 'high' as const,
        conflictsResolved: ['Color mismatch: vision AI (blue) vs barcode product image (red) - used vision AI'],
        reasoning: 'Vision AI is authoritative for physical attributes',
        model_used: 'claude-sonnet-4-5',
        latency: 1500,
        tokensUsed: { input: 500, output: 150, total: 650 },
      };

      mockProvider.synthesize.mockResolvedValue(mockSynthesis);

      const input = {
        detectedLabel: 'widget',
        layer2a: {
          category: 'electronics',
          color: 'blue',
          condition: 'good',
          confidence: 0.9,
        },
        layer2b: {
          source: 'barcode' as const,
          product: {
            brand: 'BrandX',
            name: 'Red Widget',  // Product says "red"
            category: 'electronics',
          },
        },
      };

      const result = await synthesizeMetadata(input, 'test-item');

      expect(result.color).toBe('blue');
      expect(result.conflictsResolved.length).toBeGreaterThan(0);
    });

    it('should resolve category conflict with reasoning', async () => {
      const mockSynthesis = {
        name: 'Multi-Tool',
        category: 'kitchen',  // Barcode wins (more specific)
        brand: 'ToolCo',
        color: 'silver',
        condition: 'like-new' as const,
        estimatedValue: 30,
        confidence: 'medium' as const,
        conflictsResolved: ['Category mismatch: vision AI (tools) vs barcode (kitchen) - used barcode (more specific)'],
        reasoning: 'Barcode data is authoritative for product identity',
        model_used: 'claude-sonnet-4-5',
        latency: 1200,
        tokensUsed: { input: 450, output: 120, total: 570 },
      };

      mockProvider.synthesize.mockResolvedValue(mockSynthesis);

      const input = {
        detectedLabel: 'tool',
        layer2a: {
          category: 'tools',
          color: 'silver',
          condition: 'like-new',
          confidence: 0.7,
        },
        layer2b: {
          source: 'barcode' as const,
          product: {
            brand: 'ToolCo',
            name: 'Kitchen Multi-Tool',
            category: 'kitchen',
          },
        },
      };

      const result = await synthesizeMetadata(input, 'test-item');

      expect(result.category).toBe('kitchen');
      expect(result.conflictsResolved).toContain('Category mismatch: vision AI (tools) vs barcode (kitchen) - used barcode (more specific)');
    });
  });

  describe('Missing or incomplete data', () => {
    it('should synthesize metadata when Layer 2b has no barcode match', async () => {
      const mockSynthesis = {
        name: 'Blue Ceramic Mug',
        category: 'kitchenware',
        brand: 'Unknown',
        color: 'blue',
        material: 'ceramic',
        condition: 'good' as const,
        estimatedValue: 15,  // Estimated based on category + condition
        confidence: 'low' as const,  // No barcode = lower confidence
        conflictsResolved: [],
        reasoning: 'No barcode data available, relying on vision analysis only',
        model_used: 'claude-sonnet-4-5',
        latency: 1000,
        tokensUsed: { input: 400, output: 100, total: 500 },
      };

      mockProvider.synthesize.mockResolvedValue(mockSynthesis);

      const input = {
        detectedLabel: 'mug',
        layer2a: {
          category: 'kitchenware',
          color: 'blue',
          material: 'ceramic',
          condition: 'good',
          confidence: 0.85,
        },
        layer2b: {
          source: 'serpapi' as const,
          product: {
            brand: 'Unknown',
            name: 'Generic Mug',
            estimatedValue: 15,
          },
        },
      };

      const result = await synthesizeMetadata(input, 'test-item');

      expect(result.confidence).toBe('low');
      expect(result.brand).toBe('Unknown');
    });

    it('should handle missing Layer 2a material field', async () => {
      const mockSynthesis = {
        name: 'Plastic Container',
        category: 'storage',
        brand: 'StorageCo',
        color: 'clear',
        material: undefined,  // No material detected
        condition: 'good' as const,
        estimatedValue: 10,
        confidence: 'medium' as const,
        conflictsResolved: [],
        reasoning: 'Material could not be determined from image',
        model_used: 'claude-sonnet-4-5',
        latency: 900,
        tokensUsed: { input: 350, output: 90, total: 440 },
      };

      mockProvider.synthesize.mockResolvedValue(mockSynthesis);

      const input = {
        detectedLabel: 'container',
        layer2a: {
          category: 'storage',
          color: 'clear',
          material: undefined,  // Missing
          condition: 'good',
          confidence: 0.8,
        },
        layer2b: {
          source: 'barcode' as const,
          product: {
            brand: 'StorageCo',
            name: 'Clear Container',
            category: 'storage',
          },
        },
      };

      const result = await synthesizeMetadata(input, 'test-item');

      expect(result.material).toBeUndefined();
    });
  });

  describe('Claude API failures', () => {
    it('should throw error when Claude returns empty response', async () => {
      mockProvider.synthesize.mockRejectedValue(new Error('Empty response from Claude Sonnet'));

      const input = {
        detectedLabel: 'item',
        layer2a: {
          category: 'unknown',
          color: 'unknown',
          condition: 'unknown',
          confidence: 0.5,
        },
        layer2b: {
          source: 'serpapi' as const,
          product: {
            brand: 'Unknown',
            name: 'Unknown Item',
          },
        },
      };

      await expect(synthesizeMetadata(input, 'test-item')).rejects.toThrow('Empty response from Claude Sonnet');
    });
  });
});
