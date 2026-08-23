note
	description: "[
		The hierarchy as boxes: a tidy LAYERED layout (each node
		centred over its children's span, leaves packed left to
		right - the classic org drawing, not force physics), elbow
		connectors parent to child, and click selection firing
		on_select with the node id. The layout (node_x by subtree
		width, depth_of rows) is deterministic public math,
		assaulted: a parent's centre equals its children's midspan.
	]"

class
	SW_ORG_CHART

inherit
	SW_CHART
		redefine
			draw, handle_click
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create labels.make (8)
			create parents.make (8)
		end

feature -- Access

	labels: ARRAYED_LIST [STRING_32]

	parents: ARRAYED_LIST [INTEGER]
			-- Per node: its parent id; 0 for the root(s).

	selected_index: INTEGER

	on_select: detachable PROCEDURE [INTEGER]

	Box_w: REAL_64 = 118.0

	Box_h: REAL_64 = 30.0

	Gap_x: REAL_64 = 12.0

	Gap_y: REAL_64 = 34.0

	node_count: INTEGER
		do
			Result := labels.count
		end

	depth_of (a_node: INTEGER): INTEGER
			-- Root depth 0; children one deeper.
		require
			known: a_node >= 1 and a_node <= node_count
		local
			cur: INTEGER
		do
			from
				cur := parents.i_th (a_node)
			until
				cur = 0
			loop
				Result := Result + 1
				cur := parents.i_th (cur)
			end
		ensure
			non_negative: Result >= 0
		end

	children_of (a_node: INTEGER): ARRAYED_LIST [INTEGER]
		require
			known: a_node >= 1 and a_node <= node_count
		local
			i: INTEGER
		do
			create Result.make (4)
			from
				i := 1
			until
				i > node_count
			loop
				if parents.i_th (i) = a_node then
					Result.extend (i)
				end
				i := i + 1
			end
		end

	subtree_width (a_node: INTEGER): REAL_64
			-- The horizontal room the subtree claims.
		require
			known: a_node >= 1 and a_node <= node_count
		local
			kids: ARRAYED_LIST [INTEGER]
			total: REAL_64
		do
			kids := children_of (a_node)
			if kids.is_empty then
				Result := Box_w + Gap_x
			else
				across
					kids as k
				loop
					total := total + subtree_width (k)
				end
				Result := total.max (Box_w + Gap_x)
			end
		ensure
			roomy: Result >= Box_w
		end

	node_x (a_node: INTEGER): REAL_64
			-- The box's LEFT edge: a parent centres over its
			-- children's span; leaves pack left to right.
		require
			known: a_node >= 1 and a_node <= node_count
		local
			kids: ARRAYED_LIST [INTEGER]
			first_c, last_c: REAL_64
		do
			kids := children_of (a_node)
			if kids.is_empty then
				Result := subtree_left (a_node) + (subtree_width (a_node) - Box_w) / 2.0
			else
				first_c := node_x (kids.first)
				last_c := node_x (kids.last)
				Result := (first_c + last_c) / 2.0
			end
		end

	node_y (a_node: INTEGER): REAL_64
		require
			known: a_node >= 1 and a_node <= node_count
		do
			Result := plot_y + depth_of (a_node) * (Box_h + Gap_y)
		end

feature -- Element change

	add_node (a_label: READABLE_STRING_GENERAL; a_parent: INTEGER): INTEGER
			-- 0 parent = a root.
		require
			parent_sane: a_parent >= 0 and a_parent <= node_count
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			labels.extend (l)
			parents.extend (a_parent)
			Result := labels.count
		ensure
			grew: node_count = old node_count + 1
		end

	set_on_select (a_action: PROCEDURE [INTEGER])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

feature -- Data

	refresh_domains
			-- Layered layout has no axes; the chassis scales idle.
		do
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			i: INTEGER
		do
			if is_enabled then
				from
					i := 1
				until
					i > node_count or Result
				loop
					if a_px >= node_x (i) and then a_px <= node_x (i) + Box_w
						and then a_py >= node_y (i) and then a_py <= node_y (i) + Box_h
					then
						selected_index := i
						if attached on_select as a then
							a.call (i)
						end
						Result := True
					end
					i := i + 1
				end
				Result := True
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, p: INTEGER
			bx, by, pcx, pby: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
				-- connectors beneath the boxes
			a_p.set_color (t.outline)
			from
				i := 1
			until
				i > node_count
			loop
				p := parents.i_th (i)
				if p > 0 then
					pcx := node_x (p) + Box_w / 2.0
					pby := node_y (p) + Box_h
					bx := node_x (i) + Box_w / 2.0
					by := node_y (i)
					a_p.line (pcx, pby, pcx, pby + Gap_y / 2.0, 1.2)
					a_p.line (pcx, pby + Gap_y / 2.0, bx, pby + Gap_y / 2.0, 1.2)
					a_p.line (bx, pby + Gap_y / 2.0, bx, by, 1.2)
				end
				i := i + 1
			end
			from
				i := 1
			until
				i > node_count
			loop
				bx := node_x (i)
				by := node_y (i)
				if i = selected_index then
					a_p.set_color (t.wash_accent)
				else
					a_p.set_color (t.surface_variant)
				end
				a_p.rrect_fill (bx, by, Box_w, Box_h, 4.0)
				if i = selected_index then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_stroke (bx + 0.5, by + 0.5, Box_w - 1.0, Box_h - 1.0, 4.0)
				a_p.font ({SW_PAINTER}.Role_ui, 11.5, i = selected_index)
				a_p.set_color (t.ink)
				a_p.text (bx + Box_w / 2.0 - a_p.advance (labels.i_th (i)) / 2.0,
					by + Box_h / 2.0 + 4.0, labels.i_th (i))
				i := i + 1
			end
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature {NONE} -- Layout engine

	subtree_left (a_node: INTEGER): REAL_64
			-- Where this node's subtree band begins: after every
			-- earlier sibling subtree, inside the parent's band.
		local
			p, i: INTEGER
			kids: ARRAYED_LIST [INTEGER]
			acc: REAL_64
		do
			p := parents.i_th (a_node)
			if p = 0 then
				acc := plot_x
				from
					i := 1
				until
					i >= a_node
				loop
					if parents.i_th (i) = 0 then
						acc := acc + subtree_width (i)
					end
					i := i + 1
				end
				Result := acc
			else
				acc := subtree_left (p)
				kids := children_of (p)
				from
					i := 1
				until
					i > kids.count or else kids.i_th (i) = a_node
				loop
					acc := acc + subtree_width (kids.i_th (i))
					i := i + 1
				end
				Result := acc
			end
		end

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	organs: labels /= Void and parents /= Void
	parallel: labels.count = parents.count
	parents_sane: across parents as p all p >= 0 and p <= labels.count end

end
