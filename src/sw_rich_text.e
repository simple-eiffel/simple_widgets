note
	description: "[
		One stretch of rich text (GW-13): the characters and the inline
		spans over them - bold, italic, small capitals, superscript, and
		links with a target. A paragraph of a commentary, a heading, a
		list item or a table cell of an SW_DOCUMENT is one of these.

		Spans may overlap: a link may be bold, a bold word may hold an
		italic one. `styles' FLATTENS them for the shaper - every maximal
		stretch with one combination becomes one SHAPING_STYLES span
		carrying its whole setting (weight, slant, size, lift, small
		capitals and ink) - because in SHAPING_STYLES the later span wins
		outright.

		The text is the SOURCE: search, copy and a caret see it as typed.
		`revision' grows with every change, so a view re-measures only
		what changed.
	]"
	author: "Larry Rix"

class
	SW_RICH_TEXT

create
	make

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL)
			-- `a_text', no spans.
		do
			create text.make_from_string_general (a_text)
			create kinds.make (4)
			create starts.make (4)
			create counts.make (4)
			create targets.make (4)
		ensure
			text_kept: text.same_string_general (a_text)
			plain: span_count = 0
		end

feature -- Constants

	Kind_bold: INTEGER = 1
	Kind_italic: INTEGER = 2
	Kind_small_caps: INTEGER = 3
	Kind_superscript: INTEGER = 4
	Kind_link: INTEGER = 5

	is_valid_kind (a_kind: INTEGER): BOOLEAN
		do
			Result := a_kind >= Kind_bold and a_kind <= Kind_link
		end

feature -- Access

	text: STRING_32
			-- The characters, as typed.

	count: INTEGER
			-- Characters.
		do
			Result := text.count
		ensure
			definition: Result = text.count
		end

	revision: INTEGER
			-- Grows with every change of text or spans.

	span_count: INTEGER
		do
			Result := kinds.count
		ensure
			non_negative: Result >= 0
		end

	span_kind (a_k: INTEGER): INTEGER
		require
			in_range: a_k >= 1 and a_k <= span_count
		do
			Result := kinds.i_th (a_k)
		ensure
			valid: is_valid_kind (Result)
		end

	span_start (a_k: INTEGER): INTEGER
		require
			in_range: a_k >= 1 and a_k <= span_count
		do
			Result := starts.i_th (a_k)
		end

	span_length (a_k: INTEGER): INTEGER
		require
			in_range: a_k >= 1 and a_k <= span_count
		do
			Result := counts.i_th (a_k)
		end

	span_target (a_k: INTEGER): STRING_32
			-- A link's target; empty for every other kind.
		require
			in_range: a_k >= 1 and a_k <= span_count
		do
			Result := targets.i_th (a_k)
		end

	has_kind_at (a_kind, a_i: INTEGER): BOOLEAN
			-- Does a span of `a_kind' cover character `a_i'?
		require
			valid_kind: is_valid_kind (a_kind)
		local
			k: INTEGER
		do
			from
				k := 1
			until
				k > span_count or Result
			loop
				Result := kinds.i_th (k) = a_kind and then covers (k, a_i)
				k := k + 1
			end
		end

	link_at (a_i: INTEGER): INTEGER
			-- The link span over character `a_i' (the last added, where
			-- links overlap); 0 for none.
		local
			k: INTEGER
		do
			from
				k := span_count
			until
				k < 1 or Result > 0
			loop
				if kinds.i_th (k) = Kind_link and then covers (k, a_i) then
					Result := k
				end
				k := k - 1
			end
		ensure
			in_range: Result >= 0 and Result <= span_count
			is_a_link: Result > 0 implies span_kind (Result) = Kind_link
		end

	link_count: INTEGER
			-- Link spans held.
		do
			across kinds as k loop
				if k = Kind_link then
					Result := Result + 1
				end
			end
		ensure
			bounded: Result >= 0 and Result <= span_count
		end

	styles (a_link_ink: INTEGER): SHAPING_STYLES
			-- The spans flattened for the shaper: each maximal stretch with
			-- one combination of kinds becomes one span with its whole
			-- setting. Links are set in ink `a_link_ink' (a number the
			-- painting host maps to a colour).
		require
			ink_positive: a_link_ink > 0
		local
			i, j, l_key: INTEGER
		do
			create Result.make
			if span_count > 0 then
				from
					i := 1
				until
					i > count
				loop
					l_key := setting_key (i)
					from
						j := i
					until
						j >= count or else setting_key (j + 1) /= l_key
					loop
						j := j + 1
					end
					if l_key /= 0 then
						Result.add_setting (i, j - i + 1,
							if l_key & Bit_superscript /= 0 then Result.Superscript_scale else 1.0 end,
							if l_key & Bit_superscript /= 0 then Result.Superscript_rise else 0.0 end,
							l_key & Bit_small_caps /= 0,
							if l_key & Bit_bold /= 0 then Result.Weight_bold else 0 end,
							l_key & Bit_italic /= 0,
							if l_key & Bit_link /= 0 then a_link_ink else 0 end)
					end
					i := j + 1
				end
			end
		ensure
			plain_is_empty: span_count = 0 implies Result.is_empty
		end

feature -- Element change

	add_bold (a_start, a_count: INTEGER)
		require
			range_valid: is_valid_range (a_start, a_count)
		do
			add_span (Kind_bold, a_start, a_count, {STRING_32} "")
		ensure
			one_more: span_count = old span_count + 1
			bold: has_kind_at (Kind_bold, a_start)
		end

	add_italic (a_start, a_count: INTEGER)
		require
			range_valid: is_valid_range (a_start, a_count)
		do
			add_span (Kind_italic, a_start, a_count, {STRING_32} "")
		ensure
			one_more: span_count = old span_count + 1
			italic: has_kind_at (Kind_italic, a_start)
		end

	add_small_caps (a_start, a_count: INTEGER)
		require
			range_valid: is_valid_range (a_start, a_count)
		do
			add_span (Kind_small_caps, a_start, a_count, {STRING_32} "")
		ensure
			one_more: span_count = old span_count + 1
		end

	add_superscript (a_start, a_count: INTEGER)
		require
			range_valid: is_valid_range (a_start, a_count)
		do
			add_span (Kind_superscript, a_start, a_count, {STRING_32} "")
		ensure
			one_more: span_count = old span_count + 1
		end

	add_link (a_start, a_count: INTEGER; a_target: READABLE_STRING_GENERAL)
			-- Characters `a_start' .. `a_start' + `a_count' - 1 lead to
			-- `a_target' (a verse reference, an article key, a URL: the
			-- host's to interpret).
		require
			range_valid: is_valid_range (a_start, a_count)
			target_not_empty: not a_target.is_empty
		do
			add_span (Kind_link, a_start, a_count, a_target.to_string_32)
		ensure
			one_more: span_count = old span_count + 1
			linked: link_at (a_start) = span_count
			target_kept: span_target (span_count).same_string_general (a_target)
		end

	set_text (a_text: READABLE_STRING_GENERAL)
			-- Replace the characters; spans past the new end go, a span
			-- over it is cut there.
		local
			k: INTEGER
		do
			create text.make_from_string_general (a_text)
			from
				k := span_count
			until
				k < 1
			loop
				if starts.i_th (k) > count then
					remove_span (k)
				elseif starts.i_th (k) + counts.i_th (k) - 1 > count then
					counts.put_i_th (count - starts.i_th (k) + 1, k)
				end
				k := k - 1
			end
			revision := revision + 1
		ensure
			text_set: text.same_string_general (a_text)
			changed: revision > old revision
			never_more_spans: span_count <= old span_count
		end

	remove_spans
			-- Plain again.
		do
			kinds.wipe_out
			starts.wipe_out
			counts.wipe_out
			targets.wipe_out
			revision := revision + 1
		ensure
			plain: span_count = 0
			changed: revision > old revision
		end

feature -- Status

	is_valid_range (a_start, a_count: INTEGER): BOOLEAN
			-- Is `a_start' .. `a_start' + `a_count' - 1 a non-empty stretch
			-- inside the text?
		do
			Result := a_start >= 1 and a_count > 0 and a_start + a_count - 1 <= count
		end

feature {NONE} -- Implementation

	kinds, starts, counts: ARRAYED_LIST [INTEGER]
	targets: ARRAYED_LIST [STRING_32]

	Bit_bold: INTEGER = 1
	Bit_italic: INTEGER = 2
	Bit_small_caps: INTEGER = 4
	Bit_superscript: INTEGER = 8
	Bit_link: INTEGER = 16

	covers (a_k, a_i: INTEGER): BOOLEAN
			-- Does span `a_k' cover character `a_i'?
		require
			in_range: a_k >= 1 and a_k <= span_count
		do
			Result := a_i >= starts.i_th (a_k) and a_i < starts.i_th (a_k) + counts.i_th (a_k)
		end

	setting_key (a_i: INTEGER): INTEGER
			-- The kinds over character `a_i', one bit each.
		local
			k: INTEGER
		do
			from
				k := 1
			until
				k > span_count
			loop
				if covers (k, a_i) then
					inspect kinds.i_th (k)
					when Kind_bold then
						Result := Result | Bit_bold
					when Kind_italic then
						Result := Result | Bit_italic
					when Kind_small_caps then
						Result := Result | Bit_small_caps
					when Kind_superscript then
						Result := Result | Bit_superscript
					else
						Result := Result | Bit_link
					end
				end
				k := k + 1
			end
		ensure
			bounded: Result >= 0 and Result < 32
		end

	add_span (a_kind, a_start, a_count: INTEGER; a_target: STRING_32)
		require
			valid_kind: is_valid_kind (a_kind)
			range_valid: is_valid_range (a_start, a_count)
		do
			kinds.extend (a_kind)
			starts.extend (a_start)
			counts.extend (a_count)
			targets.extend (a_target)
			revision := revision + 1
		ensure
			one_more: span_count = old span_count + 1
			changed: revision > old revision
		end

	remove_span (a_k: INTEGER)
		require
			in_range: a_k >= 1 and a_k <= span_count
		do
			kinds.go_i_th (a_k)
			kinds.remove
			starts.go_i_th (a_k)
			starts.remove
			counts.go_i_th (a_k)
			counts.remove
			targets.go_i_th (a_k)
			targets.remove
		ensure
			one_fewer: span_count = old span_count - 1
		end

invariant
	parallel: starts.count = kinds.count and counts.count = kinds.count and targets.count = kinds.count
	revision_non_negative: revision >= 0

end
