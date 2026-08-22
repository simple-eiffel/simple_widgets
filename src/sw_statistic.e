note
	description: "[
		A number that matters: big value, muted label beneath, and
		an optional delta wearing its semantic - green up, red down.
	]"

class
	SW_STATISTIC

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make

feature {NONE} -- Initialization

	make (a_label, a_value: READABLE_STRING_GENERAL)
		do
			create label.make_from_string_general (a_label)
			create value_text.make_from_string_general (a_value)
			create delta_text.make_empty
		ensure
			kept: label.same_string_general (a_label)
		end

feature -- Access

	label: STRING_32

	value_text: STRING_32

	delta_text: STRING_32

	is_delta_positive: BOOLEAN

	has_delta: BOOLEAN
		do
			Result := not delta_text.is_empty
		end

feature -- Element change

	set_value (a_value: READABLE_STRING_GENERAL)
		do
			create value_text.make_from_string_general (a_value)
		ensure
			set: value_text.same_string_general (a_value)
		end

	set_delta (a_text: READABLE_STRING_GENERAL; a_positive: BOOLEAN)
		do
			create delta_text.make_from_string_general (a_text)
			is_delta_positive := a_positive
		ensure
			set: delta_text.same_string_general (a_text)
			signed: is_delta_positive = a_positive
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, 26.0, True)
			Result := a_p.advance (value_text) + 20.0
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := Result.max (a_p.advance (label) + 20.0)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 58.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			vx: REAL_64
		do
			t := a_p.theme
			a_p.font ({SW_PAINTER}.Role_ui, 26.0, True)
			a_p.set_color (t.ink)
			a_p.text (x, y + 28.0, value_text)
			vx := x + a_p.advance (value_text) + 8.0
			if has_delta then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip + 1.0, True)
				if is_delta_positive then
					a_p.set_color (t.success)
				else
					a_p.set_color (t.danger)
				end
				a_p.text (vx, y + 26.0, delta_text)
			end
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			a_p.set_color (t.ink_muted)
			a_p.text (x, y + 50.0, label)
		end

invariant
	texts_attached: label /= Void and value_text /= Void and delta_text /= Void

end
