note
	description: "[
		Pointing into a scrolling stack of items (0.24.0): SW_TEXT_POINTING,
		SW_VSCROLLING and SW_STACKED_ITEMS joined ONCE, here, so a widget
		that needs all three inherits one parent and writes its own
		redefinitions in one clause. Each of the three inherits SW_WIDGET;
		SW_TEXT_POINTING is the one that redefines some of its features
		(the pointer's), so the other two let go of theirs (`undefine') and
		those features join. It also says once what every such widget says
		alike: it takes the focus, wants the pointer's position, and asks
		its `viewport_height' of a layout.
	]"
	author: "Larry Rix"

deferred class
	SW_STACKED_POINTING

inherit
	SW_TEXT_POINTING
		redefine
			accepts_focus, wants_hover_point
		end

	SW_VSCROLLING
		undefine
			set_hover_point, set_hovered, dwell_ms, handle_dwell, hover_card_at,
			accepts_focus, wants_hover_point
		end

	SW_STACKED_ITEMS
		undefine
			set_hover_point, set_hovered, dwell_ms, handle_dwell, hover_card_at,
			accepts_focus, wants_hover_point
		end

feature -- Layout

	accepts_focus: BOOLEAN
			-- Text to point into and scroll: it takes the focus.
		do
			Result := True
		end

	wants_hover_point: BOOLEAN
			-- It follows the pointer to the character under it.
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The height asked of a layout.
		do
			Result := viewport_height
		end

end
