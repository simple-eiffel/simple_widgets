# Design scan (diff mode), simple_widgets since 760abf1 (main c396f22)

Read-only. Nothing compiled or run: every statement comes from reading the code at the cited lines. "Unverified" marks what only a run can settle.
Subjects: src/sw_tab_strip.e (new), src/sw_tabs.e, src/sw_dock_zone.e, testing/sw_tabs_assault.e, testing/test_app.e. Compared against all of src/ (grep for tab, glyph, chevron, overflow, drag-threshold and pixel-literal patterns in the other classes).

Counts: HIGH 2, MEDIUM 5, LOW 8.

Summary: the index bookkeeping after close and move is correct (traced below). The two HIGH items are contract failures reachable by ordinary use (a narrow bar, a theme with zero inset). The main design debt is that SW_TAB_STRIP took over the boxes but not the measuring or the drawing, so SW_TABS and SW_DOCK_ZONE now carry two parallel copies of "natural width", "strip height" and "draw a tab" that have already drifted.

## HIGH

### 1. HIGH, sw_tabs.e:485-511 with sw_tab_strip.e:160-200: `arrange` postcondition `selected_shown` fails on a narrow bar

Scenario: the bar is narrower than about 2 + chevron_w + tab_gap (roughly 35 pixels at 1x: a collapsed splitter pane, a hidden pane arranged at width 0, a dock sliver). `l_room` is `(width - 2.0).max 0.0` (494). Any tab set then overflows, `has_overflow` is True (495), and `l_room` becomes `(l_room - chevron_w - tab_gap).max 0.0` = 0 (497). `first_showing` returns the selected tab (its run can never be <= 0), and `place_tabs_scrolling` gives tab `a_first` width `natural.min (a_room)` = 0 (187). `is_tab_shown (selected_index)` is then False, so `selected_shown` (510) is violated. The comment at sw_tab_strip.e:164 ("Tab a_first is always placed, cut to the room") and the contract at 199 (`last_placed >= a_first`, which is true) hide that "placed" can mean width 0. In a contracts build this aborts the application (the memory note on the SW_DATA_GRID invariant crash shows how that looks to the user: the window just closes). Not covered: the assault file never arranges a tab bar below normal width (unverified).
Fix: in `place_tabs_scrolling` give the first tab `(natural.min a_room).max 1.0` (the SHRINK policy already floors at 1.0, sw_tab_strip.e:145), or weaken `selected_shown` to a width of at least 1. Add an assault test: arrange at widths 0, 1, 20, 34 with six tabs and assert no violation and that `tab_index_at` never answers a tab with width 0.

### 2. HIGH, sw_tabs.e:728: natural width cap is `20.0 * tab_pad`, and `tab_pad` is a theme token that may be 0

Scenario: `SW_THEME.set_spacing (b, p, 0.0)` is legal (sw_theme.e:478-487 requires only `>= 0.0`). `tab_pad` is `control_inset` (704) = 0, so every natural width is `.min (0.0)` = 0, every tab has width 0, nothing is clickable, and the same `selected_shown` violation as finding 1 fires on the first arrange. Even at the default the cap is a hidden magic ratio (twenty insets, about 220 pixels) rather than a token.
Fix: cap by the font (the label font box times a named constant) or add a scaled `SW_THEME.tab_max_width`, and floor each natural width at the close box plus one inset. Test with `set_spacing (0, 0, 0)`.

## MEDIUM

### 3. MEDIUM (duplication, drift), sw_tabs.e:704-707,724-728 vs sw_dock_zone.e:196-198,211: strip measuring is written twice and has drifted

- Natural width: `advance + 2.0 * tab_pad` in both (tabs 724, dock 211), but SW_TABS adds a close box and a cap, SW_DOCK_ZONE neither.
- Strip height: SW_TABS `text_extent + 2.0 * control_inset` (707); SW_DOCK_ZONE `text_extent + theme.padding` (196). Same role (a tab strip height), two different tokens. At the default theme they differ, and they scale differently if only `set_spacing` padding or inset is retuned.
- Font: `label_font` (tabs 735, Role_ui size_label) versus `title_font` in the dock zone; unverified whether these are the same role and size.
Fix: SW_TAB_STRIP owns `tab_inset (a_p)`, `strip_height_for (a_p)` and `natural_tab_width (a_p, a_label)`; both heirs call them, and SW_TABS adds the close extra on top. This is the natural second feature of the mixin (a side-by-side parent, no new inheritance level).

### 4. MEDIUM (duplicate drawing), sw_tabs.e:531-563 vs sw_dock_zone.e:309-322

Both draw "selected tab: surface fill plus accent underline; others muted; label clipped to the box; baseline centered". The copies disagree: SW_TABS uses a rounded fill inset 4.0 from the top and a 3.0 underline inset 4.0 each side (537-539); SW_DOCK_ZONE uses a square fill from y + 1.0 and a 2.0 full-width underline (311-313). Separators exist only in the dock zone (322). The label clip is the box in the dock zone (318) and box minus inset minus close box in SW_TABS (557). A future theme change (accent weight, radius) will be applied to one copy only.
Fix: put `draw_tab_box (a_p, a_left, a_width, a_selected, a_hovered)` and `draw_tab_label (a_p, a_left, a_width, a_label, a_ink, a_reserved_right)` in SW_TAB_STRIP. Keep separators and close boxes in the heirs. Make the underline weight a token.

### 5. MEDIUM (hard-coded pixels), sw_tabs.e:479,494,504-505,523,537-539,544,550,555,572,708,726,763 and sw_dock_zone.e:214,301,311,313,322

Literals that belong in SW_THEME tokens and do not scale with `text_scale`:
- Gap between bar and page: `bar_h + 8.0` (479, 504, 505). Same role as `content_pad := border_width` in SW_DOCK_ZONE (199), which does scale. Use `border_width`.
- Strip edge margin: `width - 2.0` (494) versus `x + 2.0 ... width - 4.0` in the dock zone (214): two margins for the same edge. Use `border_width`.
- Tab box insets `y + 4.0`, `bar_h - 5.0` (537, 544), underline `bar_h - 3.0`, height 3.0, `tx + 4.0`, `tw - 8.0` (539), stroke offsets 0.5 and 1.0 (550), dock separator `y + 4.0`, `bar_h - 8.0` (322). At text_scale 2 the tab box is relatively tiny. Candidates: half of `control_inset` for the top inset, and a `theme.underline_width` token.
- Magic ratios `close_size * 0.6` (763), `close_size * 0.8` (572), `chevron_w := bar_h * 0.8` (708), `tab_pad / 2.0` close spacing (555, 726): make them named constants in the mixin.
- The hairline `hline (x, y + bar_h - 1.0, width)` (523): fine, but name it.

## MEDIUM (contracts and index bookkeeping)

### 6. MEDIUM, sw_tabs.e:413-418 (`let_go` postcondition) versus 406-409

`let_go: (old pages.i_th (a_i)).parent = Void` is checked after `on_close` runs. A client that adopts the closed page elsewhere in `on_close` (moving a tab to another notebook or a floating window, the natural use of an agent that "fires with its page") gets `set_parent` to the new owner, and the contract then fails in a contracts build although the code is behaving. Fix: drop the postcondition (the code unparents before the callback) or state "no longer a page of Current" without a parent test, and say in the `on_close` note that the handler may adopt the page.

### 7. MEDIUM, sw_tab_strip.e:214-234 (`swap_adjacent_boxes`) via sw_tabs.e:789-791

`move_tab` is public. When the pair includes a tab with width 0 (scrolled off), `l_gap` is computed from the hidden tab's left, which is `a_left` (192), giving a large negative gap and a bogus left edge (228). The swapped widths also hand the shown (possibly selected) tab width 0 until the next arrange, and give the formerly hidden tab a real width at that bogus edge. Only the drag path guards with `is_tab_shown` (635, 643), so a keyboard "move tab left/right" binding (the class note advertises application accelerators) reaches it. Effect: one stale frame and a possible mis-hit before arrange, not a crash. Fix: call `forget_placement` in `swap_with_next` when either box has width 0, or add precondition `both_shown` to `swap_adjacent_boxes`.

## LOW

### 8. LOW, sw_tabs.e:610-611, 758

`close_box_at` is evaluated twice in `handle_click` (610, 611), and `draw_close_box` calls it once per closable tab per draw while hovered, each call running the linear `tab_index_at`: a hovered redraw is O(n squared) in the tab count. About 2,500 steps with 50 tabs, harmless; not with hundreds of tabs. Fix: compute the hot close box once at the top of `draw`; keep the first result in `handle_click`.

### 9. LOW, sw_tab_strip.e:97-121 and sw_tabs.e:711-733

`run_width` is linear and is called inside both loops of `first_showing`, so it is O(n squared) worst case; `natural_widths` measures every label with `a_p.advance` on every arrange. Fine at tens of tabs. For hundreds, cache natural widths per label and keep a running sum. All new contracts are O(1) (no across, no MML) and the invariants (sw_tabs.e:819-827, sw_tab_strip.e:237-238) are count comparisons, so none of this is a contracts cost.

### 10. LOW, sw_tabs.e:540-542 duplicates `tab_index_at`

The hover highlight tests the point inline with a different rule (inclusive right edge, only an upper vertical bound) instead of `tab_index_at (hover_px, hover_py) = i`. One pixel of drift at each right edge, and the highlight can show for a pointer above the bar top. Fix: use the shared query (with the once-per-draw hover result from finding 8).

### 11. LOW, sw_tab_strip.e:19-29

`tab_lefts` and `tab_widths` are public mutable lists on a mixin; the invariant only keeps their counts equal. SW_DOCK_ZONE's old lists were equally public, so this is not new, but the mixin is the place to tighten it: `feature {SW_TAB_STRIP}` for the lists plus `tab_left_of (i)` and `tab_width_of (i)` queries. Check testing/ before narrowing.

### 12. LOW, sw_tabs.e:572 versus sw_select.e:166-171

Two different chevron drawings in the library (a painter glyph here; two hand-drawn lines with literal 5.0, 10.0, 1.6 in SW_SELECT). Move SW_SELECT to `Glyph_chevron_down` when it is next touched.

### 13. LOW, sw_tabs.e:693-698 (`drag_threshold`)

The drag slop is `tab_gap` (half the theme padding). A spacing token does the job of an input constant, and with `padding` 0 the threshold is 0, so any jitter during a press starts a drag and a click can reorder. Fix: a scaled `Drag_slop` constant (or a theme token shared with SW_SPLITTER).

### 14. LOW, sw_tabs.e:690, 659-663 (`armed_close` by index)

`armed_close` stores a tab index, not the page. If tabs change between press and release (a programmatic close or move from a timer), the release can close whatever tab now stands at that index when the pointer is over its box. `close_tab` and `swap_with_next` do not clear it (`close_tab` does call `end_drag`). Fix: clear `armed_close` in both, or store the page and compare identity at release.

### 15. LOW, sw_tabs.e:140-145 (`is_placed`)

`is_placed` means "counts match", not "geometry is fresh". It cannot see a changed label, `set_tab_closable`, a `text_scale` change, or an edit to the exported `labels` list. Hit tests and `close_box_at` then use boxes measured for the old state until the next arrange. Fix: a `placement_stale` flag set by `set_tab_closable` and a `set_label` command (and make `labels` read-only to clients), cleared by arrange.

## Verified correct (traced, not run)

- `close_tab` bookkeeping (373-418): all four parallel lists are removed at the same index; `forget_placement` and `end_drag` run before any callback; a closed selected tab gives `a_i.min (pages.count)`; closing an earlier tab decrements `selected_index` without `on_change` (documented); closing a later tab leaves it; empty gives 0 and `first_visible` 0; `first_visible` is clamped to 1..count. The invariants hold on every path. `ensure_built (selected_index)` builds the neighbor before `on_close`.
- `move_tab` (420-455): both directions swap adjacent pairs; `swap_with_next` swaps all four lists and re-points `selected_index`, so the selection follows the page; `a_from = a_to` does nothing and fires nothing.
- Drag state (623-651): after `move_tab` the dragged index advances with the boxes; `swap_adjacent_boxes` keeps the first left and rebuilds the second with the old gap; the opposite-direction loop cannot undo a move just made (the pointer is past the old neighbor midpoint, which is beyond the new one). `end_drag` runs on press, release and close; the window routes release to the captured widget (sw_window.e:1655-1660), so a drag released off the bar still ends.
- Placement: the fit test `l_x + natural <= a_left + a_room` matches `run_width` (gaps between tabs only), so `has_overflow`, `first_showing` and placement agree; `l_full` stops later small tabs from jumping the queue; the SHRINK result matches the old SW_DOCK_ZONE arithmetic (equal shares, floor 1.0), with `width - 4.0` now floored at 0.
- SW_DOCK_ZONE on the mixin: `tab_at` guards `tab_ids.count = tab_lefts.count`, `forget_placement` runs before `tab_ids` is refilled, the strip uses `y` and `bar_h`. Behavior is preserved.
- Contracts in the new code are O(1); no across or MML anywhere in the diff.

## Test gaps (testing/sw_tabs_assault.e, 11 tests)

No narrow or zero-width arrange (finding 1), no zero inset (finding 2), no `text_scale` change, no `move_tab` with a hidden tab (finding 7), no lazy page closed or moved, no `on_close` that adopts the page (finding 6), no close while armed (finding 14), no zero-tab arrange.

## Recommended order

1. Findings 1 and 2: small changes plus a width and spacing assault test; they stop a contract abort.
2. Finding 3: move natural width, strip height and the inset into SW_TAB_STRIP (removes the drift between the two strips).
3. Findings 4 and 5 together: shared tab drawing plus tokens (`border_width` for the page gap and margins, a scaled underline and top inset).
4. Findings 6 and 7: contract wording and the hidden-tab swap.
5. Findings 8 to 15 as cleanup when the file is next opened.

Nothing was extracted or edited; these are proposals for Larry's word.
