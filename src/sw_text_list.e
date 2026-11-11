note
	description: "[
		A list of text rows: SW_LIST holding its own strings, drawing them, and naming them
		for screen readers (W6, simple_gui's GUI_LIST on Windows).

		Rich rows (simple_gui 1s): each row may carry a subtitle, an icon, a count badge, a
		check box and a close glyph, kept with the row as it moves. When any row has a
		subtitle every row is two lines tall (`row_height' doubles). The user's acts - a
		click on a check box or close glyph, Space, Delete - notify `on_row_check' and
		`on_row_close'; code calls never do. `set_filter_text' shows only the rows whose title
		contains the text; row numbers stay the model's everywhere.
	]"

class
	SW_TEXT_LIST

inherit
	SW_ICON_NAMES

	SW_LIST
		rename
			make as make_list
		redefine
			row_part_clicked, handle_char, handle_key, shows_style, set_style
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
			-- An empty list `a_viewport_height' tall.
		require
			positive: a_viewport_height > 0.0
		do
			create rows.make (8)
			create parts.make (8)
			create filter_text.make_empty
			make_list (a_viewport_height)
			set_row_renderer (agent render_row)
			set_row_text (agent label_of)
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
		do
			Result := rows.count
		end

	i_th (a_i: INTEGER): STRING_32
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := rows.i_th (a_i)
		end

	row_subtitle (a_i: INTEGER): STRING_32
			-- Row `a_i''s second line; empty for none.
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := parts.i_th (a_i).subtitle
		end

	row_icon (a_i: INTEGER): STRING_32
			-- Row `a_i''s icon name; empty for none.
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := parts.i_th (a_i).icon
		end

	row_badge (a_i: INTEGER): INTEGER
			-- Row `a_i''s count pill; 0 for none.
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := parts.i_th (a_i).badge
		ensure
			non_negative: Result >= 0
		end

	is_row_checkable (a_i: INTEGER): BOOLEAN
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := parts.i_th (a_i).is_checkable
		end

	is_row_checked (a_i: INTEGER): BOOLEAN
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := parts.i_th (a_i).is_checked
		end

	is_row_closable (a_i: INTEGER): BOOLEAN
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := parts.i_th (a_i).is_closable
		end

	has_subtitles: BOOLEAN
			-- Does any row carry a subtitle (so every row is two lines)?
		do
			Result := subtitle_rows > 0
		ensure
			definition: Result = (subtitle_rows > 0)
		end

	filter_text: STRING_32
			-- The text a row's title must contain, ignoring case, to show; empty shows all.

	on_row_check: detachable PROCEDURE [INTEGER, BOOLEAN]
			-- Told (row, is_checked) when the user toggles a check box; never by a code call.

	on_row_close: detachable PROCEDURE [INTEGER]
			-- Told the row it was after the user closes a row, which is already removed.

feature -- Element change

	extend (a_text: READABLE_STRING_GENERAL)
			-- Add a row at the end.
		do
			rows.extend (a_text.to_string_32)
			parts.extend (create {SW_ROW_PARTS}.make)
			set_row_count (rows.count)
			if attached view as al_view and then matches_filter (rows.count) then
				al_view.extend (rows.count)
			end
		ensure
			one_more: count = old count + 1
			last: i_th (count).same_string_general (a_text)
		end

	wipe_out
			-- Remove every row (the selection goes too, silently).
		do
			rows.wipe_out
			parts.wipe_out
			subtitle_rows := 0
			set_row_count (0)
			refit_height
		ensure
			empty: count = 0
			none_selected: selected_index = 0
		end

	set_row_subtitle (a_i: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Row `a_i' gets the second line `a_text' (empty for none).
		require
			valid: 1 <= a_i and a_i <= count
		local
			l_had: BOOLEAN
		do
			l_had := not parts.i_th (a_i).subtitle.is_empty
			parts.i_th (a_i).set_subtitle (a_text)
			if l_had and then parts.i_th (a_i).subtitle.is_empty then
				subtitle_rows := subtitle_rows - 1
			elseif not l_had and then not parts.i_th (a_i).subtitle.is_empty then
				subtitle_rows := subtitle_rows + 1
			end
			refit_height
		ensure
			set: row_subtitle (a_i).same_string_general (a_text)
		end

	set_row_icon (a_i: INTEGER; a_name: READABLE_STRING_GENERAL)
			-- Row `a_i' shows the icon named `a_name' (GUI_ICON's names; empty for none; an unknown
			-- name keeps its space but draws nothing).
		require
			valid: 1 <= a_i and a_i <= count
		do
			parts.i_th (a_i).set_icon (a_name)
		ensure
			set: row_icon (a_i).same_string_general (a_name)
		end

	set_row_badge (a_i, a_count: INTEGER)
			-- Row `a_i' shows a count pill; 0 for none.
		require
			valid: 1 <= a_i and a_i <= count
			non_negative: a_count >= 0
		do
			parts.i_th (a_i).set_badge (a_count)
		ensure
			set: row_badge (a_i) = a_count
		end

	set_row_checkable (a_i: INTEGER; a_on: BOOLEAN)
			-- Row `a_i' shows a check box at the leading edge, or not.
		require
			valid: 1 <= a_i and a_i <= count
		do
			parts.i_th (a_i).set_checkable (a_on)
		ensure
			set: is_row_checkable (a_i) = a_on
		end

	set_row_checked (a_i: INTEGER; a_on: BOOLEAN)
			-- Row `a_i''s check box is ticked or not, as the program: nobody is told.
		require
			valid: 1 <= a_i and a_i <= count
		do
			parts.i_th (a_i).set_checked (a_on)
		ensure
			set: is_row_checked (a_i) = a_on
		end

	set_row_closable (a_i: INTEGER; a_on: BOOLEAN)
			-- Row `a_i' shows a close glyph at the trailing edge, or not.
		require
			valid: 1 <= a_i and a_i <= count
		do
			parts.i_th (a_i).set_closable (a_on)
		ensure
			set: is_row_closable (a_i) = a_on
		end

	set_on_row_check (a_action: detachable PROCEDURE [INTEGER, BOOLEAN])
		do
			on_row_check := a_action
		ensure
			set: on_row_check = a_action
		end

	set_on_row_close (a_action: detachable PROCEDURE [INTEGER])
		do
			on_row_close := a_action
		ensure
			set: on_row_close = a_action
		end

	remove_row (a_i: INTEGER)
			-- Take row `a_i' out; later rows move up one. Quiet: the selection adjusts (it goes
			-- when it was this row) and nobody is told.
		require
			valid: 1 <= a_i and a_i <= count
		do
			if not parts.i_th (a_i).subtitle.is_empty then
				subtitle_rows := subtitle_rows - 1
			end
			selection_after_removal (a_i)
			rows.go_i_th (a_i)
			rows.remove
			parts.go_i_th (a_i)
			parts.remove
			set_row_count (rows.count)
			refit_height
		ensure
			one_less: count = old count - 1
		end

	reorder (an_order: ARRAY [INTEGER])
			-- Put the rows in a new order: `an_order [k]' is the old number of the row that becomes
			-- row k. The selection stays with its row, quietly; the parts move with their rows.
		require
			a_permutation: is_permutation (an_order)
		local
			l_rows: like rows
			l_parts: like parts
			l_new_of_old: ARRAY [INTEGER]
			k: INTEGER
		do
			l_rows := rows.twin
			l_parts := parts.twin
			create l_new_of_old.make_filled (0, 1, count)
			from k := 1 until k > count loop
				l_rows.put_i_th (rows.i_th (an_order [an_order.lower + k - 1]), k)
				l_parts.put_i_th (parts.i_th (an_order [an_order.lower + k - 1]), k)
				l_new_of_old [an_order [an_order.lower + k - 1]] := k
				k := k + 1
			end
			selection_after_reorder (l_new_of_old)
			rows := l_rows
			parts := l_parts
			if filter_text.is_empty then
				view := Void
			else
				apply_filter
			end
		ensure
			same_count: count = old count
		end

	is_permutation (an_order: ARRAY [INTEGER]): BOOLEAN
			-- Does `an_order' name every row number 1 .. `count' exactly once?
		local
			l_seen: ARRAY [BOOLEAN]
			k: INTEGER
		do
			if an_order.count = count then
				create l_seen.make_filled (False, 1, count)
				Result := True
				from k := an_order.lower until k > an_order.upper or not Result loop
					if an_order [k] < 1 or an_order [k] > count or else l_seen [an_order [k]] then
						Result := False
					else
						l_seen [an_order [k]] := True
					end
					k := k + 1
				end
			end
		end

	set_filter_text (a_text: READABLE_STRING_GENERAL)
			-- Show only the rows whose title contains `a_text', ignoring case; empty shows all.
			-- Row numbers stay the model's. A selected row this hides is deselected and `on_select'
			-- hears 0; clearing the filter does not select it again.
		do
			create filter_text.make_from_string_general (a_text)
			apply_filter
		ensure
			set: filter_text.same_string_general (a_text)
		end

feature -- Test hooks (what the user's hand does)

	press_row_check (a_i: INTEGER)
			-- As the user clicking row `a_i''s check box: it toggles and `on_row_check' is told.
		require
			valid: 1 <= a_i and a_i <= count
			checkable: is_row_checkable (a_i)
		do
			user_toggle (a_i)
		ensure
			toggled: is_row_checked (a_i) = not old is_row_checked (a_i)
		end

	press_row_close (a_i: INTEGER)
			-- As the user clicking row `a_i''s close glyph: the row goes, then `on_row_close' is told.
		require
			valid: 1 <= a_i and a_i <= count
			closable: is_row_closable (a_i)
		do
			user_close (a_i)
		ensure
			one_less: count = old count - 1
		end

feature -- Input

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Arrows and the rest as SW_LIST; Space toggles the selected checkable row, Delete closes
			-- the selected closable one (the user's acts: they notify).
		do
			if a_vk = 32 and then selected_index > 0 and then is_row_checkable (selected_index) then
				space_by_key := True
				user_toggle (selected_index)
			elseif a_vk = 46 and then selected_index > 0 and then is_row_closable (selected_index) then
				user_close (selected_index)
			else
				Precursor (a_vk, a_shift)
			end
		end

	handle_char (a_code: INTEGER)
			-- Space as a typed character (the window sends the key and then the character for one
			-- press; the key already acted).
		do
			if a_code = 32 then
				if space_by_key then
					space_by_key := False
				elseif selected_index > 0 and then is_row_checkable (selected_index) then
					user_toggle (selected_index)
				end
			end
		end

feature {NONE} -- Implementation

	rows: ARRAYED_LIST [STRING_32]

	parts: ARRAYED_LIST [SW_ROW_PARTS]
			-- Each row's parts, parallel to `rows'.

	subtitle_rows: INTEGER
			-- How many rows have a subtitle.

	is_doubled: BOOLEAN
			-- Has `row_height' been doubled for subtitles?

	space_by_key: BOOLEAN
			-- Did a Space key press just toggle, so the character that follows it must not?

	refit_height
			-- Two lines a row while any row has a subtitle, one otherwise.
		do
			if subtitle_rows > 0 and not is_doubled then
				set_row_height (row_height * 2.0)
				is_doubled := True
			elseif subtitle_rows = 0 and is_doubled then
				set_row_height (row_height / 2.0)
				is_doubled := False
			end
		end

	matches_filter (a_i: INTEGER): BOOLEAN
			-- Does row `a_i''s title contain `filter_text', ignoring case?
		do
			Result := filter_text.is_empty or else rows.i_th (a_i).as_lower.has_substring (filter_text.as_lower)
		end

	apply_filter
			-- Build the view from `filter_text' and hand it to the list.
		local
			l_view: ARRAYED_LIST [INTEGER]
			i: INTEGER
		do
			if filter_text.is_empty then
				set_view (Void)
			else
				create l_view.make (rows.count)
				from i := 1 until i > rows.count loop
					if matches_filter (i) then
						l_view.extend (i)
					end
					i := i + 1
				end
				set_view (l_view)
			end
		end

	user_toggle (a_i: INTEGER)
			-- The user toggles row `a_i''s check box.
		do
			parts.i_th (a_i).set_checked (not parts.i_th (a_i).is_checked)
			if attached on_row_check as al_told then
				al_told.call (a_i, parts.i_th (a_i).is_checked)
			end
		end

	user_close (a_i: INTEGER)
			-- The user closes row `a_i'.
		do
			remove_row (a_i)
			if attached on_row_close as al_told then
				al_told.call (a_i)
			end
		end

feature {NONE} -- Row geometry and drawing

	Part_size: REAL_64 = 16.0
			-- A check box, an icon.

	Close_size: REAL_64 = 14.0

	Part_gap: REAL_64 = 8.0

	slot_x (a_rx, a_w, a_offset, a_size: REAL_64; a_leading: BOOLEAN): REAL_64
			-- Left edge of a part `a_size' wide, `a_offset' in from the leading edge (or the
			-- trailing one) of a row at `a_rx' `a_w' wide; the edges swap in right-to-left layout.
		do
			if a_leading /= mirrors_layout then
				Result := a_rx + a_offset
			else
				Result := a_rx + a_w - a_offset - a_size
			end
		end

	leading_used (a_parts: SW_ROW_PARTS): REAL_64
			-- How far the leading parts reach in, up to the title.
		do
			Result := Part_gap
			if a_parts.is_checkable then
				Result := Result + Part_size + Part_gap
			end
			if not a_parts.icon.is_empty then
				Result := Result + Part_size + Part_gap
			end
		end

	trailing_used (a_p: detachable SW_PAINTER; a_parts: SW_ROW_PARTS): REAL_64
			-- How far the trailing parts reach in, up to the title (the badge needs the painter to
			-- measure its number; without one it is not counted).
		do
			Result := Part_gap
			if a_parts.is_closable then
				Result := Result + Close_size + Part_gap
			end
			if a_parts.badge > 0 and then attached a_p as al_p then
				Result := Result + badge_width (al_p, a_parts.badge) + Part_gap
			end
		end

	badge_width (a_p: SW_PAINTER; a_count: INTEGER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, True)
			Result := (a_p.advance (a_count.out) + 12.0).max (18.0)
		end

	inner_width: REAL_64
			-- The width rows are drawn at (as `draw' computes it).
		do
			Result := width - bar.bar_width - 4.0
		end

	row_part_clicked (a_i: INTEGER; a_px, a_py: REAL_64): BOOLEAN
			-- A click on row `a_i''s check box toggles it; on its close glyph closes it.
		local
			l_x: REAL_64
		do
			if a_i >= 1 and a_i <= parts.count then
				if parts.i_th (a_i).is_checkable then
					l_x := slot_x (rows_x, inner_width, Part_gap, Part_size, True)
					if a_px >= l_x - 2.0 and a_px <= l_x + Part_size + 2.0 then
						user_toggle (a_i)
						Result := True
					end
				end
				if not Result and then parts.i_th (a_i).is_closable then
					l_x := slot_x (rows_x, inner_width, Part_gap, Close_size, False)
					if a_px >= l_x - 3.0 and a_px <= l_x + Close_size + 3.0 then
						user_close (a_i)
						Result := True
					end
				end
			end
		end

	render_row (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		local
			l_parts: SW_ROW_PARTS
			t: SW_THEME
			l_lead, l_trail, l_text_w, l_text_x, l_x, l_title_y, l_sub_y, l_mid: REAL_64
			l_glyph: INTEGER
			l_pill: STRING_32
		do
			if a_i >= 1 and a_i <= rows.count then
				l_parts := parts.i_th (a_i)
				t := a_p.theme
				l_mid := a_y + a_h / 2.0
				l_lead := leading_used (l_parts)
				l_trail := trailing_used (a_p, l_parts)
					-- leading: the check box, then the icon
				if l_parts.is_checkable then
					l_x := slot_x (a_x, a_w, Part_gap, Part_size, True)
					if l_parts.is_checked then
						a_p.set_color (t.accent)
						a_p.rrect_fill (l_x, l_mid - Part_size / 2.0, Part_size, Part_size, 3.0)
						a_p.set_color (t.ink_on_accent)
						a_p.glyph ({SW_PAINTER}.Glyph_check, l_x + Part_size / 2.0, l_mid, Part_size - 4.0)
					else
						a_p.set_color (t.outline)
						a_p.rrect_stroke (l_x + 0.5, l_mid - Part_size / 2.0 + 0.5, Part_size - 1.0, Part_size - 1.0, 3.0)
					end
				end
				if not l_parts.icon.is_empty then
					l_glyph := glyph_of_icon_name (l_parts.icon)
					if l_glyph > 0 then
						l_x := slot_x (a_x, a_w, l_lead - Part_gap - Part_size, Part_size, True)
						a_p.set_color (t.ink_muted)
						a_p.glyph (l_glyph, l_x + Part_size / 2.0, l_mid, Part_size)
					end
				end
					-- trailing: the close glyph, then the badge
				if l_parts.is_closable then
					l_x := slot_x (a_x, a_w, Part_gap, Close_size, False)
					a_p.set_color (t.ink_muted)
					a_p.glyph ({SW_PAINTER}.Glyph_close, l_x + Close_size / 2.0, l_mid, Close_size - 3.0)
				end
				if l_parts.badge > 0 then
					l_pill := l_parts.badge.out
					l_x := badge_width (a_p, l_parts.badge)
					l_x := slot_x (a_x, a_w, l_trail - Part_gap - l_x, l_x, False)
					a_p.set_color (t.accent)
					a_p.rrect_fill (l_x, l_mid - 9.0, badge_width (a_p, l_parts.badge), 18.0, 9.0)
					a_p.set_color (t.ink_on_accent)
					a_p.text (l_x + (badge_width (a_p, l_parts.badge) - a_p.advance (l_pill)) / 2.0, l_mid + 4.5, l_pill)
				end
					-- the title and the subtitle between them
				l_text_w := (a_w - l_lead - l_trail).max (0.0)
				if mirrors_layout then
					l_text_x := a_x + l_trail
				else
					l_text_x := a_x + l_lead
				end
				a_p.push_clip (l_text_x, a_y, l_text_w, a_h)
				use_font (a_p, {SW_PAINTER}.Role_ui, t.size_body, False)
				if has_styled_font then
						-- a face of the style's own: centered by its metrics in the row, or in
						-- the upper half over a subtitle
					if is_doubled then
						l_title_y := a_p.baseline_in (a_y, a_h / 2.0)
						l_sub_y := a_y + a_h - 11.0
					else
						l_title_y := a_p.baseline_in (a_y, a_h)
					end
				elseif is_doubled then
					l_title_y := a_y + a_h / 2.0 - 3.0
					l_sub_y := a_y + a_h - 11.0
				else
					l_title_y := a_y + a_h - 9.0
				end
				a_p.set_color (styled_ink (t.ink))
				if mirrors_layout then
						-- W4c: flush right in right-to-left layout.
					a_p.text (l_text_x + l_text_w - a_p.advance (rows.i_th (a_i)), l_title_y, rows.i_th (a_i))
				else
					a_p.text (l_text_x, l_title_y, rows.i_th (a_i))
				end
				if is_doubled and then not l_parts.subtitle.is_empty then
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
					a_p.set_color (t.ink_muted)
					if mirrors_layout then
						a_p.text (l_text_x + l_text_w - a_p.advance (l_parts.subtitle), l_sub_y, l_parts.subtitle)
					else
						a_p.text (l_text_x, l_sub_y, l_parts.subtitle)
					end
				end
				a_p.pop_clip
			end
		end

	shows_style (a_part: INTEGER): BOOLEAN
			-- The list's own parts, and the color and the font of the row titles. (A
			-- subtitle keeps the theme's smaller muted type.)
		do
			Result := Precursor (a_part) or is_text_style_part (a_part)
		end

	set_style (a_style: detachable SW_WIDGET_STYLE)
			-- <Precursor> The rows grow with a type size larger than the theme's.
		local
			l_factor: REAL_64
		do
			Precursor (a_style)
			l_factor := (styled_size (bar_theme.size_body) / bar_theme.size_body).max (1.0)
			if l_factor /= 1.0 + style_row_growth then
				set_row_height (row_height / (1.0 + style_row_growth) * l_factor)
				style_row_growth := l_factor - 1.0
			end
		ensure then
			never_shrunk: style_row_growth >= 0.0
		end

	style_row_growth: REAL_64
			-- How much taller the style's type size has made the rows, as a share of their
			-- height (0: not at all).

	label_of (a_i: INTEGER): READABLE_STRING_GENERAL
		do
			if a_i >= 1 and a_i <= rows.count then
				Result := rows.i_th (a_i)
			else
				Result := ""
			end
		end

invariant
	rows_exist: rows /= Void
	parts_exist: parts /= Void
	counted: row_count = rows.count
	parts_parallel: parts.count = rows.count
	subtitles_counted: subtitle_rows >= 0 and subtitle_rows <= rows.count

end
