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

feature -- GW-04: every widget's text through the shaped path, Hebrew and Greek in both themes

	test_gw04_painter_text_shapes_hebrew_and_greek_light
			-- Larry, 2026-10-22: "Hebrew and Greek need to work in both Light
			-- and Dark. Period. Full stop." The light half.
		do
			painter_text_gate (create {SW_THEME}.make_light, "gw04_hebrew_greek_light.png")
		end

	test_gw04_painter_text_shapes_hebrew_and_greek_dark
			-- The dark half of the same gate.
		do
			painter_text_gate (create {SW_THEME}.make_dark, "gw04_hebrew_greek_dark.png")
		end

	test_gw04_advance_is_the_shaped_width
			-- With a kit, `advance' measures what `text' draws: the shaped
			-- layout's width, bold wider than regular.
		local
			kit: SW_SHAPING
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			regular, bold: REAL_64
		do
			create kit.make_with_assets (shaping_assets)
			create th.make_light
			kit.set_theme_faces (th)
			create surf.make (400, 80)
			create ctx.make (surf)
			create p.make (ctx, th)
			p.set_shaping (kit)
			p.font ({SW_PAINTER}.Role_body, 24.0, False)
			assert_true ("the painter shapes now", p.takes_shaped_path (genesis_1_1_wlc))
			assert_reals_equal ("advance is the shaped width",
				kit.layout_styled (genesis_1_1_wlc, 0, p.font_pixel_size, {SW_PAINTER}.Role_body, False).total_width,
				p.advance (genesis_1_1_wlc), 0.001)
			p.font ({SW_PAINTER}.Role_ui, 18.0, False)
			regular := p.advance ("Passage Guide")
			p.font ({SW_PAINTER}.Role_ui, 18.0, True)
			bold := p.advance ("Passage Guide")
			assert_true ("bold measures wider than regular", bold > regular)
		end

	test_gw04_without_a_kit_the_toy_path_is_unchanged
			-- No kit: `text' and `advance' are cairo's, exactly as before.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
		do
			create th.make_light
			create surf.make (400, 80)
			create ctx.make (surf)
			create p.make (ctx, th)
			p.font ({SW_PAINTER}.Role_ui, 16.0, False)
			assert_false ("no kit, no shaping", p.takes_shaped_path ("abc"))
			assert_reals_equal ("advance is cairo's",
				ctx.text_extents ({STRING_32} "abc").x_advance, p.advance ("abc"), 0.000_1)
		end

feature -- GW-02: Hebrew flush right, the gutter on the reading side

	test_gw02_geometry_sets_hebrew_flush_right
			-- With Align_start the Hebrew line ends at the box's right edge,
			-- the caret before the first character stands there, and a click
			-- at the right edge lands on the reading start; English in the
			-- same geometry starts at the left.
		local
			kit: SW_SHAPING
			g: SW_TEXT_GEOMETRY
			box: REAL_64
		do
			create kit.make_with_assets (shaping_assets)
			create g.make
			box := 600.0
			g.set_alignment ({SHAPING_CONSTANTS}.Align_start, box)
			g.build_shaped (kit, genesis_1_1_wlc, box.floor, 22, False)
			assert_true ("the paragraph starts right to left", g.starts_right_to_left)
			assert_reals_equal ("the line is flush right",
				box - g.layouts.first.lines.first.width, g.offset_of_line (0), 0.01)
			assert_reals_equal ("the reading-start caret is at the right edge", box, g.x_at_offset (0), 1.0)
			assert_integers_equal ("a click at the right edge is the reading start", 0,
				g.offset_at (box - 1.0, g.ascent_of_line (0) / 2.0))
			g.build_shaped (kit, {STRING_32} "In the beginning", box.floor, 22, False)
			assert_false ("English starts left to right", g.starts_right_to_left)
			assert_reals_equal ("and flush left", 0.0, g.offset_of_line (0), 0.01)
		end

	test_gw02_text_box_hebrew_flush_right_light
			-- The light half: a Hebrew text box set to Align_start inks its
			-- right side, not its left.
		do
			text_box_flush_right_gate (create {SW_THEME}.make_light)
		end

	test_gw02_text_box_hebrew_flush_right_dark
			-- The dark half of the same gate.
		do
			text_box_flush_right_gate (create {SW_THEME}.make_dark)
		end

	test_gw02_paragraph_list_gutter_follows_reading_light
			-- Light: Hebrew paragraphs carry the verse number on the right,
			-- English and Greek on the left; evidence written.
		do
			paragraph_list_gate (create {SW_THEME}.make_light, "gw02_verses_light.png")
		end

	test_gw02_paragraph_list_gutter_follows_reading_dark
			-- Dark: the same.
		do
			paragraph_list_gate (create {SW_THEME}.make_dark, "gw02_verses_dark.png")
		end

feature -- GW-03: pointed Hebrew and polytonic Greek, verified in the shipped faces

	test_gw03_faces_cover_and_marks_attach
			-- At 14, 18, 24, 32 and 40 px: Hebrew in Noto Serif Hebrew and
			-- Greek in Noto Serif (loaded privately, as an app ships them),
			-- no tofu, and the marks ATTACH rather than take up room - the
			-- pointed verse is about as wide as its bare consonants, the
			-- decomposed Greek about as wide as its precomposed form.
		local
			kit: SW_SHAPING
			sizes: ARRAY [INTEGER]
			i, px: INTEGER
			pointed, bare, decomposed, composed: SHAPED_LAYOUT
		do
			kit := gw03_kit (create {SW_THEME}.make_light)
			sizes := <<14, 18, 24, 32, 40>>
			from i := sizes.lower until i > sizes.upper loop
				px := sizes [i]
				pointed := kit.layout_styled (genesis_1_1_wlc, 0, px, {SW_PAINTER}.Role_body, False)
				bare := kit.layout_styled (consonants_only (genesis_1_1_wlc), 0, px, {SW_PAINTER}.Role_body, False)
				decomposed := kit.layout_styled (john_1_1_wh, 0, px, {SW_PAINTER}.Role_body, False)
				composed := kit.layout_styled (john_1_1_wh_nfc, 0, px, {SW_PAINTER}.Role_body, False)
				assert_false (px.out + " px: no Hebrew tofu", has_missing_glyph (pointed))
				assert_false (px.out + " px: no Greek tofu", has_missing_glyph (decomposed) or has_missing_glyph (composed))
				if px < 18 then
					assert_true (px.out + " px: Hebrew letters in Noto Serif Hebrew Medium",
						letters_in_family (pointed, 0x05D0, 0x05EA, "Noto Serif Hebrew Medium"))
				else
					assert_true (px.out + " px: Hebrew letters in Noto Serif Hebrew",
						letters_in_family (pointed, 0x05D0, 0x05EA, "Noto Serif Hebrew"))
				end
				assert_true (px.out + " px: Greek letters in Noto Serif",
					letters_in_family (decomposed, 0x0370, 0x03FF, "Noto Serif"))
				assert_true (px.out + " px: Hebrew marks attach (width within 4%)",
					(pointed.total_width - bare.total_width).abs <= 0.04 * bare.total_width)
				assert_true (px.out + " px: Greek combining marks attach (width within 4%)",
					(decomposed.total_width - composed.total_width).abs <= 0.04 * composed.total_width)
				i := i + 1
			end
		end

	test_gw03_marks_visible_light
			-- Light: the points ink below the line and read clearly.
		do
			marks_visible_gate (create {SW_THEME}.make_light, "gw03_specimen_light.png")
		end

	test_gw03_marks_visible_dark
			-- Dark: the same, and no fading on the dark ground.
		do
			marks_visible_gate (create {SW_THEME}.make_dark, "gw03_specimen_dark.png")
		end

	test_gw03_mapm_nbsp_never_breaks_before_paseq
			-- MapM writes a no-break space before paseq (FR-008). Nehemiah
			-- 11:33 wrapped at every width from 60 to 400 px: the no-break
			-- space, the word before it and the paseq after it always share a
			-- line; and nothing is tofu.
		local
			kit: SW_SHAPING
			lay: SHAPED_LAYOUT
			w, nbsp: INTEGER
		do
			kit := gw03_kit (create {SW_THEME}.make_light)
			nbsp := nehemiah_11_33_mapm.index_of ((0x00A0).to_character_32, 1)
			assert_true ("the verse holds its no-break space", nbsp > 1)
			assert_integers_equal ("and paseq follows it", 0x05C0, nehemiah_11_33_mapm.code (nbsp + 1).to_integer_32)
			from w := 60 until w > 400 loop
				lay := kit.layout_styled (nehemiah_11_33_mapm, w, 22, {SW_PAINTER}.Role_body, False)
				assert_false ("no tofu at " + w.out, has_missing_glyph (lay))
				assert_true ("no break around the no-break space at " + w.out,
					same_line (lay, nbsp - 1, nbsp) and same_line (lay, nbsp, nbsp + 1))
				w := w + 20
			end
		end

feature -- GW-11: status-bar sections carry Hebrew and Greek in both themes

	test_gw11_status_sections_hebrew_greek_light
		do
			status_gate (create {SW_THEME}.make_light, "gw11_status_light.png")
		end

	test_gw11_status_sections_hebrew_greek_dark
		do
			status_gate (create {SW_THEME}.make_dark, "gw11_status_dark.png")
		end

feature {NONE} -- GW-11 gate

	status_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- Three sections - pointed Genesis 1:1, polytonic John 1:1, a
			-- mixed English/Hebrew line - in the status bar's own role and
			-- size: no tofu, and each section inks at least 40 pixels at
			-- 3:1 or better against the bar's surface. Evidence written.
		local
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			bar: SW_STATUS_BAR
			l_texts: ARRAY [STRING_32]
			i, l_index: INTEGER
			path: STRING_32
		do
			kit := gw03_kit (a_theme)
			l_texts := <<genesis_1_1_wlc, john_1_1_wh_nfc.substring (1, 28), mixed_english_hebrew>>
			create surf.make (1600, 40)
			create ctx.make (surf)
			create p.make (ctx, a_theme)
			p.set_shaping (kit)
			create bar.make
			from i := l_texts.lower until i > l_texts.upper loop
				l_index := bar.add_text (l_texts [i], i = l_texts.upper)
				assert_false ("section " + i.out + " has no tofu",
					has_missing_glyph (kit.layout_styled (l_texts [i], 0, 13, {SW_PAINTER}.Role_mono, False)))
				i := i + 1
			end
			bar.set_bounds (0.0, 4.0, 1600.0, 32.0)
			bar.arrange (p)
			bar.draw (p)
			surf.flush.do_nothing
			from i := 1 until i > bar.sections.count loop
				assert_true ("section " + i.out + " reads at 3:1 or better",
					strong_ink (surf, a_theme, bar.section (i), a_theme.surface_variant) >= 40)
				i := i + 1
			end
			path := evidence_path (a_evidence)
			if not path.is_empty and then surf.write_png (path) then
			end
		end

	strong_ink (a_surface: CAIRO_SURFACE; a_theme: SW_THEME; a_section: SW_STATUS_SECTION; a_ground: NATURAL_32): INTEGER
			-- Pixels inside the section's span reading at 3:1 or better
			-- against `a_ground'.
		local
			px, py: INTEGER
			l_pixel: NATURAL_32
		do
			from py := 6 until py >= 34 loop
				from px := a_section.left.truncated_to_integer until px >= (a_section.left + a_section.span).truncated_to_integer.min (a_surface.width - 1) loop
					l_pixel := pixel_at (a_surface, px, py).bit_and (0xFFFFFF)
					if a_theme.contrast_ratio (l_pixel, a_ground) >= 3.0 then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
		end

	mixed_english_hebrew: STRING_32
			-- "Genesis 1:1 begins " + its first Hebrew word, pointed.
		do
			Result := {STRING_32} "Genesis 1:1 begins " + genesis_1_1_wlc.substring (1, genesis_1_1_wlc.index_of (' ', 1) - 1)
		end

feature {NONE} -- GW-03 gates

	gw03_kit (a_theme: SW_THEME): SW_SHAPING
			-- A kit with the app's reading faces loaded privately and put
			-- first: Noto Serif Hebrew for Hebrew, Noto Serif for Greek and
			-- for the body role.
		local
			l_names: ARRAY [STRING]
			i: INTEGER
		do
			create Result.make_with_assets (shaping_assets)
			l_names := <<"NotoSerifHebrew-Regular.ttf", "NotoSerifHebrew-Medium.ttf", "NotoSerif-Regular.ttf", "NotoSerif-Medium.ttf">>
			from i := l_names.lower until i > l_names.upper loop
				assert_true (l_names [i] + " loads", Result.facade.load_font_file (widgets_font_fixture (l_names [i])) >= 1)
				i := i + 1
			end
			a_theme.set_families (a_theme.family_ui, {STRING_32} "Noto Serif", a_theme.family_mono)
			Result.set_theme_faces (a_theme)
			Result.set_script_face ({SHAPING_CONSTANTS}.Script_class_hebrew, {STRING_32} "Noto Serif Hebrew")
			Result.set_script_face ({SHAPING_CONSTANTS}.Script_class_greek, {STRING_32} "Noto Serif")
				-- below 18 px the true Medium design keeps the points crisp
			Result.set_small_script_face ({SHAPING_CONSTANTS}.Script_class_hebrew, {STRING_32} "Noto Serif Hebrew Medium", 18)
		end

	marks_visible_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- At 14 px, the smallest reading size: the pointed verse puts
			-- clearly more ink below its baseline than the bare consonants
			-- do, and at least a quarter of that mark ink reaches 3:1 against
			-- the surface (WCAG's floor for non-text marks). Then a specimen
			-- at all five sizes is written as evidence.
		local
			kit: SW_SHAPING
			pointed_ink, bare_ink, strong: INTEGER
			path: STRING_32
		do
			kit := gw03_kit (a_theme)
			pointed_ink := ink_below_baseline (kit, a_theme, genesis_1_1_wlc, 14, False)
			bare_ink := ink_below_baseline (kit, a_theme, consonants_only (genesis_1_1_wlc), 14, False)
			assert_true ("the points ink below the line", pointed_ink > (bare_ink * 3) // 2 + 20)
			strong := ink_below_baseline (kit, a_theme, genesis_1_1_wlc, 14, True)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				write_specimen (kit, a_theme, path)
			end
			assert_true ("a quarter of the mark ink reads at 3:1 or better", strong * 4 >= pointed_ink)
			path := evidence_path (a_evidence)
			if not path.is_empty then
				write_specimen (kit, a_theme, path)
			end
		end

	ink_below_baseline (a_kit: SW_SHAPING; a_theme: SW_THEME; a_text: STRING_32; a_px: INTEGER; a_strong_only: BOOLEAN): INTEGER
			-- Pixels below the baseline (from 2 px under it to half the
			-- size) unlike the surface - or, with `a_strong_only', at 3:1 or
			-- more against it.
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			px_x, px_y, baseline: INTEGER
			l_pixel: NATURAL_32
		do
			create surf.make (800, 80)
			create ctx.make (surf)
			create p.make (ctx, a_theme)
			p.set_shaping (a_kit)
			p.set_color (a_theme.surface)
			p.fill_rect (0.0, 0.0, 800.0, 80.0)
			p.font ({SW_PAINTER}.Role_body, a_px / a_theme.text_scale, False)
			p.set_color (a_theme.ink)
			baseline := 40
			p.text (10.0, baseline.to_double, a_text)
			surf.flush.do_nothing
			from px_y := baseline + 2 until px_y > baseline + a_px // 2 + 2 loop
				from px_x := 0 until px_x >= 800 loop
					l_pixel := pixel_at (surf, px_x, px_y).bit_and (0xFFFFFF)
					if l_pixel /= a_theme.surface.bit_and (0xFFFFFF) then
						if not a_strong_only or else a_theme.contrast_ratio (l_pixel, a_theme.surface) >= 3.0 then
							Result := Result + 1
						end
					end
					px_x := px_x + 1
				end
				px_y := px_y + 1
			end
		end

	write_specimen (a_kit: SW_SHAPING; a_theme: SW_THEME; a_path: STRING_32)
			-- Genesis 1:1 and John 1:1 at 14, 18, 24, 32 and 40 px.
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			sizes: ARRAY [INTEGER]
			i: INTEGER
			y: REAL_64
		do
			create surf.make (1400, 560)
			create ctx.make (surf)
			create p.make (ctx, a_theme)
			p.set_shaping (a_kit)
			p.set_color (a_theme.surface)
			p.fill_rect (0.0, 0.0, 1400.0, 560.0)
			sizes := <<14, 18, 24, 32, 40>>
			y := 10.0
			from i := sizes.lower until i > sizes.upper loop
				y := y + sizes [i] * 1.6
				p.font ({SW_PAINTER}.Role_ui, 11.0, False)
				p.set_color (a_theme.ink_muted)
				p.text (8.0, y, sizes [i].out + " px")
				p.font ({SW_PAINTER}.Role_body, sizes [i] / a_theme.text_scale, False)
				p.set_color (a_theme.ink)
				p.text (60.0, y, genesis_1_1_wlc)
				p.text (60.0 + sizes [i] * 21.0, y, john_1_1_wh_nfc.substring (1, 28))
				i := i + 1
			end
			surf.flush.do_nothing
			if surf.write_png (a_path) then
			end
		end

	letters_in_family (a_layout: SHAPED_LAYOUT; a_low, a_high: INTEGER; a_family: STRING): BOOLEAN
			-- Is every glyph run holding a letter in [`a_low', `a_high']
			-- realized in `a_family', and is there at least one?
		local
			c, l_found: INTEGER
			l_has: BOOLEAN
		do
			Result := True
			across a_layout.lines as l loop
				across l.runs as r loop
					if attached {GLYPH_RUN} r as al_run then
						l_has := False
						from c := al_run.source_start until c > al_run.source_start + al_run.source_count - 1 loop
							if a_layout.source_text.code (c).to_integer_32 >= a_low
								and a_layout.source_text.code (c).to_integer_32 <= a_high
							then
								l_has := True
							end
							c := c + 1
						end
						if l_has then
							l_found := l_found + 1
							if not al_run.font.realized_family.as_string_32.is_case_insensitive_equal (a_family) then
								Result := False
							end
						end
					end
				end
			end
			Result := Result and l_found > 0
		end

	same_line (a_layout: SHAPED_LAYOUT; a_one, a_other: INTEGER): BOOLEAN
			-- Do source characters `a_one' and `a_other' sit on one line?
		do
			across a_layout.lines as l loop
				if a_one >= l.source_start and a_one < l.source_start + l.source_count
					and a_other >= l.source_start and a_other < l.source_start + l.source_count
				then
					Result := True
				end
			end
		end

	consonants_only (a_text: STRING_32): STRING_32
			-- `a_text' without points and cantillation (U+0591-U+05C7),
			-- keeping maqaf, paseq, sof pasuq and nun hafukha, which are
			-- spacing characters.
		local
			i, c: INTEGER
		do
			create Result.make (a_text.count)
			from i := 1 until i > a_text.count loop
				c := a_text.code (i).to_integer_32
				if c < 0x0591 or c > 0x05C7 or c = 0x05BE or c = 0x05C0 or c = 0x05C3 or c = 0x05C6 then
					Result.append_code (c.to_natural_32)
				end
				i := i + 1
			end
		end

	widgets_font_fixture (a_name: STRING): STRING_32
			-- simple_widgets' own OFL font fixture `a_name', under
			-- $SIMPLE_EIFFEL.
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.item ("SIMPLE_EIFFEL") as al_root then
				Result := al_root.to_string_32 + {STRING_32} "/simple_widgets/testing/fixtures/fonts/" + a_name.to_string_32
			else
				Result := a_name.to_string_32
			end
		end

	john_1_1_wh_nfc: STRING_32
			-- John 1:1 (WH) in NFC: precomposed polytonic letters.
		do
			Result := text_of (<<0x1F18, 0x03BD, 0x0020, 0x1F00, 0x03C1, 0x03C7, 0x1FC7, 0x0020, 0x1F26, 0x03BD, 0x0020, 0x1F41,
				0x0020, 0x03BB, 0x03CC, 0x03B3, 0x03BF, 0x03C2, 0x002C, 0x0020, 0x03BA, 0x03B1, 0x1F76, 0x0020,
				0x1F41, 0x0020, 0x03BB, 0x03CC, 0x03B3, 0x03BF, 0x03C2, 0x0020, 0x1F26, 0x03BD, 0x0020, 0x03C0,
				0x03C1, 0x1F78, 0x03C2, 0x0020, 0x03C4, 0x1F78, 0x03BD, 0x0020, 0x03B8, 0x03B5, 0x03CC, 0x03BD,
				0x002C, 0x0020, 0x03BA, 0x03B1, 0x1F76, 0x0020, 0x03B8, 0x03B5, 0x1F78, 0x03C2, 0x0020, 0x1F26,
				0x03BD, 0x0020, 0x1F41, 0x0020, 0x03BB, 0x03CC, 0x03B3, 0x03BF, 0x03C2, 0x002E>>)
		ensure
			seventy: Result.count = 70
		end

	nehemiah_11_33_mapm: STRING_32
			-- Nehemiah 11:33, MapM (bible.db), with its no-break space
			-- before paseq, cantillation and meteg.
		do
			Result := text_of (<<0x05D7, 0x05B8, 0x05E6, 0x05A5, 0x05D5, 0x05B9, 0x05E8, 0x00A0, 0x05C0, 0x0020, 0x05E8, 0x05B8,
				0x05DE, 0x05B8, 0x0596, 0x05D4, 0x0020, 0x05D2, 0x05BC, 0x05B4, 0x05EA, 0x05BC, 0x05B8, 0x05BD,
				0x05D9, 0x05B4, 0x05DD, 0x05C3>>)
		ensure
			twenty_eight: Result.count = 28
		end

feature {NONE} -- GW-02 gates

	text_box_flush_right_gate (a_theme: SW_THEME)
			-- Draw pointed Genesis 1:1 in a 700-wide text box set to
			-- Align_start; the right half must hold most of the ink.
		local
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			tb: SW_TEXT_BOX
			left_ink, right_ink: INTEGER
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			create surf.make (720, 120)
			create ctx.make (surf)
			create p.make (ctx, a_theme)
			p.set_shaping (kit)
			p.set_color (a_theme.surface)
			p.fill_rect (0.0, 0.0, 720.0, 120.0)
			create tb.make (genesis_1_1_wlc)
			tb.set_text_alignment ({SHAPING_CONSTANTS}.Align_start)
			tb.set_bounds (10.0, 10.0, 700.0, 100.0)
			tb.arrange (p)
			tb.draw (p)
			surf.flush.do_nothing
			left_ink := pixels_unlike (surf, a_theme.surface, 20, 20, 360, 100)
			right_ink := pixels_unlike (surf, a_theme.surface, 360, 20, 700, 100)
			assert_true ("the right half carries the Hebrew", right_ink > 2 * left_ink)
		end

	paragraph_list_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- Three verses - Genesis 1:1 in Hebrew, John 1:1 in Greek, John
			-- 1:1 in English - with Align_start and the gutter on the reading
			-- side: the Hebrew gutter sits right of the others, its text
			-- starts left of theirs, and every gutter draws.
		local
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			pl: SW_PARAGRAPH_LIST
			path: STRING_32
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			create surf.make (900, 330)
			create ctx.make (surf)
			create p.make (ctx, a_theme)
			p.set_shaping (kit)
			p.set_color (a_theme.background)
			p.fill_rect (0.0, 0.0, 900.0, 330.0)
			create pl.make (310.0)
			pl.add (genesis_1_1_wlc)
			pl.add (john_1_1_wh)
			pl.add ("In the beginning was the Word, and the Word was with God, and the Word was God.")
			pl.set_gutter_width (40.0)
			pl.set_text_alignment ({SHAPING_CONSTANTS}.Align_start)
			pl.set_gutter_on_reading_side (True)
			create gutter_xs.make_filled (-1.0, 1, 3)
			pl.set_gutter_renderer (agent record_gutter)
			pl.set_bounds (10.0, 10.0, 880.0, 310.0)
			pl.arrange (p)
			pl.draw (p)
			surf.flush.do_nothing
			assert_true ("every gutter drew", gutter_xs [1] >= 0.0 and gutter_xs [2] >= 0.0 and gutter_xs [3] >= 0.0)
			assert_true ("the Hebrew gutter is on the right", gutter_xs [1] > gutter_xs [2] + 400.0)
			assert_reals_equal ("Greek and English keep the left gutter", gutter_xs [2], gutter_xs [3], 0.001)
			assert_true ("the Hebrew text starts left of the others", pl.item_text_x (1) < pl.item_text_x (3))
			path := evidence_path (a_evidence)
			if not path.is_empty then
				if surf.write_png (path) then
				end
			end
		end

	gutter_xs: ARRAY [REAL_64]
			-- Where each paragraph's gutter was drawn.
		attribute
			create Result.make_filled (-1.0, 1, 3)
		end

	record_gutter (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
			-- Draw paragraph `a_i''s verse number and note where it went.
		do
			if a_i >= gutter_xs.lower and a_i <= gutter_xs.upper then
				gutter_xs [a_i] := a_x
			end
			a_p.font ({SW_PAINTER}.Role_ui, 13.0, True)
			a_p.set_color (a_p.theme.accent)
			a_p.text (a_x + 8.0, a_y + 22.0, (a_i).out)
		end

feature {NONE} -- GW-04 gate

	painter_text_gate (a_theme: SW_THEME; a_evidence: STRING)
			-- Draw pointed Genesis 1:1 (WLC, cantillation) and polytonic
			-- John 1:1 (WH, combining marks) through plain `SW_PAINTER.text',
			-- on `a_theme''s surface in `a_theme''s ink, and require: both
			-- shaped (runs painted, none skipped), no missing glyph (tofu),
			-- Hebrew laid right to left, ink on the page in both lines, and
			-- some pixels at full ink colour (the text is drawn in the theme's
			-- ink, not washed out). Writes an evidence PNG when the repository
			-- is underfoot.
		local
			kit: SW_SHAPING
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			hebrew, greek: SHAPED_LAYOUT
			painted, skipped: INTEGER
			path: STRING_32
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_theme)
			create surf.make (900, 170)
			create ctx.make (surf)
			create p.make (ctx, a_theme)
			p.set_color (a_theme.surface)
			p.fill_rect (0.0, 0.0, 900.0, 170.0)
			p.set_shaping (kit)
			p.font ({SW_PAINTER}.Role_body, 30.0, False)
			p.set_color (a_theme.ink)
			painted := kit.bridge.painted_runs
			skipped := kit.bridge.skipped_runs
			p.text (20.0, 62.0, genesis_1_1_wlc)
			p.text (20.0, 140.0, john_1_1_wh)
			surf.flush.do_nothing

			assert_true ("runs were painted", kit.bridge.painted_runs > painted)
			assert_integers_equal ("no run was skipped", skipped, kit.bridge.skipped_runs)
			hebrew := kit.layout_styled (genesis_1_1_wlc, 0, p.font_pixel_size, {SW_PAINTER}.Role_body, False)
			greek := kit.layout_styled (john_1_1_wh, 0, p.font_pixel_size, {SW_PAINTER}.Role_body, False)
			assert_false ("no Hebrew tofu", has_missing_glyph (hebrew))
			assert_false ("no Greek tofu", has_missing_glyph (greek))
			assert_integers_equal ("Hebrew is a right-to-left paragraph",
				{SHAPING_CONSTANTS}.Direction_rtl, hebrew.base_direction)
			assert_true ("Hebrew line carries ink", pixels_unlike (surf, a_theme.surface, 0, 0, 900, 85) > 1500)
			assert_true ("Greek line carries ink", pixels_unlike (surf, a_theme.surface, 0, 85, 900, 170) > 1500)
			assert_true ("text reaches full ink colour", pixels_near (surf, a_theme.ink, 0, 0, 900, 170) > 100)

			path := evidence_path (a_evidence)
			if not path.is_empty then
				if surf.write_png (path) then
				end
			end
		end

	has_missing_glyph (a_layout: SHAPED_LAYOUT): BOOLEAN
			-- Does any glyph run of `a_layout' use glyph 0 (.notdef, tofu)?
		local
			i: INTEGER
		do
			across a_layout.lines as l loop
				across l.runs as r loop
					if attached {GLYPH_RUN} r as al_run then
						from i := al_run.glyph_ids.lower until i > al_run.glyph_ids.upper loop
							if al_run.glyph_ids [i] = 0 then
								Result := True
							end
							i := i + 1
						end
					end
				end
			end
		end

	pixels_unlike (a_surface: CAIRO_SURFACE; a_ground: NATURAL_32; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Pixels in the box whose colour is not `a_ground'.
		local
			px, py: INTEGER
		do
			from py := a_y0.max (0) until py >= a_y1.min (a_surface.height) loop
				from px := a_x0.max (0) until px >= a_x1.min (a_surface.width) loop
					if pixel_at (a_surface, px, py).bit_and (0xFFFFFF) /= a_ground.bit_and (0xFFFFFF) then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
		end

	pixels_near (a_surface: CAIRO_SURFACE; a_colour: NATURAL_32; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Pixels in the box within 24 of `a_colour' on every channel.
		local
			px, py: INTEGER
			l_pixel: NATURAL_32
		do
			from py := a_y0.max (0) until py >= a_y1.min (a_surface.height) loop
				from px := a_x0.max (0) until px >= a_x1.min (a_surface.width) loop
					l_pixel := pixel_at (a_surface, px, py)
					if channel_near (l_pixel, a_colour, 16) and channel_near (l_pixel, a_colour, 8)
						and channel_near (l_pixel, a_colour, 0)
					then
						Result := Result + 1
					end
					px := px + 1
				end
				py := py + 1
			end
		end

	channel_near (a_one, a_other: NATURAL_32; a_shift: INTEGER): BOOLEAN
			-- Are the channels at `a_shift' within 24 of each other?
		do
			Result := ((a_one |>> a_shift).bit_and (0xFF).to_integer_32
				- (a_other |>> a_shift).bit_and (0xFF).to_integer_32).abs <= 24
		end

	genesis_1_1_wlc: STRING_32
			-- Genesis 1:1, Westminster Leningrad Codex, pointed, with
			-- cantillation (bible.db), as code points.
		do
			Result := text_of (<<0x05D1, 0x05B0, 0x05BC, 0x05E8, 0x05B5, 0x05D0, 0x05E9, 0x05B4, 0x05C1, 0x0596, 0x05D9, 0x05EA,
				0x0020, 0x05D1, 0x05B8, 0x05BC, 0x05E8, 0x05B8, 0x05A3, 0x05D0, 0x0020, 0x05D0, 0x05B1, 0x05DC,
				0x05B9, 0x05D4, 0x05B4, 0x0591, 0x05D9, 0x05DD, 0x0020, 0x05D0, 0x05B5, 0x05A5, 0x05EA, 0x0020,
				0x05D4, 0x05B7, 0x05E9, 0x05B8, 0x05BC, 0x05C1, 0x05DE, 0x05B7, 0x0596, 0x05D9, 0x05B4, 0x05DD,
				0x0020, 0x05D5, 0x05B0, 0x05D0, 0x05B5, 0x05A5, 0x05EA, 0x0020, 0x05D4, 0x05B8, 0x05D0, 0x05B8,
				0x05BD, 0x05E8, 0x05B6, 0x05E5, 0x05C3>>)
		ensure
			sixty_five: Result.count = 65
		end

	john_1_1_wh: STRING_32
			-- John 1:1, Westcott-Hort 1881 (bible.db), polytonic with
			-- combining marks, as code points.
		do
			Result := text_of (<<0x0395, 0x0313, 0x03BD, 0x0020, 0x03B1, 0x0313, 0x03C1, 0x03C7, 0x03B7, 0x0342, 0x0345, 0x0020,
				0x03B7, 0x0313, 0x0342, 0x03BD, 0x0020, 0x03BF, 0x0314, 0x0020, 0x03BB, 0x03BF, 0x0301, 0x03B3,
				0x03BF, 0x03C2, 0x002C, 0x0020, 0x03BA, 0x03B1, 0x03B9, 0x0300, 0x0020, 0x03BF, 0x0314, 0x0020,
				0x03BB, 0x03BF, 0x0301, 0x03B3, 0x03BF, 0x03C2, 0x0020, 0x03B7, 0x0313, 0x0342, 0x03BD, 0x0020,
				0x03C0, 0x03C1, 0x03BF, 0x0300, 0x03C2, 0x0020, 0x03C4, 0x03BF, 0x0300, 0x03BD, 0x0020, 0x03B8,
				0x03B5, 0x03BF, 0x0301, 0x03BD, 0x002C, 0x0020, 0x03BA, 0x03B1, 0x03B9, 0x0300, 0x0020, 0x03B8,
				0x03B5, 0x03BF, 0x0300, 0x03C2, 0x0020, 0x03B7, 0x0313, 0x0342, 0x03BD, 0x0020, 0x03BF, 0x0314,
				0x0020, 0x03BB, 0x03BF, 0x0301, 0x03B3, 0x03BF, 0x03C2, 0x002E>>)
		ensure
			ninety_two: Result.count = 92
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
