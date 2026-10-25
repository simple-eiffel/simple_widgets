note
	description: "[
		A condition of a query (GW-12): a field, an operator (=, /=, >, <,
		contains) and a value. A numeric value stands bare in the SQL-shaped
		text, any other is single-quoted; contains becomes LIKE.
	]"
	author: "Larry Rix"

class
	SW_QUERY_CONDITION

inherit
	SW_QUERY_NODE

create
	make

feature {NONE} -- Initialization

	make (a_field, a_op: INTEGER; a_value: READABLE_STRING_GENERAL)
		require
			field_positive: a_field >= 1
			op_known: a_op >= 1 and a_op <= Op_count
		do
			field_index := a_field
			op_index := a_op
			create value.make_from_string_general (a_value)
		ensure
			set: field_index = a_field and op_index = a_op and value.same_string_general (a_value)
		end

feature -- Constants

	Op_count: INTEGER = 5

	op_name (a_op: INTEGER): STRING_32
		require
			known: a_op >= 1 and a_op <= Op_count
		do
			inspect a_op
			when 1 then
				Result := {STRING_32} "="
			when 2 then
				Result := {STRING_32} "/="
			when 3 then
				Result := {STRING_32} ">"
			when 4 then
				Result := {STRING_32} "<"
			else
				Result := {STRING_32} "contains"
			end
		end

feature -- Access

	field_index, op_index: INTEGER
	value: STRING_32

	is_complete: BOOLEAN
		do
			Result := not value.is_empty
		end

	expression (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
		do
			create Result.make_empty
			if is_complete then
				Result.append (a_fields.i_th (field_index.min (a_fields.count)))
				Result.append_character (' ')
				Result.append (op_name (op_index))
				Result.append ({STRING_32} " %"")
				Result.append (value)
				Result.append_character ('%"')
				Result := negated (Result)
			end
		end

	sql_text (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
		do
			create Result.make_empty
			if is_complete then
				Result.append (a_fields.i_th (field_index.min (a_fields.count)))
				if op_index = 5 then
					Result.append ({STRING_32} " LIKE ")
					Result.append (quoted ({STRING_32} "%%" + value + {STRING_32} "%%"))
				else
					Result.append_character (' ')
					Result.append (op_name (op_index))
					Result.append_character (' ')
					if value.is_double then
						Result.append (value)
					else
						Result.append (quoted (value))
					end
				end
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

	set_op (a_op: INTEGER)
		require
			op_known: a_op >= 1 and a_op <= Op_count
		do
			op_index := a_op
		end

	set_value (a_value: READABLE_STRING_GENERAL)
		do
			create value.make_from_string_general (a_value)
		ensure
			set: value.same_string_general (a_value)
		end

invariant
	op_known: op_index >= 1 and op_index <= Op_count
	field_positive: field_index >= 1

end
