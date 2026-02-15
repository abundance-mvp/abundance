/**
 * Tool Resilience Tests
 *
 * Tests error handling and edge cases for AI pipeline tools.
 * Verifies that tool failures are handled gracefully without
 * crashing the pipeline.
 */

import { executeToolCall } from '../tool-executor';

jest.mock('../google-lens', () => ({
  searchGoogleLens: jest.fn()
}));
jest.mock('../barcode-lookup', () => ({
  lookupBarcode: jest.fn()
}));
jest.mock('../web-search', () => ({
  searchWeb: jest.fn()
}));

import { searchGoogleLens } from '../google-lens';
import { lookupBarcode } from '../barcode-lookup';
import { searchWeb } from '../web-search';

describe('Tool Resilience Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('google_lens_search resilience', () => {
    it('handles timeout error gracefully', async () => {
      (searchGoogleLens as jest.Mock).mockRejectedValueOnce(
        new Error('Request timeout after 10000ms')
      );

      await expect(executeToolCall(
        'google_lens_search',
        { image_url: 'https://example.com/image.jpg' },
        'https://example.com/image.jpg'
      )).rejects.toThrow('timeout');
    });

    it('handles network error gracefully', async () => {
      (searchGoogleLens as jest.Mock).mockRejectedValueOnce(
        new Error('ECONNREFUSED: Connection refused')
      );

      await expect(executeToolCall(
        'google_lens_search',
        { image_url: 'https://example.com/image.jpg' },
        'https://example.com/image.jpg'
      )).rejects.toThrow('ECONNREFUSED');
    });

    it('handles empty results from Google Lens', async () => {
      (searchGoogleLens as jest.Mock).mockResolvedValueOnce({
        exact_matches: false,
        products: []
      });

      const result = await executeToolCall(
        'google_lens_search',
        { image_url: 'https://example.com/image.jpg' },
        'https://example.com/image.jpg'
      );

      expect((result as any).exact_matches).toBe(false);
      expect((result as any).products).toHaveLength(0);
    });

    it('handles null response from Google Lens', async () => {
      (searchGoogleLens as jest.Mock).mockResolvedValueOnce(null);

      const result = await executeToolCall(
        'google_lens_search',
        { image_url: 'https://example.com/image.jpg' },
        'https://example.com/image.jpg'
      );

      expect(result).toBeNull();
    });
  });

  describe('barcode_lookup resilience', () => {
    it('returns found:false for non-existent barcode', async () => {
      (lookupBarcode as jest.Mock).mockResolvedValueOnce({
        found: false
      });

      const result = await executeToolCall(
        'barcode_lookup',
        { code: '000000000000' },
        'https://example.com/image.jpg'
      );

      expect((result as any).found).toBe(false);
      expect((result as any).product).toBeUndefined();
    });

    it('handles 404 error gracefully', async () => {
      (lookupBarcode as jest.Mock).mockResolvedValueOnce({
        found: false,
        barcode: '999999999999'
      });

      const result = await executeToolCall(
        'barcode_lookup',
        { code: '999999999999', symbology: 'upc_a' },
        'https://example.com/image.jpg'
      );

      expect((result as any).found).toBe(false);
    });

    it('handles API error with graceful degradation', async () => {
      (lookupBarcode as jest.Mock).mockRejectedValueOnce(
        new Error('HTTP 500: Internal Server Error')
      );

      await expect(executeToolCall(
        'barcode_lookup',
        { code: '012345678905' },
        'https://example.com/image.jpg'
      )).rejects.toThrow('500');
    });

    it('returns product details for valid barcode', async () => {
      (lookupBarcode as jest.Mock).mockResolvedValueOnce({
        found: true,
        product: {
          title: 'Coleman Sundome 4-Person Tent',
          brand: 'Coleman',
          model: '2000024582',
          description: '4-person dome tent'
        },
        barcode: '076501049718'
      });

      const result = await executeToolCall(
        'barcode_lookup',
        { code: '076501049718', symbology: 'upc_a' },
        'https://example.com/image.jpg'
      );

      expect((result as any).found).toBe(true);
      expect((result as any).product.brand).toBe('Coleman');
    });
  });

  describe('web_search resilience', () => {
    it('returns empty prices for no results', async () => {
      (searchWeb as jest.Mock).mockResolvedValueOnce({
        prices: []
      });

      const result = await executeToolCall(
        'web_search',
        { query: 'nonexistent product xyz12345' },
        'https://example.com/image.jpg'
      );

      expect((result as any).prices).toHaveLength(0);
    });

    it('handles raw text response when JSON parsing fails', async () => {
      (searchWeb as jest.Mock).mockResolvedValueOnce({
        prices: [],
        raw: 'Could not find pricing information for this product.'
      });

      const result = await executeToolCall(
        'web_search',
        { query: 'vintage item no price' },
        'https://example.com/image.jpg'
      );

      expect((result as any).prices).toHaveLength(0);
      expect((result as any).raw).toContain('Could not find');
    });

    it('handles network timeout', async () => {
      (searchWeb as jest.Mock).mockRejectedValueOnce(
        new Error('Request timed out after 30000ms')
      );

      await expect(executeToolCall(
        'web_search',
        { query: 'Nike Air Max price' },
        'https://example.com/image.jpg'
      )).rejects.toThrow('timed out');
    });

    it('returns multiple prices from different sources', async () => {
      (searchWeb as jest.Mock).mockResolvedValueOnce({
        prices: [
          { source: 'Amazon', price: 129.99, condition: 'new' },
          { source: 'eBay', price: 89.99, condition: 'used' },
          { source: 'Walmart', price: 119.99, condition: 'new' }
        ]
      });

      const result = await executeToolCall(
        'web_search',
        { query: 'Coleman Sundome tent price' },
        'https://example.com/image.jpg'
      );

      expect((result as any).prices).toHaveLength(3);
      expect((result as any).prices[0].source).toBe('Amazon');
      expect((result as any).prices[1].price).toBe(89.99);
    });
  });

  describe('Unknown tool handling', () => {
    it('throws descriptive error for unknown tool name', async () => {
      await expect(executeToolCall(
        'image_segmentation',
        { image_url: 'https://example.com/image.jpg' },
        'https://example.com/image.jpg'
      )).rejects.toThrow('Unknown tool: image_segmentation');
    });

    it('throws descriptive error for empty tool name', async () => {
      await expect(executeToolCall(
        '',
        {},
        'https://example.com/image.jpg'
      )).rejects.toThrow('Unknown tool: ');
    });
  });

  describe('Parallel tool execution', () => {
    it('all results collected from parallel tool calls', async () => {
      (searchGoogleLens as jest.Mock).mockResolvedValueOnce({
        exact_matches: true,
        products: [{ title: 'Test Product', price: 99 }]
      });
      (lookupBarcode as jest.Mock).mockResolvedValueOnce({
        found: true,
        product: { title: 'Barcode Product', brand: 'TestBrand' }
      });
      (searchWeb as jest.Mock).mockResolvedValueOnce({
        prices: [{ source: 'Amazon', price: 89.99 }]
      });

      // Simulate parallel execution
      const [lensResult, barcodeResult, webResult] = await Promise.all([
        executeToolCall('google_lens_search', { image_url: 'url' }, 'url'),
        executeToolCall('barcode_lookup', { code: '012345678905' }, 'url'),
        executeToolCall('web_search', { query: 'test product price' }, 'url')
      ]);

      expect((lensResult as any).exact_matches).toBe(true);
      expect((barcodeResult as any).found).toBe(true);
      expect((webResult as any).prices).toHaveLength(1);
    });

    it('partial failure does not prevent other tools from completing', async () => {
      (searchGoogleLens as jest.Mock).mockRejectedValueOnce(
        new Error('Google Lens API timeout')
      );
      (lookupBarcode as jest.Mock).mockResolvedValueOnce({
        found: true,
        product: { title: 'Found Product' }
      });
      (searchWeb as jest.Mock).mockResolvedValueOnce({
        prices: [{ source: 'eBay', price: 49.99 }]
      });

      // Use Promise.allSettled to handle partial failures
      const results = await Promise.allSettled([
        executeToolCall('google_lens_search', { image_url: 'url' }, 'url'),
        executeToolCall('barcode_lookup', { code: '012345678905' }, 'url'),
        executeToolCall('web_search', { query: 'price' }, 'url')
      ]);

      expect(results[0].status).toBe('rejected');
      expect(results[1].status).toBe('fulfilled');
      expect(results[2].status).toBe('fulfilled');

      if (results[1].status === 'fulfilled') {
        expect((results[1].value as any).found).toBe(true);
      }
      if (results[2].status === 'fulfilled') {
        expect((results[2].value as any).prices).toHaveLength(1);
      }
    });
  });
});
