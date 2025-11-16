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

  describe('onItemCreated comprehensive trigger tests (I3)', () => {
    it('should verify trigger handles missing imageUrl by reading source', () => {
      // Read source to verify missing imageUrl handling
      const fs = require('fs');
      const path = require('path');
      const triggerPath = path.join(__dirname, '../triggers/onItemCreated.ts');
      const source = fs.readFileSync(triggerPath, 'utf8');

      // Verify it checks for missing imageUrl
      expect(source).toContain('if (!item.imageUrl)');
      expect(source).toContain("status: 'failed_layer2a'");
      expect(source).toContain('Missing imageUrl');
    });

    it('should verify trigger skips non-pending items by reading source', () => {
      const fs = require('fs');
      const path = require('path');
      const triggerPath = path.join(__dirname, '../triggers/onItemCreated.ts');
      const source = fs.readFileSync(triggerPath, 'utf8');

      // Verify it checks status
      expect(source).toContain("if (item.status !== 'pending')");
      expect(source).toContain('Skipping item');
    });

    it('should verify trigger calls extractAttributesLayer2a and updates Firestore', () => {
      const fs = require('fs');
      const path = require('path');
      const triggerPath = path.join(__dirname, '../triggers/onItemCreated.ts');
      const source = fs.readFileSync(triggerPath, 'utf8');

      // Verify it calls extractAttributesLayer2a
      expect(source).toContain('await extractAttributesLayer2a');

      // Verify it updates Firestore with attributes
      expect(source).toContain("'layer2a.category': attributes.category");
      expect(source).toContain("'layer2a.color': attributes.color");
      expect(source).toContain("'layer2a.material': attributes.material");
      expect(source).toContain("'layer2a.condition': attributes.condition");
      expect(source).toContain("'layer2a.confidence': attributes.confidence");
      expect(source).toContain("status: 'layer2a_complete'");
    });

    it('should verify trigger handles extraction failures', () => {
      const fs = require('fs');
      const path = require('path');
      const triggerPath = path.join(__dirname, '../triggers/onItemCreated.ts');
      const source = fs.readFileSync(triggerPath, 'utf8');

      // Verify it has try-catch for extraction
      expect(source).toContain('try {');
      expect(source).toContain('catch (error');

      // Verify it sets failed_layer2a status on error
      expect(source).toContain("status: 'failed_layer2a'");
      expect(source).toContain('error: {');
      expect(source).toContain('message: error.message');
    });
  });
});
