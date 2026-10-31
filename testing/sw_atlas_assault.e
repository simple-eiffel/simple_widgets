note
	description: "[
		Assault on SW_ATLAS (Plan 22 phase 3, 2026-10-31): areas follow the
		year and the view; an area's fill is never the water's color, in light
		or dark; the smallest area answers a hover; a disputed site shows each
		candidate and its card names every holder; a press on a site selects
		it and does not pan; sites and timed routes follow the year; the map
		keeps its true aspect in a tall panel and the wheel still holds the
		point under the cursor; marked sites come into view and are labeled
		below their zoom; and 3,000 areas hold the frame budget.
	]"

class
	SW_ATLAS_ASSAULT

inherit
	SW_VIRTUAL_GRID_ASSAULT
			-- for the frame budget and the timing harness

feature -- Areas

	test_atlas_areas_follow_the_year_and_the_view
		local
			w: SW_WINDOW
			a: SW_ATLAS
		do
			w := atlas_window (create {SW_THEME}.make_light, 900, 600)
			a := atlas_of (w)
			a.add_area ("Assyria", square (43.0, 36.0, 3.0), -911, -609, 1, "").do_nothing
			a.add_area ("Babylonia", square (44.5, 32.5, 2.0), -625, -539, 2, "").do_nothing
			a.add_area ("Rome", square (12.5, 41.9, 2.0), -509, -27, 3, "").do_nothing
				-- 36 degrees across from 20 east to 56 east: Rome is west of it
			a.set_view (10.0, 38.0, 32.0)
			w.request_render
			assert_integers_equal ("no year, no areas", 0, a.areas_drawn)
			a.set_year (-700)
			w.request_render
			assert_integers_equal ("700 BC: Assyria alone", 1, a.areas_drawn)
			a.set_year (-612)
			w.request_render
			assert_integers_equal ("612 BC: both", 2, a.areas_drawn)
			a.set_year (-300)
			w.request_render
			assert_integers_equal ("Rome is out of the Near East view", 0, a.areas_drawn)
		end

	test_atlas_area_fill_is_not_the_water
			-- Spike S3 read a polity tint as sea: an area's pixel must stand apart from the
			-- water's, in light and dark.
		do
			fill_gate (create {SW_THEME}.make_light, "light")
			fill_gate (create {SW_THEME}.make_dark, "dark")
		end

	test_atlas_land_is_not_the_panel
			-- In a dock panel SW_MAP's land (the surface) read as empty panel: the Atlas's land
			-- differs from the surface beside it, in light and dark.
		do
			land_gate (create {SW_THEME}.make_light, "light")
			land_gate (create {SW_THEME}.make_dark, "dark")
		end

	test_atlas_smallest_area_answers_a_hover
		local
			w: SW_WINDOW
			a: SW_ATLAS
			l_outer, l_inner: INTEGER
		do
			w := atlas_window (create {SW_THEME}.make_light, 900, 600)
			a := atlas_of (w)
			l_outer := a.add_area ("Persian Empire", square (45.0, 32.0, 8.0), -549, -330, 4, "Achaemenid")
			l_inner := a.add_area ("Yehud", square (35.2, 31.7, 0.5), -538, -332, 5, "a province")
			a.set_year (-450)
			w.request_render
			assert_integers_equal ("Jerusalem is in Yehud", l_inner, a.area_at (a.x_of_lon (35.2), a.y_of_lat (31.7)))
			assert_integers_equal ("Babylon is in the empire", l_outer, a.area_at (a.x_of_lon (44.4), a.y_of_lat (32.5)))
			if attached a.hover_card_at (a.x_of_lon (35.2), a.y_of_lat (31.7)) as al_card then
				assert_strings_equal ("an area's card", "area", a.last_card_kind)
			else
				assert_true ("a card over Yehud", False)
			end
		end

feature -- Sites

	test_atlas_disputed_site_shows_every_candidate
		local
			w: SW_WINDOW
			a: SW_ATLAS
			s: INTEGER
		do
			w := atlas_window (create {SW_THEME}.make_light, 900, 600)
			a := atlas_of (w)
			s := a.add_site ("bethsaida", "Bethsaida", 3.0, a.Always_from, a.Always_to, "")
			a.add_candidate (s, 35.630, 32.910, 2500.0, "et-Tell", False)
			a.add_candidate (s, 35.613, 32.893, 2500.0, "el-Araj", False)
			a.set_view (100.0, 35.6, 32.9)
			w.request_render
			assert_true ("disputed", a.is_disputed (s))
			assert_integers_equal ("et-Tell finds the site", s, a.site_at (a.x_of_lon (35.630), a.y_of_lat (32.910)))
			assert_integers_equal ("el-Araj finds it too", s, a.site_at (a.x_of_lon (35.613), a.y_of_lat (32.893)))
			assert_true ("each candidate labeled with its holder",
				across a.drawn_labels as d some d.text.same_string ("Bethsaida: et-Tell") end
				and across a.drawn_labels as d some d.text.same_string ("Bethsaida: el-Araj") end)
			if attached a.hover_card_at (a.x_of_lon (35.630), a.y_of_lat (32.910)) as al_card then
				assert_strings_equal ("a site's card", "site", a.last_card_kind)
			else
				assert_true ("a card over et-Tell", False)
			end
		end

	test_atlas_press_on_a_site_selects_and_does_not_pan
		local
			w: SW_WINDOW
			a: SW_ATLAS
			s: INTEGER
			l_cx: REAL_64
		do
			w := atlas_window (create {SW_THEME}.make_light, 900, 600)
			a := atlas_of (w)
			s := a.add_site ("jerusalem", "Jerusalem", 1.0, a.Always_from, a.Always_to, "")
			a.add_candidate (s, 35.234, 31.777, 800.0, "", False)
			a.set_on_site_select (agent (i: INTEGER) do picked := i end)
			a.set_view (12.0, 36.0, 32.0)
			w.request_render
			picked := 0
			l_cx := a.view_cx
			assert_true ("the press is taken", a.handle_click (a.x_of_lon (35.234), a.y_of_lat (31.777)))
			assert_integers_equal ("Jerusalem selected", s, picked)
			assert_integers_equal ("and held", s, a.selected_site)
			a.handle_drag (a.x_of_lon (35.234), a.y_of_lat (31.777))
			assert_reals_equal ("no pan from a still press", l_cx, a.view_cx, 0.000001)
			picked := 0
			a.handle_click (a.x_of_lon (30.0), a.y_of_lat (31.0)).do_nothing
			assert_integers_equal ("open ground selects nothing", 0, picked)
		end

	test_atlas_sites_and_timed_routes_follow_the_year
		local
			w: SW_WINDOW
			a: SW_ATLAS
			s: INTEGER
		do
			w := atlas_window (create {SW_THEME}.make_light, 900, 600)
			a := atlas_of (w)
			s := a.add_site ("caesarea", "Caesarea Maritima", 1.0, -21, 640, "")
			a.add_candidate (s, 34.890, 32.500, 800.0, "", False)
			a.add_timed_route ("Paul to Rome", <<34.89, 32.50, 12.49, 41.89>>, True, 59, 60)
			a.set_view (12.0, 36.0, 32.0)
			a.set_year (-500)
			w.request_render
			assert_integers_equal ("not built yet", 0, a.site_at (a.x_of_lon (34.890), a.y_of_lat (32.500)))
			assert_false ("the voyage not yet", a.route_shown (1))
			a.set_year (60)
			w.request_render
			assert_integers_equal ("built", s, a.site_at (a.x_of_lon (34.890), a.y_of_lat (32.500)))
			assert_true ("the voyage under way", a.route_shown (1))
		end

	test_atlas_marked_sites_come_into_view_labeled
		local
			w: SW_WINDOW
			a: SW_ATLAS
			s1, s2: INTEGER
			l_list: ARRAYED_LIST [INTEGER]
		do
			w := atlas_window (create {SW_THEME}.make_light, 900, 600)
			a := atlas_of (w)
			s1 := a.add_site ("lachish", "Lachish", 100.0, a.Always_from, a.Always_to, "")
			a.add_candidate (s1, 34.849, 31.565, 500.0, "", False)
			s2 := a.add_site ("nineveh", "Nineveh", 100.0, a.Always_from, a.Always_to, "")
			a.add_candidate (s2, 43.152, 36.359, 800.0, "", False)
			a.set_view (60.0, 10.0, 50.0)
			w.request_render
			create l_list.make (2)
			l_list.extend (s1)
			l_list.extend (s2)
			a.set_marked (l_list)
			a.fit_marked (64.0)
			w.request_render
			assert_true ("Lachish in the plot", inside (a, 34.849, 31.565))
			assert_true ("Nineveh in the plot", inside (a, 43.152, 36.359))
			assert_true ("labeled below their zoom because marked",
				a.effective_zoom < 100.0 and across a.drawn_labels as d some d.text.same_string ("Lachish") end
				and across a.drawn_labels as d some d.text.same_string ("Nineveh") end)
		end

feature -- Aspect

	test_atlas_keeps_a_true_aspect_and_the_wheel_its_anchor
		local
			w: SW_WINDOW
			a: SW_ATLAS
			l_lon_px, l_lat_px, l_lon, l_lat: REAL_64
		do
			w := atlas_window (create {SW_THEME}.make_light, 420, 900)
			a := atlas_of (w)
			a.set_view (8.0, 36.0, 32.0)
			w.request_render
			l_lon_px := a.x_of_lon (37.0) - a.x_of_lon (36.0)
			l_lat_px := a.y_of_lat (32.0) - a.y_of_lat (33.0)
			assert_reals_equal ("a degree of latitude is 1 / cos 32 degrees of longitude's pixels",
				l_lon_px / {DOUBLE_MATH}.cosine (32.0 * 0.017453292519943295), l_lat_px, l_lat_px * 0.01)
			a.set_hover_point (a.plot_x + a.plot_w * 0.3, a.plot_y + a.plot_h * 0.7)
			l_lon := a.lon_at_x (a.hover_px)
			l_lat := a.lat_at_y (a.hover_py)
			a.handle_wheel (240).do_nothing
			assert_reals_equal ("the wheel keeps the longitude under the cursor", l_lon, a.lon_at_x (a.hover_px), 0.0001)
			assert_reals_equal ("and the latitude", l_lat, a.lat_at_y (a.hover_py), 0.0001)
		end

feature -- Budget

	test_atlas_three_thousand_areas_hold_the_frame_budget
			-- Cliopatria-sized: 3,000 areas of 60 points, about one in twenty holding the year;
			-- a pan frame inside the budget of the build (spike S3: 5,656 outlines, 7 to 9 ms lean).
		local
			w: SW_WINDOW
			a: SW_ATLAS
			i, k: INTEGER
			l_frames: ARRAYED_LIST [REAL_64]
		do
			w := atlas_window (create {SW_THEME}.make_dark, 1400, 900)
			a := atlas_of (w)
			from i := 1 until i > 3000 loop
				a.add_area ("Polity " + i.out, ring_of (20.0 + (i \\ 50) * 0.8, 15.0 + (i // 50) * 0.5, 0.6 + (i \\ 7) * 0.4, 60),
					-3000 + (i \\ 20) * 150, -3000 + (i \\ 20) * 150 + 140, 1 + i \\ a.Hue_count, "").do_nothing
				i := i + 1
			end
			a.set_view (6.0, 40.0, 32.0)
			a.set_year (-1500)
			w.request_render
			create l_frames.make (12)
			from k := 1 until k > 12 loop
				a.set_view (6.0, 40.0 + (k \\ 2) * 0.5, 32.0)
				l_frames.extend (timed (agent w.request_render))
				k := k + 1
			end
			io.put_string ("    atlas 3,000 areas, " + a.areas_drawn.out + " drawn at 1500 BC: pan frame median " + ((median (l_frames) * 100.0).rounded / 100.0).out + " ms%N")
			assert_true ("some areas drawn", a.areas_drawn > 0)
			assert_true ("a pan frame holds the budget", median (l_frames) < budget_here)
		end

feature {NONE} -- Helpers

	picked: INTEGER

	atlas_window (a_theme: SW_THEME; a_w, a_h: INTEGER): SW_WINDOW
		local
			a: SW_ATLAS
		do
			create Result.make ("atlas", 0, 0, a_w, a_h, a_theme)
			Result.set_exports_in_screen_theme (True)
			create a.make
			Result.set_root (a)
			a.set_view (6.0, 38.0, 32.0)
		end

	atlas_of (a_window: SW_WINDOW): SW_ATLAS
		do
			check attached {SW_ATLAS} a_window.root as al_atlas then
				Result := al_atlas
			end
		end

	square (a_lon, a_lat, a_half: REAL_64): ARRAY [REAL_64]
		do
			Result := <<a_lon - a_half, a_lat - a_half, a_lon + a_half, a_lat - a_half, a_lon + a_half, a_lat + a_half, a_lon - a_half, a_lat + a_half>>
		end

	ring_of (a_lon, a_lat, a_r: REAL_64; a_n: INTEGER): ARRAY [REAL_64]
		local
			k: INTEGER
		do
			create Result.make_filled (0.0, 1, 2 * a_n)
			from k := 0 until k >= a_n loop
				Result [2 * k + 1] := a_lon + a_r * {DOUBLE_MATH}.cosine (k * 6.283185307179586 / a_n)
				Result [2 * k + 2] := a_lat + a_r * {DOUBLE_MATH}.sine (k * 6.283185307179586 / a_n)
				k := k + 1
			end
		end

	inside (a: SW_ATLAS; a_lon, a_lat: REAL_64): BOOLEAN
		do
			Result := a.x_of_lon (a_lon) >= a.plot_x and a.x_of_lon (a_lon) <= a.plot_x + a.plot_w
				and a.y_of_lat (a_lat) >= a.plot_y and a.y_of_lat (a_lat) <= a.plot_y + a.plot_h
		end

	land_gate (a_theme: SW_THEME; a_name: STRING)
			-- The Arabian desert's pixel stands apart from the panel's surface beside the plot.
		local
			w: SW_WINDOW
			a: SW_ATLAS
			l_land, l_panel: NATURAL_32
		do
			w := atlas_window (a_theme, 900, 600)
			a := atlas_of (w)
			w.request_render
			l_land := map_pixel (w, a, 46.7, 24.7)
			l_panel := a_theme.surface & 0xFFFFFF
			io.put_string ("    atlas " + a_name + ": land " + l_land.to_hex_string + ", panel " + l_panel.to_hex_string + "%N")
			assert_false (a_name + ": the land is not the panel", near (l_land, l_panel, 8))
		end

	fill_gate (a_theme: SW_THEME; a_name: STRING)
			-- An area over the open Mediterranean: its pixel differs from the water's by more
			-- than 40 levels on some channel.
		local
			w: SW_WINDOW
			a: SW_ATLAS
			l_water, l_area: NATURAL_32
		do
			w := atlas_window (a_theme, 900, 600)
			a := atlas_of (w)
			a.set_view (6.0, 25.0, 34.0)
			w.request_render
			l_water := map_pixel (w, a, 25.0, 34.0)
			a.add_area ("Sea empire", square (25.0, 34.0, 1.5), -1000, 0, 1, "").do_nothing
			a.set_year (-500)
			w.request_render
			l_area := map_pixel (w, a, 25.0, 34.0)
			io.put_string ("    atlas " + a_name + ": water " + l_water.to_hex_string + ", area " + l_area.to_hex_string + "%N")
			assert_false (a_name + ": the area is not the water", near (l_water, l_area, 40))
		end

	map_pixel (a_window: SW_WINDOW; a_map: SW_MAP; a_lon, a_lat: REAL_64): NATURAL_32
		local
			img: CAIRO_SURFACE
			m: REAL_64
			mp: MANAGED_POINTER
			px, py: INTEGER
		do
			img := a_window.widget_image (a_map, Void, 1.0)
			m := a_window.export_margin (a_window.theme)
			px := (a_map.x_of_lon (a_lon) - a_map.x + m).truncated_to_integer
			py := (a_map.y_of_lat (a_lat) - a_map.y + m).truncated_to_integer
			img.flush.do_nothing
			create mp.share_from_pointer (img.data, img.stride * img.height)
			Result := mp.read_natural_32 (py.max (0).min (img.height - 1) * img.stride + px.max (0).min (img.width - 1) * 4) & 0xFFFFFF
			img.destroy
		end

	near (a, b: NATURAL_32; a_tol: INTEGER): BOOLEAN
		do
			Result := (((a |>> 16) & 0xFF).to_integer_32 - ((b |>> 16) & 0xFF).to_integer_32).abs <= a_tol
				and (((a |>> 8) & 0xFF).to_integer_32 - ((b |>> 8) & 0xFF).to_integer_32).abs <= a_tol
				and ((a & 0xFF).to_integer_32 - (b & 0xFF).to_integer_32).abs <= a_tol
		end

end
