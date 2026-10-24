note
	description: "[
		A read-only text surface's selection (0.20.0): an anchor and a
		caret, each an (item, offset) pair, so a selection may run across
		items - the paragraphs, blocks or cells a widget numbers 1 ..
		`item_count' in reading order. The selected text, Copy through
		SW_CLIPBOARD, Select All, and the control characters a reader
		expects (Ctrl+C copies, Ctrl+A selects all, Escape clears).

		A descendant numbers its items (`item_count', `is_valid_item')
		and hands their text over (`text_of'); `item_separator' says what
		joins one item to the next in a copy (a line feed; a table cell
		joins its row neighbour with a tab). It drives the selection from
		its own pointer handlers with `begin_selection', `extend_selection'
		and `end_selection', paints `selection_in' under each item, and
		passes WM_CHAR codes to `selection_char'. Nothing of SW_WIDGET is
		redefined here. `is_valid_item' and `text_of' are named and typed
		as in SW_TEXT_POINTING, so a widget inheriting both joins them.
	]"
	author: "Larry Rix"

deferred class
	SW_TEXT_SELECTION

inherit
	SW_WIDGET

feature -- Items

	item_count: INTEGER
			-- Items, numbered in reading order.
		deferred
		ensure
			non_negative: Result >= 0
		end

	is_valid_item (a_item: INTEGER): BOOLEAN
			-- Is `a_item' one of the widget's text items?
		deferred
		end

	text_of (a_item: INTEGER): READABLE_STRING_32
			-- Item `a_item''s characters.
		require
			valid_item: is_valid_item (a_item)
		deferred
		end

	item_separator (a_item: INTEGER): STRING_32
			-- What joins item `a_item' to the next in `selected_text': a
			-- line feed.
		require
			valid_item: is_valid_item (a_item)
		do
			Result := {STRING_32} "%N"
		end

feature -- Selection

	anchor_item: INTEGER
	anchor_offset: INTEGER
			-- Where the selection began: before character `anchor_offset'
			-- + 1 of item `anchor_item' (0: no selection).

	caret_item: INTEGER
	caret_offset: INTEGER
			-- Where it ends now.

	is_selecting: BOOLEAN
			-- Is the pointer dragging a selection out?

	has_selection: BOOLEAN
			-- Is anything selected?
		do
			Result := anchor_item > 0 and then caret_item > 0
				and then (anchor_item /= caret_item or anchor_offset /= caret_offset)
		end

	selection_in (a_item: INTEGER): TUPLE [lo, hi: INTEGER]
			-- The selected caret offsets inside item `a_item': characters
			-- `lo' + 1 .. `hi'; `lo' = `hi' when none of it is selected.
		require
			valid_item: is_valid_item (a_item)
		local
			l_lo_item, l_lo_off, l_hi_item, l_hi_off, n: INTEGER
		do
			n := text_of (a_item).count
			Result := [0, 0]
			if has_selection then
				if before (anchor_item, anchor_offset, caret_item, caret_offset) then
					l_lo_item := anchor_item
					l_lo_off := anchor_offset
					l_hi_item := caret_item
					l_hi_off := caret_offset
				else
					l_lo_item := caret_item
					l_lo_off := caret_offset
					l_hi_item := anchor_item
					l_hi_off := anchor_offset
				end
				if a_item >= l_lo_item and a_item <= l_hi_item then
					Result := [if a_item = l_lo_item then l_lo_off.min (n) else 0 end,
						if a_item = l_hi_item then l_hi_off.min (n) else n end]
				end
			end
		ensure
			ordered: Result.lo >= 0 and Result.lo <= Result.hi
			in_text: Result.hi <= text_of (a_item).count
		end

	selected_text: STRING_32
			-- The selection's text, items joined by `item_separator'.
		local
			k, l_lo_item, l_hi_item: INTEGER
			l_part: TUPLE [lo, hi: INTEGER]
		do
			create Result.make (64)
			if has_selection then
				l_lo_item := anchor_item.min (caret_item)
				l_hi_item := anchor_item.max (caret_item)
				from
					k := l_lo_item
				until
					k > l_hi_item
				loop
					if is_valid_item (k) then
						l_part := selection_in (k)
						Result.append (text_of (k).substring (l_part.lo + 1, l_part.hi))
						if k < l_hi_item then
							Result.append (item_separator (k))
						end
					end
					k := k + 1
				end
			end
		ensure
			empty_without_selection: not has_selection implies Result.is_empty
		end

	select_range (a_from_item, a_from_offset, a_to_item, a_to_offset: INTEGER)
			-- Select from (`a_from_item', `a_from_offset') to
			-- (`a_to_item', `a_to_offset').
		require
			from_valid: is_valid_item (a_from_item) and a_from_offset >= 0
				and a_from_offset <= text_of (a_from_item).count
			to_valid: is_valid_item (a_to_item) and a_to_offset >= 0
				and a_to_offset <= text_of (a_to_item).count
		do
			anchor_item := a_from_item
			anchor_offset := a_from_offset
			caret_item := a_to_item
			caret_offset := a_to_offset
		ensure
			anchored: anchor_item = a_from_item and anchor_offset = a_from_offset
			caret_set: caret_item = a_to_item and caret_offset = a_to_offset
		end

	select_all
			-- Every item, first character to last.
		do
			if item_count > 0 then
				select_range (1, 0, item_count, text_of (item_count).count)
			end
		end

	clear_selection
		do
			anchor_item := 0
			anchor_offset := 0
			caret_item := 0
			caret_offset := 0
			is_selecting := False
		ensure
			cleared: not has_selection and anchor_item = 0 and caret_item = 0
		end

	copy_selection
			-- The selection onto the system clipboard; nothing when empty.
		local
			l_clip: SW_CLIPBOARD
		do
			if has_selection then
				create l_clip
				l_clip.set_text (selected_text)
			end
		end

feature {NONE} -- Selection pieces

	begin_selection (a_item, a_offset: INTEGER)
			-- The pointer went down at (`a_item', `a_offset'): an empty
			-- selection there, growing while it drags.
		require
			valid_item: is_valid_item (a_item)
			offset_valid: a_offset >= 0 and a_offset <= text_of (a_item).count
		do
			select_range (a_item, a_offset, a_item, a_offset)
			is_selecting := True
		ensure
			selecting: is_selecting
			empty: not has_selection
		end

	extend_selection (a_item, a_offset: INTEGER)
			-- The drag reached (`a_item', `a_offset').
		require
			valid_item: is_valid_item (a_item)
			offset_valid: a_offset >= 0 and a_offset <= text_of (a_item).count
		do
			caret_item := a_item
			caret_offset := a_offset
		ensure
			caret_set: caret_item = a_item and caret_offset = a_offset
		end

	end_selection
			-- The pointer came up.
		do
			is_selecting := False
		ensure
			not_selecting: not is_selecting
		end

	selection_char (a_code: INTEGER): BOOLEAN
			-- Ctrl+C (3) copies, Ctrl+A (1) selects all, Escape (27) clears;
			-- True when `a_code' was one of them.
		do
			Result := True
			inspect a_code
			when 3 then
				copy_selection
			when 1 then
				select_all
			when 27 then
				clear_selection
			else
				Result := False
			end
		end

	before (a_item, a_offset, b_item, b_offset: INTEGER): BOOLEAN
			-- Does (a_item, a_offset) come at or before (b_item, b_offset)?
		do
			Result := a_item < b_item or else (a_item = b_item and a_offset <= b_offset)
		end

invariant
	whole_anchor: (anchor_item = 0) implies anchor_offset = 0
	whole_caret: (caret_item = 0) implies caret_offset = 0

end
