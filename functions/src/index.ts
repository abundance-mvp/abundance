import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Health check endpoint (no auth required)
export const health = functions.https.onRequest((req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'abundance-backend'
  });
});

// Get user profile (auth required)
export const getUserProfile = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be signed in'
    );
  }

  const userId = context.auth.uid;

  // Fetch user document from Firestore
  const userDoc = await admin.firestore().collection('users').doc(userId).get();

  if (!userDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User profile not found');
  }

  return userDoc.data();
});
