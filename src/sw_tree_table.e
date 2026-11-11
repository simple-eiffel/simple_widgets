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
			make, draw, row_at, rows_top, accessible_role
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
			-- A REAL_64 attribute is self-initializing, so an attribute
			-- body would never run (VWAB): the 220 px tree column is
			-- set here.
		do
			Precursor (a_viewport_height)
			tree_col_width := 220.0
		end

feature -- Access

	columns: ARRAYED_LIST [SW_GRID_COLUMN [G]]
		attribute
			create Result.make (4)
		end

	tree_col_width: REAL_64

	tree_title: STRING_32
			-- The tree column's header ("item" until set).
		attribute
			Result := {STRING_32} "item"
		end
			-- Width of the tree column; 220 px from `make'.

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

	set_tree_title (a_title: READABLE_STRING_GENERAL)
			-- Name the tree column's header.
		do
			tree_title := a_title.to_string_32
		ensure
			set: tree_title.same_string_general (a_title)
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

	rows_top: REAL_64
			-- The rows begin under the header band.
		do
			Result := Header_h
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
			bar.place (x, y + rows_top, width, rows_height, t)
			bar.set_extent (rows_height, display_count * Row_h)
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- the header band
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x + 1.0, y + 1.0, width - 2.0, Header_h)
			a_p.font ({SW_PAINTER}.Role_ui, 12.5, True)
			a_p.set_color (t.ink_muted)
			a_p.text (x + 10.0, y + Header_h - 8.0, tree_title)
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
						a_p.set_color (styled_selection (t.wash_accent))
						a_p.fill_rect (x + 1.0, ry, width - 2.0, Row_h)
					elseif i \\ 2 = 0 then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x + 1.0, ry, width - 2.0, Row_h)
					end
					ix := x + 8.0 + row.depth * Indent_w
					if row.has_kids then
						a_p.set_color (t.ink_muted)
							-- a drawn chevron, as SW_TREE's: no font lacks it
						if open_nodes.has (row.node) then
							a_p.line (ix, ry + Row_h / 2.0 - 3.0, ix + 4.0, ry + Row_h / 2.0 + 3.0, 1.6)
							a_p.line (ix + 4.0, ry + Row_h / 2.0 + 3.0, ix + 8.0, ry + Row_h / 2.0 - 3.0, 1.6)
						else
							a_p.line (ix + 1.0, ry + Row_h / 2.0 - 5.0, ix + 7.0, ry + Row_h / 2.0, 1.6)
							a_p.line (ix + 7.0, ry + Row_h / 2.0, ix + 1.0, ry + Row_h / 2.0 + 5.0, 1.6)
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
				-- the scroll bar, under the header (the tree's own draw is not run here)
			bar.set_mode (styled_scroll_bars)
			bar.draw (a_p, scroll_y, shows_hover and then bar.contains (hover_px, hover_py))
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Accessibility

	accessible_role: INTEGER
			-- A tree with columns: screen readers know it as a tree-grid, as GTK's column view
			-- over a tree model and AppKit's outline view are.
		do
			Result := {SW_ACCESSIBILITY}.Role_data_grid
		end

invariant
	columns_attached: columns /= Void

end
