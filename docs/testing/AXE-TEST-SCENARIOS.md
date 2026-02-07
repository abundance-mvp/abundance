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
| `profile.signOutButton` | Sign Out button |

---

## Test Scenarios

### Scenario 1: Tab Navigation

**Goal:** All 3 tabs are reachable and show correct content.

**Steps:**
1. `axe describe-ui` - verify "Tab Bar" group present
2. Tap Catalog tab by coordinate (x=100, y=850)
3. `axe describe-ui` - verify "Inventory" navigation title
4. Tap Camera tab by coordinate (x=200, y=850)
5. `axe describe-ui` - verify camera content ("Camera" heading or `camera.simulatorPlaceholder`)
6. Tap Profile tab by coordinate (x=300, y=850)
7. `axe describe-ui` - verify "Profile" navigation title

**Assertions:**
- "Tab Bar" group exists in the AX tree
- Each tab shows its expected navigation title or content
- Catalog tab shows "Inventory" heading
- Camera tab shows "Camera" heading (simulator: `camera.simulatorPlaceholder`)
- Profile tab shows "Profile" heading

**Note:** Tab bar button identifiers (`tab.catalog`, `tab.camera`, `tab.profile`) are set on content views in code but not traversable by `snapshot_ui`/AXe due to SwiftUI TabView platform limitation (see Known Limitations). Use coordinate-based tapping.

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
- Export button visible: `profile.exportCSV`

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

---

## Known Limitations

| Issue | Workaround |
|---|---|
| SwiftUI toolbar buttons (`edit.cancelButton`, `edit.saveButton`) not exposed as children in the AX tree | Identifiers are correctly applied in code; this is a SwiftUI accessibility limitation. Assert by label text ("Cancel", "Save") instead. |
| SwiftUI `TabView` tab bar buttons not traversable by `snapshot_ui`/AXe | Identifiers (`tab.catalog`, `tab.camera`, `tab.profile`) are correctly set on content views in code. `UITabBarButton` elements are not exposed through the AXe accessibility hierarchy. Use coordinate-based tapping: Catalog (100,850), Camera (200,850), Profile (300,850). Works correctly in XCUITest via `tabBars.buttons["Catalog"]`. |
| `inventory.grid` identifier on `LazyVGrid` not exposed as a separate AX element | Grid items appear as direct children of the Application. The `LazyVGrid` container is not represented as a distinct element in the AX tree. Verify grid by checking for multiple `inventory.item.*` identifiers instead. |

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
| 2026-02-07 | Removed Scenario 12 (Catalog Processing States) — requires cloud API calls, violates no-network-calls policy. Now 11 scenarios total. |
| 2026-02-07 | Removed Scenario 12 (Deep Catalog Trigger) — catalog pipeline requires Cloud Functions/network, not suitable for AXe testing. Renumbered Scenario 13 → 12. Now 12 scenarios total. |
| 2026-02-07 | Fixed 4 AXe issues: search clear button 44x44 touch target, item IDs in selection mode, tab IDs on content views, Scenario 12 rewritten for simulator re-catalog flow. Documented 3 known limitations (tab bar, toolbar buttons, grid container). |
| 2026-02-06 | Fixed 7 AXe findings: tab IDs, grid ID, recatalog button/context menu, CSV-only export, select button height, known limitations |
| 2026-02-05 | Added re-catalog identifiers, updated Scenario 8 & 12 for re-catalog flow |
| 2026-02-05 | Initial creation with 13 scenarios |
