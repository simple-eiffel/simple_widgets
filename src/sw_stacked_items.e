note
	description: "[
		A widget that stacks items of DIFFERENT heights in a scrolling
		column (0.23.0): the SW_BLOCK_STACK they stand on, the measuring
		pass that re-measures only what changed, the visible range, the
		window top of an item, the item under a point, the scroll that
		shows an item, and the frame a pass draws in.

		A descendant says:

		    stack_count            how many items
		    stack_origin_y         where item 1's top stands below the
		                           widget's top before scrolling (a page
		                           inset, or 0)
		    item_revision (i)      what item i's measurement is for
		    is_volatile (i)        is item i measured every pass (the item
		                           under an editor)?
		    measure_item (p, i)    item i's height, laying it out
		    stack_reset            rebuild the per-item structures when
		                           every measurement is dropped
		    draw_stacked_item (p, i)

		and calls `measure_stack' from its own measure and `begin_frame',
		`draw_visible', `end_frame' from its draw. `scroll_y' and
		`is_laid_out' are deferred here so they join with SW_VSCROLLING's
		and the descendant's. Nothing of SW_WIDGET is redefined, so it
		inherits beside the other four. Lifted (0.23.0) from
		SW_PARAGRAPH_LIST and SW_DOCUMENT_VIEW, whose copies the
		post-merge scan found (and where the view's page inset had to be
		subtracted by hand at four sites).
	]"
	author: "Larry Rix"

deferred class
	SW_STACKED_ITEMS

inherit
	SW_WIDGET

feature -- Stack

	stack: SW_BLOCK_STACK
			-- Where the items stand.
		attribute
			create Result.make
		end

	viewport_height: REAL_64
			-- The height asked of a layout.

	stack_count: INTEGER
			-- Items stacked.
		deferred
		ensure
			non_negative: Result >= 0
		end

	stack_origin_y: REAL_64
			-- Item 1's top below the widget's top, before scrolling.
		deferred
		ensure
			non_negative: Result >= 0.0
		end

	scroll_y: REAL_64
			-- How far the content is shifted up.
		deferred
		end

	is_laid_out: BOOLEAN
			-- Do the measurements stand for the items as they are?
		deferred
		end

	pinned_height: REAL_64
			-- A band at the top that does not scroll (column titles): the
			-- items scrolled under it are hidden, so it is never an item and
			-- an item shown is shown below it. 0 by default.
		do
		ensure
			non_negative: Result >= 0.0
		end

	first_visible: INTEGER
			-- The first item in the viewport; 0 when none.
		do
			if is_laid_out then
				Result := stack.first_visible (scroll_y - stack_origin_y)
			end
		ensure
			in_range: Result >= 0 and Result <= stack_count
		end

	last_visible: INTEGER
			-- The last item in the viewport; 0 when none.
		local
			vh: REAL_64
		do
			if is_laid_out then
				vh := height
				if vh <= 0.0 then
					vh := viewport_height
				end
				Result := stack.last_visible (scroll_y - stack_origin_y, vh)
			end
		ensure
			in_range: Result >= 0 and Result <= stack_count
		end

	stacked_top (a_i: INTEGER): REAL_64
			-- Item `a_i''s top in window coordinates.
		require
			in_range: a_i >= 1 and a_i <= stack.count
		do
			Result := y + stack_origin_y - scroll_y + stack.top (a_i)
		end

	stacked_item_at (a_py: REAL_64): INTEGER
			-- The item whose box holds window y `a_py'; 0 outside the widget,
			-- on the pinned band, before layout, or between items.
		do
			if is_laid_out and then a_py >= y + pinned_height and then a_py < y + height then
				Result := stack.item_at (a_py - y - stack_origin_y + scroll_y)
			end
		ensure
			in_range: Result >= 0 and Result <= stack_count
		end

	stacked_scroll_for (a_i: INTEGER): REAL_64
			-- The scroll position nearest `scroll_y' that shows item `a_i'
			-- whole below the pinned band (its top, when it is taller than
			-- the view), in the coordinates `scroll_y' counts in.
		require
			in_range: a_i >= 1 and a_i <= stack.count
		local
			l_top, l_bottom: REAL_64
		do
			l_top := stack_origin_y + stack.top (a_i) - pinned_height
			l_bottom := stack_origin_y + stack.top (a_i) + stack.height (a_i)
			Result := scroll_y
			if l_bottom - Result > height then
				Result := l_bottom - height
			end
			if l_top < Result then
				Result := l_top
			end
			Result := Result.max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	scroll_to (a_y: REAL_64)
			-- Scroll to `a_y' (SW_VSCROLLING's).
		deferred
		end

	scroll_item_into_view (a_i: INTEGER)
			-- Bring item `a_i' into view, below any pinned band, once laid
			-- out.
		require
			in_range: a_i >= 1 and a_i <= stack_count
		do
			if is_laid_out and then height > 0.0 and then a_i <= stack.count then
				scroll_to (stacked_scroll_for (a_i))
			end
				-- Also met after the next measure: items added since the last layout are not
				-- stacked yet, and a refilled view (a new chapter) would lose the request.
			pending_scroll_item := a_i
		ensure
			remembered: pending_scroll_item = a_i
		end

	pending_scroll_item: INTEGER
			-- The item `scroll_item_into_view' asked for, met at the next `measure_stack' (or dropped
			-- there when the list no longer reaches it); 0 when none.

	body_pixel_size (a_p: SW_PAINTER): INTEGER
			-- Body text's pixel size at the painter's scale: what a layout
			-- key and a wheel line are made of.
		do
			Result := (a_p.theme.size_body * a_p.theme.text_scale).rounded.max (1)
		ensure
			positive: Result >= 1
		end

feature {NONE} -- Stack pieces

	item_revision (a_i: INTEGER): INTEGER
			-- What item `a_i''s measurement is for (grows with each change).
		require
			in_range: a_i >= 1 and a_i <= stack_count
		deferred
		ensure
			non_negative: Result >= 0
		end

	is_volatile (a_i: INTEGER): BOOLEAN
			-- Is item `a_i' measured on every pass?
		require
			in_range: a_i >= 1 and a_i <= stack_count
		deferred
		end

	measure_item (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
			-- Lay item `a_i' out; its height.
		require
			in_range: a_i >= 1 and a_i <= stack_count
		deferred
		ensure
			non_negative: Result >= 0.0
		end

	stack_reset
			-- Every measurement was dropped: rebuild the per-item structures.
		deferred
		end

	draw_stacked_item (a_p: SW_PAINTER; a_i: INTEGER)
			-- Paint item `a_i'.
		require
			in_range: a_i >= 1 and a_i <= stack_count
		deferred
		end

	measure_stack (a_p: SW_PAINTER; a_key: READABLE_STRING_8; a_gap: REAL_64): BOOLEAN
			-- Measure every item that changed (all of them when the count or
			-- `a_key' changed: `stack_reset' first), then restack with
			-- `a_gap' between items. Did anything change?
		require
			gap_non_negative: a_gap >= 0.0
		local
			i, l_revision: INTEGER
		do
			if stack.reset_if_changed (stack_count, a_key) then
				stack_reset
				Result := True
			end
			from
				i := 1
			until
				i > stack_count
			loop
				l_revision := item_revision (i)
				if stack.needs_measure (i, l_revision) or else is_volatile (i) then
					stack.put_height (i, measure_item (a_p, i).max (1.0), l_revision)
					Result := True
				end
				i := i + 1
			end
			stack.restack (a_gap)
			if pending_scroll_item > stack.count then
					-- The rows it named are gone (design scan 22): never move the view for them later.
				pending_scroll_item := 0
			elseif pending_scroll_item >= 1 and then height > 0.0 then
				scroll_to (stacked_scroll_for (pending_scroll_item))
				pending_scroll_item := 0
			end
		ensure
			counted: stack.count = stack_count
		end

	begin_frame (a_p: SW_PAINTER)
			-- The surface, and a clip inside its edge.
		do
			a_p.set_color (a_p.theme.surface)
			a_p.rrect_fill (x, y, width, height, a_p.theme.radius)
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
		end

	draw_visible (a_p: SW_PAINTER)
			-- Every item in the viewport.
		local
			i, l_last: INTEGER
		do
			l_last := last_visible
			from
				i := first_visible
			until
				i = 0 or i > l_last
			loop
				draw_stacked_item (a_p, i)
				i := i + 1
			end
		end

	end_frame (a_p: SW_PAINTER)
			-- Let go of the clip.
		do
			a_p.pop_clip
		end

invariant
	viewport_non_negative: viewport_height >= 0.0

end
