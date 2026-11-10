note
	description: "[
		The parts one SW_TEXT_LIST row carries beside its title (simple_gui 1s): a second line,
		an icon name, a count badge, a check box and a close glyph. Kept with the row as it
		moves, so a reorder or a removal carries them along.
	]"

class
	SW_ROW_PARTS

create
	make

feature {NONE} -- Initialization

	make
		do
			create subtitle.make_empty
			create icon.make_empty
		ensure
			plain: subtitle.is_empty and icon.is_empty and badge = 0
				and not is_checkable and not is_checked and not is_closable
		end

feature -- Access

	subtitle: STRING_32
			-- The second, dimmer line; empty for none.

	icon: STRING_32
			-- An icon name (see `SW_ICON.glyph_named'); empty for none.

	badge: INTEGER
			-- The count in the pill at the trailing edge; 0 for none.

	is_checkable: BOOLEAN
			-- Does a check box show at the leading edge?

	is_checked: BOOLEAN

	is_closable: BOOLEAN
			-- Does a close glyph show at the trailing edge?

feature -- Element change

	set_subtitle (a_text: READABLE_STRING_GENERAL)
		do
			create subtitle.make_from_string_general (a_text)
		ensure
			set: subtitle.same_string_general (a_text)
		end

	set_icon (a_name: READABLE_STRING_GENERAL)
		do
			create icon.make_from_string_general (a_name)
		ensure
			set: icon.same_string_general (a_name)
		end

	set_badge (a_count: INTEGER)
		require
			non_negative: a_count >= 0
		do
			badge := a_count
		ensure
			set: badge = a_count
		end

	set_checkable (a_on: BOOLEAN)
		do
			is_checkable := a_on
		ensure
			set: is_checkable = a_on
		end

	set_checked (a_on: BOOLEAN)
		do
			is_checked := a_on
		ensure
			set: is_checked = a_on
		end

	set_closable (a_on: BOOLEAN)
		do
			is_closable := a_on
		ensure
			set: is_closable = a_on
		end

invariant
	texts_exist: subtitle /= Void and icon /= Void
	badge_non_negative: badge >= 0

end
