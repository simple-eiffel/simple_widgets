note
	description: "[
		The data grid: typed rows, first-class columns, click-a-
		header sorting (ascending, then descending), drag-a-divider
		resizing, a host-supplied filter predicate, virtualized
		rendering, zebra rows, frozen header. Selection follows the
		ROW OBJECT, not its position - re-sorting keeps your record
		selected at its new place. Read-only in v1: activation is an
		agent; editing composes outside (the SHEET lesson).
	]"
	performance: "[
		NOTE TO WHOEVER EDITS THIS NEXT (GW-29, 2026-10-25). The grid holds
		100,000 rows of shaped text at 60 Hz; SW_VIRTUAL_GRID_ASSAULT times it.
		Keep these, or that test fails:
		- Draw touches only the visible rows.
		- `merge_sort_view' asks each row's key ONCE (`SW_GRID_COLUMN.sort_key')
		  and merges over SPECIAL arrays; two agent calls a comparison made
		  100,000 rows take 1.9 s.
		- `add_row' places one row (filter that row, binary search); a full
		  `rebuild_view' per added row took 10 s for 2,000 rows.
		- Cells shape through the painter, whose kit memo makes a redrawn row
		  free; a page of new rows is the expensive case.
		Open: Row_h and Header_h are fixed pixels (they do not follow the
		text scale); `selected_view_position' is a linear scan.
	]"

class
	SW_DATA_GRID [G]

inherit
	SW_WIDGET
		redefine
			handle_click, handle_double_click, handle_drag, handle_wheel,
			handle_key, handle_char, set_focused, takes_typing, menu_left, menu_top,
			wants_hover_point, accepts_focus, cursor_kind, handle_release,
			accessible_role, context_menu, dwell_ms, hover_card_at,
			accessible_item_count, publish_accessible_items
		end

	SW_COPYING

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			create rows.make (32)
			create columns.make (6)
			create view.make (32)
			create bar.make
			selected_model := 0
			resizing_column := 0
		ensure
			kept: viewport_height = a_viewport_height
		end

feature -- Access

	rows: ARRAYED_LIST [G]

	columns: ARRAYED_LIST [SW_GRID_COLUMN [G]]

	view: ARRAYED_LIST [INTEGER]
			-- Model indices surviving the filter, in sort order.

	viewport_height: REAL_64

	bar: SW_VSCROLLBAR
			-- The vertical scrollbar, under the header at the right edge.

	Header_h: REAL_64 = 30.0

	Row_h: REAL_64 = 26.0

	scroll_x, scroll_y: REAL_64

	sort_column: INTEGER
			-- 1-based sorted column; 0 = unsorted (model order).

	is_descending: BOOLEAN

	selected_model: INTEGER
			-- Model index of the selected row; 0 = none. Survives
			-- sorting and filtering (cleared only if filtered out).

	selected_object: detachable G
		do
			if selected_model >= 1 and selected_model <= rows.count then
				Result := rows.i_th (selected_model)
			end
		end

	on_select: detachable PROCEDURE [INTEGER]
			-- Fired with the MODEL index on selection change.

	context_model: INTEGER
			-- Model index of the row the last right-click fell on; 0 =
			-- none. Outlined, NOT selected: a right-click must not fire
			-- `on_select' (in simple_bible selecting a bookmark goes to
			-- its verse), and a later click on the same row must still
			-- select it. Cleared by the next click and by `set_rows'.

	context_column: INTEGER
			-- The column the last right-click fell in; 0 = none.

	context_object: detachable G
			-- The row the last right-click fell on, for a client's
			-- `menu_extension'.
		do
			if context_model >= 1 and context_model <= rows.count then
				Result := rows.i_th (context_model)
			end
		end

	cell_text (a_model, a_column: INTEGER): STRING_32
			-- What row `a_model' shows in column `a_column': an accepted edit's text, else the
			-- column's own value (sorting and the filter predicate still read the source rows).
		require
			row_known: a_model >= 1 and a_model <= rows.count
			column_known: a_column >= 1 and a_column <= columns.count
		do
			if not edited.is_empty and then attached edited.item (edit_key (a_model, a_column)) as al_text then
				Result := al_text.twin
			else
				Result := columns.i_th (a_column).value.item ([rows.i_th (a_model)])
			end
		end

	row_text (a_model: INTEGER): STRING_32
			-- Row `a_model''s cells, a tab between them.
		require
			row_known: a_model >= 1 and a_model <= rows.count
		local
			ci: INTEGER
		do
			create Result.make (80)
			from
				ci := 1
			until
				ci > columns.count
			loop
				if ci > 1 then
					Result.append_character ('%T')
				end
				Result.append (cell_text (a_model, ci))
				ci := ci + 1
			end
		end

	shown_rows_text: STRING_32
			-- The column titles, then every row the view shows in its
			-- order, one line each, a tab between cells - what a
			-- spreadsheet pastes as a table.
		local
			ci, i: INTEGER
		do
			create Result.make (80 * (view.count + 1))
			from
				ci := 1
			until
				ci > columns.count
			loop
				if ci > 1 then
					Result.append_character ('%T')
				end
				Result.append (columns.i_th (ci).title)
				ci := ci + 1
			end
			from
				i := 1
			until
				i > view.count
			loop
				Result.append_character ('%N')
				Result.append (row_text (view.i_th (i)))
				i := i + 1
			end
		end

	on_activate: detachable PROCEDURE [INTEGER]
			-- Fired with the MODEL index on double-click.

	filter: detachable FUNCTION [G, BOOLEAN]

	shown_width (a_i: INTEGER): REAL_64
			-- Column `a_i''s drawn width: its own, plus its share of the
			-- spare width when it grows and the grid is wider than its columns.
		require
			valid: a_i >= 1 and a_i <= columns.count
		local
			l_total_grow: REAL_64
		do
			Result := columns.i_th (a_i).width
			if columns.i_th (a_i).grow > 0.0 then
				across
					columns as c
				loop
					l_total_grow := l_total_grow + c.grow
				end
				Result := Result + (width - bar.bar_width - content_width).max (0.0) * columns.i_th (a_i).grow / l_total_grow
			end
		ensure
			at_least_own: Result >= columns.i_th (a_i).width
		end

	content_width: REAL_64
		do
			across
				columns as c
			loop
				Result := Result + c.width
			end
		ensure
			non_negative: Result >= 0.0
		end

feature -- Element change

	add_column (a_col: SW_GRID_COLUMN [G])
		do
			columns.extend (a_col)
		ensure
			grew: columns.count = old columns.count + 1
		end

	with_column (a_col: SW_GRID_COLUMN [G]): like Current
		do
			add_column (a_col)
			Result := Current
		ensure
			chained: Result = Current
		end

	set_rows (a_rows: ARRAYED_LIST [G])
			-- Adopt a SNAPSHOT of `a_rows'. The grid owns its own list, so a
			-- caller that later mutates its own list (removing a row, clearing
			-- finished ones) cannot desync `rows' from the cached `view' and
			-- trip `view_never_exceeds_rows'. To reflect such a change, the
			-- caller calls `set_rows' again - which every refresh already does.
		do
			cancel_edit
			edited.wipe_out
			cell_note.wipe_out
			note_model := 0
			rows := a_rows.twin
			if selected_model > rows.count then
				selected_model := 0
			end
			from also_selected.start until also_selected.after loop
				if also_selected.item > rows.count then
					also_selected.remove
				else
					also_selected.forth
				end
			end
			context_model := 0
			rebuild_view
		ensure
			owns_snapshot: rows /= a_rows
			same_size: rows.count = a_rows.count
		end

	add_row (a_row: G)
			-- `a_row' at the end of the rows; in the view only when it passes
			-- the filter, and then at its place in the sort (after equal keys,
			-- so the sort stays stable) - one comparison per halving, not a
			-- whole rebuild. 100,000 rows added one at a time took hours.
		local
			lo, hi, mid, l_model: INTEGER
			l_key: COMPARABLE
			l_column: SW_GRID_COLUMN [G]
		do
			rows.extend (a_row)
			l_model := rows.count
			if passes (l_model, a_row) then
				if sort_column >= 1 and sort_column <= columns.count then
					l_column := columns.i_th (sort_column)
					l_key := l_column.sort_key (a_row)
					from
						lo := 1
						hi := view.count + 1
					until
						lo >= hi
					loop
						mid := (lo + hi) // 2
						if not is_descending then
							if l_key < l_column.sort_key (rows.i_th (view.i_th (mid))) then
								hi := mid
							else
								lo := mid + 1
							end
						elseif l_column.sort_key (rows.i_th (view.i_th (mid))) < l_key then
							hi := mid
						else
							lo := mid + 1
						end
					end
					if lo > view.count then
						view.extend (l_model)
					else
						view.go_i_th (lo)
						view.put_left (l_model)
					end
				else
					view.extend (l_model)
				end
			end
			if pinned /= Void then
					-- a pinned row may belong ahead of the place the sort gave it
				rebuild_view
			end
			sync_bar
		ensure
			grew: rows.count = old rows.count + 1
			shown_when_it_passes: view.count = old view.count + (if passes (rows.count, a_row) then 1 else 0 end)
		end

	put_row (a_row: G; i: INTEGER)
			-- Model row `i' becomes `a_row' in place (a lazy table's answer for a row it
			-- showed empty). The view is rebuilt only when it is sorted, filtered or pinned;
			-- otherwise row `i' just draws anew.
		require
			valid: i >= 1 and i <= rows.count
		do
			rows.put_i_th (a_row, i)
			forget_row_edits (i)
			if (sort_column >= 1 and sort_column <= columns.count) or filter /= Void or shown_set /= Void or pinned /= Void then
				rebuild_view
			end
		ensure
			put: rows.i_th (i) = a_row
			same_size: rows.count = old rows.count
		end

	shown_positions: TUPLE [first, last: INTEGER]
			-- The view positions in sight now (both 0 when none are): what `draw' paints.
		local
			l_first, l_last: INTEGER
		do
			if view.count > 0 and height > Header_h then
				l_first := ((scroll_y / Row_h).truncated_to_integer + 1).max (1).min (view.count)
				l_last := (((scroll_y + height - Header_h) / Row_h).truncated_to_integer + 1).min (view.count)
			end
			Result := [l_first, l_last]
		ensure
			ordered: Result.first <= Result.last
			in_view: Result.last <= view.count
		end

	scroll_to_position (a_pos: INTEGER)
			-- Bring view position `a_pos' into sight: to the top when it is above, to the
			-- bottom when it is below, nothing when it shows.
		require
			valid: a_pos >= 1 and a_pos <= view.count
		do
			if (a_pos - 1) * Row_h < scroll_y then
				scroll_y := (a_pos - 1) * Row_h
			elseif a_pos * Row_h > scroll_y + height - Header_h then
				scroll_y := (a_pos * Row_h - (height - Header_h)).max (0.0)
			end
			sync_bar
		end

	add_rows (a_rows: ITERABLE [G])
			-- Every row of `a_rows' at the end, with one filter-and-sort.
		do
			across a_rows as r loop
				rows.extend (r)
			end
			rebuild_view
		end

	hover_card_provider: detachable FUNCTION [G, INTEGER, detachable SW_HOVER_CARD]
			-- A card for a row and the column under the pointer, asked after a dwell (0.54.0: a meme's
			-- picture over its icon); Void for none.

	set_hover_card (a_provider: detachable FUNCTION [G, INTEGER, detachable SW_HOVER_CARD])
			-- Rows offer the card `a_provider' gives for a row and a column (Void for none there).
		do
			hover_card_provider := a_provider
		ensure
			set: hover_card_provider = a_provider
		end

	dwell_ms: INTEGER
			-- A grid with a card provider asks for a dwell.
		do
			if hover_card_provider /= Void then
				Result := Card_dwell_ms
			end
		end

	Card_dwell_ms: INTEGER = 400
			-- How long the pointer rests on a cell before its card opens.

	hover_card_at (a_px, a_py: REAL_64): detachable SW_HOVER_CARD
			-- The card the provider gives for the row and column under the point, anchored on that cell.
		local
			r, c: INTEGER
			cx: REAL_64
		do
			if attached hover_card_provider as al_provider then
				r := view_row_at (a_py)
				c := header_column_at (a_px)
				if r > 0 and c > 0 then
					Result := al_provider.item ([rows.i_th (view.i_th (r)), c])
					if attached Result as al_card then
						cx := column_lefts.i_th (c)
						al_card.set_anchor (cx, y + Header_h + (r - 1) * Row_h - scroll_y, shown_width (c), Row_h)
					end
				end
			end
		end

	pinned: detachable FUNCTION [G, BOOLEAN]
			-- Rows that stay before the rest whatever the sort (0.53.0: a reader's favorite memes);
			-- Void for none.

	set_pinned (a_predicate: detachable FUNCTION [G, BOOLEAN])
			-- Rows `a_predicate' holds for come first, in sort order among themselves; Void clears it.
		do
			pinned := a_predicate
			rebuild_view
		ensure
			set: pinned = a_predicate
		end

	is_pinned (a_row: G): BOOLEAN
			-- Does `a_row' stay before the rest?
		do
			Result := attached pinned as al_pinned and then al_pinned.item ([a_row])
		end

	set_filter (a_predicate: detachable FUNCTION [G, BOOLEAN])
			-- Void clears the filter.
		do
			filter := a_predicate
			rebuild_view
		ensure
			set: filter = a_predicate
		end

	sort_by (a_column: INTEGER; a_descending: BOOLEAN)
		require
			in_range: a_column >= 0 and a_column <= columns.count
		do
			sort_column := a_column
			is_descending := a_descending
			rebuild_view
		ensure
			sorted: sort_column = a_column and is_descending = a_descending
		end

	select_model_row (a_model: INTEGER)
		require
			in_range: a_model >= 0 and a_model <= rows.count
		do
			if a_model /= selected_model then
				selected_model := a_model
				if a_model > 0 and then attached on_select as s then
					s.call (a_model)
				end
			end
		ensure
			selected: selected_model = a_model
		end

	on_header_click: detachable PROCEDURE [INTEGER, BOOLEAN]
			-- When set, a header click is reported - (column, ascending) - and the grid does not
			-- sort: the program sorts, the grid only shows `indicator_column' (simple_gui's rule).

	indicator_column: INTEGER
			-- The column whose header shows the sort arrow in that mode (0: none).

	indicator_descending: BOOLEAN

	set_on_header_click (a_action: PROCEDURE [INTEGER, BOOLEAN])
		do
			on_header_click := a_action
		ensure
			set: on_header_click = a_action
		end

	set_sort_indicator (a_column: INTEGER; a_ascending: BOOLEAN)
			-- Show the arrow on `a_column' (0: none), without sorting.
		require
			in_range: a_column >= 0 and a_column <= columns.count
		do
			indicator_column := a_column
			indicator_descending := not a_ascending
		ensure
			set: indicator_column = a_column and indicator_descending = not a_ascending
		end

	is_multiple: BOOLEAN
			-- May several rows be selected (Ctrl+click adds or removes one)?

	set_multiple (a_on: BOOLEAN)
		do
			is_multiple := a_on
			also_selected.wipe_out
		ensure
			set: is_multiple = a_on
		end

	also_selected: ARRAYED_LIST [INTEGER]
			-- Model rows selected besides `selected_model' (multiple mode).
		attribute
			create Result.make (4)
		end

	is_row_selected (a_model: INTEGER): BOOLEAN
		do
			Result := a_model > 0 and then (a_model = selected_model or else also_selected.has (a_model))
		end

	selected_count: INTEGER
		do
			if selected_model > 0 then
				Result := 1 + also_selected.count
			end
		end

	selected_at (a_i: INTEGER): INTEGER
			-- The `a_i'th selected model row, in the order they were selected.
		require
			in_range: a_i >= 1 and a_i <= selected_count
		do
			if a_i = 1 then
				Result := selected_model
			else
				Result := also_selected.i_th (a_i - 1)
			end
		end

	select_model_row_quietly (a_model: INTEGER; a_extend: BOOLEAN)
			-- Select `a_model' as the program, reporting nothing; with `a_extend' (multiple mode)
			-- add it to the selection.
		require
			in_range: a_model >= 0 and a_model <= rows.count
		do
			if a_extend and is_multiple and selected_model > 0 and a_model > 0 then
				if a_model /= selected_model and not also_selected.has (a_model) then
					also_selected.extend (a_model)
				end
			else
				also_selected.wipe_out
				selected_model := a_model
			end
		ensure
			selected: is_row_selected (a_model) or a_model = 0
		end

	set_on_select (a_action: PROCEDURE [INTEGER])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

	set_on_activate (a_action: PROCEDURE [INTEGER])
		do
			on_activate := a_action
		ensure
			set: on_activate = a_action
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := viewport_height
		end

	view_row_at (a_py: REAL_64): INTEGER
			-- The view row under widget-space y; 0 outside (the sign
			-- guard matters: truncation rounds toward zero).
		do
			if a_py >= y + Header_h then
				Result := (((a_py - y - Header_h + scroll_y) / Row_h).truncated_to_integer + 1)
				if Result < 1 or Result > view.count then
					Result := 0
				end
			end
		ensure
			in_range: Result >= 0 and Result <= view.count
		end

	column_edge_at (a_px: REAL_64): INTEGER
			-- Which column's closing divider (its right side, or its left
			-- when mirrored) the point is within 5px of; 0 for none.
		local
			l_lefts: ARRAYED_LIST [REAL_64]
			i: INTEGER
		do
			l_lefts := column_lefts
			from
				i := 1
			until
				i > columns.count or Result > 0
			loop
				if (a_px - divider_x (l_lefts, i)).abs <= 5.0 then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= columns.count
		end

	header_column_at (a_px: REAL_64): INTEGER
			-- The column whose header the point is in; 0 outside.
		local
			l_lefts: ARRAYED_LIST [REAL_64]
			i: INTEGER
		do
			l_lefts := column_lefts
			from
				i := 1
			until
				i > columns.count or Result > 0
			loop
				if a_px >= l_lefts.i_th (i) and a_px < l_lefts.i_th (i) + shown_width (i) then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= columns.count
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			first_v, last_v, i, ci: INTEGER
			ry, cx, l_mark_x, l_text_x, l_arrow_x: REAL_64
			col: SW_GRID_COLUMN [G]
			s: STRING_32
			l_lefts: ARRAYED_LIST [REAL_64]
		do
			t := a_p.theme
			l_lefts := column_lefts
			bar.place (x, y + Header_h, width, height - Header_h, t)
			sync_bar
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.push_clip (x, y, width, height)
				-- rows (visible band only)
			if view.count > 0 then
				first_v := ((scroll_y / Row_h).truncated_to_integer + 1).max (1).min (view.count)
				last_v := (((scroll_y + height - Header_h) / Row_h).truncated_to_integer + 1).min (view.count)
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				from
					i := first_v
				until
					i > last_v
				loop
					ry := y + Header_h + ((i - 1) * Row_h - scroll_y)
					if is_row_selected (view.i_th (i)) then
						a_p.set_color (t.wash_accent)
						a_p.fill_rect (x, ry, width, Row_h)
					elseif i \\ 2 = 0 then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x, ry, width, Row_h)
					end
					if view.i_th (i) = context_model then
						a_p.set_color (t.accent)
						a_p.rrect_stroke (x + 1.5, ry + 0.5, width - 3.0, Row_h - 1.0, 2.0)
					end
					from
						ci := 1
					until
						ci > columns.count
					loop
						cx := l_lefts.i_th (ci)
						col := columns.i_th (ci)
						s := cell_text (view.i_th (i), ci)
						a_p.push_clip (cx + 1.0, ry, shown_width (ci) - 2.0, Row_h)
							-- a star or glyph sits on the leading side: the left, or the right when mirrored
						if mirrors_layout then
							l_mark_x := cx + shown_width (ci) - 15.0
							l_text_x := cx
						else
							l_mark_x := cx + 15.0
							l_text_x := cx + 16.0
						end
						if column_editor (ci) = Edit_check then
								-- a check cell: a box, ticked when the text reads 1
							if mirrors_layout then
								l_mark_x := cx + shown_width (ci) - 22.0
							else
								l_mark_x := cx + 8.0
							end
							draw_check_box (a_p, l_mark_x + 7.0, ry + Row_h / 2.0, s.same_string ("1"))
						elseif col.is_starred (rows.i_th (view.i_th (i))) then
								-- a favorite (0.50.0): the star, then the text past it
							a_p.set_color (t.star)
							a_p.glyph ({SW_PAINTER}.Glyph_star, l_mark_x, ry + Row_h / 2.0, 12.0)
							a_p.set_color (t.ink)
							a_p.text (cell_left (a_p, s, col.alignment, l_text_x, shown_width (ci) - 16.0), ry + Row_h - 8.0, s)
						elseif col.glyph_of (rows.i_th (view.i_th (i))) > 0 then
								-- a glyph (0.54.0), muted, then the text past it
							a_p.set_color (t.ink_muted)
							a_p.glyph (col.glyph_of (rows.i_th (view.i_th (i))), l_mark_x, ry + Row_h / 2.0, 13.0)
							a_p.set_color (t.ink)
							a_p.text (cell_left (a_p, s, col.alignment, l_text_x, shown_width (ci) - 16.0), ry + Row_h - 8.0, s)
						else
							a_p.set_color (t.ink)
							a_p.text (cell_left (a_p, s, col.alignment, cx, shown_width (ci)), ry + Row_h - 8.0, s)
						end
						if column_editor (ci) = Edit_choice then
								-- a choice cell: a chevron at its trailing edge
							a_p.set_color (t.ink_muted)
							if mirrors_layout then
								l_arrow_x := cx + 6.0
							else
								l_arrow_x := cx + shown_width (ci) - 16.0
							end
							a_p.line (l_arrow_x, ry + Row_h / 2.0 - 2.0, l_arrow_x + 4.0, ry + Row_h / 2.0 + 2.0, 1.5)
							a_p.line (l_arrow_x + 4.0, ry + Row_h / 2.0 + 2.0, l_arrow_x + 8.0, ry + Row_h / 2.0 - 2.0, 1.5)
						end
						a_p.pop_clip
						ci := ci + 1
					end
					i := i + 1
				end
			end
			draw_editing (a_p)
				-- frozen header
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, Header_h)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
			from
				ci := 1
			until
				ci > columns.count
			loop
				cx := l_lefts.i_th (ci)
				col := columns.i_th (ci)
				a_p.push_clip (cx + 1.0, y, shown_width (ci) - 2.0, Header_h)
				a_p.set_color (t.ink)
					-- the title on the leading side, the sort arrow on the trailing side
				if mirrors_layout then
					a_p.text (cx + shown_width (ci) - 8.0 - a_p.advance (col.title), y + Header_h - 10.0, col.title)
					l_arrow_x := cx + 10.0
				else
					a_p.text (cx + 8.0, y + Header_h - 10.0, col.title)
					l_arrow_x := cx + shown_width (ci) - 20.0
				end
				if ci = shown_sort_column then
					a_p.set_color (t.accent)
					if shown_descending then
						a_p.line (l_arrow_x, y + 12.0, l_arrow_x + 5.0, y + 19.0, 1.8)
						a_p.line (l_arrow_x + 5.0, y + 19.0, l_arrow_x + 10.0, y + 12.0, 1.8)
					else
						a_p.line (l_arrow_x, y + 19.0, l_arrow_x + 5.0, y + 12.0, 1.8)
						a_p.line (l_arrow_x + 5.0, y + 12.0, l_arrow_x + 10.0, y + 19.0, 1.8)
					end
				end
				a_p.pop_clip
				cx := divider_x (l_lefts, ci)
					-- divider, with a hover affordance for resizing
				if shows_hover and then (hover_px - cx).abs <= 5.0 then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.vline (cx - 0.5, y, height)
				ci := ci + 1
			end
			a_p.set_color (t.outline)
			a_p.hline (x, y + Header_h - 0.5, width)
				-- vertical scrollbar
			bar.draw (a_p, scroll_y, shows_hover and then bar.contains (hover_px, hover_py))
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	cell_left (a_p: SW_PAINTER; a_text: READABLE_STRING_32; a_alignment: INTEGER; a_cx, a_width: REAL_64): REAL_64
			-- Where `a_text' starts in a cell `a_width' wide at `a_cx', by
			-- `a_alignment'. Start is the right in a mirrored grid (as GTK
			-- aligns any text right to left); otherwise start and end follow
			-- the text's own direction (Hebrew flush right, GW-02).
		local
			l_right, l_slack: REAL_64
		do
			l_slack := (a_width - 16.0 - a_p.advance (a_text)).max (0.0)
			inspect a_alignment
			when {SHAPING_CONSTANTS}.Align_right then
				l_right := l_slack
			when {SHAPING_CONSTANTS}.Align_center then
				l_right := l_slack / 2.0
			when {SHAPING_CONSTANTS}.Align_start, {SHAPING_CONSTANTS}.Align_end then
				if (mirrors_layout or else is_right_to_left (a_p, a_text)) = (a_alignment = {SHAPING_CONSTANTS}.Align_start) then
					l_right := l_slack
				end
			else
			end
			Result := a_cx + 8.0 + l_right
		end

	is_right_to_left (a_p: SW_PAINTER; a_text: READABLE_STRING_32): BOOLEAN
			-- Does `a_text' read right to left (its first strong character)?
			-- Only shaped text knows; the toy path is left to right.
		do
			if a_p.takes_shaped_path (a_text) and then attached a_p.shaping as al_kit then
				Result := al_kit.layout_styled (a_text, 0, a_p.font_pixel_size, a_p.font_role, a_p.font_bold).base_direction
					= {SHAPING_CONSTANTS}.Direction_rtl
			end
		end

	cursor_kind: INTEGER
			-- Left-right resize arrows over a header divider (where a drag
			-- resizes the column), the arrow everywhere else.
		do
			if is_hovered and then is_enabled and then hover_py < y + Header_h
					and then column_edge_at (hover_px) > 0 then
				Result := 3
			end
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			edge, hc, vr: INTEGER
		do
			sync_bar
			swallow_return_char := False
			if is_enabled and then is_editing and then attached editor as al_editor
				and then al_editor.contains (a_px, a_py)
			then
				Result := al_editor.handle_click (a_px, a_py)
			elseif is_enabled and then bar.contains (a_px, a_py) then
				resizing_column := 0
				scroll_y := bar.press (a_py, scroll_y)
				Result := True
			elseif is_enabled then
				if is_editing then
					commit_edit
				end
				if a_py < y + Header_h then
					edge := column_edge_at (a_px)
					if edge > 0 then
						resizing_column := edge
					else
						hc := header_column_at (a_px)
						if hc > 0 and then attached on_header_click as al_report then
							al_report.call (hc, not (indicator_column = hc and not indicator_descending))
						elseif hc > 0 then
							if sort_column = hc then
								if is_descending then
									sort_by (0, False)
								else
									sort_by (hc, True)
								end
							else
								sort_by (hc, False)
							end
						end
					end
				else
					resizing_column := 0
					context_model := 0
					vr := view_row_at (a_py)
					if vr > 0 and is_multiple and (create {SW_KEYS}).control_down then
						toggle_extra (view.i_th (vr))
					elseif vr > 0 then
						also_selected.wipe_out
						select_model_row (view.i_th (vr))
						hc := header_column_at (a_px)
						if hc > 0 and then (column_editor (hc) = Edit_check or else column_editor (hc) = Edit_choice) then
							begin_edit (view.i_th (vr), hc)
						end
					end
				end
				Result := True
			end
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- Copy cell, Copy row and Copy all rows. The row under the
			-- pointer is noted (`context_model', outlined) so the actions
			-- - the grid's and a client's `menu_extension' - name it.
		local
			vr, l_model, l_column: INTEGER
		do
			vr := view_row_at (a_py)
			if vr > 0 then
				l_model := view.i_th (vr)
				l_column := header_column_at (a_px)
			end
			context_model := l_model
			context_column := l_column
			create Result.make
			if l_model > 0 and l_column > 0 then
				Result.add_item ("Copy cell", "", True, agent copy_text (cell_text (l_model, l_column)))
			else
				Result.add_item ("Copy cell", "", False, Void)
			end
			if l_model > 0 then
				Result.add_item ("Copy row", "", True, agent copy_text (row_text (l_model)))
			else
				Result.add_item ("Copy row", "", False, Void)
			end
			Result.add_item ("Copy all rows", "", not view.is_empty, agent copy_text (shown_rows_text))
		ensure then
			offered: Result /= Void
			noted: context_model >= 0 and context_model <= rows.count
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		local
			vr, hc: INTEGER
		do
			if is_enabled and then is_editing and then attached editor as al_editor
				and then al_editor.contains (a_px, a_py)
			then
				Result := al_editor.handle_double_click (a_px, a_py)
			elseif is_enabled then
				if is_editing then
					commit_edit
				end
				vr := view_row_at (a_py)
				if vr > 0 then
					hc := header_column_at (a_px)
					if hc > 0 and then column_editor (hc) = Edit_text then
						begin_edit (view.i_th (vr), hc)
					elseif hc > 0 and then column_editor (hc) = Edit_check then
						begin_edit (view.i_th (vr), hc)
					else
						select_model_row (view.i_th (vr))
						if attached on_activate as act then
							act.call (view.i_th (vr))
						end
					end
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
			-- The scrollbar thumb follows the pointer; a column being resized takes the width
			-- from its leading edge (left, or right when mirrored) to the pointer.
		local
			l_left, l_extra: REAL_64
		do
			if bar.is_dragging then
				scroll_y := bar.drag_to (a_py)
			elseif is_editing and then attached editor as al_editor then
				al_editor.handle_drag (a_px, a_py)
			elseif resizing_column >= 1 and resizing_column <= columns.count then
				l_left := column_lefts.i_th (resizing_column)
				l_extra := shown_width (resizing_column) - columns.i_th (resizing_column).width
				if mirrors_layout then
					columns.i_th (resizing_column).set_width (l_left + shown_width (resizing_column) - a_px - l_extra)
				else
					columns.i_th (resizing_column).set_width (a_px - l_left - l_extra)
				end
			end
		end

	column_lefts: ARRAYED_LIST [REAL_64]
			-- Each column's left edge on screen, scrolled: from the grid's left edge, or from
			-- its right edge when the grid `mirrors_layout' (the first column at the right).
			-- The one walk every hit test and drawing pass reads.
		local
			i: INTEGER
			l_x: REAL_64
		do
			create Result.make (columns.count)
			l_x := x - scroll_x
			from
				i := 1
			until
				i > columns.count
			loop
				Result.extend (mirrored_x (l_x, shown_width (i)))
				l_x := l_x + shown_width (i)
				i := i + 1
			end
		ensure
			one_each: Result.count = columns.count
		end

	divider_x (a_lefts: ARRAYED_LIST [REAL_64]; a_i: INTEGER): REAL_64
			-- The divider that closes column `a_i': its right side, or its left when mirrored.
		require
			valid: a_i >= 1 and a_i <= a_lefts.count and a_lefts.count = columns.count
		do
			if mirrors_layout then
				Result := a_lefts.i_th (a_i)
			else
				Result := a_lefts.i_th (a_i) + shown_width (a_i)
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go of the scrollbar thumb.
		do
			bar.release
		ensure then
			released: not bar.is_dragging
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		local
			keys: SW_KEYS
		do
			create keys
			if keys.shift_down then
				scroll_x := (scroll_x - a_delta / 120.0 * 60.0)
					.max (0.0).min ((content_width - width).max (0.0))
			else
				sync_bar
				scroll_y := bar.wheel_scroll (scroll_y, a_delta, Row_h)
			end
			Result := True
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			if is_editing and then attached editor as al_editor then
				if a_vk = 13 then
					commit_edit
					swallow_return_char := True
				elseif a_vk = 27 then
					cancel_edit
				else
					al_editor.handle_key (a_vk, a_shift)
				end
			elseif a_vk = 113 or else a_vk = 13 then
				if begin_edit_selected and then a_vk = 13 then
					swallow_return_char := True
				end
			else
				swallow_return_char := False
				move_selection_by_key (a_vk)
			end
		end

	handle_char (a_code: INTEGER)
			-- While a cell is open the editor takes the characters: Return commits, Escape cancels.
			-- A Return key that already acted is not acted on again by its character.
		do
			if swallow_return_char then
				swallow_return_char := False
				if a_code /= 13 then
					handle_char_now (a_code)
				end
			else
				handle_char_now (a_code)
			end
		end

	takes_typing: BOOLEAN
			-- An open cell keeps Ctrl+Z and the like for its editor.
		do
			Result := is_editing
		end

	set_focused (a_focused: BOOLEAN)
			-- Leaving the grid commits an open cell.
		do
			if not a_focused and then is_editing then
				commit_edit
			end
			Precursor (a_focused)
		end

	menu_left: REAL_64
			-- A choice cell's dropdown opens at the cell's left edge.
		do
			if menu_cell_column >= 1 and then menu_cell_column <= columns.count then
				Result := cell_left_of (menu_cell_column)
			else
				Result := Precursor
			end
		end

	menu_top: REAL_64
			-- and just under the cell.
		do
			if menu_cell_model >= 1 and then menu_cell_model <= rows.count and then view_position_of (menu_cell_model) > 0 then
				Result := cell_top_of (menu_cell_model) + Row_h
			else
				Result := Precursor
			end
		end

feature {NONE} -- Keys

	handle_char_now (a_code: INTEGER)
		do
			if is_editing and then attached editor as al_editor then
				if a_code = 13 then
					commit_edit
				elseif a_code = 27 then
					cancel_edit
				elseif a_code /= 9 then
					al_editor.handle_char (a_code)
				end
			elseif a_code = 13 then
				if begin_edit_selected then
				end
			end
		end

	move_selection_by_key (a_vk: INTEGER)
		local
			pos: INTEGER
		do
			pos := selected_view_position
			inspect a_vk
			when 40 then
				if pos > 0 and pos < view.count then
					select_model_row (view.i_th (pos + 1))
				elseif pos = 0 and view.count > 0 then
					select_model_row (view.i_th (1))
				end
			when 38 then
				if pos > 1 then
					select_model_row (view.i_th (pos - 1))
				end
			when 34 then
				if view.count > 0 then
					select_model_row (view.i_th ((pos + page_stride).min (view.count).max (1)))
				end
			when 33 then
				if view.count > 0 then
					select_model_row (view.i_th ((pos - page_stride).max (1)))
				end
			when 36 then
				if view.count > 0 then
					select_model_row (view.i_th (1))
				end
			when 35 then
				if view.count > 0 then
					select_model_row (view.i_th (view.count))
				end
			else
			end
			scroll_selection_into_view
		end

feature -- Editing cells (simple_gui 1s)

	passes (a_model: INTEGER; a_row: G): BOOLEAN
			-- Does model row `a_model' show: the filter and `set_shown_models' both allow it?
		do
			Result := (attached filter as al_filter implies al_filter.item ([a_row]))
				and then (attached shown_set as al_set implies al_set.has (a_model))
		end

	Edit_none: INTEGER = 0
	Edit_text: INTEGER = 1
	Edit_check: INTEGER = 2
	Edit_choice: INTEGER = 3

	on_cell_edit: detachable FUNCTION [INTEGER, INTEGER, STRING_32, detachable STRING_32]
			-- Asked (model row, column, new text) when the user commits an edit. A Void or empty
			-- answer accepts it: the grid shows the new text. A message refuses it: the cell keeps its
			-- old text and the message shows under the cell until the next edit starts.

	holds_edits: BOOLEAN
			-- Does the grid keep an accepted text (the default)? A grid whose program owns its rows
			-- (a lazy table) turns it off and updates its own source on the notice.
		do
			Result := not edits_not_held
		end

	column_editor (a_column: INTEGER): INTEGER
			-- How column `a_column' is edited: `Edit_none', `Edit_text', `Edit_check' or `Edit_choice'.
		require
			column_known: a_column >= 1 and a_column <= columns.count
		do
			if edit_kinds.has (a_column) then
				Result := edit_kinds.item (a_column)
			end
		ensure
			known: Result >= Edit_none and Result <= Edit_choice
		end

	column_choices (a_column: INTEGER): ARRAY [STRING_32]
			-- The options of a choice column; empty for none.
		require
			column_known: a_column >= 1 and a_column <= columns.count
		do
			if attached edit_choices.item (a_column) as al_choices then
				Result := al_choices
			else
				create Result.make_empty
			end
		end

	is_editing: BOOLEAN
			-- Is a text cell open under an editor?
		do
			Result := editing_column > 0
		ensure
			definition: Result = (editing_column > 0)
		end

	editing_model, editing_column: INTEGER
			-- The cell under the editor; 0 when none.

	cell_note: STRING_32
			-- The refusal message showing under a cell; empty for none.
		attribute
			create Result.make_empty
		end

	shown_count: INTEGER
			-- How many rows show (after the filter and `set_shown_models').
		do
			Result := view.count
		ensure
			definition: Result = view.count
		end

	view_position_of (a_model: INTEGER): INTEGER
			-- Where model row `a_model' sits in the view; 0 when it is hidden.
		local
			i: INTEGER
		do
			from i := 1 until i > view.count or Result > 0 loop
				if view.i_th (i) = a_model then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= view.count
		end

	set_column_editor (a_column, a_kind: INTEGER)
			-- Column `a_column' is edited as `a_kind': 0 none, 1 text, 2 check (the cell reads "1" or
			-- "0"), 3 choice (see `set_column_choices').
		require
			column_known: a_column >= 1 and a_column <= columns.count
			kind_known: a_kind >= Edit_none and a_kind <= Edit_choice
		do
			if is_editing and then editing_column = a_column then
				cancel_edit
			end
			if a_kind = Edit_none then
				edit_kinds.remove (a_column)
			else
				edit_kinds.force (a_kind, a_column)
			end
		ensure
			set: column_editor (a_column) = a_kind
		end

	set_column_choices (a_column: INTEGER; a_choices: ARRAY [STRING_32])
			-- The options a choice column offers.
		require
			column_known: a_column >= 1 and a_column <= columns.count
		do
			edit_choices.force (a_choices.twin, a_column)
		ensure
			set: column_choices (a_column).count = a_choices.count
		end

	set_on_cell_edit (a_action: detachable FUNCTION [INTEGER, INTEGER, STRING_32, detachable STRING_32])
		do
			on_cell_edit := a_action
		ensure
			set: on_cell_edit = a_action
		end

	set_holds_edits (a_on: BOOLEAN)
			-- Keep accepted texts in the grid (the default), or leave them to the program's own rows.
		do
			edits_not_held := not a_on
			if a_on = False then
				edited.wipe_out
			end
		ensure
			set: holds_edits = a_on
		end

	forget_edits
			-- Drop every text the grid holds for an accepted edit: the cells show their source again.
		do
			edited.wipe_out
		end

	edit_cell (a_model, a_column: INTEGER)
			-- Start editing the cell: a text cell opens its editor with the text selected, a check
			-- cell toggles, a choice cell offers its options. Clears the note.
		require
			column_known: a_column >= 1 and a_column <= columns.count
			row_known: a_model >= 1 and a_model <= rows.count
			shown: view_position_of (a_model) > 0
			editable: column_editor (a_column) /= Edit_none
		do
			begin_edit (a_model, a_column)
		end

	commit_edit
			-- Return in the editor, or leaving it: the text goes through `on_cell_edit'.
		local
			l_model, l_column: INTEGER
			l_text: STRING_32
		do
			if attached editor as al_editor and then is_editing then
				l_model := editing_model
				l_column := editing_column
				l_text := al_editor.text.twin
				close_editor
				submit_edit (l_model, l_column, l_text)
			end
		ensure
			closed: not is_editing
		end

	cancel_edit
			-- Escape in the editor: nothing changes.
		do
			close_editor
		ensure
			closed: not is_editing
		end

	set_shown_models (a_models: detachable ARRAY [INTEGER])
			-- Show only the model rows named in `a_models' (that also pass the filter); Void shows
			-- every row. Row numbers stay the model's. A selected row this hides is deselected and
			-- `on_select' hears 0; it is not selected again when the set widens.
		local
			l_was: INTEGER
			l_set: HASH_TABLE [BOOLEAN, INTEGER]
		do
			if attached a_models as al_models then
				create l_set.make (al_models.count)
				across al_models as ic loop
					l_set.force (True, ic)
				end
				shown_set := l_set
			else
				shown_set := Void
			end
			l_was := selected_model
			rebuild_view
			if l_was > 0 and then selected_model = 0 and then attached on_select as al_select then
				al_select.call (0)
			end
		ensure
			within_rows: view.count <= rows.count
		end

feature -- Test hooks (what the user's hand does)

	edit_cell_by_user (a_model, a_column: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- As the user typing `a_text' and pressing Return (a text cell), clicking a check to that
			-- value, or choosing that option: the edit commits through `on_cell_edit'.
		require
			column_known: a_column >= 1 and a_column <= columns.count
			row_known: a_model >= 1 and a_model <= rows.count
			shown: view_position_of (a_model) > 0
			editable: column_editor (a_column) /= Edit_none
		do
			if column_editor (a_column) = Edit_text then
				begin_edit (a_model, a_column)
				if attached editor as al_editor then
					al_editor.set_text (a_text)
				end
				handle_char (13)
			else
				cell_note.wipe_out
				note_model := 0
				submit_edit (a_model, a_column, a_text.to_string_32)
			end
		ensure
			closed: not is_editing
		end

	cancel_edit_by_user (a_model, a_column: INTEGER)
			-- As the user opening a text cell and pressing Escape: nothing changes.
		require
			column_known: a_column >= 1 and a_column <= columns.count
			row_known: a_model >= 1 and a_model <= rows.count
			shown: view_position_of (a_model) > 0
			editable_text: column_editor (a_column) = Edit_text
		do
			begin_edit (a_model, a_column)
			handle_char (27)
		ensure
			closed: not is_editing
		end

feature {NONE} -- Cell editing

	shown_set: detachable HASH_TABLE [BOOLEAN, INTEGER]
			-- The model rows `set_shown_models' allows; Void: all.

	edit_kinds: HASH_TABLE [INTEGER, INTEGER]
			-- Each editable column's kind.
		attribute
			create Result.make (4)
		end

	edit_choices: HASH_TABLE [ARRAY [STRING_32], INTEGER]
		attribute
			create Result.make (4)
		end

	edited: HASH_TABLE [STRING_32, INTEGER_64]
			-- The accepted edits, by `edit_key': what a cell shows in place of its source's text.
		attribute
			create Result.make (8)
		end

	edits_not_held: BOOLEAN

	editor: detachable SW_TEXT_BOX
			-- The box over the cell being edited.

	note_model, note_column: INTEGER
			-- The cell the note hangs under.

	swallow_return_char: BOOLEAN
			-- Did a Return key just act, so the Return character that follows it must not?

	edit_key (a_model, a_column: INTEGER): INTEGER_64
		do
			Result := a_model.to_integer_64 * 65_536 + a_column
		end

	begin_edit (a_model, a_column: INTEGER)
			-- The cell's own gesture; the note of the last refusal goes.
		local
			l_kind, l_pos: INTEGER
			l_menu: SW_MENU
			l_choices: ARRAY [STRING_32]
			i: INTEGER
		do
			if is_editing then
				commit_edit
			end
			cell_note.wipe_out
			note_model := 0
			l_kind := column_editor (a_column)
			l_pos := view_position_of (a_model)
			if l_pos > 0 then
				select_model_row (a_model)
				scroll_to_position (l_pos)
				inspect l_kind
				when Edit_text then
					create editor.make_single_line (cell_text (a_model, a_column))
					editing_model := a_model
					editing_column := a_column
					place_editor
					if attached editor as al_editor then
						al_editor.set_focused (True)
						al_editor.select_all
					end
				when Edit_check then
					if cell_text (a_model, a_column).same_string ("1") then
						submit_edit (a_model, a_column, "0")
					else
						submit_edit (a_model, a_column, "1")
					end
				when Edit_choice then
					l_choices := column_choices (a_column)
					if not l_choices.is_empty then
						create l_menu.make
						from i := l_choices.lower until i > l_choices.upper loop
							l_menu.add_item (l_choices [i], "", True, agent choose_cell (a_model, a_column, l_choices [i]))
							i := i + 1
						end
						pending_menu := l_menu
						menu_cell_column := a_column
						menu_cell_model := a_model
					end
				else
				end
			end
		end

	choose_cell (a_model, a_column: INTEGER; a_text: STRING_32)
			-- A choice picked from the dropdown commits at once.
		do
			submit_edit (a_model, a_column, a_text)
		end

	close_editor
		do
			if attached editor as al_editor then
				al_editor.set_focused (False)
			end
			editor := Void
			editing_model := 0
			editing_column := 0
		ensure
			closed: not is_editing
		end

	submit_edit (a_model, a_column: INTEGER; a_text: STRING_32)
			-- The new text goes to `on_cell_edit'; accepted, the grid shows it; refused, the cell
			-- keeps its text and the message hangs under it.
		local
			l_answer: detachable STRING_32
		do
			if not a_text.same_string (cell_text (a_model, a_column)) then
				if attached on_cell_edit as al_edit then
					l_answer := al_edit.item ([a_model, a_column, a_text])
				end
				if l_answer = Void or else l_answer.is_empty then
					if holds_edits then
						edited.force (a_text.twin, edit_key (a_model, a_column))
					end
				else
					cell_note := l_answer.twin
					note_model := a_model
					note_column := a_column
				end
			end
		end

	menu_cell_column, menu_cell_model: INTEGER
			-- The cell the dropdown last offered was for.

	forget_row_edits (a_model: INTEGER)
			-- A row the program replaced shows its own texts again.
		local
			c: INTEGER
		do
			if not edited.is_empty then
				from c := 1 until c > columns.count loop
					edited.remove (edit_key (a_model, c))
					c := c + 1
				end
			end
		end

	cell_left_of (a_column: INTEGER): REAL_64
			-- Left edge of column `a_column' on screen.
		require
			column_known: a_column >= 1 and a_column <= columns.count
		do
			Result := column_lefts.i_th (a_column)
		end

	cell_top_of (a_model: INTEGER): REAL_64
			-- Top edge of model row `a_model' on screen (the view position's row).
		do
			Result := y + Header_h + (view_position_of (a_model) - 1) * Row_h - scroll_y
		end

	place_editor
			-- The editor sits over its cell.
		do
			if attached editor as al_editor and then is_editing then
				al_editor.set_bounds (cell_left_of (editing_column) + 1.0, cell_top_of (editing_model),
					shown_width (editing_column) - 2.0, Row_h)
			end
		end

	first_editable_column: INTEGER
			-- The first column with an editor; 0 for none.
		local
			c: INTEGER
		do
			from c := 1 until c > columns.count or Result > 0 loop
				if column_editor (c) /= Edit_none then
					Result := c
				end
				c := c + 1
			end
		end

	begin_edit_selected: BOOLEAN
			-- F2 or Return on the selected row: its first editable column starts. True when one did.
		local
			l_column: INTEGER
		do
			l_column := first_editable_column
			if selected_model > 0 and then l_column > 0 and then view_position_of (selected_model) > 0 then
				begin_edit (selected_model, l_column)
				Result := True
			end
		end

	draw_editing (a_p: SW_PAINTER)
			-- The editor over its cell, and the note of a refusal under its cell.
		local
			t: SW_THEME
			l_pos: INTEGER
			l_w, l_x, l_y: REAL_64
		do
			t := a_p.theme
			if attached editor as al_editor and then is_editing then
				place_editor
				al_editor.draw (a_p)
			end
			if not cell_note.is_empty and then note_model > 0 and then note_column >= 1 and then note_column <= columns.count then
				l_pos := view_position_of (note_model)
				if l_pos > 0 then
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
					l_w := (a_p.advance (cell_note) + 12.0).max (shown_width (note_column))
					l_x := cell_left_of (note_column)
					l_y := cell_top_of (note_model) + Row_h
					a_p.set_color (t.wash_danger)
					a_p.rrect_fill (l_x, l_y, l_w, 20.0, 3.0)
					a_p.set_color (t.ink_danger)
					a_p.text (l_x + 6.0, l_y + 15.0, cell_note)
				end
			end
		end

	draw_check_box (a_p: SW_PAINTER; a_cx, a_cy: REAL_64; a_on: BOOLEAN)
			-- A check cell's box, ticked or not.
		local
			t: SW_THEME
		do
			t := a_p.theme
			if a_on then
				a_p.set_color (t.accent)
				a_p.rrect_fill (a_cx - 7.0, a_cy - 7.0, 14.0, 14.0, 3.0)
				a_p.set_color (t.ink_on_accent)
				a_p.glyph ({SW_PAINTER}.Glyph_check, a_cx, a_cy, 10.0)
			else
				a_p.set_color (t.outline)
				a_p.rrect_stroke (a_cx - 6.5, a_cy - 6.5, 13.0, 13.0, 3.0)
			end
		end

feature {NONE} -- Engine

	resizing_column: INTEGER
			-- The column being width-dragged; 0 when idle.

	key_less (a_keys: SPECIAL [detachable COMPARABLE]; a_mi, b_mi: INTEGER): BOOLEAN
			-- Does model row `a_mi' order strictly before `b_mi' by the keys
			-- in `a_keys' (indexed by model row) and the current direction?
			-- Strict BOTH ways, so equal keys never reorder (stability).
		do
			if attached a_keys [a_mi] as al_a and then attached a_keys [b_mi] as al_b then
				if is_descending then
					Result := al_b < al_a
				else
					Result := al_a < al_b
				end
			end
		end

	pin_view
			-- The pinned rows first, each part keeping its order (a stable partition).
		local
			l_first, l_rest: ARRAYED_LIST [INTEGER]
		do
			create l_first.make (8)
			create l_rest.make (view.count)
			across view as ic loop
				if is_pinned (rows.i_th (ic)) then
					l_first.extend (ic)
				else
					l_rest.extend (ic)
				end
			end
			view.wipe_out
			view.append (l_first)
			view.append (l_rest)
		ensure
			same_rows: view.count = old view.count
		end

	shown_sort_column: INTEGER
			-- The column whose header shows the arrow: the indicator in report mode, else the sort.
		do
			if on_header_click /= Void then
				Result := indicator_column
			else
				Result := sort_column
			end
		end

	shown_descending: BOOLEAN
		do
			if on_header_click /= Void then
				Result := indicator_descending
			else
				Result := is_descending
			end
		end

	toggle_extra (a_model: INTEGER)
			-- Ctrl+click in multiple mode: add `a_model' to the selection or take it out.
		do
			if selected_model = 0 then
				select_model_row (a_model)
			elseif a_model = selected_model then
				if also_selected.is_empty then
					selected_model := 0
				else
					selected_model := also_selected.first
					also_selected.start
					also_selected.remove
				end
				if attached on_select as al_s then
					al_s.call (a_model)
				end
			elseif also_selected.has (a_model) then
				also_selected.prune_all (a_model)
				if attached on_select as al_s then
					al_s.call (a_model)
				end
			else
				also_selected.extend (a_model)
				if attached on_select as al_s then
					al_s.call (a_model)
				end
			end
		end

	merge_sort_view
			-- Stable bottom-up merge over the view's model indices:
			-- O(n log n) for the thousands the virtualized DRAW
			-- already handles, and equal keys keep model order in
			-- BOTH directions (the descending insertion sort swapped
			-- them - caught by a failing assault, 2026-08-23).
			-- GW-29: each row's key is asked for ONCE, before the merge, not
			-- twice a comparison - 100,000 rows made 3.4 million agent calls;
			-- and the merge runs over SPECIAL arrays, not list calls.
		require
			sorting: sort_column >= 1 and sort_column <= columns.count
		local
			src, dst, swp: SPECIAL [INTEGER]
			n, stride, lo, mid, hi, a, b, w: INTEGER
			l_keys: SPECIAL [detachable COMPARABLE]
			l_column: SW_GRID_COLUMN [G]
		do
			l_column := columns.i_th (sort_column)
			n := view.count
			create l_keys.make_filled (Void, rows.count + 1)
			create src.make_filled (0, n)
			create dst.make_filled (0, n)
			from w := 0 until w >= n loop
				src [w] := view.i_th (w + 1)
					-- A fresh copy of each key: the copies lie together, so the merge reads
					-- compact memory however scattered the rows' own strings are (a long-
					-- running heap made the same sort six times slower, GW-29 on macOS).
				l_keys [src [w]] := l_column.sort_key (rows.i_th (src [w])).twin
				w := w + 1
			end
			from
				stride := 1
			until
				stride >= n
			loop
				from
					lo := 0
				until
					lo >= n
				loop
					mid := (lo + stride).min (n)
					hi := (lo + 2 * stride).min (n)
					a := lo
					b := mid
					from w := lo until w >= hi loop
						if b >= hi or else (a < mid and then not key_less (l_keys, src [b], src [a])) then
							dst [w] := src [a]
							a := a + 1
						else
							dst [w] := src [b]
							b := b + 1
						end
						w := w + 1
					end
					lo := lo + 2 * stride
				end
				swp := src
				src := dst
				dst := swp
				stride := stride * 2
			end
			view.wipe_out
			from w := 0 until w >= n loop
				view.extend (src [w])
				w := w + 1
			end
		ensure
			same_rows: view.count = old view.count
		end

	page_stride: INTEGER
			-- Rows one PgUp/PgDn covers: the live viewport when laid
			-- out, the declared viewport before.
		local
			vh: REAL_64
		do
			vh := height - Header_h
			if vh <= 0.0 then
				vh := viewport_height
			end
			Result := (vh / Row_h).truncated_to_integer.max (1)
		end

	selected_view_position: INTEGER
			-- Where the selected model row sits in the view; 0 when
			-- unselected or filtered out.
		local
			i: INTEGER
		do
			if selected_model > 0 then
				from
					i := 1
				until
					i > view.count or Result > 0
				loop
					if view.i_th (i) = selected_model then
						Result := i
					end
					i := i + 1
				end
			end
		end

	scroll_selection_into_view
		local
			pos: INTEGER
		do
			pos := selected_view_position
			if pos > 0 then
				if (pos - 1) * Row_h < scroll_y then
					scroll_y := (pos - 1) * Row_h
				elseif pos * Row_h > scroll_y + height - Header_h then
					scroll_y := pos * Row_h - (height - Header_h)
				end
			end
		end

	rebuild_view
			-- Filter, then sort; the selection's OBJECT survives when
			-- it survives the filter.
		local
			i: INTEGER
		do
			view.wipe_out
			from
				i := 1
			until
				i > rows.count
			loop
				if passes (i, rows.i_th (i)) then
					view.extend (i)
				end
				i := i + 1
			end
			if sort_column >= 1 and sort_column <= columns.count then
				merge_sort_view
			end
			if pinned /= Void then
				pin_view
			end
			if selected_model > 0 and then selected_view_position = 0 then
				selected_model := 0
			end
			if is_editing and then view_position_of (editing_model) = 0 then
				cancel_edit
			end
			scroll_y := scroll_y.max (0.0)
			sync_bar
		ensure
			view_within_rows: view.count <= rows.count
		end

	sync_bar
			-- Tell the bar how much the rows show of how much there is.
		do
			bar.set_extent ((height - Header_h).max (0.0), view.count * Row_h)
		end


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_data_grid
		end

	accessible_item_count: INTEGER
			-- The column headers, then the rows in view order, up to the block's size.
		do
			Result := (columns.count + view.count).min (2_047)
		end

	publish_accessible_items (a_accessibility: SW_ACCESSIBILITY)
			-- Each column header ("column-header: Book"), then each row, named by its cells.
		local
			i, k, c: INTEGER
			l_name: STRING_32
			cx: REAL_64
		do
			cx := x - scroll_x
			from
				c := 1
			until
				c > columns.count or k >= accessible_item_count
			loop
				k := k + 1
				a_accessibility.add_node (accessible_item_id (k), accessible_node_id, {SW_ACCESSIBILITY}.Role_header_item,
					columns.i_th (c).title, Void, cx, y, shown_width (c), Header_h, False, is_enabled)
				cx := cx + shown_width (c)
				c := c + 1
			end
			from
				i := 1
			until
				i > view.count or k >= accessible_item_count
			loop
				k := k + 1
				create l_name.make (32)
				from
					c := 1
				until
					c > columns.count
				loop
					if c > 1 then
						l_name.append_character (' ')
					end
					l_name.append (cell_text (view.i_th (i), c))
					c := c + 1
				end
				a_accessibility.add_node (accessible_item_id (k), accessible_node_id, {SW_ACCESSIBILITY}.Role_data_item,
					l_name, Void, x, y + Header_h + (i - 1) * Row_h - scroll_y, width, Row_h, False, is_enabled)
				i := i + 1
			end
		end

invariant
	rows_attached: rows /= Void and columns /= Void and view /= Void
	view_never_exceeds_rows: view.count <= rows.count
	sort_in_range: sort_column >= 0 and sort_column <= columns.count
	selection_in_model: selected_model >= 0 and selected_model <= rows.count
	editing_a_known_cell: is_editing implies (editing_model >= 1 and editing_model <= rows.count and editing_column >= 1 and editing_column <= columns.count)
	context_in_model: context_model >= 0 and context_model <= rows.count

end
