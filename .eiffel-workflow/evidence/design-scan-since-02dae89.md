# Design Scan (diff mode): simple_widgets since 02dae89
# Date: 2026-10-25   Read-only; nothing compiled or run; findings are proposals.
# Subjects (changed since 02dae89 in src): sw_window.e, feature clause "Export (GW-21)", lines 204-317 at 1b7aa7c.
# Also read: testing/sw_widget_image_assault.e, simple_cairo (CAIRO_SURFACE, CAIRO_CONTEXT), simple_shell (SHELL_CLIPBOARD).
# Compared against all of src/ and testing/.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Correctness (resource, drift, contracts, semantics) | 11 | 2 | 4 | 5 |
| Abstraction / duplication | 2 | 0 | 1 | 1 |
| MI / monolith | 1 | 0 | 0 | 1 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **14** | **2** | **5** | **7** |

| # | Pri | Cat | Where |
|---|-----|-----|-------|
| 1 | HIGH | resource | widget_image never destroys its cairo context; the context keeps the surface alive |
| 2 | HIGH | resource | export_widget_png and copy_widget_image never destroy the surface they create |
| 3 | MEDIUM | D1 | Two widgets draw hover through is_hovered, so set_hover_signal (False) does not silence them |
| 4 | MEDIUM | correctness | Background is a rectangle fill, not a paint: fractional sizes leave semi-transparent last row and column |
| 5 | MEDIUM | correctness | Draw-time state left by the export draw is never refreshed, wrong for a custom a_theme or during a resize storm |
| 6 | MEDIUM | contract | No upper bound on pixel size; a failed surface violates the next precondition (or crashes lean builds) |
| 7 | MEDIUM | A5 | Surface, context and painter setup: now four copies in SW_WINDOW |
| 8 | LOW | contract | The `sized` postcondition builds a second export theme; export_margin ignores Current |
| 9 | LOW | correctness | Hover silencing is not exception safe (no rescue) |
| 10 | LOW | correctness | arrange with another painter: scroll clamp and tab strip scroll are lossy |
| 11 | LOW | semantics | Exports are viewport-only and window-level overlays are not captured; not stated in the contract |
| 12 | LOW | clipboard | copy_widget_image cannot report failure; set_image gives up silently after five attempts |
| 13 | LOW | A5 (tests) | Pixel readers and evidence_path: many copies; the new test class duplicates an inherited helper |
| 14 | LOW | M4 / MI | SW_WINDOW is 3033 lines; the export cluster is a ready side-by-side ancestor |

## Detailed Findings

### Finding 1: the cairo context is never destroyed, and it pins the surface
**Priority:** HIGH   **Category:** resource lifetime
**Where:** src/sw_window.e:233-235 (`create l_ctx.make (Result)`; no `l_ctx.destroy` anywhere in widget_image)
**Evidence:** CAIRO_CONTEXT.destroy exists (simple_cairo cairo_context.e:974). Neither CAIRO_CONTEXT nor CAIRO_SURFACE inherits DISPOSABLE or MEMORY (no inherit clause in either file), so nothing frees the native cairo_t when the Eiffel object is collected. The window destroys its own contexts explicitly (sw_window.e:2084, 2707). The native cairo_t holds a reference on its target surface.
**Failure scenario:** A Copy as image button pressed 200 times leaks 200 cairo_t objects. Worse, even after Finding 2 is fixed (the caller destroys the returned surface), cairo frees the pixel buffer only when the last reference drops, and the leaked context still holds one, so the pixels (up to ((w + 2m) * 4) by ((h + 2m) * 4) by 4 bytes, tens of megabytes for a window-sized widget at the 4.0 scale) stay allocated.
**Suggested fix:** call `l_ctx.destroy` after the final draw and before `Result.flush` (the surface stays valid).

### Finding 2: callers never destroy the exported surface
**Priority:** HIGH   **Category:** resource lifetime
**Where:** src/sw_window.e:268 (`export_widget_png`: `widget_image (...).write_png (a_path)`), src/sw_window.e:277-280 (`copy_widget_image`: `l_image` never destroyed)
**Evidence:** `widget_image` allocates a fresh native surface per call (sw_window.e:234). simple_cairo's own examples call `surface.destroy` (cairo_surface.e:15, simple_cairo.e:23).
**Failure scenario:** Each export leaks a full ARGB32 pixel buffer: a 1200 by 800 widget at scale 2 is about 15 megabytes per click. The two convenience features exist precisely to be called repeatedly. The tests never destroy either (testing/sw_widget_image_assault.e lines 41, 56, 85-86, 106-113), so the leak is invisible to the suite.
**Suggested fix:** in `export_widget_png` and `copy_widget_image`, hold the surface in a local, do the write or clipboard call, then `destroy` it. Document on `widget_image` that the CALLER owns the returned surface and must `destroy` it. Add a loop test of a few hundred exports watching process memory.

### Finding 3: hover silencing misses widgets that read `is_hovered` directly
**Priority:** MEDIUM   **Category:** D1 (drift between the hover contract and two draws)
**Where:** src/sw_data_grid.e:441 (`bar.draw (a_p, scroll_y, is_hovered and then bar.contains (hover_px, hover_py))`), src/sw_dock_host.e:764 (`if e = 0 and then is_hovered then e := edge_at (hover_px, hover_py)`, which then highlights the edge).
**Evidence:** `SW_WIDGET.shows_hover` (sw_widget.e:255-260) is `is_hovered and is_enabled and not is_hover_silenced`; the other draws use it (sw_scroll_area.e:160, sw_list.e:331, many more). Only these two draws bypass it. `widget_image` silences exactly one widget, the window's `hovered`, through `set_hover_signal (False)` (sw_window.e:243-244).
**Failure scenario:** The pointer rests on a SW_DATA_GRID scrollbar; the user triggers Copy as image on the grid. The grid is the hovered widget, `set_hover_signal (False)` is called, yet line 441 still draws the scrollbar thumb in its hover color. `test_gw21_hover_never_exports` (sw_widget_image_assault.e:59) proves the promise only for a SW_BUTTON. The same drift means `hover_silenced` (sw_widget.e:269) is ignored by those two widgets for ordinary use.
**Suggested fix:** change both sites to `shows_hover`. Add hover cases for SW_DATA_GRID and SW_DOCK_HOST (hover the scrollbar or edge, export, compare with the unhovered export).

### Finding 4: the background is a rectangle fill, so edge pixels can be semi-transparent
**Priority:** MEDIUM   **Category:** correctness
**Where:** src/sw_window.e:234 (surface size is the `ceiling` of the scaled size) and 238-239 (`fill_rect (a_widget.x - m, ..., a_widget.width + 2.0 * m, ...)` under `scale`)
**Evidence:** A new CAIRO_SURFACE starts fully transparent. The filled rectangle covers exactly (width + 2m) * a_scale device pixels; the surface is the `ceiling` of that.
**Failure scenario:** Any widget with a fractional width or height (splitter ratio, a flexible column, a label measured with shaping at a fractional advance) gets a last column and row only partly covered. In the PNG those pixels are partly transparent, so over a dark document they show as a thin dark hairline. On the clipboard, `set_image` forces alpha opaque (shell_clipboard.e:158-160), and a premultiplied half-covered pixel then shows darker, again a hairline at the right and bottom edges. The test checks only pixel (0, 0) (sw_widget_image_assault.e:47), the one pixel that is always fully covered.
**Suggested fix:** paint the background with `set_color` plus an unclipped `ctx.paint` BEFORE the scale and translate (as `render` does at sw_window.e:2255-2256), or round the logical size up to whole device pixels before filling. Extend the test to read the bottom-right pixel of an export of a fractional-size widget.

### Finding 5: draw-time state from the export draw is left behind
**Priority:** MEDIUM   **Category:** correctness (state recorded at draw)
**Where:** src/sw_window.e:245-251 (arrange and draw with the export painter, then `arrange (painter)` only; no redraw)
**Evidence:** Several widgets record geometry and metrics in `draw`, not in `arrange`, and read them for hit testing between frames. sw_chat_thread.e:884-899 says the scrollbar is "placed and sized by the theme at each `draw` (hit-testing has no painter of its own)" and `last_text_scale` is "as of the most recent `draw`". `laid_out_width`, `laid_out_size` and the shaped layouts are likewise written during draw (sw_chat_thread.e:1263-1296). `widget_image` takes any theme (`a_theme`), not only `export_theme`.
**Failure scenario:** With the default `export_theme` (which adopts the screen metrics) the leftovers match the screen. But `widget_image (chat, some_other_theme, 1.0)` (public) leaves the chat thread's scrollbar width and `last_text_scale` from that theme, so a click on the scrollbar in the next input event hits the wrong column until the following frame redraws. During a resize storm (`busy_ticks > 0`) the export painter has `is_resize_storm` False, so SW_CHAT_THREAD re-shapes every message at the current width (sw_chat_thread.e:1262-1263) and discards the layouts that rule R10 was keeping; the window painter then keeps those new layouts, so the screen layout silently changes mid-drag.
**Suggested fix:** end `widget_image` with a redraw through the screen painter when the theme differs from `theme` or a storm is active (or restrict `a_theme` with a precondition `a_theme.text_scale = theme.text_scale`). Carry `painter.is_resize_storm` onto `l_painter` with `set_resize_storm`. Add a test: export a chat thread in a theme with another text scale, then hit-test the scrollbar before any render.

### Finding 6: no upper bound on the surface; failure is a precondition violation or a crash
**Priority:** MEDIUM   **Category:** contract
**Where:** src/sw_window.e:216-217 (`scale_sane` bounds only the scale), 233-235
**Evidence:** `create Result.make (w, h)` can fail for a large size (cairo caps an image surface near 32767 pixels per side and the allocation can fail first); CAIRO_SURFACE.make states `handle_set: handle /= default_pointer implies is_valid` (cairo_surface.e:38), so an invalid surface is a documented outcome. `CAIRO_CONTEXT.make` then requires `surface_valid` (cairo_context.e:35).
**Failure scenario:** `copy_widget_image` on a 9000-pixel-high document view child at scale 4.0 asks for a 36000-pixel surface: with contracts on, a precondition violation inside the library; in a lean release build, a null handle passed into cairo.
**Suggested fix:** add a precondition bounding the device size (a constant, about 16384 per side), or scale down to fit, or return a detachable surface (Void when it cannot be made) and let the wrappers return False.

### Finding 7: surface, context and painter setup is now copied four times
**Priority:** MEDIUM   **Category:** A5 (duplicated body)
**Classes:** SW_WINDOW
**Evidence:** sw_window.e:87-89 (`make`: create_surface, ctx, painter), 2084-2088 (`resize_surface`: destroy both, rebuild the three, `set_shaping`), 695-696 (theme swap: new painter, `set_shaping`), 233-237 (`widget_image`: surface, context, painter, `set_shaping`). Three of the four repeat the pair `create painter.make (ctx, t)` plus `painter.set_shaping (shaping)` (`make` runs before a kit exists). `set_resize_storm` at 2254 is a further place where painter state must be kept in step, and `widget_image` does not do it (Finding 5).
**Description:** a live drift risk: the painter gained `set_shaping` (GW-03) and `set_resize_storm` (R10), and every site must be updated; `widget_image` carries one and not the other.
**Suggested action:** one `new_painter (a_ctx: CAIRO_CONTEXT; a_theme: SW_THEME): SW_PAINTER` in a `{NONE}` clause that creates, sets shaping and carries the storm flag; use it at all four sites. Effort: 1 feature, 4 call sites.

### Finding 8: `sized` builds a second theme; `export_margin` is a theme query hosted on the window
**Priority:** LOW   **Category:** contract
**Where:** src/sw_window.e:253-254 (`sized`), 294-301 (`export_margin`)
**Evidence:** `export_theme` creates a new light theme and adopts metrics whenever `exports_in_screen_theme` is False (sw_window.e:285-289). The postcondition calls `export_theme` when `a_theme` is Void, so each Void-theme export builds the theme twice with contracts on (once in `do`, once in `ensure`), and the second is a different object. The margin is equal by construction, so this is wasteful rather than wrong; the string copies in `adopt_metrics_from` (sw_theme.e:472-474) make it not free. The test adds three more calls per case (sw_widget_image_assault.e:44-45).
**Failure scenario:** allocation churn in contract builds, and a trap for a future theme whose margin differs between instances.
**Suggested fix:** move the margin to SW_THEME (`export_margin` is `a_theme.border_width` and does not use Current) and compute the postcondition from a value stored during `do`.

### Finding 9: hover silencing is not exception safe
**Priority:** LOW   **Category:** correctness
**Where:** src/sw_window.e:241-250
**Evidence:** `set_hover_signal (False)` at 244, restoration at 249; nothing between them is protected by `rescue`. A draw that raises (a contract violation in any child draw, exactly what the assault suite provokes) skips the restore.
**Failure scenario:** after a failed export the hovered widget's hover feedback stays off for the rest of the session (`is_hover_silenced` stays True), with no visible cause.
**Suggested fix:** restore in a `rescue` clause (set a local flag first) and re-raise, or through a small wrapper routine that always restores.

### Finding 10: arrange with a second painter has lossy side effects
**Priority:** LOW   **Category:** correctness
**Where:** src/sw_window.e:246 and 251; effects at sw_scroll_area.e:139-140 (`scroll_y := scroll_y.min (max_scroll)`, `scroll_x`), sw_paragraph_list.e:913 and 934, sw_tabs.e:513 (`first_visible := first_showing (...)`)
**Evidence:** `arrange` is not pure: scroll areas clamp their scroll position and the tab strip moves `first_visible`. No arrange in src fires an event or user action (checked sw_splitter, sw_dock_host, sw_dock_zone, sw_tabs, sw_accordion, sw_drawer, sw_group, sw_status_bar, sw_scroll_area), so there is no event hazard; what remains is that a clamp done under the export painter is not undone by the second arrange.
**Failure scenario:** only when `a_theme` has different metrics (the default export theme adopts them, so measures match): the content is measured smaller, the scroll position is clamped, and the on-screen widget jumps on the next frame.
**Suggested fix:** none needed for the default theme; disappears if Finding 5 restricts `a_theme` to metric-compatible themes. Otherwise save and restore scroll positions.

### Finding 11: what an export is, and is not
**Priority:** LOW   **Category:** semantics (documentation and contract wording)
**Where:** src/sw_window.e:206-217 (header comment)
**Evidence and scenarios (all follow from drawing `a_widget.draw` alone):**
- Window-level overlays are not in the image: popup menu, sheet and drawer content, toasts, the pick-and-drop trajectory (`draw_pick_trajectory`, sw_window.e:2264-2266), hover card. Right for popups and trajectory. A widget that IS sheet content is exported on `background`, while the screen shows it on the sheet panel `surface` (sw_window.e:2287); likewise a card on its parent. Cosmetic.
- Virtualized widgets export their viewport only: SW_DATA_GRID, SW_LIST and SW_CHAT_THREAD draw only the rows inside their own bounds and scroll position (sw_list.e:312, sw_data_grid.e:366-442). That is a faithful picture of what is on screen, but the header says "drawn alone" and not "as scrolled".
- A widget inside a SW_SCROLL_AREA that is partly scrolled out exports in full (the ancestor clip, sw_scroll_area.e:155-159, is not applied).
- Nothing in src clips to window coordinates in a way the translate breaks (every `push_clip` uses widget coordinates such as `x, y, width, height`), and no widget reads the window theme or window size in `draw` (searched src outside sw_window.e; none found).
- SW_SHAPING layout memo is keyed on text, width, pixel size, role and bold (sw_shaping.e:422) and is cleared on `policy_revision` change (182-184); colors are applied at paint time, so sharing one kit between the screen painter and the export painter is safe. SW_SHAPED_TEXT keeps no cache of its own (class note, 0.28.2).
- Custom accent or palette overrides on the screen theme are lost in the light export (only metrics are adopted, sw_theme.e:456-475). Fine for "paste into other documents"; worth a sentence.
**Suggested fix:** state the viewport and overlay behavior in the feature comment; optionally a later full-content export for scrollable widgets.

### Finding 12: the clipboard path cannot say it failed
**Priority:** LOW   **Category:** clipboard
**Where:** src/sw_window.e:277-280; shell_clipboard.e:154-180 in simple_shell
**Evidence:** `set_image` loops up to five times with a 10 millisecond sleep, then returns normally whether or not it succeeded (the `c_clip_set_image (...) = 1` result is only a loop exit). `copy_widget_image` is a command with no result.
**Failure scenario:** a clipboard history manager holds the clipboard longer than 50 milliseconds; the user sees nothing on paste and no message. `test_gw21_png_reads_back_and_clipboard_takes_it` (sw_widget_image_assault.e:98-114) asserts `has_image` and is exposed to the same race on a busy machine.
**Suggested fix:** make `copy_widget_image` return BOOLEAN (from a `set_image` that returns BOOLEAN, a simple_shell change) and let the test tolerate a busy clipboard. Premultiplied alpha is not a problem apart from Finding 4: the background fill makes the surface opaque, and stride and data pointer are used as the clipboard contract states.

### Finding 13: test-side duplication
**Priority:** LOW   **Category:** A5 in testing
**Where:** testing/sw_widget_image_assault.e:156-166 (`pixel`), 168-182 (`same_pixels`)
**Evidence:** the class inherits SW_SHAPING_ASSAULT, which already offers `pixel_at` (testing/sw_shaping_assault.e:1670-1678, with a range precondition), so `pixel` is a second private reader in the same class tree. The same read (`share_from_pointer` plus `read_natural_32` at `y * stride + x * 4`) appears in sw_label_shaping_assault.e:358, sw_menu_shaping_assault.e:425, sw_chrome_assault.e:381 and sw_deepening_assault.e (349, 641, 877). `evidence_path` exists in eight test classes (sw_chat_mutation, sw_chat_scroll, sw_chat_text, sw_keyboard, sw_label_shaping, sw_margins, sw_menu_shaping, sw_shaping assaults). `pixel` calls `flush` on every read, so `same_pixels` flushes width times height times two.
**Suggested action:** a deferred test ancestor (for example SW_PIXEL_KIT) holding `pixel_at`, `same_pixels`, `ink_in`, `evidence_path`, inherited side by side with TEST_SET_BASE by those classes (Larry's MI rule). Effort: 4 features, about 10 classes. A refactor-branch job, not part of a feature branch.

### Finding 14: SW_WINDOW is 3033 lines; the export cluster is a clean side-by-side ancestor
**Priority:** LOW   **Category:** M4 / MI
**Where:** src/sw_window.e (3033 lines); export feature clause at 204-317
**Evidence:** the export features need only `theme`, `shaping`, `painter` and the hover pair (`hovered` is in the `{NONE}` state clause). They have no dependency on events, sheets or native handles.
**Suggested action:** `SW_WIDGET_EXPORTING`, a deferred class declaring the theme, shaping, painter and hover-silencing hooks and effecting `widget_image`, `export_widget_png`, `copy_widget_image`, `export_margin`, `exports_in_screen_theme`; SW_WINDOW inherits it next to SHELL_WINDOW. It also lets headless tools export without a window. Worth doing only together with Finding 7 (`new_painter`).

## Checked and found clean

- `stays_put` postcondition is sound: arrange does not move the arranged widget itself (SW_DRAWER and SW_GROUP shift `y` and `height` temporarily and restore them, sw_drawer.e:69-75, sw_group.e:57-63).
- No arrange fires events or user actions (Finding 10 list).
- Other render paths: `render` (2248), `write_frame` (480), frame echo (2557), `blit` (2690). `widget_image` correctly does not reuse `render` (it would draw the whole window). `write_frame` writes the full allocated offscreen (allocation size, up to 255 pixels beyond the window), a pre-existing quirk, not new.
- Hover restore keeps a caller-silenced widget silenced (`l_was_silenced`), correct.
- Focus is deliberately kept, with no event fired; correct and stated in the header.
- Scale bounds: contract keeps scale within 1.0 to 4.0; the only gap is the device size (Finding 6).

## Recommended Order

1. Findings 1 and 2 together (destroy the context and the surface; one small change plus a leak test).
2. Finding 3 (two one-word fixes plus a hover test on the grid).
3. Finding 4 (background paint) and Finding 6 (size bound), both contract-visible.
4. Finding 5 (state left by the export draw), with Finding 7 `new_painter` carrying the storm flag.
5. Findings 8 to 12 as cleanup; Findings 13 and 14 on a refactor branch only on Larry's word.

