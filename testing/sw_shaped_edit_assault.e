note
	description: "[
		Assault on SW_TEXT_BOX's caret geometry over BOTH engines: the
		toy path (no kit) and the shaped path (a real SW_SHAPING kit
		over an offscreen painter). The law under test is one sentence:
		for every offset, the x the caret stands at maps back to that
		offset - in Latin, in Hebrew where the caret walks leftward,
		across a bidi boundary, and across paragraph breaks, whose
		caret now stands at the START of the line it opens.
	]"

class
	SW_SHAPED_EDIT_ASSAULT

inherit
	TEST_SET_BASE

feature -- Toy path

	test_toy_caret_round_trip
		local
			b: SW_TEXT_BOX
			c: INTEGER
		do
			create b.make ("hello wide world")
			b.set_bounds (0.0, 0.0, 300.0, b.preferred_height (plain_painter, 300.0))
			assert_false ("toy path", b.is_shaped_layout)
			assert_integers_equal ("one line", 1, b.line_count)
			from c := 0 until c > b.text.count loop
				assert_integers_equal ("toy round trip at " + c.out, c, offset_under (b, c))
				if c > 0 then
					assert ("toy caret walks rightward", b.x_at_offset (c) >= b.x_at_offset (c - 1))
				end
				c := c + 1
			end
		end

	test_toy_newline_opens_a_line
		local
			b: SW_TEXT_BOX
		do
			create b.make ("ab%Ncd")
			b.set_bounds (0.0, 0.0, 300.0, b.preferred_height (plain_painter, 300.0))
			assert_integers_equal ("two lines", 2, b.line_count)
			assert_integers_equal ("after b is line 0", 0, b.line_at_offset (2))
			assert_integers_equal ("after the newline is line 1", 1, b.line_at_offset (3))
			assert_reals_equal ("and at its start", 0.0, b.x_at_offset (3), 1.0e-9)
			assert_integers_equal ("after d is line 1", 1, b.line_at_offset (5))
				-- HOME and END on the second line stay on it
			if b.handle_click (b.Pad_x + b.x_at_offset (5), b.Pad_y + line_mid (b, 1)) then end
			assert_integers_equal ("clicked to the end", 5, b.caret)
			b.handle_key (36, False)
			assert_integers_equal ("HOME lands after the newline", 3, b.caret)
			b.handle_key (35, False)
			assert_integers_equal ("END lands after d", 5, b.caret)
			b.handle_key (38, False)
			assert_integers_equal ("UP keeps the column", 2, b.caret)
		end

feature -- Shaped path

	test_shaped_latin_round_trip
		local
			b: SW_TEXT_BOX
			c: INTEGER
		do
			create b.make ("hello wide world")
			b.set_bounds (0.0, 0.0, 300.0, b.preferred_height (shaped_painter, 300.0))
			assert ("shaped path", b.is_shaped_layout)
			assert_integers_equal ("one line", 1, b.line_count)
			from c := 0 until c > b.text.count loop
				assert_integers_equal ("shaped round trip at " + c.out, c, offset_under (b, c))
				assert_false ("latin is ltr", c > 0 and then b.is_rtl_at (c))
				if c > 0 then
					assert ("shaped caret walks rightward", b.x_at_offset (c) >= b.x_at_offset (c - 1))
				end
				c := c + 1
			end
		end

	test_shaped_hebrew_caret_walks_leftward
		local
			b: SW_TEXT_BOX
			c: INTEGER
		do
			create b.make (shalom)
			b.set_bounds (0.0, 0.0, 300.0, b.preferred_height (shaped_painter, 300.0))
			assert ("shaped path", b.is_shaped_layout)
			assert ("shin is rtl", b.is_rtl_at (1))
			assert ("mem is rtl", b.is_rtl_at (4))
			assert ("offset 0 stands at the RIGHT", b.x_at_offset (0) > b.x_at_offset (4))
			from c := 1 until c > 4 loop
				assert ("each step moves LEFT", b.x_at_offset (c) < b.x_at_offset (c - 1))
				c := c + 1
			end
			from c := 0 until c > 4 loop
				assert_integers_equal ("hebrew round trip at " + c.out, c, offset_under (b, c))
				c := c + 1
			end
		end

	test_shaped_mixed_round_trip
		local
			b: SW_TEXT_BOX
			s: STRING_32
			c: INTEGER
		do
			create s.make_from_string ("abc ")
			s.append (shalom)
			s.append (" xyz")
			create b.make (s)
			b.set_bounds (0.0, 0.0, 400.0, b.preferred_height (shaped_painter, 400.0))
			assert ("shaped path", b.is_shaped_layout)
			assert_false ("a is ltr", b.is_rtl_at (1))
			assert ("shin is rtl", b.is_rtl_at (5))
			assert ("mem is rtl", b.is_rtl_at (8))
			assert_false ("z is ltr", b.is_rtl_at (s.count))
			from c := 0 until c > s.count loop
				if c <= 3 or c >= 9 then
						-- pure Latin: exact
					assert_integers_equal ("mixed round trip at " + c.out, c, offset_under (b, c))
				else
						-- at and inside the Hebrew: the same pixel on the
						-- same line, since two offsets share a boundary x
						-- where the directions meet (see offset_on_line)
					assert_reals_equal ("mixed same pixel at " + c.out,
						b.x_at_offset (c), b.x_at_offset (offset_under (b, c)), 0.5)
					assert_integers_equal ("mixed same line at " + c.out,
						b.line_at_offset (c), b.line_at_offset (offset_under (b, c)))
				end
				c := c + 1
			end
				-- the boundary tie resolves to the LTR side, deterministically
			assert_integers_equal ("after the space, not after the mem", 4, offset_under (b, 4))
			assert_integers_equal ("the mem's own boundary maps to the space", 4, offset_under (b, 8))
				-- the Hebrew sits between the Latin words on screen
			assert ("hebrew right of abc", b.x_at_offset (4) <= b.x_at_offset (8))
			assert ("xyz right of hebrew", b.x_at_offset (8) <= b.x_at_offset (s.count))
		end

	test_shaped_paragraphs_stack
		local
			b: SW_TEXT_BOX
		do
			create b.make ("ab%Ncd%N%Nef")
			b.set_bounds (0.0, 0.0, 300.0, b.preferred_height (shaped_painter, 300.0))
			assert ("shaped path", b.is_shaped_layout)
			assert_integers_equal ("four lines", 4, b.line_count)
			assert_integers_equal ("after the first newline", 1, b.line_at_offset (3))
			assert_reals_equal ("at the start of line 1", 0.0, b.x_at_offset (3), 1.0e-9)
			assert_integers_equal ("the empty line", 2, b.line_at_offset (6))
			assert_integers_equal ("after the empty line", 3, b.line_at_offset (7))
			assert_integers_equal ("f on the last line", 3, b.line_at_offset (9))
			assert ("content taller than one line", b.content_height > 3.0 * b.x_at_offset (1))
				-- HOME and END on the empty line stay put
			if b.handle_click (b.Pad_x + 1.0, b.Pad_y + line_mid (b, 2)) then end
			assert_integers_equal ("clicked onto the empty line", 6, b.caret)
			b.handle_key (36, False)
			assert_integers_equal ("HOME stays", 6, b.caret)
			b.handle_key (35, False)
			assert_integers_equal ("END stays", 6, b.caret)
			b.handle_key (40, False)
			assert_integers_equal ("DOWN reaches line 3", 3, b.line_at_offset (b.caret))
		end

	test_shaped_wrap_stays_inside
		local
			b: SW_TEXT_BOX
			c: INTEGER
		do
			create b.make ("the quick brown fox jumps over the lazy dog again and again and again")
			b.set_bounds (0.0, 0.0, 160.0, b.preferred_height (shaped_painter, 160.0))
			assert ("shaped path", b.is_shaped_layout)
			assert ("wrapped", b.line_count > 1)
			from c := 0 until c > b.text.count loop
				assert ("every caret inside the wrap", b.x_at_offset (c) <= 160.0 - 2.0 * b.Pad_x + 0.5)
				assert_integers_equal ("wrapped round trip at " + c.out, c, offset_under (b, c))
				c := c + 1
			end
		end

	test_masked_box_keeps_the_toy_path
		local
			b: SW_TEXT_BOX
		do
			create b.make_password ("secret")
			b.set_bounds (0.0, 0.0, 200.0, b.preferred_height (shaped_painter, 200.0))
			assert_false ("bullets are never shaped", b.is_shaped_layout)
			b.toggle_reveal
			b.set_bounds (0.0, 0.0, 200.0, b.preferred_height (shaped_painter, 200.0))
			assert ("revealed text is shaped", b.is_shaped_layout)
		end

	test_click_and_drag_select_hebrew
		local
			b: SW_TEXT_BOX
		do
			create b.make (shalom)
			b.set_bounds (0.0, 0.0, 300.0, b.preferred_height (shaped_painter, 300.0))
			if b.handle_click (b.Pad_x + b.x_at_offset (2), b.Pad_y + line_mid (b, 0)) then end
			assert_integers_equal ("click lands after lamed", 2, b.caret)
			b.handle_drag (b.Pad_x + b.x_at_offset (0), b.Pad_y + line_mid (b, 0))
			assert_integers_equal ("drag to the right edge is offset 0", 0, b.caret)
			assert ("two letters selected", b.has_selection)
			assert ("shin and lamed", b.selected_text.same_string (shalom.substring (1, 2)))
		end

	test_headless_paint_both_paths
		local
			b: SW_TEXT_BOX
			s: STRING_32
		do
			create s.make_from_string ("abc ")
			s.append (shalom)
			s.append ("%Nsecond line")
			create b.make (s)
			b.set_bounds (10.0, 10.0, 300.0, 80.0)
			b.set_focused (True)
			b.select_all
			b.draw (shaped_painter)
			b.draw (plain_painter)
			b.draw (shaped_painter)
			assert ("painted three times", True)
		end

feature -- Measurement (0.8.2)

	test_toy_height_ignores_the_last_font
			-- The same box, text and width measure the same height whatever
			-- font the painter was left holding - toy path.
		do
			check_height_ignores_the_last_font (plain_painter, "toy")
		end

	test_shaped_height_ignores_the_last_font
			-- The same, on the shaped path.
		do
			check_height_ignores_the_last_font (shaped_painter, "shaped")
		end

	test_toy_lines_stack_at_row_height
			-- N plain lines are N x `row_height', and a five-row cap holds
			-- exactly five lines - toy path.
		do
			check_lines_stack_at_row_height (plain_painter, "toy")
		end

	test_shaped_lines_stack_at_row_height
			-- The same, on the shaped path, where the row is the kit's own
			-- line height and not the theme's toy pitch.
		do
			check_lines_stack_at_row_height (shaped_painter, "shaped")
		end

feature {NONE} -- Measurement checks

	check_height_ignores_the_last_font (a_p: SW_PAINTER; a_path: STRING)
			-- One box measured four times at one width, after four different
			-- fonts were selected, one of them three times the body size so
			-- the floor `min_control_height' would bind if it were read under it.
		local
			b: SW_TEXT_BOX
			h_body, h_ui, h_mono, h_big: REAL_64
		do
			create b.make ("hello")
			a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
			h_body := b.preferred_height (a_p, 300.0)
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			h_ui := b.preferred_height (a_p, 300.0)
			a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_label, True)
			h_mono := b.preferred_height (a_p, 300.0)
			a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body * 3.0, True)
			h_big := b.preferred_height (a_p, 300.0)
			assert_reals_equal (a_path + ": after the UI font", h_body, h_ui, 0.000_1)
			assert_reals_equal (a_path + ": after the mono font", h_body, h_mono, 0.000_1)
			assert_reals_equal (a_path + ": after a font three times the body", h_body, h_big, 0.000_1)
		end

	check_lines_stack_at_row_height (a_p: SW_PAINTER; a_path: STRING)
			-- One to eight explicit lines: content is exactly N rows (a blank
			-- line and an empty box included), the box
			-- is those rows plus its inside inset (or `minimum_height',
			-- whichever is larger), and a cap of five rows plus the inset is
			-- what five lines need - the sixth is one row more.
		local
			b: SW_TEXT_BOX
			l_row, l_h, l_cap, l_five, l_six: REAL_64
			n: INTEGER
			l_text: STRING_32
		do
			create b.make ("")
			l_row := b.row_height (a_p)
			create l_text.make_from_string_general ("line 1")
			from n := 1 until n > 8 loop
				if n > 1 then
					l_text.append_string_general ("%Nline " + n.out)
				end
				b.set_text (l_text)
				l_h := b.preferred_height (a_p, 300.0)
				assert_integers_equal (a_path + ": " + n.out + " lines laid out", n, b.line_count)
				assert_reals_equal (a_path + ": " + n.out + " lines are " + n.out + " rows",
					n * l_row, b.content_height, 0.01)
				assert_reals_equal (a_path + ": " + n.out + " lines measure their rows plus the inset",
					(n * l_row + 2.0 * b.Pad_y).max (b.minimum_height (a_p)), l_h, 0.01)
				if n = 5 then
					l_five := l_h
				elseif n = 6 then
					l_six := l_h
				end
				n := n + 1
			end
			b.set_text ({STRING_32} "line 1%N%Nline 3")
			l_h := b.preferred_height (a_p, 300.0)
			assert_reals_equal (a_path + ": a blank line is a row like the others", 3.0 * l_row, b.content_height, 0.01)
			b.set_text ({STRING_32} "")
			l_h := b.preferred_height (a_p, 300.0)
			assert_reals_equal (a_path + ": and an empty box holds one row", l_row, b.content_height, 0.01)
			l_cap := 5.0 * l_row + 2.0 * b.Pad_y
			assert_reals_equal (a_path + ": a five-row cap is what five lines need", l_cap, l_five, 0.01)
			assert_reals_equal (a_path + ": and a sixth line is one row past it", l_cap + l_row, l_six, 0.01)
		end

feature {NONE} -- Helpers

	offset_under (a_b: SW_TEXT_BOX; a_offset: INTEGER): INTEGER
			-- Where a click at the caret's own x on its own line lands.
		do
			Result := a_b.offset_at (a_b.x + a_b.Pad_x + a_b.x_at_offset (a_offset),
				a_b.y + a_b.Pad_y + line_mid (a_b, a_b.line_at_offset (a_offset)))
		end

	line_mid (a_b: SW_TEXT_BOX; a_line: INTEGER): REAL_64
			-- A y inside visual line `a_line', below Pad_y.
		do
			Result := a_b.content_height / a_b.line_count * (a_line + 0.5)
		end

	shalom: STRING_32
			-- shin lamed vav mem, as code points.
		do
			create Result.make (4)
			Result.append_code (0x05E9)
			Result.append_code (0x05DC)
			Result.append_code (0x05D5)
			Result.append_code (0x05DD)
		ensure
			four: Result.count = 4
		end

feature {NONE} -- Fixture

	plain_painter: SW_PAINTER
			-- Cairo's toy path: no kit.
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (600, 300)
			create ctx.make (surf)
			create th.make_light
			create Result.make (ctx, th)
		end

	shaped_painter: SW_PAINTER
			-- The shaped path: a real kit (fonts from the system; the
			-- emoji artwork from beside the exe when staged, degrading
			-- to a note when not - Hebrew needs no artwork).
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			kit: SW_SHAPING
		once
			create surf.make (600, 300)
			create ctx.make (surf)
			create th.make_light
			create kit.make
			kit.set_theme_faces (th)
			create Result.make (ctx, th)
			Result.set_shaping (kit)
		end

end
