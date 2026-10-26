note
	description: "[
		The layered (Sugiyama) layout, headless: no painter, no widget
		(moved out of SW_DIAGRAM 2026-10-25, design scan finding 10, so the
		algorithms are tested without a window and can serve other owners).
		Given a node count and edges it breaks cycles (a depth-first walk
		reverses back edges), layers by longest path, gives every edge
		longer than one layer a dummy node in each layer between, and orders
		each layer by barycenter sweeps. Deterministic: the same graph lays
		out the same. Placing and drawing belong to the owner.
	]"

class
	SW_LAYERED_LAYOUT

create
	make

feature {NONE} -- Initialization

	make
		do
			create layer_of.make (8)
			create order_of.make (8)
			create is_reversed.make (8)
			create edge_a.make (8)
			create edge_b.make (8)
			create graph_layer.make (8)
			create graph_order.make (8)
			create segments.make (8)
			create edge_chains.make (8)
		end

feature -- Layout

	lay_out (a_node_count: INTEGER; a_edges: LIST [TUPLE [a, b: INTEGER]])
			-- Lay out `a_node_count' nodes joined by `a_edges' (node ids
			-- 1 .. `a_node_count', no self-loops).
		require
			count_sane: a_node_count >= 0
			edges_bounded: across a_edges as e all e.a >= 1 and e.a <= a_node_count and e.b >= 1 and e.b <= a_node_count end
			no_self_loop: across a_edges as e all e.a /= e.b end
		do
			node_count := a_node_count
			edge_a.wipe_out
			edge_b.wipe_out
			across a_edges as e loop
				edge_a.extend (e.a)
				edge_b.extend (e.b)
			end
			break_cycles
			assign_layers
			build_layout_graph
			order_layers
		ensure
			per_node: layer_of.count = a_node_count and order_of.count = a_node_count
			per_edge: is_reversed.count = a_edges.count and edge_chains.count = a_edges.count
		end

feature -- Access

	node_count: INTEGER
			-- Real nodes, as last laid out.

	edge_count: INTEGER
			-- Edges, as last laid out.
		do
			Result := edge_a.count
		end

	layer_of: ARRAYED_LIST [INTEGER]
			-- Each real node's layer (1 is the first).

	order_of: ARRAYED_LIST [INTEGER]
			-- Each real node's place in its layer.

	is_reversed: ARRAYED_LIST [BOOLEAN]
			-- Each edge: reversed to break a cycle?

	back_edge_count: INTEGER
			-- Edges reversed to break cycles.
		do
			across
				is_reversed as r
			loop
				if r then
					Result := Result + 1
				end
			end
		end

	layer_count: INTEGER
			-- The last layer.
		do
			across layer_of as l loop
				Result := Result.max (l)
			end
		end

	crossing_count: INTEGER
			-- Pairs of segments that cross, as laid out. A long edge is a chain
			-- of segments through its dummy nodes, so its crossings count too
			-- (scan 17: only adjacent-layer edges were counted).
		local
			i, j: INTEGER
			u1, v1, u2, v2: INTEGER
		do
			from i := 1 until i > segments.count loop
				from j := i + 1 until j > segments.count loop
					u1 := segments.i_th (i).u; v1 := segments.i_th (i).v
					u2 := segments.i_th (j).u; v2 := segments.i_th (j).v
					if graph_layer.i_th (u1) = graph_layer.i_th (u2)
						and then (graph_order.i_th (u1) - graph_order.i_th (u2)) * (graph_order.i_th (v1) - graph_order.i_th (v2)) < 0
					then
						Result := Result + 1
					end
					j := j + 1
				end
				i := i + 1
			end
		end

feature -- The layout graph

	graph_layer, graph_order: ARRAYED_LIST [INTEGER]
			-- The layout graph: real nodes 1 .. `node_count', then the dummy
			-- nodes long edges pass through; each one's layer and place.

	segments: ARRAYED_LIST [TUPLE [u, v: INTEGER]]
			-- Layout-graph edges, each from a layer to the next.

	edge_chains: ARRAYED_LIST [ARRAYED_LIST [INTEGER]]
			-- Each edge: the layout nodes it is drawn through, in
			-- layer order.

	tail (a_edge: INTEGER): INTEGER
			-- The edge's start after cycle breaking.
		require
			known: a_edge >= 1 and a_edge <= edge_count
		do
			if is_reversed.i_th (a_edge) then
				Result := edge_b.i_th (a_edge)
			else
				Result := edge_a.i_th (a_edge)
			end
		end

	head (a_edge: INTEGER): INTEGER
			-- The edge's end after cycle breaking.
		require
			known: a_edge >= 1 and a_edge <= edge_count
		do
			if is_reversed.i_th (a_edge) then
				Result := edge_a.i_th (a_edge)
			else
				Result := edge_b.i_th (a_edge)
			end
		end

feature {NONE} -- Steps

	edge_a, edge_b: ARRAYED_LIST [INTEGER]
			-- The edges' ends as given.

	build_layout_graph
			-- Real nodes keep their layers; each edge longer than one layer gets
			-- a dummy node in every layer between (the Sugiyama method), and
			-- every edge becomes a chain of one-layer segments.
		local
			i, l, l_prev, l_dummy: INTEGER
			l_chain: ARRAYED_LIST [INTEGER]
		do
			graph_layer.wipe_out
			graph_layer.append (layer_of)
			segments.wipe_out
			edge_chains.wipe_out
			from i := 1 until i > edge_count loop
				create l_chain.make (2)
				l_chain.extend (tail (i))
				l_prev := tail (i)
				from l := layer_of.i_th (tail (i)) + 1 until l >= layer_of.i_th (head (i)) loop
					graph_layer.extend (l)
					l_dummy := graph_layer.count
					segments.extend ([l_prev, l_dummy])
					l_chain.extend (l_dummy)
					l_prev := l_dummy
					l := l + 1
				end
				segments.extend ([l_prev, head (i)])
				l_chain.extend (head (i))
				edge_chains.extend (l_chain)
				i := i + 1
			end
		ensure
			one_chain_per_edge: edge_chains.count = edge_count
			one_layer_per_segment: across segments as sg all graph_layer.i_th (sg.v) = graph_layer.i_th (sg.u) + 1 end
		end

	break_cycles
			-- A depth-first walk from each node in id order; an edge to a node
			-- still on the walk's stack is a back edge and is reversed.
		local
			l_state: ARRAYED_LIST [INTEGER]
			v: INTEGER
		do
			is_reversed.wipe_out
			across edge_a as e loop is_reversed.extend (False) end
			create l_state.make_filled (node_count)
			from v := 1 until v > node_count loop
				if l_state.i_th (v) = 0 then
					visit (v, l_state)
				end
				v := v + 1
			end
		ensure
			parallel: is_reversed.count = edge_count
		end

	visit (a_v: INTEGER; a_state: ARRAYED_LIST [INTEGER])
			-- 1 on the stack, 2 done.
		local
			i: INTEGER
		do
			a_state.put_i_th (1, a_v)
			from i := 1 until i > edge_count loop
				if edge_a.i_th (i) = a_v then
					inspect a_state.i_th (edge_b.i_th (i))
					when 0 then
						visit (edge_b.i_th (i), a_state)
					when 1 then
						is_reversed.put_i_th (True, i)
					else
					end
				end
				i := i + 1
			end
			a_state.put_i_th (2, a_v)
		end

	assign_layers
			-- Longest path: a node's layer is one more than its deepest
			-- predecessor's (relaxed until stable; the graph is acyclic now).
		local
			i: INTEGER
			l_changed: BOOLEAN
		do
			layer_of.wipe_out
			across 1 |..| node_count as n loop layer_of.extend (1) end
			from
				l_changed := True
			until
				not l_changed
			loop
				l_changed := False
				from i := 1 until i > edge_count loop
					if layer_of.i_th (head (i)) < layer_of.i_th (tail (i)) + 1 then
						layer_of.put_i_th (layer_of.i_th (tail (i)) + 1, head (i))
						l_changed := True
					end
					i := i + 1
				end
			end
		ensure
			left_to_right: across 1 |..| edge_count as k all layer_of.i_th (head (k)) > layer_of.i_th (tail (k)) end
		end

	order_layers
			-- Start in id order (real nodes, then dummies); then four barycenter
			-- sweeps, down and up, each layer sorted by the mean place of its
			-- neighbours in the layer before (ties by id).
		local
			l_sweep, l_layer, l_top: INTEGER
		do
			graph_order.wipe_out
			across graph_layer as n loop graph_order.extend (0) end
			l_top := 0
			across graph_layer as l loop l_top := l_top.max (l) end
			from l_layer := 1 until l_layer > l_top loop
				sort_layer (l_layer, 0)
				l_layer := l_layer + 1
			end
			from l_sweep := 1 until l_sweep > 4 loop
				if l_sweep \\ 2 = 1 then
					from l_layer := 2 until l_layer > l_top loop
						sort_layer (l_layer, -1)
						l_layer := l_layer + 1
					end
				else
					from l_layer := l_top - 1 until l_layer < 1 loop
						sort_layer (l_layer, 1)
						l_layer := l_layer - 1
					end
				end
				l_sweep := l_sweep + 1
			end
			order_of.wipe_out
			from l_layer := 1 until l_layer > node_count loop
				order_of.extend (graph_order.i_th (l_layer))
				l_layer := l_layer + 1
			end
		end

	sort_layer (a_layer, a_side: INTEGER)
			-- Order layer `a_layer' of the layout graph by barycenter against
			-- the layer on `a_side' (-1 before, 1 after; 0: by id alone).
		local
			l_members: ARRAYED_LIST [INTEGER]
			l_keys: ARRAYED_LIST [REAL_64]
			i, j, v, n: INTEGER
			l_sum, l_key: REAL_64
		do
			create l_members.make (4)
			create l_keys.make (4)
			from v := 1 until v > graph_layer.count loop
				if graph_layer.i_th (v) = a_layer then
					l_sum := 0.0
					n := 0
					if a_side /= 0 then
						across
							segments as sg
						loop
							if a_side < 0 and then sg.v = v then
								l_sum := l_sum + graph_order.i_th (sg.u)
								n := n + 1
							elseif a_side > 0 and then sg.u = v then
								l_sum := l_sum + graph_order.i_th (sg.v)
								n := n + 1
							end
						end
					end
					if n > 0 then
						l_key := l_sum / n
					elseif a_side /= 0 then
						l_key := graph_order.i_th (v)
					else
						l_key := v
					end
					from
						j := l_members.count
					until
						j < 1 or else l_keys.i_th (j) < l_key or else (l_keys.i_th (j) = l_key and then l_members.i_th (j) < v)
					loop
						j := j - 1
					end
					l_members.go_i_th (j)
					l_members.put_right (v)
					l_keys.go_i_th (j)
					l_keys.put_right (l_key)
				end
				v := v + 1
			end
			from i := 1 until i > l_members.count loop
				graph_order.put_i_th (i, l_members.i_th (i))
				i := i + 1
			end
		end

invariant
	parallel_edges: edge_a.count = edge_b.count

end
