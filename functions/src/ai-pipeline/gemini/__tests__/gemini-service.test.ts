import { processItemWithGemini } from '../gemini-service';

jest.mock('@google/genai');
jest.mock('../../tools/tool-executor');
jest.mock('../vertexai-config');

import { executeToolCall } from '../../tools/tool-executor';
import { createVertexAIClient } from '../vertexai-config';

describe('Gemini Service', () => {
  const mockExecuteToolCall = executeToolCall as jest.MockedFunction<typeof executeToolCall>;
  const mockCreateVertexAIClient = createVertexAIClient as jest.MockedFunction<typeof createVertexAIClient>;
  const originalFetch = global.fetch;

  beforeEach(() => {
    jest.clearAllMocks();
    // Vertex AI config for Gemini 3 models
    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    process.env.GOOGLE_CLOUD_LOCATION = 'global';
  });

  afterEach(() => {
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_LOCATION;
    global.fetch = originalFetch;
  });

  it('should process image and return CatalogItem', async () => {
    const imageBuffer = Buffer.from('fake-image-data');
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'image/jpeg' : null
      },
      arrayBuffer: async () => imageBuffer.buffer
    });

    const mockCatalogItem = {
      name: 'Test Product',
      category: 'electronics',
      subCategory: 'gadgets',
      brand: 'TestBrand',
      model: 'Model-1',
      color: 'black',
      condition: 'good',
      dimensions: null,
      quantity: 1,
      estimatedValue: 50.00,
      confidence: 'medium'
    };

    const mockGenerateContent = jest.fn().mockResolvedValueOnce({
      text: JSON.stringify(mockCatalogItem)
    });

    mockCreateVertexAIClient.mockReturnValue({
      models: {
        generateContent: mockGenerateContent
      }
    } as any);

    const result = await processItemWithGemini('https://example.com/image.jpg');

    expect(result).toEqual(mockCatalogItem);
  });

  it('should throw error when project is not configured', async () => {
    delete process.env.GOOGLE_CLOUD_PROJECT;

    // Mock fetch so the test can proceed to the Vertex AI client creation
    const imageBuffer = Buffer.from('fake-image-data');
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'image/jpeg' : null
      },
      arrayBuffer: async () => imageBuffer.buffer
    });

    // Mock createVertexAIClient to throw when project is missing
    mockCreateVertexAIClient.mockImplementation(() => {
      throw new Error('GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI');
    });

    await expect(processItemWithGemini('https://example.com/image.jpg'))
      .rejects.toThrow('GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI');
  });

  it('should throw error when image fetch fails', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 404,
      statusText: 'Not Found'
    });

    await expect(processItemWithGemini('https://example.com/image.jpg'))
      .rejects.toThrow('Failed to fetch image');
  });

  it('should handle tool calling loop', async () => {
    const imageBuffer = Buffer.from('fake-image-data');
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'image/jpeg' : null
      },
      arrayBuffer: async () => imageBuffer.buffer
    });

    const mockCatalogItem = {
      name: 'Sony WH-1000XM4',
      category: 'electronics',
      subCategory: 'headphones',
      brand: 'Sony',
      model: 'WH-1000XM4',
      color: 'black',
      condition: 'good',
      dimensions: null,
      quantity: 1,
      estimatedValue: 199.99,
      confidence: 'high'
    };

    // First call returns a function call
    const mockGenerateContent = jest.fn()
      .mockResolvedValueOnce({
        functionCalls: [
          { name: 'google_lens_search', args: { image_url: 'https://example.com/image.jpg' } }
        ],
        text: null
      })
      // Second call after tool result returns final answer
      .mockResolvedValueOnce({
        functionCalls: [],
        text: JSON.stringify(mockCatalogItem)
      });

    mockCreateVertexAIClient.mockReturnValue({
      models: {
        generateContent: mockGenerateContent
      }
    } as any);

    mockExecuteToolCall.mockResolvedValueOnce({
      exact_matches: true,
      products: [{ title: 'Sony WH-1000XM4', price: 199.99 }]
    });

    const result = await processItemWithGemini('https://example.com/image.jpg');

    expect(mockExecuteToolCall).toHaveBeenCalledWith(
      'google_lens_search',
      { image_url: 'https://example.com/image.jpg' },
      'https://example.com/image.jpg'
    );
    expect(mockGenerateContent).toHaveBeenCalledTimes(2);
    expect(result).toEqual(mockCatalogItem);
  });

  it('should handle multiple tool calls in sequence', async () => {
    const imageBuffer = Buffer.from('fake-image-data');
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'image/jpeg' : null
      },
      arrayBuffer: async () => imageBuffer.buffer
    });

    const mockCatalogItem = {
      name: 'Test Product',
      category: 'electronics',
      subCategory: 'gadgets',
      brand: 'TestBrand',
      model: 'TB-001',
      color: 'silver',
      condition: 'like-new',
      dimensions: null,
      quantity: 1,
      estimatedValue: 75.00,
      confidence: 'high'
    };

    const mockGenerateContent = jest.fn()
      // First call: barcode lookup
      .mockResolvedValueOnce({
        functionCalls: [
          { name: 'barcode_lookup', args: { code: '012345678905' } }
        ],
        text: null
      })
      // Second call: web search for pricing
      .mockResolvedValueOnce({
        functionCalls: [
          { name: 'web_search', args: { query: 'TestBrand TB-001 price' } }
        ],
        text: null
      })
      // Final response
      .mockResolvedValueOnce({
        functionCalls: [],
        text: JSON.stringify(mockCatalogItem)
      });

    mockCreateVertexAIClient.mockReturnValue({
      models: {
        generateContent: mockGenerateContent
      }
    } as any);

    mockExecuteToolCall
      .mockResolvedValueOnce({
        found: true,
        product: { title: 'TestBrand TB-001', brand: 'TestBrand' }
      })
      .mockResolvedValueOnce({
        prices: [{ source: 'Amazon', price: 75.00 }]
      });

    const result = await processItemWithGemini('https://example.com/image.jpg');

    expect(mockExecuteToolCall).toHaveBeenCalledTimes(2);
    expect(mockGenerateContent).toHaveBeenCalledTimes(3);
    expect(result).toEqual(mockCatalogItem);
  });

  it('should throw error when no text response from Gemini', async () => {
    const imageBuffer = Buffer.from('fake-image-data');
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'image/jpeg' : null
      },
      arrayBuffer: async () => imageBuffer.buffer
    });

    const mockGenerateContent = jest.fn().mockResolvedValueOnce({
      functionCalls: [],
      text: null
    });

    mockCreateVertexAIClient.mockReturnValue({
      models: {
        generateContent: mockGenerateContent
      }
    } as any);

    await expect(processItemWithGemini('https://example.com/image.jpg'))
      .rejects.toThrow('No text response from Gemini');
  });

  it('should throw error for invalid content type', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'application/json' : null
      },
      arrayBuffer: async () => new ArrayBuffer(0)
    });

    await expect(processItemWithGemini('https://example.com/data.json'))
      .rejects.toThrow('Invalid content type');
  });

  it('should limit tool calling iterations to prevent infinite loops', async () => {
    const imageBuffer = Buffer.from('fake-image-data');
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'image/jpeg' : null
      },
      arrayBuffer: async () => imageBuffer.buffer
    });

    // Always return a function call (simulating infinite loop scenario)
    const mockGenerateContent = jest.fn().mockResolvedValue({
      functionCalls: [
        { name: 'google_lens_search', args: { image_url: 'https://example.com/image.jpg' } }
      ],
      text: null
    });

    mockCreateVertexAIClient.mockReturnValue({
      models: {
        generateContent: mockGenerateContent
      }
    } as any);

    mockExecuteToolCall.mockResolvedValue({
      exact_matches: false,
      products: []
    });

    // After max iterations, should throw error because no text response
    await expect(processItemWithGemini('https://example.com/image.jpg'))
      .rejects.toThrow('No text response from Gemini');

    // Should have called generateContent 11 times (1 initial + 10 iterations)
    expect(mockGenerateContent).toHaveBeenCalledTimes(11);
  });
});
