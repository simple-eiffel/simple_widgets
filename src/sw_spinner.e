note
	description: "[
		A busy wheel: three quarters of a ring in the accent, turned a step each frame while
		spinning (the same ring as a busy SW_BUTTON). With reduced motion it holds still as a
		full faint ring. Whoever starts it keeps frames coming (a fast timer or the toast
		heartbeat); the spinner only draws.
	]"

class
	SW_SPINNER

inherit
	SW_WIDGET
		redefine
			preferred_width, accessible_role
		end

create
	make

feature {NONE} -- Initialization

	make (a_size: REAL_64)
			-- A spinner `a_size' pixels across, not turning.
		require
			sensible: a_size >= 8.0 and a_size <= 128.0
		do
			size := a_size
		ensure
			sized: size = a_size
			still: not is_spinning
		end

feature -- Access

	size: REAL_64

	is_spinning: BOOLEAN

	step: INTEGER
			-- Which of twelve positions the ring is at.

feature -- Element change

	set_spinning (a_on: BOOLEAN)
		do
			is_spinning := a_on
		ensure
			set: is_spinning = a_on
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			Result := size
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := size
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			l_from, l_cx, l_cy, l_r: REAL_64
		do
			if is_spinning then
				l_cx := x + size / 2.0
				l_cy := y + height / 2.0
				l_r := size * 0.4
				a_p.set_line_width ((size / 8.0).max (1.5))
				if a_p.theme.reduces_motion then
					a_p.set_color_alpha (a_p.theme.accent, 0.5)
					a_p.arc_stroke (l_cx, l_cy, l_r, 0.0, 2.0 * Pi_value)
				else
					step := (step + 1) \\ 12
					l_from := step * Pi_value / 6.0
					a_p.set_color (a_p.theme.accent)
					a_p.arc_stroke (l_cx, l_cy, l_r, l_from, l_from + 4.7)
				end
				a_p.set_line_width (1.0)
			end
		end

feature -- Accessibility

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_progress_bar
		end

feature {NONE} -- Implementation

	Pi_value: REAL_64 = 3.141592653589793

invariant
	step_in_range: step >= 0 and step < 12

end
