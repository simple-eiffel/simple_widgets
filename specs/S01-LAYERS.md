# S01 — The Layer Architecture of simple_widgets

*2026-08-21/22. Written against a survey of how six production toolkits
layer abstraction above a 2D canvas: GTK 3/4 (Cairo's own child), Flutter,
Dear ImGui/egui, Qt Quick/QML, WPF/XAML, and LVGL. Each claim below names
its precedent.*

## 0. The charter (Larry, 2026-08-21, verbatim)

- "We could investigate how other Windows software uses Cairo and abstracts
  widgets as well. We might learn something from them and we might be able
  to not re-invent the wheel."
- "The idea is to get as simple high level of abstraction without losing
  the full strength of Cairo and what it can do."
- "Perhaps the solution is to create abstraction layers where layers of
  classes are designed to live at higher-to-lower levels of abstraction.
  The lower you go, the more expressive power you get, but at the cost of
  writing a lot of boilerplating code. The higher you go, the less complex
  and faster product can be built."

That third note IS the architecture. This document names the layers.

## 1. The five layers

Higher = simpler and faster to build with. Lower = more expressive, more
code. Every layer is directly usable; nothing forces an application to
enter at the top.

| # | Layer | Owns | Who lives here |
|---|-------|------|----------------|
| 5 | COMPOSITION | Assembly in plain Eiffel: creation expressions, agents, fluent setters. Future scaffolds (SW_APP, SW_FORM). Never a second language. | App authors, by default: a working window in ten lines. |
| 4 | COMPONENT | The shipped controls: SW_LABEL, SW_BUTTON, SW_CHIP, SW_CARD, SW_TEXT_BOX; later SW_LIST and friends. Behaviour and drawing together; every visual from theme tokens. | App authors composing directly. |
| 3 | WIDGET | SW_WIDGET, SW_ROW, SW_COLUMN: geometry, the one-pass layout protocol, hit testing, input bubbling and capture, focus, the parent spine. | Widget authors: a new control = one class implementing preferred_height + draw + input hooks. |
| 2 | PAINTER | SW_PAINTER + SW_THEME: the Cairo monopoly. Themed drawing verbs, text measurement, tokens with WCAG contrast as a class invariant. painter.context is the marked escape hatch. | Widget authors normally; an app may borrow a painter alone for one custom region. |
| 1 | SURFACE | SW_WINDOW's Win32 half + simple_cairo: HWND, pump, offscreen surface, blit, fonts, logical events. Clib/simple_widgets.h lives here and nowhere else. | Toolkit maintainers. Applications: only when embedding. |

Precedents per boundary: SURFACE = GDK / Flutter engine / LVGL HAL.
PAINTER = GtkSnapshot / egui Painter / WPF DrawingContext. WIDGET =
Flutter RenderBox / lv_obj / QQuickItem. COMPONENT = Material / Qt Quick
Controls / LVGL widgets. COMPOSITION = Flutter build() - and deliberately
NOT QML or XAML (rule R1).

## 2. Standing rules

R1 — **One language.** Qt documents the damage of the QML/C++ seam in its
own best-practices pages; WPF and GTK templates pay smaller versions of
the same tax (magic strings, runtime-only checks). Flutter is the control
group: one language, the pleasantest top layer of the six. Composition
stays Eiffel expressions + agents. Design-time JSON (eiffel-gui-ux) is an
artifact; the runtime API never grows a loader.

R2 — **The painter monopoly.** Only SW_PAINTER touches CAIRO_CONTEXT.
GTK4 proved the payoff: because widgets drew through GtkSnapshot rather
than raw cairo, GTK swapped its whole rendering pipeline (immediate to
recorded render nodes to GPU) with widget code barely changing. Our
painter can one day record and damage-track with zero widget edits.
Applications keep the same power through painter.context - the hatch is a
feature, not a leak.

R3 — **No property cascade until a third party needs one.** WPF's
dependency-property precedence ladder and LVGL's style cascade exist so
strangers can restyle controls they cannot edit; their shared cost is
value resolution as invisible control flow ("where did this value come
from?"). With widgets we own and a theme we own: widget reads token,
descendant redefines a draw feature. Eiffel's feature redefinition with
inherited contracts IS our ControlTemplate (parts-and-states, per LVGL /
Qt Quick Controls naming), and it is checked by the compiler.

R4 — **Layout is one pass, stated as contracts.** Flutter's "constraints
go down, sizes up, parent sets position" guarantees O(N) and no
reflow loops. Ours: parent asks preferred_*, parent set_bounds, parent
arrange - never re-entrant; postconditions pin children inside parents.

R5 — **Input bubbles; the press captures.** Handlers return handled;
unconsumed clicks climb the parent spine (LVGL's opt-in bubble, WPF's
Handled flag - minus WPF's tunneling pair, which this scale does not
need). The widget that accepts a press owns the pointer until release
(Qt Quick's exclusive grabber, ImGui's active id) - the pointer never
follows keyboard focus. Implemented 2026-08-22 and proven by synthetic
drag-selection.

R6 — **Respect the retained iceberg.** ImGui's ledger: text editing is
the hairiest code in any toolkit (caret, selection, undo, IME), and
accessibility structurally requires a persistent tree (egui rebuilds one
per frame for AccessKit). We are retained - so keep SW_WIDGET's tree,
focus and geometry rich enough that a future UIA bridge can walk it, and
grow SW_TEXT_BOX's edit state as contracted classes, never as "a rect
with text".

R7 — **Nothing native. We draw everything.** (Larry, 2026-08-22,
verbatim: "native anything is NOT in the cards for simple_widgets.
We draw everything ourselves.") No TrackPopupMenu, no common
dialogs, no MessageBox: every control, menu, and dialog is drawn by
the toolkit on its own surface - which also makes every one of them
testable from the frame echo, where native surfaces never were. OS
SERVICES with no pixels (clipboard, fonts, DPI, file SYSTEM access)
remain fair game; OS-drawn WIDGETS do not. The one pixel-bearing
exception is the window frame itself, until SW owns borderless
chrome.

## 3. What tonight's V0 already honours

- Painter monopoly (R2) - built in from the first commit.
- Semantic tokens with contrast invariants (SW_THEME) - something none of
  the six surveyed systems can promise in their type system; Design by
  Contract is the differentiator here.
- One-pass layout protocol (R4) - preferred_width / preferred_height
  (painter, width) / arrange, containers place children.
- Bubble + capture dispatch (R5) - handled BOOLEANs, parent spine,
  pointer capture between press and release.
- One language (R1) - the demo is ~95 lines of plain Eiffel.

## 4. Next steps, in the order the consumers force them

1. SW_TEXT_BOX polish: undo hooks (simple_undo when it exists), clipboard,
   scroll-into-view for long texts (R6).
2. Parts-and-states drawing convention inside components (R3) as SW_BUTTON
   grows hover and pressed states - needs mouse-move tracking without a press.
3. Dirty-rectangle invalidation in SW_WINDOW (R2's first dividend).
4. SW_LIST with virtualization - the narrate block list is the forcing
   consumer.
5. Port the narrate face to simple_widgets; then the ocr face when its
   door reopens. Success test: same pixels, app files shrink to intent.
