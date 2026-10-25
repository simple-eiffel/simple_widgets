note
	description: "[
		Assault on GW-19, SW_MAP's Atlas: a palette from the theme that keeps
		land and water apart in light and dark; the 1:10m Levant (the Sea of
		Galilee is water only with the regional layer); rivers and routes
		on their layers, an uncertain route dashed; place labels from their
		own zoom, an overlapping one left out; and the Levant with Hebrew and
		Greek place names in both themes (evidence gw19_levant_light.png,
		gw19_levant_dark.png).
	]"

class
	SW_REGIONAL_MAP_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Palette

	test_gw19_land_and_water_stay_apart
			-- In light and dark, land and water differ at 1.2:1 or more and ink
			-- labels read on land at 4.5:1.
		do
			palette_gate (create {SW_THEME}.make_light, "light")
			palette_gate (create {SW_THEME}.make_dark, "dark")
		end

feature -- Regional detail

	test_gw19_galilee_is_water_with_the_regional_layer
			-- At a Galilee view the lake's middle is water; with the regional
			-- layer off it is the world's coarse land; with lakes off, land.
		local
			w: SW_WINDOW
			m: SW_MAP
		do
			w := map_window (create {SW_THEME}.make_light)
			m := map_of (w)
				-- the Jordan's centerline crosses the lake: rivers off, lakes alone
			m.set_layer_shown (m.Layer_rivers, False)
			m.set_view (64.0, 35.58, 32.81)
			w.request_render
			assert_true ("the region draws at this zoom", m.is_region_drawn)
			assert_true ("Galilee is water", map_pixel (w, m, 35.58, 32.81) = m.water_color (w.theme))
			m.set_layer_shown (m.Layer_lakes, False)
			w.request_render
			assert_true ("lakes off: land", map_pixel (w, m, 35.58, 32.81) = m.land_color (w.theme))
			m.set_layer_shown (m.Layer_lakes, True)
			m.set_layer_shown (m.Layer_region, False)
			w.request_render
			assert_false ("region off: not drawn", m.is_region_drawn)
			assert_true ("the coarse world has no lake there", map_pixel (w, m, 35.58, 32.81) = m.land_color (w.theme))
		end

	test_gw19_rivers_and_routes_on_their_layers
			-- Over Mesopotamia the rivers ink the map; their layer off, none.
			-- An uncertain route from Jerusalem to Damascus breaks into dashes;
			-- a certain one does not; the routes layer off, no route.
		local
			w: SW_WINDOW
			m: SW_MAP
		do
			w := map_window (create {SW_THEME}.make_light)
			m := map_of (w)
			m.set_view (12.0, 44.0, 33.0)
			w.request_render
			assert_true ("the rivers show", count_near (w, m, m.river_color (w.theme)) > 50)
			m.set_layer_shown (m.Layer_rivers, False)
			w.request_render
			assert_integers_equal ("rivers off", 0, count_near (w, m, m.river_color (w.theme)))
			m.add_route ("Jerusalem to Damascus", <<35.23, 31.78, 36.29, 33.51>>, False)
			m.set_view (24.0, 35.7, 32.6)
			w.request_render
			assert_true ("the uncertain route is dashed: " + route_runs (w, m).out + " runs", route_runs (w, m) >= 4)
			m.routes.first.is_certain := True
			w.request_render
			assert_true ("a certain route is one line: " + route_runs (w, m).out, route_runs (w, m) <= 2)
			m.set_layer_shown (m.Layer_routes, False)
			w.request_render
			assert_integers_equal ("routes off", 0, route_runs (w, m))
		end

	test_gw19_labels_from_their_zoom_without_overlap
			-- Labels for places that ask for zoom 8: none at zoom 4; at 16 the
			-- second of two close places is left out; at 128 both show.
		local
			w: SW_WINDOW
			m: SW_MAP
		do
			w := map_window (create {SW_THEME}.make_light)
			m := map_of (w)
			m.add_place ("Jerusalem", 31.78, 35.23, 8.0)
			m.add_place ("Bethlehem", 31.70, 35.20, 8.0)
			m.set_view (4.0, 35.2, 31.7)
			w.request_render
			assert_integers_equal ("zoom 4: no labels", 0, m.drawn_labels.count)
			m.set_view (16.0, 35.2, 31.7)
			w.request_render
			assert_integers_equal ("zoom 16: one label", 1, m.drawn_labels.count)
			assert_true ("the first place keeps it", m.drawn_labels.first.text.same_string ("Jerusalem"))
			m.set_view (128.0, 35.2, 31.74)
			w.request_render
			assert_integers_equal ("zoom 128: both", 2, m.drawn_labels.count)
		end

feature -- Scan 16 (since 3f9242a)

	test_scan16_the_caspian_is_water
			-- HIGH: the generator kept only the land's outer rings, so the
			-- Caspian Sea - a hole in the land - drew as land.
		local
			w: SW_WINDOW
			m: SW_MAP
		do
			w := map_window (create {SW_THEME}.make_light)
			m := map_of (w)
			m.set_view (8.0, 47.0, 41.0)
			w.request_render
			assert_true ("the region draws", m.is_region_drawn)
			assert_true ("the Caspian is water", map_pixel (w, m, 49.5, 41.5) = m.water_color (w.theme))
			assert_true ("and Persia is land", map_pixel (w, m, 47.0, 34.0) = m.land_color (w.theme))
		end

feature -- Evidence

	test_gw19_levant_light
		do
			levant (create {SW_THEME}.make_light, "gw19_levant_light.png")
		end

	test_gw19_levant_dark
		do
			levant (create {SW_THEME}.make_dark, "gw19_levant_dark.png")
		end

feature {NONE} -- Fixtures

	palette_gate (a_theme: SW_THEME; a_name: STRING)
		local
			m: SW_MAP
		do
			create m.make
			assert_true (a_name + ": land and water apart",
				a_theme.contrast_ratio (m.land_color (a_theme), m.water_color (a_theme)) >= 1.2)
			assert_true (a_name + ": ink reads on land",
				a_theme.contrast_ratio (a_theme.ink, m.land_color (a_theme)) >= 4.5)
		end

	map_window (a_theme: SW_THEME): SW_WINDOW
		local
			m: SW_MAP
		do
			create Result.make ("gw19", 0, 0, 700, 520, a_theme)
			Result.set_exports_in_screen_theme (True)
			create m.make
			Result.set_root (m)
		end

	map_of (a_window: SW_WINDOW): SW_MAP
		do
			check attached {SW_MAP} a_window.root as al_map then
				Result := al_map
			end
		end

	frame_of (a_window: SW_WINDOW; a_map: SW_MAP): CAIRO_SURFACE
			-- The map drawn alone, in the screen theme.
		do
			Result := a_window.widget_image (a_map, Void, 1.0)
		end

	map_pixel (a_window: SW_WINDOW; a_map: SW_MAP; a_lon, a_lat: REAL_64): NATURAL_32
			-- The colour at (`a_lon', `a_lat'), alpha dropped.
		local
			img: CAIRO_SURFACE
			m: REAL_64
		do
			img := frame_of (a_window, a_map)
			m := a_window.export_margin (a_window.theme)
			Result := pixel (img, (a_map.x_of_lon (a_lon) - a_map.x + m).truncated_to_integer,
				(a_map.y_of_lat (a_lat) - a_map.y + m).truncated_to_integer) & 0xFFFFFF
			img.destroy
		end

	count_near (a_window: SW_WINDOW; a_map: SW_MAP; a_rgb: NATURAL_32): INTEGER
			-- Pixels of the plot within a few levels of `a_rgb'.
		local
			img: CAIRO_SURFACE
			xx, yy, m: INTEGER
		do
			img := frame_of (a_window, a_map)
			m := a_window.export_margin (a_window.theme).truncated_to_integer
			from yy := m + 20 until yy >= img.height - m - 20 loop
				from xx := m + 20 until xx >= img.width - m - 20 loop
					if near (pixel (img, xx, yy) & 0xFFFFFF, a_rgb, 12) then
						Result := Result + 1
					end
					xx := xx + 1
				end
				yy := yy + 1
			end
			img.destroy
		end

	route_runs (a_window: SW_WINDOW; a_map: SW_MAP): INTEGER
			-- Separate runs of route ink sampled along Jerusalem to Damascus.
		local
			img: CAIRO_SURFACE
			k: INTEGER
			t, m, lon, lat: REAL_64
			l_in, l_now: BOOLEAN
		do
			img := frame_of (a_window, a_map)
			m := a_window.export_margin (a_window.theme)
			from k := 10 until k > 390 loop
				t := k / 400.0
				lon := 35.23 + (36.29 - 35.23) * t
				lat := 31.78 + (33.51 - 31.78) * t
				l_now := near_around (img, (a_map.x_of_lon (lon) - a_map.x + m).rounded, (a_map.y_of_lat (lat) - a_map.y + m).rounded,
					a_map.route_color (a_window.theme))
				if l_now and not l_in then
					Result := Result + 1
				end
				l_in := l_now
				k := k + 1
			end
			img.destroy
		end

	near_around (a_img: CAIRO_SURFACE; a_x, a_y: INTEGER; a_rgb: NATURAL_32): BOOLEAN
			-- Is route ink within one pixel of (`a_x', `a_y') (a two-pixel line is
			-- antialiased; a dash gap is six)?
		local
			dx, dy: INTEGER
		do
			from dy := -1 until dy > 1 or Result loop
				from dx := -1 until dx > 1 or Result loop
					Result := near (pixel (a_img, a_x + dx, a_y + dy) & 0xFFFFFF, a_rgb, 60)
					dx := dx + 1
				end
				dy := dy + 1
			end
		end

	near (a, b: NATURAL_32; a_tol: INTEGER): BOOLEAN
		do
			Result := (((a |>> 16) & 0xFF).to_integer_32 - ((b |>> 16) & 0xFF).to_integer_32).abs <= a_tol
				and (((a |>> 8) & 0xFF).to_integer_32 - ((b |>> 8) & 0xFF).to_integer_32).abs <= a_tol
				and ((a & 0xFF).to_integer_32 - (b & 0xFF).to_integer_32).abs <= a_tol
		end

	pixel (a_surface: CAIRO_SURFACE; a_x, a_y: INTEGER): NATURAL_32
		local
			mp: MANAGED_POINTER
		do
			a_surface.flush.do_nothing
			create mp.share_from_pointer (a_surface.data, a_surface.stride * a_surface.height)
			Result := mp.read_natural_32 (a_y.max (0).min (a_surface.height - 1) * a_surface.stride + a_x.max (0).min (a_surface.width - 1) * 4)
		end

	levant (a_theme: SW_THEME; a_name: STRING)
			-- The Levant at zoom 22: rivers, lakes, two routes (one uncertain),
			-- places with Hebrew and Greek names.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			m: SW_MAP
			path: STRING_32
		do
			create w.make ("gw19", 0, 0, 900, 640, a_theme)
			kit := gw03_kit (a_theme)
			w.set_shaping (kit)
			create m.make
			m.with_title ("The Levant").do_nothing
			m.add_place (text_of (<<0x05D9, 0x05B0, 0x05E8, 0x05D5, 0x05BC, 0x05E9, 0x05B8, 0x05DC, 0x05B7, 0x05D9, 0x05B4, 0x05DD>>), 31.78, 35.23, 4.0)
			m.add_place ("Damascus", 33.51, 36.29, 4.0)
			m.add_place ("Tyre", 33.27, 35.20, 4.0)
			m.add_place (text_of (<<0x039A, 0x03B1, 0x03B9, 0x03C3, 0x03AC, 0x03C1, 0x03B5, 0x03B9, 0x03B1>>), 32.50, 34.89, 4.0)
			m.add_place ("Capernaum", 32.88, 35.57, 4.0)
			m.add_place ("Alexandria", 31.20, 29.92, 4.0)
			m.add_route ("Via Maris", <<31.20, 30.10, 34.30, 31.40, 34.89, 32.50, 35.57, 32.88, 36.29, 33.51>>, True)
			m.add_route ("Jerusalem to Damascus", <<35.23, 31.78, 35.40, 32.40, 35.70, 32.90, 36.29, 33.51>>, False)
			w.set_root (m)
			m.set_view (22.0, 33.5, 31.8)
			w.request_render
			assert_true ("the region draws", m.is_region_drawn)
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			assert_true ("the place names are drawn", m.drawn_labels.count >= 4)
			path := evidence_path (a_name)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

end
