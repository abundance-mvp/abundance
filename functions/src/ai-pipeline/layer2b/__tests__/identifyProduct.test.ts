import { identifyProduct } from '../identifyProduct';

// Mock all the providers
jest.mock('../BarcodeHybridLookup');
jest.mock('../../providers/SerpAPIProvider');
jest.mock('../../providers/ClaudeHaikuProvider');

describe('identifyProduct', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('uses barcode path when barcode found', async () => {
    // Mock BarcodeHybridLookup to return a result
    const { BarcodeHybridLookup } = require('../BarcodeHybridLookup');
    BarcodeHybridLookup.mockImplementation(() => ({
      lookup: jest.fn().mockResolvedValue({
        found: true,
        source: 'openfoodfacts',
        name: 'Coca-Cola',
        brand: 'Coca-Cola',
        category: 'beverages',
        barcode: '049000050103',
        latency: 200,
      }),
    }));

    const itemData = {
      imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
      barcodeData: {
        detected: true,
        value: '049000050103',
        type: 'EAN-13',
      },
    };

    const result = await identifyProduct(itemData, 'test_item_123');

    // Should return barcode result
    expect(result).toHaveProperty('source');
    expect(result.source).toBe('barcode');
    expect(result.product.brand).toBe('Coca-Cola');
  });

  test('uses visual path when no barcode', async () => {
    // Mock SerpAPI and Claude
    const { SerpAPIProvider } = require('../../providers/SerpAPIProvider');
    const { ClaudeHaikuProvider } = require('../../providers/ClaudeHaikuProvider');

    SerpAPIProvider.mockImplementation(() => ({
      searchWithRetry: jest.fn().mockResolvedValue({
        visual_matches: [{
          position: 1,
          title: 'Coleman Triton Stove',
          link: 'https://example.com',
          source: 'Amazon',
          price: { value: '$44.99', extracted_value: 44.99, currency: 'USD' },
        }],
        latency: 2500,
      }),
    }));

    ClaudeHaikuProvider.mockImplementation(() => ({
      parse: jest.fn().mockResolvedValue({
        brand: 'Coleman',
        model: 'Triton',
        variant: '2-Burner',
        estimatedValue: 44.99,
        confidence: 0.9,
        reasoning: 'Consistent results',
        tokensUsed: { input: 500, output: 100, total: 600 },
        cost: 0.001,
        latency: 800,
      }),
    }));

    const itemData = {
      imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
      barcodeData: null,
    };

    const result = await identifyProduct(itemData, 'test_item_456');

    // Should use visual search
    expect(result.source).toBe('serpapi');
    expect(result.product.brand).toBe('Coleman');
  });
});
