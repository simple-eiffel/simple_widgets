note
	description: "[
		A proximity of a query (GW-12): two words of a field within
		`distance' words of each other - in either order, or with the first
		before the second (`is_ordered'). "light" NEAR/5 "darkness";
		"in" BEFORE/2 "beginning". There is no SQL for it; its SQL-shaped
		text is a display form only.
	]"
	author: "Larry Rix"

class
	SW_QUERY_PROXIMITY

inherit
	SW_QUERY_NODE

create
	make

feature {NONE} -- Initialization

	make (a_field: INTEGER; a_first, a_second: READABLE_STRING_GENERAL; a_distance: INTEGER)
		require
			field_positive: a_field >= 1
			distance_positive: a_distance >= 1
		do
			field_index := a_field
			create first.make_from_string_general (a_first)
			create second.make_from_string_general (a_second)
			distance := a_distance
		ensure
			set: field_index = a_field and distance = a_distance
		end

feature -- Access

	field_index: INTEGER
	first, second: STRING_32
	distance: INTEGER
			-- Words apart, at most.

	is_ordered: BOOLEAN
			-- Must `first' come before `second'?

	is_complete: BOOLEAN
		do
			Result := not first.is_empty and not second.is_empty
		end

	expression (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
		do
			create Result.make_empty
			if is_complete then
				Result.append ({STRING_32} "%"")
				Result.append (first)
				Result.append ({STRING_32} "%" ")
				Result.append (if is_ordered then {STRING_32} "BEFORE/" else {STRING_32} "NEAR/" end)
				Result.append_integer (distance)
				Result.append ({STRING_32} " %"")
				Result.append (second)
				Result.append_character ('%"')
				Result.append ({STRING_32} " in ")
				Result.append (a_fields.i_th (field_index.min (a_fields.count)))
				Result := negated (Result)
			end
		end

	sql_text (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
		do
			create Result.make_empty
			if is_complete then
				Result.append (if is_ordered then {STRING_32} "BEFORE(" else {STRING_32} "NEAR(" end)
				Result.append (a_fields.i_th (field_index.min (a_fields.count)))
				Result.append ({STRING_32} ", ")
				Result.append (quoted (first))
				Result.append ({STRING_32} ", ")
				Result.append (quoted (second))
				Result.append ({STRING_32} ", ")
				Result.append_integer (distance)
				Result.append_character (')')
				Result := negated (Result)
			end
		end

feature -- Element change

	set_field (a_field: INTEGER)
		require
			field_positive: a_field >= 1
		do
			field_index := a_field
		end

	set_first (a_word: READABLE_STRING_GENERAL)
		do
			create first.make_from_string_general (a_word)
		end

	set_second (a_word: READABLE_STRING_GENERAL)
		do
			create second.make_from_string_general (a_word)
		end

	set_distance (a_words: INTEGER)
		require
			positive: a_words >= 1
		do
			distance := a_words
		ensure
			set: distance = a_words
		end

	set_ordered (a_on: BOOLEAN)
		do
			is_ordered := a_on
		ensure
			set: is_ordered = a_on
		end

invariant
	distance_positive: distance >= 1
	field_positive: field_index >= 1

end
