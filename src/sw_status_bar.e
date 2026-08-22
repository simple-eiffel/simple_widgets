note
	description: "[
		The bottom strip: a left message and a right message in mono
		on the variant surface, hairline above. The capture strip's
		grandchild, formalized.
	]"

class
	SW_STATUS_BAR

inherit
	SW_WIDGET

create
	make

feature {NONE} -- Initialization

	make
		do
			create left_text.make_empty
			create right_text.make_empty
		end

feature -- Access

	left_text: STRING_32
	right_text: STRING_32

feature -- Element change

	set_left (a_text: READABLE_STRING_GENERAL)
		do
			create left_text.make_from_string_general (a_text)
		ensure
			kept: left_text.same_string_general (a_text)
		end

	set_right (a_text: READABLE_STRING_GENERAL)
		do
			create right_text.make_from_string_general (a_text)
		ensure
			kept: right_text.same_string_general (a_text)
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 32.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, height)
			a_p.hline (x, y, width)
			a_p.font ({SW_PAINTER}.Role_mono, t.size_chip + 1.0, False)
			a_p.set_color (t.ink_muted)
			if not left_text.is_empty then
				a_p.text (x + 12.0, y + height / 2.0 + 5.0, left_text)
			end
			if not right_text.is_empty then
				a_p.text (x + width - 12.0 - a_p.advance (right_text), y + height / 2.0 + 5.0, right_text)
			end
		end

invariant
	texts_attached: left_text /= Void and right_text /= Void

end
