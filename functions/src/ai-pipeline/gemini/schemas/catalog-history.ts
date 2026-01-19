/**
 * Catalog History Data Model
 *
 * Stores previous catalog results for session persistence.
 * Enables Gemini to remember context when users add photos or request re-cataloging.
 *
 * Stored in Firestore subcollection: items/{itemId}/catalogHistory/{entryId}
 */

import { Timestamp } from 'firebase-admin/firestore';
import { Condition, Confidence } from './catalog-item';

/**
 * Represents a single catalog history entry for an item.
 * Stored in Firestore subcollection: items/{itemId}/catalogHistory/{entryId}
 */
export interface CatalogHistoryEntry {
  /** Firestore document ID */
  id: string;

  /** Timestamp when this catalog was performed */
  catalogedAt: Timestamp;

  /** Gemini model used (e.g., 'gemini-3-pro-preview') */
  model: string;

  /** Image URLs processed in this catalog session */
  imageUrls: string[];

  /** Tool calls made during this session */
  toolCalls: ToolCallRecord[];

  /** Final catalog result */
  result: CatalogResultSnapshot;

  /** Processing metadata */
  metadata: CatalogMetadata;
}

/**
 * Record of a tool call made during cataloging
 */
export interface ToolCallRecord {
  /** Tool name (google_lens_search, barcode_lookup, web_search) */
  name: string;
  /** Arguments passed to the tool */
  args: Record<string, unknown>;
  /** Result returned by the tool */
  result: Record<string, unknown>;
  /** Whether the call succeeded */
  success: boolean;
}

/**
 * Snapshot of catalog result at a point in time
 */
export interface CatalogResultSnapshot {
  name: string;
  brand: string | null;
  model: string | null;
  category: string;
  subCategory: string | null;
  confidence: Confidence;
  estimatedValue: number | null;
  condition: Condition | null;
}

/**
 * Processing metadata for a catalog session
 */
export interface CatalogMetadata {
  /** Total tokens used */
  totalTokens: number;
  /** Processing duration in ms */
  durationMs: number;
  /** Whether context cache was used */
  usedContextCache: boolean;
}
