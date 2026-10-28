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
			accessible_role, context_menu
		end

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
			-- Visible row under widget-space y; 0 outside (the sign
			-- guard: truncation rounds toward zero).
		do
			if a_py >= y then
				Result := (((a_py - y + scroll_y) / Row_h).truncated_to_integer + 1)
				if Result < 1 or Result > visible.count then
					Result := 0
				end
			end
		ensure
			in_range: Result >= 0 and Result <= visible.count
		end

	max_scroll: REAL_64
		do
			Result := (visible.count * Row_h - height).max (0.0)
		ensure
			non_negative: Result >= 0.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			first_v, last_v, i: INTEGER
			ry, ix: REAL_64
			row: TUPLE [node: G; depth: INTEGER; has_kids: BOOLEAN]
			lbl: STRING_32
			sel: BOOLEAN
		do
			t := a_p.theme
			bar.place (x, y, width, height, t)
			bar.set_extent (height, visible.count * Row_h)
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			a_p.push_clip (x, y, width, height)
			if visible.count > 0 then
				first_v := ((scroll_y / Row_h).truncated_to_integer + 1).max (1).min (visible.count)
				last_v := (((scroll_y + height) / Row_h).truncated_to_integer + 1).min (visible.count)
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
				from
					i := first_v
				until
					i > last_v
				loop
					row := visible.i_th (i)
					ry := y + ((i - 1) * Row_h - scroll_y)
					sel := attached selected_node as sn and then sn = row.node
					if sel then
						a_p.set_color (t.wash_accent)
						a_p.fill_rect (x, ry, width, Row_h)
					elseif shows_hover and then hover_py >= ry and then hover_py < ry + Row_h then
						a_p.set_color (t.surface_variant)
						a_p.fill_rect (x, ry, width, Row_h)
					end
					if i = context_row then
						a_p.set_color (t.accent)
						a_p.rrect_stroke (x + 1.5, ry + 0.5, width - 3.0, Row_h - 1.0, 2.0)
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
					if sel or not row.has_kids then
						a_p.set_color (t.ink)
					else
						a_p.set_color (t.ink)
					end
					a_p.text (ix + 14.0, ry + Row_h - 8.0, lbl)
					i := i + 1
				end
			end
			a_p.pop_clip
				-- scrollbar
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
			bar.set_extent (height, visible.count * Row_h)
			if is_enabled and then bar.contains (a_px, a_py) then
				scroll_y := bar.press (a_py, scroll_y)
				Result := True
			elseif is_enabled then
				context_row := 0
				i := row_at (a_py)
				if i > 0 then
					row := visible.i_th (i)
					ix := x + 8.0 + row.depth * Indent_w
					if row.has_kids and then a_px >= ix - 4.0 and then a_px <= ix + 12.0 then
						toggle_node (row.node)
					else
						select_node (row.node)
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
					Result.add_item ("Collapse", "", True, agent collapse_node (al_node))
				else
					Result.add_item ("Expand", "", True, agent expand_node (al_node))
				end
			end
			Result.add_item ("Expand all", "", not roots.is_empty, agent expand_all)
			Result.add_item ("Collapse all", "", not open_nodes.is_empty, agent collapse_all)
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
						toggle_node (row.node)
					elseif attached on_activate as act then
						act.call (row.node)
					end
				end
				Result := True
			end
		end

	handle_wheel (a_delta: INTEGER): BOOLEAN
		do
			bar.set_extent (height, visible.count * Row_h)
			scroll_y := bar.wheel_scroll (scroll_y, a_delta, Row_h)
			Result := True
		end

	handle_drag (a_px, a_py: REAL_64)
			-- Drag the thumb, wherever the pointer is.
		do
			if bar.is_dragging then
				scroll_y := bar.drag_to (a_py)
			end
		end

	handle_release (a_x, a_y: INTEGER)
			-- Let go of the scrollbar thumb.
		do
			bar.release
		ensure then
			released: not bar.is_dragging
		end

	handle_key (a_vk: INTEGER; a_shift: BOOLEAN)
		local
			pos: INTEGER
		do
			pos := selected_position
			inspect a_vk
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
					expand_node (visible.i_th (pos).node)
				end
			when 37 then
				if pos > 0 and then visible.i_th (pos).has_kids
					and then is_expanded (visible.i_th (pos).node)
				then
					collapse_node (visible.i_th (pos).node)
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
			bar.set_extent (height, visible.count * Row_h)
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

	copy_text (a_text: READABLE_STRING_GENERAL)
			-- `a_text' onto the system clipboard.
		local
			l_clip: SW_CLIPBOARD
		do
			create l_clip
			l_clip.set_text (a_text)
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


feature -- Accessibility (GW-14)

	accessible_role: INTEGER
		do
			Result := {SW_ACCESSIBILITY}.Role_tree
		end

invariant
	lists_attached: roots /= Void and open_nodes /= Void and visible /= Void
	scroll_non_negative: scroll_y >= 0.0

end
