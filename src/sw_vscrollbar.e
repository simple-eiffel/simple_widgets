note
	description: "[
		The vertical scrollbar every scrolling widget draws at its right
		edge: the track, the thumb, a thumb drag that keeps its grab
		point, a press on the bare track that pages toward it, and the
		wheel rule. One helper object per widget, owned, not inherited:
		the widget keeps its own scroll position and asks the bar what
		a press, a drag or a wheel notch turns it into.

		    place (box, theme)        each frame (or arrange): where the
		                              owner stands and how big text is
		    set_extent (view, content) the visible and the whole height
		    press / drag_to / release the pointer
		    wheel_scroll              Wheel_lines lines a notch, of the
		                              owner's own line height
		    draw (painter, scroll, hot)

		SIZES COME FROM THE THEME. The width is SW_THEME.scrollbar_width
		and the smallest thumb SW_THEME.min_thumb, both scaled by
		`text_scale'; the bar's own insets and corners scale with them.
		Lifted (0.20.0) from six widgets that each carried a copy, from
		SW_CHAT_THREAD's, the one that kept the grab point and paged on a
		track press. Its arithmetic moved up to SW_SCROLLBAR (0.49.0) when
		the River of Time needed a bar across time (SW_HSCROLLBAR); the
		names here are the vertical ones.
	]"
	author: "Larry Rix"

class
	SW_VSCROLLBAR

inherit
	SW_SCROLLBAR
		rename
			track_start as track_y,
			track_length as track_h,
			thumb_length as thumb_height,
			thumb_start as thumb_top
		end

create
	make

feature -- Geometry

	track_x: REAL_64
			-- The bar's left edge.

	contains (a_px, a_py: REAL_64): BOOLEAN
			-- Is (`a_px', `a_py') on the bar's column, while it is needed?
		do
			Result := is_needed and then a_px >= track_x and then a_px < track_x + bar_width
				and then a_py >= track_y - Track_inset * scale
				and then a_py <= track_y + track_h + Track_inset * scale
		end

feature -- Placement

	place (a_x, a_y, a_width, a_height: REAL_64; a_theme: SW_THEME)
			-- The owner's box is `a_x', `a_y', `a_width' x `a_height'; the
			-- bar stands at its right edge, sized by `a_theme'.
		do
			scale := a_theme.text_scale
			bar_width := a_theme.scrollbar_width
			min_thumb := a_theme.min_thumb
			track_x := a_x + a_width - bar_width
			track_y := a_y + Track_inset * scale
			track_h := (a_height - 2.0 * Track_inset * scale).max (1.0)
		ensure then
			at_right_edge: track_x = a_x + a_width - bar_width
		end

feature -- Drawing

	draw (a_p: SW_PAINTER; a_scroll: REAL_64; a_hot: BOOLEAN)
			-- The track and the thumb for `a_scroll', when needed; the
			-- thumb in the accent while held or `a_hot' (pointer on it).
		local
			t: SW_THEME
		do
			if is_needed then
				t := a_p.theme
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (track_x, track_y, bar_width - 2.0 * scale, track_h, 4.0 * scale)
				if is_dragging or a_hot then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (track_x + 1.5 * scale, thumb_top (a_scroll), bar_width - 5.0 * scale,
					thumb_height, 3.0 * scale)
			end
		end

end
