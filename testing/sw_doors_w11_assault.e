note
	description: "W11: test doors act on the widget as a user would, with no window, focus or keystrokes."

class
	SW_DOORS_W11_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_perform_click_needs_no_window
		local
			b: SW_BUTTON
			c: SW_CHECK_BOX
			l_clicks, l_changes: CELL [INTEGER]
		do
			create l_clicks.put (0)
			create l_changes.put (0)
			create b.make ("Plot", agent (a: CELL [INTEGER]) do a.put (a.item + 1) end (l_clicks))
			b.perform_click
			assert_integers_equal ("the button reported", 1, l_clicks.item)
			b.set_enabled (False)
			b.perform_click
			assert_integers_equal ("a disabled button does not", 1, l_clicks.item)
			create c.make ("Degrees", False, Void)
			c.set_on_change (agent (a: CELL [INTEGER]) do a.put (a.item + 1) end (l_changes))
			c.perform_click
			assert ("the box toggled", c.is_checked)
			assert_integers_equal ("and reported", 1, l_changes.item)
		end

	test_type_text_reports_and_undoes
		local
			tb: SW_TEXT_BOX
			l_changes: CELL [INTEGER]
		do
			create l_changes.put (0)
			create tb.make_single_line ("")
			tb.set_on_change (agent (a: CELL [INTEGER]) do a.put (a.item + 1) end (l_changes))
			tb.set_text ("silent")
			assert_integers_equal ("set_text is silent", 0, l_changes.item)
			tb.type_text ("sin(x)")
			assert_strings_equal ("typed", "sin(x)", tb.text)
			assert ("reported", l_changes.item >= 1)
			assert ("one undo step back", tb.can_undo)
			tb.undo
			assert_strings_equal ("undone", "silent", tb.text)
			tb.type_text ("")
			assert_strings_equal ("typing nothing clears", "", tb.text)
		end

end
