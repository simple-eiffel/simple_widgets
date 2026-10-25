note
	description: "[
		A group of a query (GW-12): child nodes joined ALL (AND) or ANY
		(OR), nested to any depth. Incomplete children are left out of the
		texts; a group with no complete child is itself incomplete.
	]"
	author: "Larry Rix"

class
	SW_QUERY_GROUP

inherit
	SW_QUERY_NODE

create
	make

feature {NONE} -- Initialization

	make
			-- Empty, joined ALL.
		do
			create children.make (4)
			join_all := True
		ensure
			empty: children.is_empty
			all_by_default: join_all
		end

feature -- Access

	children: ARRAYED_LIST [SW_QUERY_NODE]

	join_all: BOOLEAN
			-- AND between children; False: OR.

	is_complete: BOOLEAN
		do
			Result := across children as c some c.is_complete end
		end

	expression (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
		do
			Result := joined (a_fields, True, if join_all then {STRING_32} " AND " else {STRING_32} " OR " end)
		end

	sql_text (a_fields: ARRAYED_LIST [STRING_32]): STRING_32
		do
			Result := joined (a_fields, False, if join_all then {STRING_32} " AND " else {STRING_32} " OR " end)
		end

feature -- Element change

	set_join_all (a_all: BOOLEAN)
		do
			join_all := a_all
		ensure
			set: join_all = a_all
		end

	add_condition (a_field, a_op: INTEGER; a_value: READABLE_STRING_GENERAL): SW_QUERY_CONDITION
		require
			field_positive: a_field >= 1
			op_known: a_op >= 1 and a_op <= {SW_QUERY_CONDITION}.Op_count
		do
			create Result.make (a_field, a_op, a_value)
			children.extend (Result)
		ensure
			one_more: children.count = old children.count + 1
		end

	add_group: SW_QUERY_GROUP
		do
			create Result.make
			children.extend (Result)
		ensure
			one_more: children.count = old children.count + 1
		end

	add_proximity (a_field: INTEGER; a_first, a_second: READABLE_STRING_GENERAL; a_distance: INTEGER): SW_QUERY_PROXIMITY
		require
			field_positive: a_field >= 1
			distance_positive: a_distance >= 1
		do
			create Result.make (a_field, a_first, a_second, a_distance)
			children.extend (Result)
		ensure
			one_more: children.count = old children.count + 1
		end

	remove (a_node: SW_QUERY_NODE)
			-- `a_node' goes (wherever it stands below this group).
		local
			i: INTEGER
		do
			from
				i := children.count
			until
				i < 1
			loop
				if children.i_th (i) = a_node then
					children.go_i_th (i)
					children.remove
				elseif attached {SW_QUERY_GROUP} children.i_th (i) as al_g then
					al_g.remove (a_node)
				end
				i := i - 1
			end
		end

feature {NONE} -- Implementation

	joined (a_fields: ARRAYED_LIST [STRING_32]; a_readable: BOOLEAN; a_join: STRING_32): STRING_32
			-- The complete children's texts joined by `a_join', each nested
			-- group in parentheses; NOT around it all when negated.
		local
			l_part: STRING_32
			n: INTEGER
		do
			create Result.make (64)
			across children as c loop
				if c.is_complete then
					if a_readable then
						l_part := c.expression (a_fields)
					else
						l_part := c.sql_text (a_fields)
					end
					if attached {SW_QUERY_GROUP} c as al_g and then not al_g.is_negated then
						l_part := {STRING_32} "(" + l_part + {STRING_32} ")"
					end
					if n > 0 then
						Result.append (a_join)
					end
					Result.append (l_part)
					n := n + 1
				end
			end
			Result := negated (Result)
		end

end
