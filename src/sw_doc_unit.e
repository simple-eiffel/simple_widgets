note
	description: "[
		One laid-out text of an SW_DOCUMENT_VIEW (GW-13): a block's own
		text, or one cell of a table. It holds the rich text, the face it
		is set in (role, nominal size, bold), where its text origin sits
		inside its block (`dx', `dy'), its wrap width, its geometry
		(SW_TEXT_GEOMETRY: where each character paints), and for a table
		cell the cell's box.
	]"
	author: "Larry Rix"

class
	SW_DOC_UNIT

create
	make

feature {NONE} -- Initialization

	make (a_block, a_row, a_column: INTEGER; a_content: SW_RICH_TEXT;
			a_role: INTEGER; a_size: REAL_64; a_bold: BOOLEAN)
		require
			block_positive: a_block >= 1
			cell_coordinates: a_row >= 0 and a_column >= 0
			role_known: a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
			size_positive: a_size > 0.0
		do
			block := a_block
			row := a_row
			column := a_column
			content := a_content
			role := a_role
			size := a_size
			is_bold := a_bold
			create geometry.make
			wrap := 16.0
		ensure
			block_set: block = a_block
			content_set: content = a_content
		end

feature -- Access

	block: INTEGER
			-- The document block it belongs to.

	row, column: INTEGER
			-- Its cell in a table; 0, 0 for a block's own text.

	content: SW_RICH_TEXT

	role: INTEGER
			-- SW_PAINTER.Role_ui or Role_body.

	size: REAL_64
			-- Nominal size, before `text_scale'.

	is_bold: BOOLEAN

	geometry: SW_TEXT_GEOMETRY

	dx, dy: REAL_64
			-- The text origin, from the block's content-left and top.

	wrap: REAL_64
			-- The width its lines wrap at.

	box_x, box_y, box_w, box_h: REAL_64
			-- A table cell's box, from the block's content-left and top.

	is_mirrored: BOOLEAN
			-- Does it read right to left, so its marker or quote bar stands
			-- on the right?

	is_cell: BOOLEAN
		do
			Result := row > 0
		end

feature -- Element change

	set_origin (a_dx, a_dy, a_wrap: REAL_64)
		require
			wrap_positive: a_wrap > 0.0
		do
			dx := a_dx
			dy := a_dy
			wrap := a_wrap
		end

	set_box (a_x, a_y, a_w, a_h: REAL_64)
		do
			box_x := a_x
			box_y := a_y
			box_w := a_w
			box_h := a_h
		end

	set_mirrored (a_on: BOOLEAN)
		do
			is_mirrored := a_on
		end

invariant
	wrap_positive: wrap > 0.0
	size_positive: size > 0.0

end
