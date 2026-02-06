# AXe Test Scenarios

**Purpose:** Living reference document for Claude-driven interactive testing via XcodeBuildMCP + AXe.
**Execution:** Claude reads this doc, runs each scenario interactively, adapts to UI state, and reports results.
**Not automated scripts** - Claude interprets the accessibility tree and makes intelligent assertions.

---

## Identifier Reference

### Tab Bar (`FloatingTabBar`)
| Identifier | Element |
|---|---|
| `tab.catalog` | Catalog tab |
| `tab.camera` | Capture/Camera tab |
| `tab.profile` | Profile tab |

### Inventory Screen (`InventoryView`)
| Identifier | Element |
|---|---|
| `inventory.selectButton` | Select/Done toggle button |
| `inventory.deselectAllButton` | Deselect All button (selection mode) |
| `inventory.bulkDeleteButton` | Bulk Delete button (selection mode) |
| `inventory.grid` | LazyVGrid item container |
| `inventory.loading` | Loading ProgressView |
| `inventory.emptyState` | Empty inventory view |
| `inventory.retryButton` | Error retry button |
| `inventory.searchField` | Search TextField |
| `inventory.searchClearButton` | Search clear (X) button |
| `inventory.item.<id>` | Individual item card (dynamic) |

### Item Detail (`ItemDetailView`)
| Identifier | Element |
|---|---|
| `detail.editButton` | Edit (pencil) button |
| `detail.recatalogButton` | Re-catalog (arrows) button |
| `detail.itemName` | Item name text |

### Edit Flow (`EditItemSheet`)
| Identifier | Element |
|---|---|
| `edit.nameField` | Name text field |
| `edit.brandField` | Brand text field |
| `edit.modelField` | Model text field |
| `edit.categoryField` | Category text field |
| `edit.subCategoryField` | Sub-Category text field |
| `edit.colorField` | Color text field |
| `edit.materialField` | Material text field |
| `edit.dimensionsField` | Dimensions text field |
| `edit.conditionPicker` | Condition picker |
| `edit.quantityStepper` | Quantity stepper |
| `edit.valueField` | Estimated Value currency field |
| `edit.cancelButton` | Cancel toolbar button |
| `edit.saveButton` | Save toolbar button |

### Detection Results (`DetectionResultsView`)
| Identifier | Element |
|---|---|
| `detection.catalogAllButton` | "Catalog All" header button |
| `detection.catalogButton.<groupId>` | Per-object "Catalog" button (dynamic) |
| `detection.object.<groupId>` | Per-object card (dynamic) |
| `detection.retakeButton` | Retake button |
| `detection.doneButton` | Done button |

### Profile Screen (`ProfileView`)
| Identifier | Element |
|---|---|
| `profile.userInfoCard` | User info card |
| `profile.notifications` | Notifications settings row |
| `profile.privacy` | Privacy settings row |
| `profile.help` | Help settings row |
| `profile.exportCSV` | Export CSV button |
| `profile.exportJSON` | Export JSON button |
| `profile.exportPDF` | Export PDF button |
| `profile.signOutButton` | Sign Out button |

---

## Test Scenarios

### Scenario 1: Tab Navigation

**Goal:** All 3 tabs are reachable and show correct content.

**Steps:**
1. `axe describe-ui` - verify tab identifiers present
2. `axe tap --id "tab.catalog"` - tap Catalog tab
3. `axe describe-ui` - verify "Inventory" navigation title
4. `axe tap --id "tab.camera"` - tap Capture tab
5. `axe describe-ui` - verify camera content
6. `axe tap --id "tab.profile"` - tap Profile tab
7. `axe describe-ui` - verify "Profile" navigation title

**Assertions:**
- All three tab identifiers (`tab.catalog`, `tab.camera`, `tab.profile`) are in the tree
- Each tab shows its expected navigation title or content
- Tab selection indicator updates correctly

**Skip if:** N/A - tabs always exist.

---

### Scenario 2: Empty Inventory State

**Goal:** Empty state renders when no items exist.

**Precondition:** Fresh user or cleared inventory.

**Steps:**
1. Navigate to Catalog tab: `axe tap --id "tab.catalog"`
2. `axe describe-ui` - inspect inventory state

**Assertions:**
- `inventory.emptyState` is visible
- "No Items Yet" label present
- "Open Camera" button present

**Skip if:** User has items (check for `inventory.item.*` identifiers in tree).

---

### Scenario 3: Item Grid & Scroll

**Goal:** Item cards render in 2-column grid, scrolling works.

**Precondition:** 5+ items in account.

**Steps:**
1. Navigate to Catalog tab
2. `axe describe-ui` - check grid and items
3. Count `inventory.item.*` identifiers
4. `axe swipe --direction down` - scroll down
5. `axe describe-ui` - check for additional items

**Assertions:**
- `inventory.grid` exists
- Multiple `inventory.item.*` identifiers present
- Scrolling reveals more items (if applicable)

**Skip if:** < 2 items.

---

### Scenario 4: Search & Filter

**Goal:** Search bar filters items, clear restores all, no-match shows empty search state.

**Steps:**
1. Navigate to Catalog tab (with items present)
2. `axe describe-ui` - count initial items
3. `axe tap --id "inventory.searchField"` - focus search
4. `axe type --text "<known-item-term>"` - type a search term
5. `axe describe-ui` - verify filtered results (fewer items)
6. `axe tap --id "inventory.searchClearButton"` - clear search
7. `axe describe-ui` - verify all items restored
8. `axe tap --id "inventory.searchField"` - focus again
9. `axe type --text "zzz_nonexistent_item_zzz"` - type nonsense
10. `axe describe-ui` - verify empty search state (ContentUnavailableView)

**Assertions:**
- Search filters items (count decreases with relevant query)
- Clearing search restores full list
- Non-matching search shows empty state

**Skip if:** < 2 items (nothing to filter).

---

### Scenario 5: Item Detail View

**Goal:** Tapping an item navigates to detail with metadata.

**Steps:**
1. Navigate to Catalog tab (with items present)
2. Find first `inventory.item.*` identifier
3. `axe tap --id "inventory.item.<id>"` - tap item
4. `axe describe-ui` - inspect detail view
5. Scroll down to see all metadata

**Assertions:**
- `detail.editButton` visible
- `detail.itemName` shows item name text
- Metadata cells present (brand, color, material, etc.)
- AI Confidence section visible (if populated)

**Skip if:** No items.

---

### Scenario 6: Edit Item Flow

**Goal:** Edit flow opens, form fields are interactive, cancel discards changes.

**Steps:**
1. Navigate to an item's detail view (see Scenario 5)
2. `axe tap --id "detail.editButton"` - tap edit
3. Rescan prompt sheet appears - tap "Skip, Edit Manually" or equivalent
4. `axe describe-ui` - verify edit sheet
5. Verify all edit field identifiers present
6. `axe tap --id "edit.nameField"` - focus name field
7. `axe type --text " modified"` - append text
8. `axe tap --id "edit.cancelButton"` - cancel edits
9. `axe describe-ui` - verify back on detail view, name unchanged

**Assertions:**
- `edit.nameField`, `edit.brandField`, `edit.modelField` etc. all present
- `edit.saveButton`, `edit.cancelButton` visible in toolbar
- Cancel discards changes (name reverts)

**Skip if:** No items, or edit flow not yet implemented.

---

### Scenario 7: Multi-Select & Bulk Delete

**Goal:** Selection mode works, multi-select toggles, bulk delete confirmation shows.

**Steps:**
1. Navigate to Catalog tab (with 2+ items)
2. `axe tap --id "inventory.selectButton"` - enter selection mode
3. `axe describe-ui` - verify button text changed to "Done"
4. Tap two item cards to select them
5. `axe describe-ui` - verify checkmarks appear, selection count in toolbar
6. `axe tap --id "inventory.bulkDeleteButton"` - tap bulk delete
7. `axe describe-ui` - verify confirmation dialog appears
8. Tap "Cancel" in the dialog
9. `axe tap --id "inventory.deselectAllButton"` - deselect all
10. `axe tap --id "inventory.selectButton"` - exit selection mode (tap "Done")

**Assertions:**
- Button toggles between "Select" and "Done"
- Checkmarks appear on selected items
- `inventory.bulkDeleteButton` and `inventory.deselectAllButton` visible in selection mode
- Confirmation dialog appears on bulk delete
- Cancel dismisses dialog without deleting

**Skip if:** < 2 items.

---

### Scenario 8: Context Menu (Long Press)

**Goal:** Long-press shows context menu with Edit/Delete.

**Steps:**
1. Navigate to Catalog tab (with items, NOT in selection mode)
2. Find an item: `inventory.item.<id>`
3. `axe long-press --id "inventory.item.<id>"` - long press
4. `axe describe-ui` - verify context menu
5. Check for "Delete" menu option
6. Tap "Delete" if present
7. `axe describe-ui` - verify confirmation dialog
8. Tap "Cancel" to dismiss

**Assertions:**
- Context menu appears with "Delete" option
- "Re-catalog" option present in context menu
- "Edit" option may or may not be present (depends on implementation)
- Delete shows confirmation dialog
- Cancel dismisses without deleting

**Skip if:** No items.

---

### Scenario 9: Profile View

**Goal:** Profile screen shows user info, settings, export, sign out.

**Steps:**
1. `axe tap --id "tab.profile"` - navigate to Profile tab
2. `axe describe-ui` - inspect profile screen

**Assertions:**
- `profile.userInfoCard` visible
- `profile.signOutButton` visible
- Settings rows visible: `profile.notifications`, `profile.privacy`, `profile.help`
- Export buttons visible: `profile.exportCSV`, `profile.exportJSON`, `profile.exportPDF`

**Note:** Settings rows (Notifications, Privacy, Help) are placeholder - just verify they render, don't test navigation.

---

### Scenario 10: Layout Correctness (Frame Check)

**Goal:** No zero-sized or off-screen interactive elements.

**Steps:**
1. `axe describe-ui --format json` - get structured UI tree
2. Parse all interactive elements (buttons, links, text fields)
3. Check frame dimensions

**Assertions:**
- All buttons/links have `frame.width >= 44` and `frame.height >= 44` (Apple HIG minimum touch target)
- No negative x/y coordinates (off-screen elements)
- No zero-width or zero-height interactive elements

**Skip if:** N/A - always run on whatever screen is visible.

---

### Scenario 11: Accessibility Identifier Audit

**Goal:** All identifiers from Step 1 are present in the accessibility tree.

**Steps:**
1. Navigate to Catalog tab: `axe tap --id "tab.catalog"`
2. `axe describe-ui` - check for inventory identifiers
3. Navigate to Profile tab: `axe tap --id "tab.profile"`
4. `axe describe-ui` - check for profile identifiers
5. If items exist, tap into detail view and check detail identifiers
6. If edit flow is accessible, check edit identifiers

**Output:** Report listing:
- Found identifiers (with screen)
- Missing identifiers (with expected screen)
- Unexpected identifiers (bonus)

---

### Scenario 12: Deep Catalog Trigger (Gemini 3 Pro)

**Goal:** Verify "Catalog All" / individual "Catalog" button triggers Layer 2 deep cataloging with Gemini 3 Pro, and the UI reflects the full processing lifecycle.

**Precondition:** Must be on DetectionResultsView with detected objects (requires a capture session - works on device with real camera, or on simulator if session is already active).

**Steps:**
1. Verify detection results screen shows objects: `detection.object.*` identifiers present
2. Verify "Catalog All" button visible: `detection.catalogAllButton` present
3. `axe tap --id "detection.catalogButton.<groupId>"` - tap individual Catalog button
4. Immediately `axe describe-ui` - verify:
   - That object's card shows ProgressView spinner (cataloging state)
   - Bounding box border turns yellow (cataloging color)
   - "Catalog" button is replaced by spinner
5. Wait ~5-15 seconds for Gemini 3 Pro processing, then re-inspect:
   - Object card shows green checkmark (cataloged state)
   - Bounding box border turns green
   - "Catalog" button gone, replaced by `checkmark.circle.fill`
6. `axe tap --id "detection.catalogAllButton"` - catalog remaining objects, verify same progression
7. `axe tap --id "detection.doneButton"` - return to inventory
8. Navigate to inventory tab and find newly cataloged item(s)
9. Tap into detail view and verify Layer 2 metadata:
   - `detail.itemName` shows specific product name (not just Layer 1 label)
   - Brand + Model visible (Gemini 3 Pro identifies these)
   - Category + Sub-Category badges present
   - Estimated value visible (from web_search tool)
   - AI Confidence section shows High/Medium/Low
   - Processing notes may be present

**Assertions:**
- UI state machine: uncataloged (button) -> cataloging (spinner/yellow) -> cataloged (checkmark/green)
- Layer 2 data present in item detail: name, brand, model, value, confidence
- Catalog triggered via Firestore write -> onItemFromSession -> Gemini 3 Pro

**Alternative (Simulator):** Re-catalog can be triggered from inventory without a camera:
1. Long-press any item card → tap "Re-catalog" in context menu
2. Or tap into detail view → tap re-catalog button (`detail.recatalogButton`)
3. Confirm in the dialog → item status resets to "pending" → Cloud Function re-triggers

**Note:** This is an end-to-end test. On device, the full capture flow is testable. On simulator, use the re-catalog flow (context menu or detail view) to trigger the AI pipeline for existing items. E2E test mode (`--e2e-test-mode` launch arg) enables image injection via PHPicker for full pipeline testing on simulator.

---

### Scenario 13: Catalog Processing States

**Goal:** Items show progressive detail based on AI processing status.

**Steps:**
1. Navigate to Catalog tab
2. `axe describe-ui` - find items with different statuses
3. Look for status badges: "Processing" (blue), "Analyzed" (green), "Complete" (green), "Failed" (red)
4. Tap into items of each status and compare metadata completeness

**Assertions:**
- Pending items show "Processing" badge (blue), limited metadata
- Analyzed items show "Analyzed" badge (green), more metadata
- Complete items show full metadata + value + confidence
- Failed items show "Failed" badge (red)

**Skip if:** All items have the same status.

---

## Execution Model

When the user says "run the test scenarios" or invokes `/device-tester`:

1. Claude builds and launches app on simulator (XcodeBuildMCP)
2. Claude runs each scenario from this doc sequentially
3. For each scenario, Claude:
   - Checks skip conditions (adapts to current app state)
   - Runs the AXe commands
   - Inspects `describe-ui` output for assertions
   - Takes screenshots at key points
   - Reports PASS / FAIL / SKIP with details
4. At the end, Claude summarizes: X passed, Y failed, Z skipped, with screenshots

This is **not** a brittle script - Claude reads the accessibility tree, understands the UI state, and makes intelligent assertions. If a feature changed or isn't implemented, it skips gracefully.

---

## Changelog

| Date | Change |
|---|---|
| 2026-02-05 | Added re-catalog identifiers, updated Scenario 8 & 12 for re-catalog flow |
| 2026-02-05 | Initial creation with 13 scenarios |
