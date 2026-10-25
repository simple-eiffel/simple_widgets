# Design Scan (diff mode): simple_widgets since 9cb4b01
# Date: 2026-10-25   Read-only; nothing compiled or run; findings are proposals.
# Subjects (git diff --name-only 9cb4b01..HEAD -- src): sw_parallel_text.e (new), sw_doc_units.e (new),
#   sw_stacked_pointing.e (new), sw_mark_host.e (new), sw_parallel_row.e (new), sw_doc_unit.e,
#   sw_document_view.e, sw_paragraph_list.e, sw_text_box.e, sw_mark_painter.e, sw_text_geometry.e.
# Compared against all of src/. Earlier reports: design-scan-since-8125771.md, design-scan-since-a808837.md.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift / token | 11 | 4 | 4 | 3 |
| MI / inherit clauses | 2 | 0 | 1 | 1 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **13** | **4** | **5** | **4** |

| # | Pri | Cat | Where |
|---|-----|-----|-------|
| 1 | HIGH | D1 (defect) | Title band hit-testing: rows scrolled under the band answer the pointer |
| 2 | HIGH | D1 (defect) | scroll_to_row hides the row's top under the title band (row 1 included) |
| 3 | HIGH | A5 | Seven handle_*/hover/key bodies identical in DOCUMENT_VIEW and PARALLEL_TEXT |
| 4 | HIGH | A5 | Measure tail, stack_reset, is_laid_out, laid_px, margin: second copy in PARALLEL_TEXT |
| 5 | MEDIUM | A5/D1 | PARAGRAPH_LIST paints marks by hand; paint_marked exists and clamps differently |
| 6 | MEDIUM | D1 | Hover not cleared on content change: now 2 of 3 users leave it stale |
| 7 | MEDIUM | A5 | scroll_to_item / scroll_to_block / scroll_to_row: three copies of one body |
| 8 | MEDIUM | T1 | Hard-coded pixel values in the subjects (list under Q3) |
| 9 | MEDIUM | M4/A6 | Remaining view monolith: measure_block / measure_table |
| 10 | LOW | A5 | Title band + rule drawn a third way (data_grid, tree_table, parallel_text) |
| 11 | LOW | D1 | Scrollbar runs the full height beside the title band |
| 12 | LOW | M4 | SW_DOC_UNITS is 540 lines / ~45 features (do NOT split: two users) |
| 13 | LOW | A1 | Undefine lists repeated five times (Eiffel cannot share one) |

## Q1. Is SW_PARALLEL_TEXT a copy of anything?

Not of SW_DATA_GRID, SW_TREE_TABLE or SW_PARAGRAPH_LIST: its columns, weights, scales, row model (SW_PARALLEL_ROW) and
measure_item (sw_parallel_text.e:590-633) exist nowhere else. The lift worked: the pointing, link, selection, unit and
paint_run code is NOT copied (it is in sw_doc_units.e). What remains is a copy of SW_DOCUMENT_VIEW's input and layout
glue, line for line: findings 3 and 4. The title band is a third drawing of "band + bold labels + rule" (finding 10), not
a copy of either grid (they use fixed Header_h and 8.0/10.0 offsets; this one measures the font).

## Q2. Remaining duplication (DOCUMENT_VIEW | PARALLEL_TEXT | PARAGRAPH_LIST)

### Finding 1. HIGH D1 - the title band is hit-tested as content (defect)
- sw_doc_units.e:347-351 `is_on_content` = contains and not bar.contains. SW_PARALLEL_TEXT does not override it.
- sw_stacked_items.e:109-115 `stacked_item_at` maps window y with `- stack_origin_y + scroll_y`; for a parallel text the
  origin is header_height (sw_parallel_text.e:556-560).
- Rows are drawn under the band and covered (sw_parallel_text.e:361-372; first_visible takes `scroll_y - stack_origin_y`,
  sw_stacked_items.e:79). A point on the band, with the view scrolled, lands in content coordinates BELOW `scroll_y`, so
  it names a row that is hidden under the band: pointed_unit (sw_doc_units.e:216-251) returns one of its cells, and then
  press starts a selection in hidden text (unit_press 255-272), the I-beam / hand shows (unit_cursor_kind 325-333),
  hover cards and `on_cell_click` (parallel_text 410-424) fire for text the reader cannot see.
- Fix: `is_on_content` effective in SW_PARALLEL_TEXT: inherited test and `a_py >= y + header_height`. 1 feature.
  (Or a deferred-with-default `stack_pinned_height` in SW_STACKED_ITEMS used by stacked_item_at.)

### Finding 2. HIGH D1 - scroll_to_row leaves the row under the band (defect)
- sw_parallel_text.e:290-298 calls `scroll_to (stacked_scroll_for (a_row))`. sw_stacked_items.e:120-139 treats the viewport
  as [scroll_y, scroll_y + height] and sets `Result := l_top` = `stack_origin_y + stack.top (a_i)`.
- Row top then stands at window y + header_height + top - scroll = y: header_height pixels of the row sit under the band.
  For row 1 the answer is `header_height`, not 0, so scroll_to_row (1) scrolls the first verse partly under the titles.
- The view's origin is `margin` (a few pixels), so the same formula is nearly harmless there; the band makes it a bug.
- Fix: stacked_scroll_for subtracts a `stack_pinned_height` (default 0, header_height here) from the top test, and
  shrinks `height` by it for the bottom test. 1 deferred-with-default feature + 2 lines.

### Finding 3. HIGH A5 - input glue copied between the view and the parallel text
Identical bodies (view line | parallel line):
- handle_wheel 324-333 | 376-384 (wheel_scrolled, follow_hover, update_link_hover).
- handle_double_click 349-353 | 398-401; handle_drag 355-362 | 403-408 (drag_bar else unit_drag).
- set_hover_point 407-412 | 451-455 and set_hovered 414-419 | 457-461 (Precursor, then update_link_hover).
- handle_key tail 388-396 | 434-443 (scroll_key, else Up 40 / Down 38 by wheel_line).
- cursor_kind 278-288 | 347-352 (bar test, then unit_cursor_kind; the view adds the editor branch).
- handle_char 399-405 | 445-449 (selection_char).
- wheel_line 270-274 | 339-343 (`(laid_px * 1.5).max (1.0)`), laid_px attribute 438 | 483, `laid_px := 14` 91 | 68.
The list differs only where it is not a text-pointing widget (no link hover; stored wheel_line, list 1146 / 1191).
Proposal: SW_DOC_UNITS (which already owns update_link_hover) redefines and states once: handle_wheel, handle_double_click,
handle_drag, set_hover_point, set_hovered, `handle_key` scroll part (a `scroll_lines_key (a_vk): BOOLEAN` helper),
`wheel_line` (from a `laid_px` it owns) and `cursor_kind` (editor_cursor hook, default False). Effort: about 8 features;
both heirs' redefine lists shrink from 11 names to 4-5 (arrange, handle_click, handle_release, handle_char, handle_key).
The view keeps its own redefinitions only where SW_IN_PLACE_EDITING joins in (it already redefines those names).

### Finding 4. HIGH A5 - the measure tail and the layout bookkeeping
- measure: view 444-465 vs parallel 486-531: both do `margin := border_width`, `place_bar`, text width with the same
  `2.0 * margin` and a `.max (32.0)` floor, `laid_px := body_pixel_size`, key `w|px|has_shaping`, invalidate on a stale
  revision or `block_units.count /= count`, `measure_stack`, `number_units`, `place_bar`.
- stack_reset: view 489-505 vs parallel 572-588: identical except the count and the revision it stores.
- is_laid_out: view 103-108 vs parallel 324-329: `laid_X_revision = X.revision and stack.count = N and block_units.count = N`.
- stack_count 467-470 | 551-554, is_volatile, `margin` attribute 432 | 482.
Proposal (SW_DOC_UNITS): `laid_revision`, deferred `source_revision`, effective `is_laid_out`, effective `stack_reset`
(over `stack_count`), and `measure_units (a_p, a_width, a_gap)` doing the shared tail. The heirs keep `measure_item`,
`stack_count`, `stack_origin_y`, `units_left`, `unit_ink`. Effort: about 6 features. Two users, one coherent contract
("a stack whose items are lists of SW_DOC_UNITs").

### Finding 5. MEDIUM A5/D1 - the list paints marks by hand
sw_paragraph_list.e:992-999 is the body of the new SW_MARK_PAINTER.paint_marked (sw_mark_painter.e, added in this diff;
only SW_PARALLEL_TEXT calls it, parallel_text.e:684). Divergence: the list CLAMPS a stale mark set to the geometry
(992-994) and paints under/text/over; paint_marked draws only the text when `marks.text_count /= geo.count`. SW_PARALLEL_ROW
.cell_marks clamps itself (sw_parallel_row.e:80-86), so the two stay equal today, but a third caller gets the weaker
rule. Proposal: the list calls paint_marked (clamp stays one line before it). paint_marked then has two users (list,
parallel_text); text_box (645, 711) paints between the washes with the caret and stays apart. Effort: 1 call site.

### Finding 6. MEDIUM D1 - hover survives a content change (previous finding 7, wider now)
- Clears: sw_paragraph_list.e:666-667 (wipe_out).
- Stale: SW_PARALLEL_TEXT.wipe_out (254-263: rows, revision, scroll, selection; hover_item, hovered_link_unit and
  hovered_link_span stay) and SW_DOCUMENT_VIEW.set_document (137-151).
- update_link_hover (sw_doc_units.e:476-497) range-guards the link; hover_card_at is not guarded. Fix once:
  `forget_hover` in SW_TEXT_POINTING (list's lines move there), called by all three. Effort: 1 effective feature.
  Rated MEDIUM because the stale index is range-guarded in the code read; the divergence itself is drift.

### Finding 7. MEDIUM A5 - three scroll-into-view bodies
list scroll_to_item 825-836, view scroll_to_block 153-161, parallel scroll_to_row 290-298: the same
`if is_laid_out and height > 0 then scroll_to (stacked_scroll_for (n))`. Lift `scroll_item_into_view (a_i)` to
SW_STACKED_ITEMS (ensure first_visible <= a_i <= last_visible when laid out); the three are one-line renamings.
Fix finding 2 in that one body. Effort: 1 feature.

### Findings 9, 10, 11, 12, 13
- 9 MEDIUM M4/A6: SW_DOCUMENT_VIEW fell from 1317 to 876 lines (credit to the lift). measure_block 522-578, measure_table
  590-676, heading_size 678-691, mirror_if_right_to_left 580-588 remain; they use only text_w, block_units, the theme.
  A helper object would leave the view with input, drawing and editing. Still one user.
- 10 LOW A5: "surface_variant band, bold Role_ui label, divider rule": parallel_text 697-722, data_grid 337-340, tree_table
  125-128. Metrics differ (measured vs fixed Header_h). A `SW_PAINTER.draw_band` is possible only with a third user
  that wants measured metrics; leave until then.
- 11 LOW D1: the scrollbar (SW_VSCROLLING.place_bar uses the whole height; sw_vscrolling.e:94-95) runs beside the title band,
  so the thumb travels over the band's height. The bar is drawn after the band (parallel_text 371), so it is visible, not
  wrong; track top could start at `y + stack_pinned_height` (same hook as finding 2).
- 12 LOW M4: see Q4.
- 13 LOW A1: see Q4.

## Q3. Hard-coded pixel values in the subjects (theme tokens)

SW_PARALLEL_TEXT (everything else here already reads `border_width`, `padding`, `size_label`, `text_scale`):
- 366 `push_clip (x + 1.0, ..., width - 2.0, ... - 1.0)`; 706 `fill_rect (x + 1.0, y + 1.0, width - 2.0, ...)`;
  721 `x + 1.0 ... width - 1.0, ... - 0.5`; 665 `.floor - 0.5` rule: frame inset and half-pixel line = `border_width`
  (SW_PAINTER.push_frame_clip; same six copies as previous N9, now seven with sw_stacked_items.e:226).
- 503 `.max (32.0)`, 509 and 516 `.max (16.0)`: minimum text/column widths (view 452, 550, 556, 563, 641, 646; list 485):
  one SW_THEME `min_text_width` (scales).
- 342 `laid_px * 1.5` (and view 273): wheel line; theme `line_height` (sw_theme.e:134) already exists. Choose one source.
- 68 `laid_px := 14` (view 91): pre-measure default ignoring the theme.
- 626 `l_gap / 2.0`, 497 `padding / 2.0` (view 563, 609, 800, 802; list 1182; sw_label 242, 325): the half-padding is
  a recurring role; token `padding_half` or `cell_inset_y`.
- 147 (contract) column scale 0.5..3.0 and Max_columns 6: policy, not pixels; fine.
SW_DOC_UNITS paint_run: 445 `0.8 * run.height` (code wash), 450-451 `2.0 * s` (link underline, hover width `2.0 * s` else `s`),
456-457 `0.3 * run.height` (strike): type metrics; SW_THEME `underline_offset`, `underline_width`, `strike_offset`.
SW_DOCUMENT_VIEW: 441 `Quote_bar = 3.0` (chat_thread 2.0 / 5.0, sw_chat_thread.e:991-994: same role, different widths:
token `quote_bar_width`); 683-687 heading 1.6 / 1.3 / 1.12 (theme `heading_scale (level)`); 548 `2.0 * border_width` indent;
610, 626, 641 `+ 1.0`, `+ 16.0` column floors; 624 `1_000_000.0` sentinel for "no wrap".
SW_PARAGRAPH_LIST: 114 `bar_gap := 4.0` unscaled default; 126-128 28 / 8 / 8; 971-973 `set_line_width (2.0)`, `+ 1.0`,
`- 2.0`; 976 `0.5`; 124 `wheel_line := 20.0`.
SW_STACKED_ITEMS 226: clip inset (above). SW_MARK_PAINTER paint_marked: none.
Same role, three values: text width beside the bar is `2.0 * border_width` (view 452, parallel 503) vs `padding / 2`
(list 1182, 485).

## Q4. Inherit-clause complexity

Current clauses: SW_PARALLEL_TEXT = SW_DOC_UNITS (redefine 11 names) + SW_MARK_HOST (no adaptation). SW_DOCUMENT_VIEW =
SW_DOC_UNITS (redefine 12 names) + SW_IN_PLACE_EDITING (undefine 6, redefine 10). SW_PARAGRAPH_LIST =
SW_STACKED_POINTING (redefine 12) + SW_IN_PLACE_EDITING (undefine 6, redefine 10) + SW_MARK_HOST. Versus the list's
five-parent clause in the earlier report (about 75 lines), this is a real simplification.

Further simplification (proposals, none done):
1. Finding 3 into SW_DOC_UNITS: PARALLEL_TEXT's redefine list drops from 11 to about 5 and the view's first parent from 12
   to about 6. Trade-off: SW_DOC_UNITS grows (about 14 features) and the heirs lose the freedom to differ silently
   (that is the point: both are the same widget with different item models).
2. Joiner SW_SCROLLING_EDITOR (SW_STACKED_POINTING + SW_IN_PLACE_EDITING, redefining the shared SW_WIDGET features once;
   previous N3). Two users (list, view). Trade-off: the view reaches SW_STACKED_POINTING twice (through SW_DOC_UNITS and the
   joiner): legal repeated inheritance with no rename, but it must be compiled to confirm the undefine lists agree.
   Still the largest remaining boilerplate (about 8 features, two 25-line clauses). Recommend it only after finding 3,
   because 3 removes most of the same names from the view's clause.
3. Five identical `undefine set_hover_point, set_hovered, dwell_ms, handle_dwell, hover_card_at, accepts_focus,
   wants_hover_point` lists (stacked_pointing 26-27 and 32-33, doc_units 42-43, view 71-72, list 89-90). Cause: SW_TEXT_POINTING
   redefines SW_WIDGET features that other mixins inherit unchanged. Eiffel cannot share a list. Removing the cause means
   making SW_TEXT_POINTING's seven names the ONLY definitions (the mixins stop inheriting SW_WIDGET for those names): a
   larger change to SW_VSCROLLING / SW_STACKED_ITEMS / SW_IN_PLACE_EDITING. Not worth it for two more users.

Ancestors that would be over-abstraction:
- SW_MARK_HOST: three features, three users (text_box, list, parallel_text), parentless, with a clean contract. Keep. It
  is the right size; do not add paint helpers to it (paint_marked lives in SW_MARK_PAINTER, a helper object).
- SW_STACKED_POINTING: contract coherent ("pointing into a scrolling stack"), owns three features, two direct users
  (list, SW_DOC_UNITS) and four widgets. Keep.
- SW_DOC_UNITS: two users, one coherent contract (items are lists of SW_DOC_UNITs). Keep. Do NOT split links out
  (finding 12): `hovered_link*`, `on_link_*`, `pressed_link`, `update_link_hover`, link press/release are about 12 features
  with exactly the same two users; a SW_LINK_HOST mixin would have one effective user (both reach it through SW_DOC_UNITS),
  and the link code reads `units` and `hover_item`.
- SW_PARALLEL_ROW and SW_DOC_UNIT: data classes, not ancestors; one user each is fine (SW_DOC_UNIT's new `alignment`,
  doc_unit.e:73-75 and 105-113, has one user today: parallel_text 619).
- Proposed SW_SCROLLING_EDITOR is the one candidate with exactly two users and a contract that would be written as
  "text pointing in a scrolling stack with an editor": coherent, acceptable.

## Q5. Status of still-open items from the earlier reports

From design-scan-since-8125771.md:
- 1 (stack skeleton): RESOLVED (SW_STACKED_ITEMS), unchanged.
- 2 (editor-hosting SW_WIDGET features): PARTLY. accepts_focus, wants_hover_point, preferred_height now RESOLVED in SW_STACKED_POINTING (56 lines); handle_release/handle_char shapes and the joiner open (list 1068-1117, view 364-405).
- 3 (pointing geometry / stale guard): RESOLVED.
- 4 (shaped-vs-toy dispatch): RESOLVED for the dispatch; call sequence open (N6: sw_doc_units.e:419-425, list 1263-1265, text_box).
- 5 (text width beside the bar): PARTLY; list scales (1182) but 4.0 default (114) and `padding/2` vs `2.0 * border_width` (view 452, parallel 503) stand.
- 6 (end_edit semantics): RESOLVED.
- 7 (hover across content change): OPEN, wider: finding 6.
- 8 (list is seven parallel lists): OPEN (list 1150-1163); no change.
- 9 (literals that want tokens): OPEN; list in Q3.
- 10 (view is a monolith): PARTLY resolved: 1317 to 876 lines; measure_block/table remain (finding 9).
- 11 (redundant clamps): OPEN: list 915 and 936.
- 12 (modifier reads): OPEN: view 381 and 834 inline, list 1036 local.
- 13 (sentinels): OPEN: view 624 and 91; parallel_text 68 copies `laid_px := 14`.
From design-scan-since-a808837.md:
- N1 (wheel_line): OPEN, now two computed copies (view 270, parallel 339) and one stored (list 1146/1191): finding 3.
- N2 (by-hand inset math): OPEN: view 845-847 (`cy := a_py - y - margin + scroll_y`, `stack.item_at (cy)`).
- N3 (joiner): OPEN, smaller (Q4).
- N4 (scroll_to_*): OPEN, now three copies (finding 7).
- N5 (list y-only item_at in click/double-click): OPEN: list 1031 and 1053.
- N6 (layout call sequence): OPEN (see 4 above).
- N7 (on_edit_commit note): RESOLVED: list note 35-41 now states the new rule.
- N8 (`size_body * text_scale` rounded three times): OPEN: sw_stacked_items.e:147, sw_text_box.e:1118 (sw_text_geometry no longer holds one).
- N9 (clip inset): OPEN, plus parallel_text 366 and 706 (Q3).

## Recommended order
1. Findings 1 and 2 (live defects in the new widget; one small override and one hook).
2. Finding 3 then 4 (push the common code into SW_DOC_UNITS; do it before GW-06 grows tests and a third heir).
3. Findings 5, 6, 7 (small, drift-removing).
4. Joiner (Q4.2) after 3; tokens (Q3) as one SW_THEME pass.
