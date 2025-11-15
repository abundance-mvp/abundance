# Apple Documentation Systematic Verification and Completion Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Systematically verify all Apple API documentation coverage by reading every framework overview, extracting all mentioned APIs, attempting to fetch detailed docs, and creating a comprehensive gap report.

**Architecture:** Directory-by-directory verification iterating through all 25+ framework directories in `docs/apple/`. For each directory: read overview → extract API mentions → check if detailed docs exist → attempt fetch missing docs → update manifest. Generate final gap analysis report showing what exists vs missing (including 404s).

**Tech Stack:** WebFetch (sosumi.ai), file I/O, JSON manifests, Markdown documentation

---

## Task 1: Setup and Planning

**Files:**
- Create: `docs/apple-docs-verification-report.md`
- Read: `docs/apple/README.md`
- Read: `docs/apple-docs-fetching-plan.md`

**Step 1: Create verification report template**

```bash
cat > /Users/w/code/spec-kit/docs/apple-docs-verification-report.md << 'EOF'
# Apple Documentation Verification Report

**Generated:** 2025-11-02
**Status:** In Progress

## Summary

- **Total Directories Verified:** 0/25
- **Total Overview Documents:** 0
- **Total API Classes Mentioned:** 0
- **Total Detailed Docs Found:** 0
- **Total Detailed Docs Missing:** 0
- **Total 404 Errors:** 0

---

## Verification Progress

### ✅ Completed Directories
None yet

### ⏳ In Progress
None

### ❌ Not Started
All 25 directories

---

## Detailed Findings by Directory

(Will be populated during verification)

---

## Missing Documentation Priority Matrix

### CRITICAL (Stage 2.2)
TBD

### HIGH (MVP)
TBD

### MEDIUM (Future)
TBD

---

## Recommendations

TBD
EOF
```

**Step 2: Read current status**

Run: `cat /Users/w/code/spec-kit/docs/apple/README.md`
Expected: See list of 25 directories

**Step 3: Commit verification report template**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: add systematic verification report template"
```

---

## Task 2: Verify auth/ Directory

**Files:**
- Read: `docs/apple/auth/authentication-services-overview.md`
- Read: `docs/apple/auth/keychain-services-overview.md`
- Read: `docs/apple/auth/manifest.json`
- Modify: `docs/apple-docs-verification-report.md`

**Step 1: List all markdown files in auth/**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/auth/*.md`
Expected: See 2 overview files

**Step 2: Read authentication-services-overview.md and extract API mentions**

Read the file and identify all API classes/protocols mentioned:
- Expected mentions: ASAuthorizationController, ASAuthorizationAppleIDProvider, ASAuthorizationAppleIDButton, SignInWithAppleButton, ASPasswordCredential, ASWebAuthenticationSession, ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest, ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequest, ASPasskeyAssertionCredential, ASPasskeyRegistrationCredential, ASOneTimeCodeCredential, ASAuthorizationResult, ASAuthorizationError, AuthorizationController

**Step 3: Check which detailed docs exist**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/auth/ | grep -v overview | grep -v manifest | grep .md`
Expected: No detailed API docs (only overviews exist)

**Step 4: Read keychain-services-overview.md and extract API mentions**

Expected additional mentions: SecItemAdd, SecItemCopyMatching, SecItemUpdate, SecItemDelete, kSecClass*, kSecAttr* constants

**Step 5: Update verification report for auth/**

Add to report:
```markdown
### auth/ - Authentication Services

**Status:** ✅ Verified
**Overview Docs:** 2
- authentication-services-overview.md
- keychain-services-overview.md

**API Classes Mentioned:** 15+
- ASAuthorizationController
- ASAuthorizationAppleIDProvider
- ASAuthorizationAppleIDButton
- SignInWithAppleButton
- ASPasswordCredential
- ASWebAuthenticationSession
- ASPasskeyAssertionCredential
- ASPasskeyRegistrationCredential
- ASOneTimeCodeCredential
- ASAuthorizationResult
- ASAuthorizationError
- And 5+ more...

**Detailed Docs Found:** 0
**Detailed Docs Missing:** 15+

**Priority Assessment:**
- CRITICAL: ASAuthorizationController, ASWebAuthenticationSession
- HIGH: ASPasswordCredential, SignInWithAppleButton
- MEDIUM: Passkey-related APIs
```

**Step 6: Commit auth/ verification**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: verify auth/ directory (0/15+ APIs documented)"
```

---

## Task 3: Attempt Fetch Missing auth/ CRITICAL APIs

**Files:**
- Create: `docs/apple/auth/asauthorizationcontroller.md` (if successful)
- Create: `docs/apple/auth/aswebauthenticationsession.md` (if successful)
- Modify: `docs/apple/auth/manifest.json`
- Modify: `docs/apple-docs-verification-report.md`

**Step 1: Attempt fetch ASAuthorizationController**

Use WebFetch:
- URL: `https://sosumi.ai/documentation/authenticationservices/asauthorizationcontroller`
- Prompt: "Extract the complete API documentation for ASAuthorizationController. Include: overview, availability, purpose, initialization methods, all key properties (delegate, presentationContextProvider), all key methods (performRequests, performRequest async), delegate protocols, and any important usage patterns. Format as detailed markdown suitable for developer reference."

If successful: Save to `docs/apple/auth/asauthorizationcontroller.md`
If 404: Note in verification report

**Step 2: Attempt fetch ASWebAuthenticationSession**

Use WebFetch:
- URL: `https://sosumi.ai/documentation/authenticationservices/aswebauthenticationsession`
- Prompt: "Extract the complete API documentation for ASWebAuthenticationSession. Include: overview, availability, purpose, initialization methods, all key properties (delegate, prefersEphemeralWebBrowserSession), all key methods (start, cancel), callback handling, error handling, and any important usage patterns for OAuth/OpenID flows. Format as detailed markdown suitable for developer reference."

If successful: Save to `docs/apple/auth/aswebauthenticationsession.md`
If 404: Note in verification report

**Step 3: Update manifest.json if docs fetched**

If any docs were successfully fetched, add entries to manifest:
```json
{
  "title": "ASAuthorizationController API",
  "original_url": "https://developer.apple.com/documentation/authenticationservices/asauthorizationcontroller",
  "sosumi_url": "https://sosumi.ai/documentation/authenticationservices/asauthorizationcontroller",
  "local_path": "asauthorizationcontroller.md",
  "fetch_date": "2025-11-02",
  "size_kb": 5
}
```

**Step 4: Update verification report with fetch results**

Update auth/ section with:
- Number of successful fetches
- Number of 404 errors
- List of 404 URLs for future reference

**Step 5: Commit auth/ documentation updates**

```bash
git add docs/apple/auth/
git commit -m "docs: fetch auth/ CRITICAL APIs (X successful, Y 404s)"
```

---

## Task 4: Verify biometrics/ Directory

**Files:**
- Read: `docs/apple/biometrics/local-authentication-overview.md`
- Read: `docs/apple/biometrics/manifest.json`
- Modify: `docs/apple-docs-verification-report.md`

**Step 1: List all markdown files in biometrics/**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/biometrics/*.md`
Expected: 1 overview file

**Step 2: Read local-authentication-overview.md and extract API mentions**

Expected mentions:
- LAContext (EXISTS - already fetched)
- LARight
- LARightStore
- LAPrivateKey
- LAPublicKey
- LAError
- LocalAuthenticationView
- LABiometryType

**Step 3: Check which detailed docs exist**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/biometrics/ | grep -v overview | grep .md`
Expected: No detailed docs (LAContext is in security/ directory)

**Step 4: Cross-reference with security/ directory**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/security/*.md`
Expected: Find lacontext.md there

**Step 5: Update verification report for biometrics/**

Add to report:
```markdown
### biometrics/ - Local Authentication

**Status:** ✅ Verified
**Overview Docs:** 1
- local-authentication-overview.md

**API Classes Mentioned:** 8
- LAContext (FOUND in security/)
- LARight
- LARightStore
- LAPrivateKey
- LAPublicKey
- LAError
- LocalAuthenticationView
- LABiometryType

**Detailed Docs Found:** 1 (LAContext in security/)
**Detailed Docs Missing:** 7

**Priority Assessment:**
- CRITICAL: LAContext (EXISTS)
- HIGH: LARight, LAError, LABiometryType
- MEDIUM: Cryptographic APIs (LAPrivateKey, LAPublicKey)
```

**Step 6: Commit biometrics/ verification**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: verify biometrics/ directory (1/8 APIs documented)"
```

---

## Task 5: Verify camera/ Directory

**Files:**
- Read: `docs/apple/camera/avfoundation-overview.md`
- Read: `docs/apple/camera/photokit-overview.md`
- Read: `docs/apple/camera/manifest.json`
- Modify: `docs/apple-docs-verification-report.md`

**Step 1: List all markdown files in camera/**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/camera/*.md`
Expected: 2 overview + 2 detailed docs (avcapturedevice, avcapturesession)

**Step 2: Read avfoundation-overview.md and extract API mentions**

Expected mentions:
- AVCaptureSession (EXISTS)
- AVCaptureDevice (EXISTS)
- AVCapturePhotoOutput
- AVCaptureDeviceInput
- AVCaptureVideoDataOutput
- AVCaptureMovieFileOutput
- AVCapturePhotoSettings
- AVCaptureConnection

**Step 3: Read photokit-overview.md and extract API mentions**

Expected mentions:
- PHPhotoLibrary
- PHAsset
- PHAssetCollection
- PHImageManager
- PHFetchResult
- PHChange

**Step 4: Count existing vs missing docs**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/camera/*.md | wc -l`
Expected: 4 total (2 overviews + 2 API docs)

**Step 5: Update verification report for camera/**

Add to report:
```markdown
### camera/ - AVFoundation & PhotoKit

**Status:** ✅ Verified
**Overview Docs:** 2
- avfoundation-overview.md
- photokit-overview.md

**API Classes Mentioned:** 14+
- AVCaptureSession (EXISTS ✅)
- AVCaptureDevice (EXISTS ✅)
- AVCapturePhotoOutput
- AVCaptureDeviceInput
- AVCaptureVideoDataOutput
- PHPhotoLibrary
- PHAsset
- PHImageManager
- And 6+ more...

**Detailed Docs Found:** 2
**Detailed Docs Missing:** 12+

**Priority Assessment:**
- CRITICAL: AVCaptureSession (EXISTS), AVCaptureDevice (EXISTS)
- HIGH: AVCapturePhotoOutput, AVCaptureDeviceInput, PHPhotoLibrary
- MEDIUM: PHAsset, PHImageManager
```

**Step 6: Commit camera/ verification**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: verify camera/ directory (2/14+ APIs documented)"
```

---

## Task 6: Verify content-safety/ Directory

**Files:**
- Read: `docs/apple/content-safety/sensitive-content-analysis-overview.md`
- Read: `docs/apple/content-safety/manifest.json`
- Modify: `docs/apple-docs-verification-report.md`

**Step 1: Read sensitive-content-analysis-overview.md and extract API mentions**

Expected mentions:
- SCSensitivityAnalyzer
- VideoAnalysisHandler
- SCVideoStreamAnalyzer
- SCSensitivityAnalysis

**Step 2: Check detailed docs**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/content-safety/*.md | grep -v overview`
Expected: None

**Step 3: Update verification report**

Add to report with 0/4 APIs documented, all HIGH priority for Trust & Safety

**Step 4: Commit content-safety/ verification**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: verify content-safety/ directory (0/4 APIs documented)"
```

---

## Task 7: Verify foundation/ Directory

**Files:**
- Read: `docs/apple/foundation/foundation-overview.md`
- Read: `docs/apple/foundation/manifest.json`
- Modify: `docs/apple-docs-verification-report.md`

**Step 1: Read foundation-overview.md**

Expected mentions: URLSession, JSONEncoder, JSONDecoder, FileManager, UserDefaults, Notification, NotificationCenter, Date, Calendar, DateFormatter, UUID, Data, etc. (50+ APIs likely)

**Step 2: Check detailed docs**

Run: `ls -1 /Users/w/code/spec-kit/docs/apple/foundation/*.md | grep -v overview`
Expected: None or very few

**Step 3: Update verification report**

Note: Foundation is massive - may need separate sub-task for HIGH priority only

**Step 4: Commit foundation/ verification**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: verify foundation/ directory"
```

---

## Task 8: Verify networking/ Directory

**Files:**
- Read: `docs/apple/networking/network-overview.md`
- Read: `docs/apple/networking/combine-overview.md`
- Read: `docs/apple/networking/manifest.json`
- Modify: `docs/apple-docs-verification-report.md`

**Step 1: Read network-overview.md and extract API mentions**

Expected mentions:
- NWEndpoint
- NWConnection
- NWParameters
- NWPathMonitor
- NWBrowser
- NWListener
- NWProtocolTLS.Options

**Step 2: Read combine-overview.md and extract API mentions**

Expected mentions:
- Publisher
- Subscriber
- Subject
- PassthroughSubject
- CurrentValueSubject
- AnyCancellable
- Operators (map, filter, etc.)

**Step 3: Update verification report**

Add networking/ section showing 0 detailed docs out of 15+ mentioned

**Step 4: Commit networking/ verification**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: verify networking/ directory (0/15+ APIs documented)"
```

---

## Task 9: Verify Remaining 17 Directories

**Files:**
- Modify: `docs/apple-docs-verification-report.md`

**For each remaining directory:**
1. image-processing/
2. liquid-glass/
3. maps/ (we have MKMapView, check for others)
4. notifications/ (we have some, verify completeness)
5. observation/
6. payment/
7. payments/ (we have some, verify completeness)
8. performance/
9. privacy/
10. scanning/ (we have some, verify completeness)
11. security/ (we have LAContext, verify completeness)
12. sharing/
13. storage/ (we have Core Data APIs, verify completeness)
14. swift/ (we have Core ML config, verify completeness)
15. swiftui/ (we have View/State/Binding, verify completeness)
16. testing/ (we have XCTestCase, verify completeness)
17. vision/ (we have some, verify completeness)
18. visual-intelligence/

**Step 1-18: Repeat verification pattern for each directory**

For each:
- Read all overview docs
- Extract API mentions
- Check existing detailed docs
- Count found vs missing
- Assign priorities
- Update report

**Step 19: Commit after every 3-4 directories**

Pattern:
```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: verify [dir1/, dir2/, dir3/] directories"
```

---

## Task 10: Generate Summary Statistics

**Files:**
- Modify: `docs/apple-docs-verification-report.md` (Summary section)

**Step 1: Count total directories verified**

Run: `grep "Status: ✅ Verified" docs/apple-docs-verification-report.md | wc -l`
Expected: 25

**Step 2: Count total API classes mentioned**

Sum all "API Classes Mentioned" numbers from each directory section

**Step 3: Count total detailed docs found**

Sum all "Detailed Docs Found" numbers from each directory section

**Step 4: Count total missing docs**

Sum all "Detailed Docs Missing" numbers from each directory section

**Step 5: Update summary section**

Replace placeholders with actual counts:
```markdown
## Summary

- **Total Directories Verified:** 25/25 ✅
- **Total Overview Documents:** [actual count]
- **Total API Classes Mentioned:** [actual count]
- **Total Detailed Docs Found:** [actual count]
- **Total Detailed Docs Missing:** [actual count]
- **Total 404 Errors:** [actual count from fetch attempts]

**Coverage Percentage:** [found / (found + missing) * 100]%
```

**Step 6: Commit summary update**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: complete verification summary statistics"
```

---

## Task 11: Generate Missing Documentation Priority Matrix

**Files:**
- Modify: `docs/apple-docs-verification-report.md` (Priority Matrix section)

**Step 1: Extract all CRITICAL missing docs**

Scan report for "CRITICAL" priority APIs that are missing

**Step 2: Extract all HIGH missing docs**

Scan report for "HIGH" priority APIs that are missing

**Step 3: Extract all MEDIUM missing docs**

Scan report for "MEDIUM" priority APIs that are missing

**Step 4: Update Priority Matrix section**

Format as actionable lists:
```markdown
## Missing Documentation Priority Matrix

### CRITICAL (Stage 2.2) - [X] APIs
Must fetch before Stage 2.2 implementation:
- auth/: ASAuthorizationController, ASWebAuthenticationSession
- camera/: AVCapturePhotoOutput, AVCaptureDeviceInput
- [continue with all CRITICAL]

### HIGH (MVP) - [Y] APIs
Should fetch for MVP features:
- biometrics/: LARight, LAError, LABiometryType
- content-safety/: All 4 APIs
- [continue with all HIGH]

### MEDIUM (Future) - [Z] APIs
Can fetch on-demand during implementation:
- [list all MEDIUM priority]
```

**Step 5: Commit priority matrix**

```bash
git add docs/apple-docs-verification-report.md
git commit -m "docs: add missing documentation priority matrix"
```

---

## Task 12: Generate Recommendations

**Files:**
- Modify: `docs/apple-docs-verification-report.md` (Recommendations section)
- Modify: `docs/apple-docs-fetching-plan.md`

**Step 1: Write Phase 1.5 recommendation**

If significant CRITICAL APIs are missing:
```markdown
## Recommendations

### Immediate Actions (Phase 1.5)

**Status:** Phase 1 was incomplete - claimed 19 CRITICAL APIs but verified only [actual] exist.

**Missing CRITICAL APIs:** [X]
Must fetch immediately for Stage 2.2:
1. [prioritized list of top 10-15 CRITICAL missing APIs]

**Estimated Time:** 2-3 hours for batch fetching + manifest updates

**Blocker Risk:** HIGH - Stage 2.2 implementation cannot proceed without these APIs
```

**Step 2: Write Phase 2 recommendation**

For HIGH priority gaps:
```markdown
### Phase 2 Actions (MVP)

**Missing HIGH Priority APIs:** [Y]
Should fetch before MVP feature implementation:
- By feature area: [group by framework]
- Estimated time: 4-6 hours

**MVP Risk:** MEDIUM - Can implement basic features but will lack comprehensive API coverage
```

**Step 3: Write Phase 3 recommendation**

For MEDIUM priority:
```markdown
### Phase 3 Actions (On-Demand)

**Missing MEDIUM Priority APIs:** [Z]
Fetch as needed during implementation:
- Maintain current approach: fetch when implementation requires it
- Reference sosumi.ai URLs for quick access
```

**Step 4: Write 404 handling strategy**

```markdown
### 404 Documentation Handling

**APIs that returned 404:** [list if any]

**Strategy:**
1. Check alternative URL patterns (lowercase, different path structures)
2. Search sosumi.ai directly for these APIs
3. If truly missing from sosumi.ai, reference official Apple docs
4. Document which APIs require Apple Developer access
```

**Step 5: Update apple-docs-fetching-plan.md**

Correct the completion percentages and add Phase 1.5 to the plan

**Step 6: Commit recommendations**

```bash
git add docs/apple-docs-verification-report.md docs/apple-docs-fetching-plan.md
git commit -m "docs: add verification recommendations and Phase 1.5 plan"
```

---

## Task 13: Final Verification Report

**Files:**
- Read: `docs/apple-docs-verification-report.md`
- Create: Summary output for user

**Step 1: Generate human-readable summary**

Read the completed report and create a concise summary:
```
VERIFICATION COMPLETE

Directories Verified: 25/25
API Classes Found: [X]
Detailed Docs Existing: [Y]
Detailed Docs Missing: [Z]
Coverage: [Y/(Y+Z)]%

CRITICAL GAPS (Stage 2.2 Blockers): [N] APIs
HIGH PRIORITY GAPS (MVP): [M] APIs
MEDIUM PRIORITY GAPS: [P] APIs

404 Errors Encountered: [count]

RECOMMENDATION: [immediate action needed]
```

**Step 2: Present findings to user**

Display summary and ask:
"Verification complete. Would you like me to:
1. Execute Phase 1.5 (fetch missing CRITICAL APIs immediately)
2. Generate focused fetch plan for specific framework
3. Review detailed findings by directory
4. Update apple-docs-fetching-plan.md with corrections"

**Step 3: Final commit**

```bash
git add .
git commit -m "docs: complete systematic Apple documentation verification

Verified 25 directories, found [Y]/[Z] APIs documented.
Identified [N] CRITICAL gaps for Stage 2.2.
See apple-docs-verification-report.md for full details."
```

---

## Execution Notes

**Total Estimated Time:** 6-8 hours for complete verification + selective fetching
**Batch Opportunities:** Can parallelize directory verification (Tasks 2-9)
**Dependencies:** None - each directory verification is independent
**Risks:**
- Many sosumi.ai 404s may require alternative approaches
- Foundation/ and SwiftUI/ are massive - may need subset strategy
**Testing:** Each commit includes verification counts that should add up correctly

---

## Post-Completion Actions

After this plan completes:
1. Review verification report with user
2. Decide on Phase 1.5 scope (immediate CRITICAL fetch)
3. Update main README.md with realistic completion stats
4. Consider automation script for ongoing verification
5. Document which APIs cannot be fetched from sosumi.ai

