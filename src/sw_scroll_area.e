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
			arrange, widget_at, handle_wheel, handle_click, handle_drag,
			wants_hover_point
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
		ensure
			kept: viewport_height = a_viewport_height
		end

feature -- Access

	child: detachable SW_WIDGET

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
			Result := (content_width - (width - Bar_w - 4.0)).max (0.0)
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

feature -- Layout

	Bar_w: REAL_64 = 11.0

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
			if attached child as c then
				inner_w := (width - Bar_w - 4.0).max (0.0)
				content_width := c.preferred_width (a_p).max (inner_w)
				content_height := c.preferred_height (a_p, content_width)
				scroll_y := scroll_y.min (max_scroll)
				scroll_x := scroll_x.min (max_scroll_x)
				c.set_bounds (x - scroll_x, y - scroll_y, content_width, content_height)
				c.arrange (a_p)
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			track_h, thumb_h, thumb_y: REAL_64
			track_w, thumb_w, thumb_x: REAL_64
		do
			t := a_p.theme
			a_p.push_clip (x, y, width, height)
			if attached child as c then
				c.draw (a_p)
			end
			a_p.pop_clip
			if max_scroll > 0.0 then
				track_h := height - 4.0
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + width - Bar_w, y + 2.0, Bar_w - 2.0, track_h, 4.0)
				thumb_h := (height / content_height * track_h).max (24.0)
				thumb_y := y + 2.0 + (scroll_y / max_scroll) * (track_h - thumb_h)
				if shows_hover and then hover_px >= x + width - Bar_w then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (x + width - Bar_w + 1.5, thumb_y, Bar_w - 5.0, thumb_h, 3.0)
			end
			if max_scroll_x > 0.0 then
				track_w := width - Bar_w - 6.0
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + 2.0, y + height - Bar_w, track_w, Bar_w - 2.0, 4.0)
				thumb_w := ((width - Bar_w) / content_width * track_w).max (24.0)
				thumb_x := x + 2.0 + (scroll_x / max_scroll_x) * (track_w - thumb_w)
				if shows_hover and then hover_py >= y + height - Bar_w then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (thumb_x, y + height - Bar_w + 1.5, thumb_w, Bar_w - 5.0, 3.0)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if a_px >= x + width - Bar_w
					or else (max_scroll_x > 0.0 and then a_py >= y + height - Bar_w)
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
				scroll_to (scroll_y - a_delta / 120.0 * wheel_step)
			end
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if a_px >= x + width - Bar_w and max_scroll > 0.0 then
					-- jump-scroll toward the click, then the drag refines
				scroll_to ((a_py - y) / height * max_scroll)
				dragging_horizontal := False
				Result := True
			elseif a_py >= y + height - Bar_w and max_scroll_x > 0.0 then
				scroll_to_x ((a_px - x) / width * max_scroll_x)
				dragging_horizontal := True
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if dragging_horizontal then
				if max_scroll_x > 0.0 then
					scroll_to_x ((a_px - x) / width * max_scroll_x)
				end
			elseif max_scroll > 0.0 then
				scroll_to ((a_py - y) / height * max_scroll)
			end
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
