# S05 — VERDICTS: the high-value targets, answered

**Date:** 2026-08-23 · **Scope decision (Larry):** "do the high value targets
and leave the rest." The ~230 remaining S04 lines stay open as the living
wishlist/limits ledger — that is a deliberate close, not abandonment. This
document answers the items where "explain why not" carries real engineering
value. Suite standing at close: **186/186**, F_code, full DBC.

Verdict vocabulary:
- **FEASIBLE-NOW** — substrate ready; an afternoon-to-days job awaiting a consumer.
- **FEASIBLE-QUEUED** — real but bounded work; named first consumer or trigger.
- **BLOCKED-ON-SUBSTRATE** — needs a named lower layer that does not exist yet.
- **BY-DESIGN** — the limit is the contract; changing it would break a law we chose.
- **MITIGATED** — the pain is handled by another route; the pure fix is not worth its risk today.
- **RESEARCH-WALL** — honestly out of reach without a project-sized effort; documented so nobody pretends otherwise.

---

## 1. THE DEPENDENCY AUDIT — EXECUTED (Larry, 2026-08-22)

Swept every ECF and source file of simple_widgets and simple_shell:

| Finding | Evidence |
|---|---|
| **Zero Gobo** anywhere | no DS_/KL_/ET_ classes, no Gobo ECF references |
| **Zero ISE libraries beyond the sanctioned three** | ECFs reference only `base`, `testing` (test targets), and simple_* — no vision2, wel, net, process, time-lib |
| DATE/TIME: **fully migrated** | zero ISE `DATE`/`TIME` uses; SIMPLE_DATE/SIMPLE_DATE_TIME throughout (the S04 audit line's "live example," confirmed complete) |
| Base-kernel file classes: **3 classes, 17 uses** | `PATH` (8) / `DIRECTORY` (7) in sw_file_dialog + sw_file_manager (browsing IS their job); `PLAIN_TEXT_FILE` (2) in sw_window's log_line |
| All Win32 C | carved to simple_shell (2026-08-23); simple_widgets is pure Eiffel |

**Verdict:** COMPLIANT under BUILD_STANDARDS ("prefer simple_* … except base,
time, testing"). Optional tightening recorded: simple_file exists
(SIMPLE_FILE/SIMPLE_FILES/SIMPLE_PATH) and could absorb the 17 base-kernel
file uses in a small maintenance pass — do it when simple_file's directory
enumeration is verified equal-or-better ergonomically, not before.

## 2. Multi-window — FEASIBLE-QUEUED (a simple_shell 2.0)

The shell's C is single-window by architecture: one static `s_shell_hwnd`,
one global event queue, one wndproc. SW_WINDOW assumes sole ownership of
focus, capture and the offscreen. The route: per-HWND context via
`GWLP_USERDATA`, queue entries tagged by window, SHELL_WINDOW instances
registered and dispatched by tag, one painter per window. Bounded but
substantial — and no current consumer (demo, OCR capture, narrate) is
multi-window. **Trigger:** the first real two-window application;
simple_studio's detached tool windows are the likely one.

## 3. Dirty-rect rendering — MITIGATED, tripwire armed

Today every input renders the full surface and blits the whole frame — and
it MEASURES healthy (last_render_ms; the 100ms slow-frame log has stayed
quiet since the frame-echo fix). True dirty-rect needs damage tracking
through the widget tree, clip-limited redraw and partial blits: real
complexity for a win that is currently ~0 at this scale. **The perf hooks
(before/after_render_actions, last_render_ms) are the tripwire:** the day a
real application logs sustained slow frames, this item reopens with data.

## 4. IME composition input — FEASIBLE-QUEUED (shell-first)

Today text arrives as WM_CHAR with surrogate pairing (R8) — CJK composition
does not happen. The route lives in simple_shell: handle
WM_IME_STARTCOMPOSITION/COMPOSITION/ENDCOMPOSITION, buffer the composition
string like the drop-path buffer, queue events for composition
updates; the text box then renders the underline run and positions the
candidate window near the caret. Bounded, well-documented Win32 territory.
**Trigger:** the first CJK-typing consumer.

## 5. UIA accessibility — RESEARCH-WALL (stated plainly)

A fully-drawn toolkit is invisible to screen readers. The honest fix is a
UIA provider surface (IRawElementProviderSimple + patterns) mirroring the
widget tree — a COM project comparable to the toolkit itself. Nobody should
pretend a lesser gesture (MSAA crumbs) is accessibility. What EXISTS and is
real: full keyboard traversal (Tab ring, arrows everywhere), theme contrast
invariants (ink_readable_on_surface >= 4.5 is CHECKED at runtime), and
text_scale. **This wall stands until the toolkit has users who need UIA,
at which point it is a funded project, not a sweep item.**

## 6. Text shaping / bidi / glyph fallback — BLOCKED-ON-SUBSTRATE (simple_shaping)

Cairo's toy text API is one face per call, no shaping, no bidi, no
fallback — R7 chose it deliberately for zero font gambling. Latin scripts
are right; Arabic/Indic are honestly wrong; missing glyphs render .notdef.
The real fix is a shaping substrate (HarfBuzz + font fallback chains)
feeding cairo glyph runs — a new simple_* library, named here:
**simple_shaping**. Until it exists, every claim above it (rich runs,
baseline alignment) inherits the block.

## 7. JPEG and image formats — FEASIBLE-QUEUED (WIC codec in simple_shell)

Cairo reads PNG only. Windows Imaging Component decodes JPEG/GIF/BMP/WEBP
to ARGB32 and is COM/Win32 — which since the carve has an obvious home:
a SHELL_IMAGE_CODEC in simple_shell yielding raw pixels, married to
CAIRO_SURFACE in simple_widgets exactly as SW_SCREEN.grab already does.
**Trigger:** the first consumer that must open a photo that isn't PNG.

## 8. Rich-text runs — FEASIBLE-QUEUED (text engine v2)

Styled spans (face/weight/color per range) change the text box's measure,
draw, caret mapping and selection geometry together — that is a v2 of the
text engine, not a patch. Find/replace bars and multi-caret ride the same
rework. The chat and prompt views are the consumers-in-waiting. Do it as
one movement when they demand it; anything smaller smears.

## 9. Submenus + menu item icons/checks — FEASIBLE-NOW

The glyph set (sweep 3) removed the icon blocker; the peek-grace pattern
(sweep 2) is exactly the open/close dwell law a hover submenu needs; the
menu already measures and places. This is the most shovel-ready item in
the ledger — first UI that wants nesting takes it.

## 10. Multi-select ranges (list / grid / tree) — FEASIBLE-QUEUED

The disjoint-range vocabulary already exists in the text engine; rows need
a selection SET plus anchor-extend (Shift) and toggle (Ctrl) plus range
events. Medium, clean, and dull — which is why it waits for its first real
consumer (batch file operations in the file manager is the likely one).

## 11. Animation system — FEASIBLE-QUEUED, with the heartbeat lesson

All motion today rides the 250ms heartbeat (marquee, shimmer, toasts) —
honest and cheap. Smooth easing needs a fast tick (~16ms) that runs ONLY
while an animation is live (SetTimer swap in the shell), a small tween
engine, and repaint coalescing. The oracle's lesson stands guard: work on
the heartbeat becomes the app's speed — a fast tick must carry nothing but
tweens. **Trigger:** the first design that needs motion to mean something.

## 12. Gradients and shadows — PARTIAL SUBSTRATE, flat is also a choice

simple_cairo already wraps gradients (CAIRO_GRADIENT — unexposed by the
painter). Gradient theme tokens are an afternoon when a design calls.
TRUE soft shadows are different: cairo has no native blur, so elevation
means stacked-alpha approximations or image blurs — cost without a design
that demands it. The flat language is a choice the theme made, not only a
limit it suffers.

## 13. Eyedropper — FEASIBLE-NOW (the carve's gift)

SW_SCREEN.grab makes desktop sampling a solved problem: grab 1x1 at the
cursor, track on move, commit on click. Before the carve this was a
project; now it is an afternoon on the color picker.

## 14. Alpha in the color picker — BY-DESIGN for theme, variant possible

Theme tokens are opaque RGB by charter (compositing over the backdrop
stays predictable). An alpha VARIANT of the picker (fourth bar +
checkerboard swatch; painter's set_color_alpha already exists) is small —
when a consumer authors translucency, not before.

## 15. Tree-table — FEASIBLE-QUEUED, first consumer already named

The grid engine (stable-sorted, virtualized) and the tree flatten both
exist; a tree-table weaves the indent column into the grid's column model.
**simple_studio's class browser is the obvious first consumer** — build it
there, against real data, then fold back.

## 16. In-place grid editors — BY-DESIGN in v1, pattern proven elsewhere

The grid's v1 law: activation composes YOUR editor. The spreadsheet has
since proven the in-cell edit pattern (buffer + commit/escape). If real
usage demands in-place editing in the general grid, port that pattern —
but the composition law stays the default; it keeps editors honest.

## 17. Log/time scales — FEASIBLE-QUEUED (siblings of SW_SCALE)

SW_LOG_SCALE (positive domains, decade ticks) and SW_TIME_SCALE (the
minute/hour/day/month ladder) share SW_SCALE's interface. Small, clean;
waits for the first chart with a genuine time axis (gantt currently
self-scales and does not need them).

## 18. Live-resize rendering purity — MITIGATED (the SEGV boundary stands)

The modal sizing loop starves any poll pump; the pure fix (render from
inside the loop) hit the EIF_THREADS dollar-callback SEGV wall, recorded
in the oracle. The mitigation stack that shipped instead — coalesced
WM_SIZE, theme backdrop brush on exposed pixels, 256px alloc stepping,
frame-echo quieting — measured the resize back to health. A future
attempt needs runtime-bracketed callbacks (eif_access discipline) or a
render thread; neither is worth the risk while the mitigation holds.

---

*Everything not named here remains in S04 as the open wishlist and limits
ledger, by decision. The sweep that produced this document closed 90 of
339 items with proofs (suites 150→186), birthed simple_shell 1.0–1.2, and
recorded its laws in the oracle.*
