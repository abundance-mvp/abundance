# EFFORT-ESTIMATES-001: Complexity Reference

**Created**: 2025-11-12
**Purpose**: Simple complexity indicators for task estimation (agent-driven development)

---

## T-Shirt Sizing

| Size | Complexity | Examples |
|------|------------|----------|
| XS | Trivial | Add constant, fix typo, update doc |
| S | Simple | Add helper function, simple UI component, unit test suite |
| M | Moderate | ViewModel + tests, API endpoint + tests, feature module |
| L | Large | Multi-screen flow, Cloud Function + triggers, major epic (Camera, AI Pipeline Layer) |
| XL | Extra Large | Massive epic (Full AI Pipeline Layers 2-3), new platform (Android client) |

---

## Epic Complexity

| Epic | T-Shirt | Rationale |
|------|---------|-----------|
| Epic 1: Authentication | M | Apple Sign-In + Firebase Auth + Backend endpoint + tests |
| Epic 2: iOS Setup | M | Project config, CI/CD, SwiftLint, Sourcery |
| Epic 3: Camera/Layer 1 | L | AVCaptureSession + Vision + Barcode + Upload + tests |
| Epic 4: Backend Functions | L | 8 HTTP + 3 triggers + 2 jobs + Firestore + tests |
| Epic 5: AI Pipeline | XL | Layers 2a/2b/3 + 4 providers + cost tracking + tests |
| Epic 6: Catalog View | M | ViewModel + View + Search + Filters + tests |
| Epic 7: Item Detail | M | Detail view + Edit + API integration + tests |
| Epic 8: Onboarding | M | 3-screen flow + Profile + Export + tests |
| Epic 9: Testing | L | Unit/Integration/E2E across all sprints |

---
