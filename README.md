# simple_widgets

[Documentation](https://simple-eiffel.github.io/simple_widgets/) •
[GitHub](https://github.com/simple-eiffel/simple_widgets) •
[Issues](https://github.com/simple-eiffel/simple_widgets/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)
![Tests](https://img.shields.io/badge/tests-213%2F213-brightgreen.svg)

A drawn widget toolkit for Eiffel on pure Win32 — no Vision2, no GTK, no native
controls. Every pixel is the toolkit's own.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

✅ **ALL SIX WAVES SHIPPED** — 103 classes (97 library + 5 devkit + 1 speechkit)
- Wave 5 (all 11 composites): tree table, spreadsheet doctrine whole,
  pivot, kanban, scheduler, gantt, file manager, query builder, form
  generator, org chart, TRUE DOCKING with collapsing reflow zones
- Wave 4 (all 15 concepts): SW_SCALE axis engine, line/bar/area/scatter,
  pie/donut + funnel + legend, gauge + sparkline, heatmap + treemap, sankey,
  world map (markers + UTC bands), force diagram, and the timezone tools
  (pickable band map + live world clock); the demo streams live
  frame costs into four instruments off one render-bell subscription
- 213 contract-assault tests passing
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
denial), combo (an editable dropdown that IS a text box), select, check box,
switch, radio group, slider, number box, progress, chips.

**Layout** — row/column containership unifying Vision2's model with flex
(grow / min / max), card, titled group, separator, spacer (the pinned-footer
idiom), splitter (contract-clamped ratio).

**Data & chrome** — virtualized list (10,000 rows scroll like ten; selection,
double-click activation, per-row pick-and-drop pebbles), scroll area, tabs,
drawn menus (built fresh on every open), menu bar (builder agents), toolbar
(toggles queried by label), status bar.

**Dialogs & media** — drawn modal alerts, a complete drawn **file dialog**
(open/save, dirs-first listing, extension filter — base PATH/DIRECTORY only),
PNG display with contain scaling; a shell-drop zone (WM_DROPFILES
through the widget spine to any opted-in control).

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

### Known limits

- `SW_LABEL`, `SW_BUTTON` and the rest of the chrome still draw through
  `SW_PAINTER.text`. Their `preferred_width` / `preferred_height` are cairo toy
  advances, and every layout in the toolkit is measured from them, so swapping
  their metrics is a separate, wider change — not a small safe one.
- One kit per window, per SCOOP processor. A background processor that wants to
  measure text creates its own.

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
`clamped_height`. Measured at 1x → 2x: button 38 → 75, text box 42 → 80, check
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
