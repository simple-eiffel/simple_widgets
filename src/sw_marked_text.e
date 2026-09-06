note
	description: "[
		The data BEHIND a highlighted text: every span (SW_MARK_SPAN)
		that has been laid over it, addressable by id, and the
		arithmetic that keeps those spans honest while the text under
		them is edited.

		WHAT IT REMEMBERS. Ranges as caret offsets (lo + 1 .. hi), the
		REASON each range carries, an optional explicit look, an annotation.
		Not the text itself: the widget owns the text, this owns what
		was said about it, and `text_count' is the one fact shared -
		no span may reach past it.

		HOW IT FOLLOWS AN EDIT. The widget calls `text_inserted (at, n)'
		and `text_removed (lo, hi)' as it changes its string, and the
		spans move as a reader expects:

		    insert strictly INSIDE a span      the span grows
		    insert AT a span's start (= lo)    the span shifts right
		    insert AT a span's end (= hi)      the span does NOT grow
		    remove across a span               the span is trimmed
		    remove a whole span                the span is dropped

		`clamp_to' is the coarse door for an edit that arrives as a
		whole new string (undo, redo, a programmatic set_text): spans
		past the end are trimmed or dropped.

		CHANGE AND REMOVE. `restyle' swaps a span's explicit look,
		`rereason' its meaning, `set_range' its extent; `remove' takes
		one out, `remove_at' every span over a character, `remove_reason'
		every span carrying a reason, `clear' all of them.

		ORDER. Spans are kept in creation order and painted in it, so
		the latest one is on top. `spans_at' answers bottom to top.

		CODEC. `code' / `make_from_code' write one span per line as
		"id|lo|hi|reason|mark-code|annotation" - a form any store (a TOML
		string, a database column, a sidecar file) can hold, with no
		dependency on a JSON library.
	]"
	author: "Larry Rix"

class
	SW_MARKED_TEXT

create
	make, make_from_code

feature {NONE} -- Initialization

	make (a_text_count: INTEGER)
			-- Nothing marked over a text `a_text_count' characters long.
		require
			non_negative: a_text_count >= 0
		do
			text_count := a_text_count
			create spans.make (8)
			next_id := 1
		ensure
			sized: text_count = a_text_count
			empty: count = 0
			first_id: next_id = 1
		end

	make_from_code (a_text_count: INTEGER; a_code: READABLE_STRING_GENERAL)
			-- The spans `a_code' names (see `code'), clamped into
			-- `a_text_count'. A line that does not parse is skipped:
			-- the store may be older than the codec.
		require
			non_negative: a_text_count >= 0
		local
			lines: LIST [STRING_32]
			f: LIST [STRING_32]
			l_id, l_lo, l_hi: INTEGER
			s: SW_MARK_SPAN
		do
			make (a_text_count)
			lines := a_code.to_string_32.split ('%N')
			across
				lines as ln
			loop
				f := ln.split ('|')
				if f.count >= 5 and then f.i_th (1).is_integer and then f.i_th (2).is_integer
					and then f.i_th (3).is_integer
				then
					l_id := f.i_th (1).to_integer
					l_lo := f.i_th (2).to_integer
					l_hi := f.i_th (3).to_integer.min (a_text_count)
					if l_id > 0 and then l_lo >= 0 and then l_lo < l_hi and then not has (l_id)
						and then (create {SW_MARK_SPAN}.make (1, 0, 1, "x")).is_valid_reason (f.i_th (4))
					then
						create s.make (l_id, l_lo, l_hi, f.i_th (4))
						if not f.i_th (5).is_empty and then (create {SW_MARK}.make (1)).is_valid_code (f.i_th (5).to_string_8) then
							s.set_mark (create {SW_MARK}.make_from_code (f.i_th (5).to_string_8))
						end
						if f.count >= 6 then
							s.set_annotation (f.i_th (6))
						end
						spans.extend (s)
						next_id := next_id.max (l_id + 1)
					end
				end
			end
		ensure
			sized: text_count = a_text_count
		end

feature -- Access

	text_count: INTEGER
			-- How long the text under these spans is.

	count: INTEGER
		do
			Result := spans.count
		end

	span (a_id: INTEGER): SW_MARK_SPAN
		require
			present: has (a_id)
		do
			Result := spans.i_th (index_of (a_id))
		ensure
			that_one: Result.id = a_id
		end

	i_th (a_i: INTEGER): SW_MARK_SPAN
			-- The `a_i'-th span in paint order (1 = bottom).
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := spans.i_th (a_i)
		end

	spans_at (a_offset_of_char: INTEGER): ARRAYED_LIST [SW_MARK_SPAN]
			-- Every span covering character `a_offset_of_char', bottom to top.
		require
			in_text: a_offset_of_char >= 1 and a_offset_of_char <= text_count
		do
			create Result.make (2)
			across
				spans as s
			loop
				if s.covers (a_offset_of_char) then
					Result.extend (s)
				end
			end
		end

	spans_in (a_lo, a_hi: INTEGER): ARRAYED_LIST [SW_MARK_SPAN]
			-- Every span overlapping caret range `a_lo' .. `a_hi'.
		require
			range_valid: a_lo >= 0 and a_lo <= a_hi and a_hi <= text_count
		do
			create Result.make (2)
			across
				spans as s
			loop
				if s.overlaps (a_lo, a_hi) then
					Result.extend (s)
				end
			end
		end

	reasons: ARRAYED_LIST [STRING_32]
			-- Every distinct reason in use, first-seen order.
		do
			create Result.make (4)
			across
				spans as s
			loop
				if not across Result as r some r.same_string (s.reason) end then
					Result.extend (s.reason.twin)
				end
			end
		end

	unresolved (a_legend: SW_MARK_LEGEND): ARRAYED_LIST [STRING_32]
			-- Reasons no explicit mark covers and `a_legend' does not know.
		do
			create Result.make (2)
			across
				spans as s
			loop
				if s.mark = Void and then not a_legend.has (s.reason)
					and then not across Result as r some r.same_string (s.reason) end
				then
					Result.extend (s.reason.twin)
				end
			end
		end

feature -- Status

	has (a_id: INTEGER): BOOLEAN
		do
			Result := index_of (a_id) > 0
		end

	is_marked (a_offset_of_char: INTEGER): BOOLEAN
		require
			in_text: a_offset_of_char >= 1 and a_offset_of_char <= text_count
		do
			Result := across spans as s some s.covers (a_offset_of_char) end
		end

feature -- Marking

	mark_range (a_lo, a_hi: INTEGER; a_reason: READABLE_STRING_GENERAL): INTEGER
			-- Lay `a_reason' over caret range `a_lo' .. `a_hi', on top;
			-- answer the new span's id.
		require
			range_valid: a_lo >= 0 and a_lo < a_hi and a_hi <= text_count
			reason_valid: (create {SW_MARK_SPAN}.make (1, 0, 1, "x")).is_valid_reason (a_reason)
		local
			s: SW_MARK_SPAN
		do
			Result := next_id
			create s.make (Result, a_lo, a_hi, a_reason)
			spans.extend (s)
			next_id := next_id + 1
		ensure
			one_more: count = old count + 1
			on_top: i_th (count).id = Result
			present: has (Result)
		end

	mark_range_with (a_lo, a_hi: INTEGER; a_reason: READABLE_STRING_GENERAL; a_mark: SW_MARK): INTEGER
			-- The same, with an explicit look that beats the legend.
		require
			range_valid: a_lo >= 0 and a_lo < a_hi and a_hi <= text_count
			reason_valid: (create {SW_MARK_SPAN}.make (1, 0, 1, "x")).is_valid_reason (a_reason)
		do
			Result := mark_range (a_lo, a_hi, a_reason)
			span (Result).set_mark (a_mark)
		ensure
			styled: span (Result).mark = a_mark
		end

	restyle (a_id: INTEGER; a_mark: detachable SW_MARK)
			-- Change how span `a_id' looks (Void: back to the legend's).
		require
			present: has (a_id)
		do
			span (a_id).set_mark (a_mark)
		ensure
			restyled: span (a_id).mark = a_mark
		end

	rereason (a_id: INTEGER; a_reason: READABLE_STRING_GENERAL)
			-- Change what span `a_id' means.
		require
			present: has (a_id)
			reason_valid: (create {SW_MARK_SPAN}.make (1, 0, 1, "x")).is_valid_reason (a_reason)
		do
			span (a_id).set_reason (a_reason)
		ensure
			rereasoned: span (a_id).reason.same_string_general (a_reason)
		end

	set_range (a_id, a_lo, a_hi: INTEGER)
			-- Change how far span `a_id' reaches.
		require
			present: has (a_id)
			range_valid: a_lo >= 0 and a_lo < a_hi and a_hi <= text_count
		do
			span (a_id).set_range (a_lo, a_hi)
		ensure
			resized: span (a_id).lo = a_lo and span (a_id).hi = a_hi
		end

	remove (a_id: INTEGER)
		require
			present: has (a_id)
		do
			spans.go_i_th (index_of (a_id))
			spans.remove
		ensure
			gone: not has (a_id)
			one_fewer: count = old count - 1
		end

	remove_at (a_offset_of_char: INTEGER)
			-- Every span over character `a_offset_of_char'.
		require
			in_text: a_offset_of_char >= 1 and a_offset_of_char <= text_count
		do
			from
				spans.start
			until
				spans.after
			loop
				if spans.item.covers (a_offset_of_char) then
					spans.remove
				else
					spans.forth
				end
			end
		ensure
			bare: not is_marked (a_offset_of_char)
		end

	remove_reason (a_reason: READABLE_STRING_GENERAL)
			-- Every span carrying `a_reason'.
		do
			from
				spans.start
			until
				spans.after
			loop
				if spans.item.reason.same_string_general (a_reason) then
					spans.remove
				else
					spans.forth
				end
			end
		ensure
			none_left: not across spans as s some s.reason.same_string_general (a_reason) end
		end

	clear
		do
			spans.wipe_out
		ensure
			empty: count = 0
		end

feature -- Following the text

	text_inserted (a_at, a_n: INTEGER)
			-- `a_n' characters went in at caret offset `a_at'.
		require
			at_in_text: a_at >= 0 and a_at <= text_count
			positive: a_n > 0
		do
			across
				spans as s
			loop
				if a_at <= s.lo then
					s.set_range (s.lo + a_n, s.hi + a_n)
				elseif a_at < s.hi then
					s.set_range (s.lo, s.hi + a_n)
				end
			end
			text_count := text_count + a_n
		ensure
			grown: text_count = old text_count + a_n
			count_kept: count = old count
		end

	text_removed (a_lo, a_hi: INTEGER)
			-- Characters `a_lo' + 1 .. `a_hi' came out.
		require
			range_valid: a_lo >= 0 and a_lo < a_hi and a_hi <= text_count
		local
			n, nlo, nhi: INTEGER
		do
			n := a_hi - a_lo
			from
				spans.start
			until
				spans.after
			loop
				nlo := spans.item.lo
				nhi := spans.item.hi
				if nlo >= a_hi then
					nlo := nlo - n
					nhi := nhi - n
				else
					if nlo > a_lo then
						nlo := a_lo
					end
					if nhi > a_hi then
						nhi := nhi - n
					elseif nhi > a_lo then
						nhi := a_lo
					end
				end
				if nhi > nlo then
					spans.item.set_range (nlo, nhi)
					spans.forth
				else
					spans.remove
				end
			end
			text_count := text_count - n
		ensure
			shrunk: text_count = old text_count - (a_hi - a_lo)
			never_more: count <= old count
		end

	clamp_to (a_text_count: INTEGER)
			-- The text is now `a_text_count' long, by whatever route:
			-- spans past the end are trimmed, empty ones dropped.
		require
			non_negative: a_text_count >= 0
		do
			from
				spans.start
			until
				spans.after
			loop
				if spans.item.lo >= a_text_count then
					spans.remove
				else
					if spans.item.hi > a_text_count then
						spans.item.set_range (spans.item.lo, a_text_count)
					end
					spans.forth
				end
			end
			text_count := a_text_count
		ensure
			sized: text_count = a_text_count
			all_inside: across spans as s all s.hi <= a_text_count end
		end

feature -- Copying

	duplicate: SW_MARKED_TEXT
			-- A deep copy: same spans, same ids, independent objects.
		do
			create Result.make_from_code (text_count, code)
		ensure
			same_count: Result.count = count
			independent: Result /= Current
		end

	copy_from (a_other: SW_MARKED_TEXT)
			-- Become a deep copy of `a_other'.
		local
			d: SW_MARKED_TEXT
		do
			d := a_other.duplicate
			spans := d.spans
			text_count := d.text_count
			next_id := d.next_id
		ensure
			same_count: count = a_other.count
			same_size: text_count = a_other.text_count
		end

feature -- Codec

	code: STRING_32
			-- One span per line: id|lo|hi|reason|mark-code|annotation.
		do
			create Result.make (spans.count * 24)
			across
				spans as s
			loop
				if not Result.is_empty then
					Result.append_character ('%N')
				end
				Result.append_string_general (s.id.out)
				Result.append_character ('|')
				Result.append_string_general (s.lo.out)
				Result.append_character ('|')
				Result.append_string_general (s.hi.out)
				Result.append_character ('|')
				Result.append (s.reason)
				Result.append_character ('|')
				if attached s.mark as m then
					Result.append_string_general (m.code)
				end
				Result.append_character ('|')
				Result.append (s.annotation)
			end
		end

feature {SW_MARKED_TEXT} -- Implementation

	spans: ARRAYED_LIST [SW_MARK_SPAN]

	next_id: INTEGER
			-- The id the next span takes; ids are never reused. Set by
			-- the creation procedures: an INTEGER attribute is
			-- self-initializing, so an attribute body would never run
			-- (VWAB) and every marked text would be born at 0.

feature {NONE} -- Implementation

	index_of (a_id: INTEGER): INTEGER
			-- Position of span `a_id' in `spans'; 0 when absent.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > spans.count or Result > 0
			loop
				if spans.i_th (i).id = a_id then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= spans.count
		end

invariant
	size_non_negative: text_count >= 0
	spans_inside: across spans as s all s.hi <= text_count end
	next_id_positive: next_id >= 1
	ids_unique: across spans as s all index_of (s.id) > 0 end

end
