note
	description: "[
		The ampersand convention, in one place: "&File" is a label whose
		F is UNDERLINED and whose Alt-key is F; "Select &All" is "Select
		All" with the A underlined; "R&&D" is the literal "R&D" with no
		mnemonic at all.

		WHY A CLASS AND NOT A ROUTINE ON EACH MENU. SW_MENU_BAR parses
		pad titles, SW_MENU parses item labels, and SW_WINDOW matches a
		typed letter against both. Three copies of "find the first
		single ampersand" is three chances to disagree about "&&"; this
		is the one answer all three ask.

		THE PARSE IS TOTAL. Every query here answers for every string,
		including the empty one and a label ending in a bare "&" (which
		names no letter and is simply dropped). Nothing raises.

		CASE. `mnemonic_letter' answers UPPER case and `matches' folds
		its argument, because Alt+f and Alt+F are the same gesture and
		WM_CHAR reports whichever the shift state produced.
	]"
	author: "Larry Rix"

class
	SW_MNEMONIC

feature -- Access

	plain (a_label: READABLE_STRING_GENERAL): STRING_32
			-- `a_label' as the user reads it: every single "&" removed,
			-- every "&&" collapsed to one literal "&".
		local
			s: STRING_32
			i, n: INTEGER
			c: CHARACTER_32
		do
			create s.make_from_string_general (a_label)
			create Result.make (s.count)
			n := s.count
			from
				i := 1
			until
				i > n
			loop
				c := s.item (i)
				if c = Amp then
					if i < n and then s.item (i + 1) = Amp then
						Result.append_character (Amp)
						i := i + 1
					end
						-- a single "&" is the marker, not a character,
						-- and a trailing "&" marks nothing
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		ensure
			never_longer: Result.count <= a_label.count
		end

	underline_index (a_label: READABLE_STRING_GENERAL): INTEGER
			-- 1-based index INTO `plain (a_label)' of the character the
			-- mnemonic underlines; 0 when the label declares none.
		local
			s: STRING_32
			i, n, out_i: INTEGER
			c: CHARACTER_32
		do
			create s.make_from_string_general (a_label)
			n := s.count
			from
				i := 1
			until
				i > n or Result /= 0
			loop
				c := s.item (i)
				if c = Amp then
					if i < n and then s.item (i + 1) = Amp then
						out_i := out_i + 1
						i := i + 1
					elseif i < n then
						Result := out_i + 1
					end
				else
					out_i := out_i + 1
				end
				i := i + 1
			end
		ensure
			in_plain: Result >= 0 and Result <= plain (a_label).count
		end

	mnemonic_letter (a_label: READABLE_STRING_GENERAL): CHARACTER_32
			-- The UPPER-cased letter (or digit) `a_label' answers Alt to;
			-- `No_letter' when it declares none.
		local
			idx: INTEGER
			p: STRING_32
		do
			Result := No_letter
			idx := underline_index (a_label)
			if idx > 0 then
				p := plain (a_label)
				Result := p.item (idx).as_upper
			end
		end

	has_mnemonic (a_label: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_label' declare an Alt-key?
		do
			Result := underline_index (a_label) > 0
		ensure
			definition: Result = (underline_index (a_label) > 0)
		end

	matches (a_label: READABLE_STRING_GENERAL; a_typed: CHARACTER_32): BOOLEAN
			-- Is `a_typed' the key `a_label' answers to, case folded?
		do
			Result := has_mnemonic (a_label)
				and then mnemonic_letter (a_label) = a_typed.as_upper
		end

	virtual_key (a_label: READABLE_STRING_GENERAL): INTEGER
			-- The Win32 virtual-key code of `a_label''s mnemonic - 65..90
			-- for A..Z, 48..57 for 0..9 - or 0 when it declares none or
			-- names a character with no VK of its own.
		local
			c: CHARACTER_32
			code: INTEGER
		do
			c := mnemonic_letter (a_label)
			code := c.code
			if (code >= 65 and code <= 90) or (code >= 48 and code <= 57) then
				Result := code
			end
		ensure
			letters_and_digits_only: Result = 0
				or else ((Result >= 65 and Result <= 90) or (Result >= 48 and Result <= 57))
		end

feature -- Constants

	Amp: CHARACTER_32 = '&'

	No_letter: CHARACTER_32 = '%U'
			-- What `mnemonic_letter' answers for a label with no "&".

end
