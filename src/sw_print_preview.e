note
	description: "[
		GW-20: a print job's sheets as they will print, one under another on
		a grey ground, each as wide as the preview allows, scrolled under a
		bar (SW_VSCROLLING): the wheel, the bar and the paging keys move
		through them. `page_at_top' names the sheet at the top; `show_page'
		brings one there. The sheets are drawn in vector from the job, the
		same drawing the printer and the PDF get.
	]"

class
	SW_PRINT_PREVIEW

inherit
	SW_VSCROLLING
		redefine
			arrange, handle_click, handle_drag, handle_release, handle_wheel, handle_key, accepts_focus
		end

create
	make

feature {NONE} -- Initialization

	make (a_job: SW_PRINT_JOB)
		do
			job := a_job
			grow := 1.0
		ensure
			showing: job = a_job
		end

feature -- Access

	job: SW_PRINT_JOB
			-- The sheets shown.

	sheet_scale: REAL_64
			-- Pixels to a point, as laid out.

	sheet_left: REAL_64
			-- The sheets' left edge, as laid out.

	page_at_top: INTEGER
			-- The sheet at the top of the view.
		local
			i: INTEGER
		do
			Result := 1
			from
				i := 1
			until
				i > job.page_count
			loop
				if sheet_y (i) <= scroll_y + Gap then
					Result := i
				end
				i := i + 1
			end
		ensure
			a_sheet: Result >= 1 and Result <= job.page_count
		end

	sheet_y (a_page: INTEGER): REAL_64
			-- Sheet `a_page''s top within the scrolled content.
		require
			known: a_page >= 1 and a_page <= job.page_count
		do
			Result := Gap + (a_page - 1) * (sheet_height + Gap)
		end

	sheet_height: REAL_64
		do
			Result := job.setup.page_height_points * sheet_scale
		end

feature -- Element change

	set_job (a_job: SW_PRINT_JOB)
			-- Show another job (a new setup re-paginated), from its first sheet.
		do
			job := a_job
			scroll_to (0.0)
		ensure
			showing: job = a_job
		end

	show_page (a_page: INTEGER)
			-- Bring sheet `a_page' to the top.
		require
			known: a_page >= 1 and a_page <= job.page_count
		do
			scroll_to (sheet_y (a_page) - Gap)
		end

feature -- Scrolling

	scroll_extent: REAL_64
		do
			Result := Gap + job.page_count * (sheet_height + Gap)
		end

	wheel_line: REAL_64
		do
			Result := 40.0
		end

feature -- Layout

	arrange (a_p: SW_PAINTER)
		local
			l_room: REAL_64
		do
			place_bar (a_p.theme)
			l_room := (width - bar.bar_width - 2.0 * Gap).max (40.0)
			sheet_scale := l_room / job.setup.page_width_points
			sheet_left := x + Gap
			scroll_to (scroll_y)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 400.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			i: INTEGER
			l_top: REAL_64
		do
			a_p.set_color (a_p.theme.surface_variant)
			a_p.fill_rect (x, y, width, height)
			a_p.push_clip (x, y, width, height)
			from
				i := 1
			until
				i > job.page_count
			loop
				l_top := y + sheet_y (i) - scroll_y
				if l_top < y + height and then l_top + sheet_height > y then
					a_p.set_color (a_p.theme.outline)
					a_p.fill_rect (sheet_left + 3.0, l_top + 3.0, job.setup.page_width_points * sheet_scale, sheet_height)
					job.draw_page (a_p, i, sheet_left, l_top, sheet_scale)
				end
				i := i + 1
			end
			a_p.pop_clip
			draw_bar (a_p)
		end

feature -- Input

	accepts_focus: BOOLEAN = True

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			Result := press_bar (a_px, a_py) or else True
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			drag_bar (a_py).do_nothing
		end

	handle_release (a_x, a_y: INTEGER)
		do
			release_bar
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			wheel_scrolled (a_delta)
			Result := True
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		do
			scroll_key (a_vk).do_nothing
		end

feature {NONE} -- Constants

	Gap: REAL_64 = 16.0
			-- Between sheets, and round them.

end
