# simple_widgets

A drawn widget toolkit for Eiffel, above [simple_cairo](https://github.com/simple-eiffel/simple_cairo),
on pure Win32. No Vision2, no GTK, no boilerplate in application code.

The chain, deliberately mirroring WEL -> Vision2 -> app:

    simple_cairo     the substrate - full, faithful Cairo (the "WEL of drawing")
    simple_widgets   the vocabulary - runtime, theme, painter, widgets, layout
    your application intent - widgets, layout containers, agents

## What an application writes

```eiffel
create theme.make_light
create window.make ("my app", 8, 8, 900, 560, theme)
create card.make_striped (theme.success)
card.put (create {SW_LABEL}.make_body ("Hello."))
card.put (create {SW_BUTTON}.make_primary ("Do It", agent on_do_it))
window.set_root (card)
window.run
```

No externals. No coordinates. No CAIRO_CONTEXT. Colours, faces and
metrics come from the theme; positions come from the layout; behaviour
binds through agents.

## Architecture rules

- `SW_PAINTER` is the only class that touches `CAIRO_CONTEXT`. Widgets
  draw through its primitives; `painter.context` remains reachable as
  the escape hatch for custom drawing.
- `SW_WINDOW` owns the native window, the message pump, focus and
  dispatch - the one home of the inline-C runtime (`Clib/simple_widgets.h`).
- `SW_THEME` carries the tokens, with contrast as a class invariant:
  a theme whose ink fails WCAG against its surface cannot exist.
- Widgets are `SW_WIDGET` descendants: bounds, preferred size, draw,
  input hooks. Containers (`SW_ROW`, `SW_COLUMN`, `SW_CARD`) place
  children; nobody else does coordinate arithmetic.

## Platform notes

- The toolkit is Windows-only by charter (pure Win32 + simple_cairo).
- SW_SPELLER rides Windows' inbox ISpellChecker (Windows 8+): the
  spelling squiggles and suggestions are a WINDOWS-ONLY service and
  do not exist elsewhere. A future port would swap this seam for a
  portable engine (SymSpell, MIT).
- SW_CLIPBOARD, SW_KEYS and the font loader are likewise Win32
  services behind SURFACE-layer seams.

## Status

V0 - harvested from two production faces (simple_ocr_capture 1.8.0
and the simple_narrate editor): runtime, theme (light and dark),
painter, label, button, chip, card, row, column, and a demo target
(`sw_demo`) that proves the whole chain interactively.

Build:

    ec.sh test -config simple_widgets.ecf -target sw_demo
    ./EIFGENs/sw_demo/F_code/simple_widgets.exe
