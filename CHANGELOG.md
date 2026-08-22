# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Wave 3 in progress

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
