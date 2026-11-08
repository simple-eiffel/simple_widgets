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

	test_select_row_quietly_runs_no_agent
			-- The program's selection is silent; the user's (select_row) still reports.
		local
			l: SW_LIST
			l_count: CELL [INTEGER]
		do
			create l_count.put (0)
			create l.make (150.0)
			l.set_row_count (5)
			l.set_on_select (agent (r: INTEGER; c: CELL [INTEGER]) do c.put (c.item + 1) end (?, l_count))
			l.select_row_quietly (2)
			assert_integers_equal ("selected", 2, l.selected_index)
			assert_integers_equal ("no agent ran", 0, l_count.item)
			l.select_row (3)
			assert_integers_equal ("select_row still reports", 1, l_count.item)
			l.select_row_quietly (0)
			assert_integers_equal ("cleared", 0, l.selected_index)
		end

	test_text_list_holds_its_rows
		local
			l: SW_TEXT_LIST
		do
			create l.make (150.0)
			l.extend ("Genesis")
			l.extend ("Exodus")
			l.extend ("Leviticus")
			assert_integers_equal ("three rows", 3, l.count)
			assert_integers_equal ("row count follows", 3, l.row_count)
			assert_strings_equal ("second", "Exodus", l.i_th (2))
			l.select_row_quietly (2)
			l.wipe_out
			assert_integers_equal ("empty", 0, l.count)
			assert_integers_equal ("selection gone", 0, l.selected_index)
		end

	test_text_list_rows_are_list_items
			-- A screen reader finds each visible row as a list item, named by its text, under the list.
		local
			w: SW_WINDOW
			l: SW_TEXT_LIST
			acc: SW_ACCESSIBILITY
			i, l_items, l_list_id: INTEGER
			l_found: BOOLEAN
		do
			create w.make ("rows", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create l.make (200.0)
			l.extend ("Genesis")
			l.extend ("Exodus")
			l.extend ("Leviticus")
			w.set_root (l)
			w.request_render
			w.publish_accessibility
			acc := w.accessibility
			l_list_id := w.accessible_id_of (l)
			from i := 1 until i > acc.served_rows loop
				if acc.served_role (i) = {SW_ACCESSIBILITY}.Role_list_item then
					l_items := l_items + 1
					assert_integers_equal ("under the list", l_list_id, acc.served_parent (i))
					if acc.served_name (i).same_string ("Exodus") then
						l_found := True
					end
				end
				i := i + 1
			end
			assert_integers_equal ("three list items", 3, l_items)
			assert ("named by their text", l_found)
		end

	test_every_row_is_published_beyond_the_viewport
			-- A list longer than its viewport reports as many items as rows (AppKit and GTK
			-- do); the selected row says so.
		local
			w: SW_WINDOW
			l: SW_TEXT_LIST
			acc: SW_ACCESSIBILITY
			i, l_items: INTEGER
			l_selected_found: BOOLEAN
		do
			create w.make ("many rows", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create l.make (90.0)
			from i := 1 until i > 50 loop
				l.extend ("row " + i.out)
				i := i + 1
			end
			l.select_row_quietly (42)
			w.set_root (l)
			w.request_render
			w.publish_accessibility
			acc := w.accessibility
			from i := 1 until i > acc.served_rows loop
				if acc.served_role (i) = {SW_ACCESSIBILITY}.Role_list_item then
					l_items := l_items + 1
					if acc.served_name (i).same_string ("row 42") then
						l_selected_found := acc.served_has_value (i) and then acc.served_value (i).same_string ("selected")
					end
				end
				i := i + 1
			end
			assert_integers_equal ("items = rows", 50, l_items)
			assert ("the selected row says so", l_selected_found)
		end

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

	test_bar_drag_ends_on_release
			-- A thumb drag works anywhere down the page and ends when the
			-- button comes up.
		local
			l: SW_LIST
			l_scroll: REAL_64
		do
			create l.make (150.0)
			l.set_row_count (100)
			l.set_bounds (0.0, 0.0, 300.0, 150.0)
			assert ("the press on the thumb is taken", l.handle_click (295.0, 5.0))
			assert ("the bar is dragging", l.bar.is_dragging)
			l.handle_drag (100.0, 100.0)
			assert ("the drag scrolled, off the bar column too", l.scroll_y > 0.0)
			l.handle_release (100, 100)
			assert ("released", not l.bar.is_dragging)
			l_scroll := l.scroll_y
			l.handle_drag (100.0, 140.0)
			assert_reals_equal ("a later drag does not scroll", l_scroll, l.scroll_y, 0.0)
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
