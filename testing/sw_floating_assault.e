note
	description: "[
		Assault on GW-22: a dock panel torn off into a floating window (a
		framed simple_shell panel, real, never shown: the main window is not
		on screen in a test) by a double click on its tab, drawing its
		content in the owner's theme, taking clicks, keys, characters
		(surrogate pairs whole), Tab and the wheel as the main window does,
		honouring the owner's accelerators and modal dialogs, and docking
		again where it was when asked to close.
	]"

class
	SW_FLOATING_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Tearing off and docking

	test_gw22_double_click_floats_a_tab_and_close_docks_it
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			r1, r2: SW_TEST_RECORDER
			z: SW_DOCK_ZONE
			l_float: SW_FLOATING_WINDOW
			tx, ty: INTEGER
		do
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create r1.make
			create r2.make
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			dh.add_keyed_panel ("word", "Word study", r1, dh.Zone_south).do_nothing
			dh.add_keyed_panel ("refs", "Cross references", r2, dh.Zone_south).do_nothing
			dh.set_tabbed (dh.Zone_south, True)
			w.set_root (dh)
			w.enable_floating_panels (dh)
			w.request_render
			z := dh.zone_widget (dh.Zone_south)
			tx := (z.tab_lefts [2] + z.tab_widths [2] / 2.0).truncated_to_integer
			ty := (z.y + z.bar_h / 2.0).truncated_to_integer
			w.dispatch (2, tx, ty)
			w.dispatch (10, tx, ty)
			w.dispatch (8, tx, ty)
			assert_true ("the second panel floats", dh.is_floating (2) and not dh.is_floating (1))
			assert_false ("out of its zone", dh.is_panel_visible (2))
			assert_true ("its content let go", r2.parent = Void)
			assert_integers_equal ("one floating window", 1, w.floating_windows.count)
			l_float := w.floating_windows.first
			assert_true ("a framed panel", l_float.is_open and l_float.panel.is_framed)
			assert_true ("titled after the panel", l_float.panel.title.same_string ("Cross references"))
			assert_false ("not shown while the main window is not", l_float.panel.is_visible)
			assert_true ("found by its slot", w.floating_at (l_float.slot) = l_float)
			assert_true ("drawn", l_float.render_count > 0)
			assert_true ("its content fills the client area inside the padding",
				r2.width = l_float.client_width - 2.0 * l_float.content_inset
				and r2.height = l_float.client_height - 2.0 * l_float.content_inset)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_close_request, 0, 0)
			assert_false ("docked again", dh.is_floating (2))
			assert_true ("shown in its zone", dh.is_panel_visible (2))
			assert_true ("adopted by the host", r2.parent = dh)
			assert_true ("the window is gone", w.floating_windows.is_empty and not l_float.is_open)
		end

feature -- Scan 19

	test_scan19_an_accelerator_runs_once_from_a_floating_window
			-- Ctrl+B reaches a floating window as a key down (60) AND the
			-- control code its WM_CHAR carries (61): the toggle must run once.
		local
			w: SW_WINDOW
			r: SW_TEST_RECORDER
			l_float: SW_FLOATING_WINDOW
			l_keys: SW_KEYS
		do
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create r.make
			w.set_root (create {SW_LABEL}.make_ui ("main"))
			w.request_render
			fired := 0
			w.register_accelerator (66, True, False, False, agent do fired := fired + 1 end)
			l_float := w.float_widget (r, "Notes", -3000, -3000, 400, 300)
			create l_keys
			l_keys.simulate (False, True, False)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 66, 0)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_char, 2, 0)
			assert_integers_equal ("Ctrl+B ran once", 1, fired)
				-- Ctrl+B as a WM_CHAR alone (no key down claimed it) still runs it
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 17, 0)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_char, 2, 0)
			l_keys.stop_simulating
			assert_integers_equal ("a control code alone still runs it", 2, fired)
			w.unfloat (l_float)
		end

	test_scan19_closing_gives_the_frame_back
		local
			w: SW_WINDOW
			r: SW_TEST_RECORDER
			l_float: SW_FLOATING_WINDOW
		do
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create r.make
			w.set_root (create {SW_LABEL}.make_ui ("main"))
			w.request_render
			l_float := w.float_widget (r, "Notes", -3000, -3000, 400, 300)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_press, 20, 20)
			assert_true ("pressed", r.is_pressed)
			w.unfloat (l_float)
			assert_true ("the offscreen frame is released", l_float.is_frame_released)
			assert_false ("nothing left pressed", r.is_pressed)
		end

	test_scan19_a_floating_panel_stays_out_of_its_zone
			-- Restoring a layout, or moving the panel to another zone, while it
			-- floats must not show it in a zone as well.
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			r1, r2: SW_TEST_RECORDER
			l_snapshot: STRING_32
		do
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create r1.make
			create r2.make
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			dh.add_keyed_panel ("word", "Word study", r1, dh.Zone_south).do_nothing
			dh.add_keyed_panel ("refs", "Cross references", r2, dh.Zone_south).do_nothing
			w.set_root (dh)
			w.enable_floating_panels (dh)
			w.request_render
			l_snapshot := dh.layout_snapshot
			w.give_focus (r2)
			w.float_dock_panel (dh, 2)
			assert_true ("the main window let go of the focus inside it", w.focused = Void and not r2.is_focused)
			dh.restore_layout (l_snapshot)
			assert_true ("restored", dh.last_restore_ok)
			assert_true ("still floating, not in a zone", dh.is_floating (2) and not dh.is_panel_visible (2))
			assert_true ("its content still free", r2.parent = Void)
			dh.move_panel (2, dh.Zone_east)
			assert_false ("moved, still not in a zone", dh.is_panel_visible (2))
			w.floating_windows.first.handle_event ({SHELL_EVENTS}.Event_panel_close_request, 0, 0)
			assert_true ("docked again in the zone it was moved to",
				dh.is_panel_visible (2) and dh.panels [2].zone = dh.Zone_east and r2.parent = dh)
		end

feature -- Evidence

	test_gw22_floating_panel_light
		do
			float_gate (create {SW_THEME}.make_light, "gw22_floating_light.png")
		end

	test_gw22_floating_panel_dark
		do
			float_gate (create {SW_THEME}.make_dark, "gw22_floating_dark.png")
		end

feature -- Input

	test_gw22_a_floating_window_takes_input_like_the_main_one
		local
			w: SW_WINDOW
			r, other: SW_TEST_RECORDER
			l_float: SW_FLOATING_WINDOW
			l_box: SW_COLUMN
			cx, cy: INTEGER
		do
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create r.make
			create other.make
			create l_box.make
			l_box.put (r)
			l_box.put (other)
			w.set_root (create {SW_LABEL}.make_ui ("main"))
			w.request_render
			fired := 0
			w.register_accelerator (116, False, False, False, agent do fired := fired + 1 end)
			l_float := w.float_widget (l_box, "Notes", -3000, -3000, 400, 300)
			assert_true ("open", l_float.is_open)
			cx := (r.x + r.width / 2.0).truncated_to_integer
			cy := (r.y + r.height / 2.0).truncated_to_integer
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_press, cx, cy)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_release, cx, cy)
			assert_integers_equal ("clicked", 1, r.clicks)
			assert_integers_equal ("released", 1, r.releases)
			assert_true ("focused by the click", l_float.focused = r and r.is_focused)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_char, 97, 0)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_char, 0xD83D, 0)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_char, 0xDCD6, 0)
			assert_true ("a, then the book whole", r.typed.count = 2 and r.typed [1] = 'a' and r.typed [2].natural_32_code = 0x1F4D6)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 40, 0)
			assert_true ("a key reaches the focused widget", r.keys.count = 1 and r.keys [1] = 40)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 116, 0)
			assert_integers_equal ("F5 runs the owner's accelerator", 1, fired)
			assert_integers_equal ("and is not typed into the widget", 1, r.keys.count)
				-- as typed: the key down first (it disarms the accelerator's swallow)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 9, 0)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_char, 9, 0)
			assert_true ("Tab moves the focus within the window", l_float.focused = other and not r.is_focused)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_move, cx, cy)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_wheel, -120, 0)
			assert_integers_equal ("the wheel goes under the pointer", 1, r.wheel_turns)
			assert_true ("hovered", l_float.hovered = r)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_leave, 0, 0)
			assert_true ("the pointer left", l_float.hovered = Void)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_resized, 500, 360)
			assert_true ("a new size lays the tree out again",
				l_float.client_width = 500 and l_box.width = 500.0 - 2.0 * l_float.content_inset
				and l_box.height = 360.0 - 2.0 * l_float.content_inset)
			w.unfloat (l_float)
			assert_false ("closed", l_float.is_open)
		end

	test_gw22_a_modal_dialog_holds_the_floating_window
		local
			w: SW_WINDOW
			r: SW_TEST_RECORDER
			l_float: SW_FLOATING_WINDOW
		do
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create r.make
			w.set_root (create {SW_LABEL}.make_ui ("main"))
			w.request_render
			l_float := w.float_widget (r, "Notes", -3000, -3000, 400, 300)
			w.show_dialog (create {SW_DIALOG}.make ({SW_DIALOG}.Kind_warning, "Save?", "Save the note first?"))
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_press, 20, 20)
			assert_integers_equal ("no click under a modal dialog", 0, r.clicks)
			w.unfloat (l_float)
		end

feature {NONE} -- Evidence

	float_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- A study panel of scripture labels torn off: the floating frame
			-- in `a_theme', written to `a_evidence', with the main window's
			-- zone now empty.
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			l_col: SW_COLUMN
			kit: SW_SHAPING
			l_float: SW_FLOATING_WINDOW
		do
			create w.make ("floating", 0, 0, 900, 600, a_theme)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			w.set_shaping (kit)
			create l_col.make
			l_col.put (create {SW_LABEL}.make_ui ("Genesis 1:1 and John 1:1"))
			l_col.put (create {SW_LABEL}.make_body (genesis_1_1_wlc))
			l_col.put (create {SW_LABEL}.make_body (john_1_1_wh))
			l_col.put (create {SW_LABEL}.make_ui ("In the beginning God created the heaven and the earth."))
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			dh.add_keyed_panel ("word", "Word study", l_col, dh.Zone_south).do_nothing
			w.set_root (dh)
			w.enable_floating_panels (dh)
			w.request_render
			w.float_dock_panel (dh, 1)
			l_float := w.floating_windows.first
			assert_true ("the south zone collapsed", dh.zone_rect (dh.Zone_south).rh = 0.0)
			assert_true ("the frame was written", l_float.export_frame_png (evidence_path (a_evidence)))
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_close_request, 0, 0)
			assert_true ("docked again", dh.is_panel_visible (1) and w.floating_windows.is_empty)
		end

feature {NONE} -- Counters

	fired: INTEGER
			-- Accelerator runs.

end
