note
	description: "[
		The classic 270-degree gauge: a track band from lower-left
		around to lower-right (wedge_fill with close radii IS a
		thick arc - the painter primitive earning double keep), the
		value band over it in semantic colour - accent until the
		warn threshold, warning until the danger threshold, danger
		beyond - and the value written large in the centre. The
		zone logic and fraction math are public, assaulted headless.
	]"

class
	SW_GAUGE

inherit
	SW_CHART
		redefine
			draw
		end

create
	make

feature {NONE} -- Initialization

	make (a_minimum, a_maximum: REAL_64)
		require
			ordered: a_minimum <= a_maximum
		do
			make_chart
			minimum := a_minimum
			maximum := a_maximum
			value := a_minimum
			warn_from := a_maximum + 1.0
			danger_from := a_maximum + 1.0
		ensure
			bounds_kept: minimum = a_minimum and maximum = a_maximum
			at_rest: value = minimum
		end

feature -- Access

	minimum, maximum: REAL_64

	value: REAL_64

	warn_from, danger_from: REAL_64
			-- Zone thresholds; both default beyond maximum (no zones).

	fraction: REAL_64
			-- How far along the sweep the value sits; 0 on a
			-- degenerate span.
		do
			if maximum > minimum then
				Result := ((value - minimum) / (maximum - minimum)).max (0.0).min (1.0)
			end
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

	zone: INTEGER
			-- 0 calm, 1 warning, 2 danger - where the value stands.
		do
			if value >= danger_from then
				Result := 2
			elseif value >= warn_from then
				Result := 1
			end
		ensure
			known: Result >= 0 and Result <= 2
		end

feature -- Element change

	set_value (a_value: REAL_64)
			-- Clamps into the span: gauges show truth within range.
		do
			value := a_value.max (minimum).min (maximum)
		ensure
			held: value >= minimum and value <= maximum
		end

	set_zones (a_warn_from, a_danger_from: REAL_64)
		require
			ordered: a_warn_from <= a_danger_from
		do
			warn_from := a_warn_from
			danger_from := a_danger_from
		ensure
			kept: warn_from = a_warn_from and danger_from = a_danger_from
		end

feature -- Data

	refresh_domains
			-- Gauges have no axes; the chassis scales idle.
		do
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cx, cy, r, a0, band: REAL_64
			v: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			r := ((width - 40.0) / 2.0).min (height - 44.0).max (24.0)
			cx := x + width / 2.0
			cy := y + height - 26.0
			band := (r * 0.22).max (8.0)
			a0 := {SW_PAINTER}.Two_pi * 0.375
				-- the track: lower-left around the top to lower-right
			a_p.set_color (t.surface_variant)
			a_p.wedge_fill (cx, cy, r, r - band, a0, a0 + {SW_PAINTER}.Two_pi * 0.75)
				-- the value band, in its zone's colour
			if fraction > 0.0 then
				inspect zone
				when 2 then
					a_p.set_color (t.danger)
				when 1 then
					a_p.set_color (t.warning)
				else
					a_p.set_color (t.accent)
				end
				a_p.wedge_fill (cx, cy, r, r - band, a0,
					a0 + {SW_PAINTER}.Two_pi * 0.75 * fraction)
			end
				-- the value, large in the centre
			v := label_of (value)
			a_p.font ({SW_PAINTER}.Role_mono, (r * 0.42).max (16.0), True)
			a_p.set_color (t.ink)
			a_p.text (cx - a_p.advance (v) / 2.0, cy - r * 0.18, v)
				-- the ends, named small
			a_p.font ({SW_PAINTER}.Role_mono, 10.5, False)
			a_p.set_color (t.ink_muted)
			a_p.text (cx - r + 2.0, cy + 14.0, label_of (minimum))
			a_p.text (cx + r - 2.0 - a_p.advance (label_of (maximum)), cy + 14.0, label_of (maximum))
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature {NONE} -- Chassis contract

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	ordered: minimum <= maximum
	value_held: value >= minimum and value <= maximum
	zones_ordered: warn_from <= danger_from

end
