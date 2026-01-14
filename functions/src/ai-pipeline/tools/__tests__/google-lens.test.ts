import { searchGoogleLens } from '../google-lens';

describe('Google Lens Tool', () => {
  const originalFetch = global.fetch;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.SERPAPI_KEY = 'test-api-key';
  });

  afterEach(() => {
    delete process.env.SERPAPI_KEY;
    global.fetch = originalFetch;
  });

  it('should return exact match when found', async () => {
    const mockResponse = {
      visual_matches: [
        {
          position: 1,
          title: 'Nike Air Max 90',
          source: 'nike.com',
          link: 'https://nike.com/air-max-90',
          price: { extracted_value: 120, currency: 'USD' },
          exact_match: true
        }
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await searchGoogleLens('https://example.com/image.jpg');

    expect(result.exact_matches).toBe(true);
    expect(result.products).toHaveLength(1);
    expect(result.products[0].title).toBe('Nike Air Max 90');
    expect(result.products[0].price).toBe(120);
  });

  it('should return empty products when no matches', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ visual_matches: [] })
    });

    const result = await searchGoogleLens('https://example.com/image.jpg');

    expect(result.exact_matches).toBe(false);
    expect(result.products).toHaveLength(0);
  });

  it('should throw error when API key is missing', async () => {
    delete process.env.SERPAPI_KEY;

    await expect(searchGoogleLens('https://example.com/image.jpg'))
      .rejects.toThrow('SERPAPI_KEY environment variable is required');
  });

  it('should limit results to 5 products', async () => {
    const mockResponse = {
      visual_matches: Array(10).fill({
        position: 1,
        title: 'Product',
        source: 'amazon.com',
        link: 'https://amazon.com',
        price: { extracted_value: 50 }
      })
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await searchGoogleLens('https://example.com/image.jpg');

    expect(result.products).toHaveLength(5);
  });

  it('should extract brand from known brands in title', async () => {
    const mockResponse = {
      visual_matches: [
        {
          position: 1,
          title: 'Apple iPhone 15 Pro Max',
          source: 'apple.com',
          link: 'https://apple.com/iphone',
          price: { extracted_value: 1199 }
        }
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await searchGoogleLens('https://example.com/image.jpg');

    expect(result.products[0].brand).toBe('Apple');
  });

  it('should use brand field if provided', async () => {
    const mockResponse = {
      visual_matches: [
        {
          position: 1,
          title: 'Wireless Headphones',
          brand: 'Sony',
          source: 'amazon.com',
          link: 'https://amazon.com/headphones',
          price: { extracted_value: 299 }
        }
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await searchGoogleLens('https://example.com/image.jpg');

    expect(result.products[0].brand).toBe('Sony');
  });

  it('should handle API errors gracefully', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error'
    });

    await expect(searchGoogleLens('https://example.com/image.jpg'))
      .rejects.toThrow('SerpAPI request failed: 500 Internal Server Error');
  });

  it('should handle missing price gracefully', async () => {
    const mockResponse = {
      visual_matches: [
        {
          position: 1,
          title: 'Generic Product',
          source: 'example.com',
          link: 'https://example.com/product'
          // No price field
        }
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await searchGoogleLens('https://example.com/image.jpg');

    expect(result.products[0].price).toBeUndefined();
  });

  it('should handle missing title gracefully', async () => {
    const mockResponse = {
      visual_matches: [
        {
          position: 1,
          source: 'example.com',
          link: 'https://example.com/product'
          // No title field
        }
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await searchGoogleLens('https://example.com/image.jpg');

    expect(result.products[0].title).toBe('Unknown Product');
  });

  it('should construct correct SerpAPI URL', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ visual_matches: [] })
    });

    await searchGoogleLens('https://example.com/image.jpg');

    expect(global.fetch).toHaveBeenCalledTimes(1);
    const calledUrl = (global.fetch as jest.Mock).mock.calls[0][0];
    expect(calledUrl).toContain('https://serpapi.com/search');
    expect(calledUrl).toContain('engine=google_lens');
    expect(calledUrl).toContain('url=https%3A%2F%2Fexample.com%2Fimage.jpg');
    expect(calledUrl).toContain('api_key=test-api-key');
  });
});
