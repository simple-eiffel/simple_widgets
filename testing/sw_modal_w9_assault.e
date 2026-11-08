note
	description: "W9: the synchronous faces of the drawn dialogs (headless: no native window, so they answer at once)."

class
	SW_MODAL_W9_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_run_modal_until_returns_without_a_window
			-- Headless there is no native window to pump: the loop must not spin.
		local
			w: SW_WINDOW
			l_asked: CELL [INTEGER]
		do
			create l_asked.put (0)
			create w.make ("w9", 0, 0, 400, 300, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make_ui ("x"))
			w.run_modal_until (agent (c: CELL [INTEGER]): BOOLEAN do c.put (c.item + 1) end (l_asked))
			assert_integers_equal ("asked once, then left", 1, l_asked.item)
		end

	test_ask_shows_ok_and_cancel
			-- The dialog carries OK first (Windows order) and Cancel when confirming; headless
			-- the answer is No and the dialog stays for the window to close.
		local
			w: SW_WINDOW
		do
			create w.make ("w9", 0, 0, 400, 300, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make_ui ("x"))
			w.request_render
			assert ("headless: no", not w.ask ({SW_DIALOG}.Kind_warning, "Delete?", "Delete the file?", True))
			assert ("shown", attached w.dialog as al_d and then al_d.buttons.count = 2)
			if attached w.dialog as al_d then
				assert_strings_equal ("OK first", "OK", al_d.buttons.i_th (1).label)
				assert ("OK is the primary", al_d.buttons.i_th (1).is_primary)
				assert_strings_equal ("then Cancel", "Cancel", al_d.buttons.i_th (2).label)
			end
			w.close_dialog
			assert ("a message has OK only", not w.ask ({SW_DIALOG}.Kind_info, "Saved", "The file was saved.", False))
			assert ("one button", attached w.dialog as al_d2 and then al_d2.buttons.count = 1)
		end

	test_choose_file_offers_the_filtered_dialog
		local
			w: SW_WINDOW
		do
			create w.make ("w9", 0, 0, 800, 600, create {SW_THEME}.make_light)
			w.set_root (create {SW_LABEL}.make_ui ("x"))
			w.request_render
			assert ("headless: nothing chosen", w.choose_file (True, ".", "untitled.txt", "txt;md") = Void)
			assert ("and the sheet is closed", not w.has_sheet)
		end

end
