note
	description: "A concordance row for the GW-29 grid assault: a citation, the word, the line."

class
	SW_TEST_CONC_ROW

create
	make

feature {NONE} -- Initialization

	make (a_citation, a_word, a_line: STRING_32)
		do
			citation := a_citation
			word := a_word
			line := a_line
		end

feature -- Access

	citation, word, line: STRING_32

end
