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
	make, make_disc, make_rect

feature {NONE} -- Initialization

	make (a_lines: INTEGER)
		require
			at_least_one: a_lines >= 1
		do
			line_count := a_lines
		ensure
			kept: line_count = a_lines
		end

feature {NONE} -- Shape variants

	make_disc (a_diameter: REAL_64)
			-- A circular placeholder (avatars, images).
		require
			positive: a_diameter > 0.0
		do
			make (1)
			shape := Shape_disc
			disc_diameter := a_diameter
		end

	make_rect (a_w, a_h: REAL_64)
			-- A block placeholder (cards, images).
		require
			positive: a_w > 0.0 and a_h > 0.0
		do
			make (1)
			shape := Shape_rect
			rect_w := a_w
			rect_h := a_h
		end

feature -- Access

	Shape_lines: INTEGER = 0
	Shape_disc: INTEGER = 1
	Shape_rect: INTEGER = 2

	shape: INTEGER

	disc_diameter, rect_w, rect_h: REAL_64

	line_count: INTEGER

	Line_h: REAL_64 = 14.0

	Line_gap: REAL_64 = 10.0

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			inspect shape
			when Shape_disc then
				Result := disc_diameter
			when Shape_rect then
				Result := rect_h
			else
				Result := line_count * Line_h + (line_count - 1) * Line_gap
			end
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
			if shape = Shape_disc then
				a_p.set_color (t.surface_variant)
				a_p.circle_fill (x + disc_diameter / 2.0, y + disc_diameter / 2.0, disc_diameter / 2.0)
				a_p.push_clip (x, y, disc_diameter, disc_diameter)
				a_p.set_color_alpha (t.ink_muted, 0.18)
				a_p.rrect_fill (x + (phase / 24.0) * disc_diameter - 20.0, y, 40.0, disc_diameter, 8.0)
				a_p.pop_clip
			elseif shape = Shape_rect then
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x, y, rect_w.min (width), rect_h, 4.0)
				a_p.push_clip (x, y, rect_w.min (width), rect_h)
				a_p.set_color_alpha (t.ink_muted, 0.18)
				a_p.rrect_fill (x + (phase / 24.0) * rect_w - 30.0, y, 60.0, rect_h, 4.0)
				a_p.pop_clip
			else
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
		end

feature {NONE} -- Animation

	phase: INTEGER
			-- Shimmer position, advanced once per render; the window
			-- heartbeat repaints, so waiting screens breathe.

invariant
	lines_positive: line_count >= 1

end
