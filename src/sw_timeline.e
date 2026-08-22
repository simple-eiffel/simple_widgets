note
	description: "[
		Events down a rail: a dot per entry wearing its semantic
		kind, the time in mono, the title in ink, an optional detail
		muted beneath. History made scannable.
	]"

class
	SW_TIMELINE

inherit
	SW_WIDGET

create
	make

feature {NONE} -- Initialization

	make
		do
			create entries.make (8)
		end

feature -- Access

	entries: ARRAYED_LIST [TUPLE [when_text: STRING_32; title: STRING_32; detail: STRING_32; kind: INTEGER]]

	Kind_neutral: INTEGER = 0
	Kind_accent: INTEGER = 1
	Kind_success: INTEGER = 2
	Kind_warning: INTEGER = 3
	Kind_danger: INTEGER = 4

	Rail_x: REAL_64 = 86.0

	row_height (a_i: INTEGER): REAL_64
		require
			in_range: a_i >= 1 and a_i <= entries.count
		do
			if entries.i_th (a_i).detail.is_empty then
				Result := 30.0
			else
				Result := 48.0
			end
		end

feature -- Element change

	add_entry (a_when, a_title, a_detail: READABLE_STRING_GENERAL; a_kind: INTEGER)
		require
			kind_known: a_kind >= Kind_neutral and a_kind <= Kind_danger
		local
			w, ti, d: STRING_32
		do
			create w.make_from_string_general (a_when)
			create ti.make_from_string_general (a_title)
			create d.make_from_string_general (a_detail)
			entries.extend ([w, ti, d, a_kind])
		ensure
			grew: entries.count = old entries.count + 1
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > entries.count
			loop
				Result := Result + row_height (i)
				i := i + 1
			end
			Result := Result + 8.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			i: INTEGER
			cy, dot_y: REAL_64
		do
			t := a_p.theme
			cy := y + 4.0
			from
				i := 1
			until
				i > entries.count
			loop
				dot_y := cy + 10.0
				if i < entries.count then
					a_p.set_color (t.outline)
					a_p.vline (x + Rail_x, dot_y + 6.0, row_height (i) - 8.0)
				end
				inspect entries.i_th (i).kind
				when 1 then
					a_p.set_color (t.accent)
				when 2 then
					a_p.set_color (t.success)
				when 3 then
					a_p.set_color (t.warning)
				when 4 then
					a_p.set_color (t.danger)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.circle_fill (x + Rail_x, dot_y, 5.0)
				a_p.font ({SW_PAINTER}.Role_mono, t.size_chip + 1.0, False)
				a_p.set_color (t.ink_muted)
				a_p.text (x + Rail_x - 16.0 - a_p.advance (entries.i_th (i).when_text), dot_y + 5.0, entries.i_th (i).when_text)
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
				a_p.set_color (t.ink)
				a_p.text (x + Rail_x + 16.0, dot_y + 5.0, entries.i_th (i).title)
				if not entries.i_th (i).detail.is_empty then
					a_p.font ({SW_PAINTER}.Role_ui, t.size_chip + 1.0, False)
					a_p.set_color (t.ink_muted)
					a_p.text (x + Rail_x + 16.0, dot_y + 23.0, entries.i_th (i).detail)
				end
				cy := cy + row_height (i)
				i := i + 1
			end
		end

invariant
	entries_attached: entries /= Void

end
