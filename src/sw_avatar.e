note
	description: "[
		A person as a disc: up to two initials derived from the
		display name, on a wash whose hue is a stable hash of the
		name - the same person always wears the same colour.
	]"

class
	SW_AVATAR

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
		do
			create display_name.make_from_string_general (a_name)
			diameter := 36.0
		ensure
			named: display_name.same_string_general (a_name)
		end

feature -- Access

	display_name: STRING_32

	diameter: REAL_64

	initials: STRING_32
			-- First letters of the first and last words, upper-cased;
			-- '?' when the name is blank.
		local
			i: INTEGER
			first_c, last_c: CHARACTER_32
			in_word: BOOLEAN
		do
			create Result.make (2)
			from
				i := 1
			until
				i > display_name.count
			loop
				if display_name.item (i) = ' ' then
					in_word := False
				elseif not in_word then
					in_word := True
					if first_c = '%U' then
						first_c := display_name.item (i)
					end
					last_c := display_name.item (i)
				end
				i := i + 1
			end
			if first_c /= '%U' then
				Result.append_character (first_c.as_upper)
				if last_c /= first_c or display_name.has (' ') then
					if last_c /= '%U' and then Result.count = 1 and then last_c /= first_c or else (display_name.occurrences (' ') > 0 and last_c /= '%U') then
						Result.append_character (last_c.as_upper)
					end
				end
			end
			if Result.is_empty then
				Result := {STRING_32} "?"
			end
		ensure
			short: Result.count >= 1 and Result.count <= 2
		end

feature -- Element change

	with_diameter (a_d: REAL_64): like Current
		require
			positive: a_d > 0.0
		do
			diameter := a_d
			Result := Current
		ensure
			chained: Result = Current
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			Result := diameter
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := diameter
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			h: NATURAL_32
			i: INTEGER
			cx, cy: REAL_64
		do
			t := a_p.theme
			from
				i := 1
			until
				i > display_name.count
			loop
				h := h * 31 + display_name.code (i)
				i := i + 1
			end
			inspect (h \\ 4).to_integer_32
			when 0 then
				a_p.set_color (t.wash_accent)
			when 1 then
				a_p.set_color (t.wash_success)
			when 2 then
				a_p.set_color (t.wash_warning)
			else
				a_p.set_color (t.wash_danger)
			end
			cx := x + width / 2.0
			cy := y + height / 2.0
			a_p.circle_fill (cx, cy, diameter / 2.0)
			a_p.set_color (t.ink)
			a_p.font ({SW_PAINTER}.Role_ui, diameter * 0.38, True)
			a_p.text (cx - a_p.advance (initials) / 2.0, cy + diameter * 0.14, initials)
		end

invariant
	name_attached: display_name /= Void
	diameter_positive: diameter > 0.0

end
