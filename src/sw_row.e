note
	description: "[
		Children side by side at their preferred widths, separated by
		the gap, vertically centred. This container is what deletes the
		'x := x + advance (label) + 8.0' arithmetic from applications.
	]"

class
	SW_ROW

inherit
	SW_WIDGET
		redefine
			arrange, widget_at
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create children.make (8)
			gap := 8.0
		end

feature -- Access

	children: ARRAYED_LIST [SW_WIDGET]
	gap: REAL_64

feature -- Element change

	add (a_w: SW_WIDGET): like Current
			-- Fluent append.
		do
			put (a_w)
			Result := Current
		ensure
			added: children.last = a_w
			chained: Result = Current
		end

	put (a_w: SW_WIDGET)
		do
			children.extend (a_w)
			a_w.set_parent (Current)
		ensure
			added: children.last = a_w
			adopted: a_w.parent = Current
		end

	with_gap (a_gap: REAL_64): like Current
		require
			non_negative: a_gap >= 0.0
		do
			gap := a_gap
			Result := Current
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			h: REAL_64
		do
			across
				children as c
			loop
				h := c.preferred_height (a_p, a_width)
				if h > Result then
					Result := h
				end
			end
		end

	arrange (a_p: SW_PAINTER)
			-- Natural widths first; leftover space then splits among
			-- growers by weight - the containership pass.
		local
			cx, cw, ch, natural, leftover, total_grow: REAL_64
			widths: ARRAYED_LIST [REAL_64]
			i: INTEGER
		do
			create widths.make (children.count)
			across
				children as c
			loop
				widths.extend (c.clamped_width (c.preferred_width (a_p)))
				natural := natural + widths.last
				total_grow := total_grow + c.grow
			end
			if children.count > 1 then
				natural := natural + gap * (children.count - 1)
			end
			leftover := width - natural
			cx := x
			from
				i := 1
			until
				i > children.count
			loop
				cw := widths.i_th (i)
				if leftover > 0.0 and total_grow > 0.0 and children.i_th (i).grow > 0.0 then
					cw := children.i_th (i).clamped_width
						(cw + leftover * children.i_th (i).grow / total_grow)
				end
				ch := children.i_th (i).clamped_height
					(children.i_th (i).preferred_height (a_p, cw))
				if ch > height then
					ch := height
				end
				children.i_th (i).set_bounds (cx, y + (height - ch) / 2.0, cw, ch)
				children.i_th (i).arrange (a_p)
				cx := cx + cw + gap
				i := i + 1
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		do
			across
				children as c
			loop
				c.draw (a_p)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		do
			if contains (a_px, a_py) then
				across
					children as c
				until
					Result /= Void
				loop
					Result := c.widget_at (a_px, a_py)
				end
				if Result = Void then
					Result := Current
				end
			end
		end

invariant
	children_attached: children /= Void
	gap_non_negative: gap >= 0.0

end
