note
	description: "[
		A control character acts instead of drawing a missing-glyph box.

		TABS (SW_TEXT_GEOMETRY): a tab advances to the next stop, every
		eight space-widths of the face from the line's start, on both the
		toy and the shaped engine, and the box's caret, hit test and
		selection read the same slot.

		BREAKS (SW_LABEL): a line break (LF, CR LF as one) starts a new
		line: taller by a line, as wide as the widest line, the second
		line painted below the first.
	]"

class
	SW_BREAKS_AND_TABS_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tabs, toy path

	test_a_tab_reaches_the_stop_on_the_toy_path
		do
			check_a_tab_reaches_the_stop (plain_painter, "toy")
		end

	test_a_tab_reaches_the_stop_on_the_shaped_path
		do
			check_a_tab_reaches_the_stop (shaped_painter, "shaped")
		end

	test_toy_stop_is_eight_space_widths
			-- On the toy path the stop is exactly eight cairo blanks.
		local
			b: SW_TEXT_BOX
			l_h: REAL_64
		do
			create b.make ({STRING_32} "a%Tb")
			l_h := b.preferred_height (plain_painter, 300.0)
			plain_painter.font ({SW_PAINTER}.Role_body, plain_painter.theme.size_body, False)
			assert_reals_equal ("b stands at 8 space widths", 8.0 * plain_painter.advance (" "), b.geometry.x_of (3), 0.001)
			assert_reals_equal ("the stop is the geometry's tab width", b.geometry.tab_width, b.geometry.x_of (3), 0.001)
		end

	test_text_without_tabs_is_unchanged
		local
			b: SW_TEXT_BOX
			l_h: REAL_64
		do
			create b.make ({STRING_32} "ab cd")
			l_h := b.preferred_height (plain_painter, 300.0)
			plain_painter.font ({SW_PAINTER}.Role_body, plain_painter.theme.size_body, False)
			assert_reals_equal ("b follows a directly", plain_painter.advance ("a"), b.geometry.x_of (2), 0.001)
			assert_reals_equal ("d follows 'ab c'", plain_painter.advance ("ab c"), b.geometry.x_of (5), 0.001)
			assert_integers_equal ("one line", 1, b.line_count)
		end

feature {NONE} -- Tab checks

	check_a_tab_reaches_the_stop (a_p: SW_PAINTER; a_path: STRING)
		local
			b: SW_TEXT_BOX
			l_h, l_stop, l_adv_a, l_py: REAL_64
			l_ignored: BOOLEAN
			l_segs: ARRAYED_LIST [TUPLE [line: INTEGER; left, width: REAL_64]]
		do
				-- "a<TAB>b": b stands on the first stop
			create b.make ({STRING_32} "a%Tb")
			b.set_bounds (0.0, 0.0, 400.0, 100.0)
			l_h := b.preferred_height (a_p, 400.0)
			l_stop := b.geometry.tab_width
			assert_real_greater_than (a_path + ": a stop is positive", l_stop, 8.0)
			assert_reals_equal (a_path + ": b stands on the first stop", l_stop, b.geometry.x_of (3), 0.01)
			assert_integers_equal (a_path + ": still one line", 1, b.line_count)
			assert_reals_equal (a_path + ": the caret after the tab is at the stop", l_stop, b.x_at_offset (2), 0.01)
				-- a click on b's left edge puts the caret before b
			l_py := b.y + b.Pad_y + b.content_height / 2.0
			assert_integers_equal (a_path + ": a click at the stop is before b", 2,
				b.offset_at (b.x + b.Pad_x + l_stop, l_py))
			assert_integers_equal (a_path + ": a click at the right edge of the line is after b", 3,
				b.offset_at (b.x + b.Pad_x + l_stop + 500.0, l_py))
			assert_integers_equal (a_path + ": a click at the line's start is before a", 0,
				b.offset_at (b.x + b.Pad_x, l_py))
				-- the selection over the tab spans to the stop
			l_adv_a := b.geometry.x_of (2)
			assert_real_greater_than (a_path + ": a has width", l_adv_a, 1.0)
			l_segs := b.geometry.segments (1, 2)
			assert_integers_equal (a_path + ": one rectangle over the tab", 1, l_segs.count)
			assert_reals_equal (a_path + ": it starts where a ends", l_adv_a, l_segs.first.left, 0.01)
			assert_reals_equal (a_path + ": it ends at the stop", l_stop, l_segs.first.left + l_segs.first.width, 0.01)
			l_segs := b.geometry.segments (1, 3)
			assert_reals_equal (a_path + ": a selection of the tab and b starts at the tab", l_adv_a, l_segs.first.left, 0.01)
			assert_reals_equal (a_path + ": the selection through b ends past the stop", l_stop + b.geometry.width_of (3),
				l_segs.first.left + l_segs.first.width, 0.01)

				-- "abc<TAB>d": the same stop
			b.set_text ({STRING_32} "abc%Td")
			l_h := b.preferred_height (a_p, 400.0)
			if b.geometry.x_of (4) < l_stop then
				assert_reals_equal (a_path + ": d reaches the same stop", l_stop, b.geometry.x_of (5), 0.01)
			else
					-- a face whose three letters outrun eight blanks lands on the next stop
				assert_reals_equal (a_path + ": d reaches the next stop", 2.0 * l_stop, b.geometry.x_of (5), 0.01)
				b.set_text ({STRING_32} "ab%Td")
				l_h := b.preferred_height (a_p, 400.0)
				assert_reals_equal (a_path + ": ab then d reaches the same stop", l_stop, b.geometry.x_of (4), 0.01)
			end

				-- two tabs: 16 space widths
			b.set_text ({STRING_32} "a%T%Tb")
			l_h := b.preferred_height (a_p, 400.0)
			assert_reals_equal (a_path + ": two tabs reach the second stop", 2.0 * l_stop, b.geometry.x_of (4), 0.01)
			assert_reals_equal (a_path + ": the first tab ends at the first stop", l_stop, b.geometry.x_of (3), 0.01)

				-- a line past a stop goes to the next one; stops restart on each line
			b.set_text ({STRING_32} "a%Tb%Nc%Td")
			l_h := b.preferred_height (a_p, 400.0)
			assert_integers_equal (a_path + ": two lines", 2, b.line_count)
			assert_reals_equal (a_path + ": the second line measures from its own start", l_stop, b.geometry.x_of (7), 0.01)

				-- drawing takes the tabbed text without raising
			b.set_text ({STRING_32} "a%Tb")
			b.set_bounds (0.0, 0.0, 400.0, b.preferred_height (a_p, 400.0))
			b.draw (a_p)
			assert_true (a_path + ": drawn", b.is_laid_out)
			l_ignored := True
		end

feature -- Breaks

	test_a_label_break_is_two_lines_on_the_toy_path
		do
			check_label_breaks (plain_painter, "toy")
		end

	test_a_label_break_is_two_lines_on_the_shaped_path
		do
			check_label_breaks (shaped_painter, "shaped")
		end

	test_a_wrapping_label_wraps_inside_each_line
			-- Each line wraps on its own: two long lines are at least four rows.
		local
			lb, l_one: SW_LABEL
			l_long: STRING_32
		do
			l_long := {STRING_32} "the quick brown fox jumps over the lazy dog"
			create l_one.make_ui (l_long)
			l_one.set_wrap_chars (12)
			create lb.make_ui (l_long + {STRING_32} "%N" + l_long)
			lb.set_wrap_chars (12)
			assert_real_greater_than ("two wrapped lines are twice one wrapped line (toy)",
				lb.preferred_height (plain_painter, 300.0), 1.99 * l_one.preferred_height (plain_painter, 300.0) - 0.01)
			assert_reals_equal ("exactly twice (toy)", 2.0 * l_one.preferred_height (plain_painter, 300.0),
				lb.preferred_height (plain_painter, 300.0), 0.01)
		end

	test_a_hint_breaks_lines
			-- A tooltip with a break is a line taller, as wide as its widest line.
		local
			w: SW_WINDOW
			root: SW_COLUMN
			l_one_h, l_two_h, l_one_w, l_wide_w: REAL_64
		do
			create w.make ("hint", 0, 0, 400, 300, create {SW_THEME}.make_light)
			create root.make
			w.set_root (root)
			w.request_render
			l_one_h := w.hint_box_size ({STRING_32} "ab").h
			l_one_w := w.hint_box_size ({STRING_32} "ab").w
			l_two_h := w.hint_box_size ({STRING_32} "ab%Nb").h
			assert_real_greater_than ("a break makes the hint taller", l_two_h, l_one_h + 5.0)
			assert_reals_equal ("a short second line keeps the width", l_one_w, w.hint_box_size ({STRING_32} "ab%Nb").w, 0.01)
			l_wide_w := w.hint_box_size ({STRING_32} "ab%R%Nbbbbbbbbb").w
			assert_real_greater_than ("the widest line sets the width", l_wide_w, l_one_w + 5.0)
			assert_reals_equal ("CR LF is one break", l_two_h, w.hint_box_size ({STRING_32} "ab%R%Nbbbbbbbbb").h, 0.01)
		end

feature {NONE} -- Break checks

	check_label_breaks (a_p: SW_PAINTER; a_path: STRING)
		local
			l_one, l_two, l_crlf, l_wide, l_trail: SW_LABEL
			l_surf: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_top, l_bottom: INTEGER
			l_step: REAL_64
		do
			create l_one.make_ui ({STRING_32} "ab")
			create l_two.make_ui ({STRING_32} "a%Nb")
			create l_crlf.make_ui ({STRING_32} "a%R%Nb")
			create l_wide.make_ui ({STRING_32} "a%Nbbbbbbb")
			create l_trail.make_ui ({STRING_32} "a%N")
			l_step := l_one.preferred_height (a_p, 300.0)
			assert_reals_equal (a_path + ": a label without breaks is one step", l_step, l_one.line_step (a_p), 0.001)
			assert_true (a_path + ": no breaks, no break flag", not l_one.has_line_breaks)
			assert_integers_equal (a_path + ": one line", 1, l_one.text_lines.count)
			assert_true (a_path + ": a%Nb has a break", l_two.has_line_breaks)
			assert_integers_equal (a_path + ": two lines", 2, l_two.text_lines.count)
			assert_integers_equal (a_path + ": one break", 1, l_two.line_break_count)
			assert_reals_equal (a_path + ": two lines are two steps tall", 2.0 * l_step, l_two.preferred_height (a_p, 300.0), 0.5)
			assert_integers_equal (a_path + ": CR LF counts once", 2, l_crlf.text_lines.count)
			assert_reals_equal (a_path + ": and is as tall as LF alone", l_two.preferred_height (a_p, 300.0),
				l_crlf.preferred_height (a_p, 300.0), 0.001)
			assert_reals_equal (a_path + ": and as wide", l_two.preferred_width (a_p), l_crlf.preferred_width (a_p), 0.001)
			assert_integers_equal (a_path + ": a trailing break opens an empty line", 2, l_trail.text_lines.count)
				-- the width is the widest line's
			assert_reals_equal (a_path + ": as wide as the wider line", l_wide.line_width_of (a_p, {STRING_32} "bbbbbbb"),
				l_wide.preferred_width (a_p), 0.001)
			assert_real_greater_than (a_path + ": wider than the short line", l_wide.preferred_width (a_p),
				l_wide.line_width_of (a_p, {STRING_32} "a"))

				-- the second line paints below the first
			create l_surf.make (200, 200)
			create l_ctx.make (l_surf)
			create l_wide.make_ui ({STRING_32} "MMMM%NMMMM")
			l_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			l_wide.set_bounds (10.0, 10.0, 150.0, l_wide.preferred_height (a_p, 150.0))
			draw_on (l_wide, a_p, l_ctx)
			l_surf.flush.do_nothing
			l_step := l_wide.preferred_height (a_p, 150.0) / 2.0
			l_top := ink_in (l_surf, 10, 10, 160, (10.0 + l_step).floor)
			l_bottom := ink_in (l_surf, 10, (10.0 + l_step).ceiling, 160, (10.0 + 2.0 * l_step).ceiling)
			assert_greater_than (a_path + ": ink on the first line", l_top, 20)
			assert_greater_than (a_path + ": ink on the second line, below the first", l_bottom, 20)
		end

	draw_on (a_label: SW_LABEL; a_p: SW_PAINTER; a_ctx: CAIRO_CONTEXT)
			-- Draw `a_label' through a painter over `a_ctx' that shares `a_p''s
			-- theme and kit.
		local
			l_p: SW_PAINTER
		do
			create l_p.make (a_ctx, a_p.theme)
			l_p.set_shaping (a_p.shaping)
			a_label.draw (l_p)
		end

	ink_in (a_surface: CAIRO_SURFACE; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Pixels in the rectangle that are not white.
		local
			mp: MANAGED_POINTER
			x, y: INTEGER
			l_px: NATURAL_32
		do
			create mp.share_from_pointer (a_surface.data, a_surface.stride * a_surface.height)
			from
				y := a_y0.max (0)
			until
				y >= a_y1.min (a_surface.height)
			loop
				from
					x := a_x0.max (0)
				until
					x >= a_x1.min (a_surface.width)
				loop
					l_px := mp.read_natural_32 (y * a_surface.stride + x * 4) & 0xFFFFFF
					if l_px /= 0xFFFFFF then
						Result := Result + 1
					end
					x := x + 1
				end
				y := y + 1
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
