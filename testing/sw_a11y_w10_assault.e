note
	description: "W10: accessible descriptions, the shared role names, and the tree as simple_gui reads it."

class
	SW_A11Y_W10_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_the_tree_reads_in_the_shared_vocabulary
		local
			w: SW_WINDOW
			col: SW_COLUMN
			b: SW_BUTTON
			tb: SW_TEXT_BOX
			l: SW_TEXT_LIST
			l_tree: STRING_32
		do
			create w.make ("Shared", 0, 0, 400, 400, create {SW_THEME}.make_light)
			create col.make
			create b.make ("Save", agent do end)
			create tb.make_single_line ("")
			tb.set_accessible_name ("Name")
			create l.make (120.0)
			l.extend ("one")
			col.put (b)
			col.put (tb)
			col.put (l)
			w.set_root (col)
			w.request_render
			l_tree := w.describe_accessibility
			assert ("the window: " + l_tree.to_string_8, l_tree.has_substring ("application: Shared"))
			assert ("button read", l_tree.has_substring ("button: Save"))
			assert ("field named", l_tree.has_substring ("text-box: Name"))
			assert ("list read", l_tree.has_substring ("list:"))
			assert ("its row", l_tree.has_substring ("list-item: one"))
			assert ("rows sit deeper than their list", l_tree.has_substring ("  list-item: one"))
			assert ("panes are left out", not l_tree.has_substring ("generic"))
		end

	test_a_description_is_published
		local
			w: SW_WINDOW
			b: SW_BUTTON
			i: INTEGER
			l_found: BOOLEAN
		do
			create w.make ("w10", 0, 0, 400, 200, create {SW_THEME}.make_light)
			create b.make ("Plot", agent do end)
			b.set_accessible_description ("Draws the function")
			w.set_root (b)
			w.request_render
			w.publish_accessibility
			from i := 1 until i > w.accessibility.served_rows loop
				if w.accessibility.served_name (i).same_string ("Plot") then
					l_found := w.accessibility.served_description (i).same_string ("Draws the function")
				end
				i := i + 1
			end
			assert ("served as the description", l_found)
		end

	test_role_names
		local
			a: SW_ACCESSIBILITY
		do
			create a
			assert_strings_equal ("button", "button", a.role_name (a.Role_button))
			assert_strings_equal ("edit", "text-box", a.role_name (a.Role_edit))
			assert_strings_equal ("text", "label", a.role_name (a.Role_text))
			assert_strings_equal ("check box", "checkbox", a.role_name (a.Role_check_box))
			assert_strings_equal ("image", "img", a.role_name (a.Role_image))
			assert_strings_equal ("pane", "generic", a.role_name (a.Role_pane))
		end

end
