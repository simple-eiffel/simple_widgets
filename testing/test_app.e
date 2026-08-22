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

			print ("%N=== WAVE 3 INDICATORS ===%N")
			run_indicator_tests

			print ("%N=== WAVE 3 DISCLOSURE ===%N")
			run_disclosure_tests

			print ("%N=== 7GUIS ENGINES ===%N")
			run_guis7_tests

			print ("%N=== DATA GRID ===%N")
			run_grid_tests

			print ("%N=== LOCALE + PICKERS ===%N")
			run_locale_tests

			print ("%N=== TREE + COLOUR ===%N")
			run_tree_color_tests

			print ("%N=== DEV STUDIO ===%N")
			run_dev_studio_tests

			print ("%N=== STATE CONTROL ===%N")
			run_state_control_tests

			print ("%N=== EVENT QUEUES ===%N")
			run_event_tests

			print ("%N=== WAVE 4 CHARTS ===%N")
			run_chart_tests

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

	tree_color_tests: SW_TREE_COLOR_ASSAULT

	run_tree_color_tests
		do
			create tree_color_tests
			run_test (agent tree_color_tests.test_flatten_follows_disclosure, "tree_flatten_follows_disclosure")
			run_test (agent tree_color_tests.test_children_agent_is_lazy_enough, "tree_children_lazy")
			run_test (agent tree_color_tests.test_selection_is_identity_stable, "tree_selection_identity_stable")
			run_test (agent tree_color_tests.test_hsv_to_rgb_known_values, "color_hsv_known_values")
			run_test (agent tree_color_tests.test_rgb_round_trips, "color_rgb_round_trips")
			run_test (agent tree_color_tests.test_hex_readout, "color_hex_readout")
			run_test (agent tree_color_tests.test_dropzone_contract, "dropzone_contract")
			run_test (agent tree_color_tests.test_inspector_reveals_truth, "inspector_reveals_truth")
		end

	locale_tests: SW_LOCALE_ASSAULT

	run_locale_tests
		do
			create locale_tests
			run_test (agent locale_tests.test_us_round_trip, "locale_us_round_trip")
			run_test (agent locale_tests.test_iso_and_european_orders, "locale_iso_and_european_orders")
			run_test (agent locale_tests.test_separators_are_generous, "locale_separators_generous")
			run_test (agent locale_tests.test_impossible_dates_refused, "locale_impossible_dates_refused")
			run_test (agent locale_tests.test_leap_february, "locale_leap_february")
			run_test (agent locale_tests.test_time_both_cultures, "locale_time_both_cultures")
			run_test (agent locale_tests.test_first_cell_honors_week_start, "calendar_first_cell_week_start")
			run_test (agent locale_tests.test_calendar_step_wraps_year, "calendar_step_wraps_year")
		end

	grid_tests: SW_GRID_ASSAULT

	run_grid_tests
		do
			create grid_tests
			run_test (agent grid_tests.test_text_sort_ascending, "grid_text_sort_ascending")
			run_test (agent grid_tests.test_typed_sort_beats_text, "grid_typed_sort_beats_text")
			run_test (agent grid_tests.test_filter_composes_with_sort, "grid_filter_composes_with_sort")
			run_test (agent grid_tests.test_selection_survives_resort, "grid_selection_survives_resort")
			run_test (agent grid_tests.test_selection_cleared_when_filtered_out, "grid_selection_cleared_when_filtered")
			run_test (agent grid_tests.test_column_resize_clamps, "grid_column_resize_clamps")
			run_test (agent grid_tests.test_view_row_at_guards, "grid_view_row_at_guards")
		end

	guis7_tests: SW_7GUIS_ASSAULT

	run_guis7_tests
		do
			create guis7_tests
			run_test (agent guis7_tests.test_cells_literal_and_formula, "cells_literal_and_formula")
			run_test (agent guis7_tests.test_cells_propagation, "cells_propagation")
			run_test (agent guis7_tests.test_cells_cycle_is_error, "cells_cycle_is_error")
			run_test (agent guis7_tests.test_cells_text_and_garbage, "cells_text_and_garbage")
			run_test (agent guis7_tests.test_circles_undo_redo_law, "circles_undo_redo_law")
			run_test (agent guis7_tests.test_circles_adjustment_is_one_step, "circles_adjustment_is_one_step")
			run_test (agent guis7_tests.test_circles_nearest_hit, "circles_nearest_hit")
			run_test (agent guis7_tests.test_clear_button_contract, "clear_button_contract")
		end

	disclosure_tests: SW_DISCLOSURE_ASSAULT

	run_disclosure_tests
		do
			create disclosure_tests
			run_test (agent disclosure_tests.test_accordion_exclusive_law, "accordion_exclusive_law")
			run_test (agent disclosure_tests.test_accordion_multi_mode, "accordion_multi_mode")
			run_test (agent disclosure_tests.test_accordion_height_follows_disclosure, "accordion_height_follows_disclosure")
			run_test (agent disclosure_tests.test_stepper_starts_and_clamps, "stepper_starts_and_clamps")
			run_test (agent disclosure_tests.test_stepper_only_done_ground_is_clickable, "stepper_done_ground_only")
			run_test (agent disclosure_tests.test_timeline_row_math, "timeline_row_math")
			run_test (agent disclosure_tests.test_drawer_close_zone, "drawer_close_zone")
		end

	indicator_tests: SW_INDICATOR_ASSAULT

	run_indicator_tests
		do
			create indicator_tests
			run_test (agent indicator_tests.test_badge_caption_caps, "badge_caption_caps")
			run_test (agent indicator_tests.test_avatar_initials, "avatar_initials")
			run_test (agent indicator_tests.test_segmented_first_chosen_at_birth, "segmented_first_chosen")
			run_test (agent indicator_tests.test_segmented_select_fires_once, "segmented_select_fires_once")
			run_test (agent indicator_tests.test_segmented_click_zones, "segmented_click_zones")
			run_test (agent indicator_tests.test_rating_click_sets_and_clears, "rating_click_sets_and_clears")
			run_test (agent indicator_tests.test_rating_star_at_bounds, "rating_star_at_bounds")
			run_test (agent indicator_tests.test_statistic_delta, "statistic_delta")
			run_test (agent indicator_tests.test_empty_state_action_zone, "empty_state_action_zone")
			run_test (agent indicator_tests.test_skeleton_draw_smoke, "skeleton_draw_smoke")
			run_test (agent indicator_tests.test_scroll_wheel_step_programmable, "scroll_wheel_step_programmable")
			run_test (agent indicator_tests.test_scroll_two_axis_clamps, "scroll_two_axis_clamps")
		end

	run_dev_studio_tests
		do
			create studio_tests
			run_test (agent studio_tests.test_mesh_depth_limit_and_frontier, "mesh_depth_limit_and_frontier")
			run_test (agent studio_tests.test_mesh_expand_grows_in_place, "mesh_expand_grows_in_place")
			run_test (agent studio_tests.test_mesh_full_harvest_no_frontier, "mesh_full_harvest_no_frontier")
			run_test (agent studio_tests.test_mesh_context_menu_nodes_only, "mesh_context_menu_nodes_only")
			run_test (agent studio_tests.test_mesh_names_toggle, "mesh_names_toggle")
			run_test (agent studio_tests.test_mesh_pebble_hole_types, "mesh_pebble_hole_types")
			run_test (agent studio_tests.test_mesh_re_root_follows_the_drop, "mesh_re_root_follows_the_drop")
			run_test (agent studio_tests.test_studio_pane_follows_re_root, "studio_pane_follows_re_root")
			run_test (agent studio_tests.test_lens_ignores_its_own_chrome, "lens_ignores_its_own_chrome")
			run_test (agent studio_tests.test_studio_aim_at_syncs_pane_and_mesh, "studio_aim_at_syncs_pane_and_mesh")
			run_test (agent studio_tests.test_studio_pane_swaps_on_select, "studio_pane_swaps_on_select")
			run_test (agent studio_tests.test_studio_live_edit_drives_public_setter, "studio_live_edit_drives_public_setter")
			run_test (agent studio_tests.test_inspector_full_lifts_field_cap, "inspector_full_lifts_field_cap")
		end

	studio_tests: SW_DEV_STUDIO_ASSAULT

	run_state_control_tests
		do
			create state_tests
			run_test (agent state_tests.test_enabled_when_applies_immediately, "enabled_when_applies_immediately")
			run_test (agent state_tests.test_refresh_walks_the_sub_widget_spine, "refresh_walks_the_sub_widget_spine")
			run_test (agent state_tests.test_menubar_pad_conditions, "menubar_pad_conditions")
		end

	state_tests: SW_STATE_CONTROL_ASSAULT

	run_event_tests
		do
			create event_tests
			run_test (agent event_tests.test_event_order_and_permanence, "event_order_and_permanence")
			run_test (agent event_tests.test_kamikaze_fires_in_place_once, "kamikaze_fires_in_place_once")
			run_test (agent event_tests.test_abort_stops_the_round, "abort_stops_the_round")
			run_test (agent event_tests.test_pause_buffers_block_drops, "pause_buffers_block_drops")
			run_test (agent event_tests.test_spine_fires_on_change_only, "spine_fires_on_change_only")
			run_test (agent event_tests.test_sensitivity_speaks_through_the_queue, "sensitivity_speaks_through_the_queue")
			run_test (agent event_tests.test_button_queue_beside_legacy, "button_queue_beside_legacy")
		end

	event_tests: SW_EVENT_ASSAULT

	run_chart_tests
		do
			create chart_tests
			run_test (agent chart_tests.test_scale_round_trip, "scale_round_trip")
			run_test (agent chart_tests.test_scale_degenerate_honesty, "scale_degenerate_honesty")
			run_test (agent chart_tests.test_scale_ladder_125, "scale_ladder_125")
			run_test (agent chart_tests.test_scale_nice_domain, "scale_nice_domain")
			run_test (agent chart_tests.test_line_rolling_capacity, "line_rolling_capacity")
			run_test (agent chart_tests.test_line_auto_domains, "line_auto_domains")
			run_test (agent chart_tests.test_bar_slots_and_domain, "bar_slots_and_domain")
			run_test (agent chart_tests.test_scatter_nearest, "scatter_nearest")
			run_test (agent chart_tests.test_pie_shares_and_slices, "pie_shares_and_slices")
			run_test (agent chart_tests.test_pie_empty_is_honest, "pie_empty_is_honest")
			run_test (agent chart_tests.test_funnel_conversion_and_bands, "funnel_conversion_and_bands")
			run_test (agent chart_tests.test_gauge_fraction_zones_and_clamp, "gauge_fraction_zones_and_clamp")
			run_test (agent chart_tests.test_gauge_degenerate_span, "gauge_degenerate_span")
			run_test (agent chart_tests.test_sparkline_rolls_and_normalizes, "sparkline_rolls_and_normalizes")
			run_test (agent chart_tests.test_sparkline_flat_is_midline, "sparkline_flat_is_midline")
			run_test (agent chart_tests.test_heatmap_blend_endpoints, "heatmap_blend_endpoints")
			run_test (agent chart_tests.test_heatmap_slots_and_flat_honesty, "heatmap_slots_and_flat_honesty")
			run_test (agent chart_tests.test_treemap_areas_are_shares, "treemap_areas_are_shares")
			run_test (agent chart_tests.test_treemap_tiles_cover_and_answer, "treemap_tiles_cover_and_answer")
			run_test (agent chart_tests.test_sankey_throughput_is_max_flow, "sankey_throughput_is_max_flow")
			run_test (agent chart_tests.test_sankey_heights_proportional_in_column, "sankey_heights_proportional_in_column")
			run_test (agent chart_tests.test_sankey_moorings_stack_contiguously, "sankey_moorings_stack_contiguously")
		end

	chart_tests: SW_CHART_ASSAULT

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
