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

		GW-23: a LAYERED layout (`set_layered'), deterministic and left to
		right, for clause outlines - the force layout is not reproducible.
		Cycles are broken by reversing the back edges a depth-first walk in
		node order finds (drawn dashed); layers by longest path, so every
		other edge runs left to right; each layer ordered by barycenter
		sweeps, ties by node id, to cut crossings; layers spaced by their
		widest label. The same graph lays out the same way every time.
		Edges carry arrowheads; dragging is off in this mode.
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
			is_at_rest := False
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
			is_at_rest := False
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
			is_at_rest := False
		ensure
			held: nodes.i_th (a_node).pinned
		end

	release (a_node: INTEGER)
		require
			known: a_node >= 1 and a_node <= nodes.count
		do
			nodes.i_th (a_node).pinned := False
			is_at_rest := False
		ensure
			free: not nodes.i_th (a_node).pinned
		end

feature -- Physics

	is_at_rest: BOOLEAN
			-- Has `settle' brought the layout to rest since the nodes, edges,
			-- pins or size last changed?

	settle
			-- Reduced motion (scan 12): instead of one step a frame, relax the
			-- layout to rest at once (at most `Settle_steps' steps), then
			-- hold still until something changes.
		local
			k: INTEGER
		do
			if not is_at_rest or else rest_width /= width or else rest_height /= height then
				from
					relax_step
					k := 1
				until
					k >= Settle_steps or else top_speed < Rest_speed
				loop
					relax_step
					k := k + 1
				end
				is_at_rest := True
				rest_width := width
				rest_height := height
			end
		ensure
			at_rest: is_at_rest
		end

	top_speed: REAL_64
			-- The fastest node's speed, summed over both axes.
		do
			across
				nodes as n
			loop
				Result := Result.max (n.vx.abs + n.vy.abs)
			end
		end

	Settle_steps: INTEGER = 400
			-- The most steps one `settle' takes.

	Rest_speed: REAL_64 = 0.01
			-- Below this every node counts as still.

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
			if is_layered then
				lay_out_layers (a_p)
			elseif t.reduces_motion then
				settle
			else
				relax_step
			end
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			if shows_hover then
				hot := nearest_node (hover_px, hover_py)
			end
			a_p.set_color (t.outline)
			from
				i := 1
			until
				i > edges.count
			loop
				if is_layered then
					draw_layered_edge (a_p, i)
				else
					a_p.line (x + nodes.i_th (edges.i_th (i).a).px, y + nodes.i_th (edges.i_th (i).a).py,
						x + nodes.i_th (edges.i_th (i).b).px, y + nodes.i_th (edges.i_th (i).b).py, 1.0)
				end
				i := i + 1
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
			if not is_layered and then drag_index >= 1 and drag_index <= nodes.count then
				nodes.i_th (drag_index).px := (a_px - x).max (16.0).min ((width - 16.0).max (17.0))
				nodes.i_th (drag_index).py := (a_py - y).max (16.0).min ((height - 16.0).max (17.0))
				nodes.i_th (drag_index).vx := 0.0
				nodes.i_th (drag_index).vy := 0.0
				nodes.i_th (drag_index).pinned := True
				is_at_rest := False
			end
		end

feature -- Layered layout (GW-23)

	is_layered: BOOLEAN
			-- Lay out in layers, left to right, deterministically?

	set_layered (a_on: BOOLEAN)
		do
			is_layered := a_on
			layered_key := -1
		ensure
			set: is_layered = a_on
		end

	layering: SW_LAYERED_LAYOUT
			-- The headless engine that breaks cycles, layers and orders
			-- (moved out 2026-10-25, scan finding 10: testable without a
			-- window); this widget places and draws what it decides.
		attribute
			create Result.make
		end

	layer_of: ARRAYED_LIST [INTEGER]
			-- Parallel to `nodes': each node's layer (1 is the leftmost), as
			-- last laid out.
		do
			Result := layering.layer_of
		end

	order_of: ARRAYED_LIST [INTEGER]
			-- Parallel to `nodes': each node's place in its layer from the top.
		do
			Result := layering.order_of
		end

	is_reversed: ARRAYED_LIST [BOOLEAN]
			-- Parallel to `edges': reversed to break a cycle (drawn dashed).
		do
			Result := layering.is_reversed
		end

	back_edge_count: INTEGER
			-- Edges reversed to break cycles.
		do
			Result := layering.back_edge_count
		end

	crossing_count: INTEGER
			-- Pairs of segments that cross, as laid out (long edges through
			-- their dummy nodes).
		do
			Result := layering.crossing_count
		end

	is_layout_current: BOOLEAN
			-- Does the layered layout cover every edge (none added since)?
		do
			Result := layering.edge_count = edges.count
		end

	layout_runs: INTEGER
			-- How many layered layouts have been made (one per change of the
			-- graph or the size, not per frame).

	edge_route (a_edge: INTEGER): ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			-- The points edge `a_edge' is drawn through, in the widget's own
			-- coordinates: its tail, a dummy node in every layer it crosses,
			-- its head (scan 17: long edges were one straight segment through
			-- whatever nodes stood between).
		require
			known: a_edge >= 1 and a_edge <= edges.count
			laid_out: is_layout_current
		do
			create Result.make (layering.edge_chains.i_th (a_edge).count)
			across
				layering.edge_chains.i_th (a_edge) as k
			loop
				Result.extend ([ln_x.i_th (k), ln_y.i_th (k)])
			end
		end

	lay_out_layers (a_p: SW_PAINTER)
			-- Break cycles, assign layers, order them, place them - unless
			-- nothing changed since the last time.
		local
			l_key: INTEGER
		do
			l_key := nodes.count * 100_003 + edges.count * 31 + width.truncated_to_integer * 7 + height.truncated_to_integer
			if l_key /= layered_key then
				layered_key := l_key
				layering.lay_out (nodes.count, edges)
				place_layers (a_p)
				layout_runs := layout_runs + 1
			end
		ensure
			laid_out: layer_of.count = nodes.count and order_of.count = nodes.count
		end

feature {NONE} -- Layered layout internals

	layered_key: INTEGER
			-- What the last layered layout was made for.

	ln_x, ln_y: ARRAYED_LIST [REAL_64]
			-- Each layout node's position (`layering''s graph: real nodes,
			-- then dummies).
		attribute
			create Result.make (8)
		end

	place_layers (a_p: SW_PAINTER)
			-- Layers left to right, each as wide as its widest label; each
			-- layer's nodes spread down the height and centred.
		local
			l_top, l_layer, l_count, l_most: INTEGER
			l_widths: ARRAYED_LIST [REAL_64]
			l_x, l_row, l_inset: REAL_64
			l_lefts: ARRAYED_LIST [REAL_64]
			l_counts: ARRAYED_LIST [INTEGER]
			v: INTEGER
		do
			a_p.font ({SW_PAINTER}.Role_ui, 11.5, False)
			l_inset := a_p.theme.border_width
			l_top := layering.layer_count
			create l_widths.make_filled (l_top)
			create l_counts.make_filled (l_top)
			from v := 1 until v > layering.graph_layer.count loop
				l_layer := layering.graph_layer.i_th (v)
				if v <= nodes.count then
					l_widths.put_i_th (l_widths.i_th (l_layer).max (a_p.advance (nodes.i_th (v).label)), l_layer)
				end
				l_counts.put_i_th (l_counts.i_th (l_layer) + 1, l_layer)
				v := v + 1
			end
			create l_lefts.make (l_top)
			l_x := l_inset + 8.0
			from l_layer := 1 until l_layer > l_top loop
				l_lefts.extend (l_x)
					-- room after the widest label for the edges to slope visibly
				l_x := l_x + 56.0 + l_widths.i_th (l_layer) + l_inset * 2.0
				l_layer := l_layer + 1
			end
			l_most := 1
			across l_counts as k loop l_most := l_most.max (k) end
			l_row := ((height - 2.0 * l_inset - 24.0) / l_most).max (a_p.text_extent * 1.6)
			ln_x.wipe_out
			ln_y.wipe_out
			from v := 1 until v > layering.graph_layer.count loop
				l_layer := layering.graph_layer.i_th (v)
				l_count := l_counts.i_th (l_layer)
				ln_x.extend (l_lefts.i_th (l_layer))
				ln_y.extend ((height - l_count * l_row) / 2.0 + (layering.graph_order.i_th (v) - 0.5) * l_row)
				if v <= nodes.count then
					nodes.i_th (v).px := ln_x.last
					nodes.i_th (v).py := ln_y.last
					nodes.i_th (v).vx := 0.0
					nodes.i_th (v).vy := 0.0
				end
				v := v + 1
			end
		end

	draw_layered_edge (a_p: SW_PAINTER; a_edge: INTEGER)
			-- Along its chain - from the end of the left node's label, through a
			-- dummy node in every layer between, to the right node - with an
			-- arrowhead at the head; a reversed edge dashed, without one.
		local
			ax, ay, bx, by, l_len, ux, uy: REAL_64
			l_pts: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			l_route: ARRAYED_LIST [TUPLE [px, py: REAL_64]]
			m: DOUBLE_MATH
			l_first: INTEGER
		do
			create m
			a_p.font ({SW_PAINTER}.Role_ui, 11.5, False)
			l_route := edge_route (a_edge)
			l_first := layering.edge_chains.i_th (a_edge).first
			create l_pts.make (l_route.count)
			across
				l_route as rp
			loop
				l_pts.extend ([x + rp.px, y + rp.py])
			end
				-- from the end of the left node's label, so no edge runs through it
			l_pts.first.px := l_pts.first.px + 14.0 + a_p.advance (nodes.i_th (l_first).label)
			ax := l_pts.i_th (l_pts.count - 1).px
			ay := l_pts.i_th (l_pts.count - 1).py
			bx := l_pts.last.px
			by := l_pts.last.py
			if is_reversed.i_th (a_edge) then
				a_p.dashed_polyline (l_pts, 1.2, a_p.Stroke_dashed)
			else
				a_p.dashed_polyline (l_pts, 1.2, a_p.Stroke_solid)
			end
			l_len := m.sqrt ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
			if l_len > 20.0 and then not is_reversed.i_th (a_edge) then
				ux := (bx - ax) / l_len
				uy := (by - ay) / l_len
					-- the arrow stops at the head's ring (radius 8)
				a_p.triangle_fill (bx - ux * 8.0, by - uy * 8.0,
					bx - ux * 16.0 - uy * 4.0, by - uy * 16.0 + ux * 4.0,
					bx - ux * 16.0 + uy * 4.0, by - uy * 16.0 - ux * 4.0)
			end
		end

feature {NONE} -- Rest

	rest_width, rest_height: REAL_64
			-- The size the layout last came to rest at.

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
