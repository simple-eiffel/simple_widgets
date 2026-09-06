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
		`end_edit (True)' - or a click on another paragraph - commits
		through `on_edit_commit'. The list forwards keys to the editor
		while the list itself holds focus, so typing works the instant
		the edit begins; a click inside the editor moves the window's
		focus onto it and the keys then arrive directly.

		SELECTION. `selected_index' is the anchor - the paragraph the
		keyboard moves from - and `is_selected' is the set. A plain
		click selects only; Ctrl+click toggles; Shift+click ranges from
		the anchor. Assigning one property to six paragraphs is one
		gesture, which is the whole reason the set exists.

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
	SW_WIDGET
		redefine
			sub_widgets, arrange, widget_at, handle_wheel, handle_click,
			handle_double_click, handle_drag, handle_key, handle_char,
			accepts_focus, wants_hover_point, cursor_kind, focusables
		end

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
			create texts.make (16)
			create revisions.make (16)
			create laid_revisions.make (16)
			create laid_heights.make (16)
			create laid_tops.make (16)
			create bands_above.make (16)
			create bands_below.make (16)
			create selected_flags.make (16)
			create marks_list.make (16)
			create geometries.make (16)
			create mark_painter.make
			create edit_backup.make_empty
			create edit_marks_backup.make (0)
		ensure
			kept: viewport_height = a_viewport_height
			empty: count = 0
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
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := texts.i_th (a_i).twin
		end

	viewport_height: REAL_64

	scroll_y: REAL_64
			-- How far the content is shifted up; 0 .. `max_scroll'.

	gutter_width: REAL_64
			-- The host-drawn column at every paragraph's left.

	item_gap: REAL_64
			-- Between two paragraphs.

	item_pad: REAL_64
			-- Inside a paragraph's box, above and below its content.

	selected_index: INTEGER
			-- The anchor: the paragraph the keyboard moves from and
			-- the editor opens on; 0 = none.

	editing_index: INTEGER
			-- The paragraph under the in-place editor; 0 = none.

	editor: detachable SW_TEXT_BOX
			-- The in-place editor while `is_editing'.

	on_select: detachable PROCEDURE [INTEGER]
			-- The anchor moved to this paragraph.

	on_activate: detachable PROCEDURE [INTEGER]
			-- A paragraph was double-clicked.

	on_edit_change: detachable PROCEDURE [INTEGER, STRING_32]
			-- The editor changed this paragraph's text (live).

	on_edit_commit: detachable PROCEDURE [INTEGER, STRING_32]
			-- The edit ended and this is the text that stands.

	gutter_renderer: detachable PROCEDURE [SW_PAINTER, INTEGER, REAL_64, REAL_64, REAL_64, REAL_64]
			-- Draws paragraph `index''s gutter: (painter, index, x, y, width, height).

	band_renderer: detachable PROCEDURE [SW_PAINTER, INTEGER, BOOLEAN, REAL_64, REAL_64, REAL_64, REAL_64]
			-- Draws a band: (painter, index, is_above, x, y, width, height).

	wash_of: detachable FUNCTION [INTEGER, NATURAL_32]
			-- The colour washing paragraph `index''s box; 0 = none.

	legend: detachable SW_MARK_LEGEND
			-- What a span's reason looks like, for every paragraph.

	mark_painter: SW_MARK_PAINTER
			-- Paints the spans; set its size floors here.

	marks_of (a_i: INTEGER): SW_MARKED_TEXT
			-- The data behind paragraph `a_i': lay spans on it here.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := marks_list.i_th (a_i)
		ensure
			fits: Result.text_count = text_of (a_i).count
		end

	set_legend (a_legend: detachable SW_MARK_LEGEND)
		do
			legend := a_legend
		ensure
			set: legend = a_legend
		end

feature -- Status

	is_editing: BOOLEAN
		do
			Result := editing_index > 0
		ensure
			definition: Result = (editing_index > 0)
		end

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
			Result := laid_tops.count = count and laid_heights.count = count
		end

	is_shaped_layout: BOOLEAN
			-- Did the last measurement go through the shaping kit?
		do
			Result := laid_shaped
		end

feature -- Geometry

	Bar_w: REAL_64 = 11.0

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
				Result := laid_tops.last + laid_heights.last
			end
		ensure
			non_negative: Result >= 0.0
		end

	max_scroll: REAL_64
		do
			Result := (content_height - height).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

	item_top (a_i: INTEGER): REAL_64
			-- Paragraph `a_i''s top in CONTENT coordinates (before scroll).
		require
			in_range: a_i >= 1 and a_i <= count
			laid_out: is_laid_out
		do
			Result := laid_tops.i_th (a_i)
		ensure
			non_negative: Result >= 0.0
		end

	item_height (a_i: INTEGER): REAL_64
		require
			in_range: a_i >= 1 and a_i <= count
			laid_out: is_laid_out
		do
			Result := laid_heights.i_th (a_i)
		ensure
			positive: Result > 0.0
		end

	item_at (a_py: REAL_64): INTEGER
			-- The paragraph under window y `a_py'; 0 outside every box.
		local
			i: INTEGER
			cy: REAL_64
		do
			if is_laid_out and then a_py >= y and then a_py < y + height then
				cy := a_py - y + scroll_y
				from
					i := 1
				until
					i > count or Result > 0
				loop
					if cy >= laid_tops.i_th (i) and then cy < laid_tops.i_th (i) + laid_heights.i_th (i) then
						Result := i
					end
					i := i + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
			nothing_above: a_py < y implies Result = 0
		end

	first_visible: INTEGER
			-- The first paragraph intersecting the viewport; 0 when empty.
		local
			i: INTEGER
		do
			if is_laid_out then
				from
					i := 1
				until
					i > count or Result > 0
				loop
					if laid_tops.i_th (i) + laid_heights.i_th (i) > scroll_y then
						Result := i
					end
					i := i + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

	last_visible: INTEGER
			-- The last paragraph intersecting the viewport; 0 when empty.
		local
			i: INTEGER
			vh: REAL_64
		do
			if is_laid_out then
				vh := height
				if vh <= 0.0 then
					vh := viewport_height
				end
				from
					i := 1
				until
					i > count
				loop
					if laid_tops.i_th (i) < scroll_y + vh then
						Result := i
					end
					i := i + 1
				end
			end
		ensure
			ordered: Result >= first_visible
		end

	text_x: REAL_64
			-- Where a paragraph's text starts, in window coordinates.
		do
			Result := x + gutter_width + item_pad
		end

	text_width: REAL_64
			-- How wide a paragraph's text may run.
		do
			Result := (width - Bar_w - 4.0 - gutter_width - 2.0 * item_pad).max (16.0)
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
				drop_editor
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
		do
			if a_from /= a_to then
				l_marks := marks_list.i_th (a_from)
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
			drop_editor
			texts.wipe_out
			revisions.wipe_out
			bands_above.wipe_out
			bands_below.wipe_out
			selected_flags.wipe_out
			marks_list.wipe_out
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

	set_on_edit_change (a_action: PROCEDURE [INTEGER, STRING_32])
		do
			on_edit_change := a_action
		ensure
			set: on_edit_change = a_action
		end

	set_on_edit_commit (a_action: PROCEDURE [INTEGER, STRING_32])
		do
			on_edit_commit := a_action
		ensure
			set: on_edit_commit = a_action
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

	scroll_to (a_y: REAL_64)
		do
			scroll_y := a_y.max (0.0).min (max_scroll)
		ensure
			clamped: scroll_y >= 0.0 and scroll_y <= max_scroll
		end

	scroll_to_item (a_i: INTEGER)
			-- Bring paragraph `a_i' into the viewport, once laid out.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			if is_laid_out and then height > 0.0 then
				if laid_tops.i_th (a_i) < scroll_y then
					scroll_to (laid_tops.i_th (a_i))
				elseif laid_tops.i_th (a_i) + laid_heights.i_th (a_i) > scroll_y + height then
					scroll_to (laid_tops.i_th (a_i) + laid_heights.i_th (a_i) - height)
				end
			end
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
		local
			l_ed: SW_TEXT_BOX
		do
			create l_ed.make (texts.i_th (a_i))
			l_ed.set_parent (Current)
			l_ed.set_on_change (agent editor_changed)
			l_ed.set_caret (l_ed.text.count)
			l_ed.set_marks (marks_list.i_th (a_i))
			l_ed.set_legend (legend)
			l_ed.mark_painter.set_floors (mark_painter.min_mark_size, mark_painter.min_effect_size, mark_painter.min_badge_size)
			l_ed.set_focused (True)
			editor := l_ed
			editing_index := a_i
			edit_backup := texts.i_th (a_i).twin
			edit_marks_backup := marks_list.i_th (a_i).duplicate
			select_only (a_i)
		ensure
			editing: is_editing and editing_index = a_i
			editor_up: attached editor as al_ed and then al_ed.text.same_string (text_of (a_i))
			caret_at_the_end: attached editor as al_ed2 and then al_ed2.caret = al_ed2.text.count
			selected: selected_index = a_i
		end

	end_edit (a_commit: BOOLEAN)
			-- Take the editor down: keep its text and tell the host
			-- (`a_commit'), or restore what stood before.
		require
			editing: is_editing
		local
			i: INTEGER
		do
			i := editing_index
			if a_commit then
				if attached on_edit_commit as al_c then
					al_c.call (i, texts.i_th (i).twin)
				end
			else
				texts.put_i_th (edit_backup.twin, i)
				marks_list.i_th (i).copy_from (edit_marks_backup)
				revisions.put_i_th (revisions.i_th (i) + 1, i)
			end
			drop_editor
		ensure
			done: not is_editing
			restored: not a_commit implies text_of (i_before (old editing_index)).same_string (old edit_backup)
		end

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			create Result.make (1)
			if attached editor as al_ed then
				Result.extend (al_ed)
			end
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

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	cursor_kind: INTEGER
			-- The I-beam over the editor, the arrow elsewhere.
		do
			if is_editing and then attached editor as al_ed and then al_ed.contains (hover_px, hover_py) then
				Result := 1
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := viewport_height
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
				ty := y - scroll_y + laid_tops.i_th (i) + item_pad + bands_above.i_th (i)
				al_ed.set_bounds (text_x - al_ed.Pad_x, ty - al_ed.Pad_y,
					text_width + 2.0 * al_ed.Pad_x,
					laid_heights.i_th (i) - 2.0 * item_pad - bands_above.i_th (i) - bands_below.i_th (i)
						+ 2.0 * al_ed.Pad_y)
				al_ed.arrange (a_p)
			end
		end

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				if a_px < x + width - Bar_w and then attached editor as al_ed
					and then al_ed.contains (a_px, a_py)
				then
					Result := al_ed
				else
					Result := Current
				end
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- Only the paragraphs inside the viewport: wash, ring,
			-- gutter, bands, text (or the editor over it), then the bar.
		local
			t: SW_THEME
			i: INTEGER
			inner_w, top, bx, by, bw, bh, ty, th, track_h, thumb_h, thumb_y: REAL_64
			l_wash: NATURAL_32
		do
			t := a_p.theme
			measure (a_p)
			scroll_y := scroll_y.min (max_scroll)
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.push_clip (x + 1.0, y + 1.0, width - 2.0, height - 2.0)
			inner_w := width - Bar_w - 4.0
			if count > 0 then
				from
					i := first_visible
				until
					i > last_visible or i = 0
				loop
					top := y - scroll_y + laid_tops.i_th (i)
					bx := x
					by := top
					bw := inner_w
					bh := laid_heights.i_th (i)
					l_wash := 0
					if attached wash_of as al_w then
						l_wash := al_w.item ([i])
					end
					if l_wash /= 0 then
						a_p.set_color (l_wash)
						a_p.rrect_fill (bx, by, bw, bh, t.radius)
					elseif selected_flags.i_th (i) then
						a_p.set_color (t.wash_accent)
						a_p.rrect_fill (bx, by, bw, bh, t.radius)
					end
					if i = selected_index then
						a_p.set_color (t.accent)
						a_p.set_line_width (2.0)
						a_p.rrect_stroke (bx + 1.0, by + 1.0, bw - 2.0, bh - 2.0, t.radius)
						a_p.set_line_width (1.0)
					elseif selected_flags.i_th (i) then
						a_p.set_color (t.accent)
						a_p.rrect_stroke (bx + 0.5, by + 0.5, bw - 1.0, bh - 1.0, t.radius)
					end
					if attached gutter_renderer as al_g and then gutter_width > 0.0 then
						al_g.call (a_p, i, bx, by, gutter_width, bh)
					end
					ty := by + item_pad
					if bands_above.i_th (i) > 0.0 then
						if attached band_renderer as al_b then
							al_b.call (a_p, i, True, text_x, ty, text_width, bands_above.i_th (i))
						end
						ty := ty + bands_above.i_th (i)
					end
					th := bh - 2.0 * item_pad - bands_above.i_th (i) - bands_below.i_th (i)
					if i = editing_index and then attached editor as al_ed then
						al_ed.draw (a_p)
					else
						if marks_list.i_th (i).text_count /= geometries.i_th (i).count then
							marks_list.i_th (i).clamp_to (geometries.i_th (i).count)
						end
						mark_painter.paint_under (a_p, geometries.i_th (i), marks_list.i_th (i), legend, text_x, ty)
						a_p.set_color (t.ink)
						draw_item_text (i, a_p, 0.0, 0.0, text_x, ty)
						mark_painter.paint_over (a_p, geometries.i_th (i), marks_list.i_th (i), legend, text_x, ty,
							t.size_body * t.text_scale, agent draw_item_text (i, ?, ?, ?, text_x, ty))
						ty := by + item_pad + bands_above.i_th (i) + th
					end
					if bands_below.i_th (i) > 0.0 and then attached band_renderer as al_b2 then
						al_b2.call (a_p, i, False, text_x, ty, text_width, bands_below.i_th (i))
					end
					i := i + 1
				end
			end
			a_p.pop_clip
			if max_scroll > 0.0 then
				track_h := height - 4.0
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + width - Bar_w, y + 2.0, Bar_w - 2.0, track_h, 4.0)
				thumb_h := (height / content_height * track_h).max (24.0)
				thumb_y := y + 2.0 + (scroll_y / max_scroll) * (track_h - thumb_h)
				if shows_hover and then hover_px >= x + width - Bar_w then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_fill (x + width - Bar_w + 1.5, thumb_y, Bar_w - 5.0, thumb_h, 3.0)
			end
		end

feature -- Input

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			scroll_to (scroll_y - a_delta / 120.0 * Wheel_step)
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
			if a_px >= x + width - Bar_w and max_scroll > 0.0 then
				scroll_to ((a_py - y) / height * max_scroll)
				dragging_bar := True
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
			if i > 0 and a_px < x + width - Bar_w then
				select_only (i)
				if attached on_activate as al_a then
					al_a.call (i)
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if dragging_bar and then max_scroll > 0.0 then
				scroll_to ((a_py - y) / height * max_scroll)
			end
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- While editing, the editor's; otherwise arrows, PgUp/PgDn,
			-- Home/End move the anchor and keep it in view.
		local
			target: INTEGER
		do
			if is_editing and then attached editor as al_ed then
				al_ed.handle_key (a_vk, a_shift)
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
			if is_editing and then attached editor as al_ed then
				if a_code = 27 then
					end_edit (False)
				else
					al_ed.handle_char (a_code)
				end
			end
		end

feature {NONE} -- Measurement

	Wheel_step: REAL_64 = 60.0

	texts: ARRAYED_LIST [STRING_32]
	revisions: ARRAYED_LIST [INTEGER]
			-- Per paragraph, bumped on every text or band change.
	laid_revisions: ARRAYED_LIST [INTEGER]
			-- Per paragraph, the revision its measurement is for.
	laid_heights: ARRAYED_LIST [REAL_64]
	laid_tops: ARRAYED_LIST [REAL_64]
	bands_above: ARRAYED_LIST [REAL_64]
	bands_below: ARRAYED_LIST [REAL_64]
	geometries: ARRAYED_LIST [SW_TEXT_GEOMETRY]
			-- Per paragraph, where its characters paint (either engine).
	marks_list: ARRAYED_LIST [SW_MARKED_TEXT]
			-- Per paragraph, the data behind it.
	edit_marks_backup: SW_MARKED_TEXT
			-- The edited paragraph's marks as they stood at `begin_edit'.
	selected_flags: ARRAYED_LIST [BOOLEAN]
	laid_width: REAL_64
	laid_size: INTEGER
	laid_shaped: BOOLEAN
	dragging_bar: BOOLEAN
	edit_backup: STRING_32
			-- The edited paragraph's text as it stood at `begin_edit'.

	drop_measurements
			-- Every paragraph measures again on the next frame.
		do
			laid_revisions.wipe_out
			laid_heights.wipe_out
			laid_tops.wipe_out
			geometries.wipe_out
		ensure
			dropped: not is_laid_out or count = 0
		end

	measure (a_p: SW_PAINTER)
			-- Every paragraph's height at the current width, size and
			-- engine - re-measuring only what changed - then the tops.
		local
			i, px: INTEGER
			tw, top, th: REAL_64
			want_shaped, all_again: BOOLEAN
		do
			tw := text_width
			want_shaped := a_p.has_shaping
			px := (a_p.theme.size_body * a_p.theme.text_scale).rounded.max (1)
			all_again := tw /= laid_width or px /= laid_size or want_shaped /= laid_shaped
				or laid_heights.count /= count
			if all_again then
				drop_measurements
				laid_width := tw
				laid_size := px
				laid_shaped := want_shaped
				from
					i := 1
				until
					i > count
				loop
					laid_revisions.extend (-1)
					laid_heights.extend (1.0)
					laid_tops.extend (0.0)
					geometries.extend (create {SW_TEXT_GEOMETRY}.make)
					i := i + 1
				end
			end
			top := 0.0
			from
				i := 1
			until
				i > count
			loop
				if laid_revisions.i_th (i) /= revisions.i_th (i) or i = editing_index then
					if i = editing_index and then attached editor as al_ed then
						th := al_ed.preferred_height (a_p, tw + 2.0 * al_ed.Pad_x) - 2.0 * al_ed.Pad_y
					elseif want_shaped and then attached a_p.shaping as al_kit then
						th := shaped_height (al_kit, i, tw.floor.max (16), px)
					else
						th := toy_height (a_p, i, tw)
					end
					laid_heights.put_i_th ((2.0 * item_pad + bands_above.i_th (i) + th + bands_below.i_th (i)).max (1.0), i)
					laid_revisions.put_i_th (revisions.i_th (i), i)
				end
				laid_tops.put_i_th (top, i)
				top := top + laid_heights.i_th (i) + item_gap
				i := i + 1
			end
		ensure
			laid_out: is_laid_out
			engine_recorded: laid_shaped = a_p.has_shaping
		end

	shaped_height (a_kit: SW_SHAPING; a_i: INTEGER; a_wpx, a_px: INTEGER): REAL_64
			-- Lay paragraph `a_i' out through the kit into its geometry
			-- and answer the stacked height.
		require
			in_range: a_i >= 1 and a_i <= count
			positive: a_wpx > 0 and a_px > 0
		do
			geometries.i_th (a_i).build_shaped (a_kit, texts.i_th (a_i), a_wpx, a_px, False)
			Result := geometries.i_th (a_i).content_height
		ensure
			non_negative: Result >= 0.0
		end

	toy_height (a_p: SW_PAINTER; a_i: INTEGER; a_w: REAL_64): REAL_64
			-- Greedy word wrap on cairo's advances into the geometry.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
			geometries.i_th (a_i).build_toy (a_p, texts.i_th (a_i), a_w, False, False)
			Result := geometries.i_th (a_i).content_height.max (a_p.theme.scaled_line_height)
		ensure
			positive: Result > 0.0
		end

	draw_item_text (a_i: INTEGER; a_p: SW_PAINTER; a_dx, a_dy, a_ox, a_oy: REAL_64)
			-- Paragraph `a_i''s text shifted by (a_dx, a_dy) from its
			-- origin (a_ox, a_oy), in the painter's current colour.
		require
			in_range: a_i >= 1 and a_i <= count
		local
			g: SW_TEXT_GEOMETRY
			k, ln: INTEGER
			ox, oy: REAL_64
		do
			g := geometries.i_th (a_i)
			ox := a_ox + a_dx
			oy := a_oy + a_dy
			if g.is_shaped then
				from
					k := 1
				until
					k > g.layouts.count
				loop
					a_p.draw_shaped_layout (g.layouts.i_th (k), ox, oy + g.para_tops.i_th (k))
					k := k + 1
				end
			else
				a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
				from
					k := 1
				until
					k > g.count
				loop
					if not g.is_break (k) then
						ln := g.line_of (k)
						a_p.text (ox + g.x_of (k), oy + g.top_of_line (ln) + g.ascent_of_line (ln),
							texts.i_th (a_i).substring (k, k))
					end
					k := k + 1
				end
			end
		end

	pieces_of (a_text: STRING_32): ARRAYED_LIST [STRING_32]
			-- `a_text' cut at every LF; an empty text is one empty piece.
		local
			i, start: INTEGER
		do
			create Result.make (2)
			start := 1
			from
				i := 1
			until
				i > a_text.count
			loop
				if a_text.item (i) = '%N' then
					Result.extend (a_text.substring (start, i - 1))
					start := i + 1
				end
				i := i + 1
			end
			Result.extend (a_text.substring (start, a_text.count))
		ensure
			at_least_one: not Result.is_empty
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

	i_before (a_i: INTEGER): INTEGER
			-- Identity, named for a postcondition that must read an
			-- index captured before the editor came down.
		do
			Result := a_i
		end

	editor_changed
			-- The editor typed: the paragraph follows, its height
			-- reflows, and the host hears.
		local
			i: INTEGER
		do
			if is_editing and then attached editor as al_ed then
				i := editing_index
				texts.put_i_th (al_ed.text.twin, i)
				revisions.put_i_th (revisions.i_th (i) + 1, i)
				if attached on_edit_change as al_c then
					al_c.call (i, al_ed.text.twin)
				end
			end
		end

	drop_editor
			-- Take the editor down without judging its text.
		do
			if attached editor as al_ed then
				al_ed.set_focused (False)
				al_ed.set_parent (Void)
			end
			editor := Void
			editing_index := 0
		ensure
			down: editor = Void and editing_index = 0
		end

invariant
	texts_attached: texts /= Void
	parallel_model: revisions.count = count and bands_above.count = count
		and bands_below.count = count and selected_flags.count = count
		and marks_list.count = count
	parallel_measurements: laid_heights.count = laid_tops.count
		and laid_revisions.count = laid_heights.count
		and geometries.count = laid_heights.count
	measurements_never_outrun: laid_heights.count <= count
	anchor_in_range: selected_index >= 0 and selected_index <= count
	editing_in_range: editing_index >= 0 and editing_index <= count
	editor_iff_editing: (editor /= Void) = (editing_index > 0)
	scroll_non_negative: scroll_y >= 0.0
	metrics_non_negative: gutter_width >= 0.0 and item_gap >= 0.0 and item_pad >= 0.0
	viewport_positive: viewport_height > 0.0

end
