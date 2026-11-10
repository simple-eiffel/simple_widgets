note
	description: "[
		A drawn, scrolling grid of cells (simple_gui 1v-a, GUI_GRID_VIEW on Windows): each cell a
		picture (scaled to fit and centered, kept in proportion) or an icon or a blank frame,
		over an ellipsized title and a dimmer subtitle. As many columns as fit the width; it
		scrolls vertically.

		Pictures are decoded one per heartbeat or frame (`decode_next_picture'), the cells in
		view first, so a folder of photos never freezes the window; a cell shows its icon or a
		blank frame until its picture is ready. Only PNG files decode today (simple_cairo).

		Item numbers are the model's everywhere; `set_filter_text' hides cells without changing
		them. `on_select' and `on_activate' tell only of the user's acts; code calls are quiet.
	]"

class
	SW_GRID_VIEW

inherit
	SW_WIDGET
		redefine
			widget_at, handle_wheel, handle_click, handle_drag,
			wants_hover_point, handle_double_click,
			handle_key, accepts_focus, handle_release, set_bounds,
			accessible_role, accessible_item_count, publish_accessible_items, handle_char
		end

	SW_ICON_NAMES

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
			-- An empty grid `a_viewport_height' tall, of 120 by 120 cells.
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			item_width := 120
			item_height := 120
			spacing := 8
			create cells.make (8)
			create selected_set.make (4)
			create filter_text.make_empty
			create bar.make
			create bar_theme.make_light
		ensure
			empty: count = 0
			default_size: item_width = 120 and item_height = 120
		end

feature -- Access

	count: INTEGER
		do
			Result := cells.count
		end

	item_title (a_i: INTEGER): STRING_32
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := cells.i_th (a_i).title
		end

	item_subtitle (a_i: INTEGER): STRING_32
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := cells.i_th (a_i).subtitle
		end

	item_icon (a_i: INTEGER): STRING_32
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := cells.i_th (a_i).icon
		end

	item_picture_path (a_i: INTEGER): STRING_32
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := cells.i_th (a_i).path
		end

	is_picture_ready (a_i: INTEGER): BOOLEAN
			-- Is item `a_i''s picture decoded, so the cell draws it?
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := cells.i_th (a_i).is_picture_ready
		end

	item_width: INTEGER
			-- A cell's width.

	item_height: INTEGER
			-- A cell's height.

	spacing: INTEGER
			-- The gap between cells, and between the cells and the edges.

	viewport_height: REAL_64

	scroll_y: REAL_64

	bar: SW_VSCROLLBAR

	bar_theme: SW_THEME

	filter_text: STRING_32
			-- What a title or subtitle must contain, ignoring case, to show; empty shows all.

	on_select: detachable PROCEDURE [INTEGER]
			-- Told the first selected item (0 for none) after the user's acts.

	on_activate: detachable PROCEDURE [INTEGER]
			-- Told the item after a double click or Return.

	is_multiple: BOOLEAN

	selected_index: INTEGER
			-- The first selected item; 0 for none.
		do
			if not selected_set.is_empty then
				Result := selected_set.first
			end
		end

	selected_count: INTEGER
		do
			Result := selected_set.count
		end

	selected_at (a_k: INTEGER): INTEGER
			-- The `a_k'-th selected item, ascending.
		require
			valid: 1 <= a_k and a_k <= selected_count
		do
			Result := selected_set.i_th (a_k)
		ensure
			an_item: 1 <= Result and Result <= count
		end

	is_item_selected (a_i: INTEGER): BOOLEAN
		do
			Result := selected_set.has (a_i)
		end

feature -- Layout

	columns: INTEGER
			-- How many cells fit across the width (at least one).
		do
			Result := ((inner_width - spacing) / (item_width + spacing)).truncated_to_integer.max (1)
		ensure
			at_least_one: Result >= 1
		end

	cell_rows: INTEGER
			-- How many rows of cells the shown items fill.
		do
			Result := (shown_count + columns - 1) // columns
		end

	row_step: REAL_64
		do
			Result := (item_height + spacing).to_double
		end

	content_height: REAL_64
		do
			if shown_count = 0 then
				Result := 0.0
			else
				Result := spacing + cell_rows * row_step
			end
		ensure
			non_negative: Result >= 0.0
		end

	max_scroll: REAL_64
		do
			Result := (content_height - height).max (0.0)
		end

	cell_x (a_i: INTEGER): REAL_64
			-- Where item `a_i''s cell begins across; the cell must be shown.
		require
			shown: is_shown (a_i)
		do
			Result := rows_x + spacing + ((position_of (a_i) - 1) \\ columns) * (item_width + spacing)
		end

	cell_y (a_i: INTEGER): REAL_64
			-- Where item `a_i''s cell begins down, in window coordinates (scrolling counted).
		require
			shown: is_shown (a_i)
		do
			Result := y + spacing + ((position_of (a_i) - 1) // columns) * row_step - scroll_y
		end

	item_at (a_px, a_py: REAL_64): INTEGER
			-- The item whose cell holds the point; 0 for a gap, the edge or beyond the items.
		local
			l_col, l_row, l_pos: INTEGER
			l_rx, l_ry: REAL_64
		do
			l_rx := a_px - rows_x - spacing
			l_ry := a_py - y + scroll_y - spacing
			if a_py >= y and then l_rx >= 0.0 and then l_ry >= 0.0 then
				l_col := (l_rx / (item_width + spacing)).truncated_to_integer
				l_row := (l_ry / row_step).truncated_to_integer
				if l_col < columns and then l_rx - l_col * (item_width + spacing) < item_width
					and then l_ry - l_row * row_step < item_height
				then
					l_pos := l_row * columns + l_col + 1
					if l_pos >= 1 and l_pos <= shown_count then
						Result := model_at (l_pos)
					end
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

	first_visible: INTEGER
			-- Position (among the shown items) of the first one in the first visible row.
		do
			if shown_count > 0 then
				Result := ((scroll_y - spacing) / row_step).truncated_to_integer.max (0) * columns + 1
				Result := Result.min (shown_count)
			end
		ensure
			in_range: shown_count > 0 implies (Result >= 1 and Result <= shown_count)
		end

	last_visible: INTEGER
			-- Position of the last item in the last visible row.
		do
			if shown_count > 0 then
				Result := ((((scroll_y + height) / row_step).truncated_to_integer + 1) * columns).min (shown_count)
				Result := Result.max (first_visible)
			end
		ensure
			in_range: shown_count > 0 implies (Result >= first_visible and Result <= shown_count)
		end

feature -- Layout (preferred)

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := viewport_height
		end

feature -- Element change

	set_bounds (a_x, a_y, a_w, a_h: REAL_64)
		do
			Precursor (a_x, a_y, a_w, a_h)
			place_bar (bar_theme)
			refit_scroll
		end

	extend (a_title: READABLE_STRING_GENERAL)
			-- An item at the end.
		do
			cells.extend (create {SW_GRID_CELL}.make (a_title))
			if attached view as al_view and then matches_filter (cells.count) then
				al_view.extend (cells.count)
			end
			refit_scroll
		ensure
			one_more: count = old count + 1
			last: item_title (count).same_string_general (a_title)
		end

	set_item_subtitle (a_i: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			valid: 1 <= a_i and a_i <= count
		do
			cells.i_th (a_i).set_subtitle (a_text)
			if not filter_text.is_empty then
				apply_filter
			end
		ensure
			set: item_subtitle (a_i).same_string_general (a_text)
		end

	set_item_icon (a_i: INTEGER; a_name: READABLE_STRING_GENERAL)
			-- Item `a_i' shows the icon named `a_name' (GUI_ICON's names) until a picture is ready.
		require
			valid: 1 <= a_i and a_i <= count
		do
			cells.i_th (a_i).set_icon (a_name)
		ensure
			set: item_icon (a_i).same_string_general (a_name)
		end

	set_item_picture (a_i: INTEGER; a_path: READABLE_STRING_GENERAL)
			-- Item `a_i' shows the picture in file `a_path', scaled to fit, once it is decoded.
		require
			valid: 1 <= a_i and a_i <= count
		do
			cells.i_th (a_i).set_path (a_path)
		ensure
			set: item_picture_path (a_i).same_string_general (a_path)
			not_yet: not a_path.is_empty implies not is_picture_ready (a_i)
		end

	remove_item (a_i: INTEGER)
			-- Take item `a_i' out; later items move up one. Quiet.
		require
			valid: 1 <= a_i and a_i <= count
		local
			k: INTEGER
		do
			selected_set.prune_all (a_i)
			from k := 1 until k > selected_set.count loop
				if selected_set [k] > a_i then
					selected_set [k] := selected_set [k] - 1
				end
				k := k + 1
			end
			if attached view as al_view then
				from k := al_view.count until k < 1 loop
					if al_view [k] = a_i then
						al_view.go_i_th (k)
						al_view.remove
					elseif al_view [k] > a_i then
						al_view [k] := al_view [k] - 1
					end
					k := k - 1
				end
			end
			cells.go_i_th (a_i)
			cells.remove
			cursor := 0
			anchor := 0
			refit_scroll
		ensure
			one_less: count = old count - 1
		end

	wipe_out
			-- Remove every item (the selection goes too, quietly).
		do
			cells.wipe_out
			selected_set.wipe_out
			if attached view then
				view := create {ARRAYED_LIST [INTEGER]}.make (0)
			end
			cursor := 0
			anchor := 0
			refit_scroll
		ensure
			empty: count = 0
			none_selected: selected_count = 0
		end

	set_item_size (a_w, a_h: INTEGER)
		require
			positive: a_w > 0 and a_h > 0
		do
			item_width := a_w
			item_height := a_h
			refit_scroll
		ensure
			set: item_width = a_w and item_height = a_h
		end

	set_spacing (a_n: INTEGER)
		require
			non_negative: a_n >= 0
		do
			spacing := a_n
			refit_scroll
		ensure
			set: spacing = a_n
		end

	set_on_select (a_action: detachable PROCEDURE [INTEGER])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

	set_on_activate (a_action: detachable PROCEDURE [INTEGER])
		do
			on_activate := a_action
		ensure
			set: on_activate = a_action
		end

	set_multiple (a_on: BOOLEAN)
			-- Allow several selected items, or back to one (the first stays).
		local
			l_first: INTEGER
		do
			l_first := selected_index
			is_multiple := a_on
			selected_set.wipe_out
			if l_first > 0 then
				selected_set.extend (l_first)
			end
		ensure
			set: is_multiple = a_on
		end

	select_item_quietly (a_i: INTEGER; a_extend: BOOLEAN)
			-- As the program: select item `a_i' (0 clears), adding it when `a_extend' and several
			-- may be selected. Nobody is told.
		require
			in_range: a_i >= 0 and a_i <= count
		do
			if a_i = 0 then
				selected_set.wipe_out
			elseif a_extend and is_multiple then
				if not selected_set.has (a_i) then
					insert_sorted (a_i)
				end
			else
				selected_set.wipe_out
				selected_set.extend (a_i)
			end
			if a_i > 0 then
				cursor := a_i
				anchor := a_i
			end
		ensure
			chosen: a_i > 0 implies is_item_selected (a_i)
			cleared: a_i = 0 implies selected_count = 0
		end

	scroll_to_item (a_i: INTEGER)
			-- Bring item `a_i' into the viewport (nothing when the filter hides it).
		require
			in_range: a_i >= 1 and a_i <= count
		local
			l_top, l_bottom: REAL_64
		do
			if is_shown (a_i) then
				l_top := spacing + ((position_of (a_i) - 1) // columns) * row_step
				l_bottom := l_top + item_height + spacing
				if height <= 0.0 then
					scroll_y := l_top.min (max_scroll)
				elseif l_top - spacing < scroll_y then
					scroll_y := (l_top - spacing).max (0.0)
				elseif l_bottom > scroll_y + height then
					scroll_y := (l_bottom - height).max (0.0)
				end
			end
		end

	set_filter_text (a_text: READABLE_STRING_GENERAL)
			-- Show only the items whose title or subtitle contains `a_text', ignoring case; empty
			-- shows all. Item numbers stay the model's. A selected item this hides is deselected
			-- and `on_select' hears the new first, or 0; clearing the filter selects nothing again.
		do
			create filter_text.make_from_string_general (a_text)
			apply_filter
		ensure
			set: filter_text.same_string_general (a_text)
		end

feature -- Filtering

	view: detachable ARRAYED_LIST [INTEGER]
			-- The model items shown, ascending; Void: every item shows.

	shown_count: INTEGER
		do
			if attached view as al_view then
				Result := al_view.count
			else
				Result := count
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

	is_shown (a_i: INTEGER): BOOLEAN
		do
			Result := position_of (a_i) > 0
		end

	position_of (a_i: INTEGER): INTEGER
			-- Where item `a_i' sits among the shown ones; 0 when hidden or unknown.
		local
			lo, hi, mid: INTEGER
		do
			if a_i >= 1 and a_i <= count then
				if attached view as al_view then
					lo := 1
					hi := al_view.count
					from until lo > hi or Result > 0 loop
						mid := (lo + hi) // 2
						if al_view.i_th (mid) = a_i then
							Result := mid
						elseif al_view.i_th (mid) < a_i then
							lo := mid + 1
						else
							hi := mid - 1
						end
					end
				else
					Result := a_i
				end
			end
		ensure
			in_range: Result >= 0 and Result <= shown_count
		end

	model_at (a_pos: INTEGER): INTEGER
			-- The item at shown position `a_pos'.
		require
			in_range: a_pos >= 1 and a_pos <= shown_count
		do
			if attached view as al_view then
				Result := al_view.i_th (a_pos)
			else
				Result := a_pos
			end
		ensure
			in_range: Result >= 1 and Result <= count
		end

feature -- Pictures

	pending_pictures: INTEGER
			-- How many pictures still wait to be decoded.
		local
			k: INTEGER
		do
			from k := 1 until k > cells.count loop
				if cells.i_th (k).is_picture_pending then
					Result := Result + 1
				end
				k := k + 1
			end
		ensure
			non_negative: Result >= 0
		end

	decode_next_picture: BOOLEAN
			-- Decode ONE waiting picture, the cells in view first; True when there was one. The
			-- frame (every heartbeat) calls this, so a folder of photos fills in a cell at a time
			-- and drawing is never held for more than one file. It runs on the GUI thread.
		local
			p, l_item: INTEGER
		do
			if shown_count > 0 and then height > 0.0 then
				from p := first_visible until p > last_visible or Result loop
					l_item := model_at (p)
					if cells.i_th (l_item).is_picture_pending then
						cells.i_th (l_item).decode
						Result := True
					end
					p := p + 1
				end
			end
			from p := 1 until p > cells.count or Result loop
				if cells.i_th (p).is_picture_pending then
					cells.i_th (p).decode
					Result := True
				end
				p := p + 1
			end
		ensure
			one_fewer: Result implies pending_pictures = old pending_pictures - 1
		end

feature -- Test hooks (what the user's hand does)

	press_item (a_i: INTEGER; a_ctrl: BOOLEAN)
			-- As the user clicking item `a_i', with Ctrl held or not.
		require
			shown: is_shown (a_i)
		do
			click_item (a_i, a_ctrl, False)
		end

	press_item_shift (a_i: INTEGER)
			-- As the user clicking item `a_i' with Shift held: the range from the last click.
		require
			shown: is_shown (a_i)
		do
			click_item (a_i, False, True)
		end

	activate_by_user (a_i: INTEGER)
			-- As the user double-clicking item `a_i'.
		require
			shown: is_shown (a_i)
		do
			click_item (a_i, False, False)
			tell_activated (a_i)
		end

feature -- Input

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				Result := Current
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			bar.set_extent (height, content_height)
			scroll_y := bar.wheel_scroll (scroll_y, a_delta, row_step)
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			l_item: INTEGER
		do
			bar.set_extent (height, content_height)
			if bar.contains (a_px, a_py) then
				scroll_y := bar.press (a_py, scroll_y)
			else
				l_item := item_at (a_px, a_py)
				if l_item > 0 then
					click_item (l_item, (create {SW_KEYS}).control_down, (create {SW_KEYS}).shift_down)
				end
			end
			Result := True
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		local
			l_item: INTEGER
		do
			if not bar.contains (a_px, a_py) then
				l_item := item_at (a_px, a_py)
				if l_item > 0 then
					click_item (l_item, False, False)
					tell_activated (l_item)
				end
			end
			Result := True
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if bar.is_dragging then
				scroll_y := bar.drag_to (a_py)
			end
		end

	handle_release (a_x, a_y: INTEGER)
		do
			bar.release
		ensure then
			released: not bar.is_dragging
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Arrows move in two dimensions (Up and Down by a row of columns), Home and End go to
			-- the ends, Return activates the selected item, Space toggles the current one in
			-- multiple mode. With Shift in multiple mode a move extends the range.
		local
			l_pos, n, l_target: INTEGER
		do
			n := shown_count
			if n > 0 then
				l_pos := position_of (current_item)
				inspect a_vk
				when 37 then
					l_target := (l_pos - 1).max (1)
				when 39 then
					l_target := (l_pos + 1).min (n)
				when 38 then
					if l_pos = 0 then
						l_target := 1
					elseif l_pos - columns >= 1 then
						l_target := l_pos - columns
					else
						l_target := l_pos
					end
				when 40 then
					if l_pos = 0 then
						l_target := 1
					elseif l_pos + columns <= n then
						l_target := l_pos + columns
					else
						l_target := l_pos
					end
				when 36 then
					l_target := 1
				when 35 then
					l_target := n
				when 13 then
					if selected_index > 0 and then is_shown (selected_index) then
						tell_activated (selected_index)
					end
				when 32 then
					if is_multiple and then current_item > 0 and then is_shown (current_item) then
						toggle_item (current_item)
					end
				else
				end
				if l_target > 0 and then (l_target /= l_pos or else a_shift) then
					move_to (model_at (l_target), a_shift)
				end
			end
		end

	handle_char (a_code: INTEGER)
			-- Keys act through `handle_key'.
		do
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			p, l_item: INTEGER
			l_more: BOOLEAN
		do
			t := a_p.theme
			bar_theme := t
			place_bar (t)
			refit_scroll
			a_p.push_clip (x, y, width, height)
			if shown_count > 0 and then height > 0.0 then
				from p := first_visible until p > last_visible loop
					l_item := model_at (p)
					draw_cell (a_p, l_item, cell_x (l_item), cell_y (l_item), is_item_selected (l_item))
					p := p + 1
				end
			end
			a_p.pop_clip
			bar.draw (a_p, scroll_y, shows_hover and then bar.contains (hover_px, hover_py))
				-- one picture a frame; the next waits for the next heartbeat
			l_more := decode_next_picture
		end

feature -- Accessibility

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_list
		end

	publishes_every_item: BOOLEAN
		do
			Result := shown_count <= {SW_LIST}.Published_rows_cap
		end

	accessible_item_count: INTEGER
			-- The items published as list items.
		do
			if shown_count > 0 then
				if publishes_every_item then
					Result := shown_count
				elseif height > 0.0 then
					Result := (last_visible - first_visible + 1).min ({SW_LIST}.Item_block - 1)
				end
			end
		end

	publish_accessible_items (a_accessibility: SW_ACCESSIBILITY)
			-- Each cell as a list item named by its title.
		local
			k, l_first, l_item: INTEGER
			l_value: detachable STRING_32
		do
			if accessible_item_count > 0 then
				if publishes_every_item then
					l_first := 1
				else
					l_first := first_visible
				end
				from k := 1 until k > accessible_item_count loop
					l_item := model_at (l_first + k - 1)
					if is_item_selected (l_item) then
						l_value := {STRING_32} "selected"
					else
						l_value := Void
					end
					a_accessibility.add_node ({SW_LIST}.Item_ids + (accessible_node_id \\ 200_000) * {SW_LIST}.Item_block + k,
						accessible_node_id, {SW_ACCESSIBILITY}.Role_list_item, cells.i_th (l_item).title, l_value,
						cell_x (l_item), cell_y (l_item), item_width, item_height, False, is_enabled)
					k := k + 1
				end
			end
		end

feature {NONE} -- Implementation

	cells: ARRAYED_LIST [SW_GRID_CELL]

	selected_set: ARRAYED_LIST [INTEGER]
			-- The selected items, ascending.

	cursor: INTEGER
			-- The item the keys move from; 0 until one is clicked or moved to.

	anchor: INTEGER
			-- Where a Shift range starts.

	current_item: INTEGER
			-- The item a key moves from: the cursor, else the first selected.
		do
			if cursor > 0 and then cursor <= count then
				Result := cursor
			else
				Result := selected_index
			end
		end

	inner_width: REAL_64
		do
			Result := width - bar.bar_width - 4.0
		end

	rows_x: REAL_64
		do
			Result := x
			if mirrors_layout then
				Result := x + bar.bar_width + 4.0
			end
		end

	place_bar (a_theme: SW_THEME)
		do
			if mirrors_layout then
				bar.place_at_left (x, y, width, height, a_theme)
			else
				bar.place (x, y, width, height, a_theme)
			end
		end

	refit_scroll
		do
			scroll_y := scroll_y.min (max_scroll).max (0.0)
			bar.set_extent (height, content_height)
		end

	matches_filter (a_i: INTEGER): BOOLEAN
		local
			l_lower: STRING_32
		do
			if filter_text.is_empty then
				Result := True
			else
				l_lower := filter_text.as_lower
				Result := cells.i_th (a_i).title.as_lower.has_substring (l_lower)
					or else cells.i_th (a_i).subtitle.as_lower.has_substring (l_lower)
			end
		end

	apply_filter
			-- Rebuild the view from `filter_text'; drop hidden items from the selection.
		local
			l_view: ARRAYED_LIST [INTEGER]
			i, k: INTEGER
			l_changed: BOOLEAN
		do
			if filter_text.is_empty then
				view := Void
			else
				create l_view.make (cells.count)
				from i := 1 until i > cells.count loop
					if matches_filter (i) then
						l_view.extend (i)
					end
					i := i + 1
				end
				view := l_view
			end
			from k := selected_set.count until k < 1 loop
				if not is_shown (selected_set [k]) then
					selected_set.go_i_th (k)
					selected_set.remove
					l_changed := True
				end
				k := k - 1
			end
			refit_scroll
			if l_changed then
				tell_selected
			end
		ensure
			none_hidden_selected: across selected_set as ic all is_shown (ic) end
		end

	tell_selected
		do
			if attached on_select as al_select then
				al_select.call (selected_index)
			end
		end

	tell_activated (a_i: INTEGER)
		do
			if attached on_activate as al_activate then
				al_activate.call (a_i)
			end
		end

	click_item (a_i: INTEGER; a_ctrl, a_shift: BOOLEAN)
			-- The user's click on item `a_i'.
		do
			if is_multiple and then a_shift and then anchor > 0 and then is_shown (anchor) then
				select_range (anchor, a_i)
				cursor := a_i
			elseif is_multiple and then a_ctrl then
				toggle_item (a_i)
				anchor := a_i
			else
				selected_set.wipe_out
				selected_set.extend (a_i)
				cursor := a_i
				anchor := a_i
			end
			tell_selected
		end

	toggle_item (a_i: INTEGER)
			-- Add item `a_i' to the selection or take it out; it becomes the current one.
		do
			if selected_set.has (a_i) then
				selected_set.prune_all (a_i)
			else
				insert_sorted (a_i)
			end
			cursor := a_i
			anchor := a_i
			tell_selected
		end

	select_range (a_from, a_to: INTEGER)
			-- Select the shown items between `a_from' and `a_to', replacing the selection.
		require
			both_shown: is_shown (a_from) and is_shown (a_to)
		local
			l_lo, l_hi, p: INTEGER
		do
			l_lo := position_of (a_from).min (position_of (a_to))
			l_hi := position_of (a_from).max (position_of (a_to))
			selected_set.wipe_out
			from p := l_lo until p > l_hi loop
				selected_set.extend (model_at (p))
				p := p + 1
			end
		end

	move_to (a_i: INTEGER; a_shift: BOOLEAN)
			-- The user's key moves to item `a_i'.
		do
			if is_multiple and then a_shift and then anchor > 0 and then is_shown (anchor) then
				select_range (anchor, a_i)
			else
				selected_set.wipe_out
				selected_set.extend (a_i)
				anchor := a_i
			end
			cursor := a_i
			scroll_to_item (a_i)
			tell_selected
		end

	insert_sorted (a_i: INTEGER)
		local
			k: INTEGER
		do
			from k := 1 until k > selected_set.count or else selected_set [k] > a_i loop
				k := k + 1
			end
			selected_set.go_i_th (k)
			if k > selected_set.count then
				selected_set.extend (a_i)
			else
				selected_set.put_left (a_i)
			end
		ensure
			added: selected_set.has (a_i)
		end

feature {NONE} -- Cell drawing

	Pad: REAL_64 = 6.0

	Title_band: REAL_64 = 18.0

	Subtitle_band: REAL_64 = 14.0

	has_subtitles: BOOLEAN
		local
			k: INTEGER
		do
			from k := 1 until k > cells.count or Result loop
				Result := not cells.i_th (k).subtitle.is_empty
				k := k + 1
			end
		end

	draw_cell (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y: REAL_64; a_selected: BOOLEAN)
		local
			t: SW_THEME
			l_cell: SW_GRID_CELL
			l_w, l_h, l_pic_h, l_text_y, l_s, l_dw, l_dh, l_pic_w: REAL_64
			l_glyph: INTEGER
			l_hover: BOOLEAN
		do
			t := a_p.theme
			l_cell := cells.i_th (a_i)
			l_w := item_width
			l_h := item_height
			l_hover := shows_hover and then not bar.contains (hover_px, hover_py)
				and then hover_px >= a_x and then hover_px < a_x + l_w
				and then hover_py >= a_y and then hover_py < a_y + l_h
			if a_selected then
				a_p.set_color (t.wash_accent)
				a_p.rrect_fill (a_x, a_y, l_w, l_h, t.radius)
			elseif l_hover then
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (a_x, a_y, l_w, l_h, t.radius)
			end
			l_pic_w := l_w - 2.0 * Pad
			l_pic_h := l_h - 2.0 * Pad - Title_band
			if has_subtitles then
				l_pic_h := l_pic_h - Subtitle_band
			end
			l_pic_h := l_pic_h.max (8.0)
			if attached l_cell.picture as al_picture then
				l_s := (l_pic_w / al_picture.width).min (l_pic_h / al_picture.height)
				l_dw := al_picture.width * l_s
				l_dh := al_picture.height * l_s
				a_p.draw_image (al_picture, a_x + Pad + (l_pic_w - l_dw) / 2.0, a_y + Pad + (l_pic_h - l_dh) / 2.0, l_dw, l_dh)
			else
				l_glyph := glyph_of_icon_name (l_cell.icon)
				if l_glyph > 0 then
					a_p.set_color (t.ink_muted)
					a_p.glyph (l_glyph, a_x + l_w / 2.0, a_y + Pad + l_pic_h / 2.0, l_pic_h.min (l_pic_w).min (48.0))
				else
					a_p.set_color (t.outline)
					a_p.rrect_stroke (a_x + Pad + 0.5, a_y + Pad + 0.5, l_pic_w - 1.0, l_pic_h - 1.0, t.radius)
				end
			end
			l_text_y := a_y + Pad + l_pic_h + 13.0
			a_p.push_clip (a_x, a_y, l_w, l_h)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_body, False)
			a_p.set_color (t.ink)
			draw_centered (a_p, l_cell.title, a_x + Pad, l_text_y, l_pic_w)
			if not l_cell.subtitle.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				a_p.set_color (t.ink_muted)
				draw_centered (a_p, l_cell.subtitle, a_x + Pad, l_text_y + Subtitle_band, l_pic_w)
			end
			a_p.pop_clip
		end

	draw_centered (a_p: SW_PAINTER; a_text: READABLE_STRING_GENERAL; a_x, a_baseline, a_w: REAL_64)
			-- `a_text' centered in `a_w', cut with an ellipsis where it would not fit.
		local
			l_text: STRING_32
		do
			l_text := fitted (a_p, a_text, a_w)
			a_p.text (a_x + (a_w - a_p.advance (l_text)) / 2.0, a_baseline, l_text)
		end

	fitted (a_p: SW_PAINTER; a_text: READABLE_STRING_GENERAL; a_w: REAL_64): STRING_32
			-- `a_text' if it fits `a_w' at the current font, else its head and an ellipsis.
		local
			l_n: INTEGER
		do
			create Result.make_from_string_general (a_text)
			if a_p.advance (Result) > a_w then
				from l_n := Result.count until l_n <= 0 or else a_p.advance (Result.head (l_n) + ellipsis) <= a_w loop
					l_n := l_n - 1
				end
				Result := Result.head (l_n) + ellipsis
			end
		end

	ellipsis: STRING_32
		once
			create Result.make (1)
			Result.append_character ((8230).to_character_32)
		end

invariant
	cells_exist: cells /= Void
	selection_in_range: across selected_set as ic all ic >= 1 and ic <= cells.count end
	one_unless_multiple: not is_multiple implies selected_set.count <= 1
	size_positive: item_width > 0 and item_height > 0
	spacing_non_negative: spacing >= 0
	scroll_bounded: scroll_y >= 0.0
	view_in_range: attached view as al_view implies al_view.count <= cells.count

end
