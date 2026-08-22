note
	description: "[
		The pipeline as trapezoids: stages narrow with their values,
		centred symmetrically, each band joined to the next by its
		slanted sides (polygon_fill earns its keep). Every band
		names itself, its value and its CONVERSION from the first
		stage - the number funnels exist to show. Hover brightens a
		band and restates its truth; stage_at and conversion_of are
		public math, assaulted headless.
	]"

class
	SW_FUNNEL_CHART

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
			create stages.make (5)
		end

feature -- Access

	stages: ARRAYED_LIST [TUPLE [label: STRING_32; value: REAL_64]]

	conversion_of (a_index: INTEGER): REAL_64
			-- Stage `a_index''s value as a percent of the FIRST
			-- stage; 100 for the first, 0 when the first is nothing.
		require
			in_range: a_index >= 1 and a_index <= stages.count
		do
			if not stages.is_empty and then stages.first.value > 0.0 then
				Result := stages.i_th (a_index).value / stages.first.value * 100.0
			end
		ensure
			non_negative: Result >= 0.0
		end

	stage_at (a_py: REAL_64): INTEGER
			-- The band under a surface y; 0 outside. Slot math over
			-- the inset plot, assaultable once bounds are set.
		local
			slot: REAL_64
		do
			if not stages.is_empty and then a_py >= plot_y and then a_py <= plot_y + plot_h then
				slot := plot_h / stages.count
				Result := (((a_py - plot_y) / slot).floor + 1).min (stages.count)
			end
		ensure
			in_range: Result >= 0 and Result <= stages.count
		end

feature -- Element change

	add_stage (a_label: READABLE_STRING_GENERAL; a_value: REAL_64)
		require
			non_negative: a_value >= 0.0
			descending: stages.is_empty or else a_value <= stages.last.value
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			stages.extend ([l, a_value])
		ensure
			grew: stages.count = old stages.count + 1
		end

feature -- Data

	refresh_domains
			-- Funnels have no axes; the chassis scales idle.
		do
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, hot: INTEGER
			slot, cx, wt, wb, ty, band_h: REAL_64
			quad: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			row: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if shows_hover then
				hot := stage_at (hover_py)
				if hover_px < plot_x or hover_px > plot_x + plot_w then
					hot := 0
				end
			end
			if not stages.is_empty and then stages.first.value > 0.0 then
				slot := plot_h / stages.count
				band_h := slot * 0.78
				cx := plot_x + plot_w / 2.0
				from
					i := 1
				until
					i > stages.count
				loop
					ty := plot_y + (i - 1) * slot + (slot - band_h) / 2.0
					wt := plot_w * (conversion_of (i) / 100.0).max (0.04)
					if i < stages.count then
						wb := plot_w * (conversion_of (i + 1) / 100.0).max (0.04)
					else
						wb := wt
					end
					create quad.make (4)
					quad.extend ([cx - wt / 2.0, ty])
					quad.extend ([cx + wt / 2.0, ty])
					quad.extend ([cx + wb / 2.0, ty + band_h])
					quad.extend ([cx - wb / 2.0, ty + band_h])
					if i = hot then
						a_p.set_color (t.accent)
					else
						a_p.set_color_alpha (t.accent, 0.55 + 0.45 * (conversion_of (i) / 100.0))
					end
					a_p.polygon_fill (quad)
					create row.make (32)
					row.append (stages.i_th (i).label)
					row.append ({STRING_32} "  ")
					row.append (label_of (stages.i_th (i).value))
					row.append ({STRING_32} "  (")
					row.append (label_of (conversion_of (i)))
					row.append ({STRING_32} "%%)")
					a_p.font ({SW_PAINTER}.Role_ui, 12.0, i = hot)
					if i = hot then
						a_p.set_color (t.ink)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.text (cx - a_p.advance (row) / 2.0,
						ty + band_h / 2.0 + 4.5, row)
					i := i + 1
				end
			else
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + Inset_left, y + height / 2.0, {STRING_32} "no data yet")
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
			-- Unused: draw is redefined wholesale (no axes here).
		do
		end

invariant
	stages_attached: stages /= Void

end
