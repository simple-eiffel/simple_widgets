note
	description: "[
		The 7GUIs Cells engine, graduated library-grade - the
		spreadsheet doctrine's middle made real. Everything the demo
		engine proved carries over (formulas led by '=', A0-Z99
		references, + - * / and parentheses, lazy evaluation with
		two cycle guards - the recursive visiting stack AND the
		structural reachability sweep that the value cache taught us
		to need). Graduations: RANGES (A0:B9) inside the aggregate
		functions SUM / AVG / MIN / MAX / COUNT (every member wires
		a dependency, so filling an empty cell inside a summed range
		propagates); TSV block in/out (Excel interop for free); CSV
		serialization of the used extent; and command-pattern UNDO -
		commit records (key, before, after), undo and redo replay
		through the same commit so propagation is never special-
		cased. Aggregate law, stated and assaulted: empty members
		count for nothing; SUM and COUNT of nothing are 0; AVG, MIN
		and MAX of nothing are #ERR; any erroring member poisons the
		aggregate.
	]"

class
	SW_CELLS_ENGINE

create
	make

feature {NONE} -- Initialization

	make
		do
			create formulas.make (64)
			create numeric.make (64)
			create dependents.make (64)
			create depends_on.make (64)
			create touched.make (16)
			create visiting.make (16)
			create undo_stack.make (32)
			create redo_stack.make (8)
		end

feature -- Access

	Cols: INTEGER = 26

	Rows: INTEGER = 100

	key (a_row, a_col: INTEGER): INTEGER
		require
			row_ok: a_row >= 0 and a_row <= Rows - 1
			col_ok: a_col >= 1 and a_col <= Cols
		do
			Result := a_row * Cols + a_col
		end

	key_name (a_key: INTEGER): STRING_32
			-- "B7" for the key of row 7, column 2.
		do
			create Result.make (4)
			Result.append_character ((64 + ((a_key - 1) \\ Cols + 1)).to_character_32)
			Result.append_string_general (((a_key - 1) // Cols).out)
		end

	formula (a_key: INTEGER): STRING_32
			-- The raw text the user committed; empty when none.
		do
			if attached formulas.item (a_key) as f then
				Result := f.twin
			else
				create Result.make_empty
			end
		end

	display (a_key: INTEGER): STRING_32
			-- What the cell shows: a formatted number, the literal
			-- text, or #ERR.
		local
			v: REAL_64
		do
			if numeric.has (a_key) then
				v := numeric.item (a_key)
				if v.is_nan then
					Result := {STRING_32} "#ERR"
				elseif v = v.truncated_to_integer then
					Result := v.truncated_to_integer.out.to_string_32
				else
					Result := v.out.to_string_32
				end
			elseif attached formulas.item (a_key) as f then
				Result := f.twin
			else
				create Result.make_empty
			end
		end

	is_occupied (a_key: INTEGER): BOOLEAN
		do
			Result := formulas.has (a_key)
		end

	used_max_row: INTEGER
			-- The last row holding anything; -1 when the sheet is bare.
		do
			Result := -1
			across
				formulas as f
			loop
				Result := Result.max ((@ f.key - 1) // Cols)
			end
		end

	used_max_col: INTEGER
			-- The last column holding anything; 0 when bare.
		do
			across
				formulas as f
			loop
				Result := Result.max ((@ f.key - 1) \\ Cols + 1)
			end
		end

	touched: ARRAYED_LIST [INTEGER]
			-- Every key whose display may have changed in the last
			-- `commit' - the host repaints exactly these.

	can_undo: BOOLEAN
		do
			Result := not undo_stack.is_empty
		end

	can_redo: BOOLEAN
		do
			Result := not redo_stack.is_empty
		end

feature -- Commands

	commit (a_key: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Set the cell's formula, evaluate, propagate - and
			-- record for undo (unless this IS an undo replaying).
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			if not replaying then
				undo_stack.extend ([a_key, formula (a_key), s.twin])
				redo_stack.wipe_out
			end
			touched.wipe_out
			unwire (a_key)
			if s.is_empty then
				formulas.remove (a_key)
				numeric.remove (a_key)
			else
				formulas.force (s, a_key)
			end
			reevaluate (a_key)
		ensure
			self_touched: touched.has (a_key)
		end

	undo
			-- Replay the last edit backwards, through commit itself.
		require
			something: can_undo
		local
			step: TUPLE [cell: INTEGER; before, after: STRING_32]
		do
			step := undo_stack.last
			undo_stack.finish
			undo_stack.remove
			replaying := True
			commit (step.cell, step.before)
			replaying := False
			redo_stack.extend (step)
		ensure
			redoable: can_redo
		end

	redo
		require
			something: can_redo
		local
			step: TUPLE [cell: INTEGER; before, after: STRING_32]
		do
			step := redo_stack.last
			redo_stack.finish
			redo_stack.remove
			replaying := True
			commit (step.cell, step.after)
			replaying := False
			undo_stack.extend (step)
		ensure
			undoable: can_undo
		end

feature -- Blocks (TSV and CSV)

	block_tsv (a_row0, a_col0, a_row1, a_col1: INTEGER): STRING_32
			-- The rectangle's DISPLAY values, tab-joined, newline
			-- rowed - what Excel pastes.
		require
			ordered: a_row0 <= a_row1 and a_col0 <= a_col1
			inside: a_row0 >= 0 and a_row1 <= Rows - 1 and a_col0 >= 1 and a_col1 <= Cols
		local
			r, c: INTEGER
		do
			create Result.make (64)
			from
				r := a_row0
			until
				r > a_row1
			loop
				from
					c := a_col0
				until
					c > a_col1
				loop
					Result.append (display (key (r, c)))
					if c < a_col1 then
						Result.append_character ('%T')
					end
					c := c + 1
				end
				if r < a_row1 then
					Result.append_character ('%N')
				end
				r := r + 1
			end
		end

	paste_tsv (a_row0, a_col0: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Commit a tab/newline block starting at (row0, col0);
			-- cells beyond the sheet's edge are dropped, not wrapped.
		require
			inside: a_row0 >= 0 and a_row0 <= Rows - 1 and a_col0 >= 1 and a_col0 <= Cols
		local
			s: STRING_32
			lines: LIST [STRING_32]
			cells: LIST [STRING_32]
			r, c: INTEGER
		do
			create s.make_from_string_general (a_text)
			s.prune_all ('%R')
			lines := s.split ('%N')
			r := a_row0
			across
				lines as ln
			loop
				if r <= Rows - 1 then
					cells := ln.split ('%T')
					c := a_col0
					across
						cells as cl
					loop
						if c <= Cols then
							commit (key (r, c), cl)
						end
						c := c + 1
					end
				end
				r := r + 1
			end
		end

	to_csv: STRING_32
			-- The used extent as CSV; fields holding commas, quotes
			-- or newlines are quote-wrapped with doubled quotes.
		local
			r, c: INTEGER
			cell_text: STRING_32
		do
			create Result.make (128)
			from
				r := 0
			until
				r > used_max_row
			loop
				from
					c := 1
				until
					c > used_max_col
				loop
					cell_text := formula (key (r, c))
					if cell_text.has (',') or cell_text.has ('"') or cell_text.has ('%N') then
						Result.append_character ('"')
						across
							cell_text as ch
						loop
							if ch = '"' then
								Result.append ({STRING_32} "%"%"")
							else
								Result.append_character (ch)
							end
						end
						Result.append_character ('"')
					else
						Result.append (cell_text)
					end
					if c < used_max_col then
						Result.append_character (',')
					end
					c := c + 1
				end
				Result.append_character ('%N')
				r := r + 1
			end
		end

	from_csv (a_text: READABLE_STRING_GENERAL)
			-- Load CSV starting at A0, quote-aware; the sheet is NOT
			-- cleared first (compose deliberately, or clear yourself).
		local
			s, field: STRING_32
			i, r, c: INTEGER
			in_quotes: BOOLEAN
			ch: CHARACTER_32
		do
			create s.make_from_string_general (a_text)
			s.prune_all ('%R')
			create field.make (16)
			r := 0
			c := 1
			from
				i := 1
			until
				i > s.count or r > Rows - 1
			loop
				ch := s.item (i)
				if in_quotes then
					if ch = '"' then
						if i < s.count and then s.item (i + 1) = '"' then
							field.append_character ('"')
							i := i + 1
						else
							in_quotes := False
						end
					else
						field.append_character (ch)
					end
				elseif ch = '"' then
					in_quotes := True
				elseif ch = ',' then
					if c <= Cols and then not field.is_empty then
						commit (key (r, c), field)
					end
					field.wipe_out
					c := c + 1
				elseif ch = '%N' then
					if c <= Cols and then not field.is_empty then
						commit (key (r, c), field)
					end
					field.wipe_out
					r := r + 1
					c := 1
				else
					field.append_character (ch)
				end
				i := i + 1
			end
			if not field.is_empty and then r <= Rows - 1 and then c <= Cols then
				commit (key (r, c), field)
			end
		end

feature {NONE} -- Undo machinery

	undo_stack, redo_stack: ARRAYED_LIST [TUPLE [cell: INTEGER; before, after: STRING_32]]

	replaying: BOOLEAN

feature {NONE} -- Engine

	formulas: HASH_TABLE [STRING_32, INTEGER]

	numeric: HASH_TABLE [REAL_64, INTEGER]

	dependents: HASH_TABLE [ARRAYED_LIST [INTEGER], INTEGER]
			-- key -> cells whose formulas reference it.

	depends_on: HASH_TABLE [ARRAYED_LIST [INTEGER], INTEGER]
			-- key -> cells its own formula references.

	visiting: ARRAYED_LIST [INTEGER]
			-- Cycle guard during evaluation.

	has_cycle_from (a_key: INTEGER): BOOLEAN
			-- Can `a_key' reach itself along depends_on edges?
		local
			stack, seen: ARRAYED_LIST [INTEGER]
			cur: INTEGER
		do
			create stack.make (8)
			create seen.make (8)
			if attached depends_on.item (a_key) as r then
				across
					r as z
				loop
					stack.extend (z)
				end
			end
			from
			until
				stack.is_empty or Result
			loop
				cur := stack.last
				stack.finish
				stack.remove
				if cur = a_key then
					Result := True
				elseif not seen.has (cur) then
					seen.extend (cur)
					if attached depends_on.item (cur) as r2 then
						across
							r2 as z2
						loop
							stack.extend (z2)
						end
					end
				end
			end
		end

	unwire (a_key: INTEGER)
		do
			if attached depends_on.item (a_key) as refs then
				across
					refs as r
				loop
					if attached dependents.item (r) as ds then
						ds.prune_all (a_key)
					end
				end
				depends_on.remove (a_key)
			end
		end

	reevaluate (a_key: INTEGER)
		local
			old_has: BOOLEAN
			old_v, new_v: REAL_64
			changed: BOOLEAN
		do
			old_has := numeric.has (a_key)
			if old_has then
				old_v := numeric.item (a_key)
			end
			evaluate_cell (a_key)
			if has_cycle_from (a_key) then
				numeric.force ({REAL_64}.nan, a_key)
			end
			if not touched.has (a_key) then
				touched.extend (a_key)
			end
			changed := numeric.has (a_key) /= old_has
			if not changed and then numeric.has (a_key) then
				new_v := numeric.item (a_key)
				changed := new_v /= old_v and not (new_v.is_nan and old_v.is_nan)
			end
			if changed or not old_has then
				if attached dependents.item (a_key) as ds then
					across
						ds.twin as d
					loop
						reevaluate (d)
					end
				end
			end
		end

	evaluate_cell (a_key: INTEGER)
		local
			f: detachable STRING_32
			v: REAL_64
		do
			f := formulas.item (a_key)
			if f = Void then
				numeric.remove (a_key)
			elseif f.count >= 1 and then f.item (1) = '=' then
				if visiting.has (a_key) then
					numeric.force ({REAL_64}.nan, a_key)
				else
					visiting.extend (a_key)
					v := parse_expression (f, a_key)
					visiting.finish
					visiting.remove
					numeric.force (v, a_key)
				end
			elseif f.is_double then
				numeric.force (f.to_double, a_key)
			else
				numeric.remove (a_key)
			end
		end

feature {NONE} -- Parser (recursive descent over '=expr')

	src: detachable STRING_32

	pos: INTEGER

	home_key: INTEGER

	parse_expression (a_formula: STRING_32; a_for: INTEGER): REAL_64
		do
			src := a_formula
			pos := 2
			home_key := a_for
			Result := expr
			skip_blanks
			if attached src as s and then pos <= s.count then
				Result := {REAL_64}.nan
			end
		end

	expr: REAL_64
		local
			op: CHARACTER_32
		do
			Result := term
			from
				skip_blanks
			until
				not (peek = '+' or peek = '-')
			loop
				op := peek
				pos := pos + 1
				if op = '+' then
					Result := Result + term
				else
					Result := Result - term
				end
				skip_blanks
			end
		end

	term: REAL_64
		local
			op: CHARACTER_32
			d: REAL_64
		do
			Result := factor
			from
				skip_blanks
			until
				not (peek = '*' or peek = '/')
			loop
				op := peek
				pos := pos + 1
				d := factor
				if op = '*' then
					Result := Result * d
				else
					if d = 0.0 then
						Result := {REAL_64}.nan
					else
						Result := Result / d
					end
				end
				skip_blanks
			end
		end

	factor: REAL_64
		local
			start: INTEGER
			c: CHARACTER_32
			letters: STRING_32
		do
			skip_blanks
			c := peek
			if c = '(' then
				pos := pos + 1
				Result := expr
				skip_blanks
				if peek = ')' then
					pos := pos + 1
				else
					Result := {REAL_64}.nan
				end
			elseif c >= 'A' and c <= 'Z' then
				start := pos
				from
				until
					not (peek >= 'A' and peek <= 'Z')
				loop
					pos := pos + 1
				end
				if attached src as s then
					letters := s.substring (start, pos - 1)
				else
					create letters.make_empty
				end
				if letters.count = 1 and then peek >= '0' and then peek <= '9' then
					Result := cell_ref_value (letters.item (1))
				elseif peek = '(' then
					Result := aggregate (letters)
				else
					Result := {REAL_64}.nan
				end
			elseif (c >= '0' and c <= '9') or c = '.' then
				start := pos
				from
				until
					not ((peek >= '0' and peek <= '9') or peek = '.')
				loop
					pos := pos + 1
				end
				if attached src as s and then s.substring (start, pos - 1).is_double then
					Result := s.substring (start, pos - 1).to_double
				else
					Result := {REAL_64}.nan
				end
			elseif c = '-' then
				pos := pos + 1
				Result := -factor
			else
				Result := {REAL_64}.nan
				pos := pos + 1
			end
		end

	cell_ref_value (a_col_letter: CHARACTER_32): REAL_64
			-- Finish parsing the digits of a single-cell reference
			-- whose column letter is already consumed.
		local
			start, ref_row, ref_col: INTEGER
		do
			ref_col := a_col_letter.natural_32_code.to_integer_32 - 64
			start := pos
			from
			until
				not (peek >= '0' and peek <= '9')
			loop
				pos := pos + 1
			end
			if pos > start and then attached src as s then
				ref_row := s.substring (start, pos - 1).to_integer
				if ref_row >= 0 and ref_row <= Rows - 1 then
					Result := reference_value (ref_row * Cols + ref_col)
				else
					Result := {REAL_64}.nan
				end
			else
				Result := {REAL_64}.nan
			end
		end

	read_ref_key: INTEGER
			-- Parse LETTER+digits at the cursor into a key; -1 on
			-- anything else.
		local
			c: CHARACTER_32
			start, ref_row: INTEGER
		do
			Result := -1
			skip_blanks
			c := peek
			if c >= 'A' and c <= 'Z' then
				pos := pos + 1
				start := pos
				from
				until
					not (peek >= '0' and peek <= '9')
				loop
					pos := pos + 1
				end
				if pos > start and then attached src as s then
					ref_row := s.substring (start, pos - 1).to_integer
					if ref_row >= 0 and ref_row <= Rows - 1 then
						Result := ref_row * Cols
							+ (c.natural_32_code.to_integer_32 - 64)
					end
				end
			end
		end

	aggregate (a_name: STRING_32): REAL_64
			-- FUNC(REF:REF) for SUM / AVG / MIN / MAX / COUNT.
			-- The law: empty members count for nothing; SUM and
			-- COUNT of nothing are 0; AVG, MIN, MAX of nothing are
			-- error; any erroring member poisons the whole.
		local
			k0, k1, r0, c0, r1, c1, r, c, n: INTEGER
			v, total, best_min, best_max: REAL_64
			poisoned: BOOLEAN
		do
			pos := pos + 1
			k0 := read_ref_key
			skip_blanks
			if peek = ':' then
				pos := pos + 1
			else
				k0 := -1
			end
			k1 := read_ref_key
			skip_blanks
			if peek = ')' then
				pos := pos + 1
			else
				k0 := -1
			end
			if k0 < 0 or k1 < 0 then
				Result := {REAL_64}.nan
			else
				r0 := ((k0 - 1) // Cols).min ((k1 - 1) // Cols)
				r1 := ((k0 - 1) // Cols).max ((k1 - 1) // Cols)
				c0 := ((k0 - 1) \\ Cols + 1).min ((k1 - 1) \\ Cols + 1)
				c1 := ((k0 - 1) \\ Cols + 1).max ((k1 - 1) \\ Cols + 1)
				from
					r := r0
				until
					r > r1
				loop
					from
						c := c0
					until
						c > c1
					loop
						v := reference_value (key (r, c))
						if is_occupied (key (r, c)) then
							if v.is_nan then
								poisoned := True
							else
								if n = 0 then
									best_min := v
									best_max := v
								else
									best_min := best_min.min (v)
									best_max := best_max.max (v)
								end
								n := n + 1
								total := total + v
							end
						end
						c := c + 1
					end
					r := r + 1
				end
				if poisoned then
					Result := {REAL_64}.nan
				elseif a_name.same_string_general ("SUM") then
					Result := total
				elseif a_name.same_string_general ("COUNT") then
					Result := n.to_double
				elseif a_name.same_string_general ("AVG") then
					if n > 0 then
						Result := total / n
					else
						Result := {REAL_64}.nan
					end
				elseif a_name.same_string_general ("MIN") then
					if n > 0 then
						Result := best_min
					else
						Result := {REAL_64}.nan
					end
				elseif a_name.same_string_general ("MAX") then
					if n > 0 then
						Result := best_max
					else
						Result := {REAL_64}.nan
					end
				else
					Result := {REAL_64}.nan
				end
			end
		end

	reference_value (a_ref: INTEGER): REAL_64
			-- The referenced cell's value; wires the dependency both
			-- ways, evaluates lazily, and turns cycles into error.
		local
			ds, refs: ARRAYED_LIST [INTEGER]
		do
			if attached dependents.item (a_ref) as d0 then
				ds := d0
			else
				create ds.make (4)
				dependents.force (ds, a_ref)
			end
			if not ds.has (home_key) then
				ds.extend (home_key)
			end
			if attached depends_on.item (home_key) as r0 then
				refs := r0
			else
				create refs.make (4)
				depends_on.force (refs, home_key)
			end
			if not refs.has (a_ref) then
				refs.extend (a_ref)
			end
			if visiting.has (a_ref) then
				Result := {REAL_64}.nan
			elseif numeric.has (a_ref) then
				Result := numeric.item (a_ref)
			elseif formulas.has (a_ref) then
				Result := evaluate_reference (a_ref)
			else
				Result := 0.0
			end
		end

	evaluate_reference (a_ref: INTEGER): REAL_64
		local
			keep_src: detachable STRING_32
			keep_pos, keep_home: INTEGER
		do
			keep_src := src
			keep_pos := pos
			keep_home := home_key
			evaluate_cell (a_ref)
			src := keep_src
			pos := keep_pos
			home_key := keep_home
			if numeric.has (a_ref) then
				Result := numeric.item (a_ref)
			end
		end

	peek: CHARACTER_32
		do
			if attached src as s and then pos <= s.count then
				Result := s.item (pos)
			else
				Result := '%U'
			end
		end

	skip_blanks
		do
			from
			until
				peek /= ' '
			loop
				pos := pos + 1
			end
		end

invariant
	tables_attached: formulas /= Void and numeric /= Void
	stacks_attached: undo_stack /= Void and redo_stack /= Void

end
