note
	description: "[
		Carrying and dropping (0.55.0, simple_bible's Favorites): a selection is
		dragged out of a document and dropped where the button is released; Pick
		up (`start_pick') follows the pointer with no button held and a click
		drops it; middle-click lifts a selection with its card; Escape cancels;
		in a tree the folder under the pointer is lit, a closed folder springs
		open after a rest and closes again after the drop unless the item landed
		inside it, a folder's arrow opens it without dropping, the New folder row
		makes a folder, and a row is dragged to another folder; a tab springs
		open under a resting pick and the tab shown before returns. Every test
		drives the window's own dispatch (press 2, release 10, drag 9, move 13,
		heartbeat 7, middle-click 17, key 3) on an offscreen window.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SW_CARRY_DROP_ASSAULT

inherit
	TEST_SET_BASE

feature -- Carrying a selection

	test_a_selection_dragged_out_drops_in_the_folder_under_the_release
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
			px, py: INTEGER
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			v.select_range (1, 4, 1, 14)
			px := point_in (v, 1, 6).x
			py := point_in (v, 1, 6).y
			w.dispatch (2, px, py)
			assert_true ("a press on the selection keeps it", v.has_selection)
			assert_false ("and is not yet a pick", w.is_picking)
			w.dispatch (9, px + 30, py)
			assert_true ("a drag past the distance lifts it", w.is_picking)
			assert_true ("to drop on release", w.pick_by_drag)
			assert_strings_equal ("with its card", "For God so...", w.pick_card)
			assert_true ("the selection stands", v.has_selection)
			w.dispatch (9, row_x (t), row_y (t, 2))
			assert_true ("Grace is lit", attached t.drop_folder as al_f and then al_f.same_string ("Grace"))
			w.dispatch (10, row_x (t), row_y (t, 2))
			assert_false ("the release drops it", w.is_picking)
			assert_integers_equal ("once", 1, drops)
			assert_true ("the quote", attached {STRING_32} dropped_pebble as al_p and then al_p.same_string ("quote"))
			assert_true ("into Grace", attached dropped_folder as al_d and then al_d.same_string ("Grace"))
			assert_false ("not a new folder", dropped_new)
		end

	test_a_press_on_the_selection_that_never_moves_clears_it
			-- The ordinary click keeps its meaning: a new empty selection.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
			px, py: INTEGER
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			v.select_range (1, 4, 1, 14)
			px := point_in (v, 1, 6).x
			py := point_in (v, 1, 6).y
			w.dispatch (2, px, py)
			w.dispatch (9, px + 2, py)
			w.dispatch (10, px + 2, py)
			assert_false ("a click on the selection clears it", v.has_selection)
			assert_false ("nothing lifted", w.is_picking)
			assert_integers_equal ("nothing dropped", 0, drops)
		end

	test_a_drop_off_every_hole_goes_nowhere
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
			px, py: INTEGER
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			v.select_range (1, 4, 1, 14)
			px := point_in (v, 1, 6).x
			py := point_in (v, 1, 6).y
			w.dispatch (2, px, py)
			w.dispatch (9, px + 30, py + 40)
			w.dispatch (10, px + 30, py + 40)
			assert_false ("the pick is over", w.is_picking)
			assert_integers_equal ("dropped in the document: nowhere", 0, drops)
			assert_true ("the source is never changed", v.has_selection)
		end

	test_middle_click_lifts_the_selection_with_its_card
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			v.select_range (1, 4, 1, 14)
			w.dispatch (17, point_in (v, 1, 6).x, point_in (v, 1, 6).y)
			assert_true ("lifted", w.is_picking)
			assert_false ("no button held: a click drops it", w.pick_by_drag)
			assert_strings_equal ("its card", "For God so...", w.pick_card)
			w.dispatch (13, row_x (t), row_y (t, 1))
			w.dispatch (2, row_x (t), row_y (t, 1))
			assert_true ("into Bookmarks", attached dropped_folder as al_d and then al_d.same_string ("Bookmarks"))
		end

feature -- Pick up

	test_pick_up_follows_the_pointer_and_a_click_drops
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "For God so...", 20, 20)
			assert_true ("picking", w.is_picking)
			w.dispatch (13, row_x (t), row_y (t, 2))
			w.dispatch (10, row_x (t), row_y (t, 2))
			assert_true ("a stray release does not drop a Pick up", w.is_picking)
			w.dispatch (2, row_x (t), row_y (t, 2))
			assert_false ("the click drops it", w.is_picking)
			assert_true ("into Grace", attached dropped_folder as al_d and then al_d.same_string ("Grace"))
		end

	test_escape_and_right_click_cancel
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, row_x (t), row_y (t, 2))
			w.dispatch (3, 27, 0)
			assert_false ("Escape cancels", w.is_picking)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (11, row_x (t), row_y (t, 2))
			assert_false ("a right-click cancels", w.is_picking)
			assert_integers_equal ("nothing dropped", 0, drops)
			assert_true ("the tree put its lights away", t.drop_folder = Void and t.new_row_at = 0)
		end

feature -- Composed sources and holes (simple_gui 1q)

	test_hooked_widgets_pick_by_drag_and_by_secondary_click
			-- 2026-11-09: plain widgets made a source and a hole with agents, not
			-- subclasses. A press that moves lifts the pebble and the release over
			-- the hole drops it; a secondary click lifts it and a click drops it; a
			-- drop where nothing takes it is told as a cancel.
		local
			w: SW_WINDOW
			l_column: SW_COLUMN
			l_source, l_hole: SW_LABEL
			l_got, l_cancels: CELL [INTEGER]
			sx, sy, hx, hy: INTEGER
		do
			create l_got.put (0)
			create l_cancels.put (0)
			w := new_window
			create l_source.make_ui ("A note")
			create l_hole.make_ui ("Takes text")
			l_source.set_pick_gestures (True, True)
			l_source.set_pebble_hook (agent (x, y: REAL_64): detachable ANY do Result := {STRING_32} "note" end)
			l_hole.set_drop_hooks (agent (p: ANY; x, y: REAL_64): BOOLEAN do Result := attached {STRING_32} p end,
				agent (p: ANY; x, y: REAL_64; c: CELL [INTEGER]) do c.put (c.item + 1) end (?, ?, ?, l_got))
			w.set_on_pick_cancelled (agent (c: CELL [INTEGER]) do c.put (c.item + 1) end (l_cancels))
			create l_column.make
			l_column.put (l_source)
			l_column.put (l_hole)
			w.set_root (l_column)
			w.request_render
			sx := (l_source.x + 10.0).truncated_to_integer
			sy := (l_source.y + l_source.height / 2.0).truncated_to_integer
			hx := (l_hole.x + 10.0).truncated_to_integer
			hy := (l_hole.y + l_hole.height / 2.0).truncated_to_integer
			w.dispatch (2, sx, sy)
			assert_false ("a press alone is no pick", w.is_picking)
			w.dispatch (9, sx + 30, sy)
			assert_true ("a press that moves lifts it", w.is_picking and w.pick_by_drag)
			w.dispatch (9, hx, hy)
			w.dispatch (10, hx, hy)
			assert_false ("the release drops it", w.is_picking)
			assert_integers_equal ("into the hole", 1, l_got.item)
			w.dispatch (11, sx, sy)
			assert_true ("a secondary click lifts it", w.is_picking and not w.pick_by_drag)
			w.dispatch (2, hx, hy)
			assert_integers_equal ("a click drops it", 2, l_got.item)
			assert_integers_equal ("no cancel yet", 0, l_cancels.item)
			w.dispatch (11, sx, sy)
			w.dispatch (2, sx, sy)
			assert_false ("dropped on the source, which takes nothing", w.is_picking)
			assert_integers_equal ("told as a cancel", 1, l_cancels.item)
			assert_integers_equal ("and the hole had nothing", 2, l_got.item)
		end

	test_a_hooked_widget_takes_files
			-- simple_gui 1q-b (2026-11-09): a plain widget takes files from the shell through a
			-- hook; without one it takes none.
		local
			l_label: SW_LABEL
			l_paths: ARRAYED_LIST [STRING_32]
			l_got: CELL [INTEGER]
		do
			create l_got.put (0)
			create l_label.make_ui ("Drop files here")
			assert_false ("no hook, no files", l_label.accepts_files)
			l_label.set_files_hook (agent (a_p: ARRAYED_LIST [STRING_32]; c: CELL [INTEGER]) do c.put (a_p.count) end (?, l_got))
			assert_true ("a hook takes files", l_label.accepts_files)
			create l_paths.make (2)
			l_paths.extend ("C:/notes.txt")
			l_paths.extend ("C:/sermon.md")
			l_label.receive_files (l_paths, 1.0, 1.0)
			assert_integers_equal ("both", 2, l_got.item)
		end

feature -- The tree as the hole

	test_a_resting_pick_springs_a_folder_that_closes_after
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
			i: INTEGER
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, row_x (t), row_y (t, 3))
			from i := 1 until i > t.Spring_ticks - 1 loop w.dispatch (7, 0, 0); i := i + 1 end
			assert_false ("not before its time", t.is_expanded (sermons))
			w.dispatch (7, 0, 0)
			assert_true ("Sermons springs open", t.is_expanded (sermons))
			w.dispatch (13, row_x (t), row_y (t, 2))
			w.dispatch (2, row_x (t), row_y (t, 2))
			assert_true ("dropped in Grace", attached dropped_folder as al_d and then al_d.same_string ("Grace"))
			assert_false ("Sermons closes again", t.is_expanded (sermons))
		end

	test_a_sprung_folder_stays_open_when_the_item_lands_in_it
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
			i: INTEGER
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, row_x (t), row_y (t, 3))
			from i := 1 until i > t.Spring_ticks loop w.dispatch (7, 0, 0); i := i + 1 end
			assert_true ("open", t.is_expanded (sermons))
				-- row 4 is now Mark 1, inside Sermons
			w.dispatch (13, row_x (t), row_y (t, 4))
			assert_true ("a row lights its folder", attached t.drop_folder as al_f and then al_f.same_string ("Sermons"))
			w.dispatch (2, row_x (t), row_y (t, 4))
			assert_true ("dropped in Sermons", attached dropped_folder as al_d and then al_d.same_string ("Sermons"))
			assert_true ("which stays open", t.is_expanded (sermons))
		end

	test_a_folders_arrow_opens_it_without_dropping
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, (t.x + 10.0).truncated_to_integer, row_y (t, 3))
			w.dispatch (2, (t.x + 10.0).truncated_to_integer, row_y (t, 3))
			assert_true ("Sermons opened", t.is_expanded (sermons))
			assert_true ("the pebble still in flight", w.is_picking)
			assert_integers_equal ("nothing dropped", 0, drops)
			w.cancel_pick
			assert_true ("a folder opened on purpose stays open", t.is_expanded (sermons))
		end

	test_a_folders_new_folder_button_makes_a_folder_inside_it
			-- No row moves under the pointer: the button stands on the lit
			-- folder's own row.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
			cx: INTEGER
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, row_x (t), row_y (t, 2))
			assert_integers_equal ("the top level's New folder row is last", 4, t.new_row_at)
			assert_false ("on Grace itself", t.is_on_new_folder_row)
			cx := (t.new_folder_chip_left + 20.0).truncated_to_integer
			w.dispatch (13, cx, row_y (t, 2))
			assert_true ("on Grace's New folder button", t.is_on_new_folder_row)
			assert_true ("for Grace", attached t.drop_folder as al_f and then al_f.same_string ("Grace"))
			w.dispatch (2, cx, row_y (t, 2))
			assert_true ("a new folder", dropped_new)
			assert_true ("in Grace", attached dropped_folder as al_d and then al_d.same_string ("Grace"))
			assert_integers_equal ("the row is gone", 0, t.new_row_at)
		end

	test_the_last_row_makes_a_folder_at_the_top_level
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, row_x (t), row_y (t, 4))
			assert_true ("on the New folder row", t.is_on_new_folder_row)
			assert_true ("of the top level", t.drop_folder = Void)
			w.dispatch (2, row_x (t), row_y (t, 4))
			assert_true ("a new folder", dropped_new)
			assert_true ("at the top level", dropped_folder = Void)
		end

	test_below_the_rows_is_the_top_level
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, row_x (t), row_y (t, 7))
			assert_true ("no folder lit", t.drop_folder = Void)
			assert_integers_equal ("New folder at the very end", 4, t.new_row_at)
			w.dispatch (2, row_x (t), row_y (t, 7))
			assert_integers_equal ("dropped", 1, drops)
			assert_true ("at the top level", dropped_folder = Void)
		end

	test_a_row_dragged_to_another_folder_moves
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			t.set_row_offer (agent (a_node: STRING_32): detachable TUPLE [pebble: ANY; card: STRING_32]
				do
					if not a_node.same_string ("Bookmarks") and not a_node.same_string ("Grace") and not a_node.same_string ("Sermons") then
						Result := [a_node, a_node]
					end
				end)
			t.expand_node (bookmarks)
				-- row 2 is John 3:16, inside Bookmarks; Grace is row 3
			w.dispatch (2, row_x (t), row_y (t, 2))
			w.dispatch (9, row_x (t), row_y (t, 2) + 10)
			assert_true ("the row lifts", w.is_picking and w.pick_by_drag)
			assert_strings_equal ("its card", "John 3:16", w.pick_card)
			w.dispatch (9, row_x (t), row_y (t, 3))
			w.dispatch (10, row_x (t), row_y (t, 3))
			assert_true ("John 3:16", attached {STRING_32} dropped_pebble as al_p and then al_p.same_string ("John 3:16"))
			assert_true ("into Grace", attached dropped_folder as al_d and then al_d.same_string ("Grace"))
		end

	test_a_drop_that_takes_rows_away_draws_safely
			-- Found in simple_bible (2026-11-03): a favorite moved into a closed folder leaves the tree
			-- a row shorter; the New folder row's place went stale and the next frame read past the
			-- last row.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [STRING_32]
			l_short: ARRAYED_LIST [STRING_32]
		do
			w := new_window
			v := document
			t := tree
			place (w, v, t)
			create l_short.make (1)
			l_short.extend (bookmarks)
			t.set_drop_handler (Void, agent (a_pebble: ANY; a_folder: detachable STRING_32; a_new: BOOLEAN; a_tree: SW_TREE [STRING_32]; a_window: SW_WINDOW; a_roots: ARRAYED_LIST [STRING_32])
				do
					a_tree.set_roots (a_roots)
					a_window.request_render
				end (?, ?, ?, t, w, l_short))
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, row_x (t), row_y (t, 3))
			w.dispatch (2, row_x (t), row_y (t, 3))
			w.request_render
			assert_integers_equal ("one row left", 1, t.visible.count)
			assert_integers_equal ("and no New folder row", 0, t.new_row_at)
		end

feature -- A tab under a pick

	test_a_tab_springs_open_and_the_one_before_returns
		local
			w: SW_WINDOW
			tabs: SW_TABS
			t: SW_TREE [STRING_32]
			l_label: SW_LABEL
			tx, ty, i: INTEGER
		do
			w := new_window
			t := tree
			create tabs.make
			create l_label.make ("Books", {SW_PAINTER}.Role_ui, 14.0, False)
			tabs.add_page ("Books", l_label)
			tabs.add_page ("Favorites", t)
			tabs.select_tab (1)
			w.set_root (tabs)
			w.request_render
			ty := (tabs.y + tabs.bar_h / 2.0).truncated_to_integer
			from tx := tabs.x.truncated_to_integer until tx > (tabs.x + tabs.width).truncated_to_integer or else tabs.tab_index_at (tx, ty) = 2 loop tx := tx + 2 end
			assert_integers_equal ("found the Favorites tab", 2, tabs.tab_index_at (tx + 4, ty))
			w.start_pick ({STRING_32} "quote", "", 20, 20)
			w.dispatch (13, tx + 4, ty)
			from i := 1 until i > tabs.Spring_beats loop w.dispatch (7, 0, 0); i := i + 1 end
			assert_integers_equal ("Favorites springs open", 2, tabs.selected_index)
			w.dispatch (3, 27, 0)
			assert_integers_equal ("and Books returns", 1, tabs.selected_index)
		end

feature {NONE} -- Fixture

	drops: INTEGER
	dropped_pebble: detachable ANY
	dropped_folder: detachable STRING_32
	dropped_new: BOOLEAN

	note_drop (a_pebble: ANY; a_folder: detachable STRING_32; a_new: BOOLEAN)
		do
			drops := drops + 1
			dropped_pebble := a_pebble
			dropped_folder := a_folder
			dropped_new := a_new
		end

	bookmarks: STRING_32
		once ("OBJECT") Result := {STRING_32} "Bookmarks" end

	grace: STRING_32
		once ("OBJECT") Result := {STRING_32} "Grace" end

	sermons: STRING_32
		once ("OBJECT") Result := {STRING_32} "Sermons" end

	john: STRING_32
		once ("OBJECT") Result := {STRING_32} "John 3:16" end

	mark: STRING_32
		once ("OBJECT") Result := {STRING_32} "Mark 1" end

	new_window: SW_WINDOW
		do
			drops := 0
			dropped_pebble := Void
			dropped_folder := Void
			dropped_new := False
			create Result.make ("carry", 0, 0, 800, 400, create {SW_THEME}.make_light)
		end

	document: SW_DOCUMENT_VIEW
			-- One paragraph whose selection offers "quote".
		local
			d: SIMPLE_DOCUMENT
		do
			create d.make
			d.add_paragraph ("For God so loved the world, that he gave his only begotten Son.").do_nothing
			create Result.make (300.0)
			Result.set_document (d)
			Result.set_selection_offer (agent: detachable TUPLE [pebble: ANY; card: STRING_32]
				do
					Result := [{STRING_32} "quote", {STRING_32} "For God so..."]
				end)
		end

	tree: SW_TREE [STRING_32]
			-- Bookmarks (John 3:16), Grace (empty), Sermons (Mark 1); folders
			-- by name.
		local
			l_roots: ARRAYED_LIST [STRING_32]
		do
			create Result.make (300.0)
			create l_roots.make (3)
			l_roots.extend (bookmarks)
			l_roots.extend (grace)
			l_roots.extend (sermons)
			Result.set_children (agent kids)
			Result.set_label (agent (s: STRING_32): STRING_32 do Result := s end)
			Result.set_folder_test (agent (s: STRING_32): BOOLEAN do Result := s = bookmarks or s = grace or s = sermons end)
			Result.set_drop_handler (Void, agent note_drop)
			Result.set_roots (l_roots)
		end

	kids (a_node: STRING_32): ARRAYED_LIST [STRING_32]
		do
			create Result.make (1)
			if a_node = bookmarks then
				Result.extend (john)
			elseif a_node = sermons then
				Result.extend (mark)
			end
		end

	place (a_window: SW_WINDOW; a_view: SW_DOCUMENT_VIEW; a_tree: SW_TREE [STRING_32])
			-- The document on the left, the tree on the right.
		local
			r: SW_ROW
		do
			create r.make
			r.put (a_view.growing)
			r.put (a_tree.growing)
			a_window.set_root (r)
			a_window.request_render
		end

	point_in (a_view: SW_DOCUMENT_VIEW; a_item, a_offset: INTEGER): TUPLE [x, y: INTEGER]
			-- The middle of character `a_offset' + 1 of item `a_item'.
		local
			b: TUPLE [x, y, width, height: REAL_64]
		do
			b := a_view.text_boxes (a_item, a_offset, a_offset + 1).first
			Result := [(b.x + b.width / 2.0).truncated_to_integer, (b.y + b.height / 2.0).truncated_to_integer]
		end

	row_x (a_tree: SW_TREE [STRING_32]): INTEGER
			-- Over a row's label, past any arrow.
		do
			Result := (a_tree.x + 60.0).truncated_to_integer
		end

	row_y (a_tree: SW_TREE [STRING_32]; a_row: INTEGER): INTEGER
			-- The middle of shown row `a_row'.
		do
			Result := (a_tree.y + (a_row - 0.5) * a_tree.Row_h).truncated_to_integer
		end

end
