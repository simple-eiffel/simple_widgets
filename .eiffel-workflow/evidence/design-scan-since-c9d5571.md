# Design Scan (diff mode): simple_widgets, since c9d5571 (main 2f4a729)
# Date: 2026-10-25
# Mode: read-only, nothing compiled, no source edited
# Subjects: SW_ERA_YEARS, SW_TIMELINE_ITEM, SW_LANE_TIMELINE (GW-17, 0.35.0); test class SW_LANE_TIMELINE_ASSAULT
# Compared against: all of src (SW_SCALE, SW_GANTT, SW_TIMELINE, SW_MAP, SW_DIAGRAM, SW_TABS, SW_ACCORDION, SW_LIST, SW_PAINTER)
# Spec: simple_bible research 11-HISTORY-TIMELINE, sections 5.2 and 9

## Summary

| Severity | Findings |
|----------|----------|
| HIGH     | 5  |
| MEDIUM   | 14 |
| LOW      | 13 |
| **Total**| **32** |

Categories used: D1 drift, A5 duplicated body, A6 helper candidate, T1 token drift, SPEC (spec violation), CONTRACT, PERF, TEST, A11Y.

## HIGH

### H1. SPEC. A dispute with positions in several lanes keeps only the last lane's envelope
sw_lane_timeline.e:353 (`envelope_boxes` is parallel to the DISPUTES, one box each), :481-485 (`ey` set per lane), :862-864 (`ex`, `ew`, `eh` overwritten per lane in `place_dispute`).
Scenario: "Crucifixion" has positions in the Rome lane and in the Church lane. `arrange` places Rome first and fills envelope_boxes[d]; then the Church lane overwrites ex, ew, eh and ey. Only the Church envelope is drawn; the Rome positions are stacked with no envelope. Spec section 9: all positions "stacked and bracketed, inside the dispute's envelope". The test (assault:91-122) uses one lane, so it cannot see this.
Fix: key envelopes by (dispute, lane): a list of tuples [dispute, lane, ex, ey, ew, eh] rebuilt per arrange, or an array indexed (dispute - 1) * lane_count + lane. Add a two-lane test.

### H2. SPEC. A one-year item of class B, C, D or F draws the class A tick: certainty is overstated
sw_timeline_item.e:70 (`is_point` is true for any one-year item except E and G); sw_lane_timeline.e:910-912, :917-918, :927-928 route those to `draw_tick`; :939 default also ticks.
Scenario: the pilot's "Qarqar" (class B, one year, assault:227) draws exactly like a class A "fixed to the day" tick, with no label. Class D (scientific range; spec asks for a gradient and a stated confidence) and class C (scheme badge) become the same solid tick. Spec 5.2: "shown with a pattern and a label, never color alone"; section 9: "a firm Roman date never lends its firmness to a soft Hopewell range". A reader cannot tell a day-fixed record from a year-fixed or scientific one.
Fix: `is_point` true only for class A. Other classes at one year draw their own pattern at a minimum width (the class G rule, 6 pixels), keeping the class pattern. Add a per-class drawing test (see M14).

### H3. SPEC. Dispute positions are hidden one at a time, so a dispute can disappear or look settled
sw_lane_timeline.e:727-731 (`is_shown_now` tests each item's own importance and view overlap), :458 and :733-742 (`positions_shown`), :113-126 (`add_position` leaves importance at Major).
Scenarios: (a) at millennium scale (4 years per pixel and up) every dispute position is hidden, with no trace that a dispute exists, against "disputes are drawn, not hidden". (b) One position is set to Detail and its rival is Major: at century scale only one position draws, inside an envelope sized for one row, so a disputed event reads as settled. (c) One of two positions is scrolled just off the view: the envelope shows one position.
Fix: decide visibility per DISPUTE: if any position qualifies, draw all positions of the dispute in that lane (or at least a stub "N positions" bracket when the zoom hides the labels). Store importance on the dispute and let positions inherit it.

### H4. SPEC/D1. Ticks sit at the start of the year; the cursor and the axis use the middle
sw_lane_timeline.e:804-808 (a point box is centered on `year_x (year_from)`, the left edge of the year cell) against :561 and :1037 (`year_x (cursor_year + 0.5)`) and :989 (`year_x (yr + 0.5)`); `contains` (sw_timeline_item.e:81) defines a year as [y, y+1).
Scenario: at the closest zoom (2 years across about 900 pixels, one year is about 400 pixels) an item at AD 30 draws 200 pixels left of the cursor set at AD 30 and of the axis label "AD 30". Bars use [from, to+1), so the tick convention differs from the bar convention in the same widget.
Fix: center points on `year_x (year_from + 0.5)` (or the range midpoint); one helper `year_center_x` used by tick, cursor and axis. Put it with the shared year-to-pixel code (see M8).

### H5. SPEC. No vertical scroll; content past the widget height is unreachable; `preferred_height` under-reports
sw_lane_timeline.e:408-412 (`axis_h + (lane_count + 2) * row_h` ignores stacked rows, group headers and folds), :441-492 (lanes laid out downward without a limit), :510 and :543 (clip at the widget height), :620-631 (the wheel is consumed for zoom).
Scenario: the spec's world timeline has many lanes (Israel, Rome, Parthia, Han, Kush, Aksum, Church, and more) and busy lanes stack into many rows. Lanes below the widget bottom cannot be seen or clicked; a host that reads `preferred_height` for a scroll area gets a number that is too small.
Fix: inherit the SW_VSCROLLING mixin (the library's shared vertical scroll protocol) and compute `preferred_height` from the real layout total (`cy` after the lane loop). Shift plus wheel, or wheel over the label column, scrolls.

## MEDIUM

### M1. SPEC. Class D has no stated confidence, class E no defining authority, and the "provenance badge" is the scheme badge
sw_timeline_item.e:50-52 (`badge` is a single free string: "class C names its scheme"); sw_lane_timeline.e:916-922 (D draws a fade, no confidence), :923-925 (E: translucent fill, no outline). Spec 5.2: D "with stated confidence (68% / 95%)", E "period name, defining authority"; section 9: "a provenance badge (P1, P2, P3)".
Scenario: Teotihuacan's Sun Pyramid (D) shows a gradient with no 68 or 95 percent; a class C item with an empty badge is legal; the scheme and the provenance grade cannot both be shown. Class E rests on alpha 0.18 of the accent, which is color strength alone, against "never color alone".
Fix: add `confidence_label` (D), `authority` (E), `grade` (P1 to P3) and `scheme` to SW_TIMELINE_ITEM; require a scheme for class C; give E a thin solid or dotted outline so it has a pattern in both themes.

### M2. Inside label is cut off when the bar starts left of the view
sw_lane_timeline.e:946-948 (`l_text_x := b.bx + 4.0`), :907 (`l_inside` uses the full bar width).
Scenario: "Principate" (-26 to 284) viewed from AD 0: the bar starts at a negative x, the label is drawn at that x plus 4, wholly under the clip: the period's name is invisible while its bar shows.
Fix: `l_text_x := b.bx.max (plot_left) + 4.0` and test `l_inside` against the visible part of the bar.

### M3. Selection is recorded but never drawn
sw_lane_timeline.e:305 and :596-600 set `selected`; `draw_item` (893-962) never reads it. The clicked event shows no feedback; the spec's "both views share one selection" has no visible side on the timeline.
Fix: draw a stroke (accent, 2 pixels) around `selected`'s box; clear `selected` when its lane folds.

### M4. A press always moves the cursor, so every pan starts by firing `on_cursor`
sw_lane_timeline.e:586-605 (`handle_click` runs on the press and falls through to `set_cursor`), :607-618 (the drag pans afterward).
Scenario: dragging to pan the view moves the synchronism cursor to the press year and fires `on_cursor` (a host will reload the slice) once per drag; a drag that starts on a group header folds it first.
Fix: on press only arm the pan; set the cursor, select or fold on release when no pan happened (SW_TABS has the same press/drag split with a `drag_threshold`, sw_tabs.e:643, :707).

### M5. Label and lean text overflow: stacking ignores the lean, nothing flips at the right edge
sw_lane_timeline.e:798-820 (`reach` covers the title and suffix only), :956-961 (lean marker and wording are drawn after, past `reach`).
Scenario: "AD 33" with the lean note "AD 33 over AD 30: 0.60, a lean, not consensus" is drawn over the next item on the same row; at the right edge the text is clipped silently, so the lean wording (required by spec section 9) can be unreadable.
Fix: include the lean width in `item_span`'s `reach`; when `reach` passes the plot right edge, draw the label to the LEFT of the box (right-aligned) or on its own row.

### M6. PERF. `arrange` is O(lanes x disputes x items); `slice` is O(lanes x items) and runs on every accessibility query
sw_lane_timeline.e:457-486 per (lane, dispute): `positions_shown` (733-742, a full scan), again at :482, `first_row_of` (744-755, a full scan), and `place_dispute` calls `lane_order` (702-725: a scan plus insertion sort, worst case quadratic for descending input) at :850; :466-471 and :474-479 rescan all items per lane; :274-300 scans all items for each lane; :662-671 calls `slice` for every value query.
Estimate: 1,000 items, 30 lanes, 100 disputes: about 6 million cursor steps per arrange (not quadratic in items, but the dispute count scales with the item count); 5,000 items, 50 lanes, 500 disputes: about 375 million. `free_block` (757-785) adds O(rows x block size) per item.
Fix: one pass over `items` building per-lane lists and per-(dispute, lane) lists (bucket by lane once, sort each bucket once), then lay out from the buckets; make `slice` one pass plus a stable bucket by lane. The `slice` postcondition (299) is cheap (O(result x collapsed groups)) and fine; all class invariants (1044-1047, sw_timeline_item.e:134-138) are O(1).

### M7. A11Y. Keyboard cannot set the cursor, select, or fold; the accessible value is only a count
sw_lane_timeline.e:633-648 (Left, Right, plus, minus, Home only), :662-671 (the value is "AD 30: 3 items"; the feature comment at :663 says it also says what stands there).
Scenario: a keyboard or screen-reader user cannot place the cursor, open an item, fold a group, or hear which items are in the slice. No Up/Down, Enter or Space, no lane or item focus. `handle_key` ignores `is_enabled` (the pointer handlers check it).
Fix: add item and lane focus (arrow cycling), Enter to select, Space to fold a header, a key to set the cursor at the view center; make `accessible_value` list the item titles with their certainty class names ("Augustus, fixed to the year").

### M8. A5/A6. Year-to-pixel mapping written by hand next to SW_SCALE; the two copies already disagree
sw_lane_timeline.e:331-341 (`year_x` divides by `plot_w`, `year_at` by `plot_w.max (1.0)`: with a plot narrower than one pixel they are not inverses); SW_SCALE (`position`, `value_at`, `tick_step`) is used by SW_GANTT (sw_gantt.e:74, :127-151). Tick ladders also differ: SW_ERA_YEARS.nice_step (sw_era_years.e:108-130, a lookup that allocates an array per call) against SW_SCALE.tick_step (1.5, 3, 7 thresholds).
Fix: hold one SW_SCALE (domain view_from..view_to, range plot_left..plot_left+plot_w), set in `arrange`. SW_SCALE requires range_min /= range_max, so guard `plot_w` at 1 pixel the way `year_at` does. Keep SW_ERA_YEARS only for the BC/AD joint (ticks on displayed years); take the step ladder from SW_SCALE.

### M9. A6. Wheel zoom ignores the notch size and jumps when the pointer is off the plot; pan duplicates SW_MAP
sw_lane_timeline.e:620-631 (any positive delta is 0.8, any negative 1.25), :163-178 (an anchor outside the plot clamps `l_t` to 0 or 1, so the zoom pivots on a view edge). SW_MAP.handle_wheel (sw_map.e:161-205) scales per 120-unit notch and falls back to the plot center when the pointer is outside. Pan: sw_lane_timeline.e:586-592 and :607-618 (press offset) against sw_map.e:209-243 (`begin_pan`, grab the ground under the pointer): both are a "grab the ground" pan with their own state.
Scenario: a precision touchpad sends many small deltas: each event zooms 25 percent, so the timeline races. The mouse over the lane-label column zooms about the left edge.
Fix: one deferred ancestor inherited side by side (for example SW_ZOOM_PANNING: view window, `zoom_about`, `pan_to`, notch-aware wheel step, drag grab with a threshold), with SW_MAP using two instances or a 2-D twin. The helper-object candidate is the window state plus the drag grab.

### M10. CONTRACT. Stale parallel lists break `draw` when data is added after the last arrange
sw_lane_timeline.e:555, :532, :545 (`item_boxes.i_th (it.id)`, `lane_heights.i_th (l)`, `envelope_boxes.i_th (i)` without the count guard that `item_at` has at :377); the invariant (1044-1047) does not relate them to `items`. Data is "data, not code": an asynchronous load adding an item between two frames hits an `i_th` precondition (finalized code: undefined behavior).
Fix: guard `draw` on `item_boxes.count = items.count` and the lane and dispute counts, or mark the layout dirty in `add_lane`, `add_item`, `add_dispute`, `toggle_group`, `set_view` and arrange lazily at the top of `draw`.

### M11. Hit testing: hidden items under the label column, no hit slop, labels not clickable
sw_lane_timeline.e:372-392 (boxes only; no plot-bound test, so an item whose box starts left of the plot is selected by a click on a lane label), :964-974 (a tick box is 6 pixels wide), and the label text beside a box is outside its box.
Fix: clamp the hit box to the plot, widen ticks to a theme control size for hit tests, and include the label run in the hit box.

### M12. SPEC. `slice` says "visible" but lists off-view items; the cursor chip is parked at the edge when the cursor is off the view
sw_lane_timeline.e:274-300 (no test that `a_year` lies inside view_from..view_to or that the item is shown), :1037 (the chip clamps to the plot edge, and when `plot_w < l_w` the `min` wins and the chip leaves the plot).
Scenario: cursor AD 30, user pans to 500 BC: the chip sits on the left edge as if it marked a place, and `slice` still lists items that are not on screen (the accessible value reports "3 items" for nothing visible).
Fix: draw an off-screen marker (an arrow chip "AD 30 >") and say so in the accessible value; either document that `slice` is about lane data at the zoom level or restrict it to shown items.

### M13. A5. Group header fold code copies SW_ACCORDION and draws the same chevron in an if and else
sw_lane_timeline.e:516-522 (both branches call `set_color (t.ink_muted)`; only the glyph differs), :212-249 (fold list by group name), compared with sw_accordion.e:92 (`toggle_section`) and its chevron, right when shut and down when open (sw_accordion.e:206).
Fix: a shared foldable-header-row helper (chevron, title, `is_open`) used by SW_ACCORDION, SW_TREE and the timeline; at minimum collapse the if and else to one `glyph` call with a chosen constant.

### M14. TEST. Several assertions are vacuous or tautological; the certainty classes are not tested at all
- assault:65-87 axis labels: the assertion repeats the very filter that builds `axis_labels` (sw_lane_timeline.e:991), so it cannot fail; the lane has no items; no check that "1000 BC" is present or that no label overlaps another.
- assault:121 `tl.selected = Void`: nothing in the test sets it, so it is true by construction; it does not test "lean never pre-selected" (click an item and verify the lean one is not chosen; verify the lean marker is drawn).
- assault:41-46 loops `display_year`, which has its own postcondition; it never tests `label`, the feature that makes the text.
- assault:184 and :190 accept one year of error (about one pixel at that zoom), and the half-year tick offset (H4) passes.
- assault:246 `slice (30).count >= 2` would pass with extra items; the pilot (:207-253) writes a PNG but compares nothing and ignores the return of `write_frame`.
- Not tested: class A to G drawing (would catch H2), a dispute across two lanes (H1), hidden positions (H3), pan and keys, BCE label, dark-theme assertion, accessible value, label overflow, folding the lane that holds the selection, the cursor off the view, years near the integer limits.
Fix: assert on `item_boxes` and a recording painter (or the SW_PAINTER call log) with one assertion per class.

## LOW

### L1. Integer overflow in year arithmetic
sw_lane_timeline.e:730, :804-805, :151, :155 (`year_to + 1`); sw_timeline_item.e:81; sw_era_years.e:33 (`1 - a_year` at the minimum integer) and :53. `add_item` accepts any INTEGER. At 2147483647 the sum wraps negative; at the minimum integer `display_year` returns a negative and breaks its own `never_zero` postcondition.
Fix: bound years in the preconditions (for example plus or minus 1,000,000,000, far beyond Max_span) and say so in the class note.

### L2. Unbounded pan can overflow `ticks`
sw_lane_timeline.e:180-184 (no clamp) with sw_era_years.e:144-156 (`.ceiling` and `.floor` into INTEGER). After the view passes the integer range the tick range is garbage (possibly a very long loop). Fix: clamp the view to the data bounds plus a margin in `pan` and `zoom_about`.

### L3. Axis labels can overlap at the widest span
sw_era_years.e:115 (the step ladder ends at 5000) with sw_lane_timeline.e:985-993 (only the plot edges are checked). At the 20,000-year maximum span in a narrow plot (about 200 pixels) the 5000-year step gives 40-pixel spacing with 50-pixel labels. Fix: extend the ladder (10000, 20000) and skip a label that would touch the previous one.

### L4. `fit_all` can silently truncate
sw_lane_timeline.e:144-161 with :139 (`set_view` keeps `a_to.min (a_from + Max_span)`): items spanning more than 20,000 years are cut, though Home is documented as "fits everything". Fix: raise `Max_span` or document the cut.

### L5. T1. Hard-coded pixel values that belong in tokens
sw_lane_timeline.e: `Gap` 6.0 (:678); row inset 3.0 and `row_h - 6.0` (:478, :834, :857); minimum widths 6.0 and 3.0 (:806-812); tick half-height 2.0 and diamond 4.0 (:964-974); label padding 8.0 (:814, :907, :957); text inset 4.0 (:947, :949, :960); `label_w - 4.0` (:537); drag threshold 4.0 (:612; SW_TABS derives its threshold from `tab_gap`, sw_tabs.e:707); 90.0 pixels per axis label (:985); dash widths 1.5 and 1.0; hatch spacing 5.0 (:935); envelope inset 2.0 and 4.0 (:862-864); axis tick 6.0 (:1018); class E alpha 0.18 (:924); chip inset 2.0 (:1039); pan 0.1 and zoom 0.8 and 1.25 (:627, :637-643).
Tokens: SW_THEME.padding and control_inset for insets; new `item_inset`, `hit_slop`, `drag_threshold`, `hatch_spacing`; zoom and pan factors as public settings. None scale with the theme or display scaling, while `row_h` does (derived from the font).

### L6. Class A range drawn as a point; class E and G minimum widths differ
sw_timeline_item.e:70 (class A with `year_from < year_to` is a point), sw_lane_timeline.e:806-812 (G at least 6 pixels, others 3). A day-fixed event cannot be a range, so `make` should require `a_from = a_to` for class A; the 3-pixel class E sliver is below the class G floor.

### L7. Allocation per call
sw_era_years.e:112-115 (an array per `nice_step`), sw_lane_timeline.e:871 (`title.twin` per item per arrange and per draw), :875-890 (`item_suffix` builds a string three times per item in `draw_item`), :217 (`is_group_collapsed` per lane per frame). Cache the label per item when the title or class changes; make the ladder a once-constant.

### L8. Semantic zoom thresholds are fixed pixel ratios and not settable
sw_lane_timeline.e:195-209 (`Millennium_scale` 4.0 and `Century_scale` 0.4 years per pixel). The same data changes level when the window is resized; at 900 pixels the "millennium" threshold is a 3,600-year span and "century" 360 years. Make them settable and state the intended spans in the contract.

### L9. CONTRACT. `is_item_shown` precondition is O(n) and weak
sw_lane_timeline.e:364-370 (`items.has (a_item)` scans the list, and the body trusts `id = index` without saying so). Replace with `a_item.id >= 1 and a_item.id <= items.count and items.i_th (a_item.id) = a_item` (O(1)) and add an invariant that item ids are their positions. `set_view` postcondition (141) says nothing about `view_to`.

### L10. Row stacking is conservative and depends on dispute order
sw_lane_timeline.e:457-471, :757-785, :787-796: each row keeps one maximum end, and disputes are placed before the rest in dispute-number order, so a dispute at the right of a lane can force an earlier item onto a lower row. No overlap results, but there are extra rows and a layout that changes with the dispute numbering. Place everything by start year with the dispute blocks inline.

### L11. Key codes are numeric literals
sw_lane_timeline.e:636-646 (37, 39, 107, 187, 109, 189, 36). SW_LIST does the same (sw_list.e:231-239) and SW_KEYS exists (sw_keys.e); name them in one place.

### L12. `fit_all` margin is not kept by zoom and pan
`fit_all` gives a 5 percent margin (sw_lane_timeline.e:158), but `zoom_about` and `pan` can leave all data behind with no way back except Home. Offer `clamp_to_data` as a setting.

### L13. Possible cost of hatching very wide boxes (unverified)
sw_lane_timeline.e:933-937 draws a hatched band from the true box (a class G item of 2,000 years at the 2-year minimum span is hundreds of thousands of pixels wide); `hatch_rrect` clips to the path but `draw_hatch` receives the unclipped rectangle (sw_painter.e:605-614). Not measured. Safer: intersect every box with the plot before drawing.

## Recommended order

1. H1, H2, H3, H4: spec drift in the drawing of certainty classes and disputes (all in sw_lane_timeline.e and sw_timeline_item.e); add per-class and multi-lane tests with them (M14).
2. H5 with M6: scrolling and the layout cost share the same bucketed pass; do the bucket refactor first.
3. M8, M9 (one year-window abstraction shared with SW_MAP and SW_SCALE, inherited side by side), then M4 (press versus release), which depends on it.
4. M1, M2, M3, M5, M7, M10, M11, M12.
5. Tokens (L5) and the remaining LOW items.
