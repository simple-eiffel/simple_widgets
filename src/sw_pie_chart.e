note
	description: "[
		Proportions over the chassis: labelled slices swept clockwise
		from twelve o'clock, an optional donut hole (a TRUE ring -
		arc out, arc_negative back, no fake overlay), an eight-step
		palette (the four semantic colours then their washes), a side
		legend with percentages, and angle-arithmetic hover naming
		label, value and share. The slice math (slice_at, percent_of,
		angle_of) is public and assaulted headless.
	]"

class
	SW_PIE_CHART

inherit
	SW_CHART
		redefine
			draw
		end

create
	make, make_donut

feature {NONE} -- Initialization

	make
		do
			make_chart
			create slices.make (6)
		end

	make_donut
			-- The ringed variant: a hole at 55% of the radius.
		do
			make
			inner_fraction := 0.55
		ensure
			holed: inner_fraction > 0.0
		end

feature -- Access

	slices: ARRAYED_LIST [TUPLE [label: STRING_32; value: REAL_64]]

	inner_fraction: REAL_64
			-- Hole radius as a share of the pie radius; 0 = solid.

	total: REAL_64
			-- The whole the slices are shares of.
		do
			across
				slices as s
			loop
				Result := Result + s.value
			end
		ensure
			non_negative: Result >= 0.0
		end

	percent_of (a_index: INTEGER): REAL_64
			-- Slice `a_index''s share of the whole, in percent;
			-- 0 when the whole is nothing.
		require
			in_range: a_index >= 1 and a_index <= slices.count
		do
			if total > 0.0 then
				Result := slices.i_th (a_index).value / total * 100.0
			end
		ensure
			sane: Result >= 0.0 and Result <= 100.0
		end

feature -- Geometry

	pie_cx: REAL_64
		do
			Result := x + Inset_left + pie_r
		end

	pie_cy: REAL_64
		do
			Result := y + height / 2.0
		end

	pie_r: REAL_64
		do
			Result := ((height - Inset_top - Inset_bottom) / 2.0)
				.min (width * 0.58 / 2.0 - Inset_left).max (20.0)
		end

	angle_of (a_dx, a_dy: REAL_64): REAL_64
			-- Clockwise angle from twelve o'clock, 0 .. Two_pi, in
			-- screen coordinates (y grows downward).
		local
			m: DOUBLE_MATH
			a: REAL_64
		do
			create m
			if a_dx.abs < 0.000_001 and a_dy.abs < 0.000_001 then
				Result := 0.0
			else
				if a_dx.abs < 0.000_001 then
					if a_dy > 0.0 then
						a := {SW_PAINTER}.Two_pi / 4.0
					else
						a := -{SW_PAINTER}.Two_pi / 4.0
					end
				else
					a := m.arc_tangent (a_dy / a_dx)
					if a_dx < 0.0 then
						a := a + {SW_PAINTER}.Two_pi / 2.0
					end
				end
					-- a is now measured from three o'clock,
					-- counter-clockwise negative; shift to
					-- twelve-o'clock clockwise
				Result := a + {SW_PAINTER}.Two_pi / 4.0
				from
				until
					Result >= 0.0
				loop
					Result := Result + {SW_PAINTER}.Two_pi
				end
				from
				until
					Result < {SW_PAINTER}.Two_pi
				loop
					Result := Result - {SW_PAINTER}.Two_pi
				end
			end
		ensure
			normalized: Result >= 0.0 and Result < {SW_PAINTER}.Two_pi
		end

	slice_at (a_px, a_py: REAL_64): INTEGER
			-- The slice under a surface point; 0 outside the ring.
		local
			dx, dy, d2, ang, sweep_end, acc: REAL_64
			m: DOUBLE_MATH
			i: INTEGER
		do
			if total > 0.0 then
				create m
				dx := a_px - pie_cx
				dy := a_py - pie_cy
				d2 := dx * dx + dy * dy
				if d2 <= pie_r * pie_r
					and then m.sqrt (d2) >= pie_r * inner_fraction
				then
					ang := angle_of (dx, dy)
					from
						i := 1
					until
						i > slices.count or Result > 0
					loop
						sweep_end := acc + slices.i_th (i).value / total * {SW_PAINTER}.Two_pi
						if ang >= acc and ang < sweep_end then
							Result := i
						end
						acc := sweep_end
						i := i + 1
					end
					if Result = 0 and slices.count > 0 then
							-- floating-point tail: the last sliver
						Result := slices.count
					end
				end
			end
		ensure
			in_range: Result >= 0 and Result <= slices.count
		end

feature -- Element change

	add_slice (a_label: READABLE_STRING_GENERAL; a_value: REAL_64)
		require
			non_negative: a_value >= 0.0
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			slices.extend ([l, a_value])
		ensure
			grew: slices.count = old slices.count + 1
		end

feature -- Data

	refresh_domains
			-- Proportions have no axes; the chassis scales idle.
		do
		end

feature -- Drawing

	slice_color (a_index: INTEGER; a_p: SW_PAINTER): NATURAL_32
			-- Eight distinguishable steps: the semantics, then washes.
		do
			inspect (a_index - 1) \\ 8
			when 0 then
				Result := a_p.theme.accent
			when 1 then
				Result := a_p.theme.success
			when 2 then
				Result := a_p.theme.warning
			when 3 then
				Result := a_p.theme.danger
			when 4 then
				Result := a_p.theme.wash_accent
			when 5 then
				Result := a_p.theme.wash_success
			when 6 then
				Result := a_p.theme.wash_warning
			else
				Result := a_p.theme.wash_danger
			end
		end

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, hot: INTEGER
			a0, sweep, ly: REAL_64
			row: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if shows_hover then
				hot := slice_at (hover_px, hover_py)
			end
			if total > 0.0 then
				a0 := -{SW_PAINTER}.Two_pi / 4.0
				from
					i := 1
				until
					i > slices.count
				loop
					sweep := slices.i_th (i).value / total * {SW_PAINTER}.Two_pi
					if sweep > 0.0 then
						a_p.set_color (slice_color (i, a_p))
						a_p.wedge_fill (pie_cx, pie_cy, pie_r,
							pie_r * inner_fraction, a0, a0 + sweep)
						if i = hot then
							a_p.set_color (t.ink)
							a_p.wedge_stroke (pie_cx, pie_cy, pie_r,
								pie_r * inner_fraction, a0, a0 + sweep)
						end
					end
					a0 := a0 + sweep
					i := i + 1
				end
					-- the side legend: dot, label, share
				a_p.font ({SW_PAINTER}.Role_ui, 12.5, False)
				ly := y + Inset_top + 10.0
				from
					i := 1
				until
					i > slices.count
				loop
					a_p.set_color (slice_color (i, a_p))
					a_p.circle_fill (x + width * 0.62, ly - 4.0, 4.5)
					create row.make (24)
					row.append (slices.i_th (i).label)
					row.append ({STRING_32} "  ")
					row.append (label_of (percent_of (i)))
					row.append_character ('%%')
					if i = hot then
						a_p.set_color (t.ink)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.text (x + width * 0.62 + 12.0, ly, row)
					ly := ly + 19.0
					i := i + 1
				end
				if hot > 0 then
					create row.make (32)
					row.append (slices.i_th (hot).label)
					row.append ({STRING_32} " %/8212/ ")
					row.append (label_of (slices.i_th (hot).value))
					row.append ({STRING_32} " (")
					row.append (label_of (percent_of (hot)))
					row.append ({STRING_32} "%%)")
					a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
					a_p.set_color (t.surface_variant)
					a_p.rrect_fill (x + 10.0, y + height - 24.0,
						a_p.advance (row) + 10.0, 17.0, 3.0)
					a_p.set_color (t.ink)
					a_p.text (x + 15.0, y + height - 11.0, row)
				end
			else
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + Inset_left, y + height / 2.0, {STRING_32} "no data yet")
			end
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
			-- Unused: draw is redefined wholesale (no axes here).
		do
		end

invariant
	slices_attached: slices /= Void
	hole_sane: inner_fraction >= 0.0 and inner_fraction < 1.0

end
