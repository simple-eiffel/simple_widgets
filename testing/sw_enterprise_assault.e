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
			assert_strings_equal ("and its neighbor", "8", e.display (e.key (5, 2)))
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
			assert_reals_equal ("the parent centers over its children's span",
				(oc.node_x (l1) + oc.node_x (l3)) / 2.0, oc.node_x (boss), 0.000_1)
			assert ("siblings pack left to right",
				oc.node_x (l1) < oc.node_x (l2) and oc.node_x (l2) < oc.node_x (l3))
			assert_reals_equal ("rows stack by box plus gap",
				oc.Box_h + oc.Gap_y, oc.node_y (l1) - oc.node_y (boss), 0.000_1)
		end

	test_dock_panel_buttons_follow_their_conditions
			-- A button inside a docked panel, in a column, re-queries its enabling condition when
			-- the window's enabling pass walks the dock (2026-10-31: the Atlas's Undo point, End,
			-- Close shape and Delete kept the state they were made with, so only Start worked;
			-- the zones never passed the pass on to their panels).
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			col: SW_COLUMN
			b: SW_BUTTON
		do
			create w.make ("dock-enabling", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			create col.make
			create b.make ("Delete", Void)
			col.put (b)
			if dh.add_panel ("ATLAS", col, dh.Zone_east) > 0 then end
			w.set_root (dh)
			w.request_render
			dock_flag := False
			b.set_enabled_when (agent: BOOLEAN do Result := dock_flag end)
			assert_false ("made disabled", b.is_enabled)
			dock_flag := True
			dh.refresh_enabling
			assert_true ("the window's pass enables it", b.is_enabled)
			dock_flag := False
			dh.refresh_enabling
			assert_false ("and disables it again", b.is_enabled)
		end

	dock_flag: BOOLEAN
			-- The condition `test_dock_panel_buttons_follow_their_conditions' flips.

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
			assert_reals_equal ("no panels: the center takes everything wide",
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
			assert_reals_equal ("the center reflows around the west",
				800.0 - 800.0 * 0.22, r.rw, 0.000_1)
			assert_reals_equal ("and above the south",
				500.0 - 500.0 * 0.30, r.rh, 0.000_1)
			dh.move_panel (p1, dh.Zone_east)
			r := dh.zone_rect (dh.Zone_west)
			assert_reals_equal ("the west collapses once emptied", 0.0, r.rw, 0.000_1)
			r := dh.zone_rect (dh.Zone_east)
			assert ("and the east stands up", r.rw > 0.0)
		end

feature -- Dock north zone

	north_dock: SW_DOCK_HOST
			-- An 800 x 500 host with a west, an east and a north panel.
		do
			create Result.make (create {SW_LABEL}.make_ui ("the document"))
			Result.set_bounds (0.0, 0.0, 800.0, 500.0)
			if Result.add_keyed_panel ("W1", "explorer", create {SW_LABEL}.make_ui ("tree"), Result.Zone_west) > 0 then end
			if Result.add_keyed_panel ("E1", "properties", create {SW_LABEL}.make_ui ("form"), Result.Zone_east) > 0 then end
			if Result.add_keyed_panel ("N1", "toolbox", create {SW_LABEL}.make_ui ("tools"), Result.Zone_north) > 0 then end
		end

	test_dock_north_band_across_the_top
			-- A north panel takes a band across the top, full width; west
			-- and east start below it; the center is what is left; an
			-- empty north zone takes nothing.
		local
			dh: SW_DOCK_HOST
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			dh.set_bounds (0.0, 0.0, 800.0, 500.0)
			if dh.add_panel ("explorer", create {SW_LABEL}.make_ui ("tree"), dh.Zone_west) > 0 then end
			r := dh.zone_rect (dh.Zone_north)
			assert_reals_equal ("an empty north zone takes no height", 0.0, r.rh, 0.000_1)
			r := dh.zone_rect (dh.Zone_west)
			assert_reals_equal ("so the west still starts at the top", 0.0, r.ry, 0.000_1)
			assert_reals_equal ("and runs the full height", 500.0, r.rh, 0.000_1)
			dh := north_dock
			r := dh.zone_rect (dh.Zone_north)
			assert_reals_equal ("the band starts at the left", 0.0, r.rx, 0.000_1)
			assert_reals_equal ("and at the top", 0.0, r.ry, 0.000_1)
			assert_reals_equal ("it is full width", 800.0, r.rw, 0.000_1)
			assert_reals_equal ("and its fraction of the height", 500.0 * 0.20, r.rh, 0.000_1)
			r := dh.zone_rect (dh.Zone_west)
			assert_reals_equal ("the west starts below the band", 100.0, r.ry, 0.000_1)
			assert_reals_equal ("and runs to the bottom", 400.0, r.rh, 0.000_1)
			r := dh.zone_rect (dh.Zone_east)
			assert_reals_equal ("the east starts below the band", 100.0, r.ry, 0.000_1)
			assert_reals_equal ("and runs to the bottom too", 400.0, r.rh, 0.000_1)
			r := dh.center_rect
			assert_reals_equal ("the center starts below the band", 100.0, r.ry, 0.000_1)
			assert_reals_equal ("and keeps what is left down", 400.0, r.rh, 0.000_1)
			assert_reals_equal ("and across", 800.0 - 800.0 * 0.22 - 800.0 * 0.24, r.rw, 0.000_1)
			assert_true ("north is a zone", dh.is_zone (dh.Zone_north))
			assert_false ("and nothing beyond it is", dh.is_zone (dh.Zone_north + 1))
			assert_true ("it has a title for menus", dh.zone_title (dh.Zone_north).same_string ("top panel area"))
		end

	test_dock_north_and_south_keep_the_center
			-- North and south together never leave the center less than
			-- Min_center down.
		local
			dh: SW_DOCK_HOST
			r, n, s: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			dh := north_dock
			if dh.add_keyed_panel ("S1", "output", create {SW_LABEL}.make_ui ("log"), dh.Zone_south) > 0 then end
			dh.set_fraction (dh.Zone_north, dh.Max_fraction)
			dh.set_fraction (dh.Zone_south, dh.Max_fraction)
			r := dh.center_rect
			assert_reals_equal ("the center keeps its minimum down", dh.Min_center, r.rh, 0.000_1)
			n := dh.zone_rect (dh.Zone_north)
			s := dh.zone_rect (dh.Zone_south)
			assert_reals_equal ("the two bands and the center fill the host", 500.0, n.rh + s.rh + r.rh, 0.000_1)
			assert_reals_equal ("the south ends at the bottom", 500.0, s.ry + s.rh, 0.000_1)
			assert_reals_equal ("the center sits between them", n.ry + n.rh, r.ry, 0.000_1)
			dh.set_bounds (0.0, 0.0, 800.0, 100.0)
			r := dh.center_rect
			assert_true ("a host shorter than the minimum still leaves no negative center", r.rh >= 0.0)
		end

	test_dock_north_edge_drags_to_resize
			-- The inner edge of the north zone is its bottom edge: edge_at
			-- finds it, a drag sets its fraction from y, and it clamps.
		local
			dh: SW_DOCK_HOST
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			dh := north_dock
			r := dh.zone_rect (dh.Zone_north)
			assert_integers_equal ("the bottom edge of the band is the north edge", dh.Zone_north, dh.edge_at (300.0, r.ry + r.rh))
			assert_integers_equal ("a little inside still grips", dh.Zone_north, dh.edge_at (300.0, r.ry + r.rh - 2.0))
			assert_integers_equal ("the middle of the band is no edge", 0, dh.edge_at (300.0, r.ry + r.rh / 2.0))
			assert_integers_equal ("the top of the host is no edge", 0, dh.edge_at (300.0, 0.0))
			assert_true ("the edge answers as the host", attached dh.widget_at (300.0, r.ry + r.rh) as al_w and then al_w = dh)
			assert_true ("a press grabs it", dh.handle_click (300.0, r.ry + r.rh))
			dh.handle_drag (300.0, 250.0)
			assert_reals_equal ("the drag sets the fraction from y", 0.5, dh.north_fraction, 0.000_1)
			dh.handle_drag (300.0, 5.0)
			assert_reals_equal ("and stops at the smallest share", dh.Min_fraction, dh.north_fraction, 0.000_1)
			dh.handle_drag (300.0, 490.0)
			assert_reals_equal ("and at the largest", dh.Max_fraction, dh.north_fraction, 0.000_1)
			dh.set_fraction (dh.Zone_north, 0.3)
			assert_reals_equal ("set_fraction reaches it too", 0.3, dh.fraction (dh.Zone_north), 0.000_1)
			assert_reals_equal ("and the band follows", 150.0, dh.zone_rect (dh.Zone_north).rh, 0.000_1)
			assert_integers_equal ("the west edge still works below the band", dh.Zone_west,
				dh.edge_at (800.0 * 0.22, 300.0))
			assert_integers_equal ("but not beside the band", 0, dh.edge_at (800.0 * 0.22, 50.0))
		end

	test_dock_north_fold_is_an_across_strip
			-- Folding north makes an across strip along the top; expanding
			-- restores the fraction.
		local
			dh: SW_DOCK_HOST
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			dh := north_dock
			dh.set_fraction (dh.Zone_north, 0.3)
			assert_true ("north runs across", dh.zone_widget (dh.Zone_north).is_across)
			assert_true ("so does south", dh.zone_widget (dh.Zone_south).is_across)
			assert_false ("west runs down", dh.zone_widget (dh.Zone_west).is_across)
			dh.collapse_zone (dh.Zone_north)
			assert_true ("it is folded", dh.is_folded (dh.Zone_north))
			r := dh.zone_rect (dh.Zone_north)
			assert_reals_equal ("the strip is at the top", 0.0, r.ry, 0.000_1)
			assert_reals_equal ("across the whole width", 800.0, r.rw, 0.000_1)
			assert_reals_equal ("as tall as a bar and its margin", dh.strip_extent (dh.Zone_north), r.rh, 0.000_1)
			assert_true ("and no taller than the band was", r.rh < 150.0)
			assert_reals_equal ("the west starts below the strip", r.rh, dh.zone_rect (dh.Zone_west).ry, 0.000_1)
			assert_integers_equal ("a folded zone has no edge", 0, dh.edge_at (300.0, r.rh))
			dh.expand_zone (dh.Zone_north)
			assert_false ("expanded", dh.is_folded (dh.Zone_north))
			assert_reals_equal ("the fraction came back", 0.3, dh.north_fraction, 0.000_1)
			assert_reals_equal ("and the band", 150.0, dh.zone_rect (dh.Zone_north).rh, 0.000_1)
		end

	test_dock_north_panels_move_and_the_menu_offers_it
			-- move_panel to and from north; the zone context menu offers
			-- "Move to the" and the title of north (and not from north to
			-- itself).
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			z: SW_DOCK_ZONE
		do
			create w.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			if dh.add_keyed_panel ("W1", "explorer", create {SW_LABEL}.make_ui ("tree"), dh.Zone_west) > 0 then end
			w.set_root (dh)
			w.request_render
			z := dh.zone_widget (dh.Zone_west)
			w.simulate_context_click ((z.x + 20.0).truncated_to_integer, (z.y + 4.0).truncated_to_integer)
			if attached w.open_popup as al_menu then
				assert_true ("the menu offers the top", al_menu.index_of_label ({STRING_32} "Move to the " + dh.zone_title (dh.Zone_north)) > 0)
				assert_true ("and still the bottom", al_menu.index_of_label ("Move to the bottom") > 0)
				assert_true ("Collapse the west", al_menu.index_of_label ("Collapse the left side") > 0)
			else
				assert_true ("a title bar offers a menu", False)
			end
			dh.move_panel (1, dh.Zone_north)
			assert_integers_equal ("the panel is in north", dh.Zone_north, dh.panels.i_th (1).zone)
			assert_true ("the west emptied", dh.panels_in (dh.Zone_west).is_empty)
			assert_reals_equal ("the west took nothing", 0.0, dh.zone_rect (dh.Zone_west).rw, 0.000_1)
			assert_true ("north stands up", dh.zone_rect (dh.Zone_north).rh > 0.0)
			create w.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			w.set_root (dh)
			w.request_render
			z := dh.zone_widget (dh.Zone_north)
			w.simulate_context_click ((z.x + 20.0).truncated_to_integer, (z.y + 4.0).truncated_to_integer)
			if attached w.open_popup as al_menu then
				assert_true ("north offers the left side", al_menu.index_of_label ("Move to the left side") > 0)
				assert_true ("and the bottom", al_menu.index_of_label ("Move to the bottom") > 0)
				assert_true ("but not itself", al_menu.index_of_label ({STRING_32} "Move to the " + dh.zone_title (dh.Zone_north)) = 0)
				assert_true ("and folds as the top", al_menu.index_of_label ({STRING_32} "Collapse the " + dh.zone_title (dh.Zone_north)) > 0)
			else
				assert_true ("a north title bar offers a menu", False)
			end
			dh.move_panel (1, dh.Zone_east)
			assert_true ("and out of north", dh.panels_in (dh.Zone_north).is_empty)
			assert_reals_equal ("north took nothing again", 0.0, dh.zone_rect (dh.Zone_north).rh, 0.000_1)
		end

	test_dock_north_snapshot_round_trip
			-- layout_snapshot writes north like the others and restore_layout
			-- reads it; a snapshot written without north restores as before.
		local
			a, b: SW_DOCK_HOST
			snap, old_snap: STRING_32
		do
			a := north_dock
			a.set_fraction (a.Zone_north, 0.35)
			a.collapse_zone (a.Zone_north)
			snap := a.layout_snapshot
			assert_true ("the snapshot names north", snap.has_substring ("fraction%Tnorth%T0.3"))
			assert_true ("and its fold", snap.has_substring ("collapsed%Tnorth"))
			b := north_dock
			b.set_fraction (b.Zone_north, 0.5)
			b.restore_layout (snap)
			assert_true ("it read", b.last_restore_ok)
			assert_reals_equal ("the north share", 0.35, b.north_fraction, 0.000_1)
			assert_true ("the north fold", b.is_collapsed (b.Zone_north))
			assert_integers_equal ("N1 is in north", b.Zone_north, b.panels.i_th (b.panel_by_key ("N1")).zone)
			assert_true ("the same layout, line for line", b.layout_snapshot.same_string (snap))
				-- an old snapshot: the same text without any north line
			create old_snap.make (200)
			across snap.split ('%N') as ic loop
				if not ic.has_substring ("north") then
					if not old_snap.is_empty then
						old_snap.append_character ('%N')
					end
					old_snap.append (ic)
				end
			end
			assert_false ("the old text has no north", old_snap.has_substring ("north"))
			create b.make (create {SW_LABEL}.make_ui ("the document"))
			b.set_bounds (0.0, 0.0, 800.0, 500.0)
			if b.add_keyed_panel ("W1", "explorer", create {SW_LABEL}.make_ui ("tree"), b.Zone_west) > 0 then end
			if b.add_keyed_panel ("E1", "properties", create {SW_LABEL}.make_ui ("form"), b.Zone_east) > 0 then end
			b.restore_layout (old_snap)
			assert_true ("an old snapshot reads", b.last_restore_ok)
			assert_true ("north stays empty", b.panels_in (b.Zone_north).is_empty)
			assert_reals_equal ("with its default share", 0.20, b.north_fraction, 0.000_1)
			assert_false ("and unfolded", b.is_collapsed (b.Zone_north))
			assert_reals_equal ("west and east as before", 800.0 * 0.22, b.zone_rect (b.Zone_west).rw, 0.000_1)
		end

feature -- Dock 1r-b

	rb_events: INTEGER
			-- How many times a 1r-b dock announced a layout change.

	rb_bump
		do
			rb_events := rb_events + 1
		end

	rb_dock: SW_DOCK_HOST
			-- An 800 x 500 host: south A, B, C (ids 1..3), west W (4), north N (5), east E (6).
		do
			create Result.make (create {SW_LABEL}.make_ui ("the document"))
			Result.set_bounds (0.0, 0.0, 800.0, 500.0)
			if Result.add_keyed_panel ("A", "alpha", create {SW_LABEL}.make_ui ("a"), Result.Zone_south) > 0 then end
			if Result.add_keyed_panel ("B", "beta", create {SW_LABEL}.make_ui ("b"), Result.Zone_south) > 0 then end
			if Result.add_keyed_panel ("C", "gamma", create {SW_LABEL}.make_ui ("c"), Result.Zone_south) > 0 then end
			if Result.add_keyed_panel ("W", "west one", create {SW_LABEL}.make_ui ("w"), Result.Zone_west) > 0 then end
			if Result.add_keyed_panel ("N", "north one", create {SW_LABEL}.make_ui ("n"), Result.Zone_north) > 0 then end
			if Result.add_keyed_panel ("E", "east one", create {SW_LABEL}.make_ui ("e"), Result.Zone_east) > 0 then end
		end

	rb_window (a_host: SW_DOCK_HOST): SW_WINDOW
			-- A window whose root is `a_host', rendered once.
		do
			create Result.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			Result.set_root (a_host)
			Result.request_render
		end

	rb_same_rect (a, b: TUPLE [rx, ry, rw, rh: REAL_64]): BOOLEAN
		do
			Result := (a.rx - b.rx).abs < 0.000_1 and (a.ry - b.ry).abs < 0.000_1
				and (a.rw - b.rw).abs < 0.000_1 and (a.rh - b.rh).abs < 0.000_1
		end

	test_dock_1rb_move_panel_to_orders_a_zone
			-- move_panel_to sets the place among a zone's panels; ids stay;
			-- panels_in, all_panels_in and the tabs follow; adds and moves append.
		local
			dh: SW_DOCK_HOST
			w: SW_WINDOW
			l_id: INTEGER
		do
			dh := rb_dock
			dh.set_on_layout_change (agent rb_bump)
			rb_events := 0
			dh.move_panel_to (3, dh.Zone_south, 1)
			assert_integers_equal ("C leads", 3, dh.all_panels_in (dh.Zone_south).first)
			assert_true ("the order is C A B", dh.all_panels_in (dh.Zone_south).i_th (2) = 1 and dh.all_panels_in (dh.Zone_south).i_th (3) = 2)
			assert_integers_equal ("one announcement", 1, rb_events)
			assert_true ("ids did not change", dh.panels.i_th (3).key.same_string ("C") and dh.panels.i_th (1).key.same_string ("A")
				and dh.panels.i_th (2).key.same_string ("B"))
			dh.move_panel_to (3, dh.Zone_south, 1)
			assert_integers_equal ("the same place says nothing", 1, rb_events)
			dh.hide_panel (1)
			assert_true ("panels_in follows the order and skips hidden", dh.panels_in (dh.Zone_south).count = 2
				and dh.panels_in (dh.Zone_south).first = 3 and dh.panels_in (dh.Zone_south).last = 2)
			assert_integers_equal ("all_panels_in still counts the hidden", 3, dh.all_panels_in (dh.Zone_south).count)
			dh.show_panel (1)
				-- from another zone: it moves, then takes its place
			dh.move_panel_to (4, dh.Zone_south, 2)
			assert_integers_equal ("W is now south", dh.Zone_south, dh.panels.i_th (4).zone)
			assert_true ("and second there", dh.all_panels_in (dh.Zone_south).i_th (2) = 4)
			assert_true ("the old zone let it go", dh.all_panels_in (dh.Zone_west).is_empty)
			dh.move_panel_to (4, dh.Zone_south, 4)
			assert_true ("the last place", dh.all_panels_in (dh.Zone_south).last = 4)
			l_id := dh.add_keyed_panel ("F", "fifth", create {SW_LABEL}.make_ui ("f"), dh.Zone_south)
			assert_integers_equal ("add_panel appends", l_id, dh.all_panels_in (dh.Zone_south).last)
			dh.move_panel (3, dh.Zone_north)
			assert_integers_equal ("move_panel appends to the new zone", 3, dh.all_panels_in (dh.Zone_north).last)
			assert_true ("and leaves the old", not dh.all_panels_in (dh.Zone_south).has (3))
				-- drawing and tabs follow the order
			dh.set_tabbed (dh.Zone_south, True)
			dh.move_panel_to (2, dh.Zone_south, 1)
			w := rb_window (dh)
			assert_true ("the tabs follow the order", dh.zone_widget (dh.Zone_south).tab_ids.count = dh.panels_in (dh.Zone_south).count)
			assert_integers_equal ("first tab is B", 2, dh.zone_widget (dh.Zone_south).tab_ids.first)
			assert_true ("and the rest as ordered", dh.zone_widget (dh.Zone_south).tab_ids.is_equal (dh.panels_in (dh.Zone_south)))
			dh.set_tabbed (dh.Zone_south, False)
			w.request_render
			assert_integers_equal ("a stacked zone's first bar is B too", 2,
				dh.zone_widget (dh.Zone_south).panel_at_bar (dh.zone_widget (dh.Zone_south).y + 2.0))
		end

	test_dock_1rb_remove_after_reordering
			-- remove_panel drops the id from the orders and shifts the higher ids down.
		local
			dh: SW_DOCK_HOST
		do
			dh := rb_dock
			dh.move_panel_to (3, dh.Zone_south, 1)
			dh.remove_panel (1)
			assert_integers_equal ("two left in the south", 2, dh.all_panels_in (dh.Zone_south).count)
			assert_integers_equal ("C is now id 2 and leads", 2, dh.all_panels_in (dh.Zone_south).first)
			assert_integers_equal ("B is now id 1", 1, dh.all_panels_in (dh.Zone_south).last)
			assert_true ("the keys moved with the ids", dh.panels.i_th (2).key.same_string ("C") and dh.panels.i_th (1).key.same_string ("B"))
			assert_integers_equal ("W shifted down to 3", 3, dh.all_panels_in (dh.Zone_west).first)
			dh.remove_panel (2)
			assert_integers_equal ("the last of the order goes too", 1, dh.all_panels_in (dh.Zone_south).count)
			assert_integers_equal ("B stays", 1, dh.all_panels_in (dh.Zone_south).first)
		end

	test_dock_1rb_auto_hide_slides_a_panel_over_the_center
			-- An auto-hide zone stands as its strip; slide_out shows the
			-- panel over the center without reflow; slide_back hides it.
		local
			dh: SW_DOCK_HOST
			w: SW_WINDOW
			l_center, l_slide, l_zone: TUPLE [rx, ry, rw, rh: REAL_64]
			l_strip: SW_DOCK_ZONE
		do
			dh := rb_dock
			w := rb_window (dh)
			dh.set_on_layout_change (agent rb_bump)
			rb_events := 0
			assert_false ("not auto-hide to begin with", dh.is_auto_hide (dh.Zone_west))
			dh.set_auto_hide (dh.Zone_west, True)
			w.request_render
			assert_true ("it is auto-hide", dh.is_auto_hide (dh.Zone_west))
			assert_false ("which is not collapse", dh.is_collapsed (dh.Zone_west))
			assert_true ("it stands as a strip", dh.is_folded (dh.Zone_west))
			assert_integers_equal ("announced", 1, rb_events)
			l_zone := dh.zone_rect (dh.Zone_west)
			assert_reals_equal ("a strip wide", dh.strip_extent (dh.Zone_west), l_zone.rw, 0.000_1)
			l_strip := dh.zone_widget (dh.Zone_west)
			assert_true ("the strip names the panel", l_strip.strip_titles.count = 1)
			assert_integers_equal ("nothing slid out", 0, dh.slid_out_panel)
			l_center := dh.center_rect
			dh.slide_out (4)
			w.request_render
			assert_integers_equal ("W is out", 4, dh.slid_out_panel)
			assert_integers_equal ("announced again", 2, rb_events)
			assert_true ("the center did not reflow", rb_same_rect (l_center, dh.center_rect))
			l_slide := dh.slide_rect
			assert_reals_equal ("it stands beside the strip", l_zone.rx + l_zone.rw, l_slide.rx, 0.000_1)
			assert_reals_equal ("at the zone's size", dh.width * dh.west_fraction, l_slide.rw, 0.000_1)
			assert_true ("OVER the center", l_slide.rx < l_center.rx + l_center.rw and l_slide.rx + l_slide.rw > l_center.rx)
			assert_true ("its content is seated inside it", dh.panels.i_th (4).content.x >= l_slide.rx
				and dh.panels.i_th (4).content.x < l_slide.rx + l_slide.rw)
			assert_true ("and answers hits", attached dh.widget_at (l_slide.rx + 30.0, l_slide.ry + 40.0) as al_h
				and then al_h /= dh.center)
			dh.slide_back
			w.request_render
			assert_integers_equal ("back in", 0, dh.slid_out_panel)
			assert_true ("the slide has no extent", dh.slide_rect.rw = 0.0)
			assert_integers_equal ("announced a third time", 3, rb_events)
			dh.slide_back
			assert_integers_equal ("a second slide_back says nothing", 3, rb_events)
				-- a press on the name slides it out; a press outside sends it back
			assert_true ("the strip takes the press", l_strip.handle_click (l_strip.x + l_strip.width / 2.0,
				(l_strip.strip_titles.first.lo + l_strip.strip_titles.first.hi) / 2.0))
			assert_integers_equal ("a press on the name slides it out", 4, dh.slid_out_panel)
			assert_true ("a press on the center is outside", not dh.handle_click (l_center.rx + l_center.rw - 20.0, l_center.ry + 50.0))
			assert_integers_equal ("and slides it back", 0, dh.slid_out_panel)
				-- a rest on the name does it too
			assert_true ("a strip dwells", l_strip.dwell_ms > 0)
			l_strip.handle_dwell (l_strip.x + l_strip.width / 2.0, (l_strip.strip_titles.first.lo + l_strip.strip_titles.first.hi) / 2.0)
			assert_integers_equal ("a rest slides it out", 4, dh.slid_out_panel)
				-- a press inside it leaves it out
			l_slide := dh.slide_rect
			w.request_render
			l_slide := dh.slide_rect
			assert_false ("a press inside the slid panel keeps it", dh.handle_click (l_slide.rx + 20.0, l_slide.ry + 20.0))
			assert_integers_equal ("still out", 4, dh.slid_out_panel)
				-- expand_zone clears auto-hide and the slide
			dh.expand_zone (dh.Zone_west)
			assert_false ("expand_zone turns auto-hide off", dh.is_auto_hide (dh.Zone_west))
			assert_integers_equal ("and takes the panel in", 0, dh.slid_out_panel)
			assert_false ("the zone stands open", dh.is_folded (dh.Zone_west))
			assert_reals_equal ("at its fraction", dh.width * dh.west_fraction, dh.zone_rect (dh.Zone_west).rw, 0.000_1)
		end

	test_dock_1rb_auto_hide_pin_button
			-- The bar's pin button turns auto-hide on and off, and announces.
		local
			dh: SW_DOCK_HOST
			w: SW_WINDOW
			l_zone: SW_DOCK_ZONE
			b: detachable TUPLE [kind, panel: INTEGER; bx, by, side: REAL_64]
			i: INTEGER
		do
			dh := rb_dock
			w := rb_window (dh)
			dh.set_on_layout_change (agent rb_bump)
			rb_events := 0
			l_zone := dh.zone_widget (dh.Zone_east)
			from
				i := 1
			until
				i > l_zone.buttons.count
			loop
				if l_zone.buttons.i_th (i).kind = l_zone.Button_pin then
					b := l_zone.buttons.i_th (i)
				end
				i := i + 1
			end
			assert_true ("the open zone's bar has a pin", b /= Void)
			if attached b as al_b then
				assert_integers_equal ("button_at finds it", l_zone.Button_pin, l_zone.button_at (al_b.bx + 2.0, al_b.by + 2.0).kind)
				assert_true ("a click takes it", l_zone.handle_click (al_b.bx + 2.0, al_b.by + 2.0))
			end
			assert_true ("the pin turned auto-hide on", dh.is_auto_hide (dh.Zone_east))
			assert_integers_equal ("and announced", 1, rb_events)
			w.request_render
			assert_true ("the strip has a pin as well", l_zone.buttons.count >= 2 and then l_zone.buttons.i_th (2).kind = l_zone.Button_pin)
			l_zone.press_button (l_zone.Button_pin, 0)
			assert_false ("pressed again it turns it off", dh.is_auto_hide (dh.Zone_east))
			assert_integers_equal ("announced again", 2, rb_events)
				-- the pin on a strip click path
			dh.set_auto_hide (dh.Zone_east, True)
			w.request_render
			assert_true ("a click on the strip's pin", l_zone.handle_click (l_zone.buttons.i_th (2).bx + 2.0, l_zone.buttons.i_th (2).by + 2.0))
			assert_false ("turns it off", dh.is_auto_hide (dh.Zone_east))
		end

	test_dock_1rb_maximize_center_round_trip
			-- The center takes the host; every zone keeps its fold, auto-hide
			-- state and fraction for restore_center.
		local
			dh: SW_DOCK_HOST
			l_before: ARRAY [TUPLE [rx, ry, rw, rh: REAL_64]]
			l_center: TUPLE [rx, ry, rw, rh: REAL_64]
			z: INTEGER
		do
			dh := rb_dock
			dh.set_on_layout_change (agent rb_bump)
			dh.set_fraction (dh.Zone_south, 0.4)
			dh.collapse_zone (dh.Zone_east)
			dh.set_auto_hide (dh.Zone_north, True)
			dh.slide_out (5)
			create l_before.make_filled ([0.0, 0.0, 0.0, 0.0], dh.Zone_west, dh.Zone_north)
			from
				z := dh.Zone_west
			until
				z > dh.Zone_north
			loop
				l_before [z] := dh.zone_rect (z)
				z := z + 1
			end
			l_center := dh.center_rect
			rb_events := 0
			dh.maximize_center
			assert_true ("maximized", dh.is_center_maximized)
			assert_integers_equal ("announced", 1, rb_events)
			assert_integers_equal ("a slid panel goes in", 0, dh.slid_out_panel)
			assert_true ("the center has the whole host", rb_same_rect (dh.center_rect, [0.0, 0.0, 800.0, 500.0]))
			from
				z := dh.Zone_west
			until
				z > dh.Zone_north
			loop
				assert_true ("every zone stands nowhere", dh.zone_rect (z).rw = 0.0 and dh.zone_rect (z).rh = 0.0)
				assert_integers_equal ("no zone has an edge", 0, dh.edge_at (dh.zone_rect (z).rx + 1.0, 300.0))
				z := z + 1
			end
			dh.maximize_center
			assert_integers_equal ("again says nothing", 1, rb_events)
			dh.restore_center
			assert_false ("restored", dh.is_center_maximized)
			assert_integers_equal ("announced", 2, rb_events)
			assert_true ("east is still collapsed", dh.is_collapsed (dh.Zone_east))
			assert_true ("north is still auto-hide", dh.is_auto_hide (dh.Zone_north))
			assert_false ("and not collapsed", dh.is_collapsed (dh.Zone_north))
			assert_reals_equal ("south has its fraction", 0.4, dh.south_fraction, 0.000_1)
			from
				z := dh.Zone_west
			until
				z > dh.Zone_north
			loop
				assert_true ("every zone is where it was", rb_same_rect (l_before [z], dh.zone_rect (z)))
				z := z + 1
			end
			assert_true ("and the center", rb_same_rect (l_center, dh.center_rect))
				-- maximize_panel keeps working, and the two do not combine
			dh.set_maximizable (4, True)
			dh.maximize_panel (4)
			assert_integers_equal ("the panel has the host", 4, dh.maximized_panel)
			dh.maximize_center
			assert_integers_equal ("the center takes it from the panel", 0, dh.maximized_panel)
			dh.maximize_panel (4)
			assert_false ("and a panel takes it from the center", dh.is_center_maximized)
			dh.restore_maximized
			assert_integers_equal ("restore_maximized still works", 0, dh.maximized_panel)
		end

	test_dock_1rb_snapshot_round_trip
			-- The snapshot writes and restores order, auto-hide and the
			-- maximized center; an old snapshot restores with the order of ids.
		local
			a, b: SW_DOCK_HOST
			snap, old_snap: STRING_32
		do
			a := rb_dock
			a.move_panel_to (3, a.Zone_south, 1)
			a.move_panel_to (1, a.Zone_south, 3)
			a.set_auto_hide (a.Zone_west, True)
			a.set_auto_hide (a.Zone_east, True)
			a.collapse_zone (a.Zone_east)
			a.maximize_center
			snap := a.layout_snapshot
			assert_true ("the snapshot has the order", snap.has_substring ("order%Tsouth%TC%TB%TA"))
			assert_true ("and auto-hide", snap.has_substring ("autohide%Twest"))
			assert_true ("and the maximized center", snap.has_substring ("center_maximized"))
			b := rb_dock
			b.restore_layout (snap)
			assert_true ("it read", b.last_restore_ok)
			assert_true ("the order came back", b.all_panels_in (b.Zone_south).count = 3
				and b.panels.i_th (b.all_panels_in (b.Zone_south).i_th (1)).key.same_string ("C")
				and b.panels.i_th (b.all_panels_in (b.Zone_south).i_th (2)).key.same_string ("B")
				and b.panels.i_th (b.all_panels_in (b.Zone_south).i_th (3)).key.same_string ("A"))
			assert_true ("west auto-hide", b.is_auto_hide (b.Zone_west))
			assert_true ("east both", b.is_auto_hide (b.Zone_east) and b.is_collapsed (b.Zone_east))
			assert_false ("south not", b.is_auto_hide (b.Zone_south))
			assert_true ("the center is maximized", b.is_center_maximized)
			assert_true ("line for line", b.layout_snapshot.same_string (snap))
			a.restore_center
			b.restore_layout (a.layout_snapshot)
			assert_false ("a snapshot without the line restores the center", b.is_center_maximized)
				-- an old snapshot: no order, autohide or center lines
			create old_snap.make (200)
			across snap.split ('%N') as ic loop
				if not (ic.starts_with ("order") or ic.starts_with ("autohide") or ic.starts_with ("center_maximized")) then
					if not old_snap.is_empty then
						old_snap.append_character ('%N')
					end
					old_snap.append (ic)
				end
			end
			assert_false ("the old text has no order line", old_snap.has_substring ("order"))
			b := rb_dock
			b.set_auto_hide (b.Zone_north, True)
			b.maximize_center
			b.restore_layout (old_snap)
			assert_true ("an old snapshot reads", b.last_restore_ok)
			assert_false ("without the center", b.is_center_maximized)
			assert_false ("without auto-hide", b.is_auto_hide (b.Zone_north) or b.is_auto_hide (b.Zone_west))
			assert_true ("collapse still restores", b.is_collapsed (b.Zone_east))
			assert_true ("the order is that of the ids", b.all_panels_in (b.Zone_south).count = 3
				and b.panels.i_th (b.all_panels_in (b.Zone_south).first).key.same_string ("A")
				and b.panels.i_th (b.all_panels_in (b.Zone_south).last).key.same_string ("C"))
		end

feature -- Dock (GW-05)

	test_gw05_tabbed_zone_shows_one_panel
			-- Five panels in the south zone: stacked, each gets a fifth;
			-- tabbed, one tab each, the active panel fills the zone, a
			-- click on a tab (through the window) shows that panel, the
			-- content answers hit tests, and a tab lifts its panel as a
			-- pebble.
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			z: SW_DOCK_ZONE
			ids: ARRAYED_LIST [INTEGER]
			r: TUPLE [rx, ry, rw, rh: REAL_64]
		do
			create w.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			create ids.make (5)
			across <<"Word Study", "Search Results", "Guides", "Census", "Notes">> as t loop
				ids.extend (dh.add_panel (t, create {SW_LABEL}.make_ui (t), dh.Zone_south))
			end
			dock_changes := 0
			dh.set_on_layout_change (agent do dock_changes := dock_changes + 1 end)
			w.set_root (dh)
			w.request_render
			z := dh.zone_widget (dh.Zone_south)
			r := dh.zone_rect (dh.Zone_south)
			assert_reals_equal ("stacked: each panel a fifth", r.rh / 5.0, z.panel_slot_h, 0.000_1)
			dh.set_tabbed (dh.Zone_south, True)
			assert_integers_equal ("switching to tabs is a layout change", 1, dock_changes)
			w.request_render
			assert_integers_equal ("one tab per panel", 5, z.tab_ids.count)
			assert_integers_equal ("the first panel shows", ids [1], dh.active_panel (dh.Zone_south))
			assert_reals_equal ("and fills the zone under the strip",
				r.rh - z.bar_h - 2.0 * z.content_pad, dh.panels [ids [1]].content.height, 0.000_1)
			assert_true ("tabs left to right without overlap",
				across 2 |..| 5 as k all z.tab_lefts [k] >= z.tab_lefts [k - 1] + z.tab_widths [k - 1] - 0.000_1 end)
			w.dispatch (2, (z.tab_lefts [3] + z.tab_widths [3] / 2.0).truncated_to_integer, (r.ry + 8.0).truncated_to_integer)
			w.dispatch (10, (z.tab_lefts [3] + z.tab_widths [3] / 2.0).truncated_to_integer, (r.ry + 8.0).truncated_to_integer)
			assert_integers_equal ("a click on the third tab shows Guides", ids [3], dh.active_panel (dh.Zone_south))
			assert_integers_equal ("and is a layout change", 2, dock_changes)
			assert_true ("the shown panel answers hit tests",
				dh.widget_at (r.rx + 40.0, r.ry + z.bar_h + 20.0) = dh.panels [ids [3]].content)
			if attached {INTEGER_REF} z.pebble_at (z.tab_lefts [4] + 4.0, r.ry + 8.0) as al_id then
				assert_integers_equal ("a tab lifts its panel", ids [4], al_id.item)
			else
				assert_true ("a tab is a pebble source", False)
			end
		end

	test_gw05_edges_drag_and_clamp
			-- Through the window: the west edge shows the left-right
			-- cursor, follows a drag, stops at the largest share and
			-- announces once on release; the south edge drags too; the
			-- center always keeps its minimum.
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			r: TUPLE [rx, ry, rw, rh: REAL_64]
			ex, ey: INTEGER
		do
			create w.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			if dh.add_panel ("explorer", create {SW_LABEL}.make_ui ("tree"), dh.Zone_west) > 0 then end
			if dh.add_panel ("output", create {SW_LABEL}.make_ui ("log"), dh.Zone_south) > 0 then end
			if dh.add_panel ("properties", create {SW_LABEL}.make_ui ("form"), dh.Zone_east) > 0 then end
			w.set_root (dh)
			w.request_render
			dock_changes := 0
			dh.set_on_layout_change (agent do dock_changes := dock_changes + 1 end)
			r := dh.zone_rect (dh.Zone_west)
			ex := (r.rx + r.rw).truncated_to_integer
			ey := (r.ry + r.rh / 2.0).truncated_to_integer
			assert_integers_equal ("the west edge is found", dh.Zone_west, dh.edge_at (ex, ey))
			w.dispatch (13, ex, ey)
			assert_integers_equal ("with the left-right cursor", 3, dh.cursor_kind)
			w.dispatch (2, ex, ey)
			w.dispatch (9, (dh.x + dh.width * 0.4).truncated_to_integer, ey)
			assert_reals_equal ("the edge follows the drag", 0.4,
				dh.west_fraction, 2.0 / dh.width)
			assert_integers_equal ("no announcement mid-drag", 0, dock_changes)
			w.dispatch (9, (dh.x + dh.width * 0.95).truncated_to_integer, ey)
			assert_reals_equal ("and stops at the largest share", dh.Max_fraction, dh.west_fraction, 0.000_1)
			w.dispatch (10, (dh.x + dh.width * 0.95).truncated_to_integer, ey)
			assert_integers_equal ("one announcement on release", 1, dock_changes)
			assert_integers_equal ("released", 0, dh.dragging_edge)
			w.request_render
			assert_true ("the center keeps its minimum across", dh.center_rect.rw >= dh.Min_center - 0.000_1)
			r := dh.zone_rect (dh.Zone_south)
			w.dispatch (13, (r.rx + 300.0).truncated_to_integer, r.ry.truncated_to_integer)
			assert_integers_equal ("the south edge shows the up-down cursor", 4, dh.cursor_kind)
			w.dispatch (2, (r.rx + 300.0).truncated_to_integer, r.ry.truncated_to_integer)
			w.dispatch (9, (r.rx + 300.0).truncated_to_integer, (dh.y + dh.height * 0.5).truncated_to_integer)
			w.dispatch (10, (r.rx + 300.0).truncated_to_integer, (dh.y + dh.height * 0.5).truncated_to_integer)
			assert_reals_equal ("the south edge follows", 0.5, dh.south_fraction, 2.0 / dh.height)
			dh.set_fraction (dh.Zone_east, 0.6)
			assert_true ("west and east squeezed: the center still keeps its minimum",
				dh.center_rect.rw >= dh.Min_center - 0.000_1)
		end

	test_gw05_hide_show_remove
			-- Hiding a zone's only panel collapses the zone and keeps the
			-- panel; showing it brings it back where it was; removing lets
			-- it go, the ids after it shift, and keys still find panels.
		local
			dh: SW_DOCK_HOST
			p1, p2, p3: INTEGER
		do
			create dh.make (create {SW_LABEL}.make_ui ("the document"))
			dh.set_bounds (0.0, 0.0, 800.0, 500.0)
			p1 := dh.add_keyed_panel ("P04", "Cross references", create {SW_LABEL}.make_ui ("x"), dh.Zone_east)
			p2 := dh.add_keyed_panel ("P05", "Word study", create {SW_LABEL}.make_ui ("w"), dh.Zone_south)
			p3 := dh.add_keyed_panel ("P07", "Search results", create {SW_LABEL}.make_ui ("s"), dh.Zone_south)
			dh.set_tabbed (dh.Zone_south, True)
			dh.hide_panel (p1)
			assert_false ("hidden", dh.is_panel_visible (p1))
			assert_reals_equal ("its zone collapsed", 0.0, dh.zone_rect (dh.Zone_east).rw, 0.0)
			assert_integers_equal ("but it is still in the zone", 1, dh.all_panels_in (dh.Zone_east).count)
			dh.show_panel (p1)
			assert_true ("shown again, where it was", dh.is_panel_visible (p1) and dh.panels [p1].zone = dh.Zone_east)
			dh.activate_panel (p3)
			dh.hide_panel (p3)
			assert_integers_equal ("hiding the shown tab shows the other", p2, dh.active_panel (dh.Zone_south))
			dh.show_panel (p3)
			assert_integers_equal ("showing a hidden tab shows it", p3, dh.active_panel (dh.Zone_south))
			dh.remove_panel (p2)
			assert_integers_equal ("one fewer", 2, dh.panels.count)
			assert_integers_equal ("the key finds the shifted panel", 2, dh.panel_by_key ("P07"))
			assert_integers_equal ("its tab is still the shown one", 2, dh.active_panel (dh.Zone_south))
			assert_integers_equal ("a removed key finds nothing", 0, dh.panel_by_key ("P05"))
		end

	test_gw05_snapshot_round_trip
			-- A layout's snapshot restored into a host built the default
			-- way gives the same layout back, line for line; a panel the
			-- snapshot does not name keeps its state and follows; a key it
			-- names that the host lacks is passed over; text that does not
			-- read changes nothing.
		local
			a, b: SW_DOCK_HOST
			snap, before: STRING_32
		do
			a := study_dock
			a.set_tabbed (a.Zone_south, True)
			a.activate_panel (a.panel_by_key ("P09"))
			a.set_fraction (a.Zone_south, 0.4)
			a.set_fraction (a.Zone_west, 0.18)
			a.move_panel (a.panel_by_key ("P04"), a.Zone_west)
			a.hide_panel (a.panel_by_key ("P08"))
			snap := a.layout_snapshot
			b := study_dock
			b.restore_layout (snap)
			assert_true ("it read", b.last_restore_ok)
			assert_true ("the same layout, line for line", b.layout_snapshot.same_string (snap))
			assert_integers_equal ("Census is the shown tab", b.panel_by_key ("P09"), b.active_panel (b.Zone_south))
			assert_false ("Guides is hidden", b.is_panel_visible (b.panel_by_key ("P08")))
			assert_reals_equal ("the south share", 0.4, b.south_fraction, 0.000_1)
			b := study_dock
			if b.add_keyed_panel ("P20", "Notes", create {SW_LABEL}.make_ui ("n"), b.Zone_east) > 0 then end
			b.restore_layout (snap + {STRING_32} "%Npanel%TP99%Twest%Tshown")
			assert_true ("an unknown key is passed over", b.last_restore_ok)
			assert_integers_equal ("a panel it does not name keeps its zone", b.Zone_east, b.panels [b.panel_by_key ("P20")].zone)
			assert_integers_equal ("and follows the named ones", b.panels.count, b.panel_by_key ("P20"))
			b := study_dock
			before := b.layout_snapshot
			dock_changes := 0
			b.set_on_layout_change (agent do dock_changes := dock_changes + 1 end)
			b.restore_layout ("sw_dock 1%Nfraction%Twest%Tlots")
			assert_false ("a bad line: not read", b.last_restore_ok)
			assert_true ("and nothing changed", b.layout_snapshot.same_string (before))
			assert_integers_equal ("nor was it announced", 0, dock_changes)
			b.restore_layout ("not a dock")
			assert_false ("a wrong header: not read", b.last_restore_ok)
		end

	test_gw05_spacing_follows_the_theme
			-- The zone takes its spacing from the theme's Vision2 tokens, not
			-- from constants: content inset = border_width, tab padding =
			-- control_inset, bar = measured title + padding. At 2x text every
			-- one of them doubles.
		local
			w1, w2: SW_WINDOW
			d1, d2: SW_DOCK_HOST
			t2: SW_THEME
			z1, z2: SW_DOCK_ZONE
		do
			create w1.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			d1 := study_dock
			d1.set_tabbed (d1.Zone_south, True)
			w1.set_root (d1)
			w1.request_render
			create t2.make_light
			t2.set_text_scale (2.0)
			create w2.make ("dock", 0, 0, 1800, 1200, t2)
			d2 := study_dock
			d2.set_tabbed (d2.Zone_south, True)
			w2.set_root (d2)
			w2.request_render
			z1 := d1.zone_widget (d1.Zone_south)
			z2 := d2.zone_widget (d2.Zone_south)
			assert_reals_equal ("content inset is the theme's border", w1.theme.border_width, z1.content_pad, 0.000_1)
			assert_reals_equal ("tab padding is the theme's control inset", w1.theme.control_inset, z1.tab_pad, 0.000_1)
			assert_reals_equal ("the inset doubles at 2x", 2.0 * z1.content_pad, z2.content_pad, 0.000_1)
			assert_reals_equal ("the tab padding doubles at 2x", 2.0 * z1.tab_pad, z2.tab_pad, 0.000_1)
			assert_true ("the bar grows with the text (about double)",
				z2.bar_h > 1.8 * z1.bar_h and z2.bar_h < 2.2 * z1.bar_h)
		end

	study_dock: SW_DOCK_HOST
			-- simple_bible's Study layout, built the default way.
		do
			create Result.make (create {SW_LABEL}.make_ui ("reader"))
			Result.set_bounds (0.0, 0.0, 1200.0, 800.0)
			if Result.add_keyed_panel ("P04", "Cross references", create {SW_LABEL}.make_ui ("x"), Result.Zone_east) > 0 then end
			if Result.add_keyed_panel ("P05", "Word study", create {SW_LABEL}.make_ui ("w"), Result.Zone_south) > 0 then end
			if Result.add_keyed_panel ("P07", "Search results", create {SW_LABEL}.make_ui ("s"), Result.Zone_south) > 0 then end
			if Result.add_keyed_panel ("P08", "Guides", create {SW_LABEL}.make_ui ("g"), Result.Zone_south) > 0 then end
			if Result.add_keyed_panel ("P09", "Census", create {SW_LABEL}.make_ui ("c"), Result.Zone_south) > 0 then end
		end

	dock_changes: INTEGER


end
