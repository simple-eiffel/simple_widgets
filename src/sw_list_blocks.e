note
	description: "[
		Block edits on an ARRAYED_LIST: a run of items given way to
		another (`splice'), and the items last added moved into the
		place of a run further up (`move_end_in'). Each moves the items
		after the place once, as one block, through the list's `area'.
		ARRAYED_LIST itself takes out one item at a time, and moves
		every item after it each time: a hundred items taken out of the
		middle of 400,000 are a hundred such moves.

		Stateless: one object serves every list of its item type. The
		list's cursor is left before the first item.

		RIGHT TOOL. For a list edited at its end, `extend' and
		`remove_tail' of the list itself. This class is for parallel
		lists edited in their middle on every keystroke
		(SW_TEXT_GEOMETRY's slots, lines and layouts).
	]"
	contract_cost: "[
		2026-11-10. The postconditions state the count only. What the
		items are after an edit is checked by a test against a model
		built one item at a time (SW_BREAKS_AND_TABS_ASSAULT), not by a
		postcondition: that would copy the list on every call, and the
		lists here hold a slot per character of a text.
	]"
	author: "Larry Rix"

class
	SW_LIST_BLOCKS [G]

feature -- Basic operations

	splice (a_list: ARRAYED_LIST [G]; a_after, a_removed, a_inserted: INTEGER; a_fill: G)
			-- In `a_list', put `a_inserted' items equal to `a_fill' in the
			-- place of the `a_removed' items after position `a_after'.
			-- Room is taken with some to spare, so a run of small
			-- insertions does not move the list each time.
		require
			after_valid: a_after >= 0
			removed_valid: a_removed >= 0 and a_after + a_removed <= a_list.count
			inserted_non_negative: a_inserted >= 0
		local
			l_area: SPECIAL [G]
			l_old, l_new, l_tail: INTEGER
		do
			a_list.go_i_th (0)
			l_old := a_list.count
			l_new := l_old - a_removed + a_inserted
			l_tail := l_old - a_after - a_removed
			if l_new > a_list.capacity then
				a_list.grow (l_new + l_new // 4 + 16)
			end
			l_area := a_list.area
			if l_new > l_old then
					-- raise the count, so the items after the place can move up
				l_area.fill_with (a_fill, l_old, l_new - 1)
			end
			l_area.move_data (a_after + a_removed, a_after + a_inserted, l_tail)
			if l_new < l_old then
				l_area.keep_head (l_new)
			end
			if a_inserted > 0 then
				l_area.fill_with (a_fill, a_after, a_after + a_inserted - 1)
			end
		ensure
			count_follows: a_list.count = old a_list.count - a_removed + a_inserted
		end

	move_end_in (a_list: ARRAYED_LIST [G]; a_after, a_removed, a_count: INTEGER)
			-- In `a_list', put its last `a_count' items in the place of the
			-- `a_removed' items after position `a_after'. (Items are added
			-- with `extend', as the code that makes them does anyway, and
			-- then moved to where they belong.)
		require
			after_valid: a_after >= 0
			removed_non_negative: a_removed >= 0
			count_non_negative: a_count >= 0
			apart: a_after + a_removed + a_count <= a_list.count
		local
			l_area, l_end: SPECIAL [G]
			l_old, l_between: INTEGER
		do
			a_list.go_i_th (0)
			l_old := a_list.count
			l_between := l_old - a_count - a_after - a_removed
			l_area := a_list.area
			create l_end.make_empty (a_count)
			l_end.copy_data (l_area, l_old - a_count, 0, a_count)
			l_area.move_data (a_after + a_removed, a_after + a_count, l_between)
			l_area.copy_data (l_end, 0, a_after, a_count)
			l_area.keep_head (l_old - a_removed)
		ensure
			count_follows: a_list.count = old a_list.count - a_removed
		end

end
