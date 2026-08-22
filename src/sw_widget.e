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
			is_focused := a_focused
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

	set_hovered (a_hovered: BOOLEAN)
		do
			is_hovered := a_hovered
		ensure
			set: is_hovered = a_hovered
		end

	set_pressed (a_pressed: BOOLEAN)
		require
			only_enabled_press: a_pressed implies is_enabled
		do
			is_pressed := a_pressed
		ensure
			set: is_pressed = a_pressed
		end

	set_enabled (a_enabled: BOOLEAN)
		do
			is_disabled := not a_enabled
		ensure
			set: is_enabled = a_enabled
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

	handle_char (a_code: INTEGER)
		do
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
		end

feature {NONE} -- Implementation

	is_disabled: BOOLEAN
			-- Stored inverted so a fresh widget is enabled by default.

invariant
	sane_size: width >= 0.0 and height >= 0.0
	pressed_only_when_enabled: is_pressed implies is_enabled
	grow_non_negative: grow >= 0.0
	anchors_sane: min_width >= 0.0 and min_height >= 0.0
		and max_width >= 0.0 and max_height >= 0.0

end
