note
	description: "[
		Assault on GW-15, SW_TABS: closing (the neighbor that is selected,
		the close guard, pinned tabs, the close box pressed and released
		through the window), dragging a tab to a new place through the
		window, overflow (the strip scrolls so the selected tab is whole;
		the chevron's menu picks any tab through the popup), the keys an
		application binds (Ctrl+Tab, Ctrl+Shift+Tab, Ctrl+W), the wheel,
		and scripture tab labels in both themes (evidence
		gw15_tabs_light.png and gw15_tabs_dark.png). Inherits the shaping
		assault for its scripture fixtures and kit.
	]"

class
	SW_TABS_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- One inset (scan 18)

	test_scan18_drag_outline_hugs_the_ground_at_any_scale
			-- At text scale 2 the tab ground is inset by half the theme's
			-- padding; the drag outline must sit on that ground's edge, not 4
			-- pixels above it where the old literal put it.
		local
			w: SW_WINDOW
			tb: SW_TABS
			t: SW_THEME
			l_image: CAIRO_SURFACE
			cy, ax, l_column, l_ground_row, l_old_row: INTEGER
			m, l_inset: REAL_64
		do
			create t.make_light
			t.set_text_scale (2.0)
			create w.make ("tabs", 0, 0, 900, 300, t)
			tb := four_tabs
			w.set_root (tb)
			w.request_render
			cy := (tb.y + tb.bar_h / 2.0).truncated_to_integer
			ax := (tb.tab_lefts [1] + tb.tab_pad + 2.0).truncated_to_integer
			w.dispatch (2, ax, cy)
			w.dispatch (9, ax + 20, cy)
			assert_true ("dragging the first tab", tb.is_dragging and tb.labels [1].same_string ("A"))
			l_image := w.widget_image (tb, t, 1.0)
			m := w.export_margin (t)
			l_inset := t.padding / 2.0
			assert_true ("the scale moves the inset off the old 4 pixels", l_inset >= 6.0)
			l_column := (tb.tab_lefts [1] + tb.tab_widths [1] / 2.0 - tb.x + m).truncated_to_integer
			l_ground_row := (tb.y + l_inset - tb.y + m).truncated_to_integer
			l_old_row := (4.0 + m).truncated_to_integer
			assert_true ("the outline is on the ground's top edge",
				is_near (image_pixel (l_image, l_column, l_ground_row), t.accent))
			assert_false ("and not where the literal put it",
				is_near (image_pixel (l_image, l_column, l_old_row), t.accent))
			l_image.destroy
			w.dispatch (10, ax + 20, cy)
		end

feature -- Closing

	test_gw15_close_selects_the_neighbor
			-- Closing the selected tab selects its right neighbor, or its
			-- left when it was last; closing an earlier tab keeps the same
			-- page selected without a change event.
		local
			tb: SW_TABS
			p2: SW_WIDGET
		do
			tb := four_tabs
			tb.set_on_change (agent (i: INTEGER) do changes := changes + 1 end)
			tb.set_on_close (agent (pg: SW_WIDGET) do closed_page := pg end)
			tb.select_tab (2)
			p2 := tb.pages [2]
			changes := 0
			tb.close_tab (2)
			assert_integers_equal ("three left", 3, tb.pages.count)
			assert_true ("the closed page was announced", closed_page = p2)
			assert_true ("and let go", p2.parent = Void)
			assert_true ("C, the right neighbor, is selected", tb.labels [tb.selected_index].same_string ("C"))
			assert_integers_equal ("one change", 1, changes)
			tb.select_tab (3)
			changes := 0
			tb.close_tab (3)
			assert_true ("closing the last selects its left", tb.labels [tb.selected_index].same_string ("C"))
			changes := 0
			tb.close_tab (1)
			assert_true ("closing an earlier tab keeps C", tb.labels [tb.selected_index].same_string ("C"))
			assert_integers_equal ("its index shifted", 1, tb.selected_index)
			assert_integers_equal ("without a change event", 0, changes)
			tb.close_tab (1)
			assert_integers_equal ("empty", 0, tb.pages.count)
			assert_integers_equal ("nothing selected", 0, tb.selected_index)
		end

	test_gw15_guard_and_pinned_tabs
			-- A tab that is not closable ignores a close request; the close
			-- guard can refuse; programmatic `close_tab' always closes.
		local
			tb: SW_TABS
		do
			tb := four_tabs
			tb.set_tab_closable (1, False)
			tb.request_close (1)
			assert_integers_equal ("a pinned tab stays", 4, tb.pages.count)
			guard_answer := False
			tb.set_close_guard (agent (i: INTEGER): BOOLEAN do Result := guard_answer end)
			tb.request_close (2)
			assert_integers_equal ("the guard refused", 4, tb.pages.count)
			guard_answer := True
			tb.request_close (2)
			assert_integers_equal ("the guard agreed", 3, tb.pages.count)
			tb.close_tab (1)
			assert_integers_equal ("close_tab closes even a pinned tab", 2, tb.pages.count)
		end

	test_gw15_close_box_through_the_window
			-- Pressed and released on the close box, the tab closes; pressed
			-- there and released off it, nothing closes. A press on a tab's
			-- label selects it and closes nothing.
		local
			w: SW_WINDOW
			tb: SW_TABS
			cx, cy: INTEGER
		do
			create w.make ("tabs", 0, 0, 900, 300, create {SW_THEME}.make_light)
			tb := four_tabs
			w.set_root (tb)
			w.request_render
			assert_true ("placed", tb.is_placed)
			cx := close_x (tb, 2)
			cy := (tb.y + tb.bar_h / 2.0).truncated_to_integer
			assert_integers_equal ("the box is found", 2, tb.close_box_at (cx, cy))
			w.dispatch (2, cx, cy)
			w.dispatch (10, cx + 200, cy)
			assert_integers_equal ("released off the box: nothing closes", 4, tb.pages.count)
			w.dispatch (2, (tb.tab_lefts [3] + tb.tab_pad + 2.0).truncated_to_integer, cy)
			w.dispatch (10, (tb.tab_lefts [3] + tb.tab_pad + 2.0).truncated_to_integer, cy)
			assert_integers_equal ("a press on the label selects", 3, tb.selected_index)
			assert_integers_equal ("and closes nothing", 4, tb.pages.count)
			w.request_render
			cx := close_x (tb, 2)
			w.dispatch (2, cx, cy)
			w.dispatch (10, cx, cy)
			assert_integers_equal ("pressed and released on the box: closed", 3, tb.pages.count)
			assert_true ("B is gone", across tb.labels as l all not l.same_string ("B") end)
			assert_true ("C is still selected", tb.labels [tb.selected_index].same_string ("C"))
		end

feature -- Moving

	test_gw15_drag_reorders_through_the_window
			-- A press on A and a drag past C's middle moves A to third
			-- place in one pointer move; the selection follows A. A small
			-- wobble moves nothing.
		local
			w: SW_WINDOW
			tb: SW_TABS
			cy, ax: INTEGER
			pa: SW_WIDGET
		do
			create w.make ("tabs", 0, 0, 900, 300, create {SW_THEME}.make_light)
			tb := four_tabs
			tb.set_on_move (agent (f, t: INTEGER) do moves := moves + 1 end)
			moves := 0
			w.set_root (tb)
			w.request_render
			pa := tb.pages [1]
			cy := (tb.y + tb.bar_h / 2.0).truncated_to_integer
			ax := (tb.tab_lefts [1] + tb.tab_pad + 2.0).truncated_to_integer
			w.dispatch (2, ax, cy)
			w.dispatch (9, ax + 2, cy)
			assert_false ("a wobble is no drag", tb.is_dragging)
			assert_true ("A still first", tb.labels [1].same_string ("A"))
			w.dispatch (9, (tb.tab_lefts [3] + tb.tab_widths [3] * 0.75).truncated_to_integer, cy)
			assert_true ("dragging", tb.is_dragging)
			w.dispatch (10, (tb.tab_lefts [3] + tb.tab_widths [3] * 0.75).truncated_to_integer, cy)
			assert_false ("released", tb.is_dragging)
			assert_true ("order B C A D",
				tb.labels [1].same_string ("B") and tb.labels [2].same_string ("C")
				and tb.labels [3].same_string ("A") and tb.labels [4].same_string ("D"))
			assert_true ("A's page moved with it", tb.pages [3] = pa)
			assert_integers_equal ("A is selected", 3, tb.selected_index)
			assert_integers_equal ("two places, two moves", 2, moves)
			w.request_render
			assert_true ("boxes left to right again",
				across 2 |..| 4 as k all tb.tab_lefts [k] >= tb.tab_lefts [k - 1] + tb.tab_widths [k - 1] end)
		end

	test_gw15_move_tab_keeps_the_selection
			-- `move_tab' both ways; the selected page stays selected.
		local
			tb: SW_TABS
			pb: SW_WIDGET
		do
			tb := four_tabs
			tb.select_tab (2)
			pb := tb.pages [2]
			tb.move_tab (4, 1)
			assert_true ("D first", tb.labels [1].same_string ("D"))
			assert_true ("B still selected", tb.selected_page = pb)
			assert_integers_equal ("at its new place", 3, tb.selected_index)
			tb.move_tab (1, 4)
			assert_true ("D last again", tb.labels [4].same_string ("D"))
			assert_true ("B still selected", tb.selected_page = pb and tb.selected_index = 2)
		end

feature -- Overflow

	test_gw15_overflow_keeps_the_selected_tab_whole
			-- Twelve tabs in a narrow window overflow: selecting the last
			-- scrolls the strip so it is whole and clear of the chevron; the
			-- chevron's menu lists every tab and picking one through the
			-- popup selects it and scrolls back.
		local
			w: SW_WINDOW
			tb: SW_TABS
			i, cy, my: INTEGER
		do
			create w.make ("tabs", 0, 0, 360, 300, create {SW_THEME}.make_light)
			create tb.make
			tb.set_closable_by_default (True)
			from i := 1 until i > 12 loop
				tb.add_page ({STRING_32} "Genesis " + i.out, create {SW_SPACER}.make)
				i := i + 1
			end
			w.set_root (tb)
			w.request_render
			assert_true ("overflows", tb.has_overflow)
			assert_true ("the first tab shows", tb.is_tab_shown (1))
			assert_false ("the last does not", tb.is_tab_shown (12))
			tb.select_tab (12)
			w.request_render
			assert_true ("the selected last tab shows", tb.is_tab_shown (12))
			assert_true ("the strip scrolled", tb.first_visible > 1)
			assert_false ("the first is off the strip", tb.is_tab_shown (1))
			assert_true ("whole and clear of the chevron",
				tb.tab_lefts [12] + tb.tab_widths [12] <= tb.x + tb.width - tb.chevron_w)
			cy := (tb.y + tb.bar_h / 2.0).truncated_to_integer
			w.dispatch (2, (tb.x + tb.width - tb.chevron_w / 2.0).truncated_to_integer, cy)
			if attached w.open_popup as m then
				assert_integers_equal ("every tab in the menu", 12, m.items.count)
				assert_true ("in order", m.items [3].label.same_string ("Genesis 3"))
				my := item_y (m, 3)
				assert_true ("item 3 found on the menu", my > 0)
				w.dispatch (2, (m.x + m.width / 2.0).truncated_to_integer, my)
				assert_true ("the pick closed the menu", w.open_popup = Void)
				assert_integers_equal ("Genesis 3 selected", 3, tb.selected_index)
				w.request_render
				assert_true ("and shown", tb.is_tab_shown (3))
			else
				assert_true ("the chevron opened the menu", False)
			end
		end

	test_gw15_closing_at_the_end_pulls_the_strip_back
			-- With the strip scrolled to the end, closing the last tabs
			-- leaves no empty room while earlier tabs are hidden.
		local
			w: SW_WINDOW
			tb: SW_TABS
			i: INTEGER
		do
			create w.make ("tabs", 0, 0, 360, 300, create {SW_THEME}.make_light)
			create tb.make
			from i := 1 until i > 8 loop
				tb.add_page ({STRING_32} "Romans " + i.out, create {SW_SPACER}.make)
				i := i + 1
			end
			w.set_root (tb)
			tb.select_tab (8)
			w.request_render
			assert_true ("scrolled", tb.first_visible > 1)
			from until tb.pages.count = 2 loop
				tb.close_tab (tb.pages.count)
				w.request_render
			end
			assert_integers_equal ("all back from the first", 1, tb.first_visible)
			assert_false ("no overflow left", tb.has_overflow)
		end

feature -- Keys and wheel

	test_gw15_keys_an_application_binds
			-- Ctrl+Tab and Ctrl+Shift+Tab step with wrapping; Ctrl+W closes
			-- the selected tab.
		local
			w: SW_WINDOW
			tb: SW_TABS
		do
			create w.make ("tabs", 0, 0, 900, 300, create {SW_THEME}.make_light)
			tb := four_tabs
			w.set_root (tb)
			w.register_accelerator (9, True, False, False, agent tb.select_next)
			w.register_accelerator (9, True, False, True, agent tb.select_previous)
			w.register_accelerator (87, True, False, False, agent tb.close_selected)
			w.request_render
			w.simulate_key_down (9, True, False, True)
			assert_integers_equal ("Ctrl+Shift+Tab from the first wraps to the last", 4, tb.selected_index)
			w.simulate_key_down (9, True, False, False)
			assert_integers_equal ("Ctrl+Tab from the last wraps to the first", 1, tb.selected_index)
			w.simulate_key_down (9, True, False, False)
			assert_integers_equal ("Ctrl+Tab steps", 2, tb.selected_index)
			w.simulate_key_down (87, True, False, False)
			assert_integers_equal ("Ctrl+W closes", 3, tb.pages.count)
			assert_true ("C selected", tb.labels [tb.selected_index].same_string ("C"))
		end

	test_gw15_wheel_steps_over_the_strip
			-- The wheel over the strip steps the selection, without wrapping.
		local
			w: SW_WINDOW
			tb: SW_TABS
			px, py: INTEGER
		do
			create w.make ("tabs", 0, 0, 900, 300, create {SW_THEME}.make_light)
			tb := four_tabs
			w.set_root (tb)
			w.request_render
			px := (tb.tab_lefts [2] + 4.0).truncated_to_integer
			py := (tb.y + tb.bar_h / 2.0).truncated_to_integer
			w.dispatch (13, px, py)
			w.simulate_wheel (px, py, -120)
			assert_integers_equal ("down steps right", 2, tb.selected_index)
			w.simulate_wheel (px, py, 120)
			w.simulate_wheel (px, py, 120)
			assert_integers_equal ("up stops at the first", 1, tb.selected_index)
		end

feature -- Scripture labels in both themes

	test_gw15_tabs_light
		do
			scripture_tabs_gate (create {SW_THEME}.make_light, "gw15_tabs_light.png")
		end

	test_gw15_tabs_dark
		do
			scripture_tabs_gate (create {SW_THEME}.make_dark, "gw15_tabs_dark.png")
		end

feature -- Scan 9 (since 760abf1)

	test_scan9_a_narrow_bar_still_shows_the_selected_tab
			-- Scan 9 HIGH 1: in a bar too narrow for the chevron's room, the
			-- selected tab was given no width and `arrange' broke its own
			-- postcondition. It keeps at least one pixel.
		local
			w: SW_WINDOW
			tb: SW_TABS
		do
			create w.make ("tabs", 0, 0, 30, 200, create {SW_THEME}.make_light)
			tb := four_tabs
			tb.select_tab (3)
			w.set_root (tb)
			w.request_render
			assert_true ("placed", tb.is_placed)
			assert_true ("the selected tab shows", tb.is_tab_shown (3))
		end

	test_scan9_a_zero_inset_theme_still_shows_tabs
			-- Scan 9 HIGH 2: the width cap was twenty insets, so a theme with
			-- no control inset gave every tab no width. The cap follows the
			-- font now.
		local
			w: SW_WINDOW
			tb: SW_TABS
			th: SW_THEME
		do
			create th.make_light
			th.set_spacing (th.border_width, th.padding, 0.0)
			create w.make ("tabs", 0, 0, 900, 200, th)
			tb := four_tabs
			w.set_root (tb)
			w.request_render
			assert_true ("every tab shows", across 1 |..| 4 as k all tb.is_tab_shown (k) end)
			assert_true ("with room for its label", tb.tab_widths [1] > tb.close_size)
		end

	test_scan9_a_close_handler_may_adopt_the_page
			-- Scan 9 MEDIUM 6: `close_tab' promised the closed page had no
			-- parent AFTER calling `on_close', so a handler that moved the page
			-- into another notebook broke the promise.
		local
			tb, other: SW_TABS
		do
			tb := four_tabs
			create other.make
			tb.set_on_close (agent (pg: SW_WIDGET; a_other: SW_TABS) do a_other.add_page ("moved", pg) end (?, other))
			tb.close_tab (2)
			assert_integers_equal ("closed", 3, tb.pages.count)
			assert_true ("adopted by the other notebook", other.pages.count = 1 and then other.pages [1].parent = other)
		end

	test_scan9_moving_across_hidden_tabs_leaves_no_stale_box
			-- Scan 9 MEDIUM 7: `move_tab' across a tab scrolled off the strip
			-- swapped boxes with a made-up gap, leaving a box outside the strip
			-- until the next arrange. No stale box may answer.
		local
			w: SW_WINDOW
			tb: SW_TABS
			i: INTEGER
		do
			create w.make ("tabs", 0, 0, 360, 300, create {SW_THEME}.make_light)
			create tb.make
			from i := 1 until i > 12 loop
				tb.add_page ({STRING_32} "Genesis " + i.out, create {SW_SPACER}.make)
				i := i + 1
			end
			w.set_root (tb)
			w.request_render
			assert_false ("the last is hidden", tb.is_tab_shown (12))
			tb.move_tab (1, 12)
			assert_true ("every box answering a hit stands inside the strip",
				not tb.is_placed or else across 1 |..| 12 as k all
					not tb.is_tab_shown (k) or else (tb.tab_lefts [k] >= tb.x and tb.tab_lefts [k] + tb.tab_widths [k] <= tb.x + tb.width) end)
			w.request_render
			assert_true ("placed again", tb.is_placed)
			assert_true ("the moved tab is last", tb.labels [12].same_string ("Genesis 1"))
		end

feature {NONE} -- Fixtures

	changes, moves: INTEGER

	closed_page: detachable SW_WIDGET

	guard_answer: BOOLEAN

	four_tabs: SW_TABS
			-- A, B, C, D, closable, A selected.
		do
			create Result.make
			Result.set_closable_by_default (True)
			across <<"A", "B", "C", "D">> as l loop
				Result.add_page (l, create {SW_LABEL}.make_ui (l))
			end
		end

	close_x (a_tabs: SW_TABS; a_i: INTEGER): INTEGER
			-- The middle of tab `a_i''s close box, from the public geometry.
		do
			Result := (a_tabs.tab_lefts [a_i] + a_tabs.tab_widths [a_i] - a_tabs.tab_pad - a_tabs.close_size / 2.0).truncated_to_integer
		end

	item_y (a_menu: SW_MENU; a_item: INTEGER): INTEGER
			-- A y inside menu item `a_item', found by asking the menu; 0 if
			-- none.
		local
			yy: INTEGER
		do
			from
				yy := a_menu.y.truncated_to_integer
			until
				yy > (a_menu.y + a_menu.height).truncated_to_integer or Result > 0
			loop
				if a_menu.item_at (a_menu.x + a_menu.width / 2.0, yy + 0.0) = a_item then
					Result := yy + 3
				end
				yy := yy + 1
			end
		end

	scripture_tabs_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- Tabs labelled with pointed Hebrew, polytonic Greek, a mixed
			-- English and Hebrew line and an ampersand, closable, the
			-- Hebrew one selected: all shown, shaped with nothing skipped,
			-- and written as evidence.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			tb: SW_TABS
			path: STRING_32
		do
			create w.make ("gw15", 0, 0, 900, 160, a_theme)
			kit := gw03_kit (a_theme)
			w.set_shaping (kit)
			create tb.make
			tb.set_closable_by_default (True)
			tb.add_page ({STRING_32} "Genesis 1", create {SW_LABEL}.make_ui ("Genesis 1"))
			tb.add_page (genesis_first_word, create {SW_LABEL}.make_ui (genesis_first_word))
			tb.add_page (john_1_1_wh_nfc.substring (1, 7), create {SW_LABEL}.make_ui (john_1_1_wh_nfc.substring (1, 7)))
			tb.add_page (mixed_english_hebrew, create {SW_LABEL}.make_ui (mixed_english_hebrew))
			tb.add_page ({STRING_32} "Notes & Links", create {SW_LABEL}.make_ui ("Notes & Links"))
			tb.set_tab_closable (1, False)
			tb.select_tab (2)
			w.set_root (tb)
			w.request_render
			assert_true ("placed", tb.is_placed)
			assert_true ("every tab shows", across 1 |..| 5 as k all tb.is_tab_shown (k) end)
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			assert_true ("the menu keeps the ampersand",
				tb.overflow_menu.items [5].label.same_string ({STRING_32} "Notes & Links"))
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

feature {NONE} -- Pixels

	image_pixel (a_image: CAIRO_SURFACE; a_x, a_y: INTEGER): NATURAL_32
			-- The colour at (`a_x', `a_y') of an opaque image, as 0xRRGGBB.
		require
			inside: a_x >= 0 and a_y >= 0 and a_x < a_image.width and a_y < a_image.height
		local
			l_bytes: MANAGED_POINTER
		do
			create l_bytes.share_from_pointer (a_image.data, a_image.stride * a_image.height)
			Result := l_bytes.read_natural_32 (a_y * a_image.stride + a_x * 4) & 0xFFFFFF
		end

	is_near (a_rgb, a_want: NATURAL_32): BOOLEAN
			-- Within 48 per channel.
		do
			Result := ((a_rgb |>> 16) & 0xFF).to_integer_32 - ((a_want |>> 16) & 0xFF).to_integer_32 <= 48
				and ((a_want |>> 16) & 0xFF).to_integer_32 - ((a_rgb |>> 16) & 0xFF).to_integer_32 <= 48
				and ((a_rgb |>> 8) & 0xFF).to_integer_32 - ((a_want |>> 8) & 0xFF).to_integer_32 <= 48
				and ((a_want |>> 8) & 0xFF).to_integer_32 - ((a_rgb |>> 8) & 0xFF).to_integer_32 <= 48
				and (a_rgb & 0xFF).to_integer_32 - (a_want & 0xFF).to_integer_32 <= 48
				and (a_want & 0xFF).to_integer_32 - (a_rgb & 0xFF).to_integer_32 <= 48
		end

end
