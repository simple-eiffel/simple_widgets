note
	description: "[
		Hierarchy over YOUR nodes: roots plus a children agent
		(called lazily, only on expansion) plus a label agent -
		the data-grid philosophy applied to trees. Expansion is
		tracked by object identity; the visible flattening draws
		virtualized like SW_LIST; selection follows the node
		object. Arrows navigate; left collapses, right expands.
	]"

class
	SW_TREE [G]

inherit
	SW_WIDGET
		redefine
			handle_click, handle_double_click, handle_wheel, handle_key,
			wants_hover_point, accepts_focus, handle_drag, handle_release,
			accessible_role, context_menu, pebble_at, pebble_card_at,
			accessible_item_count, publish_accessible_items,
			accepts_pebble_at, receive_pebble_at, responds_to_pick, pick_hover,
			pick_tick, pick_click, pick_ended, shows_style
		end

	SW_COPYING

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
		require
			positive: a_viewport_height > 0.0
		do
			viewport_height := a_viewport_height
			create roots.make (4)
			create open_nodes.make (16)
			create visible.make (32)
			create sprung.make (4)
			chip_w := 110.0
			create bar.make
		ensure
			kept: viewport_height = a_viewport_height
		end

feature -- Access

	roots: ARRAYED_LIST [G]

	children_provider: detachable FUNCTION [G, ARRAYED_LIST [G]]
			-- Supplies a node's children; called lazily, only when a
			-- node is expanded or probed for the disclosure triangle.

	label_provider: detachable FUNCTION [G, STRING_32]

	icon_provider: detachable FUNCTION [G, INTEGER]
			-- Each node's glyph ({SW_PAINTER}.Glyph_*; 0 for none), drawn before its label (0.50.0:
			-- folders and starred favorites). A star is drawn in the theme's gold.

	viewport_height: REAL_64

	Row_h: REAL_64 = 26.0

	Indent_w: REAL_64 = 20.0

	scroll_y: REAL_64

	bar: SW_VSCROLLBAR
			-- The scrollbar at the right edge.

	selected_node: detachable G
			-- Object-stable selection: survives expand and collapse.

	on_select: detachable PROCEDURE [G]

	on_activate: detachable PROCEDURE [G]
			-- Double-click on a LEAF (parents toggle instead).

	visible: ARRAYED_LIST [TUPLE [node: G; depth: INTEGER; has_kids: BOOLEAN]]
			-- The flattened rows currently showing.

	context_row: INTEGER
			-- The row of `visible' the last right-click fell on; 0 = none.
			-- Outlined, not selected (a right-click must not fire
			-- `on_select'); cleared by the next click and whenever the
			-- rows are rebuilt.

	context_node: detachable G
			-- The node the last right-click fell on; Void = none.
		do
			if context_row >= 1 and context_row <= visible.count then
				Result := visible.i_th (context_row).node
			end
		end

	label_of (a_node: G): STRING_32
			-- What the tree shows for `a_node'.
		do
			if attached label_provider as al_provider then
				Result := al_provider.item ([a_node])
			else
				create Result.make_empty
			end
		end

	has_children (a_node: G): BOOLEAN
			-- Does `a_node' have children to show?
		do
			Result := attached children_provider as al_provider and then attached al_provider.item ([a_node]) as al_kids
				and then not al_kids.is_empty
		end

	is_expanded (a_node: G): BOOLEAN
		do
			Result := open_nodes.has (a_node)
		end

feature -- Element change

	set_roots (a_roots: ARRAYED_LIST [G])
		do
			roots := a_roots
			rebuild_visible
		ensure
			kept: roots = a_roots
		end

	set_children (a_provider: FUNCTION [G, ARRAYED_LIST [G]])
		do
			children_provider := a_provider
			rebuild_visible
		ensure
			set: children_provider = a_provider
		end

	set_label (a_provider: FUNCTION [G, STRING_32])
		do
			label_provider := a_provider
		ensure
			set: label_provider = a_provider
		end

	set_icon (a_provider: FUNCTION [G, INTEGER])
			-- Nodes show the glyph `a_provider' names before their labels.
		do
			icon_provider := a_provider
		ensure
			set: icon_provider = a_provider
		end

	icon_of (a_node: G): INTEGER
			-- `a_node''s glyph (0: none).
		do
			if attached icon_provider as al_icon then
				Result := al_icon.item ([a_node])
			end
		ensure
			known: Result >= 0 and Result <= {SW_PAINTER}.Glyph_last
		end

	set_on_select (a_action: PROCEDURE [G])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

	set_on_activate (a_action: PROCEDURE [G])
		do
			on_activate := a_action
		ensure
			set: on_activate = a_action
		end

	on_expansion: detachable PROCEDURE [G, BOOLEAN]
			-- The user opened (True) or closed (False) a node: a click on its triangle, a double
			-- click, the arrow keys or the tree's own menu. The program's `expand_node' and
			-- `collapse_node' report nothing.

	set_on_expansion (a_action: PROCEDURE [G, BOOLEAN])
		do
			on_expansion := a_action
		ensure
			set: on_expansion = a_action
		end

	select_node_quietly (a_node: detachable G)
			-- Select `a_node' as the program, reporting nothing.
		do
			selected_node := a_node
		ensure
			selected: selected_node = a_node
		end

	expand_node (a_node: G)
		do
			if not open_nodes.has (a_node) then
				open_nodes.extend (a_node)
				rebuild_visible
			end
		ensure
			opened: is_expanded (a_node)
		end

	collapse_node (a_node: G)
		do
			open_nodes.prune_all (a_node)
			rebuild_visible
		ensure
			collapsed: not is_expanded (a_node)
		end

	toggle_node (a_node: G)
		do
			if open_nodes.has (a_node) then
				collapse_node (a_node)
			else
				expand_node (a_node)
			end
		end

	user_toggle (a_node: G)
			-- The user's toggle: reported through `on_expansion'.
		do
			toggle_node (a_node)
			if attached on_expansion as al_e then
				al_e.call (a_node, is_expanded (a_node))
			end
		end

	user_expand (a_node: G)
		do
			if not is_expanded (a_node) then
				user_toggle (a_node)
			end
		end

	user_collapse (a_node: G)
		do
			if is_expanded (a_node) then
				user_toggle (a_node)
			end
		end

	expand_all
			-- Every node with children open, all the way down (the
			-- provider must describe a finite tree).
		do
			across
				roots as al_root
			loop
				open_subtree (al_root)
			end
			rebuild_visible
		ensure
			roots_open: across roots as al_root all has_children (al_root) implies is_expanded (al_root) end
		end

	collapse_all
			-- Every node closed: only the roots show.
		do
			open_nodes.wipe_out
			rebuild_visible
		ensure
			only_roots: visible.count = roots.count
		end

	user_expand_all
			-- The user's Expand all: `expand_all', each node it opened reported
			-- through `on_expansion' (parents first).
		local
			l_before: ARRAYED_LIST [G]
		do
			l_before := open_nodes.twin
			expand_all
			if attached on_expansion as al_e then
				across open_nodes as al_n loop
					if not l_before.has (al_n) then
						al_e.call (al_n, True)
					end
				end
			end
		end

	user_collapse_all
			-- The user's Collapse all: `collapse_all', each node it closed
			-- reported through `on_expansion'.
		local
			l_before: ARRAYED_LIST [G]
		do
			l_before := open_nodes.twin
			collapse_all
			if attached on_expansion as al_e then
				across l_before as al_n loop
					al_e.call (al_n, False)
				end
			end
		end

	select_node (a_node: detachable G)
		do
			if a_node /= selected_node then
				selected_node := a_node
				if attached a_node as n and then attached on_select as s then
					s.call (n)
				end
			end
		ensure
			selected: selected_node = a_node
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	accepts_focus: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := viewport_height
		end

	row_at (a_py: REAL_64): INTEGER
			-- Visible row under widget-space y; 0 outside, and 0 on the
			-- New folder row a pick shows.
		local
			d: INTEGER
		do
			d := display_at (a_py)
			if d > 0 then
				Result := visible_index (d)
			end
		ensure
			in_range: Result >= 0 and Result <= visible.count
		end

	display_at (a_py: REAL_64): INTEGER
			-- Shown row under widget-space y (the New folder row counted);
			-- 0 outside (the sign guard: truncation rounds toward zero).
		do
			if a_py >= y then
				Result := (((a_py - y + scroll_y) / Row_h).truncated_to_integer + 1)
				if Result < 1 or Result > display_count then
					Result := 0
				end
			end
		ensure
			in_range: Result >= 0 and Result <= display_count
		end

	display_count: INTEGER
			-- Rows shown: the visible nodes, and the New folder row while a
			-- pick shows one.
		do
			Result := visible.count
			if new_row_at > 0 then
				Result := Result + 1
			end
		end

	visible_index (a_display: INTEGER): INTEGER
			-- The visible node row shown at `a_display'; 0 for the New
			-- folder row.
		require
			shown: a_display >= 1 and a_display <= display_count
		do
			if new_row_at > 0 and then a_display = new_row_at then
				Result := 0
			elseif new_row_at > 0 and then a_display > new_row_at then
				Result := a_display - 1
			else
				Result := a_display
			end
		ensure
			in_range: Result >= 0 and Result <= visible.count
		end

	max_scroll: REAL_64
		do
			Result := (display_count * Row_h - height).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

feature -- Drawing

	shows_style (a_part: INTEGER): BOOLEAN
			-- The fill of the selected rows and when the scroll bar shows. (The rows keep
			-- the theme's type: their heights are cut to it.)
		do
			Result := a_part = {SW_WIDGET_STYLE}.Part_selection
				or a_part = {SW_WIDGET_STYLE}.Part_scroll_bars
		end

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			first_v, last_v, i: INTEGER
			ry, ix: REAL_64
			row: TUPLE [node: G; depth: INTEGER; has_kids: BOOLEAN]
			lbl: STRING_32
			sel: BOOLEAN
			l_icon, k: INTEGER
		do
			t := a_p.theme
			bar.place (x, y, width, height, t)
			bar.set_extent (height, display_count * Row_h)
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.push_clip (x, y, width, height)
			if display_count > 0 then
				first_v := ((scroll_y / Row_h).truncated_to_integer + 1).max (1).min (display_count)
				last_v := (((scroll_y + height) / Row_h).truncated_to_integer + 1).min (display_count)
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				from
					i := first_v
				until
					i > last_v
				loop
					ry := y + ((i - 1) * Row_h - scroll_y)
					k := visible_index (i)
					if k = 0 then
						draw_new_folder_row (a_p, ry)
					else
					row := visible.i_th (k)
					sel := attached selected_node as sn and then sn = row.node
					if sel then
						a_p.set_color (styled_selection (t.wash_accent))
						a_p.fill_rect (x, ry, width, Row_h)
					elseif shows_hover and then hover_py >= ry and then hover_py < ry + Row_h then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x, ry, width, Row_h)
					end
					if k = context_row then
						a_p.set_color (t.accent)
						a_p.rrect_stroke (x + 1.5, ry + 0.5, width - 3.0, Row_h - 1.0, 2.0)
					end
					if k = drop_row and then new_row_at > 0 then
							-- 0.55.0: the folder a pick would land in, and its
							-- New folder button
						if not is_on_new_folder_row then
							a_p.set_color (t.accent)
							a_p.set_line_width (2.0)
							a_p.rrect_stroke (x + 2.0, ry + 1.0, width - 4.0, Row_h - 2.0, 3.0)
							a_p.set_line_width (1.0)
						end
						draw_new_folder_chip (a_p, ry)
					end
					ix := x + 8.0 + row.depth * Indent_w
					if row.has_kids then
						a_p.set_color (t.ink_muted)
						if is_expanded (row.node) then
							a_p.line (ix, ry + 10.0, ix + 4.0, ry + 16.0, 1.6)
							a_p.line (ix + 4.0, ry + 16.0, ix + 8.0, ry + 10.0, 1.6)
						else
							a_p.line (ix + 1.0, ry + 8.0, ix + 7.0, ry + 13.0, 1.6)
							a_p.line (ix + 7.0, ry + 13.0, ix + 1.0, ry + 18.0, 1.6)
						end
					end
					if attached label_provider as lp then
						lbl := lp.item ([row.node])
					else
						create lbl.make_empty
					end
					l_icon := icon_of (row.node)
					if l_icon > 0 then
						if l_icon = {SW_PAINTER}.Glyph_star then
							a_p.set_color (t.star)
						else
							a_p.set_color (t.ink_muted)
						end
						a_p.glyph (l_icon, ix + 21.0, ry + Row_h / 2.0, 13.0)
						a_p.set_color (t.ink)
						a_p.text (ix + 32.0, ry + Row_h - 8.0, lbl)
					else
						a_p.set_color (t.ink)
						a_p.text (ix + 14.0, ry + Row_h - 8.0, lbl)
					end
					end
					i := i + 1
				end
			end
			a_p.pop_clip
				-- scrollbar
			bar.set_mode (styled_scroll_bars)
			bar.draw (a_p, scroll_y, shows_hover and then bar.contains (hover_px, hover_py))
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
			row: TUPLE [node: G; depth: INTEGER; has_kids: BOOLEAN]
			ix: REAL_64
		do
			bar.set_extent (height, display_count * Row_h)
			if is_enabled and then bar.contains (a_px, a_py) then
				scroll_y := bar.press (a_py, scroll_y)
				Result := True
			elseif is_enabled then
				context_row := 0
				i := row_at (a_py)
				press_row := 0
				if i > 0 then
					row := visible.i_th (i)
					ix := x + 8.0 + row.depth * Indent_w
					if row.has_kids and then a_px >= ix - 4.0 and then a_px <= ix + 12.0 then
						user_toggle (row.node)
					else
						select_node (row.node)
						if row_offer /= Void then
								-- 0.55.0: the press may become a drag of the row
							press_row := i
							press_x := a_px
							press_y := a_py
						end
					end
				end
				Result := True
			end
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- Expand or Collapse the node under the pointer, Expand all,
			-- Collapse all, Copy its label. The node is noted
			-- (`context_node', outlined) for a client's `menu_extension'.
		local
			i: INTEGER
			l_node: detachable G
		do
			i := row_at (a_py)
			if i > 0 then
				l_node := visible.i_th (i).node
			end
			context_row := i
			create Result.make
			if attached l_node as al_node and then visible.i_th (i).has_kids then
				if is_expanded (al_node) then
					Result.add_item ("Collapse", "", True, agent user_collapse (al_node))
				else
					Result.add_item ("Expand", "", True, agent user_expand (al_node))
				end
			end
			Result.add_item ("Expand all", "", not roots.is_empty, agent user_expand_all)
			Result.add_item ("Collapse all", "", not open_nodes.is_empty, agent user_collapse_all)
			Result.add_separator
			if attached l_node as al_node then
				Result.add_item ("Copy", "", True, agent copy_text (label_of (al_node)))
			else
				Result.add_item ("Copy", "", False, Void)
			end
		ensure then
			offered: Result /= Void
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
			row: TUPLE [node: G; depth: INTEGER; has_kids: BOOLEAN]
		do
			if is_enabled then
				i := row_at (a_py)
				if i > 0 then
					row := visible.i_th (i)
					select_node (row.node)
					if row.has_kids then
						user_toggle (row.node)
					elseif attached on_activate as act then
						act.call (row.node)
					end
				end
				Result := True
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			bar.set_extent (height, display_count * Row_h)
			scroll_y := bar.wheel_scroll (scroll_y, a_delta, Row_h)
			Result := True
		end

	handle_drag (a_px, a_py: REAL_64)
			-- Drag the thumb, wherever the pointer is; a press on a row
			-- moved past `Drag_distance' carries the row (0.55.0).
		do
			if bar.is_dragging then
				scroll_y := bar.drag_to (a_py)
			elseif press_row > 0 and then press_row <= visible.count
				and then ((a_px - press_x).abs > Drag_distance or else (a_py - press_y).abs > Drag_distance)
			then
				if attached row_offer as al_offer and then attached al_offer.item ([visible.i_th (press_row).node]) as al_o then
					request_pick (al_o.pebble, al_o.card)
				end
				press_row := 0
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go of the scrollbar thumb, or of a row.
		do
			bar.release
			press_row := 0
		ensure then
			released: not bar.is_dragging
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
			-- Down and Up move the selection; the arrow that points into the
			-- reading direction opens a node and the other closes it (Right
			-- and Left, swapped when the tree is mirrored, as GTK and AppKit do).
		local
			pos, l_vk: INTEGER
		do
			pos := selected_position
			l_vk := a_vk
			if mirrors_layout then
				if l_vk = 37 then
					l_vk := 39
				elseif l_vk = 39 then
					l_vk := 37
				end
			end
			inspect l_vk
			when 40 then
				if pos > 0 and pos < visible.count then
					select_node (visible.i_th (pos + 1).node)
				elseif pos = 0 and visible.count > 0 then
					select_node (visible.i_th (1).node)
				end
			when 38 then
				if pos > 1 then
					select_node (visible.i_th (pos - 1).node)
				end
			when 39 then
				if pos > 0 and then visible.i_th (pos).has_kids then
					user_expand (visible.i_th (pos).node)
				end
			when 37 then
				if pos > 0 and then visible.i_th (pos).has_kids
					and then is_expanded (visible.i_th (pos).node)
				then
					user_collapse (visible.i_th (pos).node)
				end
			else
			end
			scroll_selection_into_view
		end

feature {NONE} -- Engine

	open_nodes: ARRAYED_LIST [G]
			-- Reference-identity expansion set.

	selected_position: INTEGER
		local
			i: INTEGER
		do
			if attached selected_node as sn then
				from
					i := 1
				until
					i > visible.count or Result > 0
				loop
					if visible.i_th (i).node = sn then
						Result := i
					end
					i := i + 1
				end
			end
		end

	scroll_selection_into_view
		local
			pos: INTEGER
		do
			pos := selected_position
			if pos > 0 then
				if (pos - 1) * Row_h < scroll_y then
					scroll_y := (pos - 1) * Row_h
				elseif pos * Row_h > scroll_y + height then
					scroll_y := (pos * Row_h - height).max (0.0)
				end
			end
		end

	rebuild_visible
		do
			context_row := 0
			visible.wipe_out
			across
				roots as r
			loop
				append_subtree (r, 0)
			end
			scroll_y := scroll_y.min (max_scroll)
			bar.set_extent (height, display_count * Row_h)
		end

	open_subtree (a_node: G)
			-- `a_node' and every node below it with children, opened.
		do
			if attached children_provider as al_provider and then attached al_provider.item ([a_node]) as al_kids
				and then not al_kids.is_empty
			then
				if not open_nodes.has (a_node) then
					open_nodes.extend (a_node)
				end
				across
					al_kids as al_kid
				loop
					open_subtree (al_kid)
				end
			end
		end

	append_subtree (a_node: G; a_depth: INTEGER)
		local
			kids: detachable ARRAYED_LIST [G]
			has_kids: BOOLEAN
		do
			if attached children_provider as cp then
				kids := cp.item ([a_node])
				has_kids := attached kids as k and then not k.is_empty
			end
			visible.extend ([a_node, a_depth, has_kids])
			if has_kids and then open_nodes.has (a_node) and then attached kids as k2 then
				across
					k2 as c
				loop
					append_subtree (c, a_depth + 1)
				end
			end
		end


feature -- Carrying and dropping (0.55.0)

	drop_welcome: detachable FUNCTION [ANY, detachable G, BOOLEAN]
			-- Would the tree take this pebble into this folder (Void: the
			-- top level)? Void: every pebble is welcome where `drop_action'
			-- is set.

	drop_action: detachable PROCEDURE [ANY, detachable G, BOOLEAN]
			-- Take the pebble into the folder (Void: the top level); True:
			-- into a new folder made inside it (the New folder row). Void:
			-- the tree takes no drops.

	folder_test: detachable PREDICATE [G]
			-- Is the node a folder (it takes drops, springs open and gets a
			-- New folder row)? Void: a node with children is.

	row_offer: detachable FUNCTION [G, detachable TUPLE [pebble: ANY; card: STRING_32]]
			-- What a row carries when dragged or middle-clicked; Void, or an
			-- answer of Void, when it stays put.

	set_drop_handler (a_welcome: like drop_welcome; a_action: like drop_action)
		do
			drop_welcome := a_welcome
			drop_action := a_action
		ensure
			set: drop_welcome = a_welcome and drop_action = a_action
		end

	set_folder_test (a_test: like folder_test)
		do
			folder_test := a_test
		ensure
			set: folder_test = a_test
		end

	set_row_offer (a_offer: like row_offer)
		do
			row_offer := a_offer
		ensure
			set: row_offer = a_offer
		end

	is_folder (a_node: G): BOOLEAN
		do
			if attached folder_test as al_test then
				Result := al_test.item ([a_node])
			else
				Result := has_children (a_node)
			end
		end

	Spring_ticks: INTEGER = 3
			-- Heartbeats (250 ms each) a closed folder must be hovered by a
			-- pick before it springs open: about 0.7 seconds.

	New_folder_label: STRING_32 = "New folder"

	drop_folder: detachable G
			-- The folder a pick in flight would land in (Void: the top
			-- level, or no pick over the tree).

	drop_row: INTEGER
			-- The visible row of `drop_folder'; 0 for the top level or none.

	is_on_new_folder_row: BOOLEAN
			-- Is a pick over a New folder target: the lit folder's "New
			-- folder" button, or the New folder row at the end of the tree?

	new_row_at: INTEGER
			-- The shown row the top level's New folder row takes during a
			-- pick (always the last, so no row moves under the pointer);
			-- 0 = none. Worked out from the rows there are now: a drop that
			-- takes rows away cannot leave it standing past them.
		do
			if shows_new_row then
				Result := visible.count + 1
			end
		ensure
			last_or_none: Result = 0 or Result = visible.count + 1
		end

	shows_new_row: BOOLEAN
			-- Does a pick over the tree show the New folder row?

	new_row_depth: INTEGER
			-- Its indent (the top level: 0).

	new_folder_chip_left: REAL_64
			-- Where the lit folder row's "New folder" button begins (window
			-- space). A row that moved to the end of whichever folder the
			-- pointer was in made every row below it jump as the pointer
			-- crossed into the next folder (2026-11-03); the button stays on
			-- the folder's own row.
		do
			Result := x + width - chip_w - 16.0
		end

	sprung: ARRAYED_LIST [G]
			-- Folders the pick in flight sprang open.

	responds_to_pick (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- A tree that takes drops acts anywhere inside it: it lights
			-- rows, springs folders and scrolls at its edges.
		do
			Result := drop_action /= Void and then is_enabled and then contains (a_px, a_py)
		end

	accepts_pebble_at (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- A client's composition hooks (simple_gui) answer when set; else the folder drop.
		do
			if accepts_hook /= Void then
				Result := Precursor (a_pebble, a_px, a_py)
			elseif drop_action /= Void and then contains (a_px, a_py) then
				if attached drop_welcome as al_welcome then
					Result := al_welcome.item ([a_pebble, drop_spot_at (a_px, a_py).folder])
				else
					Result := True
				end
			end
		end

	receive_pebble_at (a_pebble: ANY; a_px, a_py: REAL_64)
			-- Into the folder under the point, or a new folder there.
		local
			l_spot: like drop_spot_at
		do
			if receive_hook /= Void then
				Precursor (a_pebble, a_px, a_py)
			else
				l_spot := drop_spot_at (a_px, a_py)
				landed := l_spot.folder
				if attached drop_action as al_action then
					al_action.call ([a_pebble, l_spot.folder, l_spot.new_folder])
				end
			end
		end

	pick_hover (a_pebble: ANY; a_px, a_py: REAL_64)
			-- Light the folder the pebble would land in, and stand the New
			-- folder row at its end.
		local
			l_spot: like drop_spot_at
			d, k: INTEGER
		do
			pick_px := a_px
			pick_py := a_py
				-- the New folder row first: the spot is read on the rows as shown
			shows_new_row := True
			new_row_depth := 0
			l_spot := drop_spot_at (a_px, a_py)
			drop_folder := l_spot.folder
			drop_row := l_spot.row
			is_on_new_folder_row := l_spot.new_folder
			d := display_at (a_py)
			if d > 0 then
				k := visible_index (d)
			end
			if k /= spring_row then
				spring_row := k
				spring_count := 0
			end
		end

	pick_tick (a_pebble: ANY): BOOLEAN
			-- Spring the hovered closed folder open after `Spring_ticks';
			-- scroll a row near the top or bottom edge.
		local
			l_node: G
		do
			if pick_py < y + Row_h * 0.75 and then scroll_y > 0.0 then
				scroll_y := (scroll_y - Row_h).max (0.0)
				Result := True
			elseif pick_py > y + height - Row_h * 0.75 and then scroll_y < max_scroll then
				scroll_y := (scroll_y + Row_h).min (max_scroll)
				Result := True
			end
			if spring_row > 0 and then spring_row <= visible.count then
				l_node := visible.i_th (spring_row).node
				if visible.i_th (spring_row).has_kids and then not is_expanded (l_node) and then is_folder (l_node) then
					spring_count := spring_count + 1
					if spring_count >= Spring_ticks then
						expand_node (l_node)
						sprung.extend (l_node)
						spring_count := 0
						Result := True
					end
				end
			end
			if Result then
				pick_hover (a_pebble, pick_px, pick_py)
			end
		end

	pick_click (a_pebble: ANY; a_px, a_py: REAL_64): BOOLEAN
			-- A press on a folder's arrow opens or closes it; the pebble
			-- stays in flight.
		local
			k: INTEGER
			ix: REAL_64
		do
			shows_new_row := True
			k := row_at (a_py)
			if k > 0 and then visible.i_th (k).has_kids then
				ix := x + 8.0 + visible.i_th (k).depth * Indent_w
				if a_px >= ix - 4.0 and then a_px <= ix + 12.0 then
					toggle_node (visible.i_th (k).node)
					pick_hover (a_pebble, a_px, a_py)
					Result := True
				end
			end
		end

	pick_ended
			-- Folders the pick sprang open close again, except the path to
			-- where it landed.
		local
			l_keep: ARRAYED_LIST [G]
			k: INTEGER
			l_none: detachable G
		do
			create l_keep.make (4)
			if attached landed as al_landed then
				from
					k := visible_row_of (al_landed)
				until
					k = 0
				loop
					l_keep.extend (visible.i_th (k).node)
					k := parent_row (k)
				end
			end
			across sprung as ic loop
				if not l_keep.has (ic) then
					open_nodes.prune_all (ic)
				end
			end
			sprung.wipe_out
			landed := l_none
			drop_folder := l_none
			drop_row := 0
			is_on_new_folder_row := False
			shows_new_row := False
			spring_row := 0
			spring_count := 0
			rebuild_visible
		ensure then
			none_sprung: sprung.is_empty
			no_new_row: new_row_at = 0
		end

	pebble_at (a_px, a_py: REAL_64): detachable ANY
			-- The row's offer under the point, else the tree's own.
		local
			k: INTEGER
		do
			k := row_at (a_py)
			if k > 0 and then attached row_offer as al_offer and then attached al_offer.item ([visible.i_th (k).node]) as al_o then
				Result := al_o.pebble
			else
				Result := Precursor (a_px, a_py)
			end
		end

	pebble_card_at (a_px, a_py: REAL_64): STRING_32
		local
			k: INTEGER
		do
			k := row_at (a_py)
			if k > 0 and then attached row_offer as al_offer and then attached al_offer.item ([visible.i_th (k).node]) as al_o then
				Result := al_o.card
			else
				Result := Precursor (a_px, a_py)
			end
		end

feature {NONE} -- Carrying internals

	landed: detachable G
			-- The folder the last drop went into, until the pick ends.

	pick_px, pick_py: REAL_64
			-- Where the pick in flight last passed over the tree.

	spring_row, spring_count: INTEGER
			-- The visible row the pick rests on, and for how many beats.

	press_row: INTEGER
	press_x, press_y: REAL_64
			-- The row a press fell on, while it may yet become a drag.

	drop_spot_at (a_px, a_py: REAL_64): TUPLE [folder: detachable G; new_folder: BOOLEAN; row: INTEGER]
			-- Where a pebble at the point lands: a folder row is its own
			-- folder (its "New folder" button, a new folder inside it); any
			-- other row, the folder it is in; the New folder row at the end,
			-- a new folder at the top level; below the rows, the top level.
		local
			d, k, p: INTEGER
			l_none: detachable G
		do
			Result := [l_none, False, 0]
			d := display_at (a_py)
			if d > 0 then
				k := visible_index (d)
				if k = 0 then
					Result := [l_none, True, 0]
				elseif is_folder (visible.i_th (k).node) then
					Result := [visible.i_th (k).node, a_px >= new_folder_chip_left, k]
				else
					p := parent_row (k)
					if p > 0 then
						Result := [visible.i_th (p).node, False, p]
					end
				end
			end
		end

	chip_w: REAL_64
			-- The "New folder" button's width, measured when drawn.

	parent_row (a_row: INTEGER): INTEGER
			-- The visible row of the folder holding the row; 0 = the top level.
		require
			valid: a_row >= 1 and a_row <= visible.count
		local
			j: INTEGER
		do
			from
				j := a_row - 1
			until
				j < 1 or Result > 0
			loop
				if visible.i_th (j).depth < visible.i_th (a_row).depth then
					Result := j
				end
				j := j - 1
			end
		ensure
			above: Result >= 0 and Result < a_row
		end

	visible_row_of (a_node: G): INTEGER
			-- The visible row showing `a_node'; 0 = not shown.
		local
			j: INTEGER
		do
			from
				j := 1
			until
				j > visible.count or Result > 0
			loop
				if visible.i_th (j).node = a_node then
					Result := j
				end
				j := j + 1
			end
		end

	draw_new_folder_chip (a_p: SW_PAINTER; a_ry: REAL_64)
			-- The lit folder row's "New folder" button at its right end,
			-- filled when the pick is over it.
		local
			cx: REAL_64
		do
			chip_w := a_p.advance (New_folder_label) + 30.0
			cx := new_folder_chip_left
			if is_on_new_folder_row then
				a_p.set_color (a_p.theme.wash_accent)
				a_p.rrect_fill (cx, a_ry + 3.0, chip_w, Row_h - 6.0, 4.0)
			end
			a_p.set_color (a_p.theme.accent)
			a_p.rrect_stroke (cx + 0.5, a_ry + 3.5, chip_w - 1.0, Row_h - 7.0, 4.0)
			a_p.line (cx + 7.0, a_ry + Row_h / 2.0, cx + 15.0, a_ry + Row_h / 2.0, 1.6)
			a_p.line (cx + 11.0, a_ry + Row_h / 2.0 - 4.0, cx + 11.0, a_ry + Row_h / 2.0 + 4.0, 1.6)
			a_p.set_color (a_p.theme.ink)
			a_p.text (cx + 20.0, a_ry + Row_h - 8.0, New_folder_label)
		end

	draw_new_folder_row (a_p: SW_PAINTER; a_ry: REAL_64)
			-- The New folder row: a plus and the words, washed when a pick
			-- is over it.
		local
			ix: REAL_64
		do
			ix := x + 8.0 + new_row_depth * Indent_w
			if is_on_new_folder_row then
				a_p.set_color (a_p.theme.wash_accent)
				a_p.fill_rect (x, a_ry, width, Row_h)
			end
			a_p.set_color (a_p.theme.accent)
			a_p.line (ix + 1.0, a_ry + Row_h / 2.0, ix + 9.0, a_ry + Row_h / 2.0, 1.6)
			a_p.line (ix + 5.0, a_ry + Row_h / 2.0 - 4.0, ix + 5.0, a_ry + Row_h / 2.0 + 4.0, 1.6)
			a_p.set_color (a_p.theme.ink_muted)
			a_p.text (ix + 14.0, a_ry + Row_h - 8.0, New_folder_label)
		end

feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_tree
		end

	accessible_item_count: INTEGER
			-- The shown nodes, published as tree items.
		do
			Result := visible.count.min (2_047)
		end

	publish_accessible_items (a_accessibility: SW_ACCESSIBILITY)
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > accessible_item_count
			loop
				a_accessibility.add_node (accessible_item_id (i), accessible_node_id, {SW_ACCESSIBILITY}.Role_tree_item,
					label_of (visible.i_th (i).node), Void, x, y + (i - 1) * Row_h - scroll_y, width, Row_h, False, is_enabled)
				i := i + 1
			end
		end

invariant
	lists_attached: roots /= Void and open_nodes /= Void and visible /= Void
	scroll_non_negative: scroll_y >= 0.0

end
