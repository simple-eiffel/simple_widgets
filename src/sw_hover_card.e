note
	description: "[
		What a hover card shows and what it was opened for (GW-09): a
		widget tree (`content') at a width, and the ANCHOR - the window
		rectangle of the thing hovered, a word or a reference. The window
		places the card below the anchor (above when there is no room)
		and keeps it open while the pointer is on the card, on the
		anchor, or crossing the gap between them.

		A widget names the sub-region it offers a card for by answering
		`SW_WIDGET.hover_card_at' with one of these. One without an
		anchor gets one from the widget that offered it (the paragraph
		list anchors at the word under the pointer).
	]"
	author: "Larry Rix"

class
	SW_HOVER_CARD

create
	make

feature {NONE} -- Initialization

	make (a_content: SW_WIDGET; a_width: REAL_64)
			-- Show `a_content' `a_width' wide; no anchor yet.
		require
			positive_width: a_width > 0.0
		do
			content := a_content
			width := a_width
		ensure
			content_kept: content = a_content
			width_kept: width = a_width
			no_anchor: not has_anchor
		end

feature -- Access

	content: SW_WIDGET
			-- The tree the card holds.

	width: REAL_64
			-- The content's width (the card adds its padding).

	anchor_x, anchor_y, anchor_width, anchor_height: REAL_64
			-- The window rectangle the card was opened for.

	has_anchor: BOOLEAN
			-- Has `set_anchor' run?

	anchor_matches (a_other: SW_HOVER_CARD): BOOLEAN
			-- Is `a_other' opened for the same rectangle?
		do
			Result := has_anchor and a_other.has_anchor
				and anchor_x = a_other.anchor_x and anchor_y = a_other.anchor_y
				and anchor_width = a_other.anchor_width and anchor_height = a_other.anchor_height
		end

	anchor_has (a_x, a_y: REAL_64): BOOLEAN
			-- Is (`a_x', `a_y') on the anchor?
		do
			Result := has_anchor and a_x >= anchor_x and a_x < anchor_x + anchor_width
				and a_y >= anchor_y and a_y < anchor_y + anchor_height
		end

feature -- Element change

	set_anchor (a_x, a_y, a_width, a_height: REAL_64)
			-- Opened for the window rectangle (`a_x', `a_y', `a_width', `a_height').
		require
			non_negative: a_width >= 0.0 and a_height >= 0.0
		do
			anchor_x := a_x
			anchor_y := a_y
			anchor_width := a_width
			anchor_height := a_height
			has_anchor := True
		ensure
			anchored: has_anchor
			kept: anchor_x = a_x and anchor_y = a_y and anchor_width = a_width and anchor_height = a_height
		end

invariant
	positive_width: width > 0.0
	anchor_non_negative: anchor_width >= 0.0 and anchor_height >= 0.0

end
