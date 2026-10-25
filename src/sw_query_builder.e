note
	description: "[
		A question built by hand, as a clause TREE (GW-12): groups joined
		ALL or ANY and nested to any depth, conditions (field / operator /
		value), proximities ("light" within 5 words of "darkness", in
		either order or in order), and NOT on any of them. simple_bible's
		Search Builder and Census criteria (B01, B05, D03) are built on it.

		THE ENGINE READS `root' - an SW_QUERY_GROUP of SW_QUERY_NODEs - and
		builds its own parameterized query. Nothing here executes anything:
		`expression' is the question as the reader reads it, and
		`query_text' an SQL-shaped rendering for display (and for the flat
		builder's older callers).

		TYPED VALUES. A field is text (a box), a number (a box), a choice
		(`set_field_choices': a picker of codes, morphology for one) or a
		lemma (`set_field_suggester': a picker whose choices follow what is
		typed). Every control carries the node it edits, so an edit goes
		straight to the tree; adding, removing or re-typing a row rebuilds
		the rows. `on_change' hears every change.

		The flat calls of the first builder still work on the root group:
		`add_clause', `set_clause', `set_join_all', `query_text'.
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
			create field_kinds.make (4)
			create field_choices.make (4)
			create suggesters.make (4)
			across a_fields as f loop
				fields.extend (create {STRING_32}.make_from_string_general (f))
				field_kinds.extend (Field_text)
				field_choices.extend (Void)
				suggesters.extend (Void)
			end
			create root.make
			rebuild_rows
		end

feature -- Spacing (theme defaults; an explicit value still wins)

	default_gap (a_p: SW_PAINTER): REAL_64
			-- 6 px at 1x, as before, now scaled with the text.
		do
			Result := a_p.theme.padding * 0.75
		end

feature -- Constants

	Field_text: INTEGER = 1
	Field_number: INTEGER = 2
	Field_choice: INTEGER = 3
	Field_lemma: INTEGER = 4

	Op_count: INTEGER = 5

	op_name (a_i: INTEGER): STRING_32
		require
			known: a_i >= 1 and a_i <= Op_count
		do
			Result := (create {SW_QUERY_CONDITION}.make (1, 1, "")).op_name (a_i)
		end

feature -- Access

	fields: ARRAYED_LIST [STRING_32]

	root: SW_QUERY_GROUP
			-- The clause tree: what the engine reads.

	join_all: BOOLEAN
			-- The root group's join: AND (True) or OR.
		do
			Result := root.join_all
		end

	on_change: detachable PROCEDURE

	field_kind (a_field: INTEGER): INTEGER
		require
			valid: a_field >= 1 and a_field <= fields.count
		do
			Result := field_kinds.i_th (a_field)
		end

	expression: STRING_32
			-- The question as the reader reads it; empty when nothing is
			-- complete.
		do
			Result := root.expression (fields)
		end

	query_text: STRING_32
			-- An SQL-shaped rendering, for display only; empty when nothing
			-- is complete. Never executed.
		do
			Result := root.sql_text (fields)
		end

feature -- Field types

	set_field_kind (a_field, a_kind: INTEGER)
		require
			valid: a_field >= 1 and a_field <= fields.count
			kind_known: a_kind >= Field_text and a_kind <= Field_lemma
		do
			field_kinds.put_i_th (a_kind, a_field)
			rebuild_rows
		ensure
			set: field_kind (a_field) = a_kind
		end

	set_field_choices (a_field: INTEGER; a_choices: ITERABLE [READABLE_STRING_GENERAL])
			-- Field `a_field' takes one of `a_choices' (codes).
		require
			valid: a_field >= 1 and a_field <= fields.count
		local
			l: ARRAYED_LIST [STRING_32]
		do
			create l.make (8)
			across a_choices as c loop
				l.extend (c.to_string_32)
			end
			field_choices.put_i_th (l, a_field)
			field_kinds.put_i_th (Field_choice, a_field)
			rebuild_rows
		ensure
			a_choice: field_kind (a_field) = Field_choice
		end

	set_field_suggester (a_field: INTEGER; a_suggester: FUNCTION [STRING_32, ITERABLE [READABLE_STRING_GENERAL]])
			-- Field `a_field' is a lemma: its picker offers what
			-- `a_suggester' answers for the text typed so far.
		require
			valid: a_field >= 1 and a_field <= fields.count
		do
			suggesters.put_i_th (a_suggester, a_field)
			field_kinds.put_i_th (Field_lemma, a_field)
			rebuild_rows
		ensure
			a_lemma: field_kind (a_field) = Field_lemma
		end

feature -- Building the tree

	add_condition_to (a_group: SW_QUERY_GROUP)
			-- A new, empty condition at the end of `a_group'.
		do
			a_group.add_condition (1, 1, "").do_nothing
			changed_structure
		end

	add_group_to (a_group: SW_QUERY_GROUP)
			-- A new group, holding one empty condition, at the end of `a_group'.
		do
			a_group.add_group.add_condition (1, 1, "").do_nothing
			changed_structure
		end

	add_proximity_to (a_group: SW_QUERY_GROUP)
			-- A new proximity (within 5 words) at the end of `a_group'.
		do
			a_group.add_proximity (1, "", "", 5).do_nothing
			changed_structure
		end

	remove_node (a_node: SW_QUERY_NODE)
			-- `a_node' goes from the tree (the root stays).
		do
			root.remove (a_node)
			changed_structure
		end

feature -- Element change (the flat builder's calls, on the root group)

	add_clause
			-- An empty condition at the end of the root group.
		do
			add_condition_to (root)
		end

	set_clause (a_index, a_field, a_op: INTEGER; a_value: READABLE_STRING_GENERAL)
			-- The `a_index'-th condition of the root group, set.
		require
			clause_known: a_index >= 1 and a_index <= root_condition_count
			field_known: a_field >= 1 and a_field <= fields.count
			op_known: a_op >= 1 and a_op <= Op_count
		do
			if attached root_condition (a_index) as al_c then
				al_c.set_field (a_field)
				al_c.set_op (a_op)
				al_c.set_value (a_value)
			end
			rebuild_rows
			announce
		end

	root_condition_count: INTEGER
			-- Conditions directly in the root group.
		do
			across root.children as c loop
				if attached {SW_QUERY_CONDITION} c then
					Result := Result + 1
				end
			end
		end

	set_join_all (a_all: BOOLEAN)
		do
			root.set_join_all (a_all)
			rebuild_rows
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

	field_kinds: ARRAYED_LIST [INTEGER]
	field_choices: ARRAYED_LIST [detachable ARRAYED_LIST [STRING_32]]
	suggesters: ARRAYED_LIST [detachable FUNCTION [STRING_32, ITERABLE [READABLE_STRING_GENERAL]]]

	root_condition (a_index: INTEGER): detachable SW_QUERY_CONDITION
		local
			n: INTEGER
		do
			across root.children as c loop
				if attached {SW_QUERY_CONDITION} c as al_c then
					n := n + 1
					if n = a_index then
						Result := al_c
					end
				end
			end
		end

	rebuild_rows
			-- The controls, from the tree.
		do
			children.wipe_out
			put (group_view (root, True))
		end

	group_view (a_group: SW_QUERY_GROUP; a_root: BOOLEAN): SW_COLUMN
			-- A group: its join and NOT, its children, its add buttons; framed
			-- when nested.
		local
			l_head, l_foot: SW_ROW
			l_join: SW_SEGMENTED
		do
			if a_root then
				create Result.make
			else
				create {SW_GROUP} Result.make_titled ("group")
			end
			create l_head.make
			create l_join.make
			l_join.add_segment ("ALL")
			l_join.add_segment ("ANY")
			l_join.select_segment (if a_group.join_all then 1 else 2 end)
			l_join.set_on_change (agent set_group_join (a_group, ?))
			l_head.put (l_join)
			l_head.put (negation_box (a_group))
			if not a_root then
				l_head.put (create {SW_BUTTON}.make ("remove group", agent remove_node (a_group)))
			end
			Result.put (l_head)
			across a_group.children as c loop
				if attached {SW_QUERY_CONDITION} c as al_c then
					Result.put (condition_row (al_c))
				elseif attached {SW_QUERY_PROXIMITY} c as al_p then
					Result.put (proximity_row (al_p))
				elseif attached {SW_QUERY_GROUP} c as al_g then
					Result.put (group_view (al_g, False))
				end
			end
			create l_foot.make
			l_foot.put (create {SW_BUTTON}.make ("+ condition", agent add_condition_to (a_group)))
			l_foot.put (create {SW_BUTTON}.make ("+ group", agent add_group_to (a_group)))
			l_foot.put (create {SW_BUTTON}.make ("+ near", agent add_proximity_to (a_group)))
			Result.put (l_foot)
		end

	condition_row (a_c: SW_QUERY_CONDITION): SW_ROW
			-- NOT, field, operator, the value's control by the field's type,
			-- remove.
		local
			fc, oc: SW_COMBO
			i: INTEGER
		do
			create Result.make
			Result.put (negation_box (a_c))
			fc := field_combo (a_c.field_index)
			fc.set_on_change (agent condition_field_changed (a_c, fc))
			Result.put (fc)
			create oc.make_with_options
			from
				i := 1
			until
				i > Op_count
			loop
				oc.add_option (op_name (i))
				i := i + 1
			end
			oc.set_text (op_name (a_c.op_index))
			oc.set_on_change (agent condition_op_changed (a_c, oc))
			Result.put (oc)
			Result.put (value_control (a_c).growing)
			Result.put (create {SW_BUTTON}.make ("remove", agent remove_node (a_c)))
		end

	proximity_row (a_p: SW_QUERY_PROXIMITY): SW_COLUMN
			-- Two lines, so it fits beside the others: NOT, field, first word,
			-- "within", distance, "words of", second word; then "in order"
			-- and remove.
		local
			fc: SW_COMBO
			b1, b2: SW_TEXT_BOX
			l_order: SW_CHECK_BOX
			l_words, l_options: SW_ROW
		do
			create Result.make
			create l_words.make
			create l_options.make
			Result.put (l_words)
			Result.put (l_options)
			l_words.put (negation_box (a_p))
			fc := field_combo (a_p.field_index)
			fc.set_on_change (agent proximity_field_changed (a_p, fc))
			l_words.put (fc)
			create b1.make_single_line (a_p.first)
			b1.set_on_change (agent proximity_first_changed (a_p, b1))
			b1.set_preferred_text_width (120.0)
			l_words.put (b1.growing)
			l_words.put (create {SW_LABEL}.make_ui ("within"))
			l_words.put (create {SW_NUMBER_BOX}.make (a_p.distance, 1, 99, agent a_p.set_distance))
			l_words.put (create {SW_LABEL}.make_ui ("words of"))
			create b2.make_single_line (a_p.second)
			b2.set_on_change (agent proximity_second_changed (a_p, b2))
			b2.set_preferred_text_width (120.0)
			l_words.put (b2.growing)
			create l_order.make ("in order", a_p.is_ordered, Void)
			l_order.set_on_change (agent proximity_order_changed (a_p, l_order))
			l_options.put (l_order)
			l_options.put (create {SW_BUTTON}.make ("remove", agent remove_node (a_p)))
		end

	value_control (a_c: SW_QUERY_CONDITION): SW_TEXT_BOX
			-- A box for text and numbers; a picker of codes for a choice; a
			-- picker that follows the typing for a lemma.
		local
			l_combo: SW_COMBO
		do
			inspect field_kinds.i_th (a_c.field_index.min (fields.count))
			when Field_choice then
				create l_combo.make_with_options
				if attached field_choices.i_th (a_c.field_index) as al_choices then
					across al_choices as ch loop
						l_combo.add_option (ch)
					end
				end
				l_combo.set_text (a_c.value)
				l_combo.set_on_change (agent condition_value_changed (a_c, l_combo))
				Result := l_combo
			when Field_lemma then
				create l_combo.make_with_options
				l_combo.set_text (a_c.value)
				refresh_suggestions (a_c, l_combo)
				l_combo.set_on_change (agent lemma_typed (a_c, l_combo))
				Result := l_combo
			else
				create Result.make_single_line (a_c.value)
				Result.set_on_change (agent condition_value_changed (a_c, Result))
			end
		end

	field_combo (a_selected: INTEGER): SW_COMBO
		do
			create Result.make_with_options
			across fields as f loop
				Result.add_option (f)
			end
			Result.set_text (fields.i_th (a_selected.min (fields.count)))
		end

	negation_box (a_node: SW_QUERY_NODE): SW_CHECK_BOX
		do
			create Result.make ("not", a_node.is_negated, Void)
			Result.set_on_change (agent negation_changed (a_node, Result))
		end

feature {NONE} -- Edits from the controls

	set_group_join (a_group: SW_QUERY_GROUP; a_segment: INTEGER)
		do
			a_group.set_join_all (a_segment = 1)
			announce
		end

	negation_changed (a_node: SW_QUERY_NODE; a_box: SW_CHECK_BOX)
		do
			a_node.set_negated (a_box.is_checked)
			announce
		end

	condition_field_changed (a_c: SW_QUERY_CONDITION; a_combo: SW_COMBO)
			-- A known field picked: set it; a field of another type rebuilds
			-- the row (its value control changes).
		local
			k, l_old_kind: INTEGER
		do
			k := field_of (a_combo.text)
			if k > 0 and then k /= a_c.field_index then
				l_old_kind := field_kinds.i_th (a_c.field_index.min (fields.count))
				a_c.set_field (k)
				if field_kinds.i_th (k) /= l_old_kind then
					a_c.set_value ("")
					rebuild_rows
				end
				announce
			end
		end

	condition_op_changed (a_c: SW_QUERY_CONDITION; a_combo: SW_COMBO)
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > Op_count
			loop
				if a_combo.text.same_string (op_name (i)) then
					a_c.set_op (i)
				end
				i := i + 1
			end
			announce
		end

	condition_value_changed (a_c: SW_QUERY_CONDITION; a_box: SW_TEXT_BOX)
		do
			a_c.set_value (a_box.text)
			announce
		end

	lemma_typed (a_c: SW_QUERY_CONDITION; a_combo: SW_COMBO)
			-- The lemma's text follows the typing, and so do its choices.
		do
			a_c.set_value (a_combo.text)
			refresh_suggestions (a_c, a_combo)
			announce
		end

	refresh_suggestions (a_c: SW_QUERY_CONDITION; a_combo: SW_COMBO)
		do
			if attached suggesters.i_th (a_c.field_index.min (fields.count)) as al_s then
				a_combo.options.wipe_out
				across al_s.item ([a_c.value.twin]) as s loop
					a_combo.add_option (s)
				end
			end
		end

	proximity_field_changed (a_p: SW_QUERY_PROXIMITY; a_combo: SW_COMBO)
		local
			k: INTEGER
		do
			k := field_of (a_combo.text)
			if k > 0 then
				a_p.set_field (k)
				announce
			end
		end

	proximity_first_changed (a_p: SW_QUERY_PROXIMITY; a_box: SW_TEXT_BOX)
		do
			a_p.set_first (a_box.text)
			announce
		end

	proximity_second_changed (a_p: SW_QUERY_PROXIMITY; a_box: SW_TEXT_BOX)
		do
			a_p.set_second (a_box.text)
			announce
		end

	proximity_order_changed (a_p: SW_QUERY_PROXIMITY; a_box: SW_CHECK_BOX)
		do
			a_p.set_ordered (a_box.is_checked)
			announce
		end

	field_of (a_name: READABLE_STRING_32): INTEGER
			-- The field named `a_name'; 0 for none (a combo mid-typing).
		local
			j: INTEGER
		do
			from
				j := 1
			until
				j > fields.count or Result > 0
			loop
				if fields.i_th (j).same_string (a_name) then
					Result := j
				end
				j := j + 1
			end
		end

	changed_structure
			-- The tree's shape changed: the rows follow, the host hears.
		do
			rebuild_rows
			announce
		end

	announce
		do
			if attached on_change as a then
				a.call (Void)
			end
		end

invariant
	organs: fields /= Void and root /= Void
	parallel_fields: field_kinds.count = fields.count and field_choices.count = fields.count
		and suggesters.count = fields.count

end
