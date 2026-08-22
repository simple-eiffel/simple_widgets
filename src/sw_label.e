note
	description: "[
		A single line of text in one of the three type roles. The role
		is semantic: ui for the tool's own voice, body for the author's
		prose, mono for machine-produced values.
	]"

class
	SW_LABEL

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make, make_ui, make_mono, make_body

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL; a_role: INTEGER; a_size: REAL_64; a_bold: BOOLEAN)
		require
			size_positive: a_size > 0.0
		do
			create text.make_from_string_general (a_text)
			role := a_role
			size := a_size
			is_bold := a_bold
		ensure
			text_kept: text.same_string_general (a_text)
		end

	make_ui (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_ui, 13.0, False)
		end

	make_mono (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_mono, 13.0, False)
		end

	make_body (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_body, 16.0, False)
			is_wrapping := True
		ensure
			wraps: is_wrapping
		end

feature -- Access

	text: STRING_32
	role: INTEGER
	size: REAL_64
	is_bold: BOOLEAN
	is_muted: BOOLEAN

	is_wrapping: BOOLEAN
			-- Break into as many lines as the width demands? Body
			-- labels wrap by default; chrome labels stay single-line.
	custom_color: NATURAL_32
			-- 0 means: theme ink (or muted ink).

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
		do
			create text.make_from_string_general (a_text)
		ensure
			kept: text.same_string_general (a_text)
		end

	set_muted (a_muted: BOOLEAN)
		do
			is_muted := a_muted
		end

	set_color (a_rgb: NATURAL_32)
		do
			custom_color := a_rgb
		end

	with_wrap: like Current
			-- Fluent: wrapping variant of Current.
		do
			is_wrapping := True
			Result := Current
		ensure
			wraps: is_wrapping
			chained: Result = Current
		end

	as_muted: like Current
			-- Fluent: muted variant of Current.
		do
			is_muted := True
			Result := Current
		end

	colored (a_rgb: NATURAL_32): like Current
			-- Fluent: Current drawn in `a_rgb'.
		do
			custom_color := a_rgb
			Result := Current
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font (role, size, is_bold)
			Result := a_p.advance (text)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			if is_wrapping then
				Result := wrapped_lines (a_p, a_width).count * (size + 9.0)
			else
				Result := size + 9.0
			end
		end

	wrapped_lines (a_p: SW_PAINTER; a_width: REAL_64): ARRAYED_LIST [STRING_32]
			-- `text' broken at word boundaries to fit `a_width'.
		local
			words: LIST [STRING_32]
			line: STRING_32
			cx, ww: REAL_64
		do
			create Result.make (4)
			a_p.font (role, size, is_bold)
			words := text.split (' ')
			create line.make (60)
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

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			lines: ARRAYED_LIST [STRING_32]
			i: INTEGER
		do
			a_p.font (role, size, is_bold)
			if custom_color /= 0 then
				a_p.set_color (custom_color)
			elseif is_muted then
				a_p.set_color (a_p.theme.ink_muted)
			else
				a_p.set_color (a_p.theme.ink)
			end
			if is_wrapping then
				lines := wrapped_lines (a_p, width)
				from
					i := 1
				until
					i > lines.count
				loop
					a_p.text (x, y + (i - 1) * (size + 9.0) + size + 2.0, lines.i_th (i))
					i := i + 1
				end
			else
				a_p.text (x, y + size + 2.0, text)
			end
		end

invariant
	text_attached: text /= Void

end
