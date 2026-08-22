note
	description: "[
		Assault on the dev studio suite: the mesh's depth-limited
		harvest and frontier disclosure, the node context menu, the
		names toggle, the studio's pane swap on selection, and the
		live edit driving a PUBLIC setter with every contract armed.
		All headless - the physics never needs a window to be true.
	]"

class
	SW_DEV_STUDIO_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- Fixture

	deep_root: SW_COLUMN
			-- root(0) > [branch(1), stray label(1)];
			-- branch > [label(2), text box(2), sub column(2)];
			-- sub column > one leaf label(3).
			-- Six widgets to depth 2; the seventh hides below.
		local
			branch, sub: SW_COLUMN
		do
			create Result.make
			create branch.make
			create sub.make
			sub.put (create {SW_LABEL}.make_ui ("deep leaf"))
			branch.put (create {SW_LABEL}.make_ui ("edit me"))
			branch.put (create {SW_TEXT_BOX}.make_single_line ("seed"))
			branch.put (sub)
			Result.put (branch)
			Result.put (create {SW_LABEL}.make_ui ("shallow leaf"))
		end

	frontier_count (a_mesh: SW_MESH): INTEGER
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_mesh.node_count
			loop
				if a_mesh.nodes.i_th (i).frontier then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	first_frontier (a_mesh: SW_MESH): INTEGER
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_mesh.node_count or Result > 0
			loop
				if a_mesh.nodes.i_th (i).frontier then
					Result := i
				end
				i := i + 1
			end
		end

	node_index_of (a_mesh: SW_MESH; a_w: SW_WIDGET): INTEGER
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_mesh.node_count or Result > 0
			loop
				if a_mesh.nodes.i_th (i).w = a_w then
					Result := i
				end
				i := i + 1
			end
		end

feature -- Mesh

	test_mesh_depth_limit_and_frontier
		local
			m: SW_MESH
		do
			create m.make_over (deep_root, 2)
			assert_integers_equal ("six widgets to depth 2", 6, m.node_count)
			assert_integers_equal ("exactly one frontier node (the sub column)", 1, frontier_count (m))
		end

	test_mesh_expand_grows_in_place
		local
			m: SW_MESH
			k, old_edges: INTEGER
		do
			create m.make_over (deep_root, 2)
			k := first_frontier (m)
			old_edges := m.edges.count
			m.expand_at (k)
			assert_integers_equal ("the hidden leaf joined", 7, m.node_count)
			assert ("its frontier flag cleared", not m.nodes.i_th (k).frontier)
			assert_integers_equal ("one new edge to the parent", old_edges + 1, m.edges.count)
			assert_integers_equal ("nothing left to disclose", 0, frontier_count (m))
		end

	test_mesh_full_harvest_no_frontier
		local
			m: SW_MESH
		do
			create m.make_over (deep_root, 9)
			assert_integers_equal ("all seven harvested", 7, m.node_count)
			assert_integers_equal ("no frontier at full depth", 0, frontier_count (m))
		end

	test_mesh_context_menu_nodes_only
		local
			m: SW_MESH
		do
			create m.make_over (deep_root, 2)
			if attached m.context_menu (m.nodes.i_th (1).px, m.nodes.i_th (1).py) as menu then
				assert_integers_equal ("four actions on a node", 4, menu.items.count)
			else
				assert ("a node offers its menu", False)
			end
			assert ("open space offers nothing", m.context_menu (9_999.0, 9_999.0) = Void)
		end

	test_mesh_names_toggle
		local
			m: SW_MESH
		do
			create m.make_over (deep_root, 2)
			assert ("names start hidden", not m.show_labels)
			m.toggle_labels
			assert ("toggle shows all names", m.show_labels)
			m.toggle_labels
			assert ("toggle hides them again", not m.show_labels)
		end

feature -- Re-rooting

	test_mesh_pebble_hole_types
		local
			m: SW_MESH
		do
			create m.make_over (deep_root, 2)
			assert ("a widget pebble is welcome", m.accepts_pebble (create {SW_LABEL}.make_ui ("pb")))
			assert ("a string is not a graph", not m.accepts_pebble ({STRING_32} "nope"))
		end

	test_mesh_re_root_follows_the_drop
		local
			m: SW_MESH
			r, branch: SW_COLUMN
		do
			r := deep_root
			create m.make_over (r, 9)
			assert_integers_equal ("whole tree first", 7, m.node_count)
			if attached {SW_COLUMN} m.nodes.i_th (2).w as b then
				branch := b
				m.receive_pebble (branch)
				assert_integers_equal ("re-rooted at the branch: five survive", 5, m.node_count)
				assert ("the drop wears the crown", m.nodes.i_th (1).w = branch)
				assert_integers_equal ("depths re-zeroed", 0, m.nodes.i_th (1).depth)
			else
				assert ("fixture second node is the branch", False)
			end
		end

	test_studio_pane_follows_re_root
		local
			s: SW_DEV_STUDIO
		do
			create s.make_over (deep_root, 2)
			s.mesh.receive_pebble (s.mesh.nodes.i_th (1).w)
			assert ("re-root announced through on_select", s.subject = s.mesh.nodes.i_th (1).w)
		end

feature -- The law

	test_lens_ignores_its_own_chrome
			-- Larry's law: the instrument never inspects the
			-- instrument - chips, reveals and dev-mode picking all
			-- gate on DEV_LENS.observes.
		local
			lens: DEV_LENS
			m: SW_MESH
			s: SW_DEV_STUDIO
			insp: SW_INSPECTOR
			free: SW_LABEL
		do
			create lens
			create free.make_ui ("a page widget")
			assert ("a page widget is observed", lens.observes (free))
			create m.make_over (deep_root, 2)
			assert ("the mesh is exempt", not lens.observes (m))
			create s.make_over (deep_root, 2)
			assert ("the studio is exempt", not lens.observes (s))
			assert ("the studio's mesh is exempt through its chain", not lens.observes (s.mesh))
			create insp.make_for (free)
			assert ("an inspector column is exempt", not lens.observes (insp))
			if attached {SW_WIDGET} insp.children.first as row then
				assert ("a row INSIDE an inspector is exempt via its chain",
					not lens.observes (row))
			else
				assert ("inspector holds rows", False)
			end
		end

	test_studio_aim_at_syncs_pane_and_mesh
		local
			s: SW_DEV_STUDIO
			foreign: SW_LABEL
		do
			create s.make_over (deep_root, 2)
			s.aim_at (s.mesh.nodes.i_th (1).w)
			assert ("aim sets the subject", s.subject = s.mesh.nodes.i_th (1).w)
			assert_integers_equal ("aim lights the node", 1, s.mesh.selected_index)
			create foreign.make_ui ("not in the graph")
			s.aim_at (foreign)
			assert ("foreign subjects still land in the pane", s.subject = foreign)
			assert_integers_equal ("no node pretends to hold it", 0, s.mesh.selected_index)
		end

feature -- Studio

	test_studio_pane_swaps_on_select
		local
			s: SW_DEV_STUDIO
		do
			create s.make_over (deep_root, 2)
			assert ("no subject before any click", s.subject = Void)
			assert_integers_equal ("the invitation holds the pane", 1, s.pane_line_count)
			s.mesh.handle_click (s.mesh.nodes.i_th (1).px, s.mesh.nodes.i_th (1).py).do_nothing
			assert ("the root became the subject", s.subject = s.mesh.nodes.i_th (1).w)
			assert_integers_equal ("a plain container: dossier scroll only", 1, s.pane_line_count)
		end

	test_studio_live_edit_drives_public_setter
		local
			s: SW_DEV_STUDIO
			k: INTEGER
			tb: detachable SW_TEXT_BOX
			lb: detachable SW_LABEL
			i: INTEGER
		do
			create s.make_over (deep_root, 9)
				-- find the text box node and select it through the mesh
			from
				i := 1
			until
				i > s.mesh.node_count or tb /= Void
			loop
				if attached {SW_TEXT_BOX} s.mesh.nodes.i_th (i).w as f then
					tb := f
					k := i
				end
				i := i + 1
			end
			if attached tb as box then
				s.mesh.handle_click (s.mesh.nodes.i_th (k).px, s.mesh.nodes.i_th (k).py).do_nothing
				assert ("the box is the subject", s.subject = box)
				assert_integers_equal ("dossier + rig label + box + apply", 4, s.pane_line_count)
				assert_strings_equal ("edit box preloaded from the subject", "seed", s.edit_text)
				s.set_edit_text ("driven from the pane")
				s.apply_edit
				assert_strings_equal ("set_text drove the live widget",
					"driven from the pane", box.text)
			else
				assert ("fixture holds a text box", False)
			end
				-- and the label path
			from
				i := 1
				lb := Void
			until
				i > s.mesh.node_count or lb /= Void
			loop
				if attached {SW_LABEL} s.mesh.nodes.i_th (i).w as f
					and then f.text.same_string_general ("edit me")
				then
					lb := f
					k := i
				end
				i := i + 1
			end
			if attached lb as lab then
				s.mesh.handle_click (s.mesh.nodes.i_th (k).px, s.mesh.nodes.i_th (k).py).do_nothing
				s.set_edit_text ("relabelled live")
				s.apply_edit
				assert_strings_equal ("labels live-edit too", "relabelled live", lab.text)
			else
				assert ("fixture holds the label", False)
			end
		end

	test_inspector_full_lifts_field_cap
		local
			compact, full: SW_INSPECTOR
			tb: SW_TEXT_BOX
		do
			create tb.make_single_line ("cap probe")
			create compact.make_for (tb)
			create full.make_full (tb)
			assert ("a text box overflows the compact cap",
				full.line_count > compact.line_count)
		end

end
