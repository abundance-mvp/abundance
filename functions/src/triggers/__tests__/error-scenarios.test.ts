import { identifyProduct } from '../../ai-pipeline/layer2b/identifyProduct';
import { synthesizeMetadata } from '../../ai-pipeline/layer3/synthesize';

jest.mock('../../ai-pipeline/layer2b/identifyProduct');
jest.mock('../../ai-pipeline/layer3/synthesize');

describe('Firestore Triggers - Error Scenarios', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Layer 2b error handling', () => {
    it('should handle identifyProduct errors by returning error object', async () => {
      // Mock identifyProduct to throw error
      (identifyProduct as jest.Mock).mockRejectedValue(new Error('SerpAPI timeout'));

      await expect(identifyProduct({ imageUrl: 'test.jpg', barcodeData: null }, 'test-item'))
        .rejects.toThrow('SerpAPI timeout');
    });
  });

  describe('Layer 3 error handling', () => {
    it('should handle synthesizeMetadata errors by throwing', async () => {
      // Mock synthesizeMetadata to throw error
      (synthesizeMetadata as jest.Mock).mockRejectedValue(new Error('Claude API error'));

      await expect(synthesizeMetadata({
        detectedLabel: 'phone',
        layer2a: { category: 'electronics', color: 'black', condition: 'good', confidence: 0.9 },
        layer2b: { source: 'barcode' as const, product: { brand: 'Apple', name: 'iPhone 14' } },
      }, 'test-item'))
        .rejects.toThrow('Claude API error');
    });
  });
});
