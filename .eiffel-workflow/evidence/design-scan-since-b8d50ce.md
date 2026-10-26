# Design Scan (diff mode): GW-22 floating panels
# Since: simple_shell ed45551..6526d80 (1.23.0), simple_widgets b8d50ce..c9db626 (0.39.0)
# Read-only. Subjects: sw_floating_window, sw_pointer_routing, sw_window, sw_dock_host, sw_dock_zone, shell_panel, simple_shell.h
# Not compiled, not run; every finding is from reading the diff and the current files.

## Summary
HIGH 4, MEDIUM 8, LOW 7.

| # | Sev | Where | Title |
|---|-----|-------|-------|
| 1 | HIGH | sw_floating_window.e:295-319 vs sw_window.e:1766-1772 | D1: accelerator fires twice (key-down, then trailing WM_CHAR); the floating copy lacks `swallow_next_char` |
| 2 | HIGH | sw_floating_window.e:128-145 | `close` never destroys offscreen surface, context or painter: a cairo surface leaks per float/unfloat cycle |
| 3 | HIGH | sw_dock_host.e:382-394, 596-700, 400-405 | A floating panel can be re-shown or re-zoned by `show_panel`, `restore_layout`, `move_panel`: content drawn by two parents |
| 4 | HIGH | sw_window.e:601-612, simple_shell.h:1518-1530 | Floating windows and their shell slots are never closed when the owner's `run` ends |
| 5 | MEDIUM | sw_window.e:392-418 | `float_dock_panel` leaves main-window `focused`/`hovered`/`capture` pointing at the content now in another window |
| 6 | MEDIUM | sw_floating_window.e:34-64, 128-145 | `make` allocates cairo objects even when the panel did not open; `close` leaves `capture` pressed |
| 7 | MEDIUM | sw_window.e:451-461, 635, 2491 | Every main frame re-lays-out, redraws and blits every floating window, dirty or not |
| 8 | MEDIUM | sw_floating_window.e:156-158 | Every WM_SIZE (48) triggers a full main-plus-all-floats render; the queue does not coalesce 48 |
| 9 | MEDIUM | sw_floating_window.e:241-321 vs sw_window.e (route_key_down, press) | A2/A5: input state and itinerary copied, SW_POINTER_ROUTING absorbed only the stateless walks |
| 10 | MEDIUM | sw_floating_window.e:163-164 | Deactivation leaves the floating focus ring drawn beside the main window's; two focused widgets |
| 11 | MEDIUM | sw_window.e:287-310 | Floating trees are never published to screen readers; node ids resolve to nothing |
| 12 | MEDIUM | simple_shell.h (48), shell_panel.e:201-233 | Event 48 means outer size for plain panels, client size for framed; `panel.width/height` go stale |
| 13 | LOW | sw_window.e:717-724 | `dispatch` reads `event_extra`: stale when `dispatch` is called directly |
| 14 | LOW | sw_floating_window.e:149-169 | Events 47/49/50 and right press 46 are dropped silently; file drops never drained |
| 15 | LOW | sw_floating_window.e:104-114 | Default `on_close_request` is Void: the close box does nothing |
| 16 | LOW | sw_window.e:407-412 | T1: 160, 32, 320, 200, +32 magic numbers; caption height guessed; screen coordinates ignore owner and monitor |
| 17 | LOW | sw_dock_host.e:469-480, layout_snapshot | Floating state is not in the snapshot; a floating panel is saved as hidden |
| 18 | LOW | simple_shell.h:1204-1215 | WM_MOUSELEAVE and WM_LBUTTONDBLCLK cases apply to plain panels too (harmless today, unguarded) |
| 19 | LOW | sw_floating_window.e:149-169 | Resize, activate and close-request bypass the modal-dialog guard |

## Detailed Findings

### 1. HIGH (D1) Accelerators run twice in a floating window
Evidence: `SW_WINDOW.key_down_accelerator_fired` (sw_window.e:1766-1772) sets `swallow_next_char := True` after the table fires, and the char arm (sw_window.e:2101-2114) swallows the trailing control-code WM_CHAR. `SW_FLOATING_WINDOW.handle_input` key arm (sw_floating_window.e:297) calls `owner.fire_accelerator` directly, so nothing is armed. The shell pushes 61 for every WM_CHAR of a framed panel (simple_shell.h:1226-1230), including the control code behind Ctrl+letter. The char arm (sw_floating_window.e:311-313) then calls `owner.claims_char_accelerator` -> `char_accelerator_fired`, which runs the same accelerator again. A toggle accelerator (Ctrl+B) is a no-op; Ctrl+W closes twice. `test_gw22_a_floating_window_takes_input_like_the_main_one` exercises keys and chars separately, probably not the pair.
Fix: put the key-then-char pair in one place. Route the float's key arm through `owner.key_down_accelerator_fired` (export to SW_FLOATING_WINDOW) and keep the swallow flag on the owner, or move the flag into the shared ancestor of finding 9. Add a test that sends 60 then 61(0x17) and counts accelerator runs.

### 2. HIGH Cairo surface leak on every close
Evidence: `make` creates `offscreen` and `ctx` (sw_floating_window.e:56-57) and `resize` destroys the old pair (:382-383), but `close` (:128-145) destroys neither, and the class has no `dispose`. `unfloat` (sw_window.e:353-358) only prunes the list. Each float/unfloat leaves an `alloc_w x alloc_h` ARGB surface (e.g. 1280x800 is about 4 MB) plus the context.
Fix: in `close`, `ctx.destroy` and `offscreen.destroy` once (guard with a `is_released` flag; ensure it), or build the window with a shared SW_OFFSCREEN_SURFACE helper (finding 9) that owns destroy. Contract: `closed` ensure that `is_open` is False and the surface is released.

### 3. HIGH Floating panel re-parented or re-zoned behind the float's back
Evidence: `float_panel` (sw_dock_host.e:513-521) keeps the panel in `panels` with `is_visible := False` and `content.parent = Void`. Nothing stops later calls:
- `show_panel` (:382-394) has no `not is_floating` precondition; it sets `is_visible` and `active_ids`, so the zone draws the content while the float still draws it. Both call `arrange`/`set_bounds` on the same widget in one frame; the float renders last, so the main window's hit test (`widget_at`) sees the float's bounds.
- `restore_layout` (:596-700) assigns `panels.i_th(id).is_visible := e.shown` directly, same result. A snapshot taken while floating says "hidden", so the common case is safe; a snapshot taken earlier is not.
- `move_panel` (ensure at :366) changes the zone of a floating panel, which `redock_panel` then trusts.
Fix: add `not is_floating (a_panel)` to `show_panel`/`move_panel`; in `restore_layout` skip `is_visible` for floating keys (or call `redock`-free hide); add `redock_all`/`floating_count` query. Invariant: a panel whose key is in `floating_keys` is not visible and `content.parent = Void`.
Related, LOW: `remove_panel` (:400-405) forgets the key but the float keeps the content; closing the float then finds `panel_by_key = 0` and merely unfloats. Acceptable, but a later `add_keyed_panel` with the same key would be redocked by the stale agent.

### 4. HIGH Owner death leaves floats and slots
Evidence: `run` (sw_window.e:601-612) returns from `shell_run` and does nothing to `floating_windows`. The framed panels are owned by the main hwnd, so Windows destroys the HWNDs, but `s_shell_panel[slot]`, `s_shell_panel_framed[slot]` stay set (simple_shell.h shell_panel_close is the only reset, :1516-1530). `shell_panel_hwnd` then answers a dead HWND, and `SW_FLOATING_WINDOW.is_open` still reports True. A second SW_WINDOW in the same process (tests do this) finds fewer free slots, and any later `panel.close` calls DestroyWindow on a handle that may have been reused.
Fix: after `shell_run` returns, `across floating_windows` call `close`, then wipe the list (ensure `floating_windows.is_empty`). In simple_shell, `shell_window` teardown should close every slot whose HWND `IsWindow` is false.

### 5. MEDIUM Main window keeps references into floated content
Evidence: `float_dock_panel` (sw_window.e:392-418) calls `a_host.float_panel` but never checks the main window's `focused`, `hovered`, popup target or pressed capture. If the double-clicked widget (or one inside the panel) is focused in the main window, keystrokes still go to it while it is drawn in the float; the float's own `focused` is Void. Same on `dock_floating` in reverse: the float's `close` clears its own (sw_floating_window.e:134-142) but the main window gets no focus.
Fix: in `float_dock_panel` clear main focus/hover/capture when they lie in the panel content's subtree (`is_ancestor_of`), and after `redock_panel` give focus back to the old widget if it is still enabled. Postcondition: no main-window reference to a widget with a different root.

### 6. MEDIUM make/close state
Evidence: `make` (sw_floating_window.e:46-59) creates cairo, surface, context and painter before it knows `panel.is_open` (when it is not, the object is discarded, finding 2's leak with no owner). `close` sets `capture := Void` (:142) without `set_pressed (False)`, so a button pressed when the window closes stays pressed in its next home. Postcondition lacks `focused = Void and hovered = Void and capture = Void`.
Fix: allocate surfaces only `if panel.is_open`; make `capture` clearing share one `release_capture` feature with the release arm (:275-283).

### 7. MEDIUM Performance: floats redrawn every frame
Evidence: `render_floating_windows` (sw_window.e:451-461) is called from `request_render` (:635) and the frame path (:2491). Each call runs `content.arrange`, `content.draw` and a GDI blit per float (`render`, sw_floating_window.e:173-192), even when only a tick-driven toast changed in the main window or when the float is hidden/minimized. The 100 ms SLOW frame log (sw_window.e:2494) measures this inside `last_render_ms`, so a float makes the main window look slow.
Fix: a dirty flag per float (set by `after_floating_input`, `resize`, theme change, and by owner state changes that touch its content, e.g. `refresh_enabling`), skip render when clean and when `not panel.is_visible`; time floats separately.

### 8. MEDIUM Size events flood
Evidence: WM_SIZE pushes 48 for every size step (simple_shell.h:1252-1254 area); WM_MOUSEMOVE coalesces 43 (:1289-1295) but 48 is not coalesced. Each 48 reaches `handle_event` (sw_floating_window.e:156-158) -> `resize` -> `owner.after_floating_input` -> main render + every float render. Also `resize` (:372-392) recreates the painter on growth but ignores a failed `create_surface` (no validity check as `blit` does).
Fix: coalesce adjacent 48 for the same slot in the shell (as 43); in the float, resize then render only itself.

### 9. MEDIUM (A2/A5/A6) Itinerary and state copied; ancestor only half extracted
Evidence: `SW_POINTER_ROUTING` took `spine_click`, `spine_wheel`, `spine_file_taker`, `ring_neighbour`, `paired_code_point`. Still duplicated between SW_FLOATING_WINDOW and SW_WINDOW:
- state `focused`, `hovered`, `capture`, `last_x/last_y`; `move_focus` (float :323-334) vs the focus code at sw_window.e ~1940-1960; `update_hover` (float :350-370) vs sw_window `update_hover` (~2415); focus ring walk and Tab step;
- press/move/release/leave/wheel arms (float :247-294) vs the SW_WINDOW press/drag/release arms (the main copy also handles popups, hover cards, drag pebbles, text pointing);
- offscreen life: `cairo`, `offscreen`, `ctx`, `alloc_w/h`, 256-step growth, `blit`, `export_frame_png` (float :200-237, :372-392) vs sw_window.e:2378-2379 and `write_frame`.
Drift already visible: floats lack Escape/arrow-step handling, `swallow_next_char` (finding 1), pebble drag, right press, hover card closing, pointer shape.
Fix (MI, side by side): a deferred `SW_INPUT_SURFACE` (focused/hovered/capture/last_x/last_y, move_focus, update_hover, press/move/release/leave/wheel itinerary, `after_input` deferred) inherited with `SW_POINTER_ROUTING` by both SW_WINDOW and SW_FLOATING_WINDOW; and an `SW_OFFSCREEN_FRAME` helper object (surface, ctx, painter, alloc, resize, blit, export, destroy) held by both. Effort about 12 features. Needs Larry's word.

### 10. MEDIUM Focus when the float deactivates
Evidence: `Event_panel_activated` only sets `is_active` (sw_floating_window.e:163-164). `focused` keeps `set_focused (True)`, so its caret/ring show in the float while the main window's focused widget shows too; there is no event path to tell the main window it regained the keyboard from a float. Conversely, activating the main window leaves keys typed there routed to main focus (correct) while the float still looks focused.
Fix: on deactivation, `focused.set_focused (False)` (remember it), on activation restore; make `is_active` part of what widgets see (draw focus ring only when active).

### 11. MEDIUM Accessibility gap
Evidence: `publish_accessibility` (sw_window.e:287-295) collects `active_root` and `sheet` only; `begin_tree (… + floating_node_count)` counts only dialog and popup (:912-920). A floated panel disappears from the tree the moment it floats; `accessible_widget_with_id` can't resolve its nodes. The class note admits "publishing to screen readers" is not done.
Fix: add each float as a window node with its content subtree; `floating_node_count` counts them; route accessibility focus requests to the owning float.

### 12. MEDIUM Event 48 means two things
Evidence: plain panels push the outer rect size from WM_EXITSIZEMOVE (simple_shell.h:1299-1305, now guarded `!framed`); framed panels push client size from every WM_SIZE (:1250-1254). `SHELL_PANEL.width/height` (cached Eiffel-side) are never updated from either, and SW_FLOATING_WINDOW ignores 47, so after the user moves or sizes the window `show`/`place` (sw_floating_window.e:121) would restore the opening geometry. SHELL_EVENTS names one `Event_panel_resized` for both.
Fix: a separate number (66, `Event_panel_client_resized`) for framed panels, leaving 48 with one meaning; or document it in `Event_panel_resized` and add `SHELL_PANEL.note_moved/note_resized` that keeps geometry current. `client_width/height` already call C each time; fine.

### 13. LOW Stale `event_extra`
Evidence: `dispatch` (sw_window.e:717-724) calls `floating_at (event_extra)`; `event_extra` reads the live event buffer (shell_window.e:96). Any harness that calls `dispatch` directly (the `simulate_*` doors do not set it) can route a float event by the previous event's slot, or hand an own-panel event to a float.
Fix: the shell hands the slot as a parameter or `dispatch` takes `a_extra`; or tests set it through a recorder (sw_test_recorder.e).

### 14. LOW Silent drops
Evidence: `handle_input` has no arm for 46, 47, 49, 50. A right press does nothing (no context menu, no popup in floats, as the note says); file drops (50) leave `take_dropped_paths` filling, `spine_file_taker` exists in the shared ancestor but the float never calls it.
Fix: handle 50 via `spine_file_taker (content.widget_at ...)`; drain the paths either way.

### 15. LOW Default close
Evidence: `on_close_request` (sw_floating_window.e:104) is Void unless set; WM_CLOSE returns 0 (simple_shell.h:1245-1249). A float made with `float_widget` alone cannot be closed by the user.
Fix: default to `owner.unfloat (Current)`; or require the agent in `float_widget`.

### 16. LOW Token drift (T1)
Evidence: sw_window.e:407-412: `160 + 32 * count`, `max 320`, `max 200 + 32` (guessed caption height). Start position is in screen coordinates, not relative to the owner or the monitor it is on.
Fix: tokens in SW_THEME (`float_min_width`, `float_cascade_step`), query `panel.client` vs outer after open (`open_framed` then adjust with `client_height`), place relative to owner's `win_x/win_y`.

### 17. LOW Snapshot
Evidence: `floating_keys` is not read by `layout_snapshot`/`restore_layout`; a floating panel is saved hidden (finding 3).
Fix: write a `floating` line; restore it through `enable_floating_panels`' request.

### 18. LOW Unguarded shell cases
Evidence: simple_shell.h:1207-1215: `WM_LBUTTONDBLCLK` and `WM_MOUSELEAVE` push 64/65 with no `is_framed` guard; harmless because plain classes lack CS_DBLCLKS and never call TrackMouseEvent. A plain panel with `CS_DBLCLKS` added later would start sending 64.
Fix: guard like the others.

### 19. LOW Modal bypass
Evidence: `handle_event` handles resize, activate and close-request before the `owner.dialog = Void` test (sw_floating_window.e:154-168). A close request while a modal dialog is open redocks the panel under it.
Fix: defer the close request while `owner.dialog /= Void`.

## Checked, no finding
- WM_SIZE during creation: `shell_panel_is_framed` compares `s_shell_panel[slot] == h`, false before the slot is stored; safe.
- WM_ACTIVATE: pushes 63 then `break` to DefWindowProc; default handling kept.
- Layered framed class: `SetLayeredWindowAttributes (…, 255, LWA_ALPHA)` after creation is valid; non-client draws normally.
- Capture: WM_LBUTTONDOWN still `SetCapture`, WM_LBUTTONUP releases; release outside the client arrives as 42, so drag does end. Leave (65) clears hover only, not the capture.
- Float hover on close: `close` clears `hovered`.
- Redock after unfloat order: `dock_floating` unfloats (content free), then `redock_panel` sets the parent; correct.

## Recommended Order
1. Finding 1 (live defect, small), then 2 and 4 (leaks and stale slots).
2. Finding 3 (preconditions on the dock host).
3. Finding 9 (shared ancestor and frame helper) before finding 5/10/11 so they land once.
4. Findings 7, 8, 12 together (render policy and the event meaning).
