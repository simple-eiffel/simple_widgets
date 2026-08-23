note
	description: "[
		Assault on Wave 5's opening: the tree table's slot and
		header arithmetic, and the graduated cells engine - the
		aggregate law as stated, range dependencies that propagate
		when an empty member fills, command undo walking history
		both ways, TSV blocks, CSV round trips - plus the
		spreadsheet widget's cell geometry and its keyboard commit
		path, driven headless.
	]"

class
	SW_ENTERPRISE_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- Tree fixture

	label_of (a_n: DEMO_NODE): STRING_32
		do
			Result := a_n.label
		end

	kids_of (a_n: DEMO_NODE): ARRAYED_LIST [DEMO_NODE]
		do
			Result := a_n.children
		end

	size_of (a_n: DEMO_NODE): STRING_32
		do
			Result := a_n.children.count.out.to_string_32
		end

feature -- Tree table

	test_tree_table_slots_and_header
		local
			tt: SW_TREE_TABLE [DEMO_NODE]
			roots: ARRAYED_LIST [DEMO_NODE]
			a: DEMO_NODE
		do
			create a.make ("alpha")
			a := a.with_child ("a1").with_child ("a2")
			create roots.make (1)
			roots.extend (a)
			create tt.make (260.0)
			tt.set_label (agent label_of)
			tt.set_children (agent kids_of)
			tt.set_roots (roots)
			tt.add_column (create {SW_GRID_COLUMN [DEMO_NODE]}.make ("kids", 80.0, agent size_of))
			tt.add_column (create {SW_GRID_COLUMN [DEMO_NODE]}.make ("again", 60.0, agent size_of))
			tt.set_bounds (0.0, 0.0, 500.0, 300.0)
			assert_reals_equal ("first value column starts after the tree column",
				tt.tree_col_width, tt.column_x (1) - tt.x, 0.000_1)
			assert_reals_equal ("second column stacks the first's width",
				tt.tree_col_width + 80.0, tt.column_x (2) - tt.x, 0.000_1)
			assert_integers_equal ("the header band owns its strip", 0,
				tt.row_at (tt.y + 2.0))
			assert_integers_equal ("row one begins under the header", 1,
				tt.row_at (tt.y + tt.Header_h + 2.0))
		end

feature -- The graduated engine

	test_cells_aggregate_law
		local
			e: SW_CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (0, 1), "10")
			e.commit (e.key (1, 1), "20")
			e.commit (e.key (0, 2), "5")
			e.commit (e.key (0, 3), "=SUM(A0:A2)")
			assert_strings_equal ("SUM skips the empty member", "30", e.display (e.key (0, 3)))
			e.commit (e.key (1, 3), "=COUNT(A0:A2)")
			assert_strings_equal ("COUNT counts the occupied", "2", e.display (e.key (1, 3)))
			e.commit (e.key (2, 3), "=AVG(A0:A2)")
			assert_strings_equal ("AVG divides by the occupied", "15", e.display (e.key (2, 3)))
			e.commit (e.key (3, 3), "=MIN(A0:A1)")
			assert_strings_equal ("MIN finds the floor", "10", e.display (e.key (3, 3)))
			e.commit (e.key (4, 3), "=MAX(A0:A1)")
			assert_strings_equal ("MAX finds the ceiling", "20", e.display (e.key (4, 3)))
			e.commit (e.key (5, 3), "=SUM(D0:D2)")
			assert_strings_equal ("SUM of nothing is zero", "0", e.display (e.key (5, 3)))
			e.commit (e.key (6, 3), "=AVG(D0:D2)")
			assert_strings_equal ("AVG of nothing is error", "#ERR", e.display (e.key (6, 3)))
			e.commit (e.key (0, 5), "=1/0")
			e.commit (e.key (7, 3), "=SUM(E0:E1)")
			assert_strings_equal ("an erroring member poisons the whole", "#ERR",
				e.display (e.key (7, 3)))
		end

	test_cells_range_propagation
		local
			e: SW_CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (0, 1), "10")
			e.commit (e.key (1, 1), "20")
			e.commit (e.key (0, 3), "=SUM(A0:A2)")
			assert_strings_equal ("the sum before", "30", e.display (e.key (0, 3)))
			e.commit (e.key (2, 1), "5")
			assert_strings_equal ("filling an EMPTY member inside the range propagates",
				"35", e.display (e.key (0, 3)))
			e.commit (e.key (1, 1), "25")
			assert_strings_equal ("changing a member propagates too",
				"40", e.display (e.key (0, 3)))
		end

	test_cells_undo_walks_both_ways
		local
			e: SW_CELLS_ENGINE
		do
			create e.make
			assert ("nothing to undo at birth", not e.can_undo)
			e.commit (e.key (0, 1), "10")
			e.commit (e.key (0, 1), "20")
			assert_strings_equal ("latest stands", "20", e.display (e.key (0, 1)))
			e.undo
			assert_strings_equal ("undo restores the prior", "10", e.display (e.key (0, 1)))
			e.undo
			assert_strings_equal ("undo to bare", "", e.display (e.key (0, 1)))
			assert ("redo is armed", e.can_redo)
			e.redo
			assert_strings_equal ("redo walks forward", "10", e.display (e.key (0, 1)))
			e.commit (e.key (0, 1), "99")
			assert ("a fresh edit clears redo", not e.can_redo)
		end

	test_cells_tsv_blocks
		local
			e: SW_CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (0, 1), "10")
			e.commit (e.key (0, 2), "5")
			e.commit (e.key (1, 1), "20")
			assert_strings_equal ("the block reads row-major, tabbed",
				"10%T5%N20%T", e.block_tsv (0, 1, 1, 2))
			e.paste_tsv (5, 1, "7%T8%N9")
			assert_strings_equal ("paste lands the first row", "7", e.display (e.key (5, 1)))
			assert_strings_equal ("and its neighbour", "8", e.display (e.key (5, 2)))
			assert_strings_equal ("and the second row", "9", e.display (e.key (6, 1)))
		end

	test_cells_csv_round_trip
		local
			e, e2: SW_CELLS_ENGINE
		do
			create e.make
			e.commit (e.key (0, 1), "10")
			e.commit (e.key (1, 2), "=A0*2")
			e.commit (e.key (2, 1), "hello, world")
			create e2.make
			e2.from_csv (e.to_csv)
			assert_strings_equal ("numbers survive", "10", e2.display (e2.key (0, 1)))
			assert_strings_equal ("formulas survive AS formulas", "=A0*2",
				e2.formula (e2.key (1, 2)))
			assert_strings_equal ("and re-evaluate", "20", e2.display (e2.key (1, 2)))
			assert_strings_equal ("quoted commas survive", "hello, world",
				e2.formula (e2.key (2, 1)))
		end

feature -- The widget, headless

	test_spreadsheet_slots_and_keyboard_commit
		local
			sh: SW_SPREADSHEET
		do
			create sh.make
			sh.set_bounds (0.0, 0.0, 600.0, 340.0)
			assert_integers_equal ("above the cells is nobody", -1,
				sh.cell_row_at (sh.y + 10.0))
			assert_integers_equal ("row zero sits under bar and header", 0,
				sh.cell_row_at (sh.y + sh.Bar_h + sh.Header_h + 2.0))
			assert_integers_equal ("the row-number gutter is no column", 0,
				sh.cell_col_at (sh.x + 10.0))
			assert_integers_equal ("column A begins after the gutter", 1,
				sh.cell_col_at (sh.x + sh.Rowhdr_w + 2.0))
				-- type '1','0', Enter: lands in A0, selection drops a row
			sh.handle_char (49)
			sh.handle_char (48)
			assert ("typing opened the edit", sh.is_editing)
			sh.handle_char (13)
			assert_strings_equal ("Enter committed to A0", "10",
				sh.engine.display (sh.engine.key (0, 1)))
			assert_integers_equal ("and the anchor moved down", 1, sh.sel_row)
				-- Ctrl+Z through the widget's own char path
			sh.handle_char (26)
			assert_strings_equal ("Ctrl+Z reached the engine", "",
				sh.engine.display (sh.engine.key (0, 1)))
		end

feature -- Pivot

	test_pivot_folds_and_totals
		local
			pv: SW_PIVOT
		do
			create pv.make
			pv.add_record ("north", "Q1", 10.0)
			pv.add_record ("north", "Q2", 15.0)
			pv.add_record ("south", "Q1", 7.0)
			pv.add_record ("north", "Q1", 5.0)
			assert_integers_equal ("two distinct rows", 2, pv.row_keys.count)
			assert_integers_equal ("two distinct columns", 2, pv.col_keys.count)
			assert_strings_equal ("keys keep first-appearance order", "north", pv.row_keys.first)
			assert_reals_equal ("SUM folds duplicates", 15.0, pv.value_at (1, 1), 0.000_1)
			assert_reals_equal ("row total crosses columns", 30.0, pv.row_total (1), 0.000_1)
			assert_reals_equal ("column total crosses rows", 22.0, pv.col_total (1), 0.000_1)
			assert_reals_equal ("the grand total agrees", 37.0, pv.grand_total, 0.000_1)
			pv.set_mode (pv.Mode_count)
			assert_reals_equal ("COUNT counts records", 2.0, pv.value_at (1, 1), 0.000_1)
			pv.set_mode (pv.Mode_avg)
			assert_reals_equal ("AVG divides the fold", 7.5, pv.value_at (1, 1), 0.000_1)
			assert_reals_equal ("AVG of an empty cell is zero-honest", 0.0, pv.value_at (2, 2), 0.000_1)
		end

feature -- Kanban

	test_kanban_board_truth
		local
			kb: SW_KANBAN
			todo, doing, done: INTEGER
			c1, c2, c3: INTEGER
		do
			create kb.make
			todo := kb.add_lane ("todo")
			doing := kb.add_lane ("doing")
			done := kb.add_lane ("done")
			c1 := kb.add_card (todo, "write it")
			c2 := kb.add_card (todo, "test it")
			c3 := kb.add_card (doing, "ship it")
			assert_integers_equal ("todo holds two", 2, kb.cards_in (todo).count)
			assert_integers_equal ("ids keep order", c1, kb.cards_in (todo).first)
			kb.move_card (c1, done)
			assert_integers_equal ("the moved card left", 1, kb.cards_in (todo).count)
			assert_integers_equal ("and arrived", 1, kb.cards_in (done).count)
			kb.move_card (c1, done)
			assert_integers_equal ("a drop home is a quiet no-op", 1, kb.cards_in (done).count)
		end

	test_kanban_lane_pebbles
		local
			kb: SW_KANBAN
			todo, done: INTEGER
			c1, c2: INTEGER
			lane1, lane3: SW_KANBAN_LANE
		do
			create kb.make
			todo := kb.add_lane ("todo")
			done := kb.add_lane ("done")
			c1 := kb.add_card (todo, "alpha")
			c2 := kb.add_card (todo, "beta")
			if attached {SW_KANBAN_LANE} kb.children.first as l1 then
				lane1 := l1
				lane1.set_bounds (0.0, 0.0, 200.0, 300.0)
				assert_integers_equal ("the first card row answers its id", c1,
					lane1.card_at (lane1.y + lane1.Title_h + 8.0))
				assert_integers_equal ("the second row answers the second", c2,
					lane1.card_at (lane1.y + lane1.Title_h + lane1.Card_h + 14.0))
				assert_integers_equal ("below the stack is nobody", 0,
					lane1.card_at (lane1.y + 290.0))
				assert ("a card id is a welcome pebble", lane1.accepts_pebble (c2))
				assert ("a stranger id is not", not lane1.accepts_pebble (99))
			else
				assert ("first child is a lane", False)
			end
			if attached {SW_KANBAN_LANE} kb.children.i_th (2) as l3 then
				lane3 := l3
				lane3.receive_pebble (c1)
				assert_integers_equal ("receive moved the card", done,
					kb.cards.i_th (c1).lane)
			else
				assert ("second child is a lane", False)
			end
		end

feature -- Boards and plans

	test_scheduler_overlap_lanes
		local
			s: SW_SCHEDULER
		do
			create s.make
			s.add_event (2, 9 * 60, 10 * 60, "standup")
			s.add_event (2, 9 * 60 + 30, 10 * 60 + 30, "review")
			s.add_event (2, 10 * 60, 11 * 60, "focus")
			s.add_event (3, 9 * 60, 17 * 60, "offsite")
			assert_integers_equal ("the first claims lane one", 1, s.lane_of (1))
			assert_integers_equal ("the overlapper takes lane two", 2, s.lane_of (2))
			assert_integers_equal ("back-to-back reuses lane one", 1, s.lane_of (3))
			assert_integers_equal ("tuesday needs two lanes", 2, s.lanes_in_day (2))
			assert_integers_equal ("wednesday needs one", 1, s.lanes_in_day (3))
			assert_integers_equal ("an empty day still stands one wide", 1, s.lanes_in_day (5))
		end

	test_gantt_geometry_and_contracts
		local
			g: SW_GANTT
			t1, t2: INTEGER
		do
			create g.make
			t1 := g.add_task ("design", 0, 4)
			t2 := g.add_task ("build", 4, 6)
			assert_integers_equal ("the horizon is the last touch", 10, g.horizon)
			g.add_dependency (t1, t2)
			assert_integers_equal ("the dependency stands", 1, g.dependencies.count)
			g.set_bounds (0.0, 0.0, 500.0, 200.0)
			g.refresh_domains
			g.x_scale.set_range (g.plot_x, g.plot_x + g.plot_w)
			assert_reals_equal ("a task starting at zero starts at the plot edge",
				g.plot_x, g.bar_x (t1), 0.000_1)
			assert_reals_equal ("bars abut where tasks chain",
				g.bar_x (t1) + g.bar_w (t1), g.bar_x (t2), 0.000_1)
			assert_reals_equal ("rows stack by the row height",
				g.Row_h, g.row_y (t2) - g.row_y (t1), 0.000_1)
		end

feature -- Files, queries, forms, charts of command

	test_file_manager_engine
		local
			fm: SW_FILE_MANAGER
			base: STRING_32
			d: DIRECTORY
			f: PLAIN_TEXT_FILE
		do
			create base.make_from_string_general ("sw_fm_fixture")
			create d.make (base.to_string_8)
			if not d.exists then
				d.create_dir
			end
			create d.make (base.to_string_8 + "/beta")
			if not d.exists then
				d.create_dir
			end
			create d.make (base.to_string_8 + "/alpha")
			if not d.exists then
				d.create_dir
			end
			create f.make_open_write (base.to_string_8 + "/zed.txt")
			f.put_string ("z")
			f.close
			create f.make_open_write (base.to_string_8 + "/able.txt")
			f.put_string ("a")
			f.close
			create fm.make (base)
			assert_integers_equal ("two subdirectories seen", 2, fm.subdirs (base).count)
			assert_integers_equal ("two files listed", 2, fm.file_count)
			assert_strings_equal ("files sort case-blind", "able.txt", fm.file_name (1))
			fm.enter_directory (base + {STRING_32} "/alpha")
			assert_integers_equal ("an empty folder lists nothing", 0, fm.file_count)
		end

	test_query_builder_emission
		local
			qb: SW_QUERY_BUILDER
		do
			create qb.make (<<"name", "age">>)
			assert_strings_equal ("no clauses, no text", "", qb.query_text)
			qb.add_clause
			qb.set_clause (1, 1, 1, "O'Brien")
			assert_strings_equal ("text values quote and double inner quotes",
				"name = 'O''Brien'", qb.query_text)
			qb.add_clause
			qb.set_clause (2, 2, 3, "30")
			assert_strings_equal ("numbers ride bare; AND joins",
				"name = 'O''Brien' AND age > 30", qb.query_text)
			qb.set_join_all (False)
			assert_strings_equal ("OR when asked",
				"name = 'O''Brien' OR age > 30", qb.query_text)
			qb.set_clause (1, 1, 5, "bri")
			assert_strings_equal ("contains becomes LIKE with wildcards",
				"name LIKE '%%bri%%' OR age > 30", qb.query_text)
		end

	test_form_generator_model
		local
			fg: SW_FORM_GENERATOR
		do
			create fg.make
			fg.add_field ("title", fg.Kind_text, True)
			fg.add_field ("count", fg.Kind_number, False)
			fg.add_field ("armed", fg.Kind_check, False)
			assert ("a bare required field blocks completeness", not fg.is_complete)
			fg.set_value ("title", "hello")
			assert ("filling the required completes", fg.is_complete)
			assert_strings_equal ("values read back", "hello", fg.value_of ("title"))
			assert_strings_equal ("checks speak boolean", "False", fg.value_of ("armed"))
			assert_strings_equal ("unknown names answer empty", "", fg.value_of ("ghost"))
		end

	test_org_chart_layout_law
		local
			oc: SW_ORG_CHART
			boss, l1, l2, l3: INTEGER
		do
			create oc.make
			boss := oc.add_node ("boss", 0)
			l1 := oc.add_node ("one", boss)
			l2 := oc.add_node ("two", boss)
			l3 := oc.add_node ("three", boss)
			oc.set_bounds (0.0, 0.0, 600.0, 300.0)
			assert_integers_equal ("the root stands at depth zero", 0, oc.depth_of (boss))
			assert_integers_equal ("children stand one deeper", 1, oc.depth_of (l2))
			assert_reals_equal ("the parent centres over its children's span",
				(oc.node_x (l1) + oc.node_x (l3)) / 2.0, oc.node_x (boss), 0.000_1)
			assert ("siblings pack left to right",
				oc.node_x (l1) < oc.node_x (l2) and oc.node_x (l2) < oc.node_x (l3))
			assert_reals_equal ("rows stack by box plus gap",
				oc.Box_h + oc.Gap_y, oc.node_y (l1) - oc.node_y (boss), 0.000_1)
		end

	test_dock_reflow_law
		local
			dh: SW_DOCK_HOST
			doc: SW_LABEL
			p1, p2: INTEGER
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			create doc.make_ui ("the document")
			create dh.make (doc)
			dh.set_bounds (0.0, 0.0, 800.0, 500.0)
			r := dh.center_rect
			assert_reals_equal ("no panels: the centre takes everything wide",
				800.0, r.rw, 0.000_1)
			assert_reals_equal ("and everything tall", 500.0, r.rh, 0.000_1)
			p1 := dh.add_panel ("explorer", create {SW_LABEL}.make_ui ("tree"), dh.Zone_west)
			p2 := dh.add_panel ("output", create {SW_LABEL}.make_ui ("log"), dh.Zone_south)
			r := dh.zone_rect (dh.Zone_west)
			assert_reals_equal ("an occupied west zone takes its fraction",
				800.0 * 0.22, r.rw, 0.000_1)
			r := dh.zone_rect (dh.Zone_east)
			assert_reals_equal ("an EMPTY zone collapses to nothing", 0.0, r.rw, 0.000_1)
			r := dh.center_rect
			assert_reals_equal ("the centre reflows around the west",
				800.0 - 800.0 * 0.22, r.rw, 0.000_1)
			assert_reals_equal ("and above the south",
				500.0 - 500.0 * 0.30, r.rh, 0.000_1)
			dh.move_panel (p1, dh.Zone_east)
			r := dh.zone_rect (dh.Zone_west)
			assert_reals_equal ("the west collapses once emptied", 0.0, r.rw, 0.000_1)
			r := dh.zone_rect (dh.Zone_east)
			assert ("and the east stands up", r.rw > 0.0)
		end

end
