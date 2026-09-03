note
	description: "[
		The board: lanes side by side, cards stacked within, and
		pick-and-drop carrying cards BETWEEN lanes - the pebble
		protocol earning its enterprise keep (middle-click lifts a
		card, drop it on any lane). The board owns the truth (cards
		registry, lane assignment, move_card with on_move); lanes
		are real widgets (SW_KANBAN_LANE), each its own pebble
		source and drop hole, which is why the window's existing
		pick routing needs nothing new. All the board math -
		cards_in ordering, move semantics, the lane's card_at row
		arithmetic - is public and assaulted.
	]"

class
	SW_KANBAN

inherit
	SW_ROW
		rename
			make as make_row
		redefine
			default_gap
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_row
			create cards.make (16)
			create lane_titles.make (4)
		end


feature -- Spacing (theme defaults; an explicit value still wins)

	default_gap (a_p: SW_PAINTER): REAL_64
			-- 10 px at 1x, as before, now scaled with the text.
		do
			Result := a_p.theme.padding * 1.25
		end

feature -- Access

	cards: ARRAYED_LIST [TUPLE [title: STRING_32; lane: INTEGER]]
			-- Card id = position in this list; a card's lane may
			-- change, its id never does.

	lane_titles: ARRAYED_LIST [STRING_32]

	lane_count: INTEGER
		do
			Result := lane_titles.count
		end

	cards_in (a_lane: INTEGER): ARRAYED_LIST [INTEGER]
			-- The card ids standing in a lane, in id order.
		require
			known: a_lane >= 1 and a_lane <= lane_count
		local
			i: INTEGER
		do
			create Result.make (8)
			from
				i := 1
			until
				i > cards.count
			loop
				if cards.i_th (i).lane = a_lane then
					Result.extend (i)
				end
				i := i + 1
			end
		end

	on_move: detachable PROCEDURE [INTEGER, INTEGER]
			-- Fired with (card id, new lane) after a move.

feature -- Element change

	add_lane (a_title: READABLE_STRING_GENERAL): INTEGER
		local
			l: STRING_32
			lane: SW_KANBAN_LANE
		do
			create l.make_from_string_general (a_title)
			lane_titles.extend (l)
			Result := lane_titles.count
			create lane.make_on (Current, Result)
			put (lane.growing)
		ensure
			grew: lane_count = old lane_count + 1
		end

	add_card (a_lane: INTEGER; a_title: READABLE_STRING_GENERAL): INTEGER
		require
			lane_known: a_lane >= 1 and a_lane <= lane_count
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_title)
			cards.extend ([l, a_lane])
			Result := cards.count
		ensure
			grew: cards.count = old cards.count + 1
			placed: cards.i_th (Result).lane = a_lane
		end

	move_card (a_card, a_lane: INTEGER)
		require
			card_known: a_card >= 1 and a_card <= cards.count
			lane_known: a_lane >= 1 and a_lane <= lane_count
		do
			if cards.i_th (a_card).lane /= a_lane then
				cards.i_th (a_card).lane := a_lane
				if attached on_move as a then
					a.call (a_card, a_lane)
				end
			end
		ensure
			moved: cards.i_th (a_card).lane = a_lane
		end

	set_on_move (a_action: PROCEDURE [INTEGER, INTEGER])
		do
			on_move := a_action
		ensure
			set: on_move = a_action
		end

invariant
	registries_attached: cards /= Void and lane_titles /= Void
	lanes_hold_cards: across cards as c all
		c.lane >= 1 and c.lane <= lane_count end

end
