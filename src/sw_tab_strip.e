note
	description: "[
		A row of tabs as geometry (GW-15): where each tab stands, which tab
		a point is on, and the two placement policies the library uses.
		SHRINK puts every tab on the strip, in equal shares when their
		natural widths overflow (SW_DOCK_ZONE). SCROLL puts tabs at their
		natural widths from a first one, as many as fit whole, and gives
		the rest no width (SW_TABS, whose overflow menu reaches them).
		The heir measures and draws; this class only knows boxes. One box
		per tab, in tab order, filled by `place_tabs_shrinking' or
		`place_tabs_scrolling' during arrange.
	]"

deferred class
	SW_TAB_STRIP

feature -- Access

	tab_lefts: ARRAYED_LIST [REAL_64]
			-- Each tab's left edge, in tab order.
		attribute
			create Result.make (4)
		end

	tab_widths: ARRAYED_LIST [REAL_64]
			-- Each tab's width; 0 for a tab not on the strip.
		attribute
			create Result.make (4)
		end

	last_placed: INTEGER
			-- The last tab given a width by the latest placement; 0 when
			-- nothing was placed.

	strip_top: REAL_64
			-- The strip's top edge.
		deferred
		end

	strip_height: REAL_64
			-- The strip's height.
		deferred
		end

	tab_index_at (a_px, a_py: REAL_64): INTEGER
			-- The tab whose box holds the point (1-based, tab order); 0 off
			-- the strip, between tabs, or on a tab with no width.
		local
			i: INTEGER
		do
			if a_py >= strip_top and then a_py < strip_top + strip_height then
				from
					i := 1
				until
					i > tab_lefts.count or Result > 0
				loop
					if a_px >= tab_lefts.i_th (i) and then a_px < tab_lefts.i_th (i) + tab_widths.i_th (i) then
						Result := i
					end
					i := i + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= tab_lefts.count
			on_a_box: Result > 0 implies tab_widths.i_th (Result) > 0.0
		end

	is_tab_shown (a_i: INTEGER): BOOLEAN
			-- Does tab `a_i' have a box on the strip?
		require
			placed: a_i >= 1 and a_i <= tab_widths.count
		do
			Result := tab_widths.i_th (a_i) > 0.0
		end

	run_width (a_naturals: ARRAYED_LIST [REAL_64]; a_from, a_to: INTEGER; a_gap: REAL_64): REAL_64
			-- The room tabs `a_from' to `a_to' take side by side at their
			-- natural widths, with `a_gap' between.
		require
			ordered: 1 <= a_from and a_from <= a_to + 1 and a_to <= a_naturals.count
		local
			i: INTEGER
		do
			from
				i := a_from
			until
				i > a_to
			loop
				Result := Result + a_naturals.i_th (i)
				if i > a_from then
					Result := Result + a_gap
				end
				i := i + 1
			end
		end

	first_showing (a_naturals: ARRAYED_LIST [REAL_64]; a_room, a_gap: REAL_64; a_first, a_keep: INTEGER): INTEGER
			-- SCROLL: the tab to start from so that tab `a_keep' stands whole
			-- on the strip, moving from `a_first' as little as possible; and
			-- moving back while the earlier tabs fit too, so closing tabs at
			-- the end never leaves empty room with tabs hidden at the start.
		require
			keep_in_range: a_keep >= 1 and a_keep <= a_naturals.count
			first_in_range: a_first >= 1 and a_first <= a_naturals.count
		do
			Result := a_first.min (a_keep)
			from
			until
				Result = a_keep or else run_width (a_naturals, Result, a_keep, a_gap) <= a_room
			loop
				Result := Result + 1
			end
			from
			until
				Result = 1 or else run_width (a_naturals, Result - 1, a_naturals.count, a_gap) > a_room
			loop
				Result := Result - 1
			end
		ensure
			keeps: Result >= 1 and Result <= a_keep
		end

feature -- Placement

	place_tabs_shrinking (a_naturals: ARRAYED_LIST [REAL_64]; a_left, a_room: REAL_64)
			-- SHRINK: every tab side by side from `a_left' at its natural
			-- width, or in equal shares of `a_room' when those overflow it.
		require
			room_non_negative: a_room >= 0.0
		local
			i: INTEGER
			l_x, l_w: REAL_64
			l_shrink: BOOLEAN
		do
			tab_lefts.wipe_out
			tab_widths.wipe_out
			l_shrink := run_width (a_naturals, 1, a_naturals.count, 0.0) > a_room
			l_x := a_left
			from
				i := 1
			until
				i > a_naturals.count
			loop
				if l_shrink then
					l_w := (a_room / a_naturals.count).max (1.0)
				else
					l_w := a_naturals.i_th (i)
				end
				tab_lefts.extend (l_x)
				tab_widths.extend (l_w)
				l_x := l_x + l_w
				i := i + 1
			end
			last_placed := a_naturals.count
		ensure
			one_box_per_tab: tab_lefts.count = a_naturals.count and tab_widths.count = a_naturals.count
			all_placed: last_placed = a_naturals.count
		end

	place_tabs_scrolling (a_naturals: ARRAYED_LIST [REAL_64]; a_left, a_room, a_gap: REAL_64; a_first: INTEGER)
			-- SCROLL: from tab `a_first', tabs side by side at their natural
			-- widths with `a_gap' between, as many as fit whole in `a_room';
			-- the tabs before `a_first' and after the last that fits get no
			-- width. Tab `a_first' is always placed, cut to the room but
			-- never below one pixel (scan 9: a bar too narrow for any room
			-- once gave the selected tab no width at all).
		require
			first_in_range: a_naturals.is_empty or else (a_first >= 1 and a_first <= a_naturals.count)
			room_non_negative: a_room >= 0.0
			gap_non_negative: a_gap >= 0.0
		local
			i: INTEGER
			l_x: REAL_64
			l_full: BOOLEAN
		do
			tab_lefts.wipe_out
			tab_widths.wipe_out
			last_placed := 0
			l_x := a_left
			from
				i := 1
			until
				i > a_naturals.count
			loop
				if i >= a_first and then not l_full
					and then (i = a_first or else l_x + a_naturals.i_th (i) <= a_left + a_room)
				then
					tab_lefts.extend (l_x)
					tab_widths.extend (a_naturals.i_th (i).min (a_room).max (1.0))
					l_x := l_x + a_naturals.i_th (i) + a_gap
					last_placed := i
				else
					l_full := l_full or i > a_first
					tab_lefts.extend (a_left)
					tab_widths.extend (0.0)
				end
				i := i + 1
			end
		ensure
			one_box_per_tab: tab_lefts.count = a_naturals.count and tab_widths.count = a_naturals.count
			first_placed: not a_naturals.is_empty implies last_placed >= a_first
			first_has_width: not a_naturals.is_empty implies tab_widths.i_th (a_first) > 0.0
		end

	forget_placement
			-- The tabs changed in number: no box stands until the next
			-- placement, so no stale box answers a hit test.
		do
			tab_lefts.wipe_out
			tab_widths.wipe_out
			last_placed := 0
		ensure
			no_boxes: tab_lefts.is_empty and tab_widths.is_empty
			nothing_placed: last_placed = 0
		end

	swap_adjacent_boxes (a_i: INTEGER)
			-- Tabs `a_i' and `a_i' + 1 changed places: swap their widths and
			-- stand the second where the first ends, keeping the gap, so hit
			-- testing is right again before the next arrange (a drag moves a
			-- tab several places in one pointer move).
		require
			both_placed: a_i >= 1 and a_i < tab_widths.count
			both_shown: tab_widths.i_th (a_i) > 0.0 and tab_widths.i_th (a_i + 1) > 0.0
		local
			l_gap, l_w: REAL_64
		do
			l_gap := tab_lefts.i_th (a_i + 1) - tab_lefts.i_th (a_i) - tab_widths.i_th (a_i)
			l_w := tab_widths.i_th (a_i)
			tab_widths.put_i_th (tab_widths.i_th (a_i + 1), a_i)
			tab_widths.put_i_th (l_w, a_i + 1)
			tab_lefts.put_i_th (tab_lefts.i_th (a_i) + tab_widths.i_th (a_i) + l_gap, a_i + 1)
		ensure
			same_count: tab_widths.count = old tab_widths.count
			left_stays: tab_lefts.i_th (a_i) = old tab_lefts.i_th (a_i)
			swapped: tab_widths.i_th (a_i) = old tab_widths.i_th (a_i + 1)
				and tab_widths.i_th (a_i + 1) = old tab_widths.i_th (a_i)
		end

invariant
	one_left_per_width: tab_lefts.count = tab_widths.count
	last_placed_in_range: last_placed >= 0 and last_placed <= tab_widths.count

end
