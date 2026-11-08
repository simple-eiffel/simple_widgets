note
	description: "W8: neutral shortcuts, edit commands to the focused widget, relabeled menu titles."

class
	SW_MENU_W8_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_neutral_shortcuts_parse
		local
			s: SW_SHORTCUT
		do
			create s.make ("primary+O")
			assert ("O with Control", s.vk = 79 and s.has_control and not s.has_shift and not s.has_alt)
			assert_strings_equal ("shown", "Ctrl+O", s.display_text)
			create s.make ("primary+shift+z")
			assert ("Z with Control and Shift", s.vk = 90 and s.has_control and s.has_shift)
			assert_strings_equal ("shown in order", "Ctrl+Shift+Z", s.display_text)
			create s.make ("alt+F4")
			assert ("Alt+F4", s.vk = 115 and s.has_alt)
			create s.make ("F5")
			assert ("a bare function key is registrable", s.vk = 116 and s.is_registrable)
			create s.make ("ctrl+Delete")
			assert_strings_equal ("named keys", "Ctrl+Del", s.display_text)
			create s.make ("primary+plus")
			assert ("plus", s.vk = 0xBB)
			create s.make ("K")
			assert ("a bare letter is not registrable", s.is_valid and not s.is_registrable)
			create s.make ("bogus+K")
			assert ("an unknown modifier", not s.is_valid)
			create s.make ("primary+")
			assert ("no key", not s.is_valid)
			create s.make ("")
			assert ("empty", not s.is_valid)
		end

	test_a_registered_shortcut_runs_its_action
		local
			w: SW_WINDOW
			l_count: CELL [INTEGER]
		do
			create l_count.put (0)
			create w.make ("w8", 0, 0, 400, 200, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make_ui ("x"))
			w.register_shortcut ("primary+O", agent (c: CELL [INTEGER]) do c.put (c.item + 1) end (l_count))
			w.simulate_key_down (79, True, False, False)
			assert_integers_equal ("ran once", 1, l_count.item)
			w.simulate_key_down (79, False, False, False)
			assert_integers_equal ("not without Control", 1, l_count.item)
		end

	test_edit_commands_reach_the_focused_text_box
		local
			w: SW_WINDOW
			col: SW_COLUMN
			tb: SW_TEXT_BOX
			ro: SW_TEXT_BOX
		do
			create w.make ("w8", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create col.make
			create tb.make_single_line ("")
			create ro.make_single_line ("read only")
			ro.set_read_only (True)
			col.put (tb)
			col.put (ro)
			w.set_root (col)
			w.request_render
			assert ("nothing focused: nothing to edit", not w.can_edit_focused ({SW_WIDGET}.Edit_select_all))
			w.give_focus (tb)
			tb.handle_char (('a').code)
			tb.handle_char (('b').code)
			assert ("undo is possible", w.can_edit_focused ({SW_WIDGET}.Edit_undo))
			w.edit_focused ({SW_WIDGET}.Edit_undo)
			assert ("undone", tb.text.count < 2)
			tb.set_text ("hello")
			assert ("no selection: no cut", not w.can_edit_focused ({SW_WIDGET}.Edit_cut))
			w.edit_focused ({SW_WIDGET}.Edit_select_all)
			assert ("all selected", tb.has_selection and tb.selected_text.same_string ("hello"))
			assert ("now cut is possible", w.can_edit_focused ({SW_WIDGET}.Edit_cut))
			w.give_focus (ro)
			ro.select_all
			assert ("a read-only box copies", w.can_edit_focused ({SW_WIDGET}.Edit_copy))
			assert ("but does not cut", not w.can_edit_focused ({SW_WIDGET}.Edit_cut))
			assert ("nor paste", not w.can_edit_focused ({SW_WIDGET}.Edit_paste))
		end

	test_a_menu_title_is_relabeled
		local
			bar: SW_MENU_BAR
			l_built: CELL [INTEGER]
		do
			create l_built.put (0)
			create bar.make
			bar.add_menu ("&File", agent (c: CELL [INTEGER]): SW_MENU do c.put (c.item + 1); create Result.make end (l_built))
			bar.set_title (1, "קו&בץ")
			assert_strings_equal ("plain title", "קובץ", bar.labels.i_th (1))
			assert_strings_equal ("as declared", "קו&בץ", bar.raw_labels.i_th (1))
			assert ("the builder stays", bar.builders.i_th (1).item ([]) /= Void and l_built.item = 1)
		end

end
