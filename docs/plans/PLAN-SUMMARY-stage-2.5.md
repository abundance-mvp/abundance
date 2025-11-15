# PLAN SUMMARY: Stage 2.5 - Privacy & Security Architecture

**Created**: 2025-11-09
**Stage**: 2.5 - Privacy & Security Architecture
**Status**: Plan Complete - Ready for Gate 1 Approval ✅
**Expert Agent**: Privacy & Security Architect

---

## What This Stage Accomplishes

Stage 2.5 provides **comprehensive security hardening and privacy validation** for the complete Abundance MVP architecture. With all technical components designed (Stages 2.0-2.4), this stage identifies and remediates security gaps, validates GDPR/CCPA compliance, and creates a pre-launch security checklist.

**Key Accomplishments**:
1. ✅ Research validation complete (12 iOS/Firebase/GCP security claims verified, November 2025 sources)
2. ✅ 4 security gaps identified (2 P0 blockers, 2 P1 before-launch items)
3. 🎯 STRIDE threat model (identify all attack vectors across iOS, Firebase, GCP, AI APIs)
4. 🎯 Security & privacy architecture (comprehensive design integrating all mitigations)
5. 🎯 3 ADRs (data encryption, photo privacy, authentication/authorization)
6. 🎯 Privacy impact assessment (GDPR 5 requirements, CCPA 3 requirements validated)
7. 🎯 Security test plan (penetration, privacy audits, vulnerability scanning, compliance testing)
8. 🎯 Security hardening checklist (pre-launch review with P0/P1 action items)

**Ready for Stage 3.1**: With security architecture complete, iOS implementation research can proceed with security requirements embedded.

---

## Critical Security Gaps Identified (Research Validation)

**File**: `docs/validation/RESEARCH-VALIDATION-stage-2.5.md`

### P0 Blockers (Must Fix Before Any Launch)

#### Gap #1: Firebase Misconfiguration Risk (OWASP #2 in 2025)
- **Risk**: Security misconfiguration is #2 in OWASP Top 10 2025
- **Vulnerability**: Incorrect Firestore/Storage rules expose user data
- **Mitigation**: Automated security rules testing in CI/CD pipeline
- **Deliverables**: THREAT-MODEL-001 (threat analysis), TEST-003 (automated tests), SECURITY-HARDENING-CHECKLIST-001 (pre-deployment validation)

#### Gap #2: GDPR Data Transfer Compliance
- **Risk**: Firebase Auth stores data in US by default, requires SCCs + Transfer Impact Assessment
- **Vulnerability**: EU data transfer without proper safeguards violates GDPR Article 46
- **Mitigation**: Accept Firebase SCCs in GCP Console, conduct Transfer Impact Assessment (TIA)
- **Timeline**: Complete before EU user beta testing (Month 4)
- **Deliverables**: PRIVACY-IMPACT-ASSESSMENT-001 (GDPR compliance), ADR-023 (authentication strategy with EU considerations)

### P1 Before Launch (Must Fix Before Public Release)

#### Gap #3: Signed URL 7-Day Maximum Expiration
- **Risk**: Firebase/GCS signed URLs have 7-day maximum expiration (verified November 2025)
- **Current Architecture**: iOS generates signed URLs on upload (violates privacy principle - images accessible for 7 days)
- **Required Architecture Change**: Server-side signed URL generation with 2-5 minute expiration
- **Mitigation**: Cloud Functions generate short-lived signed URLs immediately before passing to SerpAPI
- **Deliverables**: DESIGN-025 (architecture change), ADR-022 (photo privacy validation)

#### Gap #4: Email Enumeration Protection (New 2025 Feature)
- **Risk**: Attackers can enumerate valid email addresses via login attempts
- **Firebase Feature**: Email enumeration protection (opt-in, new in 2025)
- **Mitigation**: Enable in Firebase Console (Authentication > Settings)
- **Deliverables**: ADR-023 (authentication strategy), SECURITY-HARDENING-CHECKLIST-001 (pre-deployment validation)

---

## Research Validation Summary

### 12 Technical Claims Verified (November 2025 Sources)

**iOS Security** (Apple Documentation):
1. ✅ iOS Keychain: AES-256-GCM encryption with Secure Enclave integration
2. ✅ Apple Sign-In: OAuth 2.0 with privacy protections (no email sharing without consent)
3. ✅ AVCaptureSession: Camera privacy permissions enforced by iOS
4. ✅ App Transport Security: TLS 1.2+ required, TLS 1.0/1.1 deprecated
5. ✅ Data Protection API: File-level AES-256 encryption for temporary files

**Firebase Security** (Firebase Documentation, November 2025):
6. ✅ Firestore Security Rules: Row-level access control with `request.auth.uid`
7. ✅ Email enumeration protection: New 2025 feature, opt-in required (P1 action item)
8. ⚠️ Signed URLs: 7-day maximum expiration, server-side generation required (P1 architecture change)
9. ✅ App Check: Request attestation for abuse prevention (optional for MVP)

**GCP Security** (GCP Documentation, November 2025):
10. ✅ Secret Manager: AES-256 encryption, automatic rotation, audit logging
11. ✅ Cloud Functions IAM: Bearer token authentication via Firebase ID tokens
12. ✅ Cloud Storage: Signed URLs have 7-day maximum expiration (same as Firebase Storage)

**Token Usage**: 20K / 25K budget (80% efficiency)

---

## Artifacts to Create (8 Documents)

### Threat Modeling
1. **THREAT-MODEL-001-stride-analysis.md** - STRIDE analysis (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)
   - Minimum 15 threats identified across iOS, Firebase, GCP, AI APIs
   - Each threat has risk level (High/Medium/Low), mitigation strategy, verification method
   - All P0/P1 security gaps addressed

### Design Documents
2. **DESIGN-025-security-privacy-architecture.md** - Comprehensive security architecture
   - Layer 1: iOS Client Security (Keychain, Apple Sign-In, Camera Privacy, ATS, Data Protection)
   - Layer 2: Firebase Security (Firestore rules, Storage rules, email enumeration protection, App Check)
   - Layer 3: GCP Security (Secret Manager, Cloud Functions IAM, signed URL strategy with 2-5 minute expiration)
   - Layer 4: AI API Security (Vertex AI, SerpAPI, Anthropic)
   - Monitoring & Alerting (Cloud Logging, Cloud Monitoring, Budget Alerts)

3. **PRIVACY-IMPACT-ASSESSMENT-001.md** - GDPR/CCPA compliance validation
   - GDPR: 5 requirements (Right to Access, Right to Erasure, Data Minimization, Data Transfer, DPA Review)
   - CCPA: 3 requirements (Right to Know, Right to Delete, Do Not Sell)
   - P0 action items: SCCs acceptance, Transfer Impact Assessment (TIA)
   - Privacy policy requirements (legal review needed)

4. **SECURITY-HARDENING-CHECKLIST-001.md** - Pre-launch security review checklist
   - iOS Security (5 items: Keychain, ATS, camera permissions, Data Protection, privacy firewall)
   - Firebase Security (5 items: Firestore rules, Storage rules, email enumeration, App Check, security review)
   - GCP Security (5 items: Secret Manager, Cloud Functions IAM, signed URLs, bucket access, budget alerts)
   - GDPR/CCPA Compliance (5 items: SCCs, TIA, privacy policy, Right to Access, Right to Erasure)
   - Monitoring & Alerting (4 items: Cloud Logging, Cloud Monitoring, Budget Alerts, Incident Response)

### Architecture Decision Records (ADRs)
5. **ADR-021-data-encryption-approach.md** - Encryption at rest, in transit, in use
   - Data at Rest: iOS Keychain (AES-256-GCM), Firestore/Storage (AES-256 default), temporary photos (Data Protection API)
   - Data in Transit: HTTPS with TLS 1.2+ (iOS), TLS 1.3 (Cloud Functions ↔ AI APIs)
   - Data in Use: iOS secure sandbox, Cloud Functions ephemeral memory
   - Key Management: Firebase ID tokens (1-hour expiration), API keys (Secret Manager, 90-day rotation)

6. **ADR-022-photo-privacy-protection.md** - Privacy firewall validation
   - Privacy Firewall Requirements: Full photos on-device only, Vision crops to bounding boxes, immediate deletion, only cropped objects uploaded
   - Validation Strategy: Code review, Firebase Storage audit (< 500KB files), network traffic analysis
   - GDPR Compliance: Data Minimization (cropped objects only), Purpose Limitation (AI cataloging), Storage Limitation (90-day lifecycle)
   - Test Cases: File size verification, network traffic capture, storage audit

7. **ADR-023-authentication-authorization-strategy.md** - Complete auth strategy
   - Authentication Flow: Apple Sign-In (OAuth 2.0) → Firebase ID token → Keychain storage (AES-256-GCM)
   - Authorization Patterns: Firestore row-level security (`request.auth.uid`), Storage user folder isolation, Cloud Functions bearer token validation
   - Session Management: 1-hour token expiration, automatic refresh, logout deletes Keychain tokens
   - P1 Action Item: Email enumeration protection (Firebase Console configuration)

### Test Strategy
8. **TEST-003-security-test-plan.md** - Comprehensive security testing
   - Penetration Testing: Firestore rules, Storage rules, API endpoints, rate limiting
   - Privacy Audits: Privacy firewall validation (network traffic), data retention (90-day lifecycle), GDPR Right to Erasure (cascade delete)
   - Vulnerability Scanning: Firebase misconfiguration (P0), OWASP Top 10, dependency scanning (npm audit, Xcode)
   - Compliance Testing: GDPR data export (30 days), GDPR data deletion (30 days), CCPA privacy policy disclosure

### Checkpoint
9. **CHECKPOINT-stage-2.5-2025-11-09.md** - Stage completion summary (created in Phase 5)

---

## P0/P1 Action Items Summary

### P0 Blockers (Must Complete Before Any Launch)
1. **Firebase Misconfiguration Testing**: Automated security rules tests in CI/CD pipeline (THREAT-MODEL-001, TEST-003, SECURITY-HARDENING-CHECKLIST-001)
2. **GDPR SCCs Acceptance**: Accept Firebase Standard Contractual Clauses in GCP Console (PRIVACY-IMPACT-ASSESSMENT-001, ADR-023)
3. **GDPR Transfer Impact Assessment**: Conduct TIA with legal counsel for US data transfer (PRIVACY-IMPACT-ASSESSMENT-001)

### P1 Before Launch (Must Complete Before Public Release)
1. **Signed URL Architecture Change**: Server-side generation with 2-5 minute expiration (DESIGN-025, ADR-022)
2. **Email Enumeration Protection**: Enable in Firebase Console (ADR-023, SECURITY-HARDENING-CHECKLIST-001)

---

## GDPR/CCPA Compliance Summary

### GDPR (5 Requirements)
1. **Right to Access** (Article 15): ✅ Export function implemented (`POST /api/v1/users/:id/export`), JSON download within 30 days
2. **Right to Erasure** (Article 17): ✅ Cascade delete strategy (user → items → storage → AI metadata), complete within 30 days
3. **Data Minimization** (Article 5): ✅ Privacy firewall (only cropped objects uploaded, not full photos), verified in DESIGN-015, ADR-022
4. **Data Transfer** (Article 46): ⚠️ **P0 ACTION ITEM** - Firebase Auth US storage requires SCCs + TIA before EU launch
5. **DPA Review** (Article 28): ⚠️ Review Firebase (Google), SerpAPI, Anthropic DPAs for data retention policies

### CCPA (3 Requirements)
1. **Right to Know** (Section 1798.100): ✅ Privacy policy disclosure (camera photos, cropped objects, AI processing), legal review required
2. **Right to Delete** (Section 1798.105): ✅ Same as GDPR Right to Erasure (cascade delete, 30-day timeline)
3. **Do Not Sell** (Section 1798.120): ✅ No data sales occur, AI APIs are service providers (not buyers), disclosure in privacy policy

---

## Technology Stack Alignment

**iOS Platform** (from TECH-STACK-MAP-001):
- iOS 26.0+ (SwiftUI, Vision Framework, AVFoundation, AuthenticationServices, Keychain Services)
- Security Frameworks: Keychain (AES-256-GCM), App Transport Security (TLS 1.2+), Data Protection API (file-level encryption)

**Firebase Platform**:
- Firebase Authentication (Apple Sign-In, OAuth 2.0)
- Cloud Firestore (row-level security rules, verified in SECURITY-RULES-001)
- Firebase Storage (user folder isolation, signed URLs, verified in STORAGE-RULES-001)

**GCP Platform**:
- Google Secret Manager (API key storage, AES-256 encryption, 90-day rotation)
- Cloud Functions (IAM bearer token authentication, ephemeral compute)
- Cloud Storage (signed URLs, 7-day maximum expiration, requires architecture change)

**Third-Party APIs**:
- Vertex AI Gemini 2.5 Flash-Lite (Layer 2a attribute extraction)
- SerpAPI Google Lens (Layer 2b product search)
- Anthropic Claude Sonnet 4.5 Batch (Layer 3 synthesis)

---

## Risks Identified

### Risk 1: GDPR Data Transfer Compliance Complexity
- **Impact**: High (blocker for EU launch if not resolved)
- **Probability**: Medium (SCCs and TIA are well-documented processes)
- **Mitigation**: Accept Firebase SCCs (P0, 1 day), conduct TIA with legal counsel (P0, 1 week), document safeguards, consider EU region
- **Timeline**: Complete before EU user beta testing (Month 4)

### Risk 2: Firebase Misconfiguration Despite Testing
- **Impact**: High (privacy breach, GDPR violation)
- **Probability**: Low (automated testing + manual checklist + external audit)
- **Mitigation**: Automated tests in CI/CD (P0), Firebase Security Review Checklist (P0), external security audit (recommended v1.0)

### Risk 3: Signed URL Architecture Change Breaks SerpAPI Integration
- **Impact**: Medium (Layer 2b product search fails)
- **Probability**: Low (architecture change isolated to Cloud Function)
- **Mitigation**: Test in Firebase Emulator Suite, integration test (signed URL → SerpAPI → verify success), fallback to 7-day URLs (technical debt)

### Risk 4: Privacy Firewall Bypass via Code Change
- **Impact**: High (full photos uploaded, privacy violation)
- **Probability**: Very Low (automated testing + code review + privacy audit)
- **Mitigation**: Automated test (< 500KB files, CI/CD), Firebase Storage rules (10MB max), privacy audit checklist

---

## Consistency Verification

### Cross-Reference with Stage 2.4

| Stage 2.4 Output | Stage 2.5 Integration | Status |
|------------------|----------------------|--------|
| DESIGN-015 (privacy firewall) | ADR-022 validates privacy architecture (full photos never leave device) | ✅ Aligned |
| DESIGN-012 (camera capture) | DESIGN-025 documents camera privacy permissions (AVCaptureSession) | ✅ Aligned |
| DESIGN-016 (Cloud Storage uploads) | ADR-022 validates signed URL expiration (P1 architecture change) | ⚠️ Architecture Change Required |
| DESIGN-024 (Firestore listeners) | DESIGN-025 documents real-time sync security (authenticated listeners) | ✅ Aligned |

### Cross-Reference with Stage 2.3

| Stage 2.3 Output | Stage 2.5 Integration | Status |
|------------------|----------------------|--------|
| SECURITY-RULES-001 (Firestore rules) | THREAT-MODEL-001 validates row-level access control, TEST-003 adds automated testing | ✅ Enhanced with Testing |
| STORAGE-RULES-001 (Firebase Storage rules) | THREAT-MODEL-001 validates user folder isolation, ADR-022 adds signed URL expiration requirements | ⚠️ Signed URL Change Required |
| DATA-MODEL-001 (Firestore schema) | PRIVACY-IMPACT-ASSESSMENT-001 validates userId-based isolation for GDPR compliance | ✅ Aligned |
| AI-INTEGRATION-LAYER-001 (cloud AI) | DESIGN-025 documents AI API security (Secret Manager, rate limiting, monitoring) | ✅ Aligned |

### Cross-Reference with Stage 2.2

| Stage 2.2 Output | Stage 2.5 Integration | Status |
|------------------|----------------------|--------|
| ADR-010 (MVVM architecture) | DESIGN-025 documents ViewModels call secure services (Keychain, Firebase) | ✅ Aligned |
| DESIGN-007 (Firebase SDK integration) | ADR-023 documents Firebase Auth security (Apple Sign-In, token storage in Keychain) | ✅ Aligned |
| DESIGN-010 (iOS data persistence) | ADR-021 documents Keychain encryption (AES-256-GCM, Secure Enclave) | ✅ Aligned |

### Cross-Reference with Stage 2.0

| Stage 2.0 Output | Stage 2.5 Integration | Status |
|------------------|----------------------|--------|
| ADR-013 (Vision Framework strategy) | ADR-022 validates privacy firewall (on-device processing, no full photo uploads) | ✅ Aligned |
| ADR-014 (Cloud AI selection) | DESIGN-025 documents AI API security (Vertex AI, SerpAPI, Anthropic) | ✅ Aligned |
| DESIGN-004 (4-layer AI pipeline) | THREAT-MODEL-001 identifies security threats across all 4 layers (Layer 1-3) | ✅ Aligned |

**Result**: 1 architecture change required (signed URL expiration, P1), otherwise zero contradictions ✅

---

## Next Stage Preview

### Stage 3.1: iOS Implementation Research

**Objective**: Research iOS-specific implementation patterns for security and privacy features

**Prerequisites**:
- ✅ Stage 2.0 complete (AI architecture)
- ✅ Stage 2.1 complete (tech stack locked)
- ✅ Stage 2.2 complete (iOS architecture)
- ✅ Stage 2.3 complete (backend architecture)
- ✅ Stage 2.4 complete (CV pipeline architecture)
- ✅ Stage 2.5 complete (security & privacy architecture)

**Planned Artifacts** (4-5 documents):
1. RESEARCH-002-ios-keychain-implementation-patterns.md (secure token storage with Keychain Services)
2. RESEARCH-003-ios-privacy-permissions-implementation.md (AVCaptureSession, PHPickerViewController)
3. RESEARCH-004-ios-firebase-sdk-security-patterns.md (Firebase Auth, Firestore listeners, Storage signed URLs)
4. CODE-EXAMPLES-002-ios-security-implementations.md (Swift code examples for Keychain, ATS, Data Protection)
5. PLAN-SUMMARY-stage-3.1.md

**Expert Agent**: iOS Architecture Expert

**Why Stage 2.5 Must Complete First**: iOS implementation research requires knowing the security requirements (Keychain encryption level, camera permissions, signed URL expiration, privacy firewall validation) before researching implementation patterns. Without security architecture certainty, iOS implementation would be speculative.

---

## References

### Previous Stages
- `docs/plans/PLAN-SUMMARY-stage-2.4.md` (CV pipeline complete)
- `docs/plans/PLAN-SUMMARY-stage-2.3.md` (Backend architecture)
- `docs/plans/PLAN-SUMMARY-stage-2.2.md` (iOS architecture)
- `docs/plans/PLAN-SUMMARY-stage-2.1.md` (Tech stack locked)
- `docs/plans/PLAN-SUMMARY-stage-2.0.md` (AI research complete)

### Technology Stack
- `docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md`

### Existing Security Artifacts
- `docs/design/DESIGN-015-privacy-architecture.md` (privacy firewall)
- `docs/design/SECURITY-RULES-001-firestore-rules.md` (Firestore row-level security)
- `docs/design/STORAGE-RULES-001-firebase-storage-rules.md` (Firebase Storage signed URLs)
- `docs/tech-stack/DATA-MODEL-001-firestore-schema.md` (userId-based isolation)

### Research Validation
- `docs/validation/RESEARCH-VALIDATION-stage-2.5.md` (12 claims verified, 4 security gaps identified, November 2025 sources)

### Detailed Plan
- `docs/plans/2025-11-09-stage-2.5-privacy-security-architecture.md` (complete implementation plan)

### Master Pipeline
- `docs/abundance-analysis-pipeline-design.md` (Stage 2.5 section, lines 1076-1165)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-09 | 1.0 | Initial plan summary, Stage 2.5 privacy & security architecture complete | Privacy & Security Architect |

---

**Status**: ✅ **STAGE 2.5 PLAN COMPLETE**

**Next Step**: Gate 1 - Human reviews research validation report and implementation plan, approves execution (Phase 4)
