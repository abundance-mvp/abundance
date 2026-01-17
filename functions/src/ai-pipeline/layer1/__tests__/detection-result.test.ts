/**
 * Unit tests for detection result schema validation
 */

import {
  validateDetectionResponse,
  Layer1DetectionResponse,
  DetectedObject
} from '../schemas/detection-result';

describe('detection-result schema', () => {
  describe('validateDetectionResponse', () => {
    it('accepts valid response with objects', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: 'uuid-123',
            label: 'Table lamp',
            category: 'lighting',
            box_2d: [100, 200, 400, 600],
            image_index: 0,
            confidence: 'high'
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('accepts empty objects array with reasoning', () => {
      const response: Layer1DetectionResponse = {
        objects: [],
        reasoning: 'The image contains only built-in fixtures.'
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('accepts multiple objects', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: 'uuid-1',
            label: 'Laptop',
            category: 'electronics',
            box_2d: [100, 100, 300, 400],
            image_index: 0,
            confidence: 'high'
          },
          {
            groupId: 'uuid-2',
            label: 'Book',
            category: 'books',
            box_2d: [500, 100, 700, 300],
            image_index: 0,
            confidence: 'medium'
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(true);
    });

    it('accepts objects with optional attributes', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: 'uuid-1',
            label: 'Leather armchair',
            category: 'furniture',
            box_2d: [100, 100, 800, 800],
            image_index: 0,
            attributes: {
              color: 'brown',
              material: 'leather',
              condition: 'good',
              brand: 'IKEA'
            }
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(true);
    });

    it('rejects missing objects array', () => {
      const response = {} as Layer1DetectionResponse;

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Response must contain an objects array');
    });

    it('rejects missing required fields', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            label: 'Missing groupId',
            category: 'test',
            box_2d: [100, 100, 200, 200],
            image_index: 0
          } as DetectedObject
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('groupId'))).toBe(true);
    });

    it('rejects invalid box_2d format', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: 'uuid-1',
            label: 'Test',
            category: 'test',
            box_2d: [100, 200, 300] as unknown as [number, number, number, number],
            image_index: 0
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('box_2d'))).toBe(true);
    });

    it('rejects out of range box_2d values', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: 'uuid-1',
            label: 'Test',
            category: 'test',
            box_2d: [100, 200, 1100, 600], // 1100 > 1000
            image_index: 0
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('1000'))).toBe(true);
    });

    it('rejects negative image_index', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: 'uuid-1',
            label: 'Test',
            category: 'test',
            box_2d: [100, 200, 300, 400],
            image_index: -1
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('image_index'))).toBe(true);
    });

    it('rejects invalid confidence value', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: 'uuid-1',
            label: 'Test',
            category: 'test',
            box_2d: [100, 200, 300, 400],
            image_index: 0,
            confidence: 'very-high' as 'high'
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('confidence'))).toBe(true);
    });

    it('collects multiple errors', () => {
      const response: Layer1DetectionResponse = {
        objects: [
          {
            groupId: '',  // empty string
            label: '',    // empty string
            category: 'test',
            box_2d: [100, 200, 300, 400],
            image_index: 0
          }
        ]
      };

      const result = validateDetectionResponse(response);
      expect(result.valid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(1);
    });
  });
});
