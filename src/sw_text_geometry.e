note
	description: "[
		Where every character of a text paints: one slot per character
		(left edge, width, visual line, direction, is it a line break)
		and one record per visual line (top, ascent, height), built
		from either engine -

		    build_shaped   the shaping kit, one layout per LF piece,
		                   edges from the runs' cluster arithmetic
		    build_toy      cairo's advances and a greedy word wrap

		- so that a caret, a selection, a spell squiggle, a highlight
		box and a hit-test all ask ONE object the same questions and
		get the same answers on both paths. Lifted out of SW_TEXT_BOX
		in 0.8.0 so SW_PARAGRAPH_LIST and SW_MARK_PAINTER could ask
		them too.

		THE CARET LAW. The caret after character i stands at its right
		edge in a left-to-right run and its LEFT edge in a right-to-left
		one; before character 1 it is the mirror. Where the two
		directions meet, two offsets share a pixel, and a hit-test
		gives the click to the left-to-right side (see `offset_on_line').
		A line break's slot is zero-width at the START of the line it
		opens, so a caret after Enter draws on the new line.

		`segments' merges a character range into one rectangle per
		visual line - what a wash, a box or a selection paints - in the
		coordinate frame of the text's own origin.
	]"
	author: "Larry Rix"

class
	SW_TEXT_GEOMETRY

inherit
	SW_CLUSTER_MATH

create
	make

feature {NONE} -- Initialization

	make
			-- Empty: no characters, one empty line of no height.
		do
			create lay_x.make (16)
			create lay_adv.make (16)
			create lay_line.make (16)
			create lay_rtl.make (16)
			create lay_break.make (16)
			create line_top.make (2)
			create line_ascent.make (2)
			create line_height.make (2)
			create layouts.make (2)
			create para_tops.make (2)
			line_top.extend (0.0)
			line_ascent.extend (0.0)
			line_height.extend (0.0)
		ensure
			empty: count = 0
			one_line: line_count = 1
		end

feature -- Access

	count: INTEGER
			-- Characters laid out.
		do
			Result := lay_x.count
		end

	line_count: INTEGER
		do
			Result := line_top.count
		ensure
			at_least_one: Result >= 1
		end

	is_shaped: BOOLEAN
			-- Did the last build go through the shaping kit?

	layouts: ARRAYED_LIST [SHAPED_LAYOUT]
			-- On the shaped path, one layout per LF piece; empty on toy.

	para_tops: ARRAYED_LIST [REAL_64]
			-- Per layout, its top below the text origin.

	x_of (a_i: INTEGER): REAL_64
			-- Character `a_i''s left edge.
		require
			in_text: a_i >= 1 and a_i <= count
		do
			Result := lay_x.i_th (a_i)
		end

	width_of (a_i: INTEGER): REAL_64
		require
			in_text: a_i >= 1 and a_i <= count
		do
			Result := lay_adv.i_th (a_i)
		end

	line_of (a_i: INTEGER): INTEGER
			-- Character `a_i''s 0-based visual line.
		require
			in_text: a_i >= 1 and a_i <= count
		do
			Result := lay_line.i_th (a_i)
		ensure
			in_lines: Result >= 0 and Result < line_count
		end

	is_rtl (a_i: INTEGER): BOOLEAN
		require
			in_text: a_i >= 1 and a_i <= count
		do
			Result := lay_rtl.i_th (a_i)
		end

	is_break (a_i: INTEGER): BOOLEAN
			-- Is slot `a_i' a line break shown as one?
		require
			in_text: a_i >= 1 and a_i <= count
		do
			Result := lay_break.i_th (a_i)
		end

	top_of_line (a_line: INTEGER): REAL_64
		require
			in_lines: a_line >= 0 and a_line < line_count
		do
			Result := line_top.i_th (a_line + 1)
		end

	ascent_of_line (a_line: INTEGER): REAL_64
		require
			in_lines: a_line >= 0 and a_line < line_count
		do
			Result := line_ascent.i_th (a_line + 1)
		end

	height_of_line (a_line: INTEGER): REAL_64
		require
			in_lines: a_line >= 0 and a_line < line_count
		do
			Result := line_height.i_th (a_line + 1)
		end

	content_height: REAL_64
			-- Every line stacked.
		do
			Result := line_top.last + line_height.last
		ensure
			non_negative: Result >= 0.0
		end

feature -- Caret geometry

	line_at_offset (a_offset: INTEGER): INTEGER
			-- The 0-based visual line the caret stands on at `a_offset'.
		require
			in_range: a_offset >= 0 and a_offset <= count
		do
			if count > 0 then
				if a_offset = 0 then
					Result := lay_line.i_th (1)
				else
					Result := lay_line.i_th (a_offset)
				end
			end
		ensure
			in_lines: Result >= 0 and Result < line_count
		end

	x_at_offset (a_offset: INTEGER): REAL_64
			-- Where the caret stands at `a_offset': after character
			-- `a_offset' in reading order, before the first at 0.
		require
			in_range: a_offset >= 0 and a_offset <= count
		do
			if count > 0 then
				if a_offset = 0 then
					if lay_rtl.i_th (1) then
						Result := lay_x.i_th (1) + lay_adv.i_th (1)
					else
						Result := lay_x.i_th (1)
					end
				elseif lay_rtl.i_th (a_offset) then
					Result := lay_x.i_th (a_offset)
				else
					Result := lay_x.i_th (a_offset) + lay_adv.i_th (a_offset)
				end
			end
		ensure
			non_negative: Result >= 0.0
		end

	line_start (a_line: INTEGER): INTEGER
			-- The caret offset at the start of visual line `a_line'.
		require
			in_lines: a_line >= 0 and a_line < line_count
		local
			i: INTEGER
			found: BOOLEAN
		do
			from
				i := 1
			until
				i > count or found
			loop
				if lay_line.i_th (i) = a_line then
					if lay_break.i_th (i) then
						Result := i
					else
						Result := i - 1
						found := True
					end
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

	line_end (a_line: INTEGER): INTEGER
			-- The caret offset at the end of visual line `a_line'.
		require
			in_lines: a_line >= 0 and a_line < line_count
		local
			i: INTEGER
		do
			Result := line_start (a_line)
			from
				i := 1
			until
				i > count
			loop
				if lay_line.i_th (i) = a_line and then not lay_break.i_th (i) then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= count
			after_the_start: Result >= line_start (a_line)
		end

	offset_on_line (a_line: INTEGER; a_px: REAL_64): INTEGER
			-- The caret offset on visual line `a_line' whose boundary is
			-- nearest `a_px', in whichever direction each character
			-- paints. At the tie where a left-to-right run meets a
			-- right-to-left one, the left-to-right character's boundary
			-- wins; the other offset stays reachable by the arrow keys.
		require
			in_lines: a_line >= 0 and a_line < line_count
		local
			i: INTEGER
			best, d, before, after: REAL_64
			first, best_rtl, rtl: BOOLEAN
		do
			Result := line_start (a_line)
			first := True
			from
				i := 1
			until
				i > count
			loop
				if lay_line.i_th (i) = a_line then
					rtl := lay_rtl.i_th (i)
					if rtl then
						before := lay_x.i_th (i) + lay_adv.i_th (i)
						after := lay_x.i_th (i)
					else
						before := lay_x.i_th (i)
						after := lay_x.i_th (i) + lay_adv.i_th (i)
					end
					if not lay_break.i_th (i) then
						d := (a_px - before).abs
						if first or else d < best or else (d = best and best_rtl and not rtl) then
							best := d
							best_rtl := rtl
							Result := i - 1
							first := False
						end
					end
					d := (a_px - after).abs
					if first or else d < best or else (d = best and (best_rtl or not rtl)) then
						best := d
						best_rtl := rtl
						Result := i
						first := False
					end
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= count
		end

	line_at_y (a_dy: REAL_64): INTEGER
			-- The 0-based visual line under `a_dy' (below the origin),
			-- clamped to the lines that exist.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > line_top.count or else line_top.i_th (i) > a_dy
			loop
				Result := i - 1
				i := i + 1
			end
			Result := Result.max (0).min (line_count - 1)
		ensure
			in_lines: Result >= 0 and Result < line_count
		end

	offset_at (a_dx, a_dy: REAL_64): INTEGER
			-- The caret offset nearest a point in the text's own frame.
		do
			Result := offset_on_line (line_at_y (a_dy), a_dx)
		ensure
			in_range: Result >= 0 and Result <= count
		end

	segments (a_lo, a_hi: INTEGER): ARRAYED_LIST [TUPLE [line: INTEGER; left, width: REAL_64]]
			-- Characters `a_lo' + 1 .. `a_hi' merged into one rectangle
			-- per visual line (breaks skipped), left to right.
		require
			range_valid: a_lo >= 0 and a_lo <= a_hi and a_hi <= count
		local
			i, ln, cur_line: INTEGER
			l, r, cl, cr: REAL_64
			open: BOOLEAN
		do
			create Result.make (2)
			from
				i := a_lo + 1
			until
				i > a_hi
			loop
				if not lay_break.i_th (i) and then lay_adv.i_th (i) > 0.0 then
					ln := lay_line.i_th (i)
					cl := lay_x.i_th (i)
					cr := cl + lay_adv.i_th (i)
					if open and then ln = cur_line then
						l := l.min (cl)
						r := r.max (cr)
					else
						if open then
							Result.extend ([cur_line, l, r - l])
						end
						cur_line := ln
						l := cl
						r := cr
						open := True
					end
				end
				i := i + 1
			end
			if open then
				Result.extend ([cur_line, l, r - l])
			end
		ensure
			positive_widths: across Result as s all s.width > 0.0 end
		end

feature -- Building

	build_toy (a_p: SW_PAINTER; a_text: READABLE_STRING_32; a_wrap: REAL_64;
			a_single_line, a_hidden: BOOLEAN)
			-- One slot per character from cairo's advances (the painter's
			-- current font), greedy word wrap, uniform rows. `a_hidden'
			-- shows every character as a bullet (a password box).
		local
			n, i, j, k, line: INTEGER
			cx, ww, row, base: REAL_64
		do
			reset
			is_shaped := False
			row := a_p.theme.scaled_line_height
			base := (row - a_p.text_extent) / 2.0 + a_p.font_ascent
			n := a_text.count
			from
				i := 1
				cx := 0.0
				line := 0
			until
				i > n
			loop
				if a_text.item (i) = '%N' and then not a_hidden then
					if not a_single_line then
						line := line + 1
						cx := 0.0
					end
					add_slot (cx, 0.0, line, False, not a_single_line)
					i := i + 1
				elseif a_text.item (i) = ' ' and then not a_hidden then
					add_slot (cx, a_p.advance (" "), line, False, False)
					cx := cx + lay_adv.last
					i := i + 1
				else
					from
						j := i
					until
						j >= n or else (not a_hidden and then (a_text.item (j + 1) = ' ' or else a_text.item (j + 1) = '%N'))
					loop
						j := j + 1
					end
					ww := 0.0
					from
						k := i
					until
						k > j
					loop
						ww := ww + a_p.advance (glyph_of (a_text, k, a_hidden))
						k := k + 1
					end
					if not a_single_line and then cx > 0.0 and then cx + ww > a_wrap then
						line := line + 1
						cx := 0.0
					end
					from
						k := i
					until
						k > j
					loop
						add_slot (cx, a_p.advance (glyph_of (a_text, k, a_hidden)), line, False, False)
						cx := cx + lay_adv.last
						k := k + 1
					end
					i := j + 1
				end
			end
			from
				i := 0
			until
				i > line
			loop
				line_top.extend (i * row)
				line_ascent.extend (base)
				line_height.extend (row)
				i := i + 1
			end
		ensure
			one_slot_per_char: count = a_text.count
			toy: not is_shaped
			lines_measured: line_count >= 1
		end

	build_shaped (a_kit: SW_SHAPING; a_text: READABLE_STRING_32; a_wrap_px, a_px: INTEGER;
			a_single_line: BOOLEAN)
			-- One slot per character from the shaping kit: one layout per
			-- LF piece, the runs of every line walked in visual order and
			-- each character's edges from the cluster arithmetic.
		require
			size_positive: a_px > 0
			wrap_non_negative: a_wrap_px >= 0
		local
			n, i, line, para_start, para_end, k, r, c, src, slot: INTEGER
			lay: SHAPED_LAYOUT
			ln: SHAPED_LINE
			rn: SHAPED_RUN
			top, run_left, cl, cr: REAL_64
		do
			reset
			is_shaped := True
			n := a_text.count
			from
				i := 1
			until
				i > n
			loop
				add_slot (0.0, 0.0, 0, False, False)
				i := i + 1
			end
			line := 0
			top := 0.0
			from
				para_start := 1
			until
				para_start > n + 1
			loop
				para_end := para_start
				from
				until
					para_end > n or else (a_text.item (para_end) = '%N' and not a_single_line)
				loop
					para_end := para_end + 1
				end
				lay := a_kit.layout_for (a_text.substring (para_start, para_end - 1), a_wrap_px, a_px)
				layouts.extend (lay)
				para_tops.extend (top)
				from
					k := 1
				until
					k > lay.lines.count
				loop
					ln := lay.lines.i_th (k)
					line_top.extend (top)
					line_ascent.extend (ln.ascent)
					line_height.extend (ln.height)
					from
						src := ln.source_start
					until
						src > ln.source_start + ln.source_count - 1
					loop
						slot := para_start + src - 1
						if slot >= 1 and slot <= n then
							lay_line.put_i_th (line, slot)
							lay_x.put_i_th (ln.width, slot)
						end
						src := src + 1
					end
					run_left := 0.0
					from
						r := 1
					until
						r > ln.runs.count
					loop
						rn := ln.runs.i_th (r)
						from
							c := 1
						until
							c > rn.source_count
						loop
							slot := para_start + rn.source_start + c - 2
							if slot >= 1 and slot <= n then
								cl := run_left + char_left_x (rn, c)
								cr := run_left + char_right_x (rn, c)
								lay_x.put_i_th (cl.min (cr), slot)
								lay_adv.put_i_th ((cr - cl).abs, slot)
								lay_line.put_i_th (line, slot)
								lay_rtl.put_i_th (rn.is_rtl, slot)
							end
							c := c + 1
						end
						run_left := run_left + rn.advance_width
						r := r + 1
					end
					top := top + ln.height
					line := line + 1
					k := k + 1
				end
				if para_end <= n then
					lay_x.put_i_th (0.0, para_end)
					lay_adv.put_i_th (0.0, para_end)
					lay_line.put_i_th (line, para_end)
					lay_rtl.put_i_th (False, para_end)
					lay_break.put_i_th (True, para_end)
				end
				para_start := para_end + 1
			end
			if line_top.is_empty then
				line_top.extend (0.0)
				line_ascent.extend (a_px)
				line_height.extend (a_px * 1.4)
			end
		ensure
			one_slot_per_char: count = a_text.count
			shaped: is_shaped
			lines_measured: line_count >= 1
			a_layout_per_piece: layouts.count = para_tops.count and layouts.count >= 1
		end

feature {NONE} -- Implementation

	lay_x, lay_adv: ARRAYED_LIST [REAL_64]
	lay_line: ARRAYED_LIST [INTEGER]
	lay_rtl, lay_break: ARRAYED_LIST [BOOLEAN]
	line_top, line_ascent, line_height: ARRAYED_LIST [REAL_64]

	reset
		do
			lay_x.wipe_out
			lay_adv.wipe_out
			lay_line.wipe_out
			lay_rtl.wipe_out
			lay_break.wipe_out
			line_top.wipe_out
			line_ascent.wipe_out
			line_height.wipe_out
			layouts.wipe_out
			para_tops.wipe_out
		end

	add_slot (a_x, a_adv: REAL_64; a_line: INTEGER; a_rtl, a_break: BOOLEAN)
		do
			lay_x.extend (a_x)
			lay_adv.extend (a_adv)
			lay_line.extend (a_line)
			lay_rtl.extend (a_rtl)
			lay_break.extend (a_break)
		end

	glyph_of (a_text: READABLE_STRING_32; a_i: INTEGER; a_hidden: BOOLEAN): STRING_32
			-- What position `a_i' shows: the character, or a bullet.
		do
			if a_hidden then
				Result := {STRING_32} "%/8226/"
			else
				Result := a_text.substring (a_i, a_i)
			end
		end

invariant
	slots_parallel: lay_x.count = lay_adv.count and lay_adv.count = lay_line.count
		and lay_line.count = lay_rtl.count and lay_rtl.count = lay_break.count
	lines_parallel: line_top.count = line_ascent.count and line_ascent.count = line_height.count
	layouts_parallel: layouts.count = para_tops.count

end
