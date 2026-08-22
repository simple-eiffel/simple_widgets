note
	description: "[
		Assault on SW_EVENT - the ACTION_SEQUENCE architecture read
		from ISE 25.02 source at Larry's direction: subscription
		order holds across kinds, kamikazes fire once in place and
		vanish, abort stops a round, pause buffers and resume
		replays, block drops cold - and the widget spine's four
		state queues fire on CHANGE only, with the button's click
		queue running beside the legacy single agent.
	]"

class
	SW_EVENT_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- Fixture

	log: STRING
		attribute
			create Result.make_empty
		end

	subject_event: detachable SW_EVENT [TUPLE]

	flags: ARRAYED_LIST [BOOLEAN]
		attribute
			create Result.make (4)
		end

	clicks: INTEGER

	mark (a_tag: STRING)
		do
			log.append (a_tag)
		end

	mark_and_abort (a_tag: STRING)
		do
			log.append (a_tag)
			if attached subject_event as e then
				e.abort
			end
		end

	note_flag (a_flag: BOOLEAN)
		do
			flags.extend (a_flag)
		end

	count_click
		do
			clicks := clicks + 1
		end

	reset
		do
			create log.make_empty
			create flags.make (4)
			clicks := 0
			subject_event := Void
		end

feature -- The queue itself

	test_event_order_and_permanence
		local
			e: SW_EVENT [TUPLE]
		do
			reset
			create e.make
			e.subscribe (agent mark ("A"))
			e.extend (agent mark ("B"))
			e.call ([])
			e.call ([])
			assert_strings_equal ("permanents fire in order, every round", "ABAB", log)
		end

	test_kamikaze_fires_in_place_once
		local
			e: SW_EVENT [TUPLE]
		do
			reset
			create e.make
			e.subscribe (agent mark ("A"))
			e.kamikaze (agent mark ("K"))
			e.subscribe (agent mark ("B"))
			assert_integers_equal ("three on the roll", 3, e.count)
			e.call ([])
			assert_strings_equal ("kamikaze fired IN ORDER, not appended", "AKB", log)
			assert_integers_equal ("and left the roll", 2, e.count)
			e.call ([])
			assert_strings_equal ("second round: permanents only", "AKBAB", log)
		end

	test_abort_stops_the_round
		local
			e: SW_EVENT [TUPLE]
		do
			reset
			create e.make
			subject_event := e
			e.subscribe (agent mark_and_abort ("A"))
			e.subscribe (agent mark ("B"))
			e.call ([])
			assert_strings_equal ("abort silenced the rest of the round", "A", log)
			e.call ([])
			assert_strings_equal ("but nobody was pruned", "AA", log)
		end

	test_pause_buffers_block_drops
		local
			e: SW_EVENT [TUPLE]
		do
			reset
			create e.make
			e.subscribe (agent mark ("X"))
			e.pause
			e.call ([])
			e.call ([])
			assert_strings_equal ("paused: nothing ran", "", log)
			e.resume
			assert_strings_equal ("resume replayed the backlog in order", "XX", log)
			e.block
			e.call ([])
			e.resume
			assert_strings_equal ("blocked calls are dropped cold", "XX", log)
			e.pause
			e.call ([])
			e.flush
			e.resume
			assert_strings_equal ("flush discards the buffer unreplayed", "XX", log)
		end

feature -- The spine speaks

	test_spine_fires_on_change_only
		local
			b: SW_BUTTON
		do
			reset
			create b.make ("probe", Void)
			b.on_focus_change.subscribe (agent note_flag)
			b.set_focused (True)
			b.set_focused (True)
			b.set_focused (False)
			assert_integers_equal ("two CHANGES, two firings", 2, flags.count)
			assert ("first datum was the arrival", flags.i_th (1))
			assert ("second datum was the departure", not flags.i_th (2))
		end

	test_sensitivity_speaks_through_the_queue
		local
			b: SW_BUTTON
		do
			reset
			create b.make ("probe", Void)
			b.on_enabled_change.subscribe (agent note_flag)
			b.set_enabled_when (agent disarmed)
			assert_integers_equal ("condition install disabled it: one firing", 1, flags.count)
			assert ("and the datum said so", not flags.i_th (1))
			b.refresh_enabling
			assert_integers_equal ("no change, no chatter", 1, flags.count)
		end

	disarmed: BOOLEAN
		do
			Result := False
		end

	test_button_queue_beside_legacy
		local
			b: SW_BUTTON
		do
			reset
			create b.make ("probe", agent count_click)
			b.click_actions.subscribe (agent mark ("P"))
			b.click_actions.kamikaze (agent mark ("K"))
			if b.handle_click (0.0, 0.0) then end
			if b.handle_click (0.0, 0.0) then end
			assert_integers_equal ("legacy single agent saw both", 2, clicks)
			assert_strings_equal ("queue ran beside it, kamikaze once", "PKP", log)
		end

end
