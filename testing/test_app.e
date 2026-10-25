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
				-- The real keyboard must not steer a test: nothing is held
				-- unless a test simulates it (SW_KEYS.simulate).
			(create {SW_KEYS}).simulate (False, False, False)
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

			print ("%N=== WAVE 5 ENTERPRISE ===%N")
			run_enterprise_tests

			print ("%N=== WAVE 6 MEDIA + CHAT ===%N")
			run_media_tests

			print ("%N=== DEEPENING SWEEP ===%N")
			run_deepening_tests

			print ("%N=== SHAPED TEXT (simple_shaping) ===%N")
			run_shaping_tests

			print ("%N=== MARGINS + PADDING ===%N")
			run_margins_tests

			print ("%N=== CHAT THREAD SCROLL + SCROLLBAR ===%N")
			run_chat_scroll_tests

			print ("%N=== CHAT LINE BREAKS + SELECTION ===%N")
			run_chat_text_tests

			print ("%N=== CHAT PER-MESSAGE MUTATION ===%N")
			run_chat_mutation_tests

			print ("%N=== ACCELERATORS + MNEMONICS ===%N")
			run_keyboard_tests

			print ("%N=== SHAPED MENUS (emoji + RTL mnemonics) ===%N")
			run_menu_shaping_tests

			print ("%N=== SHAPED LABELS (RTL, artwork, mono stays toy) ===%N")
			run_label_shaping_tests

			print ("%N=== STUDIO WIDGETS (waveform, shaped editing, paragraphs) ===%N")
			run_studio_tests

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
			run_test (agent list_tests.test_bar_drag_ends_on_release, "list_bar_drag_ends_on_release")
		end

	run_chrome_tests
		do
			create chrome_tests
			run_test (agent chrome_tests.test_radio_auto_selects_first, "radio_auto_selects_first")
			run_test (agent chrome_tests.test_toolbar_by_label_state, "toolbar_by_label_state")
			run_test (agent chrome_tests.test_toolbar_click_fires_and_latches, "toolbar_click_fires_and_latches")
			run_test (agent chrome_tests.test_theme_invariants_both_ways, "theme_invariants_both_ways")
			run_test (agent chrome_tests.test_theme_gw28_both_palettes_readable, "theme_gw28_both_palettes_readable")
			run_test (agent chrome_tests.test_theme_gw28_fills_take_the_right_ink, "theme_gw28_fills_take_the_right_ink")
			run_test (agent chrome_tests.test_theme_gw28_ramp_moves_away, "theme_gw28_ramp_moves_away")
			run_test (agent chrome_tests.test_theme_gw28_unreadable_rejected, "theme_gw28_unreadable_rejected")
			run_test (agent chrome_tests.test_gw27_follow_matches_windows, "gw27_follow_matches_windows")
			run_test (agent chrome_tests.test_gw27_flip_swaps_live, "gw27_flip_swaps_live")
			run_test (agent chrome_tests.test_gw27_user_choice_stops_following, "gw27_user_choice_stops_following")
			run_test (agent chrome_tests.test_gw26_wake_calls_the_app_even_under_a_dialog, "gw26_wake_calls_the_app_even_under_a_dialog")
			run_test (agent chrome_tests.test_gw11_sections_lay_out_and_answer, "gw11_sections_lay_out_and_answer")
			run_test (agent chrome_tests.test_status_bar_and_hover_card_spacing_scale, "status_bar_and_hover_card_spacing_scale")
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
			run_test (agent tree_color_tests.test_tree_bar_thumb_in_track_and_drags, "tree_bar_thumb_in_track_and_drags")
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
			run_test (agent grid_tests.test_bar_drag_ends_on_release, "grid_bar_drag_ends_on_release")
			run_test (agent grid_tests.test_typed_sort_beats_text, "grid_typed_sort_beats_text")
			run_test (agent grid_tests.test_filter_composes_with_sort, "grid_filter_composes_with_sort")
			run_test (agent grid_tests.test_selection_survives_resort, "grid_selection_survives_resort")
			run_test (agent grid_tests.test_selection_cleared_when_filtered_out, "grid_selection_cleared_when_filtered")
			run_test (agent grid_tests.test_set_rows_snapshots_against_external_mutation, "grid_set_rows_snapshots_external_mutation")
			run_test (agent grid_tests.test_column_resize_clamps, "grid_column_resize_clamps")
			run_test (agent grid_tests.test_view_row_at_guards, "grid_view_row_at_guards")
			run_test (agent grid_tests.test_growing_column_takes_spare_width, "grid_growing_column_takes_spare_width")
			run_test (agent grid_tests.test_divider_shows_resize_cursor, "grid_divider_shows_resize_cursor")
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
			run_test (agent indicator_tests.test_scroll_bar_drag_ends_on_release, "scroll_bar_drag_ends_on_release")
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
			run_test (agent chart_tests.test_map_projection_round_trips, "map_projection_round_trips")
			run_test (agent chart_tests.test_map_raster_and_markers, "map_raster_and_markers")
			run_test (agent chart_tests.test_diagram_contracts_and_physics, "diagram_contracts_and_physics")
			run_test (agent chart_tests.test_picker_band_arithmetic, "picker_band_arithmetic")
			run_test (agent chart_tests.test_world_clock_zone_math, "world_clock_zone_math")
		end

	chart_tests: SW_CHART_ASSAULT

	run_enterprise_tests
		do
			create enterprise_tests
			run_test (agent enterprise_tests.test_tree_table_slots_and_header, "tree_table_slots_and_header")
			run_test (agent enterprise_tests.test_cells_aggregate_law, "cells_aggregate_law")
			run_test (agent enterprise_tests.test_cells_range_propagation, "cells_range_propagation")
			run_test (agent enterprise_tests.test_cells_undo_walks_both_ways, "cells_undo_walks_both_ways")
			run_test (agent enterprise_tests.test_cells_tsv_blocks, "cells_tsv_blocks")
			run_test (agent enterprise_tests.test_cells_csv_round_trip, "cells_csv_round_trip")
			run_test (agent enterprise_tests.test_spreadsheet_slots_and_keyboard_commit, "spreadsheet_slots_and_keyboard_commit")
			run_test (agent enterprise_tests.test_pivot_folds_and_totals, "pivot_folds_and_totals")
			run_test (agent enterprise_tests.test_kanban_board_truth, "kanban_board_truth")
			run_test (agent enterprise_tests.test_kanban_lane_pebbles, "kanban_lane_pebbles")
			run_test (agent enterprise_tests.test_scheduler_overlap_lanes, "scheduler_overlap_lanes")
			run_test (agent enterprise_tests.test_gantt_geometry_and_contracts, "gantt_geometry_and_contracts")
			run_test (agent enterprise_tests.test_file_manager_engine, "file_manager_engine")
			run_test (agent enterprise_tests.test_query_builder_emission, "query_builder_emission")
			run_test (agent enterprise_tests.test_form_generator_model, "form_generator_model")
			run_test (agent enterprise_tests.test_org_chart_layout_law, "org_chart_layout_law")
			run_test (agent enterprise_tests.test_dock_reflow_law, "dock_reflow_law")
			run_test (agent enterprise_tests.test_gw05_tabbed_zone_shows_one_panel, "gw05_tabbed_zone_shows_one_panel")
			run_test (agent enterprise_tests.test_gw05_edges_drag_and_clamp, "gw05_edges_drag_and_clamp")
			run_test (agent enterprise_tests.test_gw05_hide_show_remove, "gw05_hide_show_remove")
			run_test (agent enterprise_tests.test_gw05_snapshot_round_trip, "gw05_snapshot_round_trip")
			run_test (agent enterprise_tests.test_gw05_spacing_follows_the_theme, "gw05_spacing_follows_the_theme")
		end

	enterprise_tests: SW_ENTERPRISE_ASSAULT

	run_media_tests
		do
			create media_tests
			run_test (agent media_tests.test_carousel_pages_wrap, "carousel_pages_wrap")
			run_test (agent media_tests.test_gallery_flow_math, "gallery_flow_math")
			run_test (agent media_tests.test_transport_clock_and_seek, "transport_clock_and_seek")
			run_test (agent media_tests.test_crop_normalizes_any_direction, "crop_normalizes_any_direction")
			run_test (agent media_tests.test_chat_thread_roles_and_streaming, "chat_thread_roles_and_streaming")
			run_test (agent media_tests.test_prompt_view_round_trip, "prompt_view_round_trip")
			run_test (agent media_tests.test_dictation_honest_absence, "dictation_honest_absence")
			run_test (agent media_tests.test_dictation_transcribes_a_real_wav, "dictation_transcribes_a_real_wav")
		end

	media_tests: SW_MEDIA_ASSAULT

	run_deepening_tests
		do
			create deepening_tests
			run_test (agent deepening_tests.test_textbox_undo_redo, "textbox_undo_redo")
			run_test (agent deepening_tests.test_select_option_enablement, "select_option_enablement")
			run_test (agent deepening_tests.test_radio_vertical_and_enablement, "radio_vertical_and_enablement")
			run_test (agent deepening_tests.test_chip_removal_zone, "chip_removal_zone")
			run_test (agent deepening_tests.test_checkbox_tristate_resolves_to_checked, "checkbox_tristate_resolves_to_checked")
			run_test (agent deepening_tests.test_rating_read_only_and_halves, "rating_read_only_and_halves")
			run_test (agent deepening_tests.test_slider_tick_snapping, "slider_tick_snapping")
			run_test (agent deepening_tests.test_number_box_direct_typing, "number_box_direct_typing")
			run_test (agent deepening_tests.test_locale_number_formatting, "locale_number_formatting")
			run_test (agent deepening_tests.test_badge_kind_and_zero_policy, "badge_kind_and_zero_policy")
			run_test (agent deepening_tests.test_theme_text_scale, "theme_text_scale")
			run_test (agent deepening_tests.test_screen_grab_marries_cairo, "screen_grab_marries_cairo")
			run_test (agent deepening_tests.test_focus_traversal_ring, "focus_traversal_ring")
			run_test (agent deepening_tests.test_spreadsheet_keeps_its_tab, "spreadsheet_keeps_its_tab")
			run_test (agent deepening_tests.test_cursor_kinds, "cursor_kinds")
			run_test (agent deepening_tests.test_peek_grace_law, "peek_grace_law")
			run_test (agent deepening_tests.test_calendar_close_on_pick_request, "calendar_close_on_pick_request")
			run_test (agent deepening_tests.test_every_glyph_draws_ink, "every_glyph_draws_ink")
			run_test (agent deepening_tests.test_icon_button_faces, "icon_button_faces")
			run_test (agent deepening_tests.test_toolbar_icon_items_measure_squarely, "toolbar_icon_items_measure_squarely")
			run_test (agent deepening_tests.test_segmented_icon_segments, "segmented_icon_segments")
			run_test (agent deepening_tests.test_empty_state_glyph_choice, "empty_state_glyph_choice")
			run_test (agent deepening_tests.test_grid_descending_sort_is_stable, "grid_descending_sort_is_stable")
			run_test (agent deepening_tests.test_grid_sort_thousands, "grid_sort_thousands")
			run_test (agent deepening_tests.test_list_keyboard_navigation, "list_keyboard_navigation")
			run_test (agent deepening_tests.test_grid_page_and_edge_keys, "grid_page_and_edge_keys")
			run_test (agent deepening_tests.test_calendar_min_max_window, "calendar_min_max_window")
			run_test (agent deepening_tests.test_file_dialog_pattern_sets, "file_dialog_pattern_sets")
			run_test (agent deepening_tests.test_color_picker_hex_input, "color_picker_hex_input")
			run_test (agent deepening_tests.test_avatar_photo_clips_to_disc, "avatar_photo_clips_to_disc")
			run_test (agent deepening_tests.test_row_wrap_math, "row_wrap_math")
			run_test (agent deepening_tests.test_row_wrap_arranges_lines, "row_wrap_arranges_lines")
			run_test (agent deepening_tests.test_splitter_horizontal_and_dblclick_reset, "splitter_horizontal_and_dblclick_reset")
			run_test (agent deepening_tests.test_tabs_lazy_builders, "tabs_lazy_builders")
			run_test (agent deepening_tests.test_separator_vertical, "separator_vertical")
			run_test (agent deepening_tests.test_drawer_all_four_edges, "drawer_all_four_edges")
			run_test (agent deepening_tests.test_world_geometry_sanity, "world_geometry_sanity")
			run_test (agent deepening_tests.test_map_draws_real_coastlines, "map_draws_real_coastlines")
			run_test (agent deepening_tests.test_world_cities_sanity, "world_cities_sanity")
			run_test (agent deepening_tests.test_map_city_adoption_and_bands, "map_city_adoption_and_bands")
			run_test (agent deepening_tests.test_map_zoom_laws, "map_zoom_laws")
			run_test (agent deepening_tests.test_zoomed_band_pick_stays_true, "zoomed_band_pick_stays_true")
			run_test (agent deepening_tests.test_click_on_atlanta_answers_eastern, "click_on_atlanta_answers_eastern")
		end

	deepening_tests: SW_DEEPENING_ASSAULT

	shaping_tests: SW_SHAPING_ASSAULT

	margins_tests: SW_MARGINS_ASSAULT

	run_margins_tests
			-- The Vision2 outside/inside spacing model: border_width at the
			-- root, padding between siblings, control_inset inside a control.
		do
			create margins_tests
			run_test (agent margins_tests.test_theme_carries_border_padding_and_inset, "theme_carries_border_padding_and_inset")
			run_test (agent margins_tests.test_column_places_children_from_the_theme, "column_places_children_from_the_theme")
			run_test (agent margins_tests.test_nested_column_adds_no_second_border, "nested_column_adds_no_second_border")
			run_test (agent margins_tests.test_explicit_spacing_always_wins, "explicit_spacing_always_wins")
			run_test (agent margins_tests.test_card_and_group_carry_their_own_border, "card_and_group_carry_their_own_border")
			run_test (agent margins_tests.test_control_minimum_comes_from_the_font, "control_minimum_comes_from_the_font")
			run_test (agent margins_tests.test_controls_track_the_font_at_1x_and_2x, "controls_track_the_font_at_1x_and_2x")
			run_test (agent margins_tests.test_label_line_step_equals_the_painted_line, "label_line_step_equals_the_painted_line")
			run_test (agent margins_tests.test_margins_evidence, "margins_evidence (offscreen PNG)")
		end

	chat_scroll_tests: SW_CHAT_SCROLL_ASSAULT

	run_chat_scroll_tests
			-- The scroll-clamp defect (0.5.0) and its fix, and the new
			-- scrollbar: offscreen only, no window is ever shown.
		do
			create chat_scroll_tests
			run_test (agent chat_scroll_tests.test_reproduction_at_larrys_scale, "reproduction_at_larrys_scale (2x, 1071x836, through the window)")
			run_test (agent chat_scroll_tests.test_scroll_to_clamps_and_updates_stickiness, "scroll_to_clamps_and_updates_stickiness")
			run_test (agent chat_scroll_tests.test_clamp_survives_content_shrink, "clamp_survives_content_shrink")
			run_test (agent chat_scroll_tests.test_sticky_transitions, "sticky_transitions")
			run_test (agent chat_scroll_tests.test_wheel_notch_is_three_lines, "chat_wheel_notch_is_three_lines")
			run_test (agent chat_scroll_tests.test_thumb_height_and_position, "thumb_height_and_position")
			run_test (agent chat_scroll_tests.test_scrollbar_visible_only_on_overflow, "scrollbar_visible_only_on_overflow")
			run_test (agent chat_scroll_tests.test_drag_thumb_scrolls, "drag_thumb_scrolls")
			run_test (agent chat_scroll_tests.test_track_click_pages, "track_click_pages")
			run_test (agent chat_scroll_tests.test_keyboard_paging, "keyboard_paging")
			run_test (agent chat_scroll_tests.test_log_line_is_timestamped, "log_line_is_timestamped")
			run_test (agent chat_scroll_tests.test_scroll_evidence, "scroll_evidence (offscreen PNGs)")
		end

	run_shaping_tests
			-- The shaped-text battery. Every one of these needs the Noto
			-- png/128 artwork and a working DirectWrite; on a machine that
			-- has neither they fail loudly rather than skipping quietly,
			-- because "shaped text works" is the claim under test.
		do
			create shaping_tests
			run_test (agent shaping_tests.test_d015_shaped_line_paints, "d015_shaped_line_paints (AC-1, end to end)")
			run_test (agent shaping_tests.test_chat_bubbles_measure_from_their_layouts, "chat_bubbles_measure_from_their_layouts (R10)")
			run_test (agent shaping_tests.test_chat_relayouts_when_the_pane_narrows, "chat_relayouts_when_the_pane_narrows (R10)")
			run_test (agent shaping_tests.test_ascii_bubble_renders_on_both_paths, "ascii_bubble_renders_on_both_paths")
			run_test (agent shaping_tests.test_kit_prepends_the_theme_face_for_latin_only, "kit_prepends_the_theme_face_for_latin_only (Q1)")
			run_test (agent shaping_tests.test_niqqud_offsets_are_reported_not_swallowed, "niqqud_offsets_are_reported_not_swallowed (diagnostic)")
			run_test (agent shaping_tests.test_gw04_painter_text_shapes_hebrew_and_greek_light, "gw04_painter_text_shapes_hebrew_and_greek_light")
			run_test (agent shaping_tests.test_gw04_painter_text_shapes_hebrew_and_greek_dark, "gw04_painter_text_shapes_hebrew_and_greek_dark")
			run_test (agent shaping_tests.test_gw04_advance_is_the_shaped_width, "gw04_advance_is_the_shaped_width")
			run_test (agent shaping_tests.test_gw04_without_a_kit_the_toy_path_is_unchanged, "gw04_without_a_kit_the_toy_path_is_unchanged")
			run_test (agent shaping_tests.test_gw02_geometry_sets_hebrew_flush_right, "gw02_geometry_sets_hebrew_flush_right")
			run_test (agent shaping_tests.test_gw02_text_box_hebrew_flush_right_light, "gw02_text_box_hebrew_flush_right_light")
			run_test (agent shaping_tests.test_gw02_text_box_hebrew_flush_right_dark, "gw02_text_box_hebrew_flush_right_dark")
			run_test (agent shaping_tests.test_gw02_paragraph_list_gutter_follows_reading_light, "gw02_paragraph_list_gutter_follows_reading_light")
			run_test (agent shaping_tests.test_gw02_paragraph_list_gutter_follows_reading_dark, "gw02_paragraph_list_gutter_follows_reading_dark")
			run_test (agent shaping_tests.test_gw03_faces_cover_and_marks_attach, "gw03_faces_cover_and_marks_attach")
			run_test (agent shaping_tests.test_gw03_marks_visible_light, "gw03_marks_visible_light")
			run_test (agent shaping_tests.test_gw03_marks_visible_dark, "gw03_marks_visible_dark")
			run_test (agent shaping_tests.test_gw03_mapm_nbsp_never_breaks_before_paseq, "gw03_mapm_nbsp_never_breaks_before_paseq")
			run_test (agent shaping_tests.test_gw11_status_sections_hebrew_greek_light, "gw11_status_sections_hebrew_greek_light")
			run_test (agent shaping_tests.test_gw11_status_sections_hebrew_greek_dark, "gw11_status_sections_hebrew_greek_dark")
			run_test (agent shaping_tests.test_gw08_raised_strongs_and_small_caps_light, "gw08_raised_strongs_and_small_caps_light")
			run_test (agent shaping_tests.test_gw08_raised_strongs_and_small_caps_dark, "gw08_raised_strongs_and_small_caps_dark")
			run_test (agent shaping_tests.test_gw09_hebrew_word_card_light, "gw09_hebrew_word_card_light")
			run_test (agent shaping_tests.test_gw09_hebrew_word_card_dark, "gw09_hebrew_word_card_dark")
			run_test (agent shaping_tests.test_gw05_study_layout_light, "gw05_study_layout_light")
			run_test (agent shaping_tests.test_gw05_study_layout_dark, "gw05_study_layout_dark")
		end

	chat_text_tests: SW_CHAT_TEXT_ASSAULT

	run_chat_text_tests
		do
			create chat_text_tests
			run_test (agent chat_text_tests.test_paragraphs_split_at_every_explicit_break, "paragraphs_split_at_every_explicit_break")
			run_test (agent chat_text_tests.test_blank_runs_are_bounded_and_trailing_blanks_dropped, "blank_runs_are_bounded_and_trailing_blanks_dropped")
			run_test (agent chat_text_tests.test_no_break_character_survives_into_a_drawn_line, "no_break_character_survives_into_a_drawn_line (the box)")
			run_test (agent chat_text_tests.test_three_line_message_occupies_three_lines, "three_line_message_occupies_three_lines")
			run_test (agent chat_text_tests.test_a_numbered_list_stays_a_list, "a_numbered_list_stays_a_list")
			run_test (agent chat_text_tests.test_shaped_message_gets_one_layout_per_paragraph, "shaped_message_gets_one_layout_per_paragraph")
			run_test (agent chat_text_tests.test_hebrew_line_then_greek_line, "hebrew_line_then_greek_line (shaped, bidi)")
			run_test (agent chat_text_tests.test_a_message_may_arrive_after_a_shaped_frame, "a_message_may_arrive_after_a_shaped_frame (the invariant)")
			run_test (agent chat_text_tests.test_drag_selects_the_characters_it_crosses, "drag_selects_the_characters_it_crosses")
			run_test (agent chat_text_tests.test_double_click_takes_the_word, "double_click_takes_the_word")
			run_test (agent chat_text_tests.test_a_selection_never_leaves_its_bubble, "a_selection_never_leaves_its_bubble")
			run_test (agent chat_text_tests.test_selection_offsets_run_over_the_displayed_text, "selection_offsets_run_over_the_displayed_text")
			run_test (agent chat_text_tests.test_context_menu_offers_copy_only_when_there_is_something_to_copy, "context_menu_offers_copy")
			run_test (agent chat_text_tests.test_line_and_selection_evidence, "line_and_selection_evidence (offscreen PNGs)")
		end

	chat_mutation_tests: SW_CHAT_MUTATION_ASSAULT

	run_chat_mutation_tests
			-- The per-message menu (0.7.0): edit, react, delete, reply -
			-- offscreen only, no window is ever shown.
		do
			create chat_mutation_tests
			run_test (agent chat_mutation_tests.test_set_message_replaces_the_words_and_the_speaker, "set_message_replaces_the_words_and_the_speaker")
			run_test (agent chat_mutation_tests.test_an_edit_drops_a_selection_that_lived_in_it, "an_edit_drops_a_selection_that_lived_in_it")
			run_test (agent chat_mutation_tests.test_set_message_after_a_shaped_frame_keeps_the_invariant, "set_message_after_a_shaped_frame_keeps_the_invariant")
			run_test (agent chat_mutation_tests.test_a_tombstone_is_shorter_and_holds_nothing, "a_tombstone_is_shorter_and_holds_nothing (1x and 2x)")
			run_test (agent chat_mutation_tests.test_a_tombstone_sheds_its_decorations, "a_tombstone_sheds_its_decorations")
			run_test (agent chat_mutation_tests.test_reactions_change_the_bubble_the_content_and_the_thumb, "reactions_change_the_bubble_the_content_and_the_thumb")
			run_test (agent chat_mutation_tests.test_the_chip_list_is_copied_in_not_borrowed, "the_chip_list_is_copied_in_not_borrowed")
			run_test (agent chat_mutation_tests.test_message_at_names_every_bubble_and_the_gaps, "message_at_names_every_bubble_and_the_gaps")
			run_test (agent chat_mutation_tests.test_reaction_at_finds_the_chip_that_was_clicked, "reaction_at_finds_the_chip_that_was_clicked")
			run_test (agent chat_mutation_tests.test_a_reply_quote_is_one_line_and_elided, "a_reply_quote_is_one_line_and_elided")
			run_test (agent chat_mutation_tests.test_elision_keeps_what_fits_and_marks_what_it_cut, "elision_keeps_what_fits_and_marks_what_it_cut")
			run_test (agent chat_mutation_tests.test_the_edited_marker_grows_a_band_and_survives_a_re_edit, "the_edited_marker_grows_a_band_and_survives_a_re_edit")
			run_test (agent chat_mutation_tests.test_every_band_scales_with_the_theme, "every_band_scales_with_the_theme (1x and 2x)")
			run_test (agent chat_mutation_tests.test_the_shaped_path_draws_the_decorations_too, "the_shaped_path_draws_the_decorations_too (2x, shaped)")
			run_test (agent chat_mutation_tests.test_mutation_evidence, "mutation_evidence (offscreen PNG)")
		end

	keyboard_tests: SW_KEYBOARD_ASSAULT

	run_keyboard_tests
		do
			create keyboard_tests
			run_test (agent keyboard_tests.test_mnemonic_parsing, "mnemonic_parsing")
			run_test (agent keyboard_tests.test_an_accelerator_fires_regardless_of_focus, "an_accelerator_fires_regardless_of_focus")
			run_test (agent keyboard_tests.test_the_modifier_state_must_match_exactly, "the_modifier_state_must_match_exactly")
			run_test (agent keyboard_tests.test_gw24_bare_function_key_is_an_accelerator, "gw24_bare_function_key_is_an_accelerator")
			run_test (agent keyboard_tests.test_gw24_no_trailing_char_never_eats_the_next_keystroke, "gw24_no_trailing_char_never_eats_the_next_keystroke")
			run_test (agent keyboard_tests.test_gw24_trailing_control_code_is_still_swallowed, "gw24_trailing_control_code_is_still_swallowed")
			run_test (agent keyboard_tests.test_an_unclaimed_ctrl_key_is_still_the_focused_box_s_own, "unclaimed_ctrl_key_is_still_the_box_s_own")
			run_test (agent keyboard_tests.test_first_registration_wins_and_clear_empties, "first_registration_wins_and_clear_empties")
			run_test (agent keyboard_tests.test_menu_bar_reads_and_answers_its_ampersands, "menu_bar_reads_and_answers_its_ampersands")
			run_test (agent keyboard_tests.test_a_disabled_pad_does_not_answer_alt, "a_disabled_pad_does_not_answer_alt")
			run_test (agent keyboard_tests.test_an_open_menu_answers_a_bare_letter, "an_open_menu_answers_a_bare_letter")
			run_test (agent keyboard_tests.test_the_window_opens_the_pad_the_mnemonic_names, "the_window_opens_the_pad_the_mnemonic_names")
			run_test (agent keyboard_tests.test_the_highlight_steps_over_separators_and_disabled_items, "the_highlight_steps_over_separators_and_disabled_items")
			run_test (agent keyboard_tests.test_a_menu_with_nothing_to_choose_cannot_spin, "a_menu_with_nothing_to_choose_cannot_spin")
			run_test (agent keyboard_tests.test_the_open_menu_answers_the_arrow_keys_and_enter, "the_open_menu_answers_the_arrow_keys_and_enter")
			run_test (agent keyboard_tests.test_escape_closes_and_left_right_walk_the_bar, "escape_closes_and_left_right_walk_the_bar")
			run_test (agent keyboard_tests.test_alt_letter_on_the_key_down_door_opens_the_menu, "alt_letter_on_the_key_down_door (the Alt door)")
			run_test (agent keyboard_tests.test_a_host_accelerator_still_wins_the_alt_key, "a_host_accelerator_still_wins_the_alt_key")
			run_test (agent keyboard_tests.test_alt_needs_a_menu_bar_before_it_opens_anything, "alt_needs_a_menu_bar_before_it_opens_anything")
			run_test (agent keyboard_tests.test_mnemonic_evidence, "mnemonic_evidence (offscreen PNGs)")
			run_test (agent keyboard_tests.test_a_context_click_opens_the_widgets_own_menu, "a_context_click_opens_the_widgets_own_menu")
			run_test (agent keyboard_tests.test_a_second_context_click_closes_the_open_one, "a_second_context_click_closes_the_open_one")
			run_test (agent keyboard_tests.test_a_context_click_on_nothing_offers_nothing, "a_context_click_on_nothing_offers_nothing")
			run_test (agent keyboard_tests.test_the_open_menu_is_painted_and_answers_the_keyboard, "the_open_menu_is_painted_and_answers_the_keyboard (offscreen PNG)")
		end

	menu_shaping_tests: SW_MENU_SHAPING_ASSAULT

	run_menu_shaping_tests
		do
			create menu_shaping_tests
			run_test (agent menu_shaping_tests.test_an_emoji_menu_item_paints_artwork_and_not_a_box, "an_emoji_menu_item_paints_artwork_and_not_a_box (2x, offscreen PNG)")
			run_test (agent menu_shaping_tests.test_a_hebrew_pad_underlines_the_glyph_it_names, "a_hebrew_pad_underlines_the_glyph_it_names (2x)")
			run_test (agent menu_shaping_tests.test_the_menu_measures_what_it_paints, "the_menu_measures_what_it_paints (2x)")
			run_test (agent menu_shaping_tests.test_an_item_with_no_mnemonic_underlines_nothing, "an_item_with_no_mnemonic_underlines_nothing")
		end

	label_shaping_tests: SW_LABEL_SHAPING_ASSAULT

	run_label_shaping_tests
		do
			create label_shaping_tests
			run_test (agent label_shaping_tests.test_a_hebrew_label_paints_its_first_letter_rightmost, "a_hebrew_label_paints_its_first_letter_rightmost (2x, offscreen PNG)")
			run_test (agent label_shaping_tests.test_an_emoji_label_paints_artwork_and_not_a_box, "an_emoji_label_paints_artwork_and_not_a_box (2x)")
			run_test (agent label_shaping_tests.test_a_mono_label_keeps_the_toy_path_whatever_the_painter_carries, "a_mono_label_keeps_the_toy_path_whatever_the_painter_carries")
			run_test (agent label_shaping_tests.test_an_empty_label_shapes_nothing, "an_empty_label_shapes_nothing")
			run_test (agent label_shaping_tests.test_a_wrapping_body_label_breaks_where_the_kit_breaks_it, "a_wrapping_body_label_breaks_where_the_kit_breaks_it")
		end

	run_file_dialog_tests
		do
			create fd_tests
			run_test (agent fd_tests.test_listing_order_and_kinds, "listing_order_and_kinds")
			run_test (agent fd_tests.test_extension_filter, "extension_filter")
			run_test (agent fd_tests.test_navigation_down_and_up, "navigation_down_and_up")
			run_test (agent fd_tests.test_drive_roots_and_hop, "drive_roots_and_hop")
			run_test (agent fd_tests.test_typed_absolute_directory_navigates, "typed_absolute_directory_navigates")
			run_test (agent fd_tests.test_typed_bare_drive_normalizes, "typed_bare_drive_normalizes")
			run_test (agent fd_tests.test_typed_relative_directory_descends, "typed_relative_directory_descends")
			run_test (agent fd_tests.test_typed_absolute_file_accepts, "typed_absolute_file_accepts")
			run_test (agent fd_tests.test_accept_delivers_full_path, "accept_delivers_full_path")
		end

	run_studio_tests
		do
			create waveform_tests
			run_test (agent waveform_tests.test_silence_is_flat, "waveform_silence_is_flat")
			run_test (agent waveform_tests.test_sine_reaches_full_scale, "waveform_sine_reaches_full_scale")
			run_test (agent waveform_tests.test_out_of_range_samples_are_clamped, "waveform_out_of_range_clamped")
			run_test (agent waveform_tests.test_short_sound_is_not_padded, "waveform_short_sound_not_padded")
			run_test (agent waveform_tests.test_column_peaks_any_width, "waveform_column_peaks_any_width")
			run_test (agent waveform_tests.test_column_peaks_without_audio_are_zero, "waveform_column_peaks_without_audio")
			run_test (agent waveform_tests.test_seek_math_both_ways, "waveform_seek_math_both_ways")
			run_test (agent waveform_tests.test_click_seeks_and_reports, "waveform_click_seeks_and_reports")
			run_test (agent waveform_tests.test_click_without_audio_is_refused, "waveform_click_without_audio_refused")
			run_test (agent waveform_tests.test_markers_within_the_audio, "waveform_markers_within_audio")
			run_test (agent waveform_tests.test_headless_paint, "waveform_headless_paint")
			create shaped_edit_tests
			run_test (agent shaped_edit_tests.test_toy_caret_round_trip, "textbox_toy_caret_round_trip")
			run_test (agent shaped_edit_tests.test_toy_newline_opens_a_line, "textbox_toy_newline_opens_a_line")
			run_test (agent shaped_edit_tests.test_shaped_latin_round_trip, "textbox_shaped_latin_round_trip")
			run_test (agent shaped_edit_tests.test_shaped_hebrew_caret_walks_leftward, "textbox_shaped_hebrew_caret_walks_leftward")
			run_test (agent shaped_edit_tests.test_shaped_mixed_round_trip, "textbox_shaped_mixed_bidi_round_trip")
			run_test (agent shaped_edit_tests.test_shaped_paragraphs_stack, "textbox_shaped_paragraphs_stack")
			run_test (agent shaped_edit_tests.test_shaped_wrap_stays_inside, "textbox_shaped_wrap_stays_inside")
			run_test (agent shaped_edit_tests.test_masked_box_keeps_the_toy_path, "textbox_masked_keeps_toy_path")
			run_test (agent shaped_edit_tests.test_click_and_drag_select_hebrew, "textbox_click_and_drag_select_hebrew")
			run_test (agent shaped_edit_tests.test_headless_paint_both_paths, "textbox_headless_paint_both_paths")
			run_test (agent shaped_edit_tests.test_toy_height_ignores_the_last_font, "textbox_toy_height_ignores_the_last_font")
			run_test (agent shaped_edit_tests.test_shaped_height_ignores_the_last_font, "textbox_shaped_height_ignores_the_last_font")
			run_test (agent shaped_edit_tests.test_toy_lines_stack_at_row_height, "textbox_toy_lines_stack_at_row_height")
			run_test (agent shaped_edit_tests.test_shaped_lines_stack_at_row_height, "textbox_shaped_lines_stack_at_row_height")
			print ("%N=== GW-13 RICH DOCUMENT ===%N")
			create document_tests
			run_test (agent document_tests.test_gw13_rich_text_flattens_for_the_shaper, "gw13_rich_text_flattens_for_the_shaper")
			run_test (agent document_tests.test_gw13_view_points_links_and_selects, "gw13_view_points_links_and_selects")
			run_test (agent document_tests.test_gw13_bold_and_links_reach_the_shaper, "gw13_bold_and_links_reach_the_shaper")
			run_test (agent document_tests.test_gw13_spacing_follows_the_theme, "gw13_spacing_follows_the_theme")
			run_test (agent document_tests.test_gw13_long_document_scrolls, "gw13_long_document_scrolls")
			run_test (agent document_tests.test_empty_paragraph_stands_a_line_tall, "empty_paragraph_stands_a_line_tall")
			run_test (agent document_tests.test_paragraph_spacing_scales, "paragraph_spacing_scales")
			run_test (agent document_tests.test_gw13_document_light, "gw13_document_light")
			run_test (agent document_tests.test_gw13_document_dark, "gw13_document_dark")
			run_test (agent document_tests.test_gw13_edit_shows_the_source_and_keeps_it, "gw13_edit_shows_the_source_and_keeps_it")
			run_test (agent document_tests.test_gw13_edit_splits_removes_and_adds, "gw13_edit_splits_removes_and_adds")
			run_test (agent document_tests.test_gw13_ctrl_click_follows_while_editable, "gw13_ctrl_click_follows_while_editable")
			run_test (agent document_tests.test_gw13_hebrew_and_greek_are_not_misspelled, "gw13_hebrew_and_greek_are_not_misspelled")
			run_test (agent document_tests.test_gw13_editing_light, "gw13_editing_light")
			run_test (agent document_tests.test_gw13_editing_dark, "gw13_editing_dark")
			print ("%N=== GW-06 PARALLEL TEXT ===%N")
			create parallel_tests
			run_test (agent parallel_tests.test_gw06_rows_follow_their_tallest_cell, "gw06_rows_follow_their_tallest_cell")
			run_test (agent parallel_tests.test_gw06_cells_hit_click_and_copy, "gw06_cells_hit_click_and_copy")
			run_test (agent parallel_tests.test_gw06_hebrew_column_and_note, "gw06_hebrew_column_and_note")
			run_test (agent parallel_tests.test_gw06_title_band_stays_while_rows_scroll, "gw06_title_band_stays_while_rows_scroll")
			run_test (agent parallel_tests.test_gw06_spacing_follows_the_theme, "gw06_spacing_follows_the_theme")
			run_test (agent parallel_tests.test_gw06_band_is_not_content, "gw06_band_is_not_content")
			run_test (agent parallel_tests.test_gw06_scroll_to_row_shows_it_below_the_band, "gw06_scroll_to_row_shows_it_below_the_band")
			run_test (agent parallel_tests.test_gw06_wipe_out_forgets_the_hovered_link, "gw06_wipe_out_forgets_the_hovered_link")
			run_test (agent parallel_tests.test_gw06_parallel_light, "gw06_parallel_light")
			run_test (agent parallel_tests.test_gw06_parallel_dark, "gw06_parallel_dark")
			print ("%N=== GW-07 INTERLINEAR ===%N")
			create interlinear_tests
			run_test (agent interlinear_tests.test_gw07_cells_flow_and_wrap, "gw07_cells_flow_and_wrap")
			run_test (agent interlinear_tests.test_gw07_lines_hide_and_show, "gw07_lines_hide_and_show")
			run_test (agent interlinear_tests.test_gw07_select_by_click_and_keys, "gw07_select_by_click_and_keys")
			run_test (agent interlinear_tests.test_gw07_every_line_can_be_pointed_at, "gw07_every_line_can_be_pointed_at")
			run_test (agent interlinear_tests.test_gw07_new_words_after_wipe_out_are_shown, "gw07_new_words_after_wipe_out_are_shown")
			run_test (agent interlinear_tests.test_gw07_a_click_ends_a_text_selection, "gw07_a_click_ends_a_text_selection")
			run_test (agent interlinear_tests.test_gw07_interlinear_light, "gw07_interlinear_light")
			run_test (agent interlinear_tests.test_gw07_interlinear_dark, "gw07_interlinear_dark")
			print ("%N=== GW-10 GROUPED BARS ===%N")
			create grouped_bars_tests
			run_test (agent grouped_bars_tests.test_gw10_groups_hit_and_domain, "gw10_groups_hit_and_domain")
			run_test (agent grouped_bars_tests.test_gw10_emphasis_quiets_the_others, "gw10_emphasis_quiets_the_others")
			run_test (agent grouped_bars_tests.test_gw10_new_series_forget_the_emphasis, "gw10_new_series_forget_the_emphasis")
			run_test (agent grouped_bars_tests.test_gw10_series_colours_stay_apart, "gw10_series_colours_stay_apart")
			run_test (agent grouped_bars_tests.test_gw10_crowded_chart_keeps_inside, "gw10_crowded_chart_keeps_inside")
			run_test (agent grouped_bars_tests.test_gw10_controls_light, "gw10_controls_light")
			run_test (agent grouped_bars_tests.test_gw10_controls_dark, "gw10_controls_dark")
			print ("%N=== SCAN 7 ===%N")
			create memo_tests
			run_test (agent memo_tests.test_scan7_memo_forgets_when_the_facade_changes, "scan7_memo_forgets_when_the_facade_changes")
			run_test (agent memo_tests.test_scan7_label_shapes_like_the_painter, "scan7_label_shapes_like_the_painter")
			run_test (agent memo_tests.test_scan7_rows_added_one_at_a_time, "scan7_rows_added_one_at_a_time")
			run_test (agent memo_tests.test_scan7_hebrew_column_sits_flush_right, "scan7_hebrew_column_sits_flush_right")
			print ("%N=== GW-15 TABS ===%N")
			create tabs_tests
			run_test (agent tabs_tests.test_gw15_close_selects_the_neighbor, "gw15_close_selects_the_neighbor")
			run_test (agent tabs_tests.test_gw15_guard_and_pinned_tabs, "gw15_guard_and_pinned_tabs")
			run_test (agent tabs_tests.test_gw15_close_box_through_the_window, "gw15_close_box_through_the_window")
			run_test (agent tabs_tests.test_gw15_drag_reorders_through_the_window, "gw15_drag_reorders_through_the_window")
			run_test (agent tabs_tests.test_gw15_move_tab_keeps_the_selection, "gw15_move_tab_keeps_the_selection")
			run_test (agent tabs_tests.test_gw15_overflow_keeps_the_selected_tab_whole, "gw15_overflow_keeps_the_selected_tab_whole")
			run_test (agent tabs_tests.test_gw15_closing_at_the_end_pulls_the_strip_back, "gw15_closing_at_the_end_pulls_the_strip_back")
			run_test (agent tabs_tests.test_gw15_keys_an_application_binds, "gw15_keys_an_application_binds")
			run_test (agent tabs_tests.test_gw15_wheel_steps_over_the_strip, "gw15_wheel_steps_over_the_strip")
			run_test (agent tabs_tests.test_gw15_tabs_light, "gw15_tabs_light")
			run_test (agent tabs_tests.test_gw15_tabs_dark, "gw15_tabs_dark")
			run_test (agent tabs_tests.test_scan9_a_narrow_bar_still_shows_the_selected_tab, "scan9_a_narrow_bar_still_shows_the_selected_tab")
			run_test (agent tabs_tests.test_scan9_a_zero_inset_theme_still_shows_tabs, "scan9_a_zero_inset_theme_still_shows_tabs")
			run_test (agent tabs_tests.test_scan9_a_close_handler_may_adopt_the_page, "scan9_a_close_handler_may_adopt_the_page")
			run_test (agent tabs_tests.test_scan9_moving_across_hidden_tabs_leaves_no_stale_box, "scan9_moving_across_hidden_tabs_leaves_no_stale_box")
			print ("%N=== GW-16 HIGH CONTRAST ===%N")
			create contrast_tests
			run_test (agent contrast_tests.test_gw16_windows_contrast_palettes_are_readable, "gw16_windows_contrast_palettes_are_readable")
			run_test (agent contrast_tests.test_gw16_an_unreadable_palette_is_mended, "gw16_an_unreadable_palette_is_mended")
			run_test (agent contrast_tests.test_gw16_window_follows_high_contrast, "gw16_window_follows_high_contrast")
			run_test (agent contrast_tests.test_gw16_following_starts_in_contrast, "gw16_following_starts_in_contrast")
			run_test (agent contrast_tests.test_gw16_contrast_black, "gw16_contrast_black")
			run_test (agent contrast_tests.test_gw16_contrast_white, "gw16_contrast_white")
			run_test (agent contrast_tests.test_scan10_selected_rows_show_in_contrast, "scan10_selected_rows_show_in_contrast")
			run_test (agent contrast_tests.test_scan10_a_pressed_button_label_reads, "scan10_a_pressed_button_label_reads")
			run_test (agent contrast_tests.test_scan10_selection_never_vanishes, "scan10_selection_never_vanishes")
			run_test (agent contrast_tests.test_scan10_disabled_text_looks_disabled, "scan10_disabled_text_looks_disabled")
			run_test (agent contrast_tests.test_scan10_hover_shows, "scan10_hover_shows")
			run_test (agent contrast_tests.test_scan10_accent_reads_as_small_text, "scan10_accent_reads_as_small_text")
			run_test (agent contrast_tests.test_scan10_a_theme_swap_updates_the_kit_faces, "scan10_a_theme_swap_updates_the_kit_faces")
			run_test (agent contrast_tests.test_scan10_the_switch_is_read_once, "scan10_the_switch_is_read_once")
			print ("%N=== GW-21 WIDGET IMAGE ===%N")
			create image_tests
			run_test (agent image_tests.test_gw21_the_widget_alone_at_scale_in_light, "gw21_the_widget_alone_at_scale_in_light")
			run_test (agent image_tests.test_gw21_the_screen_theme_when_asked, "gw21_the_screen_theme_when_asked")
			run_test (agent image_tests.test_gw21_hover_never_exports, "gw21_hover_never_exports")
			run_test (agent image_tests.test_gw21_png_reads_back_and_clipboard_takes_it, "gw21_png_reads_back_and_clipboard_takes_it")
			run_test (agent image_tests.test_gw21_scripture_export, "gw21_scripture_export")
			run_test (agent image_tests.test_scan11_exports_free_their_memory, "scan11_exports_free_their_memory")
			run_test (agent image_tests.test_scan11_widget_image_frees_its_context, "scan11_widget_image_frees_its_context")
			run_test (agent image_tests.test_scan11_grid_hover_never_exports, "scan11_grid_hover_never_exports")
			run_test (agent image_tests.test_scan11_fractional_edges_are_opaque, "scan11_fractional_edges_are_opaque")
			run_test (agent image_tests.test_scan11_oversized_export_is_refused, "scan11_oversized_export_is_refused")
			print ("%N=== GW-14 REDUCED MOTION ===%N")
			create motion_tests
			run_test (agent motion_tests.test_gw14_skeleton_holds_still, "gw14_skeleton_holds_still")
			run_test (agent motion_tests.test_gw14_progress_band_holds_still, "gw14_progress_band_holds_still")
			run_test (agent motion_tests.test_gw14_window_follows_the_animation_setting, "gw14_window_follows_the_animation_setting")
			print ("%N=== GW-29 VIRTUAL GRID ===%N")
			create virtual_grid_tests
			run_test (agent virtual_grid_tests.test_gw29_hundred_thousand_rows_light, "gw29_hundred_thousand_rows_light")
			run_test (agent virtual_grid_tests.test_gw29_hundred_thousand_rows_dark, "gw29_hundred_thousand_rows_dark")
			print ("%N=== GW-12 QUERY BUILDER ===%N")
			create query_tests
			run_test (agent query_tests.test_gw12_tree_reads_and_renders, "gw12_tree_reads_and_renders")
			run_test (agent query_tests.test_gw12_incomplete_and_negated_groups, "gw12_incomplete_and_negated_groups")
			run_test (agent query_tests.test_gw12_typed_pickers_and_removal, "gw12_typed_pickers_and_removal")
			run_test (agent query_tests.test_gw12_distance_edit_is_heard, "gw12_distance_edit_is_heard")
			run_test (agent query_tests.test_gw12_long_distance_preset_renders, "gw12_long_distance_preset_renders")
			run_test (agent query_tests.test_gw12_builder_light, "gw12_builder_light")
			run_test (agent query_tests.test_gw12_builder_dark, "gw12_builder_dark")
			create paragraph_tests
			run_test (agent paragraph_tests.test_heights_follow_the_text, "paragraphs_heights_follow_the_text")
			run_test (agent paragraph_tests.test_bands_add_exactly, "paragraphs_bands_add_exactly")
			run_test (agent paragraph_tests.test_virtualisation_and_hit_test, "paragraphs_virtualisation_and_hit_test")
			run_test (agent paragraph_tests.test_bar_drag_ends_on_release, "bar_drag_ends_on_release")
			run_test (agent paragraph_tests.test_block_stack_lookups, "block_stack_lookups")
			run_test (agent paragraph_tests.test_simulated_ctrl_click_toggles, "simulated_ctrl_click_toggles")
			run_test (agent paragraph_tests.test_stale_geometry_never_indexed, "stale_geometry_never_indexed")
			run_test (agent paragraph_tests.test_wheel_clamps, "paragraphs_wheel_clamps")
			run_test (agent paragraph_tests.test_selection_set_and_anchor, "paragraphs_selection_set_and_anchor")
			run_test (agent paragraph_tests.test_click_selects_and_keys_move, "paragraphs_click_selects_and_keys_move")
			run_test (agent paragraph_tests.test_insert_remove_move_keep_lists_honest, "paragraphs_insert_remove_move")
			run_test (agent paragraph_tests.test_put_text_reflows, "paragraphs_put_text_reflows")
			run_test (agent paragraph_tests.test_edit_in_place_reflows_and_commits, "paragraphs_edit_in_place_reflows_and_commits")
			run_test (agent paragraph_tests.test_edit_cancel_restores, "paragraphs_edit_cancel_restores")
			run_test (agent paragraph_tests.test_click_elsewhere_commits, "paragraphs_click_elsewhere_commits")
			run_test (agent paragraph_tests.test_remove_while_editing_drops_editor, "paragraphs_remove_while_editing")
			run_test (agent paragraph_tests.test_shaped_measurement_and_paint, "paragraphs_shaped_measurement_and_paint")
			run_test (agent paragraph_tests.test_gutter_only_for_visible, "paragraphs_gutter_only_for_visible")
			run_test (agent paragraph_tests.test_gw08_character_at_names_the_character, "gw08_character_at_names_the_character")
			run_test (agent paragraph_tests.test_gw08_hover_dwell_and_scroll_are_heard, "gw08_hover_dwell_and_scroll_are_heard")
			run_test (agent paragraph_tests.test_gw08_window_times_the_dwell, "gw08_window_times_the_dwell")
			run_test (agent paragraph_tests.test_gw09_dwell_opens_a_card_at_the_word, "gw09_dwell_opens_a_card_at_the_word")
			run_test (agent paragraph_tests.test_gw09_card_closes_on_click_escape_leave_and_modal, "gw09_card_closes_on_click_escape_leave_and_modal")
			create mark_tests
			run_test (agent mark_tests.test_mark_code_round_trip, "marks_code_round_trip")
			run_test (agent mark_tests.test_palette_readable_on_both_themes, "marks_palette_readable_on_both_themes")
			run_test (agent mark_tests.test_legend_defines_and_rethemes, "marks_legend_defines_and_rethemes")
			run_test (agent mark_tests.test_marked_text_mark_remove_restyle, "marks_marked_text_mark_remove_restyle")
			run_test (agent mark_tests.test_marked_text_codec_and_unresolved, "marks_marked_text_codec_and_unresolved")
			run_test (agent mark_tests.test_marked_text_follows_edits, "marks_marked_text_follows_edits")
			run_test (agent mark_tests.test_geometry_segments_merge_per_line, "marks_geometry_segments_merge_per_line")
			run_test (agent mark_tests.test_painter_paints_every_aspect_headless, "marks_painter_paints_every_aspect_headless")
			run_test (agent mark_tests.test_legend_view_draws_and_picks, "marks_legend_view_draws_and_picks")
			create marked_edit_tests
			run_test (agent marked_edit_tests.test_textbox_spans_follow_typing_and_undo, "marks_textbox_spans_follow_typing_and_undo")
			run_test (agent marked_edit_tests.test_textbox_set_text_and_shared_marks, "marks_textbox_set_text_and_shared_marks")
			run_test (agent marked_edit_tests.test_textbox_paints_marks_both_engines, "marks_textbox_paints_both_engines")
			run_test (agent marked_edit_tests.test_paragraphs_share_marks_with_the_editor, "marks_paragraphs_share_with_editor")
			run_test (agent marked_edit_tests.test_paragraphs_marks_travel_with_mutation, "marks_paragraphs_travel_with_mutation")
		end

	mark_tests: SW_MARK_ASSAULT

	marked_edit_tests: SW_MARKED_EDIT_ASSAULT

	waveform_tests: SW_WAVEFORM_ASSAULT

	shaped_edit_tests: SW_SHAPED_EDIT_ASSAULT

	paragraph_tests: SW_PARAGRAPH_LIST_ASSAULT
	document_tests: SW_DOCUMENT_ASSAULT
	parallel_tests: SW_PARALLEL_ASSAULT
	interlinear_tests: SW_INTERLINEAR_ASSAULT
	grouped_bars_tests: SW_GROUPED_BARS_ASSAULT
	query_tests: SW_QUERY_ASSAULT
	virtual_grid_tests: SW_VIRTUAL_GRID_ASSAULT
	memo_tests: SW_MEMO_ASSAULT
	tabs_tests: SW_TABS_ASSAULT
	contrast_tests: SW_HIGH_CONTRAST_ASSAULT
	image_tests: SW_WIDGET_IMAGE_ASSAULT
	motion_tests: SW_REDUCED_MOTION_ASSAULT

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run one test; any exception (contract or otherwise) fails it.
		local
			l_retried: BOOLEAN
		do
			if attached (create {EXECUTION_ENVIRONMENT}).item ("SW_ONLY") as al_only
				and then not al_only.is_empty and then not a_name.has_substring (al_only.to_string_8)
			then
					-- SW_ONLY=<part of a name> runs only the tests it names.
			elseif not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_exception then
				if attached al_exception.tag as al_tag then
					print ("        tag: " + al_tag.to_string_8 + "%N")
				end
				if attached al_exception.description as al_text then
					print ("        why: " + al_text.to_string_8 + "%N")
				end
			end
			failed := failed + 1
			l_retried := True
			retry
		end

	passed: INTEGER

	failed: INTEGER

end
