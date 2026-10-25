# simple_widgets

[Documentation](https://simple-eiffel.github.io/simple_widgets/) •
[GitHub](https://github.com/simple-eiffel/simple_widgets) •
[Issues](https://github.com/simple-eiffel/simple_widgets/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)
![Tests](https://img.shields.io/badge/tests-440%2F441-brightgreen.svg)

A drawn widget toolkit for Eiffel on pure Win32 — no Vision2, no GTK, no native
controls. Every pixel is the toolkit's own.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**0.9.0 - 0.34.1: the simple_bible gap program** (tracker in simple_bible,
`.eiffel-workflow/gui/02-GAP-PROGRAM.md`). Every item is tested headless, and
every text item is gated on Hebrew and Greek in both the light and the dark
theme, with evidence PNGs in `evidence/`.

| Version | Gap | What |
|---|---|---|
| 0.9.0 | GW-28 | Theme tokens for filled controls, status inks and dark mode, held by invariants |
| 0.10.0 | GW-04 | Every widget's text goes through the shaped path, in the theme's faces, bold and italic |
| 0.11.0 | GW-02 | Hebrew flush right; a paragraph's gutter on the reading side |
| 0.12.0 | GW-03 | `SW_SHAPING.set_script_face` / `set_small_script_face`: pointed Hebrew and polytonic Greek verified in the shipped faces |
| 0.13.0 | GW-27 | The window follows the Windows light/dark setting (`follow_system_theme`), dark caption |
| 0.14.0 | GW-24 | Function keys and Ctrl+digit accelerators; a key-down accelerator no longer eats the next keystroke |
| 0.15.0 | GW-26 | `SW_WINDOW.set_on_wake`: a worker processor's wake reaches the app at once, even under a dialog |
| 0.16.0 | GW-11 | Status-bar sections: text, clickable text, hosted progress bar and Cancel button |
| 0.17.0 | GW-08 | `SW_PARAGRAPH_LIST.character_at` / `text_boxes`; `on_hover`, `on_dwell` (400 ms, window-timed), `on_scroll`; raised Strong's numbers and small-caps LORD through `set_styles` |
| 0.18.0 | GW-09 | The hover card: `SW_WINDOW.show_hover_card`, non-modal, anchored at a word, open while hovered; `SW_WIDGET.hover_card_at`; `SW_PARAGRAPH_LIST.set_hover_card_builder` and `word_at` |
| 0.19.0 | GW-05 | The dock: tabbed zones, draggable zone edges and `set_fraction`, hide/show/remove panels by key, `layout_snapshot` / `restore_layout`; spacing from the theme tokens |
| 0.20.0 | - | Shared view parts: `SW_VSCROLLBAR` for every scrolling widget, the deferred ancestors `SW_TEXT_POINTING`, `SW_VSCROLLING` and `SW_TEXT_SELECTION`, `SW_BLOCK_STACK`, `SW_WORD_BOUNDARY`; theme tokens `scrollbar_width` and `min_thumb` |
| 0.21.0 | GW-13 | The rich document view (reading): `SW_DOCUMENT_VIEW` over an `SW_DOCUMENT` of `SW_DOC_BLOCK`s and `SW_RICH_TEXT`; headings, lists, quotes, rules and tables; links with `on_link_click` and `on_link_hover`; selection across blocks and cells; Hebrew and Greek gated |
| 0.22.0 | GW-13 | Live-preview editing, GW-13 complete: `SW_DOCUMENT_VIEW.set_codec`, `SW_DOCUMENT_CODEC` and `SW_MARKDOWN_CODEC`, the `SW_IN_PLACE_EDITING` mixin, the model moved to simple_document (`SIMPLE_DOCUMENT`, `DOC_BLOCK`, `DOC_TEXT`), `SW_DOC_STYLES`, code blocks, inline code and strikethrough, `SW_KEYS.simulate` for tests; `SW_SPELLER` skips Hebrew and Greek |
| 0.23.0 | - | The first post-merge abstraction scan's high findings: the fifth deferred ancestor `SW_STACKED_ITEMS`, editor hosting and one end of an edit in `SW_IN_PLACE_EDITING`, pointing in one place, one layout step (`SW_TEXT_GEOMETRY.lay_out`), and the paragraph list's spacing scales with the text |
| 0.24.0 | GW-06 | Parallel text: `SW_PARALLEL_TEXT` (verse rows by version columns); the composed bases `SW_STACKED_POINTING` and `SW_DOC_UNITS` lifted from the document view, and the parentless mixin `SW_MARK_HOST` |
| 0.25.0 | GW-07 | Interlinear: `SW_INTERLINEAR` (stacked word cells, right to left for Hebrew); the third post-merge scan's fixes, and `SW_DOC_UNITS` owns its heirs' input |
| 0.26.0 | GW-10 | Grouped bars: `SW_BAR_CHART.set_series`, `add_group`, `series_at`, `set_emphasized_series`; the fourth scan's fixes |
| 0.27.0 | GW-12 | The query builder clause tree: `SW_QUERY_NODE` with heirs `SW_QUERY_GROUP`, `SW_QUERY_CONDITION` and `SW_QUERY_PROXIMITY`, typed value pickers; the fifth scan's fixes (`SW_CHART.draw_chip`, a chassis-drawn legend, eight series colors) |
| 0.28.0 | GW-29 | 100,000 shaped rows at 60 Hz: `SW_SHAPING.layout_styled` remembers layouts (`forget_layouts`), `SW_GRID_COLUMN.sort_key`; measured numbers below |
| 0.28.1 | - | The sixth scan's fixes: editing a proximity's distance is heard, and a long distance renders |
| 0.34.1 | - | The thirteenth scan: screen readers are served once the window opens and on request, with stable ids; dialogs, sheets and menus are reachable; closed and hidden parts are left out |
| 0.34.0 | GW-18 | SW_PAINTER dashed, dotted and dash-dot strokes; six hatch fills for rectangles, rounded boxes and polygons; gradients and fades |
| 0.33.0 | GW-14 | Screen readers: every widget gives a UI Automation role, name and value; SW_WINDOW publishes the tree, tells the focus and obeys focus requests (simple_shell 1.22.0) |
| 0.32.1 | - | The twelfth scan: the animation setting survives a light/dark flip; SW_DIAGRAM holds still when motion is reduced |
| 0.32.0 | GW-14 (half) | Reduced motion: `SW_THEME.reduces_motion`, followed live from Windows' animation setting; the skeleton and the progress band hold still (simple_shell 1.21.0) |
| 0.31.1 | - | The eleventh scan: exports free their memory (40 exports leaked 440 megabytes); grid and dock hover never export; opaque fractional edges; `can_export` |
| 0.31.0 | GW-21 | `SW_WINDOW.widget_image`, `export_widget_png`, `copy_widget_image`: one widget to PNG or the clipboard at a scale, light by default, no hover, a margin so overhanging marks stay in |
| 0.30.1 | - | The tenth scan: in a contrast theme selected rows, pressed buttons, hover and disabled text all show and read; a theme swap reaches the shaping kit |
| 0.30.0 | GW-16 | Follow Windows high contrast: `SW_THEME.make_high_contrast` from the system colors (mended, always readable), worn by a window following Windows, live (simple_shell 1.20.0) |
| 0.29.1 | - | The ninth scan: a narrow bar and a zero-inset theme still show tabs; a close handler may adopt the page; no stale tab box after moving across hidden tabs |
| 0.29.0 | GW-15 | `SW_TABS`: closable tabs (close guard, pinned tabs), drag to reorder, overflow chevron menu, keys for Ctrl+Tab and Ctrl+W; tab geometry shared with the dock through `SW_TAB_STRIP` |
| 0.28.2 | - | The seventh scan: the layout memo follows `facade.policy_revision`; labels and menus shape like the painter; `SW_DATA_GRID.add_row` places one row; per-column alignment; GW-29 timing runs inside `without_contracts` |

✅ **ALL SIX WAVES SHIPPED, plus the Studio widgets (0.8.2)** — 114 classes (108 library + 5 devkit + 1 speechkit)
- 0.8.2: `SW_TEXT_BOX` measures the same whatever was drawn last
  (`minimum_height`), and `row_height` is the pitch its shaped lines are
  really stacked at, blank lines included (`SW_SHAPING.line_height`)
- 0.8.1: `SW_LABEL` joins the shaped path — a Hebrew label reads right-to-left
  and an emoji label is a picture whenever the window has shaped text on;
  `mono` labels keep cairo's toy path so machine values keep their monospace
- 0.8.0: HIGHLIGHTS — the data behind the text: `SW_MARKED_TEXT` spans with
  reasons that follow every edit, `SW_MARK_LEGEND` for meaning (looks, labels,
  badges), `SW_MARK_PALETTE` held readable by contract on both themes,
  `SW_MARK_PAINTER` with a size floor, `SW_MARK_LEGEND_VIEW`, and
  `SW_TEXT_GEOMETRY` lifted out of the text box
- 0.8.0: `SW_TEXT_BOX` edits SHAPED text (a caret that walks leftward through
  Hebrew, hit-tested by cluster), `SW_PARAGRAPH_LIST` (variable-height
  paragraphs, selection set, edit in place), `SW_WAVEFORM` (envelope,
  playhead, markers, seek), and `SW_CLUSTER_MATH` written once for all three
- Wave 5 (all 11 composites): tree table, spreadsheet doctrine whole,
  pivot, kanban, scheduler, gantt, file manager, query builder, form
  generator, org chart, TRUE DOCKING with collapsing reflow zones
- Wave 4 (all 15 concepts): SW_SCALE axis engine, line/bar/area/scatter,
  pie/donut + funnel + legend, gauge + sparkline, heatmap + treemap, sankey,
  world map (markers + UTC bands), force diagram, and the timezone tools
  (pickable band map + live world clock); the demo streams live
  frame costs into four instruments off one render-bell subscription
- 505 contract-assault tests passing at 0.34.1 (`screen_grab_marries_cairo` reads the
  real desktop and fails while it is unreadable, such as a locked session or a sleeping
  display — environment, not code)
- Dev instrument: SW_DEV_STUDIO — force-mesh + live reflected dossier +
  contract-armed live editing, floating or DOCKED (page stays live);
  compiled out of release-shaped builds via the devkit override
  (binary-measured absence)
- Every widget frame-proven in the live showroom (`demo/sw_demo.e`)
- Windows-only today (the SURFACE layer is Win32); everything above it is portable by design

## The idea

The classic Eiffel GUI chain was **WEL** (raw Win32) → **Vision2** (portable
widgets) → your application. The simple chain is:

```
simple_shell      the platform    (native window, pump, clipboard, keys)
simple_cairo      the substrate   (canvas, text, PNG)
simple_widgets    the vocabulary  (window runtime, theme, painter, 59 controls)
your application  the intent      (what exists and what happens)
```

Besides simple_shell and simple_cairo, the document view depends on
[simple_document](https://github.com/simple-eiffel/simple_document) (the document
model) and [simple_markdown](https://github.com/simple-eiffel/simple_markdown)
(the Markdown reader and writer behind `SW_MARKDOWN_CODEC`).

simple_widgets itself is **pure Eiffel — zero C**: every Win32 external
lives in [simple_shell](https://github.com/simple-eiffel/simple_shell)
(deferred `SHELL_WINDOW`, effected here), every pixel in simple_cairo.

Before this library, a production face over simple_cairo meant ~2,000 lines of
boilerplate per application. That boilerplate is now a toolkit — with contracts.

## What ships today

**Foundations** — SW_WINDOW (runtime: one window, one cairo surface, phased
event pump, toasts, drawn dialogs, modal sheets, pick-and-drop), SW_WIDGET
(the contract spine), SW_THEME (tokens + metrics with WCAG invariants on its
own palette; dark and light), SW_PAINTER (the only class that touches cairo).

**Controls** — button (4 kinds), label (3 roles, honest wrapping), text box
(full engine: caret, disjoint multi-select, clipboard, Windows spell-check
with one-click suggestions, password mode with reveal eye and clipboard
denial, and since 0.8.0 a SHAPED path — bidi caret and cluster hit-testing
through the window's shaping kit — and HIGHLIGHTS: spans with reasons that
follow every edit, painted through a legend), combo (an editable dropdown that IS a text box), select, check box,
switch, radio group, slider, number box, progress, chips.

**Layout** — row/column containership unifying Vision2's model with flex
(grow / min / max), card, titled group, separator, spacer (the pinned-footer
idiom), splitter (contract-clamped ratio).

**Data & chrome** — virtualized list (10,000 rows scroll like ten; selection,
double-click activation, per-row pick-and-drop pebbles), paragraph list
(variable-height shaped paragraphs, host-drawn gutter and bands, a selection
set with an anchor, one paragraph editable in place), scroll area, tabs,
drawn menus (built fresh on every open), menu bar (builder agents), toolbar
(toggles queried by label), status bar.

**Dialogs & media** — drawn modal alerts, a complete drawn **file dialog**
(open/save, dirs-first listing, extension filter — base PATH/DIRECTORY only),
PNG display with contain scaling; a waveform (envelope from a sampler agent,
playhead, markers, seek); a shell-drop zone (WM_DROPFILES
through the widget spine to any opted-in control).

**Document view (0.22.0)** — `SW_DOCUMENT_VIEW` reads and edits a rich
document: commentaries, lexicon entries, dictionary articles and library
documents. The model lives in simple_document: `SIMPLE_DOCUMENT`, an ordered
list of `DOC_BLOCK`s (paragraphs, headings of three levels, bulleted and
numbered items, block quotes, code blocks, rules and tables), each text a
`DOC_TEXT` with inline bold, italic, small capitals, superscript, inline code,
strikethrough and links that carry a target. (`SW_DOCUMENT`, `SW_DOC_BLOCK` and
`SW_RICH_TEXT` no longer exist.) `SW_DOC_STYLES` flattens a `DOC_TEXT` for the
shaper. The model knows no markup; a codec turns it into source and back. The
view draws links in the theme's `ink_accent`, calls `on_link_click (target)`
when one is followed, reports `on_link_hover`, selects across blocks and table
cells, and copies with Ctrl+C. A Hebrew paragraph sits flush right.

Give the view a codec with `set_codec` (usually `SW_MARKDOWN_CODEC`) and it
edits with live preview. Click a block and a box opens over it holding the
block's Markdown; every other block stays formatted. Click elsewhere to keep
the edit. Escape drops it. Ctrl+Enter keeps it and opens a new paragraph.
Ctrl+click follows a link. The document changes only when an edit is kept.

**Parallel text (0.24.0)** — `SW_PARALLEL_TEXT` shows versions side by side,
verse by verse. Rows are canonical verses and columns are versions (up to
six, each with a weight, a text scale and an alignment). Each cell is a
`DOC_TEXT`, wrapped and shaped in its own direction, so a Hebrew column sits
flush right. A row is as tall as its tallest cell. There is one scroll, and
the column titles stay put while the rows scroll. A note row ("LXX 9 = MT
9-10") spans every column in muted text. Each cell has its own marks, painted
through a legend ("agrees with LXX"). `cell_at` and `on_cell_click` answer
which cell the pointer is on, and `scroll_to_row` brings a verse into view.
Selecting copies a row's cells separated by tabs and the rows one per line.
Spacing comes from the theme tokens.

**Interlinear (0.25.0)** — `SW_INTERLINEAR` shows a text as stacked word
cells: the surface word, transliteration (italic), pronunciation, gloss,
lemma, Strong's number and morphology in English. Cells flow and wrap, right
to left for Hebrew and left to right for Greek. `set_line_visible` hides any
line except the surface word. A word that opens a verse carries its label on
the reading-start side. A click, Left and Right (in reading order, mirrored
right to left), Home and End select a word (`on_token_select`); `token_at`
names the word under a point; Ctrl+C copies a word's lines; a rest on a word
opens the card that `set_hover_card_builder` builds. It inherits
`SW_DOC_UNITS` alone, so only the flow, the word selection and the keys are
new. A click ends a text selection, and Ctrl+C copies that selection when
there is one.

![Interlinear, Genesis 1:1, light theme](evidence/gw07_interlinear_light.png)
![Interlinear, Genesis 1:1, dark theme](evidence/gw07_interlinear_dark.png)

**Grouped bars (0.26.0)** — `SW_BAR_CHART.set_series` names the series and
`add_group (label, values)` adds a category with one value for each series;
`add_bar` still makes a single-series chart. A group's bars stand side by side
a quarter of the theme's padding apart, and with several series a legend names
them. `series_at` says which bar is under a point, and the hover chip names its
series and value. `set_emphasized_series` draws the other series in the theme's
pale ink so the target stands out by lightness as well as hue. Values must not
be negative, and `set_series` clears the emphasis.

![Grouped bars, light theme](evidence/gw10_controls_light.png)
![Grouped bars, dark theme](evidence/gw10_controls_dark.png)
![A crowded chart stays inside its frame](evidence/gw10_crowded_light.png)

**Charts share a chassis (0.27.0)** — `SW_CHART.draw_chip` (with
`draw_chip_beside`, `draw_chip_above` and `draw_chip_corner`) is the one hover
chip for the bar, line, scatter, pie and heat map charts. It uses the theme's
chip size and padding and stays inside the frame. The chassis draws the legend
from `legend_names`, keeps it clear of the title, and ends it in "+n" when the
names do not fit. `series_color` gives eight distinct colors before it cycles.

**Query builder (0.27.0)** — `SW_QUERY_BUILDER` builds a clause tree. The
deferred `SW_QUERY_NODE` has three heirs: `SW_QUERY_GROUP` (children joined
ALL or ANY, nested to any depth), `SW_QUERY_CONDITION` (field, operator,
value) and `SW_QUERY_PROXIMITY` (two words within n words of each other,
`NEAR/n` in either order or `BEFORE/n` in order). Any node can be negated. The
engine reads `root`. `expression` is the question as a reader reads it, and
`query_text` is an SQL-shaped rendering for display only, never executed.
Incomplete nodes are left out of both. `set_field_choices` gives a field a
picker of codes, and `set_field_suggester` makes a field a lemma whose picker
follows the typing; a text or number field keeps a box. Each group is framed
with an ALL/ANY switch and a "not" check box and ends in "+ condition",
"+ group" and "+ near". An edit goes straight to the tree, and `on_change`
hears every change, including a proximity's distance (0.28.1). The first
builder's flat calls (`add_clause`, `set_clause`, `set_join_all`) still work on
the root group. `SW_TEXT_BOX.set_preferred_text_width` lets a field ask for
less than the default 240 pixels.

![Query builder, light theme](evidence/gw12_builder_light.png)
![Query builder, dark theme](evidence/gw12_builder_dark.png)

**One hundred thousand rows (0.28.0)** — `SW_DATA_GRID` draws only the rows in
view, and the concordance case (88,444 rows for the Greek article) was
measured with 100,000 rows of shaped Hebrew and Greek cells. The defect was in
simple_shaping 0.6.1: its layout cache's contracts rebuilt a whole model on
every call. In this library, `SW_SHAPING.layout_styled` (which every widget's
`SW_PAINTER.text` calls) keeps two generations of 1,024 layouts, so a string
drawn again is one hash lookup. The font setters clear that memory, and
`forget_layouts` is there for changes made on `facade` directly.
`SW_GRID_COLUMN.sort_key` gives each row's key once per sort instead of two
agent calls per comparison. Measured:
- Lean build (`ec.sh release`, the shipping configuration): wheel frame 1.5
  milliseconds median, page jump 5.1 milliseconds, sort 175 milliseconds,
  against a 16.7 millisecond frame.
- Contracts-on build (`ec.sh test`), with every contract on: wheel frame 14.8
  milliseconds, page jump 42.6 milliseconds (0.28.2; the lean build is 1.5
  and 5.1). The GW-29 test times only the measured step inside
  simple_testing's `without_contracts`, with contracts switched off for that
  step: wheel frame 3.7 milliseconds, page jump 13.6 milliseconds. It asserts
  the 60 Hz budget in every build. The grid's merge runs over SPECIAL arrays,
  and 100,000 rows sort in about 190 milliseconds.

The grid also gained (0.28.2) `SW_DATA_GRID.add_row`, which places one row by
binary search instead of filtering and sorting every row, and `add_rows` for
many rows with one rebuild; and per-column alignment through
`SW_GRID_COLUMN.alignment`, `set_alignment` and `aligned`. The default,
`Align_start`, follows the text, so a Hebrew line sits flush right.

The test runner takes `SW_ONLY=<part of a test name>` to run only those tests.

![100,000 rows, light theme](evidence/gw29_grid_light.png)
![100,000 rows, dark theme](evidence/gw29_grid_dark.png)

**Shared building blocks (0.25.0)** — the common parts of the scrolling and
text widgets live once:
- `SW_TEXT_POINTING`, `SW_VSCROLLING`, `SW_TEXT_SELECTION`,
  `SW_IN_PLACE_EDITING`, `SW_STACKED_ITEMS` and `SW_DOC_UNITS` are deferred
  ancestors. A widget inherits them side by side (Eiffel multiple
  inheritance), because none of them redefines another's `SW_WIDGET`
  features. Two composed bases do the joining once, so each widget names one
  parent: `SW_STACKED_POINTING` joins pointing, scrolling and the stack, and
  `SW_DOC_UNITS` (the units of stacked texts and cells, lifted from the
  document view) inherits it together with `SW_TEXT_SELECTION`.
  `SW_PARALLEL_TEXT`'s inherit clause is a single parent. `SW_MARK_HOST` is a
  mixin with no parent at all (legend and mark painter), shared by the text
  box, the paragraph list and the parallel text. Pointing gives the character under the pointer, hover, dwell and
  hover cards. Scrolling gives the position, the bar, the wheel and the
  paging keys. Selection gives a selection across items, Copy and Select All.
  Editing in place gives the box laid over an item, key and character
  forwarding with Escape cancelling, and the change and commit callbacks.
  Stacked items gives the block stack, the measuring pass, the visible range
  and the draw frame. `SW_DOCUMENT_VIEW`, `SW_PARAGRAPH_LIST`, `SW_PARALLEL_TEXT` and
  `SW_INTERLINEAR` stand on these. `SW_DOC_UNITS` also owns its heirs' input
  (wheel, click, double click, drag, keys, hover) and layout bookkeeping, and
  `SW_STACKED_ITEMS.pinned_height` keeps a band that does not scroll out of the
  content.
- `SW_VSCROLLBAR` is the one vertical scrollbar, owned by `SW_LIST`,
  `SW_PARAGRAPH_LIST`, `SW_SCROLL_AREA`, `SW_CHAT_THREAD`, `SW_TREE` and
  `SW_DATA_GRID`. Its drag keeps the grab point and ends on release.
- `SW_BLOCK_STACK` stacks items of different heights and finds the item under
  a point by binary search.
- `SW_WORD_BOUNDARY` is the one definition of what a word is.

**Services** — clipboard (Unicode, surrogate-safe, hardened against
clipboard-history races), modifier keys, ISpellChecker wrapper.

## Quick start

```eiffel
local
    window: SW_WINDOW
    theme: SW_THEME
    root: SW_COLUMN
do
    create theme.make_dark
    create window.make ("hello", 100, 100, 900, 700, theme)
    create root.make
    root := root.with_padding (16.0).with_gap (12.0)
    root.put (create {SW_LABEL}.make_body ("Every pixel here is the toolkit's own."))
    root.put (create {SW_BUTTON}.make_primary ("Go", agent on_go))
    window.set_root (root)
    window.run
end
```

Add to your ECF:

```xml
<library name="simple_widgets" location="$SIMPLE_EIFFEL/simple_widgets/simple_widgets.ecf"/>
```

Ship `cairo.dll` beside your executable (every finalize wipes F_code — copy it
back after building).

## Shaped text (simple_shaping)

Cairo's "toy" text API has no bidi, no shaping, no font fallback and no colour
emoji: Hebrew comes out left-to-right and unjoined, a mixed Hebrew/Latin line is
scrambled, and every emoji is a tofu box. The toolkit can now hand its
text to [simple_shaping](https://github.com/simple-eiffel/simple_shaping)
instead — bidi, script itemization, glyph shaping, deterministic font fallback,
and emoji as the same Noto picture on every screen.

**It is opt-in, and the toy path is still the default.** Turn it on once, on the
window:

```eiffel
window.enable_shaped_text
```

That builds one `SW_SHAPING` kit — one `SIMPLE_SHAPING` facade plus one
`SHAPING_CAIRO_BRIDGE` — for the whole window, prepends the theme's UI face for
Latin only (a theme face is Latin-only by design; Hebrew and Greek keep
simple_shaping's own scholar-grade order), and hands it to the painter. The kit
survives theme swaps and offscreen re-allocations, so the layout cache and the
decoded emoji surfaces are built once.

`SW_CHAT_THREAD` uses it the moment it is there: bubbles are laid out by
`SIMPLE_SHAPING.layout`, bubble height is `layout.total_height` (never a line
count times a constant — a line carrying an emoji box is taller than one that
does not), and the old greedy word wrap is skipped. Everything else about the
widget is unchanged: `add_message`, `append_to_last`, sticky-bottom, wheel
scrolling and `content_h` behave exactly as before, on either path.

Custom widgets reach it the same way:

```eiffel
if a_p.has_shaping and then attached a_p.shaping as al_kit then
    l_layout := al_kit.layout_for (my_text, inner_width_px, pixel_size)
    a_p.draw_shaped_layout (l_layout, l_x, l_y)   -- (l_x, l_y) is a TOP-LEFT
end
```

**Menus take it too, since 0.7.2** — `SW_MENU` item labels, `SW_MENU_BAR` pad
titles and the popup's shortcut column. See *Menus on the shaped path* below.
`SW_LABEL` and the rest of the chrome deliberately stay on the toy path for now
— see "Known limits" below.

**Re-layout at resize END, not per tick (R10).** `SW_WINDOW` publishes its own
`busy_ticks` debounce to the painter as `SW_PAINTER.is_resize_storm`; a shaped
widget keeps the layouts it has while the frame is being dragged and re-lays-out
once the drag settles. A *content* change never waits — a message arriving
mid-drag still appears.

### The chat thread's scrollbar (0.5.0)

`SW_CHAT_THREAD` draws a vertical scrollbar along its own right edge —
track and thumb, sized from `SW_THEME`'s `text_scale` the way every other
themed dimension in this toolkit scales (`Scrollbar_w` is 12 px at 1x) —
whenever its content overflows the pane (`scrollbar_visible`, driven by
`max_scroll > 0.0`). It is invisible, and inert, the rest of the time.

**Follow-the-tail.** The thread starts, and stays, sticky at the bottom:
a new message auto-scrolls the view with it. Scrolling up — the wheel,
dragging the thumb, clicking the track, PageUp, Home — breaks stickiness;
scrolling back down to within 2 px of the bottom — the wheel, a drag,
clicking the track, PageDown, End — restores it. Every one of those
entry points funnels through the one `scroll_to (a_y)` query, so the
`[0, max_scroll]` clamp and the sticky law are enforced in exactly one
place.

**Mouse.** Press the thumb and drag it; click the bare track above or
below the thumb to page toward the click. Both go through the widget's
existing `handle_click` / `handle_drag` / `handle_release` — no new input
plumbing in `SW_WINDOW`.

**Keyboard.** The thread now accepts keyboard focus (`accepts_focus` is
`True`, joining the Tab ring the way `SW_LIST` does) — click it once, then
PageUp, PageDown, Home and End move it, the same virtual-key vocabulary
`SW_LIST` already uses.

```eiffel
thread.scroll_to (0.0)                 -- jump to the top, programmatically
thread.scroll_to (thread.max_scroll)   -- jump to the tail
thread.is_sticky                       -- following the conversation right now?
```

**The fix underneath it.** Before 0.5.0, `draw` clamped `scroll_y` once
*per bubble*, against `content_h` while it was still being accumulated —
the very first bubble always saw a content height of 8.0 (the loop's own
starting value), so on any pane taller than 8 px the clamp reset
`scroll_y` to ~0 on every single frame, before the true total was ever
known. The tail could never scroll into view and no wheel delta survived
the next repaint. `draw` now runs two passes: PASS 1 measures every
bubble with no drawing and no dependence on `scroll_y`, so `content_h` is
the real total *before* anything is clamped against it; PASS 2 draws at
the one offset the frame settled on.

### Line breaks in a bubble (0.6.0)

A chat message is not one paragraph. `SW_CHAT_THREAD` cuts every message at
its explicit line breaks before either path lays anything out:

| in the message      | what happens                                    |
|---------------------|-------------------------------------------------|
| `LF`                | ends the line; never drawn                      |
| `CRLF`              | ONE break, not two                              |
| a lone `CR`         | ends the line; never drawn                      |
| `TAB`               | becomes a space (there are no tab stops here)   |
| two or more breaks  | at most ONE empty line — a bounded blank        |
| a trailing break    | dropped: a message ending in a newline has no empty last line |

Wrapping then applies WITHIN a paragraph, and a bubble's height is its real
line count.

```eiffel
thread.paragraphs_of (some_text)   -- the cut, as a public contracted query
thread.display_text (i)            -- message i as the bubble SHOWS it
```

On the shaped path this means **one `SHAPED_LAYOUT` per paragraph**, because
simple_shaping lays out a paragraph and treats an LF as a mere break
*opportunity* — it still shapes and paints the character, which is where the
square boxes came from. `shaped_layouts` is a flat list in message order and
`layout_spans` says which layouts belong to which message
(`shaped_layouts [base .. base + span - 1]`). A message with no line breaks
is still exactly one layout.

**Add a message whenever you like (0.6.1).** A layout can only be made by
`SW_SHAPING.layout_for`, at an inner width and a pixel size the widget does not
learn until the painter hands them over inside `draw` — so `add_message` cannot
keep `layout_spans` in step with `messages`, and between two frames the spans
describe the frame that was drawn. That is normal, and the widget says so:
`laid_out_revision = revision` is its own answer to *are these current?*. In
0.6.0 the class invariant demanded one span per message unconditionally, so
`add_message` after a first shaped frame failed **its own invariant** in any
build that checks one — which is every workbench and `ec.sh test` build, and
precisely what a live chat client does on every event after its first frame. It
never bit a shipped client only because finalized code checks no invariants.

### Selecting and copying from a bubble (0.6.0)

Bubbles are selectable text. Press and drag inside one to select; double-click
takes the word; Escape clears; Ctrl+C — or the right-click menu (Copy, Select
Message, Select None) — copies through `SW_CLIPBOARD`, the same door
`SW_TEXT_BOX` uses.

```eiffel
thread.has_selection      -- is there a range?
thread.selected_text      -- exactly what copy_selection would hand the clipboard
thread.select_message (2) -- the whole of bubble 2
thread.clear_selection
```

Granularity is per CHARACTER on the toy path and per GLYPH CLUSTER on the
shaped path, walked over `GLYPH_RUN`'s own `cluster_map` and `x_positions`
(`SHAPED_LINE` reserves `character_index_at_x` for a future simple_shaping
cycle and does not implement it). Right-to-left runs are handled by direction:
the boundary at a cluster's left edge is the caret AFTER that character.

**Selection lives inside one bubble.** A drag that wanders out runs to the
anchor bubble's own ends and stops — a thread is a list of utterances by
different speakers, and a range spanning three of them has no honest text to
hand the clipboard. Cross-bubble selection is not supported and is not
planned.

### The per-message menu — edit, react, delete, reply (0.7.0)

A bubble used to be write-once. `add_message` put one on the thread and
`append_to_last` grew it while a token stream ran, and after that nothing could
change it — which is not what a chat server does. A server folds *edit*,
*delete* and *reaction* events over the message they name, and a *reply* is a
message carrying a parent's id. The thread now has a door for each.

```eiffel
thread.set_message (2, {SW_CHAT_THREAD}.Role_keep, "the corrected text")
thread.mark_edited (2)                       -- a small muted "edited" marker
thread.tombstone (3)                         -- a visible placeholder, never a gap
thread.set_reactions (4, row)                -- emoji + tally chips, mine outlined
thread.set_reply_quote (5, "Ada", "the parent message")

thread.is_edited (2)        thread.is_tombstone (3)
thread.reactions_of (4)     thread.has_reply_quote (5)
thread.reply_quote (5)      thread.quote_line (5)     thread.drawn_quote (5)
thread.bubble_height (4)    -- what the last frame measured it at
```

`Role_keep` is not a role: it is what an edit passes when the words change and
the speaker does not, which is the common case (a server's edit event carries
no new author).

**Every one of these is a CONTENT CHANGE, and that is the whole safety story.**
A content change has meant *bump `revision`* since 0.5.0. `laid_out_revision`
then lags, the invariant's `spans_match_when_current` guard goes quiet for
exactly one frame, `refresh_layouts` rebuilds and records — the same door
`add_message` has always gone through, and the reason 0.6.1's fix generalizes to
mutations it never saw. Nothing here re-shapes: a span indexes layouts only
`SW_SHAPING.layout_for` can make, at an inner width and a pixel size the widget
does not learn until `draw`.

**A delete is a tombstone, never a gap.** `tombstone` keeps the bubble where it
is, at reduced height, muted, saying *message deleted* — because the ORDER of a
thread is part of its record and a vanished bubble silently rewrites who
answered whom. It does really destroy the text (`messages.i_th (i).text` is
emptied, not hidden), so no selection can reach it and `copy_selection` has
nothing to take; hiding the words behind a flag would leave them one query away
from anyone with a debugger, which is not what *deleted* means. Every
decoration goes with it: a reaction to a deleted message is a claim about words
nobody can read. `tombstone` is terminal and idempotent — the other four
commands require a live message.

**The four bands.** A bubble is now up to four stacked bands inside its own
padding: a one-line reply quote (elided at the inner width — a quote that
wrapped would be a second message), the text, the "edited" marker, and a
reaction row that wraps rather than run off the bubble's edge. Each band is
MEASURED, never assumed, and each therefore changes `content_h` and the
scrollbar thumb. Stickiness survives all of it exactly the way `add_message`
preserves it: a thread parked at the tail is re-parked; a reader who has
scrolled up is not yanked.

**Both text paths.** The quote and each chip's emoji go through the shaping kit
when there is one — so a Hebrew quote reads right-to-left and a reaction carries
the same Noto picture as the bubbles do — and fall back to cairo's toy metrics
when there is not. The decoration layouts are kept OUT of `shaped_layouts` on
purpose: `layout_spans` tiles that list exactly, and a quote laid into it would
make the tiling a lie.

**The two questions a host's right-click asks:**

```eiffel
thread.message_at (px, py)    -- which bubble, 0 for none
thread.reaction_at (px, py)   -- [message, emoji], or [0, ""] off every chip
```

Both are answered from the geometry the last `draw` recorded — the same frame
cache `hit_test` has used since 0.6.0 — so neither needs a painter, and a menu
and a selection can never disagree about which message was meant. A tombstone
answers `message_at` with its own index: a deleted message is still a message a
menu may want to offer something on.

![Per-message mutation at 2x](evidence/thread-mutation-2x.png)

*Left to right down the thread: an untouched bubble, an edited one with its
marker, a tombstone, a bubble carrying three reaction chips with the reader's
own outlined, and a reply with its elided quote — 2x text, shaped path.*

### The runnable folder

Shaped text adds freight beside the executable. A shipped app's folder is:

```
myapp.exe
cairo.dll                        <- from $SIMPLE_EIFFEL/simple_cairo/
LICENSE-ASSETS.md                <- from $SIMPLE_EIFFEL/simple_shaping/
assets/noto-emoji/png/128/...    <- from $SIMPLE_EIFFEL/simple_shaping/assets/
```

`SW_SHAPING.make` resolves the artwork against the directory of the **running
executable**, never the working directory (a shortcut, a service, an Explorer
double-click and a debugger all differ). `tools/stage_runnable.sh` stages all
three:

```bash
tools/stage_runnable.sh EIFGENs/sw_demo/F_code
```

Missing artwork is not a crash — simple_shaping degrades to a note and a box —
but the robot will not be a robot.

**This library's own test target does not stage the assets.** Copying 3,768
files (about 20 MiB) into `F_code` on every build is a poor trade for a suite
that reads four of them, so the shaped-text tests look for the artwork beside
the exe FIRST (so a staged folder is exercised when there is one) and fall back
to `$SIMPLE_EIFFEL/simple_shaping/assets/noto-emoji/png/128`. Applications get
no such fallback: stage the folder.

### Menus on the shaped path (0.7.2)

A menu item labelled with an emoji used to draw an **empty box**. `SW_MENU.draw`
painted with `SW_PAINTER.text` while `SW_CHAT_THREAD` painted with
`draw_shaped_layout`, and only the kit resolves the Noto artwork or shapes a
complex script — so the same character was a picture in a bubble and a square in
a menu two inches away. `SW_MENU` and `SW_MENU_BAR` now take the shaped path
whenever `SW_PAINTER.has_shaping`, and the toy path, unchanged, when it does not.

```eiffel
window.enable_shaped_text          -- the menu follows; nothing else to say
```

**The cache.** `SW_SHAPED_TEXT` holds one-line layouts keyed by **text + pixel
size** — and the pixel size is `(theme.size_label * theme.text_scale).rounded`,
the number the glyphs are shaped at, so a scale change is a different key by
construction and there is nothing extra to remember. A kit swap empties it; 64
entries cap it. `SW_MENU` owns one per menu (a menu is built fresh at every open,
so the cache's life is one presentation — which is repainted every frame it is
up); `SW_MENU_BAR` owns one per bar, which is where it earns its keep.

**The underline.** A mnemonic used to be placed at `advance (label.substring (1,
ul - 1))` — the width of the text *before* the letter, which asserts that source
order and paint order are the same thing. In an RTL title they are opposite: the
first character paints **rightmost**. `SW_SHAPED_TEXT.character_span` walks the
line's runs in visual order and reads `GLYPH_RUN.cluster_map` and `x_positions`
for where the character actually landed (an `IMAGE_RUN` answers its whole box —
what an emoji underlines as). Ask for it directly rather than re-deriving it:

```eiffel
l_bounds := a_menu.item_underline_bounds (a_p, i)   -- left, width, from the label origin
l_bounds := a_bar.pad_underline_bounds (a_p, i)
```

**The measure is the shaped measure, in both directions.** `measure` sizes items
with the same `label_width` / `hint_width` that `draw` places with, so an
emoji-only item is as wide as its picture. Row height follows: `Item_h` is a
floor, not the answer — a 128px Noto picture laid out at 2x is taller than the
type and drew over the row below and out through the menu's own border. Rows are
`Item_h.max (shaped label height + 6)`, computed by `measure` and cached in
`item_heights`, because `item_at` hit-tests where there is a menu, a point, and
no painter. On the toy path a row is exactly `Item_h`, so nothing that shipped
moves.

Evidence: `evidence/menu-emoji-2x.png`.

### Known limits

- `SW_LABEL`, `SW_BUTTON` and the rest of the chrome still draw through
  `SW_PAINTER.text`. Their `preferred_width` / `preferred_height` are cairo toy
  advances, and every layout in the toolkit is measured from them, so swapping
  their metrics is a separate, wider change — not a small safe one.
- One kit per window, per SCOOP processor. A background processor that wants to
  measure text creates its own.
- Every mnemonic is a MENU BAR mnemonic. Alt+letter opens a pad; it does not
  move focus to a labelled control, because no widget declares an `&` label
  yet. See *The Alt door* below.
- A menu's minimum width is still a flat 160, so a menu of nothing but emoji is
  wider than the pictures need. The floor, not the measure, decides there.

## Keyboard: accelerators and mnemonics (0.6.0)

A key used to reach exactly one place — the focused widget. An application
that wanted Ctrl+N to mean *New* wherever the caret happened to be had nowhere
to say so. Now it does:

```eiffel
window.register_accelerator (78, True, False, False, agent new_document)
        -- Ctrl+N, anywhere in this window, whoever holds focus
window.register_accelerator (83, True, False, True,  agent save_as)
        -- Ctrl+Shift+S is a DIFFERENT key: the modifier state must match exactly
```

`accelerator_for` answers which entry claims a key (0 = none),
`fire_accelerator` runs it, `clear_accelerators` empties the table. A modifier
is required — an unmodified accelerator would take the letter out of every
text box in the window.

**An unclaimed key is still the widget's own.** Ctrl+A / C / V / X / Z / Y
reach the focused `SW_TEXT_BOX` exactly as they always did unless an
accelerator claims them. No existing signature changed:
`SW_WIDGET.handle_key (a_vk, a_shift)` is untouched.

**Both key doors are tried**, which is not an implementation detail you can
ignore when reading the dispatch: simple_shell's WM_KEYDOWN filter forwards
only the stepping keys (arrows, Home/End, Page keys, Delete, OEM plus/minus)
as event 4, so a letter never arrives that way. Ctrl+C arrives as event 3 —
the WM_CHAR control code 3 — which is how `SW_TEXT_BOX` has always read it.
The table is consulted on both, and a hit on the key-down door swallows the
WM_CHAR that trails it.

### Menu mnemonics

An `&` in a menu title or item underlines the letter after it:

```eiffel
bar.add_menu ("&File", agent build_file_menu)     -- draws "File", F underlined
menu.add_item ("Select &All", "Ctrl+A", True, agent select_all)
menu.add_item ("R&&D", "", True, agent open_rd)   -- literal "R&D", no mnemonic
window.set_menu_bar (bar)                          -- give this bar the Alt key
```

`labels` and `items.label` keep the PLAIN reading, so every existing reader
sees the text it always saw; the declaration survives in `raw_labels`, where
`menu_for_mnemonic` and `item_for_mnemonic` find it. While a menu is open a
BARE letter picks the item that underlines it — the second half of the
*Alt+F, then N* gesture — and that half works today.

### The Alt door — the gap 0.6.0 named, closed (0.6.1)

0.6.0 shipped the mnemonics with a hole named in this README: Alt+letter never
reached the window at all, because simple_shell answered `WM_SYSKEYDOWN` for
the OEM plus/minus pair alone. **simple_shell 1.9.3 closed its half** —
Alt+A..Z and Alt+0..9 now arrive as the ordinary key-down event 4 by virtual
key, with the `WM_SYSCHAR` behind them swallowed so `DefWindowProc` cannot
open the system menu behind the application's back.

That swallow is why the toolkit still saw nothing: `activate_mnemonic` sat on
the WM_CHAR door, which the shell now never knocks on for an Alt combination,
so the gesture reached the accelerator table and died there unless the host
had registered Alt+F/E/R/H by hand. **It no longer has to.** With Alt held and
no accelerator claiming the key, the window tries its own `menu_bar`:

```eiffel
window.set_menu_bar (bar)   -- this, and nothing else, is what Alt+F needs
```

Order is the contract: the accelerator table is asked **first**, so a host that
really wants Alt+F for itself still keeps it; the menu bar is asked **second**;
the focused widget is asked **last**, so Alt+letter no longer disappears.
`activate_mnemonic` stays public — a button or a Ctrl accelerator may still
drive it — and the WM_CHAR path is untouched for shells that deliver Alt that
way. **Ctrl accelerators are unaffected.**

`SW_WINDOW.simulate_key_down (a_vk, a_ctrl, a_alt, a_shift)` delivers a
key-down through the **same** `route_key_down` the native event 4 runs, with
the modifier state as parameters instead of a live `GetKeyState`. It is how the
assault proves this offscreen without pressing Alt on anybody's desktop, and
it is the wheel door's (`simulate_wheel`) twin.

`SW_WINDOW.simulate_context_click (a_x, a_y)` completes the family. It is one
line — `dispatch (11, a_x, a_y)` — and that is deliberate: it delivers a
right-click through the **shipped** dispatch, so modality is asked first, the
dev lens gets its turn, `target_at` picks the widget and `bubble_context` walks
its ancestors for the first `context_menu` on offer, focusing the target the way
every editor does, and `show_popup` presents it. `open_popup` then answers with
what came up.

This is the only way a test can make a window **present** a menu: `show_popup`
is `feature {NONE}`, so before it a host could build a context menu and read its
items but never paint one — everything between the click and the menu was
unprovable. A second context click **closes** the open menu rather than stacking
one over it, and that falls out of routing through `dispatch` rather than being
written twice.

> A test door that reasons about anything is a test door that can be right while
> the product is wrong. `simulate_key_down` was once four lines that skipped the
> popup branch, and an arrow-key assault passed with the fix deleted. These doors
> stay one line each.

## Margins and padding

Controls do not sit on the window edge. The toolkit carries Vision2's spacing
model as three theme tokens, and every one of them **scales with the text**, so
an application drawing at 2x (`theme.set_text_scale (2.0)`) gets 2x margins
without touching a layout.

| Vision2 (`EV_BOX`, ISE 25.02) | simple_widgets | 1x | Meaning |
|---|---|---|---|
| `EV_BOX.border_width` | `SW_THEME.border_width` | 12 px | space between a container's edge and its content |
| `EV_BOX.padding` / `padding_width` | `SW_THEME.padding` | 8 px | space between siblings |
| *(no Vision2 name — a native control owns its own margins)* | `SW_THEME.control_inset` | 11 px | space between a control's edge and its label |
| `EV_LAYOUT_CONSTANTS.default_button_height` | `SW_PAINTER.min_control_height` | measured | ascent + descent + 2 × `control_inset` |
| `EV_LAYOUT_CONSTANTS.dialog_unit_to_pixels` | `SW_THEME.text_scale` | ×1.0 | the one knob every token is multiplied by |
| *(no Vision2 name)* | `SW_THEME.scrollbar_width` | 12 px | the column a vertical scrollbar takes (0.20.0) |
| *(no Vision2 name)* | `SW_THEME.min_thumb` | 24 px | the shortest a scrollbar thumb draws, so it stays grabbable (0.20.0) |

The last two tokens size `SW_VSCROLLBAR`, so every scrolling widget draws the
same bar, and both scale with the text.

**The border is applied once.** `SW_WINDOW` insets its root widget by
`theme.border_width` on all four sides (`SW_WINDOW.content_border`), and
`SW_DIALOG` does the same inside its card. Every plain box therefore defaults
its own `padding` to **0** — exactly as Vision2 defaults `EV_BOX.border_width`
to 0 (`EV_BOX_I.Default_border_width`) and lets the dialog set it
(`EV_MESSAGE_DIALOG` does `vb.set_border_width (10)`). Nest boxes as deep as you
like: the content is inset **once**.

Boxes that *are* a surface in their own right keep a border: `SW_CARD`
(`control_inset`), `SW_GROUP` (`border_width`), `SW_FILE_DIALOG`
(`padding × 0.75`).

**An explicit value always wins.** `with_padding` / `set_padding` and
`with_gap` / `set_gap` mark the box explicit (`padding_is_explicit`,
`gap_is_explicit`), and an explicit value — **including 0.0** — is never
overwritten by the theme, at any scale. Layout reads `effective_padding (p)` and
`effective_gap (p)`; a box that was never told stays theme-driven.

```eiffel
create col.make                     -- gap = theme padding, border = 0
create page.make
page.put (col)                      -- nested: still no second border
win.set_root (page)                 -- the window supplies the ONE border

create tight.make
tight := tight.with_gap (0.0)       -- explicit 0 stands, even at 2x text
```

**Controls are never smaller than their font.** `SW_PAINTER.text_extent` is
cairo's own `font_extents` ascent + descent for the *selected* font, so it
already carries `text_scale`; `min_control_height` adds the inside inset above
and below, and `min_control_width (s)` does the same either side of a measured
advance. `SW_BUTTON`, `SW_TEXT_BOX`, `SW_CHECK_BOX` and `SW_NUMBER_BOX` clamp
their natural height up to it — a larger explicit anchor still wins through
`clamped_height` (`SW_TEXT_BOX.minimum_height` selects the body font first, so
the answer never depends on what was drawn last). Measured at 1x → 2x: button 38 → 75, text box 42 → 80, check
box 38 → 75, number box 38 → 75, label 24 → 47 px.

`SW_LABEL.line_step` is measured too (`text_extent` + the theme's leading), so a
wrapped label's line step and its painted glyphs agree at every scale; it used
to step by the *nominal* `size + 9.0` while painting at `size × text_scale`.

Evidence: `evidence/margins-before.png` (root at 0,0 — controls flush on the
edge) against `evidence/margins-after.png`, plus `margins-1x.png` /
`margins-2x.png` for the control-size proof. All rendered offscreen onto a cairo
image surface; see `testing/sw_margins_assault.e`.

## The rules (spec S01)

| # | Rule |
|---|------|
| R1 | One language: Eiffel over inline C externals |
| R2 | Painter monopoly: only SW_PAINTER touches CAIRO_CONTEXT |
| R3 | Contracts everywhere |
| R4 | Theme is truth: tokens only, no literal colours in widgets |
| R5 | Agents wire behaviour |
| R6 | Immediate feedback: every interaction shows its effect now |
| R7 | Nothing native: menus, dialogs, file pickers — all drawn |
| R8 | Unicode first: STRING_32 throughout, surrogates paired at the borders |

## Documentation

- **[Core documentation](https://simple-eiffel.github.io/simple_widgets/)** — overview, architecture, rules, quick start
- **Per-control pages** — every shipped class has its own page under
  `docs/widgets/` with a complete description, working examples, known limits,
  bugs & gotchas, and extension plans
- **The living cookbook** — `demo/sw_demo.e`, the showroom exercising everything
- **Specs** — `specs/S01` (layers & rules), `S02` (the full-coverage catalog,
  waves 1–6), `S03` (the appearance model); research surveys under
  `specs/research/`

## Build & test

```bash
# the demo showroom
/d/prod/ec.sh test -config simple_widgets.ecf -target sw_demo
cp $SIMPLE_EIFFEL/simple_cairo/cairo.dll EIFGENs/sw_demo/F_code/
./EIFGENs/sw_demo/F_code/simple_widgets.exe

# the contract assault (all assertions live)
/d/prod/ec.sh test -config simple_widgets.ecf -target simple_widgets_tests
cp $SIMPLE_EIFFEL/simple_cairo/cairo.dll EIFGENs/simple_widgets_tests/F_code/
./EIFGENs/simple_widgets_tests/F_code/simple_widgets.exe
```

## Roadmap

**Waves 1–4 are COMPLETE.** Wave 3 closed with the dropzone and the
dev-mode suite (inspector, force mesh, dev studio — devkit-only classes,
binary-proven absent from release shapes). Wave 4 shipped all fifteen
visualization concepts in six movements — the SW_SCALE axis engine,
line/bar/area/scatter, pie/donut + funnel + shared legend, gauge +
sparkline, heatmap + treemap, sankey ribbons, the coarse world map and
the public force diagram — plus the timezone coda (pickable band map +
live world clock). The same day delivered the event layer (SW_EVENT,
ACTION_SEQUENCE architecture), Vision2-style sensitivity
(set_enabled_when), and subscribable render bells.

**Wave 5 is COMPLETE, in one sitting**: tree table, the SPREADSHEET
doctrine whole (graduated cells engine - ranges, aggregates with a
stated assaulted law, TSV/CSV, command undo - under a formula-bar
widget), pivot, kanban moved by pebbles, scheduler with assaulted
overlap lanes, gantt with elbow dependencies, file manager, query
builder, form generator, org chart with its centring law proven, and
TRUE DOCKING - reflow zones that collapse when empty.

**Wave 6 shipped its buildable heart the same day**: carousel, gallery,
the codec-agnostic media transport, the crop marquee, chat thread with
streaming and the sticky-tail law, the AI prompt view - and DICTATION:
whisper.cpp through simple_speech + simple_audio as a speechkit-cluster
service, with a REAL transcription in the assault suite on every run.
Honestly future-gated and stated: playback codecs, PDF view, smart
textarea.

**The catalog is shipped.** What remains is deepening: the standing
threads (on_[event] queue sweep, modal-resize round two, the ISE/Gobo
audit, simple_events graduation) and every per-control future listed
on its own page.

**The full plan:** [What's Still Coming](https://simple-eiffel.github.io/simple_widgets/roadmap.html)
— per-wave detail; `specs/S04-ROADMAP.md` is the per-control checkbox
docket, harvested from the doc pages so the two cannot drift.

## License

MIT — see [LICENSE](LICENSE).
