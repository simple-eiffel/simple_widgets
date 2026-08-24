note
	description: "[
		A picture: a PNG loaded once by cairo, drawn scaled to fit
		its bounds with aspect preserved and centered. A file that
		fails to decode draws an honest crossed placeholder rather
		than pretending.
	]"

class
	SW_IMAGE

inherit
	SW_WIDGET
		redefine
			preferred_width
		end

create
	make_from_file, make_from_surface

feature {NONE} -- Initialization

	make_from_file (a_path: READABLE_STRING_GENERAL)
		do
			create source_path.make_from_string_general (a_path)
			create picture.make_from_png (a_path)
		ensure
			path_kept: source_path.same_string_general (a_path)
		end

	make_from_surface (a_surface: CAIRO_SURFACE)
			-- Show pixels already in hand (a screen grab, a thumbnail)
			-- - no file involved.
		do
			create source_path.make_empty
			picture := a_surface
		ensure
			kept: picture = a_surface
		end

feature -- Access

	source_path: STRING_32

	picture: CAIRO_SURFACE

	set_surface (a_surface: CAIRO_SURFACE)
			-- Swap the pixels shown; the old surface stays the
			-- caller's to destroy.
		do
			picture := a_surface
		ensure
			kept: picture = a_surface
		end

	is_loaded: BOOLEAN
			-- Did the PNG decode into pixels?
		do
			Result := picture.width > 0 and picture.height > 0
		end

	natural_width: INTEGER
		do
			Result := picture.width
		end

	natural_height: INTEGER
		do
			Result := picture.height
		end

feature -- Sizing

	display_height: REAL_64
			-- Requested height; 0 = derive from width and aspect.

	with_display_height (a_h: REAL_64): like Current
		require
			positive: a_h > 0.0
		do
			display_height := a_h
			Result := Current
		ensure
			chained: Result = Current
			kept: display_height = a_h
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			if is_loaded then
				Result := natural_width
			else
				Result := 160.0
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			if display_height > 0.0 then
				Result := display_height
			elseif is_loaded then
				Result := a_width * natural_height / natural_width
			else
				Result := 120.0
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			s, dw, dh: REAL_64
		do
			t := a_p.theme
			if is_loaded and then width > 1.0 and then height > 1.0 then
				s := (width / natural_width).min (height / natural_height)
				dw := natural_width * s
				dh := natural_height * s
				a_p.draw_image (picture, x + (width - dw) / 2.0, y + (height - dh) / 2.0, dw, dh)
			else
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
				a_p.line (x, y, x + width, y + height, 1.0)
				a_p.line (x + width, y, x, y + height, 1.0)
				a_p.set_color (t.ink_muted)
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, False)
				a_p.text (x + 8.0, y + height - 8.0, {STRING_32} "image unavailable")
			end
		end

invariant
	path_attached: source_path /= Void
	picture_attached: picture /= Void
	no_negative_request: display_height >= 0.0

end
