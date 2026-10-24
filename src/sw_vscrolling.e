note
	description: "[
		A widget that scrolls its content vertically under a scrollbar
		at its right edge (0.20.0): the scroll position and its one door
		(`scroll_to', which clamps and tells `on_scroll'), the bar
		(SW_VSCROLLBAR) placed and drawn, its press, drag and release,
		the wheel and the paging keys.

		A descendant says two things:

		    scroll_extent   how tall all of its content is
		    wheel_line      how far one line is (a row, a line of text)

		and calls the pieces from its own handlers - `press_bar' first in
		`handle_click', `drag_bar' in `handle_drag', `release_bar' in
		`handle_release', `wheel_scrolled' in `handle_wheel', `scroll_key'
		in `handle_key', `place_bar' wherever it lays out, `draw_bar'
		last in `draw'. This class redefines none of SW_WIDGET's
		features, so a widget can inherit it beside SW_TEXT_POINTING or
		SW_TEXT_SELECTION without a clash.
	]"
	author: "Larry Rix"

deferred class
	SW_VSCROLLING

inherit
	SW_WIDGET

feature -- Scrolling

	scroll_extent: REAL_64
			-- The height of everything the widget could show.
		deferred
		ensure
			non_negative: Result >= 0.0
		end

	wheel_line: REAL_64
			-- One line's height: a wheel notch scrolls
			-- SW_VSCROLLBAR.Wheel_lines of them.
		deferred
		ensure
			positive: Result > 0.0
		end

	scroll_y: REAL_64
			-- How far the content is shifted up; 0 .. `max_scroll'.

	max_scroll: REAL_64
			-- How far `scroll_y' can go.
		do
			Result := (scroll_extent - height).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	bar: SW_VSCROLLBAR
			-- The scrollbar at the right edge.
		attribute
			create Result.make
		end

	on_scroll: detachable PROCEDURE [REAL_64]
			-- The content scrolled: the new `scroll_y'.

	set_on_scroll (a_action: detachable PROCEDURE [REAL_64])
		do
			on_scroll := a_action
		ensure
			set: on_scroll = a_action
		end

	scroll_to (a_y: REAL_64)
			-- Scroll to `a_y', clamped; `on_scroll' hears a real move.
		local
			l_old: REAL_64
		do
			l_old := scroll_y
			scroll_y := a_y.max (0.0).min (max_scroll)
			if scroll_y /= l_old and then attached on_scroll as al_s then
				al_s.call (scroll_y)
			end
		ensure
			clamped: scroll_y >= 0.0 and scroll_y <= max_scroll
		end

feature {NONE} -- Scrollbar pieces

	place_bar (a_theme: SW_THEME)
			-- Seat the bar at the right edge, sized by `a_theme', for the
			-- current extent, and keep `scroll_y' inside it.
		do
			bar.place (x, y, width, height, a_theme)
			bar.set_extent (height.max (0.0), scroll_extent)
			scroll_y := scroll_y.max (0.0).min (max_scroll)
		ensure
			clamped: scroll_y >= 0.0 and scroll_y <= max_scroll
		end

	draw_bar (a_p: SW_PAINTER)
			-- The bar, its thumb lit while the pointer is on the bar.
		do
			bar.draw (a_p, scroll_y, shows_hover and then bar.contains (hover_px, hover_py))
		end

	press_bar (a_px, a_py: REAL_64): BOOLEAN
			-- Was the press at (`a_px', `a_py') on the bar? Then it took
			-- it: the thumb is held, or the view paged toward the press.
		do
			if bar.contains (a_px, a_py) then
				scroll_to (bar.press (a_py, scroll_y))
				Result := True
			end
		end

	drag_bar (a_py: REAL_64): BOOLEAN
			-- Is the thumb held? Then it follows `a_py'.
		do
			if bar.is_dragging then
				scroll_to (bar.drag_to (a_py))
				Result := True
			end
		end

	release_bar
			-- Let go of the thumb.
		do
			bar.release
		ensure
			released: not bar.is_dragging
		end

	wheel_scrolled (a_delta: INTEGER)
			-- Scroll by a wheel turn of `a_delta'.
		do
			scroll_to (bar.wheel_scroll (scroll_y, a_delta, wheel_line))
		end

	scroll_key (a_vk: INTEGER): BOOLEAN
			-- PageUp 33, PageDown 34, End 35, Home 36: scroll and answer
			-- True; any other key False.
		do
			Result := True
			inspect a_vk
			when 33 then
				scroll_to (scroll_y - height)
			when 34 then
				scroll_to (scroll_y + height)
			when 35 then
				scroll_to (max_scroll)
			when 36 then
				scroll_to (0.0)
			else
				Result := False
			end
		end

invariant
	scroll_non_negative: scroll_y >= 0.0

end
