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
			sub_widgets, preferred_width,
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

	is_wrapping: BOOLEAN
			-- Flex-wrap: children beyond the width start a new line
			-- instead of clipping. Grow shares are ignored while
			-- wrapping (flexbox's own law).

	cross_axis: INTEGER
			-- Vertical placement within a line: 0 centred (the
			-- default and the old law), 1 top, 2 stretch.

	Cross_center: INTEGER = 0
	Cross_top: INTEGER = 1
	Cross_stretch: INTEGER = 2

	set_wrapping (a_flag: BOOLEAN)
		do
			is_wrapping := a_flag
		ensure
			set: is_wrapping = a_flag
		end

	with_wrapping: like Current
		do
			set_wrapping (True)
			Result := Current
		ensure
			chained: Result = Current
		end

	set_cross_axis (a_axis: INTEGER)
		require
			known: a_axis >= Cross_center and a_axis <= Cross_stretch
		do
			cross_axis := a_axis
		ensure
			set: cross_axis = a_axis
		end

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

feature -- Tooling

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
		do
			Result := children
		end

feature -- Layout

	preferred_width (a_p: SW_PAINTER): REAL_64
			-- The children's natural widths plus the gaps: rows can
			-- finally NEST (a zero-pref inner row drew overflowing
			-- and was unhittable - the OCR rebuild found it in an
			-- afternoon of hand-testing).
		do
			across
				children as c
			loop
				Result := Result + c.clamped_width (c.preferred_width (a_p))
			end
			if children.count > 1 then
				Result := Result + gap * (children.count - 1)
			end
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			h: REAL_64
			widths, heights: ARRAYED_LIST [REAL_64]
			starts: ARRAYED_LIST [INTEGER]
			li, i, line_end: INTEGER
			line_h: REAL_64
		do
			if is_wrapping then
				create widths.make (children.count)
				create heights.make (children.count)
				across
					children as c
				loop
					widths.extend (c.clamped_width (c.preferred_width (a_p)))
					heights.extend (c.clamped_height (c.preferred_height (a_p, widths.last)))
				end
				starts := wrap_starts (widths, gap, a_width)
				from
					li := 1
				until
					li > starts.count
				loop
					if li < starts.count then
						line_end := starts.i_th (li + 1) - 1
					else
						line_end := children.count
					end
					line_h := 0.0
					from
						i := starts.i_th (li)
					until
						i > line_end
					loop
						if heights.i_th (i) > line_h then
							line_h := heights.i_th (i)
						end
						i := i + 1
					end
					Result := Result + line_h
					if li > 1 then
						Result := Result + gap
					end
					li := li + 1
				end
			else
				across
					children as c
				loop
					h := c.preferred_height (a_p, a_width)
					if h > Result then
						Result := h
					end
				end
			end
		end

	wrap_starts (a_widths: ARRAYED_LIST [REAL_64]; a_gap, a_avail: REAL_64): ARRAYED_LIST [INTEGER]
			-- First child index of each wrapped line: greedy fill; a
			-- child wider than the whole width takes its own line.
			-- Pure math - the assault drives it with bare numbers.
		require
			gap_sane: a_gap >= 0.0
		local
			run: REAL_64
			i: INTEGER
		do
			create Result.make (4)
			from
				i := 1
			until
				i > a_widths.count
			loop
				if i = 1 then
					Result.extend (1)
					run := a_widths.i_th (1)
				elseif run + a_gap + a_widths.i_th (i) > a_avail then
					Result.extend (i)
					run := a_widths.i_th (i)
				else
					run := run + a_gap + a_widths.i_th (i)
				end
				i := i + 1
			end
		ensure
			leads: a_widths.count > 0 implies (not Result.is_empty and then Result.first = 1)
			empty_in_empty_out: a_widths.is_empty implies Result.is_empty
		end

	arrange (a_p: SW_PAINTER)
			-- One line (growers share leftover), or greedy wrapped
			-- lines when `is_wrapping'.
		do
			if is_wrapping then
				arrange_wrapped (a_p)
			else
				arrange_line (a_p)
			end
		end

	arrange_wrapped (a_p: SW_PAINTER)
			-- Greedy lines at natural widths; each line as tall as
			-- its tallest child; cross_axis places within the line.
		local
			widths, heights: ARRAYED_LIST [REAL_64]
			starts: ARRAYED_LIST [INTEGER]
			li, i, line_end: INTEGER
			cx, cy, line_h, ch: REAL_64
		do
			create widths.make (children.count)
			create heights.make (children.count)
			across
				children as c
			loop
				widths.extend (c.clamped_width (c.preferred_width (a_p)))
				heights.extend (c.clamped_height (c.preferred_height (a_p, widths.last)))
			end
			starts := wrap_starts (widths, gap, width)
			cy := y
			from
				li := 1
			until
				li > starts.count
			loop
				if li < starts.count then
					line_end := starts.i_th (li + 1) - 1
				else
					line_end := children.count
				end
				line_h := 0.0
				from
					i := starts.i_th (li)
				until
					i > line_end
				loop
					if heights.i_th (i) > line_h then
						line_h := heights.i_th (i)
					end
					i := i + 1
				end
				cx := x
				from
					i := starts.i_th (li)
				until
					i > line_end
				loop
					ch := heights.i_th (i)
					if cross_axis = Cross_stretch then
						ch := line_h
					end
					if cross_axis = Cross_center then
						children.i_th (i).set_bounds (cx, cy + (line_h - ch) / 2.0, widths.i_th (i), ch)
					else
						children.i_th (i).set_bounds (cx, cy, widths.i_th (i), ch)
					end
					children.i_th (i).arrange (a_p)
					cx := cx + widths.i_th (i) + gap
					i := i + 1
				end
				cy := cy + line_h + gap
				li := li + 1
			end
		end

	arrange_line (a_p: SW_PAINTER)
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
				if cross_axis = Cross_stretch or ch > height then
					ch := height
				end
				if cross_axis = Cross_top or cross_axis = Cross_stretch then
					children.i_th (i).set_bounds (cx, y, cw, ch)
				else
					children.i_th (i).set_bounds (cx, y + (height - ch) / 2.0, cw, ch)
				end
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
