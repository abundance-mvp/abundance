# SECURITY-RULES-001: Firestore Security Rules

**Created**: 2025-11-08
**Stage**: 2.3 - Backend Cloud Architecture
**Status**: Approved
**References**:
- docs/tech-stack/DATA-MODEL-001-firestore-schema.md
- docs/adr/ADR-005-authentication-strategy.md
- docs/adr/ADR-006-database-selection.md

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isPremium() {
      return isSignedIn() && request.auth.token.premium == true;
    }

    // Users collection: users can only read/write their own profile
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId) && request.resource.data.userId == userId;
      allow update: if isOwner(userId) && request.resource.data.userId == userId;
      allow delete: if false; // Users cannot delete their own accounts
    }

    // Items collection: users can only access their own items
    match /items/{itemId} {
      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;

      allow create: if isSignedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.status == 'processing'
        && request.resource.data.deletedAt == null;

      allow update: if isSignedIn()
        && resource.data.userId == request.auth.uid
        && request.resource.data.userId == resource.data.userId; // Can't change ownership

      allow delete: if false; // Soft delete only (via update)
    }

    // Subscriptions collection: read-only for users, write-only for Cloud Functions
    match /subscriptions/{subscriptionId} {
      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
      allow write: if false; // Only Cloud Functions can write via Admin SDK
    }
  }
}
```

---

## Testing

```javascript
// Firebase Emulator Suite test
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

describe('Firestore Security Rules', () => {
  test('user can read own items', async () => {
    const db = getFirestore('test_user_123');
    const itemRef = db.collection('items').doc('item_abc');
    await assertSucceeds(itemRef.get());
  });

  test('user cannot read other users items', async () => {
    const db = getFirestore('test_user_123');
    const itemRef = db.collection('items').doc('item_xyz'); // Different owner
    await assertFails(itemRef.get());
  });

  test('user can create item for themselves', async () => {
    const db = getFirestore('test_user_123');
    await assertSucceeds(db.collection('items').add({
      userId: 'test_user_123',
      name: 'Test',
      status: 'processing',
      deletedAt: null
    }));
  });

  test('user cannot create item for other users', async () => {
    const db = getFirestore('test_user_123');
    await assertFails(db.collection('items').add({
      userId: 'different_user',
      name: 'Test'
    }));
  });
});
```

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial Firestore security rules | Cloud Backend Architect |
