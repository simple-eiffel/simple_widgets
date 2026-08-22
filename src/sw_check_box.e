note
	description: "[
		A drawn check box with a label. Toggles on click; the check
		mark is two strokes, the box wears the accent when checked.
		The change agent fires after every toggle.
	]"

class
	SW_CHECK_BOX

inherit
	SW_WIDGET
		redefine
			preferred_width, handle_click
		end

create
	make

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL; a_checked: BOOLEAN; a_on_change: detachable PROCEDURE)
		do
			create label.make_from_string_general (a_label)
			is_checked := a_checked
			on_change := a_on_change
		ensure
			labelled: label.same_string_general (a_label)
			state_kept: is_checked = a_checked
		end

feature -- Access

	label: STRING_32

	is_checked: BOOLEAN

	on_change: detachable PROCEDURE

feature -- Element change

	set_checked (a_checked: BOOLEAN)
		do
			is_checked := a_checked
		ensure
			set: is_checked = a_checked
		end

	set_on_change (a_action: PROCEDURE)
		do
			on_change := a_action
		ensure
			set: on_change = a_action
		end

feature -- Layout

	Box_s: REAL_64 = 18.0

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := Box_s + 9.0 + a_p.advance (label)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
		do
			Result := 26.0
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			bx, by: REAL_64
		do
			t := a_p.theme
			bx := x
			by := y + (height - Box_s) / 2.0
			if is_checked and is_enabled then
				a_p.set_color (t.accent)
				a_p.rrect_fill (bx, by, Box_s, Box_s, t.radius)
			else
				a_p.set_color (t.surface)
				a_p.rrect_fill (bx, by, Box_s, Box_s, t.radius)
				if shows_hover then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_stroke (bx + 0.5, by + 0.5, Box_s - 1.0, Box_s - 1.0, t.radius)
			end
			if is_checked then
				if is_enabled then
					a_p.set_color (t.surface)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.line (bx + 4.0, by + 9.5, bx + 7.5, by + 13.0, 2.0)
				a_p.line (bx + 7.5, by + 13.0, bx + 14.0, by + 5.5, 2.0)
			end
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			if is_enabled then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.text (x + Box_s + 9.0, y + height - 8.0, label)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				is_checked := not is_checked
				if attached on_change as a then
					a.call
				end
				Result := True
			end
		end

invariant
	label_attached: label /= Void

end
