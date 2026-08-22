note
	description: "[
		A data grid column as a first-class object: title, width, a
		value extractor rendering any row to text, and an optional
		sort key so numbers can sort as numbers. The extractor is
		the column's meaning; everything else is presentation.
	]"

class
	SW_GRID_COLUMN [G]

create
	make

feature {NONE} -- Initialization

	make (a_title: READABLE_STRING_GENERAL; a_width: REAL_64; a_value: FUNCTION [G, STRING_32])
		require
			wide_enough: a_width >= Min_width
		do
			create title.make_from_string_general (a_title)
			width := a_width
			value := a_value
		ensure
			titled: title.same_string_general (a_title)
			kept: width = a_width and value = a_value
		end

feature -- Access

	title: STRING_32

	width: REAL_64

	value: FUNCTION [G, STRING_32]
			-- Renders a row to this column's text.

	key: detachable FUNCTION [G, COMPARABLE]
			-- Optional typed sort key; when absent, sorting compares
			-- the rendered text.

	Min_width: REAL_64 = 40.0

feature -- Element change

	set_width (a_w: REAL_64)
			-- Clamped at the minimum - a column can narrow, never
			-- vanish.
		do
			width := a_w.max (Min_width)
		ensure
			at_least_minimum: width >= Min_width
		end

	set_key (a_key: FUNCTION [G, COMPARABLE])
		do
			key := a_key
		ensure
			set: key = a_key
		end

	with_key (a_key: FUNCTION [G, COMPARABLE]): like Current
		do
			key := a_key
			Result := Current
		ensure
			chained: Result = Current
		end

feature -- Comparison

	row_less (a, b: G): BOOLEAN
			-- Does row `a' order before row `b' in this column?
		do
			if attached key as k then
				Result := k.item ([a]) < k.item ([b])
			else
				Result := value.item ([a]) < value.item ([b])
			end
		end

invariant
	title_attached: title /= Void
	value_attached: value /= Void
	never_vanishes: width >= Min_width

end
