note
	description: "[
		Loading bars: rounded placeholder lines with a shimmer band
		that drifts on the window's heartbeat. Honest waiting - the
		shape of content before the content.
	]"

class
	SW_SKELETON

inherit
	SW_WIDGET

create
	make

feature {NONE} -- Initialization

	make (a_lines: INTEGER)
		require
			at_least_one: a_lines >= 1
		do
			line_count := a_lines
		ensure
			kept: line_count = a_lines
		end

feature -- Access

	line_count: INTEGER

	Line_h: REAL_64 = 14.0

	Line_gap: REAL_64 = 10.0

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := line_count * Line_h + (line_count - 1) * Line_gap
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			ly, lw, sx: REAL_64
		do
			t := a_p.theme
			phase := (phase + 1) \\ 24
			from
				i := 0
			until
				i >= line_count
			loop
				ly := y + i * (Line_h + Line_gap)
				if i = line_count - 1 and line_count > 1 then
					lw := width * 0.62
				else
					lw := width
				end
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x, ly, lw, Line_h, Line_h / 2.0)
				sx := x + (phase / 24.0) * lw - 30.0
				a_p.push_clip (x, ly, lw, Line_h)
				a_p.set_color_alpha (t.ink_muted, 0.18)
				a_p.rrect_fill (sx, ly, 60.0, Line_h, Line_h / 2.0)
				a_p.pop_clip
				i := i + 1
			end
		end

feature {NONE} -- Animation

	phase: INTEGER
			-- Shimmer position, advanced once per render; the window
			-- heartbeat repaints, so waiting screens breathe.

invariant
	lines_positive: line_count >= 1

end
