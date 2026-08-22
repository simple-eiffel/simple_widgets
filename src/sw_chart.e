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
			-- The theme's semantic colours, cycling per series.
		do
			inspect a_index \\ 4
			when 1 then
				Result := a_p.theme.accent
			when 2 then
				Result := a_p.theme.success
			when 3 then
				Result := a_p.theme.warning
			else
				Result := a_p.theme.danger
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
