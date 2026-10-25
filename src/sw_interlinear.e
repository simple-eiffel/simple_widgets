note
	description: "[
		An interlinear (GW-07): stacked word cells that flow and wrap -
		right to left for Hebrew, left to right for Greek - each cell the
		word's lines one above another: the surface word, transliteration,
		pronunciation, gloss, lemma, Strong's number and morphology in
		English. Any line can be hidden. simple_bible's Interlinear tab
		(C04) is built on it; the Verse Analysis grid sits below it.

		Example cell, Genesis 1:1, word 1:
		    surface        the pointed Hebrew word, set large
		    transliteration bereshit (italic)
		    pronunciation  be-re-SHEET
		    gloss          in the beginning
		    lemma, Strong's, morphology

		WHAT IT IS MADE OF: SW_DOC_UNITS - one parent. Every visible line
		of every word is a unit (its line in `unit_row', its word in
		`unit_column'); every flowed row of cells is a stacked item. So
		the shaping, scrolling, pointing and hover cards are inherited: a
		rest on a word opens the card `set_hover_card_builder' builds
		(map the unit to its word with `unit_column').

		WORDS: `add_token', `set_token_line', `set_verse_label' (the verse
		a word opens, shown small before it). `select_token' and a click
		select a word (`on_token_select'); Left and Right move the
		selection in reading order (mirrored for right to left), Home and
		End go to the first and last word; `token_at' is the hit test.
		Ctrl+C copies the selected word's visible lines.

		SPACING FROM THE THEME: the page inset is `border_width', cells
		are `padding' apart across and down, and a cell is padded half
		the `padding' inside.
	]"
	author: "Larry Rix"

class
	SW_INTERLINEAR

inherit
	SW_DOC_UNITS
		redefine
			arrange, handle_click, handle_double_click, handle_key, handle_char, cursor_kind,
			stack_reset
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
			-- No words, every line shown, left to right, `a_viewport_height'
			-- tall.
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			create tokens.make (64)
			create line_shown.make_filled (True, 1, {SW_INTERLINEAR_TOKEN}.Line_count)
			create row_heights.make (16)
			create token_rows.make (64)
			create token_lefts.make (64)
			create token_widths.make (64)
			create laid_key.make_empty
			surface_scale := 1.5
			init_pointing
		ensure
			kept: viewport_height = a_viewport_height
			empty: token_count = 0
			left_to_right: not is_right_to_left
		end

feature -- Words

	token_count: INTEGER
		do
			Result := tokens.count
		end

	token_line (a_token, a_line: INTEGER): DOC_TEXT
			-- Line `a_line' of word `a_token' ({SW_INTERLINEAR_TOKEN}.Line_*).
		require
			valid_token: a_token >= 1 and a_token <= token_count
			valid_line: a_line >= 1 and a_line <= {SW_INTERLINEAR_TOKEN}.Line_count
		do
			Result := tokens.i_th (a_token).line (a_line)
		end

	verse_label (a_token: INTEGER): STRING_32
		require
			valid_token: a_token >= 1 and a_token <= token_count
		do
			Result := tokens.i_th (a_token).verse_label
		end

	add_token (a_surface: READABLE_STRING_GENERAL): INTEGER
			-- A word reading `a_surface'; its number.
		do
			tokens.extend (create {SW_INTERLINEAR_TOKEN}.make (a_surface))
			structure_revision := structure_revision + 1
			Result := token_count
		ensure
			one_more: token_count = old token_count + 1
		end

	set_token_line (a_token, a_line: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			valid_token: a_token >= 1 and a_token <= token_count
			valid_line: a_line >= 1 and a_line <= {SW_INTERLINEAR_TOKEN}.Line_count
		do
			tokens.i_th (a_token).set_line (a_line, a_text)
		ensure
			set: token_line (a_token, a_line).text.same_string_general (a_text)
		end

	set_verse_label (a_token: INTEGER; a_label: READABLE_STRING_GENERAL)
			-- Word `a_token' opens verse `a_label' (empty: it opens none).
		require
			valid_token: a_token >= 1 and a_token <= token_count
		do
			tokens.i_th (a_token).set_verse_label (a_label)
		end

	wipe_out
			-- No words.
		do
			tokens.wipe_out
			structure_revision := structure_revision + 1
			selected_token := 0
			scroll_y := 0.0
			clear_selection
			forget_hover
		ensure
			empty: token_count = 0 and selected_token = 0
		end

feature -- Lines and direction

	is_line_visible (a_line: INTEGER): BOOLEAN
		require
			valid_line: a_line >= 1 and a_line <= {SW_INTERLINEAR_TOKEN}.Line_count
		do
			Result := line_shown [a_line]
		end

	set_line_visible (a_line: INTEGER; a_on: BOOLEAN)
			-- Show or hide line `a_line' in every cell (the surface word
			-- always shows).
		require
			valid_line: a_line >= 1 and a_line <= {SW_INTERLINEAR_TOKEN}.Line_count
			surface_stays: a_line = {SW_INTERLINEAR_TOKEN}.Line_surface implies a_on
		do
			line_shown [a_line] := a_on
			structure_revision := structure_revision + 1
		ensure
			set: is_line_visible (a_line) = a_on
		end

	is_right_to_left: BOOLEAN
			-- Do the cells flow from the right (Hebrew)?

	set_right_to_left (a_on: BOOLEAN)
		do
			is_right_to_left := a_on
			structure_revision := structure_revision + 1
		ensure
			set: is_right_to_left = a_on
		end

	surface_scale: REAL_64
			-- The surface word's size, of the body size (1.5 by default).

	set_surface_scale (a_scale: REAL_64)
		require
			sensible: a_scale >= 0.8 and a_scale <= 3.0
		do
			surface_scale := a_scale
			structure_revision := structure_revision + 1
		ensure
			set: surface_scale = a_scale
		end

feature -- Selection of words

	selected_token: INTEGER
			-- The selected word; 0 for none.

	on_token_select: detachable PROCEDURE [INTEGER]
			-- A word was selected (click or key): its number.

	set_on_token_select (a_action: detachable PROCEDURE [INTEGER])
		do
			on_token_select := a_action
		ensure
			set: on_token_select = a_action
		end

	select_token (a_token: INTEGER)
			-- Select word `a_token' (0: none), bring it into view, tell the
			-- host.
		require
			valid: a_token >= 0 and a_token <= token_count
		do
			selected_token := a_token
			if a_token > 0 then
				scroll_to_token (a_token)
				if attached on_token_select as al_s then
					al_s.call (a_token)
				end
			end
		ensure
			selected: selected_token = a_token
		end

	token_at (a_px, a_py: REAL_64): INTEGER
			-- The word whose cell holds the point; 0 for none.
		local
			u: INTEGER
		do
			u := pointed_unit (a_px, a_py)
			if u > 0 then
				Result := unit_column (u)
			end
		ensure
			in_range: Result >= 0 and Result <= token_count
		end

	scroll_to_token (a_token: INTEGER)
			-- Bring word `a_token''s row into view, once laid out.
		require
			valid: a_token >= 1 and a_token <= token_count
		do
			if is_laid_out and then a_token <= token_rows.count then
				scroll_item_into_view (token_rows.i_th (a_token))
			end
		end

	row_count: INTEGER
			-- Rows the words flowed into at the last layout.
		do
			Result := row_heights.count
		end

	token_row (a_token: INTEGER): INTEGER
			-- The row word `a_token' stands in, as laid out.
		require
			valid: a_token >= 1 and a_token <= token_count
			laid_out: is_laid_out
		do
			Result := token_rows.i_th (a_token)
		end

	token_box (a_token: INTEGER): TUPLE [x, y, width, height: REAL_64]
			-- Word `a_token''s cell, in window coordinates.
		require
			valid: a_token >= 1 and a_token <= token_count
			laid_out: is_laid_out
		do
			Result := [units_left + token_lefts.i_th (a_token), stacked_top (token_rows.i_th (a_token)),
				token_widths.i_th (a_token), stack.height (token_rows.i_th (a_token))]
		end

feature -- Scrolling (SW_VSCROLLING)

feature -- Layout

	cursor_kind: INTEGER
			-- The arrow: words are picked, not typed.
		do
		end

	arrange (a_p: SW_PAINTER)
		do
			measure (a_p)
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			measure (a_p)
			begin_frame (a_p)
			draw_visible (a_p)
			end_frame (a_p)
			draw_bar (a_p)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- The bar, else the word under the pointer is selected.
		local
			k: INTEGER
		do
			if press_bar (a_px, a_py) then
				Result := True
			else
				clear_selection
				k := token_at (a_px, a_py)
				if k > 0 then
					select_token (k)
				end
				Result := contains (a_px, a_py)
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- The press before it already selected the word.
		do
			Result := token_at (a_px, a_py) > 0
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Left and Right through the words in reading order (mirrored
			-- right to left), Home and End to the first and last word;
			-- PageUp and PageDown scroll; Up and Down a line.
		local
			l_forward: INTEGER
		do
			if token_count > 0 and then (a_vk = 37 or a_vk = 39 or a_vk = 36 or a_vk = 35) then
				l_forward := if a_vk = 39 then 1 elseif a_vk = 37 then -1 else 0 end
				if is_right_to_left then
					l_forward := -l_forward
				end
				if a_vk = 36 then
					select_token (1)
				elseif a_vk = 35 then
					select_token (token_count)
				else
					select_token ((selected_token + l_forward).max (1).min (token_count))
				end
			else
				Precursor {SW_DOC_UNITS} (a_vk, a_shift)
			end
		end

	handle_char (a_code: INTEGER)
			-- Ctrl+C copies the selected text when there is one (Ctrl+A), else
			-- the selected word's visible lines; the rest is SW_DOC_UNITS'.
		local
			l_text: STRING_32
			l: INTEGER
			l_clip: SW_CLIPBOARD
		do
			if a_code = 3 and then has_selection then
				copy_selection
			elseif a_code = 3 and then selected_token > 0 then
				create l_text.make (64)
				from
					l := 1
				until
					l > {SW_INTERLINEAR_TOKEN}.Line_count
				loop
					if line_shown [l] and then not token_line (selected_token, l).text.is_empty then
						if not l_text.is_empty then
							l_text.append_character ('%N')
						end
						l_text.append (token_line (selected_token, l).text)
					end
					l := l + 1
				end
				create l_clip
				l_clip.set_text (l_text)
			else
				Precursor {SW_DOC_UNITS} (a_code)
			end
		end

feature {NONE} -- Model

	tokens: ARRAYED_LIST [SW_INTERLINEAR_TOKEN]

	line_shown: ARRAY [BOOLEAN]

	structure_revision: INTEGER
			-- Grows when words are added, lines shown or hidden, the
			-- direction or the surface size changes.

	lines_revision: INTEGER
			-- Every word's own revision, summed: grows with each line edited
			-- (within one structure; `structure_revision' covers the rest).
		do
			across tokens as t loop
				Result := Result + t.revision
			end
		end

feature {NONE} -- Layout implementation

	laid_key: STRING_8
	laid_lines: INTEGER
			-- `lines_revision' at the last flow.
	flow_width, cell_pad, gap: REAL_64
	row_heights: ARRAYED_LIST [REAL_64]
	token_rows: ARRAYED_LIST [INTEGER]
	token_lefts, token_widths: ARRAYED_LIST [REAL_64]
			-- Per word: its row, and its cell's left and width from
			-- `units_left'.

	measure (a_p: SW_PAINTER)
			-- Flow the words into rows when anything changed, then stack
			-- the rows.
		local
			t: SW_THEME
			l_key: STRING_8
		do
			t := a_p.theme
			margin := t.border_width
			gap := t.padding
			cell_pad := t.padding / 2.0
			place_bar (t)
			flow_width := (width - bar.bar_width - 2.0 * margin).max (64.0)
			laid_px := body_pixel_size (a_p)
			l_key := layout_key (a_p, flow_width)
			if laid_revision /= units_revision or else laid_lines /= lines_revision
				or else not laid_key.same_string (l_key) or else block_units.count /= row_heights.count
			then
				flow (a_p)
				laid_key := l_key
				laid_lines := lines_revision
				stack.invalidate
			end
			measure_stack (a_p, l_key, gap).do_nothing
			place_bar (t)
		ensure
			laid_out: is_laid_out
		end

	flow (a_p: SW_PAINTER)
			-- Lay every word's visible lines out, size its cell, fill rows
			-- greedily (from the right when right to left), and seat each
			-- line centred in its cell.
		local
			t: SW_THEME
			k, l, r: INTEGER
			l_cell_w, l_cell_h, l_x, l_label_w, l_inner, l_left, l_dy, l_box_top, l_box_bottom: REAL_64
			l_cells: ARRAYED_LIST [ARRAYED_LIST [SW_DOC_UNIT]]
			l_widths, l_heights, l_labels: ARRAYED_LIST [REAL_64]
			u: SW_DOC_UNIT
			l_list: ARRAYED_LIST [SW_DOC_UNIT]
		do
			t := a_p.theme
			create l_cells.make (tokens.count)
			create l_widths.make (tokens.count)
			create l_heights.make (tokens.count)
			create l_labels.make (tokens.count)
				-- Each word's lines, laid out on one line each.
			from
				k := 1
			until
				k > tokens.count
			loop
				create l_list.make (4)
				l_cell_w := 0.0
				l_cell_h := 0.0
				from
					l := 1
				until
					l > {SW_INTERLINEAR_TOKEN}.Line_count
				loop
					if line_shown [l] and then (l = {SW_INTERLINEAR_TOKEN}.Line_surface or else not tokens.i_th (k).line (l).text.is_empty) then
						u := line_unit (t, k, l)
						l_cell_h := l_cell_h + lay_unit (a_p, u)
						l_cell_w := l_cell_w.max (u.geometry.natural_width)
						l_list.extend (u)
					end
					l := l + 1
				end
				l_label_w := 0.0
				if not tokens.i_th (k).verse_label.is_empty then
					a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
					l_label_w := a_p.advance (tokens.i_th (k).verse_label) + cell_pad
				end
				l_cells.extend (l_list)
				l_widths.extend (l_cell_w + 2.0 * cell_pad + l_label_w)
				l_heights.extend (l_cell_h + 2.0 * cell_pad)
				l_labels.extend (l_label_w)
				k := k + 1
			end
				-- Rows, greedily.
			row_heights.wipe_out
			token_rows.wipe_out
			token_lefts.wipe_out
			token_widths.wipe_out
			block_units.wipe_out
			r := 0
			l_x := flow_width + 1.0
			from
				k := 1
			until
				k > tokens.count
			loop
				if r = 0 or else (l_x > 0.0 and then l_x + l_widths.i_th (k) > flow_width) then
					r := r + 1
					row_heights.extend (0.0)
					block_units.extend (create {ARRAYED_LIST [SW_DOC_UNIT]}.make (8))
					l_x := 0.0
				end
				if is_right_to_left then
					l_left := flow_width - l_x - l_widths.i_th (k)
				else
					l_left := l_x
				end
				token_rows.extend (r)
				token_lefts.extend (l_left)
				token_widths.extend (l_widths.i_th (k))
				row_heights.put_i_th (row_heights.i_th (r).max (l_heights.i_th (k)), r)
				l_x := l_x + l_widths.i_th (k) + gap
				k := k + 1
			end
				-- Seat every line: centred in its cell, past the label (on
				-- the reading-start side).
			from
				k := 1
			until
				k > tokens.count
			loop
				r := token_rows.i_th (k)
				l_inner := token_widths.i_th (k) - 2.0 * cell_pad - l_labels.i_th (k)
				l_dy := cell_pad
				across l_cells.i_th (k) as cu loop
					if is_right_to_left then
						l_left := token_lefts.i_th (k) + cell_pad + (l_inner - cu.geometry.natural_width) / 2.0
					else
						l_left := token_lefts.i_th (k) + cell_pad + l_labels.i_th (k) + (l_inner - cu.geometry.natural_width) / 2.0
					end
					cu.set_origin (l_left, l_dy, cu.wrap)
						-- Its own band of the cell: the first line from the cell's
						-- top, the last to the row's bottom.
					l_box_top := if @ cu.cursor_index = 1 then 0.0 else l_dy end
					l_dy := l_dy + cu.geometry.content_height.max (1.0)
					l_box_bottom := if @ cu.cursor_index = l_cells.i_th (k).count then row_heights.i_th (r) else l_dy end
					cu.set_box (token_lefts.i_th (k), l_box_top, token_widths.i_th (k), (l_box_bottom - l_box_top).max (1.0))
					cu.set_block (r)
					block_units.i_th (r).extend (cu)
				end
				k := k + 1
			end
			number_units
			flow_count := flow_count + 1
				-- The units are new: no selection or hover names an old one.
			clear_selection
			forget_hover
		ensure
			every_word_placed: token_rows.count = tokens.count
		end

	flow_count: INTEGER
			-- Flows done (what every row's measurement is for).

	line_unit (a_theme: SW_THEME; a_token, a_line: INTEGER): SW_DOC_UNIT
			-- A unit for line `a_line' of word `a_token', in that line's face,
			-- laid on one line.
		local
			l_role: INTEGER
			l_size: REAL_64
		do
			inspect a_line
			when {SW_INTERLINEAR_TOKEN}.Line_surface then
				l_role := {SW_PAINTER}.Role_body
				l_size := a_theme.size_body * surface_scale
			when {SW_INTERLINEAR_TOKEN}.Line_strongs then
				l_role := {SW_PAINTER}.Role_mono
				l_size := a_theme.size_chip
			when {SW_INTERLINEAR_TOKEN}.Line_morphology then
				l_role := {SW_PAINTER}.Role_ui
				l_size := a_theme.size_chip
			when {SW_INTERLINEAR_TOKEN}.Line_transliteration, {SW_INTERLINEAR_TOKEN}.Line_lemma then
				l_role := {SW_PAINTER}.Role_body
				l_size := a_theme.size_label
			else
				l_role := {SW_PAINTER}.Role_ui
				l_size := a_theme.size_label
			end
			create Result.make (1, a_line, a_token, tokens.i_th (a_token).line (a_line), l_role, l_size, False)
			Result.set_alignment ({SHAPING_CONSTANTS}.Align_left)
			Result.set_origin (0.0, 0.0, 100_000.0)
		end

	stack_count: INTEGER
		do
			Result := row_heights.count
		end

	units_revision: INTEGER
			-- The words' structure: grows with every word added or removed,
			-- every line shown or hidden, every turn of direction or size,
			-- and never comes back to an old value (a sum of the words' own
			-- revisions could, after `wipe_out').
		do
			Result := structure_revision
		end

	stack_origin_y: REAL_64
			-- The page inset.
		do
			Result := margin
		end

	item_revision (a_i: INTEGER): INTEGER
			-- Every row measures again after a flow.
		do
			Result := flow_count
		end

	is_volatile (a_i: INTEGER): BOOLEAN
		do
		end

	stack_reset
			-- The flow built the rows' units already, for `units_revision'.
		do
			laid_revision := units_revision
		end

	measure_item (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
		do
			Result := row_heights.i_th (a_i)
		end

	units_left: REAL_64
		do
			Result := x + margin
		end

	unit_ink (a_theme: SW_THEME; a_unit: SW_DOC_UNIT): NATURAL_32
			-- The surface word and its gloss in the ink, the rest muted.
		do
			if a_unit.row = {SW_INTERLINEAR_TOKEN}.Line_surface or a_unit.row = {SW_INTERLINEAR_TOKEN}.Line_gloss then
				Result := a_theme.ink
			else
				Result := a_theme.ink_muted
			end
		end

feature {NONE} -- Drawing implementation

	draw_stacked_item (a_p: SW_PAINTER; a_i: INTEGER)
			-- Row `a_i': each word's selection wash, verse label and lines.
		local
			t: SW_THEME
			k, u, l_last_token: INTEGER
			l_top, l_lx: REAL_64
			l_unit: SW_DOC_UNIT
		do
			t := a_p.theme
			l_top := stacked_top (a_i)
			from
				k := 1
			until
				k > block_units.i_th (a_i).count
			loop
				u := block_first_unit.i_th (a_i) + k - 1
				l_unit := units.i_th (u)
				if l_unit.column /= l_last_token then
					l_last_token := l_unit.column
					if l_last_token = selected_token then
						a_p.set_color (t.wash_accent)
						a_p.rrect_fill (units_left + token_lefts.i_th (l_last_token), l_top,
							token_widths.i_th (l_last_token), stack.height (a_i), t.radius)
						a_p.set_color (t.accent)
						a_p.rrect_stroke (units_left + token_lefts.i_th (l_last_token) + 0.5, l_top + 0.5,
							token_widths.i_th (l_last_token) - 1.0, stack.height (a_i) - 1.0, t.radius)
					end
					if not tokens.i_th (l_last_token).verse_label.is_empty then
						a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
						a_p.set_color (t.ink_accent)
						if is_right_to_left then
							l_lx := units_left + l_unit.box_x + l_unit.box_w - cell_pad - a_p.advance (tokens.i_th (l_last_token).verse_label)
						else
							l_lx := units_left + l_unit.box_x + cell_pad
						end
						a_p.text (l_lx, l_top + cell_pad + a_p.font_ascent, tokens.i_th (l_last_token).verse_label)
					end
				end
				paint_unit_selection (a_p, u, unit_origin_x (u), unit_origin_y (u))
				draw_unit_text (a_p, u, unit_origin_x (u), unit_origin_y (u))
				k := k + 1
			end
		end

invariant
	viewport_positive: viewport_height > 0.0
	selection_in_range: selected_token >= 0 and selected_token <= token_count

end
