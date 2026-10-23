note
	description: "[
		One section of an SW_STATUS_BAR (GW-11): a text, optionally
		clickable, or a small hosted widget (a progress bar, a Cancel
		button) at a fixed width. Leading sections pack from the left,
		trailing ones from the right; a hidden section takes no room.
		The bar places it; `left' and `span' are where it went.
	]"

class
	SW_STATUS_SECTION

create
	make_text, make_widget

feature {NONE} -- Initialization

	make_text (a_text: READABLE_STRING_GENERAL; a_trailing: BOOLEAN)
		do
			create text.make_from_string_general (a_text)
			is_trailing := a_trailing
			is_visible := True
		ensure
			text_kept: text.same_string_general (a_text)
			no_widget: widget = Void
			side_kept: is_trailing = a_trailing
			visible: is_visible
		end

	make_widget (a_widget: SW_WIDGET; a_width: REAL_64; a_trailing: BOOLEAN)
		require
			positive_width: a_width > 0.0
		do
			create text.make_empty
			widget := a_widget
			fixed_width := a_width
			is_trailing := a_trailing
			is_visible := True
		ensure
			widget_kept: widget = a_widget
			width_kept: fixed_width = a_width
			side_kept: is_trailing = a_trailing
			visible: is_visible
		end

feature -- Access

	text: STRING_32
			-- What a text section shows (empty for a widget section).

	widget: detachable SW_WIDGET
			-- What a widget section hosts.

	fixed_width: REAL_64
			-- A widget section's width.

	is_trailing: BOOLEAN
			-- Packed from the right edge?

	is_visible: BOOLEAN
			-- Does it take room and draw?

	on_click: detachable PROCEDURE
			-- Run when a text section is clicked.

	left: REAL_64
			-- Where the bar placed it (window coordinates).

	span: REAL_64
			-- How wide the bar made it.

	is_clickable: BOOLEAN
			-- A text section with a click agent?
		do
			Result := widget = Void and attached on_click
		end

	has_point (a_px: REAL_64): BOOLEAN
			-- Does `a_px' fall in this visible section?
		do
			Result := is_visible and span > 0.0 and a_px >= left and a_px < left + span
		end

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
		require
			text_section: widget = Void
		do
			create text.make_from_string_general (a_text)
		ensure
			kept: text.same_string_general (a_text)
		end

	set_visible (a_visible: BOOLEAN)
		do
			is_visible := a_visible
		ensure
			set: is_visible = a_visible
		end

	set_on_click (a_action: PROCEDURE)
		require
			text_section: widget = Void
		do
			on_click := a_action
		ensure
			set: on_click = a_action
		end

	place (a_left, a_span: REAL_64)
			-- Record where the bar put it.
		require
			non_negative: a_span >= 0.0
		do
			left := a_left
			span := a_span
		ensure
			placed: left = a_left and span = a_span
		end

invariant
	text_or_widget: attached widget implies text.is_empty
	widget_has_width: attached widget implies fixed_width > 0.0
	non_negative_span: span >= 0.0

end
