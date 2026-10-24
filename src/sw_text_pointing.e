note
	description: "[
		A widget whose text the pointer can point INTO (GW-08, GW-09):
		it follows the character under the pointer, tells the host when
		that character changes (`on_hover') and when the pointer rests
		on it (`on_dwell', after `dwell_delay' milliseconds; the window
		times it), and offers a hover card for it (`hover_card_builder'),
		anchored at its word unless the builder anchored the card.

		A descendant says where its text is, through four features:

		    pointed_item (x, y)        which of its texts is under a point
		    character_at (x, y)        which character of it
		    text_of (item)             that text's characters
		    text_boxes (item, lo, hi)  where a stretch of it paints

		An "item" is whatever unit the widget numbers: a paragraph of
		SW_PARAGRAPH_LIST, a block's text or a table cell of
		SW_DOCUMENT_VIEW. Lifted (0.20.0) from SW_PARAGRAPH_LIST so the
		document view is not a second copy. A descendant calls
		`init_pointing' from its creation procedure.
	]"
	author: "Larry Rix"

deferred class
	SW_TEXT_POINTING

inherit
	SW_WIDGET
		redefine
			set_hover_point, set_hovered, dwell_ms, handle_dwell, hover_card_at
		end

feature {NONE} -- Initialization

	init_pointing
			-- No hover yet; the word card's 400 millisecond delay.
		do
			dwell_delay := 400
		ensure
			default_delay: dwell_delay = 400
			no_hover: hover_item = 0 and hover_character = 0
		end

feature -- Pointing

	is_valid_item (a_item: INTEGER): BOOLEAN
			-- Is `a_item' one of the widget's text items?
		deferred
		end

	pointed_item (a_px, a_py: REAL_64): INTEGER
			-- The item whose text is under window point (`a_px', `a_py');
			-- 0 for none.
		deferred
		ensure
			none_or_valid: Result = 0 or else is_valid_item (Result)
		end

	character_at (a_px, a_py: REAL_64): INTEGER
			-- The character of `pointed_item' painted under the point; 0
			-- when the point is on no character.
		deferred
		ensure
			non_negative: Result >= 0
		end

	text_of (a_item: INTEGER): READABLE_STRING_32
			-- Item `a_item''s characters.
		require
			valid_item: is_valid_item (a_item)
		deferred
		end

	text_boxes (a_item, a_lo, a_hi: INTEGER): ARRAYED_LIST [TUPLE [x, y, width, height: REAL_64]]
			-- Window rectangles of item `a_item''s characters `a_lo' + 1 ..
			-- `a_hi', one per visual line; empty before it is laid out.
		require
			valid_item: is_valid_item (a_item)
			range_valid: a_lo >= 0 and a_lo <= a_hi and a_hi <= text_of (a_item).count
		deferred
		ensure
			positive_widths: across Result as b all b.width > 0.0 end
		end

	hover_item: INTEGER
			-- The item of the character under the pointer; 0 = none.

	hover_character: INTEGER
			-- The character under the pointer in `hover_item'; 0 = none.

	dwell_delay: INTEGER
			-- Milliseconds the pointer must rest on a character before
			-- `on_dwell'.

	on_hover: detachable PROCEDURE [INTEGER, INTEGER]
			-- The character under the pointer changed: (item, character),
			-- or (0, 0) when the pointer left the text.

	on_dwell: detachable PROCEDURE [INTEGER, INTEGER]
			-- The pointer rested `dwell_delay' on (item, character).

	hover_card_builder: detachable FUNCTION [INTEGER, INTEGER, detachable SW_HOVER_CARD]
			-- Builds the card for (item, character) after a dwell; Void
			-- answers none. A card it leaves without an anchor is anchored
			-- at the word.

	word_at (a_item, a_character: INTEGER): TUPLE [lo, hi: INTEGER]
			-- The word around character `a_character' of item `a_item'
			-- (SW_WORD_BOUNDARY), as caret offsets.
		require
			valid_item: is_valid_item (a_item)
			character_in_text: a_character >= 1 and a_character <= text_of (a_item).count
		do
			Result := words.word_around (text_of (a_item), a_character)
		ensure
			holds_it: Result.lo < a_character and a_character <= Result.hi
		end

	set_on_hover (a_action: detachable PROCEDURE [INTEGER, INTEGER])
		do
			on_hover := a_action
		ensure
			set: on_hover = a_action
		end

	set_on_dwell (a_action: detachable PROCEDURE [INTEGER, INTEGER])
		do
			on_dwell := a_action
		ensure
			set: on_dwell = a_action
		end

	set_dwell_delay (a_ms: INTEGER)
		require
			positive: a_ms > 0
		do
			dwell_delay := a_ms
		ensure
			set: dwell_delay = a_ms
		end

	set_hover_card_builder (a_builder: detachable FUNCTION [INTEGER, INTEGER, detachable SW_HOVER_CARD])
		do
			hover_card_builder := a_builder
		ensure
			set: hover_card_builder = a_builder
		end

feature -- Window protocol

	dwell_ms: INTEGER
			-- `dwell_delay' while someone listens on `on_dwell' or builds
			-- hover cards.
		do
			if attached on_dwell or attached hover_card_builder then
				Result := dwell_delay
			end
		end

	handle_dwell (a_px, a_py: REAL_64)
			-- The window says the pointer rested: tell the host which
			-- character it rested on, if any.
		local
			ch: INTEGER
		do
			ch := character_at (a_px, a_py)
			if ch > 0 and then attached on_dwell as al_d then
				al_d.call (pointed_item (a_px, a_py), ch)
			end
		end

	hover_card_at (a_px, a_py: REAL_64): detachable SW_HOVER_CARD
			-- The builder's card for the character under the point,
			-- anchored at its word (on the line under the pointer) unless
			-- the builder anchored it.
		local
			i, ch: INTEGER
			l_word: TUPLE [lo, hi: INTEGER]
			l_boxes: like text_boxes
		do
			ch := character_at (a_px, a_py)
			if ch > 0 and then attached hover_card_builder as al_b then
				i := pointed_item (a_px, a_py)
				Result := al_b.item ([i, ch])
				if attached Result as al_card and then not al_card.has_anchor then
					l_word := word_at (i, ch)
					l_boxes := text_boxes (i, l_word.lo, l_word.hi)
					across l_boxes as b loop
						if b.y <= a_py and a_py < b.y + b.height then
							al_card.set_anchor (b.x, b.y, b.width, b.height)
						end
					end
					if not al_card.has_anchor and then not l_boxes.is_empty then
						al_card.set_anchor (l_boxes.first.x, l_boxes.first.y, l_boxes.first.width, l_boxes.first.height)
					end
				end
			end
		end

	set_hover_point (a_px, a_py: REAL_64)
			-- Follow the pointer to the character under it.
		do
			Precursor (a_px, a_py)
			follow_hover
		end

	set_hovered (a_hovered: BOOLEAN)
			-- Leaving the widget leaves the text.
		do
			Precursor (a_hovered)
			if not a_hovered then
				hover_to (0, 0)
			end
		end

feature {NONE} -- Pointing implementation

	words: SW_WORD_BOUNDARY
			-- What a word is.
		once
			create Result
		end

	follow_hover
			-- The character under `hover_px', `hover_py' becomes the hover.
		local
			ch: INTEGER
		do
			ch := character_at (hover_px, hover_py)
			if ch > 0 then
				hover_to (pointed_item (hover_px, hover_py), ch)
			else
				hover_to (0, 0)
			end
		end

	hover_to (a_item, a_character: INTEGER)
			-- Move the hover; `on_hover' hears a change.
		do
			if a_item /= hover_item or else a_character /= hover_character then
				hover_item := a_item
				hover_character := a_character
				if attached on_hover as al_h then
					al_h.call (a_item, a_character)
				end
			end
		ensure
			moved: hover_item = a_item and hover_character = a_character
		end

invariant
	hover_whole: (hover_item = 0) = (hover_character = 0)
	dwell_delay_positive: dwell_delay > 0

end
