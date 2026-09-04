# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] — Wave 3 in progress

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
