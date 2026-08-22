# S02 — The Widget Catalog and Build Order

*2026-08-22. Synthesis of R01 (WEL + Vision2: 80 concepts from the
installed EiffelStudio 25.02 trees) and R02 (the 2025/26 web sweep:
232 concepts across 19 libraries, tiered 45/59/128). This is the
coverage map and the order of construction.*

## 1. Where simple_widgets stands today

Shipped and proven: SW_WINDOW (runtime), SW_THEME (light + dark,
programmable, contrast-contracted), SW_PAINTER, SW_LABEL, SW_BUTTON,
SW_CHIP, SW_CARD, SW_ROW, SW_COLUMN, SW_TEXT_BOX (multi/single line,
caret, selection by mouse/keyboard/double/triple click, clipboard,
context menu), SW_CLIPBOARD, SW_NATIVE_MENU.

Against the web Tier-1 bar of 45: roughly 10 covered. Against the
WEL/Vision2 union of 80: roughly 12. The map below is the gap.

## 2. The build order

Ordered by (a) forcing consumers - the narrate port first, the ocr
port second - and (b) desktop idioms promoted above their web tier
(R02's override list). Each wave is shippable alone.

### Wave 1 - the narrate port needs these (next)

| Widget | Notes |
|---|---|
| SW_SCROLL_AREA | scrolling container; prerequisite of every list |
| SW_LIST | virtualized item list (EV_GRID's spiritual heir); rows drawn via agent |
| SW_SPLITTER | two-pane, draggable divider |
| SW_CHECK_BOX | with tri-state later |
| SW_SELECT | closed dropdown (drawn popup, not native) |
| SW_PROGRESS | bar + indeterminate mode |
| SW_TOOLTIP | hover micro-hint, delay + placement |
| SW_DIALOG | modal over-window: message family first (info/warn/error/question) |
| SW_TOAST | transient corner notification queue |
| SW_ICON | glyph story: vendored icon font or drawn primitives - resolves the tofu lesson |

### Wave 2 - form-complete (the ocr port needs these)

SW_RADIO_GROUP, SW_SWITCH, SW_NUMBER_BOX (spin), SW_COMBO (editable),
SW_PASSWORD (mode of SW_TEXT_BOX), SW_SLIDER, SW_TABS, SW_STATUS_BAR,
SW_TOOLBAR, SW_MENU_BAR + drawn SW_MENU, SW_GROUP (titled border),
SW_SEPARATOR, SW_IMAGE (PNG via cairo), file dialogs (drawn - R7
allows nothing native).

### Wave 3 - the desktop long tail

SW_TREE, SW_TREE_TABLE, SW_DATA_GRID (sort/filter/edit - the crown),
SW_CALENDAR + SW_DATE_PICKER + SW_TIME_PICKER (never wrapped by WEL
or Vision2 - first-mover territory), SW_COLOR_PICKER, SW_DRAWER,
SW_POPOVER, SW_ACCORDION, SW_STEPPER, SW_BADGE, SW_AVATAR,
SW_SEGMENTED, SW_RATING, SW_SKELETON, SW_EMPTY_STATE, SW_DROPZONE,
drag-and-drop system, SW_STATISTIC, SW_TIMELINE.

### Waves 4-6 - the full-coverage charter

**Charter (Larry, 2026-08-22): ALL of it - the 232 web concepts and
the 80 WEL/Vision2 concepts - ultimately lives in simple_widgets.**
No carve-outs; the former non-goals become the final waves.

- Wave 4 - charts and visualization (15 concepts): cartesian suite,
  pie/donut, gauges, sparkline, heatmap, treemap, funnel, sankey,
  maps, diagram. All on SW_PAINTER; likely a `charts` cluster within
  this library rather than a sister repo.
- Wave 5 - enterprise composites (11): data-grid descendants first
  (tree table, pivot), then scheduler, gantt, kanban, spreadsheet,
  file manager, query builder, form generator, org chart.
- Wave 6 - media + conversational/AI (11): carousel, gallery,
  players, image tools, PDF view; chat thread, AI prompt view, smart
  textarea (the engine side rides simple_narrate's plumbing).
- WEL-era relics (MDI, rebar, resource-template dialogs) remain the
  sole exclusions unless a consumer demands them.

## 3. Theming commitments (from today's QA)

- R7 doctrine: nothing native, everything drawn - the menu that
  proved it was the first casualty and the first win (a drawn menu
  is frame-testable; TrackPopupMenu never was).
- Themes are programmable NOW: SW_THEME exposes set_surfaces /
  set_semantics / set_washes / set_families, with the WCAG contrast
  invariant still standing guard - code can build any theme except an
  unreadable one.
- Themes by DATA: a make_from_file over simple_toml is the planned
  route (theme.toml with the token names as keys). Queued for the
  narrate port, which already speaks TOML.

## 4. The scoreboard (end state: full union, per the charter)

- Web Tier 1: 45 concepts; waves 1+2 reach ~34 of them.
- WEL/Vision2 union: 80; waves 1-3 cover every non-relic entry.
- First-mover list (in neither WEL nor Vision2, in every web
  library): calendar, date picker, time picker, toast, skeleton,
  drawer, badge, avatar, stepper - simple_widgets can be the first
  Eiffel library ever to ship them natively.
