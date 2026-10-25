# Design Scan (diff mode): simple_widgets --since 24c8a87 (main 4fd7cc2)
# Date: 2026-10-25. Read-only; nothing compiled, nothing edited.
# Subjects: sw_shaping.e, sw_grid_column.e, sw_data_grid.e, sw_query_builder.e, testing/test_app.e
# Compared against: all of src/ (SW_SHAPED_TEXT, SW_PAINTER, SW_LABEL, SW_TEXT_GEOMETRY, SW_WINDOW, SW_CHAT_THREAD)

## Summary

| Area | Findings | High | Medium | Low |
|------|----------|------|--------|-----|
| (a) layout memo | 6 | 2 | 2 | 2 |
| (b) sort | 3 | 0 | 0 | 3 |
| (c) SW_DATA_GRID leftovers | 5 | 0 | 3 | 2 |
| (d) SW_SHAPED_TEXT duplication | 2 | 1 | 1 | 0 |
| Scan-6 / test_app | 2 | 0 | 0 | 2 |
| **Total** | **18** | **3** | **6** | **9** |

## HIGH

### H1 (D1, a). A facade change reached through `facade` leaves the memo stale
`SW_SHAPING.layout_styled` (sw_shaping.e:134-176) answers from `memo`/`older_memo` BEFORE the facade is asked, so the facade's own invalidation never reaches it.
- `SIMPLE_SHAPING.load_font_file` forgets effective digests, so the facade's cache re-keys (simple_shaping.e:535-550). The memo key (sw_shaping.e:387-401) holds size, width, role, weight and text only, so a face that arrives after a string was memoized never shows. Also true of `facade.set_asset_directory` (emoji artwork is part of layout identity, simple_shaping.e:372), `facade.set_default_fonts`, `facade.clear_cache`, `facade.forget_font_answers`.
- The note at sw_shaping.e:189-190 ("call it after changing `facade''s fonts directly") is a convention only. `facade` is exported (line 81), and the toolkit's own tests call `kit.facade.load_font_file` (sw_label_shaping_assault.e:208, sw_shaping_assault.e:1088). They only pass because `set_theme_faces` runs afterward and calls `forget_layouts`.
- `load_font_file` is documented PROCESS-WIDE (simple_shaping.e:526-531): "only this facade forgets". `SW_WINDOW.enable_shaped_text` (sw_window.e:174-185) builds one kit PER window, so a second window's kit keeps stale memo entries (and stale `role_fonts` lists) after the first window loads a font. The user sees tofu or the wrong face until some theme call happens to wipe it.
- Setters that DO invalidate are complete: `set_theme_faces` (:290), `set_fonts` (:302), `set_script_face` (:322), `set_small_script_face` (:350). Theme swap (`SW_WINDOW.wear_theme`, sw_window.e:528-539) rebuilds only the painter and never touches the kit, so no memo staleness from a theme swap (the kit's faces simply do not follow a theme swap, see L3). Scale is safe: `a_pixel_size` is in the key.
- Fix (proposal): give SW_SHAPING `load_font_file`, `set_asset_directory`, `clear_cache` that forward and call `forget_layouts`; make `facade` `feature {NONE}`/read-only (SW_TEXT_GEOMETRY.e:678-681 and tests reach through it for `layout`/`layout_styled`, which could go through new forwarders). For the multi-kit case put a generation stamp in the memo key (facade-level `font_epoch`, bumped by `forget_font_answers`/`set_asset_directory`/`clear_cache`) so any facade change is seen without being told.

### H2 (D1, d). SW_SHAPED_TEXT never invalidates when the SAME kit changes; it also uses a different font policy than the memo
SW_SHAPED_TEXT (sw_shaped_text.e:70-103) wipes only when `a_kit /= last_kit` (line 80). `kit.set_theme_faces`, `set_script_face`, `set_small_script_face`, `set_fonts` on the same kit leave its 64 layouts stale. It is held by SW_LABEL (sw_label.e:365), SW_MENU (sw_menu.e:46), SW_MENU_BAR (sw_menu_bar.e:62). The class note (:22-24) promises "a kit swap empties the cache" but a kit CHANGE does not. A runtime "change Hebrew face" setting leaves every menu and label on the old face; the memo wipes, this copy does not: classic drift, memo copy wins.
Second divergence: it shapes through `layout_for`, which uses `fonts` (Latin-only theme face, sw_shaping.e:281-284) and ignores `script_faces`, `small_script_faces`, role leading family and weight. So the same Hebrew string paints in one face through `SW_PAINTER.text` and another through a label or menu item.

### H3 (perf-at-scale, c). SW_DATA_GRID.add_row is a full filter + sort per call
sw_data_grid.e:152-157 calls `rebuild_view` (:658-690): filter all rows, merge-sort the whole view, then `selected_view_position`. Loading 100,000 rows by `add_row` while a sort column is set is about 100,000 x (100,000 x 17 comparisons) - hours. `set_rows` is fine (one rebuild); only the demo calls `add_row` today (demo/sw_demo.e:584-593), so it is HIGH only if a host streams rows in. Proposal: `add_rows (list)` / `begin_bulk`..`end_bulk`, and for the single append with no sort and no filter just `view.extend` when the row passes (O(1)); with a sort do a binary insert (O(n) shift, still not O(n log n) per row).

## MEDIUM

### M1 (a). `layout_for` and `layout_with_styles` should share the memo, differently
`layout_for` is called per frame by SW_LABEL when wrapping (sw_label.e:125), SW_TEXT_GEOMETRY (:689) and SW_CHAT_THREAD (:1285, 1347, 1398, 1408) and goes through the facade's key build plus contracts each time (the cost GW-29 removed for `layout_styled`). Add it to the memo under role 0 ("kit fonts") - the key already has the discriminator slot; `set_fonts`/`set_theme_faces` already wipe. `layout_with_styles` should NOT share it yet: `SHAPING_STYLES` is a mutable object, so the key would need `a_styles.digest` (exists, simple_shaping.e:244) - doable, but only if a caller needs it per frame (GW-08 Strong's numbers: SW_TEXT_GEOMETRY:686 builds per paragraph per layout pass, not per paint). Defer.

### M2 (a). Memo bound is by entry count, not bytes
`Memo_generation` = 1024 per generation, 2048 total (sw_shaping.e:184, invariant :480). Key = full copy of the text; value = the whole layout. SW_PAINTER.text passes single strings of any length (an editor line, a 1 MB log line) so worst case is 2048 x layout-of-largest-string, plus the facade's own 512-entry cache holding the same layouts (double residency: the facade evicts, the memo keeps them alive). Proposal: skip the memo above a text length (say 512 characters) or charge `a_text.count` against a character budget.

### M3 (c). Grid geometry hard-coded in pixels
`Header_h` 30.0, `Row_h` 26.0 (sw_data_grid.e:56-58), baselines `Row_h - 8.0` / `Header_h - 10.0` (:328, :349), sort arrow at fixed offsets 10-20 px / 12-19 px (:350-359), cell inset 8.0, divider hover 5.0. Cells and rows are used at `t.size_label` x `t.text_scale` through the painter; with `text_scale` > 1 the glyphs outgrow the 26 px row and are clipped. SW_BUTTON scales (sw_button.e:138). Token proposal: SW_THEME-derived `row_height` = (size_label * text_scale + 2 * control_inset).max(26) and `header_height`; scale every literal by `text_scale`. Note `view_row_at` (:229-230), `page_stride` (:617-621), `sync_bar` (:694) and the scroll step (:487) all read the constants, so one query `row_h` fixes all.

### M4 (c). Header and cell text ignore reading direction
Cells and headers are drawn at `cx + 8.0` always (:328, :349) with `SW_PAINTER.text`; SW_GRID_COLUMN has no alignment (no alignment/RTL feature in sw_grid_column.e). A Hebrew column starts at the LEFT of its cell, a numeric column cannot right-align, and the sort arrow collides at the right edge. Proposal: `SW_GRID_COLUMN.alignment` (SHAPING_CONSTANTS Align_start/end/left/right/center, default Align_start) and draw through `draw_shaped_layout_aligned` (sw_painter.e:275) with the memoized layout, which already does start-aligned RTL. Also the sort arrow should mirror in RTL.

### M5 (c). selected_view_position is a linear scan, called per key and per rebuild
sw_data_grid.e:624-642: O(view) with `i_th`, called by `handle_key` (:496), `scroll_selection_into_view` (:648) and again in `rebuild_view` (:682). At 100,000 rows that is about 0.1-0.3 ms a key press and runs twice for held arrow keys - tolerable, not a defect. Proposal: keep a `position_of: SPECIAL [INTEGER]` (model row -> view position) filled at the end of `rebuild_view` (O(n) once) and read in O(1). Also `rebuild_view` allocates `rows.count + 1` keys every call (merge_sort_view :562-565), 800 KB at 100,000 rows; reuse a buffer sized to `rows.count`.

### M6 (d). SW_SHAPED_TEXT's 64-entry linear cache is the old copy of what the memo now does
See H2. The right shape: SW_SHAPED_TEXT keeps ONLY the geometry (`SW_CLUSTER_MATH` heir: `character_span`, `top_for_baseline`, `baseline_for_top`) and asks `kit.layout_styled (text, No_wrap, size, Role_ui, False)` for the layout. That is one memo, one invalidation, linear scan (64 string compares per paint per label, `index_of` :254-271) gone, and the face policy identical to `SW_PAINTER.text`. Check first: Role_ui yields a LEADING theme family (digits and punctuation too, sw_shaping.e:214-219) where `layout_for` prepends for Latin only, so menu glyph metrics may shift by a pixel (visual-test the menu assaults). Better still as a deferred mixin: SW_SHAPED_LABEL_TEXT inherited side by side by SW_LABEL / SW_MENU / SW_MENU_BAR, replacing the `shaped: SW_SHAPED_TEXT` attribute in each.

## LOW

- L1 (a). `layout_styled` hits never touch the facade's statistics (sw_shaping.e:157-161), so `facade.statistics.cache_hits` undercounts after GW-29; sw_virtual_grid_assault.e:118-121 reads it. Say so in the header note, or add `memo_hits`/`memo_misses`.
- L2 (a). `memo_key` allocates `a_text.count + 16` STRING_32 per call, per cell, per frame (sw_shaping.e:392) and the postcondition `remembered` (:175) builds it again (finalized test builds only, assertions on). Key could be a TUPLE-free hash of text plus a check, or a value-keyed table without a copy. Cost is O(text), not a defect.
- L3 (a). Theme swap does not re-run `set_theme_faces` (sw_window.e:528-539, only `enable_shaped_text` does :183). If two themes differ in `family_ui`/`family_body`/`family_mono`, shaped text keeps the first theme's faces. Not a memo bug; flag for Larry.
- L4 (b). Stability holds in both directions: `merge_sort_view` takes the left element unless the right is STRICTLY before it (sw_data_grid.e:588), and `key_less` is strict both ways (:534-545). Keys for rows outside the view are never read (filtered rows stay Void in `l_keys`, :562-566); filter runs first (:664-677). OK.
- L5 (b). `key_less` treats a Void key as "equal" (:537). `sort_key` returns attached COMPARABLE so it cannot happen; a `check attached` would turn a future bug into a loud one instead of a silent wrong order. Keys are held by reference, so a `value`/`key` agent that returns a reused buffer string would make every key equal (before GW-29 it compared two calls back to back and was equally broken) - say "return a fresh object" in SW_GRID_COLUMN's `key` comment.
- L6 (b). `row_less` (sw_grid_column.e:96-100) is now dead for the grid (it only calls `sort_key` twice); still public, keep or drop.
- L7 (c). `selected_view_position` test of "filtered out" runs after each rebuild; fine.
- L8. testing/test_app.e `SW_ONLY` (run_test): a stray `SW_ONLY` in the environment silently skips every non-matching test and the run still ends "all passed" with a smaller count. Print `skipped N (SW_ONLY=...)` and exit non-zero from a release/CI run when it is set.
- L9. sw_query_builder.e: `a_c.field_index.min (fields.count)` (:389, 392, 449, 492) clamps but `field_kinds.i_th (0)` still fails if `fields` is empty; Distance_box_max/Word_field_width are pixels-and-words literals that belong with other builder tokens (`Word_field_width` 120.0 is a pixel width that should scale with `text_scale` like M3). `a_p.distance.max (99)` is right (SW_NUMBER_BOX.make requires value in range; `set_distance` requires >= 1).

## Recommended order
1. H2 and M6 together (route SW_SHAPED_TEXT through `layout_styled`; one invalidation point).
2. H1 (forwarders on SW_SHAPING, hide `facade`, add an epoch to the key).
3. M1 (`layout_for` under the memo) after 1.
4. H3 + M5 (bulk row add, position index), then M3/M4 (tokens and alignment) as a GW item.
