note
	description: "[
		Assault on GW-22: a dock panel torn off into a floating window (a
		framed simple_shell panel, real, never shown: the main window is not
		on screen in a test) by a double click on its tab, drawing its
		content in the owner's theme, taking clicks, keys, characters
		(surrogate pairs whole), Tab and the wheel as the main window does,
		honoring the owner's accelerators and modal dialogs, and docking
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

	test_a_document_window_floats_and_reports_its_close
			-- simple_gui's second window: a document window (W3) holding a tree, drawn by its
			-- owner, its close button reported, closed by unfloat.
		local
			w: SW_WINDOW
			l_float: SW_FLOATING_WINDOW
			l_closes: CELL [INTEGER]
		do
			create l_closes.put (0)
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make_ui ("main"))
			w.request_render
			l_float := w.float_document (create {SW_LABEL}.make_ui ("table"), "Table", -3000, -3000, 400, 300)
			assert ("open", l_float.is_open)
			assert ("a document window", l_float.is_document)
			l_float.set_on_close_request (agent (c: CELL [INTEGER]) do c.put (c.item + 1) end (l_closes))
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_close_request, 0, 0)
			assert_integers_equal ("its close is reported", 1, l_closes.item)
			w.unfloat (l_float)
			assert ("closed", not l_float.is_open)
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

	test_a_pressed_button_disabled_is_released
			-- A button whose own click disables it (simple_gui's Preview... disables the
			-- window's content, itself included, before its press ends) is released, not
			-- left pressed and disabled (the invariant crashed the example, 2026-11-12).
		local
			l_button: SW_BUTTON
		do
			create l_button.make ("Preview", Void)
			l_button.set_pressed (True)
			l_button.set_enabled (False)
			assert_false ("released", l_button.is_pressed)
			assert_false ("and disabled", l_button.is_enabled)
		end

	test_a_floating_window_serves_its_own_tree
			-- simple_shell#48: a second window (a print preview, say) publishes its own
			-- widget tree, served under its own native window, and the main window's
			-- tree stays its own. A screen reader's request to focus its canvas
			-- (a preview's page) moves its focus; closed, it serves nothing.
		local
			w: SW_WINDOW
			l_float: SW_FLOATING_WINDOW
			l_box: SW_COLUMN
			l_close: SW_BUTTON
			l_page: SW_CANVAS
			l_seen, l_main_seen: STRING_32
		do
			create w.make ("main", 0, 0, 900, 600, create {SW_THEME}.make_light)
			w.set_root (create {SW_BUTTON}.make ("Preview", Void))
			w.request_render
			create l_box.make
			l_box.put (create {SW_BUTTON}.make ("Previous", Void))
			create l_close.make ("Close", Void)
			l_box.put (l_close)
			create l_page.make (120.0)
				-- a canvas is focusable when it listens for keys, as a preview's page does
			l_page.set_on_key (agent (a_vk: INTEGER; a_shift: BOOLEAN) do end)
			l_box.put (l_page)
			l_float := w.float_document (l_box, "Print preview", -3000, -3000, 400, 300)
			assert_true ("open", l_float.is_open)
			l_float.render
			assert_true ("published when first drawn", l_float.is_accessibility_published)
			assert_true ("served under its own native window", l_float.panel.handle /= default_pointer
				and l_float.accessibility.served_window = l_float.panel.handle)
			l_seen := l_float.describe_accessibility
			assert ("its title and buttons: " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_seen), l_seen.has_substring (": Print preview%N")
				and l_seen.has_substring ("button: Previous") and l_seen.has_substring ("button: Close"))
			assert ("not the main window's button: " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_seen), not l_seen.has_substring ("button: Preview%N"))
			l_main_seen := w.describe_accessibility
			assert ("the main window's tree is its own: " + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_main_seen),
				l_main_seen.has_substring ("button: Preview") and not l_main_seen.has_substring ("button: Close"))
			assert_true ("and the second window still serves", l_float.accessibility.is_serving)
			l_float.handle_accessibility_request ({SHELL_EVENTS}.Event_focus_request, l_float.accessible_id_of (l_page))
			assert_true ("a screen reader's request focused the page", l_float.focused = l_page)
			l_float.close
			assert_false ("closed, it serves nothing", l_float.accessibility.is_serving)
		end

	test_a_menu_bar_in_a_floating_window_drops_its_menu
			-- 1c: a menu bar inside a floating document window opens its menu
			-- there; Enter runs the highlighted item, Right steps to the next
			-- pad's menu, and Escape closes it.
		local
			w: SW_WINDOW
			l_float: SW_FLOATING_WINDOW
			l_box: SW_COLUMN
			mb: SW_MENU_BAR
			l_runs: CELL [INTEGER]
		do
			create l_runs.put (0)
			create w.make ("floating", 0, 0, 900, 600, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make_ui ("main"))
			w.request_render
			create mb.make
			mb.add_menu ("File", agent (a_runs: CELL [INTEGER]): SW_MENU
				do
					create Result.make
					Result.add_item ("Open", "", True, agent (a_r: CELL [INTEGER]) do a_r.put (a_r.item + 1) end (a_runs))
				end (l_runs))
			mb.add_menu ("Edit", agent: SW_MENU
				do
					create Result.make
					Result.add_item ("Copy", "", True, agent do end)
				end)
			create l_box.make
			l_box.put (mb)
			l_box.put (create {SW_LABEL}.make_ui ("table"))
			l_float := w.float_document (l_box, "Table", -3000, -3000, 400, 300)
			assert_true ("open", l_float.is_open)
			l_float.render
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_press, (mb.x + 15.0).truncated_to_integer, (mb.y + 10.0).truncated_to_integer)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_release, (mb.x + 15.0).truncated_to_integer, (mb.y + 10.0).truncated_to_integer)
			assert_true ("the File menu drops in the floating window", attached l_float.popup and l_float.popup_bar = mb)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 40, 0)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 13, 0)
			assert_integers_equal ("Enter ran Open", 1, l_runs.item)
			assert_true ("and closed it", l_float.popup = Void)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_press, (mb.x + 15.0).truncated_to_integer, (mb.y + 10.0).truncated_to_integer)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_key, 39, 0)
			assert_true ("Right opens Edit", attached l_float.popup and mb.last_opened_pad = 2)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_char, 27, 0)
			assert_true ("Escape closes", l_float.popup = Void)
			l_float.handle_event ({SHELL_EVENTS}.Event_panel_close_request, 0, 0)
		end

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
