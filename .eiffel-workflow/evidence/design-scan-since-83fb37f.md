# Design Scan (diff mode): simple_widgets, since 83fb37f
# Date: 2026-10-26
# Subjects: src/sw_window.e (the only src class changed; "Reference marks" feature, lines 2943-3099 in the current file, commit ff9a177 merged as 46861e7, version 0.41.0)
# Compared against: all of src/ (read-only scan; no source modified, nothing compiled)

## Summary

| Severity | Count |
|----------|-------|
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 2 |

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | A5/D1 | draw_reference_tip is a copy of draw_tooltip, already drifted (gap 4 vs 6, flip 30 vs 32) |
| 2 | MEDIUM | T1 | Reference marks hard-code every size and ignore theme.text_scale; sibling chip code uses theme tokens |
| 3 | MEDIUM | A5 | Rectangle hit-test loop in reference_mark_at is a second copy of the loop in tab_at; SW_WIDGET.contains has the same test |
| 4 | MEDIUM | A6/M4 | Reference-mark state and behavior (four attributes, six features) are a helper-object candidate inside a 3519-line SW_WINDOW |
| 5 | LOW | A5 | Pill drawing (full-radius rounded rectangle plus centered label) exists in SW_BADGE and SW_SEGMENTED; no shared painter helper |
| 6 | LOW | G1 | reference_marks is a TUPLE list kept parallel to mark_rects; one list of a small record class would remove the parallel-list invariant |

## Detailed Findings

### Finding 1: draw_reference_tip duplicates draw_tooltip (HIGH)
**Category:** A5 plus D1 (the copies have already diverged)
**Classes:** src/sw_window.e only (both features live in SW_WINDOW)
**Evidence (read):**
- src/sw_window.e:2924-2942 `draw_tooltip (a_w)`: set Role_ui 10.5 not bold; width = advance + 18.0; x clamped with `.min (win_w - tw - 4.0).max (4.0)`; `ty := a_w.y + a_w.height + 6.0`; flip above when `ty + 26.0 > win_h` to `a_w.y - 32.0`; fill `theme.ink` with `rrect_fill (tx, ty, tw, 26.0, t.radius)`; text in `theme.background` at `(tx + 9.0, ty + 17.5)`.
- src/sw_window.e:3080-3099 `draw_reference_tip (a_mark)`: the same sequence line for line, with the pill box (`mark_rects.i_th (a_mark)`) as the anchor and `code + "  " + tip` as the text; the gap is 4.0 (not 6.0) and the flip offset is 30.0 (not 32.0).
**Drift:** the numbers differ for the same role (a hint box placed under an anchor, flipped above near the bottom edge). Whichever number is chosen, one hint will sit 2 pixels differently from the other. The copy that should win is draw_tooltip (the established hint).
**Proposal:** extract one feature in SW_WINDOW, for example `draw_hint (a_text: READABLE_STRING_GENERAL; a_left, a_top, a_bottom: REAL_64)`, that owns the font, box width, clamp, flip, fill and text. `draw_tooltip` calls it with the widget's x, y + height, y; `draw_reference_tip` calls it with the pill's x, y + h, y. Use one named gap constant. Any future change (scaling, shadow, wrapping) then lands once.
**Before/after test idea:** a test in testing/sw_chrome_assault.e that renders a window with a tooltip widget and a reference mark whose anchor boxes share the same bottom edge, and compares the hint rectangles (expose the last hint box as a query, like SW_CHART.last_chip). Before: the two hint tops differ by 2 pixels. After: they are equal, and both flip above the anchor when the anchor is within 26 pixels of the window bottom.
**Effort:** 1 feature extracted, 2 callers.

### Finding 2: Token drift in the pills (MEDIUM)
**Category:** T1
**Evidence (read):**
- src/sw_window.e:3016-3018: `Mark_fill: NATURAL_32 = 0xC2410C`, a constant private to SW_WINDOW. The comment says it is deliberately the same in both themes, so a fixed color is defensible, but it belongs in SW_THEME as a named token.
- src/sw_window.e:3039 `painter.font (Role_mono, 10.5, True)`; 3049 `+ 14.0`; 3048 `l_h := 19.0`; 3051 and 3056 `6.0`; 3067 `7.0` and `13.5` text offsets; 3087-3098 `18.0`, `26.0`, `4.0`, `30.0`.
- Contrast: src/sw_chart.e:209-229 `draw_chip` takes the font size from `theme.size_chip`, padding from `theme.padding * 0.625`, height from `a_p.text_extent`, radius `3.0 * theme.text_scale`; src/sw_badge.e:98 uses `size_chip`. When `theme.text_scale` is raised (SW_THEME:511-522), chips and badges grow but the pills and hints stay at 10.5 pixels in a fixed 19-pixel box.
**Proposal:** derive the pill from `theme.size_chip`, `theme.padding` and `painter.text_extent` as SW_CHART.draw_chip does; move the fill into SW_THEME. The tooltip has the same literals; fixing both through Finding 1's `draw_hint` fixes both.

### Finding 3: Rectangle hit-test loop copied (MEDIUM)
**Category:** A5
**Evidence (read):**
- src/sw_window.e:2956-2980 `reference_mark_at`: loop over `mark_rects` testing `a_x >= x and a_x <= x + w and a_y >= y and a_y <= y + h`.
- src/sw_window.e:3405-3423 `tab_at`: the same loop over `tab_rects` (fields rx, ry, rw, rh) with the same four comparisons.
- src/sw_widget.e:73 `contains (a_px, a_py)` is the same test for widgets; src/sw_status_section.e:78 `has_point` the same on one axis; sw_window.e lines 3258, 3355, 3381, 3388, 3396 repeat the one-axis form for drawer parts.
**Proposal:** one small shared record, for example SW_RECT (x, y, width, height, `contains (px, py)`), used by tab_rects, mark_rects and the drawer hit areas; at the minimum a single `rect_has (a_px, a_py, rx, ry, rw, rh)` query on SW_WINDOW. Not HIGH because the copies agree today (both inclusive on all four edges).

### Finding 4: Reference marks as a helper object (MEDIUM)
**Category:** A6 plus M4
**Evidence (read):** src/sw_window.e is 3519 lines. The feature adds attributes `reference_marks`, `reference_marks_shown`, `hovered_reference_mark`, `mark_rects`; features `reference_mark_at`, `add_reference_mark`, `set_reference_marks_shown`, `follow_reference_mark`, `draw_reference_marks`, `draw_reference_tip`; and four Corner_ constants. It touches the rest of the window at only three seams: initialization (lines 89-90), pointer motion and leave (2248-2250, 2254), and render (2737-2739). The lens (`create lens`, line 86) already follows the helper-object pattern.
**Proposal:** a class SW_REFERENCE_MARKS holding the list, the drawn rectangles, the hover index, hit test, draw and tip; SW_WINDOW keeps one attribute and forwards three calls. This is also the natural home for the Finding 1 and 3 helpers. Only SW_WINDOW owns marks, so a helper object fits better than a shared deferred ancestor. Keep `add_reference_mark`, `reference_mark_at` and the others as thin forwarders so testing/sw_chrome_assault.e:330-359 is unaffected. Only on Larry's word.

### Finding 5: No shared pill primitive (LOW)
**Category:** A5 (small)
**Evidence (read):** src/sw_badge.e:126 `rrect_fill (x, y, width, height, height / 2.0)` with a centered caption; src/sw_segmented.e:174 and 185-189 the same radius rule; src/sw_window.e:3062 and 3064 fill and stroke the pill.
**Answer to the question asked:**
- SW_BADGE is a layout-placed widget (it needs a parent and a rectangle), so the window cannot reuse it as an overlay without adding it to the widget tree.
- SW_CHIP (src/sw_chip.e:121) uses `t.radius`, a rounded rectangle, not a pill.
- DEV_LENS.draw_chip (src/dev_lens.e:32-34) is a release-build stub with an empty body; nothing to reuse.
- SW_CHART.draw_chip (src/sw_chart.e:209) is bound to the chart frame (clamps to it); its drawing body could be lifted to SW_PAINTER as a general chip primitive.
So there is no directly reusable helper today. Low priority: a few lines of repeated geometry.

### Finding 6: Parallel lists (LOW)
**Category:** G1
**Evidence (read):** src/sw_window.e:2946 `reference_marks: ARRAYED_LIST [TUPLE [widget, code, tip, corner]]` and 3015 `mark_rects: ARRAYED_LIST [TUPLE [x, y, w, h]]`, linked only by the postcondition `parallel` (line 2993) and the else branch at 3069-3071. One record class holding the rectangle as attributes removes the parallel invariant and lets Finding 4 carry a class invariant instead.

## Recommended Order
1. Finding 1 (live drift; one feature) together with Finding 2 (fixes tooltip and tip at once).
2. Finding 3 (tiny helper; unblocks Finding 4).
3. Findings 4 and 6, only on Larry's word.
4. Finding 5 last, optional.
