note
	description: "[
		A scrollbar along one axis (0.49.0, lifted from SW_VSCROLLBAR when the
		River of Time needed a bar across time): the arithmetic every bar
		shares, whatever its direction. The owner shows `viewport' of
		`content'; its scroll position runs 0 .. `max_scroll'; the thumb is
		the viewport's share of the track, never below `min_thumb'; a press
		on the thumb holds it (keeping the grab point), a press on the bare
		track pages toward it; a wheel notch scrolls Wheel_lines lines.

		Positions along the track are ALONG the bar's axis: y for SW_VSCROLLBAR,
		x for SW_HSCROLLBAR. An heir says where it stands (`place'), what it
		covers (`contains') and how it looks (`draw'); it renames the track
		and thumb to its own axis's words.

		SIZES COME FROM THE THEME: the thickness is SW_THEME.scrollbar_width
		and the smallest thumb SW_THEME.min_thumb, both scaled by text_scale.
	]"
	author: "Larry Rix"

deferred class
	SW_SCROLLBAR

feature {NONE} -- Initialization

	make
			-- A bar at 1x, nowhere yet, with nothing to scroll.
		do
			bar_width := 12.0
			min_thumb := 24.0
			scale := 1.0
			track_length := 1.0
		ensure
			nothing_to_scroll: not is_needed
			not_dragging: not is_dragging
		end

feature -- Constants

	Wheel_lines: INTEGER = 3
			-- Lines one wheel notch scrolls (the Windows default).

	Track_inset: REAL_64 = 2.0
			-- The track's gap from the owner's edges along the bar, at 1x.

feature -- Geometry

	bar_width: REAL_64
			-- The bar's thickness, across its axis.

	min_thumb: REAL_64
			-- The thumb is never shorter, so it stays grabbable.

	scale: REAL_64
			-- The theme's `text_scale' at the last `place'.

	track_start: REAL_64
			-- Where the track begins along the axis.

	track_length: REAL_64
			-- How long the track is along the axis.

	viewport: REAL_64
			-- How much the owner shows.

	content: REAL_64
			-- How much there is to show.

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

	thumb_length: REAL_64
			-- The viewport's share of the track, never below `min_thumb' nor above the track.
		do
			if content > 0.0 then
				Result := viewport / content * track_length
			end
			Result := Result.max (min_thumb).min (track_length)
		ensure
			fits_track: Result > 0.0 and Result <= track_length
		end

	thumb_start (a_scroll: REAL_64): REAL_64
			-- Where the thumb begins along the axis for scroll position `a_scroll'.
		do
			if max_scroll > 0.0 then
				Result := track_start + (clamped (a_scroll) / max_scroll) * (track_length - thumb_length)
			else
				Result := track_start
			end
		ensure
			inside_track: Result >= track_start - 0.001
				and Result + thumb_length <= track_start + track_length + 0.001
		end

	contains (a_px, a_py: REAL_64): BOOLEAN
			-- Is (`a_px', `a_py') on the bar, while it is needed?
		deferred
		end

feature -- Status

	is_dragging: BOOLEAN
			-- Is the thumb held?

feature -- Placement

	place (a_x, a_y, a_width, a_height: REAL_64; a_theme: SW_THEME)
			-- The owner's box is `a_x', `a_y', `a_width' x `a_height'; the bar stands at the edge
			-- its axis gives it, sized by `a_theme'.
		deferred
		ensure
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

	press (a_along, a_scroll: REAL_64): REAL_64
			-- The scroll position after a press at `a_along' on the bar: on the thumb a drag begins
			-- and nothing moves yet; before or after it the view pages that way.
		require
			needed: is_needed
		local
			l_start: REAL_64
		do
			l_start := thumb_start (a_scroll)
			Result := clamped (a_scroll)
			if a_along >= l_start and a_along <= l_start + thumb_length then
				is_dragging := True
				grab_offset := a_along - l_start
			elseif a_along < l_start then
				Result := clamped (a_scroll - viewport)
			else
				Result := clamped (a_scroll + viewport)
			end
		ensure
			in_range: Result >= 0.0 and Result <= max_scroll
		end

	drag_to (a_along: REAL_64): REAL_64
			-- The scroll position with the thumb held at `a_along', the grab point kept under the
			-- pointer.
		require
			dragging: is_dragging
		local
			l_span: REAL_64
		do
			l_span := (track_length - thumb_length).max (1.0)
			Result := clamped ((a_along - grab_offset - track_start) / l_span * max_scroll)
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
			-- The scroll position after a wheel turn of `a_delta' (120 a notch, positive away from
			-- the reader), `Wheel_lines' lines of `a_line' a notch.
		require
			line_positive: a_line > 0.0
		do
			Result := clamped (a_scroll - a_delta / 120.0 * Wheel_lines * a_line)
		ensure
			in_range: Result >= 0.0 and Result <= max_scroll
		end

feature -- Drawing

	draw (a_p: SW_PAINTER; a_scroll: REAL_64; a_hot: BOOLEAN)
			-- The track and the thumb for `a_scroll', when needed; the thumb in the accent while held
			-- or `a_hot' (pointer on it).
		deferred
		end

feature {NONE} -- Implementation

	grab_offset: REAL_64
			-- Where on the thumb the press landed.

invariant
	sizes_positive: bar_width > 0.0 and min_thumb > 0.0 and scale > 0.0
	track_positive: track_length > 0.0
	extent_non_negative: viewport >= 0.0 and content >= 0.0

end
