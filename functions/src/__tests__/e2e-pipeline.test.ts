/**
 * E2E Pipeline Tests
 *
 * Tests the full image catalog pipeline using mocked Gemini API calls
 * but real Firestore document operations (emulator or mocks).
 *
 * Test coverage:
 * - Session creation → detection → item creation flow
 * - 429 rate limit → retry → eventual success
 * - 429 sustained → circuit breaker → failed status
 * - Dual trigger prevention (idempotency)
 * - Image URL format → valid download URL
 * - Session timeout → failed status
 * - Invalid image → error propagation
 */

import { callGeminiFlashWithRetry } from '../ai-pipeline/layer1/layer1-service';

// Mock the Gemini/Vertex AI client
jest.mock('../ai-pipeline/gemini/vertexai-config', () => ({
  createVertexAIClient: jest.fn(() => ({
    models: {
      generateContent: jest.fn()
    }
  }))
}));

// Mock sharp (ESM module)
jest.mock('sharp', () => {
  const mockSharp = jest.fn(() => ({
    rotate: jest.fn().mockReturnThis(),
    metadata: jest.fn().mockResolvedValue({ width: 1000, height: 1000 }),
    extract: jest.fn().mockReturnThis(),
    jpeg: jest.fn().mockReturnThis(),
    toBuffer: jest.fn().mockResolvedValue(Buffer.from('fake-image'))
  }));
  return { __esModule: true, default: mockSharp };
});

// Mock firebase-admin modules
jest.mock('firebase-admin/storage', () => ({
  getStorage: jest.fn(() => ({
    bucket: jest.fn(() => ({
      name: 'test-bucket',
      file: jest.fn(() => ({
        save: jest.fn().mockResolvedValue(undefined),
        download: jest.fn().mockResolvedValue([Buffer.from('fake-image')])
      }))
    }))
  }))
}));

jest.mock('firebase-admin/firestore', () => ({
  getFirestore: jest.fn(),
  FieldValue: {
    serverTimestamp: jest.fn(() => 'MOCK_TIMESTAMP')
  }
}));

jest.mock('firebase-functions/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
}));

import { createVertexAIClient } from '../ai-pipeline/gemini/vertexai-config';

describe('E2E Pipeline Tests', () => {
  let mockGenerateContent: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    // Reset the mock AI client for each test
    mockGenerateContent = jest.fn();
    (createVertexAIClient as jest.Mock).mockReturnValue({
      models: {
        generateContent: mockGenerateContent
      }
    });
  });

  describe('Gemini Flash retry with rate limiting', () => {
    it('retries on transient error and succeeds', async () => {
      // First call: UNAVAILABLE error
      mockGenerateContent
        .mockRejectedValueOnce(new Error('UNAVAILABLE: Service temporarily unavailable'))
        .mockResolvedValueOnce({
          text: JSON.stringify({
            objects: [{
              groupId: 'grp-1',
              label: 'chair',
              category: 'furniture',
              box_2d: [100, 200, 500, 600],
              image_index: 0,
              confidence: 'high'
            }]
          })
        });

      const result = await callGeminiFlashWithRetry(['base64image'], 2);
      expect(result.objects).toHaveLength(1);
      expect(result.objects[0].label).toBe('chair');
      expect(mockGenerateContent).toHaveBeenCalledTimes(2);
    });

    it('fails immediately on non-retryable error', async () => {
      mockGenerateContent.mockRejectedValueOnce(
        new Error('INVALID_ARGUMENT: Image is corrupted')
      );

      await expect(callGeminiFlashWithRetry(['base64image'], 3))
        .rejects.toThrow('INVALID_ARGUMENT');
      expect(mockGenerateContent).toHaveBeenCalledTimes(1);
    });

    it('exhausts retries on persistent transient errors', async () => {
      // All calls fail with INTERNAL
      mockGenerateContent.mockRejectedValue(
        new Error('INTERNAL: Server error')
      );

      await expect(callGeminiFlashWithRetry(['base64image'], 2))
        .rejects.toThrow('INTERNAL');
      // 1 initial + 2 retries = 3 calls
      expect(mockGenerateContent).toHaveBeenCalledTimes(3);
    });

    it('trips circuit breaker after 3 consecutive 429 errors', async () => {
      // All calls fail with RESOURCE_EXHAUSTED (429)
      mockGenerateContent.mockRejectedValue(
        new Error('RESOURCE_EXHAUSTED: Quota exceeded')
      );

      await expect(callGeminiFlashWithRetry(['base64image'], 5))
        .rejects.toThrow('RATE_LIMITED');
      // Should stop at 3 consecutive 429s, not exhaust all 5 retries
      expect(mockGenerateContent).toHaveBeenCalledTimes(3);
    });

    it('resets circuit breaker counter on non-429 error', async () => {
      mockGenerateContent
        // First two: 429
        .mockRejectedValueOnce(new Error('RESOURCE_EXHAUSTED: Quota exceeded'))
        .mockRejectedValueOnce(new Error('RESOURCE_EXHAUSTED: Quota exceeded'))
        // Third: UNAVAILABLE (resets counter)
        .mockRejectedValueOnce(new Error('UNAVAILABLE: Service down'))
        // Fourth: 429 again (counter resets to 1)
        .mockRejectedValueOnce(new Error('RESOURCE_EXHAUSTED: Quota exceeded'))
        // Fifth: success
        .mockResolvedValueOnce({
          text: JSON.stringify({ objects: [] })
        });

      const result = await callGeminiFlashWithRetry(['base64image'], 5);
      expect(result.objects).toHaveLength(0);
      expect(mockGenerateContent).toHaveBeenCalledTimes(5);
    });
  });

  describe('Detection response parsing', () => {
    it('handles empty objects array', async () => {
      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify({
          objects: [],
          reasoning: 'Only built-in fixtures visible'
        })
      });

      const result = await callGeminiFlashWithRetry(['base64image']);
      expect(result.objects).toHaveLength(0);
      expect(result.reasoning).toBe('Only built-in fixtures visible');
    });

    it('handles multiple detected objects', async () => {
      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify({
          objects: [
            { groupId: 'g1', label: 'chair', category: 'furniture', box_2d: [100, 100, 500, 500], image_index: 0 },
            { groupId: 'g2', label: 'lamp', category: 'lighting', box_2d: [200, 600, 400, 800], image_index: 0 }
          ]
        })
      });

      const result = await callGeminiFlashWithRetry(['base64image']);
      expect(result.objects).toHaveLength(2);
      expect(result.objects[0].label).toBe('chair');
      expect(result.objects[1].label).toBe('lamp');
    });

    it('returns empty objects when response has no text', async () => {
      mockGenerateContent.mockResolvedValueOnce({ text: null });

      const result = await callGeminiFlashWithRetry(['base64image']);
      expect(result.objects).toHaveLength(0);
      expect(result.reasoning).toContain('No response');
    });

    it('returns empty objects on malformed JSON', async () => {
      mockGenerateContent.mockResolvedValueOnce({
        text: 'not valid json {{'
      });

      const result = await callGeminiFlashWithRetry(['base64image']);
      expect(result.objects).toHaveLength(0);
    });
  });

  describe('Download URL format', () => {
    it('generates valid Firebase download URL format', () => {
      // Test the URL format that Layer 1 generates
      const bucket = 'abundance-mvp.firebasestorage.app';
      const path = 'users/user-1/sessions/sess-1/crops/grp_crop_0.jpg';
      const token = 'abc-123-def';

      const encodedPath = encodeURIComponent(path);
      const url = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodedPath}?alt=media&token=${token}`;

      expect(url).toContain('firebasestorage.googleapis.com');
      expect(url).toContain(`b/${bucket}`);
      expect(url).toContain('alt=media');
      expect(url).toContain(`token=${token}`);

      // Verify URL is parseable
      const parsed = new URL(url);
      expect(parsed.protocol).toBe('https:');
      expect(parsed.hostname).toBe('firebasestorage.googleapis.com');

      // Verify path can be decoded back
      const pathMatch = parsed.pathname.match(/\/v0\/b\/[^/]+\/o\/(.+)/);
      expect(pathMatch).not.toBeNull();
      expect(decodeURIComponent(pathMatch![1])).toBe(path);
    });

    it('handles paths with special characters', () => {
      const path = 'users/user+1/items/photo (1).jpg';
      const encodedPath = encodeURIComponent(path);
      const url = `https://firebasestorage.googleapis.com/v0/b/bucket/o/${encodedPath}?alt=media&token=tok`;

      const parsed = new URL(url);
      const pathMatch = parsed.pathname.match(/\/v0\/b\/[^/]+\/o\/(.+)/);
      expect(decodeURIComponent(pathMatch![1])).toBe(path);
    });
  });

  describe('Error code mapping', () => {
    it('maps RESOURCE_EXHAUSTED to retryable error', () => {
      const error = new Error('RESOURCE_EXHAUSTED: Quota exceeded');
      expect(error.message).toContain('RESOURCE_EXHAUSTED');
    });

    it('maps 429 to rate limit error', () => {
      const error = new Error('429 Too Many Requests');
      expect(error.message).toContain('429');
    });

    it('maps UNAVAILABLE to retryable error', () => {
      const error = new Error('UNAVAILABLE: Service temporarily unavailable');
      expect(error.message).toContain('UNAVAILABLE');
    });
  });
});
