note
	description: "[
		Rows grouped into titled sections, laid out among the rows a list or a grid shows
		(simple_gui 1y-e). A section begins at a model row; rows before the first section
		have none. A section's header takes one slot, as tall as a row, directly above the
		first shown row of the section; a section with no shown row has no header. Headers
		are not rows: the shown rows keep their positions, and slots number the headers and
		the rows together from the top.

		While `is_sticky' the header of the section at the top of the visible slots is
		pinned there (`pinned_header'); the next header pushes it up as it arrives
		(`pinned_offset'), and it gives way exactly when that header reaches the top.

		SW_LIST and SW_DATA_GRID keep one each and lay it out again (`lay_out') when the
		sections or the shown rows change.
	]"

class
	SW_ROW_SECTIONS

create
	make

feature {NONE} -- Initialization

	make
			-- No sections; sticky.
		do
			create starts.make (0)
			create titles.make (0)
			create header_positions.make (0)
			create header_sections.make (0)
			create position_sections.make (0)
			is_sticky := True
		ensure
			none: count = 0
			nothing_laid_out: header_count = 0 and laid_out_count = 0
			sticky: is_sticky
		end

feature -- Access

	count: INTEGER
			-- How many sections.
		do
			Result := starts.count
		end

	first_row (i: INTEGER): INTEGER
			-- The model row section `i' begins at.
		require
			valid: 1 <= i and i <= count
		do
			Result := starts [i]
		ensure
			positive: Result >= 1
		end

	title (i: INTEGER): STRING_32
			-- Section `i''s title.
		require
			valid: 1 <= i and i <= count
		do
			Result := titles [i]
		end

	section_of (a_model: INTEGER): INTEGER
			-- The section model row `a_model' is in; 0 for a row before the first.
		local
			lo, hi, mid: INTEGER
		do
			from
				lo := 1
				hi := count
			until
				lo > hi
			loop
				mid := (lo + hi) // 2
				if starts [mid] <= a_model then
					Result := mid
					lo := mid + 1
				else
					hi := mid - 1
				end
			end
		ensure
			in_range: 0 <= Result and Result <= count
			begun: Result > 0 implies first_row (Result) <= a_model
			before_the_next: Result < count implies first_row (Result + 1) > a_model
		end

	is_sticky: BOOLEAN
			-- Is the header of the section at the top of the visible slots pinned there?

feature -- Layout (as last laid out)

	is_stale: BOOLEAN
			-- Have the sections changed since the last `lay_out'?

	laid_out_count: INTEGER
			-- How many shown rows the last `lay_out' covered.

	header_count: INTEGER
			-- How many headers show.
		do
			Result := header_positions.count
		ensure
			definition: Result = header_positions.count
		end

	header_section (k: INTEGER): INTEGER
			-- The section header `k' (from the top) belongs to.
		require
			valid: 1 <= k and k <= header_count
		do
			Result := header_sections [k]
		ensure
			a_section: 1 <= Result and Result <= count
		end

	header_position (k: INTEGER): INTEGER
			-- The shown position of the row header `k' stands above.
		require
			valid: 1 <= k and k <= header_count
		do
			Result := header_positions [k]
		ensure
			a_position: 1 <= Result and Result <= laid_out_count
		end

	header_slot (k: INTEGER): INTEGER
			-- The slot header `k' takes: after every row and header above it.
		require
			valid: 1 <= k and k <= header_count
		do
			Result := header_positions [k] + k - 1
		ensure
			definition: Result = header_position (k) + k - 1
		end

	slot_count: INTEGER
			-- The shown rows and the headers together.
		do
			Result := laid_out_count + header_count
		ensure
			definition: Result = laid_out_count + header_count
		end

	headers_through_position (a_pos: INTEGER): INTEGER
			-- How many headers stand above shown position `a_pos' or directly on it.
		local
			lo, hi, mid: INTEGER
		do
			from
				lo := 1
				hi := header_count
			until
				lo > hi
			loop
				mid := (lo + hi) // 2
				if header_positions [mid] <= a_pos then
					Result := mid
					lo := mid + 1
				else
					hi := mid - 1
				end
			end
		ensure
			in_range: 0 <= Result and Result <= header_count
		end

	headers_through_slot (a_slot: INTEGER): INTEGER
			-- How many headers take slot `a_slot' or one above it.
		local
			lo, hi, mid: INTEGER
		do
			from
				lo := 1
				hi := header_count
			until
				lo > hi
			loop
				mid := (lo + hi) // 2
				if header_positions [mid] + mid - 1 <= a_slot then
					Result := mid
					lo := mid + 1
				else
					hi := mid - 1
				end
			end
		ensure
			in_range: 0 <= Result and Result <= header_count
		end

	slot_of_position (a_pos: INTEGER): INTEGER
			-- The slot shown position `a_pos' takes.
		require
			valid: 1 <= a_pos and a_pos <= laid_out_count
		do
			Result := a_pos + headers_through_position (a_pos)
		ensure
			in_range: a_pos <= Result and Result <= slot_count
		end

	header_at_slot (a_slot: INTEGER): INTEGER
			-- The header (from the top) in slot `a_slot'; 0 when a row takes it.
		require
			valid: 1 <= a_slot and a_slot <= slot_count
		local
			k: INTEGER
		do
			k := headers_through_slot (a_slot)
			if k > 0 and then header_slot (k) = a_slot then
				Result := k
			end
		ensure
			in_range: 0 <= Result and Result <= header_count
			there: Result > 0 implies header_slot (Result) = a_slot
		end

	position_at_slot (a_slot: INTEGER): INTEGER
			-- The shown position in slot `a_slot'; 0 when a header takes it.
		require
			valid: 1 <= a_slot and a_slot <= slot_count
		do
			if header_at_slot (a_slot) = 0 then
				Result := a_slot - headers_through_slot (a_slot)
			end
		ensure
			in_range: 0 <= Result and Result <= laid_out_count
			header_or_row: (Result = 0) = (header_at_slot (a_slot) > 0)
		end

	rows_through_slot (a_slot: INTEGER): INTEGER
			-- How many shown rows take slot `a_slot' or one above it.
		require
			not_negative: a_slot >= 0
		do
			Result := (a_slot.min (slot_count) - headers_through_slot (a_slot)).max (0)
		ensure
			in_range: 0 <= Result and Result <= laid_out_count
		end

	section_at_position (a_pos: INTEGER): INTEGER
			-- The section of the row at shown position `a_pos'; 0 for none.
		require
			valid: 1 <= a_pos and a_pos <= laid_out_count
		do
			if a_pos <= position_sections.count then
				Result := position_sections [a_pos]
			end
		ensure
			in_range: 0 <= Result and Result <= count
		end

	pinned_header (a_scroll, a_slot_height: REAL_64): INTEGER
			-- With the slots scrolled up by `a_scroll', each `a_slot_height' tall: the header
			-- (from the top) pinned at the top of the visible slots, the one of the section the
			-- topmost slot belongs to; 0 for none (not sticky, no headers, or a row before the
			-- first section at the top).
		require
			not_negative: a_scroll >= 0.0
			positive: a_slot_height > 0.0
		local
			s, k, p: INTEGER
		do
			if is_sticky and header_count > 0 then
				s := (a_scroll / a_slot_height).floor + 1
				if s <= slot_count then
					k := headers_through_slot (s)
					if k > 0 then
						p := position_at_slot (s)
						if p = 0 or else section_at_position (p) = header_sections [k] then
							Result := k
						end
					end
				end
			end
		ensure
			in_range: 0 <= Result and Result <= header_count
			only_sticky: Result > 0 implies is_sticky
		end

	pinned_offset (k: INTEGER; a_scroll, a_slot_height: REAL_64): REAL_64
			-- How far pinned header `k' is pushed up from the top of the visible slots by the
			-- next header, with the slots scrolled up by `a_scroll': 0 while the next is a slot
			-- or more below the top, down to minus a slot as it reaches the top.
		require
			valid: 1 <= k and k <= header_count
			not_negative: a_scroll >= 0.0
			positive: a_slot_height > 0.0
		do
			if k < header_count then
				Result := ((header_slot (k + 1) - 1) * a_slot_height - a_scroll - a_slot_height).min (0.0)
			end
		ensure
			not_positive: Result <= 0.0
		end

feature -- Drawing

	draw_header (a_p: SW_PAINTER; a_section: INTEGER; a_x, a_y, a_w, a_h: REAL_64; a_mirrored: BOOLEAN)
			-- Section `a_section''s header in a slot at `a_x', `a_y', `a_w' by `a_h': its bold
			-- title on the leading side (the right when `a_mirrored') over a subtle opaque band
			-- with a hairline under it, so a pinned one hides the rows scrolling under it.
		require
			valid: 1 <= a_section and a_section <= count
		local
			t: SW_THEME
			l_title: STRING_32
		do
			if a_w > 0.0 and a_h > 0.0 then
				t := a_p.theme
				a_p.set_color (t.surface_variant)
				a_p.fill_rect (a_x, a_y, a_w, a_h)
				a_p.set_color (t.outline)
				a_p.hline (a_x, a_y + a_h - 0.5, a_w)
				if a_w > 2.0 * Header_inset then
					l_title := titles [a_section]
					a_p.push_clip (a_x + Header_inset, a_y, a_w - 2.0 * Header_inset, a_h)
					a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
					a_p.set_color (t.ink)
					if a_mirrored then
						a_p.text (a_x + a_w - Header_inset - a_p.advance (l_title), a_p.baseline_in (a_y, a_h), l_title)
					else
						a_p.text (a_x + Header_inset, a_p.baseline_in (a_y, a_h), l_title)
					end
					a_p.pop_clip
				end
			end
		end

	Header_inset: REAL_64 = 8.0
			-- The title's gap from the header's edges.

feature -- Element change

	set_sections (a_starts: ARRAYED_LIST [INTEGER]; a_titles: ARRAYED_LIST [STRING_32])
			-- The whole layout: section i begins at model row `a_starts [i]' and is titled
			-- `a_titles [i]'. It shows at the next `lay_out'.
		require
			one_title_each: a_starts.count = a_titles.count
			positive: across a_starts as ic all ic >= 1 end
			ascending: across 2 |..| a_starts.count as ic all a_starts [ic - 1] < a_starts [ic] end
		do
			starts := a_starts.twin
			titles := a_titles.twin
			is_stale := True
		ensure
			counted: count = a_starts.count
			stale: is_stale
		end

	set_sticky (a_on: BOOLEAN)
			-- Pin the top section's header (`a_on'), or let headers scroll away with their rows.
		do
			is_sticky := a_on
		ensure
			set: is_sticky = a_on
		end

	mark_stale
			-- The shown rows changed: lay out again before the next use.
		do
			is_stale := True
		ensure
			stale: is_stale
		end

	lay_out (a_shown: INTEGER; a_model_at: FUNCTION [INTEGER, INTEGER])
			-- Place the headers among `a_shown' rows, `a_model_at' naming the model row at each
			-- shown position: a header above every shown row whose section is not 0 and not the
			-- one of the row above it.
		require
			not_negative: a_shown >= 0
		local
			p, l_section, l_above: INTEGER
		do
			header_positions.wipe_out
			header_sections.wipe_out
			position_sections.wipe_out
			if count > 0 then
				from
					p := 1
				until
					p > a_shown
				loop
					l_section := section_of (a_model_at.item ([p]))
					position_sections.extend (l_section)
					if l_section > 0 and l_section /= l_above then
						header_positions.extend (p)
						header_sections.extend (l_section)
					end
					l_above := l_section
					p := p + 1
				end
			end
			laid_out_count := a_shown
			is_stale := False
		ensure
			fresh: not is_stale
			covered: laid_out_count = a_shown
			no_more_headers_than_rows: header_count <= a_shown
			none_without_sections: count = 0 implies header_count = 0
		end

feature {NONE} -- Implementation

	starts: ARRAYED_LIST [INTEGER]
			-- Each section's first model row, ascending.

	titles: ARRAYED_LIST [STRING_32]
			-- Each section's title.

	header_positions: ARRAYED_LIST [INTEGER]
			-- The shown position each header stands above, ascending.

	header_sections: ARRAYED_LIST [INTEGER]
			-- The section of each header.

	position_sections: ARRAYED_LIST [INTEGER]
			-- The section of the row at each shown position (empty while there are no sections).

invariant
	one_title_each: titles.count = starts.count
	starts_ascending: across 2 |..| starts.count as ic all starts [ic - 1] < starts [ic] end
	headers_paired: header_sections.count = header_positions.count
	laid_out_not_negative: laid_out_count >= 0
	positions_known: position_sections.is_empty or position_sections.count = laid_out_count

end
