note
	description: "W7: SW_CANVAS presents a finished image 1:1 and reports pointer, modifier and size events in simple_gui's vocabulary."

class
	SW_CANVAS_PRESENT_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_a_presented_image_is_drawn_one_to_one
			-- A 40 x 20 pixel red image at scale 2 covers 20 x 10 canvas units, no more.
		local
			th: SW_THEME
			surf, img: CAIRO_SURFACE
			ctx, ictx: CAIRO_CONTEXT
			p: SW_PAINTER
			c: SW_CANVAS
		do
			create th.make_light
			create surf.make (200, 100)
			create ctx.make (surf)
			create p.make (ctx, th)
			create img.make (40, 20)
			create ictx.make (img)
			ictx.set_color_rgb (1.0, 0.0, 0.0).paint.do_nothing
			img.flush.do_nothing
			create c.make (60.0)
			c.set_bounds (10.0, 10.0, 100.0, 60.0)
			c.present_image (img, 2.0)
			c.draw (p)
			surf.flush.do_nothing
			assert ("red inside", is_red (pixel_at (surf, 25, 15)))
			assert ("red at the last unit", is_red (pixel_at (surf, 29, 19)))
			assert ("not past 20 units across", not is_red (pixel_at (surf, 32, 15)))
			assert ("not past 10 units down", not is_red (pixel_at (surf, 25, 22)))
		end

	test_a_forgotten_image_is_no_longer_drawn
			-- `forget_image' before the host frees the image: the canvas draws without it.
		local
			th: SW_THEME
			surf, img: CAIRO_SURFACE
			ctx, ictx: CAIRO_CONTEXT
			p: SW_PAINTER
			c: SW_CANVAS
		do
			create th.make_light
			create surf.make (200, 100)
			create ctx.make (surf)
			create p.make (ctx, th)
			create img.make (40, 20)
			create ictx.make (img)
			ictx.set_color_rgb (1.0, 0.0, 0.0).paint.do_nothing
			img.flush.do_nothing
			create c.make (60.0)
			c.set_bounds (10.0, 10.0, 100.0, 60.0)
			c.present_image (img, 2.0)
			c.forget_image
			ictx.destroy
			img.destroy
			c.draw (p)
			surf.flush.do_nothing
			assert ("no image kept", c.image = Void and c.image_scale = 1.0)
			assert ("nothing red drawn", not is_red (pixel_at (surf, 25, 15)))
		end

	test_a_tabs_switch_draws_both_pages
			-- simple_gui 1x-c: part way through a switch a crossfade blends the two pages, and a
			-- slide shows the old page leaving on one side and the new one coming in on the
			-- other (forward: from the trailing side); at the end only the new page shows.
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			l_tabs: SW_TABS
			l_px: NATURAL_32
		do
			create th.make_light
			create surf.make (200, 100)
			create ctx.make (surf)
			create p.make (ctx, th)
			create l_tabs.make
			l_tabs.set_strip_position (l_tabs.Position_none)
			l_tabs.add_page ("Red", solid_canvas (0xFF0000))
			l_tabs.add_page ("Blue", solid_canvas (0x0000FF))
			l_tabs.set_bounds (0.0, 0.0, 200.0, 100.0)
			l_tabs.select_tab (2)
			l_tabs.show_transition (1, l_tabs.Transition_crossfade, 0.5)
			draw_tabs (l_tabs, ctx, p, surf)
			l_px := pixel_at (surf, 100, 50)
			assert ("crossfade: half red, half blue: " + l_px.to_hex_string,
				channel (l_px, 16) >= 0x60 and channel (l_px, 16) <= 0xA0 and channel (l_px, 0) >= 0x60 and channel (l_px, 0) <= 0xA0)
			l_tabs.show_transition (1, l_tabs.Transition_slide, 0.5)
			draw_tabs (l_tabs, ctx, p, surf)
			assert ("slide: the old page leaves on the left", is_red (pixel_at (surf, 50, 50)))
			assert ("slide: the new page comes in on the right", pixel_at (surf, 150, 50).bit_and (0xFFFFFF) = 0x0000FF)
			l_tabs.show_transition (1, l_tabs.Transition_slide, 1.0)
			assert ("ended", l_tabs.transition_from = 0 and l_tabs.transition_fraction = 1.0)
			draw_tabs (l_tabs, ctx, p, surf)
			assert ("only the new page", pixel_at (surf, 50, 50).bit_and (0xFFFFFF) = 0x0000FF)
		end

	test_pointer_events_carry_kind_button_and_modifiers
		local
			c: SW_CANVAS
			l_log: ARRAYED_LIST [STRING]
		do
			create l_log.make (4)
			create c.make (60.0)
			c.set_bounds (10.0, 20.0, 100.0, 60.0)
			c.set_on_pointer (agent (k: INTEGER; px, py: REAL_64; b, m: INTEGER; a_log: ARRAYED_LIST [STRING])
				do
					a_log.extend (k.out + "@" + px.truncated_to_integer.out + "," + py.truncated_to_integer.out + " b" + b.out + " m" + m.out)
				end (?, ?, ?, ?, ?, l_log))
			;(create {SW_KEYS}).simulate (True, False, True)
			c.handle_click (15.0, 25.0).do_nothing
			;(create {SW_KEYS}).simulate (False, False, False)
			c.handle_drag (30.0, 40.0)
			c.handle_release (31, 41)
			c.set_hover_point (50.0, 60.0)
			assert_integers_equal ("four events", 4, l_log.count)
			assert_strings_equal ("press, canvas-relative, shift and alt", "1@5,5 b1 m5", l_log.i_th (1))
			assert_strings_equal ("motion while dragging", "3@20,20 b0 m0", l_log.i_th (2))
			assert_strings_equal ("release", "2@21,21 b1 m0", l_log.i_th (3))
			assert_strings_equal ("hover motion", "3@40,40 b0 m0", l_log.i_th (4))
		end

	test_a_drag_that_ends_outside_still_releases_the_canvas
			-- MACMINI's W7 point: the press captures the pointer, so motion and the release
			-- outside the canvas still reach it, and plain motion afterwards does not.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			c: SW_CANVAS
			l_spacer: SW_LABEL
			l_log: ARRAYED_LIST [STRING]
			cx, cy, ox, oy: INTEGER
		do
			create l_log.make (4)
			create w.make ("capture", 0, 0, 400, 400, create {SW_THEME}.make_light)
			create col.make
			create c.make (120.0)
			create l_spacer.make_ui ("below")
			col.put (c)
			col.put (l_spacer)
			w.set_root (col)
			w.request_render
			c.set_on_pointer (agent (k: INTEGER; px, py: REAL_64; b, m: INTEGER; a_log: ARRAYED_LIST [STRING])
				do
					a_log.extend (k.out)
				end (?, ?, ?, ?, ?, l_log))
			cx := (c.x + 20.0).truncated_to_integer
			cy := (c.y + 20.0).truncated_to_integer
			ox := (l_spacer.x + 5.0).truncated_to_integer
			oy := (l_spacer.y + 5.0).truncated_to_integer
			w.dispatch ({SHELL_EVENTS}.Event_window_press, cx, cy)
			w.dispatch ({SHELL_EVENTS}.Event_window_drag, ox, oy)
			w.dispatch ({SHELL_EVENTS}.Event_window_release, ox, oy)
			w.dispatch ({SHELL_EVENTS}.Event_window_move, ox + 2, oy + 2)
			assert_integers_equal ("press, motion, release and nothing after", 3, l_log.count)
			assert_strings_equal ("pressed", "1", l_log.i_th (1))
			assert_strings_equal ("dragged outside", "3", l_log.i_th (2))
			assert_strings_equal ("released outside", "2", l_log.i_th (3))
		end

	test_resize_is_told_when_the_size_changes
		local
			c: SW_CANVAS
			l_sizes: ARRAYED_LIST [STRING]
		do
			create l_sizes.make (4)
			create c.make (60.0)
			c.set_on_resize (agent (w, h: REAL_64; a_log: ARRAYED_LIST [STRING])
				do
					a_log.extend (w.truncated_to_integer.out + "x" + h.truncated_to_integer.out)
				end (?, ?, l_sizes))
			c.set_bounds (0.0, 0.0, 100.0, 60.0)
			c.set_bounds (5.0, 5.0, 100.0, 60.0)
			c.set_bounds (5.0, 5.0, 120.0, 60.0)
			c.vanish
			assert_integers_equal ("told twice", 2, l_sizes.count)
			assert_strings_equal ("first size", "100x60", l_sizes.i_th (1))
			assert_strings_equal ("then wider", "120x60", l_sizes.i_th (2))
		end

	test_device_scale_follows_the_theme
		local
			th: SW_THEME
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			p: SW_PAINTER
			c: SW_CANVAS
		do
			create th.make_light
			th.set_text_scale (1.5)
			create surf.make (20, 20)
			create ctx.make (surf)
			create p.make (ctx, th)
			create c.make (60.0)
			assert ("one before layout", c.device_scale = 1.0)
			c.arrange (p)
			assert ("the theme's scale", c.device_scale = 1.5)
		end

feature {NONE} -- Pixels

	pixel_at (a_surface: CAIRO_SURFACE; a_x, a_y: INTEGER): NATURAL_32
			-- ARGB32 pixel at (`a_x', `a_y'). `flush' first.
		require
			in_range: a_x >= 0 and a_y >= 0 and a_x < a_surface.width and a_y < a_surface.height
		local
			mp: MANAGED_POINTER
		do
			create mp.share_from_pointer (a_surface.data, a_surface.stride * a_surface.height)
			Result := mp.read_natural_32 (a_y * a_surface.stride + a_x * 4)
		end

	is_red (a_pixel: NATURAL_32): BOOLEAN
		do
			Result := a_pixel.bit_and (0xFFFFFF) = 0xFF0000
		end

	channel (a_pixel: NATURAL_32; a_shift: INTEGER): NATURAL_32
			-- The 8-bit channel `a_shift' bits up (16 red, 8 green, 0 blue).
		do
			Result := (a_pixel |>> a_shift).bit_and (0xFF)
		end

	solid_canvas (a_rgb: NATURAL_32): SW_CANVAS
			-- A canvas showing a 200 by 100 image all of `a_rgb'.
		local
			l_image: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
		do
			create l_image.make (200, 100)
			create l_ctx.make (l_image)
			l_ctx.set_color_rgb (channel (a_rgb, 16).to_real_64 / 255.0, channel (a_rgb, 8).to_real_64 / 255.0, channel (a_rgb, 0).to_real_64 / 255.0).paint.do_nothing
			l_image.flush.do_nothing
			create Result.make (100.0)
			Result.present_image (l_image, 1.0)
		end

	draw_tabs (a_tabs: SW_TABS; a_ctx: CAIRO_CONTEXT; a_p: SW_PAINTER; a_surface: CAIRO_SURFACE)
			-- White, then `a_tabs' laid out and drawn.
		do
			a_ctx.set_color_rgb (1.0, 1.0, 1.0).paint.do_nothing
			a_tabs.arrange (a_p)
			a_tabs.draw (a_p)
			a_surface.flush.do_nothing
		end

end
