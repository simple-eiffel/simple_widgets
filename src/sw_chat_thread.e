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
		screen. The bubble's height is then `layout.total_height' and
		never a line count times a constant - which is the only honest
		measurement once a line may mix a 128-pixel emoji box with 13
		pixel text.

		THE OLD PATH IS STILL SELECTABLE, and it is the DEFAULT. Without
		a kit (`SW_PAINTER.has_shaping' False) this widget behaves exactly
		as it always has, down to the pixel: same `wrapped', same
		`Line_h', same bubble arithmetic. Nothing in the public model -
		`add_message', `append_to_last', `is_sticky', `content_h',
		`handle_wheel' - changes in either mode.

		R10, RE-LAYOUT AT RESIZE END. Shaping a paragraph is not free, and
		a drag delivers a resize every few milliseconds. So a WIDTH change
		waits for `SW_PAINTER.is_resize_storm' to clear (SW_WINDOW sets it
		from its own `busy_ticks' debounce) and the bubbles keep the
		layouts they have while the frame moves. A CONTENT change never
		waits: a message that arrives mid-drag still has to appear.
	]"

class
	SW_CHAT_THREAD

inherit
	SW_WIDGET
		redefine
			handle_wheel
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
			is_sticky := True
		ensure
			nothing_laid_out: shaped_layouts.is_empty
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
			-- One SHAPED_LAYOUT per message, in `messages' order, once a
			-- shaped frame has been drawn; empty on the toy path and
			-- before the first frame. Public because it is the widget's
			-- measurement of itself: `shaped_layouts [i].lines.count' is
			-- how many lines message `i' really needs at the width it was
			-- last laid out to.

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

feature -- Drawing

	Bubble_pad: REAL_64 = 10.0

	Line_h: REAL_64 = 19.0

	Text_size: REAL_64 = 13.0
			-- The bubble's type size, in points on the toy path and (after
			-- the theme's scale) in PIXELS on the shaped path.

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			by, bw, bx, bh, max_w, inner_w: REAL_64
			lines: detachable ARRAYED_LIST [STRING_32]
			j, px: INTEGER
			is_shaped: BOOLEAN
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- measure pass piggybacks on the draw pass: bubbles
				-- stack, content height falls out, scroll clamps
			max_w := (width * 0.72).max (60.0)
			inner_w := (max_w - 2.0 * Bubble_pad).max (16.0)
			content_h := 8.0
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			a_p.font ({SW_PAINTER}.Role_ui, Text_size, False)
			px := (Text_size * t.text_scale).rounded.max (1)
			if attached a_p.shaping as al_kit then
					-- One measurement pass for the whole thread: unchanged
					-- messages come back from the layout cache having shaped
					-- nothing, so this is cheap on a still frame.
				refresh_layouts (al_kit, inner_w, px, a_p.is_resize_storm)
				is_shaped := shaped_layouts.count = messages.count
			end
			from
				i := 1
			until
				i > messages.count
			loop
				if is_shaped then
						-- R10: the bubble is as tall as the layout says, and
						-- never a line count times a constant - a line that
						-- carries an emoji box is taller than one that does not.
					bh := shaped_layouts [i].total_height + 2.0 * Bubble_pad
					bw := (shaped_layouts [i].total_width + 2.0 * Bubble_pad).min (max_w)
				else
					lines := wrapped (a_p, messages.i_th (i).text, inner_w)
					if attached lines as al_measured then
						bh := al_measured.count * Line_h + 2.0 * Bubble_pad - 4.0
						bw := widest (a_p, al_measured) + 2.0 * Bubble_pad
					end
				end
				inspect messages.i_th (i).role
				when Role_mine then
					bx := x + width - bw - 10.0
				when Role_theirs then
					bx := x + 10.0
				else
					bx := x + (width - bw) / 2.0
				end
				by := y + content_h - scroll_clamped (a_p)
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
					if messages.i_th (i).role = Role_system then
						a_p.set_color (t.ink_muted)
					else
						a_p.set_color (t.ink)
					end
					if is_shaped then
							-- (x, y) here is a TOP-LEFT, not a baseline: the
							-- layout already knows each line's ascent.
						a_p.draw_shaped_layout (shaped_layouts [i],
							bx + Bubble_pad, by + Bubble_pad)
					elseif attached lines as al_lines then
						from
							j := 1
						until
							j > al_lines.count
						loop
							a_p.text (bx + Bubble_pad, by + Bubble_pad + (j - 1) * Line_h + 9.0,
								al_lines.i_th (j))
							j := j + 1
						end
					end
				end
				content_h := content_h + bh + 8.0
				i := i + 1
			end
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

	refresh_layouts (a_kit: SW_SHAPING; a_inner_width: REAL_64; a_pixel_size: INTEGER;
			a_resize_storm: BOOLEAN)
			-- Bring `shaped_layouts' in step with `messages' at
			-- `a_inner_width' x `a_pixel_size'.
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
			w, i: INTEGER
		do
			if a_resize_storm and then not shaped_layouts.is_empty then
				w := laid_out_width
			else
				w := a_inner_width.floor.max (16)
			end
			if w /= laid_out_width or a_pixel_size /= laid_out_size
				or revision /= laid_out_revision
			then
				shaped_layouts.wipe_out
				from
					i := 1
				until
					i > messages.count
				loop
					shaped_layouts.extend (
						a_kit.layout_for (messages.i_th (i).text, w, a_pixel_size))
					i := i + 1
				end
				laid_out_width := w
				laid_out_size := a_pixel_size
				laid_out_revision := revision
			end
		ensure
			one_layout_per_message: shaped_layouts.count = messages.count
			width_recorded: laid_out_width > 0
			content_current: laid_out_revision = revision
		end

feature -- Input

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			scroll_y := (scroll_y - a_delta / 120.0 * 48.0).max (0.0)
			is_sticky := scroll_y >= (content_h - height).max (0.0) - 2.0
			Result := True
		end

feature {NONE} -- Text machinery

	scroll_clamped (a_p: SW_PAINTER): REAL_64
		do
			Result := scroll_y.min ((content_h - height).max (0.0))
			scroll_y := Result
		end

	wrapped (a_p: SW_PAINTER; a_text: STRING_32; a_width: REAL_64): ARRAYED_LIST [STRING_32]
			-- Greedy word wrap in the current font.
		local
			words: LIST [STRING_32]
			line: STRING_32
			cx, ww: REAL_64
		do
			create Result.make (4)
			words := a_text.split (' ')
			create line.make (48)
			across
				words as w
			loop
				ww := a_p.advance (w)
				if line.is_empty then
					line := w.twin
					cx := ww
				elseif cx + 4.5 + ww > a_width then
					Result.extend (line)
					line := w.twin
					cx := ww
				else
					line.append_character (' ')
					line.append (w)
					cx := cx + 4.5 + ww
				end
			end
			Result.extend (line)
		ensure
			at_least_one: not Result.is_empty
		end

	widest (a_p: SW_PAINTER; a_lines: ARRAYED_LIST [STRING_32]): REAL_64
		do
			across
				a_lines as l
			loop
				Result := Result.max (a_p.advance (l))
			end
		end

invariant
	messages_attached: messages /= Void
	layouts_attached: shaped_layouts /= Void
	layouts_match_when_present: not shaped_layouts.is_empty implies
		shaped_layouts.count = messages.count
	revision_non_negative: revision >= 0 and laid_out_revision >= 0

end
