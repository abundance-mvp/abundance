# AXe Test Scenarios

**Purpose:** Living reference document for Claude-driven interactive testing via XcodeBuildMCP + AXe.
**Execution:** Claude reads this doc, runs each scenario interactively, adapts to UI state, and reports results.
**Not automated scripts** - Claude interprets the accessibility tree and makes intelligent assertions.

---

## Identifier Reference

### Tab Bar (`FloatingTabBar` / `DebugMainTabView`)
| Identifier | Element |
|---|---|
| `tab.collection` | Collection tab |
| `tab.scan` | Scan tab |
| `tab.profile` | Profile tab |

### Collection Screen (`CollectionView`)
| Identifier | Element |
|---|---|
| `collection.selectButton` | Select/Done toggle button |
| `collection.deselectAllButton` | Deselect All button (selection mode) |
| `collection.bulkDeleteButton` | Bulk Delete button (selection mode) |
| `collection.grid` | LazyVGrid item container |
| `collection.loading` | Loading ProgressView |
| `collection.emptyState` | Empty collection view |
| `collection.retryButton` | Error retry button |
| `inventory.searchField` | Search TextField |
| `inventory.searchClearButton` | Search clear (X) button |
| `collection.item.<id>` | Individual item card (dynamic) |

### Item Detail (`ItemDetailView`)
| Identifier | Element |
|---|---|
| `detail.editButton` | Edit (pencil) button |
| `detail.refreshButton` | Refresh (arrows) button |
| `detail.itemName` | Item name text |
| `detail.processingBanner` | Processing/refreshing banner |

### Edit Flow (`RescanPromptSheet` + `EditItemSheet`)
| Identifier | Element |
|---|---|
| `edit.takeNewPhotoButton` | "Take New Photo" button (rescan prompt) |
| `edit.skipRescanButton` | "Edit Without Rescan" button (rescan prompt) |
| `edit.cancelButton` | Cancel button (rescan prompt + edit form toolbar) |
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
| `edit.addPhotoButton` | Add photo button |
| `edit.saveButton` | Save toolbar button |

### Detection Results (`DetectionResultsView`)
| Identifier | Element |
|---|---|
| `detection.selectAllButton` | "Select All" / "Deselect All" header button |
| `detection.catalogSelectedButton` | "Catalog" button for selected objects |
| `detection.toggleCheck.<groupId>` | Per-object selection toggle (dynamic) |
| `detection.object.<groupId>` | Per-object card (dynamic) |
| `detection.retakeOverlayButton` | Retake overlay button (on image) |
| `detection.retakeButton` | Retake button (bottom bar) |
| `detection.doneButton` | Done button (bottom bar) |

### Profile Screen (`ProfileView`)
| Identifier | Element |
|---|---|
| `profile.userInfoCard` | User info card |
| `profile.notifications` | Notifications settings row |
| `profile.privacy` | Privacy settings row |
| `profile.help` | Help settings row |
| `profile.exportCSV` | Export CSV button |
| `profile.signOutButton` | Sign Out button |

---

## Test Scenarios

### Scenario 1: Tab Navigation

**Goal:** All 3 tabs are reachable and show correct content.

**Steps:**
1. `snapshot_ui` - verify tab bar area present
2. `tap(x: 100, y: 850)` - Collection tab
3. `snapshot_ui` - verify "Collection" navigation title
4. `tap(x: 200, y: 850)` - Scan tab
5. `snapshot_ui` - verify scan content ("Scan" heading or `camera.simulatorPlaceholder`)
6. `tap(x: 300, y: 850)` - Profile tab
7. `snapshot_ui` - verify "Profile" navigation title

**Assertions:**
- "Tab Bar" group exists in the AX tree
- Each tab shows its expected navigation title or content
- Collection tab shows "Collection" heading
- Scan tab shows "Scan" heading (simulator: `camera.simulatorPlaceholder`)
- Profile tab shows "Profile" heading

**Note:** Tab bar button identifiers (`tab.collection`, `tab.scan`, `tab.profile`) are set on content views in code but not traversable by `snapshot_ui`/AXe due to SwiftUI TabView platform limitation (see Known Limitations). Use coordinate-based tapping.

**Skip if:** N/A - tabs always exist.

---

### Scenario 2: Empty Collection State

**Goal:** Empty state renders when no items exist.

**Precondition:** Fresh user or cleared collection.

**Steps:**
1. Navigate to Collection tab: `tap(x: 100, y: 850)`
2. `snapshot_ui` - inspect collection state

**Assertions:**
- `collection.emptyState` is visible
- "No Items Yet" label present
- "Open Camera" button present

**Skip if:** User has items (check for `collection.item.*` identifiers in tree).

---

### Scenario 3: Item Grid & Scroll

**Goal:** Item cards render in 2-column grid, scrolling works.

**Precondition:** 5+ items in account.

**Steps:**
1. Navigate to Collection tab: `tap(x: 100, y: 850)`
2. `snapshot_ui` - check grid and items
3. Count `collection.item.*` identifiers
4. `swipe(direction: "up")` - scroll down (swipe up to scroll content down)
5. `snapshot_ui` - check for additional items

**Assertions:**
- `collection.grid` exists
- Multiple `collection.item.*` identifiers present
- Scrolling reveals more items (if applicable)

**Skip if:** < 2 items.

---

### Scenario 4: Search & Filter

**Goal:** Search bar filters items, clear restores all, no-match shows empty search state.

**Steps:**
1. Navigate to Collection tab (with items present)
2. `snapshot_ui` - count initial items
3. `tap(id: "inventory.searchField")` - focus search (MUST use id, not coordinates)
4. `snapshot_ui` - confirm focus (AXValue changes from placeholder)
5. `type_text("<known-item-term>")` - type a search term from a visible item's label
6. `snapshot_ui` - verify filtered results (fewer items)
7. `tap(id: "inventory.searchClearButton")` - clear search
8. `snapshot_ui` - verify all items restored
9. `tap(id: "inventory.searchField")` - focus again
10. `type_text("zzz_nonexistent_item_zzz")` - type nonsense
11. `snapshot_ui` - verify empty search state (ContentUnavailableView)

**Assertions:**
- Search filters items (count decreases with relevant query)
- Clearing search restores full list
- Non-matching search shows empty state

**Skip if:** < 2 items (nothing to filter).

---

### Scenario 5: Item Detail View

**Goal:** Tapping an item navigates to detail with metadata.

**Steps:**
1. Navigate to Collection tab (with items present)
2. `snapshot_ui` - find first `collection.item.*` identifier
3. `tap(id: "collection.item.<id>")` - tap item
4. `snapshot_ui` - inspect detail view
5. `swipe(direction: "up")` - scroll down to see all metadata

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
2. `tap(id: "detail.editButton")` - tap edit
3. `snapshot_ui` - verify **rescan prompt sheet** appears (NOT the edit form directly — see Known Limitations)
4. Verify rescan prompt identifiers: `edit.takeNewPhotoButton`, `edit.skipRescanButton`, `edit.cancelButton`
5. `tap(id: "edit.skipRescanButton")` - skip rescan to reach edit form
6. `snapshot_ui` - verify edit form with field identifiers
7. Verify all edit field identifiers present
8. `tap(id: "edit.nameField")` - focus name field
9. `type_text(" modified")` - append text
10. Dismiss edit form: `swipe(x: 200, y: 100, direction: "down", duration: 0.3)` — toolbar Cancel/Save buttons are NOT in AX tree (see Known Limitations)
11. `snapshot_ui` - verify back on detail view, name unchanged

**Assertions:**
- Rescan prompt sheet appears first with `edit.skipRescanButton`
- `edit.nameField`, `edit.brandField`, `edit.modelField` etc. all present in edit form
- `edit.saveButton`, `edit.cancelButton` identifiers exist in code but are NOT accessible via AXe (SwiftUI toolbar limitation)
- Swipe-to-dismiss discards changes (name reverts)

**Skip if:** No items, or edit flow not yet implemented.

---

### Scenario 7: Multi-Select & Bulk Delete

**Goal:** Selection mode works, multi-select toggles, bulk delete confirmation shows.

**Steps:**
1. Navigate to Collection tab (with 2+ items)
2. `tap(id: "collection.selectButton")` - enter selection mode
3. `snapshot_ui` - verify button label changed to "Done"
4. `tap(id: "collection.item.<id1>")` then `tap(id: "collection.item.<id2>")` - select two items
5. `snapshot_ui` - verify "selected" in item labels, selection count in delete button
6. `tap(id: "collection.bulkDeleteButton")` - tap bulk delete
7. `snapshot_ui` - verify confirmation dialog appears
8. Tap "Cancel" in the dialog
9. `tap(id: "collection.deselectAllButton")` - deselect all
10. `tap(id: "collection.selectButton")` - exit selection mode (tap "Done")

**Assertions:**
- Button toggles between "Select" and "Done"
- Checkmarks appear on selected items
- `collection.bulkDeleteButton` and `collection.deselectAllButton` visible in selection mode
- Confirmation dialog appears on bulk delete
- Cancel dismisses dialog without deleting

**Skip if:** < 2 items.

---

### Scenario 8: Context Menu (Long Press)

**Goal:** Long-press shows context menu with Edit/Delete.

**Steps:**
1. Navigate to Collection tab (with items, NOT in selection mode)
2. `snapshot_ui` - find an item `collection.item.<id>` and note its frame center coordinates
3. `long_press(x: <center_x>, y: <center_y>, duration: 1500)` — `long_press` does NOT accept an `id` parameter, must use coordinates calculated from item's AXFrame (x + width/2, y + height/2). See Known Limitations.
4. `snapshot_ui` - verify context menu
5. Check for "Delete" and "Refresh" menu options
6. Tap "Delete" if present
7. `snapshot_ui` - verify confirmation dialog
8. Tap "Cancel" to dismiss (or tap "Dismiss context menu" button if no action taken)

**Assertions:**
- Context menu appears with "Delete" option
- "Refresh" option present in context menu
- "Preview" option present in context menu
- Delete shows confirmation dialog
- Cancel dismisses without deleting

**Skip if:** No items.

---

### Scenario 9: Profile View

**Goal:** Profile screen shows user info, settings, export, sign out.

**Steps:**
1. `tap(x: 300, y: 850)` - navigate to Profile tab (coordinate-based, see Known Limitations)
2. `snapshot_ui` - inspect profile screen

**Assertions:**
- `profile.userInfoCard` visible
- `profile.signOutButton` visible
- Settings rows visible: `profile.notifications`, `profile.privacy`, `profile.help`
- Export button visible: `profile.exportCSV`

**Note:** Settings rows (Notifications, Privacy, Help) are placeholder - just verify they render, don't test navigation.

---

### Scenario 10: Layout Correctness (Frame Check)

**Goal:** No zero-sized or off-screen interactive elements.

**Steps:**
1. `snapshot_ui` - get structured UI tree on each screen visited during prior scenarios
2. Parse all interactive elements (buttons, links, text fields) from collected AX data
3. Check frame dimensions from AXFrame values

**Assertions:**
- All buttons/links have `frame.width >= 44` and `frame.height >= 44` (Apple HIG minimum touch target)
- No negative x/y coordinates (off-screen elements)
- No zero-width or zero-height interactive elements

**Skip if:** N/A - always run on whatever screen is visible.

---

### Scenario 11: Accessibility Identifier Audit

**Goal:** All identifiers from the Identifier Reference are present in the accessibility tree.

**Steps:**
1. Navigate to Collection tab: `tap(x: 100, y: 850)`
2. `snapshot_ui` - check for collection identifiers
3. Navigate to Profile tab: `tap(x: 300, y: 850)`
4. `snapshot_ui` - check for profile identifiers
5. If items exist, tap into detail view and check detail identifiers
6. If edit flow is accessible, check edit identifiers (remember two-step flow: rescan prompt → edit form)

**Output:** Report listing:
- Found identifiers (with screen)
- Missing identifiers (with expected screen)
- Unexpected identifiers (bonus)

---

---

## Known Limitations

| Issue | Workaround |
|---|---|
| SwiftUI toolbar buttons (`edit.cancelButton`, `edit.saveButton`) not exposed as children in the AX tree when inside NavigationBar | Identifiers are correctly applied in code; this is a SwiftUI accessibility limitation. The `edit.cancelButton` on the **rescan prompt sheet** IS accessible — only the edit form's NavigationBar toolbar buttons are hidden. To dismiss the edit form, **swipe down** (y=100 → y=800, duration 0.3s). |
| SwiftUI `TabView` tab bar buttons not traversable by `snapshot_ui`/AXe | Identifiers (`tab.collection`, `tab.scan`, `tab.profile`) are correctly set on content views in code. `UITabBarButton` elements are not exposed through the AXe accessibility hierarchy. Use coordinate-based tapping: **Collection (100,850), Scan (200,850), Profile (300,850)**. If tap doesn't register (scrollable content intercepts), take a `screenshot` to verify tab bar position and adjust y (try 840-860). Works correctly in XCUITest via `tabBars.buttons["Collection"]`. |
| `collection.grid` identifier on `LazyVGrid` not exposed as a separate AX element | Grid items appear as direct children of the Application. The `LazyVGrid` container is not represented as a distinct element in the AX tree. Verify grid by checking for multiple `collection.item.*` identifiers instead. |
| Search field requires tap-by-ID before typing | The custom `SearchBar` field does not activate from a coordinate tap alone. Always use `tap(id: "inventory.searchField")` first, confirm focus via `snapshot_ui` (AXValue changes from placeholder to empty or typed text), then use `type_text`. |
| Edit flow has a rescan prompt before the edit form | Tapping `detail.editButton` opens a rescan prompt sheet with `edit.takeNewPhotoButton`, `edit.skipRescanButton`, and `edit.cancelButton`. Tap `edit.skipRescanButton` ("Edit Without Rescan") to reach the actual edit form. |
| `long_press` requires explicit coordinates, not element ID | The XcodeBuildMCP `long_press` tool only accepts `x`, `y`, `duration` — no `id` parameter. Calculate coordinates from the target element's frame center (x + width/2, y + height/2). Use duration 1500ms. |

---

## Execution Model

When the user says "run the test scenarios" or invokes `/device-tester`:

1. Claude builds and launches app on simulator (XcodeBuildMCP)
2. Claude runs each scenario from this doc sequentially
3. For each scenario, Claude:
   - Checks skip conditions (adapts to current app state)
   - Uses XcodeBuildMCP tools: `snapshot_ui`, `tap`, `swipe`, `long_press`, `type_text`
   - Inspects `snapshot_ui` output for assertions
   - Takes `screenshot` at key points
   - Reports PASS / FAIL / SKIP with details
4. At the end, Claude summarizes: X passed, Y failed, Z skipped, with screenshots

This is **not** a brittle script - Claude reads the accessibility tree, understands the UI state, and makes intelligent assertions. If a feature changed or isn't implemented, it skips gracefully.

---

## Changelog

| Date | Change |
|---|---|
| 2026-02-08 | Fixed stale identifiers: tab IDs (`tab.catalog`/`tab.camera` → `tab.collection`/`tab.scan`), search IDs (`collection.searchField` → `inventory.searchField`, `collection.searchClearButton` → `inventory.searchClearButton`), detection IDs (`detection.catalogAllButton` → `detection.selectAllButton`, added `detection.catalogSelectedButton`, `detection.toggleCheck.<groupId>`, `detection.retakeOverlayButton`). Updated all scenario steps and Known Limitations to match current code. |
| 2026-02-07 | Updated all scenario steps from stale `axe` CLI syntax to XcodeBuildMCP tool names (`snapshot_ui`, `tap`, `swipe`, `long_press`, `type_text`). Expanded Known Limitations to 6 entries (search field, edit flow, long_press). Updated Scenario 6 for two-step edit flow and swipe-to-dismiss. Updated Scenario 8 for coordinate-based long_press. Updated Scenarios 1, 2, 9, 11 for coordinate-based tab navigation. |
| 2026-02-07 | Removed Scenario 12 (Catalog Processing States) — requires cloud API calls, violates no-network-calls policy. Now 11 scenarios total. |
| 2026-02-07 | Removed Scenario 12 (Deep Catalog Trigger) — catalog pipeline requires Cloud Functions/network, not suitable for AXe testing. Renumbered Scenario 13 → 12. Now 12 scenarios total. |
| 2026-02-07 | Fixed 4 AXe issues: search clear button 44x44 touch target, item IDs in selection mode, tab IDs on content views, Scenario 12 rewritten for simulator re-catalog flow. Documented 3 known limitations (tab bar, toolbar buttons, grid container). |
| 2026-02-06 | Fixed 7 AXe findings: tab IDs, grid ID, refresh button/context menu, CSV-only export, select button height, known limitations |
| 2026-02-05 | Added re-catalog identifiers, updated Scenario 8 & 12 for re-catalog flow |
| 2026-02-05 | Initial creation with 13 scenarios |
