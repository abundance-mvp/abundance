# AI Pipeline Project Structure

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/plans/PLAN-SUMMARY-stage-3.4.md (Layer 2a)
- docs/plans/PLAN-SUMMARY-stage-3.5.md (Layer 2b)
- docs/plans/PLAN-SUMMARY-stage-3.6.md (Layer 3)
- docs/design/DESIGN-004-computer-vision-pipeline.md
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
**Status**: Draft

## Overview

This document defines the directory structure, module organization, and file naming conventions for the AI Pipeline Cloud Functions implementation. The structure supports the 4-layer computer vision pipeline architecture defined in DESIGN-004.

## Directory Structure

```
functions/
├── src/
│   ├── ai-pipeline/
│   │   ├── providers/
│   │   │   ├── vertexai/
│   │   │   │   ├── gemini-provider.ts         # Layer 2a: Attribute extraction
│   │   │   │   └── gemini-provider.test.ts
│   │   │   ├── anthropic/
│   │   │   │   ├── claude-haiku-provider.ts   # Layer 2b: Parsing
│   │   │   │   ├── claude-sonnet-provider.ts  # Layer 3: Synthesis
│   │   │   │   └── providers.test.ts
│   │   │   ├── serpapi/
│   │   │   │   ├── google-lens-provider.ts    # Layer 2b: Visual search
│   │   │   │   └── google-lens-provider.test.ts
│   │   │   └── barcode/
│   │   │       ├── openfoodfacts-provider.ts  # Layer 2b: Free barcode
│   │   │       ├── upcitemdb-provider.ts      # Layer 2b: Paid barcode
│   │   │       └── barcode-providers.test.ts
│   │   ├── orchestration/
│   │   │   ├── layer2a-orchestrator.ts        # Firestore trigger → Gemini
│   │   │   ├── layer2b-orchestrator.ts        # Layer 2a complete → SerpAPI/barcode
│   │   │   ├── layer3-orchestrator.ts         # Layer 2b complete → Claude synthesis
│   │   │   └── orchestrators.test.ts
│   │   ├── models/
│   │   │   ├── item-metadata.ts               # TypeScript interfaces
│   │   │   ├── provider-responses.ts
│   │   │   └── error-types.ts
│   │   ├── utils/
│   │   │   ├── cost-tracker.ts                # Log API costs to Firestore
│   │   │   ├── retry-logic.ts                 # Exponential backoff
│   │   │   └── error-handlers.ts
│   │   └── index.ts                           # Export all providers
│   └── index.ts                                # Main Cloud Functions export
├── package.json
├── tsconfig.json
└── .env.template
```

## Module Responsibilities

### Providers (`providers/`)

**Purpose**: Adapter interfaces for external AI APIs

**Pattern**: Each provider exports a class with standardized methods:
- `initialize()`: Set up API client with credentials
- `process()`: Main processing method (varies by layer)
- `handleError()`: Standardized error handling
- `trackCost()`: Log API usage costs

**Provider Responsibilities**:
- **GeminiProvider** (Layer 2a): Extract 10-15 visual attributes from photos
- **ClaudeHaikuProvider** (Layer 2b): Parse unstructured text into structured JSON
- **ClaudeSonnetProvider** (Layer 3): Synthesize multi-source data into final metadata
- **GoogleLensProvider** (Layer 2b): Visual search for product identification
- **OpenFoodFactsProvider** (Layer 2b): Free barcode lookup (no API key required)
- **UPCitemdbProvider** (Layer 2b): Paid barcode lookup (100 calls/day free, then $0.002/call)

**Testing**: Mock external APIs using Jest, no real API calls in unit tests

### Orchestration (`orchestration/`)

**Purpose**: Firestore-triggered Cloud Functions for each layer

**Pattern**: Event-driven, async processing
- Each orchestrator listens for Firestore document writes
- Triggers when previous layer completes (detected by field updates)
- Calls appropriate provider(s)
- Updates Firestore document with results
- Handles errors with retry logic and dead letter queue

**Orchestrator Flow**:
- **Layer 2a**: Firestore onCreate trigger → GeminiProvider → Update `/items/{itemId}`
- **Layer 2b**: Firestore onUpdate trigger (Layer 2a complete) → SerpAPI/Barcode → Update `/items/{itemId}`
- **Layer 3**: Firestore onUpdate trigger (Layer 2b complete) → ClaudeSonnetProvider → Update `/items/{itemId}`

**Testing**: Firebase Emulator Suite with mock Firestore triggers

### Models (`models/`)

**Purpose**: TypeScript type definitions for all data structures

**Pattern**: Interfaces and types for:
- Item metadata schemas (Firestore documents)
- Provider request/response types
- Error types and status codes
- Cost tracking records

**Testing**: Type checking via `tsc --noEmit`, no runtime tests needed

### Utils (`utils/`)

**Purpose**: Shared utilities for cost tracking, retry logic, and error handling

**Pattern**: Pure functions with no side effects
- **cost-tracker.ts**: Log API costs to `/costs/{costId}` in Firestore
- **retry-logic.ts**: Exponential backoff with configurable max retries
- **error-handlers.ts**: Classify errors (retryable vs. permanent) and route to dead letter queue

**Testing**: Unit tests with 100% coverage

## File Naming Conventions

- **Providers**: `{service}-provider.ts` (e.g., `gemini-provider.ts`)
- **Orchestrators**: `layer{N}-orchestrator.ts` (e.g., `layer2a-orchestrator.ts`)
- **Tests**: `{module}.test.ts` (co-located with source)
- **Models**: `{domain}.ts` (e.g., `item-metadata.ts`)
- **Utils**: `{purpose}.ts` (e.g., `cost-tracker.ts`)

## Import Paths

All imports use relative paths from `functions/src/`:

```typescript
// Provider imports
import { GeminiProvider } from './ai-pipeline/providers/vertexai/gemini-provider';
import { ClaudeHaikuProvider } from './ai-pipeline/providers/anthropic/claude-haiku-provider';
import { GoogleLensProvider } from './ai-pipeline/providers/serpapi/google-lens-provider';

// Model imports
import { ItemMetadata } from './ai-pipeline/models/item-metadata';
import { ProviderResponse } from './ai-pipeline/models/provider-responses';

// Util imports
import { trackCost } from './ai-pipeline/utils/cost-tracker';
import { retryWithBackoff } from './ai-pipeline/utils/retry-logic';
import { handleProviderError } from './ai-pipeline/utils/error-handlers';
```

## Code Organization Principles

1. **Single Responsibility**: Each provider handles exactly one external API
2. **Dependency Injection**: Pass Firebase Admin SDK and API clients as constructor parameters
3. **Testability**: All external dependencies can be mocked
4. **Type Safety**: Strict TypeScript mode enabled, no `any` types
5. **Error Boundaries**: Each layer has independent error handling, failures don't cascade
6. **Cost Visibility**: Every API call is logged to Firestore with timestamp, tokens, and cost

## Deployment Structure

Functions are deployed independently to allow granular scaling:

```yaml
# firebase.json
"functions": [
  {
    "source": "functions",
    "codebase": "default",
    "runtime": "nodejs20",
    "ignore": ["node_modules", ".git", "*.test.ts"]
  }
]
```

Each orchestrator becomes a separate Cloud Function:
- `layer2aOrchestrator`: 1st gen function with Firestore onCreate trigger
- `layer2bOrchestrator`: 1st gen function with Firestore onUpdate trigger
- `layer3Orchestrator`: 1st gen function with Firestore onUpdate trigger

## Acceptance Criteria

- ✅ Directory structure documented with rationale
- ✅ Module responsibilities clearly defined
- ✅ File naming conventions specified
- ✅ Import paths documented with examples
- ✅ Aligns with Stages 3.4-3.6 code examples
- ✅ Supports independent deployment and scaling
- ✅ References current @google/genai SDK (not deprecated @google-cloud/vertexai)

## Next Steps

1. Implement `package.json` with verified dependencies (Task 2)
2. Define TypeScript provider interfaces (Task 3)
3. Configure TypeScript compiler settings (Task 4)
4. Set up environment variables (Task 5)

---

**Last Updated**: 2025-11-11
