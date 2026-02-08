/**
 * Unit tests for bounding box converter utilities
 */

import {
  boxToAbsolute,
  addPadding,
  isValidBoundingBox,
  calculateBoxArea,
  absoluteToBox,
  AbsoluteCoordinates
} from '../utils/bbox-converter';
import { BoundingBox } from '../schemas/detection-result';

describe('bbox-converter', () => {
  describe('boxToAbsolute', () => {
    it('converts center box correctly', () => {
      // Box in center of image: 25%-75% on both axes
      const box: BoundingBox = [250, 250, 750, 750];
      const result = boxToAbsolute(box, 1000, 1000);

      expect(result).toEqual({
        x1: 250,
        y1: 250,
        x2: 750,
        y2: 750,
        width: 500,
        height: 500
      });
    });

    it('handles non-square images', () => {
      // Full-width box on a 1920x1080 image
      const box: BoundingBox = [0, 0, 1000, 1000];
      const result = boxToAbsolute(box, 1920, 1080);

      expect(result).toEqual({
        x1: 0,
        y1: 0,
        x2: 1920,
        y2: 1080,
        width: 1920,
        height: 1080
      });
    });

    it('handles small box correctly', () => {
      // Small 10% box in corner
      const box: BoundingBox = [100, 100, 200, 200];
      const result = boxToAbsolute(box, 1000, 1000);

      expect(result).toEqual({
        x1: 100,
        y1: 100,
        x2: 200,
        y2: 200,
        width: 100,
        height: 100
      });
    });
  });

  describe('addPadding', () => {
    it('adds 5% padding by default', () => {
      const coords: AbsoluteCoordinates = {
        x1: 100,
        y1: 100,
        x2: 200,
        y2: 200,
        width: 100,
        height: 100
      };

      const result = addPadding(coords, 0.05, 1000, 1000);

      // 5% of 100 = 5 pixels padding
      expect(result.x1).toBe(95);
      expect(result.y1).toBe(95);
      expect(result.x2).toBe(205);
      expect(result.y2).toBe(205);
      expect(result.width).toBe(110);
      expect(result.height).toBe(110);
    });

    it('clamps to image bounds', () => {
      const coords: AbsoluteCoordinates = {
        x1: 0,
        y1: 0,
        x2: 100,
        y2: 100,
        width: 100,
        height: 100
      };

      const result = addPadding(coords, 0.10, 1000, 1000);

      // Should not go below 0
      expect(result.x1).toBe(0);
      expect(result.y1).toBe(0);
      expect(result.x2).toBe(110);
      expect(result.y2).toBe(110);
    });

    it('clamps to max bounds', () => {
      const coords: AbsoluteCoordinates = {
        x1: 900,
        y1: 900,
        x2: 1000,
        y2: 1000,
        width: 100,
        height: 100
      };

      const result = addPadding(coords, 0.10, 1000, 1000);

      // Should not exceed image dimensions
      expect(result.x1).toBe(890);
      expect(result.y1).toBe(890);
      expect(result.x2).toBe(1000);
      expect(result.y2).toBe(1000);
    });
  });

  describe('isValidBoundingBox', () => {
    it('accepts valid box', () => {
      expect(isValidBoundingBox([100, 100, 500, 500])).toBe(true);
    });

    it('rejects non-array', () => {
      expect(isValidBoundingBox(null as unknown as BoundingBox)).toBe(false);
      expect(isValidBoundingBox({} as unknown as BoundingBox)).toBe(false);
    });

    it('rejects wrong length', () => {
      expect(isValidBoundingBox([100, 100, 500] as unknown as BoundingBox)).toBe(false);
      expect(isValidBoundingBox([100, 100, 500, 500, 600] as unknown as BoundingBox)).toBe(false);
    });

    it('rejects out of range values', () => {
      expect(isValidBoundingBox([-1, 100, 500, 500])).toBe(false);
      expect(isValidBoundingBox([100, 100, 1001, 500])).toBe(false);
    });

    it('rejects inverted coordinates', () => {
      // ymin > ymax
      expect(isValidBoundingBox([500, 100, 100, 500])).toBe(false);
      // xmin > xmax
      expect(isValidBoundingBox([100, 500, 500, 100])).toBe(false);
    });

    it('rejects too small boxes', () => {
      // Less than 1% (10 units)
      expect(isValidBoundingBox([100, 100, 105, 105])).toBe(false);
    });
  });

  describe('calculateBoxArea', () => {
    it('calculates full image area', () => {
      expect(calculateBoxArea([0, 0, 1000, 1000])).toBe(1);
    });

    it('calculates quarter area', () => {
      expect(calculateBoxArea([0, 0, 500, 500])).toBe(0.25);
    });

    it('calculates small area', () => {
      expect(calculateBoxArea([0, 0, 100, 100])).toBeCloseTo(0.01, 10);
    });
  });

  describe('absoluteToBox', () => {
    it('converts back correctly', () => {
      const original: BoundingBox = [250, 250, 750, 750];
      const absolute = boxToAbsolute(original, 1000, 1000);
      const result = absoluteToBox(absolute, 1000, 1000);

      expect(result).toEqual(original);
    });

    it('handles non-square images', () => {
      const coords: AbsoluteCoordinates = {
        x1: 0,
        y1: 0,
        x2: 960,
        y2: 540,
        width: 960,
        height: 540
      };

      const result = absoluteToBox(coords, 1920, 1080);

      expect(result).toEqual([0, 0, 500, 500]);
    });
  });
});
