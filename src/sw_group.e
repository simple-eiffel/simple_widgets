note
	description: "[
		A titled border around content: the classic group box, drawn -
		hairline frame, the title carved into its top edge, content
		a padded column.
	]"

class
	SW_GROUP

inherit
	SW_COLUMN
		redefine
			draw, arrange, preferred_height
		end

create
	make_titled

feature {NONE} -- Initialization

	make_titled (a_title: READABLE_STRING_GENERAL)
		do
			make
			create title.make_from_string_general (a_title)
			padding := 14.0
			gap := 8.0
		ensure
			titled: title.same_string_general (a_title)
		end

feature -- Access

	title: STRING_32

	Top_inset: REAL_64 = 12.0

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Precursor (a_p, a_width) + Top_inset
		end

	arrange (a_p: SW_PAINTER)
		local
			keep_y, keep_h: REAL_64
		do
			keep_y := y
			keep_h := height
			y := keep_y + Top_inset
			height := (keep_h - Top_inset).max (0.0)
			Precursor (a_p)
			y := keep_y
			height := keep_h
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			tw: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + Top_inset + 0.5, width - 1.0, height - Top_inset - 1.0, t.radius)
			a_p.font ({SW_PAINTER}.Role_ui, t.size_chip + 1.0, True)
			tw := a_p.advance (title) + 16.0
			a_p.set_color (t.background)
			a_p.fill_rect (x + 14.0, y + Top_inset - 7.0, tw, 15.0)
			a_p.set_color (t.ink_muted)
			a_p.text (x + 22.0, y + Top_inset + 5.0, title)
			across
				children as c
			loop
				c.draw (a_p)
			end
		end

invariant
	title_attached: title /= Void

end
