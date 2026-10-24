note
	description: "[
		Where the items of a scrolling column of DIFFERENT heights stand:
		each item's measured height, the revision that height was
		measured for, and its top - the sum of the heights and gaps above
		it. SW_PARAGRAPH_LIST's paragraphs and SW_DOCUMENT_VIEW's blocks
		both stack on one of these.

		    reset_if_changed (n, key)  drop every measurement when the
		                               item count or the layout key (the
		                               width, the text size, the engine)
		                               changes
		    needs_measure (i, rev)     was item i measured for `rev'?
		    put_height (i, h, rev)     record a measurement
		    restack (gap)              recompute the tops
		    item_at (y)                which item a content y is in
		    first_visible / last_visible / scroll_into_view

		The lookups are BINARY SEARCHES on the tops (they ascend, every
		height being positive), so a document of ten thousand blocks
		finds the one under the pointer in fourteen steps.
	]"
	author: "Larry Rix"

class
	SW_BLOCK_STACK

create
	make

feature {NONE} -- Initialization

	make
			-- No items.
		do
			create heights.make (16)
			create tops.make (16)
			create revisions.make (16)
			create key.make_empty
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
			-- Items held.
		do
			Result := heights.count
		end

	key: STRING_8
			-- The layout key the measurements are for.

	height (a_i: INTEGER): REAL_64
			-- Item `a_i''s measured height (1.0 before its first measure).
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := heights.i_th (a_i)
		ensure
			positive: Result > 0.0
		end

	top (a_i: INTEGER): REAL_64
			-- Item `a_i''s top in content coordinates, as of `restack'.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := tops.i_th (a_i)
		ensure
			non_negative: Result >= 0.0
		end

	content_height: REAL_64
			-- Every item stacked; 0 when empty.
		do
			if count > 0 then
				Result := tops.last + heights.last
			end
		ensure
			non_negative: Result >= 0.0
		end

	needs_measure (a_i, a_revision: INTEGER): BOOLEAN
			-- Was item `a_i' last measured for another revision than
			-- `a_revision'?
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := revisions.i_th (a_i) /= a_revision
		end

feature -- Lookup

	item_at (a_y: REAL_64): INTEGER
			-- The item whose box holds content y `a_y'; 0 above the first,
			-- below the last or in a gap between two.
		local
			i: INTEGER
		do
			i := last_starting_at_or_before (a_y)
			if i > 0 and then a_y < tops.i_th (i) + heights.i_th (i) then
				Result := i
			end
		ensure
			in_range: Result >= 0 and Result <= count
			inside: Result > 0 implies (a_y >= top (Result) and a_y < top (Result) + height (Result))
		end

	first_visible (a_scroll: REAL_64): INTEGER
			-- The first item reaching below content y `a_scroll'; 0 for none.
		local
			lo, hi, mid: INTEGER
		do
			from
				lo := 1
				hi := count
			until
				lo > hi
			loop
				mid := (lo + hi) // 2
				if tops.i_th (mid) + heights.i_th (mid) > a_scroll then
					Result := mid
					hi := mid - 1
				else
					lo := mid + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

	last_visible (a_scroll, a_viewport: REAL_64): INTEGER
			-- The last item starting above content y `a_scroll' +
			-- `a_viewport'; 0 for none.
		do
			Result := last_starting_before (a_scroll + a_viewport)
		ensure
			in_range: Result >= 0 and Result <= count
		end

	scroll_into_view (a_i: INTEGER; a_scroll, a_viewport: REAL_64): REAL_64
			-- The scroll position nearest `a_scroll' that shows item `a_i'
			-- whole (its top, when it is taller than the viewport).
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := a_scroll
			if tops.i_th (a_i) + heights.i_th (a_i) > a_scroll + a_viewport then
				Result := tops.i_th (a_i) + heights.i_th (a_i) - a_viewport
			end
			if tops.i_th (a_i) < Result then
				Result := tops.i_th (a_i)
			end
			Result := Result.max (0.0)
		ensure
			non_negative: Result >= 0.0
			top_shown: Result <= top (a_i)
		end

feature -- Element change

	reset_if_changed (a_count: INTEGER; a_key: READABLE_STRING_8): BOOLEAN
			-- Hold `a_count' items laid out by `a_key'. When either changed,
			-- every measurement is dropped (each item 1.0 high, measured
			-- for no revision) and the answer is True.
		require
			count_non_negative: a_count >= 0
		local
			i: INTEGER
		do
			if a_count /= count or else not key.same_string (a_key) then
				heights.wipe_out
				tops.wipe_out
				revisions.wipe_out
				from
					i := 1
				until
					i > a_count
				loop
					heights.extend (1.0)
					tops.extend (0.0)
					revisions.extend (Unmeasured)
					i := i + 1
				end
				create key.make_from_string (a_key)
				Result := True
			end
		ensure
			count_set: count = a_count
			key_set: key.same_string (a_key)
		end

	invalidate
			-- Every measurement goes at the next `reset_if_changed', whatever
			-- its count and key (the items were reordered or replaced).
		do
			create key.make_from_string ("%U")
		ensure
			stale: key.same_string ("%U")
		end

	put_height (a_i: INTEGER; a_height: REAL_64; a_revision: INTEGER)
			-- Item `a_i' measured `a_height' high for `a_revision'. The tops
			-- follow at the next `restack'.
		require
			in_range: a_i >= 1 and a_i <= count
			positive: a_height > 0.0
			real_revision: a_revision >= 0
		do
			heights.put_i_th (a_height, a_i)
			revisions.put_i_th (a_revision, a_i)
		ensure
			height_set: height (a_i) = a_height
			measured: not needs_measure (a_i, a_revision)
		end

	forget (a_i: INTEGER)
			-- Item `a_i' measures again on the next pass.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			revisions.put_i_th (Unmeasured, a_i)
		end

	restack (a_gap: REAL_64)
			-- Every top from the heights above it, `a_gap' between items.
		require
			gap_non_negative: a_gap >= 0.0
		local
			i: INTEGER
			t: REAL_64
		do
			from
				i := 1
			until
				i > count
			loop
				tops.put_i_th (t, i)
				t := t + heights.i_th (i) + a_gap
				i := i + 1
			end
		ensure
			first_at_zero: count > 0 implies top (1) = 0.0
		end

feature {NONE} -- Implementation

	heights, tops: ARRAYED_LIST [REAL_64]
	revisions: ARRAYED_LIST [INTEGER]

	Unmeasured: INTEGER = -1
			-- The revision of an item never measured (real ones are not
			-- negative).

	last_starting_at_or_before (a_y: REAL_64): INTEGER
			-- The last item whose top is at or above `a_y'; 0 for none.
		local
			lo, hi, mid: INTEGER
		do
			from
				lo := 1
				hi := count
			until
				lo > hi
			loop
				mid := (lo + hi) // 2
				if tops.i_th (mid) <= a_y then
					Result := mid
					lo := mid + 1
				else
					hi := mid - 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

	last_starting_before (a_y: REAL_64): INTEGER
			-- The last item whose top is strictly above `a_y'; 0 for none.
		local
			lo, hi, mid: INTEGER
		do
			from
				lo := 1
				hi := count
			until
				lo > hi
			loop
				mid := (lo + hi) // 2
				if tops.i_th (mid) < a_y then
					Result := mid
					lo := mid + 1
				else
					hi := mid - 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

invariant
	parallel: tops.count = heights.count and revisions.count = heights.count

end
