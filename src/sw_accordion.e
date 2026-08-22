note
	description: "[
		Stacked disclosure: titled sections whose content shows only
		while open. Exclusive by default (opening one closes the
		others - the classic accordion); multi-open by choice. The
		chevron tells the state before the click does.
	]"

class
	SW_ACCORDION

inherit
	SW_WIDGET
		redefine
			arrange, widget_at, handle_click, wants_hover_point
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create sections.make (4)
			is_exclusive := True
		ensure
			exclusive_by_default: is_exclusive
		end

feature -- Access

	sections: ARRAYED_LIST [TUPLE [title: STRING_32; content: SW_WIDGET; is_open: BOOLEAN]]

	is_exclusive: BOOLEAN
			-- Does opening a section close the others?

	on_change: detachable PROCEDURE [INTEGER]
			-- Fired with the section index after any toggle.

	Header_h: REAL_64 = 34.0

	is_section_open (a_i: INTEGER): BOOLEAN
		require
			in_range: a_i >= 1 and a_i <= sections.count
		do
			Result := sections.i_th (a_i).is_open
		end

	open_count: INTEGER
		do
			across
				sections as s
			loop
				if s.is_open then
					Result := Result + 1
				end
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Element change

	add_section (a_title: READABLE_STRING_GENERAL; a_content: SW_WIDGET)
		local
			s: STRING_32
		do
			create s.make_from_string_general (a_title)
			sections.extend ([s, a_content, False])
			a_content.set_parent (Current)
		ensure
			grew: sections.count = old sections.count + 1
			adopted: a_content.parent = Current
		end

	set_exclusive (a_on: BOOLEAN)
		do
			is_exclusive := a_on
		ensure
			set: is_exclusive = a_on
		end

	set_on_change (a_action: PROCEDURE [INTEGER])
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

	toggle_section (a_i: INTEGER)
			-- Open or close section `a_i'; exclusive mode closes the
			-- rest when opening.
		require
			in_range: a_i >= 1 and a_i <= sections.count
		local
			j: INTEGER
		do
			if sections.i_th (a_i).is_open then
				sections.i_th (a_i).is_open := False
			else
				if is_exclusive then
					from
						j := 1
					until
						j > sections.count
					loop
						sections.i_th (j).is_open := False
						j := j + 1
					end
				end
				sections.i_th (a_i).is_open := True
			end
			if attached on_change as a then
				a.call (a_i)
			end
		ensure
			exclusive_law: (is_exclusive and is_section_open (a_i)) implies open_count = 1
		end

feature -- Layout

	wants_hover_point: BOOLEAN
		do
			Result := True
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			across
				sections as s
			loop
				Result := Result + Header_h + 2.0
				if s.is_open then
					Result := Result + s.content.preferred_height (a_p, a_width - 16.0) + 10.0
				end
			end
		end

	arrange (a_p: SW_PAINTER)
		local
			cy: REAL_64
		do
			cy := y
			across
				sections as s
			loop
				cy := cy + Header_h + 2.0
				if s.is_open then
					s.content.set_bounds (x + 8.0, cy + 2.0, width - 16.0,
						s.content.preferred_height (a_p, width - 16.0))
					s.content.arrange (a_p)
					cy := cy + s.content.height + 10.0
				end
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			cy, chx, chy: REAL_64
			i: INTEGER
		do
			t := a_p.theme
			cy := y
			from
				i := 1
			until
				i > sections.count
			loop
				if shows_hover and then hover_py >= cy and then hover_py < cy + Header_h then
					a_p.set_color (t.surface)
				else
					a_p.set_color (t.surface_variant)
				end
				a_p.rrect_fill (x, cy, width, Header_h, t.radius)
					-- the chevron: right-pointing shut, down-pointing open
				chx := x + 14.0
				chy := cy + Header_h / 2.0
				a_p.set_color (t.ink_muted)
				if sections.i_th (i).is_open then
					a_p.line (chx - 4.0, chy - 2.0, chx, chy + 3.0, 1.6)
					a_p.line (chx, chy + 3.0, chx + 4.0, chy - 2.0, 1.6)
				else
					a_p.line (chx - 2.0, chy - 4.0, chx + 3.0, chy, 1.6)
					a_p.line (chx + 3.0, chy, chx - 2.0, chy + 4.0, 1.6)
				end
				a_p.font ({SW_PAINTER}.Role_ui, t.size_label, True)
				a_p.set_color (t.ink)
				a_p.text (x + 28.0, cy + Header_h / 2.0 + t.size_label / 2.0 - 2.0, sections.i_th (i).title)
				cy := cy + Header_h + 2.0
				if sections.i_th (i).is_open then
					sections.i_th (i).content.draw (a_p)
					cy := cy + sections.i_th (i).content.height + 10.0
				end
				i := i + 1
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
		local
			cy: REAL_64
			i: INTEGER
		do
			if contains (a_px, a_py) then
				cy := y
				from
					i := 1
				until
					i > sections.count or Result /= Void
				loop
					if a_py >= cy and a_py < cy + Header_h then
						Result := Current
					end
					cy := cy + Header_h + 2.0
					if sections.i_th (i).is_open then
						if a_py >= cy and a_py < cy + sections.i_th (i).content.height then
							Result := sections.i_th (i).content.widget_at (a_px, a_py)
						end
						cy := cy + sections.i_th (i).content.height + 10.0
					end
					i := i + 1
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		local
			cy: REAL_64
			i: INTEGER
		do
			if is_enabled then
				cy := y
				from
					i := 1
				until
					i > sections.count or Result
				loop
					if a_py >= cy and a_py < cy + Header_h then
						toggle_section (i)
						Result := True
					end
					cy := cy + Header_h + 2.0
					if sections.i_th (i).is_open then
						cy := cy + sections.i_th (i).content.height + 10.0
					end
					i := i + 1
				end
				Result := True
			end
		end

invariant
	sections_attached: sections /= Void

end
