note
	description: "[
		Editable text with the full engine: measured word wrap, a caret
		placed by click or arrows, and a real selection model - drag,
		double-click word, shift with arrows, home and end. Harvested
		from the narrate editor, where it was proven against live and
		synthetic input.

		Single-line mode simply refuses to wrap and ignores line keys.
		The change agent fires after every edit, so the host owns what
		an edit MEANS (marking a block dirty, validating a number);
		this widget only owns what an edit IS.
	]"

class
	SW_TEXT_BOX

inherit
	SW_WIDGET
		redefine
			accepts_focus, handle_click, handle_double_click,
			handle_drag, handle_char, handle_key
		end

create
	make, make_single_line

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL)
		do
			create text.make_from_string_general (a_text)
			create lay_x.make (text.count + 8)
			create lay_adv.make (text.count + 8)
			create lay_line.make (text.count + 8)
			lay_lines := 1
			layout_width := -1.0
		ensure
			text_kept: text.same_string_general (a_text)
		end

	make_single_line (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text)
			is_single_line := True
		ensure
			single: is_single_line
		end

feature -- Access

	text: STRING_32

	caret: INTEGER
			-- Insertion position, 0 .. text.count.

	sel_anchor: INTEGER
			-- Other end of the selection; equal to caret when empty.

	is_single_line: BOOLEAN

	is_read_only: BOOLEAN

	on_change: detachable PROCEDURE
			-- Fired after every edit.

feature -- Status

	has_selection: BOOLEAN
		do
			Result := sel_anchor /= caret
		end

	selected_text: STRING_32
		do
			if has_selection then
				Result := text.substring (sel_anchor.min (caret) + 1, sel_anchor.max (caret))
			else
				create Result.make_empty
			end
		ensure
			empty_without_selection: not has_selection implies Result.is_empty
		end

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
		do
			create text.make_from_string_general (a_text)
			caret := caret.min (text.count)
			sel_anchor := caret
			layout_width := -1.0
		ensure
			kept: text.same_string_general (a_text)
			caret_in_range: caret <= text.count
		end

	set_on_change (a_action: PROCEDURE)
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

	set_read_only (a_ro: BOOLEAN)
		do
			is_read_only := a_ro
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			ensure_layout (a_p, a_width - 2.0 * Pad_x)
			Result := lay_lines * a_p.theme.line_height + 2.0 * Pad_y
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, n, lo, hi: INTEGER
			gx, gy, gw, cx, cy: REAL_64
			seln: BOOLEAN
		do
			t := a_p.theme
			ensure_layout (a_p, width - 2.0 * Pad_x)
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if is_focused then
				a_p.set_color (t.accent)
				a_p.set_line_width (2.0)
				a_p.rrect_stroke (x + 1.0, y + 1.0, width - 2.0, height - 2.0, t.radius)
				a_p.set_line_width (1.0)
			else
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			end
			n := text.count
			lo := sel_anchor.min (caret)
			hi := sel_anchor.max (caret)
			from
				i := 1
			until
				i > n
			loop
				gx := x + Pad_x + lay_x.i_th (i)
				gy := y + Pad_y + lay_line.i_th (i) * t.line_height + t.line_height - 8.0
				gw := lay_adv.i_th (i)
				seln := is_focused and then has_selection and then i > lo and then i <= hi
				if seln then
					a_p.set_color (t.accent)
					a_p.fill_rect (gx - 1.0, gy - 15.0, gw + 2.0, 21.0)
				end
				a_p.font ({SW_PAINTER}.Role_body, t.size_body, False)
				if seln then
					a_p.set_color (t.surface)
				else
					a_p.set_color (t.ink)
				end
				a_p.text (gx, gy, text.substring (i, i))
				i := i + 1
			end
			if is_focused then
				cx := x + Pad_x + caret_x
				cy := y + Pad_y + caret_line * t.line_height + t.line_height - 8.0
				a_p.set_color (t.danger)
				a_p.fill_rect (cx, cy - 16.0, 2.0, 23.0)
			end
		end

feature -- Input

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64)
		do
			caret := offset_at (a_px, a_py)
			sel_anchor := caret
		end

	handle_double_click (a_px, a_py: REAL_64)
			-- Select the word under the point.
		local
			c, lo, hi, n: INTEGER
		do
			n := text.count
			if n > 0 then
				c := offset_at (a_px, a_py)
				lo := c.max (1).min (n)
					-- on whitespace, snap to the nearer word instead of
					-- swallowing both neighbours
				if text.item (lo) = ' ' and then lo < n and then text.item (lo + 1) /= ' ' then
					lo := lo + 1
				end
				hi := lo
				from
				until
					lo <= 1 or else text.item (lo - 1) = ' '
				loop
					lo := lo - 1
				end
				from
				until
					hi >= n or else text.item (hi + 1) = ' '
				loop
					hi := hi + 1
				end
				sel_anchor := lo - 1
				caret := hi
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			caret := offset_at (a_px, a_py)
		end

	handle_char (a_code: INTEGER)
		do
			if not is_read_only then
				if a_code = 8 then
					if has_selection then
						delete_selection
					elseif caret > 0 then
						text.remove (caret)
						caret := caret - 1
						sel_anchor := caret
					end
					changed
				elseif a_code >= 32 or else (a_code = 13 and not is_single_line) then
					if has_selection then
						delete_selection
					end
					if a_code = 13 then
						text.insert_character ('%N', caret + 1)
					else
						text.insert_character (a_code.to_character_32, caret + 1)
					end
					caret := caret + 1
					sel_anchor := caret
					changed
				end
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		local
			cl: INTEGER
			cx: REAL_64
		do
			inspect a_vk
			when 37 then -- LEFT
				caret := (caret - 1).max (0)
				collapse_unless (a_shift)
			when 39 then -- RIGHT
				caret := (caret + 1).min (text.count)
				collapse_unless (a_shift)
			when 36 then -- HOME
				caret := line_start (caret_line)
				collapse_unless (a_shift)
			when 35 then -- END
				caret := line_end (caret_line)
				collapse_unless (a_shift)
			when 38 then -- UP
				cl := caret_line
				if cl > 0 then
					cx := caret_x
					caret := offset_on_line (cl - 1, cx)
				end
				collapse_unless (a_shift)
			when 40 then -- DOWN
				cl := caret_line
				if cl < lay_lines - 1 then
					cx := caret_x
					caret := offset_on_line (cl + 1, cx)
				end
				collapse_unless (a_shift)
			when 46 then -- DELETE
				if not is_read_only then
					if has_selection then
						delete_selection
						changed
					elseif caret < text.count then
						text.remove (caret + 1)
						changed
					end
				end
			else
			end
		end

feature {NONE} -- Engine

	Pad_x: REAL_64 = 9.0
	Pad_y: REAL_64 = 6.0

	lay_x: ARRAYED_LIST [REAL_64]
	lay_adv: ARRAYED_LIST [REAL_64]
	lay_line: ARRAYED_LIST [INTEGER]
	lay_lines: INTEGER
	layout_width: REAL_64
			-- Width the cached layout was measured at; -1 forces rebuild.

	ensure_layout (a_p: SW_PAINTER; a_wrap: REAL_64)
			-- Measure-then-place: one slot per character, greedy word
			-- wrap, spaces never wrapping. Cached against width.
		local
			n, i, j, k, line: INTEGER
			cx, ww: REAL_64
		do
			if layout_width /= a_wrap or lay_x.count /= text.count then
				layout_width := a_wrap
				lay_x.wipe_out
				lay_adv.wipe_out
				lay_line.wipe_out
				a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
				n := text.count
				from
					i := 1
					cx := 0.0
					line := 0
				until
					i > n
				loop
					if text.item (i) = '%N' then
						lay_x.extend (cx)
						lay_adv.extend (0.0)
						lay_line.extend (line)
						if not is_single_line then
							line := line + 1
							cx := 0.0
						end
						i := i + 1
					elseif text.item (i) = ' ' then
						lay_x.extend (cx)
						lay_adv.extend (a_p.advance (" "))
						lay_line.extend (line)
						cx := cx + lay_adv.last
						i := i + 1
					else
						from
							j := i
						until
							j >= n or else text.item (j + 1) = ' ' or else text.item (j + 1) = '%N'
						loop
							j := j + 1
						end
						ww := 0.0
						from
							k := i
						until
							k > j
						loop
							ww := ww + a_p.advance (text.substring (k, k))
							k := k + 1
						end
						if not is_single_line and then cx > 0.0 and then cx + ww > a_wrap then
							line := line + 1
							cx := 0.0
						end
						from
							k := i
						until
							k > j
						loop
							lay_x.extend (cx)
							lay_adv.extend (a_p.advance (text.substring (k, k)))
							lay_line.extend (line)
							cx := cx + lay_adv.last
							k := k + 1
						end
						i := j + 1
					end
				end
				lay_lines := line + 1
			end
		ensure
			one_slot_per_char: lay_x.count = text.count
			at_least_one_line: lay_lines >= 1
		end

	caret_line: INTEGER
		do
			if caret > 0 and caret <= lay_line.count then
				Result := lay_line.i_th (caret)
			end
		end

	caret_x: REAL_64
		do
			if caret > 0 and caret <= lay_x.count then
				Result := lay_x.i_th (caret) + lay_adv.i_th (caret)
			end
		end

	line_start (a_line: INTEGER): INTEGER
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > lay_line.count or else lay_line.i_th (i) = a_line
			loop
				i := i + 1
			end
			Result := (i - 1).max (0)
		end

	line_end (a_line: INTEGER): INTEGER
		local
			i: INTEGER
		do
			Result := lay_line.count
			from
				i := 1
			until
				i > lay_line.count
			loop
				if lay_line.i_th (i) = a_line then
					Result := i
				end
				i := i + 1
			end
		end

	offset_on_line (a_line: INTEGER; a_px: REAL_64): INTEGER
		local
			i: INTEGER
			found_any: BOOLEAN
		do
			Result := lay_line.count
			from
				i := 1
			until
				i > lay_line.count
			loop
				if lay_line.i_th (i) = a_line then
					if not found_any and then a_px < lay_x.i_th (i) + lay_adv.i_th (i) / 2.0 then
						Result := i - 1
						found_any := True
					elseif a_px >= lay_x.i_th (i) + lay_adv.i_th (i) / 2.0 then
						Result := i
					end
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= lay_line.count
		end

	offset_at (a_px, a_py: REAL_64): INTEGER
			-- Caret position under a window point.
		local
			line: INTEGER
			lh: REAL_64
		do
			lh := 26.0
			line := (((a_py - y - Pad_y) / lh).truncated_to_integer).max (0).min (lay_lines - 1)
			Result := offset_on_line (line, a_px - x - Pad_x)
		ensure
			in_range: Result >= 0 and Result <= text.count
		end

	collapse_unless (a_extend: BOOLEAN)
		do
			if not a_extend then
				sel_anchor := caret
			end
		ensure
			collapsed: not a_extend implies not has_selection
		end

	delete_selection
		local
			lo: INTEGER
		do
			lo := sel_anchor.min (caret)
			text.remove_substring (lo + 1, sel_anchor.max (caret))
			caret := lo
			sel_anchor := lo
		ensure
			collapsed: not has_selection
		end

	changed
		do
			layout_width := -1.0
			if attached on_change as a then
				a.call
			end
		end

invariant
	text_attached: text /= Void
	caret_in_range: caret >= 0 and caret <= text.count
	anchor_in_range: sel_anchor >= 0 and sel_anchor <= text.count

end
