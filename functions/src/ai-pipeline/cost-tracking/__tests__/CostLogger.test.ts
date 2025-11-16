import { CostLogger } from '../CostLogger';

// Mock firebase-admin at module level
jest.mock('firebase-admin');

describe('CostLogger', () => {
  let mockAdd: jest.Mock;
  let mockSet: jest.Mock;
  let mockFromDate: jest.Mock;
  let mockNow: jest.Mock;

  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();

    // Setup mocks
    mockAdd = jest.fn().mockResolvedValue({ id: 'log123' });
    mockSet = jest.fn().mockResolvedValue(undefined);
    mockFromDate = jest.fn((date: Date) => ({
      seconds: Math.floor(date.getTime() / 1000),
      nanoseconds: 0
    }));
    mockNow = jest.fn(() => ({
      seconds: Math.floor(Date.now() / 1000),
      nanoseconds: 0
    }));

    // Mock firestore admin module
    const admin = require('firebase-admin');
    admin.firestore = jest.fn(() => ({
      collection: jest.fn(() => ({
        add: mockAdd,
        doc: jest.fn(() => ({
          set: mockSet
        }))
      }))
    }));
    admin.firestore.Timestamp = {
      fromDate: mockFromDate,
      now: mockNow
    };
  });

  it('should log API call cost to Firestore', async () => {
    const logger = new CostLogger();

    await logger.logCost({
      userId: 'user123',
      itemId: 'item456',
      provider: 'gemini',
      model: 'gemini-2.5-flash-lite',
      operation: 'layer2a_extraction',
      inputTokens: 258,
      outputTokens: 100,
      totalTokens: 358,
      cost: 0.00006,
      timestamp: new Date()
    });

    expect(mockAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user123',
        itemId: 'item456',
        provider: 'gemini',
        model: 'gemini-2.5-flash-lite',
        operation: 'layer2a_extraction',
        inputTokens: 258,
        outputTokens: 100,
        totalTokens: 358,
        cost: 0.00006
      })
    );
    expect(mockFromDate).toHaveBeenCalled();
  });

  it('should calculate cost correctly', () => {
    const logger = new CostLogger();

    const cost = logger.calculateCost(
      'gemini-2.5-flash-lite',
      258, // input tokens
      100  // output tokens
    );

    // Gemini 2.5 Flash-Lite: $0.10/1M input, $0.40/1M output
    // Input: 258 × 0.10/1M = 0.0000258
    // Output: 100 × 0.40/1M = 0.0000400
    // Total: 0.0000658
    expect(cost).toBeCloseTo(0.0000658, 7);
  });

  it('should log barcode API usage (OpenFoodFacts - free)', async () => {
    const logger = new CostLogger();

    await logger.logBarcodeUsage({
      api: 'openfoodfacts',
      itemId: 'test_item_123',
      barcode: '049000050103',
      cost: 0,
      found: true,
      latency: 200,
    });

    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        api: 'openfoodfacts',
        itemId: 'test_item_123',
        barcode: '049000050103',
        cost: 0,
        found: true,
        latency: 200,
      })
    );
    expect(mockNow).toHaveBeenCalled();
  });

  it('should log SerpAPI usage', async () => {
    const logger = new CostLogger();

    await logger.logSerpAPIUsage({
      itemId: 'test_item_123',
      imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
      matchCount: 5,
      latency: 2500,
      cost: 0.015,
    });

    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        itemId: 'test_item_123',
        imageUrl: 'https://storage.googleapis.com/abundance-items/test.jpg',
        matchCount: 5,
        latency: 2500,
        cost: 0.015,
      })
    );
    expect(mockNow).toHaveBeenCalled();
  });

  it('should log Claude usage (Haiku and Sonnet)', async () => {
    const logger = new CostLogger();

    await logger.logClaudeUsage({
      model: 'claude-haiku-4-5',
      itemId: 'test_item_123',
      userId: 'test_user',
      tokensUsed: { input: 500, output: 100, total: 600 },
      cost: 0.001,
      latency: 800,
    });

    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        service: 'claude-haiku-4-5',
        itemId: 'test_item_123',
        userId: 'test_user',
        tokensInput: 500,
        tokensOutput: 100,
        tokensUsed: 600,
        cost: 0.001,
      })
    );
    expect(mockNow).toHaveBeenCalled();
  });
});
