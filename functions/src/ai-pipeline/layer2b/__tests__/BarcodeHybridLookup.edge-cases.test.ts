import { BarcodeHybridLookup } from '../BarcodeHybridLookup';
import { OpenFoodFactsProvider } from '../../providers/OpenFoodFactsProvider';
import { UPCitemdbProvider, RateLimitError, QuotaExceededError } from '../../providers/UPCitemdbProvider';

// Mock providers
jest.mock('../../providers/OpenFoodFactsProvider');
jest.mock('../../providers/UPCitemdbProvider');

describe('BarcodeHybridLookup - Edge Cases', () => {
  let lookup: BarcodeHybridLookup;
  let mockOpenFoodFacts: jest.Mocked<OpenFoodFactsProvider>;
  let mockUPCitemdb: jest.Mocked<UPCitemdbProvider>;

  beforeEach(() => {
    mockOpenFoodFacts = new OpenFoodFactsProvider() as jest.Mocked<OpenFoodFactsProvider>;
    mockUPCitemdb = new UPCitemdbProvider() as jest.Mocked<UPCitemdbProvider>;
    lookup = new BarcodeHybridLookup();
    (lookup as any).openFoodFacts = mockOpenFoodFacts;
    (lookup as any).upcitemdb = mockUPCitemdb;
  });

  describe('Both providers fail', () => {
    it('should return null when both providers timeout', async () => {
      mockOpenFoodFacts.lookup.mockRejectedValue(new Error('Timeout'));
      mockUPCitemdb.lookup.mockRejectedValue(new Error('Timeout'));

      const result = await lookup.lookup({ value: '1234567890123', type: 'EAN-13' }, 'test-item');

      expect(result).toBeNull();
    });

    it('should return null when both providers return 404', async () => {
      mockOpenFoodFacts.lookup.mockResolvedValue(null);
      mockUPCitemdb.lookup.mockResolvedValue(null);

      const result = await lookup.lookup({ value: '9999999999999', type: 'EAN-13' }, 'test-item');

      expect(result).toBeNull();
    });
  });

  describe('UPCitemdb rate limiting', () => {
    it('should fallback to OpenFoodFacts when UPCitemdb hits rate limit', async () => {
      const openFoodFactsResult = {
        found: true,
        source: 'openfoodfacts' as const,
        name: 'Test Product',
        brand: 'Test Brand',
        category: 'food',
        barcode: '1234567890123',
        latency: 100,
      };

      mockOpenFoodFacts.lookup.mockResolvedValue(openFoodFactsResult);
      mockUPCitemdb.lookup.mockRejectedValue(new RateLimitError('Rate limit exceeded', 429));

      const result = await lookup.lookup({ value: '1234567890123', type: 'EAN-13' }, 'test-item');

      expect(result).toEqual(openFoodFactsResult);
      expect(mockOpenFoodFacts.lookup).toHaveBeenCalled();
    });

    it('should return null when UPCitemdb quota exceeded and OpenFoodFacts fails', async () => {
      mockOpenFoodFacts.lookup.mockResolvedValue(null);
      mockUPCitemdb.lookup.mockRejectedValue(new QuotaExceededError('Quota exceeded', 403));

      const result = await lookup.lookup({ value: '1234567890123', type: 'EAN-13' }, 'test-item');

      expect(result).toBeNull();
    });
  });

  describe('Invalid barcode formats', () => {
    it('should handle short barcodes gracefully', async () => {
      const result = await lookup.lookup({ value: '123', type: 'CODE-128' }, 'test-item');

      expect(result).toBeNull();
    });

    it('should handle non-numeric barcodes', async () => {
      const result = await lookup.lookup({ value: 'ABC-DEF-GHI', type: 'CODE-128' }, 'test-item');

      expect(result).toBeNull();
    });
  });

  describe('Data inconsistencies', () => {
    it('should handle missing product name', async () => {
      const malformedResult = {
        found: true,
        source: 'openfoodfacts' as const,
        name: '',  // Empty name
        brand: 'Test Brand',
        category: 'unknown',
        barcode: '1234567890123',
        latency: 100,
      };

      mockOpenFoodFacts.lookup.mockResolvedValue(malformedResult);

      const result = await lookup.lookup({ value: '1234567890123', type: 'EAN-13' }, 'test-item');

      expect(result).toBeDefined();
      expect(result?.name).toBe('');  // Should preserve empty name for Layer 3 to handle
    });
  });
});
