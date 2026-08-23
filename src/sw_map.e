note
	description: "[
		The world, real: Natural Earth 110m coastlines (127 rings,
		4,964 points, generated into SW_WORLD_GEOMETRY - the once
		'stated future', arrived 2026-08-23) drawn zero-allocation
		through the projection math, public and assaulted
		(x_of_lon / y_of_lat and their inverses), labelled MARKERS
		with nearest-within-reach hover, and the timezone band-map
		grown up: highlight_utc washes the 15-degree band of any UTC
		offset. Hovering open sea reads out lat/lon - the map answers
		where you are, always.
	]"

class
	SW_MAP

inherit
	SW_CHART
		redefine
			draw
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create markers.make (8)
		end

feature -- Access

	markers: ARRAYED_LIST [TUPLE [label: STRING_32; lat, lon: REAL_64]]

	has_zone: BOOLEAN
			-- Is a UTC band highlighted?

	zone_offset: INTEGER
			-- The highlighted UTC offset when has_zone.

feature -- Projection (public, assaulted)

	x_of_lon (a_lon: REAL_64): REAL_64
			-- Equirectangular: longitude to plot x.
		do
			Result := plot_x + (a_lon + 180.0) / 360.0 * plot_w
		end

	y_of_lat (a_lat: REAL_64): REAL_64
			-- Equirectangular: latitude to plot y (north up).
		do
			Result := plot_y + (90.0 - a_lat) / 180.0 * plot_h
		end

	lon_at_x (a_px: REAL_64): REAL_64
		do
			Result := (a_px - plot_x) / plot_w * 360.0 - 180.0
		end

	lat_at_y (a_py: REAL_64): REAL_64
		do
			Result := 90.0 - (a_py - plot_y) / plot_h * 180.0
		end

	marker_at (a_px, a_py: REAL_64): INTEGER
			-- The marker within reach of a surface point; 0 for none.
		local
			i: INTEGER
			d2, best, dx, dy: REAL_64
		do
			best := 145.0
			from
				i := 1
			until
				i > markers.count
			loop
				dx := x_of_lon (markers.i_th (i).lon) - a_px
				dy := y_of_lat (markers.i_th (i).lat) - a_py
				d2 := dx * dx + dy * dy
				if d2 < best then
					best := d2
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= markers.count
		end

	is_land (a_lat, a_lon: REAL_64): BOOLEAN
			-- Does the coarse raster call this point land?
		local
			r, c: INTEGER
		do
			if a_lat < 90.0 and a_lat > -90.0 and a_lon >= -180.0 and a_lon < 180.0 then
				r := ((90.0 - a_lat) / 5.0).floor + 1
				c := ((a_lon + 180.0) / 5.0).floor + 1
				if r >= 1 and r <= 36 and c >= 1 and c <= 72 then
					Result := land_rows [r].item (c) = '#'
				end
			end
		end

feature -- Element change

	add_marker (a_label: READABLE_STRING_GENERAL; a_lat, a_lon: REAL_64)
		require
			lat_sane: a_lat >= -90.0 and a_lat <= 90.0
			lon_sane: a_lon >= -180.0 and a_lon <= 180.0
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			markers.extend ([l, a_lat, a_lon])
		ensure
			grew: markers.count = old markers.count + 1
		end

	highlight_utc (a_offset: INTEGER)
			-- Wash the 15-degree band of a UTC offset.
		require
			sane: a_offset >= -12 and a_offset <= 14
		do
			has_zone := True
			zone_offset := a_offset
		ensure
			lit: has_zone and zone_offset = a_offset
		end

	clear_zone
		do
			has_zone := False
		ensure
			dark: not has_zone
		end

feature -- Data

	refresh_domains
			-- The projection is the scale; the chassis axes idle.
		do
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			r, hot: INTEGER
			zx: REAL_64
			chip: detachable STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.surface_variant)
			draw_land (a_p)
			if has_zone then
				zx := x_of_lon ((zone_offset * 15).to_double - 7.5)
				a_p.set_color_alpha (t.accent, 0.18)
				a_p.fill_rect (zx, plot_y, plot_w / 24.0, plot_h)
				a_p.set_color_alpha (t.accent, 0.6)
				a_p.vline (x_of_lon ((zone_offset * 15).to_double), plot_y, plot_h)
			end
			if shows_hover then
				hot := marker_at (hover_px, hover_py)
			end
			from
				r := 1
			until
				r > markers.count
			loop
				a_p.set_color (t.accent)
				a_p.circle_fill (x_of_lon (markers.i_th (r).lon),
					y_of_lat (markers.i_th (r).lat), 3.4)
				a_p.set_color (t.surface)
				a_p.circle_stroke (x_of_lon (markers.i_th (r).lon),
					y_of_lat (markers.i_th (r).lat), 4.0)
				r := r + 1
			end
			if hot > 0 then
				create chip.make (32)
				chip.append (markers.i_th (hot).label)
				chip.append ({STRING_32} " %/8212/ ")
				chip.append (label_of (markers.i_th (hot).lat))
				chip.append ({STRING_32} ", ")
				chip.append (label_of (markers.i_th (hot).lon))
			elseif shows_hover and then hover_px >= plot_x and then hover_px <= plot_x + plot_w
				and then hover_py >= plot_y and then hover_py <= plot_y + plot_h
			then
				create chip.make (24)
				chip.append (label_of (lat_at_y (hover_py)))
				chip.append ({STRING_32} ", ")
				chip.append (label_of (lon_at_x (hover_px)))
				if is_land (lat_at_y (hover_py), lon_at_x (hover_px)) then
					chip.append ({STRING_32} "  land")
				else
					chip.append ({STRING_32} "  sea")
				end
			end
			if attached chip as the_chip and then not the_chip.is_empty then
				a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + 10.0, y + height - 24.0, a_p.advance (the_chip) + 10.0, 17.0, 3.0)
				a_p.set_color (t.ink)
				a_p.text (x + 15.0, y + height - 11.0, the_chip)
			end
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature {NONE} -- The coarse world

	geometry: SW_WORLD_GEOMETRY
			-- The real coastlines (Natural Earth 110m, generated);
			-- the polygon list itself is once-shared.
		once
			create Result
		end

	screen_buf: ARRAY [REAL_64]
			-- Reused screen-space buffer for the biggest ring - the
			-- hot path allocates nothing per frame.
		once
			create Result.make_filled (0.0, 1, 2600)
		end

	draw_land (a_p: SW_PAINTER)
			-- Real coastlines through the same assaulted projection
			-- the raster once used - the 'stated future', arrived
			-- (2026-08-23). The raster stays for is_land hit tests.
		local
			k, n: INTEGER
		do
			across
				geometry.polygons as poly
			loop
				n := poly.count // 2
				if n >= 3 and n * 2 <= screen_buf.count then
					from
						k := 0
					until
						k >= n
					loop
						screen_buf [k * 2 + 1] := x_of_lon (poly [k * 2 + 1])
						screen_buf [k * 2 + 2] := y_of_lat (poly [k * 2 + 2])
						k := k + 1
					end
					a_p.polygon_fill_flat (screen_buf, n)
				end
			end
		end

	land_rows: ARRAY [STRING]
			-- 36 bands of 72 five-degree cells; '#' is land.
		once
			Result := <<
			"........................................................................",
			".....................####......##.....####....####....###...............",
			"............########..###########......###.....###########..............",
			"...#####..##########....########.......#################################",
			"...#####.##############...####.##....###################################",
			"...######################............###################################",
			"......###################.........##.###################################",
			"..........###############.........##############################........",
			"...........############.............###########################.#.......",
			"...........###########............##.########################..#........",
			"...........##########.............##..#.####################.###........",
			"............########..............##########################.#..........",
			".............###...#.............###############.###########............",
			".............###...##...........################..###..####.............",
			"...............###..............##############....###..##...............",
			".................##..###........#############......#...##...#...........",
			"....................#####........############.............#.#...........",
			"....................######...........########..........#.##...##........",
			"....................#########.........######............#.#...####......",
			"....................#########.........######.............##.....##......",
			"....................########..........######..................#.........",
			"......................######..........#####.##..............#####.......",
			"......................#####...........####..#.............########......",
			"......................####.............###................########......",
			".....................###...............##..................#.#####......",
			".....................###........................................#.....#.",
			".....................##..............................................#..",
			".....................#..................................................",
			".....................#..................................................",
			"......................#.................................................",
			".......................#................................................",
			".......................#........................#################.......",
			"..................######......########################################..",
			"......################################################################..",
			"########################################################################",
			"########################################################################"
			>>
		end

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	markers_attached: markers /= Void

end
