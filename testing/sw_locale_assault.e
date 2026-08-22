note
	description: "[
		Assault on culture: date format/parse round trips in all
		three field orders, impossible dates refused, leap February
		accepted, 12/24-hour time both ways, and the calendar's
		first-cell arithmetic honoring the week's first day.
	]"

class
	SW_LOCALE_ASSAULT

inherit
	TEST_SET_BASE

feature -- Dates

	test_us_round_trip
		local
			l: SW_LOCALE
		do
			create l.make_us
			assert ("formats mdy", l.format_date (2026, 8, 22).same_string_general ("08/22/2026"))
			assert ("parses mdy", attached l.parsed_date ("12/25/2026") as d
				and then d.year = 2026 and then d.month = 12 and then d.day = 25)
		end

	test_iso_and_european_orders
		local
			iso, eu: SW_LOCALE
		do
			create iso.make_iso
			assert ("formats ymd", iso.format_date (2026, 8, 22).same_string_general ("2026-08-22"))
			assert ("parses ymd", attached iso.parsed_date ("2026-01-31") as d
				and then d.month = 1 and then d.day = 31)
			create eu.make_european
			assert ("formats dmy", eu.format_date (2026, 8, 22).same_string_general ("22.08.2026"))
			assert ("parses dmy: 04.05 is May 4th", attached eu.parsed_date ("04.05.2026") as d2
				and then d2.month = 5 and then d2.day = 4)
		end

	test_separators_are_generous
		local
			l: SW_LOCALE
		do
			create l.make_us
			assert ("dots accepted on a US keyboardless day",
				attached l.parsed_date ("12.25.2026"))
			assert ("dashes too", attached l.parsed_date ("12-25-2026"))
		end

	test_impossible_dates_refused
		local
			l: SW_LOCALE
		do
			create l.make_us
			assert ("month 13 refused", l.parsed_date ("13/01/2026") = Void)
			assert ("Feb 30 refused", l.parsed_date ("02/30/2026") = Void)
			assert ("garbage refused", l.parsed_date ("soon") = Void)
			assert ("two fields refused", l.parsed_date ("12/2026") = Void)
		end

	test_leap_february
		local
			l: SW_LOCALE
		do
			create l.make_us
			assert ("Feb 29 2024 lives", attached l.parsed_date ("02/29/2024"))
			assert ("Feb 29 2026 dies", l.parsed_date ("02/29/2026") = Void)
		end

feature -- Time

	test_time_both_cultures
		local
			us, eu: SW_LOCALE
		do
			create us.make_us
			assert ("12h formats", us.format_time (14, 5).same_string_general ("2:05 PM"))
			assert ("midnight is 12 AM", us.format_time (0, 30).same_string_general ("12:30 AM"))
			create eu.make_european
			assert ("24h formats", eu.format_time (14, 5).same_string_general ("14:05"))
			assert ("generous in: US parses 24h too", attached us.parsed_time ("14:05") as t1
				and then t1.hour = 14)
			assert ("generous in: EU parses AM/PM too", attached eu.parsed_time ("2:05 PM") as t2
				and then t2.hour = 14)
			assert ("12 AM is hour zero", attached us.parsed_time ("12:30 AM") as t3
				and then t3.hour = 0)
			assert ("25 oclock refused", us.parsed_time ("25:00") = Void)
		end

feature -- Calendar arithmetic

	test_first_cell_honors_week_start
		local
			cal: SW_CALENDAR
			iso: SW_LOCALE
			d: SIMPLE_DATE
		do
			create cal.make
			cal.show_month (2026, 8)
				-- US (Sunday-first): Aug 1 2026 is Saturday, so the
				-- top-left cell is Sunday July 26.
			d := cal.first_cell_date
			assert ("US grid opens Jul 26", d.month = 7 and d.day = 26)
			create iso.make_iso
			cal.set_locale (iso)
				-- Monday-first: top-left is Monday July 27.
			d := cal.first_cell_date
			assert ("ISO grid opens Jul 27", d.month = 7 and d.day = 27)
		end

	test_calendar_step_wraps_year
		local
			cal: SW_CALENDAR
		do
			create cal.make
			cal.show_month (2026, 12)
			cal.step_month (1)
			assert ("december steps into january", cal.shown_month = 1 and cal.shown_year = 2027)
			cal.step_month (-1)
			assert ("and back", cal.shown_month = 12 and cal.shown_year = 2026)
		end

end
