note
	description: "[
		1v-a: SW_GRID_VIEW. Layout (columns from the width, cell positions), pictures (one
		decode at a time; a missing file does not crash), selection rules, two-dimensional keys,
		filtering with model numbers, activation, and list items for screen readers.
	]"

class
	SW_GRID_VIEW_ASSAULT

inherit
	TEST_SET_BASE

feature -- Layout

	test_1v_a_columns_follow_the_width_and_cells_sit_on_a_lattice
		local
			g: SW_GRID_VIEW
		do
			g := grid_of (10, 600.0)
			assert_integers_equal ("four columns at 600", 4, g.columns)
			assert_reals_equal ("item 1 across", g.spacing, g.cell_x (1), 0.001)
			assert_reals_equal ("item 1 down", g.spacing, g.cell_y (1), 0.001)
			assert_reals_equal ("item 2 across", g.spacing + 128.0, g.cell_x (2), 0.001)
			assert_reals_equal ("item 5 wraps to column 1", g.spacing, g.cell_x (5), 0.001)
			assert_reals_equal ("item 5 is a row down", g.spacing + 128.0, g.cell_y (5), 0.001)
			assert_integers_equal ("three rows", 3, g.cell_rows)
			g.set_bounds (0.0, 0.0, 200.0, 300.0)
			assert_integers_equal ("one column when narrow", 1, g.columns)
			g.set_item_size (60, 60)
			g.set_spacing (4)
			g.set_bounds (0.0, 0.0, 600.0, 300.0)
			assert ("smaller cells fit more columns", g.columns > 4)
			assert_integers_equal ("a cell is hit at its middle", 1, g.item_at (4.0 + 30.0, 4.0 + 30.0))
			assert_integers_equal ("the gap hits nothing", 0, g.item_at (4.0 + 62.0, 4.0 + 30.0))
		end

	test_1v_a_the_grid_scrolls_to_a_selected_item
		local
			g: SW_GRID_VIEW
		do
			g := grid_of (40, 600.0)
			assert ("taller than the viewport", g.content_height > g.height)
			g.scroll_to_item (40)
			assert ("scrolled down", g.scroll_y > 0.0)
			assert ("the last cell is in view", g.cell_y (40) + g.item_height <= g.y + g.height + 0.001)
			g.scroll_to_item (1)
			assert_reals_equal ("back to the top", 0.0, g.scroll_y, 0.001)
		end

feature -- Pictures

	test_1v_a_a_picture_becomes_ready_one_decode_at_a_time
		local
			g: SW_GRID_VIEW
		do
			g := grid_of (3, 600.0)
			g.set_item_picture (1, "docs/images/logo.png")
			g.set_item_picture (2, "docs/images/logo.png")
			assert ("not ready at first", not g.is_picture_ready (1))
			assert_integers_equal ("two wait", 2, g.pending_pictures)
			assert ("one decode ran", g.decode_next_picture)
			assert_integers_equal ("only one", 1, g.pending_pictures)
			assert ("the first is ready", g.is_picture_ready (1))
			assert ("the second still waits", not g.is_picture_ready (2))
			assert ("another decode", g.decode_next_picture)
			assert ("all ready", g.is_picture_ready (2))
			assert ("nothing left to decode", not g.decode_next_picture)
		end

	test_1v_a_a_missing_picture_does_not_crash
		local
			g: SW_GRID_VIEW
		do
			g := grid_of (2, 600.0)
			g.set_item_picture (1, "docs/images/no_such_file.png")
			assert ("the decode was tried", g.decode_next_picture)
			assert ("no picture", not g.is_picture_ready (1))
			assert_integers_equal ("not pending again", 0, g.pending_pictures)
			g.set_item_icon (1, "folder")
			assert ("an icon name is kept", g.item_icon (1).same_string ("folder"))
		end

	test_1v_a_drawing_decodes_a_picture_a_frame
		local
			w: SW_WINDOW
			g: SW_GRID_VIEW
		do
			create w.make ("grid", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create g.make (300.0)
			g.extend ("One")
			g.extend ("Two")
			g.set_item_picture (1, "docs/images/logo.png")
			g.set_item_picture (2, "docs/images/logo.png")
			w.set_root (g)
			w.request_render
			assert ("one picture after one frame", g.is_picture_ready (1) and not g.is_picture_ready (2))
			w.request_render
			assert ("the next after the next frame", g.is_picture_ready (2))
		end

	test_1v_a_a_jpeg_decodes_through_a_supplied_decoder
			-- Without a decoder only PNG reads; the host's decoder opens a JPEG.
		local
			g: SW_GRID_VIEW
			l_jpg: STRING
		do
			l_jpg := written_jpeg ("grid_decoder_test.jpg", 12, 10)
			g := grid_of (2, 600.0)
			g.set_item_picture (1, l_jpg)
			g.set_picture_decoder (agent jpeg_surface)
			assert ("a decode ran", g.decode_next_picture)
			assert ("the JPEG is ready", g.is_picture_ready (1))
			assert ("its size is kept", attached g.item_picture (1) as al_s and then al_s.width = 12 and then al_s.height = 10)
			g.set_item_picture (2, l_jpg)
			g.set_picture_decoder (Void)
			assert ("the PNG reader alone cannot open it", g.decode_next_picture and not g.is_picture_ready (2))
			(create {RAW_FILE}.make_with_name (l_jpg)).delete
		end

	test_1v_a_a_loader_gets_at_most_two_requests_and_answers_come_back
		local
			g: SW_GRID_VIEW
			l_asked: ARRAYED_LIST [STRING_32]
			l_s: CAIRO_SURFACE
		do
			create l_asked.make (4)
			g := grid_of (4, 600.0)
			across 1 |..| 4 as ic loop
				g.set_item_picture (ic, "photo" + ic.out + ".jpg")
			end
			g.set_picture_loader (agent (a_path: STRING_32; a_list: ARRAYED_LIST [STRING_32]) do a_list.extend (a_path) end (?, l_asked))
			assert ("it asked", g.decode_next_picture)
			assert_integers_equal ("two asked, no more", 2, l_asked.count)
			assert_integers_equal ("two in flight", 2, g.in_flight_pictures)
			assert ("the first photo was first", l_asked [1].same_string ("photo1.jpg") and l_asked [2].same_string ("photo2.jpg"))
			assert ("nothing more while two are out", not g.decode_next_picture)
			assert_integers_equal ("still two asked", 2, l_asked.count)
			assert ("not ready until answered", not g.is_picture_ready (1))
			create l_s.make (6, 4)
			assert ("the answer lands", g.deliver_picture ("photo1.jpg", l_s))
			assert ("photo 1 ready", g.is_picture_ready (1))
			assert_integers_equal ("a slot is free", 1, g.in_flight_pictures)
			assert ("the next is asked", g.decode_next_picture)
			assert ("photo3 asked", l_asked.count = 3 and l_asked [3].same_string ("photo3.jpg"))
			assert ("an answer nobody wants is dropped", not g.deliver_picture ("other.jpg", l_s))
			assert ("a file that would not decode: answered with Void", g.deliver_picture ("photo2.jpg", Void))
			assert ("no picture, but done", not g.is_picture_ready (2) and g.pending_pictures = 2)
			g.set_item_picture (3, "changed.jpg")
			assert ("a stale answer is dropped", not g.deliver_picture ("photo3.jpg", l_s))
		end

feature -- Selection

	test_1v_a_selection_rules
		local
			g: SW_GRID_VIEW
			l_told: ARRAYED_LIST [INTEGER]
		do
			create l_told.make (4)
			g := grid_of (8, 600.0)
			g.set_on_select (agent (i: INTEGER; t: ARRAYED_LIST [INTEGER]) do t.extend (i) end (?, l_told))
			g.select_item_quietly (3, False)
			assert ("quiet", l_told.is_empty and g.selected_index = 3 and g.selected_count = 1)
			g.press_item (5, False)
			assert ("a click selects and tells", g.selected_index = 5 and g.selected_count = 1 and l_told.count = 1 and l_told [1] = 5)
			g.press_item (2, True)
			assert ("Ctrl in single mode is a click", g.selected_count = 1 and g.selected_index = 2)
			g.set_multiple (True)
			assert ("the first survives", g.selected_index = 2 and g.selected_count = 1)
			g.press_item (6, True)
			assert ("Ctrl adds, ascending", g.selected_count = 2 and g.selected_at (1) = 2 and g.selected_at (2) = 6)
			assert ("told the first", l_told.last = 2)
			g.press_item (2, True)
			assert ("Ctrl removes", g.selected_count = 1 and g.selected_index = 6 and l_told.last = 6)
			g.press_item (4, False)
			g.press_item_shift (7)
			assert ("Shift extends a range", g.selected_count = 4 and g.selected_at (1) = 4 and g.selected_at (4) = 7)
			g.select_item_quietly (1, False)
			g.select_item_quietly (8, True)
			assert ("quiet extend", g.selected_count = 2 and g.selected_at (2) = 8)
			g.select_item_quietly (0, False)
			assert ("zero clears", g.selected_count = 0 and g.selected_index = 0)
		end

	test_1v_a_removing_an_item_renumbers_the_selection
		local
			g: SW_GRID_VIEW
		do
			g := grid_of (5, 600.0)
			g.set_multiple (True)
			g.select_item_quietly (2, False)
			g.select_item_quietly (4, True)
			g.remove_item (2)
			assert ("the rest moved up", g.count = 4 and g.selected_count = 1 and g.selected_index = 3)
			g.wipe_out
			assert ("empty", g.count = 0 and g.selected_count = 0)
		end

feature -- Keys

	test_1v_a_arrows_move_in_two_dimensions
		local
			g: SW_GRID_VIEW
			l_told: ARRAYED_LIST [INTEGER]
		do
			create l_told.make (8)
			g := grid_of (10, 600.0)
			g.set_on_select (agent (i: INTEGER; t: ARRAYED_LIST [INTEGER]) do t.extend (i) end (?, l_told))
			g.select_item_quietly (1, False)
			g.handle_key (40, False)
			assert_integers_equal ("Down is a row of columns", 5, g.selected_index)
			g.handle_key (39, False)
			assert_integers_equal ("Right", 6, g.selected_index)
			g.handle_key (38, False)
			assert_integers_equal ("Up", 2, g.selected_index)
			g.handle_key (38, False)
			assert_integers_equal ("Up at the top stays", 2, g.selected_index)
			g.handle_key (35, False)
			assert_integers_equal ("End", 10, g.selected_index)
			g.handle_key (40, False)
			assert_integers_equal ("Down at the bottom stays", 10, g.selected_index)
			g.handle_key (36, False)
			assert_integers_equal ("Home", 1, g.selected_index)
			g.handle_key (37, False)
			assert_integers_equal ("Left at the start stays", 1, g.selected_index)
			assert_integers_equal ("each real move told", 5, l_told.count)
		end

	test_1v_a_space_toggles_in_multiple_mode_and_return_activates
		local
			g: SW_GRID_VIEW
			l_opened: ARRAYED_LIST [INTEGER]
		do
			create l_opened.make (2)
			g := grid_of (6, 600.0)
			g.set_on_activate (agent (i: INTEGER; t: ARRAYED_LIST [INTEGER]) do t.extend (i) end (?, l_opened))
			g.set_multiple (True)
			g.press_item (2, False)
			g.handle_key (32, False)
			assert ("Space took the current one out", g.selected_count = 0)
			g.handle_key (32, False)
			assert ("and back", g.selected_count = 1 and g.selected_index = 2)
			g.handle_key (39, True)
			assert ("Shift and an arrow extends", g.selected_count = 2)
			g.select_item_quietly (3, False)
			g.handle_key (13, False)
			assert ("Return activates the selected", l_opened.count = 1 and l_opened [1] = 3)
		end

feature -- Filtering and activation

	test_1v_a_the_filter_keeps_model_numbers
		local
			g: SW_GRID_VIEW
			l_told: ARRAYED_LIST [INTEGER]
		do
			create l_told.make (2)
			g := grid_of (0, 600.0)
			g.extend ("Genesis")
			g.extend ("Exodus")
			g.extend ("Leviticus")
			g.extend ("Numbers")
			g.set_item_subtitle (4, "The census")
			g.set_on_select (agent (i: INTEGER; t: ARRAYED_LIST [INTEGER]) do t.extend (i) end (?, l_told))
			g.set_multiple (True)
			g.select_item_quietly (2, False)
			g.select_item_quietly (3, True)
			g.set_filter_text ("EXO")
			assert_integers_equal ("one shown", 1, g.shown_count)
			assert ("the model number stays", g.is_shown (2) and not g.is_shown (3))
			assert ("the hidden one was deselected", g.selected_count = 1 and g.selected_index = 2)
			assert ("the new first was told", l_told.count = 1 and l_told [1] = 2)
			g.set_filter_text ("census")
			assert_integers_equal ("a subtitle matches", 1, g.shown_count)
			assert ("Numbers is 4", g.is_shown (4))
			assert ("nothing selected, told 0", g.selected_count = 0 and l_told.last = 0)
			g.press_item (4, False)
			assert_integers_equal ("a click on a shown cell gives the model number", 4, g.selected_index)
			assert_integers_equal ("the first cell is item 4", 4, g.item_at (g.spacing + 5.0, g.spacing + 5.0))
			g.extend ("Census Two")
			assert_integers_equal ("a new matching item shows", 2, g.shown_count)
			g.set_filter_text ("")
			assert_integers_equal ("all again", 5, g.shown_count)
			assert ("clearing does not reselect", g.selected_count = 1)
		end

	test_1v_a_activation_is_the_users
		local
			g: SW_GRID_VIEW
			l_opened, l_told: ARRAYED_LIST [INTEGER]
		do
			create l_opened.make (2)
			create l_told.make (2)
			g := grid_of (4, 600.0)
			g.set_on_activate (agent (i: INTEGER; t: ARRAYED_LIST [INTEGER]) do t.extend (i) end (?, l_opened))
			g.set_on_select (agent (i: INTEGER; t: ARRAYED_LIST [INTEGER]) do t.extend (i) end (?, l_told))
			g.select_item_quietly (2, False)
			assert ("code is quiet", l_opened.is_empty and l_told.is_empty)
			g.activate_by_user (3)
			assert ("selects then opens", g.selected_index = 3 and l_told.count = 1 and l_opened.count = 1 and l_opened [1] = 3)
			assert ("a real double click on cell 2", g.handle_double_click (g.cell_x (2) + 5.0, g.cell_y (2) + 5.0))
			assert ("opened 2", l_opened.count = 2 and l_opened [2] = 2)
			assert ("a double click on a gap opens nothing", g.handle_double_click (1.0, 1.0) and l_opened.count = 2)
		end

feature -- Accessibility

	test_1v_a_cells_are_list_items_named_by_their_titles
		local
			w: SW_WINDOW
			g: SW_GRID_VIEW
			acc: SW_ACCESSIBILITY
			i, l_items, l_grid_id: INTEGER
			l_found: BOOLEAN
		do
			create w.make ("cells", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create g.make (300.0)
			g.extend ("Genesis")
			g.extend ("Exodus")
			g.extend ("Leviticus")
			w.set_root (g)
			w.request_render
			w.publish_accessibility
			acc := w.accessibility
			l_grid_id := w.accessible_id_of (g)
			from i := 1 until i > acc.served_rows loop
				if acc.served_role (i) = {SW_ACCESSIBILITY}.Role_list_item then
					l_items := l_items + 1
					assert_integers_equal ("under the grid", l_grid_id, acc.served_parent (i))
					if acc.served_name (i).same_string ("Exodus") then
						l_found := True
					end
				end
				i := i + 1
			end
			assert_integers_equal ("three list items", 3, l_items)
			assert ("named by their titles", l_found)
		end

feature {NONE} -- Helpers

	written_jpeg (a_name: STRING; a_width, a_height: INTEGER): STRING
			-- A JPEG file of that size, written now.
		local
			l_stb: SIMPLE_STB
			l_img: STB_IMAGE
		do
			create l_stb.make
			l_img := l_stb.create_rgb (a_width, a_height)
			l_img.fill (200, 40, 40, 255)
			assert ("jpeg written", l_img.write_jpg (a_name, 90))
			l_img.destroy
			Result := a_name
		end

	jpeg_surface (a_path: READABLE_STRING_GENERAL): detachable CAIRO_SURFACE
			-- A surface of the picture's size, read through simple_stb (what a host decoder does).
		local
			l_stb: SIMPLE_STB
			l_img: STB_IMAGE
		do
			create l_stb.make
			l_img := l_stb.load_rgba (a_path)
			if l_img.is_valid then
				create Result.make (l_img.width, l_img.height)
			end
			l_img.destroy
		end

	grid_of (a_count: INTEGER; a_width: REAL_64): SW_GRID_VIEW
			-- A grid of `a_count' items, each titled "item N", laid out `a_width' by 300.
		local
			i: INTEGER
		do
			create Result.make (300.0)
			from i := 1 until i > a_count loop
				Result.extend ("item " + i.out)
				i := i + 1
			end
			Result.set_bounds (0.0, 0.0, a_width, 300.0)
		end

end
