# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Wave 3 in progress

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
