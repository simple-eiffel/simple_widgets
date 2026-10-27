# Design Scan (diff mode): simple_widgets since 40e47ba
# Date: 2026-10-27
# Subjects (git diff --name-only 40e47ba..HEAD -- src): sw_column.e, sw_row.e, sw_toolbar.e, sw_parallel_text.e, sw_window.e
# Compared against: all 156 files in src/. Read-only; nothing compiled.
# Note: SW_TEXT_BOX selects_all_on_focus (0.43.0) is NOT in this diff (it landed before 40e47ba); it was inspected as the reference for finding 6.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A/D/T) | 6 | 2 | 2 | 2 |
| MI | 1 | 0 | 1 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **7** | **2** | **3** | **2** |

(Finding 3 is the MI finding; the Abstraction row counts findings 1, 2, 4, 5, 6, 7 with finding 5 as MEDIUM, 6 and 7 as LOW.)

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | A1/A5 | SW_ROW, SW_COLUMN | `remove` is a copy; belongs in a shared container ancestor |
| 2 | HIGH | latent defect (same as 0.44.1) | SW_MENU_BAR, SW_MEDIA_TRANSPORT, fill widgets | No `preferred_width`: zero width in a non-growing row, swallows clicks |
| 3 | MEDIUM | M2 | SW_ROW, SW_COLUMN, SW_TOOLBAR, SW_MENU_BAR | Deferred ancestors side by side: a box-container role and a measured-strip role |
| 4 | MEDIUM | D1-risk / T1 | SW_TOOLBAR | Item width formula and literals copied three times |
| 5 | MEDIUM | M2 | SW_TABS, SW_ACCORDION, SW_DOCK_ZONE, SW_STATUS_BAR | Other child-owning containers have ad hoc child lists with no remove protocol |
| 6 | LOW | consistency | SW_IN_PLACE_EDITING | Select-all-on-focus coverage: no gap; one stale contract comment |
| 7 | LOW | CQS | SW_TOOLBAR | `preferred_width` query has a side effect |

## Detailed Findings

### Finding 1: `remove` duplicated between SW_ROW and SW_COLUMN
**Priority:** HIGH (duplicate code across classes; A1: same signature, same contract, same body, so an EFFECTIVE ancestor candidate)
**Evidence:**
- src/sw_row.e:91-104 `remove (a_w: SW_WIDGET)`: require `a_child: children.has (a_w)`; body `children.prune_all (a_w)` then `if a_w.parent = Current then a_w.set_parent (Void) end`; ensure `gone`, `orphaned`.
- src/sw_column.e:65-78: identical text, including the identical header comment.
- Both also repeat `children: ARRAYED_LIST [SW_WIDGET]` (sw_row.e:33, sw_column.e:34), `create children.make (8)` (sw_row.e:25, sw_column.e:25), `put` (sw_row.e:106-111, sw_column.e:80-85), the gap group (`gap`, `gap_is_explicit`, `with_gap`, `set_gap`) and the `children_attached` invariant (sw_row.e:431).
- Other child-list classes with no `remove`: src/sw_tabs.e:76 (`pages`), src/sw_accordion.e:138, src/sw_dock_zone.e:143, src/sw_status_bar.e:302. Other `remove` features (sw_query_group.e:91, sw_mark_legend.e:160, sw_marked_text.e:272, sw_paragraph_list.e:559) are on non-widgets and unrelated.
**Description:** Yes, `remove` should live once in a shared ancestor. Proposal: a class SW_BOX_CONTAINER that owns `children`, `put`, `remove`, the gap group and the invariant, inherited by SW_ROW and SW_COLUMN side by side with SW_WIDGET (or inheriting SW_WIDGET once itself). SW_COLUMN adds padding; SW_ROW adds wrapping and cross axis. The orphan-on-remove contract then has one home, and a third container gets it free.
**Suggested Action:** /eiffel.abstract targeting SW_ROW, SW_COLUMN, then /eiffel.mi for the side-by-side form.
**Effort:** 1 feature now (`remove`); about 6 with `children`, `put`, and the gap group.

### Finding 2: SW_MENU_BAR and other widgets repeat the 0.44.1 zero-width bug
**Priority:** HIGH (the same latent defect SW_TOOLBAR had)
**Evidence:**
- Base default: src/sw_widget.e:159-165 `preferred_width` returns 0.0 ("give me what you have").
- SW_ROW honors it literally unless the child grows: src/sw_row.e:366 (`widths.extend (c.clamped_width (c.preferred_width (a_p)))`), :380-384 (extra width only when `children.i_th (i).grow > 0.0`), :391 (`set_bounds (cx, y, cw, ch)`); the wrapping path uses the same measure at :202 and :303. `clamped_width` only raises to `min_width` (sw_widget.e:136-145), which is 0 by default.
- Click-taking or hover widgets deriving from SW_WIDGET with NO `preferred_width` in the file: SW_MENU_BAR (labels are measured inside `draw`; fixed `preferred_height` 36.0 at sw_menu_bar.e:300-302), SW_MEDIA_TRANSPORT (preferred_height at sw_media_transport.e:136), SW_SLIDER (sw_slider.e:96), SW_TABS (sw_tabs.e:490), SW_STATUS_BAR (sw_status_bar.e:146), SW_CAROUSEL (sw_carousel.e:107), SW_EMPTY_STATE (sw_empty_state.e:71), SW_ACCORDION (sw_accordion.e:155), SW_GALLERY (sw_gallery.e:110), SW_CROP_BOX (sw_crop_box.e:82), SW_WAVEFORM (sw_waveform.e:355), SW_DROPZONE (sw_dropzone.e:69), SW_PROGRESS (sw_progress.e:67), SW_SKELETON (sw_skeleton.e:71), SW_CHART (sw_chart.e:75).
- Contrast, widgets that do measure: SW_BUTTON (sw_button.e:128), SW_CHECK_BOX (:82), SW_SWITCH (:70), SW_SEGMENTED (:133), SW_STEPPER (:122), SW_RADIO_GROUP (:119), SW_RATING (:111), SW_COMBO (:77), SW_NUMBER_BOX (:136), SW_TEXT_BOX (:803, a 240 default presence), SW_SPARKLINE (:118).
**Description:** In a non-growing row each of these gets width 0 and, being zero wide, takes no clicks (the 0.44.1 symptom). Two cases:
1. Natural-width controls with measurable content: SW_MENU_BAR is the true twin of SW_TOOLBAR (a strip of drawn labels) and should get `preferred_width` (sum of label advances plus insets). SW_MEDIA_TRANSPORT (buttons and readouts) is next.
2. Fill widgets (SLIDER, PROGRESS, WAVEFORM, TABS, STATUS_BAR, CAROUSEL, GALLERY, CROP_BOX, CHART, SKELETON, DROPZONE, EMPTY_STATE, ACCORDION): zero is correct only when the host sets `grow` or `min_width`. Either give each a documented default presence (as SW_TEXT_BOX does, sw_text_box.e:803-806), or add one rule in the shared layer: SW_ROW.put warns or requires that a child with zero preferred width has grow or min_width set.
**Suggested Action:** MENU_BAR and MEDIA_TRANSPORT: add `preferred_width`. For the fill group Larry chooses between default presence per class and a row-level contract.
**Effort:** 2 features now; 13 classes for the policy decision.

### Finding 3: Role-based ancestors for containers and measured strips (MI)
**Priority:** MEDIUM
**Evidence:** sw_row.e:11-12 and sw_column.e:10-11 inherit only SW_WIDGET; findings 1 and 4 are the two shared roles.
**Description:** Two roles inherited side by side with SW_WIDGET: (a) SW_BOX_CONTAINER (children, put, remove, gap) from finding 1; (b) a measured-strip role (a run of drawn items with gaps and per-item widths) used by SW_TOOLBAR and SW_MENU_BAR so `preferred_width`, `draw` and hit-test cannot disagree. Conflicts: none expected; `children` versus `sub_widgets` (sw_widget.e:486) already maps through the `sub_widgets` redefinitions (sw_row.e:14, :167).
**Suggested Action:** /eiffel.mi after Larry approves finding 1.
**Effort:** about 6 features for (a), about 5 for (b).

### Finding 4: Toolbar item geometry copied three times, with bare literals
**Priority:** MEDIUM (drift risk now; becomes D1 and HIGH the first time one copy changes)
**Evidence:**
- src/sw_toolbar.e:107-116 (`preferred_width`): start 12.0, gap 13.0, glyph 28.0 + 3.0, label `advance + 22.0 + 3.0`.
- src/sw_toolbar.e:140-182 (`draw`): start `x + 6.0` (:140), gap 13.0 (:151), glyph 28.0 (:154), label `+ 22.0` (:156), step `tw + 3.0` (:182).
- src/sw_toolbar.e:200-224 (`handle_click`): gap 13.0 (:207), glyph 28.0 (:210), label `+ 22.0` (:212), step `tw + 3.0` (:223).
- Height 34.0 at :124 and the 5.0 and 7.0 insets in `draw`.
**Description:** The same item-width formula lives in three features; the 0.44.1 fix typed it a third time (and its 12.0 start is twice the 6.0 draw inset, assuming a symmetric margin). Extract `item_width (a_p, a_item)` plus named constants, so draw, hit-test and preferred_width call one source. Token view (T1): 13, 28, 22 and 3 belong in SW_THEME (for example toolbar item padding and gap), and they must scale with the theme scale, since label width already does.
**Suggested Action:** /eiffel.abstract (helper inside the finding 3(b) ancestor).
**Effort:** 1 feature plus 4 constants.

### Finding 5: Other child-owning containers have no shared re-parenting protocol
**Priority:** MEDIUM
**Evidence:** `pages` (sw_tabs.e:76), accordion sections (sw_accordion.e:138), dock zone children (sw_dock_zone.e:143), status bar sections (sw_status_bar.e:302). `remove` was added so simple_bible can move panes between containers (comment at sw_row.e:91-93); SW_TABS and SW_DOCK_ZONE also hold panes but cannot give them up.
**Description:** Not a defect today. Design the finding 1 ancestor so `remove` is not tied to the name `children`, in case layouts also move panes through tabs or dock zones.
**Suggested Action:** none yet; decide when a consumer needs it.

### Finding 6: Select-all-on-focus coverage
**Priority:** LOW (no defect found)
**Evidence:**
- Policy lives in SW_TEXT_BOX: `selects_all_on_focus` (sw_text_box.e:307-313, single-line default), `set_focused` (:325-331), `handle_click` keeps the selection for the focusing click (:837-845).
- Covered by inheritance: SW_COMBO (sw_combo.e:13), SW_DATE_PICKER (sw_date_picker.e:15), SW_TIME_PICKER (sw_time_picker.e:13) inherit SW_TEXT_BOX; none overrides `set_focused` (grep: only sw_text_box.e and sw_widget.e:238 define it). Field consumers create SW_TEXT_BOX (sw_form_generator.e:99, sw_file_dialog.e:320, sw_query_builder.e:352).
- In-place editors: sw_in_place_editing.e:131-139 `open_editor` calls `set_caret (l_ed.text.count)` then `set_focused (True)`; for a single-line box focus now selects everything (sw_text_box.e:327-329), so the comment at :121-122 and postcondition `caret_at_the_end` (:145) now describe an end caret with all text selected. That matches Larry's rule; the wording is stale.
- SW_NUMBER_BOX (sw_number_box.e:44-95) is editable but not a text box: it types into `edit_buffer`, commits on Enter, and a first digit starts a fresh buffer, so typing already replaces the value. No change needed.
**Description:** No editable single-line widget misses the rule. Only the in-place editor wording needs a refresh.
**Effort:** comment only.

### Finding 7: `preferred_width` mutates state
**Priority:** LOW
**Evidence:** src/sw_toolbar.e:117-119 assigns `probe_painter := a_p` inside the query; `handle_click` depends on it (sw_toolbar.e:197; other assignment at :136 in `draw`).
**Description:** A measuring query that stores the painter is a hidden command (command-query separation). Idempotent and harmless, but click correctness then depends on call order. Check whether SW_MENU_BAR uses the same pattern when extracting finding 3(b).
**Effort:** 1 feature.

## Checked and found clean
- SW_PARALLEL_TEXT.set_column_title (sw_parallel_text.e:130-139): bumps `rows_revision`, as a setter should; `set_column_title` appears in no other class.
- SW_WINDOW.clear_reference_marks (sw_window.e:3029-3038): resets `reference_marks`, `mark_rects` and `hovered_reference_mark`; the parallel postcondition holds; `reference_marks` is used only in sw_window.e.
- Drift (D1) between the row and column copies of `remove`: none today (identical); the risk is future divergence.
- Generics: no findings in the subjects.

## Recommended Order
1. Finding 2 (menu bar and transport `preferred_width`): a live defect class, smallest fix.
2. Findings 1 and 3(a): extract the container ancestor so a third copy never exists.
3. Finding 4 with 3(b): one item-width source for toolbar and menu bar.
4. Findings 6 wording, 7, 5 as convenience.
