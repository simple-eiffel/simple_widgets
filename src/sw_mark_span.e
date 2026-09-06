note
	description: "[
		One highlighted range of a text: characters `lo' + 1 .. `hi'
		(the caret-offset convention SW_TEXT_BOX's selection uses), the
		REASON it carries, an optional explicit look that beats the
		legend's, and a free annotation. Owned and kept honest by
		SW_MARKED_TEXT, which is where ranges move as the text changes.
	]"
	author: "Larry Rix"

class
	SW_MARK_SPAN

create
	make

feature {NONE} -- Initialization

	make (a_id, a_lo, a_hi: INTEGER; a_reason: READABLE_STRING_GENERAL)
		require
			id_positive: a_id > 0
			range_valid: a_lo >= 0 and a_lo < a_hi
			reason_valid: is_valid_reason (a_reason)
		do
			id := a_id
			lo := a_lo
			hi := a_hi
			reason := a_reason.to_string_32
			create annotation.make_empty
		ensure
			id_set: id = a_id
			range_set: lo = a_lo and hi = a_hi
			reason_set: reason.same_string_general (a_reason)
		end

feature -- Access

	id: INTEGER
			-- Stable for the span's life; unique within its text.

	lo: INTEGER
			-- Caret offset before the first marked character.

	hi: INTEGER
			-- Caret offset after the last marked character.

	reason: STRING_32
			-- Why: the legend key.

	mark: detachable SW_MARK
			-- An explicit look; Void means "the legend's for `reason'".

	annotation: STRING_32
			-- Anything the application wants to keep with the span.

	count: INTEGER
			-- Characters covered.
		do
			Result := hi - lo
		ensure
			definition: Result = hi - lo
		end

	covers (a_offset_of_char: INTEGER): BOOLEAN
			-- Is character `a_offset_of_char' (1-based) inside?
		do
			Result := a_offset_of_char > lo and a_offset_of_char <= hi
		end

	overlaps (a_lo, a_hi: INTEGER): BOOLEAN
			-- Does the range `a_lo' .. `a_hi' (same convention) touch this one?
		do
			Result := a_lo < hi and a_hi > lo
		end

feature -- Element change

	set_range (a_lo, a_hi: INTEGER)
		require
			range_valid: a_lo >= 0 and a_lo < a_hi
		do
			lo := a_lo
			hi := a_hi
		ensure
			set: lo = a_lo and hi = a_hi
		end

	set_reason (a_reason: READABLE_STRING_GENERAL)
		require
			reason_valid: is_valid_reason (a_reason)
		do
			reason := a_reason.to_string_32
		ensure
			set: reason.same_string_general (a_reason)
		end

	set_mark (a_mark: detachable SW_MARK)
		do
			mark := a_mark
		ensure
			set: mark = a_mark
		end

	set_annotation (a_note: READABLE_STRING_GENERAL)
		require
			note_valid: not a_note.has ('%N') and not a_note.has ('|')
		do
			annotation := a_note.to_string_32
		ensure
			set: annotation.same_string_general (a_note)
		end

feature -- Status

	is_valid_reason (a_reason: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := not a_reason.is_empty and then not a_reason.has ('%N')
				and then not a_reason.has ('|')
		end

invariant
	id_positive: id > 0
	range_valid: lo >= 0 and lo < hi
	reason_valid: is_valid_reason (reason)

end
