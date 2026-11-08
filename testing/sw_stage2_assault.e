note
	description: "Hooks for simple_gui's Windows backend, stage 2: data grid header reports and multi-select, tree expansion reports, splitter mirroring."

class
	SW_STAGE2_ASSAULT

inherit
	TEST_SET_BASE

feature -- Tests

	test_a_header_click_is_reported_not_sorted
		local
			w: SW_WINDOW
			g: SW_DATA_GRID [STRING_32]
			l_rows: ARRAYED_LIST [STRING_32]
			l_log: ARRAYED_LIST [STRING]
		do
			create l_log.make (2)
			create w.make ("stage2", 0, 0, 500, 300, create {SW_THEME}.make_light)
			create g.make (200.0)
			g.add_column (create {SW_GRID_COLUMN [STRING_32]}.make ("Book", 150.0, agent (s: STRING_32): STRING_32 do Result := s end))
			g.add_column (create {SW_GRID_COLUMN [STRING_32]}.make ("Back", 150.0, agent (s: STRING_32): STRING_32 do Result := s.mirrored end))
			create l_rows.make (3)
			l_rows.extend ("Genesis")
			l_rows.extend ("Exodus")
			l_rows.extend ("Leviticus")
			g.set_rows (l_rows)
			g.set_on_header_click (agent (c: INTEGER; asc: BOOLEAN; a_log: ARRAYED_LIST [STRING]) do a_log.extend (c.out + " " + asc.out) end (?, ?, l_log))
			w.set_root (g)
			w.request_render
			g.handle_click (g.x + 160.0, g.y + 10.0).do_nothing
			assert_integers_equal ("reported", 1, l_log.count)
			assert_strings_equal ("column 2, ascending", "2 True", l_log.i_th (1))
			assert_integers_equal ("not sorted", 0, g.sort_column)
			assert_strings_equal ("rows keep their order", "Genesis", g.rows.i_th (g.view.i_th (1)))
			g.set_sort_indicator (2, True)
			g.handle_click (g.x + 160.0, g.y + 10.0).do_nothing
			assert_strings_equal ("then descending", "2 False", l_log.i_th (2))
		end

	test_several_rows_select_quietly
		local
			g: SW_DATA_GRID [STRING_32]
			l_rows: ARRAYED_LIST [STRING_32]
			l_count: CELL [INTEGER]
		do
			create l_count.put (0)
			create g.make (200.0)
			g.add_column (create {SW_GRID_COLUMN [STRING_32]}.make ("Book", 150.0, agent (s: STRING_32): STRING_32 do Result := s end))
			create l_rows.make (3)
			l_rows.extend ("Genesis")
			l_rows.extend ("Exodus")
			l_rows.extend ("Leviticus")
			g.set_rows (l_rows)
			g.set_on_select (agent (r: INTEGER; c: CELL [INTEGER]) do c.put (c.item + 1) end (?, l_count))
			g.set_multiple (True)
			g.select_model_row_quietly (1, False)
			g.select_model_row_quietly (3, True)
			assert_integers_equal ("two", 2, g.selected_count)
			assert ("in order", g.selected_at (1) = 1 and g.selected_at (2) = 3)
			assert ("row 2 is not", not g.is_row_selected (2))
			assert_integers_equal ("nothing reported", 0, l_count.item)
			g.select_model_row_quietly (2, False)
			assert_integers_equal ("a plain select replaces", 1, g.selected_count)
		end

	test_a_users_expansion_is_reported
		local
			t: SW_TREE [INTEGER]
			l_roots: ARRAYED_LIST [INTEGER]
			l_log: ARRAYED_LIST [STRING]
		do
			create l_log.make (2)
			create t.make (200.0)
			create l_roots.make (1)
			l_roots.extend (1)
			t.set_roots (l_roots)
			t.set_children (agent (n: INTEGER): ARRAYED_LIST [INTEGER] do create Result.make (2); if n = 1 then Result.extend (2) end end)
			t.set_label (agent (n: INTEGER): STRING_32 do Result := n.out end)
			t.set_on_expansion (agent (n: INTEGER; open: BOOLEAN; a_log: ARRAYED_LIST [STRING]) do a_log.extend (n.out + " " + open.out) end (?, ?, l_log))
			t.expand_node (1)
			t.collapse_node (1)
			assert_integers_equal ("the program's are not reported", 0, l_log.count)
			t.select_node_quietly (1)
			t.handle_key (39, False)
			assert_strings_equal ("Right opens, reported", "1 True", l_log.i_th (1))
			t.handle_key (37, False)
			assert_strings_equal ("Left closes, reported", "1 False", l_log.i_th (2))
		end

	test_tabs_grid_and_tree_read_their_parts
			-- What simple_gui's shared tests read: each tab, the grid's headers and rows, the
			-- tree's shown nodes.
		local
			w: SW_WINDOW
			col: SW_COLUMN
			tabs: SW_TABS
			g: SW_DATA_GRID [STRING_32]
			t: SW_TREE [INTEGER]
			l_rows: ARRAYED_LIST [STRING_32]
			l_roots: ARRAYED_LIST [INTEGER]
			l_tree: STRING_32
		do
			create w.make ("parts", 0, 0, 600, 600, create {SW_THEME}.make_light)
			create col.make
			create tabs.make
			tabs.add_page ("First", create {SW_LABEL}.make_ui ("one"))
			tabs.add_page ("Zweite", create {SW_LABEL}.make_ui ("two"))
			create g.make (150.0)
			g.add_column (create {SW_GRID_COLUMN [STRING_32]}.make ("Book", 150.0, agent (s: STRING_32): STRING_32 do Result := s end))
			create l_rows.make (2)
			l_rows.extend ("Genesis")
			l_rows.extend ("Exodus")
			g.set_rows (l_rows)
			create t.make (120.0)
			create l_roots.make (1)
			l_roots.extend (7)
			t.set_roots (l_roots)
			t.set_children (agent (n: INTEGER): ARRAYED_LIST [INTEGER] do create Result.make (0) end)
			t.set_label (agent (n: INTEGER): STRING_32 do Result := {STRING_32} "Prophets" end)
			col.put (tabs)
			col.put (g)
			col.put (t)
			w.set_root (col)
			w.request_render
			l_tree := w.describe_accessibility
			assert ("each tab: " + l_tree.to_string_8, l_tree.has_substring ("tab: First") and l_tree.has_substring ("tab: Zweite"))
			assert ("the grid's header", l_tree.has_substring ("column-header: Book"))
			assert ("its rows", l_tree.has_substring ("row: Exodus"))
			assert ("the tree's nodes", l_tree.has_substring ("tree-item: Prophets"))
		end

	test_a_splitter_mirrors
		local
			w: SW_WINDOW
			s: SW_SPLITTER
			a, b: SW_LABEL
		do
			create w.make ("stage2", 0, 0, 600, 300, create {SW_THEME}.make_light)
			create a.make_ui ("first")
			create b.make_ui ("second")
			create s.make (a, b)
			s.set_ratio (0.3)
			w.set_root (s)
			w.request_render
			assert ("left to right: first at the left", a.x < b.x)
			s.set_layout_direction ({SW_WIDGET}.Layout_right_to_left)
			w.request_render
			assert ("right to left: first at the right", a.x > b.x)
			assert ("flush right", (a.x + a.width - (s.x + s.width)).abs < 0.5)
			assert ("the divider follows", (s.divider_left - (a.x - {SW_SPLITTER}.Divider_w)).abs < 0.5)
		end

end
