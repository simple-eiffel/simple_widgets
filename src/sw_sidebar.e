note
	description: "[
		A navigation list beside pages (simple_gui 1t): a list of titles on the leading side,
		the selected page filling the rest. Pages are added with `extend'; `add_heading' puts
		a small dim group heading before the next page (not selectable, not a page).
		Each page may carry a named icon (`set_page_icon', the names SW_TEXT_LIST draws) and a
		badge pill at the row's trailing edge.

		Notices follow the quiet-from-code rule: `select_page', `collapse' and `expand' never
		notify; the user's act does - a click on a row, Return or Space on the keyboard
		cursor, the collapse button (`on_page_change', `on_collapse_change').

		Keys (the list has the focus): Up and Down move a cursor over the PAGES (headings
		are not stops), Home and End go to the first and last, Return or Space shows the
		page under the cursor, as a click does. The selection does not follow the cursor:
		a page may be heavy and Settings-style panes show it only on a choice.

		Collapsed, the list is narrow: an icon per page (a page with none shows its title's
		first letter in a small filled circle), headings hidden, and the hovered row's title
		as a tooltip. The list sits on `theme.surface_variant', the selected row on the
		accent, headings small, dim and bold.
	]"

class
	SW_SIDEBAR

inherit
	SW_WIDGET
		redefine
			sub_widgets, arrange, widget_at, handle_click, wants_hover_point, set_hover_point,
			tooltip_anchor, accepts_focus, handle_key,
			accessible_role, accessible_children, accessible_item_count, publish_accessible_items
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create pages.make (4)
			create row_pages.make (8)
			create row_texts.make (8)
			create page_rows.make (4)
			create page_icons.make (4)
			create page_badges.make (4)
			create row_tops.make (8)
			create row_hs.make (8)
			create icon_names_source.make (1.0)
			row_h := 36.0
			heading_h := 24.0
			list_w := 200.0
			pad := 8.0
		end

feature -- Access

	pages: ARRAYED_LIST [SW_WIDGET]
			-- The pages, in order (headings are not here).

	page_count: INTEGER
		do
			Result := pages.count
		end

	selected_page: INTEGER
			-- The shown page, 1-based; 0 only while empty.

	cursor_page: INTEGER
			-- The page the keyboard cursor stands on (Up, Down, then Return or Space).

	page_title (a_i: INTEGER): STRING_32
		require
			in_range: a_i >= 1 and a_i <= page_count
		do
			Result := row_texts.i_th (page_rows.i_th (a_i)).twin
		end

	page_icon (a_i: INTEGER): STRING_32
			-- The icon name given to page `a_i'; empty for none.
		require
			in_range: a_i >= 1 and a_i <= page_count
		do
			Result := page_icons.i_th (a_i).twin
		end

	page_badge (a_i: INTEGER): STRING_32
			-- The badge text of page `a_i'; empty for none.
		require
			in_range: a_i >= 1 and a_i <= page_count
		do
			Result := page_badges.i_th (a_i).twin
		end

	page_glyph (a_i: INTEGER): INTEGER
			-- The glyph page `a_i''s icon name draws; 0 for no icon or an unknown name.
		require
			in_range: a_i >= 1 and a_i <= page_count
		do
			if page_icons.i_th (a_i).is_empty then
				Result := 0
			else
				Result := icon_names_source.glyph_of_icon_name (page_icons.i_th (a_i))
			end
		end

	row_count: INTEGER
			-- Rows in the list: pages and headings.
		do
			Result := row_pages.count
		end

	is_heading_row (a_r: INTEGER): BOOLEAN
		require
			in_range: a_r >= 1 and a_r <= row_count
		do
			Result := row_pages.i_th (a_r) = 0
		end

	on_page_change: detachable PROCEDURE [INTEGER]
			-- Called with the page the USER chose (never for code).

	on_collapse_change: detachable PROCEDURE [BOOLEAN]
			-- Called with `is_collapsed' after the USER's collapse button (never for code).

	is_collapsible: BOOLEAN
			-- Does the list show a collapse button at its foot?

	is_collapsed: BOOLEAN
			-- Is the list narrow, icons only?

feature -- Measurement

	row_h: REAL_64
			-- A page row's height (set by arrange from the font and theme).

	heading_h: REAL_64
			-- A heading row's height.

	list_w: REAL_64
			-- The list's width now: about 200 logical units open, narrow collapsed.

	pad: REAL_64
			-- The list's inner padding: the theme's `padding'.

	is_placed: BOOLEAN
			-- Do the row boxes match the rows (an arrange has run since they last changed)?
		do
			Result := row_tops.count = row_pages.count
		end

	list_left: REAL_64
			-- The list's left edge: the widget's, or its right side when the layout mirrors.
		do
			if mirrors_layout then
				Result := x + width - list_w
			else
				Result := x
			end
		end

	page_row_box (a_i: INTEGER): TUPLE [x, y, w, h: REAL_64]
			-- Where page `a_i''s row stands (its height 0 when not placed).
		require
			in_range: a_i >= 1 and a_i <= page_count
		local
			l_r: INTEGER
		do
			l_r := page_rows.i_th (a_i)
			if is_placed then
				Result := [list_left, row_tops.i_th (l_r), list_w, row_hs.i_th (l_r)]
			else
				Result := [list_left, y, list_w, 0.0]
			end
		end

	heading_row_box (a_r: INTEGER): TUPLE [x, y, w, h: REAL_64]
			-- Where row `a_r' (a heading) stands; its height is 0 while collapsed.
		require
			in_range: a_r >= 1 and a_r <= row_count
		do
			if is_placed then
				Result := [list_left, row_tops.i_th (a_r), list_w, row_hs.i_th (a_r)]
			else
				Result := [list_left, y, list_w, 0.0]
			end
		end

	collapse_button_box: TUPLE [x, y, w, h: REAL_64]
			-- The collapse button's box at the list's foot.
		do
			Result := [list_left, y + height - row_h, list_w, row_h]
		end

	row_at (a_px, a_py: REAL_64): INTEGER
			-- The row (page or heading) under the point; 0 elsewhere. Hidden headings have no box.
		local
			r: INTEGER
		do
			if is_placed and then a_px >= list_left and then a_px < list_left + list_w then
				from
					r := 1
				until
					r > row_tops.count or Result > 0
				loop
					if row_hs.i_th (r) > 0.0 and then a_py >= row_tops.i_th (r) and then a_py < row_tops.i_th (r) + row_hs.i_th (r) then
						Result := r
					end
					r := r + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= row_count
		end

	page_at (a_px, a_py: REAL_64): INTEGER
			-- The page whose row holds the point; 0 on a heading or elsewhere.
		local
			l_r: INTEGER
		do
			l_r := row_at (a_px, a_py)
			if l_r > 0 then
				Result := row_pages.i_th (l_r)
			end
		ensure
			in_range: Result >= 0 and Result <= page_count
		end

	on_collapse_button (a_px, a_py: REAL_64): BOOLEAN
			-- Is the point on the collapse button?
		local
			l_box: TUPLE [x, y, w, h: REAL_64]
		do
			if is_collapsible then
				l_box := collapse_button_box
				Result := a_px >= l_box.x and then a_px < l_box.x + l_box.w and then a_py >= l_box.y and then a_py < l_box.y + l_box.h
			end
		end

	circle_diameter (a_theme: SW_THEME): REAL_64
			-- The filled circle that stands for an icon-less page while collapsed: 20 units at 1x.
		do
			Result := 20.0 * a_theme.text_scale
		end

	letter_of (a_i: INTEGER): STRING_32
			-- The first letter of page `a_i''s title, upper case ("?" for an empty title).
		require
			in_range: a_i >= 1 and a_i <= page_count
		local
			l_title: STRING_32
		do
			l_title := row_texts.i_th (page_rows.i_th (a_i))
			create Result.make (1)
			if l_title.is_empty then
				Result.append_character ('?')
			else
				Result.append_character (l_title.item (1).as_upper)
			end
		ensure
			one_letter: Result.count = 1
		end

feature -- Element change

	extend (a_page: SW_WIDGET; a_title: READABLE_STRING_GENERAL)
			-- Add `a_page' with a row titled `a_title'; the first page added is shown.
		local
			l_title: STRING_32
		do
			create l_title.make_from_string_general (a_title)
			pages.extend (a_page)
			row_pages.extend (pages.count)
			row_texts.extend (l_title)
			page_rows.extend (row_pages.count)
			page_icons.extend (create {STRING_32}.make_empty)
			page_badges.extend (create {STRING_32}.make_empty)
			a_page.set_parent (Current)
			if selected_page = 0 then
				selected_page := 1
				cursor_page := 1
			end
			forget_placement
		ensure
			grew: pages.count = old pages.count + 1
			adopted: a_page.parent = Current
			titled: page_title (pages.count).same_string_general (a_title)
			one_row_more: row_count = old row_count + 1
			something_selected: selected_page >= 1
		end

	add_heading (a_text: READABLE_STRING_GENERAL)
			-- A group heading row before the next page: not selectable, not a page.
		local
			l_text: STRING_32
		do
			create l_text.make_from_string_general (a_text)
			row_pages.extend (0)
			row_texts.extend (l_text)
			forget_placement
		ensure
			one_row_more: row_count = old row_count + 1
			not_a_page: page_count = old page_count
			a_heading: is_heading_row (row_count)
		end

	set_page_icon (a_i: INTEGER; a_name: READABLE_STRING_GENERAL)
			-- Draw the named icon (the names SW_TEXT_LIST knows) on page `a_i''s row; empty removes it.
		require
			in_range: a_i >= 1 and a_i <= page_count
		do
			page_icons.put_i_th (create {STRING_32}.make_from_string_general (a_name), a_i)
		ensure
			set: page_icon (a_i).same_string_general (a_name)
		end

	set_page_badge (a_i: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- A small pill with `a_text' at the row's trailing edge; empty removes it.
		require
			in_range: a_i >= 1 and a_i <= page_count
			short: a_text.count <= 8
		do
			page_badges.put_i_th (create {STRING_32}.make_from_string_general (a_text), a_i)
		ensure
			set: page_badge (a_i).same_string_general (a_text)
		end

	select_page (a_i: INTEGER)
			-- Show page `a_i', quietly (code, not the user).
		require
			in_range: a_i >= 1 and a_i <= page_count
		do
			selected_page := a_i
			cursor_page := a_i
		ensure
			selected: selected_page = a_i
		end

	set_on_page_change (a_action: detachable PROCEDURE [INTEGER])
		do
			on_page_change := a_action
		ensure
			set: on_page_change = a_action
		end

	set_on_collapse_change (a_action: detachable PROCEDURE [BOOLEAN])
		do
			on_collapse_change := a_action
		ensure
			set: on_collapse_change = a_action
		end

	set_collapsible (a_on: BOOLEAN)
			-- Show a collapse button at the list's foot (turning it off opens a collapsed list).
		do
			is_collapsible := a_on
			if not a_on then
				is_collapsed := False
			end
			forget_placement
		ensure
			set: is_collapsible = a_on
			open_without_button: not a_on implies not is_collapsed
		end

	collapse
			-- Narrow the list to icons, quietly.
		do
			is_collapsed := True
			forget_placement
		ensure
			collapsed: is_collapsed
		end

	expand
			-- Widen the list again, quietly.
		do
			is_collapsed := False
			forget_placement
		ensure
			open: not is_collapsed
		end

feature -- The user's acts (and test hooks)

	press_page (a_i: INTEGER)
			-- The user chooses page `a_i' (a click on its row): it shows, and `on_page_change' hears it
			-- when the page is a different one.
		require
			in_range: a_i >= 1 and a_i <= page_count
		do
			cursor_page := a_i
			if a_i /= selected_page then
				selected_page := a_i
				if attached on_page_change as al_action then
					al_action.call (a_i)
				end
			end
		ensure
			selected: selected_page = a_i
			cursor_follows: cursor_page = a_i
		end

	press_collapse_button
			-- The user presses the collapse button: collapsed becomes open and open collapsed, and
			-- `on_collapse_change' hears it.
		require
			has_button: is_collapsible
		do
			if is_collapsed then
				expand
			else
				collapse
			end
			if attached on_collapse_change as al_action then
				al_action.call (is_collapsed)
			end
		ensure
			toggled: is_collapsed = not old is_collapsed
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (pages.count)
			across
				pages as pg
			loop
				Result.extend (pg)
			end
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			measure (a_p)
			Result := row_count * row_h
			if attached shown_page as pg then
				Result := Result.max (pg.clamped_height (pg.preferred_height (a_p, (a_width - list_w).max (1.0))))
			end
		end

	arrange (a_p: SW_PAINTER)
			-- Measure, stack the rows, then lay the shown page out beside the list.
		local
			r: INTEGER
			l_top, l_h: REAL_64
		do
			measure (a_p)
			row_tops.wipe_out
			row_hs.wipe_out
			l_top := y + pad / 2.0
			from
				r := 1
			until
				r > row_pages.count
			loop
				if row_pages.i_th (r) > 0 then
					l_h := row_h
				elseif is_collapsed then
					l_h := 0.0
				else
					l_h := heading_h
				end
				row_tops.extend (l_top)
				row_hs.extend (l_h)
				l_top := l_top + l_h
				r := r + 1
			end
			if attached shown_page as pg then
				if mirrors_layout then
					pg.set_bounds (x, y, (width - list_w).max (0.0), height)
				else
					pg.set_bounds (x + list_w, y, (width - list_w).max (0.0), height)
				end
				pg.arrange (a_p)
			end
		ensure then
			placed: is_placed
		end

feature -- Hover and tooltip

	set_hover_point (a_px, a_py: REAL_64)
			-- Collapsed, the title of the row under the pointer becomes the tooltip.
		local
			l_r: INTEGER
		do
			Precursor (a_px, a_py)
			l_r := row_at (a_px, a_py)
			if is_collapsed and then l_r > 0 and then row_pages.i_th (l_r) > 0 then
				set_tooltip (row_texts.i_th (l_r))
			else
				set_tooltip ("")
			end
		end

	tooltip_anchor: TUPLE [x, y, w, h: REAL_64]
			-- Collapsed: the hovered row, the hint hanging beside the narrow list.
		local
			l_r: INTEGER
			l_left: REAL_64
		do
			l_r := row_at (hover_px, hover_py)
			if is_collapsed and then l_r > 0 then
				if mirrors_layout then
					l_left := list_left - 4.0
				else
					l_left := list_left + list_w + 4.0
				end
				Result := [l_left, row_tops.i_th (l_r), 0.0, row_hs.i_th (l_r)]
			else
				Result := Precursor
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			r: INTEGER
		do
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (list_left, y, list_w, height)
			if mirrors_layout then
				a_p.vline (list_left, y, height)
			else
				a_p.vline (list_left + list_w - 1.0, y, height)
			end
			if is_placed then
				from
					r := 1
				until
					r > row_pages.count
				loop
					if row_hs.i_th (r) > 0.0 then
						if row_pages.i_th (r) = 0 then
							draw_heading (a_p, r)
						else
							draw_page_row (a_p, r)
						end
					end
					r := r + 1
				end
			end
			if is_collapsible then
				draw_collapse_button (a_p)
			end
			if attached shown_page as pg then
				pg.draw (a_p)
			end
		end

feature -- Input

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A press on a row chooses its page; on the button, collapses or expands.
		local
			l_page: INTEGER
		do
			if is_enabled and then contains (a_px, a_py) and then a_px >= list_left and then a_px < list_left + list_w then
				Result := True
				if on_collapse_button (a_px, a_py) then
					press_collapse_button
				else
					l_page := page_at (a_px, a_py)
					if l_page > 0 then
						press_page (l_page)
					end
				end
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Up and Down move the cursor over the pages (headings are not stops, there is no
			-- wrapping), Home and End go to the ends, Return or Space shows the page under it.
		do
			if is_enabled and then page_count > 0 then
				if cursor_page < 1 then
					cursor_page := selected_page.max (1)
				end
				inspect a_vk
				when 38 then
					cursor_page := (cursor_page - 1).max (1)
				when 40 then
					cursor_page := (cursor_page + 1).min (page_count)
				when 36 then
					cursor_page := 1
				when 35 then
					cursor_page := page_count
				when 13, 32 then
					press_page (cursor_page)
				else
				end
			end
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if a_px >= list_left and then a_px < list_left + list_w then
					Result := Current
				elseif attached shown_page as pg then
					Result := pg.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Accessibility

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_list
		end

	accessible_item_count: INTEGER
			-- Each page's row, published as a list item (headings are not items).
		do
			Result := page_count.min (2_047)
		end

	publish_accessible_items (a_accessibility: SW_ACCESSIBILITY)
		local
			i: INTEGER
			l_value: detachable STRING_32
			l_box: TUPLE [x, y, w, h: REAL_64]
		do
			from
				i := 1
			until
				i > accessible_item_count
			loop
				if i = selected_page then
					l_value := {STRING_32} "selected"
				else
					l_value := Void
				end
				l_box := page_row_box (i)
				a_accessibility.add_node (accessible_item_id (i), accessible_node_id, {SW_ACCESSIBILITY}.Role_list_item,
					page_title (i), l_value, l_box.x, l_box.y, l_box.w, l_box.h, False, is_enabled)
				i := i + 1
			end
		end

	accessible_children: ARRAYED_LIST [SW_WIDGET]
			-- Only the shown page.
		do
			create Result.make (1)
			if attached shown_page as al_page then
				Result.extend (al_page)
			end
		end

feature {NONE} -- Implementation

	row_pages: ARRAYED_LIST [INTEGER]
			-- Per row: its page number, or 0 for a heading.

	row_texts: ARRAYED_LIST [STRING_32]
			-- Per row: the page's title or the heading's text.

	page_rows: ARRAYED_LIST [INTEGER]
			-- Per page: its row.

	page_icons: ARRAYED_LIST [STRING_32]

	page_badges: ARRAYED_LIST [STRING_32]

	row_tops: ARRAYED_LIST [REAL_64]
			-- Per row: its top, set by arrange.

	row_hs: ARRAYED_LIST [REAL_64]
			-- Per row: its height (0 for a heading while collapsed), set by arrange.

	icon_names_source: SW_TEXT_LIST
			-- Kept only for its icon-name table (`glyph_of_icon_name'), so the two never drift.

	shown_page: detachable SW_WIDGET
		do
			if selected_page >= 1 and selected_page <= pages.count then
				Result := pages.i_th (selected_page)
			end
		end

	forget_placement
		do
			row_tops.wipe_out
			row_hs.wipe_out
		ensure
			unplaced: row_tops.is_empty and row_hs.is_empty
		end

	measure (a_p: SW_PAINTER)
			-- Row heights and the list's width from the theme and the fonts.
		local
			t: SW_THEME
		do
			t := a_p.theme
			pad := t.padding
			a_p.font ({SW_PAINTER}.Role_ui, t.size_body, False)
			row_h := a_p.text_extent + t.control_inset * 1.5
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label * 0.85, True)
			heading_h := a_p.text_extent + pad * 1.5
			if is_collapsed then
				list_w := row_h + 2.0 * pad
			else
				list_w := 200.0 * t.text_scale
			end
			list_w := list_w.min (width).max (1.0)
		ensure
			positive: row_h > 0.0 and heading_h > 0.0 and list_w >= 1.0
		end

	draw_heading (a_p: SW_PAINTER; a_r: INTEGER)
			-- A small, dim, bold heading.
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label * 0.85, True)
			a_p.set_color (t.ink_muted)
			a_p.push_clip (list_left, row_tops.i_th (a_r), list_w, row_hs.i_th (a_r))
			a_p.text (list_left + pad + tab_inset_of (t), row_tops.i_th (a_r) + (row_hs.i_th (a_r) - a_p.text_extent) / 2.0 + a_p.font_ascent + pad / 4.0, row_texts.i_th (a_r))
			a_p.pop_clip
		end

	tab_inset_of (a_theme: SW_THEME): REAL_64
			-- The row ground's side inset: half the theme's padding.
		do
			Result := a_theme.padding / 2.0
		end

	draw_page_row (a_p: SW_PAINTER; a_r: INTEGER)
			-- A page's row: ground (accent when selected, quiet when hovered), icon or letter
			-- circle, title and badge (open), or icon and a badge dot (collapsed).
		local
			t: SW_THEME
			l_page, l_glyph: INTEGER
			l_selected, l_hovered: BOOLEAN
			l_ink: NATURAL_32
			l_left, l_top, l_h, l_inset, l_icon, l_cx, l_cy, l_text_x, l_text_w, l_pill_w, l_pill_x, l_r: REAL_64
			l_badge: STRING_32
		do
			t := a_p.theme
			l_page := row_pages.i_th (a_r)
			l_selected := l_page = selected_page
			l_hovered := shows_hover and then row_at (hover_px, hover_py) = a_r
			l_inset := tab_inset_of (t)
			l_left := list_left + l_inset
			l_top := row_tops.i_th (a_r)
			l_h := row_hs.i_th (a_r)
			if l_selected then
				a_p.set_color (t.accent)
				a_p.rrect_fill (l_left, l_top, list_w - 2.0 * l_inset - 1.0, l_h, t.radius)
				l_ink := t.ink_on_accent
			elseif l_hovered then
				a_p.set_color (t.divider)
				a_p.rrect_fill (l_left, l_top, list_w - 2.0 * l_inset - 1.0, l_h, t.radius)
				l_ink := t.ink
			else
				l_ink := t.ink
			end
			if is_focused and then l_page = cursor_page then
				a_p.set_color (t.ink)
				a_p.rrect_stroke (l_left + 0.5, l_top + 0.5, list_w - 2.0 * l_inset - 2.0, l_h - 1.0, t.radius)
			end
			a_p.font ({SW_PAINTER}.Role_ui, t.size_body, False)
			l_icon := a_p.text_extent * 0.9
			l_cy := l_top + l_h / 2.0
			l_glyph := page_glyph (l_page)
			l_badge := page_badges.i_th (l_page)
			if is_collapsed then
				l_cx := list_left + (list_w - 1.0) / 2.0
				if l_glyph > 0 then
					a_p.set_color (l_ink)
					a_p.glyph (l_glyph, l_cx, l_cy, l_icon)
				else
					l_r := circle_diameter (t) / 2.0
					if l_selected then
						a_p.set_color (t.ink_on_accent)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.circle_fill (l_cx, l_cy, l_r)
					if l_selected then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.surface_variant)
					end
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
					a_p.text (l_cx - a_p.advance (letter_of (l_page)) / 2.0, l_cy - a_p.text_extent / 2.0 + a_p.font_ascent, letter_of (l_page))
				end
				if not l_badge.is_empty then
					if l_selected then
						a_p.set_color (t.ink_on_accent)
					else
						a_p.set_color (t.accent)
					end
					a_p.circle_fill (l_cx + l_icon / 2.0, l_cy - l_icon / 2.0, 4.0)
				end
			else
				l_text_x := list_left + pad + l_inset
				if l_glyph > 0 then
					a_p.set_color (l_ink)
					a_p.glyph (l_glyph, l_text_x + l_icon / 2.0, l_cy, l_icon)
				end
				l_text_x := l_text_x + l_icon + pad
				l_text_w := list_left + list_w - l_inset - pad - l_text_x
				if not l_badge.is_empty then
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
					l_pill_w := a_p.advance (l_badge) + 12.0
					l_pill_x := list_left + list_w - l_inset - pad - l_pill_w
					l_text_w := l_pill_x - pad - l_text_x
					if l_selected then
						a_p.set_color (t.ink_on_accent)
					else
						a_p.set_color (t.accent)
					end
					a_p.rrect_fill (l_pill_x, l_cy - 9.0, l_pill_w, 18.0, 9.0)
					if l_selected then
						a_p.set_color (t.accent)
					else
						a_p.set_color (t.ink_on_accent)
					end
					a_p.text (l_pill_x + 6.0, l_cy - a_p.text_extent / 2.0 + a_p.font_ascent, l_badge)
				end
				a_p.font ({SW_PAINTER}.Role_ui, t.size_body, False)
				a_p.set_color (l_ink)
				a_p.push_clip (l_text_x, l_top, l_text_w.max (0.0), l_h)
				a_p.text (l_text_x, l_cy - a_p.text_extent / 2.0 + a_p.font_ascent, row_texts.i_th (a_r))
				a_p.pop_clip
			end
		end

	draw_collapse_button (a_p: SW_PAINTER)
			-- A chevron at the foot: pointing in while open (it collapses), out while collapsed.
		local
			t: SW_THEME
			l_box: TUPLE [x, y, w, h: REAL_64]
			l_cx: REAL_64
		do
			t := a_p.theme
			l_box := collapse_button_box
			a_p.hline (l_box.x, l_box.y, l_box.w - 1.0)
			if shows_hover and then on_collapse_button (hover_px, hover_py) then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			if is_collapsed then
				l_cx := l_box.x + (l_box.w - 1.0) / 2.0
				a_p.glyph ({SW_PAINTER}.Glyph_chevron_right, l_cx, l_box.y + l_box.h / 2.0, l_box.h * 0.45)
			else
				l_cx := l_box.x + l_box.w - pad - l_box.h * 0.5
				a_p.glyph ({SW_PAINTER}.Glyph_chevron_left, l_cx, l_box.y + l_box.h / 2.0, l_box.h * 0.45)
			end
		end

invariant
	parallel_pages: page_rows.count = pages.count and page_icons.count = pages.count and page_badges.count = pages.count
	parallel_rows: row_texts.count = row_pages.count
	parallel_boxes: row_tops.count = row_hs.count
	selection_in_range: selected_page >= 0 and selected_page <= pages.count
	selected_when_populated: pages.count > 0 implies selected_page >= 1
	cursor_in_range: cursor_page >= 0 and cursor_page <= pages.count

end
