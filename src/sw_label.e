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
			make (a_text, {SW_PAINTER}.Role_ui, 11.0, False)
		end

	make_mono (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_mono, 11.0, False)
		end

	make_body (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text, {SW_PAINTER}.Role_body, 13.5, False)
		end

feature -- Access

	text: STRING_32
	role: INTEGER
	size: REAL_64
	is_bold: BOOLEAN
	is_muted: BOOLEAN
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
			Result := size + 9.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			a_p.font (role, size, is_bold)
			if custom_color /= 0 then
				a_p.set_color (custom_color)
			elseif is_muted then
				a_p.set_color (a_p.theme.ink_muted)
			else
				a_p.set_color (a_p.theme.ink)
			end
			a_p.text (x, y + size + 2.0, text)
		end

invariant
	text_attached: text /= Void

end
