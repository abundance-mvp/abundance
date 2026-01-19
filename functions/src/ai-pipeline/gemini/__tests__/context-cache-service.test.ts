import {
  getOrCreateContextCache,
  listContextCaches,
  deleteContextCache,
  estimateTokenSavings,
  clearCacheReference
} from '../context-cache-service';
import { createVertexAIClient } from '../vertexai-config';

jest.mock('../vertexai-config');

const mockCreateVertexAIClient = createVertexAIClient as jest.MockedFunction<typeof createVertexAIClient>;

describe('context-cache-service', () => {
  let mockCachesCreate: jest.Mock;
  let mockCachesList: jest.Mock;
  let mockCachesDelete: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    clearCacheReference();
    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    process.env.GOOGLE_CLOUD_LOCATION = 'global';

    // Setup mock Vertex AI client
    mockCachesCreate = jest.fn();
    mockCachesList = jest.fn();
    mockCachesDelete = jest.fn();

    mockCreateVertexAIClient.mockReturnValue({
      caches: {
        create: mockCachesCreate,
        list: mockCachesList,
        delete: mockCachesDelete
      }
    } as any);
  });

  afterEach(() => {
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_LOCATION;
  });

  describe('getOrCreateContextCache', () => {
    it('should create a new cache when none exists', async () => {
      const mockCache = {
        name: 'projects/test-project/locations/global/cachedContents/cache-123',
        displayName: 'abundance-catalog-context',
        model: 'gemini-3-pro'
      };
      mockCachesCreate.mockResolvedValue(mockCache);

      const result = await getOrCreateContextCache();

      expect(result).toEqual(mockCache);
      expect(mockCachesCreate).toHaveBeenCalledTimes(1);
      expect(mockCachesCreate).toHaveBeenCalledWith(
        expect.objectContaining({
          model: expect.any(String),
          config: expect.objectContaining({
            systemInstruction: expect.any(String),
            tools: expect.any(Array),
            ttl: '3600s',
            displayName: 'abundance-catalog-context'
          })
        })
      );
    });

    it('should reuse existing cache when still valid', async () => {
      const mockCache = {
        name: 'projects/test-project/locations/global/cachedContents/cache-123',
        displayName: 'abundance-catalog-context'
      };
      mockCachesCreate.mockResolvedValue(mockCache);

      // First call creates cache
      const result1 = await getOrCreateContextCache();
      expect(mockCachesCreate).toHaveBeenCalledTimes(1);

      // Second call should reuse cache
      const result2 = await getOrCreateContextCache();
      expect(mockCachesCreate).toHaveBeenCalledTimes(1);
      expect(result2).toEqual(result1);
    });

    it('should create new cache when existing cache has expired', async () => {
      const mockCache1 = { name: 'cache-1', displayName: 'abundance-catalog-context' };
      const mockCache2 = { name: 'cache-2', displayName: 'abundance-catalog-context' };
      mockCachesCreate
        .mockResolvedValueOnce(mockCache1)
        .mockResolvedValueOnce(mockCache2);

      // First call creates cache
      await getOrCreateContextCache();
      expect(mockCachesCreate).toHaveBeenCalledTimes(1);

      // Simulate cache expiry by clearing reference
      clearCacheReference();

      // Third call should create new cache
      const result = await getOrCreateContextCache();
      expect(mockCachesCreate).toHaveBeenCalledTimes(2);
      expect(result).toEqual(mockCache2);
    });

    it('should throw when Vertex AI fails', async () => {
      const error = new Error('Vertex AI unavailable');
      mockCachesCreate.mockRejectedValue(error);

      await expect(getOrCreateContextCache()).rejects.toThrow('Vertex AI unavailable');
    });
  });

  describe('listContextCaches', () => {
    it('should return all cached contents', async () => {
      const mockCaches = [
        { name: 'cache-1', displayName: 'test-1' },
        { name: 'cache-2', displayName: 'test-2' }
      ];

      // Mock async iterator
      mockCachesList.mockResolvedValue({
        [Symbol.asyncIterator]: async function* () {
          for (const cache of mockCaches) {
            yield cache;
          }
        }
      });

      const result = await listContextCaches();

      expect(result).toHaveLength(2);
      expect(result[0]).toEqual(mockCaches[0]);
      expect(result[1]).toEqual(mockCaches[1]);
    });

    it('should return empty array when no caches exist', async () => {
      mockCachesList.mockResolvedValue({
        [Symbol.asyncIterator]: async function* () {
          // Empty iterator
        }
      });

      const result = await listContextCaches();

      expect(result).toHaveLength(0);
    });
  });

  describe('deleteContextCache', () => {
    it('should delete cache by name', async () => {
      mockCachesDelete.mockResolvedValue(undefined);

      await deleteContextCache('cache-to-delete');

      expect(mockCachesDelete).toHaveBeenCalledWith({ name: 'cache-to-delete' });
    });

    it('should clear local reference if deleted cache matches current', async () => {
      const mockCache = { name: 'cache-123', displayName: 'test' };
      mockCachesCreate.mockResolvedValue(mockCache);
      mockCachesDelete.mockResolvedValue(undefined);

      // Create a cache first
      await getOrCreateContextCache();

      // Delete the same cache
      await deleteContextCache('cache-123');

      // Next call should create a new cache
      mockCachesCreate.mockResolvedValue({ name: 'cache-456', displayName: 'test' });
      const result = await getOrCreateContextCache();

      expect(result.name).toBe('cache-456');
      expect(mockCachesCreate).toHaveBeenCalledTimes(2);
    });
  });

  describe('estimateTokenSavings', () => {
    it('should return estimated token savings', () => {
      const savings = estimateTokenSavings();

      expect(savings.systemTokens).toBe(2300);
      expect(savings.savingsPercent).toBe(90);
    });
  });

  describe('clearCacheReference', () => {
    it('should clear the in-memory cache reference', () => {
      expect(() => clearCacheReference()).not.toThrow();
    });

    it('should force new cache creation on next call', async () => {
      const mockCache1 = { name: 'cache-1', displayName: 'test' };
      const mockCache2 = { name: 'cache-2', displayName: 'test' };
      mockCachesCreate
        .mockResolvedValueOnce(mockCache1)
        .mockResolvedValueOnce(mockCache2);

      await getOrCreateContextCache();
      clearCacheReference();
      const result = await getOrCreateContextCache();

      expect(result.name).toBe('cache-2');
      expect(mockCachesCreate).toHaveBeenCalledTimes(2);
    });
  });
});
