note
	description: "[
		Assault on GW-14's UI Automation bridge, from the toolkit side: the
		table a window publishes (read back through SW_ACCESSIBILITY's
		readers - simple_shell's own test reads the same table through a
		real UI Automation client): roles, names, values, parents, a
		notebook's hidden page left out, a masked line's text never told,
		pointed Hebrew and polytonic Greek names intact, the focus told,
		a screen reader's focus request obeyed, a name given by the
		application, and nothing served when the window is not accessible.
	]"

class
	SW_ACCESSIBILITY_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- The published tree

	test_gw14_the_tree_is_published
			-- Roles, names, values and parents as the widgets describe them;
			-- the notebook publishes only its shown page; a masked line has
			-- no value.
		local
			w: SW_WINDOW
			f: like form
			acc: SW_ACCESSIBILITY
		do
			create w.make ("Study", 0, 0, 700, 600, create {SW_THEME}.make_light)
			f := form
			w.set_root (f.col)
			w.request_render
			acc := w.accessibility
			assert_true ("published", w.is_accessibility_published and acc.is_serving)
			assert_integers_equal ("one row per laid-out widget plus the window", w.accessible_widgets.count + 1, acc.served_rows)
			assert_true ("the window is node 0, named by its title",
				acc.served_id (1) = 0 and acc.served_name (1).same_string ("Study"))
			assert_role_name (w, f.lb, {SW_ACCESSIBILITY}.Role_text, "Genesis 1:1")
			assert_role_name (w, f.bt, {SW_ACCESSIBILITY}.Role_button, "Search")
			assert_role_name (w, f.tx, {SW_ACCESSIBILITY}.Role_edit, "")
			assert_true ("the text box tells its text",
				acc.served_value (row_of (w, f.tx)).same_string ("In the beginning"))
			assert_false ("a masked line tells nothing", acc.served_has_value (row_of (w, f.pw)))
			assert_true ("the check box tells it is checked",
				acc.served_value (row_of (w, f.cb)).same_string ("checked"))
			assert_true ("the notebook tells its shown tab",
				acc.served_role (row_of (w, f.tb)) = {SW_ACCESSIBILITY}.Role_tab
				and acc.served_value (row_of (w, f.tb)).same_string ("First"))
			assert_true ("the shown page is published", w.accessible_id_of (f.page_one) > 0)
			assert_integers_equal ("the hidden page is not", 0, w.accessible_id_of (f.page_two))
			assert_integers_equal ("the button sits in the column",
				w.accessible_id_of (f.col), acc.served_parent (row_of (w, f.bt)))
			assert_true ("the text box is focusable", acc.served_focusable (row_of (w, f.tx)))
			assert_false ("the label is not", acc.served_focusable (row_of (w, f.lb)))
		end

	test_gw14_scripture_names_are_intact
			-- Pointed Hebrew and polytonic Greek reach the table exactly.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			he, gr: SW_LABEL
		do
			create w.make ("gw14", 0, 0, 900, 300, create {SW_THEME}.make_light)
			create col.make
			create he.make_body (genesis_1_1_wlc)
			create gr.make_body (john_1_1_wh_nfc)
			col.add (he).do_nothing
			col.add (gr).do_nothing
			w.set_root (col)
			w.request_render
			assert_true ("Genesis 1:1 pointed, exactly", w.accessibility.served_name (row_of (w, he)).same_string (genesis_1_1_wlc))
			assert_true ("John 1:1 polytonic, exactly", w.accessibility.served_name (row_of (w, gr)).same_string (john_1_1_wh_nfc))
		end

feature -- Focus

	test_gw14_focus_is_told_and_requests_are_obeyed
			-- A click focuses the text box and UI Automation is told. A screen
			-- reader's request (event 58) to focus the label is refused (a
			-- label takes no focus); to focus the password line, obeyed.
		local
			w: SW_WINDOW
			f: like form
		do
			create w.make ("Study", 0, 0, 700, 600, create {SW_THEME}.make_light)
			f := form
			w.set_root (f.col)
			w.request_render
			w.dispatch (2, (f.tx.x + 10.0).truncated_to_integer, (f.tx.y + 10.0).truncated_to_integer)
			w.dispatch (10, (f.tx.x + 10.0).truncated_to_integer, (f.tx.y + 10.0).truncated_to_integer)
			assert_true ("the text box holds the focus", w.focused = f.tx)
			assert_integers_equal ("UI Automation was told", w.accessible_id_of (f.tx), w.accessibility.served_focus)
			w.dispatch ({SW_ACCESSIBILITY}.Event_focus_request, w.accessible_id_of (f.lb), 0)
			assert_true ("a label cannot take the focus: refused", w.focused = f.tx)
			w.dispatch ({SW_ACCESSIBILITY}.Event_focus_request, w.accessible_id_of (f.pw), 0)
			assert_true ("the password line can: obeyed", w.focused = f.pw)
			assert_integers_equal ("and UI Automation was told", w.accessible_id_of (f.pw), w.accessibility.served_focus)
		end

feature -- Naming and switching off

	test_gw14_a_given_name_and_switching_off
			-- An application-given name replaces the widget's own; a window
			-- that is not accessible serves nothing.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			b: SW_BUTTON
		do
			create w.make ("gw14", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create col.make
			create b.make ("x", Void)
			b.set_accessible_name ("Close the note")
			col.add (b).do_nothing
			w.set_root (col)
			w.request_render
			assert_true ("the given name", w.accessibility.served_name (row_of (w, b)).same_string ("Close the note"))
			w.set_accessible (False)
			assert_false ("off: nothing served", w.accessibility.is_serving)
			w.request_render
			assert_false ("and nothing after a frame", w.accessibility.is_serving)
		end

feature {NONE} -- Fixtures

	form: TUPLE [col: SW_COLUMN; lb: SW_LABEL; bt: SW_BUTTON; tx, pw: SW_TEXT_BOX; cb: SW_CHECK_BOX; tb: SW_TABS; page_one, page_two: SW_LABEL]
			-- A column: label, button, text box, password line, check box,
			-- and a notebook of two pages (the first shown).
		local
			col: SW_COLUMN
			lb: SW_LABEL
			bt: SW_BUTTON
			tx, pw: SW_TEXT_BOX
			cb: SW_CHECK_BOX
			tb: SW_TABS
			p1, p2: SW_LABEL
		do
			create col.make
			create lb.make_ui ("Genesis 1:1")
			create bt.make ("Search", Void)
			create tx.make_single_line ("In the beginning")
			create pw.make_password ("secret")
			create cb.make ("Strong's numbers", True, Void)
			create tb.make
			create p1.make_ui ("Page one")
			create p2.make_ui ("Page two")
			tb.add_page ("First", p1)
			tb.add_page ("Second", p2)
			col.add (lb).do_nothing
			col.add (bt).do_nothing
			col.add (tx).do_nothing
			col.add (pw).do_nothing
			col.add (cb).do_nothing
			col.add (tb).do_nothing
			Result := [col, lb, bt, tx, pw, cb, tb, p1, p2]
		end

	row_of (a_window: SW_WINDOW; a_widget: SW_WIDGET): INTEGER
			-- The served row of `a_widget'.
		do
			Result := a_window.accessibility.served_row_of (a_window.accessible_id_of (a_widget))
			assert_true ("the widget was published", Result > 0 and a_window.accessible_id_of (a_widget) > 0)
		end

	assert_role_name (a_window: SW_WINDOW; a_widget: SW_WIDGET; a_role: INTEGER; a_name: STRING)
		local
			r: INTEGER
		do
			r := row_of (a_window, a_widget)
			assert_integers_equal (a_name + ": role", a_role, a_window.accessibility.served_role (r))
			assert_true (a_name + ": name", a_window.accessibility.served_name (r).same_string (a_name))
		end

end
