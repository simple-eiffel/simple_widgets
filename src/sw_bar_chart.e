note
	description: "[
		Bars over the chassis: one series of labelled categories,
		y fitted 0-to-max on the tick ladder, slots dividing the
		plot evenly with bars at 62% of their slot. The x axis
		writes category labels, not numbers. Hovering a slot rings
		its bar and names the value. Grouped multi-series bars are
		a future - the docs say so out loud.
	]"

class
	SW_BAR_CHART

inherit
	SW_CHART
		redefine
			draw_x_axis, draw_hover
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create bars.make (6)
		end

feature -- Access

	bars: ARRAYED_LIST [TUPLE [label: STRING_32; value: REAL_64]]

	bar_at (a_px: REAL_64): INTEGER
			-- Which slot the x position falls in; 0 outside. Pure
			-- math over the plot rectangle - assaultable headless
			-- once ranges are anchored.
		local
			slot: REAL_64
		do
			if not bars.is_empty and then a_px >= plot_x and then a_px <= plot_x + plot_w then
				slot := plot_w / bars.count
				Result := (((a_px - plot_x) / slot).floor + 1).min (bars.count)
			end
		ensure
			in_range: Result >= 0 and Result <= bars.count
		end

feature -- Element change

	add_bar (a_label: READABLE_STRING_GENERAL; a_value: REAL_64)
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			bars.extend ([l, a_value])
		ensure
			grew: bars.count = old bars.count + 1
		end

feature -- Data

	refresh_domains
		local
			hi: REAL_64
		do
			across
				bars as b
			loop
				hi := hi.max (b.value)
			end
			y_scale.set_domain (0.0, hi.max (1.0))
			y_scale.nice_domain (4)
			x_scale.set_domain (0.0, bars.count.max (1).to_double)
		end

feature {NONE} -- Drawing

	draw_data (a_p: SW_PAINTER)
		local
			i: INTEGER
			slot, bw, bx, by: REAL_64
		do
			if not bars.is_empty then
				slot := plot_w / bars.count
				bw := slot * 0.62
				from
					i := 1
				until
					i > bars.count
				loop
					bx := plot_x + (i - 1) * slot + (slot - bw) / 2.0
					by := y_scale.position (bars.i_th (i).value)
					a_p.set_color (a_p.theme.accent)
					a_p.fill_rect (bx, by, bw, (plot_y + plot_h - by).max (1.0))
					i := i + 1
				end
			end
		end

	draw_x_axis (a_p: SW_PAINTER)
			-- Category labels, centred under their slots.
		local
			i: INTEGER
			slot, cx: REAL_64
		do
			if not bars.is_empty then
				slot := plot_w / bars.count
				a_p.font ({SW_PAINTER}.Role_ui, 11.5, False)
				a_p.set_color (a_p.theme.ink_muted)
				from
					i := 1
				until
					i > bars.count
				loop
					cx := plot_x + (i - 1) * slot + slot / 2.0
					a_p.text (cx - a_p.advance (bars.i_th (i).label) / 2.0,
						y + height - 9.0, bars.i_th (i).label)
					i := i + 1
				end
			end
		end

	draw_hover (a_p: SW_PAINTER)
		local
			k: INTEGER
			slot, bw, bx, by: REAL_64
			chip: STRING_32
		do
			if shows_hover and then hover_py >= plot_y and then hover_py <= plot_y + plot_h then
				k := bar_at (hover_px)
				if k > 0 then
					slot := plot_w / bars.count
					bw := slot * 0.62
					bx := plot_x + (k - 1) * slot + (slot - bw) / 2.0
					by := y_scale.position (bars.i_th (k).value)
					a_p.set_color (a_p.theme.ink)
					a_p.rrect_stroke (bx - 1.0, by - 1.0, bw + 2.0,
						(plot_y + plot_h - by).max (1.0) + 2.0, 2.0)
					chip := label_of (bars.i_th (k).value)
					a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
					a_p.set_color (a_p.theme.surface_variant)
					a_p.rrect_fill (bx + bw / 2.0 - a_p.advance (chip) / 2.0 - 5.0,
						(by - 22.0).max (y + 4.0), a_p.advance (chip) + 10.0, 16.0, 3.0)
					a_p.set_color (a_p.theme.ink)
					a_p.text (bx + bw / 2.0 - a_p.advance (chip) / 2.0,
						(by - 10.0).max (y + 16.0), chip)
				end
			end
		end

invariant
	bars_attached: bars /= Void

end
