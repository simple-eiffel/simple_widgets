note
	description: "[
		A widget whose stacked items each hold one or more simple_document
		texts (0.24.0): a document's blocks and table cells
		(SW_DOCUMENT_VIEW), a parallel text's verse cells
		(SW_PARALLEL_TEXT). Every text is an SW_DOC_UNIT - its DOC_TEXT,
		face, origin inside its item, wrap, geometry and, for a cell, its
		box - numbered 1 .. `unit_count' in reading order.

		From that numbering this class gives the item hooks of
		SW_TEXT_POINTING and SW_TEXT_SELECTION, which it inherits (one
		parent for its heirs where there were two): `text_of',
		`item_geometry', `item_origin_x/y', `item_separator' (a tab between
		two cells of one row) and `pointed_unit' (the item's one text, or
		the cell whose box holds the point). It lays a unit out
		(`lay_unit', DOC_TEXT through SW_DOC_STYLES), paints its text with
		the run hook (links in `ink_accent' over an underline, code on a
		wash, struck runs) and its selection, and keeps the link under the
		pointer (`hovered_link', `on_link_hover', `link_target_at').

		It inherits SW_STACKED_POINTING (pointing, scrolling and the
		stack, joined once) and SW_TEXT_SELECTION, so its heirs inherit it
		alone. A descendant fills `block_units' (one list per stacked
		item), calls `number_units', and says where a unit's `dx' counts
		from (`units_left') and what ink a unit's plain text takes
		(`unit_ink'). Lifted from
		SW_DOCUMENT_VIEW so GW-06 is not its second copy.
	]"
	author: "Larry Rix"

deferred class
	SW_DOC_UNITS

inherit
	SW_STACKED_POINTING
		redefine
			item_text_count
		end

	SW_TEXT_SELECTION
		undefine
			set_hover_point, set_hovered, dwell_ms, handle_dwell, hover_card_at
		redefine
			item_separator
		end

feature -- Units

	unit_count: INTEGER
			-- Texts laid out: each text block one, each table cell one.
		do
			Result := units.count
		end

	unit_block (a_unit: INTEGER): INTEGER
			-- The document block unit `a_unit' belongs to.
		require
			valid: is_valid_item (a_unit)
		do
			Result := units.i_th (a_unit).block
		end

	unit_row (a_unit: INTEGER): INTEGER
			-- Its table row; 0 for a block's own text.
		require
			valid: is_valid_item (a_unit)
		do
			Result := units.i_th (a_unit).row
		end

	unit_column (a_unit: INTEGER): INTEGER
			-- Its table column; 0 for a block's own text.
		require
			valid: is_valid_item (a_unit)
		do
			Result := units.i_th (a_unit).column
		end

	unit_geometry (a_unit: INTEGER): SW_TEXT_GEOMETRY
			-- Where unit `a_unit''s characters paint, from its text origin.
		require
			valid: is_valid_item (a_unit)
		do
			Result := units.i_th (a_unit).geometry
		end

	unit_origin_x (a_unit: INTEGER): REAL_64
			-- Where unit `a_unit''s text origin is, in window coordinates.
		require
			valid: is_valid_item (a_unit)
		do
			Result := units_left + units.i_th (a_unit).dx
		end

	unit_origin_y (a_unit: INTEGER): REAL_64
		require
			valid: is_valid_item (a_unit)
		do
			if is_laid_out then
				Result := stacked_top (units.i_th (a_unit).block) + units.i_th (a_unit).dy
			end
		end

feature -- Links

	link_target_at (a_unit, a_character: INTEGER): detachable STRING_32
			-- The target of the link over character `a_character' of unit
			-- `a_unit'; Void for none.
		require
			valid: is_valid_item (a_unit)
		local
			k: INTEGER
		do
			k := units.i_th (a_unit).content.link_at (a_character)
			if k > 0 then
				Result := units.i_th (a_unit).content.span_target (k).twin
			end
		end

	hovered_link: STRING_32
			-- The target of the link under the pointer; empty for none.
		do
			if hovered_link_span > 0 and then hovered_link_unit <= units.count then
				Result := units.i_th (hovered_link_unit).content.span_target (hovered_link_span).twin
			else
				create Result.make_empty
			end
		end

	on_link_click: detachable PROCEDURE [STRING_32]
			-- A link was clicked: its target.

	on_link_hover: detachable PROCEDURE [STRING_32]
			-- The link under the pointer changed: its target, or empty
			-- when the pointer left every link.

	set_on_link_click (a_action: detachable PROCEDURE [STRING_32])
		do
			on_link_click := a_action
		ensure
			set: on_link_click = a_action
		end

	set_on_link_hover (a_action: detachable PROCEDURE [STRING_32])
		do
			on_link_hover := a_action
		ensure
			set: on_link_hover = a_action
		end

feature -- Items (SW_TEXT_POINTING, SW_TEXT_SELECTION)

	item_count: INTEGER
		do
			Result := units.count
		end

	is_valid_item (a_item: INTEGER): BOOLEAN
		do
			Result := a_item >= 1 and a_item <= units.count
		end

	text_of (a_item: INTEGER): STRING_32
		do
			Result := units.i_th (a_item).content.text
		end

	item_separator (a_item: INTEGER): STRING_32
			-- A tab between two cells of one table row, else a line feed.
		do
			if a_item < units.count and then units.i_th (a_item).is_cell
				and then units.i_th (a_item + 1).block = units.i_th (a_item).block
				and then units.i_th (a_item + 1).row = units.i_th (a_item).row
			then
				Result := {STRING_32} "%T"
			else
				Result := {STRING_32} "%N"
			end
		end

	item_geometry (a_item: INTEGER): SW_TEXT_GEOMETRY
			-- Unit `a_item''s geometry (SW_TEXT_POINTING).
		do
			Result := units.i_th (a_item).geometry
		end

	item_origin_x (a_item: INTEGER): REAL_64
		do
			Result := unit_origin_x (a_item)
		end

	item_origin_y (a_item: INTEGER): REAL_64
		do
			Result := unit_origin_y (a_item)
		end

	is_item_pointable (a_item: INTEGER): BOOLEAN
			-- Units exist only for laid-out blocks (the edited block has
			-- none).
		do
			Result := is_laid_out
		end

	item_text_count (a_item: INTEGER): INTEGER
		do
			Result := units.i_th (a_item).content.count
		end

	pointed_unit (a_px, a_py: REAL_64): INTEGER
			-- The unit under the point: its item's one text, or - when the
			-- item's units carry boxes (table cells, parallel columns) -
			-- the unit whose box holds it.
		local
			b, k: INTEGER
			cx, cy: REAL_64
			l_list: ARRAYED_LIST [SW_DOC_UNIT]
		do
			if is_on_content (a_px, a_py) then
				b := stacked_item_at (a_py)
				if b > 0 and then b <= block_units.count and then b <= block_first_unit.count then
					l_list := block_units.i_th (b)
					if l_list.count = 1 and then l_list.first.box_w = 0.0 then
						Result := block_first_unit.i_th (b)
					else
						cx := a_px - units_left
						cy := a_py - stacked_top (b)
						from
							k := 1
						until
							k > l_list.count or Result > 0
						loop
							if cx >= l_list.i_th (k).box_x and cx < l_list.i_th (k).box_x + l_list.i_th (k).box_w
								and cy >= l_list.i_th (k).box_y and cy < l_list.i_th (k).box_y + l_list.i_th (k).box_h
							then
								Result := block_first_unit.i_th (b) + k - 1
							end
							k := k + 1
						end
					end
				end
			end
		ensure
			none_or_valid: Result = 0 or else is_valid_item (Result)
		end

feature {NONE} -- Reading with the pointer

	unit_press (a_px, a_py: REAL_64): BOOLEAN
			-- A press: on text it starts a selection (and remembers a link
			-- under it); elsewhere inside it clears the selection. Taken
			-- when inside.
		local
			u: INTEGER
		do
			create pressed_link.make_empty
			u := pointed_item (a_px, a_py)
			if u > 0 then
				begin_selection (u, offset_at_point (u, a_px, a_py))
				pressed_link := link_target_at_point (a_px, a_py)
				Result := True
			else
				clear_selection
				Result := contains (a_px, a_py)
			end
		end

	unit_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- Select the word under the pointer.
		local
			u, ch: INTEGER
			w: TUPLE [lo, hi: INTEGER]
		do
			ch := character_at (a_px, a_py)
			if ch > 0 then
				u := pointed_item (a_px, a_py)
				w := word_at (u, ch)
				select_range (u, w.lo, u, w.hi)
				Result := True
			end
		end

	unit_drag (a_px, a_py: REAL_64)
			-- The selection grows to the text under the pointer.
		local
			u: INTEGER
		do
			if is_selecting then
				u := pointed_item (a_px, a_py)
				if u > 0 then
					extend_selection (u, offset_at_point (u, a_px, a_py))
				end
			end
		end

	unit_release (a_x, a_y: INTEGER)
			-- End the selection; a click on a link (pressed and released on
			-- it, nothing selected) follows it.
		local
			l_target: STRING_32
		do
			if is_selecting then
				end_selection
				if not has_selection and then not pressed_link.is_empty
					and then link_target_at_point (a_x, a_y).same_string (pressed_link)
				then
					l_target := pressed_link.twin
					clear_selection
					if attached on_link_click as al_click then
						al_click.call (l_target)
					end
				end
			end
			create pressed_link.make_empty
		ensure
			not_selecting: not is_selecting
		end

	unit_cursor_kind: INTEGER
			-- A hand over a link, an I-beam over text, else the arrow.
		do
			if hovered_link_span > 0 then
				Result := 2
			elseif hover_character > 0 then
				Result := 1
			end
		end

feature {NONE} -- Unit hooks

	units_left: REAL_64
			-- Where a unit's `dx' counts from, in window coordinates.
		deferred
		end

	unit_ink (a_theme: SW_THEME; a_unit: SW_DOC_UNIT): NATURAL_32
			-- The colour of `a_unit''s plain text.
		deferred
		end

	is_on_content (a_px, a_py: REAL_64): BOOLEAN
			-- Is the point over the units: inside, off the scrollbar?
		do
			Result := contains (a_px, a_py) and then not bar.contains (a_px, a_py)
		end

feature {NONE} -- Unit implementation

	block_units: ARRAYED_LIST [ARRAYED_LIST [SW_DOC_UNIT]]
			-- Per item, its texts.
		attribute
			create Result.make (16)
		end

	units: ARRAYED_LIST [SW_DOC_UNIT]
			-- Every text in reading order.
		attribute
			create Result.make (16)
		end

	block_first_unit: ARRAYED_LIST [INTEGER]
			-- Per item, the number of its first unit (one past the units
			-- before it, when it has none).
		attribute
			create Result.make (16)
		end

	hovered_link_unit, hovered_link_span: INTEGER
			-- The link under the pointer: its unit and its span (0, 0).

	pressed_link: STRING_32
			-- The target of the link the last press landed on.
		attribute
			create Result.make_empty
		end

	doc_styles: SW_DOC_STYLES
			-- How a DOC_TEXT is set by the shaper.
		once
			create Result
		end

	number_units
			-- `units' and `block_first_unit' from the blocks' lists.
		local
			i: INTEGER
		do
			units.wipe_out
			block_first_unit.wipe_out
			from
				i := 1
			until
				i > block_units.count
			loop
				block_first_unit.extend (units.count + 1)
				across block_units.i_th (i) as u loop
					units.extend (u)
				end
				i := i + 1
			end
			if anchor_item > units.count or caret_item > units.count then
				clear_selection
			end
		end

	lay_unit (a_p: SW_PAINTER; a_unit: SW_DOC_UNIT): REAL_64
			-- Lay `a_unit' out at its wrap, in its face, with its spans on
			-- the shaped path; its height.
		local
			g: SW_TEXT_GEOMETRY
		do
			g := a_unit.geometry
			g.set_alignment (a_unit.alignment, a_unit.wrap)
			if a_unit.content.span_count > 0 then
				g.set_styles (doc_styles.styles_of (a_unit.content))
			else
				g.set_styles (Void)
			end
			Result := g.lay_out (a_p, a_unit.content.text, a_unit.wrap, a_unit.role, a_unit.size, a_unit.is_bold, False, False)
		ensure
			non_negative: Result >= 0.0
		end

	paint_run (a_p: SW_PAINTER; a_unit, a_character: INTEGER; a_run: SHAPED_RUN; a_pen, a_baseline: REAL_64)
			-- Before a run paints: code over a wash, a link's runs in
			-- `ink_accent' over an underline (heavier while the pointer is
			-- on that link), the rest in the unit's ink; a struck run gets
			-- its line through.
		local
			t: SW_THEME
			l_link, l_flags: INTEGER
			s: REAL_64
		do
			t := a_p.theme
			s := t.text_scale
			l_flags := units.i_th (a_unit).content.flags_at (a_character)
			if l_flags & {DOC_TEXT}.Flag_code /= 0 then
				a_p.set_color (t.surface_variant)
				a_p.fill_rect (a_pen, a_baseline - 0.8 * a_run.height, a_run.advance_width, a_run.height)
			end
			l_link := units.i_th (a_unit).content.link_at (a_character)
			if l_link > 0 then
				a_p.set_color (t.ink_accent)
				a_p.line (a_pen, a_baseline + 2.0 * s, a_pen + a_run.advance_width, a_baseline + 2.0 * s,
					if a_unit = hovered_link_unit and l_link = hovered_link_span then 2.0 * s else s end)
			else
				a_p.set_color (unit_ink (t, units.i_th (a_unit)))
			end
			if l_flags & {DOC_TEXT}.Flag_strike /= 0 then
				a_p.line (a_pen, a_baseline - 0.3 * a_run.height, a_pen + a_run.advance_width,
					a_baseline - 0.3 * a_run.height, s)
			end
		end

	link_target_at_point (a_px, a_py: REAL_64): STRING_32
			-- The target of the link under the point; empty for none.
		local
			u, ch: INTEGER
		do
			create Result.make_empty
			ch := character_at (a_px, a_py)
			if ch > 0 then
				u := pointed_item (a_px, a_py)
				if attached link_target_at (u, ch) as al_target then
					Result := al_target
				end
			end
		end

	update_link_hover
			-- The link under `hover_item', `hover_character' becomes the
			-- hovered link; `on_link_hover' hears a change.
		local
			l_unit, l_span: INTEGER
		do
			if hover_item > 0 and then hover_item <= units.count then
				l_span := units.i_th (hover_item).content.link_at (hover_character)
				if l_span > 0 then
					l_unit := hover_item
				end
			end
			if l_unit /= hovered_link_unit or else l_span /= hovered_link_span then
				hovered_link_unit := l_unit
				hovered_link_span := l_span
				if attached on_link_hover as al_h then
					al_h.call (hovered_link)
				end
			end
		ensure
			whole: (hovered_link_unit = 0) = (hovered_link_span = 0)
		end

	paint_unit_selection (a_p: SW_PAINTER; a_unit: INTEGER; a_ox, a_oy: REAL_64)
			-- The selection's wash under unit `a_unit''s selected characters.
		require
			valid: is_valid_item (a_unit)
		local
			g: SW_TEXT_GEOMETRY
			l_sel: TUPLE [lo, hi: INTEGER]
		do
			g := units.i_th (a_unit).geometry
			if g.count = units.i_th (a_unit).content.count then
				l_sel := selection_in (a_unit)
				if l_sel.lo < l_sel.hi then
					a_p.set_color (a_p.theme.selection)
					across g.segments (l_sel.lo, l_sel.hi) as sg loop
						a_p.fill_rect (a_ox + sg.left, a_oy + g.top_of_line (sg.line), sg.width, g.height_of_line (sg.line))
					end
				end
			end
		end

	draw_unit_text (a_p: SW_PAINTER; a_unit: INTEGER; a_ox, a_oy: REAL_64)
			-- Unit `a_unit''s text from (`a_ox', `a_oy'): shaped, each run
			-- through `paint_run'; else plain in its ink.
		require
			valid: is_valid_item (a_unit)
		local
			l_unit: SW_DOC_UNIT
		do
			l_unit := units.i_th (a_unit)
			a_p.set_color (unit_ink (a_p.theme, l_unit))
			if l_unit.geometry.is_shaped and then a_p.has_shaping then
				l_unit.geometry.draw_hooked (a_p, a_ox, a_oy, agent paint_run (a_p, a_unit, ?, ?, ?, ?))
			elseif l_unit.geometry.count = l_unit.content.count then
				l_unit.geometry.draw (a_p, l_unit.content.text, False, a_ox, a_oy)
			end
		end

invariant
	link_whole: (hovered_link_unit = 0) = (hovered_link_span = 0)
	first_units_per_block: block_first_unit.count <= block_units.count

end
