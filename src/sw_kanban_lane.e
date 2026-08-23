note
	description: "[
		One lane of the board: draws its title and its cards, offers
		any card under the pointer as a PEBBLE (middle-click lifts
		it), and welcomes any card id as a drop - receiving means
		asking the board to move_card here. The row arithmetic
		(card_at) is public and assaulted through the board.
	]"

class
	SW_KANBAN_LANE

inherit
	SW_WIDGET
		redefine
			pebble_at, accepts_pebble, receive_pebble
		end

create
	make_on

feature {NONE} -- Initialization

	make_on (a_board: SW_KANBAN; a_index: INTEGER)
		require
			index_positive: a_index >= 1
		do
			board := a_board
			lane_index := a_index
		ensure
			aboard: board = a_board and lane_index = a_index
		end

feature -- Access

	board: SW_KANBAN

	lane_index: INTEGER

	Title_h: REAL_64 = 28.0

	Card_h: REAL_64 = 34.0

	card_at (a_py: REAL_64): INTEGER
			-- The card id under a surface y in THIS lane; 0 between
			-- and beyond cards.
		local
			slot: INTEGER
			mine: ARRAYED_LIST [INTEGER]
		do
			if a_py >= y + Title_h then
				slot := ((a_py - y - Title_h) / (Card_h + 6.0)).truncated_to_integer + 1
				mine := board.cards_in (lane_index)
				if slot >= 1 and slot <= mine.count then
					Result := mine.i_th (slot)
				end
			end
		end

feature -- Pebbles

	pebble_at (a_px, a_py: REAL_64): detachable ANY
			-- The card under the point, as its id.
		local
			id: INTEGER
		do
			id := card_at (a_py)
			if id > 0 then
				Result := id
			end
		end

	accepts_pebble (a_pebble: ANY): BOOLEAN
			-- Any card of this board is welcome (including from
			-- this very lane - a drop home is a quiet no-op).
		do
			if attached {INTEGER_REF} a_pebble as id then
				Result := id.item >= 1 and id.item <= board.cards.count
			end
		end

	receive_pebble (a_pebble: ANY)
		do
			if attached {INTEGER_REF} a_pebble as id then
				board.move_card (id.item, lane_index)
			end
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := Title_h + 5.0 * (Card_h + 6.0) + 10.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			mine: ARRAYED_LIST [INTEGER]
			i: INTEGER
			cy: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.set_color (t.surface_variant)
			a_p.rrect_fill (x + 1.0, y + 1.0, width - 2.0, Title_h, t.radius)
			a_p.font ({SW_PAINTER}.Role_ui, 13.0, True)
			a_p.set_color (t.ink)
			mine := board.cards_in (lane_index)
			a_p.text (x + 10.0, y + Title_h - 9.0,
				board.lane_titles.i_th (lane_index) + {STRING_32} "  (" + mine.count.out + {STRING_32} ")")
			from
				i := 1
			until
				i > mine.count
			loop
				cy := y + Title_h + (i - 1) * (Card_h + 6.0) + 6.0
				a_p.set_color (t.background)
				a_p.rrect_fill (x + 8.0, cy, width - 16.0, Card_h, t.radius)
				a_p.set_color (t.outline)
				a_p.rrect_stroke (x + 8.5, cy + 0.5, width - 17.0, Card_h - 1.0, t.radius)
				a_p.font ({SW_PAINTER}.Role_ui, 12.5, False)
				a_p.set_color (t.ink)
				a_p.text (x + 16.0, cy + Card_h / 2.0 + 4.0,
					board.cards.i_th (mine.i_th (i)).title)
				i := i + 1
			end
			a_p.font ({SW_PAINTER}.Role_ui, 10.5, False)
			a_p.set_color (t.ink_muted)
			a_p.text (x + 10.0, y + height - 8.0, {STRING_32} "middle-click lifts a card; drop moves it here")
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

invariant
	aboard: board /= Void
	indexed: lane_index >= 1

end
