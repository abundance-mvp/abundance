import { getVertexAIConfig, createVertexAIClient } from '../vertexai-config';

describe('Vertex AI Configuration', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('getVertexAIConfig', () => {
    it('should return config with project and location from env vars', () => {
      process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
      process.env.GOOGLE_CLOUD_LOCATION = 'us-central1';

      const config = getVertexAIConfig();

      expect(config).toEqual({
        vertexai: true,
        project: 'test-project',
        location: 'us-central1'
      });
    });

    it('should default location to global when not set', () => {
      process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
      delete process.env.GOOGLE_CLOUD_LOCATION;

      const config = getVertexAIConfig();

      expect(config.location).toBe('global');
    });

    it('should throw error when project is not set', () => {
      delete process.env.GOOGLE_CLOUD_PROJECT;

      expect(() => getVertexAIConfig()).toThrow(
        'Could not determine GCP project ID. Set GOOGLE_CLOUD_PROJECT or ensure Firebase Admin is initialized.'
      );
    });
  });

  describe('createVertexAIClient', () => {
    it('should create GoogleGenAI client with Vertex AI config', () => {
      process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
      process.env.GOOGLE_CLOUD_LOCATION = 'global';

      const client = createVertexAIClient();

      expect(client).toBeDefined();
    });
  });
});
