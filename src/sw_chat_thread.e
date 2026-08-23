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
			is_sticky := True
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

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			by, bw, bx, bh, max_w: REAL_64
			lines: ARRAYED_LIST [STRING_32]
			j: INTEGER
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- measure pass piggybacks on the draw pass: bubbles
				-- stack, content height falls out, scroll clamps
			max_w := (width * 0.72).max (60.0)
			content_h := 8.0
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			a_p.font ({SW_PAINTER}.Role_ui, 13.0, False)
			from
				i := 1
			until
				i > messages.count
			loop
				lines := wrapped (a_p, messages.i_th (i).text, max_w - 2.0 * Bubble_pad)
				bh := lines.count * Line_h + 2.0 * Bubble_pad - 4.0
				bw := widest (a_p, lines) + 2.0 * Bubble_pad
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
					from
						j := 1
					until
						j > lines.count
					loop
						a_p.text (bx + Bubble_pad, by + Bubble_pad + (j - 1) * Line_h + 9.0,
							lines.i_th (j))
						j := j + 1
					end
				end
				content_h := content_h + bh + 8.0
				i := i + 1
			end
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
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

end
