note
	description: "[
		Assault on SW_DATA_GRID: typed vs text sorting, descending,
		filter composition, selection surviving re-sort, resize
		clamping, and row addressing at the edges.
	]"

class
	SW_GRID_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- Fixture

	Row_type_anchor: detachable TUPLE [name: STRING_32; size: INTEGER]

	new_grid: SW_DATA_GRID [TUPLE [name: STRING_32; size: INTEGER]]
		do
			create Result.make (200.0)
			Result.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("Name", 120.0, agent name_of))
			Result.add_column ((create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("Size", 80.0, agent size_text)).with_key (agent size_key))
			Result.add_row ([{STRING_32} "beta", 100])
			Result.add_row ([{STRING_32} "alpha", 9])
			Result.add_row ([{STRING_32} "gamma", 30])
		end

	name_of (a_r: TUPLE [name: STRING_32; size: INTEGER]): STRING_32
		do
			Result := a_r.name
		end

	size_text (a_r: TUPLE [name: STRING_32; size: INTEGER]): STRING_32
		do
			Result := a_r.size.out.to_string_32
		end

	size_key (a_r: TUPLE [name: STRING_32; size: INTEGER]): COMPARABLE
		do
			Result := a_r.size
		end

	small_only (a_r: TUPLE [name: STRING_32; size: INTEGER]): BOOLEAN
		do
			Result := a_r.size < 50
		end

feature -- Sorting

	test_text_sort_ascending
		local
			g: like new_grid
		do
			g := new_grid
			g.sort_by (1, False)
			assert ("alpha first", g.rows.i_th (g.view.i_th (1)).name.same_string_general ("alpha"))
			assert ("gamma last", g.rows.i_th (g.view.i_th (3)).name.same_string_general ("gamma"))
		end

	test_typed_sort_beats_text
			-- Text would order 100 < 30 < 9; the INTEGER key must
			-- order 9 < 30 < 100.
		local
			g: like new_grid
		do
			g := new_grid
			g.sort_by (2, False)
			assert_integers_equal ("smallest first", 9, g.rows.i_th (g.view.i_th (1)).size)
			assert_integers_equal ("largest last", 100, g.rows.i_th (g.view.i_th (3)).size)
			g.sort_by (2, True)
			assert_integers_equal ("descending flips", 100, g.rows.i_th (g.view.i_th (1)).size)
		end

feature -- Filter and selection

	test_filter_composes_with_sort
		local
			g: like new_grid
		do
			g := new_grid
			g.set_filter (agent small_only)
			g.sort_by (2, False)
			assert_integers_equal ("two survive", 2, g.view.count)
			assert_integers_equal ("nine leads", 9, g.rows.i_th (g.view.i_th (1)).size)
			g.set_filter (Void)
			assert_integers_equal ("all return", 3, g.view.count)
		end

	test_selection_survives_resort
		local
			g: like new_grid
		do
			g := new_grid
			g.select_model_row (2)
			g.sort_by (2, True)
			assert_integers_equal ("same OBJECT still selected", 2, g.selected_model)
			assert ("object is alpha", attached g.selected_object as o and then o.name.same_string_general ("alpha"))
			g.set_filter (agent small_only)
			assert_integers_equal ("survives a filter it passes", 2, g.selected_model)
		end

	test_selection_cleared_when_filtered_out
		local
			g: like new_grid
		do
			g := new_grid
			g.select_model_row (1)
			g.set_filter (agent small_only)
			assert_integers_equal ("beta was filtered away", 0, g.selected_model)
		end

	test_set_rows_snapshots_against_external_mutation
			-- Regression: a caller that shrinks its OWN list after `set_rows'
			-- (Remove, Clear Finished) must not desync the grid's `rows' from
			-- its cached `view' and trip `view_never_exceeds_rows'. The grid
			-- takes a snapshot, so the caller's later mutation cannot reach it.
		local
			g: like new_grid
			l: ARRAYED_LIST [TUPLE [name: STRING_32; size: INTEGER]]
		do
			g := new_grid
			create l.make (2)
			l.extend ([{STRING_32} "one", 1])
			l.extend ([{STRING_32} "two", 2])
			g.set_rows (l)
			assert_integers_equal ("grid took the two", 2, g.rows.count)
			assert ("grid owns a snapshot, not the caller's list", g.rows /= l)
				-- The caller shrinks its own list, as Remove/Clear Finished do.
			l.finish
			l.remove
			assert_integers_equal ("caller's list is now one", 1, l.count)
			assert_integers_equal ("grid snapshot is unaffected", 2, g.rows.count)
				-- The exact call that used to crash with the invariant violated.
			g.select_model_row (0)
			assert_integers_equal ("selection cleared without a crash", 0, g.selected_model)
			assert ("view still within rows", g.view.count <= g.rows.count)
		end

feature -- Geometry

	test_column_resize_clamps
		local
			c: SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]
		do
			create c.make ("Name", 120.0, agent name_of)
			c.set_width (10.0)
			assert ("clamped at minimum", c.width = c.Min_width)
			c.set_width (300.0)
			assert ("wide is fine", c.width = 300.0)
		end

	test_view_row_at_guards
		local
			g: like new_grid
		do
			g := new_grid
			g.set_bounds (0.0, 0.0, 400.0, 200.0)
			assert_integers_equal ("header is not a row", 0, g.view_row_at (10.0))
			assert_integers_equal ("first row", g.view.i_th (1), g.view.i_th (g.view_row_at (35.0)))
			assert_integers_equal ("beyond content", 0, g.view_row_at (5000.0))
		end

feature -- Growing columns and the divider cursor

	test_growing_column_takes_spare_width
			-- A growing column takes the grid's spare width (less the
			-- scrollbar gutter); a fixed one keeps its own; a narrow grid
			-- gives nothing extra.
		local
			g: SW_DATA_GRID [TUPLE [name: STRING_32; size: INTEGER]]
		do
			create g.make (200.0)
			g.add_column ((create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("Name", 120.0, agent name_of)).growing)
			g.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("Size", 80.0, agent size_text))
			g.set_bounds (0.0, 0.0, 400.0, 200.0)
			assert ("grows into the spare width", g.shown_width (1) = 120.0 + (400.0 - g.Scroll_gutter - 200.0))
			assert ("fixed column unchanged", g.shown_width (2) = 80.0)
			g.set_bounds (0.0, 0.0, 150.0, 200.0)
			assert ("no spare, own width", g.shown_width (1) = 120.0)
		end

	test_divider_shows_resize_cursor
			-- Over a header divider the pointer is the left-right arrow;
			-- in the body or mid-header it is the plain arrow.
		local
			g: like new_grid
		do
			g := new_grid
			g.set_bounds (0.0, 0.0, 400.0, 200.0)
			g.set_hovered (True)
			g.set_hover_point (120.0, 10.0)
			assert_integers_equal ("divider in header", 3, g.cursor_kind)
			g.set_hover_point (60.0, 10.0)
			assert_integers_equal ("mid header", 0, g.cursor_kind)
			g.set_hover_point (120.0, 100.0)
			assert_integers_equal ("divider line in body", 0, g.cursor_kind)
			g.set_hovered (False)
			g.set_hover_point (120.0, 10.0)
			assert_integers_equal ("not hovered", 0, g.cursor_kind)
		end

end
