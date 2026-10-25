note
	description: "[
		The chart chassis every plot rides: two SW_SCALE axes, a
		plot rectangle inside labelled insets, y-gridlines and tick
		labels from the 1/2/5 ladder, a clip around the data layer
		so nothing bleeds, and the theme's semantic colours cycling
		per series. Descendants declare their data, refresh the
		domains, and draw inside the plot - the frame, axes and
		hygiene are chassis business. Wave 4 opens here.
	]"

deferred class
	SW_CHART

inherit
	SW_WIDGET
		redefine
			wants_hover_point
		end

feature {NONE} -- Initialization

	make_chart
			-- The chassis organs; descendants call this first.
		do
			create x_scale.make (0.0, 1.0, 0.0, 1.0)
			create y_scale.make (0.0, 1.0, 0.0, 1.0)
			create title.make_empty
		end

feature -- Access

	x_scale, y_scale: SW_SCALE
			-- The shared axis engine; ranges are re-anchored to the
			-- plot rectangle every draw (immediate-mode truth).

	title: STRING_32

	with_title (a_title: READABLE_STRING_GENERAL): like Current
			-- Fluent: a top-left caption inside the frame.
		do
			create title.make_from_string_general (a_title)
			Result := Current
		ensure
			chained: Result = Current
		end

feature -- Layout

	Inset_left: REAL_64 = 46.0
	Inset_right: REAL_64 = 14.0
	Inset_top: REAL_64 = 26.0
	Inset_bottom: REAL_64 = 26.0

	plot_x: REAL_64
		do
			Result := x + Inset_left
		end

	plot_y: REAL_64
		do
			Result := y + Inset_top
		end

	plot_w: REAL_64
		do
			Result := (width - Inset_left - Inset_right).max (10.0)
		end

	plot_h: REAL_64
		do
			Result := (height - Inset_top - Inset_bottom).max (10.0)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 240.0
		end

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			ty: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			refresh_domains
			x_scale.set_range (plot_x, plot_x + plot_w)
			y_scale.set_range (plot_y + plot_h, plot_y)
			a_p.font ({SW_PAINTER}.Role_mono, 10.5, False)
			across
				y_scale.ticks (4) as v
			loop
				ty := y_scale.position (v)
				a_p.set_color (t.outline)
				a_p.hline (plot_x, ty, plot_w)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 6.0, ty + 3.5, label_of (v))
			end
			draw_x_axis (a_p)
			a_p.push_clip (plot_x, plot_y, plot_w, plot_h)
			draw_data (a_p)
			a_p.pop_clip
			if legend_names.count >= 2 then
				draw_legend_row (a_p, legend_names)
			end
			draw_hover (a_p)
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

	draw_x_axis (a_p: SW_PAINTER)
			-- Default: numeric labels from the x ladder; categorical
			-- charts redefine.
		local
			tx: REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_mono, 10.5, False)
			a_p.set_color (a_p.theme.ink_muted)
			across
				x_scale.ticks (5) as v
			loop
				tx := x_scale.position (v)
				a_p.text (tx - a_p.advance (label_of (v)) / 2.0,
					y + height - 9.0, label_of (v))
			end
		end

	draw_hover (a_p: SW_PAINTER)
			-- Hover truth layer; descendants that answer the pointer
			-- redefine (drawn OUTSIDE the clip so chips may overhang).
		do
		end

	legend_names: ARRAYED_LIST [STRING_32]
			-- The series a legend names; the chassis draws one when there are
			-- two or more. None by default.
		do
			create Result.make (0)
		end

	draw_legend_row (a_p: SW_PAINTER; a_names: ARRAYED_LIST [STRING_32])
			-- The shared legend machinery: colour dots + names in a
			-- right-aligned row inside the frame's top band - as many as fit
			-- beside the title, then "+n" for the rest.
		local
			lx, l_floor, l_dot, l_gap, l_width: REAL_64
			i, l_fit: INTEGER
			l_more: STRING_32
		do
			l_dot := a_p.theme.padding
			l_gap := a_p.theme.padding * 1.5
			l_floor := x + Inset_left
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_chip, True)
				l_floor := l_floor.max (x + 10.0 + a_p.advance (title) + l_gap)
			end
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_chip, False)
				-- How many fit, from the first.
			from
				i := 1
			until
				i > a_names.count or else l_width + l_dot + a_p.advance (a_names.i_th (i)) + l_gap
					> (x + width - Inset_right) - l_floor
			loop
				l_width := l_width + l_dot + a_p.advance (a_names.i_th (i)) + l_gap
				l_fit := i
				i := i + 1
			end
			create l_more.make_empty
			if l_fit < a_names.count then
				l_more.append_character ('+')
				l_more.append_integer (a_names.count - l_fit)
				l_width := l_width + a_p.advance (l_more)
			end
			lx := x + width - Inset_right - l_width
			from
				i := 1
			until
				i > l_fit
			loop
				a_p.set_color (series_color (i, a_p))
				a_p.circle_fill (lx + l_dot / 2.0, y + 12.0, l_dot / 2.0)
				lx := lx + l_dot
				a_p.set_color (a_p.theme.ink_muted)
				a_p.text (lx + l_dot / 2.0, y + 16.0, a_names.i_th (i))
				lx := lx + a_p.advance (a_names.i_th (i)) + l_gap
				i := i + 1
			end
			if not l_more.is_empty then
				a_p.set_color (a_p.theme.ink_muted)
				a_p.text (lx, y + 16.0, l_more)
			end
		end

	draw_chip (a_p: SW_PAINTER; a_text: READABLE_STRING_GENERAL; a_left, a_top: REAL_64)
			-- A value chip: `a_text' in the mono face at the chip size on the
			-- surface variant, its box placed at (`a_left', `a_top') but kept
			-- inside the frame. The one chip every chart draws.
		local
			w, h, l_pad, lx, ly, l_edge: REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_chip, False)
			l_pad := a_p.theme.padding * 0.625
			l_edge := a_p.theme.padding / 2.0
			w := a_p.advance (a_text) + 2.0 * l_pad
			h := a_p.text_extent + a_p.theme.padding / 2.0
			lx := a_left.min (x + width - w - l_edge).max (x + l_edge)
			ly := a_top.min (y + height - h - l_edge).max (y + l_edge)
			last_chip := [lx, ly, w, h]
			a_p.set_color (a_p.theme.surface_variant)
			a_p.rrect_fill (lx, ly, w, h, 3.0 * a_p.theme.text_scale)
			a_p.set_color (a_p.theme.ink)
			a_p.text (lx + l_pad, ly + (h - a_p.text_extent) / 2.0 + a_p.font_ascent, a_text)
		end

	chip_width (a_p: SW_PAINTER; a_text: READABLE_STRING_GENERAL): REAL_64
			-- The width `draw_chip' gives `a_text'.
		do
			a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_chip, False)
			Result := a_p.advance (a_text) + 2.0 * a_p.theme.padding * 0.625
		end

	draw_chip_beside (a_p: SW_PAINTER; a_text: READABLE_STRING_GENERAL; a_px, a_py: REAL_64)
			-- A chip up and to the right of the point (`a_px', `a_py').
		do
			draw_chip (a_p, a_text, a_px + a_p.theme.padding, a_py - a_p.theme.padding * 2.75)
		end

	draw_chip_above (a_p: SW_PAINTER; a_text: READABLE_STRING_GENERAL; a_cx, a_py: REAL_64)
			-- A chip centred over x `a_cx', above y `a_py'.
		do
			draw_chip (a_p, a_text, a_cx - chip_width (a_p, a_text) / 2.0, a_py - a_p.theme.padding * 2.75)
		end

	draw_chip_corner (a_p: SW_PAINTER; a_text: READABLE_STRING_GENERAL)
			-- A chip pinned to the bottom-left corner of the frame.
		do
			draw_chip (a_p, a_text, x + a_p.theme.padding * 1.25, y + height)
		end

	last_chip: TUPLE [x, y, width, height: REAL_64]
			-- The box of the last chip drawn (what a test checks is inside).
		attribute
			Result := [0.0, 0.0, 0.0, 0.0]
		end

feature -- Formatting

	label_of (a_value: REAL_64): STRING_32
			-- A human-width number: whole when large or already
			-- whole, one decimal in single digits, two below one.
		local
			r: REAL_64
			scaled: INTEGER
		do
			create Result.make (8)
			r := a_value.abs
			if r >= 100.0 or a_value = a_value.rounded.to_double then
				Result.append_string_general (a_value.rounded.out)
			else
				if a_value < 0.0 then
					Result.append_character ('-')
				end
				if r >= 1.0 then
					scaled := (r * 10.0).rounded
					Result.append_string_general ((scaled // 10).out)
					Result.append_character ('.')
					Result.append_string_general ((scaled \\ 10).out)
				else
					scaled := (r * 100.0).rounded
					Result.append_string_general ((scaled // 100).out)
					Result.append_character ('.')
					Result.append_string_general (((scaled \\ 100) // 10).out)
					Result.append_string_general (((scaled \\ 100) \\ 10).out)
				end
			end
		end

feature -- Series palette

	series_color (a_index: INTEGER; a_p: SW_PAINTER): NATURAL_32
			-- The theme's semantic colours, then their strong inks: eight
			-- apart before they cycle.
		do
			inspect (a_index - 1) \\ 8 + 1
			when 1 then
				Result := a_p.theme.accent
			when 2 then
				Result := a_p.theme.success
			when 3 then
				Result := a_p.theme.warning
			when 4 then
				Result := a_p.theme.danger
			when 5 then
				Result := a_p.theme.ink_accent
			when 6 then
				Result := a_p.theme.ink_success
			when 7 then
				Result := a_p.theme.ink_warning
			else
				Result := a_p.theme.ink_danger
			end
		end

feature -- Data

	refresh_domains
			-- Aim both scales' domains at the current data. Public:
			-- draw calls it every frame, and assaults call it to
			-- interrogate the domain math headless.
		deferred
		end

feature {NONE} -- Deferred data contract

	draw_data (a_p: SW_PAINTER)
			-- The series themselves, clipped to the plot.
		deferred
		end

invariant
	organs: x_scale /= Void and y_scale /= Void and title /= Void

end
