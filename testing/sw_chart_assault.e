note
	description: "[
		Assault on Wave 4's opening: the SW_SCALE axis engine (round
		trips, the 1/2/5 ladder, degenerate honesty, nice domains)
		and the chart family's headless math - rolling line feeds,
		auto-fitted domains, bar slot arithmetic, scatter nearest.
	]"

class
	SW_CHART_ASSAULT

inherit
	TEST_SET_BASE

feature -- The axis engine

	test_scale_round_trip
		local
			s: SW_SCALE
		do
			create s.make (0.0, 100.0, 10.0, 510.0)
			assert_reals_equal ("zero lands at range start", 10.0, s.position (0.0), 0.000_1)
			assert_reals_equal ("full lands at range end", 510.0, s.position (100.0), 0.000_1)
			assert_reals_equal ("midpoint maps linearly", 260.0, s.position (50.0), 0.000_1)
			assert_reals_equal ("inverse recovers the value", 50.0, s.value_at (260.0), 0.000_1)
			s.set_range (500.0, 0.0)
			assert_reals_equal ("inverted ranges are first-class", 500.0, s.position (0.0), 0.000_1)
			assert_reals_equal ("and invert back", 100.0, s.value_at (0.0), 0.000_1)
		end

	test_scale_degenerate_honesty
		local
			s: SW_SCALE
		do
			create s.make (5.0, 5.0, 0.0, 100.0)
			assert ("flat domain knows itself", s.is_degenerate)
			assert_reals_equal ("positions collapse to mid-range", 50.0, s.position (5.0), 0.000_1)
			assert_reals_equal ("inverse answers the one value", 5.0, s.value_at (70.0), 0.000_1)
			assert_integers_equal ("the ladder offers one tick", 1, s.ticks (5).count)
			assert_reals_equal ("and it is the value", 5.0, s.ticks (5).first, 0.000_1)
		end

	test_scale_ladder_125
		local
			s: SW_SCALE
		do
			create s.make (0.0, 97.0, 0.0, 500.0)
			assert_reals_equal ("0..97 at 5 takes step 20", 20.0, s.tick_step (5), 0.000_1)
			assert_integers_equal ("five rungs inside", 5, s.ticks (5).count)
			assert_reals_equal ("first rung at zero", 0.0, s.ticks (5).first, 0.000_1)
			assert_reals_equal ("last rung at 80", 80.0, s.ticks (5).last, 0.000_1)
			create s.make (-40.0, 25.0, 0.0, 500.0)
			assert_reals_equal ("negative spans ladder too (span 65 -> 10)", 10.0, s.tick_step (5), 0.000_1)
			assert_reals_equal ("rungs start inside the domain", -40.0, s.ticks (5).first, 0.000_1)
			assert_reals_equal ("and end inside it", 20.0, s.ticks (5).last, 0.000_1)
		end

	test_scale_nice_domain
		local
			s: SW_SCALE
		do
			create s.make (3.0, 97.0, 0.0, 500.0)
			s.nice_domain (5)
			assert_reals_equal ("floor snaps to the rung below", 0.0, s.domain_min, 0.000_1)
			assert_reals_equal ("ceiling snaps to the rung above", 100.0, s.domain_max, 0.000_1)
		end

feature -- The charts, headless

	test_line_rolling_capacity
		local
			c: SW_LINE_CHART
			i: INTEGER
		do
			create c.make
			c.set_capacity (5)
			c.add_series ("feed")
			from
				i := 1
			until
				i > 8
			loop
				c.add_point (i.to_double, (i * 10).to_double)
				i := i + 1
			end
			assert_integers_equal ("the roll holds five", 5, c.series.first.pts.count)
			assert_reals_equal ("the oldest three fell off", 4.0, c.series.first.pts.first.vx, 0.000_1)
			assert_reals_equal ("the newest survives", 8.0, c.series.first.pts.last.vx, 0.000_1)
		end

	test_line_auto_domains
		local
			c: SW_LINE_CHART
		do
			create c.make
			c.add_series ("s")
			c.add_point (2.0, 5.0)
			c.add_point (10.0, 45.0)
			c.refresh_domains
			assert_reals_equal ("x hugs the data start", 2.0, c.x_scale.domain_min, 0.000_1)
			assert_reals_equal ("x hugs the data end", 10.0, c.x_scale.domain_max, 0.000_1)
			assert_reals_equal ("y floor snapped nice", 0.0, c.y_scale.domain_min, 0.000_1)
			assert_reals_equal ("y ceiling snapped nice", 50.0, c.y_scale.domain_max, 0.000_1)
		end

	test_bar_slots_and_domain
		local
			c: SW_BAR_CHART
		do
			create c.make
			c.add_bar ("a", 3.0)
			c.add_bar ("b", 9.0)
			c.add_bar ("c", 6.0)
			c.refresh_domains
			assert_reals_equal ("y runs from zero", 0.0, c.y_scale.domain_min, 0.000_1)
			assert_reals_equal ("to the nice ceiling over the max", 10.0, c.y_scale.domain_max, 0.000_1)
			c.set_bounds (0.0, 0.0, 246.0, 240.0)
			assert_integers_equal ("the first slot answers", 1, c.bar_at (c.plot_x + 1.0))
			assert_integers_equal ("the middle slot answers", 2, c.bar_at (c.plot_x + c.plot_w / 2.0))
			assert_integers_equal ("the last slot answers", 3, c.bar_at (c.plot_x + c.plot_w - 1.0))
			assert_integers_equal ("outside is nobody", 0, c.bar_at (c.plot_x - 20.0))
		end

	test_scatter_nearest
		local
			c: SW_SCATTER_CHART
		do
			create c.make
			c.set_bounds (0.0, 0.0, 246.0, 240.0)
			c.add_point (0.0, 0.0)
			c.add_point (10.0, 10.0)
			c.refresh_domains
			c.x_scale.set_range (c.plot_x, c.plot_x + c.plot_w)
			c.y_scale.set_range (c.plot_y + c.plot_h, c.plot_y)
			assert_integers_equal ("the low corner dot answers at its position", 1,
				c.nearest_point (c.x_scale.position (0.0), c.y_scale.position (0.0)))
			assert_integers_equal ("the high dot answers at its position", 2,
				c.nearest_point (c.x_scale.position (10.0), c.y_scale.position (10.0)))
			assert_integers_equal ("open space answers nobody", 0,
				c.nearest_point (9_999.0, 9_999.0))
		end

end
