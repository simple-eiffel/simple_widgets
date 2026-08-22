note
	description: "[
		Nodes and edges as living structure: the force physics the
		dev mesh proved (all-pairs repulsion, edge springs, centre
		gravity, one relax per heartbeat - EiffelStudio Diagram Tool
		family) graduated into a PUBLIC generic widget. Nodes carry
		labels and ring-seed deterministically (the golden-angle
		walk); connect refuses unknown ids and self-loops by
		contract; dragging pins a node (warning ring); clicking
		selects and fires on_select with the node id. Names draw
		beside every node - a diagram that will not say what its
		nodes are is furniture. The layout math (nearest_node,
		relax_step, bounds clamping, pinning) is public and
		assaulted headless. The roadmap's note comes true in
		reverse: this feeds the inspector's mesh its next chassis.
	]"

class
	SW_DIAGRAM

inherit
	SW_CHART
		redefine
			draw, handle_click, handle_drag, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create nodes.make (16)
			create edges.make (16)
		end

feature -- Access

	nodes: ARRAYED_LIST [TUPLE [label: STRING_32; px, py, vx, vy: REAL_64; pinned: BOOLEAN]]

	edges: ARRAYED_LIST [TUPLE [a, b: INTEGER]]

	node_count: INTEGER
		do
			Result := nodes.count
		end

	selected_index: INTEGER

	on_select: detachable PROCEDURE [INTEGER]
			-- Fired with the node id when one is clicked.

	Rest_length: REAL_64 = 74.0

	nearest_node (a_px, a_py: REAL_64): INTEGER
			-- The node within grabbing distance of a surface point;
			-- 0 when open space.
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

feature -- Element change

	add_node (a_label: READABLE_STRING_GENERAL): INTEGER
			-- Register a node; its id for connecting. Ring-seeded by
			-- the golden-angle walk, deterministic and repeatable.
		local
			l: STRING_32
			m: DOUBLE_MATH
			ring, ang: REAL_64
		do
			create l.make_from_string_general (a_label)
			create m
			ring := 40.0 + nodes.count * 9.0
			ang := nodes.count * 2.399
			nodes.extend ([l,
				160.0 + ring * m.cosine (ang),
				120.0 + ring * m.sine (ang),
				0.0, 0.0, False])
			Result := nodes.count
		ensure
			grew: nodes.count = old nodes.count + 1
			id_is_last: Result = nodes.count
		end

	connect (a_from, a_to: INTEGER)
		require
			from_known: a_from >= 1 and a_from <= nodes.count
			to_known: a_to >= 1 and a_to <= nodes.count
			no_self_loop: a_from /= a_to
		do
			edges.extend ([a_from, a_to])
		ensure
			grew: edges.count = old edges.count + 1
		end

	set_on_select (a_action: PROCEDURE [INTEGER])
		do
			on_select := a_action
		ensure
			set: on_select = a_action
		end

	pin (a_node: INTEGER)
		require
			known: a_node >= 1 and a_node <= nodes.count
		do
			nodes.i_th (a_node).pinned := True
		ensure
			held: nodes.i_th (a_node).pinned
		end

	release (a_node: INTEGER)
		require
			known: a_node >= 1 and a_node <= nodes.count
		do
			nodes.i_th (a_node).pinned := False
		ensure
			free: not nodes.i_th (a_node).pinned
		end

feature -- Physics

	relax_step
			-- One tick: repulsion, springs, centre gravity, damping,
			-- bounds. Pinned nodes hold their ground.
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
					f := 2400.0 / d2
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
						.max (16.0).min ((width - 16.0).max (17.0))
					nodes.i_th (i).py := (nodes.i_th (i).py + nodes.i_th (i).vy)
						.max (16.0).min ((height - 16.0).max (17.0))
				end
				i := i + 1
			end
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, hot: INTEGER
			nx, ny: REAL_64
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
			a_p.font ({SW_PAINTER}.Role_ui, 11.5, False)
			from
				i := 1
			until
				i > nodes.count
			loop
				nx := x + nodes.i_th (i).px
				ny := y + nodes.i_th (i).py
				a_p.set_color (t.surface_variant)
				a_p.circle_fill (nx, ny, 7.0)
				if i = selected_index then
					a_p.set_color (t.accent)
				elseif i = hot then
					a_p.set_color (t.ink)
				elseif nodes.i_th (i).pinned then
					a_p.set_color (t.warning)
				else
					a_p.set_color (t.outline)
				end
				a_p.circle_stroke (nx, ny, 7.5)
				if i = selected_index then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.text (nx + 10.0, ny + 4.0, nodes.i_th (i).label)
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

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				selected_index := nearest_node (a_px, a_py)
				drag_index := selected_index
				if selected_index > 0 and then attached on_select as s then
					s.call (selected_index)
				end
				Result := True
			end
		end

	handle_drag (a_px, a_py: REAL_64)
		do
			if drag_index >= 1 and drag_index <= nodes.count then
				nodes.i_th (drag_index).px := (a_px - x).max (16.0).min ((width - 16.0).max (17.0))
				nodes.i_th (drag_index).py := (a_py - y).max (16.0).min ((height - 16.0).max (17.0))
				nodes.i_th (drag_index).vx := 0.0
				nodes.i_th (drag_index).vy := 0.0
				nodes.i_th (drag_index).pinned := True
			end
		end

feature -- Data

	refresh_domains
			-- Structure has no axes; the chassis scales idle.
		do
		end

feature {NONE} -- Engine

	drag_index: INTEGER

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	graph_attached: nodes /= Void and edges /= Void
	edges_bounded: across edges as e all
		e.a >= 1 and e.a <= nodes.count and e.b >= 1 and e.b <= nodes.count end

end
