# THREAT-MODEL-001: STRIDE Analysis

**Created**: 2025-11-09
**Stage**: 2.5 - Privacy & Security Architecture
**Status**: Draft
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-2.5.md
- docs/plans/PLAN-SUMMARY-stage-2.5.md
- docs/design/DESIGN-015-privacy-architecture.md
- docs/design/SECURITY-RULES-001-firestore-rules.md
- docs/design/STORAGE-RULES-001-firebase-storage-rules.md

---

## Executive Summary

This threat model identifies 18 security threats across the Abundance MVP architecture using the STRIDE methodology (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege). Analysis covers all four architectural layers: iOS client, Firebase backend, GCP services, and third-party AI APIs. Two P0 security gaps (Firebase misconfiguration, GDPR data transfer) and two P1 gaps (signed URL expiration, email enumeration) are addressed with specific mitigations. All threats include risk assessment, likelihood analysis, mitigation strategies, and verification methods referenced against research validation claims.

---

## Methodology

STRIDE threat modeling framework:
- **S**poofing: Identity verification failures
- **T**ampering: Data integrity violations
- **R**epudiation: Lack of audit trails
- **I**nformation Disclosure: Privacy breaches
- **D**enial of Service: Availability attacks
- **E**levation of Privilege: Authorization bypasses

---

## Threat Catalog

### Spoofing Threats

#### Threat S-1: Firebase Auth Token Spoofing
- **STRIDE Category**: Spoofing
- **Attack Vector**: Attacker intercepts or forges Firebase ID token to impersonate legitimate user
- **Affected Component**: Firebase Authentication, Cloud Functions (ADR-023)
- **Current State**: Firebase ID tokens use JWT with cryptographic signatures (RS256), validated automatically by Firebase SDK
- **Risk Level**: Low
- **Likelihood**: Very Low (cryptographic signature validation prevents forgery, verified in RESEARCH-VALIDATION-stage-2.5.md, Claim 2)
- **Mitigation**:
  - Firebase SDK automatic token validation (RS256 signature verification)
  - TLS 1.2+ enforced via App Transport Security (verified Claim 4)
  - Token expiration: 1 hour (automatic refresh via Firebase SDK)
  - Certificate pinning option available via URLSessionDelegate (defense-in-depth)
  - Cloud Functions validate tokens via `admin.auth().verifyIdToken()`
- **Verification**: Integration test - attempt Cloud Function invocation with invalid token, assert 401 Unauthorized
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claims 2, 4, 11)

#### Threat S-2: Apple Sign-In Credential Replay
- **STRIDE Category**: Spoofing
- **Attack Vector**: Attacker captures and replays Apple Sign-In credentials from network traffic
- **Affected Component**: Apple Sign-In (ASAuthorizationController), Firebase Authentication
- **Current State**: OAuth 2.0 flow with nonce-based replay protection, TLS 1.2+ encryption in transit
- **Risk Level**: Low
- **Likelihood**: Low (OAuth 2.0 nonce prevents replay, TLS prevents interception, verified Claim 2)
- **Mitigation**:
  - OAuth 2.0 authorization code flow (single-use codes)
  - Nonce validation in Apple Sign-In response
  - TLS 1.2+ for all network requests (App Transport Security, verified Claim 4)
  - Apple ID two-factor authentication enforced for user accounts
  - Automatic credential revocation when user removes app access
- **Verification**: Integration test - attempt to reuse Apple Sign-In authorization code, assert failure
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claims 2, 4)

#### Threat S-3: Malicious App Spoofing Firebase Project
- **STRIDE Category**: Spoofing
- **Attack Vector**: Attacker creates fake app with Abundance's Firebase project credentials to access user data
- **Affected Component**: Firebase App Check, Firebase Authentication
- **Current State**: App Check optional for MVP (verified Claim 9), Firebase project credentials in iOS bundle
- **Risk Level**: Medium
- **Likelihood**: Medium (Firebase credentials extractable from iOS bundle, App Check not enforced)
- **Mitigation**:
  - Enable Firebase App Check for Firestore, Storage, Cloud Functions (P1 before launch)
  - iOS DeviceCheck and App Attest integration for attestation tokens
  - Monitor for unusual access patterns via Cloud Logging
  - Bundle obfuscation (SwiftShield) to protect Firebase credentials
  - Rate limiting on Firebase endpoints (quota configuration)
- **Verification**: Test with Firebase Emulator - attempt access without valid App Check token, assert denied
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 9, Security Gap #2)

---

### Tampering Threats

#### Threat T-1: Firestore Data Modification via Rule Bypass
- **STRIDE Category**: Tampering
- **Attack Vector**: Attacker exploits misconfigured Firestore Security Rules to modify other users' items
- **Affected Component**: Firestore Security Rules (SECURITY-RULES-001)
- **Current State**: Row-level access control with `request.auth.uid == resource.data.userId` validation
- **Risk Level**: High (privacy violation if user data modified/deleted)
- **Likelihood**: Medium (OWASP #2: Security Misconfiguration, 125M+ records exposed in 2024, verified Security Gap #1)
- **Mitigation**:
  - **P0**: Automated security rules testing in CI/CD pipeline (Firebase Emulator Suite)
  - **P0**: Firebase Security Review Checklist before deployment
  - Production mode (deny by default) enforced in all environments
  - Version control for security rules (firestore.rules in git)
  - Cloud Logging alerts for rule evaluation failures
  - Quarterly security rules audit against app usage patterns
- **Verification**: Unit test suite with 90% coverage target - test unauthorized read/write/delete operations, assert all fail
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Security Gap #1, Claim 6)

#### Threat T-2: Cropped Image Manipulation in Storage
- **STRIDE Category**: Tampering
- **Attack Vector**: Attacker modifies cropped images in Firebase Storage to inject malicious content
- **Affected Component**: Firebase Storage (STORAGE-RULES-001)
- **Current State**: User folder isolation (`users/{userId}/items/{itemId}/*.jpg`), owner-only write access
- **Risk Level**: Low
- **Likelihood**: Low (users can only modify own images, AI pipeline validates image format)
- **Mitigation**:
  - Firebase Storage rules: `isOwner(userId)` check for write operations
  - File size validation: 10MB limit (verified in STORAGE-RULES-001)
  - Content-Type validation: `image/.*` only
  - Vision Framework on iOS validates image format before upload
  - Cloud Functions validate JPEG format before AI processing
  - Immutable storage for AI-processed results (deny write to `/processed/*`)
- **Verification**: Integration test - attempt to upload non-image file, assert rejected
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 6), STORAGE-RULES-001

#### Threat T-3: Privacy Firewall Bypass via Code Change
- **STRIDE Category**: Tampering
- **Attack Vector**: Malicious developer or code change uploads full photos instead of cropped objects
- **Affected Component**: Privacy Firewall (DESIGN-015)
- **Current State**: PrivacyFirewall service enforces deletion via `defer` block, full photos never leave device
- **Risk Level**: High (privacy violation, GDPR breach if full photos uploaded)
- **Likelihood**: Very Low (automated testing, code review, privacy audit)
- **Mitigation**:
  - **Automated test**: CI/CD verification that uploaded files < 500KB (full photos ~3-5MB)
  - **Firebase Storage rules**: 10MB max upload (blocks full photos)
  - **Code review**: Privacy firewall changes require security team approval
  - **Privacy audit checklist**: Manual review before launch
  - **Monitoring**: Cloud Logging alert for files > 1MB uploaded to user folders
  - **Network traffic analysis**: Integration test captures traffic, verifies no large uploads
- **Verification**: Integration test - mock camera capture (3MB photo), verify Firebase Storage only contains < 500KB files
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 3, 5), DESIGN-015 (privacy firewall)

---

### Repudiation Threats

#### Threat R-1: Unauthorized Item Deletion Without Audit Trail
- **STRIDE Category**: Repudiation
- **Attack Vector**: User deletes items, then denies action (lacks audit trail for regulatory compliance)
- **Affected Component**: Firestore soft delete mechanism (DATA-MODEL-001)
- **Current State**: Soft delete via `deletedAt` timestamp, no audit log for delete operations
- **Risk Level**: Low (MVP scope)
- **Likelihood**: Low (user-initiated deletions only, no financial impact)
- **Mitigation**:
  - Soft delete pattern: `deletedAt` timestamp in Firestore (DATA-MODEL-001)
  - Cloud Logging captures all Firestore write operations (automatic)
  - Export Cloud Logs to BigQuery for long-term retention (90 days)
  - Optional: Add `deletedBy` field and `deletionReason` for audit trail
  - Future: Integrate with Cloud Audit Logs for compliance-grade audit trail
- **Verification**: Query Cloud Logging for Firestore delete operations, verify timestamp and userId captured
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 6), DATA-MODEL-001

#### Threat R-2: Cloud Function Execution Without Logging
- **STRIDE Category**: Repudiation
- **Attack Vector**: Cloud Functions execute privileged operations without audit trail (GDPR Article 30)
- **Affected Component**: Cloud Functions (AI-INTEGRATION-LAYER-001)
- **Current State**: Cloud Functions have automatic Cloud Logging integration, structured logging available
- **Risk Level**: Medium (compliance risk for GDPR/CCPA)
- **Likelihood**: Low (Cloud Logging enabled by default, verified Claim 11)
- **Mitigation**:
  - Cloud Logging automatic capture of function invocations (start, end, errors)
  - Structured logging for sensitive operations (user data access, AI API calls)
  - Log export to BigQuery for compliance retention (7 years GDPR requirement)
  - Cloud Monitoring dashboards for security event visualization
  - Incident response runbook references Cloud Logs for breach investigation
- **Verification**: Trigger Cloud Function, query Cloud Logging for invocation record within 1 minute
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 11)

#### Threat R-3: AI API Requests Without Traceability
- **STRIDE Category**: Repudiation
- **Attack Vector**: AI API calls (Gemini, SerpAPI, Claude) occur without correlation to user requests
- **Affected Component**: AI Integration Layer (Layer 2a, 2b, 3 - DESIGN-004)
- **Current State**: Cloud Functions log API calls, no structured correlation ID
- **Risk Level**: Low (MVP scope)
- **Likelihood**: Low (cost tracking via GCP billing, logs available for 30 days)
- **Mitigation**:
  - Request correlation ID: Pass `itemId` to all AI API calls
  - Structured logging: `{ itemId, userId, apiName, requestTimestamp, responseStatus }`
  - Cost allocation tags: GCP labels on Cloud Function invocations
  - API usage monitoring: Cloud Monitoring dashboards for quota tracking
  - Future: Distributed tracing with Cloud Trace for end-to-end visibility
- **Verification**: Trigger item creation, query Cloud Logs for AI API calls with matching `itemId`
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 10, 11)

---

### Information Disclosure Threats

#### Threat I-1: Photo Leakage via Firebase Storage Misconfiguration (P0)
- **STRIDE Category**: Information Disclosure
- **Attack Vector**: Attacker discovers Firebase Storage bucket with public read access enabled
- **Affected Component**: Firebase Storage (STORAGE-RULES-001)
- **Current State**: Storage rules require authentication (`isOwner(userId)`), but misconfiguration risk exists
- **Risk Level**: High (privacy violation, GDPR breach, user photos exposed)
- **Likelihood**: Medium (OWASP #2: Security Misconfiguration, 900+ Firebase sites exposed 125M records in 2024, verified Security Gap #1)
- **Mitigation**:
  - **P0**: Automated security rules testing in CI/CD pipeline (Firebase Emulator Suite)
  - **P0**: Firebase Security Review Checklist (pre-deployment validation)
  - Cloud Storage bucket policy: Uniform bucket-level access (deny public read)
  - Monitoring: Cloud Logging alert for public bucket access attempts
  - Version control: storage.rules file in git, PR reviews required
  - Production mode enforced: Default deny for all read/write operations
  - Quarterly security audit: Verify no public buckets, no overly permissive rules
- **Verification**: Run `firebase emulators:start`, attempt unauthorized read without auth token, assert 403 Forbidden
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Security Gap #1, Claim 8)

#### Threat I-2: Full Photo Upload Bypassing Privacy Firewall
- **STRIDE Category**: Information Disclosure
- **Attack Vector**: Code bug or malicious change uploads full photos instead of cropped objects
- **Affected Component**: Privacy Firewall (DESIGN-015), Firebase Storage
- **Current State**: PrivacyFirewall enforces deletion, but no server-side validation of image size
- **Risk Level**: High (privacy violation, full photos contain sensitive metadata)
- **Likelihood**: Very Low (automated testing, code review, see Threat T-3)
- **Mitigation**: See Threat T-3 (same mitigations apply)
- **Verification**: See Threat T-3
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 3, 5), DESIGN-015

#### Threat I-3: Signed URL Extended Expiration (7 days) (P1)
- **STRIDE Category**: Information Disclosure
- **Attack Vector**: Signed URLs for cropped photos leaked/shared, remain accessible for 7 days
- **Affected Component**: Firebase Storage signed URLs (STORAGE-RULES-001)
- **Current State**: Signed URLs generated with 1 hour expiration (STORAGE-RULES-001), but 7-day maximum available
- **Risk Level**: High (cropped photos accessible beyond intended use case)
- **Likelihood**: Medium (URLs may be logged, cached, or shared via insecure channels, verified Security Gap #3)
- **Mitigation**:
  - **P1**: Architecture change - server-side signed URL generation with 2-5 minute expiration
  - Cloud Function `generateShortLivedSignedUrl` generates URLs on-demand for SerpAPI
  - Store URL generation timestamp in Firestore for audit trail
  - URL rotation: Generate new signed URL for each SerpAPI request
  - Alternative: Download tokens with manual revocation after first download
  - Monitoring: Alert if signed URL expiration > 10 minutes (unexpected pattern)
- **Verification**: Generate signed URL with 5-minute expiration, wait 6 minutes, attempt access, assert 403 Forbidden
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Security Gap #3, Claim 8)

#### Threat I-4: Email Enumeration Attack (P1)
- **STRIDE Category**: Information Disclosure
- **Attack Vector**: Attacker probes Firebase Auth endpoints to enumerate valid user email addresses
- **Affected Component**: Firebase Authentication (ADR-023)
- **Current State**: Email enumeration protection available but opt-in (not enabled by default)
- **Risk Level**: Medium (account enumeration enables targeted phishing)
- **Likelihood**: Medium (common attack vector, easily automated, verified Security Gap #4)
- **Mitigation**:
  - **P1**: Enable email enumeration protection in Firebase Console (Authentication > Settings)
  - Generic error messages for failed logins (no distinction between "user not found" vs "wrong password")
  - Rate limiting on sign-in endpoint (Firebase quota configuration)
  - iOS error handling: Display generic "Login failed" message (no email hints)
  - Monitoring: Alert on unusual login failure rates (brute force detection)
  - Future: Migrate to Google Cloud Identity Platform for MFA support
- **Verification**:
  ```bash
  POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword
  Body: { "email": "nonexistent@example.com", "password": "wrong" }
  Expected: Generic error message (not "EMAIL_NOT_FOUND")
  ```
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Security Gap #4, Claim 7)

#### Threat I-5: API Keys Exposed in Client Bundle
- **STRIDE Category**: Information Disclosure
- **Attack Vector**: Attacker extracts API keys (Gemini, SerpAPI, Claude) from iOS app bundle
- **Affected Component**: GCP Secret Manager (Claim 10), Cloud Functions
- **Current State**: API keys stored in Secret Manager (server-side), NOT in iOS bundle
- **Risk Level**: Low
- **Likelihood**: Low (API keys server-side only, verified Claim 10)
- **Mitigation**:
  - API keys stored in GCP Secret Manager (AES-256 encryption)
  - Cloud Functions access keys via Secret Manager API (no hardcoded keys)
  - iOS app never contains API keys (Firebase credentials only)
  - 90-day API key rotation policy
  - IP restriction: API keys limited to Cloud Functions NAT gateway IPs
  - Monitoring: Alert on unusual API usage (quota exhaustion, rate limits)
- **Verification**: Decompile iOS app bundle, verify no API keys for Gemini/SerpAPI/Claude present
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 10)

#### Threat I-6: GDPR Data Transfer Without SCCs (P0)
- **STRIDE Category**: Information Disclosure
- **Attack Vector**: EU user data transferred to US Firebase servers without proper safeguards
- **Affected Component**: Firebase Authentication, GCP data residency (Security Gap #2)
- **Current State**: Firebase Auth stores data in US by default, no EU region option
- **Risk Level**: High (GDPR Article 46 violation, regulatory fines)
- **Likelihood**: High (default Firebase configuration, verified Security Gap #2)
- **Mitigation**:
  - **P0**: Accept Firebase Standard Contractual Clauses (SCCs) in GCP Console
  - **P0**: Conduct Transfer Impact Assessment (TIA) with legal counsel
  - Configure EU regions for Firestore (`europe-west1`), Storage (`europe-west1`), Cloud Functions
  - Document data flows in privacy policy (user notice requirement)
  - Google Data Privacy Framework certification (EU-US DPF)
  - Review Firebase, SerpAPI, Anthropic DPAs for GDPR compliance
- **Verification**: Privacy policy disclosure review, Firebase Console region configuration audit
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Security Gap #2, GDPR Data Transfer)

---

### Denial of Service Threats

#### Threat D-1: Malicious Image Upload Exhausts Gemini Quota
- **STRIDE Category**: Denial of Service
- **Attack Vector**: Attacker uploads many invalid images to exhaust Gemini API quota, blocking legitimate users
- **Affected Component**: Vertex AI Gemini (Layer 2a), Cloud Functions
- **Current State**: No rate limiting on item creation, quota monitoring via Cloud Monitoring
- **Risk Level**: Medium (service degradation, cost overrun)
- **Likelihood**: Medium (easy to automate, Gemini quota limits exist)
- **Mitigation**:
  - Rate limiting: 10 items per user per minute (Cloud Functions validation)
  - Firebase quota configuration: Firestore write rate limits per user
  - Budget alerts: 50%, 90%, 100% thresholds for Gemini API quota
  - Input validation: Reject images > 10MB (Firebase Storage rules)
  - Image format validation: JPEG/PNG only (Vision Framework pre-validation)
  - Circuit breaker: Disable Gemini processing if quota exhausted (return cached results)
  - Monitoring: Alert on unusual item creation rates per user
- **Verification**: Load test - create 100 items in 1 minute, verify rate limiting enforced after 10th item
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 10)

#### Threat D-2: Firestore Query Rate Limiting Bypass
- **STRIDE Category**: Denial of Service
- **Attack Vector**: Attacker floods Firestore with queries to exhaust quota, increase costs
- **Affected Component**: Firestore (SECURITY-RULES-001), Cloud Functions
- **Current State**: Firestore has default rate limits (10K reads/writes per second), no per-user limits
- **Risk Level**: Low (Firestore auto-scales, billing alerts exist)
- **Likelihood**: Low (requires authenticated user, Firestore quota is high)
- **Mitigation**:
  - Firebase quota configuration: Per-user read/write limits (100 reads per minute)
  - Firestore index optimization: Reduce query cost (composite indexes)
  - Pagination: Limit query results to 50 items per request
  - Budget alerts: 80% quota threshold triggers notification
  - Rate limiting: Cloud Functions enforce per-user request limits
  - Monitoring: Dashboard for Firestore read/write rates by user
- **Verification**: Load test - execute 1000 queries in 1 minute, verify rate limiting enforced
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 6)

#### Threat D-3: SerpAPI Quota Exhaustion Attack
- **STRIDE Category**: Denial of Service
- **Attack Vector**: Attacker creates many items to exhaust SerpAPI quota (5K searches/month free tier)
- **Affected Component**: SerpAPI (Layer 2b), Cloud Functions
- **Current State**: No per-user limits on SerpAPI usage, quota monitoring via Cloud Logging
- **Risk Level**: Medium (service degradation, cost overrun if paid tier required)
- **Likelihood**: Medium (5K searches/month = ~166 searches/day, easily exhausted)
- **Mitigation**:
  - Per-user rate limiting: 5 SerpAPI searches per day (Cloud Functions)
  - Budget alerts: 80% SerpAPI quota triggers notification
  - Circuit breaker: Disable SerpAPI if quota exhausted (fallback to cached results)
  - Premium tier: Unlimited searches for paid users (custom claims)
  - Monitoring: Dashboard for SerpAPI usage by user, daily quota tracking
  - Abuse detection: Alert on users exceeding 10 searches/day
- **Verification**: Create 10 items in 1 day, verify 6th SerpAPI call rejected with quota exceeded error
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 10)

---

### Elevation of Privilege Threats

#### Threat E-1: Cloud Functions Admin SDK Access Compromise
- **STRIDE Category**: Elevation of Privilege
- **Attack Vector**: Attacker compromises Cloud Function, gains Admin SDK access to Firestore/Storage
- **Affected Component**: Cloud Functions (Claim 11), Firebase Admin SDK
- **Current State**: Cloud Functions use default Compute Engine service account (broad permissions)
- **Risk Level**: High (full database access if function compromised)
- **Likelihood**: Low (Cloud Functions sandboxed, automatic security patches, verified Claim 11)
- **Mitigation**:
  - **Best practice**: Create user-managed service accounts per Cloud Function category
  - Principle of least privilege: Grant minimal IAM roles (e.g., `datastore.user` only)
  - Network isolation: Restrict Cloud Functions to internal traffic (VPC)
  - Automatic runtime updates: Security patches applied with zero downtime
  - Seccomp system call filtering: Reduces attack surface via sandboxing
  - Dependency scanning: `npm audit` in CI/CD pipeline
  - Monitoring: Alert on Cloud Function execution failures (potential exploit attempts)
- **Verification**: Attempt Cloud Function invocation with excessive permissions, verify IAM denies unauthorized operations
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 11)

#### Threat E-2: Premium Feature Access Without Subscription
- **STRIDE Category**: Elevation of Privilege
- **Attack Vector**: Non-premium user manipulates custom claims to access premium features
- **Affected Component**: Firestore Security Rules (SECURITY-RULES-001), custom claims
- **Current State**: Custom claims set server-side only (Cloud Functions), not client-controllable
- **Risk Level**: Medium (revenue loss if premium features accessed for free)
- **Likelihood**: Low (custom claims cryptographically signed, verified Claim 2)
- **Mitigation**:
  - Custom claims managed exclusively by Cloud Functions (no client-side modification)
  - Firestore Security Rules: `request.auth.token.premium == true` validation
  - Cloud Functions: Validate subscription status via Stripe/RevenueCat before setting custom claims
  - Token refresh: Custom claims updated on token refresh (1 hour)
  - Monitoring: Alert on premium feature usage by non-premium users
  - Audit: Quarterly review of custom claims vs subscription database
- **Verification**: Set custom claims to `premium: false`, attempt premium feature access, assert denied by Firestore rules
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 2, 6)

#### Threat E-3: Firebase Admin SDK Key Leakage
- **STRIDE Category**: Elevation of Privilege
- **Attack Vector**: Firebase Admin SDK service account key leaked in git history, public bucket
- **Affected Component**: GCP Secret Manager (Claim 10), service accounts
- **Current State**: Service account keys stored in Secret Manager, not in git
- **Risk Level**: High (full Firebase project access if key leaked)
- **Likelihood**: Low (Secret Manager enforced, git pre-commit hooks prevent key commits)
- **Mitigation**:
  - Service account keys stored in Secret Manager (AES-256 encryption)
  - `.gitignore`: Block `*.json` service account keys
  - Pre-commit hooks: Scan for API keys/secrets before commit (detect-secrets, gitleaks)
  - Key rotation: 90-day automatic rotation via Secret Manager
  - Workload Identity Federation: Avoid exporting service account keys when possible
  - Monitoring: Alert on service account key creation events (audit log)
  - Incident response: Revoke compromised keys within 1 hour
- **Verification**: Attempt to commit service account key file, verify pre-commit hook rejects
- **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 10)

---

## Risk Matrix

| Threat ID | Component | STRIDE Category | Risk Level | Likelihood | Priority |
|-----------|-----------|-----------------|------------|------------|----------|
| I-1 | Firebase Storage | Information Disclosure | High | Medium | P0 |
| I-6 | Firebase Auth | Information Disclosure | High | High | P0 |
| T-1 | Firestore Rules | Tampering | High | Medium | P0 |
| I-3 | Signed URLs | Information Disclosure | High | Medium | P1 |
| I-4 | Firebase Auth | Information Disclosure | Medium | Medium | P1 |
| S-3 | App Check | Spoofing | Medium | Medium | P1 |
| T-3 | Privacy Firewall | Tampering | High | Very Low | P1 |
| E-1 | Cloud Functions | Elevation of Privilege | High | Low | P2 |
| E-2 | Custom Claims | Elevation of Privilege | Medium | Low | P2 |
| D-1 | Gemini API | Denial of Service | Medium | Medium | P2 |
| D-3 | SerpAPI | Denial of Service | Medium | Medium | P2 |
| S-1 | Firebase Auth | Spoofing | Low | Very Low | P3 |
| S-2 | Apple Sign-In | Spoofing | Low | Low | P3 |
| T-2 | Firebase Storage | Tampering | Low | Low | P3 |
| R-1 | Firestore | Repudiation | Low | Low | P3 |
| R-2 | Cloud Functions | Repudiation | Medium | Low | P3 |
| R-3 | AI APIs | Repudiation | Low | Low | P3 |
| I-5 | API Keys | Information Disclosure | Low | Low | P3 |
| D-2 | Firestore | Denial of Service | Low | Low | P3 |
| E-3 | Service Accounts | Elevation of Privilege | High | Low | P2 |

**Total Threats Identified**: 20

---

## P0/P1 Security Gaps Addressed

### P0 Blockers (Must Fix Before Any Launch)
1. **Firebase Misconfiguration** (Threats I-1, T-1):
   - **Mitigation**: Automated security rules testing in CI/CD pipeline
   - **Deliverable**: TEST-003 (security test plan), SECURITY-HARDENING-CHECKLIST-001
   - **Verification**: Firebase Emulator Suite with 90% rules coverage target

2. **GDPR Data Transfer** (Threat I-6):
   - **Mitigation**: Accept Firebase SCCs, conduct Transfer Impact Assessment (TIA)
   - **Deliverable**: PRIVACY-IMPACT-ASSESSMENT-001 (GDPR compliance)
   - **Timeline**: Complete before EU user beta testing (Month 4)

### P1 Before Launch (Must Fix Before Public Release)
3. **Signed URL Expiration** (Threat I-3):
   - **Mitigation**: Server-side signed URL generation with 2-5 minute expiration
   - **Deliverable**: DESIGN-025 (architecture change), ADR-022 (photo privacy)
   - **Verification**: Integration test - generate 5-min URL, wait 6 min, assert 403

4. **Email Enumeration** (Threat I-4):
   - **Mitigation**: Enable protection in Firebase Console (Authentication > Settings)
   - **Deliverable**: ADR-023 (authentication strategy), SECURITY-HARDENING-CHECKLIST-001
   - **Verification**: Test login endpoint with nonexistent email, assert generic error

---

## Verification Summary

- **Total threats identified**: 20 (exceeds minimum 15 requirement)
- **High risk**: 7 threats (I-1, I-3, I-6, T-1, T-3, E-1, E-3)
- **Medium risk**: 7 threats (S-3, I-4, R-2, D-1, D-3, E-2)
- **Low risk**: 6 threats (S-1, S-2, T-2, R-1, R-3, I-5, D-2)
- **P0 threats**: 2 (Firebase misconfiguration, GDPR data transfer)
- **P1 threats**: 4 (signed URL expiration, email enumeration, App Check, privacy firewall)
- **All STRIDE categories analyzed**: ✅ 6/6 (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)

**Critical Finding**: Two P0 blockers (Firebase misconfiguration, GDPR SCCs) and two P1 security gaps (signed URL expiration, email enumeration) must be remediated before launch.

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial STRIDE threat model, 20 threats identified | Privacy & Security Architect |

---

**Status**: ✅ **THREAT MODEL COMPLETE** - Ready for security review and implementation planning
