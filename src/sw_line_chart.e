note
	description: "[
		Lines over the chassis: multiple named series, auto-fitted
		domains (y widened to the tick ladder), an optional area
		wash under each line (with_area covers the roadmap's area
		chart), an emphasized endpoint per series, and a rolling
		capacity so a live feed - the demo streams every frame's
		render cost into one of these - stays bounded. Hover snaps
		a crosshair to the nearest sample of the first series and
		names its numbers.
	]"

class
	SW_LINE_CHART

inherit
	SW_CHART
		redefine
			draw_hover
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create series.make (2)
		end

feature -- Access

	series: ARRAYED_LIST [TUPLE [name: STRING_32; pts: ARRAYED_LIST [TUPLE [vx, vy: REAL_64]]]]

	capacity: INTEGER
			-- Per-series point cap; 0 = unbounded. A full series
			-- drops its oldest point per arrival - the rolling feed.

	is_area: BOOLEAN
			-- Wash the region under each line?

feature -- Element change

	add_series (a_name: READABLE_STRING_GENERAL)
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_name)
			series.extend ([l, create {ARRAYED_LIST [TUPLE [vx, vy: REAL_64]]}.make (64)])
		ensure
			grew: series.count = old series.count + 1
		end

	add_point (a_vx, a_vy: REAL_64)
			-- Append to the LAST series; capacity rolls the oldest out.
		require
			has_series: not series.is_empty
		do
			series.last.pts.extend ([a_vx, a_vy])
			if capacity > 0 and then series.last.pts.count > capacity then
				series.last.pts.start
				series.last.pts.remove
			end
		ensure
			bounded: capacity > 0 implies series.last.pts.count <= capacity
		end

	set_capacity (a_capacity: INTEGER)
		require
			sane: a_capacity >= 0
		do
			capacity := a_capacity
		ensure
			set: capacity = a_capacity
		end

	with_area: like Current
			-- Fluent: wash under the lines.
		do
			is_area := True
			Result := Current
		ensure
			washed: is_area
			chained: Result = Current
		end

feature -- Data

	refresh_domains
		local
			lo_x, hi_x, lo_y, hi_y: REAL_64
			seen: BOOLEAN
		do
			across
				series as s
			loop
				across
					s.pts as pt
				loop
					if not seen then
						lo_x := pt.vx
						hi_x := pt.vx
						lo_y := pt.vy
						hi_y := pt.vy
						seen := True
					else
						lo_x := lo_x.min (pt.vx)
						hi_x := hi_x.max (pt.vx)
						lo_y := lo_y.min (pt.vy)
						hi_y := hi_y.max (pt.vy)
					end
				end
			end
			if seen then
				x_scale.set_domain (lo_x, hi_x)
				y_scale.set_domain (lo_y, hi_y)
				y_scale.nice_domain (4)
			else
				x_scale.set_domain (0.0, 1.0)
				y_scale.set_domain (0.0, 1.0)
			end
		end

feature {NONE} -- Drawing

	draw_data (a_p: SW_PAINTER)
		local
			i: INTEGER
			poly, wash: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			base: REAL_64
		do
			base := plot_y + plot_h
			from
				i := 1
			until
				i > series.count
			loop
				create poly.make (series.i_th (i).pts.count)
				across
					series.i_th (i).pts as pt
				loop
					poly.extend ([x_scale.position (pt.vx), y_scale.position (pt.vy)])
				end
				if poly.count >= 2 then
					if is_area then
						wash := poly.twin
						wash.extend ([poly.last.px, base])
						wash.extend ([poly.first.px, base])
						a_p.set_color_alpha (series_color (i, a_p), 0.16)
						a_p.polygon_fill (wash)
					end
					a_p.set_color (series_color (i, a_p))
					a_p.polyline (poly, 1.6)
					a_p.circle_fill (poly.last.px, poly.last.py, 2.6)
				elseif poly.count = 1 then
					a_p.set_color (series_color (i, a_p))
					a_p.circle_fill (poly.first.px, poly.first.py, 2.6)
				end
				i := i + 1
			end
		end

	draw_hover (a_p: SW_PAINTER)
			-- Legend row first, then the crosshair snapped to the
			-- first series' nearest sample.
		local
			names: ARRAYED_LIST [STRING_32]
		do
			if series.count >= 2 then
				create names.make (series.count)
				across
					series as s
				loop
					names.extend (s.name)
				end
				draw_legend_row (a_p, names)
			end
			draw_crosshair (a_p)
		end

	draw_crosshair (a_p: SW_PAINTER)
			-- Crosshair snapped to the first series' nearest sample.
		local
			k, i: INTEGER
			d, best, sx, sy: REAL_64
			chip: STRING_32
		do
			if shows_hover and then not series.is_empty
				and then not series.first.pts.is_empty
				and then hover_px >= plot_x and then hover_px <= plot_x + plot_w
				and then hover_py >= plot_y and then hover_py <= plot_y + plot_h
			then
				best := plot_w
				from
					i := 1
				until
					i > series.first.pts.count
				loop
					d := (x_scale.position (series.first.pts.i_th (i).vx) - hover_px).abs
					if d < best then
						best := d
						k := i
					end
					i := i + 1
				end
				if k > 0 then
					sx := x_scale.position (series.first.pts.i_th (k).vx)
					sy := y_scale.position (series.first.pts.i_th (k).vy)
					a_p.set_color (a_p.theme.outline)
					a_p.vline (sx, plot_y, plot_h)
					a_p.set_color (series_color (1, a_p))
					a_p.circle_stroke (sx, sy, 4.0)
					chip := label_of (series.first.pts.i_th (k).vx)
					chip.append ({STRING_32} ", ")
					chip.append (label_of (series.first.pts.i_th (k).vy))
					a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
					a_p.set_color (a_p.theme.surface_variant)
					a_p.rrect_fill ((sx + 8.0).min (x + width - a_p.advance (chip) - 14.0),
						(sy - 22.0).max (y + 4.0), a_p.advance (chip) + 10.0, 16.0, 3.0)
					a_p.set_color (a_p.theme.ink)
					a_p.text ((sx + 13.0).min (x + width - a_p.advance (chip) - 9.0),
						(sy - 10.0).max (y + 16.0), chip)
				end
			end
		end

invariant
	series_attached: series /= Void
	capacity_sane: capacity >= 0

end
