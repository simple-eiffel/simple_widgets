# Design Scan (diff mode): simple_widgets since 7504574
# Date: 2026-10-25   Read-only; nothing compiled or run; findings are proposals.
# Subjects (git diff --name-only 7504574..HEAD -- src): sw_bar_chart.e, sw_doc_units.e, sw_document_view.e,
#   sw_interlinear.e, sw_parallel_text.e.  Compared with all of src/. Previous: design-scan-since-f8df023.md.

## Summary

| Priority | Count |
|----------|-------|
| HIGH | 9 (7 new in SW_BAR_CHART, 2 carried from the previous HIGH list) |
| MEDIUM | 6 |
| LOW | 3 |
| **Total** | **18** |

## Q1. The previous report's six HIGH findings

1. Interlinear pointing reaches only the surface line: RESOLVED. sw_interlinear.e:528-531 gives each line unit its own band
   (first from the cell top, last to the row bottom); sw_doc_units.e:237-245 hit-tests those boxes. Wash now from token_lefts (657-661).
2. Selection invisible, Ctrl+A / Ctrl+C: PARTLY. Wash painted (sw_interlinear.e:674). Remains: handle_char 345 lets `selected_token > 0`
   win over the text selection, so Ctrl+A then Ctrl+C copies one word while the whole text is washed; handle_click 291-305 never
   calls clear_selection, so a Ctrl+A wash survives picking a word. See H8.
3. units_revision non-monotone: RESOLVED. sw_interlinear.e:583-590 returns structure_revision only (wipe_out bumps it, 129);
   line edits go through lines_revision/laid_lines (377-384, 413).
4. Stale hover and selection on wipe_out / re-flow: RESOLVED. wipe_out 132-133; flow ends 540-541 (renumbered units clear both).
5. forget_hover leaves the link hover: RESOLVED. sw_doc_units.e:284-292 (Precursor, then update_link_hover; ensure no_link).
6. Measure tail copied: PARTLY. Lifted: margin (doc_units:492), layout_key (495-499), scroll_extent (277-282); view and parallel
   now call layout_key and measure_units. Remains: sw_interlinear.e:398-425 still hand-builds the prologue (margin 406, place_bar
   409/422, floor 410, laid_px 411) and its own invalidate test 413-415 (copy of doc_units:526-528), never calls measure_units;
   own stack_reset 608-612 (no clear_selection, differs from doc_units:502-518); `stack_origin_y = margin` in interlinear:592-596
   and document_view:380-384; arrange 273-276 / draw skeleton 280-287. See H9.

## Findings (all involve a subject)

| # | Pri | Cat | Where |
|---|-----|-----|-------|
| 1 | HIGH | D1/defect | SW_BAR_CHART negative values: invisible bar, ring and chip off the plot |
| 2 | HIGH | D1 | Bar hover chip has no frame clamp; line and scatter have one |
| 3 | HIGH | defect | emphasized_series survives set_series, can exceed series_count |
| 4 | HIGH | defect | Quiet series colour ink_soft is the loudest ink, not quiet |
| 5 | HIGH | defect | series_color cycles 4: series 5 equals series 1 (grouped charts want 5+) |
| 6 | HIGH | A5/T1/D1 | Hover chip drawn five times with different sizes; bar uses size_chip, the rest 11.0 |
| 7 | HIGH | D1 | Legend: bar draws it before the data (draw_x_axis), line after (draw_hover); no overflow guard |
| 8 | HIGH | D1 | Interlinear: Ctrl+C copies the word while the washed selection is something else |
| 9 | HIGH | A5 | Interlinear still does not use measure_units / stack_reset / stack_origin_y default |
| 10 | MED | defect | Bars narrower than 1 px overlap the next group (bar_width .max 1.0) |
| 11 | MED | defect | bar_gap only set during draw_data: headless bar_left uses 0 |
| 12 | MED | defect | Hover rings a bar when the pointer is anywhere above it in the plot |
| 13 | MED | defect | Category labels overlap with many groups or long names; not trimmed |
| 14 | MED | D1 | Interlinear flow runs in draw: clear_selection loses selection on every resize; forget_hover calls on_hover mid-paint |
| 15 | MED | T1 | Repeated chart literals (see Q2) |
| 16 | LOW | defect | label_of(-0.004) reads "-0.00" (sw_chart.e:184-197) |
| 17 | LOW | M4 | SW_BAR_CHART has no wipe_out / clear: set_series needs zero groups, so a chart cannot be re-used |
| 18 | LOW | perf | lines_revision summed twice per measure (interlinear 413, 418); is_laid_out ignores line edits (units_revision excludes them) |

## Q2. SW_BAR_CHART vs the other SW_CHART heirs

Good: the legend is NOT copied; bar calls the shared SW_CHART.draw_legend_row (sw_chart.e:145-168) like SW_LINE_CHART (178),
and `series_color` is redefined so the shared legend follows emphasis. Category-label font is now theme size_chip (was 11.5).

### 6. HIGH A5/T1/D1 - hover chip copied five times
Same rrect_fill + text block (rect = advance + 10, height 16 or 17, radius 3, text 5 px in):
- sw_bar_chart.e:324-329 (font size_chip, centred, NO clamp)
- sw_line_chart.e:218-224 and sw_scatter_chart.e:140-146 (font literal 11.0, `.min (x + width - adv - 14.0)` clamp, height 16.0)
- sw_pie_chart.e:285-290 and sw_heatmap.e:254-258 (11.0, height 17.0, fixed bottom-left x+10, y+height-24)
Drift: height 16 vs 17; font 11.0 vs size_chip (SW_THEME.size_chip = 11.0 today, sw_theme.e:133, so equal until a theme changes);
clamp present in two, absent in bar. Propose SW_CHART.draw_chip (a_p, a_anchor_x, a_anchor_y, a_text) clamped on both sides
with theme.size_chip and one height; five callers drop about 30 lines. Effort: 1 feature, 5 callers.

### 2. HIGH D1 - bar chip off the frame
sw_bar_chart.e:326-329: left = bx + bar_width/2 - adv/2 - 5 with no min/max against x or x+width.
Input: add_group x12, set_series (<<"target","control 1">>), pointer on group 12: chip "control 1: 12.5" (about 90 px) centred on a
bar near the right edge overhangs x+width (hover is drawn outside the clip, sw_chart.e:112). First group: left edge below x.
Line/scatter clamp the right side only; bar needs both. Fix in the shared draw_chip.

### 7. HIGH D1 - legend
- Order: bar draws it from draw_x_axis (bar_chart.e:298-300, before the data and the clip); line from draw_hover (line_chart.e:165-179,
  after). A tall bar can paint over the legend row only in the bar chart; legend is hover-layer elsewhere.
- sw_chart.e:152-167: lx only decreases, no floor. Input: width 300, set_series with 5 names ("target","control 1".."control 4"):
  each entry is name width plus 26 px, about 5 x 85 = 425 px, so lx goes negative: the left entries are drawn off the frame and over
  the title at x+10 (sw_chart.e:116). Fix: stop (or wrap or elide) when lx < x + Inset_left; drop the title overlap.
- Literal 11.5 at sw_chart.e:152 vs bar category labels size_chip (11.0) vs pie legend 12.5 (pie:254), funnel 12.0 (138): one token
  `legend_size` / theme.size_label.

### 15. MEDIUM T1 - literals in the chart family
- 11.5 legend (sw_chart.e:152); 10.5 axis ticks (sw_chart.e:98, 128), 10.0 in heatmap:221, 10.5 in gauge:138: one tick size.
- 9.0 x-label baseline: sw_chart.e:135, sw_bar_chart.e:294, sw_heatmap.e:237 (`y + height - 9.0`); 16.0 title/legend baseline:
  sw_chart.e:116, 161, pie:300, funnel:156, heatmap:263; 22.0 and 10.0 chip offsets (bar 327/329, line 221/224, scatter 143/146).
  Names: `Axis_label_baseline`, `Band_baseline` or `Inset_*` constants in SW_CHART next to Inset_left (46.0 etc. already there).
- 0.78 and 0.62 slot fractions (sw_bar_chart.e:246) and 0.78 funnel band (funnel:106): named group_fill constants.
- 4.0 legend dot radius, 12.0/14.0 legend spacing (sw_chart.e:162-165): spacing = theme.padding.
- bar_chart.e:317 `bx - 1.0 ... + 2.0`, 2.0 radius: ring inset = theme.border_width.

## Q3. Live defects by reading (SW_BAR_CHART)

1. HIGH negative values: add_group (172-193) has no `non_negative` (pie:177 and funnel:67 do). refresh_domains (218-230) starts hi at 0 so
   the y domain never goes below 0. Input add_group ("Gen", <<-3.0, 9.0>>): value -3 has by below the baseline;
   fill_rect height `(plot_y+plot_h - by).max (1.0)` = 1.0 at a position under the plot, clipped away: no bar. Hovering ring
   (317) and chip (326-329) are drawn outside the clip, below the axis over the category labels. Fix: precondition or a signed baseline.
2. HIGH emphasis index: set_series (158-170) neither resets nor checks emphasized_series; there is no invariant.
   Input: set_series (<<"a","b","c">>), set_emphasized_series (3), set_series (<<"a">>) (legal, zero groups): emphasized_series = 3 >
   series_count = 1, so series_color (1, p) (146-154) takes the quiet branch: the only series is grey and nothing is emphasized.
   Fix: set_series sets emphasized_series := 0; invariant emphasized_series <= series_count.
3. HIGH quiet colour: series_color 150 returns theme.ink_soft. ink_soft is a TEXT ink proven at body contrast (sw_theme.e:250-253):
   0x3A4452 on the light theme (near black) and 0xC9D1DC on the dark (near white). Input: light theme, set_emphasized_series (1):
   controls are the darkest marks on the chart, the target (accent) the lighter: the emphasis is inverted. Use outline, divider,
   or a ramp_* step (or a new `quiet_series` token), so quiet = lower contrast.
4. HIGH colour cycle: SW_CHART.series_color (sw_chart.e:204-217) is `index \\ 4`: 1 accent, 2 success, 3 warning, 0 and 4 danger, 5 accent
   again. Input: set_series with 5 names ("target" + 4 controls) and no emphasis: series 1 and 5 identical, the legend dots equal;
   with the census use ("target" vs several controls) five or more series are the point of GW-10. Fix: fall back to the ramp or a
   lightness-stepped accent past 4, or add `series_count <= 4` as a contract.
5. MEDIUM narrow groups: bar_width (138-144) floors at 1.0; group extent = n*1 + (n-1)*gap can exceed the slot. Input: 30 groups x 5 series
   in 200 px (slot 6.7, group 5.2, gap padding/4): bars of 1 px spill into the next group; series_at/bar_at then map a pointer to the
   wrong category.
6. MEDIUM bar_gap (238, set at 257) is assigned only inside draw_data. Headless `bar_left`, `bar_width`, `series_at` (assault tests, doc
   at 89-90) see gap 0 until a draw. Compute from theme in a feature, or pass it.
7. MEDIUM hover vertical: draw_hover 310 only requires the pointer inside the plot band; series_at is x-only, so a pointer well above
   a short bar rings it and shows its chip. Line/scatter hit-test in both axes. Add `hover_py >= by`.
8. MEDIUM labels: draw_x_axis 288-296 never elides or skips labels: 12 groups at 300 px (slot 20 px) with "Genesis" overlap.
Checked and fine: zero categories (bar_at 94 guards, bar_width 141 guards, group_width 245 guards, draw loops skip, precondition
protects bar_left from division by zero, x_scale domain 0..1); single series keeps the old 0.62 slot and one accent colour;
add_group with a lower bound other than 1 (187); parallel invariant (335).

## Interlinear / SW_DOC_UNITS items

### 8. HIGH D1 - Ctrl+C semantics
sw_interlinear.e:345 `selected_token > 0` takes precedence over a text selection (washed by 674). Input: click word 3, Ctrl+A, Ctrl+C:
whole text washed, one word copied. Input: Ctrl+A, then click a word: wash stays (handle_click 291-305 has no clear_selection).
Fix: clicking clears the text selection; Ctrl+A clears selected_token (or Ctrl+C asks has_selection first).

### 9. HIGH A5 - the rest of the measure copy
See Q1.6. Proposal: interlinear.measure ends with `measure_units (a_p, l_key, gap)` after flow (drop 413-415, 421 and the own stack_reset);
`stack_origin_y` default `margin` in SW_DOC_UNITS (view 380, interlinear 592 become inherited; parallel keeps header_height).
Three width floors remain 32.0 (view 361, parallel 409) and 64.0 (interlinear 410): one `min_text_width`.

### 14. MEDIUM D1 - flow inside draw
flow (427-544) runs from measure, called by draw (280-282), and ends with clear_selection and forget_hover. Input: Ctrl+A, drag the window
border: every width change re-flows and drops the selection; forget_hover calls on_hover and the hover card closes while painting.
Keep the selection by (token, line) across a re-flow, and defer forget_hover out of the paint pass.

## Q4. Still-open earlier items (one line each)

- Prev 9 measure_block/measure_table monolith: OPEN, sw_document_view.e (one user).
- Prev 10 title band drawn a third way: OPEN, sw_parallel_text.e:605-630 vs data_grid/tree_table.
- Prev 11 scrollbar full height beside the pinned band: OPEN, sw_vscrolling.e:94-95.
- Prev 13 five identical undefine lists: OPEN (doc_units.e:44-46, stacked_pointing.e, view 69-74, list).
- Joiner SW_SCROLLING_EDITOR: OPEN (view 62-75, list).
- Wheel_line in the list (paragraph_list.e:124, 1189) and `laid_px.max (8) * 1.5` (doc_units.e:274): OPEN.
- Greedy wrap copy of SW_ROW.wrap_starts (interlinear 483-507): OPEN. scroll_to_token: now RESOLVED (229-237 uses scroll_item_into_view).
- Mark guard drift parallel_text.e:584 vs paragraph_list.e:991: OPEN. Verse label two faces (parallel 568-572, interlinear 663-672): OPEN.
- RTL cell wider than flow gets negative left (interlinear.e:498): OPEN. units_revision cost: RESOLVED (O(1) now; lines sum O(words), twice per measure).
- Text-width floors 32/32/64 and by-hand inset math (view 735): OPEN.
