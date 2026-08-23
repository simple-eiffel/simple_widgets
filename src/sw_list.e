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
			handle_key, accepts_focus
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
		ensure
			kept: viewport_height = a_viewport_height
		end

feature -- Access

	row_count: INTEGER

	row_height: REAL_64

	viewport_height: REAL_64

	scroll_y: REAL_64

	selected_index: INTEGER
			-- 1-based selected row; 0 = none.

	row_renderer: detachable PROCEDURE [SW_PAINTER, INTEGER, REAL_64, REAL_64, REAL_64, REAL_64]
			-- Draws one row: (painter, index, x, y, width, height).

	on_select: detachable PROCEDURE [INTEGER]

	on_activate: detachable PROCEDURE [INTEGER]
			-- Fired when a row is double-clicked (after selection).

	row_pebble: detachable FUNCTION [INTEGER, detachable ANY]
			-- Supplies the pebble a given row offers to pick-and-drop.

	row_at (a_py: REAL_64): INTEGER
			-- The row index under viewport y `a_py'; 0 outside content.
		do
			if row_count > 0 and then a_py >= y then
					-- the guard matters: truncation rounds toward zero,
					-- so a point just ABOVE the list would otherwise
					-- alias to row 1 - the assault suite's first catch.
				Result := ((a_py - y + scroll_y) / row_height).truncated_to_integer + 1
				if Result < 1 or Result > row_count then
					Result := 0
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
			if r > 0 and then a_px < x + width - Bar_w and then attached row_pebble as rp then
				Result := rp.item ([r])
			else
				Result := pebble
			end
		end

	content_height: REAL_64
		do
			Result := row_count * row_height
		ensure
			non_negative: Result >= 0.0
		end

	max_scroll: REAL_64
		do
			Result := (content_height - height).max (0.0)
		end

	first_visible: INTEGER
			-- Index of the first row intersecting the viewport.
		do
			if row_count > 0 then
				Result := ((scroll_y / row_height).truncated_to_integer + 1)
					.max (1).min (row_count)
			end
		ensure
			in_range: row_count > 0 implies (Result >= 1 and Result <= row_count)
		end

	last_visible: INTEGER
		do
			if row_count > 0 then
				Result := (((scroll_y + height) / row_height).truncated_to_integer + 1)
					.max (1).min (row_count)
			end
		ensure
			ordered: Result >= first_visible or row_count = 0
		end

feature -- Element change

	set_row_count (a_n: INTEGER)
		require
			non_negative: a_n >= 0
		do
			row_count := a_n
			if selected_index > a_n then
				selected_index := 0
			end
			scroll_y := scroll_y.min (max_scroll)
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
			target: INTEGER
		do
			if row_count > 0 then
				inspect a_vk
				when 40 then
					target := (selected_index + 1).min (row_count).max (1)
				when 38 then
					target := (selected_index - 1).max (1)
				when 34 then
					target := (selected_index + page_rows).min (row_count).max (1)
				when 33 then
					target := (selected_index - page_rows).max (1)
				when 36 then
					target := 1
				when 35 then
					target := row_count
				else
					target := 0
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
			if a_i > 0 and then attached on_select as a then
				a.call (a_i)
			end
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
		do
			if height <= 0.0 then
				scroll_y := (a_i - 1) * row_height
			elseif (a_i - 1) * row_height < scroll_y then
				scroll_y := (a_i - 1) * row_height
			elseif a_i * row_height > scroll_y + height then
				scroll_y := (a_i * row_height - height).max (0.0)
			end
		ensure
			visible_once_laid_out: height > 0.0 implies
				(a_i >= first_visible and a_i <= last_visible)
		end

feature -- Layout

	Bar_w: REAL_64 = 11.0

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
			i: INTEGER
			ry, inner_w, track_h, thumb_h, thumb_y: REAL_64
		do
			t := a_p.theme
			scroll_y := scroll_y.min (max_scroll)
			a_p.push_clip (x, y, width, height)
			inner_w := width - Bar_w - 4.0
			if row_count > 0 and then attached row_renderer as rr then
				from
					i := first_visible
				until
					i > last_visible
				loop
					ry := y + (i - 1) * row_height - scroll_y
					if i = selected_index then
						a_p.set_color (t.wash_accent)
						a_p.fill_rect (x, ry, inner_w, row_height)
					elseif shows_hover and then hover_px < x + width - Bar_w
						and then hover_py >= ry and then hover_py < ry + row_height
					then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x, ry, inner_w, row_height)
					end
					rr.call (a_p, i, x, ry, inner_w, row_height)
					i := i + 1
				end
			end
			a_p.pop_clip
			if max_scroll > 0.0 then
				track_h := height - 4.0
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + width - Bar_w, y + 2.0, Bar_w - 2.0, track_h, 4.0)
				thumb_h := (height / content_height * track_h).max (24.0)
				thumb_y := y + 2.0 + (scroll_y / max_scroll) * (track_h - thumb_h)
				if shows_hover and then hover_px >= x + width - Bar_w then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (x + width - Bar_w + 1.5, thumb_y, Bar_w - 5.0, thumb_h, 3.0)
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
			scroll_y := (scroll_y - a_delta / 120.0 * row_height * 2.0)
				.max (0.0).min (max_scroll)
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
		do
			if a_px >= x + width - Bar_w and max_scroll > 0.0 then
				scroll_y := ((a_py - y) / height * max_scroll).max (0.0).min (max_scroll)
			elseif row_count > 0 then
				i := row_at (a_py)
				if i > 0 then
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
			if i > 0 and a_px < x + width - Bar_w then
				select_row (i)
				if attached on_activate as a then
					a.call (i)
				end
			end
			Result := True
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if a_px >= x + width - Bar_w and max_scroll > 0.0 then
				scroll_y := ((a_py - y) / height * max_scroll).max (0.0).min (max_scroll)
			end
		end

invariant
	rows_non_negative: row_count >= 0
	row_height_positive: row_height > 0.0
	selection_in_range: selected_index >= 0 and selected_index <= row_count
	scroll_bounded: scroll_y >= 0.0

end
