import { onLayer2aComplete } from '../onLayer2aComplete';
import { onLayer2bComplete } from '../onLayer2bComplete';

describe('Firestore Triggers - Error Scenarios', () => {
  describe('onLayer2aComplete', () => {
    it('should update status to failed_layer2b when Layer 2b throws error', async () => {
      // Mock Firestore document
      const mockRef = {
        update: jest.fn().mockResolvedValue(undefined),
      };

      const mockEvent = {
        params: { itemId: 'test-item-123' },
        data: {
          before: {
            data: () => ({ status: 'pending' }),
          },
          after: {
            data: () => ({
              status: 'layer2a_complete',
              imageUrl: 'https://example.com/image.jpg',
              barcodeData: null,
              layer2a: {
                category: 'electronics',
                color: 'black',
                condition: 'good',
                confidence: 0.9,
              },
            }),
            ref: mockRef,
          },
        },
      };

      // Mock identifyProduct to throw error
      jest.mock('../ai-pipeline/layer2b/identifyProduct', () => ({
        identifyProduct: jest.fn().mockRejectedValue(new Error('SerpAPI timeout')),
      }));

      await onLayer2aComplete(mockEvent as any);

      expect(mockRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed_layer2b',
          error: expect.objectContaining({
            message: 'SerpAPI timeout',
          }),
        })
      );
    });
  });

  describe('onLayer2bComplete', () => {
    it('should update status to failed_layer3 when synthesis throws error', async () => {
      const mockRef = {
        update: jest.fn().mockResolvedValue(undefined),
      };

      const mockEvent = {
        params: { itemId: 'test-item-456' },
        data: {
          before: {
            data: () => ({ status: 'layer2a_complete' }),
          },
          after: {
            data: () => ({
              status: 'layer2b_complete',
              detectedLabel: 'phone',
              layer2a: {
                category: 'electronics',
                color: 'black',
                condition: 'good',
                confidence: 0.9,
              },
              layer2b: {
                source: 'barcode',
                product: {
                  brand: 'Apple',
                  name: 'iPhone 14',
                },
              },
            }),
            ref: mockRef,
          },
        },
      };

      // Mock synthesizeMetadata to throw error
      jest.mock('../ai-pipeline/layer3/synthesize', () => ({
        synthesizeMetadata: jest.fn().mockRejectedValue(new Error('Claude API error')),
      }));

      await onLayer2bComplete(mockEvent as any);

      expect(mockRef.update).toHaveBeenCalledWith(
        expect.objectContaining({
          status: 'failed_layer3',
          error: expect.objectContaining({
            message: 'Claude API error',
          }),
        })
      );
    });
  });
});
