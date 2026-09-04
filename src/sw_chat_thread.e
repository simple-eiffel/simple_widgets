note
	description: "[
		Wave 6 conversational: the thread - bubbles by ROLE (mine
		right in accent wash, theirs left on quiet surface, system
		centred and muted), word-wrapped inside their bubbles,
		wheel-scrolled, and STICKY to the bottom: adding a message
		follows the conversation unless the reader has scrolled
		back up (the rule every chat client honours). The model
		(roles, append_to_last for streaming, stickiness law) is
		public and assaulted headless.

		SHAPED TEXT (simple_shaping). When the painter carries a
		SW_SHAPING kit, a bubble is laid out by the shaping library
		instead of by the greedy word wrap below: bidi so Hebrew reads
		right-to-left inside a left-to-right pane, script itemization and
		font fallback so Greek and Hebrew find faces the theme face does
		not have, and emoji as the SAME Noto picture on every member's
		screen. The bubble's height is then the sum of its paragraphs'
		`total_height' and never a line count times a constant - which is
		the only honest measurement once a line may mix a 128-pixel emoji
		box with 13 pixel text.

		THE OLD PATH IS STILL SELECTABLE, and it is the DEFAULT. Without
		a kit (`SW_PAINTER.has_shaping' False) this widget behaves as it
		always has - same greedy wrap, same `Line_h', same bubble
		arithmetic. Nothing in the public model - `add_message',
		`append_to_last', `is_sticky', `content_h', `handle_wheel' -
		changes in either mode.

		THE SQUARE BOXES (0.6.0), AND WHY THEY WERE THERE. Larry, reading
		a numbered list from the assistant: square boxes where the line
		breaks should be. Neither path had ever heard of a newline. The
		toy wrap split on the SPACE CHARACTER ALONE, so an LF was just
		another character inside a "word" and cairo drew it as .notdef -
		the box. The shaped path was worse in a quieter way:
		simple_shaping's `is_breaking_space_code' counts LF among the
		characters a line MAY break at, so the text wrapped SOMEWHERE
		near the break but the LF itself was still shaped, still measured
		and still painted as a glyph. Both paths now cut the message into
		PARAGRAPHS first (`paragraphs_of'): an LF, a CRLF or a lone CR
		ends a paragraph and is never drawn; a TAB becomes a space; a RUN
		of breaks yields at most ONE empty line, so a message padded with
		blank lines cannot inflate a bubble without bound; and trailing
		blank paragraphs are dropped. Wrapping then applies WITHIN a
		paragraph, and the bubble's height is the real line count - which
		is why `shaped_layouts' is now one layout PER PARAGRAPH (see
		`layout_spans') and not one per message.

		SELECTION AND COPY (0.6.0). A bubble is now selectable text, not
		a picture of text: press inside one and drag to select,
		double-click to take the word, Ctrl+C or the right-click menu to
		copy, Escape to clear. Character granularity on the toy path;
		GLYPH-CLUSTER granularity on the shaped path, where the caret
		boundaries come from GLYPH_RUN's own `cluster_map' and
		`x_positions' (SHAPED_LINE reserves `character_index_at_x' for a
		future cycle and does not implement it, so the boundary walk
		lives here, over the runs the layout does publish). RTL is
		handled by direction, not by hope: in a right-to-left run the
		caret that sits at a cluster's LEFT edge is the one AFTER that
		character.

		SELECTION IS WITHIN ONE BUBBLE. Dragging out of a bubble extends
		the selection to that bubble's own ends and stops; there is no
		cross-bubble selection, deliberately - a thread is a list of
		utterances by different speakers, and a range that spans three of
		them has no honest text to hand the clipboard.

		WHAT IS COPIED IS WHAT IS SHOWN. Selection offsets are offsets
		into `display_text' - the message's paragraphs joined by single
		LFs - so the clipboard receives the tabs-as-spaces,
		blank-runs-collapsed reading the reader actually sees.

		R10, RE-LAYOUT AT RESIZE END. Shaping a paragraph is not free, and
		a drag delivers a resize every few milliseconds. So a WIDTH change
		waits for `SW_PAINTER.is_resize_storm' to clear (SW_WINDOW sets it
		from its own `busy_ticks' debounce) and the bubbles keep the
		layouts they have while the frame moves. A CONTENT change never
		waits: a message that arrives mid-drag still has to appear.

		THE SCROLL-CLAMP DEFECT (0.5.0) AND THE FIX. `draw' used to clamp
		`scroll_y' once PER BUBBLE, against `content_h' while it was still
		mid-accumulation (`content_h' starts the frame at 8.0 and only
		reaches its true total at the LAST bubble). Bubble 1's clamp saw a
		content height of 8.0 - far short of the real total - so on any
		pane taller than 8 pixels it collapsed `scroll_y' to 0 EVERY
		FRAME, before a single pixel had been measured honestly. The tail
		could never scroll into view, and no wheel delta or drag survived
		the next repaint: the thread looked permanently pinned to its
		top. `draw' now runs two passes - PASS 1 measures every bubble's
		height with no drawing and no dependence on `scroll_y' at all, so
		`content_h' is the true total before anything is clamped; PASS 2
		draws at the one scroll offset the frame settled on. Every
		scroll-changing entry point (`handle_wheel', a scrollbar drag or
		track click, PageUp/PageDown/Home/End) funnels through `scroll_to',
		so the same [0, max_scroll] law applies everywhere, not just here.

		THE SCROLLBAR (0.5.0). A vertical track along the right edge,
		visible only when `max_scroll' > 0.0 (`scrollbar_visible'), sized
		from SW_THEME's `text_scale' the way every other themed dimension
		in this toolkit scales. The thumb's height and position come from
		the same `thumb_height' / `thumb_top' queries `draw' paints with
		and `handle_click' / `handle_drag' hit-test with - one geometry,
		never two formulas that can drift apart. Dragging the thumb,
		clicking the bare track to page, the wheel, and (once the pane
		holds focus - it accepts it) PageUp/PageDown/Home/End all funnel
		through `scroll_to', which is where the follow-the-tail law now
		lives: sticky while within 2 px of the bottom, broken by scrolling
		up, restored by scrolling or dragging back down. Bubble wrap width
		reserves the scrollbar's gutter UNCONDITIONALLY (whether or not it
		is drawn this frame), matching SW_SCROLL_AREA's own convention -
		so text never reflows the instant the thread crosses the overflow
		line.
	]"

class
	SW_CHAT_THREAD

inherit
	SW_WIDGET
		redefine
			handle_wheel, handle_click, handle_double_click, handle_drag,
			handle_release, handle_key, handle_char, context_menu,
			accepts_focus, cursor_kind
		end

create
	make

feature -- Roles

	Role_mine: INTEGER = 1
	Role_theirs: INTEGER = 2
	Role_system: INTEGER = 3

feature {NONE} -- Initialization

	make
		do
			create messages.make (16)
			create shaped_layouts.make (16)
			create layout_spans.make (16)
			create displays.make (16)
			create line_cache.make (16)
			create bubble_boxes.make (16)
			is_sticky := True
			scrollbar_width := Scrollbar_w
			last_text_scale := 1.0
			displayed_revision := -1
		ensure
			nothing_laid_out: shaped_layouts.is_empty
			nothing_selected: not has_selection
		end

feature -- Access

	messages: ARRAYED_LIST [TUPLE [role: INTEGER; text: STRING_32]]

	scroll_y: REAL_64

	is_sticky: BOOLEAN
			-- Following the conversation's tail? Adding messages
			-- auto-scrolls only while True; scrolling up breaks it,
			-- scrolling back to the bottom restores it.

	content_h: REAL_64
			-- Measured during draw; 0 before the first frame.

	shaped_layouts: ARRAYED_LIST [SHAPED_LAYOUT]
			-- One SHAPED_LAYOUT per PARAGRAPH, in message order, once a
			-- shaped frame has been drawn; empty on the toy path and
			-- before the first frame. Public because it is the widget's
			-- measurement of itself. A message with no line breaks is one
			-- paragraph, so for single-paragraph traffic this is still one
			-- layout per message; `layout_spans' says which layouts belong
			-- to which message when it is not.

	layout_spans: ARRAYED_LIST [TUPLE [base, span: INTEGER]]
			-- One entry per message once a shaped frame has been drawn:
			-- the message's paragraph layouts are
			-- `shaped_layouts [base .. base + span - 1]'.

	laid_out_width: INTEGER
			-- Bubble INNER width, in pixels, the current `shaped_layouts'
			-- were built for; 0 before the first shaped frame.

	laid_out_size: INTEGER
			-- Pixel size the current `shaped_layouts' were built at.

	revision: INTEGER
			-- Bumped by every content change. `laid_out_revision' lags it
			-- exactly when the layouts are stale.

	laid_out_revision: INTEGER
			-- `revision' as of the last re-layout.

	count: INTEGER
		do
			Result := messages.count
		end

	last_text: STRING_32
		require
			aboard: count > 0
		do
			Result := messages.last.text.twin
		end

feature -- Element change

	add_message (a_role: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			role_known: a_role >= Role_mine and a_role <= Role_system
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			messages.extend ([a_role, s])
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
					-- clamped to the true bottom at next draw
			end
		ensure
			grew: count = old count + 1
		end

	append_to_last (a_text: READABLE_STRING_GENERAL)
			-- Streaming: grow the last message in place.
		require
			aboard: count > 0
		do
			messages.last.text.append_string_general (a_text)
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 260.0
		end

feature -- Line breaks

	paragraphs_of (a_text: READABLE_STRING_32): ARRAYED_LIST [STRING_32]
			-- `a_text' cut at every EXPLICIT line break. An LF, a CRLF or
			-- a lone CR ends a paragraph and is itself never drawn; a TAB
			-- becomes a space (cairo's toy path has no tab stops and the
			-- shaper would give it a box); a RUN of breaks collapses to at
			-- most ONE empty paragraph, so a message padded with blank
			-- lines cannot inflate its bubble without bound; and trailing
			-- empty paragraphs are dropped, because a message that ends
			-- with a newline is not a message with an empty last line.
			--
			-- Always at least one paragraph: the empty message is one
			-- empty paragraph, which is one empty line.
		local
			raw: ARRAYED_LIST [STRING_32]
			cur: STRING_32
			i, n, c: INTEGER
			blanks: INTEGER
		do
			create raw.make (4)
			create cur.make (32)
			n := a_text.count
			from
				i := 1
			until
				i > n
			loop
				c := a_text.code (i).to_integer_32
				if c = 10 or c = 13 then
					if c = 13 and then i < n and then a_text.code (i + 1).to_integer_32 = 10 then
							-- CRLF is ONE break, not two
						i := i + 1
					end
					raw.extend (cur.twin)
					cur.wipe_out
				elseif c = 9 then
					cur.append_character (' ')
				else
					cur.append_code (a_text.code (i))
				end
				i := i + 1
			end
			raw.extend (cur.twin)

				-- collapse runs of blank paragraphs to one, and drop the
				-- trailing ones entirely
			create Result.make (raw.count)
			from
				i := 1
			until
				i > raw.count
			loop
				if raw.i_th (i).is_empty then
					blanks := blanks + 1
				else
					if blanks > 0 and then not Result.is_empty then
						Result.extend ({STRING_32} "")
					end
					blanks := 0
					Result.extend (raw.i_th (i))
				end
				i := i + 1
			end
			if Result.is_empty then
				Result.extend ({STRING_32} "")
			end
		ensure
			at_least_one: not Result.is_empty
			no_trailing_blank: Result.count = 1 or else not Result.last.is_empty
		end

	display_text (i: INTEGER): STRING_32
			-- Message `i' AS THE BUBBLE SHOWS IT: its paragraphs joined by
			-- single LFs. Selection offsets are offsets into this, so what
			-- reaches the clipboard is what the reader was looking at.
		require
			in_range: i >= 1 and i <= messages.count
		local
			ps: ARRAYED_LIST [STRING_32]
			k: INTEGER
		do
			ps := paragraphs_of (messages.i_th (i).text)
			create Result.make (messages.i_th (i).text.count)
			from
				k := 1
			until
				k > ps.count
			loop
				if k > 1 then
					Result.append_character ('%N')
				end
				Result.append (ps.i_th (k))
				k := k + 1
			end
		end

feature -- Selection

	sel_message: INTEGER
			-- The bubble the selection lives in; 0 = nothing selected.
			-- A selection never spans two bubbles (see the class note).

	sel_anchor: INTEGER
			-- Where the press landed: a CARET OFFSET into
			-- `display_text (sel_message)', 0 .. its count.

	sel_caret: INTEGER
			-- Where the drag has reached; equal to `sel_anchor' when the
			-- press has not moved.

	has_selection: BOOLEAN
			-- Is there a non-empty selected range?
		do
			Result := sel_message > 0 and then sel_anchor /= sel_caret
		ensure
			definition: Result = (sel_message > 0 and then sel_anchor /= sel_caret)
		end

	sel_low: INTEGER
			-- The selection's lower caret offset.
		do
			Result := sel_anchor.min (sel_caret)
		end

	sel_high: INTEGER
			-- The selection's upper caret offset.
		do
			Result := sel_anchor.max (sel_caret)
		end

	is_selecting: BOOLEAN
			-- Is a press-drag selection in progress?

	selected_text: STRING_32
			-- The selected characters, as shown; empty when nothing is
			-- selected. Characters `sel_low' + 1 .. `sel_high'.
		local
			d: STRING_32
		do
			create Result.make_empty
			if has_selection and then sel_message <= messages.count then
				d := display_text (sel_message)
				if sel_low < sel_high and then sel_high <= d.count then
					Result := d.substring (sel_low + 1, sel_high)
				end
			end
		ensure
			empty_without_selection: not has_selection implies Result.is_empty
		end

	clear_selection
			-- Escape, a click on bare pane, or a host that is done.
		do
			sel_message := 0
			sel_anchor := 0
			sel_caret := 0
			is_selecting := False
		ensure
			gone: not has_selection
			not_dragging: not is_selecting
		end

	select_range (a_message, a_from, a_to: INTEGER)
			-- Select characters `a_from' + 1 .. `a_to' of message
			-- `a_message' - the programmatic twin of a press-drag, for a
			-- host (and for a test) with no pointer.
		require
			in_range: a_message >= 1 and a_message <= messages.count
			offsets_sane: a_from >= 0 and a_to >= 0
			within_text: a_from <= display_text (a_message).count
				and a_to <= display_text (a_message).count
		do
			sel_message := a_message
			sel_anchor := a_from
			sel_caret := a_to
		ensure
			in_that_message: sel_message = a_message
			anchored: sel_anchor = a_from and sel_caret = a_to
		end

	select_word_at (a_message, a_offset: INTEGER)
			-- Grow a caret into the word around it - what a double-click
			-- means. On a space, take the run of spaces; a line break is
			-- never crossed.
		require
			in_range: a_message >= 1 and a_message <= messages.count
		local
			d: STRING_32
			lo, hi, n: INTEGER
			on_space: BOOLEAN
		do
			d := display_text (a_message)
			n := d.count
			if n = 0 then
				select_range (a_message, 0, 0)
			else
				lo := (a_offset + 1).max (1).min (n)
				on_space := d.item (lo) = ' '
				hi := lo
				from
				until
					lo <= 1 or else not same_word_class (d.item (lo - 1), on_space)
				loop
					lo := lo - 1
				end
				from
				until
					hi >= n or else not same_word_class (d.item (hi + 1), on_space)
				loop
					hi := hi + 1
				end
				select_range (a_message, lo - 1, hi)
			end
		ensure
			in_that_message: sel_message = a_message
		end

	select_message (a_message: INTEGER)
			-- The whole bubble - what the context menu's Select Message
			-- does.
		require
			in_range: a_message >= 1 and a_message <= messages.count
		do
			select_range (a_message, 0, display_text (a_message).count)
		ensure
			in_that_message: sel_message = a_message
		end

	copy_selection
			-- Put the selected text on the system clipboard through
			-- SW_CLIPBOARD - the same door SW_TEXT_BOX uses, so there is
			-- one clipboard path in the toolkit and not two. A no-op when
			-- nothing is selected.
		local
			clip: SW_CLIPBOARD
		do
			if has_selection then
				create clip
				clip.set_text (selected_text)
			end
		end

feature {NONE} -- Selection support

	same_word_class (a_c: CHARACTER_32; a_on_space: BOOLEAN): BOOLEAN
			-- Does `a_c' belong to the same run a double-click started
			-- in? A line break belongs to neither run and always stops.
		do
			if a_c = '%N' then
				Result := False
			elseif a_on_space then
				Result := a_c = ' '
			else
				Result := a_c /= ' '
			end
		end

feature -- Scrollbar

	Scrollbar_w: REAL_64 = 12.0
			-- Track width at 1x text.

	scrollbar_width: REAL_64
			-- `Scrollbar_w' times the theme's `text_scale' as of the most
			-- recent `draw' - cached because hit-testing (`handle_click',
			-- `handle_drag') has no painter/theme of its own to read
			-- `text_scale' from. `Scrollbar_w' (1x), set by `make', before
			-- the first frame - REAL_64 is expanded, so (unlike a
			-- reference attribute) an `attribute...end' body here would
			-- never run; `make' is where the honest default lives.

	last_text_scale: REAL_64
			-- The theme's `text_scale' as of the most recent `draw'; 1.0,
			-- set by `make', before the first frame.

	max_scroll: REAL_64
			-- How far `scroll_y' can go before the tail is showing.
		do
			Result := (content_h - height).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	scrollbar_visible: BOOLEAN
			-- Drawn - and hit-testable - only when the thread overflows
			-- its own pane.
		do
			Result := max_scroll > 0.0
		end

	track_x: REAL_64
		do
			Result := x + width - scrollbar_width
		end

	track_y: REAL_64
		do
			Result := y + 2.0
		end

	track_h: REAL_64
		do
			Result := (height - 4.0).max (1.0)
		end

	Min_thumb_h: REAL_64 = 24.0
			-- Smallest the thumb ever draws at 1x, so it stays
			-- grabbable over a very long thread.

	thumb_height: REAL_64
			-- The thumb's height: the pane's share of the content,
			-- never smaller than `Min_thumb_h' (scaled) nor larger than
			-- the track itself.
		do
			if content_h > 0.0 then
				Result := height / content_h * track_h
			end
			Result := Result.max (Min_thumb_h * last_text_scale).min (track_h)
		ensure
			fits_track: Result > 0.0 and Result <= track_h
		end

	thumb_top: REAL_64
			-- The thumb's Y, from `scroll_y''s fraction of `max_scroll'.
		do
			if max_scroll > 0.0 then
				Result := track_y + (scroll_y / max_scroll) * (track_h - thumb_height)
			else
				Result := track_y
			end
		ensure
			within_track: Result >= track_y - 0.001
				and Result <= track_y + (track_h - thumb_height) + 0.001
		end

	is_dragging_thumb: BOOLEAN
			-- Is the pointer holding the thumb down right now? Drives
			-- the thumb's drag colour and gates `handle_drag'.

	scroll_to (a_y: REAL_64)
			-- The one door every scroll-changing entry point uses -
			-- `handle_wheel', a scrollbar drag or track click,
			-- PageUp/PageDown/Home/End, and `draw''s own once-per-frame
			-- clamp: land at `a_y', clamped to [0, `max_scroll'], and
			-- update `is_sticky' the same way everywhere.
		do
			scroll_y := a_y.max (0.0).min (max_scroll)
			is_sticky := scroll_y >= max_scroll - 2.0
		ensure
			clamped_low: scroll_y >= 0.0
			clamped_high: scroll_y <= max_scroll
			sticky_law: is_sticky = (scroll_y >= max_scroll - 2.0)
		end

feature -- Drawing

	Bubble_pad: REAL_64 = 10.0

	Line_h: REAL_64 = 19.0

	Space_w: REAL_64 = 4.5
			-- The toy path's inter-word gap, unchanged from 0.5.0 so a
			-- wrap that fitted then still fits now.

	Text_size: REAL_64 = 13.0
			-- The bubble's type size, in points on the toy path and (after
			-- the theme's scale) in PIXELS on the shaped path.

	Sel_alpha: REAL_64 = 0.32
			-- How solid the selection wash draws over the bubble.

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, j, px: INTEGER
			by, bw, bx, bh, max_w, inner_w, usable_w, sb_gutter, total_h: REAL_64
			recs: ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]
			rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]
			heights, widths: ARRAYED_LIST [REAL_64]
			is_shaped: BOOLEAN
			d: STRING_32
		do
			t := a_p.theme
			probe_painter := a_p
			scrollbar_width := Scrollbar_w * t.text_scale
			last_text_scale := t.text_scale
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- the gutter is reserved whether or not the bar draws
				-- this frame, so crossing the overflow line never
				-- reflows a bubble that was already on screen
			sb_gutter := scrollbar_width + 4.0
			usable_w := (width - sb_gutter).max (40.0)
			max_w := (usable_w * 0.72).max (60.0)
			inner_w := (max_w - 2.0 * Bubble_pad).max (16.0)
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
			px := (Text_size * t.text_scale).rounded.max (1)
			refresh_displays
			if attached a_p.shaping as al_kit then
					-- One measurement pass for the whole thread: unchanged
					-- messages come back from the layout cache having shaped
					-- nothing, so this is cheap on a still frame.
				refresh_layouts (al_kit, inner_w, px, a_p.is_resize_storm)
				is_shaped := layout_spans.count = messages.count
			end
			last_frame_shaped := is_shaped

				-- PASS 1: measure every bubble - no drawing, no scroll
				-- dependence - so `content_h' is the real total BEFORE
				-- anything gets clamped against it. See the class note.
			create heights.make (messages.count)
			create widths.make (messages.count)
			line_cache.wipe_out
			bubble_boxes.wipe_out
			total_h := 8.0
			from
				i := 1
			until
				i > messages.count
			loop
				if is_shaped then
					recs := shaped_lines_of (i)
					bh := lines_height (recs) + 2.0 * Bubble_pad
					bw := (widest_layout (i) + 2.0 * Bubble_pad).min (max_w)
				else
					recs := toy_lines_of (a_p, i, inner_w)
					bh := recs.count * Line_h + 2.0 * Bubble_pad - 4.0
					bw := widest_toy_line (a_p, i, recs) + 2.0 * Bubble_pad
				end
				line_cache.extend (recs)
				heights.extend (bh)
				widths.extend (bw)
				bubble_boxes.extend ([0.0, 0.0, 0.0, 0.0])
				total_h := total_h + bh + 8.0
				i := i + 1
			end
			content_h := total_h

				-- THE FIX: one clamp for the whole frame, against the
				-- true total - not one per bubble against a running sum.
			scroll_to (scroll_y)

				-- PASS 2: draw, at the now-stable offset.
			from
				i := 1
				by := y + 8.0 - scroll_y
			until
				i > messages.count
			loop
				bh := heights [i]
				bw := widths [i]
				inspect messages.i_th (i).role
				when Role_mine then
					bx := x + usable_w - bw - 10.0
				when Role_theirs then
					bx := x + 10.0
				else
					bx := x + (usable_w - bw) / 2.0
				end
				bubble_boxes.put_i_th ([bx, by, bw, bh], i)
				if by + bh > y and then by < y + height then
					inspect messages.i_th (i).role
					when Role_mine then
						a_p.set_color (t.wash_accent)
					when Role_theirs then
						a_p.set_color (t.surface_variant)
					else
						a_p.set_color_alpha (t.surface_variant, 0.5)
					end
					a_p.rrect_fill (bx, by, bw, bh, 7.0)
					if has_selection and then sel_message = i then
						draw_selection (a_p, i, bx + Bubble_pad, by + Bubble_pad)
					end
					if messages.i_th (i).role = Role_system then
						a_p.set_color (t.ink_muted)
					else
						a_p.set_color (t.ink)
					end
					if is_shaped then
							-- (x, y) here is a TOP-LEFT, not a baseline: the
							-- layout already knows each line's ascent.
						from
							j := 1
						until
							j > layout_spans.i_th (i).span
						loop
							a_p.draw_shaped_layout (
								shaped_layouts.i_th (layout_spans.i_th (i).base + j - 1),
								bx + Bubble_pad, by + Bubble_pad + paragraph_top (i, j))
							j := j + 1
						end
					else
						d := displays [i]
						a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
						from
							j := 1
						until
							j > line_cache.i_th (i).count
						loop
							rec := line_cache.i_th (i).i_th (j)
							a_p.text (bx + Bubble_pad, by + Bubble_pad + rec.top + 9.0,
								line_text (d, rec))
							j := j + 1
						end
					end
				end
				by := by + bh + 8.0
				i := i + 1
			end
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)

			if scrollbar_visible then
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (track_x, track_y, scrollbar_width - 2.0, track_h, 4.0 * last_text_scale)
				if is_dragging_thumb then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (track_x + 1.5, thumb_top, scrollbar_width - 5.0, thumb_height,
					3.0 * last_text_scale)
			end
		end

	refresh_layouts (a_kit: SW_SHAPING; a_inner_width: REAL_64; a_pixel_size: INTEGER;
			a_resize_storm: BOOLEAN)
			-- Bring `shaped_layouts' in step with `messages' at
			-- `a_inner_width' x `a_pixel_size' - ONE LAYOUT PER PARAGRAPH,
			-- because simple_shaping lays out a paragraph and treats an LF
			-- as a mere break OPPORTUNITY, shaping and painting the
			-- character itself (the square box Larry saw). Cutting first
			-- and laying out the pieces is the only way the break is real.
			--
			-- R10 lives in the first branch: while the frame is being
			-- dragged, a WIDTH change is ignored and the bubbles keep the
			-- layouts they have, so a drag costs zero shaping calls. A
			-- CONTENT change (a new message, a streamed token) is honoured
			-- immediately at the width already in force - a reply that
			-- arrives mid-drag must still appear.
		require
			width_positive: a_inner_width > 0.0
			size_positive: a_pixel_size > 0
		local
			w, i, k: INTEGER
			ps: ARRAYED_LIST [STRING_32]
		do
			if a_resize_storm and then not shaped_layouts.is_empty then
				w := laid_out_width
			else
				w := a_inner_width.floor.max (16)
			end
			if w /= laid_out_width or a_pixel_size /= laid_out_size
				or revision /= laid_out_revision
				or layout_spans.count /= messages.count
			then
				shaped_layouts.wipe_out
				layout_spans.wipe_out
				from
					i := 1
				until
					i > messages.count
				loop
					ps := paragraphs_of (messages.i_th (i).text)
					layout_spans.extend ([shaped_layouts.count + 1, ps.count])
					from
						k := 1
					until
						k > ps.count
					loop
						shaped_layouts.extend (a_kit.layout_for (ps.i_th (k), w, a_pixel_size))
						k := k + 1
					end
					i := i + 1
				end
				laid_out_width := w
				laid_out_size := a_pixel_size
				laid_out_revision := revision
			end
		ensure
			one_span_per_message: layout_spans.count = messages.count
			at_least_one_layout_each: shaped_layouts.count >= messages.count
			width_recorded: laid_out_width > 0
			content_current: laid_out_revision = revision
		end

feature {NONE} -- Drawing internals

	draw_selection (a_p: SW_PAINTER; a_message: INTEGER; a_ix, a_iy: REAL_64)
			-- (secret: its contract names the frame cache)
			-- Wash the selected characters of message `a_message', whose
			-- text starts at (`a_ix', `a_iy') - the bubble's inner
			-- top-left. One rectangle per visual line on the toy path;
			-- one per intersecting RUN on the shaped path, because a run
			-- is where a direction (and so a left-to-right span) is
			-- constant.
		require
			in_range: a_message >= 1 and a_message <= line_cache.count
		local
			j, lo, hi: INTEGER
			rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]
			x0, x1: REAL_64
			d: STRING_32
		do
			a_p.set_color_alpha (a_p.theme.accent, Sel_alpha)
			d := displays.i_th (a_message)
			from
				j := 1
			until
				j > line_cache.i_th (a_message).count
			loop
				rec := line_cache.i_th (a_message).i_th (j)
				lo := (sel_low + 1).max (rec.lo)
				hi := sel_high.min (rec.hi)
				if hi >= lo then
					if last_frame_shaped then
						draw_shaped_selection_line (a_p, a_message, rec, lo, hi, a_ix, a_iy)
					else
						a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
						x0 := a_p.advance (d.substring (rec.lo, lo - 1))
						x1 := a_p.advance (d.substring (rec.lo, hi))
						a_p.rrect_fill (a_ix + x0, a_iy + rec.top, (x1 - x0).max (1.0), rec.h, 2.0)
					end
				end
				j := j + 1
			end
		end

feature -- Input

	accepts_focus: BOOLEAN
			-- Yes: once the pane has been clicked, PageUp/PageDown/
			-- Home/End move it, the same ring SW_LIST joins - and Ctrl+C
			-- copies whatever the pointer selected.
		do
			Result := True
		end

	cursor_kind: INTEGER
			-- An I-beam: the bubbles are selectable text now, and the
			-- pointer has to say so before the user tries.
		do
			Result := 1
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			scroll_to (scroll_y - a_delta / 120.0 * 48.0)
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- The scrollbar first: press the thumb to start a drag, press
			-- the bare track to page toward the click. Then the BUBBLES: a
			-- press inside one starts a text selection and IS consumed
			-- (the widget needs the pointer capture to receive the drag).
			-- A press on bare pane clears the selection and is NOT
			-- consumed, so it still bubbles up per the base default.
		local
			hit: TUPLE [message, offset: INTEGER]
		do
			if scrollbar_visible and then a_px >= track_x then
				if a_py >= thumb_top and a_py <= thumb_top + thumb_height then
					is_dragging_thumb := True
					drag_grab_offset := a_py - thumb_top
				elseif a_py < thumb_top then
					scroll_to (scroll_y - height)
				else
					scroll_to (scroll_y + height)
				end
				Result := True
			else
				hit := hit_test (a_px, a_py)
				if hit.message > 0 then
					sel_message := hit.message
					sel_anchor := hit.offset
					sel_caret := hit.offset
					is_selecting := True
					Result := True
				else
					clear_selection
				end
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- Take the word under the pointer, the editor convention.
		local
			hit: TUPLE [message, offset: INTEGER]
		do
			hit := hit_test (a_px, a_py)
			if hit.message > 0 then
				select_word_at (hit.message, hit.offset)
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		local
			span: REAL_64
			hit: TUPLE [message, offset: INTEGER]
		do
			if is_dragging_thumb then
				span := (track_h - thumb_height).max (1.0)
				scroll_to (((a_py - drag_grab_offset - track_y) / span) * max_scroll)
			elseif is_selecting and then sel_message > 0 then
					-- clamped INTO the anchor's own bubble: dragging away
					-- runs the selection to that bubble's end, never into
					-- the next speaker's words
				hit := hit_in_message (sel_message, a_px, a_py)
				sel_caret := hit.offset
			end
		end

	handle_release (a_x, a_y: INTEGER)
		do
			is_dragging_thumb := False
			is_selecting := False
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- PageDown 34, PageUp 33, Home 36, End 35 - SW_LIST's own
			-- virtual-key vocabulary (Win32 VK_NEXT/VK_PRIOR/VK_HOME/VK_END).
		do
			inspect a_vk
			when 34 then
				scroll_to (scroll_y + height)
			when 33 then
				scroll_to (scroll_y - height)
			when 36 then
				scroll_to (0.0)
			when 35 then
				scroll_to (max_scroll)
			else
			end
		end

	handle_char (a_code: INTEGER)
			-- Ctrl+C copies, Escape clears - the two characters a
			-- read-only text surface owes its reader. Both arrive as
			-- WM_CHAR control codes, which is where SW_TEXT_BOX has always
			-- read them too; a window-level accelerator that CLAIMS Ctrl+C
			-- takes precedence and this is never reached.
		do
			if a_code = 3 then
				copy_selection
			elseif a_code = 27 then
				clear_selection
			end
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- Copy, and the two ways to change what Copy would take. A
			-- right-click outside the current selection moves it to the
			-- bubble under the pointer first, as every editor does.
		local
			hit: TUPLE [message, offset: INTEGER]
		do
			hit := hit_test (a_px, a_py)
			if hit.message > 0 and then (not has_selection or else sel_message /= hit.message) then
				select_word_at (hit.message, hit.offset)
			end
			create Result.make
			Result.add_item ("Copy", "Ctrl+C", has_selection, agent copy_selection)
			if hit.message > 0 then
				Result.add_item ("Select &Message", "", True, agent select_message (hit.message))
			end
			Result.add_item ("Select &None", "Esc", has_selection, agent clear_selection)
		ensure then
			offered: Result /= Void
		end

feature -- Hit testing

	hit_test (a_px, a_py: REAL_64): TUPLE [message, offset: INTEGER]
			-- Which message, and which caret offset inside it, the point
			-- names; message 0 when the point is on no bubble. Answered
			-- from the geometry the LAST `draw' recorded, which is why
			-- this needs no painter of its own - only the one `draw'
			-- cached.
		local
			i: INTEGER
			b: TUPLE [bx, by, bw, bh: REAL_64]
		do
			Result := [0, 0]
			from
				i := 1
			until
				i > bubble_boxes.count or Result.message /= 0
			loop
				b := bubble_boxes.i_th (i)
				if b.bw > 0.0 and then a_px >= b.bx and then a_px <= b.bx + b.bw
					and then a_py >= b.by and then a_py <= b.by + b.bh
				then
					Result := hit_in_message (i, a_px, a_py)
				end
				i := i + 1
			end
		ensure
			named: Result.message >= 0 and Result.message <= messages.count
		end

	hit_in_message (a_message: INTEGER; a_px, a_py: REAL_64): TUPLE [message, offset: INTEGER]
			-- The caret offset the point names WITHIN message
			-- `a_message', clamped to that message's own ends - the drag
			-- rule that keeps a selection inside one bubble.
		require
			in_range: a_message >= 1 and a_message <= messages.count
		local
			b: TUPLE [bx, by, bw, bh: REAL_64]
			recs: ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]
			rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]
			j: INTEGER
			ly, ix: REAL_64
			found: BOOLEAN
		do
			Result := [a_message, 0]
			if a_message <= bubble_boxes.count and then a_message <= line_cache.count
				and then a_message <= displays.count
			then
				b := bubble_boxes.i_th (a_message)
				recs := line_cache.i_th (a_message)
				if not recs.is_empty then
					ly := a_py - (b.by + Bubble_pad)
					ix := a_px - (b.bx + Bubble_pad)
					rec := recs.i_th (recs.count)
					from
						j := 1
					until
						j > recs.count or found
					loop
						if ly < recs.i_th (j).top + recs.i_th (j).h then
							rec := recs.i_th (j)
							found := True
						end
						j := j + 1
					end
					if ly < 0.0 then
						rec := recs.i_th (1)
					end
					Result := [a_message, offset_in_line (a_message, rec, ix)]
				end
			end
		ensure
			same_message: Result.message = a_message
			non_negative: Result.offset >= 0
		end

feature {NONE} -- Hit testing: the toy path

	offset_in_line (a_message: INTEGER; a_rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER];
			a_x: REAL_64): INTEGER
			-- The caret offset nearest `a_x' (bubble-inner-relative) on
			-- the visual line `a_rec' of message `a_message'.
		require
			in_range: a_message >= 1 and a_message <= displays.count
		local
			d: STRING_32
			k: INTEGER
			best, dist, cx: REAL_64
			first: BOOLEAN
		do
			Result := a_rec.lo - 1
			if last_frame_shaped then
				Result := shaped_offset_in_line (a_message, a_rec, a_x)
			elseif attached probe_painter as p then
				d := displays.i_th (a_message)
				p.font ({SW_PAINTER}.Role_ui, Text_size, False)
				first := True
				from
					k := a_rec.lo - 1
				until
					k > a_rec.hi
				loop
					cx := p.advance (d.substring (a_rec.lo, k))
					dist := (cx - a_x).abs
					if first or else dist < best then
						best := dist
						Result := k
						first := False
					end
					k := k + 1
				end
			end
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Hit testing: the shaped path

	shaped_offset_in_line (a_message: INTEGER;
			a_rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER];
			a_x: REAL_64): INTEGER
			-- `offset_in_line' over a SHAPED line: the caret boundaries
			-- are the CLUSTER edges GLYPH_RUN publishes (`cluster_map'
			-- into `x_positions'), walked run by run in visual order.
			-- SHAPED_LINE reserves `character_index_at_x' for a future
			-- cycle and does not implement it, so this is the boundary
			-- walk, done once, here.
		require
			in_range: a_message >= 1 and a_message <= layout_spans.count
		local
			lay: SHAPED_LAYOUT
			ln: SHAPED_LINE
			rn: SHAPED_RUN
			r, poff, bo: INTEGER
			run_left, best, dist, bx: REAL_64
			first: BOOLEAN
		do
			Result := a_rec.lo - 1
			lay := shaped_layouts.i_th (layout_spans.i_th (a_message).base + a_rec.pidx - 1)
			if a_rec.lidx >= 1 and then a_rec.lidx <= lay.lines.count then
				ln := lay.lines.i_th (a_rec.lidx)
				poff := paragraph_offset (a_message, a_rec.pidx)
				first := True
				from
					r := 1
				until
					r > ln.runs.count
				loop
					rn := ln.runs.i_th (r)
					from
						bo := 0
					until
						bo > rn.source_count
					loop
						bx := run_left + run_boundary_x (rn, bo)
						dist := (bx - a_x).abs
						if first or else dist < best then
							best := dist
							Result := poff + run_boundary_offset (rn, bo) - 1
							first := False
						end
						bo := bo + 1
					end
					run_left := run_left + rn.advance_width
					r := r + 1
				end
			end
		ensure
			non_negative: Result >= 0
		end

	run_boundary_x (a_run: SHAPED_RUN; a_k: INTEGER): REAL_64
			-- The x, run-relative, of the `a_k'-th caret boundary of
			-- `a_run' counting from its VISUAL LEFT (0 = the run's left
			-- edge, `source_count' = its right edge).
		require
			in_range: a_k >= 0 and a_k <= a_run.source_count
		do
			if a_k = a_run.source_count then
				Result := a_run.advance_width
			elseif attached {GLYPH_RUN} a_run as g then
				if g.is_rtl then
					Result := cluster_x (g, g.source_count - a_k)
				else
					Result := cluster_x (g, a_k + 1)
				end
			else
					-- an IMAGE_RUN is one indivisible picture
				Result := (a_k.to_double / a_run.source_count.to_double) * a_run.advance_width
			end
		ensure
			non_negative: Result >= 0.0
		end

	run_boundary_offset (a_run: SHAPED_RUN; a_k: INTEGER): INTEGER
			-- The PARAGRAPH character position (1-based, as a caret
			-- offset + 1) that the `a_k'-th visual boundary of `a_run'
			-- stands for. In a right-to-left run the boundary at a
			-- cluster's LEFT edge is the caret AFTER that character,
			-- which is the whole of what "RTL hit-testing" means here.
		require
			in_range: a_k >= 0 and a_k <= a_run.source_count
		do
			if a_run.is_rtl then
				Result := a_run.source_start + a_run.source_count - a_k
			else
				Result := a_run.source_start + a_k
			end
		ensure
			positive: Result >= 1
		end

	cluster_x (a_run: GLYPH_RUN; a_char: INTEGER): REAL_64
			-- The x of the cluster that renders paragraph-relative
			-- character `a_char' of `a_run' (1 .. `source_count').
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		local
			g: INTEGER
		do
			g := a_run.cluster_map [a_run.cluster_map.lower + a_char - 1]
			if g >= 1 and then g <= a_run.x_positions.count then
				Result := a_run.x_positions [a_run.x_positions.lower + g - 1]
			end
		end

	draw_shaped_selection_line (a_p: SW_PAINTER; a_message: INTEGER;
			a_rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER];
			a_lo, a_hi: INTEGER; a_ix, a_iy: REAL_64)
			-- Wash characters `a_lo' .. `a_hi' (display offsets) of one
			-- shaped line - one rectangle per intersecting run, because a
			-- run is where the direction, and so a left-to-right pixel
			-- span, is constant.
		require
			in_range: a_message >= 1 and a_message <= layout_spans.count
		local
			lay: SHAPED_LAYOUT
			ln: SHAPED_LINE
			rn: SHAPED_RUN
			r, poff, lo, hi, c: INTEGER
			run_left, x0, x1, cl, cr: REAL_64
			first: BOOLEAN
		do
			lay := shaped_layouts.i_th (layout_spans.i_th (a_message).base + a_rec.pidx - 1)
			if a_rec.lidx >= 1 and then a_rec.lidx <= lay.lines.count then
				ln := lay.lines.i_th (a_rec.lidx)
				poff := paragraph_offset (a_message, a_rec.pidx)
				from
					r := 1
				until
					r > ln.runs.count
				loop
					rn := ln.runs.i_th (r)
					lo := (a_lo - poff).max (rn.source_start)
					hi := (a_hi - poff).min (rn.source_start + rn.source_count - 1)
					if hi >= lo then
						first := True
						from
							c := lo
						until
							c > hi
						loop
							cl := char_left_x (rn, c - rn.source_start + 1)
							cr := char_right_x (rn, c - rn.source_start + 1)
							if first then
								x0 := cl.min (cr)
								x1 := cl.max (cr)
								first := False
							else
								x0 := x0.min (cl.min (cr))
								x1 := x1.max (cl.max (cr))
							end
							c := c + 1
						end
						a_p.rrect_fill (a_ix + run_left + x0, a_iy + a_rec.top,
							(x1 - x0).max (1.0), a_rec.h, 2.0)
					end
					run_left := run_left + rn.advance_width
					r := r + 1
				end
			end
		end

	char_left_x (a_run: SHAPED_RUN; a_char: INTEGER): REAL_64
			-- The left pixel edge of run-relative character `a_char'.
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		do
			if attached {GLYPH_RUN} a_run as g then
				Result := cluster_x (g, a_char)
			end
		end

	char_right_x (a_run: SHAPED_RUN; a_char: INTEGER): REAL_64
			-- The right pixel edge of run-relative character `a_char':
			-- the NEXT cluster's left edge in a left-to-right run, the
			-- PREVIOUS one's in a right-to-left run, and the run's own
			-- right edge at whichever end that is.
		require
			in_range: a_char >= 1 and a_char <= a_run.source_count
		do
			Result := a_run.advance_width
			if attached {GLYPH_RUN} a_run as g then
				if g.is_rtl then
					if a_char > 1 then
						Result := cluster_x (g, a_char - 1)
					end
				elseif a_char < g.source_count then
					Result := cluster_x (g, a_char + 1)
				end
			end
		end

feature {NONE} -- Drag state

	drag_grab_offset: REAL_64
			-- Where inside the thumb the press landed, so a drag keeps
			-- the pointer over the same spot on the thumb instead of
			-- snapping its top to the cursor.

feature {NONE} -- Frame cache

	probe_painter: detachable SW_PAINTER
			-- The painter of the most recent `draw'. Hit-testing has no
			-- painter of its own and the toy path's caret positions can
			-- only be measured in a font; SW_MENU_BAR keeps the same
			-- reference for the same reason.

	last_frame_shaped: BOOLEAN
			-- Did the most recent `draw' use the shaped path? Decides
			-- which boundary walk hit-testing and the selection wash use.

	displays: ARRAYED_LIST [STRING_32]
			-- `display_text' per message, rebuilt on a content change -
			-- not on every frame, and never inside a hit-test.

	displayed_revision: INTEGER
			-- `revision' as of the last `refresh_displays'.

	line_cache: ARRAYED_LIST [ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]]
			-- Per message, its visual lines: the display-text range each
			-- one covers, its top and height inside the bubble's inner
			-- box, and (shaped path only) which paragraph layout and
			-- which of its lines it came from.

	bubble_boxes: ARRAYED_LIST [TUPLE [bx, by, bw, bh: REAL_64]]
			-- Per message, the bubble rectangle the last frame drew, in
			-- WINDOW coordinates - so a click can find it without
			-- re-deriving the layout.

	refresh_displays
			-- Bring `displays' in step with `messages'.
		local
			i: INTEGER
		do
			if displayed_revision /= revision or else displays.count /= messages.count then
				displays.wipe_out
				from
					i := 1
				until
					i > messages.count
				loop
					displays.extend (display_text (i))
					i := i + 1
				end
				displayed_revision := revision
			end
		ensure
			one_per_message: displays.count = messages.count
		end

	paragraph_offset (a_message, a_paragraph: INTEGER): INTEGER
			-- The display-text offset just BEFORE paragraph
			-- `a_paragraph' of message `a_message' - so display position
			-- = this + the paragraph-relative position.
		require
			in_range: a_message >= 1 and a_message <= layout_spans.count
		local
			k: INTEGER
		do
			from
				k := 1
			until
				k >= a_paragraph
			loop
				Result := Result
					+ shaped_layouts.i_th (layout_spans.i_th (a_message).base + k - 1).source_text.count + 1
				k := k + 1
			end
		ensure
			non_negative: Result >= 0
		end

	paragraph_top (a_message, a_paragraph: INTEGER): REAL_64
			-- How far down the bubble's inner box paragraph
			-- `a_paragraph' of message `a_message' starts.
		require
			in_range: a_message >= 1 and a_message <= layout_spans.count
		local
			k: INTEGER
		do
			from
				k := 1
			until
				k >= a_paragraph
			loop
				Result := Result
					+ shaped_layouts.i_th (layout_spans.i_th (a_message).base + k - 1).total_height
				k := k + 1
			end
		ensure
			non_negative: Result >= 0.0
		end

	shaped_lines_of (a_message: INTEGER): ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]
			-- The visual lines of message `a_message' on the shaped path,
			-- across all its paragraph layouts.
		require
			in_range: a_message >= 1 and a_message <= layout_spans.count
		local
			k, j, poff: INTEGER
			lay: SHAPED_LAYOUT
			ln: SHAPED_LINE
			top: REAL_64
		do
			create Result.make (4)
			from
				k := 1
			until
				k > layout_spans.i_th (a_message).span
			loop
				lay := shaped_layouts.i_th (layout_spans.i_th (a_message).base + k - 1)
				from
					j := 1
				until
					j > lay.lines.count
				loop
					ln := lay.lines.i_th (j)
					Result.extend ([poff + ln.source_start,
						poff + ln.source_start + ln.source_count - 1,
						top, ln.height, k, j])
					top := top + ln.height
					j := j + 1
				end
				poff := poff + lay.source_text.count + 1
				k := k + 1
			end
		ensure
			at_least_one: not Result.is_empty
		end

	toy_lines_of (a_p: SW_PAINTER; a_message: INTEGER; a_width: REAL_64):
			ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]
			-- The visual lines of message `a_message' on the toy path:
			-- the greedy word wrap of 0.5.0, applied WITHIN each
			-- paragraph and expressed as SOURCE RANGES rather than
			-- rebuilt strings - so a selection can name characters
			-- instead of copies of them.
		require
			in_range: a_message >= 1 and a_message <= displays.count
			width_positive: a_width > 0.0
		local
			d: STRING_32
			p_lo, i, n: INTEGER
			spans: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			top: REAL_64
		do
			create Result.make (4)
			d := displays.i_th (a_message)
			n := d.count
			a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
			from
				p_lo := 1
				i := 1
			until
				i > n + 1
			loop
				if i > n or else d.item (i) = '%N' then
					spans := wrap_spans (a_p, d, p_lo, i - 1, a_width)
					across
						spans as sp
					loop
						Result.extend ([sp.lo, sp.hi, top, Line_h, 0, 0])
						top := top + Line_h
					end
					p_lo := i + 1
				end
				i := i + 1
			end
		ensure
			at_least_one: not Result.is_empty
		end

	wrap_spans (a_p: SW_PAINTER; a_text: STRING_32; a_lo, a_hi: INTEGER; a_width: REAL_64):
			ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- Greedy word wrap of ONE paragraph - `a_text' characters
			-- `a_lo' .. `a_hi', which contain no line break - as the
			-- source ranges of its visual lines. An empty paragraph is
			-- one empty range (`hi' = `lo' - 1), which is one empty line.
		require
			paragraph_sane: a_lo >= 1 and a_hi >= a_lo - 1 and a_hi <= a_text.count
			width_positive: a_width > 0.0
		local
			i, ws, we, line_lo, last_end: INTEGER
			cx, ww: REAL_64
		do
			create Result.make (4)
			line_lo := a_lo
			last_end := a_lo - 1
			from
				i := a_lo
			until
				i > a_hi
			loop
				from
				until
					i > a_hi or else a_text.item (i) /= ' '
				loop
					i := i + 1
				end
				if i <= a_hi then
					ws := i
					from
					until
						i > a_hi or else a_text.item (i) = ' '
					loop
						i := i + 1
					end
					we := i - 1
					ww := a_p.advance (a_text.substring (ws, we))
					if last_end < line_lo then
						cx := ww
						last_end := we
					elseif cx + Space_w + ww > a_width then
						Result.extend ([line_lo, last_end])
						line_lo := ws
						cx := ww
						last_end := we
					else
						cx := cx + Space_w + ww
						last_end := we
					end
				end
			end
			if last_end >= line_lo then
				Result.extend ([line_lo, last_end])
			else
				Result.extend ([a_lo, a_lo - 1])
			end
		ensure
			at_least_one: not Result.is_empty
		end

	line_text (a_display: STRING_32; a_rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]): STRING_32
			-- What visual line `a_rec' actually paints.
		do
			if a_rec.hi >= a_rec.lo then
				Result := a_display.substring (a_rec.lo, a_rec.hi)
			else
				create Result.make_empty
			end
		end

	lines_height (a_recs: ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]): REAL_64
			-- The total height of a message's visual lines.
		do
			across
				a_recs as r
			loop
				Result := Result + r.h
			end
		ensure
			non_negative: Result >= 0.0
		end

	widest_layout (a_message: INTEGER): REAL_64
			-- The widest paragraph layout of message `a_message'.
		require
			in_range: a_message >= 1 and a_message <= layout_spans.count
		local
			k: INTEGER
		do
			from
				k := 1
			until
				k > layout_spans.i_th (a_message).span
			loop
				Result := Result.max (
					shaped_layouts.i_th (layout_spans.i_th (a_message).base + k - 1).total_width)
				k := k + 1
			end
		end

	widest_toy_line (a_p: SW_PAINTER; a_message: INTEGER;
			a_recs: ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]): REAL_64
			-- The widest visual line of message `a_message' on the toy
			-- path, in the bubble's own font.
		require
			in_range: a_message >= 1 and a_message <= displays.count
		local
			d: STRING_32
		do
			d := displays.i_th (a_message)
			a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
			across
				a_recs as r
			loop
				Result := Result.max (a_p.advance (line_text (d, r)))
			end
		end

feature -- Text machinery

	wrapped (a_p: SW_PAINTER; a_text: STRING_32; a_width: REAL_64): ARRAYED_LIST [STRING_32]
			-- Greedy word wrap in the current font, line breaks honoured:
			-- the 0.5.0 query, kept because it is how the toy path's
			-- wrapping is stated, now expressed over `paragraphs_of' and
			-- `wrap_spans' so there is ONE wrap in this class.
		local
			d: STRING_32
			k: INTEGER
			ps: ARRAYED_LIST [STRING_32]
		do
			create Result.make (4)
			ps := paragraphs_of (a_text)
			from
				k := 1
			until
				k > ps.count
			loop
				d := ps.i_th (k)
				across
					wrap_spans (a_p, d, 1, d.count, a_width) as sp
				loop
					if sp.hi >= sp.lo then
						Result.extend (d.substring (sp.lo, sp.hi))
					else
						Result.extend ({STRING_32} "")
					end
				end
				k := k + 1
			end
		ensure
			at_least_one: not Result.is_empty
		end

invariant
	messages_attached: messages /= Void
	layouts_attached: shaped_layouts /= Void
	spans_attached: layout_spans /= Void
	displays_attached: displays /= Void
	line_cache_attached: line_cache /= Void
	bubble_boxes_attached: bubble_boxes /= Void
	spans_match_when_present: not shaped_layouts.is_empty implies
		layout_spans.count = messages.count
	a_layout_per_paragraph: not shaped_layouts.is_empty implies
		shaped_layouts.count >= messages.count
	revision_non_negative: revision >= 0 and laid_out_revision >= 0
	scrollbar_width_positive: scrollbar_width > 0.0
	text_scale_recorded_positive: last_text_scale > 0.0
	selection_names_a_message: sel_message >= 0 and sel_message <= messages.count
	selection_offsets_non_negative: sel_anchor >= 0 and sel_caret >= 0
	no_selection_without_a_message: sel_message = 0 implies
		(sel_anchor = 0 and sel_caret = 0)

end
