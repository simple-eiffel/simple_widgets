note
	description: "[
		An editable dropdown: the full text-editing engine on one
		line, plus a chevron that opens the option list as a drawn
		menu. Picking an option replaces the text; typing refines
		it freely afterwards.
	]"

class
	SW_COMBO

inherit
	SW_TEXT_BOX
		redefine
			draw, handle_click, preferred_width
		end

create
	make_with_options

feature {NONE} -- Initialization

	make_with_options
		do
			make_single_line ("")
			create options.make (8)
			set_spellcheck (False)
		ensure
			no_options_yet: options.is_empty
		end

feature -- Access

	options: ARRAYED_LIST [STRING_32]

	Chevron_zone: REAL_64 = 30.0
			-- Width of the click zone, at the right edge, that opens
			-- the option menu rather than placing the caret.

feature -- Element change

	add_option (a_text: READABLE_STRING_GENERAL)
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			options.extend (s)
		ensure
			grew: options.count = old options.count + 1
		end

	with_option (a_text: READABLE_STRING_GENERAL): like Current
			-- Fluent option append.
		do
			add_option (a_text)
			Result := Current
		ensure
			chained: Result = Current
		end

	choose_option (a_i: INTEGER)
			-- Replace the text with option `a_i', caret at the end.
		require
			in_range: a_i >= 1 and a_i <= options.count
		do
			set_text (options.i_th (a_i))
			caret := text.count
			sel_anchor := caret
			changed
		ensure
			taken: text.same_string (options.i_th (a_i))
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		local
			w: REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
			Result := 170.0
			across
				options as o
			loop
				w := a_p.advance (o) + Chevron_zone + 26.0
				if w > Result then
					Result := w
				end
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cx, cy: REAL_64
		do
			Precursor (a_p)
			t := a_p.theme
			cx := x + width - 19.0
			cy := y + height / 2.0 - 2.0
			a_p.set_color (t.ink_muted)
			a_p.line (cx, cy, cx + 5.0, cy + 5.0, 1.6)
			a_p.line (cx + 5.0, cy + 5.0, cx + 10.0, cy, 1.6)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			m: SW_MENU
			i: INTEGER
		do
			if is_enabled and then not options.is_empty and then a_px >= x + width - Chevron_zone then
				create m.make
				from
					i := 1
				until
					i > options.count
				loop
					m.add_item (options.i_th (i), "", True, agent choose_option (i))
					i := i + 1
				end
				pending_menu := m
				Result := True
			else
				Result := Precursor (a_px, a_py)
			end
		end

invariant
	options_attached: options /= Void
	one_line_forever: is_single_line

end
