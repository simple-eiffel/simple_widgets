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

feature -- Batch 3: the drawn-glyph set

	test_every_glyph_draws_ink
			-- The whole vocabulary, proven at the pixel: each kind is
			-- drawn white on black and the surface must change.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			mp: MANAGED_POINTER
			k, i, inked: INTEGER
		do
			create th.make_dark
			create surf.make (32, 32)
			create ctx.make (surf)
			create p.make (ctx, th)
			from
				k := {SW_PAINTER}.Glyph_plus
			until
				k > {SW_PAINTER}.Glyph_error
			loop
				p.set_color (0x000000)
				p.fill_rect (0.0, 0.0, 32.0, 32.0)
				p.set_color (0xFFFFFF)
				p.glyph (k, 16.0, 16.0, 20.0)
				surf.flush.do_nothing
				create mp.share_from_pointer (surf.data, 32 * surf.stride)
				inked := 0
				from
					i := 0
				until
					i >= 32 * 32 or inked > 0
				loop
					if mp.read_natural_32 (i * 4) /= 0xFF000000 then
						inked := inked + 1
					end
					i := i + 1
				end
				assert ("glyph " + k.out + " leaves ink", inked > 0)
				k := k + 1
			end
		end

	test_icon_button_faces
		local
			b, ib: SW_BUTTON
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			w_plain, w_glyph: REAL_64
		do
			create th.make_dark
			create surf.make (8, 8)
			create ctx.make (surf)
			create p.make (ctx, th)
			create b.make ("Save", Void)
			w_plain := b.preferred_width (p)
			b := b.with_glyph ({SW_PAINTER}.Glyph_check)
			w_glyph := b.preferred_width (p)
			assert ("a glyph widens the face", w_glyph > w_plain)
			create ib.make ("", Void)
			ib := ib.with_glyph ({SW_PAINTER}.Glyph_gear)
			assert ("an icon-only button is compact", ib.preferred_width (p) < w_plain + 22.0)
		end

	test_toolbar_icon_items_measure_squarely
		local
			tb: SW_TOOLBAR
		do
			create tb.make
			tb.add_icon_item ({SW_PAINTER}.Glyph_search, "Search", Void)
			assert_integers_equal ("icon item recorded", {SW_PAINTER}.Glyph_search,
				tb.items.first.glyph)
			assert ("label demoted to the tooltip", tb.items.first.label.is_empty)
			assert_strings_equal ("which carries the words", "Search", tb.items.first.hint)
		end

	test_segmented_icon_segments
		local
			sg: SW_SEGMENTED
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
		do
			create th.make_dark
			create surf.make (8, 8)
			create ctx.make (surf)
			create p.make (ctx, th)
			create sg.make
			sg := sg.with_segment ("List").with_icon_segment ({SW_PAINTER}.Glyph_gear)
			assert_integers_equal ("parallel lists", 2, sg.segment_glyphs.count)
			assert_reals_equal ("icon segments measure squarely (the shared measure)",
				34.0, sg.seg_w (p, 2), 0.000_1)
		end

	test_empty_state_glyph_choice
		local
			es: SW_EMPTY_STATE
		do
			create es.make ("Nothing here", "Add an item to begin")
			assert_integers_equal ("the tray by default", 0, es.glyph_kind)
			es.set_glyph_kind ({SW_PAINTER}.Glyph_search)
			assert_integers_equal ("or the host's kind", {SW_PAINTER}.Glyph_search, es.glyph_kind)
		end

feature -- Batch 4: data + enterprise deepening

	test_grid_descending_sort_is_stable
			-- THE BUG, test-first: equal keys must keep model order
			-- under DESCENDING sort. The insertion sort's blanket
			-- 'less := not less' swaps equals - merge sort cures it.
		local
			g: SW_DATA_GRID [TUPLE [name: STRING_32; size: INTEGER]]
		do
			create g.make (200.0)
			g.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("Name", 120.0, agent (r: TUPLE [name: STRING_32; size: INTEGER]): STRING_32 do Result := r.name end))
			g.add_column ((create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("Size", 80.0, agent (r: TUPLE [name: STRING_32; size: INTEGER]): STRING_32 do Result := r.size.out.to_string_32 end)).with_key (agent (r: TUPLE [name: STRING_32; size: INTEGER]): COMPARABLE do Result := r.size end))
			g.add_row ([{STRING_32} "first-one", 1])
			g.add_row ([{STRING_32} "second-one", 1])
			g.add_row ([{STRING_32} "the-two", 2])
			g.sort_by (2, True)
			assert ("the two leads descending", g.rows.i_th (g.view.i_th (1)).size = 2)
			assert ("equal keys keep MODEL order (stability)",
				g.rows.i_th (g.view.i_th (2)).name.same_string_general ("first-one"))
			assert ("both ones present, in order",
				g.rows.i_th (g.view.i_th (3)).name.same_string_general ("second-one"))
		end

	test_grid_sort_thousands
			-- The O(n log n) claim under load: 2000 rows, reverse-
			-- keyed, sorted ascending - first, last and a middle
			-- probe all land exactly.
		local
			g: SW_DATA_GRID [TUPLE [name: STRING_32; size: INTEGER]]
			i: INTEGER
		do
			create g.make (200.0)
			g.add_column ((create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("Size", 80.0, agent (r: TUPLE [name: STRING_32; size: INTEGER]): STRING_32 do Result := r.size.out.to_string_32 end)).with_key (agent (r: TUPLE [name: STRING_32; size: INTEGER]): COMPARABLE do Result := r.size end))
			from
				i := 2000
			until
				i < 1
			loop
				g.add_row ([{STRING_32} "r", i])
				i := i - 1
			end
			g.sort_by (1, False)
			assert_integers_equal ("first is 1", 1, g.rows.i_th (g.view.i_th (1)).size)
			assert_integers_equal ("1000th is 1000", 1000, g.rows.i_th (g.view.i_th (1000)).size)
			assert_integers_equal ("last is 2000", 2000, g.rows.i_th (g.view.i_th (2000)).size)
		end

	test_list_keyboard_navigation
			-- Arrows walk, PgDn strides a viewport, Home/End jump,
			-- and every move keeps the selection visible.
		local
			l: SW_LIST
		do
			create l.make (90.0)
			l.set_row_count (100)
			assert ("lists join the Tab ring", l.accepts_focus)
			l.handle_key (40, False)
			assert_integers_equal ("Down from nothing selects the first", 1, l.selected_index)
			l.handle_key (40, False)
			assert_integers_equal ("and walks", 2, l.selected_index)
			l.handle_key (34, False)
			assert_integers_equal ("PgDn strides the declared viewport", 5, l.selected_index)
			l.handle_key (35, False)
			assert_integers_equal ("End jumps to the tail", 100, l.selected_index)
			assert ("and the tail is scrolled into view",
				l.scroll_y >= (100.0 - 3.0) * l.row_height - 0.001)
			l.handle_key (33, False)
			assert_integers_equal ("PgUp strides back", 97, l.selected_index)
			l.handle_key (36, False)
			assert_integers_equal ("Home rewinds", 1, l.selected_index)
			l.handle_key (38, False)
			assert_integers_equal ("Up at the top holds", 1, l.selected_index)
		end

	test_grid_page_and_edge_keys
		local
			g: SW_DATA_GRID [TUPLE [name: STRING_32; size: INTEGER]]
			i: INTEGER
		do
			create g.make (104.0)
			g.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; size: INTEGER]]}.make ("N", 80.0, agent (r: TUPLE [name: STRING_32; size: INTEGER]): STRING_32 do Result := r.name end))
			from
				i := 1
			until
				i > 50
			loop
				g.add_row ([{STRING_32} "row", i])
				i := i + 1
			end
			g.handle_key (40, False)
			assert_integers_equal ("Down selects the first model row", 1, g.selected_model)
			g.handle_key (34, False)
			assert_integers_equal ("PgDn strides the declared viewport", 5, g.selected_model)
			g.handle_key (35, False)
			assert_integers_equal ("End lands on the last", 50, g.selected_model)
			g.handle_key (36, False)
			assert_integers_equal ("Home on the first", 1, g.selected_model)
		end

	test_calendar_min_max_window
			-- Cells outside the window refuse clicks; with the window
			-- 10..20 Aug 2026, a click storm over all 42 cells fires
			-- on_pick EXACTLY 11 times - layout-independent proof.
		local
			cal: SW_CALENDAR
			mn, mx, probe: SIMPLE_DATE
			fired: CELL [INTEGER]
			r, c: INTEGER
		do
			create cal.make
			cal.set_bounds (0.0, 0.0, 250.0, 240.0)
			cal.select_date (2026, 8, 15)
			create mn.make (2026, 8, 10)
			create mx.make (2026, 8, 20)
			cal.set_min_date (mn)
			cal.set_max_date (mx)
			create probe.make (2026, 8, 5)
			assert ("the 5th is refused", not cal.date_allowed (probe))
			create probe.make (2026, 8, 10)
			assert ("the fence is IN", cal.date_allowed (probe))
			create fired.put (0)
			cal.set_on_pick (agent (y_, m_, d_: INTEGER; f: CELL [INTEGER]) do f.put (f.item + 1) end (?, ?, ?, fired))
			from
				r := 0
			until
				r > 5
			loop
				from
					c := 0
				until
					c > 6
				loop
					if cal.handle_click (5.0 + c * 34.0 + 17.0, 63.0 + r * 28.0 + 14.0) then
					end
					c := c + 1
				end
				r := r + 1
			end
			assert_integers_equal ("exactly the eleven allowed days fire", 11, fired.item)
			assert ("selection never left the window",
				cal.selected_day >= 10 and cal.selected_day <= 20)
		end

	test_file_dialog_pattern_sets
		local
			fd: SW_FILE_DIALOG
		do
			create fd.make_open (".")
			fd.set_extension_filter ("*.png;*.jpg")
			assert ("png passes", fd.passes_filter ("shot.PNG"))
			assert ("jpg passes", fd.passes_filter ("photo.jpg"))
			assert ("txt refused", not fd.passes_filter ("notes.txt"))
			fd.set_extension_filter ("png")
			assert ("legacy single suffix normalizes", fd.passes_filter ("a.png"))
			assert ("and still refuses others", not fd.passes_filter ("a.gif"))
			fd.set_extension_filter ("")
			assert ("empty filter admits everything", fd.passes_filter ("anything.xyz"))
		end

	test_color_picker_hex_input
		local
			cp: SW_COLOR_PICKER
			r0: NATURAL_32
		do
			create cp.make (0xFF0000)
			assert ("pickers join the Tab ring", cp.accepts_focus)
			assert ("full form parses", cp.from_hex ("#3A6EA5"))
			assert ("adopted within HSV rounding",
				(cp.rgb.bit_and (0xFF0000) |>> 16).to_integer_32 - 0x3A <= 2
				and (cp.rgb.bit_and (0xFF0000) |>> 16).to_integer_32 - 0x3A >= -2)
			assert ("short form expands", cp.from_hex ("#FA5"))
			assert ("garbage refused", not cp.from_hex ("#GG0011"))
			r0 := cp.rgb
			cp.handle_char (35)
			cp.handle_char (48)
			cp.handle_char (48)
			assert ("typing opened the readout edit", cp.is_editing_hex)
			cp.handle_char (27)
			assert ("Escape abandons", not cp.is_editing_hex)
			assert ("and the colour stands", cp.rgb = r0)
		end

	test_avatar_photo_clips_to_disc
			-- Pixel proof: a white photo drawn into the avatar leaves
			-- the bounding-box corner BLACK (outside the disc) and
			-- the centre white.
		local
			th: SW_THEME
			surf, photo: CAIRO_SURFACE
			ctx, pctx: CAIRO_CONTEXT
			p, pp: SW_PAINTER
			av: SW_AVATAR
			mp: MANAGED_POINTER
			corner, center: NATURAL_32
		do
			create th.make_dark
			create surf.make (40, 40)
			create ctx.make (surf)
			create p.make (ctx, th)
			p.set_color (0x000000)
			p.fill_rect (0.0, 0.0, 40.0, 40.0)
			create photo.make (8, 8)
			create pctx.make (photo)
			create pp.make (pctx, th)
			pp.set_color (0xFFFFFF)
			pp.fill_rect (0.0, 0.0, 8.0, 8.0)
			create av.make ("Larry Rix")
			av := av.with_image (photo).with_diameter (32.0)
			av.set_bounds (4.0, 4.0, 32.0, 32.0)
			av.draw (p)
			surf.flush.do_nothing
			create mp.share_from_pointer (surf.data, 40 * surf.stride)
			corner := mp.read_natural_32 (6 * surf.stride + 6 * 4)
			center := mp.read_natural_32 (20 * surf.stride + 20 * 4)
			assert_integers_equal ("the corner stays black (clipped)",
				0xFF000000, corner.to_integer_32)
			assert ("the centre carries the photo",
				center.bit_and (0x00FFFFFF) /= 0)
		end

feature -- Batch 5: layout

	test_row_wrap_math
			-- The pure law: greedy fill, oversized children take
			-- their own line, empty in - empty out.
		local
			r: SW_ROW
			ws: ARRAYED_LIST [REAL_64]
			starts: ARRAYED_LIST [INTEGER]
		do
			create r.make
			create ws.make (3)
			ws.extend (50.0)
			ws.extend (50.0)
			ws.extend (50.0)
			starts := r.wrap_starts (ws, 8.0, 120.0)
			assert_integers_equal ("two lines", 2, starts.count)
			assert_integers_equal ("break lands on the third", 3, starts.i_th (2))
			ws.wipe_out
			ws.extend (50.0)
			ws.extend (200.0)
			ws.extend (50.0)
			starts := r.wrap_starts (ws, 8.0, 120.0)
			assert_integers_equal ("the giant takes its own line", 3, starts.count)
			ws.wipe_out
			starts := r.wrap_starts (ws, 8.0, 120.0)
			assert ("empty in, empty out", starts.is_empty)
		end

	test_row_wrap_arranges_lines
			-- Three 10px dots in a 30px row: two on the first line,
			-- the third wrapped beneath - and preferred_height says
			-- so before arrange does.
		local
			r: SW_ROW
			b1, b2, b3: SW_BADGE
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
		do
			create th.make_dark
			create surf.make (8, 8)
			create ctx.make (surf)
			create p.make (ctx, th)
			create r.make
			create b1.make_dot
			create b2.make_dot
			create b3.make_dot
			r := r.add (b1).add (b2).add (b3).with_wrapping
			assert_reals_equal ("two lines tall at width 30",
				28.0, r.preferred_height (p, 30.0), 0.000_1)
			r.set_bounds (0.0, 0.0, 30.0, 60.0)
			r.arrange (p)
			assert_reals_equal ("first two share a line", b1.y, b2.y, 0.000_1)
			assert ("the third wrapped beneath", b3.y > b1.y + 9.0)
			assert_reals_equal ("and rewinds to the left edge", 0.0, b3.x, 0.000_1)
		end

	test_splitter_horizontal_and_dblclick_reset
		local
			sp: SW_SPLITTER
			a, b: SW_LABEL
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
		do
			create th.make_dark
			create surf.make (8, 8)
			create ctx.make (surf)
			create p.make (ctx, th)
			create a.make_ui ("top")
			create b.make_ui ("bottom")
			create sp.make (a, b)
			sp := sp.with_horizontal
			assert_integers_equal ("north-south cursor over the divider", 4, sp.cursor_kind)
			sp.set_bounds (0.0, 0.0, 100.0, 209.0)
			sp.arrange (p)
			assert_reals_equal ("top pane takes half the slack", 100.0, a.height, 0.000_1)
			assert_reals_equal ("bottom starts past the divider", 109.0, b.y, 0.000_1)
			sp.set_ratio (0.7)
			assert ("double-click on the divider answers",
				sp.handle_double_click (50.0, (209.0 - 9.0) * 0.7 + 4.0))
			assert_reals_equal ("and the ratio snaps home", 0.5, sp.ratio, 0.000_1)
		end

	test_tabs_lazy_builders
			-- Builders fire on FIRST selection only; adding is free.
		local
			tb: SW_TABS
			built: CELL [INTEGER]
		do
			create built.put (0)
			create tb.make
			tb.add_lazy_page ("A", agent (c: CELL [INTEGER]): SW_WIDGET
				do
					c.put (c.item + 1)
					create {SW_SPACER} Result.make
				end (built))
			tb.add_lazy_page ("B", agent (c: CELL [INTEGER]): SW_WIDGET
				do
					c.put (c.item + 1)
					create {SW_SPACER} Result.make
				end (built))
			assert_integers_equal ("adding builds nothing", 0, built.item)
			tb.select_tab (2)
			assert_integers_equal ("first selection builds B", 1, built.item)
			assert ("the built page is adopted",
				attached tb.selected_page as pg and then pg.parent = tb)
			tb.select_tab (1)
			assert_integers_equal ("and then A", 2, built.item)
			tb.select_tab (2)
			assert_integers_equal ("re-selection never rebuilds", 2, built.item)
		end

	test_separator_vertical
		local
			s: SW_SEPARATOR
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
		do
			create th.make_dark
			create surf.make (8, 8)
			create ctx.make (surf)
			create p.make (ctx, th)
			create s.make_vertical
			assert ("upright", s.is_vertical)
			assert_reals_equal ("slim in a row", 9.0, s.preferred_width (p), 0.000_1)
			assert_reals_equal ("with presence", 24.0, s.preferred_height (p, 100.0), 0.000_1)
		end

	test_drawer_all_four_edges
			-- The S04 gutters, landed: top and bottom tabs register
			-- (the old precondition refused them), reserve their
			-- gutters, open drawers in the new modes - and a full
			-- headless render survives every edge.
		local
			w: SW_WINDOW
			th: SW_THEME
		do
			create th.make_dark
			create w.make ("edges", 0, 0, 400, 300, th)
			w.set_root (create {SW_LABEL}.make_ui ("page"))
			w.add_drawer_tab ("LOG", agent (): SW_WIDGET do create {SW_LABEL} Result.make_ui ("log") end, w.Edge_top)
			w.add_drawer_tab ("OUT", agent (): SW_WIDGET do create {SW_LABEL} Result.make_ui ("out") end, w.Edge_bottom)
			w.add_drawer_tab ("NAV", agent (): SW_WIDGET do create {SW_LABEL} Result.make_ui ("nav") end, w.Edge_left)
			assert_reals_equal ("top gutter reserved", 22.0, w.gutter_top, 0.000_1)
			assert_reals_equal ("bottom gutter reserved", 22.0, w.gutter_bottom, 0.000_1)
			assert_reals_equal ("left gutter reserved", 22.0, w.gutter_left, 0.000_1)
			assert_reals_equal ("right stays open", 0.0, w.gutter_right, 0.000_1)
			w.request_render
			w.open_drawer_from_tab (1, True)
			assert ("a drawer is up", w.is_drawer_mode)
			w.request_render
			w.close_sheet
			w.open_drawer_from_tab (2, True)
			assert ("the bottom one too", w.is_drawer_mode)
			w.request_render
			w.close_sheet
			w.show_drawer_edge (create {SW_LABEL}.make_ui ("bar"), 180.0, w.Edge_top)
			assert ("and the public edge call presents", w.is_drawer_mode)
			w.request_render
		end

feature -- The pretty map (Natural Earth 110m, generated)

	test_world_geometry_sanity
			-- The generated planet: ring and point counts pinned,
			-- every coordinate inside the geographic domain.
		local
			g: SW_WORLD_GEOMETRY
			pts, biggest, k: INTEGER
			sane: BOOLEAN
		do
			create g
			assert_integers_equal ("127 exterior rings", 127, g.polygons.count)
			sane := True
			across
				g.polygons as poly
			loop
				pts := pts + poly.count // 2
				if poly.count // 2 > biggest then
					biggest := poly.count // 2
				end
				from
					k := 1
				until
					k > poly.count or not sane
				loop
					if k \\ 2 = 1 then
						sane := poly [k] >= -180.0 and poly [k] <= 180.0
					else
						sane := poly [k] >= -90.0 and poly [k] <= 90.0
					end
					k := k + 1
				end
			end
			assert_integers_equal ("4964 points survived generation", 4964, pts)
			assert_integers_equal ("Eurasia-Africa is the biggest ring", 1298, biggest)
			assert ("every lon in -180..180, every lat in -90..90", sane)
		end

	test_map_draws_real_coastlines
			-- Pixel truth on the drawn planet: Kansas is land-
			-- coloured, the mid-Atlantic wears the card surface.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			m: SW_MAP
			mp: MANAGED_POINTER
			land_px, sea_px, want_land, want_sea: NATURAL_32
			kx, ky, ax, ay: INTEGER
		do
			create th.make_dark
			create surf.make (300, 160)
			create ctx.make (surf)
			create p.make (ctx, th)
			create m.make
			m.set_bounds (0.0, 0.0, 300.0, 160.0)
			m.arrange (p)
			m.draw (p)
			surf.flush.do_nothing
			create mp.share_from_pointer (surf.data, 160 * surf.stride)
			kx := m.x_of_lon (-98.5).rounded
			ky := m.y_of_lat (38.5).rounded
			ax := m.x_of_lon (-30.0).rounded
			ay := m.y_of_lat (25.0).rounded
			land_px := mp.read_natural_32 (ky * surf.stride + kx * 4)
			sea_px := mp.read_natural_32 (ay * surf.stride + ax * 4)
			want_land := {NATURAL_32} 0xFF000000 + th.surface_variant
			want_sea := {NATURAL_32} 0xFF000000 + th.surface
			assert_integers_equal ("Kansas wears the land colour",
				want_land.to_integer_32, land_px.to_integer_32)
			assert_integers_equal ("the mid-Atlantic wears the surface",
				want_sea.to_integer_32, sea_px.to_integer_32)
		end

	test_world_cities_sanity
			-- 243 places, biggest first, every coordinate on Earth.
		local
			wc: SW_WORLD_CITIES
			sane: BOOLEAN
		do
			create wc
			assert_integers_equal ("243 places", 243, wc.cities.count)
			assert_strings_equal ("Tokyo leads (biggest first)", "Tokyo", wc.cities.first.name)
			assert_strings_equal ("in Japan", "Japan", wc.cities.first.country)
			assert_integers_equal ("with its peak population", 35_676_000, wc.cities.first.population)
			sane := True
			across
				wc.cities as c
			loop
				sane := sane and c.lat >= -90.0 and c.lat <= 90.0
					and c.lon >= -180.0 and c.lon <= 180.0
					and c.population >= 0 and not c.name.is_empty
			end
			assert ("every record on the planet, named, non-negative", sane)
			across
				wc.cities as c
			loop
				if c.name.same_string_general ("Atlanta") then
					assert_integers_equal ("Atlanta rides Eastern: civil -300, not solar -6h",
						-300, c.offset_minutes)
				end
			end
		end

	test_map_city_adoption_and_bands
			-- The floor filters, labels carry the data, and band
			-- queries answer biggest-first - empty for open ocean.
		local
			m: SW_MAP
			b: ARRAYED_LIST [STRING_32]
		do
			create m.make
			m.add_world_cities (5_000_000)
			assert_integers_equal ("38 five-million cities became markers", 38, m.markers.count)
			assert ("labels carry the data, civil offset included",
				m.markers.first.label.has_substring ({STRING_32} "Tokyo")
				and m.markers.first.label.has_substring ({STRING_32} "Japan")
				and m.markers.first.label.has_substring ({STRING_32} "35.7M")
				and m.markers.first.label.has_substring ({STRING_32} "UTC+9"))
			b := m.cities_in_band (0, 3)
			assert_integers_equal ("civil band zero offers three", 3, b.count)
			assert_strings_equal ("London biggest in civil zero", "London", b.first)
			b := m.cities_in_band (-5, 8)
			assert ("ATLANTA ANSWERS UNDER EASTERN (the civil law, Larry's case)",
				across b as nm some nm.same_string_general ("Atlanta") end)
			assert_integers_equal ("open-ocean -10 is honestly empty", 0, m.cities_in_band (-10, 5).count)
		end

	test_map_zoom_laws
			-- The wheel zooms AT the pointer (the ground under the
			-- cursor stays put), clamps 1..16, pans keep the grab
			-- under the hand, and double-click goes home.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			m: SW_MAP
			ax, ay: REAL_64
			k: INTEGER
		do
			create th.make_dark
			create surf.make (300, 160)
			create ctx.make (surf)
			create p.make (ctx, th)
			create m.make
			m.set_bounds (0.0, 0.0, 300.0, 160.0)
			m.arrange (p)
			m.draw (p)
				-- roundtrip law holds through any window
			m.set_view (4.0, 30.0, 20.0)
			assert_reals_equal ("projection inverts at zoom 4",
				37.0, m.lon_at_x (m.x_of_lon (37.0)), 0.000_1)
			assert_reals_equal ("latitude too",
				12.5, m.lat_at_y (m.y_of_lat (12.5)), 0.000_1)
				-- the anchor law: zoom in at a known place
			m.set_view (2.0, 0.0, 0.0)
			ax := m.x_of_lon (10.0)
			ay := m.y_of_lat (10.0)
			m.set_hover_point (ax, ay)
			assert ("wheel-in answers", m.handle_wheel (120))
			assert_reals_equal ("zoom grew a quarter step", 2.5, m.effective_zoom, 0.000_1)
			assert_reals_equal ("the ground under the cursor stayed put",
				10.0, m.lon_at_x (ax), 0.000_1)
			assert_reals_equal ("in latitude as well",
				10.0, m.lat_at_y (ay), 0.000_1)
				-- clamps both ways
			from
				k := 1
			until
				k > 20
			loop
				if m.handle_wheel (-120) then
				end
				k := k + 1
			end
			assert_reals_equal ("wheel-out floors at the whole world", 1.0, m.effective_zoom, 0.000_1)
			from
				k := 1
			until
				k > 40
			loop
				if m.handle_wheel (120) then
				end
				k := k + 1
			end
			assert_reals_equal ("wheel-in ceils at 16", 16.0, m.effective_zoom, 0.000_1)
				-- pan keeps the grab under the hand
			m.set_view (4.0, 0.0, 0.0)
			if m.handle_click (m.plot_x + m.plot_w / 2.0, m.plot_y + m.plot_h / 2.0) then
			end
			m.handle_drag (m.plot_x + m.plot_w / 2.0 + 40.0, m.plot_y + m.plot_h / 2.0)
			assert ("dragging east shows the west", m.view_cx < -1.0)
				-- and home again
			if m.handle_double_click (10.0, 10.0) then
			end
			assert_reals_equal ("double-click resets", 1.0, m.effective_zoom, 0.000_1)
			assert_reals_equal ("centred home", 0.0, m.view_cx, 0.000_1)
		end

	test_zoomed_band_pick_stays_true
			-- The picker's 15-degree arithmetic reads through the
			-- zoom window - a zoomed click still names its band.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			zp: SW_TIMEZONE_PICKER
		do
			create th.make_dark
			create surf.make (300, 160)
			create ctx.make (surf)
			create p.make (ctx, th)
			create zp.make
			zp.set_bounds (0.0, 0.0, 300.0, 160.0)
			zp.arrange (p)
			zp.draw (p)
			zp.set_view (2.0, 30.0, 10.0)
			if zp.handle_click (zp.x_of_lon (31.0), zp.plot_y + 10.0) then
			end
			assert_integers_equal ("31 degrees east is band +2", 2, zp.selected_offset)
		end

	test_click_on_atlanta_answers_eastern
			-- Larry's law: zones are not bands. Atlanta sits at 84W
			-- (solar arithmetic says -6) but a click ON the city
			-- answers its CIVIL zone, -5. Open ocean still answers
			-- solar, the only honest thing it can say.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			zp: SW_TIMEZONE_PICKER
		do
			create th.make_dark
			create surf.make (600, 300)
			create ctx.make (surf)
			create p.make (ctx, th)
			create zp.make
			zp.add_world_cities (2_000_000)
			zp.set_bounds (0.0, 0.0, 600.0, 300.0)
			zp.arrange (p)
			zp.draw (p)
			assert_integers_equal ("solar arithmetic at 84.37W says -6",
				-6, zp.offset_at (zp.x_of_lon (-84.37)))
			if zp.handle_click (zp.x_of_lon (-84.37), zp.y_of_lat (33.74)) then
			end
			assert_integers_equal ("but clicking ATLANTA answers Eastern",
				-5, zp.selected_offset)
			if zp.handle_click (zp.x_of_lon (-40.0), zp.y_of_lat (30.0)) then
			end
			assert_integers_equal ("open Atlantic answers solar -3",
				-3, zp.selected_offset)
		end

end
