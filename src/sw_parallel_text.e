note
	description: "[
		Versions side by side, verse by verse (GW-06): rows are canonical
		verses, columns are versions (up to six), and every cell is wrapped,
		shaped text of its own direction and face. A row is as tall as its
		tallest cell, and there is one scroll. The column titles stay put
		above the rows. A note row - one muted line across every column -
		stands where the versification map paired unequal numbers ("LXX 9 =
		MT 9-10"). simple_bible's Parallel tab (A02), its word diff (A04)
		and They Chose (I-P06) are built on it.

		CELLS are simple_document DOC_TEXTs (bold, italic, small capitals,
		superscript Strong's numbers, links) with their own SW_MARKED_TEXT:
		an SW_MARK_LEGEND turns reasons into looks ("agrees with LXX",
		"differs from KJV") with text labels, never colour alone.

		WHAT IT IS MADE OF: SW_DOC_UNITS (pointing, scrolling, the stack and
		the selection, joined once; each cell is a unit with its box) - one
		parent. Cells of one row copy tab-separated, rows line by line.
		`cell_at' says which verse and version is under a point;
		`on_cell_click' hears a click on a cell; hover cards come through
		`set_hover_card_builder' (map the unit with `unit_block' and
		`unit_column').

		COLUMNS: `add_column' (before any row), `set_column_weight' (share
		of the width), `set_column_scale' (a Hebrew column set larger),
		`set_column_alignment' (Align_start by default: a Hebrew cell sits
		flush right, an English one flush left).

		SPACING FROM THE THEME: the page inset is `border_width', columns
		are `padding' apart, a cell is padded half the `padding' above and
		below, the label gutter is the widest label plus `padding', and the
		title band is the measured label font plus `padding'.
	]"
	author: "Larry Rix"

class
	SW_PARALLEL_TEXT

inherit
	SW_DOC_UNITS
		redefine
			arrange, handle_wheel, handle_click, handle_double_click, handle_drag,
			handle_release, handle_key, handle_char, cursor_kind, set_hover_point, set_hovered
		end

	SW_MARK_HOST

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
			-- No columns, no rows, `a_viewport_height' tall.
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			create titles.make (Max_columns)
			create weights.make (Max_columns)
			create scales.make (Max_columns)
			create alignments.make (Max_columns)
			create rows.make (64)
			create column_lefts.make (Max_columns)
			create column_widths.make (Max_columns)
			laid_rows_revision := -1
			laid_px := 14
			init_pointing
		ensure
			kept: viewport_height = a_viewport_height
			empty: column_count = 0 and row_count = 0
		end

feature -- Constants

	Max_columns: INTEGER = 6

feature -- Columns

	column_count: INTEGER
		do
			Result := titles.count
		end

	column_title (a_column: INTEGER): STRING_32
		require
			valid: a_column >= 1 and a_column <= column_count
		do
			Result := titles.i_th (a_column)
		end

	column_weight (a_column: INTEGER): REAL_64
			-- The column's share of the width (1.0 by default).
		require
			valid: a_column >= 1 and a_column <= column_count
		do
			Result := weights.i_th (a_column)
		end

	column_scale (a_column: INTEGER): REAL_64
			-- The column's text size, of the body size (1.0 by default).
		require
			valid: a_column >= 1 and a_column <= column_count
		do
			Result := scales.i_th (a_column)
		end

	column_alignment (a_column: INTEGER): INTEGER
		require
			valid: a_column >= 1 and a_column <= column_count
		do
			Result := alignments.i_th (a_column)
		end

	add_column (a_title: READABLE_STRING_GENERAL): INTEGER
			-- A version column titled `a_title'; its number.
		require
			before_rows: row_count = 0
			room: column_count < Max_columns
		do
			titles.extend (a_title.to_string_32)
			weights.extend (1.0)
			scales.extend (1.0)
			alignments.extend ({SHAPING_CONSTANTS}.Align_start)
			Result := column_count
			rows_revision := rows_revision + 1
		ensure
			one_more: column_count = old column_count + 1
			numbered: Result = column_count
		end

	set_column_weight (a_column: INTEGER; a_weight: REAL_64)
		require
			valid: a_column >= 1 and a_column <= column_count
			positive: a_weight > 0.0
		do
			weights.put_i_th (a_weight, a_column)
			rows_revision := rows_revision + 1
		ensure
			set: column_weight (a_column) = a_weight
		end

	set_column_scale (a_column: INTEGER; a_scale: REAL_64)
		require
			valid: a_column >= 1 and a_column <= column_count
			sensible: a_scale >= 0.5 and a_scale <= 3.0
		do
			scales.put_i_th (a_scale, a_column)
			rows_revision := rows_revision + 1
		ensure
			set: column_scale (a_column) = a_scale
		end

	set_column_alignment (a_column, a_alignment: INTEGER)
		require
			valid: a_column >= 1 and a_column <= column_count
			alignment_valid: a_alignment >= {SHAPING_CONSTANTS}.Align_start
				and a_alignment <= {SHAPING_CONSTANTS}.Align_center
		do
			alignments.put_i_th (a_alignment, a_column)
			rows_revision := rows_revision + 1
		ensure
			set: column_alignment (a_column) = a_alignment
		end

feature -- Rows

	row_count: INTEGER
		do
			Result := rows.count
		end

	row_label (a_row: INTEGER): STRING_32
		require
			valid: a_row >= 1 and a_row <= row_count
		do
			Result := rows.i_th (a_row).label
		end

	is_note_row (a_row: INTEGER): BOOLEAN
		require
			valid: a_row >= 1 and a_row <= row_count
		do
			Result := rows.i_th (a_row).is_note
		end

	cell (a_row, a_column: INTEGER): DOC_TEXT
			-- The text of verse row `a_row' in column `a_column': set it, add
			-- its spans.
		require
			valid_row: a_row >= 1 and a_row <= row_count
			verse_row: not is_note_row (a_row)
			valid_column: a_column >= 1 and a_column <= column_count
		do
			Result := rows.i_th (a_row).cell (a_column)
		end

	note_text (a_row: INTEGER): DOC_TEXT
			-- The text of note row `a_row'.
		require
			valid_row: a_row >= 1 and a_row <= row_count
			note_row: is_note_row (a_row)
		do
			Result := rows.i_th (a_row).cell (1)
		end

	cell_marks (a_row, a_column: INTEGER): SW_MARKED_TEXT
			-- The marks over a cell (agreement classes, word-diff washes).
		require
			valid_row: a_row >= 1 and a_row <= row_count
			verse_row: not is_note_row (a_row)
			valid_column: a_column >= 1 and a_column <= column_count
		do
			Result := rows.i_th (a_row).cell_marks (a_column)
		end

	add_row (a_label: READABLE_STRING_GENERAL): INTEGER
			-- A verse row labelled `a_label', its cells empty; its number.
		require
			has_columns: column_count > 0
		do
			rows.extend (create {SW_PARALLEL_ROW}.make (a_label, column_count))
			rows_revision := rows_revision + 1
			Result := row_count
		ensure
			one_more: row_count = old row_count + 1
		end

	add_note (a_text: READABLE_STRING_GENERAL): INTEGER
			-- A note row reading `a_text'; its number.
		do
			rows.extend (create {SW_PARALLEL_ROW}.make_note (a_text))
			rows_revision := rows_revision + 1
			Result := row_count
		ensure
			one_more: row_count = old row_count + 1
			a_note: is_note_row (row_count)
		end

	set_cell (a_row, a_column: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Cell (`a_row', `a_column') reads `a_text', plain.
		require
			valid_row: a_row >= 1 and a_row <= row_count
			verse_row: not is_note_row (a_row)
			valid_column: a_column >= 1 and a_column <= column_count
		do
			cell (a_row, a_column).set_text (a_text)
			cell (a_row, a_column).remove_spans
		ensure
			set: cell (a_row, a_column).text.same_string_general (a_text)
		end

	wipe_out
			-- No rows (the columns stay).
		do
			rows.wipe_out
			rows_revision := rows_revision + 1
			scroll_y := 0.0
			clear_selection
		ensure
			empty: row_count = 0
		end

	on_cell_click: detachable PROCEDURE [INTEGER, INTEGER]
			-- A cell was clicked (pressed and released on it, nothing
			-- selected): (row, column).

	set_on_cell_click (a_action: detachable PROCEDURE [INTEGER, INTEGER])
		do
			on_cell_click := a_action
		ensure
			set: on_cell_click = a_action
		end

	cell_at (a_px, a_py: REAL_64): TUPLE [row, column: INTEGER]
			-- The verse and version under the point; column 0 on a note
			-- row; (0, 0) off every cell.
		local
			u: INTEGER
		do
			u := pointed_item (a_px, a_py)
			if u > 0 then
				Result := [unit_block (u), unit_column (u)]
			else
				Result := [0, 0]
			end
		end

	scroll_to_row (a_row: INTEGER)
			-- Bring row `a_row' into view, once laid out.
		require
			valid: a_row >= 1 and a_row <= row_count
		do
			if is_laid_out and then height > 0.0 then
				scroll_to (stacked_scroll_for (a_row))
			end
		end

	header_height: REAL_64
			-- The title band's height at the last layout.

	laid_column_count: INTEGER
			-- Columns placed by the last layout.
		do
			Result := column_lefts.count.min (column_widths.count)
		end

	column_left (a_column: INTEGER): REAL_64
			-- Column `a_column''s left, from `units_left', at the last layout.
		require
			valid: a_column >= 1 and a_column <= laid_column_count
		do
			Result := column_lefts.i_th (a_column)
		end

	column_width (a_column: INTEGER): REAL_64
		require
			valid: a_column >= 1 and a_column <= laid_column_count
		do
			Result := column_widths.i_th (a_column)
		end

	is_laid_out: BOOLEAN
			-- Do the measurements stand for the rows as they are?
		do
			Result := laid_rows_revision = rows_revision and stack.count = rows.count
				and block_units.count = rows.count
		end

feature -- Scrolling (SW_VSCROLLING)

	scroll_extent: REAL_64
			-- The rows, under the title band, with the page inset below.
		do
			Result := stack.content_height + stack_origin_y + margin
		end

	wheel_line: REAL_64
			-- A line of body text.
		do
			Result := (laid_px * 1.5).max (1.0)
		end

feature -- Layout

	cursor_kind: INTEGER
		do
			if not bar.contains (hover_px, hover_py) then
				Result := unit_cursor_kind
			end
		end

	arrange (a_p: SW_PAINTER)
		do
			measure (a_p)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- The rows under the title band, the band, the bar.
		do
			measure (a_p)
			begin_frame (a_p)
			a_p.push_clip (x + 1.0, y + header_height, width - 2.0, (height - header_height - 1.0).max (0.0))
			draw_visible (a_p)
			a_p.pop_clip
			draw_header (a_p)
			end_frame (a_p)
			draw_bar (a_p)
		end

feature -- Input

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			wheel_scrolled (a_delta)
			if is_hovered then
				follow_hover
				update_link_hover
			end
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- The bar, else a press on a cell starts a selection.
		do
			pressed_cell := [0, 0]
			if press_bar (a_px, a_py) then
				Result := True
			else
				pressed_cell := cell_at (a_px, a_py)
				Result := unit_press (a_px, a_py)
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := unit_double_click (a_px, a_py)
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if not drag_bar (a_py) then
				unit_drag (a_px, a_py)
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go; a press and release on one cell, nothing selected, is
			-- a click on it.
		local
			l_cell: TUPLE [row, column: INTEGER]
		do
			release_bar
			if is_selecting and then not has_selection and then pressed_cell.row > 0 then
				l_cell := cell_at (a_x, a_y)
				if l_cell.row = pressed_cell.row and l_cell.column = pressed_cell.column
					and then attached on_cell_click as al_click
				then
					al_click.call (l_cell.row, l_cell.column)
				end
			end
			unit_release (a_x, a_y)
			pressed_cell := [0, 0]
		ensure then
			released: not bar.is_dragging and not is_selecting
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- PageUp, PageDown, Home, End; Up and Down a line.
		do
			if not scroll_key (a_vk) then
				inspect a_vk
				when 40 then
					scroll_to (scroll_y + wheel_line)
				when 38 then
					scroll_to (scroll_y - wheel_line)
				else
				end
			end
		end

	handle_char (a_code: INTEGER)
			-- Ctrl+C copies, Ctrl+A selects all, Escape clears.
		do
			selection_char (a_code).do_nothing
		end

	set_hover_point (a_px, a_py: REAL_64)
		do
			Precursor {SW_DOC_UNITS} (a_px, a_py)
			update_link_hover
		end

	set_hovered (a_hovered: BOOLEAN)
		do
			Precursor {SW_DOC_UNITS} (a_hovered)
			update_link_hover
		end

feature {NONE} -- Model

	titles: ARRAYED_LIST [STRING_32]
	weights, scales: ARRAYED_LIST [REAL_64]
	alignments: ARRAYED_LIST [INTEGER]
	rows: ARRAYED_LIST [SW_PARALLEL_ROW]

	rows_revision: INTEGER
			-- Grows when rows or columns are added, removed or retuned.

	pressed_cell: TUPLE [row, column: INTEGER]
			-- The cell the last press landed on.
		attribute
			Result := [0, 0]
		end

feature {NONE} -- Layout implementation

	laid_rows_revision: INTEGER
	margin, gutter_w, columns_w, cell_pad: REAL_64
	laid_px: INTEGER
	column_lefts, column_widths: ARRAYED_LIST [REAL_64]

	measure (a_p: SW_PAINTER)
			-- The title band, the gutter and the columns from the width, then
			-- every row that changed.
		local
			t: SW_THEME
			c: INTEGER
			l_total, l_left, l_gap, l_avail: REAL_64
			l_key: STRING_8
		do
			t := a_p.theme
			margin := t.border_width
			cell_pad := t.padding / 2.0
			l_gap := t.padding
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
			header_height := a_p.text_extent + t.padding
			place_bar (t)
			gutter_w := label_gutter (a_p)
			columns_w := (width - bar.bar_width - 2.0 * margin - gutter_w).max (32.0)
			column_lefts.wipe_out
			column_widths.wipe_out
			across weights as w loop
				l_total := l_total + w
			end
			l_avail := (columns_w - l_gap * (column_count - 1).max (0)).max (16.0)
			from
				c := 1
			until
				c > column_count
			loop
				column_lefts.extend (l_left)
				column_widths.extend ((l_avail * weights.i_th (c) / l_total.max (0.000_1)).max (16.0))
				l_left := l_left + column_widths.last + l_gap
				c := c + 1
			end
			laid_px := body_pixel_size (a_p)
			l_key := columns_w.truncated_to_integer.out + "|" + laid_px.out + "|" + a_p.has_shaping.out
			if laid_rows_revision /= rows_revision or else block_units.count /= rows.count then
				stack.invalidate
			end
			if measure_stack (a_p, l_key, 0.0) then
				number_units
			end
			place_bar (t)
		ensure
			laid_out: is_laid_out
		end

	label_gutter (a_p: SW_PAINTER): REAL_64
			-- The widest verse label plus the padding; 0 with no labels.
		local
			l_widest: REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			across rows as r loop
				if not r.label.is_empty then
					l_widest := l_widest.max (a_p.advance (r.label))
				end
			end
			if l_widest > 0.0 then
				Result := l_widest + a_p.theme.padding
			end
		ensure
			non_negative: Result >= 0.0
		end

	stack_count: INTEGER
		do
			Result := rows.count
		end

	stack_origin_y: REAL_64
			-- The rows begin under the title band.
		do
			Result := header_height
		end

	item_revision (a_i: INTEGER): INTEGER
		do
			Result := rows.i_th (a_i).revision
		end

	is_volatile (a_i: INTEGER): BOOLEAN
			-- Nothing is edited in place here.
		do
		end

	stack_reset
			-- An empty unit list per row, for the rows as they are.
		local
			i: INTEGER
		do
			block_units.wipe_out
			from
				i := 1
			until
				i > rows.count
			loop
				block_units.extend (create {ARRAYED_LIST [SW_DOC_UNIT]}.make (column_count.max (1)))
				i := i + 1
			end
			laid_rows_revision := rows_revision
			clear_selection
		end

	measure_item (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
			-- Lay row `a_i''s cells out, each in its column; the row is as
			-- tall as its tallest cell, padded above and below.
		local
			t: SW_THEME
			r: SW_PARALLEL_ROW
			u: SW_DOC_UNIT
			c: INTEGER
			l_tallest, l_gap: REAL_64
			l_list: ARRAYED_LIST [SW_DOC_UNIT]
		do
			t := a_p.theme
			r := rows.i_th (a_i)
			l_list := block_units.i_th (a_i)
			l_list.wipe_out
			l_gap := t.padding
			if r.is_note then
				create u.make (a_i, 0, 0, r.cell (1), {SW_PAINTER}.Role_body, t.size_label, False)
				u.set_origin (0.0, cell_pad, columns_w)
				l_tallest := lay_unit (a_p, u)
				u.set_box (0.0, 0.0, columns_w, l_tallest + 2.0 * cell_pad)
				l_list.extend (u)
			else
				from
					c := 1
				until
					c > column_count
				loop
					create u.make (a_i, 1, c, r.cell (c), {SW_PAINTER}.Role_body, t.size_body * scales.i_th (c), False)
					u.set_alignment (alignments.i_th (c))
					u.set_origin (column_lefts.i_th (c), cell_pad, column_widths.i_th (c))
					l_tallest := l_tallest.max (lay_unit (a_p, u))
					l_list.extend (u)
					c := c + 1
				end
				across l_list as cu loop
					cu.set_box (column_lefts.i_th (cu.column) - l_gap / 2.0, 0.0, column_widths.i_th (cu.column) + l_gap,
						l_tallest + 2.0 * cell_pad)
				end
			end
			Result := l_tallest + 2.0 * cell_pad
		ensure then
			non_negative: Result >= 0.0
		end

	units_left: REAL_64
			-- Where the columns begin: past the inset and the label gutter.
		do
			Result := x + margin + gutter_w
		end

	unit_ink (a_theme: SW_THEME; a_unit: SW_DOC_UNIT): NATURAL_32
			-- Muted for a note, else the ink.
		do
			if rows.i_th (a_unit.block).is_note then
				Result := a_theme.ink_muted
			else
				Result := a_theme.ink
			end
		end

feature {NONE} -- Drawing implementation

	draw_stacked_item (a_p: SW_PAINTER; a_i: INTEGER)
			-- Row `a_i': its rule below, its label, each cell's marks under,
			-- selection, text and marks over.
		local
			t: SW_THEME
			l_top, l_bottom, ox, oy: REAL_64
			k, u: INTEGER
			l_unit: SW_DOC_UNIT
			l_marks: SW_MARKED_TEXT
		do
			t := a_p.theme
			l_top := stacked_top (a_i)
			l_bottom := (l_top + stack.height (a_i)).floor - 0.5
			a_p.set_color (t.divider)
			a_p.line (x + margin, l_bottom, x + width - bar.bar_width, l_bottom, t.text_scale)
			if not rows.i_th (a_i).label.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + margin, l_top + cell_pad + a_p.font_ascent, rows.i_th (a_i).label)
			end
			from
				k := 1
			until
				k > block_units.i_th (a_i).count
			loop
				u := block_first_unit.i_th (a_i) + k - 1
				l_unit := units.i_th (u)
				ox := unit_origin_x (u)
				oy := unit_origin_y (u)
				l_marks := rows.i_th (a_i).cell_marks (l_unit.column.max (1))
				paint_unit_selection (a_p, u, ox, oy)
				mark_painter.paint_marked (a_p, l_unit.geometry, l_marks, legend, ox, oy,
					l_unit.size * t.text_scale, agent redraw_unit (u, ?, ?, ?, ox, oy))
				k := k + 1
			end
		end

	redraw_unit (a_unit: INTEGER; a_p: SW_PAINTER; a_dx, a_dy, a_ox, a_oy: REAL_64)
			-- Unit `a_unit''s text shifted by (`a_dx', `a_dy'): what a mark's
			-- text effects draw through.
		do
			draw_unit_text (a_p, a_unit, a_ox + a_dx, a_oy + a_dy)
		end

	draw_header (a_p: SW_PAINTER)
			-- The column titles on a band, a rule under it.
		local
			t: SW_THEME
			c: INTEGER
			l_baseline: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x + 1.0, y + 1.0, width - 2.0, header_height - 1.0)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
			l_baseline := y + (header_height - a_p.text_extent) / 2.0 + a_p.font_ascent
			a_p.set_color (t.ink)
			from
				c := 1
			until
				c > column_count or c > column_lefts.count
			loop
				a_p.push_clip (units_left + column_lefts.i_th (c), y, column_widths.i_th (c), header_height)
				a_p.text (units_left + column_lefts.i_th (c), l_baseline, titles.i_th (c))
				a_p.pop_clip
				c := c + 1
			end
			a_p.set_color (t.divider)
			a_p.line (x + 1.0, y + header_height - 0.5, x + width - 1.0, y + header_height - 0.5, t.text_scale)
		end

invariant
	parallel_columns: weights.count = titles.count and scales.count = titles.count
		and alignments.count = titles.count
	at_most_six: column_count <= Max_columns
	viewport_positive: viewport_height > 0.0

end
