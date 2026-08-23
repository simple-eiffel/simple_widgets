note
	description: "A scored hairline, horizontal by construction here."

class
	SW_SEPARATOR

inherit
	SW_WIDGET

create
	make, make_labeled

feature {NONE} -- Initialization

	make
		do
		end

feature {NONE} -- Labeled variant

	make_labeled (a_text: READABLE_STRING_GENERAL)
			-- A line carved by centred text ('--- OR ---').
		do
			make
			create label.make_from_string_general (a_text)
		end

feature -- Access

	label: detachable STRING_32

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 9.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			lw, half: REAL_64
		do
			if attached label as l and then not l.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_chip, False)
				lw := a_p.advance (l)
				half := (width - lw - 20.0) / 2.0
				a_p.hline (x + 2.0, y + height / 2.0, half.max (2.0))
				a_p.set_color (a_p.theme.ink_muted)
				a_p.text (x + half + 10.0, y + height / 2.0 + a_p.theme.size_chip / 2.0 - 1.0, l)
				a_p.hline (x + half + lw + 18.0, y + height / 2.0, half.max (2.0))
			else
				a_p.hline (x + 2.0, y + height / 2.0, width - 4.0)
			end
		end

end
