note
	description: "Contract-assault runner for simple_widgets."
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Assault the toolkit's model layer under full DBC.
		do
			print ("simple_widgets contract assault (F_code -keep, all assertions live)%N%N")
			passed := 0
			failed := 0

			print ("=== TEXT ENGINE ===%N")
			run_engine_tests

			print ("%N=== LIST MATH ===%N")
			run_list_tests

			print ("%N=== CHROME + THEME ===%N")
			run_chrome_tests

			print ("%N=== FILE DIALOG ===%N")
			run_file_dialog_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test runners

	engine_tests: SW_ENGINE_ASSAULT

	list_tests: SW_LIST_ASSAULT

	chrome_tests: SW_CHROME_ASSAULT

	fd_tests: SW_FILE_DIALOG_ASSAULT

	run_engine_tests
		do
			create engine_tests
			run_test (agent engine_tests.test_set_text_kills_stale_ranges, "set_text_kills_stale_ranges (the bug)")
			run_test (agent engine_tests.test_arrow_selection_and_invert, "arrow_selection_and_invert")
			run_test (agent engine_tests.test_masked_glyph_state, "masked_glyph_state")
			run_test (agent engine_tests.test_masked_copy_denied, "masked_copy_denied")
			run_test (agent engine_tests.test_reveal_is_view_only, "reveal_is_view_only")
			run_test (agent engine_tests.test_single_line_paste_flattens, "single_line_paste_flattens")
			run_test (agent engine_tests.test_astral_code_point_round_trip, "astral_code_point_round_trip (R8)")
			run_test (agent engine_tests.test_combo_choose_option, "combo_choose_option")
			run_test (agent engine_tests.test_caret_clamps_on_shorter_text, "caret_clamps_on_shorter_text")
		end

	run_list_tests
		do
			create list_tests
			run_test (agent list_tests.test_prelayout_scroll_regression, "prelayout_scroll (the postcondition kill)")
			run_test (agent list_tests.test_row_at_bounds, "row_at_bounds")
			run_test (agent list_tests.test_shrink_count_clears_selection, "shrink_count_clears_selection")
			run_test (agent list_tests.test_wheel_clamps, "wheel_clamps")
			run_test (agent list_tests.test_double_click_activates, "double_click_activates")
			run_test (agent list_tests.test_row_pebble_offer, "row_pebble_offer")
		end

	run_chrome_tests
		do
			create chrome_tests
			run_test (agent chrome_tests.test_radio_auto_selects_first, "radio_auto_selects_first")
			run_test (agent chrome_tests.test_toolbar_by_label_state, "toolbar_by_label_state")
			run_test (agent chrome_tests.test_toolbar_click_fires_and_latches, "toolbar_click_fires_and_latches")
			run_test (agent chrome_tests.test_theme_invariants_both_ways, "theme_invariants_both_ways")
			run_test (agent chrome_tests.test_painter_circles_and_text, "painter_circles_and_text")
			run_test (agent chrome_tests.test_layout_clamps, "layout_clamps")
		end

	run_file_dialog_tests
		do
			create fd_tests
			run_test (agent fd_tests.test_listing_order_and_kinds, "listing_order_and_kinds")
			run_test (agent fd_tests.test_extension_filter, "extension_filter")
			run_test (agent fd_tests.test_navigation_down_and_up, "navigation_down_and_up")
			run_test (agent fd_tests.test_accept_delivers_full_path, "accept_delivers_full_path")
		end

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run one test; any exception (contract or otherwise) fails it.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

	passed: INTEGER

	failed: INTEGER

end
