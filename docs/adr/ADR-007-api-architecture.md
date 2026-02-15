# ADR-007: API Architecture

**Status**: Approved (Revised 2026-02-08 to reflect Gemini 3 Pro pipeline)
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, Backend Developer, iOS Developer
**Related Documents**:
- docs/adr/ADR-002-platform-strategy.md (GCP/Firebase platform)
- docs/specs/SPEC-ARCH-002-layer1-layer2-pipeline.md (AI pipeline architecture)
- docs/specs/SPEC-API-001-cloud-functions.md (Cloud Functions specification)

---

## Context

Abundance needs an API layer for:
- **iOS app to Backend communication**: Item CRUD operations, AI pipeline triggers
- **AI pipeline orchestration**: Gemini 3 Pro with tool calling (Google Lens, barcode lookup, web search)
- **Session-based capture**: Multi-image detection pipeline using Gemini 3 Flash
- **Future PWA support**: Phase 2 web app uses same API as iOS app

**Requirements**:
- Simple iOS integration (Firebase SDK callable functions + HTTP endpoints)
- Serverless (auto-scale, pay-per-use, no server management)
- GCP platform (ADR-002): Native Firebase/GCP integration
- Cost-efficient (low invocation cost for free tier users)

---

## Decision

**Use Cloud Functions (2nd gen) with a mix of HTTP endpoints, Firebase callable functions, and Firestore triggers for all backend compute.**

### Specifications

- **Architecture**: HTTP endpoints for item CRUD, Firestore triggers for AI pipeline orchestration
- **Compute**: Cloud Functions 2nd gen (Node.js 20 runtime, TypeScript)
- **AI Pipeline**: Gemini 3 Pro (`gemini-3-pro-preview`) with tool calling via Vertex AI
- **Layer 1 Detection**: Gemini 3 Flash (`gemini-3-flash-preview`) for object detection and cropping
- **Authentication**: Firebase ID tokens (Bearer token in `Authorization` header for HTTP; `context.auth` for callables)
- **Response Format**: JSON (Content-Type: `application/json`)
- **SDK**: `@google/genai` for Vertex AI (Application Default Credentials, no API keys)

---

## Rationale

### 1. Unified Gemini Pipeline (Replaced Multi-Layer Claude/SerpAPI Architecture)

**Previous Design**: 4-layer pipeline with separate AI services per layer (Vertex AI Gemini for attributes, SerpAPI + Claude Haiku for product identification, Claude Sonnet for synthesis).

**Current Design**: Unified Gemini 3 Pro pipeline with tool calling. A single Gemini 3 Pro call handles the entire cataloging workflow, invoking tools as needed:

| Tool | Purpose | Implementation |
|------|---------|----------------|
| `google_lens_search` | Visual product matching via SerpAPI Google Lens | `functions/src/ai-pipeline/tools/google-lens.ts` |
| `barcode_lookup` | UPC/EAN barcode product lookup | `functions/src/ai-pipeline/tools/barcode-lookup.ts` |
| `web_search` | E-commerce pricing search via SerpAPI | `functions/src/ai-pipeline/tools/web-search.ts` |

**How it works**:
1. Image uploaded by iOS app to Firebase Storage
2. Firestore trigger (`onItemCreatedGemini3`) fires on item creation
3. Image fetched and sent to Gemini 3 Pro with tool declarations
4. Gemini decides which tools to call (barcode, Google Lens, web search)
5. Tool results returned to Gemini for synthesis
6. Final catalog JSON written to Firestore item document

**Benefits**:
- **Single model**: One Gemini 3 Pro call replaces 3 separate AI services
- **Tool calling**: Model autonomously decides which tools to invoke based on image content
- **Thought signatures**: Gemini 3 requires thought_signature preservation for multi-turn tool calls
- **Session persistence**: Catalog history enables context continuity across rescans

### 2. Two-Tier AI Model Strategy

**Layer 1 (Detection)**: Gemini 3 Flash (`gemini-3-flash-preview`)
- Object detection with bounding boxes in images
- Server-side cropping with sharp
- Runs in `onSessionCreated` trigger
- Optimized for speed with `thinking_level: low`

**Layer 2 (Cataloging)**: Gemini 3 Pro (`gemini-3-pro-preview`)
- Full product cataloging with tool calling
- Runs in `onItemCreatedGemini3` and `onItemFromSession` triggers
- Returns structured CatalogItem JSON with confidence scoring
- Supports context caching for cost optimization

### 3. Cloud Functions Auto-Scale (Serverless)

Cloud Functions (2nd gen) auto-scale from 0 to 1,000+ concurrent instances. All functions use `us-central1` region with configurable memory and timeout per function.

### 4. GCP Integration (Cloud Functions Native to Firebase)

**Integration Points**:
- **Vertex AI**: Gemini 3 models via `@google/genai` SDK with Application Default Credentials
- **Firebase Auth**: `context.auth` for callable functions, Bearer token verification for HTTP
- **Firestore**: Direct access via `firebase-admin` SDK
- **Cloud Storage**: Image fetch via Admin SDK (bypasses security rules)
- **Secret Manager**: `SERPAPI_KEY` stored as Cloud Functions secret

---

## Alternatives Considered

### Alternative 1: GraphQL (Apollo Server)

**Why Rejected**: GraphQL overkill for simple catalog CRUD. REST/callable API simpler for iOS integration with Firebase SDK.

### Alternative 2: Multi-Model Pipeline (Claude + Gemini + SerpAPI)

**Previous approach**: Separate AI services per pipeline layer.

**Why Replaced**: Gemini 3 Pro tool calling unifies all AI operations into a single model call. Reduces latency, simplifies orchestration, and eliminates Claude/Anthropic dependency.

### Alternative 3: API Key Authentication for Gemini

**Why Rejected**: Gemini 3 Preview models require Vertex AI (not API keys). Application Default Credentials provide automatic authentication in Cloud Functions.

---

## Implications & Consequences

### Positive

1. **Unified AI Pipeline**: Single Gemini 3 Pro model with tool calling replaces multi-service orchestration
2. **Serverless Auto-Scale**: Cloud Functions scale 0 to 1,000+ instances automatically
3. **GCP-Native Auth**: Vertex AI uses Application Default Credentials (no API key management)
4. **Cost Efficient**: Context caching reduces Gemini token costs for repeat scans
5. **Simple iOS Integration**: Firebase SDK for callables, standard HTTP for REST endpoints

### Negative

1. **Gemini 3 Preview Dependency**: Using preview model (`gemini-3-pro-preview`), will need migration when GA
   - **Mitigation**: Model ID centralized in `prompts.ts`, single-line change
2. **Tool calling latency**: Multi-turn tool calling loop adds latency (up to 10 iterations)
   - **Mitigation**: Max iteration cap prevents infinite loops; typical items complete in 2-3 iterations
3. **SerpAPI Dependency**: Google Lens and web search require SerpAPI key
   - **Mitigation**: Graceful degradation if tools fail; Gemini falls back to visual analysis

---

## Implementation Details

### Cloud Functions Project Structure

```
functions/
├── src/
│   ├── index.ts                          // All function exports
│   ├── ai-pipeline/
│   │   ├── gemini/
│   │   │   ├── gemini-service.ts         // Gemini 3 Pro tool-calling loop
│   │   │   ├── orchestrator.ts           // Firestore trigger handler
│   │   │   ├── prompts.ts               // System prompt, tool declarations, model config
│   │   │   ├── vertexai-config.ts        // Vertex AI client setup (ADC)
│   │   │   ├── context-cache-service.ts  // Context caching for cost optimization
│   │   │   ├── catalog-history-service.ts // Session persistence
│   │   │   └── schemas/
│   │   │       ├── catalog-item.ts       // CatalogItem JSON schema
│   │   │       └── catalog-history.ts    // History record schema
│   │   ├── layer1/
│   │   │   ├── layer1-service.ts         // Gemini 3 Flash object detection
│   │   │   ├── prompts.ts               // Detection prompts and config
│   │   │   ├── schemas/
│   │   │   │   └── detection-result.ts   // Detection response schema
│   │   │   └── utils/
│   │   │       └── bbox-converter.ts     // Bounding box utilities
│   │   ├── tools/
│   │   │   ├── tool-executor.ts          // Central dispatch for tool calls
│   │   │   ├── google-lens.ts            // SerpAPI Google Lens integration
│   │   │   ├── barcode-lookup.ts         // Barcode product lookup
│   │   │   └── web-search.ts             // SerpAPI web search for pricing
│   │   ├── providers/
│   │   │   └── GeminiProvider.ts         // Provider abstraction
│   │   └── cost-tracking/
│   │       └── CostLogger.ts            // AI cost logging
│   ├── items/
│   │   ├── createItem.ts                 // Item creation logic
│   │   ├── getItem.ts                    // Item retrieval logic
│   │   └── listItems.ts                  // Item listing logic
│   ├── triggers/
│   │   ├── onItemCreatedGemini3.ts       // New item -> Gemini 3 Pro cataloging
│   │   ├── onItemFromSession.ts          // Session item -> Gemini 3 Pro cataloging
│   │   ├── onSessionCreated.ts           // Session -> Gemini 3 Flash detection
│   │   ├── onItemUpdatedDeepScan.ts      // Deep scan -> Gemini 3 Pro enhanced
│   │   ├── onItemUpdatedRescan.ts        // Rescan -> Gemini 3 Pro re-cataloging
│   │   └── onItemDeleted.ts              // Item deletion -> Storage cleanup
│   ├── scheduled/
│   │   ├── cleanupDeletedItems.ts        // Scheduled cleanup job
│   │   └── checkSubscriptionExpiry.ts    // Subscription expiry check
│   └── migrations/
│       └── backfillFlattenedSchema.ts    // Schema migration
├── package.json
└── tsconfig.json
```

### Dependencies

```json
{
  "@google/genai": "^1.35.0",
  "firebase-admin": "^12.0.0",
  "firebase-functions": "^7.0.3",
  "node-fetch": "^3.3.2",
  "sharp": "^0.33.0"
}
```

Note: No Claude/Anthropic SDK dependency. All AI operations use `@google/genai` for Vertex AI.

### Deployment

```bash
cd functions
npm install
firebase deploy --only functions
```

---

### Exported Functions (from index.ts)

| Function | Type | Purpose |
|----------|------|---------|
| `health` | HTTP (onRequest) | Health check endpoint (no auth) |
| `getUserProfile` | Callable (onCall) | Get authenticated user profile |
| `createItemHTTP` | HTTP (onRequest) | Create item with image URL and layer 1 result |
| `getItemHTTP` | HTTP (onRequest) | Get item by ID |
| `listItemsHTTP` | HTTP (onRequest) | List items for authenticated user |
| `onItemCreatedGemini3` | Firestore trigger (onCreate) | Process new items with Gemini 3 Pro |
| `onItemFromSession` | Firestore trigger (onCreate) | Process session-detected items with Gemini 3 Pro |
| `onSessionCreated` | Firestore trigger (onUpdate) | Run Gemini 3 Flash detection on sessions |
| `onItemUpdatedDeepScan` | Firestore trigger (onUpdate) | Enhanced deep scan with Gemini 3 Pro |
| `onItemUpdatedRescan` | Firestore trigger (onUpdate) | Re-catalog item through standard pipeline |
| `onItemDeleted` | Firestore trigger (onDelete) | Clean up Cloud Storage files |
| `cleanupDeletedItemsScheduled` | Scheduled | Periodic cleanup of soft-deleted items |
| `checkSubscriptionExpiryScheduled` | Scheduled | Check and expire lapsed subscriptions |
| `backfillFlattenedSchema` | HTTP (migration) | One-time schema migration |

---

### Error Handling

Cloud Functions use Firebase `HttpsError` for callable functions and standard HTTP status codes for HTTP endpoints:

```typescript
// Callable function errors
throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
throw new functions.https.HttpsError('not-found', 'Item not found');

// HTTP endpoint errors
res.status(401).json({ error: { code: 'unauthenticated', message: 'User must be signed in' } });
res.status(404).json({ error: { code: 'not-found', message: 'Item not found' } });
```

**HTTP Status Codes**:
- `200 OK`: Success
- `201 Created`: Item created
- `400 Bad Request`: Invalid input
- `401 Unauthorized`: Missing or invalid Firebase token
- `404 Not Found`: Item not found
- `500 Internal Server Error`: Server error (logged to Cloud Logging)

---

## Acceptance Criteria

- [x] Gemini 3 Pro pipeline operational with tool calling (google_lens, barcode_lookup, web_search)
- [x] Gemini 3 Flash detection pipeline for session-based capture
- [x] Cloud Functions (2nd gen) deployed to GCP with Vertex AI ADC
- [x] Firebase Auth token validation on all endpoints
- [x] Firestore triggers orchestrate AI pipeline automatically
- [x] Context caching and session persistence implemented

---

## Related Decisions

- **ADR-002**: Platform strategy (GCP) -> Cloud Functions native GCP service
- **ADR-005**: Authentication (Firebase Auth) -> API validates Firebase ID tokens
- **ADR-006**: Database (Firestore) -> API writes results to Firestore
- **ADR-020**: Cloud Functions organization -> Function categories and trigger strategy

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, REST API with Cloud Functions | Software Architecture Expert |
| 2026-02-08 | 2.0 | Major revision: Updated to reflect Gemini 3 Pro pipeline with tool calling, replaced Claude/SerpAPI multi-layer references, updated project structure from JS to TypeScript, updated function inventory to match actual exports | Documentation Agent |

---

**This API architecture uses Gemini 3 Pro with tool calling for unified AI cataloging, Gemini 3 Flash for object detection, and Cloud Functions 2nd gen for serverless auto-scaling compute.**
