note
	description: "[
		The pivot: flat records (row key, column key, value) folded
		into a cross-table with row totals, column totals and the
		grand total. Keys order by first appearance - the data's own
		narrative, not alphabetical accident. Three aggregations:
		SUM (default), COUNT, AVG. All the folding math is public
		and assaulted; the widget merely renders what value_at and
		the totals already prove.
	]"

class
	SW_PIVOT

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
			create records.make (16)
			create row_keys.make (8)
			create col_keys.make (8)
			mode := Mode_sum
		end

feature -- Access

	Mode_sum: INTEGER = 1
	Mode_count: INTEGER = 2
	Mode_avg: INTEGER = 3

	mode: INTEGER

	records: ARRAYED_LIST [TUPLE [row_key, col_key: STRING_32; value: REAL_64]]

	row_keys, col_keys: ARRAYED_LIST [STRING_32]
			-- Distinct keys, in first-appearance order.

	value_at (a_row, a_col: INTEGER): REAL_64
			-- The aggregated cell for row_keys[a_row] x col_keys[a_col].
		require
			row_known: a_row >= 1 and a_row <= row_keys.count
			col_known: a_col >= 1 and a_col <= col_keys.count
		local
			total: REAL_64
			n: INTEGER
		do
			across
				records as r
			loop
				if r.row_key.same_string (row_keys.i_th (a_row))
					and then r.col_key.same_string (col_keys.i_th (a_col))
				then
					total := total + r.value
					n := n + 1
				end
			end
			inspect mode
			when Mode_count then
				Result := n.to_double
			when Mode_avg then
				if n > 0 then
					Result := total / n
				end
			else
				Result := total
			end
		end

	row_total (a_row: INTEGER): REAL_64
		require
			known: a_row >= 1 and a_row <= row_keys.count
		local
			c: INTEGER
		do
			from
				c := 1
			until
				c > col_keys.count
			loop
				Result := Result + value_at (a_row, c)
				c := c + 1
			end
		end

	col_total (a_col: INTEGER): REAL_64
		require
			known: a_col >= 1 and a_col <= col_keys.count
		local
			r: INTEGER
		do
			from
				r := 1
			until
				r > row_keys.count
			loop
				Result := Result + value_at (r, a_col)
				r := r + 1
			end
		end

	grand_total: REAL_64
		local
			r: INTEGER
		do
			from
				r := 1
			until
				r > row_keys.count
			loop
				Result := Result + row_total (r)
				r := r + 1
			end
		end

feature -- Element change

	add_record (a_row_key, a_col_key: READABLE_STRING_GENERAL; a_value: REAL_64)
		local
			rk, ck: STRING_32
		do
			create rk.make_from_string_general (a_row_key)
			create ck.make_from_string_general (a_col_key)
			records.extend ([rk, ck, a_value])
			if not across row_keys as k some k.same_string (rk) end then
				row_keys.extend (rk)
			end
			if not across col_keys as k some k.same_string (ck) end then
				col_keys.extend (ck)
			end
		ensure
			grew: records.count = old records.count + 1
		end

	set_mode (a_mode: INTEGER)
		require
			known: a_mode >= Mode_sum and a_mode <= Mode_avg
		do
			mode := a_mode
		ensure
			set: mode = a_mode
		end

feature -- Data

	refresh_domains
			-- The fold is the scale; the chassis axes idle.
		do
		end

feature -- Drawing

	Cell_w: REAL_64 = 86.0

	Row_h: REAL_64 = 24.0

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			r, c: INTEGER
			cx, cy, label_w: REAL_64
			s: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			label_w := 110.0
			a_p.font ({SW_PAINTER}.Role_ui, 12.0, True)
			from
				c := 1
			until
				c > col_keys.count
			loop
				cx := x + label_w + (c - 1) * Cell_w
				a_p.set_color (t.ink_muted)
				a_p.text (cx + 6.0, y + Inset_top + Row_h - 8.0, col_keys.i_th (c))
				c := c + 1
			end
			a_p.set_color (t.ink_muted)
			a_p.text (x + label_w + col_keys.count * Cell_w + 6.0,
				y + Inset_top + Row_h - 8.0, {STRING_32} "total")
			from
				r := 1
			until
				r > row_keys.count
			loop
				cy := y + Inset_top + r * Row_h
				if r \\ 2 = 0 then
					a_p.set_color (t.surface_variant)
					a_p.fill_rect (x + 6.0, cy, width - 12.0, Row_h)
				end
				a_p.font ({SW_PAINTER}.Role_ui, 12.0, True)
				a_p.set_color (t.ink)
				a_p.text (x + 10.0, cy + Row_h - 8.0, row_keys.i_th (r))
				a_p.font ({SW_PAINTER}.Role_mono, 12.0, False)
				from
					c := 1
				until
					c > col_keys.count
				loop
					cx := x + label_w + (c - 1) * Cell_w
					a_p.text (cx + 6.0, cy + Row_h - 8.0, label_of (value_at (r, c)))
					c := c + 1
				end
				a_p.set_color (t.accent)
				a_p.text (x + label_w + col_keys.count * Cell_w + 6.0,
					cy + Row_h - 8.0, label_of (row_total (r)))
				r := r + 1
			end
				-- the totals row
			cy := y + Inset_top + (row_keys.count + 1) * Row_h
			a_p.set_color (t.outline)
			a_p.hline (x + 6.0, cy - 1.5, width - 12.0)
			a_p.font ({SW_PAINTER}.Role_ui, 12.0, True)
			a_p.set_color (t.ink_muted)
			a_p.text (x + 10.0, cy + Row_h - 8.0, {STRING_32} "total")
			a_p.font ({SW_PAINTER}.Role_mono, 12.0, True)
			from
				c := 1
			until
				c > col_keys.count
			loop
				a_p.set_color (t.accent)
				a_p.text (x + label_w + (c - 1) * Cell_w + 6.0,
					cy + Row_h - 8.0, label_of (col_total (c)))
				c := c + 1
			end
			a_p.set_color (t.ink)
			a_p.text (x + label_w + col_keys.count * Cell_w + 6.0,
				cy + Row_h - 8.0, label_of (grand_total))
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
	records_attached: records /= Void
	keys_attached: row_keys /= Void and col_keys /= Void
	mode_known: mode >= Mode_sum and mode <= Mode_avg

end
