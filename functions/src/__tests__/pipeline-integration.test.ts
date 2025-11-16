import * as admin from 'firebase-admin';
import { createItem } from '../items/createItem';

/**
 * Full AI Pipeline Integration Test (Task 11)
 * Tests the complete flow: Layer 1 → 2a → 2b → 3
 *
 * Requires Firebase Emulator to be running:
 * firebase emulators:start --only functions,firestore,auth
 */
describe('Full AI Pipeline Integration', () => {
  let db: admin.firestore.Firestore;

  beforeAll(() => {
    // Initialize Firebase Admin if not already initialized
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: process.env.GOOGLE_CLOUD_PROJECT || 'abundance-mvp-test'
      });
    }
    db = admin.firestore();
  });

  test('completes full pipeline: Layer 1 → 2a → 2b → 3', async () => {
    // Set longer timeout for full pipeline (60 seconds)
    jest.setTimeout(60000);

    // Skip if not running against emulator
    if (!process.env.FIRESTORE_EMULATOR_HOST) {
      console.log('Skipping integration test: FIRESTORE_EMULATOR_HOST not set');
      console.log('Run: firebase emulators:start --only functions,firestore,auth');
      return;
    }

    // Create item with Layer 1 data (iOS detection)
    const itemId = await createItem(
      'test_user_integration',
      'https://storage.googleapis.com/abundance-items/test-camping-stove.jpg',
      {
        detectedClass: 'camping stove',
        confidence: 0.92,
        boundingBox: { x: 0, y: 0, width: 100, height: 100 },
      },
      '012345678905'
    );

    console.log(`Created item ${itemId} for integration test`);

    // Wait for Layer 2a completion (triggered by createItem)
    let itemDoc;
    let attempts = 0;
    const maxAttempts = 20;

    while (attempts < maxAttempts) {
      itemDoc = await db.collection('items').doc(itemId).get();
      const itemData = itemDoc.data();

      if (itemData?.status === 'layer2a_complete') {
        console.log(`✅ Layer 2a complete after ${attempts + 1} attempts`);
        break;
      }

      await new Promise(resolve => setTimeout(resolve, 1000));
      attempts++;
    }

    expect(itemDoc?.data()?.status).toBe('layer2a_complete');
    expect(itemDoc?.data()?.layer2a).toBeDefined();
    expect(itemDoc?.data()?.layer2a?.category).toBeDefined();
    expect(itemDoc?.data()?.layer2a?.color).toBeDefined();
    expect(itemDoc?.data()?.layer2a?.condition).toBeDefined();

    // Wait for Layer 2b completion (triggered by onLayer2aComplete)
    attempts = 0;
    while (attempts < maxAttempts) {
      itemDoc = await db.collection('items').doc(itemId).get();
      const itemData = itemDoc.data();

      if (itemData?.status === 'layer2b_complete') {
        console.log(`✅ Layer 2b complete after ${attempts + 1} attempts`);
        break;
      }

      await new Promise(resolve => setTimeout(resolve, 1000));
      attempts++;
    }

    expect(itemDoc?.data()?.status).toBe('layer2b_complete');
    expect(itemDoc?.data()?.layer2b).toBeDefined();
    expect(itemDoc?.data()?.layer2b?.source).toMatch(/barcode|serpapi/);
    expect(itemDoc?.data()?.layer2b?.product).toBeDefined();
    expect(itemDoc?.data()?.layer2b?.product?.name).toBeDefined();
    expect(itemDoc?.data()?.layer2b?.product?.brand).toBeDefined();

    // Wait for Layer 3 completion (triggered by onLayer2bComplete)
    attempts = 0;
    while (attempts < maxAttempts) {
      itemDoc = await db.collection('items').doc(itemId).get();
      const itemData = itemDoc.data();

      if (itemData?.status === 'complete') {
        console.log(`✅ Layer 3 complete after ${attempts + 1} attempts`);
        break;
      }

      await new Promise(resolve => setTimeout(resolve, 1000));
      attempts++;
    }

    expect(itemDoc?.data()?.status).toBe('complete');
    expect(itemDoc?.data()?.metadata).toBeDefined();

    const metadata = itemDoc?.data()?.metadata;
    expect(metadata?.name).toBeDefined();
    expect(metadata?.brand).toBeDefined();
    expect(metadata?.category).toBeDefined();
    expect(metadata?.color).toBeDefined();
    expect(metadata?.condition).toMatch(/new|like-new|good|fair|poor/);
    expect(metadata?.estimatedValue).toBeGreaterThan(0);
    expect(metadata?.confidence).toMatch(/high|medium|low/);
    expect(metadata?.model_used).toBe('claude-sonnet-4-5');
    expect(metadata?.tokensUsed).toBeDefined();

    console.log('✅ Full pipeline integration test complete!');
    console.log('Final metadata:', JSON.stringify(metadata, null, 2));

    // Cleanup
    await db.collection('items').doc(itemId).delete();
  }, 60000);
});
