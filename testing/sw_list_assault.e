note
	description: "[
		Assault on SW_LIST's virtualization math: scrolling before
		layout (the postcondition kill of 2026-08-22), row addressing
		at the edges, selection under shrinkage, wheel clamping,
		activation and per-row pebbles.
	]"

class
	SW_LIST_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_prelayout_scroll_regression
			-- scroll_to_row before any layout killed the file dialog;
			-- it must degrade honestly now.
		local
			l: SW_LIST
		do
			create l.make (150.0)
			l.set_row_count (100)
			l.scroll_to_row (1)
			assert ("topped", l.scroll_y = 0.0)
			l.scroll_to_row (50)
			assert ("positioned by arithmetic", l.scroll_y = 49.0 * l.row_height)
		end

	test_row_at_bounds
		local
			l: SW_LIST
		do
			create l.make (150.0)
			l.set_row_count (100)
			l.set_bounds (0.0, 0.0, 300.0, 150.0)
			assert_integers_equal ("first pixel is row 1", 1, l.row_at (0.0))
			assert_integers_equal ("last viewport pixel is row 5", 5, l.row_at (149.0))
			assert_integers_equal ("beyond content is nothing", 0, l.row_at (100.0 * l.row_height + 5.0))
			assert_integers_equal ("above the widget is nothing", 0, l.row_at (-1.0))
		end

	test_shrink_count_clears_selection
		local
			l: SW_LIST
		do
			create l.make (150.0)
			l.set_row_count (100)
			l.select_row (50)
			assert_integers_equal ("selected", 50, l.selected_index)
			l.set_row_count (10)
			assert_integers_equal ("selection cleared by shrink", 0, l.selected_index)
		end

	test_wheel_clamps
		local
			l: SW_LIST
			i: INTEGER
		do
			create l.make (150.0)
			l.set_row_count (20)
			l.set_bounds (0.0, 0.0, 300.0, 150.0)
			from i := 1 until i > 50 loop
				if l.handle_wheel (-120) then end
				i := i + 1
			end
			assert ("bottom clamped", l.scroll_y <= l.max_scroll)
			from i := 1 until i > 100 loop
				if l.handle_wheel (120) then end
				i := i + 1
			end
			assert ("top clamped", l.scroll_y >= 0.0)
		end

	test_double_click_activates
		local
			l: SW_LIST
		do
			create l.make (150.0)
			l.set_row_count (10)
			l.set_bounds (0.0, 0.0, 300.0, 150.0)
			l.set_on_activate (agent record_activation)
			activated := 0
			if l.handle_double_click (50.0, 45.0) then end
			assert_integers_equal ("row 2 activated", 2, activated)
			assert_integers_equal ("row 2 selected too", 2, l.selected_index)
		end

	test_row_pebble_offer
		local
			l: SW_LIST
		do
			create l.make (150.0)
			l.set_row_count (10)
			l.set_bounds (0.0, 0.0, 300.0, 150.0)
			l.set_row_pebble (agent pebble_for)
			assert ("row 3 offers its pebble",
				attached {STRING_32} l.pebble_at (50.0, 75.0) as s and then s.same_string_general ("pebble-3"))
			assert ("scrollbar offers nothing", l.pebble_at (295.0, 75.0) = Void)
			assert ("beyond content offers nothing", l.pebble_at (50.0, 400.0) = Void)
		end

feature {NONE} -- Recording

	activated: INTEGER

	record_activation (a_i: INTEGER)
		do
			activated := a_i
		end

	pebble_for (a_i: INTEGER): detachable ANY
		do
			Result := {STRING_32} "pebble-" + a_i.out
		end

end
