# Catalog Pipeline Documentation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create comprehensive visual documentation of the Abundance catalog pipeline with rendered Mermaid diagrams (PNG) covering every stage from photo capture to inventory display.

**Architecture:** Documentation-only task. Uses the `mcp-mermaid` MCP server to render Mermaid syntax into PNG images stored in `docs/architecture/diagrams/`. A single master document (`docs/architecture/catalog-pipeline.md`) ties everything together with inline diagram references, exact prompts, schemas, and data flow descriptions.

**Tech Stack:** Mermaid (via mcp-mermaid MCP server), Markdown, PNG output

---

## Prerequisites

- mcp-mermaid MCP server is configured in `.claude.json` (already done)
- Claude session restarted to pick up MCP server
- Load the mermaid tool via `ToolSearch` query `"mermaid"` before first use

## File Layout

```
docs/architecture/
  catalog-pipeline.md              ← Master document
  diagrams/
    01-system-overview.png         ← High-level system architecture
    02-capture-upload-flow.png     ← Camera → GCS → Firestore
    03-layer1-detection.png        ← Gemini Flash object detection
    04-layer1-cropping.png         ← Server-side crop + storage
    05-catalog-button-flow.png     ← User catalogs → item creation
    06-layer2-tool-calling.png     ← Gemini Pro tool calling loop
    07-rescan-flow.png             ← Re-catalog button flow
    08-deep-scan-flow.png          ← Deep scan button flow
    09-firestore-schema.png        ← Entity relationship diagram
    10-storage-paths.png           ← GCS bucket/path diagram
    11-status-state-machine.png    ← Item + Session status transitions
    12-cost-breakdown.png          ← Per-item cost flow
```

---

### Task 1: Create Directory Structure

**Files:**
- Create: `docs/architecture/` directory
- Create: `docs/architecture/diagrams/` directory

**Step 1: Create directories**

```bash
mkdir -p docs/architecture/diagrams
```

**Step 2: Verify**

```bash
ls -la docs/architecture/diagrams/
```
Expected: empty directory exists

**Step 3: Commit**

```bash
git add docs/architecture/
git commit -m "docs: scaffold architecture documentation directories"
```

---

### Task 2: Load MCP Tool & Render Diagram 01 — System Overview

**Step 1: Load the mermaid MCP tool**

Use `ToolSearch` with query `"mermaid"` to discover and load the rendering tool.

**Step 2: Render the system overview diagram**

Use the mermaid MCP tool to render this diagram to `docs/architecture/diagrams/01-system-overview.png`:

```mermaid
graph TB
    subgraph "iOS App"
        CAM[Camera Capture]
        DET[Detection Results View]
        INV[Inventory Grid]
        DETAIL[Item Detail View]
    end

    subgraph "Firebase"
        FS_SESS[(sessions collection)]
        FS_ITEMS[(items collection)]
        FS_HIST[(catalogHistory subcollection)]
        GCS_TEMP[GCS Temp Bucket<br/>24h auto-delete]
        GCS_PERM[GCS Permanent Bucket<br/>Cropped objects]
    end

    subgraph "Cloud Functions"
        CF_SESS[onSessionCreated<br/>Layer 1 Trigger]
        CF_ITEM[onItemFromSession<br/>Layer 2a Trigger]
        CF_RESCAN[onItemUpdatedRescan<br/>Re-catalog Trigger]
        CF_DEEP[onItemUpdatedDeepScan<br/>Deep Scan Trigger]
        CF_DEL[onItemDeleted<br/>Storage Cleanup]
    end

    subgraph "AI Models"
        FLASH[Gemini 3 Flash Preview<br/>Object Detection]
        PRO[Gemini 3 Pro Preview<br/>Product Cataloging]
    end

    subgraph "External APIs"
        SERP[SerpAPI<br/>Google Lens Search]
        UPC[UPCitemdb<br/>Barcode Lookup]
        GSEARCH[Google Search<br/>Grounding for Pricing]
    end

    CAM -->|Upload JPEG 80%| GCS_TEMP
    CAM -->|Create session doc| FS_SESS
    FS_SESS -->|onDocumentUpdated| CF_SESS
    CF_SESS -->|Fetch images| GCS_TEMP
    CF_SESS -->|base64 images + prompt| FLASH
    FLASH -->|bounding boxes JSON| CF_SESS
    CF_SESS -->|Crop with Sharp| GCS_PERM
    CF_SESS -->|Update detectedObjects| FS_SESS
    FS_SESS -->|Realtime listener| DET

    DET -->|Catalog button → create item| FS_ITEMS
    FS_ITEMS -->|onDocumentCreated| CF_ITEM
    CF_ITEM -->|cropped image + prompt| PRO
    PRO -->|functionCall| SERP
    PRO -->|functionCall| UPC
    PRO -->|functionCall| GSEARCH
    CF_ITEM -->|Update catalog fields| FS_ITEMS
    CF_ITEM -->|Save history| FS_HIST
    FS_ITEMS -->|Realtime listener| INV
    INV --> DETAIL

    DETAIL -->|Re-catalog| CF_RESCAN
    DETAIL -->|Deep Scan| CF_DEEP
    CF_RESCAN -->|Same pipeline| PRO
    CF_DEEP -->|Extended pipeline| PRO
```

**Step 3: Verify the PNG was created**

```bash
ls -la docs/architecture/diagrams/01-system-overview.png
```

---

### Task 3: Render Diagram 02 — Capture & Upload Flow

**Step 1: Render to `docs/architecture/diagrams/02-capture-upload-flow.png`**

```mermaid
sequenceDiagram
    participant User
    participant CaptureVM as CaptureSession<br/>ViewModel
    participant Storage as StorageService
    participant Session as SessionService
    participant GCS as GCS Temp Bucket
    participant Firestore as Firestore<br/>sessions/

    User->>CaptureVM: Double-tap (single)<br/>or Long-press (burst)
    activate CaptureVM
    CaptureVM->>CaptureVM: uiState = .capturing(count)
    CaptureVM->>CaptureVM: Haptic feedback

    Note over CaptureVM: Burst: 0.5s intervals<br/>Max 8 photos, 4s timeout

    CaptureVM->>Session: createSession(userId, mode, count)
    Session->>Firestore: sessions/{id} = {<br/>  status: "uploading",<br/>  expectedImageCount: N<br/>}

    CaptureVM->>CaptureVM: observeSession(id)<br/>Start realtime listener

    loop For each captured photo
        CaptureVM->>Storage: uploadCroppedObject(jpeg80%)
        Storage->>GCS: PUT users/{uid}/items/{sid}_{idx}.jpg<br/>metadata: contentType, uploadedAt
        Storage-->>CaptureVM: downloadURL
        CaptureVM->>Session: addUploadedImage(url)
        Session->>Firestore: originalImageUrls.append(url)<br/>imagesUploaded++
        CaptureVM->>CaptureVM: uiState = .uploading(progress)
    end

    CaptureVM->>Session: markReadyForDetection(id)
    Session->>Firestore: status = "detecting"
    CaptureVM->>CaptureVM: uiState = .analyzing

    Note over Firestore: Triggers onSessionCreated<br/>Cloud Function

    deactivate CaptureVM
```

---

### Task 4: Render Diagram 03 — Layer 1 Detection

**Step 1: Render to `docs/architecture/diagrams/03-layer1-detection.png`**

```mermaid
sequenceDiagram
    participant FS as Firestore Trigger
    participant CF as onSessionCreated<br/>1GiB / 120s
    participant GCS as GCS Temp Bucket
    participant Flash as Gemini 3 Flash<br/>Preview
    participant PERM as GCS Permanent<br/>Bucket

    FS->>CF: sessions/{id} updated<br/>status: detecting
    activate CF

    CF->>CF: Transaction: claim session<br/>(prevent duplicates)
    CF->>CF: Validate userId, URLs,<br/>bucket whitelist

    CF->>GCS: Fetch images → base64
    GCS-->>CF: image buffers

    CF->>CF: EXIF normalize with Sharp<br/>(rotation fix, JPEG 95%)

    CF->>Flash: generateContent({<br/>  model: gemini-3-flash-preview,<br/>  systemInstruction: DETECTION_PROMPT,<br/>  config: { temp:0, topP:0.95,<br/>    maxTokens:4096, thinkingLevel:LOW }<br/>  contents: [base64 images]<br/>})

    Flash-->>CF: JSON response:<br/>{objects: [{groupId, label,<br/>category, box_2d, confidence}]}

    Note over CF: box_2d format:<br/>[ymin, xmin, ymax, xmax]<br/>normalized 0-1000

    loop For each detected object
        CF->>CF: Convert box 0-1000 → pixels<br/>Add 5% padding, clamp bounds
        CF->>CF: Sharp.extract({left,top,w,h})<br/>.jpeg({quality: 85})
        CF->>PERM: Upload crop:<br/>users/{uid}/sessions/{sid}/<br/>crops/{groupId}_crop_{N}.jpg
        PERM-->>CF: Firebase download URL
    end

    CF->>FS: Update session:<br/>status: "detected"<br/>detectedObjects: [...]<br/>detectedAt: timestamp
    deactivate CF

    Note over FS: iOS app receives update<br/>via realtime listener
```

---

### Task 5: Render Diagram 04 — Layer 1 Cropping Detail

**Step 1: Render to `docs/architecture/diagrams/04-layer1-cropping.png`**

```mermaid
flowchart LR
    subgraph "Gemini Response"
        BOX["box_2d: [100, 200, 600, 800]<br/>(ymin, xmin, ymax, xmax)<br/>0-1000 scale"]
    end

    subgraph "Coordinate Conversion"
        CONV["xmin=200 → x1 = (200/1000)*W<br/>ymin=100 → y1 = (100/1000)*H<br/>xmax=800 → x2 = (800/1000)*W<br/>ymax=600 → y2 = (600/1000)*H"]
    end

    subgraph "Padding (5%)"
        PAD["padX = width * 0.05<br/>padY = height * 0.05<br/>Clamp to image bounds"]
    end

    subgraph "Sharp Crop"
        CROP["sharp(buffer)<br/>.extract({left, top, w, h})<br/>.jpeg({quality: 85})<br/>.toBuffer()"]
    end

    subgraph "Upload"
        UP["users/{uid}/sessions/{sid}/<br/>crops/{groupId}_crop_{N}.jpg<br/>→ Firebase download URL"]
    end

    BOX --> CONV --> PAD --> CROP --> UP
```

---

### Task 6: Render Diagram 05 — Catalog Button Flow

**Step 1: Render to `docs/architecture/diagrams/05-catalog-button-flow.png`**

```mermaid
sequenceDiagram
    participant User
    participant DetView as DetectionResults<br/>View
    participant CaptureVM as CaptureSession<br/>ViewModel
    participant CatSvc as CatalogService
    participant FS as Firestore<br/>items/

    User->>DetView: Tap "Catalog" button<br/>(selected objects)
    DetView->>CaptureVM: catalogSelectedObjects(ids)

    loop For each selected groupId
        CaptureVM->>CaptureVM: Guard: idempotency check<br/>submittedCatalogRequests
        CaptureVM->>CaptureVM: catalogingObjectIds.insert(groupId)
        CaptureVM->>CatSvc: catalogDetectedObject(<br/>userId, sessionId, object)

        CatSvc->>FS: items/{newId} = {<br/>  userId, sessionId, groupId,<br/>  fromDetection: true,<br/>  imageUrl: croppedImageUrls[0],<br/>  additionalImageUrls: [...rest],<br/>  imagePath: extracted GCS path,<br/>  layer1Label, layer1Category,<br/>  layer1Confidence, layer1Attributes,<br/>  status: "pending",<br/>  createdAt, updatedAt<br/>}

        Note over FS: status: "pending" +<br/>fromDetection: true<br/>→ triggers onItemFromSession

        CatSvc-->>CaptureVM: itemId

        CaptureVM->>CatSvc: observeItem(itemId)
        Note over CaptureVM: Realtime listener on<br/>items/{itemId}

        CatSvc-->>CaptureVM: status updates
        alt status == "complete"
            CaptureVM->>CaptureVM: catalogingObjectIds.remove<br/>catalogedObjectIds.insert
            CaptureVM->>DetView: Green checkmark
        else status == "failed"
            CaptureVM->>CaptureVM: catalogingObjectIds.remove
            CaptureVM->>DetView: Error indicator
        end
    end
```

---

### Task 7: Render Diagram 06 — Layer 2 Tool Calling Loop

**Step 1: Render to `docs/architecture/diagrams/06-layer2-tool-calling.png`**

```mermaid
sequenceDiagram
    participant FS as Firestore Trigger
    participant CF as onItemFromSession<br/>512MiB / 120s
    participant Cache as Context Cache<br/>1hr TTL
    participant Pro as Gemini 3 Pro<br/>Preview
    participant Lens as SerpAPI<br/>Google Lens
    participant UPC as UPCitemdb<br/>Barcode
    participant Web as Google Search<br/>Grounding

    FS->>CF: items/{id} created<br/>fromDetection:true, status:pending
    activate CF

    CF->>CF: Generate signed URL for image<br/>(15-min expiration)
    CF->>CF: Fetch image → base64

    CF->>Cache: Check context cache<br/>key: sha256(prompt+tools+schema)
    alt Cache hit
        Cache-->>CF: Cached system context<br/>(~90% token savings)
    else Cache miss
        CF->>Cache: Create cache entry<br/>TTL: 3600s
    end

    CF->>Pro: Initial request:<br/>system prompt + 3 tool defs +<br/>image (base64) + JSON schema

    loop Max 10 iterations
        Pro-->>CF: Response with functionCall(s)<br/>+ thought_signature (CRITICAL)

        Note over CF: MUST preserve<br/>thought_signature<br/>in conversation history

        par Execute tools in parallel
            opt google_lens_search called
                CF->>Lens: POST serpapi.com/search<br/>engine=google_lens&url={imageUrl}
                Lens-->>CF: {exact_matches, products[]}
            end
            opt barcode_lookup called
                CF->>UPC: GET upcitemdb.com<br/>/prod/trial/lookup?upc={code}
                UPC-->>CF: {found, product?}
            end
            opt web_search called
                CF->>Web: Gemini + googleSearch tool<br/>query: "{brand} {model} price"
                Web-->>CF: {prices: [{source, price}]}
            end
        end

        CF->>Pro: Append to conversation:<br/>model: [functionCall + thoughtSig]<br/>user: [functionResponse results]
    end

    Pro-->>CF: Final JSON (no more calls):<br/>{name, category, subCategory,<br/>brand, model, color, condition,<br/>dimensions, quantity,<br/>estimatedValue, confidence,<br/>processingNotes}

    CF->>CF: Validate against schema
    CF->>FS: Flatten to item doc:<br/>status: "complete" + all fields
    CF->>FS: Save catalogHistory entry
    deactivate CF
```

---

### Task 8: Render Diagram 07 — Re-catalog Flow

**Step 1: Render to `docs/architecture/diagrams/07-rescan-flow.png`**

```mermaid
sequenceDiagram
    participant User
    participant Detail as ItemDetailView
    participant InvVM as InventoryViewModel
    participant ItemSvc as ItemService
    participant FS as Firestore<br/>items/
    participant CF as onItemUpdated<br/>Rescan
    participant Pro as Gemini 3 Pro

    User->>Detail: Tap re-catalog button
    Detail->>Detail: Show confirmation dialog
    User->>Detail: Confirm

    Detail->>InvVM: recatalogItem(item)
    InvVM->>ItemSvc: rescanItem(item)

    ItemSvc->>FS: items/{id}.update({<br/>  status: "pending",<br/>  deepScanRequested: false,<br/>  lastRescanAt: serverTimestamp(),<br/>  updatedAt: serverTimestamp()<br/>})

    Note over FS: status changed TO "pending"<br/>→ triggers onItemUpdatedRescan<br/>(guard: before.status != pending)

    FS->>CF: Document updated
    activate CF

    CF->>CF: Fetch existing imageUrl<br/>(same cropped image)

    opt Catalog history exists
        CF->>FS: Read catalogHistory subcollection
        CF->>CF: Format history as context:<br/>"PREVIOUS CATALOG CONTEXT:<br/>Last identification: ...<br/>Tool results: ...<br/>User corrections: ..."
    end

    CF->>Pro: Image + prompt + history context
    Note over Pro: Same Layer 2 pipeline<br/>(tool calling loop)
    Pro-->>CF: Updated CatalogItem JSON

    CF->>FS: Update item with new fields<br/>status: "complete"
    CF->>FS: Append to catalogHistory
    deactivate CF

    FS-->>Detail: Realtime listener update
    Detail->>Detail: Refresh displayed fields
```

---

### Task 9: Render Diagram 08 — Deep Scan Flow

**Step 1: Render to `docs/architecture/diagrams/08-deep-scan-flow.png`**

```mermaid
sequenceDiagram
    participant User
    participant Detail as ItemDetailView
    participant InvVM as InventoryViewModel
    participant ItemSvc as ItemService
    participant FS as Firestore<br/>items/
    participant CF as onItemUpdated<br/>DeepScan<br/>1GiB / 180s
    participant Pro as Gemini 3 Pro

    User->>Detail: Tap sparkles button
    Detail->>Detail: Show confirmation dialog
    User->>Detail: Confirm

    Detail->>InvVM: requestDeepScan(item)
    InvVM->>ItemSvc: requestDeepScan(id)

    ItemSvc->>FS: items/{id}.update({<br/>  deepScanRequested: true,<br/>  status: "pending",<br/>  updatedAt: serverTimestamp()<br/>})

    Note over FS: deepScanRequested:true<br/>+ status:pending<br/>→ triggers onItemUpdatedDeepScan

    FS->>CF: Document updated
    activate CF

    CF->>Pro: Image + extended prompt<br/>+ ALL 3 tools forced

    Note over Pro: More aggressive tool use:<br/>Always calls Lens + Web Search<br/>Searches sold-price data

    Pro-->>CF: Extended CatalogItem:<br/>{...standard fields,<br/>productUrl, upcCode,<br/>marketPriceRange,<br/>originalRetailPrice}

    CF->>FS: Update item with extended fields:<br/>status: "complete"<br/>deepScanCompletedAt: timestamp<br/>productUrl, upcCode,<br/>marketPriceRange, originalRetailPrice

    deactivate CF

    FS-->>Detail: Realtime listener update
    Detail->>Detail: Show enriched fields
    Detail->>Detail: Disable sparkles button<br/>(one-time operation)
```

---

### Task 10: Render Diagram 09 — Firestore Schema ERD

**Step 1: Render to `docs/architecture/diagrams/09-firestore-schema.png`**

```mermaid
erDiagram
    USERS {
        string userId PK
        string email
        string displayName
        string subscriptionTier
        int catalogItemCount
        timestamp createdAt
    }

    SESSIONS {
        string id PK
        string userId FK
        string captureMode
        string status
        array originalImageUrls
        int imagesUploaded
        int expectedImageCount
        array detectedObjects
        string reasoning
        timestamp createdAt
        timestamp detectedAt
    }

    ITEMS {
        string id PK
        string userId FK
        string sessionId FK
        string groupId
        boolean fromDetection
        string imageUrl
        string imagePath
        array additionalImageUrls
        string status
        string name
        string category
        string subCategory
        string brand
        string model
        string color
        string condition
        int quantity
        float estimatedValue
        string confidence
        boolean deepScanRequested
        timestamp deepScanCompletedAt
        string productUrl
        string upcCode
        timestamp createdAt
        timestamp completedAt
    }

    CATALOG_HISTORY {
        string id PK
        string itemId FK
        timestamp catalogedAt
        string modelId
        array imageUrls
        array toolCalls
        object result
        object metadata
    }

    AI_COSTS {
        string id PK
        string itemId FK
        timestamp timestamp
        float gemini
        object tools
        float total
    }

    USERS ||--o{ SESSIONS : "creates"
    USERS ||--o{ ITEMS : "owns"
    SESSIONS ||--o{ ITEMS : "generates"
    ITEMS ||--o{ CATALOG_HISTORY : "has"
    ITEMS ||--o| AI_COSTS : "incurs"
```

---

### Task 11: Render Diagram 10 — Storage Paths

**Step 1: Render to `docs/architecture/diagrams/10-storage-paths.png`**

```mermaid
graph TB
    subgraph "Temp Bucket (24h auto-delete)"
        TEMP["gs://abundance-temp/"]
        TEMP_SESS["sessions/{sessionId}/"]
        TEMP_IMG["{imageIndex}.jpg<br/>Original full photos (3-5MB)"]
        TEMP --> TEMP_SESS --> TEMP_IMG
    end

    subgraph "Permanent Bucket"
        PERM["gs://abundance-mvp.firebasestorage.app/"]
        PERM_USER["users/{userId}/"]
        PERM_SESS["sessions/{sessionId}/crops/"]
        PERM_CROP["{groupId}_crop_{N}.jpg<br/>Cropped objects (<500KB)"]
        PERM_ITEMS["items/{itemId}/"]
        PERM_PHOTO["photo_{index}.jpg<br/>Additional photos"]
        PERM_MOTION["motion.mov<br/>Live Photo clips"]

        PERM --> PERM_USER
        PERM_USER --> PERM_SESS --> PERM_CROP
        PERM_USER --> PERM_ITEMS
        PERM_ITEMS --> PERM_PHOTO
        PERM_ITEMS --> PERM_MOTION
    end

    subgraph "Privacy Model"
        ORIG["Original Photo<br/>(room context, people)"]
        CROPPED["Cropped Object<br/>(object only)"]
        DELETE["DELETED after 24h"]

        ORIG -->|"Server-side crop"| CROPPED
        ORIG -->|"Lifecycle rule"| DELETE
    end

    style DELETE fill:#f66,stroke:#333
    style CROPPED fill:#6f6,stroke:#333
```

---

### Task 12: Render Diagram 11 — Status State Machines

**Step 1: Render to `docs/architecture/diagrams/11-status-state-machine.png`**

```mermaid
stateDiagram-v2
    state "Session Status" as sess {
        [*] --> uploading: createSession()
        uploading --> detecting: markReadyForDetection()
        detecting --> detected: Layer 1 success
        detecting --> failed: Layer 1 error
    }

    state "Item Status" as item {
        [*] --> pending: catalogDetectedObject()<br/>or rescanItem()
        pending --> complete: Layer 2 success
        pending --> failed: Layer 2 error
        pending --> failed_layer2a: Layer 2a error
        pending --> failed_layer2b: Layer 2b error
        complete --> pending: rescanItem()<br/>or requestDeepScan()
        failed --> pending: rescanItem() retry
    }
```

---

### Task 13: Render Diagram 12 — Cost Breakdown

**Step 1: Render to `docs/architecture/diagrams/12-cost-breakdown.png`**

```mermaid
graph LR
    subgraph "Layer 1 (~$0.002/image)"
        L1_IN["Gemini Flash input<br/>~$0.001 (image)"]
        L1_TXT["Flash input text<br/>~$0.0001"]
        L1_OUT["Flash output<br/>~$0.0004"]
    end

    subgraph "Layer 2a (~$0.04/item)"
        L2_PRO["Gemini Pro<br/>~$0.004"]
        L2_LENS["Google Lens<br/>SerpAPI $0.015"]
        L2_UPC["Barcode Lookup<br/>UPCitemdb $0.005"]
        L2_WEB["Web Search<br/>Grounding $0.014"]
    end

    subgraph "Context Cache Savings"
        CACHE["System prompt cached<br/>1hr TTL, ~90% reduction<br/>Rescan: $0.016 vs $0.04"]
    end

    subgraph "Total Per Item"
        TOTAL["First catalog: ~$0.042<br/>Re-catalog: ~$0.018<br/>Deep scan: ~$0.044"]
    end

    L1_IN --> TOTAL
    L1_TXT --> TOTAL
    L1_OUT --> TOTAL
    L2_PRO --> TOTAL
    L2_LENS --> TOTAL
    L2_UPC --> TOTAL
    L2_WEB --> TOTAL
    CACHE -.->|saves| TOTAL
```

---

### Task 14: Write Master Documentation

**Files:**
- Create: `docs/architecture/catalog-pipeline.md`

**Step 1: Write the complete documentation file**

This is the master document that combines all diagrams with detailed explanatory text. It must include:

1. **Executive Summary** — Two-layer AI pipeline overview
2. **System Architecture** — Reference `01-system-overview.png`, describe all components
3. **Photo Capture & Upload** — Reference `02-capture-upload-flow.png`
   - Double-tap vs burst capture mechanics
   - JPEG compression (80% quality)
   - Session creation payload (exact Firestore fields)
   - Upload to GCS temp bucket path format
   - Status transitions: uploading → detecting
4. **Layer 1: Object Detection** — Reference `03-layer1-detection.png`, `04-layer1-cropping.png`
   - Model: `gemini-3-flash-preview`
   - Config: temperature=0, topP=0.95, maxTokens=4096, thinkingLevel=LOW
   - **Full system prompt** (verbatim from `layer1/prompts.ts`)
   - Bounding box format: `[ymin, xmin, ymax, xmax]` 0-1000
   - Coordinate conversion formula
   - Sharp cropping: 5% padding, JPEG 85%
   - Firestore update payload (detectedObjects array schema)
   - Error codes and retry strategy (exponential backoff 1s/2s/4s, max 4 retries)
5. **Catalog Button Action** — Reference `05-catalog-button-flow.png`
   - Idempotency via `submittedCatalogRequests` set
   - Item document creation payload (exact fields)
   - `fromDetection: true` routing to `onItemFromSession`
   - Realtime listener on `items/{itemId}`
6. **Layer 2: Product Cataloging** — Reference `06-layer2-tool-calling.png`
   - Model: `gemini-3-pro-preview`
   - Config: temperature=0.1, topP=0.95, maxTokens=32768
   - **Full system prompt** (verbatim from `gemini/prompts.ts`)
   - Context caching: sha256 key, 1hr TTL, ~90% token savings
   - **Thought signature handling** (critical Gemini 3 requirement)
   - Tool definitions with request/response schemas:
     - `google_lens_search` → SerpAPI
     - `barcode_lookup` → UPCitemdb
     - `web_search` → Google Search grounding
   - Tool calling loop (max 10 iterations)
   - Confidence scoring rules
   - Condition-based pricing multipliers
   - Output schema: CatalogItem
   - Firestore flatten + write
   - Catalog history subcollection entry
7. **Re-catalog (Rescan)** — Reference `07-rescan-flow.png`
   - Trigger: `ItemService.rescanItem()` sets status="pending"
   - Cloud Function: `onItemUpdatedRescan`
   - Uses existing `imageUrl` (no new photo)
   - Injects catalog history as context prompt prefix
   - History format (verbatim `PREVIOUS CATALOG CONTEXT` block)
8. **Deep Scan** — Reference `08-deep-scan-flow.png`
   - Trigger: `ItemService.requestDeepScan()` sets deepScanRequested=true
   - Cloud Function: `onItemUpdatedDeepScan` (1GiB, 180s)
   - Extended schema fields: productUrl, upcCode, marketPriceRange, originalRetailPrice
   - One-time operation (button disabled after completion)
9. **Data Model** — Reference `09-firestore-schema.png`
   - Complete Item document schema with types
   - Session document schema
   - catalogHistory subcollection schema
   - aiCosts collection schema
10. **Storage Architecture** — Reference `10-storage-paths.png`
    - Temp vs permanent bucket roles
    - Exact path formats
    - Privacy model (originals deleted, crops retained)
    - Firebase Storage security rules
    - URL types: signed (24h) vs download (permanent with token)
11. **Status State Machine** — Reference `11-status-state-machine.png`
    - Session status transitions
    - Item status transitions
    - Cloud Function trigger conditions
12. **Cost Model** — Reference `12-cost-breakdown.png`
    - Per-component costs
    - Context cache savings (37% over 3 catalogs)
    - Total per-item estimate

**Step 2: Verify all diagram references resolve**

```bash
# Check all PNG files exist
for f in 01 02 03 04 05 06 07 08 09 10 11 12; do
  ls docs/architecture/diagrams/${f}-*.png
done
```

**Step 3: Commit**

```bash
git add docs/architecture/
git commit -m "docs: comprehensive catalog pipeline documentation with diagrams"
```

---

### Task 15: Verify & Cross-Reference

**Step 1: Check doc-index for registration**

```bash
# If doc-index requires registration:
./scripts/update_doc_index.py add docs/architecture/catalog-pipeline.md
```

**Step 2: Verify links resolve**

```bash
# Check for broken image references
rg '!\[' docs/architecture/catalog-pipeline.md
```

**Step 3: Final commit**

```bash
git add docs/
git commit -m "docs: register catalog pipeline doc in index"
```

---

## Appendix: Key Source Files Referenced

| Component | Source File |
|-----------|------------|
| Capture flow | `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift` |
| Detection results UI | `Sources/CameraFeature/Views/DetectionResultsView.swift` |
| Catalog service | `Sources/CameraFeature/Services/CatalogService.swift` |
| Session service | `Sources/CameraFeature/Services/SessionService.swift` |
| Storage service | `Sources/Persistence/Firebase/StorageService.swift` |
| Item service | `Sources/Persistence/Firebase/ItemService.swift` |
| Item model | `Sources/Persistence/Models/Item.swift` |
| Session model | `Sources/CameraFeature/Models/CaptureSession.swift` |
| Layer 1 prompts | `functions/src/layer1/prompts.ts` |
| Layer 2 prompts | `functions/src/gemini/prompts.ts` |
| Layer 1 service | `functions/src/layer1/layer1-service.ts` |
| Layer 2 orchestrator | `functions/src/gemini/orchestrator.ts` |
| Tool: Google Lens | `functions/src/gemini/tools/google-lens.ts` |
| Tool: Barcode | `functions/src/gemini/tools/barcode-lookup.ts` |
| Tool: Web Search | `functions/src/gemini/tools/web-search.ts` |
| Context cache | `functions/src/gemini/context-cache-service.ts` |
| Catalog history | `functions/src/gemini/catalog-history-service.ts` |
| Session trigger | `functions/src/onSessionCreated.ts` |
| Item trigger | `functions/src/onItemFromSession.ts` |
| Rescan trigger | `functions/src/onItemUpdatedRescan.ts` |
| Deep scan trigger | `functions/src/onItemUpdatedDeepScan.ts` |
| Vertex AI config | `functions/src/vertexai-config.ts` |

## Appendix: Exact Prompts (Verbatim)

### Layer 1 Detection System Prompt

```
You are an object detection system for a home inventory app.

TASK: Analyze the provided image(s) and identify all distinct physical objects suitable for cataloging.

DETECTION RULES:
1. Detect objects that could be inventoried (furniture, electronics, appliances, tools, books, clothing, etc.)
2. Ignore: walls, floors, ceilings, windows, built-in fixtures, people, pets
3. For each object, provide a bounding box as [ymin, xmin, ymax, xmax] normalized to 0-1000
4. Provide a specific label (e.g., "leather armchair" not just "chair")

CRITICAL - BOUNDING BOX ACCURACY:
Each bounding box MUST accurately frame ONLY the specific object described by its label.
- Double-check that [ymin, xmin, ymax, xmax] coordinates enclose ONLY the labeled item
- Do NOT include adjacent objects in a bounding box
- If two objects are close together, draw SEPARATE tight boxes around each one
- Verify the label matches what is INSIDE the bounding box, not nearby objects

MULTI-IMAGE RULES:
When given multiple images:
1. Identify if the SAME object appears in multiple photos (different angles)
2. Assign matching objects the same groupId
3. Different objects get different groupIds
4. Use visual similarity, position context, and reasoning to group

BOUNDING BOX FORMAT:
- box_2d: [ymin, xmin, ymax, xmax] where values are 0-1000
- ymin: top edge, ymax: bottom edge
- xmin: left edge, xmax: right edge

IF NO CATALOGABLE OBJECTS FOUND:
Return an empty array with a "reasoning" field explaining why.
```

### Layer 2 Cataloging System Prompt

```
You are an expert product cataloger. Analyze the provided image and create detailed catalog entries.

WORKFLOW:
1. Examine the image carefully for:
   - Product type, category, and sub-category
   - Visible barcodes (if any)
   - Brand logos or text
   - Physical condition indicators
   - Size/dimension clues
   - Quantity (if multiple identical items)

2. If you see a barcode, use barcode_lookup to get product details.
   Always also use google_lens_search for verification and additional data.

3. Verify tool results against what you see:
   - Does the returned product match the image?
   - If mismatch, trust your visual analysis over tool results.

4. Once you have HIGH or MEDIUM confidence on product identity:
   - Use web_search to find current market prices
   - Search query format: "{brand} {model} {condition} price"

5. Return complete catalog entry(ies) with confidence level.

CONFIDENCE SCORING:
- "high": Google Lens returned exact_matches:true OR barcode lookup succeeded AND visual verification confirms
- "medium": Google Lens returned similar products but not exact, OR barcode lookup failed but Google Lens found likely match
- "low": Only related suggestions available, relying primarily on visual analysis

PRICING:
- Use SOLD prices when available (eBay sold listings)
- Apply condition multipliers to new retail price:
  - new: 1.0
  - like-new: 0.85
  - good: 0.65
  - fair: 0.45
  - poor: 0.25
- If no pricing found, set estimatedValue: null

OUTPUT FORMAT:
Return valid JSON matching the CatalogItem schema.
```

### Rescan History Context Format

```
PREVIOUS CATALOG CONTEXT:
========================

Last identification ({timestamp}, confidence: {level}):
- Name: {name}
- Brand: {brand}
- Model: {model}
- Category: {category} > {subCategory}
- Condition: {condition}
- Estimated Value: ${value}

Tool results from previous attempt:
- barcode_lookup({code}): {result}
- google_lens_search: {result}
- web_search("{query}"): {result}

User corrections applied:
- {field}: "{old}" → "{new}" (user override)

========================

Now analyze the NEW image(s) below...
```
