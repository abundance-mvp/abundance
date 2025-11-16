import { SerpAPIProvider, InvalidAPIKeyError } from '../SerpAPIProvider';

describe('SerpAPIProvider', () => {
  let provider: SerpAPIProvider;

  beforeEach(() => {
    process.env.SERPAPI_API_KEY = 'test-serpapi-key';
    provider = new SerpAPIProvider();
  });

  test('searches with valid image URL', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        visual_matches: [
          {
            position: 1,
            title: 'Coleman Triton 2-Burner Camping Stove - Green',
            link: 'https://www.amazon.com/Coleman-Triton-Camping-Stove/dp/B0009PUQK8',
            source: 'Amazon.com',
            price: {
              value: '$44.99',
              extracted_value: 44.99,
              currency: 'USD',
            },
            thumbnail: 'https://example.com/thumb.jpg',
          },
        ],
        search_metadata: {
          id: 'search_123',
          status: 'Success',
          total_time_taken: 2.75,
        },
      }),
    });

    const imageUrl = 'https://storage.googleapis.com/abundance-items/test-item.jpg';
    const response = await provider.search(imageUrl, 'test_item_123');

    expect(response.visual_matches).toHaveLength(1);
    expect(response.visual_matches[0].title).toContain('Coleman Triton');
    expect(response.visual_matches[0].price?.extracted_value).toBe(44.99);
    expect(response.latency).toBeGreaterThanOrEqual(0);
  });

  test('returns empty array when no visual matches', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        search_metadata: { status: 'Success' },
      }),
    });

    const imageUrl = 'https://storage.googleapis.com/abundance-items/test-item.jpg';
    const response = await provider.search(imageUrl, 'test_item_456');

    expect(response.visual_matches).toEqual([]);
  });

  test('throws InvalidAPIKeyError on 403', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 403,
    });

    const imageUrl = 'https://storage.googleapis.com/abundance-items/test-item.jpg';
    await expect(provider.search(imageUrl, 'test_item_789')).rejects.toThrow(InvalidAPIKeyError);
  });

  test('throws error for non-HTTPS URL', async () => {
    const imageUrl = 'http://storage.googleapis.com/abundance-items/test-item.jpg';
    await expect(provider.search(imageUrl, 'test_item_103')).rejects.toThrow('must be HTTPS');
  });
});
