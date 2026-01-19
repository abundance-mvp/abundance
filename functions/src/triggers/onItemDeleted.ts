import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { StructuredLogger } from '../monitoring/logger';

/**
 * Firestore Trigger: onItemDeleted
 * Cleans up Cloud Storage files when an item document is deleted.
 *
 * Deletes:
 * - /users/{userId}/items/{itemId}.jpg (primary image)
 * - /users/{userId}/items/{itemId}_crop_*.jpg (cropped object images from Layer 1)
 * - /users/{userId}/items/{itemId}/motion.mov (Live Photo motion clip, if exists)
 *
 * Note: Crop files are created by layer1-service.ts with pattern:
 *   users/${userId}/items/${groupId}_crop_${index}.jpg
 * where groupId === itemId for items created from session detection
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
    let deletedCount = 0;
    let notFoundCount = 0;
    let errorCount = 0;

    // Helper function to delete a file with proper error handling
    const deleteFile = async (filePath: string, description: string): Promise<void> => {
      try {
        await bucket.file(filePath).delete();
        deletedCount++;
        logger.info(`Deleted ${description}`, { path: filePath });
      } catch (error: unknown) {
        const err = error as { code?: number | string };
        if (err.code === 404 || err.code === '404') {
          notFoundCount++;
          // Only log at debug level for optional files
          logger.info(`${description} not found (may not exist)`, { path: filePath });
        } else {
          errorCount++;
          logger.error(`Failed to delete ${description}`, error as Error, { path: filePath });
        }
      }
    };

    // 1. Delete primary image
    // Path format: users/{userId}/items/{itemId}.jpg
    const imagePath = `users/${userId}/items/${itemId}.jpg`;
    deletePromises.push(deleteFile(imagePath, 'primary image'));

    // 2. Delete cropped object images (from Layer 1 detection)
    // Path pattern: users/{userId}/items/{itemId}_crop_*.jpg
    // These are created by layer1-service.ts during object detection
    // We need to list files with this prefix and delete them all
    const cropPrefix = `users/${userId}/items/${itemId}_crop_`;
    try {
      const [files] = await bucket.getFiles({ prefix: cropPrefix });
      if (files.length > 0) {
        logger.info('Found cropped images to delete', { count: files.length, prefix: cropPrefix });
        for (const file of files) {
          deletePromises.push(deleteFile(file.name, 'cropped image'));
        }
      } else {
        logger.info('No cropped images found (single image capture?)', { prefix: cropPrefix });
      }
    } catch (error) {
      logger.error('Failed to list cropped images', error as Error, { prefix: cropPrefix });
    }

    // 3. Delete Live Photo motion clip if it exists
    // Path format: users/{userId}/items/{itemId}/motion.mov
    const motionPath = `users/${userId}/items/${itemId}/motion.mov`;
    deletePromises.push(deleteFile(motionPath, 'motion clip'));

    // Wait for all deletions (with error handling above)
    await Promise.all(deletePromises);

    logger.info('Storage cleanup complete for item', {
      deletedCount,
      notFoundCount,
      errorCount,
      totalAttempted: deletedCount + notFoundCount + errorCount
    });
  }
);
