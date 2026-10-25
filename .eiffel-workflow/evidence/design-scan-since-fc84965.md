# Design Scan (diff mode): simple_widgets, since fc84965 (main c01e578)
# Date: 2026-10-25
# Scope: GW-14b 0.33.0, accessibility publishing
# Subjects: src/sw_widget.e (accessible_*), src/sw_window.e (publish_accessibility, collect_accessible, tell_accessible_focus,
#           render and render_frame, event 58), src/sw_accessibility.e, overrides in twenty widget classes,
#           testing/sw_accessibility_assault.e
# Read-only: nothing compiled, no source edited. Compared against all of src/.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Publishing lifecycle (1, 2, 3, 4, 11) | 5 | 4 | 1 | 0 |
| Tree fidelity (5, 6, 8, 9, 10) | 5 | 2 | 3 | 0 |
| Cost (7) | 1 | 0 | 1 | 0 |
| Tests (12) | 1 | 0 | 1 | 0 |
| Duplication and text (13, 14, 15, 16) | 4 | 0 | 0 | 4 |
| **Total** | **16** | **6** | **6** | **4** |

Quadratic cost was checked and is NOT present: `accessible_id_of` is linear but is called only from `tell_accessible_focus`
(once per publish or focus change), and `add_node` is constant time per row.

## Findings

| # | Priority | Where | Finding |
|---|----------|-------|---------|
| 1 | HIGH | sw_window.e:572-575, :284-285, :2460 | The first publish happens before the native window exists (window handle null) and is never repeated unless a client listens |
| 2 | HIGH | sw_window.e:2456-2467 | Republishing is gated on a client listening, and windows render only on events: polling clients and late clients see a stale or empty tree |
| 3 | HIGH | sw_window.e:229-257, :276-284, :728-736 | Node id is the index in the last published list: identity shifts on every insert, and event 58 trusts a stale id |
| 4 | HIGH | sw_window.e:286-287, :840-853 | Every publish resets `last_told_focus`, so every frame raises a focus-changed event while a client listens |
| 5 | HIGH | sw_window.e:256-290, :728-748 | Dialog, popup menu, sheet, drawer, hover card and toasts are never published; event 58 is honored under a modal dialog |
| 6 | HIGH | sw_accordion.e:124-132, :150-163 | Collapsed accordion sections are published as live nodes with stale bounds |
| 7 | MEDIUM | sw_window.e:256-290, sw_widget.e:690-715 | Full tree rebuild and string copies on every frame, no change detection |
| 8 | MEDIUM | sw_window.e:819-838, sw_scroll_area.e:141 | Published bounds are unclipped: scrolled-away content overlaps siblings |
| 9 | MEDIUM | sw_tabs.e:853-860, sw_list.e, sw_tree.e, sw_data_grid.e, sw_menu_bar.e, sw_toolbar.e, sw_radio_group.e | Containers publish a role but not the items they draw |
| 10 | MEDIUM | sw_text_box.e, sw_select.e, sw_slider.e, sw_progress.e, sw_image.e | Controls with no drawn caption publish an empty name |
| 11 | MEDIUM | sw_window.e:204-208, :221-225 | Facade state is global in C while the window object is not; no disable when the window closes |
| 12 | MEDIUM | testing/sw_accessibility_assault.e | Tests cover the first publish only |
| 13 | LOW | sw_slider.e, sw_progress.e | The percent formatting body is copied |
| 14 | LOW | sw_button.e, sw_check_box.e, sw_switch.e, sw_label.e, sw_group.e | Five `default_accessible_name` overrides are the same twin; two value overrides share a shape |
| 15 | LOW | sw_widget.e:671-679 | `accessible_name` hands out the internal override string (aliasing) |
| 16 | LOW | sw_check_box.e, sw_switch.e, sw_progress.e, sw_tabs.e | English state words as the Value string; mnemonic markers in names unverified |

## Detailed findings

### Finding 1: First publish with a null window handle (HIGH)
**Where:** `run` (sw_window.e:572-575) calls `render` BEFORE `shell_run` creates the window; `render` (:2456-2467) publishes because `is_accessibility_published` is False, and
`publish_accessibility` calls `accessibility.commit (hwnd)` (:284) with `hwnd = default_pointer`, then sets `is_accessibility_published := True` (:285). Nothing resets the flag in `on_shell_open`.
**Failure scenario:** the C side serves a window only when `l_h == s_uia_hwnd` (simple_shell_uia.h:518); the table now holds a null handle, so WM_GETOBJECT never matches. From then on `render` republishes only
when `clients_listening` is true. A client that only polls (Accessibility Insights in inspect mode, a UI Automation test script, voice control) never registers a listener, so it sees the bare window forever. Even a listening client first meets a window that answers nothing, and learns the tree only after the next render.
**Suggested fix:** in `on_shell_open` set `is_accessibility_published := False` and publish (the handle is valid there); contract: `published_with_window: is_accessibility_published implies (accessibility_hwnd = hwnd)`.

### Finding 2: Stale snapshot unless a client is listening (HIGH)
**Where:** `render` (sw_window.e:2456-2467): `if not is_accessibility_published or else accessibility.clients_listening then publish`.
**Failure scenario:** the window renders only when something asks (input, `request_render`, tick work). (a) With no listener nothing republishes after the first frame, so a page switch, a new root (`set_root`), an inserted row or a changed text leaves the served table as it was at start-up. (b) When a screen reader starts, no frame is due, so the first query returns the start-up table until the user happens to move the mouse. The test client in simple_shell reads exactly this way (a poll) and passes only because the tree never changed.
**Suggested fix:** a `tree_changed` flag set by `set_root`, structural changes and `request_render`, plus a hook: when the shell sees the first WM_GETOBJECT after a quiet period, it queues an event (59, the pump thread, so `shell_push` is safe there) and the window publishes. Publish on that event and on a flagged frame; do not key on `clients_listening` at all, only use it to decide whether to raise change events.

### Finding 3: Node id is a list index, so identity is unstable (HIGH)
**Where:** `accessible_widgets` (:229-234) "the node id of each is its index"; `publish_accessibility` (:276-284); `accessible_id_of` (:237-257); event 58 handler (:728-736); simple_shell_uia.h serves `sw<id>` as the AutomationId and `{UiaAppendRuntimeId, id}` as the runtime id.
**Failure scenario:** a widget inserted before the button shifts every later id by one. UI Automation clients cache elements by runtime id: the "Save" element they hold now names the widget that took its index, so a screen reader announces the wrong control or treats two controls as one. The focus request has the same defect: a client reads id 7, a publish renumbers, the client sends SetFocus for 7, and `give_focus` is applied to whatever now sits at index 7 (:731-734), or to a widget that has left the tree entirely (the old list is only replaced by the next publish, which on an idle window may be never; see finding 2), so the keyboard goes to a detached widget.
**Suggested fix:** give each widget a permanent serial number from a class-level counter in SW_WIDGET (`accessible_serial`), publish that as the id (node 0 stays 0), keep a hash table serial to widget for event 58, and before `give_focus` confirm that the widget is still reachable from `root`.

### Finding 4: A focus event on every frame (HIGH)
**Where:** `publish_accessibility` sets `last_told_focus := Void` (:286) and then calls `tell_accessible_focus` (:287), which tells whenever `focused /= last_told_focus` (:846), i.e. whenever any widget is focused. `render` publishes on every frame while a client listens (:2460).
**Failure scenario:** with a screen reader running and a text box focused, each frame raises UiaRaiseAutomationEvent (focus changed) for the same element, up to sixty cross-process events a second. Screen readers either re-announce or churn their speech queue, and each event costs a COM round trip into the client.
**Suggested fix:** do not reset `last_told_focus` on publish; reset it only when the id of the focused widget changes under the new numbering (with stable serials it never does), or when the first publish follows `disable`.

### Finding 5: Modal and floating surfaces are not published, and event 58 ignores modality (HIGH)
**Where:** `publish_accessibility` walks only `root` (:268-271). `dialog`, `popup`, `sheet` (and the drawer mode), `hover_card` and the toasts are window-level fields (sw_window.e:3208 `dialog`, :1118 `sheet_content`, :1472 `open_popup`).
**Failure scenario:** a modal dialog opens. It owns all input (`dispatch_to_dialog`), but its buttons are absent from the table, while the dimmed page behind it is published as if live. A screen-reader user hears the page, cannot find or reach the dialog buttons, and is stuck. The same holds for a context menu (its items never appear) and for a sheet or drawer. Worse, the event 58 arm (:728-736) sits before the `dialog`/`popup` dispatch (:743-748) and honors a request to focus a widget BEHIND the dialog, moving the keyboard focus under a modal.
**Suggested fix:** when `dialog`, `popup` or a modal sheet is present, publish it as the only child of node 0 (the covered page is withheld, as a modal should be) and take its widgets through the same `collect_accessible`; ignore event 58 for ids outside the modal subtree; publish the hover card and toasts as read-only text nodes after the page.

### Finding 6: Collapsed accordion content is published (HIGH)
**Where:** `SW_ACCORDION.sub_widgets` (sw_accordion.e:124-132) returns the content of every section; `arrange` (:150-163) sets bounds only for OPEN sections. `accessible_children` defaults to `sub_widgets` (sw_widget.e:708-713) and `collect_accessible` keeps any widget whose stale `width` and `height` are above zero (sw_window.e:824).
**Failure scenario:** a section is opened and closed: its content keeps the rectangle from the open state, is skipped by `draw` but still listed as a visible child, so a screen reader reads closed text, and `ElementProviderFromPoint` finds a ghost node under later sections. A section never opened is skipped only by luck (zero size).
**Suggested fix:** override `accessible_children` in SW_ACCORDION to return only open sections (as SW_TABS does for its shown page), and publish the section headers as ExpandCollapse-capable button nodes. The same audit applies to SW_DOCK_HOST (:646-653 returns all four zones; panels with `is_visible` false, sw_dock_host.e:216, need the same filter; not verified here whether hidden panels keep stale bounds) and to every `sub_widgets` override that can hold children it does not draw: SW_SPLITTER, SW_STATUS_BAR.

### Finding 7: Per-frame rebuild cost (MEDIUM)
**Where:** `publish_accessibility` (:256-290), `accessible_role` default (sw_widget.e:690-701), the widget overrides.
**Failure scenario:** while a client listens, every frame (including each animation frame) walks the whole tree; `sub_widgets` and `accessible_children` build a new list per call (accordion, dock host, tabs); `accessible_role`'s default calls `accessible_children` AND `collect_accessible` calls it again, so containers allocate twice per publish; every name and value is copied (`.twin`), converted to a native string, copied again in C by `shell_uia_copy`, and the old table is freed. A multi-line text box returns `text.twin` of the whole document (sw_text_box.e accessible_value) as the Value of one node, per frame. This is linear, so it is not a quadratic, but it spends the GW-29 budget on a tree that did not change, and contracts stay on in the checked builds (`collect_accessible` ensure and the `add_node` requires run per row).
**Suggested fix:** publish only when flagged (finding 2) or compare a cheap per-frame digest of (serial, role, name, value hash, bounds, enabled) and skip when equal; cap the Value of long text (the first and last few hundred characters, plus a selection) and provide it through a Text pattern later; call `accessible_children` once per widget.

### Finding 8: Unclipped bounds (MEDIUM)
**Where:** `publish_accessibility` passes `w.x, w.y, w.width, w.height` (:281). SW_SCROLL_AREA places its child at `y - scroll_y` (sw_scroll_area.e:141), so the child rectangle runs beyond the viewport; `collect_accessible` never intersects with an ancestor.
**Failure scenario:** the long content of a scroll area is published at its true, partly off-viewport position and overlaps toolbars and neighbors; the last-box-wins hit test (simple_shell_uia.h:416) returns the scrolled-away row for a point over a sibling, so touch exploration and hover reading name the wrong control, and a click simulated at the published center lands elsewhere. Gutters and scrollbar areas are inside the parent rectangle and are published as part of the child.
**Suggested fix:** carry a clip rectangle down `collect_accessible` (each container may narrow it), publish the intersection, and skip nodes whose intersection is empty (or flag them offscreen, see the simple_shell scan finding 7).

### Finding 9: Items are drawn but not published (MEDIUM)
**Where:** SW_TABS publishes role Tab with only the shown page (sw_tabs.e:853-860): no tab-item nodes, so the tab strip cannot be read or switched. SW_LIST, SW_TREE and SW_DATA_GRID publish a container with no rows or cells; SW_MENU_BAR and SW_TOOLBAR publish no items; SW_RADIO_GROUP publishes role group with only the selected option as its Value.
**Failure scenario:** a screen-reader user meets "list" or "menu bar" with nothing inside, cannot read the rows, cannot find "File", and cannot choose a radio option. That is a coverage decision rather than a bug, but it defeats the purpose of the bridge for the most common controls. The `accessible_children` contract ("the widgets a screen reader can reach below this one") cannot express items that are not widgets.
**Suggested fix:** let `accessible_children` return lightweight descriptor objects (an `SW_ACCESSIBLE_NODE` deferred ancestor with role, name, value, bounds, and an action), implemented by SW_WIDGET (itself) and by item adapters; windowed rows only (the visible range) for virtualized lists, which also bounds finding 7.

### Finding 10: Unnamed controls (MEDIUM)
**Where:** `default_accessible_name` in sw_widget.e:681-685 returns empty; the text box, select, combo, slider, progress bar and image do not override it. The assault test pins the empty name (`assert_role_name (w, f.tx, ..., "")`).
**Failure scenario:** a labeled field (a label drawn beside a text box) announces as just "edit"; the screen-reader user must guess. `set_accessible_name` exists but nothing links a label to its field.
**Suggested fix:** a `labelled_by: detachable SW_WIDGET` on SW_WIDGET (name taken from that label), set by SW_FORM-style helpers when a label and a field are added together; an image alternative text parameter.

### Finding 11: Global C state under per-window objects (MEDIUM)
**Where:** `accessibility` is `once ("OBJECT")` (sw_window.e:208), so each window object has a facade, but every facade drives the same C table, handle and staging area (simple_shell scan finding 3). `set_accessible (False)` disables (:221-225); closing the window does not.
**Failure scenario:** a toolkit app with a second top-level window (or the offscreen test harness running several windows in one process) fights over the single table: the last publisher wins and the other window answers no client. A closed window keeps its table and hook.
**Suggested fix:** one fix in the shell (state keyed by window handle); in this class, call `accessibility.disable` after `shell_run` returns, and add the contract `closed_serves_nothing`.

### Finding 12: Test gaps (MEDIUM)
**Where:** testing/sw_accessibility_assault.e (176 lines, four tests, all one `request_render` after `set_root`).
**Failure scenario:** nothing covers republish after a tree change (finding 2), id stability across an insert (3), the focus event count over many frames (4), a dialog or popup open (5), an accordion opened then closed (6), a scrolled area (8), the window handle at publish (1, the offscreen harness has `hwnd = default_pointer` by design, so the defect is invisible to every test), or the cost of a publish at, say, five thousand nodes against the frame budget.
**Suggested fix:** add: insert a widget, republish, assert the old widgets keep their ids; render sixty frames and count `focus_changed` calls (a counter in a test double of the facade); open and close an accordion section; open a dialog and assert node 0 has the dialog as its only child; a timed publish test under `without_contracts` as the timing rule requires.

### Finding 13: Copied percent formatting (LOW)
**Where:** `SW_SLIDER.accessible_value` and the non-indeterminate branch of `SW_PROGRESS.accessible_value` are the same five lines (create string, `append_integer ((fraction * 100.0).rounded)`, append `%`).
**Description:** a fraction-valued widget family. **Suggested action:** a `percent_text (a_fraction): STRING_32` in SW_WIDGET (or a small deferred `SW_FRACTIONAL` mixin inherited side by side, carrying `fraction` and `accessible_value`), used by both. Effort: one feature, two call sites.

### Finding 14: Repeated name and value overrides (LOW)
**Where:** `default_accessible_name` is `X.twin` of a string attribute in SW_BUTTON (`label`), SW_CHECK_BOX (`label`), SW_SWITCH (`label`), SW_LABEL (`text`), SW_GROUP (`title`); `accessible_value` in SW_CHECK_BOX and SW_SWITCH is a two-state word choice.
**Description:** the pair "caption attribute is the name" is repeated five times; fine at this size, but a `caption: STRING_32` deferred query in a shared ancestor (inherited next to the role mixins) would remove the five overrides and give finding 10 a single place to extend. **Effort:** one deferred feature, five classes.

### Finding 15: Aliasing in `accessible_name` (LOW)
sw_widget.e:671-679 returns `accessible_name_override` itself when set, but a copy (`twin`) in every default; a caller that edits the result changes the stored override. Return `al_name.twin` for consistency.

### Finding 16: Value words and mnemonics (LOW)
"checked", "not checked", "on", "off", "working" (sw_check_box.e, sw_switch.e, sw_progress.e) are fixed English strings in the Value, not localizable and not the Toggle or RangeValue patterns clients expect (see the simple_shell scan finding 5). Labels that carry a mnemonic marker (an ampersand before a letter) are published verbatim as the name in SW_BUTTON and SW_CHECK_BOX if their `label` stores the marker; this was not verified here and should be checked and stripped.

## Verified, no finding

- `collect_accessible` skips a zero-size widget with its whole subtree (sw_window.e:824); `ensure parallel` keeps the parent list in step.
- SW_TABS publishes only the shown page (sw_tabs.e:853-860), tested by `test_gw14_the_tree_is_published`.
- A masked text box never publishes its text (sw_text_box.e accessible_value), tested.
- `accessible_widgets` is wiped on `set_accessible (False)` and the table disabled; no stale list remains in that case.
- `render` was split cleanly: `render_frame` keeps the old body; `request_render` still draws then blits.

## Recommended order

1. Finding 1 (one-line cause, makes the whole bridge reachable by polling clients).
2. Findings 3 and 4 together (stable serial ids; stop resetting the told focus), since 4 is a per-frame defect and 3 changes the data model the rest depend on.
3. Finding 2 (a change flag and a first-query event), then 7 (digest and skip), which finish the publishing lifecycle.
4. Finding 5 (modal surfaces and modality for event 58), 6 (accordion and the dock audit), 8 (clip).
5. Findings 9 and 10 (coverage and names), with 13 and 14 folded into the same refactor.
6. Finding 12 (tests pinning all of the above) alongside each step; findings 11, 15, 16 last.
