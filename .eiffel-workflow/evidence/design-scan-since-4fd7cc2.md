# Design scan (diff mode), simple_widgets since 4fd7cc2 (main 14ae36e)

Read-only. Nothing compiled or run: every statement comes from reading the code at the cited lines. "Unverified" marks what only a run can settle.
Subjects: sw_shaping.e, sw_shaped_text.e, sw_label.e, sw_data_grid.e, sw_grid_column.e, sw_interlinear.e (comment only), testing/sw_memo_assault.e, sw_virtual_grid_assault.e, test_app.e.

Counts: HIGH 0, MEDIUM 6, LOW 6.

## (a) add_row (src/sw_data_grid.e:167-216) - correct

- Ascending (190-194): `key < mid_key` goes left, else right, so the insertion point is the UPPER bound: the new row lands after equal keys. Descending (196-199): `mid_key < key` goes left, else right: also the upper bound. `merge_sort_view` keeps model order among equals in both directions (`key_less` is strict both ways, 632-645) and the new row is last in the model, so the incremental and rebuilt views agree. Stable and correct both ways.
- Boundaries: empty view gives lo=1, hi=1, the loop is skipped and `lo > view.count` extends. Insert at 1 uses `go_i_th (1)` + `put_left`. Insert at the end uses `extend`. No sort (sort_column 0 or out of range) appends. Fine.
- Filter: a failing row is in `rows` but not in `view`; `view.count <= rows.count` still holds (`rows.extend` runs first).
- Invariants: `view_never_exceeds_rows` holds. `selection_in_model` holds: the row is appended at the model end, no model index moves, `selected_model` stays valid.
- Scrollbar: `sync_bar` runs on every path (212); `SW_VSCROLLBAR.set_extent` is two assignments. `scroll_y` is not re-clamped; fine, the extent only grows.
- Test coverage (sw_memo_assault.e:56-79): descending only, no filter, no boundary cases. Add ascending, a filter, an empty grid, sort_column 0.

Findings
- MEDIUM, sw_data_grid.e:205: postcondition `shown_when_it_passes` calls the user filter a second time. A filter with side effects or real cost runs twice per row under contracts. State it as `view.count >= old view.count and view.count <= old view.count + 1`.
- LOW, sw_data_grid.e:210 (`add_rows`): no `ensure` (rows grew by the count) and no precondition `a_rows /= rows`. `rows` is exported (tests read `g.rows`), so `add_rows (g.rows)` would loop while extending the list it iterates. No threshold either: adding 3 rows to 100,000 pays a full rebuild (merge sort, 100,000 key agent calls).
- LOW, sw_data_grid.e:189: the binary search trusts that `view` is sorted by keys read NOW. If a row object is mutated after sorting, the insert point is wrong until the next rebuild. One sentence in the class note.

## (b) alignment (sw_data_grid.e:449-479, sw_grid_column.e:44-120)

- Text wider than the cell: slack is `(width - 16 - advance).max 0`, so the text starts at cx+8 and the cell clip cuts it. Same as `SHAPED_LAYOUT.line_offset`. A wide RTL line shows its tail, not its beginning. LOW, unremarked.
- Align_end: `is_right_to_left = (alignment = Align_start)`. Start+RTL right, End+LTR right, Start+LTR and End+RTL left. Correct. Align_left falls to `else` (offset 0). Right and Center correct.
- Toy path: `is_right_to_left` is False (no kit, or empty text), so Start is left and End is right. A Hebrew cell with no kit is left. Same as `SW_PAINTER.text` there.
- MEDIUM, sw_data_grid.e:421: header cells are NOT aligned (`a_p.text (cx + 8.0, ...)`). A right-aligned numeric column has a left title; a Hebrew title sits left over cells that sit right. Use the same offset with `col.alignment`, clear of the sort arrow (drawn at cx+width-20).
- MEDIUM, sw_data_grid.e:395 and 449-479: per cell per frame `cell_left` calls `a_p.advance` UNCONDITIONALLY (a `layout_styled` lookup), `is_right_to_left` does a second, `a_p.text` a third. All three hit the memo (same width 0, size, role, weight as the painter, so the same key; no re-shaping). But each lookup builds a STRING_32 key copying the text, and under contracts the `remembered` postcondition (sw_shaping.e:204) builds another: 3 key builds lean, 6 under contracts, against 1 before. On the toy path the unconditional `advance` is a cairo `text_extents` per cell even for the default column. The class note measures a wheel frame at 14.8 ms of 16.7; check whether that already includes alignment (unverified).
  This is a DUPLICATE of `SHAPED_LAYOUT.line_offset` (simple_shaping src/result/shaped_layout.e:137-170), which already does Align_left/right/center/end/start with `is_rtl` and "wider than the box starts at the left edge". Get ONE layout (`kit.layout_styled`), call `layout.line_offset (layout.lines.first, width - 16, alignment)`, draw it with `a_p.draw_shaped_layout`. One lookup per cell; `cell_left` and `is_right_to_left` shrink to the toy branch.

## (c) the memo (sw_shaping.e:156-231)

Closed: facade.clear_cache, load_font_file (via forget_font_answers), set_default_fonts, set_asset_directory each bump `policy_revision` (simple_shaping.e:397, 418, 615, 626), checked first on every call (182); the kit setters (`set_theme_faces`, `set_fonts`, `set_script_face`, `set_small_script_face`) call `forget_layouts`. Two kits on one facade both see the revision move. The key carries size, width, role, weight, text, joined by a separator (422-436), so no forgery.

Remaining ways to serve a stale layout
- MEDIUM, sw_window.e:528-539 (`wear_theme`): a theme swap builds a new painter but never calls `kit.set_theme_faces (a_theme)`; only `enable_shaped_text` (183) does. After `set_theme` to a theme with other `family_ui/body/mono`, the kit keeps the OLD role faces and the memo serves layouts made with them. The role faces were already stale before this change, but the class note's promise ("must never serve a layout made under other fonts") is false here, and the deleted SW_SHAPED_TEXT comment ("a theme swap rebuilds the faces") described a mechanism that does not exist. A light/dark pair sharing a family hides it. Fix: `wear_theme` calls `set_theme_faces` on `shaping`.
- MEDIUM, sw_shaping.e:79 and simple_shaping.e:579-599: each `SW_SHAPING.make` creates its OWN SIMPLE_SHAPING. `load_font_file` is process-wide but only the loading facade bumps its revision (the library says so, 593-594). A second window's kit keeps stale layouts until it calls `forget_font_answers`. Document "load fonts before the first window", or let SW_SHAPING forward `load_font_file` to every kit.
- Theme scale change: not stale; the pixel size is in the key.
- LOW, sw_shaping.e:204: `remembered` recomputes `memo_key` (allocates the text) on every call; it restates the body. Under contracts it doubles the cost the class note is cutting. Drop it.
- LOW, sw_shaping.e:213: 1,024 per generation. A screen with more than about 2,000 distinct visible strings (4K, 100 rows x 20 columns) would thrash and re-shape every frame. State the bound.

## (d) SW_SHAPED_TEXT after deleting its cache

- Nothing in src/ or testing/ used `count`, `is_cached` or `wipe_out` (grep). Menus (sw_menu.e 297, 310, 342, 427, 547, 572; sw_menu_bar.e 222, 252, 342) now do one memo lookup instead of a key build plus a linear scan of up to 64 string compares: cheaper, not dearer. Per frame they still do width_of + layout_of + total_height per item (several lookups of one string), fine through the memo.
- MEDIUM, sw_menu.e:310, 572 vs sw_shaped_text.e:56: shortcut hints set `Role_mono` on the painter (312, 575) but are measured and drawn through `shaped.layout_of`, which is Role_ui regular. The hint is shaped in the UI face, not the mono face the painter was told. The new note says menus get "the same faces as SW_PAINTER.text"; for hints that is false (it was already so with `layout_for`). Fix: `layout_styled_of (kit, hint, size, Role_mono, False)` in `hint_width` and in the draw.
- LOW, sw_shaped_text.e:49-97: the class now holds no state. `make` is empty and `layout_of`, `layout_styled_of`, `width_of` forward to `kit.layout_styled`; sw_label.e:124-127 calls the kit directly in the wrapping branch and through `shaped` in the other, and SW_LABEL (line 46) still creates an instance per label. Proposal: keep the geometry (top_for_baseline, baseline_for_top, character_span) as a deferred mixin beside SW_CLUSTER_MATH (SW_SHAPED_TEXT already inherits it, with SW_CHAT_THREAD and SW_TEXT_BOX), inherited side by side by menus and labels; move the layout forwards onto SW_SHAPING.

## (e) other duplication and drift

- MEDIUM, alignment: "Align_* code to x offset" now lives in `SHAPED_LAYOUT.line_offset`, `SW_DATA_GRID.cell_left` (new) and the aligned paths of SW_PAINTER (278-302). Six classes carry an alignment attribute with its own setter (SW_LABEL.text_alignment, SW_TEXT_BOX, SW_PARAGRAPH_LIST, SW_DOC_UNIT, SW_PARALLEL_TEXT, SW_GRID_COLUMN), each with a copy of `a_alignment >= Align_start and a_alignment <= Align_center` (sw_grid_column.e:105, 114; sw_label.e:145; sw_text_box.e:422; sw_paragraph_list.e:463; sw_parallel_text.e:155; sw_doc_unit.e:118; sw_painter.e:282, 301) although `SHAPING_CONSTANTS.is_valid_alignment` exists (shaping_constants.e:52). Proposal: a deferred `SW_ALIGNABLE` mixin (attribute, `set_alignment`, the clause once) inherited side by side. Defaults disagree: SW_GRID_COLUMN is Align_start, the others Align_left. For the grid that is a visible change (Hebrew cells flush right unasked); say so in the CHANGELOG.
- MEDIUM, testing/sw_virtual_grid_assault.e (130-168): moving every timed step inside `without_contracts` removed the only assertion that guarded contract COST. "page frames do not grow slower" now measures the lean build, so the 0.6.1 defect (contracts that grow with the cache) would pass. The contracts-on series is report-only. Assert that series does not grow (median of the last 5 within 2x of the first 5 plus slack).
- LOW, same file, `timed` (176-190): a contract violation inside a timed step is invisible (set_rows, sort_by, handle_key, request_render run unchecked); the 10 checked frames cover only request_render.
- LOW, sw_grid_column.e:100-120: `aligned` repeats `set_alignment` and its precondition text.
- LOW: sw_interlinear.e change is comment-only; no finding.
