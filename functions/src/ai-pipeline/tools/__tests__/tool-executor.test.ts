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

describe('Tool Executor', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should route google_lens_search to searchGoogleLens', async () => {
    (searchGoogleLens as jest.Mock).mockResolvedValueOnce({
      exact_matches: true,
      products: [{ title: 'Test Product' }]
    });

    const result = await executeToolCall(
      'google_lens_search',
      { image_url: 'https://example.com/image.jpg' },
      'https://example.com/image.jpg'
    );

    expect(searchGoogleLens).toHaveBeenCalledWith('https://example.com/image.jpg');
    expect((result as any).exact_matches).toBe(true);
  });

  it('should route barcode_lookup to lookupBarcode', async () => {
    (lookupBarcode as jest.Mock).mockResolvedValueOnce({
      found: true,
      product: { title: 'Test Product', brand: 'TestBrand' }
    });

    const result = await executeToolCall(
      'barcode_lookup',
      { code: '012345678905', symbology: 'upc_a' },
      'https://example.com/image.jpg'
    );

    expect(lookupBarcode).toHaveBeenCalledWith('012345678905', 'upc_a');
    expect((result as any).found).toBe(true);
  });

  it('should route web_search to searchWeb', async () => {
    (searchWeb as jest.Mock).mockResolvedValueOnce({
      prices: [{ source: 'Amazon', price: 99.99 }]
    });

    const result = await executeToolCall(
      'web_search',
      { query: 'Nike Air Max price' },
      'https://example.com/image.jpg'
    );

    expect(searchWeb).toHaveBeenCalledWith('Nike Air Max price');
    expect((result as any).prices).toHaveLength(1);
  });

  it('should throw error for unknown tool', async () => {
    await expect(executeToolCall(
      'unknown_tool',
      {},
      'https://example.com/image.jpg'
    )).rejects.toThrow('Unknown tool: unknown_tool');
  });

  it('should use provided image_url for google_lens or fall back to default', async () => {
    (searchGoogleLens as jest.Mock).mockResolvedValueOnce({ exact_matches: false, products: [] });

    await executeToolCall(
      'google_lens_search',
      {},
      'https://default.com/image.jpg'
    );

    expect(searchGoogleLens).toHaveBeenCalledWith('https://default.com/image.jpg');
  });

  it('should prefer args.image_url over default imageUrl for google_lens', async () => {
    (searchGoogleLens as jest.Mock).mockResolvedValueOnce({ exact_matches: false, products: [] });

    await executeToolCall(
      'google_lens_search',
      { image_url: 'https://override.com/image.jpg' },
      'https://default.com/image.jpg'
    );

    expect(searchGoogleLens).toHaveBeenCalledWith('https://override.com/image.jpg');
  });

  it('should pass undefined symbology for barcode_lookup when not provided', async () => {
    (lookupBarcode as jest.Mock).mockResolvedValueOnce({ found: false });

    await executeToolCall(
      'barcode_lookup',
      { code: '012345678905' },
      'https://example.com/image.jpg'
    );

    expect(lookupBarcode).toHaveBeenCalledWith('012345678905', undefined);
  });
});
