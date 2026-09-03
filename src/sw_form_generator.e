note
	description: "[
		Forms from specs: declare fields (text, number, check,
		choice) and the generator builds the labelled column - the
		whole input fleet reused, nothing hand-laid. The VALUES
		read back as a name->text table (value_of / values_table),
		and required fields report through is_complete - the model
		surface the assault drives without a single pixel. Pairs
		with Smart Paste when R03 lands, as the roadmap pinned.
	]"

class
	SW_FORM_GENERATOR

inherit
	SW_COLUMN
		rename
			make as make_column
		end

create
	make

feature -- Kinds

	Kind_text: INTEGER = 1
	Kind_number: INTEGER = 2
	Kind_check: INTEGER = 3
	Kind_choice: INTEGER = 4

feature {NONE} -- Initialization

	make
		do
			make_column
			create specs.make (6)
			create boxes.make (6)
			create checks.make (6)
		end

feature -- Access

	specs: ARRAYED_LIST [TUPLE [name: STRING_32; kind: INTEGER; required: BOOLEAN]]

	value_of (a_name: READABLE_STRING_GENERAL): STRING_32
			-- The field's current text ("True"/"False" for checks);
			-- empty for unknown names.
		local
			i: INTEGER
		do
			create Result.make_empty
			from
				i := 1
			until
				i > specs.count
			loop
				if specs.i_th (i).name.same_string_general (a_name) then
					if specs.i_th (i).kind = Kind_check then
						if attached checks.item (i) as cb then
							Result := cb.is_checked.out.to_string_32
						end
					elseif attached boxes.item (i) as tb then
						Result := tb.text.twin
					end
				end
				i := i + 1
			end
		end

	is_complete: BOOLEAN
			-- Does every REQUIRED field hold something?
		local
			i: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > specs.count
			loop
				if specs.i_th (i).required and then specs.i_th (i).kind /= Kind_check then
					if attached boxes.item (i) as tb then
						Result := Result and not tb.text.is_empty
					end
				end
				i := i + 1
			end
		end

feature -- Element change

	add_field (a_name: READABLE_STRING_GENERAL; a_kind: INTEGER; a_required: BOOLEAN)
			-- Declare and build one labelled row.
		require
			kind_known: a_kind >= Kind_text and a_kind <= Kind_choice
		local
			n: STRING_32
			row: SW_ROW
			tb: SW_TEXT_BOX
			cb: SW_CHECK_BOX
			lbl: SW_LABEL
		do
			create n.make_from_string_general (a_name)
			specs.extend ([n, a_kind, a_required])
			create row.make
			row := row.with_gap (8.0)
			if a_required then
				create lbl.make_ui (n + {STRING_32} " *")
			else
				create lbl.make_ui (n)
			end
			lbl := lbl.with_min_size (130.0, 0.0)
			row.put (lbl)
			if a_kind = Kind_check then
				create cb.make ("", False, Void)
				checks.force (cb, specs.count)
				row.put (cb)
			else
				create tb.make_single_line ("")
				boxes.force (tb, specs.count)
				row.put (tb.growing)
			end
			put (row)
		ensure
			grew: specs.count = old specs.count + 1
		end

	add_choice_field (a_name: READABLE_STRING_GENERAL; a_options: ITERABLE [READABLE_STRING_GENERAL]; a_required: BOOLEAN)
		local
			n: STRING_32
			row: SW_ROW
			co: SW_COMBO
			lbl: SW_LABEL
		do
			create n.make_from_string_general (a_name)
			specs.extend ([n, Kind_choice, a_required])
			create row.make
			row := row.with_gap (8.0)
			if a_required then
				create lbl.make_ui (n + {STRING_32} " *")
			else
				create lbl.make_ui (n)
			end
			lbl := lbl.with_min_size (130.0, 0.0)
			row.put (lbl)
			create co.make_with_options
			across
				a_options as o
			loop
				co.add_option (o)
			end
			boxes.force (co, specs.count)
			row.put (co.growing)
			put (row)
		ensure
			grew: specs.count = old specs.count + 1
		end

	set_value (a_name, a_text: READABLE_STRING_GENERAL)
			-- Programmatic fill - the assault's hand, and Smart
			-- Paste's doorway later.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > specs.count
			loop
				if specs.i_th (i).name.same_string_general (a_name)
					and then attached boxes.item (i) as tb
				then
					tb.set_text (a_text)
				end
				i := i + 1
			end
		end

feature {NONE} -- Organs

	boxes: HASH_TABLE [SW_TEXT_BOX, INTEGER]
			-- Spec index -> its box (combos are boxes too).

	checks: HASH_TABLE [SW_CHECK_BOX, INTEGER]

invariant
	organs: specs /= Void and boxes /= Void and checks /= Void

end
