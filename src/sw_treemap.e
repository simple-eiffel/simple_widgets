note
	description: "[
		Areas as shares: labelled items tiled into the plot by
		recursive slice-and-dice bisection - the range splits where
		cumulative value crosses half, the rectangle splits in the
		same proportion, and the axis alternates per level. The
		layout is deterministic pure math with an exact property
		the assault asserts: every item's area fraction EQUALS its
		value fraction, and the tiles sum to the plot. Hover
		outlines a tile and names label, value and share.
		Squarified layout is a stated future.
	]"

class
	SW_TREEMAP

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
			create items.make (8)
			create layout.make_filled ([0.0, 0.0, 0.0, 0.0], 1, 1)
		end

feature -- Access

	items: ARRAYED_LIST [TUPLE [label: STRING_32; value: REAL_64]]

	layout: ARRAY [TUPLE [rx, ry, rw, rh: REAL_64]]
			-- One rectangle per item, valid after refresh_layout.

	total: REAL_64
		do
			across
				items as it
			loop
				Result := Result + it.value
			end
		ensure
			non_negative: Result >= 0.0
		end

	percent_of (a_index: INTEGER): REAL_64
		require
			in_range: a_index >= 1 and a_index <= items.count
		do
			if total > 0.0 then
				Result := items.i_th (a_index).value / total * 100.0
			end
		ensure
			sane: Result >= 0.0 and Result <= 100.0
		end

	item_at (a_px, a_py: REAL_64): INTEGER
			-- The tile under a surface point; 0 outside. Valid after
			-- refresh_layout.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > items.count or Result > 0
			loop
				if i <= layout.count
					and then a_px >= layout [i].rx and then a_px < layout [i].rx + layout [i].rw
					and then a_py >= layout [i].ry and then a_py < layout [i].ry + layout [i].rh
				then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= items.count
		end

feature -- Element change

	add_item (a_label: READABLE_STRING_GENERAL; a_value: REAL_64)
		require
			positive: a_value > 0.0
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			items.extend ([l, a_value])
		ensure
			grew: items.count = old items.count + 1
		end

feature -- Layout

	refresh_layout
			-- Tile the current items into the plot rectangle.
			-- Public: draw calls it every frame, assaults call it to
			-- interrogate the geometry headless.
		do
			create layout.make_filled ([0.0, 0.0, 0.0, 0.0], 1, items.count.max (1))
			if not items.is_empty and then total > 0.0 then
				place (1, items.count, plot_x, plot_y, plot_w, plot_h, plot_w >= plot_h)
			end
		end

feature -- Data

	refresh_domains
			-- Areas have no axes; the chassis scales idle.
		do
		end

feature -- Drawing

	tile_color (a_index: INTEGER; a_p: SW_PAINTER): NATURAL_32
			-- The pie's eight-step palette, shared discipline.
		do
			inspect (a_index - 1) \\ 8
			when 0 then
				Result := a_p.theme.accent
			when 1 then
				Result := a_p.theme.success
			when 2 then
				Result := a_p.theme.warning
			when 3 then
				Result := a_p.theme.danger
			when 4 then
				Result := a_p.theme.wash_accent
			when 5 then
				Result := a_p.theme.wash_success
			when 6 then
				Result := a_p.theme.wash_warning
			else
				Result := a_p.theme.wash_danger
			end
		end

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, hot: INTEGER
			chip: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			refresh_layout
			if shows_hover then
				hot := item_at (hover_px, hover_py)
			end
			from
				i := 1
			until
				i > items.count
			loop
				a_p.set_color (tile_color (i, a_p))
				a_p.fill_rect (layout [i].rx + 1.0, layout [i].ry + 1.0,
					(layout [i].rw - 2.0).max (1.0), (layout [i].rh - 2.0).max (1.0))
				a_p.font ({SW_PAINTER}.Role_ui, 11.5, i = hot)
				if layout [i].rw > a_p.advance (items.i_th (i).label) + 10.0
					and then layout [i].rh > 18.0
				then
					a_p.set_color (t.ink)
					a_p.text (layout [i].rx + 6.0, layout [i].ry + 15.0, items.i_th (i).label)
				end
				i := i + 1
			end
			if hot > 0 then
				a_p.set_color (t.ink)
				a_p.rrect_stroke (layout [hot].rx + 0.5, layout [hot].ry + 0.5,
					layout [hot].rw - 1.0, layout [hot].rh - 1.0, 2.0)
				create chip.make (32)
				chip.append (items.i_th (hot).label)
				chip.append ({STRING_32} " %/8212/ ")
				chip.append (label_of (items.i_th (hot).value))
				chip.append ({STRING_32} " (")
				chip.append (label_of (percent_of (hot)))
				chip.append ({STRING_32} "%%)")
				a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + 10.0, y + height - 24.0, a_p.advance (chip) + 10.0, 17.0, 3.0)
				a_p.set_color (t.ink)
				a_p.text (x + 15.0, y + height - 11.0, chip)
			end
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature {NONE} -- The bisection

	place (a_from, a_to: INTEGER; a_rx, a_ry, a_rw, a_rh: REAL_64; a_split_x: BOOLEAN)
			-- Tile items a_from..a_to into the rectangle, splitting
			-- the range where cumulative value crosses half and the
			-- rectangle in the same proportion; axis alternates.
		require
			ordered: a_from <= a_to
		local
			range_total, half, acc, share: REAL_64
			k, i: INTEGER
		do
			if a_from = a_to then
				layout [a_from] := [a_rx, a_ry, a_rw, a_rh]
			else
				from
					i := a_from
				until
					i > a_to
				loop
					range_total := range_total + items.i_th (i).value
					i := i + 1
				end
				half := range_total / 2.0
				k := a_from
				from
					i := a_from
					acc := 0.0
				until
					i >= a_to or acc + items.i_th (i).value > half
				loop
					acc := acc + items.i_th (i).value
					k := i + 1
					i := i + 1
				end
				if k = a_from then
						-- the first item alone outweighs half
					acc := items.i_th (a_from).value
					k := a_from + 1
				end
				share := acc / range_total
				if a_split_x then
					place (a_from, k - 1, a_rx, a_ry, a_rw * share, a_rh, False)
					place (k, a_to, a_rx + a_rw * share, a_ry, a_rw * (1.0 - share), a_rh, False)
				else
					place (a_from, k - 1, a_rx, a_ry, a_rw, a_rh * share, True)
					place (k, a_to, a_rx, a_ry + a_rh * share, a_rw, a_rh * (1.0 - share), True)
				end
			end
		end

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	items_attached: items /= Void
	layout_attached: layout /= Void

end
