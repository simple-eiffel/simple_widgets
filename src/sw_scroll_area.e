note
	description: "[
		A fixed-height viewport over one taller child. The child is
		laid out at its natural height and shifted by the scroll
		offset; the painter clips to the viewport so overflow never
		paints. Mouse wheel scrolls; the drawn scrollbar thumb drags.
	]"

class
	SW_SCROLL_AREA

inherit
	SW_WIDGET
		redefine
			sub_widgets,
			arrange, widget_at, handle_wheel, handle_click, handle_drag,
			wants_hover_point, handle_release
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			wheel_step := 96.0
			create bar.make
		ensure
			kept: viewport_height = a_viewport_height
		end

feature -- Access

	child: detachable SW_WIDGET

	bar: SW_VSCROLLBAR
			-- The vertical scrollbar at the right edge.

	viewport_height: REAL_64

	scroll_y: REAL_64
			-- How far the content is shifted up; 0 .. max_scroll.

	scroll_x: REAL_64
			-- How far the content is shifted left; 0 .. max_scroll_x.

	content_height: REAL_64
			-- The child's natural height at the content width.

	content_width: REAL_64
			-- The child's announced width, at least the viewport's.

	wheel_step: REAL_64
			-- Pixels one wheel notch travels - the responsiveness knob.

	max_scroll: REAL_64
		do
			Result := (content_height - height).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	max_scroll_x: REAL_64
		do
			Result := (content_width - (width - bar.bar_width - 4.0)).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

feature -- Element change

	set_child (a_child: SW_WIDGET)
		do
			child := a_child
			a_child.set_parent (Current)
		ensure
			adopted: a_child.parent = Current
		end

	scroll_to (a_y: REAL_64)
		do
			scroll_y := a_y.max (0.0).min (max_scroll)
		ensure
			clamped: scroll_y >= 0.0 and scroll_y <= max_scroll
		end

	scroll_to_x (a_x: REAL_64)
		do
			scroll_x := a_x.max (0.0).min (max_scroll_x)
		ensure
			clamped: scroll_x >= 0.0 and scroll_x <= max_scroll_x
		end

	set_wheel_step (a_px: REAL_64)
			-- Program the responsiveness: pixels per wheel notch.
		require
			positive: a_px > 0.0
		do
			wheel_step := a_px
		ensure
			set: wheel_step = a_px
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (1)
			if attached child as c then
				Result.extend (c)
			end
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := viewport_height
		end

	arrange (a_p: SW_PAINTER)
		local
			inner_w: REAL_64
		do
			bar.place (x, y, width, height, a_p.theme)
			if attached child as c then
				inner_w := (width - bar.bar_width - 4.0).max (0.0)
				content_width := c.preferred_width (a_p).max (inner_w)
				content_height := c.preferred_height (a_p, content_width)
				scroll_y := scroll_y.min (max_scroll)
				scroll_x := scroll_x.min (max_scroll_x)
				c.set_bounds (x - scroll_x, y - scroll_y, content_width, content_height)
				c.arrange (a_p)
			end
			bar.set_extent (height, content_height)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			track_w, thumb_w, thumb_x, bw: REAL_64
		do
			t := a_p.theme
			a_p.push_clip (x, y, width, height)
			if attached child as c then
				c.draw (a_p)
			end
			a_p.pop_clip
			bar.draw (a_p, scroll_y, shows_hover and then bar.contains (hover_px, hover_py))
			if max_scroll_x > 0.0 then
				bw := bar.bar_width
				track_w := width - bw - 6.0
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + 2.0, y + height - bw, track_w, bw - 2.0, 4.0)
				thumb_w := ((width - bw) / content_width * track_w).max (24.0)
				thumb_x := x + 2.0 + (scroll_x / max_scroll_x) * (track_w - thumb_w)
				if shows_hover and then hover_py >= y + height - bw then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (thumb_x, y + height - bw + 1.5, thumb_w, bw - 5.0, 3.0)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if bar.contains (a_px, a_py)
					or else (max_scroll_x > 0.0 and then a_py >= y + height - bar.bar_width)
				then
					Result := Current
				elseif attached child as c then
					Result := c.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Input

	handle_wheel (a_delta: INTEGER): BOOLEAN
			-- One notch travels `wheel_step' pixels; Shift steers the
			-- wheel sideways when there is sideways to go.
		local
			keys: SW_KEYS
		do
			create keys
			if keys.shift_down and then max_scroll_x > 0.0 then
				scroll_to_x (scroll_x - a_delta / 120.0 * wheel_step)
			else
				scroll_to (bar.wheel_scroll (scroll_y, a_delta, wheel_step / bar.Wheel_lines))
			end
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if bar.contains (a_px, a_py) then
					-- on the thumb a drag begins; on the track the view pages
				scroll_to (bar.press (a_py, scroll_y))
				dragging_horizontal := False
				Result := True
			elseif a_py >= y + height - bar.bar_width and max_scroll_x > 0.0 then
				scroll_to_x ((a_px - x) / width * max_scroll_x)
				dragging_horizontal := True
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if bar.is_dragging then
				scroll_to (bar.drag_to (a_py))
			elseif dragging_horizontal and then max_scroll_x > 0.0 then
				scroll_to_x ((a_px - x) / width * max_scroll_x)
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go of either thumb.
		do
			bar.release
			dragging_horizontal := False
		ensure then
			released: not bar.is_dragging and not dragging_horizontal
		end

feature {NONE} -- Drag state

	dragging_horizontal: BOOLEAN
			-- Which bar the active drag belongs to.

invariant
	viewport_positive: viewport_height > 0.0
	scroll_non_negative: scroll_y >= 0.0
	scroll_x_non_negative: scroll_x >= 0.0
	step_positive: wheel_step > 0.0

end
