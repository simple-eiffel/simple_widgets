# S03 — The Appearance Model

*2026-08-22. Canonized from the five-vector decomposition agreed with
Larry, cross-checked against GTK/Flutter/WPF/LVGL/CSS (S01 research).
Every vector has a named home in the library and carries contracts.*

## The equation

    appearance = structure(parts)
               x style(kind, state -> token choices)
               x theme(token -> value)

Layout is deliberately OUTSIDE this equation: rows, columns, gaps and
alignment take no tokens, so swapping a theme can never move anything.

## The five vectors, as implemented

| Vector | Definition | Home in simple_widgets |
|---|---|---|
| THEME | State-independent vocabulary of named values: colours, type roles, metrics, radii. | SW_THEME. Programmable via set_surfaces / set_semantics / set_washes / set_families; light and dark shipped; TOML themes planned. WCAG contrast is a class INVARIANT: an unreadable theme cannot exist. |
| STRUCTURE | The parts a control is made of. | Per-part draw features: SW_BUTTON.draw_background / draw_border / draw_label. Redefining a part feature is this library's ControlTemplate - and inherited contracts survive the reskin. |
| STYLE | The rules assigning tokens to parts, keyed by (kind, state). | Style queries: SW_BUTTON.fill_color / border_color / label_color (theme): NATURAL_32. A descendant restyles by redefining a QUERY, never a draw body. |
| STATE | Dynamic, machine-driven condition. | SW_WIDGET: is_enabled, is_hovered, is_pressed, is_focused - maintained by SW_WINDOW (hover via pump mouse-move/leave events, pressed via pointer capture, focus via click transitions). Contract: pressed_only_when_enabled. Disabled widgets are inert: dispatch bubbles PAST them. |
| VARIANT | Static, author-chosen role of a control. | The `kind` query (the natural word is an Eiffel keyword): SW_BUTTON Kind_normal / primary / quiet / danger; SW_CHIP Kind_neutral / accent / success / warning / danger. Fluent: as_kind. |

## Rules of the model

1. No literal colour below the theme. A widget names tokens only.
2. No token below the style queries. Draw parts call the queries.
3. State setters live on SW_WIDGET; only SW_WINDOW calls them.
4. Kind never changes from input; state never changes from the author.
5. Layout containers take no tokens and no states beyond geometry.

## The pocket rule

If it survives a rebrand it is structure; if a rebrand changes it,
theme; if it decides who wears what when, style; if the user causes
it, state; if the author chose it, kind; if it moves things, layout.

## Proven

- Theme swap live (Dark / Light button), zero widget edits.
- Hover: pump events 13/14 (coalesced moves + TrackMouseEvent leave),
  hover fill renders on entry.
- Pressed: capture-held frame shows wash fill while the button is
  physically down; state clears on release.
- Danger kind renders from the same three style queries.
- Keyword lesson recorded in the oracle: variant -> kind.
