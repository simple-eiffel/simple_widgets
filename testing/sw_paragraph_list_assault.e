note
	description: "[
		Assault on SW_PARAGRAPH_LIST: variable heights measured not
		guessed, virtualised painting, the selection set with its
		anchor, mutation keeping every parallel list honest, editing in
		place that reflows live and restores on cancel, and both text
		engines headless.
	]"

class
	SW_PARAGRAPH_LIST_ASSAULT

inherit
	TEST_SET_BASE

feature -- Measurement

	test_heights_follow_the_text
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (3)
			l.put_text (2, long_text)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			assert ("laid out", l.is_laid_out)
			assert ("a long paragraph is taller", l.item_height (2) > 2.0 * l.item_height (1))
			assert ("short ones match", l.item_height (1) = l.item_height (3))
			assert_reals_equal ("tops stack with the gap", l.item_top (1) + l.item_height (1) + l.item_gap, l.item_top (2), 1.0e-9)
			assert ("content is the whole stack", l.content_height = l.item_top (3) + l.item_height (3))
		end

	test_bands_add_exactly
		local
			l: SW_PARAGRAPH_LIST
			h0: REAL_64
		do
			l := filled (2)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			h0 := l.item_height (1)
			l.set_band_above (1, 24.0)
			l.set_band_below (1, 10.0)
			l.arrange (plain_painter)
			assert_reals_equal ("bands add their height", h0 + 34.0, l.item_height (1), 1.0e-9)
			assert ("the neighbour is untouched", l.item_height (2) = h0)
		end

	test_virtualisation_and_hit_test
		local
			l: SW_PARAGRAPH_LIST
			i: INTEGER
		do
			l := filled (200)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			assert ("taller than the viewport", l.content_height > 300.0)
			assert_integers_equal ("starts at the top", 1, l.first_visible)
			assert ("only a band is visible", l.last_visible < 40)
			assert_integers_equal ("first pixel is item 1", 1, l.item_at (0.0))
			assert_integers_equal ("above the widget is nothing", 0, l.item_at (-1.0))
			assert_integers_equal ("below the viewport is nothing", 0, l.item_at (300.0))
			l.scroll_to (l.max_scroll)
			l.arrange (plain_painter)
			assert_integers_equal ("scrolled to the end", 200, l.last_visible)
			assert ("the first is gone", l.first_visible > 150)
			i := l.item_at (299.0)
			assert_integers_equal ("the last pixel is the last item", 200, i)
			l.scroll_to_item (1)
			assert_integers_equal ("back to the top", 1, l.first_visible)
		end

	test_wheel_clamps
		local
			l: SW_PARAGRAPH_LIST
			i: INTEGER
		do
			l := filled (30)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			from i := 1 until i > 100 loop
				if l.handle_wheel (-120) then end
				i := i + 1
			end
			assert ("bottom clamped", l.scroll_y = l.max_scroll)
			from i := 1 until i > 200 loop
				if l.handle_wheel (120) then end
				i := i + 1
			end
			assert ("top clamped", l.scroll_y = 0.0)
		end

feature -- Selection

	test_selection_set_and_anchor
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (10)
			l.set_on_select (agent record_select)
			l.select_only (3)
			assert_integers_equal ("anchor", 3, l.selected_index)
			assert_integers_equal ("one selected", 1, l.selection_count)
			assert_integers_equal ("host told", 3, heard)
			l.toggle_select (5)
			assert ("three still in", l.is_selected (3))
			assert ("five joined", l.is_selected (5))
			assert_integers_equal ("anchor moved", 5, l.selected_index)
			l.select_range (5, 8)
			assert_integers_equal ("three plus five to eight", 5, l.selection_count)
			assert_integers_equal ("anchor kept by a range", 5, l.selected_index)
			l.toggle_select (5)
			assert_false ("five left", l.is_selected (5))
			assert_integers_equal ("indices ascend", 3, l.selected_indices.first)
			assert_integers_equal ("indices end", 8, l.selected_indices.last)
			l.clear_selection
			assert_integers_equal ("nothing", 0, l.selection_count)
			assert_integers_equal ("no anchor", 0, l.selected_index)
		end

	test_click_selects_and_keys_move
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (40)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			if l.handle_click (100.0, l.item_top (2) + 2.0) then end
			assert_integers_equal ("clicked two", 2, l.selected_index)
			l.handle_key (40, False)
			assert_integers_equal ("down", 3, l.selected_index)
			l.handle_key (35, False)
			assert_integers_equal ("end", 40, l.selected_index)
			l.arrange (plain_painter)
			assert ("scrolled to it", l.last_visible = 40)
			l.handle_key (36, False)
			assert_integers_equal ("home", 1, l.selected_index)
			l.handle_key (40, True)
			l.handle_key (40, True)
			assert_integers_equal ("shift-down grows the set", 3, l.selection_count)
			assert_integers_equal ("and moves the anchor", 3, l.selected_index)
		end

feature -- Mutation

	test_insert_remove_move_keep_lists_honest
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (5)
			l.select_only (3)
			l.insert (2, "new")
			assert_integers_equal ("six", 6, l.count)
			assert ("inserted where asked", l.text_of (2).same_string ("new"))
			assert_integers_equal ("anchor shifted down", 4, l.selected_index)
			assert ("still selected", l.is_selected (4))
			l.remove (1)
			assert_integers_equal ("five again", 5, l.count)
			assert_integers_equal ("anchor shifted up", 3, l.selected_index)
			l.move (3, 1)
			assert_integers_equal ("anchor travelled", 1, l.selected_index)
			assert ("flag travelled", l.is_selected (1))
			assert ("text travelled", l.text_of (1).same_string ("paragraph 3"))
			l.move (1, 5)
			assert_integers_equal ("anchor travelled back down", 5, l.selected_index)
			l.remove (5)
			assert_integers_equal ("removing the anchor clears it", 0, l.selected_index)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			assert ("re-measured after every change", l.is_laid_out)
			l.wipe_out
			assert_integers_equal ("empty", 0, l.count)
			assert ("nothing to lay out", l.content_height = 0.0)
		end

	test_put_text_reflows
		local
			l: SW_PARAGRAPH_LIST
			h0: REAL_64
		do
			l := filled (2)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			h0 := l.item_height (1)
			l.put_text (1, long_text)
			l.arrange (plain_painter)
			assert ("taller now", l.item_height (1) > h0)
			assert ("the second moved down", l.item_top (2) > h0 + l.item_gap)
		end

feature -- Editing

	test_edit_in_place_reflows_and_commits
		local
			l: SW_PARAGRAPH_LIST
			h0: REAL_64
		do
			l := filled (3)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			h0 := l.item_height (2)
			l.set_on_edit_change (agent record_change)
			l.set_on_edit_commit (agent record_commit)
			l.begin_edit (2)
			assert ("editing", l.is_editing)
			assert_integers_equal ("on two", 2, l.editing_index)
			assert_integers_equal ("selected it", 2, l.selected_index)
			assert ("the editor has the text", attached l.editor as e and then e.text.same_string ("paragraph 2"))
			l.arrange (plain_painter)
			assert ("editor seated inside the item", attached l.editor as e2 and then
				e2.y + e2.Pad_y >= l.item_top (2) and then e2.x < 100.0)
			assert ("widget_at finds the editor", attached l.editor as e3 and then
				l.widget_at (e3.x + 5.0, e3.y + 5.0) = e3)
				-- type a long tail through the list's own key door
			type_into (l, " tail")
			assert ("the item followed the keystrokes, at the END", l.text_of (2).same_string ("paragraph 2 tail"))
			type_into (l, long_text)
			assert ("host heard live", heard_change > 0)
			l.arrange (plain_painter)
			assert ("and it reflowed taller", l.item_height (2) > h0)
			l.end_edit (True)
			assert_false ("down", l.is_editing)
			assert ("host got the commit", committed.count > 20)
			assert ("editor gone", l.editor = Void)
		end

	test_edit_cancel_restores
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (2)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			l.begin_edit (1)
			type_into (l, " changed")
			assert ("changed while editing", l.text_of (1).same_string ("paragraph 1 changed"))
			l.handle_char (27)
			assert_false ("escape ended it", l.is_editing)
			assert ("and restored the text", l.text_of (1).same_string ("paragraph 1"))
		end

	test_click_elsewhere_commits
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (3)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (plain_painter)
			l.set_on_edit_commit (agent record_commit)
			l.begin_edit (1)
			type_into (l, "!")
			if l.handle_click (100.0, l.item_top (3) + 2.0) then end
			assert_false ("edit ended by the click", l.is_editing)
			assert ("committed", committed.same_string ("paragraph 1!"))
			assert_integers_equal ("and the click selected", 3, l.selected_index)
		end

	test_remove_while_editing_drops_editor
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (3)
			l.begin_edit (2)
			l.remove (2)
			assert_false ("editor dropped", l.is_editing)
			assert_integers_equal ("two left", 2, l.count)
		end

feature -- Shaped path

	test_shaped_measurement_and_paint
		local
			l: SW_PARAGRAPH_LIST
			s: STRING_32
		do
			l := filled (3)
			create s.make_from_string ("abc ")
			s.append (shalom)
			s.append ("%N")
			s.append (long_text)
			l.put_text (2, s)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.set_gutter_renderer (agent count_gutter)
			l.set_wash_of (agent wash_for)
			l.arrange (shaped_painter)
			assert ("shaped", l.is_shaped_layout)
			assert ("two pieces stack taller", l.item_height (2) > 2.5 * l.item_height (1))
			gutters := 0
			l.draw (shaped_painter)
			assert_integers_equal ("gutter drawn for each visible item", 3, gutters)
			l.arrange (plain_painter)
			assert_false ("toy again on a plain painter", l.is_shaped_layout)
			l.draw (plain_painter)
			l.begin_edit (2)
			l.arrange (shaped_painter)
			l.draw (shaped_painter)
			assert ("painted through both engines and the editor", True)
		end

	test_gutter_only_for_visible
		local
			l: SW_PARAGRAPH_LIST
		do
			l := filled (200)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.set_gutter_renderer (agent count_gutter)
			l.arrange (plain_painter)
			gutters := 0
			l.draw (plain_painter)
			assert ("a band, not the world", gutters > 0 and gutters < 40)
			assert_integers_equal ("exactly the visible band", l.last_visible - l.first_visible + 1, gutters)
		end

feature -- Pointing (GW-08)

	test_gw08_character_at_names_the_character
			-- The point inside a character's box is that character of that
			-- paragraph; a gutter, a line's empty end, the gap between
			-- paragraphs and the paragraph under the editor are no character.
		local
			l: SW_PARAGRAPH_LIST
			b, w: TUPLE [x, y, width, height: REAL_64]
			cy: REAL_64
		do
			l := filled (3)
			l.put_text (2, genesis_kjv)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (shaped_painter)
			assert_integers_equal ("one box for one character", 1, l.text_boxes (2, 7, 8).count)
			b := l.text_boxes (2, 7, 8).first
			cy := b.y + b.height / 2.0
			assert_integers_equal ("the point in the box of b is b", 8, l.character_at (b.x + b.width / 2.0, cy))
			assert_integers_equal ("of paragraph 2", 2, l.item_at (cy))
			assert_integers_equal ("the gutter is no character", 0, l.character_at (l.x + 4.0, cy))
			w := l.text_boxes (2, 7, 16).first
			assert_true ("the word's box holds the letter's", w.width > 3.0 * b.width and w.x <= b.x)
			assert_integers_equal ("caret before the first character", 0,
				l.caret_offset_at (l.item_text_x (2) - 3.0, cy))
			assert_integers_equal ("past a short line's end is no character", 0,
				l.character_at (l.item_text_x (1) + 300.0, l.text_top (1) + 6.0))
			assert_integers_equal ("the gap between paragraphs is no character", 0,
				l.character_at (b.x + 1.0, l.item_top (2) - l.item_gap / 2.0))
			l.begin_edit (2)
			l.arrange (shaped_painter)
			assert_integers_equal ("the editor answers over its paragraph, not the list", 0,
				l.character_at (b.x + b.width / 2.0, cy))
			l.end_edit (False)
		end

	test_gw08_hover_dwell_and_scroll_are_heard
			-- `on_hover' hears the character under the pointer change (and
			-- only a change), `on_dwell' hears a rest on a character,
			-- `on_scroll' hears a real scroll, and a wheel turn under a
			-- resting pointer re-reads the character under it.
		local
			l: SW_PARAGRAPH_LIST
			b: TUPLE [x, y, width, height: REAL_64]
			cx, cy: REAL_64
			n: INTEGER
		do
			l := filled (40)
			l.put_text (2, genesis_kjv)
			l.set_bounds (0.0, 0.0, 400.0, 300.0)
			l.arrange (shaped_painter)
			assert_integers_equal ("nobody listens: no dwell wanted", 0, l.dwell_ms)
			l.set_on_hover (agent record_hover)
			l.set_on_dwell (agent record_dwell)
			l.set_on_scroll (agent record_scroll)
			assert_integers_equal ("a listener: the word hover card's 400 ms", 400, l.dwell_ms)
			b := l.text_boxes (2, 7, 8).first
			cx := b.x + b.width / 2.0
			cy := b.y + b.height / 2.0
			hover_events := 0
			l.set_hovered (True)
			l.set_hover_point (cx, cy)
			assert_integers_equal ("heard once", 1, hover_events)
			assert_true ("on b of paragraph 2", hover_heard_item = 2 and hover_heard_character = 8)
			l.set_hover_point (cx + 0.25, cy)
			assert_integers_equal ("the same character is silent", 1, hover_events)
			l.set_hover_point (l.x + 4.0, cy)
			assert_true ("leaving the text is heard as (0, 0)",
				hover_events = 2 and hover_heard_item = 0 and hover_heard_character = 0)
			dwell_events := 0
			l.handle_dwell (cx, cy)
			assert_true ("a rest on b is heard", dwell_events = 1 and dwell_heard_item = 2 and dwell_heard_character = 8)
			l.handle_dwell (l.x + 4.0, cy)
			assert_integers_equal ("a rest on the gutter is not", 1, dwell_events)
			l.set_dwell_delay (250)
			assert_integers_equal ("the delay is the host's", 250, l.dwell_ms)
			l.set_hover_point (cx, cy)
			n := hover_events
			scroll_events := 0
			assert_true ("the wheel scrolls", l.handle_wheel (-120))
			assert_true ("the scroll is heard", scroll_events = 1 and scroll_heard = l.scroll_y and l.scroll_y > 0.0)
			assert_integers_equal ("the text moved under the pointer: heard", n + 1, hover_events)
			l.scroll_to (l.scroll_y)
			assert_integers_equal ("no move, no scroll heard", 1, scroll_events)
			l.set_hovered (False)
			assert_true ("leaving the list leaves the text", hover_heard_item = 0 and l.hover_character = 0)
		end

	test_gw08_window_times_the_dwell
			-- Through the window's own event path: a pointer move over a
			-- character arms the shell's dwell timer and is heard; the timer's
			-- event reaches the list as a rest on that character; leaving
			-- cancels it. Under a dialog the dwell goes nowhere - not to the
			-- list and not to the app's shell-event handler.
		local
			w: SW_WINDOW
			l: SW_PARAGRAPH_LIST
			d: SW_DIALOG
			b: TUPLE [x, y, width, height: REAL_64]
			cx, cy: INTEGER
		do
			create w.make ("dwell", 0, 0, 600, 400, create {SW_THEME}.make_light)
			l := filled (5)
			l.put_text (2, genesis_kjv)
			w.set_root (l)
			w.request_render
			l.set_on_hover (agent record_hover)
			l.set_on_dwell (agent record_dwell)
			b := l.text_boxes (2, 7, 8).first
			cx := (b.x + b.width / 2.0).truncated_to_integer
			cy := (b.y + b.height / 2.0).truncated_to_integer
			dwell_events := 0
			w.dispatch (13, cx, cy)
			assert_true ("the list is under the pointer", l.is_hovered)
			assert_true ("the move was heard on b", hover_heard_item = 2 and hover_heard_character = 8)
			assert_true ("the window armed the dwell", w.is_dwell_timer_armed)
			w.dispatch (w.Event_dwell, 0, 0)
			assert_true ("the rest reached the list", dwell_events = 1 and dwell_heard_item = 2 and dwell_heard_character = 8)
			w.dispatch (14, 0, 0)
			assert_false ("leaving cancels it", w.is_dwell_timer_armed)
			assert_true ("and leaves the text", hover_heard_item = 0)
			shell_events := 0
			w.set_on_shell_event (agent record_shell)
			w.dispatch (13, cx, cy)
			create d.make ({SW_DIALOG}.Kind_info, "Title", "Body")
			w.show_dialog (d)
			w.dispatch (w.Event_dwell, 0, 0)
			assert_integers_equal ("a dialog swallows the dwell", 1, dwell_events)
			assert_integers_equal ("and keeps it from the app's shell handler", 0, shell_events)
			w.close_dialog
			w.dispatch (14, 0, 0)
			assert_false ("disarmed at the end", w.is_dwell_timer_armed)
		end

feature -- Hover card (GW-09)

	test_gw09_dwell_opens_a_card_at_the_word
			-- Through the window's own event path: a dwell on "beginning"
			-- opens the builder's card, anchored at the whole word and
			-- seated below it inside the window. It stays while the pointer
			-- is on the word or on the card, its button takes a click, a
			-- second rest on the same word keeps the same card, a rest on
			-- another word replaces it, and off both it closes after the
			-- grace (and not before).
		local
			w: SW_WINDOW
			l: SW_PARAGRAPH_LIST
			b, word: TUPLE [x, y, width, height: REAL_64]
			cx, cy, kx, ky: INTEGER
			c1: detachable SW_HOVER_CARD
		do
			create w.make ("card", 0, 0, 700, 420, create {SW_THEME}.make_light)
			l := filled (6)
			l.put_text (2, genesis_kjv)
			w.set_root (l)
			w.request_render
			cards_built := 0
			card_clicks := 0
			l.set_hover_card_builder (agent build_card)
			assert_integers_equal ("a builder alone wants the dwell", 400, l.dwell_ms)
			assert_true ("the word around b is beginning",
				l.word_at (2, 8).lo = 7 and l.word_at (2, 8).hi = 16)
			b := l.text_boxes (2, 7, 8).first
			word := l.text_boxes (2, 7, 16).first
			cx := (b.x + b.width / 2.0).truncated_to_integer
			cy := (b.y + b.height / 2.0).truncated_to_integer
			w.dispatch (13, cx, cy)
			w.dispatch (w.Event_dwell, 0, 0)
			assert_true ("the dwell opened a card", w.has_hover_card)
			c1 := w.hover_card
			if attached c1 as al_c then
				assert_true ("anchored at the whole word",
					al_c.anchor_x = word.x and al_c.anchor_width = word.width and al_c.anchor_y = word.y)
				assert_true ("seated below the word", w.hover_card_py >= word.y + word.height)
				assert_true ("inside the window", w.hover_card_px >= 0.0
					and w.hover_card_px + w.hover_card_pw <= 700.0 and w.hover_card_py + w.hover_card_ph <= 420.0)
			end
			w.set_hover_card_grace_ms (0)
			w.dispatch (13, cx + 1, cy)
			w.dispatch (7, 0, 0)
			assert_true ("on the word it stays", w.has_hover_card)
			kx := (w.hover_card_px + w.hover_card_pw / 2.0).truncated_to_integer
			ky := (w.hover_card_py + 6.0).truncated_to_integer
			w.dispatch (13, kx, ky)
			w.dispatch (7, 0, 0)
			assert_true ("on the card it stays", w.has_hover_card)
			assert_false ("the page under it lets go of the pointer", l.is_hovered)
			if attached last_card_button as al_btn then
				w.dispatch (2, (al_btn.x + al_btn.width / 2.0).truncated_to_integer,
					(al_btn.y + al_btn.height / 2.0).truncated_to_integer)
				w.dispatch (10, (al_btn.x + al_btn.width / 2.0).truncated_to_integer,
					(al_btn.y + al_btn.height / 2.0).truncated_to_integer)
				assert_integers_equal ("the card's button took the click", 1, card_clicks)
			end
			assert_true ("and the card is still up", w.has_hover_card)
			w.dispatch (13, cx, cy)
			w.dispatch (w.Event_dwell, 0, 0)
			assert_true ("a rest on the same word keeps the same card", w.hover_card = c1)
			b := l.text_boxes (2, 17, 18).first
			w.dispatch (13, (b.x + b.width / 2.0).truncated_to_integer, (b.y + b.height / 2.0).truncated_to_integer)
			w.dispatch (w.Event_dwell, 0, 0)
			assert_true ("a rest on God opens God's card", w.has_hover_card and w.hover_card /= c1)
			w.set_hover_card_grace_ms (300)
			w.dispatch (13, 600, 400)
			w.dispatch (7, 0, 0)
			assert_true ("off both, the grace has not run yet", w.has_hover_card)
			w.set_hover_card_grace_ms (0)
			w.dispatch (13, 600, 401)
			w.dispatch (7, 0, 0)
			assert_false ("off both, after the grace it closes", w.has_hover_card)
			w.dispatch (13, 650, 405)
			w.dispatch (14, 0, 0)
		end

	test_gw09_card_closes_on_click_escape_leave_and_modal
			-- A click off the card closes it AND still reaches the page;
			-- Escape, the pointer leaving the window and a dialog opening
			-- each close it too.
		local
			w: SW_WINDOW
			l: SW_PARAGRAPH_LIST
			cx, cy: INTEGER
			b: TUPLE [x, y, width, height: REAL_64]
			d: SW_DIALOG
		do
			create w.make ("card", 0, 0, 700, 420, create {SW_THEME}.make_light)
			l := filled (6)
			l.put_text (2, genesis_kjv)
			w.set_root (l)
			w.request_render
			l.set_hover_card_builder (agent build_card)
			b := l.text_boxes (2, 7, 8).first
			cx := (b.x + b.width / 2.0).truncated_to_integer
			cy := (b.y + b.height / 2.0).truncated_to_integer
			w.dispatch (13, cx, cy)
			w.dispatch (w.Event_dwell, 0, 0)
			assert_true ("up", w.has_hover_card)
			w.dispatch (2, 30, (l.text_top (6) + 4.0).truncated_to_integer)
			w.dispatch (10, 30, (l.text_top (6) + 4.0).truncated_to_integer)
			assert_false ("a click off the card closes it", w.has_hover_card)
			assert_integers_equal ("and the click still selected paragraph 6", 6, l.selected_index)
			w.dispatch (13, cx, cy)
			w.dispatch (w.Event_dwell, 0, 0)
			w.dispatch (3, 27, 0)
			assert_false ("Escape closes it", w.has_hover_card)
			w.dispatch (13, cx, cy)
			w.dispatch (w.Event_dwell, 0, 0)
			w.dispatch (14, 0, 0)
			assert_false ("leaving the window closes it", w.has_hover_card)
			w.dispatch (13, cx, cy)
			w.dispatch (w.Event_dwell, 0, 0)
			create d.make ({SW_DIALOG}.Kind_info, "Title", "Body")
			w.show_dialog (d)
			assert_false ("a dialog closes it", w.has_hover_card)
			w.close_dialog
			w.dispatch (14, 0, 0)
		end

feature {NONE} -- Helpers

	filled (a_n: INTEGER): SW_PARAGRAPH_LIST
		local
			i: INTEGER
		do
			create Result.make (300.0)
			from i := 1 until i > a_n loop
				Result.add ("paragraph " + i.out)
				i := i + 1
			end
		end

	long_text: STRING_32
		do
			Result := {STRING_32} "In one-twelve CE a Roman governor sat down to write to his emperor about a problem he could not solve. The province he had been appointed to govern had a Christianity problem. The new sect was growing. Pagan temples were emptying. Civic-religious revenues were down."
		end

	shalom: STRING_32
		do
			create Result.make (4)
			Result.append_code (0x05E9)
			Result.append_code (0x05DC)
			Result.append_code (0x05D5)
			Result.append_code (0x05DD)
		end

	type_into (a_l: SW_PARAGRAPH_LIST; a_text: READABLE_STRING_GENERAL)
			-- Every character through the list's key door, as a user
			-- typing right after a double-click would.
		local
			i: INTEGER
		do
			from i := 1 until i > a_text.count loop
				a_l.handle_char (a_text.code (i).to_integer_32)
				i := i + 1
			end
		end

	count_gutter (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		do
			gutters := gutters + 1
			a_p.set_color (a_p.theme.accent)
			a_p.fill_rect (a_x, a_y, 4.0, a_h)
		end

	wash_for (a_i: INTEGER): NATURAL_32
		do
			if a_i \\ 2 = 0 then
				Result := 0xFAF1DD
			end
		end

feature {NONE} -- Capture

	heard: INTEGER
	heard_change: INTEGER
	gutters: INTEGER

	committed: STRING_32
		attribute
			create Result.make_empty
		end

	record_select (a_i: INTEGER)
		do
			heard := a_i
		end

	record_change (a_i: INTEGER; a_text: STRING_32)
		do
			heard_change := heard_change + 1
		end

	record_commit (a_i: INTEGER; a_text: STRING_32)
		do
			committed := a_text.twin
		end

	hover_events, hover_heard_item, hover_heard_character: INTEGER
	dwell_events, dwell_heard_item, dwell_heard_character: INTEGER
	scroll_events, shell_events: INTEGER
	scroll_heard: REAL_64

	record_hover (a_item, a_character: INTEGER)
		do
			hover_events := hover_events + 1
			hover_heard_item := a_item
			hover_heard_character := a_character
		end

	record_dwell (a_item, a_character: INTEGER)
		do
			dwell_events := dwell_events + 1
			dwell_heard_item := a_item
			dwell_heard_character := a_character
		end

	record_scroll (a_y: REAL_64)
		do
			scroll_events := scroll_events + 1
			scroll_heard := a_y
		end

	record_shell (a_type, a_x, a_y: INTEGER)
		do
			shell_events := shell_events + 1
		end

	genesis_kjv: STRING_32
		do
			Result := {STRING_32} "In the beginning God created the heaven and the earth. And the earth was without form, and void."
		end

	cards_built, card_clicks: INTEGER
	last_card_button: detachable SW_BUTTON

	build_card (a_item, a_character: INTEGER): detachable SW_HOVER_CARD
			-- A small word card: the word, a gloss, a button.
		local
			col: SW_COLUMN
			btn: SW_BUTTON
		do
			cards_built := cards_built + 1
			create col.make
			col.put (create {SW_LABEL}.make_body ("word " + a_character.out))
			col.put (create {SW_LABEL}.make_ui ("gloss"))
			create btn.make ("Word Study", agent do card_clicks := card_clicks + 1 end)
			col.put (btn)
			last_card_button := btn
			create Result.make (col, 220.0)
		end

feature {NONE} -- Fixture

	plain_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
		once
			create surf.make (600, 400)
			create ctx.make (surf)
			create th.make_light
			create Result.make (ctx, th)
		end

	shaped_painter: SW_PAINTER
		local
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			kit: SW_SHAPING
		once
			create surf.make (600, 400)
			create ctx.make (surf)
			create th.make_light
			create kit.make
			kit.set_theme_faces (th)
			create Result.make (ctx, th)
			Result.set_shaping (kit)
		end

end
