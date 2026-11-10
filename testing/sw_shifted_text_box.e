note
	description: "[
		A test double for SW_TEXT_BOX's text-frame hooks: a box whose text
		starts `shift_x', `shift_y' away from the usual origin and never
		wraps, as a scrolling editor with a gutter places its text.
	]"
	author: "Larry Rix"

class
	SW_SHIFTED_TEXT_BOX

inherit
	SW_TEXT_BOX
		redefine
			text_left,
			text_top,
			wrap_width_in
		end

create
	make

feature -- Access

	shift_x: REAL_64
			-- How far right of the usual origin the text starts.

	shift_y: REAL_64
			-- How far below the usual origin the text starts.

	Unwrapped_width: REAL_64 = 100_000.0
			-- A wrap width no test line reaches.

feature -- Element change

	set_shift (a_x, a_y: REAL_64)
			-- Start the text (`a_x', `a_y') away from the usual origin.
		do
			shift_x := a_x
			shift_y := a_y
		ensure
			set: shift_x = a_x and shift_y = a_y
		end

feature -- Text frame

	text_left: REAL_64
		do
			Result := Precursor + shift_x
		end

	text_top: REAL_64
		do
			Result := Precursor + shift_y
		end

	wrap_width_in (a_width: REAL_64): REAL_64
		do
			Result := Unwrapped_width
		end

end
