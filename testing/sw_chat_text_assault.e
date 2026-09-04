note
	description: "[
		THE SQUARE BOXES, and the selection that was never there.
		Offscreen only: every SW_WINDOW here is built with `make' and
		driven with `request_render' / `write_frame'. `run' - which
		alone creates a native HWND - is never called, so `hwnd' stays
		`default_pointer' and no window, visible or hidden, ever exists.

		THE REPORT. Larry, reading a numbered list from the assistant in
		the chat client: square boxes where the line breaks should be.
		SW_CHAT_THREAD wrapped by splitting on the SPACE CHARACTER ALONE,
		so a newline was never a break - it was a character, and cairo
		drew it as .notdef. On the shaped path simple_shaping counts LF
		among the characters a line MAY break at
		(`is_breaking_space_code'), so the wrap happened near the break
		but the LF was still shaped and still painted.

		WHAT IS PROVEN HERE. (1) `paragraphs_of' cuts at LF, at CRLF as
		ONE break, and at a lone CR; turns tabs into spaces; collapses a
		RUN of blank lines to one; drops trailing blanks. (2) A
		three-line message really occupies three lines and a numbered
		list stays a list, on BOTH paths. (3) The bubble's height follows
		the real line count. (4) A Hebrew line followed by a Greek line
		is TWO shaped layouts with the break between them, not one
		paragraph with a box in the middle. (5) The selection: which
		characters a drag rectangle covers, and what `selected_text' -
		the exact payload `copy_selection' hands SW_CLIPBOARD - then is.

		THE CLIPBOARD IS NEVER TOUCHED. `copy_selection' writes to the
		SYSTEM clipboard; Larry is at this machine, and a test suite has
		no business overwriting what he has copied. So the tests assert
		on `selected_text' - which IS the payload, by construction - and
		never call `copy_selection'.
	]"
	author: "Larry Rix"

class
	SW_CHAT_TEXT_ASSAULT

inherit
	TEST_SET_BASE

feature -- Paragraphs: the cut that was missing

	test_paragraphs_split_at_every_explicit_break
		local
			c: SW_CHAT_THREAD
			ps: ARRAYED_LIST [STRING_32]
		do
			create c.make

			ps := c.paragraphs_of ({STRING_32} "one%Ntwo%Nthree")
			assert_integers_equal ("an LF ends a line: three paragraphs", 3, ps.count)
			assert_strings_equal_diff ("first", {STRING_32} "one", ps.i_th (1))
			assert_strings_equal_diff ("third", {STRING_32} "three", ps.i_th (3))

			ps := c.paragraphs_of ({STRING_32} "one%R%Ntwo")
			assert_integers_equal ("CRLF is ONE break, not two", 2, ps.count)
			assert_strings_equal_diff ("and the CR is gone", {STRING_32} "one", ps.i_th (1))

			ps := c.paragraphs_of ({STRING_32} "one%Rtwo")
			assert_integers_equal ("a lone CR breaks too", 2, ps.count)
			assert_strings_equal_diff ("...and is never drawn", {STRING_32} "two", ps.i_th (2))

			ps := c.paragraphs_of ({STRING_32} "a%Tb")
			assert_integers_equal ("a tab is not a break", 1, ps.count)
			assert_strings_equal_diff ("a tab is a space", {STRING_32} "a b", ps.i_th (1))
		end

	test_blank_runs_are_bounded_and_trailing_blanks_dropped
		local
			c: SW_CHAT_THREAD
			ps: ARRAYED_LIST [STRING_32]
		do
			create c.make

			ps := c.paragraphs_of ({STRING_32} "a%N%Nb")
			assert_integers_equal ("one blank line survives", 3, ps.count)
			assert_string_empty ("...and it is blank", ps.i_th (2))

			ps := c.paragraphs_of ({STRING_32} "a%N%N%N%N%Nb")
			assert_integers_equal ("five breaks still yield ONE blank line", 3, ps.count)

			ps := c.paragraphs_of ({STRING_32} "a%N")
			assert_integers_equal ("a trailing newline is not a trailing empty line", 1, ps.count)

			ps := c.paragraphs_of ({STRING_32} "")
			assert_integers_equal ("the empty message is one empty paragraph", 1, ps.count)
			assert_string_empty ("...and it is empty", ps.i_th (1))
		end

	test_no_break_character_survives_into_a_drawn_line
			-- The box, named: not one line the toy path draws may contain
			-- an LF, a CR or a tab.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			lines: ARRAYED_LIST [STRING_32]
			bad: INTEGER
		do
			create th.make_light
			create surf.make (400, 300)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			p.font ({SW_PAINTER}.Role_ui, 13.0, False)

			lines := c.wrapped (p, {STRING_32} "1. first%R%N2. second%N%N3. third%Tafter a tab", 260.0)
			across
				lines as l
			loop
				if l.has ('%N') or l.has ('%R') or l.has ('%T') then
					bad := bad + 1
				end
			end
			assert_integers_equal ("no drawn line carries a break character", 0, bad)
			assert_integers_equal ("three items and one blank line between two of them",
				4, lines.count)
			assert_strings_equal_diff ("the numbering survived", {STRING_32} "1. first", lines.i_th (1))
			assert_string_empty ("the blank line is blank", lines.i_th (3))

			ctx.destroy
			surf.destroy
		end

feature -- The toy path: three lines are three lines

	test_three_line_message_occupies_three_lines
		local
			c, c1: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			three_h, one_h: REAL_64
		do
			create th.make_light
			create surf.make (400, 900)
			create ctx.make (surf)
			create p.make (ctx, th)

			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 900.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "alpha%Nbeta%Ngamma")
			c.draw (p)
			three_h := c.content_h

			create c1.make
			c1.set_bounds (0.0, 0.0, 400.0, 900.0)
			c1.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "alpha")
			c1.draw (p)
			one_h := c1.content_h

			print ("    toy: one line " + one_h.out + ", three lines " + three_h.out + "%N")
			assert_reals_equal ("three lines cost exactly two more Line_h than one",
				2.0 * {SW_CHAT_THREAD}.Line_h, three_h - one_h, 0.01)

			ctx.destroy
			surf.destroy
		end

	test_a_numbered_list_stays_a_list
			-- The workaround the chat client is carrying today - collapse
			-- newlines to spaces - turns this into one paragraph. It must
			-- not have to.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			d: STRING_32
		do
			create th.make_light
			create surf.make (600, 600)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 600.0, 600.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs,
				{STRING_32} "Here are three:%N1. the first%N2. the second%N3. the third")
			c.draw (p)

			d := c.display_text (1)
			assert_integers_equal ("four lines of display text",
				3, occurrences (d, '%N'))
			assert_string_contains ("item 2 is still its own line", d, {STRING_32} "%N2. the second")

			ctx.destroy
			surf.destroy
		end

feature -- The shaped path: one layout per paragraph

	test_shaped_message_gets_one_layout_per_paragraph
		local
			c: SW_CHAT_THREAD
			kit: SW_SHAPING
			p: SW_PAINTER
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			assets: STRING_32
		do
			assets := shaping_assets
			if not assets.is_empty then
				create kit.make_with_assets (assets)
				create th.make_dark
				kit.set_theme_faces (th)
				create surf.make (500, 500)
				create ctx.make (surf)
				create p.make (ctx, th)
				p.set_shaping (kit)

				create c.make
				c.set_bounds (0.0, 0.0, 500.0, 500.0)
				c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "one%Ntwo%Nthree")
				c.add_message ({SW_CHAT_THREAD}.Role_mine, {STRING_32} "no breaks here at all")
				c.draw (p)

				assert_integers_equal ("two messages, two spans", 2, c.layout_spans.count)
				assert_integers_equal ("the three-line message is THREE layouts",
					3, c.layout_spans.i_th (1).span)
				assert_integers_equal ("the plain one is still ONE",
					1, c.layout_spans.i_th (2).span)
				assert_integers_equal ("four paragraph layouts in all",
					4, c.shaped_layouts.count)
				assert_strings_equal_diff ("and no layout carries a break character",
					{STRING_32} "two", c.shaped_layouts.i_th (2).source_text.to_string_32)
				print ("    shaped: " + c.shaped_layouts.count.out + " layouts for "
					+ c.count.out + " messages, content_h " + c.content_h.out + "%N")

				kit.dispose_surfaces
				ctx.destroy
				surf.destroy
			else
				print ("    (no Noto assets underfoot - shaped paragraph test skipped)%N")
			end
		end

	test_a_message_may_arrive_after_a_shaped_frame
			-- THE LIVE-CLIENT CASE, and the reason simple_chat could not
			-- adopt 0.6.0 in a workbench build. A chat client paints a
			-- frame, a reply arrives, it paints again. Between those two
			-- frames `layout_spans' still describes the messages of the
			-- LAST frame - and the invariant used to demand
			-- `layout_spans.count = messages.count' the moment
			-- `shaped_layouts' was non-empty, so `add_message' itself
			-- failed ON EXIT. Finalized code checks no invariant, which
			-- is the only reason it never bit the shipped client.
			--
			-- The counts CANNOT be equal here: a span indexes layouts
			-- that only `SW_SHAPING.layout_for' can make, and it needs an
			-- inner width and a pixel size the widget does not learn
			-- until the painter hands them over at draw time. So the
			-- equality was never a property of the class; it is a
			-- property of a laid-out frame, and it is now stated where it
			-- becomes true - `refresh_layouts''s postcondition - and
			-- guarded in the invariant by `laid_out_revision = revision',
			-- the flag that says whether the layouts are current at all.
		local
			c: SW_CHAT_THREAD
			kit: SW_SHAPING
			p: SW_PAINTER
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			assets: STRING_32
		do
			assets := shaping_assets
			if not assets.is_empty then
				create kit.make_with_assets (assets)
				create th.make_dark
				kit.set_theme_faces (th)
				create surf.make (500, 500)
				create ctx.make (surf)
				create p.make (ctx, th)
				p.set_shaping (kit)

				create c.make
				c.set_bounds (0.0, 0.0, 500.0, 500.0)
				c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "one%Ntwo")
				c.draw (p)
				assert_false ("a shaped frame really was drawn", c.shaped_layouts.is_empty)
				assert_integers_equal ("...and the spans describe it", 1, c.layout_spans.count)
				assert_integers_equal ("...at the revision it was drawn for",
					c.revision, c.laid_out_revision)

					-- THE ASSAULT: the reply arrives. THIS is the call
					-- that used to raise on exit.
				c.add_message ({SW_CHAT_THREAD}.Role_mine, {STRING_32} "and a reply")
				assert_integers_equal ("the message is aboard", 2, c.count)
				assert_integers_equal ("...while the spans still describe the frame drawn",
					1, c.layout_spans.count)
				assert_true ("...which the revision counter says out loud",
					c.laid_out_revision /= c.revision)

					-- streaming does the same thing, over and over
				c.append_to_last ({STRING_32} " - continued")
				assert_integers_equal ("a streamed token leaves the spans alone",
					1, c.layout_spans.count)

					-- and the next frame catches up, on its own
				c.draw (p)
				assert_integers_equal ("the next frame lays out both messages",
					2, c.layout_spans.count)
				assert_integers_equal ("...and the revision is current again",
					c.revision, c.laid_out_revision)
				assert_integers_equal ("...with a layout per paragraph, in message order",
					c.layout_spans.i_th (2).base + c.layout_spans.i_th (2).span - 1,
					c.shaped_layouts.count)
				print ("    live client: " + c.count.out + " messages, "
					+ c.shaped_layouts.count.out + " layouts, revision "
					+ c.revision.out + "%N")

				kit.dispose_surfaces
				ctx.destroy
				surf.destroy
			else
				print ("    (no Noto assets underfoot - live-client test skipped)%N")
			end
		end

	test_hebrew_line_then_greek_line
			-- Larry's own mixed-script case, with the break between them:
			-- two paragraphs, two layouts, two BASE DIRECTIONS - which is
			-- exactly what a single layout with an LF inside it could
			-- never give.
		local
			c: SW_CHAT_THREAD
			kit: SW_SHAPING
			p: SW_PAINTER
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			assets: STRING_32
		do
			assets := shaping_assets
			if not assets.is_empty then
				create kit.make_with_assets (assets)
				create th.make_dark
				kit.set_theme_faces (th)
				create surf.make (500, 400)
				create ctx.make (surf)
				create p.make (ctx, th)
				p.set_shaping (kit)

				create c.make
				c.set_bounds (0.0, 0.0, 500.0, 400.0)
				c.add_message ({SW_CHAT_THREAD}.Role_theirs, two_script_lines)
				c.draw (p)

				assert_integers_equal ("Hebrew line + Greek line = two layouts",
					2, c.layout_spans.i_th (1).span)
				assert_integers_equal ("the Hebrew paragraph reads right to left",
					{SHAPING_CONSTANTS}.Direction_rtl, c.shaped_layouts.i_th (1).base_direction)
				assert_integers_equal ("the Greek paragraph reads left to right",
					{SHAPING_CONSTANTS}.Direction_ltr, c.shaped_layouts.i_th (2).base_direction)
				print ("    hebrew/greek: heights "
					+ c.shaped_layouts.i_th (1).total_height.out + " / "
					+ c.shaped_layouts.i_th (2).total_height.out + "%N")

				kit.dispose_surfaces
				ctx.destroy
				surf.destroy
			else
				print ("    (no Noto assets underfoot - bidi paragraph test skipped)%N")
			end
		end

feature -- Selection: which characters a drag covers

	test_drag_selects_the_characters_it_crosses
			-- The layout math, driven through the widget's own public
			-- mouse handlers at coordinates measured from the SAME
			-- painter the bubble drew with.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			msg: STRING_32
			ix, iy, x6: REAL_64
			consumed: BOOLEAN
		do
			create th.make_light
			create surf.make (500, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 500.0, 400.0)
			msg := {STRING_32} "Selectable at last."
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, msg)
			c.draw (p)
			assert_false ("nothing is selected before a press", c.has_selection)

				-- a `theirs' bubble sits at x + 10, y + 8; its text starts
				-- one Bubble_pad inside that
			ix := 10.0 + {SW_CHAT_THREAD}.Bubble_pad
			iy := 8.0 + {SW_CHAT_THREAD}.Bubble_pad + {SW_CHAT_THREAD}.Line_h / 2.0
			p.font ({SW_PAINTER}.Role_ui, {SW_CHAT_THREAD}.Text_size, False)
			x6 := p.advance (msg.substring (1, 6))

			consumed := c.handle_click (ix + 0.1, iy)
			assert_true ("a press inside a bubble is consumed - the pane needs the capture",
				consumed)
			assert_integers_equal ("the press landed in message 1", 1, c.sel_message)
			assert_integers_equal ("...at the very start", 0, c.sel_anchor)

			c.handle_drag (ix + x6, iy)
			assert_true ("the drag made a selection", c.has_selection)
			assert_strings_equal_diff ("the drag covers exactly the characters it crossed",
				msg.substring (1, 6), c.selected_text)
			print ("    drag: [" + c.sel_low.out + ", " + c.sel_high.out + "] = %""
				+ c.selected_text.to_string_8 + "%"%N")

			c.handle_release (0, 0)
			assert_false ("release ends the drag", c.is_selecting)
			assert_true ("...but keeps the selection", c.has_selection)

			c.handle_char (27)
			assert_false ("Escape clears it", c.has_selection)

			ctx.destroy
			surf.destroy
		end

	test_double_click_takes_the_word
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			msg: STRING_32
			ix, iy: REAL_64
			took: BOOLEAN
		do
			create th.make_light
			create surf.make (500, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 500.0, 400.0)
			msg := {STRING_32} "alpha beta gamma"
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, msg)
			c.draw (p)

			ix := 10.0 + {SW_CHAT_THREAD}.Bubble_pad
			iy := 8.0 + {SW_CHAT_THREAD}.Bubble_pad + {SW_CHAT_THREAD}.Line_h / 2.0
			p.font ({SW_PAINTER}.Role_ui, {SW_CHAT_THREAD}.Text_size, False)

			took := c.handle_double_click (ix + p.advance (msg.substring (1, 8)), iy)
			assert_true ("a double click inside a bubble is consumed", took)
			assert_strings_equal_diff ("...and takes the whole word under it",
				{STRING_32} "beta", c.selected_text)

			c.select_word_at (1, 0)
			assert_strings_equal_diff ("the first word, from the very start",
				{STRING_32} "alpha", c.selected_text)

			ctx.destroy
			surf.destroy
		end

	test_a_selection_never_leaves_its_bubble
			-- Cross-bubble selection is deliberately not supported: a drag
			-- that wanders into the next speaker's words runs to the
			-- anchor bubble's own end and stops there.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			ix, iy: REAL_64
			consumed: BOOLEAN
		do
			create th.make_light
			create surf.make (500, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 500.0, 400.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "first bubble")
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "second bubble")
			c.draw (p)

			ix := 10.0 + {SW_CHAT_THREAD}.Bubble_pad
			iy := 8.0 + {SW_CHAT_THREAD}.Bubble_pad + {SW_CHAT_THREAD}.Line_h / 2.0
			consumed := c.handle_click (ix + 0.1, iy)
			assert_true ("pressed in the first bubble", consumed and c.sel_message = 1)

				-- drag far down, well past the second bubble
			c.handle_drag (ix + 400.0, iy + 300.0)
			assert_integers_equal ("still the FIRST bubble's selection", 1, c.sel_message)
			assert_strings_equal_diff ("run to that bubble's own end, and no further",
				{STRING_32} "first bubble", c.selected_text)

			ctx.destroy
			surf.destroy
		end

	test_selection_offsets_run_over_the_displayed_text
			-- What is copied is what is shown: offsets index
			-- `display_text', so a multi-line message's selection can
			-- carry the break with it.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		do
			create th.make_light
			create surf.make (500, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 500.0, 400.0)
			c.add_message ({SW_CHAT_THREAD}.Role_mine, {STRING_32} "ab%R%Ncd")
			c.draw (p)

			assert_strings_equal_diff ("the CRLF shows as ONE LF",
				{STRING_32} "ab%Ncd", c.display_text (1))

			c.select_message (1)
			assert_strings_equal_diff ("the whole bubble, break and all",
				{STRING_32} "ab%Ncd", c.selected_text)

			c.select_range (1, 1, 4)
			assert_strings_equal_diff ("a range that straddles the break",
				{STRING_32} "b%Nc", c.selected_text)

			c.clear_selection
			assert_string_empty ("nothing selected, nothing to copy", c.selected_text)

			ctx.destroy
			surf.destroy
		end

	test_context_menu_offers_copy_only_when_there_is_something_to_copy
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			m: detachable SW_MENU
			ix, iy: REAL_64
		do
			create th.make_light
			create surf.make (500, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 500.0, 400.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "right click me")
			c.draw (p)

			ix := 10.0 + {SW_CHAT_THREAD}.Bubble_pad
			iy := 8.0 + {SW_CHAT_THREAD}.Bubble_pad + {SW_CHAT_THREAD}.Line_h / 2.0
			m := c.context_menu (ix + 2.0, iy)
			assert_attached ("the thread offers a menu now", m)
			if attached m as al_m then
				assert_strings_equal_diff ("Copy is the first item",
					{STRING_32} "Copy", al_m.items.i_th (1).label)
				assert_true ("...and it is live, because the right-click took a word",
					al_m.items.i_th (1).enabled)
				assert_strings_equal_diff ("the ampersand never reaches the drawn label",
					{STRING_32} "Select Message", al_m.items.i_th (2).label)
			end

			ctx.destroy
			surf.destroy
		end

feature -- Evidence (offscreen only - no window is ever shown)

	test_line_and_selection_evidence
		local
			room: TUPLE [window: SW_WINDOW; thread: SW_CHAT_THREAD]
			w: SW_WINDOW
			th: SW_CHAT_THREAD
			evidence: STRING_32
			wrote: BOOLEAN
		do
			room := build_room (2.0)
			w := room.window
			th := room.thread
			th.add_message ({SW_CHAT_THREAD}.Role_theirs,
				{STRING_32} "Three lines, and none of them a box:%Nline one%Nline two")
			th.add_message ({SW_CHAT_THREAD}.Role_mine,
				{STRING_32} "Here are three:%N1. the first%N2. the second%N3. the third")
			th.add_message ({SW_CHAT_THREAD}.Role_system, two_script_lines)
			w.request_render

			assert_integers_equal ("three messages in the room", 3, th.count)
			evidence := evidence_path ("thread-linebreaks-2x.png")
			if not evidence.is_empty then
				wrote := w.write_frame (evidence)
				print ("    written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end

				-- and now with a selection washed across the middle bubble
			th.select_range (2, 15, 30)
			w.request_render
			assert_true ("something is selected for the picture", th.has_selection)
			print ("    selected: %"" + th.selected_text.to_string_8 + "%"%N")
			evidence := evidence_path ("thread-selection-2x.png")
			if not evidence.is_empty then
				wrote := w.write_frame (evidence)
				print ("    written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end
		end

feature {NONE} -- Building the room (mirrors simple_chat/apps/client/sw_chat_view.e)

	build_room (a_scale: REAL_64): TUPLE [window: SW_WINDOW; thread: SW_CHAT_THREAD]
		require
			sane_scale: a_scale >= 0.5 and a_scale <= 3.0
		local
			th: SW_THEME
			w: SW_WINDOW
			c: SW_CHAT_THREAD
			title: SW_LABEL
			input: SW_TEXT_BOX
			root: SW_COLUMN
		do
			create th.make_dark
			th.set_text_scale (a_scale)
			create w.make ("lines-and-selection", 0, 0, 900, 700, th)
			w.enable_shaped_text
			create c.make
			c.set_grow (1.0)
			create title.make_ui ("Chat")
			create input.make_single_line ("")
			create root.make
			root.put (title)
			root.put (c)
			root.put (input)
			w.set_root (root)
			Result := [w, c]
		ensure
			shaped: attached Result.window.shaping
		end

	two_script_lines: STRING_32
			-- Hebrew shalom on one line, Greek Christos on the next - as
			-- CODE POINTS, so a source literal never puts this file's own
			-- encoding on trial instead of the line-break math.
		do
			Result := text_of (<<0x05E9, 0x05DC, 0x05D5, 0x05DD, 0x000A,
				0x03A7, 0x03C1, 0x03B9, 0x03C3, 0x03C4, 0x03CC, 0x03C2>>)
		end

	text_of (a_codes: ARRAY [INTEGER]): STRING_32
		local
			i: INTEGER
		do
			create Result.make (a_codes.count)
			from
				i := a_codes.lower
			until
				i > a_codes.upper
			loop
				Result.append_code (a_codes [i].to_natural_32)
				i := i + 1
			end
		ensure
			one_per_code_point: Result.count = a_codes.count
		end

	occurrences (a_s: STRING_32; a_c: CHARACTER_32): INTEGER
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_s.count
			loop
				if a_s.item (i) = a_c then
					Result := Result + 1
				end
				i := i + 1
			end
		end

feature {NONE} -- Assets and evidence (mirrors SW_CHAT_SCROLL_ASSAULT)

	shaping_assets: STRING_32
			-- The Noto png/128 tree, or empty: the runnable folder first
			-- (what a shipped app has), then the simple_shaping
			-- repository under $SIMPLE_EIFFEL.
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
			-- `<repo>/evidence/<a_name>', or empty when the repository is
			-- not underfoot - which simply means no file is written.
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
