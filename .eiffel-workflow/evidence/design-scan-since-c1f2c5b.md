# Design Scan (diff mode): simple_widgets, since c1f2c5b (0.46.0)
# Date: 2026-10-28
# Subjects: 16 changed classes (of 157 src files), compared against all of src/
# Read-only scan; no source modified, nothing compiled.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (Findings 1, 2, 3, 4, 6, 7) | 6 | 2 | 3 | 1 |
| MI (Finding 5) | 1 | 0 | 1 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| Contracts (Findings 8, 9) | 2 | 0 | 1 | 1 |
| **Total** | **9** | **2** | **5** | **2** |

## Findings

| # | Priority | Category | Classes | Opportunity | Effort | Suggested Skill |
|---|----------|----------|---------|-------------|--------|-----------------|
| 1 | HIGH | A5 | SW_DATA_GRID, SW_DOC_UNITS, SW_PARAGRAPH_LIST, SW_TREE, SW_LABEL | `copy_text` is five private copies of one body (plus inline clipboard sites elsewhere): one shared helper | 1 feature, 5 deletions | /eiffel.abstract |
| 2 | HIGH | D1 | SW_TEXT_GEOMETRY, SW_SHAPING | The two `line_height` floors in one class measure different font lists (the 0.46.0 fix reached one) | 1 helper, 2 call sites | refactor branch |
| 3 | MEDIUM | A5 | SW_DOCK_HOST | `forget_floating_key` is a third copy of `forget_key`; `is_panel_floating` inlines `has_key` | 2 features | refactor |
| 4 | MEDIUM | A1/A6 | SW_DATA_GRID, SW_PARAGRAPH_LIST, SW_TREE, SW_DOC_UNITS, SW_INTERLINEAR | Repeated "note context, build Copy items (enabled or disabled twin)" protocol | 1 helper | /eiffel.abstract |
| 5 | MEDIUM | M2 | SW_WIDGET, SW_MENU | Menu-offering role lives in the SW_WIDGET root | 4 features | /eiffel.mi |
| 6 | MEDIUM | A5 | SW_TEXT_BOX, SW_TEXT_SELECTION, SW_CHAT_THREAD, SW_SPREADSHEET | Older direct clipboard writers repeat the same shape | 3 features | fold into 1 |
| 7 | LOW | A1/T1 | SW_DOCK_ZONE, SW_DOCK_HOST | Reach-through to `host.panels.i_th`, parallel title-draw branches, repeated 3.5 radius | cosmetic | none |
| 8 | MEDIUM | contracts | SW_WIDGET, SW_WINDOW, SW_TREE, SW_DOCK_ZONE | Empty-menu case unguarded; thin contracts on new menu features | 2 features | /eiffel.contracts |
| 9 | LOW | contracts | SW_MENU | `index_of_label` public without in-library use | none | none |

## Detailed Findings

### Finding 1: `copy_text` is five copies of one body (answer to the question asked: yes, a missing shared helper)
**Priority:** HIGH
**Category:** A5 (duplicated bodies), A6, M2
**Classes:** SW_DATA_GRID, SW_DOC_UNITS, SW_PARAGRAPH_LIST, SW_TREE (each `copy_text (a_text: READABLE_STRING_GENERAL)`), SW_LABEL (`copy_text`, no argument, puts `text`)
**Description:** Each 0.46.0 context menu added a private feature that creates an SW_CLIPBOARD and calls `set_text`. The four argument-taking bodies are identical; the label differs only in what it copies. SW_INTERLINEAR inherits SW_DOC_UNITS' copy and calls it (src/sw_interlinear.e:384, :400), so it is a sixth consumer. The wider library holds five more inline `create clip ... clip.set_text (...)` sites, so there is no single clipboard-writing door above SW_CLIPBOARD.
**Evidence:**
- src/sw_data_grid.e:748-755 `copy_text`; used at :631, :636, :640
- src/sw_doc_units.e:406-413 `copy_text`; used at :398, :400
- src/sw_paragraph_list.e:550-557 `copy_text`; used at :503, :508, :510
- src/sw_tree.e:521-528 `copy_text`; used at :372
- src/sw_label.e:211-218 `copy_text` (same body on `text`); agent at :205
- Inline sites doing the same: src/sw_text_selection.e:178-184, src/sw_text_box.e:404 and :998-1005, src/sw_chat_thread.e:855-866, src/sw_spreadsheet.e:367-373
**Suggested Action:** One effective feature `copy_to_clipboard (a_text)` with a postcondition, placed in a small stateless mixin (for example SW_CLIPBOARD_COPYING) that the owners inherit side by side with their existing parents, in the same shape as SW_TEXT_POINTING and SW_VSCROLLING. It has no state, so no feature-adaptation conflicts. SW_LABEL becomes `agent copy_to_clipboard (text)`. A per-owner helper object adds nothing here because there is no state to hold.
**Effort:** 1 feature, 5 deletions, 6 call-site renames (optionally 5 more inline sites)

### Finding 2: Two line-height floors in SW_TEXT_GEOMETRY measure different fonts
**Priority:** HIGH (drift, D1)
**Category:** D1
**Classes:** SW_TEXT_GEOMETRY, SW_SHAPING, SW_TEXT_BOX
**Description:** 0.46.0 changed SW_SHAPING.line_height to measure `primary_fonts` (the theme face leading the list) once `set_theme_faces` ran. In the same release SW_TEXT_GEOMETRY's per-line floor was changed to use the geometry's own `fonts` through `a_kit.facade.line_height` when a host role policy is set (src/sw_text_geometry.e:707-712). The whole-box floor in the same class still calls `al_kit.line_height (px)` (src/sw_text_geometry.e:538), right after `set_fonts (al_kit.fonts_for_role ...)` at :530. For a role-set host the per-line floor and the box floor therefore measure different faces and can disagree by a few pixels, the very symptom the fix comment describes (25 px against 21 px). SW_TEXT_BOX measures through the kit as well (src/sw_text_box.e:593). The fix reached one of three call sites. Which side should win is a behavior decision; the evidence shows only that they diverge when a role policy is set.
**Evidence:**
- src/sw_shaping.e:303-313 (`primary_fonts` branch), :332-333 (set in `set_theme_faces`), :352 (cleared in `set_fonts`)
- src/sw_text_geometry.e:538 against :707-712
- src/sw_text_box.e:593
**Suggested Action:** One private `floor_height (a_kit, a_px)` in SW_TEXT_GEOMETRY used at :538 and :709, and an optional-fonts overload on SW_SHAPING.line_height so the geometry stops reaching through `a_kit.facade`. Add a test comparing the two floors for a role-set geometry.
**Effort:** 1 helper, 2 call sites

### Finding 3: Key-list helpers duplicated inside SW_DOCK_HOST
**Priority:** MEDIUM
**Category:** A5
**Classes:** SW_DOCK_HOST
**Description:** 0.46.0 added `has_key` and `forget_key` (generic over a key list) for the maximizable and marked lists, but the older floating list keeps inline copies: `forget_floating_key` repeats the `forget_key` loop line for line, and `is_panel_floating` repeats `has_key` with `same_string` instead of `same_string_general`.
**Evidence:**
- src/sw_dock_host.e:1191-1195 `has_key`; :1197-1213 `forget_key` (with postcondition `gone`)
- src/sw_dock_host.e:1139-1153 `forget_floating_key` (same loop, no postcondition)
- src/sw_dock_host.e:732 `is_panel_floating` inlines the `has_key` body
- three lists of panel keys: `floating_keys` :1135, `maximizable_keys` :1179, `marked_keys` :1185, each extended with `.key.twin` (:637, :704, :769)
**Suggested Action:** Call `has_key (floating_keys, ...)` and `forget_key (floating_keys, ...)`. Larger step: a small SW_KEY_SET class (add, remove, has with the postconditions once) held three times.
**Effort:** 2 features now, 1 small class later

### Finding 4: The context-menu protocol over a pointed item is repeated by five readers
**Priority:** MEDIUM
**Category:** A1/A6
**Classes:** SW_DATA_GRID, SW_PARAGRAPH_LIST, SW_TREE, SW_DOC_UNITS, SW_INTERLINEAR
**Description:** Every reader notes the pointed item in a differently named attribute (`context_model` and `context_column`, `context_item`, `context_row`, `context_item`, `context_token`), creates the menu, adds an enabled Copy item or a disabled twin (`add_item ("Copy ...", "", False, Void)`), and promises `ensure then offered: Result /= Void`. The attribute exists for the client's `menu_extension`, so clients learn five names for one idea.
**Evidence:**
- src/sw_data_grid.e:615-641 (enabled and disabled pairs at :630-638)
- src/sw_paragraph_list.e:496-514 (pair at :502-506)
- src/sw_tree.e:347-379 (pair at :371-375)
- src/sw_doc_units.e:382-404
- src/sw_interlinear.e:377-391
**Suggested Action:** In the mixin from Finding 1 add `add_copy_item (a_menu, a_label, a_has_text, a_text)` so each menu reads declaratively. Keep the per-class context noting (types differ) but document one convention next to `menu_extension` in SW_WIDGET.
**Effort:** 1 helper feature, 5 classes simplified

### Finding 5: Menu-extension protocol lives in the SW_WIDGET root
**Priority:** MEDIUM
**Category:** M2
**Classes:** SW_WIDGET (src/sw_widget.e:666-705), SW_WINDOW (src/sw_window.e:2337)
**Description:** `context_menu`, `menu_extension`, `set_menu_extension` and `offered_menu` form one role (menu offering; `offered_menu` is the template method, `context_menu` the hook). It sits in the root every widget inherits, beside `pending_menu` and `take_pending_menu` (src/sw_widget.e:652-663), a second menu role (popup hand-off for combos, selects and tabs). A mixin for menu offering would be the side-by-side shape Larry prefers. Cost: the `undefine ... context_menu` lists (src/sw_document_view.e:72, src/sw_doc_units.e:40 and :48, src/sw_paragraph_list.e:84 and :95) must be revisited, so this is a refactor rather than a quick win.
**Suggested Action:** /eiffel.mi only if the root keeps growing; nothing required today.
**Effort:** 4 features moved; touches the inherit clauses of about 10 classes

### Finding 6: Older direct clipboard writers repeat the same shape
**Priority:** MEDIUM
**Category:** A5
**Classes:** SW_TEXT_SELECTION, SW_TEXT_BOX, SW_CHAT_THREAD, SW_SPREADSHEET (none changed in this diff; listed because Finding 1 would unify them)
**Description:** Three `copy_selection` features differ only in a guard (`has_selection`, plus `not is_masked` in the text box). With Finding 1's helper they shrink to a guard and one call.
**Evidence:** src/sw_text_selection.e:177-185; src/sw_text_box.e:400-410; src/sw_chat_thread.e:855-866; src/sw_spreadsheet.e:365-373
**Suggested Action:** Fold into Finding 1's extraction.
**Effort:** 3 features simplified

### Finding 7: Dock zone and host reach-through, repeated literal
**Priority:** LOW
**Category:** A1/T1
**Classes:** SW_DOCK_ZONE, SW_DOCK_HOST
**Description:** SW_DOCK_ZONE repeats `host.panels.i_th (n)` and `host.panels.i_th (host.maximized_panel).zone` many times (for example src/sw_dock_zone.e:172, :279, :316-325, :475). A host query such as `panel_title (i)` or `is_panel_in_zone (i, z)` would shorten those and keep `panels` private. The folded strip draws its titles in two parallel branches (src/sw_dock_zone.e:845-860); the second differs only by `push_rotation`. The marker-dot radius 3.5 appears in both branches (:848 area and :858 area) and belongs in one named constant. Cosmetic.
**Effort:** 2 features

### Finding 8: Contract gaps around the new menu features
**Priority:** MEDIUM
**Category:** contracts (A4)
**Classes:** SW_WIDGET, SW_WINDOW, SW_TREE, SW_DOCK_ZONE
**Description:**
- `offered_menu` promises non-empty only when an extension exists (src/sw_widget.e:704). Without an extension it returns `context_menu`'s result as is (:705-706 region, the `else` branch), so any widget that returns an empty non-Void menu reaches `show_popup` (src/sw_window.e:2337-2350) unguarded. Either add a root `ensure` on `context_menu` (Void or non-empty) or normalize the empty case in both branches of `offered_menu`.
- SW_TREE.context_menu has `ensure then offered` but no postcondition tying `context_row` to 0..visible count (src/sw_tree.e:347-379), unlike SW_PARAGRAPH_LIST's `noted` clause (src/sw_paragraph_list.e:512-514).
- SW_DATA_GRID.context_menu notes `context_model` and `context_column` (src/sw_data_grid.e:615-645); I read only to line 645 and did not locate an `ensure` clause there, so verify before acting.
- All five `copy_text` features lack a postcondition (see Finding 1).
**Suggested Action:** The `offered_menu` normalization plus a root `ensure` fixes the gap for every subclass at once.
**Effort:** 2 features

### Finding 9: `index_of_label` has no in-library caller
**Priority:** LOW
**Category:** contracts / API
**Classes:** SW_MENU (src/sw_menu.e:111-132)
**Description:** `index_of_label` is documented "for tests and for clients" and grep over src/ found only its declaration, which is acceptable as client API. `append_items` (src/sw_menu.e:85-109) requires `not_self` and ensures growth, with the label parallelism covered through `add_item`'s `parallel` postcondition. Noted for completeness; no action required.
**Effort:** none

## Not found
- Generics (G1-G4): no new candidates in the subjects; SW_TREE [G] already constrains its node type and the new code adds no ANY-typed collections.
- `push_rotation` (src/sw_painter.e:427-433) and `vanish` (src/sw_widget.e:73-88) each have one definition in src/; no duplicated bodies.
- Other 0.46.0 touches (src/sw_document_view.e one-line undefine, src/sw_parallel_text.e `set_item_noun ("verse")`, src/sw_window.e switch to `offered_menu`) raise no finding.

## Recommended Order

1. Finding 2 (live drift: the two floors disagree) - verify and fix before any refactor.
2. Finding 1 with Findings 6 and 4 - one mixin carrying `copy_to_clipboard` and `add_copy_item`; removes five private copies and simplifies five more sites.
3. Finding 8 - one `offered_menu` normalization and a root ensure; cheap and covers every widget.
4. Finding 3 - use `has_key` and `forget_key` for the floating list.
5. Findings 5, 7, 9 - only if the files keep growing.
