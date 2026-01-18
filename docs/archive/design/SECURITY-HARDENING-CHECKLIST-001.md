# SECURITY-HARDENING-CHECKLIST-001: Pre-Launch Security Review

**Created**: 2025-11-09
**Stage**: 2.5 - Privacy & Security Architecture
**Status**: Draft - Pre-Deployment Validation Required
**References**:
- docs/design/THREAT-MODEL-001-stride-analysis.md
- docs/design/DESIGN-025-security-privacy-architecture.md
- docs/adr/ADR-021-data-encryption-approach.md
- docs/adr/ADR-022-photo-privacy-protection.md
- docs/adr/ADR-023-authentication-authorization-strategy.md
- docs/design/PRIVACY-IMPACT-ASSESSMENT-001.md
- docs/test/TEST-003-security-test-plan.md

---

## Executive Summary

This checklist provides comprehensive pre-launch security validation across 5 categories (iOS Security, Firebase Security, GCP Security, GDPR/CCPA Compliance, Monitoring & Alerting). All P0 action items (Firebase misconfiguration testing, GDPR SCCs/TIA) must be completed before any launch. All P1 action items (email enumeration protection, signed URL expiration) must be completed before public release. Use this checklist as final gate before production deployment.

---

## How to Use This Checklist

1. **Pre-Deployment**: Review all items before deploying to production
2. **P0 Items**: Must complete before ANY user access (MVP, beta, production)
3. **P1 Items**: Must complete before PUBLIC launch (can defer for internal beta)
4. **Verification**: Each item includes verification step or test reference
5. **Sign-Off**: Security team must approve all P0/P1 items before launch

---

## iOS Security Checklist

### Authentication & Session Management

- [ ] **Firebase ID tokens stored in Keychain with AES-256-GCM encryption**
  - **Implementation**: ADR-021 (Keychain integration)
  - **Protection Class**: `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`
  - **Verification**: Unit test verifies token storage, retrieval, deletion
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 1)

- [ ] **Apple Sign-In configured with OAuth 2.0 + nonce replay protection**
  - **Implementation**: ADR-023 (Apple Sign-In flow)
  - **Nonce Generation**: Cryptographic randomness (32 bytes)
  - **Verification**: Integration test verifies nonce validation
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 2)

- [ ] **Automatic token refresh enabled (1 hour expiration)**
  - **Implementation**: Firebase SDK automatic refresh
  - **Refresh Token**: Stored in Keychain
  - **Verification**: Test token expiration handling
  - **Reference**: ADR-023 (session management)

### Privacy & Data Protection

- [ ] **App Transport Security enabled (TLS 1.2+ enforced, no exceptions)**
  - **Configuration**: Info.plist `NSAppTransportSecurity` with no exceptions
  - **Verification**: Verify `NSAllowsArbitraryLoads` is `false` or absent
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 4), ADR-021

- [ ] **Camera permission prompt includes privacy disclosure**
  - **Configuration**: Info.plist `NSCameraUsageDescription`
  - **Disclosure**: "Photos are processed on-device only, full photos never uploaded"
  - **Verification**: Test camera permission flow on physical device
  - **Reference**: DESIGN-025 (camera privacy)

- [ ] **Temporary photo files use Data Protection API (file-level encryption)**
  - **Protection Class**: `FileProtectionType.complete`
  - **Lifecycle**: Files deleted immediately after Vision processing
  - **Verification**: Unit test verifies temp file encryption + deletion
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 5), ADR-021

- [ ] **Privacy firewall enforced (no code path uploads full photos)** - **P0**
  - **Implementation**: DESIGN-015 (privacy firewall architecture)
  - **Validation Strategy**: ADR-022 (multi-layered validation)
  - **Automated Test**: CI/CD verifies uploaded files < 500KB
  - **Manual Review**: Code review + network traffic analysis
  - **Verification**: Run TEST-003 privacy audit tests
  - **Reference**: THREAT-MODEL-001 (Threat T-3, I-2)

---

## Firebase Security Checklist

### Firestore Security Rules

- [ ] **Firestore Security Rules deployed and tested (row-level access control)** - **P0**
  - **Implementation**: SECURITY-RULES-001 (firestore.rules)
  - **Production Mode**: Deny by default (no `allow read, write: if true`)
  - **Automated Testing**: Firebase Emulator Suite with 90% coverage target
  - **Verification**: Run TEST-003 penetration tests (Section 1.1)
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 6), THREAT-MODEL-001 (Threat T-1)

- [ ] **Firestore rules version controlled (firestore.rules in git)**
  - **Location**: `/firestore.rules` at repository root
  - **PR Review**: All changes require security team approval
  - **Verification**: Verify file exists in git with latest rules
  - **Reference**: DESIGN-025 (Firebase security)

- [ ] **Firestore rules CI/CD testing enabled** - **P0**
  - **Configuration**: `.github/workflows/firebase-rules-test.yml`
  - **Coverage Target**: 90% rule coverage
  - **Failure Behavior**: PR blocked if tests fail
  - **Verification**: Create test PR, verify CI/CD runs Firestore rules tests
  - **Reference**: TEST-003 (automated testing), THREAT-MODEL-001 (Security Gap #1)

### Firebase Storage Security Rules

- [ ] **Firebase Storage Rules deployed and tested (user folder isolation)** - **P0**
  - **Implementation**: STORAGE-RULES-001 (storage.rules)
  - **User Isolation**: `users/{userId}/items/{itemId}/objects/*.jpg`
  - **File Size Limit**: 10MB max (blocks full photos)
  - **Verification**: Run TEST-003 penetration tests (Section 1.2)
  - **Reference**: THREAT-MODEL-001 (Threat I-1)

- [ ] **Storage rules enforce image content type validation**
  - **Validation**: `request.resource.contentType.matches('image/.*')`
  - **Verification**: Test upload of non-image file, verify rejection
  - **Reference**: STORAGE-RULES-001

- [ ] **Uniform bucket-level access enabled (deny public read)** - **P0**
  - **Configuration**: GCP Console > Cloud Storage > Bucket > Permissions
  - **Setting**: "Uniform" access control (not "Fine-grained")
  - **Verification**: Run `gsutil iam get gs://[bucket]`, verify no `allUsers` binding
  - **Reference**: DESIGN-025 (Cloud Storage), THREAT-MODEL-001 (Threat I-1)

### Firebase Authentication

- [ ] **Email enumeration protection enabled** - **P1**
  - **Configuration**: Firebase Console > Authentication > Settings
  - **Setting**: "User enumeration protection" = ENABLED
  - **Verification**: Test login with nonexistent email, verify generic error
  - **Test**: `POST /accounts:signInWithPassword` with invalid email → `INVALID_LOGIN_CREDENTIALS`
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 7, Security Gap #4), THREAT-MODEL-001 (Threat I-4)

- [ ] **Firebase App Check configured** - **P1**
  - **iOS Integration**: DeviceCheck provider (production) or App Attest
  - **Services Protected**: Firestore, Storage, Cloud Functions
  - **Enforcement**: Require valid attestation tokens
  - **Verification**: Attempt request without App Check token, verify denied
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 9), THREAT-MODEL-001 (Threat S-3)

---

## GCP Security Checklist

### Secret Management

- [ ] **API keys stored in Secret Manager (AES-256 encryption)**
  - **Secrets**: Gemini API key, SerpAPI key, Claude API key
  - **Access Control**: IAM service accounts only (Cloud Functions)
  - **Verification**: Verify no hardcoded keys in git history (`git log -S "AIza"`)
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 10), ADR-021

- [ ] **Secret Manager 90-day rotation policy configured**
  - **Policy**: Automatic rotation every 90 days
  - **Process**: Create new version → Update Cloud Functions → Delete old version
  - **Verification**: Check Secret Manager console for rotation schedule
  - **Reference**: ADR-021 (key management)

- [ ] **Pre-commit hooks prevent API key commits**
  - **Tools**: `detect-secrets`, `gitleaks`, or similar
  - **Configuration**: `.pre-commit-config.yaml`
  - **Verification**: Attempt to commit test API key, verify hook rejects
  - **Reference**: THREAT-MODEL-001 (Threat E-3)

### Cloud Functions Security

- [ ] **Cloud Functions enforce bearer token authentication**
  - **Implementation**: `admin.auth().verifyIdToken()` in all HTTP functions
  - **Error Handling**: Return 401 Unauthorized if token missing/invalid
  - **Verification**: Run TEST-003 penetration tests (Section 1.3)
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Claim 11), DESIGN-025

- [ ] **Cloud Functions use user-managed service accounts (not default)**
  - **Configuration**: Create dedicated service account per function category
  - **IAM Roles**: Principle of least privilege (e.g., `datastore.user` only)
  - **Verification**: Check Cloud Functions console for service account assignment
  - **Reference**: DESIGN-025 (service account best practices)

- [ ] **Signed URLs use 2-5 minute expiration (server-side generation)** - **P1**
  - **Implementation**: Cloud Function `generateShortLivedSignedUrl`
  - **Expiration**: 5 minutes (not 7-day default)
  - **Audit Trail**: Store generation timestamp in Firestore
  - **Verification**: Generate signed URL, wait 6 minutes, verify 403 Forbidden
  - **Reference**: RESEARCH-VALIDATION-stage-2.5.md (Security Gap #3), THREAT-MODEL-001 (Threat I-3)

### Cloud Storage

- [ ] **Cloud Storage buckets deny public access**
  - **Configuration**: Uniform bucket-level access enabled (see Firebase Storage above)
  - **IAM Policy**: No `allUsers` or `allAuthenticatedUsers` bindings
  - **Verification**: Run `gsutil iam get gs://[bucket]` for all buckets
  - **Reference**: DESIGN-025 (Cloud Storage security)

- [ ] **Cloud Storage 90-day lifecycle policy configured**
  - **Policy**: Auto-delete files > 90 days old
  - **Scope**: All user-uploaded images (`users/*/items/*/objects/*`)
  - **Verification**: Check Cloud Storage console for lifecycle rules
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (data retention)

### Budget & Monitoring

- [ ] **Budget alerts configured (50%, 90%, 100% thresholds)**
  - **Budget**: $500/month (adjust per project)
  - **Notification**: Email to security team
  - **Verification**: Check GCP Console > Billing > Budgets & Alerts
  - **Reference**: DESIGN-025 (budget alerts)

- [ ] **Cloud Logging exports to BigQuery (7-year retention for GDPR)**
  - **Export**: All security events (severity >= WARNING)
  - **Destination**: BigQuery dataset `security_logs`
  - **Retention**: 7 years (GDPR Article 30 compliance)
  - **Verification**: Check Cloud Logging console for log sink configuration
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (audit logging)

---

## GDPR/CCPA Compliance Checklist

### GDPR Requirements (EU Markets)

- [ ] **Standard Contractual Clauses (SCCs) accepted in Firebase Console** - **P0**
  - **Action**: GCP Console > IAM & Admin > Agreements > Accept Google Cloud DPA
  - **Document**: Download signed DPA for records
  - **Timeline**: Complete before EU user beta testing (Month 4)
  - **Verification**: Check GCP Console > IAM & Admin > Agreements for accepted DPA
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (Section 4), THREAT-MODEL-001 (Threat I-6)

- [ ] **Transfer Impact Assessment (TIA) completed for US data transfer** - **P0**
  - **Action**: Conduct TIA with legal counsel, document safeguards
  - **Safeguards**: Encryption (TLS 1.3, AES-256), access controls, data minimization
  - **Legal Review**: Obtain legal opinion on adequacy of safeguards
  - **Timeline**: Complete before EU user beta testing (Month 4)
  - **Verification**: Verify TIA document signed by legal counsel
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (Section 4), THREAT-MODEL-001 (Threat I-6)

- [ ] **SerpAPI DPA reviewed for GDPR compliance** - **P0**
  - **Action**: Request DPA from SerpAPI, review data retention policy
  - **Review**: Verify GDPR compliance (data retention, subprocessors, SCCs)
  - **Timeline**: Before launch
  - **Verification**: Verify signed DPA document on file
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (Section 5)

- [ ] **Anthropic Claude DPA reviewed for GDPR compliance** - **P0**
  - **Action**: Request DPA from Anthropic, review data retention policy
  - **Review**: Verify GDPR compliance (data retention, subprocessors, SCCs)
  - **Timeline**: Before launch
  - **Verification**: Verify signed DPA document on file
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (Section 5)

- [ ] **Privacy policy reviewed by legal counsel (GDPR/CCPA disclosures)** - **P1**
  - **Disclosures**: Data collection, third-party processors, user rights
  - **Legal Review**: Attorney reviews for GDPR Article 13 + CCPA Section 1798.130 compliance
  - **Timeline**: Before public launch
  - **Verification**: Verify signed legal review memo
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (privacy policy requirements)

- [ ] **Right to Access export function implemented and tested**
  - **Implementation**: Cloud Function `exportUserData`
  - **Timeline**: Within 30 days of request
  - **Verification**: Run TEST-003 compliance tests (Section 2.3.2)
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (Section 1)

- [ ] **Right to Erasure cascade delete implemented and tested**
  - **Implementation**: Cloud Function `deleteUserAccount`
  - **Timeline**: Within 30 days of request
  - **Scope**: Firestore, Storage, Auth, AI metadata
  - **Verification**: Run TEST-003 compliance tests (Section 2.3.1)
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (Section 2)

### CCPA Requirements (California Markets)

- [ ] **Privacy policy includes CCPA disclosures (Right to Know, Right to Delete, Do Not Sell)**
  - **Disclosures**: Categories of data collected, purposes, third parties
  - **User Rights**: Right to Know, Right to Delete, Do Not Sell
  - **Verification**: Review privacy policy text for CCPA Section 1798.130 compliance
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (CCPA Section 1, 3)

- [ ] **"Do Not Sell" statement in privacy policy**
  - **Statement**: "We do not sell your personal information to third parties"
  - **Third-Party Disclosure**: AI services act as service providers (not buyers)
  - **Verification**: Search privacy policy for "Do Not Sell" text
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (CCPA Section 3)

### Optional EU Region Configuration

- [ ] **Firebase Auth EU region configured** (Optional, if available)
  - **Configuration**: Firebase Console > Project Settings > Cloud Firestore locations
  - **Region**: `europe-west1` for Firestore, Storage, Cloud Functions
  - **Benefit**: Eliminates US data transfer requirement, simplifies GDPR compliance
  - **Verification**: Check Firebase Console for region configuration
  - **Reference**: PRIVACY-IMPACT-ASSESSMENT-001 (Section 4, Step 3)

---

## Monitoring & Alerting Checklist

### Cloud Logging

- [ ] **All security events logged (unauthorized access, rule violations)**
  - **Events**: Firebase Auth failures, Firestore rule denials, Storage access denials
  - **Severity**: >= WARNING for security events
  - **Verification**: Trigger test security event, verify Cloud Logging entry
  - **Reference**: DESIGN-025 (monitoring)

- [ ] **Cloud Logging alert for unauthorized access attempts (> 10/minute)**
  - **Condition**: `severity="WARNING" AND eventType="UNAUTHORIZED_ACCESS"`
  - **Threshold**: > 10 events per minute
  - **Notification**: Email to security team
  - **Verification**: Check Cloud Monitoring console for alert policy
  - **Reference**: DESIGN-025 (Cloud Monitoring alerts)

- [ ] **Cloud Logging alert for large file uploads (> 500KB)**
  - **Condition**: `resource.type="gcs_bucket" AND response.size > 500000`
  - **Severity**: HIGH (privacy violation)
  - **Notification**: Email to security team
  - **Verification**: Upload test file > 500KB, verify alert triggered
  - **Reference**: ADR-022 (privacy firewall monitoring), THREAT-MODEL-001 (Threat I-2)

### Cloud Monitoring

- [ ] **Error rate dashboard configured (alert if > 5%)**
  - **Metric**: Cloud Functions error rate by function
  - **Threshold**: > 5% error rate
  - **Verification**: Check Cloud Monitoring console for dashboard
  - **Reference**: DESIGN-025 (monitoring dashboards)

- [ ] **Latency P95 dashboard configured (alert if > 2s)**
  - **Metric**: Cloud Functions latency P95 by endpoint
  - **Threshold**: > 2 seconds
  - **Verification**: Check Cloud Monitoring console for dashboard
  - **Reference**: DESIGN-025 (monitoring dashboards)

- [ ] **API quota usage dashboard configured (Gemini, SerpAPI, Claude)**
  - **Metrics**: Vertex AI quota, SerpAPI usage, Claude API usage
  - **Alert**: 80% quota threshold
  - **Verification**: Check Cloud Monitoring console for dashboard
  - **Reference**: DESIGN-025 (API monitoring)

### Incident Response

- [ ] **Security breach contact configured (email: security@abundance.app)**
  - **Configuration**: Privacy policy, Cloud Monitoring alerts
  - **Verification**: Verify email alias exists and routes to security team
  - **Reference**: DESIGN-025 (incident response)

- [ ] **Incident response runbook documented**
  - **Steps**: Detect → Assess → Contain → Eradicate → Recover → Learn
  - **Timeline**: Revoke compromised credentials within 1 hour
  - **Verification**: Verify runbook document exists
  - **Reference**: DESIGN-025 (incident response runbook)

---

## Deployment Validation Checklist

### Pre-Deployment (Before Any User Access)

- [ ] **All P0 items completed** (see sections above)
- [ ] **Automated security tests pass in CI/CD pipeline (Firestore rules, Storage rules)**
  - **Verification**: Check GitHub Actions for latest test run status
  - **Reference**: TEST-003 (automated testing)

- [ ] **Firebase Security Review Checklist completed** (see Firebase section above)
- [ ] **No high/critical vulnerabilities in npm audit**
  - **Command**: `cd functions && npm audit --audit-level=high`
  - **Verification**: 0 high/critical vulnerabilities
  - **Reference**: TEST-003 (Section 3.3.1)

- [ ] **No high/critical vulnerabilities in Xcode static analysis**
  - **Command**: `xcodebuild -project Abundance.xcodeproj analyze`
  - **Verification**: 0 security warnings
  - **Reference**: TEST-003 (Section 3.3.2)

### Pre-Public Launch (Before General Availability)

- [ ] **All P1 items completed** (see sections above)
- [ ] **Manual penetration testing completed** (optional for MVP, recommended for v1.0)
  - **Scope**: OWASP Top 10 validation, vulnerability assessment
  - **Deliverable**: Penetration test report
  - **Reference**: TEST-003 (manual testing)

- [ ] **Privacy audit completed by privacy counsel** (required for EU launch)
  - **Scope**: GDPR compliance, data flow validation, privacy policy review
  - **Deliverable**: Privacy audit report
  - **Reference**: TEST-003 (manual testing)

- [ ] **Load testing completed (verify rate limiting works under load)**
  - **Test**: 100 concurrent users, 1000 requests/minute
  - **Verification**: Rate limiting enforced (10 items/minute per user)
  - **Reference**: THREAT-MODEL-001 (Threat D-1, D-2, D-3)

---

## Final Sign-Off

**Security Team Approval**:

- [ ] iOS Security checklist reviewed and approved
- [ ] Firebase Security checklist reviewed and approved
- [ ] GCP Security checklist reviewed and approved
- [ ] GDPR/CCPA Compliance checklist reviewed and approved
- [ ] Monitoring & Alerting checklist reviewed and approved
- [ ] All P0 action items completed
- [ ] All P1 action items completed (or deferred with justification)
- [ ] Deployment validation completed

**Sign-Off**:

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Privacy & Security Architect | | | |
| iOS Lead Developer | | | |
| Backend Lead Developer | | | |
| Legal Counsel | | | |
| Product Manager | | | |

---

## P0 Action Items Summary (Must Complete Before Launch)

1. ✅ **Privacy firewall validation** - Automated tests verify no full photo uploads
2. ✅ **Firestore Security Rules testing** - CI/CD enforces 90% coverage
3. ✅ **Firebase Storage Rules testing** - 100% coverage target
4. ✅ **Uniform bucket access** - Deny public read on all buckets
5. ✅ **Firebase SCCs acceptance** - Google Cloud DPA accepted in GCP Console
6. ✅ **Transfer Impact Assessment** - TIA completed with legal counsel
7. ✅ **SerpAPI DPA review** - GDPR compliance verified
8. ✅ **Anthropic DPA review** - GDPR compliance verified

---

## P1 Action Items Summary (Must Complete Before Public Release)

1. ✅ **Email enumeration protection** - Enabled in Firebase Console
2. ✅ **Firebase App Check** - Configured for Firestore, Storage, Cloud Functions
3. ✅ **Signed URL expiration** - 5-minute server-side generation implemented
4. ✅ **Privacy policy legal review** - Legal counsel approves GDPR/CCPA disclosures

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial security hardening checklist, 5 categories | Privacy & Security Architect |
