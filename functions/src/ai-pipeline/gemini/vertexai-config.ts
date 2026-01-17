/**
 * Vertex AI Configuration for Gemini 3 Models
 *
 * Gemini 3 Preview models require Vertex AI authentication (not API keys).
 * Cloud Functions authenticate automatically via Application Default Credentials.
 */

import { GoogleGenAI } from '@google/genai';
import { getApp } from 'firebase-admin/app';

export interface VertexAIConfig {
  vertexai: true;
  project: string;
  location: string;
}

/**
 * Get the GCP project ID from available sources.
 *
 * Priority:
 * 1. GOOGLE_CLOUD_PROJECT env var (explicit config)
 * 2. GCLOUD_PROJECT env var (Cloud Functions v1)
 * 3. Firebase Admin SDK (Cloud Functions v2 / Cloud Run)
 */
function getProjectId(): string | undefined {
  // Try environment variables first
  if (process.env.GOOGLE_CLOUD_PROJECT) {
    return process.env.GOOGLE_CLOUD_PROJECT;
  }
  if (process.env.GCLOUD_PROJECT) {
    return process.env.GCLOUD_PROJECT;
  }

  // Fallback to Firebase Admin SDK (works in Cloud Functions v2)
  try {
    const projectId = getApp().options.projectId;
    if (projectId) {
      return projectId;
    }
  } catch {
    // App not initialized yet, ignore
  }

  return undefined;
}

/**
 * Get Vertex AI configuration from environment variables.
 *
 * Project ID is obtained from:
 * - GOOGLE_CLOUD_PROJECT or GCLOUD_PROJECT env vars
 * - Firebase Admin SDK (for Cloud Functions v2)
 *
 * @throws Error if project ID cannot be determined
 */
export function getVertexAIConfig(): VertexAIConfig {
  const project = getProjectId();

  if (!project) {
    throw new Error(
      'Could not determine GCP project ID. Set GOOGLE_CLOUD_PROJECT or ensure Firebase Admin is initialized.'
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
