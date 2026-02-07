import { handleItemCreated } from '../orchestrator';

// Mock dependencies
jest.mock('../gemini-service');

const mockFirestoreInstance = {
  collection: jest.fn(() => ({
    add: jest.fn()
  }))
};

jest.mock('firebase-admin', () => ({
  firestore: Object.assign(
    jest.fn(() => mockFirestoreInstance),
    {
      FieldValue: {
        serverTimestamp: () => ({ _serverTimestamp: true })
      }
    }
  ),
  storage: jest.fn(() => ({
    bucket: jest.fn(() => ({
      file: jest.fn(() => ({
        getSignedUrl: jest.fn().mockResolvedValue(['https://signed-url.com/image.jpg'])
      }))
    }))
  }))
}));

import { processItemWithGeminiPersistent } from '../gemini-service';

describe('Orchestrator', () => {
  const mockProcessItem = processItemWithGeminiPersistent as jest.MockedFunction<typeof processItemWithGeminiPersistent>;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should process item and return catalog result', async () => {
    mockProcessItem.mockResolvedValueOnce({
      name: 'Test Product',
      category: 'electronics',
      subCategory: 'gadgets',
      brand: 'TestBrand',
      model: 'Model-1',
      color: 'black',
      condition: 'good',
      dimensions: null,
      quantity: 1,
      estimatedValue: 50.00,
      confidence: 'high',
      processingNotes: null
    });

    const mockUpdate = jest.fn().mockResolvedValue({});
    const mockSnapshot = {
      data: () => ({
        userId: 'user123',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/items/item123.jpg',
        status: 'pending'
      }),
      ref: {
        update: mockUpdate
      }
    };

    const mockContext = {
      params: { itemId: 'item123' }
    };

    await handleItemCreated(mockSnapshot as any, mockContext as any);

    expect(mockProcessItem).toHaveBeenCalled();
    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'complete',
        catalog: expect.objectContaining({
          name: 'Test Product',
          confidence: 'high'
        })
      })
    );
  });

  it('should handle processing errors gracefully', async () => {
    mockProcessItem.mockRejectedValueOnce(new Error('API Error'));

    const mockUpdate = jest.fn().mockResolvedValue({});
    const mockSnapshot = {
      data: () => ({
        userId: 'user123',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/items/item123.jpg',
        status: 'pending'
      }),
      ref: {
        update: mockUpdate
      }
    };

    const mockContext = {
      params: { itemId: 'item123' }
    };

    await handleItemCreated(mockSnapshot as any, mockContext as any);

    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'failed',
        error: 'API Error'
      })
    );
  });

  it('should skip non-pending items', async () => {
    const mockSnapshot = {
      data: () => ({
        status: 'complete' // Already processed
      }),
      ref: {
        update: jest.fn()
      }
    };

    const mockContext = {
      params: { itemId: 'item123' }
    };

    await handleItemCreated(mockSnapshot as any, mockContext as any);

    expect(mockProcessItem).not.toHaveBeenCalled();
  });

  it('should skip items with no data', async () => {
    const mockSnapshot = {
      data: () => undefined,
      ref: {
        update: jest.fn()
      }
    };

    const mockContext = {
      params: { itemId: 'item123' }
    };

    await handleItemCreated(mockSnapshot as any, mockContext as any);

    expect(mockProcessItem).not.toHaveBeenCalled();
  });

  it('should handle array result for multi-object images', async () => {
    mockProcessItem.mockResolvedValueOnce([
      {
        name: 'Product 1',
        category: 'electronics',
        subCategory: 'gadgets',
        brand: null,
        model: null,
        color: 'black',
        condition: 'good',
        dimensions: null,
        quantity: 1,
        estimatedValue: 25.00,
        confidence: 'medium',
        processingNotes: null
      },
      {
        name: 'Product 2',
        category: 'electronics',
        subCategory: 'cables',
        brand: null,
        model: null,
        color: 'white',
        condition: 'good',
        dimensions: null,
        quantity: 1,
        estimatedValue: 10.00,
        confidence: 'medium',
        processingNotes: null
      }
    ]);

    const mockUpdate = jest.fn().mockResolvedValue({});
    const mockSnapshot = {
      data: () => ({
        userId: 'user123',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/bucket/items/item123.jpg',
        status: 'pending'
      }),
      ref: {
        update: mockUpdate
      }
    };

    const mockContext = {
      params: { itemId: 'item123' }
    };

    await handleItemCreated(mockSnapshot as any, mockContext as any);

    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'complete',
        catalog: expect.arrayContaining([
          expect.objectContaining({ name: 'Product 1' }),
          expect.objectContaining({ name: 'Product 2' })
        ])
      })
    );
  });

  it('should fall back to imagePath when imageUrl is not present', async () => {
    mockProcessItem.mockResolvedValueOnce({
      name: 'Legacy Product',
      category: 'electronics',
      subCategory: 'gadgets',
      brand: null,
      model: null,
      color: 'black',
      condition: 'good',
      dimensions: null,
      quantity: 1,
      estimatedValue: 30.00,
      confidence: 'medium',
      processingNotes: null
    });

    const mockUpdate = jest.fn().mockResolvedValue({});
    const mockSnapshot = {
      data: () => ({
        userId: 'user123',
        imagePath: 'users/user123/items/item123.jpg',
        status: 'pending'
      }),
      ref: {
        update: mockUpdate
      }
    };

    const mockContext = {
      params: { itemId: 'item123' }
    };

    await handleItemCreated(mockSnapshot as any, mockContext as any);

    expect(mockProcessItem).toHaveBeenCalled();
    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'complete',
        name: 'Legacy Product'
      })
    );
  });

  it('should fail when neither imageUrl nor imagePath is present', async () => {
    const mockUpdate = jest.fn().mockResolvedValue({});
    const mockSnapshot = {
      data: () => ({
        userId: 'user123',
        status: 'pending'
      }),
      ref: {
        update: mockUpdate
      }
    };

    const mockContext = {
      params: { itemId: 'item123' }
    };

    await handleItemCreated(mockSnapshot as any, mockContext as any);

    expect(mockUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'failed',
        error: expect.stringContaining('neither imageUrl nor imagePath')
      })
    );
  });
});
