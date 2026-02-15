# ADR-027: Terminology Standardization

**Status:** Accepted
**Date:** 2026-02-08
**Deciders:** Product owner, development team

## Context

The Abundance MVP has accumulated inconsistent terminology across three layers:

1. **User-facing UI** — tab labels, button text, status messages
2. **Developer code** — module names, type names, variable names
3. **Documentation/specs** — architectural and product language

Key problems:

- **"Catalog" overload**: Used as both a noun (the user's collection) and a verb (AI processing an item). The Brand Bible says the tab is "Catalog" but the code module is `InventoryFeature`.
- **Re-processing confusion**: Three terms (`deep scan`, `super scan`, `re-catalog`) describe the same operation — re-running Layer 2 AI on existing images.
- **Pipeline leakage**: Internal terms like "Layer 1" and "Layer 2" appear in UI-adjacent code despite being invisible to users.
- **Tab naming mismatch**: Brand Bible specifies "Catalog / Scan / Profile" but code uses "Inventory / Camera / Profile".

## Decision

### 1. Establish Two Terminology Domains

**User Domain** — terms that appear in the UI, product copy, and user-facing documentation.
**Machine Domain** — terms used in pipeline code, backend specs, and architectural docs.

Machine Domain terms (Layer 1, Layer 2, EdgeTAM, etc.) MUST NOT appear in UI strings or user-facing copy. User Domain terms are preferred in code that directly backs UI (Views, ViewModels).

### 2. Canonical Term Choices

| Concept | User Term | Developer Term | Replaces |
|---------|-----------|---------------|----------|
| User's item collection | **Collection** | `CollectionFeature`, `CollectionView` | "Catalog" (noun), "Inventory" |
| Camera/capture tab | **Scan** | `ScanFeature`, `CaptureView` | "Camera" (tab label) |
| Taking photos | **Scan** (verb) | `CaptureMode`, `CaptureSession` | — |
| Single photo mode | **Photo** | `CaptureMode.single` | — |
| Multi-photo mode | **Burst** | `CaptureMode.burst` | — |
| EdgeTAM segmentation mode | **Sweep** | `CaptureMode.sweep`, `EdgeTAMFeature` | — |
| AI object detection | *(hidden)* | Layer 1 Detection, `DetectionService` | — |
| AI product identification | **Analyzing...** (status) | Layer 2 Cataloging, `CatalogService` | — |
| Re-run AI on existing images | **Refresh** | `refreshItem()` | "deep scan", "super scan", "re-catalog", "super catalog" |
| New photo + re-run AI | **Rescan** | `rescanItem()` | — |
| Individual item | **Item** | `Item` model | — |
| User account | **Profile** | `ProfileFeature`, `ProfileView` | — |
| AI processing status | **Analyzing...** | `ItemStatus.processing` | — |
| AI complete status | **Ready** | `ItemStatus.complete` | — |
| AI failed status | **Try Again** | `ItemStatus.failed` | — |

### 3. Code Alignment (Practical Renames)

Align module and type names to match user terms where practical:

| Current | New | Priority | Status |
|---------|-----|----------|--------|
| `InventoryFeature` | `CollectionFeature` | High — module rename | **DONE** (Sources/CollectionFeature/) |
| `InventoryView` | `CollectionView` | High — follows module | **DONE** |
| `InventoryViewModel` | `CollectionViewModel` | High — follows module | **DONE** |
| `requestDeepScan()` | `refreshItem()` | High — term change | **DONE** (code uses `refreshItem()`, Firestore field `deepScanRequested` preserved for backward compat) |
| `deepScanRequested` | `refreshRequested` | High — follows method | **DONE** (code property is `refreshRequested`, Firestore field name preserved as `deepScanRequested`) |
| `recatalogItem()` | `refreshItem()` | High — merge into single "refresh" action | **DONE** |
| Camera tab label "Camera" | "Scan" | Medium — string change | Pending |
| Catalog tab label "Catalog" | "Collection" | Medium — string change | Pending |

**Keep as-is** (Machine Domain, no user exposure):
- `CatalogService` — internal AI pipeline service
- `Layer1Metadata`, `layer1Label`, `layer1Confidence` — Firestore schema fields
- `EdgeTAMFeature`, `EdgeTAMService` — internal module
- `CaptureSession`, `CaptureSessionViewModel` — internal capture orchestration
- `CaptureMode` enum values — code-only, UI shows "Photo/Burst/Sweep" strings

### 4. Forbidden Terms

These terms MUST NOT be used in any new code, docs, or UI:

| Forbidden | Canonical Replacement |
|-----------|----------------------|
| "super scan" | **Refresh** |
| "super catalog" | **Refresh** |
| "deep scan" | **Refresh** |
| "re-catalog" (user-facing) | **Refresh** |
| "inventory" (user-facing) | **Collection** |
| "camera" (tab label) | **Scan** |

### 5. Documentation Format

- **Glossary** (`docs/GLOSSARY.md`) — quick-reference mapping matrix, referenced from CLAUDE.md
- **This ADR** — captures the rationale and decision history

## Consequences

### Positive
- Single source of truth for all terminology
- Users see consistent language throughout the app
- Developers have clear mapping when naming new code
- "Catalog" overload eliminated — Collection (noun) vs. Cataloging (internal verb)

### Negative
- ~~Module rename (`InventoryFeature` → `CollectionFeature`) requires updating imports across the codebase~~ **DONE** -- `Sources/CollectionFeature/` exists with all renamed types
- Existing documentation references need updating (some ADRs still reference old names)
- Firestore field names (`deepScanRequested`) diverge from code names (`refreshRequested`) -- code-level aliases are in place, migration deferred

### Risks
- Firestore schema fields cannot be renamed without migration — code-level aliases needed
- Brand Bible v3 references "Catalog" tab — needs update to "Collection"
