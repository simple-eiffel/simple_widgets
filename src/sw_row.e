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
			children.extend (a_w)
			Result := Current
		ensure
			added: children.last = a_w
			chained: Result = Current
		end

	put (a_w: SW_WIDGET)
		do
			children.extend (a_w)
		ensure
			added: children.last = a_w
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
		local
			cx, cw, ch: REAL_64
		do
			cx := x
			across
				children as c
			loop
				cw := c.preferred_width (a_p)
				ch := c.preferred_height (a_p, cw)
				c.set_bounds (cx, y + (height - ch) / 2.0, cw, ch)
				c.arrange (a_p)
				cx := cx + cw + gap
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
