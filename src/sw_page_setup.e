note
	description: "[
		The sheet a print job lays its pages on (GW-20): paper (Letter or
		A4), orientation, margins, a header line and page numbers, and how
		big a screen pixel prints (`points_per_pixel': 0.75 prints at the
		size the screen shows at 96 dots per inch). Lengths on paper are in
		points (72 to the inch); the content area is also given in widget
		pixels, for laying the widget out.
	]"

class
	SW_PAGE_SETUP

create
	make_letter, make_a4

feature {NONE} -- Initialization

	make_letter
			-- US Letter, portrait, three-quarter-inch margins, page numbers.
		do
			paper := {SHELL_PRINTER}.Paper_letter
			paper_width_points := 612.0
			paper_height_points := 792.0
			set_defaults
		ensure
			letter: paper = {SHELL_PRINTER}.Paper_letter
			portrait: not is_landscape
		end

	make_a4
			-- A4, portrait, the same margins.
		do
			paper := {SHELL_PRINTER}.Paper_a4
			paper_width_points := 595.28
			paper_height_points := 841.89
			set_defaults
		ensure
			a4: paper = {SHELL_PRINTER}.Paper_a4
			portrait: not is_landscape
		end

	set_defaults
		do
			margin_points := 54.0
			points_per_pixel := 0.75
			show_page_numbers := True
			create header.make_empty
		end

feature -- Paper

	paper: INTEGER
			-- The printer's paper code (SHELL_PRINTER.Paper_*).

	paper_width_points, paper_height_points: REAL_64
			-- The sheet upright, in points.

	is_landscape: BOOLEAN
			-- Turned on its side?

	page_width_points: REAL_64
			-- Across the sheet as it is turned.
		do
			if is_landscape then
				Result := paper_height_points
			else
				Result := paper_width_points
			end
		end

	page_height_points: REAL_64
		do
			if is_landscape then
				Result := paper_width_points
			else
				Result := paper_height_points
			end
		end

feature -- Layout

	margin_points: REAL_64
			-- The blank edge all round; the header and the page number sit in it.

	points_per_pixel: REAL_64
			-- How big a widget pixel prints.

	content_width_points: REAL_64
		do
			Result := page_width_points - 2.0 * margin_points
		end

	content_height_points: REAL_64
		do
			Result := page_height_points - 2.0 * margin_points
		end

	content_width_pixels: REAL_64
			-- The width the widget is laid out at.
		do
			Result := content_width_points / points_per_pixel
		end

	content_height_pixels: REAL_64
			-- How much of the widget one page holds.
		do
			Result := content_height_points / points_per_pixel
		end

	margin_pixels: REAL_64
		do
			Result := margin_points / points_per_pixel
		end

feature -- Header and footer

	header: STRING_32
			-- A line above the content of every page; empty for none.

	show_page_numbers: BOOLEAN
			-- "Page n of m" below the content?

feature -- Element change

	set_landscape (a_on: BOOLEAN)
		do
			is_landscape := a_on
		ensure
			set: is_landscape = a_on
		end

	set_margin_points (a_points: REAL_64)
		require
			fits: a_points >= 0.0 and a_points * 2.0 < paper_width_points.min (paper_height_points) - 72.0
		do
			margin_points := a_points
		ensure
			set: margin_points = a_points
		end

	set_points_per_pixel (a_scale: REAL_64)
		require
			sane: a_scale >= 0.25 and a_scale <= 2.0
		do
			points_per_pixel := a_scale
		ensure
			set: points_per_pixel = a_scale
		end

	set_header (a_text: READABLE_STRING_GENERAL)
		do
			create header.make_from_string_general (a_text)
		ensure
			set: header.same_string_general (a_text)
		end

	set_show_page_numbers (a_on: BOOLEAN)
		do
			show_page_numbers := a_on
		ensure
			set: show_page_numbers = a_on
		end

invariant
	content_area: content_width_points > 0.0 and content_height_points > 0.0
	scale_positive: points_per_pixel > 0.0

end
