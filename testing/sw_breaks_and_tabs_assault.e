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

		DRAWING INSIDE THE CLIP (SW_TEXT_GEOMETRY.draw): a long text
		paints only what the painter's clip can show, and what it shows
		there is pixel for pixel what a draw that skips nothing shows
		(and what the whole draw shows, on every line the clip holds
		whole); a tabbed
		line stays flush left in an aligned text, wherever it stands
		among the layouts. Held to a line (`hold_draw_to_line'), a draw
		paints that line's layouts alone and shows on the line's rows
		what the clip alone shows; SW_MARK_PAINTER redraws each colored
		span that way.

		LINE QUERIES (SW_TEXT_GEOMETRY.line_start and its kin): read
		from an index of each line's slots, they answer what a scan of
		every slot answers.

		BUILDING AGAIN (SW_TEXT_GEOMETRY.last_shaped_count): a text laid
		out again after an edit has the kit lay out the edited piece
		alone and measures as a fresh build does; another size, another
		font policy or styles lay every piece out again. A long text is
		patched (`is_patched'): the edited pieces alone are placed
		again, and after any run of edits it measures as a fresh build
		does. SW_LIST_BLOCKS, which moves the lists for it, edits as a
		list made one item at a time.
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

feature -- Drawing inside the clip

	test_a_clipped_draw_matches_the_whole_draw_on_the_toy_path
		do
			check_a_clipped_draw_matches (plain_painter, "toy")
		end

	test_a_clipped_draw_matches_the_whole_draw_on_the_shaped_path
		do
			check_a_clipped_draw_matches (shaped_painter, "shaped")
		end

	test_a_held_draw_paints_its_line_alone_on_the_toy_path
		do
			check_a_held_draw_paints_its_line (plain_painter, "toy")
		end

	test_a_held_draw_paints_its_line_alone_on_the_shaped_path
		do
			check_a_held_draw_paints_its_line (shaped_painter, "shaped")
		end

	test_a_colored_mark_redraws_its_line_alone
			-- SW_MARK_PAINTER holds each redraw to its span's line: forty lines
			-- that open with a tab, a colored word on line 20 and an outlined
			-- one on line 30. Every redraw paints one layout, the hold is
			-- released after, the two lines change and no pixel of any other.
		local
			g: SW_TEXT_GEOMETRY
			l_text: STRING_32
			l_marks: SW_MARKED_TEXT
			l_mark: SW_MARK
			l_painter: SW_MARK_PAINTER
			l_plain, l_marked: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
			l_h: REAL_64
			i, l_at, l_height, l_top_20, l_bottom_20, l_top_30, l_bottom_30: INTEGER
		do
			create l_text.make (800)
			from i := 1 until i > 40 loop
				l_text.append_string_general ("%Tline " + i.out + " of forty%N")
				i := i + 1
			end
			create g.make
			l_h := g.lay_out (shaped_painter, l_text, 300.0, {SW_PAINTER}.Role_body, shaped_painter.theme.size_body, False, False, False)
			assert_true ("shaped", g.is_shaped)
			l_height := l_h.ceiling + 20
			create l_marks.make (l_text.count)
			l_at := l_text.substring_index ({STRING_32} "line 20 of forty", 1) + 11
			create l_mark.make ({SW_MARK}.Hue_red)
			if l_marks.mark_range_with (l_at - 1, l_at + 4, "colored", l_mark.colorized) > 0 then end
			l_top_20 := (5.0 + g.top_of_line (g.line_of (l_at))).floor - 1
			l_bottom_20 := (5.0 + g.top_of_line (g.line_of (l_at)) + g.height_of_line (g.line_of (l_at))).ceiling + 1
			l_at := l_text.substring_index ({STRING_32} "line 30 of forty", 1) + 11
			create l_mark.make ({SW_MARK}.Hue_blue)
			if l_marks.mark_range_with (l_at - 1, l_at + 4, "outlined", l_mark.with_outline (1)) > 0 then end
			l_top_30 := (5.0 + g.top_of_line (g.line_of (l_at))).floor - 1
			l_bottom_30 := (5.0 + g.top_of_line (g.line_of (l_at)) + g.height_of_line (g.line_of (l_at))).ceiling + 1
			l_plain := drawn_under_clip (g, l_text, shaped_painter, l_height, 0, l_height)
			create l_marked.make (320, l_height)
			create l_ctx.make (l_marked)
			l_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create l_p.make (l_ctx, shaped_painter.theme)
			l_p.set_shaping (shaped_painter.shaping)
			l_p.set_color (l_p.theme.ink)
			g.draw (l_p, l_text, False, 10.0, 5.0)
			assert_integers_equal ("the whole text paints first", g.layouts.count, g.last_drawn_count)
			redraws := 0
			redrawn_units := 0
			create l_painter.make
			l_painter.paint_over (l_p, g, l_marks, Void, 10.0, 5.0, 14.0, agent redraw_counted (g, l_text, ?, ?, ?))
			l_marked.flush.do_nothing
			assert_greater_than ("the color is one redraw, the outline several", redraws, 2)
			assert_integers_equal ("one layout a redraw", redraws, redrawn_units)
			assert_integers_equal ("the hold is released", -1, g.held_line)
			assert_greater_than ("line 20 changed color", differing_in (l_plain, l_marked, l_top_20, l_bottom_20), 5)
			assert_greater_than ("line 30 took its outline", differing_in (l_plain, l_marked, l_top_30, l_bottom_30), 5)
			assert_integers_equal ("nothing changed above line 20", 0, differing_in (l_plain, l_marked, 0, l_top_20))
			assert_integers_equal ("nor between the two", 0, differing_in (l_plain, l_marked, l_bottom_20, l_top_30))
			assert_integers_equal ("nor below line 30", 0, differing_in (l_plain, l_marked, l_bottom_30, l_height))
		end

	test_a_tabbed_line_stays_flush_left_among_many
			-- Right-aligned lines with a tabbed line after each: every tabbed line
			-- starts at the left edge, every other line leaves the left edge bare.
		local
			g: SW_TEXT_GEOMETRY
			l_text: STRING_32
			l_surf: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
			l_h: REAL_64
			i, l_tab_line, l_plain_line, l_top: INTEGER
		do
			create l_text.make (800)
			from i := 1 until i > 40 loop
				l_text.append_string_general ("xyz%NMM%TMM%N")
				i := i + 1
			end
			create g.make
			g.set_alignment ({SHAPING_CONSTANTS}.Align_right, 300.0)
			l_h := g.lay_out (shaped_painter, l_text, 300.0, {SW_PAINTER}.Role_body, shaped_painter.theme.size_body, False, False, False)
			create l_surf.make (320, l_h.ceiling + 20)
			create l_ctx.make (l_surf)
			l_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create l_p.make (l_ctx, shaped_painter.theme)
			l_p.set_shaping (shaped_painter.shaping)
			l_p.set_color (l_p.theme.ink)
			g.draw (l_p, l_text, False, 10.0, 5.0)
			l_surf.flush.do_nothing
			assert_integers_equal ("unclipped, every layout paints", g.layouts.count, g.last_drawn_count)
			across
				<<0, 19, 39>> as ic_pair
			loop
					-- pair k: "xyz" at character 10 k + 1, "MM<TAB>MM" from character 10 k + 5
				l_plain_line := g.line_of (10 * ic_pair + 1)
				l_tab_line := g.line_of (10 * ic_pair + 5)
				l_top := (5.0 + g.top_of_line (l_tab_line)).floor
				assert_greater_than ("pair " + ic_pair.out + ": the tabbed line starts at the left edge",
					ink_in (l_surf, 10, l_top, 50, l_top + g.height_of_line (l_tab_line).floor), 10)
				l_top := (5.0 + g.top_of_line (l_plain_line)).floor
				assert_integers_equal ("pair " + ic_pair.out + ": the right-aligned line leaves the left edge bare", 0,
					ink_in (l_surf, 10, l_top, 110, l_top + g.height_of_line (l_plain_line).floor))
			end
		end

feature -- Line queries

	test_the_line_queries_agree_with_a_scan_on_the_toy_path
		do
			check_the_line_queries (plain_painter, "toy")
		end

	test_the_line_queries_agree_with_a_scan_on_the_shaped_path
		do
			check_the_line_queries (shaped_painter, "shaped")
		end

feature {NONE} -- Line query checks

	check_the_line_queries (a_p: SW_PAINTER; a_path: STRING)
			-- Texts that are empty, start with a break, end with one, are breaks
			-- only, hold tabs, and wrap with empty lines and a right-to-left word:
			-- every line's start, end and right edge, the offset under points along
			-- it, the line under heights down the text and the character under
			-- points, each against a scan of every slot (how the geometry answered
			-- before it kept an index of its lines).
		local
			g: SW_TEXT_GEOMETRY
			l_texts: ARRAYED_LIST [STRING_32]
			l_mixed: STRING_32
			l_h, x, y, l_reach: REAL_64
			l_line, n, i, l_bad_start, l_bad_end, l_bad_offset, l_bad_right, l_bad_line, l_bad_character: INTEGER
			l_tag: STRING
		do
			create l_mixed.make (600)
			from i := 1 until i > 12 loop
				l_mixed.append_string_general ("several words that wrap at the width given, line " + i.out + " ")
				l_mixed.append_string_general ({STRING_32} "%/1513/%/1500/%/1493/%/1501/ after it%N")
				if i \\ 3 = 0 then
					l_mixed.append_string_general ("%N%Tone stop%T%Ttwo more%N")
				end
				i := i + 1
			end
			create l_texts.make (6)
			l_texts.extend ({STRING_32} "")
			l_texts.extend ({STRING_32} "%Nstarts with a break")
			l_texts.extend ({STRING_32} "ends with a break%N")
			l_texts.extend ({STRING_32} "%N%N%N")
			l_texts.extend (code_like_text (40))
			l_texts.extend (l_mixed)
			across
				l_texts as ic_text
			loop
				n := n + 1
				l_tag := a_path + ", text " + n.out + ": "
				l_bad_start := 0
				l_bad_end := 0
				l_bad_offset := 0
				l_bad_right := 0
				l_bad_line := 0
				l_bad_character := 0
				l_reach := 0.0
				create g.make
				l_h := g.lay_out (a_p, ic_text, 220.0, {SW_PAINTER}.Role_body, a_p.theme.size_body, False, False, False)
				from l_line := 0 until l_line >= g.line_count loop
					if g.line_start (l_line) /= scanned_line_start (g, l_line) then
						l_bad_start := l_bad_start + 1
					end
					if g.line_end (l_line) /= scanned_line_end (g, l_line) then
						l_bad_end := l_bad_end + 1
					end
					if g.right_of_line (l_line) /= scanned_right_of_line (g, l_line) then
						l_bad_right := l_bad_right + 1
					end
					l_reach := l_reach.max (scanned_right_of_line (g, l_line))
					from x := -10.0 until x > 260.0 loop
						if g.offset_on_line (l_line, x) /= scanned_offset_on_line (g, l_line, x) then
							l_bad_offset := l_bad_offset + 1
						end
						x := x + 7.0
					end
					l_line := l_line + 1
				end
				from y := -5.0 until y > l_h + 20.0 loop
					if g.line_at_y (y) /= scanned_line_at_y (g, y) then
						l_bad_line := l_bad_line + 1
					end
					from x := -3.0 until x > 240.0 loop
						if g.character_at (x, y) /= scanned_character_at (g, x, y) then
							l_bad_character := l_bad_character + 1
						end
						x := x + 9.0
					end
					y := y + 3.0
				end
				assert_integers_equal (l_tag + "lines whose start differs from the scan's", 0, l_bad_start)
				assert_integers_equal (l_tag + "lines whose end differs from the scan's", 0, l_bad_end)
				assert_integers_equal (l_tag + "lines whose right edge differs from the scan's", 0, l_bad_right)
				assert_integers_equal (l_tag + "points whose offset differs from the scan's", 0, l_bad_offset)
				assert_integers_equal (l_tag + "heights whose line differs from the scan's", 0, l_bad_line)
				assert_integers_equal (l_tag + "points whose character differs from the scan's", 0, l_bad_character)
				assert_true (l_tag + "the rightmost edge is the widest line's", g.rightmost_edge = l_reach)
				if n = 6 then
					assert_greater_than (l_tag + "it wrapped", g.line_count, 30)
				end
			end
		end

	scanned_line_start (a_g: SW_TEXT_GEOMETRY; a_line: INTEGER): INTEGER
			-- SW_TEXT_GEOMETRY.line_start by a walk over every slot.
		local
			i: INTEGER
			l_found: BOOLEAN
		do
			from i := 1 until i > a_g.count or l_found loop
				if a_g.line_of (i) = a_line then
					if a_g.is_break (i) then
						Result := i
					else
						Result := i - 1
						l_found := True
					end
				end
				i := i + 1
			end
		end

	scanned_line_end (a_g: SW_TEXT_GEOMETRY; a_line: INTEGER): INTEGER
			-- SW_TEXT_GEOMETRY.line_end by a walk over every slot.
		local
			i: INTEGER
		do
			Result := scanned_line_start (a_g, a_line)
			from i := 1 until i > a_g.count loop
				if a_g.line_of (i) = a_line and then not a_g.is_break (i) then
					Result := i
				end
				i := i + 1
			end
		end

	scanned_right_of_line (a_g: SW_TEXT_GEOMETRY; a_line: INTEGER): REAL_64
			-- SW_TEXT_GEOMETRY.right_of_line by a walk over every slot.
		local
			i: INTEGER
		do
			from i := 1 until i > a_g.count loop
				if a_g.line_of (i) = a_line and then not a_g.is_break (i) then
					Result := Result.max (a_g.x_of (i) + a_g.width_of (i))
				end
				i := i + 1
			end
		end

	scanned_offset_on_line (a_g: SW_TEXT_GEOMETRY; a_line: INTEGER; a_px: REAL_64): INTEGER
			-- SW_TEXT_GEOMETRY.offset_on_line by a walk over every slot.
		local
			i: INTEGER
			l_best, l_d, l_before, l_after: REAL_64
			l_first, l_best_rtl, l_rtl: BOOLEAN
		do
			Result := scanned_line_start (a_g, a_line)
			l_first := True
			from i := 1 until i > a_g.count loop
				if a_g.line_of (i) = a_line then
					l_rtl := a_g.is_rtl (i)
					if l_rtl then
						l_before := a_g.x_of (i) + a_g.width_of (i)
						l_after := a_g.x_of (i)
					else
						l_before := a_g.x_of (i)
						l_after := a_g.x_of (i) + a_g.width_of (i)
					end
					if not a_g.is_break (i) then
						l_d := (a_px - l_before).abs
						if l_first or else l_d < l_best or else (l_d = l_best and l_best_rtl and not l_rtl) then
							l_best := l_d
							l_best_rtl := l_rtl
							Result := i - 1
							l_first := False
						end
					end
					l_d := (a_px - l_after).abs
					if l_first or else l_d < l_best or else (l_d = l_best and (l_best_rtl or not l_rtl)) then
						l_best := l_d
						l_best_rtl := l_rtl
						Result := i
						l_first := False
					end
				end
				i := i + 1
			end
		end

	scanned_line_at_y (a_g: SW_TEXT_GEOMETRY; a_dy: REAL_64): INTEGER
			-- SW_TEXT_GEOMETRY.line_at_y by a walk down the lines.
		local
			i: INTEGER
		do
			from i := 0 until i >= a_g.line_count or else a_g.top_of_line (i) > a_dy loop
				Result := i
				i := i + 1
			end
		end

	scanned_character_at (a_g: SW_TEXT_GEOMETRY; a_dx, a_dy: REAL_64): INTEGER
			-- SW_TEXT_GEOMETRY.character_at by a walk over every slot.
		local
			i, l_line: INTEGER
		do
			if a_g.count > 0 and then a_dy >= 0.0 and then a_dy < a_g.content_height then
				l_line := scanned_line_at_y (a_g, a_dy)
				from i := 1 until i > a_g.count or Result > 0 loop
					if a_g.line_of (i) = l_line and then not a_g.is_break (i) and then a_g.width_of (i) > 0.0
						and then a_dx >= a_g.x_of (i) and then a_dx < a_g.x_of (i) + a_g.width_of (i)
					then
						Result := i
					end
					i := i + 1
				end
			end
		end

feature -- Building again

	test_a_rebuild_lays_out_only_what_changed
		local
			g, l_fresh: SW_TEXT_GEOMETRY
			l_text, l_edited: STRING_32
			l_p: SW_PAINTER
			l_h: REAL_64
		do
			l_p := shaped_painter
			l_text := code_like_text (300)
			create g.make
			l_h := g.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_greater_than ("the first build lays pieces out", g.last_shaped_count, 100)
			assert_less_than ("equal pieces are laid out once", g.last_shaped_count, g.layouts.count)
			l_h := g.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_integers_equal ("the same text again lays nothing out", 0, g.last_shaped_count)
				-- one character typed into a tabbed line, then into a plain one
			l_edited := l_text.twin
			l_edited.insert_character ('x', l_text.substring_index ({STRING_32} "item 151", 1))
			l_h := g.lay_out (l_p, l_edited, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_integers_equal ("an edit to a tabbed line lays out the edited segment", 1, g.last_shaped_count)
			create l_fresh.make
			l_h := l_fresh.lay_out (l_p, l_edited, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_integers_equal ("after it, measured as a fresh build", 0, differing_slots (g, l_fresh))
			l_edited.insert_character ('y', l_edited.substring_index ({STRING_32} "plain row 150", 1))
			l_h := g.lay_out (l_p, l_edited, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_integers_equal ("an edit to a plain line lays out that line", 1, g.last_shaped_count)
			create l_fresh.make
			l_h := l_fresh.lay_out (l_p, l_edited, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_integers_equal ("after it, measured as a fresh build", 0, differing_slots (g, l_fresh))
				-- a line taken out
			l_edited.remove_substring (1, l_edited.index_of ('%N', 1))
			l_h := g.lay_out (l_p, l_edited, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_integers_equal ("a line taken out lays nothing out", 0, g.last_shaped_count)
			create l_fresh.make
			l_h := l_fresh.lay_out (l_p, l_edited, 300.0, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_integers_equal ("after it, measured as a fresh build", 0, differing_slots (g, l_fresh))
		end

	test_a_rebuild_trusts_nothing_made_under_other_terms
			-- Another size, a kit that forgot its layouts (its fonts changed), another
			-- wrap width and styles: what was kept under the old terms is not used.
		local
			g, l_fresh: SW_TEXT_GEOMETRY
			l_text: STRING_32
			l_p: SW_PAINTER
			l_styles: SHAPING_STYLES
			l_h, l_size: REAL_64
			l_all: INTEGER
		do
			l_p := shaped_painter
			l_text := code_like_text (120)
			l_size := l_p.theme.size_body
			create g.make
			l_h := g.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_mono, l_size, False, False, False)
			l_all := g.last_shaped_count
				-- another size
			l_h := g.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_mono, l_size + 4.0, False, False, False)
			assert_integers_equal ("another size lays every piece out again", l_all, g.last_shaped_count)
			create l_fresh.make
			l_h := l_fresh.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_mono, l_size + 4.0, False, False, False)
			assert_integers_equal ("another size, measured as a fresh build", 0, differing_slots (g, l_fresh))
				-- another face
			l_h := g.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_integers_equal ("another face lays every piece out again", l_all, g.last_shaped_count)
			create l_fresh.make
			l_h := l_fresh.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_integers_equal ("another face, measured as a fresh build", 0, differing_slots (g, l_fresh))
				-- the kit forgot (what every font setter of it does)
			if attached l_p.shaping as al_kit then
				al_kit.forget_layouts
			end
			l_h := g.lay_out (l_p, l_text, 300.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_integers_equal ("after the kit forgot, every piece is laid out again", l_all, g.last_shaped_count)
				-- another wrap width: the unwrapped segments of tabbed lines stand
			l_h := g.lay_out (l_p, l_text, 500.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_greater_than ("another width lays the wrapped pieces out again", g.last_shaped_count, 30)
			assert_less_than ("another width keeps the unwrapped segments", g.last_shaped_count, l_all)
			create l_fresh.make
			l_h := l_fresh.lay_out (l_p, l_text, 500.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_integers_equal ("another width, measured as a fresh build", 0, differing_slots (g, l_fresh))
				-- styles: every piece goes to the kit, equal ones too
			create l_styles.make
			l_styles.add_bold (3, 40)
			g.set_styles (l_styles)
			l_h := g.lay_out (l_p, l_text, 500.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_integers_equal ("under styles every piece is laid out", g.layouts.count, g.last_shaped_count)
			create l_fresh.make
			l_fresh.set_styles (l_styles)
			l_h := l_fresh.lay_out (l_p, l_text, 500.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_integers_equal ("under styles, measured as a fresh build", 0, differing_slots (g, l_fresh))
				-- and plain again after them
			g.set_styles (Void)
			l_h := g.lay_out (l_p, l_text, 500.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			create l_fresh.make
			l_h := l_fresh.lay_out (l_p, l_text, 500.0, {SW_PAINTER}.Role_body, l_size + 4.0, False, False, False)
			assert_integers_equal ("plain again, measured as a fresh build", 0, differing_slots (g, l_fresh))
		end

	test_a_long_text_is_laid_out_again_quickly
			-- 10,000 lines of code-like text: an edit to one line is laid out again
			-- within a budget a typist does not notice. Timed inside
			-- `without_contracts' (the budget is the shipped program's).
		local
			g: SW_TEXT_GEOMETRY
			l_text: STRING_32
			l_p: SW_PAINTER
			l_first, l_again, l_worst: REAL_64
			i: INTEGER
		do
			l_p := shaped_painter
			l_text := code_like_text (10_000)
			create g.make
			without_contracts (agent time_it (agent lay_code_out (g, l_p, l_text)))
			l_first := last_ms
			from i := 1 until i > 5 loop
				l_text.insert_character ('z', l_text.substring_index ({STRING_32} "item 5000", 1))
				without_contracts (agent time_it (agent lay_code_out (g, l_p, l_text)))
				l_again := l_again + last_ms
				l_worst := l_worst.max (last_ms)
				assert_integers_equal ("edit " + i.out + " lays out the edited segment", 1, g.last_shaped_count)
				assert_true ("edit " + i.out + " is patched in", g.is_patched)
				i := i + 1
			end
			print ("    long text: " + l_text.count.out + " characters, " + g.layouts.count.out + " layouts; first build "
				+ l_first.rounded.out + " ms, after an edit " + (l_again / 5.0).rounded.out + " ms mean, "
				+ l_worst.rounded.out + " ms worst%N")
			assert_true ("an edit to a 10,000-line text is laid out again within " + Rebuild_budget_ms.out
				+ " milliseconds: " + l_worst.out, l_worst < Rebuild_budget_ms)
		end

	test_list_blocks_edit_as_a_model_does
			-- SW_LIST_BLOCKS against a list made one item at a time: at the start, in
			-- the middle and at the end, growing, shrinking and of no length; and the
			-- list goes on working as a list after it.
		local
			l_blocks: SW_LIST_BLOCKS [INTEGER]
			l_names: SW_LIST_BLOCKS [STRING]
			l_list, l_model: ARRAYED_LIST [INTEGER]
			l_words: ARRAYED_LIST [STRING]
			l_count, l_after, l_removed, l_more, l_cases, l_wrong: INTEGER
		do
			create l_blocks
			from l_count := 0 until l_count > 9 loop
				from l_after := 0 until l_after > l_count loop
					from l_removed := 0 until l_after + l_removed > l_count loop
						from l_more := 0 until l_more > 40 loop
								-- 0, 1, 4, 13 and 40 put in: the last two outgrow the list
							l_list := counted_list (l_count)
							l_model := spliced_model (l_list, l_after, l_removed, l_more, -7)
							l_blocks.splice (l_list, l_after, l_removed, l_more, -7)
							l_list.extend (99)
							l_model.extend (99)
							if not same_items (l_list, l_model) then
								l_wrong := l_wrong + 1
							end
							l_cases := l_cases + 1
							l_more := l_more * 3 + 1
						end
						from l_more := 0 until l_after + l_removed + l_more > l_count loop
							l_list := counted_list (l_count)
							l_model := moved_model (l_list, l_after, l_removed, l_more)
							l_blocks.move_end_in (l_list, l_after, l_removed, l_more)
							l_list.extend (99)
							l_model.extend (99)
							if not same_items (l_list, l_model) then
								l_wrong := l_wrong + 1
							end
							l_cases := l_cases + 1
							l_more := l_more + 1
						end
						l_removed := l_removed + 1
					end
					l_after := l_after + 1
				end
				l_count := l_count + 1
			end
			assert_greater_than ("many cases tried", l_cases, 1000)
			assert_integers_equal ("every block edit leaves what the model has", 0, l_wrong)
				-- items that are objects
			create l_names
			create l_words.make_from_array (<<"one", "two", "three", "four", "five">>)
			l_names.move_end_in (l_words, 1, 2, 2)
			assert_integers_equal ("two of five gave way to the last two", 3, l_words.count)
			assert_true ("the list reads one, four, five", l_words.i_th (1).same_string ("one")
				and l_words.i_th (2).same_string ("four") and l_words.i_th (3).same_string ("five"))
		end

	test_a_patched_build_equals_a_whole_one
			-- Edit after edit to a text of tabbed and plain lines - characters, tabs
			-- and line breaks put in, taken out and written over, at the start, in
			-- the middle and at the end - wrapped and not: after each the geometry
			-- measures as one built from nothing, and most were patched in.
		do
			check_patched_builds (100_000.0, 300)
			check_patched_builds (220.0, 300)
		end

	test_a_build_is_patched_only_under_the_same_terms
			-- Another wrap width, other tab stops, an aligned text, styles, a single
			-- line, a short text and a text mostly rewritten are built whole, and so
			-- is the build after an aligned or styled one.
		local
			g: SW_TEXT_GEOMETRY
			l_text, l_short, l_other: STRING_32
			l_p: SW_PAINTER
			l_styles: SHAPING_STYLES
		do
			l_p := shaped_painter
			l_text := code_like_text (150)
			create g.make
			lay_and_compare (g, l_p, l_text, 400.0, False, "the first build")
			assert_false ("the first build is whole", g.is_patched)
			l_text.insert_character ('a', 700)
			lay_and_compare (g, l_p, l_text, 400.0, False, "an edit")
			assert_true ("an edit is patched in", g.is_patched)
			lay_and_compare (g, l_p, l_text, 400.0, False, "the same text")
			assert_true ("the same text again stands as it is", g.is_patched)
				-- another wrap width
			l_text.insert_character ('b', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "another wrap width")
			assert_false ("another wrap width builds whole", g.is_patched)
			l_text.insert_character ('c', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "an edit at the new width")
			assert_true ("the edit after it is patched in", g.is_patched)
				-- other tab stops
			g.set_tab_spaces (4)
			l_text.insert_character ('d', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "other tab stops")
			assert_false ("other tab stops build whole", g.is_patched)
				-- aligned, and flush left again
			g.set_alignment ({SHAPING_CONSTANTS}.Align_center, 350.0)
			l_text.insert_character ('e', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "centered")
			assert_false ("a centered text builds whole", g.is_patched)
			l_text.insert_character ('f', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "centered, edited")
			assert_false ("and so does an edit to it", g.is_patched)
			g.set_alignment ({SHAPING_CONSTANTS}.Align_left, 350.0)
			l_text.insert_character ('g', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "flush left again")
			assert_false ("the build after a centered one is whole", g.is_patched)
			l_text.insert_character ('h', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "flush left, edited")
			assert_true ("the edit after that is patched in", g.is_patched)
				-- styles, and plain again
			create l_styles.make
			l_styles.add_bold (3, 40)
			g.set_styles (l_styles)
			l_text.insert_character ('i', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "under styles")
			assert_false ("a styled text builds whole", g.is_patched)
			g.set_styles (Void)
			l_text.insert_character ('j', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "plain again")
			assert_false ("the build after a styled one is whole", g.is_patched)
			l_text.insert_character ('k', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "plain, edited")
			assert_true ("the edit after that is patched in", g.is_patched)
				-- a single line, and many lines again
			l_text.insert_character ('l', 700)
			lay_and_compare (g, l_p, l_text, 350.0, True, "as a single line")
			assert_false ("a single line builds whole", g.is_patched)
			l_text.insert_character ('m', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "many lines again")
			assert_false ("the build after a single line is whole", g.is_patched)
			l_text.insert_character ('n', 700)
			lay_and_compare (g, l_p, l_text, 350.0, False, "many lines, edited")
			assert_true ("the edit after that is patched in", g.is_patched)
				-- most of the text written over (in other words from its first
				-- character on: `code_like_text' as it is would write back the
				-- lines it took out, and those are patched in)
			l_other := code_like_text (90)
			l_other.replace_substring_all ({STRING_32} "item", {STRING_32} "ITEM")
			l_other.replace_substring_all ({STRING_32} "plain", {STRING_32} "PLAIN")
			l_other.prepend_character ('Z')
			l_text.replace_substring (l_other, 1, l_text.count * 2 // 3)
			lay_and_compare (g, l_p, l_text, 350.0, False, "mostly rewritten")
			assert_false ("a text mostly rewritten builds whole", g.is_patched)
			l_text.replace_substring (code_like_text (40), 1, l_text.count // 4)
			lay_and_compare (g, l_p, l_text, 350.0, False, "a quarter rewritten")
			assert_true ("a text a quarter rewritten is patched in", g.is_patched)
				-- a short text
			l_short := code_like_text (20)
			lay_and_compare (g, l_p, l_short, 350.0, False, "a short text")
			l_short.insert_character ('o', 100)
			lay_and_compare (g, l_p, l_short, 350.0, False, "a short text, edited")
			assert_false ("a short text builds whole", g.is_patched)
		end

feature {NONE} -- Building again: checks

	Rebuild_budget_ms: REAL_64 = 400.0
			-- What laying a 10,000-line text out again after an edit may take.

	last_ms: REAL_64
			-- What the last `time_it' took.

	time_it (a_work: PROCEDURE)
		local
			l_clock: SIMPLE_MONOTONIC_CLOCK
			l_t0: INTEGER_64
		do
			create l_clock
			l_t0 := l_clock.nanoseconds
			a_work.call (Void)
			last_ms := l_clock.elapsed_nanoseconds (l_t0) / 1.0e6
		end

	lay_code_out (a_g: SW_TEXT_GEOMETRY; a_p: SW_PAINTER; a_text: STRING_32)
			-- `a_text' unwrapped in the fixed-pitch face, as a code editor has it.
		local
			l_h: REAL_64
		do
			l_h := a_g.lay_out (a_p, a_text, 100_000.0, {SW_PAINTER}.Role_mono, a_p.theme.size_body, False, False, False)
		end

	code_like_text (a_lines: INTEGER): STRING_32
			-- `a_lines' lines: two tabbed ones (two tabs, "item <n>", a tab, "end") and
			-- a plain one ("plain row <n>") by turns, each ended by a line break.
		require
			some_lines: a_lines >= 1
		local
			i: INTEGER
		do
			create Result.make (a_lines * 20)
			from i := 1 until i > a_lines loop
				if i \\ 3 = 0 then
					Result.append_string_general ("plain row " + i.out)
				else
					Result.append_string_general ("%T%Titem " + i.out + "%Tend")
				end
				Result.append_character ('%N')
				i := i + 1
			end
		end

	differing_slots (a_one, a_other: SW_TEXT_GEOMETRY): INTEGER
			-- How many characters, lines and layouts the two place differently
			-- (a different count of any of them counts once).
		local
			i: INTEGER
		do
			if a_one.count /= a_other.count or a_one.line_count /= a_other.line_count
				or a_one.layouts.count /= a_other.layouts.count
			then
				Result := 1
			else
				from i := 1 until i > a_one.count loop
					if a_one.x_of (i) /= a_other.x_of (i) or a_one.width_of (i) /= a_other.width_of (i)
						or a_one.line_of (i) /= a_other.line_of (i) or a_one.is_break (i) /= a_other.is_break (i)
					then
						Result := Result + 1
					end
					i := i + 1
				end
				from i := 0 until i >= a_one.line_count loop
					if a_one.top_of_line (i) /= a_other.top_of_line (i) or a_one.height_of_line (i) /= a_other.height_of_line (i)
						or a_one.ascent_of_line (i) /= a_other.ascent_of_line (i)
						or a_one.line_start (i) /= a_other.line_start (i) or a_one.line_end (i) /= a_other.line_end (i)
						or a_one.right_of_line (i) /= a_other.right_of_line (i)
					then
						Result := Result + 1
					end
					i := i + 1
				end
				from i := 1 until i > a_one.layouts.count loop
					if (a_one.para_tops.i_th (i) - a_other.para_tops.i_th (i)).abs > Top_slack
						or a_one.para_lefts.i_th (i) /= a_other.para_lefts.i_th (i)
						or a_one.layouts.i_th (i).total_width /= a_other.layouts.i_th (i).total_width
					then
						Result := Result + 1
					end
					i := i + 1
				end
				if a_one.rightmost_edge /= a_other.rightmost_edge or a_one.tallest_line /= a_other.tallest_line
					or a_one.content_height /= a_other.content_height
				then
					Result := Result + 1
				end
			end
		end

feature {NONE} -- Patched builds: checks

	Top_slack: REAL_64 = 1.0e-6
			-- How far a layout's top may stand from a fresh build's after a patch
			-- (SW_TEXT_GEOMETRY: COST OF A BUILD).

	check_patched_builds (a_wrap: REAL_64; a_edits: INTEGER)
			-- `a_edits' edits from a fixed sequence, each laid out at `a_wrap' and
			-- compared with a geometry built from nothing.
		local
			g, l_fresh: SW_TEXT_GEOMETRY
			l_text: STRING_32
			l_p: SW_PAINTER
			l_h: REAL_64
			i, l_patched, l_wrong, l_first_wrong: INTEGER
		do
			l_p := shaped_painter
			l_text := code_like_text (150)
			random_state := 20261110
			create g.make
			l_h := g.lay_out (l_p, l_text, a_wrap, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
			assert_false ("the first build is whole", g.is_patched)
			from i := 1 until i > a_edits loop
				edit_at_random (l_text)
				l_h := g.lay_out (l_p, l_text, a_wrap, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
				if g.is_patched then
					l_patched := l_patched + 1
				end
				create l_fresh.make
				l_h := l_fresh.lay_out (l_p, l_text, a_wrap, {SW_PAINTER}.Role_mono, l_p.theme.size_body, False, False, False)
				if differing_slots (g, l_fresh) > 0 or else (i \\ 10 = 0 and then differing_runs (g, l_fresh, l_p) > 0) then
					l_wrong := l_wrong + 1
					if l_first_wrong = 0 then
						l_first_wrong := i
					end
				end
				i := i + 1
			end
			assert_integers_equal ("at wrap " + a_wrap.rounded.out + ", every build after an edit measures as a fresh one"
				+ " (the first that does not: edit " + l_first_wrong.out + ")", 0, l_wrong)
			assert_greater_than ("at wrap " + a_wrap.rounded.out + ", most edits were patched in", l_patched, a_edits * 3 // 4)
		end

	lay_and_compare (g: SW_TEXT_GEOMETRY; a_p: SW_PAINTER; a_text: STRING_32; a_wrap: REAL_64; a_single_line: BOOLEAN;
			a_what: STRING)
			-- Lay `a_text' out in `g', and hold it against a geometry built from
			-- nothing under g's tab stops, alignment and styles.
		local
			l_fresh: SW_TEXT_GEOMETRY
			l_h: REAL_64
		do
			l_h := g.lay_out (a_p, a_text, a_wrap, {SW_PAINTER}.Role_mono, a_p.theme.size_body, False, a_single_line, False)
			create l_fresh.make
			l_fresh.set_tab_spaces (g.tab_spaces)
			l_fresh.set_alignment (g.alignment, g.box_width)
			l_fresh.set_styles (g.styles)
			l_h := l_fresh.lay_out (a_p, a_text, a_wrap, {SW_PAINTER}.Role_mono, a_p.theme.size_body, False, a_single_line, False)
			assert_integers_equal (a_what + ": measured as a fresh build", 0, differing_slots (g, l_fresh))
		end

	random_state: INTEGER_64
			-- Where the fixed sequence of `random' stands.

	random (a_below: INTEGER): INTEGER
			-- The next number of a fixed sequence, 0 .. `a_below' - 1.
		require
			a_range: a_below >= 1
		do
			random_state := (random_state * 1103515245 + 12345) \\ {INTEGER_64} 2147483648
			Result := ((random_state // 65536) \\ a_below).to_integer_32
		ensure
			in_range: Result >= 0 and Result < a_below
		end

	edit_at_random (a_text: STRING_32)
			-- One edit to `a_text' from the fixed sequence: something put in, taken
			-- out or written over, anywhere, with the start and the end taking their
			-- turns. (A text grown short is given lines at its end.)
		local
			l_pool: ARRAY [STRING_32]
			l_piece: STRING_32
			l_at, l_span, l_kind: INTEGER
		do
			l_pool := <<{STRING_32} "x", {STRING_32} " ", {STRING_32} "%T", {STRING_32} "%N", {STRING_32} "%N%N",
				{STRING_32} "words and more words to wrap the line with", {STRING_32} "%/1488/%/1489/",
				{STRING_32} "%T%N", {STRING_32} "end%Nplain row">>
			l_piece := l_pool.item (1 + random (l_pool.count))
			l_kind := random (12)
			l_at := 1 + random (a_text.count)
			l_span := (1 + random (60)).min (a_text.count - l_at + 1)
			if a_text.count < 1500 then
				a_text.append (code_like_text (25))
			elseif l_kind <= 3 then
				a_text.insert_string (l_piece, l_at)
			elseif l_kind = 4 then
				a_text.insert_string (l_piece, 1)
			elseif l_kind = 5 then
				a_text.append (l_piece)
			elseif l_kind = 6 then
				a_text.remove_head (1 + random (3))
			elseif l_kind = 7 then
				a_text.remove_tail (1 + random (3))
			elseif l_kind = 8 then
				a_text.remove (l_at)
			elseif l_kind = 9 then
				a_text.remove_substring (l_at, l_at + l_span - 1)
			elseif l_kind = 10 then
				a_text.replace_substring (l_piece, l_at, l_at + l_span - 1)
			else
				a_text.put ('%N', l_at)
			end
		end

	differing_runs (a_one, a_other: SW_TEXT_GEOMETRY; a_p: SW_PAINTER): INTEGER
			-- How many runs the two hand a hook differently - its first character in
			-- the whole text, its pen, its baseline - drawn band by band over their
			-- height (a different count of runs counts once).
		local
			l_one, l_other: ARRAYED_LIST [REAL_64]
			l_y: REAL_64
			i: INTEGER
		do
			create l_one.make (256)
			create l_other.make (256)
			from l_y := 0.0 until l_y > a_one.content_height loop
				a_one.draw_hooked (a_p, 0.0, - l_y, agent note_run (l_one, ?, ?, ?, ?))
				a_other.draw_hooked (a_p, 0.0, - l_y, agent note_run (l_other, ?, ?, ?, ?))
				l_y := l_y + 200.0
			end
			if l_one.count /= l_other.count then
				Result := 1
			else
				from i := 1 until i > l_one.count loop
					if (l_one.i_th (i) - l_other.i_th (i)).abs > Top_slack then
						Result := Result + 1
					end
					i := i + 1
				end
			end
		end

	note_run (a_into: ARRAYED_LIST [REAL_64]; a_start: INTEGER; a_run: SHAPED_RUN; a_pen, a_baseline: REAL_64)
		do
			a_into.extend (a_start)
			a_into.extend (a_pen)
			a_into.extend (a_baseline)
		end

	counted_list (a_count: INTEGER): ARRAYED_LIST [INTEGER]
			-- 1, 2 .. `a_count'.
		local
			i: INTEGER
		do
			create Result.make (a_count)
			from i := 1 until i > a_count loop
				Result.extend (i)
				i := i + 1
			end
		end

	spliced_model (a_list: ARRAYED_LIST [INTEGER]; a_after, a_removed, a_inserted, a_fill: INTEGER): ARRAYED_LIST [INTEGER]
			-- What SW_LIST_BLOCKS.splice is to leave, made one item at a time.
		local
			i: INTEGER
		do
			create Result.make (0)
			from i := 1 until i > a_after loop
				Result.extend (a_list.i_th (i))
				i := i + 1
			end
			from i := 1 until i > a_inserted loop
				Result.extend (a_fill)
				i := i + 1
			end
			from i := a_after + a_removed + 1 until i > a_list.count loop
				Result.extend (a_list.i_th (i))
				i := i + 1
			end
		end

	moved_model (a_list: ARRAYED_LIST [INTEGER]; a_after, a_removed, a_count: INTEGER): ARRAYED_LIST [INTEGER]
			-- What SW_LIST_BLOCKS.move_end_in is to leave, made one item at a time.
		local
			i: INTEGER
		do
			create Result.make (0)
			from i := 1 until i > a_after loop
				Result.extend (a_list.i_th (i))
				i := i + 1
			end
			from i := a_list.count - a_count + 1 until i > a_list.count loop
				Result.extend (a_list.i_th (i))
				i := i + 1
			end
			from i := a_after + a_removed + 1 until i > a_list.count - a_count loop
				Result.extend (a_list.i_th (i))
				i := i + 1
			end
		end

	same_items (a_one, a_other: ARRAYED_LIST [INTEGER]): BOOLEAN
			-- Do the two hold the same numbers in the same order?
		local
			i: INTEGER
		do
			Result := a_one.count = a_other.count
			from i := 1 until not Result or else i > a_one.count loop
				Result := a_one.i_th (i) = a_other.i_th (i)
				i := i + 1
			end
		end

feature {NONE} -- Clip checks

	check_a_clipped_draw_matches (a_p: SW_PAINTER; a_path: STRING)
			-- Sixty paragraphs (tabbed, wrapping, empty, plain) drawn whole, then
			-- again under a clip over a band of rows. Inside the band the clipped
			-- draw agrees pixel for pixel with a draw under the same band that
			-- skips nothing, and with the whole draw on the rows of the lines the
			-- band holds whole; and it painted a fraction of the text.
			--
			-- The whole draw is not compared on a line the band's edge cuts: there
			-- the two differ by what the cut does to a glyph, which is cairo's
			-- matter, not the draw's. On macOS (cairo 1.18, the Quartz font
			-- backend) a character drawn alone at a fractional x, as the toy path
			-- draws each one, loses its leftmost column inside a clip that cuts it.
		local
			g: SW_TEXT_GEOMETRY
			l_text: STRING_32
			l_whole, l_part, l_unskipped: CAIRO_SURFACE
			l_h: REAL_64
			l_height, l_whole_count, l_part_count, l_unit_count, l_line: INTEGER
			l_bands: ARRAY [TUPLE [top, bottom: INTEGER]]
			l_rows: TUPLE [top, bottom: INTEGER]
			l_name: STRING
		do
			l_text := sixty_paragraphs
			create g.make
			l_h := g.lay_out (a_p, l_text, 300.0, {SW_PAINTER}.Role_body, a_p.theme.size_body, False, False, False)
			l_height := l_h.ceiling + 20
			l_whole := drawn_under_clip (g, l_text, a_p, l_height, 0, l_height)
			l_whole_count := g.last_drawn_count
			if g.is_shaped then
				l_unit_count := g.layouts.count
				assert_integers_equal (a_path + ": unclipped, every layout paints", l_unit_count, l_whole_count)
			else
				l_unit_count := g.count
			end
			assert_greater_than (a_path + ": the whole draw left ink", ink_in (l_whole, 0, 0, 320, l_height), 2000)
				-- a line in the middle that holds text
			l_line := g.line_of (l_text.substring_index ({STRING_32} "plain line 31", 1))
			l_bands := <<[0, 40],
				[(5.0 + g.top_of_line (l_line)).floor, (5.0 + g.top_of_line (l_line) + g.height_of_line (l_line)).ceiling],
				[l_height // 3, l_height // 3 + 200],
				[l_height - 70, l_height]>>
			across
				l_bands as ic_band
			loop
				l_name := a_path + ": rows " + ic_band.top.out + " to " + ic_band.bottom.out
				l_part := drawn_under_clip (g, l_text, a_p, l_height, ic_band.top, ic_band.bottom)
				l_part_count := g.last_drawn_count
				l_unskipped := drawn_unskipped (g, l_text, a_p, l_height, ic_band.top, ic_band.bottom)
				assert_integers_equal (l_name + ": the draw to compare with skips nothing", l_whole_count, g.last_drawn_count)
				assert_integers_equal (l_name + " show what a draw that skips nothing shows", 0,
					differing_in (l_unskipped, l_part, ic_band.top, ic_band.bottom))
				l_rows := rows_of_whole_lines (g, ic_band.top, ic_band.bottom)
				assert_greater_than (l_name + " hold a whole line", l_rows.bottom, l_rows.top)
				assert_integers_equal (l_name + " match the whole draw on their whole lines", 0,
					differing_in (l_whole, l_part, l_rows.top, l_rows.bottom))
				assert_less_than (l_name + " paint a fraction of the text", l_part_count, l_unit_count // 2)
			end
				-- one line's clip paints a handful
			l_part := drawn_under_clip (g, l_text, a_p, l_height, l_bands [2].top, l_bands [2].bottom)
			assert_greater_than (a_path + ": the one-line clip shows ink", ink_in (l_part, 0, l_bands [2].top, 320, l_bands [2].bottom), 5)
			assert_less_than (a_path + ": the one-line clip paints a handful", g.last_drawn_count, l_unit_count // 6)
		end

	check_a_held_draw_paints_its_line (a_p: SW_PAINTER; a_path: STRING)
			-- The sixty paragraphs, and four of their lines (plain, tabbed, the
			-- last of a wrapped paragraph, empty) each drawn twice under a clip
			-- of its own rows, free and held to the line: the rows agree pixel
			-- for pixel, and the held draw painted what stands on the line and
			-- no more. Released, a draw paints all again; a hold left over a
			-- shorter text holds nothing.
		local
			g: SW_TEXT_GEOMETRY
			l_text: STRING_32
			l_free, l_held: CAIRO_SURFACE
			l_h: REAL_64
			l_height, l_whole_count, l_top, l_bottom, l_free_count, l_held_count, l_wrapped: INTEGER
			l_lines: ARRAY [TUPLE [name: STRING; line: INTEGER; shaped_count: INTEGER; toy_most: INTEGER]]
		do
			l_text := sixty_paragraphs
			create g.make
			l_h := g.lay_out (a_p, l_text, 300.0, {SW_PAINTER}.Role_body, a_p.theme.size_body, False, False, False)
			l_height := l_h.ceiling + 20
			l_free := drawn_under_clip (g, l_text, a_p, l_height, 0, l_height)
			l_whole_count := g.last_drawn_count
				-- paragraph 33 wraps: its last line holds its number
			l_wrapped := l_text.substring_index ({STRING_32} "word 33", 1)
			assert_greater_than (a_path + ": paragraph 33 wraps",
				g.line_of (l_wrapped), g.line_of (l_text.substring_index ({STRING_32} "indented 32", 1)) + 1)
			l_lines := <<
				["a plain line", g.line_of (l_text.substring_index ({STRING_32} "plain line 31", 1)), 1, 13],
				["a tabbed line", g.line_of (l_text.substring_index ({STRING_32} "indented 32", 1)), 2, 22],
				["the last line of a wrapped paragraph", g.line_of (l_wrapped), 1, 150],
				["an empty line", g.line_of (l_text.substring_index ({STRING_32} "plain line 35", 1)) - 1, 0, 0]>>
			across
				l_lines as ic_line
			loop
				l_top := (5.0 + g.top_of_line (ic_line.line)).ceiling
				l_bottom := (5.0 + g.top_of_line (ic_line.line) + g.height_of_line (ic_line.line)).floor
				l_free := drawn_under_clip (g, l_text, a_p, l_height, l_top, l_bottom)
				l_free_count := g.last_drawn_count
				g.hold_draw_to_line (ic_line.line)
				l_held := drawn_under_clip (g, l_text, a_p, l_height, l_top, l_bottom)
				l_held_count := g.last_drawn_count
				g.release_draw
				assert_integers_equal (a_path + ", " + ic_line.name + ": held, its rows show what the clip alone shows", 0,
					differing_in (l_free, l_held, l_top, l_bottom))
				assert_less_than (a_path + ", " + ic_line.name + ": held, less is painted than under the clip alone",
					l_held_count, l_free_count)
				if g.is_shaped then
					assert_integers_equal (a_path + ", " + ic_line.name + ": the line's layouts and no other",
						ic_line.shaped_count, l_held_count)
				else
					assert_less_than (a_path + ", " + ic_line.name + ": the line's characters and no other",
						l_held_count, ic_line.toy_most + 1)
				end
				if ic_line.toy_most > 0 then
					assert_greater_than (a_path + ", " + ic_line.name + ": held, the line shows ink",
						ink_in (l_held, 0, l_top, 320, l_bottom), 5)
					assert_greater_than (a_path + ", " + ic_line.name + ": held, something is painted", l_held_count, 0)
				else
					assert_integers_equal (a_path + ", " + ic_line.name + ": held, nothing is painted", 0, l_held_count)
				end
			end
			assert_integers_equal (a_path + ": released", -1, g.held_line)
			l_free := drawn_under_clip (g, l_text, a_p, l_height, 0, l_height)
			assert_integers_equal (a_path + ": released, the whole text paints again", l_whole_count, g.last_drawn_count)
				-- a hold on a line the next text does not have
			g.hold_draw_to_line (g.line_count - 1)
			l_text := {STRING_32} "one line"
			l_h := g.lay_out (a_p, l_text, 300.0, {SW_PAINTER}.Role_body, a_p.theme.size_body, False, False, False)
			l_free := drawn_under_clip (g, l_text, a_p, 60, 0, 60)
			assert_greater_than (a_path + ": a hold past the last line holds nothing", g.last_drawn_count, 0)
			g.release_draw
		end

	sixty_paragraphs: STRING_32
			-- Sixty paragraphs in turn: plain, tabbed twice, wrapping at 300
			-- pixels, empty; each but the empty ones with its number.
		local
			i, j: INTEGER
		do
			create Result.make (6000)
			from i := 1 until i > 60 loop
				inspect i \\ 4
				when 0 then
					Result.append_string_general ("%Tindented " + i.out + "%Tsecond stop")
				when 1 then
					from j := 1 until j > 24 loop
						Result.append_string_general ("word ")
						j := j + 1
					end
					Result.append_string_general (i.out)
				when 2 then
						-- an empty line
				else
					Result.append_string_general ("plain line " + i.out)
				end
				Result.append_character ('%N')
				i := i + 1
			end
		ensure
			sixty: Result.occurrences ('%N') = 60
		end

	redraws, redrawn_units: INTEGER
			-- How many times `redraw_counted' drew, and how much those draws
			-- painted in all (`last_drawn_count').

	redraw_counted (a_g: SW_TEXT_GEOMETRY; a_text: STRING_32; a_p: SW_PAINTER; a_dx, a_dy: REAL_64)
			-- `a_text' from (10, 5) shifted by (`a_dx', `a_dy'), counted: the
			-- text agent of a mark painter.
		do
			a_g.draw (a_p, a_text, False, 10.0 + a_dx, 5.0 + a_dy)
			redraws := redraws + 1
			redrawn_units := redrawn_units + a_g.last_drawn_count
		end

	drawn_under_clip (a_g: SW_TEXT_GEOMETRY; a_text: STRING_32; a_p: SW_PAINTER; a_height, a_top, a_bottom: INTEGER): CAIRO_SURFACE
			-- A white surface 320 wide and `a_height' tall with `a_text' drawn from
			-- (10, 5) under a clip over rows `a_top' to `a_bottom', by a painter
			-- that shares `a_p''s theme and kit.
		require
			band: 0 <= a_top and a_top < a_bottom and a_bottom <= a_height
		local
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
		do
			create Result.make (320, a_height)
			create l_ctx.make (Result)
			l_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create l_p.make (l_ctx, a_p.theme)
			l_p.set_shaping (a_p.shaping)
			l_p.push_clip (0.0, a_top, 320.0, a_bottom - a_top)
			l_p.set_color (l_p.theme.ink)
			a_g.draw (l_p, a_text, False, 10.0, 5.0)
			l_p.pop_clip
			Result.flush.do_nothing
		end

	drawn_unskipped (a_g: SW_TEXT_GEOMETRY; a_text: STRING_32; a_p: SW_PAINTER; a_height, a_top, a_bottom: INTEGER): CAIRO_SURFACE
			-- As `drawn_under_clip', by a draw that skips nothing: the clip is
			-- rows `a_top' to `a_bottom' and one pixel more in the first row and
			-- in the last, at the right edge, where no text is. The clip then
			-- reaches from the top of the text to its bottom, so every line may
			-- show, and the rows of the band are cut as `drawn_under_clip' cuts them.
		require
			band: 0 <= a_top and a_top < a_bottom and a_bottom <= a_height
		local
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
		do
			create Result.make (320, a_height)
			create l_ctx.make (Result)
			l_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create l_p.make (l_ctx, a_p.theme)
			l_p.set_shaping (a_p.shaping)
			l_ctx.save.do_nothing
			l_ctx.new_path.do_nothing
			l_ctx.rectangle (0.0, a_top, 320.0, a_bottom - a_top).do_nothing
			l_ctx.rectangle (319.0, 0.0, 1.0, 1.0).do_nothing
			l_ctx.rectangle (319.0, a_height - 1, 1.0, 1.0).do_nothing
			l_ctx.clip.do_nothing
			l_p.set_color (l_p.theme.ink)
			a_g.draw (l_p, a_text, False, 10.0, 5.0)
			l_ctx.restore.do_nothing
			Result.flush.do_nothing
		end

	rows_of_whole_lines (a_g: SW_TEXT_GEOMETRY; a_top, a_bottom: INTEGER): TUPLE [top, bottom: INTEGER]
			-- The rows, `top' up to `bottom', of the lines of `a_g' (drawn from
			-- row 5) that stand whole inside rows `a_top' to `a_bottom';
			-- `bottom' = `top' when no line does.
		local
			i, l_first, l_last: INTEGER
			l_line_top, l_line_bottom: REAL_64
			l_found: BOOLEAN
		do
			from
				i := 0
			until
				i >= a_g.line_count
			loop
				l_line_top := 5.0 + a_g.top_of_line (i)
				l_line_bottom := l_line_top + a_g.height_of_line (i)
				if l_line_top >= a_top and l_line_bottom <= a_bottom then
					if not l_found then
						l_first := l_line_top.ceiling
						l_found := True
					end
					l_last := l_line_bottom.floor
				end
				i := i + 1
			end
			if l_found then
				Result := [l_first, l_last.max (l_first)]
			else
				Result := [a_top, a_top]
			end
		ensure
			ordered: Result.bottom >= Result.top
			inside: Result.top >= a_top and Result.bottom <= a_bottom
		end

	differing_in (a_one, a_other: CAIRO_SURFACE; a_y0, a_y1: INTEGER): INTEGER
			-- Pixels in rows `a_y0' up to `a_y1' where the two surfaces differ.
		require
			same_size: a_one.width = a_other.width and a_one.height = a_other.height
		local
			l_one, l_other: MANAGED_POINTER
			x, y: INTEGER
		do
			create l_one.share_from_pointer (a_one.data, a_one.stride * a_one.height)
			create l_other.share_from_pointer (a_other.data, a_other.stride * a_other.height)
			from
				y := a_y0.max (0)
			until
				y >= a_y1.min (a_one.height)
			loop
				from
					x := 0
				until
					x >= a_one.width
				loop
					if l_one.read_natural_32 (y * a_one.stride + x * 4) /= l_other.read_natural_32 (y * a_other.stride + x * 4) then
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
