note
	description: "[
		A word-sized trend: the line chart's soul with no chrome at
		all - no axes, no insets, no labels. Values normalize to the
		widget's own box, wash under the line, and the endpoint is
		emphasized (the reader's eye lands on NOW). A flat series
		draws its midline honestly. Rolling capacity makes it a live
		feed; the demo pairs one with SW_STATISTIC, as that page
		promised. fraction_of and span are public, assaulted math.
	]"

class
	SW_SPARKLINE

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create values.make (32)
		end

feature -- Access

	values: ARRAYED_LIST [REAL_64]

	capacity: INTEGER
			-- 0 = unbounded; else a rolling feed.

	low: REAL_64
			-- The smallest value aboard; 0 when empty.
		local
			first_seen: BOOLEAN
		do
			across
				values as v
			loop
				if not first_seen then
					Result := v
					first_seen := True
				else
					Result := Result.min (v)
				end
			end
		end

	high: REAL_64
			-- The largest value aboard; 0 when empty.
		local
			first_seen: BOOLEAN
		do
			across
				values as v
			loop
				if not first_seen then
					Result := v
					first_seen := True
				else
					Result := Result.max (v)
				end
			end
		end

	span: REAL_64
		do
			Result := high - low
		ensure
			non_negative: Result >= 0.0
		end

	fraction_of (a_index: INTEGER): REAL_64
			-- Value `a_index' normalized 0 (low) .. 1 (high); a flat
			-- series answers its honest midline, 0.5.
		require
			in_range: a_index >= 1 and a_index <= values.count
		do
			if span > 0.0 then
				Result := (values.i_th (a_index) - low) / span
			else
				Result := 0.5
			end
		ensure
			unit: Result >= 0.0 and Result <= 1.0
		end

feature -- Element change

	add_value (a_value: REAL_64)
		do
			values.extend (a_value)
			if capacity > 0 and then values.count > capacity then
				values.start
				values.remove
			end
		ensure
			bounded: capacity > 0 implies values.count <= capacity
		end

	set_capacity (a_capacity: INTEGER)
		require
			sane: a_capacity >= 0
		do
			capacity := a_capacity
		ensure
			set: a_capacity = capacity
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			Result := 120.0
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 34.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			poly, wash: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			i: INTEGER
			step, px_, py_: REAL_64
		do
			t := a_p.theme
			if values.count >= 2 then
				create poly.make (values.count)
				step := (width - 8.0) / (values.count - 1)
				from
					i := 1
				until
					i > values.count
				loop
					px_ := x + 4.0 + (i - 1) * step
					py_ := y + height - 5.0 - fraction_of (i) * (height - 10.0)
					poly.extend ([px_, py_])
					i := i + 1
				end
				wash := poly.twin
				wash.extend ([poly.last.px, y + height - 3.0])
				wash.extend ([poly.first.px, y + height - 3.0])
				a_p.set_color_alpha (t.accent, 0.18)
				a_p.polygon_fill (wash)
				a_p.set_color (t.accent)
				a_p.polyline (poly, 1.4)
				a_p.circle_fill (poly.last.px, poly.last.py, 2.4)
			elseif values.count = 1 then
				a_p.set_color (t.accent)
				a_p.circle_fill (x + width / 2.0, y + height / 2.0, 2.4)
			else
				a_p.set_color (t.outline)
				a_p.hline (x + 4.0, y + height / 2.0, width - 8.0)
			end
		end

invariant
	values_attached: values /= Void
	capacity_sane: capacity >= 0

end
