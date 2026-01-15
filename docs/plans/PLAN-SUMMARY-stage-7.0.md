# PLAN-SUMMARY: Stage 7.0 - Layer 2 Gemini 3 Pro Implementation

**Created**: 2026-01-14
**Stage**: 7.0 - Layer 2 Gemini 3 Pro Implementation
**Status**: Planning Complete
**Full Plan**: docs/plans/2026-01-14-stage-7.0-gemini-3-pro-implementation.md
**Research Validation**: docs/validation/RESEARCH-VALIDATION-stage-7.0.md

---

## What This Stage Accomplishes

Stage 7.0 replaces the existing 4-model AI pipeline with a single Gemini 3 Pro model using native tool calling. The new architecture:

- **Consolidates from 4 models to 1**: Eliminates Gemini Flash-Lite (Layer 2a), Claude Haiku (parsing), and Claude Sonnet (Layer 3 synthesis)
- **Enables native tool calling**: Gemini 3 Pro calls tools directly (google_lens, barcode_lookup, web_search) without separate parsing layers
- **Simplifies orchestration**: One Cloud Function trigger instead of three chained triggers
- **Maintains cost parity**: ~$0.033-0.043 per item vs ~$0.017-0.019 old architecture (2x cost for 4x simpler architecture)

---

## Key Decisions Made

### 1. Model Selection: Gemini 3 Pro Preview
- **Decision**: Use `gemini-3-pro-preview` model ID
- **Rationale**: Best reasoning capabilities, native tool calling, vision support
- **Trade-off**: Preview status means model ID may change at GA
- **ADR**: Updates ADR-014 (Cloud AI Provider Selection)

### 2. SDK Migration: @google/genai
- **Decision**: Use `GoogleGenAI` class from `@google/genai` SDK
- **Rationale**: Old `@google/generative-ai` package deprecated (support ended Aug 2025)
- **Impact**: Different API pattern (`ai.models.generateContent()` vs `model.generateContent()`)

### 3. Tool Strategy: Custom Function Declarations
- **Decision**: Use custom function declarations for all tools
- **Rationale**: Gemini 3 doesn't yet support combining built-in tools with custom function calling
- **Impact**: google_lens, barcode_lookup, web_search all implemented as custom tools

### 4. UPCitemdb Pricing Model
- **Decision**: Plan for monthly subscription ($99/mo Dev plan)
- **Rationale**: Per-lookup pricing model incorrect; actual pricing is subscription-based
- **Impact**: Cost model updated in COST-MODEL-001

---

## Outputs to Be Created

**New Files (18 total):**
- Schema: `functions/src/ai-pipeline/gemini/schemas/catalog-item.ts`
- Prompts: `functions/src/ai-pipeline/gemini/prompts.ts`
- Tools: `google-lens.ts`, `barcode-lookup.ts`, `web-search.ts`, `tool-executor.ts`
- Service: `functions/src/ai-pipeline/gemini/gemini-service.ts`
- Orchestrator: `functions/src/ai-pipeline/gemini/orchestrator.ts`
- Trigger: `functions/src/triggers/onItemCreatedGemini3.ts`
- Tests for all components

**Modified Files:**
- `functions/src/index.ts` - Add new trigger export
- `functions/package.json` - Update SDK version

---

## Next Stage Preview

**Stage 7.1**: iOS Client Integration
- Update iOS app to work with new `onItemCreatedGemini3` trigger
- Update Firestore listener for new `catalog` field structure
- UI updates for new CatalogItem schema (subCategory, dimensions, confidence)

---

## Technical Corrections from Research

| Original Claim | Correction | Source |
|----------------|------------|--------|
| Model ID: `gemini-3-pro` | `gemini-3-pro-preview` | ai.google.dev |
| SDK: `GoogleGenerativeAI` | `GoogleGenAI` | Migration guide |
| UPCitemdb: $0.005/lookup | $99/month subscription | upcitemdb.com |
| UPCitemdb response: `category` field | No category in response | API docs |
| SDK version: ^1.29.0 | ^1.35.0 (latest) | npm |

---

**This plan provides complete implementation details for replacing the 4-model AI pipeline with Gemini 3 Pro.**
