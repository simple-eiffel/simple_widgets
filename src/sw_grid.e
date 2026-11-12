note
	description: "[
		Widgets in rows and columns (W4a, simple_gui's GUI_GRID on Windows). Rows and
		columns are 1-based. A column is as wide as its widest single-column child, a row
		as tall as its tallest single-row child; a spanning child covers its cells but does
		not size them, and is clipped to them. Children fill their cells. Gaps default to
		the theme's padding and sit only between occupied lines: a row or column nothing
		covers has no size and no gaps (as GtkGrid). With homogeneous columns every column
		takes the widest width and they share the spare width; homogeneous takes precedence
		over a stretching column, which otherwise takes the spare width. `padding' (0 unless
		set) is kept clear inside the grid's edges.
	]"

class
	SW_GRID

inherit
	SW_WIDGET
		redefine
			sub_widgets, preferred_width, arrange, widget_at, shows_style
		end

	SW_PADDED

create
	make

feature {NONE} -- Initialization

	make
			-- An empty grid.
		do
			create cells.make (8)
			create children.make (8)
		ensure
			empty: children.is_empty
		end

feature -- Access

	children: ARRAYED_LIST [SW_WIDGET]
			-- The widgets, in the order they were put.

	column_count: INTEGER
			-- Columns used: the furthest right edge of any cell.
		do
			across cells as ic loop
				Result := Result.max (ic.column + ic.columns - 1)
			end
		end

	row_count: INTEGER
			-- Rows used: the lowest edge of any cell.
		do
			across cells as ic loop
				Result := Result.max (ic.row + ic.rows - 1)
			end
		end

	has_homogeneous_columns: BOOLEAN
			-- Do all columns take the widest width?

	stretching_column: INTEGER
			-- The column that takes the spare width (0: none).

	row_gap, column_gap: REAL_64
			-- Explicit gaps (used when `gaps_are_explicit').

	gaps_are_explicit: BOOLEAN

feature -- Element change

	put (a_widget: SW_WIDGET; a_row, a_column: INTEGER)
			-- Place `a_widget' in one cell.
		require
			cell: a_row >= 1 and a_column >= 1
			not_here: not children.has (a_widget)
		do
			put_spanning (a_widget, a_row, a_column, 1, 1)
		ensure
			adopted: a_widget.parent = Current
		end

	put_spanning (a_widget: SW_WIDGET; a_row, a_column, a_rows, a_columns: INTEGER)
			-- Place `a_widget' over `a_rows' by `a_columns' cells.
		require
			cell: a_row >= 1 and a_column >= 1
			span: a_rows >= 1 and a_columns >= 1
			not_here: not children.has (a_widget)
		do
			cells.extend ([a_widget, a_row, a_column, a_rows, a_columns])
			children.extend (a_widget)
			a_widget.set_parent (Current)
		ensure
			adopted: a_widget.parent = Current
			one_more: children.count = old children.count + 1
		end

	set_homogeneous_columns (a_on: BOOLEAN)
		do
			has_homogeneous_columns := a_on
		ensure
			set: has_homogeneous_columns = a_on
		end

	set_stretching_column (a_column: INTEGER)
		require
			non_negative: a_column >= 0
		do
			stretching_column := a_column
		ensure
			set: stretching_column = a_column
		end

	set_gaps (a_row_gap, a_column_gap: REAL_64)
		require
			non_negative: a_row_gap >= 0.0 and a_column_gap >= 0.0
		do
			row_gap := a_row_gap
			column_gap := a_column_gap
			gaps_are_explicit := True
		ensure
			set: gaps_are_explicit and row_gap = a_row_gap and column_gap = a_column_gap
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- The natural column widths plus the gaps.
		local
			l_widths: ARRAYED_LIST [REAL_64]
		do
			l_widths := natural_widths (a_p)
			across l_widths as ic loop
				Result := Result + ic
			end
			Result := framed_width (Result + gaps_total (occupied (True), effective_column_gap (a_p)))
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The row heights at `a_width' plus the gaps.
		local
			l_heights: ARRAYED_LIST [REAL_64]
		do
			l_heights := row_heights (a_p, column_widths (a_p, unframed_width (a_width)))
			across l_heights as ic loop
				Result := Result + ic
			end
			Result := framed_height (Result + gaps_total (occupied (False), effective_row_gap (a_p)))
		end

	arrange (a_p: SW_PAINTER)
			-- Size the columns to `width', the rows to their content, and place every cell,
			-- inside the padding.
		do
			lay_out_within_frame (agent arrange_cells (a_p))
		end

	arrange_cells (a_p: SW_PAINTER)
		local
			l_widths, l_heights, l_x, l_y: ARRAYED_LIST [REAL_64]
			l_cg, l_rg, l_w, l_h: REAL_64
		do
			l_cg := effective_column_gap (a_p)
			l_rg := effective_row_gap (a_p)
			l_widths := column_widths (a_p, width)
			l_heights := row_heights (a_p, l_widths)
			l_x := starts (x, l_widths, occupied (True), l_cg)
			l_y := starts (y, l_heights, occupied (False), l_rg)
			across cells as ic loop
				if ic.widget.is_hidden then
					ic.widget.vanish
				else
					l_w := spanned (l_widths, ic.column, ic.columns, l_cg)
					l_h := spanned (l_heights, ic.row, ic.rows, l_rg)
					ic.widget.set_bounds (mirrored_x (l_x.i_th (ic.column), l_w), l_y.i_th (ic.row), l_w, l_h)
					ic.widget.arrange (a_p)
				end
			end
		end

feature -- Drawing

	shows_style (a_part: INTEGER): BOOLEAN
			-- The frame: background, padding, border, radius and shadow, around the children.
		do
			Result := is_frame_style_part (a_part)
		end

	draw (a_p: SW_PAINTER)
			-- Each shown child, clipped to its cells.
		do
			if attached style then
				draw_style_frame (a_p)
			end
			across children as ic loop
					-- a cell with no area draws nothing (and cairo refuses an empty clip)
				if not ic.is_hidden and ic.width > 0.0 and ic.height > 0.0 then
					a_p.push_clip (ic.x, ic.y, ic.width, ic.height)
					ic.paint (a_p)
					a_p.pop_clip
				end
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				across children as ic until Result /= Void loop
					if not ic.is_hidden then
						Result := ic.widget_at (a_px, a_py)
					end
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			Result := children
		end

feature {NONE} -- Implementation

	cells: ARRAYED_LIST [TUPLE [widget: SW_WIDGET; row, column, rows, columns: INTEGER]]

	effective_column_gap (a_p: SW_PAINTER): REAL_64
		do
			if gaps_are_explicit then
				Result := column_gap
			else
				Result := a_p.theme.padding
			end
		ensure
			non_negative: Result >= 0.0
		end

	effective_row_gap (a_p: SW_PAINTER): REAL_64
		do
			if gaps_are_explicit then
				Result := row_gap
			else
				Result := a_p.theme.padding
			end
		ensure
			non_negative: Result >= 0.0
		end

	natural_widths (a_p: SW_PAINTER): ARRAYED_LIST [REAL_64]
			-- Each column's widest single-column child; all the widest when homogeneous.
		local
			n, i: INTEGER
			l_widest: REAL_64
		do
			n := column_count
			create Result.make_filled (n)
			across cells as ic loop
				if ic.columns = 1 and not ic.widget.is_hidden then
					Result.put_i_th (Result.i_th (ic.column).max (ic.widget.clamped_width (ic.widget.preferred_width (a_p))), ic.column)
				end
			end
			if has_homogeneous_columns then
				across Result as ic loop
					l_widest := l_widest.max (ic)
				end
				from i := 1 until i > n loop
					Result.put_i_th (l_widest, i)
					i := i + 1
				end
			end
		ensure
			one_per_column: Result.count = column_count
		end

	column_widths (a_p: SW_PAINTER; a_width: REAL_64): ARRAYED_LIST [REAL_64]
			-- The natural widths, with the spare width of `a_width' given to the stretching
			-- column (or, when homogeneous, shared equally).
		local
			l_natural, l_spare: REAL_64
			n, i: INTEGER
			l_occupied: ARRAYED_LIST [BOOLEAN]
		do
			Result := natural_widths (a_p)
			l_occupied := occupied (True)
			n := Result.count
			across Result as ic loop
				l_natural := l_natural + ic
			end
			l_natural := l_natural + gaps_total (l_occupied, effective_column_gap (a_p))
			l_spare := a_width - l_natural
			if l_spare > 0.0 and n > 0 then
				if has_homogeneous_columns then
					from i := 1 until i > n loop
						Result.put_i_th (Result.i_th (i) + l_spare / n, i)
						i := i + 1
					end
				elseif stretching_column >= 1 and stretching_column <= n then
					Result.put_i_th (Result.i_th (stretching_column) + l_spare, stretching_column)
				end
			end
		ensure
			one_per_column: Result.count = column_count
		end

	row_heights (a_p: SW_PAINTER; a_widths: ARRAYED_LIST [REAL_64]): ARRAYED_LIST [REAL_64]
			-- Each row's tallest single-row child at its cell width.
		local
			l_cg: REAL_64
		do
			l_cg := effective_column_gap (a_p)
			create Result.make_filled (row_count)
			across cells as ic loop
				if ic.rows = 1 and not ic.widget.is_hidden then
					Result.put_i_th (Result.i_th (ic.row).max (ic.widget.clamped_height (
						ic.widget.preferred_height (a_p, spanned (a_widths, ic.column, ic.columns, l_cg)))), ic.row)
				end
			end
		ensure
			one_per_row: Result.count = row_count
		end

	starts (a_origin: REAL_64; a_sizes: ARRAYED_LIST [REAL_64]; a_occupied: ARRAYED_LIST [BOOLEAN];
			a_gap: REAL_64): ARRAYED_LIST [REAL_64]
			-- Where each column (or row) begins; an empty line adds no gap.
		require
			matched: a_occupied.count = a_sizes.count
		local
			l_at: REAL_64
			i: INTEGER
		do
			create Result.make (a_sizes.count)
			l_at := a_origin
			from i := 1 until i > a_sizes.count loop
				Result.extend (l_at)
				l_at := l_at + a_sizes.i_th (i)
				if a_occupied.i_th (i) then
					l_at := l_at + a_gap
				end
				i := i + 1
			end
		ensure
			one_each: Result.count = a_sizes.count
		end

	occupied (a_columns: BOOLEAN): ARRAYED_LIST [BOOLEAN]
			-- For each column (`a_columns') or row: does any shown cell cover it?
		local
			i, l_first, l_count: INTEGER
		do
			if a_columns then
				create Result.make_filled (column_count)
			else
				create Result.make_filled (row_count)
			end
			across cells as ic loop
				if ic.widget.is_hidden then
					l_count := 0
				elseif a_columns then
					l_first := ic.column
					l_count := ic.columns
				else
					l_first := ic.row
					l_count := ic.rows
				end
				from i := l_first until i > l_first + l_count - 1 loop
					Result.put_i_th (True, i)
					i := i + 1
				end
			end
		end

	gaps_total (a_occupied: ARRAYED_LIST [BOOLEAN]; a_gap: REAL_64): REAL_64
			-- The gaps between the occupied lines.
		local
			n: INTEGER
		do
			across a_occupied as ic loop
				if ic then
					n := n + 1
				end
			end
			if n > 1 then
				Result := a_gap * (n - 1)
			end
		ensure
			non_negative: Result >= 0.0
		end

	spanned (a_sizes: ARRAYED_LIST [REAL_64]; a_first, a_count: INTEGER; a_gap: REAL_64): REAL_64
			-- The size of `a_count' columns (or rows) from `a_first', with the gaps between them.
		require
			first: a_first >= 1
			count: a_count >= 1
			inside: a_first + a_count - 1 <= a_sizes.count
		local
			i: INTEGER
		do
			from i := a_first until i > a_first + a_count - 1 loop
				Result := Result + a_sizes.i_th (i)
				i := i + 1
			end
			Result := Result + a_gap * (a_count - 1)
		ensure
			non_negative: Result >= 0.0
		end

invariant
	children_exist: children /= Void
	cells_exist: cells /= Void
	one_cell_each: cells.count = children.count
	stretching_non_negative: stretching_column >= 0

end
