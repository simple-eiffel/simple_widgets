note
	description: "[
		Tests: a widget that fills its bounds in solid black, so a test can read how
		much of it reaches the surface (1x opacity).
	]"

class
	SW_TEST_FILL

inherit
	SW_WIDGET

create
	make

feature {NONE} -- Initialization

	make
		do
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 20.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			a_p.set_color (0x000000)
			a_p.fill_rect (x, y, width, height)
		end

end
