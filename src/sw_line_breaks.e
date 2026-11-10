note
	description: "[
		Where program text breaks into lines: LF, CR LF (ONE break) or a
		lone CR. One place for every drawer of program text (SW_LABEL,
		SW_PAINTER.broken_lines for hints), so a break acts as a break
		instead of painting a missing-glyph box.
	]"

class
	SW_LINE_BREAKS

feature -- Access

	lines_of (a_s: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- `a_s' cut at each line break. Text without breaks is one
			-- line; a trailing break opens a final empty line, as GtkLabel
			-- shows it.
		local
			i: INTEGER
			c: CHARACTER_32
			l_line: STRING_32
		do
			create Result.make (2)
			create l_line.make (a_s.count)
			from
				i := 1
			until
				i > a_s.count
			loop
				c := a_s.item (i)
				if c = '%N' then
					Result.extend (l_line)
					create l_line.make (a_s.count)
				elseif c = '%R' then
					if i = a_s.count or else a_s.item (i + 1) /= '%N' then
						Result.extend (l_line)
						create l_line.make (a_s.count)
					end
				else
					l_line.append_character (c)
				end
				i := i + 1
			end
			Result.extend (l_line)
		ensure
			at_least_one: not Result.is_empty
		end

end
