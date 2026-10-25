# Design Scan (diff mode): simple_widgets since f8df023
# Date: 2026-10-25   Read-only; nothing compiled or run; findings are proposals.
# Subjects (git diff --name-only f8df023..HEAD -- src): sw_interlinear.e (new), sw_interlinear_token.e (new),
#   sw_doc_units.e, sw_doc_unit.e, sw_document_view.e, sw_parallel_text.e, sw_stacked_items.e,
#   sw_text_pointing.e, sw_mark_painter.e, sw_paragraph_list.e.
# Compared against all of src/. Previous report: design-scan-since-9cb4b01.md.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift / token / live defect | 16 | 6 | 6 | 4 |
| MI / inherit clauses | 2 | 0 | 1 | 1 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **18** | **6** | **7** | **5** |

| # | Pri | Cat | Where |
|---|-----|-----|-------|
| 1 | HIGH | D1 (defect) | Interlinear: every point in a cell answers the SURFACE unit; lines 2-7 are unreachable |
| 2 | HIGH | D1 (defect) | Interlinear never paints the text selection, yet Ctrl+A / Ctrl+C are live |
| 3 | HIGH | D1 (defect) | Interlinear units_revision is a non-monotone sum: wipe_out can leave a stale layout |
| 4 | HIGH | D1 (defect) | Interlinear.wipe_out / flow leave hover and text selection stale (view and parallel clear them) |
| 5 | HIGH | D1 (defect) | forget_hover does not clear the LINK hover: stale span index in view and parallel |
| 6 | HIGH | A5 | Interlinear.measure re-implements measure_units; margin, key, scroll_extent, arrange copied a third time |
| 7 | MEDIUM | A5 | scroll_to_token is a 4th copy of the body just lifted to scroll_item_into_view |
| 8 | MEDIUM | A5 | Greedy flow (sw_interlinear.e:483-507) repeats SW_ROW.wrap_starts |
| 9 | MEDIUM | D1 | Mark painting guards differ: list clamps, parallel skips |
| 10 | MEDIUM | perf/D1 | units_revision walks every token and line on every is_laid_out call |
| 11 | MEDIUM | T1 | Hard-coded pixels (Q4) |
| 12 | MEDIUM | D1 | Interlinear input policy: double click selects twice; select before layout never scrolls; Up/Down |
| 13 | MEDIUM | A3 | arrange/draw skeleton identical in parallel_text and interlinear |
| 14 | MEDIUM | M4/A6 | flow is 110 lines doing three jobs |
| 15 | LOW | D1 | Verse label drawn two ways (face, ink, side) |
| 16 | LOW | defect | RTL cell wider than the flow width gets a negative left |
| 17 | LOW | A1 | Inherit clause: 3 of 7 redefines in SW_INTERLINEAR are avoidable |
| 18 | LOW | M1/A4 | token list not iterable; row/column overload on SW_DOC_UNIT; add_token command-query mix |

## Q1. The previous report's four HIGH findings

1. Title band hit-tested as content: RESOLVED. sw_stacked_items.e:75-82 `pinned_height` (default 0), :122 `stacked_item_at`
   tests `a_py >= y + pinned_height`; sw_doc_units.e:459-465 `is_on_content` the same; sw_parallel_text.e:469-473 redefines it as
   header_height. Nothing remains.
2. scroll_to_row hides the row under the band: RESOLVED. sw_stacked_items.e:129-150 `stacked_scroll_for` subtracts
   pinned_height from the top test (:138); parallel_text.e:293 goes through `scroll_item_into_view` (stacked_items.e:157-166).
   Read: row 1 gives l_top = 0, so it lands whole below the band.
3. Seven input bodies copied view/parallel: RESOLVED. sw_doc_units.e:279-363 (handle_wheel, double click, drag, release, key tail,
   char, cursor_kind, set_hover_point, set_hovered) and :271-275 wheel_line. Neither heir redefines them any more.
4. Measure tail / stack_reset / is_laid_out / laid_px: PARTLY. Lifted: doc_units.e:258-263 is_laid_out, :469-472 laid_revision and
   laid_px, :475-491 stack_reset, :493-505 measure_units. Remains: `margin` declared in three heirs (view 353, parallel 395,
   interlinear 391); the layout-key string built three times (view 372, parallel 433, interlinear 412); scroll_extent three
   variants (view 254-257, parallel 322-326, interlinear 264-267); `stack_origin_y` = margin twice (view 389, interlinear 581);
   the measure prologue (margin, place_bar, width floor, laid_px) three times; and SW_INTERLINEAR does not call measure_units at
   all (finding 6).

## Q2. Does SW_INTERLINEAR copy anything? Drift among the three SW_DOC_UNITS heirs

Not a copy of SW_PARALLEL_TEXT's cells, SW_DATA_GRID, SW_GALLERY (fixed-size thumbnails; sw_gallery.e:49-90) or the
paragraph list. The pointing, stack, scroll and shaping come from SW_DOC_UNITS; that lift worked. It copies:

- SW_ROW.wrap_starts (sw_row.e:230-258), pure greedy wrap, 4th copy of "fill until it overruns" (finding 8).
- The measure tail of view/parallel (finding 6) and the scroll-into-view body (finding 7).
- Its draw skeleton equals parallel_text.e:337-348 minus the band (finding 13).

Drift between the three heirs (all HIGH, findings 1, 2, 4, 5):

| Behaviour | DOCUMENT_VIEW | PARALLEL_TEXT | INTERLINEAR |
|---|---|---|---|
| Selection wash | doc_view.e:686 paint_unit_selection | parallel_text.e:583 | NEVER (draw_stacked_item 625-664) |
| Clear hover on content change | set_document :135 | wipe_out :258 | wipe_out :125-134 does not |
| Clear text selection on content change | :138 | :257 | not cleared (only token) |
| Hit unit | the block's one text | the cell whose box holds the point | the first unit of the cell (always the surface) |
| Marks | none | under/over (guarded) | none |

### Finding 1. HIGH D1 (live defect) - pointing reaches only the surface line
- sw_interlinear.e:526 gives EVERY line unit of a word the SAME box: `cu.set_box (token_lefts.i_th (k), 0.0, token_widths.i_th (k), row_heights.i_th (r))`.
- sw_doc_units.e:237-248 `pointed_unit` returns the first unit whose box holds the point (`until ... or Result > 0`), i.e. the word's
  first unit, the surface line (Line_surface = 1, interlinear_token.e:41, is always shown, interlinear.e:458).
- Input -> result: pointer on the gloss line of word 3 (y inside that cell, below the surface line). pointed_unit = the surface unit;
  `character_at` (sw_text_pointing.e:123-124) asks that unit's geometry for a point below its content_height ->
  sw_text_geometry.e:435 returns 0. So hover_item = 0, no on_hover, no hover card (sw_text_pointing.e:274-282 needs ch > 0), arrow
  cursor. The header (interlinear.e:20-22) promises "a rest on a word opens the card"; it opens only over the surface glyphs.
  Lines 2-7 are never a unit under the pointer, so `unit_row` (the line) can never reach a host.
- `token_at` and click still work (they use unit_column), which hides the defect from a click test.
- Fix: give each line unit its OWN box (cell x and width, y = l_dy, height = that line's content_height), and draw the wash from
  `token_box` arithmetic (token_lefts/token_widths/row_heights) instead of `l_unit.box_*` (lines 646-648). 2 edits in flow, 1 in draw.

### Finding 2. HIGH D1 (live defect) - selection is real but invisible
- sw_interlinear.e:625-664 never calls `paint_unit_selection` (parallel_text.e:583, document_view.e:686 do).
- handle_char (339-367) hands Ctrl+A and Escape to SW_DOC_UNITS (comment at 340-341 advertises them): sw_text_selection.e:231-235
  `select_all` selects every unit; nothing paints it.
- Input -> result: Ctrl+A shows nothing; Ctrl+C then copies every visible line of every word (sw_text_selection.e:177-186)
  though the user sees no selection. With a word selected (selected_token > 0) the same Ctrl+C copies only that word (line 347),
  so the identical keystroke does two different things depending on an invisible state. Escape clears the text selection but not
  `selected_token`.
- Fix options: (a) drop the inherited Ctrl+A/Escape (handle_char answers only Ctrl+C and Escape-clears-token), or (b) paint the
  wash. (a) is right: words are picked, not typed (header 3-6). Either way one contract.

### Finding 3. HIGH D1 (live defect) - units_revision can repeat after wipe_out
- sw_interlinear.e:375-386 `content_revision` = structure_revision + sum of every token's revision; :125-134 `wipe_out` adds 1 to
  structure but removes the tokens' revisions from the sum. The value is not monotone.
- Layout runs only when `laid_revision /= units_revision` (interlinear.e:413). Input -> result: verse A is shown (structure s,
  tokens' sum S). wipe_out (s + 1, sum 0); verse B is added: add_token x N (+N) and its lines set. If S_B + N + 1 = S_A the
  value equals the laid one, `laid_key` is unchanged (same width), `block_units.count = row_heights.count` still holds -> no
  flow: the old rows, token_rows and units stay, `token_rows.count /= tokens.count`, and draw_stacked_item reads
  `tokens.i_th (l_last_token)` for an old unit past the new count (precondition violation) or paints verse A's words.
  Rare but a plain contract hole; SW_PARALLEL_TEXT uses a monotone `rows_revision` (parallel_text.e:384) and per-row revisions.
- Fix: keep a `revision_floor` that wipe_out raises by the removed sum (or count flows and compare `flow_stamp`); same cure removes
  finding 10's cost.

### Finding 4. HIGH D1 (live defect) - stale hover and selection after wipe_out / set_line_visible / set_right_to_left
- sw_interlinear.e:125-134 `wipe_out`: no `forget_hover`, no `clear_selection` (parallel_text.e:257-258 does both;
  document_view.e:135-138 does both). `hover_item` keeps a unit number of the dead verse; `anchor_item/caret_item` survive when
  the new verse has at least as many units (number_units only clears when beyond the count, doc_units.e:559-561).
- set_line_visible (145-156), set_right_to_left (161-167), set_surface_scale: `flow` creates NEW units each time
  (interlinear.e:459, line_unit 565), renumbering them; hover_item and the text selection still hold old unit numbers. Input -> result:
  hover a word, hide the gloss line: hover_item now names another word's unit until the pointer moves; Ctrl+A, hide a line,
  Ctrl+C copies the new unit set.
- Fix: `wipe_out` calls forget_hover and clear_selection; `flow` ends with the same two (a layout that renumbers units must not
  keep unit numbers). One line each, or once in a shared `units_renumbered` hook in SW_DOC_UNITS.number_units.

### Finding 5. HIGH D1 (live defect, view and parallel) - forget_hover leaves the link hover
- sw_text_pointing.e:239-246 `forget_hover` = hover_to (0, 0). SW_DOC_UNITS keeps `hovered_link_unit/span` (doc_units.e:526) and
  clears them only in `update_link_hover` (628-649), which `forget_hover` never calls (set_hovered and set_hover_point do,
  :351-363).
- `hovered_link` (124-132) guards the unit (`<= units.count`) but not the span: `span_target (hovered_link_span)`.
- Input -> result: pointer over a link (span 3 of unit 5) in document A; host calls `set_document (B)` (view :134-142) or
  `wipe_out` (parallel :251-261). hovered_link now reads unit 5 of B with span 3; if that text has fewer spans, span_target's
  precondition fails; if it has one, paint_run (:603) draws a heavy underline and on_link_hover consumers see a link that is not
  under the pointer. This is the "partly" left of previous finding 6.
- Fix: SW_DOC_UNITS redefines `forget_hover` (Precursor, then update_link_hover; hover_item = 0 clears the link and tells the
  host). Then findings 4 and 5 share one call.

### Finding 6. HIGH A5 - the third copy of the measure tail
- interlinear.e:405-421 repeats what `measure_units` does (doc_units.e:493-505): invalidate when `laid_revision /= units_revision` or
  `block_units.count /= stack_count`, then `measure_stack`; plus the same prologue (view 368-373, parallel 408-435): `margin :=
  border_width`, `place_bar`, floor on the width (32.0 / 32.0 / 64.0), `laid_px := body_pixel_size`, key `w|px|has_shaping`,
  `place_bar`.
- It needed its own `stack_reset` (597-601) only because it did not use that path: SW_DOC_UNITS.stack_reset (475-491) rebuilds
  empty lists and clears the selection; the interlinear's version neither (and so keeps stale selection, finding 4).
- Proposal (SW_DOC_UNITS): deferred `measure (a_p)` + effective `arrange` calling it; effective `layout_key (a_width, a_p)`
  (the key string); `margin` attribute and default `stack_origin_y` (margin) and `scroll_extent` (content_height + stack_origin_y +
  margin; matches all three today); `flow` stays interlinear's own, followed by `measure_units`. Removes `arrange` from two
  redefine lists, `stack_reset` from the interlinear's. About 5 features, three users, one contract.

## Medium and low findings

### 7. MEDIUM A5 - scroll_to_token
sw_interlinear.e:227-235 is the body lifted into `scroll_item_into_view` (stacked_items.e:157-166), called with a longer
guard. Replace by `scroll_item_into_view (token_rows.i_th (a_token))` under `a_token <= token_rows.count`.

### 8. MEDIUM A5 - greedy wrap
interlinear.e:483-507 equals sw_row.e:230-258 `wrap_starts` (fill until `run + gap + w > avail`; an overlong item takes its own
row), with right-to-left placement added. Two users now (SW_ROW, SW_INTERLINEAR; SW_GALLERY columns_now is fixed-cell and
different). Propose a small pure helper class or mixin `SW_WRAP_FLOW` (starts, plus `left_in_row` that mirrors for RTL). Do not
lift into SW_DOC_UNITS (SW_ROW is not an heir).

### 9. MEDIUM D1 - mark painting guard
parallel_text.e:584-591 paints under/over only when `l_marks.text_count = geometry.count`; paragraph_list.e:991-997 clamps first
and always paints; text_box.e:645,711 its own. `paint_marked` is gone (sw_mark_painter.e diff) so the old divergence finding is
closed, but three call sites still state two rules. Put "clamp then paint" in SW_MARKED_TEXT.fit_to (geometry) and call it before
all of them.

### 10. MEDIUM perf - units_revision cost
interlinear.e:375-386, 575-579: `is_laid_out` (doc_units.e:258-263) is called by pointed_unit, unit_origin_y, is_item_pointable,
first/last_visible, scroll_item_into_view - several times per pointer move and per drawn row - and each call sums 7 lines x every
token. A chapter of 400 words is ~2,800 additions per call. Cache the sum per `measure`, or count revisions (finding 3).

### 11. MEDIUM T1 - see Q4.

### 12. MEDIUM D1 - input policy
- sw_interlinear.e:310-313 double click = click: `select_token` fires `on_token_select` a second time for the same word.
  Guard `a_token /= selected_token`.
- :197-212 `select_token` before the first layout: `scroll_to_token` does nothing (is_laid_out false) and nothing retries; the
  word is selected off-screen. Remember `scroll_pending` and apply in `measure`.
- :315-337 Up/Down scroll a line, so Left/Right can leave the selected word off-screen without scrolling? No: select_token scrolls.
  But Up/Down do not move the selection by row; with three rows of words the keyboard cannot step down a row.
  Proposal only; needs Larry's decision.

### 13. MEDIUM A3 - arrange/draw skeleton
`arrange` = `measure (a_p)` (parallel 330-333, interlinear 276-279; view adds the editor) and draw = measure, begin_frame, draw_visible,
end_frame, draw_bar (view 294-302, parallel 337-348, interlinear 283-290). One effective `arrange` in SW_DOC_UNITS (finding 6)
and a `draw_content (a_p)` hook between begin_frame and end_frame would remove three redefinitions.

### 14. MEDIUM M4/A6 - flow
interlinear.e:426-536: word measuring, greedy rows, and seating in one routine of 110 lines with 6 parallel lists. Split into
`measure_words`, `place_rows` (finding 8), `seat_lines`; a small helper (SW_WRAP_FLOW) can own the row lists.

### 15. LOW D1 - verse label
parallel_text.e:568-572: Role_ui size_label regular, `ink_muted`, left only. interlinear.e:650-659: Role_ui size_chip bold,
`ink_accent`, flips for RTL. Same role (a verse number), two faces. Pick one theme face (`label_face`) and mirror in both.

### 16. LOW defect - RTL cell wider than the flow
interlinear.e:497: `flow_width - l_x - width` is negative when one word is wider than flow_width (flow_width has a 64.0 floor, :410):
the cell hangs off the left edge, its units seat at negative dx. Clamp to `max (0)` for left-to-right parity.

### 17. LOW A1 - inherit clause
SW_INTERLINEAR redefines 7 names (arrange, handle_click, handle_double_click, handle_key, handle_char, cursor_kind, stack_reset);
arrange (finding 6/13) and stack_reset (finding 6) go; handle_double_click goes if SW_DOC_UNITS has a `pick_at` hook both click
and double click call; cursor_kind can stay. Result: 3-4 names. SW_PARALLEL_TEXT: arrange goes (3 left: handle_click,
handle_release, pinned_height). Do NOT make SW_INTERLINEAR a second parent chain: single parent with a coherent contract is right.

### 18. LOW M1/A4
`tokens` (interlinear.e:371) has no new_cursor; SW_DOC_UNIT `row`/`column` now mean (line, word) here and (table row, column)
elsewhere (doc_units.e:67-81 comments say table) so `item_separator` (doc_units.e:172-183) tabs two one-line words and
newlines the rest: update the comments/contracts. `add_token` (97-105) is a command returning a value (parallel_text add_row
does the same: consistent, so LOW).

## Q3. Live defects by reading (summary table)

| Input | Wrong result | Finding |
|---|---|---|
| Hover/rest on the gloss, lemma, Strong's or morphology line | no card, arrow cursor | 1 |
| Ctrl+A, then Ctrl+C | copies everything, nothing shown | 2 |
| Show verse A, wipe_out, load B with matching revision sum | verse A's rows/units kept; draw reads past tokens | 3 |
| Hover a word, hide its gloss line | hover_item names another unit | 4 |
| set_document(B) / wipe_out with the pointer on a link | stale link span; contract failure or false heavy underline | 5 |
| Double click a word | on_token_select twice | 12 |
| Right-to-left, word wider than the view | negative left, hangs off the edge | 16 |
Checked and fine by reading: RTL arithmetic for cells that fit (right edge at flow_width - l_x, units_left = x + margin, label side
and line centring agree); left/right keys mirror correctly (interlinear.e:322-326); lines hidden or empty have no unit (cannot
be hit); pinned band hit test and scroll (Q1); selection_in_range invariant after wipe_out.

## Q4. Hard-coded pixels that should be theme tokens

SW_INTERLINEAR: 410 `.max (64.0)` flow floor (token `min_text_width`; view uses 32.0, parallel 32.0/16.0: three floors for one role);
484 `flow_width + 1.0` sentinel (use a Boolean "row open"); 567 `100_000.0` no-wrap sentinel (view 523 uses 1_000_000.0: pick one
named constant); 648 `+ 0.5`, `- 1.0` selection stroke inset (= border_width; same six copies as before); 408 `padding / 2.0`
(parallel 409, view 462, 508, 563: token `cell_inset_y`/`padding_half`); 66 `surface_scale := 1.5` default: policy, but 1.5 body-to-
heading ratios live in view 577-591 (1.6/1.3/1.12): one `theme.heading_scale`.
SW_DOC_UNITS: 274 `laid_px.max (8) * 1.5` (theme.line_height exists, sw_theme.e:134); 597 `0.8 * run.height`, 602-603 `2.0 * s`, 608
`0.3 * run.height`: underline/strike metrics -> `underline_offset`, `underline_width`, `strike_offset`.
SW_STACKED_ITEMS 251: `x + 1.0, y + 1.0, width - 2.0, height - 2.0` (push_frame_clip with border_width).
SW_PARALLEL_TEXT: 342, 614, 629 (`+ 1.0`, `- 2.0`, `- 0.5`), 565 `.floor - 0.5` rule, 526 `l_gap / 2.0`, 415 `32.0`, 421/428 `16.0`
(unchanged since the last report).
Not hard-coded: all text sizes (size_body, size_label, size_chip), colours (wash_accent, accent, ink_accent, ink_muted, divider),
radius, padding, border_width in the interlinear are from the theme.

## Q5. Still-open earlier items (one line each)

- Prev 6 hover on content change: PARTLY (forget_hover exists, text_pointing.e:239; interlinear and link state missing: findings 4, 5).
- Prev 5 paint_marked: RESOLVED by removal; guard drift remains (finding 9).
- Prev 7 scroll bodies: RESOLVED in stacked_items.e:157; interlinear is a fourth copy (finding 7).
- Prev 9 measure_block/measure_table monolith: OPEN, document_view.e:421-575 and 489-575; still one user.
- Prev 10 title band drawn a third way: OPEN, parallel_text.e:605-630 vs data_grid/tree_table; interlinear adds no band.
- Prev 11 scrollbar full height beside the band: OPEN, sw_vscrolling.e:94-95 (place_bar ignores pinned_height).
- Prev 12 SW_DOC_UNITS size: now 692 lines, three heirs; keep unsplit.
- Prev 13 five identical undefine lists: OPEN (doc_units.e:44-46, stacked_pointing.e:26-27/32-33, view 69-72, list).
- Joiner SW_SCROLLING_EDITOR (view 62-75, list): OPEN.
- Wheel_line: RESOLVED for the heirs (doc_units.e:271-275); list stores 20.0 / measure_px * 1.5 (paragraph_list.e:124, 1189): OPEN.
- By-hand inset math: OPEN, document_view.e:744-745 (`cy := a_py - y - margin + scroll_y`, `stack.item_at`).
- Rounded body size three times: OPEN, stacked_items.e:172, text_box.e:1118 (+ 616 unrounded).
- Redundant clamps (list 915/936), modifier reads (view 325, 733; list 1035), sentinels: OPEN.
- Text width beside the bar (`2.0 * border_width` vs `padding / 2`): OPEN, now with interlinear's third floor (410).

## Recommended order
1. Findings 1, 2, 3, 4, 5 (live defects; 1 and 2 are interlinear-local, 5 is one SW_DOC_UNITS redefine that also covers 4).
2. Finding 6 with 13 and 17 (one SW_DOC_UNITS pass: measure/arrange/margin/key/extent; interlinear uses measure_units; drop its stack_reset).
3. Findings 7, 9, 10, 12; then 8 and 14 together (SW_WRAP_FLOW with SW_ROW as the second user).
4. Tokens (Q4) as one SW_THEME pass.
