note
	description: "[
		A scrolling column of paragraphs of DIFFERENT heights, each a
		shaped block of text with a host-drawn gutter beside it and
		optional host-drawn bands above and below; a selection that is
		a SET with an anchor; and one paragraph at a time editable IN
		PLACE through a real SW_TEXT_BOX laid over it. The document
		editor's spine: a script, a list of notes, a narration session,
		anything whose unit is "a paragraph the reader can pick, read
		and change".

		WHY NOT SW_LIST. SW_LIST is uniform row height by design, which
		is what makes ten thousand rows arithmetic; a paragraph is as
		tall as its own wrap makes it. So every paragraph is MEASURED
		(cheap: unchanged text comes back from the shaping cache having
		shaped nothing) and its top is the sum of the ones above it.
		Only the paragraphs inside the viewport are ever PAINTED.

		WHY NOT SW_CHAT_THREAD. The thread knows what a message is -
		roles, bubbles, reactions, quotes. This widget knows nothing
		about its paragraphs beyond their text: what stands in the
		gutter, what the bands hold and what colour washes a row are
		the host's, through agents. The Studio puts a severity stripe,
		a voice dot and a fidelity chip there; a notes app puts a date.

		SHAPED OR TOY. When the painter carries a shaping kit, each
		paragraph is laid out through it - one layout per LF-separated
		piece, as SW_CHAT_THREAD does, because simple_shaping treats an
		LF as a break OPPORTUNITY. Without a kit, cairo's advances and
		a greedy word wrap. Either way the height is measured, never
		guessed.

		EDITING IN PLACE. `begin_edit' lays an SW_TEXT_BOX over the
		paragraph so its text origin lands exactly where the paragraph
		was painted: nothing jumps. While it is up, the item's text
		follows every keystroke (so its height reflows live) and the
		host hears `on_edit_change'; Escape cancels and restores;
		`end_edit (True)' - or a click on another paragraph - keeps the
		edit, and the host hears `on_edit_commit' when the text changed
		(an unchanged edit is not a commit: SW_IN_PLACE_EDITING's one
		`end_edit'). The list forwards keys to the editor
		while the list itself holds focus, so typing works the instant
		the edit begins; a click inside the editor moves the window's
		focus onto it and the keys then arrive directly.

		SELECTION. `selected_index' is the anchor - the paragraph the
		keyboard moves from - and `is_selected' is the set. A plain
		click selects only; Ctrl+click toggles; Shift+click ranges from
		the anchor. Assigning one property to six paragraphs is one
		gesture, which is the whole reason the set exists.

		POINTING AND STYLING (GW-08). `character_at' answers which
		character of which paragraph (`item_at') is under a point, so a
		host can name the word the pointer is on; `text_boxes' gives the
		rectangles of a stretch, to anchor a hover card or ring a word.
		`on_hover' hears the character under the pointer change,
		`on_dwell' hears the pointer rest on one for `dwell_delay'
		milliseconds (400 by default; the window times it), and
		`on_scroll' hears every scroll. `set_styles' sets stretches of a
		paragraph smaller, raised or in small capitals - Strong's numbers
		after their words, LORD - on the shaped path; the toy path and
		the in-place editor show them plain.

		HIGHLIGHTS. Every paragraph has its own SW_MARKED_TEXT
		(`marks_of') - spans with reasons that a legend (`legend') turns
		into looks - painted by SW_MARK_PAINTER under and over the
		text. The in-place editor is handed the SAME object, so a span
		follows its words through every keystroke by the editor's own
		reconciliation and there is nothing to merge back; a cancelled
		edit restores the marks with the text.
	]"
	author: "Larry Rix"

class
	SW_PARAGRAPH_LIST

inherit
	SW_STACKED_POINTING
		redefine
			item_text_count,
			sub_widgets, arrange, widget_at, handle_wheel, handle_click,
			handle_double_click, handle_drag, handle_key, handle_char,
			cursor_kind, focusables,
			handle_release
		end

	SW_IN_PLACE_EDITING
		undefine
			set_hover_point, set_hovered, dwell_ms, handle_dwell, hover_card_at,
			accepts_focus, wants_hover_point
		redefine
			sub_widgets, arrange, widget_at, handle_wheel, handle_click,
			handle_double_click, handle_drag, handle_key, handle_char,
			cursor_kind, focusables,
			handle_release
		end

	SW_MARK_HOST

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			gutter_width := 28.0
			item_gap := 8.0
			item_pad := 8.0
			laid_scale := 1.0
			bar_gap := 4.0
			create texts.make (16)
			create revisions.make (16)
			create bands_above.make (16)
			create bands_below.make (16)
			create selected_flags.make (16)
			create marks_list.make (16)
			create styles_list.make (16)
			create geometries.make (16)
			init_pointing
			wheel_line := 20.0
			create edit_marks_backup.make (0)
			text_alignment := {SHAPING_CONSTANTS}.Align_left
		ensure
			kept: viewport_height = a_viewport_height
			empty: count = 0
			flush_left: text_alignment = {SHAPING_CONSTANTS}.Align_left
			gutter_left: not is_gutter_on_reading_side
		end

feature -- Access

	count: INTEGER
			-- Paragraphs held.
		do
			Result := texts.count
		ensure
			non_negative: Result >= 0
		end

	text_of (a_i: INTEGER): STRING_32
			-- Paragraph `a_i''s text (a copy; the list keeps its own).
		do
			Result := texts.i_th (a_i).twin
		end

	gutter_width: REAL_64
			-- At 1x; drawn `gutter_px' wide, scaled with the text (as the
			-- theme's spacing tokens are).
			-- The host-drawn column at every paragraph's left.

	item_gap: REAL_64
			-- Between two paragraphs.

	item_pad: REAL_64
			-- Inside a paragraph's box, above and below its content.

	selected_index: INTEGER
			-- The anchor: the paragraph the keyboard moves from and
			-- the editor opens on; 0 = none.

	on_select: detachable PROCEDURE [INTEGER]
			-- The anchor moved to this paragraph.

	on_activate: detachable PROCEDURE [INTEGER]
			-- A paragraph was double-clicked.

	gutter_renderer: detachable PROCEDURE [SW_PAINTER, INTEGER, REAL_64, REAL_64, REAL_64, REAL_64]
			-- Draws paragraph `index''s gutter: (painter, index, x, y, width, height).

	band_renderer: detachable PROCEDURE [SW_PAINTER, INTEGER, BOOLEAN, REAL_64, REAL_64, REAL_64, REAL_64]
			-- Draws a band: (painter, index, is_above, x, y, width, height).

	wash_of: detachable FUNCTION [INTEGER, NATURAL_32]
			-- The colour washing paragraph `index''s box; 0 = none.

	marks_of (a_i: INTEGER): SW_MARKED_TEXT
			-- The data behind paragraph `a_i': lay spans on it here.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := marks_list.i_th (a_i)
		ensure
			fits: Result.text_count = text_of (a_i).count
		end

	styles_of (a_i: INTEGER): SHAPING_STYLES
			-- How paragraph `a_i''s stretches are set (a copy; change it
			-- through `set_styles').
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := styles_list.i_th (a_i).deep_twin
		end

	set_styles (a_i: INTEGER; a_styles: SHAPING_STYLES)
			-- Set paragraph `a_i''s stretches by `a_styles' (a copy is
			-- kept); it re-measures on the next frame.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			styles_list.put_i_th (a_styles.deep_twin, a_i)
			styles_list.i_th (a_i).clamp_to (texts.i_th (a_i).count)
			revisions.put_i_th (revisions.i_th (a_i) + 1, a_i)
		ensure
			kept: styles_of (a_i).count <= a_styles.count
		end

feature -- Status

	is_selected (a_i: INTEGER): BOOLEAN
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := selected_flags.i_th (a_i)
		end

	selection_count: INTEGER
		do
			across
				selected_flags as f
			loop
				if f then
					Result := Result + 1
				end
			end
		ensure
			bounded: Result >= 0 and Result <= count
		end

	selected_indices: ARRAYED_LIST [INTEGER]
			-- Every selected paragraph, ascending.
		local
			i: INTEGER
		do
			create Result.make (selection_count)
			from
				i := 1
			until
				i > count
			loop
				if selected_flags.i_th (i) then
					Result.extend (i)
				end
				i := i + 1
			end
		ensure
			complete: Result.count = selection_count
		end

	is_laid_out: BOOLEAN
			-- Has every paragraph been measured for the current width?
		do
			Result := stack.count = count and geometries.count = count
				and not stack.key.same_string ("%U")
		end

	is_shaped_layout: BOOLEAN
			-- Did the last measurement go through the shaping kit?
		do
			Result := laid_shaped
		end

feature -- Geometry

	band_above (a_i: INTEGER): REAL_64
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := bands_above.i_th (a_i)
		ensure
			non_negative: Result >= 0.0
		end

	band_below (a_i: INTEGER): REAL_64
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := bands_below.i_th (a_i)
		ensure
			non_negative: Result >= 0.0
		end

	content_height: REAL_64
			-- Every paragraph stacked with its gaps; 0 before layout.
		do
			if is_laid_out and count > 0 then
				Result := stack.content_height
			end
		ensure
			non_negative: Result >= 0.0
		end

	scroll_extent: REAL_64
			-- Every paragraph stacked (SW_VSCROLLING).
		do
			Result := content_height
		end

	item_top (a_i: INTEGER): REAL_64
			-- Paragraph `a_i''s top in CONTENT coordinates (before scroll).
		require
			in_range: a_i >= 1 and a_i <= count
			laid_out: is_laid_out
		do
			Result := stack.top (a_i)
		ensure
			non_negative: Result >= 0.0
		end

	item_height (a_i: INTEGER): REAL_64
		require
			in_range: a_i >= 1 and a_i <= count
			laid_out: is_laid_out
		do
			Result := stack.height (a_i)
		ensure
			positive: Result > 0.0
		end

	item_at (a_py: REAL_64): INTEGER
			-- The paragraph under window y `a_py'; 0 outside every box
			-- (SW_STACKED_ITEMS: a binary search).
		do
			Result := stacked_item_at (a_py)
		ensure
			in_range: Result >= 0 and Result <= count
			nothing_above: a_py < y implies Result = 0
		end

	text_x: REAL_64
			-- Where a paragraph's text starts, in window coordinates, with
			-- the gutter on the left (every paragraph before GW-02).
		do
			Result := x + gutter_px + pad_px
		end

	item_text_x (a_i: INTEGER): REAL_64
			-- Where paragraph `a_i''s text starts: `text_x', or - for a
			-- right-to-left paragraph when the gutter follows the reading -
			-- just inside the left edge, the gutter moved to the right.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			if gutter_reads_right (a_i) then
				Result := x + pad_px
			else
				Result := text_x
			end
		end

	item_gutter_x (a_i: INTEGER): REAL_64
			-- Where paragraph `a_i''s gutter is drawn: the left edge, or the
			-- right edge of the text area for a right-to-left paragraph when
			-- the gutter follows the reading (GW-02: the verse number sits on
			-- the side the Hebrew starts from).
		require
			in_range: a_i >= 1 and a_i <= count
		do
			if gutter_reads_right (a_i) then
				Result := x + width - bar.bar_width - bar_gap - gutter_px
			else
				Result := x
			end
		end

	gutter_reads_right (a_i: INTEGER): BOOLEAN
			-- Does paragraph `a_i' carry its gutter on the right?
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := is_gutter_on_reading_side and then a_i <= geometries.count
				and then geometries.i_th (a_i).starts_right_to_left
		end

feature -- Pointing (GW-08)

	caret_offset_at (a_px, a_py: REAL_64): INTEGER
			-- The caret offset nearest the point in paragraph
			-- `item_at (a_py)', 0 .. its length; 0 outside every paragraph.
		local
			i: INTEGER
		do
			i := item_at (a_py)
			if i > 0 then
				Result := offset_at_point (i, a_px, a_py)
			end
		ensure
			non_negative: Result >= 0
		end

	item_geometry (a_i: INTEGER): SW_TEXT_GEOMETRY
			-- Paragraph `a_i''s geometry (SW_TEXT_POINTING).
		do
			Result := geometries.i_th (a_i)
		end

	item_origin_x (a_i: INTEGER): REAL_64
		do
			Result := item_text_x (a_i)
		end

	item_origin_y (a_i: INTEGER): REAL_64
		do
			Result := text_top (a_i)
		end

	is_item_pointable (a_i: INTEGER): BOOLEAN
			-- Measured, and not under the in-place editor (the editor
			-- answers there).
		do
			Result := is_laid_out and then a_i <= geometries.count and then a_i /= editing_index
		end

	item_text_count (a_i: INTEGER): INTEGER
			-- Without `text_of''s copy.
		do
			Result := texts.i_th (a_i).count
		end

	text_top (a_i: INTEGER): REAL_64
			-- Window y where paragraph `a_i''s text begins (below its band).
		require
			in_range: a_i >= 1 and a_i <= count
		do
			if is_laid_out then
				Result := stacked_top (a_i) + pad_px + bands_above.i_th (a_i)
			end
		end

	is_valid_item (a_item: INTEGER): BOOLEAN
			-- Is `a_item' a paragraph (SW_TEXT_POINTING)?
		do
			Result := a_item >= 1 and a_item <= count
		end

	pointed_item (a_px, a_py: REAL_64): INTEGER
			-- The paragraph under the point: `item_at (a_py)', inside the
			-- list and off its scrollbar.
		do
			if contains (a_px, a_py) and then not bar.contains (a_px, a_py) then
				Result := item_at (a_py)
			end
		end

feature -- Alignment (GW-02)

	text_alignment: INTEGER
			-- How each paragraph's lines sit in the text area on the shaped
			-- path: a SHAPING_CONSTANTS Align_* code. Align_left (the
			-- default) is the list before GW-02; Align_start sets each Hebrew
			-- paragraph flush right and each English one flush left.

	is_gutter_on_reading_side: BOOLEAN
			-- Does a right-to-left paragraph carry its gutter on the right?

	set_text_alignment (a_alignment: INTEGER)
			-- Place every paragraph's lines by `a_alignment'.
		require
			alignment_valid: a_alignment >= {SHAPING_CONSTANTS}.Align_start
				and a_alignment <= {SHAPING_CONSTANTS}.Align_center
		do
			if a_alignment /= text_alignment then
				text_alignment := a_alignment
				laid_width := -1.0
			end
		ensure
			set: text_alignment = a_alignment
		end

	set_gutter_on_reading_side (a_on: BOOLEAN)
			-- Put a right-to-left paragraph's gutter on the right (or not).
		do
			is_gutter_on_reading_side := a_on
		ensure
			set: is_gutter_on_reading_side = a_on
		end

	text_width: REAL_64
			-- How wide a paragraph's text may run.
		do
			Result := (width - bar.bar_width - bar_gap - gutter_px - 2.0 * pad_px).max (16.0)
		ensure
			positive: Result >= 16.0
		end

feature -- Element change

	add (a_text: READABLE_STRING_GENERAL)
			-- Append a paragraph.
		do
			insert (count + 1, a_text)
		ensure
			one_more: count = old count + 1
			appended: text_of (count).same_string_general (a_text)
		end

	insert (a_i: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- A new paragraph at position `a_i'; the ones from there
			-- down shift by one, and so do the selection and the editor.
		require
			in_range: a_i >= 1 and a_i <= count + 1
		local
			l_text: STRING_32
		do
			create l_text.make_from_string_general (a_text)
			texts.go_i_th (a_i)
			texts.put_left (l_text)
			revisions.go_i_th (a_i)
			revisions.put_left (1)
			bands_above.go_i_th (a_i)
			bands_above.put_left (0.0)
			bands_below.go_i_th (a_i)
			bands_below.put_left (0.0)
			selected_flags.go_i_th (a_i)
			selected_flags.put_left (False)
			marks_list.go_i_th (a_i)
			marks_list.put_left (create {SW_MARKED_TEXT}.make (l_text.count))
			styles_list.go_i_th (a_i)
			styles_list.put_left (create {SHAPING_STYLES}.make)
			drop_measurements
			if selected_index >= a_i then
				selected_index := selected_index + 1
			end
			if editing_index >= a_i then
				editing_index := editing_index + 1
			end
		ensure
			one_more: count = old count + 1
			placed: text_of (a_i).same_string_general (a_text)
		end

	put_text (a_i: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Replace paragraph `a_i''s text; it re-measures on the next
			-- frame. While it is being edited the editor follows.
		require
			in_range: a_i >= 1 and a_i <= count
		local
			l_text: STRING_32
		do
			create l_text.make_from_string_general (a_text)
			texts.put_i_th (l_text, a_i)
			revisions.put_i_th (revisions.i_th (a_i) + 1, a_i)
			if a_i = editing_index and then attached editor as al_ed
				and then not al_ed.text.same_string (l_text)
			then
				al_ed.set_text (l_text)
			end
			marks_list.i_th (a_i).clamp_to (l_text.count)
			styles_list.i_th (a_i).clamp_to (l_text.count)
		ensure
			kept: text_of (a_i).same_string_general (a_text)
			count_unchanged: count = old count
		end

	remove (a_i: INTEGER)
			-- Take paragraph `a_i' out; an edit on it is cancelled.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			if editing_index = a_i then
				close_editor
			end
			texts.go_i_th (a_i)
			texts.remove
			revisions.go_i_th (a_i)
			revisions.remove
			bands_above.go_i_th (a_i)
			bands_above.remove
			bands_below.go_i_th (a_i)
			bands_below.remove
			selected_flags.go_i_th (a_i)
			selected_flags.remove
			marks_list.go_i_th (a_i)
			marks_list.remove
			styles_list.go_i_th (a_i)
			styles_list.remove
			drop_measurements
			if selected_index = a_i then
				selected_index := 0
			elseif selected_index > a_i then
				selected_index := selected_index - 1
			end
			if editing_index > a_i then
				editing_index := editing_index - 1
			end
		ensure
			one_fewer: count = old count - 1
			not_editing_it: editing_index /= a_i or else not is_editing
		end

	move (a_from, a_to: INTEGER)
			-- Paragraph `a_from' takes position `a_to'; everything
			-- travels with it - text, bands, selection flag, the anchor
			-- and the editor.
		require
			from_in_range: a_from >= 1 and a_from <= count
			to_in_range: a_to >= 1 and a_to <= count
		local
			l_text: STRING_32
			l_rev: INTEGER
			l_above, l_below: REAL_64
			l_sel: BOOLEAN
			l_marks: SW_MARKED_TEXT
			l_styles: SHAPING_STYLES
		do
			if a_from /= a_to then
				l_marks := marks_list.i_th (a_from)
				l_styles := styles_list.i_th (a_from)
				l_text := texts.i_th (a_from)
				l_rev := revisions.i_th (a_from)
				l_above := bands_above.i_th (a_from)
				l_below := bands_below.i_th (a_from)
				l_sel := selected_flags.i_th (a_from)
				texts.go_i_th (a_from)
				texts.remove
				revisions.go_i_th (a_from)
				revisions.remove
				bands_above.go_i_th (a_from)
				bands_above.remove
				bands_below.go_i_th (a_from)
				bands_below.remove
				selected_flags.go_i_th (a_from)
				selected_flags.remove
				marks_list.go_i_th (a_from)
				marks_list.remove
				styles_list.go_i_th (a_from)
				styles_list.remove
				texts.go_i_th (a_to)
				texts.put_left (l_text)
				revisions.go_i_th (a_to)
				revisions.put_left (l_rev)
				bands_above.go_i_th (a_to)
				bands_above.put_left (l_above)
				bands_below.go_i_th (a_to)
				bands_below.put_left (l_below)
				selected_flags.go_i_th (a_to)
				selected_flags.put_left (l_sel)
				marks_list.go_i_th (a_to)
				marks_list.put_left (l_marks)
				styles_list.go_i_th (a_to)
				styles_list.put_left (l_styles)
				selected_index := shifted (selected_index, a_from, a_to)
				editing_index := shifted (editing_index, a_from, a_to)
				drop_measurements
			end
		ensure
			count_unchanged: count = old count
			moved: text_of (a_to).same_string (old text_of (a_from))
		end

	wipe_out
			-- No paragraphs, no selection, no editor.
		do
			close_editor
			texts.wipe_out
			revisions.wipe_out
			bands_above.wipe_out
			bands_below.wipe_out
			selected_flags.wipe_out
			marks_list.wipe_out
			styles_list.wipe_out
			hover_item := 0
			hover_character := 0
			selected_index := 0
			scroll_y := 0.0
			drop_measurements
		ensure
			empty: count = 0
			nothing_selected: selected_index = 0
		end

	set_band_above (a_i: INTEGER; a_h: REAL_64)
		require
			in_range: a_i >= 1 and a_i <= count
			non_negative: a_h >= 0.0
		do
			bands_above.put_i_th (a_h, a_i)
			revisions.put_i_th (revisions.i_th (a_i) + 1, a_i)
		ensure
			set: band_above (a_i) = a_h
		end

	set_band_below (a_i: INTEGER; a_h: REAL_64)
		require
			in_range: a_i >= 1 and a_i <= count
			non_negative: a_h >= 0.0
		do
			bands_below.put_i_th (a_h, a_i)
			revisions.put_i_th (revisions.i_th (a_i) + 1, a_i)
		ensure
			set: band_below (a_i) = a_h
		end

	set_gutter_width (a_w: REAL_64)
		require
			non_negative: a_w >= 0.0
		do
			gutter_width := a_w
			drop_measurements
		ensure
			set: gutter_width = a_w
		end

	set_item_gap (a_gap: REAL_64)
		require
			non_negative: a_gap >= 0.0
		do
			item_gap := a_gap
			drop_measurements
		ensure
			set: item_gap = a_gap
		end

	set_on_select (a_action: PROCEDURE [INTEGER])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

	set_on_activate (a_action: PROCEDURE [INTEGER])
		do
			on_activate := a_action
		ensure
			set: on_activate = a_action
		end

	set_gutter_renderer (a_r: PROCEDURE [SW_PAINTER, INTEGER, REAL_64, REAL_64, REAL_64, REAL_64])
		do
			gutter_renderer := a_r
		ensure
			set: gutter_renderer = a_r
		end

	set_band_renderer (a_r: PROCEDURE [SW_PAINTER, INTEGER, BOOLEAN, REAL_64, REAL_64, REAL_64, REAL_64])
		do
			band_renderer := a_r
		ensure
			set: band_renderer = a_r
		end

	set_wash_of (a_f: FUNCTION [INTEGER, NATURAL_32])
		do
			wash_of := a_f
		ensure
			set: wash_of = a_f
		end

feature -- Selection

	select_only (a_i: INTEGER)
			-- Paragraph `a_i' alone, and it becomes the anchor; 0 clears.
		require
			in_range: a_i >= 0 and a_i <= count
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > count
			loop
				selected_flags.put_i_th (i = a_i, i)
				i := i + 1
			end
			selected_index := a_i
			if a_i > 0 and then attached on_select as al_s then
				al_s.call (a_i)
			end
		ensure
			anchored: selected_index = a_i
			just_it: selection_count = (a_i > 0).to_integer
		end

	toggle_select (a_i: INTEGER)
			-- Flip paragraph `a_i' in the set; it becomes the anchor.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			selected_flags.put_i_th (not selected_flags.i_th (a_i), a_i)
			selected_index := a_i
			if attached on_select as al_s then
				al_s.call (a_i)
			end
		ensure
			flipped: is_selected (a_i) = not old is_selected (a_i)
			anchored: selected_index = a_i
		end

	select_range (a_from, a_to: INTEGER)
			-- Every paragraph between the two, inclusive, in either
			-- order, ADDED to the set; the anchor stays where it was.
		require
			from_in_range: a_from >= 1 and a_from <= count
			to_in_range: a_to >= 1 and a_to <= count
		local
			i: INTEGER
		do
			from
				i := a_from.min (a_to)
			until
				i > a_from.max (a_to)
			loop
				selected_flags.put_i_th (True, i)
				i := i + 1
			end
		ensure
			covered: across a_from.min (a_to) |..| a_from.max (a_to) as k all is_selected (k) end
			anchor_kept: selected_index = old selected_index
		end

	clear_selection
		do
			select_only (0)
		ensure
			nothing: selection_count = 0 and selected_index = 0
		end

feature -- Scrolling

	scroll_to_item (a_i: INTEGER)
			-- Bring paragraph `a_i' into the viewport, once laid out.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			scroll_item_into_view (a_i)
		ensure
			visible_once_laid_out: (is_laid_out and height > 0.0) implies
				(a_i >= first_visible and a_i <= last_visible)
		end

feature -- Editing

	begin_edit (a_i: INTEGER)
			-- Lay the editor over paragraph `a_i' with its text, select
			-- it alone, and give the editor the caret.
		require
			in_range: a_i >= 1 and a_i <= count
			not_editing: not is_editing
		do
			open_editor (a_i, texts.i_th (a_i))
			if attached editor as al_ed then
				al_ed.set_marks (marks_list.i_th (a_i))
				al_ed.set_legend (legend)
				al_ed.mark_painter.set_floors (mark_painter.min_mark_size, mark_painter.min_effect_size, mark_painter.min_badge_size)
					-- GW-02: the editor places lines as the list does, so the
					-- text does not jump sideways when editing begins.
				al_ed.set_text_alignment (text_alignment)
			end
			edit_marks_backup := marks_list.i_th (a_i).duplicate
			select_only (a_i)
		ensure
			editing: is_editing and editing_index = a_i
			editor_up: attached editor as al_ed and then al_ed.text.same_string (text_of (a_i))
			caret_at_the_end: attached editor as al_ed2 and then al_ed2.caret = al_ed2.text.count
			selected: selected_index = a_i
		end

	keep_item (a_i: INTEGER; a_text: STRING_32)
			-- The paragraph already follows the typing (`edited').
		do
			texts.put_i_th (a_text, a_i)
		end

	restore_item (a_i: INTEGER)
			-- The text and marks as they stood at `begin_edit'.
		do
			texts.put_i_th (edit_backup.twin, a_i)
			marks_list.i_th (a_i).copy_from (edit_marks_backup)
			revisions.put_i_th (revisions.i_th (a_i) + 1, a_i)
		ensure then
			restored: text_of (a_i).same_string (edit_backup)
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			Result := editor_sub_widgets
		end

	focusables (a_acc: ARRAYED_LIST [SW_WIDGET])
			-- The list itself joins the Tab ring; the editor is reached
			-- by clicking it, never by tabbing past the list into it.
		do
			if accepts_focus and is_enabled then
				a_acc.extend (Current)
			end
		end

feature -- Layout

	cursor_kind: INTEGER
			-- The I-beam over the editor, the arrow elsewhere.
		do
			if is_editing and then attached editor as al_ed and then al_ed.contains (hover_px, hover_py) then
				Result := 1
			end
		end

	arrange (a_p: SW_PAINTER)
			-- Measure every paragraph, then seat the editor over its
			-- paragraph so the text does not move when editing begins.
		local
			i: INTEGER
			ty: REAL_64
		do
			measure (a_p)
			scroll_y := scroll_y.min (max_scroll)
			if is_editing and then attached editor as al_ed then
				i := editing_index
				ty := stacked_top (i) + pad_px + bands_above.i_th (i)
				seat_editor (a_p, item_text_x (i), ty, text_width,
					stack.height (i) - 2.0 * pad_px - bands_above.i_th (i) - bands_below.i_th (i))
			end
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- The editor where it stands (off the bar), else the list.
		do
			Result := widget_or_editor_at (a_px, a_py, not bar.contains (a_px, a_py))
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- Only the paragraphs inside the viewport, then the bar.
		do
			measure (a_p)
			scroll_y := scroll_y.min (max_scroll)
			begin_frame (a_p)
			draw_visible (a_p)
			end_frame (a_p)
			draw_bar (a_p)
		end

	draw_stacked_item (a_p: SW_PAINTER; a_i: INTEGER)
			-- One paragraph: wash, ring, gutter, bands, text (or the editor
			-- over it).
		local
			t: SW_THEME
			inner_w, top, bx, by, bw, bh, ty, th: REAL_64
			l_wash: NATURAL_32
		do
			t := a_p.theme
			inner_w := width - bar.bar_width - bar_gap
			top := stacked_top (a_i)
			bx := x
			by := top
			bw := inner_w
			bh := stack.height (a_i)
			l_wash := 0
			if attached wash_of as al_w then
				l_wash := al_w.item ([a_i])
			end
			if l_wash /= 0 then
				a_p.set_color (l_wash)
				a_p.rrect_fill (bx, by, bw, bh, t.radius)
			elseif selected_flags.i_th (a_i) then
				a_p.set_color (t.wash_accent)
				a_p.rrect_fill (bx, by, bw, bh, t.radius)
			end
			if a_i = selected_index then
				a_p.set_color (t.accent)
				a_p.set_line_width (2.0)
				a_p.rrect_stroke (bx + 1.0, by + 1.0, bw - 2.0, bh - 2.0, t.radius)
				a_p.set_line_width (1.0)
			elseif selected_flags.i_th (a_i) then
				a_p.set_color (t.accent)
				a_p.rrect_stroke (bx + 0.5, by + 0.5, bw - 1.0, bh - 1.0, t.radius)
			end
			if attached gutter_renderer as al_g and then gutter_width > 0.0 then
				al_g.call (a_p, a_i, item_gutter_x (a_i), by, gutter_px, bh)
			end
			ty := by + pad_px
			if bands_above.i_th (a_i) > 0.0 then
				if attached band_renderer as al_b then
					al_b.call (a_p, a_i, True, item_text_x (a_i), ty, text_width, bands_above.i_th (a_i))
				end
				ty := ty + bands_above.i_th (a_i)
			end
			th := bh - 2.0 * pad_px - bands_above.i_th (a_i) - bands_below.i_th (a_i)
			if a_i = editing_index and then attached editor as al_ed then
				al_ed.draw (a_p)
			else
				if marks_list.i_th (a_i).text_count /= geometries.i_th (a_i).count then
					marks_list.i_th (a_i).clamp_to (geometries.i_th (a_i).count)
				end
				mark_painter.paint_under (a_p, geometries.i_th (a_i), marks_list.i_th (a_i), legend, item_text_x (a_i), ty)
				a_p.set_color (t.ink)
				draw_item_text (a_i, a_p, 0.0, 0.0, item_text_x (a_i), ty)
				mark_painter.paint_over (a_p, geometries.i_th (a_i), marks_list.i_th (a_i), legend, item_text_x (a_i), ty,
					t.size_body * t.text_scale, agent draw_item_text (a_i, ?, ?, ?, item_text_x (a_i), ty))
				ty := by + pad_px + bands_above.i_th (a_i) + th
			end
			if bands_below.i_th (a_i) > 0.0 and then attached band_renderer as al_b2 then
				al_b2.call (a_p, a_i, False, item_text_x (a_i), ty, text_width, bands_below.i_th (a_i))
			end
		end

feature -- Input

	handle_wheel (a_delta: INTEGER): BOOLEAN
			-- Scroll; the text moved under the pointer, so the character
			-- under it may have changed.
		do
			wheel_scrolled (a_delta)
			if is_hovered then
				follow_hover
			end
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- The bar pages; a paragraph selects - plain alone, Ctrl
			-- toggles, Shift ranges from the anchor. Clicking another
			-- paragraph while editing commits the edit first.
		local
			i: INTEGER
			keys: SW_KEYS
		do
			if press_bar (a_px, a_py) then
				Result := True
			else
				i := item_at (a_py)
				if i > 0 then
					if is_editing and then i /= editing_index then
						end_edit (True)
					end
					create keys
					if keys.control_down then
						toggle_select (i)
					elseif keys.shift_down and then selected_index > 0 then
						select_range (selected_index, i)
					else
						select_only (i)
					end
					Result := True
				end
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
		do
			i := item_at (a_py)
			if i > 0 and not bar.contains (a_px, a_py) then
				select_only (i)
				if attached on_activate as al_a then
					al_a.call (i)
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			drag_bar (a_py).do_nothing
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go of the scrollbar thumb.
		do
			release_bar
		ensure then
			released: not bar.is_dragging
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- While editing, the editor's; otherwise arrows, PgUp/PgDn,
			-- Home/End move the anchor and keep it in view.
		local
			target: INTEGER
		do
			if editor_key (a_vk, a_shift) then
					-- The editor's.
			elseif count > 0 then
				inspect a_vk
				when 40 then
					target := (selected_index + 1).min (count).max (1)
				when 38 then
					target := (selected_index - 1).max (1)
				when 34 then
					target := (selected_index + page_items).min (count).max (1)
				when 33 then
					target := (selected_index - page_items).max (1)
				when 36 then
					target := 1
				when 35 then
					target := count
				else
					target := 0
				end
				if target > 0 and target /= selected_index then
					if a_shift and then selected_index > 0 then
						select_range (selected_index, target)
						selected_index := target
					else
						select_only (target)
					end
					scroll_to_item (target)
				end
			end
		end

	handle_char (a_code: INTEGER)
			-- While editing: Escape cancels, everything else types.
		do
			editor_char (a_code).do_nothing
		end

feature {NONE} -- Measurement

	laid_scale: REAL_64
			-- The theme's `text_scale' at the last measure (1.0 before).

	bar_gap: REAL_64
			-- Between the items and the scrollbar: half the theme's
			-- padding at the last measure (4 pixels at 1x).

	gutter_px: REAL_64
			-- `gutter_width' at the text's scale.
		do
			Result := gutter_width * laid_scale
		end

	gap_px: REAL_64
			-- `item_gap' at the text's scale.
		do
			Result := item_gap * laid_scale
		end

	pad_px: REAL_64
			-- `item_pad' at the text's scale.
		do
			Result := item_pad * laid_scale
		end

	wheel_line: REAL_64
			-- One line of body text at the last measure: a wheel notch
			-- scrolls SW_VSCROLLBAR.Wheel_lines of them.

	texts: ARRAYED_LIST [STRING_32]
	revisions: ARRAYED_LIST [INTEGER]
			-- Per paragraph, bumped on every text or band change.
	bands_above: ARRAYED_LIST [REAL_64]
	bands_below: ARRAYED_LIST [REAL_64]
	geometries: ARRAYED_LIST [SW_TEXT_GEOMETRY]
			-- Per paragraph, where its characters paint (either engine).
	marks_list: ARRAYED_LIST [SW_MARKED_TEXT]
			-- Per paragraph, the data behind it.
	styles_list: ARRAYED_LIST [SHAPING_STYLES]
			-- Per paragraph, how its stretches are set (GW-08).
	edit_marks_backup: SW_MARKED_TEXT
			-- The edited paragraph's marks as they stood at `begin_edit'.
	selected_flags: ARRAYED_LIST [BOOLEAN]
	laid_width: REAL_64
	laid_size: INTEGER
	laid_shaped: BOOLEAN

	drop_measurements
			-- Every paragraph measures again on the next frame.
		do
			stack.invalidate
			geometries.wipe_out
		ensure
			dropped: not is_laid_out or count = 0
		end

	measure (a_p: SW_PAINTER)
			-- Every paragraph's height at the current width, size and
			-- engine - re-measuring only what changed - then the tops.
		do
			laid_scale := a_p.theme.text_scale
			bar_gap := a_p.theme.padding / 2.0
			bar.place (x, y, width, height, a_p.theme)
			measure_width := text_width
			measure_shaped := a_p.has_shaping
			measure_px := body_pixel_size (a_p)
			if geometries.count /= count then
				stack.invalidate
			end
			measure_stack (a_p, measure_width.out + "|" + measure_px.out + "|" + measure_shaped.out, gap_px).do_nothing
			wheel_line := measure_px * 1.5
			place_bar (a_p.theme)
		ensure
			laid_out: is_laid_out
			engine_recorded: laid_shaped = a_p.has_shaping
		end

	measure_width: REAL_64
	measure_px: INTEGER
	measure_shaped: BOOLEAN
			-- The width, size and engine of the pass under way.

	stack_count: INTEGER
		do
			Result := count
		end

	stack_origin_y: REAL_64
			-- The list has no page inset.
		do
		end

	item_revision (a_i: INTEGER): INTEGER
		do
			Result := revisions.i_th (a_i)
		end

	is_volatile (a_i: INTEGER): BOOLEAN
			-- The paragraph under the editor follows its typing.
		do
			Result := a_i = editing_index
		end

	stack_reset
			-- A fresh geometry per paragraph, for this width, size and engine.
		local
			i: INTEGER
		do
			geometries.wipe_out
			laid_width := measure_width
			laid_size := measure_px
			laid_shaped := measure_shaped
			from
				i := 1
			until
				i > count
			loop
				geometries.extend (create {SW_TEXT_GEOMETRY}.make)
				i := i + 1
			end
		end

	measure_item (a_p: SW_PAINTER; a_i: INTEGER): REAL_64
			-- The paragraph's box: padding, bands and its text (the editor's
			-- while editing).
		local
			th: REAL_64
		do
			if a_i = editing_index and then is_editing then
				th := editor_text_height (a_p, measure_width)
			else
				th := laid_text_height (a_p, a_i, measure_width)
			end
			Result := (2.0 * pad_px + bands_above.i_th (a_i) + th + bands_below.i_th (a_i)).max (1.0)
		end

	laid_text_height (a_p: SW_PAINTER; a_i: INTEGER; a_w: REAL_64): REAL_64
			-- Lay paragraph `a_i' out into its geometry (SW_TEXT_GEOMETRY
			-- .lay_out) and answer the stacked height.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			geometries.i_th (a_i).set_alignment (text_alignment, a_w.floor.max (16).to_double)
			geometries.i_th (a_i).set_styles (styles_list.i_th (a_i))
			Result := geometries.i_th (a_i).lay_out (a_p, texts.i_th (a_i), a_w, 0, a_p.theme.size_body, False, False, False)
		ensure
			positive: Result > 0.0
		end

	draw_item_text (a_i: INTEGER; a_p: SW_PAINTER; a_dx, a_dy, a_ox, a_oy: REAL_64)
			-- Paragraph `a_i''s text shifted by (a_dx, a_dy) from its
			-- origin (a_ox, a_oy), in the painter's current colour.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			geometries.i_th (a_i).draw (a_p, texts.i_th (a_i), False, a_ox + a_dx, a_oy + a_dy)
		end

	page_items: INTEGER
			-- How many paragraphs one PgUp/PgDn stride covers: the
			-- visible band, at least one.
		do
			Result := (last_visible - first_visible).max (1)
		ensure
			positive: Result >= 1
		end

	shifted (a_index, a_from, a_to: INTEGER): INTEGER
			-- Where index `a_index' lands after paragraph `a_from'
			-- moves to `a_to'; 0 stays 0.
		do
			if a_index = 0 then
				Result := 0
			elseif a_index = a_from then
				Result := a_to
			elseif a_from < a_to and then a_index > a_from and then a_index <= a_to then
				Result := a_index - 1
			elseif a_from > a_to and then a_index >= a_to and then a_index < a_from then
				Result := a_index + 1
			else
				Result := a_index
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

edited (a_i: INTEGER; a_text: STRING_32)
			-- The editor typed: the paragraph follows and its height
			-- reflows (SW_IN_PLACE_EDITING tells the host).
		do
			texts.put_i_th (a_text, a_i)
			revisions.put_i_th (revisions.i_th (a_i) + 1, a_i)
		end

invariant
	texts_attached: texts /= Void
	parallel_model: revisions.count = count and bands_above.count = count
		and bands_below.count = count and selected_flags.count = count
		and marks_list.count = count and styles_list.count = count
	measurements_never_outrun: geometries.count <= count
	anchor_in_range: selected_index >= 0 and selected_index <= count
	editing_in_range: editing_index >= 0 and editing_index <= count
	metrics_non_negative: gutter_width >= 0.0 and item_gap >= 0.0 and item_pad >= 0.0
	viewport_positive: viewport_height > 0.0

end
