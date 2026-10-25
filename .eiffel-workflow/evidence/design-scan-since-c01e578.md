# Design Scan (diff mode): simple_widgets since c01e578 (main aabcd2f)
# Date: 2026-10-25
# Subjects: src/sw_painter.e (GW-18 0.34.0: stroke styles, hatch fills, gradients) and testing/sw_strokes_assault.e
# Compared against: all of src/ (read-only scan; nothing compiled, nothing edited)

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / duplication / drift | 3 | 0 | 1 | 2 |
| Tokens | 2 | 0 | 2 | 0 |
| Cost, preconditions, correctness | 5 | 1 | 2 | 2 |
| Cairo state and lifetime | 2 | 0 | 0 | 2 |
| **Total** | **12** | **1** | **5** | **6** |

Clean results (checked, no finding): no widget draws its own dashes or hatches today
(no set_dash, clear_dash or hatch loop outside the painter; chart and Gantt gridlines
are solid one-pixel rectangles through hline and vline, so there is no hand-drawn dashed
gridline to replace); every context.save in the new code is matched by a restore on the
normal path; the gradient is destroyed after the restore, and cairo takes its own
reference when a pattern becomes the source and the saved state restores the previous
source, so the destroy is safe.

## Findings

### 1. HIGH - Dot hatching has a quadratic cost with no bound
File: src/sw_painter.e, draw_hatch dots branch (nested loops, about lines 748-770); entry points hatch_rect, hatch_rrect, hatch_polygon (about lines 543-612).
Scenario: hatch_rect over a 10000 by 10000 box (a zoomed map region, a Gantt bar on a huge date range, a polygon whose bounding box extends far off screen) with Hatch_dots and spacing 4 builds (10000/4)^2 = 6.25 million arc sub-paths in one path before a single fill, which stalls the interface thread and exhausts memory. The line kinds are linear (about (w+h)/gap segments) and survive far larger boxes, but they share the flaw: the loop covers the whole box, not the visible part, and the clip only discards ink afterwards. hatch_polygon is worst because its box is the polygon bounding box, not the visible portion.
Fix: bound the work to the visible area. simple_cairo has no clip_extents (checked cairo_context.e), so either add clip_extents to simple_cairo (the right home) and intersect the box with it before looping, or give the painter a precondition `bounded: marks_in (a_w, a_h, a_spacing) <= Max_hatch_marks` with a named constant. Start the loops at the first grid line at or after the clipped left or top edge so the phase stays anchored (see finding 6).

### 2. MEDIUM - Channel math is now copied in four places; the heatmap copy has drifted
Files: src/sw_painter.e channel_of (about line 797), src/sw_painter.e set_color_alpha (lines 398-403, the same shift-and-mask math inline in the same class), src/sw_heatmap.e blend (lines 128-144), src/sw_theme.e mixed and mixed_channel (lines 785-800), src/sw_color_picker.e (lines 158-160).
Divergence: SW_THEME.mixed clamps each channel with min (255) and its contract proves exact endpoints; SW_HEATMAP.blend neither clamps nor masks. SW_HEATMAP.blend is a second, weaker implementation of SW_THEME.mixed. The new channel_of is a further unpack that set_color_alpha, a few lines away, does not use.
Failure scenario: any future change to rounding or clamping (for example gamma-correct blending) lands in one copy, and the heatmap ramp, the theme ramps and the painter gradient disagree on the same two colors.
Fix: set_color_alpha should call channel_of (same file, no risk). SW_THEME.mixed is `feature {NONE}` (section at line 742), which is why the heatmap could not call it: export it (or move color unpacking and mixing into a small deferred mixin, for example SW_COLOR_MATH, inherited side by side by SW_THEME and SW_PAINTER) and delete SW_HEATMAP.blend, keeping the test at testing/sw_chart_assault.e line 269 pointed at the shared feature.

### 3. MEDIUM - Stroke and hatch widths use two different scaling conventions
File: src/sw_painter.e apply_stroke_style (about line 683) against draw_hatch (lines 708-709).
apply_stroke_style sets the line to a_width as given but computes the dash unit as a_width.max (1.0) * theme.text_scale. A caller who already scaled the width by the text scale gets dashes scaled twice, quadratic in the scale: at scale 3 and nominal width 2 (passed as 6) the dash is 4 * 18 = 72 pixels with a 54 pixel gap. A caller who passes the nominal width (as sw_gantt.e lines 181-183 pass 1.2) gets a line that does not scale and dashes that do. draw_hatch, by contrast, scales both the spacing and the line width by the scale and takes the nominal spacing. The contract never says which the caller owes.
Fix: pick one rule and state it in the header comment and a contract: widths and spacings passed to the painter are nominal pixels, scaled inside (hatch already follows this); then apply_stroke_style should set_line_width (a_width * text_scale) and use u := a_width.max (1.0) * text_scale.

### 4. MEDIUM - Hatch geometry is not snapped at fractional text scales
File: src/sw_painter.e draw_hatch (lines 708-709, 721-728); apply_stroke_style dash lengths.
Gap is spacing * scale and line width is scale.max (1.0), both fractional at 1.25 or 1.5. Lines land on fractional pixels with fractional width, so anti-aliased intensity alternates between rows (moire) and a 45 degree hatch looks uneven; dash runs of 4u and 3u are 5.0 and 3.75 pixels at 1.25. The tests run only at scale 1.0 (testing/sw_strokes_assault.e has no text_scale case).
Fix: round the gap to whole pixels (l_gap := (a_spacing * scale).rounded.max (2)), the hatch width to a whole pixel, and the dash unit likewise; add one assault test at scale 1.25 and 1.5 asserting the dash period.

### 5. MEDIUM - Zero, negative and oversized radius inputs are unchecked on every public entry
File: src/sw_painter.e hatch_rect, hatch_rrect, hatch_polygon, gradient_rect, fade_rect, dashed_rrect_stroke (about lines 543-690).
Negative w or h silently draws nothing for some hatch kinds (loop guards fall through) and a mirrored pattern for others; a_r larger than half the box makes rrect_path (line 1134) produce overlapping arcs and a clip that is not the intended shape. No contract says so, and the new tests contain no zero, negative, three-point or huge case (searched testing/sw_strokes_assault.e).
Fix: add `non_negative_size: a_w >= 0.0 and a_h >= 0.0` (an empty box is a legal no-op) and, on the rounded variants, `radius_fits: a_r >= 0.0 and a_r * 2.0 <= a_w.min (a_h)`, matching whatever rrect_fill already requires; add tests for zero size, a polygon with exactly 3 points, and a huge box (after finding 1).

### 6. LOW - Hatch phase is anchored to each shape, not the surface
File: src/sw_painter.e draw_hatch (starts at k = 0.0 or l_gap / 2.0 from the box corner), hatch_polygon (box is the polygon bounding box).
Two adjacent hatched regions (map regions, two Gantt bands) show a visible seam where the lines do not continue. Cosmetic today.
Fix: anchor k to a multiple of the gap in surface coordinates (k0 := floor (a_x / gap) * gap); this also gives finding 1 its natural loop start.

### 7. LOW - draw_hatch trusts the inherited dash and cap
File: src/sw_painter.e draw_hatch (lines 705-710), called inside save/restore by hatch_*; apply_stroke_style (lines 680-697).
draw_hatch sets the line width only. A caller that set a dash through the context directly before calling hatch_rect gets dashed hatch lines; likewise apply_stroke_style sets no explicit butt cap for the dashed and solid styles (only dotted and dash-dot set a round one), so a stray round cap from outside rounds the dashes. Nothing in the library does this today (the only set_line_cap calls are at sw_painter.e lines 690 and 693, both inside save/restore), so this is defensive.
Fix: begin draw_hatch with context.clear_dash and set_line_cap (0); begin apply_stroke_style with set_line_cap (0) before the inspect.

### 8. LOW - Dotted and dash-dot crowd at small scales and wide lines
File: src/sw_painter.e apply_stroke_style (lines 689-693).
Round caps extend each dash by half the width at both ends. At scale 0.5 (the minimum the theme allows, sw_theme.e line 515) with width 4: u = 2, dotted spacing 5 against a dot diameter 4, a visible gap of one pixel, which reads as a solid line; dash-dot gaps (3u = 6 minus 4 of caps) are 2 pixels.
Fix: for the capped styles add the cap to the pitch (spacing := 2.5 * u + a_width) or state the supported width range in a precondition.

### 9. LOW - New code and `line` use different state disciplines
File: src/sw_painter.e line (lines 409-415) against dashed_line (about lines 520-535).
The existing line (and polyline) reset the width to 1.0 by hand after stroking; the new methods use save and restore. Both are correct today, but a future stroke helper has two patterns to copy, and `line` still drops any width the caller had set.
Fix: move line and polyline onto the same save/restore bracket when next touched.

### 10. LOW - Unmatched save and unreleased gradient if a callee contract fails mid-call
File: src/sw_painter.e blend_rect (about lines 790-806) and the save/restore pairs in dashed_polyline and hatch_polygon.
Preconditions on the public routines run before any save, so a caller violation is caught before state changes. Inside, a violated callee contract (CAIRO_GRADIENT.add_stop_rgba requires channels and alphas in 0..1; set_dash requires some ink) would leave one saved level on the cairo stack and the gradient undestroyed in a contract-checking build. All inputs are validated by the public contracts today (alpha range on fade_rect; u is always positive), so it cannot trigger now. blend_rect has no alpha precondition of its own: it is private and only fade_rect (checked) and gradient_rect (constants) call it.
Fix: none required; if blend_rect is ever exported, move the alpha precondition from fade_rect onto it.

### 11. LOW - Gantt marks are candidate callers of the new painter features
File: src/sw_gantt.e lines 181-183 (dependency elbows drawn as three line calls at hard-coded width 1.2) and line 187 (today marker through vline, a one-pixel solid).
Not duplicates of the new code, but the natural first callers: a dashed today marker (dashed_line with Stroke_dashed in the danger color) and a dashed_polyline for provisional dependencies would make "today" and uncertainty distinguishable without color alone, the stated purpose of GW-18. The 1.2 and 6.0 literals belong in theme tokens (a line-weight token and a connector inset) with the scaling rule of finding 3.
Fix: when SW_GANTT is next touched; no new painter feature needed.

### 12. MEDIUM - Token drift: pattern constants are literals in the painter
File: src/sw_painter.e apply_stroke_style (lines 685-695: 4.0, 3.0, 2.5, 5.0, 0.5), draw_hatch (0.22 dot radius, minimum 1.0).
The dash lengths, dot fraction and gaps are the same role as other pattern metrics but live as bare literals in feature bodies, so a theme cannot make patterns coarser for accessibility and a second pattern consumer (a legend swatch drawing the same hatch in a key) has to repeat them.
Fix: named constants in the painter (Dash_on, Dash_off, Dot_gap, Dot_radius_fraction), or SW_THEME tokens (stroke_dash_unit, hatch_default_spacing) if themes should own them; they must scale (they already do through text_scale, see finding 3).

## Recommended Order

1. Finding 1 (cost bound; add clip_extents to simple_cairo, then bound the loops), the only live hazard.
2. Finding 5 (preconditions) together with finding 1, since both change the same entry contracts.
3. Finding 3 (one scaling rule) before any widget calls the stroke styles, so callers are written once.
4. Finding 2 (single channel-math owner; export or mix in SW_THEME.mixed, delete SW_HEATMAP.blend).
5. Findings 4, 6, 7 (pixel snapping, anchored phase, defensive reset) in one hatch pass.
6. Findings 11 and 12 with the first widget that adopts dashes (Gantt today marker).
7. Findings 8, 9, 10 as opportunistic cleanup.
