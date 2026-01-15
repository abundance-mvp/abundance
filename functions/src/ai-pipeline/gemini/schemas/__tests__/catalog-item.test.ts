import {
  CatalogItem,
  validateCatalogItem,
  CATALOG_ITEM_SCHEMA
} from '../catalog-item';

describe('CatalogItem Schema', () => {
  describe('validateCatalogItem', () => {
    it('should validate a complete catalog item', () => {
      const item: CatalogItem = {
        name: 'Nike Air Max 90',
        category: 'footwear',
        subCategory: 'sneakers',
        brand: 'Nike',
        model: 'Air Max 90',
        color: 'white/red',
        condition: 'good',
        dimensions: 'size 10 mens',
        quantity: 1,
        estimatedValue: 85.00,
        confidence: 'high',
        processingNotes: null
      };

      const result = validateCatalogItem(item);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should validate item with null optional fields', () => {
      const item: CatalogItem = {
        name: 'Unknown Item',
        category: 'other',
        subCategory: 'misc',
        brand: null,
        model: null,
        color: 'gray',
        condition: 'fair',
        dimensions: null,
        quantity: 1,
        estimatedValue: null,
        confidence: 'low',
        processingNotes: null
      };

      const result = validateCatalogItem(item);
      expect(result.valid).toBe(true);
    });

    it('should reject invalid condition value', () => {
      const item = {
        name: 'Test Item',
        category: 'other',
        subCategory: 'misc',
        brand: null,
        model: null,
        color: 'red',
        condition: 'excellent',
        dimensions: null,
        quantity: 1,
        estimatedValue: null,
        confidence: 'high'
      };

      const result = validateCatalogItem(item as CatalogItem);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Invalid condition: excellent');
    });

    it('should reject negative quantity', () => {
      const item: CatalogItem = {
        name: 'Test Item',
        category: 'other',
        subCategory: 'misc',
        brand: null,
        model: null,
        color: 'red',
        condition: 'good',
        dimensions: null,
        quantity: -1,
        estimatedValue: null,
        confidence: 'medium',
        processingNotes: null
      };

      const result = validateCatalogItem(item);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Quantity must be positive');
    });
  });

  describe('CATALOG_ITEM_SCHEMA', () => {
    it('should have correct JSON schema structure for Gemini', () => {
      expect(CATALOG_ITEM_SCHEMA.type).toBe('object');
      expect(CATALOG_ITEM_SCHEMA.properties).toHaveProperty('name');
      expect(CATALOG_ITEM_SCHEMA.properties).toHaveProperty('category');
      expect(CATALOG_ITEM_SCHEMA.properties).toHaveProperty('condition');
      expect(CATALOG_ITEM_SCHEMA.required).toContain('name');
      expect(CATALOG_ITEM_SCHEMA.required).toContain('category');
      expect(CATALOG_ITEM_SCHEMA.required).toContain('condition');
    });
  });
});
