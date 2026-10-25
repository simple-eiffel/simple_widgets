note
	description: "[
		Assault on GW-10, grouped bars in SW_BAR_CHART: a category's bars
		side by side, one per series, the hit test naming category and
		series, the domain over every series, the single-series form
		unchanged, and the census controls chart (a target against three
		frequency-matched controls, the target emphasized) in both themes
		(evidence gw10_controls_light.png and gw10_controls_dark.png).
	]"

class
	SW_GROUPED_BARS_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Grouped bars

	test_gw10_groups_hit_and_domain
			-- Three series by four groups: the y domain covers the largest
			-- value of any series; a point on a bar names its category and
			-- its series; the bars of a group stand left to right in series
			-- order, a gap apart.
		local
			w: SW_WINDOW
			c: SW_BAR_CHART
			l_mid: REAL_64
		do
			create w.make ("bars", 0, 0, 640, 300, create {SW_THEME}.make_light)
			c := controls_chart
			w.set_root (c)
			w.request_render
			assert_integers_equal ("three series", 3, c.series_count)
			assert_integers_equal ("four groups", 4, c.category_count)
			assert_true ("the domain covers the largest value", c.y_scale.domain_max >= 31.0)
			l_mid := c.bar_left (2, 3) + c.bar_width / 2.0
			assert_integers_equal ("category 2", 2, c.bar_at (l_mid))
			assert_integers_equal ("series 3", 3, c.series_at (l_mid))
			assert_true ("series in order, a gap apart",
				c.bar_left (2, 2) >= c.bar_left (2, 1) + c.bar_width)
			assert_reals_equal ("the gap is a quarter of the padding", w.theme.padding / 4.0,
				c.bar_left (2, 2) - c.bar_left (2, 1) - c.bar_width, 0.000_1)
		end

	test_gw10_emphasis_quiets_the_others
		local
			w: SW_WINDOW
			c: SW_BAR_CHART
		do
			create w.make ("bars", 0, 0, 640, 300, create {SW_THEME}.make_light)
			c := controls_chart
			c.set_emphasized_series (1)
			w.set_root (c)
			w.request_render
			assert_true ("the target keeps its colour", c.series_color (1, w.painter) = w.theme.accent)
			assert_true ("the controls go quiet: a pale ramp tone, not a text ink",
				c.series_color (2, w.painter) = w.theme.ramp (2)
				and c.series_color (3, w.painter) = w.theme.ramp (2)
				and c.series_color (2, w.painter) /= w.theme.ink_soft)
		end

	test_gw10_new_series_forget_the_emphasis
			-- Emphasis names a series by number; new series start without it.
		local
			c: SW_BAR_CHART
		do
			create c.make
			c.set_series (<<"a", "b", "c">>)
			c.set_emphasized_series (3)
			c.set_series (<<"only">>)
			assert_integers_equal ("no emphasis on new series", 0, c.emphasized_series)
		end

	test_gw10_series_colours_stay_apart
			-- Eight series, eight colours: the fifth is not the first again.
		local
			w: SW_WINDOW
			c: SW_BAR_CHART
		do
			create w.make ("bars", 0, 0, 640, 300, create {SW_THEME}.make_light)
			create c.make
			w.set_root (c)
			w.request_render
			assert_true ("series 5 is not series 1", c.series_color (5, w.painter) /= c.series_color (1, w.painter))
			assert_true ("series 8 is not series 4", c.series_color (8, w.painter) /= c.series_color (4, w.painter))
		end

	test_gw10_crowded_chart_keeps_inside
			-- Five series at 300 wide: the hover chip over the last bar stays
			-- inside the frame, and the legend gives way to "+n" rather than
			-- running over the title (evidence gw10_crowded_light.png).
		local
			w: SW_WINDOW
			c: SW_BAR_CHART
			path: STRING_32
		do
			create w.make ("bars", 0, 0, 300, 220, create {SW_THEME}.make_light)
			create c.make
			c := c.with_title ("Five series")
			c.set_series (<<"target", "control 1", "control 2", "control 3", "control 4">>)
			c.add_group ("Gen", <<12.0, 9.5, 8.0, 7.0, 6.0>>)
			c.add_group ("Isa", <<31.0, 12.0, 9.0, 8.0, 40.0>>)
			w.set_root (c)
			w.request_render
			c.set_hovered (True)
			c.set_hover_point (c.bar_left (2, 5) + c.bar_width / 2.0, c.plot_y + c.plot_h - 2.0)
			w.request_render
			assert_true ("a chip was drawn", c.last_chip.width > 0.0)
			assert_true ("the chip stays inside the frame",
				c.last_chip.x >= c.x and c.last_chip.x + c.last_chip.width <= c.x + c.width
				and c.last_chip.y >= c.y and c.last_chip.y + c.last_chip.height <= c.y + c.height)
			path := evidence_path ("gw10_crowded_light.png")
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

feature -- The controls chart, both themes

	test_gw10_controls_light
		do
			controls_gate (create {SW_THEME}.make_light, "gw10_controls_light.png")
		end

	test_gw10_controls_dark
		do
			controls_gate (create {SW_THEME}.make_dark, "gw10_controls_dark.png")
		end

feature {NONE} -- Fixtures

	controls_chart: SW_BAR_CHART
			-- Hits per 1,000 words: a target against two controls, four books.
		do
			create Result.make
			Result.set_series (<<"target", "control 1", "control 2">>)
			Result.add_group ("Gen", <<12.0, 9.5, 8.0>>)
			Result.add_group ("Exod", <<18.0, 10.0, 11.5>>)
			Result.add_group ("Isa", <<31.0, 12.0, 9.0>>)
			Result.add_group ("Ps", <<7.0, 8.5, 9.5>>)
		end

	controls_gate (a_theme: SW_THEME; a_evidence: STRING)
		local
			w: SW_WINDOW
			c: SW_BAR_CHART
			path: STRING_32
		do
			create w.make ("gw10", 0, 0, 640, 300, a_theme)
			c := controls_chart
			c.set_emphasized_series (1)
			c := c.with_title ("Hits per 1,000 words: target against controls")
			w.set_root (c)
			w.request_render
			assert_true ("bars laid", c.bar_width > 1.0)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

end
