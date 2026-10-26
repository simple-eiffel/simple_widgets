# Design Scan (diff mode): since af94462 (simple_widgets 0.38.0-0.38.5) and 64c66ac (simple_shell 1.22.2)
# Date: 2026-10-25   Read-only: no source edited, nothing compiled, nothing run.
# Subjects: sw_color_math, sw_geometry_data, sw_tab_strip (draw_tab_ground), sw_widget_exporting,
#   sw_layered_layout, sw_virtual_grid_assault (simple_widgets); shell_events (simple_shell)

## Summary

| Severity | Count |
|----------|-------|
| HIGH     | 1 |
| MEDIUM   | 6 |
| LOW      | 7 |

Behavior-preservation verdict: the moves are faithful except where noted. Checked and CLEAN:
SW_HEATMAP.blend fraction range; SW_THEME luminance/contrast; SW_PAINTER and SW_COLOR_PICKER channel
arithmetic; SW_GEOMETRY_DATA parse loop (token for token the old Region copy); SHELL_EVENTS numbers
against the C header (46 registry entries == 46 distinct `shell_push(N,` literals in
Clib/simple_shell.h: 2-4, 6-18, 21-23, 25, 31-37, 41-59).

## HIGH

### H1. Tab ground now scales with the theme; the drag outline and dock separators beside it do not (D1/T1)
Files: src/sw_tabs.e:552, src/sw_dock_zone.e:358, src/sw_tab_strip.e:126-155.
Evidence: `draw_tab_ground` derives `l_inset := t.padding / 2.0` (padding = gap * text_scale,
sw_theme.e:565-570) and `l_rule := (t.border_width / 4.0).max (2.0)`. The old code had literals 4.0/3.0
(tabs) and 1.0/2.0 (dock). Right beside the call, SW_TABS still draws the drag outline with
`a_p.rrect_stroke (tx + 0.5, y + 4.5, tw - 1.0, bar_h - 6.0, t.radius)` (sw_tabs.e:552) and SW_DOCK_ZONE
draws tab separators with `y + 4.0, 1.0, bar_h - 8.0` (sw_dock_zone.e:358). At text_scale 1 (gap 8,
inset 4) they still agree; at any other scale the ground moves and the outline/separators stay put, so
the outline no longer hugs the ground it outlines. One copy scales, the others ignore the setting.
Suggested fix: add `tab_inset` (padding / 2) to SW_TAB_STRIP plus `draw_tab_outline` and a separator
helper beside `draw_tab_ground`, so all three paint with one inset; SW_TABS and SW_DOCK_ZONE lose the literals.

## MEDIUM

### M1. Dock zone selected tab changed shape, not just numbers
Files: src/sw_dock_zone.e:350-358, src/sw_tab_strip.e:140-147.
Old dock: square `fill_rect` from y+1, full tab width, 2 high underline across the whole tab. New:
`rrect_fill` (radius t.radius) from y + padding/2 (about 17 of 22 px tall instead of 21), underline
inset padding/2 each side. SW_TABS also loses 1 px of underline (3 -> 2 via `.max (2.0)`).
Intended per the class note, but the CHANGELOG should say it is a visual change, and only the GW-05
study PNGs changed, so no pixel check covers the dock. Fix: a dock-zone pixel assault (light and dark).
Safe point verified: `draw_tab_ground` precondition `tab_widths.i_th (a_i) > 0.0` holds in the dock
because `place_tabs_shrinking` floors every width at 1.0 (sw_tab_strip.e:~175).

### M2. `is_lean_build` probe rests on the library cluster compiling with preconditions
File: testing/sw_virtual_grid_assault.e (`is_lean_build`, `breaks_a_precondition`); src/sw_era_years.e:47-50.
Verified: `astronomical` has `require no_year_zero: a_display >= 1` (sw_era_years.e:49-50) and `make` is its
creation procedure (line 14-19), so `astronomical (0, True)` raises exactly when that precondition is
compiled in. The probe is sound only if the contract build keeps the library cluster option
`precondition="true"` (simple_widgets.ecf:13). Memory note "Extending ECF target drops assertions"
applies: if the tests target stops carrying it, the contract build silently calls itself lean, holds
16.7 ms, and the one-in-three flake returns with no message. Fix: report which build was detected
(`report ("build", ...)`), and add a check that `ec.sh test` runs detect "contracts" (an environment
variable the test script sets). A dedicated tiny canary class with `require a > 0` would also not break if
SW_ERA_YEARS relaxes its contract.

### M3. SW_COLOR_MATH inherited plainly leaks five color features into four public APIs
Files: src/sw_color_math.e (all public); inheritors SW_THEME, SW_PAINTER, SW_HEATMAP, SW_COLOR_PICKER.
Callers use `luminance`, `contrast_ratio`, `mixed` on a theme (sw_map.e:525-541, sw_mark_palette.e:73,
sw_chip.e:182), so SW_THEME must keep them public. SW_PAINTER, SW_HEATMAP and SW_COLOR_PICKER need only
`channel_fraction`/`mixed` internally yet now export all five. Fix: keep SW_THEME public; give the other
three `export {NONE} all` in the inherit clause (or split channel helpers into a second ancestor).

### M4. SW_GEOMETRY_DATA.pending is ONE once shared by every heir and every block set
File: src/sw_geometry_data.e (`pending ... once`).
Before, SW_WORLD_GEOMETRY and SW_REGION_GEOMETRY each had their own once; now one serves both and all of
region's sets (land, holes, lakes, rivers). Correct today only because every set ends with `flush` and
nothing interleaves. If `to_double` raises on a bad token, or an heir forgets the closing `flush`, the
leftovers prepend to the NEXT set parsed anywhere. The old world guard (`is_last_block` comparing against
`data_5`) is gone, replaced by a rule that lives in a class comment. Fix: make parsing stateless across
calls: `parse_set (a_blocks: ARRAY [STRING]; a_acc)` with a local pending list that flushes itself, so an
heir cannot forget; one-line change in each generator.

### M5. SW_WINDOW dispatches on raw event numbers although it now inherits the named registry
File: src/sw_window.e:568 (`a_type = 7`), 590 (`= 16`), and `inspect a_type` at 652, 935, 1832, 1890
with `when 2/3/4/6/8/11/13`; the same file uses names at 594-626 (`Event_appearance_changed`,
`{SW_ACCESSIBILITY}.Event_focus_request`).
SW_WINDOW inherits SHELL_WINDOW, which inherits SHELL_EVENTS, so `Event_tick`, `Event_window_press` and
the rest are in scope (inspect accepts constant attributes). The registry exists so numbers have one
home, yet the largest consumer still matches them by hand. Fix: replace the literals with the names
(`when Event_window_press then`), roughly 12 branches. Mechanical.

### M6. The C header is still a second hand-kept copy of the numbers
Files: simple_shell/Clib/simple_shell.h (`shell_push(N,`), simple_shell/src/shell_events.e.
The registry comment says a new event joins `registry` "and only then goes into the header": a discipline,
not a check. `test_event_numbers_never_collide` (testing/shell_assault.e) compares Eiffel names to each
other only; it cannot see a header number missing from, or wrong in, the registry. I confirmed they agree
today. Fix: a test that scans the header text for `shell_push(N,` and asserts each N is in `registry`, or
generate the header's numbers from the registry.

## LOW

### L1. SW_HEATMAP.blend is now a one-line delegate with a duplicated precondition
src/sw_heatmap.e:130-136. Callers: sw_heatmap.e:206 (fraction from `heat_of`, whose postcondition `unit`
keeps it in 0..1: SAFE) and testing/sw_chart_assault.e:275-279 (0.0, 1.0, 0.5: SAFE). Behavior difference:
`mixed_channel` now clamps 0..255 and applies `max (0)` before `to_natural_32` (the old heat-map blend
did not clamp; negatives wrapped), an improvement. Fix: drop `blend`, call `mixed` at the one site, repoint
the three test lines (public API removal: Larry's call).

### L2. NaN heat fails `heat_of`'s own postcondition before it can reach `mixed`
src/sw_heatmap.e:95-102. Pre-existing; note only.

### L3. SW_COLOR_PICKER still packs RGB by hand, the inverse of `channel_fraction`
src/sw_color_picker.e:233-235 (`((r+m)*255.0).rounded.to_natural_32.bit_shift_left (16) ...`). Fix: a
`packed (a_r, a_g, a_b: REAL_64): NATURAL_32` in SW_COLOR_MATH with the same clamp as `mixed_channel`.

### L4. `mixed` repeats the shift/mask that `channel_fraction` owns
src/sw_color_math.e (`mixed` uses `|>> 16`, `|>> 8` inline). A private `channel_byte (rgb, shift)` would
serve both. Cosmetic.

### L5. SW_GEOMETRY_DATA.flush minimum is now 4 numbers (world was 6)
src/sw_geometry_data.e (`pending.count >= 4`); old world `flush_ring` used `>= 6`. A two-point world "ring"
is now kept. I found no such ring in the data, and SW_MAP consumes `geometry.polygons` (sw_map.e:802), but
nothing asserts it: the world `ensure many_rings: Result.count >= 100` cannot notice. Fix: a test that every
world polygon has `count >= 6`; `parse_block` has no postcondition and `flush` only `emptied`.

### L6. Misplaced comment in the GW-29 test
testing/sw_virtual_grid_assault.e: the `-- One frame at 60 Hz.` comment that documented `Frame_budget_ms`
now sits after `breaks_a_precondition` (the new features were inserted between the constant and its
comment); `breaks_a_precondition` itself has no header comment. Move the comment back.

### L7. `collection_off` is not exception-safe in `timed`
testing/sw_virtual_grid_assault.e (`timed`). If `a_work.call` raises, `collection_on` never runs and the
collector stays off for the rest of the suite. Fix: a `rescue` that restores it and re-raises.

## Subjects with no finding (checked)

- SW_WIDGET_EXPORTING: defers theme, painter, shaping (public) and hovered ({NONE}); SW_WINDOW supplies all
  four with matching signatures (sw_window.e:102, 107, 130, 2895). Every contract moved intact
  (`can_export`, `stays_put`, `sized`, `light_by_default`, `screen_when_asked`). Carried-over smell:
  `export_theme` creates a new light SW_THEME per call and is called from `can_export` (precondition),
  `widget_image` and the `sized` postcondition, so one export builds 3-4 themes; cache it and invalidate
  in `set_exports_in_screen_theme`.
- SW_LAYERED_LAYOUT: no widget or painter reference remains. Contracts were strengthened (count_sane,
  edges_bounded, no_self_loop, per_node, per_edge). SW_DIAGRAM `connect` requires `a_from /= a_to`
  (sw_diagram.e:120), so `no_self_loop` is covered. Aliasing: SW_DIAGRAM `layer_of`, `order_of`,
  `is_reversed` return the engine's own mutable lists (sw_diagram.e:391-407); the engine invariant is only
  `parallel_edges`. `visit` is recursive (depth = longest DFS path); same shape as the old copy.
- SW_THEME: `luminance`, `contrast_ratio`, `mixed` kept signatures and contracts; private `channel` became
  `linear` (same WCAG arithmetic).
- SHELL_EVENTS rename chains: SHELL_PANEL, SHELL_TRAY, SHELL_APPEARANCE rename to their old short names;
  SHELL_WINDOW and SHELL_WAKE both expose `Event_wake` by plain inheritance (one feature, no clash).
  Side effect: every heir now exports `registry` and `next_free_event` as public API (the new test builds a
  SHELL_WAKE just to reach them); consider `feature {SHELL_EVENTS}` plus a test-visible accessor.

## Recommended Order

1. H1 - the live scale drift; one small helper in SW_TAB_STRIP.
2. M5 and M6 - make the registry the single source (names in SW_WINDOW, header checked).
3. M4 - stateless block parsing before a third geometry heir arrives.
4. M2 - make the GW-29 build detection visible so it cannot go quiet.
5. M1, M3, then the LOW items.
