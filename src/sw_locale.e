note
	description: "[
		Cultural presentation truth for regional controls: date field
		order and separator, month and day names, the week's first
		day, 12/24-hour time, the decimal mark. Distinct from the
		theme (visual truth) but carried beside it; any regional
		control accepts a per-control override. Defaults are US, by
		project decree.
	]"

class
	SW_LOCALE

create
	make_us, make_iso, make_european

feature {NONE} -- Initialization

	make_us
			-- month/day/year with slashes, Sunday-first, 12-hour.
		do
			date_order := Order_mdy
			date_separator := '/'
			first_day_of_week := 7
			uses_24h_clock := False
			decimal_separator := '.'
			set_english_names
		ensure
			us: date_order = Order_mdy and not uses_24h_clock
		end

	make_iso
			-- year-month-day with dashes, Monday-first, 24-hour.
		do
			date_order := Order_ymd
			date_separator := '-'
			first_day_of_week := 1
			uses_24h_clock := True
			decimal_separator := '.'
			set_english_names
		ensure
			iso: date_order = Order_ymd and uses_24h_clock
		end

	make_european
			-- day.month.year with dots, Monday-first, 24-hour.
		do
			date_order := Order_dmy
			date_separator := '.'
			first_day_of_week := 1
			uses_24h_clock := True
			decimal_separator := ','
			set_english_names
		ensure
			european: date_order = Order_dmy and uses_24h_clock
		end

feature -- Access

	Order_mdy: INTEGER = 1
	Order_dmy: INTEGER = 2
	Order_ymd: INTEGER = 3

	date_order: INTEGER

	date_separator: CHARACTER_32

	first_day_of_week: INTEGER
			-- ISO day number the calendar week opens on:
			-- 1 = Monday .. 7 = Sunday.

	uses_24h_clock: BOOLEAN

	decimal_separator: CHARACTER_32

	month_names: ARRAY [STRING_32]

	day_names_short: ARRAY [STRING_32]
			-- Two-letter day names indexed 1 (Monday) .. 7 (Sunday).

feature -- Element change

	set_names (a_months, a_days_short: ARRAY [STRING_32])
			-- Localize the vocabulary.
		require
			twelve: a_months.count = 12
			seven: a_days_short.count = 7
		do
			month_names := a_months
			day_names_short := a_days_short
		ensure
			kept: month_names = a_months and day_names_short = a_days_short
		end

	set_first_day_of_week (a_iso_day: INTEGER)
		require
			iso_day: a_iso_day >= 1 and a_iso_day <= 7
		do
			first_day_of_week := a_iso_day
		ensure
			set: first_day_of_week = a_iso_day
		end

feature -- Dates

	format_date (a_year, a_month, a_day: INTEGER): STRING_32
			-- The date in this locale's field order and separator,
			-- zero-padded, four-digit year.
		require
			plausible: a_month >= 1 and a_month <= 12 and a_day >= 1 and a_day <= 31
		do
			create Result.make (10)
			inspect date_order
			when Order_mdy then
				Result.append (padded (a_month))
				Result.append_character (date_separator)
				Result.append (padded (a_day))
				Result.append_character (date_separator)
				Result.append (a_year.out.to_string_32)
			when Order_dmy then
				Result.append (padded (a_day))
				Result.append_character (date_separator)
				Result.append (padded (a_month))
				Result.append_character (date_separator)
				Result.append (a_year.out.to_string_32)
			else
				Result.append (a_year.out.to_string_32)
				Result.append_character (date_separator)
				Result.append (padded (a_month))
				Result.append_character (date_separator)
				Result.append (padded (a_day))
			end
		ensure
			has_two_separators: Result.occurrences (date_separator) = 2
		end

	parsed_date (a_text: READABLE_STRING_GENERAL): detachable TUPLE [year, month, day: INTEGER]
			-- The date the text denotes in this locale's field order,
			-- or Void when ill-formed or impossible. Any of / . -
			-- is accepted as the separator - users borrow keyboards.
		local
			s, piece: STRING_32
			parts: ARRAYED_LIST [STRING_32]
			i: INTEGER
			c: CHARACTER_32
			f1, f2, f3, yy, mm, dd: INTEGER
			probe: SIMPLE_DATE
		do
			create s.make_from_string_general (a_text)
			create parts.make (3)
			create piece.make (4)
			from
				i := 1
			until
				i > s.count
			loop
				c := s.item (i)
				if c = '/' or c = '.' or c = '-' then
					parts.extend (piece.twin)
					piece.wipe_out
				else
					piece.append_character (c)
				end
				i := i + 1
			end
			parts.extend (piece.twin)
			if parts.count = 3 and then parts.i_th (1).is_integer
				and then parts.i_th (2).is_integer and then parts.i_th (3).is_integer
				and then not parts.i_th (1).is_empty and then not parts.i_th (2).is_empty
				and then not parts.i_th (3).is_empty
			then
				f1 := parts.i_th (1).to_integer
				f2 := parts.i_th (2).to_integer
				f3 := parts.i_th (3).to_integer
				inspect date_order
				when Order_mdy then
					mm := f1
					dd := f2
					yy := f3
				when Order_dmy then
					dd := f1
					mm := f2
					yy := f3
				else
					yy := f1
					mm := f2
					dd := f3
				end
				if yy >= 1 and yy <= 9999 and mm >= 1 and mm <= 12 and dd >= 1 then
					create probe.make (yy, mm, 1)
					if dd <= probe.days_in_month then
						Result := [yy, mm, dd]
					end
				end
			end
		ensure
			honest: attached Result as r implies (r.month >= 1 and r.month <= 12)
		end

feature -- Time

	format_time (a_hour, a_minute: INTEGER): STRING_32
			-- 24-hour "HH:MM", or 12-hour "H:MM AM/PM", per locale.
		require
			sane: a_hour >= 0 and a_hour <= 23 and a_minute >= 0 and a_minute <= 59
		local
			h12: INTEGER
		do
			create Result.make (8)
			if uses_24h_clock then
				Result.append (padded (a_hour))
				Result.append_character (':')
				Result.append (padded (a_minute))
			else
				h12 := a_hour \\ 12
				if h12 = 0 then
					h12 := 12
				end
				Result.append (h12.out.to_string_32)
				Result.append_character (':')
				Result.append (padded (a_minute))
				if a_hour >= 12 then
					Result.append ({STRING_32} " PM")
				else
					Result.append ({STRING_32} " AM")
				end
			end
		end

	parsed_time (a_text: READABLE_STRING_GENERAL): detachable TUPLE [hour, minute: INTEGER]
			-- "HH:MM" always accepted; "H:MM AM/PM" accepted too -
			-- generous in, exact out.
		local
			s, hp, mp: STRING_32
			ci: INTEGER
			hh, mm: INTEGER
			pm, am: BOOLEAN
		do
			create s.make_from_string_general (a_text)
			s.to_upper
			s.replace_substring_all ({STRING_32} " ", {STRING_32} "")
			if s.ends_with ({STRING_32} "PM") then
				pm := True
				s.remove_tail (2)
			elseif s.ends_with ({STRING_32} "AM") then
				am := True
				s.remove_tail (2)
			end
			ci := s.index_of (':', 1)
			if ci >= 2 and ci < s.count then
				hp := s.substring (1, ci - 1)
				mp := s.substring (ci + 1, s.count)
				if hp.is_integer and then mp.is_integer and then mp.count = 2 then
					hh := hp.to_integer
					mm := mp.to_integer
					if pm or am then
						if hh >= 1 and hh <= 12 and mm >= 0 and mm <= 59 then
							if pm and hh < 12 then
								hh := hh + 12
							elseif am and hh = 12 then
								hh := 0
							end
							Result := [hh, mm]
						end
					elseif hh >= 0 and hh <= 23 and mm >= 0 and mm <= 59 then
						Result := [hh, mm]
					end
				end
			end
		ensure
			honest: attached Result as r implies (r.hour >= 0 and r.hour <= 23 and r.minute >= 0 and r.minute <= 59)
		end

feature -- Names

	month_name (a_month: INTEGER): STRING_32
		require
			valid: a_month >= 1 and a_month <= 12
		do
			Result := month_names [a_month]
		end

	day_name_short (a_iso_day: INTEGER): STRING_32
		require
			valid: a_iso_day >= 1 and a_iso_day <= 7
		do
			Result := day_names_short [a_iso_day]
		end

feature {NONE} -- Plumbing

	padded (a_n: INTEGER): STRING_32
		do
			if a_n < 10 then
				Result := {STRING_32} "0" + a_n.out.to_string_32
			else
				Result := a_n.out.to_string_32
			end
		end

	set_english_names
		do
			month_names := <<{STRING_32} "January", {STRING_32} "February", {STRING_32} "March",
				{STRING_32} "April", {STRING_32} "May", {STRING_32} "June",
				{STRING_32} "July", {STRING_32} "August", {STRING_32} "September",
				{STRING_32} "October", {STRING_32} "November", {STRING_32} "December">>
			day_names_short := <<{STRING_32} "Mo", {STRING_32} "Tu", {STRING_32} "We",
				{STRING_32} "Th", {STRING_32} "Fr", {STRING_32} "Sa", {STRING_32} "Su">>
		end

invariant
	order_known: date_order >= Order_mdy and date_order <= Order_ymd
	first_day_iso: first_day_of_week >= 1 and first_day_of_week <= 7
	twelve_months: month_names.count = 12
	seven_days: day_names_short.count = 7

end
