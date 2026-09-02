note
	description: "[
		The shaped-text battery: simple_shaping adopted by the toolkit,
		proven on pixels rather than on a comment.

		The opening test is the one that was still owed - D-015, the
		simple_chat acceptance line, laid out by the production facade and
		painted through SW_PAINTER onto a real image surface, with the ink
		counted in three x-regions. It writes evidence/shaped-d015.png so a
		human can look at what the assertions measured.

		WHY x-REGIONS AND NOT A DIFF. The line's paragraph direction is RTL
		(first-strong is Hebrew), so UAX #9 puts the runs on the screen in
		the order Greek, robot, Hebrew from left to right - the Hebrew
		RIGHTMOST. That ordering is the whole point of adopting a shaping
		library, and it is exactly what cairo's toy `show_text' cannot do.
		Counting ink either side of the emoji box tests the ordering
		without pinning a single pixel, so a font update cannot break it
		and a bidi regression cannot pass it.
	]"
	author: "Larry Rix"

class
	SW_SHAPING_ASSAULT

inherit
	TEST_SET_BASE

feature -- The D-015 proof (AC-1, both halves, through the toolkit)

	test_d015_shaped_line_paints
			-- Hebrew right-to-left, the robot as the shipped Noto picture,
			-- Greek intact - laid out by SIMPLE_SHAPING, painted by
			-- SW_PAINTER.draw_shaped_layout, measured in ink.
		local
			kit: SW_SHAPING
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			lay: SHAPED_LAYOUT
			ln: SHAPED_LINE
			img: detachable IMAGE_RUN
			assets, evidence: STRING_32
			pen, box_x, box_top, baseline, max_y_offset: REAL_64
			left_ink, box_ink, right_ink, total_ink, i: INTEGER
			ink_top, ink_bottom, box_ink_top, box_ink_bottom: INTEGER
			origin_x, origin_y: REAL_64
			wrote: BOOLEAN
		do
			assets := shaping_assets
			assert_false ("the Noto png/128 assets were located", assets.is_empty)

			create kit.make_with_assets (assets)
			lay := kit.facade.layout_default (d015_text, {SHAPING_CONSTANTS}.No_wrap, 16)

				-- ---- what the LAYOUT says, before a pixel is drawn ----
			assert_integers_equal ("No_wrap gives one unbounded line", 1, lay.lines.count)
			assert_true ("coverage holds", lay.covers_all_characters)
			assert_integers_equal ("first-strong is Hebrew, so the paragraph is RTL",
				{SHAPING_CONSTANTS}.Direction_rtl, lay.base_direction)
			ln := lay.lines [1]

			across ln.runs as r loop
				if attached {IMAGE_RUN} r as al_img then
					img := al_img
				elseif attached {GLYPH_RUN} r as al_gly then
					from i := al_gly.y_positions.lower until i > al_gly.y_positions.upper loop
						max_y_offset := max_y_offset.max (al_gly.y_positions [i].abs)
						i := i + 1
					end
				end
			end
			assert_attached ("U+1F916 came back as an IMAGE_RUN", img)

				-- THE ORDERING, AS STRUCTURE. In an RTL paragraph UAX #9 L2
				-- reverses the line, so the LTR Greek (an even embedding
				-- level) is painted FIRST - leftmost - and the Hebrew (an odd
				-- level) LAST - rightmost. The ink counts below say ink is in
				-- three places; this says which script is in which place.
			assert_true ("the first run in visual order is LTR - the Greek",
				not ln.runs.first.is_rtl)
			assert_true ("and the last is RTL - the Hebrew, visually rightmost",
				ln.runs.last.is_rtl)

				-- ---- paint it ----
			origin_x := 12.0
			origin_y := 10.0
			create th.make_dark
			create surf.make (420, 80)
			create ctx.make (surf)
			ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			surf.flush.do_nothing
			assert_integers_equal ("a white ground carries no ink", 0, ink_in (surf, 0, 0, 420, 80))

			create p.make (ctx, th)
			p.set_shaping (kit)
			assert_true ("the painter reports shaping available", p.has_shaping)
			p.set_color (0x000000)
			p.draw_shaped_layout (lay, origin_x, origin_y)
			surf.flush.do_nothing

				-- ---- where the bridge put the emoji box ----
			pen := origin_x
			box_x := -1.0
			across ln.runs as r loop
				if attached {IMAGE_RUN} r and then box_x < 0.0 then
					box_x := pen
				end
				pen := pen + r.advance_width
			end
			assert_true ("the image run was found in visual order", box_x >= 0.0)
			baseline := origin_y + ln.ascent
			if attached img as al_robot then
				box_top := baseline - al_robot.height
				left_ink := ink_in (surf, 0, 0, box_x.floor, 80)
				box_ink := ink_in (surf, box_x.floor, 0, (box_x + al_robot.width).ceiling, 80)
				right_ink := ink_in (surf, (box_x + al_robot.width).ceiling, 0, 420, 80)
				box_ink_top := ink_top_in (surf, box_x.floor, (box_x + al_robot.width).ceiling)
				box_ink_bottom := ink_bottom_in (surf, box_x.floor, (box_x + al_robot.width).ceiling)
			end
			total_ink := ink_in (surf, 0, 0, 420, 80)
				-- The TRIPWIRE and the placement check are read off the GLYPH
				-- band (left of the emoji box), never off the whole image: a
				-- 16-pixel emoji box would satisfy a height test on its own
				-- and hide exactly the 1/32 collapse the test exists to catch.
			ink_top := ink_top_in (surf, 0, box_x.floor)
			ink_bottom := ink_bottom_in (surf, 0, box_x.floor)

			print ("    d015: runs " + ln.runs.count.out + ", width " + ln.width.out
				+ ", height " + ln.height.out + ", ascent " + ln.ascent.out
				+ ", total_height " + lay.total_height.out
				+ ", box_top " + box_top.out + "%N")
			print ("    d015 ink: left(Greek) " + left_ink.out + ", box(emoji) " + box_ink.out
				+ ", right(Hebrew) " + right_ink.out + ", total " + total_ink.out
				+ "; glyph rows " + ink_top.out + ".." + ink_bottom.out
				+ " (h " + (ink_bottom - ink_top + 1).out + ")"
				+ "; box rows " + box_ink_top.out + ".." + box_ink_bottom.out
				+ "; painted " + kit.bridge.painted_runs.out
				+ ", skipped " + kit.bridge.skipped_runs.out
				+ ", status " + ctx.status.out
				+ ", max|y_position| " + max_y_offset.out + "%N")

				-- ---- THE THREE REGIONS ----
			assert_greater_than ("Greek inked the LEFT of the emoji box", left_ink, 20)
			assert_greater_than ("the robot inked the BOX", box_ink, 40)
			assert_greater_than ("Hebrew inked the RIGHT of the emoji box - RTL, visually last",
				right_ink, 20)

				-- ---- THE SAME-N TRIPWIRE ----
			assert_greater_than ("the glyph ink box is at least half the 16 px size",
				ink_bottom - ink_top + 1, 7)

				-- ---- the glyphs are not vertically misplaced ----
			assert_greater_or_equal ("no glyph ink above the layout's own top",
				ink_top, origin_y.floor - 1)
			assert_less_or_equal ("no glyph ink below the layout's own bottom",
				ink_bottom, (origin_y + lay.total_height).ceiling + 1)
			assert_greater_or_equal ("the Hebrew band sits on the same rows",
				ink_top_in (surf, (box_x + robot_width (img)).ceiling, 420), origin_y.floor - 1)

				-- ---- the image run's BOX contains its ink ----
			if attached img as al_robot then
				assert_greater_or_equal ("the emoji ink starts at or below the box top",
					box_ink_top, box_top.floor - 1)
				assert_less_or_equal ("and ends at or above the box bottom",
					box_ink_bottom, (box_top + al_robot.height).ceiling + 1)
			end

				-- ---- the context is healthy and nothing degraded ----
			assert_integers_equal ("cairo is still healthy", 0, ctx.status)
			assert_true ("and the context reports itself valid", ctx.is_valid)
			assert_integers_equal ("no run was skipped", 0, kit.bridge.skipped_runs)
			assert_integers_equal ("every run painted",
				kit.bridge.run_count (lay), kit.bridge.painted_runs)

				-- ---- evidence a human can open ----
			evidence := evidence_path ("shaped-d015.png")
			if not evidence.is_empty then
				wrote := surf.write_png (evidence)
					-- STRING_32 and STRING_8 do not concatenate without an
					-- obsolete narrowing call; three prints cost nothing.
				print ("    d015 evidence: ")
				print (evidence)
				print (" written " + wrote.out + "%N")
			end
			ctx.destroy
			surf.destroy
			kit.dispose_surfaces
		end

feature -- The chat thread

	test_chat_bubbles_measure_from_their_layouts
			-- Three bubbles of mixed script: every height comes from
			-- `total_height', the paint raises nothing, and the widget's
			-- public model is untouched.
		local
			c: SW_CHAT_THREAD
			kit: SW_SHAPING
			p: SW_PAINTER
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			assets: STRING_32
			i, expected_runs: INTEGER
		do
			assets := shaping_assets
			assert_false ("assets located", assets.is_empty)
			create kit.make_with_assets (assets)
			create th.make_dark
			kit.set_theme_faces (th)
			create surf.make (400, 300)
			create ctx.make (surf)
			ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create p.make (ctx, th)
			p.set_shaping (kit)

			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 300.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, d015_text)
			c.add_message ({SW_CHAT_THREAD}.Role_mine, "A plain ASCII reply that is long enough to need more than one line inside a bubble this wide.")
			c.add_message ({SW_CHAT_THREAD}.Role_system, hebrew_text)
			assert_integers_equal ("three messages", 3, c.count)

			c.draw (p)
			surf.flush.do_nothing

			assert_integers_equal ("one layout per message", 3, c.shaped_layouts.count)
			from i := 1 until i > 3 loop
				assert_true ("bubble " + i.out + " has a real height",
					c.shaped_layouts [i].total_height > 0.0)
				assert_integers_equal ("bubble " + i.out + " was laid out at the pane's inner width",
					c.laid_out_width, c.shaped_layouts [i].width_pixels)
				i := i + 1
			end
			from i := 1 until i > 3 loop
				expected_runs := expected_runs + kit.bridge.run_count (c.shaped_layouts [i])
				i := i + 1
			end
			print ("    chat: inner width " + c.laid_out_width.out + " px, size "
				+ c.laid_out_size.out + " px, heights "
				+ c.shaped_layouts [1].total_height.out + " / "
				+ c.shaped_layouts [2].total_height.out + " / "
				+ c.shaped_layouts [3].total_height.out
				+ ", content_h " + c.content_h.out
				+ ", runs " + expected_runs.out
				+ ", painted " + kit.bridge.painted_runs.out
				+ ", skipped " + kit.bridge.skipped_runs.out + "%N")

			assert_real_greater_than ("the thread measured itself", c.content_h, 0.0)
				-- The honest instrument, and the reason this is not an ink
				-- count: the widget paints its own background, so a pane of
				-- solid theme colour is "non-white" everywhere and an ink
				-- count over it would pass whether or not a glyph was drawn.
				-- `painted_runs' counts what actually reached cairo.
			assert_greater_than ("every run of all three bubbles reached cairo",
				kit.bridge.painted_runs, expected_runs - 1)
			assert_integers_equal ("cairo is healthy after three shaped bubbles", 0, ctx.status)

				-- the public model is exactly what it always was
			assert_true ("sticky by default", c.is_sticky)
			c.append_to_last (" and more")
			assert_true ("append_to_last still grows the last message",
				c.last_text.ends_with_general (" and more"))
			c.draw (p)
			assert_integers_equal ("still one layout per message", 3, c.shaped_layouts.count)
			assert_integers_equal ("no run was skipped across two frames", 0, kit.bridge.skipped_runs)

			ctx.destroy
			surf.destroy
			kit.dispose_surfaces
		end

	test_chat_relayouts_when_the_pane_narrows
			-- R10's other half: a WIDTH change re-lays-out (and the line
			-- count moves), but only once the resize storm has passed.
		local
			c: SW_CHAT_THREAD
			kit: SW_SHAPING
			p: SW_PAINTER
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			assets: STRING_32
			wide_lines, storm_lines, narrow_lines, wide_w: INTEGER
		do
			assets := shaping_assets
			assert_false ("assets located", assets.is_empty)
			create kit.make_with_assets (assets)
			create th.make_dark
			create surf.make (600, 300)
			create ctx.make (surf)
			ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create p.make (ctx, th)
			p.set_shaping (kit)

			create c.make
			c.add_message ({SW_CHAT_THREAD}.Role_theirs,
				"The quick brown fox jumps over the lazy dog, and then it does it again, and again, until the sentence is long enough to wrap several times over.")

			c.set_bounds (0.0, 0.0, 560.0, 300.0)
			c.draw (p)
			wide_lines := c.shaped_layouts [1].lines.count
			wide_w := c.laid_out_width

				-- Mid-drag: the pane narrows but the layout must NOT move.
			c.set_bounds (0.0, 0.0, 200.0, 300.0)
			p.set_resize_storm (True)
			c.draw (p)
			storm_lines := c.shaped_layouts [1].lines.count
			assert_integers_equal ("R10: a drag does not reflow", wide_lines, storm_lines)
			assert_integers_equal ("and the width on record is still the old one",
				wide_w, c.laid_out_width)

				-- Drag over: now it reflows.
			p.set_resize_storm (False)
			c.draw (p)
			narrow_lines := c.shaped_layouts [1].lines.count
			print ("    resize: " + wide_w.out + " px -> " + c.laid_out_width.out
				+ " px, lines " + wide_lines.out + " -> " + storm_lines.out
				+ " (mid-drag) -> " + narrow_lines.out + "%N")
			assert_less_than ("the pane really did narrow", c.laid_out_width, wide_w)
			assert_greater_than ("a narrower bubble needs more lines", narrow_lines, wide_lines)
			assert_integers_equal ("cairo is healthy", 0, ctx.status)

			ctx.destroy
			surf.destroy
			kit.dispose_surfaces
		end

	test_ascii_bubble_renders_on_both_paths
			-- The regression that matters most: plain ASCII still draws, with
			-- a kit and without one, and the toy path builds no layouts at all.
			--
			-- HOW "IT DREW THE TEXT" IS MEASURED. The widget paints its own
			-- background, so counting non-white pixels would pass on a pane of
			-- solid theme colour with no glyph on it. So each path draws the
			-- SAME thread twice - once with a sentence, once with a single
			-- full stop - over the same bounds, and the sentence must leave
			-- materially more non-background pixels than the stop does. That
			-- difference is the text and nothing else.
		local
			c, dot: SW_CHAT_THREAD
			kit: SW_SHAPING
			p: SW_PAINTER
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			assets: STRING_32
			toy_text, toy_dot, shaped_text, shaped_dot: INTEGER
		do
			create th.make_dark
			create surf.make (400, 200)
			create ctx.make (surf)
			create p.make (ctx, th)

			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 200.0)
			c.add_message ({SW_CHAT_THREAD}.Role_mine, "Plain ASCII, no kit at all.")
			create dot.make
			dot.set_bounds (0.0, 0.0, 400.0, 200.0)
			dot.add_message ({SW_CHAT_THREAD}.Role_mine, ".")

				-- ---- toy path ----
			assert_false ("no kit means no shaping", p.has_shaping)
			toy_text := non_background_ink (surf, ctx, p, c, th)
			assert_true ("the toy path built no layouts", c.shaped_layouts.is_empty)
			toy_dot := non_background_ink (surf, ctx, p, dot, th)

				-- ---- shaped path, same two threads ----
			assets := shaping_assets
			assert_false ("assets located", assets.is_empty)
			create kit.make_with_assets (assets)
			p.set_shaping (kit)
			shaped_text := non_background_ink (surf, ctx, p, c, th)
			shaped_dot := non_background_ink (surf, ctx, p, dot, th)

			print ("    ascii: toy " + toy_text.out + " vs " + toy_dot.out
				+ " px, shaped " + shaped_text.out + " vs " + shaped_dot.out
				+ " px, lines " + c.shaped_layouts [1].lines.count.out
				+ ", painted " + kit.bridge.painted_runs.out
				+ ", skipped " + kit.bridge.skipped_runs.out + "%N")

			assert_integers_equal ("one layout on the shaped path", 1, c.shaped_layouts.count)
			assert_greater_than ("the TOY path really drew the sentence",
				toy_text - toy_dot, 100)
			assert_greater_than ("and so did the SHAPED path",
				shaped_text - shaped_dot, 100)
			assert_greater_than ("runs reached cairo", kit.bridge.painted_runs, 1)
			assert_integers_equal ("no run degraded on pure ASCII", 0, kit.bridge.skipped_runs)

				-- ---- and back to the toy path, on demand ----
			p.set_shaping (Void)
			assert_false ("shaping is off again", p.has_shaping)
			assert_greater_than ("the toy path still works after a shaped frame",
				non_background_ink (surf, ctx, p, c, th) - toy_dot, 100)
			assert_integers_equal ("cairo survived three mode switches", 0, ctx.status)

			ctx.destroy
			surf.destroy
			kit.dispose_surfaces
		end

	test_niqqud_offsets_are_reported_not_swallowed
			-- A DIAGNOSTIC, and it is here because the toolkit is the first
			-- consumer that can see the answer.
			--
			-- simple_shaping's own Task 13 evidence states the assembly rule
			-- for a glyph run as `y_positions [i] = -shaped.y_offsets [i]',
			-- because DirectWrite's ascenderOffset is positive UPWARD while
			-- cairo's user space is y-down. Latin, Greek and unpointed Hebrew
			-- carry no mark offsets at all (the D-015 test prints
			-- max|y_position| 0), so the sign is invisible there. Hebrew WITH
			-- NIQQUD is the first text that can show it.
			--
			-- This test asserts only what is certainly true - the layout is
			-- produced, every run paints, cairo stays healthy - and PRINTS the
			-- offsets it found, so the number is on the record for the
			-- library's owner rather than guessed at from source.
		local
			kit: SW_SHAPING
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			lay: SHAPED_LAYOUT
			assets: STRING_32
			min_y, max_y: REAL_64
			i, marks: INTEGER
		do
			assets := shaping_assets
			assert_false ("assets located", assets.is_empty)
			create kit.make_with_assets (assets)
			lay := kit.facade.layout_default (pointed_hebrew, {SHAPING_CONSTANTS}.No_wrap, 24)

			across lay.lines as l loop
				across l.runs as r loop
					if attached {GLYPH_RUN} r as al_gly then
						from i := al_gly.y_positions.lower until i > al_gly.y_positions.upper loop
							min_y := min_y.min (al_gly.y_positions [i])
							max_y := max_y.max (al_gly.y_positions [i])
							if al_gly.y_positions [i] /= 0.0 then
								marks := marks + 1
							end
							i := i + 1
						end
					end
				end
			end

			create th.make_dark
			create surf.make (300, 80)
			create ctx.make (surf)
			ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			create p.make (ctx, th)
			p.set_shaping (kit)
			p.set_color (0x000000)
			p.draw_shaped_layout (lay, 10.0, 10.0)
			surf.flush.do_nothing

			print ("    niqqud: " + lay.lines [1].runs.count.out + " runs, "
				+ marks.out + " glyphs with a non-zero y_position, range "
				+ min_y.out + " .. " + max_y.out
				+ "; ink rows " + ink_top_in (surf, 0, 300).out + ".."
				+ ink_bottom_in (surf, 0, 300).out
				+ "; painted " + kit.bridge.painted_runs.out
				+ ", skipped " + kit.bridge.skipped_runs.out
				+ ", status " + ctx.status.out + "%N")

			assert_true ("pointed Hebrew laid out", not lay.lines.is_empty)
			assert_integers_equal ("nothing degraded", 0, kit.bridge.skipped_runs)
			assert_greater_than ("something reached cairo", kit.bridge.painted_runs, 0)
			assert_integers_equal ("cairo is healthy", 0, ctx.status)

			ctx.destroy
			surf.destroy
			kit.dispose_surfaces
		end

feature {NONE} -- Measuring a widget against its own background

	non_background_ink (a_surface: CAIRO_SURFACE; a_context: CAIRO_CONTEXT;
			a_painter: SW_PAINTER; a_thread: SW_CHAT_THREAD; a_theme: SW_THEME): INTEGER
			-- Draw `a_thread' on a cleared surface and count the pixels that
			-- are neither the pane's own fill nor the bubble's - which is the
			-- text, the outline and their antialiasing, and nothing else.
		require
			valid: a_surface.is_valid
		do
			a_context.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			a_thread.draw (a_painter)
			a_surface.flush.do_nothing
			Result := ink_excluding (a_surface, opaque (a_theme.surface),
				opaque (a_theme.wash_accent))
		ensure
			non_negative: Result >= 0
		end

	opaque (a_rgb: NATURAL_32): NATURAL_32
			-- `a_rgb' as the ARGB32 pixel cairo writes for it.
		do
			Result := a_rgb.bit_and (0x00FFFFFF) | 0xFF000000
		end

	ink_excluding (a_surface: CAIRO_SURFACE; a_first, a_second: NATURAL_32): INTEGER
			-- Pixels over the whole surface that are neither `a_first' nor
			-- `a_second'.
		require
			valid: a_surface.is_valid
		local
			px, py: INTEGER
			v: NATURAL_32
		do
			from py := 0 until py >= a_surface.height loop
				from px := 0 until px >= a_surface.width loop
					v := pixel_at (a_surface, px, py)
					if v /= a_first and v /= a_second then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
		ensure
			non_negative: Result >= 0
		end

feature -- The kit

	test_kit_prepends_the_theme_face_for_latin_only
			-- Q1: a theme face is Latin-only, so it is prepended for the
			-- LATIN class and nowhere else. Hebrew and Greek keep the
			-- library's own scholar-grade order.
		local
			kit: SW_SHAPING
			th: SW_THEME
			assets: STRING_32
		do
			assets := shaping_assets
			assert_false ("assets located", assets.is_empty)
			create kit.make_with_assets (assets)
			assert_void ("a fresh kit uses the facade's own defaults", kit.fonts)
			create th.make_dark
			kit.set_theme_faces (th)
			if attached kit.fonts as f then
				assert_true ("the theme face leads the LATIN bucket",
					f.families_for ({SHAPING_CONSTANTS}.Script_class_latin).first.same_string_general (th.family_ui))
				assert_false ("Hebrew is untouched by the theme",
					f.families_for ({SHAPING_CONSTANTS}.Script_class_hebrew).first.same_string_general (th.family_ui))
				assert_false ("and so is Greek",
					f.families_for ({SHAPING_CONSTANTS}.Script_class_greek).first.same_string_general (th.family_ui))
			else
				assert_true ("set_theme_faces left a policy", False)
			end
		end

feature {NONE} -- The acceptance text

	robot_width (a_run: detachable IMAGE_RUN): REAL_64
			-- `a_run''s box width, or 0 when the robot never arrived.
		do
			if attached a_run as al then
				Result := al.width
			end
		ensure
			non_negative: Result >= 0.0
		end

	d015_text: STRING_32
			-- The D-015 line as CODE POINTS - shalom, space, robot, space,
			-- Christos. A source literal would put this file's encoding on
			-- trial instead of the shaping library.
		do
			Result := text_of (<<0x05E9, 0x05DC, 0x05D5, 0x05DD, 0x0020, 0x1F916, 0x0020,
				0x03A7, 0x03C1, 0x03B9, 0x03C3, 0x03C4, 0x03CC, 0x03C2>>)
		ensure
			fourteen_code_points: Result.count = 14
		end

	pointed_hebrew: STRING_32
			-- Shalom WITH NIQQUD: shin + shin-dot + qamats, lamed, vav +
			-- holam, final mem. Marks sit BELOW and ABOVE the base letters,
			-- which is the whole point - unpointed text carries no vertical
			-- offsets and so cannot show a sign error.
		do
			Result := text_of (<<0x05E9, 0x05C1, 0x05B8, 0x05DC, 0x05D5, 0x05B9, 0x05DD>>)
		ensure
			seven_code_points: Result.count = 7
		end

	hebrew_text: STRING_32
			-- Shalom alone - one RTL bubble with no Latin in it at all.
		do
			Result := text_of (<<0x05E9, 0x05DC, 0x05D5, 0x05DD>>)
		end

	text_of (a_codes: ARRAY [INTEGER]): STRING_32
			-- `a_codes' as one STRING_32 code point per entry.
		local
			i: INTEGER
		do
			create Result.make (a_codes.count)
			from i := a_codes.lower until i > a_codes.upper loop
				Result.append_code (a_codes [i].to_natural_32)
				i := i + 1
			end
		ensure
			one_per_code_point: Result.count = a_codes.count
		end

feature {NONE} -- Ink

	White_pixel: NATURAL_32 = 0xFFFFFFFF

	pixel_at (a_surface: CAIRO_SURFACE; a_x, a_y: INTEGER): NATURAL_32
			-- ARGB32 pixel at (`a_x', `a_y'). `flush' first.
		require
			valid: a_surface.is_valid
			in_range: a_x >= 0 and a_y >= 0
				and a_x < a_surface.width and a_y < a_surface.height
		local
			mp: MANAGED_POINTER
		do
			create mp.share_from_pointer (a_surface.data, a_surface.stride * a_surface.height)
			Result := mp.read_natural_32 (a_y * a_surface.stride + a_x * 4)
		end

	ink_in (a_surface: CAIRO_SURFACE; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Non-white pixels inside [`a_x0', `a_x1') x [`a_y0', `a_y1').
		require
			valid: a_surface.is_valid
		local
			px, py: INTEGER
		do
			from py := a_y0.max (0) until py >= a_y1.min (a_surface.height) loop
				from px := a_x0.max (0) until px >= a_x1.min (a_surface.width) loop
					if pixel_at (a_surface, px, py) /= White_pixel then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
		ensure
			non_negative: Result >= 0
		end

	ink_top_in (a_surface: CAIRO_SURFACE; a_x0, a_x1: INTEGER): INTEGER
			-- Topmost inked row within the x-band; -1 when the band is blank.
		require
			valid: a_surface.is_valid
		local
			py: INTEGER
			found: BOOLEAN
		do
			Result := -1
			from py := 0 until py >= a_surface.height or found loop
				if ink_in (a_surface, a_x0, py, a_x1, py + 1) > 0 then
					Result := py
					found := True
				end
				py := py + 1
			end
		end

	ink_bottom_in (a_surface: CAIRO_SURFACE; a_x0, a_x1: INTEGER): INTEGER
			-- Bottommost inked row within the x-band; -1 when blank.
		require
			valid: a_surface.is_valid
		local
			py: INTEGER
			found: BOOLEAN
		do
			Result := -1
			from py := a_surface.height - 1 until py < 0 or found loop
				if ink_in (a_surface, a_x0, py, a_x1, py + 1) > 0 then
					Result := py
					found := True
				end
				py := py - 1
			end
		end

feature {NONE} -- Locating things on disk

	shaping_assets: STRING_32
			-- The Noto png/128 tree, or empty.
			--
			-- SEARCH ORDER, and it is a decision, not an accident. FIRST the
			-- AC-9 runnable folder (assets beside the exe) - because that is
			-- what a shipped app has, and a test that never looks there
			-- would never notice the staging step going missing. SECOND the
			-- simple_shaping repository under $SIMPLE_EIFFEL - because this
			-- library's own test target deliberately does NOT copy 3,768
			-- files (about 20 MiB) into F_code on every build. See README.
		local
			env: EXECUTION_ENVIRONMENT
			exe, candidate: PATH
		do
			create Result.make_empty
			create env
			create exe.make_from_string (env.arguments.command_name)
			candidate := exe.parent.extended ("assets").extended ("noto-emoji").extended ("png").extended ("128")
			if directory_exists (candidate.name) then
				Result := candidate.name.to_string_32
			elseif attached env.item ("SIMPLE_EIFFEL") as al_root and then not al_root.is_empty then
				candidate := (create {PATH}.make_from_string (al_root)).extended ("simple_shaping")
					.extended ("assets").extended ("noto-emoji").extended ("png").extended ("128")
				if directory_exists (candidate.name) then
					Result := candidate.name.to_string_32
				end
			end
		end

	evidence_path (a_name: STRING): STRING_32
			-- `<repo>/evidence/<a_name>', where `<repo>' is the first
			-- ancestor of the working directory or of the exe's own folder
			-- that holds `simple_widgets.ecf'. Empty when the repository is
			-- not underfoot, which simply means no evidence file is written.
		require
			name_not_empty: not a_name.is_empty
		local
			env: EXECUTION_ENVIRONMENT
			starts: ARRAYED_LIST [PATH]
			base, marker, dir: PATH
			d: DIRECTORY
			i, step: INTEGER
			found: BOOLEAN
		do
			create Result.make_empty
			create env
			create starts.make (2)
			starts.extend (env.current_working_path)
			starts.extend ((create {PATH}.make_from_string (env.arguments.command_name)).parent)
			from i := 1 until i > starts.count or found loop
				base := starts [i]
				from step := 0 until step > 6 or found loop
					marker := base.extended ("simple_widgets.ecf")
					if file_exists (marker.name) then
						dir := base.extended ("evidence")
						if not directory_exists (dir.name) then
							create d.make_with_path (dir)
							d.recursive_create_dir
						end
						if directory_exists (dir.name) then
							Result := dir.extended (a_name).name.to_string_32
						end
						found := True
					else
						base := base.parent
					end
					step := step + 1
				end
				i := i + 1
			end
		end

	directory_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			d: DIRECTORY
		do
			create d.make_with_name (a_path)
			Result := d.exists
		end

	file_exists (a_path: READABLE_STRING_32): BOOLEAN
		local
			f: RAW_FILE
		do
			create f.make_with_name (a_path)
			Result := f.exists
		end

end
