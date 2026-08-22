note
	description: "[
		Dots over the chassis: raw (x, y) points, both domains
		fitted and widened to the tick ladder, accent discs with a
		surface ring so overlaps stay legible. Hover finds the
		nearest dot within reach and names its pair - the same
		nearest-within-radius idiom the mesh uses.
	]"

class
	SW_SCATTER_CHART

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
			create points.make (32)
		end

feature -- Access

	points: ARRAYED_LIST [TUPLE [vx, vy: REAL_64]]

	nearest_point (a_px, a_py: REAL_64): INTEGER
			-- The dot within grabbing distance of a surface position;
			-- 0 for open space. Range-anchored math, assaultable.
		local
			i: INTEGER
			d2, best, dx, dy: REAL_64
		do
			best := 145.0
			from
				i := 1
			until
				i > points.count
			loop
				dx := x_scale.position (points.i_th (i).vx) - a_px
				dy := y_scale.position (points.i_th (i).vy) - a_py
				d2 := dx * dx + dy * dy
				if d2 < best then
					best := d2
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= points.count
		end

feature -- Element change

	add_point (a_vx, a_vy: REAL_64)
		do
			points.extend ([a_vx, a_vy])
		ensure
			grew: points.count = old points.count + 1
		end

feature -- Data

	refresh_domains
		local
			lo_x, hi_x, lo_y, hi_y: REAL_64
			seen: BOOLEAN
		do
			across
				points as pt
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
			if seen then
				x_scale.set_domain (lo_x, hi_x)
				x_scale.nice_domain (5)
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
			px_, py_: REAL_64
		do
			across
				points as pt
			loop
				px_ := x_scale.position (pt.vx)
				py_ := y_scale.position (pt.vy)
				a_p.set_color (a_p.theme.accent)
				a_p.circle_fill (px_, py_, 3.0)
				a_p.set_color (a_p.theme.surface)
				a_p.circle_stroke (px_, py_, 3.5)
			end
		end

	draw_hover (a_p: SW_PAINTER)
		local
			k: INTEGER
			sx, sy: REAL_64
			chip: STRING_32
		do
			if shows_hover then
				k := nearest_point (hover_px, hover_py)
				if k > 0 then
					sx := x_scale.position (points.i_th (k).vx)
					sy := y_scale.position (points.i_th (k).vy)
					a_p.set_color (a_p.theme.ink)
					a_p.circle_stroke (sx, sy, 5.5)
					create chip.make (16)
					chip.append_character ('(')
					chip.append (label_of (points.i_th (k).vx))
					chip.append ({STRING_32} ", ")
					chip.append (label_of (points.i_th (k).vy))
					chip.append_character (')')
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
	points_attached: points /= Void

end
