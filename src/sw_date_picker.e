note
	description: "[
		A date field with culture: typing parses in the effective
		locale's field order (any of / . - accepted), ill-formed or
		impossible dates wear the invalid tint, and the calendar
		glyph summons an SW_CALENDAR popover whose pick writes back
		formatted. Locale is settable per control; the theme's (US
		by default) otherwise.
	]"

class
	SW_DATE_PICKER

inherit
	SW_TEXT_BOX
		redefine
			draw, handle_click, changed
		end

create
	make_picker

feature {NONE} -- Initialization

	make_picker
		do
			make_single_line ("")
			set_spellcheck (False)
			create shown_locale_probe.make_us
		end

feature -- Access

	selected_year, selected_month, selected_day: INTEGER

	has_date: BOOLEAN
		do
			Result := selected_day > 0
		end

	on_date_change: detachable PROCEDURE [INTEGER, INTEGER, INTEGER]

	locale_override: detachable SW_LOCALE

	Glyph_zone: REAL_64 = 30.0

feature -- Element change

	set_on_date_change (a_action: PROCEDURE [INTEGER, INTEGER, INTEGER])
		do
			on_date_change := a_action
		ensure
			set: on_date_change = a_action
		end

	set_picker_locale (a_locale: SW_LOCALE)
		do
			locale_override := a_locale
		ensure
			set: locale_override = a_locale
		end

	with_picker_locale (a_locale: SW_LOCALE): like Current
		do
			locale_override := a_locale
			Result := Current
		ensure
			chained: Result = Current
		end

	set_date (a_year, a_month, a_day: INTEGER)
			-- Programmatic set: formats into the box per locale.
		require
			plausible: a_month >= 1 and a_month <= 12 and a_day >= 1 and a_day <= 31
		do
			selected_year := a_year
			selected_month := a_month
			selected_day := a_day
			set_text (effective_locale_now.format_date (a_year, a_month, a_day))
			set_invalid (False)
		ensure
			dated: has_date
		end

feature -- Culture

	effective_locale_now: SW_LOCALE
			-- Override, else a US default; the DRAW path prefers the
			-- theme's locale via the painter (see draw), but parsing
			-- on keystrokes has no painter - the override (or US)
			-- governs there. Set the override when the theme's
			-- culture is not US and typing must match it.
		do
			if attached locale_override as lo then
				Result := lo
			else
				Result := shown_locale_probe
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			gx, gy: REAL_64
		do
			if locale_override = Void then
					-- adopt the theme's culture for parsing too
				shown_locale_probe := a_p.theme.locale
			end
			Precursor (a_p)
			t := a_p.theme
				-- the calendar glyph: a little month
			gx := x + width - 21.0
			gy := y + height / 2.0
			if shows_hover then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.rrect_stroke (gx - 6.0, gy - 6.0, 13.0, 12.0, 2.0)
			a_p.hline (gx - 6.0, gy - 2.5, 13.0)
			a_p.vline (gx - 2.0, gy - 8.0, 3.0)
			a_p.vline (gx + 3.0, gy - 8.0, 3.0)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			cal: SW_CALENDAR
		do
			if is_enabled and then a_px >= x + width - Glyph_zone then
				create cal.make
				if attached locale_override as lo then
					cal.set_locale (lo)
				end
				if has_date then
					cal.select_date (selected_year, selected_month, selected_day)
				end
				cal.set_on_pick (agent on_calendar_pick)
				cal.set_closes_overlay_on_pick (True)
				pending_popover := cal
				pending_popover_width := 250.0
				Result := True
			else
				Result := Precursor (a_px, a_py)
			end
		end

feature {NONE} -- Engine

	shown_locale_probe: SW_LOCALE
		attribute
			create Result.make_us
		end

	on_calendar_pick (a_year, a_month, a_day: INTEGER)
		do
			set_date (a_year, a_month, a_day)
			if attached on_date_change as dc then
				dc.call (a_year, a_month, a_day)
			end
		end

	changed
			-- Re-parse after every edit; the tint tells the truth.
		local
			loc: SW_LOCALE
		do
			Precursor
			loc := effective_locale_now
			if text.is_empty then
				set_invalid (False)
				selected_day := 0
			elseif attached loc.parsed_date (text) as d then
				selected_year := d.year
				selected_month := d.month
				selected_day := d.day
				set_invalid (False)
				if attached on_date_change as dc then
					dc.call (d.year, d.month, d.day)
				end
			else
				selected_day := 0
				set_invalid (True)
			end
		end

invariant
	selection_sane: selected_day >= 0 and selected_day <= 31

end
