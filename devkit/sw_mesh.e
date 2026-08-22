note
	description: "[
		The widget graph as a living thing: one node per widget in
		the tree, springs on parent/child edges, charge repulsion
		between all pairs, a soft pull to centre - relaxing one step
		per frame on the heartbeat, the physics family of
		EiffelStudio's Diagram Tool. Drag a node to pin it; hover
		names it; DOUBLE-CLICK opens its SW_INSPECTOR reveal - the
		mesh and the lens, married. Lives in devkit: release builds
		never compile it.
	]"

class
	SW_MESH

inherit
	SW_WIDGET
		redefine
			handle_click, handle_double_click, handle_drag,
			wants_hover_point, context_menu,
			accepts_pebble, receive_pebble
		end

create
	make_over

feature {NONE} -- Initialization

	make_over (a_root: SW_WIDGET; a_max_depth: INTEGER)
			-- Graph the tree down to `a_max_depth' levels - a full
			-- face is hundreds of widgets (Larry counted 109 and
			-- called for mercy); the skeleton reads at three.
		require
			some_depth: a_max_depth >= 1
		do
			max_depth := a_max_depth
			create nodes.make (64)
			create edges.make (64)
			harvest (a_root, 0, 0)
		ensure
			populated: node_count >= 1
		end

feature -- Access

	nodes: ARRAYED_LIST [TUPLE [w: SW_WIDGET; px, py, vx, vy: REAL_64; pinned: BOOLEAN; depth: INTEGER; frontier: BOOLEAN]]

	edges: ARRAYED_LIST [TUPLE [a, b: INTEGER]]

	node_count: INTEGER
		do
			Result := nodes.count
		end

	selected_index: INTEGER

	show_labels: BOOLEAN
			-- Paint every node's class name beside it? (Larry's
			-- toggle - the hover chip names one; this names all.)

	select_widget (a_w: SW_WIDGET)
			-- Select the node carrying `a_w'; clears the selection
			-- when the widget is not in the graph.
		local
			i: INTEGER
		do
			selected_index := 0
			from
				i := 1
			until
				i > nodes.count or selected_index > 0
			loop
				if nodes.i_th (i).w = a_w then
					selected_index := i
				end
				i := i + 1
			end
		end

	toggle_labels
		do
			show_labels := not show_labels
		ensure
			flipped: show_labels = not old show_labels
		end

	on_select: detachable PROCEDURE [SW_WIDGET]
			-- Fired when a node is clicked - the studio's pane rides it.

	set_on_select (a_action: PROCEDURE [SW_WIDGET])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

	Rest_length: REAL_64 = 64.0

	max_depth: INTEGER

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 540.0
		end

	nearest_node (a_px, a_py: REAL_64): INTEGER
			-- The node within grabbing distance of a widget-space
			-- point; 0 when open space.
		local
			i: INTEGER
			d2, best: REAL_64
		do
			best := 260.0
			from
				i := 1
			until
				i > nodes.count
			loop
				d2 := (x + nodes.i_th (i).px - a_px) * (x + nodes.i_th (i).px - a_px)
					+ (y + nodes.i_th (i).py - a_py) * (y + nodes.i_th (i).py - a_py)
				if d2 < best then
					best := d2
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= node_count
		end

feature -- Physics

	relax_step
			-- One tick of the simulation: repulsion, springs,
			-- centre gravity, damping, bounds.
		local
			i, j: INTEGER
			dx, dy, d2, d, f: REAL_64
			m: DOUBLE_MATH
		do
			create m
			from
				i := 1
			until
				i > nodes.count
			loop
				from
					j := i + 1
				until
					j > nodes.count
				loop
					dx := nodes.i_th (j).px - nodes.i_th (i).px
					dy := nodes.i_th (j).py - nodes.i_th (i).py
					d2 := (dx * dx + dy * dy).max (25.0)
					f := 2200.0 / d2
					d := m.sqrt (d2)
					nodes.i_th (i).vx := nodes.i_th (i).vx - f * dx / d
					nodes.i_th (i).vy := nodes.i_th (i).vy - f * dy / d
					nodes.i_th (j).vx := nodes.i_th (j).vx + f * dx / d
					nodes.i_th (j).vy := nodes.i_th (j).vy + f * dy / d
					j := j + 1
				end
				i := i + 1
			end
			across
				edges as e
			loop
				dx := nodes.i_th (e.b).px - nodes.i_th (e.a).px
				dy := nodes.i_th (e.b).py - nodes.i_th (e.a).py
				d := m.sqrt ((dx * dx + dy * dy).max (1.0))
				f := (d - Rest_length) * 0.03
				nodes.i_th (e.a).vx := nodes.i_th (e.a).vx + f * dx / d
				nodes.i_th (e.a).vy := nodes.i_th (e.a).vy + f * dy / d
				nodes.i_th (e.b).vx := nodes.i_th (e.b).vx - f * dx / d
				nodes.i_th (e.b).vy := nodes.i_th (e.b).vy - f * dy / d
			end
			from
				i := 1
			until
				i > nodes.count
			loop
				if not nodes.i_th (i).pinned then
					nodes.i_th (i).vx := (nodes.i_th (i).vx
						+ (width / 2.0 - nodes.i_th (i).px) * 0.002) * 0.82
					nodes.i_th (i).vy := (nodes.i_th (i).vy
						+ (height / 2.0 - nodes.i_th (i).py) * 0.002) * 0.82
					nodes.i_th (i).px := (nodes.i_th (i).px + nodes.i_th (i).vx)
						.max (16.0).min (width - 16.0)
					nodes.i_th (i).py := (nodes.i_th (i).py + nodes.i_th (i).vy)
						.max (16.0).min (height - 16.0)
				end
				i := i + 1
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, hot: INTEGER
			nx, ny: REAL_64
			lbl: STRING_32
		do
			t := a_p.theme
			relax_step
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if shows_hover then
				hot := nearest_node (hover_px, hover_py)
			end
			a_p.set_color (t.outline)
			across
				edges as e
			loop
				a_p.line (x + nodes.i_th (e.a).px, y + nodes.i_th (e.a).py,
					x + nodes.i_th (e.b).px, y + nodes.i_th (e.b).py, 1.0)
			end
			from
				i := 1
			until
				i > nodes.count
			loop
				nx := x + nodes.i_th (i).px
				ny := y + nodes.i_th (i).py
				if nodes.i_th (i).depth = 0 then
						-- the origin wears the crown: accent, larger,
						-- double-ringed (Larry: make it unmistakable)
					a_p.set_color (t.accent)
					a_p.circle_fill (nx, ny, 11.0)
					a_p.set_color (t.surface)
					a_p.circle_stroke (nx, ny, 8.0)
				else
						-- fill encodes KIND: containers quiet, interactive
						-- controls accent-washed, passive leaves barely-there
					if not nodes.i_th (i).w.sub_widgets.is_empty then
						a_p.set_color (t.surface_variant)
					elseif nodes.i_th (i).w.accepts_focus then
						a_p.set_color (t.wash_accent)
					else
						a_p.set_color (t.outline)
					end
					a_p.circle_fill (nx, ny, 7.0)
				end
				if i = selected_index then
					a_p.set_color (t.accent)
				elseif i = hot then
					a_p.set_color (t.ink)
				elseif nodes.i_th (i).pinned then
					a_p.set_color (t.warning)
				elseif not nodes.i_th (i).w.is_enabled then
						-- ring encodes STATE: disabled burns danger
					a_p.set_color (t.danger)
				else
					a_p.set_color (t.outline)
				end
				a_p.circle_stroke (nx, ny, 7.5)
				if nodes.i_th (i).frontier then
						-- the plus badge: more beneath, click to grow
					a_p.set_color (t.accent)
					a_p.hline (nx - 3.0, ny, 6.0)
					a_p.line (nx, ny - 3.0, nx, ny + 3.0, 1.0)
				end
				i := i + 1
			end
			if show_labels then
					-- every node named: the map becomes a legend
				a_p.font ({SW_PAINTER}.Role_mono, 10.5, False)
				a_p.set_color (t.ink_muted)
				from
					i := 1
				until
					i > nodes.count
				loop
					a_p.text (x + nodes.i_th (i).px + 10.0,
						y + nodes.i_th (i).py + 3.5,
						nodes.i_th (i).w.generating_type.name_32)
					i := i + 1
				end
			end
			if hot > 0 or selected_index > 0 then
				i := hot.max (selected_index)
				if hot > 0 then
					i := hot
				else
					i := selected_index
				end
				lbl := nodes.i_th (i).w.generating_type.name_32
				a_p.font ({SW_PAINTER}.Role_mono, 12.0, True)
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + nodes.i_th (i).px + 10.0, y + nodes.i_th (i).py - 18.0,
					a_p.advance (lbl) + 10.0, 16.0, 3.0)
				a_p.set_color (t.ink)
				a_p.text (x + nodes.i_th (i).px + 15.0, y + nodes.i_th (i).py - 6.0, lbl)
			end
			a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, False)
			a_p.set_color (t.ink_muted)
			a_p.text (x + 10.0, y + height - 10.0,
				node_count.out + {STRING_32} " widgets to depth " + max_depth.out + {STRING_32} ", live physics %/8212/ drag pins a node; double-click reveals it")
				-- the names chip: click toggles all-node labels
			if show_labels then
				a_p.set_color (t.wash_accent)
			else
				a_p.set_color (t.surface_variant)
			end
			a_p.rrect_fill (x + width - 62.0, y + 8.0, 52.0, 20.0, 4.0)
			if show_labels then
				a_p.set_color (t.accent)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.font ({SW_PAINTER}.Role_ui, 12.0, False)
			a_p.text (x + width - 54.0, y + 22.0, {STRING_32} "names")
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if a_px >= x + width - 64.0 and a_px <= x + width - 8.0
					and a_py >= y + 6.0 and a_py <= y + 30.0
				then
						-- the names chip in the corner
					toggle_labels
				else
					selected_index := nearest_node (a_px, a_py)
					drag_index := selected_index
					if selected_index > 0 then
						if nodes.i_th (selected_index).frontier then
							expand_at (selected_index)
						end
						if attached on_select as s then
							s.call (nodes.i_th (selected_index).w)
						end
					end
				end
				Result := True
			end
		end

	handle_double_click (a_px, a_py: REAL_64): BOOLEAN
			-- Doubles behave as clicks here: the studio pane is the
			-- reveal (one overlay at a time - a popover would REPLACE
			-- the sheet we live in; the pane makes that moot).
		do
			Result := handle_click (a_px, a_py)
		end

	context_menu (a_px, a_py: REAL_64): detachable SW_MENU
			-- The node menu: reveal, expand, unpin - each acting on the
			-- node under the right-click. Open space offers nothing.
		local
			k: INTEGER
		do
			k := nearest_node (a_px, a_py)
			if k > 0 then
				menu_node := k
				create Result.make
				Result.add_item ("Reveal in pane", "", True, agent reveal_menu_node)
				Result.add_item ("Expand children", "", nodes.i_th (k).frontier, agent expand_menu_node)
				Result.add_item ("Release pin", "", nodes.i_th (k).pinned, agent unpin_menu_node)
				if show_labels then
					Result.add_item ("Hide all names", "", True, agent toggle_labels)
				else
					Result.add_item ("Show all names", "", True, agent toggle_labels)
				end
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if drag_index >= 1 and drag_index <= nodes.count then
				nodes.i_th (drag_index).px := (a_px - x).max (16.0).min (width - 16.0)
				nodes.i_th (drag_index).py := (a_py - y).max (16.0).min (height - 16.0)
				nodes.i_th (drag_index).vx := 0.0
				nodes.i_th (drag_index).vy := 0.0
				nodes.i_th (drag_index).pinned := True
			end
		end

feature -- Re-rooting

	accepts_pebble (a_pebble: ANY): BOOLEAN
			-- Widgets are welcome; anything else is not a graph.
		do
			Result := attached {SW_WIDGET} a_pebble
		end

	receive_pebble (a_pebble: ANY)
			-- A control dropped on the mesh becomes its new origin -
			-- dev-mode pick-and-drop closes Larry's cycle.
		do
			if attached {SW_WIDGET} a_pebble as w then
				re_root (w)
			end
		end

	re_root (a_root: SW_WIDGET)
			-- Rebuild the graph around a new origin and announce it,
			-- so the studio pane follows.
		do
			nodes.wipe_out
			edges.wipe_out
			selected_index := 0
			drag_index := 0
			menu_node := 0
			harvest (a_root, 0, 0)
			if attached on_select as s then
				s.call (a_root)
			end
		ensure
			populated: node_count >= 1
			crowned: nodes.i_th (1).w = a_root
		end

feature -- Disclosure

	expand_at (a_index: INTEGER)
			-- Harvest the hidden children of a frontier node, seeded
			-- around it - the graph grows where you ask.
		require
			in_range: a_index >= 1 and a_index <= node_count
		local
			base_x, base_y, ang: REAL_64
			m: DOUBLE_MATH
			k: INTEGER
		do
			if nodes.i_th (a_index).frontier then
				create m
				base_x := nodes.i_th (a_index).px
				base_y := nodes.i_th (a_index).py
				across
					nodes.i_th (a_index).w.sub_widgets as c
				loop
					k := k + 1
					ang := k * 2.399
					nodes.extend ([c,
						(base_x + 34.0 * m.cosine (ang)).max (16.0).min (width - 16.0),
						(base_y + 34.0 * m.sine (ang)).max (16.0).min (height - 16.0),
						0.0, 0.0, False,
						nodes.i_th (a_index).depth + 1,
						not c.sub_widgets.is_empty])
					edges.extend ([a_index, nodes.count])
				end
				nodes.i_th (a_index).frontier := False
			end
		ensure
			opened: not nodes.i_th (a_index).frontier
		end

feature {NONE} -- Engine

	menu_node: INTEGER
			-- The node the open context menu is about.

	reveal_menu_node
		do
			if menu_node >= 1 and menu_node <= nodes.count then
				selected_index := menu_node
				if attached on_select as s then
					s.call (nodes.i_th (menu_node).w)
				end
			end
		end

	expand_menu_node
		do
			if menu_node >= 1 and menu_node <= nodes.count then
				expand_at (menu_node)
			end
		end

	unpin_menu_node
		do
			if menu_node >= 1 and menu_node <= nodes.count then
				nodes.i_th (menu_node).pinned := False
			end
		end

	drag_index: INTEGER

	harvest (a_w: SW_WIDGET; a_depth, a_parent: INTEGER)
			-- Ring-seeded depth-first walk over sub_widgets.
		local
			my_index: INTEGER
			ring, ang: REAL_64
			m: DOUBLE_MATH
		do
			create m
			ring := 30.0 + a_depth * 52.0
			ang := nodes.count * 2.399
			nodes.extend ([a_w,
				330.0 + ring * m.cosine (ang),
				260.0 + ring * m.sine (ang),
				0.0, 0.0, False, a_depth,
				a_depth >= max_depth and not a_w.sub_widgets.is_empty])
			my_index := nodes.count
			if a_parent >= 1 then
				edges.extend ([a_parent, my_index])
			end
			if a_depth < max_depth then
				across
					a_w.sub_widgets as c
				loop
					harvest (c, a_depth + 1, my_index)
				end
			end
		end

invariant
	graph_attached: nodes /= Void and edges /= Void
	edges_bounded: across edges as e all
		e.a >= 1 and e.a <= nodes.count and e.b >= 1 and e.b <= nodes.count end

end
