note
	description: "[
		SW_TEXT_BOX's text frame, as a host that scrolls or shows code
		needs it (simple_gui's code editor, 1v-b):

		TAB STOPS: `set_tab_spaces' moves the stops, on both engines; 8
		stays the default.

		FACE: `set_text_role' sets the text in a role's face; the mono
		face gives every character the same advance; 0 gives the field's
		own face back.

		FRAME: a descendant that redefines `text_left', `text_top' and
		`wrap_width_in' moves the painted text, the hit test and the wrap
		together; a plain box stays where it was.
	]"
	author: "Larry Rix"

class
	SW_TEXT_FRAME_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tab stops

	test_tab_stops_follow_tab_spaces_on_the_toy_path
		do
			check_tab_stops_follow_tab_spaces (plain_painter, "toy")
		end

	test_tab_stops_follow_tab_spaces_on_the_shaped_path
		do
			check_tab_stops_follow_tab_spaces (shaped_painter, "shaped")
		end

feature -- Face

	test_mono_role_gives_equal_advances_on_the_toy_path
		do
			check_mono_role_gives_equal_advances (plain_painter, "toy")
		end

	test_mono_role_gives_equal_advances_on_the_shaped_path
		do
			check_mono_role_gives_equal_advances (shaped_painter, "shaped")
		end

feature -- Frame

	test_a_plain_box_keeps_its_frame
			-- The defaults are the insets the box always had.
		local
			b: SW_TEXT_BOX
		do
			create b.make ({STRING_32} "abc")
			b.set_bounds (20.0, 30.0, 200.0, 60.0)
			assert_reals_equal ("the text starts at the left inset", 20.0 + b.Pad_x, b.text_left, 0.0001)
			assert_reals_equal ("the text starts at the top inset", 30.0 + b.Pad_y, b.text_top, 0.0001)
			assert_reals_equal ("the lines wrap inside both insets", 200.0 - 2.0 * b.Pad_x, b.wrap_width_in (200.0), 0.0001)
			assert_integers_equal ("the field's own face", 0, b.text_role)
			assert_integers_equal ("eight spaces to a stop", 8, b.tab_spaces)
		end

	test_a_moved_frame_moves_the_hit_test_on_the_toy_path
		do
			check_a_moved_frame_moves_the_hit_test (plain_painter, "toy")
		end

	test_a_moved_frame_moves_the_hit_test_on_the_shaped_path
		do
			check_a_moved_frame_moves_the_hit_test (shaped_painter, "shaped")
		end

	test_a_moved_frame_moves_the_painted_text_on_the_toy_path
		do
			check_a_moved_frame_moves_the_painted_text (plain_painter, "toy")
		end

	test_a_moved_frame_moves_the_painted_text_on_the_shaped_path
		do
			check_a_moved_frame_moves_the_painted_text (shaped_painter, "shaped")
		end

feature {NONE} -- Checks

	check_tab_stops_follow_tab_spaces (a_p: SW_PAINTER; a_path: STRING)
		local
			b: SW_TEXT_BOX
			l_h, l_eight: REAL_64
		do
			create b.make ({STRING_32} "%Tb")
			b.set_bounds (0.0, 0.0, 400.0, 100.0)
			l_h := b.preferred_height (a_p, 400.0)
			l_eight := b.geometry.tab_width
			assert_real_greater_than (a_path + ": a stop is positive", l_eight, 8.0)
			assert_reals_equal (a_path + ": b stands on the eight-space stop", l_eight, b.geometry.x_of (2), 0.01)
			b.set_tab_spaces (4)
			assert_integers_equal (a_path + ": the stops are four spaces apart", 4, b.tab_spaces)
			l_h := b.preferred_height (a_p, 400.0)
			assert_reals_equal (a_path + ": a stop is half as far", l_eight / 2.0, b.geometry.tab_width, 0.01)
			assert_reals_equal (a_path + ": b stands on the four-space stop", l_eight / 2.0, b.geometry.x_of (2), 0.01)
			assert_reals_equal (a_path + ": the caret after the tab is at the stop", l_eight / 2.0, b.x_at_offset (1), 0.01)
			b.set_tab_spaces (2)
			l_h := b.preferred_height (a_p, 400.0)
			assert_reals_equal (a_path + ": and a quarter as far at two", l_eight / 4.0, b.geometry.x_of (2), 0.01)
				-- a text set afterwards keeps the stops
			b.set_text ({STRING_32} "%T%Tc")
			l_h := b.preferred_height (a_p, 400.0)
			assert_reals_equal (a_path + ": two tabs reach the second two-space stop", l_eight / 2.0, b.geometry.x_of (3), 0.01)
		end

	check_mono_role_gives_equal_advances (a_p: SW_PAINTER; a_path: STRING)
		local
			b: SW_TEXT_BOX
			l_h, l_i, l_w: REAL_64
		do
			create b.make ({STRING_32} "iW")
			b.set_bounds (0.0, 0.0, 400.0, 100.0)
			l_h := b.preferred_height (a_p, 400.0)
			l_i := b.geometry.width_of (1)
			l_w := b.geometry.width_of (2)
			assert_real_greater_than (a_path + ": in the field's own face W is wider than i", l_w, l_i + 1.0)
			b.set_text_role ({SW_PAINTER}.Role_mono)
			assert_integers_equal (a_path + ": the role is kept", {SW_PAINTER}.Role_mono, b.text_role)
			l_h := b.preferred_height (a_p, 400.0)
			assert_real_greater_than (a_path + ": i has width in the mono face", b.geometry.width_of (1), 1.0)
			assert_reals_equal (a_path + ": in the mono face i and W advance alike", b.geometry.width_of (1),
				b.geometry.width_of (2), 0.01)
				-- a tab stop is counted in the mono face's own spaces
			b.set_text ({STRING_32} "ii%TW")
			b.set_tab_spaces (4)
			l_h := b.preferred_height (a_p, 400.0)
			assert_reals_equal (a_path + ": four mono characters reach a four-space stop", 4.0 * b.geometry.width_of (1),
				b.geometry.x_of (4), 0.05)
				-- drawing in the mono face raises nothing
			b.draw (a_p)
				-- 0 gives the field's own face back
			b.set_text ({STRING_32} "iW")
			b.set_text_role (0)
			l_h := b.preferred_height (a_p, 400.0)
			assert_reals_equal (a_path + ": i is as wide as it was", l_i, b.geometry.width_of (1), 0.01)
			assert_reals_equal (a_path + ": W is as wide as it was", l_w, b.geometry.width_of (2), 0.01)
		end

	check_a_moved_frame_moves_the_hit_test (a_p: SW_PAINTER; a_path: STRING)
		local
			l_plain: SW_TEXT_BOX
			l_moved: SW_SHIFTED_TEXT_BOX
			l_h, l_row, l_x4: REAL_64
			l_words: STRING_32
		do
			l_words := {STRING_32} "one two three four five six seven eight nine ten eleven twelve"
				-- a plain box wraps these words at 160; the moved one never wraps
			create l_plain.make (l_words)
			l_plain.set_bounds (0.0, 0.0, 160.0, 200.0)
			l_h := l_plain.preferred_height (a_p, 160.0)
			assert_greater_than (a_path + ": the plain box wraps", l_plain.line_count, 1)
			create l_moved.make (l_words)
			l_moved.set_bounds (0.0, 0.0, 160.0, 200.0)
			l_moved.set_shift (70.0, 40.0)
			l_h := l_moved.preferred_height (a_p, 160.0)
			assert_integers_equal (a_path + ": the moved box keeps one line", 1, l_moved.line_count)
				-- two lines, to hit the second one
			l_moved.set_text ({STRING_32} "abcdef%Nuvwxyz")
			l_h := l_moved.preferred_height (a_p, 160.0)
			assert_integers_equal (a_path + ": two lines", 2, l_moved.line_count)
			l_row := l_moved.geometry.height_of_line (0)
			l_x4 := l_moved.geometry.x_of (4)
			assert_real_greater_than (a_path + ": d stands right of the origin", l_x4, 3.0)
			assert_reals_equal (a_path + ": the origin moved right", l_moved.x + l_moved.Pad_x + 70.0, l_moved.text_left, 0.0001)
			assert_reals_equal (a_path + ": the origin moved down", l_moved.y + l_moved.Pad_y + 40.0, l_moved.text_top, 0.0001)
			assert_integers_equal (a_path + ": a click on d's left edge, first line, is before d", 3,
				l_moved.offset_at (l_moved.text_left + l_x4 + 0.5, l_moved.text_top + l_row / 2.0))
			assert_integers_equal (a_path + ": the same x on the second line is before x", 10,
				l_moved.offset_at (l_moved.text_left + l_moved.geometry.x_of (11) + 0.5,
					l_moved.text_top + l_moved.geometry.top_of_line (1) + l_row / 2.0))
				-- where the text used to start is now left of the first character
			assert_integers_equal (a_path + ": a click at the old origin is before a", 0,
				l_moved.offset_at (l_moved.x + l_moved.Pad_x + l_x4 + 0.5, l_moved.text_top + l_row / 2.0))
		end

	check_a_moved_frame_moves_the_painted_text (a_p: SW_PAINTER; a_path: STRING)
			-- The glyphs are painted from the moved origin: a band left of it
			-- looks the same with and without text, the band right of it
			-- does not.
		local
			l_empty, l_full: SW_SHIFTED_TEXT_BOX
			l_left_empty, l_left_full, l_right_empty, l_right_full: INTEGER
		do
			create l_empty.make ({STRING_32} "")
			create l_full.make ({STRING_32} "MMMMMMMM")
			l_left_empty := painted_ink (l_empty, a_p, 20, 190)
			l_right_empty := painted_ink (l_empty, a_p, 200, 380)
			l_left_full := painted_ink (l_full, a_p, 20, 190)
			l_right_full := painted_ink (l_full, a_p, 200, 380)
			assert_integers_equal (a_path + ": nothing more is painted left of the moved origin", l_left_empty, l_left_full)
			assert_greater_than (a_path + ": the text is painted right of it", l_right_full, l_right_empty + 20)
		end

	painted_ink (a_box: SW_SHIFTED_TEXT_BOX; a_p: SW_PAINTER; a_x0, a_x1: INTEGER): INTEGER
			-- Pixels that are not white between `a_x0' and `a_x1', inside the
			-- frame of `a_box' drawn 400 by 60 with its text moved 190 right.
		local
			l_surf: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
			mp: MANAGED_POINTER
			px, py: INTEGER
		do
			create l_surf.make (400, 60)
			create l_ctx.make (l_surf)
			l_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create l_p.make (l_ctx, a_p.theme)
			l_p.set_shaping (a_p.shaping)
			a_box.set_bounds (0.0, 0.0, 400.0, 60.0)
			a_box.set_shift (190.0, 8.0)
			a_box.draw (l_p)
			l_surf.flush.do_nothing
			create mp.share_from_pointer (l_surf.data, l_surf.stride * l_surf.height)
			from
				py := 4
			until
				py >= 56
			loop
				from
					px := a_x0
				until
					px >= a_x1
				loop
					if mp.read_natural_32 (py * l_surf.stride + px * 4) & 0xFFFFFF /= 0xFFFFFF then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
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
			-- The shaped path: a real kit over an offscreen painter.
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
