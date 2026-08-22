# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Wave 3 in progress

### Added
- Indicator septet: SW_BADGE (99+ cap), SW_AVATAR (hash-stable hues,
  derived initials), SW_SEGMENTED (first chosen at birth), SW_RATING
  (star primitives; click again clears), SW_SKELETON (heartbeat shimmer),
  SW_EMPTY_STATE (tray glyph + one action), SW_STATISTIC (semantic delta)
- SW_PAINTER.star_fill / star_stroke (computed vertices, path hygiene)
- Heartbeat repaints unconditionally: the toolkit's ambient animation clock
- Demo is now a true app shell: menubar/toolbar/status bar pinned, body in
  a growing SW_SCROLL_AREA (window contents scroll; the footer never sinks)
- SW_INDICATOR_ASSAULT: ten new tests; suite at 35/35
- Docs: pages for the septet plus a PLANNED page for SW_INSPECTOR;
  specs/S04-ROADMAP.md consolidates every page's extension plans,
  fixable gotchas and pushable limits as action items

### Fixed
- Keyword casualty #5: `some` is an Eiffel quantifier keyword (across ...
  some); an assertion tag learned it the hard way

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
