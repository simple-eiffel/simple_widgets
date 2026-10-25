# Design Scan (diff mode): simple_widgets since 1d2249f (main 24c8a87)
# Date: 2026-10-25   Read-only; nothing compiled or run; findings are proposals.
# Subjects: sw_query_builder, sw_query_node, sw_query_group, sw_query_condition, sw_query_proximity,
#   sw_chart, sw_bar_chart, sw_line_chart, sw_scatter_chart, sw_pie_chart, sw_heatmap, sw_interlinear, sw_text_box.
# Compared with all of src/. Previous: design-scan-since-7504574.md.

## Summary

| Priority | Count |
|----------|-------|
| HIGH | 2 |
| MEDIUM | 12 |
| LOW | 15 |

HIGH:
1. sw_query_builder.e:362 - the "within N words" box is built with `agent a_p.set_distance`, which never calls `announce`: editing a distance does not fire on_change, so the host's expression label goes stale.
2. sw_query_builder.e:362 - SW_NUMBER_BOX.make requires value in min..max (sw_number_box.e:24-26) but SW_QUERY_GROUP.add_proximity (group:162-171) and SW_QUERY_PROXIMITY.make (proximity:372-383) accept any distance >= 1: a preset/saved distance of 100+ makes `rebuild_rows` violate that precondition and abort.

## Q1. Did each fix land fully?

Landed:
- Chips: bar (bar_chart.e:333 draw_chip_above), line (line_chart.e:215 draw_chip_beside), scatter (scatter_chart.e:140 draw_chip_beside), pie (pie_chart.e:285 draw_chip_corner), heatmap (heatmap.e:254 draw_chip_corner). No leftover rrect/text chip block in any of the five. draw_chip (sw_chart.e, new block after draw_legend_row) clamps both axes with theme tokens and sets last_chip.
- Legend: drawn once by the chassis (sw_chart.e:112-114) after draw_data, before draw_hover. bar and line both redefine legend_names (bar_chart.e:25,146; line_chart.e:19,165) with matching signature; the old legend calls are gone (draw_legend_row appears only in sw_chart.e). Scatter, heatmap, funnel, gauge, treemap, sankey, pivot, gantt, org_chart inherit the empty default and none draws a legend.
- series_color cycles 8 (sw_chart.e series palette); quiet = ramp (2) (bar_chart.e:157-158); emphasis reset in set_series (176) plus invariant (340); non-negative preconditions (bar_chart.e:187, 210); Interlinear click clears selection (interlinear.e:299) and Ctrl+C copies the selection first (339-345).

Leftovers:
- MEDIUM  SW_MAP still hand-draws its hover chip: sw_map.e:482-486 (literal 11.0, rect x+10 / y+height-24, height 17). Same block as draw_chip_corner; the sixth copy, missed by the lift. Replace with draw_chip_corner (a_p, the_chip).
- MEDIUM  SW_PIE_CHART draws its own side legend (pie_chart.e:253-262, literal 12.5, dot radius 4.5, x + width * 0.62) instead of legend_names + chassis. Defensible (percentages, different place) but then it should share the tokens; funnel uses 12.0 (funnel_chart.e:138). Open from 7504574 item 7.
- LOW     With emphasis on, every non-emphasized bar series takes ramp (2) (bar_chart.e:157), so their legend dots are identical (the chassis legend uses series_color): the legend cannot tell quiet series apart.
- LOW     bar legend_names returns the live `series_names` list (bar_chart.e:146-150), a public alias: a caller can mutate it and break the series_count / parallel contracts. Return a twin. Line builds a fresh list each call (line_chart.e:165-172) and the chassis calls it twice per draw (sw_chart.e:112-113): hold it in a local.
- LOW     draw_legend_row keeps literals 12.0 / 16.0 (dot centre, baseline) and 10.0 (title left, also at sw_chart.e:116): one Title_left constant and theme tokens.
- LOW     A zero value still draws a 1 px bar (bar_chart.e:282 `.max (1.0)`); with negatives barred this reads as data where there is none.

## Q2. Query builder: live defects

Checked and fine:
- remove walk: SW_QUERY_GROUP.remove (group:173-191) goes from the end, removes at i, then i - 1; the elseif recursion is skipped for the removed element; nothing is skipped or visited twice.
- Root removal: remove_node (root) (builder:186-191) cannot remove it (the root is nobody's child): a no-op, though it still rebuilds and announces (L1).
- empty_iff_incomplete holds in every heir: condition (condition:282-321) text non-empty iff value non-empty; proximity (395-433) iff both words non-empty; group (119-132, 195-221) complete iff some child complete, and `joined` appends only complete children, each of whose text is non-empty; a negated group whose children are all incomplete gives "" from `negated` (node:60) and is_complete is False; a nested negated group gives "NOT (...)" and is complete. A whitespace-only value is non-empty, so it is complete and the contract still holds (see M6).
- on_change fires once per edit: a field pick that changes the kind = rebuild then one announce (builder:441-446); structure = one announce (537-542); join, negation, op, value = one announce each. No double fire found.
- Edits land in the tree on every keystroke, so a rebuild never loses text typed in OTHER rows.
- field_index never exceeds fields.count through the builder's own paths (set_clause precondition 205; field pick uses field_of, 438-439); it can through the public tree (M4).

HIGH: the two above (362).

MEDIUM:
- M1 Field_number is not validated. set_field_kind accepts it (builder:121-130, kind_known 124) but value_control (374-401) has no branch for it: `else` builds a plain text box, so "abc" is accepted. The class note (builder:15-16) promises "a number (a box)". SW_QUERY_CONDITION cannot help, it does not know the kind. Needs a digit filter in value_control or a kind-aware value; sql_text also guesses by `is_double` (condition:313).
- M2 Value outside the choices. set_field_choices / set_field_kind / set_field_suggester (builder:132-161) rebuild but never touch conditions already using that field: a condition holding "foo" on a field that becomes a choice list keeps "foo"; `l_combo.set_text (a_c.value)` (388) shows it, the tree keeps it, `expression` reports it. Same when a user switches between two choice fields: condition_field_changed clears only when the KIND differs (440-445), so a code from field A stays on field B (also two lemma fields). Clear when the value is not in the new list, not only when the kind differs.
- M3 set_field_kind (Field_choice) with no choices, or (Field_lemma) with no suggester, builds an empty combo (builder:381-396; the nulls are skipped at 383, 483): a field the user cannot fill. Add preconditions or fall back to the text box.
- M4 Index mismatch: value_control clamps for the kind (380) but not for the choices: `field_choices.i_th (a_c.field_index)` (383). A condition made through the public tree (`root.add_condition (9, ...)`, group:143-152 requires only field >= 1) whose clamped field is a choice field crashes in i_th. Clamp once (`field_slot`) and use it at 380, 383, 409, 440, 483.
- M5 Zero fields: make (builder:42-57) accepts an empty iterable; the first condition row then calls `fields.i_th (a_selected.min (0))` = i_th (0) in field_combo (409), and `expression`/`query_text` violate `fields_given` (node:30, 37). Add `fields_given: a_fields has an item` to make.
- M6 Whitespace is a value. `is_complete = not value.is_empty` (condition:284; proximity:397): "   " makes the clause complete and the query `lemma = "   "`. Contract true, behaviour wrong; treat all-blank as empty (or trim in the setters).
- M7 Focus and re-entrancy. rebuild_rows (263-268) wipes `children` and rebuilds the whole tree for + condition / + group / + near / remove (changed_structure 537-542), set_clause, set_join_all, set_field_kind/choices/suggester, and a field pick that changes kind (441-446). The focused control is gone afterwards: after "+ condition" the keyboard focus is lost and the new row's value box is not focused; a kind-changing pick destroys the combo, and a click destroys the button, from inside their own handlers. Whether SW_COLUMN/focus survives that was not verified (no run); if focus is held by reference it dangles. Fix: focus the new row's value control after rebuild (return it from add_*), or rebuild only the changed group's view.
- M8 lemma_typed (473-479) rewrites `a_combo.options` in place on every keystroke (refresh_suggestions 481-489), calling the suggester synchronously: a slow suggester (concordance database) blocks typing, and the option count is uncapped. Debounce or cap.
- M9 Proximity on non-text fields: proximity_row (338-372) always offers every field, including choice and number fields where "within N words" means nothing; proximity_field_changed (491-500) has no kind check or reset like condition_field_changed.

LOW:
- L1 remove_node of the root, or of a node not in the tree, still rebuilds and announces (186-191).
- L2 Redundant parentheses: `joined` parenthesises every non-negated child group (group:210-212), including a lone group under the root: "(a AND b)".
- L3 Duplicate field names: field_of (520-535) returns the first match, so picking the second of two equal names selects the first.
- L4 Field combo free-typing: field_of returns 0 mid-typing and the change is dropped (439, 496); the combo text then disagrees with the tree.
- L5 `value.is_double` (condition:313) makes " 12" or "1e5" bare, and a text field holding "1" prints unquoted. Display only, but the node has no kind.
- L6 Op_count declared twice (builder:74, condition:257); `op_index = 5` is a magic number for contains (condition:306). Name it Op_contains.
- L7 builder op_name (76-81) creates a throw-away condition to read a constant list: make op_name a class feature of SW_QUERY_CONDITION and have the builder use it.
- L8 condition_op_changed announces even when no option matched (450-465).

## Q3. Design

- D1 (MEDIUM) Field-name lookup `a_fields.i_th (field_index.min (a_fields.count))` is repeated in condition (291, 305) and proximity (413, 423): 4 copies in two heirs, plus the builder's own clamps at 380, 383, 409, 440, 483. Group has no field. Move up: a deferred SW_QUERY_FIELDED mixin (field_index, set_field, `field_label (a_fields)`, the field_positive invariant now at condition:348 and proximity:472, set_field now at condition:325-330 and proximity:437-442) inherited by condition and proximity SIDE BY SIDE with SW_QUERY_NODE; group stays out. Not a single-parent chain.
- D2 (MEDIUM) Template method in SW_QUERY_NODE. Every leaf writes the same shape four times (`create Result.make_empty; if is_complete then ... Result := negated (Result) end`: condition 289-298 and 303-320, proximity 402-415 and 420-432), while the postcondition empty_iff_incomplete sits only on the deferred features (node:32-34, 43-44). Make `expression` and `sql_text` effective in the node (`if is_complete then Result := negated (plain_expression (a_fields)) else create Result.make_empty end`, ensure once) with deferred plain_expression / plain_sql_text. Group already splits that way in `joined`.
- D3 (MEDIUM) condition_row (310-336) and proximity_row (338-372) repeat "field_combo; set_on_change (agent X_field_changed (node, fc))"; condition_value_changed / proximity_first_changed / proximity_second_changed (467-471, 502-512) differ only in the setter: one `text_edited (setter, box)` handler. Larger: a deferred row-view per node kind so group_view is a loop over `node_view (c)`.
- D4 (LOW) Hard-coded pixels: 120.0 (builder:359, 366: two copies, the word boxes); 99 (362: the maximum distance, a second source of truth beside the node's open-ended `distance >= 1`: make Max_distance a constant of SW_QUERY_PROXIMITY with a precondition and invariant, which also closes HIGH 2); 240.0 default in SW_TEXT_BOX (text_box.e preferred_width, still a literal). The word-box width should scale with theme.text_scale.
- D5 (LOW) set_preferred_text_width (sw_text_box.e) is ignored by SW_COMBO, which overrides preferred_width (sw_combo.e:76-90, floor 170.0): calling it on a combo silently does nothing. Honour it or restrict by contract.
- D6 (LOW) The flat API (add_clause, set_clause, root_condition_count, root_condition 195-261) walks the tree by counting; kept "for older callers". Retire if no ecosystem caller remains; set_clause also rebuilds all rows for a value change.
- D7 (LOW) `query_text` is documented as display only but produces SQL-shaped, quoted text (node:67-80) that looks safe to execute: consider naming it display_sql.
- No other src class builds a clause tree, so nothing to share with other widgets.

## Q4. Still-open items from design-scan-since-7504574.md (and its carried list)

- H9 interlinear measure copy: OPEN. interlinear.e:595-599 `stack_origin_y` still = margin (copy of document_view.e:380); own stack_reset at 611-615 (no clear_selection, unlike doc_units.e:502-518); no call to measure_units anywhere in interlinear.e (document_view.e:363 calls it); prologue and invalidate test still hand-built (398-425). No change in this merge. Rated MEDIUM, carried (not a live defect).
- #1 negative bars: RESOLVED (preconditions bar_chart.e:187, 210).   #2 chip clamp: RESOLVED (draw_chip).   #3 emphasis: RESOLVED (176-179, 340).
- #4 quiet colour: RESOLVED (ramp 2; see Q1 LOW for the legend side effect).   #5 colour cycle: RESOLVED (8).   #6 chip x5: RESOLVED for the five, OPEN for sw_map.e:482.
- #7 legend order/overflow: RESOLVED (chassis, floor, "+n"); literal sizes still OPEN in pie (12.5) and funnel (12.0).
- #8 Ctrl+C / click clears selection: RESOLVED (interlinear.e:299, 339-345).
- #10 bars narrower than 1 px: OPEN (bar_chart.e:142).   #11 bar_gap only set in draw_data: OPEN (bar_chart.e:250, 269).
- #12 hover rings a bar from anywhere above it: OPEN (bar_chart.e:319 tests only the plot band).   #13 category labels overlap: OPEN (draw_x_axis not changed).
- #14 flow inside draw (clear_selection + forget_hover at interlinear.e:543-544; selection lost on every resize): OPEN.
- #15 chart literals: PARTLY. Legend size, dot, gap and chip offsets are now theme tokens. Remaining: 10.5 axis ticks (sw_chart.e:98, 131), 10.0 heatmap:221, 10.5 gauge:138, 9.0 x-label baseline (sw_chart.e:138), the 0.78 / 0.62 slot fractions.
- #16 label_of (-0.004) reads "-0.00": OPEN (sw_chart.e:262-290: the '-' is written before rounding).
- #17 SW_BAR_CHART has no wipe_out / clear: OPEN (only set_series 172 clears names, and needs zero groups).
- #18 lines_revision summed twice per measure: not re-checked; no diff touched it.
- Carried, untouched by this merge, still OPEN: measure_block / measure_table monolith (document_view.e); title band drawn a third way (parallel_text.e:605-630); scrollbar full height beside the pinned band (vscrolling.e:94-95); five identical undefine lists; SW_SCROLLING_EDITOR joiner; Wheel_line copies (paragraph_list.e, doc_units.e:274); greedy wrap copy of SW_ROW.wrap_starts (interlinear.e:483-507); mark guard drift (parallel_text.e:584 vs paragraph_list.e:991); verse label two faces; RTL cell negative left (interlinear.e:498); text-width floors 32/32/64.
