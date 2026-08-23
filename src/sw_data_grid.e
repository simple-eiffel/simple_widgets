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

class
	SW_DATA_GRID [G]

inherit
	SW_WIDGET
		redefine
			handle_click, handle_double_click, handle_drag, handle_wheel,
			handle_key, wants_hover_point, accepts_focus
		end

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

	on_activate: detachable PROCEDURE [INTEGER]
			-- Fired with the MODEL index on double-click.

	filter: detachable FUNCTION [G, BOOLEAN]

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
		do
			rows := a_rows
			if selected_model > rows.count then
				selected_model := 0
			end
			rebuild_view
		ensure
			kept: rows = a_rows
		end

	add_row (a_row: G)
		do
			rows.extend (a_row)
			rebuild_view
		ensure
			grew: rows.count = old rows.count + 1
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
			-- Which column's right divider the point is within 5px
			-- of; 0 for none.
		local
			cx: REAL_64
			i: INTEGER
		do
			cx := x - scroll_x
			from
				i := 1
			until
				i > columns.count or Result > 0
			loop
				cx := cx + columns.i_th (i).width
				if (a_px - cx).abs <= 5.0 then
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
			cx: REAL_64
			i: INTEGER
		do
			cx := x - scroll_x
			from
				i := 1
			until
				i > columns.count or Result > 0
			loop
				if a_px >= cx and a_px < cx + columns.i_th (i).width then
					Result := i
				end
				cx := cx + columns.i_th (i).width
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
			ry, cx: REAL_64
			col: SW_GRID_COLUMN [G]
			s: STRING_32
		do
			t := a_p.theme
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
					if view.i_th (i) = selected_model then
						a_p.set_color (t.wash_accent)
						a_p.fill_rect (x, ry, width, Row_h)
					elseif i \\ 2 = 0 then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x, ry, width, Row_h)
					end
					cx := x - scroll_x
					from
						ci := 1
					until
						ci > columns.count
					loop
						col := columns.i_th (ci)
						s := col.value.item ([rows.i_th (view.i_th (i))])
						a_p.push_clip (cx + 1.0, ry, col.width - 2.0, Row_h)
						a_p.set_color (t.ink)
						a_p.text (cx + 8.0, ry + Row_h - 8.0, s)
						a_p.pop_clip
						cx := cx + col.width
						ci := ci + 1
					end
					i := i + 1
				end
			end
				-- frozen header
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, Header_h)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
			cx := x - scroll_x
			from
				ci := 1
			until
				ci > columns.count
			loop
				col := columns.i_th (ci)
				a_p.push_clip (cx + 1.0, y, col.width - 2.0, Header_h)
				a_p.set_color (t.ink)
				a_p.text (cx + 8.0, y + Header_h - 10.0, col.title)
				if ci = sort_column then
					a_p.set_color (t.accent)
					if is_descending then
						a_p.line (cx + col.width - 20.0, y + 12.0, cx + col.width - 15.0, y + 19.0, 1.8)
						a_p.line (cx + col.width - 15.0, y + 19.0, cx + col.width - 10.0, y + 12.0, 1.8)
					else
						a_p.line (cx + col.width - 20.0, y + 19.0, cx + col.width - 15.0, y + 12.0, 1.8)
						a_p.line (cx + col.width - 15.0, y + 12.0, cx + col.width - 10.0, y + 19.0, 1.8)
					end
				end
				a_p.pop_clip
				cx := cx + col.width
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
			if view.count * Row_h > height - Header_h then
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + width - 9.0, y + Header_h + 2.0, 7.0, height - Header_h - 4.0, 3.0)
				a_p.set_color (t.outline)
				a_p.rrect_fill (x + width - 8.0,
					y + Header_h + 2.0 + (scroll_y / (view.count * Row_h)) * (height - Header_h - 4.0),
					5.0,
					(((height - Header_h) / (view.count * Row_h)) * (height - Header_h - 4.0)).max (20.0),
					2.5)
			end
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			edge, hc, vr: INTEGER
		do
			if is_enabled then
				if a_py < y + Header_h then
					edge := column_edge_at (a_px)
					if edge > 0 then
						resizing_column := edge
					else
						hc := header_column_at (a_px)
						if hc > 0 then
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
					vr := view_row_at (a_py)
					if vr > 0 then
						select_model_row (view.i_th (vr))
					end
				end
				Result := True
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		local
			vr: INTEGER
		do
			if is_enabled then
				vr := view_row_at (a_py)
				if vr > 0 then
					select_model_row (view.i_th (vr))
					if attached on_activate as act then
						act.call (view.i_th (vr))
					end
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		local
			cx: REAL_64
			i: INTEGER
		do
			if resizing_column >= 1 and resizing_column <= columns.count then
				cx := x - scroll_x
				from
					i := 1
				until
					i >= resizing_column
				loop
					cx := cx + columns.i_th (i).width
					i := i + 1
				end
				columns.i_th (resizing_column).set_width (a_px - cx)
			end
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
				scroll_y := (scroll_y - a_delta / 120.0 * Row_h * 3.0)
					.max (0.0).min (((view.count * Row_h) - (height - Header_h)).max (0.0))
			end
			Result := True
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
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

feature {NONE} -- Engine

	resizing_column: INTEGER
			-- The column being width-dragged; 0 when idle.

	view_less (a_mi, b_mi: INTEGER): BOOLEAN
			-- Does model row `a_mi' order strictly before `b_mi'
			-- under the current column and direction? Strict BOTH
			-- ways, so equal keys never reorder (stability).
		require
			sorting: sort_column >= 1 and sort_column <= columns.count
		do
			if is_descending then
				Result := columns.i_th (sort_column).row_less
					(rows.i_th (b_mi), rows.i_th (a_mi))
			else
				Result := columns.i_th (sort_column).row_less
					(rows.i_th (a_mi), rows.i_th (b_mi))
			end
		end

	merge_sort_view
			-- Stable bottom-up merge over the view's model indices:
			-- O(n log n) for the thousands the virtualized DRAW
			-- already handles, and equal keys keep model order in
			-- BOTH directions (the descending insertion sort swapped
			-- them - caught by a failing assault, 2026-08-23).
		local
			src, dst, swp: ARRAYED_LIST [INTEGER]
			stride, lo, mid, hi, a, b: INTEGER
		do
			src := view.twin
			dst := view.twin
			from
				stride := 1
			until
				stride >= src.count
			loop
				from
					lo := 1
				until
					lo > src.count
				loop
					mid := (lo + stride - 1).min (src.count)
					hi := (lo + 2 * stride - 1).min (src.count)
					a := lo
					b := mid + 1
					across
						lo |..| hi as w
					loop
						if b > hi or else (a <= mid and then not view_less (src.i_th (b), src.i_th (a))) then
							dst.put_i_th (src.i_th (a), w)
							a := a + 1
						else
							dst.put_i_th (src.i_th (b), w)
							b := b + 1
						end
					end
					lo := lo + 2 * stride
				end
				swp := src
				src := dst
				dst := swp
				stride := stride * 2
			end
			view.wipe_out
			across
				src as mi
			loop
				view.extend (mi)
			end
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
				if attached filter as f then
					if f.item ([rows.i_th (i)]) then
						view.extend (i)
					end
				else
					view.extend (i)
				end
				i := i + 1
			end
			if sort_column >= 1 and sort_column <= columns.count then
				merge_sort_view
			end
			if selected_model > 0 and then selected_view_position = 0 then
				selected_model := 0
			end
			scroll_y := scroll_y.max (0.0)
		ensure
			view_within_rows: view.count <= rows.count
		end

invariant
	rows_attached: rows /= Void and columns /= Void and view /= Void
	view_never_exceeds_rows: view.count <= rows.count
	sort_in_range: sort_column >= 0 and sort_column <= columns.count
	selection_in_model: selected_model >= 0 and selected_model <= rows.count

end
