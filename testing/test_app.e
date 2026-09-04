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

			print ("%N=== ACCELERATORS + MNEMONICS ===%N")
			run_keyboard_tests

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

	keyboard_tests: SW_KEYBOARD_ASSAULT

	run_keyboard_tests
		do
			create keyboard_tests
			run_test (agent keyboard_tests.test_mnemonic_parsing, "mnemonic_parsing")
			run_test (agent keyboard_tests.test_an_accelerator_fires_regardless_of_focus, "an_accelerator_fires_regardless_of_focus")
			run_test (agent keyboard_tests.test_the_modifier_state_must_match_exactly, "the_modifier_state_must_match_exactly")
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
