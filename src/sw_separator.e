note
	description: "A scored hairline, horizontal by construction here."

class
	SW_SEPARATOR

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
			Result := 9.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			a_p.hline (x + 2.0, y + height / 2.0, width - 4.0)
		end

end
