note
	description: "[
		Assault on the tree (flatten math, lazy children, identity-
		stable selection) and the colour picker (HSV<->RGB on known
		values, clamps).
	]"

class
	SW_TREE_COLOR_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- Tree fixture

	probes: INTEGER
			-- How many times the children agent was consulted.

	kids_of (a_n: DEMO_NODE): ARRAYED_LIST [DEMO_NODE]
		do
			probes := probes + 1
			Result := a_n.children
		end

	label_of (a_n: DEMO_NODE): STRING_32
		do
			Result := a_n.label
		end

	new_forest: ARRAYED_LIST [DEMO_NODE]
		local
			a, b: DEMO_NODE
		do
			create Result.make (2)
			create a.make ("alpha")
			a := a.with_child ("a1").with_child ("a2").with_child ("a3")
			create b.make ("beta")
			b := b.with_child ("b1")
			Result.extend (a)
			Result.extend (b)
		end

	new_tree (a_forest: ARRAYED_LIST [DEMO_NODE]): SW_TREE [DEMO_NODE]
		do
			create Result.make (200.0)
			Result.set_label (agent label_of)
			Result.set_children (agent kids_of)
			Result.set_roots (a_forest)
		end

feature -- Tree

	test_flatten_follows_disclosure
		local
			f: ARRAYED_LIST [DEMO_NODE]
			tr: SW_TREE [DEMO_NODE]
		do
			f := new_forest
			tr := new_tree (f)
			assert_integers_equal ("collapsed shows roots only", 2, tr.visible.count)
			tr.expand_node (f.i_th (1))
			assert_integers_equal ("alpha opens to 5 rows", 5, tr.visible.count)
			assert_integers_equal ("children are deeper", 1, tr.visible.i_th (2).depth)
			tr.expand_node (f.i_th (2))
			assert_integers_equal ("both open: 6 rows", 6, tr.visible.count)
			tr.collapse_node (f.i_th (1))
			assert_integers_equal ("alpha folds back", 3, tr.visible.count)
		end

	test_children_agent_is_lazy_enough
			-- The agent runs for triangle probing, but a collapsed
			-- node's GRANDCHILDREN are never probed.
		local
			f: ARRAYED_LIST [DEMO_NODE]
			tr: SW_TREE [DEMO_NODE]
			collapsed_probes: INTEGER
		do
			f := new_forest
			probes := 0
			tr := new_tree (f)
			collapsed_probes := probes
			assert ("collapsed probes only the roots", collapsed_probes = 2)
			tr.expand_node (f.i_th (1))
			assert ("expansion probes the opened node's children too", probes > collapsed_probes)
		end

	test_selection_is_identity_stable
		local
			f: ARRAYED_LIST [DEMO_NODE]
			tr: SW_TREE [DEMO_NODE]
		do
			f := new_forest
			tr := new_tree (f)
			tr.expand_node (f.i_th (1))
			tr.select_node (f.i_th (1).children.i_th (2))
			tr.collapse_node (f.i_th (1))
			assert ("selection survives the fold (object identity)",
				attached tr.selected_node as sn and then sn = f.i_th (1).children.i_th (2))
			tr.expand_node (f.i_th (1))
			assert ("and is findable again after reopening",
				attached tr.selected_node as sn2 and then sn2.label.same_string_general ("a2"))
		end

	test_tree_bar_thumb_in_track_and_drags
			-- On a long tree the thumb stays inside its track at the end,
			-- the bar drags, and the drag ends on release.
		local
			f: ARRAYED_LIST [DEMO_NODE]
			tr: SW_TREE [DEMO_NODE]
			n: DEMO_NODE
			i: INTEGER
			p: SW_PAINTER
			surf: CAIRO_SURFACE
			ctx: CAIRO_CONTEXT
			th: SW_THEME
			l_scroll: REAL_64
		do
			create th.make_light
			create surf.make (300, 200)
			create ctx.make (surf)
			create p.make (ctx, th)
			create f.make (300)
			from i := 1 until i > 300 loop
				create n.make ("node")
				f.extend (n)
				i := i + 1
			end
			tr := new_tree (f)
			tr.set_bounds (0.0, 0.0, 300.0, 200.0)
			tr.draw (p)
			if tr.handle_wheel (-120 * 1000) then end
			assert_reals_equal ("scrolled to the end", tr.max_scroll, tr.scroll_y, 0.001)
			assert ("thumb ends inside the track",
				tr.bar.thumb_top (tr.scroll_y) + tr.bar.thumb_height <= tr.bar.track_y + tr.bar.track_h + 0.001)
			assert ("a press on the thumb is taken", tr.handle_click (tr.bar.track_x + 2.0, tr.bar.thumb_top (tr.scroll_y) + 2.0))
			assert ("the bar is dragging", tr.bar.is_dragging)
			tr.handle_drag (100.0, 20.0)
			assert ("the drag moved the view up", tr.scroll_y < tr.max_scroll)
			tr.handle_release (100, 20)
			assert ("released", not tr.bar.is_dragging)
			l_scroll := tr.scroll_y
			tr.handle_drag (100.0, 150.0)
			assert_reals_equal ("a later drag does nothing", l_scroll, tr.scroll_y, 0.0)
			ctx.destroy
			surf.destroy
		end

feature -- Inspector

	test_inspector_reveals_truth
		local
			b: SW_BUTTON
			ins: SW_INSPECTOR
		do
			create b.make ("Probe", Void)
			b.set_bounds (10.0, 20.0, 100.0, 38.0)
			b.set_dev_note ("the probe subject")
			create ins.make_for (b)
			assert ("headline names the class", ins.summary.has_substring ({STRING_32} "SW_BUTTON"))
			assert ("headline carries geometry", ins.summary.has_substring ({STRING_32} "100x38"))
			assert ("a real dossier", ins.line_count >= 8)
		end

feature -- Dropzone

	test_dropzone_contract
		local
			dz: SW_DROPZONE
			paths: ARRAYED_LIST [STRING_32]
		do
			create dz.make ("Drop here")
			assert ("welcomes files when enabled", dz.accepts_files)
			dz.set_enabled (False)
			assert ("disabled refuses", not dz.accepts_files)
			dz.set_enabled (True)
			create paths.make (2)
			paths.extend ({STRING_32} "C:/one.txt")
			paths.extend ({STRING_32} "C:/two.png")
			dropped_count := 0
			dz.set_on_drop (agent record_drop)
			dz.receive_files (paths, 10.0, 10.0)
			assert_integers_equal ("agent told twice-blessed", 2, dropped_count)
			assert ("last drop kept", dz.last_paths = paths)
		end

feature {NONE} -- Drop recording

	dropped_count: INTEGER

	record_drop (a_paths: ARRAYED_LIST [STRING_32])
		do
			dropped_count := a_paths.count
		end

feature -- Colour

	test_hsv_to_rgb_known_values
		local
			cp: SW_COLOR_PICKER
		do
			create cp.make (0)
			assert ("red", cp.hsv_to_rgb (0.0, 1.0, 1.0) = 0xFF0000)
			assert ("green", cp.hsv_to_rgb (120.0, 1.0, 1.0) = 0x00FF00)
			assert ("blue", cp.hsv_to_rgb (240.0, 1.0, 1.0) = 0x0000FF)
			assert ("cyan", cp.hsv_to_rgb (180.0, 1.0, 1.0) = 0x00FFFF)
			assert ("white", cp.hsv_to_rgb (0.0, 0.0, 1.0) = 0xFFFFFF)
			assert ("black", cp.hsv_to_rgb (123.0, 0.5, 0.0) = 0x000000)
		end

	test_rgb_round_trips
		local
			cp: SW_COLOR_PICKER
		do
			create cp.make (0x4D8FD6)
			assert ("accent survives", cp.rgb = 0x4D8FD6)
			cp.set_rgb (0xFF0000)
			assert ("red survives", cp.rgb = 0xFF0000)
			cp.set_rgb (0x000000)
			assert ("black survives", cp.rgb = 0x000000)
			cp.set_rgb (0xFFFFFF)
			assert ("white survives", cp.rgb = 0xFFFFFF)
		end

	test_hex_readout
		local
			cp: SW_COLOR_PICKER
		do
			create cp.make (0x0C2766)
			assert ("hex renders", cp.hex_text.same_string_general ("#0C2766"))
		end

end
