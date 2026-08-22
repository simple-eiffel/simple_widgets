note
	description: "[
		Flow as ribbons: nodes assigned to columns, links carrying
		value between them, drawn as cubic-bezier bands (the painter
		gained ribbon_fill - curves at last, as the roadmap said it
		would here). A node's THROUGHPUT is the larger of its
		inflow and outflow; heights are proportional to throughput
		within each column; link bands leave and arrive at stacked
		offsets so ribbons never overlap at their moorings. The
		layout is public math - refresh_layout, node_rect, link_band
		- and the assault proves proportionality, contiguous
		moorings, and honest throughput. Hover names a node with its
		in/out totals; ribbon hit-testing is a stated future.
	]"

class
	SW_SANKEY

inherit
	SW_CHART
		redefine
			draw
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			make_chart
			create nodes.make (8)
			create links.make (8)
			create node_rects.make_filled ([0.0, 0.0, 0.0, 0.0], 1, 1)
			create link_bands.make_filled ([0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 1, 1)
		end

feature -- Access

	nodes: ARRAYED_LIST [TUPLE [label: STRING_32; column: INTEGER]]

	links: ARRAYED_LIST [TUPLE [source, target: INTEGER; value: REAL_64]]

	node_rects: ARRAY [TUPLE [rx, ry, rw, rh: REAL_64]]
			-- One bar per node, valid after refresh_layout.

	link_bands: ARRAY [TUPLE [x0, y0_top, y0_bot, x1, y1_top, y1_bot: REAL_64]]
			-- One ribbon per link, valid after refresh_layout.

	column_count: INTEGER
		do
			across
				nodes as n
			loop
				Result := Result.max (n.column)
			end
		end

	inflow_of (a_node: INTEGER): REAL_64
		require
			known: a_node >= 1 and a_node <= nodes.count
		do
			across
				links as l
			loop
				if l.target = a_node then
					Result := Result + l.value
				end
			end
		end

	outflow_of (a_node: INTEGER): REAL_64
		require
			known: a_node >= 1 and a_node <= nodes.count
		do
			across
				links as l
			loop
				if l.source = a_node then
					Result := Result + l.value
				end
			end
		end

	throughput_of (a_node: INTEGER): REAL_64
			-- The node's height driver: the larger of its flows.
		require
			known: a_node >= 1 and a_node <= nodes.count
		do
			Result := inflow_of (a_node).max (outflow_of (a_node))
		ensure
			non_negative: Result >= 0.0
		end

	node_at (a_px, a_py: REAL_64): INTEGER
			-- The node bar under a point; 0 outside. Valid after
			-- refresh_layout.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > nodes.count or Result > 0
			loop
				if i <= node_rects.count
					and then a_px >= node_rects [i].rx and then a_px <= node_rects [i].rx + node_rects [i].rw
					and then a_py >= node_rects [i].ry and then a_py <= node_rects [i].ry + node_rects [i].rh
				then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= nodes.count
		end

feature -- Element change

	add_node (a_label: READABLE_STRING_GENERAL; a_column: INTEGER): INTEGER
			-- Register a node in `a_column'; its id for linking.
		require
			column_positive: a_column >= 1
		local
			l: STRING_32
		do
			create l.make_from_string_general (a_label)
			nodes.extend ([l, a_column])
			Result := nodes.count
		ensure
			grew: nodes.count = old nodes.count + 1
			id_is_last: Result = nodes.count
		end

	add_link (a_source, a_target: INTEGER; a_value: REAL_64)
		require
			source_known: a_source >= 1 and a_source <= nodes.count
			target_known: a_target >= 1 and a_target <= nodes.count
			flows_rightward: nodes.i_th (a_source).column < nodes.i_th (a_target).column
			positive: a_value > 0.0
		do
			links.extend ([a_source, a_target, a_value])
		ensure
			grew: links.count = old links.count + 1
		end

feature -- Layout

	Node_w: REAL_64 = 14.0

	refresh_layout
			-- Bars per column (heights proportional to throughput),
			-- then ribbons at stacked moorings. Public for assaults.
		local
			col, i, k: INTEGER
			col_total, gap, cy, col_x, scale_h, off_s, off_t, th: REAL_64
			out_off, in_off: ARRAY [REAL_64]
		do
			create node_rects.make_filled ([0.0, 0.0, 0.0, 0.0], 1, nodes.count.max (1))
			create link_bands.make_filled ([0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 1, links.count.max (1))
			if not nodes.is_empty and then column_count >= 1 then
				from
					col := 1
				until
					col > column_count
				loop
					col_total := 0.0
					k := 0
					from
						i := 1
					until
						i > nodes.count
					loop
						if nodes.i_th (i).column = col then
							col_total := col_total + throughput_of (i)
							k := k + 1
						end
						i := i + 1
					end
					if k > 0 and col_total > 0.0 then
						gap := 12.0
						scale_h := (plot_h - gap * (k - 1)) / col_total
						if column_count > 1 then
							col_x := plot_x + (col - 1) / (column_count - 1)
								* (plot_w - Node_w)
						else
							col_x := plot_x + (plot_w - Node_w) / 2.0
						end
						cy := plot_y
						from
							i := 1
						until
							i > nodes.count
						loop
							if nodes.i_th (i).column = col then
								node_rects [i] := [col_x, cy, Node_w,
									(throughput_of (i) * scale_h).max (2.0)]
								cy := cy + throughput_of (i) * scale_h + gap
							end
							i := i + 1
						end
					end
					col := col + 1
				end
					-- moorings: stack link bands down each node's edge
				create out_off.make_filled (0.0, 1, nodes.count)
				create in_off.make_filled (0.0, 1, nodes.count)
				from
					i := 1
				until
					i > links.count
				loop
					off_s := out_off [links.i_th (i).source]
					off_t := in_off [links.i_th (i).target]
					if throughput_of (links.i_th (i).source) > 0.0 then
						th := links.i_th (i).value
							/ throughput_of (links.i_th (i).source)
							* node_rects [links.i_th (i).source].rh
					else
						th := 2.0
					end
					link_bands [i] := [
						node_rects [links.i_th (i).source].rx + Node_w,
						node_rects [links.i_th (i).source].ry + off_s,
						node_rects [links.i_th (i).source].ry + off_s + th,
						node_rects [links.i_th (i).target].rx,
						node_rects [links.i_th (i).target].ry + off_t,
						node_rects [links.i_th (i).target].ry + off_t
							+ (if throughput_of (links.i_th (i).target) > 0.0 then
								links.i_th (i).value
									/ throughput_of (links.i_th (i).target)
									* node_rects [links.i_th (i).target].rh
							else
								2.0
							end)]
					out_off [links.i_th (i).source] := off_s + th
					in_off [links.i_th (i).target] := in_off [links.i_th (i).target]
						+ (link_bands [i].y1_bot - link_bands [i].y1_top)
					i := i + 1
				end
			end
		end

feature -- Data

	refresh_domains
			-- Flows have no axes; the chassis scales idle.
		do
		end

feature -- Drawing

	node_color (a_index: INTEGER; a_p: SW_PAINTER): NATURAL_32
		do
			inspect (a_index - 1) \\ 4
			when 0 then
				Result := a_p.theme.accent
			when 1 then
				Result := a_p.theme.success
			when 2 then
				Result := a_p.theme.warning
			else
				Result := a_p.theme.danger
			end
		end

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i, hot: INTEGER
			chip: STRING_32
		do
			t := a_p.theme
			a_p.set_color (t.surface)
			a_p.rrect_fill (x, y, width, height, t.radius)
			refresh_layout
			if shows_hover then
				hot := node_at (hover_px, hover_py)
			end
				-- ribbons first, washed in their source's colour
			from
				i := 1
			until
				i > links.count
			loop
				a_p.set_color_alpha (node_color (links.i_th (i).source, a_p), 0.35)
				a_p.ribbon_fill (link_bands [i].x0, link_bands [i].y0_top,
					link_bands [i].y0_bot, link_bands [i].x1,
					link_bands [i].y1_top, link_bands [i].y1_bot)
				i := i + 1
			end
				-- node bars over them
			from
				i := 1
			until
				i > nodes.count
			loop
				a_p.set_color (node_color (i, a_p))
				a_p.fill_rect (node_rects [i].rx, node_rects [i].ry,
					node_rects [i].rw, node_rects [i].rh)
				a_p.font ({SW_PAINTER}.Role_ui, 11.5, i = hot)
				if i = hot then
					a_p.set_color (t.ink)
				else
					a_p.set_color (t.ink_muted)
				end
				if nodes.i_th (i).column = 1 then
					a_p.text (node_rects [i].rx - 6.0
						- a_p.advance (nodes.i_th (i).label),
						node_rects [i].ry + node_rects [i].rh / 2.0 + 4.0,
						nodes.i_th (i).label)
				else
					a_p.text (node_rects [i].rx + Node_w + 6.0,
						node_rects [i].ry + node_rects [i].rh / 2.0 + 4.0,
						nodes.i_th (i).label)
				end
				i := i + 1
			end
			if hot > 0 then
				create chip.make (40)
				chip.append (nodes.i_th (hot).label)
				chip.append ({STRING_32} " %/8212/ in ")
				chip.append (label_of (inflow_of (hot)))
				chip.append ({STRING_32} ", out ")
				chip.append (label_of (outflow_of (hot)))
				a_p.font ({SW_PAINTER}.Role_mono, 11.0, False)
				a_p.set_color (t.surface_variant)
				a_p.rrect_fill (x + 10.0, y + height - 24.0,
					a_p.advance (chip) + 10.0, 17.0, 3.0)
				a_p.set_color (t.ink)
				a_p.text (x + 15.0, y + height - 11.0, chip)
			end
			if not title.is_empty then
				a_p.font ({SW_PAINTER}.Role_ui, t.size_chip, True)
				a_p.set_color (t.ink_muted)
				a_p.text (x + 10.0, y + 16.0, title)
			end
			a_p.set_color (t.outline)
			a_p.rrect_stroke (x + 0.5, y + 0.5, width - 1.0, height - 1.0, t.radius)
		end

feature {NONE} -- Chassis contract

	draw_data (a_p: SW_PAINTER)
			-- Unused: draw is redefined wholesale.
		do
		end

invariant
	organs: nodes /= Void and links /= Void and node_rects /= Void and link_bands /= Void

end
