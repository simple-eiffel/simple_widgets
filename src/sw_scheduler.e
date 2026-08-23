note
	description: "[
		The week as a surface: seven day columns, a minute axis run
		through SW_SCALE (the chart chassis's y scale earning
		enterprise keep), events as washed blocks - and OVERLAP
		LANES: events sharing a day and overlapping in time split
		their column side by side, assigned greedily to the lowest
		lane whose previous occupant has ended. The lane math
		(lane_of, lanes_in_day) is public and assaulted; day names
		follow the theme's locale.
	]"

class
	SW_SCHEDULER

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
			create events.make (16)
			day_start := 8 * 60
			day_end := 18 * 60
		end

feature -- Access

	events: ARRAYED_LIST [TUPLE [day, start_min, end_min: INTEGER; label: STRING_32]]

	day_start, day_end: INTEGER
			-- The visible minute window (defaults 08:00 .. 18:00).

	lane_of (a_event: INTEGER): INTEGER
			-- The overlap lane this event stands in within its day:
			-- greedy lowest-free-lane in add order.
		require
			known: a_event >= 1 and a_event <= events.count
		local
			i, j, lane: INTEGER
			ends: ARRAYED_LIST [INTEGER]
		do
			create ends.make (4)
			from
				i := 1
			until
				i > a_event
			loop
				if events.i_th (i).day = events.i_th (a_event).day then
					lane := 0
					from
						j := 1
					until
						j > ends.count or lane > 0
					loop
						if ends.i_th (j) <= events.i_th (i).start_min then
							lane := j
						end
						j := j + 1
					end
					if lane = 0 then
						ends.extend (events.i_th (i).end_min)
						lane := ends.count
					else
						ends.put_i_th (events.i_th (i).end_min, lane)
					end
				end
				i := i + 1
			end
			Result := lane
		ensure
			positive: Result >= 1
		end

	lanes_in_day (a_day: INTEGER): INTEGER
			-- How many side-by-side lanes the day needs; at least 1.
		local
			i, deepest: INTEGER
		do
			deepest := 1
			from
				i := 1
			until
				i > events.count
			loop
				if events.i_th (i).day = a_day then
					deepest := deepest.max (lane_of (i))
				end
				i := i + 1
			end
			Result := deepest
		ensure
			positive: Result >= 1
		end

feature -- Element change

	add_event (a_day, a_start_min, a_end_min: INTEGER; a_label: READABLE_STRING_GENERAL)
		require
			day_known: a_day >= 1 and a_day <= 7
			ordered: a_start_min < a_end_min
			inside: a_start_min >= 0 and a_end_min <= 24 * 60
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			events.extend ([a_day, a_start_min, a_end_min, l])
		ensure
			grew: events.count = old events.count + 1
		end

	set_window (a_start_min, a_end_min: INTEGER)
		require
			ordered: a_start_min < a_end_min
		do
			day_start := a_start_min
			day_end := a_end_min
		ensure
			kept: day_start = a_start_min and day_end = a_end_min
		end

feature -- Data

	refresh_domains
		do
			y_scale.set_domain (day_start.to_double, day_end.to_double)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			d, i, lanes: INTEGER
			day_w, ex, ey, eh, lane_w: REAL_64
			nm: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			refresh_domains
			y_scale.set_range (plot_y, plot_y + plot_h)
			day_w := plot_w / 7.0
				-- hour lines off the ladder
			a_p.font ({SW_PAINTER}.Role_mono, 10.0, False)
			across
				y_scale.ticks (6) as v
			loop
				a_p.set_color (t.outline)
				a_p.hline (plot_x, y_scale.position (v), plot_w)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 4.0, y_scale.position (v) + 3.5,
					t.locale.format_time (v.rounded // 60, v.rounded \\ 60))
			end
				-- day columns, named by the locale
			a_p.font ({SW_PAINTER}.Role_ui, 11.5, True)
			from
				d := 1
			until
				d > 7
			loop
				a_p.set_color (t.outline)
				a_p.vline (plot_x + (d - 1) * day_w + 0.5, plot_y, plot_h)
				nm := t.locale.day_name_short (d)
				a_p.set_color (t.ink_muted)
				a_p.text (plot_x + (d - 1) * day_w + day_w / 2.0 - a_p.advance (nm) / 2.0,
					y + Inset_top - 4.0, nm)
				d := d + 1
			end
				-- the events, laned
			from
				i := 1
			until
				i > events.count
			loop
				lanes := lanes_in_day (events.i_th (i).day)
				lane_w := (day_w - 6.0) / lanes
				ex := plot_x + (events.i_th (i).day - 1) * day_w + 3.0
					+ (lane_of (i) - 1) * lane_w
				ey := y_scale.position (events.i_th (i).start_min.to_double)
				eh := (y_scale.position (events.i_th (i).end_min.to_double) - ey).max (12.0)
				a_p.set_color_alpha (t.accent, 0.30)
				a_p.rrect_fill (ex, ey, lane_w - 2.0, eh, 3.0)
				a_p.set_color (t.accent)
				a_p.vline (ex + 0.5, ey, eh)
				a_p.font ({SW_PAINTER}.Role_ui, 10.5, False)
				a_p.set_color (t.ink)
				a_p.text (ex + 5.0, ey + 12.0, events.i_th (i).label)
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

feature {NONE} -- Chassis contract

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	events_attached: events /= Void
	window_ordered: day_start < day_end

end
