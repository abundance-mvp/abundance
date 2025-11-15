# Stage 2.1 Archive - High-Level Tech Stack Mapping

**Archive Date**: 2025-11-06
**Reason**: Re-running Stage 2.1 using verified-stage-development skill
**Original Status**: Completed (2025-11-01)

---

## Why This Was Archived

The original Stage 2.1 documents were created before the verified-stage-development skill was fully implemented. To ensure consistency with the new staged development methodology and to regenerate specs using the latest skill framework, these documents have been archived and Stage 2.1 will be re-executed.

---

## Archived Documents

### ADRs (Architecture Decision Records)
- **ADR-005**: GCP Platform Selection
- **ADR-006**: Monolith-First Architecture
- **ADR-007**: REST API Design
- **ADR-008**: Firestore Database
- **ADR-009**: Firebase Authentication
- **ADR-010**: Hybrid Storage Strategy
- **ADR-011**: Cloud Functions Compute
- **ADR-012**: Shopping Graph Primary AI
- **ADR-013**: Vision Framework Strategy
- **ADR-014**: Cloud AI Provider Selection
- **ADR-015**: AI Reasoning Layer Architecture
- **ADR-016**: Image Hosting Strategy
- **ADR-017**: LLM Parsing Architecture

### Tech Stack Documents
- **TECH-STACK-MAP-001**: Complete Technology Stack Map (v2.1, includes barcode feature)
- **API-CONTRACTS-001**: Service Interface Definitions
- **SCHEMA-001**: Enriched Item Metadata (includes barcode fields)

### Design Documents
- **DESIGN-004**: Computer Vision Pipeline (4-layer architecture, includes barcode workflow)
- **DESIGN-005**: Layer 2b Product Search Architecture (SerpAPI integration)

### Test Documents
- **TEST-STRATEGY-001**: Test Pyramid Strategy

### Research Documents
- **SYNTHESIS-stage-2.1-comprehensive-verification**: Comprehensive verification report
- **RECONCILIATION-design-004-vs-stage-2.1**: Architecture reconciliation document
- **RESEARCH-serpapi-gcs-integration-2025-11-01**: SerpAPI GCS integration research

### Checkpoints
- **CHECKPOINT-stage-2.1-verification-complete**: Final verification checkpoint
- **stage-2.1-execution-plan-REVISED**: Revised execution plan

---

## Notable Features in Archived Version

The archived Stage 2.1 documents include:

1. **4-Layer AI Pipeline Architecture**:
   - Layer 1: On-device (YOLOv3-Tiny via Vision Framework)
   - Layer 2a: Attribute extraction (Gemini 2.5 Flash-Lite)
   - Layer 2b: Product search (SerpAPI Google Lens + Claude Haiku)
   - Layer 3: AI synthesis (Claude Sonnet 4.5)

2. **Barcode Scanning Feature** (Added 2025-11-06):
   - UPCitemdb DEV Plan ($99/month)
   - Barcode-first lookup strategy
   - 7.1% cost reduction for barcoded items

3. **Multi-AI Provider Strategy**:
   - SerpAPI for visual product search
   - Gemini for attribute extraction
   - Claude for reasoning and synthesis

4. **Cost Model**:
   - Premium tier: $0.019449 per item
   - 7-10 second latency
   - 88% gross margin at scale

---

## What Will Change in New Stage 2.1

The new Stage 2.1 execution will:

1. Follow verified-stage-development skill methodology
2. Use updated research → planning → execution → verification workflow
3. Potentially refine architecture based on latest best practices
4. Ensure all documents follow consistent format and structure
5. Re-evaluate technology choices with fresh perspective

---

## Reference

If you need to reference the original Stage 2.1 work, all documents are preserved in this archive directory with their original file structure:

```
docs/archive/stage-2-1/
├── adr/           # Architecture Decision Records (ADR-005 through ADR-017)
├── tech-stack/    # Tech stack documents (TECH-STACK-MAP-001, API-CONTRACTS-001, SCHEMA-001)
├── design/        # Design documents (DESIGN-004, DESIGN-005)
├── test/          # Test strategy (TEST-STRATEGY-001)
├── research/      # Research and reconciliation documents
├── checkpoints/   # Execution plans and verification checkpoints
└── README.md      # This file
```

---

## Important Notes

- **Barcode feature documents remain active**: ADR-018 and RESEARCH-BARCODE-API-2025-11-06 are NOT archived, as they were created AFTER Stage 2.1 completion
- **Phase 1 documents remain active**: ADR-001 through ADR-004 and all Stage 1.1/1.2 specs remain in their original locations
- **Stage 2.2+ documents remain active**: All Stage 2.2, 2.3, 2.4 documents are unaffected

---

**Archive Created By**: Claude (verified-stage-development preparation)
**Next Step**: Execute Stage 2.1 using verified-stage-development skill
