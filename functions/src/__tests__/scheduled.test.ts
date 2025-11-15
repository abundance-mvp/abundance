import { describe, it, expect } from '@jest/globals';
import { cleanupDeletedItemsScheduled } from '../scheduled/cleanupDeletedItems';
import { checkSubscriptionExpiryScheduled } from '../scheduled/checkSubscriptionExpiry';

describe('Scheduled Jobs', () => {
  describe('cleanupDeletedItemsScheduled', () => {
    it('should be defined and exported', () => {
      expect(cleanupDeletedItemsScheduled).toBeDefined();
      expect(typeof cleanupDeletedItemsScheduled).toBe('function');
    });

    it('should have the correct schedule configuration', () => {
      // Verify scheduled function is configured for daily 2am UTC
      expect(cleanupDeletedItemsScheduled.__endpoint).toBeDefined();
      expect(cleanupDeletedItemsScheduled.__endpoint.scheduleTrigger).toBeDefined();
      expect(cleanupDeletedItemsScheduled.__endpoint.scheduleTrigger?.schedule).toBe('0 2 * * *');
      expect(cleanupDeletedItemsScheduled.__endpoint.scheduleTrigger?.timeZone).toBe('UTC');
    });
  });

  describe('checkSubscriptionExpiryScheduled', () => {
    it('should be defined and exported', () => {
      expect(checkSubscriptionExpiryScheduled).toBeDefined();
      expect(typeof checkSubscriptionExpiryScheduled).toBe('function');
    });

    it('should have the correct schedule configuration', () => {
      // Verify scheduled function is configured for daily 6am UTC
      expect(checkSubscriptionExpiryScheduled.__endpoint).toBeDefined();
      expect(checkSubscriptionExpiryScheduled.__endpoint.scheduleTrigger).toBeDefined();
      expect(checkSubscriptionExpiryScheduled.__endpoint.scheduleTrigger?.schedule).toBe('0 6 * * *');
      expect(checkSubscriptionExpiryScheduled.__endpoint.scheduleTrigger?.timeZone).toBe('UTC');
    });
  });

  describe('Scheduled jobs structure', () => {
    it('should have both cleanup and subscription jobs defined', () => {
      // Verify both scheduled jobs are exported and configured
      expect(cleanupDeletedItemsScheduled).toBeDefined();
      expect(checkSubscriptionExpiryScheduled).toBeDefined();
    });
  });
});
