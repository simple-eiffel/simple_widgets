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
			handle_triple_click, handle_drag, handle_char, handle_key,
			context_menu, accepts_pebble, receive_pebble
		end

create
	make, make_single_line, make_password

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL)
		do
			create text.make_from_string_general (a_text)
			create extra_ranges.make (4)
			create spell_ranges.make (8)
			is_spellcheck_enabled := True
			spell_dirty := True
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

	make_password (a_text: READABLE_STRING_GENERAL)
			-- One masked line: bullets on screen, no copy to the
			-- clipboard, no spellcheck peeking at the secret.
		do
			make_single_line (a_text)
			is_masked := True
		ensure
			single: is_single_line
			masked: is_masked
		end

feature -- Access

	text: STRING_32

	caret: INTEGER
			-- Insertion position, 0 .. text.count.

	sel_anchor: INTEGER
			-- Other end of the primary selection; equal to caret when empty.

	spell_ranges: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- Misspelled ranges from the inbox checker; refreshed
			-- lazily after edits.

	is_masked: BOOLEAN
			-- Draw bullets instead of characters? Masked boxes also
			-- refuse clipboard copy and skip spellcheck.

	is_revealed: BOOLEAN
			-- Eye toggled open? A view change only: copy stays denied
			-- and spellcheck still never sees the text.

	is_hiding: BOOLEAN
			-- Are characters drawn as bullets right now?
		do
			Result := is_masked and not is_revealed
		end

	is_spellcheck_enabled: BOOLEAN

	extra_ranges: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- Additional selected ranges beyond the primary one - the
			-- fruit of Invert Selection. Each covers characters
			-- lo+1 .. hi; kept sorted, disjoint and non-empty.

	is_single_line: BOOLEAN

	is_read_only: BOOLEAN

	on_change: detachable PROCEDURE
			-- Fired after every edit.

feature -- Status

	has_selection: BOOLEAN
		do
			Result := sel_anchor /= caret or else not extra_ranges.is_empty
		end

	is_char_selected (a_i: INTEGER): BOOLEAN
			-- Is character `a_i' inside any selected range?
		require
			in_text: a_i >= 1 and a_i <= text.count
		do
			Result := a_i > sel_anchor.min (caret) and a_i <= sel_anchor.max (caret)
			across
				extra_ranges as r
			loop
				Result := Result or else (a_i > r.lo and a_i <= r.hi)
			end
		end

	selected_text: STRING_32
			-- All selected pieces in text order; disjoint pieces join
			-- with a newline, the multi-select copy convention.
		local
			pieces: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
		do
			create Result.make_empty
			pieces := all_ranges
			across
				pieces as r
			loop
				if not Result.is_empty then
					Result.append_character ('%N')
				end
				Result.append (text.substring (r.lo + 1, r.hi))
			end
		ensure
			empty_without_selection: not has_selection implies Result.is_empty
		end

feature -- Clipboard and selection commands

	select_all
		do
			extra_ranges.wipe_out
			sel_anchor := 0
			caret := text.count
		ensure
			all_selected: text.count > 0 implies has_selection
		end

	select_none
			-- Collapse every selection to the caret.
		do
			sel_anchor := caret
			extra_ranges.wipe_out
		ensure
			collapsed: not has_selection
			caret_unmoved: caret = old caret
		end

	invert_selection
			-- Select exactly what was not selected; deselect the rest.
			-- May yield disjoint ranges - the primary becomes the last
			-- complement range, the others ride extra_ranges.
		local
			sel, comp: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			pos: INTEGER
			last_r: TUPLE [lo, hi: INTEGER]
		do
			sel := all_ranges
			create comp.make (sel.count + 1)
			pos := 0
			across
				sel as r
			loop
				if r.lo > pos then
					comp.extend ([pos, r.lo])
				end
				pos := r.hi
			end
			if pos < text.count then
				comp.extend ([pos, text.count])
			end
			extra_ranges.wipe_out
			if comp.is_empty then
				sel_anchor := caret
			else
				last_r := comp.last
				comp.finish
				comp.remove
				across
					comp as r
				loop
					extra_ranges.extend (r)
				end
				sel_anchor := last_r.lo
				caret := last_r.hi
			end
		ensure
			nothing_becomes_everything: (old all_ranges.is_empty and text.count > 0) implies
				(sel_anchor.min (caret) = 0 and sel_anchor.max (caret) = text.count)
		end

	copy_selection
			-- Masked boxes never surrender their text to the
			-- clipboard - copying from one is a silent no-op.
		local
			clip: SW_CLIPBOARD
		do
			if has_selection and not is_masked then
				create clip
				clip.set_text (selected_text)
			end
		end

	cut_selection
		do
			if not is_read_only and then has_selection then
				copy_selection
				delete_selection
				changed
			end
		end

	paste_clipboard
		local
			clip: SW_CLIPBOARD
			s: STRING_32
		do
			if not is_read_only then
				create clip
				s := clip.text
				s.prune_all ('%R')
				if is_single_line then
					s.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
				end
				if not s.is_empty then
					if has_selection then
						delete_selection
					end
					text.insert_string (s, caret + 1)
					caret := caret + s.count
					sel_anchor := caret
					changed
				end
			end
		end

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
			-- Swap the whole text. Every selection artifact of the old
			-- text dies with it - ranges into a vanished string are
			-- exactly the invariant breach DBC exists to forbid.
		do
			create text.make_from_string_general (a_text)
			caret := caret.min (text.count)
			sel_anchor := caret
			extra_ranges.wipe_out
			layout_width := -1.0
			spell_dirty := True
		ensure
			kept: text.same_string_general (a_text)
			caret_in_range: caret <= text.count
			no_stale_extras: extra_ranges.is_empty
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

	set_spellcheck (a_on: BOOLEAN)
		do
			is_spellcheck_enabled := a_on
			spell_dirty := True
		ensure
			set: is_spellcheck_enabled = a_on
		end

	set_masked (a_on: BOOLEAN)
		do
			is_masked := a_on
			layout_width := -1.0
			spell_dirty := True
		ensure
			set: is_masked = a_on
		end

	toggle_reveal
			-- Flip the eye: show or hide the secret on screen.
		require
			masked_box: is_masked
		do
			is_revealed := not is_revealed
			layout_width := -1.0
		ensure
			flipped: is_revealed = not (old is_revealed)
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
				if shows_hover then
					a_p.set_color (t.ink_muted)
				else
					a_p.set_color (t.outline)
				end
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
				seln := is_focused and then has_selection and then is_char_selected (i)
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
				a_p.text (gx, gy, glyph (i))
				i := i + 1
			end
			refresh_spelling
			across
				spell_ranges as sr
			loop
				from
					i := sr.lo + 1
				until
					i > sr.hi or i > n
				loop
					gx := x + Pad_x + lay_x.i_th (i)
					gy := y + Pad_y + lay_line.i_th (i) * t.line_height + t.line_height - 8.0
					a_p.set_color (t.danger)
					a_p.fill_rect (gx, gy + 3.5, lay_adv.i_th (i) + 1.0, 1.6)
					i := i + 1
				end
			end
			if is_focused then
				cx := x + Pad_x + caret_x
				cy := y + Pad_y + caret_line * t.line_height + t.line_height - 8.0
				a_p.set_color (t.danger)
				a_p.fill_rect (cx, cy - 16.0, 2.0, 23.0)
			end
			if is_masked then
					-- the reveal eye: almond, iris, and a slash while open
				cx := x + width - 19.0
				cy := y + height / 2.0
				if is_revealed or shows_hover then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.rrect_stroke (cx - 8.0, cy - 4.5, 16.0, 9.0, 4.5)
				a_p.rrect_fill (cx - 2.5, cy - 2.5, 5.0, 5.0, 2.5)
				if is_revealed then
					a_p.line (cx - 8.0, cy + 6.0, cx + 8.0, cy - 6.0, 1.6)
				end
			end
		end

feature -- Input

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- Click places the caret; Shift+Click keeps the anchor and
			-- selects everything between it and the click point.
		local
			keys: SW_KEYS
		do
			if is_masked and then a_px >= x + width - Eye_zone then
				toggle_reveal
			else
				create keys
				caret := offset_at (a_px, a_py)
				if not keys.shift_down then
					sel_anchor := caret
					extra_ranges.wipe_out
				end
			end
			Result := True
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- Select the word under the point.
		local
			c, lo, hi, n: INTEGER
		do
			Result := True
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

	handle_triple_click (a_px, a_py: REAL_64): BOOLEAN
			-- Triple click: the whole text, the editor convention.
		do
			select_all
			Result := True
		ensure then
			all_selected: text.count > 0 implies has_selection
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			caret := offset_at (a_px, a_py)
		end

	handle_char (a_code: INTEGER)
		do
			if a_code = 27 then -- Escape
				select_none
			elseif a_code = 1 then -- Ctrl+A
				select_all
			elseif a_code = 3 then -- Ctrl+C
				copy_selection
			elseif a_code = 24 then -- Ctrl+X
				cut_selection
			elseif a_code = 22 then -- Ctrl+V
				paste_clipboard
			elseif not is_read_only then
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

	accepts_pebble (a_pebble: ANY): BOOLEAN
			-- Text boxes welcome any string pebble (unless read-only).
		do
			Result := not is_read_only and then attached {READABLE_STRING_GENERAL} a_pebble
		end

	receive_pebble (a_pebble: ANY)
			-- Drop inserts the string at the caret.
		local
			s: STRING_32
		do
			if attached {READABLE_STRING_GENERAL} a_pebble as rs then
				create s.make_from_string_general (rs)
				if has_selection then
					delete_selection
				end
				text.insert_string (s, caret + 1)
				caret := caret + s.count
				sel_anchor := caret
				changed
			end
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- The standard text menu. A right-click outside the current
			-- selection moves the caret there first, as every editor does.
		local
			clip: SW_CLIPBOARD
			c: INTEGER
		do
			c := offset_at (a_px, a_py)
			if not (has_selection and then c >= sel_anchor.min (caret) and then c <= sel_anchor.max (caret)) then
				caret := c
				sel_anchor := c
			end
			create clip
			create Result.make
			refresh_spelling
			if not is_read_only and then attached spell_range_at (c) as sr then
				across
					suggestion_texts (sr) as sg
				loop
					Result.add_item (sg, "", True, agent replace_range (sr.lo, sr.hi, sg))
				end
				Result.add_separator
			end
			Result.add_item ("Cut", "Ctrl+X", has_selection and not is_read_only and not is_masked, agent cut_selection)
			Result.add_item ("Copy", "Ctrl+C", has_selection and not is_masked, agent copy_selection)
			Result.add_item ("Paste", "Ctrl+V", clip.has_text and not is_read_only, agent paste_clipboard)
			Result.add_separator
			Result.add_item ("Select All", "Ctrl+A", text.count > 0, agent select_all)
			Result.add_item ("Select None", "Esc", has_selection, agent select_none)
			Result.add_item ("Invert Selection", "", has_selection, agent invert_selection)
		ensure then
			offered: Result /= Void
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

	Eye_zone: REAL_64 = 30.0
			-- Right-edge click zone of a masked box: the reveal eye.

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
					if text.item (i) = '%N' and then not is_hiding then
						lay_x.extend (cx)
						lay_adv.extend (0.0)
						lay_line.extend (line)
						if not is_single_line then
							line := line + 1
							cx := 0.0
						end
						i := i + 1
					elseif text.item (i) = ' ' and then not is_hiding then
						lay_x.extend (cx)
						lay_adv.extend (a_p.advance (" "))
						lay_line.extend (line)
						cx := cx + lay_adv.last
						i := i + 1
					else
						from
							j := i
						until
							j >= n or else (not is_hiding and then (text.item (j + 1) = ' ' or else text.item (j + 1) = '%N'))
						loop
							j := j + 1
						end
						ww := 0.0
						from
							k := i
						until
							k > j
						loop
							ww := ww + a_p.advance (glyph (k))
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
							lay_adv.extend (a_p.advance (glyph (k)))
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

	glyph (a_i: INTEGER): STRING_32
			-- What position `a_i' shows: the character itself, or a
			-- bullet when masked - secrets have length, not content.
		require
			in_text: a_i >= 1 and a_i <= text.count
		do
			if is_hiding then
				Result := {STRING_32} "%/8226/"
			else
				Result := text.substring (a_i, a_i)
			end
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

	suggestion_texts (a_r: TUPLE [lo, hi: INTEGER]): ARRAYED_LIST [STRING_32]
			-- Up to three corrections for the word in `a_r'.
		local
			sp: SW_SPELLER
		do
			create sp
			create Result.make (3)
			across
				sp.suggestions (text.substring (a_r.lo + 1, a_r.hi)) as s
			loop
				if Result.count < 3 then
					Result.extend (s)
				end
			end
		ensure
			few: Result.count <= 3
		end

	all_ranges: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- Primary plus extras, normalized, sorted, non-empty only.
		local
			lo, hi, i, j: INTEGER
			r, s: TUPLE [lo, hi: INTEGER]
		do
			create Result.make (extra_ranges.count + 1)
			across
				extra_ranges as er
			loop
				Result.extend (er)
			end
			lo := sel_anchor.min (caret)
			hi := sel_anchor.max (caret)
			if hi > lo then
				Result.extend ([lo, hi])
			end
				-- insertion sort by lo; lists are tiny
			from
				i := 2
			until
				i > Result.count
			loop
				from
					j := i
				until
					j <= 1 or else Result.i_th (j - 1).lo <= Result.i_th (j).lo
				loop
					r := Result.i_th (j)
					s := Result.i_th (j - 1)
					Result.put_i_th (r, j - 1)
					Result.put_i_th (s, j)
					j := j - 1
				end
				i := i + 1
			end
		ensure
			sorted: across 2 |..| Result.count as k all
				Result.i_th (k - 1).lo <= Result.i_th (k).lo end
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
			-- Remove every selected range; the caret lands where the
			-- first one began.
		local
			pieces: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			i, first_lo: INTEGER
		do
			pieces := all_ranges
			if not pieces.is_empty then
				first_lo := pieces.first.lo
				from
					i := pieces.count
				until
					i < 1
				loop
					text.remove_substring (pieces.i_th (i).lo + 1, pieces.i_th (i).hi)
					i := i - 1
				end
				caret := first_lo
				sel_anchor := first_lo
				extra_ranges.wipe_out
			end
		ensure
			collapsed: not has_selection
		end

	changed
		do
			layout_width := -1.0
			spell_dirty := True
			if attached on_change as a then
				a.call
			end
		end

	spell_dirty: BOOLEAN

	refresh_spelling
		local
			sp: SW_SPELLER
		do
			if spell_dirty then
				spell_dirty := False
				spell_ranges.wipe_out
				if is_spellcheck_enabled and not is_masked then
					create sp
					across
						sp.misspellings (text) as r
					loop
						if r.hi <= text.count then
							spell_ranges.extend (r)
						end
					end
				end
			end
		end

	spell_range_at (a_pos: INTEGER): detachable TUPLE [lo, hi: INTEGER]
			-- The misspelled range containing position `a_pos', if any.
		do
			across
				spell_ranges as r
			loop
				if a_pos > r.lo and a_pos <= r.hi then
					Result := r
				end
			end
		end

	replace_range (a_lo, a_hi: INTEGER; a_with: READABLE_STRING_GENERAL)
			-- Swap characters a_lo+1..a_hi for `a_with' (a suggestion).
		require
			sane: a_lo >= 0 and a_hi <= text.count and a_lo < a_hi
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_with)
			text.remove_substring (a_lo + 1, a_hi)
			text.insert_string (s, a_lo + 1)
			caret := a_lo + s.count
			sel_anchor := caret
			changed
		end

invariant
	text_attached: text /= Void
	caret_in_range: caret >= 0 and caret <= text.count
	anchor_in_range: sel_anchor >= 0 and sel_anchor <= text.count
	extras_attached: extra_ranges /= Void
	extras_well_formed: across extra_ranges as r all
		r.lo >= 0 and r.lo < r.hi and r.hi <= text.count end

end
