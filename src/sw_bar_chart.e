note
	description: "[
		Bars over the chassis: labelled categories, each holding one bar
		per series side by side (GW-10: a census target against its
		frequency-matched control words), y fitted 0-to-max on the tick
		ladder. The x axis writes category labels; with more than one
		series a legend names them. Hovering a bar rings it and names its
		series and value.

		    set_series (<<"target", "control 1", ...>>)   before the groups
		    add_group ("Gen", <<12.0, 9.5, ...>>)        one value a series
		    add_bar ("Gen", 12.0)                        one series

		`set_emphasized_series' draws every other series in a quiet ink so
		the target stands out - by lightness as well as hue, never colour
		alone - and the legend follows (`series_color').
	]"

class
	SW_BAR_CHART

inherit
	SW_CHART
		redefine
			draw_x_axis, draw_hover, series_color
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create series_names.make (2)
			create labels.make (6)
			create values.make (6)
		end

feature -- Access

	series_count: INTEGER
			-- Bars a group holds: the named series, or 1.
		do
			Result := series_names.count.max (1)
		ensure
			at_least_one: Result >= 1
		end

	series_name (a_series: INTEGER): STRING_32
		require
			valid: a_series >= 1 and a_series <= series_count
		do
			if series_names.is_empty then
				create Result.make_empty
			else
				Result := series_names.i_th (a_series)
			end
		end

	category_count: INTEGER
			-- Groups.
		do
			Result := labels.count
		end

	category_label (a_category: INTEGER): STRING_32
		require
			valid: a_category >= 1 and a_category <= category_count
		do
			Result := labels.i_th (a_category)
		end

	value (a_category, a_series: INTEGER): REAL_64
		require
			valid_category: a_category >= 1 and a_category <= category_count
			valid_series: a_series >= 1 and a_series <= series_count
		do
			Result := values.i_th (a_category) [a_series]
		end

	emphasized_series: INTEGER
			-- The series drawn in its colour while the others go quiet; 0:
			-- every series in its colour.

	bar_at (a_px: REAL_64): INTEGER
			-- Which category's slot the x position falls in; 0 outside.
			-- Pure math over the plot rectangle - assaultable headless
			-- once ranges are anchored.
		local
			slot: REAL_64
		do
			if category_count > 0 and then a_px >= plot_x and then a_px <= plot_x + plot_w then
				slot := plot_w / category_count
				Result := (((a_px - plot_x) / slot).floor + 1).min (category_count)
			end
		ensure
			in_range: Result >= 0 and Result <= category_count
		end

	series_at (a_px: REAL_64): INTEGER
			-- Which series' bar the x position falls on, in its category;
			-- 0 between bars or outside.
		local
			c, s: INTEGER
		do
			c := bar_at (a_px)
			if c > 0 then
				from
					s := 1
				until
					s > series_count or Result > 0
				loop
					if a_px >= bar_left (c, s) and then a_px < bar_left (c, s) + bar_width then
						Result := s
					end
					s := s + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= series_count
		end

	bar_left (a_category, a_series: INTEGER): REAL_64
			-- The left of bar (`a_category', `a_series') at the last layout.
		require
			valid_category: a_category >= 1 and a_category <= category_count
			valid_series: a_series >= 1 and a_series <= series_count
		local
			slot: REAL_64
		do
			slot := plot_w / category_count
			Result := plot_x + (a_category - 1) * slot + (slot - group_width) / 2.0
				+ (a_series - 1) * (bar_width + bar_gap)
		end

	bar_width: REAL_64
			-- One bar's width at the last layout.
		do
			if category_count > 0 then
				Result := ((group_width - bar_gap * (series_count - 1)) / series_count).max (1.0)
			end
		end

	series_color (a_index: INTEGER; a_p: SW_PAINTER): NATURAL_32
			-- A series' colour; quiet for every series but the emphasized one.
		do
			if emphasized_series > 0 and then a_index /= emphasized_series then
				Result := a_p.theme.ink_soft
			else
				Result := Precursor (a_index, a_p)
			end
		end

feature -- Element change

	set_series (a_names: ARRAY [READABLE_STRING_GENERAL])
			-- Name the series, one per bar of a group.
		require
			before_groups: category_count = 0
			at_least_one: a_names.count >= 1
		do
			series_names.wipe_out
			across a_names as n loop
				series_names.extend (n.to_string_32)
			end
		ensure
			counted: series_count = a_names.count
		end

	add_group (a_label: READABLE_STRING_GENERAL; a_values: ARRAY [REAL_64])
			-- A category labelled `a_label', one value per series.
		require
			one_per_series: a_values.count = series_count
		local
			l: ARRAY [REAL_64]
			k: INTEGER
		do
			labels.extend (a_label.to_string_32)
			create l.make_filled (0.0, 1, a_values.count)
			from
				k := 1
			until
				k > a_values.count
			loop
				l [k] := a_values [a_values.lower + k - 1]
				k := k + 1
			end
			values.extend (l)
		ensure
			grew: category_count = old category_count + 1
		end

	add_bar (a_label: READABLE_STRING_GENERAL; a_value: REAL_64)
			-- A category with one bar (a single-series chart).
		require
			one_series: series_count = 1
		do
			add_group (a_label, <<a_value>>)
		ensure
			grew: category_count = old category_count + 1
		end

	set_emphasized_series (a_series: INTEGER)
			-- Draw `a_series' in its colour and the others quiet (0: all in
			-- their colours).
		require
			valid: a_series >= 0 and a_series <= series_count
		do
			emphasized_series := a_series
		ensure
			set: emphasized_series = a_series
		end

feature -- Data

	refresh_domains
		local
			hi: REAL_64
		do
			across values as v loop
				across v as e loop
					hi := hi.max (e)
				end
			end
			y_scale.set_domain (0.0, hi.max (1.0))
			y_scale.nice_domain (4)
			x_scale.set_domain (0.0, category_count.max (1).to_double)
		end

feature {NONE} -- Layout

	series_names: ARRAYED_LIST [STRING_32]
	labels: ARRAYED_LIST [STRING_32]
	values: ARRAYED_LIST [ARRAY [REAL_64]]

	bar_gap: REAL_64
			-- Between two bars of a group.

	group_width: REAL_64
			-- The bars of a group with their gaps: 62 percent of the slot
			-- for one series, 78 percent for several.
		do
			if category_count > 0 then
				Result := plot_w / category_count * (if series_count > 1 then 0.78 else 0.62 end)
			end
		end

feature {NONE} -- Drawing

	draw_data (a_p: SW_PAINTER)
		local
			c, s: INTEGER
			by: REAL_64
		do
			bar_gap := a_p.theme.padding / 4.0
			from
				c := 1
			until
				c > category_count
			loop
				from
					s := 1
				until
					s > series_count
				loop
					by := y_scale.position (value (c, s))
					a_p.set_color (series_color (s, a_p))
					a_p.fill_rect (bar_left (c, s), by, bar_width, (plot_y + plot_h - by).max (1.0))
					s := s + 1
				end
				c := c + 1
			end
		end

	draw_x_axis (a_p: SW_PAINTER)
			-- Category labels, centred under their slots; the legend when
			-- there are several series.
		local
			c: INTEGER
			slot, cx: REAL_64
		do
			if category_count > 0 then
				slot := plot_w / category_count
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_chip, False)
				a_p.set_color (a_p.theme.ink_muted)
				from
					c := 1
				until
					c > category_count
				loop
					cx := plot_x + (c - 1) * slot + slot / 2.0
					a_p.text (cx - a_p.advance (labels.i_th (c)) / 2.0, y + height - 9.0, labels.i_th (c))
					c := c + 1
				end
			end
			if series_names.count > 1 then
				draw_legend_row (a_p, series_names)
			end
		end

	draw_hover (a_p: SW_PAINTER)
			-- The hovered bar ringed; a chip with its series and value.
		local
			c, s: INTEGER
			bx, by: REAL_64
			chip: STRING_32
		do
			if shows_hover and then hover_py >= plot_y and then hover_py <= plot_y + plot_h then
				c := bar_at (hover_px)
				s := series_at (hover_px)
				if c > 0 and s > 0 then
					bx := bar_left (c, s)
					by := y_scale.position (value (c, s))
					a_p.set_color (a_p.theme.ink)
					a_p.rrect_stroke (bx - 1.0, by - 1.0, bar_width + 2.0, (plot_y + plot_h - by).max (1.0) + 2.0, 2.0)
					create chip.make (24)
					if series_names.count > 1 then
						chip.append (series_names.i_th (s))
						chip.append ({STRING_32} ": ")
					end
					chip.append (label_of (value (c, s)))
					a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_chip, False)
					a_p.set_color (a_p.theme.surface_variant)
					a_p.rrect_fill (bx + bar_width / 2.0 - a_p.advance (chip) / 2.0 - 5.0,
						(by - 22.0).max (y + 4.0), a_p.advance (chip) + 10.0, 16.0, 3.0)
					a_p.set_color (a_p.theme.ink)
					a_p.text (bx + bar_width / 2.0 - a_p.advance (chip) / 2.0, (by - 10.0).max (y + 16.0), chip)
				end
			end
		end

invariant
	parallel: values.count = labels.count

end
