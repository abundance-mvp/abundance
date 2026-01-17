/**
 * Bounding Box Converter Utilities
 *
 * Converts between Gemini's normalized bounding box format (0-1000)
 * and absolute pixel coordinates for image cropping.
 */

import { BoundingBox } from '../schemas/detection-result';

/**
 * Absolute pixel coordinates for cropping
 */
export interface AbsoluteCoordinates {
  x1: number;  // left edge
  y1: number;  // top edge
  x2: number;  // right edge
  y2: number;  // bottom edge
  width: number;
  height: number;
}

/**
 * Convert Gemini box_2d format to absolute pixel coordinates
 *
 * Gemini format: [ymin, xmin, ymax, xmax] normalized to 0-1000
 *
 * @param box_2d - Bounding box in Gemini format [ymin, xmin, ymax, xmax]
 * @param imageWidth - Image width in pixels
 * @param imageHeight - Image height in pixels
 * @returns Absolute pixel coordinates for cropping
 */
export function boxToAbsolute(
  box_2d: BoundingBox,
  imageWidth: number,
  imageHeight: number
): AbsoluteCoordinates {
  const [ymin, xmin, ymax, xmax] = box_2d;

  const x1 = Math.round((xmin / 1000) * imageWidth);
  const y1 = Math.round((ymin / 1000) * imageHeight);
  const x2 = Math.round((xmax / 1000) * imageWidth);
  const y2 = Math.round((ymax / 1000) * imageHeight);

  return {
    x1,
    y1,
    x2,
    y2,
    width: x2 - x1,
    height: y2 - y1
  };
}

/**
 * Add padding to absolute coordinates (for better cropping)
 *
 * @param coords - Absolute coordinates
 * @param padding - Padding as percentage (0.0-1.0), default 0.05 (5%)
 * @param imageWidth - Image width for bounds checking
 * @param imageHeight - Image height for bounds checking
 * @returns Padded coordinates clamped to image bounds
 */
export function addPadding(
  coords: AbsoluteCoordinates,
  padding: number = 0.05,
  imageWidth: number,
  imageHeight: number
): AbsoluteCoordinates {
  const padX = Math.round(coords.width * padding);
  const padY = Math.round(coords.height * padding);

  const x1 = Math.max(0, coords.x1 - padX);
  const y1 = Math.max(0, coords.y1 - padY);
  const x2 = Math.min(imageWidth, coords.x2 + padX);
  const y2 = Math.min(imageHeight, coords.y2 + padY);

  return {
    x1,
    y1,
    x2,
    y2,
    width: x2 - x1,
    height: y2 - y1
  };
}

/**
 * Validate bounding box coordinates
 *
 * @param box_2d - Bounding box to validate
 * @returns true if valid, false otherwise
 */
export function isValidBoundingBox(box_2d: BoundingBox): boolean {
  if (!Array.isArray(box_2d) || box_2d.length !== 4) {
    return false;
  }

  const [ymin, xmin, ymax, xmax] = box_2d;

  // Check all values are numbers in valid range
  for (const val of box_2d) {
    if (typeof val !== 'number' || val < 0 || val > 1000) {
      return false;
    }
  }

  // Check min < max
  if (ymin >= ymax || xmin >= xmax) {
    return false;
  }

  // Check minimum size (at least 10 units = 1%)
  if (ymax - ymin < 10 || xmax - xmin < 10) {
    return false;
  }

  return true;
}

/**
 * Calculate area of bounding box (for filtering small detections)
 *
 * @param box_2d - Bounding box in Gemini format
 * @returns Area as percentage of image (0-1)
 */
export function calculateBoxArea(box_2d: BoundingBox): number {
  const [ymin, xmin, ymax, xmax] = box_2d;
  const width = (xmax - xmin) / 1000;
  const height = (ymax - ymin) / 1000;
  return width * height;
}

/**
 * Convert absolute coordinates back to Gemini format
 * (useful for storing normalized coordinates)
 *
 * @param coords - Absolute pixel coordinates
 * @param imageWidth - Image width in pixels
 * @param imageHeight - Image height in pixels
 * @returns Bounding box in Gemini format [ymin, xmin, ymax, xmax]
 */
export function absoluteToBox(
  coords: AbsoluteCoordinates,
  imageWidth: number,
  imageHeight: number
): BoundingBox {
  const xmin = Math.round((coords.x1 / imageWidth) * 1000);
  const ymin = Math.round((coords.y1 / imageHeight) * 1000);
  const xmax = Math.round((coords.x2 / imageWidth) * 1000);
  const ymax = Math.round((coords.y2 / imageHeight) * 1000);

  return [ymin, xmin, ymax, xmax];
}
