note
	description: "[
		Wave 5 opens: the tree table - SW_TREE's flatten engine
		(lazy children, identity-stable selection, virtualization)
		wearing SW_DATA_GRID's first-class columns. The first column
		is the tree itself (indent, arrows, label); every added
		SW_GRID_COLUMN renders its cell from the same node object.
		A header band names the columns; rows band like SW_SHEET
		taught. The two engines were built to converge - this is the
		convergence. Column slot math and the header's row-offset
		arithmetic are public and assaulted.
	]"

class
	SW_TREE_TABLE [G]

inherit
	SW_TREE [G]
		redefine
			draw, row_at, max_scroll
		end

create
	make

feature -- Access

	columns: ARRAYED_LIST [SW_GRID_COLUMN [G]]
		attribute
			create Result.make (4)
		end

	tree_col_width: REAL_64
		attribute
			Result := 220.0
		end

	Header_h: REAL_64 = 26.0

	column_x (a_index: INTEGER): REAL_64
			-- The left edge of value column `a_index' (1-based,
			-- after the tree column). Public slot math, assaulted.
		require
			in_range: a_index >= 1 and a_index <= columns.count
		local
			i: INTEGER
		do
			Result := x + tree_col_width
			from
				i := 1
			until
				i >= a_index
			loop
				Result := Result + columns.i_th (i).width
				i := i + 1
			end
		end

feature -- Element change

	add_column (a_col: SW_GRID_COLUMN [G])
		do
			columns.extend (a_col)
		ensure
			grew: columns.count = old columns.count + 1
		end

	with_column (a_col: SW_GRID_COLUMN [G]): like Current
		do
			add_column (a_col)
			Result := Current
		ensure
			chained: Result = Current
		end

	set_tree_col_width (a_width: REAL_64)
		require
			wide_enough: a_width >= 60.0
		do
			tree_col_width := a_width
		ensure
			set: tree_col_width = a_width
		end

feature -- Layout

	row_at (a_py: REAL_64): INTEGER
			-- Rows begin under the header band.
		do
			if a_py >= y + Header_h then
				Result := (((a_py - y - Header_h + scroll_y) / Row_h).truncated_to_integer + 1)
				if Result < 1 or Result > visible.count then
					Result := 0
				end
			end
		end

	max_scroll: REAL_64
		do
			Result := (visible.count * Row_h - (height - Header_h)).max (0.0)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, ci, first_v, last_v: INTEGER
			ry, ix, cx: REAL_64
			row: TUPLE [node: G; depth: INTEGER; has_kids: BOOLEAN]
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- the header band
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x + 1.0, y + 1.0, width - 2.0, Header_h)
			a_p.font ({SW_PAINTER}.Role_ui, 12.5, True)
			a_p.set_color (t.ink_muted)
			a_p.text (x + 10.0, y + Header_h - 8.0, {STRING_32} "item")
			from
				ci := 1
			until
				ci > columns.count
			loop
				cx := column_x (ci)
				a_p.set_color (t.outline)
				a_p.vline (cx + 0.5, y + 1.0, height - 2.0)
				a_p.set_color (t.ink_muted)
				a_p.text (cx + 8.0, y + Header_h - 8.0, columns.i_th (ci).title)
				ci := ci + 1
			end
			a_p.set_color (t.outline)
			a_p.hline (x + 1.0, y + Header_h + 0.5, width - 2.0)
			if visible.count > 0 then
				a_p.push_clip (x + 1.0, y + Header_h + 1.0, width - 2.0, height - Header_h - 2.0)
				first_v := ((scroll_y / Row_h).truncated_to_integer + 1).max (1).min (visible.count)
				last_v := (((scroll_y + height - Header_h) / Row_h).truncated_to_integer + 1).min (visible.count)
				from
					i := first_v
				until
					i > last_v
				loop
					row := visible.i_th (i)
					ry := y + Header_h + (i - 1) * Row_h - scroll_y
					if attached selected_node as sel and then sel = row.node then
						a_p.set_color (t.wash_accent)
						a_p.fill_rect (x + 1.0, ry, width - 2.0, Row_h)
					elseif i \\ 2 = 0 then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x + 1.0, ry, width - 2.0, Row_h)
					end
					ix := x + 8.0 + row.depth * Indent_w
					if row.has_kids then
						a_p.set_color (t.ink_muted)
						if open_nodes.has (row.node) then
							a_p.text (ix, ry + Row_h - 8.0, {STRING_32} "%/9662/")
						else
							a_p.text (ix, ry + Row_h - 8.0, {STRING_32} "%/9656/")
						end
					end
					a_p.font ({SW_PAINTER}.Role_ui, 13.0, False)
					a_p.set_color (t.ink)
					if attached label_provider as lp then
						a_p.text (ix + 16.0, ry + Row_h - 8.0, lp.item ([row.node]))
					end
					from
						ci := 1
					until
						ci > columns.count
					loop
						a_p.text (column_x (ci) + 8.0, ry + Row_h - 8.0,
							columns.i_th (ci).value.item ([row.node]))
						ci := ci + 1
					end
					i := i + 1
				end
				a_p.pop_clip
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

invariant
	columns_attached: columns /= Void

end
