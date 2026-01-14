/**
 * Vertex AI Configuration for Gemini 3 Models
 *
 * Gemini 3 Preview models require Vertex AI authentication (not API keys).
 * Cloud Functions authenticate automatically via Application Default Credentials.
 */

import { GoogleGenAI } from '@google/genai';

export interface VertexAIConfig {
  vertexai: true;
  project: string;
  location: string;
}

/**
 * Get Vertex AI configuration from environment variables.
 *
 * Required env vars:
 * - GOOGLE_CLOUD_PROJECT: GCP project ID
 * - GOOGLE_CLOUD_LOCATION: Region (defaults to 'global' for Gemini 3)
 *
 * @throws Error if GOOGLE_CLOUD_PROJECT is not set
 */
export function getVertexAIConfig(): VertexAIConfig {
  const project = process.env.GOOGLE_CLOUD_PROJECT;

  if (!project) {
    throw new Error(
      'GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI'
    );
  }

  // Default to 'global' for Gemini 3 models per Google's recommendation
  const location = process.env.GOOGLE_CLOUD_LOCATION || 'global';

  return {
    vertexai: true,
    project,
    location
  };
}

/**
 * Create a GoogleGenAI client configured for Vertex AI.
 *
 * Authentication is automatic in Cloud Functions via service account.
 * For local development, use: gcloud auth application-default login
 */
export function createVertexAIClient(): GoogleGenAI {
  const config = getVertexAIConfig();
  return new GoogleGenAI(config);
}
