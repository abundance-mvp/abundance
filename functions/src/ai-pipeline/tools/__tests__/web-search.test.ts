import { searchWeb } from '../web-search';

jest.mock('@google/genai', () => ({
  GoogleGenAI: jest.fn().mockImplementation(() => ({
    models: {
      generateContent: jest.fn()
    }
  }))
}));

import { GoogleGenAI } from '@google/genai';

describe('Web Search Tool', () => {
  const MockGoogleGenAI = GoogleGenAI as jest.MockedClass<typeof GoogleGenAI>;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.GOOGLE_API_KEY = 'test-api-key';
  });

  afterEach(() => {
    delete process.env.GOOGLE_API_KEY;
  });

  it('should return prices from search results', async () => {
    const mockInstance = new MockGoogleGenAI({ apiKey: 'test' });
    (mockInstance.models.generateContent as jest.Mock).mockResolvedValueOnce({
      text: JSON.stringify({
        prices: [
          { source: 'Amazon', price: 89.99, condition: 'new' },
          { source: 'eBay', price: 65.00, condition: 'used' }
        ]
      })
    });

    MockGoogleGenAI.mockImplementation(() => mockInstance);

    const result = await searchWeb('Nike Air Max 90 size 10 price');

    expect(result.prices).toHaveLength(2);
    expect(result.prices[0].source).toBe('Amazon');
    expect(result.prices[0].price).toBe(89.99);
  });

  it('should return empty prices on parse error', async () => {
    const mockInstance = new MockGoogleGenAI({ apiKey: 'test' });
    (mockInstance.models.generateContent as jest.Mock).mockResolvedValueOnce({
      text: 'Invalid JSON response'
    });

    MockGoogleGenAI.mockImplementation(() => mockInstance);

    const result = await searchWeb('Unknown product price');

    expect(result.prices).toHaveLength(0);
    expect(result.raw).toBe('Invalid JSON response');
  });

  it('should throw error when API key is missing', async () => {
    delete process.env.GOOGLE_API_KEY;

    await expect(searchWeb('Test query'))
      .rejects.toThrow('GOOGLE_API_KEY environment variable is required');
  });
});
