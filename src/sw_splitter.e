note
	description: "[
		Two children side by side with a draggable divider. The ratio
		is contract-clamped so neither pane can vanish; the divider
		wears grip dots and consumes its own clicks and drags.
	]"

class
	SW_SPLITTER

inherit
	SW_WIDGET
		redefine
			arrange, widget_at, handle_click, handle_drag
		end

create
	make

feature {NONE} -- Initialization

	make (a_left, a_right: SW_WIDGET)
		do
			left_child := a_left
			right_child := a_right
			a_left.set_parent (Current)
			a_right.set_parent (Current)
			ratio := 0.5
		ensure
			adopted: a_left.parent = Current and a_right.parent = Current
			balanced: ratio = 0.5
		end

feature -- Access

	left_child: SW_WIDGET
	right_child: SW_WIDGET

	ratio: REAL_64
			-- Left pane's share of the width, 0.15 .. 0.85.

	Divider_w: REAL_64 = 9.0

feature -- Element change

	set_ratio (a_ratio: REAL_64)
		do
			ratio := a_ratio.max (0.15).min (0.85)
		ensure
			clamped: ratio >= 0.15 and ratio <= 0.85
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			lw: REAL_64
		do
			lw := (a_width - Divider_w) * ratio
			Result := left_child.preferred_height (a_p, lw)
				.max (right_child.preferred_height (a_p, a_width - Divider_w - lw))
		end

	arrange (a_p: SW_PAINTER)
		local
			lw: REAL_64
		do
			lw := (width - Divider_w) * ratio
			left_child.set_bounds (x, y, lw, height)
			left_child.arrange (a_p)
			right_child.set_bounds (x + lw + Divider_w, y, width - lw - Divider_w, height)
			right_child.arrange (a_p)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			dx, cy: REAL_64
			i: INTEGER
		do
			t := a_p.theme
			left_child.draw (a_p)
			right_child.draw (a_p)
			dx := x + (width - Divider_w) * ratio + Divider_w / 2.0
			if shows_hover then
					-- announce draggability: a wide accent bar under the
					-- pointer says push me, pull me
				a_p.set_color (t.wash_accent)
				a_p.rrect_fill (dx - Divider_w / 2.0 + 1.0, y + 2.0, Divider_w - 2.0, height - 4.0, 3.0)
				a_p.set_color (t.accent)
				a_p.fill_rect (dx - 1.0, y + 2.0, 2.0, height - 4.0)
			else
				a_p.set_color (t.outline)
				a_p.fill_rect (dx - 0.5, y + 2.0, 1.0, height - 4.0)
			end
			cy := y + height / 2.0 - 12.0
			from
				i := 1
			until
				i > 3
			loop
				if shows_hover then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.rrect_fill (dx - 1.5, cy + i * 6.0, 3.0, 3.0, 1.5)
				i := i + 1
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		local
			dx: REAL_64
		do
			if contains (a_px, a_py) then
				dx := x + (width - Divider_w) * ratio
				if a_px >= dx - 2.0 and a_px <= dx + Divider_w + 2.0 then
					Result := Current
				elseif a_px < dx then
					Result := left_child.widget_at (a_px, a_py)
				else
					Result := right_child.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A press on the divider begins the drag (the window's
			-- capture routes the moves back here).
		local
			dx: REAL_64
		do
			dx := x + (width - Divider_w) * ratio
			Result := a_px >= dx - 2.0 and a_px <= dx + Divider_w + 2.0
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if width > Divider_w then
				set_ratio ((a_px - x) / (width - Divider_w))
			end
		end

invariant
	children_adopted: left_child.parent = Current and right_child.parent = Current
	ratio_clamped: ratio >= 0.15 and ratio <= 0.85

end
