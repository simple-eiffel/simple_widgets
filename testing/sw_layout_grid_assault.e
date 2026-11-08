note
	description: "W4a: SW_GRID, the layout container simple_gui's GUI_GRID uses on Windows."

class
	SW_LAYOUT_GRID_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_columns_take_their_widest_child
			-- A column is as wide as its widest single-column child; cells in a column line up.
		local
			w: SW_WINDOW
			g: SW_GRID
			a, b, c: SW_LABEL
		do
			create w.make ("grid", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create g.make
			create a.make_ui ("a")
			create b.make_ui ("a much longer caption")
			create c.make_ui ("a wider first column cell")
			g.put (a, 1, 1)
			g.put (b, 1, 2)
			g.put (c, 2, 1)
			w.set_root (g)
			w.request_render
			assert_integers_equal ("two columns", 2, g.column_count)
			assert_integers_equal ("two rows", 2, g.row_count)
			assert ("column 1 is as wide as its widest cell", (a.width - c.width).abs < 0.5)
			assert ("cells in a column line up", (a.x - c.x).abs < 0.5)
			assert ("column 2 after column 1", b.x >= a.x + a.width)
			assert ("row 2 below row 1", c.y >= a.y + a.height)
		end

	test_homogeneous_columns_are_equal
		local
			w: SW_WINDOW
			g: SW_GRID
			a, b: SW_LABEL
		do
			create w.make ("grid", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create g.make
			create a.make_ui ("a")
			create b.make_ui ("a much longer caption")
			g.set_homogeneous_columns (True)
			g.put (a, 1, 1)
			g.put (b, 1, 2)
			w.set_root (g)
			w.request_render
			assert ("equal widths", (a.width - b.width).abs < 0.5)
		end

	test_a_stretching_column_takes_the_spare_width
		local
			w: SW_WINDOW
			g: SW_GRID
			a, b: SW_LABEL
		do
			create w.make ("grid", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create g.make
			create a.make_ui ("b")
			create b.make_ui ("c")
			g.put (a, 1, 1)
			g.put (b, 1, 2)
			g.set_stretching_column (2)
			w.set_root (g)
			w.request_render
			assert ("column 2 stretches", b.width > 4.0 * a.width)
			assert ("it reaches the grid's right edge", (b.x + b.width - (g.x + g.width)).abs < 0.5)
		end

	test_a_spanning_child_covers_its_cells
			-- It takes the columns' widths and the gap between them, and does not size them.
		local
			w: SW_WINDOW
			g: SW_GRID
			a, b, l_span: SW_LABEL
		do
			create w.make ("grid", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create g.make
			create a.make_ui ("left")
			create b.make_ui ("right")
			create l_span.make_ui ("x")
			g.put (a, 1, 1)
			g.put (b, 1, 2)
			g.put_spanning (l_span, 2, 1, 1, 2)
			w.set_root (g)
			w.request_render
			assert ("starts at column 1", (l_span.x - a.x).abs < 0.5)
			assert ("ends at column 2's edge", (l_span.x + l_span.width - (b.x + b.width)).abs < 0.5)
		end

end
