note
	description: "[
		The chat-thread scroll defect and its fix, offscreen only. Every
		SW_WINDOW here is built with `make' and driven with
		`request_render' / `simulate_wheel' / `write_frame' - `run' (which
		alone creates a native HWND) is never called, so `hwnd' stays
		`default_pointer' and no window, visible or hidden, ever exists.

		THE REPORT. Larry, in the live chat: "the primary window scrolled
		up for the new text response" did not happen; "I have no
		scrollbar to manually scroll"; "I cannot even put the cursor over
		the primary window and scroll up or down."

		THE ROOT CAUSE (see SW_CHAT_THREAD's own note for the full
		account). `draw' used to clamp `scroll_y' once PER BUBBLE against
		`content_h' while it was still mid-accumulation - bubble 1 always
		saw a content height of 8.0, the loop's own starting value, and
		reset `scroll_y' to ~0 on every single frame before the true
		total was ever known. The tail could never scroll into view, and
		no wheel delta or drag survived the next repaint.

		`test_reproduction_at_larrys_scale' rebuilds the room the way
		SW_CHAT_VIEW does (`enable_shaped_text', 2x `text_scale', a
		1071x836 window, thirty mixed-length messages including one
		Hebrew + emoji + Greek line) and answers Larry's own two
		questions - is the tail visible, does a wheel delivered THROUGH
		THE WINDOW (`SW_WINDOW.simulate_wheel', never
		`thread.handle_wheel' directly) move the view.

		THE SCROLLBAR. `thumb_height' / `thumb_top' are the same formulas
		`draw' paints with and `handle_click' / `handle_drag' hit-test
		with - proven directly as layout math, then driven through the
		widget's own public mouse and keyboard handlers exactly as the
		window would call them.
	]"
	author: "Larry Rix"

class
	SW_CHAT_SCROLL_ASSAULT

inherit
	TEST_SET_BASE

feature -- Reproduction (Larry's own numbers, through the window)

	test_reproduction_at_larrys_scale
			-- The report, rebuilt: 1071x836, 2x text, shaped, thirty
			-- messages. (a) is the tail visible; (b) does a wheel
			-- delivered through the WINDOW move `scroll_y'.
		local
			room: TUPLE [window: SW_WINDOW; thread: SW_CHAT_THREAD]
			w: SW_WINDOW
			th: SW_CHAT_THREAD
			before_scroll: REAL_64
			cx, cy: INTEGER
			evidence: STRING_32
			wrote: BOOLEAN
		do
			room := build_room (2.0)
			w := room.window
			th := room.thread
			seed_messages (th)
			assert_integers_equal ("thirty messages seeded", 30, th.count)

			w.request_render
			before_scroll := th.scroll_y

			print ("    repro (2x, 1071x836, 30 msgs): height " + th.height.out
				+ ", content_h " + th.content_h.out
				+ ", scroll_y " + before_scroll.out
				+ ", is_sticky " + th.is_sticky.out
				+ ", max_scroll " + th.max_scroll.out + "%N")

			assert_true ("the pane really overflows thirty messages at 2x text",
				th.max_scroll > 0.0)
			assert_true ("(a) the LAST message is visible: parked at the tail",
				th.scroll_y >= th.max_scroll - 2.0)
			assert_true ("and the thread knows it is sticky", th.is_sticky)
			assert_true ("a scrollbar is now drawable", th.scrollbar_visible)

			evidence := evidence_path ("thread-scroll-before.png")
			if not evidence.is_empty then
				wrote := w.write_frame (evidence)
				print ("    written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end

				-- (b) a wheel delivered THROUGH THE WINDOW - target_at's
				-- own hit-test, then bubble_wheel's own parent walk -
				-- with the pointer over the thread, not a direct call to
				-- `handle_wheel'.
			cx := (th.x + th.width / 2.0).truncated_to_integer
			cy := (th.y + th.height / 2.0).truncated_to_integer
			w.simulate_wheel (cx, cy, 240)
			print ("    repro after window wheel: scroll_y " + th.scroll_y.out
				+ ", content_h " + th.content_h.out
				+ ", is_sticky " + th.is_sticky.out + "%N")
			assert_true ("(b) the wheel through the window moved scroll_y off the tail",
				th.scroll_y < before_scroll - 1.0)
			assert_false ("scrolling up breaks stickiness", th.is_sticky)

			w.simulate_wheel (cx, cy, -24000)
			assert_true ("scrolling back down through the window re-sticks", th.is_sticky)
			assert_true ("...and lands back at the true tail",
				th.scroll_y >= th.max_scroll - 2.0)
		end

feature -- The fix, proven directly on SW_CHAT_THREAD

	test_scroll_to_clamps_and_updates_stickiness
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		do
			create th.make_light
			create surf.make (300, 120)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 120.0)
			add_plain_messages (c, 20)
			c.draw (p)
			assert_true ("twenty short bubbles overflow a 120px pane", c.max_scroll > 0.0)
			assert_true ("sticky at birth - every chat client's rule", c.is_sticky)

			c.scroll_to (0.0)
			assert_reals_equal ("landed exactly at the top", 0.0, c.scroll_y, 0.000_1)
			assert_false ("scrolling to the top un-sticks", c.is_sticky)

			c.scroll_to (c.max_scroll + 500.0)
			assert_reals_equal ("clamped to max_scroll, never the requested overshoot",
				c.max_scroll, c.scroll_y, 0.000_1)
			assert_true ("landing at the bottom re-sticks", c.is_sticky)

			c.scroll_to (-500.0)
			assert_reals_equal ("clamped at zero, never negative", 0.0, c.scroll_y, 0.000_1)

			ctx.destroy
			surf.destroy
		end

	test_clamp_survives_content_shrink
			-- A pane that grows past its own content must not strand
			-- `scroll_y' above the new (lower) `max_scroll'.
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		do
			create th.make_light
			create surf.make (300, 4000)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 120.0)
			add_plain_messages (c, 20)
			c.draw (p)
			c.scroll_to (c.max_scroll / 2.0)
			assert_true ("parked mid-thread for the shrink", c.scroll_y > 0.0)

			c.set_bounds (0.0, 0.0, 300.0, 4000.0)
			c.draw (p)
			assert_reals_equal ("nothing left to scroll once the pane outgrows the content",
				0.0, c.max_scroll, 0.000_1)
			assert_reals_equal ("scroll_y clamped down with it, not stranded above it",
				0.0, c.scroll_y, 0.000_1)
			assert_true ("and sticky again", c.is_sticky)

			ctx.destroy
			surf.destroy
		end

	test_sticky_transitions
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			scroll_before: REAL_64
		do
			create th.make_light
			create surf.make (300, 120)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 120.0)
			add_plain_messages (c, 20)
			c.draw (p)
			assert_true ("sticky at birth", c.is_sticky)

			if c.handle_wheel (240) then end
			assert_false ("a wheel turn toward the top breaks stickiness", c.is_sticky)

			scroll_before := c.scroll_y
			c.add_message ({SW_CHAT_THREAD}.Role_theirs, "arriving while scrolled up")
			c.draw (p)
			assert_reals_equal ("the view does not jump while un-stuck",
				scroll_before, c.scroll_y, 0.01)
			assert_false ("...and stays un-stuck", c.is_sticky)

			if c.handle_wheel (-24000) then end
			assert_true ("wheeling back to the tail re-sticks", c.is_sticky)

			c.add_message ({SW_CHAT_THREAD}.Role_mine, "and THIS one follows, because sticky")
			c.draw (p)
			assert_true ("still sticky: the new message pulled the view with it",
				c.is_sticky)
			assert_true ("...and the tail is genuinely on screen",
				c.scroll_y >= c.max_scroll - 2.0)

			ctx.destroy
			surf.destroy
		end

feature -- Scrollbar layout math

	test_thumb_height_and_position
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			track, expected_h, expected_top: REAL_64
		do
			create th.make_light
			create surf.make (200, 100)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 200.0, 100.0)
			add_plain_messages (c, 25)
			c.draw (p)
			assert_true ("twenty-five bubbles overflow a 100px pane", c.scrollbar_visible)

			track := c.track_h
			expected_h := (c.height / c.content_h * track).max (24.0).min (track)
			assert_reals_equal ("thumb_height matches the height/content_h fraction",
				expected_h, c.thumb_height, 0.01)
			assert_true ("the thumb fits inside its own track",
				c.thumb_height > 0.0 and c.thumb_height <= track)

			c.scroll_to (0.0)
			assert_reals_equal ("at the top, the thumb sits at the track's own top",
				c.track_y, c.thumb_top, 0.01)

			c.scroll_to (c.max_scroll)
			assert_reals_equal ("at the bottom, the thumb's foot meets the track's",
				c.track_y + track - c.thumb_height, c.thumb_top, 0.01)

			c.scroll_to (c.max_scroll / 2.0)
			expected_top := c.track_y + 0.5 * (track - c.thumb_height)
			assert_reals_equal ("at the midpoint, the thumb sits at the track's midpoint",
				expected_top, c.thumb_top, 0.01)

			ctx.destroy
			surf.destroy
		end

	test_scrollbar_visible_only_on_overflow
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		do
			create th.make_light
			create surf.make (400, 3000)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 400.0, 3000.0)
			add_plain_messages (c, 3)
			c.draw (p)
			assert_false ("three short messages in a 3000px pane do not overflow",
				c.scrollbar_visible)
			assert_reals_equal ("nothing to scroll", 0.0, c.max_scroll, 0.000_1)

			c.set_bounds (0.0, 0.0, 400.0, 80.0)
			c.draw (p)
			assert_true ("the SAME three messages overflow an 80px pane",
				c.scrollbar_visible)
			assert_true ("and there is real room to scroll", c.max_scroll > 0.0)

			ctx.destroy
			surf.destroy
		end

feature -- Scrollbar interaction (the widget's own public handlers)

	test_drag_thumb_scrolls
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			press_x, press_y: REAL_64
			consumed: BOOLEAN
		do
			create th.make_light
			create surf.make (300, 120)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 120.0)
			add_plain_messages (c, 25)
			c.draw (p)
			c.scroll_to (0.0)
			assert_false ("parked at the top for the drag", c.is_sticky)

			press_x := c.track_x + 1.0
			press_y := c.thumb_top + c.thumb_height / 2.0
			consumed := c.handle_click (press_x, press_y)
			assert_true ("pressing the thumb is consumed by the scrollbar", consumed)
			assert_true ("...and starts a drag", c.is_dragging_thumb)

			c.handle_drag (press_x, c.track_y + c.track_h)
			assert_true ("dragging the thumb toward the track's foot moves scroll_y down",
				c.scroll_y > 0.0)

			c.handle_release (press_x.truncated_to_integer, (c.track_y + c.track_h).truncated_to_integer)
			assert_false ("release ends the drag", c.is_dragging_thumb)
			assert_true ("dragged all the way down re-sticks", c.is_sticky)

			ctx.destroy
			surf.destroy
		end

	test_track_click_pages
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			consumed: BOOLEAN
			before: REAL_64
		do
			create th.make_light
			create surf.make (300, 120)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 120.0)
			add_plain_messages (c, 30)
			c.draw (p)
				-- sticky at birth: the thumb sits at the track's FOOT,
				-- so a click near the track's top is bare track, not thumb.
			before := c.scroll_y
			consumed := c.handle_click (c.track_x + 1.0, c.track_y + 1.0)
			assert_true ("a track click is consumed by the scrollbar", consumed)
			assert_false ("...but is not a thumb press", c.is_dragging_thumb)
			assert_true ("clicking ABOVE the thumb pages UP, away from the tail",
				c.scroll_y < before)
			assert_false ("paging away from the tail un-sticks", c.is_sticky)

			before := c.scroll_y
			consumed := c.handle_click (c.track_x + 1.0, c.track_y + c.track_h - 1.0)
			assert_true ("clicking BELOW the (now higher) thumb pages DOWN",
				c.scroll_y > before)

			ctx.destroy
			surf.destroy
		end

	test_keyboard_paging
		local
			c: SW_CHAT_THREAD
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		do
			create th.make_light
			create surf.make (300, 120)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make
			c.set_bounds (0.0, 0.0, 300.0, 120.0)
			add_plain_messages (c, 30)
			c.draw (p)
			assert_true ("the pane accepts keyboard focus", c.accepts_focus)

			c.handle_key (36, False)
			assert_reals_equal ("Home jumps to the very top", 0.0, c.scroll_y, 0.000_1)
			assert_false ("...and un-sticks", c.is_sticky)

			c.handle_key (34, False)
			assert_true ("PageDown moves toward the tail", c.scroll_y > 0.0)

			c.handle_key (35, False)
			assert_reals_equal ("End lands exactly at the tail", c.max_scroll, c.scroll_y, 0.000_1)
			assert_true ("...and re-sticks", c.is_sticky)

			c.handle_key (33, False)
			assert_true ("PageUp backs away from the tail", c.scroll_y < c.max_scroll)

			ctx.destroy
			surf.destroy
		end

feature -- The session log's timestamp (0.5.0)

	test_log_line_is_timestamped
			-- `zero_padded' and the shape of `timestamp_prefix' -
			-- "YYYY-MM-DD HH:MM:SS " - that every `log_line' now carries.
		local
			w: SW_WINDOW
			th: SW_THEME
			prefix: STRING_8
		do
			create th.make_light
			create w.make ("ts-check", 0, 0, 100, 100, th)

			assert_strings_equal_diff ("single digits get a leading zero",
				"07", w.zero_padded (7))
			assert_strings_equal_diff ("two-digit values pass through unchanged",
				"42", w.zero_padded (42))

			prefix := w.timestamp_prefix
			assert_integers_equal ("YYYY-MM-DD HH:MM:SS plus one trailing space",
				20, prefix.count)
			assert_true ("year-month separated", prefix.item (5) = '-')
			assert_true ("month-day separated", prefix.item (8) = '-')
			assert_true ("date and time separated by a space", prefix.item (11) = ' ')
			assert_true ("hour-minute separated", prefix.item (14) = ':')
			assert_true ("minute-second separated", prefix.item (17) = ':')
			assert_true ("ends with the trailing space `log_line' relies on",
				prefix.item (20) = ' ')
		end

feature -- Evidence (offscreen only - no window is ever shown)

	test_scroll_evidence
		local
			room: TUPLE [window: SW_WINDOW; thread: SW_CHAT_THREAD]
			w: SW_WINDOW
			th: SW_CHAT_THREAD
			evidence: STRING_32
			wrote: BOOLEAN
			cx, cy: INTEGER
		do
			room := build_room (2.0)
			w := room.window
			th := room.thread
			seed_messages (th)
			w.request_render

			assert_true ("scrolled to the tail on arrival", th.is_sticky)
			evidence := evidence_path ("thread-scroll-after.png")
			if not evidence.is_empty then
				wrote := w.write_frame (evidence)
				print ("    written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end

			cx := (th.x + th.width / 2.0).truncated_to_integer
			cy := (th.y + th.height / 2.0).truncated_to_integer
			w.simulate_wheel (cx, cy, 480)
			assert_false ("mid-scroll: no longer sticky", th.is_sticky)
			assert_true ("mid-scroll: still overflowing, the bar still shows",
				th.scrollbar_visible)

			evidence := evidence_path ("thread-scroll-mid.png")
			if not evidence.is_empty then
				wrote := w.write_frame (evidence)
				print ("    written ")
				print (evidence)
				print (" " + wrote.out + "%N")
			end
		end

feature {NONE} -- Building the room (mirrors simple_chat/apps/client/sw_chat_view.e)

	build_room (a_scale: REAL_64): TUPLE [window: SW_WINDOW; thread: SW_CHAT_THREAD]
			-- The same shape SW_CHAT_VIEW builds: a themed window with
			-- shaped text on, a column of title / thread (grow 1.0) /
			-- composer, at Larry's own 1071x836.
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
			create w.make ("scroll-repro", 0, 0, 1071, 836, th)
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
			grows: Result.thread.grow > 0.0
		end

	seed_messages (a_c: SW_CHAT_THREAD)
			-- Thirty messages: mixed length, some multi-line, message 15
			-- Hebrew + an emoji + Greek - Larry's own scale scenario.
		local
			i, role: INTEGER
		do
			from
				i := 1
			until
				i > 30
			loop
				role := ((i - 1) \\ 3) + 1
				if i = 15 then
					a_c.add_message (role, mixed_script_text)
				elseif i \\ 4 = 0 then
					a_c.add_message (role, long_message (i))
				else
					a_c.add_message (role, "Message " + i.out + ": a short line.")
				end
				i := i + 1
			end
		ensure
			thirty: a_c.count = old a_c.count + 30
		end

	add_plain_messages (a_c: SW_CHAT_THREAD; a_n: INTEGER)
			-- `a_n' short bubbles, roles cycling, for the layout-math
			-- tests that only need real overflow, not real content.
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
				a_c.add_message (role, "Message " + i.out + " - a short line to bulk out the thread.")
				i := i + 1
			end
		ensure
			grew: a_c.count = old a_c.count + a_n
		end

	long_message (a_i: INTEGER): STRING_32
		do
			create Result.make (200)
			Result.append_string_general ("Message " + a_i.out + ": ")
			Result.append_string_general ("This one runs long enough to wrap across "
				+ "several lines inside a bubble that tops out at seventy-two percent "
				+ "of the pane's usable width - exactly the kind of message the scroll "
				+ "defect used to hide behind, because the tail was never reachable "
				+ "at all.")
		end

	mixed_script_text: STRING_32
			-- Hebrew shalom, an emoji, Greek Christos - as CODE POINTS,
			-- so a source literal never puts this file's own encoding on
			-- trial instead of the scroll math (mirrors
			-- SW_SHAPING_ASSAULT.d015_text).
		do
			Result := text_of (<<0x05E9, 0x05DC, 0x05D5, 0x05DD, 0x0020, 0x1F916, 0x0020,
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

feature {NONE} -- Evidence location (mirrors SW_MARGINS_ASSAULT)

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
