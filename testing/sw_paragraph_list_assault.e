note
	description: "[
		Assault on SW_PARAGRAPH_LIST: variable heights measured not
		guessed, virtualised painting, the selection set with its
		anchor, mutation keeping every parallel list honest, editing in
		place that reflows live and restores on cancel, and both text
		engines headless.
	]"

class
	SW_PARAGRAPH_LIST_ASSAULT

inherit
	TEST_SET_BASE

feature -- Measurement

	test_heights_follow_the_text
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (3)
			l.put_text (2, long_text)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			assert ("laid out", l.is_laid_out)
			assert ("a long paragraph is taller", l.item_height (2) > 2.0 * l.item_height (1))
			assert ("short ones match", l.item_height (1) = l.item_height (3))
			assert_reals_equal ("tops stack with the gap", l.item_top (1) + l.item_height (1) + l.item_gap, l.item_top (2), 1.0e-9)
			assert ("content is the whole stack", l.content_height = l.item_top (3) + l.item_height (3))
		end

	test_bands_add_exactly
		local
			l: SW_PARAGRAPH_LIST
			h0: REAL_64
		do
			l := filled (2)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			h0 := l.item_height (1)
			l.set_band_above (1, 24.0)
			l.set_band_below (1, 10.0)
			l.arrange (plain_painter)
			assert_reals_equal ("bands add their height", h0 + 34.0, l.item_height (1), 1.0e-9)
			assert ("the neighbour is untouched", l.item_height (2) = h0)
		end

	test_virtualisation_and_hit_test
		local
			l: SW_PARAGRAPH_LIST
			i: INTEGER
		do
			l := filled (200)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			assert ("taller than the viewport", l.content_height > 300.0)
			assert_integers_equal ("starts at the top", 1, l.first_visible)
			assert ("only a band is visible", l.last_visible < 40)
			assert_integers_equal ("first pixel is item 1", 1, l.item_at (0.0))
			assert_integers_equal ("above the widget is nothing", 0, l.item_at (-1.0))
			assert_integers_equal ("below the viewport is nothing", 0, l.item_at (300.0))
			l.scroll_to (l.max_scroll)
			l.arrange (plain_painter)
			assert_integers_equal ("scrolled to the end", 200, l.last_visible)
			assert ("the first is gone", l.first_visible > 150)
			i := l.item_at (299.0)
			assert_integers_equal ("the last pixel is the last item", 200, i)
			l.scroll_to_item (1)
			assert_integers_equal ("back to the top", 1, l.first_visible)
		end

	test_wheel_clamps
		local
			l: SW_PARAGRAPH_LIST
			i: INTEGER
		do
			l := filled (30)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			from i := 1 until i > 100 loop
				if l.handle_wheel (-120) then end
				i := i + 1
			end
			assert ("bottom clamped", l.scroll_y = l.max_scroll)
			from i := 1 until i > 200 loop
				if l.handle_wheel (120) then end
				i := i + 1
			end
			assert ("top clamped", l.scroll_y = 0.0)
		end

feature -- Selection

	test_selection_set_and_anchor
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (10)
			l.set_on_select (agent record_select)
			l.select_only (3)
			assert_integers_equal ("anchor", 3, l.selected_index)
			assert_integers_equal ("one selected", 1, l.selection_count)
			assert_integers_equal ("host told", 3, heard)
			l.toggle_select (5)
			assert ("three still in", l.is_selected (3))
			assert ("five joined", l.is_selected (5))
			assert_integers_equal ("anchor moved", 5, l.selected_index)
			l.select_range (5, 8)
			assert_integers_equal ("three plus five to eight", 5, l.selection_count)
			assert_integers_equal ("anchor kept by a range", 5, l.selected_index)
			l.toggle_select (5)
			assert_false ("five left", l.is_selected (5))
			assert_integers_equal ("indices ascend", 3, l.selected_indices.first)
			assert_integers_equal ("indices end", 8, l.selected_indices.last)
			l.clear_selection
			assert_integers_equal ("nothing", 0, l.selection_count)
			assert_integers_equal ("no anchor", 0, l.selected_index)
		end

	test_click_selects_and_keys_move
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (40)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			if l.handle_click (100.0, l.item_top (2) + 2.0) then end
			assert_integers_equal ("clicked two", 2, l.selected_index)
			l.handle_key (40, False)
			assert_integers_equal ("down", 3, l.selected_index)
			l.handle_key (35, False)
			assert_integers_equal ("end", 40, l.selected_index)
			l.arrange (plain_painter)
			assert ("scrolled to it", l.last_visible = 40)
			l.handle_key (36, False)
			assert_integers_equal ("home", 1, l.selected_index)
			l.handle_key (40, True)
			l.handle_key (40, True)
			assert_integers_equal ("shift-down grows the set", 3, l.selection_count)
			assert_integers_equal ("and moves the anchor", 3, l.selected_index)
		end

feature -- Mutation

	test_insert_remove_move_keep_lists_honest
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (5)
			l.select_only (3)
			l.insert (2, "new")
			assert_integers_equal ("six", 6, l.count)
			assert ("inserted where asked", l.text_of (2).same_string ("new"))
			assert_integers_equal ("anchor shifted down", 4, l.selected_index)
			assert ("still selected", l.is_selected (4))
			l.remove (1)
			assert_integers_equal ("five again", 5, l.count)
			assert_integers_equal ("anchor shifted up", 3, l.selected_index)
			l.move (3, 1)
			assert_integers_equal ("anchor travelled", 1, l.selected_index)
			assert ("flag travelled", l.is_selected (1))
			assert ("text travelled", l.text_of (1).same_string ("paragraph 3"))
			l.move (1, 5)
			assert_integers_equal ("anchor travelled back down", 5, l.selected_index)
			l.remove (5)
			assert_integers_equal ("removing the anchor clears it", 0, l.selected_index)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			assert ("re-measured after every change", l.is_laid_out)
			l.wipe_out
			assert_integers_equal ("empty", 0, l.count)
			assert ("nothing to lay out", l.content_height = 0.0)
		end

	test_put_text_reflows
		local
			l: SW_PARAGRAPH_LIST
			h0: REAL_64
		do
			l := filled (2)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			h0 := l.item_height (1)
			l.put_text (1, long_text)
			l.arrange (plain_painter)
			assert ("taller now", l.item_height (1) > h0)
			assert ("the second moved down", l.item_top (2) > h0 + l.item_gap)
		end

feature -- Editing

	test_edit_in_place_reflows_and_commits
		local
			l: SW_PARAGRAPH_LIST
			h0: REAL_64
		do
			l := filled (3)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			h0 := l.item_height (2)
			l.set_on_edit_change (agent record_change)
			l.set_on_edit_commit (agent record_commit)
			l.begin_edit (2)
			assert ("editing", l.is_editing)
			assert_integers_equal ("on two", 2, l.editing_index)
			assert_integers_equal ("selected it", 2, l.selected_index)
			assert ("the editor has the text", attached l.editor as e and then e.text.same_string ("paragraph 2"))
			l.arrange (plain_painter)
			assert ("editor seated inside the item", attached l.editor as e2 and then
				e2.y + e2.Pad_y >= l.item_top (2) and then e2.x < 100.0)
			assert ("widget_at finds the editor", attached l.editor as e3 and then
				l.widget_at (e3.x + 5.0, e3.y + 5.0) = e3)
				-- type a long tail through the list's own key door
			type_into (l, " tail")
			assert ("the item followed the keystrokes, at the END", l.text_of (2).same_string ("paragraph 2 tail"))
			type_into (l, long_text)
			assert ("host heard live", heard_change > 0)
			l.arrange (plain_painter)
			assert ("and it reflowed taller", l.item_height (2) > h0)
			l.end_edit (True)
			assert_false ("down", l.is_editing)
			assert ("host got the commit", committed.count > 20)
			assert ("editor gone", l.editor = Void)
		end

	test_edit_cancel_restores
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (2)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			l.begin_edit (1)
			type_into (l, " changed")
			assert ("changed while editing", l.text_of (1).same_string ("paragraph 1 changed"))
			l.handle_char (27)
			assert_false ("escape ended it", l.is_editing)
			assert ("and restored the text", l.text_of (1).same_string ("paragraph 1"))
		end

	test_click_elsewhere_commits
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (3)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			l.set_on_edit_commit (agent record_commit)
			l.begin_edit (1)
			type_into (l, "!")
			if l.handle_click (100.0, l.item_top (3) + 2.0) then end
			assert_false ("edit ended by the click", l.is_editing)
			assert ("committed", committed.same_string ("paragraph 1!"))
			assert_integers_equal ("and the click selected", 3, l.selected_index)
		end

	test_remove_while_editing_drops_editor
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (3)
			l.begin_edit (2)
			l.remove (2)
			assert_false ("editor dropped", l.is_editing)
			assert_integers_equal ("two left", 2, l.count)
		end

feature -- Shaped path

	test_shaped_measurement_and_paint
		local
			l: SW_PARAGRAPH_LIST
			s: STRING_32
		do
			l := filled (3)
			create s.make_from_string ("abc ")
			s.append (shalom)
			s.append ("%N")
			s.append (long_text)
			l.put_text (2, s)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.set_gutter_renderer (agent count_gutter)
			l.set_wash_of (agent wash_for)
			l.arrange (shaped_painter)
			assert ("shaped", l.is_shaped_layout)
			assert ("two pieces stack taller", l.item_height (2) > 2.5 * l.item_height (1))
			gutters := 0
			l.draw (shaped_painter)
			assert_integers_equal ("gutter drawn for each visible item", 3, gutters)
			l.arrange (plain_painter)
			assert_false ("toy again on a plain painter", l.is_shaped_layout)
			l.draw (plain_painter)
			l.begin_edit (2)
			l.arrange (shaped_painter)
			l.draw (shaped_painter)
			assert ("painted through both engines and the editor", True)
		end

	test_gutter_only_for_visible
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (200)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.set_gutter_renderer (agent count_gutter)
			l.arrange (plain_painter)
			gutters := 0
			l.draw (plain_painter)
			assert ("a band, not the world", gutters > 0 and gutters < 40)
			assert_integers_equal ("exactly the visible band", l.last_visible - l.first_visible + 1, gutters)
		end

feature {NONE} -- Helpers

	filled (a_n: INTEGER): SW_PARAGRAPH_LIST
		local
			i: INTEGER
		do
			create Result.make (300.0)
			from i := 1 until i > a_n loop
				Result.add ("paragraph " + i.out)
				i := i + 1
			end
		end

	long_text: STRING_32
		do
			Result := {STRING_32} "In one-twelve CE a Roman governor sat down to write to his emperor about a problem he could not solve. The province he had been appointed to govern had a Christianity problem. The new sect was growing. Pagan temples were emptying. Civic-religious revenues were down."
		end

	shalom: STRING_32
		do
			create Result.make (4)
			Result.append_code (0x05E9)
			Result.append_code (0x05DC)
			Result.append_code (0x05D5)
			Result.append_code (0x05DD)
		end

	type_into (a_l: SW_PARAGRAPH_LIST; a_text: READABLE_STRING_GENERAL)
			-- Every character through the list's key door, as a user
			-- typing right after a double-click would.
		local
			i: INTEGER
		do
			from i := 1 until i > a_text.count loop
				a_l.handle_char (a_text.code (i).to_integer_32)
				i := i + 1
			end
		end

	count_gutter (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		do
			gutters := gutters + 1
			a_p.set_color (a_p.theme.accent)
			a_p.fill_rect (a_x, a_y, 4.0, a_h)
		end

	wash_for (a_i: INTEGER): NATURAL_32
		do
			if a_i \\ 2 = 0 then
				Result := 0xFAF1DD
			end
		end

feature {NONE} -- Capture

	heard: INTEGER
	heard_change: INTEGER
	gutters: INTEGER

	committed: STRING_32
		attribute
			create Result.make_empty
		end

	record_select (a_i: INTEGER)
		do
			heard := a_i
		end

	record_change (a_i: INTEGER; a_text: STRING_32)
		do
			heard_change := heard_change + 1
		end

	record_commit (a_i: INTEGER; a_text: STRING_32)
		do
			committed := a_text.twin
		end

feature {NONE} -- Fixture

	plain_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (600, 400)
			create ctx.make (surf)
			create th.make_light
			create Result.make (ctx, th)
		end

	shaped_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			kit: SW_SHAPING
		once
			create surf.make (600, 400)
			create ctx.make (surf)
			create th.make_light
			create kit.make
			kit.set_theme_faces (th)
			create Result.make (ctx, th)
			Result.set_shaping (kit)
		end

end
