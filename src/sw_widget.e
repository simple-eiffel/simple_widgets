note
	description: "[
		Ancestor of everything drawable. A widget owns a rectangle,
		reports its preferred size, draws itself through the painter,
		and may respond to input. Containers redefine `arrange' and
		`widget_at' to manage children.

		No widget touches Cairo or Win32: geometry, painter calls and
		agents are the whole vocabulary.
	]"

deferred class
	SW_WIDGET

feature -- Tree

	parent: detachable SW_WIDGET
			-- Enclosing container, set on adoption; the spine input
			-- bubbling and any future accessibility bridge walk.

	set_parent (a_parent: detachable SW_WIDGET)
		do
			parent := a_parent
		ensure
			set: parent = a_parent
		end

feature -- Tooltip

	tooltip: STRING_32
			-- Hover hint; empty means none. Drawn by the window after
			-- a dwell - a drawn overlay per R7, never a native tip.
		attribute
			create Result.make_empty
		end

	set_tooltip (a_tip: READABLE_STRING_GENERAL)
		do
			create tooltip.make_from_string_general (a_tip)
		ensure
			kept: tooltip.same_string_general (a_tip)
		end

	with_tooltip (a_tip: READABLE_STRING_GENERAL): like Current
			-- Fluent tooltip.
		do
			set_tooltip (a_tip)
			Result := Current
		ensure
			chained: Result = Current
		end

feature -- Geometry

	x: REAL_64
	y: REAL_64
	width: REAL_64
	height: REAL_64

	set_bounds (a_x, a_y, a_w, a_h: REAL_64)
		require
			sane_size: a_w >= 0.0 and a_h >= 0.0
		do
			x := a_x
			y := a_y
			width := a_w
			height := a_h
		ensure
			placed: x = a_x and y = a_y
			sized: width = a_w and height = a_h
		end

	vanish
			-- Take this widget and everything below it off the surface:
			-- no extent where it stands, so pills, hover and hit tests
			-- pass it by until the next `arrange' places it again. A
			-- folded dock zone and the zones a maximized panel covers
			-- send their contents away so.
		do
			set_bounds (x, y, 0.0, 0.0)
			across
				sub_widgets as al_child
			loop
				al_child.vanish
			end
		ensure
			gone: width = 0.0 and height = 0.0
		end

	contains (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := a_px >= x and then a_px <= x + width
				and then a_py >= y and then a_py <= y + height
		end

feature -- Sizing policy (the containership vocabulary)

	grow: REAL_64
			-- Share of a container's leftover space this widget claims;
			-- 0 = natural size only (the default). Vision2's expanded
			-- item and the web's flex-grow, unified.

	min_width: REAL_64
	min_height: REAL_64
	max_width: REAL_64
	max_height: REAL_64
			-- Anchors; 0 means unset.

	set_grow (a_g: REAL_64)
		require
			non_negative: a_g >= 0.0
		do
			grow := a_g
		ensure
			set: grow = a_g
		end

	growing: like Current
			-- Fluent: claim leftover space with weight 1. (Vision2
			-- called this expanded - an Eiffel keyword, so: growing.)
		do
			grow := 1.0
			Result := Current
		ensure
			growing: grow = 1.0
			chained: Result = Current
		end

	with_min_size (a_w, a_h: REAL_64): like Current
			-- Fluent minimum anchors (0 leaves an axis unset).
		require
			sane: a_w >= 0.0 and a_h >= 0.0
		do
			min_width := a_w
			min_height := a_h
			Result := Current
		ensure
			chained: Result = Current
		end

	with_max_size (a_w, a_h: REAL_64): like Current
			-- Fluent maximum anchors (0 leaves an axis unset).
		require
			sane: a_w >= 0.0 and a_h >= 0.0
		do
			max_width := a_w
			max_height := a_h
			Result := Current
		ensure
			chained: Result = Current
		end

	clamped_width (a_natural: REAL_64): REAL_64
			-- `a_natural' pulled inside the anchors.
		do
			Result := a_natural.max (min_width)
			if max_width > 0.0 then
				Result := Result.min (max_width)
			end
		ensure
			at_least_minimum: Result >= min_width
		end

	clamped_height (a_natural: REAL_64): REAL_64
		do
			Result := a_natural.max (min_height)
			if max_height > 0.0 then
				Result := Result.min (max_height)
			end
		ensure
			at_least_minimum: Result >= min_height
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- Natural width; 0.0 means "give me what you have".
		do
			Result := 0.0
		ensure
			non_negative: Result >= 0.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- Natural height when laid out `a_width' wide.
		deferred
		ensure
			non_negative: Result >= 0.0
		end

	arrange (a_p: SW_PAINTER)
			-- Place children (containers); leaves need nothing.
		do
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		deferred
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- Deepest widget under the point, if any.
		do
			if contains (a_px, a_py) then
				Result := Current
			end
		ensure
			inside_when_found: Result = Current implies contains (a_px, a_py)
		end

feature -- Input

	accepts_focus: BOOLEAN
			-- Should a click here move the keyboard focus?
		do
			Result := False
		end

	wants_tab: BOOLEAN
			-- Does this widget consume the Tab CHARACTER itself
			-- (spreadsheet cell-advance)? When False, Tab traverses
			-- window focus instead of arriving here.
		do
			Result := False
		end

	cursor_kind: INTEGER
			-- The pointer shape over this widget: 0 arrow, 1 ibeam,
			-- 2 hand, 3 size-we, 4 size-ns, 5 cross, 6 wait
			-- (SHELL_WINDOW's cursor vocabulary).
		do
			Result := 0
		end

	is_focused: BOOLEAN
			-- Does this widget hold the keyboard focus?
			-- Maintained by the window; drawn by the widget.

	is_hovered: BOOLEAN
			-- Is the pointer over this widget? Window-maintained.

	is_pressed: BOOLEAN
			-- Is the pointer held down on this widget? Window-maintained.

	is_enabled: BOOLEAN
			-- Does this widget accept input? Disabled widgets draw muted
			-- and are skipped by dispatch.
		do
			Result := not is_disabled
		end

	set_focused (a_focused: BOOLEAN)
		do
			if is_focused /= a_focused then
				is_focused := a_focused
				if attached focus_event as e then
					e.call ([a_focused])
				end
			end
		ensure
			set: is_focused = a_focused
		end

	hover_px: REAL_64
	hover_py: REAL_64
			-- Pointer position while hovered, for widgets that signal
			-- per-part hover (list rows, scrollbar thumbs, radio dots).

	shows_hover: BOOLEAN
			-- Should hover feedback draw right now? On by default;
			-- silence per widget with set_hover_signal (False).
		do
			Result := is_hovered and then is_enabled and then not is_hover_silenced
		end

	set_hover_signal (a_on: BOOLEAN)
		do
			is_hover_silenced := not a_on
		ensure
			set: shows_hover implies a_on
		end

	hover_silenced: like Current
			-- Fluent: Current with hover feedback off.
		do
			is_hover_silenced := True
			Result := Current
		ensure
			chained: Result = Current
		end

	is_hover_silenced: BOOLEAN
			-- Stored inverted: fresh widgets signal hover.

	wants_hover_point: BOOLEAN
			-- Should the window re-render on every pointer move over
			-- this widget (not only on enter/leave)?
		do
		end

	set_hover_point (a_px, a_py: REAL_64)
		do
			hover_px := a_px
			hover_py := a_py
		end

	dwell_ms: INTEGER
			-- How long the pointer must rest on this widget before the
			-- window calls `handle_dwell'; 0 (the default) never. The
			-- window times it with the shell's one-shot dwell timer,
			-- re-armed on every pointer move (GW-08).
		do
		ensure
			non_negative: Result >= 0
		end

	handle_dwell (a_px, a_py: REAL_64)
			-- The pointer has rested `dwell_ms' at (`a_px', `a_py').
		do
		end

	hover_card_at (a_px, a_py: REAL_64): detachable SW_HOVER_CARD
			-- The card this widget offers for the sub-region under
			-- (`a_px', `a_py'), asked by the window after a dwell (GW-09);
			-- Void (the default) offers none. A widget that offers cards
			-- also answers a positive `dwell_ms'.
		do
		end

	set_hovered (a_hovered: BOOLEAN)
		do
			if is_hovered /= a_hovered then
				is_hovered := a_hovered
				if attached hover_event as e then
					e.call ([a_hovered])
				end
			end
		ensure
			set: is_hovered = a_hovered
		end

	set_pressed (a_pressed: BOOLEAN)
		require
			only_enabled_press: a_pressed implies is_enabled
		do
			if is_pressed /= a_pressed then
				is_pressed := a_pressed
				if attached press_event as e then
					e.call ([a_pressed])
				end
			end
		ensure
			set: is_pressed = a_pressed
		end

	set_enabled (a_enabled: BOOLEAN)
		do
			if is_disabled = a_enabled then
				is_disabled := not a_enabled
				if attached enabled_event as e then
					e.call ([a_enabled])
				end
			end
		ensure
			set: is_enabled = a_enabled
		end

	on_focus_change: SW_EVENT [TUPLE [focused: BOOLEAN]]
			-- Fires when is_focused CHANGES (the datum is the new
			-- truth). Lazily allocated - unobserved widgets pay one
			-- Void test. With on_hover_change, on_press_change and
			-- on_enabled_change, the widget's own state machine is
			-- observable: subscribe permanents or kamikazes and the
			-- GUI state machine emerges by default (Larry's design).
		do
			if attached focus_event as e then
				Result := e
			else
				create Result.make
				focus_event := Result
			end
		end

	on_hover_change: SW_EVENT [TUPLE [hovered: BOOLEAN]]
			-- Fires when is_hovered changes.
		do
			if attached hover_event as e then
				Result := e
			else
				create Result.make
				hover_event := Result
			end
		end

	on_press_change: SW_EVENT [TUPLE [pressed: BOOLEAN]]
			-- Fires when is_pressed changes.
		do
			if attached press_event as e then
				Result := e
			else
				create Result.make
				press_event := Result
			end
		end

	on_enabled_change: SW_EVENT [TUPLE [enabled: BOOLEAN]]
			-- Fires when is_enabled changes - by hand or by an
			-- enabled_when condition; the sensitivity pass speaks
			-- through the same queue.
		do
			if attached enabled_event as e then
				Result := e
			else
				create Result.make
				enabled_event := Result
			end
		end

	enabled_when: detachable FUNCTION [BOOLEAN]
			-- The enabling condition: the window re-queries it after
			-- every user interaction and applies its verdict - state
			-- control by agent collection, the Vision2 sensitivity
			-- idiom (Larry's call). Void = enablement is manual.

	set_enabled_when (a_condition: FUNCTION [BOOLEAN])
			-- Install the condition and apply it immediately.
		do
			enabled_when := a_condition
			set_enabled (a_condition.item ([]))
		ensure
			installed: enabled_when = a_condition
			applied: is_enabled = a_condition.item ([])
		end

	refresh_enabling
			-- Re-query conditions down the whole subtree; sub_widgets
			-- is the spine (containers expose their children there),
			-- so one walk from the root refreshes the entire face.
		do
			if attached enabled_when as c then
				set_enabled (c.item ([]))
			end
			across
				sub_widgets as sw
			loop
				sw.refresh_enabling
			end
		end

	disabled: like Current
			-- Fluent: Current, disabled.
		do
			set_enabled (False)
			Result := Current
		ensure
			off: not is_enabled
			chained: Result = Current
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- React to a click; True when consumed. False lets the
			-- window bubble the click to the parent chain.
		do
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := handle_click (a_px, a_py)
		end

	handle_triple_click (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := handle_double_click (a_px, a_py)
		end

	handle_drag (a_px, a_py: REAL_64)
		do
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
			-- React to a mouse-wheel turn; True when consumed.
		do
		end

	handle_context (a_px, a_py: REAL_64): BOOLEAN
			-- React to a right-click; True when consumed. Prefer
			-- declaring a menu via context_menu and letting the window
			-- present it; use this hook only for non-menu reactions.
		do
		end

	pebble: detachable ANY
			-- What a pick lifts from this widget; Void = not a source.
			-- Vision2's pick-and-drop, contract-checked: by default the
			-- stored pebble_item; redefine for position-dependent picks.
		do
			Result := pebble_item
		end

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
			-- The widgets this one owns, for tooling that walks the
			-- tree (the dev mesh, the coming inspector tree panel).
			-- Leaves answer empty; containers redefine.
		do
			create Result.make (0)
		ensure
			answered: Result /= Void
		end

	focusables (a_acc: ARRAYED_LIST [SW_WIDGET])
			-- Append, in tree order, every enabled widget below (and
			-- including) this one that accepts keyboard focus - the
			-- window's Tab ring, collected purely so a headless
			-- assault can hold it to account.
		do
			if accepts_focus and is_enabled then
				a_acc.extend (Current)
			end
			across
				sub_widgets as sw
			loop
				sw.focusables (a_acc)
			end
		ensure
			grew_or_not: a_acc.count >= old a_acc.count
		end

	dev_note: detachable STRING_32
			-- Creator-supplied provenance for the dev-mode inspector:
			-- intent, wiring rationale - what reflection cannot know.

	set_dev_note (a_note: READABLE_STRING_GENERAL)
		do
			create dev_note.make_from_string_general (a_note)
		ensure
			noted: dev_note /= Void
		end

	with_dev_note (a_note: READABLE_STRING_GENERAL): like Current
		do
			set_dev_note (a_note)
			Result := Current
		ensure
			chained: Result = Current
		end

	accepts_files: BOOLEAN
			-- Does this widget welcome files dropped from the shell?
			-- The pebble protocol's file-shaped sibling.
		do
		end

	receive_files (a_paths: ARRAYED_LIST [STRING_32]; a_px, a_py: REAL_64)
			-- Take the dropped paths (drop point in widget space).
		require
			welcome: accepts_files
			something: not a_paths.is_empty
		do
		end

	pebble_at (a_px, a_py: REAL_64): detachable ANY
			-- The pebble offered at a specific point - by default the
			-- widget-wide `pebble'. Virtualized widgets redefine this
			-- to offer per-row or per-cell pebbles.
		do
			Result := pebble
		end

	set_pebble (a_pebble: detachable ANY)
		do
			pebble_item := a_pebble
		ensure
			set: pebble_item = a_pebble
		end

	with_pebble (a_pebble: ANY): like Current
			-- Fluent pick-source declaration.
		do
			pebble_item := a_pebble
			Result := Current
		ensure
			chained: Result = Current
		end

	accepts_pebble (a_pebble: ANY): BOOLEAN
			-- Would this widget welcome `a_pebble'? The hole's type
			-- check, as an honest query.
		do
		end

	receive_pebble (a_pebble: ANY)
			-- Accept the drop.
		require
			welcome: accepts_pebble (a_pebble)
			enabled: is_enabled
		do
		end

	pebble_item: detachable ANY
			-- Stored pebble behind the default `pebble'.

	focus_event: detachable SW_EVENT [TUPLE [focused: BOOLEAN]]
			-- Backing store for on_focus_change; Void until observed.

	hover_event: detachable SW_EVENT [TUPLE [hovered: BOOLEAN]]

	press_event: detachable SW_EVENT [TUPLE [pressed: BOOLEAN]]

	enabled_event: detachable SW_EVENT [TUPLE [enabled: BOOLEAN]]

	pending_popover: detachable SW_WIDGET
			-- A widget tree this widget wants presented as an
			-- anchored popover at its foot - the pending-menu
			-- handshake's sibling. The window takes it after the
			-- click that set it.

	pending_popover_width: REAL_64

	take_pending_popover: detachable SW_WIDGET
		do
			Result := pending_popover
			pending_popover := Void
		ensure
			taken: pending_popover = Void
		end

	requests_sheet_close: BOOLEAN
			-- Has this widget asked the window to close the overlay
			-- it lives in (a popover picker completing its pick)?

	request_sheet_close
			-- Ask the window to close the overlay after this
			-- interaction; consumed by `take_sheet_close_request'.
		do
			requests_sheet_close := True
		ensure
			asked: requests_sheet_close
		end

	take_sheet_close_request: BOOLEAN
			-- One-shot: the pending close request, consumed on read.
		do
			Result := requests_sheet_close
			requests_sheet_close := False
		ensure
			consumed: not requests_sheet_close
		end

	pending_menu: detachable SW_MENU
			-- A menu this widget wants presented after its click was
			-- handled - the dropdown handshake: the widget declares
			-- during handle_click, the window presents and clears.

	take_pending_menu: detachable SW_MENU
			-- The pending menu, consumed.
		do
			Result := pending_menu
			pending_menu := Void
		ensure
			consumed: pending_menu = Void
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- The menu this widget offers at the point, if any. The
			-- window presents it; every widget is right-clickable, and
			-- the only question is whether something is defined here.
		do
		end

	menu_extension: detachable PROCEDURE [SW_MENU, REAL_64, REAL_64]
			-- A client's own items for this widget's right-click menu:
			-- called with an empty menu and the point, after the widget's
			-- `context_menu' was asked (so a grid has already noted the
			-- row under the pointer); what it adds stands first.

	set_menu_extension (a_action: detachable PROCEDURE [SW_MENU, REAL_64, REAL_64])
		do
			menu_extension := a_action
		ensure
			set: menu_extension = a_action
		end

	offered_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- What a right-click at the point presents: the client's
			-- `menu_extension' items, a separator, then the widget's own
			-- `context_menu'; Void when neither offers an item.
		local
			l_own: detachable SW_MENU
		do
			l_own := context_menu (a_px, a_py)
			if attached menu_extension as al_extension then
				create Result.make
				al_extension.call ([Result, a_px, a_py])
				if attached l_own as al_own and then not al_own.items.is_empty then
					if not Result.items.is_empty then
						Result.add_separator
					end
					Result.append_items (al_own)
				end
				if Result.items.is_empty then
					Result := Void
				end
			else
				Result := l_own
			end
		ensure
			extended_never_empty: (menu_extension /= Void and attached Result as al_result) implies not al_result.items.is_empty
		end

	handle_char (a_code: INTEGER)
		do
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
		end

	handle_release (a_x, a_y: INTEGER)
			-- The pointer let go while this widget held the capture.
			-- No-op by default; press-and-hold interactions (a brake
			-- pedal, a scrub) redefine it.
		do
		end

feature -- Accessibility (GW-14)

	accessible_name: STRING_32
			-- What a screen reader announces for this widget: the name given
			-- with `set_accessible_name', else `default_accessible_name'.
		do
			if attached accessible_name_override as al_name then
				Result := al_name
			else
				Result := default_accessible_name
			end
		end

	default_accessible_name: STRING_32
			-- The widget's own name: its label or text where it has one.
		do
			create Result.make_empty
		end

	accessible_role: INTEGER
			-- Its UI Automation control type (a {SW_ACCESSIBILITY} `Role_'
			-- constant): a pane when it holds widgets, else custom. Widgets
			-- with a standard role redefine it.
		do
			if accessible_children.is_empty then
				Result := {SW_ACCESSIBILITY}.Role_custom
			else
				Result := {SW_ACCESSIBILITY}.Role_pane
			end
		end

	accessible_value: detachable STRING_32
			-- Its current value, read-only, when it has one (a text box's
			-- text, a progress percentage); Void for none.
		do
		end

	accessible_children: ARRAYED_LIST [SW_WIDGET]
			-- The widgets a screen reader can reach below this one: those it
			-- shows (`sub_widgets' by default; a notebook redefines it to its
			-- shown page only).
		do
			Result := sub_widgets
		end

	set_accessible_name (a_name: READABLE_STRING_GENERAL)
			-- Name this widget for screen readers (an icon button, a field
			-- whose label is drawn beside it).
		do
			create accessible_name_override.make_from_string_general (a_name)
		ensure
			named: accessible_name.same_string_general (a_name)
		end

	accessible_name_override: detachable STRING_32
			-- The name given with `set_accessible_name'.

	accessible_node_id: INTEGER
			-- This widget's node id for UI Automation: given once, the first
			-- time it is published, and kept for its life - so a screen
			-- reader's reference survives widgets added before it (scan 13:
			-- ids were tree positions and shifted).
		do
			if accessible_node_id_cache = 0 then
				accessible_node_id_counter.put (accessible_node_id_counter.item + 1)
				accessible_node_id_cache := accessible_node_id_counter.item
			end
			Result := accessible_node_id_cache
		ensure
			positive: Result > 0
		end

feature {NONE} -- Implementation

	accessible_node_id_cache: INTEGER

	accessible_node_id_counter: CELL [INTEGER]
			-- The last node id given, per processor: a window's widgets all live on its one processor,
			-- so ids stay unique where UI Automation reads them. Not once ("PROCESS"): a process-wide
			-- once of a non-separate type is rejected under SCOOP (VFFD(8)), and every SCOOP app
			-- failed to compile from 0.34.1 (2026-10-25) until this (simple_bible's window, 2026-10-26).
		once
			create Result.put (0)
		end

	is_disabled: BOOLEAN
			-- Stored inverted so a fresh widget is enabled by default.

feature -- Printing (GW-20)

	print_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- How tall all of this is at `a_width', to be printed: its
			-- preferred height (a widget that scrolls answers all of its
			-- content).
		require
			positive_width: a_width > 0.0
		do
			Result := preferred_height (a_p, a_width)
		ensure
			non_negative: Result >= 0.0
		end

	clean_break (a_y: REAL_64): REAL_64
			-- Where a page may end at or above `a_y' without cutting through
			-- a line of text. A widget without parts keeps itself whole (its
			-- top, when `a_y' falls inside it); one with parts asks the parts
			-- `a_y' falls in. Valid after `arrange'.
		local
			l_inside: BOOLEAN
		do
			Result := a_y
			if a_y > y and a_y < y + height then
				across
					sub_widgets as al_part
				loop
					if a_y > al_part.y and a_y < al_part.y + al_part.height then
						Result := Result.min (al_part.clean_break (a_y))
						l_inside := True
					end
				end
				if not l_inside and sub_widgets.is_empty then
					Result := y
				end
			end
		ensure
			no_lower: Result <= a_y
		end

invariant
	sane_size: width >= 0.0 and height >= 0.0
	pressed_only_when_enabled: is_pressed implies is_enabled
	grow_non_negative: grow >= 0.0
	anchors_sane: min_width >= 0.0 and min_height >= 0.0
		and max_width >= 0.0 and max_height >= 0.0

end
