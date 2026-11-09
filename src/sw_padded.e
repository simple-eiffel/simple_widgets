note
	description: "[
		A container with `padding': space inside its edges, around its children (0 unless set).
		Its preferred sizes add the padding on both sides (`padded'), and it lays its children
		out within the inset bounds (`lay_out_within_padding'), keeping its own bounds.
	]"

deferred class
	SW_PADDED

feature -- Access

	padding: REAL_64
			-- Space inside each edge, around the children.

	x, y, width, height: REAL_64
		deferred
		end

feature -- Element change

	set_padding (a_pad: REAL_64)
		require
			non_negative: a_pad >= 0.0
		do
			padding := a_pad
		ensure
			set: padding = a_pad
		end

	set_bounds (a_x, a_y, a_w, a_h: REAL_64)
		require
			sane_size: a_w >= 0.0 and a_h >= 0.0
		deferred
		ensure
			placed: x = a_x and y = a_y
			sized: width = a_w and height = a_h
		end

feature {NONE} -- Layout

	padded (a_inner: REAL_64): REAL_64
			-- A size `a_inner' with the padding on both sides.
		do
			Result := a_inner + 2.0 * padding
		ensure
			both_sides: Result = a_inner + 2.0 * padding
		end

	unpadded (a_outer: REAL_64): REAL_64
			-- What is left of `a_outer' inside the padding.
		do
			Result := (a_outer - 2.0 * padding).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	lay_out_within_padding (a_layout: PROCEDURE)
			-- Run `a_layout' with the bounds inset by the padding, then restore them.
		local
			l_x, l_y, l_w, l_h: REAL_64
		do
			if padding > 0.0 then
				l_x := x
				l_y := y
				l_w := width
				l_h := height
				set_bounds (l_x + padding, l_y + padding, unpadded (l_w), unpadded (l_h))
				a_layout.call
				set_bounds (l_x, l_y, l_w, l_h)
			else
				a_layout.call
			end
		ensure
			bounds_kept: x = old x and y = old y and width = old width and height = old height
		end

invariant
	padding_non_negative: padding >= 0.0

end
