note
	description: "[
		A notice that offers an action, and shortcuts that yield to typing
		(0.56.0, simple_bible's Favorites Undo): a click on a notice's action
		runs it once and closes the notice; a plain notice offers none; a
		yielding accelerator steps aside while an editable text box holds the
		keyboard (Ctrl+Z there undoes the typing) and fires everywhere else;
		a plain accelerator still fires inside a text box.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SW_NOTICE_ACTION_ASSAULT

inherit
	TEST_SET_BASE

feature -- Notices

	test_a_notices_action_runs_once_and_closes_it
		local
			w: SW_WINDOW
			l_spot: TUPLE [x, y, w, h: REAL_64; toast: TUPLE [txt: STRING_32; tkind: INTEGER; life: INTEGER; act_label: STRING_32; act: detachable PROCEDURE]]
		do
			ran := 0
			create w.make ("notice", 0, 0, 600, 300, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make ("page", {SW_PAINTER}.Role_ui, 14.0, False))
			w.toast_with_action ("Added John 3:16 to Sermons.", 1, "Undo", agent note_run)
			w.request_render
			assert_integers_equal ("its action is drawn", 1, w.toast_action_spots.count)
			l_spot := w.toast_action_spots.first
			w.dispatch (2, (l_spot.x + l_spot.w / 2.0).truncated_to_integer, (l_spot.y + l_spot.h / 2.0).truncated_to_integer)
			assert_integers_equal ("a click runs it", 1, ran)
			assert_true ("and the notice goes", w.toast_action_at ((l_spot.x + 2.0).truncated_to_integer, (l_spot.y + 2.0).truncated_to_integer) = Void)
			w.request_render
			assert_integers_equal ("not drawn again", 0, w.toast_action_spots.count)
			w.dispatch (2, (l_spot.x + l_spot.w / 2.0).truncated_to_integer, (l_spot.y + l_spot.h / 2.0).truncated_to_integer)
			assert_integers_equal ("once only", 1, ran)
		end

	test_a_plain_notice_offers_no_action
		local
			w: SW_WINDOW
		do
			create w.make ("notice", 0, 0, 600, 300, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make ("page", {SW_PAINTER}.Role_ui, 14.0, False))
			w.toast ("Saved.", 2)
			w.request_render
			assert_integers_equal ("no action drawn", 0, w.toast_action_spots.count)
		end

feature -- Shortcuts that yield to typing

	test_a_yielding_shortcut_steps_aside_for_typing
		local
			w: SW_WINDOW
			r: SW_ROW
			box, shown: SW_TEXT_BOX
		do
			ran := 0
			plain_ran := 0
			create w.make ("keys", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create box.make_single_line ("typing here")
			create shown.make_single_line ("read only")
			shown.set_read_only (True)
			create r.make
			r.put (box.growing)
			r.put (shown.growing)
			w.set_root (r)
			w.request_render
			w.register_accelerator_yielding (90, True, False, False, agent note_run)
			w.register_accelerator (68, True, False, False, agent note_plain)
			w.give_focus (box)
			assert_true ("an editable box takes typing", box.takes_typing)
			w.simulate_key_down (90, True, False, False)
			assert_integers_equal ("Ctrl+Z in a text box is the box's own", 0, ran)
			w.simulate_key_down (68, True, False, False)
			assert_integers_equal ("a plain shortcut still fires there", 1, plain_ran)
			w.give_focus (shown)
			assert_false ("a read-only box does not", shown.takes_typing)
			w.simulate_key_down (90, True, False, False)
			assert_integers_equal ("elsewhere it is the program's", 1, ran)
			w.simulate_key_down (90, True, False, True)
			assert_integers_equal ("only under its own modifiers", 1, ran)
		end

feature {NONE} -- Fixture

	ran, plain_ran: INTEGER

	note_run
		do
			ran := ran + 1
		end

	note_plain
		do
			plain_ran := plain_ran + 1
		end

end
