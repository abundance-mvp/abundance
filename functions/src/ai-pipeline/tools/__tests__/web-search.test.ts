jest.mock('../../gemini/vertexai-config');
import { createVertexAIClient } from '../../gemini/vertexai-config';
import { searchWeb } from '../web-search';

describe('Web Search Tool', () => {
  const mockCreateVertexAIClient = createVertexAIClient as jest.MockedFunction<typeof createVertexAIClient>;

  let mockGenerateContent: jest.Mock;
  let mockAIClient: { models: { generateContent: jest.Mock } };

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    process.env.GOOGLE_CLOUD_LOCATION = 'global';

    mockGenerateContent = jest.fn();
    mockAIClient = {
      models: {
        generateContent: mockGenerateContent
      }
    };
    mockCreateVertexAIClient.mockReturnValue(mockAIClient as any);
  });

  afterEach(() => {
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_LOCATION;
  });

  it('should return prices from search results', async () => {
    mockGenerateContent.mockResolvedValueOnce({
      text: JSON.stringify({
        prices: [
          { source: 'Amazon', price: 89.99, condition: 'new' },
          { source: 'eBay', price: 65.00, condition: 'used' }
        ]
      })
    });

    const result = await searchWeb('Nike Air Max 90 size 10 price');

    expect(result.prices).toHaveLength(2);
    expect(result.prices[0].source).toBe('Amazon');
    expect(result.prices[0].price).toBe(89.99);
    expect(mockCreateVertexAIClient).toHaveBeenCalled();
  });

  it('should return empty prices on parse error', async () => {
    mockGenerateContent.mockResolvedValueOnce({
      text: 'Invalid JSON response'
    });

    const result = await searchWeb('Unknown product price');

    expect(result.prices).toHaveLength(0);
    expect(result.raw).toBe('Invalid JSON response');
  });

  it('should throw error when project is not configured', async () => {
    mockCreateVertexAIClient.mockImplementation(() => {
      throw new Error('GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI');
    });

    await expect(searchWeb('Test query'))
      .rejects.toThrow('GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI');
  });
});
