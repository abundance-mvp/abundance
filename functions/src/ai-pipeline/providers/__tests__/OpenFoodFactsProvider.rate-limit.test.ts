import { OpenFoodFactsProvider, RateLimitError } from '../OpenFoodFactsProvider';

global.fetch = jest.fn();

describe('OpenFoodFactsProvider - Rate Limiting', () => {
  let provider: OpenFoodFactsProvider;

  beforeEach(() => {
    provider = new OpenFoodFactsProvider();
    jest.clearAllMocks();
  });

  it('should throw RateLimitError when API returns 429', async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: false,
      status: 429,
      headers: new Map([['retry-after', '60']]),
    });

    await expect(provider.lookup('3017620422003')).rejects.toThrow(RateLimitError);
    await expect(provider.lookup('3017620422003')).rejects.toMatchObject({
      status: 429,
      retryAfter: 60,
    });
  });

  it('should extract retry-after header from 429 response', async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: false,
      status: 429,
      headers: new Map([['retry-after', '120']]),
    });

    try {
      await provider.lookup('3017620422003');
    } catch (error) {
      expect(error).toBeInstanceOf(RateLimitError);
      expect((error as RateLimitError).retryAfter).toBe(120);
    }
  });

  it('should default to 60s retry-after if header missing', async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: false,
      status: 429,
      headers: new Map(),
    });

    try {
      await provider.lookup('3017620422003');
    } catch (error) {
      expect(error).toBeInstanceOf(RateLimitError);
      expect((error as RateLimitError).retryAfter).toBe(60);
    }
  });
});
