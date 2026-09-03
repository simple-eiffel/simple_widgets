note
	description: "[
		Predicates by hand: rows of field / operator / value, joined
		ALL or ANY, emitting an SQL-shaped WHERE text on demand -
		the emission (query_text) is pure public string math,
		assaulted on quoting, joining, numeric-vs-text detection and
		emptiness. The rows are combos and a box; edits sync back to
		the clause model by TEXT (the combo picks by filling its own
		text - its nature), and hosts read query_text or subscribe
		to on_change. Deliberately NOT here: executing anything -
		this builds the question, never answers it.
	]"

class
	SW_QUERY_BUILDER

inherit
	SW_COLUMN
		rename
			make as make_column
		redefine
			default_gap
		end

create
	make

feature {NONE} -- Initialization

	make (a_fields: ITERABLE [READABLE_STRING_GENERAL])
		do
			make_column
			create fields.make (4)
			across
				a_fields as f
			loop
				fields.extend (create {STRING_32}.make_from_string_general (f))
			end
			create clauses.make (4)
			create row_organs.make (4)
			join_all := True
			rebuild_rows
		end


feature -- Spacing (theme defaults; an explicit value still wins)

	default_gap (a_p: SW_PAINTER): REAL_64
			-- 6 px at 1x, as before, now scaled with the text.
		do
			Result := a_p.theme.padding * 0.75
		end

feature -- Access

	fields: ARRAYED_LIST [STRING_32]

	clauses: ARRAYED_LIST [TUPLE [field_index, op_index: INTEGER; value: STRING_32]]

	join_all: BOOLEAN
			-- True = AND between clauses; False = OR.

	on_change: detachable PROCEDURE

	Op_count: INTEGER = 5

	op_name (a_i: INTEGER): STRING_32
		require
			known: a_i >= 1 and a_i <= Op_count
		do
			inspect a_i
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

	query_text: STRING_32
			-- The WHERE text: numeric values bare, text values
			-- single-quoted with doubled inner quotes; contains
			-- becomes LIKE with wildcards. Clauses without a value
			-- are skipped; none at all yields empty.
		local
			part: STRING_32
			first_done: BOOLEAN
		do
			create Result.make (48)
			across
				clauses as c
			loop
				if not c.value.is_empty then
					create part.make (24)
					part.append (fields.i_th (c.field_index))
					if c.op_index = 5 then
						part.append ({STRING_32} " LIKE '%%")
						append_escaped (part, c.value)
						part.append ({STRING_32} "%%'")
					else
						part.append_character (' ')
						part.append (op_name (c.op_index))
						part.append_character (' ')
						if c.value.is_double then
							part.append (c.value)
						else
							part.append_character ('%'')
							append_escaped (part, c.value)
							part.append_character ('%'')
						end
					end
					if first_done then
						if join_all then
							Result.append ({STRING_32} " AND ")
						else
							Result.append ({STRING_32} " OR ")
						end
					end
					Result.append (part)
					first_done := True
				end
			end
		end

feature -- Element change

	add_clause
		do
			clauses.extend ([1, 1, create {STRING_32}.make_empty])
			rebuild_rows
		ensure
			grew: clauses.count = old clauses.count + 1
		end

	set_clause (a_index, a_field, a_op: INTEGER; a_value: READABLE_STRING_GENERAL)
			-- The model path, widget-free - the assaults drive this.
		require
			clause_known: a_index >= 1 and a_index <= clauses.count
			field_known: a_field >= 1 and a_field <= fields.count
			op_known: a_op >= 1 and a_op <= Op_count
		local
			v: STRING_32
		do
			create v.make_from_string_general (a_value)
			clauses.i_th (a_index).field_index := a_field
			clauses.i_th (a_index).op_index := a_op
			clauses.i_th (a_index).value := v
			announce
		end

	set_join_all (a_all: BOOLEAN)
		do
			join_all := a_all
			announce
		ensure
			set: join_all = a_all
		end

	set_on_change (a_action: PROCEDURE)
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature {NONE} -- Rows

	row_organs: ARRAYED_LIST [TUPLE [fc, oc: SW_COMBO; vb: SW_TEXT_BOX]]

	rebuild_rows
		local
			i: INTEGER
			row: SW_ROW
			fc, oc: SW_COMBO
			vb: SW_TEXT_BOX
		do
			children.wipe_out
			row_organs.wipe_out
			from
				i := 1
			until
				i > clauses.count
			loop
				create row.make
				row := row.with_gap (6.0)
				create fc.make_with_options
				across
					fields as f
				loop
					fc.add_option (f)
				end
				fc.set_text (fields.i_th (clauses.i_th (i).field_index))
				fc.set_on_change (agent sync_from_widgets)
				create oc.make_with_options
				var_ops (oc)
				oc.set_text (op_name (clauses.i_th (i).op_index))
				oc.set_on_change (agent sync_from_widgets)
				create vb.make_single_line (clauses.i_th (i).value)
				vb.set_on_change (agent sync_from_widgets)
				row_organs.extend ([fc, oc, vb])
				row.put (fc)
				row.put (oc)
				row.put (vb.growing)
				put (row)
				i := i + 1
			end
			put (create {SW_BUTTON}.make ("+ condition", agent add_clause))
		end

	var_ops (a_combo: SW_COMBO)
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > Op_count
			loop
				a_combo.add_option (op_name (i))
				i := i + 1
			end
		end

	sync_from_widgets
			-- Texts back into the clause model; unknown texts keep
			-- the prior index (a combo mid-typing stays harmless).
		local
			i, j: INTEGER
			v: STRING_32
		do
			from
				i := 1
			until
				i > row_organs.count or i > clauses.count
			loop
				from
					j := 1
				until
					j > fields.count
				loop
					if row_organs.i_th (i).fc.text.same_string (fields.i_th (j)) then
						clauses.i_th (i).field_index := j
					end
					j := j + 1
				end
				from
					j := 1
				until
					j > Op_count
				loop
					if row_organs.i_th (i).oc.text.same_string (op_name (j)) then
						clauses.i_th (i).op_index := j
					end
					j := j + 1
				end
				create v.make_from_string (row_organs.i_th (i).vb.text)
				clauses.i_th (i).value := v
				i := i + 1
			end
			announce
		end

	append_escaped (a_to: STRING_32; a_value: STRING_32)
			-- Single quotes doubled, the SQL way.
		do
			across
				a_value as ch
			loop
				if ch = '%'' then
					a_to.append ({STRING_32} "''")
				else
					a_to.append_character (ch)
				end
			end
		end

	announce
		do
			if attached on_change as a then
				a.call (Void)
			end
		end

invariant
	organs: fields /= Void and clauses /= Void and row_organs /= Void

end
