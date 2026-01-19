/**
 * Integration tests for processItemWithGeminiPersistent()
 *
 * Tests the full session persistence flow:
 * 1. History retrieval from Firestore
 * 2. Context injection into prompt
 * 3. Gemini call with optional context cache
 * 4. History save after successful processing
 * 5. Token counting across iterations
 */

import { processItemWithGeminiPersistent } from '../gemini-service';
import {
  getRecentCatalogHistory,
  saveCatalogHistory
} from '../catalog-history-service';
import { getOrCreateContextCache, clearCacheReference } from '../context-cache-service';
import { createVertexAIClient } from '../vertexai-config';
import { executeToolCall } from '../../tools/tool-executor';
import { Timestamp } from 'firebase-admin/firestore';

jest.mock('@google/genai');
jest.mock('../vertexai-config');
// Partial mock - only mock Firestore functions, keep utility functions
jest.mock('../catalog-history-service', () => {
  const actual = jest.requireActual('../catalog-history-service');
  return {
    ...actual,
    getRecentCatalogHistory: jest.fn(),
    saveCatalogHistory: jest.fn()
  };
});
jest.mock('../context-cache-service');
jest.mock('../../tools/tool-executor');

const mockCreateVertexAIClient = createVertexAIClient as jest.MockedFunction<typeof createVertexAIClient>;
const mockGetRecentCatalogHistory = getRecentCatalogHistory as jest.MockedFunction<typeof getRecentCatalogHistory>;
const mockSaveCatalogHistory = saveCatalogHistory as jest.MockedFunction<typeof saveCatalogHistory>;
const mockGetOrCreateContextCache = getOrCreateContextCache as jest.MockedFunction<typeof getOrCreateContextCache>;
const mockClearCacheReference = clearCacheReference as jest.MockedFunction<typeof clearCacheReference>;
const mockExecuteToolCall = executeToolCall as jest.MockedFunction<typeof executeToolCall>;

describe('processItemWithGeminiPersistent - Integration', () => {
  const originalFetch = global.fetch;
  let mockGenerateContent: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    mockClearCacheReference.mockImplementation(() => {});

    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    process.env.GOOGLE_CLOUD_LOCATION = 'global';

    // Setup mock fetch for image retrieval
    const imageBuffer = Buffer.from('fake-image-data');
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      headers: {
        get: (name: string) => name === 'content-type' ? 'image/jpeg' : null
      },
      arrayBuffer: async () => imageBuffer.buffer
    });

    // Setup mock Vertex AI client
    mockGenerateContent = jest.fn();
    mockCreateVertexAIClient.mockReturnValue({
      models: {
        generateContent: mockGenerateContent
      },
      caches: {
        create: jest.fn(),
        list: jest.fn(),
        delete: jest.fn()
      }
    } as any);

    // Default: no history
    mockGetRecentCatalogHistory.mockResolvedValue([]);

    // Default: save succeeds
    mockSaveCatalogHistory.mockResolvedValue('history-entry-id');

    // Default: context cache available
    mockGetOrCreateContextCache.mockResolvedValue({
      name: 'projects/test-project/cachedContents/cache-123',
      displayName: 'abundance-catalog-context'
    } as any);
  });

  afterEach(() => {
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_LOCATION;
    global.fetch = originalFetch;
  });

  describe('Full flow without history', () => {
    it('should process image and save history for new item', async () => {
      const mockCatalogItem = {
        name: 'Test Product',
        category: 'electronics',
        subCategory: 'gadgets',
        brand: 'TestBrand',
        model: 'Model-1',
        confidence: 'high'
      };

      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockCatalogItem),
        usageMetadata: { totalTokenCount: 150 }
      });

      const result = await processItemWithGeminiPersistent(
        'https://example.com/image.jpg',
        'item-123'
      );

      // Verify result
      expect(result).toEqual(mockCatalogItem);

      // Verify history was fetched
      expect(mockGetRecentCatalogHistory).toHaveBeenCalledWith('item-123', 1);

      // Verify history was saved
      expect(mockSaveCatalogHistory).toHaveBeenCalledWith('item-123', expect.objectContaining({
        model: expect.any(String),
        imageUrls: ['https://example.com/image.jpg'],
        toolCalls: [],
        result: expect.objectContaining({
          name: 'Test Product',
          category: 'electronics'
        }),
        metadata: expect.objectContaining({
          totalTokens: 150,
          usedContextCache: true
        })
      }));
    });

    it('should accumulate tokens across multiple iterations', async () => {
      const mockCatalogItem = {
        name: 'Sony Headphones',
        category: 'electronics',
        subCategory: 'headphones',
        brand: 'Sony',
        model: 'WH-1000XM4',
        confidence: 'high'
      };

      // First call returns function call, second returns result
      mockGenerateContent
        .mockResolvedValueOnce({
          functionCalls: [{ name: 'google_lens_search', args: { image_url: 'test.jpg' } }],
          candidates: [{
            content: {
              parts: [{ functionCall: { name: 'google_lens_search' } }]
            }
          }],
          usageMetadata: { totalTokenCount: 100 }
        })
        .mockResolvedValueOnce({
          text: JSON.stringify(mockCatalogItem),
          usageMetadata: { totalTokenCount: 200 }
        });

      mockExecuteToolCall.mockResolvedValue({
        exact_matches: true,
        products: [{ title: 'Sony WH-1000XM4' }]
      });

      await processItemWithGeminiPersistent(
        'https://example.com/image.jpg',
        'item-456'
      );

      // Verify total tokens accumulated (100 + 200 = 300)
      expect(mockSaveCatalogHistory).toHaveBeenCalledWith(
        'item-456',
        expect.objectContaining({
          metadata: expect.objectContaining({
            totalTokens: 300
          })
        })
      );
    });
  });

  describe('Full flow with existing history', () => {
    it('should include history context in prompt', async () => {
      // Setup existing history
      const mockTimestamp = {
        seconds: Math.floor(Date.now() / 1000),
        nanoseconds: 0,
        toDate: () => new Date(),
        toMillis: () => Date.now(),
        isEqual: () => false
      } as unknown as Timestamp;

      mockGetRecentCatalogHistory.mockResolvedValue([{
        id: 'history-1',
        catalogedAt: mockTimestamp,
        model: 'gemini-3-pro',
        imageUrls: ['https://example.com/old-image.jpg'],
        toolCalls: [{ name: 'barcode_lookup', args: {}, result: {}, success: true }],
        result: {
          name: 'Sony WH-1000XM4',
          brand: 'Sony',
          model: 'WH-1000XM4',
          category: 'electronics',
          subCategory: 'headphones',
          confidence: 'high',
          estimatedValue: 199,
          condition: 'good'
        },
        metadata: { totalTokens: 100, durationMs: 5000, usedContextCache: false }
      }]);

      const mockCatalogItem = {
        name: 'Sony WH-1000XM4',
        category: 'electronics',
        subCategory: 'headphones',
        brand: 'Sony',
        model: 'WH-1000XM4',
        confidence: 'high',
        condition: 'like-new' // Updated condition
      };

      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockCatalogItem),
        usageMetadata: { totalTokenCount: 120 }
      });

      const result = await processItemWithGeminiPersistent(
        'https://example.com/new-image.jpg',
        'item-789'
      );

      expect(result).toEqual(mockCatalogItem);

      // Verify generateContent was called with history context in prompt
      expect(mockGenerateContent).toHaveBeenCalledWith(
        expect.objectContaining({
          contents: expect.arrayContaining([
            expect.objectContaining({
              role: 'user',
              parts: expect.arrayContaining([
                expect.objectContaining({
                  text: expect.stringContaining('PREVIOUS CATALOG INFORMATION')
                })
              ])
            })
          ])
        })
      );
    });
  });

  describe('Context caching behavior', () => {
    it('should use context cache when available', async () => {
      const mockCache = {
        name: 'projects/test-project/cachedContents/cache-xyz',
        displayName: 'abundance-catalog-context'
      };
      mockGetOrCreateContextCache.mockResolvedValue(mockCache as any);

      const mockCatalogItem = { name: 'Test', category: 'other', confidence: 'low' };
      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockCatalogItem),
        usageMetadata: { totalTokenCount: 50 }
      });

      await processItemWithGeminiPersistent(
        'https://example.com/image.jpg',
        'item-cache-test'
      );

      // Verify generateContent was called with cached content reference
      expect(mockGenerateContent).toHaveBeenCalledWith(
        expect.objectContaining({
          config: expect.objectContaining({
            cachedContent: 'projects/test-project/cachedContents/cache-xyz'
          })
        })
      );

      // Verify history shows cache was used
      expect(mockSaveCatalogHistory).toHaveBeenCalledWith(
        'item-cache-test',
        expect.objectContaining({
          metadata: expect.objectContaining({
            usedContextCache: true
          })
        })
      );
    });

    it('should fallback to inline config when cache fails', async () => {
      mockGetOrCreateContextCache.mockRejectedValue(new Error('Cache unavailable'));

      const mockCatalogItem = { name: 'Fallback Test', category: 'other', confidence: 'low' };
      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockCatalogItem),
        usageMetadata: { totalTokenCount: 80 }
      });

      await processItemWithGeminiPersistent(
        'https://example.com/image.jpg',
        'item-fallback-test'
      );

      // Verify generateContent was called with inline config (not cached)
      expect(mockGenerateContent).toHaveBeenCalledWith(
        expect.objectContaining({
          config: expect.objectContaining({
            systemInstruction: expect.any(String),
            tools: expect.any(Array)
          })
        })
      );

      // Verify history shows cache was NOT used
      expect(mockSaveCatalogHistory).toHaveBeenCalledWith(
        'item-fallback-test',
        expect.objectContaining({
          metadata: expect.objectContaining({
            usedContextCache: false
          })
        })
      );
    });

    it('should skip cache when useContextCache is false', async () => {
      const mockCatalogItem = { name: 'No Cache Test', category: 'other', confidence: 'low' };
      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockCatalogItem),
        usageMetadata: { totalTokenCount: 60 }
      });

      await processItemWithGeminiPersistent(
        'https://example.com/image.jpg',
        'item-no-cache',
        false // useContextCache = false
      );

      // Should NOT have called getOrCreateContextCache
      expect(mockGetOrCreateContextCache).not.toHaveBeenCalled();

      // Verify history shows cache was not used
      expect(mockSaveCatalogHistory).toHaveBeenCalledWith(
        'item-no-cache',
        expect.objectContaining({
          metadata: expect.objectContaining({
            usedContextCache: false
          })
        })
      );
    });
  });

  describe('Tool call recording', () => {
    it('should record all tool calls in history', async () => {
      const mockCatalogItem = {
        name: 'Researched Product',
        category: 'electronics',
        brand: 'BrandX',
        confidence: 'high'
      };

      mockGenerateContent
        .mockResolvedValueOnce({
          functionCalls: [{ name: 'barcode_lookup', args: { code: '123456' } }],
          candidates: [{ content: { parts: [{ functionCall: { name: 'barcode_lookup' } }] } }],
          usageMetadata: { totalTokenCount: 50 }
        })
        .mockResolvedValueOnce({
          functionCalls: [{ name: 'web_search', args: { query: 'BrandX product' } }],
          candidates: [{ content: { parts: [{ functionCall: { name: 'web_search' } }] } }],
          usageMetadata: { totalTokenCount: 60 }
        })
        .mockResolvedValueOnce({
          text: JSON.stringify(mockCatalogItem),
          usageMetadata: { totalTokenCount: 70 }
        });

      mockExecuteToolCall
        .mockResolvedValueOnce({ found: true, product: { title: 'BrandX Item' } })
        .mockResolvedValueOnce({ results: [{ url: 'https://example.com' }] });

      await processItemWithGeminiPersistent(
        'https://example.com/image.jpg',
        'item-tools'
      );

      // Verify both tool calls were recorded
      expect(mockSaveCatalogHistory).toHaveBeenCalledWith(
        'item-tools',
        expect.objectContaining({
          toolCalls: expect.arrayContaining([
            expect.objectContaining({ name: 'barcode_lookup', success: true }),
            expect.objectContaining({ name: 'web_search', success: true })
          ])
        })
      );
    });

    it('should record failed tool calls', async () => {
      const mockCatalogItem = { name: 'Failed Tool Test', category: 'other', confidence: 'low' };

      mockGenerateContent
        .mockResolvedValueOnce({
          functionCalls: [{ name: 'barcode_lookup', args: { code: 'invalid' } }],
          candidates: [{ content: { parts: [{ functionCall: { name: 'barcode_lookup' } }] } }],
          usageMetadata: { totalTokenCount: 40 }
        })
        .mockResolvedValueOnce({
          text: JSON.stringify(mockCatalogItem),
          usageMetadata: { totalTokenCount: 50 }
        });

      mockExecuteToolCall.mockRejectedValueOnce(new Error('Invalid barcode'));

      await processItemWithGeminiPersistent(
        'https://example.com/image.jpg',
        'item-failed-tool'
      );

      // Verify failed tool call was recorded with success: false
      expect(mockSaveCatalogHistory).toHaveBeenCalledWith(
        'item-failed-tool',
        expect.objectContaining({
          toolCalls: expect.arrayContaining([
            expect.objectContaining({
              name: 'barcode_lookup',
              success: false,
              result: expect.objectContaining({ error: 'Invalid barcode' })
            })
          ])
        })
      );
    });
  });

  describe('Without itemId (no persistence)', () => {
    it('should process without fetching or saving history', async () => {
      const mockCatalogItem = { name: 'No Persist', category: 'other', confidence: 'low' };

      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockCatalogItem),
        usageMetadata: { totalTokenCount: 30 }
      });

      const result = await processItemWithGeminiPersistent(
        'https://example.com/image.jpg'
        // No itemId provided
      );

      expect(result).toEqual(mockCatalogItem);
      expect(mockGetRecentCatalogHistory).not.toHaveBeenCalled();
      expect(mockSaveCatalogHistory).not.toHaveBeenCalled();
    });
  });

  describe('Error handling', () => {
    it('should throw when Gemini returns no text', async () => {
      mockGenerateContent.mockResolvedValueOnce({
        text: null,
        usageMetadata: { totalTokenCount: 10 }
      });

      await expect(
        processItemWithGeminiPersistent('https://example.com/image.jpg', 'item-err')
      ).rejects.toThrow('No text response from Gemini');

      // History should not be saved on error
      expect(mockSaveCatalogHistory).not.toHaveBeenCalled();
    });

    it('should propagate Gemini API errors', async () => {
      mockGenerateContent.mockRejectedValueOnce(new Error('Gemini API error'));

      await expect(
        processItemWithGeminiPersistent('https://example.com/image.jpg', 'item-api-err')
      ).rejects.toThrow('Gemini API error');
    });
  });
});
