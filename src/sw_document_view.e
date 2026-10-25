note
	description: "[
		A rich document, read (GW-13): an SIMPLE_DOCUMENT's headings,
		paragraphs, bulleted and numbered items, block quotes, rules and
		tables, in a scrolling column - a commentary on the active verse,
		a lexicon entry, a dictionary article, a note.

		WHAT IT IS MADE OF. Four abilities, inherited:

		    SW_TEXT_POINTING   the character under the pointer, dwell,
		                       hover cards anchored at the word
		    SW_VSCROLLING      the scroll position, the bar, wheel, keys
		    SW_TEXT_SELECTION  a selection across blocks, Copy, Select All
		    SW_IN_PLACE_EDITING the box a block is edited in

		and three helpers: SW_BLOCK_STACK stacks the blocks (binary
		search, so a long article finds the block under the pointer in a
		few steps), each text is an SW_DOC_UNIT with its SW_TEXT_GEOMETRY,
		and the text is drawn through SW_TEXT_GEOMETRY.draw_hooked so a
		link's runs take the theme's `ink_accent' and an underline.

		UNITS. The selection, the pointing and the hover cards number the
		document's TEXTS 1 .. `unit_count' in reading order: a block's own
		text is one unit, a table cell is one. `unit_block', `unit_row'
		and `unit_column' map a unit back to the document.

		LINKS. A press and release on the same link, with nothing
		selected between, calls `on_link_click' with its target (a verse
		reference, an article key: the host's to follow). `on_link_hover'
		hears the link under the pointer change; the pointer is a hand
		over a link and an I-beam over text.

		LIVE PREVIEW (editing). Given a codec (`set_codec', usually
		SW_MARKDOWN_CODEC) the view edits: a click on a block lays a text
		box over it holding the block's source (its Markdown), and every
		other block stays formatted. A click on another block, or below
		the last, keeps the edit - the source is read back into blocks
		(one, several, or none) - and opens the next; Escape drops it;
		Ctrl+Enter keeps it and starts a new paragraph after it; a
		Ctrl+click on a link follows the link. The document changes only
		when an edit is kept (`on_edit_commit', `on_document_change').
		Without a codec the view only reads.

		SPACING FROM THE THEME (Vision2's model). The page is inset by
		`border_width'; blocks are `padding' apart; a level-1 heading
		takes `border_width' above it and the others `padding'; a list
		item is indented `border_width' x 2 a level, a quote
		`border_width' a level; a table cell is padded by
		`control_inset' across and half the `padding' down. Everything
		doubles at 2x text.

		Hebrew and Greek: every text is laid out with Align_start, so a
		Hebrew paragraph sits flush right and a Hebrew list item carries
		its bullet on the right. The shaped path sets the inline styles;
		the toy path (no shaping kit) sets each text plain in its face.
	]"
	author: "Larry Rix"

class
	SW_DOCUMENT_VIEW

inherit
	SW_DOC_UNITS
		redefine
			arrange, handle_click, handle_key, handle_char, cursor_kind, sub_widgets, widget_at
		end

	SW_IN_PLACE_EDITING
		undefine
			set_hover_point, set_hovered, dwell_ms, handle_dwell, hover_card_at,
			accepts_focus, wants_hover_point, handle_wheel, handle_double_click,
			handle_drag, handle_release
		redefine
			arrange, handle_click, handle_key, handle_char, cursor_kind, sub_widgets, widget_at
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
			-- An empty view `a_viewport_height' tall.
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			create document.make
			laid_revision := -1
			init_pointing
		ensure
			kept: viewport_height = a_viewport_height
			empty: document.count = 0
		end

feature -- Access

	document: SIMPLE_DOCUMENT
			-- What is shown.

	block_top (a_block: INTEGER): REAL_64
			-- Block `a_block''s top in window coordinates.
		require
			in_range: a_block >= 1 and a_block <= document.count
			laid_out: is_laid_out
		do
			Result := stacked_top (a_block)
		end

	block_height (a_block: INTEGER): REAL_64
		require
			in_range: a_block >= 1 and a_block <= document.count
			laid_out: is_laid_out
		do
			Result := stack.height (a_block)
		ensure
			positive: Result > 0.0
		end

	content_pad: REAL_64
			-- The page inset, as of the last layout (theme border_width).
		do
			Result := margin
		end

feature -- Element change

	set_document (a_document: SIMPLE_DOCUMENT)
			-- Show `a_document' from its top (an edit under way is dropped).
		do
			if is_editing then
				close_editor
			end
			document := a_document
			forget_hover
			laid_revision := -1
			scroll_y := 0.0
			clear_selection
		ensure
			set: document = a_document
			at_top: scroll_y = 0.0
			nothing_selected: not has_selection
		end

	scroll_to_block (a_block: INTEGER)
			-- Bring block `a_block' into view, once laid out.
		require
			in_range: a_block >= 1 and a_block <= document.count
		do
			scroll_item_into_view (a_block)
		end

feature -- Editing (live preview)

	codec: detachable SW_DOCUMENT_CODEC
			-- Turns a block into source and back; Void: the view only reads.

	is_editable: BOOLEAN
		do
			Result := codec /= Void
		ensure
			definition: Result = (codec /= Void)
		end

	on_document_change: detachable PROCEDURE
			-- A kept edit changed the document.

	set_codec (a_codec: detachable SW_DOCUMENT_CODEC)
			-- Edit through `a_codec' (Void: read only; an edit under way is
			-- dropped).
		do
			if is_editing then
				end_edit (False)
			end
			codec := a_codec
		ensure
			set: codec = a_codec
			not_editing: not is_editing
		end

	set_on_document_change (a_action: detachable PROCEDURE)
		do
			on_document_change := a_action
		ensure
			set: on_document_change = a_action
		end

	begin_edit (a_block: INTEGER)
			-- Lay the box over block `a_block', holding its source.
		require
			editable: is_editable
			not_editing: not is_editing
			in_range: a_block >= 1 and a_block <= document.count
		do
			if attached codec as al_codec then
				clear_selection
				open_editor (a_block, al_codec.block_source (document, a_block))
			end
		ensure
			editing: is_editing and editing_index = a_block
		end

	keep_item (a_i: INTEGER; a_text: STRING_32)
			-- The edited source replaces the block - with as many blocks as
			-- it reads as.
		do
			if attached codec as al_codec then
				document.replace (a_i, al_codec.blocks_from (a_text))
				if attached on_document_change as al_changed then
					al_changed.call (Void)
				end
			end
		end

	restore_item (a_i: INTEGER)
			-- The document was never touched; the block measures again at
			-- its own height.
		do
			if a_i <= stack.count then
				stack.forget (a_i)
			end
		ensure then
			document_untouched: document.revision = old document.revision
		end

	new_paragraph_after (a_block: INTEGER)
			-- An empty paragraph after block `a_block' (0: at the top),
			-- opened for editing.
		require
			editable: is_editable
			not_editing: not is_editing
			in_range: a_block >= 0 and a_block <= document.count
		do
			document.insert (create {DOC_BLOCK}.make ({DOC_BLOCK}.Kind_paragraph, 1, {STRING_32} ""), a_block + 1)
			if attached on_document_change as al_changed then
				al_changed.call (Void)
			end
			begin_edit (a_block + 1)
		ensure
			one_more: document.count = old document.count + 1
			editing_it: is_editing and editing_index = a_block + 1
		end

feature -- Items (SW_TEXT_POINTING, SW_TEXT_SELECTION)

	units_left: REAL_64
			-- The page's left inset.
		do
			Result := x + margin
		end

feature -- Scrolling (SW_VSCROLLING)

feature -- Layout

	cursor_kind: INTEGER
			-- The I-beam over the box; else SW_DOC_UNITS'.
		do
			if not bar.contains (hover_px, hover_py) and then editor_has (hover_px, hover_py) then
				Result := 1
			else
				Result := Precursor {SW_DOC_UNITS}
			end
		end

	arrange (a_p: SW_PAINTER)
			-- Measure, then seat the box over the block it edits.
		do
			measure (a_p)
			if is_editing and then editing_index <= document.count then
				seat_editor (a_p, x + margin, block_top (editing_index), text_w, stack.height (editing_index))
			end
		end

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			Result := editor_sub_widgets
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- The box where it stands (off the bar), else the view.
		do
			Result := widget_or_editor_at (a_px, a_py, not bar.contains (a_px, a_py))
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- The page, the visible blocks, the bar.
		do
			measure (a_p)
			begin_frame (a_p)
			draw_visible (a_p)
			end_frame (a_p)
			draw_bar (a_p)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- Editable and off the bar: the live preview's press; else
			-- SW_DOC_UNITS' (the bar, or a selection).
		do
			if is_editable and then not bar.contains (a_px, a_py) then
				create pressed_link.make_empty
				Result := editable_click (a_px, a_py)
			else
				Result := Precursor {SW_DOC_UNITS} (a_px, a_py)
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- While editing: Ctrl+Enter keeps the edit and opens a new
			-- paragraph after it, every other key is the box's. Otherwise
			-- PageUp, PageDown, Home, End; Up and Down a line.
		local
			i, l_before: INTEGER
		do
			if is_editing and then a_vk = 13 and then (create {SW_KEYS}).control_down then
				i := editing_index
				l_before := document.count
				end_edit (True)
				new_paragraph_after ((i + document.count - l_before).max (0).min (document.count))
			elseif editor_key (a_vk, a_shift) then
					-- The box's.
			else
				Precursor {SW_DOC_UNITS} (a_vk, a_shift)
			end
		end

	handle_char (a_code: INTEGER)
			-- Ctrl+C copies, Ctrl+A selects all, Escape clears.
		do
			if not editor_char (a_code) then
				Precursor {SW_DOC_UNITS} (a_code)
			end
		end

feature {NONE} -- Layout implementation

	edited (a_item: INTEGER; a_text: STRING_32)
			-- The box typed. The block it covers is measured again at every
			-- layout while edited, so there is nothing to do here.
		do
		end

	text_w: REAL_64
			-- The width a block's text may run.

	Quote_bar: REAL_64 = 3.0
			-- A quote bar's width at 1x.

	measure (a_p: SW_PAINTER)
			-- Measure what changed, restack, number the units, seat the bar.
		local
			t: SW_THEME
		do
			t := a_p.theme
			margin := t.border_width
			place_bar (t)
			text_w := (width - bar.bar_width - 2.0 * margin).max (32.0)
			laid_px := body_pixel_size (a_p)
			measure_units (a_p, layout_key (a_p, text_w), t.padding)
			place_bar (t)
		ensure
			laid_out: is_laid_out
		end

	stack_count: INTEGER
		do
			Result := document.count
		end

	units_revision: INTEGER
			-- The document's.
		do
			Result := document.revision
		end

	stack_origin_y: REAL_64
			-- The page inset.
		do
			Result := margin
		end

	item_revision (a_i: INTEGER): INTEGER
		do
			Result := document.block (a_i).revision
		end

	is_volatile (a_i: INTEGER): BOOLEAN
			-- The block under the box follows its typing.
		do
			Result := a_i = editing_index
		end

	measure_item (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
		do
			Result := measure_block (a_p, a_i)
		end

	draw_stacked_item (a_p: SW_PAINTER; a_i: INTEGER)
			-- The box over the edited block, else the block.
		do
			if a_i = editing_index and then attached editor as al_ed then
				al_ed.draw (a_p)
			else
				draw_block (a_p, a_i)
			end
		end

	measure_block (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
			-- Lay block `a_i''s texts out into its units; its height.
		require
			in_range: a_i >= 1 and a_i <= document.count
		local
			b: DOC_BLOCK
			t: SW_THEME
			u: detachable SW_DOC_UNIT
			l_above, l_indent: REAL_64
		do
			b := document.block (a_i)
			t := a_p.theme
			block_units.i_th (a_i).wipe_out
			if a_i = editing_index and then is_editing then
					-- Under the box: its source's height, no units.
				Result := editor_text_height (a_p, text_w).max (1.0)
			else
			inspect b.kind
			when {DOC_BLOCK}.Kind_heading then
				create u.make (a_i, 0, 0, b.content, {SW_PAINTER}.Role_ui, heading_size (t, b.level), True)
				if a_i > 1 then
					l_above := if b.level = 1 then t.border_width else t.padding end
				end
				u.set_origin (0.0, l_above, text_w)
				Result := l_above + lay_unit (a_p, u)
			when {DOC_BLOCK}.Kind_bullet, {DOC_BLOCK}.Kind_numbered then
				l_indent := b.level * 2.0 * t.border_width
				create u.make (a_i, 0, 0, b.content, {SW_PAINTER}.Role_body, t.size_body, False)
				u.set_origin (l_indent, 0.0, (text_w - l_indent).max (16.0))
				Result := lay_unit (a_p, u)
				mirror_if_right_to_left (u)
			when {DOC_BLOCK}.Kind_quote then
				l_indent := b.level * t.border_width
				create u.make (a_i, 0, 0, b.content, {SW_PAINTER}.Role_body, t.size_body, False)
				u.set_origin (l_indent, 0.0, (text_w - l_indent).max (16.0))
				Result := lay_unit (a_p, u)
				mirror_if_right_to_left (u)
			when {DOC_BLOCK}.Kind_rule then
				Result := t.border_width
			when {DOC_BLOCK}.Kind_code_block then
				create u.make (a_i, 0, 0, b.content, {SW_PAINTER}.Role_mono, t.size_body, False)
				u.set_origin (t.control_inset, t.padding / 2.0, (text_w - 2.0 * t.control_inset).max (16.0))
				Result := lay_unit (a_p, u) + t.padding
			when {DOC_BLOCK}.Kind_table then
				Result := measure_table (a_p, a_i)
			else
				create u.make (a_i, 0, 0, b.content, {SW_PAINTER}.Role_body, t.size_body, False)
				u.set_origin (0.0, 0.0, text_w)
				Result := lay_unit (a_p, u)
			end
			if attached u as al_u then
				block_units.i_th (a_i).extend (al_u)
			end
			end
		ensure
			non_negative: Result >= 0.0
		end

	mirror_if_right_to_left (a_unit: SW_DOC_UNIT)
			-- A right-to-left item keeps its text box but moves its indent
			-- (the marker or the quote bar) to the right.
		do
			if a_unit.geometry.starts_right_to_left then
				a_unit.set_mirrored (True)
				a_unit.set_origin (0.0, a_unit.dy, a_unit.wrap)
			end
		end

	measure_table (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
			-- Lay table block `a_i''s cells out: each column as wide as its
			-- widest cell on one line, shrunk in proportion when the table
			-- would overrun the page; each row as tall as its tallest cell.
		require
			table: document.block (a_i).kind = {DOC_BLOCK}.Kind_table
		local
			b: DOC_BLOCK
			t: SW_THEME
			r, c: INTEGER
			l_pad_x, l_pad_y, l_total, l_cx, l_cy: REAL_64
			l_widths, l_heights: ARRAY [REAL_64]
			u: SW_DOC_UNIT
			l_list: ARRAYED_LIST [SW_DOC_UNIT]
		do
			b := document.block (a_i)
			t := a_p.theme
			l_list := block_units.i_th (a_i)
			l_pad_x := t.control_inset
			l_pad_y := t.padding / 2.0
			create l_widths.make_filled (2.0 * l_pad_x + 1.0, 1, b.column_count)
			create l_heights.make_filled (0.0, 1, b.row_count)
			from
				r := 1
			until
				r > b.row_count
			loop
				from
					c := 1
				until
					c > b.column_count
				loop
					create u.make (a_i, r, c, b.cell (r, c), {SW_PAINTER}.Role_body, t.size_body,
						r = 1 and b.has_header)
					u.set_origin (0.0, 0.0, 1_000_000.0)
					lay_unit (a_p, u).do_nothing
					l_widths [c] := l_widths [c].max (u.geometry.natural_width + 2.0 * l_pad_x + 1.0)
					l_list.extend (u)
					c := c + 1
				end
				r := r + 1
			end
			across l_widths as w loop
				l_total := l_total + w
			end
			if l_total > text_w then
				from
					c := 1
				until
					c > b.column_count
				loop
					l_widths [c] := (text_w * l_widths [c] / l_total).max (2.0 * l_pad_x + 16.0)
					c := c + 1
				end
			end
			across l_list as cell loop
				cell.set_origin (0.0, 0.0, (l_widths [cell.column] - 2.0 * l_pad_x).max (16.0))
				l_heights [cell.row] := l_heights [cell.row].max (lay_unit (a_p, cell) + 2.0 * l_pad_y)
			end
			across l_list as cell loop
				l_cx := 0.0
				from
					c := 1
				until
					c >= cell.column
				loop
					l_cx := l_cx + l_widths [c]
					c := c + 1
				end
				l_cy := 0.0
				from
					r := 1
				until
					r >= cell.row
				loop
					l_cy := l_cy + l_heights [r]
					r := r + 1
				end
				cell.set_origin (l_cx + l_pad_x, l_cy + l_pad_y, cell.wrap)
				cell.set_box (l_cx, l_cy, l_widths [cell.column], l_heights [cell.row])
			end
			across l_heights as h loop
				Result := Result + h
			end
		ensure
			non_negative: Result >= 0.0
		end

	heading_size (a_theme: SW_THEME; a_level: INTEGER): REAL_64
			-- A heading's nominal size: 1.6, 1.3 or 1.12 times the body.
		do
			inspect a_level
			when 1 then
				Result := a_theme.size_body * 1.6
			when 2 then
				Result := a_theme.size_body * 1.3
			else
				Result := a_theme.size_body * 1.12
			end
		ensure
			larger_than_body: Result > a_theme.size_body
		end

feature {NONE} -- Drawing implementation

	draw_block (a_p: SW_PAINTER; a_i: INTEGER)
			-- Block `a_i': its rule, quote bars or table frame, then each
			-- unit's selection, marker and text.
		require
			in_range: a_i >= 1 and a_i <= document.count
		local
			b: DOC_BLOCK
			t: SW_THEME
			l_top, l_left, s, l_mid: REAL_64
			k, u: INTEGER
		do
			b := document.block (a_i)
			t := a_p.theme
			s := t.text_scale
			l_top := block_top (a_i)
			l_left := x + margin
			inspect b.kind
			when {DOC_BLOCK}.Kind_rule then
				l_mid := (l_top + stack.height (a_i) / 2.0).floor + 0.5
				a_p.set_color (t.divider)
				a_p.line (l_left, l_mid, l_left + text_w, l_mid, s)
			when {DOC_BLOCK}.Kind_quote then
				a_p.set_color (t.accent)
				from
					k := 1
				until
					k > b.level
				loop
					if not block_units.i_th (a_i).is_empty and then block_units.i_th (a_i).first.is_mirrored then
						a_p.fill_rect (l_left + text_w - k * t.border_width + t.border_width - Quote_bar * s,
							l_top, Quote_bar * s, stack.height (a_i))
					else
						a_p.fill_rect (l_left + (k - 1) * t.border_width, l_top, Quote_bar * s, stack.height (a_i))
					end
					k := k + 1
				end
			when {DOC_BLOCK}.Kind_table then
				draw_table_frame (a_p, a_i, l_left, l_top)
			when {DOC_BLOCK}.Kind_code_block then
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (l_left, l_top, text_w, stack.height (a_i), t.radius)
			else
			end
			from
				k := 1
			until
				k > block_units.i_th (a_i).count
			loop
				u := block_first_unit.i_th (a_i) + k - 1
				draw_unit (a_p, u, b)
				k := k + 1
			end
		end

	draw_table_frame (a_p: SW_PAINTER; a_i: INTEGER; a_left, a_top: REAL_64)
			-- The header row's wash, each cell's rule, the outline.
		local
			t: SW_THEME
			l_w, l_h: REAL_64
		do
			t := a_p.theme
			across block_units.i_th (a_i) as cell loop
				if cell.row = 1 and document.block (a_i).has_header then
					a_p.set_color (t.surface_variant)
					a_p.fill_rect (a_left + cell.box_x, a_top + cell.box_y, cell.box_w, cell.box_h)
				end
				l_w := l_w.max (cell.box_x + cell.box_w)
				l_h := l_h.max (cell.box_y + cell.box_h)
			end
			a_p.set_color (t.divider)
			across block_units.i_th (a_i) as cell loop
				a_p.stroke_rect ((a_left + cell.box_x).floor + 0.5, (a_top + cell.box_y).floor + 0.5,
					cell.box_w, cell.box_h)
			end
			a_p.set_color (t.outline)
			a_p.stroke_rect (a_left.floor + 0.5, a_top.floor + 0.5, l_w, l_h)
		end

	draw_unit (a_p: SW_PAINTER; a_unit: INTEGER; a_block: DOC_BLOCK)
			-- Unit `a_unit''s selection wash, list marker and text.
		local
			t: SW_THEME
			l_unit: SW_DOC_UNIT
			g: SW_TEXT_GEOMETRY
			ox, oy, mx: REAL_64
			m: STRING_32
		do
			t := a_p.theme
			l_unit := units.i_th (a_unit)
			g := l_unit.geometry
			ox := unit_origin_x (a_unit)
			oy := unit_origin_y (a_unit)
			paint_unit_selection (a_p, a_unit, ox, oy)
			if a_block.is_list_item and then not l_unit.is_cell then
				if a_block.kind = {DOC_BLOCK}.Kind_bullet then
					create m.make_empty
					m.append_code (0x2022)
				else
					create m.make (4)
					m.append_integer (document.number_of (l_unit.block))
					m.append_character ('.')
				end
				a_p.font ({SW_PAINTER}.Role_body, t.size_body, False)
				a_p.set_color (t.ink_muted)
				if l_unit.is_mirrored then
					mx := ox + l_unit.wrap + t.padding / 2.0
				else
					mx := ox - t.padding / 2.0 - a_p.advance (m)
				end
				a_p.text (mx, oy + g.ascent_of_line (0), m)
			end
			draw_unit_text (a_p, a_unit, ox, oy)
		end

	unit_ink (a_theme: SW_THEME; a_unit: SW_DOC_UNIT): NATURAL_32
			-- The colour of a unit's plain text: muted in a quote.
		do
			if document.block (a_unit.block).kind = {DOC_BLOCK}.Kind_quote then
				Result := a_theme.ink_muted
			else
				Result := a_theme.ink
			end
		end

feature {NONE} -- Input implementation

	editable_click (a_px, a_py: REAL_64): BOOLEAN
			-- A press while editable: Ctrl on a link follows it; on a block,
			-- the edit under way is kept and that block opens; below the
			-- last block, the last empty paragraph (or a new one) opens.
		require
			editable: is_editable
		local
			l_target: STRING_32
			b, e, l_before: INTEGER
			cy: REAL_64
			l_below: BOOLEAN
		do
			l_target := link_target_at_point (a_px, a_py)
			if (create {SW_KEYS}).control_down and then not l_target.is_empty then
				if is_editing then
					end_edit (True)
				end
				if attached on_link_click as al_click then
					al_click.call (l_target)
				end
				Result := True
			elseif contains (a_px, a_py) then
				Result := True
				if is_laid_out then
					cy := a_py - y - margin + scroll_y
					b := stack.item_at (cy)
					l_below := b = 0 and then cy >= stack.content_height
				end
				if not (is_editing and then b = editing_index and then b > 0) then
					if is_editing then
						e := editing_index
						l_before := document.count
						end_edit (True)
						if b > e then
							b := b + document.count - l_before
						end
					end
					if l_below then
						if document.count > 0 and then document.block (document.count).kind = {DOC_BLOCK}.Kind_paragraph
							and then document.block (document.count).content.count = 0
						then
							begin_edit (document.count)
						else
							new_paragraph_after (document.count)
						end
					elseif b >= 1 and then b <= document.count then
						begin_edit (b)
					end
				end
			end
		end

invariant
	viewport_positive: viewport_height > 0.0

end
