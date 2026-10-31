note
	description: "[
		The Atlas (Plan 22 phase 3, 2026-10-31): SW_MAP with time and doubt.

		AREAS (empires, lands) each hold a span of years and are drawn only
		when the year shown (`set_year') falls inside it, largest first so the
		smallest answers a hover, each in an earth hue of its own with an
		outline: never a tint near the water's blue (spike S3 read a polity
		tint as sea).

		SITES are places whose location is a claim: one candidate is a dot (a
		dashed ring as well when its doubt is wide on screen); several are
		dashed rings, each labeled with who holds it, the lean drawn solid.
		A site may hold a span of years too. Sites MARKED by the caller (an
		event's places) are ringed in the accent and always labeled, and
		`fit_marked' brings them into view. A press on a site selects it
		(`on_site_select') instead of starting a pan.

		Hover cards on sites, routes and areas (spike S6). Routes added with
		`add_timed_route' follow the year as well.

		A SCALE (Larry, 2026-10-31: "a scale in US Miles, Kilometers, and
		perhaps Nautical Miles"): three bars in the plot's lower right, each a
		round length (1, 2 or 5 times a power of ten) as long as fits, measured
		across the map at the view's center latitude, labeled in words.

		MEASURING (Larry, 2026-10-31): `start_measuring', then each click on
		the map (a press and release that did not pan) places the next point,
		point to point to point; `undo_point' takes the last back;
		`end_measuring' keeps the path shown; `close_shape' (or a click on the
		first point once there are three) joins it into a shape with a
		perimeter and an area; `delete_measure' removes it entirely. The
		readout, on a plate in the plot's upper right, is in miles,
		kilometers and nautical miles, and square miles, square kilometers
		and square nautical miles. Distances are great-circle (haversine);
		areas are spherical (the polygon formula GIS uses, exact for a box of
		latitude and longitude).

		AN AREA FOR EVERY SHAPE: an empire's hover card gives its area in all
		three units (every outline the polity has in the year shown); a press
		on it selects it, outlines it and shows the same on the plate.

		A TRUE ASPECT: SW_MAP shows 360 by 180 degrees over any plot, which
		stretched a tall dock panel; here a degree of latitude takes 1 / cos
		of `standard_parallel' the pixels of a degree of longitude, whatever
		the panel's shape.
	]"

class
	SW_ATLAS

inherit
	SW_MAP
		redefine
			make, span_lat, handle_click, handle_release, handle_double_click, dwell_ms, hover_card_at,
			route_shown, draw_under_routes, draw_over_places, land_color
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			Precursor
			create areas.make (64)
			create area_order.make (64)
			create sites.make (32)
			create site_candidates.make (32)
			create candidates.make (32)
			create marked.make (4)
			create route_spans.make (4)
			create ring_buffer.make_filled (0.0, 1, 64)
			create era.make
			create last_card_kind.make_empty
			create name_widths.make (64)
			create scale_labels.make (3)
			create measure_points.make (8)
			create measure_actions.make (2)
			create readout_lines.make (8)
			set_standard_parallel (32.0)
			shows_scale := True
		end

feature -- The year shown

	year: INTEGER
			-- The year shown (astronomical, as SW_ERA_YEARS counts), when `has_year'.

	has_year: BOOLEAN
			-- Is a year chosen? Without one no area is drawn, and every site and route is.

	set_year (a_year: INTEGER)
		do
			year := a_year
			has_year := True
		ensure
			set: has_year and year = a_year
		end

	clear_year
		do
			has_year := False
		ensure
			cleared: not has_year
		end

	holds_year (a_from, a_to: INTEGER): BOOLEAN
			-- Is something that holds `a_from' .. `a_to' shown now?
		do
			Result := not has_year or else (year >= a_from and year <= a_to)
		end

	era: SW_ERA_YEARS
			-- How years read on the cards.

feature -- Aspect

	standard_parallel: REAL_64
			-- The latitude where the scale is true (32 degrees north, the Levant, by default).

	set_standard_parallel (a_lat: REAL_64)
		require
			not_polar: a_lat > -80.0 and a_lat < 80.0
		do
			standard_parallel := a_lat
			cos_parallel := math.cosine (a_lat * Degree)
		ensure
			set: standard_parallel = a_lat
		end

	cos_parallel: REAL_64
			-- The cosine of `standard_parallel', worked out once.

	span_lat: REAL_64
			-- Degrees of latitude the window shows, from its shape, so the map keeps its true
			-- aspect at `standard_parallel'.
		do
			if plot_w > 0.0 and plot_h > 0.0 then
				Result := span_lon * plot_h / plot_w * cos_parallel
			else
				Result := Precursor
			end
		end

feature -- Scale

	shows_scale: BOOLEAN
			-- Is the scale drawn?

	set_shows_scale (a_on: BOOLEAN)
		do
			shows_scale := a_on
		ensure
			set: shows_scale = a_on
		end

	Mile: REAL_64 = 1609.344
			-- A US (statute) mile in meters.

	Kilometer: REAL_64 = 1000.0

	Nautical_mile: REAL_64 = 1852.0

	Scale_max_px: REAL_64 = 140.0
			-- The longest a scale bar may be.

	meters_per_pixel: REAL_64
			-- Meters a pixel spans across the map at the view's center latitude.
		do
			Result := span_lon * Meters_per_degree * math.cosine (view_cy * Degree) / plot_w.max (1.0)
		ensure
			positive: Result > 0.0
		end

	scale_value (a_unit: REAL_64): REAL_64
			-- The round length, in units of `a_unit' meters (1, 2 or 5 times a power of ten), whose
			-- bar is the longest within `Scale_max_px'.
		require
			positive: a_unit > 0.0
		local
			l_most, l_power: REAL_64
		do
			l_most := Scale_max_px * meters_per_pixel / a_unit
			l_power := 10.0 ^ math.log10 (l_most).floor
			if 5.0 * l_power <= l_most then
				Result := 5.0 * l_power
			elseif 2.0 * l_power <= l_most then
				Result := 2.0 * l_power
			else
				Result := l_power
			end
		ensure
			fits: Result * a_unit / meters_per_pixel <= Scale_max_px * 1.000001
			not_short: Result * a_unit / meters_per_pixel >= Scale_max_px / 5.000001
		end

	scale_length (a_unit: REAL_64): REAL_64
			-- The bar of `scale_value (a_unit)', in pixels.
		require
			positive: a_unit > 0.0
		do
			Result := scale_value (a_unit) * a_unit / meters_per_pixel
		end

	grouped (a_number: INTEGER_64): STRING_32
			-- `a_number' with a comma every three digits from four on ("9,400"; SW_ERA_YEARS leaves
			-- four-digit numbers whole, as years read).
		local
			l_digits: STRING_32
			i: INTEGER
		do
			l_digits := a_number.abs.out.to_string_32
			create Result.make (l_digits.count + l_digits.count // 3 + 1)
			from i := 1 until i > l_digits.count loop
				if i > 1 and (l_digits.count - i + 1) \\ 3 = 0 then
					Result.append_character (',')
				end
				Result.append_character (l_digits [i])
				i := i + 1
			end
			if a_number < 0 then
				Result.prepend_character ('-')
			end
		end

	scale_text (a_value: REAL_64; a_unit: REAL_64): STRING_32
			-- "50 miles", "1 kilometer", "0.5 nautical miles": spelled out (no abbreviations).
		do
			if a_value >= 1.0 then
				Result := grouped (a_value.rounded)
			else
				create Result.make_from_string_general (a_value.out)
			end
			Result.append_character (' ')
			if a_unit = Mile then
				Result.append (if a_value = 1.0 then {STRING_32} "mile" else {STRING_32} "miles" end)
			elseif a_unit = Nautical_mile then
				Result.append (if a_value = 1.0 then {STRING_32} "nautical mile" else {STRING_32} "nautical miles" end)
			else
				Result.append (if a_value = 1.0 then {STRING_32} "kilometer" else {STRING_32} "kilometers" end)
			end
		end

	scale_labels: ARRAYED_LIST [STRING_32]
			-- The scale's labels as the last frame drew them.

feature -- Measuring on the sphere

	Earth_radius_m: REAL_64 = 6371008.8
			-- The mean radius of the earth.

	Square_mile: REAL_64 = 2589988.110336
	Square_kilometer: REAL_64 = 1000000.0
	Square_nautical_mile: REAL_64 = 3429904.0

	distance_m (a_lon1, a_lat1, a_lon2, a_lat2: REAL_64): REAL_64
			-- The great-circle distance between two points (haversine).
		local
			l_a: REAL_64
		do
			l_a := math.sine ((a_lat2 - a_lat1) * Degree / 2.0) ^ 2
				+ math.cosine (a_lat1 * Degree) * math.cosine (a_lat2 * Degree) * math.sine ((a_lon2 - a_lon1) * Degree / 2.0) ^ 2
			Result := 2.0 * Earth_radius_m * math.arc_sine (l_a.min (1.0).max (0.0) ^ 0.5)
		ensure
			non_negative: Result >= 0.0
		end

	ring_area_m2 (a_ring: ARRAY [REAL_64]): REAL_64
			-- The area inside a flat [lon1, lat1, ...] ring on the sphere: half the radius squared
			-- times the sum over its edges of the change in longitude times (2 + the sines of the
			-- two latitudes), in radians.
		require
			pairs: a_ring.count \\ 2 = 0
		local
			i, j, n: INTEGER
			l_sum: REAL_64
		do
			n := a_ring.count // 2
			if n >= 3 then
				from i := 0 until i >= n loop
					j := (i + 1) \\ n
					l_sum := l_sum + (a_ring [a_ring.lower + 2 * j] - a_ring [a_ring.lower + 2 * i]) * Degree
						* (2.0 + math.sine (a_ring [a_ring.lower + 2 * i + 1] * Degree) + math.sine (a_ring [a_ring.lower + 2 * j + 1] * Degree))
					i := i + 1
				end
				Result := (l_sum * Earth_radius_m * Earth_radius_m / 2.0).abs
			end
		ensure
			non_negative: Result >= 0.0
		end

	polity_area_m2 (a_area: INTEGER): REAL_64
			-- The area of every outline of `a_area''s polity that holds the year shown (or, with no
			-- year, the outlines of the same name and years).
		require
			known: a_area >= 1 and a_area <= areas.count
		local
			a: like areas.item
		do
			a := areas.i_th (a_area)
			across areas as ic loop
				if ic.name.same_string (a.name) and then (if has_year then year >= ic.year_from and year <= ic.year_to else ic.year_from = a.year_from and ic.year_to = a.year_to end) then
					Result := Result + ring_area_m2 (ic.ring)
				end
			end
		end

	area_lines (a_area: INTEGER): ARRAYED_LIST [STRING_32]
			-- The polity's area in the three units, a line each.
		require
			known: a_area >= 1 and a_area <= areas.count
		do
			Result := square_lines (polity_area_m2 (a_area))
		end

	length_lines (a_meters: REAL_64): ARRAYED_LIST [STRING_32]
			-- "12.3 miles", "19.8 kilometers", "10.7 nautical miles".
		do
			create Result.make (3)
			Result.extend (amount_text (a_meters / Mile) + (if (a_meters / Mile - 1.0).abs < 0.0005 then {STRING_32} " mile" else {STRING_32} " miles" end))
			Result.extend (amount_text (a_meters / Kilometer) + (if (a_meters / Kilometer - 1.0).abs < 0.0005 then {STRING_32} " kilometer" else {STRING_32} " kilometers" end))
			Result.extend (amount_text (a_meters / Nautical_mile) + (if (a_meters / Nautical_mile - 1.0).abs < 0.0005 then {STRING_32} " nautical mile" else {STRING_32} " nautical miles" end))
		end

	square_lines (a_square_meters: REAL_64): ARRAYED_LIST [STRING_32]
			-- "3,630 square miles", "9,400 square kilometers", "2,740 square nautical miles".
		do
			create Result.make (3)
			Result.extend (amount_text (a_square_meters / Square_mile) + {STRING_32} " square miles")
			Result.extend (amount_text (a_square_meters / Square_kilometer) + {STRING_32} " square kilometers")
			Result.extend (amount_text (a_square_meters / Square_nautical_mile) + {STRING_32} " square nautical miles")
		end

	amount_text (a_value: REAL_64): STRING_32
			-- `a_value' to three significant figures, with thousands separators: "9,400", "45.6",
			-- "4.56", "0.456".
		local
			l_digits, l_int: INTEGER
			l_scaled: INTEGER_64
			l_frac: STRING_32
		do
			if a_value <= 0.0 then
				Result := {STRING_32} "0"
			elseif a_value >= 100.0 then
				l_digits := math.log10 (a_value).floor - 2
				Result := grouped (((a_value / (10.0 ^ l_digits)).rounded * (10.0 ^ l_digits)).rounded_real_64.truncated_to_integer_64)
			else
					-- decimals so three figures show: 2 below 10, 1 below 100, more below 1
				l_digits := (2 - math.log10 (a_value).floor).max (1).min (6)
				l_scaled := (a_value * (10.0 ^ l_digits)).rounded_real_64.truncated_to_integer_64
				l_int := (l_scaled // (10 ^ l_digits).truncated_to_integer_64).to_integer_32
				create l_frac.make_filled ('0', l_digits)
				l_frac.append ((l_scaled \\ (10 ^ l_digits).truncated_to_integer_64).out)
				Result := l_int.out.to_string_32 + {STRING_32} "." + l_frac.substring (l_frac.count - l_digits + 1, l_frac.count)
			end
		end

feature -- The measuring tool

	Measure_idle: INTEGER = 0
	Measure_running: INTEGER = 1
	Measure_ended: INTEGER = 2

	measure_state: INTEGER
			-- Idle (nothing measured), running (clicks place points) or ended (the result shown).

	is_measuring: BOOLEAN
			-- Do clicks place points?
		do
			Result := measure_state = Measure_running
		end

	measure_points: ARRAYED_LIST [TUPLE [lon, lat: REAL_64]]
			-- The points placed, in order.

	is_measure_closed: BOOLEAN
			-- Was the path joined into a shape?

	measure_actions: ARRAYED_LIST [PROCEDURE]
			-- Agents called after every change to the measurement: started, a point placed or taken
			-- back, ended, closed, deleted. The state pushes to its listeners (Larry, 2026-10-31:
			-- state machines through agent collections), so a button that follows it needs no
			-- walk of the widget tree to hear.

	on_measure_change (a_action: PROCEDURE)
			-- Call `a_action' after every change to the measurement.
		do
			measure_actions.extend (a_action)
		ensure
			kept: measure_actions.has (a_action)
		end

	start_measuring
			-- A new measurement: the old one removed, clicks place points.
		do
			measure_points.wipe_out
			is_measure_closed := False
			measure_state := Measure_running
			selected_area := 0
			tell_measure_change
		ensure
			running: is_measuring and measure_points.is_empty and not is_measure_closed
		end

	place_point (a_lon, a_lat: REAL_64)
			-- The next point; a click on the first point once there are three closes the shape; a
			-- click on the last point again (a double-click's second press) adds nothing.
		require
			running: is_measuring
		do
			if measure_points.count >= 3 and then near_point (measure_points.first, a_lon, a_lat) then
				close_shape
			elseif measure_points.is_empty or else not near_point (measure_points.last, a_lon, a_lat) then
				measure_points.extend ([a_lon, a_lat])
				tell_measure_change
			end
		end

	undo_point
			-- The last point taken back.
		require
			running: is_measuring
			a_point: not measure_points.is_empty
		do
			measure_points.finish
			measure_points.remove
			tell_measure_change
		ensure
			one_less: measure_points.count = old measure_points.count - 1
		end

	can_close: BOOLEAN
			-- Can the path be joined into a shape?
		do
			Result := is_measuring and measure_points.count >= 3
		end

	end_measuring
			-- The path kept shown, clicks no longer placing points.
		require
			running: is_measuring
		do
			measure_state := Measure_ended
			tell_measure_change
		ensure
			ended: measure_state = Measure_ended
		end

	close_shape
			-- The last point joined to the first: a shape with a perimeter and an area.
		require
			closable: can_close
		do
			is_measure_closed := True
			measure_state := Measure_ended
			tell_measure_change
		ensure
			closed: is_measure_closed and measure_state = Measure_ended
		end

	delete_measure
			-- The measurement removed entirely.
		do
			measure_points.wipe_out
			is_measure_closed := False
			measure_state := Measure_idle
			tell_measure_change
		ensure
			idle: measure_state = Measure_idle and measure_points.is_empty
		end

	measured_length_m: REAL_64
			-- The path's length, with the closing edge when it is a shape.
		local
			i: INTEGER
		do
			from i := 2 until i > measure_points.count loop
				Result := Result + distance_m (measure_points [i - 1].lon, measure_points [i - 1].lat, measure_points [i].lon, measure_points [i].lat)
				i := i + 1
			end
			if is_measure_closed and measure_points.count >= 3 then
				Result := Result + distance_m (measure_points.last.lon, measure_points.last.lat, measure_points.first.lon, measure_points.first.lat)
			end
		end

	measured_area_m2: REAL_64
			-- The shape's area; 0 for an open path.
		local
			l_ring: ARRAY [REAL_64]
			i: INTEGER
		do
			if is_measure_closed and measure_points.count >= 3 then
				create l_ring.make_filled (0.0, 1, 2 * measure_points.count)
				from i := 1 until i > measure_points.count loop
					l_ring [2 * i - 1] := measure_points [i].lon
					l_ring [2 * i] := measure_points [i].lat
					i := i + 1
				end
				Result := ring_area_m2 (l_ring)
			end
		end

	readout_lines: ARRAYED_LIST [STRING_32]
			-- The plate's lines as the last frame drew them (the measurement, else the area chosen).

	selected_area: INTEGER
			-- The area last pressed on; 0 for none.

feature -- Areas

	areas: ARRAYED_LIST [TUPLE [name: STRING_32; ring: ARRAY [REAL_64]; year_from, year_to, hue: INTEGER; west, south, east, north: REAL_64; line: STRING_32]]
			-- Each area: its name, a flat [lon1, lat1, ...] ring, the years it holds, its hue,
			-- its bounding box and its card's second line.

	area_order: ARRAYED_LIST [INTEGER]
			-- Area indexes, largest bounding box first.

	add_area (a_name: READABLE_STRING_GENERAL; a_ring: ARRAY [REAL_64]; a_from, a_to, a_hue: INTEGER; a_line: READABLE_STRING_GENERAL): INTEGER
			-- An area holding `a_from' .. `a_to', filled in hue `a_hue'; `a_line' its card's
			-- second line (a dynasty, a source). Its index.
		require
			three_points: a_ring.count >= 6
			pairs: a_ring.count \\ 2 = 0
			ordered: a_from <= a_to
			known_hue: a_hue >= 1 and a_hue <= Hue_count
		local
			w, s, e, n, l_size: REAL_64
			i, lo, hi, mid: INTEGER
		do
			w := 180.0
			e := -180.0
			s := 90.0
			n := -90.0
			from i := a_ring.lower until i > a_ring.upper loop
				w := w.min (a_ring [i])
				e := e.max (a_ring [i])
				s := s.min (a_ring [i + 1])
				n := n.max (a_ring [i + 1])
				i := i + 2
			end
			areas.extend ([create {STRING_32}.make_from_string_general (a_name), a_ring.twin, a_from, a_to, a_hue, w, s, e, n,
				create {STRING_32}.make_from_string_general (a_line)])
			Result := areas.count
			name_widths.extend (0.0)
			if ring_buffer.count < a_ring.count then
				create ring_buffer.make_filled (0.0, 1, a_ring.count)
			end
				-- largest first: binary insertion by bounding-box size, equal sizes in the order added
			l_size := area_size (Result)
			from
				lo := 1
				hi := area_order.count + 1
			until
				lo >= hi
			loop
				mid := (lo + hi) // 2
				if area_size (area_order.i_th (mid)) >= l_size then
					lo := mid + 1
				else
					hi := mid
				end
			end
			if lo > area_order.count then
				area_order.extend (Result)
			else
				area_order.go_i_th (lo)
				area_order.put_left (Result)
			end
		ensure
			added: areas.count = old areas.count + 1 and Result = areas.count
			ordered: area_order.count = areas.count
		end

	area_size (a_area: INTEGER): REAL_64
			-- The area's bounding box in square degrees.
		require
			known: a_area >= 1 and a_area <= areas.count
		do
			Result := (areas.i_th (a_area).east - areas.i_th (a_area).west) * (areas.i_th (a_area).north - areas.i_th (a_area).south)
		end

	area_shown (a_area: INTEGER): BOOLEAN
			-- Is the area drawn at this year and view?
		require
			known: a_area >= 1 and a_area <= areas.count
		local
			a: like areas.item
		do
			a := areas.i_th (a_area)
			Result := has_year and then year >= a.year_from and then year <= a.year_to
				and then a.east >= view_cx - span_lon / 2.0 and then a.west <= view_cx + span_lon / 2.0
				and then a.north >= view_cy - span_lat / 2.0 and then a.south <= view_cy + span_lat / 2.0
		end

	area_at (a_px, a_py: REAL_64): INTEGER
			-- The smallest area shown that holds the surface point; 0 for none.
		local
			i: INTEGER
			l_lon, l_lat: REAL_64
			a: like areas.item
		do
			l_lon := lon_at_x (a_px)
			l_lat := lat_at_y (a_py)
			from i := area_order.count until i < 1 or Result > 0 loop
				a := areas.i_th (area_order.i_th (i))
				if area_shown (area_order.i_th (i)) and then l_lon >= a.west and then l_lon <= a.east
					and then l_lat >= a.south and then l_lat <= a.north and then holds (a.ring, l_lon, l_lat)
				then
					Result := area_order.i_th (i)
				end
				i := i - 1
			end
		ensure
			in_range: Result >= 0 and Result <= areas.count
		end

	areas_drawn: INTEGER
			-- How many areas the last frame filled.

	Hue_count: INTEGER = 8

	hue_color (a_hue: INTEGER): NATURAL_32
			-- Earth hues, none near the water's blue (spike S3).
		require
			known: a_hue >= 1 and a_hue <= Hue_count
		do
			inspect a_hue
			when 1 then
				Result := 0xC8892B -- amber
			when 2 then
				Result := 0xB5523B -- terracotta
			when 3 then
				Result := 0x7E8F3A -- olive
			when 4 then
				Result := 0x8E4C8A -- plum
			when 5 then
				Result := 0xA07A2C -- ochre
			when 6 then
				Result := 0xC0566E -- rose
			when 7 then
				Result := 0x5E7F43 -- moss
			else
				Result := 0x8A6239 -- umber
			end
		end

	area_fill_alpha (a_theme: SW_THEME): REAL_64
			-- How strongly an area tints what is under it: more on a dark surface, where a
			-- light tint left the dark water's color nearly unchanged (4A4A45 over 26384D).
		do
			if a_theme.is_dark then
				Result := 0.4
			else
				Result := 0.22
			end
		end

	land_color (a_theme: SW_THEME): NATURAL_32
			-- The land a step from the panel's surface toward the ink: SW_MAP's land is the surface
			-- itself, so in a dock panel the desert and the panel read as one (2026-10-31).
		do
			Result := a_theme.mixed (a_theme.surface, a_theme.ink, 0.08)
		end

feature -- Sites

	sites: ARRAYED_LIST [TUPLE [key, name: STRING_32; min_zoom: REAL_64; year_from, year_to: INTEGER; line: STRING_32]]
			-- Each site: the caller's key, its name, the zoom its label shows from, the years it
			-- holds and its card's line.

	candidates: ARRAYED_LIST [TUPLE [site: INTEGER; lon, lat, radius_m: REAL_64; holder: STRING_32; is_lean: BOOLEAN]]
			-- Every candidate location of every site: where, how wide its doubt, who holds it,
			-- and whether it is the view shown first.

	site_candidates: ARRAYED_LIST [ARRAYED_LIST [INTEGER]]
			-- Per site: its candidates' indexes.

	add_site (a_key, a_name: READABLE_STRING_GENERAL; a_min_zoom: REAL_64; a_from, a_to: INTEGER; a_line: READABLE_STRING_GENERAL): INTEGER
			-- A site holding `a_from' .. `a_to' (`Always_from' .. `Always_to' for all time); its
			-- candidates come with `add_candidate'. Its index.
		require
			zoom_sane: a_min_zoom >= 1.0
			ordered: a_from <= a_to
		do
			sites.extend ([create {STRING_32}.make_from_string_general (a_key), create {STRING_32}.make_from_string_general (a_name),
				a_min_zoom, a_from, a_to, create {STRING_32}.make_from_string_general (a_line)])
			site_candidates.extend (create {ARRAYED_LIST [INTEGER]}.make (1))
			Result := sites.count
		ensure
			added: sites.count = old sites.count + 1 and Result = sites.count
		end

	Always_from: INTEGER = -1_000_000
	Always_to: INTEGER = 1_000_000

	add_candidate (a_site: INTEGER; a_lon, a_lat, a_radius_m: REAL_64; a_holder: READABLE_STRING_GENERAL; a_lean: BOOLEAN)
			-- A place the site may have been, `a_radius_m' the width of the doubt, `a_holder' who
			-- holds it ("" when undisputed).
		require
			known_site: a_site >= 1 and a_site <= sites.count
			on_the_planet: a_lat >= -90.0 and a_lat <= 90.0 and a_lon >= -180.0 and a_lon <= 180.0
			radius_sane: a_radius_m >= 0.0
		do
			candidates.extend ([a_site, a_lon, a_lat, a_radius_m, create {STRING_32}.make_from_string_general (a_holder), a_lean])
			site_candidates.i_th (a_site).extend (candidates.count)
		ensure
			added: candidates.count = old candidates.count + 1
		end

	site_index (a_key: READABLE_STRING_GENERAL): INTEGER
			-- The site with `a_key'; 0 for none.
		local
			i: INTEGER
		do
			from i := 1 until i > sites.count or Result > 0 loop
				if sites.i_th (i).key.same_string_general (a_key) then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= sites.count
		end

	is_disputed (a_site: INTEGER): BOOLEAN
			-- Has the site more than one candidate?
		require
			known_site: a_site >= 1 and a_site <= sites.count
		do
			Result := site_candidates.i_th (a_site).count > 1
		end

	site_shown (a_site: INTEGER): BOOLEAN
			-- Is the site drawn at this year?
		require
			known_site: a_site >= 1 and a_site <= sites.count
		do
			Result := holds_year (sites.i_th (a_site).year_from, sites.i_th (a_site).year_to)
		end

	site_at (a_px, a_py: REAL_64): INTEGER
			-- The site shown with a candidate nearest the surface point, within 10 pixels; 0 for none.
		local
			i: INTEGER
			l_best, l_d: REAL_64
			c: like candidates.item
		do
			l_best := Reach
			from i := 1 until i > candidates.count loop
				c := candidates.i_th (i)
				if site_shown (c.site) then
					l_d := ((x_of_lon (c.lon) - a_px) ^ 2 + (y_of_lat (c.lat) - a_py) ^ 2) ^ 0.5
					if l_d <= l_best then
						l_best := l_d
						Result := c.site
					end
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= sites.count
		end

	Reach: REAL_64 = 10.0
			-- How near a press or a hover must come to a site, in pixels.

	clear_sites
			-- No sites, no marks, nothing selected.
		do
			sites.wipe_out
			site_candidates.wipe_out
			candidates.wipe_out
			marked.wipe_out
			selected_site := 0
		ensure
			none: sites.is_empty and candidates.is_empty and marked.is_empty
		end

feature -- Marks and selection

	marked: ARRAYED_LIST [INTEGER]
			-- The sites the caller has marked (an event's places).

	set_marked (a_sites: ITERABLE [INTEGER])
			-- Mark exactly `a_sites'.
		do
			marked.wipe_out
			across a_sites as ic loop
				if ic >= 1 and ic <= sites.count and then not marked.has (ic) then
					marked.extend (ic)
				end
			end
		end

	is_marked (a_site: INTEGER): BOOLEAN
		do
			Result := marked.has (a_site)
		end

	fit_marked (a_max_zoom: REAL_64)
			-- Center the view on the marked sites' candidates with room around them, no closer
			-- than `a_max_zoom'; with nothing marked, the view stays.
		require
			zoom_sane: a_max_zoom >= 1.0
		local
			w, s, e, n, l_aspect, l_lon_span: REAL_64
			l_any: BOOLEAN
		do
			w := 180.0
			e := -180.0
			s := 90.0
			n := -90.0
			across marked as ic_site loop
				across site_candidates.i_th (ic_site) as ic_c loop
					l_any := True
					w := w.min (candidates.i_th (ic_c).lon)
					e := e.max (candidates.i_th (ic_c).lon)
					s := s.min (candidates.i_th (ic_c).lat)
					n := n.max (candidates.i_th (ic_c).lat)
				end
			end
			if l_any then
				if plot_w > 0.0 and plot_h > 0.0 then
					l_aspect := plot_w / plot_h / cos_parallel
				else
					l_aspect := 1.0
				end
					-- the longitude span that holds both the width and the height, with room around
				l_lon_span := ((e - w) * 1.6).max ((n - s) * 1.6 * l_aspect).max (360.0 / a_max_zoom)
				set_view (360.0 / l_lon_span, (w + e) / 2.0, (s + n) / 2.0)
			end
		end

	selected_site: INTEGER
			-- The site last pressed or selected; 0 for none.

	on_site_select: detachable PROCEDURE [INTEGER]
			-- Called with the site a press lands on.

	set_on_site_select (a_action: PROCEDURE [INTEGER])
		do
			on_site_select := a_action
		ensure
			set: on_site_select = a_action
		end

	select_site (a_site: INTEGER)
			-- Select `a_site' (0 for none) without calling `on_site_select'.
		require
			in_range: a_site >= 0 and a_site <= sites.count
		do
			selected_site := a_site
		ensure
			set: selected_site = a_site
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- While measuring, a press grabs the ground and its release places a point (unless the
			-- pointer moved: that was a pan). Otherwise a press on a site selects it; on an area,
			-- selects the area; anywhere, grabs the ground for panning.
		local
			l_site: INTEGER
		do
			press_px := a_px
			press_py := a_py
			is_press_pending := True
			if is_measuring then
				begin_pan (a_px, a_py)
				Result := True
			else
				l_site := site_at (a_px, a_py)
				if l_site > 0 then
					begin_pan (a_px, a_py)
					selected_site := l_site
					if attached on_site_select as al_select then
						al_select.call (l_site)
					end
					Result := True
				else
					selected_area := area_at (a_px, a_py)
					Result := Precursor (a_px, a_py)
				end
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- A still press while measuring places the next point where it landed.
		do
			if is_measuring and is_press_pending and then ((a_x - press_px) ^ 2 + (a_y - press_py) ^ 2) ^ 0.5 < 4.0 then
				place_point (lon_at_x (press_px), lat_at_y (press_py))
			end
			is_press_pending := False
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- While measuring, a double-click ends the path; otherwise the whole world (SW_MAP).
		do
			if is_measuring then
				end_measuring
				Result := True
			else
				Result := Precursor (a_px, a_py)
			end
		end

feature -- Routes in time

	route_spans: ARRAYED_LIST [TUPLE [route, year_from, year_to: INTEGER]]
			-- The years each timed route holds.

	add_timed_route (a_name: READABLE_STRING_GENERAL; a_lon_lat: ARRAY [REAL_64]; a_certain: BOOLEAN; a_from, a_to: INTEGER)
			-- A route drawn only when the year shown falls in `a_from' .. `a_to'.
		require
			two_points_at_least: a_lon_lat.count >= 4
			pairs: a_lon_lat.count \\ 2 = 0
			ordered: a_from <= a_to
		do
			add_route (a_name, a_lon_lat, a_certain)
			route_spans.extend ([routes.count, a_from, a_to])
		ensure
			added: routes.count = old routes.count + 1
		end

	route_shown (a_route: INTEGER): BOOLEAN
			-- Untimed routes always; timed ones by the year.
		do
			Result := True
			across route_spans as ic loop
				if ic.route = a_route then
					Result := holds_year (ic.year_from, ic.year_to)
				end
			end
		end

feature -- Hover cards

	dwell_ms: INTEGER
		do
			Result := 400
		end

	last_card_kind: STRING_32
			-- "site", "route" or "area": what the last card was for.

	hover_card_at (a_px, a_py: REAL_64): detachable SW_HOVER_CARD
			-- The nearest site within reach, else a route within 6 pixels, else the smallest
			-- area holding the point.
		local
			l_site, l_area, l_route, i, k: INTEGER
			l_lines: ARRAYED_LIST [STRING_32]
			c: like candidates.item
			rt: like routes.item
		do
			create l_lines.make (4)
			l_site := site_at (a_px, a_py)
			if l_site > 0 then
				if not sites.i_th (l_site).line.is_empty then
					l_lines.extend (sites.i_th (l_site).line)
				end
				if is_disputed (l_site) then
					l_lines.extend ({STRING_32} "Where it was is disputed:")
					across site_candidates.i_th (l_site) as ic loop
						c := candidates.i_th (ic)
						l_lines.extend ({STRING_32} "  " + (if c.holder.is_empty then {STRING_32} "a candidate" else c.holder end)
							+ (if c.is_lean then {STRING_32} " (shown first)" else {STRING_32} "" end))
					end
				elseif not site_candidates.i_th (l_site).is_empty and then not candidates.i_th (site_candidates.i_th (l_site).first).holder.is_empty then
					l_lines.extend (candidates.i_th (site_candidates.i_th (l_site).first).holder)
				end
				Result := card (sites.i_th (l_site).name, l_lines)
				Result.set_anchor (a_px - 6.0, a_py - 6.0, 12.0, 12.0)
				last_card_kind := "site"
			else
				from i := 1 until i > routes.count loop
					rt := routes.i_th (i)
					if route_shown (i) then
						from k := rt.points.lower until k + 3 > rt.points.upper loop
							if segment_distance (a_px, a_py, x_of_lon (rt.points [k]), y_of_lat (rt.points [k + 1]),
								x_of_lon (rt.points [k + 2]), y_of_lat (rt.points [k + 3])) <= 6.0
							then
								l_route := i
							end
							k := k + 2
						end
					end
					i := i + 1
				end
				if l_route > 0 then
					l_lines.extend (if routes.i_th (l_route).is_certain then {STRING_32} "A route" else {STRING_32} "A route whose course is debated" end)
					Result := card (routes.i_th (l_route).name, l_lines)
					Result.set_anchor (a_px - 6.0, a_py - 6.0, 12.0, 12.0)
					last_card_kind := "route"
				else
					l_area := area_at (a_px, a_py)
					if l_area > 0 then
						l_lines.extend (era.range_label (areas.i_th (l_area).year_from, areas.i_th (l_area).year_to))
						if not areas.i_th (l_area).line.is_empty then
							l_lines.extend (areas.i_th (l_area).line)
						end
						l_lines.extend ((if has_year then {STRING_32} "Its area in " + era.label (year) else {STRING_32} "Its area" end) + {STRING_32} ", about:")
						across area_lines (l_area) as ic_line loop
							l_lines.extend ({STRING_32} "  " + ic_line)
						end
						Result := card (areas.i_th (l_area).name, l_lines)
						Result.set_anchor (a_px - 6.0, a_py - 6.0, 12.0, 12.0)
						last_card_kind := "area"
					end
				end
			end
		end

feature {NONE} -- Drawing

	draw_under_routes (a_p: SW_PAINTER)
			-- The areas holding the year in view, largest first: a translucent fill in each
			-- one's hue and an outline in it.
		local
			k, n: INTEGER
			a: like areas.item
			sx, ox, sy, oy: REAL_64
		do
			areas_drawn := 0
				-- the projection as one scale and offset per axis, worked out once a frame
				-- (x_of_lon per point cost 18,000 contract-checked calls at 3,000 areas)
			sx := plot_w / span_lon
			ox := x_of_lon (0.0)
			sy := - plot_h / span_lat
			oy := y_of_lat (0.0)
			across area_order as ic loop
				if area_shown (ic) then
					a := areas.i_th (ic)
					n := a.ring.count // 2
					from k := 0 until k >= n loop
						ring_buffer [2 * k + 1] := ox + sx * a.ring [a.ring.lower + 2 * k]
						ring_buffer [2 * k + 2] := oy + sy * a.ring [a.ring.lower + 2 * k + 1]
						k := k + 1
					end
					a_p.set_color_alpha (hue_color (a.hue), area_fill_alpha (a_p.theme))
					a_p.polygon_fill_flat (ring_buffer, n)
					a_p.set_color_alpha (hue_color (a.hue), 0.8)
					a_p.polygon_stroke_flat (ring_buffer, n, 1.2)
					areas_drawn := areas_drawn + 1
				end
			end
		end

	draw_over_places (a_p: SW_PAINTER)
			-- The marked sites first (their labels win), then the rest, then the area names
			-- where there is room.
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			draw_sites (a_p, True)
			draw_sites (a_p, False)
			draw_area_names (a_p)
			draw_selected_area (a_p)
			draw_measure (a_p)
			draw_readout (a_p)
			if shows_scale then
				draw_scale (a_p)
			end
		end

	draw_selected_area (a_p: SW_PAINTER)
			-- The chosen polity's outlines in the year, drawn heavy in the ink.
		local
			k, n: INTEGER
			a: like areas.item
		do
			if selected_area > 0 and selected_area <= areas.count then
				a_p.set_color (a_p.theme.ink)
				across areas as ic loop
					if ic.name.same_string (areas.i_th (selected_area).name) and then has_year and then year >= ic.year_from and then year <= ic.year_to then
						a := ic
						n := a.ring.count // 2
						from k := 0 until k >= n loop
							ring_buffer [2 * k + 1] := x_of_lon (a.ring [a.ring.lower + 2 * k])
							ring_buffer [2 * k + 2] := y_of_lat (a.ring [a.ring.lower + 2 * k + 1])
							k := k + 1
						end
						a_p.polygon_stroke_flat (ring_buffer, n, 2.5)
					end
				end
			end
		end

	draw_measure (a_p: SW_PAINTER)
			-- The path through the points (closed and tinted when a shape), each point a dot; while
			-- running with three points or more, the first point ringed: a click there closes it.
		local
			t: SW_THEME
			l_pts: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			l_flat: ARRAY [REAL_64]
			i: INTEGER
		do
			t := a_p.theme
			if not measure_points.is_empty then
				create l_pts.make (measure_points.count + 1)
				create l_flat.make_filled (0.0, 1, 2 * measure_points.count)
				from i := 1 until i > measure_points.count loop
					l_pts.extend ([x_of_lon (measure_points [i].lon), y_of_lat (measure_points [i].lat)])
					l_flat [2 * i - 1] := l_pts.last.px
					l_flat [2 * i] := l_pts.last.py
					i := i + 1
				end
				if is_measure_closed then
					a_p.set_color_alpha (t.accent, 0.18)
					a_p.polygon_fill_flat (l_flat, measure_points.count)
					l_pts.extend (l_pts.first)
				end
				if l_pts.count >= 2 then
					a_p.set_color (t.ink_accent)
					a_p.dashed_polyline (l_pts, 2.5, a_p.Stroke_solid)
				end
				across l_pts as ic loop
					a_p.set_color (t.ink_accent)
					a_p.circle_fill (ic.px, ic.py, 4.0)
					a_p.set_color (t.surface)
					a_p.circle_stroke (ic.px, ic.py, 4.5)
				end
				if can_close then
					a_p.set_color (t.ink_accent)
					a_p.circle_stroke (l_pts.first.px, l_pts.first.py, 8.0)
				end
			end
		end

	draw_readout (a_p: SW_PAINTER)
			-- The plate in the plot's upper right: the measurement while there is one, else the
			-- area chosen.
		local
			t: SW_THEME
			lh, lw, x0, y0, l_h: REAL_64
			i: INTEGER
		do
			t := a_p.theme
			readout_lines.wipe_out
			if measure_state /= Measure_idle then
				if is_measuring then
					readout_lines.extend ({STRING_32} "Measuring: " + measure_points.count.out + (if measure_points.count = 1 then {STRING_32} " point" else {STRING_32} " points" end))
				end
				if measure_points.count < 2 and is_measuring then
					readout_lines.extend ({STRING_32} "Click the map to place points")
				else
					readout_lines.extend (if is_measure_closed then {STRING_32} "Perimeter" else {STRING_32} "Distance" end)
					across length_lines (measured_length_m) as ic loop
						readout_lines.extend ({STRING_32} "  " + ic)
					end
					if is_measure_closed then
						readout_lines.extend ({STRING_32} "Area")
						across square_lines (measured_area_m2) as ic loop
							readout_lines.extend ({STRING_32} "  " + ic)
						end
					end
				end
			elseif selected_area > 0 and selected_area <= areas.count and then has_year
				and then year >= areas.i_th (selected_area).year_from and then year <= areas.i_th (selected_area).year_to
			then
				readout_lines.extend (areas.i_th (selected_area).name)
				readout_lines.extend ({STRING_32} "Its area in " + era.label (year) + {STRING_32} ", about:")
				across area_lines (selected_area) as ic loop
					readout_lines.extend ({STRING_32} "  " + ic)
				end
			end
			if not readout_lines.is_empty then
				lh := a_p.text_extent
				across readout_lines as ic loop
					lw := lw.max (a_p.advance (ic))
				end
				l_h := readout_lines.count * (lh + 2.0) + 12.0
				x0 := plot_x + plot_w - lw - 24.0
				y0 := plot_y + 8.0
				a_p.set_color_alpha (t.surface, 0.9)
				a_p.rrect_fill (x0, y0, lw + 16.0, l_h, t.radius)
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x0 + 0.5, y0 + 0.5, lw + 15.0, l_h - 1.0, t.radius)
				a_p.set_color (t.ink)
				from i := 1 until i > readout_lines.count loop
					a_p.text (x0 + 8.0, y0 + 6.0 + (i - 1) * (lh + 2.0) + a_p.font_ascent, readout_lines [i])
					i := i + 1
				end
			end
		end

	draw_scale (a_p: SW_PAINTER)
			-- Three bars on a plate in the plot's lower right: miles, kilometers, nautical miles.
		local
			t: SW_THEME
			l_units: ARRAY [REAL_64]
			lh, lw, l_plate_w, l_plate_h, x0, y0, l_len, ly: REAL_64
			i: INTEGER
		do
			t := a_p.theme
			l_units := <<Mile, Kilometer, Nautical_mile>>
			scale_labels.wipe_out
			across l_units as u loop
				scale_labels.extend (scale_text (scale_value (u), u))
			end
			lh := a_p.text_extent
			across scale_labels as s loop
				lw := lw.max (a_p.advance (s))
			end
			l_plate_w := 8.0 + Scale_max_px + 8.0 + lw + 8.0
			l_plate_h := 3.0 * (lh + 6.0) + 6.0
			x0 := plot_x + plot_w - l_plate_w - 8.0
			y0 := plot_y + plot_h - l_plate_h - 8.0
			a_p.set_color_alpha (t.surface, 0.85)
			a_p.rrect_fill (x0, y0, l_plate_w, l_plate_h, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x0 + 0.5, y0 + 0.5, l_plate_w - 1.0, l_plate_h - 1.0, t.radius)
			from i := 1 until i > 3 loop
				l_len := scale_length (l_units [i])
				ly := y0 + 6.0 + (i - 1) * (lh + 6.0) + lh / 2.0
				a_p.set_color (t.ink)
				a_p.fill_rect (x0 + 8.0, ly - 1.0, l_len, 2.0)
				a_p.fill_rect (x0 + 8.0, ly - 4.0, 1.5, 8.0)
				a_p.fill_rect (x0 + 8.0 + l_len - 1.5, ly - 4.0, 1.5, 8.0)
				a_p.fill_rect (x0 + 8.0 + l_len / 2.0 - 0.75, ly - 3.0, 1.5, 3.0)
				a_p.text (x0 + 8.0 + Scale_max_px + 8.0, ly - lh / 2.0 + a_p.font_ascent, scale_labels [i])
				i := i + 1
			end
		end

	draw_sites (a_p: SW_PAINTER; a_marked: BOOLEAN)
			-- The candidates of the marked sites, or of the others: a dot, dashed rings for a
			-- disputed site or a wide doubt (the lean solid), the mark in the accent, and the
			-- label from the site's zoom on (always, when marked).
		local
			t: SW_THEME
			i: INTEGER
			c: like candidates.item
			s: like sites.item
			px, py, r: REAL_64
			l_disputed: BOOLEAN
			l_text: STRING_32
		do
			t := a_p.theme
			from i := 1 until i > candidates.count loop
				c := candidates.i_th (i)
				s := sites.i_th (c.site)
				if marked.has (c.site) = a_marked and then site_shown (c.site) then
					px := x_of_lon (c.lon)
					py := y_of_lat (c.lat)
					r := c.radius_m / Meters_per_degree * plot_h / span_lat.max (0.000001)
					l_disputed := is_disputed (c.site)
					if a_marked then
						a_p.set_color_alpha (t.accent, 0.35)
						a_p.circle_fill (px, py, 9.0)
					end
					if l_disputed or r >= 8.0 then
						a_p.set_color (t.ink_accent)
						dashed_circle (a_p, px, py, r.max (6.0), c.is_lean)
					end
					a_p.set_color (t.ink)
					a_p.circle_fill (px, py, (if a_marked or c.site = selected_site then 4.0 else 3.0 end))
					if is_layer_shown (Layer_labels) and then (a_marked or effective_zoom >= s.min_zoom) then
						l_text := s.name.twin
						if l_disputed and not c.holder.is_empty then
							l_text.append ({STRING_32} ": ")
							l_text.append (c.holder)
						end
						put_label (a_p, l_text, px + 7.0, py, t.ink)
					end
				end
				i := i + 1
			end
		end

	draw_area_names (a_p: SW_PAINTER)
			-- Each area's name in the middle of the part in view, when that part is wide and tall
			-- enough and the name is not already shown.
		local
			t: SW_THEME
			a: like areas.item
			w, e, s, n, lw, lh: REAL_64
			i: INTEGER
		do
			t := a_p.theme
			lh := a_p.text_extent
			if names_size /= t.size_label then
				from i := 1 until i > name_widths.count loop
					name_widths.put_i_th (0.0, i)
					i := i + 1
				end
				names_size := t.size_label
			end
			if is_layer_shown (Layer_labels) then
				across area_order as ic loop
					if area_shown (ic) then
						a := areas.i_th (ic)
						w := x_of_lon (a.west.max (view_cx - span_lon / 2.0))
						e := x_of_lon (a.east.min (view_cx + span_lon / 2.0))
						n := y_of_lat (a.north.min (view_cy + span_lat / 2.0))
						s := y_of_lat (a.south.max (view_cy - span_lat / 2.0))
							-- too small for any name: no measuring (3,000 areas, 2026-10-31)
						if e - w >= 40.0 and then s - n >= 2.0 * lh then
							lw := name_widths.i_th (ic)
							if lw = 0.0 then
								lw := a_p.advance (a.name).max (0.001)
								name_widths.put_i_th (lw, ic)
							end
							if e - w >= lw + 16.0 and then not across drawn_labels as d some d.text.same_string (a.name) end then
								put_label (a_p, a.name, (w + e - lw) / 2.0, (n + s) / 2.0, t.mixed (hue_color (a.hue), t.ink, 0.45))
							end
						end
					end
				end
			end
		end

	name_widths: ARRAYED_LIST [REAL_64]
			-- Each area's name measured at `names_size'; 0 until measured.

	names_size: REAL_64
			-- The label size `name_widths' were measured at.

	put_label (a_p: SW_PAINTER; a_text: STRING_32; a_x, a_cy: REAL_64; a_color: NATURAL_32)
			-- `a_text' from `a_x', centered on `a_cy'; where that overlaps a label already placed
			-- this frame, mirrored to the left of the point (`a_x' is 7 pixels right of it),
			-- then a line above, then a line below; nowhere free, left out.
		local
			lw, lh, lx, ly: REAL_64
			k: INTEGER
			l_done: BOOLEAN
		do
			lw := a_p.advance (a_text)
			lh := a_p.text_extent
			from k := 1 until k > 4 or l_done loop
				inspect k
				when 1 then
					lx := a_x
					ly := a_cy - lh / 2.0
				when 2 then
					lx := a_x - 14.0 - lw
					ly := a_cy - lh / 2.0
				when 3 then
					lx := a_x
					ly := a_cy - lh * 1.5
				else
					lx := a_x
					ly := a_cy + lh / 2.0
				end
				if not across drawn_labels as d some lx < d.lx + d.lw and then lx + lw > d.lx and then ly < d.ly + d.lh and then ly + lh > d.ly end then
					drawn_labels.extend ([a_text, lx, ly, lw, lh])
					a_p.set_color (a_color)
					a_p.text (lx, ly + a_p.font_ascent, a_text)
					l_done := True
				end
				k := k + 1
			end
		end

	dashed_circle (a_p: SW_PAINTER; a_cx, a_cy, a_r: REAL_64; a_solid: BOOLEAN)
			-- A ring of radius `a_r', dashed unless `a_solid'.
		require
			positive: a_r > 0.0
		local
			l_pts: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			k: INTEGER
		do
			create l_pts.make (33)
			from k := 0 until k > 32 loop
				l_pts.extend ([a_cx + a_r * math.cosine (k * Two_pi / 32.0), a_cy + a_r * math.sine (k * Two_pi / 32.0)])
				k := k + 1
			end
			a_p.dashed_polyline (l_pts, 1.5, (if a_solid then a_p.Stroke_solid else a_p.Stroke_dashed end))
		end

feature {NONE} -- Implementation

	tell_measure_change
			-- Every agent in `measure_actions', in the order given.
		do
			across measure_actions as ic loop
				ic.call ([])
			end
		end

	press_px, press_py: REAL_64
			-- Where the last press landed.

	is_press_pending: BOOLEAN
			-- Has the last press not yet been released?

	near_point (a_point: TUPLE [lon, lat: REAL_64]; a_lon, a_lat: REAL_64): BOOLEAN
			-- Is (`a_lon', `a_lat') within `Reach' pixels of `a_point' on screen?
		do
			Result := ((x_of_lon (a_point.lon) - x_of_lon (a_lon)) ^ 2 + (y_of_lat (a_point.lat) - y_of_lat (a_lat)) ^ 2) ^ 0.5 <= Reach
		end

	ring_buffer: ARRAY [REAL_64]
			-- Screen points of the area being drawn, reused frame to frame.

	card (a_title: READABLE_STRING_GENERAL; a_lines: ARRAYED_LIST [STRING_32]): SW_HOVER_CARD
		local
			l_col: SW_COLUMN
		do
			create l_col.make
			l_col.put (create {SW_LABEL}.make_ui (a_title))
			across a_lines as ic loop
				l_col.put (create {SW_LABEL}.make_ui (ic))
			end
			create Result.make (l_col, 280.0)
		end

	segment_distance (a_px, a_py, a_ax, a_ay, a_bx, a_by: REAL_64): REAL_64
			-- The distance from the point to the segment.
		local
			dx, dy, t: REAL_64
		do
			dx := a_bx - a_ax
			dy := a_by - a_ay
			if dx * dx + dy * dy = 0.0 then
				t := 0.0
			else
				t := (((a_px - a_ax) * dx + (a_py - a_ay) * dy) / (dx * dx + dy * dy)).max (0.0).min (1.0)
			end
			Result := ((a_px - a_ax - t * dx) ^ 2 + (a_py - a_ay - t * dy) ^ 2) ^ 0.5
		end

	holds (a_ring: ARRAY [REAL_64]; a_lon, a_lat: REAL_64): BOOLEAN
			-- Is (`a_lon', `a_lat') inside the ring (even-odd rule)?
		local
			i, j, n: INTEGER
			xi, yi, xj, yj: REAL_64
		do
			n := a_ring.count // 2
			from
				i := 0
				j := n - 1
			until
				i >= n
			loop
				xi := a_ring [a_ring.lower + 2 * i]
				yi := a_ring [a_ring.lower + 2 * i + 1]
				xj := a_ring [a_ring.lower + 2 * j]
				yj := a_ring [a_ring.lower + 2 * j + 1]
				if ((yi > a_lat) /= (yj > a_lat)) and then a_lon < (xj - xi) * (a_lat - yi) / (yj - yi) + xi then
					Result := not Result
				end
				j := i
				i := i + 1
			end
		end

	math: DOUBLE_MATH
		once
			create Result
		end

	Degree: REAL_64 = 0.017453292519943295
			-- Radians in a degree.

	Two_pi: REAL_64 = 6.283185307179586

	Meters_per_degree: REAL_64 = 111_320.0
			-- Of latitude, near enough for the width of a doubt.

invariant
	order_covers_areas: area_order.count = areas.count
	one_list_per_site: site_candidates.count = sites.count

end
