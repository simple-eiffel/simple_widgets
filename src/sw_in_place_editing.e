note
	description: "[
		A widget that edits one of its items IN PLACE (0.22.0): an
		SW_TEXT_BOX laid over the item so its text origin lands where the
		item was painted, keys and characters forwarded to it while the
		widget holds the focus (Escape cancels), the item following every
		keystroke, and the host told (`on_edit_change' while typing,
		`on_edit_commit' when the edit stands).

		A descendant opens the box with `open_editor', seats it each
		layout with `seat_editor' (measuring it with
		`editor_text_height'), follows the typing in `edited', takes the
		box down in `end_edit' (keeping or restoring), and passes keys
		and characters through `editor_key' and `editor_char' first.
		Nothing of SW_WIDGET is redefined here, so it inherits beside
		SW_TEXT_POINTING, SW_VSCROLLING and SW_TEXT_SELECTION without a
		clash. Lifted from SW_PARAGRAPH_LIST for SW_DOCUMENT_VIEW's live
		preview.
	]"
	author: "Larry Rix"

deferred class
	SW_IN_PLACE_EDITING

inherit
	SW_WIDGET

feature -- Editing

	editor: detachable SW_TEXT_BOX
			-- The box over the item being edited.

	editing_index: INTEGER
			-- The item under the box; 0 = none.

	is_editing: BOOLEAN
		do
			Result := editing_index > 0
		ensure
			definition: Result = (editing_index > 0)
		end

	edit_backup: STRING_32
			-- The text the box opened with.
		attribute
			create Result.make_empty
		end

	on_edit_change: detachable PROCEDURE [INTEGER, STRING_32]
			-- The box changed this item's text (live).

	on_edit_commit: detachable PROCEDURE [INTEGER, STRING_32]
			-- The edit ended and this is the text that stands.

	set_on_edit_change (a_action: detachable PROCEDURE [INTEGER, STRING_32])
		do
			on_edit_change := a_action
		ensure
			set: on_edit_change = a_action
		end

	set_on_edit_commit (a_action: detachable PROCEDURE [INTEGER, STRING_32])
		do
			on_edit_commit := a_action
		ensure
			set: on_edit_commit = a_action
		end

	end_edit (a_commit: BOOLEAN)
			-- Take the box down: keep its text (`a_commit') or restore what
			-- stood before.
		require
			editing: is_editing
		deferred
		ensure
			done: not is_editing
		end

feature {NONE} -- Editing pieces

	edited (a_item: INTEGER; a_text: STRING_32)
			-- The box now reads `a_text': the item follows (and reflows).
		require
			editing_it: a_item = editing_index
		deferred
		end

	open_editor (a_item: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Lay a box holding `a_text' over item `a_item', its caret at the
			-- end and the focus in it.
		require
			not_editing: not is_editing
			item_positive: a_item > 0
		local
			l_ed: SW_TEXT_BOX
		do
			create l_ed.make (a_text)
			l_ed.set_parent (Current)
			l_ed.set_on_change (agent editor_changed)
			l_ed.set_caret (l_ed.text.count)
			l_ed.set_focused (True)
			editor := l_ed
			editing_index := a_item
			create edit_backup.make_from_string_general (a_text)
		ensure
			editing: is_editing and editing_index = a_item
			text_up: attached editor as al_ed and then al_ed.text.same_string_general (a_text)
			caret_at_the_end: attached editor as al_ed2 and then al_ed2.caret = al_ed2.text.count
			backed_up: edit_backup.same_string_general (a_text)
		end

	close_editor
			-- Take the box down without judging its text.
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

	editor_changed
			-- The box typed: the item follows, and the host hears.
		local
			i: INTEGER
		do
			if is_editing and then attached editor as al_ed then
				i := editing_index
				edited (i, al_ed.text.twin)
				if attached on_edit_change as al_c then
					al_c.call (i, al_ed.text.twin)
				end
			end
		end

	seat_editor (a_p: SW_PAINTER; a_x, a_y, a_width, a_height: REAL_64)
			-- Put the box so its text origin is at (`a_x', `a_y') and its
			-- text area `a_width' x `a_height'.
		do
			if attached editor as al_ed then
				al_ed.set_bounds (a_x - al_ed.Pad_x, a_y - al_ed.Pad_y, a_width + 2.0 * al_ed.Pad_x,
					a_height + 2.0 * al_ed.Pad_y)
				al_ed.arrange (a_p)
			end
		end

	editor_text_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- The height the box's text takes at `a_width'.
		require
			editing: is_editing
		do
			if attached editor as al_ed then
				Result := (al_ed.preferred_height (a_p, a_width + 2.0 * al_ed.Pad_x) - 2.0 * al_ed.Pad_y).max (0.0)
			end
		ensure
			non_negative: Result >= 0.0
		end

	editor_key (a_vk: INTEGER; a_shift: BOOLEAN): BOOLEAN
			-- While editing, the key is the box's: True.
		do
			if is_editing and then attached editor as al_ed then
				al_ed.handle_key (a_vk, a_shift)
				Result := True
			end
		end

	editor_char (a_code: INTEGER): BOOLEAN
			-- While editing: Escape cancels, everything else types. True
			-- while editing.
		do
			if is_editing and then attached editor as al_ed then
				if a_code = 27 then
					end_edit (False)
				else
					al_ed.handle_char (a_code)
				end
				Result := True
			end
		end

	editor_has (a_px, a_py: REAL_64): BOOLEAN
			-- Is the point on the box?
		do
			Result := attached editor as al_ed and then al_ed.contains (a_px, a_py)
		end

invariant
	editor_iff_editing: (editor /= Void) = (editing_index > 0)

end
