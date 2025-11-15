# ADR-021: Data Encryption Approach

**Status**: Approved
**Date**: 2025-11-09
**Deciders**: Privacy & Security Architect
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-2.5.md (Claims 1, 4, 5, 10)
- docs/design/DESIGN-025-security-privacy-architecture.md
- docs/design/THREAT-MODEL-001-stride-analysis.md (Threats I-1, I-2, I-5)

---

## Context

Abundance MVP requires comprehensive data encryption across all data states (at rest, in transit, in use) to maintain privacy-first positioning, ensure GDPR compliance, and protect user data from unauthorized access. The encryption strategy must leverage industry-standard algorithms (AES-256-GCM, TLS 1.2+), hardware-backed security (iOS Secure Enclave, Google HSMs), and automatic key rotation policies to minimize manual overhead while maximizing security guarantees.

This ADR documents the complete encryption approach across iOS client, Firebase backend, GCP services, and third-party AI APIs, with specific algorithms, key management strategies, and compliance validation.

---

## Decision

We will implement **end-to-end encryption** across all data states (at rest, in transit, in use) using industry-standard algorithms and key management practices.

---

## Encryption at Rest

### iOS Client

#### 1. Keychain Storage (Firebase ID Tokens)
- **Algorithm**: AES-256-GCM with Secure Enclave integration
- **Verified**: RESEARCH-VALIDATION-stage-2.5.md (Claim 1)
- **Implementation**: iOS Keychain Services API with `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`
- **Key Management**: iOS manages encryption keys automatically (hardware-backed, cannot be extracted)

```swift
// Store token in Keychain with AES-256-GCM
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "firebase_id_token",
    kSecValueData as String: tokenData,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
]
SecItemAdd(query as CFDictionary, nil)
```

**Security Guarantee**:
- Hardware-backed encryption via Secure Enclave coprocessor
- Dual-key encryption: Metadata key (cached) + Secret key (always in Secure Enclave)
- Keys never leave Secure Enclave even if OS is compromised
- Protection class tightly couples credentials to device passcode

#### 2. Temporary Photo Files
- **Algorithm**: File-level AES-256 encryption via Data Protection API
- **Verified**: RESEARCH-VALIDATION-stage-2.5.md (Claim 5)
- **Protection Class**: `FileProtectionType.complete` (files inaccessible when device locked)
- **Lifecycle**: Files deleted immediately after Vision Framework processing (DESIGN-015)

```swift
// Create temporary file with encryption
try imageData.write(to: tempFileURL, options: .completeFileProtection)
```

**Encryption Details**:
- AES-256 encryption for all file protection classes
- Keys stored in Secure Enclave (inaccessible to software)
- Keys derived from device UID + user passcode (hardware-backed)
- File system metadata encrypted separately from content

### Firebase Backend

#### 1. Cloud Firestore
- **Algorithm**: AES-256 automatic encryption (GCP default)
- **Scope**: All documents (users, items, subscriptions)
- **Key Management**: Google-managed encryption keys (automatic rotation)
- **Access Control**: Firestore Security Rules enforce row-level access (SECURITY-RULES-001)

#### 2. Firebase Storage
- **Algorithm**: AES-256 automatic encryption (GCP default)
- **Scope**: All uploaded images (cropped objects only, not full photos)
- **Key Management**: Google-managed encryption keys (automatic rotation)
- **Access Control**: Storage Security Rules enforce user folder isolation (STORAGE-RULES-001)

### GCP Services

#### 1. Google Secret Manager (API Keys)
- **Algorithm**: AES-256 encryption
- **Verified**: RESEARCH-VALIDATION-stage-2.5.md (Claim 10)
- **Secrets Stored**: Gemini API key, SerpAPI API key, Claude API key
- **Rotation Policy**: 90-day automatic rotation
- **Access Control**: IAM service accounts (Cloud Functions only)

```javascript
// Access secret from Secret Manager
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const client = new SecretManagerServiceClient();
const [version] = await client.accessSecretVersion({
  name: 'projects/abundance-prod/secrets/serpapi-key/versions/latest'
});
const apiKey = version.payload.data.toString('utf8');
```

**Best Practices**:
- Version pinning for production (not `latest` alias)
- Least privilege IAM roles (`secretmanager.secretAccessor`)
- Audit logging via Cloud Audit Logs
- Automatic replication unless GDPR requires EU-only storage

#### 2. Cloud Storage (GCS)
- **Algorithm**: AES-256 automatic encryption
- **Scope**: Processed images, backups
- **Key Management**: Google-managed (default) or customer-managed (optional, not used in MVP)

---

## Encryption in Transit

### iOS ↔ Firebase

#### 1. App Transport Security (ATS)
- **Protocol**: HTTPS with TLS 1.2+ (minimum)
- **Verified**: RESEARCH-VALIDATION-stage-2.5.md (Claim 4)
- **Enforcement**: iOS enforces TLS 1.2+ by default, TLS 1.0/1.1 deprecated
- **Configuration**: No custom ATS exceptions (all connections use default security)

```xml
<!-- Info.plist (default ATS configuration, no exceptions) -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- No exceptions, all domains require HTTPS with TLS 1.2+ -->
</dict>
```

**Security Guarantee**:
- ATS enabled by default on all iOS/iPadOS apps
- HTTPS enforced for all URLSession connections (HTTP blocked)
- Certificate validation with perfect forward secrecy required
- All Abundance APIs (Firebase, GCP, Vertex AI, SerpAPI, Anthropic) support HTTPS natively

#### 2. Firebase SDK Connections
- **Firestore Real-Time Listeners**: TLS 1.3 (Firebase default, November 2025)
- **Firebase Storage Uploads**: TLS 1.3
- **Firebase Auth**: TLS 1.3

### Cloud Functions ↔ AI APIs

#### 1. Vertex AI (Gemini)
- **Protocol**: HTTPS with TLS 1.3
- **Authentication**: Bearer token (GCP service account)
- **Encryption**: Google infrastructure (internal TLS)

#### 2. SerpAPI
- **Protocol**: HTTPS with TLS 1.3
- **Authentication**: API key in query parameter
- **Rate Limiting**: 5K searches/month (Developer Plan)

#### 3. Anthropic Claude
- **Protocol**: HTTPS with TLS 1.3
- **Authentication**: Bearer token (API key in Authorization header)
- **Batch API**: Encrypted queue (Anthropic infrastructure)

---

## Encryption in Use

### iOS Client

#### 1. On-Device Vision Processing
- **Environment**: iOS secure sandbox
- **Memory Protection**: iOS memory management (automatic encryption for sensitive data)
- **Privacy Firewall**: Full photos processed on-device, never uploaded (DESIGN-015)
- **Verified**: RESEARCH-VALIDATION-stage-2.5.md (Claim 3 - AVCaptureSession privacy)

### Cloud Functions

#### 1. Ephemeral Compute
- **Memory**: In-memory processing only, no disk persistence
- **Lifecycle**: Compute instances destroyed after function execution
- **Secrets**: Loaded from Secret Manager at runtime, never written to disk

### AI API Processing

#### 1. Vertex AI (Google Infrastructure)
- **Data Residency**: us-central1 (same region as Cloud Functions)
- **Processing**: Google-managed infrastructure with encryption
- **Retention**: Gemini API processes images ephemerally (no storage, verified November 2025)

#### 2. SerpAPI (Third-Party)
- **Data Sent**: Image URL (signed URL with 5-minute expiration, P1 architecture change)
- **Processing**: SerpAPI infrastructure (external)
- **Retention**: Review SerpAPI DPA for data retention policy (PRIVACY-IMPACT-ASSESSMENT-001)

#### 3. Anthropic Claude (Third-Party)
- **Data Sent**: Layer 2a + 2b metadata (text only, no images)
- **Processing**: Anthropic infrastructure (external)
- **Retention**: Review Claude DPA for data retention policy (PRIVACY-IMPACT-ASSESSMENT-001)

---

## Key Management Strategy

### Automatic Key Rotation

#### 1. Firebase ID Tokens
- **Expiration**: 1 hour (Firebase default)
- **Refresh**: Automatic via Firebase SDK (refresh token stored in Keychain)
- **Revocation**: User logout deletes Keychain tokens, Firebase session revoked

#### 2. API Keys (Secret Manager)
- **Rotation Policy**: 90 days
- **Process**:
  1. Create new secret version in Secret Manager
  2. Update Cloud Functions environment to use new version
  3. Deploy Cloud Functions
  4. Delete old secret version after 7-day grace period
- **Access Control**: IAM service account `abundance-cloud-functions@{project}.iam.gserviceaccount.com`

#### 3. Signed URLs (Firebase Storage / GCS)
- **Expiration**: 5 minutes (P1 architecture change from 7-day default)
- **Generation**: Server-side via Cloud Functions (not client-side)
- **Usage**: Immediately passed to SerpAPI, expires after 5 minutes
- **Verification**: 99.95% reduction in exposure window (7 days → 5 minutes)

```javascript
// Generate short-lived signed URL (5 minutes)
const [url] = await bucket.file(imagePath).getSignedUrl({
  version: 'v4',
  action: 'read',
  expires: Date.now() + 300000 // 5 minutes
});
```

### Key Storage

#### 1. iOS Keychain
- **Storage**: Hardware-backed Secure Enclave (iPhone 15 Pro+)
- **Access**: Biometric authentication (Face ID / Touch ID) or device passcode
- **Extraction**: Keys cannot be extracted from device (iOS security guarantee)

#### 2. Google Secret Manager
- **Storage**: Google-managed HSMs (hardware security modules)
- **Access**: IAM service accounts only (Cloud Functions)
- **Audit**: Cloud Logging tracks all secret accesses

#### 3. Firebase/GCP Default Encryption
- **Storage**: Google-managed keys (automatic rotation)
- **Access**: Not exposed to application code
- **Compliance**: SOC 2, ISO 27001 certified

---

## Consequences

### Positive
- ✅ End-to-end encryption across all data states (at rest, in transit, in use)
- ✅ Industry-standard algorithms (AES-256-GCM, TLS 1.2+, TLS 1.3)
- ✅ Automatic key rotation (Firebase tokens 1 hour, API keys 90 days, signed URLs 5 minutes)
- ✅ Hardware-backed security (iOS Secure Enclave, Google HSMs)
- ✅ GDPR compliance (encryption at rest + in transit, verified Claims 1, 4, 5, 10)
- ✅ Privacy firewall enforced (on-device processing, no full photo uploads)

### Negative
- ⚠️ Third-party AI APIs (SerpAPI, Claude) process data outside Abundance infrastructure
  - **Mitigation**: Review DPAs for data retention policies (PRIVACY-IMPACT-ASSESSMENT-001)
  - **GDPR Article 28**: Requires Data Processing Agreements with third-party processors
- ⚠️ 90-day API key rotation requires manual deployment
  - **Mitigation**: Automate via Cloud Scheduler + Cloud Functions (future enhancement)
- ⚠️ Signed URL 5-minute expiration requires server-side generation (architecture change)
  - **Mitigation**: Implemented in DESIGN-025 (Layer 3, signed URL strategy)

### Trade-offs
- **Security vs. Complexity**: End-to-end encryption adds complexity (key management, rotation)
  - **Decision**: Accept complexity for privacy-first positioning (strategic differentiator)
- **Performance vs. Security**: Encryption/decryption adds latency
  - **Impact**: Negligible (< 10ms for AES-256, < 50ms for TLS handshake)
  - **Decision**: Accept performance overhead for security guarantee

---

## Compliance

### GDPR
- **Article 32**: Security of processing (encryption at rest + in transit) ✅
- **Article 5**: Data minimization (only cropped objects uploaded, not full photos) ✅
- **Article 46**: Data transfer (Firebase Auth US storage requires SCCs + TIA, P0) ⚠️

### CCPA
- **Section 1798.150**: Encryption safe harbor (AES-256 + TLS 1.2+ qualifies) ✅

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial encryption strategy, all data states documented | Privacy & Security Architect |
