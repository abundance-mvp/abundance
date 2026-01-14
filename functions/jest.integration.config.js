/**
 * Jest configuration for integration tests.
 *
 * Integration tests use real Firebase Storage and external APIs.
 * They require:
 * - GOOGLE_CLOUD_PROJECT (for Vertex AI)
 * - SERPAPI_KEY
 * - FIREBASE_PROJECT_ID
 * - GOOGLE_APPLICATION_CREDENTIALS (for local development)
 *
 * Run: npm run test:integration
 *
 * Note: Integration tests are skipped in CI by default.
 * Set RUN_INTEGRATION_TESTS=true to run them in CI.
 */

/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.integration.test.ts'],
  testTimeout: 60000, // 60 seconds for API calls
  verbose: true,
  // Don't run integration tests in CI by default
  testPathIgnorePatterns: process.env.CI && !process.env.RUN_INTEGRATION_TESTS ? ['.*'] : [],
  // Load environment variables from .env.integration if it exists
  setupFiles: ['dotenv/config'],
  globals: {
    'ts-jest': {
      tsconfig: 'tsconfig.json',
    },
  },
};
