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
		track press.
	]"
	author: "Larry Rix"

class
	SW_VSCROLLBAR

create
	make

feature {NONE} -- Initialization

	make
			-- A bar at 1x, nowhere yet, with nothing to scroll.
		do
			bar_width := 12.0
			min_thumb := 24.0
			scale := 1.0
			track_h := 1.0
		ensure
			nothing_to_scroll: not is_needed
			not_dragging: not is_dragging
		end

feature -- Constants

	Wheel_lines: INTEGER = 3
			-- Lines one wheel notch scrolls (the Windows default).

	Track_inset: REAL_64 = 2.0
			-- The track's gap from the owner's top and bottom edges, at 1x.

feature -- Geometry

	bar_width: REAL_64
			-- The column the bar takes at the owner's right edge.

	min_thumb: REAL_64
			-- The thumb is never shorter, so it stays grabbable.

	scale: REAL_64
			-- The theme's `text_scale' at the last `place'.

	track_x: REAL_64
	track_y: REAL_64
	track_h: REAL_64

	viewport: REAL_64
			-- The height the owner shows.

	content: REAL_64
			-- The height of everything it could show.

	max_scroll: REAL_64
			-- How far the scroll position can go.
		do
			Result := (content - viewport).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	is_needed: BOOLEAN
			-- Does the content overflow, so the bar draws and answers?
		do
			Result := max_scroll > 0.0
		end

	clamped (a_scroll: REAL_64): REAL_64
			-- `a_scroll' kept inside 0 .. `max_scroll'.
		do
			Result := a_scroll.max (0.0).min (max_scroll)
		ensure
			low: Result >= 0.0
			high: Result <= max_scroll
		end

	thumb_height: REAL_64
			-- The viewport's share of the track, never below `min_thumb'
			-- nor above the track.
		do
			if content > 0.0 then
				Result := viewport / content * track_h
			end
			Result := Result.max (min_thumb).min (track_h)
		ensure
			fits_track: Result > 0.0 and Result <= track_h
		end

	thumb_top (a_scroll: REAL_64): REAL_64
			-- The thumb's top for scroll position `a_scroll'.
		do
			if max_scroll > 0.0 then
				Result := track_y + (clamped (a_scroll) / max_scroll) * (track_h - thumb_height)
			else
				Result := track_y
			end
		ensure
			inside_track: Result >= track_y - 0.001
				and Result + thumb_height <= track_y + track_h + 0.001
		end

	contains (a_px, a_py: REAL_64): BOOLEAN
			-- Is (`a_px', `a_py') on the bar's column, while it is needed?
		do
			Result := is_needed and then a_px >= track_x and then a_px < track_x + bar_width
				and then a_py >= track_y - Track_inset * scale
				and then a_py <= track_y + track_h + Track_inset * scale
		end

feature -- Status

	is_dragging: BOOLEAN
			-- Is the thumb held?

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
		ensure
			at_right_edge: track_x = a_x + a_width - bar_width
			width_from_theme: bar_width = a_theme.scrollbar_width
		end

	set_extent (a_viewport, a_content: REAL_64)
			-- The owner shows `a_viewport' of `a_content'.
		require
			non_negative: a_viewport >= 0.0 and a_content >= 0.0
		do
			viewport := a_viewport
			content := a_content
		ensure
			viewport_set: viewport = a_viewport
			content_set: content = a_content
		end

feature -- Pointer

	press (a_py, a_scroll: REAL_64): REAL_64
			-- The scroll position after a press at `a_py' on the bar: on
			-- the thumb a drag begins and nothing moves yet; above or below
			-- it the view pages that way.
		require
			needed: is_needed
		local
			l_top: REAL_64
		do
			l_top := thumb_top (a_scroll)
			Result := clamped (a_scroll)
			if a_py >= l_top and a_py <= l_top + thumb_height then
				is_dragging := True
				grab_offset := a_py - l_top
			elseif a_py < l_top then
				Result := clamped (a_scroll - viewport)
			else
				Result := clamped (a_scroll + viewport)
			end
		ensure
			in_range: Result >= 0.0 and Result <= max_scroll
		end

	drag_to (a_py: REAL_64): REAL_64
			-- The scroll position with the thumb held at `a_py', the grab
			-- point kept under the pointer.
		require
			dragging: is_dragging
		local
			l_span: REAL_64
		do
			l_span := (track_h - thumb_height).max (1.0)
			Result := clamped ((a_py - grab_offset - track_y) / l_span * max_scroll)
		ensure
			in_range: Result >= 0.0 and Result <= max_scroll
		end

	release
			-- Let go of the thumb.
		do
			is_dragging := False
		ensure
			not_dragging: not is_dragging
		end

	wheel_scroll (a_scroll: REAL_64; a_delta: INTEGER; a_line: REAL_64): REAL_64
			-- The scroll position after a wheel turn of `a_delta' (120 a
			-- notch, positive away from the reader), `Wheel_lines' lines of
			-- `a_line' pixels a notch.
		require
			line_positive: a_line > 0.0
		do
			Result := clamped (a_scroll - a_delta / 120.0 * Wheel_lines * a_line)
		ensure
			in_range: Result >= 0.0 and Result <= max_scroll
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

feature {NONE} -- Implementation

	grab_offset: REAL_64
			-- Where on the thumb the press landed.

invariant
	sizes_positive: bar_width > 0.0 and min_thumb > 0.0 and scale > 0.0
	track_positive: track_h > 0.0
	extent_non_negative: viewport >= 0.0 and content >= 0.0

end
