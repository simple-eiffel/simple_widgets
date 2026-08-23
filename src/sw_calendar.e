note
	description: "[
		A month of days: title with prev/next, a day-of-week header
		opening on the locale's first day, six weeks of cells. Today
		wears a ring, the selection a fill; out-of-month days are
		muted but pickable. Date arithmetic is SIMPLE_DATE's
		(simple_datetime) - the toolkit hand-rolls no calendars.
	]"

class
	SW_CALENDAR

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make
		local
			today: SIMPLE_DATE
		do
			create today.make_now
			shown_year := today.year
			shown_month := today.month
		ensure
			showing_now: shown_month >= 1 and shown_month <= 12
		end

feature -- Access

	shown_year, shown_month: INTEGER

	selected_year, selected_month, selected_day: INTEGER
			-- The picked date; selected_day = 0 means none yet.

	has_selection: BOOLEAN
		do
			Result := selected_day > 0
		end

	on_pick: detachable PROCEDURE [INTEGER, INTEGER, INTEGER]
			-- Fired (year, month, day) when a day is clicked.

	locale_override: detachable SW_LOCALE
			-- Per-control culture; Void = the theme's.

	Cell_w: REAL_64 = 34.0
	Cell_h: REAL_64 = 28.0
	Head_h: REAL_64 = 34.0

feature -- Element change

	min_date: detachable SIMPLE_DATE
			-- Earliest selectable date; Void = unconstrained.

	max_date: detachable SIMPLE_DATE
			-- Latest selectable date; Void = unconstrained.

	set_min_date (a_date: SIMPLE_DATE)
		do
			min_date := a_date
		ensure
			set: min_date = a_date
		end

	set_max_date (a_date: SIMPLE_DATE)
		do
			max_date := a_date
		ensure
			set: max_date = a_date
		end

	date_allowed (a_date: SIMPLE_DATE): BOOLEAN
			-- Does `a_date' fall inside the min/max window? Cells
			-- outside draw muted and REFUSE clicks; select_date (a
			-- silent command) is deliberately not guarded - the
			-- programmer stays king.
		do
			Result := (not attached min_date as mn or else not a_date.is_before (mn))
				and (not attached max_date as mx or else not a_date.is_after (mx))
		end

	closes_overlay_on_pick: BOOLEAN
			-- Should a day pick ask the window to close the overlay
			-- this calendar rides in? Set by popover hosts (the date
			-- picker); embedded calendars leave it off.

	set_closes_overlay_on_pick (a_flag: BOOLEAN)
		do
			closes_overlay_on_pick := a_flag
		ensure
			set: closes_overlay_on_pick = a_flag
		end

	set_on_pick (a_action: PROCEDURE [INTEGER, INTEGER, INTEGER])
		do
			on_pick := a_action
		ensure
			set: on_pick = a_action
		end

	set_locale (a_locale: SW_LOCALE)
		do
			locale_override := a_locale
		ensure
			set: locale_override = a_locale
		end

	with_locale (a_locale: SW_LOCALE): like Current
		do
			locale_override := a_locale
			Result := Current
		ensure
			chained: Result = Current
		end

	show_month (a_year, a_month: INTEGER)
		require
			plausible: a_year >= 1 and a_year <= 9999 and a_month >= 1 and a_month <= 12
		do
			shown_year := a_year
			shown_month := a_month
		ensure
			shown: shown_year = a_year and shown_month = a_month
		end

	select_date (a_year, a_month, a_day: INTEGER)
			-- Select and show that month; fires nothing (commands are
			-- silent; picks by CLICK fire on_pick).
		require
			plausible: a_month >= 1 and a_month <= 12 and a_day >= 1 and a_day <= 31
		do
			selected_year := a_year
			selected_month := a_month
			selected_day := a_day
			show_month (a_year, a_month)
		ensure
			selected: has_selection
		end

	step_month (a_delta: INTEGER)
		local
			d: SIMPLE_DATE
		do
			create d.make (shown_year, shown_month, 1)
			if a_delta >= 0 then
				d := d.plus_months (a_delta)
			else
				d := d.minus_months (-a_delta)
			end
			shown_year := d.year
			shown_month := d.month
		end

feature -- Culture

	effective_locale (a_p: SW_PAINTER): SW_LOCALE
		do
			if attached locale_override as lo then
				Result := lo
			else
				Result := a_p.theme.locale
			end
		end

feature -- Layout hooks

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

feature -- Geometry

	first_cell_date: SIMPLE_DATE
			-- The date the top-left cell shows, honoring the first
			-- day of week (override first, else US Sunday).
		local
			first_of_month: SIMPLE_DATE
			fdow, back: INTEGER
		do
			if attached locale_override as lo then
				fdow := lo.first_day_of_week
			else
				fdow := 7
			end
			create first_of_month.make (shown_year, shown_month, 1)
			back := (first_of_month.day_of_week - fdow + 7) \\ 7
			Result := first_of_month.minus_days (back)
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			Result := 7.0 * Cell_w + 8.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Head_h + Cell_h + 6.0 * Cell_h + 8.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			loc: SW_LOCALE
			today, cursor: SIMPLE_DATE
			title: STRING_32
			i, r, c: INTEGER
			cx, cy: REAL_64
			in_month, sel, is_today: BOOLEAN
		do
			t := a_p.theme
			loc := effective_locale (a_p)
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
				-- title and chevrons
			title := loc.month_name (shown_month) + {STRING_32} " " + shown_year.out
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
			a_p.set_color (t.ink)
			a_p.text (x + (width - a_p.advance (title)) / 2.0, y + 22.0, title)
			a_p.set_color (t.ink_muted)
			a_p.line (x + 18.0, y + 12.0, x + 12.0, y + 17.0, 1.6)
			a_p.line (x + 12.0, y + 17.0, x + 18.0, y + 22.0, 1.6)
			a_p.line (x + width - 18.0, y + 12.0, x + width - 12.0, y + 17.0, 1.6)
			a_p.line (x + width - 12.0, y + 17.0, x + width - 18.0, y + 22.0, 1.6)
				-- day-of-week header, rotated to the locale's first day
			a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
			from
				i := 0
			until
				i > 6
			loop
				cx := x + 4.0 + i * Cell_w
				a_p.set_color (t.ink_muted)
				a_p.text (cx + 9.0, y + Head_h + 16.0,
					loc.day_name_short (((loc.first_day_of_week - 1 + i) \\ 7) + 1))
				i := i + 1
			end
				-- six weeks of cells
			create today.make_now
			cursor := first_cell_date
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			from
				r := 0
			until
				r > 5
			loop
				from
					c := 0
				until
					c > 6
				loop
					cx := x + 4.0 + c * Cell_w
					cy := y + Head_h + Cell_h + r * Cell_h
					in_month := cursor.month = shown_month
					sel := has_selection and then cursor.year = selected_year
						and then cursor.month = selected_month
						and then cursor.day = selected_day
					is_today := cursor.year = today.year
						and then cursor.month = today.month
						and then cursor.day = today.day
					if sel then
						a_p.set_color (t.accent)
						a_p.rrect_fill (cx + 2.0, cy + 2.0, Cell_w - 4.0, Cell_h - 4.0, t.radius)
						a_p.set_color (t.surface)
					elseif is_today then
						a_p.set_color (t.accent)
						a_p.rrect_stroke (cx + 2.5, cy + 2.5, Cell_w - 5.0, Cell_h - 5.0, t.radius)
						a_p.set_color (t.ink)
					elseif not date_allowed (cursor) then
						a_p.set_color (t.outline)
					elseif shows_hover and then hover_px >= cx and then hover_px < cx + Cell_w
						and then hover_py >= cy and then hover_py < cy + Cell_h
					then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (cx + 2.0, cy + 2.0, Cell_w - 4.0, Cell_h - 4.0)
						a_p.set_color (t.ink)
					elseif in_month then
						a_p.set_color (t.ink)
					else
						a_p.set_color (t.ink_muted)
					end
					a_p.text (cx + Cell_w / 2.0 - a_p.advance (cursor.day.out) / 2.0,
						cy + Cell_h - 9.0, cursor.day.out)
					cursor := cursor.days_from_now (1)
					c := c + 1
				end
				r := r + 1
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			c, r: INTEGER
			d: SIMPLE_DATE
		do
			if is_enabled then
				if a_py < y + Head_h then
					if a_px < x + 30.0 then
						step_month (-1)
					elseif a_px > x + width - 30.0 then
						step_month (1)
					end
				elseif a_py >= y + Head_h + Cell_h then
					c := ((a_px - x - 4.0) / Cell_w).truncated_to_integer
					r := ((a_py - y - Head_h - Cell_h) / Cell_h).truncated_to_integer
					if a_px >= x + 4.0 and c >= 0 and c <= 6 and r >= 0 and r <= 5 then
						d := first_cell_date.days_from_now (r * 7 + c)
						if date_allowed (d) then
						selected_year := d.year
						selected_month := d.month
						selected_day := d.day
						shown_year := d.year
						shown_month := d.month
						if attached on_pick as pk then
							pk.call (d.year, d.month, d.day)
						end
						if closes_overlay_on_pick then
							request_sheet_close
						end
						end
					end
				end
				Result := True
			end
		end

invariant
	month_sane: shown_month >= 1 and shown_month <= 12
	selection_sane: selected_day >= 0 and selected_day <= 31

end
