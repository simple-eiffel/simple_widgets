note
	description: "[
		A grid of heat: rows by columns of values, each cell washed
		along a two-colour ramp (channel-wise blend between the
		theme's quiet surface and its accent - the blend math is
		public and assaulted at its endpoints). Row and column
		labels ride the edges; hover outlines a cell and names
		row / column / value. Cell slot arithmetic is bar_at's
		idiom, twice. Flat data washes everything to the honest
		midpoint - no divide-by-nothing heroics.
	]"

class
	SW_HEATMAP

inherit
	SW_CHART
		redefine
			draw
		end

create
	make

feature {NONE} -- Initialization

	make (a_rows, a_cols: INTEGER)
		require
			some_grid: a_rows >= 1 and a_cols >= 1
		do
			make_chart
			rows := a_rows
			cols := a_cols
			create cells.make_filled (0.0, 1, a_rows * a_cols)
			create row_labels.make (a_rows)
			create col_labels.make (a_cols)
		ensure
			sized: rows = a_rows and cols = a_cols
		end

feature -- Access

	rows, cols: INTEGER

	cells: ARRAY [REAL_64]
			-- Row-major values.

	row_labels, col_labels: ARRAYED_LIST [STRING_32]

	cell (a_row, a_col: INTEGER): REAL_64
		require
			in_grid: a_row >= 1 and a_row <= rows and a_col >= 1 and a_col <= cols
		do
			Result := cells [(a_row - 1) * cols + a_col]
		end

	low: REAL_64
		local
			i: INTEGER
		do
			Result := cells [1]
			from
				i := 2
			until
				i > cells.count
			loop
				Result := Result.min (cells [i])
				i := i + 1
			end
		end

	high: REAL_64
		local
			i: INTEGER
		do
			Result := cells [1]
			from
				i := 2
			until
				i > cells.count
			loop
				Result := Result.max (cells [i])
				i := i + 1
			end
		end

	heat_of (a_row, a_col: INTEGER): REAL_64
			-- The cell normalized 0 (coolest) .. 1 (hottest); flat
			-- grids answer the honest midpoint.
		require
			in_grid: a_row >= 1 and a_row <= rows and a_col >= 1 and a_col <= cols
		do
			if high > low then
				Result := (cell (a_row, a_col) - low) / (high - low)
			else
				Result := 0.5
			end
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

	row_at (a_py: REAL_64): INTEGER
			-- The grid row under a surface y; 0 outside.
		local
			slot: REAL_64
		do
			if a_py >= plot_y and then a_py <= plot_y + plot_h then
				slot := plot_h / rows
				Result := (((a_py - plot_y) / slot).floor + 1).min (rows)
			end
		ensure
			in_range: Result >= 0 and Result <= rows
		end

	col_at (a_px: REAL_64): INTEGER
			-- The grid column under a surface x; 0 outside.
		local
			slot: REAL_64
		do
			if a_px >= plot_x and then a_px <= plot_x + plot_w then
				slot := plot_w / cols
				Result := (((a_px - plot_x) / slot).floor + 1).min (cols)
			end
		ensure
			in_range: Result >= 0 and Result <= cols
		end

	blend (a_from, a_to: NATURAL_32; a_fraction: REAL_64): NATURAL_32
			-- Channel-wise interpolation between two 0xRRGGBB colours.
		require
			unit: a_fraction >= 0.0 and a_fraction <= 1.0
		local
			r1, g1, b1, r2, g2, b2: INTEGER
		do
			r1 := a_from.bit_shift_right (16).bit_and (0xFF).to_integer_32
			g1 := a_from.bit_shift_right (8).bit_and (0xFF).to_integer_32
			b1 := a_from.bit_and (0xFF).to_integer_32
			r2 := a_to.bit_shift_right (16).bit_and (0xFF).to_integer_32
			g2 := a_to.bit_shift_right (8).bit_and (0xFF).to_integer_32
			b2 := a_to.bit_and (0xFF).to_integer_32
			Result := ((r1 + ((r2 - r1).to_double * a_fraction).rounded).to_natural_32.bit_shift_left (16))
				.bit_or ((g1 + ((g2 - g1).to_double * a_fraction).rounded).to_natural_32.bit_shift_left (8))
				.bit_or ((b1 + ((b2 - b1).to_double * a_fraction).rounded).to_natural_32)
		end

feature -- Element change

	set_cell (a_row, a_col: INTEGER; a_value: REAL_64)
		require
			in_grid: a_row >= 1 and a_row <= rows and a_col >= 1 and a_col <= cols
		do
			cells [(a_row - 1) * cols + a_col] := a_value
		ensure
			kept: cell (a_row, a_col) = a_value
		end

	set_row_labels (a_labels: ITERABLE [READABLE_STRING_GENERAL])
		do
			row_labels.wipe_out
			across
				a_labels as l
			loop
				row_labels.extend (create {STRING_32}.make_from_string_general (l))
			end
		end

	set_col_labels (a_labels: ITERABLE [READABLE_STRING_GENERAL])
		do
			col_labels.wipe_out
			across
				a_labels as l
			loop
				col_labels.extend (create {STRING_32}.make_from_string_general (l))
			end
		end

feature -- Data

	refresh_domains
			-- Heat has no axes; the chassis scales idle.
		do
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			r, c, hr, hc: INTEGER
			cw, ch, cx, cy: REAL_64
			chip: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			cw := plot_w / cols
			ch := plot_h / rows
			if shows_hover then
				hr := row_at (hover_py)
				hc := col_at (hover_px)
			end
			from
				r := 1
			until
				r > rows
			loop
				from
					c := 1
				until
					c > cols
				loop
					cx := plot_x + (c - 1) * cw
					cy := plot_y + (r - 1) * ch
					a_p.set_color (blend (t.surface_variant, t.accent, heat_of (r, c)))
					a_p.fill_rect (cx + 0.5, cy + 0.5, (cw - 1.0).max (1.0), (ch - 1.0).max (1.0))
					c := c + 1
				end
				r := r + 1
			end
				-- edge labels
			a_p.font ({SW_PAINTER}.Role_mono, 10.0, False)
			a_p.set_color (t.ink_muted)
			from
				r := 1
			until
				r > rows or r > row_labels.count
			loop
				a_p.text (x + 6.0, plot_y + (r - 0.5) * ch + 3.5, row_labels.i_th (r))
				r := r + 1
			end
			from
				c := 1
			until
				c > cols or c > col_labels.count
			loop
				a_p.text (plot_x + (c - 0.5) * cw - a_p.advance (col_labels.i_th (c)) / 2.0,
					y + height - 9.0, col_labels.i_th (c))
				c := c + 1
			end
			if hr > 0 and hc > 0 then
				a_p.set_color (t.ink)
				a_p.rrect_stroke (plot_x + (hc - 1) * cw + 0.5, plot_y + (hr - 1) * ch + 0.5,
					cw - 1.0, ch - 1.0, 2.0)
				create chip.make (24)
				if hr <= row_labels.count then
					chip.append (row_labels.i_th (hr))
					chip.append ({STRING_32} " / ")
				end
				if hc <= col_labels.count then
					chip.append (col_labels.i_th (hc))
					chip.append ({STRING_32} " %/8212/ ")
				end
				chip.append (label_of (cell (hr, hc)))
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

feature {NONE} -- Chassis contract

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	grid_positive: rows >= 1 and cols >= 1
	cells_sized: cells.count = rows * cols

end
