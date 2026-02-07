/**
 * Unit tests for onItemUpdatedDeepScan trigger
 *
 * Tests the deep scan processing logic when an item is updated with
 * deepScanRequested=true and status="pending".
 *
 * Verifies:
 * 1. Guard conditions prevent infinite loops
 * 2. Successful deep scan updates Firestore with extended fields
 * 3. Error handling writes status='failed' on all failure paths
 * 4. Image URL resolution (imageUrl vs imagePath fallback)
 */

// Mock firebase-admin
const mockUpdate = jest.fn();
const mockServerTimestamp = jest.fn(() => 'SERVER_TIMESTAMP');

jest.mock('firebase-admin', () => ({
  firestore: {
    FieldValue: {
      serverTimestamp: mockServerTimestamp,
    },
  },
}));

// Mock gemini-service
const mockProcessItem = jest.fn();

jest.mock('../../ai-pipeline/gemini/gemini-service', () => ({
  processItemWithGeminiPersistent: mockProcessItem,
}));

// Mock StructuredLogger
const mockLogInfo = jest.fn();
const mockLogError = jest.fn();

jest.mock('../../monitoring/logger', () => ({
  StructuredLogger: jest.fn().mockImplementation(() => ({
    info: mockLogInfo,
    error: mockLogError,
  })),
}));

// Mock defineSecret
jest.mock('firebase-functions/params', () => ({
  defineSecret: jest.fn(() => ({
    value: () => 'test-serpapi-key',
  })),
}));

// Capture the trigger handler
let capturedHandler: ((event: unknown) => Promise<void>) | null = null;

jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentUpdated: jest.fn((_config: unknown, handler: (event: unknown) => Promise<void>) => {
    capturedHandler = handler;
    return { handler };
  }),
}));

// Helper to create mock events
function createMockEvent(
  itemId: string,
  beforeData: Record<string, unknown>,
  afterData: Record<string, unknown>
) {
  return {
    params: { itemId },
    data: {
      before: { data: () => beforeData },
      after: {
        data: () => afterData,
        ref: { update: mockUpdate },
      },
    },
  };
}

describe('onItemUpdatedDeepScan trigger', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    capturedHandler = null;
  });

  describe('trigger registration', () => {
    it('should register with correct document path and config', async () => {
      const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

      await import('../onItemUpdatedDeepScan');

      expect(onDocumentUpdated).toHaveBeenCalledWith(
        expect.objectContaining({
          document: 'items/{itemId}',
          region: 'us-central1',
          memory: '1GiB',
          timeoutSeconds: 180,
        }),
        expect.any(Function)
      );
    });
  });

  describe('guard conditions', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemUpdatedDeepScan');
    });

    it('should skip when deepScanRequested is not true', async () => {
      const event = createMockEvent('item1',
        { status: 'complete', deepScanRequested: false },
        { status: 'pending', deepScanRequested: false }
      );

      await capturedHandler!(event);

      expect(mockProcessItem).not.toHaveBeenCalled();
      expect(mockUpdate).not.toHaveBeenCalled();
    });

    it('should skip when after.status is not pending', async () => {
      const event = createMockEvent('item2',
        { status: 'complete', deepScanRequested: false },
        { status: 'complete', deepScanRequested: true }
      );

      await capturedHandler!(event);

      expect(mockProcessItem).not.toHaveBeenCalled();
      expect(mockUpdate).not.toHaveBeenCalled();
    });

    it('should skip when before.status is already pending (prevents re-trigger)', async () => {
      const event = createMockEvent('item3',
        { status: 'pending', deepScanRequested: true },
        { status: 'pending', deepScanRequested: true }
      );

      await capturedHandler!(event);

      expect(mockProcessItem).not.toHaveBeenCalled();
      expect(mockUpdate).not.toHaveBeenCalled();
    });

    it('should skip when event data is missing', async () => {
      const event = {
        params: { itemId: 'item4' },
        data: null,
      };

      await capturedHandler!(event);

      expect(mockProcessItem).not.toHaveBeenCalled();
    });
  });

  describe('successful deep scan', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemUpdatedDeepScan');
    });

    it('should process item and update Firestore with deep scan fields', async () => {
      mockProcessItem.mockResolvedValueOnce({
        name: 'Updated Product Name',
        productUrl: 'https://example.com/product',
        upcCode: '012345678901',
        marketPriceRange: '$50-$80',
        originalRetailPrice: 99.99,
        dimensions: '10x5x3 inches',
        estimatedValue: 65.0,
      });

      const event = createMockEvent('item5',
        { status: 'complete', deepScanRequested: false },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://storage.example.com/image.jpg',
          userId: 'user123',
          name: 'Original Name',
        }
      );

      await capturedHandler!(event);

      expect(mockProcessItem).toHaveBeenCalledWith(
        'https://storage.example.com/image.jpg',
        'item5',
        true,
        undefined
      );

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'complete',
          productUrl: 'https://example.com/product',
          upcCode: '012345678901',
          marketPriceRange: '$50-$80',
          originalRetailPrice: 99.99,
          name: 'Updated Product Name',
          dimensions: '10x5x3 inches',
          estimatedValue: 65.0,
        })
      );
    });

    it('should handle array result from Gemini', async () => {
      mockProcessItem.mockResolvedValueOnce([
        {
          productUrl: 'https://example.com/product',
          upcCode: null,
          marketPriceRange: '$30-$50',
          originalRetailPrice: null,
        },
      ]);

      const event = createMockEvent('item6',
        { status: 'complete', deepScanRequested: false },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://storage.example.com/image.jpg',
          userId: 'user123',
        }
      );

      await capturedHandler!(event);

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'complete',
          productUrl: 'https://example.com/product',
          upcCode: null,
          marketPriceRange: '$30-$50',
          originalRetailPrice: null,
        })
      );
    });

    it('should pass additionalImageUrls to Gemini when present', async () => {
      mockProcessItem.mockResolvedValueOnce({
        name: 'Multi-Photo Product',
        productUrl: null,
        upcCode: null,
        marketPriceRange: '$40-$60',
        originalRetailPrice: null,
      });

      const event = createMockEvent('item5b',
        { status: 'complete', deepScanRequested: false },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://storage.example.com/primary.jpg',
          additionalImageUrls: [
            'https://storage.example.com/angle2.jpg',
            'https://storage.example.com/angle3.jpg',
          ],
          userId: 'user123',
          name: 'Original Name',
        }
      );

      await capturedHandler!(event);

      expect(mockProcessItem).toHaveBeenCalledWith(
        'https://storage.example.com/primary.jpg',
        'item5b',
        true,
        ['https://storage.example.com/angle2.jpg', 'https://storage.example.com/angle3.jpg']
      );

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'complete',
          name: 'Multi-Photo Product',
        })
      );
    });

    it('should not overwrite standard fields when Gemini returns falsy values', async () => {
      mockProcessItem.mockResolvedValueOnce({
        name: undefined,
        dimensions: undefined,
        estimatedValue: undefined,
        productUrl: 'https://example.com',
        upcCode: null,
        marketPriceRange: null,
        originalRetailPrice: null,
      });

      const event = createMockEvent('item7',
        { status: 'complete' },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://storage.example.com/image.jpg',
          userId: 'user123',
          name: 'Keep This Name',
        }
      );

      await capturedHandler!(event);

      // name/dimensions/estimatedValue should NOT be in update when falsy
      const updateArg = mockUpdate.mock.calls[0][0];
      expect(updateArg.name).toBeUndefined();
      expect(updateArg.dimensions).toBeUndefined();
      expect(updateArg.estimatedValue).toBeUndefined();
      expect(updateArg.productUrl).toBe('https://example.com');
    });
  });

  describe('image URL resolution', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemUpdatedDeepScan');
    });

    it('should prefer imageUrl over imagePath', async () => {
      mockProcessItem.mockResolvedValueOnce({
        productUrl: null,
        upcCode: null,
        marketPriceRange: null,
        originalRetailPrice: null,
      });

      const event = createMockEvent('item8',
        { status: 'complete' },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://preferred-url.com/image.jpg',
          imagePath: 'users/u1/items/item8.jpg',
          userId: 'user123',
        }
      );

      await capturedHandler!(event);

      expect(mockProcessItem).toHaveBeenCalledWith(
        'https://preferred-url.com/image.jpg',
        'item8',
        true,
        undefined
      );
    });

    it('should fall back to imagePath when imageUrl is missing', async () => {
      mockProcessItem.mockResolvedValueOnce({
        productUrl: null,
        upcCode: null,
        marketPriceRange: null,
        originalRetailPrice: null,
      });

      const event = createMockEvent('item9',
        { status: 'complete' },
        {
          status: 'pending',
          deepScanRequested: true,
          imagePath: 'users/u1/items/item9.jpg',
          userId: 'user123',
        }
      );

      await capturedHandler!(event);

      expect(mockProcessItem).toHaveBeenCalledWith(
        'users/u1/items/item9.jpg',
        'item9',
        true,
        undefined
      );
    });

    it('should fail when neither imageUrl nor imagePath exists', async () => {
      const event = createMockEvent('item10',
        { status: 'complete' },
        {
          status: 'pending',
          deepScanRequested: true,
          userId: 'user123',
        }
      );

      await capturedHandler!(event);

      // Should write failed status
      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed',
          deepScanRequested: false,
        })
      );
      expect(mockProcessItem).not.toHaveBeenCalled();
    });
  });

  describe('error handling', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemUpdatedDeepScan');
    });

    it('should write failed status when Gemini processing fails', async () => {
      mockProcessItem.mockRejectedValueOnce(new Error('Gemini API timeout'));

      const event = createMockEvent('item11',
        { status: 'complete' },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://storage.example.com/image.jpg',
          userId: 'user123',
        }
      );

      await capturedHandler!(event);

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed',
          deepScanRequested: false,
          error: 'Deep scan failed: Gemini API timeout',
        })
      );
    });

    it('should handle non-Error thrown values', async () => {
      mockProcessItem.mockRejectedValueOnce('string error');

      const event = createMockEvent('item12',
        { status: 'complete' },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://storage.example.com/image.jpg',
          userId: 'user123',
        }
      );

      await capturedHandler!(event);

      expect(mockUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed',
          deepScanRequested: false,
          error: 'Deep scan failed: Unknown error',
        })
      );
    });

    it('should log the error via StructuredLogger', async () => {
      const testError = new Error('Processing failed');
      mockProcessItem.mockRejectedValueOnce(testError);

      const event = createMockEvent('item13',
        { status: 'complete' },
        {
          status: 'pending',
          deepScanRequested: true,
          imageUrl: 'https://storage.example.com/image.jpg',
          userId: 'user123',
        }
      );

      await capturedHandler!(event);

      expect(mockLogError).toHaveBeenCalledWith(
        'Deep scan failed',
        testError,
        expect.objectContaining({ itemId: 'item13' })
      );
    });
  });
});
