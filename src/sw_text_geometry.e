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

		TABS. A tab (U+0009) advances to the next tab stop: stops lie every
		`tab_spaces' space-widths of the face (8 until `set_tab_spaces' -
		GtkTextView's default), measured from the line's start. The tab's
		slot spans from where the
		pen stood to the stop, so a caret, a click, a selection wash and
		the characters after it all read the stop from the same slot. On
		the toy path this is part of the greedy wrap; on the shaped path a
		paragraph holding tabs is laid out as one layout per tab-free
		segment, each placed at its pen position (`para_lefts'), and wraps
		at tabs only (a segment is never broken inside) and is placed flush
		left whatever the alignment.

		COST OF A DRAW. `draw' and `draw_hooked' paint only what the
		painter's clip can show (`last_drawn_count' says how much), found
		by a binary search over the layouts' tops: a text of 10,000 lines
		costs the lines in view. It matters twice over under marks, since
		SW_MARK_PAINTER redraws the text once per colored span, clipped to
		that span: measured in a code editor, 250 lines with about 200
		colored spans in view took 5.6 seconds a frame when every redraw
		walked every layout. The clip alone still lets a line's neighbors
		through (`draw_margin': five or six layouts for the one wanted),
		so the mark painter holds each redraw to its span's own line
		(`hold_draw_to_line').

		COST OF A BUILD. A shaped build keeps its layouts by piece text,
		and the next build takes from them every piece whose text stands
		unchanged, when the kit, its fonts, the size and the facade's
		policy are the same and no styles are set (`last_shaped_count'
		says how many pieces went to the kit). An edit to one line of a
		long text has the kit lay out that line, not the text. The kit's
		own cache cannot do this for a long text: it holds 512 layouts,
		and 10,000 lines of code are some 30,000 pieces.

		Taking every piece from the kept layouts still walks every
		character to place it. So a build also notes its text, and the
		next one, under the same terms, finds the head and the tail the
		two texts share and lays out only the LF pieces between
		(`is_patched'): their slots, lines and layouts take the place
		of the old ones as blocks (SW_LIST_BLOCKS), and what stands
		after them moves by the change in length, in lines and in
		height. It is done for a shaped build of many lines, flush
		left, without styles, of 1,024 characters or more, when the
		pieces between are at most half the text; anything else is
		built whole, as is every 4,096th build in a row. A patched
		build equals a whole one to the bit, but for `para_tops' after
		the edit when a line's height changed: those move by the
		difference, which can differ from a whole build's sum in the
		last bits (the next whole build clears it).

		COST OF A LINE QUERY. Every build notes, per visual line, the
		first and the last slot standing on it and its right edge, so
		`line_start', `line_end', `offset_on_line' and `character_at'
		read one line's slots, `line_at_y' is a binary search over the
		lines' tops, and `rightmost_edge' is kept, not summed. Before
		this each of them walked the whole text: measured in a code
		editor of 10,000 lines, finding the first and last character in
		view took 32 milliseconds of every frame.
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
			create para_lefts.make (2)
			create tabbed_pieces.make (2)
			create para_starts.make (2)
			create line_offset.make (2)
			create line_first.make (2)
			create line_last.make (2)
			create line_right.make (2)
			create kept_wrapped.make (0)
			create kept_unwrapped.make (0)
			create previous_wrapped.make (0)
			create previous_unwrapped.make (0)
			create built_text.make_empty
			create real_blocks
			create integer_blocks
			create boolean_blocks
			create layout_blocks
			line_top.extend (0.0)
			line_ascent.extend (0.0)
			line_height.extend (0.0)
			line_offset.extend (0.0)
			line_first.extend (1)
			line_last.extend (0)
			line_right.extend (0.0)
			alignment := {SHAPING_CONSTANTS}.Align_left
			tab_spaces := Default_tab_spaces
			held_line := -1
		ensure
			empty: count = 0
			every_line_draws: held_line = -1
			flush_left: alignment = {SHAPING_CONSTANTS}.Align_left
			one_line: line_count = 1
			default_stops: tab_spaces = Default_tab_spaces
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

	para_lefts: ARRAYED_LIST [REAL_64]
			-- Per layout, its left edge right of the text origin: 0 for a
			-- tab-free piece, the pen position for a segment after a tab.

	Default_tab_spaces: INTEGER = 8
			-- Space-widths between tab stops until `set_tab_spaces'
			-- (GtkTextView's default).

	tab_spaces: INTEGER
			-- Space-widths between tab stops, from the next build on.

	set_tab_spaces (a_count: INTEGER)
			-- Put the tab stops every `a_count' space-widths. The next build
			-- places by it: the host rebuilds (SW_TEXT_BOX.set_tab_spaces
			-- drops its cached layout).
		require
			positive: a_count >= 1
		do
			tab_spaces := a_count
		ensure
			set: tab_spaces = a_count
		end

	tab_width: REAL_64
			-- The distance between tab stops of the last build: `tab_spaces'
			-- spaces of the face laid out. Positive once something is laid out.

	next_tab_stop (a_x: REAL_64): REAL_64
			-- The first tab stop strictly right of `a_x', measured from the
			-- line's start.
		require
			positive_width: tab_width > 0.0
		do
			Result := ((a_x / tab_width + 0.000001).floor + 1) * tab_width
		ensure
			right_of_it: Result > a_x
		end

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

	tallest_line: REAL_64
			-- The height of the tallest line of the last shaped build (0
			-- before one, and on the toy path).

	rightmost_edge: REAL_64
			-- How far right of the text's origin the last build reaches:
			-- the right edge of the rightmost character on any line (0
			-- with no characters). What a host that scrolls sideways
			-- takes for the content's width.

	right_of_line (a_line: INTEGER): REAL_64
			-- The right edge of the rightmost character on visual line
			-- `a_line' (0 on an empty line).
		require
			in_lines: a_line >= 0 and a_line < line_count
		do
			Result := line_right.i_th (a_line + 1)
		ensure
			non_negative: Result >= 0.0
			within_the_text: Result <= rightmost_edge
		end

	last_drawn_count: INTEGER
			-- How much the last `draw' or `draw_hooked' painted: layouts
			-- on the shaped path, characters on the toy one. The rest lay
			-- outside the painter's clip.

	last_shaped_count: INTEGER
			-- How many pieces the last shaped build had the kit lay out;
			-- the rest it took from the build before, or from an equal
			-- piece of its own (COST OF A BUILD in the class note).

	is_patched: BOOLEAN
			-- Did the last shaped build lay out again only the pieces its
			-- text differed in from the text before, and leave the rest
			-- standing (COST OF A BUILD in the class note)?

	natural_width: REAL_64
			-- The width the text takes laid out on one line: its characters'
			-- advances, whatever the lines' placement (a table column's
			-- natural width).
		local
			k: INTEGER
		do
			from
				k := 1
			until
				k > count
			loop
				if not is_break (k) then
					Result := Result + width_of (k)
				end
				k := k + 1
			end
		ensure
			non_negative: Result >= 0.0
		end

feature -- Alignment (GW-02)

	alignment: INTEGER
			-- How `build_shaped' places each line in `box_width':
			-- a SHAPING_CONSTANTS Align_* code. Align_left (the default)
			-- is the geometry before GW-02; Align_start sets a Hebrew
			-- paragraph flush right and an English one flush left.

	box_width: REAL_64
			-- The width lines are aligned in (0: no alignment).

	set_alignment (a_alignment: INTEGER; a_box_width: REAL_64)
			-- Align the next `build_shaped' by `a_alignment' in a box
			-- `a_box_width' wide. Every slot, caret and hit-test moves
			-- with its line, so they keep agreeing with what paints.
		require
			alignment_valid: a_alignment >= {SHAPING_CONSTANTS}.Align_start
				and a_alignment <= {SHAPING_CONSTANTS}.Align_center
			box_non_negative: a_box_width >= 0.0
		do
			alignment := a_alignment
			box_width := a_box_width
		ensure
			alignment_set: alignment = a_alignment
			box_set: box_width = a_box_width
		end

	offset_of_line (a_line: INTEGER): REAL_64
			-- How far right of the text origin visual line `a_line' starts.
		require
			in_lines: a_line >= 0 and a_line < line_count
		do
			Result := line_offset.i_th (a_line + 1)
		ensure
			non_negative: Result >= 0.0
		end

	is_aligned: BOOLEAN
			-- Will `build_shaped' move lines off the left edge?
		do
			Result := alignment /= {SHAPING_CONSTANTS}.Align_left and box_width > 0.0
		end

	styles: detachable SHAPING_STYLES
			-- How the next `build_shaped' sets stretches of the text
			-- smaller, raised or in small capitals (GW-08); Void or empty:
			-- plain. The toy path ignores it.

	set_styles (a_styles: detachable SHAPING_STYLES)
			-- Set the next `build_shaped' by `a_styles'.
		do
			styles := a_styles
		ensure
			set: styles = a_styles
		end

	fonts: detachable FONT_LIST
			-- The policy the next `build_shaped' lays text out under (GW-13:
			-- SW_SHAPING.fonts_for_role); Void: the kit's own.

	set_fonts (a_fonts: detachable FONT_LIST)
			-- Lay the next `build_shaped' out under `a_fonts'.
		do
			fonts := a_fonts
		ensure
			set: fonts = a_fonts
		end

	own_faces: detachable FONT_LIST
			-- The faces `lay_out' shapes under in place of its role's (a widget's own
			-- style: SW_SHAPING.faced_fonts); Void: the role's.

	set_own_faces (a_faces: detachable FONT_LIST)
			-- Have `lay_out' shape under `a_faces' (Void: under its role's faces again).
		do
			own_faces := a_faces
		ensure
			set: own_faces = a_faces
		end

	toy_role: INTEGER
			-- The painter font `build_toy' measured with, which `draw'
			-- selects again (0: the body face).

	toy_size: REAL_64
	toy_bold: BOOLEAN

	starts_right_to_left: BOOLEAN
			-- Is the first paragraph laid out right to left? (A host puts
			-- a gutter on the reading-start side from this.)
		do
			Result := not layouts.is_empty and then layouts.first.is_rtl
		end

feature -- Caret geometry

	floor_line_height (a_kit: SW_SHAPING; a_px: INTEGER): REAL_64
			-- One line of the face text is laid out in at `a_px': the
			-- leading face of a host's role policy (`fonts', GW-13) when
			-- one is set, else the kit's (`SW_SHAPING.line_height'). The
			-- one floor for an empty piece, a blank text box and a text
			-- box's row (design scan 55: three call sites had drifted).
		require
			size_positive: a_px > 0
		do
			if attached fonts as al_fonts then
				Result := a_kit.facade.line_height (a_px, al_fonts)
			else
				Result := a_kit.line_height (a_px)
			end
		ensure
			positive: Result > 0.0
		end

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
			-- (Like the line queries after it, read from the line's own
			-- slots: COST OF A LINE QUERY in the class note.)
		require
			in_lines: a_line >= 0 and a_line < line_count
		local
			i: INTEGER
			found: BOOLEAN
		do
			from
				i := line_first.i_th (a_line + 1)
			until
				i > line_last.i_th (a_line + 1) or found
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
				i := line_first.i_th (a_line + 1)
			until
				i > line_last.i_th (a_line + 1)
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
				i := line_first.i_th (a_line + 1)
			until
				i > line_last.i_th (a_line + 1)
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
			l_low, l_high, l_mid: INTEGER
		do
				-- the last line whose top is at or above `a_dy': tops ascend
			from
				l_low := 1
				l_high := line_top.count + 1
			until
				l_high - l_low <= 1
			loop
				l_mid := l_low + (l_high - l_low) // 2
				if line_top.i_th (l_mid) <= a_dy then
					l_low := l_mid
				else
					l_high := l_mid
				end
			end
			Result := (l_low - 1).max (0).min (line_count - 1)
		ensure
			in_lines: Result >= 0 and Result < line_count
		end

	character_at (a_dx, a_dy: REAL_64): INTEGER
			-- The character painted under a point in the text's own frame
			-- (GW-08: which word the pointer is over): the one whose slot
			-- holds `a_dx' on the visual line under `a_dy'. 0 off the text -
			-- above or below every line, past a line's ends, on a break.
		local
			i, ln: INTEGER
		do
			if count > 0 and then a_dy >= 0.0 and then a_dy < content_height then
				ln := line_at_y (a_dy)
				from
					i := line_first.i_th (ln + 1)
				until
					i > line_last.i_th (ln + 1) or Result > 0
				loop
					if lay_line.i_th (i) = ln and then not lay_break.i_th (i)
						and then lay_adv.i_th (i) > 0.0
						and then a_dx >= lay_x.i_th (i) and then a_dx < lay_x.i_th (i) + lay_adv.i_th (i)
					then
						Result := i
					end
					i := i + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= count
			on_a_painted_slot: Result > 0 implies (not is_break (Result) and width_of (Result) > 0.0)
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

	lay_out (a_p: SW_PAINTER; a_text: READABLE_STRING_32; a_wrap: REAL_64; a_role: INTEGER;
			a_size: REAL_64; a_bold, a_single_line, a_hidden: BOOLEAN): REAL_64
			-- Lay `a_text' out by the engine the painter offers - the shaping
			-- kit (unless `a_hidden') or cairo's toy advances - at `a_size'
			-- (nominal, before `text_scale') in `a_role''s face (0: the kit's
			-- own policy on the shaped path, the body face on the toy one),
			-- wrapping at `a_wrap' unless `a_single_line'; the height it
			-- takes, never less than one line of the face, so an empty text
			-- stands as tall as the first character typed into it will make
			-- it. The alignment and styles set before apply. The one engine
			-- switch every geometry host shares.
		require
			wrap_non_negative: a_wrap >= 0.0
			size_positive: a_size > 0.0
			role_known: a_role = 0 or a_role = {SW_PAINTER}.Role_ui or a_role = {SW_PAINTER}.Role_body
				or a_role = {SW_PAINTER}.Role_mono
		local
			px, wpx: INTEGER
		do
			px := (a_size * a_p.theme.text_scale).rounded.max (1)
			if a_p.has_shaping and then not a_hidden and then attached a_p.shaping as al_kit then
				if attached own_faces as al_faces then
					set_fonts (al_faces)
				elseif a_role > 0 then
					set_fonts (al_kit.fonts_for_role (a_role, px, a_bold))
				else
					set_fonts (Void)
				end
				if not a_single_line then
					wpx := a_wrap.floor.max (16)
				end
				build_shaped (al_kit, a_text, wpx, px, a_single_line)
				Result := content_height.max (floor_line_height (al_kit, px))
			else
				a_p.font (if a_role > 0 then a_role else {SW_PAINTER}.Role_body end, a_size, a_bold)
				build_toy (a_p, a_text, a_wrap, a_single_line, a_hidden)
				Result := content_height.max (a_p.text_extent)
			end
		ensure
			one_slot_per_char: count = a_text.count
			at_least_a_line: Result > 0.0
		end

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
			toy_role := a_p.font_role
			toy_size := a_p.font_size
			toy_bold := a_p.font_bold
			tab_width := (tab_spaces * a_p.advance (" ")).max (1.0)
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
				elseif a_text.item (i) = '%T' and then not a_hidden then
						-- a tab spans to the next stop from the line's start
					add_slot (cx, next_tab_stop (cx) - cx, line, False, False)
					cx := cx + lay_adv.last
					i := i + 1
				elseif a_text.item (i) = ' ' and then not a_hidden then
					add_slot (cx, a_p.advance (" "), line, False, False)
					cx := cx + lay_adv.last
					i := i + 1
				else
					from
						j := i
					until
						j >= n or else (not a_hidden and then (a_text.item (j + 1) = ' ' or else a_text.item (j + 1) = '%N' or else a_text.item (j + 1) = '%T'))
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
				line_offset.extend (0.0)
				i := i + 1
			end
			index_all_lines
		ensure
			one_slot_per_char: count = a_text.count
			toy: not is_shaped
			lines_measured: line_count >= 1
		end

	build_shaped (a_kit: SW_SHAPING; a_text: READABLE_STRING_32; a_wrap_px, a_px: INTEGER;
			a_single_line: BOOLEAN)
			-- One slot per character from the shaping kit: one layout per
			-- LF piece, the runs of every line walked in visual order and
			-- each character's edges from the cluster arithmetic. When the
			-- build before stands for a text this one differs from in a
			-- few pieces, only those are laid out again (`is_patched':
			-- COST OF A BUILD in the class note).
		require
			size_positive: a_px > 0
			wrap_non_negative: a_wrap_px >= 0
		do
			is_patched := False
			if is_patchable (a_kit, a_wrap_px, a_px, a_single_line) then
				patch_shaped (a_kit, a_text, a_wrap_px, a_px)
			end
			if not is_patched then
				build_whole (a_kit, a_text, a_wrap_px, a_px, a_single_line)
			end
			is_patch_base := is_line_ordered and then not has_stand_in_line and then not a_single_line
				and then not is_aligned and then is_keeping and then a_text.count >= Patch_floor
			built_text.wipe_out
			if is_patch_base then
				built_text.append (a_text)
				built_wrap_px := a_wrap_px
				built_tab_spaces := tab_spaces
			end
		ensure
			one_slot_per_char: count = a_text.count
			shaped: is_shaped
			lines_measured: line_count >= 1
			a_layout_per_piece: layouts.count = para_tops.count
			tallest_measured: tallest_line >= 0.0
		end

feature {NONE} -- Building: shaped

	Patch_floor: INTEGER = 1024
			-- The shortest text a build is patched for. Under it a whole
			-- build is cheap (at the rate measured on 2026-11-10, 211
			-- milliseconds for 388,893 characters, about half a
			-- millisecond), and the build keeps no copy of the text.

	Patch_limit: INTEGER = 4096
			-- How many builds in a row are patched before one is done
			-- whole: it bounds what `para_tops' can drift by (COST OF A
			-- BUILD in the class note).

	Kept_slack: INTEGER = 256
			-- How many kept layouts beyond two per layout in use a patch
			-- lets pile up before a whole build clears them out.

	Scan_block: INTEGER = 1024
			-- How many characters `shared_head' and `shared_tail' compare
			-- at a time.

	is_patch_base: BOOLEAN
			-- Can the next shaped build patch this one? A shaped build of
			-- many lines, flush left, without styles, whose slots stand in
			-- line order, of a text `Patch_floor' long at least.

	is_line_ordered: BOOLEAN
			-- Does no slot stand on an earlier line than the slot before
			-- it? (Always, but for a character no layout line covers,
			-- which stays on line 0.) A patch counts on it: the slots
			-- after a line break are on the lines after it.

	has_stand_in_line: BOOLEAN
			-- Did the build give the text a line of its own making,
			-- because the layouts gave none?

	built_text: STRING_32
			-- The text the build stands for, while `is_patch_base'.

	built_wrap_px, built_tab_spaces: INTEGER
			-- What `built_text' was laid out under, besides the terms the
			-- kept layouts note (`is_made_under').

	patch_count: INTEGER
			-- Builds patched since the last whole one.

	real_blocks: SW_LIST_BLOCKS [REAL_64]
	integer_blocks: SW_LIST_BLOCKS [INTEGER]
	boolean_blocks: SW_LIST_BLOCKS [BOOLEAN]
	layout_blocks: SW_LIST_BLOCKS [SHAPED_LAYOUT]
			-- Block edits on the slot, line and layout lists.

	is_patchable (a_kit: SW_SHAPING; a_wrap_px, a_px: INTEGER; a_single_line: BOOLEAN): BOOLEAN
			-- Would a build under these terms place every unchanged piece
			-- as the build before did?
		do
			Result := is_patch_base and then is_shaped and then not a_single_line
				and then a_wrap_px = built_wrap_px and then tab_spaces = built_tab_spaces
				and then not is_aligned
				and then not (attached styles as al_styles and then not al_styles.is_empty)
				and then is_made_under (a_kit, a_px)
				and then patch_count < Patch_limit
				and then kept_wrapped.count + kept_unwrapped.count <= 2 * layouts.count + Kept_slack
		ensure
			only_over_a_base: Result implies is_patch_base and is_shaped
		end

	build_whole (a_kit: SW_SHAPING; a_text: READABLE_STRING_32; a_wrap_px, a_px: INTEGER;
			a_single_line: BOOLEAN)
			-- Every piece of `a_text', from nothing.
		require
			size_positive: a_px > 0
			wrap_non_negative: a_wrap_px >= 0
		do
			reset
			begin_keeping (a_kit, a_px)
			is_shaped := True
			tab_width := (tab_spaces * shaped_space_width (a_kit, a_px)).max (1.0)
			replace_slots (0, 0, a_text.count)
			build_paragraphs (a_kit, a_text, a_wrap_px, a_px, a_single_line, 1, a_text.count + 1, 0, 0.0)
			if line_top.is_empty then
				line_top.extend (0.0)
				line_ascent.extend (a_px)
				line_height.extend (a_px * 1.4)
				line_offset.extend (0.0)
				has_stand_in_line := True
			end
			measure_tallest_line
			index_all_lines
			end_keeping (a_kit, a_px)
		ensure
			one_slot_per_char: count = a_text.count
			shaped: is_shaped
			lines_measured: line_count >= 1
			not_a_patch: not is_patched and patch_count = 0
		end

	build_paragraphs (a_kit: SW_SHAPING; a_text: READABLE_STRING_32; a_wrap_px, a_px: INTEGER;
			a_single_line: BOOLEAN; a_first, a_stop, a_line: INTEGER; a_top: REAL_64)
			-- Lay out the LF pieces of `a_text' that start at `a_first' ..
			-- `a_stop', the first of them on visual line `a_line' with its
			-- top at `a_top'. Their slots (which stand blank already) are
			-- written where they are; their lines and layouts are added at
			-- the END of the line and layout lists, for the caller to
			-- leave there (a whole build) or move into place (a patch).
		require
			first_starts_a_piece: a_first >= 1 and a_first <= a_text.count + 1
			stop_valid: a_stop >= a_first and a_stop <= a_text.count + 1
			slots_stand: count = a_text.count
			line_non_negative: a_line >= 0
		local
			n, line, para_start, para_end, k, r, c, src, slot, pending_break, next_tab: INTEGER
			lay: SHAPED_LAYOUT
			ln: SHAPED_LINE
			rn: SHAPED_RUN
			top, run_left, cl, cr, l_height, off: REAL_64
		do
			n := a_text.count
			line := a_line
			top := a_top
			from
				para_start := a_first
			until
				para_start > a_stop
			loop
				para_end := para_start
				from
				until
					para_end > n or else (a_text.item (para_end) = '%N' and not a_single_line)
				loop
					para_end := para_end + 1
				end
				if next_tab < para_start then
						-- the next tab from this piece on, looked for once and
						-- kept until a piece passes it (asked of every piece, a
						-- text with no tab ahead was scanned to its end each time)
					next_tab := a_text.index_of ('%T', para_start)
					if next_tab = 0 then
						next_tab := n + 2
					end
				end
				if next_tab < para_end then
						-- a tab in this piece: segments, each at its pen position
					build_tabbed_paragraph (a_kit, a_text, para_start, para_end, a_wrap_px, a_px, top, line)
					top := tab_next_top
					line := tab_next_line
					pending_break := 0
				else
					lay := layout_piece (a_kit, a_text, para_start, para_end - 1, a_wrap_px, a_px)
					layouts.extend (lay)
					para_tops.extend (top)
					para_lefts.extend (0.0)
					para_starts.extend (para_start)
					from
						k := 1
					until
						k > lay.lines.count
					loop
						ln := lay.lines.i_th (k)
						l_height := ln.height
						if para_end = para_start then
								-- an EMPTY piece (a blank line, or empty text): the
								-- facade measures it at the bare pixel size and
								-- leaves the primary-face row to its consumer, so
								-- it gets that row here - a blank line is as tall
								-- as the lines around it, and N lines are N rows
							l_height := l_height.max (floor_line_height (a_kit, a_px))
						end
							-- GW-02: where this line starts in the box.
						if is_aligned then
							off := lay.line_offset (ln, box_width, alignment)
						else
							off := 0.0
						end
						line_top.extend (top)
						line_ascent.extend (ln.ascent)
						line_height.extend (l_height)
						line_offset.extend (off)
						if k = 1 and pending_break > 0 then
								-- the break that opened this paragraph stands at
								-- its reading start: the left of an LTR line, the
								-- right of an RTL one
							if lay.is_rtl then
								lay_x.put_i_th (off + ln.width, pending_break)
							else
								lay_x.put_i_th (off, pending_break)
							end
							pending_break := 0
						end
						from
							src := ln.source_start
						until
							src > ln.source_start + ln.source_count - 1
						loop
							slot := para_start + src - 1
							if slot >= 1 and slot <= n then
								lay_line.put_i_th (line, slot)
								lay_x.put_i_th (off + ln.width, slot)
							end
							src := src + 1
						end
						run_left := off
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
						top := top + l_height
						line := line + 1
						k := k + 1
					end
				end
				if para_end <= n then
					lay_x.put_i_th (0.0, para_end)
					lay_adv.put_i_th (0.0, para_end)
					lay_line.put_i_th (line, para_end)
					lay_rtl.put_i_th (False, para_end)
					lay_break.put_i_th (True, para_end)
					if is_aligned then
						pending_break := para_end
					end
				end
				para_start := para_end + 1
			end
		ensure
			slots_stand: count = a_text.count
			layouts_parallel: layouts.count = para_tops.count and para_starts.count = layouts.count
				and para_lefts.count = layouts.count
			lines_parallel: line_top.count = line_ascent.count and line_ascent.count = line_height.count
				and line_offset.count = line_height.count
		end

	patch_shaped (a_kit: SW_SHAPING; a_text: READABLE_STRING_32; a_wrap_px, a_px: INTEGER)
			-- Lay out again only the LF pieces in which `a_text' differs
			-- from `built_text', and move what stands after them along.
			-- `is_patched' says whether that was done: when it was not,
			-- nothing has changed and the build is to be done whole.
			--
			-- The pieces laid out again run from after line break `a' (the
			-- last one in the head the two texts share, 0: from the start)
			-- to line break `c_new' (the first one in the tail they share;
			-- none: to the end). A piece's slots depend on its own layout
			-- alone when nothing is aligned, so the pieces before stand as
			-- they are, and the ones after move by the change in length,
			-- in lines and in height.
		require
			patchable: is_patch_base and is_shaped
			text_noted: built_text.count = count
			size_positive: a_px > 0
			wrap_non_negative: a_wrap_px >= 0
		local
			n, m, d, p, s, a, c_new, c_old, l_stop, l_end_new, i: INTEGER
			l_lines_a, l_lines_c, l_layouts_a, l_layouts_c, l_tabs_a, l_tabs_c: INTEGER
			l_old_lines, l_old_layouts, l_old_tabs, l_new_lines, l_new_layouts, l_new_tabs: INTEGER
			l_dl, l_dk, l_first: INTEGER
			l_top, l_old_top, l_dt: REAL_64
			l_has_tail: BOOLEAN
		do
			n := a_text.count
			m := built_text.count
			d := n - m
			p := shared_head (a_text, m.min (n))
			if p = n and p = m then
					-- the same text: everything stands
				last_shaped_count := 0
				is_patched := True
			else
				s := shared_tail (a_text, m.min (n) - p)
				if p > 0 then
					a := a_text.last_index_of ('%N', p)
				end
				if s > 0 then
					c_new := a_text.index_of ('%N', n - s + 1)
				end
				l_has_tail := c_new > 0
				if l_has_tail then
					c_old := c_new - d
					l_stop := c_new
					l_end_new := c_new
					l_lines_c := lay_line.i_th (c_old)
					l_layouts_c := count_up_to (para_starts, c_old)
				else
					l_stop := n + 1
					l_end_new := n
					l_lines_c := line_top.count
					l_layouts_c := layouts.count
				end
				if a > 0 then
					l_lines_a := lay_line.i_th (a)
					l_layouts_a := count_up_to (para_starts, a)
				end
				l_tabs_a := count_up_to (tabbed_pieces, l_layouts_a)
				l_tabs_c := count_up_to (tabbed_pieces, l_layouts_c)
				if l_lines_a <= l_lines_c and then l_lines_c <= line_top.count
					and then l_layouts_a <= l_layouts_c
					and then (a = 0 or else l_lines_a >= 1)
					and then (not l_has_tail or else (l_lines_c >= 1 and l_lines_c < line_top.count))
					and then 2 * (l_stop - a) <= n
				then
					is_patch_base := False
					last_shaped_count := 0
					is_keeping := True
					l_old_lines := line_top.count
					l_old_layouts := layouts.count
					l_old_tabs := tabbed_pieces.count
					if l_lines_c < l_old_lines then
						l_old_top := line_top.i_th (l_lines_c + 1)
					end
						-- the pieces between, laid out at the end of the lists
					replace_slots (a, l_end_new - d - a, l_end_new - a)
					if l_lines_a > 0 then
						l_top := line_top.i_th (l_lines_a) + line_height.i_th (l_lines_a)
					end
					build_paragraphs (a_kit, a_text, a_wrap_px, a_px, False, a + 1, l_stop, l_lines_a, l_top)
					l_new_lines := line_top.count - l_old_lines
					l_new_layouts := layouts.count - l_old_layouts
					l_new_tabs := tabbed_pieces.count - l_old_tabs
					from
						i := 1
					until
						i > l_new_lines
					loop
						line_first.extend (1)
						line_last.extend (0)
						line_right.extend (0.0)
						i := i + 1
					end
						-- and moved to where the old ones stood
					real_blocks.move_end_in (line_top, l_lines_a, l_lines_c - l_lines_a, l_new_lines)
					real_blocks.move_end_in (line_ascent, l_lines_a, l_lines_c - l_lines_a, l_new_lines)
					real_blocks.move_end_in (line_height, l_lines_a, l_lines_c - l_lines_a, l_new_lines)
					real_blocks.move_end_in (line_offset, l_lines_a, l_lines_c - l_lines_a, l_new_lines)
					integer_blocks.move_end_in (line_first, l_lines_a, l_lines_c - l_lines_a, l_new_lines)
					integer_blocks.move_end_in (line_last, l_lines_a, l_lines_c - l_lines_a, l_new_lines)
					real_blocks.move_end_in (line_right, l_lines_a, l_lines_c - l_lines_a, l_new_lines)
					layout_blocks.move_end_in (layouts, l_layouts_a, l_layouts_c - l_layouts_a, l_new_layouts)
					real_blocks.move_end_in (para_tops, l_layouts_a, l_layouts_c - l_layouts_a, l_new_layouts)
					real_blocks.move_end_in (para_lefts, l_layouts_a, l_layouts_c - l_layouts_a, l_new_layouts)
					integer_blocks.move_end_in (para_starts, l_layouts_a, l_layouts_c - l_layouts_a, l_new_layouts)
						-- (a tabbed piece is noted by its layout's place, which
						-- was at the end of the list when it was noted)
					from
						i := l_old_tabs + 1
					until
						i > tabbed_pieces.count
					loop
						tabbed_pieces.put_i_th (tabbed_pieces.i_th (i) - (l_old_layouts - l_layouts_a), i)
						i := i + 1
					end
					integer_blocks.move_end_in (tabbed_pieces, l_tabs_a, l_tabs_c - l_tabs_a, l_new_tabs)
						-- what stands after them moves along
					l_dl := l_lines_a + l_new_lines - l_lines_c
					l_dk := l_layouts_a + l_new_layouts - l_layouts_c
					l_first := l_lines_a + l_new_lines + 1
					if l_first <= line_top.count then
						if l_first > 1 then
							l_top := line_top.i_th (l_first - 1) + line_height.i_th (l_first - 1)
						else
							l_top := 0.0
						end
						l_dt := l_top - l_old_top
						if l_dt /= 0.0 then
								-- the tops summed again as a whole build sums
								-- them, so they come out the same to the bit
							from
								i := l_first
							until
								i > line_top.count
							loop
								line_top.put_i_th (l_top, i)
								l_top := l_top + line_height.i_th (i)
								i := i + 1
							end
							from
								i := l_layouts_a + l_new_layouts + 1
							until
								i > para_tops.count
							loop
								para_tops.put_i_th (para_tops.i_th (i) + l_dt, i)
								i := i + 1
							end
						end
					end
					if d /= 0 then
						from
							i := l_layouts_a + l_new_layouts + 1
						until
							i > para_starts.count
						loop
							para_starts.put_i_th (para_starts.i_th (i) + d, i)
							i := i + 1
						end
						from
							i := l_first
						until
							i > line_last.count
						loop
							if line_last.i_th (i) > 0 then
								line_first.put_i_th (line_first.i_th (i) + d, i)
								line_last.put_i_th (line_last.i_th (i) + d, i)
							end
							i := i + 1
						end
					end
					if l_dk /= 0 then
						from
							i := l_tabs_a + l_new_tabs + 1
						until
							i > tabbed_pieces.count
						loop
							tabbed_pieces.put_i_th (tabbed_pieces.i_th (i) + l_dk, i)
							i := i + 1
						end
					end
					if l_dl /= 0 then
							-- (the line break at `c_new' was written with its
							-- line as it is now)
						from
							i := l_end_new + 1
						until
							i > n
						loop
							lay_line.put_i_th (lay_line.i_th (i) + l_dl, i)
							i := i + 1
						end
					end
					index_lines (a.max (1), (l_end_new + 1).min (n))
					measure_tallest_line
					measure_rightmost_edge
					end_keeping (a_kit, a_px)
					patch_count := patch_count + 1
					is_patched := not line_top.is_empty
				end
			end
		ensure
			one_slot_per_char: is_patched implies count = a_text.count
			untouched_otherwise: not is_patched implies count = old count
		end

	replace_slots (a_after, a_removed, a_inserted: INTEGER)
			-- Put `a_inserted' blank slots in the place of the `a_removed'
			-- slots after slot `a_after'.
		require
			after_valid: a_after >= 0
			removed_valid: a_removed >= 0 and a_after + a_removed <= count
			inserted_non_negative: a_inserted >= 0
		do
			real_blocks.splice (lay_x, a_after, a_removed, a_inserted, 0.0)
			real_blocks.splice (lay_adv, a_after, a_removed, a_inserted, 0.0)
			integer_blocks.splice (lay_line, a_after, a_removed, a_inserted, 0)
			boolean_blocks.splice (lay_rtl, a_after, a_removed, a_inserted, False)
			boolean_blocks.splice (lay_break, a_after, a_removed, a_inserted, False)
		ensure
			count_follows: count = old count - a_removed + a_inserted
		end

	shared_head (a_text: READABLE_STRING_32; a_limit: INTEGER): INTEGER
			-- How many characters `a_text' and `built_text' start with
			-- alike, `a_limit' at most.
		require
			limit_valid: a_limit >= 0 and a_limit <= a_text.count and a_limit <= built_text.count
		do
			from
			until
				Result + Scan_block > a_limit
					or else not a_text.same_characters (built_text, Result + 1, Result + Scan_block, Result + 1)
			loop
				Result := Result + Scan_block
			end
			from
			until
				Result >= a_limit or else a_text.item (Result + 1) /= built_text.item (Result + 1)
			loop
				Result := Result + 1
			end
		ensure
			within_limit: Result >= 0 and Result <= a_limit
		end

	shared_tail (a_text: READABLE_STRING_32; a_limit: INTEGER): INTEGER
			-- How many characters `a_text' and `built_text' end with
			-- alike, `a_limit' at most.
		require
			limit_valid: a_limit >= 0 and a_limit <= a_text.count and a_limit <= built_text.count
		local
			n, m: INTEGER
		do
			n := a_text.count
			m := built_text.count
			from
			until
				Result + Scan_block > a_limit
					or else not a_text.same_characters (built_text, m - Result - Scan_block + 1, m - Result,
						n - Result - Scan_block + 1)
			loop
				Result := Result + Scan_block
			end
			from
			until
				Result >= a_limit or else a_text.item (n - Result) /= built_text.item (m - Result)
			loop
				Result := Result + 1
			end
		ensure
			within_limit: Result >= 0 and Result <= a_limit
		end

	count_up_to (a_list: ARRAYED_LIST [INTEGER]; a_value: INTEGER): INTEGER
			-- How many items of `a_list', which ascends, are `a_value' or
			-- less. A binary search.
		local
			l_low, l_high, l_mid: INTEGER
		do
			from
				l_low := 0
				l_high := a_list.count + 1
			until
				l_high - l_low <= 1
			loop
				l_mid := l_low + (l_high - l_low) // 2
				if a_list.i_th (l_mid) <= a_value then
					l_low := l_mid
				else
					l_high := l_mid
				end
			end
			Result := l_low
		ensure
			within_the_list: Result >= 0 and Result <= a_list.count
		end

	measure_tallest_line
			-- Take `tallest_line' from the lines' heights.
		do
			tallest_line := 0.0
			across
				line_height as ic_h
			loop
				tallest_line := tallest_line.max (ic_h)
			end
		ensure
			non_negative: tallest_line >= 0.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER; a_text: READABLE_STRING_32; a_hidden: BOOLEAN; a_ox, a_oy: REAL_64)
			-- `a_text' (the text this geometry was built from) with its
			-- origin at (`a_ox', `a_oy'), in the painter's current color:
			-- on the shaped path its layouts, each line placed by the
			-- alignment; on the toy path every character at its slot in the
			-- body face, a bullet each when `a_hidden', line breaks drawing
			-- nothing. The one drawing loop every geometry host shares.
			-- Only what the painter's clip can show is painted
			-- (`last_drawn_count'): see COST OF A DRAW in the class note.
			-- Held to a line (`hold_draw_to_line'), only what stands on it.
		require
			built_from_it: a_text.count = count
		local
			k, ln, l_last: INTEGER
			l_band: TUPLE [top, bottom: REAL_64]
			l_to, l_top, l_height: REAL_64
			l_held: BOOLEAN
		do
			last_drawn_count := 0
			l_band := a_p.clip_band
			l_held := is_holding
			if is_shaped then
				l_to := l_band.bottom - a_oy + draw_margin
				k := first_layout_near (l_band.top - a_oy - draw_margin)
				l_last := layouts.count
				if l_held then
					k := k.max (first_held_layout)
					l_last := last_held_layout
				end
				from
				until
					k > l_last or else para_tops.i_th (k) > l_to
				loop
					if para_lefts.i_th (k) > 0.0 or else is_tabbed_piece (k) then
							-- a segment of a tabbed paragraph: flush left at its pen
						a_p.draw_shaped_layout (layouts.i_th (k), a_ox + para_lefts.i_th (k), a_oy + para_tops.i_th (k))
					elseif is_aligned then
						a_p.draw_shaped_layout_aligned (layouts.i_th (k), a_ox, a_oy + para_tops.i_th (k),
							box_width, alignment)
					else
						a_p.draw_shaped_layout (layouts.i_th (k), a_ox, a_oy + para_tops.i_th (k))
					end
					last_drawn_count := last_drawn_count + 1
					k := k + 1
				end
			else
				if toy_role > 0 and toy_size > 0.0 then
					a_p.font (toy_role, toy_size, toy_bold)
				else
					a_p.font ({SW_PAINTER}.Role_body, a_p.theme.size_body, False)
				end
				k := 1
				l_last := count
				if l_held then
					k := first_held_slot
					l_last := last_held_slot
				end
				from
				until
					k > l_last
				loop
					if not is_break (k) and then not (not a_hidden and then a_text.item (k) = '%T')
						and then (not l_held or else line_of (k) = held_line)
					then
						ln := line_of (k)
						l_top := a_oy + top_of_line (ln)
						l_height := height_of_line (ln)
						if l_top + 2.0 * l_height >= l_band.top and then l_top - l_height <= l_band.bottom then
								-- its line, or a neighbor of it, is inside the clip
							a_p.text (a_ox + x_of (k), l_top + ascent_of_line (ln),
								glyph_of (a_text, k, a_hidden))
							last_drawn_count := last_drawn_count + 1
						end
					end
					k := k + 1
				end
			end
		ensure
			no_more_than_there_is: last_drawn_count <= layouts.count.max (count)
		end

	draw_hooked (a_p: SW_PAINTER; a_ox, a_oy: REAL_64;
			a_before_run: PROCEDURE [INTEGER, SHAPED_RUN, REAL_64, REAL_64])
			-- The shaped layouts with their origin at (`a_ox', `a_oy'),
			-- calling `a_before_run' with the run's first character AS AN
			-- INDEX OF THE WHOLE TEXT (a run counts from its own LF piece;
			-- this adds the piece's start), the run, its pen x and its
			-- baseline, before painting it - where a host colors a link
			-- and underlines it (GW-13). Shaped path only. Like `draw', it
			-- paints (and calls `a_before_run' for) only what the
			-- painter's clip can show, and held to a line
			-- (`hold_draw_to_line') only what stands on it.
		require
			shaped: is_shaped
			painter_shapes: a_p.has_shaping
		local
			k, l_last: INTEGER
			l_band: TUPLE [top, bottom: REAL_64]
			l_to: REAL_64
		do
			last_drawn_count := 0
			l_band := a_p.clip_band
			l_to := l_band.bottom - a_oy + draw_margin
			k := first_layout_near (l_band.top - a_oy - draw_margin)
			l_last := layouts.count
			if is_holding then
				k := k.max (first_held_layout)
				l_last := last_held_layout
			end
			from
			until
				k > l_last or else para_tops.i_th (k) > l_to
			loop
				a_p.draw_shaped_layout_hooked (layouts.i_th (k), a_ox + para_lefts.i_th (k), a_oy + para_tops.i_th (k),
					box_width, if is_tabbed_piece (k) then {SHAPING_CONSTANTS}.Align_left else alignment end, agent forward_run (para_starts.i_th (k), a_before_run, ?, ?, ?))
				last_drawn_count := last_drawn_count + 1
				k := k + 1
			end
		ensure
			no_more_than_there_is: last_drawn_count <= layouts.count
		end

	held_line: INTEGER
			-- The visual line `draw' and `draw_hooked' are held to, or
			-- -1: they then paint every line the painter's clip can show.

	hold_draw_to_line (a_line: INTEGER)
			-- Have `draw' and `draw_hooked' paint only what stands on
			-- visual line `a_line': on the shaped path the layouts with a
			-- character on it, on the toy path its characters. For a
			-- caller that draws one line again under a clip of that line
			-- (SW_MARK_PAINTER, once per colored span): the clip alone
			-- lets the neighbor lines' layouts through (`draw_margin'),
			-- five or six for every one wanted. `release_draw' ends it.
		require
			in_lines: a_line >= 0 and a_line < line_count
		do
			held_line := a_line
		ensure
			held: held_line = a_line
		end

	release_draw
			-- Have `draw' and `draw_hooked' paint every line the clip can
			-- show again.
		do
			held_line := -1
		ensure
			released: held_line = -1
		end

feature {NONE} -- Tabbed paragraphs

	tab_next_top: REAL_64
			-- Where the line after the last `build_tabbed_paragraph' starts.

	tab_next_line: INTEGER
			-- The index of the line after the last `build_tabbed_paragraph'.

	tabbed_pieces: ARRAYED_LIST [INTEGER]
			-- The layouts (indices) that are segments of a tabbed paragraph.

	is_tabbed_piece (a_k: INTEGER): BOOLEAN
			-- Is layout `a_k' a segment of a tabbed paragraph? A binary
			-- search (`tabbed_pieces' ascends): `draw' asks for every
			-- layout it paints, and in code most lines hold a tab.
		local
			l_low, l_high, l_mid, l_item: INTEGER
		do
			from
				l_low := 1
				l_high := tabbed_pieces.count
			until
				Result or else l_low > l_high
			loop
				l_mid := l_low + (l_high - l_low) // 2
				l_item := tabbed_pieces.i_th (l_mid)
				if l_item = a_k then
					Result := True
				elseif l_item < a_k then
					l_low := l_mid + 1
				else
					l_high := l_mid - 1
				end
			end
		end

	shaped_space_width (a_kit: SW_SHAPING; a_px: INTEGER): REAL_64
			-- The width of one blank in the face this build shapes in,
			-- measured as the difference of "a a" and "aa" so no
			-- trailing-blank trimming can read it as zero.
		do
			if attached fonts as al_fonts then
				Result := a_kit.facade.layout ("a a", 0, a_px, al_fonts).total_width
					- a_kit.facade.layout ("aa", 0, a_px, al_fonts).total_width
			else
				Result := a_kit.layout_for ("a a", 0, a_px).total_width
					- a_kit.layout_for ("aa", 0, a_px).total_width
			end
			if Result <= 0.0 then
				Result := a_px * 0.3
			end
		ensure
			positive: Result > 0.0
		end

	layout_piece (a_kit: SW_SHAPING; a_text: READABLE_STRING_32; a_from, a_to, a_wrap_px, a_px: INTEGER): SHAPED_LAYOUT
			-- Characters `a_from' .. `a_to' of `a_text' in the host's fonts
			-- and styles (numbered from the piece's start): the layout an
			-- equal piece of this build or of the one before was given,
			-- or else a new one from the kit (`last_shaped_count').
		require
			range_valid: a_from >= 1 and a_to >= a_from - 1 and a_to <= a_text.count
		local
			l_piece: STRING_32
			l_kept, l_previous: like kept_wrapped
		do
			l_piece := a_text.substring (a_from, a_to).to_string_32
			if is_keeping then
				if a_wrap_px > 0 then
					l_kept := kept_wrapped
					l_previous := previous_wrapped
				else
					l_kept := kept_unwrapped
					l_previous := previous_unwrapped
				end
				if attached l_kept.item (l_piece) as al_seen and then al_seen.width_pixels = a_wrap_px then
					Result := al_seen
				elseif attached l_previous.item (l_piece) as al_before and then al_before.width_pixels = a_wrap_px then
					Result := al_before
					l_kept.force (Result, l_piece)
				else
					Result := shaped_piece (a_kit, l_piece, a_from, a_wrap_px, a_px)
					last_shaped_count := last_shaped_count + 1
					l_kept.force (Result, l_piece)
				end
			else
				Result := shaped_piece (a_kit, l_piece, a_from, a_wrap_px, a_px)
				last_shaped_count := last_shaped_count + 1
			end
		ensure
			as_asked: Result.width_pixels = a_wrap_px and Result.pixel_size = a_px
		end

	shaped_piece (a_kit: SW_SHAPING; a_piece: STRING_32; a_from, a_wrap_px, a_px: INTEGER): SHAPED_LAYOUT
			-- `a_piece' (the text being built from character `a_from' on)
			-- through the kit, in the host's fonts and styles.
		require
			from_valid: a_from >= 1
		do
			if attached fonts as al_fonts then
					-- GW-13: the host's policy, styled or not (no spans
					-- is the plain layout itself).
				if attached styles as al_fonts_styles then
					Result := a_kit.facade.layout_styled (a_piece, a_wrap_px, a_px, al_fonts,
						al_fonts_styles.slice (a_from, a_piece.count))
				else
					Result := a_kit.facade.layout (a_piece, a_wrap_px, a_px, al_fonts)
				end
			elseif attached styles as al_styles and then not al_styles.is_empty then
					-- GW-08: this piece's spans, numbered from its start.
				Result := a_kit.layout_with_styles (a_piece, a_wrap_px, a_px, al_styles.slice (a_from, a_piece.count))
			else
				Result := a_kit.layout_for (a_piece, a_wrap_px, a_px)
			end
		end

	kept_wrapped, kept_unwrapped: HASH_TABLE [SHAPED_LAYOUT, STRING_32]
			-- The layouts of the last shaped build (of the one under way,
			-- while it runs) by piece text: the pieces laid out at the
			-- build's wrap width, and the unwrapped ones (the segments of
			-- tabbed lines, every piece of an unwrapped build). A layout
			-- is immutable, so equal pieces share one.

	previous_wrapped, previous_unwrapped: HASH_TABLE [SHAPED_LAYOUT, STRING_32]
			-- Those of the build before, while a build runs and may take
			-- from them; empty between builds.

	kept_kit: detachable SW_SHAPING
	kept_fonts: detachable FONT_LIST
	kept_px, kept_font_revision, kept_policy_revision: INTEGER
			-- What the kept layouts were made under.

	is_keeping: BOOLEAN
			-- Does the build under way keep its layouts and take from the
			-- build before? Not under styles: a piece's spans depend on
			-- where it stands in the text.

	begin_keeping (a_kit: SW_SHAPING; a_px: INTEGER)
			-- Open a shaped build: what the last one kept becomes
			-- `previous_wrapped' and `previous_unwrapped' when it was made
			-- under this kit, these fonts, this size and the same policy,
			-- and is dropped otherwise.
		local
			l_swap: like kept_wrapped
		do
			last_shaped_count := 0
			is_keeping := not (attached styles as al_styles and then not al_styles.is_empty)
			if is_keeping and then is_made_under (a_kit, a_px) then
				l_swap := previous_wrapped
				previous_wrapped := kept_wrapped
				kept_wrapped := l_swap
				l_swap := previous_unwrapped
				previous_unwrapped := kept_unwrapped
				kept_unwrapped := l_swap
			end
			kept_wrapped.wipe_out
			kept_unwrapped.wipe_out
		ensure
			none_counted: last_shaped_count = 0
			kept_empty: kept_wrapped.is_empty and kept_unwrapped.is_empty
		end

	is_made_under (a_kit: SW_SHAPING; a_px: INTEGER): BOOLEAN
			-- Were the kept layouts made under this kit, these fonts, this
			-- size and the policy as it stands?
		do
			Result := kept_kit = a_kit and then kept_fonts = fonts and then kept_px = a_px
				and then kept_font_revision = a_kit.font_revision
				and then kept_policy_revision = a_kit.facade.policy_revision
		end

	end_keeping (a_kit: SW_SHAPING; a_px: INTEGER)
			-- Close a shaped build: note what its layouts were made under,
			-- and let go of the build before.
		do
			previous_wrapped.wipe_out
			previous_unwrapped.wipe_out
			kept_kit := a_kit
			kept_fonts := fonts
			kept_px := a_px
			kept_font_revision := a_kit.font_revision
			kept_policy_revision := a_kit.facade.policy_revision
		ensure
			previous_let_go: previous_wrapped.is_empty and previous_unwrapped.is_empty
		end

	build_tabbed_paragraph (a_kit: SW_SHAPING; a_text: READABLE_STRING_32; a_start, a_end, a_wrap_px, a_px: INTEGER;
			a_top: REAL_64; a_line: INTEGER)
			-- Characters `a_start' .. `a_end' - 1 (one LF piece holding a
			-- tab) laid out as one unwrapped layout per tab-free segment,
			-- each at its pen position; a tab's slot spans to the next stop.
			-- A segment that would cross `a_wrap_px' (when above 0) starts
			-- the next visual line instead. Sets `tab_next_top' and
			-- `tab_next_line'.
		require
			range_valid: a_start >= 1 and a_end > a_start and a_end <= a_text.count + 1
			has_a_tab: a_text.index_of ('%T', a_start) < a_end and a_text.index_of ('%T', a_start) > 0
		local
			pos, e, r, c, src, slot, first_layout, line: INTEGER
			lay: SHAPED_LAYOUT
			ln: SHAPED_LINE
			rn: SHAPED_RUN
			cx, top, run_left, cl, cr, line_asc, line_h, seg_w: REAL_64
			asc_list: ARRAYED_LIST [REAL_64]
		do
			create asc_list.make (4)
			line := a_line
			top := a_top
			first_layout := layouts.count + 1
			line_h := floor_line_height (a_kit, a_px)
			line_asc := 0.0
			cx := 0.0
			from
				pos := a_start
			until
				pos > a_end
			loop
				e := a_text.index_of ('%T', pos)
				if e = 0 or else e >= a_end then
					e := a_end
				end
				if e > pos then
					lay := layout_piece (a_kit, a_text, pos, e - 1, 0, a_px)
					if not lay.lines.is_empty then
						ln := lay.lines.first
						seg_w := ln.width
						if a_wrap_px > 0 and then cx > 0.0 and then cx + seg_w > a_wrap_px then
							close_tabbed_line (top, line_asc, line_h, first_layout, asc_list)
							top := top + line_h
							line := line + 1
							cx := 0.0
							line_asc := 0.0
							line_h := floor_line_height (a_kit, a_px)
							first_layout := layouts.count + 1
							asc_list.wipe_out
						end
						line_asc := line_asc.max (ln.ascent)
						line_h := line_h.max (ln.height)
						layouts.extend (lay)
						para_tops.extend (top)
						para_lefts.extend (cx)
						para_starts.extend (pos)
						tabbed_pieces.extend (layouts.count)
						asc_list.extend (ln.ascent)
						from
							src := ln.source_start
						until
							src > ln.source_start + ln.source_count - 1
						loop
							slot := pos + src - 1
							if slot >= 1 and slot < e then
								lay_line.put_i_th (line, slot)
								lay_x.put_i_th (cx + ln.width, slot)
							end
							src := src + 1
						end
						run_left := cx
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
								slot := pos + rn.source_start + c - 2
								if slot >= 1 and slot < e then
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
						cx := cx + seg_w
					end
				end
				if e < a_end then
					lay_x.put_i_th (cx, e)
					lay_adv.put_i_th (next_tab_stop (cx) - cx, e)
					lay_line.put_i_th (line, e)
					lay_rtl.put_i_th (False, e)
					cx := next_tab_stop (cx)
				end
				pos := e + 1
			end
			close_tabbed_line (top, line_asc, line_h, first_layout, asc_list)
			tab_next_top := top + line_h
			tab_next_line := line + 1
		ensure
			one_more_line_at_least: tab_next_line > a_line
			below: tab_next_top > a_top
		end

	close_tabbed_line (a_top, a_ascent, a_height: REAL_64; a_first_layout: INTEGER; a_ascents: ARRAYED_LIST [REAL_64])
			-- Record the visual line just filled, and drop each of its
			-- segments so their baselines meet.
		local
			k: INTEGER
			l_asc: REAL_64
		do
			l_asc := a_ascent
			if l_asc <= 0.0 and then not a_ascents.is_empty then
				l_asc := a_ascents.first
			end
			line_top.extend (a_top)
			line_ascent.extend (l_asc)
			line_height.extend (a_height)
			line_offset.extend (0.0)
			from
				k := 1
			until
				k > a_ascents.count
			loop
				para_tops.put_i_th (a_top + l_asc - a_ascents.i_th (k), a_first_layout + k - 1)
				k := k + 1
			end
		end

feature {NONE} -- Implementation

	para_starts: ARRAYED_LIST [INTEGER]
			-- Per layout, its piece's first character in the whole text.

	forward_run (a_piece_start: INTEGER; a_hook: PROCEDURE [INTEGER, SHAPED_RUN, REAL_64, REAL_64];
			a_run: SHAPED_RUN; a_pen, a_baseline: REAL_64)
			-- Hand `a_run' to `a_hook' with its first character counted
			-- from the start of the whole text.
		do
			a_hook.call (a_piece_start + a_run.source_start - 1, a_run, a_pen, a_baseline)
		end

	is_holding: BOOLEAN
			-- Is the draw held to a line there still is?
		do
			Result := held_line >= 0 and held_line < line_first.count
		end

	first_held_slot: INTEGER
			-- The first character on the held line, the line break that
			-- opens it apart; above `last_held_slot' when the line holds
			-- no character.
		require
			holding: is_holding
		do
			Result := line_first.i_th (held_line + 1)
			if Result <= line_last.i_th (held_line + 1) and then lay_break.i_th (Result) then
				Result := Result + 1
			end
		ensure
			at_least_the_first: Result >= 1
		end

	last_held_slot: INTEGER
			-- The last character on the held line.
		require
			holding: is_holding
		do
			Result := line_last.i_th (held_line + 1)
		ensure
			in_text: Result >= 0 and Result <= count
		end

	first_held_layout: INTEGER
			-- The first layout with a character on the held line (shaped
			-- path); above `last_held_layout' when the line holds none.
		require
			holding: is_holding
		local
			l_start: INTEGER
		do
			Result := count_up_to (para_starts, first_held_slot).max (1)
			if Result <= layouts.count and then layouts.i_th (Result).lines.count <= 1 then
					-- a layout of one line: on the held line, or all of it on a
					-- line before (the held line opens with a tab, which no
					-- layout holds, so the search found the layout before it)
				l_start := para_starts.i_th (Result)
				if l_start >= 1 and l_start <= count and then lay_line.i_th (l_start) /= held_line then
					Result := Result + 1
				end
			end
		ensure
			at_least_the_first: Result >= 1
		end

	last_held_layout: INTEGER
			-- The last layout with a character on the held line (shaped
			-- path), 0 when the line holds none.
		require
			holding: is_holding
		do
			if first_held_slot <= last_held_slot then
				Result := count_up_to (para_starts, last_held_slot)
			end
		ensure
			within_the_layouts: Result >= 0 and Result <= layouts.count
		end

	draw_margin: REAL_64
			-- How far outside the clip a layout is still painted: one
			-- tallest line for ink that overshoots its own line, one for
			-- the segments of a tabbed line, whose tops differ by up to
			-- the line's ascent.
		do
			Result := 2.0 * tallest_line + 2.0
		ensure
			positive: Result > 0.0
		end

	first_layout_near (a_y: REAL_64): INTEGER
			-- The layout to start painting from when nothing above `a_y'
			-- (measured from the text's top) can show: the last one whose
			-- top is above `a_y', or the first. A binary search: tops
			-- ascend from line to line (within one tabbed line they differ
			-- by less than `draw_margin' allows for).
		local
			l_low, l_high, l_mid: INTEGER
		do
			from
				l_low := 0
				l_high := layouts.count + 1
			until
				l_high - l_low <= 1
			loop
				l_mid := l_low + (l_high - l_low) // 2
				if para_tops.i_th (l_mid) < a_y then
					l_low := l_mid
				else
					l_high := l_mid
				end
			end
			Result := l_low.max (1)
		ensure
			at_least_the_first: Result >= 1
			no_further_than_the_last: Result <= layouts.count.max (1)
		end

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
			line_offset.wipe_out
			layouts.wipe_out
			para_tops.wipe_out
			para_lefts.wipe_out
			tabbed_pieces.wipe_out
			para_starts.wipe_out
			line_first.wipe_out
			line_last.wipe_out
			line_right.wipe_out
			tallest_line := 0.0
			rightmost_edge := 0.0
			is_patched := False
			is_patch_base := False
			is_line_ordered := False
			has_stand_in_line := False
			patch_count := 0
		ensure
			nothing_to_patch: not is_patch_base and not is_patched and patch_count = 0
		end

	line_offset: ARRAYED_LIST [REAL_64]
			-- Per visual line: where it starts in the box (GW-02).

	line_first, line_last: ARRAYED_LIST [INTEGER]
			-- Per visual line, the lowest and the highest slot standing on
			-- it (`line_last' 0: none - a first line left empty by a
			-- leading line break, an empty text). What the line queries
			-- read instead of the whole text.

	line_right: ARRAYED_LIST [REAL_64]
			-- Per visual line, the right edge of its rightmost character.

	index_all_lines
			-- Fill the per-line index from the slots as they stand.
		local
			i: INTEGER
		do
			line_first.wipe_out
			line_last.wipe_out
			line_right.wipe_out
			from
				i := 1
			until
				i > line_top.count
			loop
				line_first.extend (1)
				line_last.extend (0)
				line_right.extend (0.0)
				i := i + 1
			end
			is_line_ordered := True
			index_lines (1, count)
			measure_rightmost_edge
		ensure
			a_range_per_line: line_first.count = line_top.count
		end

	index_lines (a_from, a_to: INTEGER)
			-- Enter slots `a_from' .. `a_to' in the per-line index, and
			-- note in `is_line_ordered' a slot that stands on an earlier
			-- line than the slot before it.
		require
			range_valid: a_from >= 1 and a_to <= count
			sized: line_first.count = line_top.count and line_last.count = line_top.count
				and line_right.count = line_top.count
		local
			i, l_line: INTEGER
		do
			from
				i := a_from
			until
				i > a_to
			loop
				l_line := lay_line.i_th (i) + 1
				if i > 1 and then l_line <= lay_line.i_th (i - 1) then
					is_line_ordered := False
				end
				if l_line <= line_last.count then
					if line_last.i_th (l_line) = 0 then
						line_first.put_i_th (i, l_line)
						line_last.put_i_th (i, l_line)
					else
						line_first.put_i_th (line_first.i_th (l_line).min (i), l_line)
						line_last.put_i_th (line_last.i_th (l_line).max (i), l_line)
					end
					if not lay_break.i_th (i) then
						line_right.put_i_th (line_right.i_th (l_line).max (lay_x.i_th (i) + lay_adv.i_th (i)), l_line)
					end
				end
				i := i + 1
			end
		end

	measure_rightmost_edge
			-- Take `rightmost_edge' from the lines' right edges.
		do
			rightmost_edge := 0.0
			across
				line_right as ic_right
			loop
				rightmost_edge := rightmost_edge.max (ic_right)
			end
		ensure
			non_negative: rightmost_edge >= 0.0
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
	tab_stops_apart: tab_spaces >= 1
	slots_parallel: lay_x.count = lay_adv.count and lay_adv.count = lay_line.count
		and lay_line.count = lay_rtl.count and lay_rtl.count = lay_break.count
	lines_parallel: line_top.count = line_ascent.count and line_ascent.count = line_height.count
	offsets_parallel: line_offset.count = line_height.count
	line_index_parallel: line_first.count = line_top.count and line_last.count = line_top.count
		and line_right.count = line_top.count
	reach_non_negative: rightmost_edge >= 0.0
	layouts_parallel: layouts.count = para_tops.count and para_starts.count = layouts.count
		and para_lefts.count = layouts.count

end
