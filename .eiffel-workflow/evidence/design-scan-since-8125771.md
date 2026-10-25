# Design Scan (diff mode): simple_widgets since 8125771
# Date: 2026-10-25   Read-only; nothing compiled; findings are proposals.
# Subjects (added/changed under src/, still present at HEAD): sw_document_view.e, sw_paragraph_list.e,
#   sw_in_place_editing.e, sw_keys.e, sw_doc_styles.e, sw_doc_unit.e, sw_document_codec.e,
#   sw_markdown_codec.e, sw_speller.e.
#   (sw_doc_block.e, sw_document.e, sw_rich_text.e were deleted by the diff: not subjects.)
# Compared against all 128 files of src/.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift / token | 12 | 6 | 4 | 2 |
| MI | 1 | 0 | 0 | 1 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **13** | **6** | **4** | **3** |

(Finding 12 is the one M2 item; finding 10 is M4 counted under Abstraction.)

## Findings

| # | Pri | Cat | Classes | Opportunity |
|---|-----|-----|---------|-------------|
| 1 | HIGH | A5/A1 | DOCUMENT_VIEW, PARAGRAPH_LIST | Fifth mixin SW_STACKED_ITEMS: stack, measure loop, visible range, frame draw |
| 2 | HIGH | A1/A5 | same | Editor-hosting SW_WIDGET features copied verbatim (sub_widgets, widget_at, preferred_height ...) |
| 3 | HIGH | A5/D1 | same | Pointing geometry copies; list lacks the stale-geometry guard the view has |
| 4 | HIGH | A5/D1 | DOCUMENT_VIEW, PARAGRAPH_LIST, SW_TEXT_BOX | Shaped-vs-toy layout dispatch x3, already diverged |
| 5 | HIGH | D1/T1 | same | Text width beside the bar: `bar_width - 4.0` (list) vs `2.0 * margin` (view); list does not scale |
| 6 | HIGH | D1/A3 | IN_PLACE_EDITING + both | end_edit / on_edit_commit semantics differ between the two users |
| 7 | MEDIUM | D1 | same | set_document keeps hover state; wipe_out clears it |
| 8 | MEDIUM | A6 | PARAGRAPH_LIST (SW_DOC_UNIT as model) | Seven parallel lists; item object like SW_DOC_UNIT |
| 9 | MEDIUM | T1 | DOCUMENT_VIEW + chat_thread + others | Literals that should be tokens |
| 10 | MEDIUM | M4/A6 | DOCUMENT_VIEW | 1371 lines; block/table layout is a separable helper |
| 11 | LOW | A5 | PARAGRAPH_LIST | Redundant scroll clamps (place_bar already clamps) |
| 12 | LOW | M2 | 10 sites | `create keys` per call; modifiers could be one inherited query |
| 13 | LOW | T1 | DOCUMENT_VIEW | Magic sentinels (1_000_000.0, laid_px 14) |

SHELL_KEYS direct callers: NONE remain. The only mention in src/ is the parent clause at
sw_keys.e:20; sw_window.e:36 is a comment. Every modifier read (data_grid 479-482, paragraph_list
1111-1124, scroll_area 201-204, sheet 364-367, spreadsheet 233-241, text_box 795-808, window
1254-1260 and 1521-1623, document_view 705 and 1274) goes through SW_KEYS, so `simulate` covers them.

## Detailed findings

### 1. HIGH A5/A1 - the "stack of items under a bar" skeleton (SW_STACKED_ITEMS)
Copies:
- measure: sw_document_view.e:793-844 vs sw_paragraph_list.e:1240-1293. Both: `bar` placed, width key
  `text_w|px|has_shaping` (806 / 1255), `stack.reset_if_changed`, per-item `stack.needs_measure` with
  `or i = editing_index`, `put_height`, `stack.restack (gap)`, `place_bar`. Same px formula
  `(size_body * text_scale).rounded.max (1)` at 805 / 1251 (also sw_text_box.e:1131).
- first_visible / last_visible (242-260 / 353-377), item height/top (block_height 215 / item_height 331),
  scroll_to_block 300 / scroll_to_item 874.
- draw frame: surface rrect_fill, push_clip, loop first_visible..last_visible with editor-or-item,
  pop_clip, draw_bar (doc 587-606 vs para 1021-1090).
- wheel_line: `px * 1.5` at 515 / 1288.
- viewport_height + preferred_height + invariant (doc 127, 544, 1367; para 154, 974, 1383; the same
  pair is in sw_list 48/291, sw_tree 49/168, sw_data_grid 51/222, sw_scroll_area 43/127, sw_sheet 50/189).
Proposal: deferred SW_STACKED_ITEMS inheriting SW_WIDGET only, side by side with the other four (the
mixin rule: define NO SW_WIDGET feature). Owns `stack`, `viewport_height`, effective `first_visible`,
`last_visible`, `item_top`, `item_height`, `scroll_item_into_view`, `measure_stack (a_p, gap, key)`
with deferred `measure_item (a_p, i): REAL_64`, `stack_origin_y` (view: margin; list: 0), and
`wheel_line` (effective, from the shared px). Helpers `begin_frame (a_p)` / `end_frame (a_p)` for the
surface+clip+bar. Effort: about 14 features.
Offset drift inside the copies: the view uses `scroll_y - margin` (212, 246, 256, 306), the list uses
`scroll_y`; a deferred `stack_origin_y` states it once.

### 2. HIGH A1/A5 - editor-hosting widget features copied verbatim
- sub_widgets: doc 558-564 = para 937-943 (identical).
- widget_at: doc 566-576 = para 996-1007 (same logic, operands reordered).
- preferred_height: doc 544-547 = para 974-977. accepts_focus 520/956, wants_hover_point 525/961 identical.
- cursor_kind editor branch: doc 535-536 vs para 969-970 (the list omits the bar test and the hover I-beam).
- handle_release: both `release_bar` + `ensure then released` (doc 674-696 / para 1153-1159).
- handle_char: `editor_char` first (doc 723-729 / para 1198-1202); handle_key `editor_key` first.
- Identical 4-parent `redefine` lists of 15 features (doc 62-95; para 75-102).
Constraint: the mixins must not redefine SW_WIDGET features, so the shared bodies cannot move into
SW_IN_PLACE_EDITING itself. Options: (a) effective NON-redefining helpers in the mixin
(`editor_sub_widgets`, `editor_widget_at (px, py, a_excluded: SW_VSCROLLBAR)`), each user's one-line
redefinition calls them; or (b) a joiner ancestor SW_SCROLLING_EDITOR that inherits SW_VSCROLLING and
SW_IN_PLACE_EDITING and redefines the shared SW_WIDGET features once (both users then inherit it beside
POINTING/SELECTION). (b) removes about 7 features and most of the redefine boilerplate. Check (b)
against the "never redefine each other's features" pattern before committing to it.

### 3. HIGH A5/D1 - pointing geometry; the list lacks the guard
Copies of "geometry.X (px - origin_x, py - origin_y)":
- text_boxes: doc 488-502 vs para 457-474 (same body, only the origin and geometry accessors differ).
- character_at: doc 473-486 vs para 426-441. Offset-at-point: doc offset_at_point 1313-1326 vs para
  caret_offset_at 443-455.
Drift: the view guards every use with `geometry.count = content.count` (482, 495, 1321) so text that
changed before the next measure cannot be indexed with stale geometry. The list guards only
text_boxes (466); character_at (436-437) and caret_offset_at (450-451) check only
`i <= geometries.count`. `edited` (1366-1372) changes `texts` at once, and caret_offset_at does not
exclude `editing_index`, so it can read a stale geometry. The view's guard should win.
Second drift: view pointed_item (446) requires `contains` and `not bar.contains`; list pointed_item
(492-496) is `item_at (a_py)`, a y-only test, so a point over the bar (or beside the widget) names an item.
Proposal: in SW_TEXT_POINTING, make character_at / text_boxes / `offset_at_point` EFFECTIVE over
deferred `item_geometry (i)`, `item_origin_x (i)`, `item_origin_y (i)`, with the guard and the
bar/contains rule once. Effort: 3 effective, 3 deferred.

### 4. HIGH A5/D1 - shaped-vs-toy layout dispatch, three copies, diverged
- sw_document_view.e:1045-1071 (lay_unit), sw_paragraph_list.e:1277-1281 + 1295-1319,
  sw_text_box.e:1163-1179, sw_mark_legend_view.e:147-149.
Divergences: the view floors the shaped height with `al_kit.line_height (px)` (1063); the list's shaped
path does not (1305) while its own toy path floors with `scaled_line_height` (1317). Whether an
empty paragraph measures 0 high on the shaped path depends on `content_height`
(sw_text_geometry.e:154-158, `line_top.last + line_height.last`): NOT verified by running; check it.
Toy fonts: view `a_p.font (role, size, bold)` (1065), list/box `Role_body, size_body` (1315, 1177).
Proposal: `SW_TEXT_GEOMETRY.lay_out (a_p, text, wrap, role, size, bold, alignment, styles): REAL_64` (or a
helper object) holding the engine switch and the height floor once. Effort: 1 feature, 4 callers.

### 5. HIGH D1/T1 - text width beside the scrollbar
- sw_paragraph_list.e:409, 534, 1026: `width - bar.bar_width - 4.0` (three copies; the 4.0 is a fixed
  pixel gap) and `gutter_width 28.0`, `item_gap 8.0`, `item_pad 8.0` (114-116), `set_line_width (2.0)` 1051.
- sw_document_view.e:804: `width - bar.bar_width - 2.0 * margin` (margin = theme.border_width, scales).
- sw_vscrollbar.e:147-148 scales its Track_inset by `scale`. The bar width scales
  (SW_THEME.scrollbar_width, sw_theme.e:451-456) but the list's gap does not, so at 2x text the list
  keeps a 4-pixel gap beside a 24-pixel bar.
The view's behavior should win (everything doubles at 2x). Token: a SW_THEME `scrollbar_gap` (or
`padding / 2`) read by one `SW_VSCROLLING.text_area_width`; the list's gutter/gap/pad defaults come from
`control_inset` / `padding` (defaults only; the setters stay).

### 6. HIGH D1/A3 - end_edit and on_edit_commit differ between the users
- list end_edit (para 914-933): commit ALWAYS calls `on_edit_commit` (922-924) BEFORE close_editor;
  cancel restores text and marks (926-928).
- view end_edit (doc 360-388): commit calls `on_edit_commit` only when the text CHANGED (377), AFTER
  `document.replace`, and after the box is down.
The mixin note (sw_in_place_editing.e:7-8) says `on_edit_commit` "when the edit stands"; the two disagree
about an unchanged commit and about whether the box is still up. Proposal: a template `end_edit` in
SW_IN_PLACE_EDITING (effective): take text, `close_editor`, then deferred `keep_item (i, text)` /
`restore_item (i)`, with the "unchanged is not a commit" rule decided once. Effort: 1 effective, 2 deferred.

### 7. MEDIUM D1 - hover state across document change
sw_paragraph_list.e:715-716 `wipe_out` zeros `hover_item` / `hover_character`; sw_document_view.e
set_document (270-284) and number_units (846-867) leave `hover_item`, `hovered_link_unit`,
`hovered_link_span` as they were, so a hover (and a pointed link) can name a unit of the old document.
`update_link_hover` (1349) and `hovered_link` (185) guard the range, but a hover card anchored by
SW_TEXT_POINTING is not guarded. Proposal: `forget_hover` effective in SW_TEXT_POINTING, called by both.

### 8. MEDIUM A6 - the list is seven parallel lists
sw_paragraph_list.e:1210-1226 (texts, revisions, bands_above, bands_below, selected_flags, marks_list,
styles_list, plus geometries) with the invariant 1376-1378 and the 7-way bookkeeping in insert (550-583),
remove (608-642), move (644-702), wipe_out (704-723). The view already models "one text" as an object,
SW_DOC_UNIT (geometry, origin, wrap). A SW_PARAGRAPH_ITEM object (text, revision, bands, flag, marks,
styles, geometry) would drop about 100 lines and one class of off-by-one risk, and would line the
two widgets up on item_geometry (finding 3).

### 9. MEDIUM T1 - literals that want tokens
- Quote_bar 3.0 (document_view:790, used 1119-1122, scaled by `s`) vs chat_thread Quote_bar_w 2.0 and
  Quote_bar_gap 5.0 (sw_chat_thread.e:991-994, 1969): the same role, different widths. Token
  `quote_bar_width` (scales).
- Link underline `2.0 * s`, hover width `2.0 * s` else `s` (1248-1249); strike at `0.3 * run.height` (1254);
  code wash `0.8 * run.height` (1243): type metrics, better from the run's ascent / SW_THEME
  `underline_offset`, `underline_width`.
- Heading sizes 1.6 / 1.3 / 1.12 (1078-1082): SW_THEME `heading_scale (level)`.
- Minimum widths 32.0 (804), 16.0 (897, 903, 910, 988, 993; para 534), 16 in 1062 and para 1302:
  one `min_text_width` token.
- wheel_line = px * 1.5 (doc 515, para 1288) vs SW_THEME.line_height 30.0 (sw_theme.e:134) /
  `scaled_line_height` (used at para 1317): choose one source.
- Clip inset `push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)`: doc 590, para 1025, and also
  chat_thread 1055, mark_legend_view 142, waveform 375, dock_zone 366 (six copies): `SW_PAINTER.push_frame_clip`.
- Selection ring `set_line_width (2.0)`, `bx + 1.0`, `- 2.0` (para 1051-1052) and `+ 0.5` (1056): `border_width`.
- Table: `+ 1.0` / `+ 16.0` column floors (957, 973, 988). `l_pad_x := control_inset` does scale.
Already tokens (good): border_width, padding, control_inset, text_scale (document_view 802-805, 890, 895,
901, 910, 955-956, 1204-1206).
Not found in subjects: hard-coded `scrollbar_width` or `min_thumb` (both are SW_THEME, sw_theme.e:451-465).

### 10. MEDIUM M4/A6 - SW_DOCUMENT_VIEW is 1371 lines
Block/table layout (measure_block 869, measure_table 937-1023, natural_width 1025, lay_unit 1045,
heading_size 1073, mirror_if_right_to_left 927) uses no widget state beyond `text_w`, `block_units`, the
theme and the painter. A SW_DOC_LAYOUT helper (`doc_styles`, 784, is already one) would leave the view
with input, drawing and the editor protocol, and gives the list a place to share finding 4.

### 11. LOW A5 - redundant clamps
sw_paragraph_list.e:987 and 1022 `scroll_y := scroll_y.min (max_scroll)`: measure -> place_bar
(sw_vscrolling.e:96) already clamps. The view omits them and is right.

### 12. LOW M2 - modifier reads
`(create {SW_KEYS}).control_down` is allocated inline at document_view:705 and 1274; nine other sites
allocate a local. A `keys` once-query (or `control_held` etc.) on SW_WIDGET would make "tests simulate"
a property of one object. All sites already use SW_KEYS, so there is no test hole today.

### 13. LOW T1 - sentinels
`set_origin (0.0, 0.0, 1_000_000.0)` (document_view:971) means "no wrap"; name it. `laid_px := 14` (115)
is a pre-measure default that ignores the theme.

## Other new classes
- SW_DOC_STYLES (sw_doc_styles.e): no other `add_setting` caller in src/ - not duplicated.
- SW_SPELLER.has_other_script (42-62): no other script test in src/ - no duplicate.
- SW_DOCUMENT_CODEC / SW_MARKDOWN_CODEC: deferred contract + one effective; no finding.
- SW_KEYS: no finding (see the SHELL_KEYS note above).

## Recommended order
1. Finding 3 then 4 (the list's missing guard is a live-defect candidate).
2. Findings 6 and 5 (drift; decide the winning behavior first).
3. Findings 1 and 2 (the structural payoff; 2 after 1).
4. Findings 7-10; then 11-13.
