note
	description: "[
		One row of an SW_PARALLEL_TEXT (GW-06): a canonical verse with a
		label ("3:16") and one cell per version column - each a
		simple_document DOC_TEXT with its own SW_MARKED_TEXT (agreement
		classes, word-diff washes) - or a NOTE row: one muted line across
		every column, where the versification map paired unequal numbers
		("LXX 9 = MT 9-10").
	]"
	author: "Larry Rix"

class
	SW_PARALLEL_ROW

create
	make, make_note

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL; a_columns: INTEGER)
			-- A verse row labelled `a_label', `a_columns' empty cells.
		require
			has_columns: a_columns > 0
		local
			c: INTEGER
		do
			create label.make_from_string_general (a_label)
			create cells.make (a_columns)
			create marks.make (a_columns)
			from
				c := 1
			until
				c > a_columns
			loop
				cells.extend (create {DOC_TEXT}.make ({STRING_32} ""))
				marks.extend (create {SW_MARKED_TEXT}.make (0))
				c := c + 1
			end
		ensure
			verse: not is_note
			cells_made: cell_count = a_columns
		end

	make_note (a_text: READABLE_STRING_GENERAL)
			-- A note row reading `a_text'.
		do
			create label.make_empty
			is_note := True
			create cells.make (1)
			create marks.make (1)
			cells.extend (create {DOC_TEXT}.make (a_text))
			marks.extend (create {SW_MARKED_TEXT}.make (a_text.count))
		ensure
			is_a_note: is_note
			one_text: cell_count = 1
		end

feature -- Access

	label: STRING_32
			-- The verse's label; empty for a note.

	is_note: BOOLEAN
			-- A note across every column rather than a verse?

	cell_count: INTEGER
		do
			Result := cells.count
		end

	cell (a_column: INTEGER): DOC_TEXT
		require
			valid: a_column >= 1 and a_column <= cell_count
		do
			Result := cells.i_th (a_column)
		end

	cell_marks (a_column: INTEGER): SW_MARKED_TEXT
			-- The marks over cell `a_column' (kept to its text's length).
		require
			valid: a_column >= 1 and a_column <= cell_count
		do
			Result := marks.i_th (a_column)
			if Result.text_count /= cells.i_th (a_column).count then
				Result.clamp_to (cells.i_th (a_column).count)
			end
		ensure
			fits: Result.text_count = cell (a_column).count
		end

	revision: INTEGER
			-- Grows whenever a cell's text or spans change.
		do
			across cells as c loop
				Result := Result + c.revision
			end
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	cells: ARRAYED_LIST [DOC_TEXT]
	marks: ARRAYED_LIST [SW_MARKED_TEXT]

invariant
	parallel: marks.count = cells.count
	note_is_one_text: is_note implies cells.count = 1

end
