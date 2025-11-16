import { CostLogger } from '../CostLogger';

// Mock firebase-admin at module level
jest.mock('firebase-admin');

describe('CostLogger', () => {
  let mockAdd: jest.Mock;
  let mockFromDate: jest.Mock;

  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();

    // Setup mocks
    mockAdd = jest.fn().mockResolvedValue({ id: 'log123' });
    mockFromDate = jest.fn((date: Date) => ({
      seconds: Math.floor(date.getTime() / 1000),
      nanoseconds: 0
    }));

    // Mock firestore admin module
    const admin = require('firebase-admin');
    admin.firestore = jest.fn(() => ({
      collection: jest.fn(() => ({
        add: mockAdd
      }))
    }));
    admin.firestore.Timestamp = {
      fromDate: mockFromDate
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
});
