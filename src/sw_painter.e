note
	description: "[
		The only class in the toolkit that touches CAIRO_CONTEXT.
		Widgets draw through these primitives; applications normally
		never see this class at all. `context' remains reachable as the
		escape hatch for custom drawing - the toolkit is a floor, not a
		ceiling.
	]"

class
	SW_PAINTER

create
	make

feature {NONE} -- Initialization

	make (a_context: CAIRO_CONTEXT; a_theme: SW_THEME)
		do
			context := a_context
			theme := a_theme
		ensure
			context_set: context = a_context
			theme_set: theme = a_theme
		end

feature -- Access

	context: CAIRO_CONTEXT
			-- The escape hatch. Custom widgets may draw directly.

	theme: SW_THEME

feature -- Colour

	set_color (a_rgb: NATURAL_32)
		do
			context.set_color_hex (a_rgb.bit_and (0x00FFFFFF)).do_nothing
		end

feature -- Type

	Role_ui: INTEGER = 1
	Role_body: INTEGER = 2
	Role_mono: INTEGER = 3

	font (a_role: INTEGER; a_size: REAL_64; a_bold: BOOLEAN)
		require
			role_known: a_role = Role_ui or a_role = Role_body or a_role = Role_mono
			size_positive: a_size > 0.0
		local
			fam: STRING_32
		do
			inspect a_role
			when 2 then
				fam := theme.family_body
			when 3 then
				fam := theme.family_mono
			else
				fam := theme.family_ui
			end
			if a_bold then
				context.select_font (fam, context.Slant_normal, context.Weight_bold).do_nothing
			else
				context.select_font (fam, context.Slant_normal, context.Weight_normal).do_nothing
			end
			context.set_font_size (a_size).do_nothing
		end

	text (a_x, a_y: REAL_64; a_s: READABLE_STRING_GENERAL)
			-- Draw `a_s' with its baseline at (`a_x', `a_y'), in the
			-- current font and colour.
		do
			context.move_to (a_x, a_y).show_text (a_s.to_string_32).do_nothing
		end

	advance (a_s: READABLE_STRING_GENERAL): REAL_64
			-- Horizontal advance of `a_s' in the current font.
		do
			Result := context.text_extents (a_s.to_string_32).x_advance
		end

feature -- Shapes

	fill_rect (a_x, a_y, a_w, a_h: REAL_64)
		do
			context.rectangle (a_x, a_y, a_w, a_h).fill.do_nothing
		end

	rrect_fill (a_x, a_y, a_w, a_h, a_r: REAL_64)
		do
			rrect_path (a_x, a_y, a_w, a_h, a_r)
			context.fill.do_nothing
		end

	rrect_stroke (a_x, a_y, a_w, a_h, a_r: REAL_64)
			-- One-pixel-honest outline: caller passes half-pixel-snapped
			-- coordinates for crispness.
		do
			rrect_path (a_x, a_y, a_w, a_h, a_r)
			context.stroke.do_nothing
		end

	set_line_width (a_w: REAL_64)
		require
			positive: a_w > 0.0
		do
			context.set_line_width (a_w).do_nothing
		end

	hline (a_x, a_y, a_w: REAL_64)
			-- Theme-outline horizontal hairline.
		do
			set_color (theme.outline)
			fill_rect (a_x, a_y, a_w, 1.0)
		end

	vline (a_x, a_y, a_h: REAL_64)
			-- Theme-outline vertical hairline.
		do
			set_color (theme.outline)
			fill_rect (a_x, a_y, 1.0, a_h)
		end

feature {NONE} -- Implementation

	rrect_path (a_x, a_y, a_w, a_h, a_r: REAL_64)
		do
			context.new_path.do_nothing
			context.arc (a_x + a_w - a_r, a_y + a_r, a_r, -1.5708, 0.0).do_nothing
			context.arc (a_x + a_w - a_r, a_y + a_h - a_r, a_r, 0.0, 1.5708).do_nothing
			context.arc (a_x + a_r, a_y + a_h - a_r, a_r, 1.5708, 3.1416).do_nothing
			context.arc (a_x + a_r, a_y + a_r, a_r, 3.1416, 4.7124).do_nothing
			context.close_path.do_nothing
		end

invariant
	context_attached: context /= Void
	theme_attached: theme /= Void

end
