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
			sub_widgets, cursor_kind,
			arrange, widget_at, handle_click, handle_drag,
			handle_double_click
		end

create
	make

feature {NONE} -- Initialization

	cursor_kind: INTEGER
			-- Resize arrows matching the divider's axis.
		do
			if is_horizontal then
				Result := 4
			else
				Result := 3
			end
		end

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
			-- First pane's share (left, or top when horizontal),
			-- 0.15 .. 0.85.

	is_horizontal: BOOLEAN
			-- Does the divider run horizontally (top/bottom panes)?
			-- `left_child' is then the TOP pane, `right_child' the
			-- bottom - the names keep their creation order.

	set_horizontal (a_flag: BOOLEAN)
		do
			is_horizontal := a_flag
		ensure
			set: is_horizontal = a_flag
		end

	with_horizontal: like Current
		do
			set_horizontal (True)
			Result := Current
		ensure
			chained: Result = Current
		end

	Divider_w: REAL_64 = 9.0

feature -- Element change

	set_ratio (a_ratio: REAL_64)
		do
			ratio := a_ratio.max (0.15).min (0.85)
		ensure
			clamped: ratio >= 0.15 and ratio <= 0.85
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (2)
			Result.extend (left_child)
			Result.extend (right_child)
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			lw: REAL_64
		do
			if is_horizontal then
				Result := left_child.preferred_height (a_p, a_width) + Divider_w
					+ right_child.preferred_height (a_p, a_width)
			else
				lw := (a_width - Divider_w) * ratio
				Result := left_child.preferred_height (a_p, lw)
					.max (right_child.preferred_height (a_p, a_width - Divider_w - lw))
			end
		end

	arrange (a_p: SW_PAINTER)
		local
			lw: REAL_64
		do
			if is_horizontal then
				lw := (height - Divider_w) * ratio
				left_child.set_bounds (x, y, width, lw)
				left_child.arrange (a_p)
				right_child.set_bounds (x, y + lw + Divider_w, width, height - lw - Divider_w)
				right_child.arrange (a_p)
			else
				lw := (width - Divider_w) * ratio
				left_child.set_bounds (x, y, lw, height)
				left_child.arrange (a_p)
				right_child.set_bounds (x + lw + Divider_w, y, width - lw - Divider_w, height)
				right_child.arrange (a_p)
			end
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
			if is_horizontal then
				cy := y + (height - Divider_w) * ratio + Divider_w / 2.0
				if shows_hover then
					a_p.set_color (t.wash_accent)
					a_p.rrect_fill (x + 2.0, cy - Divider_w / 2.0 + 1.0, width - 4.0, Divider_w - 2.0, 3.0)
					a_p.set_color (t.accent)
					a_p.fill_rect (x + 2.0, cy - 1.0, width - 4.0, 2.0)
				else
					a_p.set_color (t.outline)
					a_p.fill_rect (x + 2.0, cy - 0.5, width - 4.0, 1.0)
				end
				dx := x + width / 2.0 - 12.0
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
					a_p.rrect_fill (dx + i * 6.0, cy - 1.5, 3.0, 3.0, 1.5)
					i := i + 1
				end
			else
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
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		local
			dx: REAL_64
		do
			if contains (a_px, a_py) then
				if is_horizontal then
					dx := y + (height - Divider_w) * ratio
					if a_py >= dx - 2.0 and a_py <= dx + Divider_w + 2.0 then
						Result := Current
					elseif a_py < dx then
						Result := left_child.widget_at (a_px, a_py)
					else
						Result := right_child.widget_at (a_px, a_py)
					end
				else
					dx := x + (width - Divider_w) * ratio
					if a_px >= dx - 2.0 and a_px <= dx + Divider_w + 2.0 then
						Result := Current
					elseif a_px < dx then
						Result := left_child.widget_at (a_px, a_py)
					else
						Result := right_child.widget_at (a_px, a_py)
					end
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
			if is_horizontal then
				dx := y + (height - Divider_w) * ratio
				Result := a_py >= dx - 2.0 and a_py <= dx + Divider_w + 2.0
			else
				dx := x + (width - Divider_w) * ratio
				Result := a_px >= dx - 2.0 and a_px <= dx + Divider_w + 2.0
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- Double-click the divider: the ratio snaps home to 0.5.
		do
			Result := handle_click (a_px, a_py)
			if Result then
				set_ratio (0.5)
			end
		ensure then
			reset: Result implies ratio = 0.5
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if is_horizontal then
				if height > Divider_w then
					set_ratio ((a_py - y) / (height - Divider_w))
				end
			elseif width > Divider_w then
				set_ratio ((a_px - x) / (width - Divider_w))
			end
		end

invariant
	children_adopted: left_child.parent = Current and right_child.parent = Current
	ratio_clamped: ratio >= 0.15 and ratio <= 0.85

end
