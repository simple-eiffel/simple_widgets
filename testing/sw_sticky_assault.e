note
	description: "[
		Sections and sticky headers (simple_gui 1y-e): a list's and a data grid's section
		headers take slots but are not rows, the header of the section at the top stays
		pinned and is pushed up by the next as it arrives, a filter leaves only the shown
		sections' headers; a scroll area's sticky child stays at the top of the viewport
		while its part of the column is in view, CSS's position: sticky.
	]"

class
	SW_STICKY_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_list_headers_take_slots_not_rows
			-- Headers sit above their sections' first rows; row numbers, the count and keyboard
			-- moves stay the rows'; the pinned header is pushed up and gives way exactly at the top.
		local
			l: SW_TEXT_LIST
			i: INTEGER
		do
			create l.make (120.0)
			from i := 1 until i > 5 loop
				l.extend ("apple " + i.out)
				i := i + 1
			end
			from i := 6 until i > 10 loop
				l.extend ("berry " + i.out)
				i := i + 1
			end
			l.set_sections (starts_of (<<1, 6>>), titles_of (<<"A", "B">>))
			l.set_bounds (0.0, 0.0, 200.0, 4 * l.row_height)
			assert_integers_equal ("rows only", 10, l.shown_count)
			assert_integers_equal ("two headers", 2, l.sections.header_count)
			assert_reals_equal ("headers add height", 12 * l.row_height, l.content_height, 0.001)
			assert_integers_equal ("a header is no row", 0, l.row_at (l.row_height / 2.0))
			assert_integers_equal ("row 1 under its header", 1, l.row_at (l.row_height * 1.5))
			assert_reals_equal ("row 6 below two headers", 7 * l.row_height, l.position_top (6), 0.001)
			l.draw (painter)
			assert_integers_equal ("at the top, A pinned", 1, l.pinned_section)
			assert_reals_equal ("at its place", 0.0, l.pinned_offset, 0.001)
				-- three rows a notch: 90, then 60, then 15
			if l.handle_wheel (-120) then end
			if l.handle_wheel (-80) then end
			if l.handle_wheel (-20) then end
			assert_reals_equal ("half a row before B's header", 5.5 * l.row_height, l.scroll_y, 0.001)
			assert_integers_equal ("A still pinned", 1, l.pinned_section)
			assert_reals_equal ("pushed up by half", -0.5 * l.row_height, l.pinned_offset, 0.001)
			l.draw (painter)
			if l.handle_wheel (-20) then end
			assert_integers_equal ("B takes over at the top", 2, l.pinned_section)
			assert_reals_equal ("pinned at 0", 0.0, l.pinned_offset, 0.001)
			l.select_row (5)
			l.handle_key (40, False)
			assert_integers_equal ("the down arrow steps over the header", 6, l.selected_index)
			l.set_filter_text ("berry")
			assert_integers_equal ("filtered: B's header only", 1, l.sections.header_count)
			assert_integers_equal ("its section", 2, l.sections.header_section (1))
			assert_integers_equal ("shown rows", 5, l.shown_count)
			l.set_filter_text ("")
			l.set_sticky_headers (False)
			assert_integers_equal ("not sticky: nothing pinned", 0, l.pinned_section)
			l.set_sections (starts_of (<<1, 6, 11>>), titles_of (<<"A", "B", "C">>))
			assert_integers_equal ("C waits for its row", 2, l.sections.header_count)
			l.extend ("cherry 11")
			assert_integers_equal ("C's header with its row", 3, l.sections.header_count)
		end

	test_grid_headers_pin_below_the_titles
			-- A data grid's sections: header slots answer no view row, the pinned header is pushed
			-- up below the column titles, and the view's filter leaves only shown sections.
		local
			g: SW_DATA_GRID [ARRAY [STRING_32]]
			l_row: ARRAY [STRING_32]
			i: INTEGER
		do
			create g.make (150.0)
			g.add_column (create {SW_GRID_COLUMN [ARRAY [STRING_32]]}.make ("Name", 150.0,
				agent (a_row: ARRAY [STRING_32]): STRING_32 do Result := a_row [1] end))
			from i := 1 until i > 10 loop
				create l_row.make_filled ({STRING_32} "", 1, 1)
				l_row [1] := ("item " + i.out).to_string_32
				g.add_row (l_row)
				i := i + 1
			end
			g.set_sections (starts_of (<<1, 6>>), titles_of (<<"First", "Second">>))
			g.set_bounds (0.0, 0.0, 300.0, g.Header_h + 4 * g.Row_h)
			assert_integers_equal ("rows only", 10, g.shown_count)
			assert_integers_equal ("first header slot", 0, g.view_row_at (g.Header_h + 5.0))
			assert_integers_equal ("row 1", 1, g.view_row_at (g.Header_h + g.Row_h + 5.0))
			assert_integers_equal ("second header slot", 0, g.view_row_at (g.Header_h + 6 * g.Row_h + 5.0))
			assert_integers_equal ("row 6", 6, g.view_row_at (g.Header_h + 7 * g.Row_h + 5.0))
			g.draw (painter)
			assert_integers_equal ("First pinned", 1, g.pinned_section)
				-- 78 a notch, then 39, 26, 13
			if g.handle_wheel (-120) then end
			if g.handle_wheel (-60) then end
			if g.handle_wheel (-40) then end
			assert_integers_equal ("First still pinned", 1, g.pinned_section)
			assert_reals_equal ("pushed up by half a row", -0.5 * g.Row_h, g.pinned_offset, 0.001)
			g.draw (painter)
			if g.handle_wheel (-20) then end
			assert_integers_equal ("Second at the top", 2, g.pinned_section)
			assert_reals_equal ("pinned at 0", 0.0, g.pinned_offset, 0.001)
			g.set_shown_models (<<6, 7>>)
			assert_integers_equal ("one header left", 1, g.sections.header_count)
			assert_integers_equal ("two rows and a header", 3, g.sections.slot_count)
		end

	test_scroll_area_sticky_child
			-- A sticky child stays at the top while its part is in view, the next pushes it up
			-- and takes over, it takes the pointer where drawn, and not sticky it scrolls.
		local
			sa: SW_SCROLL_AREA
			col: SW_COLUMN
			a, b: SW_LABEL
			i: INTEGER
			l_b_top: REAL_64
		do
			create col.make
			create a.make_ui ("Part A")
			col.put (a)
			from i := 1 until i > 20 loop
				col.put (create {SW_LABEL}.make_ui ("A line " + i.out))
				i := i + 1
			end
			create b.make_ui ("Part B")
			col.put (b)
			from i := 1 until i > 20 loop
				col.put (create {SW_LABEL}.make_ui ("B line " + i.out))
				i := i + 1
			end
			create sa.make (150.0)
			sa.set_child (col)
			sa.set_sticky (a, True)
			sa.set_sticky (b, True)
			assert ("lifted", a.is_lifted and b.is_lifted)
			sa.set_bounds (0.0, 0.0, 300.0, 150.0)
			sa.arrange (painter)
			assert ("at the top, A", sa.pinned_sticky = a)
			l_b_top := b.y - col.y
			assert ("B below the viewport", l_b_top > 150.0)
			sa.scroll_to (40.0)
			sa.arrange (painter)
			assert ("A stays at the top", sa.pinned_sticky = a and a.y = sa.y)
			assert_reals_equal ("pinned at 0", 0.0, sa.pinned_offset, 0.001)
			sa.draw (painter)
			sa.scroll_to (l_b_top - a.height / 2.0)
			sa.arrange (painter)
			assert ("A pushed up", sa.pinned_sticky = a and sa.pinned_offset < 0.0 and a.y < sa.y)
			sa.scroll_to (l_b_top)
			sa.arrange (painter)
			assert ("B takes over", sa.pinned_sticky = b and b.y = sa.y)
			assert_reals_equal ("B pinned at 0", 0.0, sa.pinned_offset, 0.001)
			assert ("B takes the pointer where drawn", sa.widget_at (5.0, sa.y + 2.0) = b)
			sa.set_sticky (b, False)
			sa.scroll_to (sa.max_scroll)
			sa.arrange (painter)
			assert ("B scrolls again", not b.is_lifted and not sa.is_sticky (b))
			assert ("A to the end of the column", sa.pinned_sticky = a and a.y = sa.y)
			sa.set_child (create {SW_COLUMN}.make)
			assert ("a new content, none sticky", sa.sticky_children.is_empty and not a.is_lifted)
		end

feature {NONE} -- Fixture

	starts_of (a_starts: ARRAY [INTEGER]): ARRAYED_LIST [INTEGER]
		do
			create Result.make_from_array (a_starts)
		end

	titles_of (a_titles: ARRAY [STRING]): ARRAYED_LIST [STRING_32]
		do
			create Result.make (a_titles.count)
			across a_titles as ic loop
				Result.extend (ic.to_string_32)
			end
		end

	painter: SW_PAINTER
			-- One headless painter for every test.
		local
			l_surface: CAIRO_SURFACE
			l_context: CAIRO_CONTEXT
		once
			create l_surface.make (800, 600)
			create l_context.make (l_surface)
			create Result.make (l_context, create {SW_THEME}.make_light)
		end

end
