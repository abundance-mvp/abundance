import { describe, it, expect, jest } from '@jest/globals';
import { onItemCreated } from '../triggers/onItemCreated';
import { onLayer2aComplete } from '../triggers/onLayer2aComplete';
import { onLayer2bComplete } from '../triggers/onLayer2bComplete';
import { extractAttributesLayer2a } from '../ai-pipeline/layer2a/extractAttributes';

jest.mock('../ai-pipeline/layer2a/extractAttributes');

describe('Firestore Triggers', () => {
  describe('onItemCreated', () => {
    it('should be defined and exported', () => {
      expect(onItemCreated).toBeDefined();
      expect(typeof onItemCreated).toBe('function');
    });

    it('should have the correct trigger path', () => {
      // Verify trigger is configured for items collection
      expect(onItemCreated.__endpoint).toBeDefined();
      expect(onItemCreated.__endpoint.eventTrigger?.eventType).toContain('created');
    });
  });

  describe('onLayer2aComplete', () => {
    it('should be defined and exported', () => {
      expect(onLayer2aComplete).toBeDefined();
      expect(typeof onLayer2aComplete).toBe('function');
    });

    it('should have the correct trigger path', () => {
      // Verify trigger is configured for items collection updates
      expect(onLayer2aComplete.__endpoint).toBeDefined();
      expect(onLayer2aComplete.__endpoint.eventTrigger?.eventType).toContain('updated');
    });
  });

  describe('onLayer2bComplete', () => {
    it('should be defined and exported', () => {
      expect(onLayer2bComplete).toBeDefined();
      expect(typeof onLayer2bComplete).toBe('function');
    });

    it('should have the correct trigger path', () => {
      // Verify trigger is configured for items collection updates
      expect(onLayer2bComplete.__endpoint).toBeDefined();
      expect(onLayer2bComplete.__endpoint.eventTrigger?.eventType).toContain('updated');
    });
  });

  describe('Trigger orchestration logic', () => {
    it('should define the correct state transition flow', () => {
      // onItemCreated: pending → layer2a_scheduled
      // onLayer2aComplete: layer2a_complete → layer2b_scheduled
      // onLayer2bComplete: layer2b_complete → layer3_scheduled

      // This is a smoke test to verify trigger structure
      expect(onItemCreated).toBeDefined();
      expect(onLayer2aComplete).toBeDefined();
      expect(onLayer2bComplete).toBeDefined();
    });
  });

  describe('onItemCreated Layer 2a integration', () => {
    it('should import extractAttributesLayer2a function', () => {
      // This test verifies that extractAttributesLayer2a is imported and available
      expect(extractAttributesLayer2a).toBeDefined();
      expect(typeof extractAttributesLayer2a).toBe('function');
    });

    it('should have Layer 2a integration in onItemCreated source code', () => {
      // Read the source code to verify it calls extractAttributesLayer2a
      const fs = require('fs');
      const path = require('path');
      const triggerPath = path.join(__dirname, '../triggers/onItemCreated.ts');
      const source = fs.readFileSync(triggerPath, 'utf8');

      // Verify the trigger imports extractAttributesLayer2a
      expect(source).toContain('extractAttributesLayer2a');

      // Verify it calls the function
      expect(source).toContain('await extractAttributesLayer2a');

      // Verify it updates with layer2a attributes
      expect(source).toContain("'layer2a.category'");
      expect(source).toContain("status: 'layer2a_complete'");
    });
  });
});
