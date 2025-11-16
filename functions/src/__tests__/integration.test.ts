import { extractAttributesLayer2a } from '../ai-pipeline/layer2a/extractAttributes';

// Mock Firebase Admin for cost logging
jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      add: jest.fn().mockResolvedValue({ id: 'log123' })
    }))
  })),
  Timestamp: {
    now: jest.fn(() => ({ toDate: () => new Date() })),
    fromDate: jest.fn((date: Date) => ({ toDate: () => date }))
  }
}));

describe('Integration: Layer 2a End-to-End', () => {
  it('should extract attributes from real image URL (skip if no API key)', async () => {
    if (!process.env.GOOGLE_API_KEY) {
      console.log('Skipping integration test: GOOGLE_API_KEY not set');
      return;
    }

    // Use a publicly accessible test image
    const testImageUrl =
      'https://storage.googleapis.com/abundance-test/backpack.jpg';

    const result = await extractAttributesLayer2a(
      'test_user',
      'test_item',
      testImageUrl
    );

    expect(result).toHaveProperty('category');
    expect(result).toHaveProperty('color');
    expect(result).toHaveProperty('condition');

    // Validate category is from enum
    const validCategories = [
      'camping',
      'electronics',
      'furniture',
      'clothing',
      'kitchenware',
      'books',
      'toys',
      'sports',
      'tools',
      'other'
    ];
    expect(validCategories).toContain(result.category);

    // Validate condition is from enum
    const validConditions = ['new', 'like-new', 'good', 'fair', 'poor'];
    expect(validConditions).toContain(result.condition);

    console.log('Integration test result:', result);
  }, 30000); // 30 second timeout
});
