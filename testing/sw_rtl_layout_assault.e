note
	description: "W4c-1: right-to-left layout mirrors rows, columns and grids; direction is inherited."

class
	SW_RTL_LAYOUT_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_a_menu_bar_starts_at_the_right
			-- Right to left the first menu title sits at the right and a click there opens it.
		local
			w: SW_WINDOW
			mb: SW_MENU_BAR
			b1, b2: TUPLE [left, width: REAL_64]
		do
			create w.make ("rtl", 0, 0, 600, 200, create {SW_THEME}.make_light)
			create mb.make
			mb.add_menu ("File", agent: SW_MENU do create Result.make end)
			mb.add_menu ("Edit", agent: SW_MENU do create Result.make end)
			mb.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.set_root (mb)
			w.request_render
			b1 := mb.pad_bounds (w.painter, 1)
			b2 := mb.pad_bounds (w.painter, 2)
			assert ("the first title is at the right: " + b1.left.out + " vs " + b2.left.out, b1.left > b2.left)
			assert ("flush right, six pixels in", (mb.x + mb.width - (b1.left + b1.width) - 6.0).abs < 0.5)
			assert ("a click on it", mb.handle_click (b1.left + b1.width / 2.0, mb.y + 10.0))
			assert_integers_equal ("opens the first menu", 1, mb.last_opened_pad)
		end

	test_tabs_start_at_the_right
			-- Right to left the first tab sits at the right; a press there selects it.
		local
			w: SW_WINDOW
			tb: SW_TABS
		do
			create w.make ("rtl", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create tb.make
			tb.add_page ("One", create {SW_LABEL}.make_ui ("first"))
			tb.add_page ("Two", create {SW_LABEL}.make_ui ("second"))
			tb.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.set_root (tb)
			w.request_render
			assert ("placed", tb.is_placed)
			assert ("the first tab is at the right", tb.tab_lefts.i_th (1) > tb.tab_lefts.i_th (2))
			assert ("its right edge near the bar's", tb.x + tb.width - (tb.tab_lefts.i_th (1) + tb.tab_widths.i_th (1)) < 4.0)
			assert ("a press on the second", tb.handle_click (tb.tab_lefts.i_th (2) + 4.0, tb.y + 4.0))
			assert_integers_equal ("selects the second", 2, tb.selected_index)
		end

	test_a_data_grid_puts_its_first_column_at_the_right
			-- Right to left the first column sits at the right, its header is hit there, and a
			-- resize drags the column's left edge.
		local
			w: SW_WINDOW
			g: SW_DATA_GRID [STRING_32]
			l_lefts: ARRAYED_LIST [REAL_64]
			l_rows: ARRAYED_LIST [STRING_32]
			l_old: REAL_64
		do
			create w.make ("rtl", 0, 0, 500, 300, create {SW_THEME}.make_light)
			create g.make (200.0)
			g.add_column (create {SW_GRID_COLUMN [STRING_32]}.make ("Book", 150.0, agent (s: STRING_32): STRING_32 do Result := s end))
			g.add_column (create {SW_GRID_COLUMN [STRING_32]}.make ("Back", 150.0, agent (s: STRING_32): STRING_32 do Result := s.mirrored end))
			create l_rows.make (1)
			l_rows.extend ("Genesis")
			g.set_rows (l_rows)
			g.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.set_root (g)
			w.request_render
			l_lefts := g.column_lefts
			assert ("the first column is at the right", l_lefts.i_th (1) > l_lefts.i_th (2))
			assert ("flush right", (g.x + g.width - (l_lefts.i_th (1) + g.shown_width (1))).abs < 0.5)
			assert_integers_equal ("its header is hit at the right", 1, g.header_column_at (g.x + g.width - 5.0))
			assert_integers_equal ("its divider is its left edge", 1, g.column_edge_at (l_lefts.i_th (1)))
			l_old := g.columns.i_th (1).width
			assert ("a press on the divider", g.handle_click (l_lefts.i_th (1), g.y + 10.0))
			g.handle_drag (l_lefts.i_th (1) - 20.0, g.y + 10.0)
			assert ("dragging the left edge leftwards widens it: " + g.columns.i_th (1).width.out,
				(g.columns.i_th (1).width - (l_old + 20.0)).abs < 0.5)
		end

	test_a_row_places_from_the_right
		local
			w: SW_WINDOW
			r: SW_ROW
			a, b, c: SW_BUTTON
		do
			create w.make ("rtl", 0, 0, 600, 200, create {SW_THEME}.make_light)
			create r.make
			create a.make ("one", agent do end)
			create b.make ("two", agent do end)
			create c.make ("three", agent do end)
			r.put (a)
			r.put (b)
			r.put (c)
			r.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.set_root (r)
			w.request_render
			assert ("the first child is flush right", (a.x + a.width - (r.x + r.width)).abs < 0.5)
			assert ("then leftwards", a.x > b.x and b.x > c.x)
			assert ("one gap between", (a.x - (b.x + b.width) - (b.x - (c.x + c.width))).abs < 0.5)
			assert ("spare width at the left", c.x > r.x + 1.0)
		end

	test_a_wrapping_row_starts_each_line_at_the_right
		local
			w: SW_WINDOW
			r: SW_ROW
			a, b: SW_BUTTON
		do
			create w.make ("rtl", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create r.make
			r.set_wrapping (True)
			create a.make ("first", agent do end)
			create b.make ("second", agent do end)
			r.put (a)
			r.put (b)
			r.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.set_root (r)
			w.request_render
			assert ("flush right", (a.x + a.width - (r.x + r.width)).abs < 0.5)
			assert ("the second to its left", b.x + b.width <= a.x)
		end

	test_a_start_aligned_button_moves_to_the_right_edge
			-- MACMINI's test: start is the left in left-to-right and the right in right-to-left.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			s, e, f: SW_BUTTON
			l_left, l_right: REAL_64
		do
			create w.make ("rtl", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create col.make
			create s.make ("start", agent do end)
			create e.make ("end", agent do end)
			create f.make ("fill", agent do end)
			s.set_cross_alignment ({SW_WIDGET}.Place_start)
			e.set_cross_alignment ({SW_WIDGET}.Place_end)
			col.put (s)
			col.put (e)
			col.put (f)
			w.set_root (col)
			w.request_render
			l_left := f.x
			l_right := f.x + f.width
			assert ("start is the left", (s.x - l_left).abs < 0.5)
			assert ("natural width", s.width < f.width)
			assert ("end is the right", (e.x + e.width - l_right).abs < 0.5)
			col.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.request_render
			assert ("start is now the right", (s.x + s.width - l_right).abs < 0.5)
			assert ("end is now the left", (e.x - l_left).abs < 0.5)
			assert ("fill still fills", (f.x - l_left).abs < 0.5 and (f.x + f.width - l_right).abs < 0.5)
		end

	test_a_grid_mirrors_its_columns
		local
			w: SW_WINDOW
			g: SW_GRID
			a, b: SW_LABEL
		do
			create w.make ("rtl", 0, 0, 600, 200, create {SW_THEME}.make_light)
			create g.make
			create a.make_ui ("column one")
			create b.make_ui ("two")
			g.put (a, 1, 1)
			g.put (b, 1, 2)
			g.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.set_root (g)
			w.request_render
			assert ("column one is at the right", (a.x + a.width - (g.x + g.width)).abs < 0.5)
			assert ("column two to its left", b.x + b.width <= a.x)
		end

	test_direction_is_inherited_unless_set
		local
			w: SW_WINDOW
			outer: SW_COLUMN
			inner_rtl, inner_ltr: SW_ROW
			a, b, c, d: SW_BUTTON
		do
			create w.make ("rtl", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create outer.make
			create inner_rtl.make
			create inner_ltr.make
			create a.make ("a", agent do end)
			create b.make ("b", agent do end)
			create c.make ("c", agent do end)
			create d.make ("d", agent do end)
			inner_rtl.put (a)
			inner_rtl.put (b)
			inner_ltr.put (c)
			inner_ltr.put (d)
			inner_ltr.set_layout_direction ({SW_WIDGET}.Layout_left_to_right)
			outer.put (inner_rtl)
			outer.put (inner_ltr)
			outer.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.set_root (outer)
			w.request_render
			assert ("the child inherits", inner_rtl.mirrors_layout and a.mirrors_layout)
			assert ("so it places from the right", a.x > b.x)
			assert ("its own setting wins", not inner_ltr.mirrors_layout and c.x < d.x)
			assert ("left to right at the root by default", not (create {SW_ROW}.make).mirrors_layout)
		end

	test_a_row_child_can_sit_at_the_bottom
		local
			w: SW_WINDOW
			r: SW_ROW
			a: SW_BUTTON
		do
			create w.make ("rtl", 0, 0, 600, 200, create {SW_THEME}.make_light)
			create r.make
			create a.make ("down", agent do end)
			a.set_cross_alignment ({SW_WIDGET}.Place_end)
			r.put (a)
			w.set_root (r)
			w.request_render
			assert ("bottom edge", (a.y + a.height - (r.y + r.height)).abs < 0.5)
		end

end
