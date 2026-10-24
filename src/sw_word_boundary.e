note
	description: "[
		What a word is, for pointing at one: a run of letters (with
		their marks) or a run of digits - so a raised Strong's number
		after its word is a word of its own - while a space or a
		punctuation mark is a word of one. Hebrew and Greek punctuation
		separates too (maqaf, paseq, sof pasuq, ano teleia, the Greek
		question mark). Lifted (0.20.0) from SW_PARAGRAPH_LIST so the
		document view and every pointing widget agree on a word.
	]"
	author: "Larry Rix"

class
	SW_WORD_BOUNDARY

feature -- Access

	word_around (a_text: READABLE_STRING_32; a_character: INTEGER): TUPLE [lo, hi: INTEGER]
			-- The word around character `a_character' of `a_text', as caret
			-- offsets: characters `lo' + 1 .. `hi'.
		require
			character_in_text: a_character >= 1 and a_character <= a_text.count
		local
			k, lo, hi: INTEGER
		do
			k := word_class (a_text.item (a_character))
			lo := a_character - 1
			hi := a_character
			if k /= 0 then
				from until lo = 0 or else word_class (a_text.item (lo)) /= k loop
					lo := lo - 1
				end
				from until hi = a_text.count or else word_class (a_text.item (hi + 1)) /= k loop
					hi := hi + 1
				end
			end
			Result := [lo, hi]
		ensure
			holds_it: Result.lo < a_character and a_character <= Result.hi
			in_text: Result.lo >= 0 and Result.hi <= a_text.count
		end

	word_class (c: CHARACTER_32): INTEGER
			-- 0 a separator (space or punctuation), 1 a digit, 2 a letter,
			-- a mark or anything else a word is made of.
		do
			if c.is_space or else Separators.has (c) then
				Result := 0
			elseif c >= '0' and c <= '9' then
				Result := 1
			else
				Result := 2
			end
		ensure
			known: Result >= 0 and Result <= 2
		end

	Separators: STRING_32
			-- Punctuation that ends a word, Hebrew and Greek included.
		once
			Result := {STRING_32} ".,;:!?%"'()[]{}<>/-"
			Result.append_code (0x2014)
			Result.append_code (0x2013)
			Result.append_code (0x2018)
			Result.append_code (0x2019)
			Result.append_code (0x201C)
			Result.append_code (0x201D)
			Result.append_code (0x00AB)
			Result.append_code (0x00BB)
			Result.append_code (0x00B7)
			Result.append_code (0x05BE)
			Result.append_code (0x05C0)
			Result.append_code (0x05C3)
			Result.append_code (0x0387)
			Result.append_code (0x037E)
		end

end
