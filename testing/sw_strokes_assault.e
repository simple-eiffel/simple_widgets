note
	description: "[
		Assault on GW-18, SW_PAINTER's dashes, hatches and gradients, read
		back pixel by pixel from an offscreen surface: dashed and dotted
		lines break where a solid line does not, and dots break more
		often; no stroke style, clip or gradient leaks into the next
		drawing; hatching stays inside its shape and a cross hatch carries
		more ink than one direction; a gradient runs from its first colour
		to its second, a fade from its first strength to its second. A
		specimen of every style in both themes is written as evidence
		(gw18_patterns_light.png, gw18_patterns_dark.png).
	]"

class
	SW_STROKES_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Strokes

	test_gw18_dashes_break_and_solid_does_not
			-- Along a horizontal line: solid is ink all the way; dashed breaks
			-- into runs; dotted breaks into more runs than dashed.
		local
			solid, dashed, dotted, dash_dot: INTEGER
		do
			solid := runs_along (Stroke_solid)
			dashed := runs_along (Stroke_dashed)
			dotted := runs_along (Stroke_dotted)
			dash_dot := runs_along (3)
			assert_integers_equal ("solid is one run", 1, solid)
			assert_true ("dashed breaks: " + dashed.out, dashed >= 5)
			assert_true ("dots break more often: " + dotted.out + " against " + dashed.out, dotted > dashed)
			assert_true ("dash-dot shows its dots (two runs a period, period 16.5 pixels): " + dash_dot.out, dash_dot >= 20)
		end

	test_gw18_no_style_leaks
			-- After a dotted line, a plain `line' is solid again; after a
			-- hatch, nothing outside it is inked; after a gradient, `fill_rect'
			-- paints the colour set, flat.
		local
			sf: CAIRO_SURFACE
			p: SW_PAINTER
		do
			sf := surface (120, 60)
			p := painter_on (sf)
			p.set_color (0x000000)
			p.dashed_line (5.0, 10.5, 115.0, 10.5, 1.0, p.Stroke_dotted)
			p.line (5.0, 30.5, 115.0, 30.5, 1.0)
			assert_integers_equal ("a plain line after dots is solid", 1, ink_runs (sf, 30, 5, 114))
			p.hatch_rect (10.0, 40.0, 20.0, 15.0, p.Hatch_cross, 4.0)
			assert_true ("nothing inked right of the hatch", ink_count (sf, 50, 40, 110, 58) = 0)
			p.gradient_rect (0.0, 0.0, 120.0, 8.0, 0xFF0000, 0x0000FF, False)
			p.set_color (0x00FF00)
			p.fill_rect (60.0, 45.0, 20.0, 10.0)
			assert_true ("a flat fill after a gradient", pixel (sf, 62, 50) = 0xFF00FF00 and pixel (sf, 78, 50) = 0xFF00FF00)
			sf.destroy
		end

feature -- Hatches

	test_gw18_hatches_stay_inside_and_cross_carries_more
			-- A hatched rectangle inks part of its inside and nothing of its
			-- outside; cross carries more ink than forward; dots ink less than
			-- either; a hatched polygon stays inside its bounding triangle.
		local
			sf: CAIRO_SURFACE
			p: SW_PAINTER
			l_forward, l_cross, l_dots, l_inside: INTEGER
		do
			l_forward := hatch_ink (Hatch_forward)
			l_cross := hatch_ink (Hatch_cross)
			l_dots := hatch_ink (Hatch_dots)
			assert_true ("forward inks some of it: " + l_forward.out, l_forward > 200 and l_forward < 2500)
			assert_true ("cross inks more than forward", l_cross > l_forward)
			assert_true ("dots carry real ink, and less than cross: " + l_dots.out, l_dots > 250 and l_dots < l_cross)
			sf := surface (100, 100)
			p := painter_on (sf)
			p.set_color (0x000000)
			p.hatch_rrect (20.0, 20.0, 64.0, 40.0, 6.0, Hatch_dots, 6.0)
			assert_true ("dots inside a rounded box carry ink: " + ink_count (sf, 20, 20, 84, 60).out, ink_count (sf, 20, 20, 84, 60) > 150)
			sf.destroy
			sf := surface (100, 100)
			p := painter_on (sf)
			p.set_color (0x000000)
			p.hatch_polygon (<<10.0, 90.0, 90.0, 90.0, 50.0, 10.0>>, 3, p.Hatch_horizontal, 4.0)
			l_inside := ink_count (sf, 10, 10, 90, 90)
			assert_true ("the triangle is hatched", l_inside > 100)
			assert_integers_equal ("its top corners are not", 0, ink_count (sf, 0, 0, 25, 25) + ink_count (sf, 75, 0, 99, 25))
			sf.destroy
		end

feature -- Gradients

	test_gw18_gradients_and_fades_run_end_to_end
			-- Red to blue across: red at the left, blue at the right, both in
			-- the middle. Top to bottom likewise. A fade from opaque to clear
			-- leaves the far end barely touched.
		local
			sf: CAIRO_SURFACE
			p: SW_PAINTER
			l_mid: NATURAL_32
		do
			sf := surface (100, 100)
			p := painter_on (sf)
			p.gradient_rect (0.0, 0.0, 100.0, 20.0, 0xFF0000, 0x0000FF, False)
			assert_true ("red at the left", red_of (pixel (sf, 0, 10)) > 240 and blue_of (pixel (sf, 0, 10)) < 15)
			assert_true ("blue at the right", blue_of (pixel (sf, 99, 10)) > 240 and red_of (pixel (sf, 99, 10)) < 15)
			l_mid := pixel (sf, 50, 10)
			assert_true ("both in the middle", red_of (l_mid) > 90 and blue_of (l_mid) > 90)
			p.gradient_rect (0.0, 30.0, 20.0, 60.0, 0x000000, 0xFFFFFF, True)
			assert_true ("dark at the top, light at the bottom", red_of (pixel (sf, 10, 31)) < 20 and red_of (pixel (sf, 10, 88)) > 230)
			p.set_color (0xFFFFFF)
			p.fill_rect (40.0, 40.0, 60.0, 20.0)
			p.fade_rect (40.0, 40.0, 60.0, 20.0, 0x000000, 1.0, 0.0, False)
			assert_true ("the faded start is dark", red_of (pixel (sf, 40, 50)) < 20)
			assert_true ("its far end barely touched", red_of (pixel (sf, 99, 50)) > 230)
			sf.destroy
		end

feature -- Evidence

	test_gw18_patterns_light
		do
			specimen (create {SW_THEME}.make_light, "gw18_patterns_light.png")
		end

	test_gw18_patterns_dark
		do
			specimen (create {SW_THEME}.make_dark, "gw18_patterns_dark.png")
		end

feature {NONE} -- Fixtures

	Stroke_solid: INTEGER = 0
	Stroke_dashed: INTEGER = 1
	Stroke_dotted: INTEGER = 2
	Hatch_forward: INTEGER = 1
	Hatch_cross: INTEGER = 3
	Hatch_dots: INTEGER = 6

	surface (a_w, a_h: INTEGER): CAIRO_SURFACE
			-- A transparent offscreen surface.
		do
			create Result.make (a_w, a_h)
		end

	painter_on (a_surface: CAIRO_SURFACE): SW_PAINTER
		do
			create Result.make (create {CAIRO_CONTEXT}.make (a_surface), create {SW_THEME}.make_light)
		end

	runs_along (a_style: INTEGER): INTEGER
			-- Ink runs along a 200-pixel line drawn in `a_style'.
		local
			sf: CAIRO_SURFACE
			p: SW_PAINTER
		do
			sf := surface (220, 20)
			p := painter_on (sf)
			p.set_color (0x000000)
			p.dashed_line (10.0, 10.5, 210.0, 10.5, 1.5, a_style)
			Result := ink_runs (sf, 10, 12, 207)
			sf.destroy
		end

	hatch_ink (a_kind: INTEGER): INTEGER
			-- Inked pixels of a 60 by 60 hatch of `a_kind', 6 pixels apart,
			-- after checking nothing outside it was inked.
		local
			sf: CAIRO_SURFACE
			p: SW_PAINTER
		do
			sf := surface (100, 100)
			p := painter_on (sf)
			p.set_color (0x000000)
			p.hatch_rect (20.0, 20.0, 60.0, 60.0, a_kind, 6.0)
			Result := ink_count (sf, 20, 20, 79, 79)
			assert_integers_equal ("nothing outside", 0, ink_count (sf, 0, 0, 99, 99) - Result)
			sf.destroy
		end

	specimen (a_theme: SW_THEME; a_name: STRING)
			-- Every stroke style, every hatch and both blends, in `a_theme'.
		local
			sf: CAIRO_SURFACE
			p: SW_PAINTER
			path: STRING_32
			i: INTEGER
		do
			sf := surface (520, 200)
			create p.make (create {CAIRO_CONTEXT}.make (sf), a_theme)
			p.set_color (a_theme.background)
			p.fill_rect (0.0, 0.0, 520.0, 200.0)
			p.set_color (a_theme.ink)
			from i := 0 until i > 3 loop
				p.dashed_line (20.0, 20.5 + i * 14.0, 240.0, 20.5 + i * 14.0, 2.0, i)
				i := i + 1
			end
			p.set_color (a_theme.accent)
			from i := 1 until i > 6 loop
				p.set_color (a_theme.accent)
				p.hatch_rrect (20.0 + (i - 1) * 80.0, 90.0, 64.0, 40.0, 6.0, i, 6.0)
				p.set_color (a_theme.outline)
				p.dashed_rrect_stroke (20.5 + (i - 1) * 80.0, 90.5, 63.0, 39.0, 6.0, 1.0, p.Stroke_solid)
				i := i + 1
			end
			p.gradient_rect (270.0, 14.0, 230.0, 20.0, a_theme.accent, a_theme.danger, False)
			p.fade_rect (270.0, 44.0, 230.0, 20.0, a_theme.ink, 0.0, 1.0, False)
			p.fade_rect (20.0, 150.0, 480.0, 30.0, a_theme.accent, 0.9, 0.0, False)
			path := evidence_path (a_name)
			if not path.is_empty then
				assert_true ("written", sf.write_png (path))
			end
			sf.destroy
		end

	pixel (a_surface: CAIRO_SURFACE; a_x, a_y: INTEGER): NATURAL_32
		local
			mp: MANAGED_POINTER
		do
			a_surface.flush.do_nothing
			create mp.share_from_pointer (a_surface.data, a_surface.stride * a_surface.height)
			Result := mp.read_natural_32 (a_y * a_surface.stride + a_x * 4)
		end

	red_of (a_argb: NATURAL_32): INTEGER
		do
			Result := ((a_argb |>> 16) & 0xFF).to_integer_32
		end

	blue_of (a_argb: NATURAL_32): INTEGER
		do
			Result := (a_argb & 0xFF).to_integer_32
		end

	is_ink (a_argb: NATURAL_32): BOOLEAN
			-- Drawn on (alpha over a third)?
		do
			Result := (a_argb |>> 24) > 85
		end

	ink_runs (a_surface: CAIRO_SURFACE; a_y, a_from, a_to: INTEGER): INTEGER
			-- Separate inked runs along row `a_y' from `a_from' to `a_to'.
		local
			xx: INTEGER
			l_in: BOOLEAN
		do
			from xx := a_from until xx > a_to loop
				if is_ink (pixel (a_surface, xx, a_y)) then
					if not l_in then
						Result := Result + 1
					end
					l_in := True
				else
					l_in := False
				end
				xx := xx + 1
			end
		end

	ink_count (a_surface: CAIRO_SURFACE; a_x0, a_y0, a_x1, a_y1: INTEGER): INTEGER
			-- Inked pixels in the box, corners included.
		local
			xx, yy: INTEGER
		do
			from yy := a_y0 until yy > a_y1 loop
				from xx := a_x0 until xx > a_x1 loop
					if is_ink (pixel (a_surface, xx, yy)) then
						Result := Result + 1
					end
					xx := xx + 1
				end
				yy := yy + 1
			end
		end

end
