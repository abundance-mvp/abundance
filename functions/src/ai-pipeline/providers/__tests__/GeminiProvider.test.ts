import { GeminiProvider } from '../GeminiProvider';

// Mock node-fetch at module level
jest.mock('node-fetch', () => jest.fn());

describe('GeminiProvider', () => {
  describe('extractAttributes', () => {
    it('should extract attributes from image URL', async () => {
      // Mock environment variable
      process.env.GOOGLE_API_KEY = 'test_api_key';

      // Mock node-fetch
      const fetch = require('node-fetch');
      const mockFetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(
          Buffer.from('fake-image-data').buffer
        )
      });
      (fetch as jest.Mock).mockImplementation(mockFetch);

      const provider = new GeminiProvider();

      // Mock the SDK's generateContent method
      const mockGenerateContent = jest.fn().mockResolvedValue({
        text: JSON.stringify({
          category: 'camping',
          color: 'green',
          material: 'fabric',
          condition: 'good',
          confidence: 0.87
        }),
        usageMetadata: {
          promptTokenCount: 258,
          candidatesTokenCount: 100,
          totalTokenCount: 358
        }
      });

      // Inject mock into genAI.models
      (provider as any).genAI = {
        models: {
          generateContent: mockGenerateContent
        }
      };

      const result = await provider.extractAttributes(
        'https://storage.googleapis.com/test/image.jpg',
        'user123',
        'item456'
      );

      expect(result).toMatchObject({
        category: 'camping',
        color: 'green',
        material: 'fabric',
        condition: 'good',
        confidence: 0.87
      });
      expect(mockFetch).toHaveBeenCalledWith(
        'https://storage.googleapis.com/test/image.jpg'
      );
      expect(mockGenerateContent).toHaveBeenCalled();
    });

    it('should return usage metadata', async () => {
      process.env.GOOGLE_API_KEY = 'test_api_key';

      const fetch = require('node-fetch');
      const mockFetch = jest.fn().mockResolvedValue({
        arrayBuffer: jest.fn().mockResolvedValue(
          Buffer.from('fake-image-data').buffer
        )
      });
      (fetch as jest.Mock).mockImplementation(mockFetch);

      const provider = new GeminiProvider();

      const mockGenerateContent = jest.fn().mockResolvedValue({
        text: JSON.stringify({
          category: 'camping',
          color: 'green',
          condition: 'good'
        }),
        usageMetadata: {
          promptTokenCount: 258,
          candidatesTokenCount: 100,
          totalTokenCount: 358
        }
      });

      (provider as any).genAI = {
        models: {
          generateContent: mockGenerateContent
        }
      };

      const result = await provider.extractAttributes(
        'https://storage.googleapis.com/test/image.jpg',
        'user123',
        'item456'
      );

      const usage = (result as any).usage;
      expect(usage).toBeDefined();
      expect(usage.totalTokens).toBe(358);
      expect(usage.inputTokens).toBe(258);
      expect(usage.outputTokens).toBe(100);
    });

    it('should throw error if API key is missing', async () => {
      delete process.env.GOOGLE_API_KEY;

      await expect(async () => {
        const provider = new GeminiProvider();
        await provider.extractAttributes(
          'https://storage.googleapis.com/test/image.jpg',
          'user123',
          'item456'
        );
      }).rejects.toThrow();
    });
  });
});
