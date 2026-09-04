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

		BETWEEN TWO FRAMES. A layout can be made only by
		`SW_SHAPING.layout_for', and only at an inner width and a pixel
		size the widget does not learn until the painter hands them over
		inside `draw'. So `add_message' CANNOT keep `layout_spans' in
		step with `messages': to do it, a content command would have to
		shape - which means inventing a width, or demanding a painter
		from a caller who has one only while it is painting.

		The counts are therefore equal exactly when the layouts are
		CURRENT, and `laid_out_revision = revision' is the widget's own
		answer to that. Every content change bumps `revision';
		`refresh_layouts' rebuilds and then, and only then, records it.
		The equality is a POSTCONDITION of that rebuild, and the
		invariant states it under that guard - not unconditionally, which
		made `add_message' after a first shaped frame fail its own class
		invariant in any build that checks one. A live chat client does
		exactly that on every event after its first frame.

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

		MUTATION (0.7.0). A bubble can now be CHANGED after it is drawn -
		`set_message', `mark_edited', `tombstone', `set_reactions',
		`set_reply_quote' - because a chat server folds edit, delete and
		reaction events over the message they name, and until this cycle
		the only public model here was `add_message' and
		`append_to_last'. Nothing new had to be invented to make that
		safe: every one of them is a CONTENT CHANGE, and a content change
		has meant "bump `revision'" since 0.5.0. `laid_out_revision' then
		lags, `spans_match_when_current' goes quiet for exactly one
		frame, `refresh_layouts' rebuilds and records - the same door
		`add_message' has always gone through. That is the whole of why
		these commands cannot break the invariant 0.6.1 wrote.

		A DELETE IS A TOMBSTONE, NEVER A GAP. `tombstone' does not remove
		the message: the bubble stays where it is, at reduced height, in
		a muted "message deleted" placeholder, because the ORDER of a
		thread is part of its record and a vanished bubble silently
		rewrites who answered whom. It does, however, really destroy the
		text - `messages.i_th (i).text' is emptied, not hidden - so there
		is nothing left for a selection to reach and nothing for
		`copy_selection' to hand the clipboard. Hiding it behind a flag
		would leave the words one query away from anyone with a debugger,
		which is not what "deleted" means.

		THE DECORATION BANDS. A bubble is now up to four stacked bands
		inside its own padding: a one-line REPLY QUOTE (elided at the
		bubble's inner width - a quote that wrapped would be a second
		message), the TEXT, an "edited" MARKER, and a REACTION ROW of
		emoji-and-count chips (the reader's own outlined). Each band is
		MEASURED, never assumed: the quote and the chips' emoji go
		through the shaping kit when there is one, so a Hebrew quote
		reads right-to-left and a reaction carries the same Noto picture
		as the bubbles do; without a kit both fall back to cairo's toy
		metrics, which is the same two-path rule the rest of this class
		obeys. The bands change the bubble's height, so they change
		`content_h' - and stickiness is preserved the way `add_message'
		preserves it: a thread parked at the tail is re-parked, a reader
		who has scrolled up is not yanked.

		THE MENU'S TWO QUESTIONS. A host that puts a per-message menu on
		a right-click has to know WHICH bubble the click landed on
		(`message_at') and, if it landed on a reaction chip, WHICH emoji
		(`reaction_at'). Both are answered from the geometry the last
		`draw' recorded - the same frame cache `hit_test' has used since
		0.6.0 - so neither needs a painter of its own.
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

	Role_keep: INTEGER = 0
			-- Not a role: what `set_message' is passed when the edit
			-- changes the words and must leave the speaker alone. A
			-- server's edit event carries new text and no new author, so
			-- the common call has nothing honest to put in the role slot.

feature {NONE} -- Initialization

	make
		do
			create messages.make (16)
			create shaped_layouts.make (16)
			create layout_spans.make (16)
			create displays.make (16)
			create line_cache.make (16)
			create bubble_boxes.make (16)
			create decor.make (16)
			create chip_sets.make (16)
			create quote_layouts.make (16)
			create chip_layouts.make (16)
			create head_bands.make (16)
			create body_bands.make (16)
			create edit_bands.make (16)
			create chip_boxes.make (16)
			create drawn_quotes.make (16)
			is_sticky := True
			scrollbar_width := Scrollbar_w
			last_text_scale := 1.0
			displayed_revision := -1
			decor_revision := -1
		ensure
			nothing_laid_out: shaped_layouts.is_empty
			nothing_selected: not has_selection
			nothing_decorated: decor.is_empty and chip_sets.is_empty
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
			-- One entry per message OF THE LAST LAID-OUT FRAME: that
			-- message's paragraph layouts are
			-- `shaped_layouts [base .. base + span - 1]'.
			--
			-- BETWEEN FRAMES IT LAGS, and that is not a defect - see
			-- BETWEEN TWO FRAMES in the class note. `laid_out_revision =
			-- revision' is the question "are these current?", and the
			-- invariant asks it before demanding one span per message.

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
			decor.extend ([False, False, {STRING_32} "", {STRING_32} ""])
			chip_sets.extend (create {ARRAYED_LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]]}.make (2))
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
					-- clamped to the true bottom at next draw
			end
		ensure
			grew: count = old count + 1
			undecorated: not is_edited (count) and not is_tombstone (count)
				and reactions_of (count).is_empty and not has_reply_quote (count)
		end

	append_to_last (a_text: READABLE_STRING_GENERAL)
			-- Streaming: grow the last message in place.
		require
			aboard: count > 0
			alive: not is_tombstone (count)
		do
			messages.last.text.append_string_general (a_text)
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		end

feature -- Element change: mutation (0.7.0)

	set_message (a_message, a_role: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Replace what bubble `a_message' says, and who said it when
			-- `a_role' is a real role rather than `Role_keep'. THE ONLY
			-- MECHANISM IS THE ONE 0.5.0 ALREADY HAD: `revision' is
			-- bumped, so `laid_out_revision' lags, so the shaped spans
			-- and the toy displays are both stale until the next frame
			-- rebuilds them - and `spans_match_when_current' asks about
			-- currency before it demands one span per message. There is
			-- nothing to re-shape here and no width to invent.
			--
			-- The selection is dropped when it lived in this bubble: its
			-- offsets are offsets into text that no longer exists, and a
			-- selection that survives its own text is how a clipboard
			-- ends up with somebody else's words.
		require
			in_range: a_message >= 1 and a_message <= count
			role_known_or_kept: a_role = Role_keep
				or (a_role >= Role_mine and a_role <= Role_system)
			alive: not is_tombstone (a_message)
		local
			s: STRING_32
			r: INTEGER
		do
			create s.make_from_string_general (a_text)
			if a_role = Role_keep then
				r := messages.i_th (a_message).role
			else
				r := a_role
			end
			messages.put_i_th ([r, s], a_message)
			if sel_message = a_message then
				clear_selection
			end
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		ensure
			text_replaced: messages.i_th (a_message).text.same_string_general (a_text)
			role_set_when_given: a_role /= Role_keep implies
				messages.i_th (a_message).role = a_role
			role_kept_when_not: a_role = Role_keep implies
				messages.i_th (a_message).role = old messages.i_th (a_message).role
			place_kept: count = old count
			bumped: revision = old revision + 1
			no_stale_selection: sel_message /= a_message
		end

	mark_edited (a_message: INTEGER)
			-- Say that bubble `a_message' has been edited: it grows a
			-- small muted marker band under its text. Idempotent, and it
			-- bumps `revision' either way, because the band is height and
			-- height is measured in a frame this class has not drawn yet.
		require
			in_range: a_message >= 1 and a_message <= count
			alive: not is_tombstone (a_message)
		do
			decor.put_i_th ([True, False, decor.i_th (a_message).quote_author,
				decor.i_th (a_message).quote_text], a_message)
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		ensure
			marked: is_edited (a_message)
			still_alive: not is_tombstone (a_message)
			bumped: revision = old revision + 1
		end

	tombstone (a_message: INTEGER)
			-- Delete bubble `a_message' THE WAY A THREAD CAN AFFORD TO:
			-- the bubble keeps its place and its order and becomes a
			-- muted, reduced-height "message deleted" placeholder. The
			-- text is really destroyed - emptied, not hidden - so no
			-- selection can reach it and `copy_selection' has nothing to
			-- take. Every decoration goes with it: a reaction to a
			-- deleted message, or a quote inside one, is a claim about
			-- words nobody can read.
			--
			-- Terminal and idempotent: `set_message', `mark_edited',
			-- `set_reactions' and `set_reply_quote' all require a live
			-- message, so a tombstone cannot be edited back into speech.
		require
			in_range: a_message >= 1 and a_message <= count
		do
			messages.put_i_th ([messages.i_th (a_message).role, {STRING_32} ""], a_message)
			decor.put_i_th ([False, True, {STRING_32} "", {STRING_32} ""], a_message)
			chip_sets.put_i_th (
				create {ARRAYED_LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]]}.make (2),
				a_message)
			if sel_message = a_message then
				clear_selection
			end
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		ensure
			tombstoned: is_tombstone (a_message)
			text_destroyed: messages.i_th (a_message).text.is_empty
			nothing_to_copy: display_text (a_message).is_empty
			reactions_gone: reactions_of (a_message).is_empty
			quote_gone: not has_reply_quote (a_message)
			marker_gone: not is_edited (a_message)
			place_kept: count = old count
			no_stale_selection: sel_message /= a_message
			bumped: revision = old revision + 1
		end

	set_reactions (a_message: INTEGER;
			a_list: LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]])
			-- Give bubble `a_message' the reaction row `a_list' - one
			-- chip per emoji, carrying how many people sent it and
			-- whether the reader is one of them. REPLACES the row
			-- wholesale, because the server has already deduped per
			-- person per emoji and a widget that tried to merge would be
			-- keeping a second, worse tally.
			--
			-- The chips are COPIED in: a caller that reuses its list for
			-- the next event must not be able to rewrite a drawn frame.
			--
			-- The label is `tally' and not `count' for one reason:
			-- TUPLE already has a `count', and a labelled field cannot
			-- shadow it.
		require
			in_range: a_message >= 1 and a_message <= count
			alive: not is_tombstone (a_message)
			list_attached: a_list /= Void
			tallies_positive: across a_list as r all r.tally >= 1 end
			emoji_present: across a_list as r all not r.emoji.is_empty end
		local
			l: ARRAYED_LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]]
		do
			create l.make (a_list.count)
			across
				a_list as r
			loop
				l.extend ([r.emoji.twin, r.tally, r.mine])
			end
			chip_sets.put_i_th (l, a_message)
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		ensure
			one_chip_each: reactions_of (a_message).count = a_list.count
			bumped: revision = old revision + 1
		end

	set_reply_quote (a_message: INTEGER; a_author, a_text: READABLE_STRING_GENERAL)
			-- Make bubble `a_message' a REPLY: it grows a one-line quoted
			-- header naming `a_author' and showing `a_text', elided at the
			-- bubble's inner width. One line, always - a quote allowed to
			-- wrap stops being a header and becomes a second message.
			-- Line breaks inside `a_text' are flattened to spaces for the
			-- same reason.
			--
			-- Two empty strings clear the quote, which is how an event
			-- that un-parents a message is applied.
		require
			in_range: a_message >= 1 and a_message <= count
			alive: not is_tombstone (a_message)
		local
			au, tx: STRING_32
		do
			create au.make_from_string_general (a_author)
			create tx.make_from_string_general (a_text)
			decor.put_i_th ([decor.i_th (a_message).edited, False, au, tx], a_message)
			revision := revision + 1
			if is_sticky then
				scroll_y := {REAL_64}.max_value / 4.0
			end
		ensure
			quoted: has_reply_quote (a_message) =
				(not a_author.is_empty or not a_text.is_empty)
			bumped: revision = old revision + 1
		end

feature -- Per-message decoration

	is_edited (a_message: INTEGER): BOOLEAN
			-- Does bubble `a_message' carry the "edited" marker?
		require
			in_range: a_message >= 1 and a_message <= count
		do
			Result := decor.i_th (a_message).edited
		end

	is_tombstone (a_message: INTEGER): BOOLEAN
			-- Has bubble `a_message' been deleted - drawn as a muted
			-- placeholder that keeps its place in the thread?
		require
			in_range: a_message >= 1 and a_message <= count
		do
			Result := decor.i_th (a_message).tomb
		end

	reactions_of (a_message: INTEGER): ARRAYED_LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]]
			-- The reaction chips of bubble `a_message', in the order the
			-- host gave them; empty when there are none. A COPY - the
			-- caller cannot reach into a drawn frame through it.
		require
			in_range: a_message >= 1 and a_message <= count
		do
			create Result.make (chip_sets.i_th (a_message).count)
			across
				chip_sets.i_th (a_message) as r
			loop
				Result.extend ([r.emoji.twin, r.tally, r.mine])
			end
		ensure
			same_size: Result.count = chip_sets.i_th (a_message).count
		end

	has_reply_quote (a_message: INTEGER): BOOLEAN
			-- Is bubble `a_message' a reply, with a quoted header to draw?
		require
			in_range: a_message >= 1 and a_message <= count
		do
			Result := not decor.i_th (a_message).quote_author.is_empty
				or else not decor.i_th (a_message).quote_text.is_empty
		end

	reply_quote (a_message: INTEGER): TUPLE [author, text: STRING_32]
			-- What bubble `a_message' is quoting; two empty strings when
			-- it is not a reply.
		require
			in_range: a_message >= 1 and a_message <= count
		do
			Result := [decor.i_th (a_message).quote_author.twin,
				decor.i_th (a_message).quote_text.twin]
		end

	quote_line (a_message: INTEGER): STRING_32
			-- The reply header of bubble `a_message' AS ONE LINE: the
			-- quoted author, then the quoted text with every break
			-- flattened to a space. Empty when it is not a reply. This is
			-- the string the elision then cuts.
		require
			in_range: a_message >= 1 and a_message <= count
		local
			au, tx: STRING_32
			i: INTEGER
			c: NATURAL_32
		do
			au := decor.i_th (a_message).quote_author
			tx := decor.i_th (a_message).quote_text
			create Result.make (au.count + tx.count + 2)
			if not au.is_empty then
				Result.append (au)
				if not tx.is_empty then
					Result.append ({STRING_32} ": ")
				end
			end
			from
				i := 1
			until
				i > tx.count
			loop
				c := tx.code (i)
				if c = 10 or c = 13 or c = 9 then
					Result.append_character (' ')
				else
					Result.append_code (c)
				end
				i := i + 1
			end
		ensure
			empty_without_a_quote: not has_reply_quote (a_message) implies Result.is_empty
		end

	drawn_quote (a_message: INTEGER): STRING_32
			-- The quote line the LAST frame actually painted for bubble
			-- `a_message', elided to that bubble's inner width; empty
			-- before the first frame and for a message with no quote.
		require
			in_range: a_message >= 1 and a_message <= count
		do
			if a_message <= drawn_quotes.count then
				Result := drawn_quotes.i_th (a_message).twin
			else
				create Result.make_empty
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

	Band_gap: REAL_64 = 4.0
			-- The space between two of a bubble's stacked bands - quote,
			-- text, "edited" marker, reaction row - at 1x. Scaled by the
			-- theme's `text_scale' wherever it is used, because these
			-- bands sit against MEASURED type, which already carries it.

	Quote_bar_w: REAL_64 = 2.0
			-- The accent rule down the left of a reply header.

	Quote_bar_gap: REAL_64 = 5.0
			-- Between that rule and the quoted line.

	Chip_pad_h: REAL_64 = 6.0
	Chip_pad_v: REAL_64 = 2.0
			-- Inside a reaction chip.

	Chip_gap: REAL_64 = 4.0
			-- Between two chips, and between two wrapped chip rows.

	Chip_inner_gap: REAL_64 = 3.0
			-- Between a chip's picture and its tally.

	Chip_radius: REAL_64 = 7.0

	Tomb_pad: REAL_64 = 5.0
			-- HALF `Bubble_pad', and - like `Bubble_pad' - deliberately
			-- NOT theme-scaled. That is what makes "a tombstone is
			-- shorter than the bubble it replaced" true at every text
			-- scale and on both text paths: the placeholder's band is
			-- capped at one body line (`tomb_band_h') and its padding is
			-- half, so the whole thing fits strictly inside even a
			-- one-line live bubble.

	Meta_size_ratio: REAL_64 = 0.78
			-- The "edited" marker and the tombstone placeholder, as a
			-- fraction of `Text_size'.

	Chip_size_ratio: REAL_64 = 0.85
			-- A reaction chip's picture and tally, likewise.

	Edited_marker: STRING = "edited"

	Deleted_marker: STRING = "message deleted"

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, j, px: INTEGER
			by, bw, bx, bh, max_w, inner_w, usable_w, sb_gutter, total_h: REAL_64
			recs: ARRAYED_LIST [TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]]
			rec: TUPLE [lo, hi: INTEGER; top, h: REAL_64; pidx, lidx: INTEGER]
			heights, widths: ARRAYED_LIST [REAL_64]
			is_shaped: BOOLEAN
			d, q: STRING_32
			body_h, body_w, hh, eh: REAL_64
			rel: ARRAYED_LIST [TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]]
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
					-- the decorations follow the body onto the same width
					-- `refresh_layouts' just settled on, storm and all, so
					-- a quote and the bubble under it can never be shaped
					-- for two different panes
				refresh_decor_layouts (al_kit, laid_out_width, px)
			else
				drop_decor_layouts
			end
			last_frame_shaped := is_shaped

				-- PASS 1: measure every bubble - no drawing, no scroll
				-- dependence - so `content_h' is the real total BEFORE
				-- anything gets clamped against it. See the class note.
			create heights.make (messages.count)
			create widths.make (messages.count)
			line_cache.wipe_out
			bubble_boxes.wipe_out
			head_bands.wipe_out
			body_bands.wipe_out
			edit_bands.wipe_out
			chip_boxes.wipe_out
			drawn_quotes.wipe_out
			total_h := 8.0
			from
				i := 1
			until
				i > messages.count
			loop
				if is_shaped then
					recs := shaped_lines_of (i)
					body_h := lines_height (recs)
					body_w := widest_layout (i)
				else
					recs := toy_lines_of (a_p, i, inner_w)
					body_h := recs.count * Line_h - 4.0
					body_w := widest_toy_line (a_p, i, recs)
				end
				line_cache.extend (recs)
				if is_tombstone (i) then
						-- the placeholder replaces the text ENTIRELY: no
						-- quote, no marker, no chips, half the padding
					create q.make_empty
					create rel.make (0)
					hh := 0.0
					eh := 0.0
					bh := tomb_band_h (a_p, body_h.max (1.0)) + 2.0 * Tomb_pad
					bw := tomb_text_width (a_p) + 2.0 * Tomb_pad
					body_h := 0.0
				else
					q := quote_band_text (a_p, i, is_shaped, inner_w)
					hh := quote_band_h (a_p, i, is_shaped)
					eh := edited_band_h (a_p, i)
					rel := chip_geometry (a_p, i, is_shaped, inner_w)
					bh := hh + body_h + eh + band_height_of (rel) + 2.0 * Bubble_pad
					bw := body_w.max (quote_band_w (a_p, i, is_shaped, q))
						.max (edited_band_w (a_p, i)).max (band_width_of (rel))
						+ 2.0 * Bubble_pad
					if is_shaped then
						bw := bw.min (max_w)
					end
				end
				drawn_quotes.extend (q)
				head_bands.extend (hh)
				body_bands.extend (body_h)
				edit_bands.extend (eh)
				chip_boxes.extend (rel)
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
					-- the chips' RELATIVE boxes become window boxes here and
					-- only here, so `reaction_at' hit-tests the rectangles
					-- `draw_chips' paints and never a second formula
				place_chips (i, bx + Bubble_pad,
					by + Bubble_pad + head_bands [i] + body_bands [i] + edit_bands [i]
						+ Band_gap * t.text_scale)
				if by + bh > y and then by < y + height then
					if is_tombstone (i) then
						draw_tombstone (a_p, bx, by, bw, bh)
					else
					inspect messages.i_th (i).role
					when Role_mine then
						a_p.set_color (t.wash_accent)
					when Role_theirs then
						a_p.set_color (t.surface_variant)
					else
						a_p.set_color_alpha (t.surface_variant, 0.5)
					end
					a_p.rrect_fill (bx, by, bw, bh, 7.0)
					if has_reply_quote (i) then
						draw_quote_band (a_p, i, is_shaped, bx + Bubble_pad, by + Bubble_pad)
					end
					if has_selection and then sel_message = i then
						draw_selection (a_p, i, bx + Bubble_pad, by + Bubble_pad + head_bands [i])
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
								bx + Bubble_pad,
								by + Bubble_pad + head_bands [i] + paragraph_top (i, j))
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
							a_p.text (bx + Bubble_pad,
								by + Bubble_pad + head_bands [i] + rec.top + 9.0,
								line_text (d, rec))
							j := j + 1
						end
					end
					if is_edited (i) then
						draw_edited_marker (a_p, bx + Bubble_pad,
							by + Bubble_pad + head_bands [i] + body_bands [i])
					end
					if not chip_boxes [i].is_empty then
						draw_chips (a_p, i, is_shaped)
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

	refresh_decor_layouts (a_kit: SW_SHAPING; a_inner_width, a_pixel_size: INTEGER)
			-- Bring the DECORATION layouts - one reply quote per message,
			-- one picture per reaction chip - in step with `messages' at
			-- the width and size `refresh_layouts' just settled on.
			--
			-- They are kept OUT of `shaped_layouts' on purpose:
			-- `layout_spans' tiles that list exactly (see
			-- `spans_tile_the_layouts'), and a quote laid into it would
			-- make the tiling a lie and every paragraph offset wrong by
			-- one. Same lag rule though - every mutator bumps `revision',
			-- so `decor_revision /= revision' is what "these are stale"
			-- means, and the invariant asks that question before
			-- demanding one entry per message.
		require
			width_positive: a_inner_width > 0
			size_positive: a_pixel_size > 0
		local
			i, k, cpx: INTEGER
			cl: ARRAYED_LIST [SHAPED_LAYOUT]
		do
			cpx := (a_pixel_size * Chip_size_ratio).rounded.max (1)
			if a_inner_width /= decor_width or a_pixel_size /= decor_size
				or revision /= decor_revision
				or quote_layouts.count /= messages.count
				or chip_layouts.count /= messages.count
			then
				quote_layouts.wipe_out
				chip_layouts.wipe_out
				from
					i := 1
				until
					i > messages.count
				loop
					if has_reply_quote (i) then
						quote_layouts.extend (
							one_line_layout (a_kit, quote_line (i),
								(a_inner_width - quote_indent.ceiling).max (16), a_pixel_size))
					else
						quote_layouts.extend (Void)
					end
					create cl.make (chip_sets.i_th (i).count)
					from
						k := 1
					until
						k > chip_sets.i_th (i).count
					loop
						cl.extend (a_kit.layout_for (chip_sets.i_th (i).i_th (k).emoji,
							a_inner_width, cpx))
						k := k + 1
					end
					chip_layouts.extend (cl)
					i := i + 1
				end
				decor_width := a_inner_width
				decor_size := a_pixel_size
				decor_revision := revision
			end
		ensure
			one_quote_slot_per_message: quote_layouts.count = messages.count
			one_chip_list_per_message: chip_layouts.count = messages.count
			content_current: decor_revision = revision
		end

	drop_decor_layouts
			-- No shaping kit this frame: nothing may hold a decoration
			-- layout the toy path would then measure against. `-1' is a
			-- revision no content change can produce, so the guarded
			-- invariant clause goes quiet rather than lying.
		do
			quote_layouts.wipe_out
			chip_layouts.wipe_out
			decor_revision := -1
			decor_width := 0
			decor_size := 0
		ensure
			gone: quote_layouts.is_empty and chip_layouts.is_empty
			not_current: decor_revision /= revision
		end

	one_line_layout (a_kit: SW_SHAPING; a_text: READABLE_STRING_32;
			a_width, a_size: INTEGER): SHAPED_LAYOUT
			-- `a_text' shaped to ONE line at `a_width' - the layout as it
			-- came when it already fits, else the prefix its first line
			-- covers, one character shorter, with an ellipsis, RE-SHAPED,
			-- because an ellipsis is a character the shaper has to
			-- measure too and a cut made on a toy advance would be a
			-- guess about a bidi line.
			--
			-- Bounded: each pass strictly shortens the text, so the loop
			-- cannot spin; six passes is a ceiling, not an expectation.
		require
			width_positive: a_width > 0
			size_positive: a_size > 0
		local
			n, tries: INTEGER
			s: STRING_32
		do
			Result := a_kit.layout_for (a_text, a_width, a_size)
			n := a_text.count
			from
			until
				Result.lines.count <= 1 or tries >= 6 or n <= 1
			loop
				n := (Result.lines.i_th (1).source_count - 1).min (n - 1).max (1)
				create s.make (n + 1)
				s.append (a_text.substring (1, n))
				s.append_code (0x2026)
				Result := a_kit.layout_for (s, a_width, a_size)
				tries := tries + 1
			end
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

	message_at (a_px, a_py: REAL_64): INTEGER
			-- WHICH BUBBLE the point lands on, 0 for none - the one
			-- question a host's right-click has to answer before it can
			-- offer a per-message menu. Built on the same frame geometry
			-- `hit_test' has hit-tested since 0.6.0, so a menu and a
			-- selection can never disagree about which message was meant.
			-- A tombstone answers with its own index: a deleted message
			-- is still a message, and a host may well want to offer
			-- something on it.
		do
			Result := hit_test (a_px, a_py).message
		ensure
			named: Result >= 0 and Result <= count
			nothing_before_a_frame: bubble_boxes.is_empty implies Result = 0
		end

	reaction_at (a_px, a_py: REAL_64): TUPLE [message: INTEGER; emoji: STRING_32]
			-- The reaction chip under the point: which bubble it belongs
			-- to and WHICH EMOJI it carries, so a click can toggle that
			-- one reaction. Message 0 and an empty string when the point
			-- is on no chip - which is most of the pane, and is not an
			-- error.
		local
			i, k: INTEGER
			b: TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]
			none: STRING_32
		do
			create none.make_empty
			Result := [0, none]
			from
				i := 1
			until
				i > chip_boxes.count or Result.message /= 0
			loop
				from
					k := 1
				until
					k > chip_boxes.i_th (i).count or Result.message /= 0
				loop
					b := chip_boxes.i_th (i).i_th (k)
					if b.cw > 0.0 and then a_px >= b.cx and then a_px <= b.cx + b.cw
						and then a_py >= b.cy and then a_py <= b.cy + b.ch
					then
						Result := [i, b.emoji.twin]
					end
					k := k + 1
				end
				i := i + 1
			end
		ensure
			named: Result.message >= 0 and Result.message <= count
			nothing_has_no_emoji: Result.message = 0 implies Result.emoji.is_empty
			something_has_an_emoji: Result.message > 0 implies not Result.emoji.is_empty
		end

	bubble_height (a_message: INTEGER): REAL_64
			-- The height the LAST frame drew bubble `a_message' at; 0
			-- before the first frame. The widget's own measurement of
			-- itself, published for the same reason `content_h' is: a
			-- host (and a test) can ask what a tombstone or a reaction
			-- row did to a bubble without re-deriving the layout.
		require
			in_range: a_message >= 1 and a_message <= count
		do
			if a_message <= bubble_boxes.count then
				Result := bubble_boxes.i_th (a_message).bh
			end
		ensure
			non_negative: Result >= 0.0
		end

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
			if is_tombstone (a_message) then
					-- a deleted message has no text to name an offset in:
					-- `tombstone' destroyed it rather than hiding it
			elseif a_message <= bubble_boxes.count and then a_message <= line_cache.count
				and then a_message <= displays.count
			then
				b := bubble_boxes.i_th (a_message)
				recs := line_cache.i_th (a_message)
				if not recs.is_empty then
						-- the text starts under the reply-quote band, when
						-- there is one; `head_of' is 0 when there is not,
						-- which is every bubble that predates 0.7.0
					ly := a_py - (b.by + Bubble_pad + head_of (a_message))
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

feature {NONE} -- Decoration measurement

	head_of (a_message: INTEGER): REAL_64
			-- How far down its own inner box message `a_message''s TEXT
			-- began in the last frame: the reply-quote band, or 0. Read
			-- by hit-testing, which has no painter and must not measure.
		do
			if a_message >= 1 and then a_message <= head_bands.count then
				Result := head_bands.i_th (a_message)
			end
		ensure
			non_negative: Result >= 0.0
		end

	meta_font (a_p: SW_PAINTER)
			-- Select the small muted face the "edited" marker and the
			-- tombstone placeholder share - in ONE place, so a
			-- measurement and the paint that follows it cannot drift.
		do
			a_p.font ({SW_PAINTER}.Role_ui, Text_size * Meta_size_ratio, False)
		end

	chip_font (a_p: SW_PAINTER)
			-- Likewise for a reaction chip's tally, and for its picture
			-- on the toy fallback.
		do
			a_p.font ({SW_PAINTER}.Role_ui, Text_size * Chip_size_ratio, False)
		end

	quote_indent: REAL_64
			-- The accent rule plus its gap: how far a quoted line is
			-- inset from the bubble's own inner edge.
		do
			Result := (Quote_bar_w + Quote_bar_gap) * last_text_scale
		ensure
			positive: Result > 0.0
		end

	quote_band_text (a_p: SW_PAINTER; a_message: INTEGER; a_shaped: BOOLEAN;
			a_inner_w: REAL_64): STRING_32
			-- The reply header message `a_message' will ACTUALLY paint
			-- this frame - the shaped path's own elided layout text when
			-- there is a kit, cairo's toy elision otherwise. Empty when
			-- the message is not a reply.
		do
			create Result.make_empty
			if has_reply_quote (a_message) then
				if a_shaped and then a_message <= quote_layouts.count
					and then attached quote_layouts.i_th (a_message) as al_q
				then
					create Result.make_from_string_general (al_q.source_text)
				else
					a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
					Result := elided (a_p, quote_line (a_message),
						(a_inner_w - quote_indent).max (8.0))
				end
			end
		ensure
			empty_without_a_quote: not has_reply_quote (a_message) implies Result.is_empty
		end

	quote_band_h (a_p: SW_PAINTER; a_message: INTEGER; a_shaped: BOOLEAN): REAL_64
			-- What the reply header adds to bubble `a_message''s height,
			-- INCLUDING the gap under it; 0 when it is not a reply.
		do
			if has_reply_quote (a_message) then
				if a_shaped and then a_message <= quote_layouts.count
					and then attached quote_layouts.i_th (a_message) as al_q
				then
					Result := al_q.total_height
				else
					a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
					Result := a_p.text_extent
				end
				Result := Result + Band_gap * last_text_scale
			end
		ensure
			non_negative: Result >= 0.0
			nothing_without_a_quote: not has_reply_quote (a_message) implies Result = 0.0
		end

	quote_band_w (a_p: SW_PAINTER; a_message: INTEGER; a_shaped: BOOLEAN;
			a_drawn: STRING_32): REAL_64
			-- What the reply header needs across, INCLUDING its indent.
		do
			if has_reply_quote (a_message) then
				if a_shaped and then a_message <= quote_layouts.count
					and then attached quote_layouts.i_th (a_message) as al_q
				then
					Result := al_q.total_width
				else
					a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
					Result := a_p.advance (a_drawn)
				end
				Result := Result + quote_indent
			end
		ensure
			non_negative: Result >= 0.0
		end

	edited_band_h (a_p: SW_PAINTER; a_message: INTEGER): REAL_64
			-- What the "edited" marker adds to bubble `a_message''s
			-- height, INCLUDING the gap above it; 0 when unmarked.
		do
			if is_edited (a_message) then
				meta_font (a_p)
				Result := a_p.text_extent + Band_gap * last_text_scale
			end
		ensure
			non_negative: Result >= 0.0
			nothing_without_the_marker: not is_edited (a_message) implies Result = 0.0
		end

	edited_band_w (a_p: SW_PAINTER; a_message: INTEGER): REAL_64
			-- What it needs across; 0 when unmarked.
		do
			if is_edited (a_message) then
				meta_font (a_p)
				Result := a_p.advance (Edited_marker)
			end
		ensure
			non_negative: Result >= 0.0
		end

	tomb_text_width (a_p: SW_PAINTER): REAL_64
			-- The placeholder's own advance, in its own face.
		do
			meta_font (a_p)
			Result := a_p.advance (Deleted_marker)
		ensure
			non_negative: Result >= 0.0
		end

	tomb_band_h (a_p: SW_PAINTER; a_line_h: REAL_64): REAL_64
			-- The placeholder's measured line, CAPPED at one body line.
			-- The cap plus `Tomb_pad' being half `Bubble_pad' is the
			-- whole proof that a tombstone is shorter than the bubble it
			-- replaced - at every text scale, on both text paths, and
			-- even against a live bubble of one single line.
		require
			line_positive: a_line_h > 0.0
		do
			meta_font (a_p)
			Result := a_p.text_extent.min (a_line_h).max (1.0)
		ensure
			positive: Result > 0.0
		end

	chip_geometry (a_p: SW_PAINTER; a_message: INTEGER; a_shaped: BOOLEAN;
			a_inner_w: REAL_64): ARRAYED_LIST [TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]]
			-- The reaction chips of message `a_message', laid left to
			-- right and wrapped at `a_inner_w', as boxes RELATIVE to the
			-- bubble's inner top-left. PASS 2 turns these into window
			-- boxes once it knows where the bubble landed.
			--
			-- The emoji's OWN artwork sizes the chip on the shaped path -
			-- simple_shaping makes an image run square at the line height,
			-- so a picture is proportional to the type and a chip cannot
			-- run away with the row. Without a kit the chip is measured
			-- in cairo's toy face instead, which is the text fallback and
			-- is what a machine with no Noto assets gets.
		require
			in_range: a_message >= 1 and a_message <= count
			width_positive: a_inner_w > 0.0
		local
			k: INTEGER
			ew, eh, tw, th, w, h, cx, cy, row_h, s, padh, padv, gap, inner: REAL_64
		do
			s := last_text_scale
			padh := Chip_pad_h * s
			padv := Chip_pad_v * s
			gap := Chip_gap * s
			inner := Chip_inner_gap * s
			create Result.make (chip_sets.i_th (a_message).count)
			from
				k := 1
			until
				k > chip_sets.i_th (a_message).count
			loop
				if a_shaped and then a_message <= chip_layouts.count
					and then k <= chip_layouts.i_th (a_message).count
				then
					ew := chip_layouts.i_th (a_message).i_th (k).total_width
					eh := chip_layouts.i_th (a_message).i_th (k).total_height
				else
					chip_font (a_p)
					ew := a_p.advance (chip_sets.i_th (a_message).i_th (k).emoji)
					eh := a_p.text_extent
				end
				chip_font (a_p)
				tw := a_p.advance (chip_sets.i_th (a_message).i_th (k).tally.out)
				th := a_p.text_extent
				w := padh * 2.0 + ew + inner + tw
				h := padv * 2.0 + eh.max (th)
				if k > 1 and then cx + w > a_inner_w then
						-- one row is not a law: a bubble with a dozen
						-- reactions wraps them instead of drawing off its
						-- own edge
					cx := 0.0
					cy := cy + row_h + gap
					row_h := 0.0
				end
				Result.extend ([cx, cy, w, h, chip_sets.i_th (a_message).i_th (k).emoji])
				cx := cx + w + gap
				row_h := row_h.max (h)
				k := k + 1
			end
		ensure
			one_box_per_chip: Result.count = reactions_of (a_message).count
		end

	band_height_of (a_boxes: ARRAYED_LIST [TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]]): REAL_64
			-- What a reaction row adds to a bubble's height, INCLUDING
			-- the gap above it; 0 for no chips.
		do
			across
				a_boxes as b
			loop
				Result := Result.max (b.cy + b.ch)
			end
			if not a_boxes.is_empty then
				Result := Result + Band_gap * last_text_scale
			end
		ensure
			non_negative: Result >= 0.0
			nothing_without_chips: a_boxes.is_empty implies Result = 0.0
		end

	band_width_of (a_boxes: ARRAYED_LIST [TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]]): REAL_64
			-- What it needs across; 0 for no chips.
		do
			across
				a_boxes as b
			loop
				Result := Result.max (b.cx + b.cw)
			end
		ensure
			non_negative: Result >= 0.0
		end

	place_chips (a_message: INTEGER; a_ox, a_oy: REAL_64)
			-- Turn message `a_message''s relative chip boxes into WINDOW
			-- boxes, now that PASS 2 knows where the bubble landed.
		require
			in_range: a_message >= 1 and a_message <= chip_boxes.count
		local
			k: INTEGER
			b: TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]
		do
			from
				k := 1
			until
				k > chip_boxes.i_th (a_message).count
			loop
				b := chip_boxes.i_th (a_message).i_th (k)
				chip_boxes.i_th (a_message).put_i_th (
					[a_ox + b.cx, a_oy + b.cy, b.cw, b.ch, b.emoji], k)
				k := k + 1
			end
		ensure
			same_count: chip_boxes.i_th (a_message).count = old chip_boxes.i_th (a_message).count
		end

feature {NONE} -- Decoration drawing

	draw_quote_band (a_p: SW_PAINTER; a_message: INTEGER; a_shaped: BOOLEAN;
			a_ix, a_iy: REAL_64)
			-- The reply header: an accent rule down its left edge, then
			-- the one elided line beside it, muted.
		require
			quoted: has_reply_quote (a_message)
		local
			t: SW_THEME
			band: REAL_64
		do
			t := a_p.theme
			band := (quote_band_h (a_p, a_message, a_shaped)
				- Band_gap * last_text_scale).max (1.0)
			a_p.set_color_alpha (t.accent, 0.85)
			a_p.rrect_fill (a_ix, a_iy, Quote_bar_w * last_text_scale, band, 1.0)
			a_p.set_color (t.ink_muted)
			if a_shaped and then a_message <= quote_layouts.count
				and then attached quote_layouts.i_th (a_message) as al_q
			then
				a_p.draw_shaped_layout (al_q, a_ix + quote_indent, a_iy)
			else
				a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
				a_p.text (a_ix + quote_indent, a_iy + a_p.font_ascent,
					drawn_quote (a_message))
			end
		end

	draw_edited_marker (a_p: SW_PAINTER; a_ix, a_iy: REAL_64)
			-- The small muted "edited" line under a bubble's text.
		do
			meta_font (a_p)
			a_p.set_color (a_p.theme.ink_muted)
			a_p.text (a_ix, a_iy + Band_gap * last_text_scale + a_p.font_ascent,
				Edited_marker)
		end

	draw_tombstone (a_p: SW_PAINTER; a_bx, a_by, a_bw, a_bh: REAL_64)
			-- A deleted message: a dimmed, outlined placeholder that keeps
			-- its place in the thread. DIMMED rather than italic -
			-- SW_PAINTER's `font' takes a weight and no slant, and there
			-- is no honest way to fake one; muted plus an outline says
			-- "this is not speech" just as plainly, and says it in a theme
			-- that may already be dark.
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.set_color_alpha (t.surface_variant, 0.35)
			a_p.rrect_fill (a_bx, a_by, a_bw, a_bh, 7.0)
			a_p.set_color_alpha (t.outline, 0.6)
			a_p.rrect_stroke (a_bx + 0.5, a_by + 0.5, a_bw - 1.0, a_bh - 1.0, 7.0)
			meta_font (a_p)
			a_p.set_color (t.ink_muted)
			a_p.text (a_bx + Tomb_pad,
				a_by + a_bh / 2.0 + (a_p.font_ascent - a_p.font_descent) / 2.0,
				Deleted_marker)
		end

	draw_chips (a_p: SW_PAINTER; a_message: INTEGER; a_shaped: BOOLEAN)
			-- The reaction row: one rounded chip per emoji, the reader's
			-- OWN outlined in the accent - so "I reacted" is legible
			-- without asking anyone to tell two washes apart.
		require
			in_range: a_message >= 1 and a_message <= chip_boxes.count
		local
			t: SW_THEME
			k: INTEGER
			b: TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]
			ew, ex, r: REAL_64
		do
			t := a_p.theme
			r := Chip_radius * last_text_scale
			from
				k := 1
			until
				k > chip_boxes.i_th (a_message).count
			loop
				b := chip_boxes.i_th (a_message).i_th (k)
				if k <= chip_sets.i_th (a_message).count
					and then chip_sets.i_th (a_message).i_th (k).mine
				then
					a_p.set_color_alpha (t.accent, 0.18)
					a_p.rrect_fill (b.cx, b.cy, b.cw, b.ch, r)
					a_p.set_color (t.accent)
				else
					a_p.set_color_alpha (t.surface, 0.85)
					a_p.rrect_fill (b.cx, b.cy, b.cw, b.ch, r)
					a_p.set_color_alpha (t.outline, 0.7)
				end
				a_p.rrect_stroke (b.cx + 0.5, b.cy + 0.5, b.cw - 1.0, b.ch - 1.0, r)
				ex := b.cx + Chip_pad_h * last_text_scale
				a_p.set_color (t.ink)
				if a_shaped and then a_message <= chip_layouts.count
					and then k <= chip_layouts.i_th (a_message).count
				then
					ew := chip_layouts.i_th (a_message).i_th (k).total_width
					a_p.draw_shaped_layout (chip_layouts.i_th (a_message).i_th (k),
						ex, b.cy + Chip_pad_v * last_text_scale)
				else
					chip_font (a_p)
					ew := a_p.advance (b.emoji)
					a_p.text (ex, b.cy + Chip_pad_v * last_text_scale + a_p.font_ascent,
						b.emoji)
				end
				chip_font (a_p)
				a_p.set_color (t.ink_muted)
				if k <= chip_sets.i_th (a_message).count then
					a_p.text (ex + ew + Chip_inner_gap * last_text_scale,
						b.cy + Chip_pad_v * last_text_scale + a_p.font_ascent,
						chip_sets.i_th (a_message).i_th (k).tally.out)
				end
				k := k + 1
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

	head_bands: ARRAYED_LIST [REAL_64]
			-- Per message, how far down its inner box the TEXT begins:
			-- the reply-quote band and the gap under it, or 0. Hit-testing
			-- and the selection wash both read it, which is why it is a
			-- frame cache and not a measurement.

	body_bands: ARRAYED_LIST [REAL_64]
			-- Per message, the height of the text itself - what the
			-- "edited" marker and the reaction row are stacked below.

	edit_bands: ARRAYED_LIST [REAL_64]
			-- Per message, the "edited" marker band, or 0.

	chip_boxes: ARRAYED_LIST [ARRAYED_LIST [TUPLE [cx, cy, cw, ch: REAL_64; emoji: STRING_32]]]
			-- Per message, its reaction chips. RELATIVE to the bubble's
			-- inner top-left while PASS 1 is measuring, WINDOW boxes once
			-- PASS 2 has called `place_chips' - which it does for every
			-- message, drawn or scrolled out, so `reaction_at' never
			-- answers from a stale frame.

	drawn_quotes: ARRAYED_LIST [STRING_32]
			-- Per message, the quote line the frame actually painted -
			-- elided. Published through `drawn_quote'.

feature {NONE} -- Decoration store

	decor: ARRAYED_LIST [TUPLE [edited, tomb: BOOLEAN; quote_author, quote_text: STRING_32]]
			-- One entry per message, ALWAYS - `add_message' extends it in
			-- the same breath it extends `messages', and nothing else
			-- grows either list. Kept beside `messages' rather than
			-- inside its tuple because `messages' is public and widening
			-- its type would break every host that reads a role.

	chip_sets: ARRAYED_LIST [ARRAYED_LIST [TUPLE [emoji: STRING_32; tally: INTEGER; mine: BOOLEAN]]]
			-- One reaction list per message, likewise always.

	quote_layouts: ARRAYED_LIST [detachable SHAPED_LAYOUT]
			-- The shaped, ONE-LINE reply header per message; Void for a
			-- message with no quote, and the whole list empty on the toy
			-- path and before the first shaped frame. Deliberately NOT in
			-- `shaped_layouts': `layout_spans' tiles that list exactly.

	chip_layouts: ARRAYED_LIST [ARRAYED_LIST [SHAPED_LAYOUT]]
			-- The shaped picture per reaction chip per message - the same
			-- Noto artwork the bubbles use, at the chip's own pixel size.

	decor_revision: INTEGER
			-- `revision' as of the last `refresh_decor_layouts'; -1 when
			-- the decoration layouts have been dropped, which is a value
			-- no content change can produce.

	decor_width: INTEGER
			-- The inner width they were built for.

	decor_size: INTEGER
			-- The body pixel size they were built at; a chip's own size
			-- is derived from it by `Chip_size_ratio'.

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

	elided (a_p: SW_PAINTER; a_text: READABLE_STRING_32; a_width: REAL_64): STRING_32
			-- `a_text' cut to `a_width' IN THE FONT ALREADY SELECTED,
			-- with a single ellipsis standing for what was dropped;
			-- `a_text' itself when it already fits. The caller selects the
			-- font first - this measures what is selected NOW, exactly the
			-- way `advance' does.
			--
			-- Found by halving, not by walking. A quoted line can be a
			-- whole paragraph long, and one `advance' per character is a
			-- measurement bill nobody asked for on a frame that is also
			-- shaping bubbles.
		require
			width_positive: a_width > 0.0
		local
			lo, hi, mid: INTEGER
		do
			if a_p.advance (a_text) <= a_width then
				create Result.make_from_string_general (a_text)
			else
				from
					lo := 0
					hi := a_text.count - 1
				until
					lo >= hi
				loop
					mid := (lo + hi + 1) // 2
					if a_p.advance (with_ellipsis (a_text, mid)) <= a_width then
						lo := mid
					else
						hi := mid - 1
					end
				end
				Result := with_ellipsis (a_text, lo)
			end
		ensure
			kept_whole_when_it_fits: a_p.advance (a_text) <= a_width implies
				Result.same_string_general (a_text)
			marked_when_cut: a_p.advance (a_text) > a_width implies
				(Result.count >= 1 and then Result.item (Result.count).natural_32_code = 0x2026)
			never_longer: Result.count <= a_text.count.max (1)
		end

	with_ellipsis (a_text: READABLE_STRING_32; a_n: INTEGER): STRING_32
			-- The first `a_n' characters of `a_text', then U+2026 - the
			-- ONE place the ellipsis is spelled, so a measurement and the
			-- string that gets drawn cannot be two different strings.
		require
			in_range: a_n >= 0 and a_n <= a_text.count
		do
			create Result.make (a_n + 1)
			if a_n > 0 then
				Result.append (a_text.substring (1, a_n))
			end
			Result.append_code (0x2026)
		ensure
			exactly_one_longer: Result.count = a_n + 1
		end

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
	spans_never_outrun_messages: layout_spans.count <= messages.count
	spans_match_when_current: laid_out_revision = revision implies
		layout_spans.count = messages.count
	spans_and_layouts_arrive_together: shaped_layouts.is_empty = layout_spans.is_empty
	spans_tile_the_layouts: layout_spans.is_empty or else
		layout_spans.last.base + layout_spans.last.span - 1 = shaped_layouts.count
	a_layout_per_paragraph: shaped_layouts.count >= layout_spans.count
	revision_non_negative: revision >= 0 and laid_out_revision >= 0
	scrollbar_width_positive: scrollbar_width > 0.0
	text_scale_recorded_positive: last_text_scale > 0.0
	selection_names_a_message: sel_message >= 0 and sel_message <= messages.count
	selection_offsets_non_negative: sel_anchor >= 0 and sel_caret >= 0
	no_selection_without_a_message: sel_message = 0 implies
		(sel_anchor = 0 and sel_caret = 0)

		-- 0.7.0, mutation. The decoration STORE is content, so it is one
		-- entry per message unconditionally - `add_message' is the only
		-- thing that grows either list and it grows both. The decoration
		-- LAYOUTS are shaped artefacts, so they lag between frames for
		-- exactly the reason `layout_spans' does (see BETWEEN TWO FRAMES),
		-- and `decor_revision = revision' is the same question asked
		-- again: are these current?
	decor_attached: decor /= Void and chip_sets /= Void
	decor_layouts_attached: quote_layouts /= Void and chip_layouts /= Void
	bands_attached: head_bands /= Void and body_bands /= Void
		and edit_bands /= Void and chip_boxes /= Void and drawn_quotes /= Void
	one_decoration_per_message: decor.count = messages.count
	one_chip_set_per_message: chip_sets.count = messages.count
	decor_layouts_never_outrun_messages: quote_layouts.count <= messages.count
		and chip_layouts.count <= messages.count
	decor_matches_when_current: decor_revision = revision implies
		(quote_layouts.count = messages.count and chip_layouts.count = messages.count)
	bands_never_outrun_messages: head_bands.count <= messages.count
		and body_bands.count <= messages.count and edit_bands.count <= messages.count
		and chip_boxes.count <= messages.count and drawn_quotes.count <= messages.count

end
