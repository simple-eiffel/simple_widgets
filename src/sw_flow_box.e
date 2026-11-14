note
	description: "[
		Children that wrap to new lines as the width runs out: tag clouds, chips, card grids
		(GtkFlowBox's job; simple_gui's GUI_FLOW_BOX on Windows). A wrapping SW_ROW with its own
		gap between lines, a limit on children per line, and an option to make every child as
		wide as the widest. Lines start at the leading edge, mirrored under right-to-left.
	]"

class
	SW_FLOW_BOX

inherit
	SW_ROW
		redefine
			make, wrap_starts, wrapped_widths, line_gap
		end

create
	make

feature {NONE} -- Initialization

	make
			-- An empty flow box, wrapping.
		do
			Precursor
			set_wrapping (True)
		ensure then
			wrapping: is_wrapping
			no_limit: maximum_per_line = 0
			natural_widths: not is_homogeneous
		end

feature -- Access

	line_spacing: REAL_64
			-- The space between lines, once set (`set_gaps'); until then the gap between siblings.

	line_spacing_is_explicit: BOOLEAN
			-- Has `set_gaps' fixed the space between lines?

	maximum_per_line: INTEGER
			-- The most children on one line (0: as many as fit).

	is_homogeneous: BOOLEAN
			-- Is every child as wide as the widest?

feature -- Element change

	set_gaps (a_line_gap, a_sibling_gap: REAL_64)
			-- `a_line_gap' between lines and `a_sibling_gap' between children on a line.
		require
			non_negative: a_line_gap >= 0.0 and a_sibling_gap >= 0.0
		do
			line_spacing := a_line_gap
			line_spacing_is_explicit := True
			set_gap (a_sibling_gap)
		ensure
			line_set: line_spacing_is_explicit and line_spacing = a_line_gap
			sibling_set: gap_is_explicit and gap = a_sibling_gap
		end

	set_maximum_per_line (a_count: INTEGER)
			-- Put at most `a_count' children on a line (0: as many as fit).
		require
			non_negative: a_count >= 0
		do
			maximum_per_line := a_count
		ensure
			set: maximum_per_line = a_count
		end

	set_homogeneous (a_on: BOOLEAN)
			-- Make every child as wide as the widest (`a_on'), or each its own width.
		do
			is_homogeneous := a_on
		ensure
			set: is_homogeneous = a_on
		end

feature -- Layout

	wrap_starts (a_widths: ARRAYED_LIST [REAL_64]; a_gap, a_avail: REAL_64): ARRAYED_LIST [INTEGER]
			-- <Precursor> A line holding more than `maximum_per_line' is cut after each
			-- `maximum_per_line' children.
		local
			l_greedy: ARRAYED_LIST [INTEGER]
			li, l_first, l_end: INTEGER
		do
			l_greedy := Precursor (a_widths, a_gap, a_avail)
			if maximum_per_line = 0 then
				Result := l_greedy
			else
				create Result.make (l_greedy.count)
				from li := 1 until li > l_greedy.count loop
					if li < l_greedy.count then
						l_end := l_greedy.i_th (li + 1) - 1
					else
						l_end := a_widths.count
					end
					from l_first := l_greedy.i_th (li) until l_first > l_end loop
						Result.extend (l_first)
						l_first := l_first + maximum_per_line
					end
					li := li + 1
				end
			end
		ensure then
			limited: maximum_per_line > 0 implies across 1 |..| Result.count as i all
				(if i < Result.count then Result.i_th (i + 1) else a_widths.count + 1 end) - Result.i_th (i) <= maximum_per_line end
		end

	wrapped_widths (a_p: SW_PAINTER; a_kids: ARRAYED_LIST [SW_WIDGET]): ARRAYED_LIST [REAL_64]
			-- <Precursor> The widest one's for every child while `is_homogeneous'.
		local
			l_widest: REAL_64
			i: INTEGER
		do
			Result := Precursor (a_p, a_kids)
			if is_homogeneous then
				across Result as ic loop
					l_widest := l_widest.max (ic)
				end
				from i := 1 until i > Result.count loop
					Result.put_i_th (l_widest, i)
					i := i + 1
				end
			end
		ensure then
			equal_when_homogeneous: is_homogeneous implies across Result as ic all ic = Result.first end
		end

	line_gap (a_p: SW_PAINTER): REAL_64
			-- <Precursor> `line_spacing' once set.
		do
			if line_spacing_is_explicit then
				Result := line_spacing
			else
				Result := Precursor (a_p)
			end
		ensure then
			explicit_wins: line_spacing_is_explicit implies Result = line_spacing
		end

invariant
	line_spacing_non_negative: line_spacing >= 0.0
	limit_non_negative: maximum_per_line >= 0

end
