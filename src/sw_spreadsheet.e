note
	description: "[
		The spreadsheet doctrine's top tier: SW_SHEET's banding,
		SW_DATA_GRID's chrome discipline, SW_CELLS_ENGINE's brain.
		A formula bar names the anchor cell and mirrors its raw
		text; clicking selects (shift extends a range); typing
		edits in place; Enter commits down, Tab commits right,
		Escape abandons; arrows commit-then-move. Ctrl+C copies the
		selection as a TSV block (Excel pastes it), Ctrl+V pastes
		one back, Ctrl+Z and Ctrl+Y drive the engine's command
		undo. Deliberately NOT here, per the pinned doctrine:
		macros, per-cell styling wars, charts-in-cells. The cell
		geometry (cell_row_at / cell_col_at) is public slot math,
		assaulted; everything semantic lives in the engine, already
		assaulted on its own.
	]"

class
	SW_SPREADSHEET

inherit
	SW_WIDGET
		redefine
			handle_click, handle_char, handle_key, handle_wheel,
			accepts_focus
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create engine.make
			create edit_buffer.make_empty
			sel_col := 1
			ext_col := 1
		end

feature -- Access

	engine: SW_CELLS_ENGINE
			-- The brain, public: hosts feed CSV through it, tests
			-- interrogate it, the widget only ever renders it.

	sel_row, sel_col: INTEGER
			-- The anchor cell.

	ext_row, ext_col: INTEGER
			-- The selection's far corner (equal to the anchor when
			-- the selection is a single cell).

	is_editing: BOOLEAN

	edit_buffer: STRING_32

	scroll_row: INTEGER

	on_change: detachable PROCEDURE

	Row_h: REAL_64 = 24.0

	Col_w: REAL_64 = 92.0

	Rowhdr_w: REAL_64 = 44.0

	Header_h: REAL_64 = 24.0

	Bar_h: REAL_64 = 30.0

	cell_row_at (a_py: REAL_64): INTEGER
			-- The sheet row under a surface y; -1 outside the cells.
		do
			Result := -1
			if a_py >= y + Bar_h + Header_h and then a_py <= y + height then
				Result := ((a_py - y - Bar_h - Header_h) / Row_h).truncated_to_integer + scroll_row
				if Result > engine.Rows - 1 then
					Result := -1
				end
			end
		ensure
			sane: Result >= -1 and Result <= engine.Rows - 1
		end

	cell_col_at (a_px: REAL_64): INTEGER
			-- The sheet column under a surface x; 0 outside.
		do
			if a_px >= x + Rowhdr_w and then a_px <= x + width then
				Result := ((a_px - x - Rowhdr_w) / Col_w).truncated_to_integer + 1
				if Result > engine.Cols then
					Result := 0
				end
			end
		ensure
			sane: Result >= 0 and Result <= engine.Cols
		end

feature -- Element change

	set_on_change (a_action: PROCEDURE)
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 340.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			r, c, vis_rows, r0, c0, r1, c1: INTEGER
			cx, cy: REAL_64
			s: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- the formula bar
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x + 1.0, y + 1.0, width - 2.0, Bar_h)
			a_p.font ({SW_PAINTER}.Role_mono, 12.5, True)
			a_p.set_color (t.accent)
			a_p.text (x + 10.0, y + Bar_h - 10.0, engine.key_name (engine.key (sel_row, sel_col)))
			a_p.font ({SW_PAINTER}.Role_mono, 12.5, False)
			a_p.set_color (t.ink)
			if is_editing then
				s := edit_buffer.twin
				s.append_character ('|')
			else
				s := engine.formula (engine.key (sel_row, sel_col))
			end
			a_p.text (x + 58.0, y + Bar_h - 10.0, s)
			a_p.set_color (t.outline)
			a_p.hline (x + 1.0, y + Bar_h + 0.5, width - 2.0)
				-- headers
			vis_rows := (((height - Bar_h - Header_h) / Row_h).truncated_to_integer).max (1)
			a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
			from
				c := 1
			until
				c > engine.Cols or else x + Rowhdr_w + (c - 1) * Col_w > x + width
			loop
				cx := x + Rowhdr_w + (c - 1) * Col_w
				a_p.set_color (t.surface_variant)
				a_p.fill_rect (cx, y + Bar_h + 1.0, Col_w - 1.0, Header_h)
				a_p.set_color (t.ink_muted)
				a_p.text (cx + Col_w / 2.0 - 4.0, y + Bar_h + Header_h - 7.0,
					(64 + c).to_character_32.out.to_string_32)
				c := c + 1
			end
				-- cells
			r0 := sel_row.min (ext_row)
			r1 := sel_row.max (ext_row)
			c0 := sel_col.min (ext_col)
			c1 := sel_col.max (ext_col)
			a_p.push_clip (x + 1.0, y + Bar_h + Header_h, width - 2.0, height - Bar_h - Header_h - 1.0)
			from
				r := scroll_row
			until
				r > (scroll_row + vis_rows).min (engine.Rows - 1)
			loop
				cy := y + Bar_h + Header_h + (r - scroll_row) * Row_h
				a_p.set_color (t.surface_variant)
				a_p.fill_rect (x + 1.0, cy, Rowhdr_w - 1.0, Row_h - 1.0)
				a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 8.0, cy + Row_h - 8.0, r.out.to_string_32)
				from
					c := 1
				until
					c > engine.Cols or else x + Rowhdr_w + (c - 1) * Col_w > x + width
				loop
					cx := x + Rowhdr_w + (c - 1) * Col_w
					if r >= r0 and r <= r1 and c >= c0 and c <= c1 then
						a_p.set_color (t.wash_accent)
						a_p.fill_rect (cx, cy, Col_w - 1.0, Row_h - 1.0)
					elseif r \\ 2 = 1 then
						a_p.set_color_alpha (t.surface_variant, 0.45)
						a_p.fill_rect (cx, cy, Col_w - 1.0, Row_h - 1.0)
					end
					a_p.font ({SW_PAINTER}.Role_mono, 12.0, False)
					a_p.set_color (t.ink)
					if is_editing and r = sel_row and c = sel_col then
						s := edit_buffer.twin
						s.append_character ('|')
						a_p.text (cx + 5.0, cy + Row_h - 8.0, s)
					else
						a_p.text (cx + 5.0, cy + Row_h - 8.0,
							engine.display (engine.key (r, c)))
					end
					c := c + 1
				end
				r := r + 1
			end
				-- the anchor's border
			if sel_row >= scroll_row and sel_row <= scroll_row + vis_rows then
				a_p.set_color (t.accent)
				a_p.rrect_stroke (x + Rowhdr_w + (sel_col - 1) * Col_w - 0.5,
					y + Bar_h + Header_h + (sel_row - scroll_row) * Row_h - 0.5,
					Col_w, Row_h, 2.0)
			end
			a_p.pop_clip
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			r, c: INTEGER
			keys: SW_KEYS
		do
			if is_enabled then
				r := cell_row_at (a_py)
				c := cell_col_at (a_px)
				if r >= 0 and c >= 1 then
					commit_edit
					create keys
					if keys.shift_down then
						ext_row := r
						ext_col := c
					else
						sel_row := r
						sel_col := c
						ext_row := r
						ext_col := c
					end
				end
				Result := True
			end
		end

	handle_char (a_code: INTEGER)
		do
			inspect a_code
			when 3 then
				copy_selection
			when 22 then
				paste_at_anchor
			when 26 then
				if engine.can_undo then
					engine.undo
					announce
				end
			when 25 then
				if engine.can_redo then
					engine.redo
					announce
				end
			when 13 then
				commit_edit
				move_sel (1, 0)
			when 9 then
				commit_edit
				move_sel (0, 1)
			when 27 then
				is_editing := False
				edit_buffer.wipe_out
			when 8 then
				if is_editing and then not edit_buffer.is_empty then
					edit_buffer.remove_tail (1)
				end
			else
				if a_code >= 32 then
					if not is_editing then
						is_editing := True
						edit_buffer.wipe_out
					end
					edit_buffer.append_code (a_code.to_natural_32)
				end
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			inspect a_vk
			when 37 then
				commit_edit
				if a_shift then
					extend_sel (0, -1)
				else
					move_sel (0, -1)
				end
			when 39 then
				commit_edit
				if a_shift then
					extend_sel (0, 1)
				else
					move_sel (0, 1)
				end
			when 38 then
				commit_edit
				if a_shift then
					extend_sel (-1, 0)
				else
					move_sel (-1, 0)
				end
			when 40 then
				commit_edit
				if a_shift then
					extend_sel (1, 0)
				else
					move_sel (1, 0)
				end
			when 36 then
				commit_edit
				sel_col := 1
				ext_col := 1
				ext_row := sel_row
			when 35 then
				commit_edit
				sel_col := engine.used_max_col.max (1)
				ext_col := sel_col
				ext_row := sel_row
			when 46 then
				clear_selection
			else
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			scroll_row := (scroll_row - (a_delta // 40)).max (0).min (engine.Rows - 4)
			Result := True
		end

feature -- Operations

	commit_edit
			-- Land the edit buffer in the anchor cell, if editing.
		do
			if is_editing then
				engine.commit (engine.key (sel_row, sel_col), edit_buffer)
				is_editing := False
				edit_buffer.wipe_out
				announce
			end
		ensure
			landed: not is_editing
		end

	copy_selection
			-- The selection as a TSV block, onto the clipboard.
		local
			clip: SW_CLIPBOARD
		do
			create clip
			clip.set_text (engine.block_tsv (
				sel_row.min (ext_row), sel_col.min (ext_col),
				sel_row.max (ext_row), sel_col.max (ext_col)))
		end

	paste_at_anchor
		local
			clip: SW_CLIPBOARD
		do
			create clip
			if not clip.text.is_empty then
				engine.paste_tsv (sel_row.min (ext_row), sel_col.min (ext_col), clip.text)
				announce
			end
		end

	clear_selection
			-- Empty every selected cell - each through commit, so
			-- undo walks them back one by one.
		local
			r, c: INTEGER
		do
			from
				r := sel_row.min (ext_row)
			until
				r > sel_row.max (ext_row)
			loop
				from
					c := sel_col.min (ext_col)
				until
					c > sel_col.max (ext_col)
				loop
					if engine.is_occupied (engine.key (r, c)) then
						engine.commit (engine.key (r, c), "")
					end
					c := c + 1
				end
				r := r + 1
			end
			announce
		end

feature {NONE} -- Movement

	move_sel (a_dr, a_dc: INTEGER)
		do
			sel_row := (sel_row + a_dr).max (0).min (engine.Rows - 1)
			sel_col := (sel_col + a_dc).max (1).min (engine.Cols)
			ext_row := sel_row
			ext_col := sel_col
			if sel_row < scroll_row then
				scroll_row := sel_row
			end
		end

	extend_sel (a_dr, a_dc: INTEGER)
		do
			ext_row := (ext_row + a_dr).max (0).min (engine.Rows - 1)
			ext_col := (ext_col + a_dc).max (1).min (engine.Cols)
		end

	announce
		do
			if attached on_change as a then
				a.call (Void)
			end
		end

invariant
	engine_attached: engine /= Void
	anchor_sane: sel_row >= 0 and sel_row <= engine.Rows - 1
		and sel_col >= 1 and sel_col <= engine.Cols

end
