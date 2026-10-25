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

feature -- Scan 13 (since fc84965)

	test_scan13_ids_survive_an_insert
			-- HIGH 3: node ids were tree positions, so widgets added before a
			-- text box shifted its id and a screen reader's focus request
			-- reached the wrong widget. Ids are the widgets' own now.
		local
			w: SW_WINDOW
			col, inner: SW_COLUMN
			tx: SW_TEXT_BOX
			l_id: INTEGER
		do
			create w.make ("gw14", 0, 0, 600, 400, create {SW_THEME}.make_light)
			create col.make
			create inner.make
			create tx.make_single_line ("note")
			col.add (inner).do_nothing
			col.add (tx).do_nothing
			w.set_root (col)
			w.request_render
			l_id := w.accessible_id_of (tx)
			inner.add (create {SW_LABEL}.make_ui ("one")).do_nothing
			inner.add (create {SW_LABEL}.make_ui ("two")).do_nothing
			w.request_render
			w.publish_accessibility
			assert_integers_equal ("the text box keeps its id", l_id, w.accessible_id_of (tx))
			w.dispatch ({SW_ACCESSIBILITY}.Event_focus_request, l_id, 0)
			assert_true ("a request by that id focuses the text box", w.focused = tx)
		end

	test_scan13_the_focus_is_told_once
			-- HIGH 4: every publish told UI Automation the focus again, so a
			-- listening reader heard it on every frame.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			tx: SW_TEXT_BOX
			l_told: INTEGER
		do
			create w.make ("gw14", 0, 0, 600, 400, create {SW_THEME}.make_light)
			create col.make
			create tx.make_single_line ("note")
			col.add (tx).do_nothing
			w.set_root (col)
			w.request_render
			w.give_focus (tx)
			w.publish_accessibility
			l_told := w.accessible_focus_tellings
			w.publish_accessibility
			w.publish_accessibility
			assert_integers_equal ("told once, not on every publish", l_told, w.accessible_focus_tellings)
		end

	test_scan13_a_request_republishes
			-- HIGH 2: a window renders only on input, so a reader that asked
			-- later was served a stale tree. A request (event 59) republishes.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			b: SW_BUTTON
		do
			create w.make ("gw14", 0, 0, 600, 400, create {SW_THEME}.make_light)
			create col.make
			create b.make ("Search", Void)
			col.add (b).do_nothing
			w.set_root (col)
			w.request_render
			b.set_accessible_name ("Search the Bible")
			w.dispatch ({SW_ACCESSIBILITY}.Event_refresh_request, 0, 0)
			assert_true ("the new name is served", w.accessibility.served_name (row_of (w, b)).same_string ("Search the Bible"))
		end

	test_scan13_a_dialog_is_reachable_and_modal
			-- HIGH 5: dialogs, sheets and menus were never published, and a
			-- focus request was obeyed under a modal dialog.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			tx: SW_TEXT_BOX
			d: SW_DIALOG
		do
			create w.make ("gw14", 0, 0, 600, 400, create {SW_THEME}.make_light)
			create col.make
			create tx.make_single_line ("note")
			col.add (tx).do_nothing
			w.set_root (col)
			w.request_render
			create d.make ({SW_DIALOG}.Kind_danger, "Delete the note?", "It cannot be undone.")
			d.add_button ("Delete", True, Void)
			d.add_button ("Cancel", False, Void)
			w.show_dialog (d)
			w.publish_accessibility
			assert_true ("the dialog is a window", served_has (w, "Delete the note?", {SW_ACCESSIBILITY}.Role_window))
			assert_true ("its message is read", served_has (w, "It cannot be undone.", {SW_ACCESSIBILITY}.Role_text))
			assert_true ("Delete is a button", served_has (w, "Delete", {SW_ACCESSIBILITY}.Role_button))
			assert_true ("Cancel is a button", served_has (w, "Cancel", {SW_ACCESSIBILITY}.Role_button))
			w.dispatch ({SW_ACCESSIBILITY}.Event_focus_request, tx.accessible_node_id, 0)
			assert_false ("no focus moves under the dialog", w.focused = tx)
		end

	test_scan13_closed_and_hidden_parts_are_left_out
			-- HIGH 6: a closed accordion section was published (with stale
			-- bounds); a dock zone published none of its panels. Now: open
			-- sections and shown panels only.
		local
			w: SW_WINDOW
			acc: SW_ACCORDION
			open_one, closed_one: SW_LABEL
			dh: SW_DOCK_HOST
			p1, p2: SW_LABEL
			l_ids: ARRAYED_LIST [INTEGER]
		do
			create w.make ("gw14", 0, 0, 800, 600, create {SW_THEME}.make_light)
			create acc.make
			create open_one.make_ui ("open")
			create closed_one.make_ui ("closed")
			acc.add_section ("First", open_one)
			acc.add_section ("Second", closed_one)
			w.set_root (acc)
			acc.toggle_section (2)
			w.request_render
			assert_true ("open and laid out first", acc.is_section_open (2) and closed_one.height > 0.0)
			acc.toggle_section (2)
			w.request_render
			assert_false ("the second section is closed", acc.is_section_open (2))
			assert_integers_equal ("a closed section is not published", 0, w.accessible_id_of (closed_one))
			create p1.make_ui ("Word study")
			create p2.make_ui ("Search results")
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			create l_ids.make (2)
			l_ids.extend (dh.add_panel ("Word study", p1, dh.Zone_south))
			l_ids.extend (dh.add_panel ("Search results", p2, dh.Zone_south))
			dh.set_tabbed (dh.Zone_south, True)
			dh.activate_panel (l_ids [2])
			w.set_root (dh)
			w.request_render
			w.publish_accessibility
			assert_true ("the shown panel is published", w.accessible_id_of (p2) > 0)
			assert_integers_equal ("the tab behind it is not", 0, w.accessible_id_of (p1))
		end

	test_scan13_a_real_window_is_served_once_it_opens
			-- HIGH 1: `run' rendered before the native window existed, so the
			-- only publish named no window and polling readers got nothing. A
			-- hidden, offscreen window (never shown) is served once it opens;
			-- it closes itself on its first heartbeat.
		local
			w: SW_WINDOW
			col: SW_COLUMN
		do
			create w.make ("gw14 probe", -3000, -3000, 300, 200, create {SW_THEME}.make_light)
			w.set_starts_hidden (True)
			create col.make
			col.add (create {SW_BUTTON}.make ("Search", Void)).do_nothing
			w.set_root (col)
			served_its_window := False
			w.set_on_tick (agent (a_w: SW_WINDOW)
				do
					served_its_window := a_w.hwnd /= default_pointer and then a_w.accessibility.served_window = a_w.hwnd
					a_w.close
				end (w))
			w.run
			assert_true ("served for its own window once open", served_its_window)
		end

feature {NONE} -- Fixtures

	served_its_window: BOOLEAN

	served_has (a_window: SW_WINDOW; a_name: STRING; a_role: INTEGER): BOOLEAN
			-- Is a row named `a_name' of `a_role' served?
		local
			r: INTEGER
		do
			from r := 1 until r > a_window.accessibility.served_rows or Result loop
				Result := a_window.accessibility.served_name (r).same_string (a_name) and a_window.accessibility.served_role (r) = a_role
				r := r + 1
			end
		end

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
