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

feature -- Proportions

	test_pie_shares_and_slices
		local
			c: SW_PIE_CHART
		do
			create c.make_donut
			c.add_slice ("a", 50.0)
			c.add_slice ("b", 30.0)
			c.add_slice ("c", 20.0)
			assert_reals_equal ("the whole is the sum", 100.0, c.total, 0.000_1)
			assert_reals_equal ("shares are percentages", 30.0, c.percent_of (2), 0.000_1)
			assert_reals_equal ("shares sum to the whole", 100.0,
				c.percent_of (1) + c.percent_of (2) + c.percent_of (3), 0.000_1)
			c.set_bounds (0.0, 0.0, 400.0, 300.0)
				-- slice 1 spans the first half turn clockwise from
				-- twelve: three o'clock is inside it
			assert_integers_equal ("three o'clock lies in the half slice", 1,
				c.slice_at (c.pie_cx + c.pie_r * 0.8, c.pie_cy))
				-- nine o'clock is 75% around: inside slice 2 (50..80)
			assert_integers_equal ("nine o'clock lies in the second slice", 2,
				c.slice_at (c.pie_cx - c.pie_r * 0.8, c.pie_cy))
				-- 90% around (upper-left): inside slice 3 (80..100)
			assert_integers_equal ("ninety percent around lies in the last fifth", 3,
				c.slice_at (c.pie_cx - c.pie_r * 0.47, c.pie_cy - c.pie_r * 0.647))
			assert_integers_equal ("the donut hole is nobody", 0,
				c.slice_at (c.pie_cx, c.pie_cy))
			assert_integers_equal ("open space is nobody", 0,
				c.slice_at (c.pie_cx + c.pie_r * 3.0, c.pie_cy))
		end

	test_pie_empty_is_honest
		local
			c: SW_PIE_CHART
		do
			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 300.0)
			assert_reals_equal ("no slices, no whole", 0.0, c.total, 0.000_1)
			assert_integers_equal ("no whole, no hits", 0,
				c.slice_at (c.pie_cx, c.pie_cy - c.pie_r * 0.5))
		end

	test_funnel_conversion_and_bands
		local
			c: SW_FUNNEL_CHART
		do
			create c.make
			c.add_stage ("in", 1_000.0)
			c.add_stage ("mid", 400.0)
			c.add_stage ("out", 250.0)
			assert_reals_equal ("the first converts fully", 100.0, c.conversion_of (1), 0.000_1)
			assert_reals_equal ("the tail names its share", 25.0, c.conversion_of (3), 0.000_1)
			c.set_bounds (0.0, 0.0, 400.0, 300.0)
			assert_integers_equal ("top band answers", 1, c.stage_at (c.plot_y + 1.0))
			assert_integers_equal ("bottom band answers", 3, c.stage_at (c.plot_y + c.plot_h - 1.0))
			assert_integers_equal ("outside answers nobody", 0, c.stage_at (c.plot_y - 10.0))
		end

feature -- Indicators

	test_gauge_fraction_zones_and_clamp
		local
			g: SW_GAUGE
		do
			create g.make (0.0, 40.0)
			g.set_zones (20.0, 33.0)
			g.set_value (10.0)
			assert_reals_equal ("a quarter along", 0.25, g.fraction, 0.000_1)
			assert_integers_equal ("calm below the warn line", 0, g.zone)
			g.set_value (20.0)
			assert_integers_equal ("warning AT the warn line", 1, g.zone)
			g.set_value (39.0)
			assert_integers_equal ("danger past its line", 2, g.zone)
			g.set_value (900.0)
			assert_reals_equal ("clamped to the span", 40.0, g.value, 0.000_1)
			assert_reals_equal ("and the sweep is full", 1.0, g.fraction, 0.000_1)
			g.set_value (-5.0)
			assert_reals_equal ("clamped from below too", 0.0, g.value, 0.000_1)
		end

	test_gauge_degenerate_span
		local
			g: SW_GAUGE
		do
			create g.make (7.0, 7.0)
			g.set_value (7.0)
			assert_reals_equal ("a flat span never sweeps", 0.0, g.fraction, 0.000_1)
		end

	test_sparkline_rolls_and_normalizes
		local
			s: SW_SPARKLINE
			i: INTEGER
		do
			create s.make
			s.set_capacity (4)
			from
				i := 1
			until
				i > 6
			loop
				s.add_value (i * 10.0)
				i := i + 1
			end
			assert_integers_equal ("the feed rolls at four", 4, s.values.count)
			assert_reals_equal ("the oldest two fell off", 30.0, s.values.first, 0.000_1)
			assert_reals_equal ("low is the survivor floor", 30.0, s.low, 0.000_1)
			assert_reals_equal ("high is the newest peak", 60.0, s.high, 0.000_1)
			assert_reals_equal ("the floor normalizes to zero", 0.0, s.fraction_of (1), 0.000_1)
			assert_reals_equal ("the peak normalizes to one", 1.0, s.fraction_of (4), 0.000_1)
		end

	test_sparkline_flat_is_midline
		local
			s: SW_SPARKLINE
		do
			create s.make
			s.add_value (5.0)
			s.add_value (5.0)
			s.add_value (5.0)
			assert_reals_equal ("no span on a flat feed", 0.0, s.span, 0.000_1)
			assert_reals_equal ("flat answers the honest midline", 0.5, s.fraction_of (2), 0.000_1)
		end

feature -- Densities

	test_heatmap_blend_endpoints
		local
			h: SW_HEATMAP
		do
			create h.make (2, 2)
			assert ("zero keeps the from-colour",
				h.blend (0x102030, 0xFFFFFF, 0.0) = 0x102030)
			assert ("one lands the to-colour",
				h.blend (0x102030, 0xFFFFFF, 1.0) = 0xFFFFFF)
			assert ("midway blends channel-wise",
				h.blend (0x000000, 0xFF00FF, 0.5) = 0x800080)
		end

	test_heatmap_slots_and_flat_honesty
		local
			h: SW_HEATMAP
		do
			create h.make (3, 4)
			h.set_cell (2, 3, 9.0)
			assert_reals_equal ("a cell keeps its value", 9.0, h.cell (2, 3), 0.000_1)
			assert_reals_equal ("the hottest normalizes to one", 1.0, h.heat_of (2, 3), 0.000_1)
			assert_reals_equal ("a cold cell normalizes to zero", 0.0, h.heat_of (1, 1), 0.000_1)
			h.set_bounds (0.0, 0.0, 400.0, 300.0)
			assert_integers_equal ("top row answers", 1, h.row_at (h.plot_y + 1.0))
			assert_integers_equal ("last column answers", 4, h.col_at (h.plot_x + h.plot_w - 1.0))
			assert_integers_equal ("outside answers nobody", 0, h.row_at (h.plot_y - 5.0))
			create h.make (2, 2)
			assert_reals_equal ("flat grids wash to the honest midpoint",
				0.5, h.heat_of (1, 1), 0.000_1)
		end

	test_treemap_areas_are_shares
		local
			tm: SW_TREEMAP
			i: INTEGER
			area, plot_area: REAL_64
		do
			create tm.make
			tm.add_item ("a", 50.0)
			tm.add_item ("b", 25.0)
			tm.add_item ("c", 15.0)
			tm.add_item ("d", 10.0)
			tm.set_bounds (0.0, 0.0, 400.0, 300.0)
			tm.refresh_layout
			plot_area := tm.plot_w * tm.plot_h
			from
				i := 1
			until
				i > tm.items.count
			loop
				area := tm.layout [i].rw * tm.layout [i].rh
				assert_reals_equal ("area fraction equals value fraction",
					tm.items.i_th (i).value / tm.total, area / plot_area, 0.000_001)
				i := i + 1
			end
		end

	test_treemap_tiles_cover_and_answer
		local
			tm: SW_TREEMAP
			i: INTEGER
			sum: REAL_64
		do
			create tm.make
			tm.add_item ("a", 60.0)
			tm.add_item ("b", 30.0)
			tm.add_item ("c", 10.0)
			tm.set_bounds (0.0, 0.0, 400.0, 300.0)
			tm.refresh_layout
			from
				i := 1
			until
				i > tm.items.count
			loop
				sum := sum + tm.layout [i].rw * tm.layout [i].rh
				assert_integers_equal ("each tile answers at its own centre", i,
					tm.item_at (tm.layout [i].rx + tm.layout [i].rw / 2.0,
						tm.layout [i].ry + tm.layout [i].rh / 2.0))
				i := i + 1
			end
			assert_reals_equal ("the tiles sum to the plot",
				tm.plot_w * tm.plot_h, sum, 0.001)
			assert_integers_equal ("outside answers nobody", 0,
				tm.item_at (tm.plot_x - 5.0, tm.plot_y))
			assert_reals_equal ("shares still sum to the whole", 100.0,
				tm.percent_of (1) + tm.percent_of (2) + tm.percent_of (3), 0.000_1)
		end

feature -- Flows

	test_sankey_throughput_is_max_flow
		local
			s: SW_SANKEY
			a, b, c: INTEGER
		do
			create s.make
			a := s.add_node ("a", 1)
			b := s.add_node ("b", 2)
			c := s.add_node ("c", 3)
			s.add_link (a, b, 100.0)
			s.add_link (b, c, 60.0)
			assert_reals_equal ("a source's throughput is its outflow", 100.0, s.throughput_of (a), 0.000_1)
			assert_reals_equal ("a middle node takes the LARGER flow", 100.0, s.throughput_of (b), 0.000_1)
			assert_reals_equal ("a sink's throughput is its inflow", 60.0, s.throughput_of (c), 0.000_1)
		end

	test_sankey_heights_proportional_in_column
		local
			s: SW_SANKEY
			a, b, c, d: INTEGER
		do
			create s.make
			a := s.add_node ("a", 1)
			b := s.add_node ("big", 2)
			c := s.add_node ("small", 2)
			d := s.add_node ("d", 3)
			s.add_link (a, b, 75.0)
			s.add_link (a, c, 25.0)
			s.add_link (b, d, 75.0)
			s.add_link (c, d, 25.0)
			s.set_bounds (0.0, 0.0, 500.0, 340.0)
			s.refresh_layout
			assert_reals_equal ("column heights carry the 3:1 ratio",
				3.0, s.node_rects [b].rh / s.node_rects [c].rh, 0.000_1)
			assert_integers_equal ("a bar answers at its centre", b,
				s.node_at (s.node_rects [b].rx + 2.0,
					s.node_rects [b].ry + s.node_rects [b].rh / 2.0))
		end

	test_sankey_moorings_stack_contiguously
		local
			s: SW_SANKEY
			a, b, c, d: INTEGER
		do
			create s.make
			a := s.add_node ("src", 1)
			b := s.add_node ("t1", 2)
			c := s.add_node ("t2", 2)
			d := s.add_node ("t3", 2)
			s.add_link (a, b, 50.0)
			s.add_link (a, c, 30.0)
			s.add_link (a, d, 20.0)
			s.set_bounds (0.0, 0.0, 500.0, 340.0)
			s.refresh_layout
			assert_reals_equal ("the first mooring starts at the bar top",
				s.node_rects [a].ry, s.link_bands [1].y0_top, 0.000_1)
			assert_reals_equal ("the second moors where the first ends",
				s.link_bands [1].y0_bot, s.link_bands [2].y0_top, 0.000_1)
			assert_reals_equal ("the third moors where the second ends",
				s.link_bands [2].y0_bot, s.link_bands [3].y0_top, 0.000_1)
			assert_reals_equal ("and the stack fills the bar exactly",
				s.node_rects [a].ry + s.node_rects [a].rh,
				s.link_bands [3].y0_bot, 0.000_1)
		end

feature -- Space and structure

	test_map_projection_round_trips
		local
			m: SW_MAP
		do
			create m.make
			m.set_bounds (0.0, 0.0, 500.0, 300.0)
			assert_reals_equal ("the dateline is the left edge",
				m.plot_x, m.x_of_lon (-180.0), 0.000_1)
			assert_reals_equal ("greenwich is the middle",
				m.plot_x + m.plot_w / 2.0, m.x_of_lon (0.0), 0.000_1)
			assert_reals_equal ("the north pole is the top",
				m.plot_y, m.y_of_lat (90.0), 0.000_1)
			assert_reals_equal ("longitude round-trips",
				-105.0, m.lon_at_x (m.x_of_lon (-105.0)), 0.000_1)
			assert_reals_equal ("latitude round-trips",
				39.7, m.lat_at_y (m.y_of_lat (39.7)), 0.000_1)
		end

	test_map_raster_and_markers
		local
			m: SW_MAP
		do
			create m.make
			m.set_bounds (0.0, 0.0, 500.0, 300.0)
			assert ("Denver sits on land", m.is_land (39.7, -105.0))
			assert ("the mid-Atlantic is sea", not m.is_land (30.0, -40.0))
			assert ("the mid-Pacific is sea", not m.is_land (0.0, -150.0))
			assert ("the Sahara is land", m.is_land (25.0, 10.0))
			assert ("Australia is land", m.is_land (-25.0, 135.0))
			m.add_marker ("Denver", 39.7, -105.0)
			assert_integers_equal ("the marker answers at its projection", 1,
				m.marker_at (m.x_of_lon (-105.0), m.y_of_lat (39.7)))
			assert_integers_equal ("open sea answers nobody", 0,
				m.marker_at (m.x_of_lon (-40.0), m.y_of_lat (30.0)))
		end

	test_diagram_contracts_and_physics
		local
			d: SW_DIAGRAM
			a, b, c: INTEGER
			i: INTEGER
		do
			create d.make
			a := d.add_node ("a")
			b := d.add_node ("b")
			c := d.add_node ("c")
			d.connect (a, b)
			d.connect (b, c)
			assert_integers_equal ("three nodes stand", 3, d.node_count)
			assert_integers_equal ("two edges bind them", 2, d.edges.count)
			d.set_bounds (0.0, 0.0, 400.0, 260.0)
			assert_integers_equal ("a node answers at its seed", a,
				d.nearest_node (d.x + d.nodes.i_th (a).px, d.y + d.nodes.i_th (a).py))
			from
				i := 1
			until
				i > 60
			loop
				d.relax_step
				i := i + 1
			end
			from
				i := 1
			until
				i > d.node_count
			loop
				assert ("physics keeps every node inside the box",
					d.nodes.i_th (i).px >= 16.0 and d.nodes.i_th (i).px <= 384.0
					and d.nodes.i_th (i).py >= 16.0 and d.nodes.i_th (i).py <= 244.0)
				i := i + 1
			end
			d.pin (b)
			d.nodes.i_th (b).px := 200.0
			d.nodes.i_th (b).py := 130.0
			d.relax_step
			d.relax_step
			assert_reals_equal ("a pinned node holds its ground",
				200.0, d.nodes.i_th (b).px, 0.000_1)
		end

feature -- Timezone tools

	test_picker_band_arithmetic
		local
			p: SW_TIMEZONE_PICKER
		do
			create p.make
			p.set_bounds (0.0, 0.0, 500.0, 300.0)
			assert_integers_equal ("greenwich is band zero", 0,
				p.offset_at (p.x_of_lon (0.0)))
			assert_integers_equal ("Denver's meridian is minus seven", -7,
				p.offset_at (p.x_of_lon (-105.0)))
			assert_integers_equal ("Sydney's meridian is plus ten", 10,
				p.offset_at (p.x_of_lon (151.2)))
			assert_integers_equal ("the west edge clamps to minus twelve", -12,
				p.offset_at (p.x_of_lon (-179.9)))
			assert_integers_equal ("the east edge clamps to plus twelve", 12,
				p.offset_at (p.x_of_lon (179.9)))
		end

	test_world_clock_zone_math
		local
			c: SW_WORLD_CLOCK
		do
			create c.make
			assert_integers_equal ("plus ninety past 23:30 is 01:00", 60,
				c.zone_time (23 * 60 + 30, 90))
			assert_integers_equal ("and that is tomorrow", 1,
				c.day_delta (23 * 60 + 30, 90))
			assert_integers_equal ("minus an hour before 00:15 is 23:15", 23 * 60 + 15,
				c.zone_time (15, -60))
			assert_integers_equal ("and that is yesterday", -1,
				c.day_delta (15, -60))
			assert_integers_equal ("India at noon UTC is 17:30", 17 * 60 + 30,
				c.zone_time (12 * 60, 330))
			assert_integers_equal ("and still today", 0,
				c.day_delta (12 * 60, 330))
		end

end
