note
	description: "[
		Children stacked top to bottom, each given the full inner
		width, separated by the gap, inset by the padding.
	]"

class
	SW_COLUMN

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
			padding := 0.0
		end

feature -- Access

	children: ARRAYED_LIST [SW_WIDGET]
	gap: REAL_64
	padding: REAL_64

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

	with_padding (a_pad: REAL_64): like Current
		require
			non_negative: a_pad >= 0.0
		do
			padding := a_pad
			Result := Current
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			inner: REAL_64
			n: INTEGER
		do
			inner := (a_width - 2.0 * padding).max (0.0)
			across
				children as c
			loop
				Result := Result + c.preferred_height (a_p, inner)
				n := n + 1
			end
			if n > 1 then
				Result := Result + gap * (n - 1)
			end
			Result := Result + 2.0 * padding
		end

	arrange (a_p: SW_PAINTER)
		local
			cy, inner, ch: REAL_64
		do
			inner := (width - 2.0 * padding).max (0.0)
			cy := y + padding
			across
				children as c
			loop
				ch := c.preferred_height (a_p, inner)
				c.set_bounds (x + padding, cy, inner, ch)
				c.arrange (a_p)
				cy := cy + ch + gap
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
	padding_non_negative: padding >= 0.0

end
