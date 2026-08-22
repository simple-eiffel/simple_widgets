note
	description: "[
		A surface card: rounded, hairline-outlined, optionally wearing
		a severity stripe on its left edge. Its content is a column.
	]"

class
	SW_CARD

inherit
	SW_COLUMN
		redefine
			draw, arrange
		end

create
	make, make_striped

feature {NONE} -- Initialization

	make_striped (a_stripe: NATURAL_32)
		do
			make
			stripe := a_stripe
			padding := 11.0
			gap := 8.0
		ensure
			striped: stripe = a_stripe
		end

feature -- Access

	stripe: NATURAL_32
			-- Left-edge severity colour; 0 draws none.

feature -- Element change

	set_stripe (a_rgb: NATURAL_32)
		do
			stripe := a_rgb
		ensure
			set: stripe = a_rgb
		end

feature -- Layout

	arrange (a_p: SW_PAINTER)
		do
			Precursor (a_p)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
			if stripe /= 0 then
				a_p.set_color (stripe)
				a_p.fill_rect (x, y + 3.0, 4.0, height - 6.0)
			end
			Precursor (a_p)
		end

end
