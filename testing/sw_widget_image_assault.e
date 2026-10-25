note
	description: "[
		Assault on GW-21, a widget region to PNG: the image is the widget
		alone at the asked scale, light by default even from a dark
		window, the screen theme when asked, never shows hover, leaves the
		widget where it was, writes a PNG that reads back at its size, and
		reaches the clipboard. Scripture exported from a dark window in
		light and in the screen theme (evidence gw21_export_light.png,
		gw21_export_screen.png). Inherits the shaping assault for its
		scripture fixtures and kit.
	]"

class
	SW_WIDGET_IMAGE_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- The image

	test_gw21_the_widget_alone_at_scale_in_light
			-- From a dark window, the export of one label is twice its size
			-- and stands on the LIGHT background; the window keeps its dark
			-- theme and the label keeps its place.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			lb: SW_LABEL
			img: CAIRO_SURFACE
			l_light: SW_THEME
			bx, by, bw, bh: REAL_64
		do
			create w.make ("gw21", 0, 0, 600, 300, create {SW_THEME}.make_dark)
			create col.make
			col.add (create {SW_LABEL}.make_ui ("above")).do_nothing
			create lb.make_ui ("Genesis 1:1")
			col.add (lb).do_nothing
			w.set_root (col)
			w.request_render
			bx := lb.x; by := lb.y; bw := lb.width; bh := lb.height
			img := w.widget_image (lb, Void, 2.0)
			assert_integers_equal ("twice as wide, margin included", ((bw + 2.0 * w.export_margin (w.export_theme)) * 2.0).ceiling, img.width)
			assert_integers_equal ("twice as tall, margin included", ((bh + 2.0 * w.export_margin (w.export_theme)) * 2.0).ceiling, img.height)
			create l_light.make_light
			assert_true ("on the light background", pixel (img, 0, 0) = {NATURAL_32} 0xFF000000 | l_light.background)
			assert_true ("the window stays dark", w.theme.is_dark)
			assert_true ("the label stays put", lb.x = bx and lb.y = by and lb.width = bw and lb.height = bh)
		end

	test_gw21_the_screen_theme_when_asked
			-- With `exports_in_screen_theme' the export stands on the dark
			-- background of the dark window.
		local
			w: SW_WINDOW
			lb: SW_LABEL
			img: CAIRO_SURFACE
		do
			create w.make ("gw21", 0, 0, 600, 300, create {SW_THEME}.make_dark)
			create lb.make_ui ("Genesis 1:1")
			w.set_root (lb)
			w.request_render
			w.set_exports_in_screen_theme (True)
			img := w.widget_image (lb, Void, 1.0)
			assert_true ("on the dark background", pixel (img, 0, 0) = {NATURAL_32} 0xFF000000 | w.theme.background)
		end

	test_gw21_hover_never_exports
			-- A hovered button exports exactly as an unhovered one, and is
			-- still hovered afterwards.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			b: SW_BUTTON
			hovered_image, plain_image: CAIRO_SURFACE
		do
			create w.make ("gw21", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create col.make
			create b.make ("Export", Void)
			col.add (b).do_nothing
			col.add (create {SW_LABEL}.make_ui ("below")).do_nothing
			w.set_root (col)
			w.request_render
			w.dispatch (13, (b.x + b.width / 2.0).truncated_to_integer, (b.y + b.height / 2.0).truncated_to_integer)
			assert_true ("hovered", b.shows_hover)
			hovered_image := w.widget_image (b, Void, 1.0)
			assert_true ("still hovered afterwards", b.shows_hover)
			w.dispatch (14, 0, 0)
			assert_false ("not hovered", b.shows_hover)
			plain_image := w.widget_image (b, Void, 1.0)
			assert_true ("the same pixels", same_pixels (hovered_image, plain_image))
		end

	test_gw21_png_reads_back_and_clipboard_takes_it
			-- The PNG reads back at the asked size; copy-as-image puts an
			-- image of that size on the clipboard.
		local
			w: SW_WINDOW
			lb: SW_LABEL
			path: STRING_32
			back: CAIRO_SURFACE
			clip: SW_CLIPBOARD
		do
			create w.make ("gw21", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create lb.make_ui ("Genesis 1:1")
			w.set_root (lb)
			w.request_render
			path := evidence_path ("gw21_readback.png")
			if not path.is_empty then
				assert_true ("written", w.export_widget_png (lb, path, 2.0))
				create back.make_from_png (path)
				assert_integers_equal ("reads back at twice the width", ((lb.width + 2.0 * w.export_margin (w.export_theme)) * 2.0).ceiling, back.width)
				(create {RAW_FILE}.make_with_name (path)).delete
			end
			w.copy_widget_image (lb, 1.0)
			create clip
			assert_true ("an image on the clipboard", clip.has_image)
			assert_integers_equal ("of the label's width", (lb.width + 2.0 * w.export_margin (w.export_theme)).ceiling, clip.image_width)
		end

feature -- Scripture exported

	test_gw21_scripture_export
			-- A pane of pointed Hebrew, polytonic Greek and a mixed line in a
			-- dark window, exported in light (the default) and in the screen
			-- theme, at twice the size.
		local
			w: SW_WINDOW
			th: SW_THEME
			kit: SW_SHAPING
			col: SW_COLUMN
			path: STRING_32
		do
			create th.make_dark
			create w.make ("gw21", 0, 0, 760, 260, th)
			kit := gw03_kit (th)
			w.set_shaping (kit)
			create col.make
			col.add (create {SW_LABEL}.make_body (genesis_1_1_wlc)).do_nothing
			col.add (create {SW_LABEL}.make_body (john_1_1_wh_nfc)).do_nothing
			col.add (create {SW_LABEL}.make_body (mixed_english_hebrew)).do_nothing
			w.set_root (col)
			w.request_render
			path := evidence_path ("gw21_export_light.png")
			if not path.is_empty then
				assert_true ("light export written", w.export_widget_png (col, path, 2.0))
			end
			w.set_exports_in_screen_theme (True)
			path := evidence_path ("gw21_export_screen.png")
			if not path.is_empty then
				assert_true ("screen export written", w.export_widget_png (col, path, 2.0))
			end
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
		end

feature {NONE} -- Pixels

	pixel (a_surface: CAIRO_SURFACE; a_x, a_y: INTEGER): NATURAL_32
			-- The ARGB pixel at (`a_x', `a_y').
		local
			mp: MANAGED_POINTER
		do
			a_surface.flush.do_nothing
			create mp.share_from_pointer (a_surface.data, a_surface.stride * a_surface.height)
			Result := mp.read_natural_32 (a_y * a_surface.stride + a_x * 4)
		end

	same_pixels (a, b: CAIRO_SURFACE): BOOLEAN
			-- Same size and every pixel equal?
		local
			xx, yy: INTEGER
		do
			Result := a.width = b.width and a.height = b.height
			from yy := 0 until yy >= a.height or not Result loop
				from xx := 0 until xx >= a.width or not Result loop
					Result := pixel (a, xx, yy) = pixel (b, xx, yy)
					xx := xx + 1
				end
				yy := yy + 1
			end
		end

end
