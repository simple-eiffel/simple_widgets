note
	description: "[
		Assault on 0.46.0: right-click menus everywhere and panes that
		fold and maximize. A client's `menu_extension' stands above a
		widget's own items; a grid, a tree, a paragraph list, a document
		view and a label each offer Copy; a grid's right-click names
		its row WITHOUT selecting it; a dock zone folds to a strip whose
		names open it again, a panel maximizes and restores, and a title
		bar's menu offers both. Driven through SW_WINDOW where the
		gesture matters (dispatch 2/10 click, 11 right-click).
	]"

class
	SW_CONTEXT_PANE_ASSAULT

inherit
	TEST_SET_BASE

feature {NONE} -- Fixture

	selections: INTEGER
			-- `on_select' calls heard.

	layout_changes: INTEGER
			-- `on_layout_change' calls heard.

	letter (a_row: TUPLE [name: STRING_32; n: INTEGER]): STRING_32
		do
			Result := a_row.name
		end

	number (a_row: TUPLE [name: STRING_32; n: INTEGER]): STRING_32
		do
			Result := a_row.n.out.to_string_32
		end

	run_item (a_menu: SW_MENU; a_label: READABLE_STRING_GENERAL)
			-- Run the item labelled `a_label', as a click on it would.
		local
			i: INTEGER
		do
			i := a_menu.index_of_label (a_label)
			assert_true ({STRING_32} "the menu offers " + a_label.to_string_32, i > 0)
			if i > 0 then
				assert_true ({STRING_32} "and it is live: " + a_label.to_string_32, a_menu.items.i_th (i).enabled)
				if attached a_menu.items.i_th (i).action as al_action then
					al_action.call
				end
			end
		end

	clipboard_text: STRING_32
		do
			Result := (create {SW_CLIPBOARD}).text
		end

	three_panel_dock (a_window: SW_WINDOW): SW_DOCK_HOST
			-- Explorer west, output south, properties east, in `a_window'.
		do
			create Result.make (create {SW_LABEL}.make_ui ("the document"))
			if Result.add_panel ("EXPLORER", create {SW_LABEL}.make_ui ("tree"), Result.Zone_west) > 0 then end
			if Result.add_panel ("OUTPUT", create {SW_LABEL}.make_ui ("log"), Result.Zone_south) > 0 then end
			if Result.add_panel ("PROPERTIES", create {SW_LABEL}.make_ui ("form"), Result.Zone_east) > 0 then end
			a_window.set_root (Result)
			a_window.request_render
		end

feature -- Menu extension

	test_extension_stands_above_the_own_items
			-- A label's own menu is Copy; a client's extension comes first,
			-- a separator between; an empty label with an extension offers
			-- only the extension, and with nothing to add, no menu at all.
		local
			l: SW_LABEL
		do
			create l.make_ui ("Galatians 2:20")
			if attached l.offered_menu (1.0, 1.0) as al_menu then
				assert_integers_equal ("alone, the label offers Copy", 1, al_menu.items.count)
				assert_strings_equal_diff ("Copy", {STRING_32} "Copy", al_menu.items.i_th (1).label)
			else
				assert_true ("a label with text offers a menu", False)
			end
			l.set_menu_extension (agent (a_menu: SW_MENU; a_px, a_py: REAL_64) do a_menu.add_item ("Go there", "", True, Void) end)
			if attached l.offered_menu (1.0, 1.0) as al_menu then
				assert_integers_equal ("extension, separator, Copy", 3, al_menu.items.count)
				assert_strings_equal_diff ("the client's item first", {STRING_32} "Go there", al_menu.items.i_th (1).label)
				assert_true ("then a separator", al_menu.items.i_th (2).separator)
				assert_strings_equal_diff ("then the label's own", {STRING_32} "Copy", al_menu.items.i_th (3).label)
			else
				assert_true ("an extended label offers a menu", False)
			end
			l.set_text ("")
			if attached l.offered_menu (1.0, 1.0) as al_menu then
				assert_integers_equal ("an empty label: the extension alone, no separator", 1, al_menu.items.count)
			else
				assert_true ("the extension still offers its item", False)
			end
			l.set_menu_extension (agent (a_menu: SW_MENU; a_px, a_py: REAL_64) do end)
			assert_true ("nothing to add and nothing of its own: no menu, the click goes on", l.offered_menu (1.0, 1.0) = Void)
		end

feature -- Grid

	test_grid_right_click_names_a_row_without_selecting_it
			-- Through the window: a right-click on the second row opens the
			-- grid's menu, notes that row and outlines it, but neither
			-- selects it nor fires `on_select'; Copy row and Copy all rows
			-- put tab-separated text on the clipboard; a later click on the
			-- same row still selects it.
		local
			w: SW_WINDOW
			g: SW_DATA_GRID [TUPLE [name: STRING_32; n: INTEGER]]
			l_rows: ARRAYED_LIST [TUPLE [name: STRING_32; n: INTEGER]]
			ry: INTEGER
		do
			create w.make ("grid", 0, 0, 500, 300, create {SW_THEME}.make_light)
			create g.make (260.0)
			g.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; n: INTEGER]]}.make ("Name", 150.0, agent letter))
			g.add_column (create {SW_GRID_COLUMN [TUPLE [name: STRING_32; n: INTEGER]]}.make ("Count", 80.0, agent number))
			create l_rows.make (3)
			l_rows.extend ([{STRING_32} "alpha", 1])
			l_rows.extend ([{STRING_32} "beta", 2])
			l_rows.extend ([{STRING_32} "gamma", 3])
			g.set_rows (l_rows)
			selections := 0
			g.set_on_select (agent (a_model: INTEGER) do selections := selections + 1 end)
			w.set_root (g)
			w.request_render
			ry := (g.y + g.Header_h + g.Row_h * 1.5).truncated_to_integer
			w.simulate_context_click ((g.x + 20.0).truncated_to_integer, ry)
			assert_integers_equal ("the right-click noted the second row", 2, g.context_model)
			assert_integers_equal ("in the first column", 1, g.context_column)
			assert_integers_equal ("but did not select it", 0, g.selected_model)
			assert_integers_equal ("nor fire on_select", 0, selections)
			if attached w.open_popup as al_menu then
				run_item (al_menu, "Copy row")
				assert_strings_equal_diff ("Copy row: the cells, a tab between", {STRING_32} "beta%T2", clipboard_text)
				run_item (al_menu, "Copy cell")
				assert_strings_equal_diff ("Copy cell: the cell under the pointer", {STRING_32} "beta", clipboard_text)
				run_item (al_menu, "Copy all rows")
				assert_strings_equal_diff ("Copy all rows: titles, then every row",
					{STRING_32} "Name%TCount%Nalpha%T1%Nbeta%T2%Ngamma%T3", clipboard_text)
			else
				assert_true ("the grid's menu is up", False)
			end
			w.dispatch (2, (g.x + 20.0).truncated_to_integer, ry)
			w.dispatch (10, (g.x + 20.0).truncated_to_integer, ry)
			w.dispatch (2, (g.x + 20.0).truncated_to_integer, ry)
			w.dispatch (10, (g.x + 20.0).truncated_to_integer, ry)
			assert_integers_equal ("a click on the same row selects it", 2, g.selected_model)
			assert_integers_equal ("and is heard", 1, selections)
			assert_integers_equal ("and clears the outline", 0, g.context_model)
		end

feature -- Tree, paragraphs, document

	test_tree_menu_expands_all_and_copies
		local
			t: SW_TREE [DEMO_NODE]
			root, a, b, a1: DEMO_NODE
			l_roots: ARRAYED_LIST [DEMO_NODE]
		do
			create root.make ("Bible")
			create a.make ("Old Testament")
			create b.make ("New Testament")
			create a1.make ("Genesis")
			a.children.extend (a1)
			root.children.extend (a)
			root.children.extend (b)
			create l_roots.make (1)
			l_roots.extend (root)
			create t.make (300.0)
			t.set_bounds (0.0, 0.0, 300.0, 300.0)
			t.set_label (agent (n: DEMO_NODE): STRING_32 do Result := n.label end)
			t.set_children (agent (n: DEMO_NODE): ARRAYED_LIST [DEMO_NODE] do Result := n.children end)
			t.set_roots (l_roots)
			assert_integers_equal ("only the root shows", 1, t.visible.count)
			if attached t.offered_menu (20.0, t.Row_h / 2.0) as al_menu then
				assert_true ("the root offers Expand", al_menu.index_of_label ("Expand") > 0)
				run_item (al_menu, "Copy")
				assert_strings_equal_diff ("Copy: the node's label", {STRING_32} "Bible", clipboard_text)
				run_item (al_menu, "Expand all")
				assert_integers_equal ("Expand all opens the whole tree", 4, t.visible.count)
			else
				assert_true ("a tree offers a menu", False)
			end
			if attached t.offered_menu (20.0, t.Row_h / 2.0) as al_menu then
				assert_true ("an open root offers Collapse", al_menu.index_of_label ("Collapse") > 0)
				run_item (al_menu, "Collapse all")
				assert_integers_equal ("Collapse all leaves the roots", 1, t.visible.count)
			end
		end

	test_paragraph_list_copies_the_paragraph_under_the_pointer
		local
			w: SW_WINDOW
			l: SW_PARAGRAPH_LIST
		do
			create w.make ("notes", 0, 0, 500, 300, create {SW_THEME}.make_light)
			create l.make (280.0)
			l.add ("The first note.")
			l.add ("The second note.")
			w.set_root (l)
			w.request_render
			if attached l.offered_menu (l.x + 40.0, l.item_top (2) + l.item_height (2) / 2.0) as al_menu then
				assert_integers_equal ("the second paragraph is noted", 2, l.context_item)
				run_item (al_menu, "Copy paragraph")
				assert_strings_equal_diff ("Copy paragraph", {STRING_32} "The second note.", clipboard_text)
				run_item (al_menu, "Copy all")
				assert_strings_equal_diff ("Copy all: a blank line between", {STRING_32} "The first note.%N%NThe second note.", clipboard_text)
			else
				assert_true ("a paragraph list offers a menu", False)
			end
		end

	test_document_view_offers_open_link_and_copy
			-- Over a link that a host follows: Open link first, which calls
			-- `on_link_click' with the target; Copy paragraph copies the
			-- text under the pointer; Select All then Copy copies it all.
		local
			w: SW_WINDOW
			v: SW_DOCUMENT_VIEW
			d: SIMPLE_DOCUMENT
			r: DOC_TEXT
			l_followed: STRING_32
			lx, ly: REAL_64
			u: INTEGER
		do
			create w.make ("doc", 0, 0, 600, 400, create {SW_THEME}.make_light)
			create d.make
			d.add_heading (1, "Commentary").do_nothing
			r := d.add_paragraph ("For God so loved the world; see John 3:16 and read on.")
			r.add_link (33, 9, "John 3:16")
			create v.make (380.0)
			v.set_document (d)
			create l_followed.make_empty
			v.set_on_link_click (agent (a_target: STRING_32; a_into: STRING_32) do a_into.copy (a_target) end (?, l_followed))
			w.set_root (v)
			w.request_render
			u := 2
			lx := v.unit_origin_x (u) + v.unit_geometry (u).x_of (35)
			ly := v.unit_origin_y (u) + v.unit_geometry (u).top_of_line (v.unit_geometry (u).line_of (35))
				+ v.unit_geometry (u).height_of_line (v.unit_geometry (u).line_of (35)) / 2.0
			if attached v.offered_menu (lx, ly) as al_menu then
				assert_strings_equal_diff ("over a link: Open link first", {STRING_32} "Open link", al_menu.items.i_th (1).label)
				run_item (al_menu, "Open link")
				assert_strings_equal_diff ("which follows it", {STRING_32} "John 3:16", l_followed)
				run_item (al_menu, "Copy paragraph")
				assert_strings_equal_diff ("Copy paragraph: the text under the pointer",
					{STRING_32} "For God so loved the world; see John 3:16 and read on.", clipboard_text)
				run_item (al_menu, "Copy all")
				assert_true ("Copy all: the heading and the paragraph", clipboard_text.starts_with ({STRING_32} "Commentary") and clipboard_text.has_substring ({STRING_32} "read on."))
			else
				assert_true ("a document view offers a menu", False)
			end
		end

feature -- Dock: fold

	test_zone_folds_to_a_strip_and_a_name_opens_it
			-- The west zone's fold button through the window: the zone stands
			-- as a strip, the centre takes the room, its edge no longer drags,
			-- its panel is sent off the surface, the snapshot remembers it;
			-- a click on the strip's name opens it again showing that panel.
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			z: SW_DOCK_ZONE
			r, c: TUPLE [rx, ry, rw, rh: REAL_64]
			b: TUPLE [kind, panel: INTEGER; bx, by, side: REAL_64]
			l_center_before: REAL_64
			l_snapshot: STRING_32
		do
			create w.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			dh := three_panel_dock (w)
			z := dh.zone_widget (dh.Zone_west)
			l_center_before := dh.center_rect.rw
			layout_changes := 0
			dh.set_on_layout_change (agent do layout_changes := layout_changes + 1 end)
			b := z.buttons.i_th (z.buttons.count)
			assert_integers_equal ("the zone's bar ends in the fold button", z.Button_collapse, b.kind)
			w.dispatch (2, (b.bx + b.side / 2.0).truncated_to_integer, (b.by + b.side / 2.0).truncated_to_integer)
			w.dispatch (10, (b.bx + b.side / 2.0).truncated_to_integer, (b.by + b.side / 2.0).truncated_to_integer)
			w.request_render
			assert_true ("the west is folded", dh.is_folded (dh.Zone_west))
			assert_integers_equal ("once announced", 1, layout_changes)
			r := dh.zone_rect (dh.Zone_west)
			assert_reals_equal ("it stands as a strip", dh.strip_extent (dh.Zone_west), r.rw, 0.000_1)
			c := dh.center_rect
			assert_true ("the centre took the room", c.rw > l_center_before + 100.0)
			assert_integers_equal ("a folded zone's edge does not drag", 0, dh.edge_at (r.rx + r.rw, r.ry + r.rh / 2.0))
			assert_reals_equal ("its panel is off the surface", 0.0, dh.panels [1].content.width, 0.000_1)
			assert_integers_equal ("the strip names its one panel", 1, z.strip_titles.count)
			l_snapshot := dh.layout_snapshot
			assert_true ("the snapshot remembers the fold", l_snapshot.has_substring ({STRING_32} "collapsed%Twest"))
			w.dispatch (2, (r.rx + r.rw / 2.0).truncated_to_integer, ((z.strip_titles.i_th (1).lo + z.strip_titles.i_th (1).hi) / 2.0).truncated_to_integer)
			w.dispatch (10, (r.rx + r.rw / 2.0).truncated_to_integer, ((z.strip_titles.i_th (1).lo + z.strip_titles.i_th (1).hi) / 2.0).truncated_to_integer)
			w.request_render
			assert_false ("a click on the name opens the zone", dh.is_collapsed (dh.Zone_west))
			assert_reals_equal ("at its fraction again", dh.width * dh.west_fraction, dh.zone_rect (dh.Zone_west).rw, 1.0)
			assert_true ("and its panel is back on the surface", dh.panels [1].content.width > 10.0)
			dh.restore_layout (l_snapshot)
			assert_true ("restoring the snapshot folds it again", dh.last_restore_ok and dh.is_collapsed (dh.Zone_west))
			dh.set_all_collapsed (True)
			assert_true ("folding everything focuses the centre", dh.is_focused_on_center)
			dh.set_all_collapsed (False)
			assert_false ("and opening everything ends it", dh.is_focused_on_center)
		end

feature -- Dock: maximize

	test_panel_maximizes_and_restores
			-- A maximizable panel's bar carries the maximize button; a click
			-- lets the panel take the whole host (the centre and the other
			-- zones step aside, their contents off the surface); the bar's
			-- restore button, or a double click on the bar, puts it back;
			-- hiding a maximized panel restores the layout.
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			z: SW_DOCK_ZONE
			b: TUPLE [kind, panel: INTEGER]
			i: INTEGER
			bx, by: INTEGER
		do
			create w.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			dh := three_panel_dock (w)
			dh.set_maximizable (3, True)
			w.request_render
			z := dh.zone_widget (dh.Zone_east)
			from i := 1 until i > z.buttons.count loop
				if z.buttons.i_th (i).kind = z.Button_maximize then
					bx := (z.buttons.i_th (i).bx + z.buttons.i_th (i).side / 2.0).truncated_to_integer
					by := (z.buttons.i_th (i).by + z.buttons.i_th (i).side / 2.0).truncated_to_integer
				end
				i := i + 1
			end
			assert_true ("the maximizable panel's bar has the button", bx > 0)
			b := z.button_at (bx, by)
			assert_integers_equal ("which acts on that panel", 3, b.panel)
			w.dispatch (2, bx, by)
			w.dispatch (10, bx, by)
			w.request_render
			assert_integers_equal ("a click maximizes it", 3, dh.maximized_panel)
			assert_reals_equal ("its zone takes the whole width", dh.width, dh.zone_rect (dh.Zone_east).rw, 0.000_1)
			assert_reals_equal ("the centre steps aside", 0.0, dh.center_rect.rw, 0.000_1)
			assert_reals_equal ("the west zone too", 0.0, dh.zone_rect (dh.Zone_west).rw, 0.000_1)
			assert_reals_equal ("its panel is off the surface", 0.0, dh.panels [1].content.width, 0.000_1)
			assert_reals_equal ("and the centre's content", 0.0, dh.center.width, 0.000_1)
			assert_true ("the panel fills the host under its bar", dh.panels [3].content.width > 800.0)
			assert_true ("the panel's content answers hit tests",
				dh.widget_at (dh.x + 200.0, dh.y + z.bar_h + 30.0) = dh.panels [3].content)
			b := z.button_at (z.buttons.i_th (1).bx + 2.0, z.buttons.i_th (1).by + 2.0)
			assert_integers_equal ("the solo bar's button restores", z.Button_restore, b.kind)
			w.dispatch (2, (z.buttons.i_th (1).bx + 4.0).truncated_to_integer, (z.buttons.i_th (1).by + 4.0).truncated_to_integer)
			w.dispatch (10, (z.buttons.i_th (1).bx + 4.0).truncated_to_integer, (z.buttons.i_th (1).by + 4.0).truncated_to_integer)
			w.request_render
			assert_integers_equal ("a click restores it", 0, dh.maximized_panel)
			assert_true ("the centre is back", dh.center_rect.rw > 200.0)
			assert_true ("a double click on the bar maximizes", z.handle_double_click (z.x + 20.0, z.y + 4.0) and dh.maximized_panel = 3)
			dh.hide_panel (3)
			assert_integers_equal ("hiding the maximized panel restores the layout", 0, dh.maximized_panel)
		end

	test_title_bar_menu_offers_maximize_fold_and_move
		local
			w: SW_WINDOW
			dh: SW_DOCK_HOST
			z: SW_DOCK_ZONE
		do
			create w.make ("dock", 0, 0, 900, 600, create {SW_THEME}.make_light)
			dh := three_panel_dock (w)
			dh.set_maximizable (1, True)
			w.request_render
			z := dh.zone_widget (dh.Zone_west)
			w.simulate_context_click ((z.x + 20.0).truncated_to_integer, (z.y + 4.0).truncated_to_integer)
			if attached w.open_popup as al_menu then
				assert_true ("Maximize explorer", al_menu.index_of_label ("Maximize explorer") > 0)
				assert_true ("Collapse the left side", al_menu.index_of_label ("Collapse the left side") > 0)
				assert_true ("Move to the right side", al_menu.index_of_label ("Move to the right side") > 0)
				assert_true ("Move to the bottom", al_menu.index_of_label ("Move to the bottom") > 0)
				assert_true ("not to where it is", al_menu.index_of_label ("Move to the left side") = 0)
				run_item (al_menu, "Collapse the left side")
				assert_true ("which folds it", dh.is_collapsed (dh.Zone_west))
			else
				assert_true ("a title bar offers a menu", False)
			end
			assert_true ("a right-click on a panel's ground offers no zone menu",
				z.context_menu (z.x + 20.0, z.y + z.height - 10.0) = Void or dh.is_folded (dh.Zone_west))
			dh.set_panel_marked (1, True)
			assert_true ("a panel can be marked", dh.is_panel_marked (1))
			dh.set_panel_marked (1, False)
			assert_false ("and unmarked", dh.is_panel_marked (1))
		end

end
