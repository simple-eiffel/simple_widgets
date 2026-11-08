note
	description: "W4c-1: right-to-left layout mirrors rows, columns and grids; direction is inherited."

class
	SW_RTL_LAYOUT_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

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
