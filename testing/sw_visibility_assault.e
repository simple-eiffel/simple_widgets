note
	description: "W4b: a hidden widget is absent from layout, drawing, hit tests and the accessibility tree."

class
	SW_VISIBILITY_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_a_hidden_child_leaves_no_gap_in_a_row
		local
			w: SW_WINDOW
			r: SW_ROW
			a, b, c: SW_BUTTON
			l_with, l_b_x: REAL_64
		do
			create w.make ("hide", 0, 0, 600, 200, create {SW_THEME}.make_light)
			create r.make
			create a.make ("one", agent do end)
			create b.make ("two", agent do end)
			create c.make ("three", agent do end)
			r.put (a)
			r.put (b)
			r.put (c)
			w.set_root (r)
			w.request_render
			l_with := c.x
			l_b_x := b.x
			b.set_visible (False)
			w.request_render
			assert ("hidden", not b.is_visible)
			assert ("no extent", b.width = 0.0 and b.height = 0.0)
			assert ("the third takes the second's place", (c.x - l_b_x).abs < 0.5)
			assert ("not hit", r.widget_at (l_b_x + 1.0, b.y + 1.0) /= b)
			b.set_visible (True)
			w.request_render
			assert ("back in place", (c.x - l_with).abs < 0.5)
		end

	test_a_hidden_child_leaves_no_gap_in_a_column
		local
			w: SW_WINDOW
			col: SW_COLUMN
			a, b, c: SW_LABEL
			l_with: REAL_64
		do
			create w.make ("hide", 0, 0, 400, 400, create {SW_THEME}.make_light)
			create col.make
			create a.make_ui ("one")
			create b.make_ui ("two")
			create c.make_ui ("three")
			col.put (a)
			col.put (b)
			col.put (c)
			w.set_root (col)
			w.request_render
			l_with := c.y
			b.set_visible (False)
			w.request_render
			assert ("the third moves up", c.y < l_with)
		end

	test_a_hidden_widget_is_not_published
		local
			w: SW_WINDOW
			col: SW_COLUMN
			a, b: SW_LABEL
		do
			create w.make ("hide", 0, 0, 400, 400, create {SW_THEME}.make_light)
			create col.make
			create a.make_ui ("shown")
			create b.make_ui ("hidden")
			col.put (a)
			col.put (b)
			b.set_visible (False)
			w.set_root (col)
			w.request_render
			w.publish_accessibility
			assert ("the shown one is published", w.accessible_id_of (a) > 0)
			assert_integers_equal ("the hidden one is not", 0, w.accessible_id_of (b))
		end

	test_a_hidden_grid_cell_takes_no_width
		local
			w: SW_WINDOW
			g: SW_GRID
			a, b, c: SW_LABEL
			l_with: REAL_64
		do
			create w.make ("hide", 0, 0, 600, 200, create {SW_THEME}.make_light)
			create g.make
			g.set_gaps (10.0, 10.0)
			create a.make_ui ("a")
			create b.make_ui ("a very wide middle caption")
			create c.make_ui ("c")
			g.put (a, 1, 1)
			g.put (b, 1, 2)
			g.put (c, 1, 3)
			w.set_root (g)
			w.request_render
			l_with := c.x
			b.set_visible (False)
			w.request_render
			assert ("column 3 moves left", c.x < l_with)
			assert ("by the whole column and one gap", (c.x - (a.x + a.width + 10.0)).abs < 0.5)
			assert ("the hidden cell has no extent", b.width = 0.0)
		end

	test_hiding_the_focused_widget_passes_the_focus_on
			-- MACMINI's review: keystrokes must not go to an invisible box.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			t1, t2, t3: SW_TEXT_BOX
			fs: ARRAYED_LIST [SW_WIDGET]
		do
			create w.make ("hide", 0, 0, 400, 400, create {SW_THEME}.make_light)
			create col.make
			create t1.make_single_line ("")
			create t2.make_single_line ("")
			create t3.make_single_line ("")
			col.put (t1)
			col.put (t2)
			col.put (t3)
			w.set_root (col)
			w.request_render
			w.give_focus (t2)
			t2.set_visible (False)
			w.request_render
			assert ("the hidden box let go", not t2.is_focused)
			assert ("the next one has it", t3.is_focused and w.focused = t3)
			create fs.make (3)
			col.focusables (fs)
			assert_integers_equal ("the hidden box left the Tab ring", 2, fs.count)
			t3.set_visible (False)
			w.request_render
			assert ("wraps to the first", t1.is_focused)
			t1.set_visible (False)
			w.request_render
			assert ("none left: no focus", w.focused = Void)
		end

	test_a_key_after_hiding_reaches_the_next_widget
			-- MACMINI's follow-up: a key queued before the next render must not reach the
			-- hidden box.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			t1, t2: SW_TEXT_BOX
		do
			create w.make ("hide", 0, 0, 400, 400, create {SW_THEME}.make_light)
			create col.make
			create t1.make_single_line ("")
			create t2.make_single_line ("")
			col.put (t1)
			col.put (t2)
			w.set_root (col)
			w.request_render
			w.give_focus (t1)
			t1.set_visible (False)
			w.dispatch ({SHELL_EVENTS}.Event_window_char, ('x').code, 0)
			assert ("the key went to the next box", w.focused = t2 and not t1.is_focused)
			assert ("the hidden box typed nothing", t1.text.is_empty)
			assert_strings_equal ("the next box has it", "x", t2.text)
		end

end
