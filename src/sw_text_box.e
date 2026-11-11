note
	description: "[
		Editable text with the full engine: measured word wrap, a caret
		placed by click or arrows, and a real selection model - drag,
		double-click word, shift with arrows, home and end. Harvested
		from the narrate editor, where it was proven against live and
		synthetic input.

		Single-line mode simply refuses to wrap and ignores line keys.
		The change agent fires after every edit, so the host owns what
		an edit MEANS (marking a block dirty, validating a number);
		this widget only owns what an edit IS.

		GEOMETRY (0.8.0). Where every character paints - on cairo's toy
		path or through the window's shaping kit, bidi and all - is
		SW_TEXT_GEOMETRY's, rebuilt when the text, the width, the size
		or the engine changes. The caret, the selection, the squiggles
		and the highlights all read it.

		HIGHLIGHTS (0.8.0). `marks' is the data behind the text - the
		spans a host lays over it with a REASON each (SW_MARKED_TEXT),
		and `legend' says what a reason looks like (SW_MARK_LEGEND).
		Every edit path here tells `marks' what moved, so a span
		follows its words through typing, deleting, pasting, undo and
		redo; SW_MARK_PAINTER paints washes under the text and the
		effects and boxes over it. A host that wants the marks to
		outlive `set_text' keeps its own reference through `set_marks'.
	]"

class
	SW_TEXT_BOX

inherit
	SW_WIDGET
		redefine
			accepts_focus, preferred_width, handle_click, handle_double_click,
			handle_triple_click, handle_drag, handle_char, handle_key,
			context_menu, accepts_pebble, receive_pebble, cursor_kind,
			accessible_role, accessible_value, set_focused, takes_typing,
			can_edit, perform_edit, shows_style, set_style
		end

	SW_CLUSTER_MATH

	SW_MARK_HOST

	SW_COPYING

create
	make, make_single_line, make_wrapping_line, make_password

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL)
		do
			create text.make_from_string_general (a_text)
			create extra_ranges.make (4)
			create spell_ranges.make (8)
			is_spellcheck_enabled := True
			spell_dirty := True
			create geometry.make
			create marks.make (text.count)
			layout_width := -1.0
			text_alignment := {SHAPING_CONSTANTS}.Align_left
			laid_alignment := text_alignment
		ensure
			text_kept: text.same_string_general (a_text)
			flush_left: text_alignment = {SHAPING_CONSTANTS}.Align_left
		end

	make_single_line (a_text: READABLE_STRING_GENERAL)
		do
			make (a_text)
			is_single_line := True
		ensure
			single: is_single_line
		end

	make_wrapping_line (a_text: READABLE_STRING_GENERAL)
			-- One paragraph that wraps on screen and grows a line at a time (0.52.0: a reason, an
			-- answer): a field, so focus selects it all, but never a line break - Enter adds none and
			-- pasted breaks become spaces (Larry, 2026-11-01: typing on, the words ran out of sight).
		do
			make (a_text)
			is_one_paragraph := True
			is_focus_select_requested := True
		ensure
			one_paragraph: is_one_paragraph
			wraps: not is_single_line
			a_field: selects_all_on_focus
		end

	make_password (a_text: READABLE_STRING_GENERAL)
			-- One masked line: bullets on screen, no copy to the
			-- clipboard, no spellcheck peeking at the secret.
		do
			make_single_line (a_text)
			is_masked := True
		ensure
			single: is_single_line
			masked: is_masked
		end

feature -- Access

	text: STRING_32

	text_size: REAL_64
			-- The size the text is set at, before the theme's scale; 0: the theme's body size.

	text_styles: detachable SHAPING_STYLES
			-- Stretches set bold, italic, smaller or in another ink, in real glyphs, on the
			-- shaped path (rich text); Void: plain. Cut to the text on every layout.

	caret: INTEGER
			-- Insertion position, 0 .. text.count.

	sel_anchor: INTEGER
			-- Other end of the primary selection; equal to caret when empty.

	spell_ranges: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- Misspelled ranges from the inbox checker; refreshed
			-- lazily after edits.

	has_clear_button: BOOLEAN
			-- Draw a clear X at the right edge while there is text?
			-- Off by default; masked boxes never show it (the eye
			-- owns that slot).

	on_clear_request: detachable PROCEDURE
			-- When attached, the X asks the HOST instead of clearing:
			-- the host may confirm with a dialog, then call
			-- `clear_text' itself. When Void, the X clears directly.

	is_invalid: BOOLEAN
			-- Host-declared invalidity: the box wears the danger wash
			-- and a danger border until cleared. Validation is the
			-- host's judgment; the box only shows it.

	is_masked: BOOLEAN
			-- Draw bullets instead of characters? Masked boxes also
			-- refuse clipboard copy and skip spellcheck.

	is_revealed: BOOLEAN
			-- Eye toggled open? A view change only: copy stays denied
			-- and spellcheck still never sees the text.

	is_hiding: BOOLEAN
			-- Are characters drawn as bullets right now?
		do
			Result := is_masked and not is_revealed
		end

	is_spellcheck_enabled: BOOLEAN

	extra_ranges: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- Additional selected ranges beyond the primary one - the
			-- fruit of Invert Selection. Each covers characters
			-- lo+1 .. hi; kept sorted, disjoint and non-empty.

	is_one_paragraph: BOOLEAN
			-- Does it wrap but never break a line (`make_wrapping_line')?

	is_single_line: BOOLEAN

	is_just_focused: BOOLEAN
			-- Did focus just arrive, so the click that brought it keeps everything selected?

	is_focus_select_requested, is_focus_select_declined: BOOLEAN
			-- `set_selects_all_on_focus' choices over the single-line default.

	is_read_only: BOOLEAN

	takes_typing: BOOLEAN
			-- An editable box keeps Ctrl+Z and Ctrl+Y for its own undo and
			-- redo (0.56.0).
		do
			Result := not is_read_only
		end

	on_focus_lost: detachable PROCEDURE
			-- Told when the box loses the keyboard focus (editing ended; simple_gui 1p).

	on_reveal: detachable PROCEDURE [BOOLEAN]
			-- Told when the user clicks the eye, with whether the text now shows.

	set_on_focus_lost (an_action: detachable PROCEDURE)
		do
			on_focus_lost := an_action
		ensure
			set: on_focus_lost = an_action
		end

	set_on_reveal (an_action: detachable PROCEDURE [BOOLEAN])
		do
			on_reveal := an_action
		ensure
			set: on_reveal = an_action
		end

	set_revealed (a_on: BOOLEAN)
			-- Show or hide a masked box's text, as the program: nothing is told.
		require
			masked_box: is_masked
		do
			if is_revealed /= a_on then
				toggle_reveal
			end
		ensure
			set: is_revealed = a_on
		end

	on_change: detachable PROCEDURE
			-- Fired after every edit.

	on_activate: detachable PROCEDURE
			-- Fired when Enter is pressed in a single-line or one-paragraph box (W5, for
			-- simple_gui's activate event). Enter inserts nothing there.

	placeholder: STRING_32
			-- A hint drawn in the muted ink while the box is empty (never the accessible name).
		attribute
			create Result.make_empty
		end

feature -- Status

	has_selection: BOOLEAN
		do
			Result := sel_anchor /= caret or else not extra_ranges.is_empty
		end

	is_char_selected (a_i: INTEGER): BOOLEAN
			-- Is character `a_i' inside any selected range?
		require
			in_text: a_i >= 1 and a_i <= text.count
		do
			Result := a_i > sel_anchor.min (caret) and a_i <= sel_anchor.max (caret)
			across
				extra_ranges as r
			loop
				Result := Result or else (a_i > r.lo and a_i <= r.hi)
			end
		end

	selected_text: STRING_32
			-- All selected pieces in text order; disjoint pieces join
			-- with a newline, the multi-select copy convention.
		local
			pieces: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
		do
			create Result.make_empty
			pieces := all_ranges
			across
				pieces as r
			loop
				if not Result.is_empty then
					Result.append_character ('%N')
				end
				Result.append (text.substring (r.lo + 1, r.hi))
			end
		ensure
			empty_without_selection: not has_selection implies Result.is_empty
		end

feature -- Highlights

	marks: SW_MARKED_TEXT
			-- The data behind the text: spans with reasons, following
			-- every edit made here.

	set_marks (a_marks: SW_MARKED_TEXT)
			-- Share `a_marks' (a host keeping the data behind several
			-- boxes, or a paragraph list seating an editor); it is
			-- clamped to the text on the spot.
		do
			marks := a_marks
			marks.clamp_to (text.count)
		ensure
			shared: marks = a_marks
			fits: marks.text_count = text.count
		end

feature -- Undo and redo (the most-missed feature, landed)

	can_undo: BOOLEAN
		do
			Result := not undo_stack.is_empty
		end

	can_redo: BOOLEAN
		do
			Result := not redo_stack.is_empty
		end

	undo
			-- Unwind the last edit RUN (typing coalesces; deletes
			-- coalesce; blocks - paste, cut, drop - stand alone).
		require
			something: can_undo
		local
			snap: TUPLE [snapshot: STRING_32; snap_caret, snap_anchor: INTEGER; snap_marks: STRING_32]
		do
			redo_stack.extend ([text.twin, caret, sel_anchor, marks.code])
			snap := undo_stack.last
			undo_stack.finish
			undo_stack.remove
			text := snap.snapshot.twin
			marks.copy_from (create {SW_MARKED_TEXT}.make_from_code (text.count, snap.snap_marks))
			caret := snap.snap_caret.min (text.count)
			sel_anchor := snap.snap_anchor.min (text.count)
			last_edit_kind := 0
			changed
		ensure
			redoable: can_redo
		end

	redo
		require
			something: can_redo
		local
			snap: TUPLE [snapshot: STRING_32; snap_caret, snap_anchor: INTEGER; snap_marks: STRING_32]
		do
			undo_stack.extend ([text.twin, caret, sel_anchor, marks.code])
			snap := redo_stack.last
			redo_stack.finish
			redo_stack.remove
			text := snap.snapshot.twin
			marks.copy_from (create {SW_MARKED_TEXT}.make_from_code (text.count, snap.snap_marks))
			caret := snap.snap_caret.min (text.count)
			sel_anchor := snap.snap_anchor.min (text.count)
			last_edit_kind := 0
			changed
		ensure
			undoable: can_undo
		end

feature {NONE} -- Undo machinery

	Kind_typing: INTEGER = 1
	Kind_deleting: INTEGER = 2
	Kind_block: INTEGER = 3

	undo_stack: ARRAYED_LIST [TUPLE [snapshot: STRING_32; snap_caret, snap_anchor: INTEGER; snap_marks: STRING_32]]
		attribute
			create Result.make (8)
		end

	redo_stack: ARRAYED_LIST [TUPLE [snapshot: STRING_32; snap_caret, snap_anchor: INTEGER; snap_marks: STRING_32]]
		attribute
			create Result.make (4)
		end

	last_edit_kind: INTEGER

	remember (a_kind: INTEGER)
			-- Snapshot before a mutation; consecutive edits of the
			-- same kind coalesce into one step, blocks never do.
		do
			if a_kind = Kind_block or a_kind /= last_edit_kind then
				undo_stack.extend ([text.twin, caret, sel_anchor, marks.code])
				redo_stack.wipe_out
			end
			last_edit_kind := a_kind
		end

feature -- Clipboard and selection commands

	set_caret (a_offset: INTEGER)
			-- Put the caret at `a_offset' with nothing selected - the
			-- host seating a fresh editor at the END of its text, say.
		require
			in_range: a_offset >= 0 and a_offset <= text.count
		do
			caret := a_offset
			sel_anchor := a_offset
			extra_ranges.wipe_out
		ensure
			placed: caret = a_offset
			collapsed: not has_selection
		end

	selects_all_on_focus: BOOLEAN
			-- Does gaining focus select every character, so typing replaces the text? Single-line boxes
			-- (fields, cell editors) by default; multi-line ones place the caret, so one keystroke
			-- never replaces a whole document (Larry, 2026-10-26).
		do
			Result := (is_single_line and not is_focus_select_declined) or is_focus_select_requested
		end

	set_selects_all_on_focus (a_on: BOOLEAN)
			-- Choose `selects_all_on_focus' for this box.
		do
			is_focus_select_requested := a_on
			is_focus_select_declined := not a_on
		ensure
			set: selects_all_on_focus = a_on
		end

	set_focused (a_focused: BOOLEAN)
			-- Gaining focus selects everything when `selects_all_on_focus'; the click that brought the
			-- focus keeps it selected, and the next click places the caret (Larry: "clicking then
			-- again puts the edit-bar wherever the mousetip was in the text").
		do
			if a_focused and not is_focused and selects_all_on_focus then
				select_all
				is_just_focused := True
			elseif not a_focused then
				is_just_focused := False
			end
			if is_focused and not a_focused and then attached on_focus_lost as al_told then
				Precursor (a_focused)
				al_told.call (Void)
			else
				Precursor (a_focused)
			end
		end

	select_all
		do
			extra_ranges.wipe_out
			sel_anchor := 0
			caret := text.count
		ensure
			all_selected: text.count > 0 implies has_selection
		end

	select_none
			-- Collapse every selection to the caret.
		do
			sel_anchor := caret
			extra_ranges.wipe_out
		ensure
			collapsed: not has_selection
			caret_unmoved: caret = old caret
		end

	invert_selection
			-- Select exactly what was not selected; deselect the rest.
			-- May yield disjoint ranges - the primary becomes the last
			-- complement range, the others ride extra_ranges.
		local
			sel, comp: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			pos: INTEGER
			last_r: TUPLE [lo, hi: INTEGER]
		do
			sel := all_ranges
			create comp.make (sel.count + 1)
			pos := 0
			across
				sel as r
			loop
				if r.lo > pos then
					comp.extend ([pos, r.lo])
				end
				pos := r.hi
			end
			if pos < text.count then
				comp.extend ([pos, text.count])
			end
			extra_ranges.wipe_out
			if comp.is_empty then
				sel_anchor := caret
			else
				last_r := comp.last
				comp.finish
				comp.remove
				across
					comp as r
				loop
					extra_ranges.extend (r)
				end
				sel_anchor := last_r.lo
				caret := last_r.hi
			end
		ensure
			nothing_becomes_everything: (old all_ranges.is_empty and text.count > 0) implies
				(sel_anchor.min (caret) = 0 and sel_anchor.max (caret) = text.count)
		end

	copy_selection
			-- Masked boxes never surrender their text to the
			-- clipboard - copying from one is a silent no-op.
		do
			if has_selection and not is_masked then
				copy_text (selected_text)
			end
		end

	cut_selection
		do
			if not is_read_only and then has_selection then
				remember (Kind_block)
				copy_selection
				delete_selection
				changed
			end
		end

	paste_clipboard
		local
			clip: SW_CLIPBOARD
			s: STRING_32
		do
			if not is_read_only then
				create clip
				s := clip.text
				s.prune_all ('%R')
				if is_single_line or is_one_paragraph then
					s.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
				end
				if not s.is_empty then
					remember (Kind_block)
					if has_selection then
						delete_selection
					end
					text.insert_string (s, caret + 1)
					marks.text_inserted (caret, s.count)
					caret := caret + s.count
					sel_anchor := caret
					changed
				end
			end
		end

feature -- Edit commands (W8)

	can_edit (a_command: INTEGER): BOOLEAN
			-- Undo and redo when there is a step; cut when a selection can be removed; copy
			-- when one can be read (never from a masked box); paste when the box is writable
			-- and the clipboard holds text; select all when there is text.
		local
			l_clip: SW_CLIPBOARD
		do
			inspect a_command
			when Edit_undo then
				Result := not is_read_only and can_undo
			when Edit_redo then
				Result := not is_read_only and can_redo
			when Edit_cut then
				Result := not is_read_only and has_selection and not is_masked
			when Edit_copy then
				Result := has_selection and not is_masked
			when Edit_paste then
				if not is_read_only then
					create l_clip
					Result := l_clip.has_text
				end
			when Edit_select_all then
				Result := text.count > 0
			else
			end
		end

	perform_edit (a_command: INTEGER)
		do
			inspect a_command
			when Edit_undo then
				undo
			when Edit_redo then
				redo
			when Edit_cut then
				cut_selection
			when Edit_copy then
				copy_selection
			when Edit_paste then
				paste_clipboard
			when Edit_select_all then
				select_all
			else
			end
		end

feature -- Alignment (GW-02)

	text_alignment: INTEGER
			-- How lines sit in the box on the shaped path: a
			-- SHAPING_CONSTANTS Align_* code. Align_left (the default)
			-- is the box before GW-02; Align_start sets Hebrew flush
			-- right and English flush left, line by paragraph.

	effective_text_alignment: INTEGER
			-- `text_alignment' as drawn: left and right swap when this widget `mirrors_layout'
			-- (W4c; GTK mirrors a label's xalign the same way). Start and center are unchanged.
		do
			Result := text_alignment
			if mirrors_layout then
				if Result = {SHAPING_CONSTANTS}.Align_left then
					Result := {SHAPING_CONSTANTS}.Align_right
				elseif Result = {SHAPING_CONSTANTS}.Align_right then
					Result := {SHAPING_CONSTANTS}.Align_left
				end
			end
		end

	reads_right_to_left: BOOLEAN
			-- Does the text run right to left, by its first paragraph as laid out? Left and
			-- Right then move the caret visually, as GTK and AppKit do (W4c). A later paragraph
			-- of the other direction, or a run of the other direction inside a line, still
			-- moves logically: 0.2's limit (visual order needs the geometry's run order).
		do
			Result := is_laid_out and then geometry.is_shaped and then geometry.starts_right_to_left
		end

	set_text_alignment (a_alignment: INTEGER)
			-- Place lines by `a_alignment'; the next layout honors it,
			-- and the caret and selection follow the text.
		require
			alignment_valid: a_alignment >= {SHAPING_CONSTANTS}.Align_start
				and a_alignment <= {SHAPING_CONSTANTS}.Align_center
		do
			text_alignment := a_alignment
		ensure
			set: text_alignment = a_alignment
		end

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
			-- Swap the whole text. Every selection artifact of the old
			-- text dies with it - ranges into a vanished string are
			-- exactly the invariant breach DBC exists to forbid.
		do
			undo_stack.wipe_out
			redo_stack.wipe_out
			last_edit_kind := 0
			create text.make_from_string_general (a_text)
			marks.clear
			marks.clamp_to (text.count)
			caret := caret.min (text.count)
			sel_anchor := caret
			extra_ranges.wipe_out
			layout_width := -1.0
			spell_dirty := True
		ensure
			kept: text.same_string_general (a_text)
			caret_in_range: caret <= text.count
			no_stale_extras: extra_ranges.is_empty
		end

	set_text_size (a_size: REAL_64)
			-- Set the text at `a_size' (0: the theme's body size).
		require
			non_negative: a_size >= 0.0
		do
			text_size := a_size
			layout_width := -1.0
		ensure
			set: text_size = a_size
		end

	new_text_styles: SHAPING_STYLES
			-- A fresh, empty set of styles for `set_text_styles' (so a client names no
			-- shaping class of its own).
		do
			create Result.make
		ensure
			empty: Result.is_empty
		end

	set_text_styles (a_styles: detachable SHAPING_STYLES)
			-- Set stretches of the text by `a_styles' (Void: plain). A host that changes the
			-- object in place calls this again, so the text is laid out anew.
		do
			text_styles := a_styles
			layout_width := -1.0
		ensure
			set: text_styles = a_styles
		end

	set_on_activate (a_action: detachable PROCEDURE)
			-- Run `a_action' when Enter is pressed in a single-line or one-paragraph box.
		do
			on_activate := a_action
		ensure
			set: on_activate = a_action
		end

	set_placeholder (a_text: READABLE_STRING_GENERAL)
			-- Show `a_text' in the muted ink while the box is empty.
		do
			placeholder := a_text.to_string_32
		ensure
			set: placeholder.same_string_general (a_text)
		end

	set_on_change (a_action: PROCEDURE)
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

	set_read_only (a_ro: BOOLEAN)
		do
			is_read_only := a_ro
		end

	set_spellcheck (a_on: BOOLEAN)
		do
			is_spellcheck_enabled := a_on
			spell_dirty := True
		ensure
			set: is_spellcheck_enabled = a_on
		end

	set_clear_button (a_on: BOOLEAN)
		do
			has_clear_button := a_on
		ensure
			set: has_clear_button = a_on
		end

	with_clear_button: like Current
		do
			has_clear_button := True
			Result := Current
		ensure
			chained: Result = Current
			armed: has_clear_button
		end

	set_on_clear_request (a_action: PROCEDURE)
		do
			on_clear_request := a_action
		ensure
			set: on_clear_request = a_action
		end

	clear_text
			-- Empty the box as a user action: on_change fires.
		do
			set_text ("")
			changed
		ensure
			empty: text.is_empty
		end

	shows_clear: BOOLEAN
		do
			Result := has_clear_button and then not text.is_empty and then not is_masked
		end

	set_invalid (a_on: BOOLEAN)
		do
			is_invalid := a_on
		ensure
			set: is_invalid = a_on
		end

	set_masked (a_on: BOOLEAN)
		do
			is_masked := a_on
			layout_width := -1.0
			spell_dirty := True
		ensure
			set: is_masked = a_on
		end

	toggle_reveal
			-- Flip the eye: show or hide the secret on screen.
		require
			masked_box: is_masked
		do
			is_revealed := not is_revealed
			layout_width := -1.0
		ensure
			flipped: is_revealed = not (old is_revealed)
		end

feature -- Layout

	row_height (a_p: SW_PAINTER): REAL_64
			-- One text row at the current scale: the pitch this box
			-- actually stacks its lines at, so N plain lines are N rows.
			-- On the shaped path (`ensure_layout' with a kit, text not
			-- masked) that is the kit's `line_height' - one line of its
			-- primary face at the laid-out body pixel size, the pitch
			-- `SW_TEXT_GEOMETRY.build_shaped' stacks plain body lines and
			-- blank lines at (a line in another script's face, Hebrew in
			-- David say, is as tall as that face makes it). On the toy
			-- path it is the theme's `scaled_line_height',
			-- what `build_toy' uses. (Before 0.8.2 this answered the toy
			-- pitch on both paths: 60 px against 45 px shaped lines at 2x,
			-- so a host capping a box at five rows let it grow to 6.7.)
		do
			if a_p.has_shaping and not is_hiding and then attached a_p.shaping as al_kit then
				Result := geometry.floor_line_height (al_kit, body_pixels (a_p))
			else
				Result := a_p.theme.scaled_line_height
			end
		ensure
			positive: Result >= 0.0
		end

	row_baseline (a_p: SW_PAINTER): REAL_64
			-- Baseline offset inside one row, from MEASURED metrics.
		do
			use_font (a_p, face_role, body_size (a_p), False)
			Result := (row_height (a_p) - a_p.text_extent) / 2.0 + a_p.font_ascent
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The rows it needs plus the inside inset, never less than
			-- the minimum the font demands: `minimum_height'.
		do
			ensure_layout (a_p, wrap_width_in (a_width))
			Result := (content_height + 2.0 * Pad_y).max (minimum_height (a_p)) + style_inset_height
		ensure then
			at_least_the_minimum: Result >= minimum_height (a_p)
		end

	minimum_height (a_p: SW_PAINTER): REAL_64
			-- The least height this box may have: `SW_PAINTER.
			-- min_control_height' (the font's ascent + descent plus the
			-- theme's `control_inset' above and below) read under the BODY
			-- font (or `text_role''s), the role the box paints its text in. That query measures
			-- the painter's CURRENT font, so the body font is selected here
			-- first, as every other control selects its own. Before 0.8.2
			-- only a toy-path relayout happened to select it; on the shaped
			-- path one box, text and width measured 70, 75 or 80 px at 2x
			-- depending on what had been drawn before it.
		do
			use_font (a_p, face_role, body_size (a_p), False)
			Result := a_p.min_control_height
		ensure
			clears_the_insets: Result >= 2.0 * a_p.theme.control_inset
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
			-- The field; the highlight washes; the text through whichever
			-- engine laid it out; the squiggles; the highlight effects
			-- and boxes; the caret over everything; the clear X and the
			-- reveal eye. Three parts (`draw_field', `draw_content',
			-- `draw_adornments') so a descendant that scrolls its text
			-- can clip the middle one (simple_gui's code editor).
		do
			ensure_layout (a_p, wrap_width_in (width))
			draw_field (a_p)
			draw_content (a_p)
			draw_adornments (a_p)
		end

	draw_text_at (a_p: SW_PAINTER; a_dx, a_dy: REAL_64)
			-- The whole text shifted by (a_dx, a_dy) from its origin, in
			-- the painter's current color - what the highlight painter
			-- redraws through for its effects.
		do
			geometry.draw (a_p, text, is_hiding, text_left + a_dx, text_top + a_dy)
		end

feature {NONE} -- Drawing parts

	draw_field (a_p: SW_PAINTER)
			-- The field's fill and its frame: danger when invalid, the
			-- accent when focused, the outline otherwise. A style (SW_WIDGET_STYLE)
			-- gives the shadow, the fill, the corners and the resting border; invalid
			-- and focused still show over it.
		local
			t: SW_THEME
			r: REAL_64
		do
			t := a_p.theme
			r := field_radius (a_p)
			draw_style_shadow (a_p, r)
			if is_invalid then
				a_p.set_color (t.wash_danger)
			else
				a_p.set_color (styled_ground (t.surface))
			end
			a_p.rrect_fill (x, y, width, height, r)
			if is_invalid then
				a_p.set_color (t.danger)
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, r)
			elseif is_focused then
				a_p.set_color (t.accent)
				a_p.set_line_width (2.0)
				a_p.rrect_stroke (x + 1.0, y + 1.0, width - 2.0, height - 2.0, r)
				a_p.set_line_width (1.0)
			elseif style_border > 0.0 then
				draw_style_border (a_p, r)
			else
				if shows_hover then
					a_p.set_color (t.ink_muted)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, r)
			end
		end

	field_radius (a_p: SW_PAINTER): REAL_64
			-- The field's corners: the style's where it shows, else the theme's.
		do
			if attached shown_style ({SW_WIDGET_STYLE}.Part_radius) then
				Result := style_radius
			else
				Result := a_p.theme.radius
			end
		end

	draw_content (a_p: SW_PAINTER)
			-- Everything that moves with the text, from the origin
			-- (`text_left', `text_top'): the hint, the highlight washes,
			-- the selection and the text, the squiggles, the highlight
			-- effects and boxes, the caret over everything.
		require
			laid_out: is_laid_out
		local
			t: SW_THEME
			i, n, ln: INTEGER
			gx, gy, gw, cx, cy, asc, ext, ox, oy, px: REAL_64
			seln: BOOLEAN
		do
			t := a_p.theme
			use_font (a_p, face_role, body_size (a_p), False)
			asc := a_p.font_ascent
			ext := a_p.text_extent
			ox := text_left
			oy := text_top
			px := body_size (a_p) * t.text_scale
			n := text.count
				-- Password boxes show their hint too: it is no secret (GTK and AppKit agree).
			if n = 0 and then not placeholder.is_empty then
				if text_role = 0 and then a_p.has_shaping and then not is_hiding then
						-- the face typed text is shaped in (the kit leads with the UI face)
					use_font (a_p, {SW_PAINTER}.Role_ui, body_size (a_p), False)
				end
				a_p.set_color (styled_placeholder (t.ink_muted))
				if effective_text_alignment = {SHAPING_CONSTANTS}.Align_right then
						-- W4c: the hint sits where typing starts.
					a_p.text (ox + wrap_width_in (width) - a_p.advance (placeholder), oy + asc, placeholder)
				else
					a_p.text (ox, oy + asc, placeholder)
				end
			end
			if marks.text_count /= n then
					-- a host that wrote `text' directly: never a crash
				marks.clamp_to (n)
			end
			if not is_hiding then
				mark_painter.paint_under (a_p, geometry, marks, legend, ox, oy)
			end
			if geometry.is_shaped then
					-- the selection is a wash UNDER the glyphs on this path:
					-- a shaped run paints as one stroke and cannot be
					-- recoloured a character at a time
				if is_focused and then has_selection then
					a_p.set_color (styled_selection (t.wash_accent))
					from
						i := 1
					until
						i > n
					loop
						if is_char_selected (i) and then geometry.width_of (i) > 0.0 then
							ln := geometry.line_of (i)
							a_p.fill_rect (ox + geometry.x_of (i), oy + geometry.top_of_line (ln),
								geometry.width_of (i), geometry.height_of_line (ln))
						end
						i := i + 1
					end
				end
				a_p.set_color (styled_ink (t.ink))
				draw_text_at (a_p, 0.0, 0.0)
			else
				from
					i := 1
				until
					i > n
				loop
					ln := geometry.line_of (i)
					gx := ox + geometry.x_of (i)
					gy := oy + geometry.top_of_line (ln) + geometry.ascent_of_line (ln)
					gw := geometry.width_of (i)
					seln := is_focused and then has_selection and then is_char_selected (i)
					if seln then
						a_p.set_color (styled_selection (t.accent))
						a_p.fill_rect (gx - 1.0, gy - asc, gw + 2.0, ext + 2.0)
					end
					use_font (a_p, face_role, body_size (a_p), False)
					if seln and then not attached shown_style ({SW_WIDGET_STYLE}.Part_selection) then
						a_p.set_color (t.surface)
					else
							-- over a selection color of the style's the text keeps its ink
						a_p.set_color (styled_ink (t.ink))
					end
					if is_hiding or else text.item (i) /= '%T' then
							-- a tab paints nothing: its slot spans to the stop
						a_p.text (gx, gy, glyph (i))
					end
					i := i + 1
				end
			end
			refresh_spelling
			across
				spell_ranges as sr
			loop
				from
					i := sr.lo + 1
				until
					i > sr.hi or i > n
				loop
					ln := geometry.line_of (i)
					gx := ox + geometry.x_of (i)
					gy := oy + geometry.top_of_line (ln) + geometry.ascent_of_line (ln)
					a_p.set_color (t.danger)
					a_p.fill_rect (gx, gy + 3.5, geometry.width_of (i) + 1.0, 1.6)
					i := i + 1
				end
			end
			if not is_hiding then
				mark_painter.paint_over (a_p, geometry, marks, legend, ox, oy, px, agent draw_text_at)
			end
			if is_focused then
				ln := geometry.line_at_offset (caret)
				cx := ox + geometry.x_at_offset (caret)
				cy := oy + geometry.top_of_line (ln)
				a_p.set_color (t.danger)
				a_p.fill_rect (cx, cy, 2.0, geometry.height_of_line (ln))
			end
		end

	draw_adornments (a_p: SW_PAINTER)
			-- What sits over the field's right edge and does not move with
			-- the text: the clear X and the reveal eye.
		local
			t: SW_THEME
			cx, cy: REAL_64
		do
			t := a_p.theme
			if shows_clear then
					-- the clear X: muted at rest, danger under the pointer
				cx := x + width - 17.0
				cy := y + height / 2.0
				if shows_hover and then hover_px >= x + width - Eye_zone then
					a_p.set_color (t.danger)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.line (cx - 5.0, cy - 5.0, cx + 5.0, cy + 5.0, 1.7)
				a_p.line (cx - 5.0, cy + 5.0, cx + 5.0, cy - 5.0, 1.7)
			end
			if is_masked then
					-- the reveal eye: almond, iris, and a slash while open
				cx := x + width - 19.0
				cy := y + height / 2.0
				if is_revealed or shows_hover then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.rrect_stroke (cx - 8.0, cy - 4.5, 16.0, 9.0, 4.5)
				a_p.rrect_fill (cx - 2.5, cy - 2.5, 5.0, 5.0, 2.5)
				if is_revealed then
					a_p.line (cx - 8.0, cy + 6.0, cx + 8.0, cy - 6.0, 1.6)
				end
			end
		end

feature -- Input

	cursor_kind: INTEGER
			-- The I-beam: this is a text surface.
		do
			Result := 1
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- A real field's presence, not the content's length: a
			-- long path must not blow the row apart. Growers stretch
			-- past this; nothing shrinks below it. 240 unless the host
			-- asked for another (`set_preferred_text_width').
		do
			if preferred_text_width > 0.0 then
				Result := preferred_text_width
			else
				Result := 240.0
			end
		end

	preferred_text_width: REAL_64
			-- The width the host asked of this field; 0: the default 240.

	set_preferred_text_width (a_width: REAL_64)
			-- Ask `a_width' of a row (a short word field beside others).
		require
			positive: a_width > 0.0
		do
			preferred_text_width := a_width
		ensure
			set: preferred_text_width = a_width
		end

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- Click places the caret; Shift+Click keeps the anchor and
			-- selects everything between it and the click point. The click
			-- that brought focus keeps everything selected (`selects_all_on_focus').
		do
			Result := placed_click (a_px, a_py)
			if is_just_focused then
				select_all
				is_just_focused := False
			end
		end

	placed_click (a_px, a_py: REAL_64): BOOLEAN
			-- The click's own work: the eye, the clear button, or the caret.
		local
			keys: SW_KEYS
		do
			if is_masked and then a_px >= x + width - Eye_zone then
				toggle_reveal
				if attached on_reveal as al_told then
					al_told.call ([is_revealed])
				end
			elseif shows_clear and then a_px >= x + width - Eye_zone then
				if attached on_clear_request as cr then
					cr.call
				else
					clear_text
				end
			else
				create keys
				caret := offset_at (a_px, a_py)
				if not keys.shift_down then
					sel_anchor := caret
					extra_ranges.wipe_out
				end
			end
			Result := True
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- Select the word under the point.
		local
			c, lo, hi, n: INTEGER
		do
			Result := True
			n := text.count
			if n > 0 then
				c := offset_at (a_px, a_py)
				lo := c.max (1).min (n)
					-- on whitespace, snap to the nearer word instead of
					-- swallowing both neighbors
				if text.item (lo) = ' ' and then lo < n and then text.item (lo + 1) /= ' ' then
					lo := lo + 1
				end
				hi := lo
				from
				until
					lo <= 1 or else text.item (lo - 1) = ' '
				loop
					lo := lo - 1
				end
				from
				until
					hi >= n or else text.item (hi + 1) = ' '
				loop
					hi := hi + 1
				end
				sel_anchor := lo - 1
				caret := hi
			end
		end

	handle_triple_click (a_px, a_py: REAL_64): BOOLEAN
			-- Triple click: the whole text, the editor convention.
		do
			select_all
			Result := True
		ensure then
			all_selected: text.count > 0 implies has_selection
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			caret := offset_at (a_px, a_py)
		end

	handle_char (a_code: INTEGER)
		do
			if a_code = 27 then -- Escape
				select_none
			elseif a_code = 1 then -- Ctrl+A
				select_all
			elseif a_code = 3 then -- Ctrl+C
				copy_selection
			elseif a_code = 24 then -- Ctrl+X
				cut_selection
			elseif a_code = 22 then -- Ctrl+V
				paste_clipboard
			elseif a_code = 26 then -- Ctrl+Z
				if not is_read_only and then can_undo then
					undo
				end
			elseif a_code = 25 then -- Ctrl+Y
				if not is_read_only and then can_redo then
					redo
				end
			elseif not is_read_only then
				if a_code = 8 then
					if has_selection or caret > 0 then
						remember (Kind_deleting)
					end
					if has_selection then
						delete_selection
					elseif caret > 0 then
						text.remove (caret)
						marks.text_removed (caret - 1, caret)
						caret := caret - 1
						sel_anchor := caret
					end
					changed
				elseif a_code = 13 and (is_single_line or is_one_paragraph) then
					if attached on_activate as a then
						a.call
					end
				elseif a_code >= 32 or else (a_code = 13 and not is_single_line and not is_one_paragraph) then
					remember (Kind_typing)
					if has_selection then
						delete_selection
					end
					if a_code = 13 then
						text.insert_character ('%N', caret + 1)
					else
						text.insert_character (a_code.to_character_32, caret + 1)
					end
					marks.text_inserted (caret, 1)
					caret := caret + 1
					sel_anchor := caret
					changed
				end
			end
		end

	accepts_pebble (a_pebble: ANY): BOOLEAN
			-- Text boxes welcome any string pebble (unless read-only).
		do
			Result := not is_read_only and then attached {READABLE_STRING_GENERAL} a_pebble
		end

	receive_pebble (a_pebble: ANY)
			-- Drop inserts the string at the caret.
		local
			s: STRING_32
		do
			if attached {READABLE_STRING_GENERAL} a_pebble as rs then
				create s.make_from_string_general (rs)
				remember (Kind_block)
				if has_selection then
					delete_selection
				end
				text.insert_string (s, caret + 1)
				marks.text_inserted (caret, s.count)
				caret := caret + s.count
				sel_anchor := caret
				changed
			end
		end

	type_text (a_text: READABLE_STRING_GENERAL)
			-- Replace the text as a user would (W11, simple_gui's test door): one undo step,
			-- and `on_change' runs - unlike `set_text', which is the program's and silent.
		require
			writable: not is_read_only
		do
			select_all
			if not a_text.is_empty then
				receive_pebble (a_text)
			elseif has_selection then
				remember (Kind_block)
				delete_selection
				changed
			end
		ensure
			typed: text.same_string_general (a_text)
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- The standard text menu. A right-click outside the current
			-- selection moves the caret there first, as every editor does.
		local
			clip: SW_CLIPBOARD
			c: INTEGER
		do
			c := offset_at (a_px, a_py)
			if not (has_selection and then c >= sel_anchor.min (caret) and then c <= sel_anchor.max (caret)) then
				caret := c
				sel_anchor := c
			end
			create clip
			create Result.make
			refresh_spelling
			if not is_read_only and then attached spell_range_at (c) as sr then
				across
					suggestion_texts (sr) as sg
				loop
					Result.add_item (sg, "", True, agent replace_range (sr.lo, sr.hi, sg))
				end
				Result.add_item ({STRING_32} "Ignore %"" + word_of (sr) + {STRING_32} "%"",
					"", True, agent ignore_misspelling (sr.lo, sr.hi))
				Result.add_item ({STRING_32} "Add %"" + word_of (sr) + {STRING_32} "%" to dictionary",
					"", True, agent learn_word (sr.lo, sr.hi))
				Result.add_separator
			end
			Result.add_item ("Cut", "Ctrl+X", has_selection and not is_read_only and not is_masked, agent cut_selection)
			Result.add_item ("Copy", "Ctrl+C", has_selection and not is_masked, agent copy_selection)
			Result.add_item ("Paste", "Ctrl+V", clip.has_text and not is_read_only, agent paste_clipboard)
			Result.add_separator
			Result.add_item ("Select All", "Ctrl+A", text.count > 0, agent select_all)
			Result.add_item ("Select None", "Esc", has_selection, agent select_none)
			Result.add_item ("Invert Selection", "", has_selection, agent invert_selection)
		ensure then
			offered: Result /= Void
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		local
			cl: INTEGER
			cx: REAL_64
		do
			inspect a_vk
			when 37 then -- LEFT: on screen, so forward through right-to-left text
				if reads_right_to_left then
					caret := (caret + 1).min (text.count)
				else
					caret := (caret - 1).max (0)
				end
				collapse_unless (a_shift)
			when 39 then -- RIGHT
				if reads_right_to_left then
					caret := (caret - 1).max (0)
				else
					caret := (caret + 1).min (text.count)
				end
				collapse_unless (a_shift)
			when 36 then -- HOME
				caret := line_start (caret_line)
				collapse_unless (a_shift)
			when 35 then -- END
				caret := line_end (caret_line)
				collapse_unless (a_shift)
			when 38 then -- UP
				cl := caret_line
				if cl > 0 then
					cx := caret_x
					caret := offset_on_line (cl - 1, cx)
				end
				collapse_unless (a_shift)
			when 40 then -- DOWN
				cl := caret_line
				if cl < lay_lines - 1 then
					cx := caret_x
					caret := offset_on_line (cl + 1, cx)
				end
				collapse_unless (a_shift)
			when 46 then -- DELETE
				if not is_read_only then
					if has_selection or caret < text.count then
						remember (Kind_deleting)
					end
					if has_selection then
						delete_selection
						changed
					elseif caret < text.count then
						text.remove (caret + 1)
						marks.text_removed (caret, caret + 1)
						changed
					end
				end
			else
			end
		end

feature -- Caret geometry

	geometry: SW_TEXT_GEOMETRY
			-- Where every character paints, for the current text, width,
			-- size and engine (see `ensure_layout').

	line_count: INTEGER
			-- Visual lines the last layout produced; 1 before any.
		do
			Result := geometry.line_count
		ensure
			at_least_one: Result >= 1
		end

	is_shaped_layout: BOOLEAN
			-- Did the last layout come from the shaping kit (bidi,
			-- itemization, fallback) rather than cairo's toy path?
		do
			Result := geometry.is_shaped
		end

	is_laid_out: BOOLEAN
			-- Has the current text been measured (by `preferred_height'
			-- or `draw')? The geometry queries answer for the text on
			-- screen only.
		do
			Result := geometry.count = text.count
		ensure
			definition: Result = (geometry.count = text.count)
		end

	is_rtl_at (a_i: INTEGER): BOOLEAN
			-- Does character `a_i' paint in a right-to-left run?
			-- Always False on the toy path.
		require
			in_text: a_i >= 1 and a_i <= text.count
			laid_out: is_laid_out
		do
			Result := geometry.is_rtl (a_i)
		end

	line_at_offset (a_offset: INTEGER): INTEGER
			-- The 0-based visual line the caret stands on at `a_offset'.
		require
			in_range: a_offset >= 0 and a_offset <= text.count
		do
			if is_laid_out then
				Result := geometry.line_at_offset (a_offset)
			end
		ensure
			in_lines: Result >= 0 and Result < line_count
		end

	x_at_offset (a_offset: INTEGER): REAL_64
			-- Where the caret stands at `a_offset', measured from the
			-- text's left edge: AFTER character `a_offset' in reading
			-- order - its right edge in a left-to-right run, its LEFT
			-- edge in a right-to-left one - and before the first
			-- character at offset 0.
		require
			in_range: a_offset >= 0 and a_offset <= text.count
		do
			if is_laid_out then
				Result := geometry.x_at_offset (a_offset)
			end
		ensure
			non_negative: Result >= 0.0
		end

	offset_at (a_px, a_py: REAL_64): INTEGER
			-- The caret offset nearest a window point: the line under
			-- `a_py', then the nearest caret boundary along it.
		do
			if is_laid_out then
				Result := geometry.offset_at (a_px - text_left, a_py - text_top)
			end
		ensure
			in_range: Result >= 0 and Result <= text.count
		end

	content_height: REAL_64
			-- The stacked height of every laid-out line.
		do
			Result := geometry.content_height
		ensure
			non_negative: Result >= 0.0
		end

feature -- Metrics

	Pad_x: REAL_64 = 9.0
	Pad_y: REAL_64 = 6.0
			-- The field's own inside inset at 1x: the text origin is
			-- (x + Pad_x, y + Pad_y) unless a descendant moves it (see
			-- `text_left'), which is what `x_at_offset' and `offset_at'
			-- are measured against. (The HEIGHT minimum is theme- and
			-- metric-driven; see `preferred_height'.)

feature -- Text frame

	text_left: REAL_64
			-- The window x of the text's origin: the field's left edge
			-- plus its inset. A descendant that scrolls sideways or
			-- carries a gutter answers its own; the drawing, the hit test
			-- (`offset_at') and the caret all read this one query.
		do
			Result := x + Pad_x + style_inset_left
		end

	text_top: REAL_64
			-- The window y of the text's origin: the field's top edge plus
			-- its inset. A descendant that scrolls answers its own.
		do
			Result := y + Pad_y + style_inset_top
		end

	wrap_width_in (a_width: REAL_64): REAL_64
			-- The width the lines wrap at in a field `a_width' wide: what
			-- the insets leave. A descendant that never wraps (a code
			-- editor) answers a width no line reaches.
		do
			Result := a_width - 2.0 * Pad_x - style_inset_width
		end

feature -- Own appearance

	shows_style (a_part: INTEGER): BOOLEAN
			-- The text's color and font, the placeholder's and the selection's colors, and
			-- the frame: background, padding, border, radius and shadow. (The border is the
			-- resting one: focus and an invalid entry still draw their own.) No scroll bars:
			-- the box grows with its text.
		do
			Result := is_text_style_part (a_part) or is_frame_style_part (a_part)
				or a_part = {SW_WIDGET_STYLE}.Part_placeholder
				or a_part = {SW_WIDGET_STYLE}.Part_selection
		end

	set_style (a_style: detachable SW_WIDGET_STYLE)
			-- <Precursor> The text is laid out again: the face or the padding may differ.
		do
			Precursor (a_style)
			layout_width := -1.0
		end

	text_role: INTEGER
			-- The face the text is set in: a painter role, or 0 for the
			-- field's own (the shaping kit's policy, the body face on the
			-- toy path).

	set_text_role (a_role: INTEGER)
			-- Set the text in `a_role''s face (`Role_mono' for code); 0
			-- gives the field's own back.
		require
			role_known: a_role = 0 or a_role = {SW_PAINTER}.Role_ui
				or a_role = {SW_PAINTER}.Role_body or a_role = {SW_PAINTER}.Role_mono
		do
			text_role := a_role
			layout_width := -1.0
		ensure
			set: text_role = a_role
		end

	tab_spaces: INTEGER
			-- Space-widths between tab stops (8 until `set_tab_spaces').
		do
			Result := geometry.tab_spaces
		ensure
			positive: Result >= 1
		end

	set_tab_spaces (a_count: INTEGER)
			-- Put the tab stops every `a_count' space-widths of the face.
		require
			positive: a_count >= 1
		do
			geometry.set_tab_spaces (a_count)
			layout_width := -1.0
		ensure
			set: tab_spaces = a_count
		end

feature {NONE} -- Engine

	face_role: INTEGER
			-- The painter role the text is measured and painted under:
			-- `text_role', or the body face when that is 0.
		do
			Result := styled_role (text_role)
			if Result = 0 then
				Result := {SW_PAINTER}.Role_body
			end
		ensure
			a_role: Result = {SW_PAINTER}.Role_ui or Result = {SW_PAINTER}.Role_body
				or Result = {SW_PAINTER}.Role_mono
		end

	body_size (a_p: SW_PAINTER): REAL_64
			-- The size the text is set at, before the theme's scale: `text_size', or the
			-- theme's body size when that is 0.
		do
			if text_size > 0.0 then
				Result := styled_size (text_size)
			else
				Result := styled_size (a_p.theme.size_body)
			end
		ensure
			positive: Result > 0.0
		end

	body_pixels (a_p: SW_PAINTER): INTEGER
			-- The body text's pixel size at the theme's scale: what the
			-- shaped path lays out at, and what `row_height' measures.
		do
			Result := (body_size (a_p) * a_p.theme.text_scale).rounded.max (1)
		ensure
			positive: Result >= 1
		end

	Eye_zone: REAL_64 = 30.0
			-- Right-edge click zone of a masked box: the reveal eye.

	layout_width: REAL_64
			-- Width the cached layout was measured at; -1 forces rebuild.
	laid_size: INTEGER
			-- Pixel size the cached layout was shaped at.
	laid_shaped: BOOLEAN
			-- Did the cached layout come from the shaping kit?
	laid_alignment: INTEGER
			-- `effective_text_alignment' the cached layout was placed by (GW-02).

	ensure_layout (a_p: SW_PAINTER; a_wrap: REAL_64)
			-- Measure-then-place, cached against width, size and engine:
			-- the shaping kit when the painter carries one and the text
			-- is not masked, cairo's toy advances otherwise.
		local
			want_shaped: BOOLEAN
			px: INTEGER
		do
			want_shaped := a_p.has_shaping and not is_hiding
			px := body_pixels (a_p)
			if layout_width /= a_wrap or geometry.count /= text.count
				or laid_shaped /= want_shaped or laid_size /= px
				or laid_alignment /= effective_text_alignment
			then
				layout_width := a_wrap
				laid_size := px
				laid_shaped := want_shaped
				laid_alignment := effective_text_alignment
					-- GW-02: lines placed by `text_alignment' in the box the
					-- text may fill (mirrored in right-to-left layout, W4c).
				geometry.set_alignment (laid_alignment, a_wrap.max (0.0))
				if attached text_styles as al_styles then
					al_styles.clamp_to (text.count)
				end
				geometry.set_styles (text_styles)
				if has_styled_font and then attached a_p.shaping as al_kit then
						-- its own face (SW_WIDGET_STYLE); a box without a role leads with the
						-- UI face, as the kit's own policy does
					geometry.set_own_faces (al_kit.faced_fonts (
						(if styled_role (text_role) > 0 then styled_role (text_role) else {SW_PAINTER}.Role_ui end),
						px, styled_weight (False), styled_italic, styled_family))
				else
					geometry.set_own_faces (Void)
				end
				geometry.lay_out (a_p, text, a_wrap.max (0.0), styled_role (text_role), body_size (a_p),
					styled_weight (False) >= 600, is_single_line, is_hiding).do_nothing
			end
		ensure
			laid_out: is_laid_out
			engine_recorded: laid_shaped = (a_p.has_shaping and not is_hiding)
		end

	glyph (a_i: INTEGER): STRING_32
			-- What position `a_i' shows: the character itself, or a
			-- bullet when masked - secrets have length, not content.
		require
			in_text: a_i >= 1 and a_i <= text.count
		do
			if is_hiding then
				Result := {STRING_32} "%/8226/"
			else
				Result := text.substring (a_i, a_i)
			end
		end

	caret_line: INTEGER
		do
			Result := line_at_offset (caret)
		end

	caret_x: REAL_64
		do
			Result := x_at_offset (caret)
		end

	line_start (a_line: INTEGER): INTEGER
		do
			if is_laid_out and then a_line >= 0 and then a_line < geometry.line_count then
				Result := geometry.line_start (a_line)
			end
		ensure
			in_range: Result >= 0 and Result <= text.count
		end

	line_end (a_line: INTEGER): INTEGER
		do
			if is_laid_out and then a_line >= 0 and then a_line < geometry.line_count then
				Result := geometry.line_end (a_line)
			end
		ensure
			in_range: Result >= 0 and Result <= text.count
		end

	offset_on_line (a_line: INTEGER; a_px: REAL_64): INTEGER
		do
			if is_laid_out and then a_line >= 0 and then a_line < geometry.line_count then
				Result := geometry.offset_on_line (a_line, a_px)
			end
		ensure
			in_range: Result >= 0 and Result <= text.count
		end

	lay_lines: INTEGER
			-- Visual lines, for the arrow keys.
		do
			Result := geometry.line_count
		end

	suggestion_texts (a_r: TUPLE [lo, hi: INTEGER]): ARRAYED_LIST [STRING_32]
			-- Up to three corrections for the word in `a_r'.
		local
			sp: SW_SPELLER
		do
			create sp
			create Result.make (3)
			across
				sp.suggestions (text.substring (a_r.lo + 1, a_r.hi)) as s
			loop
				if Result.count < 3 then
					Result.extend (s)
				end
			end
		ensure
			few: Result.count <= 3
		end

	all_ranges: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			-- Primary plus extras, normalized, sorted, non-empty only.
		local
			lo, hi, i, j: INTEGER
			r, s: TUPLE [lo, hi: INTEGER]
		do
			create Result.make (extra_ranges.count + 1)
			across
				extra_ranges as er
			loop
				Result.extend (er)
			end
			lo := sel_anchor.min (caret)
			hi := sel_anchor.max (caret)
			if hi > lo then
				Result.extend ([lo, hi])
			end
				-- insertion sort by lo; lists are tiny
			from
				i := 2
			until
				i > Result.count
			loop
				from
					j := i
				until
					j <= 1 or else Result.i_th (j - 1).lo <= Result.i_th (j).lo
				loop
					r := Result.i_th (j)
					s := Result.i_th (j - 1)
					Result.put_i_th (r, j - 1)
					Result.put_i_th (s, j)
					j := j - 1
				end
				i := i + 1
			end
		ensure
			sorted: across 2 |..| Result.count as k all
				Result.i_th (k - 1).lo <= Result.i_th (k).lo end
		end

	collapse_unless (a_extend: BOOLEAN)
		do
			if not a_extend then
				sel_anchor := caret
			end
		ensure
			collapsed: not a_extend implies not has_selection
		end

	delete_selection
			-- Remove every selected range; the caret lands where the
			-- first one began.
		local
			pieces: ARRAYED_LIST [TUPLE [lo, hi: INTEGER]]
			i, first_lo: INTEGER
		do
			pieces := all_ranges
			if not pieces.is_empty then
				first_lo := pieces.first.lo
				from
					i := pieces.count
				until
					i < 1
				loop
					text.remove_substring (pieces.i_th (i).lo + 1, pieces.i_th (i).hi)
					marks.text_removed (pieces.i_th (i).lo, pieces.i_th (i).hi)
					i := i - 1
				end
				caret := first_lo
				sel_anchor := first_lo
				extra_ranges.wipe_out
			end
		ensure
			collapsed: not has_selection
		end

	changed
		do
			layout_width := -1.0
			spell_dirty := True
			if attached on_change as a then
				a.call
			end
		end

	spell_dirty: BOOLEAN

	refresh_spelling
		local
			sp: SW_SPELLER
		do
			if spell_dirty then
				spell_dirty := False
				spell_ranges.wipe_out
				if is_spellcheck_enabled and not is_masked then
					create sp
					across
						sp.misspellings (text) as r
					loop
						if r.hi <= text.count then
							spell_ranges.extend (r)
						end
					end
				end
			end
		end

	spell_range_at (a_pos: INTEGER): detachable TUPLE [lo, hi: INTEGER]
			-- The misspelled range containing position `a_pos', if any.
		do
			across
				spell_ranges as r
			loop
				if a_pos > r.lo and a_pos <= r.hi then
					Result := r
				end
			end
		end

	word_of (a_range: TUPLE [lo, hi: INTEGER]): STRING_32
			-- The flagged characters themselves.
		do
			Result := text.substring (a_range.lo + 1, a_range.hi)
		end

	ignore_misspelling (a_lo, a_hi: INTEGER)
			-- Stop flagging this word for the session (the OS
			-- checker's Ignore); the squiggle lifts on repaint.
		require
			sane: a_lo >= 0 and a_hi <= text.count and a_lo < a_hi
		local
			sp: SW_SPELLER
		do
			create sp
			if sp.ignore (text.substring (a_lo + 1, a_hi)) then
			end
			spell_dirty := True
		end

	learn_word (a_lo, a_hi: INTEGER)
			-- Teach the word permanently: it joins the user's
			-- Windows dictionary, honored system-wide.
		require
			sane: a_lo >= 0 and a_hi <= text.count and a_lo < a_hi
		local
			sp: SW_SPELLER
		do
			create sp
			if sp.add_to_dictionary (text.substring (a_lo + 1, a_hi)) then
			end
			spell_dirty := True
		end

	replace_range (a_lo, a_hi: INTEGER; a_with: READABLE_STRING_GENERAL)
			-- Swap characters a_lo+1..a_hi for `a_with' (a suggestion).
		require
			sane: a_lo >= 0 and a_hi <= text.count and a_lo < a_hi
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_with)
			text.remove_substring (a_lo + 1, a_hi)
			marks.text_removed (a_lo, a_hi)
			text.insert_string (s, a_lo + 1)
			if not s.is_empty then
				marks.text_inserted (a_lo, s.count)
			end
			caret := a_lo + s.count
			sel_anchor := caret
			changed
		end


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_edit
		end

	accessible_value: detachable STRING_32
		do
				-- a masked line never tells its text
			if not is_masked then
				Result := text.twin
			end
		end

invariant
	text_attached: text /= Void
	geometry_attached: geometry /= Void
	marks_attached: marks /= Void
	caret_in_range: caret >= 0 and caret <= text.count
	anchor_in_range: sel_anchor >= 0 and sel_anchor <= text.count
	extras_attached: extra_ranges /= Void
	extras_well_formed: across extra_ranges as r all
		r.lo >= 0 and r.lo < r.hi and r.hi <= text.count end

end
