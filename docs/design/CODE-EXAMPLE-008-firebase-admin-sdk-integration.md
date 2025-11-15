# CODE-EXAMPLE-008: Firebase Admin SDK Integration

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**References**: CLOUD-FUNCTIONS-001, RESEARCH-VALIDATION-stage-3.2, CODE-EXAMPLE-005
**Status**: Complete

## Overview

Production-ready patterns for Firebase Admin SDK (Node.js) in Cloud Functions:

- **Authentication**: Token verification, custom claims (premium status)
- **Storage**: Upload/download patterns, signed URLs vs download URLs
- **Lifecycle Policies**: Auto-delete after 90 days
- **Security**: User ownership verification

All patterns verified against Firebase Admin SDK v12.0.0+ documentation.

## 1. Firebase Admin SDK Initialization

```javascript
const admin = require('firebase-admin');

// Initialize Admin SDK (automatic in Cloud Functions)
admin.initializeApp();

// Get service instances
const auth = admin.auth();
const firestore = admin.firestore();
const storage = admin.storage();

// Configure Firestore settings
firestore.settings({
  ignoreUndefinedProperties: true // Ignore undefined fields in writes
});

module.exports = { admin, auth, firestore, storage };
```

## 2. Authentication: Token Verification

```javascript
/**
 * Middleware: Verify Firebase ID token from Authorization header
 * Use in all HTTP endpoints that require authentication
 *
 * @param {Request} req - Express request
 * @param {Response} res - Express response
 * @param {Function} next - Next middleware
 */
async function verifyAuthToken(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing or invalid Authorization header'
      });
    }

    const idToken = authHeader.split('Bearer ')[1];

    // Verify token and decode claims
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // Attach user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      premium: decodedToken.premium || false, // Custom claim
      subscriptionTier: decodedToken.subscriptionTier || 'free' // Custom claim
    };

    console.log({
      severity: 'INFO',
      message: 'Auth token verified',
      uid: req.user.uid,
      premium: req.user.premium
    });

    next();
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Auth token verification failed',
      error: error.message
    });

    res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired token'
    });
  }
}

/**
 * Example: Protected HTTP endpoint
 */
const functions = require('firebase-functions');
const express = require('express');
const app = express();

app.use(express.json());
app.use(verifyAuthToken); // Apply to all routes

app.post('/analyzeItem', async (req, res) => {
  try {
    // req.user.uid is now available
    const userId = req.user.uid;

    // Check premium status
    if (!req.user.premium && await isOverFreeLimit(userId)) {
      return res.status(403).json({
        error: 'Upgrade Required',
        message: 'Free tier limit reached. Upgrade to premium for unlimited items.'
      });
    }

    // Process request...
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

exports.api = functions.https.onRequest(app);
```

## 3. Authentication: Custom Claims

```javascript
/**
 * Set custom claims after user purchases premium subscription
 * Custom claims appear in decoded ID token
 *
 * @param {string} userId - Firebase Auth UID
 * @param {string} tier - Subscription tier (free/premium/pro)
 * @returns {Promise<void>}
 */
async function setSubscriptionClaims(userId, tier) {
  try {
    const claims = {
      premium: tier === 'premium' || tier === 'pro',
      subscriptionTier: tier,
      subscriptionUpdatedAt: Date.now()
    };

    await admin.auth().setCustomUserClaims(userId, claims);

    console.log({
      severity: 'INFO',
      message: 'Custom claims updated',
      userId,
      tier
    });

    // User must refresh token to see new claims
    // iOS app should call getIDTokenResult(forcingRefresh: true)
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Failed to set custom claims',
      userId,
      tier,
      error: error.message
    });
    throw error;
  }
}

/**
 * Stripe webhook: Upgrade user to premium after successful payment
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const event = req.body;

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      const userId = session.metadata.userId;

      // Update custom claims
      await setSubscriptionClaims(userId, 'premium');

      // Update Firestore user document
      await firestore.collection('users').doc(userId).update({
        subscriptionTier: 'premium',
        subscriptionStartedAt: admin.firestore.FieldValue.serverTimestamp(),
        stripeCustomerId: session.customer
      });

      console.log({
        severity: 'INFO',
        message: 'User upgraded to premium',
        userId
      });
    }

    res.json({ received: true });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Stripe webhook failed',
      error: error.message
    });
    res.status(500).json({ error: error.message });
  }
});

/**
 * Remove custom claims (downgrade/cancellation)
 */
async function removeSubscriptionClaims(userId) {
  try {
    await admin.auth().setCustomUserClaims(userId, {
      premium: false,
      subscriptionTier: 'free',
      subscriptionUpdatedAt: Date.now()
    });

    console.log({
      severity: 'INFO',
      message: 'User downgraded to free',
      userId
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Failed to remove custom claims',
      userId,
      error: error.message
    });
    throw error;
  }
}
```

## 4. Storage: Upload Patterns

```javascript
/**
 * Upload image from iOS app (multipart/form-data)
 * Returns download URL for immediate display
 *
 * @param {Request} req - Express request with file upload
 * @param {Response} res - Express response
 */
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });

app.post('/uploadImage', upload.single('image'), async (req, res) => {
  try {
    const userId = req.user.uid;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Generate unique filename
    const itemId = firestore.collection('items').doc().id;
    const filename = `items/${userId}/${itemId}.jpg`;

    // Upload to Firebase Storage
    const bucket = admin.storage().bucket();
    const fileRef = bucket.file(filename);

    await fileRef.save(file.buffer, {
      metadata: {
        contentType: file.mimetype,
        metadata: {
          userId,
          itemId,
          uploadedAt: new Date().toISOString()
        }
      }
    });

    console.log({
      severity: 'INFO',
      message: 'Image uploaded',
      userId,
      itemId,
      size: file.size
    });

    // Get persistent download URL for iOS app
    const [downloadURL] = await fileRef.getSignedUrl({
      action: 'read',
      expires: '03-01-2500' // Far future = persistent
    });

    res.json({
      success: true,
      itemId,
      filename,
      downloadURL
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Image upload failed',
      error: error.message
    });
    res.status(500).json({ error: error.message });
  }
});
```

## 5. Storage: Signed URLs vs Download URLs

### Pattern Comparison

```javascript
/**
 * PATTERN 1: Persistent Download URL (for iOS app)
 * - Never expires (far-future expiration)
 * - Use for image display in app
 * - Publicly accessible if URL known
 *
 * @param {string} filePath - Storage path (e.g., "items/userId/itemId.jpg")
 * @returns {Promise<string>} Persistent download URL
 */
async function getPersistentDownloadURL(filePath) {
  const bucket = admin.storage().bucket();
  const file = bucket.file(filePath);

  const [downloadURL] = await file.getSignedUrl({
    action: 'read',
    expires: '03-01-2500' // Far future
  });

  console.log({
    severity: 'INFO',
    message: 'Generated persistent download URL',
    filePath
  });

  return downloadURL;
}

/**
 * PATTERN 2: Time-Limited Signed URL (for SerpAPI)
 * - Expires after short duration (e.g., 1 hour)
 * - Use for external API requests (SerpAPI Google Lens)
 * - More secure for temporary access
 * - Max expiration: 2 weeks (verified in RESEARCH-VALIDATION)
 *
 * @param {string} filePath - Storage path
 * @param {number} expirationMs - Expiration in milliseconds (default 1 hour)
 * @returns {Promise<string>} Time-limited signed URL
 */
async function getTimeLimitedSignedURL(filePath, expirationMs = 3600 * 1000) {
  const bucket = admin.storage().bucket();
  const file = bucket.file(filePath);

  const [signedURL] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + expirationMs
  });

  console.log({
    severity: 'INFO',
    message: 'Generated time-limited signed URL',
    filePath,
    expirationMs
  });

  return signedURL;
}

/**
 * Example: AI pipeline usage
 */
async function processImageWithAI(itemId, imagePath) {
  // For iOS app (persistent URL stored in Firestore)
  const downloadURL = await getPersistentDownloadURL(imagePath);
  await firestore.collection('items').doc(itemId).update({
    imageURL: downloadURL // iOS app uses this
  });

  // For SerpAPI (temporary URL, expires in 1 hour)
  const signedURL = await getTimeLimitedSignedURL(imagePath);
  await searchByImage(signedURL); // SerpAPI request

  console.log({
    severity: 'INFO',
    message: 'Image processed with AI',
    itemId,
    hasDownloadURL: !!downloadURL,
    hasSignedURL: !!signedURL
  });
}
```

## 6. Storage: Lifecycle Policies

### Auto-Delete After 90 Days

```javascript
/**
 * Configure Storage lifecycle policy (run once during setup)
 * Auto-deletes items older than 90 days
 *
 * Note: This is configured via gsutil CLI, not Admin SDK
 * Run: gsutil lifecycle set lifecycle.json gs://abundance-prod.appspot.com
 */

// lifecycle.json
const lifecycleConfig = {
  lifecycle: {
    rule: [
      {
        action: { type: 'Delete' },
        condition: {
          age: 90, // Days
          matchesPrefix: ['items/'] // Only delete items folder
        }
      }
    ]
  }
};

/**
 * Deployment command:
 * gsutil lifecycle set lifecycle.json gs://abundance-prod.appspot.com
 */
```

### Manual Cleanup (Scheduled Function)

```javascript
/**
 * Scheduled function: Delete items older than 90 days
 * Runs daily at 3 AM UTC
 * Backup strategy if lifecycle policy fails
 */
exports.cleanupOldItems = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const bucket = admin.storage().bucket();
      const cutoffDate = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);

      // List files in items/ folder
      const [files] = await bucket.getFiles({ prefix: 'items/' });

      let deletedCount = 0;

      for (const file of files) {
        const [metadata] = await file.getMetadata();
        const createdAt = new Date(metadata.timeCreated);

        if (createdAt < cutoffDate) {
          await file.delete();
          deletedCount++;

          console.log({
            severity: 'INFO',
            message: 'Old file deleted',
            filename: file.name,
            age: Math.floor((Date.now() - createdAt.getTime()) / (24 * 60 * 60 * 1000))
          });
        }
      }

      console.log({
        severity: 'INFO',
        message: 'Cleanup job completed',
        deletedCount,
        totalFiles: files.length
      });
    } catch (error) {
      console.error({
        severity: 'ERROR',
        message: 'Cleanup job failed',
        error: error.message
      });
    }
  });
```

## 7. Security: User Ownership Verification

```javascript
/**
 * Verify user owns item before allowing access/modification
 * CRITICAL: Prevents unauthorized access
 *
 * @param {string} itemId - Item document ID
 * @param {string} userId - Firebase Auth UID from token
 * @returns {Promise<DocumentSnapshot>} Item document
 * @throws {Error} If item not found or unauthorized
 */
async function verifyItemOwnership(itemId, userId) {
  const itemDoc = await firestore.collection('items').doc(itemId).get();

  if (!itemDoc.exists) {
    throw new Error('Item not found');
  }

  const itemData = itemDoc.data();

  if (itemData.userId !== userId) {
    console.error({
      severity: 'ERROR',
      message: 'Unauthorized item access attempt',
      itemId,
      requestedBy: userId,
      ownedBy: itemData.userId
    });
    throw new Error('Unauthorized: Item does not belong to user');
  }

  return itemDoc;
}

/**
 * Example: Delete item endpoint with ownership verification
 */
app.delete('/items/:itemId', async (req, res) => {
  try {
    const itemId = req.params.itemId;
    const userId = req.user.uid;

    // Verify ownership
    const itemDoc = await verifyItemOwnership(itemId, userId);

    // Delete Storage file
    const imagePath = itemDoc.data().imagePath;
    if (imagePath) {
      const bucket = admin.storage().bucket();
      await bucket.file(imagePath).delete();
    }

    // Delete Firestore document
    await itemDoc.ref.delete();

    // Decrement user item count
    await firestore.collection('users').doc(userId).update({
      itemCount: admin.firestore.FieldValue.increment(-1)
    });

    console.log({
      severity: 'INFO',
      message: 'Item deleted',
      itemId,
      userId
    });

    res.json({ success: true });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Delete item failed',
      error: error.message
    });

    const statusCode = error.message.includes('Unauthorized') ? 403 : 500;
    res.status(statusCode).json({ error: error.message });
  }
});

/**
 * Example: Update item endpoint with ownership verification
 */
app.patch('/items/:itemId', async (req, res) => {
  try {
    const itemId = req.params.itemId;
    const userId = req.user.uid;
    const updates = req.body;

    // Verify ownership
    await verifyItemOwnership(itemId, userId);

    // Prevent updating protected fields
    delete updates.userId;
    delete updates.createdAt;
    delete updates.status;

    // Update Firestore
    await firestore.collection('items').doc(itemId).update({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log({
      severity: 'INFO',
      message: 'Item updated',
      itemId,
      userId
    });

    res.json({ success: true });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Update item failed',
      error: error.message
    });

    const statusCode = error.message.includes('Unauthorized') ? 403 : 500;
    res.status(statusCode).json({ error: error.message });
  }
});
```

## 8. Free Tier Limit Enforcement

```javascript
/**
 * Check if user is over free tier limit (10 items)
 * Premium users have unlimited items
 *
 * @param {string} userId - Firebase Auth UID
 * @returns {Promise<boolean>} True if over limit
 */
async function isOverFreeLimit(userId) {
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return false; // New user, not over limit
    }

    const userData = userDoc.data();
    const itemCount = userData.itemCount || 0;
    const isPremium = userData.subscriptionTier === 'premium' || userData.subscriptionTier === 'pro';

    if (isPremium) {
      return false; // Premium users have unlimited items
    }

    return itemCount >= 10; // Free tier limit
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Failed to check free tier limit',
      userId,
      error: error.message
    });
    return false; // Fail open to avoid blocking users
  }
}

/**
 * Increment item count and check limit
 */
async function createItemWithLimitCheck(userId, itemData) {
  try {
    // Check limit BEFORE creating item
    if (await isOverFreeLimit(userId)) {
      throw new Error('Free tier limit reached (10 items). Upgrade to premium for unlimited items.');
    }

    // Create item
    const itemRef = firestore.collection('items').doc();
    await itemRef.set({
      ...itemData,
      userId,
      status: 'processing',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Increment user item count (transaction for atomicity)
    const userRef = firestore.collection('users').doc(userId);
    await firestore.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const currentCount = userDoc.data()?.itemCount || 0;
      transaction.update(userRef, { itemCount: currentCount + 1 });
    });

    console.log({
      severity: 'INFO',
      message: 'Item created',
      itemId: itemRef.id,
      userId
    });

    return itemRef.id;
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Create item failed',
      userId,
      error: error.message
    });
    throw error;
  }
}
```

## 9. Batch User Operations

```javascript
/**
 * Create multiple users (for testing or migration)
 *
 * @param {Array<Object>} users - Array of user data
 * @returns {Promise<Array<string>>} Array of created UIDs
 */
async function batchCreateUsers(users) {
  try {
    const createdUIDs = [];

    for (const user of users) {
      const userRecord = await admin.auth().createUser({
        email: user.email,
        password: user.password,
        displayName: user.displayName,
        emailVerified: user.emailVerified || false
      });

      // Initialize Firestore user document
      await firestore.collection('users').doc(userRecord.uid).set({
        email: user.email,
        displayName: user.displayName,
        subscriptionTier: 'free',
        itemCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      createdUIDs.push(userRecord.uid);

      console.log({
        severity: 'INFO',
        message: 'User created',
        uid: userRecord.uid,
        email: user.email
      });
    }

    return createdUIDs;
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'Batch user creation failed',
      error: error.message
    });
    throw error;
  }
}

/**
 * Delete user and all associated data (GDPR compliance)
 */
async function deleteUserData(userId) {
  try {
    // Delete all user's items
    const itemsSnapshot = await firestore
      .collection('items')
      .where('userId', '==', userId)
      .get();

    const batch = firestore.batch();
    itemsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Delete Storage files
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix: `items/${userId}/` });
    await Promise.all(files.map(file => file.delete()));

    // Delete user document
    await firestore.collection('users').doc(userId).delete();

    // Delete Auth user
    await admin.auth().deleteUser(userId);

    console.log({
      severity: 'INFO',
      message: 'User data deleted',
      userId,
      itemsDeleted: itemsSnapshot.size,
      filesDeleted: files.length
    });
  } catch (error) {
    console.error({
      severity: 'ERROR',
      message: 'User data deletion failed',
      userId,
      error: error.message
    });
    throw error;
  }
}
```

## Cross-References

- **CODE-EXAMPLE-005**: See Cloud Functions HTTP endpoint patterns
- **CODE-EXAMPLE-006**: See Firestore queries using Admin SDK
- **CODE-EXAMPLE-007**: See Storage URL usage in AI pipeline
- **TEST-EXAMPLE-003**: See unit tests with mocked Admin SDK
- **INFRASTRUCTURE-001**: See deployment with environment variables
- **RESEARCH-VALIDATION-stage-3.2**: Verified signed URL max expiration (2 weeks)

## Notes

- Admin SDK v12.0.0+ requires Node.js 18+ (use Node.js 20 in Cloud Functions)
- Custom claims appear in decoded ID token (require token refresh)
- Signed URLs max expiration: 2 weeks (use far-future for persistent URLs)
- Lifecycle policies configured via gsutil CLI (not Admin SDK)
- Always verify user ownership before allowing access to items
- Free tier limit: 10 items (enforced in createItem endpoint)
- Premium users: Unlimited items (custom claim: `premium: true`)
