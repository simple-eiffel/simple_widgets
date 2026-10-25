note
	description: "[
		One word of an SW_INTERLINEAR (GW-07): its lines - the surface
		word, transliteration, pronunciation, gloss, lemma, Strong's
		number and morphology in English - each a simple_document
		DOC_TEXT, and the verse label it opens ("1:1"), empty when it does
		not start a verse. The transliteration is set italic.
	]"
	author: "Larry Rix"

class
	SW_INTERLINEAR_TOKEN

create
	make

feature {NONE} -- Initialization

	make (a_surface: READABLE_STRING_GENERAL)
			-- The word `a_surface', its other lines empty.
		local
			k: INTEGER
		do
			create lines.make (Line_count)
			from
				k := 1
			until
				k > Line_count
			loop
				lines.extend (create {DOC_TEXT}.make ({STRING_32} ""))
				k := k + 1
			end
			lines.first.set_text (a_surface)
			create verse_label.make_empty
		ensure
			surface_kept: line (Line_surface).text.same_string_general (a_surface)
		end

feature -- Constants

	Line_surface: INTEGER = 1
	Line_transliteration: INTEGER = 2
	Line_pronunciation: INTEGER = 3
	Line_gloss: INTEGER = 4
	Line_lemma: INTEGER = 5
	Line_strongs: INTEGER = 6
	Line_morphology: INTEGER = 7
	Line_count: INTEGER = 7

	is_valid_line (a_line: INTEGER): BOOLEAN
		do
			Result := a_line >= 1 and a_line <= Line_count
		end

feature -- Access

	line (a_line: INTEGER): DOC_TEXT
		require
			valid: is_valid_line (a_line)
		do
			Result := lines.i_th (a_line)
		end

	verse_label: STRING_32
			-- The verse this word opens; empty when it opens none.

	revision: INTEGER
			-- Grows whenever a line changes.
		do
			Result := own_revision
			across lines as l loop
				Result := Result + l.revision
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Element change

	set_line (a_line: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Line `a_line' reads `a_text' (the transliteration italic).
		require
			valid: is_valid_line (a_line)
		do
			lines.i_th (a_line).set_text (a_text)
			lines.i_th (a_line).remove_spans
			if a_line = Line_transliteration and then a_text.count > 0 then
				lines.i_th (a_line).add_italic (1, a_text.count)
			end
		ensure
			set: line (a_line).text.same_string_general (a_text)
		end

	set_verse_label (a_label: READABLE_STRING_GENERAL)
		do
			create verse_label.make_from_string_general (a_label)
			own_revision := own_revision + 1
		ensure
			set: verse_label.same_string_general (a_label)
		end

feature {NONE} -- Implementation

	lines: ARRAYED_LIST [DOC_TEXT]
	own_revision: INTEGER

invariant
	seven_lines: lines.count = Line_count

end
