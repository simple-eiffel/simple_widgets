note
	description: "[
		The axis engine every chart shares: a linear map from a data
		DOMAIN onto a pixel RANGE, its inverse (hover asks 'what
		value is under the pointer?'), and the classic 1/2/5 tick
		ladder - steps are always 1, 2 or 5 times a power of ten, so
		gridlines land on numbers a human would choose. Degenerate
		domains (min = max) answer honestly: positions collapse to
		the range midpoint and the ladder offers the one value.
		Pure math, no painter - which is why every claim here is
		assaultable headless.
	]"

class
	SW_SCALE

create
	make

feature {NONE} -- Initialization

	make (a_domain_min, a_domain_max, a_range_min, a_range_max: REAL_64)
		require
			range_spread: a_range_min /= a_range_max
		do
			domain_min := a_domain_min
			domain_max := a_domain_max
			range_min := a_range_min
			range_max := a_range_max
		ensure
			domain_kept: domain_min = a_domain_min and domain_max = a_domain_max
			range_kept: range_min = a_range_min and range_max = a_range_max
		end

feature -- Access

	domain_min, domain_max: REAL_64
			-- The data ends. May be equal (a flat series) and may
			-- run in either direction.

	range_min, range_max: REAL_64
			-- The pixel ends. Inverted ranges are normal: a y-axis
			-- maps larger values to SMALLER pixel positions.

	is_degenerate: BOOLEAN
			-- A flat domain?
		do
			Result := domain_max = domain_min
		end

feature -- Element change

	set_domain (a_min, a_max: REAL_64)
		do
			domain_min := a_min
			domain_max := a_max
		ensure
			kept: domain_min = a_min and domain_max = a_max
		end

	set_range (a_min, a_max: REAL_64)
		require
			spread: a_min /= a_max
		do
			range_min := a_min
			range_max := a_max
		ensure
			kept: range_min = a_min and range_max = a_max
		end

	nice_domain (a_target_ticks: INTEGER)
			-- Widen the domain outward to tick-step multiples, so the
			-- axis begins and ends on chosen numbers.
		require
			some_ticks: a_target_ticks >= 2
		local
			step: REAL_64
		do
			if not is_degenerate then
				step := tick_step (a_target_ticks)
				domain_min := (domain_min / step).floor * step
				domain_max := (domain_max / step).ceiling * step
			end
		ensure
			still_ordered: (old domain_min <= old domain_max) implies domain_min <= domain_max
			covers: domain_min <= old domain_min and domain_max >= old domain_max
		end

feature -- Mapping

	position (a_value: REAL_64): REAL_64
			-- Where `a_value' lands in the range; a degenerate domain
			-- collapses to the range midpoint.
		do
			if is_degenerate then
				Result := (range_min + range_max) / 2.0
			else
				Result := range_min + (a_value - domain_min)
					/ (domain_max - domain_min) * (range_max - range_min)
			end
		end

	value_at (a_position: REAL_64): REAL_64
			-- The inverse map: the data value under a range position.
		do
			if is_degenerate then
				Result := domain_min
			else
				Result := domain_min + (a_position - range_min)
					/ (range_max - range_min) * (domain_max - domain_min)
			end
		end

feature -- Ticks

	tick_step (a_target_ticks: INTEGER): REAL_64
			-- The 1/2/5-ladder step giving about `a_target_ticks'
			-- divisions; 1.0 for a degenerate domain.
		require
			some_ticks: a_target_ticks >= 2
		local
			raw, mag, norm: REAL_64
		do
			if is_degenerate then
				Result := 1.0
			else
				raw := (domain_max - domain_min).abs / a_target_ticks
				mag := 1.0
				from
				until
					raw < mag * 10.0
				loop
					mag := mag * 10.0
				end
				from
				until
					raw >= mag
				loop
					mag := mag / 10.0
				end
				norm := raw / mag
				if norm < 1.5 then
					Result := mag
				elseif norm < 3.0 then
					Result := mag * 2.0
				elseif norm < 7.0 then
					Result := mag * 5.0
				else
					Result := mag * 10.0
				end
			end
		ensure
			positive: Result > 0.0
		end

	ticks (a_target_ticks: INTEGER): ARRAYED_LIST [REAL_64]
			-- Ladder values inside the domain, ascending; a flat
			-- domain offers its one value.
		require
			some_ticks: a_target_ticks >= 2
		local
			step, v, lo, hi: REAL_64
		do
			create Result.make (a_target_ticks + 2)
			if is_degenerate then
				Result.extend (domain_min)
			else
				step := tick_step (a_target_ticks)
				lo := domain_min.min (domain_max)
				hi := domain_min.max (domain_max)
				from
					v := (lo / step).ceiling * step
				until
					v > hi + step * 0.000_001
				loop
					Result.extend (v)
					v := v + step
				end
				if Result.is_empty then
						-- a domain narrower than one step still gets truth
					Result.extend (lo)
				end
			end
		ensure
			never_empty: not Result.is_empty
			ascending: across 2 |..| Result.count as i all
				Result.i_th (i) > Result.i_th (i - 1) end
		end

invariant
	range_spread: range_min /= range_max

end
