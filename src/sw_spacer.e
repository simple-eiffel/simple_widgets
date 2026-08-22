note
	description: "[
		Stretchy nothing: an invisible widget born with grow weight 1,
		so it absorbs a container's slack. Vision2 called this EV_CELL;
		the web calls it a flex spacer. Put one before a status bar and
		the bar pins to the window's bottom edge at any height.
	]"

class
	SW_SPACER

inherit
	SW_WIDGET

create
	make

feature {NONE} -- Initialization

	make
		do
			grow := 1.0
		ensure
			born_growing: grow = 1.0
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 0.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
		end

end
