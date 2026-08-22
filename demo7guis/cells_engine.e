note
	description: "[
		The Cells domain: formulas keyed by cell, values, a
		dependency graph, and change propagation that reevaluates
		exactly the dependents of what changed - transitively, until
		quiet. Formula language: numbers, A0-Z99 references, + - * /
		and parentheses, led by '='. Cycles evaluate to error.
	]"

class
	CELLS_ENGINE

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
		end

feature -- Access

	Cols: INTEGER = 26

	key (a_row, a_col: INTEGER): INTEGER
		require
			row_ok: a_row >= 0 and a_row <= 99
			col_ok: a_col >= 1 and a_col <= Cols
		do
			Result := a_row * Cols + a_col
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

	touched: ARRAYED_LIST [INTEGER]
			-- Every key whose display may have changed in the last
			-- `commit' - the host repaints exactly these.

feature -- Commands

	commit (a_key: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Set the cell's formula, evaluate it, and propagate to
			-- dependents until no value changes.
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
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
			-- Remove a_key from its old references' dependent lists.
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
			-- Evaluate a_key, then its dependents, transitively.
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
					-- the lazy value cache can hide a cycle from the
					-- recursive guard: a member reads its partner's
					-- CACHED value and never recurses. Detect cycles
					-- structurally instead - and poison with NaN, which
					-- propagation spreads to every member as #ERR.
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
			ref_col, ref_row: INTEGER
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
				ref_col := c.natural_32_code.to_integer_32 - 64
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
					if ref_row >= 0 and ref_row <= 99 then
						Result := reference_value (ref_row * Cols + ref_col)
					else
						Result := {REAL_64}.nan
					end
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
					-- referenced but not yet evaluated: evaluate now,
					-- preserving this parse's cursor
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

end
