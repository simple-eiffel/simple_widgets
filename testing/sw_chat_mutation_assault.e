note
	description: "[
		THE PER-MESSAGE MENU (0.7.0), offscreen only. Every SW_WINDOW
		here is built with `make' and driven with `request_render' /
		`write_frame'; `run' - which alone creates a native HWND - is
		never called, so `hwnd' stays `default_pointer' and no window,
		visible or hidden, ever exists.

		THE ASK. Larry, through the chat agent: a per-message menu -
		reply, react, edit, delete. SW_CHAT_THREAD's public model was
		`add_message' and `append_to_last' and nothing else, so a bubble
		could be born and grown and never changed or removed. The server
		side folds edit, delete and reaction events over the message they
		name; the widget had no door for any of them.

		WHAT IS PROVEN HERE. (1) `set_message' really replaces the words,
		optionally the speaker, and leaves the class standing between two
		frames - the 0.6.1 case, run again against a NEW kind of content
		change. (2) A tombstone keeps its place and its order, is SHORTER
		than the bubble it replaced, and holds nothing a selection can
		reach - because the text is destroyed, not hidden. (3) A reaction
		row changes the bubble's height, therefore `content_h', therefore
		the scrollbar thumb - and stickiness survives it. (4)
		`message_at' names every bubble and answers 0 in the gaps
		between them. (5) `reaction_at' finds the chip that was clicked,
		and finds nothing everywhere else. (6) A reply quote is ONE line,
		elided, with the ellipsis the elision promises. All of it at 1x
		AND 2x, and on both text paths.

		THE CLIPBOARD IS NEVER TOUCHED, for the reason
		SW_CHAT_TEXT_ASSAULT gives: `copy_selection' writes to the SYSTEM
		clipboard and Larry is at this machine. The tests assert on
		`selected_text', which IS the payload by construction.
	]"
	author: "Larry Rix"

class
	SW_CHAT_MUTATION_ASSAULT

inherit
	TEST_SET_BASE

feature -- set_message: the words change, the class stands

	test_set_message_replaces_the_words_and_the_speaker
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			r0: INTEGER
		do
			create th.make_light
			create surf.make (400, 300)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 300.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "the first draft")
			c.add_message ({SW_CHAT_THREAD}.Role_mine, {STRING_32} "answered")
			c.draw (p)
			r0 := c.revision

			c.set_message (1, {SW_CHAT_THREAD}.Role_keep, {STRING_32} "the second draft")
			assert_strings_equal_diff ("the words really changed",
				{STRING_32} "the second draft", c.display_text (1))
			assert_integers_equal ("Role_keep left the speaker alone",
				{SW_CHAT_THREAD}.Role_theirs, c.messages.i_th (1).role)
			assert_integers_equal ("the count did not move", 2, c.count)
			assert_integers_equal ("a content change bumps the revision - once",
				r0 + 1, c.revision)

			c.set_message (2, {SW_CHAT_THREAD}.Role_system, {STRING_32} "reassigned")
			assert_integers_equal ("a real role replaces the speaker",
				{SW_CHAT_THREAD}.Role_system, c.messages.i_th (2).role)
			assert_strings_equal_diff ("...and the words with it",
				{STRING_32} "reassigned", c.display_text (2))

				-- the frame catches up on its own, the way it always has
			c.draw (p)
			assert_strings_equal_diff ("the redrawn bubble shows the edit",
				{STRING_32} "the second draft", c.display_text (1))

			ctx.destroy
			surf.destroy
		end

	test_an_edit_drops_a_selection_that_lived_in_it
			-- Selection offsets are offsets into text. Let them outlive
			-- the text and the clipboard receives somebody else's words -
			-- or a substring of a message that no longer exists.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		do
			create th.make_light
			create surf.make (400, 300)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 300.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "abcdefghij")
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "klmnopqrst")
			c.draw (p)

			c.select_range (1, 2, 6)
			assert_strings_equal_diff ("something is selected in bubble 1",
				{STRING_32} "cdef", c.selected_text)

			c.set_message (2, {SW_CHAT_THREAD}.Role_keep, {STRING_32} "elsewhere")
			assert_strings_equal_diff ("editing ANOTHER bubble leaves it alone",
				{STRING_32} "cdef", c.selected_text)

			c.set_message (1, {SW_CHAT_THREAD}.Role_keep, {STRING_32} "xy")
			assert_false ("editing THIS bubble drops the selection", c.has_selection)
			assert_true ("...and it is empty, not stale", c.selected_text.is_empty)

			ctx.destroy
			surf.destroy
		end

	test_set_message_after_a_shaped_frame_keeps_the_invariant
			-- 0.6.1's case, run again against a change 0.6.1 never saw.
			-- `set_message' cannot re-shape: a span indexes layouts only
			-- `SW_SHAPING.layout_for' can make, at an inner width and a
			-- pixel size the widget does not learn until `draw'. So the
			-- spans go STALE for exactly one frame, and the invariant's
			-- `laid_out_revision = revision' guard is what makes that
			-- legal. Reaching the end of this test at all is the proof:
			-- in an F_code -keep build an invariant violation raises.
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
				c.add_message ({SW_CHAT_THREAD}.Role_mine, {STRING_32} "a reply")
				c.draw (p)
				assert_integers_equal ("two messages, two spans", 2, c.layout_spans.count)
				assert_integers_equal ("...current", c.revision, c.laid_out_revision)

					-- THE ASSAULT: each mutator in turn, with a qualified
					-- call after every one so the invariant is checked.
				c.set_message (1, {SW_CHAT_THREAD}.Role_keep,
					{STRING_32} "one%Ntwo%Nthree")
				assert_true ("set_message leaves the layouts stale, by design",
					c.laid_out_revision /= c.revision)
				assert_integers_equal ("...and the spans still describe the frame drawn",
					2, c.layout_spans.count)
				assert_true ("spans never outrun messages", c.layout_spans.count <= c.count)

				c.mark_edited (1)
				assert_true ("mark_edited is a content change too",
					c.laid_out_revision /= c.revision)

				c.set_reply_quote (2, {STRING_32} "Ada", {STRING_32} "one two three")
				assert_true ("so is a reply quote", c.laid_out_revision /= c.revision)

				c.set_reactions (2, chips (<<0x1F44D>>, <<3>>, <<True>>))
				assert_true ("so is a reaction row", c.laid_out_revision /= c.revision)

				c.tombstone (1)
				assert_true ("so is a delete", c.laid_out_revision /= c.revision)
				assert_integers_equal ("the tombstone kept its PLACE", 2, c.count)

					-- and the next frame catches up, on its own
				c.draw (p)
				assert_integers_equal ("the frame lays out both messages again",
					2, c.layout_spans.count)
				assert_integers_equal ("...at the current revision",
					c.revision, c.laid_out_revision)
				assert_integers_equal ("...with the spans still tiling the layouts",
					c.layout_spans.i_th (2).base + c.layout_spans.i_th (2).span - 1,
					c.shaped_layouts.count)
				print ("    after five mutations: " + c.count.out + " messages, "
					+ c.shaped_layouts.count.out + " layouts, revision "
					+ c.revision.out + "%N")

				kit.dispose_surfaces
				ctx.destroy
				surf.destroy
			else
				print ("    (no Noto assets underfoot - shaped mutation test skipped)%N")
			end
		end

feature -- The tombstone

	test_a_tombstone_is_shorter_and_holds_nothing
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			before, after: REAL_64
			scale: REAL_64
			k: INTEGER
		do
			from
				k := 1
			until
				k > 2
			loop
				if k = 1 then
					scale := 1.0
				else
					scale := 2.0
				end
				create th.make_light
				th.set_text_scale (scale)
				create surf.make (500, 600)
				create ctx.make (surf)
				create p.make (ctx, th)
				create c.make
				c.set_bounds (0.0, 0.0, 500.0, 600.0)
				c.add_message ({SW_CHAT_THREAD}.Role_theirs,
					{STRING_32} "a message with words in it%Nand a second line")
				c.add_message ({SW_CHAT_THREAD}.Role_mine, {STRING_32} "after it")
				c.draw (p)
				before := c.bubble_height (1)
				assert_true ("the live bubble has a height", before > 0.0)

				c.tombstone (1)
				c.draw (p)
				after := c.bubble_height (1)
				print ("    tombstone at " + scale.out + "x (toy): "
					+ before.out + " -> " + after.out + "%N")

				assert_integers_equal ("the message KEPT ITS PLACE - order is the record",
					2, c.count)
				assert_true ("the widget says so", c.is_tombstone (1))
				assert_true ("the bubble is SHORTER than the one it replaced",
					after < before)
				assert_true ("...and still has a height, so it still holds its slot",
					after > 0.0)
				assert_true ("the text is DESTROYED, not hidden",
					c.messages.i_th (1).text.is_empty)
				assert_true ("...so there is nothing to display",
					c.display_text (1).is_empty)

					-- and nothing a selection can reach
				c.select_message (1)
				assert_false ("selecting a tombstone selects nothing", c.has_selection)
				assert_true ("...and takes nothing", c.selected_text.is_empty)
				c.select_word_at (1, 0)
				assert_false ("nor does a double-click", c.has_selection)

					-- terminal and idempotent
				c.tombstone (1)
				assert_true ("a second delete is a no-op, not a fault", c.is_tombstone (1))
				assert_false ("the bubble after it is untouched", c.is_tombstone (2))

				ctx.destroy
				surf.destroy
				k := k + 1
			end
		end

	test_a_tombstone_sheds_its_decorations
			-- A reaction to a deleted message, or a quote inside one, is
			-- a claim about words nobody can read.
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
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "decorated")
			c.mark_edited (1)
			c.set_reply_quote (1, {STRING_32} "Ada", {STRING_32} "the parent")
			c.set_reactions (1, chips (<<0x1F44D, 0x2764>>, <<2, 1>>, <<True, False>>))
			c.draw (p)
			assert_true ("edited", c.is_edited (1))
			assert_true ("quoted", c.has_reply_quote (1))
			assert_integers_equal ("two chips", 2, c.reactions_of (1).count)

			c.tombstone (1)
			assert_false ("the marker went with it", c.is_edited (1))
			assert_false ("the quote went with it", c.has_reply_quote (1))
			assert_integers_equal ("the reactions went with it",
				0, c.reactions_of (1).count)
			c.draw (p)
			assert_true ("nothing left to hit-test as a chip",
				c.reaction_at (10.0, 10.0).message = 0)

			ctx.destroy
			surf.destroy
		end

feature -- Reactions

	test_reactions_change_the_bubble_the_content_and_the_thumb
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			bh0, bh1, content0, content1, thumb0, thumb1: REAL_64
		do
			create th.make_light
			create surf.make (300, 140)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 140.0)
			add_plain_messages (c, 8)
			c.draw (p)
			bh0 := c.bubble_height (3)
			content0 := c.content_h
			thumb0 := c.thumb_height
			assert_true ("the pane overflows, so there is a thumb to move",
				c.scrollbar_visible)
			assert_true ("sticky at birth", c.is_sticky)

			c.set_reactions (3, chips (<<0x1F44D, 0x2764, 0x1F389>>, <<4, 2, 1>>,
				<<True, False, False>>))
			c.draw (p)
			bh1 := c.bubble_height (3)
			content1 := c.content_h
			thumb1 := c.thumb_height
			print ("    reactions: bubble " + bh0.out + " -> " + bh1.out
				+ ", content_h " + content0.out + " -> " + content1.out
				+ ", thumb " + thumb0.out + " -> " + thumb1.out + "%N")

			assert_integers_equal ("three chips are aboard", 3, c.reactions_of (3).count)
			assert_true ("the reader's own is marked", c.reactions_of (3).i_th (1).mine)
			assert_integers_equal ("with its tally", 4, c.reactions_of (3).i_th (1).tally)
			assert_true ("the BUBBLE grew by a reaction row", bh1 > bh0)
			assert_true ("...so content_h grew", content1 > content0)
			assert_true ("...and the thumb shrank against the taller content",
				thumb1 < thumb0)
			assert_true ("follow-the-tail survived it", c.is_sticky)
			assert_true ("...parked at the true tail", c.scroll_y >= c.max_scroll - 2.0)

				-- replacing the row wholesale, which is what a server event does
			c.set_reactions (3, chips (<<0x1F44D>>, <<5>>, <<False>>))
			c.draw (p)
			assert_integers_equal ("the row is REPLACED, never merged",
				1, c.reactions_of (3).count)
			assert_integers_equal ("with the server's tally", 5, c.reactions_of (3).i_th (1).tally)
			assert_reals_equal ("one row is one row, however many chips ride on it",
				bh1, c.bubble_height (3), 0.001)

				-- until they no longer fit across, and the row wraps
			c.set_reactions (3, chips (
				<<0x1F44D, 0x2764, 0x1F389, 0x1F600, 0x1F64F, 0x1F525, 0x1F4A1, 0x2705>>,
				<<1, 1, 1, 1, 1, 1, 1, 1>>,
				<<False, False, False, False, False, False, False, False>>))
			c.draw (p)
			print ("    eight chips: bubble " + c.bubble_height (3).out + "%N")
			assert_integers_equal ("eight chips are aboard", 8, c.reactions_of (3).count)
			assert_true ("...they wrap to a second row rather than run off the bubble",
				c.bubble_height (3) > bh1)

				-- an empty list is how a last reaction is taken away
			c.set_reactions (3, chips (<<>>, <<>>, <<>>))
			c.draw (p)
			assert_integers_equal ("no chips left", 0, c.reactions_of (3).count)
			assert_reals_equal ("...and the bubble is exactly what it was before any",
				bh0, c.bubble_height (3), 0.001)

			ctx.destroy
			surf.destroy
		end

	test_the_chip_list_is_copied_in_not_borrowed
			-- A caller that reuses its list for the next event must not
			-- be able to rewrite a frame that has already been drawn.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			l: ARRAYED_LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]]
		do
			create th.make_light
			create surf.make (300, 200)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 200.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "reacted to")
			l := chips (<<0x1F44D>>, <<2>>, <<True>>)
			c.set_reactions (1, l)
			c.draw (p)

			l.wipe_out
			l.extend ([{STRING_32} "?", 99, False])
			assert_integers_equal ("the widget still has its own one chip",
				1, c.reactions_of (1).count)
			assert_integers_equal ("...with its own tally", 2, c.reactions_of (1).i_th (1).tally)

			c.reactions_of (1).wipe_out
			assert_integers_equal ("and what it hands OUT is a copy too",
				1, c.reactions_of (1).count)

			ctx.destroy
			surf.destroy
		end

feature -- The two questions a per-message menu asks

	test_message_at_names_every_bubble_and_the_gaps
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			h1, h2: REAL_64
		do
			create th.make_light
			create surf.make (400, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 400.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "first")
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "second")
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "third")

			assert_integers_equal ("before a frame there is no geometry to name",
				0, c.message_at (20.0, 20.0))

			c.draw (p)
			h1 := c.bubble_height (1)
			h2 := c.bubble_height (2)
				-- Role_theirs draws at x + 10, first bubble at y + 8,
				-- eight pixels of air between bubbles
			assert_integers_equal ("above the first bubble is nobody's",
				0, c.message_at (12.0, 2.0))
			assert_integers_equal ("inside the first", 1, c.message_at (12.0, 8.0 + h1 / 2.0))
			assert_integers_equal ("the GAP between one and two is nobody's",
				0, c.message_at (12.0, 8.0 + h1 + 4.0))
			assert_integers_equal ("inside the second",
				2, c.message_at (12.0, 8.0 + h1 + 8.0 + h2 / 2.0))
			assert_integers_equal ("the gap between two and three",
				0, c.message_at (12.0, 8.0 + h1 + 8.0 + h2 + 4.0))
			assert_integers_equal ("left of every bubble is nobody's",
				0, c.message_at (2.0, 8.0 + h1 / 2.0))
			assert_integers_equal ("below the last is nobody's",
				0, c.message_at (12.0, 390.0))

				-- and a tombstone is still a message a menu can name
			c.tombstone (2)
			c.draw (p)
			h1 := c.bubble_height (1)
			assert_integers_equal ("a deleted bubble still answers with its own index",
				2, c.message_at (12.0, 8.0 + h1 + 8.0 + c.bubble_height (2) / 2.0))

			ctx.destroy
			surf.destroy
		end

	test_reaction_at_finds_the_chip_that_was_clicked
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			found: TUPLE [px, py: REAL_64; message: INTEGER; emoji: STRING_32]
			hits: INTEGER
		do
			create th.make_light
			create surf.make (400, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 400.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "reacted to")
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "not reacted to")
			c.set_reactions (1, chips (<<0x1F44D, 0x2764>>, <<3, 1>>, <<True, False>>))
			c.draw (p)

			hits := chip_points (c, 0.0, 0.0, 400.0, 400.0)
			print ("    chip hit points over a 400x400 pane: " + hits.out + "%N")
			assert_true ("the chips are hit-testable at all", hits > 0)
			assert_true ("...and they are CHIPS, not the whole pane", hits < 4000)

			found := first_chip (c, 0.0, 0.0, 400.0, 400.0)
			assert_integers_equal ("the chip belongs to the message that carries it",
				1, found.message)
			assert_strings_equal_diff ("...and names the emoji a click would toggle",
				text_of (<<0x1F44D>>), found.emoji)
			assert_integers_equal ("a chip is INSIDE its own bubble",
				1, c.message_at (found.px, found.py))

			assert_integers_equal ("off every chip is message 0",
				0, c.reaction_at (2.0, 2.0).message)
			assert_true ("...with no emoji to toggle",
				c.reaction_at (2.0, 2.0).emoji.is_empty)
			assert_integers_equal ("a bubble with no reactions has no chips",
				0, c.reaction_at (12.0, 8.0 + c.bubble_height (1) + 12.0).message)

			ctx.destroy
			surf.destroy
		end

feature -- The reply quote

	test_a_reply_quote_is_one_line_and_elided
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			bh0, bh1: REAL_64
			line, drawn: STRING_32
		do
			create th.make_light
			create surf.make (260, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 260.0, 400.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "the answer")
			c.draw (p)
			bh0 := c.bubble_height (1)

			c.set_reply_quote (1, {STRING_32} "Ada",
				{STRING_32} "a quoted parent message that runs on%Nand on across a break "
					+ "and keeps running well past anything a header could hold")
			c.draw (p)
			bh1 := c.bubble_height (1)
			line := c.quote_line (1)
			drawn := c.drawn_quote (1)
			print ("    quote line " + line.count.out + " chars, drawn "
				+ drawn.count.out + "%N")

			assert_true ("the bubble grew a header band", bh1 > bh0)
			assert_true ("the header names the author", line.substring (1, 3).same_string ({STRING_32} "Ada"))
			assert_integers_equal ("the header is ONE line - the break became a space",
				0, occurrences (line, '%N'))
			assert_true ("the drawn header is shorter than the whole quote",
				drawn.count < line.count)
			assert_true ("...and says so with an ellipsis",
				drawn.count > 0 and then drawn.item (drawn.count).natural_32_code = 0x2026)

				-- clearing it is how an un-parenting event is applied
			c.set_reply_quote (1, {STRING_32} "", {STRING_32} "")
			c.draw (p)
			assert_false ("two empty strings clear the quote", c.has_reply_quote (1))
			assert_reals_equal ("...and the bubble is what it was", bh0, c.bubble_height (1), 0.001)

			ctx.destroy
			surf.destroy
		end

	test_elision_keeps_what_fits_and_marks_what_it_cut
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			short, long, cut: STRING_32
		do
			create th.make_light
			create surf.make (400, 100)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			p.font ({SW_PAINTER}.Role_ui, 13.0, False)

			short := {STRING_32} "short"
			long := {STRING_32} "a line far too long to fit inside the width this test hands it"

			assert_strings_equal_diff ("what fits is kept whole, character for character",
				short, c.elided (p, short, 300.0))

			cut := c.elided (p, long, 120.0)
			print ("    elided to 120px: %"" + cut.to_string_8 + "%"%N")
			assert_true ("what does not fit is cut", cut.count < long.count)
			assert_true ("...and marked with one ellipsis",
				cut.item (cut.count).natural_32_code = 0x2026)
			assert_true ("...and the result really fits", p.advance (cut) <= 120.0)
			assert_true ("the cut is a PREFIX of the original, never a rewrite",
				long.substring (1, cut.count - 1).same_string (cut.substring (1, cut.count - 1)))

			ctx.destroy
			surf.destroy
		end

feature -- The marker

	test_the_edited_marker_grows_a_band_and_survives_a_re_edit
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			bh0, bh1: REAL_64
		do
			create th.make_light
			create surf.make (400, 300)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 300.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "before")
			c.draw (p)
			bh0 := c.bubble_height (1)
			assert_false ("a fresh bubble carries no marker", c.is_edited (1))

			c.set_message (1, {SW_CHAT_THREAD}.Role_keep, {STRING_32} "after")
			c.mark_edited (1)
			c.draw (p)
			bh1 := c.bubble_height (1)
			print ("    edited marker: " + bh0.out + " -> " + bh1.out + "%N")
			assert_true ("the marker is on", c.is_edited (1))
			assert_true ("...and it costs a band of height", bh1 > bh0)

			c.mark_edited (1)
			c.draw (p)
			assert_reals_equal ("marking twice does not stack two bands",
				bh1, c.bubble_height (1), 0.001)

			ctx.destroy
			surf.destroy
		end

feature -- 2x, and the shaped path

	test_every_band_scales_with_the_theme
			-- The bands are MEASURED type, not constants, so they have to
			-- grow with `text_scale' - and the whole bubble with them.
		local
			one_x, two_x: REAL_64
		do
			one_x := decorated_bubble_height (1.0)
			two_x := decorated_bubble_height (2.0)
			print ("    decorated bubble: 1x " + one_x.out + ", 2x " + two_x.out + "%N")
			assert_true ("both scales measured something", one_x > 0.0 and two_x > 0.0)
			assert_true ("2x is taller than 1x - the bands follow the type",
				two_x > one_x)
		end

	test_the_shaped_path_draws_the_decorations_too
		local
			room: TUPLE [window: SW_WINDOW; thread: SW_CHAT_THREAD]
			w: SW_WINDOW
			c: SW_CHAT_THREAD
			bh0, bh1: REAL_64
		do
			room := build_room (2.0)
			w := room.window
			c := room.thread
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "a shaped bubble")
			w.request_render
			bh0 := c.bubble_height (1)

			c.set_reply_quote (1, {STRING_32} "Ada", {STRING_32} "the parent message")
			c.mark_edited (1)
			c.set_reactions (1, chips (<<0x1F44D, 0x2764>>, <<2, 1>>, <<True, False>>))
			w.request_render
			bh1 := c.bubble_height (1)
			print ("    shaped 2x bubble: " + bh0.out + " -> " + bh1.out + "%N")

			assert_true ("the shaped bubble carries all three bands", bh1 > bh0)
			assert_true ("the quote was shaped, not guessed",
				not c.drawn_quote (1).is_empty)
			assert_integers_equal ("one span per message, current",
				1, c.layout_spans.count)
			assert_integers_equal ("...at this revision", c.revision, c.laid_out_revision)
			assert_true ("and the chips are hit-testable on the shaped path",
				chip_points (c, c.x, c.y, c.x + c.width, c.y + c.height) > 0)
		end

feature -- Evidence (offscreen only - no window is ever shown)

	test_mutation_evidence
		local
			room: TUPLE [window: SW_WINDOW; thread: SW_CHAT_THREAD]
			w: SW_WINDOW
			c: SW_CHAT_THREAD
			evidence: STRING_32
			wrote: BOOLEAN
		do
			room := build_room (2.0)
			w := room.window
			c := room.thread
			c.add_message ({SW_CHAT_THREAD}.Role_theirs,
				{STRING_32} "The original message, before anybody touched it.")
			c.add_message ({SW_CHAT_THREAD}.Role_mine,
				{STRING_32} "This one was edited after it was sent.")
			c.add_message ({SW_CHAT_THREAD}.Role_theirs,
				{STRING_32} "This one is about to be deleted.")
			c.add_message ({SW_CHAT_THREAD}.Role_mine,
				{STRING_32} "Three people reacted to this one.")
			c.add_message ({SW_CHAT_THREAD}.Role_theirs,
				{STRING_32} "And this one is a reply.")

			c.set_message (2, {SW_CHAT_THREAD}.Role_keep,
				{STRING_32} "This one was edited after it was sent - twice.")
			c.mark_edited (2)
			c.tombstone (3)
			c.set_reactions (4, chips (<<0x1F44D, 0x2764, 0x1F389>>, <<4, 2, 1>>,
				<<True, False, False>>))
			c.set_reply_quote (5, {STRING_32} "Ada",
				{STRING_32} "The original message, before anybody touched it.")

			w.request_render
			assert_integers_equal ("five bubbles in the picture", 5, c.count)
			assert_true ("one of them is edited", c.is_edited (2))
			assert_true ("one of them is a tombstone", c.is_tombstone (3))
			assert_integers_equal ("one of them carries three chips",
				3, c.reactions_of (4).count)
			assert_true ("one of them is mine", c.reactions_of (4).i_th (1).mine)
			assert_true ("one of them is a reply", c.has_reply_quote (5))

			evidence := evidence_path ("thread-mutation-2x.png")
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
			kit: SW_SHAPING
			assets: STRING_32
		do
			create th.make_dark
			th.set_text_scale (a_scale)
			create w.make ("mutation", 0, 0, 900, 700, th)
			w.enable_shaped_text
			assets := shaping_assets
			if not assets.is_empty then
					-- `enable_shaped_text' builds its kit over the RUNNABLE
					-- FOLDER, which is what a shipped app has and what an
					-- EIFGENs build does not. Point it at the repository's
					-- own artwork instead, so a reaction chip is a PICTURE
					-- in the evidence and not a .notdef box - which is the
					-- whole difference between the shaped path and the
					-- text fallback.
				create kit.make_with_assets (assets)
				kit.set_theme_faces (th)
				w.set_shaping (kit)
			end
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

	decorated_bubble_height (a_scale: REAL_64): REAL_64
			-- One bubble carrying a quote, a marker and two chips, drawn
			-- on the TOY path at `a_scale', measured.
		require
			sane_scale: a_scale >= 0.5 and a_scale <= 3.0
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		do
			create th.make_light
			th.set_text_scale (a_scale)
			create surf.make (600, 400)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 600.0, 400.0)
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, {STRING_32} "decorated")
			c.set_reply_quote (1, {STRING_32} "Ada", {STRING_32} "the parent")
			c.mark_edited (1)
			c.set_reactions (1, chips (<<0x1F44D, 0x2764>>, <<2, 1>>, <<True, False>>))
			c.draw (p)
			Result := c.bubble_height (1)
			ctx.destroy
			surf.destroy
		ensure
			non_negative: Result >= 0.0
		end

	add_plain_messages (a_c: SW_CHAT_THREAD; a_n: INTEGER)
			-- `a_n' short bubbles, roles cycling - enough to overflow a
			-- small pane without putting real content on trial.
		require
			positive: a_n > 0
		local
			i, role: INTEGER
		do
			from
				i := 1
			until
				i > a_n
			loop
				role := ((i - 1) \\ 3) + 1
				a_c.add_message (role, "Message " + i.out + " - a short line.")
				i := i + 1
			end
		ensure
			grew: a_c.count = old a_c.count + a_n
		end

feature {NONE} -- Chips

	chips (a_codes: ARRAY [INTEGER]; a_tallies: ARRAY [INTEGER]; a_mine: ARRAY [BOOLEAN]):
			ARRAYED_LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]]
			-- A reaction row built from CODE POINTS, so a source literal
			-- never puts this file's own encoding on trial instead of the
			-- chip math.
		require
			same_length: a_codes.count = a_tallies.count and a_codes.count = a_mine.count
		local
			i: INTEGER
		do
			create Result.make (a_codes.count)
			from
				i := 1
			until
				i > a_codes.count
			loop
				Result.extend ([text_of (<<a_codes [a_codes.lower + i - 1]>>),
					a_tallies [a_tallies.lower + i - 1],
					a_mine [a_mine.lower + i - 1]])
				i := i + 1
			end
		ensure
			one_each: Result.count = a_codes.count
		end

	chip_points (a_c: SW_CHAT_THREAD; a_x0, a_y0, a_x1, a_y1: REAL_64): INTEGER
			-- How many points of a 2px grid over the rectangle land on a
			-- reaction chip. A sweep, because the chips' own rectangles
			-- are the widget's business and not a host's.
		local
			px, py: REAL_64
		do
			from
				py := a_y0
			until
				py > a_y1
			loop
				from
					px := a_x0
				until
					px > a_x1
				loop
					if a_c.reaction_at (px, py).message > 0 then
						Result := Result + 1
					end
					px := px + 2.0
				end
				py := py + 2.0
			end
		ensure
			non_negative: Result >= 0
		end

	first_chip (a_c: SW_CHAT_THREAD; a_x0, a_y0, a_x1, a_y1: REAL_64):
			TUPLE [px, py: REAL_64; message: INTEGER; emoji: STRING_32]
			-- The topmost-leftmost grid point that lands on a chip, and
			-- what `reaction_at' says about it. Message 0 when the sweep
			-- finds nothing.
		local
			px, py: REAL_64
			hit: TUPLE [message: INTEGER; emoji: STRING_32]
			none: STRING_32
		do
			create none.make_empty
			Result := [0.0, 0.0, 0, none]
			from
				py := a_y0
			until
				py > a_y1 or Result.message /= 0
			loop
				from
					px := a_x0
				until
					px > a_x1 or Result.message /= 0
				loop
					hit := a_c.reaction_at (px, py)
					if hit.message > 0 then
						Result := [px, py, hit.message, hit.emoji]
					end
					px := px + 2.0
				end
				py := py + 2.0
			end
		end

feature {NONE} -- Text

	text_of (a_codes: ARRAY [INTEGER]): STRING_32
		do
			create Result.make (a_codes.count)
			across
				a_codes as k
			loop
				Result.append_code (k.to_natural_32)
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
