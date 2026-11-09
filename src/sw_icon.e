note
	description: "[
		One SW_PAINTER glyph as a widget: a square `size' pixels across, drawn in `color'
		(0 for the theme's ink). For icons beside text in a row - an info bar's kind mark, a
		status line, a list header.
	]"

class
	SW_ICON

inherit
	SW_WIDGET
		redefine
			preferred_width, accessible_role
		end

create
	make

feature {NONE} -- Initialization

	make (a_glyph: INTEGER; a_size: REAL_64)
		require
			known: a_glyph >= 1 and a_glyph <= {SW_PAINTER}.Glyph_last
			sensible: a_size >= 6.0 and a_size <= 256.0
		do
			glyph := a_glyph
			size := a_size
		ensure
			glyph_set: glyph = a_glyph
			sized: size = a_size
		end

feature -- Access

	glyph: INTEGER

	size: REAL_64

	color: NATURAL_32
			-- The ink; 0 for the theme's.

feature -- Element change

	set_glyph (a_glyph: INTEGER)
		require
			known: a_glyph >= 1 and a_glyph <= {SW_PAINTER}.Glyph_last
		do
			glyph := a_glyph
		ensure
			set: glyph = a_glyph
		end

	set_color (a_rgb: NATURAL_32)
		do
			color := a_rgb
		ensure
			set: color = a_rgb
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
		do
			if color = 0 then
				a_p.set_color (a_p.theme.ink)
			else
				a_p.set_color (color)
			end
			a_p.glyph (glyph, x + width / 2.0, y + height / 2.0, size * 0.8)
		end

feature -- Accessibility

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_image
		end

end
