# Design Scan (diff mode): simple_widgets, since 053211b (GW-16, 0.30.0)
# Date: 2026-10-25
# Subjects: src/sw_theme.e, src/sw_window.e (plus testing files, read only)
# Compared against: all of src/ (141 files)
# Nothing was compiled or edited. Findings are proposals.

## Summary

| Severity | Count |
|----------|-------|
| HIGH     | 3 |
| MEDIUM   | 7 |
| LOW      | 3 |
| Total    | 13 |

## Findings

| # | Severity | Category | Where | Finding |
|---|----------|----------|-------|---------|
| 1 | HIGH | token | src/sw_theme.e:168-171 vs src/sw_list.e:318, src/sw_tree.e:222, src/sw_tree_table.e:156, src/sw_data_grid.e:379, src/sw_sheet.e:225, src/sw_spreadsheet.e:196, src/sw_toolbar.e:139, src/sw_text_box.e:652, src/sw_org_chart.e:240, src/sw_paragraph_list.e:964, src/sw_interlinear.e:661 | The contrast theme sets every wash to the window ground, but selected rows and selected text paint with `wash_accent`, so a selection is invisible |
| 2 | HIGH | token | src/sw_theme.e:142 vs src/sw_button.e:163-176 and 200-212 | `outline` equals `ink`, and a pressed plain button fills with `outline` while its label is drawn in `ink`: ink on ink |
| 3 | HIGH | token (D1 drift) | src/sw_theme.e:156, 168 vs the widgets in finding 1 | The contrast theme builds a readable `selection` token, but only src/sw_doc_units.e:690 uses it; the other selection sites use the token the theme flattened |
| 4 | MEDIUM | token | src/sw_theme.e:139-141 vs src/sw_button.e:200-203 | `ink_muted` and `ink_soft` equal `ink`, so disabled labels, hints and placeholders look exactly like live text |
| 5 | MEDIUM | token | src/sw_theme.e:144-148 | `surface_variant` is the button face, which on the built-in contrast themes equals the window; hover fills (53 sites) become invisible, and the fallback also assigns the window |
| 6 | MEDIUM | token | src/sw_badge.e:124-138, src/sw_chip.e:121-146 | Text on `success`, `warning`, `danger` and `accent` is drawn with tokens the contrast theme does not check; the mended `ink_on_*` and `ink_*` tokens have no widget consumer |
| 7 | MEDIUM | token | src/sw_theme.e:150-154 | `accent` is accepted at 3:1 but is drawn as 11 pixel chip text and as a badge ground with 3:1 text on it |
| 8 | MEDIUM | correctness | src/sw_theme.e:426-442 | `adopt_metrics_from` copies 8 fields and drops `radius`, `button_height`, `chip_height`, `size_body`, `size_label`, `size_chip`, `line_height` |
| 9 | MEDIUM | correctness | src/sw_window.e:565-576 | `wear_theme` never refreshes the shaping kit's theme faces (`set_theme_faces` runs only in `enable_shaped_text`, src/sw_window.e:183) |
| 10 | MEDIUM | contract | src/sw_window.e:595 | Postcondition calls the system reader (`system_high_contrast`), and the body reads it and the system colors several more times |
| 11 | LOW | duplication (A5) | src/sw_theme.e:730-745 vs src/sw_heatmap.e:128-143; src/sw_mark_palette.e:70-74 vs src/sw_theme.e:308-312 | Channel-wise color mixing exists twice; `SW_MARK_PALETTE.is_dark` re-derives `SW_THEME.is_dark` |
| 12 | LOW | token | src/sw_mark_palette.e:80-100, src/sw_heatmap.e:214 | Mark palette hues and the heat map blend ignore the contrast theme's own ground and ramp |
| 13 | LOW | tests | testing/sw_high_contrast_assault.e | Rendering tests cover one resting screen only |


## Detailed findings

### 1. HIGH - Selection is invisible in a contrast theme
make_high_contrast sets `wash_accent := a_window` (src/sw_theme.e:168), the same as `surface`. SW_LIST (src/sw_list.e:318) and SW_TREE (src/sw_tree.e:222) fill the selected row with `wash_accent`, and SW_TEXT_BOX (src/sw_text_box.e:652) paints the selected text's ground with it; the grid, sheet, spreadsheet, toolbar, org chart, paragraph list and interlinear sites do the same.
Scenario: Windows High Contrast Black. A user arrows down a list; the selected row paints the window color over a window-colored row. There is no highlight and no outline, so keyboard users cannot tell where they are. The header comment says "No washes: they all take the ground", which is safe for tint-behind-text uses but not for state fills.
Fix: read selection state from `selection` in all eleven sites and make the contrast theme guarantee `selection` is distinct from `surface` (finding 3). A shared deferred ancestor or a painter query (for example one that paints a selected ground) would end the eleven copies of "fill a row with wash_accent".

### 2. HIGH - Pressed plain button draws ink on ink
`outline := ink` (src/sw_theme.e:142). SW_BUTTON.fill_color for the default kind while pressed returns `outline` (src/sw_button.e:173), and label_color returns `ink` (src/sw_button.e:205). In light and dark themes outline is a pale or dark neutral, so the text reads; in a contrast theme the fill and the label are one color.
Scenario: press and hold any plain button in High Contrast White: the label vanishes until release.
Fix: give the contrast theme a distinct pressed pairing (fill with `selection`, or fill with `ink` and label in the ground color), or have SW_BUTTON choose its label from the fill. Add a test that renders each button kind pressed and checks label against fill.

### 3. HIGH (drift) - Mended `selection` is used by one widget only
src/sw_theme.e:156 computes `selection := readable_ground (a_highlight, a_window, ink)`, which falls back to the window itself when no step toward the highlight reads (k reaches 0). For a bright highlight with white ink on black (for example cyan), the walk ends at the window or a near-window color. Only src/sw_doc_units.e:690 reads `selection`. So (a) that one consumer may get a color equal to the window, with the invisibility of finding 1, and (b) the other consumers never see the token. This is drift between the documented role of `selection` ("selected row or verse ground") and the widgets that draw selection.
Fix: define the contrast contract as "selection stands apart from surface by a measurable amount or the widget adds a marker" (an `accent` outline on the row), add it to the ensure clause of make_high_contrast, and migrate the finding 1 sites to the token.

### 4. MEDIUM - No disabled or hint distinction
`ink_muted := ink; ink_soft := ink` (src/sw_theme.e:139-141). Disabled button labels (src/sw_button.e:203), tree expanders (src/sw_tree.e:230) and hints all use `ink_muted`. Windows supplies the gray-text system color for exactly this; make_high_contrast takes six colors and has no argument for it.
Scenario: a disabled Save button looks identical to an enabled one.
Fix: add a gray-text parameter (Windows contrast themes guarantee it reads on the window) and assign `ink_muted` from it, mended at the label threshold.

### 5. MEDIUM - Hover fill equals the ground
`surface_variant := a_button_face` (src/sw_theme.e:145), else the window (src/sw_theme.e:147). On High Contrast Black and White, the button face equals the window. 53 sites paint `surface_variant` for hover, zebra rows and quiet grounds (for example src/sw_list.e:323, src/sw_tree.e:225, src/sw_menu.e:522, src/sw_menu_bar.e:316, src/sw_tabs.e:556, src/sw_button.e:176). Hover feedback disappears; skeleton placeholders (src/sw_skeleton.e:92-117) and gauge tracks (src/sw_gauge.e:117) vanish.
Fix: when the variant would equal the window, use a mixed step toward the ink that still reads under it (the loop shape of readable_ground), otherwise keep the window and have hover sites draw an outline frame.

### 6. MEDIUM - Text on unchecked grounds
SW_BADGE draws its caption in `surface` on a `success`, `warning`, `danger` or `accent` fill (src/sw_badge.e:124-139). SW_CHIP draws `success`, `warning`, `danger` and `accent` text on the window (src/sw_chip.e:121-132). make_high_contrast takes the semantic hues from whichever base (dark or light) matches the window luminance (src/sw_theme.e:119-123, 160-162) and never checks `success`, `warning` or `danger` against the window or `surface`; it checks only the `ink_*` and `ink_on_*` tokens. For a mid-luminance contrast palette the base choice (a 0.5 threshold) can leave them unreadable. `ink_on_accent`, `ink_on_success`, `ink_on_warning` and `ink_on_danger` are read by no widget outside sw_theme.e (confirmed by search), so their mending protects nothing.
Fix: badge text should use `ink_on_*`; chip text should use `ink_*`. These tokens exist and are mended; the same change is the documented intent of GW-28 for the light and dark themes.

### 7. MEDIUM - Accent accepted at 3:1 but used as small text and as a text ground
`accent := a_highlight` when contrast to the window is at least Label_contrast (src/sw_theme.e:150-154), and the `accent_visible` postcondition (src/sw_theme.e:181) uses the same threshold. A highlight at 3.2:1 is kept and then used for 11 pixel chip text (src/sw_chip.e:121), for the accent button label (src/sw_button.e:207) and as the ground under badge text. WCAG asks 4.5:1 for small text.
Fix: use the body threshold for `accent` in the contrast theme, or route small-text uses through `ink_accent`.

### 8. MEDIUM - adopt_metrics_from misses fields
src/sw_theme.e:426-442 copies `text_scale`, `pad`, `gap`, `control_pad`, the three families and `locale`. Not copied: `radius`, `button_height`, `chip_height`, `size_body`, `size_label`, `size_chip`, `line_height` (set in set_metrics, src/sw_theme.e:192-206; plain attributes at src/sw_theme.e:468-482). An application that retunes any of these on its light theme sees the contrast theme jump back to 16, 13 and 11 pixel text and 38 pixel buttons, which undercuts the stated purpose ("keeps its sizes and faces").
Also: only the light member is adopted (src/sw_window.e:608-610). If the application set `text_scale` on the dark member or on the worn theme only, the contrast theme takes the light value.
Fix: copy every metric and ensure all of them; better, move the metric block into one small value (a push-up candidate: SW_THEME owns one, `adopt_metrics_from` becomes one assignment) so a new metric cannot be forgotten. Adopt from the theme being replaced (the one currently worn), not only from `system_light`.

### 9. MEDIUM - Shaping kit's faces stale after any theme swap
`wear_theme` (src/sw_window.e:565-576) rebuilds the painter and re-attaches the kit with `set_shaping` but does not call `set_theme_faces`; that call exists only in `enable_shaped_text` (src/sw_window.e:183), once. The comment at src/sw_window.e:128-134 says the kit survives a theme swap, which is right for the layout cache and wrong for the faces. With adopt_metrics_from the contrast theme copies the light family so the common case matches, but a dark member with another family, or `set_theme` to any theme with other faces, leaves shaped text in the old family (per-role faces: src/sw_shaping.e:308-322).
Fix: in wear_theme, call `set_theme_faces (a_theme)` on the kit when one is attached (it already calls forget_layouts), and add that to the postcondition.

### 10. MEDIUM - Contract queries the system, and repeated system reads
wear_system_appearance's postcondition (src/sw_window.e:595) calls `system_appearance.system_high_contrast`, which asks Windows. Finalized test builds keep contracts, so every wear pays an extra query, and it can disagree with what the body just did if Windows changes in between. The body reads the flag at src/sw_window.e:583, the event handler reads it at src/sw_window.e:474 before calling the callee, and system_contrast_theme reads `system_color` six times (src/sw_window.e:601-607). A flip mid-sequence yields a theme whose `is_high_contrast` is true but that is painted from ordinary colors (or the reverse), and the postcondition then raises in a finalized build.
Fix: read the flag once into a local and pass it down, or take one snapshot object holding the flag and the six colors; make the postcondition compare against the stored decision, or drop it.

### 11. LOW - Duplicated bodies
SW_THEME.mixed and mixed_channel (src/sw_theme.e:730-745) and SW_HEATMAP.blend (src/sw_heatmap.e:128-143) are the same channel-wise interpolation written two ways (the theme clamps to 255 and works in REAL_64; the heat map works in integers and does not clamp). Results agree for fractions in 0..1: duplication without drift today. Fix: export `mixed` from SW_THEME (or a small color helper) and have SW_HEATMAP call it.
SW_MARK_PALETTE.is_dark (src/sw_mark_palette.e:70-74) is `luminance (surface) < 0.5`, exactly SW_THEME.is_dark (src/sw_theme.e:308-312). Replace it with `a_theme.is_dark`.

### 12. LOW - Palette and heat map outside the contrast guarantee
SW_MARK_PALETTE.ink and wash (src/sw_mark_palette.e:80-100) return fixed light or dark hues with postconditions that assume a near-white or near-black surface (3:1 against the surface, 4.5:1 for `ink` on the wash). A contrast palette with a colored window can violate those postconditions in contract builds, and the marks keep decorative hues instead of system colors. SW_HEATMAP (src/sw_heatmap.e:214) blends `surface_variant` (equal to `surface` in a contrast theme) toward `accent`, so the low end of the scale equals the ground. Use `ramp (1..5)`, which the contrast theme sets (src/sw_theme.e:747-762).

### 13. LOW - Test gap
testing/sw_high_contrast_assault.e checks tokens and renders one resting screen in white and black. It does not render a pressed button, a selected row, selected text, a hovered row or a disabled control, which are exactly the failures in findings 1, 2, 4 and 5.

## Checked and found sound
- Order of wear_theme and on_theme_changed: both paths wear first, then tell the callback with the new theme (src/sw_window.e:586-589, 620-628), consistent with GW-27.
- Event 53 versus 56: while contrast is on, event 53 re-wears the contrast theme (src/sw_window.e:474-477) and event 56 re-reads the system (src/sw_window.e:481-485); switching contrast off falls through to wear_system_theme with the system preference. The 56 payload is ignored in favor of re-reading (but see finding 10).
- Title bar: wear_theme sets the caption from `is_dark`, and the contrast theme guarantees `is_dark` matches the window luminance (src/sw_theme.e:182).
- Invariant cost: unchanged by this diff. make_high_contrast builds a throwaway base theme (two readability postconditions) on every event; harmless at event rates.

## Recommended order
1. Findings 1, 2 and 3 together (selection and pressed state): one token decision, then migrate the sites.
2. Findings 9 (one call) and 8 (copy all metrics).
3. Finding 10 (single snapshot per wear).
4. Findings 4 to 7 (disabled ink, hover, badge and chip token choice).
5. Findings 11 to 13 (cleanup and tests).
