note
	description: "[
		Years on one axis and how they read (GW-17). Years are ASTRONOMICAL
		numbers - 1 BC is 0, 2 BC is -1 - so sorting and arithmetic are
		plain; they read as BC/AD (or BCE/CE) and no year zero is ever
		shown, because there is none. Ticks fall on years whose DISPLAYED
		number is round (100 BC, AD 100), so labels read the way people
		write them.
	]"

class
	SW_ERA_YEARS

create
	make

feature {NONE} -- Initialization

	make
		do
		end

feature -- Access

	uses_common_era: BOOLEAN
			-- BCE/CE instead of BC/AD?

	display_year (a_year: INTEGER): INTEGER
			-- The number shown for astronomical year `a_year': 753 for -752
			-- (753 BC), 1 for 0 (1 BC), 33 for 33 (AD 33).
		do
			if a_year <= 0 then
				Result := 1 - a_year
			else
				Result := a_year
			end
		ensure
			never_zero: Result >= 1
		end

	is_before_christ (a_year: INTEGER): BOOLEAN
			-- Does astronomical year `a_year' read as BC?
		do
			Result := a_year <= 0
		end

	astronomical (a_display: INTEGER; a_before: BOOLEAN): INTEGER
			-- The astronomical year of `a_display' BC (`a_before') or AD.
		require
			no_year_zero: a_display >= 1
		do
			if a_before then
				Result := 1 - a_display
			else
				Result := a_display
			end
		ensure
			round_trip: display_year (Result) = a_display and is_before_christ (Result) = a_before
		end

	label (a_year: INTEGER): STRING_32
			-- "753 BC", "AD 33" (or "753 BCE", "33 CE").
		do
			create Result.make (12)
			if a_year <= 0 then
				Result.append_integer (display_year (a_year))
				if uses_common_era then
					Result.append ({STRING_32} " BCE")
				else
					Result.append ({STRING_32} " BC")
				end
			elseif uses_common_era then
				Result.append_integer (a_year)
				Result.append ({STRING_32} " CE")
			else
				Result.append ({STRING_32} "AD ")
				Result.append_integer (a_year)
			end
		ensure
			never_year_zero: not Result.starts_with ({STRING_32} "0 ") and not Result.ends_with ({STRING_32} " 0")
		end

	range_label (a_from, a_to: INTEGER): STRING_32
			-- "1650-1550 BC", "AD 29-34", "4 BC - AD 30"; one year reads alone.
		require
			ordered: a_from <= a_to
		do
			if a_from = a_to then
				Result := label (a_from)
			elseif is_before_christ (a_from) = is_before_christ (a_to) then
				if is_before_christ (a_from) or uses_common_era then
					create Result.make (16)
					Result.append_integer (display_year (a_from))
					Result.append_character ('-')
					Result.append (label (a_to))
				else
					Result := label (a_from)
					Result.append_character ('-')
					Result.append_integer (a_to)
				end
			else
				Result := label (a_from)
				Result.append ({STRING_32} " - ")
				Result.append (label (a_to))
			end
		end

	nice_step (a_years: REAL_64): INTEGER
			-- The smallest round step (1, 2, 5, 10, 20, 50 ... 5000) of at
			-- least `a_years' years.
		local
			l_steps: ARRAY [INTEGER]
			i: INTEGER
		do
			l_steps := <<1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000>>
			Result := l_steps [l_steps.upper]
			from
				i := l_steps.upper
			until
				i < l_steps.lower
			loop
				if l_steps [i] >= a_years then
					Result := l_steps [i]
				end
				i := i - 1
			end
		ensure
			positive: Result >= 1
			enough_or_largest: Result >= a_years or Result = 5000
		end

	ticks (a_from, a_to: REAL_64; a_step: INTEGER): ARRAYED_LIST [INTEGER]
			-- Astronomical years from `a_from' to `a_to', ascending, whose
			-- displayed number is a multiple of `a_step': k * `a_step' BC and
			-- AD k * `a_step'.
		require
			positive_step: a_step >= 1
			ordered: a_from <= a_to
		local
			d, l_low, l_high: INTEGER
		do
			create Result.make (16)
				-- BC side: displayed d is astronomical 1 - d
			l_low := ((1.0 - a_to).max (1.0) / a_step).ceiling
			l_high := ((1.0 - a_from) / a_step).floor
			from
				d := l_high
			until
				d < l_low
			loop
				Result.extend (1 - d * a_step)
				d := d - 1
			end
				-- AD side
			l_low := (a_from.max (1.0) / a_step).ceiling
			l_high := (a_to / a_step).floor
			from
				d := l_low
			until
				d > l_high
			loop
				Result.extend (d * a_step)
				d := d + 1
			end
		ensure
			within: across Result as y all y >= a_from and y <= a_to end
		end

feature -- Element change

	set_common_era (a_on: BOOLEAN)
		do
			uses_common_era := a_on
		ensure
			set: uses_common_era = a_on
		end

end
