note
	description: "[
		Windows' inbox spell checker (ISpellChecker, Windows 8+) as a
		SURFACE-layer service - the zero-model, zero-license AI-assist.
		The COM machinery lives in simple_shell (SHELL_SPELLER); this
		facade keeps the toolkit vocabulary. Absent language support
		degrades to no findings, never to failure. WINDOWS-ONLY by the
		toolkit's charter; any port must treat this seam as a seam.

		OTHER SCRIPTS ARE NOT MISSPELLED (0.22.0). The checker reads
		with the user's Latin-script language, so every Hebrew or Greek
		word it meets came back "misspelled" and a Bible note was covered
		in red. A finding is kept only when its word is written in Latin
		script.
	]"

class
	SW_SPELLER

inherit
	SHELL_SPELLER
		redefine
			misspellings
		end

feature -- Queries

	misspellings (a_text: READABLE_STRING_GENERAL): ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- The checker's findings, less every word written in another
			-- script than Latin.
		do
			create Result.make (8)
			across Precursor (a_text) as r loop
				if r.hi <= a_text.count and then not has_other_script (a_text, r.lo + 1, r.hi) then
					Result.extend (r)
				end
			end
		ensure then
			latin_only: across Result as r all not has_other_script (a_text, r.lo + 1, r.hi) end
		end

	has_other_script (a_text: READABLE_STRING_GENERAL; a_from, a_to: INTEGER): BOOLEAN
			-- Does a character of `a_from' .. `a_to' belong to a script
			-- other than Latin (Greek, Hebrew, Arabic, Cyrillic, ...)?
			-- Punctuation and symbols do not count.
		require
			range_valid: a_from >= 1 and a_to <= a_text.count
		local
			i: INTEGER
			c: NATURAL_32
		do
			from
				i := a_from
			until
				i > a_to or Result
			loop
				c := a_text.code (i)
				Result := c >= 0x0370 and then not (c >= 0x1E00 and c <= 0x1EFF)
					and then not (c >= 0x2000 and c <= 0x2BFF)
				i := i + 1
			end
		end

end
