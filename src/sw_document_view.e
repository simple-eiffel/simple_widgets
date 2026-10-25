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
	SW_TEXT_POINTING
		redefine
			item_text_count,
			arrange, handle_wheel, handle_click, handle_double_click, handle_drag,
			handle_release, handle_key, handle_char, accepts_focus, wants_hover_point,
			cursor_kind, set_hover_point, set_hovered, sub_widgets, widget_at
		end

	SW_VSCROLLING
		undefine
			dwell_ms, handle_dwell, hover_card_at
		redefine
			arrange, handle_wheel, handle_click, handle_double_click, handle_drag,
			handle_release, handle_key, handle_char, accepts_focus, wants_hover_point,
			cursor_kind, set_hover_point, set_hovered, sub_widgets, widget_at
		end

	SW_TEXT_SELECTION
		undefine
			dwell_ms, handle_dwell, hover_card_at
		redefine
			arrange, handle_wheel, handle_click, handle_double_click, handle_drag,
			handle_release, handle_key, handle_char, accepts_focus, wants_hover_point,
			cursor_kind, set_hover_point, set_hovered, sub_widgets, widget_at, item_separator
		end

	SW_IN_PLACE_EDITING
		undefine
			dwell_ms, handle_dwell, hover_card_at
		redefine
			arrange, handle_wheel, handle_click, handle_double_click, handle_drag,
			handle_release, handle_key, handle_char, accepts_focus, wants_hover_point,
			cursor_kind, set_hover_point, set_hovered, sub_widgets, widget_at
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
			create stack.make
			create block_units.make (16)
			create units.make (16)
			create block_first_unit.make (16)
			create pressed_link.make_empty
			laid_doc_revision := -1
			laid_px := 14
			init_pointing
		ensure
			kept: viewport_height = a_viewport_height
			empty: document.count = 0
		end

feature -- Access

	document: SIMPLE_DOCUMENT
			-- What is shown.

	viewport_height: REAL_64
			-- The height asked of a layout.

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

	is_laid_out: BOOLEAN
			-- Do the measurements stand for the document as it is?
		do
			Result := laid_doc_revision = document.revision and stack.count = document.count
				and block_units.count = document.count
		end

	block_top (a_block: INTEGER): REAL_64
			-- Block `a_block''s top in window coordinates.
		require
			in_range: a_block >= 1 and a_block <= document.count
			laid_out: is_laid_out
		do
			Result := y + margin - scroll_y + stack.top (a_block)
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

	unit_origin_x (a_unit: INTEGER): REAL_64
			-- Where unit `a_unit''s text origin is, in window coordinates.
		require
			valid: is_valid_item (a_unit)
		do
			Result := x + margin + units.i_th (a_unit).dx
		end

	unit_origin_y (a_unit: INTEGER): REAL_64
		require
			valid: is_valid_item (a_unit)
		do
			if is_laid_out then
				Result := block_top (units.i_th (a_unit).block) + units.i_th (a_unit).dy
			end
		end

	first_visible: INTEGER
			-- The first block in the viewport; 0 when empty.
		do
			if is_laid_out then
				Result := stack.first_visible (scroll_y - margin)
			end
		ensure
			in_range: Result >= 0 and Result <= document.count
		end

	last_visible: INTEGER
			-- The last block in the viewport; 0 when empty.
		do
			if is_laid_out then
				Result := stack.last_visible (scroll_y - margin, height)
			end
		ensure
			in_range: Result >= 0 and Result <= document.count
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
			laid_doc_revision := -1
			scroll_y := 0.0
			clear_selection
		ensure
			set: document = a_document
			at_top: scroll_y = 0.0
			nothing_selected: not has_selection
		end

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

	scroll_to_block (a_block: INTEGER)
			-- Bring block `a_block' into view, once laid out.
		require
			in_range: a_block >= 1 and a_block <= document.count
		do
			if is_laid_out and then height > 0.0 then
				scroll_to (stack.scroll_into_view (a_block, (scroll_y - margin).max (0.0), height - 2.0 * margin) + margin)
			end
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

	pointed_item (a_px, a_py: REAL_64): INTEGER
			-- The unit under the point: the block's text, or the table cell
			-- whose box holds it.
		local
			i, k: INTEGER
			cy, cx: REAL_64
			l_list: ARRAYED_LIST [SW_DOC_UNIT]
		do
			if is_laid_out and then contains (a_px, a_py) and then not bar.contains (a_px, a_py) then
				cy := a_py - y - margin + scroll_y
				i := stack.item_at (cy)
				if i > 0 then
					l_list := block_units.i_th (i)
					if document.block (i).kind = {DOC_BLOCK}.Kind_table then
						cx := a_px - x - margin
						cy := cy - stack.top (i)
						from
							k := 1
						until
							k > l_list.count or Result > 0
						loop
							if cx >= l_list.i_th (k).box_x and cx < l_list.i_th (k).box_x + l_list.i_th (k).box_w
								and cy >= l_list.i_th (k).box_y and cy < l_list.i_th (k).box_y + l_list.i_th (k).box_h
							then
								Result := block_first_unit.i_th (i) + k - 1
							end
							k := k + 1
						end
					elseif not l_list.is_empty then
						Result := block_first_unit.i_th (i)
					end
				end
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

feature -- Scrolling (SW_VSCROLLING)

	scroll_extent: REAL_64
			-- The stacked blocks and the page inset above and below.
		do
			Result := stack.content_height + 2.0 * margin
		end

	wheel_line: REAL_64
			-- A line of body text.
		do
			Result := (laid_px * 1.5).max (1.0)
		end

feature -- Layout

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	cursor_kind: INTEGER
			-- A hand over a link, an I-beam over text, else the arrow.
		do
			if bar.contains (hover_px, hover_py) then
				Result := 0
			elseif editor_has (hover_px, hover_py) then
				Result := 1
			elseif hovered_link_span > 0 then
				Result := 2
			elseif hover_character > 0 then
				Result := 1
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := viewport_height
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
			create Result.make (1)
			if attached editor as al_ed then
				Result.extend (al_ed)
			end
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- The box where it stands, else the view.
		do
			if contains (a_px, a_py) then
				if attached editor as al_ed and then not bar.contains (a_px, a_py) and then al_ed.contains (a_px, a_py) then
					Result := al_ed
				else
					Result := Current
				end
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- The page, the visible blocks, the bar.
		local
			t: SW_THEME
			i, l_last: INTEGER
		do
			t := a_p.theme
			measure (a_p)
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			l_last := last_visible
			from
				i := first_visible
			until
				i = 0 or i > l_last
			loop
				if i = editing_index and then attached editor as al_ed then
					al_ed.draw (a_p)
				else
					draw_block (a_p, i)
				end
				i := i + 1
			end
			a_p.pop_clip
			draw_bar (a_p)
		end

feature -- Input

	handle_wheel (a_delta: INTEGER): BOOLEAN
			-- Scroll; the text moved under the pointer.
		do
			wheel_scrolled (a_delta)
			if is_hovered then
				follow_hover
				update_link_hover
			end
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- The bar first; then a press on text starts a selection (and
			-- remembers a link under it); a press elsewhere clears it.
		local
			u: INTEGER
		do
			create pressed_link.make_empty
			if press_bar (a_px, a_py) then
				Result := True
			elseif is_editable then
				Result := editable_click (a_px, a_py)
			else
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
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
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

	handle_drag (a_px, a_py: REAL_64)
			-- The thumb follows, or the selection grows to the text under
			-- the pointer.
		local
			u: INTEGER
		do
			if not drag_bar (a_py) and then is_selecting then
				u := pointed_item (a_px, a_py)
				if u > 0 then
					extend_selection (u, offset_at_point (u, a_px, a_py))
				end
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go of the thumb or end the selection; a click on a link
			-- (pressed and released on it, nothing selected) follows it.
		local
			l_target: STRING_32
		do
			release_bar
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
		ensure then
			released: not bar.is_dragging and not is_selecting
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
			elseif not scroll_key (a_vk) then
				inspect a_vk
				when 40 then
					scroll_to (scroll_y + wheel_line)
				when 38 then
					scroll_to (scroll_y - wheel_line)
				else
				end
			end
		end

	handle_char (a_code: INTEGER)
			-- Ctrl+C copies, Ctrl+A selects all, Escape clears.
		do
			if not editor_char (a_code) then
				selection_char (a_code).do_nothing
			end
		end

	set_hover_point (a_px, a_py: REAL_64)
			-- Follow the pointer to the character - and the link - under it.
		do
			Precursor {SW_TEXT_POINTING} (a_px, a_py)
			update_link_hover
		end

	set_hovered (a_hovered: BOOLEAN)
			-- Leaving the view leaves every link.
		do
			Precursor {SW_TEXT_POINTING} (a_hovered)
			update_link_hover
		end

feature {NONE} -- Layout implementation

	edited (a_item: INTEGER; a_text: STRING_32)
			-- The box typed. The block it covers is measured again at every
			-- layout while edited, so there is nothing to do here.
		do
		end

	stack: SW_BLOCK_STACK
			-- Where the blocks stand.

	block_units: ARRAYED_LIST [ARRAYED_LIST [SW_DOC_UNIT]]
			-- Per block, its texts.

	units: ARRAYED_LIST [SW_DOC_UNIT]
			-- Every text in reading order.

	block_first_unit: ARRAYED_LIST [INTEGER]
			-- Per block, the number of its first unit (one past the units
			-- before it, when it has none).

	laid_doc_revision: INTEGER
			-- The document revision `block_units' were made for.

	margin: REAL_64
			-- The page inset at the last layout.

	text_w: REAL_64
			-- The width a block's text may run.

	laid_px: INTEGER
			-- Body text pixel size at the last layout.

	hovered_link_unit, hovered_link_span: INTEGER
			-- The link under the pointer: its unit and its span (0, 0).

	pressed_link: STRING_32
			-- The target of the link the last press landed on.

	doc_styles: SW_DOC_STYLES
			-- How a DOC_TEXT is set by the shaper.
		once
			create Result
		end

	Quote_bar: REAL_64 = 3.0
			-- A quote bar's width at 1x.

	measure (a_p: SW_PAINTER)
			-- Measure what changed, restack, number the units, seat the bar.
		local
			t: SW_THEME
			i, l_revision: INTEGER
			l_key: STRING_8
			l_reset, l_changed: BOOLEAN
		do
			t := a_p.theme
			margin := t.border_width
			place_bar (t)
			text_w := (width - bar.bar_width - 2.0 * margin).max (32.0)
			laid_px := (t.size_body * t.text_scale).rounded.max (1)
			l_key := text_w.truncated_to_integer.out + "|" + laid_px.out + "|" + a_p.has_shaping.out
			l_reset := stack.reset_if_changed (document.count, l_key)
			if l_reset or else laid_doc_revision /= document.revision or else block_units.count /= document.count then
				block_units.wipe_out
				from
					i := 1
				until
					i > document.count
				loop
					block_units.extend (create {ARRAYED_LIST [SW_DOC_UNIT]}.make (1))
					if not l_reset then
						stack.forget (i)
					end
					i := i + 1
				end
				laid_doc_revision := document.revision
				clear_selection
				l_changed := True
			end
			from
				i := 1
			until
				i > document.count
			loop
				l_revision := document.block (i).revision
				if stack.needs_measure (i, l_revision) or i = editing_index then
					stack.put_height (i, measure_block (a_p, i).max (1.0), l_revision)
					l_changed := True
				end
				i := i + 1
			end
			stack.restack (t.padding)
			if l_changed then
				number_units
			end
			place_bar (t)
		ensure
			laid_out: is_laid_out
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
					l_widths [c] := l_widths [c].max (natural_width (u.geometry) + 2.0 * l_pad_x + 1.0)
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

	natural_width (a_geometry: SW_TEXT_GEOMETRY): REAL_64
			-- The width of a text laid out on one line: its characters'
			-- advances, whatever the line's placement.
		local
			k: INTEGER
		do
			from
				k := 1
			until
				k > a_geometry.count
			loop
				if not a_geometry.is_break (k) then
					Result := Result + a_geometry.width_of (k)
				end
				k := k + 1
			end
		ensure
			non_negative: Result >= 0.0
		end

	lay_unit (a_p: SW_PAINTER; a_unit: SW_DOC_UNIT): REAL_64
			-- Lay `a_unit' out at its wrap, in its face, with its spans on
			-- the shaped path; its height.
		local
			g: SW_TEXT_GEOMETRY
			px: INTEGER
		do
			g := a_unit.geometry
			px := (a_unit.size * a_p.theme.text_scale).rounded.max (1)
			if a_p.has_shaping and then attached a_p.shaping as al_kit then
				g.set_alignment ({SHAPING_CONSTANTS}.Align_start, a_unit.wrap)
				g.set_fonts (al_kit.fonts_for_role (a_unit.role, px, a_unit.is_bold))
				if a_unit.content.span_count > 0 then
					g.set_styles (doc_styles.styles_of (a_unit.content))
				else
					g.set_styles (Void)
				end
				g.build_shaped (al_kit, a_unit.content.text, a_unit.wrap.floor.max (16), px, False)
				Result := g.content_height.max (al_kit.line_height (px))
			else
				a_p.font (a_unit.role, a_unit.size, a_unit.is_bold)
				g.build_toy (a_p, a_unit.content.text, a_unit.wrap, False, False)
				Result := g.content_height.max (a_p.text_extent)
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
			l_sel: TUPLE [lo, hi: INTEGER]
			m: STRING_32
		do
			t := a_p.theme
			l_unit := units.i_th (a_unit)
			g := l_unit.geometry
			ox := unit_origin_x (a_unit)
			oy := unit_origin_y (a_unit)
			if g.count = l_unit.content.count then
				l_sel := selection_in (a_unit)
				if l_sel.lo < l_sel.hi then
					a_p.set_color (t.selection)
					across g.segments (l_sel.lo, l_sel.hi) as sg loop
						a_p.fill_rect (ox + sg.left, oy + g.top_of_line (sg.line), sg.width, g.height_of_line (sg.line))
					end
				end
			end
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
			a_p.set_color (unit_ink (t, l_unit))
			if g.is_shaped and then a_p.has_shaping then
				g.draw_hooked (a_p, ox, oy, agent paint_run (a_p, a_unit, ?, ?, ?, ?))
			elseif g.count = l_unit.content.count then
				g.draw (a_p, l_unit.content.text, False, ox, oy)
			end
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

invariant
	viewport_positive: viewport_height > 0.0
	link_whole: (hovered_link_unit = 0) = (hovered_link_span = 0)
	first_units_per_block: block_first_unit.count <= block_units.count

end
