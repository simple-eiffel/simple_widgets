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

feature -- Scan 11 (since 02dae89)

	test_scan11_exports_free_their_memory
			-- HIGH 1 and 2: every export leaked its cairo context and its
			-- image (no dispose on either). Forty exports of a large widget
			-- at four times its size (about 3 megabytes each) must not grow
			-- the process's committed memory by more than a quarter of that.
		local
			w: SW_WINDOW
			lb: SW_LABEL
			path: STRING_32
			i: INTEGER
			l_before, l_after: NATURAL_64
			l_file: RAW_FILE
		do
			create w.make ("scan11", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create lb.make_ui ("Genesis 1:1")
			w.set_root (lb)
			w.request_render
			path := evidence_path ("scan11_leak_probe.png")
			if not path.is_empty then
				assert_true ("one export first (warm caches)", w.export_widget_png (lb, path, 4.0))
				l_before := commit_bytes
				from i := 1 until i > 40 loop
					assert_true ("written", w.export_widget_png (lb, path, 4.0))
					i := i + 1
				end
				l_after := commit_bytes
				create l_file.make_with_name (path)
				l_file.delete
				assert_true ("the probe reads memory", l_before > 0)
				assert_true ("forty exports leave under 32 megabytes behind: grew " + ((l_after - l_before.min (l_after)) // 1_048_576).out + " megabytes",
					l_after < l_before + {NATURAL_64} 33_554_432)
			end
		end

	test_scan11_widget_image_frees_its_context
			-- HIGH 1: the context held a reference to the image, so even a
			-- caller that destroyed the image could not free its pixels.
		local
			w: SW_WINDOW
			lb: SW_LABEL
			img: CAIRO_SURFACE
			i: INTEGER
			l_before, l_after: NATURAL_64
		do
			create w.make ("scan11", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create lb.make_ui ("Genesis 1:1")
			w.set_root (lb)
			w.request_render
			img := w.widget_image (lb, Void, 4.0)
			img.destroy
			l_before := commit_bytes
			from i := 1 until i > 40 loop
				img := w.widget_image (lb, Void, 4.0)
				img.destroy
				i := i + 1
			end
			l_after := commit_bytes
			assert_true ("forty images destroyed by the caller leave under 32 megabytes behind: grew " + ((l_after - l_before.min (l_after)) // 1_048_576).out + " megabytes",
				l_after < l_before + {NATURAL_64} 33_554_432)
		end

	test_scan11_grid_hover_never_exports
			-- MEDIUM 3: the grid lit its scrollbar thumb from `is_hovered', so
			-- silencing hover did not reach it.
		local
			w: SW_WINDOW
			g: SW_DATA_GRID [INTEGER]
			rows: ARRAYED_LIST [INTEGER]
			i, px, py: INTEGER
			hovered_image, plain_image: CAIRO_SURFACE
		do
			create w.make ("scan11", 0, 0, 500, 300, create {SW_THEME}.make_light)
			create g.make (260.0)
			g.add_column (create {SW_GRID_COLUMN [INTEGER]}.make ("n", 120.0, agent (n: INTEGER): STRING_32 do Result := n.out end))
			create rows.make (200)
			from i := 1 until i > 200 loop rows.extend (i); i := i + 1 end
			g.set_rows (rows)
			w.set_root (g)
			w.request_render
			py := (g.bar.thumb_top (g.scroll_y) + g.bar.thumb_height / 2.0).truncated_to_integer
			from px := (g.x + g.width).truncated_to_integer until px < g.x or else g.bar.contains (px, py) loop
				px := px - 1
			end
			assert_true ("found the thumb", g.bar.contains (px, py))
			w.dispatch (13, px, py)
			assert_true ("hovered", g.is_hovered)
			hovered_image := w.widget_image (g, Void, 1.0)
			w.dispatch (14, 0, 0)
			plain_image := w.widget_image (g, Void, 1.0)
			assert_true ("the same pixels", same_pixels (hovered_image, plain_image))
			hovered_image.destroy
			plain_image.destroy
		end

	test_scan11_fractional_edges_are_opaque
			-- MEDIUM 4: the ground was a rectangle the size of the widget, so a
			-- fractional width left the last column half see-through.
		local
			w: SW_WINDOW
			sp: SW_SPACER
			col: SW_COLUMN
			img: CAIRO_SURFACE
		do
			create w.make ("scan11", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create col.make
			create sp.make
			col.add (sp).do_nothing
			w.set_root (col)
			w.request_render
			sp.set_bounds (sp.x, sp.y, 100.5, 40.25)
			img := w.widget_image (sp, Void, 1.0)
			assert_true ("the last column is opaque", pixel (img, img.width - 1, 5) |>> 24 = 0xFF)
			assert_true ("the last row is opaque", pixel (img, 5, img.height - 1) |>> 24 = 0xFF)
			img.destroy
		end

	test_scan11_oversized_export_is_refused
			-- MEDIUM 6: the scale was bounded but the size was not; cairo
			-- cannot make a surface past 32767 pixels a side. `can_export'
			-- says so before anything is asked of cairo.
		local
			w: SW_WINDOW
			sp: SW_SPACER
			col: SW_COLUMN
		do
			create w.make ("scan11", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create col.make
			create sp.make
			col.add (sp).do_nothing
			w.set_root (col)
			w.request_render
			sp.set_bounds (sp.x, sp.y, 9000.0, 40.0)
			assert_false ("9000 pixels at four times is too large", w.can_export (sp, 4.0))
			assert_true ("at once it is fine", w.can_export (sp, 1.0))
		end

feature {NONE} -- Memory

	commit_bytes: NATURAL_64
			-- The process's committed private memory (PagefileUsage), through
			-- K32GetProcessMemoryInfo looked up at run time (its psapi.h
			-- declaration is gated above the Windows 2000 target ISE builds
			-- for); 0 when unavailable.
		external
			"C inline use <windows.h>, <psapi.h>"
		alias
			"PROCESS_MEMORY_COUNTERS l_pmc; BOOL (WINAPI *l_f)(HANDLE, PROCESS_MEMORY_COUNTERS*, DWORD); l_f = (BOOL (WINAPI *)(HANDLE, PROCESS_MEMORY_COUNTERS*, DWORD)) GetProcAddress (GetModuleHandleW (L%"kernel32.dll%"), %"K32GetProcessMemoryInfo%"); l_pmc.cb = sizeof (l_pmc); if (l_f && l_f (GetCurrentProcess (), &l_pmc, sizeof (l_pmc))) return (EIF_NATURAL_64) l_pmc.PagefileUsage; return 0;"
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
