note
	description: "[
		Assault on GW-20: printing. A column of labels and a long document
		are paginated so that no page edge cuts through a label or a line;
		a PDF is written with as many pages; the document goes through the
		Windows file printer (Microsoft Print to PDF) to a file with no
		dialog; landscape turns the sheet; the preview shows the sheets and
		scrolls through them (evidence gw20_page_light.png,
		gw20_preview_light.png).
	]"

class
	SW_PRINT_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Pagination

	test_gw20_no_page_edge_cuts_a_label
		local
			l_col: SW_COLUMN
			l_job: SW_PRINT_JOB
			i, n: INTEGER
			b: REAL_64
		do
			create l_col.make
			from i := 1 until i > 120 loop
				l_col.put (create {SW_LABEL}.make_ui ("Verse " + i.out + ": In the beginning was the Word."))
				i := i + 1
			end
			create l_job.make (l_col, create {SW_PAGE_SETUP}.make_letter, create {SW_THEME}.make_light, Void)
			assert_true ("more than one page: " + l_job.page_count.out, l_job.page_count > 1)
			assert_true ("the pages cover it all", l_job.page_bottom (l_job.page_count) = l_job.printed_height)
			from n := 1 until n >= l_job.page_count loop
				b := l_job.page_bottom (n)
				assert_true ("each page starts where the last ended", l_job.page_top (n + 1) = b)
				assert_true ("no page is taller than the sheet holds",
					b - l_job.page_top (n) <= l_job.setup.content_height_pixels + 0.001)
				across l_col.sub_widgets as ic_label loop
					assert_false ("page " + n.out + " cuts no label",
						ic_label.y < b - 0.001 and ic_label.y + ic_label.height > b + 0.001)
				end
				n := n + 1
			end
		end

	test_gw20_no_page_edge_cuts_a_line_of_a_document
		local
			v: SW_DOCUMENT_VIEW
			d: SIMPLE_DOCUMENT
			l_job: SW_PRINT_JOB
			i, n, u, l: INTEGER
			b, l_top, l_bottom: REAL_64
			kit: SW_SHAPING
		do
			create d.make
			d.add_heading (1, "A long commentary").do_nothing
			from i := 1 until i > 40 loop
				d.add_paragraph ("Paragraph " + i.out + ". In the beginning God created the heaven and the earth. "
					+ "And the earth was without form, and void; and darkness was upon the face of the deep. "
					+ "And the Spirit of God moved upon the face of the waters.").do_nothing
				i := i + 1
			end
			create v.make (400.0)
			v.set_document (d)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (create {SW_THEME}.make_light)
			create l_job.make (v, create {SW_PAGE_SETUP}.make_letter, create {SW_THEME}.make_light, kit)
			assert_true ("the whole document, not a viewport: " + l_job.printed_height.out, l_job.printed_height > 2000.0)
			assert_true ("several pages: " + l_job.page_count.out, l_job.page_count >= 3)
			from n := 1 until n >= l_job.page_count loop
				b := l_job.page_bottom (n)
				from u := 1 until u > v.unit_count loop
					from l := 0 until l >= v.unit_geometry (u).line_count loop
						l_top := v.unit_origin_y (u) + v.unit_geometry (u).top_of_line (l)
						l_bottom := l_top + v.unit_geometry (u).height_of_line (l)
						assert_false ("page " + n.out + " cuts no line", l_top < b - 0.001 and l_bottom > b + 0.001)
						l := l + 1
					end
					u := u + 1
				end
				n := n + 1
			end
		end

feature -- Output

	test_gw20_a_pdf_with_every_page
		local
			l_job: SW_PRINT_JOB
			l_path: STRING_32
			l_file: RAW_FILE
			l_setup: SW_PAGE_SETUP
			l_portrait: SW_PRINT_JOB
		do
			l_job := commentary_job (create {SW_PAGE_SETUP}.make_letter)
			l_path := evidence_path ("gw20_commentary.pdf")
			assert_true ({STRING_32} "written " + l_job.last_error, l_job.write_pdf (l_path))
			if l_job.used_windows_pdf_printer then
				io.put_string ("    GW-20: the PDF went through the Windows PDF printer (cairo.dll cannot write PDF)%N")
			end
			create l_file.make_with_name (l_path)
			l_file.open_read
			l_file.read_stream (5)
			assert_true ("a PDF", l_file.last_string.same_string ("%%PDF-"))
			l_file.close
			assert_true ("a real document: " + l_file.count.out + " bytes", l_file.count > 2000)
			create l_setup.make_a4
			l_setup.set_landscape (True)
			assert_true ("landscape turns the sheet", l_setup.page_width_points > l_setup.page_height_points)
			l_job := commentary_job (l_setup)
			l_portrait := commentary_job (create {SW_PAGE_SETUP}.make_a4)
			assert_true ("a wider sheet lays the text out wider and never taller: " + l_job.printed_height.out + " at "
				+ l_setup.content_width_pixels.out + " against " + l_portrait.printed_height.out + " at " + l_portrait.setup.content_width_pixels.out,
				l_job.printed_height <= l_portrait.printed_height
				and l_setup.content_width_pixels > l_portrait.setup.content_width_pixels)
		end

	test_gw20_prints_through_the_file_printer
			-- Through Microsoft Print to PDF, when it is installed: no dialog,
			-- and the file arrives.
		local
			l_job: SW_PRINT_JOB
			l_printer: SW_PRINTER
			l_path: STRING_32
			l_file: RAW_FILE
			env: EXECUTION_ENVIRONMENT
			l_tries: INTEGER
		do
			create l_printer.make
			if l_printer.has_printer ({STRING_32} "Microsoft Print to PDF") then
				l_job := commentary_job (create {SW_PAGE_SETUP}.make_letter)
				l_path := evidence_path ("gw20_printed.pdf")
				create l_file.make_with_name (l_path)
				if l_file.exists then
					l_file.delete
				end
				assert_true ("the spooler took every page",
					l_job.print_to ({STRING_32} "Microsoft Print to PDF", "simple_widgets GW-20", l_path))
				create env
				from
				until
					(l_file.exists and then l_file.count > 1000) or l_tries > 300
				loop
					env.sleep (100_000_000)
					l_tries := l_tries + 1
				end
				assert_true ("the printed file arrived", l_file.exists and then l_file.count > 1000)
			end
		end

feature -- Preview and evidence

	test_gw20_preview_light
		local
			w: SW_WINDOW
			l_job: SW_PRINT_JOB
			l_preview: SW_PRINT_PREVIEW
			l_image: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
			cairo: SIMPLE_CAIRO
			l_setup: SW_PAGE_SETUP
		do
			create l_setup.make_letter
			l_setup.set_header ("Genesis 1 - a commentary")
			l_job := commentary_job (l_setup)
				-- the first sheet as it prints, at 1.5 pixels a point
			create cairo.make
			l_image := cairo.create_surface ((l_setup.page_width_points * 1.5).ceiling, (l_setup.page_height_points * 1.5).ceiling)
			create l_ctx.make (l_image)
			create l_p.make (l_ctx, l_job.theme)
			l_p.set_shaping (l_job.shaping)
			l_job.draw_page (l_p, 1, 0.0, 0.0, 1.5)
			assert_true ("the sheet written", l_image.write_png (evidence_path ("gw20_page_light.png")))
			l_ctx.destroy
			l_image.destroy
				-- the preview in a window
			create w.make ("preview", 0, 0, 700, 800, create {SW_THEME}.make_light)
			attach_window_kit (w)
			create l_preview.make (l_job)
			w.set_root (l_preview)
			w.request_render
			assert_integers_equal ("starts on the first sheet", 1, l_preview.page_at_top)
			l_preview.show_page (2)
			w.request_render
			assert_integers_equal ("shows the second", 2, l_preview.page_at_top)
			l_preview.show_page (1)
			w.request_render
			assert_true ("the preview written", w.export_widget_png (l_preview, evidence_path ("gw20_preview_light.png"), 1.0))
		end

feature {NONE} -- Fixtures

	commentary_job (a_setup: SW_PAGE_SETUP): SW_PRINT_JOB
			-- Genesis 1:1 in Hebrew, John 1:1 in Greek, and a long English
			-- commentary, on `a_setup''s sheets.
		local
			v: SW_DOCUMENT_VIEW
			d: SIMPLE_DOCUMENT
			kit: SW_SHAPING
			i: INTEGER
		do
			create d.make
			d.add_heading (1, "Genesis 1:1 and John 1:1").do_nothing
			d.add_paragraph (genesis_1_1_wlc).do_nothing
			d.add_paragraph (john_1_1_wh).do_nothing
			from i := 1 until i > 30 loop
				d.add_paragraph ("Note " + i.out + ". In the beginning God created the heaven and the earth. "
					+ "And the earth was without form, and void; and darkness was upon the face of the deep.").do_nothing
				i := i + 1
			end
			create v.make (400.0)
			v.set_document (d)
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (create {SW_THEME}.make_light)
			create Result.make (v, a_setup, create {SW_THEME}.make_light, kit)
		end

	attach_window_kit (a_window: SW_WINDOW)
		local
			kit: SW_SHAPING
		do
			create kit.make_with_assets (shaping_assets)
			kit.set_theme_faces (a_window.theme)
			a_window.set_shaping (kit)
		end

end
