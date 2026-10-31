# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Wave 3 in progress

### Fixed (0.48.2 - docked buttons follow their state)

- `SW_DOCK_ZONE.refresh_enabling` passes the window's enabling pass on to every panel in the zone: the panels are not `sub_widgets`, so a docked button's `enabled_when` condition was asked once and never again (the Atlas's Undo point, End, Close shape and Delete stayed greyed in Simple Bible 0.7.43; only Start, made enabled, worked). Before: `dock_panel_buttons_follow_their_conditions` FAILED; after: passed.
- `SW_ATLAS.on_measure_change`: an agent collection the measurement calls after every change (start, a point placed or taken back, end, close, delete), so state pushes to what follows it (Larry, 2026-10-31: state machines through agent collections). `atlas_tells_every_measure_change`. 601 pass.

### Added (0.48.1 - the Atlas measures: a scale, a measuring tool, the area of every shape)

- A scale (Larry, 2026-10-31): three bars in the plot's lower right in miles (US statute), kilometers and nautical miles, each a round length (1, 2 or 5 times a power of ten) that fits, measured across the map at the view's center latitude, labeled in words. Jerusalem to Damascus measures 216 kilometers by the scale against 217 great-circle.
- A measuring tool: `start_measuring`, then each still click places the next point (a drag still pans); `undo_point`; `end_measuring` (or a double-click) keeps the path shown; `close_shape` (or a click on the first point) joins it into a shape; `delete_measure` removes it entirely. The readout plate gives the distance or perimeter in miles, kilometers and nautical miles and the area in square miles, square kilometers and square nautical miles: great-circle (haversine) distances, spherical areas (exact for a box of latitude and longitude: 9,401.8 square kilometers for 30-31 east, 40-41 north).
- Every area's hover card gives its area (all the polity's outlines in the year), and a press on an area outlines it and shows the same on the plate. Amounts read to three significant figures with US separators (`amount_text`, `grouped`). 5 new tests; 599 pass.

### Added (0.48.0 - the Atlas: SW_ATLAS, Plan 22 phase 3)

- `SW_ATLAS` (an heir of `SW_MAP`): areas that hold a span of years, drawn only when the year shown (`set_year`) falls inside, largest first so the smallest answers a hover, each in one of eight earth hues with an outline (never a tint near the water: the dark theme fills at 0.4, since 0.22 left `4A4A45` over water `26384D`); sites whose location is a claim (one candidate a dot, several dashed rings each labeled with its holder, the lean solid), with spans of years; marked sites ringed and always labeled, `fit_marked` brings them into view; a press on a site selects it (`on_site_select`) instead of panning; timed routes; hover cards on sites, routes and areas; a true aspect at `standard_parallel` (32 degrees north by default) whatever the panel's shape; a label that collides tries the left, then above, then below. Land is a step from the panel surface toward the ink (SW_MAP's land is the surface, so in a dock panel the desert read as empty panel; `atlas_land_is_not_the_panel` failed on that code, FFFFFF against FFFFFF). 10 tests (`SW_ATLAS_ASSAULT`), including 3,000 areas in the frame budget (28.8 ms median in the contract build, budget 33.3).
- `SW_MAP`: `draw_under_routes` and `draw_over_places` layers for heirs, `route_shown`; the wheel reads `span_lon` / `span_lat`, so an heir's aspect keeps the point under the cursor (unchanged for `SW_MAP`, whose tests all pass).
- `SW_PAINTER.polygon_stroke_flat`: the zero-allocation outline beside `polygon_fill_flat`.

### Fixed (0.47.1 - River of Time labels, found in the first seeded snapshot)

- A band mostly off the left edge put its label inside the sliver still in view, so the label started left of the plot and was clipped ("eriod" for a period). It now labels inside only when the part in view holds the whole label, and otherwise after its end. Before: `river_band_label_stays_in_view` (new sliver case) FAILED; after: passed.
- A lean's marker and wording ("shown first") are drawn after the label, but rows were claimed only to the label's end, so the next item in the lane was laid over the wording. Rows now keep room for it. Before: `river_a_lean_keeps_its_room` FAILED; after: passed.

### Added (0.47.0 - the River of Time: SW_LANE_TIMELINE at scale, the lens, hover cards)

- `SW_LANE_TIMELINE` keeps an index as items are added (each lane's items by start, binary-search insertion, stable; each lane's disputes with their positions) and lays rows and envelopes out from it in one pass, remembering what it placed (`shown_ids`); only items in the visible rows are drawn; label widths are measured once per item and size. The same boxes as before (every existing GW-17 and scan-15 test passes). 10,000 items: a wheel frame took 2,334 ms in the contract build, now 20 ms (Plan 22 spike S1: 753 ms to 10.7 ms lean). Before: `river_ten_thousand_items_hold_the_frame_budget` FAILED; after: passed.
- The lens (`set_lens`, `set_lens_anchor`, `lens_blend`, `u_of`, `year_of_u`, `position`): a bent scale u = -ln (1 + (anchor - year) / 1,000) blended with the linear one by the width of the view, exactly linear at 1,000 years or less and fully bent at 20,000 or more, so one view reaches 200,000 years ago (`Lens_max_span` 250,000) while 1000 BC to AD 135 keeps more than a tenth of the axis; `year_at` inverts it by bisection; zoom, pan and drag work in the bent coordinate; the axis picks its round years stretch by stretch. Test `river_lens_spans_deep_time_and_turns_linear`.
- Hover cards (`dwell_ms`, `hover_card_at`): an item's title and years, and a dispute's name and other positions. Test `river_hover_card_on_an_item`.
- `label_left`: a band that starts left of the plot keeps its label at the plot's edge. Test `river_band_label_stays_in_view`.
- `SW_ERA_YEARS.number_text`: deep time reads with US thousands separators ("175,000 BC"); four-digit years as before. Before: `river_deep_time_labels_have_separators` FAILED ("175000 BC"); after: passed.
- Removed: `lane_order`, `positions_shown`, `first_row_of`, `place_item`, `place_dispute` (the index replaces them). 583 passed, 0 failed.

### Fixed (0.46.3 - fitting is a column's choice)

- 0.46.2 made every `SW_COLUMN` take a shortfall back from its growers. Dock panels hold growing lists in columns shorter than the list's natural height; squeezed to almost nothing, `SW_STACKED_ITEMS.begin_frame` asked cairo for a clip of negative height and failed `CAIRO_CONTEXT.clip_rectangle`'s `positive_extent` (Simple Bible's window, caught by its snapshots before release). Now a column fits only when asked: `SW_COLUMN.fitting` (fluent) and `is_fitting`; a plain column keeps its growers' natural heights as before 0.46.2. Before: `short_column_takes_space_back_from_a_grower` FAILED on 0.46.2 ("a plain column does not shrink its grower: expected 2000, got 251"); after: 578 passed, 0 failed, twice.
- `gw29_hundred_thousand_rows_light/dark`: the contracts-on growth check compares halves of ten frames, not five; one burst of other work on the machine failed the light or the dark run in turn.

### Fixed (0.46.2 - a short column takes space back from its growers)

- `SW_COLUMN.arrange`: when the column is shorter than its children's natural heights, the growing children give the shortfall back by weight, down to each one's `min_height`, so the children after them stay inside. Before, only leftover space was handed out; a grower taller than its column pushed the rest off the bottom (Simple Bible's Help > About: the text kept its height while the sheet was resized, and Close sat under a gap). Before: `short_column_takes_space_back_from_a_grower` FAILED (577 passed, 1 failed); after: 578 passed, 0 failed.

### Fixed (0.46.1 - design scan 55)

- One floor for a line's height: `SW_TEXT_GEOMETRY.floor_line_height` (the leading face of a host's role policy, else the kit's) serves the block floor, the empty-piece floor and `SW_TEXT_BOX.row_height`. 0.46.0 had moved one of three: a document whose reading face has a shorter line than the UI face stood a one-line paragraph a UI line tall, so its second line added 17 px and its third 21. Before: `each_line_adds_one_line_of_its_face` FAILED; after: 577 passed, 0 failed. Also `empty_document_block_stands_a_line_of_its_face`.
- One clipboard writer: the parentless mixin `SW_COPYING.copy_text`, inherited by `SW_DATA_GRID`, `SW_TREE`, `SW_LABEL`, `SW_PARAGRAPH_LIST`, `SW_TEXT_SELECTION` (so the document view, parallel text and interlinear), `SW_TEXT_BOX`, `SW_CHAT_THREAD` and `SW_SPREADSHEET`; five private copies from 0.46.0 and four inline writers are gone.

### Added (0.46.0 - right-click menus everywhere; panes that fold and maximize)

- `SW_WIDGET.set_menu_extension` and `offered_menu`: a client's own items stand above a widget's own right-click menu, a separator between; `SW_WINDOW` presents `offered_menu`. `SW_MENU.append_items` and `index_of_label`.
- Default menus: `SW_DATA_GRID` Copy cell, Copy row, Copy all rows (titles first, tab-separated); the right-click notes the row (`context_model`, `context_object`, outlined) WITHOUT selecting it, so `on_select` does not fire. `SW_TREE` Expand or Collapse, Expand all, Collapse all, Copy (`expand_all`, `collapse_all`, `context_node`). `SW_DOC_UNITS` (document view, parallel text, interlinear) Open link, Copy, Copy paragraph / verse / line, Copy all, Select All; `SW_INTERLINEAR` adds Copy word. `SW_PARAGRAPH_LIST` Copy paragraph, Copy selected, Copy all. `SW_LABEL` Copy while it has text.
- `SW_DOCK_HOST`: `collapse_zone`, `expand_zone`, `toggle_zone`, `set_all_collapsed`, `is_folded`, `is_focused_on_center` - a folded zone is a strip along the edge naming its panels (set along the strip on the west and east through the new `SW_PAINTER.push_rotation`); a click on a name opens the zone at that panel; `set_panel_marked` puts a dot beside a name. `set_maximizable`, `maximize_panel`, `restore_maximized`, `toggle_maximized`: a panel takes the whole host. The snapshot keeps folds (`collapsed` lines).
- `SW_DOCK_ZONE`: bar buttons (fold chevron on the zone's top bar or tab strip, maximize on a maximizable panel's bar, restore on a maximized one; `button_at`, `strip_panel_at`), a double click on a bar maximizes or restores when the host does not float panels, and a right-click on a bar, tab or strip offers Maximize or Restore, Collapse or Show, and Move to another zone.
- `SW_WIDGET.vanish`: a widget and its subtree off the surface (no extent), so pills and hit tests pass panels a fold or a maximized panel covers.
- Tests: `SW_CONTEXT_PANE_ASSAULT` (8). `a_context_click_on_nothing_offers_nothing` now holds its case with an empty label, since a label with text offers Copy.

### Fixed (0.46.0 - an empty line as tall as a line of text)

- With the theme's UI face installed (Archivo, by simple_bible 0.7.18 on 2026-10-27), a shaped line of text stood 25 px and an empty one 21 (37 against 41 in a paragraph list): `SW_SHAPING.line_height` measured the general list's first face while `set_theme_faces` puts the theme face first for Latin only. It now measures the theme face leading the list (`primary_fonts`), and `SW_TEXT_GEOMETRY` floors an empty piece at its own role policy's line when a host set one. Before: `textbox_shaped_lines_stack_at_row_height` and `empty_paragraph_stands_a_line_tall` FAILED on unchanged main (573 passed, 2 failed); after: 575 passed, 0 failed.

### Fixed (0.45.2 - design scan 37)

- A refill kept the stack's row request: a word or row asked for in a laid-out view stays armed until the next measure, so a refill that asked for nothing (simple_bible's Interlinear on a whole chapter) jumped to the old place. `SW_STACKED_ITEMS.forget_pending_scroll`, called by every refill: `SW_INTERLINEAR.wipe_out`, `SW_PARALLEL_TEXT.wipe_out`, `SW_PARAGRAPH_LIST.wipe_out`, `SW_DOCUMENT_VIEW.set_document`. Before: `refilled_interlinear_forgets_an_old_scroll` FAILED; after: passes.

### Fixed (0.45.1 - a mark left of its run)

- `SW_CLUSTER_MATH.cluster_x` passed HarfBuzz's x through, and a mark placed left of its run's origin (a Hebrew cantillation accent on the first letter, as MACULA writes Genesis 1:1) gave a negative edge: the `non_negative` postconditions failed and simple_bible's Interlinear tab died on its first frame. The edge is now held within the run (new postcondition `within_run`). Before: `interlinear_lays_out_cantillated_hebrew` FAILED (565 passed, 1 failed); after: 566 passed, 0 failed.

### Added (0.45.0 - an interlinear opens at its verse)

- `SW_INTERLINEAR.scroll_to_token` (and so `select_token`) asked before the words are laid out - a chapter just filled - is met at the next layout (`pending_scroll_token`), as `SW_STACKED_ITEMS` does for rows. simple_bible's Interlinear tab opens at the verse read. Before: `interlinear_scrolls_to_a_word_chosen_before_layout` FAILED (564 passed, 1 failed).

### Fixed (0.44.2 - design scan 35)

- `SW_MENU_BAR` and `SW_MEDIA_TRANSPORT` had no `preferred_width`: the 0.44.1 toolbar bug in its siblings (in a row they got no room and a click fell outside them). The menu bar now claims the width of its titles (from `pad_bounds`), the transport its button, clock and a `Min_bar_width` seek bar. Before: `menu_bar_and_transport_in_a_row_claim_their_width` FAILED (563 passed, 1 failed); after: 564 passed, 0 failed.
- New deferred `SW_BOX_CONTAINER`: the child list, `put`, `add`, `remove`, the gap and `sub_widgets`, which `SW_ROW` and `SW_COLUMN` had copied byte for byte. `SW_TOOLBAR` measures, draws and hit-tests with one formula (`tool_width`, `tool_advance`, named constants) instead of three copies.

### Fixed (0.44.1 - a toolbar in a row)

- `SW_TOOLBAR` had no `preferred_width`: placed in a row (not growing) it got no room, drew its tools past its bounds, and a click on them fell outside it (simple_bible's C10 Parallel did nothing). It now claims the width its tools are drawn in. Before: `toolbar_in_a_row_claims_its_width` FAILED; after: 563 passed, 0 failed.

### Added (0.44.0 - one set of panes, two arrangements)

- `SW_ROW.remove` and `SW_COLUMN.remove` (take a child out to put it elsewhere), `SW_PARALLEL_TEXT.set_column_title`, `SW_WINDOW.clear_reference_marks`: what simple_bible's Simple and Study layouts need to move the same panes and rename their pills. Test `layout_moves_remove_retitle_and_clear_marks`.

### Added (0.43.0 - select all on focus)

- `SW_TEXT_BOX.selects_all_on_focus` (single-line boxes by default; `set_selects_all_on_focus` to choose): gaining focus selects every character, so typing replaces the text; the click that brought focus keeps it selected; the next click places the caret. Multi-line boxes place the caret, so one keystroke never replaces a document. Larry's rule for every editable field (2026-10-26), after simple_bible's reference box joined "John 3:16" onto "Genesis 1". Test `textbox_focus_selects_all_then_a_click_places_the_caret`; 561 passed, 0 failed.

### Added (0.42.0 - window title)

- `SW_WINDOW.set_title`: rename the window after it is made; the caption changes at once when it is up (simple_shell 1.25.0 `set_caption`). Test `set_title_renames_the_window`; 560 passed, 0 failed.

### Fixed (0.41.2 - design scan 22)

- A kept scroll request (0.41.1) is dropped when the list no longer reaches its item, so it can never move the view later when rows grow again. Before: `gw06_a_scroll_for_vanished_rows_is_dropped` FAILED (the view jumped to row 40); after: 559 passed, 0 failed. Report: `.eiffel-workflow/evidence/design-scan-since-7b79425.md` (0 HIGH; the uneven wrapper contracts and SW_LIST stay LOW).

### Fixed (0.41.1 - a scroll asked for during a refill is kept)

- `SW_STACKED_ITEMS.scroll_item_into_view` (so `SW_PARALLEL_TEXT.scroll_to_row`, the document view and the interlinear) dropped a request made after the rows were replaced and before the next layout: the old stack answered it. The request is now kept (`pending_scroll_item`) and met once the next `measure_stack` has restacked. Found by simple_bible's reading pane (a new chapter opened at a verse showed verse 1). Before: `gw06_scroll_to_row_waits_for_new_rows` FAILED; after: 558 passed, 0 failed.

### Added (0.41.0 - reference marks)

- `SW_WINDOW.add_reference_mark (widget, code, tip, corner)` and `set_reference_marks_shown`: numbered pills (the design boards' burnt-orange marker, white text and rim) at a chosen corner of each laid-out widget, kept on screen; the pill under the pointer shows its tip (`hovered_reference_mark`, `reference_mark_at`). A screenshot with the pills on can say "P05.4" and be understood. Hidden pills cost one boolean per frame. First user: simple_bible's View > Show design pills. Test `reference_marks_sit_on_corners_and_tip`; 556 passed, 0 failed.

### Fixed (0.40.2 - SCOOP apps compile again)

- `SW_WIDGET.accessible_node_id_counter` was a `once ("PROCESS")` of a non-separate type, which SCOOP rejects (VFFD(8)). The library's own targets compile in thread mode, so from 0.34.1 (2026-10-25, the UI Automation bridge) every SCOOP application failed to compile, unseen. It is now a plain `once`: per processor under SCOOP, and a window's widgets all live on its one processor, so node ids stay unique where UI Automation reads them. Before: simple_bible's window (a SCOOP app) stopped at VFFD(8); after: it compiles. Test suite: 555 passed, 0 failed.

### Fixed (0.40.1 - design scan 20, since 1260e13)

Report: `.eiffel-workflow/evidence/design-scan-since-1260e13.md` (5 HIGH,
10 MEDIUM, 7 LOW). Needs simple_shell 1.24.1. Each fix has a test that
failed on the old code:
- **HIGH**: on a dark or high-contrast screen the preview drew the content
  in the screen's inks on white paper (light grey on white), unlike what
  prints. `draw_page` now draws in the job's paper theme whatever painter
  it is given (`SW_PAINTER.twin_in_theme`).
  `scan20_the_preview_shows_paper_inks_on_a_dark_screen` (old code: "0
  dark pixels").
- **HIGH**: printing left a widget that is also shown laid out at the
  paper's size. The job puts a placed widget back after paginating and
  after each page (one never placed stays laid out for print, so the
  preview does not re-lay it every frame).
  `scan20_printing_leaves_the_widget_where_it_was`.
- **HIGH**: `print_to` had no rescue: a page that failed to draw leaked its
  surfaces and left the process's printer document open, refusing every
  later print; a null printing surface went unchecked. **HIGH**: its
  failures never set `last_error`, so `write_pdf`'s fallback (the route the
  shipped cairo.dll forces) reported no reason. Both fixed: every failure
  says why, the document is aborted, the surfaces released.
  `scan20_a_failed_print_says_why_and_lets_go` (old code: "and it says
  why"), with a test widget whose drawing fails.
- **HIGH** (simple_shell 1.24.1): a printer owns only its own document.
- 555 pass.
- Open (in the report): the preview draws every visible sheet each frame;
  `print_height` measures by laying out; units assume square dots; the
  file helpers and the paper theme beside `export_theme` could be shared.

### Added (0.40.0 - GW-20: print preview, print, print to PDF)

Needs simple_shell 1.24.0 (SHELL_PRINTER) and simple_cairo 1.6.0 (the
Windows printing surface).
- **`SW_PRINT_JOB`**: any widget printed. It is laid out at the page's
  content width and its whole printable height, then cut into pages where
  the widget says a page may end cleanly; pages are drawn in vector through
  SW_PAINTER on paper white in the theme's faces, with a header line and
  "Page n of m" in the margins. `write_pdf`, `print_to (printer, title,
  output)`, `draw_page`, `page_count`, `page_top`/`page_bottom`,
  `last_error`.
- **`SW_PAGE_SETUP`**: Letter or A4, landscape, margins in points, header,
  page numbers, `points_per_pixel` (0.75 prints at the screen's size).
- **`SW_PRINT_PREVIEW`**: the sheets one under another, scrolled under a
  bar; `page_at_top`, `show_page`.
- **`SW_PRINTER`**: the toolkit's name for SHELL_PRINTER.
- **SW_WIDGET**: `print_height` (preferred height; SW_DOC_UNITS answers its
  whole text) and `clean_break` (a widget without parts keeps itself whole,
  one with parts asks the parts; SW_DOC_UNITS breaks between lines).
  **SW_PAINTER**: `push_transform`/`pop_transform`.
- **PDF**: the shipped cairo.dll cannot write PDF (its first page fails
  with "out of memory"; see simple_cairo's CHANGELOG), so `write_pdf` falls
  back to the Windows PDF printer and waits for the spooler's file
  (`used_windows_pdf_printer`). A rebuilt cairo.dll makes the cairo route
  work with no change here.
- Tests: no page edge cuts a label or a line of a document; a PDF is
  written; the commentary prints through Microsoft Print to PDF with no
  dialog; landscape lays the text out wider; the preview pages. Evidence
  `gw20_page_light.png` (a Letter sheet: header, Hebrew right-aligned,
  Greek, page number) and `gw20_preview_light.png`, looked at. 552 pass.
- Open: grids and lists print only what fits (they report no whole height
  yet); no printer dialog by design (the application lists printers); the
  preview draws every visible sheet each frame (no cache); copies and page
  ranges are not offered.

### Fixed (0.39.1 - design scan 19, since b8d50ce)

Report: `.eiffel-workflow/evidence/design-scan-since-b8d50ce.md` (4 HIGH,
8 MEDIUM, 7 LOW). Needs simple_shell 1.23.1. Each fix has a test that
failed on the old code:
- **HIGH**: an accelerator ran twice from a floating window - once on the
  key down, again on the control code its WM_CHAR carries (a Ctrl+B
  toggle undid itself). The floating window now arms a swallow as the main
  window does. `scan19_an_accelerator_runs_once_from_a_floating_window`
  (old code: "expected 1, got 2").
- **HIGH**: closing a floating window never released its cairo frame;
  every float and unfloat leaked a client-sized surface. `close` destroys
  it (`is_frame_released`), and `render` and `export_frame_png` now
  require an open window. `scan19_closing_gives_the_frame_back`.
- **HIGH**: a floating panel could be shown in a zone behind the floating
  window's back. `restore_layout` keeps floating panels out of their zones,
  `move_panel` only changes where a floating panel will dock, and
  `show_panel` requires `not is_floating`.
  `scan19_a_floating_panel_stays_out_of_its_zone` (its first assertion,
  the focus one below, is where the old code failed).
- **HIGH** (simple_shell 1.23.1): a panel destroyed with its owner kept
  answering open.
- MEDIUM: floating a tree now drops the main window's focus, hover and
  capture inside it (`let_go_of`), and `close` releases a pressed widget.
- 547 pass.
- Open (the report has them all): every main frame repaints every
  floating window (no dirty flag); size events are not coalesced; the
  input state and itinerary are still two copies (the report proposes a
  deferred SW_INPUT_SURFACE beside SW_POINTER_ROUTING); a deactivated
  floating window still draws its focus ring; floating trees are not
  published to screen readers; event 48 means outer size for plain panels
  and client size for framed ones.

### Added (0.39.0 - GW-22: floating panels in a second window)

Needs simple_shell 1.23.0 (framed panels).
- **`SW_FLOATING_WINDOW`**: one widget tree in a floating window of its own
  (a framed simple_shell panel: caption, sizing border, focus, owned by the
  main window, never topmost) for a study pane on a second monitor. It
  draws in the owner's theme and shaping kit, inside the theme's padding,
  and takes clicks, double clicks, drags, the wheel, hover and leave, keys,
  characters (surrogate pairs whole) and Tab like the main window; a key
  the owner's accelerator table claims still runs it (F5, Ctrl+letter).
  Every input goes through the owner's one itinerary, so all windows
  repaint together. Input waits while the owner shows a modal dialog.
  `export_frame_png` writes its client area.
- **SW_WINDOW**: `float_widget`, `unfloat`, `floating_windows`,
  `floating_at`, `enable_floating_panels (host)`, `float_dock_panel`; panel
  events (41-50, 60-65) go to the floating window that owns their slot.
- **SW_DOCK_HOST**: `float_panel`, `redock_panel`, `is_floating`,
  `can_float`, `request_float`, `on_float_request`. With floating enabled a
  **double click on a tab or a title bar** tears that panel off; closing
  the floating window docks it again where it was.
- **`SW_POINTER_ROUTING`** (pushed up out of SW_WINDOW): `spine_click`,
  `spine_wheel`, `spine_file_taker`, `ring_neighbour`, `paired_code_point`
  - the walks both kinds of window take. SW_WINDOW's `bubble_wheel` is now
  `spine_wheel`; behaviour unchanged.
- Tests: `gw22_double_click_floats_a_tab_and_close_docks_it`,
  `gw22_a_floating_window_takes_input_like_the_main_one`,
  `gw22_a_modal_dialog_holds_the_floating_window`, evidence
  `gw22_floating_light.png` / `gw22_floating_dark.png` (looked at: Hebrew
  and Greek shaped, inset). Test widget `SW_TEST_RECORDER`. 544 pass.
- Open: popups, sheets and hover cards inside a floating window; per-widget
  pointer shapes there; screen-reader publishing of floating trees;
  `layout_snapshot` does not record floating panels or their geometry
  (they come back docked); the first placement is a fixed offset, not the
  second monitor.

### Fixed (0.38.6 - design scan 18, since af94462)

Report: `.eiffel-workflow/evidence/design-scan-since-af94462.md` (1 HIGH,
6 MEDIUM, 7 LOW).
- **HIGH H1**: the tab ground scaled with the theme, but the SW_TABS drag
  outline and the SW_DOCK_ZONE separators kept 4-pixel literals, so at
  text scale 2 the outline stood 4 pixels above the ground it outlines.
  SW_TAB_STRIP now has `tab_inset` (half the padding), `draw_tab_outline`
  and `draw_tab_separator` beside `draw_tab_ground`; both heirs lost
  their literals. Test `scan18_drag_outline_hugs_the_ground_at_any_scale`
  reads the pixels at scale 2: it failed on the old code ("the outline is
  on the ground's top edge") and passes now. Scale 1 is unchanged (the
  evidence PNGs are byte-identical).
- M2: the GW-29 test prints which build it measured (lean or contract).
- M3: SW_PAINTER, SW_HEATMAP and SW_COLOR_PICKER inherit SW_COLOR_MATH
  `{NONE}`; only SW_THEME exports it.
- M5: SW_WINDOW names its 31 event numbers from `SHELL_EVENTS`
  (`Event_window_press` and the rest); key codes and modes stay numbers.
- simple_shell 1.23.0 (framed panels, GW-22): rebuilt clean, 539 pass.
- Open: M1 (no pixel check on the dock's tab look), M4 (a stateless
  block parser before a third geometry heir), M6 (nothing checks the C
  header's numbers against the registry), and the LOW items.

### Changed (0.38.5 - the layered layout, headless)

- New **`SW_LAYERED_LAYOUT`** (design scan finding 10): cycle breaking,
  longest-path layering, dummy nodes and barycenter ordering moved out of
  SW_DIAGRAM (849 lines, now 600) into an engine with no painter and no
  widget - `lay_out (node_count, edges)`, then `layer_of`, `order_of`,
  `is_reversed`, `edge_chains`, `graph_layer`/`graph_order`, `segments`,
  `crossing_count`, `layer_count`. SW_DIAGRAM keeps placement and drawing
  and its public names, delegating through `layering`. New test
  `layered_engine_runs_headless` (no window); 538 pass; the GW-23 outline
  evidence is byte-identical. Not moved: SW_ORG_CHART's forest depth (a
  parent walk, nothing to share yet) and the lane timeline's interval
  packing (a different algorithm), as the scan advised.
- simple_shell 1.22.2 (`SHELL_EVENTS`): rebuilt clean against it, 537 pass.

### Changed (0.38.4 - exports in their own ancestor; GW-29 timing without collector pauses)

- **`SW_WIDGET_EXPORTING`**: the GW-21 export cluster (`widget_image`,
  `export_widget_png`, `copy_widget_image`, `export_theme`, `can_export`,
  `export_margin`, `exports_in_screen_theme`) moved out of SW_WINDOW
  (3,350 lines, now 3,209) into a deferred ancestor; the window supplies the
  screen theme, painter, shaping kit and hovered widget. No change for
  callers.
- **GW-29 timing**: a full suite once put a 190-millisecond collector pause
  into one measured frame (page-jump median 66 milliseconds in that run).
  The test now collects fully before its timed loops and switches
  collection off for each measured frame. Two full runs: 537 pass, page
  jump 14.7-15.8 milliseconds.

### Changed (0.38.3 - one way to paint a tab)

- `SW_TAB_STRIP.draw_tab_ground` paints a tab's ground and answers its
  label's ink: the selected tab on the surface with an accent underline,
  a hovered one on the quiet surface, insets and rule from the theme.
  SW_TABS and SW_DOCK_ZONE both call it, instead of two copies that had
  drifted (square versus rounded fills, 2 versus 3 pixel underlines).
  The dock's selected tab now looks like a notebook's. 537 pass; the
  evidence checked (gw15_tabs, gw05_study_layout).

### Fixed (0.38.2 - GW-29's budget held in the build it belongs to)

- The 60 Hz assertions of the 100,000-row grid failed about one run in
  three in the contract build: switching contracts off at run time does
  not make that build as fast as the shipped one (page jump 15-18
  milliseconds there, 5.7-7.9 in the lean build on this machine), and
  0.28.2 rebuilt from its own commit failed the same way. Following
  Larry's rule that timing belongs to the shipping build, the lean build
  (`ec.sh release`, simple_widgets_lean.exe) is held to 16.7 milliseconds
  and the contract build to twice that, which still catches a gross
  regression; both report their numbers. `is_lean_build` probes a library
  precondition (a test-class one cannot tell: the testing cluster runs
  without assertions). The class note says why, for the next editor.
- Verified: contract build 6 of 6 runs green; lean build page jump
  5.7-7.9 milliseconds, wheel 1.7-2.1, 3 of 3 green. 537 pass in the
  contract build; the lean suite fails only `theme_gw28_unreadable_rejected`,
  which proves a contract and has none to prove there.

### Changed (0.38.1 - one parser for generated geometry)

- New deferred **`SW_GEOMETRY_DATA`** (`parse_block`, `flush`, `pending`):
  SW_WORLD_GEOMETRY and SW_REGION_GEOMETRY inherit it instead of carrying
  two parser copies that had drifted (the world's ended its last block by
  comparing the block's identity with `data_5` and kept 6 numbers at
  least, the region's 4). Both generators (`tools/gen_world_geometry.py`,
  `tools/gen_region_geometry.py`) emit the inheritance and a `flush` after
  the last block; regenerated, the world's data is identical to before.
  537 pass (GW-29's contract-build timing excepted, see 0.37.3).

### Changed (0.38.0 - one place for colour arithmetic)

Larry 2026-10-25: "keep going with your recommends" - the extractions the
scans proposed, each behaviour-preserving on its own branch.
- New mixin **`SW_COLOR_MATH`**: `channel_fraction`, `luminance`,
  `contrast_ratio`, `mixed`, `mixed_channel` (clamped). SW_THEME, SW_PAINTER,
  SW_HEATMAP and SW_COLOR_PICKER inherit it side by side instead of keeping
  four copies; SW_THEME keeps the same public names through it, so callers
  are unchanged. The heat map's `blend` (which did not clamp) now calls
  `mixed`; SW_PAINTER's private `channel_of` is gone. 537 pass.

### Fixed (0.37.3 - chips and badges read in every theme)

- **SW_BADGE** wrote its count in `surface` on the semantic fill and
  **SW_CHIP** its label in the fill colour on its wash, ignoring the
  GW-28 tokens made for exactly this: in dark the accent chip read at
  3.7:1. Badges now use `ink_on_accent` / `ink_on_success` /
  `ink_on_warning` / `ink_on_danger`, chips `ink_accent` / `ink_success` /
  `ink_warning` / `ink_danger`; a neutral chip keeps muted ink wherever it
  reads at 4.5:1 and takes full ink in a contrast palette. The colours are
  queries now (`fill_color`, `text_color`).
- Test `chips_and_badges_read_in_every_theme` (every kind, light, dark and
  the four Windows contrast palettes) failed before the fix. 537 pass.
- Noted, not changed: GW-29's page-jump frame in the test build (contracts
  compiled in, switched off) now runs 15-17 milliseconds against the
  16.7 budget and fails about one run in three - 0.28.2 built from its own
  commit does the same on this machine today, so it is not a regression;
  the shipped lean build measured 5.1. The page-jump work is an open
  performance item.

### Fixed (0.37.2 - the seventeenth scan, since 086d3e8: long edges)

Three HIGH findings in the layered layout, each with a test:
- **Long edges go round, through dummy nodes** (the Sugiyama method): an
  edge skipping layers was one straight segment through whatever stood
  between and took no part in the ordering. It now has a dummy node in
  every layer it crosses, ordered with the rest, and is drawn through them
  (`edge_route`; `scan17_a_long_edge_goes_round_the_node_between`).
- **Crossings of long edges are counted:** `crossing_count` walks the
  one-layer segments, so a crossing between long edges is no longer
  reported as 0 (`scan17_crossings_of_long_edges_are_counted` failed on
  0.37.1). It also no longer reads past a stale list after `connect`.
- **The cache and the reproduction are proven:** `layout_runs` counts
  layouts; frames that change nothing do not lay out again, and a forced
  relayout lands on the same pixels (`scan17_the_layout_is_cached_and_reproduced`).
  `is_layout_current`.
- Not done (MEDIUM): labels wider than the widget overflow; a layer taller
  than the widget; the layout cache misses relabels; the layering could be
  a headless helper shared with SW_ORG_CHART. Report:
  `.eiffel-workflow/evidence/design-scan-since-086d3e8.md`. 536 pass.

### Fixed (0.37.1 - the sixteenth scan, since 3f9242a: the Caspian)

- **Seas inside the land are water.** The generator kept only the land's
  outer rings, so the Caspian Sea - an interior ring of the land - drew as
  land. `tools/gen_region_geometry.py` emits the interior rings as
  `SW_REGION_GEOMETRY.holes`, which SW_MAP paints as water whatever the lake
  layer says. Test `scan16_the_caspian_is_water` failed on 0.37.0.
- Kept as designed (the scan called it HIGH): hiding the lakes layer shows
  lakes as land - that is what the layer hides; seas inside the land stay
  water.
- Not done (MEDIUM): rivers stop just short of the region box; a seam where
  the 1:10m coast meets the 110m coast; the hover chip still reads the
  5-degree raster; no culling; the geometry parsers of SW_WORLD_GEOMETRY
  and SW_REGION_GEOMETRY are copies (a shared ancestor waits for Larry).
  Report: `.eiffel-workflow/evidence/design-scan-since-3f9242a.md`. 533 pass.

### Added (0.37.0 - GW-23: a deterministic layered layout for SW_DIAGRAM)

For clause outlines (C09): the force layout is not reproducible.
- **`SW_DIAGRAM.set_layered (True)`**: cycles broken by reversing the back
  edges a depth-first walk in node order finds (`is_reversed`,
  `back_edge_count`; drawn dashed); layers by longest path (`layer_of`), so
  every other edge runs left to right (postcondition); each layer ordered
  by four barycenter sweeps, ties by node id (`order_of`), cutting crossings
  (`crossing_count`); layers spaced by their widest label, nodes spread and
  centred down the height. The same graph lays out to the same pixels every
  time, and only again when the graph or the size changes. Edges start at
  the end of the tail's label (none runs through a label) and carry
  arrowheads; dragging is off in this mode. The force layout stays the
  default.
- Tests (`SW_LAYERED_DIAGRAM_ASSAULT`, 6): edges left to right; the same
  pixels for the same graph; a crossing undone; a cycle broken by one edge
  and laid out; Romans 1:16-17 as an outline with Greek words in both themes
  (evidence `gw23_outline_light.png`, `gw23_outline_dark.png`). 532 pass.

### Added (0.36.0 - GW-19: the Atlas - regional map, routes, labels, layers, dark style)

For the Atlas (P14).
- **`SW_REGION_GEOMETRY`** (generated by the new `tools/gen_region_geometry.py`
  from Natural Earth 10m, public domain): the Mediterranean, the Levant and
  Mesopotamia - lon 8 to 50, lat 22 to 46 - as 237 land rings, 29 lakes
  (the Sea of Galilee, both basins of the Dead Sea) and 72 river lines
  (Jordan, Nile, Euphrates, Tigris), clipped to the box and simplified to
  0.012 degrees: about 9,000 points.
- **`SW_MAP`**: from `Region_zoom` (6) the regional detail replaces the
  world's coast inside the box; `Max_zoom` is 128 (was 16), a Levant valley
  across. **Layers** (`Layer_region`, `Layer_rivers`, `Layer_lakes`,
  `Layer_routes`, `Layer_labels`, `Layer_markers`; `set_layer_shown`).
  **Routes** (`add_route`, flat lon/lat, dashed when uncertain through
  GW-18). **Places** labelled from their own zoom (`add_place`), a label that
  would overlap one already placed left out (`drawn_labels`). A **map
  palette** from the theme (`water_color`, `land_color`, `coast_color`,
  `river_color`, `route_color`) keeps land and water at least 1.2:1 apart in
  light and dark; land is the surface, so ink labels read on it.
- `SW_THEME.mixed` is public now (the palette blends theme colours with it
  rather than a third copy of the channel arithmetic).
- Found by the Galilee test and the evidence before merge: the clipped
  mainland ring (3,266 points) overflowed a fixed 3,000-point screen buffer
  and was skipped, so the Levant drew as open sea; the buffer is sized from
  the data now (postcondition `holds_every_ring`).
- `map_draws_real_coastlines` and the zoom-ceiling assertion follow the new
  palette and `Max_zoom`.
- Tests (`SW_REGIONAL_MAP_ASSAULT`, 6): land and water apart in both themes;
  Galilee is water only with the regional and lake layers; rivers and routes
  on their layers, an uncertain route dashed and a certain one whole; labels
  from their zoom without overlap; the Levant with Hebrew and Greek place
  names in both themes (evidence `gw19_levant_light.png`,
  `gw19_levant_dark.png`). 526 pass.

### Fixed (0.35.1 - the fifteenth scan, since c9d5571: the timeline)

Five HIGH findings, each with a test that failed on 0.35.0:
- **A dispute across lanes is bracketed in each lane.** One envelope box
  per dispute kept only the last lane's; boxes are per dispute and lane now
  (`scan15_a_dispute_across_lanes_is_enveloped_in_each`).
- **Only class A is a tick.** One year of class B, C, D or F was drawn as a
  day; it is a bar at least six pixels wide (`scan15_a_one_year_bar_is_not_a_tick`).
- **Disputes are drawn, not hidden.** Positions were shown one by one, so a
  dispute of detail positions vanished at millennium scale; all positions
  show while the envelope is on the view (`scan15_a_dispute_never_loses_a_position`).
- **Every year mark at the middle of its year.** Ticks stood at the start,
  the cursor and labels at the middle: 200 pixels apart at a two-year view
  (`scan15_a_tick_stands_where_the_cursor_stands`).
- **Every lane can be reached.** SW_LANE_TIMELINE now inherits SW_VSCROLLING:
  a scrollbar, Up/Down and Page Up/Page Down scroll the lanes (the wheel
  still zooms); the preferred height is the laid-out height
  (`scan15_preferred_height_counts_rows_and_headers`,
  `scan15_lanes_below_the_bottom_can_be_reached`).
- A class note `scan_15` records the five rules for the next editor.
- Not done (MEDIUM): class D's stated confidence and class E's authority are
  not drawn; the provenance badge shares the scheme badge; selection is not
  drawn; the keyboard cannot set the cursor or select; layout is
  lanes x disputes x items; the year mapping is written beside SW_SCALE
  rather than with it. Report: `.eiffel-workflow/evidence/design-scan-since-c9d5571.md`.
  520 pass.

### Added (0.35.0 - GW-17: SW_LANE_TIMELINE, a world timeline)

For the world timeline (P13, research 11-HISTORY-TIMELINE).
- **`SW_ERA_YEARS`**: astronomical years (1 BC = 0) read as BC/AD or BCE/CE;
  no label ever shows a year zero (postcondition); `range_label`
  ("1650-1550 BC", "AD 29-34", "4 BC - AD 30"); ticks on round DISPLAYED
  years (100 BC, AD 100); `nice_step`.
- **`SW_TIMELINE_ITEM`**: a range of years in a lane with a certainty class
  A-G, a badge, a dispute, a lean and an importance for semantic zoom.
  Tradition (G) is never a point (invariant).
- **`SW_LANE_TIMELINE`**: lanes in collapsible groups (a click on a header
  folds it), overlapping items stacked into rows, every certainty class
  drawn by pattern with a label through GW-18 (A tick, B solid bar, C bar
  with its scheme badge, D gradient bar, E soft band, F dashed bar "per the
  text", G hatched band "tradition"), a dispute's positions stacked inside
  its dashed envelope, the owner's lean marked with its wording and never
  pre-selected, semantic zoom (periods at millennium scale, major events at
  century scale, everything at decade scale), a synchronism cursor with its
  year in a chip and `slice (year)` listing every visible item at that
  moment. The wheel zooms about the pointer, a drag pans, Left/Right pan,
  plus and minus zoom, Home fits everything; `on_select`, `on_cursor`. Year
  labels that the plot's edge would cut are left out, and a right-to-left
  title keeps its class label after it (both seen in the evidence).
- Tests (`SW_LANE_TIMELINE_ASSAULT`, 8): years without a year zero across
  6,000 years; round ticks; whole axis labels at several views; stacking and
  disputes; semantic zoom and folding; cursor, wheel and tradition; a pilot
  timeline with pointed Hebrew and polytonic Greek titles in both themes
  (evidence `gw17_timeline_light.png`, `gw17_timeline_dark.png`). 514 pass.

### Fixed (0.34.2 - the fourteenth scan, since c01e578: hatch cost)

- **A huge hatch is bounded.** The clip throws ink away only after every
  mark is built, so a dot hatch over a 5,000-pixel box was 1.5 million arcs
  (599 milliseconds; a 200,000-pixel cross hatch longer still). The spacing
  now widens until at most `Max_hatch_marks` (20,000) dots or
  `Max_hatch_lines` (2,000) lines fit; boxes the size of a screen are
  unaffected. Test `scan14_a_huge_hatch_is_bounded` (timed inside
  `without_contracts`) failed on 0.34.1.
- Not done (MEDIUM): the colour-channel arithmetic is copied in SW_PAINTER,
  SW_HEATMAP and SW_THEME; dash lengths scale with the text but the width
  does not; fractional scales are not snapped to whole pixels; the dash
  and hatch proportions are literals. Report:
  `.eiffel-workflow/evidence/design-scan-since-c01e578.md`. 506 pass.

### Fixed (0.34.1 - the thirteenth scan, since fc84965: the UI Automation bridge)

Needs simple_shell 1.22.1. Six HIGH findings, each with a test that failed
with the old behaviour:
- **Served once the window opens.** `run` renders before the native window
  exists, so the only publish named no window and polling readers got
  nothing. `on_shell_open` publishes, and a frame republishes when the
  served window is not this one (`scan13_a_real_window_is_served_once_it_opens`,
  on a hidden, offscreen window that closes itself on its first heartbeat).
- **A reader's request republishes** (event 59): a window renders only on
  input, so a reader that asked later was served a stale tree
  (`scan13_a_request_republishes`).
- **Stable node ids.** Ids were tree positions, so widgets added before a
  text box shifted its id and a focus request reached the wrong widget.
  Each widget now has its own `accessible_node_id` for life;
  `accessible_widget_with_id` finds it (`scan13_ids_survive_an_insert`).
- **The focus is told once**, not on every publish
  (`accessible_focus_tellings`; `scan13_the_focus_is_told_once`).
- **Dialogs, sheets and menus are reachable.** An open sheet's widgets, a
  dialog (a window node with its message and buttons, `SW_DIALOG.button_bounds`)
  and a popup menu's items are published; a focus request is refused under a
  modal dialog or menu (`scan13_a_dialog_is_reachable_and_modal`).
- **Closed and hidden parts are left out.** A closed accordion section was
  published with stale bounds, and a dock zone published none of its panels;
  now open sections and shown panels only (tabbed zone: the active one)
  (`scan13_closed_and_hidden_parts_are_left_out`).
- Not done: rows, cells and items drawn inside a widget; bounds are not
  clipped to scroll areas; no property-changed events; one table per process.
  Report: `.eiffel-workflow/evidence/design-scan-since-fc84965.md`. 505 pass.

### Added (0.34.0 - GW-18: dashes, hatches and gradients in SW_PAINTER)

Phase 4 begins. Certainty classes drawn by pattern, never by colour alone.
- **Stroke styles** `Stroke_solid`, `Stroke_dashed`, `Stroke_dotted`,
  `Stroke_dash_dot`: `dashed_line`, `dashed_polyline`,
  `dashed_rrect_stroke`. Dash lengths grow with the line width and the text
  scale; dots are round.
- **Hatch fills** `Hatch_forward` (/), `Hatch_backward` (\), `Hatch_cross`,
  `Hatch_horizontal`, `Hatch_vertical`, `Hatch_dots`: `hatch_rect`,
  `hatch_rrect`, `hatch_polygon` (a dispute envelope, a map region), in the
  current colour, spacing scaled with the text.
- **Gradients**: `gradient_rect` (one colour to another, across or down) and
  `fade_rect` (one colour from one strength to another: an uncertain edge).
  The gradient is destroyed after use.
- Every call saves and restores the cairo state, so no dash, clip, cap,
  width or gradient leaks into the next drawing.
- Two cairo behaviours found by pixel tests and worked around: a
  zero-length dash in the middle of a pattern draws nothing (the dash-dot
  dot is a half-unit dash), and many small fills under a rounded clip drew
  almost nothing (the dots are one path filled once).
- Tests (`SW_STROKES_ASSAULT`, 6): dashes break where solid does not, dots
  more often, dash-dot shows its dots; nothing leaks; hatches stay inside
  (a rectangle, a rounded box, a triangle) and cross carries more ink than
  one direction; gradients and fades run end to end; a specimen in both
  themes (evidence `gw18_patterns_light.png`, `gw18_patterns_dark.png`).
  499 pass.

### Added (0.33.0 - GW-14, second half: screen readers through UI Automation)

Needs simple_shell 1.22.0.
- **Every widget describes itself**: `accessible_role` (a {SW_ACCESSIBILITY}
  `Role_` constant; a pane when it holds widgets, else custom),
  `accessible_name` (its label or text, or one given with
  `set_accessible_name`), `accessible_value` (read-only) and
  `accessible_children` (what it shows). Standard roles in SW_BUTTON,
  SW_LABEL, SW_TEXT_BOX (its text as value, except a masked line, which
  tells nothing), SW_COMBO, SW_CHECK_BOX and SW_SWITCH (checked / on as
  value), SW_PROGRESS and SW_SLIDER (a percentage), SW_SELECT, SW_RADIO_GROUP
  (the chosen option), SW_GROUP (named by its title), SW_TABS (the shown
  tab as value; only the shown page is reachable), SW_DATA_GRID, SW_LIST,
  SW_TREE, SW_STATUS_BAR, SW_MENU_BAR, SW_TOOLBAR, SW_IMAGE, SW_SEPARATOR.
- **SW_WINDOW publishes** the laid-out tree (node 0 is the window, named by
  its title) on its first frame and on every frame while a UI Automation
  client listens, tells it when the keyboard focus moves, and obeys a
  screen reader's focus request (event 58) when the widget takes focus.
  `is_accessible` is on by default (`set_accessible (False)` stops it);
  `accessibility`, `accessible_widgets`, `accessible_id_of`,
  `publish_accessibility`. New facade class `SW_ACCESSIBILITY`.
- One table per process: with several windows, the last to publish is the
  one served.
- Not yet: rows, cells, tab items and menu items drawn inside a widget are
  not separate elements (a grid is one element); no Toggle, Selection or
  Invoke patterns; SW_DOCUMENT_VIEW keeps the default role.
- Tests (`SW_ACCESSIBILITY_ASSAULT`, 4): roles, names, values and parents,
  the hidden page left out and the masked line silent; pointed Hebrew and
  polytonic Greek names exact; the focus told and requests obeyed or
  refused; a given name, and nothing served when switched off. simple_shell
  proves the same table through a real UI Automation client. 493 pass.

### Fixed (0.32.1 - the twelfth scan, since 02eec11: motion on every path)

Each fix has a test that failed on 0.32.0:
- **The animation setting survives a light/dark flip.** Event 57 set
  `reduces_motion` on the worn theme only, and a light/dark flip only swaps
  themes, so the other member was worn with a stale setting (animation
  turned back on, then dark: still held). One `apply_motion_preference`
  now reads the setting once and sets both followed themes and the worn
  one; following, contrast changes and event 57 all go through it, and
  event 57 tells `on_theme_changed` (`scan12_motion_survives_a_light_dark_flip`).
- **SW_DIAGRAM holds still.** It took one relaxation step on every draw,
  even when motion was reduced. Reduced, it now `settle`s: relaxes to rest
  at once (at most 400 steps) and holds still until nodes, edges, pins or
  its size change (`scan12_diagram_holds_still`).
- Not done: a window that sets its own theme (not following Windows) does
  not learn the animation setting; following Windows overwrites the
  application's own `reduces_motion` on the followed themes, which are the
  application's objects (both documented). simple_shell's scan (no HIGH)
  noted the PowerShell cross-check fails rather than skips where
  PowerShell is locked down. Reports:
  `.eiffel-workflow/evidence/design-scan-since-02eec11.md`, and simple_shell's
  `design-scan-since-6064bb3.md`. 489 pass.

### Added (0.32.0 - GW-14, first half: reduced motion)

Needs simple_shell 1.21.0. (GW-14's other half, the UI Automation bridge,
is its own item.)
- **`SW_THEME.reduces_motion`** and `set_reduces_motion`; carried by
  `adopt_metrics_from`, so a contrast theme and an export keep it.
- **SW_SKELETON** holds still: no shimmer is drawn and its phase does not
  advance. **SW_PROGRESS** in indeterminate mode shows the whole track at
  half strength instead of a travelling band. (Toasts do not move; nothing
  else in the toolkit animates.)
- **SW_WINDOW, following Windows**, carries the animation setting into the
  worn theme (the light, dark or contrast member), live on event 57.
- Tests (`SW_REDUCED_MOTION_ASSAULT`, 3): the skeleton and the band move
  between frames and hold still when reduced; the window follows the
  setting on and off and keeps it in a contrast theme. 487 pass.

### Fixed (0.31.1 - the eleventh scan, since 02dae89: export memory and edges)

Each fix has a test that failed on 0.31.0:
- **Exports free their memory.** Cairo contexts and surfaces have no
  dispose, and `widget_image` never destroyed its context, which also held
  a reference to the image; `export_widget_png` and `copy_widget_image`
  never destroyed the image. Forty exports at four times a 600-pixel label
  grew the process by 440 megabytes. Now the context is destroyed in
  `widget_image`, the two exporters destroy their image, and the header
  says the caller of `widget_image` owns and destroys the image
  (`scan11_exports_free_their_memory`,
  `scan11_widget_image_frees_its_context`, which read the process's
  committed memory).
- **Hover never exports, in the grid and the dock too.** SW_DATA_GRID lit
  its scrollbar thumb and SW_DOCK_HOST its edges from `is_hovered`, which
  silencing does not reach; both use `shows_hover`
  (`scan11_grid_hover_never_exports`).
- **Fractional edges are opaque.** The ground was a rectangle the widget's
  size, so a fractional width left the last column half see-through; the
  whole image is painted (`scan11_fractional_edges_are_opaque`).
- **Oversized exports are refused by contract.** New `can_export` (laid
  out, scale 1 to 4, at most `Max_export_side` = 16384 pixels a side) is the
  precondition of all three export features
  (`scan11_oversized_export_is_refused`).
- Not done: state some widgets record while drawing (SW_CHAT_THREAD's
  scrollbar geometry) is not redrawn after an export in a custom theme; the
  surface-context-painter setup now appears four times in SW_WINDOW and the
  export cluster could become its own ancestor (an extraction, waiting for
  Larry). Report: `.eiffel-workflow/evidence/design-scan-since-02dae89.md`.
  484 pass.

### Added (0.31.0 - GW-21: a widget region to PNG and to the clipboard)

For image export of a pane (share-safe exports, Visual Copy later).
- **`SW_WINDOW.widget_image (widget, theme, scale)`**: the widget drawn
  alone onto a new cairo surface, `scale` times its size (1 to 4) with
  `export_margin` (the theme's `border_width`) all round, so glyphs that
  overhang the widget's box - a Greek breathing before a capital - stay in
  the picture. Hover is silenced quietly (no hover event fires) and
  restored; the widget keeps its place and is laid out again in the screen
  theme, so hit testing stays right. A focused widget still shows its
  focus: clearing it would fire focus events.
- **`export_widget_png (widget, path, scale)`** and
  **`copy_widget_image (widget, scale)`** (copy-as-image, through
  SW_CLIPBOARD).
- **Light by default.** `export_theme` is light with the screen theme's
  sizes and faces, because exports get pasted into other people's
  documents; `set_exports_in_screen_theme (True)` keeps the screen theme.
- Tests (`SW_WIDGET_IMAGE_ASSAULT`, 5): the widget alone at twice its size
  on the light background from a dark window, which stays dark; the screen
  theme when asked; hover never exports (same pixels hovered and not, and
  still hovered after); the PNG reads back at its size and the clipboard
  takes the image; scripture exported in light and in the screen theme
  (evidence `gw21_export_light.png`, `gw21_export_screen.png`). 479 pass,
  none failing (the session was unlocked, so `screen_grab_marries_cairo`
  passed too).

### Fixed (0.30.1 - the tenth scan, since 053211b: contrast grounds)

The contrast theme kept every pairing readable on the window but left the
grounds widgets actually draw ink on unchecked. Each fix has a test that
failed on 0.30.0:
- **Selected rows show.** Every wash was the window, and eleven widgets
  paint a selected row or selected text with `wash_accent`. It is now the
  selection ground, a step toward the highlight that stands out from the
  window and keeps the ink at 4.5:1 (`scan10_selected_rows_show_in_contrast`).
- **A pressed button's label reads.** `outline` was the ink, and a pressed
  plain button fills with `outline` under an ink label. Outlines are now
  the furthest step from the window toward the ink that keeps the ink at
  4.5:1 (`scan10_a_pressed_button_label_reads`).
- **Selection never vanishes.** With a highlight lost in the window the
  selection fell back to the window; it takes the outline step instead
  (`scan10_selection_never_vanishes`).
- **Disabled text looks disabled.** Muted text was the ink; it fades
  toward the window and still reads at 4.5:1
  (`scan10_disabled_text_looks_disabled`).
- **Hover shows.** On High Contrast Black the button face is the window,
  so `surface_variant` vanished; it is half the outline step
  (`scan10_hover_shows`).
- **The accent reads as small text.** It was kept at 3:1 but is drawn as
  chip and badge text; it now needs 4.5:1 or gives way to the ink
  (`scan10_accent_reads_as_small_text`).
- **A theme swap reaches the shaping kit.** `SW_WINDOW.wear_theme` now
  calls `set_theme_faces` when the type families change
  (`scan10_a_theme_swap_updates_the_kit_faces`); `SW_SHAPING.role_family`
  is public.
- **The switch is read once.** `wear_system_appearance` read the switch
  again in a postcondition, so a flip in between broke the promise
  (`scan10_the_switch_is_read_once`).
- `adopt_metrics_from` also takes the radius, the control heights, the
  type sizes and the line height (no setter can make two themes differ in
  these today, so no test can fail on 0.30.0).
- New postconditions on `make_high_contrast`: `accent_reads`,
  `pressed_label_reads`, `selection_reads`, `hover_reads`. A class note
  in `make_high_contrast` says why, for the next editor.
- Not done: SW_BADGE and SW_CHIP draw text on semantic fills without the
  `ink_on_*` tokens (a widget fix, not the theme's); the duplicated color
  blend in SW_HEATMAP. Report:
  `.eiffel-workflow/evidence/design-scan-since-053211b.md`. 473 pass;
  `screen_grab_marries_cairo` fails only in a locked session.

### Added (0.30.0 - GW-16: follow Windows high contrast)

Needs simple_shell 1.20.0.
- **`SW_THEME.make_high_contrast (window, window_text, highlight,
  highlight_text, button_face, hotlight)`** paints a theme with a Windows
  contrast theme's system colors: one ground, one ink for body, soft and
  muted text alike, outlines and dividers in that ink, the highlight for
  accent fills, the hotlight for accent-family text, no washes (they take
  the ground), and a grey ramp from the ground toward black or white. The
  semantic hues stay, made readable. `is_high_contrast` says so.
- **Mended, never refused.** A custom palette whose ink fails 4.5:1 gets
  black or white; text on the highlight likewise; a highlight that is not
  3:1 on the window gives way to the ink; the selection ground moves from
  the highlight toward the window until the ink reads on it. The theme is
  always `is_readable` (postcondition).
- **`SW_THEME.adopt_metrics_from`**: text scale, spacing, type families and
  locale, so a contrast theme worn in place of the application's keeps its
  sizes and faces.
- **`SW_WINDOW` follows it.** While following Windows
  (`follow_system_theme`), a contrast theme switched on (event 56) is worn
  with the light member's metrics, its palette changes are followed, a
  light/dark flip does not unseat it, and when it is switched off the pair
  returns. Following that starts while contrast is on starts in it.
  `is_wearing_high_contrast`. `system_appearance` and
  `set_system_appearance` let a test stand in for Windows' settings
  (testing class `SW_TEST_APPEARANCE`).
- Tests (`SW_HIGH_CONTRAST_ASSAULT`, 6): the four Windows contrast palettes
  (High Contrast Black and White, Desert, Aquatic) readable with the
  user's colors kept; unreadable palettes mended; the window following on,
  palette change, light/dark flip and off; following that starts in
  contrast; scripture in the black and white palettes (evidence
  `gw16_contrast_black.png`, `gw16_contrast_white.png`). 465 pass;
  `screen_grab_marries_cairo` fails only in a locked session.

### Fixed (0.29.1 - the ninth scan, since 760abf1)

- **A narrow bar shows the selected tab.** In a bar too narrow for any
  room beside the chevron, the selected tab got no width and `arrange`
  broke its own `selected_shown` postcondition. The first placed tab now
  keeps at least one pixel (`SW_TAB_STRIP.place_tabs_scrolling`, new
  postcondition `first_has_width`).
- **A theme with no control inset shows its tabs.** The width cap was
  twenty `control_inset`s, and `set_spacing` allows an inset of 0, which
  gave every tab no width. The cap is thirteen label-font boxes (about
  the same 220 pixels at 1x), and every natural width is at least one
  pixel.
- **A close handler may adopt the page.** `close_tab` promised the closed
  page had no parent after calling `on_close`, so a handler that moved the
  page into another notebook broke the promise. The page is let go before
  the call, and the promise is gone.
- **No stale box after moving across hidden tabs.** `move_tab` across a
  tab scrolled off the strip swapped boxes with a made-up gap, leaving a
  box outside the strip until the next arrange. Such a swap now forgets
  the placement; `swap_adjacent_boxes` requires both tabs shown.
- Tests (before/after; all four failed on 0.29.0):
  `scan9_a_narrow_bar_still_shows_the_selected_tab`,
  `scan9_a_zero_inset_theme_still_shows_tabs`,
  `scan9_a_close_handler_may_adopt_the_page`,
  `scan9_moving_across_hidden_tabs_leaves_no_stale_box`. 459 pass;
  `screen_grab_marries_cairo` fails only in a locked session.
- Not done (the scan's extraction candidates wait for Larry's word):
  tab measuring and drawing move into `SW_TAB_STRIP` for both SW_TABS
  and SW_DOCK_ZONE (they have drifted: strip height and fill insets
  differ); the remaining fixed pixel insets in tab drawing become theme
  tokens. Report: `.eiffel-workflow/evidence/design-scan-since-760abf1.md`.

### Added (0.29.0 - GW-15: closable, reorderable tabs with an overflow menu)

For many Bible tabs (`Ctrl+W` in the GUI specification).
- **Closable.** `SW_TABS.set_closable_by_default` and `set_tab_closable`
  (a pinned tab has no close box). A press and release on the close box
  calls `request_close`, which asks the `close_guard` (an unsaved note can
  refuse) and then `close_tab`. Releasing off the box closes nothing.
  Closing the selected tab selects its right neighbor, else its left.
  `on_close` gets the closed page; `on_change` fires only when a
  different page becomes selected (closing an earlier tab shifts
  `selected_index` silently).
- **Reorderable.** A tab dragged sideways past half the theme's `padding`
  changes places with each neighbor whose middle the pointer crosses,
  several in one pointer move (`move_tab`, `on_move`). The selection
  follows its page.
- **Overflow.** Tabs keep their natural widths (capped at twenty insets).
  When they outrun the bar the strip scrolls so the selected tab is whole,
  and a chevron at the right end opens `overflow_menu`, every tab in order
  (ampersands doubled so they show as written). Closing tabs at the end
  pulls the strip back.
- **Keys and wheel.** `select_next` and `select_previous` (wrapping) and
  `close_selected` are for the application's Ctrl+Tab, Ctrl+Shift+Tab and
  Ctrl+W accelerators. The wheel over the strip steps the selection.
- **Spacing from the theme.** The bar is the label font's box plus
  `control_inset` above and below (40 at 1x, as before), tab sides are
  `control_inset`, the gap between tabs half of `padding`. The fixed
  `Bar_h` constant is now the measured `bar_h`.
- **Shared tab geometry.** New deferred class `SW_TAB_STRIP`: tab boxes,
  `tab_index_at`, and two placement policies, SHRINK (every tab, equal
  shares when crowded) and SCROLL (natural widths from a first tab).
  `SW_DOCK_ZONE` now inherits it (SHRINK) instead of keeping its own copy;
  its behavior is unchanged (the GW-05 tests pass as they were).
- Tests (`SW_TABS_ASSAULT`, 11): closing and the neighbor selected, the
  guard and pinned tabs, the close box through the window, drag reorder
  through the window, `move_tab` both ways, overflow scrolling and the
  chevron menu picked through the popup, the strip pulling back, the
  accelerators, the wheel, and scripture tab labels (pointed Hebrew,
  polytonic Greek, mixed English and Hebrew) in both themes (evidence
  `gw15_tabs_light.png`, `gw15_tabs_dark.png`). 455 pass;
  `screen_grab_marries_cairo` fails only in a locked session.

### Changed (0.19.1 — STATUS BAR AND HOVER CARD SPACING FROM THE THEME)

Larry asked whether the controls carry Vision2's inner and outer borders
and padding. The toolkit does, as theme tokens that scale with the text,
but two pieces of this program had kept fixed pixels.
- `SW_STATUS_BAR`: the end pad is `theme.border_width` (was 12), the gap
  between sections twice `theme.padding` (was 16), the divider insets
  `theme.padding` (was 8), and the height the measured status font plus
  `padding` above and below (was a fixed 32, still at least 32 at 1x).
- `SW_WINDOW` hover card: the inset is `theme.border_width` (was 12), and
  the gap from the word is `theme.padding` (was 6, now 8 at 1x).
- Nothing else moves at 1x. At 2x text all of it doubles.
- Test: `status_bar_and_hover_card_spacing_scale`. 383 pass.

### Fixed (0.28.2 — the seventh scan, since 24c8a87; timing without contracts; flush-right Hebrew)

- **The layout memo follows the facade.** `SW_SHAPING.layout_styled`
  forgets its memo when `facade.policy_revision` moves (simple_shaping
  0.6.2). That happens when a font file is loaded, the default fonts or
  asset directory are set, or the facade's cache is cleared. Before, a
  layout made under the old fonts kept being served.
- **Labels and menus shape like the painter.** `SW_SHAPED_TEXT` kept its
  own 64-entry cache. It was wiped only when the kit object changed, and it
  shaped through `layout_for`, which does not apply script faces. So a
  Hebrew label could use another face than `SW_PAINTER.text` and keep a
  stale layout after a font change. It now shapes through
  `layout_styled_of` (role and weight) over the kit's memo and keeps only
  the cluster arithmetic. `SW_LABEL`, wrapping or not, passes its role and
  weight.
- **`SW_DATA_GRID.add_row` places one row.** It tests the filter on that
  row and puts the row at its sorted place by binary search, after equal
  keys so the sort stays stable. It used to filter and sort every row on
  every call. `add_rows` adds many rows with one rebuild.
- **Per-column alignment.** `SW_GRID_COLUMN.alignment`, set with
  `set_alignment` or `aligned`, takes the SHAPING_CONSTANTS `Align_*`
  codes. The default, `Align_start`, follows the text, so a Hebrew line
  sits flush right with nothing asked. `Align_right` suits numbers.
- **The grid's merge runs over SPECIAL arrays.** It sorts 100,000 rows in
  190 milliseconds with contracts off, down from 430.
- **Timing runs without contracts** (Larry: "Timing needs trump
  contracts"). The GW-29 test times each measured step inside simple_testing's
  new `without_contracts`. The 60 Hz budget is now asserted in every build:
  in the contracts build a wheel frame takes 3.7 milliseconds, a page jump
  13.6 and a sort 190. The test's set-up and its checks still run under
  contracts.
- **Before/after tests** (`SW_MEMO_ASSAULT`):
  - `scan7_memo_forgets_when_the_facade_changes` failed and now passes.
  - `scan7_label_shapes_like_the_painter` (with Hebrew and Greek script
    faces set) failed on the old label code and now passes.
  - `scan7_rows_added_one_at_a_time`: 2,000 rows added one by one took 10.3
    seconds and now take 22 milliseconds, in the order a full sort gives.
  - Added: `scan7_hebrew_column_sits_flush_right`.
  - The eighth scan (no HIGH findings) noted that timing inside
    `without_contracts` hid contract cost that grows; the GW-29 test now also
    asserts that, with every contract on, wheel frames do not grow slower.
    445 pass.
  - 444 pass. `screen_grab_marries_cairo` fails only in a locked session.
- Open from the scan: the grid's row and header heights are fixed pixels
  that do not follow the text scale; `SW_TEXT_GEOMETRY` and
  `SW_CHAT_THREAD` still shape through `layout_for` when no fonts are
  given; `selected_view_position` is a linear scan (tolerable at 100,000
  rows).

### Fixed (0.28.1 — the sixth scan, since 1d2249f: the proximity's distance)

- Editing a proximity's distance now changes the tree **and** fires
  `on_change`. The box called `set_distance` directly and never announced,
  so a host's question label went stale.
- A question that already says "within 120 words" renders. The distance
  box's top is now the larger of 99 (`Distance_box_max`) and the distance
  it shows. It was a fixed 99, so rebuilding the rows broke
  `SW_NUMBER_BOX.make`'s precondition. The tree has no top.
- `Word_field_width` names the proximity's 120-pixel word fields, which
  were two literals. A choice field's lookup is clamped to the field list,
  like every other field lookup.
- Before/after tests: `gw12_distance_edit_is_heard` and
  `gw12_long_distance_preset_renders` failed on the old code and pass now.
  440 pass. `screen_grab_marries_cairo` fails only in a locked session.
- Still open from the scan (MEDIUM and LOW, in
  `.eiffel-workflow/evidence/design-scan-since-1d2249f.md`):
  - the node heirs repeat the field lookup and the "complete, then
    negated" skeleton;
  - a whitespace value counts as complete;
  - a number field takes any text;
  - a choice field keeps a value outside its new choices;
  - SW_MAP still draws its own chip.

### Added (0.28.0 — 100,000 SHAPED ROWS AT 60 HZ; GW-29)

simple_bible's concordance lists every place a word occurs: 88,444 rows for
the Greek article. `SW_DATA_GRID` already drew only the rows in view. GW-29
measured it with 100,000 rows of shaped Hebrew and Greek cells and fixed
what the measurement found.
- **The defect was in simple_shaping** (0.6.1, merged there). Its layout
  cache's postconditions rebuilt the whole MML model on every call, so under
  assertions each shaped string cost more than the last. A frame took 316
  ms and then grew past 3 seconds. The fix is in that library, with its own
  before/after test.
- **`SW_SHAPING.layout_styled` remembers** (every widget's
  `SW_PAINTER.text` comes through it). It keeps two generations of 1,024
  layouts, so a string drawn again is one hash lookup and scrolling never
  empties the memo at once. The font setters clear it, and
  `forget_layouts` is there for changes made on `facade` directly.
- **The grid sorts by keys asked for once.** `SW_GRID_COLUMN.sort_key`
  gives each row's key once per sort, instead of two agent calls per
  comparison (3.4 million for 100,000 rows).
- **Measured** (`gw29_hundred_thousand_rows_light`/`_dark`; evidence
  `gw29_grid_light.png`/`_dark.png`):
  - Lean build (`ec.sh release`, the `_lean` binary, the shipping
    configuration): wheel frame 1.5 ms median, page jump 5.1 ms, sort 175 ms,
    against a 16.7 ms frame. The test asserts the 60 Hz budget here.
  - Contracts-on build (`ec.sh test`): wheel frame 39 ms, page jump 190 ms,
    sort 0.8 s. The test asserts that frames do not grow slower and that a
    frame drawn again never reaches the facade.
- The test runner takes `SW_ONLY=<part of a test name>` to run only those
  tests.
- Not built: a virtual row source (count plus fetch, with the host owning
  sort and filter). 100,000 rows in memory take 1.4 ms to adopt. Build it
  when a list too large to hold appears.
- Next: per-column alignment, so a Hebrew line column can sit flush right.

### Added (0.27.0 — QUERY BUILDER CLAUSE TREE; GW-12; and the fifth scan's fixes)

- **`SW_QUERY_BUILDER` builds a clause tree** (simple_bible's Search
  Builder and Census criteria). The deferred `SW_QUERY_NODE` has three heirs:
  `SW_QUERY_GROUP` (children joined ALL or ANY, nested to any depth),
  `SW_QUERY_CONDITION` (field, operator, value) and `SW_QUERY_PROXIMITY`
  (two words within n words of each other, `NEAR/n` in either order or
  `BEFORE/n` in order). Any node can be negated (NOT).
- The engine reads `root`. `expression` is the question as the reader
  reads it. `query_text` is an SQL-shaped rendering for display only and is
  never executed. Incomplete nodes are left out of both.
- **Typed value pickers.** `set_field_choices` gives a field a picker of
  codes (morphology, for one). `set_field_suggester` makes a field a lemma
  whose picker follows the typing. A text or number field keeps a box.
- **Controls carry their node.** Each group is framed with an ALL/ANY switch
  and a "not" check box and ends in "+ condition", "+ group" and "+ near".
  Every row has "not" and remove. An edit goes straight to the tree, and
  `on_change` hears every change.
- The first builder's flat calls (`add_clause`, `set_clause`,
  `set_join_all`, `query_text`) still work on the root group.
- `SW_TEXT_BOX.set_preferred_text_width`: a field can ask for less than
  the default 240 (the proximity's word fields ask for 120).
- Tests: `gw12_tree_reads_and_renders`,
  `gw12_incomplete_and_negated_groups`, `gw12_typed_pickers_and_removal`,
  and `gw12_builder_light`/`_dark` (evidence).

### Fixed (0.27.0 — the fifth scan, since 7504574)

- **One chart chip.** `SW_CHART.draw_chip` (with `draw_chip_beside`,
  `draw_chip_above` and `draw_chip_corner`) replaces the chip that bar,
  line, scatter, pie and heat map each drew themselves. It uses the theme's
  chip size and padding and is kept inside the frame. The bar chart's chip
  had no clamp before.
- **The chassis draws the legend** from `legend_names` (bar and line
  redefine it). `draw_legend_row` keeps clear of the title and ends in "+n"
  when the names do not fit. Five series at 300 wide ran over the title
  before.
- `series_color` gives eight distinct colors before cycling (it was four,
  so series 5 matched series 1).
- `SW_BAR_CHART`: `set_series` clears the emphasis (an invariant keeps it
  in range). Values must not be negative. The quiet series use the theme's
  pale `ramp (2)` instead of `ink_soft`, a near-black text ink that made the
  controls darker than the emphasized bar.
- `SW_INTERLINEAR`: a click ends a text selection, and Ctrl+C copies the
  text selection when there is one. Ctrl+A then Ctrl+C copied a single word
  before.
- Before/after tests: `gw10_new_series_forget_the_emphasis`,
  `gw10_series_colours_stay_apart` and `gw07_a_click_ends_a_text_selection`
  failed on the old code and pass now. Also added:
  `gw10_crowded_chart_keeps_inside` (evidence `gw10_crowded_light.png`).
  436 pass. `screen_grab_marries_cairo` fails only when the desktop cannot be read.

### Added (0.26.0 — GROUPED BARS; GW-10; and the fourth scan's fixes)

- **Grouped multi-series bars in `SW_BAR_CHART`** (simple_bible's census
  controls chart, I-P02: a target word against frequency-matched controls).
  `set_series` names the series and `add_group (label, values)` adds a
  category with one value a series; `add_bar` still makes a single-series
  chart. A group's bars stand side by side a quarter of the theme's padding
  apart; with several series a legend names them; `series_at` says which bar
  is under a point and the hover chip names its series and value.
  `set_emphasized_series` draws the other series in the theme's soft ink so
  the target stands out by lightness as well as hue, and the legend follows
  (`series_color` is redefined). Labels use the theme's chip size.
- **Fourth post-merge scan** (`design-scan-since-f8df023.md`) found five live
  defects, fixed, three with tests that fail on the old code:
  - the interlinear's lines below the surface word could not be pointed at
    (no hover card from a gloss): every line now has its own box;
  - after `wipe_out` the interlinear could keep the old words, because its
    revision was a sum that can come back to an old value: it now uses a
    structure counter that only grows, and checks line edits apart;
  - a hovered link survived the rows it was in: `SW_DOC_UNITS.forget_hover`
    forgets it;
  - the interlinear did not paint its text selection (Ctrl+A selected
    invisibly), and `wipe_out` and each re-flow kept a stale selection and
    hover.
- `margin`, `scroll_extent` and `layout_key` live once in `SW_DOC_UNITS`; the
  interlinear's scroll-to-word uses `scroll_item_into_view`; a double click
  selects a word once.
- Tests: grouped bars hit and domain, emphasis, the controls chart in both
  themes (evidence gw10_controls_light.png and gw10_controls_dark.png), and
  the three defect tests. 428 pass.

### Added (0.25.0 — INTERLINEAR; GW-07; and the third scan's fixes)

- **`SW_INTERLINEAR`** (simple_bible's Interlinear tab, C04): stacked word
  cells - the surface word, transliteration (italic), pronunciation, gloss,
  lemma, Strong's number, morphology in English - flowing and wrapping, right
  to left for Hebrew and left to right for Greek. Any line can be hidden
  (`set_line_visible`; the surface word always shows). A word that opens a
  verse carries its label on the reading-start side. A click or Left/Right
  (in reading order, mirrored right to left), Home and End select a word
  (`on_token_select`); `token_at`; Ctrl+C copies a word's lines; a rest on a
  word opens the card `set_hover_card_builder` builds. It inherits
  `SW_DOC_UNITS` alone: every visible line is a unit and every flowed row a
  stacked item, so the shaping, scrolling, pointing and hover cards come
  with it, and only the flow, the word selection and the keys are new.
- **Third post-merge scan** (`design-scan-since-9cb4b01.md`) found two live
  defects in the parallel text, both fixed with tests that fail on the old
  code: a point on the title band named a row hidden under it, and
  `scroll_to_row` put the row under the band.
  `SW_STACKED_ITEMS.pinned_height` (a band that does not scroll) fixes both.
- **`SW_DOC_UNITS` owns its heirs' input** (wheel, click, double-click, drag,
  release, keys, characters, cursor, hover) and layout bookkeeping
  (`is_laid_out`, `stack_reset`, `measure_units`, `wheel_line`): the document
  view redefines 7 of them, the parallel text 4, the interlinear 7.
  `SW_STACKED_ITEMS.scroll_item_into_view`, `SW_TEXT_POINTING.forget_hover`
  (hover cleared when content changes).
- `SW_MARK_PAINTER.paint_marked` is gone: it redrew a mark's text effects in
  the text's own ink; the parallel text redraws them in the painter's colour.
- Tests: the band is not content, scroll-to-row below the band, cells flowing
  and wrapping, lines hidden and shown, words selected by click and keys, and
  Genesis 1:1 in both themes (evidence gw07_interlinear_light.png and
  gw07_interlinear_dark.png). 421 pass.

### Added (0.24.0 — PARALLEL TEXT; GW-06; and the ancestors it stands on)

simple_bible's Parallel tab (A02), word diff (A04) and They Chose (I-P06) show
versions side by side, verse by verse. Larry's rule: extract what a new widget
would copy before building it, and use multiple inheritance to do it.

- **`SW_PARALLEL_TEXT`.** Rows are canonical verses, columns are versions (up
  to six, each with a weight, a text scale and an alignment), and each cell is
  a simple_document `DOC_TEXT`: wrapped, shaped, in its own direction (Hebrew
  flush right). A row is as tall as its tallest cell; one scroll; the title
  band stays while the rows scroll; note rows ("LXX 9 = MT 9-10") span every
  column in muted text. Each cell has its own `SW_MARKED_TEXT`, painted
  through an `SW_MARK_LEGEND` ("agrees with LXX"). `cell_at`, `on_cell_click`,
  `scroll_to_row`; selection copies a row's cells with tabs and rows line by
  line. Spacing from the theme: the page inset is `border_width`, columns are
  `padding` apart, cells half the `padding` down, the title band the measured
  label font plus `padding`. Its whole inherit clause is one parent.
- **`SW_DOC_UNITS`**, lifted from the document view: the units of stacked
  items (texts and cells, numbered in reading order), the pointing and
  selection item hooks, `pointed_unit` (an item's one text, or the cell whose
  box holds the point), `lay_unit`, the run hook for links, code and
  strikethrough, selection washes, link hover, and the read-only pointer
  (`unit_press`, `unit_drag`, `unit_release`, `unit_double_click`). The
  document view went from about 1,370 lines to 876.
- **Composed bases, for shorter inherit clauses.** The compiler confirmed that
  every parent bringing a feature the heir redefines needs it listed, so the
  joining is done once: `SW_STACKED_POINTING` joins pointing, scrolling and the
  stack, and owns `accepts_focus`, `wants_hover_point` and `preferred_height`;
  `SW_DOC_UNITS` inherits it and `SW_TEXT_SELECTION`. The paragraph list's
  inherit clause went from 45 lines to 24, the document view's to 17.
- **`SW_MARK_HOST`**, a mixin with no parent (so no adaptation anywhere):
  `legend`, `set_legend`, `mark_painter` for the text box, the paragraph list
  and the parallel text. `SW_MARK_PAINTER.paint_marked` paints a marked text
  whole. `SW_DOC_UNIT` has an alignment; `SW_TEXT_GEOMETRY.natural_width`.
- The second post-merge scan (report `design-scan-since-a808837.md`): no new
  high findings; the paragraph list's note now says an unchanged edit is not a
  commit.
- Tests: rows following their tallest cell, cells hit, clicked and copied,
  a Hebrew column flush right and a note row, the title band staying while
  rows scroll, spacing at 1x and 2x, and They Chose in both themes (evidence
  gw06_parallel_light.png and gw06_parallel_dark.png). 414 pass.

### Changed (0.23.0 — THE FIRST POST-MERGE SCAN'S HIGH FINDINGS)

The post-merge abstraction scan (simple_bible gap program rule 9;
`/eiffel.design-scan --since`, report in
`.eiffel-workflow/evidence/design-scan-since-8125771.md`) compared the GW-13 code
with the whole library and found six high items. Larry: fix them all before
GW-06. Each is its own commit.

- **A fifth deferred ancestor, `SW_STACKED_ITEMS`**: the block stack, the
  viewport height, the measuring pass (`measure_stack` over `item_revision`,
  `is_volatile`, `measure_item`, `stack_reset`), the visible range,
  `stacked_top`, `stacked_item_at`, `stacked_scroll_for` (the page inset stated
  once as `stack_origin_y`, where the view subtracted it by hand at four
  sites) and the draw frame. The paragraph list and the document view inherit
  it; GW-06 will too.
- **Editor hosting**: `SW_IN_PLACE_EDITING.editor_sub_widgets` and
  `widget_or_editor_at`, so a host's `sub_widgets` and `widget_at` are one line.
- **Pointing in one place**: `character_at`, `offset_at_point` and `text_boxes`
  are effective in `SW_TEXT_POINTING` over deferred `item_geometry`,
  `item_origin_x/y` and `is_item_pointable`, with one guard: a geometry that
  no longer matches its text is never indexed. The paragraph list read stale
  geometry while a paragraph was being edited (a test fails on the old code,
  passes now), and its `pointed_item` named a paragraph under the scrollbar.
- **One layout step**: `SW_TEXT_GEOMETRY.lay_out` holds the shaped-or-toy
  switch, the role's fonts and the one-line floor for the text box, the
  paragraph list, the legend and the document view. (The scan suspected an
  empty shaped paragraph measured short; a test shows it did not, and stays as
  a guard.)
- **The paragraph list's spacing scales**: `gutter_width`, `item_gap` and
  `item_pad` are 1x values drawn at the text's scale, and the gap beside the
  scrollbar is half the theme's padding. At 1x nothing moves; at 2x the gap no
  longer stays 4 pixels beside a 24-pixel bar (a test fails on the old code).
- **One end of an edit**: `SW_IN_PLACE_EDITING.end_edit` is the template;
  hosts give `keep_item` and `restore_item`. An unchanged edit is not a commit,
  and the box is down before either runs (the two hosts disagreed on both).
- Tests: stale geometry never indexed, an empty paragraph a line tall,
  paragraph spacing scaling at 2x. 407 pass.

### Added (0.22.0 — LIVE-PREVIEW EDITING; GW-13 complete)

Larry chose live preview for editing notes: the block being edited shows its
Markdown, and every other block stays formatted. He also chose one neutral
document model, so the model moved out of this library.

- **The model is now simple_document** (`SIMPLE_DOCUMENT`, `DOC_BLOCK`,
  `DOC_TEXT`; 0.21.0's SW_DOCUMENT, SW_DOC_BLOCK and SW_RICH_TEXT are gone,
  with no outside users). It adds code blocks, inline code and strikethrough:
  code blocks draw in the mono face on a wash, inline code on a wash, and a
  struck run with its line through. `SW_DOC_STYLES` flattens a DOC_TEXT for
  the shaper, for any widget that draws one.
- **Live preview.** `SW_DOCUMENT_VIEW.set_codec (codec)` makes the view edit.
  A click on a block opens a box over it holding the block's source, and a
  click on another block (or below the last) keeps the edit: the source is
  read back into one block, several, or none. Escape drops the edit,
  Ctrl+Enter keeps it and opens a new paragraph after it, and Ctrl+click
  follows a link. `begin_edit`, `end_edit`, `new_paragraph_after`,
  `on_edit_commit`, `on_document_change`. The document changes only when an
  edit is kept.
- **Codecs.** `SW_DOCUMENT_CODEC` (deferred: a block to source, source to
  blocks) keeps the view markup-neutral; `SW_MARKDOWN_CODEC` is the shipped
  one, on simple_markdown 1.1.0's reader and writer (now a dependency).
- **`SW_IN_PLACE_EDITING`**, a fourth deferred ancestor, lifted from the
  paragraph list: the box over an item, key and character forwarding with
  Escape cancelling, live change and commit callbacks, seating. The paragraph
  list and the document view both inherit it.
- **`SW_KEYS.simulate`**: the test runner holds no modifier down, so a key
  held on the real keyboard no longer turns a test's click into a Ctrl+click
  or Shift+click (two tests had failed at random); a test that needs a
  modifier simulates it.
- **The spell checker no longer marks Hebrew or Greek**: `SW_SPELLER` keeps a
  finding only when its word is written in Latin script.
- Tests: a block's Markdown in the box, typing kept and read back with its
  spans, Escape dropping an edit; one edit becoming two blocks, an emptied
  edit removing its block, Ctrl+Enter, a click below the last block; Ctrl+click
  following a link while a plain click edits; Hebrew and Greek never
  misspelled; a simulated Ctrl+click; and the editing gate in both themes
  (evidence gw13_editing_light.png and gw13_editing_dark.png). 404 pass, four
  runs in a row before the spell fix.

### Added (0.21.0 — THE RICH DOCUMENT VIEW; GW-13, reading)

simple_bible shows commentaries, lexicon entries, dictionary articles and
author-library documents as formatted text, with Scripture references that
can be hovered and followed.

- **The model.** `SW_DOCUMENT` is an ordered list of `SW_DOC_BLOCK`s:
  paragraphs, headings (levels 1 to 3), bulleted and numbered items and
  block quotes (depths 1 to 3), rules and tables (a header row, then rows of
  cells). Every text is an `SW_RICH_TEXT` with inline bold, italic, small
  capitals, superscript and links with a target. Overlapping spans are
  flattened for the shaper (`SW_RICH_TEXT.styles`). Numbered items count
  within their run (`number_of`); `plain_text` is what Copy gives. The
  model knows no markup: a host builds it from Markdown or HTML.
- **The view.** `SW_DOCUMENT_VIEW` inherits SW_TEXT_POINTING, SW_VSCROLLING
  and SW_TEXT_SELECTION and stacks its blocks on SW_BLOCK_STACK. It sets
  bold, italic, superscript and small capitals through simple_shaping 0.6.0,
  draws links in the theme's `ink_accent` over an underline (heavier under
  the pointer), and gives the hand pointer over a link and the I-beam over
  text. A press and release on one link calls `on_link_click (target)`;
  `on_link_hover` hears the link under the pointer change. A selection runs
  across blocks and table cells (cells of a row copy tab-separated);
  Ctrl+C, Ctrl+A, Escape, double-click selects a word. Hover cards come from
  `set_hover_card_builder` as in the paragraph list. Units (a block's text
  or one table cell) are numbered in reading order: `unit_block`,
  `unit_row`, `unit_column`, `link_target_at`, `unit_geometry`.
- **Tables** size each column to its widest cell on one line and shrink
  them in proportion when the page is narrower; the header row is washed.
- **Hebrew and Greek.** Every text is laid out with Align_start: a Hebrew
  paragraph sits flush right, and a Hebrew list item or quote carries its
  bullet or bar on the right.
- **Spacing from the theme:** page inset `border_width`, blocks `padding`
  apart, a level-1 heading `border_width` above, list indent twice
  `border_width` a level, quote indent `border_width` a level, cells padded
  by `control_inset` across and half the `padding` down.
- Tests: span flattening; numbering and plain text; pointing, link hover,
  hand pointer, link click, selection across blocks and a table row,
  Escape and Ctrl+A; the bold word realized at weight 700 and a drag from a
  link selecting without following it; spacing at 1x and 2x; a 300-paragraph
  document; and the Hebrew and Greek gate in both themes (evidence
  gw13_document_light.png and gw13_document_dark.png). 398 pass.

Editing (notes) is the second half of GW-13.

### Changed (0.20.0 — SHARED VIEW PARTS: SCROLLING, POINTING, SELECTION, STACKING)

Larry asked that common code be pushed up the abstraction structure, using
Eiffel's multiple inheritance where it fits. A read-only review found the
vertical scrollbar copied into six widgets (the copies had drifted: the tree
and grid thumbs overran their tracks and could not be dragged, the paragraph
list's drag never ended), the hover and dwell plumbing about to be copied a
second time, and three copies of the text drawing loop.

- **`SW_VSCROLLBAR`**, one scrollbar for every scrolling widget: the track,
  a thumb drag that keeps its grab point, a track press that pages, three
  lines a wheel notch, sizes from the new theme tokens
  `SW_THEME.scrollbar_width` and `min_thumb` (both scale with text).
  SW_LIST, SW_PARAGRAPH_LIST, SW_SCROLL_AREA, SW_CHAT_THREAD, SW_TREE and
  SW_DATA_GRID use it. Every bar's drag now ends on release; the tree's and
  grid's bars now click, page and drag; the tree's thumb stays inside its
  track; a list notch is three rows (was two); a chat notch is three lines.
- **Deferred ancestors a widget inherits side by side.** None redefines
  another's SW_WIDGET features, so their shared features join:
  - `SW_TEXT_POINTING`: the character under the pointer, `on_hover`,
    `on_dwell`, hover cards anchored at the word. A widget names its texts
    through `pointed_item`, `character_at`, `text_of`, `text_boxes`.
  - `SW_VSCROLLING`: `scroll_y`, `scroll_to` with `on_scroll`, the bar,
    wheel and paging keys. A widget gives `scroll_extent` and `wheel_line`.
  - `SW_TEXT_SELECTION`: a selection across items, `selected_text`, Copy,
    Select All, Ctrl+C / Ctrl+A / Escape.

  SW_PARAGRAPH_LIST now inherits the first two.
- **`SW_BLOCK_STACK`** stacks items of different heights (measured height,
  revision, top) with binary-search lookups (`item_at`, `first_visible`,
  `last_visible`, `scroll_into_view`). SW_PARAGRAPH_LIST stacks on it.
- **`SW_WORD_BOUNDARY`** is the one definition of a word (letters with
  marks, digit runs, Hebrew and Greek punctuation separating).
- **`SW_TEXT_GEOMETRY.draw`** replaces the drawing loops of SW_TEXT_BOX,
  SW_PARAGRAPH_LIST and SW_MARK_LEGEND_VIEW (the legend's skipped line
  breaks and alignment) and draws a plain-path text in the font it was
  measured in. `draw_hooked` paints shaped text with a hook before each run
  (absolute character indexes); `set_fonts` lays text out under a role's
  policy (`SW_SHAPING.fonts_for_role`).
- `SW_PAINTER.stroke_rect`, `font_size`, `draw_shaped_layout_hooked`. The
  dead `SW_PARAGRAPH_LIST.pieces_of` is gone.
- Tests: a bar drag that ends on release (paragraph list: it failed on the
  old code), the same for list, scroll area and grid, the tree's thumb in
  its track, a chat wheel notch, and the block stack's lookups. 389 pass;
  `screen_grab_marries_cairo` failed in these runs only because the desktop
  was unreadable (an untouched path that passed in the run before).

### Added (0.19.0 — THE DOCK: TABS, DRAGGABLE EDGES, HIDE AND REMOVE, SNAPSHOT; GW-05)

simple_bible's Study layout docks five panels in the south zone, and its
presets and session restore must read and set the dock. `SW_DOCK_HOST`
stacked a zone's panels in equal shares (five became unusable slivers),
fixed every zone's share at creation, could not hide or remove a panel,
and had no snapshot.

- **Tabbed zones.** `set_tabbed (zone, True)` gives a zone one tab strip,
  with the active panel filling the rest. A click on a tab shows that
  panel, a middle-click lifts it for pick-and-drop as a title bar does,
  and only the active panel is arranged, drawn and hit-tested.
  `activate_panel`, `active_panel`. Moving or showing a panel shows it
  in its zone.
- **Draggable edges.** Each open zone's inner edge shows the resize
  cursor and an accent line under the pointer, follows a drag inside
  `Min_fraction` .. `Max_fraction`, and announces once on release.
  `set_fraction (zone, f)` and `fraction (zone)`. The centre always keeps
  `Min_center` pixels; the zones are squeezed in proportion.
- **Hide, show, remove.** `hide_panel` keeps a panel and its place, and
  its zone collapses when it was the last visible panel there.
  `show_panel` brings it back. `remove_panel` lets it go, and the ids after
  it shift down. Durable identity is the panel's key: `add_keyed_panel
  (key, title, content, zone)` and `panel_by_key`. `add_panel` keys by
  title. `panels_in` now lists the visible panels and `all_panels_in`
  lists every one.
- **Snapshot and restore.** `layout_snapshot` writes the fractions, the tab
  modes, every panel's key, zone, visibility and order, and each tabbed
  zone's active panel, one fact a line. `restore_layout` applies it all
  or nothing, with one `on_layout_change`; `last_restore_ok` reports
  whether it read. Panels the snapshot does not name keep their state and
  follow; keys the host lacks are passed over.
- **Spacing from the theme** (Vision2's model, as every box here uses it).
  A zone is a framed surface like `SW_GROUP`:
  - panel content is inset by `theme.border_width`;
  - tabs are padded by `theme.control_inset`;
  - the bar is the measured title font plus `theme.padding`.

  All of it doubles at 2x text. Panel content is clipped to its zone.
- The `zones_hold` invariant walked every panel on every call. It is
  replaced by O(1) clauses.
- Tests:
  - stacked versus tabbed with five panels;
  - a tab click through the window, hit tests in the shown panel, and a
    tab as a pebble source;
  - edge drag with cursor, clamp and one announcement, the south edge,
    and the centre minimum;
  - hide, show and remove with keys;
  - a snapshot round trip line for line, unnamed panels, unknown keys,
    and bad text changing nothing;
  - spacing that follows the theme at 1x and 2x;
  - the Study layout in both themes with a Hebrew tab title (evidence
    gw05_study_layout_light.png and gw05_study_layout_dark.png).

  382 pass.

### Added (0.18.0 — THE HOVER CARD; GW-09)

simple_bible's reader rests on a word and its lexicon card opens beside
it: the pointed word, transliteration, gloss, Strong's number,
morphology, uses, provenance, and Word Study / Search / Journey / Pin.
The old tooltip was one line of plain text per whole widget.
`show_popover` holds a widget tree, but it is modal: while it is up the
page beneath takes no input, so the reader could not move on to the next
word.

- **`SW_HOVER_CARD`**: a widget tree, its width, and the anchor (the
  window rectangle of the word or reference it was opened for).
- **`SW_WINDOW.show_hover_card` / `close_hover_card` / `has_hover_card`.**
  The card is non-modal: the page keeps all its input off the card, and
  the card takes the pointer only over itself, so its buttons work.
  - Placement: drawn on top, with a soft shadow, below the anchor, or
    above it when there is no room, and always inside the window.
  - It stays open while the pointer is on the card, on the anchor, or
    crossing between them. Off all three it closes after
    `hover_card_grace_ms` (300 by default).
  - A click off the card closes it and still reaches the page. Escape, the
    pointer leaving the window, a wheel turn off the card, and a dialog,
    popup or sheet opening also close it.
  - A second rest on the same anchor keeps the card already up rather
    than rebuilding it.
- **A widget names the sub-region:** `SW_WIDGET.hover_card_at (x, y)`.
  After a dwell the window asks the hovered widget for a card.
- **`SW_PARAGRAPH_LIST.set_hover_card_builder`** (paragraph, character
  → card). A card left without an anchor is anchored at the word under
  the pointer. `word_at (item, character)`: a run of letters with their
  marks, or a run of digits (a raised Strong's number is its own word);
  Hebrew and Greek punctuation end a word.
- Tests: through the window's own event path, a dwell opens the card
  anchored at the whole word and below it; the card stays on the word
  and on itself, its button takes a click, a second rest keeps it,
  another word replaces it, and it closes after the grace but not
  before; click-off (the click still selects), Escape, leaving the window
  and a dialog each close it. Hebrew word card for Genesis 1:1 in both
  themes, shaped (evidence gw09_word_card_light.png and
  gw09_word_card_dark.png). 375 pass.

### Added (0.17.0 — POINTING AT A WORD, RAISED STRONG'S, SMALL-CAPS LORD; GW-08)

simple_bible's reader hovers a word for its lexicon card, raises Strong's
numbers after tagged words, and sets LORD in small capitals.
`SW_PARAGRAPH_LIST` could say which paragraph was under the pointer, but
not which character, and it set every character the same way.

- **Hit test.** `character_at (x, y)` gives the character of paragraph
  `item_at (y)` painted under a point, and 0 on a gutter, a band, a
  line's empty end, the gap between paragraphs, or the paragraph under
  the editor. Also `caret_offset_at`, and `text_boxes (item, lo, hi)`:
  the window rectangles of a stretch, to anchor a hover card or ring a
  word. Underneath is `SW_TEXT_GEOMETRY.character_at`.
- **Events:**
  - `on_hover (item, character)` fires when the character under the
    pointer changes, and gives (0, 0) when the pointer leaves the text.
    A wheel turn re-reads the character under a resting pointer.
  - `on_dwell (item, character)` fires when the pointer rests for
    `dwell_delay` (400 milliseconds by default).
  - `on_scroll (y)` fires on every real scroll.
- **Dwell, window-wide.** `SW_WIDGET.dwell_ms` and `handle_dwell`.
  `SW_WINDOW` re-arms simple_shell 1.19.0's one-shot dwell timer on every
  pointer move and wheel turn over a widget that wants it, cancels it when
  the pointer leaves, and hands event 55 to the hovered widget. A dialog
  or popup swallows the event, and it never reaches the app's shell-event
  handler.
- **Styled runs** (simple_shaping 0.5.0). `SW_PARAGRAPH_LIST.set_styles
  (item, SHAPING_STYLES)` and `styles_of`; `SW_TEXT_GEOMETRY.set_styles`;
  `SW_SHAPING.layout_with_styles`. Superscripts and small capitals show on
  the shaped path; the toy path and the in-place editor show them plain.
- Tests: the hit test; hover, dwell and scroll events; the dwell through
  the window's own event path, including under a dialog; KJV Genesis 1:1
  and 2:7 with 15 raised numbers and small-caps LORD above the same text
  plain and the Hebrew verse, in both themes (evidence
  gw08_strongs_light.png and gw08_strongs_dark.png). 371 pass on a clean
  build.

### Added (0.16.0 — STATUS-BAR SECTIONS; GW-11)

simple_bible's status bar shows the reference and version, the active link
set, the versification note, job progress with Cancel, and the database
edition. `SW_STATUS_BAR` had only a left and a right message.

- **Sections**, between the existing left and right messages (both kept):
  - `add_text (text, trailing)` and `add_widget (widget, width, trailing)`
    answer the section's index;
  - `set_section_text`, `set_section_visible`, `set_on_section_click`,
    `section (i)` and `section_at (x)`.
  - Leading sections pack after the left message, trailing ones before
    the right message, each side in the order added, with a divider
    between neighbours.
- **Clickable text sections** draw in the accent ink, show the hand
  cursor, and run their agent through the window's ordinary click path.
- **Hosted widgets** (an `SW_PROGRESS`, a Cancel `SW_BUTTON`) are real
  children: they are arranged into their section, vertically centered,
  and they draw, hit-test, take clicks and the focus.
- A hidden section takes no room, draws nothing, answers no click and
  drops out of `sub_widgets`.
- New class `SW_STATUS_SECTION`.
- Tests:
  - layout order, no overlap, the last trailing section on the right pad,
    the progress bar inside its section;
  - the link-set section's agent fires and a plain section does nothing,
    both through `dispatch`; the hosted Cancel fires;
  - hiding the progress section closes up the trailing side;
  - Hebrew/Greek gate in light and dark: pointed Genesis 1:1, polytonic
    John 1:1 and a mixed English/Hebrew line, no tofu, each section at
    least 40 pixels at 3:1. Evidence `gw11_status_light.png` and
    `gw11_status_dark.png`.
- 366 pass, 0 fail, 0 warnings.

### Added (0.15.0 — A WORKER'S WAKE REACHES THE APP; GW-26)

This release needs simple_shell 1.18.0.

- **`SW_WINDOW.set_on_wake`:** when a worker processor calls
  `SHELL_WAKE.wake`, `on_wake` runs (the app polls its job there) and the
  window repaints. Wakes that arrive together come as one. Event 54 is
  handled before modality, so an open dialog or popup cannot hold a result
  back.
- **The heartbeat is settable:** `set_heartbeat_ms`, inherited from
  `SHELL_WINDOW`; the default is still 250 milliseconds.
- Test: event 54 calls the app with and without an open dialog and is
  harmless with no handler; the heartbeat passes through. 363 pass, 0
  fail, 0 warnings (clean build).

### Added (0.14.0 — FUNCTION KEYS AND CTRL+DIGIT ACCELERATORS; GW-24)

This release needs simple_shell 1.17.0, which delivers F1-F12, Ctrl+digit
and Ctrl+punctuation as event 4.

- **`register_accelerator` accepts F1-F12 with no modifier.** Function keys
  type nothing, so F1 (help), F3 (find next) and F6 (next pane) can stand
  alone. Letters and digits still require Ctrl or Alt. New query:
  `is_function_key`.
- **Fixed: a key-down accelerator ate the reader's next keystroke.** It
  armed a flag that swallowed the next WM_CHAR, whatever it was. Ctrl+1,
  Ctrl+Plus and Alt+S make no WM_CHAR, so the next real character typed
  was lost. Now the flag eats only a control code (Ctrl+[ makes 27, which
  would read as Escape), and any character or new key-down disarms it.
  Shown before and after: with the old logic,
  `gw24_no_trailing_char_never_eats_the_next_keystroke` fails with "the
  next keystroke still types".
- New query `has_sheet`: is a sheet, drawer or popover presented?
- Tests:
  - bare F1 fires while a text box holds the focus, and the box is untouched;
  - after Ctrl+1 and after Alt+S, the next characters still type;
  - Ctrl+['s trailing 27 does not close an open sheet, while a bare 27
    does.
- 362 pass, 0 fail, 0 warnings (clean build).

### Added (0.13.0 — THE WINDOW FOLLOWS THE WINDOWS LIGHT/DARK SETTING; GW-27)

simple_bible's theming decision: default Light, a Dark theme, and the user
can switch. This release adds the third choice, "follow Windows". It needs
simple_shell 1.16.0.

- **`SW_WINDOW.follow_system_theme (light, dark)`** wears the member of the
  pair that Windows asks for. Event 53 (`Event_appearance_changed`) swaps
  the theme live and repaints. The swap is handled before modality, so an
  open dialog or popup cannot block it. **`set_on_theme_changed`** tells
  the app the new theme. A later **`set_theme`** is the user's own choice:
  it stops following.
- **The caption always matches the theme:** creation, `set_theme` and every
  followed flip call `set_dark_title_bar (theme.is_dark)`.
- Tests:
  - following matches `SHELL_APPEARANCE.system_prefers_dark`, caption
    included;
  - 53 with 1, then 0, swaps the theme both ways, and frame pixel (2,2)
    repaints in each background;
  - the app is told twice, with the right themes;
  - a dialog does not block the flip;
  - after `set_theme`, a flip is ignored.
- 359 pass, 0 fail, 0 warnings (clean build).

### Added (0.12.0 — POINTED HEBREW AND POLYTONIC GREEK, VERIFIED IN THE SHIPPED FACES; GW-03)

Asked for by simple_bible (gap GW-03): Hebrew with vowel points and
cantillation, MapM's no-break space before paseq, and polytonic Greek must
render correctly in both themes from 14 to 40 px.

- **`SW_SHAPING.set_script_face (script_class, family)`:** an app's own
  reading face for a script goes first in every role (Noto Serif Hebrew for
  Hebrew, Noto Serif for Greek).
- **`SW_SHAPING.set_small_script_face (script_class, family, below_px)`.**
  Measured: at 14 px, regular Noto Serif Hebrew's points antialias to grey
  (light theme: 16 of 67 mark pixels at 3:1). The true Medium design gives
  31%. A static Medium file is its own GDI family, so asking weight 500 of the
  regular family returns Regular unchanged (600 synthesizes bold). The face
  must be named.
- **The GW-03 gate, in Noto Serif Hebrew and Noto Serif loaded privately
  (OFL fixtures in `testing/fixtures/fonts/`):**
  - At 14, 18, 24, 32 and 40 px: no tofu, every Hebrew letter in the Hebrew
    face (Medium below 18 px) and every Greek letter in Noto Serif. The marks
    attach: pointed Genesis 1:1 is within 4% of its bare consonants' width,
    and decomposed John 1:1 within 4% of its precomposed form.
  - Light and dark at 14 px: the points ink below the line (67 pixels against
    2 for the bare consonants), and at least a quarter of that ink reads at 3:1
    against the surface.
  - Nehemiah 11:33 (MapM) wrapped at every width from 60 to 400 px: the
    no-break space, the word before it and the paseq after it always share a
    line, with no tofu.
  - Evidence: `evidence/gw03_specimen_light.png` and `gw03_specimen_dark.png`.
- 356 pass, 0 fail, 0 warnings.

### Added (0.11.0 — HEBREW FLUSH RIGHT, THE GUTTER ON THE READING SIDE; GW-02)

Asked for by simple_bible (gap GW-02): a Hebrew verse must read right to
left AND sit flush right, with its verse number on the right.

- **`SW_TEXT_GEOMETRY.set_alignment (alignment, box_width)`:** `build_shaped`
  places each line by `SHAPED_LAYOUT.line_offset` (simple_shaping 0.4.0),
  and every slot moves with its line, so carets, selections, squiggles and
  hit-tests keep agreeing with what paints. A line break's slot stands at the
  reading start of the line it opens. New: `offset_of_line`, `is_aligned`,
  `starts_right_to_left`.
- **`SW_PAINTER.draw_shaped_layout_aligned (layout, x, y, box_width,
  alignment)`.**
- **`SW_TEXT_BOX.set_text_alignment`, `SW_PARAGRAPH_LIST.set_text_alignment`
  and `SW_LABEL.set_text_alignment`.** With `Align_start`, each Hebrew
  paragraph sits flush right and each English one flush left. The list's
  inline editor aligns the same way, so text does not jump when editing
  begins.
- **`SW_PARAGRAPH_LIST.set_gutter_on_reading_side`:** a right-to-left
  paragraph carries its gutter on the right and its text moves left
  (`item_gutter_x`, `item_text_x`). Bands and marks follow.
- The default for all three is `Align_left` with the gutter on the left:
  exactly the behavior before GW-02.
- Tests, in both themes: geometry (flush right, reading-start caret at the
  right edge, a click there is offset 0); a Hebrew text box inks its right
  half; a three-verse list (Hebrew, Greek, English) puts the Hebrew gutter
  on the right. Evidence: `evidence/gw02_verses_light.png` and
  `gw02_verses_dark.png`. 352 pass, 0 fail, 0 warnings.

### Changed (0.10.0 — EVERY WIDGET'S TEXT GOES THROUGH THE SHAPED PATH; GW-04)

Asked for by simple_bible (gap GW-04): Hebrew and Greek appear in data
grids, trees, tabs, chips, selects, dialogs, the status bar, dock title bars,
charts and tooltips, and until now only labels, text boxes, paragraph lists,
menus and the chat thread were shaped.

- **`SW_PAINTER.text` and `advance` shape whenever the painter carries a
  kit.** They use the role and weight of the last `font` call, with the
  baseline where the toy path put it, so every widget gets bidi, pointing,
  cantillation, polytonic marks and font fallback with no widget of its own
  changed. Without a kit, cairo's toy path is exactly as before. New:
  `font_role`, `font_bold`, `font_pixel_size`, `takes_shaped_path`.
- **`SW_SHAPING.layout_styled (text, width, size, role, bold)` and
  `styled_fonts (role, bold)`:** one policy per role (ui, body, mono) and
  weight, with the theme's face for that role LEADING the general list
  (simple_shaping 0.3.1 `with_leading_family`), so it carries Latin, digits
  and punctuation. Hebrew and Greek fall through to simple_shaping's scholar
  lists, which an app can now ship privately (simple_shaping 0.2.0
  `load_font_file`). Bold labels are bold (simple_shaping 0.3.0).
- **Requires simple_shaping 0.3.1.** Clients rebuild with `-clean`.
- **The Hebrew and Greek gate**, in both themes: pointed Genesis 1:1 (WLC,
  cantillation) and polytonic John 1:1 (WH, combining marks) drawn through
  plain `SW_PAINTER.text`. Both shaped with no run skipped, no glyph 0 (tofu),
  Hebrew right to left, ink on both lines and pixels at full ink colour.
  Evidence: `evidence/gw04_hebrew_greek_light.png` and
  `gw04_hebrew_greek_dark.png`.
- `SW_LABEL`'s mono note restated: a mono label still builds no layout of its
  own, and through the painter it now shapes in the theme's MONO face. The
  test proves the monospace holds (digits and capitals one width) with the
  mono face loaded privately.
- The test runner prints the failing assertion's tag and message.
- Tests: 347 pass, 0 fail, 0 warnings.

### Added (0.9.0 — THEME TOKENS FOR FILLED CONTROLS, STATUS INKS, AND DARK MODE; GW-28)

Asked for by simple_bible's light and dark mockups (gap GW-28): the
mockups draw filled controls, status chips and heat maps, and in dark mode
white text on the brightened accent fill is only about 3.3:1.

- **`SW_THEME` gains fifteen tokens in both palettes:** `ink_on_accent`,
  `ink_on_success`, `ink_on_warning`, `ink_on_danger` (text on a filled
  control; white in light, `0x0B1220` in dark); `ink_accent`, `ink_success`,
  `ink_warning`, `ink_danger` (strong text on each wash and on the surface);
  `ink_soft` (secondary body text); `divider`, `selection`, `scrim`; and a
  five-step sequential `ramp (i)` for heat maps and ordered charts.
- **`is_readable`** checks every text-bearing pairing (4.5:1 for body text,
  3:1 for labels) and that the ramp moves away from the surface step by step.
  `make_light` and `make_dark` guarantee it, and **`is_dark`** says which a
  theme is. It is deliberately not in the invariant: the invariant runs on
  every call during painting, and this is about thirty WCAG computations.
- **New setters refuse unreadable values at the call site:**
  `set_inks_on_fills`, `set_semantic_inks`, `set_quiet_tones` and `set_ramp`.
  The existing setters are unchanged.
- Tests: four in `SW_CHROME_ASSAULT` (343 pass, 0 fail).

### Fixed

- Zero warnings again. `SW_MESH.draw` no longer uses the obsolete
  `as_string_8` conversion, and the drawer-tab test agents drop the empty
  `()` argument list.

### Fixed (0.8.2 — A TEXT BOX MEASURES THE SAME TWICE, IN ROWS IT REALLY HAS)

Found by simple_chat's composer tests, which failed on two measurements that
0.8.0's shaped editing left inconsistent.

- **`SW_TEXT_BOX.preferred_height` no longer depends on the last font
  drawn.** Its floor, `SW_PAINTER.min_control_height`, measures the painter's
  CURRENT font, and only a toy-path relayout happened to select the body font
  first. At 2x the same box, text and width measured 70, 75 or 80 px depending
  on what had been painted before it, so a box was arranged at one height and
  measured at another. The new public `minimum_height` selects the body font
  and reads the floor, as every other control selects its own font. One
  visible result: an empty or one-line shaped text box now sits at the
  documented body-font floor (README: text box 42 → 80 px at 1x → 2x). Before,
  it often borrowed a smaller floor from whatever was drawn last. The six
  2x thread evidence frames were rewritten for this reason: their composer is
  80 px, not 57 px.
- **`SW_TEXT_BOX.row_height` is the pitch the lines are really stacked at.**
  It answered the theme's `scaled_line_height` on both paths, 60 px at 2x,
  while the shaped path stacks lines at the kit's line height, 45 px. A host
  capping a box at five rows therefore let it grow to about 6.7 lines. On the
  shaped path it now answers the new `SW_SHAPING.line_height`: the facade's
  `line_height`, one line of the kit's primary face at the body pixel size. The
  toy path is unchanged.
- **A blank line is a row.** The facade lays an EMPTY piece out at the bare
  pixel size and leaves the primary-face height to its consumers (simple_shaping
  R10 / FR-N01). So on the shaped path a blank line between paragraphs, or an
  empty box, was 16 px against 21 px text lines at 1x.
  `SW_TEXT_GEOMETRY.build_shaped` now gives an empty piece the kit's
  `line_height`, so N plain lines (blank ones included) measure N rows. A line
  in another script's face is still as tall as that face makes it: Hebrew
  shaped in its own face measured 25 px against Latin's 21 px at 1x.
- Four new tests in `SW_SHAPED_EDIT_ASSAULT`, run on both the toy and shaped
  paths: the height is the same after four different fonts, and one to eight
  lines are N rows (plus the inset, or the floor), with a five-row cap holding
  five lines. Three of them failed before the fix (the toy rows already held).
  Suite 335 to 339, all passing.

### Changed (0.8.1 — THE LABEL JOINS THE SHAPED PATH)

Found by simple_narrate's Studio shell, whose first gate is "Hebrew in a
label reads right-to-left": `SW_LABEL` painted with `SW_PAINTER.text` -
cairo's toy `show_text` - while the menu bar beside it had drawn through the
window's shaping kit since 0.7.2. A window with shaped text on drew its
Hebrew menu titles right-to-left and its Hebrew labels left-to-right.

- **`SW_LABEL` measures and paints through the kit** when the painter carries
  one and the role is `ui` or `body`: `preferred_width` is the layout's own
  width, a wrapping label breaks where the kit breaks it (not at blanks), and
  `draw` goes through `draw_shaped_layout`. `shaped_layout (painter, width)`
  says which path a label is on - Void is the toy path; `takes_shaped_path`,
  `is_shaped_role` and `pixel_size` beside it.
- **A `mono` label stays on the toy path** whatever the painter carries: mono
  marks machine-produced values, ASCII by definition, and the kit's face
  policy (the theme's ui face for Latin) would take the monospace away.
- An empty label shapes nothing (the toy path, zero wide, one step tall).
- Contract note: `line_step`'s `clears_the_glyphs` now holds on the toy path
  only (the shaped step is the shaped line's height plus the leading);
  `leaded: Result >= padding` added.
- `SW_LABEL_SHAPING_ASSAULT`, 5 tests: a Hebrew label's first letter paints in
  the RIGHT half (read from the layout's cluster positions) and the two paths
  paint different pixels; an emoji label carries saturated artwork the toy
  path does not; a mono label measures the same with a kit as without; an
  empty label; a wrapping body label is taller narrow than wide and has more
  than one line. Evidence: `evidence/label-hebrew-2x.png`.

### Added (0.8.0 — THE STUDIO WIDGETS: shaped editing, paragraphs, waveform)

Three gaps surfaced while framing simple_narrate's Studio against
ElevenLabs. Larry's rule: build the reusable widget, do not fudge it.

- **`SW_TEXT_BOX` edits SHAPED text.** When the painter carries a shaping kit
  (and the box is not masked), the text is laid out through it - one layout per
  LF piece, as `SW_CHAT_THREAD` does - and the box's per-character slot model
  is filled from the runs' cluster arithmetic. The caret after a character is
  its right edge in a left-to-right run and its LEFT edge in a right-to-left
  one; hit-testing takes the nearest boundary in either direction. So a caret
  walks leftward through Hebrew, a click inside it lands where the reader
  expects, and a drag selects the letters under the pointer. Lines carry their
  own measured top, ascent and height, so a fallback face taller than the theme
  row no longer overdraws its neighbour. The toy path is unchanged in
  behaviour except for one deliberate fix: **a newline's caret now stands at
  the start of the line it opens**, not the end of the one it closes.
  New public geometry: `x_at_offset`, `line_at_offset`, `offset_at`,
  `line_count`, `is_rtl_at`, `is_shaped_layout`, `is_laid_out`,
  `content_height`, `set_caret`; `Pad_x` / `Pad_y` are exported so a host can
  address the text origin. Assaulted in both engines, ten tests.

  **The bidi tie, resolved rather than guessed.** Where a left-to-right run
  meets a right-to-left one, two offsets stand at the same pixel (after the
  last LTR character, and after the visually leftmost RTL one). The rule: the
  boundary belonging to a left-to-right character wins the click; the other
  offset stays reachable by the arrow keys - the same resolution a Windows
  edit control makes with its caret-direction flag. Written into
  `offset_on_line`'s note and pinned by a test.

- **New `SW_CLUSTER_MATH`.** `char_left_x`, `char_right_x`, `cluster_x`,
  `caret_before_x`, `caret_after_x` - the cluster arithmetic `SW_CHAT_THREAD`
  and `SW_SHAPED_TEXT` each carried privately, identical to the character,
  now written once and inherited by both and by `SW_TEXT_BOX`. A caret law
  that lives in three places drifts in one of them.

- **New `SW_PARAGRAPH_LIST`.** A scrolling column of paragraphs of DIFFERENT
  heights - measured through the kit or the toy wrap, cached by a per-item
  revision, only the visible band painted - with a host-drawn gutter and
  optional bands above and below (agents), a wash colour per item, a
  selection SET with an anchor (plain / Ctrl / Shift click; `select_only`,
  `toggle_select`, `select_range`), keyboard navigation that keeps the anchor
  in view, and ONE paragraph editable IN PLACE through a real `SW_TEXT_BOX`
  seated so the text does not move when editing begins: the item follows
  every keystroke and reflows live, Escape restores, a click elsewhere
  commits, `on_edit_change` / `on_edit_commit` tell the host. `SW_LIST` is
  uniform row height by design and `SW_CHAT_THREAD` knows what a message is;
  this knows only that a paragraph has text. Fourteen tests.

- **New `SW_WAVEFORM`.** The amplitude envelope of a sound, one bar per pixel
  column, from a summary of 4,096 (low, high) columns read ONCE through a
  0-based sampler agent (`agent buffer.sample_at (?, 0)` passes verbatim) and
  re-bucketed to any paint width - a nine-minute recording is never copied.
  Played part in the accent, unplayed muted, playhead in the caret colour,
  markers as warning ticks with a mono label. Click and drag seek and fire
  `on_seek`; `position_at`, `x_of`, `column_peaks` are public and assaulted.
  Out-of-range samples clamp to full scale rather than paint outside the box.
  Eleven tests.

- **HIGHLIGHTS — the data behind the text (2026-09-06).** Larry's ask: select
  any part of a text and apply a "speaking function" from a palette, have the
  text remember it, show it in a way that stays readable, and let a later
  programmer give the marks whatever meaning their application needs. Seven
  classes, four concerns apart:

  - `SW_MARK` — the LOOK: hue 1..12 × wash / box (0..3 rules) / text outline
    (0..2) / colorized / bold / italic; a value with a short `code`.
  - `SW_MARK_PALETTE` — twelve hues as ink + wash per theme, **held by
    contract**: wash under the theme's ink ≥ 4.5:1, ink on the surface ≥ 3:1,
    light and dark; the assault walks all 48 pairs under -keep.
  - `SW_MARK_LEGEND` — the MEANING: reason → mark + label + badge (1-2 chars).
    Re-theme a reason and every span wearing it changes at the next paint.
  - `SW_MARK_SPAN` / `SW_MARKED_TEXT` — the DATA BEHIND: spans by id with a
    reason, an optional explicit look, an annotation; add / remove / restyle /
    rereason / resize; **follows the text** through `text_inserted` /
    `text_removed` (inside grows, at the start shifts, at the end does not
    grow, across trims, collapsed drops); a line-per-span codec for any store.
  - `SW_TEXT_GEOMETRY` — where every character paints, on either engine,
    lifted out of `SW_TEXT_BOX`; `segments` merges a range into one rectangle
    per line.
  - `SW_MARK_PAINTER` — washes under, effects and boxes over. Outline, bold and
    italic are honest approximations (offset passes, a packed shear matrix)
    because cairo here strokes no glyph paths and the facade shapes regular
    upright; none changes an advance. A **size policy**: below `min_effect_size`
    no glyph effects or badges and one box rule at most; below `min_mark_size`
    the wash alone.
  - `SW_MARK_LEGEND_VIEW` — the key, drawn with live swatches; `on_pick`.

  `SW_TEXT_BOX` gains `marks`, `legend`, `set_marks`, `mark_painter`; every edit
  path reconciles, and the **undo snapshot carries the marks**. `SW_PARAGRAPH_LIST`
  gains `marks_of (i)` and `set_legend`, hands the SAME marked text to its
  in-place editor and restores it on cancel. `SW_TEXT_BOX` now measures through
  `SW_TEXT_GEOMETRY` (its private slot arrays are gone).

  Three lessons the compiler taught on the way, recorded in the oracle: an
  INTEGER attribute's initialization body never runs (VWAB is an error in
  disguise); `note` is a keyword; `prune_all` on a string list wants
  `compare_objects`.

- **The showroom gains a Studio page** (`demo/sw_demo.e`): a paragraph list
  with a stripe-and-dot gutter and a plate-rule band, five speaking functions
  in a legend view whose pick lays the function over the editor's selection, a
  marked shaped text box with Hebrew inside it, and a waveform fed by a
  synthesized reading with sentence markers. Note for the next session: the
  test target compiles the demo cluster but SW_DEMO is dead code from
  TEST_APP's root, so only `-target sw_demo` type-checks it.

- Suite 327/327 (was 270). Downstream rebuilt and run: simple_chat 278/278
  (from the project root, where its evidence folder lives),
  simple_ocr_capture 75/75, simple_speed_reader 51/51.

### Fixed (0.7.2 — THE MENU JOINS THE SHAPED PATH)

- **A menu item labelled with an emoji drew an empty box.** `SW_MENU.draw`
  painted its labels with `SW_PAINTER.text` — cairo's toy `show_text` — while
  `SW_CHAT_THREAD` had painted with `draw_shaped_layout` since 0.4.0 whenever the
  painter carried a kit. Only the shaping kit resolves the Noto colour-emoji
  artwork (the PNGs beside the running exe) and shapes Hebrew, Greek and every
  other complex script. So in any consumer with shaped text on, the very same
  character drew as a **picture** in a chat bubble and as a **square** in a menu
  two inches away. simple_chat's eight-emoji reaction picker found it: eight
  identical boxes, all labelled `react`.

  `SW_MENU` and `SW_MENU_BAR` now take the shaped path whenever
  `SW_PAINTER.has_shaping` — item labels, pad titles and the popup's shortcut
  column — and fall back to the toy path, unchanged, when there is no kit. **The
  toy path is byte-identical to what it was**; every existing menu assault and
  every mnemonic evidence PNG is untouched.

- **New: `SW_SHAPED_TEXT`** — the chrome's own one-line layout cache and the
  cluster arithmetic that goes with it. `SW_CHAT_THREAD` shapes *paragraphs* at a
  wrap width and keeps them in a frame cache tied to a revision counter; a menu
  item is one short string, never wrapped, repainted every frame the menu is up,
  on an object built fresh at every open. Keyed by **text + pixel size**, and the
  pixel size is where `theme.text_scale` already lives — `(size * text_scale)
  .rounded` is the number the glyphs are shaped at, so a scale change is a
  different key by construction. A kit swap empties it; a cap of 64 bounds it.
  `SW_MENU` owns one per menu, `SW_MENU_BAR` one per bar (which is where the
  caching earns its keep — a bar is repainted on every frame of the application).

- **The mnemonic underline now comes from the layout's cluster positions.** It
  used to be placed at `advance (label.substring (1, ul - 1))` — the width of the
  text *before* the letter. That is a claim that source order and paint order are
  the same thing, and in an RTL title they are opposite: the first character
  paints **rightmost**, so the prefix advance underlined the other end of the
  word. `SW_SHAPED_TEXT.character_span` walks the line's runs in visual order and
  asks `GLYPH_RUN`'s own `cluster_map` and `x_positions` where the character
  actually landed — an `IMAGE_RUN` answering its whole box, which is what an
  emoji underlines as. Exposed as `SW_MENU.item_underline_bounds` and
  `SW_MENU_BAR.pad_underline_bounds`: **the** one formula, so `draw` paints with
  it and a test can read it without counting pixels.

- **The menu measures what it paints, in both directions.** `measure` sizes items
  from `label_width` / `hint_width` — the same queries `draw` places with — so an
  emoji-only item is as wide as its picture instead of measuring nothing and
  painting 128 pixels over its neighbour. Row height follows too: `Item_h` was a
  flat 30 that never scaled with the theme, which stayed invisible while every
  label was one line of type, and is not survivable for a Noto picture at 2x — it
  drew over the item below and out through the menu's own top border.
  `row_height` is now `Item_h.max (shaped label height + 6)`, computed by
  `measure` and cached in `item_heights`, because `item_at` hit-tests on the
  pointer path where there is a menu and a point and no painter. On the toy path
  it is exactly `Item_h`, so nothing that shipped moves.

  Four assaults, 274 → **278**: eight emoji items opened through
  `simulate_context_click` and painted, with the ink counted as **saturation** —
  the dark theme's widest channel spread is `0x0F`, Noto's thumbs-up is over
  `0xC0`, so artwork separates from chrome without pinning a pixel, and a
  `.notdef` box drawn in ink cannot pass it (shaped **4,775** saturated pixels,
  toy **0**, **6,345** pixels differing between the two renderings of the *same*
  menu); a Hebrew pad whose underline lands in the right half of its title while
  the prefix advance names the left edge, with an LTR control so the RTL answer
  cannot be a constant; the shaped measure covering what the widest item paints;
  and the total answer for a label that declares no ampersand.
  Evidence: `evidence/menu-emoji-2x.png` — eight pictures, each inside its row.

  Disabled items still draw in `ink_muted`, and the separator, the hover wash and
  the placement clamp are unchanged.

### Added (0.7.1 — THE RIGHT-CLICK DOOR)

- **`SW_WINDOW.simulate_context_click (a_x, a_y)`** — the pointer half of what
  `simulate_key_down` is for the keyboard, and the last gap in driving a window
  headless. `show_popup` is `feature {NONE}` and only the window's own event-11
  dispatch calls it, so until now a host could BUILD a context menu in a test and
  read every item off it, but could never make the window **present** one. Nothing
  between the click and the painted menu was provable: that `target_at` finds the
  widget, that `bubble_context` walks to the first ancestor offering a menu, that
  the widget takes the focus a right-click gives it, that the menu is placed.

  **The door is one line — `dispatch (11, a_x, a_y)` — on purpose.**
  `simulate_key_down` was once four lines that called `route_key_down`
  unconditionally, and an arrow-key assault passed *with the fix deleted*, because
  the door was a SECOND path that never saw the popup branch at all. A test door
  that reasons about anything is a test door that can be right while the product is
  wrong. Routing through `dispatch` means modality is asked first, exactly as the
  native queue asks it — which is why a second context click **closes** the open
  menu rather than stacking a second one over it, and why that behaviour is now
  under test without a line of code written for it.

  Four assaults, 270 → **274**: a click presents the widget's own menu and focuses
  it; a second click closes it; a click over a widget with no menu opens nothing —
  the honest answer, since a door that opened an empty popup would put a grey
  rectangle on screen for every stray right-click in the application; and one
  itinerary that opens the menu **with the pointer**, walks it **with the
  keyboard**, paints the frame and closes it with Escape.
  Evidence: `evidence/menu-context-open-2x.png` — a real context menu, painted.

  Found while writing it, and worth the next reader's time: `SW_MENU` names its
  highlight `hover_index`, not `hovered`.

### Added (0.7.0 — THE PER-MESSAGE MENU: edit, react, delete, reply)

- **`SW_CHAT_THREAD` bubbles can be CHANGED after they are drawn.** Larry, through
  the chat agent: *a per-message menu — reply, react, edit, delete.* The public
  model was `add_message` and `append_to_last` and nothing else, so a bubble
  could be born and grown and never touched again. A chat server does not work
  that way: it folds *edit*, *delete* and *reaction* events over the message
  they name, and a *reply* is a message carrying a parent's id. The class's own
  note already said mutation was architecturally supported — every content
  change bumps `revision` and `refresh_layouts` rebuilds — it was simply never
  exposed.

  - `set_message (i, role, text)` — replace the words, and the speaker when the
    role is not `Role_keep` (a new constant, and NOT a role: it is what an edit
    passes when the author has not changed, which is what a server's edit event
    carries). Drops a selection that lived in that bubble, because selection
    offsets are offsets into text and one that outlives its text hands the
    clipboard somebody else's words.
  - `mark_edited (i)` / `is_edited (i)` — a small muted marker band.
  - `tombstone (i)` / `is_tombstone (i)` — see below.
  - `set_reactions (i, list)` / `reactions_of (i)` — a compact row of emoji +
    tally chips, the reader's own OUTLINED in the accent so "I reacted" is
    legible without asking anyone to tell two washes apart. The row is
    REPLACED wholesale (the server has already deduped per person per emoji; a
    widget that merged would be keeping a second, worse tally) and COPIED in
    and out, so neither side can rewrite a drawn frame through a borrowed list.
    The tuple field is `tally` and not `count` for one reason: `TUPLE` already
    has a `count` and a labelled field cannot shadow it.
  - `set_reply_quote (i, author, text)` / `has_reply_quote` / `reply_quote` /
    `quote_line` / `drawn_quote` — a ONE-LINE quoted header, elided at the
    bubble's inner width. One line always: a quote allowed to wrap stops being
    a header and becomes a second message.
  - `message_at (x, y)` and `reaction_at (x, y)` — the two questions a host's
    right-click has to answer before it can offer a menu, both from the frame
    geometry `hit_test` has used since 0.6.0, so a menu and a selection can
    never disagree about which message was meant.
  - `bubble_height (i)` — what the last frame measured a bubble at, published
    for the same reason `content_h` is.
  - `elided` / `with_ellipsis` — cut-to-width in the selected font, found by
    HALVING rather than walking (a quoted line can be a paragraph, and one
    `advance` per character is a measurement bill nobody asked for on a frame
    that is also shaping bubbles).

- **THE INVARIANT NEEDED NOTHING NEW, and that is the point.** Every one of the
  five commands is a content change, and a content change has meant "bump
  `revision`" since 0.5.0. So `laid_out_revision` lags,
  `spans_match_when_current` goes quiet for exactly one frame,
  `refresh_layouts` rebuilds and records — the same door `add_message` has gone
  through since 0.6.1 wrote that guard for a defect found in a live client.
  None of them can re-shape: a span indexes layouts only
  `SW_SHAPING.layout_for` can make, at an inner width and a pixel size the
  widget does not learn until `draw`. The new invariant clauses mirror the old
  ones exactly — the decoration STORE is content, so it is one entry per
  message unconditionally; the decoration LAYOUTS are shaped artefacts, so
  `decor_revision = revision` guards them the way `laid_out_revision` guards
  the spans.

- **A DELETE IS A TOMBSTONE, NEVER A GAP.** `tombstone` keeps the bubble where
  it is, at reduced height, muted, reading *message deleted* — because the
  ORDER of a thread is part of its record and a vanished bubble silently
  rewrites who answered whom. It DOES really destroy the text
  (`messages.i_th (i).text` is emptied, not hidden), so no selection can reach
  it and `copy_selection` has nothing to take. Hiding the words behind a flag
  would have left them one query away from anyone with a debugger, which is not
  what "deleted" means. Every decoration goes with it. It is terminal and
  idempotent: the other four commands `require` a live message.

  A tombstone is guaranteed SHORTER than the bubble it replaced, at every text
  scale and on both text paths — not by hoping the placeholder is small, but by
  construction: its band is capped at one body line and its padding is half
  `Bubble_pad`. It is dimmed and outlined rather than italic, because
  `SW_PAINTER.font` takes a weight and no slant and there is no honest way to
  fake one.

- **Four bands, all MEASURED.** A bubble is now up to four stacked bands inside
  its own padding — reply quote, text, "edited" marker, reaction row — and each
  changes the bubble's height, therefore `content_h`, therefore the scrollbar
  thumb. Stickiness survives all of it exactly as `add_message` preserves it:
  a thread parked at the tail is re-parked, a reader who has scrolled up is not
  yanked. The reaction row WRAPS at the bubble's inner width rather than run
  off its own edge.

  Both text paths are served. The quote and each chip's emoji go through the
  shaping kit when there is one — so a Hebrew quote reads right-to-left and a
  reaction carries the same Noto picture the bubbles use — and fall back to
  cairo's toy metrics when there is not. The decoration layouts are kept OUT of
  `shaped_layouts` deliberately: `layout_spans` tiles that list exactly
  (`spans_tile_the_layouts`), and a quote laid into it would make the tiling a
  lie and every paragraph offset wrong by one.

- **`SW_CHAT_MUTATION_ASSAULT`** — 15 new tests, offscreen only, at 1x and 2x
  and on both paths: the invariant survives all five mutators between frames;
  a tombstone is shorter, keeps its place, and holds nothing a selection can
  reach; a reaction row moves the bubble, `content_h` and the thumb, and eight
  chips wrap to a second row; `message_at` names every bubble and answers 0 in
  the gaps; `reaction_at` finds the clicked chip by a grid sweep and nothing
  off it; a quote is one line with the ellipsis the elision promises. Evidence:
  `evidence/thread-mutation-2x.png`. **255 → 270 tests, 0 failed.**

### Added (0.6.2 — THE ARROW KEYS, the half of the menu gesture 0.6.1 left out)

- **An open menu now walks under the arrow keys.** 0.6.1 closed the Alt door:
  `Alt+F` opens the File menu. What it did not do was let you *move* once you were
  in — and Larry found that within minutes of adopting it: *"Once open, the
  arrow-keys need to navigate just like all Windows programs do."*

  The cause was written down in the source, in `SW_WINDOW.dispatch_to_popup`'s own
  comment: *"While a popup is up it owns the pointer and Escape; everything else is
  swallowed until it closes."* It handled the click, the hover, Escape and the bare
  letter that picks an item by mnemonic. It had **no branch for the virtual-key**
  **event** — and every arrow, plus Home, End and Enter, arrives as one. They
  reached the window and were discarded.

  - `SW_MENU` — `hover_next`, `hover_previous`, `hover_first`, `hover_last`,
    `clear_hover`, `is_selectable`, `has_selectable`, `hovered_action`. The
    highlight **steps over separators and disabled items**, which is what every
    Windows menu does and what a naive `index++` gets wrong. Wrapping is bounded by
    the item count, so a menu of nothing but separators terminates instead of
    spinning.
  - `SW_MENU_BAR` — `last_opened_pad`, recorded on **both** doors (a pointer click
    and `open_menu`), and `neighbour_pad` to walk the bar with wrap. A menu opened
    by mouse therefore answers Left/Right exactly as one opened by Alt: the two
    paths cannot drift.
  - `SW_WINDOW` — `navigate_open_menu`: Down/Up move, Home/End jump, Enter runs the
    highlighted item and closes, Escape closes running nothing, Left/Right open the
    neighbouring pad. Public for the reason `activate_mnemonic` is public: it is the
    whole gesture. `dispatch_to_popup` gained the `when 4` branch that reaches it.

- **`SW_WINDOW.deliver_key`** — a public door onto the window's own `dispatch`, so
  an assault can deliver a key **the way the message pump does** rather than calling
  the gesture directly.

  This exists because of a mistake worth recording. The first four assaults for the
  arrow keys called `navigate_open_menu` themselves — and **passed with the routing
  deleted**, because they never went through the branch that was missing. A test
  that skips the branch it is meant to guard is worth nothing. Re-pointed through
  `deliver_key`, the suite is **255 / 0** with the fix and **253 / 2** without it.

### Fixed (0.6.1 — TWO SEAMS 0.6.0 LEFT, both found by the first host to adopt it)

- **`SW_CHAT_THREAD` could not be given a message after it had drawn a shaped
  frame.** Its invariant demanded `layout_spans.count = messages.count` the
  moment `shaped_layouts` was non-empty, but `layout_spans` is rebuilt only by
  `draw` — so between `add_message` (n+1 messages) and the next frame (n spans)
  the class **failed its own invariant, on exit from `add_message`**. That is
  precisely what a live chat client does on every event after its first frame.
  It never bit Larry because the shipped client is finalized and finalized code
  checks no invariants; it bit every workbench and `ec.sh test` build, and it
  bit simple_chat's adoption branch, which had to fill a pane before painting it
  rather than painting and then filling.

  **The weakening was the honest fix, and it made the invariant stronger, not
  vaguer.** The other branch — keeping the spans in step inside `add_message` —
  cannot be done: a span indexes `SHAPED_LAYOUT`s that only
  `SW_SHAPING.layout_for` can make, at an inner width and a pixel size the
  widget does not learn until the painter hands them over inside `draw`. To
  rebuild there, a content command would have to invent a width or demand a
  painter from a caller who has one only while painting — turning "a message
  arrived" into "draw a frame". The equality was therefore never a property of
  the class. It is a property of a CURRENT layout, and the class already carries
  the flag that says so:

  ```eiffel
  spans_never_outrun_messages: layout_spans.count <= messages.count
  spans_match_when_current: laid_out_revision = revision implies
      layout_spans.count = messages.count
  spans_and_layouts_arrive_together: shaped_layouts.is_empty = layout_spans.is_empty
  spans_tile_the_layouts: layout_spans.is_empty or else
      layout_spans.last.base + layout_spans.last.span - 1 = shaped_layouts.count
  a_layout_per_paragraph: shaped_layouts.count >= layout_spans.count
  ```

  Every content change bumps `revision`; `refresh_layouts` rebuilds and only
  then records it, and **already carried the equality as its own postcondition**
  (`one_span_per_message`), so nothing was lost by moving it there. What was
  gained: `spans_tile_the_layouts` says the spans partition `shaped_layouts`
  exactly — a structural truth that holds BETWEEN frames and that the old
  invariant never asserted at all — and `spans_match_when_current` now also
  catches a caller who mutates the public `messages` list behind the widget's
  back without bumping `revision`, which the old clause let through.

  **The sibling clauses were checked for the same hole and have none.**
  `displays`, `line_cache` and `bubble_boxes` are asserted only as attached;
  no clause couples their counts to `messages`, and every reader of those
  frame caches (`hit_test`, `hit_in_message`, `draw_selection`) already guards
  on the cache's own count, so a click that lands on a bubble not yet drawn
  simply misses instead of raising. `a_layout_per_paragraph` had the identical
  hole in its `implies` and is fixed with it.

- **Alt+letter reached the accelerator table and died there.** simple_shell
  1.9.3 closed the shell half of *the Alt gap* this library named in 0.6.0:
  Alt+A..Z and Alt+0..9 now arrive as the ORDINARY key-down event 4 by virtual
  key, with the `WM_SYSCHAR` behind them swallowed so `DefWindowProc` cannot
  open the system menu behind the application's back. **That swallow is exactly
  why the toolkit still saw nothing:** `activate_mnemonic` sat on the WM_CHAR
  door (event 3), which the shell now never knocks on for an Alt combination.
  The gesture was consumed by the accelerator table or handed to the focused
  widget, and Alt+F opened nothing unless the host registered Alt+F/E/R/H by
  hand — which simple_chat's adoption branch had to do.

  `route_key_down` is now the one itinerary for event 4, in order: the
  **accelerator table** (so a host that really wants Alt+F still keeps it),
  then — with `alt_down` and the key unclaimed — the window's own `menu_bar`
  via `key_down_mnemonic_fired`, then the **focused widget**. `set_menu_bar`
  is all a host needs; nothing else changed and no signature moved. The WM_CHAR
  path is untouched, for shells that still deliver Alt that way.

  `key_down_mnemonic_fired` deliberately does **not** arm `swallow_next_char`:
  the shell that forwards this event swallows the WM_SYSCHAR itself, so there
  is nothing trailing to eat and arming the flag would eat the reader's next
  real keystroke; and were a shell to deliver both, the popup just opened owns
  every following event (`dispatch_to_popup`), so it could not fire twice
  either.

### Added (0.6.1)

- **`SW_WINDOW.simulate_key_down (a_vk, a_ctrl, a_alt, a_shift)`** — the wheel
  door's twin (`simulate_wheel`). It runs the SAME `route_key_down` the native
  event 4 runs, with the modifier state passed as parameters instead of read
  from a live `GetKeyState`, because `SW_KEYS` asks the real keyboard and an
  offscreen harness must never press Alt on anybody's desktop. The Alt door is
  therefore proven through the shipped path and not a copy of it.

- **Four tests** (251 total, from 247). `a_message_may_arrive_after_a_shaped_frame`
  paints a shaped frame, adds a message, streams a token and paints again —
  RED before the invariant fix, on the exit of `add_message` itself.
  `alt_letter_on_the_key_down_door_opens_the_menu` drives Alt+F through
  `simulate_key_down` with no accelerator registered — RED before the mnemonic
  arm. `a_host_accelerator_still_wins_the_alt_key` pins the order, and
  `alt_needs_a_menu_bar_before_it_opens_anything` pins the bar-less window.

### Fixed (THE SQUARE BOXES — line breaks in a chat bubble; the 0.6.0 minor bump)
- **`SW_CHAT_THREAD` drew a box wherever a message had a newline.** Neither
  path had ever heard of a line break. The toy wrap split on the SPACE
  CHARACTER ALONE (`a_text.split (' ')`), so an LF was simply another
  character inside a "word" and cairo drew it as `.notdef` — the box Larry
  saw in every numbered list the assistant sent. The shaped path failed more
  quietly: simple_shaping counts LF among the characters a line MAY break at
  (`is_breaking_space_code`), so the text wrapped somewhere near the break,
  but the LF itself was still shaped, still measured and still painted.
  Both paths now cut a message into PARAGRAPHS first — `paragraphs_of`, a
  public, contracted query: LF, CRLF (ONE break, not two) and a lone CR all
  end a paragraph and are never drawn; a TAB becomes a space; a RUN of
  breaks yields at most ONE empty line, so a message padded with blank lines
  cannot inflate a bubble without bound; trailing blank paragraphs are
  dropped. Wrapping applies WITHIN a paragraph, and a bubble's height is the
  real line count.
- **The shaped path is now one `SHAPED_LAYOUT` per PARAGRAPH**, not one per
  message, because simple_shaping lays out a paragraph and cannot be told
  about a hard break. `shaped_layouts` is therefore a flat list in message
  order and the new `layout_spans` says which layouts belong to which
  message (`shaped_layouts [base .. base + span - 1]`). A message with no
  line breaks is still exactly one layout, so single-paragraph traffic sees
  no change at all.
- **Menu underlines draw in the label's own ink.** `SW_PAINTER.hline` sets
  the THEME OUTLINE colour itself, which under a label on a dark theme reads
  as nothing; the mnemonic underline uses `fill_rect` in the ink the label
  just drew in, and scales its thickness with `theme.text_scale`.

### Added (KEYBOARD — window-wide accelerators and menu mnemonics)
- **`SW_WINDOW.register_accelerator (a_vk, a_ctrl, a_alt, a_shift, a_action)`** —
  a window-level key table consulted BEFORE focused-widget routing, matched
  on the virtual key AND the exact modifier state (read from `SW_KEYS`, the
  same service `SW_TEXT_BOX` already asks for Shift). With
  `accelerators`, `accelerator_for`, `fire_accelerator` and
  `clear_accelerators`. A modifier is REQUIRED (`require modified: a_ctrl or
  a_alt`): an unmodified accelerator would take the letter out of every text
  box in the window. An UNCLAIMED Ctrl+A / C / V / X / Z / Y still reaches
  the focused text box exactly as it always did; a claimed one never does.
  **No existing signature changed** — `SW_WIDGET.handle_key (a_vk, a_shift)`
  is untouched.
- **Both key doors are tried.** simple_shell's WM_KEYDOWN filter forwards
  only the stepping keys (arrows, Home/End, Page keys, Delete, the OEM
  plus/minus pair) as event 4, so a letter key never arrives that way.
  Ctrl+C arrives instead as event 3 — the WM_CHAR CONTROL CODE 3, which is
  exactly how `SW_TEXT_BOX` has always read it. `dispatch_plain` therefore
  tries the table on event 4 by virtual key and on event 3 by control code
  folded back to its letter (code + 64). A hit on the key-down door swallows
  the WM_CHAR that trails it, so one gesture never fires twice.
- **Menu mnemonics.** `SW_MNEMONIC` is the one ampersand parser (`plain`,
  `underline_index`, `mnemonic_letter`, `has_mnemonic`, `matches`,
  `virtual_key`): `"&File"` draws as `File` with the F underlined,
  `"Select &All"` underlines the A, `"R&&D"` is the literal `R&D` with no
  mnemonic, a trailing `"&"` marks nothing. `SW_MENU_BAR` gains
  `raw_labels`, `pad_underline_index`, `menu_for_mnemonic`, `open_menu` and
  `pad_bounds` (ONE geometry: `draw`, `handle_click` and a keyboard open all
  ask it). `SW_MENU` gains `raw_labels`, `item_underline_index` and
  `item_for_mnemonic`. `labels` / `items.label` keep the PLAIN reading, so
  every existing reader sees the text it always saw.
- **`SW_WINDOW.set_menu_bar` / `activate_mnemonic` / `open_popup`.**
  Alt+letter opens that pad's menu, dropped under the pad itself; while a
  menu is open a BARE letter picks the item that underlines it (the second
  half of the Alt+F, then N gesture) — that half works today, since a menu
  swallows WM_CHAR already.
- **THE ALT GAP, NAMED.** Alt *state* is exposed — `SW_KEYS.alt_down` reads
  `GetKeyState(VK_MENU)` the way `shift_down` reads VK_SHIFT — so an Alt
  accelerator can be registered and WILL match. Alt+letter *delivery* is the
  gap: simple_shell answers WM_SYSKEYDOWN only for the OEM plus/minus pair
  and lets every other syskey fall through to `DefWindowProc`, swallowing
  WM_SYSCHAR for those same keys alone. Until simple_shell forwards
  WM_SYSKEYDOWN/WM_SYSCHAR for letters, Alt+F reaches the system menu and
  not this window; `activate_mnemonic` is implemented, contracted and tested
  and a host can drive it from a Ctrl accelerator or a click today.
  **Ctrl accelerators work end to end NOW.** simple_widgets was not able to
  close this half; it lives in `simple_shell/Clib/simple_shell.h`.

### Added (SELECTION AND COPY in `SW_CHAT_THREAD`)
- **A bubble is selectable text, not a picture of text.** Press and drag to
  select, double-click to take the word, Escape to clear, Ctrl+C or the new
  right-click menu (Copy / Select Message / Select None) to copy through
  `SW_CLIPBOARD` — the same door `SW_TEXT_BOX` uses. Public model:
  `sel_message`, `sel_anchor`, `sel_caret`, `sel_low`, `sel_high`,
  `has_selection`, `is_selecting`, `selected_text`, `clear_selection`,
  `select_range`, `select_word_at`, `select_message`, `copy_selection`, plus
  the hit-testers `hit_test` and `hit_in_message` and the reading the
  clipboard actually receives, `display_text`.
- **Character granularity on the toy path; GLYPH-CLUSTER granularity on the
  shaped path.** `SHAPED_LINE` reserves `character_index_at_x` for a future
  simple_shaping cycle and does not implement it, so the caret-boundary walk
  lives in the widget, over what the layout does publish: `GLYPH_RUN`'s
  `cluster_map` and `x_positions`. RTL is handled by direction, not by hope —
  in a right-to-left run the boundary at a cluster's LEFT edge is the caret
  AFTER that character.
- **Selection is within ONE bubble, deliberately.** A drag that wanders out
  runs to the anchor bubble's own ends and stops. A thread is a list of
  utterances by different speakers; a range spanning three of them has no
  honest text to hand the clipboard.
- **A press inside a bubble is now CONSUMED** (the pane needs the pointer
  capture to receive the drag) and `cursor_kind` is the I-beam. A press on
  bare pane clears the selection and still bubbles up, as before.

### Changed
- `SW_CHAT_THREAD.wrapped` is public and honours line breaks; it is now
  stated over `paragraphs_of` + the new `wrap_spans`, so there is ONE wrap
  in the class. The greedy algorithm and its 4.5 px inter-word gap
  (`Space_w`) are unchanged, so a wrap that fitted at 0.5.0 still fits.
- `SW_CHAT_THREAD`'s invariant relaxed from "one layout per message" to "at
  least one layout per message, one span per message".


### Fixed (CHAT THREAD SCROLLING — the scroll-clamp defect; the 0.5.0 minor bump)
- **`SW_CHAT_THREAD` could never show its own tail, and no wheel or drag
  survived a repaint.** `draw` clamped `scroll_y` once PER BUBBLE against
  `content_h` while it was still mid-accumulation — the first bubble always
  saw a content height of 8.0, the loop's own starting value, so on any pane
  taller than 8 px the clamp reset `scroll_y` to ~0 on every single frame,
  before the true total was ever measured. Adding a message, or turning the
  wheel, changed `scroll_y` — but the very next `draw` threw it away. `draw`
  now runs two passes: PASS 1 measures every bubble with no drawing and no
  dependence on `scroll_y`, so `content_h` is the real total before anything
  is clamped against it; PASS 2 draws at the one offset the frame settled
  on. Every scroll-changing entry point — the wheel, a scrollbar drag or
  track click, PageUp/PageDown/Home/End — now funnels through one
  `scroll_to (a_y)` query, so the `[0, max_scroll]` clamp and the
  sticky-tail law apply everywhere, not just in `draw`.

### Added
- **`SW_CHAT_THREAD` draws its own vertical scrollbar** — track and thumb
  along the right edge, sized from `SW_THEME.text_scale` (`Scrollbar_w` is
  12 px at 1x), visible only when `max_scroll` > 0.0 and invisible/inert
  otherwise. `max_scroll`, `scrollbar_visible`, `track_x`, `track_y`,
  `track_h`, `thumb_height`, `thumb_top`, `scroll_to`, `is_dragging_thumb`
  are all public and contracted (the thumb stays within its track;
  `scroll_to` clamps to `[0, max_scroll]`). Draggable with the mouse and
  clickable-to-page on the bare track, through the widget's existing
  `handle_click` / `handle_drag` / `handle_release` — no new input plumbing
  in `SW_WINDOW`. Bubble wrap width reserves the scrollbar's gutter
  unconditionally, so crossing the overflow line never reflows a bubble
  already on screen.
- **`SW_CHAT_THREAD` now accepts keyboard focus** (`accepts_focus`, joining
  the Tab ring the way `SW_LIST` does) and answers PageUp, PageDown, Home
  and End — `SW_LIST`'s own virtual-key vocabulary (33/34/36/35) — once
  clicked.
- `SW_WINDOW.simulate_wheel (a_x, a_y, a_delta)` — deliver a wheel turn
  through the SAME `target_at` + `bubble_wheel` path a real WM_MOUSEWHEEL
  takes, for an offscreen harness with no native event queue to draw one
  from (`run` is never called, so `hwnd` stays `default_pointer` and no
  window, visible or hidden, is ever created).
- `SW_WINDOW`'s session log (`sw_session.log`) now prefixes every line with
  a local `YYYY-MM-DD HH:MM:SS` timestamp (`SW_WINDOW.timestamp_prefix`),
  and logs a `session start` line (the theme's `text_scale` and the window
  size) alongside the existing `window up`.

### Fixed (MARGINS AND PADDING — Vision2's outside/inside model; the 0.4.0 minor bump)
- **Controls no longer sit on the window edge.** `SW_COLUMN.padding` defaulted
  to 0.0, so every window whose root was a column put its first control at
  (0, 0). `SW_WINDOW` now insets its root by `theme.border_width` on all four
  sides (`SW_WINDOW.content_border`), and `SW_DIALOG` does the same inside its
  card. The border is applied **once**: plain boxes keep a 0 border of their
  own, exactly as Vision2 defaults `EV_BOX.border_width` to 0
  (`EV_BOX_I.Default_border_width`) and lets the dialog set it
  (`EV_MESSAGE_DIALOG` does `vb.set_border_width (10)`), so nesting cannot
  double it.
- **`SW_LABEL` stepped wrapped lines by `size + 9.0` while painting at
  `size * text_scale`.** The two agreed only at 1x; at 2x the lines collided.
  `SW_LABEL.line_step` and `baseline_offset` are now measured from cairo's font
  extents at the size actually painted, and `space_advance` measures the blank
  the wrapper used to assume was 4.5 px.
- `SW_TEXT_BOX` rows stepped by the nominal `theme.line_height` at any scale;
  they now use `theme.scaled_line_height`, and the caret hit test agrees with
  the paint (`laid_row_h`) instead of assuming 26 px.

### Added
- `SW_THEME.border_width`, `SW_THEME.padding`, `SW_THEME.control_inset`,
  `SW_THEME.scaled_line_height`, `SW_THEME.control_pad`, `SW_THEME.set_spacing`
  — the three spacing tokens (12 / 8 / 11 px at 1x), every one multiplied by
  `text_scale`, so 2x text gets 2x margins with no layout change.
- `SW_PAINTER.font_ascent`, `font_descent`, `text_extent`, `min_control_height`,
  `min_control_width (s)`, `baseline_in (y, h)` — the minimum-size law, MEASURED
  from cairo's `font_extents` for the selected font rather than declared as a
  constant. This is the role `EV_LAYOUT_CONSTANTS.default_button_height` plays
  in Vision2, with a measurement in place of its dialog-unit conversion.
- `SW_COLUMN` / `SW_ROW`: `set_gap`, `set_padding` (SW_COLUMN),
  `gap_is_explicit`, `padding_is_explicit`, `default_gap`, `default_padding`,
  `effective_gap`, `effective_padding`. **An explicit value always wins**,
  including an explicit 0.0, at any scale; a box that was never told follows the
  theme.
- `SW_LABEL.line_step`, `baseline_offset`, `space_advance`;
  `SW_TEXT_BOX.row_height`, `row_baseline`; `SW_CHECK_BOX.box_side`;
  `SW_DIALOG.border_width`, `button_height`.
- 9 tests in `testing/sw_margins_assault.e` (204 → 213 passing): the theme
  tokens and their scaling, first child at (border, border), siblings one
  padding apart, last child clearing the bottom, a nested column adding NO
  second border, explicit-wins at 1x and 2x, card/group borders, the
  font-measured control minimum, controls tracking the font 1x → 2x, and the
  label line step matching its painted glyphs. Evidence PNGs are rendered
  OFFSCREEN onto a cairo image surface (`evidence/margins-before.png`,
  `margins-after.png`, `margins-1x.png`, `margins-2x.png`).

### Changed
- `SW_BUTTON`, `SW_TEXT_BOX`, `SW_CHECK_BOX`, `SW_NUMBER_BOX` clamp their
  natural height up to `min_control_height`; a larger explicit anchor still wins
  through `clamped_height`. Measured 1x → 2x: 38 → 75, 42 → 80, 38 → 75,
  38 → 75 px.
- Box descendants take their spacing from the theme instead of a literal, at
  the same 1x values as before except where noted: `SW_CARD` border
  `control_inset` (11), `SW_FILE_DIALOG` border `padding × 0.75` (6) and gap
  `padding × 1.25` (10), `SW_DRAWER` / `SW_KANBAN` gap `padding × 1.25` (10),
  `SW_PROMPT_VIEW` / `SW_QUERY_BUILDER` gap `padding × 0.75` (6),
  `SW_FORM_GENERATOR` gap `padding` (8). `SW_GROUP`'s border moves from a fixed
  14 to `theme.border_width` (12 at 1x). `SW_DIALOG`'s card border is
  `border_width × 1.5` (18 at 1x, unchanged) and its buttons obey
  `min_control_height`.
- `SW_BUTTON`, `SW_CHECK_BOX` and `SW_DIALOG` centre their labels on the
  measured font (`SW_PAINTER.baseline_in`) instead of a constant offset from
  the bottom edge.

### Added (SHAPED TEXT — simple_shaping adopted; the 0.3.0 minor bump)
- The toolkit can hand its text to `simple_shaping` instead of to cairo's
  toy API: bidi (Hebrew reads right-to-left inside a left-to-right pane),
  script itemization, glyph shaping, deterministic font fallback, and
  emoji as the same shipped Noto picture on every screen. Opt-in, one
  call: `SW_WINDOW.enable_shaped_text`.
- NEW CLASS `SW_SHAPING` — the ownership object: ONE `SIMPLE_SHAPING`
  facade plus ONE `SHAPING_CAIRO_BRIDGE`, held by the WINDOW and handed to
  each painter it builds. It is not a painter attribute because SW_WINDOW
  rebuilds its painter on a theme swap and on an offscreen re-allocation,
  and a facade living there would take the layout cache and every decoded
  emoji surface with it. `set_theme_faces` prepends the theme's UI face
  for the LATIN class only — a theme face is Latin-only by design, and
  asking Archivo to carry niqqud is how tofu reaches the screen (Q1).
- `SW_PAINTER`: `shaping`, `has_shaping`, `set_shaping`, `is_resize_storm`,
  `set_resize_storm`, and `draw_shaped_layout (a_layout, a_x, a_y)` —
  where (a_x, a_y) is a TOP-LEFT, not a baseline, because a SHAPED_LAYOUT
  already knows each line's ascent. Void `shaping` is the default and is
  NOT a degraded state: every widget that has not been taught shaped text
  keeps the toy path, unchanged.
- `SW_WINDOW`: `shaping`, `set_shaping`, `enable_shaped_text`. The kit is
  re-attached after every painter rebuild, and the window now publishes
  its own `busy_ticks` debounce to the painter as `is_resize_storm`.
- `SW_CHAT_THREAD` lays its bubbles out through the shaping facade when a
  kit is present: bubble height is `layout.total_height` and never a line
  count times a constant (a line carrying an emoji box is taller than one
  that does not), and the greedy word wrap is skipped. New public
  `shaped_layouts`, `laid_out_width`, `laid_out_size`, `revision`,
  `laid_out_revision`. Every existing contract and behaviour is kept:
  `add_message`, `append_to_last`, sticky-bottom, `content_h`,
  `handle_wheel` are untouched, and without a kit the widget is
  pixel-for-pixel what it was.
- R10, re-layout at resize END: a WIDTH change waits for the resize storm
  to clear, so a drag costs zero shaping calls; a CONTENT change never
  waits, because a message arriving mid-drag still has to appear.
- ECF: `simple_shaping` added to the `simple_widgets` PARENT target ONLY.
  Extending targets inherit it; listing a library in both a parent and an
  extending target makes ec resolve NO classes from it at all (the same
  lesson simple_shaping recorded for simple_cairo).
- `tools/stage_runnable.sh` stages a runnable folder: `cairo.dll`,
  `LICENSE-ASSETS.md` and `assets/noto-emoji/png/128/` beside the exe.
  Assets are resolved against the RUNNING EXECUTABLE's directory, never
  the working directory.
- Tests: `SW_SHAPING_ASSAULT`, five headless paint tests including the
  D-015 acceptance line end to end (laid out by the production facade,
  painted through SW_PAINTER, ink counted in three x-regions with the
  same-N tripwire) writing `evidence/shaped-d015.png`.

### Observed upstream (simple_shaping; reported, not worked around)
- `SIMPLE_SHAPING`'s glyph-run assembly copies the shaper's `y_offsets`
  straight into `GLYPH_RUN.y_positions`, while simple_shaping's own Task 13
  evidence states the rule as `y_positions [i] = -shaped.y_offsets [i]` -
  DirectWrite's `ascenderOffset` is positive UPWARD and cairo's user space
  is y-down, so the sign is the assembler's to get right. The toolkit does
  NOT compensate: the bridge's layering is correct and a consumer working
  around it would be papering over the seam. It is also, so far,
  UNOBSERVABLE: `test_niqqud_offsets_are_reported_not_swallowed` lays out
  pointed Hebrew (shin + shin-dot + qamats ... holam) at 24 px and finds
  ZERO glyphs with a non-zero `y_position`, as does the D-015 line at
  16 px. Both numbers are printed by the suite so the library's owner has
  measurements rather than a reading of the source.

### Known limits (shaped text)
- `SW_LABEL` and the rest of the chrome still draw through
  `SW_PAINTER.text`. Their `preferred_width` / `preferred_height` are
  cairo toy advances and the whole toolkit's layout is measured from them,
  so swapping their metrics is a wider change, not a small safe one.

### Fixed (DIALOGS HONOUR NEWLINES)
- SW_DIALOG word-wrapped its message as one run: '%N' survived
  inside a "word" and drew as a missing glyph (the About tofu).
  measure now splits into paragraphs on '%N' first - each newline
  breaks a line, a blank line stands as a paragraph gap. Every
  dialog with a %N%N message (the model-download offer, the
  auto-stop announcement) was showing boxes; all healed.

### Fixed (MODALITY LETS SHELL EVENTS PASS; the lockup's second door)
- dispatch_to_dialog, dispatch_to_popup and dispatch_in_pick
  swallowed every event type they did not own - including the status
  strip's 21..23, the fast tick 25 and the region overlay's 31..35.
  A dialog opening while the OCR overlay was up (health alerts
  arrive on the tick) would have trapped the user beneath it: the
  topmost overlay eats the pointer, the dialog eats the overlay's
  Escape. Shell events (type >= 21) now pass through modality to
  set_on_shell_event - modality gates this window's widget tree,
  never the app-owned windows or the application clock. Bonus: the
  capture cycle keeps ticking behind any dialog.

### Fixed + Added (CONTAINERS LEARN THEIR WIDTH; the speller teaches)
- FIXED (found by hand-testing the OCR rebuild): SW_ROW, SW_COLUMN
  and SW_TEXT_BOX had NO preferred_width - a row nested inside a
  row got zero width, drew its children overflowing it, and was
  UNHITTABLE where it drew (widget_at gates on contains). Rows now
  answer the sum of their children plus gaps, columns the widest
  child plus padding, text boxes a real field presence (240) that
  growers stretch past. Nesting is finally lawful.
- SW_TEXT_BOX spell menu grows the two missing verbs: Ignore "word"
  (session-scoped, the OS checker's own Ignore) and Add "word" to
  dictionary (persists to the user's WINDOWS dictionary, honoured
  by Edge and Office too) - riding simple_shell 1.5.0's
  SHELL_SPELLER teaching, assaulted live at the shell.
- Suite 193/193.

### Fixed (ZONES ARE NOT BANDS - civil time lands)
- Larry's Atlanta report, root-caused: the dot was right, the band
  arithmetic was right, but solar bands are not civil zones -
  Atlanta at 84W is solar -6 yet rides Eastern. THREE layers fixed:
  (1) every generated city now carries its CIVIL utc offset
  (standard time via the tz database at generation; solar fallback
  for the nine zoneless places); (2) labels and cities_in_band
  speak civil truth (Mumbai +5:30 buckets under +5; hover says
  'Atlanta (183) United States of America (183) 4.5M (183) UTC-5');
  (3) the picker CLICK snaps to the nearest city within reach and
  answers its civil zone - only open ground falls back to solar
  band arithmetic, the only honest thing an unmapped point can say.
- Pinned in the suite: solar arithmetic at 84.37W says -6, clicking
  ATLANTA answers -5, the open Atlantic answers solar -3; Atlanta
  lists under -5 beside New York, Miami, Toronto; civil band zero
  is London/Abidjan/Lisbon (Paris moved to +1 where it belongs).
  Suite 193/193.
- The band STRIPE remains solar geometry (political zone SHAPES
  would need Natural Earth's time-zones layer - a follow-up the
  generator pattern is ready for).

### Added (MAP ZOOM - the wheel owns the planet)
- SW_MAP wheel zoom AT THE POINTER: the ground under the cursor
  stays under the cursor (pinned to 4 decimals in the assault),
  quarter-steps per notch, clamped 1..16; drag PANS keeping the
  grabbed ground under the hand; double-click snaps the whole world
  home. The projection quartet reads through a clamped view window
  - at zoom 1 the old whole-world formulas fall out unchanged, so
  every pre-zoom projection assault still passes untouched.
- The land, band highlight and city dots clip to the plot while
  zoomed; the band highlight width is computed through the window
  (no more fixed plot_w/24). Band PICKING stays true while zoomed -
  a zoomed click still names its 15-degree band (assaulted).
- Suite 192/192.

### Added (THE POPULATED PLANET - cities with data)
- SW_WORLD_CITIES: all 243 Natural Earth 110m populated places
  (public domain) generated into source by tools/gen_world_cities.py
  - name, country, lat/lon, peak population per city, biggest first.
  Record lines wrap ONLY at record boundaries (the coastline
  generator's lesson, applied from birth).
- SW_MAP.add_world_cities (floor): every city at or above the
  population floor becomes a marker whose label CARRIES the data -
  'Tokyo (183) Japan (183) 35.7M' - shown with lat/lon in the hover
  chip. cities_in_band (offset, max) answers the biggest cities of
  any UTC band; honest ocean bands answer empty.
- Demo: the timezone picker adopts the 84 two-million-plus cities;
  picking a band now lists its five biggest cities in the status
  bar beside the offset.
- Assaulted: 243 pinned, Tokyo/Japan/35,676,000 leads, every record
  on the planet; 38 five-million markers pinned, band-zero answers
  Paris first, mid-Pacific answers empty. Suite 190/190.

### Added (THE PRETTY MAP - real coastlines)
- SW_WORLD_GEOMETRY: Natural Earth 110m land polygons (public
  domain) GENERATED into data-only Eiffel source by
  tools/gen_world_geometry.py - 127 exterior rings, 4,964 points,
  parsed once, shared by every map. The generator wraps lines at
  spaces only (a mid-number wrap was the first red - caught by the
  replica parser before it ever reached a screen).
- SW_MAP draws the real planet: zero-allocation per frame via the
  new SW_PAINTER.polygon_fill_flat (reused screen buffer, 4,964
  points transformed through the same assaulted projection). The
  5-degree raster STAYS for is_land hit tests - two representations,
  each doing what it is best at. The timezone picker and world
  clock inherit the coastlines free.
- Assaulted at the pixel: Kansas wears the land colour, the
  mid-Atlantic wears the surface; ring/point counts pinned exactly
  (127 / 4,964 / biggest 1,298). Suite 188/188.

### Added (THE VERDICTS - the sweep closes)
- specs/S05-VERDICTS.md: the high-value targets answered for real -
  and the DEPENDENCY AUDIT EXECUTED: zero Gobo, zero ISE libraries
  beyond base/testing, DATE fully migrated to simple_datetime, file
  classes confined to three filesystem-facing widgets (simple_file
  adoption recorded as optional tightening). Individual verdicts:
  multi-window, dirty-rect, IME, UIA, shaping/bidi, JPEG, rich runs,
  submenus, multi-select, animation, gradients/shadows, eyedropper,
  alpha, tree-table, in-place editors, log/time scales, live-resize.
  The ~230 remaining S04 lines stay open as the living wishlist by
  decision. Sweep total: 90 of 339 closed with proofs, suites
  150 -> 186/186, simple_shell 1.0-1.2 born along the way.

### Added (DEEPENING SWEEP 5 - layout learns to bend)
- SW_ROW WRAP: with_wrapping reflows children into greedy lines; the
  wrap_starts math is a pure public feature assaulted with bare
  numbers (oversized children take their own line, empty in - empty
  out), and preferred_height answers wrapped truth before arrange
  proves it. Cross-axis options: center (the old law, default), top,
  stretch. Baseline stays open honestly (toy text API metrics).
- SW_SPLITTER horizontal: with_horizontal flips every geometry site
  (arrange, hit test, drag, divider paint, north-south cursor);
  double-click the divider and the ratio snaps home to 0.5.
- SW_TABS lazy pages: add_lazy_page builds on FIRST selection only -
  ten heavy tabs cost one page at startup (assaulted: adding is
  free, re-selection never rebuilds, built pages are adopted).
- SW_SEPARATOR make_vertical: the upright rule for rows.
- DRAWER GUTTERS ON ALL FOUR EDGES: Edge_top/Edge_bottom open (the
  precondition that refused them is gone), horizontal tabs along the
  top/bottom rails, Mode_top/Mode_bottom presentation, the root
  shrinks by every reserved gutter, show_drawer_edge for hosts.
  Assaulted with full headless renders on every edge.
- VERDICTS (by design, recorded in the docs): column scroll-area
  auto-adoption refused (no tree mutation mid-arrange - compose
  SW_SCROLL_AREA explicitly); the spacer's vanishing-at-zero-slack
  IS its contract.
- Suite 186/186.

### Fixed + Added (DEEPENING SWEEP 4 - data earns its keep)
- FIXED (failing test first): SW_DATA_GRID's descending sort REORDERED
  EQUAL KEYS - the insertion sort's blanket 'less := not less' swapped
  ties. Cured by a stable bottom-up MERGE SORT: strict comparison in
  both directions, O(n log n), 2000 rows assaulted (first/middle/last
  pinned). All seven pre-existing grid assaults still pass.
- SW_LIST keyboard navigation: arrows walk, PgUp/PgDn stride the
  viewport, Home/End jump, every move scrolls into view; lists join
  the Tab ring. SW_FILE_DIALOG's entry list inherits it, as S04
  predicted.
- SW_DATA_GRID: PgUp/PgDn/Home/End join its arrows (page_stride from
  the live viewport).
- simple_shell 1.2.0: VK_PRIOR/VK_NEXT cross the C key filter.
- SW_CALENDAR min/max date windows: outside cells draw muted and
  REFUSE clicks - proven layout-independently (a 42-cell click storm
  fires on_pick exactly once per allowed day). SW_DATE_PICKER hands
  its constraints to the hosted calendar at popover build.
- SW_FILE_DIALOG pattern sets: '*.png;*.jpg' (legacy single suffix
  still welcome); the matcher is public and assaulted.
- SW_COLOR_PICKER hex input: from_hex (#RGB, #RRGGBB) plus direct
  typing into the readout (Enter adopts, Escape abandons).
- SW_AVATAR photo faces: with_image clips any CAIRO_SURFACE to the
  disc via the NEW painter primitive push_circle_clip - pixel-
  assaulted (corner stays background, centre carries the photo).
- Suite 180/180.

### Added (DEEPENING SWEEP 3 - the drawn-glyph set)
- SW_PAINTER.glyph: 25 kinds drawn from primitives in the current
  colour (plus, minus, close, check, four chevrons, search, gear,
  trash, pencil, folder, document, refresh, play, pause, stop, dots,
  menu, info, warning, tray, offline, error). R7-pure - no font-glyph
  gambling; the assault draws EVERY kind and proves ink at the pixel.
- SW_BUTTON.with_glyph: icon+text faces, or a compact icon-only
  button when the label is empty.
- SW_TOOLBAR.add_icon_item: the icon is the face, the label demoted
  to its tooltip (the toolbar's destiny, S04's words).
- SW_SEGMENTED.with_icon_segment: icon segments over a NEW shared
  seg_w measure - layout, draw and click zones ask one feature, so
  the class's own zone-drift gotcha is now structurally impossible.
- SW_EMPTY_STATE.set_glyph_kind: the pictogram is choosable (search,
  error, offline...); the tray stays the default.
- Docs: pages for SW_SCREEN and SW_SCALE (previously undocumented),
  roadmap.html rewritten to the post-wave truth, architecture table
  reflects the simple_shell carve, glyph section on the painter page.
- Suite 172/172.

### Added (DEEPENING SWEEP 2 - the window learns manners)
- TAB FOCUS TRAVERSAL: SW_WIDGET.focusables collects the ring purely
  (enabled + accepts_focus, tree order); the window walks it on Tab,
  Shift+Tab reverses, both wrap; wants_tab lets the spreadsheet keep
  its commit-right Tab. Assaulted headlessly end to end.
- CURSOR SHAPING: widgets declare cursor_kind (I-beam over text
  surfaces, resize arrows over the splitter divider), applied on
  hover through simple_shell's new WM_SETCURSOR path (costs nothing
  until the pointer moves).
- POPOVER AUTO-CLOSE-ON-PICK: the calendar raises a one-shot close
  request after a day pick (opt-in - embedded calendars unaffected);
  the window honours it after the click settles. The date picker's
  popover now closes itself the way every date field should.
- DRAWER PEEK-CLOSE GRACE: an unpinned drawer survives one heartbeat
  with the pointer outside (about half a second) before closing;
  re-entry resets the clock. The law is a pure feature the assault
  drives directly.
- 20 stale per-control docs pages refreshed to match everything the
  two sweeps shipped.
- Suite 167/167.

### Changed (THE CARVE - simple_widgets is now pure Eiffel)
- ALL Win32 C moved to the new simple_shell library (Larry's descend-
  and-use directive): SW_WINDOW now inherits deferred SHELL_WINDOW and
  effects `dispatch'; SW_KEYS / SW_CLIPBOARD / SW_SPELLER are facades
  over SHELL_KEYS / SHELL_CLIPBOARD / SHELL_SPELLER. Clib/ is GONE -
  zero externals remain in this library. The queue-poll pump
  architecture crossed unchanged (the EIF_THREADS $-callback SEGV law).
- NEW SW_SCREEN: the carve's dividend - SHELL_DESKTOP's raw desktop
  grab married to cairo; a virtual-screen region arrives as a
  CAIRO_SURFACE (the pure-route EV_SCREEN, completed). Assaulted for
  real: 6x6 desktop pixels grabbed every suite run.
- SW_THEME.text_scale: one knob, every glyph obeys (painter font choke
  point) - proven by measuring real cairo advances at 1.0 vs 1.5.
- Suite 162/162 (screen grab + text scale join the battery).

### Added (DEEPENING SWEEP 1 - eighteen limits fallen, test-first)
- SW_TEXT_BOX UNDO/REDO - the docket's 'most-missed feature', landed
  test-FIRST (the failing VEEN is in the log): snapshot history with
  typing/deleting runs coalesced, blocks (paste, cut, drop) standing
  alone, Ctrl+Z/Y on the char path, programmatic set_text clearing
  history by editor law.
- SW_SELECT: per-option enabled flags + group separators (the menu
  always supported them; now the select surfaces them).
- SW_RADIO_GROUP: vertical orientation (drawn + clickable + measured)
  and per-option enablement.
- SW_CHIP: removable (with_remove draws the x, the zone answers,
  the agent fires - assaulted).
- SW_CHECK_BOX: tri-state (dash drawn; any click resolves to checked
  - assaulted; the tree cascade remains queued).
- SW_SWITCH: on/off captions in the track.
- SW_PROGRESS: indeterminate marquee (phase on the ambient repaint).
- SW_RATING: read-only mode, HALF-STAR display (clip-drawn), caption.
- SW_SKELETON: disc and rect shimmer variants.
- SW_BADGE: semantic kinds + hide-at-zero policy.
- SW_SEPARATOR: the labeled '--- OR ---' variant.
- SW_SLIDER: tick marks with optional snapping (snap math assaulted;
  applied in the drag path).
- SW_NUMBER_BOX: direct typing - digits build a buffer, Enter parses
  and CLAMPS (the box's law), Escape abandons - assaulted end to end.
- SW_SPACER: make_weighted.
- SW_KEYS: control_down / alt_down (physical, like shift).
- SW_CLIPBOARD: paste cap raised 128k -> 1M characters.
- SW_LOCALE: format_number - thousands grouping with the carried
  decimal mark, the grouping mark its opposite; US and European laws
  assaulted, negatives and zero-decimals included.
- 10 new assaults: suite 160/160.

### Added (WAVE 6 - media + conversational + DICTATION)
- SW_CAROUSEL (wrapping pages, dot jumps), SW_GALLERY (width-flow slot
  math), SW_MEDIA_TRANSPORT (codec-agnostic control: honest m:ss
  clocks that never wrap into lies, clamped seek), SW_CROP_BOX
  (normalized marquee from any drag direction) - all assaulted; the
  assault generates its own real PNG fixture through simple_cairo.
- SW_CHAT_THREAD: role bubbles (mine/theirs/system), word wrap,
  streaming append_to_last, and the sticky-tail law every chat client
  honours. SW_PROMPT_VIEW: submit round trip, begin/append/end token
  streaming, say_system - the demo wires an echo engine; the real
  mate is simple_narrate.
- SW_DICTATION - Larry's standing 'Do it', DONE: a speechkit-cluster
  SERVICE (the devkit packaging lesson - only targets wanting the
  dependency add it) riding simple_audio's recorder and simple_speech
  (whisper.cpp). Honest absence: a missing model leaves is_ready
  False and the demo's mic button greys itself through
  set_enabled_when. THE PROOF IS IN THE SUITE: every run loads
  ggml-base.en and transcribes a real sample wav into real words
  (honest skip on machines without the model). Runtime freight rule
  extended: whisper.dll + ggml*.dll beside the exe, like cairo.dll.
- Honestly future-gated, stated on the roadmap: playback codecs,
  PDF view (awaits the simple_pdf render bridge), smart textarea
  (awaits per-range styling).
- Demo: Media tab (self-generated swatch PNGs feed carousel, gallery
  and crop) and Chat tab (streamed echo replies + the live mic).
- 8 new assaults: suite 150/150.

### Added (WAVE 5 COMPLETE - enterprise composites, one sitting)
- SW_TREE_TABLE: the tree's flatten engine wearing grid columns - the
  promised convergence; header-offset row math assaulted.
- SW_CELLS_ENGINE (the 7GUIs brain graduated library-grade) +
  SW_SPREADSHEET: ranges in SUM/AVG/MIN/MAX/COUNT with per-member
  dependencies (filling an EMPTY cell inside a summed range
  propagates - assaulted), TSV blocks both ways, CSV with honest
  quoting, command undo that REPLAYS THROUGH COMMIT; the widget adds
  a formula bar, shift ranges, type-in-place, Ctrl+C/V/Z/Y via
  WM_CHAR codes. The aggregate law stated and assaulted: SUM/COUNT
  of nothing are 0, AVG/MIN/MAX of nothing are #ERR, any erroring
  member poisons the whole.
- SW_PIVOT: first-appearance keys, SUM/COUNT/AVG folds, row/col/grand
  totals - all assaulted.
- SW_KANBAN + SW_KANBAN_LANE: the board owns truth, lanes are pebble
  sources and drop holes; middle-click moves cards. Assaulted.
- SW_SCHEDULER: the week with GREEDY OVERLAP LANES (assaulted on the
  classic triple); locale day names; SW_SCALE minute axis.
- SW_GANTT: bars on the day ladder, elbow dependencies (contract-
  refused self-loops), today line; chained bars abut exactly.
- SW_FILE_MANAGER: lazy dir tree + virtualized file list over plain
  base DIRECTORY; engine assaulted against a real disk fixture.
- SW_QUERY_BUILDER: WHERE emission assaulted (bare numbers, doubled
  quotes, LIKE wildcards, AND/OR, skip-empty). Builds questions,
  never executes them.
- SW_FORM_GENERATOR: forms from specs; value_of / is_complete are a
  widget-free model surface, assaulted.
- SW_ORG_CHART: tidy layered layout; the parent-centres-over-span law
  proven; click select.
- SW_DOCK_HOST + SW_DOCK_ZONE - TRUE DOCKING: west/east/south reflow
  zones around a centre document; EMPTY ZONES COLLAPSE TO NOTHING
  (zone_rect/center_rect assaulted); panels move by pebble or
  move_panel; hit-testing routes through so docked widgets stay
  alive. The overlap law's promise, kept.
- Demo: three new tabs (Enterprise, Boards, Dock) wiring all eleven.
- 19 new assaults across the wave: suite 142/142.

### Added (Wave 4 coda - the timezone tools, Larry's idea kept)
- SW_TIMEZONE_PICKER: the pickable band map, pinned as an idea on day
  one of the locale work and built the day SW_MAP made it possible.
  IS the map (inheritance): click reads longitude, rounds to the
  15-degree band (offset_at assaulted: Greenwich 0, Denver -7, edges
  clamp +/-12), highlights it, captions it, fires on_change.
- SW_WORLD_CLOCK: realtime per-zone clocks - MINUTE offsets first
  class (+5:30 India, +5:45 Nepal), 'now' from
  SIMPLE_DATE_TIME.make_now_utc (the ecosystem owns time - zero new
  externals), rendering through the theme's SW_LOCALE (12/24-hour law
  follows culture), honest +1d/-1d chips across midnight. The
  heartbeat's ambient repaint IS the tick - no timers wired. zone_time
  and day_delta assaulted across midnight both directions. DST is
  deliberately NOT computed - offsets are the caller's law.
- Demo Space tab: the picker replaces the plain map (same markers,
  UTC-7 preselected, statusbar follows picks) and six cities tick
  live, Mumbai proving the half-hour.
- 2 new assaults: suite 125/125.

### Added (Wave 4, movement six - Space & structure; WAVE 4 COMPLETE)
- SW_MAP: a built-in coarse 72x36 equirectangular world (5-degree
  cells, authored from geography and QUIZZED by the assault: Denver
  land, mid-Atlantic sea, Sahara land, Australia land). Projection
  math public and round-trip assaulted; labelled markers with reach
  hover; lat/lon/land-or-sea readout everywhere else; and
  highlight_utc washes any UTC offset's 15-degree band - the timezone
  band-map grew into a world map exactly as the roadmap promised.
  Real coastline polygons are the stated future.
- SW_DIAGRAM: the dev mesh's force physics graduated PUBLIC and
  generic - add_node ids, contract-checked connect (no self-loops, no
  unknowns), deterministic golden-angle seeding, names beside every
  node, click-select firing on_select, drag/programmatic pinning.
  Assaulted: 60 relax steps keep every node in the box; a pinned node
  holds its ground to the decimal.
- Demo: the Space tab - four city markers on the world with UTC-7
  banded, and the ecosystem as a living graph.
- 3 new assaults: suite 123/123. WAVE 4: fifteen concepts, six
  movements, one day - every roadmap row SHIPPED.

### Added (Wave 4, movement five - Flows)
- SW_SANKEY: nodes in explicit columns (add_link requires rightward
  flow by contract), bar heights proportional to THROUGHPUT (the
  larger of inflow/outflow - imbalance shows as uncovered bar, which
  is the diagram telling the truth), and every link a cubic-bezier
  ribbon: SW_PAINTER gained ribbon_fill, curves arriving exactly
  where the roadmap said they would. Moorings stack contiguously down
  each bar - assaulted to exactness - and hover names a node's in/out.
- 3 new assaults (throughput-is-max-flow, in-column proportionality,
  contiguous moorings filling the bar): suite 120/120.

### Added (Wave 4, movement four - Densities)
- SW_HEATMAP: rows-by-columns heat on a channel-wise two-colour blend
  (surface to accent) - blend math public and assaulted at endpoints
  and midpoint; heat_of normalizes against the grid's own span, flat
  grids wash to the honest midpoint; row/col edge labels; hover chip
  names row/column/value; slot math is bar_at's idiom twice.
- SW_TREEMAP: deterministic slice-and-dice bisection (range splits at
  cumulative half, rect splits in proportion, axis alternates) with an
  EXACT assaulted property: every area fraction equals its value
  fraction to a millionth, tiles sum to the plot, item_at answers
  uniquely at every centre. Pie's eight-step palette; labels draw only
  when measured to fit. Squarified layout is the stated future.
- 4 new assaults: suite 117/117.

### Added (Wave 4, movement three - Indicators)
- SW_GAUGE: the 270-degree band gauge (wedge_fill with close radii IS
  a thick arc - the pie primitive earning double keep). Value band in
  its ZONE's semantic colour (set_zones: calm/warning/danger), value
  large in the centre, ends named. set_value CLAMPS - a gauge tells
  truth within its range. fraction/zone public and assaulted,
  degenerate spans never sweep.
- SW_SPARKLINE: the line chart's soul with no chrome - normalized to
  its own box, area wash, emphasized endpoint, rolling capacity, and
  an HONEST flat midline (0.5, never a division by nothing).
  fraction_of/span assaulted.
- The pairing promise kept: the demo seats the sparkline beside
  SW_STATISTIC, and gauge + spark + stat + line chart all drink ONE
  after_render_actions subscription - four live instruments, one bell.
- 4 new assaults: suite 113/113.

### Added (Wave 4, movement two - Proportions)
- SW_PIE_CHART: slices clockwise from twelve, make_donut with a TRUE
  ring (SW_PAINTER grew wedge_fill/wedge_stroke: arc out, arc_negative
  back - no overlay fakery), eight-step palette (semantics then
  washes), side legend with shares, angle-arithmetic hover (the atan2
  quadrant dance written out and assaulted: slice_at, percent_of,
  angle_of all public math). Empty pies say "no data yet".
- SW_FUNNEL_CHART: centred conversion trapezoids, alpha washed by
  strength, every band naming label/value/conversion-from-first;
  add_stage REQUIRES descending values - a widening funnel is a lie
  the compiler refuses. stage_at/conversion_of assaulted.
- Shared legend machinery: SW_CHART.draw_legend_row (dots + names,
  right-aligned); SW_LINE_CHART adopts it for multi-series plots.
- 3 new assaults (one of which corrected ITS OWN geometry: nine
  o'clock is 75% around - slice two, not three): suite 109/109.

### Added (WAVE 4 OPENS - charts)
- SW_SCALE: the shared axis engine - linear domain-to-range mapping,
  the inverse (hover asks values), the 1/2/5 tick ladder, nice-domain
  widening, honest degenerate behaviour (flat domains collapse to the
  range midpoint and offer their one tick). Pure math, assaulted
  headless on round trips, inverted ranges, negative spans.
- SW_CHART: the chassis - two scales re-anchored to the plot rect
  every draw, y-gridlines + ladder labels, clipped data layer, hover
  layer hook, theme-semantic series colours, human-width number
  formatting. SW_PAINTER grew polyline + polygon_fill (R2 holds: the
  painter grows what charts need).
- SW_LINE_CHART: multi-series, auto-fitted domains, with_area wash
  (covers the area chart), emphasized endpoints, rolling capacity for
  live feeds, crosshair hover snapped to the nearest sample. The demo
  streams EVERY FRAME'S RENDER COST into one via after_render_actions
  - Wave 4 drinking from the event layer on day one.
- SW_BAR_CHART: labelled categories, 0-to-nice-max domain, slot
  arithmetic (bar_at - assaulted), hover rings + value chips.
  Grouped multi-series bars are a stated future.
- SW_SCATTER_CHART: fitted-and-niced domains both axes, ringed dots,
  nearest-within-reach hover naming the pair.
- 8 new assaults (scale round trips/ladder/nice/degenerate, rolling
  capacity, auto domains, bar slots, scatter nearest): suite 106/106.

### Attempted and reverted (recorded so the next season knows)
- The modal-resize render callback (the WEL idiom: wndproc drives a
  frame per WM_SIZE through a registered frozen-routine pointer)
  rendered beautifully smooth and then SEGV-panicked under a resize
  storm: under -DEIF_THREADS, re-entering decorated Eiffel from a C
  callback without the runtime's reentry bracketing lets the GC move
  objects beneath the running frame. Reverted to the coalesced-queue
  path (stable through 23-step storms); the in_frame guard stays as
  permanent hygiene. Next season: WEL's own dispatcher glue is the
  sanctioned pattern - read cwel before round two.

### Added (the event layer)
- SW_EVENT [ARGS]: the agent collection behind every on_[event] -
  ISE's ACTION_SEQUENCE architecture, read from the installed 25.02
  source (base/ise/event) at Larry's direction and kept faithful:
  one ordered roll where KAMIKAZES fire in subscription order beside
  permanents and vanish before their bodies run; abort stops the
  current round (nested rounds stack-tracked); pause buffers event
  data, resume replays the backlog, block drops cold, flush discards.
  Rounds work a snapshot - mid-fire subscription is safe. Vocabulary
  double-salted: call/extend/extend_kamikaze/prune beside
  fire/subscribe/kamikaze/unsubscribe.
- The spine speaks: on_focus_change / on_hover_change /
  on_press_change / on_enabled_change on EVERY widget, lazily
  allocated, fired by the setters on CHANGE only. The sensitivity
  pass announces through the same queue (enabled_when verdicts fire
  on_enabled_change). SW_BUTTON.click_actions runs beside the legacy
  single agent. The GUI state machine now emerges by default -
  Larry's design, verbatim.
- Cairo-based queues (Larry): window.before_render_actions and
  after_render_actions - the latter delivers last_render_ms, so perf
  instruments subscribe instead of being wired in.
- Demo: a kamikaze in the wild - Click Me toasts on its FIRST click
  only. 7 new assaults (order, kamikaze, abort, pause/block/flush,
  change-only spine, sensitivity-through-queue, queue-beside-legacy):
  suite 98/98.

### Fixed (performance)
- Window-grow drags no longer crawl (Larry's sizing video, diagnosed
  frame by frame): the frame-echo PNG - a debug hook - was being
  compressed on EVERY heartbeat (~300ms per encode of the full
  surface), alternating with renders at roughly 1Hz. The echo is now
  QUIET-GATED: resizes stamp busy_ticks and the write waits two
  heartbeats of stillness. A resize storm to 1408px now logs zero
  frames over 100ms (new last_render_ms gauge; frames above 100ms
  self-report to sw_session.log - the perf pane's first instrument).
- Newly exposed resize pixels no longer flash BLACK: the window class
  carries a backdrop brush that follows theme.background (boot and
  set_theme), and DefWindowProc erases exposed regions with it.
  Steady-state repaints never erase (we blit whole frames), so no
  flicker cost.

### Added
- State control by agent collection (the Vision2 sensitivity idiom,
  Larry's call): SW_WIDGET.set_enabled_when installs a BOOLEAN function
  agent and applies it immediately; the window re-queries every
  installed condition after EVERY user interaction (refresh_enabling
  walks the sub_widgets spine across page and overlay). Menu-bar pads
  join via add_menu_when - greyed and deaf when their condition says
  False (menu ITEMS were already live: builders run fresh per open).
  The rule that demanded it: the Dev Studio entries are now enabled
  ONLY while dev mode is armed - the mesh is unreachable without the
  toggle. Demo's Danger button converted to the declarative form:
  set_enabled_when (agent danger_check.is_checked), zero manual
  toggling. 3 new assaults; suite 91/91.
- Larry's law: the instrument never inspects the instrument. One seam
  query - DEV_LENS.observes - exempts the mesh, the studio and every
  inspector column (parent-chain walk) from hover chips, right-click
  reveals AND dev-mode middle-click picking. Contract-tested.
- Dock-aimed reveals: with a docked studio pinned, right-clicking a
  live-page control no longer goes dark - the lens aims the dock's own
  pane (studio.aim_at: subject lands, its mesh node lights when the
  graph holds it) instead of opening a popover that would replace the
  drawer. SW_MESH.select_widget joins the public surface.
- Pick-and-drop re-rooting (Larry's cycle): with dev mode on,
  middle-click lifts ANY control as its own pebble; drop it on the
  mesh and the graph rebuilds around it (re_root: new crown, depths
  re-zeroed, on_select announces so the pane follows). Works across
  the dock boundary - pick from the live page, drop into the drawer.
- SW_DEV_STUDIO (devkit): the dev instrument grown from Larry's four
  questions — force-mesh left, living reveal right. Click a node and
  the pane rebuilds with the FULL reflected dossier (make_full, no
  field cap) in a growing scroll area; text-bearing subjects (labels,
  text boxes) offer a live edit that drives their PUBLIC set_text with
  every contract armed. Public tooling surface (pane_line_count /
  edit_text / set_edit_text / apply_edit) so tests and future scripts
  drive the same path a human does. 13 new assaults; suite now 88/88.
- SW_MESH (devkit): the widget tree as live physics (repulsion,
  springs, centre gravity on the heartbeat — the Diagram Tool's
  family). Depth-limited harvest (Larry counted 109 nodes and called
  for mercy; the skeleton reads at 3) with plus-badged frontier nodes
  that expand in place. The root wears the crown (accent, larger,
  double-ringed). Colour grammar: FILL encodes kind (containers quiet,
  interactive accent-washed, passive barely-there), RING encodes state
  (accent selected, ink hovered, warning pinned, danger disabled).
  "names" chip + context-menu item toggle all-node class labels.
  Right-click node menu: Reveal in pane / Expand children / Release
  pin / names toggle.
- THE DOCK: "Dev Studio — docked right (page stays live)". A pinned
  right drawer hosting the studio while the page underneath stays
  fully interactive — clicks, wheel, hover, drops and pebbles outside
  the panel route to the live page (new target_at routing). Larry
  named the shape: EiffelStudio's debugger pane, not a modal.
- Mesh from selection: the dev-mode reveal popover now ends in a
  "Mesh this subtree" button — the studio opens rooted at the control
  you right-clicked, not the whole window.
- Centered-sheet chrome, window-owned so every modal gains it: a
  header band with grip dots (drag to move), a corner stair-grip
  (drag to resize, clamped 280x200 minimum), a danger-red close pearl
  straddling the top-right corner, and push_clip/pop_clip around all
  sheet content so nothing bleeds past the panel again.
- DEV_FLAGS release gate, the real one: a `devkit` ECF override
  cluster swaps DEV_FLAGS (False -> True) and DEV_LENS (no-op ->
  armed), and SW_INSPECTOR / SW_MESH / SW_DEV_STUDIO exist ONLY in
  devkit — release-shaped targets never compile them. Binary-measured:
  the sw_7guis exe contains 0 occurrences of any devkit class name in
  ascii/utf-16/utf-32. (Supersedes the v1 `debug ("dev_mode")` claim:
  finalization strips debug-clause bodies regardless of ECF keys —
  recorded as oracle law.)
- SW_LABEL with_wrap adopted across the dossiers (parent chains, notes,
  field lines) — long truths wrap instead of truncating.

### Fixed
- Double-clicks now harvest pending popovers too (bubble_click gated
  them behind single-click; the mesh's double-click reveal exposed it).
- The "body scroll gets stuck" report resolved as bench geometry, not
  a toolkit bug: the drawer gutter (22px) shifts every layout-derived
  coordinate, so the synthetic clicks were aiming beside the scrollbar
  lane. One correctly-aimed click scrolled ~700px.
- SW_INSPECTOR v1 - WAVE 3 COMPLETE. The dev lens: arm via the Dev
  menu; hovering outlines any widget with a class+size chip;
  right-click opens the REVEAL popover - class/geometry headline,
  layout hints, state flags, full parent chain, dev_note, and the
  REFLECTOR attribute dump (label, wired agents, protocol slots,
  live values). dev_note/with_dev_note joined the widget spine.
  DISCOVERY (oracle law): finalization strips debug-clauses no
  matter the ECF key - the release-absence gate will ride a
  cluster-swapped DEV_FLAGS constant + dead-code removal (S04);
  v1 ships the runtime gate. 75/75 assaults.
- SW_DROPZONE + the file-drop protocol: the pump accepts shell drags
  (DragAcceptFiles) and answers WM_DROPFILES by buffering wide paths
  (clipboard pull pattern) and pushing event 18 with the drop point;
  the window surrogate-parses, splits, and walks the spine to the
  first widget whose accepts_files welcomes - receive_files is the
  pebble protocol's file-shaped sibling, open to ANY widget. Proven
  by a forged HDROP through the full chain AND Larry's real Explorer
  drag. 74/74 assaults. (No drag-over tracking - that is OLE DnD,
  an S04 future.)
- SW_TREE [G]: hierarchy over host nodes via agents (roots/children/
  label); children called LAZILY (probe counting is test-pinned:
  grandchildren of collapsed nodes are never touched); expansion and
  selection tracked by OBJECT IDENTITY (fold the selection's subtree,
  reopen - same object); virtualized rows, arrows navigate, left/right
  fold. The inspector's future tree panel is this class over
  SW_WIDGET.
- SW_COLOR_PICKER: hue-banded SV field + spectrum bar + swatch + hex;
  HSV model (invariant-clamped), RGB border; conversions assault-
  pinned on the corner colours. Proven live by a gloriously mis-aimed
  click (#0C2766 delivered through the agent to the footer) and by
  Larry's magenta session (#5D4257).
- Keyword casualty REPEAT: an attribute named 'expanded' (tally #4)
  slipped in and the compiler refused it in seconds - the tally
  protects, the gate enforces. Renamed open_nodes.
- Suite at 73/73 (tree + colour set). Demo cluster joined the tests
  target (DEMO_NODE fixtures).
- Culture batch (Larry's regional-controls notice): SW_LOCALE (date
  order/separator, names, week start, 12/24h clock, decimal mark; US
  default by decree, make_iso/make_european ship) carried on SW_THEME
  and overridable PER CONTROL. simple_datetime adopted (ecosystem-
  first rule) for all date arithmetic
- SW_CALENDAR (today ringed, pick filled, week opens on the locale's
  first day - first-cell math assault-pinned both cultures),
  SW_DATE_PICKER (locale-ordered parse, invalid tint, calendar in a
  popover via the new pending-popover widget handshake),
  SW_TIME_PICKER (12/24h; generous in, exact out; 12 AM trap pinned)
- Pending-popover handshake on SW_WIDGET + window presentation - the
  pending-menu handshake's sibling for anchored widget panels
- Suite at 67/67 (locale/calendar set added). Proofs: US picker parsed
  12/25/2026 -> (2026,12,25) agent-delivered; Larry drove the full
  glyph->calendar->pick->write-back chain live
- SW_DATA_GRID [G] + SW_GRID_COLUMN [G] - the Wave 3 crown: typed rows,
  first-class columns (value + optional COMPARABLE key agents: numbers
  sort as numbers), header-click sort asc/desc/clear with drawn
  triangle, drag-divider resize (invariant-clamped), host filter
  predicate, virtualized zebra rows under a frozen header, both-axis
  wheel. Selection follows the ROW OBJECT across re-sorts; filtered-out
  selections clear honestly. Seven assaults; suite at 59/59
- 7GUIs (Eugen Kiss's benchmark) implemented spec-exact as target
  sw_7guis: Counter, Temperature, Flight Booker, Timer, CRUD, Circle
  Drawer, Cells - every behaviour synthetically proven. Forced four
  toolkit features: SW_TEXT_BOX.set_invalid (danger tint),
  window.set_on_tick (250ms application clock; heartbeat now 250ms,
  toast life rescaled), SW_CANVAS (delegate-drawn surface), SW_SHEET
  (grid organ: frozen headers, two-axis scroll, in-place editing,
  formulas outside via agents). Domain engines CELLS_ENGINE (formula
  parse + propagation + STRUCTURAL cycle detection - the recursive
  guard alone was fooled by the value cache; an assault test caught
  it) and CIRCLES_MODEL (snapshot undo/redo) live in demo7guis
- SW_TEXT_BOX clear X (Larry's note): opt-in with_clear_button;
  on_clear_request agent lets the host confirm before clearing;
  masked boxes keep the eye instead. clear_text fires on_change
- Assault suite at 52/52 (7GUIs engine set added)
- Disclosure batch: SW_ACCORDION (exclusive law by postcondition),
  SW_STEPPER (only done ground is clickable), SW_TIMELINE (semantic
  dots, row math pinned by test), SW_DRAWER furniture
- Overlay engine unified: sheets (centered modal), DRAWERS (edge,
  dismissable) and POPOVERS (anchored, light) are one mechanism with
  four presentations; outside-click closes the dismissable kinds;
  popups still open above them all
- Drawer PUSHPIN: filled while pinned, hollow while peeking; click
  toggles auto-hide (unpin exempt from implicit pinning). Overlap law
  stated: one overlay at a time; dual pinned drawers await true docking
  (Wave 5). Fixed: menu-opened drawers no longer inherit stale peek
  state (present defaults to stay-put)
- Drawer TABS with peek and pin (Larry's design): edge tabs in reserved
  GUTTERS outside content and scrollbars; hover peeks, click pins,
  interacting with a peek pins implicitly; tiny drawn drawer icon per
  tab; builder agents keep content fresh per open; add_drawer_tab
  accepts all four edges (left/right live, top/bottom with S04)
- Indicator septet: SW_BADGE (99+ cap), SW_AVATAR (hash-stable hues,
  derived initials), SW_SEGMENTED (first chosen at birth), SW_RATING
  (star primitives; click again clears), SW_SKELETON (heartbeat
  shimmer), SW_EMPTY_STATE (tray glyph + one action), SW_STATISTIC
  (semantic delta)
- SW_PAINTER.star_fill / star_stroke (computed vertices, path hygiene)
- Heartbeat repaints unconditionally: the ambient animation clock
- App-shell demo: pinned chrome, body in a growing two-axis
  SW_SCROLL_AREA (programmable wheel step, default 96 px/notch;
  horizontal bar + Shift+wheel when content announces wide)
- Wheel coalescing in the pump: fast spins are one scroll + one render
- Assault suite at 44/44 (indicator + disclosure sets added)
- Docs: pages for all new controls, SW_INSPECTOR PLANNED page,
  specs/S04-ROADMAP.md harvested from the page sources

### Fixed
- Keyword casualty #5: `some` (across...some quantifier)
- CHANGELOG is now append-only history - the docs generator no longer
  regenerates it (it silently discarded Unreleased entries once)

## [0.2.0] - 2026-08-22 — Wave 2 complete

### Added
- SW_COMBO — editable dropdown inheriting the full SW_TEXT_BOX engine;
  chevron menu via the pending-menu handshake
- SW_TEXT_BOX password mode — `make_password`: bullets in draw AND layout,
  spell-check bypass, clipboard copy/cut denial, muted menu items, reveal eye
  (`toggle_reveal`, a view change only — denials hold while revealed)
- SW_TOOLBAR — plain tools, latching toggles queried by label, gaps,
  per-item hints as tooltips
- SW_IMAGE — PNG via cairo, contain-scaled and centered, honest placeholder;
  SW_PAINTER.draw_image under the R2 monopoly
- SW_SPACER — stretchy nothing born growing; the pinned-footer idiom
- SW_MENU_BAR, SW_STATUS_BAR, SW_GROUP, SW_SEPARATOR — the chrome batch
- Window **sheet layer** — `show_sheet` hosts any widget tree modally over a
  dimmed backdrop; popups still open above; Escape dismisses
- SW_FILE_DIALOG — drawn open/save: dirs-first sorted listing, '..' on top,
  extension filter, name box, verbs; base PATH/DIRECTORY only; public
  inspection API (entry_count / entry_name / is_entry_directory / open_entry)
- SW_LIST — selection wash + on_select, double-click activation
  (on_activate), per-row pick-and-drop via the new position-aware
  SW_WIDGET.pebble_at protocol
- SW_PAINTER.circle_stroke / circle_fill — path hygiene primitives
- **simple_widgets_tests** — contract-assault target: 4 sets, 25 tests,
  headless painter fixture over an offscreen cairo surface; 25/25 across
  five consecutive runs
- Documentation: per-control pages for all 36 classes (description,
  examples, limits, gotchas, future), core docs page, this changelog

### Fixed
- Global heartbeat: tick and resize are handled before phase dispatch — an
  open popup no longer freezes toasts, the frame echo, or surface
  reallocation
- `set_text` re-establishes every invariant of the new text (stale disjoint
  selection ranges into shorter text violated `extras_well_formed`)
- `scroll_to_row` before layout degrades honestly instead of dying on its
  own postcondition (found in live fire by the file dialog)
- `row_at` no longer aliases points above the list to row 1 (truncation
  rounds toward zero); postcondition `nothing_above_the_top` pins the rule
- SW_CLIPBOARD retries OpenClipboard races in both directions (clipboard
  history managers grab the clipboard after every change)
- Radio circles: cairo `arc` joins from the current point — the
  dash-through-the-circles bug; radios and slider knobs now use the painter
  circle primitives
- SW_RADIO_GROUP auto-selects its first option (a radio group always has
  exactly one choice)

## [0.1.0] - 2026-08-21 — Wave 1

### Added
- Foundations: SW_WINDOW (Win32 + cairo runtime, phased pump: dialog /
  popup / pick / plain; toasts; drawn dialogs; pick-and-drop; live theme
  swap; frame echo), SW_WIDGET (bounds, grow/min/max, hover/pressed/focused,
  pending-menu and context-menu protocols, pebbles), SW_THEME (dark + light,
  WCAG invariants), SW_PAINTER (colour, three type roles, text + advance,
  rects, lines, clip)
- Controls: SW_BUTTON (4 kinds), SW_LABEL (3 roles, body wraps), SW_TEXT_BOX
  (caret, disjoint multi-select with invert, full keyboard map, clipboard,
  ISpellChecker underlines with one-click suggestions, string pebble hole),
  SW_SELECT, SW_CHECK_BOX, SW_SWITCH, SW_RADIO_GROUP, SW_SLIDER,
  SW_NUMBER_BOX, SW_PROGRESS, SW_CHIP
- Layout: SW_ROW / SW_COLUMN (Vision2 containership unified with flex),
  SW_CARD, SW_SPLITTER (contract-clamped ratio, hover affordance)
- Data: SW_LIST (virtualized 10k rows), SW_SCROLL_AREA, SW_TABS
- Chrome: SW_MENU (drawn popups, built fresh per open)
- Services: SW_CLIPBOARD (Unicode, surrogate pairing), SW_KEYS, SW_SPELLER
- Specs: S01 layers & rules R1–R8, S02 full-coverage catalog (waves 1–6),
  S03 appearance model; research surveys R01 (WEL/Vision2 inventory),
  R02 (232 web concepts), R03 (CPU-only AI models)
