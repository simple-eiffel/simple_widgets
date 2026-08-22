note
	description: "[
		The spreadsheet grid: rows 0-99, columns A-Z, frozen headers,
		two-axis scrolling, click selects, double-click edits in
		place. The sheet owns display and editing; formulas, values
		and change propagation belong to the host, wired through
		agents - the domain/presentation split, enforced by design.
	]"

class
	SW_SHEET

inherit
	SW_WIDGET
		redefine
			handle_click, handle_double_click, handle_char, handle_key,
			handle_wheel, wants_hover_point, accepts_focus
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			create displays.make (128)
			sel_row := 0
			sel_col := 1
			create edit_text.make_empty
		ensure
			kept: viewport_height = a_viewport_height
		end

feature -- Access

	Rows: INTEGER = 100
			-- Numbered 0 .. 99.

	Cols: INTEGER = 26
			-- Lettered A .. Z.

	Col_w: REAL_64 = 72.0
	Row_h: REAL_64 = 24.0
	Head_w: REAL_64 = 40.0

	viewport_height: REAL_64

	scroll_x, scroll_y: REAL_64

	sel_row: INTEGER
			-- Selected row, 0-based (0 .. Rows - 1).

	sel_col: INTEGER
			-- Selected column, 1-based (1 .. Cols).

	is_editing: BOOLEAN

	edit_text: STRING_32
			-- The formula being typed while `is_editing'.

	on_cell_commit: detachable PROCEDURE [INTEGER, INTEGER, STRING_32]
			-- (row, col, text) - fired when an edit commits; the host
			-- parses, evaluates, propagates, and calls
			-- `set_cell_display' for every affected cell.

	formula_provider: detachable FUNCTION [INTEGER, INTEGER, STRING_32]
			-- What editing a cell should start from (its raw formula,
			-- not its display) - the host knows.

	cell_display (a_row, a_col: INTEGER): STRING_32
		require
			row_ok: a_row >= 0 and a_row < Rows
			col_ok: a_col >= 1 and a_col <= Cols
		do
			if attached displays.item (a_row * Cols + a_col) as s then
				Result := s
			else
				create Result.make_empty
			end
		end

feature -- Element change

	set_cell_display (a_row, a_col: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			row_ok: a_row >= 0 and a_row < Rows
			col_ok: a_col >= 1 and a_col <= Cols
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_text)
			displays.force (s, a_row * Cols + a_col)
		ensure
			kept: cell_display (a_row, a_col).same_string_general (a_text)
		end

	set_on_cell_commit (a_agent: PROCEDURE [INTEGER, INTEGER, STRING_32])
		do
			on_cell_commit := a_agent
		ensure
			set: on_cell_commit = a_agent
		end

	set_formula_provider (a_agent: FUNCTION [INTEGER, INTEGER, STRING_32])
		do
			formula_provider := a_agent
		ensure
			set: formula_provider = a_agent
		end

	begin_edit
			-- Open the in-place editor on the selected cell, seeded
			-- by the host's formula for it.
		do
			is_editing := True
			if attached formula_provider as fp then
				edit_text := fp.item ([sel_row, sel_col])
			else
				create edit_text.make_empty
			end
		ensure
			editing: is_editing
		end

	commit_edit
		do
			if is_editing then
				is_editing := False
				if attached on_cell_commit as cc then
					cc.call (sel_row, sel_col, edit_text.twin)
				end
			end
		ensure
			done: not is_editing
		end

	cancel_edit
		do
			is_editing := False
		ensure
			done: not is_editing
		end

feature -- Coordinates

	column_name (a_col: INTEGER): STRING_32
		require
			col_ok: a_col >= 1 and a_col <= Cols
		do
			create Result.make (1)
			Result.append_code ((65 + a_col - 1).to_natural_32)
		ensure
			one_letter: Result.count = 1
		end

	cell_at (a_px, a_py: REAL_64): detachable TUPLE [row, col: INTEGER]
			-- The cell under a widget-space point; Void on headers or
			-- outside the grid.
		local
			r, c: INTEGER
		do
			if a_px > x + Head_w and a_py > y + Row_h then
				c := (((a_px - x - Head_w + scroll_x) / Col_w).truncated_to_integer + 1)
				r := (((a_py - y - Row_h + scroll_y) / Row_h).truncated_to_integer)
				if r >= 0 and r < Rows and c >= 1 and c <= Cols then
					Result := [r, c]
				end
			end
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

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			first_c, last_c, first_r, last_r, r, c: INTEGER
			cx, cy: REAL_64
			s: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.push_clip (x, y, width, height)
			first_c := (scroll_x / Col_w).truncated_to_integer + 1
			last_c := (((scroll_x + width - Head_w) / Col_w).truncated_to_integer + 1).min (Cols)
			first_r := (scroll_y / Row_h).truncated_to_integer
			last_r := (((scroll_y + height - Row_h) / Row_h).truncated_to_integer).min (Rows - 1)
			a_p.font ({SW_PAINTER}.Role_mono, t.size_chip + 1.0, False)
				-- grid cells
			from
				r := first_r
			until
				r > last_r
			loop
				cy := y + Row_h + (r * Row_h - scroll_y)
				from
					c := first_c
				until
					c > last_c
				loop
					cx := x + Head_w + ((c - 1) * Col_w - scroll_x)
					if r = sel_row and c = sel_col then
						if is_focused then
							a_p.set_color (t.wash_accent)
						else
							a_p.set_color (t.surface_variant)
						end
						a_p.fill_rect (cx, cy, Col_w, Row_h)
					end
					s := cell_display (r, c)
					if not s.is_empty then
						a_p.set_color (t.ink)
						a_p.text (cx + 4.0, cy + Row_h - 7.0, s)
					end
					c := c + 1
				end
				a_p.set_color (t.outline)
				a_p.hline (x + Head_w, cy + Row_h - 0.5, width - Head_w)
				r := r + 1
			end
			from
				c := first_c
			until
				c > last_c
			loop
				cx := x + Head_w + ((c - 1) * Col_w - scroll_x)
				a_p.set_color (t.outline)
				a_p.vline (cx + Col_w - 0.5, y + Row_h, height - Row_h)
				c := c + 1
			end
				-- frozen headers
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, Row_h)
			a_p.fill_rect (x, y, Head_w, height)
			a_p.set_color (t.ink_muted)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_chip + 1.0, True)
			from
				c := first_c
			until
				c > last_c
			loop
				cx := x + Head_w + ((c - 1) * Col_w - scroll_x)
				a_p.text (cx + Col_w / 2.0 - 4.0, y + Row_h - 7.0, column_name (c))
				c := c + 1
			end
			from
				r := first_r
			until
				r > last_r
			loop
				cy := y + Row_h + (r * Row_h - scroll_y)
				a_p.text (x + 6.0, cy + Row_h - 7.0, r.out)
				r := r + 1
			end
			a_p.set_color (t.outline)
			a_p.hline (x, y + Row_h - 0.5, width)
			a_p.vline (x + Head_w - 0.5, y, height)
				-- the in-place editor
			if is_editing then
				cx := x + Head_w + ((sel_col - 1) * Col_w - scroll_x)
				cy := y + Row_h + (sel_row * Row_h - scroll_y)
				a_p.set_color (t.surface)
				a_p.fill_rect (cx, cy, Col_w * 2.0, Row_h)
				a_p.set_color (t.accent)
				a_p.rrect_stroke (cx + 0.5, cy + 0.5, Col_w * 2.0 - 1.0, Row_h - 1.0, 2.0)
				a_p.font ({SW_PAINTER}.Role_mono, t.size_chip + 1.0, False)
				a_p.set_color (t.ink)
				a_p.text (cx + 4.0, cy + Row_h - 7.0, edit_text)
				a_p.fill_rect (cx + 5.0 + a_p.advance (edit_text), cy + 3.0, 1.5, Row_h - 6.0)
			end
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if is_editing then
					commit_edit
				end
				if attached cell_at (a_px, a_py) as cell then
					sel_row := cell.row
					sel_col := cell.col
				end
				Result := True
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if attached cell_at (a_px, a_py) as cell then
					sel_row := cell.row
					sel_col := cell.col
					begin_edit
				end
				Result := True
			end
		end

	handle_char (a_code: INTEGER)
		do
			if is_editing then
				if a_code = 13 then
					commit_edit
				elseif a_code = 27 then
					cancel_edit
				elseif a_code = 8 then
					if not edit_text.is_empty then
						edit_text.remove_tail (1)
					end
				elseif a_code >= 32 then
					edit_text.append_code (a_code.to_natural_32)
				end
			elseif a_code = 13 then
				begin_edit
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			if not is_editing then
				inspect a_vk
				when 37 then
					sel_col := (sel_col - 1).max (1)
				when 39 then
					sel_col := (sel_col + 1).min (Cols)
				when 38 then
					sel_row := (sel_row - 1).max (0)
				when 40 then
					sel_row := (sel_row + 1).min (Rows - 1)
				else
				end
				scroll_selection_into_view
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		local
			keys: SW_KEYS
		do
			create keys
			if keys.shift_down then
				scroll_x := (scroll_x - a_delta / 120.0 * Col_w)
					.max (0.0).min ((Cols * Col_w - (width - Head_w)).max (0.0))
			else
				scroll_y := (scroll_y - a_delta / 120.0 * Row_h * 3.0)
					.max (0.0).min ((Rows * Row_h - (height - Row_h)).max (0.0))
			end
			Result := True
		end

feature {NONE} -- Engine

	displays: HASH_TABLE [STRING_32, INTEGER]

	scroll_selection_into_view
		do
			if sel_row * Row_h < scroll_y then
				scroll_y := sel_row * Row_h
			elseif (sel_row + 1) * Row_h > scroll_y + height - Row_h then
				scroll_y := (sel_row + 1) * Row_h - (height - Row_h)
			end
			if (sel_col - 1) * Col_w < scroll_x then
				scroll_x := (sel_col - 1) * Col_w
			elseif sel_col * Col_w > scroll_x + width - Head_w then
				scroll_x := sel_col * Col_w - (width - Head_w)
			end
		end

invariant
	selection_sane: sel_row >= 0 and sel_row < Rows and sel_col >= 1 and sel_col <= Cols
	scrolls_non_negative: scroll_x >= 0.0 and scroll_y >= 0.0
	edit_text_attached: edit_text /= Void

end
