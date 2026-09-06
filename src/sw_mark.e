note
	description: "[
		What a highlight LOOKS like, and nothing about what it means:
		one of twelve palette hues applied through any combination of
		seven aspects -

		    wash          a tint behind the text (the text shows through)
		    box_lines     0 .. 3 rules boxed around the span
		    text_outlines 0 .. 2 outlines traced around the glyphs
		    colorized     the glyphs themselves in the hue's ink
		    bold, italic  the type's weight and slant

		Every combination is legal; `is_plain' is the empty one. The
		hue is required because every visible aspect needs a colour,
		and the palette (SW_MARK_PALETTE) is what turns a hue into an
		ink or a wash that stays readable on a light or a dark theme.

		A mark is a VALUE: `same_mark' compares by content, `code'
		round-trips it through any store as a short string, and the
		fluent `with_*' builders read as a sentence -
		`create m.make (Hue_amber); m := m.with_wash.with_box (2).bold'.

		Meaning lives elsewhere. SW_MARK_LEGEND maps an application's
		REASON ("spelling", "stale", "voice:narrator") to a mark, and
		SW_MARKED_TEXT keeps spans that carry reasons - so the same
		reason can look different as the application's state changes
		without a single span being touched.
	]"
	author: "Larry Rix"

class
	SW_MARK

create
	make, make_from_code

feature {NONE} -- Initialization

	make (a_hue: INTEGER)
			-- A plain mark in `a_hue': nothing visible until an aspect
			-- is switched on.
		require
			hue_known: a_hue >= 1 and a_hue <= Hue_count
		do
			hue := a_hue
		ensure
			hue_set: hue = a_hue
			plain: is_plain
		end

	make_from_code (a_code: READABLE_STRING_8)
			-- The mark `a_code' names - see `code'.
		require
			valid: is_valid_code (a_code)
		local
			i, n: INTEGER
			c: CHARACTER_8
		do
			i := a_code.index_of (':', 1)
			hue := a_code.substring (1, i - 1).to_integer
			n := a_code.count
			from
				i := i + 1
			until
				i > n
			loop
				c := a_code.item (i)
				inspect c
				when 'F' then
					has_wash := True
				when 'C' then
					is_colorized := True
				when 'b' then
					is_bold := True
				when 'i' then
					is_italic := True
				when 'B' then
					box_lines := a_code.item (i + 1).natural_32_code.to_integer_32 - ('0').natural_32_code.to_integer_32
					i := i + 1
				when 'O' then
					text_outlines := a_code.item (i + 1).natural_32_code.to_integer_32 - ('0').natural_32_code.to_integer_32
					i := i + 1
				else
				end
				i := i + 1
			end
		ensure
			round_trip: code.same_string (a_code)
		end

feature -- Hues

	Hue_count: INTEGER = 12

	Hue_red: INTEGER = 1
	Hue_orange: INTEGER = 2
	Hue_amber: INTEGER = 3
	Hue_yellow: INTEGER = 4
	Hue_lime: INTEGER = 5
	Hue_green: INTEGER = 6
	Hue_teal: INTEGER = 7
	Hue_cyan: INTEGER = 8
	Hue_blue: INTEGER = 9
	Hue_indigo: INTEGER = 10
	Hue_violet: INTEGER = 11
	Hue_magenta: INTEGER = 12

feature -- Access

	hue: INTEGER
			-- 1 .. `Hue_count'; the palette says what colour that is.

	has_wash: BOOLEAN
			-- A tint behind the text.

	box_lines: INTEGER
			-- Rules boxed around the span, 0 .. `Max_box_lines'.

	text_outlines: INTEGER
			-- Outlines traced around the glyphs, 0 .. `Max_text_outlines'.

	is_colorized: BOOLEAN
			-- The glyphs themselves in the hue's ink.

	is_bold: BOOLEAN

	is_italic: BOOLEAN

	Max_box_lines: INTEGER = 3

	Max_text_outlines: INTEGER = 2

feature -- Status

	is_plain: BOOLEAN
			-- Nothing visible?
		do
			Result := not has_wash and box_lines = 0 and text_outlines = 0
				and not is_colorized and not is_bold and not is_italic
		end

	changes_glyphs: BOOLEAN
			-- Does painting this mark redraw the text itself (as
			-- opposed to painting around or behind it)?
		do
			Result := text_outlines > 0 or is_colorized or is_bold or is_italic
		ensure
			definition: Result = (text_outlines > 0 or is_colorized or is_bold or is_italic)
		end

	same_mark (a_other: SW_MARK): BOOLEAN
			-- Identical in every aspect?
		do
			Result := hue = a_other.hue and has_wash = a_other.has_wash
				and box_lines = a_other.box_lines and text_outlines = a_other.text_outlines
				and is_colorized = a_other.is_colorized and is_bold = a_other.is_bold
				and is_italic = a_other.is_italic
		ensure
			symmetric_by_code: Result = code.same_string (a_other.code)
		end

	code: STRING_8
			-- "<hue>:" then one letter per aspect - F wash, B<n> box
			-- lines, O<n> text outlines, C colorized, b bold, i italic.
			-- "7:FB2Cb" is amber-teal... no: hue 7 (teal) washed, boxed
			-- twice, colorized, bold.
		do
			create Result.make (12)
			Result.append (hue.out)
			Result.append_character (':')
			if has_wash then
				Result.append_character ('F')
			end
			if box_lines > 0 then
				Result.append_character ('B')
				Result.append (box_lines.out)
			end
			if text_outlines > 0 then
				Result.append_character ('O')
				Result.append (text_outlines.out)
			end
			if is_colorized then
				Result.append_character ('C')
			end
			if is_bold then
				Result.append_character ('b')
			end
			if is_italic then
				Result.append_character ('i')
			end
		ensure
			valid: is_valid_code (Result)
		end

	is_valid_code (a_code: READABLE_STRING_8): BOOLEAN
			-- Would `make_from_code' accept `a_code'?
		local
			i, n, h: INTEGER
			c: CHARACTER_8
		do
			i := a_code.index_of (':', 1)
			if i >= 2 and then a_code.substring (1, i - 1).is_integer then
				h := a_code.substring (1, i - 1).to_integer
				Result := h >= 1 and h <= Hue_count
				n := a_code.count
				from
					i := i + 1
				until
					i > n or not Result
				loop
					c := a_code.item (i)
					if c = 'F' or c = 'C' or c = 'b' or c = 'i' then
					elseif c = 'B' then
						Result := i < n and then a_code.item (i + 1) >= '1' and then a_code.item (i + 1) <= '3'
						i := i + 1
					elseif c = 'O' then
						Result := i < n and then a_code.item (i + 1) >= '1' and then a_code.item (i + 1) <= '2'
						i := i + 1
					else
						Result := False
					end
					i := i + 1
				end
			end
		end

feature -- Element change (fluent)

	with_hue (a_hue: INTEGER): like Current
		require
			hue_known: a_hue >= 1 and a_hue <= Hue_count
		do
			hue := a_hue
			Result := Current
		ensure
			set: hue = a_hue
			chained: Result = Current
		end

	with_wash: like Current
		do
			has_wash := True
			Result := Current
		ensure
			washed: has_wash
			chained: Result = Current
		end

	without_wash: like Current
		do
			has_wash := False
			Result := Current
		ensure
			bare: not has_wash
			chained: Result = Current
		end

	with_box (a_lines: INTEGER): like Current
		require
			in_range: a_lines >= 0 and a_lines <= Max_box_lines
		do
			box_lines := a_lines
			Result := Current
		ensure
			set: box_lines = a_lines
			chained: Result = Current
		end

	with_outline (a_lines: INTEGER): like Current
		require
			in_range: a_lines >= 0 and a_lines <= Max_text_outlines
		do
			text_outlines := a_lines
			Result := Current
		ensure
			set: text_outlines = a_lines
			chained: Result = Current
		end

	colorized: like Current
		do
			is_colorized := True
			Result := Current
		ensure
			set: is_colorized
			chained: Result = Current
		end

	uncolorized: like Current
		do
			is_colorized := False
			Result := Current
		ensure
			set: not is_colorized
			chained: Result = Current
		end

	bold: like Current
		do
			is_bold := True
			Result := Current
		ensure
			set: is_bold
			chained: Result = Current
		end

	regular: like Current
		do
			is_bold := False
			Result := Current
		ensure
			set: not is_bold
			chained: Result = Current
		end

	italic: like Current
		do
			is_italic := True
			Result := Current
		ensure
			set: is_italic
			chained: Result = Current
		end

	upright: like Current
		do
			is_italic := False
			Result := Current
		ensure
			set: not is_italic
			chained: Result = Current
		end

	twin_mark: SW_MARK
			-- A copy that can be changed without touching this one.
		do
			create Result.make_from_code (code)
		ensure
			same: Result.same_mark (Current)
			distinct: Result /= Current
		end

invariant
	hue_known: hue >= 1 and hue <= Hue_count
	box_in_range: box_lines >= 0 and box_lines <= Max_box_lines
	outline_in_range: text_outlines >= 0 and text_outlines <= Max_text_outlines

end
