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
