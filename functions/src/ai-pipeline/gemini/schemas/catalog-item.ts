/**
 * Condition enum for item condition assessment
 */
export type Condition = 'new' | 'like-new' | 'good' | 'fair' | 'poor';

/**
 * Confidence level for catalog identification
 */
export type Confidence = 'high' | 'medium' | 'low';

/**
 * CatalogItem - the output schema for Gemini 3 Pro
 */
export interface CatalogItem {
  name: string;
  category: string;
  subCategory: string;
  brand: string | null;
  model: string | null;
  color: string;
  condition: Condition;
  dimensions: string | null;
  quantity: number;
  estimatedValue: number | null;
  confidence: Confidence;
  processingNotes: string | null;
}

/**
 * DeepScanResult - extended output schema for Gemini Pro deep scan
 * Includes pricing, product identification, and market data
 */
export interface DeepScanResult {
  productUrl: string | null;
  upcCode: string | null;
  marketPriceRange: string | null;
  originalRetailPrice: number | null;
  processingNotes: string | null;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

const VALID_CONDITIONS: Condition[] = ['new', 'like-new', 'good', 'fair', 'poor'];
const VALID_CONFIDENCES: Confidence[] = ['high', 'medium', 'low'];

export function validateCatalogItem(item: CatalogItem): ValidationResult {
  const errors: string[] = [];

  if (!item.name || typeof item.name !== 'string') {
    errors.push('Name is required and must be a string');
  }
  if (!item.category || typeof item.category !== 'string') {
    errors.push('Category is required and must be a string');
  }
  if (!item.subCategory || typeof item.subCategory !== 'string') {
    errors.push('SubCategory is required and must be a string');
  }
  if (!item.color || typeof item.color !== 'string') {
    errors.push('Color is required and must be a string');
  }
  if (!VALID_CONDITIONS.includes(item.condition)) {
    errors.push(`Invalid condition: ${item.condition}`);
  }
  if (!VALID_CONFIDENCES.includes(item.confidence)) {
    errors.push(`Invalid confidence: ${item.confidence}`);
  }
  if (typeof item.quantity !== 'number' || item.quantity < 1) {
    errors.push('Quantity must be positive');
  }
  if (item.estimatedValue !== null && typeof item.estimatedValue !== 'number') {
    errors.push('EstimatedValue must be a number or null');
  }

  return { valid: errors.length === 0, errors };
}

export const DEEP_SCAN_SCHEMA = {
  type: 'object',
  properties: {
    productUrl: { type: ['string', 'null'], description: 'URL to product page or listing' },
    upcCode: { type: ['string', 'null'], description: 'UPC/EAN barcode if identifiable' },
    marketPriceRange: { type: ['string', 'null'], description: 'Current market price range (e.g. "$25-$45")' },
    originalRetailPrice: { type: ['number', 'null'], description: 'Original retail price in USD if known' },
    processingNotes: { type: ['string', 'null'], description: 'Notes about deep scan results' }
  },
  required: []
};

export const CATALOG_ITEM_SCHEMA = {
  type: 'object',
  properties: {
    name: { type: 'string', description: 'Product name' },
    category: { type: 'string', description: 'Primary category' },
    subCategory: { type: 'string', description: 'Sub-category' },
    brand: { type: ['string', 'null'], description: 'Brand name if identifiable' },
    model: { type: ['string', 'null'], description: 'Model name/number' },
    color: { type: 'string', description: 'Primary color(s)' },
    condition: { type: 'string', enum: ['new', 'like-new', 'good', 'fair', 'poor'], description: 'Physical condition' },
    dimensions: { type: ['string', 'null'], description: 'Size/dimensions info' },
    quantity: { type: 'integer', minimum: 1, description: 'Number of items' },
    estimatedValue: { type: ['number', 'null'], description: 'Estimated market value in USD' },
    confidence: { type: 'string', enum: ['high', 'medium', 'low'], description: 'Confidence level' },
    processingNotes: { type: ['string', 'null'], description: 'Notes about AI processing quality or issues' }
  },
  required: ['name', 'category', 'subCategory', 'color', 'condition', 'quantity', 'confidence']
};
