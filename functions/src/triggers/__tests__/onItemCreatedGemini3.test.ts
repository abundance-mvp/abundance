/**
 * Tests for onItemCreatedGemini3 trigger configuration
 *
 * Verifies:
 * - Secrets are properly defined (SERPAPI_KEY only - Vertex AI uses ADC)
 * - Document path is correct (items/{itemId})
 * - 2nd gen Cloud Functions configuration
 */

// Store trigger config for testing
let capturedConfig: Record<string, unknown> | null = null;

// Mock the firestore module before importing trigger
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: jest.fn((config, handler) => {
    capturedConfig = config as Record<string, unknown>;
    return { handler };
  }),
}));

// Mock defineSecret
jest.mock('firebase-functions/params', () => ({
  defineSecret: jest.fn((name: string) => ({
    name,
    value: () => `mock-${name}-value`,
  })),
}));

// Mock the handler
jest.mock('../../ai-pipeline/gemini', () => ({
  handleItemCreated: jest.fn().mockResolvedValue(undefined),
}));

describe('onItemCreatedGemini3 trigger configuration', () => {
  beforeEach(() => {
    jest.resetModules();
    capturedConfig = null;
  });

  it('should define secrets for SERPAPI_KEY only (Vertex AI uses ADC)', async () => {
    // Import trigger to capture config
    await import('../onItemCreatedGemini3');

    expect(capturedConfig).toBeDefined();
    expect(capturedConfig?.secrets).toBeDefined();
    expect(Array.isArray(capturedConfig?.secrets)).toBe(true);
    // Only SERPAPI_KEY needed - Vertex AI uses Application Default Credentials
    expect((capturedConfig?.secrets as unknown[]).length).toBe(1);
  });

  it('should listen to items/{itemId} document path', async () => {
    await import('../onItemCreatedGemini3');

    expect(capturedConfig).toBeDefined();
    expect(capturedConfig?.document).toBe('items/{itemId}');
  });

  it('should configure region as us-central1', async () => {
    await import('../onItemCreatedGemini3');

    expect(capturedConfig).toBeDefined();
    expect(capturedConfig?.region).toBe('us-central1');
  });

  it('should configure memory and timeout appropriately', async () => {
    await import('../onItemCreatedGemini3');

    expect(capturedConfig).toBeDefined();
    expect(capturedConfig?.memory).toBe('512MiB');
    expect(capturedConfig?.timeoutSeconds).toBe(120);
  });
});
