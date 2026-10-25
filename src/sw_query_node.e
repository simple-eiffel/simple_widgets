note
	description: "[
		One node of an SW_QUERY_BUILDER's clause tree (GW-12): a group of
		nodes joined ALL or ANY, a condition (field, operator, value), or
		a proximity (two words within a distance of each other). Any node
		can be negated. The ENGINE reads the tree and builds its own
		parameterized query; the texts a node writes (`expression' to
		show the reader, `sql_text' for a display) are never executed.
	]"
	author: "Larry Rix"

deferred class
	SW_QUERY_NODE

feature -- Access

	is_negated: BOOLEAN
			-- NOT this node?

	is_complete: BOOLEAN
			-- Does the node say enough to search by (a value given, a group
			-- with a complete child)?
		deferred
		end

	expression (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
			-- The node as the reader reads it: `lemma = "bara"', `NOT (...)',
			-- `"light" NEAR/5 "darkness"'. Empty when incomplete.
		require
			fields_given: not a_fields.is_empty
		deferred
		ensure
			empty_iff_incomplete: Result.is_empty = not is_complete
		end

	sql_text (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
			-- An SQL-shaped rendering, for display only. Empty when
			-- incomplete.
		require
			fields_given: not a_fields.is_empty
		deferred
		ensure
			empty_iff_incomplete: Result.is_empty = not is_complete
		end

feature -- Element change

	set_negated (a_on: BOOLEAN)
		do
			is_negated := a_on
		ensure
			set: is_negated = a_on
		end

feature {NONE} -- Implementation

	negated (a_text: STRING_32): STRING_32
			-- `a_text', under NOT when the node is negated.
		do
			if is_negated and then not a_text.is_empty then
				Result := {STRING_32} "NOT (" + a_text + {STRING_32} ")"
			else
				Result := a_text
			end
		end

	quoted (a_value: READABLE_STRING_32): STRING_32
			-- `a_value' in single quotes, inner quotes doubled.
		do
			create Result.make (a_value.count + 2)
			Result.append_character ('%'')
			across a_value as ch loop
				if ch = '%'' then
					Result.append ({STRING_32} "''")
				else
					Result.extend (ch)
				end
			end
			Result.append_character ('%'')
		end

end
