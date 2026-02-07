/**
 * Unit tests for onItemDeleted trigger
 *
 * Tests the storage cleanup logic when an item document is deleted.
 * Verifies:
 * 1. Successful deletion of all file types (primary image, crops, motion clip)
 * 2. 404 handling (files that don't exist should not throw)
 * 3. Error handling for listing failures
 * 4. Counter accuracy (deletedCount, notFoundCount, errorCount)
 */

// Mock firebase-admin before importing trigger
const mockDelete = jest.fn();
const mockFile = jest.fn((path: string) => ({
  delete: mockDelete,
  name: path,
}));
const mockGetFiles = jest.fn();
const mockBucket = jest.fn(() => ({
  file: mockFile,
  getFiles: mockGetFiles,
}));
const mockStorage = jest.fn(() => ({
  bucket: mockBucket,
}));

jest.mock('firebase-admin', () => ({
  storage: mockStorage,
}));

// Mock StructuredLogger
const mockLogInfo = jest.fn();
const mockLogWarn = jest.fn();
const mockLogError = jest.fn();

jest.mock('../../monitoring/logger', () => ({
  StructuredLogger: jest.fn().mockImplementation(() => ({
    info: mockLogInfo,
    warn: mockLogWarn,
    error: mockLogError,
  })),
}));

// Store trigger handler for testing
let capturedHandler: ((event: unknown) => Promise<void>) | null = null;

jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentDeleted: jest.fn((path: string, handler: (event: unknown) => Promise<void>) => {
    capturedHandler = handler;
    return { handler };
  }),
}));

describe('onItemDeleted trigger', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    capturedHandler = null;
  });

  // Helper to create a mock event
  const createMockEvent = (itemId: string, userId: string, imageUrl: string) => ({
    params: { itemId },
    data: {
      data: () => ({
        userId,
        imageUrl,
      }),
    },
  });

  describe('trigger configuration', () => {
    it('should register with correct document path', async () => {
      const { onDocumentDeleted } = require('firebase-functions/v2/firestore');

      // Import trigger to register it
      await import('../onItemDeleted');

      expect(onDocumentDeleted).toHaveBeenCalledWith(
        'items/{itemId}',
        expect.any(Function)
      );
    });
  });

  describe('successful deletion of all file types', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;

      // Re-import to get fresh handler
      await import('../onItemDeleted');
    });

    it('should delete primary image, crop files, additional photos, and motion clip', async () => {
      // Setup: mock crop files found, no additional photos
      const mockCropFiles = [
        { name: 'users/user123/items/item456_crop_0.jpg' },
        { name: 'users/user123/items/item456_crop_1.jpg' },
        { name: 'users/user123/items/item456_crop_2.jpg' },
      ];
      // First call returns crops, second call returns no additional photos
      mockGetFiles
        .mockResolvedValueOnce([mockCropFiles])
        .mockResolvedValueOnce([[]]);
      mockDelete.mockResolvedValue([{}]);

      const event = createMockEvent(
        'item456',
        'user123',
        'gs://abundance-mvp.firebasestorage.app/users/user123/items/item456.jpg'
      );

      await capturedHandler!(event);

      // Verify primary image deletion attempted
      expect(mockFile).toHaveBeenCalledWith('users/user123/items/item456.jpg');

      // Verify crop files listing
      expect(mockGetFiles).toHaveBeenCalledWith({
        prefix: 'users/user123/items/item456_crop_',
      });

      // Verify additional photos listing
      expect(mockGetFiles).toHaveBeenCalledWith({
        prefix: 'users/user123/items/item456_photo_',
      });

      // Verify motion clip deletion attempted
      expect(mockFile).toHaveBeenCalledWith('users/user123/items/item456/motion.mov');

      // Verify all crop files were attempted for deletion
      expect(mockFile).toHaveBeenCalledWith('users/user123/items/item456_crop_0.jpg');
      expect(mockFile).toHaveBeenCalledWith('users/user123/items/item456_crop_1.jpg');
      expect(mockFile).toHaveBeenCalledWith('users/user123/items/item456_crop_2.jpg');

      // Total: 1 primary + 3 crops + 1 motion = 5 delete calls
      expect(mockDelete).toHaveBeenCalledTimes(5);
    });

    it('should handle single image capture (no crops, no additional photos)', async () => {
      // Setup: no crop files or additional photos found
      mockGetFiles.mockResolvedValue([[]]);
      mockDelete.mockResolvedValue([{}]);

      const event = createMockEvent('item789', 'user456', 'gs://test/image.jpg');

      await capturedHandler!(event);

      // Should still attempt primary and motion, but no crops or additional photos
      expect(mockFile).toHaveBeenCalledWith('users/user456/items/item789.jpg');
      expect(mockFile).toHaveBeenCalledWith('users/user456/items/item789/motion.mov');

      // Only 2 deletions: primary + motion
      expect(mockDelete).toHaveBeenCalledTimes(2);

      // Verify log about no crops
      expect(mockLogInfo).toHaveBeenCalledWith(
        'No cropped images found (single image capture?)',
        expect.objectContaining({ prefix: 'users/user456/items/item789_crop_' })
      );
    });
  });

  describe('404 handling - files that do not exist', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemDeleted');
    });

    it('should not throw when primary image does not exist (404)', async () => {
      mockGetFiles.mockResolvedValue([[]]); // Same empty for both crop and photo listings
      mockDelete.mockRejectedValue({ code: 404 });

      const event = createMockEvent('item123', 'user789', 'gs://test/image.jpg');

      // Should not throw
      await expect(capturedHandler!(event)).resolves.not.toThrow();

      // Should log as info, not error
      expect(mockLogInfo).toHaveBeenCalledWith(
        'primary image not found (may not exist)',
        expect.objectContaining({ path: 'users/user789/items/item123.jpg' })
      );
    });

    it('should handle 404 as string code', async () => {
      mockGetFiles.mockResolvedValue([[]]);
      mockDelete.mockRejectedValue({ code: '404' });

      const event = createMockEvent('item123', 'user789', 'gs://test/image.jpg');

      await expect(capturedHandler!(event)).resolves.not.toThrow();
    });

    it('should increment notFoundCount for 404 errors', async () => {
      // All files return 404
      mockGetFiles.mockResolvedValue([[]]);
      mockDelete.mockRejectedValue({ code: 404 });

      const event = createMockEvent('itemXYZ', 'userABC', 'gs://test/image.jpg');

      await capturedHandler!(event);

      // Final log should show notFoundCount
      expect(mockLogInfo).toHaveBeenCalledWith(
        'Storage cleanup complete for item',
        expect.objectContaining({
          notFoundCount: 2, // primary + motion
          deletedCount: 0,
          errorCount: 0,
        })
      );
    });
  });

  describe('error handling for listing failures', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemDeleted');
    });

    it('should handle getFiles failure gracefully', async () => {
      const listError = new Error('Permission denied');
      // Both crop and photo listing fail
      mockGetFiles.mockRejectedValue(listError);
      mockDelete.mockResolvedValue([{}]);

      const event = createMockEvent('item111', 'user222', 'gs://test/image.jpg');

      // Should not throw even if listing fails
      await expect(capturedHandler!(event)).resolves.not.toThrow();

      // Should log the error
      expect(mockLogError).toHaveBeenCalledWith(
        'Failed to list cropped images',
        listError,
        expect.objectContaining({ prefix: 'users/user222/items/item111_crop_' })
      );

      // Should still delete primary and motion
      expect(mockDelete).toHaveBeenCalledTimes(2);
    });

    it('should continue with other deletions when one file fails', async () => {
      // First getFiles returns crops, second returns no additional photos
      mockGetFiles
        .mockResolvedValueOnce([
          [{ name: 'users/user333/items/item444_crop_0.jpg' }],
        ])
        .mockResolvedValueOnce([[]]);

      // First delete succeeds, second fails with non-404 error
      mockDelete
        .mockResolvedValueOnce([{}]) // primary succeeds
        .mockRejectedValueOnce(new Error('Network error')) // crop fails
        .mockResolvedValueOnce([{}]); // motion succeeds

      const event = createMockEvent('item444', 'user333', 'gs://test/image.jpg');

      await capturedHandler!(event);

      // All deletes should be attempted
      expect(mockDelete).toHaveBeenCalledTimes(3);

      // Error should be logged
      expect(mockLogError).toHaveBeenCalledWith(
        'Failed to delete cropped image',
        expect.any(Error),
        expect.any(Object)
      );
    });
  });

  describe('counter accuracy', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemDeleted');
    });

    it('should accurately count deleted files', async () => {
      // First getFiles call returns crops, second returns no additional photos
      mockGetFiles
        .mockResolvedValueOnce([
          [
            { name: 'users/u1/items/i1_crop_0.jpg' },
            { name: 'users/u1/items/i1_crop_1.jpg' },
          ],
        ])
        .mockResolvedValueOnce([[]]);
      mockDelete.mockResolvedValue([{}]);

      const event = createMockEvent('i1', 'u1', 'gs://test/image.jpg');

      await capturedHandler!(event);

      // Final summary should have accurate counts
      // 1 primary + 2 crops + 1 motion = 4 deleted
      expect(mockLogInfo).toHaveBeenCalledWith(
        'Storage cleanup complete for item',
        expect.objectContaining({
          deletedCount: 4,
          notFoundCount: 0,
          errorCount: 0,
          totalAttempted: 4,
        })
      );
    });

    it('should accurately count mixed results', async () => {
      // First getFiles returns crops, second returns no additional photos
      mockGetFiles
        .mockResolvedValueOnce([
          [{ name: 'users/u2/items/i2_crop_0.jpg' }],
        ])
        .mockResolvedValueOnce([[]]);

      // Primary succeeds, crop returns 404, motion has error
      mockDelete
        .mockResolvedValueOnce([{}]) // primary - success
        .mockRejectedValueOnce({ code: 404 }) // crop - not found
        .mockRejectedValueOnce(new Error('Storage error')); // motion - error

      const event = createMockEvent('i2', 'u2', 'gs://test/image.jpg');

      await capturedHandler!(event);

      expect(mockLogInfo).toHaveBeenCalledWith(
        'Storage cleanup complete for item',
        expect.objectContaining({
          deletedCount: 1,
          notFoundCount: 1,
          errorCount: 1,
          totalAttempted: 3,
        })
      );
    });

    it('should handle all 404s correctly', async () => {
      mockGetFiles.mockResolvedValue([[]]);
      mockDelete.mockRejectedValue({ code: 404 });

      const event = createMockEvent('i3', 'u3', 'gs://test/image.jpg');

      await capturedHandler!(event);

      expect(mockLogInfo).toHaveBeenCalledWith(
        'Storage cleanup complete for item',
        expect.objectContaining({
          deletedCount: 0,
          notFoundCount: 2, // primary + motion
          errorCount: 0,
          totalAttempted: 2,
        })
      );
    });
  });

  describe('edge cases', () => {
    beforeEach(async () => {
      jest.resetModules();
      jest.clearAllMocks();
      capturedHandler = null;
      await import('../onItemDeleted');
    });

    it('should handle missing document data', async () => {
      const event = {
        params: { itemId: 'orphanItem' },
        data: {
          data: () => null,
        },
      };

      await capturedHandler!(event);

      // Should warn and return early
      expect(mockLogWarn).toHaveBeenCalledWith('No data found for deleted item');
      expect(mockDelete).not.toHaveBeenCalled();
    });

    it('should handle many crop files', async () => {
      // Simulate burst capture with 10 objects detected
      const manyCrops = Array.from({ length: 10 }, (_, i) => ({
        name: `users/uX/items/iX_crop_${i}.jpg`,
      }));
      // First getFiles returns crops, second returns no additional photos
      mockGetFiles
        .mockResolvedValueOnce([manyCrops])
        .mockResolvedValueOnce([[]]);
      mockDelete.mockResolvedValue([{}]);

      const event = createMockEvent('iX', 'uX', 'gs://test/image.jpg');

      await capturedHandler!(event);

      // 1 primary + 10 crops + 1 motion = 12 deletions
      expect(mockDelete).toHaveBeenCalledTimes(12);

      expect(mockLogInfo).toHaveBeenCalledWith(
        'Found cropped images to delete',
        expect.objectContaining({ count: 10 })
      );
    });

    it('should log userId and imageUrl at start', async () => {
      mockGetFiles.mockResolvedValue([[]]); // Same empty for both listings
      mockDelete.mockResolvedValue([{}]);

      const event = createMockEvent(
        'logTestItem',
        'logTestUser',
        'gs://bucket/path/to/image.jpg'
      );

      await capturedHandler!(event);

      expect(mockLogInfo).toHaveBeenCalledWith(
        'Cleaning up storage for deleted item',
        expect.objectContaining({
          userId: 'logTestUser',
          imageUrl: 'gs://bucket/path/to/image.jpg',
        })
      );
    });
  });
});
