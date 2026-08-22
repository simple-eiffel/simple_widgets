# S04 - ROADMAP: the per-control docket

Consolidated from the per-control documentation pages (docs/widgets/) -
generated from the same source data, so the two cannot drift. Larry's
directives (2026-08-22): (1) every documented "Extension plan" is a
standing action item here; (2) every gotcha that admits a fix is on the
docket; (3) every limit that can be pushed until it is no longer a limit
gets planned here. Items marked [standing] are truths to design around
(physics, OS behaviour, Eiffel semantics), not work.

Toolkit-wide near-term items (from the same read):
- [ ] Window-level automatic scroll policy: when root content exceeds the
      window, the window itself offers the scrollbar (today: compose an
      SW_SCROLL_AREA body, as the demo shell does).
- [ ] Dual pinned drawers = true DOCKING (content reflow, workbench
      panels) - Wave 5 enterprise composites; overlays stay one-at-a-time
      by law until then (Larry, 2026-08-22).
- [ ] Top and bottom drawer gutters + Mode_top/Mode_bottom (the
      add_drawer_tab API already accepts all four edges).
- [ ] Overlay slide/ease animation on the heartbeat (drawers expanding
      and collapsing from window edges - Larry, 2026-08-22).
- [ ] Peek-close grace delay (a short dwell before an unpinned drawer
      dismisses).
- [ ] SW_SPREADSHEET (Wave 5): SW_SHEET + CELLS_ENGINE graduated
      library-grade - ranges (A0:B9), SUM/AVG/MIN/MAX/COUNT, formula
      bar, TSV block clipboard, CSV in/out, command-pattern undo
      (Larry's spreadsheet doctrine, 2026-08-22).
- [ ] Undo/redo engine for SW_TEXT_BOX - the most-missed feature.
- [ ] Focus traversal (Tab order) - unlocks default buttons, keyboard
      activation, list keyboard selection.
- [ ] Dirty-rect rendering + batched text runs - erases resize lag.
- [ ] Drawn-glyph set - unlocks icon buttons, toolbar icons, segment icons.
- [ ] Cursor API (I-beam, resize arrows).
- [ ] SW_INSPECTOR - design pinned in S02; lands at Wave 3 tail behind the
      debug ("dev_mode") gate.





## SW_WINDOW

Planned extensions:

- [ ] Multi-window support (owner/owned, drawn dialogs across windows).
- [ ] Cursor API (I-beam over text, resize arrows over splitters).
- [ ] Dirty-rectangle rendering and batched text runs to erase resize lag.
- [ ] Dev-mode inspector overlay (SW_INSPECTOR, S02): reflection-driven widget reveals behind an ECF debug ("dev_mode") compile-time gate.
- [ ] Per-window text scale (grow/shrink all fonts) via a theme scale factor.

Gotcha docket (fix where a plan exists; else design around):

- cairo.dll must sit beside the executable. Every finalize wipes F_code, deleting the DLL; the exe then dies at load looking exactly like a code crash. Copy it back after every build.
- run blocks. Everything after it executes only when the window closes.
- Window geometry is physical pixels. If a DPI-unaware shell moves the window (MoveWindow from PowerShell), the OS scales the coordinates - at 150% they land 1.5&times; away from where you aimed.
- Popups close on the next button-down anywhere; if a menu 'never appeared', something (or someone) clicked between open and look.

Limits to push:

- [ ] One window per application for now - no secondary or child windows yet.
- [ ] The frame echo (set_frame_echo) writes PNG lazily on the tick, not on every render - it is a debug instrument, not a video feed.
- [ ] No cursor shaping yet: the pointer stays an arrow even over text boxes and splitters.
- [ ] Redraws repaint the full frame; very large windows pay for it on resize drags (felt as slight grow-lag).


## SW_WIDGET

Planned extensions:

- [ ] Tab-order focus traversal with a visible focus ring policy.
- [ ] dev_note metadata for the SW_INSPECTOR overlay (provenance, intent, wiring).
- [ ] Accessibility bridge (UIA text patterns) - a research item; it must not violate R7.
- [ ] Animation hooks (hover/press transitions driven from the tick).

Gotcha docket (fix where a plan exists; else design around):

- The fluent for flex-grow is growing, not expanded - expanded, like frozen, old and variant, is an Eiffel keyword. Four names died learning this.
- Disabled widgets are inert AND transparent: clicks pass through to the parent chain.
- handle_click returning False means 'not mine' - the parent gets a turn. Consume deliberately.
- Attributes like caret on descendants are client-readable but never client-assignable (Eiffel semantics); drive state through commands.

Limits to push:

- [ ] No keyboard focus traversal yet - Tab does not move focus between widgets; focus follows clicks.
- [ ] State flags are window-maintained; driving a widget headless (as the test suite does) means calling handlers directly - hover/pressed stay False unless you set them.
- [ ] Only rectangular hit-testing (contains / widget_at).


## SW_THEME

Planned extensions:

- [ ] A scale factor multiplying the whole metric set - Larry's grow/shrink-font control applied theme-wide, or per container.
- [ ] Named palette registry (load/save themes).
- [ ] High-contrast palette meeting WCAG AAA.
- [ ] Per-widget style variants layered between kind and theme (S03's style axis, deepened).

Gotcha docket (fix where a plan exists; else design around):

- The WCAG invariants are real contracts: hand a theme a low-contrast ink/surface pair under an assertion-checked build and it dies at the assignment, not at paint time.
- Colours are NATURAL_32 RGB (no alpha in tokens); alpha lives in painter calls like set_color_alpha.

Limits to push:

- [ ] Metrics are fixed per theme instance - there is no global text-scale knob yet (planned; see Future).
- [ ] Two built-in palettes; custom palettes are built by mutating a base via the setters.
- [ ] Fonts resolve through cairo's toy API: no automatic glyph fallback across families.


## SW_PAINTER

Planned extensions:

- [ ] Dirty-rect support and batched same-style text runs (the resize-lag cure).
- [ ] Gradient and shadow tokens for depth, kept behind theme control.
- [ ] Sub-rectangle image blits and nine-slice scaling for skinnable surfaces.
- [ ] A recording painter for golden-frame regression tests.

Gotcha docket (fix where a plan exists; else design around):

- Never call context.arc directly - the connector-line bug. Use circle_stroke/circle_fill; they reset the path first.
- Use advance for layout, never ink extents - ink excludes trailing whitespace and your caret math will drift.
- set_line_width is stateful: set it back (the fleet convention is width 1.0 at rest) or the next widget strokes fat.
- Half-pixel offsets (x + 0.5) keep 1px strokes crisp; whole-pixel strokes blur across two device pixels.

Limits to push:

- [ ] Cairo toy text API: one face per call, no shaping, no bidi, no glyph fallback - a code point missing from the face renders as .notdef.
- [ ] No gradients, dashes or transforms in the public vocabulary yet (the escape hatch can, but that trades away R2).
- [ ] draw_image scales the whole source; no sub-rect (sprite) blits yet.


## SW_TEXT_BOX

Planned extensions:

- [ ] Undo/redo stack (command-pattern edits are a natural fit for the engine).
- [ ] Find/replace bar riding the same range machinery as multi-select.
- [ ] Horizontal scroll + ellipsis policies for single-line mode.
- [ ] Push-to-talk dictation (whisper.cpp, CPU-only) feeding receive_pebble-style insertion - queued from the AI-assist survey (R03).
- [ ] Syntax-colouring hook: a per-range style agent, same shape as spell ranges.

Gotcha docket (fix where a plan exists; else design around):

- Selection is drawn only while the box has focus - Select All from a context menu works because right-click transfers focus first. If you script the box headless, remember there is no window to grant focus.
- Masked boxes refuse clipboard copy even while revealed - by design (clipboard managers are the threat), so do not build a 'copy password' button on top of one.
- set_text collapses all selection state on purpose; capture selected_text first if you need it.
- An astral character (emoji) is ONE code point in text but TWO UTF-16 units in transit; the box and clipboard pair surrogates for you - never index text by UTF-16 unit counts.

Limits to push:

- [ ] No undo/redo yet - the most-missed feature; it is first in line (see Future).
- [ ] Single-line boxes do not scroll horizontally; text beyond the width clips until the box grows.
- [ ] No IME composition window for CJK input; code points arrive via WM_CHAR only (surrogate pairs are handled - see R8 - but composition UX is absent).
- [ ] Word wrap is greedy per word; no hyphenation or break-opportunity analysis.
- [ ] Spelling and suggestions are Windows-only (ISpellChecker).


## SW_COMBO

Planned extensions:

- [ ] Autocomplete: filter the menu by the typed prefix, Down-arrow to enter it.
- [ ] Scrolling dropdown via SW_LIST for hundreds of options.
- [ ] Recent-entries memory (an app-supplied history agent).

Gotcha docket (fix where a plan exists; else design around):

- The chevron zone is the right 30px - a click there never places the caret. Users aiming at the end of a long value should click just left of the chevron.
- Being a text box, the combo's invariant pins is_single_line forever - pasted newlines flatten to spaces.

Limits to push:

- [ ] No filter-as-you-type: the chevron always offers the full option list.
- [ ] Long text can run beneath the chevron glyph (the click zone still wins).
- [ ] The dropdown menu does not scroll; very long option lists will clamp to the window.


## SW_SELECT

Planned extensions:

- [ ] Option groups with separators; per-option enabled flags.
- [ ] A multi-select variant rendering chips of the chosen set.
- [ ] Type-to-jump (first-letter navigation) while the menu is open.

Gotcha docket (fix where a plan exists; else design around):

- selected_index = 0 means nothing chosen yet and selected_text is empty - guard first use.
- Options are copied in as STRING_32; mutating the string you passed changes nothing.

Limits to push:

- [ ] Single selection only; no multi-select variant yet.
- [ ] The menu shows all options at once - no scroll for very long lists.
- [ ] No per-option disabling yet (the underlying SW_MENU supports it; the select API does not surface it).


## SW_BUTTON

Planned extensions:

- [ ] Icon + text faces from a drawn-glyph library (R7-pure, no font-glyph gambling).
- [ ] Split buttons (action + chevron menu) and toggle buttons.
- [ ] Keyboard activation once focus traversal lands.

Gotcha docket (fix where a plan exists; else design around):

- The kind attribute is named kind because variant is an Eiffel keyword (loop variants). The compiler taught us.
- An agent created inside a creation procedure requires every attached attribute already set (VEVI); when a button's agent must reference the button itself, create it with Void and call set_on_click after.

Limits to push:

- [ ] Text-only faces; icon buttons arrive with the drawn-glyph set (see Future).
- [ ] No default-button / Enter-to-activate wiring (needs focus traversal first).
- [ ] No repeat-fire on hold (spinners implement their own).


## SW_LABEL

Planned extensions:

- [ ] Ellipsis truncation modes (end/middle) with full text in the tooltip.
- [ ] Rich runs (per-range role/colour) - shared machinery with the text box's future syntax-colouring hook.
- [ ] Links (click agents on ranges).

Gotcha docket (fix where a plan exists; else design around):

- UI and mono labels do NOT wrap by default - a long one inside a narrow splitter pane clips. That exact clip was a live bug report; body labels wrap for that reason. Use make_body or with_wrap for prose.

Limits to push:

- [ ] One style per label - no inline mixed bold/colour runs (compose labels in a row, or wait for rich text).
- [ ] Wrapping is per-word greedy; no ellipsis mode yet for single-line overflow.


## SW_CHECK_BOX

Planned extensions:

- [ ] Tri-state for hierarchical selection (with SW_TREE).
- [ ] Check-box groups with select-all headers.

Gotcha docket (fix where a plan exists; else design around):

- set_checked does not fire on_change - programmatic state is silent by design; call your handler yourself if you want the side effects.

Limits to push:

- [ ] No tri-state (indeterminate) mode yet - it arrives with the tree's cascading checks.
- [ ] Label is plain text (single style).


## SW_SWITCH

Planned extensions:

- [ ] Knob travel animation from the tick.
- [ ] Optional on/off captions inside the track.

Gotcha docket (fix where a plan exists; else design around):

- set_on is silent (no agent fire) - same convention as the check box.

Limits to push:

- [ ] No sliding animation yet - the knob teleports (animation hooks are a windowing future item).


## SW_RADIO_GROUP

Planned extensions:

- [ ] Vertical orientation flag.
- [ ] Radio cards (rich content per option) as a component-layer composite.

Gotcha docket (fix where a plan exists; else design around):

- There is deliberately no 'nothing selected' state once options exist - design forms accordingly (add an explicit 'None' option if absence is a real choice).

Limits to push:

- [ ] Horizontal layout only; a vertical variant is trivial and queued.
- [ ] No per-option disabling yet.


## SW_SLIDER

Planned extensions:

- [ ] Vertical orientation; range sliders (two knobs).
- [ ] Tick marks with optional snapping; arrow-key nudges once focus traversal lands.

Gotcha docket (fix where a plan exists; else design around):

- on_change streams during the drag - debounce in your handler if the work is expensive; do not debounce the visual echo (immediate feedback is the point).

Limits to push:

- [ ] Horizontal only; no vertical orientation yet.
- [ ] No tick marks, snap points or keyboard nudging yet.
- [ ] Continuous fractions only - integer stepping is SW_NUMBER_BOX's job.


## SW_NUMBER_BOX

Planned extensions:

- [ ] Editable value area (single-line text box fusion) with parse-on-commit.
- [ ] REAL_64 variant with precision control; unit suffixes (px, %, pt).
- [ ] Hold-to-repeat on the spinners.

Gotcha docket (fix where a plan exists; else design around):

- set_value clamps rather than rejects - passing 999 into a 0..100 box yields 100, silently. The invariant holds either way.

Limits to push:

- [ ] Integers only (REAL variant queued).
- [ ] No direct typing into the box yet - values move by spin and wheel; a text-entry marriage with SW_TEXT_BOX is planned.


## SW_PROGRESS

Planned extensions:

- [ ] Indeterminate mode (marquee pulse from the tick).
- [ ] Segmented and stacked variants (multi-part totals).
- [ ] Circular progress for dashboards (SW_PAINTER circles are ready).

Gotcha docket (fix where a plan exists; else design around):

- INTEGER / INTEGER division in Eiffel is obsolete-flagged and truncating - convert first (clicks.to_double / 10.0), or the bar jumps in whole steps.

Limits to push:

- [ ] Determinate only - no indeterminate 'working...' pulse yet.
- [ ] No transition animation between values.


## SW_CHIP

Planned extensions:

- [ ] Removable chips (x zone + removal agent) for tag editors.
- [ ] Choice chips (single/multi select sets) - the web sweep's filter-chip pattern.
- [ ] Counting badges attachable to other widgets (with SW_BADGE in Wave 3).

Gotcha docket (fix where a plan exists; else design around):

- Chip text renders at the theme's smallest size (size_chip) - keep labels to a word or two; chips are badges, not sentences.

Limits to push:

- [ ] Read-only: no close button, no click action (interactive/removable chips are a planned variant).


## SW_ROW

Planned extensions:

- [ ] Wrapping mode (flex-wrap) for chip sets and toolbars that reflow.
- [ ] Cross-axis alignment options (center, baseline, stretch).

Gotcha docket (fix where a plan exists; else design around):

- A row inside a column receives the column's full width; without any growing child the leftover is simply empty space at the right - by design, not a bug.

Limits to push:

- [ ] No wrapping row yet (flex-wrap) - children beyond the width clip.
- [ ] Vertical alignment is top-aligned per child height; no baseline alignment.


## SW_COLUMN

Planned extensions:

- [ ] Scroll-aware columns (auto-adopt a scroll area when overflowing).
- [ ] Named layout regions (header/content/footer sugar over the spacer idiom).

Gotcha docket (fix where a plan exists; else design around):

- Padding lives on the column, gap between children - mixing per-child margins into widgets fights the engine; spacing belongs to containers.

Limits to push:

- [ ] No horizontal scrolling of overflow; a column taller than its slot clips (put it in an SW_SCROLL_AREA).
- [ ] Grow distribution shares positive leftover only; when content exceeds the window, excess simply runs past the bottom.


## SW_CARD

Planned extensions:

- [ ] Optional shadow depth when painter gains shadow tokens.
- [ ] Header/footer slots (title row and action row sugar).
- [ ] Collapsible cards (sharing SW_ACCORDION's machinery in Wave 3).

Gotcha docket (fix where a plan exists; else design around):

- The stripe colour is a raw token you pass - take it from the theme (theme.accent), never a literal, or the light palette will betray you.

Limits to push:

- [ ] No elevation/shadow (flat surfaces by design until gradient/shadow tokens land).
- [ ] Stripe is left-edge only.


## SW_GROUP

Planned extensions:

- [ ] Surface-aware title patch (sample the actual ground).
- [ ] Optional per-group enable switch in the title (enables/disables all children).

Gotcha docket (fix where a plan exists; else design around):

- The title's background patch is painted in theme.background - a group placed on a different surface (e.g. directly on a card) shows a faint rectangle behind the title. Grouping inside cards is fine; the patch matches in practice because cards sit on the background. Known cosmetic edge.

Limits to push:

- [ ] Title is plain text, single style, left-anchored.
- [ ] No collapse/expand (that is SW_ACCORDION's job, Wave 3).


## SW_SEPARATOR

Planned extensions:

- [ ] Vertical variant for rows.
- [ ] Labeled separator (text carved mid-line, SW_GROUP-style).

Gotcha docket (fix where a plan exists; else design around):

- It spans the container's width, not the window's - inside padded columns the line respects the padding, which is almost always what you want.

Limits to push:

- [ ] Horizontal only (menus and toolbars draw their own vertical gaps).
- [ ] No label-in-line variant ('--- OR ---') yet.


## SW_SPACER

Planned extensions:

- [ ] Weighted convenience creation (make_weighted (2.0)) - today use set_grow after creation.

Gotcha docket (fix where a plan exists; else design around):

- Two spacers share slack equally (both grow 1.0) - centering trick: spacer, content, spacer.

Limits to push:

- [ ] It has no minimum: with zero slack it vanishes entirely (that is the point).


## SW_TABS

Planned extensions:

- [ ] Closable and reorderable tabs (the app-shell pattern).
- [ ] Lazy page construction (page-builder agents, menus-style).
- [ ] Vertical rail placement for tool windows.

Gotcha docket (fix where a plan exists; else design around):

- Pages of different heights change the notebook's preferred height when swapped - content below the tabs moves. Pin the window layout with a spacer-footer, or give pages a common min height if jumping bothers the design.

Limits to push:

- [ ] Top bar only (no side/bottom placement yet).
- [ ] No close buttons, drag-reorder, or overflow scrolling of many tabs.
- [ ] Hidden pages are fully passive: they hold state but receive no events (by design).


## SW_SCROLL_AREA

Planned extensions:

- [ ] Horizontal mode and two-axis mode.
- [ ] Scroll-into-view requests bubbling from focused children.
- [ ] Kinetic wheel smoothing.

Gotcha docket (fix where a plan exists; else design around):

- The child is laid out at FULL height every frame - fine for dozens of widgets, wrong for thousands of rows. That is exactly the line between this class and SW_LIST.

Limits to push:

- [ ] Vertical only; no horizontal scrolling.
- [ ] One child (wrap multiples in a column).
- [ ] No keyboard paging (PgUp/PgDn) yet.


## SW_LIST

Planned extensions:

- [ ] Multi-select (extending the text box's disjoint-range vocabulary to rows).
- [ ] Keyboard selection movement with scroll-into-view.
- [ ] Variable row heights via a measure agent; sticky headers.
- [ ] SW_DATA_GRID and SW_TREE build on this engine in Wave 3.

Gotcha docket (fix where a plan exists; else design around):

- The renderer is called with the row's rectangle - draw relative to the given x/y, never to the list's own origin, or scrolling will smear your rows.
- scroll_to_row before the first layout positions by arithmetic and only promises visibility once laid out - the postcondition spells it out.
- Renderer agents that allocate per row (fonts are fine, objects are not) will be felt at wheel speed; keep the hot path allocation-free.

Limits to push:

- [ ] Uniform row height (variable heights are a data-grid concern, Wave 3).
- [ ] Single selection (multi-select with ranges is queued).
- [ ] No keyboard navigation of the selection yet (arrows/PgUp/PgDn).
- [ ] No columns, headers or sorting - that is SW_DATA_GRID's charter.


## SW_SPLITTER

Planned extensions:

- [ ] Horizontal orientation; double-click the divider to reset the ratio.
- [ ] Collapse buttons on the grip; remembered ratios (app settings integration).

Gotcha docket (fix where a plan exists; else design around):

- The clamp is a real contract: set_ratio (0.05) violates a precondition under assertions rather than silently pinning - clamp in the caller if your input is user-generated.

Limits to push:

- [ ] Two panes, vertical divider only (no horizontal split or three-pane nesting sugar - nest splitters for now).
- [ ] No collapse-to-edge gesture.
- [ ] No cursor change over the divider yet (windowing cursor API pending).


## SW_MENU

Planned extensions:

- [ ] Submenus with hover-open; item icons from the drawn-glyph set; check/radio items.
- [ ] Real accelerator registration once a keymap service exists.
- [ ] Type-ahead selection while open.

Gotcha docket (fix where a plan exists; else design around):

- While a popup is open it owns the pointer; the frame echo still flushes (the heartbeat is global), so snapshots CAN photograph open menus - a hard-won property; do not reintroduce tick handling into popup phases.
- Item agents run AFTER the menu closes - a handler that opens another menu or sheet is safe and common.

Limits to push:

- [ ] No submenus yet (flyout nesting is queued).
- [ ] Hints are display-only - the shortcut text does not register accelerators.
- [ ] No icons or check marks on items yet.


## SW_MENU_BAR

Planned extensions:

- [ ] Alt-key mnemonics and arrow navigation between open menus.
- [ ] Right-aligned title zone (Help pinned right, platform-style).

Gotcha docket (fix where a plan exists; else design around):

- Do not cache SW_MENU objects and hand the same one back from a builder - the freshness law is the point; build in the function, every time.

Limits to push:

- [ ] No keyboard menu access (Alt+F mnemonics) yet.
- [ ] No overflow handling for very many titles.


## SW_STATUS_BAR

Planned extensions:

- [ ] N-zone layout hosting real widgets (progress, chips) - the app-shell footer.
- [ ] Click zones with agents (e.g. click the count to open a panel).

Gotcha docket (fix where a plan exists; else design around):

- Mid-flow placement floats the bar among content - almost never what you want; use the spacer idiom.

Limits to push:

- [ ] Two zones only; no per-zone widgets (chips, progress) yet.
- [ ] Text does not ellipsize; very long messages overlap in narrow windows.


## SW_TOOLBAR

Planned extensions:

- [ ] Drawn icon glyphs (R7-pure), with labels demoted to tooltips.
- [ ] Overflow menu; vertical orientation for tool rails.
- [ ] Radio-style exclusive toggle groups.

Gotcha docket (fix where a plan exists; else design around):

- is_tool_on of an unknown or plain (non-toggle) label is simply False - no error; typos read as 'off'. Name toggles carefully.

Limits to push:

- [ ] Text labels only until the drawn-glyph set lands (icons are the toolbar's destiny).
- [ ] No overflow chevron for narrow windows.
- [ ] By-label queries assume unique labels per bar.


## SW_DIALOG

Planned extensions:

- [ ] Do-not-ask-again check row (the one embellishment worth having).
- [ ] Enter activates the primary once focus traversal lands.

Gotcha docket (fix where a plan exists; else design around):

- Button agents run after the dialog closes; opening the next dialog from an agent is safe and sequential.
- A Void action is the idiomatic Cancel - close and do nothing.

Limits to push:

- [ ] Title/message/buttons only - no embedded widgets (that is the sheet layer's job).
- [ ] No default/cancel button semantics for Enter/Escape mapping to specific buttons (Escape simply closes).


## SW_FILE_DIALOG

Planned extensions:

- [ ] Drive/known-folder rail (Desktop, Documents, drives) on the left of the sheet.
- [ ] Multi-pattern filters with a filter dropdown; hidden-file toggle.
- [ ] New-folder button in save mode; overwrite confirm option.
- [ ] Type-to-filter riding SW_COMBO's future autocomplete.

Gotcha docket (fix where a plan exists; else design around):

- on_accept fires but does NOT close the sheet - the host closes (window.close_sheet) after taking the path. That asymmetry is deliberate: the host may validate and refuse.
- Paths normalize to the OS separator; compare with PATH semantics, not string equality against your forward-slash input.
- The dialog reads the directory at construction and on navigation - external changes are not watched; reopen to refresh.

Limits to push:

- [ ] No drive/root picker yet - it browses from the start directory; '..' stops at the drive root.
- [ ] One extension filter at a time (no '*.png;*.jpg' sets yet).
- [ ] No overwrite confirmation in save mode (the host app owns that policy for now).
- [ ] No keyboard navigation of the entry list yet (arrives with SW_LIST's).


## SW_IMAGE

Planned extensions:

- [ ] Cover and tile fit modes; sub-rect (sprite) display when the painter gains it.
- [ ] Async/deferred load for galleries; a decoder service for JPEG.
- [ ] Click-to-zoom lightbox composite (with the sheet layer).

Gotcha docket (fix where a plan exists; else design around):

- A bad path does not raise - cairo returns an error surface; the widget shows the placeholder and is_loaded is False. Check it when the path is user input.
- Forward slashes are fine in paths on Windows; prefer them in source to dodge escaping layers.

Limits to push:

- [ ] PNG only (cairo's built-in decoder); JPEG et al. need a decoder service first.
- [ ] Contain-fit only - no cover/stretch/tile modes yet.
- [ ] The full-size surface stays in memory; very large images cost what they cost.


## SW_CLIPBOARD

Planned extensions:

- [ ] Image (PNG) transfer - pairs naturally with SW_IMAGE.
- [ ] File-drop list format for the dropzone widget (Wave 3).
- [ ] Clipboard-change notification for paste-aware UI enablement.

Gotcha docket (fix where a plan exists; else design around):

- Masked text boxes never write here - copy denial is enforced in SW_TEXT_BOX, not in the clipboard.
- The clipboard is global mutable state shared with every other app; test suites doing rapid ops should assert on sentinels, not on emptiness.

Limits to push:

- [ ] Text only - no images, files or custom formats yet.
- [ ] Reads cap at 128k characters (a paste larger than that truncates).


## SW_KEYS

Planned extensions:

- [ ] Ctrl/Alt/Win queries; a snapshot record for gesture recognizers.
- [ ] A keymap/accelerator service registering app-wide shortcuts (feeding menu hints).

Gotcha docket (fix where a plan exists; else design around):

- It reads the PHYSICAL keyboard - synthetic message-based tests cannot fake it, and a human holding Shift during automated runs changes behaviour. The test bench learned this the fun way.

Limits to push:

- [ ] Shift only - Ctrl and Alt queries are trivial additions awaiting a consumer.


## SW_SPELLER

Planned extensions:

- [ ] Per-language checker selection; user-dictionary add ('Add to dictionary' menu item).
- [ ] Grammar layer if a CPU-honest engine earns its keep (Harper was surveyed; deferred).
- [ ] Push-to-talk dictation is a sibling service in waiting (whisper.cpp, R03).

Gotcha docket (fix where a plan exists; else design around):

- Masked text boxes never consult the speller - secrets are not sent to OS services. If you build custom secret fields, honor the same rule.
- Results vary by machine (user dictionaries, languages) - test suites should smoke-test the plumbing, not assert specific words.

Limits to push:

- [ ] Windows-only (documented library-wide); empty results elsewhere.
- [ ] Dictionary language follows the user's Windows language settings - not selectable per call yet.
- [ ] Word-level checking only: no grammar (evaluated and deliberately deferred - the CPU-model survey R03 has the notes).


## SW_BADGE

Planned extensions:

- [ ] Overlay anchoring: badge attached to any widget's corner (composition-layer helper).
- [ ] Semantic kind parameter (accent/success/warning) mirroring SW_CHIP.
- [ ] Auto-hide-at-zero policy flag.

Gotcha docket (fix where a plan exists; else design around):

- set_count (0) renders a pill saying 0 - hide the badge (or use the dot) when zero means nothing to say.

Limits to push:

- [ ] Standalone widget for now - no attach-to-corner-of-another-widget overlay yet.
- [ ] Danger red only; semantic kinds are a small addition awaiting a consumer.


## SW_AVATAR

Planned extensions:

- [ ] Photo avatars: circular-clipped PNG via a painter clip-to-circle primitive.
- [ ] Presence dot overlay (with SW_BADGE anchoring).
- [ ] Avatar stacks (overlapping groups with a +N tail).

Gotcha docket (fix where a plan exists; else design around):

- The hue hash runs over the exact name string - 'Larry Rix' and 'larry rix' wear different colours. Normalize names upstream if identity matters.

Limits to push:

- [ ] Initials only - no picture support until SW_IMAGE gains clipped (circular) blits.
- [ ] Hash picks among the four theme washes; large rosters will share hues.


## SW_SEGMENTED

Planned extensions:

- [ ] Icon segments; equal-width mode; per-segment enabled flags.
- [ ] A sliding selection animation on the heartbeat.

Gotcha docket (fix where a plan exists; else design around):

- Click zones are measured with the same font the draw uses; if you restyle in a descendant, keep draw and handle_click measuring identically or zones will drift.

Limits to push:

- [ ] Text segments only (icons await the drawn-glyph set).
- [ ] No per-segment disabling yet.
- [ ] Fixed segment widths from label advance - no equalized widths option.


## SW_RATING

Planned extensions:

- [ ] Half-star precision (display first, then input by half-zones).
- [ ] Read-only mode with value caption ('4.2 (128)').
- [ ] Custom glyph agent (hearts, thumbs) over the same zone engine.

Gotcha docket (fix where a plan exists; else design around):

- star_at clamps rightward overshoot to max but returns 0 left of the field - the same truncation-toward-zero lesson SW_LIST's row_at taught, applied at birth.

Limits to push:

- [ ] Whole stars only - no half-star display or input.
- [ ] Read-write only; a display-only mode is a one-flag addition awaiting a consumer.


## SW_SKELETON

Planned extensions:

- [ ] Shape variants (disc, rect, card composite) mirroring the content they stand for.
- [ ] A faster dedicated animation tick if the heartbeat gains variable rate.

Gotcha docket (fix where a plan exists; else design around):

- The shimmer phase advances in draw - a busy window (mouse movement) shimmers faster than an idle one. Cosmetic, and honest in its own way.

Limits to push:

- [ ] Line shapes only - no circle/rect skeleton variants (avatar/image placeholders) yet.
- [ ] Shimmer advances per render (~2fps on the heartbeat): deliberate calm, not a spinner.


## SW_EMPTY_STATE

Planned extensions:

- [ ] Wrapped multi-line messages (borrowing SW_LABEL's body wrap).
- [ ] A small glyph set (search, error, offline) chosen by kind.
- [ ] Secondary action slot.

Gotcha docket (fix where a plan exists; else design around):

- The action zone is the band below the message - the glyph and title are deliberately inert so stray clicks do nothing.

Limits to push:

- [ ] One action only; the message is a single non-wrapping line for now.
- [ ] The glyph is fixed (the tray) - no glyph choices yet.


## SW_STATISTIC

Planned extensions:

- [ ] Count-up animation on the heartbeat when the value changes.
- [ ] Sparkline pairing when the Wave 4 charts cluster lands.
- [ ] Number formatting helpers (thousands separators, units).

Gotcha docket (fix where a plan exists; else design around):

- The delta's sign glyph is yours to include in the text ('+7') - the widget colours, it does not spell.

Limits to push:

- [ ] Static text values - no number formatting/animation built in.
- [ ] One delta; no sparkline pairing yet (charts are Wave 4).


## SW_INSPECTOR

Planned extensions:

- [ ] The full design is pinned in specs/S02 (Dev mode section) - reveal, metadata protocol, introspection engine, mesh physics, the two gates.
- [ ] AI narrator integration once the reveal data model exists.

Gotcha docket (fix where a plan exists; else design around):

- When it lands: reflection reads attributes, not computed queries - derived state (like is_hiding) will need the dev_note channel or explicit surfacing.

Limits to push:

- [ ] Not implemented - this page is the promise, kept visible on purpose.
- [ ] Depends on the popover/overlay primitives scheduled later in Wave 3.


## SW_ACCORDION

Planned extensions:

- [ ] Height easing on the heartbeat (open unfolds instead of snapping).
- [ ] Header accessories: badges, secondary text, per-section enabled flags.
- [ ] Lazy section builders (agents, menu-style) for expensive content.

Gotcha docket (fix where a plan exists; else design around):

- Toggling reflows everything below the accordion - inside a scrolling body that is fine; in a fixed layout give the region room or accept the jump.
- Content is measured at accordion width minus the inset; very wide fixed-width children will clip.

Limits to push:

- [ ] No open/close animation - sections snap (heartbeat easing is a future).
- [ ] Headers are text + chevron only; no per-section badges or icons yet.
- [ ] No keyboard operation until focus traversal lands.


## SW_STEPPER

Planned extensions:

- [ ] Error/warning step states (danger ring, warning fill).
- [ ] Vertical orientation for wizard sidebars.
- [ ] Optional free navigation mode for non-linear flows.

Gotcha docket (fix where a plan exists; else design around):

- set_current_step clamps rather than rejects - feeding it 99 lands on the last step silently; the contract keeps it sane either way.
- The click rule is deliberate: wire a button to advance for forward motion; do not fight the stepper to make the future clickable.

Limits to push:

- [ ] Horizontal only; fixed 120px step columns (no compact/vertical variants yet).
- [ ] Labels are single-line beneath the circles.
- [ ] No per-step error state (a failed step marker) yet.


## SW_TIMELINE

Planned extensions:

- [ ] Entry click agents (jump to the thing that happened).
- [ ] Grouped day headers; relative-time refresh on the heartbeat.
- [ ] Virtualized backing for thousands of events (SW_LIST marriage).

Gotcha docket (fix where a plan exists; else design around):

- Times are strings, not parsed values - ordering is yours; the widget draws what it is given in the order it was given.

Limits to push:

- [ ] Presentational: entries are not clickable and do not scroll internally (host it in a scroll area or accordion for long histories).
- [ ] Details are single-line; long details clip.


## SW_DRAWER

Planned extensions:

- [ ] Slide-in/out easing on the heartbeat.
- [ ] Top/bottom edges; pinnable (non-modal docked) mode.
- [ ] Standard footer slot for drawer verbs (Apply/Close).

Gotcha docket (fix where a plan exists; else design around):

- The panel rectangle is tracked so clicking the drawer's own border never dismisses it - but a click in the dimmed area always does. Centered sheets are the modal ones.
- The X only FIRES on_close - closing is the host's line (window.close_sheet), so a host may intercept (confirm unsaved changes) before closing.

Limits to push:

- [ ] No slide animation - the drawer appears (heartbeat easing is queued).
- [ ] One overlay at a time: a drawer displaces an open sheet or popover.
- [ ] Tab gutters: left and right today; Edge_top/Edge_bottom are accepted by the API but precondition-blocked until their gutters land (S04).
- [ ] Peeked drawers close on pointer-leave with no grace delay yet.
- [ ] One overlay at a time by law: dual pinned drawers await true docking (Wave 5).


## SW_POPOVER

Planned extensions:

- [ ] Anchor arrow and auto-flip placement.
- [ ] Hover-popovers (rich tooltips) sharing the dwell machinery.
- [ ] SW_INSPECTOR's reveal panel rides exactly this capability.

Gotcha docket (fix where a plan exists; else design around):

- Anchor coordinates are yours to compute - the widget's own x/y + height is the convention; there is no anchored-to-widget tracking if the layout later moves.

Limits to push:

- [ ] No pointer arrow toward the anchor yet - the panel is a plain rounded rect.
- [ ] Placement is clamp-into-window only; no automatic flip above the anchor when space below runs out.
- [ ] One overlay at a time (a popover displaces a drawer, and vice versa).


## SW_CANVAS

Planned extensions:

- [ ] Retained-layer mode (paint once to a surface, blit until invalidated).
- [ ] Key input routing when focus traversal lands.
- [ ] Wheel and pinch agents for zoomable canvases (charts, Wave 4, will want them).

Gotcha docket (fix where a plan exists; else design around):

- Paint in the given coordinates (a_x/a_y offsets), never absolute widget fields - the same rule as list row renderers.
- The paint agent runs on the heartbeat too (4/s), so ambient animation is free - and so is accidental cost if the agent allocates.

Limits to push:

- [ ] Fixed preferred height from creation (no aspect or grow-driven height yet).
- [ ] No offscreen retained layer: the paint agent runs every frame - keep it light.
- [ ] No key events routed (canvases are pointer surfaces today; focus work pending).


## SW_SHEET

Planned extensions:

- [ ] Row/column resize and scrollbars; range selection with block TSV copy/paste.
- [ ] Promotion path: CELLS_ENGINE graduates library-grade for SW_SPREADSHEET (Wave 5) - ranges, SUM/AVG/MIN/MAX/COUNT, formula bar, CSV.
- [ ] Cell renderers (semantic colouring, right-aligned numerics).

Gotcha docket (fix where a plan exists; else design around):

- A synthetic double-click without a preceding single click never focuses the sheet - real users always click first; test benches must too.
- The editor shows the FORMULA (via formula_provider) while the cell shows the VALUE - wire both agents or editing starts from emptiness.

Limits to push:

- [ ] Fixed geometry: 100x26, uniform 72x24 cells (variable sizes are SW_DATA_GRID's job).
- [ ] Single-cell selection; no ranges, no block clipboard yet (Wave 5 composite).
- [ ] The in-place editor is minimal (append/backspace/commit/cancel) - not the full SW_TEXT_BOX engine.
- [ ] No scrollbars drawn yet - wheel and keyboard only (bars come with the grid work).


## SW_DATA_GRID [G]

Planned extensions:

- [ ] Multi-select with range vocabulary; cell renderer agents (chips, bars in cells).
- [ ] O(n log n) sort for big row counts; column show/hide and reorder by drag.
- [ ] In-place typed editors per column (tier-three groundwork).
- [ ] Tree-table descendant (Wave 5) sharing this engine.

Gotcha docket (fix where a plan exists; else design around):

- Give numeric columns a key agent or they sort as text - the assault suite pins the difference with 9/30/100.
- on_select reports MODEL indices - stable across sort and filter; do not confuse them with view positions.
- The filter predicate closes over your state (a text box, say): re-call set_filter after that state changes - the grid cannot see through your closure.

Limits to push:

- [ ] Single-row selection (multi-select ranges queued).
- [ ] Uniform row height; no cell renderers yet (text via the value agent only).
- [ ] Insertion sort on the view: right for human-scale row counts; thousands-of-rows sorting is an S04 item (the DRAW is already virtualized for thousands).
- [ ] No in-place editing (by design in v1 - activation composes your editor).
- [ ] No horizontal scrollbar drawn yet (Shift+wheel scrolls X).
