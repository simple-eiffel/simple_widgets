note
	description: "[
		Assault on GW-23, SW_DIAGRAM's layered layout: every edge runs left to
		right, the same graph lays out to the same pixels every time, a
		crossing the node order would make is undone, a cycle is broken by
		one reversed edge and still laid out, and a clause outline of Romans
		1:16-17 with Greek words in both themes (evidence
		gw23_outline_light.png, gw23_outline_dark.png).
	]"

class
	SW_LAYERED_DIAGRAM_ASSAULT

inherit
	SW_SHAPING_ASSAULT

feature -- Layout

	test_gw23_edges_run_left_to_right
			-- A small outline: every edge's head sits in a later layer and to
			-- the right of its tail.
		local
			w: SW_WINDOW
			d: SW_DIAGRAM
		do
			w := window_with (outline)
			d := diagram_of (w)
			assert_integers_equal ("no cycle, nothing reversed", 0, d.back_edge_count)
			across d.edges as e loop
				assert_true ("later layer", d.layer_of.i_th (e.b) > d.layer_of.i_th (e.a))
				assert_true ("to the right", d.nodes.i_th (e.b).px > d.nodes.i_th (e.a).px)
			end
		end

	test_gw23_the_same_graph_lays_out_the_same
			-- Two diagrams built alike, and one drawn twice, land on the same
			-- pixels.
		local
			w1, w2: SW_WINDOW
			d1, d2: SW_DIAGRAM
			i: INTEGER
			l_same: BOOLEAN
		do
			w1 := window_with (outline)
			w2 := window_with (outline)
			d1 := diagram_of (w1)
			d2 := diagram_of (w2)
			w1.request_render
			l_same := True
			from i := 1 until i > d1.nodes.count loop
				l_same := l_same and d1.nodes.i_th (i).px = d2.nodes.i_th (i).px and d1.nodes.i_th (i).py = d2.nodes.i_th (i).py
				i := i + 1
			end
			assert_true ("identical positions", l_same)
		end

	test_gw23_a_crossing_is_undone
			-- A and B in the first layer, C and D in the second, A to D and B
			-- to C: in node order the edges cross; the sweeps uncross them.
		local
			d: SW_DIAGRAM
			w: SW_WINDOW
		do
			create d.make
			d.add_node ("A").do_nothing
			d.add_node ("B").do_nothing
			d.add_node ("C").do_nothing
			d.add_node ("D").do_nothing
			d.connect (1, 4)
			d.connect (2, 3)
			w := window_with (d)
			assert_integers_equal ("no crossing", 0, d.crossing_count)
			assert_true ("two layers", d.layer_of.i_th (1) = 1 and d.layer_of.i_th (3) = 2)
		end

	test_gw23_a_cycle_is_broken_and_laid_out
			-- A to B to C to A: one edge reversed, three distinct layers, every
			-- node placed.
		local
			d: SW_DIAGRAM
			w: SW_WINDOW
		do
			create d.make
			d.add_node ("A").do_nothing
			d.add_node ("B").do_nothing
			d.add_node ("C").do_nothing
			d.connect (1, 2)
			d.connect (2, 3)
			d.connect (3, 1)
			w := window_with (d)
			assert_integers_equal ("one edge reversed", 1, d.back_edge_count)
			assert_true ("the closing edge", d.is_reversed.i_th (3))
			assert_true ("three layers", d.layer_of.i_th (1) = 1 and d.layer_of.i_th (2) = 2 and d.layer_of.i_th (3) = 3)
		end

feature -- Scan 17 (since 086d3e8)

	test_scan17_crossings_of_long_edges_are_counted
			-- HIGH 3: only edges between adjacent layers were counted, so long
			-- edges could cross while the count said 0. A and B each reach X
			-- and Y two layers on (X and Y sit in layer 3 through P and Q): four
			-- long edges, at least one crossing whatever the order.
		local
			d: SW_DIAGRAM
			w: SW_WINDOW
		do
			create d.make
			d.add_node ("A").do_nothing
			d.add_node ("B").do_nothing
			d.add_node ("P").do_nothing
			d.add_node ("Q").do_nothing
			d.add_node ("X").do_nothing
			d.add_node ("Y").do_nothing
			d.connect (3, 4)
			d.connect (4, 5)
			d.connect (4, 6)
			d.connect (1, 5)
			d.connect (1, 6)
			d.connect (2, 5)
			d.connect (2, 6)
			w := window_with (d)
			assert_true ("X and Y two layers after A and B", d.layer_of.i_th (5) = 3 and d.layer_of.i_th (1) = 1)
			assert_true ("the unavoidable crossing is counted: " + d.crossing_count.out, d.crossing_count >= 1)
		end

	test_scan17_a_long_edge_goes_round_the_node_between
			-- HIGH 1: an edge skipping a layer was one straight segment, through
			-- whatever stood between. A to B to C, and A to C: the long edge
			-- bends through a dummy node in B's layer, clear of B.
		local
			d: SW_DIAGRAM
			w: SW_WINDOW
			r: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
		do
			create d.make
			d.add_node ("A").do_nothing
			d.add_node ("B").do_nothing
			d.add_node ("C").do_nothing
			d.connect (1, 2)
			d.connect (2, 3)
			d.connect (1, 3)
			w := window_with (d)
			r := d.edge_route (3)
			assert_integers_equal ("tail, a dummy, head", 3, r.count)
			assert_true ("the dummy stands in B's layer", r [2].px = d.nodes.i_th (2).px)
			assert_true ("and clear of B", (r [2].py - d.nodes.i_th (2).py).abs >= 10.0)
		end

	test_scan17_the_layout_is_cached_and_reproduced
			-- HIGH 2: the old test compared two fresh diagrams. Drawn again, the
			-- layout is not redone; forced again, it lands on the same pixels.
		local
			w: SW_WINDOW
			d: SW_DIAGRAM
			l_before: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			i: INTEGER
			l_same: BOOLEAN
		do
			w := window_with (outline)
			d := diagram_of (w)
			assert_integers_equal ("laid out once", 1, d.layout_runs)
			w.request_render
			w.request_render
			assert_integers_equal ("not again for frames that change nothing", 1, d.layout_runs)
			create l_before.make (d.nodes.count)
			across d.nodes as n loop l_before.extend ([n.px, n.py]) end
			d.set_layered (True)
			w.request_render
			assert_integers_equal ("forced: laid out again", 2, d.layout_runs)
			l_same := True
			from i := 1 until i > d.nodes.count loop
				l_same := l_same and d.nodes.i_th (i).px = l_before [i].px and d.nodes.i_th (i).py = l_before [i].py
				i := i + 1
			end
			assert_true ("on the same pixels", l_same)
		end

feature -- Evidence

	test_gw23_outline_light
		do
			outline_gate (create {SW_THEME}.make_light, "gw23_outline_light.png")
		end

	test_gw23_outline_dark
		do
			outline_gate (create {SW_THEME}.make_dark, "gw23_outline_dark.png")
		end

feature {NONE} -- Fixtures

	outline: SW_DIAGRAM
			-- Romans 1:16-17 as a clause outline: the main clause, its two
			-- grounds and what each grounds.
		do
			create Result.make
			Result.set_layered (True)
			Result.add_node ("I am not ashamed of the gospel").do_nothing
			Result.add_node ("for it is the power of God").do_nothing
			Result.add_node ("for salvation to everyone who believes").do_nothing
			Result.add_node ("to the Jew first and also to the Greek").do_nothing
			Result.add_node ("for in it the righteousness of God is revealed").do_nothing
			Result.add_node ("from faith for faith").do_nothing
			Result.add_node ("as it is written").do_nothing
			Result.add_node ("the righteous shall live by faith").do_nothing
			Result.connect (1, 2)
			Result.connect (2, 3)
			Result.connect (3, 4)
			Result.connect (1, 5)
			Result.connect (5, 6)
			Result.connect (5, 7)
			Result.connect (7, 8)
		end

	window_with (a_diagram: SW_DIAGRAM): SW_WINDOW
		do
			a_diagram.set_layered (True)
			create Result.make ("gw23", 0, 0, 1100, 420, create {SW_THEME}.make_light)
			Result.set_root (a_diagram)
			Result.request_render
		end

	diagram_of (a_window: SW_WINDOW): SW_DIAGRAM
		do
			check attached {SW_DIAGRAM} a_window.root as al_d then
				Result := al_d
			end
		end

	outline_gate (a_theme: SW_THEME; a_name: STRING)
			-- The outline with two Greek words, shaped, nothing skipped.
		local
			w: SW_WINDOW
			kit: SW_SHAPING
			d: SW_DIAGRAM
			path: STRING_32
		do
			d := outline
			d.add_node (text_of (<<0x03B5, 0x1F50, 0x03B1, 0x03B3, 0x03B3, 0x03AD, 0x03BB, 0x03B9, 0x03BF, 0x03BD>>)).do_nothing
			d.add_node (text_of (<<0x03B4, 0x03B9, 0x03BA, 0x03B1, 0x03B9, 0x03BF, 0x03C3, 0x03CD, 0x03BD, 0x03B7>>)).do_nothing
			d.connect (1, 9)
			d.connect (5, 10)
			d.with_title ("Romans 1:16-17").do_nothing
			create w.make ("gw23", 0, 0, 1180, 460, a_theme)
			kit := gw03_kit (a_theme)
			w.set_shaping (kit)
			w.set_root (d)
			w.request_render
			assert_integers_equal ("nothing skipped", 0, kit.bridge.skipped_runs)
			assert_integers_equal ("no crossing in the outline", 0, d.crossing_count)
			path := evidence_path (a_name)
			if not path.is_empty then
				if w.write_frame (path) then
				end
			end
		end

end
