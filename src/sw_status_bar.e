note
	description: "[
		The bottom strip: a left message and a right message in mono
		on the variant surface, hairline above. The capture strip's
		grandchild, formalized.

		SECTIONS (GW-11, asked for by simple_bible): between the two
		messages, text sections (clickable when given an agent: the
		active link set, the versification note) and small hosted
		widgets at a fixed width (job progress with its Cancel button).
		Leading sections pack after the left message, trailing ones
		before the right message, each side in the order added, with a
		divider between neighbours. A hidden section takes no room,
		draws nothing and answers no click. Hosted widgets are real
		children: they draw, hit-test, take clicks and the focus.
	]"

class
	SW_STATUS_BAR

inherit
	SW_WIDGET
		redefine
			arrange, widget_at, handle_click, cursor_kind,
			wants_hover_point, sub_widgets
		end

create
	make

feature {NONE} -- Initialization

	make
		do
			create left_text.make_empty
			create right_text.make_empty
			create sections.make (4)
		end

feature -- Access

	left_text: STRING_32
	right_text: STRING_32

	sections: ARRAYED_LIST [SW_STATUS_SECTION]
			-- In the order added; `section (i)' is the i-th.

	section (a_index: INTEGER): SW_STATUS_SECTION
		require
			valid_index: sections.valid_index (a_index)
		do
			Result := sections.i_th (a_index)
		end

	section_at (a_px: REAL_64): INTEGER
			-- Index of the visible section under `a_px' as last
			-- arranged; 0 when none.
		local
			i: INTEGER
		do
			from i := 1 until i > sections.count or Result /= 0 loop
				if sections.i_th (i).has_point (a_px) then
					Result := i
				end
				i := i + 1
			end
		ensure
			valid: Result = 0 or else (sections.valid_index (Result) and then section (Result).is_visible)
		end

feature -- Element change

	set_left (a_text: READABLE_STRING_GENERAL)
		do
			create left_text.make_from_string_general (a_text)
		ensure
			kept: left_text.same_string_general (a_text)
		end

	set_right (a_text: READABLE_STRING_GENERAL)
		do
			create right_text.make_from_string_general (a_text)
		ensure
			kept: right_text.same_string_general (a_text)
		end

feature -- Sections (GW-11)

	add_text (a_text: READABLE_STRING_GENERAL; a_trailing: BOOLEAN): INTEGER
			-- Add a text section; answer its index.
		do
			sections.extend (create {SW_STATUS_SECTION}.make_text (a_text, a_trailing))
			Result := sections.count
		ensure
			added: sections.count = old sections.count + 1 and Result = sections.count
		end

	add_widget (a_widget: SW_WIDGET; a_width: REAL_64; a_trailing: BOOLEAN): INTEGER
			-- Host `a_widget' in a section `a_width' wide; answer its index.
		require
			positive_width: a_width > 0.0
			not_hosted_elsewhere: a_widget.parent = Void
		do
			a_widget.set_parent (Current)
			sections.extend (create {SW_STATUS_SECTION}.make_widget (a_widget, a_width, a_trailing))
			Result := sections.count
		ensure
			added: sections.count = old sections.count + 1 and Result = sections.count
			hosted: a_widget.parent = Current
		end

	set_section_text (a_index: INTEGER; a_text: READABLE_STRING_GENERAL)
		require
			valid_index: sections.valid_index (a_index)
			text_section: section (a_index).widget = Void
		do
			section (a_index).set_text (a_text)
		ensure
			kept: section (a_index).text.same_string_general (a_text)
		end

	set_section_visible (a_index: INTEGER; a_visible: BOOLEAN)
			-- Show or hide a section (the progress section while no job
			-- runs). Takes effect at the next arrange.
		require
			valid_index: sections.valid_index (a_index)
		do
			section (a_index).set_visible (a_visible)
		ensure
			set: section (a_index).is_visible = a_visible
		end

	set_on_section_click (a_index: INTEGER; a_action: PROCEDURE)
		require
			valid_index: sections.valid_index (a_index)
			text_section: section (a_index).widget = Void
		do
			section (a_index).set_on_click (a_action)
		ensure
			clickable: section (a_index).is_clickable
		end

feature -- Layout

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 32.0
		end

	arrange (a_p: SW_PAINTER)
			-- Place every section, and size and arrange hosted widgets.
		local
			lx, tx, total, w, h: REAL_64
			l_trailing: INTEGER
		do
			set_font (a_p)
			lx := x + Pad
			if not left_text.is_empty then
				lx := lx + a_p.advance (left_text) + Gap
			end
			across sections as s loop
				if not s.is_visible then
					s.place (0.0, 0.0)
				elseif not s.is_trailing then
					w := natural_width (s, a_p)
					s.place (lx, w)
					lx := lx + w + Gap
				else
					total := total + natural_width (s, a_p)
					l_trailing := l_trailing + 1
				end
			end
			if l_trailing > 0 then
				total := total + Gap * (l_trailing - 1)
				tx := x + width - Pad - total
				if not right_text.is_empty then
					tx := tx - a_p.advance (right_text) - Gap
				end
				across sections as s loop
					if s.is_visible and s.is_trailing then
						w := natural_width (s, a_p)
						s.place (tx, w)
						tx := tx + w + Gap
					end
				end
			end
			across sections as s loop
				if s.is_visible and then attached s.widget as al_w then
					h := al_w.preferred_height (a_p, s.span).min (height - 8.0).max (0.0)
					al_w.set_bounds (s.left, y + (height - h) / 2.0, s.span, h)
					al_w.arrange (a_p)
				end
			end
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			l_before, l_first_trailing: BOOLEAN
			l_trailing_end, l_base: REAL_64
		do
			t := a_p.theme
			a_p.set_color (t.surface_variant)
			a_p.fill_rect (x, y, width, height)
			a_p.hline (x, y, width)
			set_font (a_p)
			l_base := y + height / 2.0 + 5.0
			a_p.set_color (t.ink_muted)
			if not left_text.is_empty then
				a_p.text (x + Pad, l_base, left_text)
			end
			if not right_text.is_empty then
				a_p.text (x + width - Pad - a_p.advance (right_text), l_base, right_text)
			end
			l_before := not left_text.is_empty
			l_first_trailing := True
			across sections as s loop
				if s.is_visible and s.span > 0.0 then
					if (not s.is_trailing and l_before) or (s.is_trailing and not l_first_trailing) then
						a_p.set_color (t.divider)
						a_p.vline (s.left - Gap / 2.0, y + 8.0, height - 16.0)
					end
					if s.is_trailing then
						l_first_trailing := False
						l_trailing_end := s.left + s.span
					else
						l_before := True
					end
					if attached s.widget as al_w then
						al_w.draw (a_p)
					else
						set_font (a_p)
						if s.is_clickable then
							a_p.set_color (t.ink_accent)
						else
							a_p.set_color (t.ink_muted)
						end
						a_p.text (s.left, l_base, s.text)
					end
				end
			end
			if not l_first_trailing and not right_text.is_empty then
				a_p.set_color (t.divider)
				a_p.vline (l_trailing_end + Gap / 2.0, y + 8.0, height - 16.0)
			end
		end

feature -- Hit testing

	widget_at (a_px, a_py: REAL_64): detachable SW_WIDGET
			-- A hosted widget under the point, else the bar itself.
		do
			if contains (a_px, a_py) then
				across sections as s until Result /= Void loop
					if s.is_visible and then attached s.widget as al_w then
						Result := al_w.widget_at (a_px, a_py)
					end
				end
				if Result = Void then
					Result := Current
				end
			end
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
			-- A clickable text section runs its agent.
		local
			i: INTEGER
		do
			i := section_at (a_px)
			if i > 0 and then attached section (i).on_click as al_action and then section (i).is_clickable then
				al_action.call
				Result := True
			end
		end

	cursor_kind: INTEGER
			-- The hand over a clickable section.
		local
			i: INTEGER
		do
			i := section_at (hover_px)
			if i > 0 and then section (i).is_clickable then
				Result := 2
			end
		end

	wants_hover_point: BOOLEAN
			-- Track the pointer when any section is clickable.
		do
			Result := across sections as s some s.is_clickable end
		end

	sub_widgets: ARRAYED_LIST [SW_WIDGET]
			-- The visible hosted widgets.
		do
			create Result.make (2)
			across sections as s loop
				if s.is_visible and then attached s.widget as al_w then
					Result.extend (al_w)
				end
			end
		end

feature {NONE} -- Implementation

	Pad: REAL_64 = 12.0
			-- Space at each end.

	Gap: REAL_64 = 16.0
			-- Space between neighbours; the divider sits in its middle.

	set_font (a_p: SW_PAINTER)
		do
			a_p.font ({SW_PAINTER}.Role_mono, a_p.theme.size_chip + 1.0, False)
		end

	natural_width (a_section: SW_STATUS_SECTION; a_p: SW_PAINTER): REAL_64
			-- Text width, or the hosted widget's fixed width.
		do
			if attached a_section.widget then
				Result := a_section.fixed_width
			else
				Result := a_p.advance (a_section.text)
			end
		ensure
			non_negative: Result >= 0.0
		end

invariant
	texts_attached: left_text /= Void and right_text /= Void
	sections_attached: sections /= Void

end
