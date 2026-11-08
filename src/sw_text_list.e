note
	description: "[
		A list of text rows: SW_LIST holding its own strings, drawing them, and naming them
		for screen readers (W6, simple_gui's GUI_LIST on Windows).
	]"

class
	SW_TEXT_LIST

inherit
	SW_LIST
		rename
			make as make_list
		end

create
	make

feature {NONE} -- Initialization

	make (a_viewport_height: REAL_64)
			-- An empty list `a_viewport_height' tall.
		require
			positive: a_viewport_height > 0.0
		do
			create rows.make (8)
			make_list (a_viewport_height)
			set_row_renderer (agent render_row)
			set_row_text (agent label_of)
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
		do
			Result := rows.count
		end

	i_th (a_i: INTEGER): STRING_32
		require
			valid: 1 <= a_i and a_i <= count
		do
			Result := rows.i_th (a_i)
		end

feature -- Element change

	extend (a_text: READABLE_STRING_GENERAL)
			-- Add a row at the end.
		do
			rows.extend (a_text.to_string_32)
			set_row_count (rows.count)
		ensure
			one_more: count = old count + 1
			last: i_th (count).same_string_general (a_text)
		end

	wipe_out
			-- Remove every row (the selection goes too, silently).
		do
			rows.wipe_out
			set_row_count (0)
		ensure
			empty: count = 0
			none_selected: selected_index = 0
		end

feature {NONE} -- Implementation

	rows: ARRAYED_LIST [STRING_32]

	render_row (a_p: SW_PAINTER; a_i: INTEGER; a_x, a_y, a_w, a_h: REAL_64)
		do
			if a_i >= 1 and a_i <= rows.count then
				a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_body, False)
				a_p.set_color (a_p.theme.ink)
				if mirrors_layout then
						-- W4c: flush right in right-to-left layout.
					a_p.text (a_x + a_w - 8.0 - a_p.advance (rows.i_th (a_i)), a_y + a_h - 9.0, rows.i_th (a_i))
				else
					a_p.text (a_x + 8.0, a_y + a_h - 9.0, rows.i_th (a_i))
				end
			end
		end

	label_of (a_i: INTEGER): READABLE_STRING_GENERAL
		do
			if a_i >= 1 and a_i <= rows.count then
				Result := rows.i_th (a_i)
			else
				Result := ""
			end
		end

invariant
	rows_exist: rows /= Void
	counted: row_count = rows.count

end
