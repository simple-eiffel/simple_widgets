# Design Scan (diff mode): simple_widgets since a808837
# Date: 2026-10-25   Read-only; nothing compiled; findings are proposals.
# Subjects (changed under src/): sw_stacked_items.e (new), sw_text_pointing.e, sw_in_place_editing.e,
#   sw_text_geometry.e, sw_paragraph_list.e, sw_document_view.e, sw_text_box.e, sw_mark_legend_view.e.
# Compared against all of src/. Previous report: design-scan-since-8125771.md.

## 1. Verdicts on the six previous HIGH findings

| # | Previous finding | Verdict |
|---|------------------|---------|
| 1 | Stack / measure / visible range / frame skeleton | RESOLVED, residues N1, N2 |
| 2 | Editor-hosting SW_WIDGET features copied | PARTLY RESOLVED |
| 3 | Pointing geometry copies; list lacks the stale guard | RESOLVED, residue N5 |
| 4 | Shaped-vs-toy layout dispatch x3, diverged | RESOLVED for the dispatch; call sequence PARTLY (N6) |
| 5 | Text width beside the bar; list does not scale | PARTLY RESOLVED |
| 6 | end_edit / on_edit_commit semantics differ | RESOLVED (one behavior change to confirm, N7) |

1. RESOLVED. sw_stacked_items.e owns stack, viewport_height, first_visible (75), last_visible (85),
   stacked_top (101), stacked_item_at (109), stacked_scroll_for (120), body_pixel_size (143),
   measure_stack (191), begin_frame (221), draw_visible, end_frame. Both users now implement only the
   deferred pieces (list sw_paragraph_list.e:1252-1300; view sw_document_view.e:762-816). The page-inset
   drift is gone (stack_origin_y: list 1252 is 0, view 767 is margin). Residue: wheel_line (N1) and by-hand
   inset arithmetic at sw_document_view.e:426 and 1246 (N2).
2. PARTLY. sub_widgets and widget_at are now one-liners over editor_sub_widgets / widget_or_editor_at
   (sw_in_place_editing.e:228, 239; list 912, 968; view 534, 539). Still duplicated with identical bodies:
   accepts_focus (list 928 / view 496), wants_hover_point (933 / 501), preferred_height (946 / 520),
   the handle_release / handle_char shapes, draw (list 976-983 / view 547-555: measure, begin_frame,
   draw_visible, end_frame, draw_bar), and the 15-name redefine list, now repeated for FIVE parents in each
   user (list inherit clause, lines 72-112; view 62-106): the fifth mixin ADDED about 15 lines per user.
   Proposal (b) of the previous report, a joiner ancestor (for example SW_SCROLLING_EDITOR inheriting
   SW_VSCROLLING, SW_STACKED_ITEMS and SW_IN_PLACE_EDITING and redefining the shared SW_WIDGET features once),
   is not done. Note the stated rule "a mixin never redefines SW_WIDGET features" does not hold for
   SW_TEXT_POINTING (sw_text_pointing.e:44-46 redefines five), which is why each user carries the
   `undefine` lists (list 78, 88, 98, 108).
3. RESOLVED. character_at (sw_text_pointing.e:115), offset_at_point (131), text_boxes (151) are effective once,
   behind is_current (106), which checks `item_geometry.count = item_text_count`. Users supply only
   item_geometry / item_origin_x,y / is_item_pointable (list 424-445, view 452-473). The list's pointed_item
   (list 469) now matches the view's (contains, not bar, then stacked_item_at, which needs is_laid_out).
4. RESOLVED for the dispatch. SW_TEXT_GEOMETRY.lay_out (sw_text_geometry.e:487-526) holds the engine switch
   and the one-line floor once; callers: list laid_text_height (list 1307-1309), view lay_unit (view 1016-1030),
   SW_TEXT_BOX.ensure_layout (sw_text_box.e:1163-1170), SW_MARK_LEGEND_VIEW (sw_mark_legend_view.e:146). The
   list's missing shaped floor is fixed. NOT VERIFIED (nothing run): that `text_extent` after build_toy equals
   the old toy floor.
5. PARTLY. The list's gap now scales: bar_gap := theme.padding / 2.0 at measure (list 1226); gutter_px,
   gap_px, pad_px scale by laid_scale (list 1174-1190); the three `- 4.0` copies are gone (text_width 514,
   draw 996 use bar_gap). Remains: the same role has two different tokens (list padding / 2; view
   `2.0 * margin` = border_width, sw_document_view.e:747); the unscaled literal default `bar_gap := 4.0`
   (list 129) and 28/8/8 defaults (list 126-128); `set_line_width (2.0)` and the +-1.0 / 0.5 ring insets in
   draw_stacked_item (list 1015-1022).
6. RESOLVED. One template: sw_in_place_editing.e:70-107 (take the text, close_editor, then keep_item or
   restore_item; unchanged is not a commit; box down before either). Users: list keep_item 894 / restore_item
   900; view keep_item 346 / restore_item 358.

## 2. New findings the refactor introduced or left

| # | Pri | Cat | Where |
|---|-----|-----|-------|
| N1 | MEDIUM | D1/T1 | wheel_line: list sw_paragraph_list.e:1190 (stored, set in measure at 1235; 20.0 default at 139) vs view sw_document_view.e:488-491 (computed from laid_px); same `px * 1.5`, two shapes. body_pixel_size now exists (sw_stacked_items.e:143): make wheel_line effective there. |
| N2 | MEDIUM | A5 | By-hand inset math survives beside the helper: sw_document_view.e:426 (`a_py - y - margin + scroll_y`, used for the table-cell test) and 1246-1247 (`stack.item_at (cy)` = stacked_item_at plus a below-content test). Use stacked_item_at (plus a "below content" query) so the inset lives in stack_origin_y only. |
| N3 | MEDIUM | A1/M2 | The joiner (finding 2) is now the largest remaining copy: about 8 identical features and about 75 lines of inherit boilerplate across the two users. |
| N4 | LOW | A5 | scroll_to_item (list 854-865) and scroll_to_block (view 286-294) are the same 4-line body over stacked_scroll_for; item_top / item_height (list ~313-331) and block_top / block_height (view 212-229) are thin wrappers of stacked_top / stack.height. Lift one `scroll_item_into_view`. |
| N5 | LOW | D1 | list caret_offset_at (sw_paragraph_list.e:410), handle_click (1064-1090) and handle_double_click (1093) still pick the item with the y-only item_at (353), not pointed_item, so a point beside the widget can name an item (offset_at_point itself is guarded). |
| N6 | LOW | A5/D1 | Layout call sequence still repeated: set_alignment, set_styles, lay_out in list 1307-1309, view 1016-1030, text_box 1166-1170. Alignment width differs: list `a_w.floor.max (16).to_double`, view `a_unit.wrap`, box `a_wrap.max (0.0)`, while lay_out floors its own wrap at 16. Fold alignment into lay_out. |
| N7 | note | behavior | The list used to call on_edit_commit on every commit; now only when the text changed (inside sw_in_place_editing.e:70-107). The list's class note (sw_paragraph_list.e:37-39) still says `end_edit (True)` "commits through on_edit_commit". Confirm the new rule is wanted for the list's hosts and update the note. No test/ directory exists in the library to show either way. |
| N8 | LOW | T1 | `(size_body * text_scale).rounded.max (1)` now in three places: sw_stacked_items.e:143, sw_text_geometry.e (lay_out, `px :=`), sw_text_box.e:1127. One SW_THEME `body_pixels` query. |
| N9 | LOW | T1 | New copy of the clip inset: sw_stacked_items.e:226 joins sw_chat_thread.e:1055, sw_mark_legend_view.e:142, sw_dock_zone.e:366 (variants: sw_spreadsheet.e:177, sw_tree_table.e:145). One SW_PAINTER.push_frame_clip. |

No new HIGH findings.

## 3. Previous MEDIUM / LOW items

- 7 (hover across document change): STANDS. list wipe_out zeroes hover (sw_paragraph_list.e:695); view set_document (sw_document_view.e:256-270) does not.
- 8 (seven parallel lists in the list): STANDS (list ~1210-1226 attributes, invariant `parallel_model`).
- 9 (literals that want tokens): STANDS in part: Quote_bar 3.0 (view 736) vs chat_thread 2.0 / 5.0 (sw_chat_thread.e:991-994); heading 1.6 / 1.3 / 1.12; floors 16.0 / 32.0 (view 747, 868, 874, 881, 964; list 514); link-underline and strike literals. The clip inset is now N9.
- 10 (view is a monolith): STANDS. 1317 lines; measure_block / measure_table / heading_size (840-1046) are still inside; lay_unit is thinner.
- 11 (redundant clamps): STANDS: list 959 and 980 `scroll_y := scroll_y.min (max_scroll)`; place_bar already clamps.
- 12 (modifier reads): STANDS: view 654 and 1235 allocate SW_KEYS inline; list 1070 / 1080 allocates a local.
- 13 (sentinels): STANDS: view 942 `1_000_000.0`, view 124 `laid_px := 14`.
