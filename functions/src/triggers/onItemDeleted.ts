import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { StructuredLogger } from '../monitoring/logger';

/**
 * Firestore Trigger: onItemDeleted
 * Cleans up Cloud Storage files when an item document is deleted.
 *
 * Deletes:
 * - /users/{userId}/items/{itemId}.jpg (primary image)
 * - /items/{itemId}/motion.mov (Live Photo motion clip, if exists)
 */
export const onItemDeleted = onDocumentDeleted(
  'items/{itemId}',
  async (event) => {
    const itemId = event.params.itemId;
    const deletedData = event.data?.data();

    const logger = new StructuredLogger({
      itemId,
      operation: 'onItemDeleted',
    });

    if (!deletedData) {
      logger.warn('No data found for deleted item');
      return;
    }

    const userId = deletedData.userId as string;
    const imageUrl = deletedData.imageUrl as string;

    logger.info('Cleaning up storage for deleted item', { userId, imageUrl });

    const bucket = admin.storage().bucket();
    const deletePromises: Promise<void>[] = [];

    // 1. Delete primary image
    // Path format: users/{userId}/items/{itemId}.jpg
    const imagePath = `users/${userId}/items/${itemId}.jpg`;
    deletePromises.push(
      bucket.file(imagePath).delete()
        .then(() => {
          logger.info('Deleted image', { path: imagePath });
        })
        .catch((error: any) => {
          // File may not exist if upload failed - log warning, don't throw
          if (error.code === 404) {
            logger.warn('Image not found (already deleted?)', { path: imagePath });
          } else {
            logger.error('Failed to delete image', error, { path: imagePath });
          }
        })
    );

    // 2. Delete Live Photo motion clip if it exists
    // Path format: items/{itemId}/motion.mov
    const motionPath = `items/${itemId}/motion.mov`;
    deletePromises.push(
      bucket.file(motionPath).delete()
        .then(() => {
          logger.info('Deleted motion clip', { path: motionPath });
        })
        .catch((error: any) => {
          // Motion clip is optional - don't throw if not found
          if (error.code === 404) {
            // Debug level - motion clip is optional
            logger.info('No motion clip found (optional)', { path: motionPath });
          } else {
            logger.error('Failed to delete motion clip', error, { path: motionPath });
          }
        })
    );

    // Wait for all deletions (with error handling above)
    await Promise.all(deletePromises);

    logger.info('Storage cleanup complete for item');
  }
);
