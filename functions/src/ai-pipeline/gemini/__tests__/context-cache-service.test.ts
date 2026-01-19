import {
  estimateTokenSavings,
  clearCacheReference
} from '../context-cache-service';

jest.mock('@google/genai');
jest.mock('../vertexai-config');

describe('context-cache-service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    clearCacheReference();
    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    process.env.GOOGLE_CLOUD_LOCATION = 'global';
  });

  afterEach(() => {
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_LOCATION;
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
      // Just verify the function can be called without error
      expect(() => clearCacheReference()).not.toThrow();
    });
  });
});
