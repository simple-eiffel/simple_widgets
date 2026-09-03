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

	is_indeterminate: BOOLEAN
			-- The third state (a dash): meaningful for cascades.
			-- Any user click resolves it to checked.

	set_indeterminate
		do
			is_indeterminate := True
		ensure
			mixed: is_indeterminate
		end

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
			-- The tick box at 1x; `box_side' scales it.

	box_side (a_p: SW_PAINTER): REAL_64
			-- The tick box at the current text scale, never smaller than
			-- the text standing beside it.
		do
			Result := (Box_s * a_p.theme.text_scale).max (a_p.text_extent)
		ensure
			positive: Result > 0.0
		end

	preferred_width (a_p: SW_PAINTER): REAL_64
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := box_side (a_p) + 9.0 * a_p.theme.text_scale + a_p.advance (label)
		end

	preferred_height (a_p: SW_PAINTER; a_width: REAL_64): REAL_64
			-- 26 px nominal, or the font's minimum, whichever is larger.
		do
			a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label, False)
			Result := (26.0).max (a_p.min_control_height)
		ensure then
			at_least_the_minimum: Result >= a_p.min_control_height
		end

feature -- Drawing

	draw (a_p: SW_PAINTER)
		local
			t: SW_THEME
			bx, by, bs: REAL_64
		do
			t := a_p.theme
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			bx := x
			bs := box_side (a_p)
			by := y + (height - bs) / 2.0
			if is_indeterminate and is_enabled then
				a_p.set_color (t.accent)
				a_p.rrect_fill (bx, by, bs, bs, t.radius)
				a_p.set_color (t.surface)
				a_p.line (bx + bs / 4.5, by + bs / 2.0, bx + bs - bs / 4.5, by + bs / 2.0, 2.4)
			elseif is_checked and is_enabled then
				a_p.set_color (t.accent)
				a_p.rrect_fill (bx, by, bs, bs, t.radius)
			else
				a_p.set_color (t.surface)
				a_p.rrect_fill (bx, by, bs, bs, t.radius)
				if shows_hover then
					a_p.set_color (t.accent)
				else
					a_p.set_color (t.outline)
				end
				a_p.rrect_stroke (bx + 0.5, by + 0.5, bs - 1.0, bs - 1.0, t.radius)
			end
			if is_checked then
				if is_enabled then
					a_p.set_color (t.surface)
				else
					a_p.set_color (t.ink_muted)
				end
				a_p.line (bx + bs * 0.222, by + bs * 0.528,
					bx + bs * 0.417, by + bs * 0.722, 2.0)
				a_p.line (bx + bs * 0.417, by + bs * 0.722,
					bx + bs * 0.778, by + bs * 0.306, 2.0)
			end
			a_p.font ({SW_PAINTER}.Role_ui, t.size_label, False)
			if is_enabled then
				a_p.set_color (t.ink)
			else
				a_p.set_color (t.ink_muted)
			end
			a_p.text (x + bs + 9.0 * t.text_scale, a_p.baseline_in (y, height), label)
		end

feature -- Input

	handle_click (a_px, a_py: REAL_64): BOOLEAN
		do
			if is_enabled then
				if is_indeterminate then
					is_indeterminate := False
					is_checked := True
				else
					is_checked := not is_checked
				end
				if attached on_change as a then
					a.call
				end
				Result := True
			end
		end

invariant
	label_attached: label /= Void

end
