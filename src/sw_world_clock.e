note
	description: "[
		Larry's idea, second half: realtime per-zone clocks. Cities
		carry MINUTE offsets (India's +5:30 and Nepal's +5:45 are
		first-class), the current moment comes from
		SIMPLE_DATE_TIME.make_now_utc (the ecosystem owns 'now'),
		times render through the theme's SW_LOCALE (12/24-hour law
		follows culture), and a +1d / -1d chip tells the truth when
		a zone lives in tomorrow or yesterday. The heartbeat's
		ambient repaint IS the tick - no timers wired. The zone
		arithmetic (zone_time, day_delta) is pure public math,
		assaulted headless. Offsets are yours to supply: DST and
		zone LAW are deliberately not computed here.
	]"

class
	SW_WORLD_CLOCK

inherit
	SW_CHART
		redefine
			draw, preferred_height
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create cities.make (6)
		end

feature -- Access

	cities: ARRAYED_LIST [TUPLE [label: STRING_32; offset_minutes: INTEGER]]

	zone_time (a_utc_minutes, a_offset_minutes: INTEGER): INTEGER
			-- Minutes-of-day in the zone, normalized 0 .. 1439.
		require
			utc_sane: a_utc_minutes >= 0 and a_utc_minutes < 1440
		local
			t: INTEGER
		do
			t := a_utc_minutes + a_offset_minutes
			from
			until
				t >= 0
			loop
				t := t + 1440
			end
			Result := t \\ 1440
		ensure
			normalized: Result >= 0 and Result < 1440
		end

	day_delta (a_utc_minutes, a_offset_minutes: INTEGER): INTEGER
			-- -1, 0 or +1: is the zone in yesterday, today or
			-- tomorrow relative to UTC?
		require
			utc_sane: a_utc_minutes >= 0 and a_utc_minutes < 1440
		local
			t: INTEGER
		do
			t := a_utc_minutes + a_offset_minutes
			if t >= 1440 then
				Result := 1
			elseif t < 0 then
				Result := -1
			end
		ensure
			small: Result >= -1 and Result <= 1
		end

feature -- Element change

	add_city (a_label: READABLE_STRING_GENERAL; a_offset_minutes: INTEGER)
			-- Offsets in MINUTES: +330 is India, +345 is Nepal.
		require
			offset_sane: a_offset_minutes >= -720 and a_offset_minutes <= 840
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			cities.extend ([l, a_offset_minutes])
		ensure
			grew: cities.count = old cities.count + 1
		end

feature -- Data

	refresh_domains
			-- Clocks have no axes; the chassis scales idle.
		do
		end

feature -- Drawing

	Row_h: REAL_64 = 24.0

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			now: SIMPLE_DATE_TIME
			utc_min, zt, dd, i: INTEGER
			ry: REAL_64
			shown: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			create now.make_now_utc
			utc_min := now.hour * 60 + now.minute
			from
				i := 1
			until
				i > cities.count
			loop
				ry := y + Inset_top + (i - 1) * Row_h
				if i \\ 2 = 0 then
					a_p.set_color (t.surface_variant)
					a_p.fill_rect (x + 8.0, ry, width - 16.0, Row_h)
				end
				a_p.font ({SW_PAINTER}.Role_ui, 13.0, False)
				a_p.set_color (t.ink)
				a_p.text (x + 16.0, ry + Row_h - 7.0, cities.i_th (i).label)
				zt := zone_time (utc_min, cities.i_th (i).offset_minutes)
				shown := t.locale.format_time (zt // 60, zt \\ 60)
				dd := day_delta (utc_min, cities.i_th (i).offset_minutes)
				a_p.font ({SW_PAINTER}.Role_mono, 13.0, True)
				a_p.set_color (t.ink)
				a_p.text (x + width - 16.0 - a_p.advance (shown)
					- (if dd /= 0 then 34.0 else 0.0 end),
					ry + Row_h - 7.0, shown)
				if dd /= 0 then
					a_p.font ({SW_PAINTER}.Role_mono, 10.5, False)
					if dd > 0 then
						a_p.set_color (t.accent)
						a_p.text (x + width - 42.0, ry + Row_h - 8.0, {STRING_32} "+1d")
					else
						a_p.set_color (t.warning)
						a_p.text (x + width - 42.0, ry + Row_h - 8.0, {STRING_32} "-1d")
					end
				end
				i := i + 1
			end
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Inset_top + cities.count * Row_h + 14.0
		end

feature {NONE} -- Chassis contract

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	cities_attached: cities /= Void

end
