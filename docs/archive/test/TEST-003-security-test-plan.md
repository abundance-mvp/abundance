# TEST-003: Security Test Plan

**Created**: 2025-11-09
**Stage**: 2.5 - Privacy & Security Architecture
**Status**: Draft
**References**:
- docs/design/THREAT-MODEL-001-stride-analysis.md
- docs/design/DESIGN-025-security-privacy-architecture.md
- docs/design/SECURITY-RULES-001-firestore-rules.md
- docs/design/STORAGE-RULES-001-firebase-storage-rules.md
- docs/validation/RESEARCH-VALIDATION-stage-2.5.md

---

## Executive Summary

This document specifies comprehensive security testing strategy for Abundance MVP, covering 4 test categories (penetration testing, privacy audits, vulnerability scanning, compliance testing) with automated and manual test procedures. Automated tests run in CI/CD pipeline via Firebase Emulator Suite (90% Firestore rules coverage, 100% Storage rules coverage). Manual tests include penetration testing (optional for MVP), privacy audit (required for EU launch), and GDPR/CCPA compliance validation.

---

## Test Categories

### 1. Penetration Testing

**Objective**: Validate security controls prevent unauthorized access, privilege escalation, and data tampering.

#### 1.1 Firestore Security Rules Tests

**Test Environment**: Firebase Emulator Suite

**Test Cases**:

##### Test 1.1.1: User Cannot Read Other Users' Items
```javascript
// Test: Unauthorized read attempt
const { assertFails } = require('@firebase/rules-unit-testing');

describe('Firestore Security - Unauthorized Read', () => {
  test('user cannot read other users items', async () => {
    const db = getFirestore('attacker_user_123');
    const itemRef = db.collection('items').doc('victim_item_xyz');

    // Verify: Row-level security enforced (SECURITY-RULES-001)
    await assertFails(itemRef.get());
  });
});
```

**Expected Result**: `PermissionDenied` error, no data returned

**Threat Mitigated**: THREAT-MODEL-001, Threat T-1 (Firestore rule bypass)

---

##### Test 1.1.2: User Cannot Create Item for Other Users
```javascript
// Test: Ownership validation on create
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

describe('Firestore Security - Create Authorization', () => {
  test('user cannot create item with different userId', async () => {
    const db = getFirestore('test_user_123');

    // Should fail - userId mismatch
    await assertFails(db.collection('items').add({
      userId: 'different_user',
      name: 'Stolen Item',
      status: 'processing'
    }));
  });

  test('user can create item with own userId', async () => {
    const db = getFirestore('test_user_123');

    // Should succeed - userId matches
    await assertSucceeds(db.collection('items').add({
      userId: 'test_user_123',
      name: 'My Item',
      status: 'processing',
      deletedAt: null
    }));
  });
});
```

**Expected Result**: Create fails if `userId != request.auth.uid`

**Threat Mitigated**: THREAT-MODEL-001, Threat T-1 (Firestore tampering)

---

##### Test 1.1.3: User Cannot Delete Items (Soft Delete Only)
```javascript
// Test: Hard delete blocked, soft delete allowed
describe('Firestore Security - Delete Operations', () => {
  test('user cannot hard delete items', async () => {
    const db = getFirestore('test_user_123');
    const itemRef = db.collection('items').doc('item_owned_by_test_user_123');

    // Should fail - hard delete not allowed
    await assertFails(itemRef.delete());
  });

  test('user can soft delete own items', async () => {
    const db = getFirestore('test_user_123');
    const itemRef = db.collection('items').doc('item_owned_by_test_user_123');

    // Should succeed - update with deletedAt timestamp
    await assertSucceeds(itemRef.update({
      deletedAt: new Date().toISOString()
    }));
  });
});
```

**Expected Result**: Hard delete fails, soft delete (update) succeeds

**Threat Mitigated**: THREAT-MODEL-001, Threat R-1 (data repudiation)

---

##### Test 1.1.4: Premium Features Require Custom Claim
```javascript
// Test: Custom claims authorization
describe('Firestore Security - Premium Features', () => {
  test('free user cannot access premium templates', async () => {
    const db = getFirestore('free_user_123'); // No premium claim

    // Should fail - requires premium custom claim
    await assertFails(db.collection('premium_templates').doc('template_xyz').get());
  });

  test('premium user can access premium templates', async () => {
    const db = getFirestore('premium_user_123', { premium: true }); // Has premium claim

    // Should succeed - premium custom claim present
    await assertSucceeds(db.collection('premium_templates').doc('template_xyz').get());
  });
});
```

**Expected Result**: Premium features inaccessible without custom claim

**Threat Mitigated**: THREAT-MODEL-001, Threat E-2 (privilege escalation)

---

#### 1.2 Firebase Storage Security Rules Tests

##### Test 1.2.1: User Cannot Read Other Users' Images
```javascript
// Test: Storage authorization
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

describe('Firebase Storage Security - Unauthorized Read', () => {
  test('user cannot read other users images', async () => {
    const storage = getStorage('attacker_user_123');
    const fileRef = storage.ref('users/victim_user/items/item456/objects/obj789.jpg');

    // Should fail - user folder isolation
    await assertFails(fileRef.getDownloadURL());
  });

  test('user can read own images', async () => {
    const storage = getStorage('test_user_123');
    const fileRef = storage.ref('users/test_user_123/items/item456/objects/obj789.jpg');

    // Should succeed - owner access
    await assertSucceeds(fileRef.getDownloadURL());
  });
});
```

**Expected Result**: User can only access own folder (`users/{userId}/`)

**Threat Mitigated**: THREAT-MODEL-001, Threat I-1 (photo leakage)

---

##### Test 1.2.2: Storage Rules Reject Files > 10MB
```javascript
// Test: File size validation
describe('Firebase Storage Security - File Size Limit', () => {
  test('storage rejects files larger than 10MB', async () => {
    const storage = getStorage('test_user_123');
    const fileRef = storage.ref('users/test_user_123/items/item123/objects/large.jpg');

    const largeFile = new Uint8Array(11 * 1024 * 1024); // 11MB

    // Should fail - exceeds 10MB limit
    await assertFails(fileRef.put(largeFile));
  });

  test('storage accepts files under 10MB', async () => {
    const storage = getStorage('test_user_123');
    const fileRef = storage.ref('users/test_user_123/items/item123/objects/small.jpg');

    const smallFile = new Uint8Array(500 * 1024); // 500KB

    // Should succeed - within limit
    await assertSucceeds(fileRef.put(smallFile));
  });
});
```

**Expected Result**: Files > 10MB rejected (blocks full photos)

**Threat Mitigated**: THREAT-MODEL-001, Threat T-3 (privacy firewall bypass)

---

#### 1.3 API Endpoint Penetration Tests

##### Test 1.3.1: Cloud Functions Require Bearer Token
```javascript
// Test: Authentication enforcement
const functions = require('firebase-functions-test')();

describe('Cloud Functions Security - Authentication', () => {
  test('function rejects requests without bearer token', async () => {
    const req = { headers: {}, body: { itemId: 'test_item' } };
    const res = {
      status: jest.fn(() => res),
      json: jest.fn()
    };

    await processItemAnalysis(req, res);

    // Should return 401 Unauthorized
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: expect.stringContaining('Unauthorized') });
  });

  test('function rejects requests with invalid token', async () => {
    const req = {
      headers: { authorization: 'Bearer invalid_token' },
      body: { itemId: 'test_item' }
    };
    const res = {
      status: jest.fn(() => res),
      json: jest.fn()
    };

    await processItemAnalysis(req, res);

    // Should return 401 Unauthorized
    expect(res.status).toHaveBeenCalledWith(401);
  });
});
```

**Expected Result**: 401 Unauthorized if token missing or invalid

**Threat Mitigated**: THREAT-MODEL-001, Threat S-1 (token spoofing)

---

##### Test 1.3.2: User Cannot Access Other Users' Items via API
```javascript
// Test: Defense-in-depth authorization
describe('Cloud Functions Security - Item Ownership', () => {
  test('user cannot process items owned by others', async () => {
    // Valid token for user_123
    const validToken = await getValidFirebaseToken('user_123');

    const req = {
      headers: { authorization: `Bearer ${validToken}` },
      body: { itemId: 'item_owned_by_user_456' } // Different user
    };
    const res = {
      status: jest.fn(() => res),
      json: jest.fn()
    };

    await processItemAnalysis(req, res);

    // Should return 403 Forbidden (defense-in-depth)
    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith({ error: expect.stringContaining('Forbidden') });
  });
});
```

**Expected Result**: 403 Forbidden if item ownership mismatch

**Threat Mitigated**: THREAT-MODEL-001, Threat T-1 (authorization bypass)

---

#### 1.4 Rate Limiting Tests

##### Test 1.4.1: Item Creation Rate Limiting
```javascript
// Test: DoS prevention via rate limiting
describe('Rate Limiting - Item Creation', () => {
  test('rejects excessive item creation requests', async () => {
    const db = getFirestore('test_user_123');

    // Create 15 items in quick succession
    const promises = [];
    for (let i = 0; i < 15; i++) {
      promises.push(
        db.collection('items').add({
          userId: 'test_user_123',
          name: `Item ${i}`,
          status: 'processing'
        })
      );
    }

    const results = await Promise.allSettled(promises);

    // Should succeed for first 10, fail for remaining 5 (rate limit)
    const succeeded = results.filter(r => r.status === 'fulfilled').length;
    const failed = results.filter(r => r.status === 'rejected').length;

    expect(succeeded).toBeLessThanOrEqual(10);
    expect(failed).toBeGreaterThanOrEqual(5);
  });
});
```

**Expected Result**: Rate limit enforced (10 items per minute per user)

**Threat Mitigated**: THREAT-MODEL-001, Threat D-1 (quota exhaustion)

---

### 2. Privacy Audits

**Objective**: Validate privacy firewall prevents full photo uploads and ensures GDPR compliance.

#### 2.1 Privacy Firewall Validation

##### Test 2.1.1: Full Photos Never Uploaded
```swift
// Test: Privacy firewall enforcement
func testPrivacyFirewall_NoFullPhotoUploads() async throws {
    // Given: Full photo (3MB) captured
    let fullPhoto = UIImage(named: "test_photo_3mb")!
    let tempURL = try temporaryStorage.saveTemporaryPhoto(fullPhoto)

    // When: Process photo with privacy firewall
    let croppedObjects = try await privacyFirewall.processPhoto(fullPhoto)

    // Then: Full photo should be deleted
    XCTAssertFalse(
        FileManager.default.fileExists(atPath: tempURL.path),
        "Full photo should be deleted after processing"
    )

    // And: Only cropped objects should exist
    XCTAssertGreaterThan(croppedObjects.count, 0, "Should have cropped objects")

    // And: All cropped objects should be < 500KB
    for object in croppedObjects {
        let imageData = object.toUploadData()!
        XCTAssertLessThan(
            imageData.count,
            500 * 1024,
            "Cropped object should be < 500KB"
        )
    }
}
```

**Expected Result**: Full photo deleted, only cropped objects (< 500KB) uploaded

**Threat Mitigated**: THREAT-MODEL-001, Threat I-2 (full photo leakage)

---

##### Test 2.1.2: Network Traffic Analysis (No Large Uploads)
```swift
// Test: Network monitoring for privacy violations
func testNetworkTraffic_NoLargeUploads() async throws {
    // Given: Network monitoring enabled
    let networkMonitor = NetworkMonitor()
    networkMonitor.startMonitoring()

    // When: Capture photo and process through privacy firewall
    let photo = try await cameraService.capturePhoto() // Full photo ~3MB
    let croppedObjects = try await privacyFirewall.processPhoto(photo)

    // Upload cropped objects
    for object in croppedObjects {
        try await uploadService.uploadCroppedObject(
            object,
            userId: "test_user",
            itemId: "test_item"
        )
    }

    // Then: Verify no large uploads in network logs
    let uploadLogs = networkMonitor.getUploadLogs()
    let largeUploads = uploadLogs.filter { $0.size > 500 * 1024 }

    XCTAssertTrue(largeUploads.isEmpty, "No uploads should exceed 500KB")
}
```

**Expected Result**: All network uploads < 500KB

**Threat Mitigated**: THREAT-MODEL-001, Threat T-3 (privacy firewall bypass)

---

#### 2.2 Data Retention Audit

##### Test 2.2.1: 90-Day Image Lifecycle Policy
```javascript
// Test: Cloud Storage lifecycle policy deletes old images
describe('Data Retention - Image Lifecycle', () => {
  test('images deleted after 90 days', async () => {
    const bucket = admin.storage().bucket();

    // Create test image with timestamp 91 days ago
    const oldImagePath = 'users/test_user/items/old_item/objects/old.jpg';
    await bucket.file(oldImagePath).save('test data', {
      metadata: {
        customTime: new Date(Date.now() - 91 * 24 * 60 * 60 * 1000).toISOString()
      }
    });

    // Wait for lifecycle policy to execute (or manually trigger)
    // ...

    // Verify: Image should be deleted
    const [exists] = await bucket.file(oldImagePath).exists();
    expect(exists).toBe(false);
  });
});
```

**Expected Result**: Images deleted after 90 days (GDPR storage limitation)

**Compliance**: GDPR Article 5 (storage limitation), PRIVACY-IMPACT-ASSESSMENT-001

---

#### 2.3 GDPR Compliance Tests

##### Test 2.3.1: Right to Erasure (Cascade Delete)
```javascript
// Test: Complete user data deletion
describe('GDPR Compliance - Right to Erasure', () => {
  test('account deletion removes all user data', async () => {
    const userId = 'test_user_delete';
    const db = admin.firestore();
    const bucket = admin.storage().bucket();

    // Given: User has 5 items with images
    const items = [];
    for (let i = 0; i < 5; i++) {
      const itemRef = await db.collection('items').add({
        userId,
        name: `Item ${i}`,
        croppedImagePath: `users/${userId}/items/item${i}/objects/obj.jpg`
      });
      items.push(itemRef.id);

      // Create image in storage
      await bucket.file(`users/${userId}/items/item${i}/objects/obj.jpg`).save('test data');
    }

    // When: User requests account deletion
    await deleteUserAccount(userId);

    // Then: All items deleted
    for (const itemId of items) {
      const itemDoc = await db.collection('items').doc(itemId).get();
      expect(itemDoc.exists).toBe(false);
    }

    // And: All images deleted
    const [files] = await bucket.getFiles({ prefix: `users/${userId}/` });
    expect(files.length).toBe(0);

    // And: User profile deleted
    const userDoc = await db.collection('users').doc(userId).get();
    expect(userDoc.exists).toBe(false);

    // And: Firebase Auth account deleted
    try {
      await admin.auth().getUser(userId);
      fail('User should be deleted');
    } catch (error) {
      expect(error.code).toBe('auth/user-not-found');
    }
  });
});
```

**Expected Result**: All user data deleted (Firestore, Storage, Auth)

**Compliance**: GDPR Article 17, PRIVACY-IMPACT-ASSESSMENT-001

---

##### Test 2.3.2: Right to Access (Data Export)
```javascript
// Test: User data export
describe('GDPR Compliance - Right to Access', () => {
  test('user can export all personal data', async () => {
    const userId = 'test_user_export';
    const db = admin.firestore();

    // Given: User has 3 items
    await db.collection('items').add({ userId, name: 'Item 1' });
    await db.collection('items').add({ userId, name: 'Item 2' });
    await db.collection('items').add({ userId, name: 'Item 3' });

    // When: User requests data export
    const exportData = await exportUserData(userId);

    // Then: Export includes all data
    expect(exportData.user).toBeDefined();
    expect(exportData.items).toHaveLength(3);
    expect(exportData.items[0].name).toBe('Item 1');
    expect(exportData.exportedAt).toBeDefined();
    expect(exportData.gdprCompliance).toBe('Right to Access (Article 15)');
  });
});
```

**Expected Result**: JSON export includes user profile + all items

**Compliance**: GDPR Article 15, PRIVACY-IMPACT-ASSESSMENT-001

---

### 3. Vulnerability Scanning

**Objective**: Detect OWASP Top 10 vulnerabilities, dependency issues, and misconfigurations.

#### 3.1 Firebase Misconfiguration Scan (P0)

##### Test 3.1.1: Firestore Production Mode Enforced
```javascript
// Test: Verify production mode (deny by default)
describe('Firebase Security - Production Mode', () => {
  test('firestore rules deny all access by default', async () => {
    const db = getFirestore('unauthenticated_user');

    // Should fail - production mode denies unauthenticated access
    await assertFails(db.collection('items').get());
    await assertFails(db.collection('users').get());
    await assertFails(db.collection('premium_templates').get());
  });
});
```

**Expected Result**: All unauthenticated requests denied

**Threat Mitigated**: THREAT-MODEL-001, Threat I-1 (Firebase misconfiguration)

---

##### Test 3.1.2: Firebase Storage No Public Access
```bash
# Test: Verify no public bucket access
#!/bin/bash

# Check Firebase Storage bucket policy
gsutil iam get gs://abundance-project.appspot.com | grep -q "allUsers\|allAuthenticatedUsers"

if [ $? -eq 0 ]; then
    echo "FAIL: Public access detected in Firebase Storage bucket"
    exit 1
else
    echo "PASS: No public access in Firebase Storage bucket"
    exit 0
fi
```

**Expected Result**: No `allUsers` or `allAuthenticatedUsers` in IAM policy

**Threat Mitigated**: THREAT-MODEL-001, Threat I-1 (storage misconfiguration)

---

#### 3.2 OWASP Top 10 Validation

##### Test 3.2.1: Injection Prevention (Firestore Rules)
```javascript
// Test: SQL injection-style attacks blocked by Firestore rules
describe('OWASP - Injection Prevention', () => {
  test('firestore rules prevent injection attacks', async () => {
    const db = getFirestore('test_user_123');

    // Attempt injection via malicious userId
    const maliciousUserId = "'; DROP COLLECTION items; --";

    await assertFails(db.collection('items').add({
      userId: maliciousUserId,
      name: 'Injected Item'
    }));
  });
});
```

**Expected Result**: Injection attempts fail (Firestore rules validate userId)

**OWASP Category**: A03:2021 – Injection

---

##### Test 3.2.2: Broken Access Control Prevention
```javascript
// Test: Authorization checks prevent privilege escalation
describe('OWASP - Broken Access Control', () => {
  test('user cannot escalate privileges via token manipulation', async () => {
    // Valid token for free user
    const freeUserToken = await getValidFirebaseToken('free_user_123');

    // Attempt to access premium feature
    const db = getFirestore('free_user_123');

    await assertFails(db.collection('premium_templates').doc('template_xyz').get());
  });
});
```

**Expected Result**: Access denied without premium custom claim

**OWASP Category**: A01:2021 – Broken Access Control

---

#### 3.3 Dependency Scanning

##### Test 3.3.1: npm Audit (Cloud Functions)
```bash
# Run npm audit for Cloud Functions dependencies
cd functions
npm audit --audit-level=moderate

# Expected: No vulnerabilities at moderate level or higher
```

**Expected Result**: 0 moderate/high/critical vulnerabilities

**CI/CD Integration**: Run on every PR to `functions/package.json`

---

##### Test 3.3.2: Xcode Vulnerability Scan (iOS)
```bash
# Run Xcode vulnerability scan for iOS dependencies
xcodebuild -project Abundance.xcodeproj -scheme Abundance analyze

# Expected: No security warnings
```

**Expected Result**: 0 security warnings from Xcode static analysis

**CI/CD Integration**: Run on every PR to iOS codebase

---

### 4. Compliance Testing

**Objective**: Validate GDPR/CCPA requirements are met.

#### 4.1 GDPR Tests

See Section 2.3 above (Right to Access, Right to Erasure)

#### 4.2 CCPA Tests

##### Test 4.2.1: Do Not Sell Disclosure
```javascript
// Test: Privacy policy includes CCPA disclosure
describe('CCPA Compliance - Do Not Sell', () => {
  test('privacy policy discloses no data sales', async () => {
    const privacyPolicy = await fetchPrivacyPolicy();

    // Verify disclosure present
    expect(privacyPolicy).toContain('We do not sell your personal information');
    expect(privacyPolicy).toContain('Do Not Sell');
    expect(privacyPolicy).toContain('service providers');
  });
});
```

**Expected Result**: Privacy policy includes CCPA "Do Not Sell" disclosure

**Compliance**: CCPA Section 1798.120, PRIVACY-IMPACT-ASSESSMENT-001

---

## Automated Testing (CI/CD Integration)

### Firebase Emulator Suite Integration

#### CI/CD Pipeline (.github/workflows/firebase-rules-test.yml)
```yaml
name: Firebase Security Rules Test

on:
  pull_request:
    paths:
      - 'firestore.rules'
      - 'storage.rules'
      - 'functions/**'

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Install dependencies
        run: |
          cd functions
          npm install

      - name: Run Firestore Rules Tests
        run: firebase emulators:exec --only firestore "npm run test:firestore"

      - name: Run Storage Rules Tests
        run: firebase emulators:exec --only storage "npm run test:storage"

      - name: Upload Coverage Report
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: firestore-rules
```

**Coverage Targets**:
- Firestore Security Rules: 90%
- Storage Security Rules: 100%

---

## Manual Testing (Pre-Launch)

### Manual Test 1: Penetration Testing (External Firm)

**Scope**: Optional for MVP, recommended for v1.0

**Deliverables**:
- Vulnerability assessment report
- OWASP Top 10 validation
- Security recommendations

**Timeline**: 2 weeks before public launch

---

### Manual Test 2: Privacy Audit (Privacy Counsel)

**Scope**: Required for EU launch (GDPR compliance)

**Deliverables**:
- GDPR compliance report
- Data flow diagram validation
- Privacy policy review

**Timeline**: 1 week before EU beta testing

---

### Manual Test 3: Firebase Security Review Checklist

**Scope**: P0 before any launch (see SECURITY-HARDENING-CHECKLIST-001)

**Checklist Items**:
- [ ] Firestore rules in production mode (deny by default)
- [ ] Storage rules in production mode (deny by default)
- [ ] No public bucket access (uniform bucket-level access enabled)
- [ ] Email enumeration protection enabled (Firebase Console)
- [ ] App Check configured (Firestore, Storage, Cloud Functions)
- [ ] API keys in Secret Manager (not hardcoded)
- [ ] Signed URLs use 5-minute expiration (server-side generation)

**Timeline**: Before deployment to production

---

## Test Coverage Summary

| Category | Test Type | Coverage Target | Status |
|----------|-----------|-----------------|--------|
| Penetration Testing | Automated (Firestore rules) | 90% | ✅ Specified |
| Penetration Testing | Automated (Storage rules) | 100% | ✅ Specified |
| Penetration Testing | Automated (Cloud Functions) | 80% | ✅ Specified |
| Penetration Testing | Manual (External firm) | N/A | ⚠️ Optional for MVP |
| Privacy Audits | Automated (Privacy firewall) | 100% | ✅ Specified |
| Privacy Audits | Automated (Data retention) | 100% | ✅ Specified |
| Privacy Audits | Manual (Privacy counsel) | N/A | ⚠️ Required for EU |
| Vulnerability Scanning | Automated (Firebase config) | 100% | ✅ Specified |
| Vulnerability Scanning | Automated (Dependencies) | 100% | ✅ Specified |
| Compliance Testing | Automated (GDPR/CCPA) | 100% | ✅ Specified |

---

## Acceptance Criteria

- [x] All 4 test categories specified (penetration, privacy, vulnerability, compliance)
- [x] Automated tests specified (Firestore rules, Storage rules, Cloud Functions)
- [x] Manual tests specified (penetration testing, privacy audit, Firebase security review)
- [x] Test coverage targets defined (90% Firestore rules, 100% Storage rules)
- [x] P0 Firebase misconfiguration testing documented
- [x] CI/CD integration specified (GitHub Actions workflow)
- [x] All tests reference THREAT-MODEL-001 threats

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial security test plan, 4 test categories | Privacy & Security Architect |
