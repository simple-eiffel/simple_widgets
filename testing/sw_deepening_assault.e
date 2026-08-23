note
	description: "[
		The deepening sweep's battery (Larry, 2026-08-23): every
		limit that falls gets its proof here, bug-shaped items
		test-first. Opening movement: the text box's undo/redo -
		the docket's own 'most-missed feature'.
	]"

class
	SW_DEEPENING_ASSAULT

inherit
	TEST_SET_BASE

feature -- Text box undo (the most-missed feature)

	test_textbox_undo_redo
		local
			b: SW_TEXT_BOX
		do
			create b.make_single_line ("")
			assert ("a fresh box has no history", not b.can_undo)
				-- a typing RUN coalesces into one undo step
			b.handle_char (97)
			b.handle_char (98)
			b.handle_char (99)
			assert_strings_equal ("typed abc", "abc", b.text)
			assert ("typing armed undo", b.can_undo)
			b.handle_char (26)
			assert_strings_equal ("one undo unwinds the whole run", "", b.text)
			assert ("redo armed", b.can_redo)
			b.handle_char (25)
			assert_strings_equal ("redo replays the run", "abc", b.text)
				-- a delete is its own step
			b.handle_char (120)
			assert_strings_equal ("typed on", "abcx", b.text)
			b.handle_char (8)
			assert_strings_equal ("backspaced", "abc", b.text)
			b.handle_char (26)
			assert_strings_equal ("undo restores the deleted", "abcx", b.text)
			b.handle_char (26)
			assert_strings_equal ("undo unwinds the second run", "abc", b.text)
				-- block ops (a pebble drop) are single steps
			b.receive_pebble ({STRING_32} " PASTED")
			assert_strings_equal ("block landed", "abc PASTED", b.text)
			b.handle_char (26)
			assert_strings_equal ("one undo removes the whole block", "abc", b.text)
				-- programmatic set_text CLEARS history (editor law)
			b.set_text ("fresh")
			assert ("set_text cleared undo", not b.can_undo)
			assert ("and redo", not b.can_redo)
		end

feature -- Batch 1: small controls, limits fallen

	test_select_option_enablement
		local
			s: SW_SELECT
		do
			create s.make
			s.add_option ("alpha")
			s.add_option ("beta")
			s.add_option ("gamma")
			assert ("options start enabled", s.option_enabled.i_th (2))
			s.set_option_enabled (2, False)
			assert ("and can be refused", not s.option_enabled.i_th (2))
			s.add_separator_after (1)
			assert_integers_equal ("the group break is recorded", 1, s.separators_after.first)
		end

	test_radio_vertical_and_enablement
		local
			r: SW_RADIO_GROUP
		do
			create r.make
			r := r.with_option ("a").with_option ("b")
			assert ("horizontal by default", not r.is_vertical)
			r.set_vertical (True)
			assert ("vertical on demand", r.is_vertical)
			r.set_option_enabled (2, False)
			assert ("per-option refusal recorded", not r.option_enabled.i_th (2))
		end

	test_chip_removal_zone
		local
			c: SW_CHIP
			fired: CELL [BOOLEAN]
		do
			create fired.put (False)
			create c.make ("tag", {SW_CHIP}.Kind_neutral)
			c.set_bounds (0.0, 0.0, 80.0, 22.0)
			assert ("a plain chip has no zone", not c.remove_zone_contains (c.x + 75.0))
			c := c.with_remove (agent (f: CELL [BOOLEAN]) do f.put (True) end (fired))
			assert ("armed chips answer at the right edge", c.remove_zone_contains (c.x + 75.0))
			assert ("but not in the body", not c.remove_zone_contains (c.x + 10.0))
			if c.handle_click (c.x + 75.0, c.y + 10.0) then end
			assert ("the removal agent fired", fired.item)
		end

	test_checkbox_tristate_resolves_to_checked
		local
			cb: SW_CHECK_BOX
		do
			create cb.make ("mixed", False, Void)
			cb.set_indeterminate
			assert ("the dash state stands", cb.is_indeterminate)
			if cb.handle_click (1.0, 1.0) then end
			assert ("a click resolves the dash", not cb.is_indeterminate)
			assert ("to CHECKED", cb.is_checked)
			if cb.handle_click (1.0, 1.0) then end
			assert ("and toggling proceeds normally", not cb.is_checked)
		end

	test_rating_read_only_and_halves
		local
			r: SW_RATING
		do
			create r.make (3, 5, Void)
			r.set_read_only (True)
			r.set_display_value (4.5)
			r.set_caption ("4.5 (128)")
			if r.handle_click (r.x + 10.0, r.y + 10.0) then end
			assert_integers_equal ("read-only clicks are inert", 3, r.value)
			assert_reals_equal ("half precision carried", 4.5, r.display_value, 0.000_1)
		end

	test_slider_tick_snapping
		local
			s: SW_SLIDER
		do
			create s.make (0.5, Void)
			assert_reals_equal ("no ticks, no snap", 0.43, s.snapped (0.43), 0.000_1)
			s.set_ticks (4, True)
			assert_reals_equal ("0.43 snaps to the half", 0.5, s.snapped (0.43), 0.000_1)
			assert_reals_equal ("0.10 snaps down to the edge", 0.0, s.snapped (0.10), 0.000_1)
			assert_reals_equal ("0.90 snaps up to the end", 1.0, s.snapped (0.90), 0.000_1)
		end

	test_number_box_direct_typing
		local
			nb: SW_NUMBER_BOX
		do
			create nb.make (5, 0, 100, Void)
			nb.handle_char (52)
			nb.handle_char (50)
			assert ("typing opened the edit", nb.is_editing)
			nb.handle_char (13)
			assert_integers_equal ("Enter parsed and landed", 42, nb.value)
			nb.handle_char (57)
			nb.handle_char (57)
			nb.handle_char (57)
			nb.handle_char (13)
			assert_integers_equal ("commit CLAMPS per the box's law", 100, nb.value)
			nb.handle_char (49)
			nb.handle_char (27)
			assert ("Escape abandons", not nb.is_editing)
			assert_integers_equal ("and the value stands", 100, nb.value)
		end

	test_locale_number_formatting
		local
			us, eu: SW_LOCALE
		do
			create us.make_us
			create eu.make_european
			assert_strings_equal ("US groups with commas", "1,234,567.89",
				us.format_number (1234567.891, 2))
			assert_strings_equal ("Europe swaps the marks", "1.234.567,89",
				eu.format_number (1234567.891, 2))
			assert_strings_equal ("whole numbers stay whole", "1,000",
				us.format_number (1000.0, 0))
			assert_strings_equal ("negatives keep their sign", "-12,345.6",
				us.format_number (-12345.6, 1))
			assert_strings_equal ("small numbers need no groups", "7.50",
				us.format_number (7.5, 2))
		end

	test_badge_kind_and_zero_policy
		local
			b: SW_BADGE
		do
			create b.make_count (0)
			assert_integers_equal ("danger is the default kind", 0, b.kind)
			b.set_kind (2)
			assert_integers_equal ("kinds swap", 2, b.kind)
			b.set_hides_at_zero (True)
			assert ("the zero policy is recorded", b.hides_at_zero)
		end

feature -- Batch 2: toolkit-wide reach

	test_theme_text_scale
			-- Larry's grow/shrink ask: one theme knob, every glyph
			-- obeys, proven by measuring real cairo advances.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			w1, w2: REAL_64
		do
			create th.make_dark
			assert_reals_equal ("nominal out of the box", 1.0, th.text_scale, 0.000_1)
			create surf.make (64, 32)
			create ctx.make (surf)
			create p.make (ctx, th)
			p.font ({SW_PAINTER}.Role_ui, 12.0, False)
			w1 := p.advance ("mmmm")
			th.set_text_scale (1.5)
			p.font ({SW_PAINTER}.Role_ui, 12.0, False)
			w2 := p.advance ("mmmm")
			assert ("half again bigger text is measurably wider", w2 > w1 * 1.2)
		end

	test_screen_grab_marries_cairo
			-- The carve's dividend: SHELL_DESKTOP's raw grab arrives
			-- as a real CAIRO_SURFACE - 6x6 desktop pixels, for real.
		local
			sc: SW_SCREEN
		do
			create sc
			if attached sc.grab (sc.virtual_x, sc.virtual_y, 6, 6) as s then
				assert_integers_equal ("width honoured", 6, s.width)
				assert_integers_equal ("height honoured", 6, s.height)
				s.destroy
			else
				assert ("desktop unreadable only in a locked session", False)
			end
		end

	test_focus_traversal_ring
			-- The Tab ring: collected purely, walked cyclically,
			-- disabled widgets skipped, inert widgets never in it.
		local
			w: SW_WINDOW
			row: SW_ROW
			b: SW_BUTTON
			t1, t2, t3: SW_TEXT_BOX
			th: SW_THEME
			fs: ARRAYED_LIST [SW_WIDGET]
		do
			create th.make_dark
			create w.make ("focus", 0, 0, 320, 200, th)
			create row.make
			create b.make ("btn", Void)
			create t1.make_single_line ("")
			create t2.make_single_line ("")
			create t3.make_single_line ("")
			t2.set_enabled (False)
			row := row.add (b).add (t1).add (t2).add (t3)
			w.set_root (row)
			create fs.make (4)
			row.focusables (fs)
			assert_integers_equal ("disabled skipped, button inert: two in the ring", 2, fs.count)
			w.focus_next
			assert ("Tab lands on the first", fs.i_th (1).is_focused)
			w.focus_next
			assert ("then the second", fs.i_th (2).is_focused)
			assert ("and the first let go", not fs.i_th (1).is_focused)
			w.focus_next
			assert ("the ring wraps", fs.i_th (1).is_focused)
			w.focus_previous
			assert ("Shift+Tab walks back (wrapping too)", fs.i_th (2).is_focused)
		end

	test_spreadsheet_keeps_its_tab
		local
			sp: SW_SPREADSHEET
			tb: SW_TEXT_BOX
		do
			create sp.make
			create tb.make_single_line ("")
			assert ("the grid consumes Tab (commit right)", sp.wants_tab)
			assert ("a text box surrenders it to traversal", not tb.wants_tab)
		end

	test_cursor_kinds
		local
			tb: SW_TEXT_BOX
			bt: SW_BUTTON
			sp: SW_SPLITTER
		do
			create tb.make_single_line ("")
			create bt.make ("x", Void)
			create sp.make (create {SW_LABEL}.make_ui ("a"), create {SW_LABEL}.make_ui ("b"))
			assert_integers_equal ("text surface shows the I-beam", 1, tb.cursor_kind)
			assert_integers_equal ("buttons keep the arrow", 0, bt.cursor_kind)
			assert_integers_equal ("the divider shows resize arrows", 3, sp.cursor_kind)
		end

	test_peek_grace_law
			-- An unpinned drawer survives one heartbeat outside;
			-- the second spends the grace; re-entry resets it.
		local
			w: SW_WINDOW
			th: SW_THEME
		do
			create th.make_dark
			create w.make ("grace", 0, 0, 200, 100, th)
			assert ("one tick outside is grazing, not leaving", not w.peek_close_due (True))
			assert ("two ticks outside spends the grace", w.peek_close_due (True))
			assert ("re-entry resets", not w.peek_close_due (False))
			assert ("and the count starts over", not w.peek_close_due (True))
		end

	test_calendar_close_on_pick_request
			-- The date-picker popover law: a day pick raises a
			-- one-shot close request - only when the host opted in.
		local
			cal: SW_CALENDAR
		do
			create cal.make
			cal.set_bounds (0.0, 0.0, 250.0, 240.0)
			if cal.handle_click (10.0, 70.0) then end
			assert ("embedded calendars never ask", not cal.take_sheet_close_request)
			cal.set_closes_overlay_on_pick (True)
			if cal.handle_click (10.0, 70.0) then end
			assert ("popover calendars ask after a pick", cal.take_sheet_close_request)
			assert ("and the request is one-shot", not cal.take_sheet_close_request)
		end

end
