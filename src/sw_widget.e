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

	handle_context (a_px, a_py: REAL_64): BOOLEAN
			-- React to a right-click; True when consumed. Prefer
			-- declaring a menu via context_menu and letting the window
			-- present it; use this hook only for non-menu reactions.
		do
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

end
