note
	description: "[
		A widget that holds children in a line - SW_ROW across, SW_COLUMN
		down: the child list, putting and removing a child, and the gap
		between siblings. Scan 35 (2026-10-27): `remove', `put', `add',
		the gap and the child list were copied byte for byte in both.
	]"

deferred class
	SW_BOX_CONTAINER

inherit
	SW_WIDGET
		redefine
			sub_widgets
		end

feature -- Access

	children: ARRAYED_LIST [SW_WIDGET]

	gap: REAL_64
			-- Space between SIBLINGS - EV_BOX.padding. Consulted only
			-- when `gap_is_explicit'; otherwise the theme decides, so a
			-- box laid out at 2x text is separated by 2x space.

	gap_is_explicit: BOOLEAN
			-- Has the application set `gap' itself? Explicit always wins.

feature -- Element change

	add (a_w: SW_WIDGET): like Current
			-- Fluent append.
		do
			put (a_w)
			Result := Current
		ensure
			added: children.last = a_w
			chained: Result = Current
		end

	put (a_w: SW_WIDGET)
		do
			children.extend (a_w)
			a_w.set_parent (Current)
		ensure
			added: children.last = a_w
			adopted: a_w.parent = Current
		end

	remove (a_w: SW_WIDGET)
			-- Take `a_w' out (it may be put elsewhere): a layout that moves a pane between containers
			-- (simple_bible's Simple and Study layouts) puts it back where the arrangement wants it.
		require
			a_child: children.has (a_w)
		do
			children.prune_all (a_w)
			if a_w.parent = Current then
				a_w.set_parent (Void)
			end
		ensure
			gone: not children.has (a_w)
			orphaned: a_w.parent /= Current
		end

	with_gap (a_gap: REAL_64): like Current
		require
			non_negative: a_gap >= 0.0
		do
			set_gap (a_gap)
			Result := Current
		ensure
			explicit: gap_is_explicit and gap = a_gap
		end

	set_gap (a_gap: REAL_64)
			-- Fix the sibling separation; the theme no longer decides.
		require
			non_negative: a_gap >= 0.0
		do
			gap := a_gap
			gap_is_explicit := True
		ensure
			explicit: gap_is_explicit and gap = a_gap
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			Result := children
		end

invariant
	gap_non_negative: gap >= 0.0

end
