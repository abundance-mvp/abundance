import {
  formatHistoryForPrompt,
  catalogItemToSnapshot
} from '../catalog-history-service';
import { CatalogHistoryEntry } from '../schemas/catalog-history';
import { CatalogItem } from '../schemas/catalog-item';

describe('catalog-history-service', () => {
  describe('catalogItemToSnapshot', () => {
    it('should convert CatalogItem to snapshot', () => {
      const item: CatalogItem = {
        name: 'Apple iPhone 15 Pro',
        brand: 'Apple',
        model: 'iPhone 15 Pro',
        category: 'electronics',
        subCategory: 'smartphones',
        color: 'black',
        confidence: 'high',
        estimatedValue: 999,
        condition: 'like-new',
        dimensions: null,
        quantity: 1,
        processingNotes: null
      };

      const snapshot = catalogItemToSnapshot(item);

      expect(snapshot.name).toBe('Apple iPhone 15 Pro');
      expect(snapshot.brand).toBe('Apple');
      expect(snapshot.model).toBe('iPhone 15 Pro');
      expect(snapshot.category).toBe('electronics');
      expect(snapshot.subCategory).toBe('smartphones');
      expect(snapshot.confidence).toBe('high');
      expect(snapshot.estimatedValue).toBe(999);
      expect(snapshot.condition).toBe('like-new');
    });

    it('should handle missing optional fields', () => {
      const item: CatalogItem = {
        name: 'Unknown Item',
        category: 'other',
        subCategory: 'misc',
        color: 'unknown',
        condition: 'good',
        quantity: 1,
        confidence: 'low',
        brand: null,
        model: null,
        dimensions: null,
        estimatedValue: null,
        processingNotes: null
      };

      const snapshot = catalogItemToSnapshot(item);

      expect(snapshot.brand).toBeNull();
      expect(snapshot.model).toBeNull();
      expect(snapshot.estimatedValue).toBeNull();
      expect(snapshot.confidence).toBe('low');
    });

    it('should default confidence to medium when undefined', () => {
      const item = {
        name: 'Test Item',
        category: 'other',
        subCategory: 'misc',
        color: 'blue',
        condition: 'good',
        quantity: 1,
        brand: null,
        model: null,
        dimensions: null,
        estimatedValue: null,
        processingNotes: null
      } as unknown as CatalogItem;

      const snapshot = catalogItemToSnapshot(item);

      expect(snapshot.confidence).toBe('medium');
    });
  });

  describe('formatHistoryForPrompt', () => {
    it('should format history entry for prompt injection', () => {
      const history: CatalogHistoryEntry[] = [{
        id: 'test-id',
        catalogedAt: { toDate: () => new Date() } as any,
        model: 'gemini-3-pro-preview',
        imageUrls: ['https://example.com/image.jpg'],
        toolCalls: [
          { name: 'google_lens_search', args: {}, result: {}, success: true },
          { name: 'barcode_lookup', args: {}, result: {}, success: false }
        ],
        result: {
          name: 'Apple iPhone 15 Pro',
          brand: 'Apple',
          model: 'iPhone 15 Pro',
          category: 'electronics',
          subCategory: 'smartphones',
          confidence: 'high',
          estimatedValue: 999,
          condition: 'like-new'
        },
        metadata: {
          totalTokens: 1500,
          durationMs: 3000,
          usedContextCache: true
        }
      }];

      const prompt = formatHistoryForPrompt(history);

      expect(prompt).toContain('PREVIOUS CATALOG INFORMATION');
      expect(prompt).toContain('Apple iPhone 15 Pro');
      expect(prompt).toContain('Brand: Apple');
      expect(prompt).toContain('Model: iPhone 15 Pro');
      expect(prompt).toContain('Category: electronics');
      expect(prompt).toContain('Confidence: high');
      expect(prompt).toContain('Estimated Value: $999');
      expect(prompt).toContain('Condition: like-new');
      expect(prompt).toContain('google_lens_search: Success');
      expect(prompt).toContain('barcode_lookup: Failed');
      expect(prompt).toContain('maintain consistency');
    });

    it('should return empty string for empty history', () => {
      const prompt = formatHistoryForPrompt([]);
      expect(prompt).toBe('');
    });

    it('should handle unknown brand and model', () => {
      const history: CatalogHistoryEntry[] = [{
        id: 'test-id',
        catalogedAt: { toDate: () => new Date() } as any,
        model: 'gemini-3-pro-preview',
        imageUrls: ['https://example.com/image.jpg'],
        toolCalls: [],
        result: {
          name: 'Generic Item',
          brand: null,
          model: null,
          category: 'other',
          subCategory: null,
          confidence: 'low',
          estimatedValue: null,
          condition: null
        },
        metadata: {
          totalTokens: 1000,
          durationMs: 2000,
          usedContextCache: false
        }
      }];

      const prompt = formatHistoryForPrompt(history);

      expect(prompt).toContain('Brand: Unknown');
      expect(prompt).toContain('Model: Unknown');
      expect(prompt).not.toContain('Estimated Value:');
      expect(prompt).not.toContain('Condition:');
    });

    it('should only use most recent entry', () => {
      const history: CatalogHistoryEntry[] = [
        {
          id: 'newer-id',
          catalogedAt: { toDate: () => new Date('2026-01-18') } as any,
          model: 'gemini-3-pro-preview',
          imageUrls: ['https://example.com/image2.jpg'],
          toolCalls: [],
          result: {
            name: 'Updated Item Name',
            brand: 'NewBrand',
            model: null,
            category: 'electronics',
            subCategory: null,
            confidence: 'high',
            estimatedValue: 200,
            condition: 'good'
          },
          metadata: {
            totalTokens: 1200,
            durationMs: 2500,
            usedContextCache: true
          }
        },
        {
          id: 'older-id',
          catalogedAt: { toDate: () => new Date('2026-01-17') } as any,
          model: 'gemini-3-pro-preview',
          imageUrls: ['https://example.com/image1.jpg'],
          toolCalls: [],
          result: {
            name: 'Old Item Name',
            brand: 'OldBrand',
            model: null,
            category: 'other',
            subCategory: null,
            confidence: 'low',
            estimatedValue: 50,
            condition: 'poor'
          },
          metadata: {
            totalTokens: 800,
            durationMs: 1500,
            usedContextCache: false
          }
        }
      ];

      const prompt = formatHistoryForPrompt(history);

      expect(prompt).toContain('Updated Item Name');
      expect(prompt).toContain('NewBrand');
      expect(prompt).not.toContain('Old Item Name');
      expect(prompt).not.toContain('OldBrand');
    });
  });
});
