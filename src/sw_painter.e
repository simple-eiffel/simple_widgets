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

	push_clip (a_x, a_y, a_w, a_h: REAL_64)
			-- Confine drawing to the rectangle until pop_clip; nests.
		do
			context.save.do_nothing
			context.clip_rectangle (a_x, a_y, a_w, a_h).do_nothing
		end

	pop_clip
		do
			context.restore.do_nothing
		end

	set_color_alpha (a_rgb: NATURAL_32; a_alpha: REAL_64)
			-- Colour with transparency, for backdrops and washes.
		require
			alpha_in_range: a_alpha >= 0.0 and a_alpha <= 1.0
		do
			context.set_color_rgba (
				a_rgb.bit_shift_right (16).bit_and (0xFF) / 255.0,
				a_rgb.bit_shift_right (8).bit_and (0xFF) / 255.0,
				a_rgb.bit_and (0xFF) / 255.0,
				a_alpha).do_nothing
		end

	line (a_x1, a_y1, a_x2, a_y2, a_width: REAL_64)
			-- A stroked segment in the current colour.
		require
			positive_width: a_width > 0.0
		do
			context.set_line_width (a_width).do_nothing
			context.move_to (a_x1, a_y1).line_to (a_x2, a_y2).do_nothing
			context.stroke.do_nothing
			context.set_line_width (1.0).do_nothing
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

feature -- Circles

	circle_stroke (a_cx, a_cy, a_r: REAL_64)
			-- Outline a circle. Hygiene lives here: cairo's arc joins
			-- from the current point with a straight line, so the path
			-- is reset first - the 'dash through the circle' bug.
		require
			positive: a_r > 0.0
		do
			context.new_path.do_nothing
			context.arc (a_cx, a_cy, a_r, 0.0, Two_pi).do_nothing
			context.stroke.do_nothing
		end

	circle_fill (a_cx, a_cy, a_r: REAL_64)
		require
			positive: a_r > 0.0
		do
			context.new_path.do_nothing
			context.arc (a_cx, a_cy, a_r, 0.0, Two_pi).do_nothing
			context.fill.do_nothing
		end

	Two_pi: REAL_64 = 6.28319

feature -- Images

	draw_image (a_img: CAIRO_SURFACE; a_x, a_y, a_w, a_h: REAL_64)
			-- Paint `a_img' scaled into the a_w x a_h box at (a_x, a_y).
		require
			loaded: a_img.width > 0 and a_img.height > 0
			positive_box: a_w > 0.0 and a_h > 0.0
		do
			context.save.do_nothing
			context.translate (a_x, a_y).scale (a_w / a_img.width, a_h / a_img.height).do_nothing
			context.set_source_surface (a_img, 0.0, 0.0).paint.do_nothing
			context.restore.do_nothing
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
