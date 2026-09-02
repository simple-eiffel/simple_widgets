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
			context.set_font_size (a_size * theme.text_scale).do_nothing
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

feature -- Shaped text (simple_shaping)

	shaping: detachable SW_SHAPING
			-- The window's shaping kit, or Void. VOID IS THE DEFAULT AND
			-- IT IS NOT A DEGRADED STATE: every widget that has not been
			-- taught shaped text keeps cairo's toy path, unchanged, which
			-- is what makes this adoption additive.

	has_shaping: BOOLEAN
			-- Is shaped text available through this painter?
		do
			Result := attached shaping
		ensure
			definition: Result = attached shaping
		end

	set_shaping (a_shaping: detachable SW_SHAPING)
			-- Attach `a_shaping' (Void switches every widget back to the
			-- toy path). SW_WINDOW re-attaches after every painter rebuild;
			-- see SW_SHAPING's class note for why the kit outlives us.
		do
			shaping := a_shaping
		ensure
			set: shaping = a_shaping
		end

	is_resize_storm: BOOLEAN
			-- Is the frame being dragged right now? R10: a shaped widget
			-- re-lays-out at resize END, not on every tick, so this is the
			-- flag that tells it to keep the layout it has. SW_WINDOW sets
			-- it from its own `busy_ticks' - the toolkit's existing
			-- two-heartbeats-of-stillness debounce.

	set_resize_storm (a_flag: BOOLEAN)
			-- Say whether a resize storm is in progress.
		do
			is_resize_storm := a_flag
		ensure
			set: is_resize_storm = a_flag
		end

	draw_shaped_layout (a_layout: SHAPED_LAYOUT; a_x, a_y: REAL_64)
			-- Paint `a_layout' with its TOP-LEFT corner at (`a_x', `a_y')
			-- in the CURRENT colour, through the kit's own cairo bridge.
			--
			-- (a_x, a_y) is a top-left, NOT a baseline - unlike `text'.
			-- The layout already knows its lines' ascents, so the caller
			-- never computes one.
			--
			-- ANTIALIAS: the bridge sets an explicit font-antialias mode
			-- before drawing a glyph, and it must - without it cairo's
			-- win32 backend renders same-pixel-size glyphs at about 1/32
			-- scale and reports no error. Nothing in this painter sets a
			-- font antialias mode, so there is no fight; the toy path's
			-- `show_text' is unaffected in every measured respect but
			-- sub-pixel smoothing, which is what a screen wants anyway.
			--
			-- Painting DEGRADES, never raises: a run whose font never
			-- realized is counted in `shaping.bridge.skipped_runs' with a
			-- reason in `last_skip_note'.
		require
			shaping_available: has_shaping
		do
			if attached shaping as al_shaping then
				al_shaping.bridge.draw_layout (context, a_layout, a_x, a_y)
			end
		ensure
			context_survives: context.is_valid
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

	triangle_fill (a_x1, a_y1, a_x2, a_y2, a_x3, a_y3: REAL_64)
			-- A filled triangle - play glyphs, markers, arrowheads.
		do
			context.move_to (a_x1, a_y1).do_nothing
			context.line_to (a_x2, a_y2).do_nothing
			context.line_to (a_x3, a_y3).do_nothing
			context.close_path.do_nothing
			context.fill.do_nothing
		end

	arc_stroke (a_cx, a_cy, a_r, a_from, a_to: REAL_64)
			-- A stroked arc from `a_from' to `a_to' radians - gauge
			-- faces, brake glyphs, partial rings.
		require
			positive_radius: a_r > 0.0
		do
			context.new_path.do_nothing
			context.arc (a_cx, a_cy, a_r, a_from, a_to).do_nothing
			context.stroke.do_nothing
		end

	push_clip (a_x, a_y, a_w, a_h: REAL_64)
			-- Confine drawing to the rectangle until pop_clip; nests.
		do
			context.save.do_nothing
			context.clip_rectangle (a_x, a_y, a_w, a_h).do_nothing
		end

	push_circle_clip (a_cx, a_cy, a_r: REAL_64)
			-- Confine drawing to a disc until pop_clip; nests like
			-- push_clip (save / clip / restore discipline).
		require
			positive: a_r > 0.0
		do
			context.save.do_nothing
			context.new_path.do_nothing
			context.arc (a_cx, a_cy, a_r, 0.0, Two_pi).do_nothing
			context.clip.do_nothing
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

feature -- Paths

	polyline (a_pts: ARRAYED_LIST [TUPLE [px, py: REAL_64]]; a_width: REAL_64)
			-- Stroke the open chain through the points, in order.
		require
			enough: a_pts.count >= 2
			positive_width: a_width > 0.0
		local
			i: INTEGER
		do
			context.new_path.do_nothing
			context.set_line_width (a_width).do_nothing
			context.move_to (a_pts.first.px, a_pts.first.py).do_nothing
			from
				i := 2
			until
				i > a_pts.count
			loop
				context.line_to (a_pts.i_th (i).px, a_pts.i_th (i).py).do_nothing
				i := i + 1
			end
			context.stroke.do_nothing
			context.set_line_width (1.0).do_nothing
		end

	polygon_fill_flat (a_xy: ARRAY [REAL_64]; a_count: INTEGER)
			-- Fill the polygon whose SCREEN points are the first
			-- `a_count' (x, y) pairs of flat `a_xy' - the zero-
			-- allocation sibling of polygon_fill, for big geometry
			-- (the world's 4,964 coastline points, every frame).
		require
			enough: a_count >= 3
			fits: a_count * 2 <= a_xy.count
		local
			i: INTEGER
		do
			context.new_path.do_nothing
			context.move_to (a_xy [a_xy.lower], a_xy [a_xy.lower + 1]).do_nothing
			from
				i := 1
			until
				i >= a_count
			loop
				context.line_to (a_xy [a_xy.lower + i * 2], a_xy [a_xy.lower + i * 2 + 1]).do_nothing
				i := i + 1
			end
			context.close_path.do_nothing
			context.fill.do_nothing
		end

	polygon_fill (a_pts: ARRAYED_LIST [TUPLE [px, py: REAL_64]])
			-- Fill the closed ring through the points (closure is
			-- implicit; same path hygiene as circles).
		require
			enough: a_pts.count >= 3
		local
			i: INTEGER
		do
			context.new_path.do_nothing
			context.move_to (a_pts.first.px, a_pts.first.py).do_nothing
			from
				i := 2
			until
				i > a_pts.count
			loop
				context.line_to (a_pts.i_th (i).px, a_pts.i_th (i).py).do_nothing
				i := i + 1
			end
			context.close_path.do_nothing
			context.fill.do_nothing
		end

feature -- Ribbons

	ribbon_fill (a_x0, a_y0_top, a_y0_bot, a_x1, a_y1_top, a_y1_bot: REAL_64)
			-- A filled band between two vertical edges, its top and
			-- bottom rails cubic beziers with midpoint control - the
			-- sankey ribbon (the painter gains curves here, as the
			-- roadmap said it would).
		require
			edges_ordered: a_y0_bot >= a_y0_top and a_y1_bot >= a_y1_top
		local
			mid: REAL_64
		do
			mid := (a_x0 + a_x1) / 2.0
			context.new_path.do_nothing
			context.move_to (a_x0, a_y0_top).do_nothing
			context.curve_to (mid, a_y0_top, mid, a_y1_top, a_x1, a_y1_top).do_nothing
			context.line_to (a_x1, a_y1_bot).do_nothing
			context.curve_to (mid, a_y1_bot, mid, a_y0_bot, a_x0, a_y0_bot).do_nothing
			context.close_path.do_nothing
			context.fill.do_nothing
		end

feature -- Wedges

	wedge_fill (a_cx, a_cy, a_r_out, a_r_in, a_a0, a_a1: REAL_64)
			-- A filled slice from angle a0 to a1 (radians, cairo
			-- convention). r_in = 0 gives a solid wedge to the
			-- centre; r_in > 0 gives a TRUE ring segment - arc out,
			-- arc_negative back, no overlay fakery.
		require
			radii_sane: a_r_out > 0.0 and a_r_in >= 0.0 and a_r_in < a_r_out
		do
			wedge_path (a_cx, a_cy, a_r_out, a_r_in, a_a0, a_a1)
			context.fill.do_nothing
		end

	wedge_stroke (a_cx, a_cy, a_r_out, a_r_in, a_a0, a_a1: REAL_64)
			-- The same slice, outlined.
		require
			radii_sane: a_r_out > 0.0 and a_r_in >= 0.0 and a_r_in < a_r_out
		do
			wedge_path (a_cx, a_cy, a_r_out, a_r_in, a_a0, a_a1)
			context.stroke.do_nothing
		end

feature {NONE} -- Wedge path

	wedge_path (a_cx, a_cy, a_r_out, a_r_in, a_a0, a_a1: REAL_64)
		do
			context.new_path.do_nothing
			if a_r_in <= 0.0 then
				context.move_to (a_cx, a_cy).do_nothing
				context.arc (a_cx, a_cy, a_r_out, a_a0, a_a1).do_nothing
			else
				context.arc (a_cx, a_cy, a_r_out, a_a0, a_a1).do_nothing
				context.arc_negative (a_cx, a_cy, a_r_in, a_a1, a_a0).do_nothing
			end
			context.close_path.do_nothing
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

	star_fill (a_cx, a_cy, a_r: REAL_64)
			-- A filled five-point star; same path hygiene as circles.
		require
			positive: a_r > 0.0
		do
			star_path (a_cx, a_cy, a_r)
			context.fill.do_nothing
		end

	star_stroke (a_cx, a_cy, a_r: REAL_64)
		require
			positive: a_r > 0.0
		do
			star_path (a_cx, a_cy, a_r)
			context.stroke.do_nothing
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

feature -- Glyphs (R7-pure: primitives, no font gambling)

	Glyph_plus: INTEGER = 1
	Glyph_minus: INTEGER = 2
	Glyph_close: INTEGER = 3
	Glyph_check: INTEGER = 4
	Glyph_chevron_right: INTEGER = 5
	Glyph_chevron_down: INTEGER = 6
	Glyph_chevron_left: INTEGER = 7
	Glyph_chevron_up: INTEGER = 8
	Glyph_search: INTEGER = 9
	Glyph_gear: INTEGER = 10
	Glyph_trash: INTEGER = 11
	Glyph_pencil: INTEGER = 12
	Glyph_folder: INTEGER = 13
	Glyph_document: INTEGER = 14
	Glyph_refresh: INTEGER = 15
	Glyph_play: INTEGER = 16
	Glyph_pause: INTEGER = 17
	Glyph_stop: INTEGER = 18
	Glyph_dots: INTEGER = 19
	Glyph_menu: INTEGER = 20
	Glyph_info: INTEGER = 21
	Glyph_warning: INTEGER = 22
	Glyph_tray: INTEGER = 23
	Glyph_offline: INTEGER = 24
	Glyph_error: INTEGER = 25

	glyph (a_kind: INTEGER; a_cx, a_cy, a_s: REAL_64)
			-- Draw glyph `a_kind' centred at (a_cx, a_cy) inside a
			-- box `a_s' on a side, in the CURRENT colour. Drawn from
			-- primitives so every face ships on every machine - no
			-- font-glyph gambling (R7).
		require
			known: a_kind >= Glyph_plus and a_kind <= Glyph_error
			positive: a_s > 0.0
		local
			m: DOUBLE_MATH
			h, lw, ang: REAL_64
			pts: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			k: INTEGER
		do
			create m
			h := a_s / 2.0
			lw := (a_s / 8.0).max (1.4)
			inspect a_kind
			when 1 then
				line (a_cx - h * 0.8, a_cy, a_cx + h * 0.8, a_cy, lw)
				line (a_cx, a_cy - h * 0.8, a_cx, a_cy + h * 0.8, lw)
			when 2 then
				line (a_cx - h * 0.8, a_cy, a_cx + h * 0.8, a_cy, lw)
			when 3 then
				line (a_cx - h * 0.6, a_cy - h * 0.6, a_cx + h * 0.6, a_cy + h * 0.6, lw)
				line (a_cx - h * 0.6, a_cy + h * 0.6, a_cx + h * 0.6, a_cy - h * 0.6, lw)
			when 4 then
				create pts.make (3)
				pts.extend ([a_cx - h * 0.7, a_cy + h * 0.05])
				pts.extend ([a_cx - h * 0.15, a_cy + h * 0.55])
				pts.extend ([a_cx + h * 0.75, a_cy - h * 0.55])
				polyline (pts, lw)
			when 5 then
				create pts.make (3)
				pts.extend ([a_cx - h * 0.3, a_cy - h * 0.65])
				pts.extend ([a_cx + h * 0.35, a_cy])
				pts.extend ([a_cx - h * 0.3, a_cy + h * 0.65])
				polyline (pts, lw)
			when 6 then
				create pts.make (3)
				pts.extend ([a_cx - h * 0.65, a_cy - h * 0.3])
				pts.extend ([a_cx, a_cy + h * 0.35])
				pts.extend ([a_cx + h * 0.65, a_cy - h * 0.3])
				polyline (pts, lw)
			when 7 then
				create pts.make (3)
				pts.extend ([a_cx + h * 0.3, a_cy - h * 0.65])
				pts.extend ([a_cx - h * 0.35, a_cy])
				pts.extend ([a_cx + h * 0.3, a_cy + h * 0.65])
				polyline (pts, lw)
			when 8 then
				create pts.make (3)
				pts.extend ([a_cx - h * 0.65, a_cy + h * 0.3])
				pts.extend ([a_cx, a_cy - h * 0.35])
				pts.extend ([a_cx + h * 0.65, a_cy + h * 0.3])
				polyline (pts, lw)
			when 9 then
				circle_stroke (a_cx - h * 0.15, a_cy - h * 0.15, h * 0.5)
				line (a_cx + h * 0.25, a_cy + h * 0.25, a_cx + h * 0.72, a_cy + h * 0.72, lw)
			when 10 then
				circle_stroke (a_cx, a_cy, h * 0.26)
				circle_stroke (a_cx, a_cy, h * 0.58)
				from
					k := 0
				until
					k > 7
				loop
					ang := k * 0.785398163397448
					line (a_cx + h * 0.58 * m.cosine (ang), a_cy + h * 0.58 * m.sine (ang),
						a_cx + h * 0.9 * m.cosine (ang), a_cy + h * 0.9 * m.sine (ang), lw)
					k := k + 1
				end
			when 11 then
				rrect_stroke (a_cx - h * 0.5, a_cy - h * 0.35, a_s * 0.5, a_s * 0.6, 1.5)
				line (a_cx - h * 0.72, a_cy - h * 0.35, a_cx + h * 0.72, a_cy - h * 0.35, lw)
				line (a_cx - h * 0.25, a_cy - h * 0.35, a_cx - h * 0.1, a_cy - h * 0.62, lw)
				line (a_cx + h * 0.25, a_cy - h * 0.35, a_cx + h * 0.1, a_cy - h * 0.62, lw)
				vline (a_cx - h * 0.18, a_cy - h * 0.1, a_s * 0.32)
				vline (a_cx + h * 0.18, a_cy - h * 0.1, a_s * 0.32)
			when 12 then
				line (a_cx - h * 0.55, a_cy + h * 0.55, a_cx + h * 0.45, a_cy - h * 0.45, lw * 1.8)
				create pts.make (3)
				pts.extend ([a_cx - h * 0.75, a_cy + h * 0.75])
				pts.extend ([a_cx - h * 0.55, a_cy + h * 0.3])
				pts.extend ([a_cx - h * 0.3, a_cy + h * 0.55])
				polygon_fill (pts)
			when 13 then
				rrect_stroke (a_cx - h * 0.8, a_cy - h * 0.4, a_s * 0.8, a_s * 0.62, 1.5)
				line (a_cx - h * 0.8, a_cy - h * 0.55, a_cx - h * 0.25, a_cy - h * 0.55, lw)
				line (a_cx - h * 0.25, a_cy - h * 0.55, a_cx - h * 0.12, a_cy - h * 0.4, lw)
			when 14 then
				rrect_stroke (a_cx - h * 0.55, a_cy - h * 0.75, a_s * 0.55, a_s * 0.75, 1.5)
				hline (a_cx - h * 0.32, a_cy - h * 0.25, a_s * 0.32)
				hline (a_cx - h * 0.32, a_cy, a_s * 0.32)
				hline (a_cx - h * 0.32, a_cy + h * 0.25, a_s * 0.32)
			when 15 then
				wedge_stroke (a_cx, a_cy, h * 0.72, h * 0.5, 0.5, 5.2)
				create pts.make (3)
				pts.extend ([a_cx + h * 0.35, a_cy - h * 0.9])
				pts.extend ([a_cx + h * 0.95, a_cy - h * 0.5])
				pts.extend ([a_cx + h * 0.25, a_cy - h * 0.25])
				polygon_fill (pts)
			when 16 then
				create pts.make (3)
				pts.extend ([a_cx - h * 0.45, a_cy - h * 0.65])
				pts.extend ([a_cx + h * 0.65, a_cy])
				pts.extend ([a_cx - h * 0.45, a_cy + h * 0.65])
				polygon_fill (pts)
			when 17 then
				fill_rect (a_cx - h * 0.5, a_cy - h * 0.6, a_s * 0.18, a_s * 0.6)
				fill_rect (a_cx + h * 0.14, a_cy - h * 0.6, a_s * 0.18, a_s * 0.6)
			when 18 then
				fill_rect (a_cx - h * 0.5, a_cy - h * 0.5, a_s * 0.5, a_s * 0.5)
			when 19 then
				circle_fill (a_cx - h * 0.55, a_cy, lw * 0.8)
				circle_fill (a_cx, a_cy, lw * 0.8)
				circle_fill (a_cx + h * 0.55, a_cy, lw * 0.8)
			when 20 then
				line (a_cx - h * 0.7, a_cy - h * 0.45, a_cx + h * 0.7, a_cy - h * 0.45, lw)
				line (a_cx - h * 0.7, a_cy, a_cx + h * 0.7, a_cy, lw)
				line (a_cx - h * 0.7, a_cy + h * 0.45, a_cx + h * 0.7, a_cy + h * 0.45, lw)
			when 21 then
				circle_stroke (a_cx, a_cy, h * 0.8)
				circle_fill (a_cx, a_cy - h * 0.4, lw * 0.7)
				line (a_cx, a_cy - h * 0.05, a_cx, a_cy + h * 0.45, lw)
			when 22 then
				create pts.make (4)
				pts.extend ([a_cx, a_cy - h * 0.75])
				pts.extend ([a_cx + h * 0.8, a_cy + h * 0.6])
				pts.extend ([a_cx - h * 0.8, a_cy + h * 0.6])
				pts.extend ([a_cx, a_cy - h * 0.75])
				polyline (pts, lw)
				line (a_cx, a_cy - h * 0.3, a_cx, a_cy + h * 0.15, lw)
				circle_fill (a_cx, a_cy + h * 0.38, lw * 0.6)
			when 23 then
				rrect_stroke (a_cx - h, a_cy - h * 0.73, a_s, a_s * 0.73, a_s * 0.115)
				line (a_cx - h, a_cy - h * 0.115, a_cx - h * 0.385, a_cy - h * 0.115, lw)
				line (a_cx + h * 0.385, a_cy - h * 0.115, a_cx + h, a_cy - h * 0.115, lw)
				line (a_cx - h * 0.385, a_cy - h * 0.115, a_cx - h * 0.23, a_cy + h * 0.19, lw)
				line (a_cx + h * 0.385, a_cy - h * 0.115, a_cx + h * 0.23, a_cy + h * 0.19, lw)
				line (a_cx - h * 0.23, a_cy + h * 0.19, a_cx + h * 0.23, a_cy + h * 0.19, lw)
			when 24 then
				wedge_stroke (a_cx, a_cy + h * 0.5, h * 0.95, h * 0.85, 3.665, 5.76)
				wedge_stroke (a_cx, a_cy + h * 0.5, h * 0.6, h * 0.5, 3.665, 5.76)
				circle_fill (a_cx, a_cy + h * 0.35, lw * 0.8)
				line (a_cx - h * 0.8, a_cy + h * 0.8, a_cx + h * 0.8, a_cy - h * 0.8, lw)
			when 25 then
				circle_stroke (a_cx, a_cy, h * 0.8)
				line (a_cx, a_cy - h * 0.45, a_cx, a_cy + h * 0.05, lw)
				circle_fill (a_cx, a_cy + h * 0.4, lw * 0.7)
			end
		end

feature {NONE} -- Star geometry

	star_path (a_cx, a_cy, a_r: REAL_64)
			-- Ten vertices alternating outer and inner radius, path
			-- reset first (cairo joins from the current point).
		local
			m: DOUBLE_MATH
			i: INTEGER
			ang, rr, px, py: REAL_64
		do
			create m
			context.new_path.do_nothing
			from
				i := 0
			until
				i >= 10
			loop
				ang := -1.5708 + i * Two_pi / 10.0
				if i \\ 2 = 0 then
					rr := a_r
				else
					rr := a_r * 0.42
				end
				px := a_cx + rr * m.cosine (ang)
				py := a_cy + rr * m.sine (ang)
				if i = 0 then
					context.move_to (px, py).do_nothing
				else
					context.line_to (px, py).do_nothing
				end
				i := i + 1
			end
			context.close_path.do_nothing
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
