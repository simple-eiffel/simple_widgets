note
	description: "[
		A virtualized list: the host supplies a row COUNT and a row
		RENDERER agent; only the rows inside the viewport are ever
		drawn, so ten thousand rows scroll like ten. Uniform row
		height in v1. Selection is a single row, painted as an accent
		wash under the renderer's own drawing; the change agent fires
		on selection moves.

		This is the engine EV_GRID's virtual mode promised - drawn
		rows, agent-rendered, contract-bounded.
	]"

class
	SW_LIST

inherit
	SW_WIDGET
		redefine
			widget_at, handle_wheel, handle_click, handle_drag,
			wants_hover_point, pebble_at, handle_double_click,
			handle_key, accepts_focus, handle_release, set_bounds,
			accessible_role, accessible_item_count, publish_accessible_items, handle_char
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			row_height := 30.0
			create bar.make
			create bar_theme.make_light
		ensure
			kept: viewport_height = a_viewport_height
		end

feature -- Access

	row_count: INTEGER

	row_height: REAL_64

	viewport_height: REAL_64

	scroll_y: REAL_64

	bar: SW_VSCROLLBAR
			-- The scrollbar at the right edge.

	bar_theme: SW_THEME
			-- The theme the bar was last sized by (before any draw, light).

feature -- Element change (bounds)

	set_bounds (a_x, a_y, a_w, a_h: REAL_64)
			-- Place the list and its bar.
		do
			Precursor (a_x, a_y, a_w, a_h)
			place_bar (bar_theme)
			bar.set_extent (height, content_height)
		end

	selected_index: INTEGER
			-- 1-based selected row; 0 = none. With several rows selected, the first of them.

	is_multiple: BOOLEAN
			-- May several rows be selected at once (a Ctrl-click adds or removes one)?

	selected_rows: ARRAYED_LIST [INTEGER]
			-- Every selected row, in order.
		do
			if is_multiple then
				Result := selected_set.twin
			else
				create Result.make (1)
				if selected_index > 0 then
					Result.extend (selected_index)
				end
			end
		ensure
			first_is_selected_index: not Result.is_empty implies Result.first = selected_index
		end

	is_row_selected (a_i: INTEGER): BOOLEAN
		do
			if is_multiple then
				Result := selected_set.has (a_i)
			else
				Result := a_i > 0 and a_i = selected_index
			end
		end

	set_multiple (a_on: BOOLEAN)
			-- Allow several selected rows, or back to one (the first stays).
		do
			is_multiple := a_on
			selected_set.wipe_out
			if a_on and selected_index > 0 then
				selected_set.extend (selected_index)
			end
		ensure
			set: is_multiple = a_on
		end

	extend_selection (a_i: INTEGER)
			-- As a Ctrl-click: add row `a_i' to the selection, or take it out; `on_select' is told
			-- the first selected row (0 for none).
		require
			multiple: is_multiple
			in_range: a_i >= 1 and a_i <= row_count
		do
			if selected_set.has (a_i) then
				selected_set.prune_all (a_i)
			else
				insert_sorted (a_i)
			end
			if selected_set.is_empty then
				selected_index := 0
			else
				selected_index := selected_set.first
			end
			if attached on_select as a then
				a.call (selected_index)
			end
		end

	row_renderer: detachable PROCEDURE [SW_PAINTER, INTEGER, REAL_64, REAL_64, REAL_64, REAL_64]
			-- Draws one row: (painter, index, x, y, width, height).

	row_text: detachable FUNCTION [INTEGER, READABLE_STRING_GENERAL]
			-- The text of a row, for screen readers (W6); SW_TEXT_LIST sets it.

	on_select: detachable PROCEDURE [INTEGER]

	on_activate: detachable PROCEDURE [INTEGER]
			-- Fired when a row is double-clicked (after selection).

	row_pebble: detachable FUNCTION [INTEGER, detachable ANY]
			-- Supplies the pebble a given row offers to pick-and-drop.

	row_at (a_py: REAL_64): INTEGER
			-- The row index under viewport y `a_py'; 0 outside content.
		do
			if shown_count > 0 and then a_py >= y then
					-- the guard matters: truncation rounds toward zero,
					-- so a point just ABOVE the list would otherwise
					-- alias to row 1 - the assault suite's first catch.
				Result := ((a_py - y + scroll_y) / row_height).truncated_to_integer + 1
				if Result < 1 or Result > shown_count then
					Result := 0
				else
					Result := model_at (Result)
				end
			end
		ensure
			in_range: Result >= 0 and Result <= row_count
			nothing_above_the_top: a_py < y implies Result = 0
		end

	pebble_at (a_px, a_py: REAL_64): detachable ANY
			-- Rows offer their own pebbles; the scrollbar offers none.
		local
			r: INTEGER
		do
			r := row_at (a_py)
			if r > 0 and then not bar.contains (a_px, a_py) and then attached row_pebble as rp then
				Result := rp.item ([r])
			else
				Result := pebble
			end
		end

	content_height: REAL_64
		do
			Result := shown_count * row_height
		ensure
			non_negative: Result >= 0.0
		end

	max_scroll: REAL_64
		do
			Result := (content_height - height).max (0.0)
		end

	first_visible: INTEGER
			-- Position (among the shown rows) of the first row intersecting the viewport.
		do
			if shown_count > 0 then
				Result := ((scroll_y / row_height).truncated_to_integer + 1)
					.max (1).min (shown_count)
			end
		ensure
			in_range: shown_count > 0 implies (Result >= 1 and Result <= shown_count)
		end

	last_visible: INTEGER
			-- Position of the last row intersecting the viewport.
		do
			if shown_count > 0 then
				Result := (((scroll_y + height) / row_height).truncated_to_integer + 1)
					.max (1).min (shown_count)
			end
		ensure
			ordered: Result >= first_visible or shown_count = 0
		end

feature -- Element change

	set_row_count (a_n: INTEGER)
		require
			non_negative: a_n >= 0
		do
			row_count := a_n
			if attached view as al_view then
				from al_view.finish until al_view.before or else al_view.item <= a_n loop
					al_view.remove
					al_view.finish
				end
			end
			if selected_index > a_n then
				selected_index := 0
			end
			from selected_set.start until selected_set.after loop
				if selected_set.item > a_n then
					selected_set.remove
				else
					selected_set.forth
				end
			end
			if is_multiple and not selected_set.is_empty then
				selected_index := selected_set.first
			end
			scroll_y := scroll_y.min (max_scroll)
			bar.set_extent (height, content_height)
		ensure
			set: row_count = a_n
			selection_still_valid: selected_index <= a_n
		end

	set_row_height (a_h: REAL_64)
		require
			positive: a_h > 0.0
		do
			row_height := a_h
		ensure
			set: row_height = a_h
		end

	set_row_renderer (a_r: PROCEDURE [SW_PAINTER, INTEGER, REAL_64, REAL_64, REAL_64, REAL_64])
		do
			row_renderer := a_r
		ensure
			set: row_renderer = a_r
		end

	set_on_activate (a_action: PROCEDURE [INTEGER])
		do
			on_activate := a_action
		ensure
			set: on_activate = a_action
		end

	set_row_pebble (a_f: FUNCTION [INTEGER, detachable ANY])
		do
			row_pebble := a_f
		ensure
			set: row_pebble = a_f
		end

	set_row_text (a_f: detachable FUNCTION [INTEGER, READABLE_STRING_GENERAL])
			-- Tell screen readers each row's text through `a_f'.
		do
			row_text := a_f
		ensure
			set: row_text = a_f
		end

	set_on_select (a_action: PROCEDURE [INTEGER])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

	accepts_focus: BOOLEAN
			-- Lists join the Tab ring: arrows move the selection.
		do
			Result := True
		end

	page_rows: INTEGER
			-- Rows one PgUp/PgDn stride covers: the live viewport
			-- when laid out, the declared one before.
		local
			vh: REAL_64
		do
			vh := height
			if vh <= 0.0 then
				vh := viewport_height
			end
			Result := (vh / row_height).truncated_to_integer.max (1)
		ensure
			positive: Result >= 1
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Arrows, PgUp/PgDn, Home/End move the selection and
			-- keep it in view - the S04 promise, assaulted headless.
		local
			target, pos, n: INTEGER
		do
			n := shown_count
			if n > 0 then
				pos := position_of (selected_index)
				inspect a_vk
				when 40 then
					target := (pos + 1).min (n).max (1)
				when 38 then
					target := (pos - 1).max (1)
				when 34 then
					target := (pos + page_rows).min (n).max (1)
				when 33 then
					target := (pos - page_rows).max (1)
				when 36 then
					target := 1
				when 35 then
					target := n
				else
					target := 0
				end
				if target > 0 then
					target := model_at (target)
				end
				if target > 0 and target /= selected_index then
					select_row (target)
					scroll_to_row (target)
				end
			end
		end

	select_row (a_i: INTEGER)
		require
			in_range: a_i >= 0 and a_i <= row_count
		do
			selected_index := a_i
			reset_set (a_i)
			if a_i > 0 and then attached on_select as a then
				a.call (a_i)
			end
		ensure
			selected: selected_index = a_i
		end

	select_row_quietly (a_i: INTEGER)
			-- Select row `a_i' (0: none) as the program, not the user: `on_select' does not run
			-- (simple_gui's rule that programmatic changes fire no event, W6).
		require
			in_range: a_i >= 0 and a_i <= row_count
		do
			selected_index := a_i
			reset_set (a_i)
		ensure
			selected: selected_index = a_i
		end

	scroll_to_row (a_i: INTEGER)
			-- Bring row `a_i' into the viewport. Before layout there
			-- is no viewport: the call degrades to 'top the list at
			-- that row', and visibility is only promised once laid
			-- out. (Found by this very postcondition, in live fire.)
		require
			in_range: a_i >= 1 and a_i <= row_count
		local
			l_pos: INTEGER
		do
			l_pos := position_of (a_i)
			if l_pos = 0 then
					-- a row the filter hides has no place to scroll to
			elseif height <= 0.0 then
				scroll_y := (l_pos - 1) * row_height
			elseif (l_pos - 1) * row_height < scroll_y then
				scroll_y := (l_pos - 1) * row_height
			elseif l_pos * row_height > scroll_y + height then
				scroll_y := (l_pos * row_height - height).max (0.0)
			end
		ensure
			visible_once_laid_out: (height > 0.0 and position_of (a_i) > 0) implies
				(position_of (a_i) >= first_visible and position_of (a_i) <= last_visible)
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := viewport_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- Only the visible band of rows is rendered.
		local
			t: SW_THEME
			i, p: INTEGER
			ry, inner_w, rx: REAL_64
		do
			t := a_p.theme
			bar_theme := t
			place_bar (t)
			bar.set_extent (height, content_height)
			scroll_y := scroll_y.min (max_scroll)
			a_p.push_clip (x, y, width, height)
			inner_w := width - bar.bar_width - 4.0
			rx := rows_x
			if shown_count > 0 and then attached row_renderer as rr then
				from
					p := first_visible
				until
					p > last_visible
				loop
					i := model_at (p)
					ry := y + (p - 1) * row_height - scroll_y
					if is_row_selected (i) then
						a_p.set_color (t.wash_accent)
						a_p.fill_rect (rx, ry, inner_w, row_height)
					elseif shows_hover and then not bar.contains (hover_px, hover_py)
						and then hover_py >= ry and then hover_py < ry + row_height
					then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (rx, ry, inner_w, row_height)
					end
					rr.call (a_p, i, rx, ry, inner_w, row_height)
					p := p + 1
				end
			end
			a_p.pop_clip
			bar.draw (a_p, scroll_y, shows_hover and then bar.contains (hover_px, hover_py))
		end

	place_bar (a_theme: SW_THEME)
			-- The scrollbar at the right edge, or the left one in right-to-left layout (W4c).
		do
			if mirrors_layout then
				bar.place_at_left (x, y, width, height, a_theme)
			else
				bar.place (x, y, width, height, a_theme)
			end
		end

	rows_x: REAL_64
			-- Where rows begin: the list's left edge, or past the bar in right-to-left layout.
		do
			Result := x
			if mirrors_layout then
				Result := x + bar.bar_width + 4.0
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				Result := Current
			end
		end

feature -- Input

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			bar.set_extent (height, content_height)
			scroll_y := bar.wheel_scroll (scroll_y, a_delta, row_height)
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
		do
			bar.set_extent (height, content_height)
			if bar.contains (a_px, a_py) then
				scroll_y := bar.press (a_py, scroll_y)
			elseif row_count > 0 then
				i := row_at (a_py)
				if i > 0 and then row_part_clicked (i, a_px, a_py) then
						-- a check box or close glyph took the click
				elseif i > 0 and then is_multiple and then (create {SW_KEYS}).control_down then
					extend_selection (i)
				elseif i > 0 then
					select_row (i)
				end
			end
			Result := True
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
		do
			i := row_at (a_py)
			if i > 0 and then not bar.contains (a_px, a_py) and then row_part_clicked (i, a_px, a_py) then
					-- a check box or close glyph took the click
			elseif i > 0 and not bar.contains (a_px, a_py) then
				select_row (i)
				if attached on_activate as a then
					a.call (i)
				end
			end
			Result := True
		end

	handle_char (a_code: INTEGER)
			-- Rows with parts take Space; the plain list has none.
		do
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if bar.is_dragging then
				scroll_y := bar.drag_to (a_py)
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go of the scrollbar thumb.
		do
			bar.release
		ensure then
			released: not bar.is_dragging
		end


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_list
		end

	Item_ids: INTEGER = 500_000_000
			-- Row node ids: from here up, a block of `Item_block' per list, all below
			-- `SW_WINDOW.Floating_ids' (500_000_000 + 200_000 * 2_048 < 1_000_000_000).

	Item_block: INTEGER = 2_048
			-- Ids per list: more than `Published_rows_cap' rows, so lists never share an id.

	Published_rows_cap: INTEGER = 2_000
			-- Up to this many rows every row is published, as AppKit's AXRows and GTK's
			-- list box do (MACMINI's probe); above it only the visible ones (0.2's limit;
			-- item virtualization comes later).

	publishes_every_row: BOOLEAN
		do
			Result := shown_count <= Published_rows_cap
		end

	accessible_item_count: INTEGER
			-- The rows published as list items.
		do
			if shown_count > 0 then
				if publishes_every_row then
					Result := shown_count
				elseif height > 0.0 then
					Result := (last_visible - first_visible + 1).min (Item_block - 1)
				end
			end
		end

	publish_accessible_items (a_accessibility: SW_ACCESSIBILITY)
			-- Each visible row as a list item under the list, named by `row_text' (else "row N").
		local
			i, l_first, l_last, l_model: INTEGER
			l_name: STRING_32
			l_value: detachable STRING_32
		do
			if accessible_item_count > 0 then
				if publishes_every_row then
					l_first := 1
				else
					l_first := first_visible
				end
				l_last := l_first + accessible_item_count - 1
				from
					i := l_first
				until
					i > l_last
				loop
					l_model := model_at (i)
					if attached row_text as al_text then
						l_name := al_text.item ([l_model]).to_string_32
					else
						l_name := {STRING_32} "row " + l_model.out
					end
					if is_row_selected (l_model) then
						l_value := {STRING_32} "selected"
					else
						l_value := Void
					end
					a_accessibility.add_node (Item_ids + (accessible_node_id \\ 200_000) * Item_block + (i - l_first + 1),
						accessible_node_id, {SW_ACCESSIBILITY}.Role_list_item, l_name, l_value,
						x, y + (i - 1) * row_height - scroll_y, width, row_height, False, is_enabled)
					i := i + 1
				end
			end
		end

feature -- Filtering (simple_gui 1s)

	view: detachable ARRAYED_LIST [INTEGER]
			-- The model rows shown, ascending; Void: every row shows. Row numbers everywhere
			-- stay the model's; only drawing, hit testing and keyboard movement use the view.

	shown_count: INTEGER
			-- How many rows show.
		do
			if attached view as al_view then
				Result := al_view.count
			else
				Result := row_count
			end
		ensure
			in_range: Result >= 0 and Result <= row_count
		end

	is_shown (a_i: INTEGER): BOOLEAN
			-- Does model row `a_i' show?
		do
			Result := position_of (a_i) > 0
		end

	position_of (a_i: INTEGER): INTEGER
			-- Where model row `a_i' sits among the shown rows; 0 when it is hidden or unknown.
		local
			lo, hi, mid: INTEGER
		do
			if a_i >= 1 and a_i <= row_count then
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
			-- The model row at shown position `a_pos'.
		require
			in_range: a_pos >= 1 and a_pos <= shown_count
		do
			if attached view as al_view then
				Result := al_view.i_th (a_pos)
			else
				Result := a_pos
			end
		ensure
			in_range: Result >= 1 and Result <= row_count
		end

	set_view (a_models: detachable ARRAYED_LIST [INTEGER])
			-- Show only the model rows `a_models' (ascending); Void shows every row. A selected row
			-- the view hides is deselected and `on_select' is told with the first row still
			-- selected (0 for none); it is not selected again when the view widens.
		require
			in_range: attached a_models as al_models implies
				across al_models as ic all ic >= 1 and ic <= row_count end
		do
			view := a_models
			scroll_y := scroll_y.min (max_scroll)
			bar.set_extent (height, content_height)
			drop_hidden_selection
		ensure
			set: view = a_models
		end

feature {NONE} -- Row parts and removal (simple_gui 1s)

	row_part_clicked (a_i: INTEGER; a_px, a_py: REAL_64): BOOLEAN
			-- Did the click at the point fall on a part of row `a_i' (a check box, a close glyph),
			-- and was it taken? Rows with no parts answer False.
		do
		end

	drop_hidden_selection
			-- Deselect every selected row the view hides; `on_select' hears the outcome.
		local
			k: INTEGER
			l_changed: BOOLEAN
		do
			if is_multiple then
				from k := selected_set.count until k < 1 loop
					if not is_shown (selected_set [k]) then
						selected_set.go_i_th (k)
						selected_set.remove
						l_changed := True
					end
					k := k - 1
				end
				if selected_set.is_empty then
					selected_index := 0
				else
					selected_index := selected_set.first
				end
			elseif selected_index > 0 and then not is_shown (selected_index) then
				selected_index := 0
				l_changed := True
			end
			if l_changed and then attached on_select as al_select then
				al_select.call (selected_index)
			end
		ensure
			none_hidden_selected: selected_index = 0 or else is_shown (selected_index)
		end

	selection_after_removal (a_i: INTEGER)
			-- Row `a_i' is going: it leaves the selection and every later row moves up one (quietly).
			-- The caller then lowers `row_count' by one.
		require
			in_range: a_i >= 1 and a_i <= row_count
		local
			k: INTEGER
		do
			if is_multiple then
				selected_set.prune_all (a_i)
				from k := 1 until k > selected_set.count loop
					if selected_set [k] > a_i then
						selected_set [k] := selected_set [k] - 1
					end
					k := k + 1
				end
				if selected_set.is_empty then
					selected_index := 0
				else
					selected_index := selected_set.first
				end
			elseif selected_index = a_i then
				selected_index := 0
			elseif selected_index > a_i then
				selected_index := selected_index - 1
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
		end

	selection_after_reorder (a_new_of_old: ARRAY [INTEGER])
			-- The rows were renumbered: old row `r' is now row `a_new_of_old [r]'. The selection goes
			-- with its rows, quietly.
		require
			one_each: a_new_of_old.count = row_count
		local
			l_old: ARRAYED_LIST [INTEGER]
		do
			if is_multiple then
				l_old := selected_set.twin
				selected_set.wipe_out
				across l_old as ic loop
					insert_sorted (a_new_of_old [a_new_of_old.lower + ic - 1])
				end
				if selected_set.is_empty then
					selected_index := 0
				else
					selected_index := selected_set.first
				end
			elseif selected_index > 0 then
				selected_index := a_new_of_old [a_new_of_old.lower + selected_index - 1]
			end
		end

feature {NONE} -- Several rows (simple_gui 1p)

	selected_set: ARRAYED_LIST [INTEGER]
			-- The selected rows, ascending, while `is_multiple'.
		attribute
			create Result.make (4)
		end

	reset_set (a_i: INTEGER)
			-- Only row `a_i' (0: none) selected.
		do
			selected_set.wipe_out
			if is_multiple and a_i > 0 then
				selected_set.extend (a_i)
			end
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

invariant
	rows_non_negative: row_count >= 0
	row_height_positive: row_height > 0.0
	selection_in_range: selected_index >= 0 and selected_index <= row_count
	one_unless_multiple: not is_multiple implies selected_set.is_empty
	first_of_several: (is_multiple and not selected_set.is_empty) implies selected_index = selected_set.first
	scroll_bounded: scroll_y >= 0.0
	view_in_range: attached view as al_view implies al_view.count <= row_count

end
