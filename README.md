# simple_widgets

[Documentation](https://simple-eiffel.github.io/simple_widgets/) •
[GitHub](https://github.com/simple-eiffel/simple_widgets) •
[Issues](https://github.com/simple-eiffel/simple_widgets/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)
![Tests](https://img.shields.io/badge/tests-109%2F109-brightgreen.svg)

A drawn widget toolkit for Eiffel on pure Win32 — no Vision2, no GTK, no native
controls. Every pixel is the toolkit's own.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

🚀 **Waves 1–3 COMPLETE, Wave 4 OPENED** — 73 classes (68 library + 5 devkit tooling)
- Wave 4's Cartesian suite is in: SW_SCALE axis engine + line/bar/area/scatter,
  pie/donut + funnel; the demo's line chart streams live frame costs off
  the render bell
- 109 contract-assault tests passing
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
simple_cairo      the substrate   (canvas, text, PNG)
simple_widgets    the vocabulary  (window runtime, theme, painter, 59 controls)
your application  the intent      (what exists and what happens)
```

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

# the contract assault (109 tests, all assertions live)
/d/prod/ec.sh test -config simple_widgets.ecf -target simple_widgets_tests
cp $SIMPLE_EIFFEL/simple_cairo/cairo.dll EIFGENs/simple_widgets_tests/F_code/
./EIFGENs/simple_widgets_tests/F_code/simple_widgets.exe
```

## Roadmap

Wave 3 is nearly closed (tree, data grid, calendar/date/time pickers,
drawers with peek-and-pin, popovers, accordion, stepper, badges, avatars,
canvas, sheet, colour picker — all shipped); **Wave 3 is COMPLETE**: SW_DROPZONE
(real Explorer drags land) and the dev-mode suite closed it:
SW_INSPECTOR reveals, the SW_MESH force graph, and SW_DEV_STUDIO
(mesh + live pane, floating sheet or docked drawer with the page
still live) — all devkit-only classes, compiled out of release-shaped
builds via the ECF override cluster and PROVEN absent by binary scan.
Then Wave 4 charts on
SW_PAINTER, Wave 5 enterprise composites (spreadsheet doctrine:
SHEET -> DATA_GRID -> SPREADSHEET; true docking), Wave 6 media +
conversational (dictation via whisper.cpp queued as a text-box service).

**The full plan:** [What's Still Coming](https://simple-eiffel.github.io/simple_widgets/roadmap.html)
— per-wave detail; `specs/S04-ROADMAP.md` is the per-control checkbox
docket, harvested from the doc pages so the two cannot drift.

## License

MIT — see [LICENSE](LICENSE).
