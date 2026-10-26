note
	description: "[
		GW-20: a widget printed - to a PDF file, to a printer, or shown in
		SW_PRINT_PREVIEW. The widget is laid out at the page's content width
		and its whole printable height (`SW_WIDGET.print_height'), then cut
		into pages where `SW_WIDGET.clean_break' says a page may end without
		cutting through a line; where no clean break comes in the last three
		quarters of a page, the page is cut at its foot. Pages are drawn in
		vector through SW_PAINTER on paper-white grounds in the theme's
		faces, with the setup's header and page numbers in the margins.

		Give it a widget that is not on screen (a second view of the same
		document): printing lays the widget out at the paper's width.
	]"

class
	SW_PRINT_JOB

create
	make

feature {NONE} -- Initialization

	make (a_widget: SW_WIDGET; a_setup: SW_PAGE_SETUP; a_theme: SW_THEME; a_shaping: detachable SW_SHAPING)
			-- Print `a_widget' on `a_setup''s sheets in `a_theme''s faces
			-- (on white paper), shaping with `a_shaping'.
		require
			off_screen: a_widget.parent = Void
		do
			widget := a_widget
			setup := a_setup
			shaping := a_shaping
			create theme.make_light
			theme.adopt_metrics_from (a_theme)
			theme.set_surfaces (0xFFFFFF, 0xFFFFFF, theme.surface_variant, theme.outline, theme.ink, theme.ink_muted)
			create cairo.make
			create page_tops.make (4)
			create page_bottoms.make (4)
			paginate
		ensure
			kept: widget = a_widget and setup = a_setup
			paginated: page_count >= 1
		end

feature -- Access

	widget: SW_WIDGET
			-- What is printed.

	setup: SW_PAGE_SETUP
			-- The sheet.

	theme: SW_THEME
			-- The faces and inks, on paper white.

	shaping: detachable SW_SHAPING

	page_count: INTEGER
		do
			Result := page_tops.count
		end

	page_top (a_page: INTEGER): REAL_64
			-- Where page `a_page' starts in the widget, in its pixels.
		require
			known: a_page >= 1 and a_page <= page_count
		do
			Result := page_tops.i_th (a_page)
		end

	page_bottom (a_page: INTEGER): REAL_64
		require
			known: a_page >= 1 and a_page <= page_count
		do
			Result := page_bottoms.i_th (a_page)
		end

	printed_height: REAL_64
			-- The widget's whole printable height, in its pixels.

	last_error: STRING_32
			-- Why the last output failed; empty when it did not.
		attribute
			create Result.make_empty
		end

feature -- Pagination

	paginate
			-- Lay the widget out at the content width and cut it into pages.
		local
			l_image: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
			l_width, l_page, l_top, l_end: REAL_64
		do
			l_image := cairo.create_surface (1, 1)
			create l_ctx.make (l_image)
			l_p := new_painter (l_ctx)
			l_width := setup.content_width_pixels
			l_page := setup.content_height_pixels
			printed_height := widget.print_height (l_p, l_width).max (1.0)
			widget.set_bounds (0.0, 0.0, l_width, printed_height)
			widget.arrange (l_p)
			page_tops.wipe_out
			page_bottoms.wipe_out
			from
				l_top := 0.0
			until
				l_top >= printed_height - 0.5
			loop
				l_end := (l_top + l_page).min (printed_height)
				if l_end < printed_height then
					l_end := widget.clean_break (l_end)
					if l_end <= l_top + l_page * 0.25 then
							-- nothing clean in the last three quarters: cut at the foot
						l_end := (l_top + l_page).min (printed_height)
					end
				end
				page_tops.extend (l_top)
				page_bottoms.extend (l_end)
				l_top := l_end
			end
			if page_tops.is_empty then
				page_tops.extend (0.0)
				page_bottoms.extend (printed_height)
			end
			l_ctx.destroy
			l_image.destroy
		ensure
			at_least_one: page_count >= 1
			parallel: page_tops.count = page_bottoms.count
		end

feature -- Drawing

	draw_page (a_p: SW_PAINTER; a_page: INTEGER; a_left, a_top, a_scale: REAL_64)
			-- Sheet `a_page' through `a_p' with its top left at (`a_left',
			-- `a_top'), `a_scale' painter units to a point: white paper, the
			-- header, the content slice, the page number.
		require
			known: a_page >= 1 and a_page <= page_count
			positive: a_scale > 0.0
		local
			l_ppp, l_w, l_h, l_m, l_slice: REAL_64
			l_number: STRING_32
		do
			l_ppp := setup.points_per_pixel
			a_p.push_transform (a_left, a_top, a_scale)
			a_p.set_color (0xFFFFFF)
			a_p.fill_rect (0.0, 0.0, setup.page_width_points, setup.page_height_points)
			a_p.push_transform (setup.margin_points, setup.margin_points, l_ppp)
				-- now in widget pixels, the content area's top left at the origin
			l_w := setup.content_width_pixels
			l_h := setup.content_height_pixels
			l_m := setup.margin_pixels
			a_p.font ({SW_PAINTER}.Role_ui, 10.0, False)
			a_p.set_color (theme.ink_muted)
			if not setup.header.is_empty then
				a_p.text (0.0, -l_m / 2.0, setup.header)
			end
			if setup.show_page_numbers then
				l_number := {STRING_32} "Page " + a_page.out.to_string_32 + {STRING_32} " of " + page_count.out.to_string_32
				a_p.text (l_w - a_p.advance (l_number), l_h + l_m / 2.0 + a_p.font_ascent, l_number)
			end
			l_slice := page_bottom (a_page) - page_top (a_page)
			a_p.push_clip (0.0, 0.0, l_w, l_slice)
			a_p.push_transform (0.0, -page_top (a_page), 1.0)
			widget.draw (a_p)
			a_p.pop_transform
			a_p.pop_clip
			a_p.pop_transform
			a_p.pop_transform
		end

feature -- Output

	write_pdf (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Every page into a PDF file at `a_path'. True when it was
			-- written. Through cairo's PDF backend; when that fails, through
			-- the Windows PDF printer, waiting for the spooler (the cairo.dll
			-- shipped in 2026-10 cannot write PDF: its first page fails with
			-- "out of memory" - see simple_cairo's CHANGELOG. A rebuilt DLL
			-- makes the first route work again with no change here).
		require
			path_given: not a_path.is_empty
		local
			l_printer: SW_PRINTER
			l_cairo_error: STRING_32
		do
			last_error.wipe_out
			used_windows_pdf_printer := False
			Result := written_through_cairo (a_path)
			if not Result then
				l_cairo_error := last_error.twin
				delete_file (a_path)
				create l_printer.make
				if l_printer.has_printer (Windows_pdf_printer) then
					last_error.wipe_out
					used_windows_pdf_printer := True
					Result := print_to (Windows_pdf_printer, file_title (a_path), a_path) and then file_arrives (a_path)
					if not Result and last_error.is_empty then
						last_error := {STRING_32} "the Windows PDF printer did not write " + a_path.to_string_32
					end
				end
				if not Result then
					last_error := {STRING_32} "cairo: " + l_cairo_error + {STRING_32} "; " + last_error
				end
			end
		end

	used_windows_pdf_printer: BOOLEAN
			-- Did the last `write_pdf' go through the Windows PDF printer?

	Windows_pdf_printer: STRING_32 = "Microsoft Print to PDF"
			-- The file printer Windows installs.

	Pdf_wait_seconds: INTEGER = 30
			-- How long `write_pdf' waits for the spooler's file.

	print_to (a_printer, a_title: READABLE_STRING_GENERAL; a_output: detachable READABLE_STRING_GENERAL): BOOLEAN
			-- Every page to printer `a_printer' as a document titled
			-- `a_title' (into file `a_output' when the printer writes files).
			-- True when the spooler took every page.
		require
			printer_named: not a_printer.is_empty
		local
			l_printer: SW_PRINTER
			l_surface: CAIRO_SURFACE
			l_ctx: CAIRO_CONTEXT
			l_p: SW_PAINTER
			i: INTEGER
			l_dots: REAL_64
		do
			create l_printer.make
			if not l_printer.is_printing and then
				l_printer.begin_document (a_printer, a_title, a_output, setup.paper, setup.is_landscape)
			then
				Result := True
				l_dots := l_printer.dots_per_inch_x / 72.0
				from
					i := 1
				until
					i > page_count or not Result
				loop
					if l_printer.begin_page then
						create l_surface.make_for_printer_dc (l_printer.dc)
						create l_ctx.make (l_surface)
						l_p := new_painter (l_ctx)
							-- the DC's origin is the printable area's corner, not the sheet's
						draw_page (l_p, i, - l_printer.unprintable_left, - l_printer.unprintable_top, l_dots)
						l_ctx.show_page
						l_ctx.destroy
						l_surface.destroy
						Result := l_printer.end_page
					else
						Result := False
					end
					i := i + 1
				end
				if Result then
					Result := l_printer.end_document
				else
					l_printer.abort_document
				end
			end
		end

feature {NONE} -- Implementation

	written_through_cairo (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Every page through cairo's PDF backend; `last_error' says why not.
		local
			l_pdf: detachable CAIRO_PDF_SURFACE
			l_ctx: detachable CAIRO_CONTEXT
			l_p: SW_PAINTER
			i: INTEGER
			l_failed: BOOLEAN
		do
			if l_failed then
					-- a page failed half way: say why, and give the surfaces back
				if attached l_ctx as al_ctx then
					if last_error.is_empty then
						last_error := {STRING_32} "page " + i.out.to_string_32 + {STRING_32} ": " + al_ctx.status_message
					end
					al_ctx.destroy
				end
				if attached l_pdf as al_pdf then
					al_pdf.destroy
				end
			else
				create l_pdf.make (a_path, setup.page_width_points, setup.page_height_points)
				if l_pdf.is_valid then
					create l_ctx.make (l_pdf.as_surface)
					l_p := new_painter (l_ctx)
					from
						i := 1
					until
						i > page_count or not last_error.is_empty
					loop
						draw_page (l_p, i, 0.0, 0.0, 1.0)
						if l_ctx.is_valid then
							l_ctx.show_page
						end
						if not l_ctx.is_valid then
							last_error := {STRING_32} "page " + i.out.to_string_32 + {STRING_32} ": " + l_ctx.status_message
						end
						i := i + 1
					end
					l_ctx.destroy
					l_pdf.destroy
					Result := last_error.is_empty and then file_size (a_path) > 0
				else
					last_error := {STRING_32} "no PDF surface for " + a_path.to_string_32
				end
			end
		rescue
			l_failed := True
			retry
		end

	file_arrives (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Wait, up to `Pdf_wait_seconds', until the file at `a_path' is
			-- there and has stopped growing.
		local
			l_env: EXECUTION_ENVIRONMENT
			l_tries, l_last: INTEGER
		do
			create l_env
			l_last := -1
			from
			until
				Result or l_tries > Pdf_wait_seconds * 10
			loop
				l_env.sleep (100_000_000)
				Result := file_size (a_path) > 0 and file_size (a_path) = l_last
				l_last := file_size (a_path)
				l_tries := l_tries + 1
			end
		end

	file_size (a_path: READABLE_STRING_GENERAL): INTEGER
			-- 0 when there is no file.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				Result := l_file.count
			end
		end

	delete_file (a_path: READABLE_STRING_GENERAL)
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
		end

	file_title (a_path: READABLE_STRING_GENERAL): STRING_32
			-- The file's name, as the spooler shows the document.
		local
			l_path: PATH
		do
			create l_path.make_from_string (a_path)
			if attached l_path.entry as al_entry then
				Result := al_entry.name
			else
				Result := a_path.to_string_32
			end
		end

	cairo: SIMPLE_CAIRO

	page_tops, page_bottoms: ARRAYED_LIST [REAL_64]

	new_painter (a_ctx: CAIRO_CONTEXT): SW_PAINTER
		do
			create Result.make (a_ctx, theme)
			Result.set_shaping (shaping)
		end

invariant
	parallel: page_tops.count = page_bottoms.count

end
